(in-package #:bog-pages)

(bog:defpage (:mutable bog:*dev* :template "+template")
  (values
   (spinneret:with-html-string
     (:h1 "Mutable Page")
     (:p "This page is declared " (:code "(:mutable bog:*dev*)") ". It bypasses the cache and re-renders on every request in dev.")
     (:h2 "Live values")
     (:dl
      (:dt "Render time")
      (:dd (multiple-value-bind (s m h) (decode-universal-time (get-universal-time))
             (format nil "~2,'0d:~2,'0d:~2,'0d" h m s)))
      (:dt "Random number")
      (:dd (write-to-string (random 1000000))))
     (:p (:a :href "/" "← Home")))
   (list :title "Mutable Page")))
