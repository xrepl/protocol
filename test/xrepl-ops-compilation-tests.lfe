(defmodule xrepl-ops-compilation-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; compile_file tests

(deftest compile-file-request-minimal
  (let ((req (xrepl-ops-compilation:compile-file-request #m(file "src/foo.lfe"))))
    (is-equal #"compile_file" (maps:get #"op" req))
    (is-equal #"src/foo.lfe" (maps:get #"file" req))
    (is-equal #"src/foo.lfe" (maps:get #"path" req))))

(deftest compile-file-request-with-path-alias
  (let ((req (xrepl-ops-compilation:compile-file-request #m(path "test.lfe"))))
    (is-equal #"compile_file" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal #"test.lfe" (maps:get #"path" req))))

(deftest compile-file-request-with-options
  (let* ((opts-map (maps:put #"warnings" 'true #m()))
         (req (xrepl-ops-compilation:compile-file-request
               `#m(file "foo.lfe" options ,opts-map))))
    (is-equal #"compile_file" (maps:get #"op" req))
    (is-equal opts-map (maps:get #"options" req))
    (is-equal opts-map (maps:get #"compile_options" req))))

(deftest compile-file-request-with-session
  (let ((req (xrepl-ops-compilation:compile-file-request
              #m(file "foo.lfe" session "s1"))))
    (is-equal #"compile_file" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest compile-file-request-missing-file
  (let ((result (xrepl-ops-compilation:compile-file-request #m())))
    (case result
      (`#(error missing-file)
       (is 'true))
      (_
       (error "Expected error for missing file")))))

(deftest compile-file-response-construction
  (let* ((result (maps:put #"success" 'true
                          (maps:put #"warnings" (list) #m())))
         (resp (xrepl-ops-compilation:compile-file-response result)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal result (maps:get #"result" resp))))

;;; compile_project tests

(deftest compile-project-request-minimal
  (let ((req (xrepl-ops-compilation:compile-project-request #m())))
    (is-equal #"compile_project" (maps:get #"op" req))))

(deftest compile-project-request-with-path
  (let ((req (xrepl-ops-compilation:compile-project-request
              #m(path "/path/to/project"))))
    (is-equal #"compile_project" (maps:get #"op" req))
    (is-equal #"/path/to/project" (maps:get #"path" req))))

(deftest compile-project-request-with-clean
  (let ((req (xrepl-ops-compilation:compile-project-request
              `#m(clean ,'true))))
    (is-equal #"compile_project" (maps:get #"op" req))
    (is-equal 'true (maps:get #"clean" req))))

(deftest compile-project-request-with-profile
  (let ((req (xrepl-ops-compilation:compile-project-request
              #m(profile "prod"))))
    (is-equal #"compile_project" (maps:get #"op" req))
    (is-equal #"prod" (maps:get #"profile" req))
    (is-equal #"prod" (maps:get #"build_profile" req))))

(deftest compile-project-request-with-options
  (let* ((opts-map (maps:put #"verbose" 'true #m()))
         (req (xrepl-ops-compilation:compile-project-request
               `#m(options ,opts-map))))
    (is-equal #"compile_project" (maps:get #"op" req))
    (is-equal opts-map (maps:get #"options" req))))

(deftest compile-project-request-with-session
  (let ((req (xrepl-ops-compilation:compile-project-request #m(session "s1"))))
    (is-equal #"compile_project" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest compile-project-response-construction
  (let* ((result (maps:put #"success" 'true
                          (maps:put #"files_compiled" 15 #m())))
         (resp (xrepl-ops-compilation:compile-project-response result)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal result (maps:get #"result" resp))))

;;; lint tests

(deftest lint-request-minimal
  (let ((req (xrepl-ops-compilation:lint-request #m())))
    (is-equal #"lint" (maps:get #"op" req))))

(deftest lint-request-with-file
  (let ((req (xrepl-ops-compilation:lint-request #m(file "src/foo.lfe"))))
    (is-equal #"lint" (maps:get #"op" req))
    (is-equal #"src/foo.lfe" (maps:get #"file" req))
    (is-equal #"src/foo.lfe" (maps:get #"path" req))))

(deftest lint-request-with-code
  (let ((req (xrepl-ops-compilation:lint-request #m(code "(defun foo () 42)"))))
    (is-equal #"lint" (maps:get #"op" req))
    (is-equal #"(defun foo () 42)" (maps:get #"code" req))))

(deftest lint-request-with-linters
  (let ((req (xrepl-ops-compilation:lint-request
              `#m(file "foo.lfe" linters ,(list "syntax" "style")))))
    (is-equal #"lint" (maps:get #"op" req))
    (is-equal (list #"syntax" #"style") (maps:get #"linters" req))))

(deftest lint-request-with-session
  (let ((req (xrepl-ops-compilation:lint-request #m(file "foo.lfe" session "s1"))))
    (is-equal #"lint" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest lint-response-construction
  (let* ((issues (list (maps:put #"severity" #"warning"
                                (maps:put #"message" #"Unused variable" #m()))))
         (resp (xrepl-ops-compilation:lint-response issues)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal issues (maps:get #"issues" resp))))

;;; dependencies tests

(deftest dependencies-request-minimal
  (let ((req (xrepl-ops-compilation:dependencies-request #m())))
    (is-equal #"dependencies" (maps:get #"op" req))))

(deftest dependencies-request-with-path
  (let ((req (xrepl-ops-compilation:dependencies-request
              #m(path "/path/to/project"))))
    (is-equal #"dependencies" (maps:get #"op" req))
    (is-equal #"/path/to/project" (maps:get #"path" req))))

(deftest dependencies-request-with-type
  (let ((req (xrepl-ops-compilation:dependencies-request #m(type "direct"))))
    (is-equal #"dependencies" (maps:get #"op" req))
    (is-equal #"direct" (maps:get #"type" req))))

(deftest dependencies-request-with-session
  (let ((req (xrepl-ops-compilation:dependencies-request #m(session "s1"))))
    (is-equal #"dependencies" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest dependencies-response-construction
  (let* ((deps (list (maps:put #"name" #"lfe"
                              (maps:put #"version" #"2.1.1" #m()))))
         (resp (xrepl-ops-compilation:dependencies-response deps)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal deps (maps:get #"dependencies" resp))))

;;; build tests

(deftest build-request-minimal
  (let ((req (xrepl-ops-compilation:build-request #m())))
    (is-equal #"build" (maps:get #"op" req))))

(deftest build-request-with-task
  (let ((req (xrepl-ops-compilation:build-request #m(task "compile"))))
    (is-equal #"build" (maps:get #"op" req))
    (is-equal #"compile" (maps:get #"task" req))
    (is-equal #"compile" (maps:get #"target" req))))

(deftest build-request-with-target-alias
  (let ((req (xrepl-ops-compilation:build-request #m(target "release"))))
    (is-equal #"build" (maps:get #"op" req))
    (is-equal #"release" (maps:get #"task" req))
    (is-equal #"release" (maps:get #"target" req))))

(deftest build-request-with-args
  (let ((req (xrepl-ops-compilation:build-request
              `#m(task "test" args ,(list "--verbose")))))
    (is-equal #"build" (maps:get #"op" req))
    (is-equal (list #"--verbose") (maps:get #"args" req))))

(deftest build-request-with-clean
  (let ((req (xrepl-ops-compilation:build-request
              `#m(task "compile" clean ,'true))))
    (is-equal #"build" (maps:get #"op" req))
    (is-equal 'true (maps:get #"clean" req))))

(deftest build-request-with-session
  (let ((req (xrepl-ops-compilation:build-request #m(task "build" session "s1"))))
    (is-equal #"build" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest build-response-construction
  (let* ((result (maps:put #"success" 'true
                          (maps:put #"duration" 5.2 #m())))
         (resp (xrepl-ops-compilation:build-response result)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal result (maps:get #"result" resp))))

;;; Parsing tests

(deftest parse-compile-file-request
  (let ((msg #m(#"op" #"compile_file" #"file" #"src/foo.lfe")))
    (case (xrepl-ops-compilation:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"compile_file" (maps:get #"op" parsed))
       (is-equal #"src/foo.lfe" (maps:get #"file" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-compile-file-request-with-path-alias
  (let ((msg #m(#"op" #"compile_file" #"path" #"test.lfe")))
    (case (xrepl-ops-compilation:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"compile_file" (maps:get #"op" parsed))
       (is-equal #"test.lfe" (maps:get #"file" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-compile-file-request-missing-file
  (let ((msg #m(#"op" #"compile_file")))
    (case (xrepl-ops-compilation:parse-request msg)
      (`#(error missing-file)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-compile-project-request
  (let ((msg #m(#"op" #"compile_project")))
    (case (xrepl-ops-compilation:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"compile_project" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-compile-project-request-with-profile-alias
  (let ((msg #m(#"op" #"compile_project" #"build_profile" #"prod")))
    (case (xrepl-ops-compilation:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"compile_project" (maps:get #"op" parsed))
       (is-equal #"prod" (maps:get #"profile" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-lint-request
  (let ((msg #m(#"op" #"lint" #"file" #"foo.lfe")))
    (case (xrepl-ops-compilation:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"lint" (maps:get #"op" parsed))
       (is-equal #"foo.lfe" (maps:get #"file" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-dependencies-request
  (let ((msg #m(#"op" #"dependencies")))
    (case (xrepl-ops-compilation:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"dependencies" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-build-request
  (let ((msg #m(#"op" #"build" #"task" #"compile")))
    (case (xrepl-ops-compilation:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"build" (maps:get #"op" parsed))
       (is-equal #"compile" (maps:get #"task" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-build-request-with-target-alias
  (let ((msg #m(#"op" #"build" #"target" #"release")))
    (case (xrepl-ops-compilation:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"build" (maps:get #"op" parsed))
       (is-equal #"release" (maps:get #"task" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-unknown-operation
  (let ((msg #m(#"op" #"unknown_op")))
    (case (xrepl-ops-compilation:parse-request msg)
      (`#(error unknown-operation)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Response parsing tests

(deftest parse-compile-file-response
  (let* ((result (maps:put #"success" 'true #m()))
         (msg (maps:put #"status" #"done" (maps:put #"result" result #m()))))
    (case (xrepl-ops-compilation:parse-response msg 'compile_file)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal result (maps:get #"result" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-compile-project-response
  (let* ((result (maps:put #"files_compiled" 10 #m()))
         (msg (maps:put #"status" #"done" (maps:put #"result" result #m()))))
    (case (xrepl-ops-compilation:parse-response msg 'compile_project)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal result (maps:get #"result" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-lint-response
  (let* ((issues (list))
         (msg (maps:put #"status" #"done" (maps:put #"issues" issues #m()))))
    (case (xrepl-ops-compilation:parse-response msg 'lint)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal issues (maps:get #"issues" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-dependencies-response
  (let* ((deps (list))
         (msg (maps:put #"status" #"done" (maps:put #"dependencies" deps #m()))))
    (case (xrepl-ops-compilation:parse-response msg 'dependencies)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal deps (maps:get #"dependencies" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-build-response
  (let* ((result (maps:put #"success" 'true #m()))
         (msg (maps:put #"status" #"done" (maps:put #"result" result #m()))))
    (case (xrepl-ops-compilation:parse-response msg 'build)
      (`#(ok ,parsed)
       (is-equal #"done" (maps:get #"status" parsed))
       (is-equal result (maps:get #"result" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-compile-file-request
  (let ((req (xrepl-ops-compilation:compile-file-request #m(file "foo.lfe"))))
    (is (xrepl-ops-compilation:valid-request? req))))

(deftest invalid-compile-file-request-missing-file
  (let ((req #m(#"op" #"compile_file")))
    (is-not (xrepl-ops-compilation:valid-request? req))))

(deftest valid-compile-project-request
  (let ((req (xrepl-ops-compilation:compile-project-request #m())))
    (is (xrepl-ops-compilation:valid-request? req))))

(deftest valid-lint-request
  (let ((req (xrepl-ops-compilation:lint-request #m())))
    (is (xrepl-ops-compilation:valid-request? req))))

(deftest valid-dependencies-request
  (let ((req (xrepl-ops-compilation:dependencies-request #m())))
    (is (xrepl-ops-compilation:valid-request? req))))

(deftest valid-build-request
  (let ((req (xrepl-ops-compilation:build-request #m())))
    (is (xrepl-ops-compilation:valid-request? req))))

(deftest invalid-request-missing-op
  (let ((req #m(#"file" #"foo.lfe")))
    (is-not (xrepl-ops-compilation:valid-request? req))))

(deftest invalid-request-unknown-op
  (let ((req #m(#"op" #"unknown_operation")))
    (is-not (xrepl-ops-compilation:valid-request? req))))

;;; Response validation tests

(deftest valid-compile-file-response
  (let* ((result (maps:put #"success" 'true #m()))
         (resp (xrepl-ops-compilation:compile-file-response result)))
    (is (xrepl-ops-compilation:valid-response? resp 'compile_file))))

(deftest invalid-compile-file-response-missing-result
  (let ((resp #m(#"status" #"done")))
    (is-not (xrepl-ops-compilation:valid-response? resp 'compile_file))))

(deftest valid-compile-project-response
  (let* ((result (maps:put #"files_compiled" 10 #m()))
         (resp (xrepl-ops-compilation:compile-project-response result)))
    (is (xrepl-ops-compilation:valid-response? resp 'compile_project))))

(deftest valid-lint-response
  (let ((resp (xrepl-ops-compilation:lint-response (list))))
    (is (xrepl-ops-compilation:valid-response? resp 'lint))))

(deftest invalid-lint-response-missing-issues
  (let ((resp #m(#"status" #"done")))
    (is-not (xrepl-ops-compilation:valid-response? resp 'lint))))

(deftest valid-dependencies-response
  (let ((resp (xrepl-ops-compilation:dependencies-response (list))))
    (is (xrepl-ops-compilation:valid-response? resp 'dependencies))))

(deftest invalid-dependencies-response-missing-deps
  (let ((resp #m(#"status" #"done")))
    (is-not (xrepl-ops-compilation:valid-response? resp 'dependencies))))

(deftest valid-build-response
  (let* ((result (maps:put #"success" 'true #m()))
         (resp (xrepl-ops-compilation:build-response result)))
    (is (xrepl-ops-compilation:valid-response? resp 'build))))

(deftest invalid-build-response-missing-result
  (let ((resp #m(#"status" #"done")))
    (is-not (xrepl-ops-compilation:valid-response? resp 'build))))

(deftest invalid-response-missing-status
  (let* ((result (maps:put #"success" 'true #m()))
         (resp #m(#"result" result)))
    (is-not (xrepl-ops-compilation:valid-response? resp 'compile_file))))

;;; Round-trip MessagePack tests

(deftest roundtrip-compile-file-request
  (let* ((req (xrepl-ops-compilation:compile-file-request
               #m(file "src/foo.lfe")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"compile_file" (maps:get #"op" decoded))
    (is-equal #"src/foo.lfe" (maps:get #"file" decoded))
    (is-equal #"src/foo.lfe" (maps:get #"path" decoded))))

(deftest roundtrip-compile-file-response
  (let* ((result (maps:put #"success" 'true
                          (maps:put #"warnings" (list) #m())))
         (resp (xrepl-ops-compilation:compile-file-response result))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal result (maps:get #"result" decoded))))

(deftest roundtrip-compile-project-request
  (let* ((req (xrepl-ops-compilation:compile-project-request
               #m(path "/project" profile "prod")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"compile_project" (maps:get #"op" decoded))
    (is-equal #"/project" (maps:get #"path" decoded))
    (is-equal #"prod" (maps:get #"profile" decoded))
    (is-equal #"prod" (maps:get #"build_profile" decoded))))

(deftest roundtrip-compile-project-response
  (let* ((result (maps:put #"success" 'true
                          (maps:put #"files_compiled" 15 #m())))
         (resp (xrepl-ops-compilation:compile-project-response result))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal result (maps:get #"result" decoded))))

(deftest roundtrip-lint-request
  (let* ((req (xrepl-ops-compilation:lint-request
               #m(file "foo.lfe")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"lint" (maps:get #"op" decoded))
    (is-equal #"foo.lfe" (maps:get #"file" decoded))
    (is-equal #"foo.lfe" (maps:get #"path" decoded))))

(deftest roundtrip-lint-response
  (let* ((issues (list (maps:put #"severity" #"warning" #m())))
         (resp (xrepl-ops-compilation:lint-response issues))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal issues (maps:get #"issues" decoded))))

(deftest roundtrip-dependencies-request
  (let* ((req (xrepl-ops-compilation:dependencies-request
               #m(type "direct")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"dependencies" (maps:get #"op" decoded))
    (is-equal #"direct" (maps:get #"type" decoded))))

(deftest roundtrip-dependencies-response
  (let* ((deps (list (maps:put #"name" #"lfe" #m())))
         (resp (xrepl-ops-compilation:dependencies-response deps))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal deps (maps:get #"dependencies" decoded))))

(deftest roundtrip-build-request
  (let* ((req (xrepl-ops-compilation:build-request
               #m(task "compile")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"build" (maps:get #"op" decoded))
    (is-equal #"compile" (maps:get #"task" decoded))
    (is-equal #"compile" (maps:get #"target" decoded))))

(deftest roundtrip-build-response
  (let* ((result (maps:put #"success" 'true
                          (maps:put #"duration" 5.2 #m())))
         (resp (xrepl-ops-compilation:build-response result))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal result (maps:get #"result" decoded))))

;;; Error tests

(deftest error-construction
  (let ((err (xrepl-ops-compilation:error 'compilation-failed "Compilation failed")))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"compilation-failed" (maps:get #"error-type" err))
    (is-equal #"Compilation failed" (maps:get #"error" err))))
