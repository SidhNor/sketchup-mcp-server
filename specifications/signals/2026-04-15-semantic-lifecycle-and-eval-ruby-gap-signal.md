# Signal: Semantic Lifecycle Gaps Still Force Eval Ruby Fallbacks

**Date**: `2026-04-15`
**Source**: Session notes distilled from [signal-scratch.md](./signal-scratch.md)
**Related HLDs**:
- [Semantic Scene Modeling](../hlds/hld-semantic-scene-modeling.md)
- [Scene Targeting And Interrogation](../hlds/hld-scene-targeting-and-interrogation.md)
- [Platform Architecture And Repo Structure](../hlds/hld-platform-architecture-and-repo-structure.md)
**Related Tasks**:
- [SEM-02 Complete First-Wave Semantic Creation Vocabulary](../tasks/semantic-scene-modeling/SEM-02-complete-first-wave-semantic-creation-vocabulary/task.md)
- [SEM-03 Add Metadata Mutation For Managed Scene Objects](../tasks/semantic-scene-modeling/SEM-03-add-metadata-mutation-for-managed-scene-objects/task.md)
**Status**: `captured`
**Disposition**: `follow-up recommended across semantic lifecycle and bridge tooling`

## Summary

A recent scene-authoring session exposed a clear boundary in the current MCP surface:

- the public tools are good enough for bounded creation, coarse inspection, and some verification
- they are not yet good enough for semantic lifecycle management of accepted scene objects

`eval_ruby` was not used because the public MCP surface was broadly ineffective. It was used because the session crossed from:

- create/query

into:

- repair
- replace
- reparent
- merge
- metadata inspection and correction
- unit-sensitive scene repair

The central signal is that the platform has made progress on semantic object creation, but it still lacks enough first-class primitives for managed scene maintenance once objects already exist in a governed 3D workflow.

## Main Pain Points Revealed By The Session

### 1. Capability mismatch between intended semantic surface and live bridge behavior

The live `create_site_element` behavior still acted like the `SEM-01` slice:

- `pad`
- `structure`

When the session attempted `tree_proxy`, the bridge returned `unsupported_element_type`.

This means the conceptual or code-level semantic surface and the live bridge behavior were out of sync during the session. That is a product and platform trust problem, not just a missing feature.

### 2. Unit-boundary ambiguity at the bridge

The repo and 3D contracts are meter-based, but managed structure creation behaved as though numeric payloads were being interpreted through raw SketchUp internal length behavior rather than the repo’s meter semantics.

Observed effect:

- the first recreated house was authored at the wrong physical size

This was the single most important behavioral bug surfaced by the session because it affects authoring correctness even when the rest of the semantic flow succeeds.

### 3. No first-class scene hierarchy operations for managed object workflows

The session needed to create and maintain canonical pass roots and place new managed objects under the correct accepted hierarchy.

The MCP surface did not expose first-class operations for:

- entering a specific edit path reliably
- inspecting the current active edit context
- reparenting an entity into another group
- duplicating an entity into a different parent while preserving geometry and metadata
- removing the old sibling cleanly after replacement

This is a lifecycle gap rather than a simple creation gap.

### 4. No first-class metadata inspection or metadata update path

The session needed exact visibility into `su_mcp` attributes and dictionary state in order to work safely.

The public surface did not expose first-class operations for:

- reading all attribute dictionaries on an entity
- updating metadata on an existing entity
- copying metadata from one entity to another

This made direct Ruby inspection and mutation the only practical path for several operations.

### 5. Semantic targeting was only strong when metadata already existed

`find_entities` by `sourceElementId` is valuable when objects already carry managed semantic metadata.

In the session, several accepted objects did not yet carry durable managed bindings, so high-level targeting fell back to weaker identity strategies:

- names
- persistent ids
- scene hierarchy context

That made targeting possible, but brittle.

### 6. Verification tools were useful but still had edge-case friction

`sample_surface_z` helped, but it was not completely smooth in the session:

- `visibleOnly: true` could produce misleading `miss` results under modeled objects
- `ignoreTargets` did not resolve as expected for some managed-object cases

So verification exists, but still requires careful operator interpretation in lifecycle-heavy scenarios.

## Why Eval Ruby Was Needed

The session consistently used `eval_ruby` for four categories of work:

### 1. Scene hierarchy inspection and control

- inspect `active_path`
- inspect nested pass roots and child placement
- ensure authoring occurred in the correct context

### 2. Metadata visibility and mutation

- inspect raw attribute dictionaries
- confirm whether managed metadata existed
- copy or attach `su_mcp` metadata directly

### 3. Replacement and reparenting flows

- move a newly created managed object under the canonical accepted root
- replace an unmanaged accepted object with a managed equivalent
- preserve geometry while changing semantic identity and metadata state

### 4. Atomic repair operations

- inspect actual geometry state
- correct wrong-size authoring
- perform several low-level SketchUp actions safely in one operation boundary

The repeated theme was not “public tools are useless.” It was:

- public tools cover bounded semantic creation
- `eval_ruby` still covers governed semantic maintenance

## What Full Metadata Coverage Would Have Changed

If all accepted objects already had correct semantic metadata, the session would have relied on higher-level MCP tools more often.

### What would have improved immediately

- semantic targeting through `find_entities` would have been much stronger
- verification could have been more semantic-first and less geometry-first
- accepted object bookkeeping would have been safer and less dependent on names and persistent ids
- merge and review confidence would have improved because semantic identity continuity would be explicit

### What metadata alone would not have solved

- the live `tree_proxy` capability mismatch
- the simplistic structure-authoring shape for multilevel or more complex forms
- missing scene reparent / replace / duplicate operations
- the weak external unit contract at the tool boundary
- the lack of public metadata mutation tools

So the correct conclusion is:

- full metadata coverage would have reduced `eval_ruby` usage materially
- it would not have eliminated `eval_ruby` under the current MCP surface

## Core Platform Signal

The current platform is stronger at:

- semantic creation
- coarse scene inspection
- targeted verification once operators know the right flags

It is still weak at:

- semantic lifecycle management
- metadata-centric maintenance
- canonical object replacement workflows
- hierarchy-aware accepted-scene repair
- unit-safe authoring without agent-side inference

That makes the current gap structural:

- the semantic surface is moving from “can create managed objects”
- toward “can govern accepted scene state safely”

The tooling has not fully caught up to that second requirement.

## Most Important Follow-On Gaps Preserved By This Signal

### 1. The external unit contract for semantic authoring needs to become strict and explicit

Preferably:

- meter-based at the public boundary
- validated consistently at the bridge
- verified by contract and integration coverage

### 2. Live capability exposure must match the running bridge

If the live bridge still only supports the `SEM-01` semantic slice, public capability signaling must not imply more than that.

### 3. Metadata read/write primitives need to become first-class

Especially for managed object maintenance:

- inspect metadata
- update metadata
- copy metadata

### 4. Scene lifecycle operations need first-class support

Especially:

- inspect active edit context
- create or preserve pass roots
- reparent
- replace
- duplicate into a target parent while preserving metadata and geometry

### 5. Canonical accepted objects become much more governable once semantic metadata is present consistently

That suggests metadata backfill or upgrade flows may be strategically important even if they are not the same thing as first-wave semantic creation.

## Planning Outcome

This signal does not argue that the current MCP surface failed.

It argues something narrower and more important:

- the current surface is sufficient for bounded semantic creation workflows
- it is not yet sufficient for full accepted-scene semantic lifecycle workflows

That distinction should shape future planning so new work is not framed only as:

- “add more semantic types”

when the actual operator pain is increasingly:

- “manage, repair, replace, and verify accepted managed objects safely”

## Follow-On Question Preserved By This Signal

`What is the smallest first-class MCP lifecycle surface that would let agents replace, reparent, inspect metadata, and repair accepted semantic scene objects without falling back to eval_ruby for governed scene maintenance?`
