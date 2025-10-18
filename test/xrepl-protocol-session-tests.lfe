(defmodule xrepl-protocol-session-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; Clone tests

(deftest clone-request-construction
  (let ((req (xrepl-protocol-session:clone-request)))
    (is-equal 'clone (maps:get 'op req))))

(deftest clone-response-construction
  (let ((resp (xrepl-protocol-session:clone-response "new-session-123")))
    (is-equal 'done (maps:get 'status resp))
    (is-equal #"new-session-123" (maps:get 'new_session resp))))

(deftest parse-clone-request
  (let ((msg #m(op clone)))
    (case (xrepl-protocol-session:parse-request msg)
      (`#(ok ,parsed)
       (is-equal 'clone (maps:get 'op parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-clone-response
  (let ((msg #m(status done new_session "session-123")))
    (case (xrepl-protocol-session:parse-response 'clone msg)
      (`#(ok ,result)
       (is-equal "session-123" (maps:get 'new_session result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Close tests

(deftest close-request-construction-no-session
  (let ((req (xrepl-protocol-session:close-request)))
    (is-equal 'close (maps:get 'op req))))

(deftest close-request-construction-with-session
  (let ((req (xrepl-protocol-session:close-request "session-123")))
    (is-equal 'close (maps:get 'op req))
    (is-equal #"session-123" (maps:get 'session req))))

(deftest close-response-construction
  (let ((resp (xrepl-protocol-session:close-response)))
    (is-equal 'done (maps:get 'status resp))))

(deftest parse-close-request
  (let ((msg #m(op close session "session-123")))
    (case (xrepl-protocol-session:parse-request msg)
      (`#(ok ,parsed)
       (is-equal 'close (maps:get 'op parsed))
       (is-equal "session-123" (maps:get 'session parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-close-response
  (let ((msg #m(status done)))
    (case (xrepl-protocol-session:parse-response 'close msg)
      (`#(ok ,result)
       (is (is_map result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; List sessions tests

(deftest ls-sessions-request-construction
  (let ((req (xrepl-protocol-session:ls-sessions-request)))
    (is-equal 'ls_sessions (maps:get 'op req))))

(deftest ls-sessions-response-construction
  (let* ((sessions (list #m(id "s1" active true created_at 123456)
                         #m(id "s2" active false created_at 123457)))
         (resp (xrepl-protocol-session:ls-sessions-response sessions)))
    (is-equal 'done (maps:get 'status resp))
    (is-equal sessions (maps:get 'sessions resp))))

(deftest parse-ls-sessions-request
  (let ((msg #m(op ls_sessions)))
    (case (xrepl-protocol-session:parse-request msg)
      (`#(ok ,parsed)
       (is-equal 'ls_sessions (maps:get 'op parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-ls-sessions-response
  (let* ((sessions (list #m(id "s1" active true)))
         (msg (map 'status 'done 'sessions sessions)))
    (case (xrepl-protocol-session:parse-response 'ls_sessions msg)
      (`#(ok ,result)
       (is-equal sessions (maps:get 'sessions result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Upload history tests

(deftest upload-history-request-construction
  (let* ((cmds (list "cmd1" "cmd2" "cmd3"))
         (req (xrepl-protocol-session:upload-history-request
                (map 'commands cmds))))
    (is-equal 'upload_history (maps:get 'op req))
    (is-equal cmds (maps:get 'commands req))))

(deftest upload-history-request-with-session
  (let* ((cmds (list "cmd1" "cmd2"))
         (req (xrepl-protocol-session:upload-history-request
                (map 'commands cmds 'session "session-123"))))
    (is-equal 'upload_history (maps:get 'op req))
    (is-equal cmds (maps:get 'commands req))
    (is-equal #"session-123" (maps:get 'session req))))

(deftest upload-history-request-missing-commands
  (is-match `#(error #(missing-required-field commands))
            (xrepl-protocol-session:upload-history-request #m())))

(deftest upload-history-response-construction
  (let ((resp (xrepl-protocol-session:upload-history-response 5 #m())))
    (is-equal 'done (maps:get 'status resp))
    (is-equal 5 (maps:get 'uploaded resp))))

(deftest upload-history-response-with-session
  (let ((resp (xrepl-protocol-session:upload-history-response 5 #m(session "session-123"))))
    (is-equal 'done (maps:get 'status resp))
    (is-equal 5 (maps:get 'uploaded resp))
    (is-equal #"session-123" (maps:get 'session resp))))

(deftest parse-upload-history-request
  (let* ((cmds (list "cmd1" "cmd2"))
         (msg (map 'op 'upload_history 'commands cmds)))
    (case (xrepl-protocol-session:parse-request msg)
      (`#(ok ,parsed)
       (is-equal 'upload_history (maps:get 'op parsed))
       (is-equal cmds (maps:get 'commands parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-upload-history-request-missing-commands
  (let ((msg #m(op upload_history)))
    (is-equal '#(error missing-commands)
              (xrepl-protocol-session:parse-request msg))))

(deftest parse-upload-history-response
  (let ((msg #m(status done uploaded 5 session "session-123")))
    (case (xrepl-protocol-session:parse-response 'upload_history msg)
      (`#(ok ,result)
       (is-equal 5 (maps:get 'uploaded result))
       (is-equal "session-123" (maps:get 'session result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Error tests

(deftest error-response-construction
  (let ((err (xrepl-protocol-session:error 'clone-failed "Out of memory")))
    (is-equal 'error (maps:get 'status err))
    (is-equal 'clone-failed (maps:get 'type (maps:get 'error err)))))

;;; Validation tests

(deftest valid-request-checks
  (is (xrepl-protocol-session:valid-request? #m(op clone)))
  (is (xrepl-protocol-session:valid-request? #m(op close)))
  (is (xrepl-protocol-session:valid-request? #m(op ls_sessions)))
  (is (xrepl-protocol-session:valid-request? #m(op upload_history commands '("cmd"))))
  (is-not (xrepl-protocol-session:valid-request? #m(op invalid))))

(deftest valid-response-checks
  (is (xrepl-protocol-session:valid-response? 'clone #m(status done new_session "s1")))
  (is (xrepl-protocol-session:valid-response? 'close #m(status done)))
  (is (xrepl-protocol-session:valid-response? 'ls_sessions #m(status done sessions '())))
  (is (xrepl-protocol-session:valid-response? 'upload_history #m(status done uploaded 5))))

;;; Round-trip tests

(deftest clone-round-trip
  (let* ((req (xrepl-protocol-session:clone-request))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    ;; MessagePack converts atom keys to binary keys
    (is-equal #"clone" (maps:get #"op" decoded))
    (is (xrepl-protocol-session:valid-request? decoded))))

(deftest upload-history-round-trip
  (let* ((cmds (list "cmd1" "cmd2"))
         (req (xrepl-protocol-session:upload-history-request
                (map 'commands cmds 'session "test")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    ;; MessagePack converts atom keys to binary keys
    (is-equal #"upload_history" (maps:get #"op" decoded))
    (is (xrepl-protocol-session:valid-request? decoded))))
