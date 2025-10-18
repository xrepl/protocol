# xrepl/protocol

[![Build Status][gh-actions-badge]][gh-actions]
[![LFE Versions][lfe-badge]][lfe]
[![Erlang Versions][erlang-badge]][version]
[![Tags][github-tags-badge]][github-tags]

[![Project Logo][logo]][logo-large]

*Wire protocol definitions and encoding/decoding utilities for xrepl communications*

## Overview

This library provides:

- MessagePack encoding/decoding with length framing
- Protocol message type definitions and schemas
- Request/response builders for all operations
- Message validation functions
- Error standardization

## Installation

Add to your `rebar.config`:

```erlang
{deps, [
    {xrepl_protocol, "0.1.0"}
]}.
```

## Usage

```lfe
;; Encoding an eval request
(let ((request (xrepl-protocol-eval:request #m(code "(+ 1 2)"))))
  (xrepl-protocol-msgpack:encode request))

;; Decoding a response
(case (xrepl-protocol-msgpack:decode binary-data)
  (`#(ok ,message)
   (xrepl-protocol-eval:parse-response message)))
```

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
