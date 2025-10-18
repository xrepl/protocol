(defmodule xrepl-ptcl-types-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

(deftest error-response-construction
  (let ((err (xrepl-ptcl-types:error-response 'test-error "Something broke")))
    (is-equal 'error (maps:get 'status err))
    (is-equal 'test-error (maps:get 'type (maps:get 'error err)))
    (is (is_binary (maps:get 'message (maps:get 'error err))))))

(deftest error-response-with-atom-message
  (let ((err (xrepl-ptcl-types:error-response 'test-error 'atom-message)))
    (is (is_binary (maps:get 'message (maps:get 'error err))))))

(deftest status-codes
  (let ((codes (xrepl-ptcl-types:status-codes)))
    (is (lists:member 'done codes))
    (is (lists:member 'error codes))
    (is (lists:member 'pending codes))))

(deftest get-field-with-atom-key
  (let ((msg #m(op eval code "(+ 1 2)")))
    (is-equal 'eval (xrepl-ptcl-types:get-field msg 'op))
    (is-equal "(+ 1 2)" (xrepl-ptcl-types:get-field msg 'code))))

(deftest get-field-with-binary-key
  (let ((msg (map #"op" 'eval #"code" #"(+ 1 2)")))
    (is-equal 'eval (xrepl-ptcl-types:get-field msg 'op))
    (is-equal #"(+ 1 2)" (xrepl-ptcl-types:get-field msg 'code))))

(deftest get-field-with-default
  (let ((msg #m(op eval)))
    (is-equal 'undefined (xrepl-ptcl-types:get-field msg 'missing))
    (is-equal 'default-value (xrepl-ptcl-types:get-field msg 'missing 'default-value))))

(deftest get-required-success
  (let ((msg #m(op eval code "(+ 1 2)")))
    (is-equal '#(ok eval) (xrepl-ptcl-types:get-required msg 'op))))

(deftest get-required-missing
  (let ((msg #m(op eval)))
    (is-match `#(error #(missing-required-field code))
              (xrepl-ptcl-types:get-required msg 'code))))

(deftest ensure-binary-conversions
  (is-equal #"hello" (xrepl-ptcl-types:ensure-binary #"hello"))
  (is-equal #"hello" (xrepl-ptcl-types:ensure-binary "hello"))
  (is-equal #"world" (xrepl-ptcl-types:ensure-binary 'world))
  (is (is_binary (xrepl-ptcl-types:ensure-binary 42))))

(deftest message-envelope-structure
  (let ((envelope (xrepl-ptcl-types:message-envelope)))
    (is (lists:member 'id envelope))
    (is (lists:member 'op envelope))))

;; Tests for new helper functions added in Phase 0

(deftest get-field-any-finds-first
  (let ((msg #m(#"candidate" #"hello")))
    (is-equal #"hello" (xrepl-ptcl-types:get-field-any msg '(candidate text)))))

(deftest get-field-any-finds-second
  (let ((msg #m(#"text" #"hello")))
    (is-equal #"hello" (xrepl-ptcl-types:get-field-any msg '(candidate text)))))

(deftest get-field-any-returns-default
  (let ((msg #m()))
    (is-equal 'not-found
              (xrepl-ptcl-types:get-field-any msg '(candidate text) 'not-found))))

(deftest get-field-any-returns-undefined
  (let ((msg #m()))
    (is-equal 'undefined
              (xrepl-ptcl-types:get-field-any msg '(candidate text)))))

(deftest put-aliased-creates-both-keys
  (let ((result (xrepl-ptcl-types:put-aliased #m() 'candidate 'text #"hello")))
    (is-equal #"hello" (maps:get #"candidate" result))
    (is-equal #"hello" (maps:get #"text" result))))

(deftest put-aliased-converts-atom-value
  (let ((result (xrepl-ptcl-types:put-aliased #m() 'status 'state 'done)))
    (is-equal #"done" (maps:get #"status" result))
    (is-equal #"done" (maps:get #"state" result))))

(deftest put-aliased-list-creates-both-keys
  (let* ((test-values '(#"item1" #"item2"))
         (result (xrepl-ptcl-types:put-aliased-list #m() 'items 'list test-values)))
    (is-equal test-values (maps:get #"items" result))
    (is-equal test-values (maps:get #"list" result))))

(deftest ensure-binary-key-conversions
  (is-equal #"test" (xrepl-ptcl-types:ensure-binary-key 'test))
  (is-equal #"test" (xrepl-ptcl-types:ensure-binary-key #"test"))
  (is-equal #"test" (xrepl-ptcl-types:ensure-binary-key "test")))

(deftest maybe-put-aliased-adds-when-present
  (let* ((opts #m(#"session" #"abc123"))
         (result (xrepl-ptcl-types:maybe-put-aliased #m() 'session 'session_id opts 'session)))
    (is-equal #"abc123" (maps:get #"session" result))
    (is-equal #"abc123" (maps:get #"session_id" result))))

(deftest maybe-put-aliased-skips-when-absent
  (let* ((opts #m())
         (base #m(#"existing" #"value"))
         (result (xrepl-ptcl-types:maybe-put-aliased base 'session 'session_id opts 'session)))
    (is-equal #"value" (maps:get #"existing" result))
    (is-equal 'undefined (maps:get #"session" result 'undefined))))

(deftest ensure-binary-handles-integers
  (is-equal #"42" (xrepl-ptcl-types:ensure-binary 42)))

(deftest ensure-binary-handles-floats
  (let ((result (xrepl-ptcl-types:ensure-binary 3.14)))
    (is (is_binary result))))
