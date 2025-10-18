(defmodule xrepl-protocol-types-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

(deftest error-response-construction
  (let ((err (xrepl-protocol-types:error-response 'test-error "Something broke")))
    (is-equal 'error (maps:get 'status err))
    (is-equal 'test-error (maps:get 'type (maps:get 'error err)))
    (is (is_binary (maps:get 'message (maps:get 'error err))))))

(deftest error-response-with-atom-message
  (let ((err (xrepl-protocol-types:error-response 'test-error 'atom-message)))
    (is (is_binary (maps:get 'message (maps:get 'error err))))))

(deftest status-codes
  (let ((codes (xrepl-protocol-types:status-codes)))
    (is (lists:member 'done codes))
    (is (lists:member 'error codes))
    (is (lists:member 'pending codes))))

(deftest get-field-with-atom-key
  (let ((msg #m(op eval code "(+ 1 2)")))
    (is-equal 'eval (xrepl-protocol-types:get-field msg 'op))
    (is-equal "(+ 1 2)" (xrepl-protocol-types:get-field msg 'code))))

(deftest get-field-with-binary-key
  (let ((msg (map #"op" 'eval #"code" #"(+ 1 2)")))
    (is-equal 'eval (xrepl-protocol-types:get-field msg 'op))
    (is-equal #"(+ 1 2)" (xrepl-protocol-types:get-field msg 'code))))

(deftest get-field-with-default
  (let ((msg #m(op eval)))
    (is-equal 'undefined (xrepl-protocol-types:get-field msg 'missing))
    (is-equal 'default-value (xrepl-protocol-types:get-field msg 'missing 'default-value))))

(deftest get-required-success
  (let ((msg #m(op eval code "(+ 1 2)")))
    (is-equal '#(ok eval) (xrepl-protocol-types:get-required msg 'op))))

(deftest get-required-missing
  (let ((msg #m(op eval)))
    (is-match `#(error #(missing-required-field code))
              (xrepl-protocol-types:get-required msg 'code))))

(deftest ensure-binary-conversions
  (is-equal #"hello" (xrepl-protocol-types:ensure-binary #"hello"))
  (is-equal #"hello" (xrepl-protocol-types:ensure-binary "hello"))
  (is-equal #"world" (xrepl-protocol-types:ensure-binary 'world))
  (is (is_binary (xrepl-protocol-types:ensure-binary 42))))

(deftest message-envelope-structure
  (let ((envelope (xrepl-protocol-types:message-envelope)))
    (is (lists:member 'id envelope))
    (is (lists:member 'op envelope))))
