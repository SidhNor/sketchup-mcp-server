# HLD: Platform Architecture and Repo Structure

## System Overview

### Purpose

This document defines the product-agnostic platform architecture for the SketchUp MCP repository.

It is intentionally separate from the capability HLDs. Its job is to define:

- runtime boundaries
- repository structure direction
- packaging direction
- test strategy
- transport and extension platform concerns
- cross-cutting development conventions

It does not define the detailed implementation of any specific capability. Those concerns belong in:

- [`hld-semantic-scene-modeling.md`](./hld-semantic-scene-modeling.md)
- [`hld-asset-exemplar-reuse.md`](./hld-asset-exemplar-reuse.md)
- [`hld-scene-validation-and-review.md`](./hld-scene-validation-and-review.md)

### Scope

This HLD covers the base system that all capability work relies on:

- Ruby extension bootstrapping
- Python MCP server exposure
- the Ruby/Python transport boundary
- internal layering and module boundaries
- packaging and distribution
- test organization
- logging, errors, and shared runtime infrastructure

### Runtime Context

```text
External Agent / MCP Client
          |
          v
Python MCP Adapter
          |
          v
Ruby SketchUp Extension Runtime
          |
          v
SketchUp Model + Extension Data
```

### Guiding Rule

The platform exists to support a maintainable Ruby extension with a thin Python adapter. It should make capability work easier to add without forcing repeated structural redesign.

## Architecture Approach

### Overall Style

The recommended style is a modular layered monolith:

- one Ruby runtime inside SketchUp
- one Python MCP adapter process
- one explicit transport boundary between them

This avoids two failure modes:

- one giant Ruby file accumulating unrelated concerns
- Python taking on capability behavior that belongs in Ruby

### Boundary Rules

- Ruby owns SketchUp-facing behavior, entity access, mutation, serialization, and capability logic
- Python owns MCP tool registration, boundary validation, invocation, and error mapping
- transport concerns must be isolated from both capability logic and low-level SketchUp API access

### Internal Layering

The target Ruby layering is:

- boot / extension registration
- runtime bootstrap
- transport and request routing
- command or use-case layer
- shared domain and support services
- SketchUp adapters

The target Python layering is:

- MCP app boot
- tool modules by capability area
- shared invocation and connection modules
- boundary error mapping

These layers are architectural boundaries, not a promise of one exact directory shape. The repository should move toward them deliberately as the platform expands.

### Design Principles

1. Keep the extension loader small.
2. Keep Ruby code namespaced and split by responsibility.
3. Keep Python mechanical and reusable.
4. Centralize cross-cutting runtime concerns.
5. Treat tests and packaging as architectural concerns, not afterthoughts.

## Component Breakdown

### 1. Extension Registration Layer

**Responsibilities**

- register the SketchUp extension
- expose extension metadata
- load the support entrypoint

**Constraints**

- no capability logic
- no transport logic
- minimal side effects during load

### 2. Ruby Runtime Bootstrap

**Responsibilities**

- initialize the extension runtime
- expose startup hooks or menus where needed
- initialize shared services
- start and stop the transport server when needed

**Constraints**

- no feature-specific command logic
- no long direct dispatch logic as the permanent design

### 3. Ruby Transport Layer

**Responsibilities**

- accept requests from the Python adapter
- parse and validate transport envelopes
- route requests into command handlers
- return structured responses

**Recommended subcomponents**

- socket server
- request parser
- response builder
- tool registry

### 4. Ruby Command Layer

**Responsibilities**

- expose a stable execution interface for capability behavior
- translate tool requests into use-case execution
- own command-local validation and orchestration

**Constraints**

- commands should not become a dumping ground for low-level SketchUp API sprawl
- commands should delegate shared concerns to support and adapter layers

### 5. Ruby SketchUp Adapter Layer

**Responsibilities**

- encapsulate SketchUp API access
- provide entity lookup helpers
- manage tags, materials, components, bounds, operations, and serialization

**Why it matters**

This isolates SketchUp API details from higher-level command logic and reduces duplication across capabilities.

### 6. Shared Runtime Infrastructure

**Responsibilities**

- uniform result envelopes
- shared error classes
- logging
- configuration
- operation runner or operation-boundary helpers
- serialization helpers

**Goal**

Cross-cutting behavior should have one platform home so future capability work reuses it rather than redefines it.

### 7. Python MCP Application Layer

**Responsibilities**

- initialize the FastMCP app
- register tools
- group tools by capability area

### 8. Python Invocation Layer

**Responsibilities**

- build transport requests
- manage retry and timeout behavior
- parse structured responses
- map transport failures into MCP-facing errors

### 9. Packaging Layer

**Responsibilities**

- build the `.rbz` extension package
- build the Python package
- keep versioning and distribution metadata aligned

**Design direction**

