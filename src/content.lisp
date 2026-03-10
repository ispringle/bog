(in-package #:bog)

;;; ================================================================
;;; Config
;;; ================================================================

(defvar *pages-dir* #p"site/"
        "Directory containing site source files.")
(defvar *site-name* "Bog"
  "Site name used in the layout header and default <title>.")
(defvar *port* 8080
  "Default port for the development server.")
(defvar *dev* t
  "When T, mutable pages bypass the cache.")
(defvar *default-template* "+template"
  "Default template name for pages without an explicit choice.")

;;; ================================================================
;;; Spinneret attribute prefixes
;;; ================================================================

(push "hx-" spinneret:*unvalidated-attribute-prefixes*)
(push "x-" spinneret:*unvalidated-attribute-prefixes*)
(push "@" spinneret:*unvalidated-attribute-prefixes*)

;;; ================================================================
;;; Utilities
;;; ================================================================

(defmacro when-let (bindings &body body)
  "Bind BINDINGS and execute BODY when all values are truthy.
All bindings evaluate unconditionally (unlike Alexandria's
when-let* which short-circuits)."
  (let ((symbols (mapcar #'first bindings)))
    `(let ,bindings
       (when (and ,@symbols)
         ,@body))))

(defmacro if-let (bindings then else)
  "Bind BINDINGS, execute THEN if all truthy, ELSE otherwise.
All bindings evaluate unconditionally."
  (let ((symbols (mapcar #'first bindings)))
    `(let ,bindings
       (if (and ,@symbols)
           ,then
           ,else))))

;;; ================================================================
;;; Page cache
;;; ================================================================

(defvar *cache* (make-hash-table :test #'equal))

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

;;; ================================================================
;;; File resolution
;;; ================================================================

(defun url-to-filepath (base name type)
  "Build a pathname under *pages-dir* from URL components."
  (let* ((parts (remove ""
                        (uiop:split-string base :separator "/")
                        :test #'equal))
         (dir (make-pathname
               :directory (list* :relative parts))))
    (merge-pathnames
     (make-pathname :name name :type type)
     (merge-pathnames dir *pages-dir*))))

(defun plus-file-p (file)
  "Returns T if FILE is a + prefixed internal file."
  (let ((name (pathname-name file)))
    (and (plusp (length name))
         (char= (char name 0) #\+))))

(defun find-page (path-info)
  "Resolve a URL path to a page file in *pages-dir*.
Tries lisp/md/html extensions, then index variants."
  (let* ((base (string-left-trim "/" path-info))
         (parts (remove ""
                        (uiop:split-string base :separator "/")
                        :test #'equal))
         (dir (butlast parts))
         (name (car (last parts))))
    (flet ((try (d n)
             (when (and (plusp (length n))
                        (or (string= n "index")
                            (not (char= (char n 0) #\+))))
               (or (probe-file (url-to-filepath d n "lisp"))
                   (probe-file (url-to-filepath d n "md"))
                   (probe-file (url-to-filepath d n "html"))))))
      (or (when name
            (try (format nil "~{~a/~}" dir) name))
          (try base "index")))))

;;; ================================================================
;;; Page definition
;;; ================================================================

(defvar *mutable-pages* (make-hash-table :test #'equal)
  "Registry of pages declared :mutable t.")

(defvar *page-templates* (make-hash-table :test #'equal)
  "Registry of template names for lisp pages.")

(defmacro defpage ((&key mutable
                      (template *default-template*))
                   &body body)
  "Define a page function in the current file context.
Pages are static by default. Declare (:mutable t) for dynamic
pages. TEMPLATE names the +template file to use."
  (let ((fn-name (intern
                  (string-upcase (pathname-name *load-pathname*))
                  "BOG-PAGES")))
    `(progn
       ,(when mutable
          `(setf (gethash ,(namestring *load-pathname*)
                          *mutable-pages*)
                 t))
       (setf (gethash ,(namestring *load-pathname*)
                      *page-templates*)
             ,template)
       (defun ,fn-name ()
         ,@body))))

(defun mutable-page-p (file)
  (gethash (namestring file) *mutable-pages*))

(defun page-template-name (file)
  (gethash (namestring file) *page-templates*
           *default-template*))

;;; ================================================================
;;; Template system
;;; ================================================================

(defvar *template-fns* (make-hash-table :test #'equal)
  "Registry of template functions. Keyed by file namestring.")

(defun template-file-name (name)
  "Convert a template name to a filename."
  (if (string= (subseq name 0 1) "+")
      (concatenate 'string name ".lisp")
      (concatenate 'string "+" name ".lisp")))

(defun find-template (page-file
                      &optional (name *default-template*))
  "Walk up from PAGE-FILE looking for NAME.lisp."
  (let ((filename (template-file-name name)))
    (labels
        ((walk (dir)
           (let ((candidate (merge-pathnames filename dir)))
             (cond
               ((probe-file candidate) candidate)
               ((uiop:pathname-equal
                 dir (truename *pages-dir*))
                (error "No template ~a found for ~a"
                       filename page-file))
               (t (walk (uiop:pathname-parent-directory-pathname
                         dir)))))))
      (walk (uiop:pathname-directory-pathname page-file)))))

(defun load-template (template-file)
  "Load a template file and return its function."
  (let ((key (namestring template-file)))
    (or (gethash key *template-fns*)
        (progn
          (load template-file)
          (or (gethash key *template-fns*)
              (error "deftemplate not found after loading ~a"
                     template-file))))))

(defmacro deftemplate (args &body body)
  "Define a template function for the current file.
ARGS: (content &key title description canonical head)."
  `(setf (gethash ,(namestring *load-pathname*)
                  *template-fns*)
         (lambda ,args
           (declare
            (ignorable
             ,@(remove-if
                (lambda (x)
                  (member x '(&key &optional &rest
                              &allow-other-keys)))
                args)))
           ,@body)))

(defun call-template (template-file content meta)
  "Invoke the template from TEMPLATE-FILE with CONTENT/META."
  (when *dev*
    (remhash (namestring template-file) *template-fns*))
  (let ((fn (load-template template-file)))
    (funcall fn content
             :title (getf meta :title)
             :description (getf meta :description)
             :canonical (getf meta :canonical)
             :head (getf meta :head))))

;;; ================================================================
;;; File reading
;;; ================================================================

(defun read-file (path)
  "Read file contents as a string."
  (uiop:read-file-string path))

;;; ================================================================
;;; Front matter
;;; ================================================================

(defun parse-front-matter (text)
  "Strip and parse a leading --- delimited front matter block.
Returns (values body-string plist-of-metadata)."
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
          (let ((key (intern
                      (string-upcase
                       (string-trim " " (subseq line 0 colon)))
                      :keyword))
                (value (string-trim
                        " " (subseq line (1+ colon)))))
            (setf result (list* key value result))))))))

(defun split-lines (str)
  (loop for start = 0 then (1+ pos)
        for pos = (position #\newline str :start start)
        for line = (string-trim
                    " "
                    (subseq str start (or pos (length str))))
        unless (string= line "") collect line
          while pos))

;;; ================================================================
;;; Markdown rendering
;;; ================================================================

(defun strip-invalid-xml-chars (s)
  "Remove characters illegal in XML 1.0."
  (with-output-to-string (out)
    (loop for c across s
          for cp = (char-code c)
          when (or (= cp #x9) (= cp #xA) (= cp #xD)
                   (<= #x20 cp #xD7FF)
                   (<= #xE000 cp #xFFFD)
                   (<= #x10000 cp #x10FFFF))
            do (write-char c out))))

(setf 3bmd-code-blocks:*code-blocks* t)

(defun md->html (md-string)
  "Render Markdown to HTML via 3bmd."
  (strip-invalid-xml-chars
   (with-output-to-string (s)
     (3bmd:parse-string-and-print-to-stream md-string s))))

;;; ================================================================
;;; DOM utilities
;;; ================================================================

(defun dom-serialize (dom)
  (plump:serialize dom nil))

(defun extract-dom-title (dom)
  (let ((h1s (clss:select "h1" dom)))
    (when (plusp (length h1s))
      (plump:render-text (aref h1s 0)))))

(defun extract-dom-description (dom)
  (let ((ps (clss:select "p" dom)))
    (when (plusp (length ps))
      (plump:render-text (aref ps 0)))))

;;; ================================================================
;;; Metadata extraction
;;; ================================================================

(defun extract-metadata (front-matter dom)
  "Build metadata plist from front-matter + DOM fallbacks."
  (list* :title (or (getf front-matter :title)
                    (extract-dom-title dom))
         :description (or (getf front-matter :description)
                          (extract-dom-description dom))
         front-matter))

;;; ================================================================
;;; Stage 1 -- raw text transforms (MD only, before md->html)
;;; ================================================================

(defvar *text-fns* (list)
  "Stage 1: raw markdown string -> string.")

(defun run-text-fns (text)
  (reduce (lambda (s f) (funcall f s))
          *text-fns* :initial-value text))

;;; ================================================================
;;; Stage 2 -- fragment DOM transforms (MD only, after md->html)
;;; ================================================================

(defvar *process-fns* (list)
  "Stage 2: fragment DOM after md->html, before template.")

(defun run-process (dom meta)
  (reduce (lambda (d f) (funcall f d meta))
          *process-fns* :initial-value dom))

;;; ================================================================
;;; Postprocessing -- full page DOM (all page types)
;;; ================================================================

(defvar *postprocess-fns* (list)
  "Postprocess transforms for the full page DOM.")

(defun run-postprocess (dom meta)
  (reduce (lambda (d f) (funcall f d meta))
          *postprocess-fns* :initial-value dom))

(defun preserve-pre-content (html thunk)
  "Extract <pre> blocks before postprocessing, restore after.
Plump escapes entities inside <pre> on re-serialize."
  (let ((originals (list))
        (idx 0))
    (let ((out (cl-ppcre:regex-replace-all
                "<pre[^>]*>.*?</pre>"
                html
                (lambda (match &rest args)
                  (declare (ignore args))
                  (push match originals)
                  (prog1
                      (format nil "BOG_PRE_~a_END" idx)
                    (incf idx)))
                :simple-calls t)))
      (let ((processed (funcall thunk out)))
        (loop for i from 0 below idx
              for original in (reverse originals)
              do (setf processed
                       (cl-ppcre:regex-replace
                        (format nil "BOG_PRE_~a_END" i)
                        processed
                        (cl-ppcre:regex-replace-all
                         "\\\\" original "\\\\\\\\"))))
        processed))))

(defun shift-heading (node)
  "Shift a heading element down one level: h1->h2 etc."
  (let* ((tag (plump:tag-name node))
         (level (parse-integer (subseq tag 1)
                               :junk-allowed t)))
    (when (and level (<= 1 level 5))
      (setf (plump:tag-name node)
            (format nil "h~a" (1+ level))))))

(defun normalize-headings (dom meta)
  "Shift content headings down one level within <main>."
  (declare (ignore meta))
  (let* ((mains (clss:select "main" dom))
         (scope (if (plusp (length mains))
                    (aref mains 0)
                    dom))
         (headings (clss:select "h1,h2,h3,h4,h5" scope)))
    (loop for i from 0 below (length headings)
          do (shift-heading (aref headings i))))
  dom)

(setf *postprocess-fns* (list #'normalize-headings))

;;; ================================================================
;;; HTML fragment detection and head hoisting
;;; ================================================================

(defun html-fragment-p (dom)
  "Returns T if DOM is a fragment, not a full document."
  (not (or (some #'plump:doctype-p (plump:children dom))
           (plusp (length (clss:select "html" dom))))))

(defun extract-frag-head (dom)
  "Extract and remove <head> from a fragment DOM.
Returns (values head-html-string title-string)."
  (let ((heads (clss:select "head" dom)))
    (if (zerop (length heads))
        (values nil nil)
        (let* ((head (aref heads 0))
               (titles (clss:select "title" head))
               (title (when (plusp (length titles))
                        (plump:render-text (aref titles 0))))
               (html (with-output-to-string (s)
                       (loop for child across (plump:children head)
                             do (plump:serialize child s)))))
          (plump:remove-child head)
          (values html title)))))

;;; ================================================================
;;; Page rendering
;;; ================================================================

(defun render-md-page (file)
  "MD pipeline: front-matter, text-fns, md->html, process,
template, postprocess."
  (or (cache-get file)
      (cache-set
       file
       (multiple-value-bind (body front-matter)
           (parse-front-matter (read-file file))
         (let* ((body (run-text-fns body))
                (frag-html (md->html body))
                (frag-dom (plump:parse frag-html))
                (meta (extract-metadata front-matter
                                        frag-dom))
                (frag-dom (run-process frag-dom meta))
                (frag-html (dom-serialize frag-dom))
                (tmpl (find-template
                       file
                       (getf meta :template
                             *default-template*)))
                (page (call-template tmpl frag-html meta))
                (page-dom (plump:parse page))
                (page-dom (run-postprocess page-dom meta)))
           (dom-serialize page-dom))))))

(defun extract-doctype-template (raw-html)
  "Extract template name from <!DOCTYPE +name>.
Returns (values template-name html-without-doctype)."
  (let ((scanner (cl-ppcre:create-scanner
                  "^\\s*<!doctype\\s+(\\+[^>]+)\\s*>\\s*"
                  :case-insensitive-mode t)))
    (multiple-value-bind (start end starts ends)
        (cl-ppcre:scan scanner raw-html)
      (if start
          (values (string-trim
                   " "
                   (subseq raw-html
                           (aref starts 0) (aref ends 0)))
                  (subseq raw-html end))
          (values *default-template* raw-html)))))

(defun render-html-page (file)
  "HTML pipeline: full docs served as-is, fragments get
template wrapping and postprocessing."
  (or (cache-get file)
      (cache-set
       file
       (let* ((raw (read-file file))
              (dom (plump:parse raw)))
         (if (not (html-fragment-p dom))
             (dom-serialize dom)
             (multiple-value-bind (tmpl-name frag-html)
                 (extract-doctype-template raw)
               (let ((dom (plump:parse frag-html)))
                 (multiple-value-bind (head-html title)
                     (extract-frag-head dom)
                   (let* ((meta (extract-metadata
                                 (when title
                                   (list :title title))
                                 dom))
                          (meta (if head-html
                                    (list* :head head-html
                                           meta)
                                    meta))
                          (tmpl (find-template
                                 file tmpl-name))
                          (page (call-template
                                 tmpl
                                 (dom-serialize dom)
                                 meta))
                          (page-dom (plump:parse page))
                          (page-dom (run-postprocess
                                     page-dom meta)))
                     (dom-serialize page-dom))))))))))

(defun render-lisp-page (file)
  "Lisp pages call their defpage fn -> (values content meta).
Template-wrapped and postprocessed."
  (flet ((call-page ()
           (load file)
           (multiple-value-bind (content meta)
               (funcall (page-fn file))
             (let* ((tmpl (find-template
                           file (page-template-name file)))
                    (page (call-template
                           tmpl content meta))
                    (page-dom (plump:parse page))
                    (page-dom (run-postprocess
                               page-dom meta)))
               (dom-serialize page-dom)))))
    (if (and *dev* (mutable-page-p file))
        (call-page)
        (or (cache-get file)
            (cache-set file (call-page))))))

(defun page-fn (file)
  "Derive the page function from the file's pathname-name."
  (let ((name (string-upcase (pathname-name file))))
    (or (find-symbol name "BOG-PAGES")
        (error "No function ~a found after loading ~a"
               name file))))

(defun render-file (file)
  (let ((type (pathname-type file)))
    (cond
      ((equal type "lisp") (render-lisp-page file))
      ((equal type "md") (render-md-page file))
      ((equal type "html") (render-html-page file))
      (t (error "Unknown file type: ~a" type)))))
