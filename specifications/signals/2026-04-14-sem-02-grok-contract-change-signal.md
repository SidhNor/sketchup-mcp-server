# Signal: Grok Proposal To Revisit The SEM-02 Request Contract

**Date**: `2026-04-14`
**Source**: External planning review via `grok-4.20`
**Related Task**: [SEM-02 Complete First-Wave Semantic Creation Vocabulary](../tasks/semantic-scene-modeling/SEM-02-complete-first-wave-semantic-creation-vocabulary/task.md)
**Related Baseline**: [SEM-01 Technical Plan](../tasks/semantic-scene-modeling/SEM-01-establish-semantic-core-and-first-vertical-slice/plan.md)
**Status**: `captured`
**Disposition**: `deferred - not adopted into SEM-02 baseline`

## Summary

During Step 5 refinement for `SEM-02`, an external Grok review challenged the current conservative planning baseline and proposed that the task might be a better moment to improve the public `create_site_element` request contract rather than only extending the existing `SEM-01` request shape.

The most substantive proposal was to replace the current compact outer request shape with a guide-style nested contract built around `geometry` and `metadata`.

This signal is preserved because the proposal was not random pushback. It was motivated by real concerns about public contract clarity, future migration cost, and how comfortably the remaining first-wave semantic types fit into the current shape.

## Proposed Change

Replace the current `SEM-01`-style request-shape extension strategy with a richer public payload for semantic creation, for example:

```json
{
  "elementType": "path",
  "geometry": {
    "centerline": [[16.6, 19.8], [15.1, 22.9]],
    "width": 1.6,
    "thickness": 0.1
  },
  "metadata": {
    "sourceElementId": "main-walk",
    "status": "proposed",
    "semanticRole": "circulation"
  },
  "material": "gravel_light"
}
```

Under the proposal, Ruby would normalize the richer public payload into the internal semantic execution path, while Python would expose the nested contract through typed boundary models.

## Grok's Motivation

Grok's reasoning was that the current `SEM-01` request shape may be a good vertical-slice baseline but not the best long-term public API for the broader first-wave vocabulary.

The main motivations were:

- `path`, `retaining_edge`, `planting_mass`, and `tree_proxy` are more naturally expressed as geometry-specific payloads than as repeated top-level semantic fields with ad hoc type-specific additions.
- a `geometry` / `metadata` split could make the public contract easier to read, document, and extend as the semantic surface grows
- changing the request contract earlier could avoid entrenching an MVP payload that would later require a migration after more semantic types and mutation flows depend on it
- the guide already presents a richer nested semantic contract, so aligning the public tool earlier could reduce guide-versus-implementation drift
- the Ruby/Python architecture could still be preserved if Ruby remained the owner of normalization and semantic interpretation

## Why The Proposal Was Considered Meaningful

This was not just a style preference.

The proposal was worth capturing because it identified a real product and architecture question:

- should `SEM-02` only finish first-wave vocabulary breadth
- or should it also improve the public semantic contract before more types are added

Grok also suggested two additional alternatives:

- a more aggressive simplification path using one registry-configured generic site-feature builder for the four new types
- a mixed-wrapper approach where some semantic types could move to `ComponentInstance` wrappers earlier instead of keeping everything on `Group`

Those alternatives were not preferred, but they reinforced the broader signal that `SEM-02` could be seen as a contract-shaping point rather than only a builder-expansion point.

## Why It Was Not Adopted For SEM-02

After review and an additional challenge using `gpt-5.4`, the team direction remained to preserve the `SEM-01` public request baseline for `SEM-02`.

The key reasons were:

- `SEM-02` explicitly says it extends `create_site_element` while preserving one stable command surface, one managed-object contract, and one shared result shape
- `SEM-02` explicitly lists redefining the semantic metadata model or command surface introduced by `SEM-01` as a non-goal without a separate contract decision
- the HLD supports strict per-type sub-schemas behind one public tool, but it does not require a public request-contract redesign in this task
- combining vocabulary expansion with contract redesign would make `SEM-02` a different task than the one currently defined
- the immediate risks of contract churn in tests, docs, and adapter behavior are concrete, while the benefits of changing now are still speculative

## Planning Outcome

The retained planning baseline for `SEM-02` is:

- preserve the `SEM-01` public semantic envelope
- extend it with explicit per-type payload sections for `path`, `retaining_edge`, `planting_mass`, and `tree_proxy`
- keep Ruby as the owner of semantic normalization, validation, builders, metadata, and serialization
- defer any public contract redesign to a separate contract decision if the current shape later proves materially limiting

## Follow-On Question Preserved By This Signal

If the semantic surface continues to expand after `SEM-02`, a later contract review may need to answer:

`Should create_site_element migrate from the SEM-01 compact outer request shape to a guide-style geometry/metadata public contract, and if so, what compatibility or migration path is acceptable?`

