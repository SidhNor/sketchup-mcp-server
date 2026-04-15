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
**Status**: `actioned`
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

## Structured Expansion Plan

### Expansion Outcome

This signal expansion preserves the original capability ownership:

- the owning capability remains `semantic scene modeling`
- no new capability is needed at this stage
- no new PRD is needed at this stage

The expansion also narrows the planning posture:

- hierarchy-aware managed-object maintenance is the most important follow-on gap
- rare accepted objects that still lack semantic metadata do not justify a dedicated adoption or backfill slice right now
- `SEM-03` should be refined while still unimplemented so it does not assume a flat scene
- full reparent, replace, and duplicate-into-parent lifecycle operations should remain a dedicated follow-on after `SEM-03`

### Required Specification Edits

#### 1. Semantic PRD update

Target file:

- `specifications/prds/prd-semantic-scene-modeling.md`

Required edits:

- add explicit product language that Managed Scene Objects may live inside nested groups or components and must remain maintainable there through normal semantic workflows
- clarify that supported revision, regroup, duplicate, and replacement flows must preserve intended parent placement and business identity
- add an explicit hierarchy-aware maintenance expectation so the semantic surface is not interpreted as top-level-only scene management

Purpose:

- make hierarchy-aware lifecycle behavior a planned product requirement rather than only an implementation concern inferred from signals and HLD language

#### 2. Semantic HLD update

Target file:

- `specifications/hlds/hld-semantic-scene-modeling.md`

Required edits:

- add an explicit architecture posture for nested managed objects in grouped scene structure
- state that semantic lifecycle helpers must work against nested scene hierarchy without introducing a second lookup subsystem
- describe parent-context preservation as part of semantic mutation and lifecycle safety
- explicitly name the planned follow-on lifecycle primitives:
  - inspect active edit context
  - reparent
  - duplicate into a target parent while preserving metadata and geometry
  - replace with identity handoff

Purpose:

- keep hierarchy-aware lifecycle behavior within the semantic capability while preserving the existing targeting and platform boundaries

#### 3. `SEM-03` task update

Target file:

- `specifications/tasks/semantic-scene-modeling/SEM-03-add-metadata-mutation-for-managed-scene-objects/task.md`

Required edits:

- update the task acceptance criteria so `set_entity_metadata` must work for nested Managed Scene Objects rather than only easy top-level cases
- clarify that target resolution and metadata mutation must preserve the object's existing parent placement and scene context
- keep reparent or replacement behavior out of scope for `SEM-03`

Purpose:

- prevent `SEM-03` from landing with a flat-scene assumption that would make later hierarchy work more expensive

#### 4. `SEM-03` technical plan update

Target file:

- `specifications/tasks/semantic-scene-modeling/SEM-03-add-metadata-mutation-for-managed-scene-objects/plan.md`

Required edits:

- add explicit nested-hierarchy targeting cases to the technical design
- require tests and contract coverage for nested managed objects
- add manual or hosted verification expectations for nested managed-object mutation where practical
- preserve the current non-goal boundary:
  - no full reparent tool
  - no full replacement flow
  - no broad hierarchy query surface

Purpose:

- make the implementation plan reflect the real scene-management constraints already visible in authoring sessions

#### 5. Follow-on semantic lifecycle task definition

Target area:

- `specifications/tasks/semantic-scene-modeling/`

Required edits:

- add a new post-`SEM-03` follow-on task or task set for hierarchy-aware semantic lifecycle operations
- scope that follow-on around:
  - active edit context inspection
  - reparent
  - duplicate into target parent
  - identity-preserving replacement
- keep the ownership in semantic modeling rather than splitting it into a new capability unless later discovery shows the workflow abstraction is broader than managed-object maintenance

Purpose:

- separate metadata mutation from heavier lifecycle operations while preserving the right next implementation path

#### 6. Unit-contract follow-on review

Target files:

- semantic capability artifacts and any owning contract or implementation tasks that define semantic authoring boundaries

Required edits:

- confirm where strict meter-based semantic authoring requirements should be made explicit if they are not already captured strongly enough in the owning artifacts
- ensure future lifecycle work does not treat unit correctness as an implementation-only detail

Purpose:

- preserve the strongest correctness finding from the originating session without forcing this signal to over-prescribe the exact owning task prematurely

### Explicit No-Change Decisions

The expansion also records decisions about what should **not** be added right now:

- do not add a new capability for this signal
- do not create a new PRD solely for this signal
- do not add a dedicated metadata adoption or backfill workflow for the small number of accepted objects that currently lack semantic metadata
- do not widen `SEM-03` into full reparent, replacement, or duplicate-into-parent behavior

### Planning Order

Recommended order for the resulting edits:

1. Update the semantic PRD and semantic HLD to make the hierarchy-aware lifecycle posture explicit.
2. Update the `SEM-03` task and technical plan so metadata mutation is designed and tested for nested managed objects.
3. After `SEM-03`, define the dedicated follow-on semantic lifecycle task for hierarchy operations.
4. During that follow-on planning, tighten the owning meter-contract language if the relevant semantic or platform artifacts still leave room for ambiguity.
