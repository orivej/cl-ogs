;;;; ogs.asd

(asdf:defsystem #:ogs
  :serial t
  :depends-on (#:drakma
               #:cl-libxml2
               #:iterate
               #:external-program)
  :components ((:file "package")
               (:file "ogs")))

