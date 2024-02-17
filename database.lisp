;;;;
;;;; Now may the God of peace, who brought again from the dead the great
;;;; shepherd of the sheep with the blood of an eternal covenant, our Lord
;;;; Jesus, make you complete in every good work to do his will, working in you
;;;; that which is well pleasing in his sight, through Jesus Christ, to whom be
;;;; the glory forever and ever. Amen.
;;;;
;;;; -- Hebrews 13:20,21
;;;;

(ql:quickload "mito")

(mito:deftable kind ()
  ((name :col-type (:varchar 64))
   (path :col-type (:varchar 64)))
  (:unique-keys name))

(mito:deftable page ()
  ((title :col-type (:varchar 128))
   (author :col-type (:varchar 64))
   (published :col-type :datetime)
   (updated :col-type (or :datetime :null))
   (kind :col-type :kind)
   (file :col-type (:varchar 256))))

(mito:deftable pageContent ()
  ((pageId :col-type :page)
   (content :col-type :text)
   (sequence :col-type :integer)))

(defun connect ()
  (mito:connect-toplevel :sqlite3 :database-name "bog"))

(defun ensure-tables ()
  (mito:ensure-table-exists 'kind)
  (mito:ensure-table-exists 'page)
  (mito:ensure-table-exists 'pageContent))

(connect)
(ensure-tables)
