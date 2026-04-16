# Ruby Platform Coding Guidelines

## Purpose

This document captures project-specific Ruby guidance for this repository.

It is not the general Ruby style guide. For portable Ruby coding guidance, use:

- `specifications/ryby-coding-guidelines.md`

It is also not the main architecture document. Use the HLDs and ADRs for broader architectural direction.

Use this document for stable repo-specific concerns only:

- runtime ownership
- current platform boundaries
- SketchUp host constraints
- packaging and vendoring
- repo-specific validation

## Runtime Ownership

- Keep SketchUp-facing behavior in Ruby.
- Keep scene queries, scene mutations, metadata behavior, and command behavior in Ruby.
- Keep Python thin at the MCP boundary.
- Do not duplicate business rules across Ruby and Python.
- Do not move SketchUp-facing behavior into Python for convenience.

## Platform Boundaries

The current platform has a Ruby SketchUp runtime and a Python MCP adapter.

Within that shape:

- keep direct SketchUp API access in Ruby
- keep Python focused on MCP-facing adapter responsibilities
- prefer one coherent Ruby operation per tool call over chatty cross-runtime flows
- keep transport, command behavior, host interaction, and response shaping distinct enough to evolve safely

Do not:

- let Python accumulate product logic
- let transport code become the home for reusable SketchUp helpers
- return raw SketchUp objects across public boundaries

## Host Constraints

Ruby runs inside SketchUp's embedded runtime.

Code should be shaped with that in mind:

- prefer embedded-runtime compatibility over generic Ruby purity
- treat startup and packaging cost as real constraints
- prefer vendoring over runtime gem installation
- assume host validation may still be required even when plain Ruby tests pass

## Packaging And Dependencies

When adding Ruby support code or dependencies:

- keep support code under the extension support tree
- preserve the loader and extension registration entrypoints
- prefer vendored dependencies
- verify packaging after structural changes

Do not design as if this were a normal standalone Ruby service with unrestricted gem installation.

## Contract And Response Rules

- Return only JSON-serializable data across runtime or protocol boundaries.
- Preserve stable public contract shapes unless an intentional interface change is being made.
- Keep boundary error translation explicit.
- Do not leak raw SketchUp objects across public boundaries.

When a shared boundary contract changes:

- update the shared contract artifacts
- update both native contract suites

## Validation

For Ruby changes, prefer:

- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`

When shared boundary behavior changes, also run:

- `bundle exec rake ruby:contract`
- `bundle exec rake python:contract`

Call out manual SketchUp verification explicitly when host-runtime behavior cannot be fully verified locally.

## Review Checklist

Before finishing a Ruby-platform change, verify:

- ownership still sits in Ruby where it should
- Python is still thin at the MCP boundary
- transport, command behavior, host interaction, and response shaping remain distinct enough
- outputs remain JSON-safe and contract-aware
- packaging and host-runtime fit were considered
- the relevant validation commands were run, or the gap was called out
