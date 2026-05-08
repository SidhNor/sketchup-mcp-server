# Task: MTA-31 Enable CDT Terrain Output After Disabled Scaffold
**Task ID**: `MTA-31`
**Title**: `Enable CDT Terrain Output After Disabled Scaffold`
**Status**: `draft`
**Priority**: `P1`
**Date**: `2026-05-08`

## Linked HLD

- [Managed Terrain Surface Authoring](../../../hlds/hld-managed-terrain-surface-authoring.md)

## Problem Statement

MTA-25 established a production-owned CDT terrain output scaffold but closed with CDT disabled by
default. Live SketchUp validation showed that enabling CDT without a deeper plan can make normal
terrain editing unacceptable: a representative terrain with hundreds of accumulated feature intents
can hang for minutes on a single small target-height edit. The same investigation exposed additional
enablement risks around accumulated feature-intent semantics, CDT input containment near terrain
boundaries, unclear output module naming, and the unresolved Ruby-versus-native triangulation
decision.

This task defines the next enablement milestone: make CDT safe to consider for default production
terrain output by proving bounded performance, feature-intent scalability, geometry containment,
clear module ownership, and a native/C++ adapter decision path while preserving the current terrain
output backend as the production default until evidence supports changing that posture.

## Goals

- Define and validate the effective feature-intent set consumed by CDT on terrains with large edit
  histories.
- Prove that a single new edit on a representative terrain with hundreds of prior feature intents
  completes within an explicit production budget.
- Ensure feature-intent override, deprecation, replacement, and merge semantics are respected before
  CDT input generation.
- Bound CDT input size and relevance for create/edit output without losing required active feature
  constraints.
- Prevent CDT triangulation inputs from expanding output geometry outside the managed terrain
  domain.
- Profile CDT enablement by phase so performance bottlenecks are attributable and actionable.
- Decide whether Ruby CDT is viable for production enablement or whether a native/C++ triangulation
  adapter is required.
- Clean up CDT output module naming and ownership so production, validation, adapter, and prototype
  responsibilities are inspectable.
- Preserve current terrain output behavior by default until enablement evidence passes.

## Acceptance Criteria

```gherkin
Scenario: current output remains the default until CDT enablement is proven
  Given the extension is loaded with default configuration
  When managed terrain create or edit output is generated
  Then the current terrain output backend remains the active default
  And CDT is not attempted unless an internal enablement switch or test injection explicitly enables it
  And public MCP responses remain unchanged

Scenario: effective feature-intent set is bounded and semantically correct
  Given a managed terrain state with hundreds of historical feature intents
  And those intents include overrides, deprecated intents, replacements, and merged edit histories
  When CDT feature geometry is prepared
  Then only active effective feature intents are included in CDT input
  And superseded or deprecated intents are excluded
  And the resulting feature geometry records enough diagnostics to explain included and excluded counts

Scenario: representative large-history edit meets a production budget
  Given a representative managed terrain fixture with hundreds of accumulated feature intents
  When a single small target-height edit is applied
  Then terrain output generation completes within the planned production time budget
  And the result does not hang SketchUp or the MCP command path for minutes
  And timing evidence separates feature-geometry preparation, point planning, residual metering,
      triangulation, and SketchUp mutation

Scenario: CDT input selection is relevant to the current output
  Given active feature intents span regions outside the current edit influence and output relevance
  When CDT input is generated for create or edit output
  Then active hard constraints required for output correctness are preserved
  And non-relevant soft or historical feature pressure does not unboundedly inflate CDT point,
      segment, or residual-refinement inputs
  And input budgets produce deterministic diagnostics when exceeded

Scenario: CDT output stays inside the managed terrain domain
  Given corridor side/cap references, protected regions, or other feature geometry near terrain
      boundaries
  When CDT output is generated
  Then emitted vertices and faces stay inside the managed terrain XY domain
  And out-of-domain reference or pressure geometry cannot expand the output hull
  And any clipped, ignored, or unsupported feature geometry is recorded as an internal diagnostic

Scenario: CDT module ownership is coherent
  Given the terrain output folder contains CDT production, validation, adapter, and prototype-derived
      collaborators
  When the CDT enablement implementation is reviewed
  Then file names and namespaces clearly distinguish production runtime ownership from validation
      wrappers and adapter contracts
  And MTA-24 candidate/probe vocabulary does not appear in production runtime ownership
  And obsolete or misleading CDT files are renamed, relocated, or explicitly documented

Scenario: native triangulation decision is evidence based
  Given Ruby CDT profiling and robustness evidence has been collected on representative fixtures
  When the enablement decision is made
  Then the task records whether Ruby CDT can meet production budgets
  And if Ruby CDT cannot meet those budgets, a native/C++ adapter path is selected or explicitly
      deferred with evidence
  And native-unavailable and native-input-violation posture remains deterministic and package-safe

Scenario: hosted SketchUp acceptance proves safe enablement
  Given local tests and profiling pass
  When hosted SketchUp validation runs against representative terrain families
  Then accepted CDT output has valid topology, bounded residuals, contained geometry, and acceptable
      runtime
  And fallback cases keep current backend output without corrupting terrain state
  And save-copy, undo, visual geometry, entity-count, and public no-leak evidence are recorded
```

