(defmodule xrepl-protocol-system-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; Ping tests

(deftest ping-request-construction
  (let ((req (xrepl-protocol-system:ping-request)))
    (is-equal 'ping (maps:get 'op req))))

(deftest ping-response-construction-auto-timestamp
  (let ((resp (xrepl-protocol-system:ping-response)))
    (is-equal 'done (maps:get 'status resp))
    (is-equal 'true (maps:get 'pong resp))
    (is (is_integer (maps:get 'timestamp resp)))))

(deftest ping-response-construction-with-timestamp
  (let ((resp (xrepl-protocol-system:ping-response 1234567890)))
    (is-equal 'done (maps:get 'status resp))
    (is-equal 'true (maps:get 'pong resp))
    (is-equal 1234567890 (maps:get 'timestamp resp))))

(deftest parse-ping-request
  (let ((msg #m(op ping)))
    (case (xrepl-protocol-system:parse-request msg)
      (`#(ok ,parsed)
       (is-equal 'ping (maps:get 'op parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-ping-request-binary-key
  (let ((msg (map #"op" #"ping")))
    (case (xrepl-protocol-system:parse-request msg)
      (`#(ok ,parsed)
       (is-equal 'ping (maps:get 'op parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-ping-response
  (let ((msg #m(status done pong true timestamp 1234567890)))
    (case (xrepl-protocol-system:parse-response 'ping msg)
      (`#(ok ,result)
       (is-equal 'true (maps:get 'pong result))
       (is-equal 1234567890 (maps:get 'timestamp result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Describe tests

(deftest describe-request-construction
  (let ((req (xrepl-protocol-system:describe-request)))
    (is-equal 'describe (maps:get 'op req))))

(deftest describe-response-construction
  (let* ((ops-list `(eval clone close ping describe))
         (transports-list `(tcp unix stdio))
         (opts (map 'versions #m(xrepl "0.1.0" lfe "2.2.0" erlang "26")
                    'ops ops-list
                    'transports transports-list))
         (resp (xrepl-protocol-system:describe-response opts)))
    (is-equal 'done (maps:get 'status resp))
    (is-equal ops-list (maps:get 'ops resp))
    (is-equal transports-list (maps:get 'transports resp))
    (let ((versions (maps:get 'versions resp)))
      (is-equal "0.1.0" (maps:get 'xrepl versions))
      (is-equal "2.2.0" (maps:get 'lfe versions))
      (is-equal "26" (maps:get 'erlang versions)))))

(deftest describe-response-minimal
  (let ((resp (xrepl-protocol-system:describe-response #m())))
    (is-equal 'done (maps:get 'status resp))
    (is (is_map (maps:get 'versions resp)))
    (is (is_list (maps:get 'ops resp)))
    (is (is_list (maps:get 'transports resp)))))

(deftest parse-describe-request
  (let ((msg #m(op describe)))
    (case (xrepl-protocol-system:parse-request msg)
      (`#(ok ,parsed)
       (is-equal 'describe (maps:get 'op parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-describe-response
  (let* ((ops-list `(eval ping))
         (transports-list `(tcp))
         (msg (map 'status 'done
                   'versions #m(xrepl "0.1.0")
                   'ops ops-list
                   'transports transports-list)))
    (case (xrepl-protocol-system:parse-response 'describe msg)
      (`#(ok ,result)
       (is-equal ops-list (maps:get 'ops result))
       (is-equal transports-list (maps:get 'transports result))
       (let ((versions (maps:get 'versions result)))
         (is-equal "0.1.0" (maps:get 'xrepl versions))))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Error tests

(deftest error-response-construction
  (let ((err (xrepl-protocol-system:error 'not-implemented "Feature not available")))
    (is-equal 'error (maps:get 'status err))
    (is-equal 'not-implemented (maps:get 'type (maps:get 'error err)))))

(deftest parse-error-response
  (let ((msg #m(status error error #m(type server-error message "Internal error"))))
    (case (xrepl-protocol-system:parse-response 'ping msg)
      (`#(error ,err-info)
       (is-equal 'server-error (maps:get 'type err-info)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-request-checks
  (is (xrepl-protocol-system:valid-request? #m(op ping)))
  (is (xrepl-protocol-system:valid-request? #m(op describe)))
  (is-not (xrepl-protocol-system:valid-request? #m(op invalid))))

(deftest valid-response-checks
  (is (xrepl-protocol-system:valid-response? 'ping #m(status done pong true timestamp 123)))
  (is (xrepl-protocol-system:valid-response? 'describe
        #m(status done versions #m() ops '() transports '())))
  (is (xrepl-protocol-system:valid-response? 'ping
        #m(status error error #m(type server-error message "err"))))
  (is-not (xrepl-protocol-system:valid-response? 'ping #m(status invalid))))

;;; Round-trip tests

(deftest ping-round-trip
  (let* ((req (xrepl-protocol-system:ping-request))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    ;; MessagePack converts atom keys to binary keys
    (is-equal #"ping" (maps:get #"op" decoded))
    (is (xrepl-protocol-system:valid-request? decoded))))

(deftest describe-round-trip
  (let* ((req (xrepl-protocol-system:describe-request))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    ;; MessagePack converts atom keys to binary keys
    (is-equal #"describe" (maps:get #"op" decoded))
    (is (xrepl-protocol-system:valid-request? decoded))))

(deftest describe-response-round-trip
  (let* ((ops-list `(eval ping))
         (transports-list `(tcp unix))
         (opts (map 'versions #m(xrepl "0.1.0")
                    'ops ops-list
                    'transports transports-list))
         (resp (xrepl-protocol-system:describe-response opts))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is (xrepl-protocol-system:valid-response? 'describe decoded))))
