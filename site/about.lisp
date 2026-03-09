(in-package #:bog-pages)

(bog:defpage ()
  (values
   (spinneret:with-html-string
     (:h1 "About")
     (:p "This is a static " (:code ".lisp") " page rendered via "
         (:code "defpage") " with no " (:code ":mutable") " flag.")
     (:p "Lisp pages return " (:code "(values content meta)") " — the template wraps the content.")
     (:h2 "What to verify")
     (:ul
      (:li "Title is \"About\" (from meta plist)")
      (:li "The bog layout is applied via " (:code "+template.lisp"))
      (:li "Heading normalization applies"))
     (:p (:a :href "/" "← Home")))
   (list :title "About" :description "About this bog test site")))
