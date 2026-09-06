(in-package #:ws-parity)

(defun print-matrix ()
  (format t "~&ws-parity matrix~%")
  (format t "  peers: node=~a python=~a~%"
          (if (node-available-p) "yes" "no")
          (if (python-available-p) "yes" "no"))
  (format t "  Lisp/Node/Python: text + binary + WSS + permessage-deflate~%")
  (format t "  H2 Extended CONNECT: Lisp→Lisp (async client)~%")
  (values))
