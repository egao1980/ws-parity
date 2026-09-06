(in-package #:ws-parity/tests)

(defun check-lisp-client (server-kind)
  (with-peer-server (url server-kind close-fn)
    (testing (format nil "lisp → ~a echo" server-kind)
      (ok (equal "ping-echo" (lisp-echo url "ping-echo"))))
    (testing (format nil "lisp → ~a close" server-kind)
      (lisp-close-code url)
      (ok (wait-until (lambda () (normal-close-code-p (funcall close-fn)))
                      :timeout 3.0)
          (format nil "peer close code ~s" (funcall close-fn))))))

(deftest lisp-client-lisp-server
  (check-lisp-client :lisp))

(deftest lisp-client-node-server
  (if (peer-available-p :node)
      (check-lisp-client :node)
      (skip "node peer not available")))

(deftest lisp-client-python-server
  (if (peer-available-p :python)
      (check-lisp-client :python)
      (skip "python peer not available")))

(defun check-lisp-binary (server-kind)
  (with-peer-server (url server-kind)
    (ok (equalp (lisp-binary-echo url "bin-echo") (ascii-octets "bin-echo"))
        (format nil "lisp → ~a binary echo" server-kind))))

(deftest lisp-binary-lisp-server
  (check-lisp-binary :lisp))

(deftest lisp-binary-node-server
  (if (peer-available-p :node)
      (check-lisp-binary :node)
      (skip "node peer not available")))

(deftest lisp-binary-python-server
  (if (peer-available-p :python)
      (check-lisp-binary :python)
      (skip "python peer not available")))

(defun check-lisp-deflate (server-kind)
  (with-peer-server (url server-kind nil :compression :deflate)
    (ok (equal "deflate-ping"
               (lisp-echo url "deflate-ping" :compression :deflate))
        (format nil "lisp → ~a permessage-deflate" server-kind))))

(deftest lisp-deflate-lisp-server
  (check-lisp-deflate :lisp))

(deftest lisp-deflate-node-server
  (if (peer-available-p :node)
      (check-lisp-deflate :node)
      (skip "node peer not available")))

(deftest lisp-deflate-python-server
  (if (peer-available-p :python)
      (check-lisp-deflate :python)
      (skip "python peer not available")))

(defun check-lisp-wss (server-kind)
  (with-peer-server (url server-kind nil :ssl t)
    (ok (equal "wss-ping" (lisp-echo url "wss-ping" :verify nil :timeout 8.0))
        (format nil "lisp → ~a WSS" server-kind))))

(deftest lisp-wss-lisp-server
  (if (and (probe-file (driver-cert "server.crt"))
           (probe-file (driver-cert "server.key")))
      (check-lisp-wss :lisp)
      (skip "driver test certs missing")))

(deftest lisp-wss-node-server
  (if (and (peer-available-p :node)
           (probe-file (driver-cert "server.crt")))
      (check-lisp-wss :node)
      (skip "node peer or certs not available")))

(deftest lisp-wss-python-server
  (if (and (peer-available-p :python)
           (probe-file (driver-cert "server.crt")))
      (check-lisp-wss :python)
      (skip "python peer or certs not available")))
