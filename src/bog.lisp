(in-package #:bog)

;;; ================================================================
;;; Router
;;; ================================================================

(defvar *mime-types*
  '(("css"   . "text/css")
    ("js"    . "application/javascript")
    ("json"  . "application/json")
    ("xml"   . "application/xml")
    ("svg"   . "image/svg+xml")
    ("png"   . "image/png")
    ("jpg"   . "image/jpeg")
    ("jpeg"  . "image/jpeg")
    ("gif"   . "image/gif")
    ("webp"  . "image/webp")
    ("woff"  . "font/woff")
    ("woff2" . "font/woff2")
    ("ico"   . "image/x-icon")
    ("pdf"   . "application/pdf")
    ("mp4"   . "video/mp4")
    ("txt"   . "text/plain")
    ("html"  . "text/html"))
  "Extension to MIME type mapping for static assets.")

(defvar *text-extensions*
  '("css" "js" "json" "xml" "svg" "html" "txt")
  "Asset extensions served as text (vs binary).")

(defun respond (body &key (status 200)
                       (content-type "text/html"))
  (list status
        (list :content-type content-type)
        (list body)))

(defun render-404 ()
  (let ((file (or (probe-file
                   (merge-pathnames "404.lisp" *pages-dir*))
                  (probe-file
                   (merge-pathnames "404.md" *pages-dir*))
                  (probe-file
                   (merge-pathnames "404.html" *pages-dir*)))))
    (if file
        (render-file file)
        (spinneret:with-html-string
          (:doctype)
          (:html
           (:head (:meta :charset "utf-8")
                  (:title "Not Found"))
           (:body (:h1 "404")
                  (:p "Page not found.")))))))

;;; ================================================================
;;; Static assets
;;; ================================================================

