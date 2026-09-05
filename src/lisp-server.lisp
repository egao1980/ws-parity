(in-package #:ws-parity)

(defun %bind-lisp ()
  (unless (find-package :ws-backend-websocket-driver)
    (asdf:load-system "ws-backend-websocket-driver"))
  (let ((maker (find-symbol "MAKE-WEBSOCKET-DRIVER-BACKEND"
                            :ws-backend-websocket-driver)))
    (setf ws-protocol:*ws-backend* (funcall maker))))

(defun start-lisp-server (&key (port (%free-port)))
  (%bind-lisp)
  (let* ((closed nil)
         (server (ws-protocol:make-ws-server
                  ws-protocol:*ws-backend*
                  :host "127.0.0.1"
                  :port port
                  :path "/echo"
                  :transport :http/1.1
                  :on-connect
                  (lambda (conn)
                    (ws-protocol:on-event
                     conn :message
                     (lambda (msg)
                       (ws-protocol:send-text conn msg)))
                    (ws-protocol:on-event
                     conn :close
                     (lambda (&key code reason)
                       (declare (ignore reason))
                       (setf closed code)))))))
    (ws-protocol:start-ws-server server)
    (sleep 0.25)
    (values server port (format nil "ws://127.0.0.1:~a/echo" port)
            (lambda () closed))))

(defun stop-lisp-server (server)
  (when server
    (ignore-errors (ws-protocol:stop-ws-server server))))

(defun call-with-lisp-server (fn)
  (multiple-value-bind (server port url close-fn)
      (start-lisp-server)
    (declare (ignore port))
    (unwind-protect (funcall fn url close-fn)
      (stop-lisp-server server))))
