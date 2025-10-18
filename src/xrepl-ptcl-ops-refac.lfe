(defmodule xrepl-ptcl-ops-refac
  "Refactoring operation protocol messages.

  This module defines all refactoring operations in the xrepl protocol."
  (export
   ;; rename_symbol operation
   (rename-symbol-request 1)
   (rename-symbol-response 1)
   ;; extract_function operation
   (extract-function-request 1)
   (extract-function-response 1)
   ;; inline_function operation
   (inline-function-request 1)
   (inline-function-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; rename_symbol operation

(defun rename-symbol-request (opts)
  "Build a rename_symbol request.

  Options:
    symbol: Symbol to rename (required, alias: old_name)
    new_name: New name for the symbol (required)
    file: File path (optional)
    line: Line number (optional)
    column: Column number (optional)
    scope: Rename scope (optional, values: file, project, workspace)
    session: Session ID (optional)

  Returns:
    Request message map or error

  Example:
    (rename-symbol-request #m(symbol \"foo\" new_name \"bar\"))
    (rename-symbol-request #m(old_name \"foo\" new_name \"bar\" file \"src/test.lfe\"))
    (rename-symbol-request #m(symbol \"baz\" new_name \"qux\" scope \"project\"))"
  (case (xrepl-ptcl-types:get-required opts 'new_name)
    (`#(ok ,new-name)
     (case (xrepl-ptcl-types:get-field-any opts '(symbol old_name))
       ('undefined
        (tuple 'error 'missing-symbol))
       (symbol
        (let* ((base (maps:put #"op" #"rename_symbol"
                              (xrepl-ptcl-types:put-aliased
                               #m() 'symbol 'old_name
                               (xrepl-ptcl-types:ensure-binary symbol))))
               (with-new-name (maps:put #"new_name"
                                       (xrepl-ptcl-types:ensure-binary new-name)
                                       base))
               (with-file (case (xrepl-ptcl-types:get-field opts 'file 'undefined)
                           ('undefined with-new-name)
                           (f (maps:put #"file"
                                       (xrepl-ptcl-types:ensure-binary f)
                                       with-new-name))))
               (with-line (case (xrepl-ptcl-types:get-field opts 'line 'undefined)
                           ('undefined with-file)
                           (l (maps:put #"line" l with-file))))
               (with-column (case (xrepl-ptcl-types:get-field opts 'column 'undefined)
                             ('undefined with-line)
                             (c (maps:put #"column" c with-line))))
               (with-scope (case (xrepl-ptcl-types:get-field opts 'scope 'undefined)
                            ('undefined with-column)
                            (s (maps:put #"scope"
                                        (xrepl-ptcl-types:ensure-binary s)
                                        with-column))))
               (with-session (xrepl-ptcl-types:maybe-put-aliased
                             with-scope 'session 'session opts 'session)))
          with-session))))
    (error error)))

(defun rename-symbol-response (changes)
  "Build a rename_symbol response.

  Args:
    changes: Map with changes information (files affected, edits made)

  Returns:
    Response message map

  Example:
    (rename-symbol-response #m(#\"files_changed\" 3
                               #\"total_edits\" 12
                               #\"edits\" (list #m(#\"file\" #\"src/foo.lfe\"
                                                   #\"changes\" 5))))"
  (maps:put #"status" #"done"
           (maps:put #"changes" changes #m())))

;;; extract_function operation

(defun extract-function-request (opts)
  "Build an extract_function request.

  Options:
    code: Code to extract (required, alias: selection)
    function_name: Name for the new function (required, alias: name)
    file: File path (optional)
    start_line: Start line of selection (optional, alias: line)
    start_column: Start column of selection (optional, alias: column)
    end_line: End line of selection (optional)
    end_column: End column of selection (optional)
    session: Session ID (optional)

  Returns:
    Request message map or error

  Example:
    (extract-function-request #m(code \"(+ x y)\" function_name \"add-nums\"))
    (extract-function-request #m(selection \"foo\" name \"bar\" file \"test.lfe\"))
    (extract-function-request #m(code \"code\" function_name \"fn\" line 10 column 5))"
  (case (xrepl-ptcl-types:get-field-any opts '(function_name name))
    ('undefined
     (tuple 'error 'missing-function-name))
    (fn-name
     (case (xrepl-ptcl-types:get-field-any opts '(code selection))
       ('undefined
        (tuple 'error 'missing-code))
       (code
        (let* ((base (maps:put #"op" #"extract_function"
                              (xrepl-ptcl-types:put-aliased
                               #m() 'code 'selection
                               (xrepl-ptcl-types:ensure-binary code))))
               (with-name (xrepl-ptcl-types:put-aliased
                          base 'function_name 'name
                          (xrepl-ptcl-types:ensure-binary fn-name)))
               (with-file (case (xrepl-ptcl-types:get-field opts 'file 'undefined)
                           ('undefined with-name)
                           (f (maps:put #"file"
                                       (xrepl-ptcl-types:ensure-binary f)
                                       with-name))))
               (with-start-line (case (xrepl-ptcl-types:get-field-any opts '(start_line line))
                                 ('undefined with-file)
                                 (sl (xrepl-ptcl-types:put-aliased
                                     with-file 'start_line 'line sl))))
               (with-start-col (case (xrepl-ptcl-types:get-field-any opts '(start_column column))
                                ('undefined with-start-line)
                                (sc (xrepl-ptcl-types:put-aliased
                                    with-start-line 'start_column 'column sc))))
               (with-end-line (case (xrepl-ptcl-types:get-field opts 'end_line 'undefined)
                               ('undefined with-start-col)
                               (el (maps:put #"end_line" el with-start-col))))
               (with-end-col (case (xrepl-ptcl-types:get-field opts 'end_column 'undefined)
                              ('undefined with-end-line)
                              (ec (maps:put #"end_column" ec with-end-line))))
               (with-session (xrepl-ptcl-types:maybe-put-aliased
                             with-end-col 'session 'session opts 'session)))
          with-session))))))

(defun extract-function-response (result)
  "Build an extract_function response.

  Args:
    result: Map with extraction result (new function, modified code, location)

  Returns:
    Response message map

  Example:
    (extract-function-response #m(#\"function\" #\"(defun add-nums (x y) (+ x y))\"
                                  #\"modified_code\" #\"(add-nums 1 2)\"
                                  #\"location\" #m(#\"line\" 42)))"
  (maps:put #"status" #"done"
           (maps:put #"result" result #m())))

;;; inline_function operation

(defun inline-function-request (opts)
  "Build an inline_function request.

  Options:
    function: Function name to inline (required, alias: symbol)
    file: File path (optional)
    line: Line number (optional)
    column: Column number (optional)
    all_calls: Inline all calls (optional, boolean, default: false)
    session: Session ID (optional)

  Returns:
    Request message map or error

  Example:
    (inline-function-request #m(function \"add-nums\"))
    (inline-function-request #m(symbol \"foo\" file \"test.lfe\" line 10))
    (inline-function-request #m(function \"bar\" all_calls true))"
  (case (xrepl-ptcl-types:get-field-any opts '(function symbol))
    ('undefined
     (tuple 'error 'missing-function))
    (fn
     (let* ((base (maps:put #"op" #"inline_function"
                           (xrepl-ptcl-types:put-aliased
                            #m() 'function 'symbol
                            (xrepl-ptcl-types:ensure-binary fn))))
            (with-file (case (xrepl-ptcl-types:get-field opts 'file 'undefined)
                        ('undefined base)
                        (f (maps:put #"file"
                                    (xrepl-ptcl-types:ensure-binary f)
                                    base))))
            (with-line (case (xrepl-ptcl-types:get-field opts 'line 'undefined)
                        ('undefined with-file)
                        (l (maps:put #"line" l with-file))))
            (with-column (case (xrepl-ptcl-types:get-field opts 'column 'undefined)
                          ('undefined with-line)
                          (c (maps:put #"column" c with-line))))
            (with-all-calls (case (xrepl-ptcl-types:get-field opts 'all_calls 'undefined)
                             ('undefined with-column)
                             (ac (maps:put #"all_calls" ac with-column))))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                          with-all-calls 'session 'session opts 'session)))
       with-session))))

(defun inline-function-response (result)
  "Build an inline_function response.

  Args:
    result: Map with inlining result (files changed, edits made)

  Returns:
    Response message map

  Example:
    (inline-function-response #m(#\"files_changed\" 2
                                 #\"total_edits\" 5
                                 #\"edits\" (list #m(#\"file\" #\"src/foo.lfe\"
                                                     #\"changes\" 3))))"
  (maps:put #"status" #"done"
           (maps:put #"result" result #m())))

;;; Parsing functions

(defun parse-request (message)
  "Parse a refactoring operation request message.

  Args:
    message: The request message map (with binary keys from MessagePack)

  Returns:
    #(ok parsed-message) or #(error reason)"
  (let ((op (xrepl-ptcl-types:get-field message 'op)))
    (cond
      ;; rename_symbol
      ((or (== op #"rename_symbol") (== op 'rename_symbol))
       (let ((symbol (xrepl-ptcl-types:get-field-any message '(symbol old_name)))
             (new-name (xrepl-ptcl-types:get-field message 'new_name))
             (file (xrepl-ptcl-types:get-field message 'file))
             (line (xrepl-ptcl-types:get-field message 'line))
             (column (xrepl-ptcl-types:get-field message 'column))
             (scope (xrepl-ptcl-types:get-field message 'scope))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (if (or (== symbol 'undefined) (== new-name 'undefined))
           (tuple 'error 'missing-required-field)
           (tuple 'ok (maps:put #"op" #"rename_symbol"
                               (maps:put #"symbol" symbol
                                        (maps:put #"new_name" new-name
                                                 (maps:put #"file" file
                                                          (maps:put #"line" line
                                                                   (maps:put #"column" column
                                                                            (maps:put #"scope" scope
                                                                                     (maps:put #"session" session #m()))))))))))))

      ;; extract_function
      ((or (== op #"extract_function") (== op 'extract_function))
       (let ((code (xrepl-ptcl-types:get-field-any message '(code selection)))
             (fn-name (xrepl-ptcl-types:get-field-any message '(function_name name)))
             (file (xrepl-ptcl-types:get-field message 'file))
             (start-line (xrepl-ptcl-types:get-field-any message '(start_line line)))
             (start-col (xrepl-ptcl-types:get-field-any message '(start_column column)))
             (end-line (xrepl-ptcl-types:get-field message 'end_line))
             (end-col (xrepl-ptcl-types:get-field message 'end_column))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (if (or (== code 'undefined) (== fn-name 'undefined))
           (tuple 'error 'missing-required-field)
           (tuple 'ok (maps:put #"op" #"extract_function"
                               (maps:put #"code" code
                                        (maps:put #"function_name" fn-name
                                                 (maps:put #"file" file
                                                          (maps:put #"start_line" start-line
                                                                   (maps:put #"start_column" start-col
                                                                            (maps:put #"end_line" end-line
                                                                                     (maps:put #"end_column" end-col
                                                                                              (maps:put #"session" session #m())))))))))))))

      ;; inline_function
      ((or (== op #"inline_function") (== op 'inline_function))
       (let ((fn (xrepl-ptcl-types:get-field-any message '(function symbol)))
             (file (xrepl-ptcl-types:get-field message 'file))
             (line (xrepl-ptcl-types:get-field message 'line))
             (column (xrepl-ptcl-types:get-field message 'column))
             (all-calls (xrepl-ptcl-types:get-field message 'all_calls))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (if (== fn 'undefined)
           (tuple 'error 'missing-function)
           (tuple 'ok (maps:put #"op" #"inline_function"
                               (maps:put #"function" fn
                                        (maps:put #"file" file
                                                 (maps:put #"line" line
                                                          (maps:put #"column" column
                                                                   (maps:put #"all_calls" all-calls
                                                                            (maps:put #"session" session #m())))))))))))

      ;; Unknown operation
      ('true
       (tuple 'error 'unknown-operation)))))

(defun parse-response (message op)
  "Parse a refactoring operation response message.

  Args:
    message: The response message map (with binary keys from MessagePack)
    op: The operation name (atom or binary)

  Returns:
    #(ok parsed-response) or #(error reason)"
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (cond
      ;; rename_symbol response
      ((or (== op #"rename_symbol") (== op 'rename_symbol))
       (let ((changes (xrepl-ptcl-types:get-field message 'changes)))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"changes" changes #m())))))

      ;; extract_function response
      ((or (== op #"extract_function") (== op 'extract_function))
       (let ((result (xrepl-ptcl-types:get-field message 'result)))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"result" result #m())))))

      ;; inline_function response
      ((or (== op #"inline_function") (== op 'inline_function))
       (let ((result (xrepl-ptcl-types:get-field message 'result)))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"result" result #m())))))

      ;; Unknown operation
      ('true
       (tuple 'error 'unknown-operation)))))

;;; Validation functions

(defun valid-request? (message)
  "Validate a refactoring operation request message.

  Args:
    message: The request message map

  Returns:
    true if valid, false otherwise"
  (let ((op (xrepl-ptcl-types:get-field message 'op)))
    (cond
      ;; rename_symbol: requires symbol and new_name
      ((or (== op #"rename_symbol") (== op 'rename_symbol))
       (let ((symbol (xrepl-ptcl-types:get-field-any message '(symbol old_name)))
             (new-name (xrepl-ptcl-types:get-field message 'new_name)))
         (and (not (== symbol 'undefined))
              (not (== new-name 'undefined)))))

      ;; extract_function: requires code and function_name
      ((or (== op #"extract_function") (== op 'extract_function))
       (let ((code (xrepl-ptcl-types:get-field-any message '(code selection)))
             (fn-name (xrepl-ptcl-types:get-field-any message '(function_name name))))
         (and (not (== code 'undefined))
              (not (== fn-name 'undefined)))))

      ;; inline_function: requires function
      ((or (== op #"inline_function") (== op 'inline_function))
       (let ((fn (xrepl-ptcl-types:get-field-any message '(function symbol))))
         (not (== fn 'undefined))))

      ;; Unknown or missing op
      ('true 'false))))

(defun valid-response? (message op)
  "Validate a refactoring operation response message.

  Args:
    message: The response message map
    op: The operation name

  Returns:
    true if valid, false otherwise"
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (cond
      ;; All responses require status
      ((== status 'undefined) 'false)

      ;; rename_symbol: requires changes
      ((or (== op #"rename_symbol") (== op 'rename_symbol))
       (let ((changes (xrepl-ptcl-types:get-field message 'changes)))
         (not (== changes 'undefined))))

      ;; extract_function: requires result
      ((or (== op #"extract_function") (== op 'extract_function))
       (let ((result (xrepl-ptcl-types:get-field message 'result)))
         (not (== result 'undefined))))

      ;; inline_function: requires result
      ((or (== op #"inline_function") (== op 'inline_function))
       (let ((result (xrepl-ptcl-types:get-field message 'result)))
         (not (== result 'undefined))))

      ;; Unknown operation
      ('true 'false))))

;;; Error handling

(defun error (type msg)
  "Build an error response.

  Args:
    type: Error type (atom)
    msg: Error message (string or binary)

  Returns:
    Error response map

  Example:
    (error 'missing-function \"Function name is required\")"
  (maps:put #"status" #"error"
           (maps:put #"error-type" (xrepl-ptcl-types:ensure-binary type)
                    (maps:put #"error" (xrepl-ptcl-types:ensure-binary msg) #m()))))
