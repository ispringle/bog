;;;;
;;;; Now may the God of peace, who brought again from the dead the great
;;;; shepherd of the sheep with the blood of an eternal covenant, our Lord
;;;; Jesus, make you complete in every good work to do his will, working in you
;;;; that which is well pleasing in his sight, through Jesus Christ, to whom be
;;;; the glory forever and ever. Amen.
;;;;
;;;; -- Hebrews 13:20,21
;;;;

(defpackage #:bog
  (:use :cl))

(in-package #:bog)
(ql:quickload :clack)
(ql:quickload :ningle)
(ql:quickload :spinneret)
(ql:quickload :mito)

(defvar app (make-instance 'ningle:app))
(defvar *public-dir* "public/")
(defvar *site-name* "Bog")

(push "x-" spinneret:*unvalidated-attribute-prefixes*) ; alpinejs
(push "@" spinneret:*unvalidated-attribute-prefixes*) ; alpinejs
(push "hx-" spinneret:*unvalidated-attribute-prefixes*) ; htmx

(defmacro when-yield (p)
  "A thin viel over `and` to make using it a bit more expressive when being used
  to check and return a conditional. When `p` returns truthy the value is
  returned, otherwise nil is returned."
  `(and ,p))

(defmacro when-let (bindings &body body)
  "Bind `bindings` and execute `body` when all bindings are true.
Example:
(when-let ((foo t) (bar nil))
  (list foo bar))"
  (let ((symbols (mapcar #'first bindings)))
    `(let ,bindings
       (when (and ,@symbols)
         ,@body))))

(defmacro if-let (bindings then else)
  "Bind `bindings` and execute `then` if all are true, `else` otherwise.
   Example:
   (if-let ((foo 1) (bar 2))
     (list foo bar)
     nil)"
  (let ((symbols (mapcar #'first bindings)))
    `(let ,bindings
       (if (and ,@symbols)
           ,then
           ,else))))

(defmacro when-path (path then)
  "When `path` exists, call `then` with `path` as the argument."
  `(when-let ((pth (probe-file ,path)))
     (funcall ,then pth)))

(defmacro with-page ((&key title) &body body)
  "Set root template, with specific `title` and template `body` inside root
document template."
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
      (:body
       (:header
        (:h* *site-name*))
       ,@body))))

(defun fetch-content (page)
  "Fetch a single html page or return an empty string if file does not exist in
  `*public-dir*`"
  (or 
   (let ((path (concatenate 'string *public-dir* page ".html")))
     (when-path path
                #'(lambda (path)
                    (with-open-file (in path)
                      (let ((contents (make-string (file-length in))))
                        (read-sequence contents in)
                        contents)))))
   ""))

(defun fetch-pages (dir)
  "Fetch a list of all pages in directory `dir` or nil"
  (let ((path (concatenate 'string *public-dir* dir "/")))
    (mapcar #'pathname-name
            (when-path path #'uiop:directory-files))))

(setf (ningle:route app "/") #'(lambda (params)
                                 (declare (ignore params))
                                 (with-page (:title "Hello World")
                                   (:header
                                    (:h* "Salutations"))
                                   (:article
                                    (:section
                                     (:div
                                      :x-data (:raw  "{open:false}")
                                      (:button :@click (:raw "open = !open") ("Click Me!"))
                                      (:span :x-show "open"
                                             :x-cloak t
                                             (:p "Hello, World!"))))
                                    (:raw (fetch-content "index")))
                                   (:footer (:p "Goodbye")))))

(setf (ningle:route app "/echo/:foo") #'(lambda (params) (cdr (assoc :foo params))))

(setf (ningle:route app "/:kind")
      #'(lambda (params)
          (let ((kind (cdr (assoc :kind params))))
            (with-page (:title kind)
              (:article
               (:raw (fetch-content kind))
               (:ul
                (dolist (page (fetch-pages kind))
                  (:li (:a :href (concatenate 'string "/" kind "/" page) page)))))))))

(setf (ningle:route app "/:kind/:page")
      #'(lambda (params)
          (let* ((page (cdr (assoc :page params)))
                 (kind (cdr (assoc :kind params)))
                 (path (concatenate 'string kind "/" page)))
            (with-page (:title page)
              (:header
               (:h* page))
              (:article
               (:p (:raw (fetch-content path))))))))

(clack:clackup app)

