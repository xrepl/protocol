# xREPL Protocol Implementation Master Plan

**Version:** 1.0  
**Date:** 2025-01-XX  
**Status:** Planning Phase

---

## Part 1: Project Understanding & Goals

### 1.1 Current State

The xREPL project currently consists of:

**Core Infrastructure (Complete)**
- `xrepl-dispatcher.lfe` - Transport-agnostic message handler implementing 8 basic operations
- `xrepl-session-manager.lfe` - Session lifecycle management API
- `xrepl-session.lfe` - Individual session gen_server with LFE environment and evaluator process
- `xrepl-session-sup.lfe` - Supervisor for session processes (simple_one_for_one)
- `xrepl-eval.lfe` - LFE form evaluation wrapper with error handling
- `xrepl-output.lfe` - Transport-aware output handling (stdio vs remote)
- `xrepl-commands.lfe` - Interactive shell commands for session management
- `xrepl-store.lfe` - Session metadata persistence (ETS-based)
- `xrepl-history.lfe` - Command history management
- `xrepl-env.lfe` - LFE environment management
- `xrepl-io.lfe` - I/O utilities for REPL
- `xrepl.lfe` - Main REPL loop and stdio interface
- `xrepl-transport.lfe` - Transport behavior definition

**Currently Implemented Operations (8/83)**
1. `eval` - Code evaluation
2. `clone` - Session cloning
3. `close` - Session closing
4. `ls_sessions` - List sessions
5. `describe` - Server capabilities
6. `ping` - Health check
7. `load_file` - File loading (placeholder)
8. `upload_history` - Client history upload

**Protocol Library (xrepl/protocol - External Dependency)**
- MessagePack request/response builders for all 83 operations
- Organized into 12 category modules (`xrepl-ptcl-ops-*`)
- Provides message construction/parsing but not operation handlers

### 1.2 Project Goals

**Primary Goal**: Implement server-side handlers for all 83 operations defined in the Unified xREPL Protocol Specification, enabling full IDE integration capabilities for LFE development.

**Specific Objectives**:

1. **Complete Protocol Coverage**: Implement handlers for all 83 operations across 12 categories
2. **Modular Architecture**: Organize handlers by category with composable dispatcher pattern
3. **Production Quality**: Include comprehensive error handling and proper response formatting
4. **Incremental Deployment**: Enable merging and deploying work in independent chunks
5. **Testability**: Ensure all handlers have both unit and integration tests
6. **Protocol Compliance**: Match MessagePack request/response format exactly per spec
7. **LFE Integration**: Leverage existing LFE/Erlang tooling where available
8. **Extension Points**: Design for future enhancement (debugging, AI features, etc.)

### 1.3 Gap Analysis

**Missing Implementations (75 operations)**:

**Session Management (5 remaining)**
- `switch_namespace` - Change module context
- `session_info` - Detailed session state
- `clear_session` - Reset session state

**Code Evaluation (5 remaining)**
- `eval_multiple` - Batch evaluation
- `eval_at_point` - Context-aware evaluation
- `stream_eval` / `eval_stream` - Streaming evaluation
- `cancel` - Cancel operation

**Code Intelligence (10 operations)**
- `complete` - Code completion
- `complete_context` - Context-aware completion
- `signature` / `signature_help` - Function signatures
- `eldoc` - Lightweight signature lookup
- `eldoc_batch` - Batch eldoc queries
- `type_info` - Type information
- `format` / `format_code` - Code formatting
- `apropos` - Symbol search
- `indent_info` - Indentation information
- `buffer_analysis` - Buffer-level analysis
- `highlight_regions` - Semantic highlighting

**Navigation (5 operations)**
- `find_definition` / `definition` - Jump to definition
- `find_references` / `references` - Find usages
- `list_definitions` - Buffer outline
- `symbol_at_point` - Symbol information
- `workspace_symbols` - Project-wide search

**Documentation (5 operations)**
- `doc` - Full documentation
- `module_doc` - Module documentation
- `search_docs` - Documentation search
- `generate_doc` - Documentation generation
- `module_summary` - Module summary

**Debugging (7 operations)**
- `set_breakpoint` - Set breakpoint
- `clear_breakpoint` - Clear breakpoint
- `list_breakpoints` - List breakpoints
- `stacktrace` - Get stack trace
- `inspect_locals` - View local variables
- `eval_in_frame` - Evaluate in stack frame
- `step` - Debug stepping

**Testing (4 operations)**
- `test_run` - Run tests
- `test_coverage` - Coverage reporting
- `test_rerun_failures` - Rerun failed tests
- `generate_tests` - Test generation

**Refactoring (3 operations)**
- `rename_symbol` - Rename refactoring
- `extract_function` - Extract function
- `inline_function` - Inline function

**Compilation & Building (5 operations)**
- `compile_file` - Compile single file
- `compile_project` - Compile project
- `lint` - Static analysis
- `dependencies` - List dependencies
- `build` - Run build command

**BEAM-Specific (6 operations)**
- `hot_reload` - Hot code reloading
- `list_processes` - List BEAM processes
- `inspect_process` - Process inspection
- `trace_calls` - Call tracing
- `system_info` - VM information
- `observer_data` - Observer metrics

**Status & Introspection (5 operations)**
- `capabilities` - Detailed capabilities
- `version` - Version information
- `loaded_modules` - List loaded modules
- `module_info` - Module information

**Advanced Features (15 operations)**
- `macroexpand` - Macro expansion
- `macroexpand_all` - Full macro expansion
- `list_macros` - List macros
- `history` - Evaluation history
- `search_history` - History search
- `profile_start` - Start profiling
- `profile_stop` - Stop profiling
- `benchmark` - Code benchmarking
- `snippets` - Code snippets
- `expand_snippet` - Snippet expansion
- `generate_function` - Function generation
- `suggest_improvements` - Code suggestions
- `share_session` - Session sharing
- `restore_session` - Session restoration
- `text_document_did_*` - LSP-style document notifications (3 ops)

### 1.4 Technical Challenges

