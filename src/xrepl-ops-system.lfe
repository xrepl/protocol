(defmodule xrepl-ops-system
  "System operation protocol messages.

  This module defines all system/meta operations in the xrepl protocol."
  (export
   ;; ping operation
   (ping-request 0)
   (ping-response 0) (ping-response 1)
   ;; describe operation
   (describe-request 0)
   (describe-response 1)
   ;; capabilities operation
   (capabilities-request 0)
   (capabilities-response 1)
   ;; version operation
   (version-request 0)
   (version-response 1)
   ;; loaded_modules operation
   (loaded-modules-request 1)
   (loaded-modules-response 1)
   ;; module_info operation
   (module-info-request 1)
   (module-info-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; ping operation

(defun ping-request ()
  "Build a ping request.

  Returns:
    Request message map with binary keys"
  #m(#"op" #"ping"))

(defun ping-response ()
  "Build a ping response with current timestamp.

  Returns:
    Response message map with binary keys"
  (maps:put #"status" #"done"
           (maps:put #"pong" 'true
                    (maps:put #"timestamp" (erlang:system_time 'second)
                             #m()))))

(defun ping-response (timestamp)
  "Build a ping response with specified timestamp.

  Args:
    timestamp: Unix timestamp in seconds

  Returns:
    Response message map with binary keys"
  (maps:put #"status" #"done"
           (maps:put #"pong" 'true
                    (maps:put #"timestamp" timestamp
                             #m()))))

;;; describe operation

(defun describe-request ()
  "Build a describe (capabilities) request.

  Returns:
    Request message map with binary keys"
  #m(#"op" #"describe"))

(defun describe-response (opts)
  "Build a describe response.

  Options:
    versions: Map of version info (xrepl, lfe, erlang, protocol)
    ops: List of supported operations (can be list or map)
    transports: List of supported transport types
    aux: Auxiliary info map (current_ns, etc.)

  Returns:
    Response message map with binary keys

  Example:
    (describe-response
      #m(versions #m(xrepl \"0.1.0\" lfe \"2.2.0\" erlang \"26\" protocol \"1.0\")
         ops '(eval clone close)
         transports '(tcp unix stdio)
         aux #m(current_ns \"user\")))"
  (let* ((versions (xrepl-ptcl-types:get-field opts 'versions #m()))
         (ops (xrepl-ptcl-types:get-field opts 'ops '()))
         (transports (xrepl-ptcl-types:get-field opts 'transports '()))
         (aux (xrepl-ptcl-types:get-field opts 'aux 'undefined))
         (base (maps:put #"status" #"done"
                        (maps:put #"versions" versions
                                 (maps:put #"ops" ops
                                          (maps:put #"transports" transports
                                                   #m()))))))
    (if (== aux 'undefined)
      base
      (maps:put #"aux" aux base))))

;;; capabilities operation

(defun capabilities-request ()
  "Build a capabilities request.

  Returns:
    Request message map with binary keys"
  #m(#"op" #"capabilities"))

(defun capabilities-response (opts)
  "Build a capabilities response.

  Options:
    ops: List of operation detail maps
    features: Map of feature flags

  Returns:
    Response message map

  Example:
    (capabilities-response
      #m(ops '(#m(#\"name\" #\"eval\"
                  #\"description\" #\"Evaluate code\"
                  #\"required_fields\" '(#\"code\")
                  #\"optional_fields\" '(#\"session\" #\"file\")))
         features #m(#\"hot_reload\" true
                     #\"debugging\" true)))"
  (let ((ops (xrepl-ptcl-types:get-field opts 'ops '()))
        (features (xrepl-ptcl-types:get-field opts 'features #m())))
    (maps:put #"status" #"done"
             (maps:put #"capabilities"
                      (maps:put #"ops" ops
                               (maps:put #"features" features
                                        #m()))
                      #m()))))

;;; version operation

(defun version-request ()
  "Build a version request.

  Returns:
    Request message map with binary keys"
  #m(#"op" #"version"))

(defun version-response (versions)
  "Build a version response.

  Args:
    versions: Map with xrepl, lfe, erlang, protocol versions

  Returns:
    Response message map

  Example:
    (version-response #m(xrepl \"0.1.0\" lfe \"2.2.0\" erlang \"26\" protocol \"1.0\"))"
  (maps:put #"status" #"done"
           (maps:put #"versions" versions
                    #m())))

;;; loaded_modules operation

(defun loaded-modules-request (opts)
  "Build a loaded_modules request.

  Options:
    session: Session ID (required)

  Returns:
    Request message map"
  (case (xrepl-ptcl-types:get-required opts 'session)
    (`#(ok ,session)
     (maps:put #"op" #"loaded_modules"
              (maps:put #"session" (xrepl-ptcl-types:ensure-binary session)
                       #m())))
    (error error)))

(defun loaded-modules-response (modules)
  "Build a loaded_modules response.

  Args:
    modules: List of module maps with name, path, exports

  Returns:
    Response message map

  Example:
    (loaded-modules-response
      '(#m(#\"name\" #\"lists\" #\"path\" #\"/usr/lib/...\" #\"exports\" 42)))"
  (maps:put #"status" #"done"
           (maps:put #"modules" modules
                    #m())))

;;; module_info operation

(defun module-info-request (opts)
  "Build a module_info request.

  Options:
    module: Module name (required)
    session: Session ID (optional)

  Returns:
    Request message map"
  (case (xrepl-ptcl-types:get-required opts 'module)
    (`#(ok ,module)
     (let* ((base (maps:put #"op" #"module_info"
                           (maps:put #"module" (xrepl-ptcl-types:ensure-binary module)
                                    #m())))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun module-info-response (info)
  "Build a module_info response.

  Args:
    info: Module info map with name, path, exports, attributes, etc.

  Returns:
    Response message map

  Example:
    (module-info-response
      #m(#\"name\" #\"lists\"
         #\"path\" #\"/usr/lib/...\"
         #\"exports\" '(#m(#\"name\" #\"map\" #\"arity\" 2))
         #\"md5\" #\"...\"))"
  (maps:put #"status" #"done"
           (maps:put #"module" info
                    #m())))

;;; Parsing and validation

(defun parse-request (message)
  "Parse and validate system operation request message.

  Args:
    message: Message map (with binary keys from MessagePack)

  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-ptcl-types:get-field message 'op)))
      (cond
        ;; ping operation
        ((or (== op #"ping") (== op 'ping))
         (tuple 'ok #m(#"op" #"ping")))

        ;; describe operation
        ((or (== op #"describe") (== op 'describe))
         (tuple 'ok #m(#"op" #"describe")))

        ;; capabilities operation
        ((or (== op #"capabilities") (== op 'capabilities))
         (tuple 'ok #m(#"op" #"capabilities")))

        ;; version operation
        ((or (== op #"version") (== op 'version))
         (tuple 'ok #m(#"op" #"version")))

        ;; loaded_modules operation
        ((or (== op #"loaded_modules") (== op 'loaded_modules))
         (let ((session (xrepl-ptcl-types:get-field message 'session)))
           (if (== session 'undefined)
             (tuple 'error 'missing-session)
             (tuple 'ok (maps:put #"op" #"loaded_modules"
                                 (maps:put #"session" session #m()))))))

        ;; module_info operation
        ((or (== op #"module_info") (== op 'module_info))
         (let ((module (xrepl-ptcl-types:get-field message 'module)))
           (if (== module 'undefined)
             (tuple 'error 'missing-module)
             (tuple 'ok (maps:put #"op" #"module_info"
                                 (maps:put #"module" module
                                          (maps:put #"session"
                                                   (xrepl-ptcl-types:get-field message 'session 'undefined)
                                                   #m())))))))

        ;; Invalid operation
        ('true (tuple 'error 'invalid-system-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))

(defun parse-response (op message)
  "Parse system operation response message.

  Args:
    op: Operation type (ping, describe, etc.)
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
         ;; ping response
         ((== norm-op #"ping")
          (tuple 'ok (maps:put #"pong"
                              (xrepl-ptcl-types:get-field message 'pong)
                              (maps:put #"timestamp"
                                       (xrepl-ptcl-types:get-field message 'timestamp)
                                       #m()))))

         ;; describe response
         ((== norm-op #"describe")
          (tuple 'ok (maps:put #"versions"
                              (xrepl-ptcl-types:get-field message 'versions #m())
                              (maps:put #"ops"
                                       (xrepl-ptcl-types:get-field message 'ops '())
                                       (maps:put #"transports"
                                                (xrepl-ptcl-types:get-field message 'transports '())
                                                #m())))))

         ;; capabilities response
         ((== norm-op #"capabilities")
          (tuple 'ok (maps:put #"capabilities"
                              (xrepl-ptcl-types:get-field message 'capabilities #m())
                              #m())))

         ;; version response
         ((== norm-op #"version")
          (tuple 'ok (maps:put #"versions"
                              (xrepl-ptcl-types:get-field message 'versions #m())
                              #m())))

         ;; loaded_modules response
         ((== norm-op #"loaded_modules")
          (tuple 'ok (maps:put #"modules"
                              (xrepl-ptcl-types:get-field message 'modules '())
                              #m())))

         ;; module_info response
         ((== norm-op #"module_info")
          (tuple 'ok (maps:put #"module"
                              (xrepl-ptcl-types:get-field message 'module #m())
                              #m())))

         ('true (tuple 'error 'unknown-operation))))

      ;; Error status
      ((or (== status #"error") (== status 'error))
       (tuple 'error (xrepl-ptcl-types:get-field message 'error)))

      ;; Invalid status
      ('true (tuple 'error 'invalid-status)))))

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
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (or (== status #"done")
        (== status 'done)
        (== status #"error")
        (== status 'error))))

;;; Errors

(defun error (error-type message)
  "Build error response for system operation.

  Args:
    error-type: Atom identifying error type
    message: Error message (binary, string, or term)

  Returns:
    Error response map"
  (xrepl-ptcl-types:error-response error-type message))
