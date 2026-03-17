(in-package #:bog-pages)

(defvar *quotes*
  '(("The only way to do great work is to love what you do."
     . "Steve Jobs")
    ("Simplicity is the ultimate sophistication."
     . "Leonardo da Vinci")
    ("Programs must be written for people to read."
     . "Abelson & Sussman")
    ("The best way to predict the future is to invent it."
     . "Alan Kay")
    ("Premature optimization is the root of all evil."
     . "Donald Knuth")
    ("Talk is cheap. Show me the code."
     . "Linus Torvalds")
    ("Any sufficiently advanced technology is indistinguishable from magic."
     . "Arthur C. Clarke")
    ("First, solve the problem. Then, write the code."
     . "John Johnson")))

(bog:defhandler
  (lambda (env)
    (declare (ignore env))
    (let* ((quote (nth (random (length *quotes*)) *quotes*))
           (text (car quote))
           (author (cdr quote)))
      (bog:respond
       (spinneret:with-html-string
         (:blockquote
          (:p text)
          (:footer "— " author)))
       :content-type "text/html"))))