Packaging should support a growing Ruby support tree rather than assume a tiny fixed file set.

### 10. Test Layer

**Responsibilities**

- support pure Ruby testing where SketchUp is not required
- support Python adapter testing
- support contract testing at the Ruby/Python boundary
- support SketchUp-hosted integration or acceptance testing

**Recommended sublayers**

- Ruby unit tests for pure logic and support services
- Python unit tests for MCP adapter and transport behavior
- contract tests for request and response envelope shaping
- SketchUp-hosted integration tests for end-to-end runtime behavior
- fixture models and scenario data for repeatable acceptance coverage

**Quality rule**

New platform infrastructure should not be considered complete unless its behavior can be verified in at least one of these test layers.

## Integration and Data Flows

### 1. Extension Startup Flow

```text
SketchUp loads extension registration file
-> Ruby bootstrap loads support runtime
-> runtime initializes shared services
-> menus / hooks / transport are prepared
```

### 2. MCP Request Flow

```text
MCP client
-> Python tool
-> Python invocation layer
-> transport request
-> Ruby transport layer
-> tool registry
-> Ruby command
-> shared services / SketchUp adapters
-> structured response
-> Python error mapping / response shaping
-> MCP response
```

### 3. Packaging Flow

```text
source tree
-> Ruby packaging step builds RBZ
-> Python packaging step builds MCP package
-> release metadata is aligned
```

### 4. Test Flow

```text
Ruby unit tests -> pure shared logic
Python tests -> adapter and transport shaping
Contract tests -> request/response compatibility
SketchUp-hosted tests -> end-to-end runtime behaviors
```

## Testing and Linting Setup

### Testing Strategy

The platform should support a layered quality model rather than relying on one heavy end-to-end suite.

#### 1. Ruby Unit Tests

**Purpose**

- verify pure logic that does not require a live SketchUp process
- verify result envelopes, metadata rules, configuration, and helper behavior

**Typical targets**

- shared support modules
- metadata and validation helpers that do not require SketchUp
- request normalization
- serializer helpers that can be exercised without live entities
- shared configuration or result-shaping logic

**Expected characteristics**

- fast
- deterministic
- runnable locally without SketchUp

#### 2. Python Unit Tests

**Purpose**

- verify MCP tool registration
- verify transport request shaping
- verify timeout, retry, parsing, and error mapping behavior

**Typical targets**

- invocation helpers
- tool wrappers
- response parsing
- MCP-facing error envelopes

#### 3. Contract Tests

**Purpose**

- ensure Python and Ruby continue to agree on request and response envelopes
- catch breaking changes in tool names, argument shape, and result schema

**Typical targets**

- JSON request envelopes
- structured error payloads
- normalized result envelopes

#### 4. SketchUp-Hosted Integration Tests

**Purpose**

- verify behavior that depends on real SketchUp runtime semantics
- verify mutation behavior, tags, materials, component interactions, and operation boundaries

**Typical targets**

- entity creation and mutation
- attribute dictionary persistence
- model fixtures
- asset library protection rules
- transport-to-command-to-model execution paths

**Tooling direction**

- TestUp 2 or an equivalent SketchUp-hosted integration approach should be the default direction for this layer

#### 5. Scenario / Acceptance Tests

**Purpose**

- verify higher-level workflows against fixture `.skp` models
- serve as regression coverage for important user flows

**Typical targets**

- startup and connection sanity
- representative MCP request sequences
- packaging smoke tests where feasible
- key workflows called out in capability HLDs

### Test Ownership Model

| Layer | Primary Owner | What It Protects |
| --- | --- | --- |
| Ruby unit tests | Ruby/platform contributors | support services and non-SketchUp runtime logic |
| Python unit tests | Python/MCP contributors | MCP adapter and invocation behavior |
| contract tests | platform owners | runtime boundary compatibility |
| SketchUp-hosted integration tests | platform + capability contributors | actual SketchUp behavior |
| scenario / acceptance tests | capability owners | user-visible workflow regressions |

### Fixture Strategy

Fixture assets should be treated as part of the platform, not as throwaway test data.

#### Fixture Types

- minimal synthetic `.skp` models for low-level behaviors
- capability-oriented `.skp` models for acceptance scenarios
- structured request/response fixtures for contract tests
- staged asset fixture libraries for asset-protection and instancing tests

#### Fixture Rules

- keep fixtures small and purpose-specific
- version fixture models explicitly where practical
- document what each fixture is meant to prove
- avoid one giant "everything" fixture model
- add fixtures close to the test layer that owns them

### Linting and Static Quality Setup

Linting should be explicit and language-specific.

#### Ruby Quality Checks

**Recommended tools**

- RuboCop for style, consistency, and basic static checks

**Scope**

- extension loader
- runtime code
- support services
- packaging scripts where practical

