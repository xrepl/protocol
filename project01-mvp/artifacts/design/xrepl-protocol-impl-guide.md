# xREPL Protocol Implementation Guide for Claude Code

## Overview

This guide provides detailed instructions for implementing the xREPL unified protocol specification in LFE (Lisp Flavored Erlang). The implementation will be done incrementally by **operation category**, with each category being a complete, testable unit of work.

## Critical Implementation Principles

### 1. Binary Keys Throughout
- **Use binary keys internally for all maps** for consistency and efficiency
- MessagePack converts atom keys to binaries, so using binaries from the start avoids conversion overhead
- Example: `#m(#"op" #"eval" #"code" #"(+ 1 2)")` NOT `#m(op eval code "(+ 1 2)")`

### 2. Field Name Aliases (Emacs/VSCode Compatibility)
All operations must support BOTH naming conventions:
- **Request builders**: Accept both field name styles as input
- **Response parsers**: Handle both field name styles from the wire
- **Response builders**: Generate BOTH field names for maximum compatibility

Example field aliases:
- `candidate` / `text` (completion text)
- `arglists` / `parameters` (function parameters)
- `doc` / `documentation` (documentation text)
- `signature` / `label` (function signature)
- `definitions` / `locations` (definition locations)
- `candidates` / `completions` (completion list)
- `history` / `commands` (command history)
- `created` / `created_at` (session creation timestamp)

### 3. Module Naming Convention
- Operations modules: `xrepl-ops-<category>.lfe` (e.g., `xrepl-ops-evaluation.lfe`)
- Other modules: `xrepl-protocol-<purpose>.lfe` (e.g., `xrepl-protocol-msgpack.lfe`)

### 4. Testing Requirements
Every module must have:
1. **Unit tests**: Test each function independently
2. **Round-trip tests**: Verify encode/decode cycles preserve data
3. **Validation tests**: Test `valid-request?` and `valid-response?` functions
4. **Alias tests**: Verify both field name styles work correctly

## Repository Structure

```
xrepl-protocol/
├── src/
│   ├── xrepl-protocol-msgpack.lfe      (existing - no changes)
│   ├── xrepl-protocol-types.lfe        (existing - UPDATE)
│   ├── xrepl-ops-evaluation.lfe        (MIGRATE from xrepl-protocol-eval.lfe)
│   ├── xrepl-ops-session.lfe           (MIGRATE from xrepl-protocol-session.lfe)
│   ├── xrepl-ops-system.lfe            (MIGRATE from xrepl-protocol-system.lfe)
│   ├── xrepl-ops-intelligence.lfe      (NEW - code intelligence)
│   ├── xrepl-ops-navigation.lfe        (NEW - navigation operations)
│   ├── xrepl-ops-documentation.lfe     (NEW - documentation operations)
│   ├── xrepl-ops-debugging.lfe         (NEW - debugging operations)
│   ├── xrepl-ops-testing.lfe           (NEW - testing operations)
│   ├── xrepl-ops-refactoring.lfe       (NEW - refactoring operations)
│   ├── xrepl-ops-compilation.lfe       (NEW - compilation & building)
│   ├── xrepl-ops-beam.lfe              (NEW - BEAM-specific operations)
│   └── xrepl-ops-advanced.lfe          (NEW - advanced features)
├── test/
│   ├── xrepl-protocol-msgpack-tests.lfe      (existing - no changes)
│   ├── xrepl-protocol-types-tests.lfe        (existing - UPDATE)
│   ├── xrepl-ops-evaluation-tests.lfe        (MIGRATE from xrepl-protocol-eval-tests.lfe)
│   ├── xrepl-ops-session-tests.lfe           (MIGRATE from xrepl-protocol-session-tests.lfe)
│   ├── xrepl-ops-system-tests.lfe            (MIGRATE from xrepl-protocol-system-tests.lfe)
│   ├── xrepl-ops-intelligence-tests.lfe      (NEW)
│   ├── xrepl-ops-navigation-tests.lfe        (NEW)
│   ├── xrepl-ops-documentation-tests.lfe     (NEW)
│   ├── xrepl-ops-debugging-tests.lfe         (NEW)
│   ├── xrepl-ops-testing-tests.lfe           (NEW)
│   ├── xrepl-ops-refactoring-tests.lfe       (NEW)
│   ├── xrepl-ops-compilation-tests.lfe       (NEW)
│   ├── xrepl-ops-beam-tests.lfe              (NEW)
│   └── xrepl-ops-advanced-tests.lfe          (NEW)
└── docs/
    └── xrepl-unified-spec.md                 (reference spec)
```

## Implementation Order by Category

### Phase 0: Foundation Updates (Do This First)

**Goal**: Update shared infrastructure to support binary keys and alias handling.

#### Task 0.1: Update `xrepl-protocol-types.lfe`

**Current Issues**:
- Uses atom keys in some places
- Field name alias support is minimal
- No helper for building dual-field responses

**Required Changes**:

1. **Update `ensure-binary-key/1` to be the primary key converter**:
```lisp
(defun ensure-binary-key (key)
  "Convert any key to binary for MessagePack compatibility.
  
  Args:
    key: Atom, binary, or string key
    
  Returns:
    Binary key"
  (cond
    ((is_binary key) key)
    ((is_atom key) (atom_to_binary key 'utf8))
    ((is_list key) (list_to_binary key))
    ('true (error (tuple 'badarg key)))))
```

2. **Add new helper for field aliases**:
```lisp
(defun get-field-any (map keys)
  "Get field trying multiple key names (for aliases).
  
  Args:
    map: Message map
    keys: List of possible key names (atoms or binaries)
    
  Returns:
    Value or 'undefined
    
  Example:
    (get-field-any msg '(candidate text))  ; tries both names"
  (get-field-any map keys 'undefined))

(defun get-field-any (map keys default)
  "Get field trying multiple key names with default.
  
  Args:
    map: Message map
    keys: List of possible key names (atoms or binaries)
    default: Default value if not found
    
  Returns:
    Value or default"
  (case keys
    ('() default)
    ((cons key rest)
     (let ((bin-key (ensure-binary-key key)))
       (case (maps:get bin-key map 'undefined)
         ('undefined (get-field-any map rest default))
         (value value))))))
```

3. **Add helper for building dual-field maps**:
```lisp
(defun put-aliased (map key1 key2 value)
  "Put value under two key names for compatibility.
  
  Args:
    map: Map to update
    key1: Primary key name (atom)
    key2: Alias key name (atom)
    value: Value to store
    
  Returns:
    Updated map with both keys
    
  Example:
    (put-aliased #m() 'candidate 'text #\"hello\")
    ; => #m(#\"candidate\" #\"hello\" #\"text\" #\"hello\")"
  (let ((bin-key1 (ensure-binary-key key1))
        (bin-key2 (ensure-binary-key key2))
        (bin-val (if (is_atom value)
                   (atom_to_binary value 'utf8)
                   value)))
    (maps:put bin-key2 bin-val
              (maps:put bin-key1 bin-val map))))

(defun put-aliased-list (map key1 key2 values)
  "Put list value under two key names for compatibility.
  
  Args:
    map: Map to update
    key1: Primary key name (atom)
    key2: Alias key name (atom)  
    values: List of values (will NOT be converted to binary)
    
  Returns:
    Updated map with both keys"
  (let ((bin-key1 (ensure-binary-key key1))
        (bin-key2 (ensure-binary-key key2)))
    (maps:put bin-key2 values
              (maps:put bin-key1 values map))))
```

4. **Update `get-field` functions to use binary keys**:
```lisp
(defun get-field (map key)
  "Get field from message map.
  
  Args:
    map: Message map
    key: Field name (atom)
    
  Returns:
    Value or 'undefined"
  (get-field map key 'undefined))

(defun get-field (map key default)
  "Get field from message map with default.
  
  MessagePack sends keys as binaries, so we convert and check.
  
  Args:
    map: Message map
    key: Field name (atom)
    default: Default value if not found
    
  Returns:
    Value or default"
  (let ((bin-key (ensure-binary-key key)))
    (maps:get bin-key map default)))
```

5. **Update `ensure-binary` to handle more types**:
```lisp
(defun ensure-binary (value)
  "Convert value to binary.
  
  Args:
    value: Any Erlang term
    
  Returns:
    Binary representation"
  (cond
    ((is_binary value) value)
    ((is_list value) 
     ;; Check if it's a string (list of integers)
     (if (io_lib:printable_list value)
       (list_to_binary value)
       ;; It's a list structure - format it
       (list_to_binary (io_lib:format "~p" (list value)))))
    ((is_atom value) (atom_to_binary value 'utf8))
    ((is_integer value) (integer_to_binary value))
    ((is_float value) (float_to_binary value))
    ('true (list_to_binary (io_lib:format "~p" (list value))))))
```

6. **Add new helper for optional fields with aliases**:
```lisp
(defun maybe-put-aliased (map key1 key2 opts opt-key)
  "Conditionally put aliased field if present in opts.
  
  Args:
    map: Map to potentially update
    key1: Primary key name
    key2: Alias key name
    opts: Options map
    opt-key: Key to look for in opts
    
  Returns:
    Updated map if field present, otherwise original map
    
  Example:
    (maybe-put-aliased base 'session 'session_id opts 'session)"
  (case (get-field opts opt-key 'undefined)
    ('undefined map)
    (value (put-aliased map key1 key2 (ensure-binary value)))))
```

#### Task 0.2: Update Test Infrastructure

**File**: `test/xrepl-protocol-types-tests.lfe`

Add tests for new helpers:

```lisp
(deftest get-field-any-finds-first
  (let ((msg #m(#"candidate" #"hello")))
    (is-equal #"hello" (xrepl-protocol-types:get-field-any msg '(candidate text)))))

(deftest get-field-any-finds-second
  (let ((msg #m(#"text" #"hello")))
    (is-equal #"hello" (xrepl-protocol-types:get-field-any msg '(candidate text)))))

(deftest get-field-any-returns-default
  (let ((msg #m()))
    (is-equal 'not-found 
              (xrepl-protocol-types:get-field-any msg '(candidate text) 'not-found))))

(deftest put-aliased-creates-both-keys
  (let ((result (xrepl-protocol-types:put-aliased #m() 'candidate 'text #"hello")))
    (is-equal #"hello" (maps:get #"candidate" result))
    (is-equal #"hello" (maps:get #"text" result))))

(deftest ensure-binary-key-conversions
  (is-equal #"test" (xrepl-protocol-types:ensure-binary-key 'test))
  (is-equal #"test" (xrepl-protocol-types:ensure-binary-key #"test"))
  (is-equal #"test" (xrepl-protocol-types:ensure-binary-key "test")))
```

### Phase 1: Migrate Existing Modules

**Goal**: Rename and update existing operation modules to use binary keys and support field aliases.

---

#### Task 1.1: Migrate Evaluation Operations

**Source**: `src/xrepl-protocol-eval.lfe` → **Target**: `src/xrepl-ops-evaluation.lfe`

