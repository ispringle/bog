(in-package #:bog.tufte)

(defun citations (text)
  (cl-ppcre:regex-replace-all
   "(?s)--(?=[^\\s-])(.*?[^-])--"
   text
   "<cite>\\1</cite>"))

(defparameter *margin-marks* #("⁜" "†" "‡"))

(defun marginnotes (text)
  (let ((sidenote-index 0)
        (aside-index 0))
    (cl-ppcre:regex-replace-all
     "(?s)\\[\\^(aside|[a-z][a-z0-9-]*):\\s*(.*?)\\]"
     text
     (lambda (match kind note &rest ignored)
       (declare (ignore match ignored))
       (if (string= kind "aside")
           (let* ((n (incf aside-index))
                  (mark (aref *margin-marks*
                              (mod (1- n) (length *margin-marks*)))))
             (format nil
                     "<label for='mn-~a' class='margin-toggle'>~a</label>~
                <input type='checkbox' id='mn-~a' class='margin-toggle'/>~
                <span class='marginnote'>~a</span>"
                     n mark n note))
           (let ((n (incf sidenote-index)))
             (format nil
                     "<label for='sn-~a' class='margin-toggle sidenote-number'></label>~
                <input type='checkbox' id='sn-~a' class='margin-toggle'/>~
                <span class='sidenote'>~a</span>"
                     n n note))))
     :simple-calls t)))

(defun epigraphs (text)
  (cl-ppcre:regex-replace-all
   "(?m)(^>>\\s*.+(?:\\n>>\\s*.+)*(?:\\n>>>\\s*.+)?)"
   text
   (lambda (match block &rest ignored)
     (declare (ignore match ignored))
     (let ((lines (cl-ppcre:split "\\n" block)))
       (with-output-to-string (s)
         (write-string "<div class=\"epigraph\"><blockquote>" s)
         (dolist (line lines)
           (cl-ppcre:register-groups-bind (marker content)
               ("^(>>>?)\\s*(.+)$" line)
             (if (string= marker ">>>")
                 (format s "<footer>~a</footer>" content)
                 (format s "<p>~a</p>" content))))
         (write-string "</blockquote></div>" s))))
   :simple-calls t))
