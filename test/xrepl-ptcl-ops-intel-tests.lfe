(defmodule xrepl-ptcl-ops-intel-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; complete tests

(deftest complete-request-minimal
  (let ((req (xrepl-ptcl-ops-intel:complete-request #m(prefix "map:"))))
    (is-equal #"complete" (maps:get #"op" req))
    (is-equal #"map:" (maps:get #"prefix" req))))

(deftest complete-request-with-cursor
  (let ((req (xrepl-ptcl-ops-intel:complete-request #m(prefix "map:" cursor 4))))
    (is-equal #"complete" (maps:get #"op" req))
    (is-equal #"map:" (maps:get #"prefix" req))
    (is-equal 4 (maps:get #"cursor" req))))

(deftest complete-request-with-position-and-code
  (let ((req (xrepl-ptcl-ops-intel:complete-request
              #m(prefix "map:" position 10 code "(defun foo () (map:))"))))
    (is-equal #"complete" (maps:get #"op" req))
    (is-equal 10 (maps:get #"position" req))
    (is-equal #"(defun foo () (map:))" (maps:get #"code" req))))

(deftest complete-response-has-both-field-names
  (let* ((candidates (list #m(#"text" #"map" #"type" #"function")))
         (resp (xrepl-ptcl-ops-intel:complete-response candidates)))
    (is-equal #"done" (maps:get #"status" resp))
    ;; Both field names should be present
    (is-equal candidates (maps:get #"candidates" resp))
    (is-equal candidates (maps:get #"completions" resp))))

(deftest complete-response-with-session
  (let* ((candidates (list #m(#"text" #"map")))
         (resp (xrepl-ptcl-ops-intel:complete-response candidates #m(session "s1"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"s1" (maps:get #"session" resp))
    ;; Both candidate field names should be present
    (is-equal candidates (maps:get #"candidates" resp))
    (is-equal candidates (maps:get #"completions" resp))))

;;; complete_context tests

(deftest complete-context-request-minimal
  (let ((req (xrepl-ptcl-ops-intel:complete-context-request
              #m(file "test.lfe" line 10 column 5))))
    (is-equal #"complete_context" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest complete-context-request-with-code
  (let ((req (xrepl-ptcl-ops-intel:complete-context-request
              #m(file "test.lfe" line 10 column 5 code "(defun foo ())"))))
    (is-equal #"complete_context" (maps:get #"op" req))
    (is-equal #"(defun foo ())" (maps:get #"code" req))))

(deftest complete-context-response-has-both-field-names
  (let* ((candidates (list #m(#"text" #"defun")))
         (context #m(#"type" #"toplevel"))
         (resp (xrepl-ptcl-ops-intel:complete-context-response candidates context)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal context (maps:get #"context" resp))
    ;; Both field names should be present
    (is-equal candidates (maps:get #"candidates" resp))
    (is-equal candidates (maps:get #"completions" resp))))

;;; signature / signature_help tests (operation name aliases)

(deftest signature-request-defaults-to-signature
  (let ((req (xrepl-ptcl-ops-intel:signature-request #m(symbol "map:get"))))
    (is-equal #"signature" (maps:get #"op" req))
    (is-equal #"map:get" (maps:get #"symbol" req))))

(deftest signature-request-with-signature-help-name
  (let ((req (xrepl-ptcl-ops-intel:signature-request
              #m(symbol "map:get" op_name signature_help))))
    (is-equal #"signature_help" (maps:get #"op" req))
    (is-equal #"map:get" (maps:get #"symbol" req))))

(deftest signature-request-with-position-info
  (let ((req (xrepl-ptcl-ops-intel:signature-request
              #m(file "test.lfe" line 10 column 5 position 42))))
    (is-equal #"signature" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))
    (is-equal 42 (maps:get #"position" req))))

(deftest signature-response-construction
  (let* ((sigs (list #m(#"label" #"(map:get key map)" #"params" (list "key" "map"))))
         (resp (xrepl-ptcl-ops-intel:signature-response sigs)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal sigs (maps:get #"signatures" resp))))

(deftest signature-response-with-session
  (let* ((sigs (list #m(#"label" #"(foo)")))
         (resp (xrepl-ptcl-ops-intel:signature-response sigs #m(session "s1"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"s1" (maps:get #"session" resp))))

;;; eldoc tests

(deftest eldoc-request-construction
  (let ((req (xrepl-ptcl-ops-intel:eldoc-request #m(symbol "map:get"))))
    (is-equal #"eldoc" (maps:get #"op" req))
    (is-equal #"map:get" (maps:get #"symbol" req))))

(deftest eldoc-request-with-session
  (let ((req (xrepl-ptcl-ops-intel:eldoc-request #m(symbol "map:get" session "s1"))))
    (is-equal #"eldoc" (maps:get #"op" req))
    (is-equal #"map:get" (maps:get #"symbol" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest eldoc-response-construction
  (let* ((info #m(#"signature" #"(map:get key map)" #"doc" #"Get value from map"))
         (resp (xrepl-ptcl-ops-intel:eldoc-response info)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal info (maps:get #"eldoc" resp))))

(deftest eldoc-response-with-session
  (let* ((info #m(#"signature" #"(foo)"))
         (resp (xrepl-ptcl-ops-intel:eldoc-response info #m(session "s1"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"s1" (maps:get #"session" resp))))

;;; eldoc_batch tests

(deftest eldoc-batch-request-construction
  (let* ((syms (list #"map:get" #"lists:map"))
         (req (xrepl-ptcl-ops-intel:eldoc-batch-request (maps:put 'symbols syms #m()))))
    (is-equal #"eldoc_batch" (maps:get #"op" req))
    (is-equal syms (maps:get #"symbols" req))))

(deftest eldoc-batch-request-with-session
  (let* ((syms (list #"map:get"))
         (req (xrepl-ptcl-ops-intel:eldoc-batch-request
               (maps:put 'session #"s1" (maps:put 'symbols syms #m())))))
    (is-equal #"eldoc_batch" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest eldoc-batch-response-construction
  (let* ((results (list #m(#"symbol" #"map:get" #"signature" #"(map:get key map)")))
         (resp (xrepl-ptcl-ops-intel:eldoc-batch-response results)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal results (maps:get #"results" resp))))

;;; type_info tests

(deftest type-info-request-construction
  (let ((req (xrepl-ptcl-ops-intel:type-info-request #m(symbol "map"))))
    (is-equal #"type_info" (maps:get #"op" req))
    (is-equal #"map" (maps:get #"symbol" req))))

(deftest type-info-request-with-session
  (let ((req (xrepl-ptcl-ops-intel:type-info-request #m(symbol "map" session "s1"))))
    (is-equal #"type_info" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest type-info-response-construction
  (let* ((info #m(#"type" #"map()" #"spec" #"map(any(), any())"))
         (resp (xrepl-ptcl-ops-intel:type-info-response info)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal info (maps:get #"type_info" resp))))

;;; format / format_code tests (operation name aliases)

(deftest format-request-defaults-to-format
  (let ((req (xrepl-ptcl-ops-intel:format-request #m(code "(defun foo())"))))
    (is-equal #"format" (maps:get #"op" req))
    (is-equal #"(defun foo())" (maps:get #"code" req))))

(deftest format-request-with-format-code-name
  (let ((req (xrepl-ptcl-ops-intel:format-request
              #m(code "(defun foo())" op_name format_code))))
    (is-equal #"format_code" (maps:get #"op" req))
    (is-equal #"(defun foo())" (maps:get #"code" req))))

(deftest format-request-with-options
  (let ((req (xrepl-ptcl-ops-intel:format-request
              #m(code "(defun foo())" options #m(#"indent" 2)))))
    (is-equal #"format" (maps:get #"op" req))
    (is-equal #"(defun foo())" (maps:get #"code" req))
    (is (is_map (maps:get #"options" req)))))

(deftest format-response-construction
  (let ((resp (xrepl-ptcl-ops-intel:format-response "(defun foo\n  ())")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"(defun foo\n  ())" (maps:get #"formatted" resp))))

;;; apropos tests

(deftest apropos-request-construction
  (let ((req (xrepl-ptcl-ops-intel:apropos-request #m(query "map"))))
    (is-equal #"apropos" (maps:get #"op" req))
    (is-equal #"map" (maps:get #"query" req))))

(deftest apropos-request-with-session
  (let ((req (xrepl-ptcl-ops-intel:apropos-request #m(query "map" session "s1"))))
    (is-equal #"apropos" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest apropos-response-construction
  (let* ((results (list #m(#"name" #"map:get" #"type" #"function")))
         (resp (xrepl-ptcl-ops-intel:apropos-response results)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal results (maps:get #"results" resp))))

;;; indent_info tests

(deftest indent-info-request-construction
  (let ((req (xrepl-ptcl-ops-intel:indent-info-request #m(line 10))))
    (is-equal #"indent_info" (maps:get #"op" req))
    (is-equal 10 (maps:get #"line" req))))

(deftest indent-info-request-with-session
  (let ((req (xrepl-ptcl-ops-intel:indent-info-request #m(line 10 session "s1"))))
    (is-equal #"indent_info" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest indent-info-response-construction
  (let* ((info #m(#"indent" 2 #"method" #"defun"))
         (resp (xrepl-ptcl-ops-intel:indent-info-response info)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal info (maps:get #"indent_info" resp))))

;;; buffer_analysis tests

(deftest buffer-analysis-request-minimal
  (let ((req (xrepl-ptcl-ops-intel:buffer-analysis-request #m(code "(defun foo ())"))))
    (is-equal #"buffer_analysis" (maps:get #"op" req))
    (is-equal #"(defun foo ())" (maps:get #"code" req))))

(deftest buffer-analysis-request-with-file
  (let ((req (xrepl-ptcl-ops-intel:buffer-analysis-request
              #m(code "(defun foo ())" file "test.lfe"))))
    (is-equal #"buffer_analysis" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))))

(deftest buffer-analysis-request-with-session
  (let ((req (xrepl-ptcl-ops-intel:buffer-analysis-request
              #m(code "(defun foo ())" session "s1"))))
    (is-equal #"buffer_analysis" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest buffer-analysis-response-construction
  (let* ((analysis #m(#"warnings" (list) #"errors" (list) #"functions" 1))
         (resp (xrepl-ptcl-ops-intel:buffer-analysis-response analysis)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal analysis (maps:get #"analysis" resp))))

;;; highlight_regions tests

(deftest highlight-regions-request-construction
  (let ((req (xrepl-ptcl-ops-intel:highlight-regions-request #m(code "(defun foo ())"))))
    (is-equal #"highlight_regions" (maps:get #"op" req))
    (is-equal #"(defun foo ())" (maps:get #"code" req))))

(deftest highlight-regions-request-with-session
  (let ((req (xrepl-ptcl-ops-intel:highlight-regions-request
              #m(code "(defun foo ())" session "s1"))))
    (is-equal #"highlight_regions" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest highlight-regions-response-construction
  (let* ((regions (list #m(#"start" 0 #"end" 5 #"type" #"keyword")))
         (resp (xrepl-ptcl-ops-intel:highlight-regions-response regions)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal regions (maps:get #"regions" resp))))

;;; Parsing tests

(deftest parse-complete-request
  (let ((msg #m(#"op" #"complete" #"prefix" #"map:")))
    (case (xrepl-ptcl-ops-intel:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"complete" (maps:get #"op" parsed))
       (is-equal #"map:" (maps:get #"prefix" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-complete-request-missing-prefix
  (let ((msg #m(#"op" #"complete")))
    (case (xrepl-ptcl-ops-intel:parse-request msg)
      (`#(error missing-prefix)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-signature-request
  (let ((msg #m(#"op" #"signature")))
    (case (xrepl-ptcl-ops-intel:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"signature" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-signature-help-request
  (let ((msg #m(#"op" #"signature_help")))
    (case (xrepl-ptcl-ops-intel:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"signature_help" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-format-request
  (let ((msg #m(#"op" #"format")))
    (case (xrepl-ptcl-ops-intel:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"format" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-format-code-request
  (let ((msg #m(#"op" #"format_code")))
    (case (xrepl-ptcl-ops-intel:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"format_code" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-eldoc-request
  (let ((msg #m(#"op" #"eldoc")))
    (case (xrepl-ptcl-ops-intel:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"eldoc" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-complete-response
  (let* ((candidates (list #m(#"text" #"map")))
         (msg (maps:put #"status" #"done"
                       (maps:put #"candidates" candidates #m()))))
    (case (xrepl-ptcl-ops-intel:parse-response #"complete" msg)
      (`#(ok ,result)
       (is-equal candidates (maps:get #"candidates" result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-request-checks
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"complete" #"prefix" #"foo")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"complete_context")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"signature")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"signature_help")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"eldoc")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"eldoc_batch")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"type_info")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"format")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"format_code")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"apropos")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"indent_info")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"buffer_analysis")))
  (is (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"highlight_regions")))
  (is-not (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"unknown")))
  (is-not (xrepl-ptcl-ops-intel:valid-request? #m(#"op" #"complete"))))  ;; missing prefix

(deftest valid-response-checks
  (is (xrepl-ptcl-ops-intel:valid-response? #"complete" #m(#"status" #"done")))
  (is (xrepl-ptcl-ops-intel:valid-response? #"signature" #m(#"status" #"done")))
  (is (xrepl-ptcl-ops-intel:valid-response? #"eldoc" #m(#"status" #"error")))
  (is-not (xrepl-ptcl-ops-intel:valid-response? #"complete" #m(#"status" #"invalid"))))

;;; Round-trip tests

(deftest complete-round-trip
  (let* ((req (xrepl-ptcl-ops-intel:complete-request #m(prefix "map:" cursor 4)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"complete" (maps:get #"op" decoded))
    (is-equal #"map:" (maps:get #"prefix" decoded))
    (is-equal 4 (maps:get #"cursor" decoded))
    (is (xrepl-ptcl-ops-intel:valid-request? decoded))))

(deftest complete-response-round-trip
  (let* ((candidates (list #m(#"text" #"map:get" #"type" #"function")))
         (resp (xrepl-ptcl-ops-intel:complete-response candidates #m(session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    ;; Both field names should survive round-trip
    (is-equal candidates (maps:get #"candidates" decoded))
    (is-equal candidates (maps:get #"completions" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))))

(deftest signature-request-round-trip
  (let* ((req (xrepl-ptcl-ops-intel:signature-request
              #m(symbol "map:get" op_name signature_help)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"signature_help" (maps:get #"op" decoded))
    (is-equal #"map:get" (maps:get #"symbol" decoded))
    (is (xrepl-ptcl-ops-intel:valid-request? decoded))))

(deftest signature-response-round-trip
  (let* ((params (list #"key" #"map"))
         (sig-map (maps:put #"label" #"(map:get key map)"
                           (maps:put #"params" params #m())))
         (sigs (list sig-map))
         (resp (xrepl-ptcl-ops-intel:signature-response sigs))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal sigs (maps:get #"signatures" decoded))))

(deftest format-request-round-trip
  (let* ((req (xrepl-ptcl-ops-intel:format-request
              #m(code "(defun foo())" op_name format_code)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"format_code" (maps:get #"op" decoded))
    (is-equal #"(defun foo())" (maps:get #"code" decoded))
    (is (xrepl-ptcl-ops-intel:valid-request? decoded))))

(deftest eldoc-batch-round-trip
  (let* ((syms (list #"map:get" #"lists:map"))
         (req (xrepl-ptcl-ops-intel:eldoc-batch-request
               (maps:put 'session #"s1" (maps:put 'symbols syms #m()))))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"eldoc_batch" (maps:get #"op" decoded))
    (is-equal syms (maps:get #"symbols" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-intel:valid-request? decoded))))

(deftest buffer-analysis-round-trip
  (let* ((req (xrepl-ptcl-ops-intel:buffer-analysis-request
              #m(code "(defun foo ())" file "test.lfe" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"buffer_analysis" (maps:get #"op" decoded))
    (is-equal #"(defun foo ())" (maps:get #"code" decoded))
    (is-equal #"test.lfe" (maps:get #"file" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-intel:valid-request? decoded))))
