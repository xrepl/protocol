(defmodule xrepl-ptcl-ops-test
  "Testing operation protocol messages.

  This module defines all testing operations in the xrepl protocol."
  (export
   ;; test_run operation
   (test-run-request 1)
   (test-run-response 1)
   ;; test_coverage operation
   (test-coverage-request 1)
   (test-coverage-response 1)
   ;; test_rerun_failures operation
   (test-rerun-failures-request 1)
   (test-rerun-failures-response 1)
   ;; generate_tests operation
   (generate-tests-request 1)
   (generate-tests-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; test_run operation

(defun test-run-request (opts)
  "Build a test_run request.

  Options:
    namespace: Module/namespace to test (optional, defaults to all)
    pattern: Test pattern to match (optional)
    tests: List of specific test names (optional, alias: test_names)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (test-run-request #m())
    (test-run-request #m(namespace \"my-module\"))
    (test-run-request #m(pattern \"*foo*\" session \"s1\"))
    (test-run-request #m(tests (list \"test1\" \"test2\")))"
  (let* ((base (maps:put #"op" #"test_run" #m()))
         (with-ns (case (xrepl-ptcl-types:get-field opts 'namespace 'undefined)
                   ('undefined base)
                   (ns (maps:put #"namespace"
                                (xrepl-ptcl-types:ensure-binary ns)
                                base))))
         (with-pattern (case (xrepl-ptcl-types:get-field opts 'pattern 'undefined)
                        ('undefined with-ns)
                        (pat (maps:put #"pattern"
                                      (xrepl-ptcl-types:ensure-binary pat)
                                      with-ns))))
         (with-tests (case (xrepl-ptcl-types:get-field-any opts '(tests test_names))
                      ('undefined with-pattern)
                      (tests (xrepl-ptcl-types:put-aliased-list
                             with-pattern 'tests 'test_names
                             (lists:map #'xrepl-ptcl-types:ensure-binary/1 tests)))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                       with-tests 'session 'session opts 'session)))
    with-session))

(defun test-run-response (results)
  "Build a test_run response.

  Args:
    results: Test results map with passed, failed, errors, etc.

  Returns:
    Response message map

  Example:
    (test-run-response #m(#\"passed\" 10
                          #\"failed\" 2
                          #\"errors\" 1
                          #\"duration\" 1.5
                          #\"failures\" (list #m(#\"test\" #\"foo\"
                                                 #\"message\" #\"expected 1\"))))"
  (xrepl-ptcl-types:put-aliased
   (maps:put #"status" #"done" #m())
   'results 'test_results results))

;;; test_coverage operation

(defun test-coverage-request (opts)
  "Build a test_coverage request.

  Options:
    namespace: Module/namespace to analyze (optional, defaults to all)
    format: Coverage format (optional, values: summary, detailed, html)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (test-coverage-request #m())
    (test-coverage-request #m(namespace \"my-module\"))
    (test-coverage-request #m(format \"detailed\" session \"s1\"))"
  (let* ((base (maps:put #"op" #"test_coverage" #m()))
         (with-ns (case (xrepl-ptcl-types:get-field opts 'namespace 'undefined)
                   ('undefined base)
                   (ns (maps:put #"namespace"
                                (xrepl-ptcl-types:ensure-binary ns)
                                base))))
         (with-format (case (xrepl-ptcl-types:get-field opts 'format 'undefined)
                       ('undefined with-ns)
                       (fmt (maps:put #"format"
                                     (xrepl-ptcl-types:ensure-binary fmt)
                                     with-ns))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                       with-format 'session 'session opts 'session)))
    with-session))

(defun test-coverage-response (coverage)
  "Build a test_coverage response.

  Args:
    coverage: Coverage data map with percentage, files, lines covered, etc.

  Returns:
    Response message map

  Example:
    (test-coverage-response #m(#\"percentage\" 85.5
                               #\"lines_covered\" 342
                               #\"lines_total\" 400
                               #\"files\" (list #m(#\"file\" #\"foo.lfe\"
                                                    #\"coverage\" 90.0))))"
  (maps:put #"status" #"done"
           (maps:put #"coverage" coverage #m())))

;;; test_rerun_failures operation

(defun test-rerun-failures-request (opts)
  "Build a test_rerun_failures request.

  Options:
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (test-rerun-failures-request #m())
    (test-rerun-failures-request #m(session \"s1\"))"
  (let* ((base (maps:put #"op" #"test_rerun_failures" #m()))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                       base 'session 'session opts 'session)))
    with-session))

(defun test-rerun-failures-response (results)
  "Build a test_rerun_failures response.

  Args:
    results: Test results map (same format as test_run response)

  Returns:
    Response message map

  Example:
    (test-rerun-failures-response #m(#\"passed\" 1
                                     #\"failed\" 1
                                     #\"duration\" 0.5))"
  (xrepl-ptcl-types:put-aliased
   (maps:put #"status" #"done" #m())
   'results 'test_results results))

;;; generate_tests operation

(defun generate-tests-request (opts)
  "Build a generate_tests request.

  Options:
    namespace: Module/namespace to generate tests for (required)
    function: Specific function to generate tests for (optional, alias: function_name)
    template: Test template to use (optional, values: unit, property, integration)
    session: Session ID (optional)

  Returns:
    Request message map or error

  Example:
    (generate-tests-request #m(namespace \"my-module\"))
    (generate-tests-request #m(namespace \"foo\" function \"bar\"))
    (generate-tests-request #m(namespace \"baz\" template \"property\"))"
  (case (xrepl-ptcl-types:get-required opts 'namespace)
    (`#(ok ,ns)
     (let* ((base (maps:put #"op" #"generate_tests"
                           (maps:put #"namespace"
                                    (xrepl-ptcl-types:ensure-binary ns)
                                    #m())))
            (with-fn (case (xrepl-ptcl-types:get-field-any opts '(function function_name))
                      ('undefined base)
                      (fn (xrepl-ptcl-types:put-aliased
                          base 'function 'function_name
                          (xrepl-ptcl-types:ensure-binary fn)))))
            (with-template (case (xrepl-ptcl-types:get-field opts 'template 'undefined)
                            ('undefined with-fn)
                            (tmpl (maps:put #"template"
                                           (xrepl-ptcl-types:ensure-binary tmpl)
                                           with-fn))))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                          with-template 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun generate-tests-response (generated)
  "Build a generate_tests response.

  Args:
    generated: Generated test info map with file, code, count

  Returns:
    Response message map

  Example:
    (generate-tests-response #m(#\"file\" #\"test/my-module-tests.lfe\"
                                #\"code\" #\"(defun test-foo () ...)\"
                                #\"count\" 3))"
  (maps:put #"status" #"done"
           (maps:put #"generated" generated #m())))

;;; Parsing functions

(defun parse-request (message)
  "Parse a testing operation request message.

  Args:
    message: The request message map (with binary keys from MessagePack)

  Returns:
    #(ok parsed-message) or #(error reason)"
  (let ((op (xrepl-ptcl-types:get-field message 'op)))
    (cond
      ;; test_run
      ((or (== op #"test_run") (== op 'test_run))
       (let ((namespace (xrepl-ptcl-types:get-field message 'namespace))
             (pattern (xrepl-ptcl-types:get-field message 'pattern))
             (tests (xrepl-ptcl-types:get-field-any message '(tests test_names)))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (tuple 'ok (maps:put #"op" #"test_run"
                             (maps:put #"namespace" namespace
                                      (maps:put #"pattern" pattern
                                               (maps:put #"tests" tests
                                                        (maps:put #"session" session #m()))))))))

      ;; test_coverage
      ((or (== op #"test_coverage") (== op 'test_coverage))
       (let ((namespace (xrepl-ptcl-types:get-field message 'namespace))
             (format (xrepl-ptcl-types:get-field message 'format))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (tuple 'ok (maps:put #"op" #"test_coverage"
                             (maps:put #"namespace" namespace
                                      (maps:put #"format" format
                                               (maps:put #"session" session #m())))))))

      ;; test_rerun_failures
      ((or (== op #"test_rerun_failures") (== op 'test_rerun_failures))
       (let ((session (xrepl-ptcl-types:get-field message 'session)))
         (tuple 'ok (maps:put #"op" #"test_rerun_failures"
                             (maps:put #"session" session #m())))))

      ;; generate_tests
      ((or (== op #"generate_tests") (== op 'generate_tests))
       (let ((namespace (xrepl-ptcl-types:get-field message 'namespace))
             (function (xrepl-ptcl-types:get-field-any message '(function function_name)))
             (template (xrepl-ptcl-types:get-field message 'template))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (if (== namespace 'undefined)
           (tuple 'error 'missing-namespace)
           (tuple 'ok (maps:put #"op" #"generate_tests"
                               (maps:put #"namespace" namespace
                                        (maps:put #"function" function
                                                 (maps:put #"template" template
                                                          (maps:put #"session" session #m())))))))))

      ;; Unknown operation
      ('true
       (tuple 'error 'unknown-operation)))))

(defun parse-response (message op)
  "Parse a testing operation response message.

  Args:
    message: The response message map (with binary keys from MessagePack)
    op: The operation name (atom or binary)

  Returns:
    #(ok parsed-response) or #(error reason)"
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (cond
      ;; test_run response
      ((or (== op #"test_run") (== op 'test_run))
       (let ((results (xrepl-ptcl-types:get-field-any message '(results test_results))))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"results" results #m())))))

      ;; test_coverage response
      ((or (== op #"test_coverage") (== op 'test_coverage))
       (let ((coverage (xrepl-ptcl-types:get-field message 'coverage)))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"coverage" coverage #m())))))

      ;; test_rerun_failures response
      ((or (== op #"test_rerun_failures") (== op 'test_rerun_failures))
       (let ((results (xrepl-ptcl-types:get-field-any message '(results test_results))))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"results" results #m())))))

      ;; generate_tests response
      ((or (== op #"generate_tests") (== op 'generate_tests))
       (let ((generated (xrepl-ptcl-types:get-field message 'generated)))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"generated" generated #m())))))

      ;; Unknown operation
      ('true
       (tuple 'error 'unknown-operation)))))

;;; Validation functions

(defun valid-request? (message)
  "Validate a testing operation request message.

  Args:
    message: The request message map

  Returns:
    true if valid, false otherwise"
  (let ((op (xrepl-ptcl-types:get-field message 'op)))
    (cond
      ;; test_run: no required fields beyond op
      ((or (== op #"test_run") (== op 'test_run))
       'true)

      ;; test_coverage: no required fields beyond op
      ((or (== op #"test_coverage") (== op 'test_coverage))
       'true)

      ;; test_rerun_failures: no required fields beyond op
      ((or (== op #"test_rerun_failures") (== op 'test_rerun_failures))
       'true)

      ;; generate_tests: requires namespace
      ((or (== op #"generate_tests") (== op 'generate_tests))
       (let ((namespace (xrepl-ptcl-types:get-field message 'namespace)))
         (not (== namespace 'undefined))))

      ;; Unknown or missing op
      ('true 'false))))

(defun valid-response? (message op)
  "Validate a testing operation response message.

  Args:
    message: The response message map
    op: The operation name

  Returns:
    true if valid, false otherwise"
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (cond
      ;; All responses require status
      ((== status 'undefined) 'false)

      ;; test_run: requires results
      ((or (== op #"test_run") (== op 'test_run))
       (let ((results (xrepl-ptcl-types:get-field-any message '(results test_results))))
         (not (== results 'undefined))))

      ;; test_coverage: requires coverage
      ((or (== op #"test_coverage") (== op 'test_coverage))
       (let ((coverage (xrepl-ptcl-types:get-field message 'coverage)))
         (not (== coverage 'undefined))))

      ;; test_rerun_failures: requires results
      ((or (== op #"test_rerun_failures") (== op 'test_rerun_failures))
       (let ((results (xrepl-ptcl-types:get-field-any message '(results test_results))))
         (not (== results 'undefined))))

      ;; generate_tests: requires generated
      ((or (== op #"generate_tests") (== op 'generate_tests))
       (let ((generated (xrepl-ptcl-types:get-field message 'generated)))
         (not (== generated 'undefined))))

      ;; Unknown operation
      ('true 'false))))

;;; Error handling

(defun error (type msg)
  "Build an error response.

  Args:
    type: Error type (atom)
    msg: Error message (string or binary)

  Returns:
    Error response map

  Example:
    (error 'missing-namespace \"Namespace is required\")"
  (maps:put #"status" #"error"
           (maps:put #"error-type" (xrepl-ptcl-types:ensure-binary type)
                    (maps:put #"error" (xrepl-ptcl-types:ensure-binary msg) #m()))))
