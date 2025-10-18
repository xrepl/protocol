(defmodule xrepl-ptcl-ops-nav-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; find_definition tests

(deftest find-definition-request-minimal
  (let ((req (xrepl-ptcl-ops-nav:find-definition-request #m(symbol "map:get"))))
    (is-equal #"find_definition" (maps:get #"op" req))
    (is-equal #"map:get" (maps:get #"symbol" req))))

(deftest find-definition-request-with-location
  (let ((req (xrepl-ptcl-ops-nav:find-definition-request
              #m(symbol "foo" file "test.lfe" line 10 column 5))))
    (is-equal #"find_definition" (maps:get #"op" req))
    (is-equal #"foo" (maps:get #"symbol" req))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest find-definition-request-with-position
  (let ((req (xrepl-ptcl-ops-nav:find-definition-request
              #m(symbol "bar" position 42 session "s1"))))
    (is-equal #"find_definition" (maps:get #"op" req))
    (is-equal 42 (maps:get #"position" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest find-definition-response-construction
  (let* ((locs (list #m(#"file" #"src/foo.lfe" #"line" 42 #"column" 10)))
         (resp (xrepl-ptcl-ops-nav:find-definition-response locs)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal locs (maps:get #"locations" resp))))

;;; find_references tests

(deftest find-references-request-minimal
  (let ((req (xrepl-ptcl-ops-nav:find-references-request #m(symbol "map:get"))))
    (is-equal #"find_references" (maps:get #"op" req))
    (is-equal #"map:get" (maps:get #"symbol" req))))

(deftest find-references-request-with-location
  (let ((req (xrepl-ptcl-ops-nav:find-references-request
              #m(symbol "foo" file "test.lfe" line 10 column 5))))
    (is-equal #"find_references" (maps:get #"op" req))
    (is-equal #"foo" (maps:get #"symbol" req))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest find-references-request-with-include-declaration
  (let* ((opts (maps:put 'symbol #"bar"
                        (maps:put 'include_declaration 'true
                                 (maps:put 'session #"s1" #m()))))
         (req (xrepl-ptcl-ops-nav:find-references-request opts)))
    (is-equal #"find_references" (maps:get #"op" req))
    (is-equal #"bar" (maps:get #"symbol" req))
    (is-equal 'true (maps:get #"include_declaration" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest find-references-response-construction
  (let* ((refs (list #m(#"file" #"src/foo.lfe"
                        #"line" 10
                        #"column" 5
                        #"context" #"usage")))
         (resp (xrepl-ptcl-ops-nav:find-references-response refs)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal refs (maps:get #"references" resp))))

;;; list_definitions tests

(deftest list-definitions-request-with-file
  (let ((req (xrepl-ptcl-ops-nav:list-definitions-request #m(file "src/foo.lfe"))))
    (is-equal #"list_definitions" (maps:get #"op" req))
    (is-equal #"src/foo.lfe" (maps:get #"file" req))))

(deftest list-definitions-request-with-module
  (let ((req (xrepl-ptcl-ops-nav:list-definitions-request #m(module "lists"))))
    (is-equal #"list_definitions" (maps:get #"op" req))
    (is-equal #"lists" (maps:get #"module" req))))

(deftest list-definitions-request-with-session
  (let ((req (xrepl-ptcl-ops-nav:list-definitions-request
              #m(file "test.lfe" session "s1"))))
    (is-equal #"list_definitions" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest list-definitions-response-construction
  (let* ((defs (list #m(#"name" #"foo"
                        #"type" #"function"
                        #"line" 10
                        #"arity" 2)))
         (resp (xrepl-ptcl-ops-nav:list-definitions-response defs)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal defs (maps:get #"definitions" resp))))

;;; symbol_at_point tests

(deftest symbol-at-point-request-construction
  (let ((req (xrepl-ptcl-ops-nav:symbol-at-point-request
              #m(file "test.lfe" line 10 column 5))))
    (is-equal #"symbol_at_point" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest symbol-at-point-request-with-session
  (let ((req (xrepl-ptcl-ops-nav:symbol-at-point-request
              #m(file "test.lfe" line 10 column 5 session "s1"))))
    (is-equal #"symbol_at_point" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest symbol-at-point-response-construction
  (let* ((info #m(#"name" #"map:get"
                  #"type" #"function"
                  #"arity" 2
                  #"doc" #"Get value from map"))
         (resp (xrepl-ptcl-ops-nav:symbol-at-point-response info)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal info (maps:get #"symbol" resp))))

;;; workspace_symbols tests

(deftest workspace-symbols-request-construction
  (let ((req (xrepl-ptcl-ops-nav:workspace-symbols-request #m(query "map"))))
    (is-equal #"workspace_symbols" (maps:get #"op" req))
    (is-equal #"map" (maps:get #"query" req))))

(deftest workspace-symbols-request-with-session
  (let ((req (xrepl-ptcl-ops-nav:workspace-symbols-request
              #m(query "map" session "s1"))))
    (is-equal #"workspace_symbols" (maps:get #"op" req))
    (is-equal #"s1" (maps:get #"session" req))))

(deftest workspace-symbols-response-construction
  (let* ((location-map (maps:put #"file" #"src/maps.lfe"
                                (maps:put #"line" 42 #m())))
         (symbol-map (maps:put #"name" #"map:get"
                              (maps:put #"kind" #"function"
                                       (maps:put #"location" location-map #m()))))
         (symbols (list symbol-map))
         (resp (xrepl-ptcl-ops-nav:workspace-symbols-response symbols)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal symbols (maps:get #"symbols" resp))))

;;; Parsing tests

(deftest parse-find-definition-request
  (let ((msg #m(#"op" #"find_definition" #"symbol" #"map:get")))
    (case (xrepl-ptcl-ops-nav:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"find_definition" (maps:get #"op" parsed))
       (is-equal #"map:get" (maps:get #"symbol" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-find-definition-request-missing-symbol
  (let ((msg #m(#"op" #"find_definition")))
    (case (xrepl-ptcl-ops-nav:parse-request msg)
      (`#(error missing-symbol)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-find-references-request
  (let ((msg #m(#"op" #"find_references" #"symbol" #"foo")))
    (case (xrepl-ptcl-ops-nav:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"find_references" (maps:get #"op" parsed))
       (is-equal #"foo" (maps:get #"symbol" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-find-references-request-missing-symbol
  (let ((msg #m(#"op" #"find_references")))
    (case (xrepl-ptcl-ops-nav:parse-request msg)
      (`#(error missing-symbol)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-list-definitions-request
  (let ((msg #m(#"op" #"list_definitions")))
    (case (xrepl-ptcl-ops-nav:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"list_definitions" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-symbol-at-point-request
  (let ((msg #m(#"op" #"symbol_at_point")))
    (case (xrepl-ptcl-ops-nav:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"symbol_at_point" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-workspace-symbols-request
  (let ((msg #m(#"op" #"workspace_symbols" #"query" #"map")))
    (case (xrepl-ptcl-ops-nav:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"workspace_symbols" (maps:get #"op" parsed))
       (is-equal #"map" (maps:get #"query" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-workspace-symbols-request-missing-query
  (let ((msg #m(#"op" #"workspace_symbols")))
    (case (xrepl-ptcl-ops-nav:parse-request msg)
      (`#(error missing-query)
       (is 'true))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-find-definition-response
  (let* ((locs (list #m(#"file" #"src/foo.lfe" #"line" 42)))
         (msg (maps:put #"status" #"done"
                       (maps:put #"locations" locs #m()))))
    (case (xrepl-ptcl-ops-nav:parse-response #"find_definition" msg)
      (`#(ok ,result)
       (is-equal locs (maps:get #"locations" result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-request-checks
  (is (xrepl-ptcl-ops-nav:valid-request? #m(#"op" #"find_definition" #"symbol" #"foo")))
  (is (xrepl-ptcl-ops-nav:valid-request? #m(#"op" #"find_references" #"symbol" #"bar")))
  (is (xrepl-ptcl-ops-nav:valid-request? #m(#"op" #"list_definitions")))
  (is (xrepl-ptcl-ops-nav:valid-request? #m(#"op" #"symbol_at_point")))
  (is (xrepl-ptcl-ops-nav:valid-request? #m(#"op" #"workspace_symbols" #"query" #"map")))
  (is-not (xrepl-ptcl-ops-nav:valid-request? #m(#"op" #"unknown")))
  (is-not (xrepl-ptcl-ops-nav:valid-request? #m(#"op" #"find_definition")))  ;; missing symbol
  (is-not (xrepl-ptcl-ops-nav:valid-request? #m(#"op" #"find_references")))  ;; missing symbol
  (is-not (xrepl-ptcl-ops-nav:valid-request? #m(#"op" #"workspace_symbols"))))  ;; missing query

(deftest valid-response-checks
  (is (xrepl-ptcl-ops-nav:valid-response? #"find_definition" #m(#"status" #"done")))
  (is (xrepl-ptcl-ops-nav:valid-response? #"find_references" #m(#"status" #"done")))
  (is (xrepl-ptcl-ops-nav:valid-response? #"workspace_symbols" #m(#"status" #"error")))
  (is-not (xrepl-ptcl-ops-nav:valid-response? #"find_definition" #m(#"status" #"invalid"))))

;;; Round-trip tests

(deftest find-definition-round-trip
  (let* ((req (xrepl-ptcl-ops-nav:find-definition-request
              #m(symbol "map:get" file "test.lfe" line 10 column 5 session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"find_definition" (maps:get #"op" decoded))
    (is-equal #"map:get" (maps:get #"symbol" decoded))
    (is-equal #"test.lfe" (maps:get #"file" decoded))
    (is-equal 10 (maps:get #"line" decoded))
    (is-equal 5 (maps:get #"column" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-nav:valid-request? decoded))))

(deftest find-definition-response-round-trip
  (let* ((locs (list #m(#"file" #"src/foo.lfe" #"line" 42 #"column" 10)))
         (resp (xrepl-ptcl-ops-nav:find-definition-response locs))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal locs (maps:get #"locations" decoded))))

(deftest find-references-round-trip
  (let* ((opts (maps:put 'symbol #"foo"
                        (maps:put 'include_declaration 'true
                                 (maps:put 'session #"s1" #m()))))
         (req (xrepl-ptcl-ops-nav:find-references-request opts))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"find_references" (maps:get #"op" decoded))
    (is-equal #"foo" (maps:get #"symbol" decoded))
    (is-equal 'true (maps:get #"include_declaration" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-nav:valid-request? decoded))))

(deftest find-references-response-round-trip
  (let* ((refs (list #m(#"file" #"src/bar.lfe"
                        #"line" 20
                        #"column" 8
                        #"context" #"usage")))
         (resp (xrepl-ptcl-ops-nav:find-references-response refs))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal refs (maps:get #"references" decoded))))

(deftest list-definitions-round-trip
  (let* ((req (xrepl-ptcl-ops-nav:list-definitions-request #m(file "test.lfe" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"list_definitions" (maps:get #"op" decoded))
    (is-equal #"test.lfe" (maps:get #"file" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-nav:valid-request? decoded))))

(deftest list-definitions-response-round-trip
  (let* ((defs (list #m(#"name" #"foo" #"type" #"function" #"line" 10 #"arity" 2)))
         (resp (xrepl-ptcl-ops-nav:list-definitions-response defs))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal defs (maps:get #"definitions" decoded))))

(deftest symbol-at-point-round-trip
  (let* ((req (xrepl-ptcl-ops-nav:symbol-at-point-request
              #m(file "test.lfe" line 10 column 5 session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"symbol_at_point" (maps:get #"op" decoded))
    (is-equal #"test.lfe" (maps:get #"file" decoded))
    (is-equal 10 (maps:get #"line" decoded))
    (is-equal 5 (maps:get #"column" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-nav:valid-request? decoded))))

(deftest symbol-at-point-response-round-trip
  (let* ((info #m(#"name" #"map:get" #"type" #"function" #"arity" 2))
         (resp (xrepl-ptcl-ops-nav:symbol-at-point-response info))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal info (maps:get #"symbol" decoded))))

(deftest workspace-symbols-round-trip
  (let* ((req (xrepl-ptcl-ops-nav:workspace-symbols-request #m(query "map" session "s1")))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"workspace_symbols" (maps:get #"op" decoded))
    (is-equal #"map" (maps:get #"query" decoded))
    (is-equal #"s1" (maps:get #"session" decoded))
    (is (xrepl-ptcl-ops-nav:valid-request? decoded))))

(deftest workspace-symbols-response-round-trip
  (let* ((location-map (maps:put #"file" #"src/maps.lfe"
                                (maps:put #"line" 42 #m())))
         (symbol-map (maps:put #"name" #"map:get"
                              (maps:put #"kind" #"function"
                                       (maps:put #"location" location-map #m()))))
         (symbols (list symbol-map))
         (resp (xrepl-ptcl-ops-nav:workspace-symbols-response symbols))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"done" (maps:get #"status" decoded))
    (is-equal symbols (maps:get #"symbols" decoded))))
