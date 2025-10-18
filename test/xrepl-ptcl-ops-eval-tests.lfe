(defmodule xrepl-ptcl-ops-eval-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; eval operation tests

(deftest eval-request-minimal
  (let ((req (xrepl-ptcl-ops-eval:eval-request #m(code "(+ 1 2)"))))
    (is-equal #"eval" (maps:get #"op" req))
    (is-equal #"(+ 1 2)" (maps:get #"code" req))))

(deftest eval-request-with-session
  (let ((req (xrepl-ptcl-ops-eval:eval-request #m(code "(+ 1 2)" session "abc123"))))
    (is-equal #"eval" (maps:get #"op" req))
    (is-equal #"(+ 1 2)" (maps:get #"code" req))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest eval-request-with-location
  (let ((req (xrepl-ptcl-ops-eval:eval-request
               #m(code "(+ 1 2)" file "test.lfe" line 10 column 5))))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest eval-response-simple
  (let ((resp (xrepl-ptcl-ops-eval:eval-response "42")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"42" (maps:get #"value" resp))))

(deftest eval-response-with-session-and-ns
  (let ((resp (xrepl-ptcl-ops-eval:eval-response "42" #m(session "abc" ns "user"))))
    (is-equal #"42" (maps:get #"value" resp))
    (is-equal #"abc" (maps:get #"session" resp))
    ;; Both ns and namespace should be present (aliases)
    (is-equal #"user" (maps:get #"ns" resp))
    (is-equal #"user" (maps:get #"namespace" resp))))

(deftest eval-action-response-switch
  (let ((resp (xrepl-ptcl-ops-eval:eval-action-response 'switch #m(session "new-id"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"switch" (maps:get #"action" resp))
    (is-equal #"new-id" (maps:get #"session" resp))))

;;; eval_multiple operation tests

(deftest eval-multiple-request-construction
  (let* ((forms (list "(+ 1 2)" "(* 3 4)"))
         (opts (maps:put 'forms forms #m()))
         (req (xrepl-ptcl-ops-eval:eval-multiple-request opts)))
    (is-equal #"eval_multiple" (maps:get #"op" req))
    (is-equal forms (maps:get #"forms" req))))

(deftest eval-multiple-response-construction
  (let* ((results '(#m(value "3" status "ok")
                    #m(value "12" status "ok")))
         (resp (xrepl-ptcl-ops-eval:eval-multiple-response results)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal results (maps:get #"results" resp))))

;;; eval_at_point operation tests

(deftest eval-at-point-request-construction
  (let ((req (xrepl-ptcl-ops-eval:eval-at-point-request
               #m(code "(+ 1 2)" file "test.lfe" line 10 column 5))))
    (is-equal #"eval_at_point" (maps:get #"op" req))
    (is-equal #"(+ 1 2)" (maps:get #"code" req))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest eval-at-point-with-context
  (let ((req (xrepl-ptcl-ops-eval:eval-at-point-request
               #m(code "(+ 1 2)"
                  file "test.lfe"
                  line 10
                  column 5
                  context #m(buffer_contents "...")))))
    (is (is_map (maps:get #"context" req)))))

;;; stream_eval operation tests

(deftest stream-eval-request-construction
  (let ((req (xrepl-ptcl-ops-eval:stream-eval-request #m(code "(dotimes (i 10) (print i))"))))
    (is-equal #"stream_eval" (maps:get #"op" req))))

(deftest stream-eval-request-alias
  (let ((req (xrepl-ptcl-ops-eval:stream-eval-request
               #m(code "(print 'hi')" op_name eval_stream))))
    (is-equal #"eval_stream" (maps:get #"op" req))))

(deftest stream-eval-intermediate-response
  (let ((resp (xrepl-ptcl-ops-eval:stream-eval-intermediate "output line" 'stdout)))
    (is-equal #"streaming" (maps:get #"status" resp))
    (is-equal #"output line" (maps:get #"output" resp))
    (is-equal #"stdout" (maps:get #"stream" resp))))

(deftest stream-eval-final-response
  (let ((resp (xrepl-ptcl-ops-eval:stream-eval-final "42")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"42" (maps:get #"value" resp))))

;;; interrupt operation tests

(deftest interrupt-request-construction
  (let ((req (xrepl-ptcl-ops-eval:interrupt-request #m())))
    (is-equal #"interrupt" (maps:get #"op" req))))

(deftest interrupt-request-with-session
  (let ((req (xrepl-ptcl-ops-eval:interrupt-request #m(session "abc123"))))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest interrupt-response-success
  (let ((resp (xrepl-ptcl-ops-eval:interrupt-response 'true #m())))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 'true (maps:get #"interrupted" resp))))

(deftest interrupt-response-with-message
  (let ((resp (xrepl-ptcl-ops-eval:interrupt-response 'true #m(message "Interrupted"))))
    (is-equal #"Interrupted" (maps:get #"message" resp))))

;;; cancel operation tests

(deftest cancel-request-construction
  (let ((req (xrepl-ptcl-ops-eval:cancel-request #m(cancel_id "req-123"))))
    (is-equal #"cancel" (maps:get #"op" req))
    (is-equal #"req-123" (maps:get #"cancel_id" req))))

(deftest cancel-response-construction
  (let ((resp (xrepl-ptcl-ops-eval:cancel-response 'true "req-123")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 'true (maps:get #"cancelled" resp))
    (is-equal #"req-123" (maps:get #"target_id" resp))))

;;; load_file operation tests

(deftest load-file-request-minimal
  (let ((req (xrepl-ptcl-ops-eval:load-file-request #m(file "test.lfe"))))
    (is-equal #"load_file" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))))

(deftest load-file-request-with-contents
  (let ((req (xrepl-ptcl-ops-eval:load-file-request
               #m(file "test.lfe" file_contents "(defun foo () 42)"))))
    (is-equal #"(defun foo () 42)" (maps:get #"file_contents" req))))

(deftest load-file-response-simple
  (let ((resp (xrepl-ptcl-ops-eval:load-file-response "ok")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"ok" (maps:get #"value" resp))))

(deftest load-file-response-with-warnings
  (let* ((warning-list (list #m(line 5 message "unused variable")))
         (opts (maps:put 'warnings warning-list #m()))
         (resp (xrepl-ptcl-ops-eval:load-file-response "ok" opts)))
    (is-equal warning-list (maps:get #"warnings" resp))))

;;; Parsing tests

(deftest parse-eval-request
  (let ((msg #m(#"op" #"eval" #"code" #"(+ 1 2)")))
    (case (xrepl-ptcl-ops-eval:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"eval" (maps:get #"op" parsed))
       (is-equal #"(+ 1 2)" (maps:get #"code" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-interrupt-request
  (let ((msg #m(#"op" #"interrupt" #"session" #"abc")))
    (case (xrepl-ptcl-ops-eval:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"interrupt" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-eval-response-value
  (let ((msg #m(#"status" #"done" #"value" #"42")))
    (case (xrepl-ptcl-ops-eval:parse-response #"eval" msg)
      (`#(ok ,result)
       (is-equal #"42" (maps:get #"value" result)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-eval-response-action
  (let ((msg #m(#"status" #"done" #"action" #"switch" #"session" #"new")))
    (case (xrepl-ptcl-ops-eval:parse-response #"eval" msg)
      (`#(ok ,result)
       (is-equal #"switch" (maps:get #"action" result)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-streaming-response
  (let ((msg #m(#"status" #"streaming" #"output" #"line" #"stream" #"stdout")))
    (case (xrepl-ptcl-ops-eval:parse-response #"stream_eval" msg)
      (`#(ok ,result)
       (is-equal #"streaming" (maps:get #"status" result))
       (is-equal #"line" (maps:get #"output" result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-request-checks
  (is (xrepl-ptcl-ops-eval:valid-request? #m(#"op" #"eval" #"code" #"(+ 1 2)")))
  (is (xrepl-ptcl-ops-eval:valid-request? #m(#"op" #"interrupt")))
  (is (xrepl-ptcl-ops-eval:valid-request? #m(#"op" #"load_file" #"file" #"test.lfe")))
  (is-not (xrepl-ptcl-ops-eval:valid-request? #m(#"op" #"eval"))))  ;; missing code

(deftest valid-response-checks
  (is (xrepl-ptcl-ops-eval:valid-response? #"eval" #m(#"status" #"done" #"value" #"42")))
  (is (xrepl-ptcl-ops-eval:valid-response? #"stream_eval" #m(#"status" #"streaming")))
  (is (xrepl-ptcl-ops-eval:valid-response? #"interrupt" #m(#"status" #"done")))
  (is-not (xrepl-ptcl-ops-eval:valid-response? #"eval" #m(#"status" #"invalid"))))

;;; Round-trip tests

(deftest eval-request-round-trip
  (let* ((req (xrepl-ptcl-ops-eval:eval-request #m(code "(+ 1 2)" session "test")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"eval" (maps:get #"op" decoded))
    (is-equal #"(+ 1 2)" (maps:get #"code" decoded))
    (is-equal #"test" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-eval:valid-request? decoded))))

(deftest load-file-request-round-trip
  (let* ((req (xrepl-ptcl-ops-eval:load-file-request #m(file "test.lfe")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"load_file" (maps:get #"op" decoded))
    (is (xrepl-ptcl-ops-eval:valid-request? decoded))))

(deftest eval-response-round-trip-with-aliases
  (let* ((resp (xrepl-ptcl-ops-eval:eval-response "42" #m(session "test" ns "user")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    ;; Both aliases should be present
    (is-equal #"user" (maps:get #"ns" decoded))
    (is-equal #"user" (maps:get #"namespace" decoded))
    (is-equal #"test" (maps:get #"session" decoded))))
