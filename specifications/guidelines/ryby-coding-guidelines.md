# Ruby Coding Guidelines

## Purpose

This document defines Ruby coding guidelines for maintainable runtime code in this repository.

It is intentionally portable. It avoids binding guidance to current class names or file names, but it is written for the kind of Ruby system this project is building:

- a command-oriented runtime
- a host-integrated server
- a protocol-facing surface
- behavior that must normalize output into JSON-safe data

Use it when writing or reviewing Ruby runtime code, including protocol handling, transport support, command execution, host integration, serializers, and tests.

## Core Position

This guide does **not** treat micro-methods as a goal.

Ruby code should be shaped around **coherent operations and clear ownership**, not arbitrary line-count minimization. Public methods may be moderately broad when they read as one end-to-end operation. Extract only when it improves ownership, reuse, verification, or change boundaries.

Preferred defaults:

- cohesive public workflows
- explicit layer boundaries
- smaller lower-level mechanics
- clear contracts
- stable JSON-safe outputs

## Design Principles

- Keep responsibilities explicit.
- Keep protocol, orchestration, domain behavior, host integration, and serialization conceptually separate.
- Prefer composition over inheritance for application behavior.
- Keep internal data shapes stable once inputs are normalized.
- Raise errors in the layer that owns the failure and translate them at boundaries.
- Favor boring, readable control flow over clever Ruby.
- Optimize for code that is inspectable, testable, and safe to extend.

## Architectural Shape

### Layer Boundaries

A healthy Ruby runtime usually contains distinct concerns such as:

- transport or protocol ingress
- request parsing and validation
- command or use-case orchestration
- host-runtime adapters
- domain or support services
- serialization and response shaping
- logging, instrumentation, and error translation

These do not require a rigid directory structure, but they should remain mentally separable.
As a capability grows, the filesystem should make those separations easier to
see instead of hiding commands, contracts, domain services, serializers, storage,
and host adapters in one flat directory. Split capability roots once they contain
multiple ownership categories or have become a default destination for unrelated
new files. Use named folders for real concerns; avoid a generic `support/`
folder when a clearer ownership name exists.

Warning signs:

- one class both accepts protocol input and performs host mutations
- one method mixes parsing, lookup, business rules, mutation, and wire-format shaping
- transport concerns leak into host adapters
- serializers start making business decisions
- low-level helpers start constructing protocol responses

### Ownership Rules

- Put host API access in host-facing seams.
- Put operation-specific behavior in command or use-case seams.
- Put request-envelope handling and protocol translation at the boundary.
- Put repeated normalization in serializers or dedicated support objects.
- Keep logging and instrumentation centralized enough that behavior code is not cluttered with noise.

## Class Shape

### What A Class Should Own

Each class or module should have one primary reason to change.

Good examples:

- parse and validate a request
- dispatch an operation
- perform one domain use case
- resolve host entities or model state
- serialize structured output
- wrap operation execution with timing and logging

An orchestration class may coordinate several steps and still count as one responsibility if it represents one coherent operation or runtime boundary.

### Public Surface Area

Prefer a small public API.

- One public entrypoint is ideal for command-style objects.
- Two or three public methods can be reasonable for lifecycle, builder, or utility objects.
- A broad public surface usually means the object has become a bucket for unrelated behavior.

Common entrypoints:

- `call`
- `execute`
- `handle`
- `serialize`
- `validate`

### Constructor Shape

Constructors should usually capture dependencies, configuration, or stable collaborators.

Prefer constructor arguments for:

- adapters
- serializers
- loggers
- configuration
- collaborators that vary in tests or environments

Prefer method arguments for:

- per-request inputs
- operation parameters
- context naturally scoped to one invocation

Avoid constructors that take a large bag of business inputs and then immediately use the object once.

### Composition Over Inheritance

Prefer composition for runtime code.

Use inheritance only when:

- there is a real shared contract
- subclasses are genuine specializations
- the base class is small and stable

Do not introduce inheritance just to share a handful of helpers.

