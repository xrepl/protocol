(defmodule xrepl-ops-advanced-tests
  "Tests for advanced operation protocol messages."
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; ==========================================
;;; macroexpand operation tests
;;; ==========================================

(deftest macroexpand-request-minimal
  (let ((req (xrepl-ops-advanced:macroexpand-request #m(form "(when true (print 1))"))))
    (is-equal #"macroexpand" (maps:get #"op" req))
    (is-equal #"(when true (print 1))" (maps:get #"form" req))))

(deftest macroexpand-request-with-expand-once
  (let ((req (xrepl-ops-advanced:macroexpand-request #m(form "(when true 1)" expand_once true))))
    (is-equal #"macroexpand" (maps:get #"op" req))
    (is-equal 'true (maps:get #"expand_once" req))))

(deftest macroexpand-request-with-session
  (let ((req (xrepl-ops-advanced:macroexpand-request #m(form "(when)" session "sess-123"))))
    (is-equal #"macroexpand" (maps:get #"op" req))
    (is-equal #"sess-123" (maps:get #"session" req))))

(deftest macroexpand-request-missing-form
  (let ((result (xrepl-ops-advanced:macroexpand-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-form (element 2 result))))

(deftest macroexpand-response-construction
  (let ((resp (xrepl-ops-advanced:macroexpand-response #m(expansion #"(progn (print 1))"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"(progn (print 1))" (maps:get #"expansion" resp))))

;;; ==========================================
;;; macroexpand_all operation tests
;;; ==========================================

(deftest macroexpand-all-request-minimal
  (let ((req (xrepl-ops-advanced:macroexpand-all-request #m(form "(when (unless))"))))
    (is-equal #"macroexpand_all" (maps:get #"op" req))
    (is-equal #"(when (unless))" (maps:get #"form" req))))

(deftest macroexpand-all-request-with-session
  (let ((req (xrepl-ops-advanced:macroexpand-all-request #m(form "(test)" session "s1"))))
    (is-equal #"macroexpand_all" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest macroexpand-all-request-missing-form
  (let ((result (xrepl-ops-advanced:macroexpand-all-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-form (element 2 result))))

(deftest macroexpand-all-response-construction
  (let ((resp (xrepl-ops-advanced:macroexpand-all-response #m(expansion #"(fully expanded)"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"(fully expanded)" (maps:get #"expansion" resp))))

;;; ==========================================
;;; list_macros operation tests
;;; ==========================================

(deftest list-macros-request-minimal
  (let ((req (xrepl-ops-advanced:list-macros-request #m())))
    (is-equal #"list_macros" (maps:get #"op" req))))

(deftest list-macros-request-with-namespace
  (let ((req (xrepl-ops-advanced:list-macros-request #m(namespace "lfe"))))
    (is-equal #"list_macros" (maps:get #"op" req))
    (is-equal #"lfe" (maps:get #"namespace" req))))

(deftest list-macros-request-with-pattern
  (let ((req (xrepl-ops-advanced:list-macros-request #m(pattern "def*"))))
    (is-equal #"list_macros" (maps:get #"op" req))
    (is-equal #"def*" (maps:get #"pattern" req))))

(deftest list-macros-response-construction
  (let ((resp (xrepl-ops-advanced:list-macros-response
                `#m(macros ,(list `#m(name #"defn" arity 2))))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 1 (length (maps:get #"macros" resp)))))

;;; ==========================================
;;; history operation tests
;;; ==========================================

(deftest history-request-minimal
  (let ((req (xrepl-ops-advanced:history-request #m())))
    (is-equal #"history" (maps:get #"op" req))))

(deftest history-request-with-limit
  (let ((req (xrepl-ops-advanced:history-request #m(limit 10))))
    (is-equal #"history" (maps:get #"op" req))
    (is-equal 10 (maps:get #"limit" req))))

(deftest history-request-with-offset-and-reverse
  (let ((req (xrepl-ops-advanced:history-request #m(offset 5 reverse true))))
    (is-equal #"history" (maps:get #"op" req))
    (is-equal 5 (maps:get #"offset" req))
    (is-equal 'true (maps:get #"reverse" req))))

(deftest history-response-construction
  (let ((resp (xrepl-ops-advanced:history-response
                `#m(entries ,(list `#m(id 1 command #"(+ 1 2)")) total 42))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 1 (length (maps:get #"entries" resp)))
    (is-equal 42 (maps:get #"total" resp))))

;;; ==========================================
;;; search_history operation tests
;;; ==========================================

(deftest search-history-request-minimal
  (let ((req (xrepl-ops-advanced:search-history-request #m(query "defn"))))
    (is-equal #"search_history" (maps:get #"op" req))
    (is-equal #"defn" (maps:get #"query" req))))

(deftest search-history-request-with-options
  (let ((req (xrepl-ops-advanced:search-history-request
               #m(query "map" limit 5 case_sensitive true))))
    (is-equal #"search_history" (maps:get #"op" req))
    (is-equal 5 (maps:get #"limit" req))
    (is-equal 'true (maps:get #"case_sensitive" req))))

(deftest search-history-request-missing-query
  (let ((result (xrepl-ops-advanced:search-history-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-query (element 2 result))))

(deftest search-history-response-construction
  (let ((resp (xrepl-ops-advanced:search-history-response
                `#m(matches ,(list `#m(id 5 command #"(defn foo)")) total_matches 3))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 1 (length (maps:get #"matches" resp)))
    (is-equal 3 (maps:get #"total_matches" resp))))

;;; ==========================================
;;; profile_start operation tests
;;; ==========================================

(deftest profile-start-request-minimal
  (let ((req (xrepl-ops-advanced:profile-start-request #m())))
    (is-equal #"profile_start" (maps:get #"op" req))))

(deftest profile-start-request-with-target
  (let ((req (xrepl-ops-advanced:profile-start-request
               #m(target "mymodule"))))
    (is-equal #"profile_start" (maps:get #"op" req))
    (is-equal #"mymodule" (maps:get #"target" req))))

(deftest profile-start-request-with-options
  (let ((req (xrepl-ops-advanced:profile-start-request
               `#m(target "all" options ,#m(memory true)))))
    (is-equal #"profile_start" (maps:get #"op" req))
    (is-equal #m(memory true) (maps:get #"options" req))))

(deftest profile-start-response-construction
  (let ((resp (xrepl-ops-advanced:profile-start-response #m(profile_id #"prof-123"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"prof-123" (maps:get #"profile_id" resp))))

;;; ==========================================
;;; profile_stop operation tests
;;; ==========================================

(deftest profile-stop-request-minimal
  (let ((req (xrepl-ops-advanced:profile-stop-request #m())))
    (is-equal #"profile_stop" (maps:get #"op" req))))

(deftest profile-stop-request-with-id-and-format
  (let ((req (xrepl-ops-advanced:profile-stop-request
               #m(profile_id "prof-123" format "json"))))
    (is-equal #"profile_stop" (maps:get #"op" req))
    (is-equal #"prof-123" (maps:get #"profile_id" req))
    (is-equal #"json" (maps:get #"format" req))))

(deftest profile-stop-response-construction
  (let ((resp (xrepl-ops-advanced:profile-stop-response
                `#m(results ,#m(total_calls 1234) elapsed_ms 10000))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 10000 (maps:get #"elapsed_ms" resp))))

;;; ==========================================
;;; benchmark operation tests
;;; ==========================================

(deftest benchmark-request-minimal
  (let ((req (xrepl-ops-advanced:benchmark-request #m(code "(fib 20)"))))
    (is-equal #"benchmark" (maps:get #"op" req))
    (is-equal #"(fib 20)" (maps:get #"code" req))))

(deftest benchmark-request-with-options
  (let ((req (xrepl-ops-advanced:benchmark-request
               #m(code "(expensive)" iterations 1000 warmup 100))))
    (is-equal #"benchmark" (maps:get #"op" req))
    (is-equal 1000 (maps:get #"iterations" req))
    (is-equal 100 (maps:get #"warmup" req))))

(deftest benchmark-request-missing-code
  (let ((result (xrepl-ops-advanced:benchmark-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-code (element 2 result))))

(deftest benchmark-response-construction
  (let ((resp (xrepl-ops-advanced:benchmark-response
                #m(mean_us 123.45 median_us 120.0 iterations 10000))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 123.45 (maps:get #"mean_us" resp))
    (is-equal 120.0 (maps:get #"median_us" resp))
    (is-equal 10000 (maps:get #"iterations" resp))))

;;; ==========================================
;;; snippets operation tests
;;; ==========================================

(deftest snippets-request-minimal
  (let ((req (xrepl-ops-advanced:snippets-request #m())))
    (is-equal #"snippets" (maps:get #"op" req))))

(deftest snippets-request-with-filters
  (let ((req (xrepl-ops-advanced:snippets-request
               #m(category "loops" language "lfe"))))
    (is-equal #"snippets" (maps:get #"op" req))
    (is-equal #"loops" (maps:get #"category" req))
    (is-equal #"lfe" (maps:get #"language" req))))

(deftest snippets-response-construction
  (let ((resp (xrepl-ops-advanced:snippets-response
                `#m(snippets ,(list `#m(id #"for-loop" name #"For Loop"))))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 1 (length (maps:get #"snippets" resp)))))

;;; ==========================================
;;; expand_snippet operation tests
;;; ==========================================

(deftest expand-snippet-request-minimal
  (let ((req (xrepl-ops-advanced:expand-snippet-request #m(id "for-loop"))))
    (is-equal #"expand_snippet" (maps:get #"op" req))
    (is-equal #"for-loop" (maps:get #"id" req))
    (is-equal #"for-loop" (maps:get #"snippet_id" req))))

(deftest expand-snippet-request-with-params
  (let ((req (xrepl-ops-advanced:expand-snippet-request
               `#m(id "for-loop" params ,#m(var #"i" limit 10)))))
    (is-equal #"expand_snippet" (maps:get #"op" req))
    (is-equal #m(var #"i" limit 10) (maps:get #"params" req))))

(deftest expand-snippet-request-with-snippet-id-alias
  (let ((req (xrepl-ops-advanced:expand-snippet-request #m(snippet_id "test"))))
    (is-equal #"expand_snippet" (maps:get #"op" req))
    (is-equal #"test" (maps:get #"id" req))
    (is-equal #"test" (maps:get #"snippet_id" req))))

(deftest expand-snippet-request-missing-id
  (let ((result (xrepl-ops-advanced:expand-snippet-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-id (element 2 result))))

(deftest expand-snippet-response-construction
  (let ((resp (xrepl-ops-advanced:expand-snippet-response
                #m(code #"(for [i (range 10)] (print i))"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"(for [i (range 10)] (print i))" (maps:get #"code" resp))))

;;; ==========================================
;;; generate_function operation tests
;;; ==========================================

(deftest generate-function-request-minimal
  (let ((req (xrepl-ops-advanced:generate-function-request #m(name "my-func"))))
    (is-equal #"generate_function" (maps:get #"op" req))
    (is-equal #"my-func" (maps:get #"name" req))))

(deftest generate-function-request-with-arity-and-params
  (let ((req (xrepl-ops-advanced:generate-function-request
               `#m(name "add" arity 2 params ,(list "a" "b")))))
    (is-equal #"generate_function" (maps:get #"op" req))
    (is-equal 2 (maps:get #"arity" req))
    (is-equal (list #"a" #"b") (maps:get #"params" req))))

(deftest generate-function-request-with-doc
  (let ((req (xrepl-ops-advanced:generate-function-request
               #m(name "test" doc "Test function"))))
    (is-equal #"generate_function" (maps:get #"op" req))
    (is-equal #"Test function" (maps:get #"doc" req))))

(deftest generate-function-request-missing-name
  (let ((result (xrepl-ops-advanced:generate-function-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-name (element 2 result))))

(deftest generate-function-response-construction
  (let ((resp (xrepl-ops-advanced:generate-function-response
                #m(code #"(defun my-func () ...)"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"(defun my-func () ...)" (maps:get #"code" resp))))

;;; ==========================================
;;; suggest_improvements operation tests
;;; ==========================================

(deftest suggest-improvements-request-minimal
  (let ((req (xrepl-ops-advanced:suggest-improvements-request
               #m(code "(defun foo () (+ 1 1))"))))
    (is-equal #"suggest_improvements" (maps:get #"op" req))
    (is-equal #"(defun foo () (+ 1 1))" (maps:get #"code" req))))

(deftest suggest-improvements-request-with-context-and-focus
  (let ((req (xrepl-ops-advanced:suggest-improvements-request
               `#m(code "(test)" context "module context" focus ,(list "performance" "readability")))))
    (is-equal #"suggest_improvements" (maps:get #"op" req))
    (is-equal #"module context" (maps:get #"context" req))
    (is-equal (list #"performance" #"readability") (maps:get #"focus" req))))

(deftest suggest-improvements-request-missing-code
  (let ((result (xrepl-ops-advanced:suggest-improvements-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-code (element 2 result))))

(deftest suggest-improvements-response-construction
  (let ((resp (xrepl-ops-advanced:suggest-improvements-response
                `#m(suggestions ,(list `#m(type #"performance" description #"Use map"))))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 1 (length (maps:get #"suggestions" resp)))))

;;; ==========================================
;;; share_session operation tests
;;; ==========================================

(deftest share-session-request-minimal
  (let ((req (xrepl-ops-advanced:share-session-request #m())))
    (is-equal #"share_session" (maps:get #"op" req))))

(deftest share-session-request-with-include-and-expiry
  (let ((req (xrepl-ops-advanced:share-session-request
               `#m(include ,(list "history" "bindings") expiry 3600))))
    (is-equal #"share_session" (maps:get #"op" req))
    (is-equal (list #"history" #"bindings") (maps:get #"include" req))
    (is-equal 3600 (maps:get #"expiry" req))))

(deftest share-session-response-construction
  (let ((resp (xrepl-ops-advanced:share-session-response
                #m(share_id #"share-abc123" url #"https://share.example.com/abc123"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"share-abc123" (maps:get #"share_id" resp))
    (is-equal #"https://share.example.com/abc123" (maps:get #"url" resp))))

;;; ==========================================
;;; restore_session operation tests
;;; ==========================================

(deftest restore-session-request-minimal
  (let ((req (xrepl-ops-advanced:restore-session-request #m(share_id "share-abc123"))))
    (is-equal #"restore_session" (maps:get #"op" req))
    (is-equal #"share-abc123" (maps:get #"share_id" req))))

(deftest restore-session-request-with-merge
  (let ((req (xrepl-ops-advanced:restore-session-request
               #m(share_id "share-123" merge true))))
    (is-equal #"restore_session" (maps:get #"op" req))
    (is-equal 'true (maps:get #"merge" req))))

(deftest restore-session-request-missing-share-id
  (let ((result (xrepl-ops-advanced:restore-session-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-share-id (element 2 result))))

(deftest restore-session-response-construction
  (let ((resp (xrepl-ops-advanced:restore-session-response
                `#m(restored ,(list #"history" #"bindings")))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal (list #"history" #"bindings") (maps:get #"restored" resp))))

;;; ==========================================
;;; text_document_did_open operation tests
;;; ==========================================

(deftest text-document-did-open-request-minimal
  (let ((req (xrepl-ops-advanced:text-document-did-open-request
               #m(uri "file:///test.lfe" language_id "lfe" version 1 text "(defun)"))))
    (is-equal #"text_document_did_open" (maps:get #"op" req))
    (is-equal #"file:///test.lfe" (maps:get #"uri" req))
    (is-equal #"lfe" (maps:get #"language_id" req))
    (is-equal 1 (maps:get #"version" req))
    (is-equal #"(defun)" (maps:get #"text" req))))

(deftest text-document-did-open-request-missing-fields
  (let ((result (xrepl-ops-advanced:text-document-did-open-request
                  #m(uri "test"))))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-required-fields (element 2 result))))

(deftest text-document-did-open-response-construction
  (let ((resp (xrepl-ops-advanced:text-document-did-open-response #m())))
    (is-equal #"done" (maps:get #"status" resp))))

;;; ==========================================
;;; text_document_did_change operation tests
;;; ==========================================

(deftest text-document-did-change-request-minimal
  (let ((req (xrepl-ops-advanced:text-document-did-change-request
               `#m(uri "file:///test.lfe" version 2
                   content_changes ,(list `#m(text #"updated"))))))
    (is-equal #"text_document_did_change" (maps:get #"op" req))
    (is-equal #"file:///test.lfe" (maps:get #"uri" req))
    (is-equal 2 (maps:get #"version" req))
    (is-equal 1 (length (maps:get #"content_changes" req)))))

(deftest text-document-did-change-request-missing-fields
  (let ((result (xrepl-ops-advanced:text-document-did-change-request
                  #m(uri "test"))))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-required-fields (element 2 result))))

(deftest text-document-did-change-response-construction
  (let ((resp (xrepl-ops-advanced:text-document-did-change-response #m())))
    (is-equal #"done" (maps:get #"status" resp))))

;;; ==========================================
;;; text_document_did_close operation tests
;;; ==========================================

(deftest text-document-did-close-request-minimal
  (let ((req (xrepl-ops-advanced:text-document-did-close-request
               #m(uri "file:///test.lfe"))))
    (is-equal #"text_document_did_close" (maps:get #"op" req))
    (is-equal #"file:///test.lfe" (maps:get #"uri" req))))

(deftest text-document-did-close-request-missing-uri
  (let ((result (xrepl-ops-advanced:text-document-did-close-request #m())))
    (is-equal 'error (element 1 result))
    (is-equal 'missing-uri (element 2 result))))

(deftest text-document-did-close-response-construction
  (let ((resp (xrepl-ops-advanced:text-document-did-close-response #m())))
    (is-equal #"done" (maps:get #"status" resp))))

;;; ==========================================
;;; Parsing tests
;;; ==========================================

(deftest parse-macroexpand-request
  (let* ((req #m(op #"macroexpand" form #"(when true 1)"))
         (`#(ok ,parsed) (xrepl-ops-advanced:parse-request req)))
    (is-equal #"macroexpand" (maps:get #"op" parsed))
    (is-equal #"(when true 1)" (maps:get #"form" parsed))))

(deftest parse-search-history-request
  (let* ((req #m(op #"search_history" query #"defn"))
         (`#(ok ,parsed) (xrepl-ops-advanced:parse-request req)))
    (is-equal #"search_history" (maps:get #"op" parsed))
    (is-equal #"defn" (maps:get #"query" parsed))))

(deftest parse-benchmark-request
  (let* ((req #m(op #"benchmark" code #"(test)"))
         (`#(ok ,parsed) (xrepl-ops-advanced:parse-request req)))
    (is-equal #"benchmark" (maps:get #"op" parsed))))

(deftest parse-unknown-operation
  (let* ((req #m(op #"unknown_advanced_op"))
         (result (xrepl-ops-advanced:parse-request req)))
    (is-equal 'error (element 1 result))
    (is-equal 'unknown-operation (element 2 result))))

(deftest parse-response
  (let* ((resp #m(status #"done" expansion #"(expanded)"))
         (`#(ok ,parsed) (xrepl-ops-advanced:parse-response 'macroexpand resp)))
    (is-equal #"done" (maps:get #"status" parsed))))

;;; ==========================================
;;; Validation tests
;;; ==========================================

(deftest valid-macroexpand-request-true
  (let ((req #m(op #"macroexpand" form #"(test)")))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-macroexpand-request-false-missing-form
  (let ((req #m(op #"macroexpand")))
    (is-equal 'false (xrepl-ops-advanced:valid-request? req))))

(deftest valid-search-history-request-true
  (let ((req #m(op #"search_history" query #"test")))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-search-history-request-false-missing-query
  (let ((req #m(op #"search_history")))
    (is-equal 'false (xrepl-ops-advanced:valid-request? req))))

(deftest valid-benchmark-request-true
  (let ((req #m(op #"benchmark" code #"(test)")))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-benchmark-request-false-missing-code
  (let ((req #m(op #"benchmark")))
    (is-equal 'false (xrepl-ops-advanced:valid-request? req))))

(deftest valid-list-macros-request-true
  (let ((req #m(op #"list_macros")))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-history-request-true
  (let ((req #m(op #"history")))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-expand-snippet-request-true
  (let ((req #m(op #"expand_snippet" id #"test")))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-expand-snippet-request-false-missing-id
  (let ((req #m(op #"expand_snippet")))
    (is-equal 'false (xrepl-ops-advanced:valid-request? req))))

(deftest valid-generate-function-request-true
  (let ((req #m(op #"generate_function" name #"foo")))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-generate-function-request-false-missing-name
  (let ((req #m(op #"generate_function")))
    (is-equal 'false (xrepl-ops-advanced:valid-request? req))))

(deftest valid-restore-session-request-true
  (let ((req #m(op #"restore_session" share_id #"abc123")))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-restore-session-request-false-missing-share-id
  (let ((req #m(op #"restore_session")))
    (is-equal 'false (xrepl-ops-advanced:valid-request? req))))

(deftest valid-text-document-did-open-request-true
  (let ((req #m(op #"text_document_did_open" uri #"file:///test"
                language_id #"lfe" version 1 text #"()")))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-text-document-did-open-request-false-missing-fields
  (let ((req #m(op #"text_document_did_open" uri #"file:///test")))
    (is-equal 'false (xrepl-ops-advanced:valid-request? req))))

(deftest valid-text-document-did-change-request-true
  (let ((req `#m(op #"text_document_did_change" uri #"file:///test"
                 version 2 content_changes ,(list `#m(text #"new")))))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-text-document-did-change-request-false-missing-fields
  (let ((req #m(op #"text_document_did_change" uri #"file:///test")))
    (is-equal 'false (xrepl-ops-advanced:valid-request? req))))

(deftest valid-text-document-did-close-request-true
  (let ((req #m(op #"text_document_did_close" uri #"file:///test")))
    (is-equal 'true (xrepl-ops-advanced:valid-request? req))))

(deftest valid-text-document-did-close-request-false-missing-uri
  (let ((req #m(op #"text_document_did_close")))
    (is-equal 'false (xrepl-ops-advanced:valid-request? req))))

(deftest valid-response-true
  (let ((resp #m(status #"done" expansion #"(test)")))
    (is-equal 'true (xrepl-ops-advanced:valid-response? 'macroexpand resp))))

(deftest valid-response-false-missing-status
  (let ((resp #m(expansion #"(test)")))
    (is-equal 'false (xrepl-ops-advanced:valid-response? 'macroexpand resp))))

;;; ==========================================
;;; Round-trip MessagePack tests
;;; ==========================================

(deftest macroexpand-request-msgpack-roundtrip
  (let* ((req (xrepl-ops-advanced:macroexpand-request #m(form "(when true 1)")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"macroexpand" (maps:get #"op" decoded))
    (is-equal #"(when true 1)" (maps:get #"form" decoded))))

(deftest history-request-msgpack-roundtrip
  (let* ((req (xrepl-ops-advanced:history-request #m(limit 10 reverse true)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"history" (maps:get #"op" decoded))
    (is-equal 10 (maps:get #"limit" decoded))
    (is-equal 'true (maps:get #"reverse" decoded))))

(deftest benchmark-request-msgpack-roundtrip
  (let* ((req (xrepl-ops-advanced:benchmark-request #m(code "(test)" iterations 1000)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"benchmark" (maps:get #"op" decoded))
    (is-equal #"(test)" (maps:get #"code" decoded))
    (is-equal 1000 (maps:get #"iterations" decoded))))

(deftest expand-snippet-request-msgpack-roundtrip
  (let* ((req (xrepl-ops-advanced:expand-snippet-request #m(id "for-loop")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"expand_snippet" (maps:get #"op" decoded))
    (is-equal #"for-loop" (maps:get #"id" decoded))
    (is-equal #"for-loop" (maps:get #"snippet_id" decoded))))

(deftest macroexpand-response-msgpack-roundtrip
  (let* ((resp (xrepl-ops-advanced:macroexpand-response #m(expansion #"(expanded)")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal #"(expanded)" (maps:get #"expansion" decoded))))

(deftest benchmark-response-msgpack-roundtrip
  (let* ((resp (xrepl-ops-advanced:benchmark-response
                 #m(mean_us 123.45 median_us 120.0 iterations 1000)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal 123.45 (maps:get #"mean_us" decoded))
    (is-equal 120.0 (maps:get #"median_us" decoded))
    (is-equal 1000 (maps:get #"iterations" decoded))))

;;; ==========================================
;;; Error tests
;;; ==========================================

(deftest error-missing-form
  (let ((err (xrepl-ops-advanced:error 'missing-form #m())))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: form" (maps:get #"error" err))))

(deftest error-missing-query
  (let ((err (xrepl-ops-advanced:error 'missing-query "query expected")))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: query" (maps:get #"error" err))))

(deftest error-missing-code
  (let ((err (xrepl-ops-advanced:error 'missing-code #m())))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: code" (maps:get #"error" err))))

(deftest error-missing-id
  (let ((err (xrepl-ops-advanced:error 'missing-id #m())))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: id" (maps:get #"error" err))))

(deftest error-missing-name
  (let ((err (xrepl-ops-advanced:error 'missing-name #m())))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: name" (maps:get #"error" err))))

(deftest error-missing-share-id
  (let ((err (xrepl-ops-advanced:error 'missing-share-id #m())))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: share_id" (maps:get #"error" err))))

(deftest error-missing-uri
  (let ((err (xrepl-ops-advanced:error 'missing-uri #m())))
    (is-equal #"error" (maps:get #"status" err))
    (is-equal #"Missing required field: uri" (maps:get #"error" err))))