**LFE Tooling Gaps**:
- No native code completion engine (need to build symbol introspection)
- No source indexing for navigation (need to parse/index source files)
- No built-in debugger integration (need BEAM debugger wrapper)
- No test framework integration (need to integrate with EUnit/LFE test libs)
- Limited static analysis capabilities (need custom analysis)

**Protocol Integration**:
- Pull in `xrepl/protocol` as rebar3 dependency
- Version coordination between protocol lib and server
- MessagePack binary key handling (current code uses atoms)
- Response formatting consistency across all handlers

**Architecture Decisions**:
- Category-based dispatcher composition
- Handler module organization
- Shared utility functions location
- Error response standardization
- Caching strategies for expensive operations

**Research Required**:
- LFE module introspection APIs
- BEAM debugging primitives available
- Existing LFE parsing/analysis tools
- Test framework integration points
- Profiling/tracing capabilities

---

## Part 2: Implementation Plan

### 2.1 Work Organization Principles

**Chunk Size**: Each work chunk should be completable in a single Claude Code session (2-4 hours of focused work) with 1-2 context compactions.

**Deliverables Per Chunk**:
- Handler module implementation
- Unit tests (per-function)
- Integration tests (MessagePack request/response cycle)
- Dispatcher integration
- Documentation updates

**Testing Strategy**:
- Unit tests: Test individual handler functions with mock data
- Integration tests: Full MessagePack encode/decode with real sessions
- All tests should be runnable via `rebar3 eunit`

**Incremental Merge Strategy**:
- Each chunk is independently mergeable to main branch
- Operations return proper error responses until fully implemented
- No feature flags needed (errors indicate "not ready yet")
- Dispatcher routes to handlers as they become available

### 2.2 Dependency Setup (Chunk 0)

**Goal**: Integrate xrepl/protocol library and establish dispatcher architecture

**Tasks**:
1. Add `xrepl/protocol` to rebar.config as dependency
2. Create category-based dispatcher architecture:
   - Design composable dispatcher pattern
   - Create `xrepl-dispatcher-*.lfe` modules (one per category)
   - Implement dispatcher composition in `xrepl-dispatcher.lfe`
   - Update message routing to delegate to category dispatchers
3. Standardize error response format:
   - Create `xrepl-errors.lfe` utility module
   - Define error types and response builders
   - Document error handling patterns
4. Create shared utilities:
   - `xrepl-protocol-utils.lfe` for common protocol operations
   - Key normalization (binary ↔ atom conversion)
   - Response formatting helpers
5. Update existing 8 handlers to use new architecture
6. Write integration test harness for MessagePack testing

**Deliverables**:
- Updated `rebar.config`
- `xrepl-dispatcher.lfe` (refactored with composition)
- `xrepl-dispatcher-sess.lfe` (session ops)
- `xrepl-dispatcher-eval.lfe` (eval ops)
- `xrepl-dispatcher-sys.lfe` (system ops)
- `xrepl-errors.lfe`
- `xrepl-protocol-utils.lfe`
- Test harness in `test/xrepl_protocol_tests.lfe`
- Documentation: `docs/dispatcher-architecture.md`

**Success Criteria**:
- All 8 existing operations work through new architecture
- Integration tests pass for all 8 operations
- Clean separation between category dispatchers
- Consistent error response format

---

### 2.3 Work Chunks by Category

The remaining 75 operations are organized into 11 category-based chunks, each building on the previous foundation.

---

#### Chunk 1: Session Management (Remaining 5 ops)

**Operations**: `switch_namespace`, `session_info`, `clear_session`

**Dependencies**: Chunk 0 (dispatcher architecture)

**Estimated Complexity**: Low (extends existing session infrastructure)

**Implementation Details**:

1. **switch_namespace**:
   - Update session environment's current module context
   - Validate module exists
   - Return confirmed namespace

2. **session_info**:
   - Aggregate session state from `xrepl-session-manager`
   - Include bindings, loaded modules, current namespace
   - Format timestamps properly

3. **clear_session**:
   - Reset session to initial environment
   - Clear variable bindings
   - Preserve session metadata
   - Reset history (optional based on spec)

**Handler Module**: `xrepl-handler-sess.lfe`

**Dispatcher**: `xrepl-dispatcher-sess.lfe` (already created in Chunk 0)

**Tests**:
- Unit: Test each operation with mock session data
- Integration: Full request/response cycle with real sessions
- Edge cases: Invalid namespace, non-existent session

**Deliverables**:
- `src/xrepl-handler-sess.lfe`
- `test/xrepl_handler_sess_tests.lfe`
- Updated dispatcher routing

---

#### Chunk 2: Code Evaluation (Remaining 5 ops)

**Operations**: `eval_multiple`, `eval_at_point`, `stream_eval` / `eval_stream`, `cancel`

**Dependencies**: Chunk 0

**Estimated Complexity**: Medium (requires streaming and cancellation support)

**Implementation Details**:

1. **eval_multiple**:
   - Parse array of code strings
   - Evaluate in sequence
   - Collect results with individual status
   - Continue on errors (collect all results)

2. **eval_at_point**:
   - Accept file context (file, line, column)
   - Same as `eval` but include location in errors
   - Enhanced error reporting with context

