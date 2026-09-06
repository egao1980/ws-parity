;;;; ci-base may have ws-protocol 0.4.0 / backend 0.4.0.

(format t "~&; ci: pre-install ws-protocol:0.4.2 + ws-backend-websocket-driver:0.4.1~%")
(funcall (find-symbol "ENSURE-SYSTEMS" :cl-repo)
         "ws-protocol" :version "0.4.2" :force t)
(funcall (find-symbol "ENSURE-SYSTEMS" :cl-repo)
         "ws-backend-websocket-driver" :version "0.4.1" :force t)
