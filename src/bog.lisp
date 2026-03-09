(in-package #:bog)

;;; =========================================================================
;;; Router
;;; =========================================================================

(defun respond (body &key (status 200) (content-type "text/html"))
  (list status (list :content-type content-type) (list body)))

(defun render-404 ()
  (let ((file (or (probe-file (merge-pathnames "404.lisp" *pages-dir*))
                  (probe-file (merge-pathnames "404.md"   *pages-dir*))
                  (probe-file (merge-pathnames "404.html" *pages-dir*)))))
    (if file
        (render-file file)
        (spinneret:with-html-string
          (:doctype)
          (:html
           (:head (:meta :charset "utf-8") (:title "Not Found"))
           (:body (:h1 "404") (:p "Page not found.")))))))

(defun serve-asset (file)
  "Serve a static asset file with appropriate content type.
Text assets (css, js, svg) are returned as strings; binary as byte vectors."
  (let* ((type (pathname-type file))
         (textp (member type '("css" "js" "svg" "html" "txt") :test #'equal))
         (ct (cond ((equal type "css") "text/css")
                   ((equal type "js") "application/javascript")
                   ((equal type "svg") "image/svg+xml")
                   ((equal type "png") "image/png")
                   ((member type '("jpg" "jpeg") :test #'equal) "image/jpeg")
                   ((equal type "gif") "image/gif")
                   ((equal type "webp") "image/webp")
                   ((equal type "woff") "font/woff")
                   ((equal type "woff2") "font/woff2")
                   ((equal type "ico") "image/x-icon")
                   (t "application/octet-stream")))
         (body (if textp
                   (read-file file)
                   (with-open-file (in file :element-type '(unsigned-byte 8))
                     (let ((buf (make-array
                                 (file-length in)
                                 :element-type '(unsigned-byte 8))))
                       (read-sequence buf in)
                       buf)))))
    (list 200 (list :content-type ct) (list body))))

(defun find-asset (path-info)
  "Resolve a URL path to a non-page file in *pages-dir*."
  (let* ((base  (string-left-trim "/" path-info))
         (parts (remove "" (uiop:split-string base :separator "/") :test #'equal))
         (dirs  (butlast parts))
         (name  (car (last parts)))
         (dir   (make-pathname :directory (list* :relative dirs)))
         (file  (merge-pathnames (make-pathname :name (pathname-name name)
                                                :type (pathname-type name))
                                 (merge-pathnames dir *pages-dir*))))
    (when (and name (probe-file file)
               (not (member (pathname-type file) '("md" "html" "lisp") :test #'equal)))
      file)))

(defun app (env)
  (let* ((method (getf env :request-method))
         (path   (getf env :path-info))
         (page   (find-page path))
         (asset  (unless page (find-asset path))))
    (cond
      ((eq method :post)  (respond (handle-post path env)))
      (page               (respond (render-file page)))
      (asset              (serve-asset asset))
      (t                  (respond (render-404) :status 404)))))

(defun handle-post (path env)
  (declare (ignore path env))
  (render-404))

;;; =========================================================================
;;; Entry points
;;; =========================================================================

(defvar *server* nil
  "Handle to the running Clack server, set by SERVE, cleared by STOP.")

(defun serve (&key (port *port*) (dev t))
  "Start the bog server.
DEV T (default): mutable pages bypass cache, errors printed verbosely.
DEV NIL: *dev* is nil so mutable pages are cached; cache populated at startup."
  (when *server*
    (warn "bog: server already running; call (bog:stop) first")
    (return-from serve *server*))
  (setf *dev* dev)
  (cache-clear)
  (when (not dev)
    (warm-cache *pages-dir*))
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
  "Pre-render all static pages into the cache at startup."
  (dolist (file (uiop:directory-files dir))
    (let ((type (pathname-type file)))
      (when (member type '("md" "html") :test #'equal)
        (render-file file))
      (when (and (equal type "lisp")
                 (not (mutable-page-p file)))
        (render-file file))))
  (dolist (subdir (uiop:subdirectories dir))
    (warm-cache subdir)))

(defun generate (&key (output #p"dist/") (warn-mutable t))
  "Walk pages/ and write a static dist/ tree.
With *dev* nil, mutable pages are cached like static ones so all pages compile."
  (setf *dev* nil)
  (uiop:ensure-all-directories-exist (list output))
  (walk-and-generate *pages-dir* output :warn-mutable warn-mutable))

(defun walk-and-generate (src-dir out-dir &key warn-mutable)
  (dolist (file (uiop:directory-files src-dir))
    (let* ((type     (pathname-type file))
           (name     (pathname-name file))
           (out-html (if (string= name "index")
                         (merge-pathnames (make-pathname :name "index" :type "html") out-dir)
                         (merge-pathnames (make-pathname :name "index" :type "html")
                                          (merge-pathnames (make-pathname :directory (list :relative name))
                                                           out-dir))))
           (out-copy (merge-pathnames (make-pathname :name name :type type) out-dir)))
      (cond
        ((char= (char name 0) #\+) nil)
        ((and (equal type "lisp") (mutable-page-p file))
         (when warn-mutable
           (format t "~&; bog: skipping mutable page ~a~%" file)))
        ((member type '("md" "html" "lisp") :test #'equal)
         (ensure-directories-exist out-html)
         (with-open-file (out out-html :direction :output :if-exists :supersede)
           (write-string (render-file file) out)))
        (t
         (ensure-directories-exist out-copy)
         (uiop:copy-file file out-copy)))))
  (dolist (subdir (uiop:subdirectories src-dir))
    (let ((sub-out (merge-pathnames
                    (make-pathname :directory
                                   (list :relative (car (last (pathname-directory subdir)))))
                    out-dir)))
      (walk-and-generate subdir sub-out :warn-mutable warn-mutable))))

(defun build (&key (output #p"bog-site") (port *port*))
  "Compile bog + site into a standalone executable.
The binary starts the Woo server when run, reading PORT from environment
or falling back to *port*."
  #+sbcl
  (sb-ext:save-lisp-and-die
   output
   :toplevel (lambda ()
               (let ((env-port (uiop:getenv "BOG_PORT")))
                 (serve :port (if env-port (parse-integer env-port) port)
                        :dev nil)))
   :executable t
   :compression t)
  #-sbcl
  (error "bog:build requires SBCL"))