3. **stream_eval** / `eval_stream**:
   - Spawn evaluator with streaming output
   - Send intermediate output messages with `status: ["streaming"]`
   - Capture stdout/stderr during evaluation
   - Send final result with `status: ["done"]`
   - Requires process group for output capture

4. **cancel**:
   - Track pending operations by request ID
   - Send interrupt signal to operation process
   - Return cancellation status
   - Clean up operation state

**Handler Module**: `xrepl-handler-eval.lfe`

**Dispatcher**: `xrepl-dispatcher-eval.lfe` (already created in Chunk 0)

**New Utilities**:
- `xrepl-eval-stream.lfe` - Output capture and streaming
- Request tracking in session state for cancellation

**Tests**:
- Unit: Mock evaluations, test result aggregation
- Integration: Real multi-form evaluation, streaming output capture
- Edge cases: Cancel during evaluation, stream errors

**Deliverables**:
- `src/xrepl-handler-eval.lfe`
- `src/xrepl-eval-stream.lfe`
- `test/xrepl_handler_eval_tests.lfe`
- Updated session state to track pending operations

---

#### Chunk 3: Code Intelligence - Part 1 (5 ops)

**Operations**: `complete`, `complete_context`, `signature` / `signature_help`, `eldoc`, `eldoc_batch`

**Dependencies**: Chunk 0, new symbol introspection library

**Estimated Complexity**: High (requires building completion engine)

**Research Required**:
- LFE module introspection APIs (`lfe_env`, module exports)
- Symbol lookup mechanisms
- Standard library function signatures
- Possible integration with existing completion in `lfe_edlin_expand`

**Implementation Details**:

1. **Symbol Introspection System** (new module: `xrepl-symbols.lfe`):
   - Index loaded modules and their exports
   - Cache function signatures and arities
   - Track imported symbols per session
   - Build completion trie/index for fast prefix matching

2. **complete**:
   - Extract prefix from request
   - Search indexed symbols by prefix
   - Return candidates with type, arity, module, doc snippet
   - Support context hints (function vs module vs variable)

3. **complete_context**:
   - Parse buffer to determine context (function call position, argument position)
   - Filter completions based on context
   - Return context info (in_function_call, expected_type, etc.)

4. **signature** / `signature_help`:
   - Look up function signature by symbol
   - Parse arglist and parameter names
   - Determine active parameter from cursor position
   - Return signature with parameter highlighting

5. **eldoc** / `eldoc_batch`:
   - Lightweight signature lookup (no full docs)
   - Return function signature and arglists
   - Batch version processes multiple symbols efficiently

**Handler Module**: `xrepl-handler-intel.lfe`

**Dispatcher**: `xrepl-dispatcher-intel.lfe`

**New Modules**:
- `xrepl-symbols.lfe` - Symbol indexing and introspection
- `xrepl-completion.lfe` - Completion engine
- `xrepl-signatures.lfe` - Signature extraction

**Tests**:
- Unit: Symbol indexing, prefix matching, signature parsing
- Integration: Full completion cycle, context detection
- Performance: Benchmark completion speed (should be <50ms)

**Deliverables**:
- `src/xrepl-handler-intel.lfe`
- `src/xrepl-symbols.lfe`
- `src/xrepl-completion.lfe`
- `src/xrepl-signatures.lfe`
- `src/xrepl-dispatcher-intel.lfe`
- `test/xrepl_handler_intel_tests.lfe`
- `test/xrepl_symbols_tests.lfe`

---

#### Chunk 4: Code Intelligence - Part 2 (5 ops)

**Operations**: `type_info`, `format` / `format_code`, `apropos`, `indent_info`, `buffer_analysis`

**Dependencies**: Chunk 3, xrepl/format library

**Estimated Complexity**: High (format requires separate library, buffer analysis is complex)

**Research Required**:
- Dialyzer/type spec extraction
- LFE indentation rules
- Buffer parsing for analysis

**Implementation Details**:

1. **type_info**:
   - Extract type specs from module attributes
   - Parse `-spec` forms if available
   - Return argument types and return type
   - Handle polymorphic/parameterized types

2. **format** / `format_code**:
   - **EXTERNAL DEPENDENCY**: `xrepl/format` library
   - Integrate formatter as rebar3 dependency
   - Pass code and options to formatter
   - Return formatted code
   - Handle format errors gracefully
   - **Note**: This chunk includes adding formatter to dependencies

3. **apropos**:
   - Search symbols by substring or regex
   - Optionally search documentation
   - Return matches with module, type, doc snippet
   - Rank by relevance

4. **indent_info**:
   - Parse line context
   - Apply LFE indentation rules
   - Return column position for proper indentation
   - Handle special forms (let, defun, etc.)

5. **buffer_analysis**:
   - Parse entire buffer
   - Detect undefined functions
   - Find unused functions
   - Identify unused imports
   - Detect shadowed variables
   - Return structured analysis results

**Handler Module**: Continue in `xrepl-handler-intel.lfe`

**New Modules**:
- `xrepl-types.lfe` - Type spec extraction
- `xrepl-indent.lfe` - Indentation engine
- `xrepl-analysis.lfe` - Static analysis

**External Dependencies**:
- `xrepl/format` - Code formatter library (add to rebar.config)

**Tests**:
- Unit: Type parsing, indentation rules, analysis detection
- Integration: Format round-trips, full buffer analysis
- Edge cases: Malformed code, missing types

**Deliverables**:
- Updated `src/xrepl-handler-intel.lfe`
- `src/xrepl-types.lfe`
- `src/xrepl-indent.lfe`
- `src/xrepl-analysis.lfe`
- Updated `rebar.config` (add xrepl/format)
- `test/xrepl_handler_intel_part2_tests.lfe`

---

#### Chunk 5: Code Intelligence - Part 3 (1 op)

**Operations**: `highlight_regions`

**Dependencies**: Chunk 4

**Estimated Complexity**: Medium (semantic analysis for highlighting)

**Implementation Details**:

1. **highlight_regions**:
   - Parse buffer into AST
   - Walk AST and classify tokens:
     - Keywords (defun, let, if, etc.)
     - Function calls
     - Variables
     - Literals (strings, numbers, atoms)
     - Comments
     - Macros
   - Return regions with start/end positions and type/face
   - Consider caching parsed results

**Handler Module**: Continue in `xrepl-handler-intel.lfe`

**New Module**:
- `xrepl-highlight.lfe` - Semantic highlighting

**Tests**:
- Unit: Token classification, region boundaries
- Integration: Full buffer highlighting
- Edge cases: Nested forms, macros, comments

**Deliverables**:
- `src/xrepl-highlight.lfe`
- Updated `src/xrepl-handler-intel.lfe`
- `test/xrepl_highlight_tests.lfe`

---

#### Chunk 6: Navigation (5 ops)

**Operations**: `find_definition` / `definition`, `find_references` / `references`, `list_definitions`, `symbol_at_point`, `workspace_symbols`

**Dependencies**: Chunk 3 (symbol system)

**Estimated Complexity**: High (requires source indexing)

**Research Required**:
- LFE source parsing for definition extraction
- File system traversal for workspace indexing
- Efficient symbol lookup data structures

**Implementation Details**:

