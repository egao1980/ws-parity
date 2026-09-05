(in-package #:ws-parity)

(defparameter *peer-root*
  (asdf:system-relative-pathname "ws-parity" "peers/")
  "Directory containing node/ and python/ peer programs.")

(defun %env-off-p (name)
  (member (uiop:getenv name) '("0" "false" "no" "off") :test #'string-equal))

(defun peers-enabled-p ()
  (not (%env-off-p "WS_PARITY_PEERS")))

(defun which (program)
  "Resolve PROGRAM. On Windows return the bare name (PATH search) so
   UIOP/CreateProcess is not handed a `Program Files` path with spaces."
  (or (uiop:getenv (format nil "WS_PARITY_~a" (string-upcase program)))
      (if (uiop:os-windows-p)
          (when (zerop (nth-value 2 (uiop:run-program
                                     (list "where" program)
                                     :ignore-error-status t
                                     :output nil
                                     :error-output nil)))
            program)
          (ignore-errors
            (string-trim '(#\space #\newline #\return)
                         (uiop:run-program (list "which" program)
                                           :output :string
                                           :error-output nil))))))

(defun node-available-p ()
  (and (peers-enabled-p)
       (which "node")
       (probe-file (merge-pathnames "node/server.mjs" *peer-root*))))

(defun python-venv ()
  (let ((root (merge-pathnames "python/" *peer-root*)))
    (find-if #'probe-file
             (list (merge-pathnames ".venv/bin/python" root)
                   (merge-pathnames ".venv/bin/python3" root)
                   (merge-pathnames ".venv/Scripts/python.exe" root)))))

(defun python3-bin ()
  (or (when (probe-file "/usr/bin/python3") "/usr/bin/python3")
      (which "python3")
      (which "python")))

(defun python-available-p ()
  (and (peers-enabled-p)
       (or (python-venv) (which "uv") (python3-bin))
       (probe-file (merge-pathnames "python/server.py" *peer-root*))))

(defun peer-available-p (kind)
  (ecase kind
    (:node (node-available-p))
    (:python (python-available-p))
    (:lisp t)))

(defun %free-port ()
  (let* ((sock (usocket:socket-listen "127.0.0.1" 0 :reuseaddress t))
         (port (usocket:get-local-port sock)))
    (usocket:socket-close sock)
    port))

(defun %wait-peer-port (proc host port timeout)
  (let ((deadline (+ (get-internal-real-time)
                     (* timeout internal-time-units-per-second))))
    (loop
      (unless (uiop:process-alive-p proc)
        (error "peer server exited ~a"
               (ignore-errors (uiop:wait-process proc))))
      (when (> (get-internal-real-time) deadline)
        (error "peer server did not accept ~a:~a within ~a s"
               host port timeout))
      (handler-case
          (progn
            (usocket:socket-close
             (usocket:socket-connect host port :timeout 0.2))
            (return t))
        (usocket:connection-refused-error ()
          (sleep 0.05))
        (error ()
          (sleep 0.05))))))

(defun python-cmd (script &rest args)
  (let ((script-path (uiop:native-namestring
                      (merge-pathnames script (merge-pathnames "python/" *peer-root*)))))
    (cond
      ((python-venv)
       (list* (uiop:native-namestring (python-venv)) "-u" script-path args))
      ((which "uv")
       (list* (which "uv") "run" "--no-sync"
              "--project" (uiop:native-namestring (merge-pathnames "python/" *peer-root*))
              "python" "-u" script-path args))
      ((python3-bin)
       (list* (python3-bin) "-u" script-path args))
      (t
       (error "no python runtime for peer ~a" script)))))

(defun peer-command (kind port)
  (ecase kind
    (:node
     (list (which "node")
           (uiop:native-namestring (merge-pathnames "node/server.mjs" *peer-root*))
           (princ-to-string port)))
    (:python
     (python-cmd "server.py" (princ-to-string port)))))

(defun client-command (kind url payload close-code)
  (ecase kind
    (:node
     (list (which "node")
           (uiop:native-namestring (merge-pathnames "node/client.mjs" *peer-root*))
           url payload (princ-to-string close-code)))
    (:python
     (python-cmd "client.py" url payload (princ-to-string close-code)))))

(defun start-peer-server (kind &key (port (%free-port)) (timeout 30))
  (let* ((cmd (peer-command kind port))
         (log (uiop:with-temporary-file (:pathname p :keep t)
                p))
         (proc (uiop:launch-program cmd
                                    :output log
                                    :error-output :output)))
    (handler-case
        (%wait-peer-port proc "127.0.0.1" port timeout)
      (error (e)
        (ignore-errors (uiop:terminate-process proc :urgent t))
        (error "~a~%cmd: ~s~%log:~%~a"
               e cmd (ignore-errors (uiop:read-file-string log)))))
    (values proc port (format nil "ws://127.0.0.1:~a/echo" port) log)))

(defun stop-peer-server (proc)
  (when proc
    (ignore-errors (uiop:terminate-process proc :urgent t))
    (ignore-errors (uiop:wait-process proc))))

(defun parse-close-code (text)
  (when text
    (let ((pos (search "CLOSE " text)))
      (when pos
        (parse-integer (subseq text (+ pos 6)) :junk-allowed t)))))