**Operations to Implement**:
1. `eval` - Evaluate code
2. `eval_multiple` - Evaluate multiple forms
3. `eval_at_point` - Context-aware evaluation
4. `stream_eval` / `eval_stream` - Streaming evaluation
5. `interrupt` - Stop evaluation
6. `cancel` - Cancel operation
7. `load_file` - Load file

**Migration Steps**:

1. **Rename module**:
```lisp
(defmodule xrepl-ops-evaluation
  "Evaluation operation protocol messages.
  
  This module defines all code evaluation operations in the xrepl protocol."
  (export
   ;; eval operation
   (eval-request 1)
   (eval-response 1) (eval-response 2)
   (eval-action-response 2)
   (eval-error 2)
   ;; eval_multiple operation
   (eval-multiple-request 1)
   (eval-multiple-response 1) (eval-multiple-response 2)
   ;; eval_at_point operation
   (eval-at-point-request 1)
   ;; stream_eval / eval_stream operations
   (stream-eval-request 1)
   (stream-eval-intermediate 2)
   (stream-eval-final 1) (stream-eval-final 2)
   ;; interrupt operation
   (interrupt-request 1)
   (interrupt-response 2)
   ;; cancel operation
   (cancel-request 1)
   (cancel-response 2)
   ;; load_file operation
   (load-file-request 1)
   (load-file-response 1) (load-file-response 2)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)))
```