1. **Source Indexing System** (new module: `xrepl-index.lfe`):
   - Index all .lfe files in project
   - Extract definition locations (functions, macros, records)
   - Build reverse index for reference finding
   - Watch file changes and reindex (optional for MVP)

2. **find_definition** / `definition`:
   - Look up symbol in index
   - Return file, line, column
   - Handle multiple definitions (different arities)
   - Support cross-module lookups

3. **find_references** / `references`:
   - Search index for symbol usages
   - Return all reference locations
   - Include context line for each reference

4. **list_definitions**:
   - Parse file to extract all top-level forms
   - Return function/macro/record definitions
   - Include line numbers and types

5. **symbol_at_point**:
   - Extract symbol at cursor position
   - Look up in current module scope
   - Return type, module, arity, local vs imported
   - Include definition location if available

6. **workspace_symbols**:
   - Search entire workspace index
   - Support fuzzy matching
   - Return symbols with file/line/type
   - Limit results (configurable)

**Handler Module**: `xrepl-handler-nav.lfe`

**Dispatcher**: `xrepl-dispatcher-nav.lfe`

**New Modules**:
- `xrepl-index.lfe` - Source file indexing
- `xrepl-parser.lfe` - LFE source parsing utilities

**Tests**:
- Unit: Index operations, symbol lookup, reference finding
- Integration: Cross-file navigation, workspace search
- Performance: Indexing large projects (<1s for 100 files)

**Deliverables**:
- `src/xrepl-handler-nav.lfe`
- `src/xrepl-dispatcher-nav.lfe`
- `src/xrepl-index.lfe`
- `src/xrepl-parser.lfe`
- `test/xrepl_handler_nav_tests.lfe`
- `test/xrepl_index_tests.lfe`

---

#### Chunk 7: Documentation (5 ops)

**Operations**: `doc`, `module_doc`, `search_docs`, `generate_doc`, `module_summary`

**Dependencies**: Chunk 3 (symbol system), Chunk 6 (indexing)

**Estimated Complexity**: Medium (extraction and formatting)

**Research Required**:
- LFE documentation conventions (docstrings)
- EDoc integration possibilities
- Module attribute documentation

**Implementation Details**:

1. **Documentation Extraction** (new module: `xrepl-docs.lfe`):
   - Parse module for docstrings
   - Extract function documentation
   - Parse EDoc-style comments
   - Format for display

2. **doc**:
   - Look up symbol documentation
   - Include signature, arglists, description
   - Add examples if available
   - Return see-also references

3. **module_doc**:
   - Extract module-level documentation
   - List exported functions with brief descriptions
   - Include module attributes
   - Format as structured documentation

4. **search_docs**:
   - Index all documentation text
   - Search by keyword/phrase
   - Return ranked results with snippets
   - Highlight matches

5. **generate_doc**:
   - Analyze function signature
   - Generate template documentation
   - Infer parameter descriptions from names
   - Return formatted doc string

6. **module_summary**:
   - Analyze module exports
   - Categorize functions by purpose
   - Generate overview text
   - List dependencies

**Handler Module**: `xrepl-handler-doc.lfe`

**Dispatcher**: `xrepl-dispatcher-doc.lfe`

**New Module**:
- `xrepl-docs.lfe` - Documentation extraction and indexing

**Tests**:
- Unit: Doc extraction, search ranking, generation templates
- Integration: Full doc lookup, module documentation
- Edge cases: Missing docs, malformed docstrings

**Deliverables**:
- `src/xrepl-handler-doc.lfe`
- `src/xrepl-dispatcher-doc.lfe`
- `src/xrepl-docs.lfe`
- `test/xrepl_handler_doc_tests.lfe`

---

#### Chunk 8: BEAM-Specific Operations (6 ops)

**Operations**: `hot_reload`, `list_processes`, `inspect_process`, `trace_calls`, `system_info`, `observer_data`

**Dependencies**: Chunk 0

**Estimated Complexity**: Medium (leverages BEAM built-ins)

**Research Required**:
- `code:load_file/1` and hot reload mechanisms
- Process introspection APIs
- `dbg` module for tracing
- System metrics gathering

**Implementation Details**:

1. **hot_reload**:
   - Use `code:load_file/1` to reload module
   - Purge old code version
   - Return reload status
   - Handle reload errors

2. **list_processes**:
   - Call `erlang:processes/0`
   - Filter by name pattern if requested
   - Gather basic info (PID, registered name, current function)
   - Return sorted/limited list

3. **inspect_process**:
   - Call `erlang:process_info/2` for detailed info
   - Extract message queue, links, monitors
   - Get current function, initial call
   - Format memory and reduction stats

4. **trace_calls**:
   - Use `dbg:tpl/3` to set trace patterns
   - Start/stop tracing for module:function/arity
   - Collect trace events
   - Stream events back to client
   - Handle trace cleanup

5. **system_info**:
   - Call `erlang:system_info/1` for various keys
   - Aggregate OTP release, ERTS version, architecture
   - Get process counts, memory stats
   - Return scheduler information

6. **observer_data**:
   - Aggregate system metrics for observer UI
   - Memory breakdown by type
   - CPU usage per scheduler
   - Top processes by reductions/memory
   - Format for visualization

**Handler Module**: `xrepl-handler-beam.lfe`

**Dispatcher**: `xrepl-dispatcher-beam.lfe`

**New Module**:
- `xrepl-beam-utils.lfe` - BEAM introspection utilities

**Tests**:
- Unit: Info extraction, metric formatting
- Integration: Hot reload cycle, process inspection
- Safety: Trace cleanup, error handling

**Deliverables**:
- `src/xrepl-handler-beam.lfe`
- `src/xrepl-dispatcher-beam.lfe`
- `src/xrepl-beam-utils.lfe`
- `test/xrepl_handler_beam_tests.lfe`

---

#### Chunk 9: Status & Introspection (5 ops)

**Operations**: `capabilities`, `version`, `loaded_modules`, `module_info`

**Dependencies**: Chunk 0

**Estimated Complexity**: Low (information gathering)

**Implementation Details**:

1. **capabilities**:
   - List all implemented operations
   - Include required/optional fields per operation
   - Document supported features
   - Return protocol version

