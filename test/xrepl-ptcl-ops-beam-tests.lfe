(defmodule xrepl-ptcl-ops-beam-tests
  "Tests for BEAM operation protocol messages."
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; ==========================================
;;; hot_reload operation tests
;;; ==========================================

(deftest hot-reload-request-minimal
  (let ((req (xrepl-ptcl-ops-beam:hot-reload-request `#m(modules ,(list "mymodule")))))
    (is-equal #"hot_reload" (maps:get #"op" req))
    (is-equal (list #"mymodule") (maps:get #"modules" req))
    ;; Verify alias exists
    (is-equal (list #"mymodule") (maps:get #"module" req))))

(deftest hot-reload-request-with-purge
  (let ((req (xrepl-ptcl-ops-beam:hot-reload-request `#m(modules ,(list "foo" "bar") purge true))))
    (is-equal #"hot_reload" (maps:get #"op" req))
    (is-equal (list #"foo" #"bar") (maps:get #"modules" req))
    (is-equal 'true (maps:get #"purge" req))))

(deftest hot-reload-request-with-session
  (let ((req (xrepl-ptcl-ops-beam:hot-reload-request `#m(modules ,(list "test") session "sess-123"))))
    (is-equal #"hot_reload" (maps:get #"op" req))
    (is-equal #"sess-123" (maps:get #"session" req))))

(deftest hot-reload-request-with-module-alias
  (let ((req (xrepl-ptcl-ops-beam:hot-reload-request `#m(module ,(list "test")))))
    (is-equal #"hot_reload" (maps:get #"op" req))
    (is-equal (list #"test") (maps:get #"modules" req))
    (is-equal (list #"test") (maps:get #"module" req))))

(deftest hot-reload-request-single-module-as-atom
  (let ((req (xrepl-ptcl-ops-beam:hot-reload-request #m(modules mymodule))))
    (is-equal #"hot_reload" (maps:get #"op" req))
    ;; Single atom should be converted to list
    (is-equal (list #"mymodule") (maps:get #"modules" req))))

(deftest hot-reload-request-missing-modules
  (let ((result (xrepl-ptcl-ops-beam:hot-reload-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-modules (element 2 result))))

(deftest hot-reload-response-minimal
  (let ((resp (xrepl-ptcl-ops-beam:hot-reload-response `#m(reloaded ,(list #"mymodule")))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal (list #"mymodule") (maps:get #"reloaded" resp))
    (is-equal 'false (maps:is_key #"failed" resp))))

(deftest hot-reload-response-with-failures
  (let ((resp (xrepl-ptcl-ops-beam:hot-reload-response
                `#m(reloaded ,(list #"foo")
                    failed ,(list `#m(module #"bar" reason #"not_found"))))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal (list #"foo") (maps:get #"reloaded" resp))
    (is-equal (list `#m(module #"bar" reason #"not_found")) (maps:get #"failed" resp))))

(deftest hot-reload-response-custom-status
  (let ((resp (xrepl-ptcl-ops-beam:hot-reload-response `#m(reloaded ,(list #"test") status #"partial"))))
    (is-equal #"partial" (maps:get #"status" resp))))

;;; ==========================================
;;; list_processes operation tests
;;; ==========================================

(deftest list-processes-request-minimal
  (let ((req (xrepl-ptcl-ops-beam:list-processes-request #m())))
    (is-equal #"list_processes" (maps:get #"op" req))))

(deftest list-processes-request-with-filter
  (let ((req (xrepl-ptcl-ops-beam:list-processes-request `#m(filter ,#m(registered_only true)))))
    (is-equal #"list_processes" (maps:get #"op" req))
    (is-equal #m(registered_only true) (maps:get #"filter" req))))

(deftest list-processes-request-with-details
  (let ((req (xrepl-ptcl-ops-beam:list-processes-request #m(details true))))
    (is-equal #"list_processes" (maps:get #"op" req))
    (is-equal 'true (maps:get #"details" req))))

(deftest list-processes-request-with-session
  (let ((req (xrepl-ptcl-ops-beam:list-processes-request #m(session "sess-123"))))
    (is-equal #"list_processes" (maps:get #"op" req))
    (is-equal #"sess-123" (maps:get #"session" req))))

(deftest list-processes-response-minimal
  (let ((resp (xrepl-ptcl-ops-beam:list-processes-response `#m(processes ,(list `#m(pid #"<0.42.0>"))))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal (list `#m(pid #"<0.42.0>")) (maps:get #"processes" resp))
    (is-equal 'false (maps:is_key #"total" resp))))

(deftest list-processes-response-with-total
  (let ((resp (xrepl-ptcl-ops-beam:list-processes-response
                `#m(processes ,(list `#m(pid #"<0.42.0>")) total 100))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 100 (maps:get #"total" resp))))

(deftest list-processes-response-empty-list
  (let ((resp (xrepl-ptcl-ops-beam:list-processes-response `#m(processes ,(list)))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal '() (maps:get #"processes" resp))))

;;; ==========================================
;;; inspect_process operation tests
;;; ==========================================

(deftest inspect-process-request-minimal
  (let ((req (xrepl-ptcl-ops-beam:inspect-process-request #m(pid "<0.42.0>"))))
    (is-equal #"inspect_process" (maps:get #"op" req))
    (is-equal #"<0.42.0>" (maps:get #"pid" req))
    ;; Verify alias exists
    (is-equal #"<0.42.0>" (maps:get #"process" req))))

(deftest inspect-process-request-with-registered-name
  (let ((req (xrepl-ptcl-ops-beam:inspect-process-request #m(pid "my_server"))))
    (is-equal #"inspect_process" (maps:get #"op" req))
    (is-equal #"my_server" (maps:get #"pid" req))))

(deftest inspect-process-request-with-info-keys
  (let ((req (xrepl-ptcl-ops-beam:inspect-process-request
               `#m(pid "shell" info_keys ,(list "status" "message_queue_len")))))
    (is-equal #"inspect_process" (maps:get #"op" req))
    (is-equal (list #"status" #"message_queue_len") (maps:get #"info_keys" req))))

(deftest inspect-process-request-with-process-alias
  (let ((req (xrepl-ptcl-ops-beam:inspect-process-request #m(process "<0.100.0>"))))
    (is-equal #"inspect_process" (maps:get #"op" req))
    (is-equal #"<0.100.0>" (maps:get #"pid" req))
    (is-equal #"<0.100.0>" (maps:get #"process" req))))

(deftest inspect-process-request-with-session
  (let ((req (xrepl-ptcl-ops-beam:inspect-process-request #m(pid "test" session "sess-123"))))
    (is-equal #"inspect_process" (maps:get #"op" req))
    (is-equal #"sess-123" (maps:get #"session" req))))

(deftest inspect-process-request-missing-pid
  (let ((result (xrepl-ptcl-ops-beam:inspect-process-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-pid (element 2 result))))

(deftest inspect-process-response-minimal
  (let ((resp (xrepl-ptcl-ops-beam:inspect-process-response
                `#m(pid #"<0.42.0>" info ,#m(status #"waiting")))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"<0.42.0>" (maps:get #"pid" resp))
    (is-equal #"<0.42.0>" (maps:get #"process" resp))
    (is-equal #m(status #"waiting") (maps:get #"info" resp))))

(deftest inspect-process-response-detailed
  (let ((resp (xrepl-ptcl-ops-beam:inspect-process-response
                `#m(pid #"<0.42.0>"
                    info ,#m(current_function #"gen_server:loop/7"
                             status #"waiting"
                             message_queue_len 0
                             heap_size 610
                             reductions 1234)))))
    (is-equal #"done" (maps:get #"status" resp))
    (let ((info (maps:get #"info" resp)))
      (is-equal #"gen_server:loop/7" (maps:get 'current_function info))
      (is-equal 0 (maps:get 'message_queue_len info))
      (is-equal 610 (maps:get 'heap_size info)))))

;;; ==========================================
;;; trace_calls operation tests
;;; ==========================================

(deftest trace-calls-request-minimal
  (let ((req (xrepl-ptcl-ops-beam:trace-calls-request #m(action "start"))))
    (is-equal #"trace_calls" (maps:get #"op" req))
    (is-equal #"start" (maps:get #"action" req))))

(deftest trace-calls-request-with-module
  (let ((req (xrepl-ptcl-ops-beam:trace-calls-request #m(module "mymodule" action "start"))))
    (is-equal #"trace_calls" (maps:get #"op" req))
    (is-equal #"mymodule" (maps:get #"module" req))
    (is-equal #"mymodule" (maps:get #"mod" req))))

(deftest trace-calls-request-with-function
  (let ((req (xrepl-ptcl-ops-beam:trace-calls-request
               #m(module "mymodule" function "myfun" action "start"))))
    (is-equal #"trace_calls" (maps:get #"op" req))
    (is-equal #"myfun" (maps:get #"function" req))
    (is-equal #"myfun" (maps:get #"fun" req))))

(deftest trace-calls-request-with-arity
  (let ((req (xrepl-ptcl-ops-beam:trace-calls-request
               #m(module "mymodule" function "myfun" arity 2 action "start"))))
    (is-equal #"trace_calls" (maps:get #"op" req))
    (is-equal 2 (maps:get #"arity" req))))

(deftest trace-calls-request-with-pattern
  (let ((req (xrepl-ptcl-ops-beam:trace-calls-request
               `#m(pattern ,#m(mod "_" fun "test_*") action "start"))))
    (is-equal #"trace_calls" (maps:get #"op" req))
    (is-equal #m(mod "_" fun "test_*") (maps:get #"pattern" req))))

(deftest trace-calls-request-with-trace-opts
  (let ((req (xrepl-ptcl-ops-beam:trace-calls-request
               `#m(action "start" trace_opts ,#m(return_trace true timestamp true)))))
    (is-equal #"trace_calls" (maps:get #"op" req))
    (is-equal #m(return_trace true timestamp true) (maps:get #"trace_opts" req))))

(deftest trace-calls-request-stop
  (let ((req (xrepl-ptcl-ops-beam:trace-calls-request #m(action "stop"))))
    (is-equal #"trace_calls" (maps:get #"op" req))
    (is-equal #"stop" (maps:get #"action" req))))

(deftest trace-calls-request-missing-action
  (let ((result (xrepl-ptcl-ops-beam:trace-calls-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-action (element 2 result))))

(deftest trace-calls-response-minimal
  (let ((resp (xrepl-ptcl-ops-beam:trace-calls-response #m(trace_id #"trace-123"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"trace-123" (maps:get #"trace_id" resp))))

(deftest trace-calls-response-with-counts
  (let ((resp (xrepl-ptcl-ops-beam:trace-calls-response
                #m(trace_id #"trace-123" matched 5 traced 2))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"trace-123" (maps:get #"trace_id" resp))
    (is-equal 5 (maps:get #"matched" resp))
    (is-equal 2 (maps:get #"traced" resp))))

(deftest trace-calls-response-stopped
  (let ((resp (xrepl-ptcl-ops-beam:trace-calls-response #m(action #"stopped"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"stopped" (maps:get #"action" resp))))

;;; ==========================================
;;; system_info operation tests
;;; ==========================================

(deftest system-info-request-minimal
  (let ((req (xrepl-ptcl-ops-beam:system-info-request #m())))
    (is-equal #"system_info" (maps:get #"op" req))))

(deftest system-info-request-with-keys
  (let ((req (xrepl-ptcl-ops-beam:system-info-request
               `#m(keys ,(list "schedulers" "process_count" "memory")))))
    (is-equal #"system_info" (maps:get #"op" req))
    (is-equal (list #"schedulers" #"process_count" #"memory") (maps:get #"keys" req))))

(deftest system-info-request-with-session
  (let ((req (xrepl-ptcl-ops-beam:system-info-request #m(session "sess-123"))))
    (is-equal #"system_info" (maps:get #"op" req))
    (is-equal #"sess-123" (maps:get #"session" req))))

(deftest system-info-response-minimal
  (let ((resp (xrepl-ptcl-ops-beam:system-info-response `#m(info ,#m(schedulers 8)))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #m(schedulers 8) (maps:get #"info" resp))))

(deftest system-info-response-detailed
  (let ((resp (xrepl-ptcl-ops-beam:system-info-response
                `#m(info ,#m(schedulers 8
                             process_count 1234
                             otp_release #"26"
                             memory #m(total 123456789 processes 45678))))))
    (is-equal #"done" (maps:get #"status" resp))
    (let ((info (maps:get #"info" resp)))
      (is-equal 8 (maps:get 'schedulers info))
      (is-equal 1234 (maps:get 'process_count info))
      (is-equal #"26" (maps:get 'otp_release info)))))

;;; ==========================================
;;; observer_data operation tests
;;; ==========================================

(deftest observer-data-request-minimal
  (let ((req (xrepl-ptcl-ops-beam:observer-data-request #m(data_type "processes"))))
    (is-equal #"observer_data" (maps:get #"op" req))
    (is-equal #"processes" (maps:get #"data_type" req))
    (is-equal #"processes" (maps:get #"type" req))))

(deftest observer-data-request-with-filter
  (let ((req (xrepl-ptcl-ops-beam:observer-data-request
               `#m(data_type "table" filter ,#m(name #"my_table")))))
    (is-equal #"observer_data" (maps:get #"op" req))
    (is-equal #m(name #"my_table") (maps:get #"filter" req))))

(deftest observer-data-request-with-type-alias
  (let ((req (xrepl-ptcl-ops-beam:observer-data-request #m(type "applications"))))
    (is-equal #"observer_data" (maps:get #"op" req))
    (is-equal #"applications" (maps:get #"data_type" req))
    (is-equal #"applications" (maps:get #"type" req))))

(deftest observer-data-request-with-session
  (let ((req (xrepl-ptcl-ops-beam:observer-data-request #m(data_type "system" session "sess-123"))))
    (is-equal #"observer_data" (maps:get #"op" req))
    (is-equal #"sess-123" (maps:get #"session" req))))

(deftest observer-data-request-missing-data-type
  (let ((result (xrepl-ptcl-ops-beam:observer-data-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-data-type (element 2 result))))

(deftest observer-data-response-minimal
  (let ((resp (xrepl-ptcl-ops-beam:observer-data-response
                `#m(data_type #"processes"
                    data ,(list `#m(pid #"<0.42.0>" memory 1234))))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"processes" (maps:get #"data_type" resp))
    (is-equal #"processes" (maps:get #"type" resp))
    (is-equal (list `#m(pid #"<0.42.0>" memory 1234)) (maps:get #"data" resp))))

(deftest observer-data-response-with-timestamp
  (let ((resp (xrepl-ptcl-ops-beam:observer-data-response
                `#m(data_type #"system"
                    data `#m(cpu 50.5 memory 75.2)
                    timestamp 1234567890))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 1234567890 (maps:get #"timestamp" resp))))

;;; ==========================================
;;; Parsing tests
;;; ==========================================

(deftest parse-hot-reload-request
  (let* ((req `#m(op #"hot_reload" modules ,(list #"foo" #"bar")))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-request req)))
    (is-equal #"hot_reload" (maps:get #"op" parsed))
    (is-equal (list #"foo" #"bar") (maps:get #"modules" parsed))))

(deftest parse-hot-reload-request-with-module-alias
  (let* ((req `#m(op #"hot_reload" module ,(list #"test")))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-request req)))
    (is-equal #"hot_reload" (maps:get #"op" parsed))
    (is-equal (list #"test") (maps:get #"modules" parsed))
    (is-equal (list #"test") (maps:get #"module" parsed))))

(deftest parse-list-processes-request
  (let* ((req `#m(op #"list_processes" details true))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-request req)))
    (is-equal #"list_processes" (maps:get #"op" parsed))
    (is-equal 'true (maps:get #"details" parsed))))

(deftest parse-inspect-process-request
  (let* ((req #m(op #"inspect_process" pid #"<0.42.0>"))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-request req)))
    (is-equal #"inspect_process" (maps:get #"op" parsed))
    (is-equal #"<0.42.0>" (maps:get #"pid" parsed))))

(deftest parse-trace-calls-request
  (let* ((req #m(op #"trace_calls" module #"mymodule" action #"start"))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-request req)))
    (is-equal #"trace_calls" (maps:get #"op" parsed))
    (is-equal #"mymodule" (maps:get #"module" parsed))
    (is-equal #"start" (maps:get #"action" parsed))))

(deftest parse-system-info-request
  (let* ((req `#m(op #"system_info" keys ,(list #"schedulers")))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-request req)))
    (is-equal #"system_info" (maps:get #"op" parsed))
    (is-equal (list #"schedulers") (maps:get #"keys" parsed))))

(deftest parse-observer-data-request
  (let* ((req #m(op #"observer_data" data_type #"processes"))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-request req)))
    (is-equal #"observer_data" (maps:get #"op" parsed))
    (is-equal #"processes" (maps:get #"data_type" parsed))))

(deftest parse-unknown-operation
  (let* ((req #m(op #"unknown_op"))
         (result (xrepl-ptcl-ops-beam:parse-request req)))
    (is-equal 'error (element 1 result))
    (is-equal 'unknown-operation (element 2 result))))

(deftest parse-hot-reload-response
  (let* ((resp `#m(status #"done" reloaded ,(list #"foo")))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-response 'hot_reload resp)))
    (is-equal #"done" (maps:get #"status" parsed))
    (is-equal (list #"foo") (maps:get #"reloaded" parsed))))

(deftest parse-list-processes-response
  (let* ((resp `#m(status #"done" processes ,(list `#m(pid #"<0.1.0>")) total 100))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-response 'list_processes resp)))
    (is-equal #"done" (maps:get #"status" parsed))
    (is-equal 100 (maps:get #"total" parsed))))

(deftest parse-inspect-process-response
  (let* ((resp `#m(status #"done" pid #"<0.42.0>" info ,#m(status #"waiting")))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-response 'inspect_process resp)))
    (is-equal #"done" (maps:get #"status" parsed))
    (is-equal #"<0.42.0>" (maps:get #"pid" parsed))
    (is-equal #m(status #"waiting") (maps:get #"info" parsed))))

(deftest parse-trace-calls-response
  (let* ((resp #m(status #"done" trace_id #"trace-123" matched 5))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-response 'trace_calls resp)))
    (is-equal #"done" (maps:get #"status" parsed))
    (is-equal #"trace-123" (maps:get #"trace_id" parsed))
    (is-equal 5 (maps:get #"matched" parsed))))

(deftest parse-system-info-response
  (let* ((resp `#m(status #"done" info ,#m(schedulers 8)))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-response 'system_info resp)))
    (is-equal #"done" (maps:get #"status" parsed))
    (is-equal #m(schedulers 8) (maps:get #"info" parsed))))

(deftest parse-observer-data-response
  (let* ((resp `#m(status #"done" data_type #"processes" data ,(list `#m(pid #"<0.1.0>"))))
         (`#(ok ,parsed) (xrepl-ptcl-ops-beam:parse-response 'observer_data resp)))
    (is-equal #"done" (maps:get #"status" parsed))
    (is-equal #"processes" (maps:get #"data_type" parsed))
    (is-equal (list `#m(pid #"<0.1.0>")) (maps:get #"data" parsed))))

;;; ==========================================
;;; Validation tests
;;; ==========================================

(deftest valid-hot-reload-request-true
  (let ((req `#m(op #"hot_reload" modules ,(list #"foo"))))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-hot-reload-request-false-missing-modules
  (let ((req #m(op #"hot_reload")))
    (is-equal 'false (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-list-processes-request-true
  (let ((req #m(op #"list_processes")))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-inspect-process-request-true
  (let ((req #m(op #"inspect_process" pid #"<0.42.0>")))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-inspect-process-request-false-missing-pid
  (let ((req #m(op #"inspect_process")))
    (is-equal 'false (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-trace-calls-request-true
  (let ((req #m(op #"trace_calls" action #"start")))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-trace-calls-request-false-missing-action
  (let ((req #m(op #"trace_calls")))
    (is-equal 'false (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-system-info-request-true
  (let ((req #m(op #"system_info")))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-observer-data-request-true
  (let ((req #m(op #"observer_data" data_type #"processes")))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-observer-data-request-false-missing-data-type
  (let ((req #m(op #"observer_data")))
    (is-equal 'false (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-unknown-request-false
  (let ((req #m(op #"unknown_op")))
    (is-equal 'false (xrepl-ptcl-ops-beam:valid-request? req))))

(deftest valid-hot-reload-response-true
  (let ((resp `#m(status #"done" reloaded ,(list #"foo"))))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-response? 'hot_reload resp))))

(deftest valid-list-processes-response-true
  (let ((resp `#m(status #"done" processes ,(list `#m(pid #"<0.1.0>")))))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-response? 'list_processes resp))))

(deftest valid-inspect-process-response-true
  (let ((resp `#m(status #"done" pid #"<0.42.0>" info ,#m(status #"waiting"))))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-response? 'inspect_process resp))))

(deftest valid-trace-calls-response-true
  (let ((resp #m(status #"done")))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-response? 'trace_calls resp))))

(deftest valid-system-info-response-true
  (let ((resp `#m(status #"done" info ,#m(schedulers 8))))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-response? 'system_info resp))))

(deftest valid-observer-data-response-true
  (let ((resp `#m(status #"done" data_type #"processes" data ,(list))))
    (is-equal 'true (xrepl-ptcl-ops-beam:valid-response? 'observer_data resp))))

(deftest valid-response-false-missing-status
  (let ((resp `#m(reloaded ,(list #"foo"))))
    (is-equal 'false (xrepl-ptcl-ops-beam:valid-response? 'hot_reload resp))))

;;; ==========================================
;;; Round-trip MessagePack tests
;;; ==========================================

(deftest hot-reload-request-msgpack-roundtrip
  (let* ((req (xrepl-ptcl-ops-beam:hot-reload-request `#m(modules ,(list "foo" "bar"))))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"hot_reload" (maps:get #"op" decoded))
    (is-equal (list #"foo" #"bar") (maps:get #"modules" decoded))
    (is-equal (list #"foo" #"bar") (maps:get #"module" decoded))))

(deftest list-processes-request-msgpack-roundtrip
  (let* ((req (xrepl-ptcl-ops-beam:list-processes-request #m(details true)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"list_processes" (maps:get #"op" decoded))
    (is-equal 'true (maps:get #"details" decoded))))

(deftest inspect-process-request-msgpack-roundtrip
  (let* ((req (xrepl-ptcl-ops-beam:inspect-process-request #m(pid "<0.42.0>")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"inspect_process" (maps:get #"op" decoded))
    (is-equal #"<0.42.0>" (maps:get #"pid" decoded))
    (is-equal #"<0.42.0>" (maps:get #"process" decoded))))

(deftest trace-calls-request-msgpack-roundtrip
  (let* ((req (xrepl-ptcl-ops-beam:trace-calls-request #m(module "mymodule" action "start")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"trace_calls" (maps:get #"op" decoded))
    (is-equal #"mymodule" (maps:get #"module" decoded))
    (is-equal #"start" (maps:get #"action" decoded))))

(deftest system-info-request-msgpack-roundtrip
  (let* ((req (xrepl-ptcl-ops-beam:system-info-request `#m(keys ,(list "schedulers" "memory"))))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"system_info" (maps:get #"op" decoded))
    (is-equal (list #"schedulers" #"memory") (maps:get #"keys" decoded))))

(deftest observer-data-request-msgpack-roundtrip
  (let* ((req (xrepl-ptcl-ops-beam:observer-data-request #m(data_type "processes")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"observer_data" (maps:get #"op" decoded))
    (is-equal #"processes" (maps:get #"data_type" decoded))
    (is-equal #"processes" (maps:get #"type" decoded))))

(deftest hot-reload-response-msgpack-roundtrip
  (let* ((resp (xrepl-ptcl-ops-beam:hot-reload-response `#m(reloaded ,(list #"foo" #"bar"))))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal (list #"foo" #"bar") (maps:get #"reloaded" decoded))))

(deftest list-processes-response-msgpack-roundtrip
  (let* ((resp (xrepl-ptcl-ops-beam:list-processes-response
                 `#m(processes ,(list `#m(pid #"<0.42.0>" status #"waiting")))))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal 1 (length (maps:get #"processes" decoded)))))

(deftest inspect-process-response-msgpack-roundtrip
  (let* ((resp (xrepl-ptcl-ops-beam:inspect-process-response
                 `#m(pid #"<0.42.0>" info ,#m(status #"waiting" heap_size 610))))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal #"<0.42.0>" (maps:get #"pid" decoded))
    (let ((info (maps:get #"info" decoded)))
      (is-equal #"waiting" (maps:get #"status" info))
      (is-equal 610 (maps:get #"heap_size" info)))))

(deftest trace-calls-response-msgpack-roundtrip
  (let* ((resp (xrepl-ptcl-ops-beam:trace-calls-response
                 #m(trace_id #"trace-123" matched 5 traced 2)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal #"trace-123" (maps:get #"trace_id" decoded))
    (is-equal 5 (maps:get #"matched" decoded))
    (is-equal 2 (maps:get #"traced" decoded))))

(deftest system-info-response-msgpack-roundtrip
  (let* ((resp (xrepl-ptcl-ops-beam:system-info-response
                 `#m(info ,#m(schedulers 8 process_count 1234))))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (let ((info (maps:get #"info" decoded)))
      (is-equal 8 (maps:get #"schedulers" info))
      (is-equal 1234 (maps:get #"process_count" info)))))

(deftest observer-data-response-msgpack-roundtrip
  (let* ((resp (xrepl-ptcl-ops-beam:observer-data-response
                 `#m(data_type #"processes"
                     data ,(list `#m(pid #"<0.42.0>" memory 1234))
                     timestamp 1234567890)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal #"processes" (maps:get #"data_type" decoded))
    (is-equal #"processes" (maps:get #"type" decoded))
    (is-equal 1234567890 (maps:get #"timestamp" decoded))
    (is-equal 1 (length (maps:get #"data" decoded)))))

;;; ==========================================
;;; Error tests
;;; ==========================================

(deftest error-missing-modules
  (let ((err (xrepl-ptcl-ops-beam:error 'missing-modules #m(attempted "hot_reload"))))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: modules" (maps:get #"error" err))))

(deftest error-missing-pid
  (let ((err (xrepl-ptcl-ops-beam:error 'missing-pid "Expected process identifier")))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: pid" (maps:get #"error" err))))

(deftest error-missing-action
  (let ((err (xrepl-ptcl-ops-beam:error 'missing-action #m())))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: action" (maps:get #"error" err))))

(deftest error-missing-data-type
  (let ((err (xrepl-ptcl-ops-beam:error 'missing-data-type #m())))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: data_type" (maps:get #"error" err))))

(deftest error-process-not-found
  (let ((err (xrepl-ptcl-ops-beam:error 'process-not-found #m(pid "<0.999.0>"))))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Process not found" (maps:get #"error" err))))
