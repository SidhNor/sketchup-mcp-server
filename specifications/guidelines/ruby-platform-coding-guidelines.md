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
- Do not duplicate business rules across multiple runtime layers.

## Platform Boundaries

The current platform is a SketchUp-hosted Ruby runtime with an MCP boundary.

Within that shape:

- keep direct SketchUp API access in Ruby
- prefer one coherent Ruby operation per tool call over chatty internal flows
- keep transport, command behavior, host interaction, and response shaping distinct enough to evolve safely

Do not:

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

- update the owning runtime tests
- update package or runtime verification where the public surface changed

## Validation

For Ruby changes, prefer:

- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`

When shared boundary behavior changes, also run focused runtime tests that cover the changed handler wiring or response shape.

Call out manual SketchUp verification explicitly when host-runtime behavior cannot be fully verified locally.

## Review Checklist

Before finishing a Ruby-platform change, verify:

- ownership still sits in Ruby where it should
- transport, command behavior, host interaction, and response shaping remain distinct enough
- outputs remain JSON-safe and contract-aware
- packaging and host-runtime fit were considered
- the relevant validation commands were run, or the gap was called out