2. **version**:
   - Return xrepl version
   - Include LFE version
   - Include Erlang/OTP version
   - Return protocol version

3. **loaded_modules**:
   - Call `code:all_loaded/0`
   - Filter LFE modules
   - Get module paths
   - Count exports per module

4. **module_info**:
   - Call `module:module_info/0`
   - Extract exports, attributes
   - Get compile options
   - Return MD5 hash

**Handler Module**: `xrepl-handler-sys.lfe`

**Dispatcher**: `xrepl-dispatcher-sys.lfe` (already created in Chunk 0, extend it)

**Tests**:
- Unit: Version parsing, module filtering
- Integration: Full capability enumeration
- Validation: Response format matches spec

**Deliverables**:
- Updated `src/xrepl-handler-sys.lfe`
- Updated `src/xrepl-dispatcher-sys.lfe`
- `test/xrepl_handler_sys_tests.lfe`

---

#### Chunk 10: Debugging (7 ops)

**Operations**: `set_breakpoint`, `clear_breakpoint`, `list_breakpoints`, `stacktrace`, `inspect_locals`, `eval_in_frame`, `step`

**Dependencies**: Chunk 0

**Estimated Complexity**: High (BEAM debugger integration)

**Research Required**:
- `int` module (Erlang interpreter for debugging)
- Breakpoint management APIs
- Stack frame introspection
- Step debugging mechanisms

**Implementation Details**:

1. **Debugger Integration** (new module: `xrepl-debug.lfe`):
   - Wrap `int` module for interpreted debugging
   - Manage breakpoint registry
   - Track debugging sessions
   - Handle debugger events

2. **set_breakpoint**:
   - Convert file:line to module:function
   - Use `int:break/2` to set breakpoint
   - Store breakpoint metadata
   - Return breakpoint ID

3. **clear_breakpoint**:
   - Look up breakpoint by ID
   - Call `int:delete_break/2`
   - Remove from registry
   - Return success status

4. **list_breakpoints**:
   - Return all active breakpoints
   - Include location, condition, hit count
   - Filter by session if needed

5. **stacktrace**:
   - Get current stack trace from debugger
   - Format frames with module:function/arity
   - Include file:line information
   - Show local variables per frame

6. **inspect_locals**:
   - Get bindings for specific stack frame
   - Format variable names and values
   - Handle large values (truncate)
   - Return type information

7. **eval_in_frame**:
   - Use `int:eval/2` or similar
   - Evaluate expression in frame context
   - Access frame bindings
   - Return result or error

8. **step**:
   - Implement step into/over/out/continue
   - Use `int:step/1` and related functions
   - Track step state
   - Return new location and locals

**Handler Module**: `xrepl-handler-debug.lfe`

**Dispatcher**: `xrepl-dispatcher-debug.lfe`

**New Module**:
- `xrepl-debug.lfe` - Debugger integration and management

**Tests**:
- Unit: Breakpoint management, frame inspection
- Integration: Full debug session workflow
- Edge cases: Invalid breakpoints, frame access

**Deliverables**:
- `src/xrepl-handler-debug.lfe`
- `src/xrepl-dispatcher-debug.lfe`
- `src/xrepl-debug.lfe`
- `test/xrepl_handler_debug_tests.lfe`

**Notes**:
- This is complex and may require two sessions
- Initial implementation can return `not_implemented` errors
- Full debugging support is a significant undertaking

---

#### Chunk 11: Testing (4 ops)

**Operations**: `test_run`, `test_coverage`, `test_rerun_failures`, `generate_tests`

**Dependencies**: Chunk 0

**Estimated Complexity**: Medium (test framework integration)

**Research Required**:
- LFE test framework conventions
- EUnit integration
- Coverage tools (cover module)
- Test result formatting

**Implementation Details**:

1. **Test Framework Integration** (new module: `xrepl-test.lfe`):
   - Detect test framework (EUnit, LFE test)
   - Run tests for module/namespace
   - Collect results
   - Format test output

2. **test_run**:
   - Run tests for specified module or all tests
   - Collect pass/fail/skip counts
   - Track individual test results
   - Return summary and details

3. **test_coverage**:
   - Use `cover` module
   - Compile module with coverage
   - Run tests
   - Analyze coverage data
   - Return line-level coverage

4. **test_rerun_failures**:
   - Store failed test list from last run
   - Re-run only failed tests
   - Update failure list
   - Return new results

5. **generate_tests**:
   - Analyze function signature
   - Generate test templates
   - Create basic/edge case tests
   - Return formatted test code

**Handler Module**: `xrepl-handler-test.lfe`

**Dispatcher**: `xrepl-dispatcher-test.lfe`

**New Module**:
- `xrepl-test.lfe` - Test runner and coverage integration

**Tests**:
- Unit: Test detection, result aggregation
- Integration: Run actual tests, coverage analysis
- Edge cases: No tests, all failures

**Deliverables**:
- `src/xrepl-handler-test.lfe`
- `src/xrepl-dispatcher-test.lfe`
- `src/xrepl-test.lfe`
- `test/xrepl_handler_test_tests.lfe`

---

#### Chunk 12: Refactoring (3 ops)

**Operations**: `rename_symbol`, `extract_function`, `inline_function`

**Dependencies**: Chunk 6 (navigation/indexing)

**Estimated Complexity**: High (code transformation)

**Research Required**:
- AST manipulation for code transformation
- Scope analysis for safe renaming
- Symbol usage tracking

**Implementation Details**:

1. **Refactoring Engine** (new module: `xrepl-refactor.lfe`):
   - Parse source to AST
   - Transform AST
   - Pretty-print back to source
   - Validate transformations

2. **rename_symbol**:
   - Find all references using index
   - Check for shadowing conflicts
   - Generate text edits for each location
   - Return workspace edits
   - Validate scope safety

3. **extract_function**:
   - Analyze selected code region
   - Determine free variables (parameters)
   - Generate function definition
   - Replace selection with function call
   - Return edit changes

4. **inline_function**:
   - Look up function definition
   - Substitute parameters with arguments
   - Replace call with inlined body
   - Handle multiple inlining
   - Return edit changes

