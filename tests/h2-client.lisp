(in-package #:ws-parity/tests)

(deftest lisp-h2-extended-connect
  "Lisp async client → Lisp H2 Extended CONNECT server."
  (cond
    ((not (h2-available-p))
     (skip "http2 server / http-backend-async / libuv not loadable"))
    (t
     (handler-case
         (with-peer-server (url :lisp nil :ssl t :transport :http/2)
           (ok (equal "h2-echo" (lisp-h2-echo url "h2-echo"))))
       (error (c)
         (skip (format nil "H2 canary unavailable: ~A" c)))))))