2. **Update `eval-request` to use binary keys**:
```lisp
(defun eval-request (opts)
  "Build an eval request message.
  
  Options:
    code: Code to evaluate (required, string or binary)
    session: Session ID (optional, binary or string)
    file: File name for error reporting (optional)
    line: Starting line number (optional)
    column: Starting column (optional)
    
  Returns:
    Request message map with binary keys
    
  Examples:
    (eval-request #m(code \"(+ 1 2)\"))
    (eval-request #m(code \"(+ 1 2)\" session \"abc123\"))"
  (case (xrepl-protocol-types:get-required opts 'code)
    (`#(ok ,code)
     (let* ((base (maps:put #"op" #"eval"
                           (maps:put #"code" (xrepl-protocol-types:ensure-binary code)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased 
                           base 'session 'session opts 'session))
            (with-file (xrepl-protocol-types:maybe-put-aliased
                        with-session 'file 'file opts 'file))
            (with-line (case (xrepl-protocol-types:get-field opts 'line 'undefined)
                        ('undefined with-file)
                        (line (maps:put #"line" line with-file))))
            (with-column (case (xrepl-protocol-types:get-field opts 'column 'undefined)
                          ('undefined with-line)
                          (col (maps:put #"column" col with-line)))))
       with-column))
    (error error)))
```

3. **Update `eval-response` to generate BOTH field aliases**:
```lisp
(defun eval-response (value)
  "Build successful eval response.
  
  Args:
    value: Evaluation result (binary or string)
    
  Returns:
    Response message map with binary keys"
  (eval-response value #m()))

(defun eval-response (value opts)
  "Build successful eval response with options.
  
  Args:
    value: Evaluation result (binary or string)
    opts: Options map (session, ns/namespace, etc.)
    
  Returns:
    Response message map with binary keys
    
  Examples:
    (eval-response \"42\")
    (eval-response \"42\" #m(session \"abc123\" ns \"user\"))"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"value" (xrepl-protocol-types:ensure-binary value)
                                 #m())))
         ;; Add session with alias
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session))
         ;; Add namespace (ns is primary, namespace is alias)
         (with-ns (xrepl-protocol-types:maybe-put-aliased
                   with-session 'ns 'namespace opts 'ns)))
    with-ns))
```

4. **Add new `eval-multiple-request` function**:
```lisp
(defun eval-multiple-request (opts)
  "Build an eval_multiple request message.
  
  Options:
    forms: Array of code strings (required)
    session: Session ID (optional)
    
  Returns:
    Request message map with binary keys
    
  Example:
    (eval-multiple-request #m(forms '(\"(+ 1 2)\" \"(* 3 4)\")))"
  (case (xrepl-protocol-types:get-required opts 'forms)
    (`#(ok ,forms)
     (let* ((base (maps:put #"op" #"eval_multiple"
                           (maps:put #"forms" forms #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))
```

5. **Add `eval-multiple-response` function**:
```lisp
(defun eval-multiple-response (results)
  "Build eval_multiple response.
  
  Args:
    results: List of result maps with value/status/error fields
    
  Returns:
    Response message map"
  (eval-multiple-response results #m()))

(defun eval-multiple-response (results opts)
  "Build eval_multiple response with options.
  
  Args:
    results: List of result maps
    opts: Options (session, etc.)
    
  Returns:
    Response message map
    
  Example:
    (eval-multiple-response 
      '(#m(value \"3\" status \"ok\")
        #m(status \"error\" error \"bad syntax\"))
      #m(session \"abc123\"))"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"results" results #m())))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))
```

6. **Add `eval-at-point-request` function**:
```lisp
(defun eval-at-point-request (opts)
  "Build eval_at_point request with context.
  
  Options:
    code: Code to evaluate (required)
    file: File path (required)
    line: Line number (required)
    column: Column number (required)
    session: Session ID (optional)
    context: Context map with buffer_contents, surrounding_forms (optional)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'code)
    (`#(ok ,code)
     (case (xrepl-protocol-types:get-required opts 'file)
       (`#(ok ,file)
        (case (xrepl-protocol-types:get-required opts 'line)
          (`#(ok ,line)
           (case (xrepl-protocol-types:get-required opts 'column)
             (`#(ok ,column)
              (let* ((base (maps:put #"op" #"eval_at_point"
                                    (maps:put #"code" (xrepl-protocol-types:ensure-binary code)
                                             (maps:put #"file" (xrepl-protocol-types:ensure-binary file)
                                                      (maps:put #"line" line
                                                               (maps:put #"column" column #m()))))))
                     (with-session (xrepl-protocol-types:maybe-put-aliased
                                    base 'session 'session opts 'session))
                     (with-context (case (xrepl-protocol-types:get-field opts 'context 'undefined)
                                    ('undefined with-session)
                                    (ctx (maps:put #"context" ctx with-session)))))
                with-context))
             (error error)))
          (error error)))
       (error error)))
    (error error)))
```

7. **Add streaming evaluation functions**:
```lisp
(defun stream-eval-request (opts)
  "Build stream_eval or eval_stream request.
  
  Options:
    code: Code to evaluate (required)
    session: Session ID (optional)
    op_name: 'stream_eval or 'eval_stream (optional, defaults to stream_eval)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'code)
    (`#(ok ,code)
     (let* ((op-name (xrepl-protocol-types:get-field opts 'op_name 'stream_eval))
            (base (maps:put #"op" (xrepl-protocol-types:ensure-binary op-name)
                           (maps:put #"code" (xrepl-protocol-types:ensure-binary code) #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun stream-eval-intermediate (output stream-type)
  "Build intermediate streaming output response.
  
  Args:
    output: Output string
    stream-type: 'stdout or 'stderr
    
  Returns:
    Intermediate response map"
  (stream-eval-intermediate output stream-type #m()))

(defun stream-eval-intermediate (output stream-type opts)
  "Build intermediate streaming output response with options.
  
  Args:
    output: Output string
    stream-type: 'stdout or 'stderr
    opts: Options (session, etc.)
    
  Returns:
    Intermediate response map"
  (let* ((base (maps:put #"status" #"streaming"
                        (maps:put #"output" (xrepl-protocol-types:ensure-binary output)
                                 (maps:put #"stream" (xrepl-protocol-types:ensure-binary stream-type)
                                          #m()))))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

(defun stream-eval-final (value)
  "Build final streaming evaluation response.
  
  Args:
    value: Final evaluation result
    
  Returns:
    Final response map"
  (stream-eval-final value #m()))

(defun stream-eval-final (value opts)
  "Build final streaming evaluation response with options.
  
  Args:
    value: Final evaluation result
    opts: Options (session, etc.)
    
  Returns:
    Final response map"
  (eval-response value opts))  ;; Same as regular eval response
```

8. **Add interrupt operations**:
```lisp
(defun interrupt-request (opts)
  "Build interrupt request.
  
  Options:
    session: Session ID (optional)
    
  Returns:
    Request message map"
  (let* ((base (maps:put #"op" #"interrupt" #m()))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))

(defun interrupt-response (interrupted opts)
  "Build interrupt response.
  
  Args:
    interrupted: Boolean indicating if interruption succeeded
    opts: Options (session, message, etc.)
    
  Returns:
    Response message map"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"interrupted" interrupted #m())))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session))
         (with-message (case (xrepl-protocol-types:get-field opts 'message 'undefined)
                        ('undefined with-session)
                        (msg (maps:put #"message" (xrepl-protocol-types:ensure-binary msg)
                                      with-session)))))
    with-message))
```

9. **Add cancel operations**:
```lisp
(defun cancel-request (opts)
  "Build cancel request.
  
  Options:
    cancel_id: ID of operation to cancel (required)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'cancel_id)
    (`#(ok ,cancel-id)
     (maps:put #"op" #"cancel"
              (maps:put #"cancel_id" (xrepl-protocol-types:ensure-binary cancel-id) #m())))
    (error error)))

(defun cancel-response (cancelled target-id)
  "Build cancel response.
  
  Args:
    cancelled: Boolean indicating if cancellation succeeded
    target-id: ID of the cancelled operation
    
  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"cancelled" cancelled
                    (maps:put #"target_id" (xrepl-protocol-types:ensure-binary target-id)
                             #m()))))
```

10. **Add load_file operations**:
```lisp
(defun load-file-request (opts)
  "Build load_file request.
  
  Options:
    file: File path (required)
    session: Session ID (optional)
    file_name: Name for error reporting (optional)
    file_contents: Optional file contents to send directly (optional)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'file)
    (`#(ok ,file)
     (let* ((base (maps:put #"op" #"load_file"
                           (maps:put #"file" (xrepl-protocol-types:ensure-binary file) #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session))
            (with-file-name (case (xrepl-protocol-types:get-field opts 'file_name 'undefined)
                             ('undefined with-session)
                             (fn (maps:put #"file_name" (xrepl-protocol-types:ensure-binary fn)
                                          with-session))))
            (with-contents (case (xrepl-protocol-types:get-field opts 'file_contents 'undefined)
                            ('undefined with-file-name)
                            (contents (maps:put #"file_contents" 
                                               (xrepl-protocol-types:ensure-binary contents)
                                               with-file-name)))))
       with-contents))
    (error error)))

(defun load-file-response (value)
  "Build load_file response.
  
  Args:
    value: Result of loading file
    
  Returns:
    Response message map"
  (load-file-response value #m()))

(defun load-file-response (value opts)
  "Build load_file response with options.
  
  Args:
    value: Result of loading file
    opts: Options (session, warnings, etc.)
    
  Returns:
    Response message map"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"value" (xrepl-protocol-types:ensure-binary value) #m())))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session))
         (with-warnings (case (xrepl-protocol-types:get-field opts 'warnings 'undefined)
                         ('undefined with-session)
                         (warnings (maps:put #"warnings" warnings with-session)))))
    with-warnings))
```

11. **Update `parse-request` to handle all operations and binary keys**:
```lisp
(defun parse-request (message)
  "Parse and validate evaluation request message.
  
  Args:
    message: Message map (with binary keys from MessagePack)
    
  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-protocol-types:get-field message 'op)))
      (cond
        ;; eval operation
        ((or (== op #"eval") (== op 'eval))
         (let ((code (xrepl-protocol-types:get-field message 'code)))
           (if (or (== code 'undefined) (not (or (is_binary code) (is_list code))))
             (tuple 'error 'missing-code)
             (tuple 'ok (maps:put #"op" #"eval"
                                 (maps:put #"code" code
                                          (maps:put #"session" 
                                                   (xrepl-protocol-types:get-field message 'session 'undefined)
                                                   #m())))))))
        
        ;; eval_multiple operation
        ((or (== op #"eval_multiple") (== op 'eval_multiple))
         (let ((forms (xrepl-protocol-types:get-field message 'forms)))
           (if (or (== forms 'undefined) (not (is_list forms)))
             (tuple 'error 'missing-forms)
             (tuple 'ok (maps:put #"op" #"eval_multiple"
                                 (maps:put #"forms" forms
                                          (maps:put #"session"
                                                   (xrepl-protocol-types:get-field message 'session 'undefined)
                                                   #m())))))))
        
        ;; eval_at_point operation
        ((or (== op #"eval_at_point") (== op 'eval_at_point))
         (let ((code (xrepl-protocol-types:get-field message 'code))
               (file (xrepl-protocol-types:get-field message 'file))
               (line (xrepl-protocol-types:get-field message 'line))
               (column (xrepl-protocol-types:get-field message 'column)))
           (if (or (== code 'undefined) (== file 'undefined) 
                   (== line 'undefined) (== column 'undefined))
             (tuple 'error 'missing-required-field)
             (tuple 'ok (maps:put #"op" #"eval_at_point"
                                 (maps:put #"code" code
                                          (maps:put #"file" file
                                                   (maps:put #"line" line
                                                            (maps:put #"column" column
                                                                     (maps:put #"session"
                                                                              (xrepl-protocol-types:get-field message 'session 'undefined)
                                                                              #m()))))))))))
        
        ;; stream_eval / eval_stream operations
        ((or (== op #"stream_eval") (== op 'stream_eval)
             (== op #"eval_stream") (== op 'eval_stream))
         (let ((code (xrepl-protocol-types:get-field message 'code)))
           (if (or (== code 'undefined) (not (or (is_binary code) (is_list code))))
             (tuple 'error 'missing-code)
             (tuple 'ok (maps:put #"op" op
                                 (maps:put #"code" code
                                          (maps:put #"session"
                                                   (xrepl-protocol-types:get-field message 'session 'undefined)
                                                   #m())))))))
        
        ;; interrupt operation
        ((or (== op #"interrupt") (== op 'interrupt))
         (tuple 'ok (maps:put #"op" #"interrupt"
                             (maps:put #"session"
                                      (xrepl-protocol-types:get-field message 'session 'undefined)
                                      #m()))))
        
        ;; cancel operation
        ((or (== op #"cancel") (== op 'cancel))
         (let ((cancel-id (xrepl-protocol-types:get-field message 'cancel_id)))
           (if (== cancel-id 'undefined)
             (tuple 'error 'missing-cancel-id)
             (tuple 'ok (maps:put #"op" #"cancel"
                                 (maps:put #"cancel_id" cancel-id #m()))))))
        
        ;; load_file operation
        ((or (== op #"load_file") (== op 'load_file))
         (let ((file (xrepl-protocol-types:get-field message 'file)))
           (if (== file 'undefined)
             (tuple 'error 'missing-file)
             (tuple 'ok (maps:put #"op" #"load_file"
                                 (maps:put #"file" file
                                          (maps:put #"session"
                                                   (xrepl-protocol-types:get-field message 'session 'undefined)
                                                   #m())))))))
        
        ;; Invalid operation
        ('true (tuple 'error 'invalid-evaluation-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))
```

12. **Update `parse-response` to handle all operations with field aliases**:
```lisp
(defun parse-response (op message)
  "Parse evaluation operation response message.
  
  Args:
    op: Operation type (eval, eval_multiple, etc.)
    message: Response message map (with binary keys)
    
  Returns:
    #(ok result-map) | #(error error-info)"
  (let ((status (xrepl-protocol-types:get-field message 'status)))
    (cond
      ;; Done status
      ((or (== status #"done") (== status 'done))
       (case op
         ;; eval response
         ((or #"eval" 'eval)
          ;; Check for action response
          (let ((action (xrepl-protocol-types:get-field message 'action 'undefined)))
            (if (== action 'undefined)
              ;; Normal value response - try both value field names
              (let ((value (xrepl-protocol-types:get-field-any message '(value result))))
                (tuple 'ok (maps:put #"value" value
                                    (maps:put #"session" 
                                             (xrepl-protocol-types:get-field message 'session 'undefined)
                                             #m()))))
              ;; Action response
              (tuple 'ok (maps:put #"action" action
                                  (maps:put #"session"
                                           (xrepl-protocol-types:get-field message 'session 'undefined)
                                           #m()))))))
         
         ;; eval_multiple response
         ((or #"eval_multiple" 'eval_multiple)
          (let ((results (xrepl-protocol-types:get-field message 'results)))
            (tuple 'ok (maps:put #"results" results
                                (maps:put #"session"
                                         (xrepl-protocol-types:get-field message 'session 'undefined)
                                         #m())))))
         
         ;; eval_at_point response (same as eval)
         ((or #"eval_at_point" 'eval_at_point)
          (let ((value (xrepl-protocol-types:get-field-any message '(value result))))
            (tuple 'ok (maps:put #"value" value
                                (maps:put #"session"
                                         (xrepl-protocol-types:get-field message 'session 'undefined)
                                         #m())))))
         
         ;; stream_eval / eval_stream final response
         ((or #"stream_eval" 'stream_eval #"eval_stream" 'eval_stream)
          (let ((value (xrepl-protocol-types:get-field-any message '(value result))))
            (tuple 'ok (maps:put #"value" value
                                (maps:put #"session"
                                         (xrepl-protocol-types:get-field message 'session 'undefined)
                                         #m())))))
         
         ;; interrupt response
         ((or #"interrupt" 'interrupt)
          (let ((interrupted (xrepl-protocol-types:get-field message 'interrupted)))
            (tuple 'ok (maps:put #"interrupted" interrupted
                                (maps:put #"session"
                                         (xrepl-protocol-types:get-field message 'session 'undefined)
                                         (maps:put #"message"
                                                  (xrepl-protocol-types:get-field message 'message 'undefined)
                                                  #m()))))))
         
         ;; cancel response
         ((or #"cancel" 'cancel)
          (let ((cancelled (xrepl-protocol-types:get-field message 'cancelled))
                (target-id (xrepl-protocol-types:get-field message 'target_id)))
            (tuple 'ok (maps:put #"cancelled" cancelled
                                (maps:put #"target_id" target-id #m())))))
         
         ;; load_file response
         ((or #"load_file" 'load_file)
          (let ((value (xrepl-protocol-types:get-field-any message '(value result))))
            (tuple 'ok (maps:put #"value" value
                                (maps:put #"session"
                                         (xrepl-protocol-types:get-field message 'session 'undefined)
                                         (maps:put #"warnings"
                                                  (xrepl-protocol-types:get-field message 'warnings 'undefined)
                                                  #m()))))))
         
         (_ (tuple 'error 'unknown-operation))))
      
      ;; Streaming status
      ((or (== status #"streaming") (== status 'streaming))
       (let ((output (xrepl-protocol-types:get-field message 'output))
             (stream (xrepl-protocol-types:get-field message 'stream)))
         (tuple 'ok (maps:put #"status" #"streaming"
                             (maps:put #"output" output
                                      (maps:put #"stream" stream
                                               (maps:put #"session"
                                                        (xrepl-protocol-types:get-field message 'session 'undefined)
                                                        #m())))))))
      
      ;; Error status
      ((or (== status #"error") (== status 'error))
       (tuple 'error (xrepl-protocol-types:get-field message 'error)))
      
      ;; Invalid status
      ('true (tuple 'error 'invalid-status)))))
```

13. **Keep validation functions simple**:
```lisp
(defun valid-request? (message)
  "Check if message is a valid evaluation request.
  
  Args:
    message: Message map
    
  Returns:
    true | false"
  (case (parse-request message)
    (`#(ok ,_) 'true)
    (_ 'false)))

(defun valid-response? (op message)
  "Check if message is a valid evaluation response.
  
  Args:
    op: Operation type
    message: Message map
    
  Returns:
    true | false"
  (let ((status (xrepl-protocol-types:get-field message 'status)))
    (or (== status #"done")
        (== status 'done)
        (== status #"error")
        (== status 'error)
        (== status #"streaming")
        (== status 'streaming))))
```

**Test File**: `test/xrepl-ops-evaluation-tests.lfe`

Migrate all tests from `xrepl-protocol-eval-tests.lfe` and add new tests:

```lisp
(defmodule xrepl-ops-evaluation-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; eval operation tests

(deftest eval-request-minimal
  (let ((req (xrepl-ops-evaluation:eval-request #m(code "(+ 1 2)"))))
    (is-equal #"eval" (maps:get #"op" req))
    (is-equal #"(+ 1 2)" (maps:get #"code" req))))

(deftest eval-request-with-session
  (let ((req (xrepl-ops-evaluation:eval-request #m(code "(+ 1 2)" session "abc123"))))
    (is-equal #"eval" (maps:get #"op" req))
    (is-equal #"(+ 1 2)" (maps:get #"code" req))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest eval-request-with-location
  (let ((req (xrepl-ops-evaluation:eval-request 
               #m(code "(+ 1 2)" file "test.lfe" line 10 column 5))))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest eval-response-simple
  (let ((resp (xrepl-ops-evaluation:eval-response "42")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"42" (maps:get #"value" resp))))

(deftest eval-response-with-session-and-ns
  (let ((resp (xrepl-ops-evaluation:eval-response "42" #m(session "abc" ns "user"))))
    (is-equal #"42" (maps:get #"value" resp))
    (is-equal #"abc" (maps:get #"session" resp))
    ;; Both ns and namespace should be present (aliases)
    (is-equal #"user" (maps:get #"ns" resp))
    (is-equal #"user" (maps:get #"namespace" resp))))

(deftest eval-action-response-switch
  (let ((resp (xrepl-ops-evaluation:eval-action-response 'switch #m(session "new-id"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"switch" (maps:get #"action" resp))
    (is-equal #"new-id" (maps:get #"session" resp))))

;;; eval_multiple operation tests

(deftest eval-multiple-request-construction
  (let ((req (xrepl-ops-evaluation:eval-multiple-request 
               #m(forms '("(+ 1 2)" "(* 3 4)")))))
    (is-equal #"eval_multiple" (maps:get #"op" req))
    (is-equal '("(+ 1 2)" "(* 3 4)") (maps:get #"forms" req))))

(deftest eval-multiple-response-construction
  (let* ((results '(#m(value "3" status "ok") 
                    #m(value "12" status "ok")))
         (resp (xrepl-ops-evaluation:eval-multiple-response results)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal results (maps:get #"results" resp))))

;;; eval_at_point operation tests

(deftest eval-at-point-request-construction
  (let ((req (xrepl-ops-evaluation:eval-at-point-request
               #m(code "(+ 1 2)" file "test.lfe" line 10 column 5))))
    (is-equal #"eval_at_point" (maps:get #"op" req))
    (is-equal #"(+ 1 2)" (maps:get #"code" req))
    (is-equal #"test.lfe" (maps:get #"file" req))
    (is-equal 10 (maps:get #"line" req))
    (is-equal 5 (maps:get #"column" req))))

(deftest eval-at-point-with-context
  (let ((req (xrepl-ops-evaluation:eval-at-point-request
               #m(code "(+ 1 2)" 
                  file "test.lfe" 
                  line 10 
                  column 5
                  context #m(buffer_contents "...")))))
    (is (is_map (maps:get #"context" req)))))

;;; stream_eval operation tests

(deftest stream-eval-request-construction
  (let ((req (xrepl-ops-evaluation:stream-eval-request #m(code "(dotimes (i 10) (print i))"))))
    (is-equal #"stream_eval" (maps:get #"op" req))))

(deftest stream-eval-request-alias
  (let ((req (xrepl-ops-evaluation:stream-eval-request 
               #m(code "(print 'hi')" op_name 'eval_stream))))
    (is-equal #"eval_stream" (maps:get #"op" req))))

(deftest stream-eval-intermediate-response
  (let ((resp (xrepl-ops-evaluation:stream-eval-intermediate "output line" 'stdout)))
    (is-equal #"streaming" (maps:get #"status" resp))
    (is-equal #"output line" (maps:get #"output" resp))
    (is-equal #"stdout" (maps:get #"stream" resp))))

(deftest stream-eval-final-response
  (let ((resp (xrepl-ops-evaluation:stream-eval-final "42")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"42" (maps:get #"value" resp))))

;;; interrupt operation tests

(deftest interrupt-request-construction
  (let ((req (xrepl-ops-evaluation:interrupt-request #m())))
    (is-equal #"interrupt" (maps:get #"op" req))))

(deftest interrupt-request-with-session
  (let ((req (xrepl-ops-evaluation:interrupt-request #m(session "abc123"))))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest interrupt-response-success
  (let ((resp (xrepl-ops-evaluation:interrupt-response 'true #m())))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 'true (maps:get #"interrupted" resp))))

(deftest interrupt-response-with-message
  (let ((resp (xrepl-ops-evaluation:interrupt-response 'true #m(message "Interrupted"))))
    (is-equal #"Interrupted" (maps:get #"message" resp))))

;;; cancel operation tests

(deftest cancel-request-construction
  (let ((req (xrepl-ops-evaluation:cancel-request #m(cancel_id "req-123"))))
    (is-equal #"cancel" (maps:get #"op" req))
    (is-equal #"req-123" (maps:get #"cancel_id" req))))

(deftest cancel-response-construction
  (let ((resp (xrepl-ops-evaluation:cancel-response 'true "req-123")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 'true (maps:get #"cancelled" resp))
    (is-equal #"req-123" (maps:get #"target_id" resp))))

;;; load_file operation tests

(deftest load-file-request-minimal
  (let ((req (xrepl-ops-evaluation:load-file-request #m(file "test.lfe"))))
    (is-equal #"load_file" (maps:get #"op" req))
    (is-equal #"test.lfe" (maps:get #"file" req))))

(deftest load-file-request-with-contents
  (let ((req (xrepl-ops-evaluation:load-file-request 
               #m(file "test.lfe" file_contents "(defun foo () 42)"))))
    (is-equal #"(defun foo () 42)" (maps:get #"file_contents" req))))

(deftest load-file-response-simple
  (let ((resp (xrepl-ops-evaluation:load-file-response "ok")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"ok" (maps:get #"value" resp))))

(deftest load-file-response-with-warnings
  (let* ((warnings '(#m(line 5 message "unused variable")))
         (resp (xrepl-ops-evaluation:load-file-response "ok" #m(warnings warnings))))
    (is-equal warnings (maps:get #"warnings" resp))))

;;; Parsing tests

(deftest parse-eval-request
  (let ((msg #m(#"op" #"eval" #"code" #"(+ 1 2)")))
    (case (xrepl-ops-evaluation:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"eval" (maps:get #"op" parsed))
       (is-equal #"(+ 1 2)" (maps:get #"code" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-interrupt-request
  (let ((msg #m(#"op" #"interrupt" #"session" #"abc")))
    (case (xrepl-ops-evaluation:parse-request msg)
      (`#(ok ,parsed)
       (is-equal #"interrupt" (maps:get #"op" parsed)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-eval-response-value
  (let ((msg #m(#"status" #"done" #"value" #"42")))
    (case (xrepl-ops-evaluation:parse-response #"eval" msg)
      (`#(ok ,result)
       (is-equal #"42" (maps:get #"value" result)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-eval-response-action
  (let ((msg #m(#"status" #"done" #"action" #"switch" #"session" #"new")))
    (case (xrepl-ops-evaluation:parse-response #"eval" msg)
      (`#(ok ,result)
       (is-equal #"switch" (maps:get #"action" result)))
      (other
       (error (tuple 'unexpected-result other))))))

(deftest parse-streaming-response
  (let ((msg #m(#"status" #"streaming" #"output" #"line" #"stream" #"stdout")))
    (case (xrepl-ops-evaluation:parse-response #"stream_eval" msg)
      (`#(ok ,result)
       (is-equal #"streaming" (maps:get #"status" result))
       (is-equal #"line" (maps:get #"output" result)))
      (other
       (error (tuple 'unexpected-result other))))))

;;; Validation tests

(deftest valid-request-checks
  (is (xrepl-ops-evaluation:valid-request? #m(#"op" #"eval" #"code" #"(+ 1 2)")))
  (is (xrepl-ops-evaluation:valid-request? #m(#"op" #"interrupt")))
  (is (xrepl-ops-evaluation:valid-request? #m(#"op" #"load_file" #"file" #"test.lfe")))
  (is-not (xrepl-ops-evaluation:valid-request? #m(#"op" #"eval"))))  ;; missing code

(deftest valid-response-checks
  (is (xrepl-ops-evaluation:valid-response? #"eval" #m(#"status" #"done" #"value" #"42")))
  (is (xrepl-ops-evaluation:valid-response? #"stream_eval" #m(#"status" #"streaming")))
  (is (xrepl-ops-evaluation:valid-response? #"interrupt" #m(#"status" #"done")))
  (is-not (xrepl-ops-evaluation:valid-response? #"eval" #m(#"status" #"invalid"))))

;;; Round-trip tests

(deftest eval-request-round-trip
  (let* ((req (xrepl-ops-evaluation:eval-request #m(code "(+ 1 2)" session "test")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"eval" (maps:get #"op" decoded))
    (is-equal #"(+ 1 2)" (maps:get #"code" decoded))
    (is-equal #"test" (maps:get #"session" decoded))
    (is (xrepl-ops-evaluation:valid-request? decoded))))

(deftest load-file-request-round-trip
  (let* ((req (xrepl-ops-evaluation:load-file-request #m(file "test.lfe")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    (is-equal #"load_file" (maps:get #"op" decoded))
    (is (xrepl-ops-evaluation:valid-request? decoded))))

(deftest eval-response-round-trip-with-aliases
  (let* ((resp (xrepl-ops-evaluation:eval-response "42" #m(session "test" ns "user")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    ;; Both aliases should be present
    (is-equal #"user" (maps:get #"ns" decoded))
    (is-equal #"user" (maps:get #"namespace" decoded))
    (is-equal #"test" (maps:get #"session" decoded))))
```

---

#### Task 1.2: Migrate Session Operations

**Source**: `src/xrepl-protocol-session.lfe` → **Target**: `src/xrepl-ops-session.lfe`

**Operations to Implement**:
1. `clone` - Create new session
2. `close` - Close session
3. `ls_sessions` - List sessions
4. `switch_namespace` - Switch module context
5. `session_info` - Get session information
6. `clear_session` - Clear session state
7. `upload_history` - Upload client history

**Migration Steps**:

1. **Rename module and update to use binary keys**:
```lisp
(defmodule xrepl-ops-session
  "Session management operation protocol messages."
  (export
   ;; clone operation
   (clone-request 0)
   (clone-response 1)
   ;; close operation
   (close-request 0) (close-request 1)
   (close-response 0)
   ;; ls_sessions operation
   (ls-sessions-request 0)
   (ls-sessions-response 1)
   ;; switch_namespace operation
   (switch-namespace-request 1)
   (switch-namespace-response 1)
   ;; session_info operation
   (session-info-request 1)
   (session-info-response 1)
   ;; clear_session operation
   (clear-session-request 1)
   (clear-session-response 1)
   ;; upload_history operation
   (upload-history-request 1)
   (upload-history-response 2)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))
```

2. **Update clone operations to use binary keys**:
```lisp
(defun clone-request ()
  "Build a clone (create new session) request.
  
  Returns:
    Request message map with binary keys"
  #m(#"op" #"clone"))

(defun clone-response (new-session-id)
  "Build a successful clone response.
  
  Args:
    new-session-id: ID of the newly created session (string or binary)
    
  Returns:
    Response message map with binary keys"
  (maps:put #"status" #"done"
           (maps:put #"new_session" (xrepl-protocol-types:ensure-binary new-session-id)
                    #m())))
```

3. **Update close operations**:
```lisp
(defun close-request ()
  "Build a close request (closes current session).
  
  Returns:
    Request message map with binary keys"
  #m(#"op" #"close"))

(defun close-request (session-id)
  "Build a close request for a specific session.
  
  Args:
    session-id: ID of session to close (string or binary)
    
  Returns:
    Request message map with binary keys"
  (maps:put #"op" #"close"
           (maps:put #"session" (xrepl-protocol-types:ensure-binary session-id)
                    #m())))

(defun close-response ()
  "Build a successful close response.
  
  Returns:
    Response message map with binary keys"
  #m(#"status" #"done"))
```

4. **Update ls_sessions operations with field aliases**:
```lisp
(defun ls-sessions-request ()
  "Build a list sessions request.
  
  Returns:
    Request message map with binary keys"
  #m(#"op" #"ls_sessions"))

(defun ls-sessions-response (sessions)
  "Build a list sessions response.
  
  Args:
    sessions: List of session maps with id, active, created/created_at fields
    
  Returns:
    Response message map with binary keys
    
  Note: Each session should have BOTH 'created' and 'created_at' fields
        for Emacs/VSCode compatibility.
    
  Example session format:
    #m(#\"id\" #\"session-1\" 
       #\"active\" true 
       #\"created\" 1234567890
       #\"created_at\" 1234567890)"
  (maps:put #"status" #"done"
           (maps:put #"sessions" sessions
                    #m())))
```

5. **Add new switch_namespace operations**:
```lisp
(defun switch-namespace-request (opts)
  "Build a switch_namespace request.
  
  Options:
    namespace: Module name (required)
    session: Session ID (optional)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'namespace)
    (`#(ok ,namespace)
     (let* ((base (maps:put #"op" #"switch_namespace"
                           (maps:put #"namespace" (xrepl-protocol-types:ensure-binary namespace)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun switch-namespace-response (namespace)
  "Build a switch_namespace response.
  
  Args:
    namespace: Confirmed new namespace (string or binary)
    
  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"namespace" (xrepl-protocol-types:ensure-binary namespace)
                    #m())))
```

6. **Add session_info operations**:
```lisp
(defun session-info-request (opts)
  "Build a session_info request.
  
  Options:
    session: Session ID (required)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'session)
    (`#(ok ,session)
     (maps:put #"op" #"session_info"
              (maps:put #"session" (xrepl-protocol-types:ensure-binary session)
                       #m())))
    (error error)))

(defun session-info-response (info)
  "Build a session_info response.
  
  Args:
    info: Session info map with id, created, last_active, namespace, bindings, loaded_modules
    
  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"session" info
                    #m())))
```

7. **Add clear_session operations**:
```lisp
(defun clear-session-request (opts)
  "Build a clear_session request.
  
  Options:
    session: Session ID (required)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'session)
    (`#(ok ,session)
     (maps:put #"op" #"clear_session"
              (maps:put #"session" (xrepl-protocol-types:ensure-binary session)
                       #m())))
    (error error)))

(defun clear-session-response (cleared)
  "Build a clear_session response.
  
  Args:
    cleared: Boolean indicating if session was cleared
    
  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"cleared" cleared
                    #m())))
```

8. **Update upload_history operations with field aliases**:
```lisp
(defun upload-history-request (opts)
  "Build an upload_history request.
  
  Options:
    commands: List of command strings (required) - also accepts 'history' as alias
    session: Session ID (optional)
    
  Returns:
    Request message map"
  ;; Try both 'commands' and 'history' field names
  (let ((cmds (xrepl-protocol-types:get-field-any opts '(commands history) 'undefined)))
    (if (== cmds 'undefined)
      (tuple 'error (tuple 'missing-required-field 'commands))
      (let* ((base (xrepl-protocol-types:put-aliased-list #m() 'commands 'history cmds))
             (with-op (maps:put #"op" #"upload_history" base))
             (with-session (xrepl-protocol-types:maybe-put-aliased
                            with-op 'session 'session opts 'session)))
        with-session))))

(defun upload-history-response (uploaded-count opts)
  "Build an upload_history response.
  
  Args:
    uploaded-count: Number of commands uploaded
    opts: Options map (session, etc.)
    
  Returns:
    Response message map"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"uploaded" uploaded-count
                                 #m())))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))
```

9. **Update parse-request to handle all operations with binary keys**:
```lisp
(defun parse-request (message)
  "Parse and validate session operation request message.
  
  Args:
    message: Message map (with binary keys from MessagePack)
    
  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-protocol-types:get-field message 'op)))
      (cond
        ;; clone operation
        ((or (== op #"clone") (== op 'clone))
         (tuple 'ok #m(#"op" #"clone")))

        ;; close operation
        ((or (== op #"close") (== op 'close))
         (tuple 'ok (maps:put #"op" #"close"
                             (maps:put #"session"
                                      (xrepl-protocol-types:get-field message 'session 'undefined)
                                      #m()))))

        ;; ls_sessions operation
        ((or (== op #"ls_sessions") (== op 'ls_sessions))
         (tuple 'ok #m(#"op" #"ls_sessions")))

        ;; switch_namespace operation
        ((or (== op #"switch_namespace") (== op 'switch_namespace))
         (let ((namespace (xrepl-protocol-types:get-field message 'namespace)))
           (if (== namespace 'undefined)
             (tuple 'error 'missing-namespace)
             (tuple 'ok (maps:put #"op" #"switch_namespace"
                                 (maps:put #"namespace" namespace
                                          (maps:put #"session"
                                                   (xrepl-protocol-types:get-field message 'session 'undefined)
                                                   #m())))))))

        ;; session_info operation
        ((or (== op #"session_info") (== op 'session_info))
         (let ((session (xrepl-protocol-types:get-field message 'session)))
           (if (== session 'undefined)
             (tuple 'error 'missing-session)
             (tuple 'ok (maps:put #"op" #"session_info"
                                 (maps:put #"session" session #m()))))))

        ;; clear_session operation
        ((or (== op #"clear_session") (== op 'clear_session))
         (let ((session (xrepl-protocol-types:get-field message 'session)))
           (if (== session 'undefined)
             (tuple 'error 'missing-session)
             (tuple 'ok (maps:put #"op" #"clear_session"
                                 (maps:put #"session" session #m()))))))

        ;; upload_history operation
        ((or (== op #"upload_history") (== op 'upload_history))
         ;; Try both 'commands' and 'history' field names
         (let ((commands (xrepl-protocol-types:get-field-any message '(commands history))))
           (if (or (== commands 'undefined) (not (is_list commands)))
             (tuple 'error 'missing-commands)
             (tuple 'ok (maps:put #"op" #"upload_history"
                                 (maps:put #"commands" commands
                                          (maps:put #"session"
                                                   (xrepl-protocol-types:get-field message 'session 'undefined)
                                                   #m())))))))

        ;; Invalid operation
        ('true (tuple 'error 'invalid-session-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))
```

10. **Update parse-response to handle field aliases**:
```lisp
(defun parse-response (op message)
  "Parse session operation response message.
  
  Args:
    op: Operation type (clone, close, ls_sessions, etc.)
    message: Response message map (with binary keys)
    
  Returns:
    #(ok result-map) | #(error error-info)"
  (let ((status (xrepl-protocol-types:get-field message 'status)))
    (cond
      ((or (== status #"done") (== status 'done))
       (case op
         ;; clone
         ((or #"clone" 'clone)
          (tuple 'ok (maps:put #"new_session" 
                              (xrepl-protocol-types:get-field message 'new_session)
                              #m())))

         ;; close
         ((or #"close" 'close)
          (tuple 'ok #m()))

         ;; ls_sessions
         ((or #"ls_sessions" 'ls_sessions)
          (tuple 'ok (maps:put #"sessions" 
                              (xrepl-protocol-types:get-field message 'sessions)
                              #m())))

         ;; switch_namespace
         ((or #"switch_namespace" 'switch_namespace)
          (tuple 'ok (maps:put #"namespace"
                              (xrepl-protocol-types:get-field message 'namespace)
                              #m())))

         ;; session_info
         ((or #"session_info" 'session_info)
          (tuple 'ok (maps:put #"session"
                              (xrepl-protocol-types:get-field message 'session)
                              #m())))

         ;; clear_session
         ((or #"clear_session" 'clear_session)
          (tuple 'ok (maps:put #"cleared"
                              (xrepl-protocol-types:get-field message 'cleared)
                              #m())))

         ;; upload_history
         ((or #"upload_history" 'upload_history)
          (tuple 'ok (maps:put #"uploaded" 
                              (xrepl-protocol-types:get-field message 'uploaded)
                              (maps:put #"session"
                                       (xrepl-protocol-types:get-field message 'session 'undefined)
                                       #m()))))

         (_ (tuple 'error 'unknown-operation))))

      ((or (== status #"error") (== status 'error))
       (tuple 'error (xrepl-protocol-types:get-field message 'error)))

      ('true (tuple 'error 'invalid-status)))))
```

**Test File**: `test/xrepl-ops-session-tests.lfe`

Migrate and expand tests:

```lisp
(defmodule xrepl-ops-session-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; clone tests

(deftest clone-request-construction
  (let ((req (xrepl-ops-session:clone-request)))
    (is-equal #"clone" (maps:get #"op" req))))

(deftest clone-response-construction
  (let ((resp (xrepl-ops-session:clone-response "new-session-123")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"new-session-123" (maps:get #"new_session" resp))))

;;; switch_namespace tests

(deftest switch-namespace-request-construction
  (let ((req (xrepl-ops-session:switch-namespace-request #m(namespace "my-module"))))
    (is-equal #"switch_namespace" (maps:get #"op" req))
    (is-equal #"my-module" (maps:get #"namespace" req))))

(deftest switch-namespace-response-construction
  (let ((resp (xrepl-ops-session:switch-namespace-response "my-module")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"my-module" (maps:get #"namespace" resp))))

;;; session_info tests

(deftest session-info-request-construction
  (let ((req (xrepl-ops-session:session-info-request #m(session "abc123"))))
    (is-equal #"session_info" (maps:get #"op" req))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest session-info-response-construction
  (let* ((info #m(#"id" #"abc123" 
                  #"created" 1234567890
                  #"namespace" #"user"))
         (resp (xrepl-ops-session:session-info-response info)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal info (maps:get #"session" resp))))

;;; clear_session tests

(deftest clear-session-request-construction
  (let ((req (xrepl-ops-session:clear-session-request #m(session "abc123"))))
    (is-equal #"clear_session" (maps:get #"op" req))
    (is-equal #"abc123" (maps:get #"session" req))))

(deftest clear-session-response-construction
  (let ((resp (xrepl-ops-session:clear-session-response 'true)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 'true (maps:get #"cleared" resp))))

;;; upload_history tests with aliases

(deftest upload-history-request-with-commands
  (let* ((cmds '("cmd1" "cmd2"))
         (req (xrepl-ops-session:upload-history-request #m(commands cmds))))
    (is-equal #"upload_history" (maps:get #"op" req))
    ;; Both field names should be present
    (is-equal cmds (maps:get #"commands" req))
    (is-equal cmds (maps:get #"history" req))))

(deftest upload-history-request-with-history-alias
  (let* ((cmds '("cmd1" "cmd2"))
         (req (xrepl-ops-session:upload-history-request #m(history cmds))))
    (is-equal #"upload_history" (maps:get #"op" req))
    ;; Both field names should be present
    (is-equal cmds (maps:get #"commands" req))
    (is-equal cmds (maps:get #"history" req))))

(deftest upload-history-response-with-session
  (let ((resp (xrepl-ops-session:upload-history-response 5 #m(session "abc123"))))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal 5 (maps:get #"uploaded" resp))
    (is-equal #"abc123" (maps:get #"session" resp))))

;;; ls_sessions tests with timestamp aliases

(deftest ls-sessions-response-with-timestamp-aliases
  (let* ((sessions (list #m(#"id" #"s1" 
                            #"active" 'true 
                            #"created" 1234567890
                            #"created_at" 1234567890)))
         (resp (xrepl-ops-session:ls-sessions-response sessions)))
    (is-equal #"done" (maps:get #"status" resp))
    (let* ((returned-sessions (maps:get #"sessions" resp))
           (first-session (lists:nth 1 returned-sessions)))
      ;; Both timestamp fields should be present
      (is-equal 1234567890 (maps:get #"created" first-session))
      (is-equal 1234567890 (maps:get #"created_at" first-session)))))

;;; Round-trip tests

(deftest upload-history-round-trip-with-aliases
  (let* ((cmds '("cmd1" "cmd2"))
         (req (xrepl-ops-session:upload-history-request #m(commands cmds session "test")))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode req))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    ;; Both field aliases should survive encoding
    (is-equal cmds (maps:get #"commands" decoded))
    (is-equal cmds (maps:get #"history" decoded))
    (is (xrepl-ops-session:valid-request? decoded))))
```

---

#### Task 1.3: Migrate System Operations

**Source**: `src/xrepl-protocol-system.lfe` → **Target**: `src/xrepl-ops-system.lfe`

**Operations to Implement**:
1. `ping` - Health check
2. `describe` - Server capabilities
3. `capabilities` - Detailed capabilities
4. `version` - Version information
5. `loaded_modules` - List loaded modules
6. `module_info` - Get module information

**Migration Steps**:

1. **Rename module and update exports**:
```lisp
(defmodule xrepl-ops-system
  "System operation protocol messages."
  (export
   ;; ping operation
   (ping-request 0)
   (ping-response 0) (ping-response 1)
   ;; describe operation
   (describe-request 0)
   (describe-response 1)
   ;; capabilities operation
   (capabilities-request 0)
   (capabilities-response 1)
   ;; version operation
   (version-request 0)
   (version-response 1)
   ;; loaded_modules operation
   (loaded-modules-request 1)
   (loaded-modules-response 1)
   ;; module_info operation
   (module-info-request 1)
   (module-info-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))
```

2. **Update ping operations with binary keys**:
```lisp
(defun ping-request ()
  "Build a ping request.
  
  Returns:
    Request message map with binary keys"
  #m(#"op" #"ping"))

(defun ping-response ()
  "Build a ping response with current timestamp.
  
  Returns:
    Response message map with binary keys"
  (maps:put #"status" #"done"
           (maps:put #"pong" 'true
                    (maps:put #"timestamp" (erlang:system_time 'second)
                             #m()))))

(defun ping-response (timestamp)
  "Build a ping response with specified timestamp.
  
  Args:
    timestamp: Unix timestamp in seconds
    
  Returns:
    Response message map with binary keys"
  (maps:put #"status" #"done"
           (maps:put #"pong" 'true
                    (maps:put #"timestamp" timestamp
                             #m()))))
```

3. **Update describe operations with field aliases**:
```lisp
(defun describe-request ()
  "Build a describe (capabilities) request.
  
  Returns:
    Request message map with binary keys"
  #m(#"op" #"describe"))

(defun describe-response (opts)
  "Build a describe response.
  
  Options:
    versions: Map of version info (xrepl, lfe, erlang, protocol)
    ops: List of supported operations (can be list or map)
    transports: List of supported transport types
    aux: Auxiliary info map (current_ns, etc.)
    
  Returns:
    Response message map with binary keys
    
  Example:
    (describe-response
      #m(versions #m(xrepl \"0.1.0\" lfe \"2.2.0\" erlang \"26\" protocol \"1.0\")
         ops '(eval clone close)
         transports '(tcp unix stdio)
         aux #m(current_ns \"user\")))"
  (let* ((versions (xrepl-protocol-types:get-field opts 'versions #m()))
         (ops (xrepl-protocol-types:get-field opts 'ops '()))
         (transports (xrepl-protocol-types:get-field opts 'transports '()))
         (aux (xrepl-protocol-types:get-field opts 'aux 'undefined))
         (base (maps:put #"status" #"done"
                        (maps:put #"versions" versions
                                 (maps:put #"ops" ops
                                          (maps:put #"transports" transports
                                                   #m()))))))
    (if (== aux 'undefined)
      base
      (maps:put #"aux" aux base))))
```

4. **Add capabilities operations**:
```lisp
(defun capabilities-request ()
  "Build a capabilities request.
  
  Returns:
    Request message map with binary keys"
  #m(#"op" #"capabilities"))

(defun capabilities-response (opts)
  "Build a capabilities response.
  
  Options:
    ops: List of operation detail maps
    features: Map of feature flags
    
  Returns:
    Response message map
    
  Example:
    (capabilities-response
      #m(ops '(#m(#\"name\" #\"eval\" 
                  #\"description\" #\"Evaluate code\"
                  #\"required_fields\" '(#\"code\")
                  #\"optional_fields\" '(#\"session\" #\"file\")))
         features #m(#\"hot_reload\" true 
                     #\"debugging\" true)))"
  (let ((ops (xrepl-protocol-types:get-field opts 'ops '()))
        (features (xrepl-protocol-types:get-field opts 'features #m())))
    (maps:put #"status" #"done"
             (maps:put #"capabilities"
                      (maps:put #"ops" ops
                               (maps:put #"features" features
                                        #m()))
                      #m()))))
```

5. **Add version operations**:
```lisp
(defun version-request ()
  "Build a version request.
  
  Returns:
    Request message map with binary keys"
  #m(#"op" #"version"))

(defun version-response (versions)
  "Build a version response.
  
  Args:
    versions: Map with xrepl, lfe, erlang, protocol versions
    
  Returns:
    Response message map
    
  Example:
    (version-response #m(xrepl \"0.1.0\" lfe \"2.2.0\" erlang \"26\" protocol \"1.0\"))"
  (maps:put #"status" #"done"
           (maps:put #"versions" versions
                    #m())))
```

6. **Add loaded_modules operations**:
```lisp
(defun loaded-modules-request (opts)
  "Build a loaded_modules request.
  
  Options:
    session: Session ID (required)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'session)
    (`#(ok ,session)
     (maps:put #"op" #"loaded_modules"
              (maps:put #"session" (xrepl-protocol-types:ensure-binary session)
                       #m())))
    (error error)))

(defun loaded-modules-response (modules)
  "Build a loaded_modules response.
  
  Args:
    modules: List of module maps with name, path, exports
    
  Returns:
    Response message map
    
  Example:
    (loaded-modules-response 
      '(#m(#\"name\" #\"lists\" #\"path\" #\"/usr/lib/...\" #\"exports\" 42)))"
  (maps:put #"status" #"done"
           (maps:put #"modules" modules
                    #m())))
```

7. **Add module_info operations**:
```lisp
(defun module-info-request (opts)
  "Build a module_info request.
  
  Options:
    module: Module name (required)
    session: Session ID (optional)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'module)
    (`#(ok ,module)
     (let* ((base (maps:put #"op" #"module_info"
                           (maps:put #"module" (xrepl-protocol-types:ensure-binary module)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session)))
       with-session))
    (error error)))

(defun module-info-response (info)
  "Build a module_info response.
  
  Args:
    info: Module info map with name, path, exports, attributes, etc.
    
  Returns:
    Response message map
    
  Example:
    (module-info-response
      #m(#\"name\" #\"lists\"
         #\"path\" #\"/usr/lib/...\"
         #\"exports\" '(#m(#\"name\" #\"map\" #\"arity\" 2))
         #\"md5\" #\"...\"))"
  (maps:put #"status" #"done"
           (maps:put #"module" info
                    #m())))
```

8. **Update parse-request**:
```lisp
(defun parse-request (message)
  "Parse and validate system operation request message.
  
  Args:
    message: Message map (with binary keys from MessagePack)
    
  Returns:
    #(ok parsed-request) | #(error reason)"
  (try
    (let ((op (xrepl-protocol-types:get-field message 'op)))
      (cond
        ;; ping operation
        ((or (== op #"ping") (== op 'ping))
         (tuple 'ok #m(#"op" #"ping")))

        ;; describe operation
        ((or (== op #"describe") (== op 'describe))
         (tuple 'ok #m(#"op" #"describe")))

        ;; capabilities operation
        ((or (== op #"capabilities") (== op 'capabilities))
         (tuple 'ok #m(#"op" #"capabilities")))

        ;; version operation
        ((or (== op #"version") (== op 'version))
         (tuple 'ok #m(#"op" #"version")))

        ;; loaded_modules operation
        ((or (== op #"loaded_modules") (== op 'loaded_modules))
         (let ((session (xrepl-protocol-types:get-field message 'session)))
           (if (== session 'undefined)
             (tuple 'error 'missing-session)
             (tuple 'ok (maps:put #"op" #"loaded_modules"
                                 (maps:put #"session" session #m()))))))

        ;; module_info operation
        ((or (== op #"module_info") (== op 'module_info))
         (let ((module (xrepl-protocol-types:get-field message 'module)))
           (if (== module 'undefined)
             (tuple 'error 'missing-module)
             (tuple 'ok (maps:put #"op" #"module_info"
                                 (maps:put #"module" module
                                          (maps:put #"session"
                                                   (xrepl-protocol-types:get-field message 'session 'undefined)
                                                   #m())))))))

        ;; Invalid operation
        ('true (tuple 'error 'invalid-system-request))))
    (catch
      ((tuple _ reason _)
       (tuple 'error reason)))))
```

**Test File**: `test/xrepl-ops-system-tests.lfe` - Similar migration pattern with binary keys and alias testing.

---

### Phase 2: Implement Code Intelligence Operations

**Goal**: Implement all code intelligence operations from the spec.

#### Task 2.1: Create Intelligence Operations Module

**New File**: `src/xrepl-ops-intelligence.lfe`

**Operations to Implement**:
1. `complete` - Code completion
2. `complete_context` - Context-aware completion
3. `signature` / `signature_help` - Signature help
4. `eldoc` - Function signature at point
5. `eldoc_batch` - Batch eldoc queries
6. `type_info` - Type information
7. `format` / `format_code` - Format code
8. `apropos` - Search symbols
9. `indent_info` - Get indentation information
10. `buffer_analysis` - Analyze entire buffer
11. `highlight_regions` - Get semantic highlighting

**Implementation Pattern**:

```lisp
(defmodule xrepl-ops-intelligence
  "Code intelligence operation protocol messages."
  (export
   ;; complete operation
   (complete-request 1)
   (complete-response 1) (complete-response 2)
   ;; complete_context operation
   (complete-context-request 1)
   (complete-context-response 2)
   ;; signature / signature_help operations (aliases)
   (signature-request 1)
   (signature-response 1) (signature-response 2)
   ;; eldoc operation
   (eldoc-request 1)
   (eldoc-response 1) (eldoc-response 2)
   ;; eldoc_batch operation
   (eldoc-batch-request 1)
   (eldoc-batch-response 1)
   ;; type_info operation
   (type-info-request 1)
   (type-info-response 1)
   ;; format / format_code operations (aliases)
   (format-request 1)
   (format-response 1)
   ;; apropos operation
   (apropos-request 1)
   (apropos-response 1)
   ;; indent_info operation
   (indent-info-request 1)
   (indent-info-response 1)
   ;; buffer_analysis operation
   (buffer-analysis-request 1)
   (buffer-analysis-response 1)
   ;; highlight_regions operation
   (highlight-regions-request 1)
   (highlight-regions-response 1)
   ;; Parsing and validation
   (parse-request 1)
   (parse-response 2)
   (valid-request? 1)
   (valid-response? 2)
   ;; Errors
   (error 2)))
```

**Key Implementation Notes**:

1. **Completion with aliases**:
```lisp
(defun complete-request (opts)
  "Build a complete request.
  
  Options:
    prefix: Completion prefix (required)
    session: Session ID (optional)
    cursor: Cursor position in prefix - Emacs style (optional)
    position: Cursor position in code - VSCode style (optional)
    code: Full code context - VSCode style (optional)
    context: Context map with type, module, etc. (optional)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'prefix)
    (`#(ok ,prefix)
     (let* ((base (maps:put #"op" #"complete"
                           (maps:put #"prefix" (xrepl-protocol-types:ensure-binary prefix)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session))
            (with-cursor (case (xrepl-protocol-types:get-field opts 'cursor 'undefined)
                          ('undefined with-session)
                          (cursor (maps:put #"cursor" cursor with-session))))
            (with-position (case (xrepl-protocol-types:get-field opts 'position 'undefined)
                            ('undefined with-cursor)
                            (pos (maps:put #"position" pos with-cursor))))
            (with-code (case (xrepl-protocol-types:get-field opts 'code 'undefined)
                        ('undefined with-position)
                        (code (maps:put #"code" (xrepl-protocol-types:ensure-binary code)
                                       with-position))))
            (with-context (case (xrepl-protocol-types:get-field opts 'context 'undefined)
                           ('undefined with-code)
                           (ctx (maps:put #"context" ctx with-code)))))
       with-context))
    (error error)))

(defun complete-response (candidates)
  "Build a complete response.
  
  Args:
    candidates: List of completion candidate maps
    
  Returns:
    Response message map"
  (complete-response candidates #m()))

(defun complete-response (candidates opts)
  "Build a complete response with options.
  
  Args:
    candidates: List of completion candidate maps
    opts: Options (session, etc.)
    
  Returns:
    Response message map with BOTH 'candidates' and 'completions' fields
    
  Note: Each candidate should have BOTH field name styles:
    - candidate/text (completion text)
    - doc/documentation (documentation)
    - detail (VSCode brief description)
    
  Example candidate:
    #m(#\"candidate\" #\"map\"
       #\"text\" #\"map\"
       #\"type\" #\"function\"
       #\"signature\" #\"map/2\"
       #\"module\" #\"lists\"
       #\"arity\" 2
       #\"doc\" #\"Apply function to list\"
       #\"documentation\" #\"Apply function to list\"
       #\"detail\" #\"lists:map/2\"
       #\"insert_text\" #\"map\"
       #\"sort_text\" #\"map\")"
  (let* ((base (maps:put #"status" #"done"
                        ;; Put candidates under BOTH field names
                        (xrepl-protocol-types:put-aliased-list #m() 
                                                               'candidates 
                                                               'completions 
                                                               candidates)))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))
```

2. **Signature help with operation name aliases**:
```lisp
(defun signature-request (opts)
  "Build a signature or signature_help request.
  
  Options:
    symbol: Symbol to get signature for (optional)
    file: File path (optional)
    line: Line number (optional)
    column: Column number (optional)
    code: Code context (optional)
    position: Position in code (optional)
    contents: Buffer contents (optional)
    session: Session ID (optional)
    op_name: 'signature or 'signature_help (optional, defaults to signature)
    
  Returns:
    Request message map"
  (let* ((op-name (xrepl-protocol-types:get-field opts 'op_name 'signature))
         (base (maps:put #"op" (xrepl-protocol-types:ensure-binary op-name) #m()))
         (with-symbol (case (xrepl-protocol-types:get-field opts 'symbol 'undefined)
                       ('undefined base)
                       (sym (maps:put #"symbol" (xrepl-protocol-types:ensure-binary sym) base))))
         (with-file (case (xrepl-protocol-types:get-field opts 'file 'undefined)
                     ('undefined with-symbol)
                     (file (maps:put #"file" (xrepl-protocol-types:ensure-binary file)
                                    with-symbol))))
         (with-line (case (xrepl-protocol-types:get-field opts 'line 'undefined)
                     ('undefined with-file)
                     (line (maps:put #"line" line with-file))))
         (with-column (case (xrepl-protocol-types:get-field opts 'column 'undefined)
                       ('undefined with-line)
                       (col (maps:put #"column" col with-line))))
         (with-code (case (xrepl-protocol-types:get-field opts 'code 'undefined)
                     ('undefined with-column)
                     (code (maps:put #"code" (xrepl-protocol-types:ensure-binary code)
                                    with-column))))
         (with-position (case (xrepl-protocol-types:get-field opts 'position 'undefined)
                         ('undefined with-code)
                         (pos (maps:put #"position" pos with-code))))
         (with-contents (case (xrepl-protocol-types:get-field opts 'contents 'undefined)
                         ('undefined with-position)
                         (cont (maps:put #"contents" (xrepl-protocol-types:ensure-binary cont)
                                        with-position))))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        with-contents 'session 'session opts 'session)))
    with-session))

(defun signature-response (signatures)
  "Build a signature response.
  
  Args:
    signatures: List of signature maps
    
  Returns:
    Response message map"
  (signature-response signatures #m()))

(defun signature-response (signatures opts)
  "Build a signature response with options.
  
  Args:
    signatures: List of signature maps
    opts: Options (session, etc.)
    
  Returns:
    Response message map
    
  Note: Each signature should have BOTH field name styles:
    - label/signature (signature string)
    - documentation/doc (documentation)
    - parameters with documentation/doc for each parameter
    
  Example signature:
    #m(#\"label\" #\"map(Fun, List)\"
       #\"signature\" #\"map(Fun, List)\"
       #\"parameters\" '(#m(#\"label\" #\"Fun\" 
                           #\"documentation\" #\"Function to apply\"
                           #\"doc\" #\"Function to apply\")
                        #m(#\"label\" #\"List\"
                           #\"documentation\" #\"List to process\"
                           #\"doc\" #\"List to process\"))
       #\"active_parameter\" 0
       #\"documentation\" #\"Apply function to each element\"
       #\"doc\" #\"Apply function to each element\")"
  (let* ((base (maps:put #"status" #"done"
                        (maps:put #"signatures" signatures #m())))
         (with-session (xrepl-protocol-types:maybe-put-aliased
                        base 'session 'session opts 'session)))
    with-session))
```

3. **Format operation with aliases**:
```lisp
(defun format-request (opts)
  "Build a format or format_code request.
  
  Options:
    code: Code to format (required)
    session: Session ID (optional)
    options: Formatting options map (optional)
    op_name: 'format or 'format_code (optional, defaults to format)
    
  Returns:
    Request message map"
  (case (xrepl-protocol-types:get-required opts 'code)
    (`#(ok ,code)
     (let* ((op-name (xrepl-protocol-types:get-field opts 'op_name 'format))
            (base (maps:put #"op" (xrepl-protocol-types:ensure-binary op-name)
                           (maps:put #"code" (xrepl-protocol-types:ensure-binary code)
                                    #m())))
            (with-session (xrepl-protocol-types:maybe-put-aliased
                           base 'session 'session opts 'session))
            (with-options (case (xrepl-protocol-types:get-field opts 'options 'undefined)
                           ('undefined with-session)
                           (fmt-opts (maps:put #"options" fmt-opts with-session)))))
       with-options))
    (error error)))

(defun format-response (formatted)
  "Build a format response.
  
  Args:
    formatted: Formatted code string
    
  Returns:
    Response message map"
  (maps:put #"status" #"done"
           (maps:put #"formatted" (xrepl-protocol-types:ensure-binary formatted)
                    #m())))
```

**Test File**: `test/xrepl-ops-intelligence-tests.lfe`

```lisp
(defmodule xrepl-ops-intelligence-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; complete operation tests

(deftest complete-request-minimal
  (let ((req (xrepl-ops-intelligence:complete-request #m(prefix "lis"))))
    (is-equal #"complete" (maps:get #"op" req))
    (is-equal #"lis" (maps:get #"prefix" req))))

(deftest complete-request-with-context
  (let ((req (xrepl-ops-intelligence:complete-request 
               #m(prefix "map" 
                  session "abc"
                  context #m(#"type" #"function" #"module" #"lists")))))
    (is-equal #"abc" (maps:get #"session" req))
    (is (is_map (maps:get #"context" req)))))

(deftest complete-response-has-both-field-names
  (let* ((candidates '(#m(#"candidate" #"map" #"text" #"map" #"type" #"function")))
         (resp (xrepl-ops-intelligence:complete-response candidates)))
    (is-equal #"done" (maps:get #"status" resp))
    ;; Both 'candidates' and 'completions' should be present
    (is-equal candidates (maps:get #"candidates" resp))
    (is-equal candidates (maps:get #"completions" resp))))

;;; signature operation tests

(deftest signature-request-with-symbol
  (let ((req (xrepl-ops-intelligence:signature-request #m(symbol "map"))))
    (is-equal #"signature" (maps:get #"op" req))
    (is-equal #"map" (maps:get #"symbol" req))))

(deftest signature-request-alias-signature-help
  (let ((req (xrepl-ops-intelligence:signature-request 
               #m(symbol "map" op_name 'signature_help))))
    (is-equal #"signature_help" (maps:get #"op" req))))

(deftest signature-response-construction
  (let* ((sigs '(#m(#"label" #"map(Fun, List)"
                    #"signature" #"map(Fun, List)"
                    #"parameters" '()
                    #"documentation" #"Apply function"
                    #"doc" #"Apply function")))
         (resp (xrepl-ops-intelligence:signature-response sigs)))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal sigs (maps:get #"signatures" resp))))

;;; eldoc operation tests

(deftest eldoc-request-construction
  (let ((req (xrepl-ops-intelligence:eldoc-request #m(symbol "map" session "abc"))))
    (is-equal #"eldoc" (maps:get #"op" req))
    (is-equal #"map" (maps:get #"symbol" req))
    (is-equal #"abc" (maps:get #"session" req))))

;;; format operation tests

(deftest format-request-minimal
  (let ((req (xrepl-ops-intelligence:format-request #m(code "(  +   1    2  )"))))
    (is-equal #"format" (maps:get #"op" req))
    (is-equal #"(  +   1    2  )" (maps:get #"code" req))))

(deftest format-request-alias-format-code
  (let ((req (xrepl-ops-intelligence:format-request 
               #m(code "(+ 1 2)" op_name 'format_code))))
    (is-equal #"format_code" (maps:get #"op" req))))

(deftest format-response-construction
  (let ((resp (xrepl-ops-intelligence:format-response "(+ 1 2)")))
    (is-equal #"done" (maps:get #"status" resp))
    (is-equal #"(+ 1 2)" (maps:get #"formatted" resp))))

;;; Round-trip tests

(deftest complete-round-trip-with-aliases
  (let* ((candidates '(#m(#"candidate" #"test" #"text" #"test")))
         (resp (xrepl-ops-intelligence:complete-response candidates))
         (`#(ok ,encoded) (xrepl-protocol-msgpack:encode resp))
         (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
    ;; Both field aliases should survive encoding
    (is-equal candidates (maps:get #"candidates" decoded))
    (is-equal candidates (maps:get #"completions" decoded))))
```

---

### Phase 3+: Remaining Operation Categories

For each remaining category, follow the same pattern:

1. **Create module** `xrepl-ops-<category>.lfe`
2. **Implement all operations** from the spec for that category
3. **Use binary keys throughout**
4. **Support field name aliases** where specified
5. **Create comprehensive test file**
6. **Test round-trip encoding/decoding**

**Remaining Categories**:

- **Navigation** (`xrepl-ops-navigation.lfe`): find_definition, find_references, list_definitions, symbol_at_point, workspace_symbols
- **Documentation** (`xrepl-ops-documentation.lfe`): doc, module_doc, search_docs, generate_doc, module_summary
- **Debugging** (`xrepl-ops-debugging.lfe`): set_breakpoint, clear_breakpoint, list_breakpoints, stacktrace, inspect_locals, eval_in_frame, step
- **Testing** (`xrepl-ops-testing.lfe`): test_run, test_coverage, test_rerun_failures, generate_tests
- **Refactoring** (`xrepl-ops-refactoring.lfe`): rename_symbol, extract_function, inline_function
- **Compilation** (`xrepl-ops-compilation.lfe`): compile_file, compile_project, lint, dependencies, build
- **BEAM** (`xrepl-ops-beam.lfe`): hot_reload, list_processes, inspect_process, trace_calls, system_info, observer_data
- **Advanced** (`xrepl-ops-advanced.lfe`): macroexpand, macroexpand_all, list_macros, history, search_history, profile_start, profile_stop, benchmark, snippets, expand_snippet, generate_function, suggest_improvements, share_session, restore_session, text_document_did_open, text_document_did_change, text_document_did_close

---

## Common Patterns and Helpers

### Pattern 1: Optional Session Field

Many operations have an optional session field:

```lisp
(let* ((base (maps:put #"op" #"operation_name" #m()))
       (with-session (xrepl-protocol-types:maybe-put-aliased
                      base 'session 'session opts 'session)))
  with-session)
```

### Pattern 2: Required Field with Error Handling

```lisp
(case (xrepl-protocol-types:get-required opts 'field_name)
  (`#(ok ,value)
   ;; Build request with value
   ...)
  (error error))
```

### Pattern 3: Building Response with Field Aliases

```lisp
(let* ((base (maps:put #"status" #"done" #m()))
       ;; Add aliased field
       (with-alias (xrepl-protocol-types:put-aliased 
                    base 'primary_name 'alias_name value)))
  with-alias)
```

### Pattern 4: Building Response with List Field Aliases

```lisp
(let* ((base (maps:put #"status" #"done" #m()))
       ;; Add aliased list field
       (with-list (xrepl-protocol-types:put-aliased-list
                   base 'primary_name 'alias_name list-value)))
  with-list)
```

### Pattern 5: Parsing Request with Binary Keys

```lisp
(let ((op (xrepl-protocol-types:get-field message 'op)))
  (cond
    ((or (== op #"operation_name") (== op 'operation_name))
     (let ((field1 (xrepl-protocol-types:get-field message 'field1))
           (field2 (xrepl-protocol-types:get-field-any message '(alias1 alias2))))
       (if (or (== field1 'undefined) (== field2 'undefined))
         (tuple 'error 'missing-required-field)
         (tuple 'ok (maps:put #"op" #"operation_name"
                             (maps:put #"field1" field1
                                      (maps:put #"field2" field2 #m())))))))
    ...))
```

### Pattern 6: Parsing Response with Field Aliases

```lisp
(case op
  ((or #"operation_name" 'operation_name)
   ;; Try multiple field names for compatibility
   (let ((value (xrepl-protocol-types:get-field-any message '(primary_name alias_name))))
     (tuple 'ok (maps:put #"result" value #m())))))
```

---

## Testing Checklist for Each Module

For every new operation module, ensure tests cover:

- [ ] **Request construction** with minimal options
- [ ] **Request construction** with all optional fields
- [ ] **Request construction** with field name aliases (if applicable)
- [ ] **Response construction** with minimal data
- [ ] **Response construction** with all optional fields
- [ ] **Response construction** generates BOTH field name aliases (if applicable)
- [ ] **Parse request** with binary keys from MessagePack
- [ ] **Parse request** handles both operation name forms (if applicable)
- [ ] **Parse request** accepts field name aliases in input
- [ ] **Parse response** with binary keys
- [ ] **Parse response** handles field name aliases in input
- [ ] **Validation** - valid-request? returns true for valid requests
- [ ] **Validation** - valid-request? returns false for invalid requests
- [ ] **Validation** - valid-response? returns true for valid responses
- [ ] **Round-trip** encode/decode preserves data
- [ ] **Round-trip** encode/decode preserves field name aliases
- [ ] **Error cases** - missing required fields
- [ ] **Error cases** - invalid field types

---

## Documentation Requirements

Each module should have:

1. **Module docstring** explaining the category and operations
2. **Function docstrings** with:
   - Brief description
   - Args/Options documentation
   - Return value documentation
   - Examples showing typical usage
3. **Inline comments** for complex logic
4. **Field alias notes** where applicable

Example docstring format:

```lisp
(defun operation-request (opts)
  "Build an operation_name request.
  
  Options:
    field1: Description of field1 (required, type)
    field2: Description of field2 (optional, type)
    session: Session ID (optional, binary or string)
    
  Returns:
    Request message map with binary keys
    
  Examples:
    (operation-request #m(field1 \"value\"))
    (operation-request #m(field1 \"value\" field2 42 session \"abc123\"))
    
  Notes:
    - Supports both 'field2_alias1' and 'field2_alias2' as field names
    - Binary keys used throughout for MessagePack efficiency"
  ...)
```

---

## Build and Test Workflow

After implementing each category:

1. **Compile the module**:
   ```bash
   rebar3 compile
   ```

2. **Run tests**:
   ```bash
   rebar3 ltest
   ```

3. **Check test coverage**:
   ```bash
   rebar3 cover
   ```

4. **Fix any failures** before moving to next category

5. **Commit with descriptive message**:
   ```bash
   git add src/xrepl-ops-<category>.lfe test/xrepl-ops-<category>-tests.lfe
   git commit -m "Implement <category> operations"
   ```

---

## Implementation Workflow for Claude Code

For each category implementation task:

### Step 1: Review the Spec
- Read the relevant section in `docs/xrepl-unified-spec.md`
- Identify all operations in the category
- Note any field name aliases
- Note any special response formats

### Step 2: Create Module File
- Create `src/xrepl-ops-<category>.lfe`
- Set up module with all exports
- Add module docstring

### Step 3: Implement Operations
- For each operation, implement:
  - Request builder function(s)
  - Response builder function(s)
  - Error builder (if category-specific errors needed)
- Follow the common patterns documented above
- Use binary keys throughout
- Support field name aliases where specified

### Step 4: Implement Parsing
- Implement `parse-request/1`
- Implement `parse-response/2`
- Handle all operations in the category
- Handle field name aliases in input

### Step 5: Implement Validation
- Implement `valid-request?/1`
- Implement `valid-response?/2`
- Keep simple (true/false only)

### Step 6: Create Test File
- Create `test/xrepl-ops-<category>-tests.lfe`
- Follow test checklist above
- Test all operations
- Test field name aliases
- Test round-trip encoding
- Test error cases

### Step 7: Verify
- Compile and fix any errors
- Run tests and fix any failures
- Check test coverage
- Review code for consistency with patterns

### Step 8: Document
- Ensure all functions have docstrings
- Add examples to docstrings
- Add notes about aliases
- Update this guide if new patterns emerge

---

## Final Integration

After all categories are implemented:

1. **Create aggregator module** (optional): `xrepl-ops.lfe` that re-exports all operations
2. **Update app.src**: Ensure all new modules are included
3. **Create comprehensive integration tests**: Test cross-operation workflows
4. **Update README**: Document all available operations
5. **Create examples**: Show typical usage patterns
6. **Performance testing**: Profile MessagePack encoding/decoding
7. **Benchmark**: Test throughput for common operations

---

## Success Criteria

The implementation is complete when:

- [ ] All 83 operations from spec are implemented
- [ ] All operations use binary keys internally
- [ ] All field name aliases are supported in request builders
- [ ] All field name aliases are supported in response parsers
- [ ] All field name aliases are generated in responses (both names present)
- [ ] All modules have comprehensive test coverage (>90%)
- [ ] All tests pass
- [ ] Round-trip encoding preserves all data and aliases
- [ ] Code follows LFE style conventions
- [ ] All functions have docstrings with examples
- [ ] Build completes without warnings

---

## Questions or Issues

If you encounter any issues or need clarification during implementation:

1. **Check the spec**: Review the relevant section in `xrepl-unified-spec.md`
2. **Check existing code**: Look at migrated modules for patterns
3. **Check test files**: See how similar operations are tested
4. **Document the issue**: Note any ambiguities or spec inconsistencies
5. **Make a reasonable decision**: Follow existing patterns when in doubt
6. **Add a TODO comment**: Mark areas that need review

---

## Appendix: Quick Reference

### Binary Key Syntax
```lisp
#"key_name"          ; binary key literal
(maps:get #"key" map)  ; get with binary key
(maps:put #"key" value map)  ; put with binary key
```

### Common Helper Functions
```lisp
;; From xrepl-protocol-types
(ensure-binary value)                    ; Convert to binary
(ensure-binary-key key)                  ; Convert key to binary
(get-field map key)                      ; Get field (tries binary key)
(get-field map key default)              ; Get field with default
(get-field-any map keys)                 ; Try multiple key names
(get-required map key)                   ; Get required field or error
(put-aliased map key1 key2 value)        ; Put value under two keys
(put-aliased-list map key1 key2 list)    ; Put list under two keys
(maybe-put-aliased map k1 k2 opts key)   ; Conditionally add aliased field
```

### Test Macros
```lisp
(is-equal expected actual)        ; Assert equality
(is-not expr)                     ; Assert false
(is expr)                         ; Assert true
(is-match pattern expr)           ; Assert pattern match
```

### Common Test Patterns
```lisp
;; Round-trip test
(let* ((data original-data)
       (`#(ok ,encoded) (xrepl-protocol-msgpack:encode data))
       (`#(ok ,decoded) (xrepl-protocol-msgpack:decode encoded)))
  (is-equal expected-value (maps:get #"key" decoded)))

;; Parse test
(case (module:parse-request message)
  (`#(ok ,parsed)
   (is-equal expected (maps:get #"field" parsed)))
  (other
   (error (tuple 'unexpected-result other))))
```

---

**End of Implementation Guide**

This guide should be sufficient for Claude Code to implement the entire xREPL protocol specification systematically, category by category, with proper binary key usage, field name alias support, and comprehensive testing.