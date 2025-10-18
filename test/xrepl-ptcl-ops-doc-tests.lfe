(defmodule xrepl-ptcl-ops-doc-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; doc tests

(deftest doc-request-minimal
  (let ((req (xrepl-ptcl-ops-doc:doc-request #m(symbol "map:get"))))
    (is-equal #"doc" (maps:get #"op" req))
    (is-equal #"map:get" (maps:get #"symbol" req))))

(deftest doc-request-with-session
  (let ((req (xrepl-ptcl-ops-doc:doc-request #m(symbol "lists:map" session "s1"))))
    (is-equal #"doc" (maps:get #"op" req))
    (is-equal #"lists:map" (maps:get #"symbol" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest doc-response-construction
  (let* ((doc-map (maps:put #"doc" #"Get value from map"
                           (maps:put #"arglists" (list #"(map:get key map)") #m())))
         (resp (xrepl-ptcl-ops-doc:doc-response doc-map)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal doc-map (maps:get #"doc" resp))))

;;; module_doc tests

(deftest module-doc-request-minimal
  (let ((req (xrepl-ptcl-ops-doc:module-doc-request #m(module "lists"))))
    (is-equal #"module_doc" (maps:get #"op" req))
    (is-equal #"lists" (maps:get #"module" req))))

(deftest module-doc-request-with-session
  (let ((req (xrepl-ptcl-ops-doc:module-doc-request #m(module "maps" session "s1"))))
    (is-equal #"module_doc" (maps:get #"op" req))
    (is-equal #"maps" (maps:get #"module" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest module-doc-response-construction
  (let* ((doc-map (maps:put #"module" #"lists"
                           (maps:put #"doc" #"List processing functions"
                                    (maps:put #"functions" (list) #m()))))
         (resp (xrepl-ptcl-ops-doc:module-doc-response doc-map)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal doc-map (maps:get #"doc" resp))))

;;; search_docs tests

(deftest search-docs-request-minimal
  (let ((req (xrepl-ptcl-ops-doc:search-docs-request #m(query "map"))))
    (is-equal #"search_docs" (maps:get #"op" req))
    (is-equal #"map" (maps:get #"query" req))))

(deftest search-docs-request-with-session
  (let ((req (xrepl-ptcl-ops-doc:search-docs-request #m(query "list filter" session "s1"))))
    (is-equal #"search_docs" (maps:get #"op" req))
    (is-equal #"list filter" (maps:get #"query" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest search-docs-response-construction
  (let* ((results (list #m(#"symbol" #"map:get"
                           #"doc" #"Get value from map"
                           #"relevance" 0.95)))
         (resp (xrepl-ptcl-ops-doc:search-docs-response results)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal results (maps:get #"results" resp))))

;;; generate_doc tests

(deftest generate-doc-request-minimal
  (let ((req (xrepl-ptcl-ops-doc:generate-doc-request #m(target "src/foo.lfe"))))
    (is-equal #"generate_doc" (maps:get #"op" req))
    (is-equal #"src/foo.lfe" (maps:get #"target" req))))

(deftest generate-doc-request-with-format
  (let ((req (xrepl-ptcl-ops-doc:generate-doc-request
              #m(target "lists:map" format "markdown"))))
    (is-equal #"generate_doc" (maps:get #"op" req))
    (is-equal #"lists:map" (maps:get #"target" req))
    (is-equal #"markdown" (maps:get #"format" req))))

(deftest generate-doc-request-with-session
  (let ((req (xrepl-ptcl-ops-doc:generate-doc-request
              #m(target "src/foo.lfe" format "html" session "s1"))))
    (is-equal #"generate_doc" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest generate-doc-response-construction
  (let* ((result (maps:put #"content" #"# Module: lists\n..."
                          (maps:put #"format" #"markdown"
                                   (maps:put #"path" #"docs/lists.md" #m()))))
         (resp (xrepl-ptcl-ops-doc:generate-doc-response result)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal result (maps:get #"result" resp))))

;;; module_summary tests

(deftest module-summary-request-minimal
  (let ((req (xrepl-ptcl-ops-doc:module-summary-request #m(module "lists"))))
    (is-equal #"module_summary" (maps:get #"op" req))
    (is-equal #"lists" (maps:get #"module" req))))

(deftest module-summary-request-with-session
  (let ((req (xrepl-ptcl-ops-doc:module-summary-request #m(module "maps" session "s1"))))
    (is-equal #"module_summary" (maps:get #"op" req))
    (is-equal #"maps" (maps:get #"module" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest module-summary-response-construction
  (let* ((summary (maps:put #"module" #"lists"
                           (maps:put #"description" #"List processing functions"
                                    (maps:put #"exports" 42
                                             (maps:put #"functions" 38
                                                      (maps:put #"types" 4 #m()))))))
         (resp (xrepl-ptcl-ops-doc:module-summary-response summary)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal summary (maps:get #"summary" resp))))

;;; Parsing tests

(deftest parse-doc-request
  (let ((msg #m(#"op" #"doc" #"symbol" #"map:get")))
    (case (xrepl-ptcl-ops-doc:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"doc" (maps:get #"op" parsed))
       (is-equal #"map:get" (maps:get #"symbol" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-doc-request-missing-symbol
  (let ((msg #m(#"op" #"doc")))
    (case (xrepl-ptcl-ops-doc:parse-request msg)
      (`#(error missing-symbol)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-module-doc-request
  (let ((msg #m(#"op" #"module_doc" #"module" #"lists")))
    (case (xrepl-ptcl-ops-doc:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"module_doc" (maps:get #"op" parsed))
       (is-equal #"lists" (maps:get #"module" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-module-doc-request-missing-module
  (let ((msg #m(#"op" #"module_doc")))
    (case (xrepl-ptcl-ops-doc:parse-request msg)
      (`#(error missing-module)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-search-docs-request
  (let ((msg #m(#"op" #"search_docs" #"query" #"map")))
    (case (xrepl-ptcl-ops-doc:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"search_docs" (maps:get #"op" parsed))
       (is-equal #"map" (maps:get #"query" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-search-docs-request-missing-query
  (let ((msg #m(#"op" #"search_docs")))
    (case (xrepl-ptcl-ops-doc:parse-request msg)
      (`#(error missing-query)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-generate-doc-request
  (let ((msg #m(#"op" #"generate_doc" #"target" #"src/foo.lfe")))
    (case (xrepl-ptcl-ops-doc:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"generate_doc" (maps:get #"op" parsed))
       (is-equal #"src/foo.lfe" (maps:get #"target" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-generate-doc-request-missing-target
  (let ((msg #m(#"op" #"generate_doc")))
    (case (xrepl-ptcl-ops-doc:parse-request msg)
      (`#(error missing-target)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-module-summary-request
  (let ((msg #m(#"op" #"module_summary" #"module" #"lists")))
    (case (xrepl-ptcl-ops-doc:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"module_summary" (maps:get #"op" parsed))
       (is-equal #"lists" (maps:get #"module" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-module-summary-request-missing-module
  (let ((msg #m(#"op" #"module_summary")))
    (case (xrepl-ptcl-ops-doc:parse-request msg)
      (`#(error missing-module)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-doc-response
  (let* ((doc-map #m(#"doc" #"Documentation text"))
         (msg (maps:put #"status" #"done"
                       (maps:put #"doc" doc-map #m()))))
    (case (xrepl-ptcl-ops-doc:parse-response #"doc" msg)
      (`#(ok ,result)
       (is-equal doc-map (maps:get #"doc" result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-request-checks
  (is (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"doc" #"symbol" #"foo")))
  (is (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"module_doc" #"module" #"lists")))
  (is (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"search_docs" #"query" #"map")))
  (is (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"generate_doc" #"target" #"src/foo.lfe")))
  (is (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"module_summary" #"module" #"lists")))
  (is-not (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"unknown")))
  (is-not (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"doc")))  ;; missing symbol
  (is-not (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"module_doc")))  ;; missing module
  (is-not (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"search_docs")))  ;; missing query
  (is-not (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"generate_doc")))  ;; missing target
  (is-not (xrepl-ptcl-ops-doc:valid-request? #m(#"op" #"module_summary"))))  ;; missing module

(deftest valid-response-checks
  (is (xrepl-ptcl-ops-doc:valid-response? #"doc" #m(#"status" #"done")))
  (is (xrepl-ptcl-ops-doc:valid-response? #"module_doc" #m(#"status" #"done")))
  (is (xrepl-ptcl-ops-doc:valid-response? #"search_docs" #m(#"status" #"error")))
  (is-not (xrepl-ptcl-ops-doc:valid-response? #"doc" #m(#"status" #"invalid"))))

;;; Round-trip tests

(deftest doc-round-trip
  (let* ((req (xrepl-ptcl-ops-doc:doc-request #m(symbol "map:get" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"doc" (maps:get #"op" decoded))
    (is-equal #"map:get" (maps:get #"symbol" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-doc:valid-request? decoded))))

(deftest doc-response-round-trip
  (let* ((doc-map (maps:put #"doc" #"Get value from map"
                           (maps:put #"arglists" (list #"(map:get key map)") #m())))
         (resp (xrepl-ptcl-ops-doc:doc-response doc-map))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal doc-map (maps:get #"doc" decoded))))

(deftest module-doc-round-trip
  (let* ((req (xrepl-ptcl-ops-doc:module-doc-request #m(module "lists" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"module_doc" (maps:get #"op" decoded))
    (is-equal #"lists" (maps:get #"module" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-doc:valid-request? decoded))))

(deftest module-doc-response-round-trip
  (let* ((doc-map (maps:put #"module" #"lists"
                           (maps:put #"doc" #"List processing functions" #m())))
         (resp (xrepl-ptcl-ops-doc:module-doc-response doc-map))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal doc-map (maps:get #"doc" decoded))))

(deftest search-docs-round-trip
  (let* ((req (xrepl-ptcl-ops-doc:search-docs-request #m(query "map" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"search_docs" (maps:get #"op" decoded))
    (is-equal #"map" (maps:get #"query" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-doc:valid-request? decoded))))

(deftest search-docs-response-round-trip
  (let* ((results (list #m(#"symbol" #"map:get" #"doc" #"Get value" #"relevance" 0.95)))
         (resp (xrepl-ptcl-ops-doc:search-docs-response results))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal results (maps:get #"results" decoded))))

(deftest generate-doc-round-trip
  (let* ((req (xrepl-ptcl-ops-doc:generate-doc-request
              #m(target "src/foo.lfe" format "markdown" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"generate_doc" (maps:get #"op" decoded))
    (is-equal #"src/foo.lfe" (maps:get #"target" decoded))
    (is-equal #"markdown" (maps:get #"format" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-doc:valid-request? decoded))))

(deftest generate-doc-response-round-trip
  (let* ((result (maps:put #"content" #"# Module: lists"
                          (maps:put #"format" #"markdown"
                                   (maps:put #"path" #"docs/lists.md" #m()))))
         (resp (xrepl-ptcl-ops-doc:generate-doc-response result))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal result (maps:get #"result" decoded))))

(deftest module-summary-round-trip
  (let* ((req (xrepl-ptcl-ops-doc:module-summary-request #m(module "lists" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"module_summary" (maps:get #"op" decoded))
    (is-equal #"lists" (maps:get #"module" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-doc:valid-request? decoded))))

(deftest module-summary-response-round-trip
  (let* ((summary (maps:put #"module" #"lists"
                           (maps:put #"description" #"List functions"
                                    (maps:put #"exports" 42 #m()))))
         (resp (xrepl-ptcl-ops-doc:module-summary-response summary))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal summary (maps:get #"summary" decoded))))
