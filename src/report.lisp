(in-package #:ws-parity)

(defun print-matrix ()
  (format t "~&ws-parity matrix~%")
  (format t "  peers: node=~a python=~a~%"
          (if (node-available-p) "yes" "no")
          (if (python-available-p) "yes" "no"))
  (format t "  Lisp/Node/Python × Lisp server: text echo + close 1000~%")
  (format t "  gaps: binary, WSS, H2 CONNECT, permessage-deflate~%")
  (values))