**Handler Module**: `xrepl-handler-refactor.lfe`

**Dispatcher**: `xrepl-dispatcher-refactor.lfe`

**New Module**:
- `xrepl-refactor.lfe` - Refactoring engine

**Tests**:
- Unit: AST transformation, scope analysis
- Integration: Full refactoring workflows
- Safety: Validate semantic preservation

**Deliverables**:
- `src/xrepl-handler-refactor.lfe`
- `src/xrepl-dispatcher-refactor.lfe`
- `src/xrepl-refactor.lfe`
- `test/xrepl_handler_refactor_tests.lfe`

**Notes**:
- This is complex and may need two sessions
- Initial version can be conservative (fewer transformations)
- Extensive testing required for correctness

---

#### Chunk 13: Compilation & Building (5 ops)

**Operations**: `compile_file`, `compile_project`, `lint`, `dependencies`, `build`

**Dependencies**: Chunk 0

**Estimated Complexity**: Medium (compiler integration)

**Research Required**:
- LFE compiler API
- Rebar3 integration
- Diagnostic formatting
- Dependency extraction

**Implementation Details**:

1. **Compiler Integration** (new module: `xrepl-compile.lfe`):
   - Wrap `lfe_comp:file/2`
   - Capture warnings and errors
   - Format diagnostics
   - Track compilation state

2. **compile_file**:
   - Compile single .lfe file
   - Collect warnings/errors
   - Return diagnostics with file:line:column
   - Handle compilation options

3. **compile_project**:
   - Use rebar3 to compile project
   - Parse build output
   - Aggregate diagnostics
   - Return overall status

4. **lint**:
   - Run static analysis rules
   - Check for common issues
   - Use buffer_analysis results
   - Return issues with severity

5. **dependencies**:
   - Parse rebar.config
   - Extract dependencies
   - Determine types (required/test/dev)
   - Return dependency list

6. **build**:
   - Execute rebar3 command
   - Capture output
   - Parse build status
   - Return success/failure

**Handler Module**: `xrepl-handler-comp.lfe`

**Dispatcher**: `xrepl-dispatcher-comp.lfe`

**New Module**:
- `xrepl-compile.lfe` - Compiler and build tool integration

**Tests**:
- Unit: Diagnostic parsing, dependency extraction
- Integration: Full compilation, build execution
- Edge cases: Syntax errors, missing dependencies

**Deliverables**:
- `src/xrepl-handler-comp.lfe`
- `src/xrepl-dispatcher-comp.lfe`
- `src/xrepl-compile.lfe`
- `test/xrepl_handler_comp_tests.lfe`

---

#### Chunk 14: Advanced Features - Part 1 (6 ops)

**Operations**: `macroexpand`, `macroexpand_all`, `list_macros`, `history`, `search_history`, `profile_start`, `profile_stop`

**Dependencies**: Chunk 0

**Estimated Complexity**: Medium

**Implementation Details**:

1. **macroexpand**:
   - Use `lfe_macro:expand_form/2`
   - Single-step expansion
   - Return expanded form
   - Preserve original for comparison

2. **macroexpand_all**:
   - Recursively expand all macros
   - Use `lfe_macro:expand_form_all/2`
   - Return fully expanded form

3. **list_macros**:
   - Extract macros from environment
   - List available macros in current context
   - Include arity and documentation

4. **history**:
   - Use existing `xrepl-history` module
   - Return session history entries
   - Support pagination (limit/offset)
   - Include timestamps

5. **search_history**:
   - Search history by substring
   - Search in code or results
   - Return matching entries

6. **profile_start** / **profile_stop**:
   - Use `fprof` or `eprof` modules
   - Start profiling for modules
   - Collect profiling data
   - Format results (function calls, time, percent)

**Handler Module**: `xrepl-handler-adv.lfe`

**Dispatcher**: `xrepl-dispatcher-adv.lfe`

**Tests**:
- Unit: Macro expansion, history search, profile formatting
- Integration: Full profiling cycle
- Performance: Profile data collection overhead

**Deliverables**:
- `src/xrepl-handler-adv.lfe`
- `src/xrepl-dispatcher-adv.lfe`
- `test/xrepl_handler_adv_tests.lfe`

---

#### Chunk 15: Advanced Features - Part 2 (3 ops)

**Operations**: `benchmark`, `snippets`, `expand_snippet`

**Dependencies**: Chunk 14

**Estimated Complexity**: Low-Medium

**Implementation Details**:

1. **benchmark**:
   - Run code multiple times
   - Measure execution time
   - Calculate statistics (avg, min, max, median, stddev)
   - Return benchmark results

2. **snippets**:
   - Define snippet templates
   - Store snippets (in-memory or file)
   - Return available snippets by context
   - Include description and prefix

3. **expand_snippet**:
   - Take snippet template
   - Fill in context-aware defaults
   - Identify placeholders
   - Return expanded snippet with cursor positions

**Handler Module**: Continue in `xrepl-handler-adv.lfe`

**New Module**:
- `xrepl-snippets.lfe` - Snippet management

**Tests**:
- Unit: Benchmark statistics, snippet expansion
- Integration: Full benchmark cycle, snippet retrieval

**Deliverables**:
- Updated `src/xrepl-handler-adv.lfe`
- `src/xrepl-snippets.lfe`
- `test/xrepl_snippets_tests.lfe`

---

#### Chunk 16: Advanced Features - Part 3 (3 ops)

**Operations**: `generate_function`, `suggest_improvements`, (AI-assisted)

**Dependencies**: All previous chunks

**Estimated Complexity**: Very High (AI integration)

**Implementation Approach**:

These operations require AI/LLM integration, which is beyond the scope of basic implementation. They should return `not_implemented` errors with clear messages.

**Implementation Details**:

1. **generate_function**:
   - Return error: `{type: "not_implemented", message: "AI-assisted function generation requires LLM integration"}`
   - Document extension point for future AI integration

2. **suggest_improvements**:
   - Return error: `{type: "not_implemented", message: "AI-assisted code suggestions require LLM integration"}`
   - Document extension point for future AI integration

**Handler Module**: Continue in `xrepl-handler-adv.lfe`

