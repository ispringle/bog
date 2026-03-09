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
  (:use #:cl)
  (:export
   ;; config
   #:*pages-dir*
   #:*site-name*
   #:*port*
   #:*dev*
   ;; page definition
   #:defpage
   #:deftemplate
   ;; pipeline
   #:*text-fns*
   #:*process-fns*
   #:*postprocess-fns*
   #:normalize-headings
   #:cache-clear
   ;; entry points
   #:*server*
   #:serve
   #:stop
   #:generate
   #:build))

;;; Package for user-authored page functions
(defpackage #:bog-pages
  (:use #:cl #:bog))

(defpackage #:bog.tufte
  (:use #:cl)
  (:export
   #:citations
   #:marginnotes
   #:epigraphs))
