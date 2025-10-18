(defmodule xrepl-ptcl-ops-debug-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; set_breakpoint tests

(deftest set-breakpoint-request-minimal
  (let ((req (xrepl-ptcl-ops-debug:set-breakpoint-request #m(file "src/foo.lfe" line 42))))
    (is-equal #"set_breakpoint" (maps:get #"op" req))
    (is-equal #"src/foo.lfe" (maps:get #"file" req))
    (is-equal 42 (maps:get #"line" req))))

(deftest set-breakpoint-request-with-condition
  (let ((req (xrepl-ptcl-ops-debug:set-breakpoint-request
              #m(file "test.lfe" line 10 condition "x > 5"))))
    (is-equal #"set_breakpoint" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal #"x > 5" (maps:get #"condition" req))))

(deftest set-breakpoint-request-with-session
  (let ((req (xrepl-ptcl-ops-debug:set-breakpoint-request
              #m(file "src/foo.lfe" line 42 session "s1"))))
    (is-equal #"set_breakpoint" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest set-breakpoint-response-construction
  (let* ((bp (maps:put #"id" #"bp-1"
                      (maps:put #"file" #"src/foo.lfe"
                               (maps:put #"line" 42
                                        (maps:put #"enabled" 'true #m())))))
         (resp (xrepl-ptcl-ops-debug:set-breakpoint-response bp)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal bp (maps:get #"breakpoint" resp))))

;;; clear_breakpoint tests

(deftest clear-breakpoint-request-minimal
  (let ((req (xrepl-ptcl-ops-debug:clear-breakpoint-request #m(id "bp-1"))))
    (is-equal #"clear_breakpoint" (maps:get #"op" req))
    (is-equal #"bp-1" (maps:get #"id" req))))

(deftest clear-breakpoint-request-with-session
  (let ((req (xrepl-ptcl-ops-debug:clear-breakpoint-request #m(id "bp-2" session "s1"))))
    (is-equal #"clear_breakpoint" (maps:get #"op" req))
    (is-equal #"bp-2" (maps:get #"id" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest clear-breakpoint-response-construction
  (let* ((result (maps:put #"id" #"bp-1" (maps:put #"cleared" 'true #m())))
         (resp (xrepl-ptcl-ops-debug:clear-breakpoint-response result)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal result (maps:get #"result" resp))))

;;; list_breakpoints tests

(deftest list-breakpoints-request-minimal
  (let ((req (xrepl-ptcl-ops-debug:list-breakpoints-request #m())))
    (is-equal #"list_breakpoints" (maps:get #"op" req))))

(deftest list-breakpoints-request-with-session
  (let ((req (xrepl-ptcl-ops-debug:list-breakpoints-request #m(session "s1"))))
    (is-equal #"list_breakpoints" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest list-breakpoints-response-construction
  (let* ((breakpoints (list #m(#"id" #"bp-1"
                               #"file" #"src/foo.lfe"
                               #"line" 42
                               #"enabled" 'true)))
         (resp (xrepl-ptcl-ops-debug:list-breakpoints-response breakpoints)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal breakpoints (maps:get #"breakpoints" resp))))

;;; stacktrace tests

(deftest stacktrace-request-minimal
  (let ((req (xrepl-ptcl-ops-debug:stacktrace-request #m())))
    (is-equal #"stacktrace" (maps:get #"op" req))))

(deftest stacktrace-request-with-session
  (let ((req (xrepl-ptcl-ops-debug:stacktrace-request #m(session "s1"))))
    (is-equal #"stacktrace" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest stacktrace-response-construction
  (let* ((frames (list #m(#"function" #"foo/2"
                          #"file" #"src/foo.lfe"
                          #"line" 42)))
         (resp (xrepl-ptcl-ops-debug:stacktrace-response frames)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal frames (maps:get #"frames" resp))))

;;; inspect_locals tests

(deftest inspect-locals-request-minimal
  (let ((req (xrepl-ptcl-ops-debug:inspect-locals-request #m())))
    (is-equal #"inspect_locals" (maps:get #"op" req))))

(deftest inspect-locals-request-with-frame
  (let ((req (xrepl-ptcl-ops-debug:inspect-locals-request #m(frame 2))))
    (is-equal #"inspect_locals" (maps:get #"op" req))
    (is-equal 2 (maps:get #"frame" req))))

(deftest inspect-locals-request-with-session
  (let ((req (xrepl-ptcl-ops-debug:inspect-locals-request #m(frame 2 session "s1"))))
    (is-equal #"inspect_locals" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest inspect-locals-response-construction
  (let* ((locals #m(#"x" 42 #"y" #"hello"))
         (resp (xrepl-ptcl-ops-debug:inspect-locals-response locals)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal locals (maps:get #"locals" resp))))

;;; eval_in_frame tests

(deftest eval-in-frame-request-minimal
  (let ((req (xrepl-ptcl-ops-debug:eval-in-frame-request #m(code "x + y"))))
    (is-equal #"eval_in_frame" (maps:get #"op" req))
    (is-equal #"x + y" (maps:get #"code" req))))

(deftest eval-in-frame-request-with-frame
  (let ((req (xrepl-ptcl-ops-debug:eval-in-frame-request #m(code "foo(x)" frame 2))))
    (is-equal #"eval_in_frame" (maps:get #"op" req))
    (is-equal #"foo(x)" (maps:get #"code" req))
    (is-equal 2 (maps:get #"frame" req))))

(deftest eval-in-frame-request-with-session
  (let ((req (xrepl-ptcl-ops-debug:eval-in-frame-request
              #m(code "bar()" frame 2 session "s1"))))
    (is-equal #"eval_in_frame" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest eval-in-frame-response-construction
  (let ((resp (xrepl-ptcl-ops-debug:eval-in-frame-response "47")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"47" (maps:get #"value" resp))))

;;; step tests

(deftest step-request-minimal
  (let ((req (xrepl-ptcl-ops-debug:step-request #m())))
    (is-equal #"step" (maps:get #"op" req))))

(deftest step-request-with-type
  (let ((req (xrepl-ptcl-ops-debug:step-request #m(type "into"))))
    (is-equal #"step" (maps:get #"op" req))
    (is-equal #"into" (maps:get #"type" req))))

(deftest step-request-with-session
  (let ((req (xrepl-ptcl-ops-debug:step-request #m(type "over" session "s1"))))
    (is-equal #"step" (maps:get #"op" req))
    (is-equal #"over" (maps:get #"type" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest step-response-construction
  (let* ((result #m(#"file" #"src/foo.lfe" #"line" 43))
         (resp (xrepl-ptcl-ops-debug:step-response result)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal result (maps:get #"result" resp))))

;;; Parsing tests

(deftest parse-set-breakpoint-request
  (let ((msg #m(#"op" #"set_breakpoint" #"file" #"src/foo.lfe" #"line" 42)))
    (case (xrepl-ptcl-ops-debug:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"set_breakpoint" (maps:get #"op" parsed))
       (is-equal #"src/foo.lfe" (maps:get #"file" parsed))
       (is-equal 42 (maps:get #"line" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-set-breakpoint-request-missing-file
  (let ((msg #m(#"op" #"set_breakpoint" #"line" 42)))
    (case (xrepl-ptcl-ops-debug:parse-request msg)
      (`#(error missing-required-field)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-clear-breakpoint-request
  (let ((msg #m(#"op" #"clear_breakpoint" #"id" #"bp-1")))
    (case (xrepl-ptcl-ops-debug:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"clear_breakpoint" (maps:get #"op" parsed))
       (is-equal #"bp-1" (maps:get #"id" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-clear-breakpoint-request-missing-id
  (let ((msg #m(#"op" #"clear_breakpoint")))
    (case (xrepl-ptcl-ops-debug:parse-request msg)
      (`#(error missing-id)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-list-breakpoints-request
  (let ((msg #m(#"op" #"list_breakpoints")))
    (case (xrepl-ptcl-ops-debug:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"list_breakpoints" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-stacktrace-request
  (let ((msg #m(#"op" #"stacktrace")))
    (case (xrepl-ptcl-ops-debug:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"stacktrace" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-inspect-locals-request
  (let ((msg #m(#"op" #"inspect_locals")))
    (case (xrepl-ptcl-ops-debug:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"inspect_locals" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-eval-in-frame-request
  (let ((msg #m(#"op" #"eval_in_frame" #"code" #"x + y")))
    (case (xrepl-ptcl-ops-debug:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"eval_in_frame" (maps:get #"op" parsed))
       (is-equal #"x + y" (maps:get #"code" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-eval-in-frame-request-missing-code
  (let ((msg #m(#"op" #"eval_in_frame")))
    (case (xrepl-ptcl-ops-debug:parse-request msg)
      (`#(error missing-code)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-step-request
  (let ((msg #m(#"op" #"step")))
    (case (xrepl-ptcl-ops-debug:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"step" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-set-breakpoint-response
  (let* ((bp #m(#"id" #"bp-1" #"file" #"src/foo.lfe" #"line" 42))
         (msg (maps:put #"status" #"done"
                       (maps:put #"breakpoint" bp #m()))))
    (case (xrepl-ptcl-ops-debug:parse-response #"set_breakpoint" msg)
      (`#(ok ,result)
       (is-equal bp (maps:get #"breakpoint" result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-request-checks
  (is (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"set_breakpoint" #"file" #"foo.lfe" #"line" 42)))
  (is (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"clear_breakpoint" #"id" #"bp-1")))
  (is (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"list_breakpoints")))
  (is (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"stacktrace")))
  (is (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"inspect_locals")))
  (is (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"eval_in_frame" #"code" #"x")))
  (is (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"step")))
  (is-not (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"unknown")))
  (is-not (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"set_breakpoint" #"line" 42)))  ;; missing file
  (is-not (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"clear_breakpoint")))  ;; missing id
  (is-not (xrepl-ptcl-ops-debug:valid-request? #m(#"op" #"eval_in_frame"))))  ;; missing code

(deftest valid-response-checks
  (is (xrepl-ptcl-ops-debug:valid-response? #"set_breakpoint" #m(#"status" #"done")))
  (is (xrepl-ptcl-ops-debug:valid-response? #"stacktrace" #m(#"status" #"done")))
  (is (xrepl-ptcl-ops-debug:valid-response? #"step" #m(#"status" #"error")))
  (is-not (xrepl-ptcl-ops-debug:valid-response? #"set_breakpoint" #m(#"status" #"invalid"))))

;;; Round-trip tests

(deftest set-breakpoint-round-trip
  (let* ((req (xrepl-ptcl-ops-debug:set-breakpoint-request
              #m(file "src/foo.lfe" line 42 condition "x > 5" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"set_breakpoint" (maps:get #"op" decoded))
    (is-equal #"src/foo.lfe" (maps:get #"file" decoded))
    (is-equal 42 (maps:get #"line" decoded))
    (is-equal #"x > 5" (maps:get #"condition" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-debug:valid-request? decoded))))

(deftest set-breakpoint-response-round-trip
  (let* ((bp (maps:put #"id" #"bp-1"
                      (maps:put #"file" #"src/foo.lfe"
                               (maps:put #"line" 42 #m()))))
         (resp (xrepl-ptcl-ops-debug:set-breakpoint-response bp))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal bp (maps:get #"breakpoint" decoded))))

(deftest clear-breakpoint-round-trip
  (let* ((req (xrepl-ptcl-ops-debug:clear-breakpoint-request #m(id "bp-1" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"clear_breakpoint" (maps:get #"op" decoded))
    (is-equal #"bp-1" (maps:get #"id" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-debug:valid-request? decoded))))

(deftest clear-breakpoint-response-round-trip
  (let* ((result (maps:put #"id" #"bp-1" (maps:put #"cleared" 'true #m())))
         (resp (xrepl-ptcl-ops-debug:clear-breakpoint-response result))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal #"bp-1" (maps:get #"id" (maps:get #"result" decoded)))
    (is-equal 'true (maps:get #"cleared" (maps:get #"result" decoded)))))

(deftest list-breakpoints-round-trip
  (let* ((req (xrepl-ptcl-ops-debug:list-breakpoints-request #m(session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"list_breakpoints" (maps:get #"op" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-debug:valid-request? decoded))))

(deftest list-breakpoints-response-round-trip
  (let* ((breakpoints (list #m(#"id" #"bp-1" #"file" #"src/foo.lfe" #"line" 42)))
         (resp (xrepl-ptcl-ops-debug:list-breakpoints-response breakpoints))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal breakpoints (maps:get #"breakpoints" decoded))))

(deftest stacktrace-round-trip
  (let* ((req (xrepl-ptcl-ops-debug:stacktrace-request #m(session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"stacktrace" (maps:get #"op" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-debug:valid-request? decoded))))

(deftest stacktrace-response-round-trip
  (let* ((frames (list #m(#"function" #"foo/2" #"file" #"src/foo.lfe" #"line" 42)))
         (resp (xrepl-ptcl-ops-debug:stacktrace-response frames))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal frames (maps:get #"frames" decoded))))

(deftest inspect-locals-round-trip
  (let* ((req (xrepl-ptcl-ops-debug:inspect-locals-request #m(frame 2 session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"inspect_locals" (maps:get #"op" decoded))
    (is-equal 2 (maps:get #"frame" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-debug:valid-request? decoded))))

(deftest inspect-locals-response-round-trip
  (let* ((locals #m(#"x" 42 #"y" #"hello"))
         (resp (xrepl-ptcl-ops-debug:inspect-locals-response locals))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal locals (maps:get #"locals" decoded))))

(deftest eval-in-frame-round-trip
  (let* ((req (xrepl-ptcl-ops-debug:eval-in-frame-request
              #m(code "x + y" frame 2 session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"eval_in_frame" (maps:get #"op" decoded))
    (is-equal #"x + y" (maps:get #"code" decoded))
    (is-equal 2 (maps:get #"frame" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-debug:valid-request? decoded))))

(deftest eval-in-frame-response-round-trip
  (let* ((resp (xrepl-ptcl-ops-debug:eval-in-frame-response "47"))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal #"47" (maps:get #"value" decoded))))

(deftest step-round-trip
  (let* ((req (xrepl-ptcl-ops-debug:step-request #m(type "into" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"step" (maps:get #"op" decoded))
    (is-equal #"into" (maps:get #"type" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-debug:valid-request? decoded))))

(deftest step-response-round-trip
  (let* ((result #m(#"file" #"src/foo.lfe" #"line" 43))
         (resp (xrepl-ptcl-ops-debug:step-response result))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal result (maps:get #"result" decoded))))
