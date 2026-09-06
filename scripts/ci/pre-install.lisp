;;;; ci-base may have ws-protocol 0.4.0; leftover needs 0.4.2 + backend 0.4.1.

(format t "~&; ci: pre-install ws-protocol:0.4.2~%")
(funcall (find-symbol "ENSURE-SYSTEMS" :cl-repo)
         "ws-protocol" :version "0.4.2" :force t)
