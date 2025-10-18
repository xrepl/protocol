(defmodule xrepl-ptcl-msgpack-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

(deftest encode-decode-round-trip
  (let* ((data #m(op eval code "( + 1 2)"))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode data))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    ;; MessagePack converts atom keys to binary keys
    (is-equal #"eval" (maps:get #"op" decoded))
    (is-equal "( + 1 2)" (maps:get #"code" decoded))))

(deftest encode-with-length-round-trip
  (let* ((data #m(op eval code "(+ 1 2)"))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode-with-length data))
         (`#(ok ,decoded ,rest) (xrepl-ptcl-msgpack:decode-with-length encoded)))
    ;; MessagePack converts atom keys to binary keys
    (is-equal #"eval" (maps:get #"op" decoded))
    (is-equal "(+ 1 2)" (maps:get #"code" decoded))
    (is-equal #"" rest)))

(deftest decode-with-length-incomplete-length
  (let* ((incomplete #"\0\0"))
    (is-equal '#(error incomplete-length)
              (xrepl-ptcl-msgpack:decode-with-length incomplete))))

(deftest decode-with-length-incomplete-message
  (let* ((incomplete #"\0\0\0\x64"))  ;; Says 100 bytes, but empty
    (is-equal '#(error incomplete-message)
              (xrepl-ptcl-msgpack:decode-with-length incomplete))))

(deftest encode-decode-various-types
  ;; Test basic types that survive round-trip unchanged
  (let ((test-cases (list
                      42
                      "hello"
                      #"binary"
                      (list 1 2 3))))
    (lists:foreach
      (lambda (test-case)
        (case (xrepl-ptcl-msgpack:encode test-case)
          (`#(ok ,encoded)
           (case (xrepl-ptcl-msgpack:decode encoded)
             (`#(ok ,decoded)
              (is-equal test-case decoded))
             (error
              (error (tuple 'decode-failed test-case error)))))
          (error
           (error (tuple 'encode-failed test-case error)))))
      test-cases))
  ;; Test map separately - keys become binaries
  (let* ((map-data #m(key value nested #m(deep true)))
         (`#(ok ,encoded) (xrepl-ptcl-msgpack:encode map-data))
         (`#(ok ,decoded) (xrepl-ptcl-msgpack:decode encoded)))
    (is-equal #"value" (maps:get #"key" decoded))
    (is-equal 'true (maps:get #"deep" (maps:get #"nested" decoded)))))
