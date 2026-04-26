# Task Estimation Taxonomy

Use this taxonomy for `size.md` identity fields, retrieval tags, analog search, and calibration notes.

The goal is stable retrieval. Prefer a small shared vocabulary over one-off phrasing.

## Tag Rules

- Use lowercase kebab-case values.
- Use one concept per tag.
- Prefer several atomic tags over one compound tag.
- Keep retrieval tags compact; include only facets that help find useful analogs.
- Do not encode scores in tags except the explicit level tags.
- Do not invent synonyms when a canonical value exists.
- If no value fits, use `unclassified:<short-value>` and mention the proposed new value in notes.
- Keep historical odd tags readable, but normalize touched ledgers to canonical tags when they are next edited.

Bad:

```md
- `systems:terrain-state-serializer-repository-migration-compatibility`
- `validation:mixed-performance-manual`
- `confidence:high-pending-live`
```

Good:

```md
- `scope:managed-terrain`
- `systems:terrain-state`
- `systems:serialization`
- `systems:repository`
- `systems:migration`
- `validation:migration`
- `validation:performance`
- `host:routine-matrix`
- `confidence:medium`
```

## Archetype Tags

Use one primary `archetype:*` tag.

- `archetype:feature`
- `archetype:bugfix`
- `archetype:refactor`
- `archetype:migration`
- `archetype:integration`
- `archetype:platform`
- `archetype:validation-heavy`
- `archetype:performance-sensitive`
- `archetype:docs-specs`
- `archetype:test-infrastructure`

## Scope Tags

Use one primary `scope:*` tag and optional secondary scope tags.

- `scope:platform`
- `scope:docs-specs`
- `scope:semantic-scene-modeling`
- `scope:scene-targeting-interrogation`
- `scope:scene-validation-review`
- `scope:managed-terrain`
- `scope:staged-asset-reuse`
- `scope:packaging-release`
- `scope:runtime-transport`
- `scope:testing-infrastructure`

## System Tags

Use one tag for each material system or seam touched.

- `systems:loader-schema`
- `systems:runtime-dispatch`
- `systems:command-layer`
- `systems:tool-response`
- `systems:public-contract`
- `systems:native-contract-fixtures`
- `systems:python-bridge`
- `systems:serialization`
- `systems:target-resolution`
- `systems:scene-query`
- `systems:scene-mutation`
- `systems:managed-object-metadata`
- `systems:semantic-builders`
- `systems:semantic-hosting`
- `systems:surface-sampling`
- `systems:measurement-service`
- `systems:validation-service`
- `systems:terrain-state`
- `systems:terrain-storage`
- `systems:terrain-repository`
- `systems:terrain-kernel`
- `systems:terrain-output`
- `systems:terrain-mesh-generator`
- `systems:asset-metadata`
- `systems:asset-query`
- `systems:asset-protection`
- `systems:docs`
- `systems:packaging`
- `systems:test-support`

## Validation Tags

Validation tags describe proof modes, not burden by themselves.

Use only validation modes that help retrieval. Do not list routine unit, lint, package, full-suite, or review checks on every task unless that mode is the distinguishing feature of the task.

- `validation:docs-check`
- `validation:contract`
- `validation:public-client-smoke`
- `validation:hosted-smoke`
- `validation:hosted-matrix`
- `validation:performance`
- `validation:persistence`
- `validation:undo`
- `validation:migration`
- `validation:compatibility`
- `validation:regression`

## Host Tags

Host tags describe SketchUp-hosted validation shape and retest-loop behavior.

- `host:not-needed`
- `host:not-run-gap`
- `host:routine-smoke`
- `host:routine-matrix`
- `host:special-scene`
- `host:single-fix-loop`
- `host:repeated-fix-loop`
- `host:blocked-matrix`
- `host:redeploy-restart`
- `host:save-reopen`
- `host:undo`
- `host:performance`
- `host:wrong-runtime-risk`

Routine hosted matrices are normal in this repo. Do not use `host:routine-matrix` alone as evidence for high validation burden.

## Contract Tags

Use contract tags when public or shared boundary shape is material.

- `contract:none`
- `contract:public-tool`
- `contract:loader-schema`
- `contract:native-fixture`
- `contract:runtime-dispatch`
- `contract:response-shape`
- `contract:finite-options`
- `contract:docs-examples`
- `contract:no-public-shape-change`

## Risk Tags

Use risk tags for dominant actual failure modes or predicted estimate breakers.

- `risk:none`
- `risk:host-api-mismatch`
- `risk:host-persistence-mismatch`
- `risk:wrong-live-runtime`
- `risk:unit-conversion`
- `risk:transform-semantics`
- `risk:visibility-semantics`
- `risk:undo-semantics`
- `risk:performance-scaling`
- `risk:metadata-storage`
- `risk:contract-drift`
- `risk:schema-requiredness`
- `risk:partial-state`
- `risk:regression-breadth`
- `risk:review-rework`

## Level Tags

Use only these values:

- `volatility:low`
- `volatility:medium`
- `volatility:high`
- `friction:low`
- `friction:medium`
- `friction:high`
- `rework:low`
- `rework:medium`
- `rework:high`
- `confidence:low`
- `confidence:medium`
- `confidence:high`

When confidence is conditional, keep the tag coarse and explain the condition in notes.

## Legacy Alias Notes

When reading older `size.md` ledgers, interpret legacy compound tags as aliases. Do not copy them into new or touched ledgers.

- `validation:mixed` -> split into the applicable `validation:*` and `host:*` tags.
- `validation:regression-heavy` -> usually `validation:regression`, plus `validation:contract` or `host:*` when applicable.
- `validation:mixed-performance-manual` -> `validation:performance`, `validation:hosted-matrix`, and the applicable `host:*` tag.
- `host:sketchup-live-validation` -> `host:routine-smoke`, `host:routine-matrix`, `host:single-fix-loop`, or `host:repeated-fix-loop` depending on observed closeout.
- `confidence:high-pending-live` -> keep `confidence:medium` before live verification or `confidence:high` after clean live verification; explain the condition in notes.
- Long `systems:*` compounds -> split into the closest canonical `systems:*` tags.
