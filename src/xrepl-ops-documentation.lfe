(defmodule xrepl-ops-documentation
  "Documentation operation protocol messages.

  This module defines all documentation operations in the xrepl protocol."
  (export
   ;; doc operation
   (doc-request 1)
   (doc-response 1)
   ;; module_doc operation
   (module-doc-request 1)
   (module-doc-response 1)
   ;; search_docs operation
   (search-docs-request 1)
   (search-docs-response 1)
   ;; generate_doc operation
   (generate-doc-request 1)
   (generate-doc-response 1)
   ;; module_summary operation
   (module-summary-request 1)
   (module-summary-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; doc operation

(defun doc-request (opts)
  "Build a doc request.

  Options:
    symbol: Symbol name to get documentation for (required)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (doc-request #m(symbol \"map:get\"))
    (doc-request #m(symbol \"lists:map\" session \"s1\"))"
  (case (xrepl-protocol-types:get-required opts 'symbol)
    (`#(ok ,symbol)
     (let* ((base (maps:put #"op" #"doc"
                           (maps:put #"symbol" (xrepl-protocol-types:ensure-binary symbol)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun doc-response (documentation)
  "Build a doc response.

  Args:
    documentation: Documentation map with doc text, arglists, examples, etc.

  Returns:
    Response message map

  Example:
    (doc-response #m(#\"doc\" #\"Get value from map\"
                     #\"arglists\" '(#\"(map:get key map)\")))"
  (maps:put #"status" #"done"
           (maps:put #"doc" documentation #m())))

;;; module_doc operation

(defun module-doc-request (opts)
  "Build a module_doc request.

  Options:
    module: Module name (required)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (module-doc-request #m(module \"lists\"))
    (module-doc-request #m(module \"maps\" session \"s1\"))"
  (case (xrepl-protocol-types:get-required opts 'module)
    (`#(ok ,module)
     (let* ((base (maps:put #"op" #"module_doc"
                           (maps:put #"module" (xrepl-protocol-types:ensure-binary module)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun module-doc-response (documentation)
  "Build a module_doc response.

  Args:
    documentation: Module documentation map with overview, functions, types, etc.

  Returns:
    Response message map

  Example:
    (module-doc-response #m(#\"module\" #\"lists\"
                            #\"doc\" #\"List processing functions\"
                            #\"functions\" (list ...)))"
  (maps:put #"status" #"done"
           (maps:put #"doc" documentation #m())))

;;; search_docs operation

(defun search-docs-request (opts)
  "Build a search_docs request.

  Options:
    query: Search query string (required)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (search-docs-request #m(query \"map\"))
    (search-docs-request #m(query \"list filter\" session \"s1\"))"
  (case (xrepl-protocol-types:get-required opts 'query)
    (`#(ok ,query)
     (let* ((base (maps:put #"op" #"search_docs"
                           (maps:put #"query" (xrepl-protocol-types:ensure-binary query)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun search-docs-response (results)
  "Build a search_docs response.

  Args:
    results: List of search result maps with symbol, doc snippet, relevance

  Returns:
    Response message map

  Example:
    (search-docs-response
      '(#m(#\"symbol\" #\"map:get\"
           #\"doc\" #\"Get value from map\"
           #\"relevance\" 0.95)))"
  (maps:put #"status" #"done"
           (maps:put #"results" results #m())))

;;; generate_doc operation

(defun generate-doc-request (opts)
  "Build a generate_doc request.

  Options:
    target: Target to generate docs for (file, module, or function) (required)
    format: Output format (html, markdown, etc.) (optional)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (generate-doc-request #m(target \"src/foo.lfe\"))
    (generate-doc-request #m(target \"lists:map\" format \"markdown\"))"
  (case (xrepl-protocol-types:get-required opts 'target)
    (`#(ok ,target)
     (let* ((base (maps:put #"op" #"generate_doc"
                           (maps:put #"target" (xrepl-protocol-types:ensure-binary target)
                                    #m())))
            (with-format (case (xrepl-protocol-types:get-field opts 'format 'undefined)
                          ('undefined base)
                          (fmt (maps:put #"format" (xrepl-protocol-types:ensure-binary fmt) base))))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           with-format 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun generate-doc-response (result)
  "Build a generate_doc response.

  Args:
    result: Generated documentation map with content, format, path

  Returns:
    Response message map

  Example:
    (generate-doc-response #m(#\"content\" #\"# Module: lists\\n...\"
                              #\"format\" #\"markdown\"
                              #\"path\" #\"docs/lists.md\"))"
  (maps:put #"status" #"done"
           (maps:put #"result" result #m())))

;;; module_summary operation

(defun module-summary-request (opts)
  "Build a module_summary request.

  Options:
    module: Module name (required)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (module-summary-request #m(module \"lists\"))
    (module-summary-request #m(module \"maps\" session \"s1\"))"
  (case (xrepl-protocol-types:get-required opts 'module)
    (`#(ok ,module)
     (let* ((base (maps:put #"op" #"module_summary"
                           (maps:put #"module" (xrepl-protocol-types:ensure-binary module)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun module-summary-response (summary)
  "Build a module_summary response.

  Args:
    summary: Module summary map with name, description, exports count, etc.

  Returns:
    Response message map

  Example:
    (module-summary-response #m(#\"module\" #\"lists\"
                                #\"description\" #\"List processing functions\"
                                #\"exports\" 42
                                #\"functions\" 38
                                #\"types\" 4))"
  (maps:put #"status" #"done"
           (maps:put #"summary" summary #m())))

;;; Parsing and validation - minimal implementation

(defun parse-request (message)
  "Parse and validate documentation operation request message.

  Args:
    message: Message map (with binary keys from MessagePack)

  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-protocol-types:get-field message 'op)))
      (cond
        ;; doc operation
        ((or (== op #"doc") (== op 'doc))
         (let ((symbol (xrepl-protocol-types:get-field message 'symbol)))
           (if (== symbol 'undefined)
             (tuple 'error 'missing-symbol)
             (tuple 'ok (maps:put #"op" #"doc"
                                 (maps:put #"symbol" symbol #m()))))))

        ;; module_doc operation
        ((or (== op #"module_doc") (== op 'module_doc))
         (let ((module (xrepl-protocol-types:get-field message 'module)))
           (if (== module 'undefined)
             (tuple 'error 'missing-module)
             (tuple 'ok (maps:put #"op" #"module_doc"
                                 (maps:put #"module" module #m()))))))

        ;; search_docs operation
        ((or (== op #"search_docs") (== op 'search_docs))
         (let ((query (xrepl-protocol-types:get-field message 'query)))
           (if (== query 'undefined)
             (tuple 'error 'missing-query)
             (tuple 'ok (maps:put #"op" #"search_docs"
                                 (maps:put #"query" query #m()))))))

        ;; generate_doc operation
        ((or (== op #"generate_doc") (== op 'generate_doc))
         (let ((target (xrepl-protocol-types:get-field message 'target)))
           (if (== target 'undefined)
             (tuple 'error 'missing-target)
             (tuple 'ok (maps:put #"op" #"generate_doc"
                                 (maps:put #"target" target #m()))))))

        ;; module_summary operation
        ((or (== op #"module_summary") (== op 'module_summary))
         (let ((module (xrepl-protocol-types:get-field message 'module)))
           (if (== module 'undefined)
             (tuple 'error 'missing-module)
             (tuple 'ok (maps:put #"op" #"module_summary"
                                 (maps:put #"module" module #m()))))))

        ('true (tuple 'error 'invalid-documentation-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))

(defun parse-response (op message)
  "Parse documentation operation response message.

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
  "Check if message is a valid documentation operation request.

  Args:
    message: Message map

  Returns:
    true | false"
  (case (parse-request message)
    (`#(ok ,_) 'true)
    (_ 'false)))

(defun valid-response? (op message)
  "Check if message is a valid documentation operation response.

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
  "Build error response for documentation operation.

  Args:
    error-type: Atom identifying error type
    message: Error message (binary, string, or term)

  Returns:
    Error response map"
  (xrepl-protocol-types:error-response error-type message))
