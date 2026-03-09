(in-package #:bog)

;;; ==========================================================================
;;; Site configuration -- edit this file to configure your bog site
;;; ==========================================================================

;;; Basic site settings
(setf *site-name* "Bog")
(setf *port*      8080)
(setf *pages-dir* #p"site/")

(setf 3bmd-code-blocks:*renderer* :chroma)
(setf 3bmd-code-blocks:*chroma-style* "algol")
