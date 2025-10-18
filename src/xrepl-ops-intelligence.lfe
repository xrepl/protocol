(defmodule xrepl-ops-intelligence
  "Code intelligence operation protocol messages.

  This module defines all code intelligence operations in the xrepl protocol."
  (export
   ;; complete operation
   (complete-request 1)
   (complete-response 1) (complete-response 2)
   ;; complete_context operation
   (complete-context-request 1)
   (complete-context-response 2)
   ;; signature / signature_help operations (aliases)
   (signature-request 1)
   (signature-response 1) (signature-response 2)
   ;; eldoc operation
   (eldoc-request 1)
   (eldoc-response 1) (eldoc-response 2)
   ;; eldoc_batch operation
   (eldoc-batch-request 1)
   (eldoc-batch-response 1)
   ;; type_info operation
   (type-info-request 1)
   (type-info-response 1)
   ;; format / format_code operations (aliases)
   (format-request 1)
   (format-response 1)
   ;; apropos operation
   (apropos-request 1)
   (apropos-response 1)
   ;; indent_info operation
   (indent-info-request 1)
   (indent-info-response 1)
   ;; buffer_analysis operation
   (buffer-analysis-request 1)
   (buffer-analysis-response 1)
   ;; highlight_regions operation
   (highlight-regions-request 1)
   (highlight-regions-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; complete operation

(defun complete-request (opts)
  "Build a complete request.

  Options:
    prefix: Completion prefix (required)
    session: Session ID (optional)
    cursor: Cursor position in prefix - Emacs style (optional)
    position: Cursor position in code - VSCode style (optional)
    code: Full code context - VSCode style (optional)
    context: Context map with type, module, etc. (optional)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'prefix)
    (`#(ok ,prefix)
     (let* ((base (maps:put #"op" #"complete"
                           (maps:put #"prefix" (xrepl-protocol-types:ensure-binary prefix)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session))
            (with-cursor (case (xrepl-protocol-types:get-field opts 'cursor 'undefined)
                          ('undefined with-session)
                          (cursor (maps:put #"cursor" cursor with-session))))
            (with-position (case (xrepl-protocol-types:get-field opts 'position 'undefined)
                            ('undefined with-cursor)
                            (pos (maps:put #"position" pos with-cursor))))
            (with-code (case (xrepl-protocol-types:get-field opts 'code 'undefined)
                        ('undefined with-position)
                        (code (maps:put #"code" (xrepl-protocol-types:ensure-binary code)
                                       with-position))))
            (with-context (case (xrepl-protocol-types:get-field opts 'context 'undefined)
                           ('undefined with-code)
                           (ctx (maps:put #"context" ctx with-code)))))
       with-context))
    (error error)))

(defun complete-response (candidates)
  "Build a complete response.

  Args:
    candidates: List of completion candidate maps

  Returns:
    Response message map"
  (complete-response candidates #m()))

(defun complete-response (candidates opts)
  "Build a complete response with options.

  Args:
    candidates: List of completion candidate maps
    opts: Options (session, etc.)

  Returns:
    Response message map with BOTH 'candidates' and 'completions' fields"
  (let* ((base (maps:put #"status" #"done"
                        ;; Put candidates under BOTH field names
                        (xrepl-protocol-types:put-aliased-list #m()
                                                               'candidates
                                                               'completions
                                                               candidates)))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

;;; complete_context operation

(defun complete-context-request (opts)
  "Build a complete_context request.

  Options:
    file: File path (required)
    line: Line number (required)
    column: Column number (required)
    code: Full buffer contents (optional)
    session: Session ID (optional)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'file)
    (`#(ok ,file)
     (case (xrepl-protocol-types:get-required opts 'line)
       (`#(ok ,line)
        (case (xrepl-protocol-types:get-required opts 'column)
          (`#(ok ,column)
           (let* ((base (maps:put #"op" #"complete_context"
                                 (maps:put #"file" (xrepl-protocol-types:ensure-binary file)
                                          (maps:put #"line" line
                                                   (maps:put #"column" column #m())))))
                  (with-code (case (xrepl-protocol-types:get-field opts 'code 'undefined)
                              ('undefined base)
                              (code (maps:put #"code" (xrepl-protocol-types:ensure-binary code) base))))
                  (with-session (xrepl-protocol-types:maybe-put-aliased
                                 with-code 'session 'session opts 'session)))
             with-session))
          (error error)))
       (error error)))
    (error error)))

(defun complete-context-response (candidates context-info)
  "Build a complete_context response.

  Args:
    candidates: List of completion candidates
    context-info: Context information map

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (xrepl-protocol-types:put-aliased-list
            (maps:put #"context" context-info #m())
            'candidates
            'completions
            candidates)))

;;; signature / signature_help operations

(defun signature-request (opts)
  "Build a signature or signature_help request.

  Options:
    symbol: Symbol to get signature for (optional)
    file: File path (optional)
    line: Line number (optional)
    column: Column number (optional)
    code: Code context (optional)
    position: Position in code (optional)
    contents: Buffer contents (optional)
    session: Session ID (optional)
    op_name: 'signature or 'signature_help (optional, defaults to signature)

  Returns:
    Request message map"
  (let* ((op-name (xrepl-protocol-types:get-field opts 'op_name 'signature))
         (base (maps:put #"op" (xrepl-protocol-types:ensure-binary op-name) #m()))
         (with-symbol (case (xrepl-protocol-types:get-field opts 'symbol 'undefined)
                       ('undefined base)
                       (sym (maps:put #"symbol" (xrepl-protocol-types:ensure-binary sym) base))))
         (with-file (case (xrepl-protocol-types:get-field opts 'file 'undefined)
                     ('undefined with-symbol)
                     (file (maps:put #"file" (xrepl-protocol-types:ensure-binary file)
                                    with-symbol))))
         (with-line (case (xrepl-protocol-types:get-field opts 'line 'undefined)
                     ('undefined with-file)
                     (line (maps:put #"line" line with-file))))
         (with-column (case (xrepl-protocol-types:get-field opts 'column 'undefined)
                       ('undefined with-line)
                       (col (maps:put #"column" col with-line))))
         (with-code (case (xrepl-protocol-types:get-field opts 'code 'undefined)
                     ('undefined with-column)
                     (code (maps:put #"code" (xrepl-protocol-types:ensure-binary code)
                                    with-column))))
         (with-position (case (xrepl-protocol-types:get-field opts 'position 'undefined)
                         ('undefined with-code)
                         (pos (maps:put #"position" pos with-code))))
         (with-contents (case (xrepl-protocol-types:get-field opts 'contents 'undefined)
                         ('undefined with-position)
                         (cont (maps:put #"contents" (xrepl-protocol-types:ensure-binary cont)
                                        with-position))))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        with-contents 'session 'session opts 'session)))
    with-session))

(defun signature-response (signatures)
  "Build a signature response.

  Args:
    signatures: List of signature maps

  Returns:
    Response message map"
  (signature-response signatures #m()))

(defun signature-response (signatures opts)
  "Build a signature response with options.

  Args:
    signatures: List of signature maps
    opts: Options (session, etc.)

  Returns:
    Response message map"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"signatures" signatures #m())))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

;;; eldoc operation

(defun eldoc-request (opts)
  "Build an eldoc request.

  Options:
    symbol: Symbol to get eldoc for (required)
    session: Session ID (optional)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'symbol)
    (`#(ok ,symbol)
     (let* ((base (maps:put #"op" #"eldoc"
                           (maps:put #"symbol" (xrepl-protocol-types:ensure-binary symbol)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun eldoc-response (info)
  "Build an eldoc response.

  Args:
    info: Eldoc info map with signature, arglists, doc, etc.

  Returns:
    Response message map"
  (eldoc-response info #m()))

(defun eldoc-response (info opts)
  "Build an eldoc response with options.

  Args:
    info: Eldoc info map
    opts: Options (session, etc.)

  Returns:
    Response message map"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"eldoc" info #m())))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

;;; eldoc_batch operation

(defun eldoc-batch-request (opts)
  "Build an eldoc_batch request.

  Options:
    symbols: List of symbols to get eldoc for (required)
    session: Session ID (optional)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'symbols)
    (`#(ok ,symbols)
     (let* ((base (maps:put #"op" #"eldoc_batch"
                           (maps:put #"symbols" symbols #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun eldoc-batch-response (results)
  "Build an eldoc_batch response.

  Args:
    results: List of eldoc result maps

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"results" results #m())))

;;; type_info operation

(defun type-info-request (opts)
  "Build a type_info request.

  Options:
    symbol: Symbol to get type info for (required)
    session: Session ID (optional)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'symbol)
    (`#(ok ,symbol)
     (let* ((base (maps:put #"op" #"type_info"
                           (maps:put #"symbol" (xrepl-protocol-types:ensure-binary symbol)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun type-info-response (type-info)
  "Build a type_info response.

  Args:
    type-info: Type information map

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"type_info" type-info #m())))

;;; format / format_code operation

(defun format-request (opts)
  "Build a format or format_code request.

  Options:
    code: Code to format (required)
    session: Session ID (optional)
    options: Formatting options map (optional)
    op_name: 'format or 'format_code (optional, defaults to format)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'code)
    (`#(ok ,code)
     (let* ((op-name (xrepl-protocol-types:get-field opts 'op_name 'format))
            (base (maps:put #"op" (xrepl-protocol-types:ensure-binary op-name)
                           (maps:put #"code" (xrepl-protocol-types:ensure-binary code)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session))
            (with-options (case (xrepl-protocol-types:get-field opts 'options 'undefined)
                           ('undefined with-session)
                           (fmt-opts (maps:put #"options" fmt-opts with-session)))))
       with-options))
    (error error)))

(defun format-response (formatted)
  "Build a format response.

  Args:
    formatted: Formatted code string

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"formatted" (xrepl-protocol-types:ensure-binary formatted)
                    #m())))

;;; apropos operation

(defun apropos-request (opts)
  "Build an apropos request.

  Options:
    query: Search query (required)
    session: Session ID (optional)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'query)
    (`#(ok ,query)
     (let* ((base (maps:put #"op" #"apropos"
                           (maps:put #"query" (xrepl-protocol-types:ensure-binary query)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun apropos-response (results)
  "Build an apropos response.

  Args:
    results: List of search result maps

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"results" results #m())))

;;; indent_info operation

(defun indent-info-request (opts)
  "Build an indent_info request.

  Options:
    line: Line to get indent info for (required)
    session: Session ID (optional)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'line)
    (`#(ok ,line)
     (let* ((base (maps:put #"op" #"indent_info"
                           (maps:put #"line" line #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun indent-info-response (indent-info)
  "Build an indent_info response.

  Args:
    indent-info: Indentation information map

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"indent_info" indent-info #m())))

;;; buffer_analysis operation

(defun buffer-analysis-request (opts)
  "Build a buffer_analysis request.

  Options:
    code: Buffer contents (required)
    file: File path (optional)
    session: Session ID (optional)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'code)
    (`#(ok ,code)
     (let* ((base (maps:put #"op" #"buffer_analysis"
                           (maps:put #"code" (xrepl-protocol-types:ensure-binary code)
                                    #m())))
            (with-file (case (xrepl-protocol-types:get-field opts 'file 'undefined)
                        ('undefined base)
                        (file (maps:put #"file" (xrepl-protocol-types:ensure-binary file) base))))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           with-file 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun buffer-analysis-response (analysis)
  "Build a buffer_analysis response.

  Args:
    analysis: Analysis result map

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"analysis" analysis #m())))

;;; highlight_regions operation

(defun highlight-regions-request (opts)
  "Build a highlight_regions request.

  Options:
    code: Code to highlight (required)
    session: Session ID (optional)

  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'code)
    (`#(ok ,code)
     (let* ((base (maps:put #"op" #"highlight_regions"
                           (maps:put #"code" (xrepl-protocol-types:ensure-binary code)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun highlight-regions-response (regions)
  "Build a highlight_regions response.

  Args:
    regions: List of highlight region maps

  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"regions" regions #m())))

;;; Parsing and validation - minimal implementation

(defun parse-request (message)
  "Parse and validate intelligence operation request message.

  Args:
    message: Message map (with binary keys from MessagePack)

  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-protocol-types:get-field message 'op)))
      (cond
        ((or (== op #"complete") (== op 'complete))
         (let ((prefix (xrepl-protocol-types:get-field message 'prefix)))
           (if (== prefix 'undefined)
             (tuple 'error 'missing-prefix)
             (tuple 'ok (maps:put #"op" #"complete"
                                 (maps:put #"prefix" prefix #m()))))))

        ((or (== op #"complete_context") (== op 'complete_context))
         (tuple 'ok (maps:put #"op" #"complete_context" #m())))

        ((or (== op #"signature") (== op 'signature)
             (== op #"signature_help") (== op 'signature_help))
         (tuple 'ok (maps:put #"op" op #m())))

        ((or (== op #"eldoc") (== op 'eldoc))
         (tuple 'ok (maps:put #"op" #"eldoc" #m())))

        ((or (== op #"eldoc_batch") (== op 'eldoc_batch))
         (tuple 'ok (maps:put #"op" #"eldoc_batch" #m())))

        ((or (== op #"type_info") (== op 'type_info))
         (tuple 'ok (maps:put #"op" #"type_info" #m())))

        ((or (== op #"format") (== op 'format)
             (== op #"format_code") (== op 'format_code))
         (tuple 'ok (maps:put #"op" op #m())))

        ((or (== op #"apropos") (== op 'apropos))
         (tuple 'ok (maps:put #"op" #"apropos" #m())))

        ((or (== op #"indent_info") (== op 'indent_info))
         (tuple 'ok (maps:put #"op" #"indent_info" #m())))

        ((or (== op #"buffer_analysis") (== op 'buffer_analysis))
         (tuple 'ok (maps:put #"op" #"buffer_analysis" #m())))

        ((or (== op #"highlight_regions") (== op 'highlight_regions))
         (tuple 'ok (maps:put #"op" #"highlight_regions" #m())))

        ('true (tuple 'error 'invalid-intelligence-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))

(defun parse-response (op message)
  "Parse intelligence operation response message.

  Args:
    op: Operation type
    message: Response message map

  Returns:
    #(ok result-map) | #(error error-info)"
  (let ((status (xrepl-protocol-types:get-field message 'status)))
    (cond
      ((or (== status #"done") (== status 'done))
       (tuple 'ok message))  ;; Simple pass-through for now

      ((or (== status #"error") (== status 'error))
       (tuple 'error (xrepl-protocol-types:get-field message 'error)))

      ('true (tuple 'error 'invalid-status)))))

(defun valid-request? (message)
  "Check if message is a valid intelligence operation request.

  Args:
    message: Message map

  Returns:
    true | false"
  (case (parse-request message)
    (`#(ok ,_) 'true)
    (_ 'false)))

(defun valid-response? (op message)
  "Check if message is a valid intelligence operation response.

  Args:
    op: Operation type
    message: Message map

  Returns:
    true | false"
  (let ((status (xrepl-protocol-types:get-field message 'status)))
    (or (== status #"done")
        (== status 'done)
        (== status #"error")
        (== status 'error))))

;;; Errors

(defun error (error-type message)
  "Build error response for intelligence operation.

  Args:
    error-type: Atom identifying error type
    message: Error message (binary, string, or term)

  Returns:
    Error response map"
  (xrepl-protocol-types:error-response error-type message))
