(defmodule xrepl-ops-navigation
  "Navigation operation protocol messages.

  This module defines all code navigation operations in the xrepl protocol."
  (export
   ;; find_definition operation
   (find-definition-request 1)
   (find-definition-response 1)
   ;; find_references operation
   (find-references-request 1)
   (find-references-response 1)
   ;; list_definitions operation
   (list-definitions-request 1)
   (list-definitions-response 1)
   ;; symbol_at_point operation
   (symbol-at-point-request 1)
   (symbol-at-point-response 1)
   ;; workspace_symbols operation
   (workspace-symbols-request 1)
   (workspace-symbols-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; find_definition operation

(defun find-definition-request (opts)
  "Build a find_definition request.

  Options:
    symbol: Symbol name to find (required)
    file: File path (optional)
    line: Line number (optional)
    column: Column number (optional)
    position: Position in file (optional)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (find-definition-request #m(symbol \"map:get\"))
    (find-definition-request #m(symbol \"foo\" file \"test.lfe\" line 10 column 5))"
  (case (xrepl-ptcl-types:get-required opts 'symbol)
    (`#(ok ,symbol)
     (let* ((base (maps:put #"op" #"find_definition"
                           (maps:put #"symbol" (xrepl-ptcl-types:ensure-binary symbol)
                                    #m())))
            (with-file (case (xrepl-ptcl-types:get-field opts 'file 'undefined)
                        ('undefined base)
                        (file (maps:put #"file" (xrepl-ptcl-types:ensure-binary file) base))))
            (with-line (case (xrepl-ptcl-types:get-field opts 'line 'undefined)
                        ('undefined with-file)
                        (line (maps:put #"line" line with-file))))
            (with-column (case (xrepl-ptcl-types:get-field opts 'column 'undefined)
                          ('undefined with-line)
                          (col (maps:put #"column" col with-line))))
            (with-position (case (xrepl-ptcl-types:get-field opts 'position 'undefined)
                            ('undefined with-column)
                            (pos (maps:put #"position" pos with-column))))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           with-position 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun find-definition-response (locations)
  "Build a find_definition response.

  Args:
    locations: List of location maps with file, line, column, range

  Returns:
    Response message map

  Example:
    (find-definition-response
      '(#m(#\"file\" #\"src/foo.lfe\" #\"line\" 42 #\"column\" 10)))"
  (maps:put #"status" #"done"
           (maps:put #"locations" locations #m())))

;;; find_references operation

(defun find-references-request (opts)
  "Build a find_references request.

  Options:
    symbol: Symbol name to find references for (required)
    file: File path (optional)
    line: Line number (optional)
    column: Column number (optional)
    include_declaration: Include declaration in results (optional, boolean)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (find-references-request #m(symbol \"map:get\"))
    (find-references-request #m(symbol \"foo\" include_declaration true))"
  (case (xrepl-ptcl-types:get-required opts 'symbol)
    (`#(ok ,symbol)
     (let* ((base (maps:put #"op" #"find_references"
                           (maps:put #"symbol" (xrepl-ptcl-types:ensure-binary symbol)
                                    #m())))
            (with-file (case (xrepl-ptcl-types:get-field opts 'file 'undefined)
                        ('undefined base)
                        (file (maps:put #"file" (xrepl-ptcl-types:ensure-binary file) base))))
            (with-line (case (xrepl-ptcl-types:get-field opts 'line 'undefined)
                        ('undefined with-file)
                        (line (maps:put #"line" line with-file))))
            (with-column (case (xrepl-ptcl-types:get-field opts 'column 'undefined)
                          ('undefined with-line)
                          (col (maps:put #"column" col with-line))))
            (with-include (case (xrepl-ptcl-types:get-field opts 'include_declaration 'undefined)
                           ('undefined with-column)
                           (incl (maps:put #"include_declaration" incl with-column))))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           with-include 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun find-references-response (references)
  "Build a find_references response.

  Args:
    references: List of reference maps with file, line, column, range, context

  Returns:
    Response message map

  Example:
    (find-references-response
      '(#m(#\"file\" #\"src/foo.lfe\" #\"line\" 10 #\"column\" 5 #\"context\" #\"usage\")))"
  (maps:put #"status" #"done"
           (maps:put #"references" references #m())))

;;; list_definitions operation

(defun list-definitions-request (opts)
  "Build a list_definitions request.

  Options:
    file: File path (optional, provide file OR module)
    module: Module name (optional, provide file OR module)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (list-definitions-request #m(file \"src/foo.lfe\"))
    (list-definitions-request #m(module \"lists\"))"
  (let* ((base (maps:put #"op" #"list_definitions" #m()))
         (with-file (case (xrepl-ptcl-types:get-field opts 'file 'undefined)
                     ('undefined base)
                     (file (maps:put #"file" (xrepl-ptcl-types:ensure-binary file) base))))
         (with-module (case (xrepl-ptcl-types:get-field opts 'module 'undefined)
                       ('undefined with-file)
                       (mod (maps:put #"module" (xrepl-ptcl-types:ensure-binary mod) with-file))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                        with-module 'session 'session opts 'session)))
    with-session))

(defun list-definitions-response (definitions)
  "Build a list_definitions response.

  Args:
    definitions: List of definition maps with name, type, line, column, range

  Returns:
    Response message map

  Example:
    (list-definitions-response
      '(#m(#\"name\" #\"foo\" #\"type\" #\"function\" #\"line\" 10 #\"arity\" 2)))"
  (maps:put #"status" #"done"
           (maps:put #"definitions" definitions #m())))

;;; symbol_at_point operation

(defun symbol-at-point-request (opts)
  "Build a symbol_at_point request.

  Options:
    file: File path (required)
    line: Line number (required)
    column: Column number (required)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (symbol-at-point-request #m(file \"test.lfe\" line 10 column 5))"
  (case (xrepl-ptcl-types:get-required opts 'file)
    (`#(ok ,file)
     (case (xrepl-ptcl-types:get-required opts 'line)
       (`#(ok ,line)
        (case (xrepl-ptcl-types:get-required opts 'column)
          (`#(ok ,column)
           (let* ((base (maps:put #"op" #"symbol_at_point"
                                 (maps:put #"file" (xrepl-ptcl-types:ensure-binary file)
                                          (maps:put #"line" line
                                                   (maps:put #"column" column #m())))))
                  (with-session (xrepl-ptcl-types:maybe-put-aliased
                                 base 'session 'session opts 'session)))
             with-session))
          (error error)))
       (error error)))
    (error error)))

(defun symbol-at-point-response (symbol-info)
  "Build a symbol_at_point response.

  Args:
    symbol-info: Map with symbol information (name, type, definition_location, doc)

  Returns:
    Response message map

  Example:
    (symbol-at-point-response
      #m(#\"name\" #\"map:get\" #\"type\" #\"function\" #\"arity\" 2))"
  (maps:put #"status" #"done"
           (maps:put #"symbol" symbol-info #m())))

;;; workspace_symbols operation

(defun workspace-symbols-request (opts)
  "Build a workspace_symbols request.

  Options:
    query: Search query string (required)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (workspace-symbols-request #m(query \"map\"))"
  (case (xrepl-ptcl-types:get-required opts 'query)
    (`#(ok ,query)
     (let* ((base (maps:put #"op" #"workspace_symbols"
                           (maps:put #"query" (xrepl-ptcl-types:ensure-binary query)
                                    #m())))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun workspace-symbols-response (symbols)
  "Build a workspace_symbols response.

  Args:
    symbols: List of symbol maps with name, kind, location, container_name

  Returns:
    Response message map

  Example:
    (workspace-symbols-response
      '(#m(#\"name\" #\"map:get\" #\"kind\" #\"function\"
           #\"location\" #m(#\"file\" #\"src/maps.lfe\" #\"line\" 42))))"
  (maps:put #"status" #"done"
           (maps:put #"symbols" symbols #m())))

;;; Parsing and validation - minimal implementation

(defun parse-request (message)
  "Parse and validate navigation operation request message.

  Args:
    message: Message map (with binary keys from MessagePack)

  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-ptcl-types:get-field message 'op)))
      (cond
        ;; find_definition operation
        ((or (== op #"find_definition") (== op 'find_definition))
         (let ((symbol (xrepl-ptcl-types:get-field message 'symbol)))
           (if (== symbol 'undefined)
             (tuple 'error 'missing-symbol)
             (tuple 'ok (maps:put #"op" #"find_definition"
                                 (maps:put #"symbol" symbol #m()))))))

        ;; find_references operation
        ((or (== op #"find_references") (== op 'find_references))
         (let ((symbol (xrepl-ptcl-types:get-field message 'symbol)))
           (if (== symbol 'undefined)
             (tuple 'error 'missing-symbol)
             (tuple 'ok (maps:put #"op" #"find_references"
                                 (maps:put #"symbol" symbol #m()))))))

        ;; list_definitions operation
        ((or (== op #"list_definitions") (== op 'list_definitions))
         (tuple 'ok (maps:put #"op" #"list_definitions" #m())))

        ;; symbol_at_point operation
        ((or (== op #"symbol_at_point") (== op 'symbol_at_point))
         (tuple 'ok (maps:put #"op" #"symbol_at_point" #m())))

        ;; workspace_symbols operation
        ((or (== op #"workspace_symbols") (== op 'workspace_symbols))
         (let ((query (xrepl-ptcl-types:get-field message 'query)))
           (if (== query 'undefined)
             (tuple 'error 'missing-query)
             (tuple 'ok (maps:put #"op" #"workspace_symbols"
                                 (maps:put #"query" query #m()))))))

        ('true (tuple 'error 'invalid-navigation-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))

(defun parse-response (op message)
  "Parse navigation operation response message.

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
  "Check if message is a valid navigation operation request.

  Args:
    message: Message map

  Returns:
    true | false"
  (case (parse-request message)
    (`#(ok ,_) 'true)
    (_ 'false)))

(defun valid-response? (op message)
  "Check if message is a valid navigation operation response.

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
  "Build error response for navigation operation.

  Args:
    error-type: Atom identifying error type
    message: Error message (binary, string, or term)

  Returns:
    Error response map"
  (xrepl-ptcl-types:error-response error-type message))
