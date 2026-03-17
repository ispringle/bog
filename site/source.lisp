(in-package #:bog-pages)

(bog:defpage (:template "+template")
  (let ((files '("bog.asd" "config.lisp"
                 "src/package.lisp" "src/content.lisp"
                 "src/tufte.lisp" "src/bog.lisp")))
    (values
     (spinneret:with-html-string
       (:h1 "Source")
       (dolist (f files)
         (let* ((path (merge-pathnames f (asdf:system-source-directory :bog)))
                (src  (uiop:read-file-string path)))
           (:h2 f)
           (:pre (:code src)))))
     (list :title "Source"))))