**Tests**:
- Verify proper error responses
- Document future integration approach

**Deliverables**:
- Updated `src/xrepl-handler-adv.lfe` with stub implementations
- Documentation: `docs/ai-integration.md` (future work)

---

#### Chunk 17: Advanced Features - Part 4 (3 ops)

**Operations**: `share_session`, `restore_session`, LSP notifications

**Dependencies**: Chunk 0

**Estimated Complexity**: Medium

**Implementation Details**:

1. **share_session**:
   - Serialize session state (environment, history, bindings)
   - Generate unique share ID
   - Store session snapshot (in-memory or external storage)
   - Set expiration time
   - Return share ID and URL

2. **restore_session**:
   - Look up share ID
   - Deserialize session state
   - Create new session with restored state
   - Return session ID

3. **LSP notifications** (`text_document_did_open`, `did_change`, `did_close`):
   - Track open documents per session
   - Update internal document cache
   - Trigger re-analysis on changes
   - Return acknowledgment
   - **Note**: These are notifications, not full LSP implementation

**Handler Module**: Continue in `xrepl-handler-adv.lfe`

**New Module**:
- `xrepl-session-share.lfe` - Session sharing/serialization

**Tests**:
- Unit: Session serialization, share ID generation
- Integration: Full share/restore cycle
- Expiration: Verify expired shares are cleaned up

**Deliverables**:
- Updated `src/xrepl-handler-adv.lfe`
- `src/xrepl-session-share.lfe`
- `test/xrepl_session_share_tests.lfe`

---

### 2.4 Final Integration & Polish (Chunk 18)

**Goal**: Ensure all pieces work together, comprehensive testing, documentation

**Tasks**:
1. Integration testing across all categories
2. Performance benchmarking and optimization
3. Error handling review
4. Documentation completion:
   - API documentation for all handlers
   - Protocol compliance validation
   - Example usage for each operation
5. Version bump and release preparation

**Deliverables**:
- `test/xrepl_integration_tests.lfe` (full protocol test suite)
- Performance benchmarks and reports
- Complete API documentation
- Release notes
- Updated README

---

### 2.5 Summary of Deliverables

**Total Chunks**: 18 (including Chunk 0)

**Handler Modules**: 12
- xrepl-handler-sess.lfe
- xrepl-handler-eval.lfe
- xrepl-handler-intel.lfe
- xrepl-handler-nav.lfe
- xrepl-handler-doc.lfe
- xrepl-handler-beam.lfe
- xrepl-handler-sys.lfe
- xrepl-handler-debug.lfe
- xrepl-handler-test.lfe
- xrepl-handler-refactor.lfe
- xrepl-handler-comp.lfe
- xrepl-handler-adv.lfe

**Dispatcher Modules**: 12
- xrepl-dispatcher.lfe (composition root)
- xrepl-dispatcher-sess.lfe
- xrepl-dispatcher-eval.lfe
- xrepl-dispatcher-intel.lfe
- xrepl-dispatcher-nav.lfe
- xrepl-dispatcher-doc.lfe
- xrepl-dispatcher-beam.lfe
- xrepl-dispatcher-sys.lfe
- xrepl-dispatcher-debug.lfe
- xrepl-dispatcher-test.lfe
- xrepl-dispatcher-refactor.lfe
- xrepl-dispatcher-comp.lfe
- xrepl-dispatcher-adv.lfe

**Utility Modules**: 20+
- xrepl-errors.lfe
- xrepl-protocol-utils.lfe
- xrepl-symbols.lfe
- xrepl-completion.lfe
- xrepl-signatures.lfe
- xrepl-types.lfe
- xrepl-indent.lfe
- xrepl-analysis.lfe
- xrepl-highlight.lfe
- xrepl-index.lfe
- xrepl-parser.lfe
- xrepl-docs.lfe
- xrepl-beam-utils.lfe
- xrepl-debug.lfe
- xrepl-test.lfe
- xrepl-refactor.lfe
- xrepl-compile.lfe
- xrepl-snippets.lfe
- xrepl-session-share.lfe
- xrepl-eval-stream.lfe

**Test Modules**: 18+ (one per chunk minimum)

**External Dependencies**:
- xrepl/protocol (MessagePack protocol library)
- xrepl/format (LFE code formatter)

---

### 2.6 Estimated Timeline

**Per Chunk**: 1 Claude Code session (2-4 hours)
**Total**: 18 chunks × 3 hours average = 54 hours
**Calendar Time**: ~3-4 weeks (assuming 3-4 sessions per week)

**Critical Path**:
- Chunk 0 (foundation) → all others
- Chunk 3 (symbol system) → chunks 4, 5, 6, 7
- Chunk 6 (indexing) → chunks 12

**Parallelizable**:
- Chunks 8, 9, 11, 13 can be done independently after Chunk 0
- Advanced features (14-17) can be done independently

---

### 2.7 Success Criteria

**Per Chunk**:
- All operations return valid protocol responses
- Unit tests pass (100% coverage for handlers)
- Integration tests pass (full MessagePack cycle)
- No regressions in existing operations
- Documentation updated

**Overall Project**:
- All 83 operations implemented and tested
- Protocol compliance verified against spec
- Performance targets met:
  - Completion: <50ms
  - Evaluation: <100ms for simple forms
  - Indexing: <1s for 100 files
- VSCode extension can use all operations
- Documentation complete and accurate

---

### 2.8 Risk Mitigation

**High-Risk Areas**:
1. **Debugging (Chunk 10)**: BEAM debugger complexity
   - Mitigation: Start with basic breakpoints, stub complex features initially
2. **Refactoring (Chunk 12)**: AST transformation correctness
   - Mitigation: Extensive testing, conservative initial implementation
3. **Code Intelligence (Chunks 3-5)**: Building completion/analysis from scratch
   - Mitigation: Leverage existing LFE tools, incremental feature addition
4. **Performance**: Large project indexing, completion speed
   - Mitigation: Benchmark early, optimize hot paths, add caching

**Dependency Risks**:
- xrepl/protocol version compatibility
  - Mitigation: Pin version, document compatibility matrix
