(defmodule xrepl-ptcl-ops-sess
  "Session management operation protocol messages.

  This module defines all session management operations in the xrepl protocol."
  (export
   ;; clone operation
   (clone-request 0)
   (clone-response 1)
   ;; close operation
   (close-request 0) (close-request 1)
   (close-response 0)
   ;; ls_sessions operation
   (ls-sessions-request 0)
   (ls-sessions-response 1)
   ;; switch_namespace operation
   (switch-namespace-request 1)
   (switch-namespace-response 1)
   ;; session_info operation
   (session-info-request 1)
   (session-info-response 1)
   ;; clear_session operation
   (clear-session-request 1)
   (clear-session-response 1)
   ;; upload_history operation
   (upload-history-request 1)
   (upload-history-response 2)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; clone operation

(defun clone-request ()
  "Build a clone (create new session) request.

  Returns:
    Request message map with binary keys"
  #m(#"op" #"clone"))

(defun clone-response (new-session-id)
  "Build a successful clone response.

  Args:
    new-session-id: ID of the newly created session (string or binary)

  Returns:
    Response message map with binary keys"
  (maps:put #"status" #"done"
           (maps:put #"new_session" (xrepl-ptcl-types:ensure-binary new-session-id)
                    #m())))

;;; close operation

(defun close-request ()
  "Build a close request (closes current session).

  Returns:
    Request message map with binary keys"
  #m(#"op" #"close"))

(defun close-request (session-id)
  "Build a close request for a specific session.

  Args:
    session-id: ID of session to close (string or binary)

  Returns:
    Request message map with binary keys"
  (maps:put #"op" #"close"
           (maps:put #"session" (xrepl-ptcl-types:ensure-binary session-id)
                    #m())))

(defun close-response ()
  "Build a successful close response.

  Returns:
    Response message map with binary keys"
  #m(#"status" #"done"))

;;; ls_sessions operation

(defun ls-sessions-request ()
  "Build a list sessions request.

  Returns:
    Request message map with binary keys"
  #m(#"op" #"ls_sessions"))

(defun ls-sessions-response (sessions)
  "Build a list sessions response.

  Args:
    sessions: List of session maps with id, active, created/created_at fields

  Returns:
    Response message map with binary keys

  Note: Each session should have BOTH 'created' and 'created_at' fields
        for Emacs/VSCode compatibility.

  Example session format:
    #m(#\"id\" #\"session-1\"
       #\"active\" true
       #\"created\" 1234567890
       #\"created_at\" 1234567890)"
  (maps:put #"status" #"done"
           (maps:put #"sessions" sessions
                    #m())))

;;; switch_namespace operation

(defun switch-namespace-request (opts)
  "Build a switch_namespace request.

  Options:
    namespace: Module name (required)
    session: Session ID (optional)

  Returns:
    Request message map"
  (case (xrepl-ptcl-types:get-required opts 'namespace)
    (`#(ok ,namespace)
     (let* ((base (maps:put #"op" #"switch_namespace"
                           (maps:put #"namespace" (xrepl-ptcl-types:ensure-binary namespace)
                                    #m())))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun switch-namespace-response (namespace)
  "Build a switch_namespace response.

  Args:
    namespace: Confirmed new namespace (string or binary)

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"namespace" (xrepl-ptcl-types:ensure-binary namespace)
                    #m())))

;;; session_info operation

(defun session-info-request (opts)
  "Build a session_info request.

  Options:
    session: Session ID (required)

  Returns:
    Request message map"
  (case (xrepl-ptcl-types:get-required opts 'session)
    (`#(ok ,session)
     (maps:put #"op" #"session_info"
              (maps:put #"session" (xrepl-ptcl-types:ensure-binary session)
                       #m())))
    (error error)))

(defun session-info-response (info)
  "Build a session_info response.

  Args:
    info: Session info map with id, created, last_active, namespace, bindings, loaded_modules

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"session" info
                    #m())))

;;; clear_session operation

(defun clear-session-request (opts)
  "Build a clear_session request.

  Options:
    session: Session ID (required)

  Returns:
    Request message map"
  (case (xrepl-ptcl-types:get-required opts 'session)
    (`#(ok ,session)
     (maps:put #"op" #"clear_session"
              (maps:put #"session" (xrepl-ptcl-types:ensure-binary session)
                       #m())))
    (error error)))

(defun clear-session-response (cleared)
  "Build a clear_session response.

  Args:
    cleared: Boolean indicating if session was cleared

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"cleared" cleared
                    #m())))

;;; upload_history operation

(defun upload-history-request (opts)
  "Build an upload_history request.

  Options:
    commands: List of command strings (required) - also accepts 'history' as alias
    session: Session ID (optional)

  Returns:
    Request message map"
  ;; Try both 'commands' and 'history' field names
  (let ((cmds (xrepl-ptcl-types:get-field-any opts '(commands history) 'undefined)))
    (if (== cmds 'undefined)
      (tuple 'error (tuple 'missing-required-field 'commands))
      (let* ((base (xrepl-ptcl-types:put-aliased-list #m() 'commands 'history cmds))
             (with-op (maps:put #"op" #"upload_history" base))
             (with-session (xrepl-ptcl-types:maybe-put-aliased
                            with-op 'session 'session opts 'session)))
        with-session))))

(defun upload-history-response (uploaded-count opts)
  "Build an upload_history response.

  Args:
    uploaded-count: Number of commands uploaded
    opts: Options map (session, etc.)

  Returns:
    Response message map"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"uploaded" uploaded-count
                                 #m())))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

;;; Parsing and validation

(defun parse-request (message)
  "Parse and validate session operation request message.

  Args:
    message: Message map (with binary keys from MessagePack)

  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-ptcl-types:get-field message 'op)))
      (cond
        ;; clone operation
        ((or (== op #"clone") (== op 'clone))
         (tuple 'ok #m(#"op" #"clone")))

        ;; close operation
        ((or (== op #"close") (== op 'close))
         (tuple 'ok (maps:put #"op" #"close"
                             (maps:put #"session"
                                      (xrepl-ptcl-types:get-field message 'session 'undefined)
                                      #m()))))

        ;; ls_sessions operation
        ((or (== op #"ls_sessions") (== op 'ls_sessions))
         (tuple 'ok #m(#"op" #"ls_sessions")))

        ;; switch_namespace operation
        ((or (== op #"switch_namespace") (== op 'switch_namespace))
         (let ((namespace (xrepl-ptcl-types:get-field message 'namespace)))
           (if (== namespace 'undefined)
             (tuple 'error 'missing-namespace)
             (tuple 'ok (maps:put #"op" #"switch_namespace"
                                 (maps:put #"namespace" namespace
                                          (maps:put #"session"
                                                   (xrepl-ptcl-types:get-field message 'session 'undefined)
                                                   #m())))))))

        ;; session_info operation
        ((or (== op #"session_info") (== op 'session_info))
         (let ((session (xrepl-ptcl-types:get-field message 'session)))
           (if (== session 'undefined)
             (tuple 'error 'missing-session)
             (tuple 'ok (maps:put #"op" #"session_info"
                                 (maps:put #"session" session #m()))))))

        ;; clear_session operation
        ((or (== op #"clear_session") (== op 'clear_session))
         (let ((session (xrepl-ptcl-types:get-field message 'session)))
           (if (== session 'undefined)
             (tuple 'error 'missing-session)
             (tuple 'ok (maps:put #"op" #"clear_session"
                                 (maps:put #"session" session #m()))))))

        ;; upload_history operation
        ((or (== op #"upload_history") (== op 'upload_history))
         ;; Try both 'commands' and 'history' field names
         (let ((commands (xrepl-ptcl-types:get-field-any message '(commands history))))
           (if (or (== commands 'undefined) (not (is_list commands)))
             (tuple 'error 'missing-commands)
             (tuple 'ok (maps:put #"op" #"upload_history"
                                 (maps:put #"commands" commands
                                          (maps:put #"session"
                                                   (xrepl-ptcl-types:get-field message 'session 'undefined)
                                                   #m())))))))

        ;; Invalid operation
        ('true (tuple 'error 'invalid-session-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))

(defun parse-response (op message)
  "Parse session operation response message.

  Args:
    op: Operation type (clone, close, ls_sessions, etc.)
    message: Response message map (with binary keys)

  Returns:
    #(ok result-map) | #(error error-info)"
  (let* ((status (xrepl-ptcl-types:get-field message 'status))
         ;; Normalize op to binary for comparison
         (norm-op (if (is_binary op) op (xrepl-ptcl-types:ensure-binary-key op))))
    (cond
      ;; Done status
      ((or (== status #"done") (== status 'done))
       (cond
         ;; clone response
         ((== norm-op #"clone")
          (tuple 'ok (maps:put #"new_session"
                              (xrepl-ptcl-types:get-field message 'new_session)
                              #m())))

         ;; close response
         ((== norm-op #"close")
          (tuple 'ok #m()))

         ;; ls_sessions response
         ((== norm-op #"ls_sessions")
          (tuple 'ok (maps:put #"sessions"
                              (xrepl-ptcl-types:get-field message 'sessions)
                              #m())))

         ;; switch_namespace response
         ((== norm-op #"switch_namespace")
          (tuple 'ok (maps:put #"namespace"
                              (xrepl-ptcl-types:get-field message 'namespace)
                              #m())))

         ;; session_info response
         ((== norm-op #"session_info")
          (tuple 'ok (maps:put #"session"
                              (xrepl-ptcl-types:get-field message 'session)
                              #m())))

         ;; clear_session response
         ((== norm-op #"clear_session")
          (tuple 'ok (maps:put #"cleared"
                              (xrepl-ptcl-types:get-field message 'cleared)
                              #m())))

         ;; upload_history response
         ((== norm-op #"upload_history")
          (tuple 'ok (maps:put #"uploaded"
                              (xrepl-ptcl-types:get-field message 'uploaded)
                              (maps:put #"session"
                                       (xrepl-ptcl-types:get-field message 'session 'undefined)
                                       #m()))))

         ('true (tuple 'error 'unknown-operation))))

      ;; Error status
      ((or (== status #"error") (== status 'error))
       (tuple 'error (xrepl-ptcl-types:get-field message 'error)))

      ;; Invalid status
      ('true (tuple 'error 'invalid-status)))))

(defun valid-request? (message)
  "Check if message is a valid session operation request.

  Args:
    message: Message map

  Returns:
    true | false"
  (case (parse-request message)
    (`#(ok ,_) 'true)
    (_ 'false)))

(defun valid-response? (op message)
  "Check if message is a valid session operation response.

  Args:
    op: Operation type
    message: Message map

  Returns:
    true | false"
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (or (== status #"done")
        (== status 'done)
        (== status #"error")
        (== status 'error))))

;;; Errors

(defun error (error-type message)
  "Build error response for session operation.

  Args:
    error-type: Atom identifying error type
    message: Error message (binary, string, or term)

  Returns:
    Error response map"
  (xrepl-ptcl-types:error-response error-type message))
