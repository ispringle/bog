(in-package #:bog)

;;; =========================================================================
;;; Config
;;; =========================================================================

(defvar *pages-dir* #p"site/"
        "Directory containing site source files -- pages, assets, and static files.")
(defvar *site-name* "Bog"
  "Site name used in the layout header and default <title>.")
(defvar *port*      8080
  "Default port for the development server.")
(defvar *dev*       t
  "When T, mutable pages bypass the cache. Set to NIL at generate/prod time.")

;;; =========================================================================
;;; Spinneret attribute prefixes
;;; =========================================================================

(push "hx-" spinneret:*unvalidated-attribute-prefixes*)  ; htmx
(push "x-"  spinneret:*unvalidated-attribute-prefixes*)  ; alpinejs
(push "@"   spinneret:*unvalidated-attribute-prefixes*)  ; alpinejs

;;; =========================================================================
;;; Utilities
;;; =========================================================================

(defmacro when-let (bindings &body body)
  "Bind BINDINGS and execute BODY when all bindings are truthy."
  (let ((symbols (mapcar #'first bindings)))
    `(let ,bindings
       (when (and ,@symbols)
         ,@body))))

(defmacro if-let (bindings then else)
  "Bind BINDINGS, execute THEN if all truthy, ELSE otherwise."
  (let ((symbols (mapcar #'first bindings)))
    `(let ,bindings
       (if (and ,@symbols)
           ,then
           ,else))))

;;; =========================================================================
;;; Page cache
;;; =========================================================================

(defvar *cache* (make-hash-table :test #'equal))
;; cache value: (mtime . rendered-html)

(defun cache-get (path)
  (when-let ((entry (gethash path *cache*))
             (mtime (file-write-date path)))
    (when (= mtime (car entry))
      (cdr entry))))

(defun cache-set (path html)
  (setf (gethash path *cache*)
        (cons (file-write-date path) html))
  html)

(defun cache-clear ()
  (clrhash *cache*))

;;; =========================================================================
;;; File resolution
;;; =========================================================================

(defun url-to-filepath (base name type)
  "Build a pathname under *pages-dir* from a URL stem + explicit name + type.
BASE provides directory components, e.g. "blog" or "".
NAME is the filename stem. TYPE is the extension."
  (let* ((parts (remove "" (uiop:split-string base :separator "/") :test #'equal))
         (dir   (make-pathname :directory (list* :relative parts))))
    (merge-pathnames (make-pathname :name name :type type)
                     (merge-pathnames dir *pages-dir*))))

(defun plus-file-p (file)
  "Returns T if FILE is a + prefixed bog-internal file (e.g. +template.lisp)."
  (char= (char (pathname-name file) 0) #\+))

(defun find-page (path-info)
  "Resolve a URL path to a file in *pages-dir*, trying lisp/md/html and index variants."
  (let* ((base  (string-left-trim "/" path-info))
         (parts (remove "" (uiop:split-string base :separator "/") :test #'equal))
         (dir   (butlast parts))
         (name  (car (last parts))))
    (flet ((try (d n)
             (when (or (string= n "index") (not (char= (char n 0) #\+)))
               (or (probe-file (url-to-filepath d n "lisp"))
                   (probe-file (url-to-filepath d n "md"))
                   (probe-file (url-to-filepath d n "html"))))))
      ;; Try the path as a direct file, then as a directory index
      (or (when name (try (format nil "~{~a/~}" dir) name))
          (try base "index")))))

;;; =========================================================================
;;; Page definition
;;; =========================================================================

(defvar *mutable-pages* (make-hash-table :test #'equal)
  "Registry of pages declared :mutable t. Keyed by namestring.")

(defvar *page-templates* (make-hash-table :test #'equal)
  "Registry of template names for lisp pages. Keyed by namestring.")

(defmacro defpage ((&key mutable (template "+template")) &body body)
  "Define a page function in the current file context.
Pages are static (deterministic) by default. Declare (:mutable t) for pages
whose output cannot be known at build time. TEMPLATE names the +template file
to use (default +template); resolved by walking up from the page directory."
  (let ((fn-name (intern (string-upcase (pathname-name *load-pathname*))
                         "BOG-PAGES")))
    `(progn
       ,(when mutable
          `(setf (gethash ,(namestring *load-pathname*) *mutable-pages*) t))
       (setf (gethash ,(namestring *load-pathname*) *page-templates*) ,template)
       (defun ,fn-name ()
         ,@body))))

(defun mutable-page-p (file)
  (gethash (namestring file) *mutable-pages*))

(defun page-template-name (file)
  "Return the template name registered for FILE, or the default."
  (gethash (namestring file) *page-templates* "+template"))


;;; =========================================================================
;;; Template system
;;; =========================================================================

(defvar *template-cache* (make-hash-table :test #'equal)
  "Cache of loaded template functions. Keyed by template file namestring.")

(defun template-file-name (name)
  "Convert a template name like +template or +tufte to a filename."
  (if (string= (subseq name 0 1) "+")
      (concatenate 'string name ".lisp")
      (concatenate 'string "+" name ".lisp")))

(defun find-template (page-file &optional (name "+template"))
  "Walk up from PAGE-FILE's directory looking for NAME.lisp.
Returns the template file pathname or signals an error if not found."
  (let ((filename (template-file-name name)))
    (labels ((walk (dir)
               (let ((candidate (merge-pathnames filename dir)))
                 (cond
                   ((probe-file candidate) candidate)
                   ;; Stop at or above *pages-dir*
                   ((uiop:pathname-equal dir (truename *pages-dir*))
                    (error "No template ~a found for ~a (searched up to ~a)"
                           filename page-file *pages-dir*))
                   (t (walk (uiop:pathname-parent-directory-pathname dir)))))))
      (walk (uiop:pathname-directory-pathname page-file)))))

(defun load-template (template-file)
  "Load a template file and return its registered function.
Templates define a function via deftemplate keyed to their directory."
  (let ((key (namestring template-file)))
    (or (gethash key *template-fns*)
        (progn
          (load template-file)
          (or (gethash key *template-fns*)
              (error "deftemplate not found after loading ~a" template-file))))))

(defvar *template-fns* (make-hash-table :test #'equal)
  "Registry of template functions. Keyed by template file namestring.")

(defmacro deftemplate (args &body body)
  "Define a template function for the current directory.
ARGS is a lambda list: (content &key title description canonical head).
CONTENT is the rendered page HTML string. Keyword args are page metadata.
Called by the render pipeline to wrap content in the site layout.

Usage: (bog:deftemplate (content &key title description canonical head) ...)"
  `(setf (gethash ,(namestring *load-pathname*) *template-fns*)
         (lambda ,args
           (declare (ignorable ,@(remove-if (lambda (x)
                                              (member x '(&key &optional &rest &allow-other-keys)))
                                            args)))
           ,@body)))

(defun call-template (template-file content meta)
  "Invoke the template function from TEMPLATE-FILE with CONTENT and META."
  ;; In dev mode, always reload template to pick up edits.
  ;; In prod, use cached function.
  (when *dev*
    (remhash (namestring template-file) *template-fns*))
  (let ((fn (load-template template-file)))
    (funcall fn content
             :title       (getf meta :title)
             :description (getf meta :description)
             :canonical   (getf meta :canonical)
             :head        (getf meta :head))))

;;; =========================================================================
;;; File reading
;;; =========================================================================

(defun read-file (path)
  "Read file contents as a string.
Uses file-length for initial buffer sizing, then trims to actual chars read,
which may be fewer for multibyte UTF-8 content."
  (with-open-file (in path)
    (let* ((buf  (make-string (file-length in)))
           (read (read-sequence buf in)))
      (subseq buf 0 read))))

;;; =========================================================================
;;; Front matter
;;; =========================================================================

(defun parse-front-matter (text)
  "Strip and parse a leading front matter block delimited by ---.
Returns (values body-string plist-of-metadata).
Supports simple key: value pairs only."
  (if (and (>= (length text) 3)
           (string= text "---" :end1 3))
      (let ((end (search "---" text :start2 3)))
        (if end
            (values (subseq text (+ end 3))
                    (parse-fm-pairs (subseq text 3 end)))
            (values text nil)))
      (values text nil)))

(defun parse-fm-pairs (str)
  "Parse newline-separated key: value lines into a plist."
  (let ((result nil))
    (dolist (line (split-lines str) result)
      (let ((colon (position #\: line)))
        (when colon
          (let ((key   (intern (string-upcase (string-trim " " (subseq line 0 colon))) :keyword))
                (value (string-trim " " (subseq line (1+ colon)))))
            (setf result (list* key value result))))))))

(defun split-lines (str)
  (loop for start = 0 then (1+ pos)
        for pos   = (position #\newline str :start start)
        for line  = (string-trim " " (subseq str start (or pos (length str))))
        unless (string= line "") collect line
          while pos))

;;; =========================================================================
;;; Markdown rendering
;;; =========================================================================

(defun strip-invalid-xml-chars (s)
  "Remove characters that are illegal in XML 1.0.
Valid ranges: #x9 #xA #xD #x20-#xD7FF #xE000-#xFFFD #x10000-#x10FFFF"
  (with-output-to-string (out)
    (loop for c across s
          for cp = (char-code c)
          when (or (= cp #x9) (= cp #xA) (= cp #xD)
                   (<= #x20 cp #xD7FF)
                   (<= #xE000 cp #xFFFD)
                   (<= #x10000 cp #x10FFFF))
            do (write-char c out))))

;; Enable fenced code blocks. *code-blocks* must be set globally before any
;; parsing occurs -- renderer and style are configured in config.lisp.
(setf 3bmd-code-blocks:*code-blocks* t)

(defun md->html (md-string)
  "Render a Markdown string to an HTML string via 3bmd.
Uses 3bmd-ext-code-blocks with Chroma for server-side syntax highlighting."
  (strip-invalid-xml-chars
   (with-output-to-string (s)
     (3bmd:parse-string-and-print-to-stream md-string s))))

;;; =========================================================================
;;; DOM utilities
;;; =========================================================================

(defun dom-serialize (dom)
  "Serialize a plump DOM to an HTML string.
plump:serialize with nil stream returns a string."
  (plump:serialize dom nil))

(defun extract-dom-title (dom)
  "Extract text content of the first h1 in the DOM, or nil."
  (let ((h1s (clss:select "h1" dom)))
    (when (plusp (length h1s))
      (plump:render-text (aref h1s 0)))))

(defun extract-dom-description (dom)
  "Extract text content of the first p in the DOM, or nil."
  (let ((ps (clss:select "p" dom)))
    (when (plusp (length ps))
      (plump:render-text (aref ps 0)))))

;;; =========================================================================
;;; Metadata extraction
;;; =========================================================================

(defun extract-metadata (front-matter dom)
  "Build a metadata plist from front-matter + DOM fallbacks.
Front-matter values always win. DOM is queried for missing keys.
Called before preprocessing so DOM is the raw 3bmd output."
  (list* :title       (or (getf front-matter :title)       (extract-dom-title dom))
         :description (or (getf front-matter :description) (extract-dom-description dom))
         front-matter))

;;; =========================================================================
;;; Stage 1 -- raw text transforms, before md->html
;;;
;;; Applied ONLY to MD pages. Operates on the raw markdown string.
;;; Runs before 3bmd sees the content -- use for custom syntax that 3bmd
;;; would mangle or can't express (sidenotes, citations, epigraphs).
;;;
;;; Each fn takes a string and returns a string.
;;; =========================================================================

(defvar *text-fns* (list)
  "Stage 1 transforms: raw markdown string -> string, before md->html.
Each fn takes (text) and returns text.")

(defun run-text-fns (text)
  (reduce (lambda (s f) (funcall f s)) *text-fns* :initial-value text))

;;; =========================================================================
;;; Stage 2 -- MD fragment DOM transforms after md->html
;;;
;;; Applied ONLY to MD pages. Operates on the plump DOM of the content
;;; fragment after md->html, before template injection.
;;;
;;; Each fn takes (dom meta) and returns dom.
;;; Good for: DOM-level rewrites that need parsed structure.
;;; =========================================================================

(defvar *process-fns* (list)
  "Stage 2 transforms: fragment DOM after md->html, before template.
Each fn takes (dom meta) and returns dom.")

(defun run-process (dom meta)
  (reduce (lambda (d f) (funcall f d meta)) *process-fns* :initial-value dom))

;;; =========================================================================
;;; Postprocessing -- full page DOM transforms after Spinneret renders layout
;;;
;;; Applied to ALL page types (md, html, lisp).
;;; For lisp pages, runs after Spinneret renders the full page HTML.
;;; Operates on the complete page DOM -- layout + content together.
;;; This is where heading normalization belongs: only here do we have
;;; all headings in context so levels can be correctly assigned.
;;;
;;; Each fn takes (dom meta) and returns dom.
;;; Good for: heading normalization, anchor links, microformat attrs.
;;; =========================================================================

(defvar *postprocess-fns* (list)
  "Postprocess transforms applied to MD and HTML pages.
Each fn takes (dom meta) and returns dom.
Populated after normalize-headings is defined below.")

(defun run-postprocess (dom meta)
  (reduce (lambda (d f) (funcall f d meta)) *postprocess-fns* :initial-value dom))

(defun preserve-pre-content (html thunk)
  "Extract <pre> block contents before postprocessing, restore after serialization.
Plump escapes HTML entities inside <pre> on re-serialize, destroying colorize spans.
We replace pre contents with placeholders, run the thunk, then restore."
  (let ((pre-contents (list))
        (counter 0))
    ;; Extract pre contents, replace with placeholder text nodes
    (flet ((placeholder (n) (format nil "BOG-PRE-~a-PLACEHOLDER" n)))
      (let* ((pre-re  (cl-ppcre:create-scanner "<pre>(.*?)</pre>" :single-line-mode t :case-insensitive-mode t))
             (cleaned (cl-ppcre:regex-replace-all
                       pre-re html
                       (lambda (match &rest args)
                         (declare (ignore args))
                         (let ((inner (cl-ppcre:regex-replace "^<pre>" (cl-ppcre:regex-replace "</pre>$" match "") "")))
                           (push inner pre-contents)
                           (format nil "<pre>~a</pre>" (placeholder counter))))
                       :simple-calls t)))
        (declare (ignore cleaned)))
      ;; actually do it properly
      (let* ((result (list))
             (idx 0)
             (out (cl-ppcre:regex-replace-all
                   "<pre[^>]*>.*?</pre>"
                   html
                   (lambda (match &rest args)
                     (declare (ignore args))
                     (push match result)
                     (prog1 (format nil "BOG_PRE_~a_END" idx)
                       (incf idx)))
                   :simple-calls t))
             (processed (funcall thunk out)))
        (loop for i from 0 below idx
              for original in (reverse result)
              do (setf processed
                       (cl-ppcre:regex-replace
                        (format nil "BOG_PRE_~a_END" i)
                        processed
                        (cl-ppcre:regex-replace-all "\\" original "\\\\"))))
        processed))))

(defun shift-heading (node)
  "Shift a single heading element down one level: h1->h2 ... h5->h6."
  (let* ((tag   (plump:tag-name node))
         (level (parse-integer (subseq tag 1) :junk-allowed t)))
    (when (and level (<= 1 level 5))
      (setf (plump:tag-name node)
            (format nil "h~a" (1+ level))))))

(defun normalize-headings (dom meta)
  "Postprocess transform: shift content headings down one level.
Scoped to <main> so the layout <h1> (site name in <header>) is untouched.
h1->h2, h2->h3, h3->h4, h4->h5, h5->h6."
  (declare (ignore meta))
  (let* ((mains (clss:select "main" dom))
         (scope (if (plusp (length mains)) (aref mains 0) dom))
         (headings (clss:select "h1,h2,h3,h4,h5" scope)))
    ;; Reverse order prevents double-shifting -- process last node first
    (loop for i from (1- (length headings)) downto 0
          do (shift-heading (aref headings i))))
  dom)

;; Default postprocess pipeline
(setf *postprocess-fns* (list #'normalize-headings))

;;; =========================================================================
;;; HTML fragment detection and head hoisting
;;; =========================================================================

(defun html-fragment-p (dom)
  "Returns T if the DOM is a fragment rather than a full document.
A full document has a doctype node or an <html> root element."
  (not (or (some #'plump:doctype-p (plump:children dom))
           (plusp (length (clss:select "html" dom))))))

(defun extract-frag-head (dom)
  "Extract and remove the <head> element from a fragment DOM.
Returns (values head-html-string title-string).
head-html-string is the serialized inner content of <head> for hoisting
into the layout's <head> via :raw. title-string is pulled from <title>
so it can populate the layout title without duplicating in the head string.
Returns (values nil nil) if no <head> present."
  (let ((heads (clss:select "head" dom)))
    (if (zerop (length heads))
        (values nil nil)
        (let* ((head  (aref heads 0))
               ;; Extract title text before serializing
               (titles (clss:select "title" head))
               (title  (when (plusp (length titles))
                         (plump:render-text (aref titles 0))))
               ;; Serialize inner children of <head>, not the <head> tag itself
               (html   (with-output-to-string (s)
                         (loop for child across (plump:children head)
                               do (plump:serialize child s)))))
          (plump:remove-child head)
          (values html title)))))

;;; =========================================================================
;;; Page rendering
;;; =========================================================================

(defun render-md-page (file)
  "MD pipeline -- three stages:
  1. parse-front-matter, run-text-fns on raw body (string->string)
  2. md->html, plump:parse, extract-metadata, run-process (fragment DOM)
  3. dom-serialize, find-template, call-template, plump:parse, run-postprocess"
  (or (cache-get file)
      (cache-set file
                 (multiple-value-bind (body front-matter)
                     (parse-front-matter (read-file file))
                   ;; Stage 1: raw text transforms
                   (let* ((body      (run-text-fns body))
                          ;; Stage 2: fragment DOM transforms
                          (frag-html (md->html body))
                          (frag-dom  (plump:parse frag-html))
                          (meta      (extract-metadata front-matter frag-dom))
                          (frag-dom  (run-process frag-dom meta))
                          (frag-html (dom-serialize frag-dom))
                          ;; Stage 3: full page postprocess
                          (tmpl      (find-template file (getf meta :template "+template")))
                          (page      (call-template tmpl frag-html meta))
                          (page-dom  (plump:parse page))
                          (page-dom  (run-postprocess page-dom meta)))
                     (dom-serialize page-dom))))))

(defun extract-doctype-template (raw-html)
  "Extract template name from <!DOCTYPE +name> convention.
Returns (values template-name html-without-doctype).
If no custom doctype, returns (values +template raw-html)."
  (let ((scanner (cl-ppcre:create-scanner
                  "^\\s*<!doctype\\s+(\\+[^>]+)\\s*>\\s*"
                  :case-insensitive-mode t)))
    (multiple-value-bind (start end starts ends)
        (cl-ppcre:scan scanner raw-html)
      (if start
          (values (string-trim " " (subseq raw-html (aref starts 0) (aref ends 0)))
                  (subseq raw-html end))
          (values "+template" raw-html)))))

(defun render-html-page (file)
  "HTML pipeline: no front matter, no preprocess.
Full documents (<!DOCTYPE html>) served as-is.
Fragments get template wrapping, head hoisting, and postprocessing.
<!DOCTYPE +name> in a fragment selects a named template."
  (or (cache-get file)
      (cache-set file
                 (let* ((raw (read-file file))
                        (dom (plump:parse raw)))
                   (if (not (html-fragment-p dom))
                       ;; Full document -- serve as-is
                       (dom-serialize dom)
                       ;; Fragment -- extract template name from doctype if present,
                       ;; hoist head, call template, postprocess
                       (multiple-value-bind (tmpl-name frag-html)
                           (extract-doctype-template raw)
                         (let* ((dom      (plump:parse frag-html)))
                           (multiple-value-bind (head-html title)
                               (extract-frag-head dom)
                             (let* (
                                    (meta     (extract-metadata
                                               (when title (list :title title))
                                               dom))
                                    (meta     (if head-html
                                                  (list* :head head-html meta)
                                                  meta))
                                    (tmpl     (find-template file tmpl-name))
                                    (page     (call-template tmpl (dom-serialize dom) meta))
                                    (page-dom (plump:parse page))
                                    (page-dom (run-postprocess page-dom meta)))
                               (dom-serialize page-dom))))))))))

(defun render-lisp-page (file)
  "Lisp pages call their defpage fn, which returns (values content-html meta-plist).
Meta is optional -- if only one value returned, meta is nil.
The template is found via find-template using the name registered by defpage.
Postprocess applies to the final page DOM."
  (flet ((call-page ()
           (load file)
           (multiple-value-bind (content meta)
               (funcall (page-fn file))
             (let* ((tmpl     (find-template file (page-template-name file)))
                    (page     (call-template tmpl content meta))
                    (page-dom (plump:parse page))
                    (page-dom (run-postprocess page-dom meta)))
               (dom-serialize page-dom)))))
    (if (and *dev* (mutable-page-p file))
        (call-page)
        (or (cache-get file)
            (cache-set file (call-page))))))

(defun page-fn (file)
  "Derive the expected page function name from the file's pathname-name."
  (let ((name (string-upcase (pathname-name file))))
    (or (find-symbol name "BOG-PAGES")
        (error "No function ~a found after loading ~a" name file))))

(defun render-file (file)
  (let ((type (pathname-type file)))
    (cond
      ((equal type "lisp") (render-lisp-page file))
      ((equal type "md")   (render-md-page file))
      ((equal type "html") (render-html-page file))
      (t (error "Unknown file type: ~a" type)))))
