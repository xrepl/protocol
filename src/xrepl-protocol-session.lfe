(defmodule xrepl-protocol-session
  "Session operation protocol messages.

  This module defines the structure of session management messages
  in the xrepl protocol, including creating (cloning), closing,
  listing, and history upload operations.

  ## Message Structures

  Clone Request:
    #m(op clone)

  Clone Response:
    #m(status done
       new_session \"session-id\")

  Close Request:
    #m(op close
       session \"session-id\")  ; optional, uses current if not provided

  Close Response:
    #m(status done)

  List Sessions Request:
    #m(op ls_sessions)

  List Sessions Response:
    #m(status done
       sessions [#m(id \"s1\" active true created_at 123456) ...])

  Upload History Request:
    #m(op upload_history
       commands [\"cmd1\" \"cmd2\" ...]
       session \"session-id\")  ; optional

  Upload History Response:
    #m(status done
       uploaded 5
       session \"session-id\")

  Error Response:
    #m(status error
       error #m(type error-type
                message \"Error details\"))"
  (export
   ;; Clone operations
   (clone-request 0)
   (clone-response 1)
   ;; Close operations
   (close-request 0)
   (close-request 1)
   (close-response 0)
   ;; List sessions operations
   (ls-sessions-request 0)
   (ls-sessions-response 1)
   ;; Upload history operations
   (upload-history-request 1)
   (upload-history-response 2)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; Clone operations

(defun clone-request ()
  "Build a clone (create new session) request.

  Returns:
    Request message map"
  #m(op clone))

(defun clone-response (new-session-id)
  "Build a successful clone response.

  Args:
    new-session-id: ID of the newly created session (string or binary)

  Returns:
    Response message map"
  (map 'status 'done
       'new_session (xrepl-protocol-types:ensure-binary new-session-id)))

;;; Close operations

(defun close-request ()
  "Build a close request (closes current session).

  Returns:
    Request message map"
  #m(op close))

(defun close-request (session-id)
  "Build a close request for a specific session.

  Args:
    session-id: ID of session to close (string or binary)

  Returns:
    Request message map"
  (map 'op 'close
       'session (xrepl-protocol-types:ensure-binary session-id)))

(defun close-response ()
  "Build a successful close response.

  Returns:
    Response message map"
  #m(status done))

;;; List sessions operations

(defun ls-sessions-request ()
  "Build a list sessions request.

  Returns:
    Request message map"
  #m(op ls_sessions))

(defun ls-sessions-response (sessions)
  "Build a list sessions response.

  Args:
    sessions: List of session maps with id, active, created_at fields

  Returns:
    Response message map

  Example session format:
    #m(id \"session-1\" active true created_at 1234567890)"
  (map 'status 'done
       'sessions sessions))

;;; Upload history operations

(defun upload-history-request (opts)
  "Build an upload history request.

  Options:
    commands: List of command strings (required)
    session: Session ID (optional, string or binary)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'commands)
    (`#(ok ,commands)
     (let ((session (maps:get 'session opts 'undefined)))
       (if (== session 'undefined)
         (map 'op 'upload_history
              'commands commands)
         (map 'op 'upload_history
              'commands commands
              'session (xrepl-protocol-types:ensure-binary session)))))
    (error error)))

(defun upload-history-response (uploaded-count opts)
  "Build an upload history response.

  Args:
    uploaded-count: Number of commands uploaded
    opts: Options map (session, etc.)

  Returns:
    Response message map"
  (let ((base (map 'status 'done
                   'uploaded uploaded-count)))
    (case (maps:get 'session opts 'undefined)
      ('undefined base)
      (session (maps:put 'session (xrepl-protocol-types:ensure-binary session) base)))))

;;; Parsing and validation

(defun parse-request (message)
  "Parse and validate session operation request message.

  Args:
    message: Message map

  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-protocol-types:get-field message 'op)))
      (cond
        ;; Clone operation
        ((or (== op 'clone) (== op #"clone"))
         (tuple 'ok (map 'op 'clone)))

        ;; Close operation
        ((or (== op 'close) (== op #"close"))
         (tuple 'ok (map 'op 'close
                         'session (xrepl-protocol-types:get-field message 'session 'undefined))))

        ;; List sessions operation
        ((or (== op 'ls_sessions) (== op #"ls_sessions"))
         (tuple 'ok (map 'op 'ls_sessions)))

        ;; Upload history operation
        ((or (== op 'upload_history) (== op #"upload_history"))
         (let ((commands (xrepl-protocol-types:get-field message 'commands)))
           (if (or (== commands 'undefined) (not (is_list commands)))
             (tuple 'error 'missing-commands)
             (tuple 'ok (map 'op 'upload_history
                             'commands commands
                             'session (xrepl-protocol-types:get-field message 'session 'undefined))))))

        ;; Invalid operation
        ('true (tuple 'error 'invalid-session-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))

(defun parse-response (op message)
  "Parse session operation response message.

  Args:
    op: Operation type (clone, close, ls_sessions, upload_history)
    message: Response message map

  Returns:
    #(ok result-map) | #(error error-info)"
  (case (xrepl-protocol-types:get-field message 'status)
    ('done
     (case op
       ('clone
        (tuple 'ok (map 'new_session (xrepl-protocol-types:get-field message 'new_session))))

       ('close
        (tuple 'ok (map)))

       ('ls_sessions
        (tuple 'ok (map 'sessions (xrepl-protocol-types:get-field message 'sessions))))

       ('upload_history
        (tuple 'ok (map 'uploaded (xrepl-protocol-types:get-field message 'uploaded)
                        'session (xrepl-protocol-types:get-field message 'session 'undefined))))

       (_ (tuple 'error 'unknown-operation))))

    ('error
     (tuple 'error (xrepl-protocol-types:get-field message 'error)))

    (_
     (tuple 'error 'invalid-status))))

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
  (let ((status (xrepl-protocol-types:get-field message 'status)))
    (or (== status 'done)
        (== status #"done")
        (== status 'error)
        (== status #"error"))))

;;; Errors

(defun error (error-type message)
  "Build error response for session operation.

  Args:
    error-type: Atom identifying error type
    message: Error message (binary, string, or term)

  Returns:
    Error response map"
  (xrepl-protocol-types:error-response error-type message))
