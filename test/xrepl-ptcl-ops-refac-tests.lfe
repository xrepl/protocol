(defmodule xrepl-ptcl-ops-refac-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; rename_symbol tests

(deftest rename-symbol-request-minimal
  (let ((req (xrepl-ptcl-ops-refac:rename-symbol-request
              #m(symbol "foo" new_name "bar"))))
    (is-equal #"rename_symbol" (maps:get #"op" req))
    (is-equal #"foo" (maps:get #"symbol" req))
    (is-equal #"foo" (maps:get #"old_name" req))
    (is-equal #"bar" (maps:get #"new_name" req))))

(deftest rename-symbol-request-with-old-name-alias
  (let ((req (xrepl-ptcl-ops-refac:rename-symbol-request
              #m(old_name "baz" new_name "qux"))))
    (is-equal #"rename_symbol" (maps:get #"op" req))
    (is-equal #"baz" (maps:get #"symbol" req))
    (is-equal #"baz" (maps:get #"old_name" req))
    (is-equal #"qux" (maps:get #"new_name" req))))

(deftest rename-symbol-request-with-file
  (let ((req (xrepl-ptcl-ops-refac:rename-symbol-request
              #m(symbol "foo" new_name "bar" file "src/test.lfe"))))
    (is-equal #"rename_symbol" (maps:get #"op" req))
    (is-equal #"src/test.lfe" (maps:get #"file" req))))

(deftest rename-symbol-request-with-location
  (let ((req (xrepl-ptcl-ops-refac:rename-symbol-request
              #m(symbol "foo" new_name "bar" file "test.lfe" line 10 column 5))))
    (is-equal #"rename_symbol" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest rename-symbol-request-with-scope
  (let ((req (xrepl-ptcl-ops-refac:rename-symbol-request
              #m(symbol "foo" new_name "bar" scope "project"))))
    (is-equal #"rename_symbol" (maps:get #"op" req))
    (is-equal #"project" (maps:get #"scope" req))))

(deftest rename-symbol-request-with-session
  (let ((req (xrepl-ptcl-ops-refac:rename-symbol-request
              #m(symbol "foo" new_name "bar" session "s1"))))
    (is-equal #"rename_symbol" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest rename-symbol-request-missing-symbol
  (let ((result (xrepl-ptcl-ops-refac:rename-symbol-request #m(new_name "bar"))))
    (case result
      (`#(error missing-symbol)
       (is 'true))
      (_
       (error "Expected error for missing symbol")))))

(deftest rename-symbol-request-missing-new-name
  (let ((result (xrepl-ptcl-ops-refac:rename-symbol-request #m(symbol "foo"))))
    (case result
      (`#(error ,_)
       (is 'true))
      (_
       (error "Expected error for missing new_name")))))

(deftest rename-symbol-response-construction
  (let* ((changes (maps:put #"files_changed" 3
                           (maps:put #"total_edits" 12 #m())))
         (resp (xrepl-ptcl-ops-refac:rename-symbol-response changes)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal changes (maps:get #"changes" resp))))

;;; extract_function tests

(deftest extract-function-request-minimal
  (let ((req (xrepl-ptcl-ops-refac:extract-function-request
              #m(code "(+ x y)" function_name "add-nums"))))
    (is-equal #"extract_function" (maps:get #"op" req))
    (is-equal #"(+ x y)" (maps:get #"code" req))
    (is-equal #"(+ x y)" (maps:get #"selection" req))
    (is-equal #"add-nums" (maps:get #"function_name" req))
    (is-equal #"add-nums" (maps:get #"name" req))))

(deftest extract-function-request-with-selection-alias
  (let ((req (xrepl-ptcl-ops-refac:extract-function-request
              #m(selection "foo" name "bar"))))
    (is-equal #"extract_function" (maps:get #"op" req))
    (is-equal #"foo" (maps:get #"code" req))
    (is-equal #"foo" (maps:get #"selection" req))
    (is-equal #"bar" (maps:get #"function_name" req))
    (is-equal #"bar" (maps:get #"name" req))))

(deftest extract-function-request-with-file
  (let ((req (xrepl-ptcl-ops-refac:extract-function-request
              #m(code "code" function_name "fn" file "test.lfe"))))
    (is-equal #"extract_function" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))))

(deftest extract-function-request-with-start-location
  (let ((req (xrepl-ptcl-ops-refac:extract-function-request
              #m(code "code" function_name "fn" line 10 column 5))))
    (is-equal #"extract_function" (maps:get #"op" req))
    (is-equal 10 (maps:get #"start_line" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"start_column" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest extract-function-request-with-full-range
  (let ((req (xrepl-ptcl-ops-refac:extract-function-request
              #m(code "code" function_name "fn"
                 start_line 10 start_column 5
                 end_line 15 end_column 20))))
    (is-equal #"extract_function" (maps:get #"op" req))
    (is-equal 10 (maps:get #"start_line" req))
    (is-equal 5 (maps:get #"start_column" req))
    (is-equal 15 (maps:get #"end_line" req))
    (is-equal 20 (maps:get #"end_column" req))))

(deftest extract-function-request-with-session
  (let ((req (xrepl-ptcl-ops-refac:extract-function-request
              #m(code "code" function_name "fn" session "s1"))))
    (is-equal #"extract_function" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest extract-function-request-missing-code
  (let ((result (xrepl-ptcl-ops-refac:extract-function-request
                 #m(function_name "fn"))))
    (case result
      (`#(error missing-code)
       (is 'true))
      (_
       (error "Expected error for missing code")))))

(deftest extract-function-request-missing-function-name
  (let ((result (xrepl-ptcl-ops-refac:extract-function-request #m(code "code"))))
    (case result
      (`#(error missing-function-name)
       (is 'true))
      (_
       (error "Expected error for missing function_name")))))

(deftest extract-function-response-construction
  (let* ((result (maps:put #"function" #"(defun add-nums (x y) (+ x y))"
                          (maps:put #"modified_code" #"(add-nums 1 2)" #m())))
         (resp (xrepl-ptcl-ops-refac:extract-function-response result)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal result (maps:get #"result" resp))))

;;; inline_function tests

(deftest inline-function-request-minimal
  (let ((req (xrepl-ptcl-ops-refac:inline-function-request #m(function "add-nums"))))
    (is-equal #"inline_function" (maps:get #"op" req))
    (is-equal #"add-nums" (maps:get #"function" req))
    (is-equal #"add-nums" (maps:get #"symbol" req))))

(deftest inline-function-request-with-symbol-alias
  (let ((req (xrepl-ptcl-ops-refac:inline-function-request #m(symbol "foo"))))
    (is-equal #"inline_function" (maps:get #"op" req))
    (is-equal #"foo" (maps:get #"function" req))
    (is-equal #"foo" (maps:get #"symbol" req))))

(deftest inline-function-request-with-file
  (let ((req (xrepl-ptcl-ops-refac:inline-function-request
              #m(function "foo" file "test.lfe"))))
    (is-equal #"inline_function" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))))

(deftest inline-function-request-with-location
  (let ((req (xrepl-ptcl-ops-refac:inline-function-request
              #m(function "foo" line 10 column 5))))
    (is-equal #"inline_function" (maps:get #"op" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest inline-function-request-with-all-calls
  (let ((req (xrepl-ptcl-ops-refac:inline-function-request
              `#m(function "foo" all_calls ,'true))))
    (is-equal #"inline_function" (maps:get #"op" req))
    (is-equal 'true (maps:get #"all_calls" req))))

(deftest inline-function-request-with-session
  (let ((req (xrepl-ptcl-ops-refac:inline-function-request
              #m(function "foo" session "s1"))))
    (is-equal #"inline_function" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest inline-function-request-missing-function
  (let ((result (xrepl-ptcl-ops-refac:inline-function-request #m())))
    (case result
      (`#(error missing-function)
       (is 'true))
      (_
       (error "Expected error for missing function")))))

(deftest inline-function-response-construction
  (let* ((result (maps:put #"files_changed" 2
                          (maps:put #"total_edits" 5 #m())))
         (resp (xrepl-ptcl-ops-refac:inline-function-response result)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal result (maps:get #"result" resp))))

;;; Parsing tests

(deftest parse-rename-symbol-request
  (let ((msg #m(#"op" #"rename_symbol"
                #"symbol" #"foo"
                #"new_name" #"bar")))
    (case (xrepl-ptcl-ops-refac:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"rename_symbol" (maps:get #"op" parsed))
       (is-equal #"foo" (maps:get #"symbol" parsed))
       (is-equal #"bar" (maps:get #"new_name" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-rename-symbol-request-with-old-name-alias
  (let ((msg #m(#"op" #"rename_symbol"
                #"old_name" #"baz"
                #"new_name" #"qux")))
    (case (xrepl-ptcl-ops-refac:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"rename_symbol" (maps:get #"op" parsed))
       (is-equal #"baz" (maps:get #"symbol" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-rename-symbol-request-missing-symbol
  (let ((msg #m(#"op" #"rename_symbol" #"new_name" #"bar")))
    (case (xrepl-ptcl-ops-refac:parse-request msg)
      (`#(error missing-required-field)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-extract-function-request
  (let ((msg #m(#"op" #"extract_function"
                #"code" #"(+ x y)"
                #"function_name" #"add-nums")))
    (case (xrepl-ptcl-ops-refac:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"extract_function" (maps:get #"op" parsed))
       (is-equal #"(+ x y)" (maps:get #"code" parsed))
       (is-equal #"add-nums" (maps:get #"function_name" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-extract-function-request-with-aliases
  (let ((msg #m(#"op" #"extract_function"
                #"selection" #"foo"
                #"name" #"bar")))
    (case (xrepl-ptcl-ops-refac:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"extract_function" (maps:get #"op" parsed))
       (is-equal #"foo" (maps:get #"code" parsed))
       (is-equal #"bar" (maps:get #"function_name" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-extract-function-request-missing-code
  (let ((msg #m(#"op" #"extract_function" #"function_name" #"fn")))
    (case (xrepl-ptcl-ops-refac:parse-request msg)
      (`#(error missing-required-field)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-inline-function-request
  (let ((msg #m(#"op" #"inline_function" #"function" #"foo")))
    (case (xrepl-ptcl-ops-refac:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"inline_function" (maps:get #"op" parsed))
       (is-equal #"foo" (maps:get #"function" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-inline-function-request-with-symbol-alias
  (let ((msg #m(#"op" #"inline_function" #"symbol" #"bar")))
    (case (xrepl-ptcl-ops-refac:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"inline_function" (maps:get #"op" parsed))
       (is-equal #"bar" (maps:get #"function" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-inline-function-request-missing-function
  (let ((msg #m(#"op" #"inline_function")))
    (case (xrepl-ptcl-ops-refac:parse-request msg)
      (`#(error missing-function)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-unknown-operation
  (let ((msg #m(#"op" #"unknown_op")))
    (case (xrepl-ptcl-ops-refac:parse-request msg)
      (`#(error unknown-operation)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Response parsing tests

(deftest parse-rename-symbol-response
  (let* ((changes (maps:put #"files_changed" 3 #m()))
         (msg (maps:put #"status" #"done" (maps:put #"changes" changes #m()))))
    (case (xrepl-ptcl-ops-refac:parse-response msg 'rename_symbol)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal changes (maps:get #"changes" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-extract-function-response
  (let* ((result (maps:put #"function" #"(defun foo () ...)" #m()))
         (msg (maps:put #"status" #"done" (maps:put #"result" result #m()))))
    (case (xrepl-ptcl-ops-refac:parse-response msg 'extract_function)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal result (maps:get #"result" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-inline-function-response
  (let* ((result (maps:put #"files_changed" 2 #m()))
         (msg (maps:put #"status" #"done" (maps:put #"result" result #m()))))
    (case (xrepl-ptcl-ops-refac:parse-response msg 'inline_function)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal result (maps:get #"result" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-rename-symbol-request
  (let ((req (xrepl-ptcl-ops-refac:rename-symbol-request
              #m(symbol "foo" new_name "bar"))))
    (is (xrepl-ptcl-ops-refac:valid-request? req))))

(deftest invalid-rename-symbol-request-missing-symbol
  (let ((req #m(#"op" #"rename_symbol" #"new_name" #"bar")))
    (is-not (xrepl-ptcl-ops-refac:valid-request? req))))

(deftest invalid-rename-symbol-request-missing-new-name
  (let ((req #m(#"op" #"rename_symbol" #"symbol" #"foo")))
    (is-not (xrepl-ptcl-ops-refac:valid-request? req))))

(deftest valid-extract-function-request
  (let ((req (xrepl-ptcl-ops-refac:extract-function-request
              #m(code "code" function_name "fn"))))
    (is (xrepl-ptcl-ops-refac:valid-request? req))))

(deftest invalid-extract-function-request-missing-code
  (let ((req #m(#"op" #"extract_function" #"function_name" #"fn")))
    (is-not (xrepl-ptcl-ops-refac:valid-request? req))))

(deftest invalid-extract-function-request-missing-name
  (let ((req #m(#"op" #"extract_function" #"code" #"code")))
    (is-not (xrepl-ptcl-ops-refac:valid-request? req))))

(deftest valid-inline-function-request
  (let ((req (xrepl-ptcl-ops-refac:inline-function-request #m(function "foo"))))
    (is (xrepl-ptcl-ops-refac:valid-request? req))))

(deftest invalid-inline-function-request-missing-function
  (let ((req #m(#"op" #"inline_function")))
    (is-not (xrepl-ptcl-ops-refac:valid-request? req))))

(deftest invalid-request-missing-op
  (let ((req #m(#"symbol" #"foo")))
    (is-not (xrepl-ptcl-ops-refac:valid-request? req))))

(deftest invalid-request-unknown-op
  (let ((req #m(#"op" #"unknown_operation")))
    (is-not (xrepl-ptcl-ops-refac:valid-request? req))))

;;; Response validation tests

(deftest valid-rename-symbol-response
  (let* ((changes (maps:put #"files_changed" 3 #m()))
         (resp (xrepl-ptcl-ops-refac:rename-symbol-response changes)))
    (is (xrepl-ptcl-ops-refac:valid-response? resp 'rename_symbol))))

(deftest invalid-rename-symbol-response-missing-changes
  (let ((resp #m(#"status" #"done")))
    (is-not (xrepl-ptcl-ops-refac:valid-response? resp 'rename_symbol))))

(deftest valid-extract-function-response
  (let* ((result (maps:put #"function" #"..." #m()))
         (resp (xrepl-ptcl-ops-refac:extract-function-response result)))
    (is (xrepl-ptcl-ops-refac:valid-response? resp 'extract_function))))

(deftest invalid-extract-function-response-missing-result
  (let ((resp #m(#"status" #"done")))
    (is-not (xrepl-ptcl-ops-refac:valid-response? resp 'extract_function))))

(deftest valid-inline-function-response
  (let* ((result (maps:put #"files_changed" 2 #m()))
         (resp (xrepl-ptcl-ops-refac:inline-function-response result)))
    (is (xrepl-ptcl-ops-refac:valid-response? resp 'inline_function))))

(deftest invalid-inline-function-response-missing-result
  (let ((resp #m(#"status" #"done")))
    (is-not (xrepl-ptcl-ops-refac:valid-response? resp 'inline_function))))

(deftest invalid-response-missing-status
  (let* ((changes (maps:put #"files_changed" 3 #m()))
         (resp #m(#"changes" changes)))
    (is-not (xrepl-ptcl-ops-refac:valid-response? resp 'rename_symbol))))

;;; Round-trip MessagePack tests

(deftest roundtrip-rename-symbol-request
  (let* ((req (xrepl-ptcl-ops-refac:rename-symbol-request
               #m(symbol "foo" new_name "bar" file "test.lfe")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"rename_symbol" (maps:get #"op" decoded))
    (is-equal #"foo" (maps:get #"symbol" decoded))
    (is-equal #"foo" (maps:get #"old_name" decoded))
    (is-equal #"bar" (maps:get #"new_name" decoded))
    (is-equal #"test.lfe" (maps:get #"file" decoded))))

(deftest roundtrip-rename-symbol-response
  (let* ((changes (maps:put #"files_changed" 3
                           (maps:put #"total_edits" 12 #m())))
         (resp (xrepl-ptcl-ops-refac:rename-symbol-response changes))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal changes (maps:get #"changes" decoded))))

(deftest roundtrip-extract-function-request
  (let* ((req (xrepl-ptcl-ops-refac:extract-function-request
               #m(code "(+ x y)" function_name "add-nums" line 10)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"extract_function" (maps:get #"op" decoded))
    (is-equal #"(+ x y)" (maps:get #"code" decoded))
    (is-equal #"(+ x y)" (maps:get #"selection" decoded))
    (is-equal #"add-nums" (maps:get #"function_name" decoded))
    (is-equal #"add-nums" (maps:get #"name" decoded))
    (is-equal 10 (maps:get #"start_line" decoded))
    (is-equal 10 (maps:get #"line" decoded))))

(deftest roundtrip-extract-function-response
  (let* ((result (maps:put #"function" #"(defun add-nums (x y) (+ x y))"
                          (maps:put #"modified_code" #"(add-nums 1 2)" #m())))
         (resp (xrepl-ptcl-ops-refac:extract-function-response result))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal result (maps:get #"result" decoded))))

(deftest roundtrip-inline-function-request
  (let* ((req (xrepl-ptcl-ops-refac:inline-function-request
               #m(function "foo" file "test.lfe")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"inline_function" (maps:get #"op" decoded))
    (is-equal #"foo" (maps:get #"function" decoded))
    (is-equal #"foo" (maps:get #"symbol" decoded))
    (is-equal #"test.lfe" (maps:get #"file" decoded))))

(deftest roundtrip-inline-function-response
  (let* ((result (maps:put #"files_changed" 2
                          (maps:put #"total_edits" 5 #m())))
         (resp (xrepl-ptcl-ops-refac:inline-function-response result))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal result (maps:get #"result" decoded))))

;;; Error tests

(deftest error-construction
  (let ((err (xrepl-ptcl-ops-refac:error 'refactoring-failed "Refactoring failed")))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"refactoring-failed" (maps:get #"error-type" err))
    (is-equal #"Refactoring failed" (maps:get #"error" err))))
