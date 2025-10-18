# xrepl/protocol

[![Build Status][gh-actions-badge]][gh-actions]
[![LFE Versions][lfe-badge]][lfe]
[![Erlang Versions][erlang-badge]][version]
[![Tags][github-tags-badge]][github-tags]

[![Project Logo][logo]][logo-large]

*Complete wire protocol implementation for xREPL - 83 operations across 12 modules with 100% spec coverage*

## Status

✅ **Production Ready** - All 83 operations from the unified xREPL specification are implemented with 776 comprehensive tests.

## Overview

This library provides a complete implementation of the xREPL protocol:

- **83 operations** across 12 organized modules
- MessagePack encoding/decoding with length framing
- Request/response builders for all operations
- Comprehensive message validation
- Field aliasing for client compatibility (Emacs, VSCode, etc.)
- Full error handling and standardization

## Protocol Operations

The protocol is organized into 12 modules covering:

- **Session Management** - Session lifecycle and state
- **Code Evaluation** - Execution and file loading
- **System & Introspection** - Server capabilities and health
- **Code Intelligence** - Completion, signatures, formatting
- **Navigation** - Symbol lookup and definitions
- **Documentation** - Doc access and generation
- **Debugging** - Breakpoints, stepping, inspection
- **Testing** - Test execution and coverage
- **Refactoring** - Symbol rename, function extraction
- **Compilation** - Building and static analysis
- **BEAM Operations** - Hot reload, process inspection
- **Advanced Features** - Macros, profiling, LSP integration

## Installation

Add to your `rebar.config`:

```erlang
{deps, [
    {xrepl_protocol, "0.2.0"}
]}.
```

## Usage

```lfe
;; Encoding an eval request
(let ((request (xrepl-ptcl-ops-eval:eval-request #m(code "(+ 1 2)"))))
  (xrepl-ptcl-msgpack:encode request))

;; Decoding a response
(case (xrepl-ptcl-msgpack:decode binary-data)
  (`#(ok ,message)
   (xrepl-ptcl-ops-eval:parse-response 'eval message)))
```

## Testing

Run the full test suite:

```bash
rebar3 as test eunit
```

All 776 tests passing ✅

## License

Apache 2.0

[//]: ---Named-Links---

[logo]: https://raw.githubusercontent.com/xrepl/xrepl/refs/heads/main/priv/images/logo-v1-x250.png
[logo-large]: https://raw.githubusercontent.com/xrepl/xrepl/refs/heads/main/priv/images/logo-v1-x4800.png
[gh-actions-badge]: https://github.com/xrepl/protocol/actions/workflows/cicd.yml/badge.svg
[gh-actions]: https://github.com/xrepl/protocol/actions/workflows/cicd.yml
[lfe]: https://github.com/lfe/lfe
[lfe-badge]: https://img.shields.io/badge/lfe-2.2-blue.svg
[erlang-badge]: https://img.shields.io/badge/erlang-24%20to%2028-blue.svg
[version]: https://github.com/xrepl/protocol/blob/main/.github/workflows/cicd.yml
[github-tags]: https://github.com/xrepl/protocol/tags
[github-tags-badge]: https://img.shields.io/github/tag/lfe/xrepl.svg
