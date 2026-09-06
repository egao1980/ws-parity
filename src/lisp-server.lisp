(in-package #:ws-parity)

(defvar *lisp-server-deflate-seen* nil
  "T when the last Lisp accept negotiated permessage-deflate.")

(defun %bind-lisp ()
  (unless (find-package :ws-backend-websocket-driver)
    (asdf:load-system "ws-backend-websocket-driver"))
  (let ((maker (find-symbol "MAKE-WEBSOCKET-DRIVER-BACKEND"
                            :ws-backend-websocket-driver)))
    (setf ws-protocol:*ws-backend* (funcall maker))))

(defun %echo-message (conn msg)
  (if (stringp msg)
      (ws-protocol:send-text conn msg)
      (ws-protocol:send-binary conn msg)))

(defun %deflate-p (conn)
  (let ((fn (and (find-package :ws-backend-websocket-driver)
                 (find-symbol "CONNECTION-DEFLATE-P"
                              :ws-backend-websocket-driver))))
    (and fn (funcall fn conn))))

(defun start-lisp-server (&key (port (%free-port)) ssl compression
                            (transport :http/1.1))
  (%bind-lisp)
  (setf *lisp-server-deflate-seen* nil)
  (let* ((closed nil)
         (cert (when ssl (driver-cert "server.crt")))
         (key (when ssl (driver-cert "server.key")))
         (server (ws-protocol:make-ws-server
                  ws-protocol:*ws-backend*
                  :host "127.0.0.1"
                  :port port
                  :path "/echo"
                  :transport transport
                  :ssl-cert cert
                  :ssl-key key
                  :compression compression
                  :on-connect
                  (lambda (conn)
                    (when (%deflate-p conn)
                      (setf *lisp-server-deflate-seen* t))
                    (ws-protocol:on-event
                     conn :message
                     (lambda (msg) (%echo-message conn msg)))
                    (ws-protocol:on-event
                     conn :close
                     (lambda (&key code reason)
                       (declare (ignore reason))
                       (setf closed code)))))))
    (ws-protocol:start-ws-server server)
    (sleep 0.35)
    (values server port
            (format nil "~A://127.0.0.1:~a/echo"
                    (if (or ssl (eq transport :http/2)) "wss" "ws")
                    port)
            (lambda () closed))))

(defun stop-lisp-server (server)
  (when server
    (ignore-errors (ws-protocol:stop-ws-server server))))

(defun call-with-lisp-server (fn &key ssl compression (transport :http/1.1)
                                   (stop t))
  (multiple-value-bind (server port url close-fn)
      (start-lisp-server :ssl ssl :compression compression
                         :transport transport)
    (declare (ignore port))
    (unwind-protect (funcall fn url close-fn)
      (when stop
        (stop-lisp-server server)))))

(defun h2-available-p ()
  (and (ignore-errors (asdf:load-system "ws-backend-websocket-driver") t)
       (let ((pred (find-symbol "H2-WS-SERVER-AVAILABLE-P"
                                :ws-backend-websocket-driver)))
         (and pred (funcall pred)))
       (ignore-errors (asdf:load-system "http-backend-async") t)
       (ignore-errors (asdf:load-system "event-backend-libuv") t)
       (probe-file (driver-cert "server.crt"))
       (probe-file (driver-cert "server.key"))))
