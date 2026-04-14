# Ruby Platform Coding Guidelines

## Purpose

This document captures project-specific Ruby guidance for the SketchUp runtime in this repository.

It complements:

- `AGENTS.md` for repo-wide architecture and review expectations
- `specifications/sketchup-extension-development-guidance.md` for SketchUp extension and packaging practices

Use this guide when changing Ruby code under `src/` or Ruby tests under `test/`.

## Core Rules

- Keep SketchUp-facing behavior in Ruby.
- Keep Python thin at the MCP boundary.
- Return only JSON-serializable data across the Ruby/Python boundary.
- Prefer one Ruby operation per coherent tool call over chatty cross-runtime flows.
- Improve weak touched code when the improvement is local, testable, and preserves ownership boundaries.

## Layer Ownership

The Ruby side should keep moving toward these layers:

- boot and extension registration
- runtime bootstrap
- transport ingress and request routing
- command or use-case execution
- shared runtime support
- SketchUp adapters
- serializers for JSON-safe payload shaping

When choosing where code belongs:

- Put direct `Sketchup.active_model` access, entity lookup, collection access, export/view access, and other raw SketchUp API mechanics in adapters.
- Put command orchestration and tool-specific result composition in command surfaces.
- Put response envelopes, request-id propagation, logging, and shared error wrapping in shared runtime support.
- Put entity/bounds normalization and JSON-safe payload shaping in serializers.

Do not:

- put MCP semantics into Ruby adapters
- move command behavior into Python
- let transport files accumulate reusable SketchUp API helpers
- return live SketchUp objects across the boundary

## Adapters

Adapters should stay small and mechanical.

Good adapter responsibilities:

- `active_model!`
- entity lookup by id
- top-level or selection collection access
- export or view access
- narrow access helpers needed by multiple commands

Bad adapter responsibilities:

- response envelope building
- command policy and branching that is specific to one tool
- serializer output shaping
- Python transport concerns

Adapter design rules:

- Prefer stateless classes.
- Resolve live SketchUp state at call time.
- Preserve stable error messages when callers already depend on them.
- Extract only reusable low-level mechanics; do not force geometry-heavy refactors into an adapter just to maximize purity.

## Serializers

Serializers own JSON-safe normalization.

Serializer rules:

- emit hashes, arrays, strings, numbers, booleans, and `nil` only
- keep live SketchUp objects inside Ruby
- keep serializer code pure where practical
- avoid transport-specific behavior in serializers

If a command already has an established serializer seam, extend it instead of creating a parallel serializer path.

## Commands And Transport

Command surfaces should orchestrate adapters and serializers, not reimplement their mechanics.

Command rules:

- preserve established tool names unless an intentional contract change is documented
- keep success payload composition near the command behavior
- reuse shared adapters and serializers instead of duplicating lookup or normalization logic

Transport rules:

- keep request parsing and response envelope logic out of SketchUp-specific code
- avoid growing `socket_server.rb` with reusable low-level helpers if a focused seam is justified

## Error Handling

Preserve behavior that other layers or tests already rely on.

In practice:

- keep established messages stable for common failures such as missing model or missing entity
- let low-level seams raise clear Ruby exceptions
- keep JSON-RPC error-envelope ownership above adapters and serializers

Do not add speculative error taxonomies unless the current change needs them.

## Refactoring Touched Code

When touching Ruby code:

- improve obviously weak code if the fix is local and verifiable
- prefer removing fake guards over preserving them once the official API contract is understood
- do not widen the task into unrelated cleanup

Use this decision test:

- If the improvement clarifies ownership, removes duplicated mechanics, or fixes incorrect behavior at the touched seam, do it now.
- If it changes unrelated behavior, forces a broader redesign, or needs runtime knowledge you cannot verify, stop and narrow the change.

## Tests

Prefer the smallest practical test layer that owns the behavior.

Common Ruby test layers in this repo:

- unit tests for extracted runtime support and adapters
- seam-level integration tests for command surfaces
- focused runtime tests for representative mutation/export paths
- manual SketchUp verification for runtime-dependent behavior not yet covered automatically

Testing rules:

- add failing tests before implementation for new behavior or refactors
- extend shared test support before inventing one-off fake infrastructure
- keep custom overlays test-owned and narrow
- when a behavior moves to a new owner, move or add tests in the same change

Good patterns from this repo:

- fake model/entity support in `test/support/`
- integration guards for extracted seams such as `scene_query_commands`
- representative command rewiring tests in `socket_server` rather than broad end-to-end fakes

## Validation Commands

For Ruby changes, prefer the real project commands:

- `bundle exec rake ruby:test`
- `bundle exec rake ruby:lint`
- `bundle exec rake package:verify`

During focused loops, narrower commands are fine, but the final state should still pass the full project checks for the affected surface.

RuboCop note:

- use `bundle exec rake ruby:lint` when possible
- if invoking RuboCop directly, set `RUBOCOP_CACHE_ROOT=tmp/.rubocop_cache` to match the repo task behavior

## Packaging And File Layout

This repo packages a SketchUp extension support tree, not just a few fixed files.

When adding Ruby files:

- keep the root loader pattern intact
- keep new support files under `src/su_mcp/`
- verify the package still passes `package:verify`

Do not assume the current small file set is fixed. Adding focused modules is expected when it improves boundaries.

## SketchUp API Notes

Use official API contracts over ad hoc guesses.

Examples:

- prefer documented `Model#export` behavior and exporter options over fake preflight checks that do not actually validate exporter availability
- prefer explicit top-level versus active-edit-context access based on the bridge contract the command is preserving

If behavior could differ in a live SketchUp host and cannot be confirmed locally, call out manual verification explicitly rather than hiding the uncertainty.

## Review Checklist For Ruby Changes

Before finishing a Ruby change, verify:

- ownership still sits in the correct Ruby layer
- reusable SketchUp API mechanics are not duplicated across commands
- serializers still emit only JSON-safe values
- error behavior is still explicit and stable where required
- Ruby tests cover the owning seam
- `ruby:test`, `ruby:lint`, and `package:verify` pass, or the gap is called out
- any runtime-only uncertainty is called out for manual SketchUp verification
