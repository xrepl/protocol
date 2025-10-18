(defmodule xrepl-ops-compilation
  "Compilation operation protocol messages.

  This module defines all compilation operations in the xrepl protocol."
  (export
   ;; compile_file operation
   (compile-file-request 1)
   (compile-file-response 1)
   ;; compile_project operation
   (compile-project-request 1)
   (compile-project-response 1)
   ;; lint operation
   (lint-request 1)
   (lint-response 1)
   ;; dependencies operation
   (dependencies-request 1)
   (dependencies-response 1)
   ;; build operation
   (build-request 1)
   (build-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))

;;; compile_file operation

(defun compile-file-request (opts)
  "Build a compile_file request.

  Options:
    file: File path to compile (required, alias: path)
    options: Compilation options map (optional, alias: compile_options)
    session: Session ID (optional)

  Returns:
    Request message map or error

  Example:
    (compile-file-request #m(file \"src/foo.lfe\"))
    (compile-file-request #m(path \"test.lfe\" options #m(#\"warnings\" true)))
    (compile-file-request #m(file \"bar.lfe\" session \"s1\"))"
  (case (xrepl-ptcl-types:get-field-any opts '(file path))
    ('undefined
     (tuple 'error 'missing-file))
    (file
     (let* ((base (maps:put #"op" #"compile_file"
                           (xrepl-ptcl-types:put-aliased
                            #m() 'file 'path
                            (xrepl-ptcl-types:ensure-binary file))))
            (with-options (case (xrepl-ptcl-types:get-field-any opts '(options compile_options))
                           ('undefined base)
                           (opts-val (xrepl-ptcl-types:put-aliased
                                     base 'options 'compile_options opts-val))))
            (with-session (xrepl-ptcl-types:maybe-put-aliased
                          with-options 'session 'session opts 'session)))
       with-session))))

(defun compile-file-response (result)
  "Build a compile_file response.

  Args:
    result: Compilation result map with success status, warnings, errors

  Returns:
    Response message map

  Example:
    (compile-file-response #m(#\"success\" true
                              #\"warnings\" (list)
                              #\"errors\" (list)
                              #\"output_file\" #\"ebin/foo.beam\"))"
  (maps:put #"status" #"done"
           (maps:put #"result" result #m())))

;;; compile_project operation

(defun compile-project-request (opts)
  "Build a compile_project request.

  Options:
    path: Project path (optional, defaults to current directory)
    clean: Clean before compile (optional, boolean)
    profile: Build profile to use (optional, alias: build_profile)
    options: Compilation options (optional)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (compile-project-request #m())
    (compile-project-request #m(path \"/path/to/project\"))
    (compile-project-request #m(clean true profile \"prod\"))"
  (let* ((base (maps:put #"op" #"compile_project" #m()))
         (with-path (case (xrepl-ptcl-types:get-field opts 'path 'undefined)
                     ('undefined base)
                     (p (maps:put #"path"
                                 (xrepl-ptcl-types:ensure-binary p)
                                 base))))
         (with-clean (case (xrepl-ptcl-types:get-field opts 'clean 'undefined)
                      ('undefined with-path)
                      (c (maps:put #"clean" c with-path))))
         (with-profile (case (xrepl-ptcl-types:get-field-any opts '(profile build_profile))
                        ('undefined with-clean)
                        (prof (xrepl-ptcl-types:put-aliased
                              with-clean 'profile 'build_profile
                              (xrepl-ptcl-types:ensure-binary prof)))))
         (with-options (case (xrepl-ptcl-types:get-field opts 'options 'undefined)
                        ('undefined with-profile)
                        (opts-val (maps:put #"options" opts-val with-profile))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                       with-options 'session 'session opts 'session)))
    with-session))

(defun compile-project-response (result)
  "Build a compile_project response.

  Args:
    result: Compilation result map with files compiled, warnings, errors

  Returns:
    Response message map

  Example:
    (compile-project-response #m(#\"success\" true
                                 #\"files_compiled\" 15
                                 #\"warnings\" (list)
                                 #\"errors\" (list)
                                 #\"duration\" 2.5))"
  (maps:put #"status" #"done"
           (maps:put #"result" result #m())))

;;; lint operation

(defun lint-request (opts)
  "Build a lint request.

  Options:
    file: File to lint (optional, alias: path)
    code: Code to lint (optional)
    linters: List of linters to run (optional)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (lint-request #m(file \"src/foo.lfe\"))
    (lint-request #m(code \"(defun foo () 42)\"))
    (lint-request #m(path \"test.lfe\" linters (list \"syntax\" \"style\")))"
  (let* ((base (maps:put #"op" #"lint" #m()))
         (with-file (case (xrepl-ptcl-types:get-field-any opts '(file path))
                     ('undefined base)
                     (f (xrepl-ptcl-types:put-aliased
                        base 'file 'path
                        (xrepl-ptcl-types:ensure-binary f)))))
         (with-code (case (xrepl-ptcl-types:get-field opts 'code 'undefined)
                     ('undefined with-file)
                     (c (maps:put #"code"
                                 (xrepl-ptcl-types:ensure-binary c)
                                 with-file))))
         (with-linters (case (xrepl-ptcl-types:get-field opts 'linters 'undefined)
                        ('undefined with-code)
                        (ls (maps:put #"linters"
                                     (lists:map #'xrepl-ptcl-types:ensure-binary/1 ls)
                                     with-code))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                       with-linters 'session 'session opts 'session)))
    with-session))

(defun lint-response (issues)
  "Build a lint response.

  Args:
    issues: List of lint issues (warnings, errors, suggestions)

  Returns:
    Response message map

  Example:
    (lint-response (list #m(#\"severity\" #\"warning\"
                            #\"message\" #\"Unused variable\"
                            #\"line\" 10
                            #\"column\" 5)))"
  (maps:put #"status" #"done"
           (maps:put #"issues" issues #m())))

;;; dependencies operation

(defun dependencies-request (opts)
  "Build a dependencies request.

  Options:
    path: Project path (optional)
    type: Dependency type filter (optional, values: direct, all, tree)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (dependencies-request #m())
    (dependencies-request #m(path \"/path/to/project\"))
    (dependencies-request #m(type \"direct\" session \"s1\"))"
  (let* ((base (maps:put #"op" #"dependencies" #m()))
         (with-path (case (xrepl-ptcl-types:get-field opts 'path 'undefined)
                     ('undefined base)
                     (p (maps:put #"path"
                                 (xrepl-ptcl-types:ensure-binary p)
                                 base))))
         (with-type (case (xrepl-ptcl-types:get-field opts 'type 'undefined)
                     ('undefined with-path)
                     (t (maps:put #"type"
                                 (xrepl-ptcl-types:ensure-binary t)
                                 with-path))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                       with-type 'session 'session opts 'session)))
    with-session))

(defun dependencies-response (deps)
  "Build a dependencies response.

  Args:
    deps: Dependencies map or list

  Returns:
    Response message map

  Example:
    (dependencies-response (list #m(#\"name\" #\"lfe\"
                                    #\"version\" #\"2.1.1\"
                                    #\"type\" #\"direct\")))"
  (maps:put #"status" #"done"
           (maps:put #"dependencies" deps #m())))

;;; build operation

(defun build-request (opts)
  "Build a build request.

  Options:
    task: Build task to run (optional, alias: target)
    args: Build arguments (optional, list)
    clean: Clean before build (optional, boolean)
    session: Session ID (optional)

  Returns:
    Request message map

  Example:
    (build-request #m())
    (build-request #m(task \"compile\"))
    (build-request #m(target \"release\" args (list \"--prod\")))
    (build-request #m(task \"test\" clean true session \"s1\"))"
  (let* ((base (maps:put #"op" #"build" #m()))
         (with-task (case (xrepl-ptcl-types:get-field-any opts '(task target))
                     ('undefined base)
                     (t (xrepl-ptcl-types:put-aliased
                        base 'task 'target
                        (xrepl-ptcl-types:ensure-binary t)))))
         (with-args (case (xrepl-ptcl-types:get-field opts 'args 'undefined)
                     ('undefined with-task)
                     (a (maps:put #"args"
                                 (lists:map #'xrepl-ptcl-types:ensure-binary/1 a)
                                 with-task))))
         (with-clean (case (xrepl-ptcl-types:get-field opts 'clean 'undefined)
                      ('undefined with-args)
                      (c (maps:put #"clean" c with-args))))
         (with-session (xrepl-ptcl-types:maybe-put-aliased
                       with-clean 'session 'session opts 'session)))
    with-session))

(defun build-response (result)
  "Build a build response.

  Args:
    result: Build result map with success status, output, errors

  Returns:
    Response message map

  Example:
    (build-response #m(#\"success\" true
                       #\"duration\" 5.2
                       #\"output\" #\"Build completed successfully\"))"
  (maps:put #"status" #"done"
           (maps:put #"result" result #m())))

;;; Parsing functions

(defun parse-request (message)
  "Parse a compilation operation request message.

  Args:
    message: The request message map (with binary keys from MessagePack)

  Returns:
    #(ok parsed-message) or #(error reason)"
  (let ((op (xrepl-ptcl-types:get-field message 'op)))
    (cond
      ;; compile_file
      ((or (== op #"compile_file") (== op 'compile_file))
       (let ((file (xrepl-ptcl-types:get-field-any message '(file path)))
             (options (xrepl-ptcl-types:get-field-any message '(options compile_options)))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (if (== file 'undefined)
           (tuple 'error 'missing-file)
           (tuple 'ok (maps:put #"op" #"compile_file"
                               (maps:put #"file" file
                                        (maps:put #"options" options
                                                 (maps:put #"session" session #m()))))))))

      ;; compile_project
      ((or (== op #"compile_project") (== op 'compile_project))
       (let ((path (xrepl-ptcl-types:get-field message 'path))
             (clean (xrepl-ptcl-types:get-field message 'clean))
             (profile (xrepl-ptcl-types:get-field-any message '(profile build_profile)))
             (options (xrepl-ptcl-types:get-field message 'options))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (tuple 'ok (maps:put #"op" #"compile_project"
                             (maps:put #"path" path
                                      (maps:put #"clean" clean
                                               (maps:put #"profile" profile
                                                        (maps:put #"options" options
                                                                 (maps:put #"session" session #m())))))))))

      ;; lint
      ((or (== op #"lint") (== op 'lint))
       (let ((file (xrepl-ptcl-types:get-field-any message '(file path)))
             (code (xrepl-ptcl-types:get-field message 'code))
             (linters (xrepl-ptcl-types:get-field message 'linters))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (tuple 'ok (maps:put #"op" #"lint"
                             (maps:put #"file" file
                                      (maps:put #"code" code
                                               (maps:put #"linters" linters
                                                        (maps:put #"session" session #m()))))))))

      ;; dependencies
      ((or (== op #"dependencies") (== op 'dependencies))
       (let ((path (xrepl-ptcl-types:get-field message 'path))
             (type (xrepl-ptcl-types:get-field message 'type))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (tuple 'ok (maps:put #"op" #"dependencies"
                             (maps:put #"path" path
                                      (maps:put #"type" type
                                               (maps:put #"session" session #m())))))))

      ;; build
      ((or (== op #"build") (== op 'build))
       (let ((task (xrepl-ptcl-types:get-field-any message '(task target)))
             (args (xrepl-ptcl-types:get-field message 'args))
             (clean (xrepl-ptcl-types:get-field message 'clean))
             (session (xrepl-ptcl-types:get-field message 'session)))
         (tuple 'ok (maps:put #"op" #"build"
                             (maps:put #"task" task
                                      (maps:put #"args" args
                                               (maps:put #"clean" clean
                                                        (maps:put #"session" session #m()))))))))

      ;; Unknown operation
      ('true
       (tuple 'error 'unknown-operation)))))

(defun parse-response (message op)
  "Parse a compilation operation response message.

  Args:
    message: The response message map (with binary keys from MessagePack)
    op: The operation name (atom or binary)

  Returns:
    #(ok parsed-response) or #(error reason)"
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (cond
      ;; compile_file response
      ((or (== op #"compile_file") (== op 'compile_file))
       (let ((result (xrepl-ptcl-types:get-field message 'result)))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"result" result #m())))))

      ;; compile_project response
      ((or (== op #"compile_project") (== op 'compile_project))
       (let ((result (xrepl-ptcl-types:get-field message 'result)))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"result" result #m())))))

      ;; lint response
      ((or (== op #"lint") (== op 'lint))
       (let ((issues (xrepl-ptcl-types:get-field message 'issues)))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"issues" issues #m())))))

      ;; dependencies response
      ((or (== op #"dependencies") (== op 'dependencies))
       (let ((deps (xrepl-ptcl-types:get-field message 'dependencies)))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"dependencies" deps #m())))))

      ;; build response
      ((or (== op #"build") (== op 'build))
       (let ((result (xrepl-ptcl-types:get-field message 'result)))
         (tuple 'ok (maps:put #"status" status
                             (maps:put #"result" result #m())))))

      ;; Unknown operation
      ('true
       (tuple 'error 'unknown-operation)))))

;;; Validation functions

(defun valid-request? (message)
  "Validate a compilation operation request message.

  Args:
    message: The request message map

  Returns:
    true if valid, false otherwise"
  (let ((op (xrepl-ptcl-types:get-field message 'op)))
    (cond
      ;; compile_file: requires file
      ((or (== op #"compile_file") (== op 'compile_file))
       (let ((file (xrepl-ptcl-types:get-field-any message '(file path))))
         (not (== file 'undefined))))

      ;; compile_project: no required fields beyond op
      ((or (== op #"compile_project") (== op 'compile_project))
       'true)

      ;; lint: no required fields beyond op (can lint file or code)
      ((or (== op #"lint") (== op 'lint))
       'true)

      ;; dependencies: no required fields beyond op
      ((or (== op #"dependencies") (== op 'dependencies))
       'true)

      ;; build: no required fields beyond op
      ((or (== op #"build") (== op 'build))
       'true)

      ;; Unknown or missing op
      ('true 'false))))

(defun valid-response? (message op)
  "Validate a compilation operation response message.

  Args:
    message: The response message map
    op: The operation name

  Returns:
    true if valid, false otherwise"
  (let ((status (xrepl-ptcl-types:get-field message 'status)))
    (cond
      ;; All responses require status
      ((== status 'undefined) 'false)

      ;; compile_file: requires result
      ((or (== op #"compile_file") (== op 'compile_file))
       (let ((result (xrepl-ptcl-types:get-field message 'result)))
         (not (== result 'undefined))))

      ;; compile_project: requires result
      ((or (== op #"compile_project") (== op 'compile_project))
       (let ((result (xrepl-ptcl-types:get-field message 'result)))
         (not (== result 'undefined))))

      ;; lint: requires issues
      ((or (== op #"lint") (== op 'lint))
       (let ((issues (xrepl-ptcl-types:get-field message 'issues)))
         (not (== issues 'undefined))))

      ;; dependencies: requires dependencies
      ((or (== op #"dependencies") (== op 'dependencies))
       (let ((deps (xrepl-ptcl-types:get-field message 'dependencies)))
         (not (== deps 'undefined))))

      ;; build: requires result
      ((or (== op #"build") (== op 'build))
       (let ((result (xrepl-ptcl-types:get-field message 'result)))
         (not (== result 'undefined))))

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
    (error 'compilation-failed \"Compilation failed\")"
  (maps:put #"status" #"error"
           (maps:put #"error-type" (xrepl-ptcl-types:ensure-binary type)
                    (maps:put #"error" (xrepl-ptcl-types:ensure-binary msg) #m()))))
