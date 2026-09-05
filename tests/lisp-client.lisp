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
