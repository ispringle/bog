(in-package #:bog-pages)

(bog:defpage (:mutable bog:*dev*)
  (let* ((blog-dir (merge-pathnames "blog/" bog:*pages-dir*))
         (posts    (sort (remove-if
                          (lambda (f)
                            (or (char= (char (pathname-name f) 0) #\+)
                                (string= (pathname-name f) "index")
                                (not (string= (pathname-type f) "md"))))
                          (uiop:directory-files blog-dir))
                         #'string> :key #'namestring)))
    (values
     (spinneret:with-html-string
       (:h1 "Blog")
       (if posts
           (:ul
            (dolist (post posts)
              (let ((name (pathname-name post)))
                (:li (:a :href (format nil "/blog/~a" name)
                         (string-capitalize (substitute #\space #\- name)))))))
           (:p "No posts yet."))
       (:p (:a :href "/" "← Home")))
     (list :title "Blog"))))
