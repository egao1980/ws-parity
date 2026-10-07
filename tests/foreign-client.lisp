(in-package #:ws-parity/tests)

(defun check-foreign-client (client-kind)
  (with-peer-server (url :lisp close-fn)
    (testing (format nil "~a → lisp echo" client-kind)
      (ok (equal "ping-echo" (foreign-echo client-kind url "ping-echo"))))
    (testing (format nil "~a → lisp close 1000" client-kind)
      (ok (eql 1000 (foreign-close-code client-kind url)))
      (ok (wait-until (lambda () (normal-close-code-p (funcall close-fn)))
                      :timeout 3.0)
          (format nil "lisp server close code ~s" (funcall close-fn))))))

(deftest node-client-lisp-server
  (if (peer-available-p :node)
      (check-foreign-client :node)
      (skip "node peer not available")))

(deftest python-client-lisp-server
  (if (peer-available-p :python)
      (check-foreign-client :python)
      (skip "python peer not available")))

(defun check-foreign-binary (client-kind)
  (with-peer-server (url :lisp)
    (ok (equal "bin-echo" (foreign-echo client-kind url "bin-echo" :binary t))
        (format nil "~a → lisp binary echo" client-kind))))

(deftest node-binary-lisp-server
  (if (peer-available-p :node)
      (check-foreign-binary :node)
      (skip "node peer not available")))

(deftest python-binary-lisp-server
  (if (peer-available-p :python)
      (check-foreign-binary :python)
      (skip "python peer not available")))

(defun check-foreign-deflate (client-kind)
  (with-peer-server (url :lisp nil :compression :deflate)
    (ok (equal "deflate-ping" (foreign-echo client-kind url "deflate-ping"))
        (format nil "~a → lisp permessage-deflate echo" client-kind))
    (ok *lisp-server-deflate-seen*
        (format nil "~a → lisp negotiated permessage-deflate" client-kind))))

(deftest node-deflate-lisp-server
  (if (peer-available-p :node)
      (check-foreign-deflate :node)
      (skip "node peer not available")))

(deftest python-deflate-lisp-server
  (if (peer-available-p :python)
      (check-foreign-deflate :python)
      (skip "python peer not available")))

(defun check-foreign-wss (client-kind)
  (with-peer-server (url :lisp nil :ssl t)
    (ok (equal "wss-ping" (foreign-echo client-kind url "wss-ping"))
        (format nil "~a → lisp WSS" client-kind))))

(deftest node-wss-lisp-server
  (if (and (peer-available-p :node)
           (probe-file (driver-cert "server.crt")))
      (check-foreign-wss :node)
      (skip "node peer or certs not available")))

(deftest python-wss-lisp-server
  (if (and (peer-available-p :python)
           (probe-file (driver-cert "server.crt")))
      (check-foreign-wss :python)
      (skip "python peer or certs not available")))
