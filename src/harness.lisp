(in-package #:ws-parity)

(defun normal-close-code-p (code)
  "RFC 6455 1000, or 1006 if the driver drops TCP without a close frame.
   websocket-driver often surfaces 1006 even after ws:close :code 1000."
  (member code '(1000 1006)))

(defun wait-until (pred &key (timeout 3.0) (step 0.02))
  (loop with deadline = (+ (get-internal-real-time)
                           (* timeout internal-time-units-per-second))
        until (or (funcall pred)
                  (> (get-internal-real-time) deadline))
        do (sleep step)
        finally (return (funcall pred))))

(defmacro with-peer-server ((url-var kind &optional close-var
                             &key ssl compression (transport :http/1.1))
                            &body body)
  (let ((proc (gensym "PROC"))
        (port (gensym "PORT"))
        (log (gensym "LOG"))
        (close-fn (gensym "CLOSE-FN")))
    `(if (eq ,kind :lisp)
         (call-with-lisp-server
          (lambda (,url-var ,close-fn)
            (let (,@(when close-var `((,close-var ,close-fn))))
              ,@body))
          :ssl ,ssl :compression ,compression :transport ,transport
          :stop ,(if ssl nil t))
         (multiple-value-bind (,proc ,port ,url-var ,log)
             (start-peer-server ,kind :ssl ,ssl)
           (declare (ignore ,port))
           (unwind-protect
                (let (,@(when close-var
                          `((,close-var (lambda ()
                                          (parse-close-code
                                           (ignore-errors
                                             (uiop:read-file-string ,log))))))))
                  ,@body)
             (stop-peer-server ,proc))))))

(defun ascii-octets (s)
  (let ((o (make-array (length s) :element-type '(unsigned-byte 8))))
    (loop for i from 0 below (length s)
          do (setf (aref o i) (char-code (char s i))))
    o))

(defun %message= (got expected)
  (or (equal got expected)
      (and (vectorp got) (not (stringp got))
           (vectorp expected) (not (stringp expected))
           (equalp got expected))
      (and (stringp got) (vectorp expected) (not (stringp expected))
           (string= got (map 'string #'code-char expected)))
      (and (vectorp got) (not (stringp got)) (stringp expected)
           (equalp got (ascii-octets expected)))))

(defun lisp-echo (url payload &key compression (type :text) (verify nil)
                                ca-path (transport :http/1.1)
                                (timeout 5.0))
  (%bind-lisp)
  (let ((got nil)
        (want (if (eq type :binary)
                  (if (stringp payload) (ascii-octets payload) payload)
                  payload)))
    (let ((conn (ws:connect url :transport transport
                            :compression compression
                            :verify verify
                            :ca-path ca-path)))
      (unwind-protect
           (progn
             (when compression
               (let ((fn (find-symbol "CONNECTION-DEFLATE-P"
                                      :ws-backend-websocket-driver)))
                 (unless (and fn (funcall fn conn))
                   (error "permessage-deflate was not negotiated with ~a" url))))
             (ws:on conn :message (lambda (msg) (setf got msg)))
             (ws:send conn (if (eq type :binary) want payload) :type type)
             (unless (wait-until (lambda () (%message= got want))
                                 :timeout timeout)
               (error "lisp client did not receive echo ~s from ~a (got ~s)"
                      payload url got))
             got)
        (ignore-errors (ws:close conn :code 1000 :reason "done"))))))

(defun lisp-binary-echo (url payload &key compression verify ca-path)
  (lisp-echo url payload :type :binary :compression compression
             :verify verify :ca-path ca-path))

(defun lisp-close-code (url)
  "Connect, send, close 1000. For a Lisp server, CLOSE-FN is unused here —
the peer-close is observed by the *server* via ON-EVENT. This helper just
closes from the Lisp client so the peer can record the code."
  (%bind-lisp)
  (let ((conn (ws:connect url :transport :http/1.1)))
    (unwind-protect
         (progn
           (ws:send conn "close-probe")
           (sleep 0.1)
           (ws:close conn :code 1000 :reason "bye")
           1000)
      (ignore-errors (ws:close conn :code 1000 :reason "bye")))))

(defun lisp-h2-echo (url payload)
  (unless (h2-available-p)
    (error "H2 Extended CONNECT deps not loadable"))
  (let* ((async (find-package :http-backend-async))
         (libuv (find-package :event-backend-libuv))
         (make-ab (find-symbol "MAKE-ASYNC-BACKEND" async))
         (make-uv (find-symbol "MAKE-LIBUV-BACKEND" libuv))
         (maker (find-symbol "*EVENT-BACKEND-MAKER*" async))
         (got nil))
    (setf (symbol-value maker) (lambda () (funcall make-uv)))
    (let ((ws-protocol:*ws-backend* (funcall make-ab)))
      (let ((conn (ws:connect url :verify nil :transport :http/2)))
        (unwind-protect
             (progn
               (ws:on conn :message (lambda (msg) (setf got msg)))
               (ws:send conn payload)
               (unless (wait-until (lambda () (equal got payload))
                                   :timeout 8.0)
                 (error "lisp H2 client did not receive echo ~s (got ~s)"
                        payload got))
               got)
          (ignore-errors (ws:close conn :code 1000 :reason "done")))))))

(defun foreign-echo (kind url payload &key binary)
  (let* ((cmd (client-command kind url payload 1000 :binary binary))
         (out (uiop:run-program cmd
                                :directory (peer-workdir kind)
                                :output :string
                                :error-output :string
                                :ignore-error-status t)))
    (or (loop for line in (uiop:split-string out :separator '(#\newline))
              for trimmed = (string-trim '(#\space #\return) line)
              when (and (plusp (length trimmed))
                        (not (alexandria:starts-with-subseq "CLOSE " trimmed))
                        (not (alexandria:starts-with-subseq "LISTEN " trimmed)))
                return trimmed)
        (error "foreign client ~a produced no echo~%~a" kind out))))

(defun foreign-close-code (kind url)
  (let* ((cmd (client-command kind url "close-probe" 1000))
         (out (uiop:run-program cmd
                                :directory (peer-workdir kind)
                                :output :string
                                :error-output :string
                                :ignore-error-status t)))
    (or (parse-close-code out)
        (error "foreign client ~a produced no CLOSE line~%~a" kind out))))