(defun mime-type (extension)
  "Look up MIME type for EXTENSION, default octet-stream."
  (or (cdr (assoc extension *mime-types* :test #'equal))
      "application/octet-stream"))

(defun text-asset-p (extension)
  (member extension *text-extensions* :test #'equal))

(defun serve-asset (file)
  "Serve a static asset with appropriate content type."
  (let* ((type (pathname-type file))
         (ct (mime-type type))
         (body (if (text-asset-p type)
                   (read-file file)
                   (with-open-file (in file
                                       :element-type
                                       '(unsigned-byte 8))
                     (let ((buf (make-array
                                 (file-length in)
                                 :element-type
                                 '(unsigned-byte 8))))
                       (read-sequence buf in)
                       buf)))))
    (list 200 (list :content-type ct) (list body))))

(defun safe-path-p (file)
  "Returns T if FILE resolves to a path under *pages-dir*.
Guards against directory traversal attacks."
  (let ((resolved (probe-file file)))
    (and resolved
         (uiop:subpathp resolved (truename *pages-dir*)))))

(defun find-asset (path-info)
  "Resolve a URL path to a non-page file in *pages-dir*."
  (let* ((base (string-left-trim "/" path-info))
         (parts (remove ""
                        (uiop:split-string base
                                           :separator "/")
                        :test #'equal))
         (dirs (butlast parts))
         (name (car (last parts)))
         (dir (make-pathname
               :directory (list* :relative dirs)))
         (file (when name
                 (merge-pathnames
                  (make-pathname
                   :name (pathname-name name)
                   :type (pathname-type name))
                  (merge-pathnames dir *pages-dir*)))))
    (when (and file
               (safe-path-p file)
               (not (member (pathname-type file)
                            '("md" "html" "lisp")
                            :test #'equal)))
      (probe-file file))))

;;; ================================================================
;;; Request dispatch
;;; ================================================================

(defun app (env)
  (let* ((method (getf env :request-method))
         (path (getf env :path-info))
         (page (find-page path))
         (asset (unless page (find-asset path))))
    ;; Ensure lisp files are loaded so handler-p works
    ;; on first request
    (when (and page
               (equal (pathname-type page) "lisp"))
      (ensure-loaded page))
    (cond
      ;; Handler files get env directly, any method
      ((and page (handler-p page))
       (render-handler page env))
      ;; Regular pages only serve GET/HEAD
      ((and page (member method '(:get :head)))
       (respond (render-file page)))
      ;; Non-GET to a regular page -> 405
      (page
       (list 405
             '(:content-type "text/plain"
               :allow "GET, HEAD")
             '("Method not allowed")))
      ;; Static assets (GET only)
      ((and asset (member method '(:get :head)))
       (serve-asset asset))
      ;; Nothing matched
      (t (respond (render-404) :status 404)))))

;;; ================================================================
;;; Entry points
;;; ================================================================

(defvar *server* nil
  "Handle to the running Clack server.")

(defun serve (&key (port *port*) (dev t))
  "Start the bog server.
DEV T: mutable pages bypass cache.
DEV NIL: all pages cached, cache warmed at startup."
  (when *server*
    (warn "bog: server already running; call (bog:stop) first")
    (return-from serve *server*))
  (setf *dev* dev)
  (cache-clear)
  (unless dev (warm-cache *pages-dir*))
  (setf *server*
        (clack:clackup #'app
                       :server :woo
                       :port port
                       :use-default-middlewares dev)))

(defun stop ()
  "Stop the running bog server."
  (when *server*
    (clack:stop *server*)
    (setf *server* nil)))

(defun warm-cache (dir)
  "Pre-render static pages into the cache.
Skips +prefixed files, handlers, and mutable pages."
  (dolist (file (uiop:directory-files dir))
    (let ((type (pathname-type file))
          (name (pathname-name file)))
      (unless (or (zerop (length name))
                  (char= (char name 0) #\+))
        (cond
          ((member type '("md" "html") :test #'equal)
           (render-file file))
          ((equal type "lisp")
           (ensure-loaded file)
           (when (and (not (handler-p file))
                      (not (mutable-page-p file)))
             (render-file file)))))))
  (dolist (subdir (uiop:subdirectories dir))
    (warm-cache subdir)))

(defun generate (&key (output #p"dist/")
                   (warn-mutable t))
  "Walk pages/ and write a static dist/ tree.
Binds *dev* nil locally so the running dev server
is unaffected."
  (let ((*dev* nil))
    (uiop:ensure-all-directories-exist (list output))
    (walk-and-generate *pages-dir* output
                       :warn-mutable warn-mutable)))

(defun walk-and-generate (src-dir out-dir
                          &key warn-mutable)
  (dolist (file (uiop:directory-files src-dir))
    (let* ((type (pathname-type file))
           (name (pathname-name file))
           (out-html
             (if (string= name "index")
                 (merge-pathnames
                  (make-pathname :name "index"
                                 :type "html")
                  out-dir)
                 (merge-pathnames
                  (make-pathname :name "index"
                                 :type "html")
                  (merge-pathnames
                   (make-pathname
                    :directory (list :relative name))
                   out-dir))))
           (out-copy
             (merge-pathnames
              (make-pathname :name name :type type)
              out-dir)))
      (cond
        ;; Skip empty names and + prefixed files
        ((or (zerop (length name))
             (char= (char name 0) #\+))
         nil)
        ;; Skip handlers in static generation
        ((and (equal type "lisp")
              (progn (ensure-loaded file)
                     (handler-p file)))
         (when warn-mutable
           (format t "~&; bog: skipping handler ~a~%" file)))
        ;; Skip mutable pages
        ((and (equal type "lisp") (mutable-page-p file))
         (when warn-mutable
           (format t "~&; bog: skipping mutable page ~a~%"
                   file)))
        ;; Render pages
        ((member type '("md" "html" "lisp")
                 :test #'equal)
         (ensure-directories-exist out-html)
         (with-open-file (out out-html
                              :direction :output
                              :if-exists :supersede)
           (write-string (render-file file) out)))
        ;; Copy static assets
        (t
         (ensure-directories-exist out-copy)
         (uiop:copy-file file out-copy)))))
  (dolist (subdir (uiop:subdirectories src-dir))
    (let ((sub-out
            (merge-pathnames
             (make-pathname
              :directory
              (list :relative
                    (car (last
                          (pathname-directory subdir)))))
             out-dir)))
      (walk-and-generate subdir sub-out
                         :warn-mutable warn-mutable))))

(defun build (&key (output #p"bog-site")
                (port *port*))
  "Compile bog + site into a standalone SBCL executable."
  #+sbcl
  (sb-ext:save-lisp-and-die
   output
   :toplevel (lambda ()
               (let ((env-port (uiop:getenv "BOG_PORT")))
                 (serve :port (if env-port
                                  (parse-integer env-port)
                                  port)
                        :dev nil)))
   :executable t
   :compression t)
  #-sbcl
  (error "bog:build requires SBCL"))
