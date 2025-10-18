(defmodule xrepl-ops-session-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; clone tests

(deftest clone-request-construction
  (let ((req (xrepl-ops-session:clone-request)))
    (is-equal #"clone" (maps:get #"op" req))))

(deftest clone-response-construction
  (let ((resp (xrepl-ops-session:clone-response "new-session-123")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"new-session-123" (maps:get #"new_session" resp))))

;;; close tests

(deftest close-request-no-session
  (let ((req (xrepl-ops-session:close-request)))
    (is-equal #"close" (maps:get #"op" req))))

(deftest close-request-with-session
  (let ((req (xrepl-ops-session:close-request "session-123")))
    (is-equal #"close" (maps:get #"op" req))
    (is-equal #"session-123" (maps:get #"session" req))))

(deftest close-response-construction
  (let ((resp (xrepl-ops-session:close-response)))
    (is-equal #"done" (maps:get #"status" resp))))

;;; ls_sessions tests

(deftest ls-sessions-request-construction
  (let ((req (xrepl-ops-session:ls-sessions-request)))
    (is-equal #"ls_sessions" (maps:get #"op" req))))

(deftest ls-sessions-response-construction
  (let* ((sessions (list #m(#"id" #"s1" #"active" 'true)
                         #m(#"id" #"s2" #"active" 'false)))
         (resp (xrepl-ops-session:ls-sessions-response sessions)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal sessions (maps:get #"sessions" resp))))

(deftest ls-sessions-response-with-timestamp-aliases
  (let* ((sessions (list #m(#"id" #"s1"
                            #"active" 'true
                            #"created" 1234567890
                            #"created_at" 1234567890)))
         (resp (xrepl-ops-session:ls-sessions-response sessions)))
    (is-equal #"done" (maps:get #"status" resp))
    (let* ((returned-sessions (maps:get #"sessions" resp))
           (first-session (lists:nth 1 returned-sessions)))
      ;; Both timestamp fields should be present
      (is-equal 1234567890 (maps:get #"created" first-session))
      (is-equal 1234567890 (maps:get #"created_at" first-session)))))

;;; switch_namespace tests

(deftest switch-namespace-request-construction
  (let ((req (xrepl-ops-session:switch-namespace-request #m(namespace "my-module"))))
    (is-equal #"switch_namespace" (maps:get #"op" req))
    (is-equal #"my-module" (maps:get #"namespace" req))))

(deftest switch-namespace-request-with-session
  (let ((req (xrepl-ops-session:switch-namespace-request
               #m(namespace "my-module" session "abc123"))))
    (is-equal #"switch_namespace" (maps:get #"op" req))
    (is-equal #"my-module" (maps:get #"namespace" req))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest switch-namespace-response-construction
  (let ((resp (xrepl-ops-session:switch-namespace-response "my-module")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"my-module" (maps:get #"namespace" resp))))

;;; session_info tests

(deftest session-info-request-construction
  (let ((req (xrepl-ops-session:session-info-request #m(session "abc123"))))
    (is-equal #"session_info" (maps:get #"op" req))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest session-info-response-construction
  (let* ((info #m(#"id" #"abc123"
                  #"created" 1234567890
                  #"namespace" #"user"))
         (resp (xrepl-ops-session:session-info-response info)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal info (maps:get #"session" resp))))

;;; clear_session tests

(deftest clear-session-request-construction
  (let ((req (xrepl-ops-session:clear-session-request #m(session "abc123"))))
    (is-equal #"clear_session" (maps:get #"op" req))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest clear-session-response-construction
  (let ((resp (xrepl-ops-session:clear-session-response 'true)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 'true (maps:get #"cleared" resp))))

;;; upload_history tests with aliases

(deftest upload-history-request-with-commands
  (let* ((cmds (list "cmd1" "cmd2"))
         (opts (maps:put 'commands cmds #m()))
         (req (xrepl-ops-session:upload-history-request opts)))
    (is-equal #"upload_history" (maps:get #"op" req))
    ;; Both field names should be present
    (is-equal cmds (maps:get #"commands" req))
    (is-equal cmds (maps:get #"history" req))))

(deftest upload-history-request-with-history-alias
  (let* ((cmds (list "cmd1" "cmd2"))
         (opts (maps:put 'history cmds #m()))
         (req (xrepl-ops-session:upload-history-request opts)))
    (is-equal #"upload_history" (maps:get #"op" req))
    ;; Both field names should be present
    (is-equal cmds (maps:get #"commands" req))
    (is-equal cmds (maps:get #"history" req))))

(deftest upload-history-request-with-session
  (let* ((cmds (list "cmd1" "cmd2"))
         (opts (maps:put 'commands cmds
                        (maps:put 'session "abc123" #m())))
         (req (xrepl-ops-session:upload-history-request opts)))
    (is-equal #"upload_history" (maps:get #"op" req))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest upload-history-response-simple
  (let ((resp (xrepl-ops-session:upload-history-response 5 #m())))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 5 (maps:get #"uploaded" resp))))

(deftest upload-history-response-with-session
  (let ((resp (xrepl-ops-session:upload-history-response 5 #m(session "abc123"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 5 (maps:get #"uploaded" resp))
    (is-equal #"abc123" (maps:get #"session" resp))))

;;; Parsing tests

(deftest parse-clone-request
  (let ((msg #m(#"op" #"clone")))
    (case (xrepl-ops-session:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"clone" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-switch-namespace-request
  (let ((msg #m(#"op" #"switch_namespace" #"namespace" #"my-module")))
    (case (xrepl-ops-session:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"switch_namespace" (maps:get #"op" parsed))
       (is-equal #"my-module" (maps:get #"namespace" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-upload-history-request-with-commands-alias
  (let ((msg #m(#"op" #"upload_history" #"commands" (list "c1" "c2"))))
    (case (xrepl-ops-session:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"upload_history" (maps:get #"op" parsed))
       (is (is_list (maps:get #"commands" parsed))))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-upload-history-request-with-history-alias
  (let ((msg #m(#"op" #"upload_history" #"history" (list "c1" "c2"))))
    (case (xrepl-ops-session:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"upload_history" (maps:get #"op" parsed))
       (is (is_list (maps:get #"commands" parsed))))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-clone-response
  (let ((msg #m(#"status" #"done" #"new_session" #"new-123")))
    (case (xrepl-ops-session:parse-response #"clone" msg)
      (`#(ok ,result)
       (is-equal #"new-123" (maps:get #"new_session" result)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-ls-sessions-response
  (let* ((sessions (list #m(#"id" #"s1")))
         (msg (maps:put #"status" #"done"
                       (maps:put #"sessions" sessions #m()))))
    (case (xrepl-ops-session:parse-response #"ls_sessions" msg)
      (`#(ok ,result)
       (is-equal sessions (maps:get #"sessions" result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-request-checks
  (is (xrepl-ops-session:valid-request? #m(#"op" #"clone")))
  (is (xrepl-ops-session:valid-request? #m(#"op" #"ls_sessions")))
  (is (xrepl-ops-session:valid-request? #m(#"op" #"upload_history" #"commands" (list "c1"))))
  (is-not (xrepl-ops-session:valid-request? #m(#"op" #"unknown"))))

(deftest valid-response-checks
  (is (xrepl-ops-session:valid-response? #"clone" #m(#"status" #"done" #"new_session" #"s1")))
  (is (xrepl-ops-session:valid-response? #"close" #m(#"status" #"done")))
  (is (xrepl-ops-session:valid-response? #"ls_sessions" #m(#"status" #"done" #"sessions" (list))))
  (is-not (xrepl-ops-session:valid-response? #"clone" #m(#"status" #"invalid"))))

;;; Round-trip tests

(deftest clone-request-round-trip
  (let* ((req (xrepl-ops-session:clone-request))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"clone" (maps:get #"op" decoded))
    (is (xrepl-ops-session:valid-request? decoded))))

(deftest upload-history-round-trip-with-aliases
  (let* ((cmds (list "cmd1" "cmd2"))
         (opts (maps:put 'commands cmds (maps:put 'session "test" #m())))
         (req (xrepl-ops-session:upload-history-request opts))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    ;; Both field aliases should survive encoding
    (is-equal cmds (maps:get #"commands" decoded))
    (is-equal cmds (maps:get #"history" decoded))
    (is (xrepl-ops-session:valid-request? decoded))))

(deftest switch-namespace-round-trip
  (let* ((req (xrepl-ops-session:switch-namespace-request #m(namespace "my-mod" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"switch_namespace" (maps:get #"op" decoded))
    (is-equal #"my-mod" (maps:get #"namespace" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ops-session:valid-request? decoded))))
