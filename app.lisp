(defpackage #:bog
  (:use :cl))

(in-package #:bog)
(ql:quickload :clack)
(ql:quickload :ningle)
(ql:quickload :spinneret)
(ql:quickload :spinneret/ps)

(defvar app (make-instance 'ningle:app))
(defvar *public-dir* "public/")

(push "x-" spinneret:*unvalidated-attribute-prefixes*)
(push "@" spinneret:*unvalidated-attribute-prefixes*)
(push "hx-" spinneret:*unvalidated-attribute-prefixes*)


(defmacro with-page ((&key title) &body body)
  `(spinneret:with-html-string
     (:doctype)
     (:html
      (:head
       (:meta :charset "utf-8")
       (:meta :name "viewport" :content "width=device-width,initial-scale=1")
       (:script :defer t :src "//unpkg.com/alpinejs")
       (:script :defer t :src "//unpkg.com/htmx.org")
       (:style "[x-cloak]{display:none !important;}")
       (:title ,title))
      (:body ,@body))))

(defun fetch-post (post)
  (with-open-file (in (concatenate 'string *public-dir* "post/" post))
    (let ((contents (make-string (file-length in))))
      (read-sequence contents in)
      contents)))

(setf (ningle:route app "/hello") #'(lambda (params)
                                      (declare (ignore params))
                                      (with-page (:title "Hello World")
                                        (:header
                                         (:h1 "Salutations"))
                                        (:article
                                         (:section
                                          (:div
                                           :x-data (:raw  "{open:false}")
                                           (:button :@click (:raw "open = !open") ("Click Me!"))
                                           (:span :x-show "open"
                                                  :x-cloak t
                                                  (:p "Hello, World!")))))
                                        (:footer (:p "Goodbye")))))

(setf (ningle:route app "/echo/:foo") #'(lambda (params) (cdr (assoc :foo params))))

(setf (ningle:route app "/posts")
      #'(lambda (params)
          (declare (ignore params))
          (with-page (:title "Posts")
            (:header
             (:h1 "Posts"))
            (:article
             (:ul
              (:li "Foo")
              (:li "Bar"))))))


(setf (ningle:route app "/post/:post")
      #'(lambda (params)
          (let ((post  (cdr (assoc :post params))))
            (with-page (:title post)
              (:header
               (:h1 post))
              (:article
               (:p (fetch-post post)))))))

(clack:clackup app)
