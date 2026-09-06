(defpackage #:ws-parity
  (:use #:cl)
  (:export #:*peer-root*
           #:peer-available-p
           #:with-peer-server
           #:lisp-echo
           #:lisp-binary-echo
           #:lisp-close-code
           #:lisp-h2-echo
           #:h2-available-p
           #:foreign-echo
           #:foreign-close-code
           #:print-matrix
           #:wait-until
           #:normal-close-code-p
           #:driver-cert
           #:ascii-octets
           #:*lisp-server-deflate-seen*))

(in-package #:ws-parity)