### Modules

Use modules deliberately.

Good module uses:

- namespacing
- small shared policies
- pure helper collections with a clear domain
- extension behavior that genuinely belongs together

Avoid modules that act as miscellaneous dumping grounds.

## Method Shape

### Cohesion, Size, And Parameters

A method should feel like one thing.

For public orchestration methods, "one thing" may still include multiple steps when they belong to one coherent operation. A good public method often reads like a transaction script:

1. normalize input
2. validate preconditions
3. resolve required targets or state
4. perform the operation
5. shape the result

That is acceptable. Do not split this into tiny methods unless doing so improves ownership or reuse.

Use method size as a signal, not a law.

- Small helper methods are good when they isolate one concrete concern.
- Medium-sized public methods are acceptable when they read clearly as one workflow.
- Large methods should be challenged when they mix distinct reasons to change.

Review a method more closely when:

- it has several levels of nesting
- it rescues exceptions and also performs core behavior
- it interleaves lookup, mutation, and serialization
- it repeats structural patterns found elsewhere
- it becomes hard to name without using "and"

A broad method is acceptable if it is:

- linear
- cohesive
- easy to scan
- hard to improve by extraction

A shorter method is still bad if it only hides complexity behind meaningless helper names.

Prefer explicit parameter shapes.

- Use positional arguments for short, obvious inputs.
- Use keyword arguments when a method has optional inputs or more than a couple of parameters.
- Use a context object when several invocation-scoped values naturally travel together.
- Avoid passing loosely structured hashes through many layers when a clearer shape is available.

Good contexts may include:

- request metadata
- logger or instrumentation hooks
- host model access
- current session or capability state

### Return Contracts

Return one clear shape per method.

Prefer:

- a well-defined value object
- a hash with a stable schema
- a boolean for a true predicate
- raising a clear exception for failure

Avoid mixed contracts such as:

- returning `nil` for some failures and raising for others
- returning `false` or a complex object from the same method
- sometimes returning host objects and sometimes returning serialized data

## Structure Inside Methods

### Normalize Early

Normalize data at boundaries and then work with a stable internal shape.

Examples of normalization work:

- key normalization
- type coercion
- required field checks
- default handling
- structural validation

Do this once where practical. Avoid repeated re-normalization in lower layers.

### Guard Clauses

Use guard clauses to keep the main flow visible.

Prefer:

- early rejection of invalid input
- early exits for unsupported conditions
- a left-aligned happy path

Avoid deeply nested control flow when early returns make the operation clearer.

### Control Flow

Prefer straightforward Ruby.

- favor linear execution over clever chaining
- use temporary variables to name important intermediate values
- keep state changes visible
- avoid conditionals that hide side effects in expressions

If a reader has to simulate several moving parts mentally just to understand the happy path, simplify the method.

### Comments

Comments should explain intent, constraints, or non-obvious choices.

Good reasons to comment:

- host-runtime limitations
- protocol-specific constraints
- ordering dependencies
- compatibility behavior
- surprising but intentional edge cases

Do not use comments to narrate obvious Ruby.

## Operation-Shaped Code

For command-oriented runtime code, it is often correct for the main public method to read like a full operation. It may legitimately include:

- input preparation
- precondition checks
- host-state resolution
- operation wrapping
- mutation or query behavior
- result construction

This is good Ruby when the method remains one coherent operation.

Extract lower-level mechanics when:

- the same lookup or normalization appears more than once
- host interactions need isolated tests
- a branch contains its own substantial policy
- geometry, entity traversal, or transformation logic is obscuring the workflow
- response shaping is reusable or substantial

Do **not** extract purely to satisfy method-count aesthetics.

## Error Handling

Raise errors in the layer that understands the failure. Translate errors into transport or protocol responses at the boundary layer.

Examples of owned failures:

- invalid input
- unsupported operation
- missing target
- host-state conflict
- operation failure

Use specific exception classes where that improves clarity or stable handling.

Rules:

