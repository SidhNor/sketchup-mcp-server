# HLD Index

## Purpose

This directory contains the high-level design documents for the SketchUp MCP project.

The HLD set is intentionally split into:

- one **platform HLD** for product-agnostic system structure
- multiple **capability HLDs** aligned to individual PRDs

This separation prevents general extension/platform concerns from being mixed with feature-specific implementation design.

## Reading Order

Read the HLDs in this order:

1. [Platform Architecture and Repo Structure](hld-platform-architecture-and-repo-structure.md)
2. [Scene Targeting and Interrogation](hld-scene-targeting-and-interrogation.md)
3. [Semantic Scene Modeling](hld-semantic-scene-modeling.md)
4. [Asset Exemplar Reuse](hld-asset-exemplar-reuse.md)
5. [Scene Validation and Review](hld-scene-validation-and-review.md)

## Document Roles

### [Platform Architecture and Repo Structure](hld-platform-architecture-and-repo-structure.md)

Defines the product-agnostic platform shape:

- runtime boundaries
- runtime responsibilities
- repo structure direction
- packaging
- testing
- shared infrastructure

Use this HLD when the question is:

- how the repo should be organized
- where a new concern belongs
- how packaging, transport, or shared runtime concerns should evolve

### [Scene Targeting and Interrogation](hld-scene-targeting-and-interrogation.md)

Defines the implementation approach for targeting and interrogation workflows:

- workflow-facing entity lookup
- collection discovery
- bounds and placement summaries
- explicit surface sampling
- topology findings

Use this HLD when the question is:

- how existing scene objects should be targeted reliably
- how surfaces should be sampled before placement or reprojection
- how edge networks should be checked before downstream modeling or validation

### [Semantic Scene Modeling](hld-semantic-scene-modeling.md)

Defines the implementation approach for semantic scene creation and lookup:

- Managed Scene Object creation
- semantic builders
- query flows
- metadata assignment
- revision-safe identity

Use this HLD when the question is:

- how `create_site_element` should work
- how semantic objects should be created and queried
- how semantic modeling should replace primitive-first flows

### [Asset Exemplar Reuse](hld-asset-exemplar-reuse.md)

Defines the implementation approach for curated asset reuse:

- Asset Exemplar discovery
- Asset Instance creation
- protection rules
- replacement flows
- lineage

Use this HLD when the question is:

- how the Asset Exemplar library should work
- how proxies are replaced with curated assets
- how asset reuse stays safe and traceable

### [Scene Validation and Review](hld-scene-validation-and-review.md)

Defines the implementation approach for confidence and review workflows:

- measurement
- validation
- structured findings
- snapshots
- post-update review

Use this HLD when the question is:

- how correctness should be checked
- how findings should be structured
- how review artifacts fit into the workflow

## Relationship to Other Specifications

The HLDs should be read alongside:

- [Domain Analysis](../domain-analysis.md)
- [PRD: Scene Targeting and Interrogation](../prds/prd-scene-targeting-and-interrogation.md)
- [PRD: Semantic Scene Modeling](../prds/prd-semantic-scene-modeling.md)
- [PRD: Staged Asset Reuse](../prds/prd-staged-asset-reuse.md)
- [PRD: Scene Validation and Review](../prds/prd-scene-validation-and-review.md)

Recommended spec reading path:

1. Domain analysis
2. Relevant PRD
3. Platform HLD
4. Relevant capability HLD

## Change Guidance

When updating HLDs:

- update the platform HLD for structural or cross-cutting platform decisions
- update a capability HLD for feature-specific design changes
- avoid putting generic repo-structure guidance into capability HLDs
- avoid putting feature-specific flows into the platform HLD

If a new major capability gets its own PRD, it should usually get its own capability HLD as well.
