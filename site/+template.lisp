(in-package #:bog-pages)

(bog:deftemplate (content &key title description canonical head)
    (spinneret:with-html-string
      (:doctype)
      (:html
       (:head
        (:meta :charset "utf-8")
        (:meta :name "viewport" :content "width=device-width,initial-scale=1")
        (:title (or title bog:*site-name*))
        (:link :rel "stylesheet" :href "/style.css")
        (when description
          (:meta :name "description" :content description))
        (when canonical
          (:link :rel "canonical" :href canonical))
        (when head
          (:raw head)))
       (:body
        (:header
         (:a :href "/" (:h1 bog:*site-name*)))
        (:main
         (:raw content))
        (:footer)))))
