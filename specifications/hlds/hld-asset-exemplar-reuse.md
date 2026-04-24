# HLD: Asset Exemplar Reuse

## System Overview

### Purpose

This HLD covers the implementation approach for the capability defined in [`prd-staged-asset-reuse.md`](../prds/prd-staged-asset-reuse.md).

It focuses on:

- Asset Exemplar discovery
- Asset Instance creation
- Asset Exemplar protection
- replacement flows
- source asset lineage

### Capability Intent

This capability turns the Asset Exemplar library concept into a reliable product workflow. The system should reuse curated Asset Exemplars safely and convert them into editable Asset Instances without damaging the library source objects.

### Capability Scope

Initial scope:

- `list_staged_assets`
- `instantiate_staged_asset`
- `replace_with_staged_asset`
- Asset Exemplar metadata and approval handling
- Asset Exemplar integrity checks

## Architecture Approach

### Core Approach

Implement asset reuse around four concepts:

1. **Asset Exemplar registry and discovery**
2. **approval-state enforcement**
3. **Asset Instance creation with lineage**
4. **Asset Exemplar protection**

### Internal Structure for This Capability

- Asset Exemplar query command
- Asset Instance creation command
- replacement command
- Asset Exemplar metadata rules
- integrity and protection checks
- lineage serializer helpers

### Separation Model

This capability must maintain a hard separation between:

- Asset Exemplars in the library/staging area
- Asset Instances in the editable design scene

This separation should be visible in:

- metadata
- Collection placement
- validation rules
- replacement flows

## Component Breakdown

### 1. Asset Exemplar Discovery Component

**Responsibilities**

- locate approved Asset Exemplars
- filter by asset metadata
- return summarized selection-friendly results

### 2. Asset Exemplar Policy Component

**Responsibilities**

- define approval-state rules
- enforce minimum metadata requirements
- determine whether an Asset Exemplar is reusable

### 3. Asset Instance Creation Component

**Responsibilities**

- instantiate or duplicate the chosen Asset Exemplar
- place the result in the editable scene
- assign lineage metadata
- mark the result as an Asset Instance and Managed Scene Object

### 4. Replacement Component

**Responsibilities**

- replace a Tree Proxy or similar lower-fidelity object
- preserve business identity
- preserve semantic role
- assign new source asset lineage

### 5. Integrity / Protection Component

**Responsibilities**

- block or detect in-place edits to Asset Exemplars
- verify Asset Exemplar library invariants

## Integration & Data Flows

### 1. Discovery Flow

```text
Agent -> list_staged_assets
-> filter normalization
-> Asset Exemplar query
-> approval-state filtering
-> summarized result response
```

### 2. Instantiation Flow

```text
Agent -> instantiate_staged_asset
-> resolve Asset Exemplar
-> verify approval and integrity
-> create Asset Instance
-> apply placement / scale / Collection / Tags
-> write lineage metadata
-> serialize result
```

### 3. Replacement Flow

```text
Agent -> replace_with_staged_asset
-> resolve target object
-> resolve Asset Exemplar
-> create replacement Asset Instance
-> preserve sourceElementId and semantic role
-> archive or remove previous representation
-> serialize result
```

### 4. Integrity Validation Flow

```text
Asset operation occurs
-> integrity checks evaluate Asset Exemplar invariants
-> violations surfaced to validation or command results
```

## Key Architectural Decisions

### 1. Asset Exemplars and Asset Instances Are Different Domain Objects

**Decision**

Do not treat a reused library object and an editable scene object as the same thing.

**Reason**

This is necessary to protect library integrity and preserve predictable reuse behavior.

### 2. Approval State Is a Product Gate

**Decision**

Only approved Asset Exemplars should be discoverable by normal reuse flows.

**Reason**

The PRD depends on curation and consistent asset quality.

### 3. Lineage Is Written at Instantiation Time

**Decision**

Asset source lineage is mandatory when creating an Asset Instance.

**Reason**

Without lineage, replacement, validation, and review all become weaker.

### 4. Replacement Preserves Business Identity

**Decision**

Replacement changes representation, not business identity.

**Reason**

The same source element may evolve from proxy to high-fidelity representation.

### 5. Discovery Returns Summaries, Not Raw Scene Objects

**Decision**

The selection workflow should use structured summaries.

**Reason**

It keeps the capability MCP-friendly and avoids leaking SketchUp internals.

## Technology Stack

| Concern | Technology / Approach | Purpose |
| --- | --- | --- |
| asset metadata | Ruby metadata service via attribute dictionaries | Asset Exemplar classification |
| asset discovery | Ruby query helpers | filtered Asset Exemplar lookup |
| instantiation | SketchUp groups / component instances | Asset Instance creation |
| lineage tracking | metadata + serializer | traceability |
| MCP exposure | MCP tools | external interface |

## Opened Questions

1. Should Asset Instance creation prefer component instancing, duplication, or policy-driven selection?
2. What exact metadata is required for an Asset Exemplar to be approved?
3. How should deprecation and versioning of Asset Exemplars be represented?
4. What protections should block in-place edits versus only detect and report them?
5. Should the first release support separate Asset Exemplar libraries by category, or one unified library with metadata filters?