- xrepl/format availability
  - Mitigation: Stub formatter if not ready, implement basic version

**Scope Risks**:
- AI features (Chunk 16) scope creep
  - Mitigation: Strict "not_implemented" responses, no actual AI work
- Debugging completeness
  - Mitigation: Define MVP feature set, defer advanced features

---

## Appendix A: Operation Checklist

### Session Management (8 operations)
- [x] clone
- [x] close
- [x] ls_sessions
- [ ] switch_namespace
- [ ] session_info
- [ ] clear_session
- [x] upload_history

### Code Evaluation (13 operations)
- [x] eval
- [ ] eval_multiple
- [ ] eval_at_point
- [ ] stream_eval / eval_stream
- [ ] interrupt (exists but needs verification)
- [ ] cancel
- [x] load_file (placeholder)

### Code Intelligence (11 operations)
- [ ] complete
- [ ] complete_context
- [ ] signature / signature_help
- [ ] eldoc
- [ ] eldoc_batch
- [ ] type_info
- [ ] format / format_code
- [ ] apropos
- [ ] indent_info
- [ ] buffer_analysis
- [ ] highlight_regions

### Navigation (5 operations)
- [ ] find_definition / definition
- [ ] find_references / references
- [ ] list_definitions
- [ ] symbol_at_point
- [ ] workspace_symbols

### Documentation (5 operations)
- [ ] doc
- [ ] module_doc
- [ ] search_docs
- [ ] generate_doc
- [ ] module_summary

### Debugging (7 operations)
- [ ] set_breakpoint
- [ ] clear_breakpoint
- [ ] list_breakpoints
- [ ] stacktrace
- [ ] inspect_locals
- [ ] eval_in_frame
- [ ] step

### Testing (4 operations)
- [ ] test_run
- [ ] test_coverage
- [ ] test_rerun_failures
- [ ] generate_tests

### Refactoring (3 operations)
- [ ] rename_symbol
- [ ] extract_function
- [ ] inline_function

### Compilation & Building (5 operations)
- [ ] compile_file
- [ ] compile_project
- [ ] lint
- [ ] dependencies
- [ ] build

### BEAM-Specific (6 operations)
- [ ] hot_reload
- [ ] list_processes
- [ ] inspect_process
- [ ] trace_calls
- [ ] system_info
- [ ] observer_data

### Status & Introspection (6 operations)
- [x] describe
- [ ] capabilities
- [x] ping
- [ ] version
- [ ] loaded_modules
- [ ] module_info

### Advanced Features (15 operations)
- [ ] macroexpand
- [ ] macroexpand_all
- [ ] list_macros
- [ ] history
- [ ] search_history
- [ ] profile_start
- [ ] profile_stop
- [ ] benchmark
- [ ] snippets
- [ ] expand_snippet
- [ ] generate_function (stub)
- [ ] suggest_improvements (stub)
- [ ] share_session
- [ ] restore_session
- [ ] text_document_did_* (3 ops)

**Total**: 83 operations
**Implemented**: 8
**Remaining**: 75

---

## Appendix B: Module Dependency Graph

```
xrepl-dispatcher (root)
├── xrepl-dispatcher-sess → xrepl-handler-sess
├── xrepl-dispatcher-eval → xrepl-handler-eval
│   └── xrepl-eval-stream
├── xrepl-dispatcher-intel → xrepl-handler-intel
│   ├── xrepl-symbols
│   ├── xrepl-completion
│   ├── xrepl-signatures
│   ├── xrepl-types
│   ├── xrepl-indent
│   ├── xrepl-analysis
│   └── xrepl-highlight
├── xrepl-dispatcher-nav → xrepl-handler-nav
│   ├── xrepl-index
│   └── xrepl-parser
├── xrepl-dispatcher-doc → xrepl-handler-doc
│   └── xrepl-docs
├── xrepl-dispatcher-beam → xrepl-handler-beam
│   └── xrepl-beam-utils
├── xrepl-dispatcher-sys → xrepl-handler-sys
├── xrepl-dispatcher-debug → xrepl-handler-debug
│   └── xrepl-debug
├── xrepl-dispatcher-test → xrepl-handler-test
│   └── xrepl-test
├── xrepl-dispatcher-refactor → xrepl-handler-refactor
│   └── xrepl-refactor
├── xrepl-dispatcher-comp → xrepl-handler-comp
│   └── xrepl-compile
└── xrepl-dispatcher-adv → xrepl-handler-adv
    ├── xrepl-snippets
    └── xrepl-session-share

Shared Utilities:
├── xrepl-errors
└── xrepl-protocol-utils
```

---

## Appendix C: Testing Strategy Details

### Unit Testing
**Scope**: Individual handler functions
**Framework**: EUnit
**Coverage Target**: 100% of handler code
**Approach**:
- Mock protocol messages
- Test with various input scenarios
- Verify response format matches spec
- Test error conditions

### Integration Testing
**Scope**: Full MessagePack request/response cycle
**Framework**: EUnit with helper harness
**Coverage Target**: All 83 operations
**Approach**:
- Encode request with MessagePack
- Send through dispatcher
- Decode response
- Verify protocol compliance
- Test with real sessions

### Performance Testing
**Scope**: Critical operations (completion, eval, indexing)
**Framework**: Custom benchmark harness
**Targets**:
- Completion: <50ms
- Evaluation: <100ms for simple forms
- Indexing: <1s per 100 files
**Approach**:
- Benchmark with `timer:tc/1`
- Test with realistic data sizes
- Profile hot paths
- Document results

### Property-Based Testing (Optional)
**Scope**: Protocol message validation
**Framework**: PropEr
**Approach**:
- Generate random valid messages
- Verify all produce valid responses
- Test roundtrip encode/decode

---

## Appendix D: Documentation Requirements

### Per Operation
- Purpose and use case
- Request format with examples
- Response format with examples
- Error conditions
- IDE integration notes
- Performance characteristics

### Per Module
- Module overview
- Public API documentation
- Internal architecture
- Dependencies
- Testing approach

### Overall Project
- Architecture overview
- Protocol compliance matrix
- Performance benchmarks
- Deployment guide
- Troubleshooting guide

---

**End of Master Plan**
