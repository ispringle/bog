(in-package #:bog)

;;; ================================================================
;;; Handler definition (API / non-HTML endpoints)
;;; ================================================================
;;;
;;; Handlers are lisp files that receive the full Clack env and
;;; return a raw Clack response. No template wrapping, no
;;; postprocessing, no caching.
;;;
;;; A handler file contains a single defhandler form whose body
;;; evaluates to a function of one argument (env). The router
;;; calls that function directly.
;;;
;;; Example handler file (site/api/submit.lisp):
;;;
;;;   (bog:defhandler
;;;     (lambda (env)
;;;       (case (getf env :request-method)
;;;         (:post
;;;          (let ((body (read-request-body env)))
;;;            (bog:respond-json
;;;             (format nil "{\"ok\":true,\"got\":~S}" body))))
;;;         (t (bog:respond-plain "Method not allowed"
;;;                               :status 405)))))
;;;
;;; The file resolves via normal find-page routing, so
;;; site/api/submit.lisp handles /api/submit for any method.
;;;
;;; --- Symbol interning ---
;;;
;;; Both defpage and defhandler intern a function into the
;;; BOG-PAGES package derived from the file's pathname-name.
;;; To avoid collisions with symbols inherited from CL (e.g.
;;; a file named quote.lisp would shadow CL:QUOTE), names are
;;; prefixed: PAGE/ for defpage, HANDLER/ for defhandler.
;;;
;;;   site/about.lisp       -> BOG-PAGES::PAGE/ABOUT
;;;   site/api/quote.lisp   -> BOG-PAGES::HANDLER/QUOTE
;;;   site/blog/index.lisp  -> BOG-PAGES::PAGE/INDEX
;;;
;;; page-fn resolves a file to its function by checking
;;; HANDLER/ first, then PAGE/. ensure-loaded checks both
;;; prefixes to decide whether a file needs loading.

;;; ================================================================
;;; Registry
;;; ================================================================

(defvar *handlers* (make-hash-table :test #'equal)
  "Files registered via defhandler. Keyed by namestring.")

(defun handler-p (file)
  "Returns T if FILE was registered as a handler."
  (gethash (namestring file) *handlers*))

;;; ================================================================
;;; defhandler macro
;;; ================================================================

(defmacro defhandler (&body body)
  "Define a raw handler in the current file context.
BODY must evaluate to a function (lambda (env) ...) that
returns a Clack response: (list status headers body-list).

Unlike defpage, handlers are never template-wrapped, cached,
or postprocessed. They receive the full Clack env and can
handle any HTTP method."
  (let ((fn-name (intern
                  (format nil "HANDLER/~a"
                          (string-upcase
                           (pathname-name *load-pathname*)))
                  "BOG-PAGES")))
    `(progn
       (setf (gethash ,(namestring *load-pathname*)
                      *handlers*)
             t)
       (defun ,fn-name ()
         ,@body))))

;;; ================================================================
;;; Loading and invocation
;;; ================================================================

(defun ensure-loaded (file)
  "Load FILE if its page/handler fn isn't yet defined.
Ensures defhandler/defpage registration happens before the
router checks handler-p."
  (let ((name (string-upcase (pathname-name file))))
    (unless (or (find-symbol (format nil "PAGE/~a" name)
                             "BOG-PAGES")
                (find-symbol (format nil "HANDLER/~a" name)
                             "BOG-PAGES"))
      (load file))))

(defun render-handler (file env)
  "Load and invoke a defhandler file with ENV.
Always reloads in dev mode to pick up edits."
  (when *dev*
    (load file))
  (unless *dev*
    (ensure-loaded file))
  (funcall (funcall (page-fn file)) env))

;;; ================================================================
;;; Response helpers
;;; ================================================================

(defun respond-json (body &key (status 200))
  "Return a JSON Clack response."
  (list status
        (list :content-type "application/json")
        (list body)))

(defun respond-plain (body &key (status 200))
  "Return a plain text Clack response."
  (list status
        (list :content-type "text/plain")
        (list body)))

(defun read-request-body (env)
  "Read the request body from a Clack env as a string.
Returns an empty string if no body is present."
  (let ((stream (getf env :raw-body)))
    (if stream
        (let ((len (getf env :content-length)))
          (if len
              (let ((buf (make-string len)))
                (read-sequence buf stream)
                buf)
              ;; No content-length, read until EOF
              (with-output-to-string (out)
                (loop for line = (read-line stream nil nil)
                      while line
                      do (write-line line out)))))
        "")))
