(asdf:defsystem #:bog
  :description "A personal website framework"
  :author "Ian"
  :license "MIT"
  :version "0.1.0"
  :depends-on (#:clack
               #:woo
               #:spinneret
               #:3bmd
               #:3bmd-ext-code-blocks
               #:colorize
               #:plump
               #:clss
               #:lquery
               #:trivia
               #:uiop
               #:cl-ppcre)
  :serial t
  :components ((:module "src"
                :components
                ((:file "package")
                 (:file "content")
                 (:file "handler")
                 (:file "tufte")
                 (:file "bog")))
               (:file "config")))
