(defmodule xrepl-protocol-types
  "Core protocol type definitions and schemas."
  (export
   (message-envelope 0)
   (error-response 2)
   (status-codes 0)
   (validate-field 2)
   (get-field 2)
   (get-field 3)
   (get-required 2)
   (ensure-binary 1)))

;; Message envelope structure
(defun message-envelope ()
  "Required fields in every protocol message."
  '(id      ;; Message identifier
    op))    ;; Operation name

;; Standard error response
(defun error-response (error-type message)
  "Construct standardized error response.

  Args:
    error-type: Atom identifying the error type
    message: Error message (binary, string, or term)

  Returns:
    Error response map"
  (map 'status 'error
       'error (map 'type error-type
                   'message (ensure-binary message))))

;; Status codes
(defun status-codes ()
  "Valid status codes for protocol messages."
  '(done error pending))

;; Field validation
(defun validate-field (field-spec value)
  "Validate a field value against its specification.

  Args:
    field-spec: Field specification (TBD)
    value: Value to validate

  Returns:
    ok | {error, reason}"
  ;; TODO: Implement field validation based on spec
  'ok)

;; Helper functions for working with message maps

(defun get-field (map key)
  "Get field from message map (tries both binary and atom keys).

  Args:
    map: Message map
    key: Field name (atom)

  Returns:
    Value or 'undefined"
  (get-field map key 'undefined))

(defun get-field (map key default)
  "Get field from message map with default.

  MessagePack sends keys as binaries, but LFE code uses atoms.
  This function tries both representations.

  Args:
    map: Message map
    key: Field name (atom)
    default: Default value if not found

  Returns:
    Value or default"
  (case (maps:get (ensure-binary-key key) map 'undefined)
    ('undefined
     (maps:get key map default))
    (value value)))

(defun get-required (map key)
  "Get required field from map or return error tuple.

  Args:
    map: Message map
    key: Field name (atom)

  Returns:
    {ok, value} | {error, {missing-required-field, key}}"
  (case (get-field map key 'undefined)
    ('undefined (tuple 'error (tuple 'missing-required-field key)))
    (value (tuple 'ok value))))

(defun ensure-binary (value)
  "Convert value to binary.

  Args:
    value: Any Erlang term

  Returns:
    Binary representation"
  (cond
    ((is_binary value) value)
    ((is_list value) (list_to_binary value))
    ((is_atom value) (atom_to_binary value 'utf8))
    ('true (list_to_binary (io_lib:format "~p" (list value))))))

(defun ensure-binary-key (key)
  "Convert atom key to binary for MessagePack compatibility.

  Args:
    key: Atom key

  Returns:
    Binary key"
  (if (is_binary key)
    key
    (list_to_binary (atom_to_list key))))
