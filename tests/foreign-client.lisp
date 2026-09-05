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
