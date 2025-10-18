(defmodule xrepl-ops-evaluation
  "Evaluation operation protocol messages.

  This module defines all code evaluation operations in the xrepl protocol."
  (export
   ;; eval operation
   (eval-request 1)
   (eval-response 1) (eval-response 2)
   (eval-action-response 2)
   (eval-error 2)
   ;; eval_multiple operation
   (eval-multiple-request 1)
   (eval-multiple-response 1) (eval-multiple-response 2)
   ;; eval_at_point operation
   (eval-at-point-request 1)
   ;; stream_eval / eval_stream operations
   (stream-eval-request 1)
   (stream-eval-intermediate 2) (stream-eval-intermediate 3)
   (stream-eval-final 1) (stream-eval-final 2)
   ;; interrupt operation
   (interrupt-request 1)
   (interrupt-response 2)
   ;; cancel operation
   (cancel-request 1)
   (cancel-response 2)
   ;; load_file operation
   (load-file-request 1)
   (load-file-response 1) (load-file-response 2)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)))

;;; eval operation

(defun eval-request (opts)
  "Build an eval request message.

  Options:
    code: Code to evaluate (required, string or binary)
    session: Session ID (optional, binary or string)
    file: File name for error reporting (optional)
    line: Starting line number (optional)
    column: Starting column (optional)

  Returns:
    Request message map with binary keys

  Examples:
    (eval-request #m(code \"(+ 1 2)\"))
    (eval-request #m(code \"(+ 1 2)\" session \"abc123\"))"
  (case (xrepl-ptcl-types:get-required opts 'code)
    (`#(ok ,code)
     (let* ((base (maps:put #"op" #"eval"
                           (maps:put #"code" (xrepl-ptcl-types:ensure-binary code)
                                    #m())))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           base 'session 'session opts 'session))
            (with-file (xrepl-ptcl-types:maybe-put-aliased
                        with-session 'file 'file opts 'file))
            (with-line (case (xrepl-ptcl-types:get-field opts 'line 'undefined)
                        ('undefined with-file)
                        (line (maps:put #"line" line with-file))))
            (with-column (case (xrepl-ptcl-types:get-field opts 'column 'undefined)
                          ('undefined with-line)
                          (col (maps:put #"column" col with-line)))))
       with-column))
    (error error)))

(defun eval-response (value)
  "Build successful eval response.

  Args:
    value: Evaluation result (binary or string)

  Returns:
    Response message map with binary keys"
  (eval-response value #m()))

(defun eval-response (value opts)
  "Build successful eval response with options.

  Args:
    value: Evaluation result (binary or string)
    opts: Options map (session, ns/namespace, etc.)

  Returns:
    Response message map with binary keys

  Examples:
    (eval-response \"42\")
    (eval-response \"42\" #m(session \"abc123\" ns \"user\"))"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"value" (xrepl-ptcl-types:ensure-binary value)
                                 #m())))
         ;; Add session with alias
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        base 'session 'session opts 'session))
         ;; Add namespace (ns is primary, namespace is alias)
         (with-ns (xrepl-ptcl-types:maybe-put-aliased
                   with-session 'ns 'namespace opts 'ns)))
    with-ns))

(defun eval-action-response (action opts)
  "Build action response for eval operation (for session switching, etc.).

  Args:
    action: Action atom (switch, switch-to-other)
    opts: Options map (session, etc.)

  Returns:
    Response message map

  Examples:
    (eval-action-response 'switch #m(session \"new-id\"))"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"action" (xrepl-ptcl-types:ensure-binary action)
                                 #m())))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

(defun eval-error (error-type message)
  "Build error response for eval operation.

  Args:
    error-type: Atom identifying error type
    message: Error message

  Returns:
    Error response map"
  (xrepl-ptcl-types:error-response error-type message))

;;; eval_multiple operation

(defun eval-multiple-request (opts)
  "Build an eval_multiple request message.

  Options:
    forms: Array of code strings (required)
    session: Session ID (optional)

  Returns:
    Request message map with binary keys

  Example:
    (eval-multiple-request #m(forms '(\"(+ 1 2)\" \"(* 3 4)\")))"
  (case (xrepl-ptcl-types:get-required opts 'forms)
    (`#(ok ,forms)
     (let* ((base (maps:put #"op" #"eval_multiple"
                           (maps:put #"forms" forms #m())))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun eval-multiple-response (results)
  "Build eval_multiple response.

  Args:
    results: List of result maps with value/status/error fields

  Returns:
    Response message map"
  (eval-multiple-response results #m()))

(defun eval-multiple-response (results opts)
  "Build eval_multiple response with options.

  Args:
    results: List of result maps
    opts: Options (session, etc.)

  Returns:
    Response message map

  Example:
    (eval-multiple-response
      '(#m(value \"3\" status \"ok\")
        #m(status \"error\" error \"bad syntax\"))
      #m(session \"abc123\"))"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"results" results #m())))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

;;; eval_at_point operation

(defun eval-at-point-request (opts)
  "Build eval_at_point request with context.

  Options:
    code: Code to evaluate (required)
    file: File path (required)
    line: Line number (required)
    column: Column number (required)
    session: Session ID (optional)
    context: Context map with buffer_contents, surrounding_forms (optional)

  Returns:
    Request message map"
  (case (xrepl-ptcl-types:get-required opts 'code)
    (`#(ok ,code)
     (case (xrepl-ptcl-types:get-required opts 'file)
       (`#(ok ,file)
        (case (xrepl-ptcl-types:get-required opts 'line)
          (`#(ok ,line)
           (case (xrepl-ptcl-types:get-required opts 'column)
             (`#(ok ,column)
              (let* ((base (maps:put #"op" #"eval_at_point"
                                    (maps:put #"code" (xrepl-ptcl-types:ensure-binary code)
                                             (maps:put #"file" (xrepl-ptcl-types:ensure-binary file)
                                                      (maps:put #"line" line
                                                               (maps:put #"column" column #m()))))))
                     (with-session (xrepl-ptcl-types:maybe-put-aliased
                                    base 'session 'session opts 'session))
                     (with-context (case (xrepl-ptcl-types:get-field opts 'context 'undefined)
                                    ('undefined with-session)
                                    (ctx (maps:put #"context" ctx with-session)))))
                with-context))
             (error error)))
          (error error)))
       (error error)))
    (error error)))

;;; stream_eval / eval_stream operations

(defun stream-eval-request (opts)
  "Build stream_eval or eval_stream request.

  Options:
    code: Code to evaluate (required)
    session: Session ID (optional)
    op_name: 'stream_eval or 'eval_stream (optional, defaults to stream_eval)

  Returns:
    Request message map"
  (case (xrepl-ptcl-types:get-required opts 'code)
    (`#(ok ,code)
     (let* ((op-name (xrepl-ptcl-types:get-field opts 'op_name 'stream_eval))
            (base (maps:put #"op" (xrepl-ptcl-types:ensure-binary op-name)
                           (maps:put #"code" (xrepl-ptcl-types:ensure-binary code) #m())))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun stream-eval-intermediate (output stream-type)
  "Build intermediate streaming output response.

  Args:
    output: Output string
    stream-type: 'stdout or 'stderr

  Returns:
    Intermediate response map"
  (stream-eval-intermediate output stream-type #m()))

(defun stream-eval-intermediate (output stream-type opts)
  "Build intermediate streaming output response with options.

  Args:
    output: Output string
    stream-type: 'stdout or 'stderr
    opts: Options (session, etc.)

  Returns:
    Intermediate response map"
  (let* ((base (maps:put #"status" #"streaming"
                        (maps:put #"output" (xrepl-ptcl-types:ensure-binary output)
                                 (maps:put #"stream" (xrepl-ptcl-types:ensure-binary stream-type)
                                          #m()))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

(defun stream-eval-final (value)
  "Build final streaming evaluation response.

  Args:
    value: Final evaluation result

  Returns:
    Final response map"
  (stream-eval-final value #m()))

(defun stream-eval-final (value opts)
  "Build final streaming evaluation response with options.

  Args:
    value: Final evaluation result
    opts: Options (session, etc.)

  Returns:
    Final response map"
  (eval-response value opts))  ;; Same as regular eval response

;;; interrupt operation

(defun interrupt-request (opts)
  "Build interrupt request.

  Options:
    session: Session ID (optional)

  Returns:
    Request message map"
  (let* ((base (maps:put #"op" #"interrupt" #m()))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

(defun interrupt-response (interrupted opts)
  "Build interrupt response.

  Args:
    interrupted: Boolean indicating if interruption succeeded
    opts: Options (session, message, etc.)

  Returns:
    Response message map"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"interrupted" interrupted #m())))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        base 'session 'session opts 'session))
         (with-message (case (xrepl-ptcl-types:get-field opts 'message 'undefined)
                        ('undefined with-session)
                        (msg (maps:put #"message" (xrepl-ptcl-types:ensure-binary msg)
                                      with-session)))))
    with-message))

;;; cancel operation

(defun cancel-request (opts)
  "Build cancel request.

  Options:
    cancel_id: ID of operation to cancel (required)

  Returns:
    Request message map"
  (case (xrepl-ptcl-types:get-required opts 'cancel_id)
    (`#(ok ,cancel-id)
     (maps:put #"op" #"cancel"
              (maps:put #"cancel_id" (xrepl-ptcl-types:ensure-binary cancel-id) #m())))
    (error error)))

(defun cancel-response (cancelled target-id)
  "Build cancel response.

  Args:
    cancelled: Boolean indicating if cancellation succeeded
    target-id: ID of the cancelled operation

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"cancelled" cancelled
                    (maps:put #"target_id" (xrepl-ptcl-types:ensure-binary target-id)
                             #m()))))

;;; load_file operation

(defun load-file-request (opts)
  "Build load_file request.

  Options:
    file: File path (required)
    session: Session ID (optional)
    file_name: Name for error reporting (optional)
    file_contents: Optional file contents to send directly (optional)

  Returns:
    Request message map"
  (case (xrepl-ptcl-types:get-required opts 'file)
    (`#(ok ,file)
     (let* ((base (maps:put #"op" #"load_file"
                           (maps:put #"file" (xrepl-ptcl-types:ensure-binary file) #m())))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           base 'session 'session opts 'session))
            (with-file-name (case (xrepl-ptcl-types:get-field opts 'file_name 'undefined)
                             ('undefined with-session)
                             (fn (maps:put #"file_name" (xrepl-ptcl-types:ensure-binary fn)
                                          with-session))))
            (with-contents (case (xrepl-ptcl-types:get-field opts 'file_contents 'undefined)
                            ('undefined with-file-name)
                            (contents (maps:put #"file_contents"
                                               (xrepl-ptcl-types:ensure-binary contents)
                                               with-file-name)))))
       with-contents))
    (error error)))

(defun load-file-response (value)
  "Build load_file response.

  Args:
    value: Result of loading file

  Returns:
    Response message map"
  (load-file-response value #m()))

(defun load-file-response (value opts)
  "Build load_file response with options.

  Args:
    value: Result of loading file
    opts: Options (session, warnings, etc.)

  Returns:
    Response message map"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"value" (xrepl-ptcl-types:ensure-binary value) #m())))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        base 'session 'session opts 'session))
         (with-warnings (case (xrepl-ptcl-types:get-field opts 'warnings 'undefined)
                         ('undefined with-session)
                         (warnings (maps:put #"warnings" warnings with-session)))))
    with-warnings))

;;; Parsing and validation functions

(defun parse-request (message)
  "Parse and validate evaluation request message.

  Args:
    message: Message map (with binary keys from MessagePack)

  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-ptcl-types:get-field message 'op)))
      (cond
        ;; eval operation
        ((or (== op #"eval") (== op 'eval))
         (let ((code (xrepl-ptcl-types:get-field message 'code)))
           (if (or (== code 'undefined) (not (or (is_binary code) (is_list code))))
             (tuple 'error 'missing-code)
             (tuple 'ok (maps:put #"op" #"eval"
                                 (maps:put #"code" code
                                          (maps:put #"session"
                                                   (xrepl-ptcl-types:get-field message 'session 'undefined)
                                                   #m())))))))

        ;; eval_multiple operation
        ((or (== op #"eval_multiple") (== op 'eval_multiple))
         (let ((forms (xrepl-ptcl-types:get-field message 'forms)))
           (if (or (== forms 'undefined) (not (is_list forms)))
             (tuple 'error 'missing-forms)
             (tuple 'ok (maps:put #"op" #"eval_multiple"
                                 (maps:put #"forms" forms
                                          (maps:put #"session"
                                                   (xrepl-ptcl-types:get-field message 'session 'undefined)
                                                   #m())))))))

        ;; eval_at_point operation
        ((or (== op #"eval_at_point") (== op 'eval_at_point))
         (let ((code (xrepl-ptcl-types:get-field message 'code))
               (file (xrepl-ptcl-types:get-field message 'file))
               (line (xrepl-ptcl-types:get-field message 'line))
               (column (xrepl-ptcl-types:get-field message 'column)))
           (if (or (== code 'undefined) (== file 'undefined)
                   (== line 'undefined) (== column 'undefined))
             (tuple 'error 'missing-required-field)
             (tuple 'ok (maps:put #"op" #"eval_at_point"
                                 (maps:put #"code" code
                                          (maps:put #"file" file
                                                   (maps:put #"line" line
                                                            (maps:put #"column" column
                                                                     (maps:put #"session"
                                                                              (xrepl-ptcl-types:get-field message 'session 'undefined)
                                                                              #m()))))))))))

        ;; stream_eval / eval_stream operations
        ((or (== op #"stream_eval") (== op 'stream_eval)
             (== op #"eval_stream") (== op 'eval_stream))
         (let ((code (xrepl-ptcl-types:get-field message 'code)))
           (if (or (== code 'undefined) (not (or (is_binary code) (is_list code))))
             (tuple 'error 'missing-code)
             (tuple 'ok (maps:put #"op" op
                                 (maps:put #"code" code
                                          (maps:put #"session"
                                                   (xrepl-ptcl-types:get-field message 'session 'undefined)
                                                   #m())))))))

        ;; interrupt operation
        ((or (== op #"interrupt") (== op 'interrupt))
         (tuple 'ok (maps:put #"op" #"interrupt"
                             (maps:put #"session"
                                      (xrepl-ptcl-types:get-field message 'session 'undefined)
                                      #m()))))

        ;; cancel operation
        ((or (== op #"cancel") (== op 'cancel))
         (let ((cancel-id (xrepl-ptcl-types:get-field message 'cancel_id)))
           (if (== cancel-id 'undefined)
             (tuple 'error 'missing-cancel-id)
             (tuple 'ok (maps:put #"op" #"cancel"
                                 (maps:put #"cancel_id" cancel-id #m()))))))

        ;; load_file operation
        ((or (== op #"load_file") (== op 'load_file))
         (let ((file (xrepl-ptcl-types:get-field message 'file)))
           (if (== file 'undefined)
             (tuple 'error 'missing-file)
             (tuple 'ok (maps:put #"op" #"load_file"
                                 (maps:put #"file" file
                                          (maps:put #"session"
                                                   (xrepl-ptcl-types:get-field message 'session 'undefined)
                                                   #m())))))))

        ;; Invalid operation
        ('true (tuple 'error 'invalid-evaluation-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))

(defun parse-response (op message)
  "Parse evaluation operation response message.

  Args:
    op: Operation type (eval, eval_multiple, etc.)
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
         ;; eval response
         ((== norm-op #"eval")
          ;; Check for action response
          (let ((action (xrepl-ptcl-types:get-field message 'action 'undefined)))
            (if (== action 'undefined)
              ;; Normal value response - try both value field names
              (let ((value (xrepl-ptcl-types:get-field-any message '(value result))))
                (tuple 'ok (maps:put #"value" value
                                    (maps:put #"session"
                                             (xrepl-ptcl-types:get-field message 'session 'undefined)
                                             #m()))))
              ;; Action response
              (tuple 'ok (maps:put #"action" action
                                  (maps:put #"session"
                                           (xrepl-ptcl-types:get-field message 'session 'undefined)
                                           #m()))))))

         ;; eval_multiple response
         ((== norm-op #"eval_multiple")
          (let ((results (xrepl-ptcl-types:get-field message 'results)))
            (tuple 'ok (maps:put #"results" results
                                (maps:put #"session"
                                         (xrepl-ptcl-types:get-field message 'session 'undefined)
                                         #m())))))

         ;; eval_at_point response (same as eval)
         ((== norm-op #"eval_at_point")
          (let ((value (xrepl-ptcl-types:get-field-any message '(value result))))
            (tuple 'ok (maps:put #"value" value
                                (maps:put #"session"
                                         (xrepl-ptcl-types:get-field message 'session 'undefined)
                                         #m())))))

         ;; stream_eval / eval_stream final response
         ((or (== norm-op #"stream_eval") (== norm-op #"eval_stream"))
          (let ((value (xrepl-ptcl-types:get-field-any message '(value result))))
            (tuple 'ok (maps:put #"value" value
                                (maps:put #"session"
                                         (xrepl-ptcl-types:get-field message 'session 'undefined)
                                         #m())))))

         ;; interrupt response
         ((== norm-op #"interrupt")
          (let ((interrupted (xrepl-ptcl-types:get-field message 'interrupted)))
            (tuple 'ok (maps:put #"interrupted" interrupted
                                (maps:put #"session"
                                         (xrepl-ptcl-types:get-field message 'session 'undefined)
                                         (maps:put #"message"
                                                  (xrepl-ptcl-types:get-field message 'message 'undefined)
                                                  #m()))))))

         ;; cancel response
         ((== norm-op #"cancel")
          (let ((cancelled (xrepl-ptcl-types:get-field message 'cancelled))
                (target-id (xrepl-ptcl-types:get-field message 'target_id)))
            (tuple 'ok (maps:put #"cancelled" cancelled
                                (maps:put #"target_id" target-id #m())))))

         ;; load_file response
         ((== norm-op #"load_file")
          (let ((value (xrepl-ptcl-types:get-field-any message '(value result))))
            (tuple 'ok (maps:put #"value" value
                                (maps:put #"session"
                                         (xrepl-ptcl-types:get-field message 'session 'undefined)
                                         (maps:put #"warnings"
                                                  (xrepl-ptcl-types:get-field message 'warnings 'undefined)
                                                  #m()))))))

         ('true (tuple 'error 'unknown-operation))))

      ;; Streaming status
      ((or (== status #"streaming") (== status 'streaming))
       (let ((output (xrepl-ptcl-types:get-field message 'output))
             (stream (xrepl-ptcl-types:get-field message 'stream)))
         (tuple 'ok (maps:put #"status" #"streaming"
                             (maps:put #"output" output
                                      (maps:put #"stream" stream
                                               (maps:put #"session"
                                                        (xrepl-ptcl-types:get-field message 'session 'undefined)
                                                        #m())))))))

      ;; Error status
      ((or (== status #"error") (== status 'error))
       (tuple 'error (xrepl-ptcl-types:get-field message 'error)))

      ;; Invalid status
      ('true (tuple 'error 'invalid-status)))))

(defun valid-request? (message)
  "Check if message is a valid evaluation request.

  Args:
    message: Message map

  Returns:
    true | false"
  (case (parse-request message)
    (`#(ok ,_) 'true)
    (_ 'false)))

(defun valid-response? (op message)
  "Check if message is a valid evaluation response.

  Args:
    op: Operation type
    message: Message map

  Returns:
    true | false"
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (or (== status #"done")
        (== status 'done)
        (== status #"error")
        (== status 'error)
        (== status #"streaming")
        (== status 'streaming))))
