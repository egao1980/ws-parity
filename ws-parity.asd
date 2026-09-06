(defsystem "ws-parity"
  :version "0.1.1"
  :description "Interop canary: ws-protocol accept vs Python websockets / Node ws"
  :author "egao1980"
  :license "MIT"
  :depends-on ("ws-protocol"
               "ws-backend-websocket-driver"
               "websocket-driver"
               "websocket-driver-server"
               "clack"
               "clack-handler-hunchentoot"
               "hunchentoot"
               "usocket"
               "uiop"
               "alexandria"
               "rove")
  :properties (:cl-repo
               (:ci (:with ("dissect" "http-backend-async"
                             "event-backend-libuv" "cl-stack-ssl"
                             "fast-websocket" "http2"
                             "compression-protocol" "compression-backend-chipz"))))
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "peers")
               (:file "lisp-server")
               (:file "harness")
               (:file "report"))
  :in-order-to ((test-op (test-op "ws-parity/tests"))))

(defsystem "ws-parity/tests"
  :depends-on ("ws-parity" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "lisp-client")
               (:file "foreign-client")
               (:file "h2-client"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "ws-parity tests failed"))))
