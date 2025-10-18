(defmodule xrepl-protocol-eval-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

(deftest request-construction-minimal
  (let ((req (xrepl-protocol-eval:request #m(code "(+ 1 2)"))))
    (is-equal 'eval (maps:get 'op req))
    (is (is_binary (maps:get 'code req)))
    (is-equal #"(+ 1 2)" (maps:get 'code req))))

(deftest request-construction-with-session
  (let ((req (xrepl-protocol-eval:request #m(code "(+ 1 2)" session "abc123"))))
    (is-equal 'eval (maps:get 'op req))
    (is-equal #"(+ 1 2)" (maps:get 'code req))
    (is-equal #"abc123" (maps:get 'session req))))

(deftest request-missing-code
  (is-match `#(error #(missing-required-field code))
            (xrepl-protocol-eval:request #m())))

(deftest response-construction-simple
  (let ((resp (xrepl-protocol-eval:response "42")))
    (is-equal 'done (maps:get 'status resp))
    (is-equal #"42" (maps:get 'value resp))))

(deftest response-construction-with-session
  (let ((resp (xrepl-protocol-eval:response "42" #m(session "abc123"))))
    (is-equal 'done (maps:get 'status resp))
    (is-equal #"42" (maps:get 'value resp))
    (is-equal #"abc123" (maps:get 'session resp))))

(deftest action-response-switch
  (let ((resp (xrepl-protocol-eval:action-response 'switch #m(session "new-id"))))
    (is-equal 'done (maps:get 'status resp))
    (is-equal 'switch (maps:get 'action resp))
    (is-equal #"new-id" (maps:get 'session resp))))

(deftest action-response-switch-to-other
  (let ((resp (xrepl-protocol-eval:action-response 'switch-to-other #m())))
    (is-equal 'done (maps:get 'status resp))
    (is-equal 'switch-to-other (maps:get 'action resp))))

(deftest error-response-construction
  (let ((err (xrepl-protocol-eval:error 'eval-error "Something broke")))
    (is-equal 'error (maps:get 'status err))
    (is-equal 'eval-error (maps:get 'type (maps:get 'error err)))
    (is (is_binary (maps:get 'message (maps:get 'error err))))))

(deftest parse-request-valid
  (let ((msg #m(op eval code "(+ 1 2)")))
    (case (xrepl-protocol-eval:parse-request msg)
      (`#(ok ,parsed)
       (is-equal "(+ 1 2)" (maps:get 'code parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-request-with-session
  (let ((msg #m(op eval code "(+ 1 2)" session "abc123")))
    (case (xrepl-protocol-eval:parse-request msg)
      (`#(ok ,parsed)
       (is-equal "(+ 1 2)" (maps:get 'code parsed))
       (is-equal "abc123" (maps:get 'session parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-request-binary-keys
  (let ((msg (map #"op" #"eval" #"code" #"(+ 1 2)")))
    (case (xrepl-protocol-eval:parse-request msg)
      (`#(ok ,parsed)
       (is (is_binary (maps:get 'code parsed))))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-request-invalid-op
  (let ((msg #m(op invalid code "(+ 1 2)")))
    (is-equal '#(error invalid-eval-request)
              (xrepl-protocol-eval:parse-request msg))))

(deftest parse-response-value
  (let ((msg #m(status done value "42")))
    (case (xrepl-protocol-eval:parse-response msg)
      (`#(ok ,result)
       (is-equal "42" (maps:get 'value result)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-response-with-session
  (let ((msg #m(status done value "42" session "abc123")))
    (case (xrepl-protocol-eval:parse-response msg)
      (`#(ok ,result)
       (is-equal "42" (maps:get 'value result))
       (is-equal "abc123" (maps:get 'session result)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-response-action
  (let ((msg #m(status done action switch session "new-id")))
    (case (xrepl-protocol-eval:parse-response msg)
      (`#(ok ,result)
       (is-equal 'switch (maps:get 'action result))
       (is-equal "new-id" (maps:get 'session result)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-response-error
  (let ((msg #m(status error error #m(type eval-error message "err"))))
    (case (xrepl-protocol-eval:parse-response msg)
      (`#(error ,err-info)
       (is-equal 'eval-error (maps:get 'type err-info)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest valid-request-check
  (is (xrepl-protocol-eval:valid-request? #m(op eval code "(+ 1 2)")))
  (is-not (xrepl-protocol-eval:valid-request? #m(op invalid code "(+ 1 2)"))))

(deftest valid-response-check
  (is (xrepl-protocol-eval:valid-response? #m(status done value "42")))
  (is (xrepl-protocol-eval:valid-response? #m(status error error #m(type eval-error message "err"))))
  (is-not (xrepl-protocol-eval:valid-response? #m(status invalid))))

(deftest round-trip-encode-decode
  (let* ((req (xrepl-protocol-eval:request #m(code "(+ 1 2)" session "test")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    ;; MessagePack converts atom keys to binary keys
    (is-equal #"eval" (maps:get #"op" decoded))
    (is-equal #"(+ 1 2)" (maps:get #"code" decoded))
    (is-equal #"test" (maps:get #"session" decoded))
    (is (xrepl-protocol-eval:valid-request? decoded))))
