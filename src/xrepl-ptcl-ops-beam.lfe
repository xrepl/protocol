(defmodule xrepl-ptcl-ops-beam
  "BEAM-specific operation protocol messages.

  This module defines BEAM VM introspection and management operations."
  (export
   ;; hot_reload operation
   (hot-reload-request 1)
   (hot-reload-response 1)
   ;; list_processes operation
   (list-processes-request 1)
   (list-processes-response 1)
   ;; inspect_process operation
   (inspect-process-request 1)
   (inspect-process-response 1)
   ;; trace_calls operation
   (trace-calls-request 1)
   (trace-calls-response 1)
   ;; system_info operation
   (system-info-request 1)
   (system-info-response 1)
   ;; observer_data operation
   (observer-data-request 1)
   (observer-data-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; hot_reload operation

(defun hot-reload-request (opts)
  "Build a hot_reload request to reload module(s) at runtime.

  Options:
    modules: List of module names to reload (required, list of binaries/atoms)
    purge: Whether to purge old code first (optional, boolean, default false)
    session: Session ID (optional, binary or string)

  Returns:
    Request message map with binary keys, or error tuple

  Examples:
    (hot-reload-request `#m(modules ,(list \"mymodule\")))
    (hot-reload-request `#m(modules ,(list \"foo\" \"bar\") purge true))

  Notes:
    - Supports both 'modules' and 'module' as field names (module will be converted to list)
    - Binary keys used throughout for MessagePack efficiency"
  (case (xrepl-ptcl-types:get-field-any opts '(modules module))
    ('undefined (tuple 'error 'missing-modules))
    (modules-val
     (let* ((modules (if (is_list modules-val)
                        modules-val
                        (list modules-val)))
            (base (maps:put #"op" #"hot_reload"
                           (xrepl-ptcl-types:put-aliased-list
                            #m() 'modules 'module
                            (lists:map #'xrepl-ptcl-types:ensure-binary/1 modules))))
            (with-purge (case (xrepl-ptcl-types:get-field opts 'purge)
                         ('undefined base)
                         (purge (maps:put #"purge" purge base))))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                          with-purge 'session 'session opts 'session)))
       with-session))))

(defun hot-reload-response (opts)
  "Build a hot_reload response.

  Options:
    reloaded: List of successfully reloaded modules (required, list of binaries)
    failed: List of modules that failed to reload (optional, list of maps with module and reason)
    status: Response status (optional, defaults to \"done\")

  Returns:
    Response message map with binary keys

  Example:
    (hot-reload-response `#m(reloaded ,(list #\"mymodule\")))
    (hot-reload-response `#m(reloaded ,(list #\"foo\")
                             failed ,(list `#m(module #\"bar\" reason #\"not_found\"))))"
  (let ((reloaded (xrepl-ptcl-types:get-field opts 'reloaded '()))
        (failed (xrepl-ptcl-types:get-field opts 'failed '()))
        (status (xrepl-ptcl-types:get-field opts 'status #"done")))
    (maps:put #"status" status
             (maps:put #"reloaded" reloaded
                      (if (== failed '())
                        #m()
                        (maps:put #"failed" failed #m()))))))

;;; list_processes operation

(defun list-processes-request (opts)
  "Build a list_processes request to get all BEAM processes.

  Options:
    filter: Filter criteria map (optional)
      - registered_only: Only show registered processes (boolean)
      - application: Filter by application name (binary/atom)
      - module: Filter by current module (binary/atom)
    details: Whether to include detailed info (optional, boolean, default false)
    session: Session ID (optional, binary or string)

  Returns:
    Request message map with binary keys

  Examples:
    (list-processes-request #m())
    (list-processes-request #m(filter `#m(registered_only true)))
    (list-processes-request #m(details true))

  Notes:
    - Binary keys used throughout for MessagePack efficiency"
  (let* ((base (maps:put #"op" #"list_processes" #m()))
         (with-filter (case (xrepl-ptcl-types:get-field opts 'filter)
                       ('undefined base)
                       (filter (maps:put #"filter" filter base))))
         (with-details (case (xrepl-ptcl-types:get-field opts 'details)
                        ('undefined with-filter)
                        (details (maps:put #"details" details with-filter))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                       with-details 'session 'session opts 'session)))
    with-session))

(defun list-processes-response (opts)
  "Build a list_processes response.

  Options:
    processes: List of process info maps (required)
      Each process info map can contain:
      - pid: Process identifier string
      - registered_name: Registered name (if any)
      - current_function: Current function tuple
      - initial_call: Initial call
      - status: Process status (running, waiting, etc.)
      - message_queue_len: Message queue length
      - memory: Process memory in bytes
    total: Total process count (optional, integer)
    status: Response status (optional, defaults to \"done\")

  Returns:
    Response message map with binary keys

  Example:
    (list-processes-response
      `#m(processes ,(list `#m(pid #\"<0.42.0>\"
                               registered_name #\"my_server\"
                               status #\"waiting\"))))"
  (let ((processes (xrepl-ptcl-types:get-field opts 'processes '()))
        (total (xrepl-ptcl-types:get-field opts 'total 'undefined))
        (status (xrepl-ptcl-types:get-field opts 'status #"done")))
    (let ((base (maps:put #"status" status
                         (maps:put #"processes" processes #m()))))
      (if (== total 'undefined)
        base
        (maps:put #"total" total base)))))

;;; inspect_process operation

(defun inspect-process-request (opts)
  "Build an inspect_process request to get detailed process information.

  Options:
    pid: Process identifier (required, binary or atom)
      Can be pid string like \"<0.42.0>\" or registered name
    info_keys: List of specific info keys to retrieve (optional, list)
      Available keys: current_function, initial_call, status, message_queue_len,
                     messages, links, monitors, heap_size, stack_size, etc.
    session: Session ID (optional, binary or string)

  Returns:
    Request message map with binary keys, or error tuple

  Examples:
    (inspect-process-request #m(pid \"<0.42.0>\"))
    (inspect-process-request #m(pid \"my_server\"))
    (inspect-process-request `#m(pid \"shell\" info_keys ,(list \"status\" \"message_queue_len\")))

  Notes:
    - Supports both 'pid' and 'process' as field names
    - Binary keys used throughout for MessagePack efficiency"
  (case (xrepl-ptcl-types:get-field-any opts '(pid process))
    ('undefined (tuple 'error 'missing-pid))
    (pid
     (let* ((base (maps:put #"op" #"inspect_process"
                           (xrepl-ptcl-types:put-aliased
                            #m() 'pid 'process
                            (xrepl-ptcl-types:ensure-binary pid))))
            (with-keys (case (xrepl-ptcl-types:get-field opts 'info_keys)
                        ('undefined base)
                        (keys (maps:put #"info_keys"
                                       (lists:map #'xrepl-ptcl-types:ensure-binary/1 keys)
                                       base))))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                          with-keys 'session 'session opts 'session)))
       with-session))))

(defun inspect-process-response (opts)
  "Build an inspect_process response.

  Options:
    pid: Process identifier string (required, binary)
    info: Process information map (required)
      Can include: current_function, initial_call, status, registered_name,
                  message_queue_len, messages, links, monitors, heap_size,
                  stack_size, reductions, dictionary, error_handler, etc.
    status: Response status (optional, defaults to \"done\")

  Returns:
    Response message map with binary keys

  Example:
    (inspect-process-response
      #m(pid #\"<0.42.0>\"
         info `#m(current_function #\"gen_server:loop/7\"
                  status #\"waiting\"
                  message_queue_len 0
                  heap_size 610
                  reductions 1234)))"
  (let ((pid (xrepl-ptcl-types:get-field opts 'pid #"unknown"))
        (info (xrepl-ptcl-types:get-field opts 'info #m()))
        (status (xrepl-ptcl-types:get-field opts 'status #"done")))
    (maps:put #"status" status
             (xrepl-ptcl-types:put-aliased
              (maps:put #"info" info #m())
              'pid 'process
              pid))))

;;; trace_calls operation

(defun trace-calls-request (opts)
  "Build a trace_calls request to enable function call tracing.

  Options:
    module: Module to trace (required if not pattern, binary/atom)
    function: Function to trace (optional, binary/atom, default all)
    arity: Function arity (optional, integer, default all)
    pattern: Match pattern for calls (optional, alternative to module/function/arity)
    action: Trace action - \"start\" or \"stop\" (required, binary)
    trace_opts: Trace options map (optional)
      - return_trace: Include return values (boolean)
      - timestamp: Include timestamps (boolean)
      - process: Specific process to trace (binary)
    session: Session ID (optional, binary or string)

  Returns:
    Request message map with binary keys, or error tuple

  Examples:
    (trace-calls-request #m(module \"mymodule\" action \"start\"))
    (trace-calls-request #m(module \"mymodule\" function \"myfun\" arity 2 action \"start\"
                           trace_opts `#m(return_trace true timestamp true)))
    (trace-calls-request #m(action \"stop\"))

  Notes:
    - Supports both 'module' and 'mod' as field names
    - Supports both 'function' and 'fun' as field names
    - Binary keys used throughout for MessagePack efficiency"
  (case (xrepl-ptcl-types:get-field opts 'action)
    ('undefined (tuple 'error 'missing-action))
    (action
     (let* ((base (maps:put #"op" #"trace_calls"
                           (maps:put #"action" (xrepl-ptcl-types:ensure-binary action) #m())))
            (with-module (case (xrepl-ptcl-types:get-field-any opts '(module mod))
                          ('undefined base)
                          (mod (xrepl-ptcl-types:put-aliased
                                base 'module 'mod
                                (xrepl-ptcl-types:ensure-binary mod)))))
            (with-function (case (xrepl-ptcl-types:get-field-any opts '(function fun))
                            ('undefined with-module)
                            (fun (xrepl-ptcl-types:put-aliased
                                  with-module 'function 'fun
                                  (xrepl-ptcl-types:ensure-binary fun)))))
            (with-arity (case (xrepl-ptcl-types:get-field opts 'arity)
                         ('undefined with-function)
                         (arity (maps:put #"arity" arity with-function))))
            (with-pattern (case (xrepl-ptcl-types:get-field opts 'pattern)
                           ('undefined with-arity)
                           (pattern (maps:put #"pattern" pattern with-arity))))
            (with-trace-opts (case (xrepl-ptcl-types:get-field opts 'trace_opts)
                              ('undefined with-pattern)
                              (trace-opts (maps:put #"trace_opts" trace-opts with-pattern))))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                          with-trace-opts 'session 'session opts 'session)))
       with-session))))

(defun trace-calls-response (opts)
  "Build a trace_calls response.

  Options:
    trace_id: Trace identifier (optional, binary)
    matched: Number of matching calls (optional, integer)
    traced: Number of traced processes (optional, integer)
    action: Action that was performed (optional, binary)
    status: Response status (optional, defaults to \"done\")

  Returns:
    Response message map with binary keys

  Example:
    (trace-calls-response #m(trace_id #\"trace-123\" matched 5 traced 2))
    (trace-calls-response #m(action #\"stopped\"))"
  (let ((trace-id (xrepl-ptcl-types:get-field opts 'trace_id 'undefined))
        (matched (xrepl-ptcl-types:get-field opts 'matched 'undefined))
        (traced (xrepl-ptcl-types:get-field opts 'traced 'undefined))
        (action (xrepl-ptcl-types:get-field opts 'action 'undefined))
        (status (xrepl-ptcl-types:get-field opts 'status #"done")))
    (let* ((base (maps:put #"status" status #m()))
           (with-trace-id (if (== trace-id 'undefined) base (maps:put #"trace_id" trace-id base)))
           (with-matched (if (== matched 'undefined) with-trace-id (maps:put #"matched" matched with-trace-id)))
           (with-traced (if (== traced 'undefined) with-matched (maps:put #"traced" traced with-matched)))
           (with-action (if (== action 'undefined) with-traced (maps:put #"action" action with-traced))))
      with-action)))

;;; system_info operation

(defun system-info-request (opts)
  "Build a system_info request to get BEAM VM system information.

  Options:
    keys: List of specific info keys to retrieve (optional, list of binaries)
      Available keys: schedulers, process_count, port_count, atom_count,
                     memory, system_version, otp_release, etc.
    session: Session ID (optional, binary or string)

  Returns:
    Request message map with binary keys

  Examples:
    (system-info-request #m())
    (system-info-request `#m(keys ,(list \"schedulers\" \"process_count\" \"memory\")))

  Notes:
    - If no keys specified, returns common system info
    - Binary keys used throughout for MessagePack efficiency"
  (let* ((base (maps:put #"op" #"system_info" #m()))
         (with-keys (case (xrepl-ptcl-types:get-field opts 'keys)
                     ('undefined base)
                     (keys (maps:put #"keys"
                                    (lists:map #'xrepl-ptcl-types:ensure-binary/1 keys)
                                    base))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                       with-keys 'session 'session opts 'session)))
    with-session))

(defun system-info-response (opts)
  "Build a system_info response.

  Options:
    info: System information map (required)
      Can include: schedulers, process_count, port_count, atom_count,
                  memory (map with total/processes/system/etc),
                  system_version, otp_release, erts_version, etc.
    status: Response status (optional, defaults to \"done\")

  Returns:
    Response message map with binary keys

  Example:
    (system-info-response
      `#m(info `#m(schedulers 8
                   process_count 1234
                   otp_release #\"26\"
                   memory `#m(total 123456789 processes 45678 system 6789))))"
  (let ((info (xrepl-ptcl-types:get-field opts 'info #m()))
        (status (xrepl-ptcl-types:get-field opts 'status #"done")))
    (maps:put #"status" status
             (maps:put #"info" info #m()))))

;;; observer_data operation

(defun observer-data-request (opts)
  "Build an observer_data request to get monitoring/observation data.

  Options:
    data_type: Type of data to retrieve (required, binary)
      - \"processes\" - Process table data
      - \"applications\" - Application information
      - \"system\" - System metrics
      - \"table\" - ETS table info
      - \"memory\" - Memory allocation
    filter: Filter criteria for the data (optional, map)
    session: Session ID (optional, binary or string)

  Returns:
    Request message map with binary keys, or error tuple

  Examples:
    (observer-data-request #m(data_type \"processes\"))
    (observer-data-request #m(data_type \"table\" filter `#m(name #\"my_table\")))

  Notes:
    - Supports both 'data_type' and 'type' as field names
    - Binary keys used throughout for MessagePack efficiency"
  (case (xrepl-ptcl-types:get-field-any opts '(data_type type))
    ('undefined (tuple 'error 'missing-data-type))
    (data-type
     (let* ((base (maps:put #"op" #"observer_data"
                           (xrepl-ptcl-types:put-aliased
                            #m() 'data_type 'type
                            (xrepl-ptcl-types:ensure-binary data-type))))
            (with-filter (case (xrepl-ptcl-types:get-field opts 'filter)
                          ('undefined base)
                          (filter (maps:put #"filter" filter base))))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                          with-filter 'session 'session opts 'session)))
       with-session))))

(defun observer-data-response (opts)
  "Build an observer_data response.

  Options:
    data_type: Type of data being returned (required, binary)
    data: The observation data (required, can be list or map depending on type)
    timestamp: When the data was collected (optional, integer)
    status: Response status (optional, defaults to \"done\")

  Returns:
    Response message map with binary keys

  Example:
    (observer-data-response
      `#m(data_type #\"processes\"
          data ,(list `#m(pid #\"<0.42.0>\" memory 1234 reductions 5678))
          timestamp 1234567890))"
  (let ((data-type (xrepl-ptcl-types:get-field opts 'data_type #"unknown"))
        (data (xrepl-ptcl-types:get-field opts 'data '()))
        (timestamp (xrepl-ptcl-types:get-field opts 'timestamp 'undefined))
        (status (xrepl-ptcl-types:get-field opts 'status #"done")))
    (let ((base (maps:put #"status" status
                         (xrepl-ptcl-types:put-aliased
                          (maps:put #"data" data #m())
                          'data_type 'type
                          data-type))))
      (if (== timestamp 'undefined)
        base
        (maps:put #"timestamp" timestamp base)))))

;;; Parsing functions

(defun parse-request (message)
  "Parse a BEAM operations request message.

  Args:
    message: Map with binary or atom keys

  Returns:
    Tuple of (ok, parsed-request-map) or (error, reason)"
  (let ((op (xrepl-ptcl-types:get-field message 'op)))
    (cond
      ;; hot_reload
      ((or (== op #"hot_reload") (== op 'hot_reload))
       (let ((modules (xrepl-ptcl-types:get-field-any message '(modules module)))
             (purge (xrepl-ptcl-types:get-field message 'purge))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (if (== modules 'undefined)
           (tuple 'error 'missing-modules)
           (let* ((modules-list (if (is_list modules) modules (list modules)))
                  (base (maps:put #"op" #"hot_reload"
                                 (xrepl-ptcl-types:put-aliased-list
                                  #m() 'modules 'module
                                  (lists:map #'xrepl-ptcl-types:ensure-binary/1 modules-list))))
                  (with-purge (if (== purge 'undefined) base (maps:put #"purge" purge base)))
                  (with-session (if (== session 'undefined)
                                  with-purge
                                  (maps:put #"session" (xrepl-ptcl-types:ensure-binary session) with-purge))))
             (tuple 'ok with-session)))))

      ;; list_processes
      ((or (== op #"list_processes") (== op 'list_processes))
       (let ((filter (xrepl-ptcl-types:get-field message 'filter))
             (details (xrepl-ptcl-types:get-field message 'details))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (let* ((base (maps:put #"op" #"list_processes" #m()))
                (with-filter (if (== filter 'undefined) base (maps:put #"filter" filter base)))
                (with-details (if (== details 'undefined) with-filter (maps:put #"details" details with-filter)))
                (with-session (if (== session 'undefined)
                                with-details
                                (maps:put #"session" (xrepl-ptcl-types:ensure-binary session) with-details))))
           (tuple 'ok with-session))))

      ;; inspect_process
      ((or (== op #"inspect_process") (== op 'inspect_process))
       (let ((pid (xrepl-ptcl-types:get-field-any message '(pid process)))
             (info-keys (xrepl-ptcl-types:get-field message 'info_keys))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (if (== pid 'undefined)
           (tuple 'error 'missing-pid)
           (let* ((base (maps:put #"op" #"inspect_process"
                                 (xrepl-ptcl-types:put-aliased
                                  #m() 'pid 'process
                                  (xrepl-ptcl-types:ensure-binary pid))))
                  (with-keys (if (== info-keys 'undefined)
                               base
                               (maps:put #"info_keys"
                                        (lists:map #'xrepl-ptcl-types:ensure-binary/1 info-keys)
                                        base)))
                  (with-session (if (== session 'undefined)
                                  with-keys
                                  (maps:put #"session" (xrepl-ptcl-types:ensure-binary session) with-keys))))
             (tuple 'ok with-session)))))

      ;; trace_calls
      ((or (== op #"trace_calls") (== op 'trace_calls))
       (let ((action (xrepl-ptcl-types:get-field message 'action))
             (module (xrepl-ptcl-types:get-field-any message '(module mod)))
             (function (xrepl-ptcl-types:get-field-any message '(function fun)))
             (arity (xrepl-ptcl-types:get-field message 'arity))
             (pattern (xrepl-ptcl-types:get-field message 'pattern))
             (trace-opts (xrepl-ptcl-types:get-field message 'trace_opts))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (if (== action 'undefined)
           (tuple 'error 'missing-action)
           (let* ((base (maps:put #"op" #"trace_calls"
                                 (maps:put #"action" (xrepl-ptcl-types:ensure-binary action) #m())))
                  (with-module (if (== module 'undefined)
                                 base
                                 (xrepl-ptcl-types:put-aliased
                                  base 'module 'mod
                                  (xrepl-ptcl-types:ensure-binary module))))
                  (with-function (if (== function 'undefined)
                                   with-module
                                   (xrepl-ptcl-types:put-aliased
                                    with-module 'function 'fun
                                    (xrepl-ptcl-types:ensure-binary function))))
                  (with-arity (if (== arity 'undefined) with-function (maps:put #"arity" arity with-function)))
                  (with-pattern (if (== pattern 'undefined) with-arity (maps:put #"pattern" pattern with-arity)))
                  (with-trace-opts (if (== trace-opts 'undefined) with-pattern (maps:put #"trace_opts" trace-opts with-pattern)))
                  (with-session (if (== session 'undefined)
                                  with-trace-opts
                                  (maps:put #"session" (xrepl-ptcl-types:ensure-binary session) with-trace-opts))))
             (tuple 'ok with-session)))))

      ;; system_info
      ((or (== op #"system_info") (== op 'system_info))
       (let ((keys (xrepl-ptcl-types:get-field message 'keys))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (let* ((base (maps:put #"op" #"system_info" #m()))
                (with-keys (if (== keys 'undefined)
                             base
                             (maps:put #"keys" (lists:map #'xrepl-ptcl-types:ensure-binary/1 keys) base)))
                (with-session (if (== session 'undefined)
                                with-keys
                                (maps:put #"session" (xrepl-ptcl-types:ensure-binary session) with-keys))))
           (tuple 'ok with-session))))

      ;; observer_data
      ((or (== op #"observer_data") (== op 'observer_data))
       (let ((data-type (xrepl-ptcl-types:get-field-any message '(data_type type)))
             (filter (xrepl-ptcl-types:get-field message 'filter))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (if (== data-type 'undefined)
           (tuple 'error 'missing-data-type)
           (let* ((base (maps:put #"op" #"observer_data"
                                 (xrepl-ptcl-types:put-aliased
                                  #m() 'data_type 'type
                                  (xrepl-ptcl-types:ensure-binary data-type))))
                  (with-filter (if (== filter 'undefined) base (maps:put #"filter" filter base)))
                  (with-session (if (== session 'undefined)
                                  with-filter
                                  (maps:put #"session" (xrepl-ptcl-types:ensure-binary session) with-filter))))
             (tuple 'ok with-session)))))

      ('true (tuple 'error 'unknown-operation)))))

(defun parse-response (op message)
  "Parse a BEAM operations response message.

  Args:
    op: Operation name (binary or atom)
    message: Map with binary or atom keys

  Returns:
    Tuple of (ok, parsed-response-map) or (error, reason)"
  (cond
    ;; hot_reload
    ((or (== op #"hot_reload") (== op 'hot_reload))
     (let ((status (xrepl-ptcl-types:get-field message 'status #"done"))
           (reloaded (xrepl-ptcl-types:get-field message 'reloaded '()))
           (failed (xrepl-ptcl-types:get-field message 'failed '())))
       (tuple 'ok (maps:put #"status" status
                           (maps:put #"reloaded" reloaded
                                    (if (== failed '())
                                      #m()
                                      (maps:put #"failed" failed #m())))))))

    ;; list_processes
    ((or (== op #"list_processes") (== op 'list_processes))
     (let ((status (xrepl-ptcl-types:get-field message 'status #"done"))
           (processes (xrepl-ptcl-types:get-field message 'processes '()))
           (total (xrepl-ptcl-types:get-field message 'total)))
       (let ((base (maps:put #"status" status
                            (maps:put #"processes" processes #m()))))
         (tuple 'ok (if (== total 'undefined) base (maps:put #"total" total base))))))

    ;; inspect_process
    ((or (== op #"inspect_process") (== op 'inspect_process))
     (let ((status (xrepl-ptcl-types:get-field message 'status #"done"))
           (pid (xrepl-ptcl-types:get-field-any message '(pid process) #"unknown"))
           (info (xrepl-ptcl-types:get-field message 'info #m())))
       (tuple 'ok (maps:put #"status" status
                           (xrepl-ptcl-types:put-aliased
                            (maps:put #"info" info #m())
                            'pid 'process
                            pid)))))

    ;; trace_calls
    ((or (== op #"trace_calls") (== op 'trace_calls))
     (let ((status (xrepl-ptcl-types:get-field message 'status #"done"))
           (trace-id (xrepl-ptcl-types:get-field message 'trace_id))
           (matched (xrepl-ptcl-types:get-field message 'matched))
           (traced (xrepl-ptcl-types:get-field message 'traced))
           (action (xrepl-ptcl-types:get-field message 'action)))
       (let* ((base (maps:put #"status" status #m()))
              (with-trace-id (if (== trace-id 'undefined) base (maps:put #"trace_id" trace-id base)))
              (with-matched (if (== matched 'undefined) with-trace-id (maps:put #"matched" matched with-trace-id)))
              (with-traced (if (== traced 'undefined) with-matched (maps:put #"traced" traced with-matched)))
              (with-action (if (== action 'undefined) with-traced (maps:put #"action" action with-traced))))
         (tuple 'ok with-action))))

    ;; system_info
    ((or (== op #"system_info") (== op 'system_info))
     (let ((status (xrepl-ptcl-types:get-field message 'status #"done"))
           (info (xrepl-ptcl-types:get-field message 'info #m())))
       (tuple 'ok (maps:put #"status" status
                           (maps:put #"info" info #m())))))

    ;; observer_data
    ((or (== op #"observer_data") (== op 'observer_data))
     (let ((status (xrepl-ptcl-types:get-field message 'status #"done"))
           (data-type (xrepl-ptcl-types:get-field-any message '(data_type type) #"unknown"))
           (data (xrepl-ptcl-types:get-field message 'data '()))
           (timestamp (xrepl-ptcl-types:get-field message 'timestamp)))
       (let ((base (maps:put #"status" status
                            (xrepl-ptcl-types:put-aliased
                             (maps:put #"data" data #m())
                             'data_type 'type
                             data-type))))
         (tuple 'ok (if (== timestamp 'undefined) base (maps:put #"timestamp" timestamp base))))))

    ('true (tuple 'error 'unknown-operation))))

;;; Validation functions

(defun valid-request? (message)
  "Validate a BEAM operations request message.

  Args:
    message: Map with binary or atom keys

  Returns:
    true if valid, false otherwise"
  (let ((op (xrepl-ptcl-types:get-field message 'op)))
    (cond
      ((or (== op #"hot_reload") (== op 'hot_reload))
       (let ((modules (xrepl-ptcl-types:get-field-any message '(modules module))))
         (andalso (/= modules 'undefined)
                  (or (is_list modules)
                      (is_binary modules)
                      (is_atom modules)))))

      ((or (== op #"list_processes") (== op 'list_processes))
       'true)  ; No required fields

      ((or (== op #"inspect_process") (== op 'inspect_process))
       (let ((pid (xrepl-ptcl-types:get-field-any message '(pid process))))
         (andalso (/= pid 'undefined)
                  (or (is_binary pid) (is_atom pid)))))

      ((or (== op #"trace_calls") (== op 'trace_calls))
       (let ((action (xrepl-ptcl-types:get-field message 'action)))
         (andalso (/= action 'undefined)
                  (or (is_binary action) (is_atom action)))))

      ((or (== op #"system_info") (== op 'system_info))
       'true)  ; No required fields

      ((or (== op #"observer_data") (== op 'observer_data))
       (let ((data-type (xrepl-ptcl-types:get-field-any message '(data_type type))))
         (andalso (/= data-type 'undefined)
                  (or (is_binary data-type) (is_atom data-type)))))

      ('true 'false))))

(defun valid-response? (op message)
  "Validate a BEAM operations response message.

  Args:
    op: Operation name (binary or atom)
    message: Map with binary or atom keys

  Returns:
    true if valid, false otherwise"
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (cond
      ((or (== op #"hot_reload") (== op 'hot_reload))
       (let ((reloaded (xrepl-ptcl-types:get-field message 'reloaded)))
         (andalso (/= status 'undefined)
                  (or (is_list reloaded) (== reloaded 'undefined)))))

      ((or (== op #"list_processes") (== op 'list_processes))
       (let ((processes (xrepl-ptcl-types:get-field message 'processes)))
         (andalso (/= status 'undefined)
                  (or (is_list processes) (== processes 'undefined)))))

      ((or (== op #"inspect_process") (== op 'inspect_process))
       (let ((info (xrepl-ptcl-types:get-field message 'info)))
         (andalso (/= status 'undefined)
                  (or (is_map info) (== info 'undefined)))))

      ((or (== op #"trace_calls") (== op 'trace_calls))
       (/= status 'undefined))

      ((or (== op #"system_info") (== op 'system_info))
       (let ((info (xrepl-ptcl-types:get-field message 'info)))
         (andalso (/= status 'undefined)
                  (or (is_map info) (== info 'undefined)))))

      ((or (== op #"observer_data") (== op 'observer_data))
       (let ((data (xrepl-ptcl-types:get-field message 'data))
             (data-type (xrepl-ptcl-types:get-field-any message '(data_type type))))
         (andalso (/= status 'undefined)
                  (/= data-type 'undefined))))

      ('true 'false))))

;;; Error handling

(defun error (type details)
  "Build an error response for BEAM operations.

  Args:
    type: Error type atom
    details: Error details (map, string, or any term)

  Returns:
    Error response map with binary keys"
  (let ((error-msg (case type
                    ('missing-modules #"Missing required field: modules")
                    ('missing-pid #"Missing required field: pid")
                    ('missing-action #"Missing required field: action")
                    ('missing-data-type #"Missing required field: data_type")
                    ('reload-failed #"Hot reload failed")
                    ('process-not-found #"Process not found")
                    ('trace-error #"Trace operation failed")
                    ('unknown-error #"Unknown error")
                    (_ #"BEAM operation error"))))
    (maps:put #"status" #"error"
             (maps:put #"error" error-msg
                      (if (is_map details)
                        details
                        (maps:put #"details" details #m()))))))
