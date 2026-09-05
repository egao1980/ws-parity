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

(defmacro with-peer-server ((url-var kind &optional close-var) &body body)
  (let ((proc (gensym "PROC"))
        (port (gensym "PORT"))
        (log (gensym "LOG"))
        (close-fn (gensym "CLOSE-FN")))
    `(if (eq ,kind :lisp)
         (call-with-lisp-server
          (lambda (,url-var ,close-fn)
            (let (,@(when close-var `((,close-var ,close-fn))))
              ,@body)))
         (multiple-value-bind (,proc ,port ,url-var ,log)
             (start-peer-server ,kind)
           (declare (ignore ,port))
           (unwind-protect
                (let (,@(when close-var
                          `((,close-var (lambda ()
                                          (parse-close-code
                                           (ignore-errors
                                             (uiop:read-file-string ,log))))))))
                  ,@body)
             (stop-peer-server ,proc))))))

(defun lisp-echo (url payload)
  (%bind-lisp)
  (let ((got nil))
    (let ((conn (ws:connect url :transport :http/1.1)))
      (unwind-protect
           (progn
             (ws:on conn :message (lambda (msg) (setf got msg)))
             (ws:send conn payload)
             (unless (wait-until (lambda () (equal got payload)))
               (error "lisp client did not receive echo ~s from ~a" payload url))
             got)
        (ignore-errors (ws:close conn :code 1000 :reason "done"))))))

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

(defun foreign-echo (kind url payload)
  (let* ((cmd (client-command kind url payload 1000))
         (out (uiop:run-program cmd
                                :directory (peer-workdir kind)
                                :output :string
                                :error-output :string
                                :ignore-error-status t)))
    (or (loop for line in (uiop:split-string out :separator '(#\newline))
              for trimmed = (string-trim '(#\space #\return) line)
              when (and (plusp (length trimmed))
                        (not (alexandria:starts-with-subseq "CLOSE " trimmed)))
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
