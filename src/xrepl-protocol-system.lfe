(defmodule xrepl-protocol-system
  "System operation protocol messages.

  This module defines the structure of system/meta operations
  in the xrepl protocol, including ping and describe (capabilities).

  ## Message Structures

  Ping Request:
    #m(op ping)

  Ping Response:
    #m(status done
       pong true
       timestamp 1234567890)

  Describe Request:
    #m(op describe)

  Describe Response:
    #m(status done
       versions #m(xrepl \"0.1.0\" lfe \"2.2.0\" erlang \"26\")
       ops [eval clone close ls_sessions describe ping ...]
       transports [tcp unix stdio])

  Error Response:
    #m(status error
       error #m(type error-type
                message \"Error details\"))"
  (export
   ;; Ping operations
   (ping-request 0)
   (ping-response 0)
   (ping-response 1)
   ;; Describe operations
   (describe-request 0)
   (describe-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; Ping operations

(defun ping-request ()
  "Build a ping request.

  Returns:
    Request message map"
  #m(op ping))

(defun ping-response ()
  "Build a ping response with current timestamp.

  Returns:
    Response message map"
  (map 'status 'done
       'pong 'true
       'timestamp (erlang:system_time 'second)))

(defun ping-response (timestamp)
  "Build a ping response with specified timestamp.

  Args:
    timestamp: Unix timestamp in seconds

  Returns:
    Response message map"
  (map 'status 'done
       'pong 'true
       'timestamp timestamp))

;;; Describe operations

(defun describe-request ()
  "Build a describe (capabilities) request.

  Returns:
    Request message map"
  #m(op describe))

(defun describe-response (opts)
  "Build a describe response.

  Options:
    versions: Map of version info (xrepl, lfe, erlang)
    ops: List of supported operations
    transports: List of supported transport types

  Returns:
    Response message map

  Example:
    (describe-response
      #m(versions #m(xrepl \"0.1.0\" lfe \"2.2.0\" erlang \"26\")
         ops '(eval clone close)
         transports '(tcp unix stdio)))"
  (let ((versions (maps:get 'versions opts #m()))
        (ops (maps:get 'ops opts '()))
        (transports (maps:get 'transports opts '())))
    (map 'status 'done
         'versions versions
         'ops ops
         'transports transports)))

;;; Parsing and validation

(defun parse-request (message)
  "Parse and validate system operation request message.

  Args:
    message: Message map

  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-protocol-types:get-field message 'op)))
      (cond
        ;; Ping operation
        ((or (== op 'ping) (== op #"ping"))
         (tuple 'ok (map 'op 'ping)))

        ;; Describe operation
        ((or (== op 'describe) (== op #"describe"))
         (tuple 'ok (map 'op 'describe)))

        ;; Invalid operation
        ('true (tuple 'error 'invalid-system-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))

(defun parse-response (op message)
  "Parse system operation response message.

  Args:
    op: Operation type (ping, describe)
    message: Response message map

  Returns:
    #(ok result-map) | #(error error-info)"
  (case (xrepl-protocol-types:get-field message 'status)
    ('done
     (case op
       ('ping
        (tuple 'ok (map 'pong (xrepl-protocol-types:get-field message 'pong)
                        'timestamp (xrepl-protocol-types:get-field message 'timestamp))))

       ('describe
        (tuple 'ok (map 'versions (xrepl-protocol-types:get-field message 'versions #m())
                        'ops (xrepl-protocol-types:get-field message 'ops '())
                        'transports (xrepl-protocol-types:get-field message 'transports '()))))

       (_ (tuple 'error 'unknown-operation))))

    ('error
     (tuple 'error (xrepl-protocol-types:get-field message 'error)))

    (_
     (tuple 'error 'invalid-status))))

(defun valid-request? (message)
  "Check if message is a valid system operation request.

  Args:
    message: Message map

  Returns:
    true | false"
  (case (parse-request message)
    (`#(ok ,_) 'true)
    (_ 'false)))

(defun valid-response? (op message)
  "Check if message is a valid system operation response.

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
  "Build error response for system operation.

  Args:
    error-type: Atom identifying error type
    message: Error message (binary, string, or term)

  Returns:
    Error response map"
  (xrepl-protocol-types:error-response error-type message))
