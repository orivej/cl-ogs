;;;; ogs.lisp

(in-package #:ogs)

;; I set my credentials in my rc file
(defvar *login*)
(defvar *password*)
(defparameter *polling-interval* '(60 100)
  "A number of seconds between polling cycles or a list of minimum and maximum for a random number")

(defparameter *login-url* "http://www.online-go.com/login.php")
(defparameter *login-form*
  `(("userName" . ,*login*)
    ("validLoginAttempt" . "1")
    ("passWord" . ,*password*)
    ("robot" . "1")))
(defparameter *mygames-url* "http://www.online-go.com/games/mygames.php")

(defparameter *myturn-xpath* "//a[@class='main'][@href='/games/mygames.php']")
(defparameter *unread-xpath* "//a[@class='main'][@href='/messages/inbox.php']/../../td[2]")

(defvar *jar* (make-instance 'drakma:cookie-jar))

(defun request (&rest args)
  (apply #'drakma:http-request (append args (list :cookie-jar *jar*))))

(defun login ()
  "Receive a login cookie into *jar*"
  (request *login-url* :method :post :parameters *login-form*))

(defun parse-integer-in-brackets (str)
  "Parse 0 in 7(0)"
  (parse-integer (subseq str
                         (1+ (position #\( str))
                         (position #\) str))))

(defun main-loop ()
  (format t "Logging in…~%")
  (login)
  (iter
    (format t "Receiving mygames page…~%")
    (multiple-value-bind (body status headers uri)
        (request *mygames-url*)
      (declare (ignore status headers))
      (when (string= (puri:uri-path uri) "/index.php")
        (format t "We have been logged out.  Logging in…~%")
        (login)
        (next-iteration))
      (html:with-parse-html (mygames body)
          (let ((myturn (parse-integer (xpath:find-string mygames *myturn-xpath*)))
                (unread (parse-integer-in-brackets (xpath:find-string mygames *unread-xpath*))))
            (format t "My turn in ~a game~:p.  ~a message~:p unread.~%" myturn unread)
            (unless (zerop (+ myturn unread))
              (format t "Displaying notification…~%")
              (unless (zerop
                       (sb-ext:process-exit-code
                        (sb-ext:process-wait
                         (sb-ext:run-program
                          "/usr/bin/kdialog"
                          (list "--yes-label" "Continuer" "--no-label" "Annuler" "--title" "OGS" "--yesno"
                                (format nil "~{~a~^~%~}"
                                        (delete nil (list
                                                     (when (plusp myturn)
                                                       (format nil "C'est à vous de jouer dans ~a partie~:p." myturn))
                                                     (when (plusp unread)
                                                       (format nil "Vous aves ~a message~:p non lus." unread))))))
                          :output t :error :output))))
                (format t "Main loop aborted by user.")
                (finish))))))
    (let ((timeout (if (listp #1=*polling-interval*)
                       (+ (first #1#) (random (1+ (- (second #1#) (first #1#)))))
                       #1#)))
      (format t "Sleeping for ~a seconds until the next cycle…~%" timeout)
      (sleep timeout))))