#### Python Quality Checks

**Recommended tools**

- Ruff for linting and formatting checks

**Scope**

- MCP adapter modules
- invocation and transport code
- Python tests

#### Documentation Quality Checks

**Recommended approach**

- markdown linting or lightweight review rules for `specifications/`
- link checks for internal document references where practical

### Local Development Quality Workflow

The default local workflow should be:

1. run fast Ruby unit tests if the change touches Ruby shared logic
2. run Python unit tests if the change touches the MCP adapter
3. run linting for the language or languages changed
4. run the smallest relevant SketchUp-hosted or scenario test for runtime changes
5. note any gaps when a layer cannot be exercised

### CI Quality Gates

The platform should evolve toward these default gates:

- Ruby linting passes
- Python linting passes
- Python unit tests pass
- contract tests pass
- selected Ruby unit tests pass
- selected scenario or smoke tests pass

SketchUp-hosted integration tests may need a separate workflow or release gate if they are not practical in the main CI path, but they should still exist as a formal part of the platform.

### Testability Requirements for Platform Changes

Any new platform abstraction should be designed so that at least one of the following is possible:

- isolated unit testing without SketchUp
- contract testing at the Python/Ruby boundary
- deterministic SketchUp-hosted integration testing

If a platform change cannot be verified in any of those ways, it should be treated as a design smell and revisited.

## Key Architectural Decisions

### 1. Ruby Remains the Source of Truth

**Decision**

All SketchUp-facing and capability-defining behavior lives in Ruby.

**Reason**

It keeps the domain model close to the SketchUp API and prevents duplicated business rules.

### 2. Python Remains a Thin Adapter

**Decision**

Python should expose tools, validate boundary inputs, and invoke Ruby. It should not accumulate domain policy.

**Reason**

This preserves a clear boundary and keeps the MCP adapter maintainable.

### 3. Small Loader, Large Support Tree

**Decision**

The extension registration file should stay small and load a support tree with the real runtime code.

**Reason**

This matches common SketchUp extension practice and avoids boot files becoming implementation hotspots.

### 4. Modular Support Tree Over Flat Growth

**Decision**

The Ruby runtime should be split into transport, commands, support, and SketchUp adapter areas.

**Reason**

This supports sustained growth without forcing feature logic into one file.

### 5. Shared Infrastructure Is Centralized

**Decision**

Results, errors, logging, configuration, and operation boundaries should be centralized.

**Reason**

Cross-cutting concerns become unstable quickly if scattered.

### 6. Packaging Must Support Growth

**Decision**

Packaging should operate on the whole support tree rather than a small fixed file list.

**Reason**

A modular runtime is incompatible with brittle packaging assumptions.

### 7. Testing Is Part of the Platform

**Decision**

Testing structure is part of the target platform design.

**Reason**

Capability HLDs will depend on platform-level confidence mechanisms and fixtures.

### 8. Linting Is a Required Quality Gate

**Decision**

Linting and static quality checks should be first-class platform requirements, not optional cleanup tasks.

**Reason**

The repo spans Ruby, Python, packaging scripts, and specifications. Without explicit language-level gates, drift and inconsistency will compound quickly.

## Technology Stack

| Layer | Technology | Purpose |
| --- | --- | --- |
| SketchUp runtime | SketchUp Ruby API | extension runtime and model access |
| Core extension language | Ruby | extension behavior and capability logic |
| MCP adapter | Python 3 + FastMCP | external tool exposure |
| Transport | local TCP socket with structured JSON payloads | Python-to-Ruby invocation |
| Ruby packaging | RBZ packaging script | extension distribution |
| Python packaging | current Python packaging toolchain | MCP server distribution |
| Ruby unit tests | lightweight Ruby test harness | pure Ruby support and domain logic |
| Python tests | `pytest` | adapter and transport tests |
| Python linting / formatting | Ruff | Python quality and consistency |
| Ruby linting | RuboCop | code quality |
| SketchUp-hosted tests | TestUp 2 or equivalent | in-SketchUp acceptance testing |
| documentation checks | markdown linting / link checks where practical | specification hygiene |

## Open Questions

1. What final directory layout should be considered the stable support-tree structure?
2. Should the transport stay one-request-per-connection long-term or be optimized later?
3. What shared response envelope should all Ruby commands standardize on?
4. How should extension and Python package versioning be synchronized?
5. What is the minimum acceptable Ruby unit-testing harness for non-SketchUp logic?
6. Should the repo support separate developer packaging and release packaging flows?
7. How should fixture `.skp` models be organized and versioned?
8. Should the platform add explicit reload or development helper tooling for faster SketchUp iteration?
9. Which subset of SketchUp-hosted tests should be mandatory in CI versus release validation only?
10. What documentation quality checks are worth enforcing automatically versus keeping as review expectations?
