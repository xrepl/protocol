(defmodule xrepl-protocol-eval
  "Evaluation operation protocol messages.

  This module defines the structure of evaluation requests and responses
  in the xrepl protocol. Evaluation requests contain code to execute in
  a session context, and responses contain either the evaluation result
  or error information.

  ## Message Structure

  Request:
    #m(op eval
       code \"(+ 1 2)\"
       session \"abc123\")  ; optional

  Success Response:
    #m(status done
       value \"3\"
       session \"abc123\")  ; if session provided

  Action Response (for session switching):
    #m(status done
       action switch
       session \"new-session-id\")

  Error Response:
    #m(status error
       error #m(type eval-error
                message \"Error details\"))

  ## Usage

  Building a request:
    (xrepl-protocol-eval:request #m(code \"(+ 1 2)\"))

  Parsing a response:
    (case (xrepl-protocol-eval:parse-response message)
      (`#(ok #m(value ,v)) (io:format \"Result: ~s~n\" (list v)))
      (`#(error ,err) (handle-error err)))"
  (export
   (request 1)
   (response 1) (response 2)
   (action-response 2)
   (error 2)
   (parse-request 1)
   (parse-response 1)
   (valid-request? 1)
   (valid-response? 1)))

(defun request (opts)
  "Build an eval request message.

  Options:
    code: Code to evaluate (required, string or binary)
    session: Session ID (optional, binary or string)

  Returns:
    Request message map

  Examples:
    (request #m(code \"(+ 1 2)\"))
    (request #m(code \"(+ 1 2)\" session \"abc123\"))"
  (case (xrepl-protocol-types:get-required opts 'code)
    (`#(ok ,code)
     (let ((session (maps:get 'session opts 'undefined)))
       (if (== session 'undefined)
         (map 'op 'eval
              'code (xrepl-protocol-types:ensure-binary code))
         (map 'op 'eval
              'code (xrepl-protocol-types:ensure-binary code)
              'session (xrepl-protocol-types:ensure-binary session)))))
    (error error)))

(defun response (value)
  "Build successful eval response.

  Args:
    value: Evaluation result (binary or string)

  Returns:
    Response message map"
  (response value #m()))

(defun response (value opts)
  "Build successful eval response with options.

  Args:
    value: Evaluation result (binary or string)
    opts: Options map (session, etc.)

  Returns:
    Response message map

  Examples:
    (response \"42\")
    (response \"42\" #m(session \"abc123\"))"
  (let ((base (map 'status 'done
                   'value (xrepl-protocol-types:ensure-binary value))))
    (case (maps:get 'session opts 'undefined)
      ('undefined base)
      (session (maps:put 'session (xrepl-protocol-types:ensure-binary session) base)))))

(defun action-response (action opts)
  "Build action response (for special commands like session switching).

  Args:
    action: Action atom (switch, switch-to-other)
    opts: Options map (session for switch action)

  Returns:
    Response message map

  Examples:
    (action-response 'switch #m(session \"new-id\"))
    (action-response 'switch-to-other #m())"
  (let ((base (map 'status 'done
                   'action action)))
    (case (maps:get 'session opts 'undefined)
      ('undefined base)
      (session (maps:put 'session (xrepl-protocol-types:ensure-binary session) base)))))

(defun error (error-type message)
  "Build error response for eval operation.

  Args:
    error-type: Atom identifying error type (eval-error, etc.)
    message: Error message (binary, string, or term)

  Returns:
    Error response map

  Examples:
    (error 'eval-error \"Division by zero\")"
  (xrepl-protocol-types:error-response error-type message))

(defun parse-request (message)
  "Parse and validate eval request message.

  Args:
    message: Message map

  Returns:
    #(ok parsed-request) | #(error reason)

  Example:
    (parse-request #m(op eval code \"(+ 1 2)\"))"
  (try
    (let ((op (xrepl-protocol-types:get-field message 'op))
          (code (xrepl-protocol-types:get-field message 'code)))
      (if (and (or (== op 'eval) (== op #"eval"))
               (or (is_binary code) (is_list code)))
        (tuple 'ok (map 'code code
                        'session (xrepl-protocol-types:get-field message 'session 'undefined)))
        (tuple 'error 'invalid-eval-request)))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))

(defun parse-response (message)
  "Parse eval response message.

  Args:
    message: Response message map

  Returns:
    #(ok result-map) | #(error error-info)

  Examples:
    (parse-response #m(status done value \"42\"))
    (parse-response #m(status done action switch session \"new-id\"))
    (parse-response #m(status error error #m(type eval-error message \"err\")))"
  (case (xrepl-protocol-types:get-field message 'status)
    ('done
     ;; Check if it's an action response or value response
     (case (xrepl-protocol-types:get-field message 'action 'undefined)
       ('undefined
        ;; Normal value response
        (tuple 'ok (map 'value (xrepl-protocol-types:get-field message 'value)
                        'session (xrepl-protocol-types:get-field message 'session 'undefined))))
       (action
        ;; Action response
        (tuple 'ok (map 'action action
                        'session (xrepl-protocol-types:get-field message 'session 'undefined))))))
    ('error
     (tuple 'error (xrepl-protocol-types:get-field message 'error)))
    (_
     (tuple 'error 'invalid-status))))

(defun valid-request? (message)
  "Check if message is a valid eval request.

  Args:
    message: Message map

  Returns:
    true | false"
  (case (parse-request message)
    (`#(ok ,_) 'true)
    (_ 'false)))

(defun valid-response? (message)
  "Check if message is a valid eval response.

  Args:
    message: Message map

  Returns:
    true | false"
  (let ((status (xrepl-protocol-types:get-field message 'status)))
    (or (== status 'done)
        (== status #"done")
        (== status 'error)
        (== status #"error"))))
