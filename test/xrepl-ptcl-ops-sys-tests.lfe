(defmodule xrepl-ptcl-ops-sys-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; ping tests

(deftest ping-request-construction
  (let ((req (xrepl-ptcl-ops-sys:ping-request)))
    (is-equal #"ping" (maps:get #"op" req))))

(deftest ping-response-auto-timestamp
  (let ((resp (xrepl-ptcl-ops-sys:ping-response)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 'true (maps:get #"pong" resp))
    (is (is_integer (maps:get #"timestamp" resp)))))

(deftest ping-response-with-timestamp
  (let ((resp (xrepl-ptcl-ops-sys:ping-response 1234567890)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 'true (maps:get #"pong" resp))
    (is-equal 1234567890 (maps:get #"timestamp" resp))))

;;; describe tests

(deftest describe-request-construction
  (let ((req (xrepl-ptcl-ops-sys:describe-request)))
    (is-equal #"describe" (maps:get #"op" req))))

(deftest describe-response-minimal
  (let ((resp (xrepl-ptcl-ops-sys:describe-response #m())))
    (is-equal #"done" (maps:get #"status" resp))
    (is (is_map (maps:get #"versions" resp)))
    (is (is_list (maps:get #"ops" resp)))
    (is (is_list (maps:get #"transports" resp)))))

(deftest describe-response-complete
  (let* ((versions #m(#"xrepl" #"0.1.0" #"lfe" #"2.2.0" #"erlang" #"26"))
         (ops (list #"eval" #"clone" #"close"))
         (transports (list #"tcp" #"unix"))
         (aux #m(#"current_ns" #"user"))
         (opts (maps:put 'versions versions
                        (maps:put 'ops ops
                                 (maps:put 'transports transports
                                          (maps:put 'aux aux #m())))))
         (resp (xrepl-ptcl-ops-sys:describe-response opts)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal versions (maps:get #"versions" resp))
    (is-equal ops (maps:get #"ops" resp))
    (is-equal transports (maps:get #"transports" resp))
    (is-equal aux (maps:get #"aux" resp))))

;;; capabilities tests

(deftest capabilities-request-construction
  (let ((req (xrepl-ptcl-ops-sys:capabilities-request)))
    (is-equal #"capabilities" (maps:get #"op" req))))

(deftest capabilities-response-construction
  (let* ((ops (list #m(#"name" #"eval" #"description" #"Evaluate code")))
         (features #m(#"hot_reload" 'true #"debugging" 'true))
         (opts (maps:put 'ops ops (maps:put 'features features #m())))
         (resp (xrepl-ptcl-ops-sys:capabilities-response opts)))
    (is-equal #"done" (maps:get #"status" resp))
    (let ((caps (maps:get #"capabilities" resp)))
      (is-equal ops (maps:get #"ops" caps))
      (is-equal features (maps:get #"features" caps)))))

;;; version tests

(deftest version-request-construction
  (let ((req (xrepl-ptcl-ops-sys:version-request)))
    (is-equal #"version" (maps:get #"op" req))))

(deftest version-response-construction
  (let* ((versions #m(#"xrepl" #"0.1.0" #"lfe" #"2.2.0" #"erlang" #"26" #"protocol" #"1.0"))
         (resp (xrepl-ptcl-ops-sys:version-response versions)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal versions (maps:get #"versions" resp))))

;;; loaded_modules tests

(deftest loaded-modules-request-construction
  (let ((req (xrepl-ptcl-ops-sys:loaded-modules-request #m(session "abc123"))))
    (is-equal #"loaded_modules" (maps:get #"op" req))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest loaded-modules-response-construction
  (let* ((modules (list #m(#"name" #"lists" #"path" #"/usr/lib/..." #"exports" 42)))
         (resp (xrepl-ptcl-ops-sys:loaded-modules-response modules)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal modules (maps:get #"modules" resp))))

;;; module_info tests

(deftest module-info-request-minimal
  (let ((req (xrepl-ptcl-ops-sys:module-info-request #m(module "lists"))))
    (is-equal #"module_info" (maps:get #"op" req))
    (is-equal #"lists" (maps:get #"module" req))))

(deftest module-info-request-with-session
  (let ((req (xrepl-ptcl-ops-sys:module-info-request #m(module "lists" session "abc123"))))
    (is-equal #"module_info" (maps:get #"op" req))
    (is-equal #"lists" (maps:get #"module" req))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest module-info-response-construction
  (let* ((info #m(#"name" #"lists"
                  #"path" #"/usr/lib/..."
                  #"exports" (list #m(#"name" #"map" #"arity" 2))))
         (resp (xrepl-ptcl-ops-sys:module-info-response info)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal info (maps:get #"module" resp))))

;;; Parsing tests

(deftest parse-ping-request
  (let ((msg #m(#"op" #"ping")))
    (case (xrepl-ptcl-ops-sys:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"ping" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-describe-request
  (let ((msg #m(#"op" #"describe")))
    (case (xrepl-ptcl-ops-sys:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"describe" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-capabilities-request
  (let ((msg #m(#"op" #"capabilities")))
    (case (xrepl-ptcl-ops-sys:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"capabilities" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-version-request
  (let ((msg #m(#"op" #"version")))
    (case (xrepl-ptcl-ops-sys:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"version" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-loaded-modules-request
  (let ((msg #m(#"op" #"loaded_modules" #"session" #"abc123")))
    (case (xrepl-ptcl-ops-sys:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"loaded_modules" (maps:get #"op" parsed))
       (is-equal #"abc123" (maps:get #"session" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-module-info-request
  (let ((msg #m(#"op" #"module_info" #"module" #"lists")))
    (case (xrepl-ptcl-ops-sys:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"module_info" (maps:get #"op" parsed))
       (is-equal #"lists" (maps:get #"module" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-ping-response
  (let ((msg #m(#"status" #"done" #"pong" true #"timestamp" 123)))
    (case (xrepl-ptcl-ops-sys:parse-response #"ping" msg)
      (`#(ok ,result)
       (is-equal 'true (maps:get #"pong" result))
       (is-equal 123 (maps:get #"timestamp" result)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-describe-response
  (let* ((versions #m(#"xrepl" #"0.1.0"))
         (ops (list #"eval" #"clone"))
         (msg (maps:put #"status" #"done"
                       (maps:put #"versions" versions
                                (maps:put #"ops" ops
                                         (maps:put #"transports" (list) #m()))))))
    (case (xrepl-ptcl-ops-sys:parse-response #"describe" msg)
      (`#(ok ,result)
       (is-equal versions (maps:get #"versions" result))
       (is-equal ops (maps:get #"ops" result)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-capabilities-response
  (let* ((caps #m(#"ops" (list) #"features" #m()))
         (msg (maps:put #"status" #"done"
                       (maps:put #"capabilities" caps #m()))))
    (case (xrepl-ptcl-ops-sys:parse-response #"capabilities" msg)
      (`#(ok ,result)
       (is-equal caps (maps:get #"capabilities" result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-request-checks
  (is (xrepl-ptcl-ops-sys:valid-request? #m(#"op" #"ping")))
  (is (xrepl-ptcl-ops-sys:valid-request? #m(#"op" #"describe")))
  (is (xrepl-ptcl-ops-sys:valid-request? #m(#"op" #"capabilities")))
  (is (xrepl-ptcl-ops-sys:valid-request? #m(#"op" #"version")))
  (is (xrepl-ptcl-ops-sys:valid-request? #m(#"op" #"loaded_modules" #"session" #"s1")))
  (is (xrepl-ptcl-ops-sys:valid-request? #m(#"op" #"module_info" #"module" #"lists")))
  (is-not (xrepl-ptcl-ops-sys:valid-request? #m(#"op" #"unknown")))
  (is-not (xrepl-ptcl-ops-sys:valid-request? #m(#"op" #"loaded_modules"))))  ;; missing session

(deftest valid-response-checks
  (is (xrepl-ptcl-ops-sys:valid-response? #"ping" #m(#"status" #"done" #"pong" true #"timestamp" 123)))
  (is (xrepl-ptcl-ops-sys:valid-response? #"describe" #m(#"status" #"done" #"versions" #m())))
  (is (xrepl-ptcl-ops-sys:valid-response? #"capabilities" #m(#"status" #"done")))
  (is (xrepl-ptcl-ops-sys:valid-response? #"version" #m(#"status" #"done")))
  (is-not (xrepl-ptcl-ops-sys:valid-response? #"ping" #m(#"status" #"invalid"))))

;;; Round-trip tests

(deftest ping-round-trip
  (let* ((req (xrepl-ptcl-ops-sys:ping-request))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"ping" (maps:get #"op" decoded))
    (is (xrepl-ptcl-ops-sys:valid-request? decoded))))

(deftest describe-round-trip
  (let* ((versions #m(#"xrepl" #"0.1.0"))
         (ops (list #"eval" #"clone"))
         (transports (list #"tcp"))
         (opts (maps:put 'versions versions
                        (maps:put 'ops ops
                                 (maps:put 'transports transports #m()))))
         (resp (xrepl-ptcl-ops-sys:describe-response opts))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal versions (maps:get #"versions" decoded))
    (is-equal ops (maps:get #"ops" decoded))
    (is-equal transports (maps:get #"transports" decoded))))

(deftest version-round-trip
  (let* ((versions #m(#"xrepl" #"0.1.0" #"protocol" #"1.0"))
         (resp (xrepl-ptcl-ops-sys:version-response versions))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal versions (maps:get #"versions" decoded))))

(deftest module-info-round-trip
  (let* ((req (xrepl-ptcl-ops-sys:module-info-request #m(module "lists" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"module_info" (maps:get #"op" decoded))
    (is-equal #"lists" (maps:get #"module" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-sys:valid-request? decoded))))
