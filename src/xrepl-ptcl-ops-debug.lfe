(defmodule xrepl-ptcl-ops-debug
  "Debugging operation protocol messages.

  This module defines all debugging operations in the xrepl protocol."
  (export
   ;; set_breakpoint operation
   (set-breakpoint-request 1)
   (set-breakpoint-response 1)
   ;; clear_breakpoint operation
   (clear-breakpoint-request 1)
   (clear-breakpoint-response 1)
   ;; list_breakpoints operation
   (list-breakpoints-request 1)
   (list-breakpoints-response 1)
   ;; stacktrace operation
   (stacktrace-request 1)
   (stacktrace-response 1)
   ;; inspect_locals operation
   (inspect-locals-request 1)
   (inspect-locals-response 1)
   ;; eval_in_frame operation
   (eval-in-frame-request 1)
   (eval-in-frame-response 1)
   ;; step operation
   (step-request 1)
   (step-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; set_breakpoint operation

(defun set-breakpoint-request (opts)
  "Build a set_breakpoint request.

  Options:
    file: File path (required)
    line: Line number (required)
    condition: Breakpoint condition (optional)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (set-breakpoint-request #m(file \"src/foo.lfe\" line 42))
    (set-breakpoint-request #m(file \"test.lfe\" line 10 condition \"x > 5\"))"
  (case (xrepl-ptcl-types:get-required opts 'file)
    (`#(ok ,file)
     (case (xrepl-ptcl-types:get-required opts 'line)
       (`#(ok ,line)
        (let* ((base (maps:put #"op" #"set_breakpoint"
                              (maps:put #"file" (xrepl-ptcl-types:ensure-binary file)
                                       (maps:put #"line" line #m()))))
               (with-condition (case (xrepl-ptcl-types:get-field opts 'condition 'undefined)
                                ('undefined base)
                                (cond (maps:put #"condition"
                                               (xrepl-ptcl-types:ensure-binary cond)
                                               base))))
               (with-session (xrepl-ptcl-types:maybe-put-aliased
                              with-condition 'session 'session opts 'session)))
          with-session))
       (error error)))
    (error error)))

(defun set-breakpoint-response (breakpoint)
  "Build a set_breakpoint response.

  Args:
    breakpoint: Breakpoint info map with id, file, line, enabled

  Returns:
    Response message map

  Example:
    (set-breakpoint-response #m(#\"id\" #\"bp-1\"
                                #\"file\" #\"src/foo.lfe\"
                                #\"line\" 42
                                #\"enabled\" true))"
  (maps:put #"status" #"done"
           (maps:put #"breakpoint" breakpoint #m())))

;;; clear_breakpoint operation

(defun clear-breakpoint-request (opts)
  "Build a clear_breakpoint request.

  Options:
    id: Breakpoint ID (required)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (clear-breakpoint-request #m(id \"bp-1\"))
    (clear-breakpoint-request #m(id \"bp-2\" session \"s1\"))"
  (case (xrepl-ptcl-types:get-required opts 'id)
    (`#(ok ,id)
     (let* ((base (maps:put #"op" #"clear_breakpoint"
                           (maps:put #"id" (xrepl-ptcl-types:ensure-binary id)
                                    #m())))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun clear-breakpoint-response (result)
  "Build a clear_breakpoint response.

  Args:
    result: Result map with id and cleared status

  Returns:
    Response message map

  Example:
    (clear-breakpoint-response #m(#\"id\" #\"bp-1\" #\"cleared\" true))"
  (maps:put #"status" #"done"
           (maps:put #"result" result #m())))

;;; list_breakpoints operation

(defun list-breakpoints-request (opts)
  "Build a list_breakpoints request.

  Options:
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (list-breakpoints-request #m())
    (list-breakpoints-request #m(session \"s1\"))"
  (let* ((base (maps:put #"op" #"list_breakpoints" #m()))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

(defun list-breakpoints-response (breakpoints)
  "Build a list_breakpoints response.

  Args:
    breakpoints: List of breakpoint maps

  Returns:
    Response message map

  Example:
    (list-breakpoints-response
      '(#m(#\"id\" #\"bp-1\" #\"file\" #\"src/foo.lfe\" #\"line\" 42 #\"enabled\" true)))"
  (maps:put #"status" #"done"
           (maps:put #"breakpoints" breakpoints #m())))

;;; stacktrace operation

(defun stacktrace-request (opts)
  "Build a stacktrace request.

  Options:
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (stacktrace-request #m())
    (stacktrace-request #m(session \"s1\"))"
  (let* ((base (maps:put #"op" #"stacktrace" #m()))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

(defun stacktrace-response (frames)
  "Build a stacktrace response.

  Args:
    frames: List of stack frame maps with function, file, line, locals

  Returns:
    Response message map

  Example:
    (stacktrace-response
      '(#m(#\"function\" #\"foo/2\" #\"file\" #\"src/foo.lfe\" #\"line\" 42)))"
  (maps:put #"status" #"done"
           (maps:put #"frames" frames #m())))

;;; inspect_locals operation

(defun inspect-locals-request (opts)
  "Build an inspect_locals request.

  Options:
    frame: Frame number to inspect (optional, defaults to current frame)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (inspect-locals-request #m())
    (inspect-locals-request #m(frame 2 session \"s1\"))"
  (let* ((base (maps:put #"op" #"inspect_locals" #m()))
         (with-frame (case (xrepl-ptcl-types:get-field opts 'frame 'undefined)
                      ('undefined base)
                      (frame (maps:put #"frame" frame base))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        with-frame 'session 'session opts 'session)))
    with-session))

(defun inspect-locals-response (locals)
  "Build an inspect_locals response.

  Args:
    locals: Map of local variable names to values

  Returns:
    Response message map

  Example:
    (inspect-locals-response #m(#\"x\" 42 #\"y\" #\"hello\"))"
  (maps:put #"status" #"done"
           (maps:put #"locals" locals #m())))

;;; eval_in_frame operation

(defun eval-in-frame-request (opts)
  "Build an eval_in_frame request.

  Options:
    code: Code to evaluate (required)
    frame: Frame number (optional, defaults to current frame)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (eval-in-frame-request #m(code \"x + y\"))
    (eval-in-frame-request #m(code \"foo(x)\" frame 2 session \"s1\"))"
  (case (xrepl-ptcl-types:get-required opts 'code)
    (`#(ok ,code)
     (let* ((base (maps:put #"op" #"eval_in_frame"
                           (maps:put #"code" (xrepl-ptcl-types:ensure-binary code)
                                    #m())))
            (with-frame (case (xrepl-ptcl-types:get-field opts 'frame 'undefined)
                         ('undefined base)
                         (frame (maps:put #"frame" frame base))))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           with-frame 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun eval-in-frame-response (result)
  "Build an eval_in_frame response.

  Args:
    result: Evaluation result value

  Returns:
    Response message map

  Example:
    (eval-in-frame-response #\"47\")"
  (maps:put #"status" #"done"
           (maps:put #"value" (xrepl-ptcl-types:ensure-binary result)
                    #m())))

;;; step operation

(defun step-request (opts)
  "Build a step request.

  Options:
    type: Step type - 'into', 'over', 'out' (optional, defaults to 'over')
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (step-request #m())
    (step-request #m(type \"into\" session \"s1\"))"
  (let* ((base (maps:put #"op" #"step" #m()))
         (with-type (case (xrepl-ptcl-types:get-field opts 'type 'undefined)
                     ('undefined base)
                     (step-type (maps:put #"type"
                                         (xrepl-ptcl-types:ensure-binary step-type)
                                         base))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        with-type 'session 'session opts 'session)))
    with-session))

(defun step-response (result)
  "Build a step response.

  Args:
    result: Step result map with location, locals

  Returns:
    Response message map

  Example:
    (step-response #m(#\"file\" #\"src/foo.lfe\" #\"line\" 43))"
  (maps:put #"status" #"done"
           (maps:put #"result" result #m())))

;;; Parsing and validation - minimal implementation

(defun parse-request (message)
  "Parse and validate debugging operation request message.

  Args:
    message: Message map (with binary keys from MessagePack)

  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-ptcl-types:get-field message 'op)))
      (cond
        ;; set_breakpoint operation
        ((or (== op #"set_breakpoint") (== op 'set_breakpoint))
         (let ((file (xrepl-ptcl-types:get-field message 'file))
               (line (xrepl-ptcl-types:get-field message 'line)))
           (if (or (== file 'undefined) (== line 'undefined))
             (tuple 'error 'missing-required-field)
             (tuple 'ok (maps:put #"op" #"set_breakpoint"
                                 (maps:put #"file" file
                                          (maps:put #"line" line #m())))))))

        ;; clear_breakpoint operation
        ((or (== op #"clear_breakpoint") (== op 'clear_breakpoint))
         (let ((id (xrepl-ptcl-types:get-field message 'id)))
           (if (== id 'undefined)
             (tuple 'error 'missing-id)
             (tuple 'ok (maps:put #"op" #"clear_breakpoint"
                                 (maps:put #"id" id #m()))))))

        ;; list_breakpoints operation
        ((or (== op #"list_breakpoints") (== op 'list_breakpoints))
         (tuple 'ok (maps:put #"op" #"list_breakpoints" #m())))

        ;; stacktrace operation
        ((or (== op #"stacktrace") (== op 'stacktrace))
         (tuple 'ok (maps:put #"op" #"stacktrace" #m())))

        ;; inspect_locals operation
        ((or (== op #"inspect_locals") (== op 'inspect_locals))
         (tuple 'ok (maps:put #"op" #"inspect_locals" #m())))

        ;; eval_in_frame operation
        ((or (== op #"eval_in_frame") (== op 'eval_in_frame))
         (let ((code (xrepl-ptcl-types:get-field message 'code)))
           (if (== code 'undefined)
             (tuple 'error 'missing-code)
             (tuple 'ok (maps:put #"op" #"eval_in_frame"
                                 (maps:put #"code" code #m()))))))

        ;; step operation
        ((or (== op #"step") (== op 'step))
         (tuple 'ok (maps:put #"op" #"step" #m())))

        ('true (tuple 'error 'invalid-debugging-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))

(defun parse-response (op message)
  "Parse debugging operation response message.

  Args:
    op: Operation type
    message: Response message map

  Returns:
    #(ok result-map) | #(error error-info)"
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (cond
      ((or (== status #"done") (== status 'done))
       (tuple 'ok message))  ;; Simple pass-through for now

      ((or (== status #"error") (== status 'error))
       (tuple 'error (xrepl-ptcl-types:get-field message 'error)))

      ('true (tuple 'error 'invalid-status)))))

(defun valid-request? (message)
  "Check if message is a valid debugging operation request.

  Args:
    message: Message map

  Returns:
    true | false"
  (case (parse-request message)
    (`#(ok ,_) 'true)
    (_ 'false)))

(defun valid-response? (op message)
  "Check if message is a valid debugging operation response.

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
  "Build error response for debugging operation.

  Args:
    error-type: Atom identifying error type
    message: Error message (binary, string, or term)

  Returns:
    Error response map"
  (xrepl-ptcl-types:error-response error-type message))