- helpers should not build protocol envelopes
- serializers should not choose transport status
- host adapters should not know wire-level error structure unless they truly are the boundary

Prefer rescue blocks at:

- protocol or transport boundaries
- operation boundaries
- top-level command execution boundaries

Avoid rescuing deep in helpers unless the helper can recover meaningfully and locally.

Error messages should be explicit and useful.

- preserve stable public messages where callers or tests depend on them
- include diagnostic context that helps debugging
- avoid leaking irrelevant internals into public contracts

## Data And Serialization

### Internal And Boundary Data

Use stable internal data conventions.

- choose one key style within a layer
- avoid passing external raw objects further than necessary
- keep data shapes predictable

Anything crossing a runtime or protocol boundary should be JSON-safe:

- hashes
- arrays
- strings
- numbers
- booleans
- `nil`

Live runtime objects should remain internal.

### Serializers

Use serializers or value objects when response shaping is repeated, substantial, or contract-sensitive.

Serializer rules:

- shape data only
- avoid hidden host lookups where practical
- avoid business policy unless the serializer explicitly owns presentational policy
- keep outputs stable and predictable

## Naming And Conventions

### Naming

- Use `snake_case` for methods and variables.
- Use clear verbs for operations.
- Use clear nouns for value objects, serializers, and adapters.
- Name methods for behavior, not implementation trivia.

### Predicates

- Predicate methods should end in `?`.
- Predicate methods should return booleans, not incidental truthy values.

### Bang Methods

Use `!` only when it communicates a real distinction:

- a stricter variant
- a mutating variant
- a version that raises instead of returning a non-exceptional result

Do not use `!` for emphasis.

### Constants

Use constants for repeated, contract-sensitive values:

- protocol method names
- public command names
- repeated keys
- error codes
- sentinel values

Avoid scattering the same string literals through many files.

### Ruby Style

- Use `# frozen_string_literal: true` where the project standard expects it.
- Prefer explicitness over metaprogramming unless metaprogramming clearly earns its complexity.
- Keep DSLs narrow and justified.
- Avoid dynamic behavior that makes control flow or ownership hard to trace.

## Host Integration Guidance

When Ruby runs inside a host process, keep host-facing code disciplined.

- Keep raw host API access behind clear seams.
- Resolve live host state close to execution when staleness matters.
- Keep host mutations explicit.
- Use operation or transaction primitives consistently when the host provides them.
- Avoid spreading host object handling across unrelated layers.

Host operation wrappers improve runtime safety, but they do not replace good code structure. They are not a reason to mix request parsing, business behavior, and result shaping into one broad method.

## Testing Expectations

Test behavior at the layer that owns it.

Prefer:

- unit tests for pure helpers, serializers, and support objects
- seam-level tests for host adapters and operation helpers
- integration tests for command flows and protocol handling
- explicit manual verification notes where host-runtime behavior cannot yet be automated

Add tests when:

- introducing a new seam
- changing a public contract
- extracting reusable logic
- changing host-mutation behavior

Do not overfit tests to private helper structure. Prefer observable behavior.

## Review Heuristics

When reviewing Ruby code, ask:

- Does this object have one primary reason to change?
- Does this public method read as one coherent operation?
- Are protocol handling, host interaction, and serialization still distinguishable?
- Is extraction happening for a real reason, not just to shrink methods?
- Are host-facing mechanics isolated enough to test and evolve?
- Are outputs explicit, stable, and JSON-safe where needed?
- Are errors raised in the right layer and translated only at boundaries?
- Is the code easier to change after this edit than before it?

## Practical Defaults

Use these as defaults, not hard laws:

- prefer cohesive public workflows over micro-methods
- prefer smaller helpers for reusable or low-level mechanics
- extract when a method mixes multiple reasons to change
- keep public APIs small
- keep return contracts explicit
- keep serializers dumb
- keep boundaries obvious
- keep Ruby boring where possible

If forced to choose between a slightly broader but readable operation and a fractured set of tiny helpers with weak names, prefer the readable operation.
