;;;; ogs.asd

(asdf:defsystem #:ogs
  :serial t
  :depends-on (#:drakma
               #:cl-libxml2
               #:iterate)
  :components ((:file "package")
               (:file "ogs")))

