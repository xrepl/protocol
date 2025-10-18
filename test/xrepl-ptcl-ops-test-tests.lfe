(defmodule xrepl-ptcl-ops-test-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; test_run tests

(deftest test-run-request-minimal
  (let ((req (xrepl-ptcl-ops-test:test-run-request #m())))
    (is-equal #"test_run" (maps:get #"op" req))))

(deftest test-run-request-with-namespace
  (let ((req (xrepl-ptcl-ops-test:test-run-request #m(namespace "my-module"))))
    (is-equal #"test_run" (maps:get #"op" req))
    (is-equal #"my-module" (maps:get #"namespace" req))))

(deftest test-run-request-with-pattern
  (let ((req (xrepl-ptcl-ops-test:test-run-request #m(pattern "*foo*"))))
    (is-equal #"test_run" (maps:get #"op" req))
    (is-equal #"*foo*" (maps:get #"pattern" req))))

(deftest test-run-request-with-tests
  (let ((req (xrepl-ptcl-ops-test:test-run-request `#m(tests ,(list "test1" "test2")))))
    (is-equal #"test_run" (maps:get #"op" req))
    (is-equal (list #"test1" #"test2") (maps:get #"tests" req))
    ;; Verify alias is also present
    (is-equal (list #"test1" #"test2") (maps:get #"test_names" req))))

(deftest test-run-request-with-test-names-alias
  (let ((req (xrepl-ptcl-ops-test:test-run-request `#m(test_names ,(list "test3" "test4")))))
    (is-equal #"test_run" (maps:get #"op" req))
    ;; Both primary and alias should be present
    (is-equal (list #"test3" #"test4") (maps:get #"tests" req))
    (is-equal (list #"test3" #"test4") (maps:get #"test_names" req))))

(deftest test-run-request-with-session
  (let ((req (xrepl-ptcl-ops-test:test-run-request #m(namespace "foo" session "s1"))))
    (is-equal #"test_run" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest test-run-request-all-options
  (let ((req (xrepl-ptcl-ops-test:test-run-request
              `#m(namespace "my-module"
                  pattern "*bar*"
                  tests ,(list "test1")
                  session "s1"))))
    (is-equal #"test_run" (maps:get #"op" req))
    (is-equal #"my-module" (maps:get #"namespace" req))
    (is-equal #"*bar*" (maps:get #"pattern" req))
    (is-equal (list #"test1") (maps:get #"tests" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest test-run-response-construction
  (let* ((results (maps:put #"passed" 10
                           (maps:put #"failed" 2
                                    (maps:put #"errors" 1
                                             (maps:put #"duration" 1.5 #m())))))
         (resp (xrepl-ptcl-ops-test:test-run-response results)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal results (maps:get #"results" resp))
    ;; Verify alias is also present
    (is-equal results (maps:get #"test_results" resp))))

;;; test_coverage tests

(deftest test-coverage-request-minimal
  (let ((req (xrepl-ptcl-ops-test:test-coverage-request #m())))
    (is-equal #"test_coverage" (maps:get #"op" req))))

(deftest test-coverage-request-with-namespace
  (let ((req (xrepl-ptcl-ops-test:test-coverage-request #m(namespace "my-module"))))
    (is-equal #"test_coverage" (maps:get #"op" req))
    (is-equal #"my-module" (maps:get #"namespace" req))))

(deftest test-coverage-request-with-format
  (let ((req (xrepl-ptcl-ops-test:test-coverage-request #m(format "detailed"))))
    (is-equal #"test_coverage" (maps:get #"op" req))
    (is-equal #"detailed" (maps:get #"format" req))))

(deftest test-coverage-request-with-session
  (let ((req (xrepl-ptcl-ops-test:test-coverage-request #m(session "s1"))))
    (is-equal #"test_coverage" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest test-coverage-request-all-options
  (let ((req (xrepl-ptcl-ops-test:test-coverage-request
              #m(namespace "my-module" format "html" session "s1"))))
    (is-equal #"test_coverage" (maps:get #"op" req))
    (is-equal #"my-module" (maps:get #"namespace" req))
    (is-equal #"html" (maps:get #"format" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest test-coverage-response-construction
  (let* ((coverage (maps:put #"percentage" 85.5
                            (maps:put #"lines_covered" 342
                                     (maps:put #"lines_total" 400 #m()))))
         (resp (xrepl-ptcl-ops-test:test-coverage-response coverage)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal coverage (maps:get #"coverage" resp))))

;;; test_rerun_failures tests

(deftest test-rerun-failures-request-minimal
  (let ((req (xrepl-ptcl-ops-test:test-rerun-failures-request #m())))
    (is-equal #"test_rerun_failures" (maps:get #"op" req))))

(deftest test-rerun-failures-request-with-session
  (let ((req (xrepl-ptcl-ops-test:test-rerun-failures-request #m(session "s1"))))
    (is-equal #"test_rerun_failures" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest test-rerun-failures-response-construction
  (let* ((results (maps:put #"passed" 1
                           (maps:put #"failed" 1
                                    (maps:put #"duration" 0.5 #m()))))
         (resp (xrepl-ptcl-ops-test:test-rerun-failures-response results)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal results (maps:get #"results" resp))
    ;; Verify alias is also present
    (is-equal results (maps:get #"test_results" resp))))

;;; generate_tests tests

(deftest generate-tests-request-with-namespace
  (let ((req (xrepl-ptcl-ops-test:generate-tests-request #m(namespace "my-module"))))
    (is-equal #"generate_tests" (maps:get #"op" req))
    (is-equal #"my-module" (maps:get #"namespace" req))))

(deftest generate-tests-request-with-function
  (let ((req (xrepl-ptcl-ops-test:generate-tests-request
              #m(namespace "foo" function "bar"))))
    (is-equal #"generate_tests" (maps:get #"op" req))
    (is-equal #"foo" (maps:get #"namespace" req))
    (is-equal #"bar" (maps:get #"function" req))
    ;; Verify alias is also present
    (is-equal #"bar" (maps:get #"function_name" req))))

(deftest generate-tests-request-with-function-name-alias
  (let ((req (xrepl-ptcl-ops-test:generate-tests-request
              #m(namespace "foo" function_name "baz"))))
    (is-equal #"generate_tests" (maps:get #"op" req))
    ;; Both primary and alias should be present
    (is-equal #"baz" (maps:get #"function" req))
    (is-equal #"baz" (maps:get #"function_name" req))))

(deftest generate-tests-request-with-template
  (let ((req (xrepl-ptcl-ops-test:generate-tests-request
              #m(namespace "foo" template "property"))))
    (is-equal #"generate_tests" (maps:get #"op" req))
    (is-equal #"property" (maps:get #"template" req))))

(deftest generate-tests-request-with-session
  (let ((req (xrepl-ptcl-ops-test:generate-tests-request
              #m(namespace "foo" session "s1"))))
    (is-equal #"generate_tests" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest generate-tests-request-all-options
  (let ((req (xrepl-ptcl-ops-test:generate-tests-request
              #m(namespace "my-module"
                 function "my-func"
                 template "unit"
                 session "s1"))))
    (is-equal #"generate_tests" (maps:get #"op" req))
    (is-equal #"my-module" (maps:get #"namespace" req))
    (is-equal #"my-func" (maps:get #"function" req))
    (is-equal #"unit" (maps:get #"template" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest generate-tests-request-missing-namespace
  (let ((result (xrepl-ptcl-ops-test:generate-tests-request #m(function "bar"))))
    (case result
      (`#(error ,_)
       (is 'true))
      (_
       (error "Expected error for missing namespace")))))

(deftest generate-tests-response-construction
  (let* ((generated (maps:put #"file" #"test/my-module-tests.lfe"
                             (maps:put #"code" #"(defun test-foo () ...)"
                                      (maps:put #"count" 3 #m()))))
         (resp (xrepl-ptcl-ops-test:generate-tests-response generated)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal generated (maps:get #"generated" resp))))

;;; Parsing tests

(deftest parse-test-run-request
  (let ((msg #m(#"op" #"test_run" #"namespace" #"my-module")))
    (case (xrepl-ptcl-ops-test:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"test_run" (maps:get #"op" parsed))
       (is-equal #"my-module" (maps:get #"namespace" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-test-run-request-with-pattern
  (let ((msg #m(#"op" #"test_run" #"pattern" #"*foo*")))
    (case (xrepl-ptcl-ops-test:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"test_run" (maps:get #"op" parsed))
       (is-equal #"*foo*" (maps:get #"pattern" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-test-run-request-with-tests-alias
  (let ((msg `#m(#"op" #"test_run" #"test_names" ,(list #"test1" #"test2"))))
    (case (xrepl-ptcl-ops-test:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"test_run" (maps:get #"op" parsed))
       (is-equal (list #"test1" #"test2") (maps:get #"tests" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-test-coverage-request
  (let ((msg #m(#"op" #"test_coverage" #"namespace" #"foo")))
    (case (xrepl-ptcl-ops-test:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"test_coverage" (maps:get #"op" parsed))
       (is-equal #"foo" (maps:get #"namespace" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-test-coverage-request-with-format
  (let ((msg #m(#"op" #"test_coverage" #"format" #"detailed")))
    (case (xrepl-ptcl-ops-test:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"test_coverage" (maps:get #"op" parsed))
       (is-equal #"detailed" (maps:get #"format" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-test-rerun-failures-request
  (let ((msg #m(#"op" #"test_rerun_failures")))
    (case (xrepl-ptcl-ops-test:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"test_rerun_failures" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-generate-tests-request
  (let ((msg #m(#"op" #"generate_tests" #"namespace" #"my-module")))
    (case (xrepl-ptcl-ops-test:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"generate_tests" (maps:get #"op" parsed))
       (is-equal #"my-module" (maps:get #"namespace" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-generate-tests-request-with-function-alias
  (let ((msg #m(#"op" #"generate_tests"
                #"namespace" #"foo"
                #"function_name" #"bar")))
    (case (xrepl-ptcl-ops-test:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"generate_tests" (maps:get #"op" parsed))
       (is-equal #"bar" (maps:get #"function" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-generate-tests-request-missing-namespace
  (let ((msg #m(#"op" #"generate_tests" #"function" #"bar")))
    (case (xrepl-ptcl-ops-test:parse-request msg)
      (`#(error missing-namespace)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-unknown-operation
  (let ((msg #m(#"op" #"unknown_op")))
    (case (xrepl-ptcl-ops-test:parse-request msg)
      (`#(error unknown-operation)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Response parsing tests

(deftest parse-test-run-response
  (let* ((results (maps:put #"passed" 10 (maps:put #"failed" 2 #m())))
         (msg (maps:put #"status" #"done" (maps:put #"results" results #m()))))
    (case (xrepl-ptcl-ops-test:parse-response msg 'test_run)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal results (maps:get #"results" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-test-run-response-with-alias
  (let* ((results (maps:put #"passed" 10 (maps:put #"failed" 2 #m())))
         (msg (maps:put #"status" #"done" (maps:put #"test_results" results #m()))))
    (case (xrepl-ptcl-ops-test:parse-response msg 'test_run)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal results (maps:get #"results" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-test-coverage-response
  (let* ((coverage (maps:put #"percentage" 85.5 #m()))
         (msg (maps:put #"status" #"done" (maps:put #"coverage" coverage #m()))))
    (case (xrepl-ptcl-ops-test:parse-response msg 'test_coverage)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal coverage (maps:get #"coverage" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-test-rerun-failures-response
  (let* ((results (maps:put #"passed" 1 (maps:put #"failed" 1 #m())))
         (msg (maps:put #"status" #"done" (maps:put #"results" results #m()))))
    (case (xrepl-ptcl-ops-test:parse-response msg 'test_rerun_failures)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal results (maps:get #"results" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-generate-tests-response
  (let* ((generated (maps:put #"file" #"test.lfe" (maps:put #"count" 3 #m())))
         (msg (maps:put #"status" #"done" (maps:put #"generated" generated #m()))))
    (case (xrepl-ptcl-ops-test:parse-response msg 'generate_tests)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal generated (maps:get #"generated" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-test-run-request
  (let ((req (xrepl-ptcl-ops-test:test-run-request #m(namespace "foo"))))
    (is (xrepl-ptcl-ops-test:valid-request? req))))

(deftest valid-test-run-request-minimal
  (let ((req (xrepl-ptcl-ops-test:test-run-request #m())))
    (is (xrepl-ptcl-ops-test:valid-request? req))))

(deftest valid-test-coverage-request
  (let ((req (xrepl-ptcl-ops-test:test-coverage-request #m())))
    (is (xrepl-ptcl-ops-test:valid-request? req))))

(deftest valid-test-rerun-failures-request
  (let ((req (xrepl-ptcl-ops-test:test-rerun-failures-request #m())))
    (is (xrepl-ptcl-ops-test:valid-request? req))))

(deftest valid-generate-tests-request
  (let ((req (xrepl-ptcl-ops-test:generate-tests-request #m(namespace "foo"))))
    (is (xrepl-ptcl-ops-test:valid-request? req))))

(deftest invalid-generate-tests-request-missing-namespace
  (let ((req #m(#"op" #"generate_tests")))
    (is-not (xrepl-ptcl-ops-test:valid-request? req))))

(deftest invalid-request-missing-op
  (let ((req #m(#"namespace" #"foo")))
    (is-not (xrepl-ptcl-ops-test:valid-request? req))))

(deftest invalid-request-unknown-op
  (let ((req #m(#"op" #"unknown_operation")))
    (is-not (xrepl-ptcl-ops-test:valid-request? req))))

;;; Response validation tests

(deftest valid-test-run-response
  (let* ((results (maps:put #"passed" 10 #m()))
         (resp (xrepl-ptcl-ops-test:test-run-response results)))
    (is (xrepl-ptcl-ops-test:valid-response? resp 'test_run))))

(deftest invalid-test-run-response-missing-results
  (let ((resp #m(#"status" #"done")))
    (is-not (xrepl-ptcl-ops-test:valid-response? resp 'test_run))))

(deftest valid-test-coverage-response
  (let* ((coverage (maps:put #"percentage" 85.5 #m()))
         (resp (xrepl-ptcl-ops-test:test-coverage-response coverage)))
    (is (xrepl-ptcl-ops-test:valid-response? resp 'test_coverage))))

(deftest invalid-test-coverage-response-missing-coverage
  (let ((resp #m(#"status" #"done")))
    (is-not (xrepl-ptcl-ops-test:valid-response? resp 'test_coverage))))

(deftest valid-test-rerun-failures-response
  (let* ((results (maps:put #"passed" 1 #m()))
         (resp (xrepl-ptcl-ops-test:test-rerun-failures-response results)))
    (is (xrepl-ptcl-ops-test:valid-response? resp 'test_rerun_failures))))

(deftest valid-generate-tests-response
  (let* ((generated (maps:put #"file" #"test.lfe" #m()))
         (resp (xrepl-ptcl-ops-test:generate-tests-response generated)))
    (is (xrepl-ptcl-ops-test:valid-response? resp 'generate_tests))))

(deftest invalid-generate-tests-response-missing-generated
  (let ((resp #m(#"status" #"done")))
    (is-not (xrepl-ptcl-ops-test:valid-response? resp 'generate_tests))))

(deftest invalid-response-missing-status
  (let* ((results (maps:put #"passed" 10 #m()))
         (resp #m(#"results" results)))
    (is-not (xrepl-ptcl-ops-test:valid-response? resp 'test_run))))

;;; Round-trip MessagePack tests

(deftest roundtrip-test-run-request
  (let* ((req (xrepl-ptcl-ops-test:test-run-request
               #m(namespace "foo" pattern "*bar*")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"test_run" (maps:get #"op" decoded))
    (is-equal #"foo" (maps:get #"namespace" decoded))
    (is-equal #"*bar*" (maps:get #"pattern" decoded))))

(deftest roundtrip-test-run-response
  (let* ((results (maps:put #"passed" 10
                           (maps:put #"failed" 2
                                    (maps:put #"duration" 1.5 #m()))))
         (resp (xrepl-ptcl-ops-test:test-run-response results))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal results (maps:get #"results" decoded))
    ;; Verify aliases are preserved
    (is-equal results (maps:get #"test_results" decoded))))

(deftest roundtrip-test-coverage-request
  (let* ((req (xrepl-ptcl-ops-test:test-coverage-request
               #m(namespace "foo" format "detailed")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"test_coverage" (maps:get #"op" decoded))
    (is-equal #"foo" (maps:get #"namespace" decoded))
    (is-equal #"detailed" (maps:get #"format" decoded))))

(deftest roundtrip-test-coverage-response
  (let* ((coverage (maps:put #"percentage" 85.5
                            (maps:put #"lines_covered" 342 #m())))
         (resp (xrepl-ptcl-ops-test:test-coverage-response coverage))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal coverage (maps:get #"coverage" decoded))))

(deftest roundtrip-test-rerun-failures-request
  (let* ((req (xrepl-ptcl-ops-test:test-rerun-failures-request #m(session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"test_rerun_failures" (maps:get #"op" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))))

(deftest roundtrip-test-rerun-failures-response
  (let* ((results (maps:put #"passed" 1 (maps:put #"failed" 1 #m())))
         (resp (xrepl-ptcl-ops-test:test-rerun-failures-response results))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal results (maps:get #"results" decoded))
    ;; Verify aliases are preserved
    (is-equal results (maps:get #"test_results" decoded))))

(deftest roundtrip-generate-tests-request
  (let* ((req (xrepl-ptcl-ops-test:generate-tests-request
               #m(namespace "foo" function "bar" template "unit")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"generate_tests" (maps:get #"op" decoded))
    (is-equal #"foo" (maps:get #"namespace" decoded))
    (is-equal #"bar" (maps:get #"function" decoded))
    ;; Verify alias is preserved
    (is-equal #"bar" (maps:get #"function_name" decoded))
    (is-equal #"unit" (maps:get #"template" decoded))))

(deftest roundtrip-generate-tests-response
  (let* ((generated (maps:put #"file" #"test/foo-tests.lfe"
                             (maps:put #"code" #"(defun test-foo () ...)"
                                      (maps:put #"count" 3 #m()))))
         (resp (xrepl-ptcl-ops-test:generate-tests-response generated))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal generated (maps:get #"generated" decoded))))

;;; Error tests

(deftest error-construction
  (let ((err (xrepl-ptcl-ops-test:error 'test-failure "Test failed")))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"test-failure" (maps:get #"error-type" err))
    (is-equal #"Test failed" (maps:get #"error" err))))
