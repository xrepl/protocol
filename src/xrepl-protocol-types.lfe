(defmodule xrepl-protocol-types
  "Core protocol type definitions and schemas."
  (export
   (message-envelope 0)
   (error-response 2)
   (status-codes 0)
   (validate-field 2)
   (get-field 2)
   (get-field 3)
   (get-field-any 2)
   (get-field-any 3)
   (get-required 2)
   (ensure-binary 1)
   (ensure-binary-key 1)
   (put-aliased 4)
   (put-aliased-list 4)
   (maybe-put-aliased 5)))

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

  MessagePack sends keys as binaries, but LFE code may use atoms.
  This function tries both representations for backwards compatibility.

  Args:
    map: Message map
    key: Field name (atom)
    default: Default value if not found

  Returns:
    Value or default"
  (let ((bin-key (ensure-binary-key key)))
    (case (maps:get bin-key map 'undefined)
      ('undefined
       (maps:get key map default))
      (value value))))

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
   ((is_list value)
    ;; Check if it's a string (list of integers)
    (if (io_lib:printable_list value)
      (list_to_binary value)
      ;; It's a list structure - format it
      (list_to_binary (io_lib:format "~p" (list value)))))
   ((is_atom value) (atom_to_binary value 'utf8))
   ((is_integer value) (integer_to_binary value))
   ((is_float value) (float_to_binary value))
   ('true (list_to_binary (io_lib:format "~p" (list value))))))

(defun ensure-binary-key (key)
  "Convert any key to binary for MessagePack compatibility.

  Args:
    key: Atom, binary, or string key

  Returns:
    Binary key"
  (cond
   ((is_binary key) key)
   ((is_atom key) (atom_to_binary key 'utf8))
   ((is_list key) (list_to_binary key))
   ('true (error (tuple 'badarg key)))))

(defun get-field-any (map keys)
  "Get field trying multiple key names (for aliases).

  Args:
    map: Message map
    keys: List of possible key names (atoms or binaries)

  Returns:
    Value or 'undefined

  Example:
    (get-field-any msg '(candidate text))  ; tries both names"
  (get-field-any map keys 'undefined))

(defun get-field-any (map keys default)
  "Get field trying multiple key names with default.

  Args:
    map: Message map
    keys: List of possible key names (atoms or binaries)
    default: Default value if not found

  Returns:
    Value or default"
  (case keys
    ('() default)
    ((cons key rest)
     ;; Try both binary and atom key for each candidate
     (let ((val (get-field map key 'undefined)))
       (case val
         ('undefined (get-field-any map rest default))
         (_ val))))))

(defun put-aliased (map key1 key2 value)
  "Put value under two key names for compatibility.

  Args:
    map: Map to update
    key1: Primary key name (atom)
    key2: Alias key name (atom)
    value: Value to store

  Returns:
    Updated map with both keys

  Example:
    (put-aliased #m() 'candidate 'text #\"hello\")
    ; => #m(#\"candidate\" #\"hello\" #\"text\" #\"hello\")"
  (let ((bin-key1 (ensure-binary-key key1))
        (bin-key2 (ensure-binary-key key2))
        (bin-val (if (is_atom value)
                   (atom_to_binary value 'utf8)
                   value)))
    (maps:put bin-key2 bin-val
              (maps:put bin-key1 bin-val map))))

(defun put-aliased-list (map key1 key2 values)
  "Put list value under two key names for compatibility.

  Args:
    map: Map to update
    key1: Primary key name (atom)
    key2: Alias key name (atom)
    values: List of values (will NOT be converted to binary)

  Returns:
    Updated map with both keys"
  (let ((bin-key1 (ensure-binary-key key1))
        (bin-key2 (ensure-binary-key key2)))
    (maps:put bin-key2 values
              (maps:put bin-key1 values map))))

(defun maybe-put-aliased (map key1 key2 opts opt-key)
  "Conditionally put aliased field if present in opts.

  Args:
    map: Map to potentially update
    key1: Primary key name
    key2: Alias key name
    opts: Options map
    opt-key: Key to look for in opts

  Returns:
    Updated map if field present, otherwise original map

  Example:
    (maybe-put-aliased base 'session 'session_id opts 'session)"
  (case (get-field opts opt-key 'undefined)
    ('undefined map)
    (value (put-aliased map key1 key2 (ensure-binary value)))))