## Non-Goals

- Enabling CDT by default before performance, feature-intent, and geometry-containment evidence
  passes.
- Replacing existing terrain edit kernels.
- Adding public backend selectors, public CDT diagnostics, or user-facing simplification knobs.
- Re-running MTA-24 as a comparison-only bakeoff without production enablement gates.
- Shipping native/C++ binaries without a packaging, fallback, and license decision.
- Solving broad terrain UI tasks unrelated to CDT output enablement.
- Removing the current production terrain output backend before CDT is proven.

## Business Constraints

- Normal terrain editing must remain responsive and must not hang for minutes on representative
  customer-like terrain histories.
- Existing current-backend terrain output remains the supported production behavior until CDT
  enablement evidence justifies changing the default.
- The task must create confidence for future default enablement, not merely add another prototype
  path.
- Public MCP contracts and user workflows must remain stable unless a separate contract-change task
  is defined.
- Follow-up work must be explicit enough to prevent another patch-stack implementation drift.

## Technical Constraints

- Terrain state remains authoritative; generated output remains disposable derived geometry.
- CDT compute collaborators must remain data-only and must not mutate SketchUp entities directly.
- Old derived output must not be erased until a chosen output path is ready to emit.
- CDT input must be derived from production terrain state and `TerrainFeatureGeometry`, not raw
  SketchUp objects or MTA-24 candidate rows.
- Effective feature-intent computation must handle accumulated histories, overrides, deprecations,
  replacements, and merges deterministically.
- Performance instrumentation must separate feature-geometry preparation, point planning, residual
  metering, triangulation, gating, and SketchUp mutation.
- Native/C++ evaluation, if pursued, must remain behind the production adapter/result envelope and
  must preserve deterministic fallback when native support is unavailable or input is unsupported.
- Public terrain responses must not leak raw CDT triangles, solver predicates, adapter limitations,
  native details, internal fallback enums, or MTA-24 vocabulary.

## Dependencies

- `MTA-20`
- `MTA-24`
- `MTA-25`
- representative large-history managed terrain fixture from MTA-25 live validation
- [Managed Terrain Surface Authoring HLD](../../../hlds/hld-managed-terrain-surface-authoring.md)
- [SketchUp Extension Development Guidance](../../../guidelines/sketchup-extension-development-guidance.md)

## Relationships

- follows `MTA-25` because MTA-25 leaves CDT disabled by default and records enablement blockers
- consumes the MTA-25 disabled scaffold, live findings, and rework notes
- may create or unblock a later default-enable task only after performance and hosted evidence pass
- informs future native/C++ triangulation packaging work if Ruby CDT cannot meet production budgets
- informs CDT output module cleanup before the output folder grows more ambiguous

## Related Technical Plan

- none yet

## Success Metrics

- Default managed terrain create/edit output remains current-backend behavior until CDT is explicitly
  enabled.
- A representative terrain with hundreds of feature intents can accept a single small edit without
  minute-scale hangs.
- CDT input generation reports bounded active feature counts and excludes superseded/deprecated
  feature intents.
- Profiling evidence identifies the dominant CDT cost centers on representative fixtures.
- CDT accepted output remains inside the managed terrain domain in boundary/corridor cases.
- Module naming and ownership clearly separate production CDT runtime, validation wrappers, adapter
  contracts, and prototype-derived implementation details.
- The task records an evidence-backed Ruby-versus-native triangulation decision.
- Hosted SketchUp evidence supports either safe CDT enablement or a clear decision to keep CDT
  disabled with specific remaining blockers.
