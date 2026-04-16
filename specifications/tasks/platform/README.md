# Platform Tasks

## Source HLD

These tasks are derived from:

- [Platform Architecture and Repo Structure](../../hlds/hld-platform-architecture-and-repo-structure.md)

## Task Set Intent

This task set covers the product-agnostic platform work required to implement the platform HLD.

It does not cover the product-capability implementation tasks from the semantic scene modeling, Asset Exemplar reuse, or validation/review HLDs.

The authoritative task set is the folder-based set below.

The current post-seeding breakdown is intentionally smaller than the recovered 10-task set. It reflects the revised platform HLD, the current repository baseline, and a refinement pass against hidden task coupling:

- 3 core delivery tasks
- 2 follow-on preparation tasks for the replacement tool rollout
- 1 deferred low-priority task for SketchUp-hosted verification
- 1 architecture spike task for validating Ruby-native MCP directly inside SketchUp

## Task Order

### Core Delivery Path

1. [PLAT-01 Decompose Ruby Runtime Boundaries](PLAT-01-decompose-ruby-runtime-boundaries/task.md)
2. [PLAT-02 Extract Ruby SketchUp Adapters and Serializers](PLAT-02-extract-ruby-sketchup-adapters-and-serializers/task.md)
3. [PLAT-03 Decompose Python MCP Adapter](PLAT-03-decompose-python-mcp-adapter/task.md)

### Follow-On Preparation

4. [PLAT-04 Define MCP Tool Decoration and Phase-Specific Metadata](PLAT-04-define-mcp-tool-decoration-and-phase-specific-metadata/task.md)
5. [PLAT-05 Prepare Python/Ruby Contract Coverage Foundations](PLAT-05-add-python-ruby-contract-coverage/task.md)

### Deferred Low-Priority Tasks

6. [PLAT-06 Add SketchUp-Hosted Smoke and Fixture Coverage](PLAT-06-add-sketchup-hosted-smoke-and-fixture-coverage/task.md)

### Architecture Spikes

7. [PLAT-07 Spike Ruby-Native MCP Runtime In SketchUp](PLAT-07-spike-ruby-native-mcp-runtime-in-sketchup/task.md)

## Dependency Summary

| Task | Depends On | Unblocks |
| --- | --- | --- |
| `PLAT-01` | revised platform HLD | `PLAT-02`, `PLAT-03`, `PLAT-04`, `PLAT-05`, `PLAT-06` |
| `PLAT-02` | `PLAT-01` | capability work, `PLAT-06` |
| `PLAT-03` | `PLAT-01` | `PLAT-04`, `PLAT-05` |
| `PLAT-04` | `PLAT-03` | phased MCP tool-metadata rollout for capability tasks |
| `PLAT-05` | `PLAT-01`, `PLAT-03` | replacement-rollout contract preparation and wave-owned boundary checks |
| `PLAT-06` | `PLAT-01`, `PLAT-02` | deferred runtime-hosted confidence work |
| `PLAT-07` | `PLAT-01`, `PLAT-02`, `PLAT-03`, ADR 2026-04-16 | future packaging decision and any decision to demote Python from the canonical MCP runtime |

## Notes

- This rewritten set is current-state-aware. It assumes the repo already has a working dual-runtime baseline, packaging, semantic release, and basic CI.
- The main delivery path is decomposition with unit-test expansion embedded in each delivery task, not “invent the platform from scratch.”
- `PLAT-01` and `PLAT-02` remain separate on purpose after refinement; the Ruby hotspot is shared, but boundary decomposition and SketchUp adapter extraction are still distinct deliverable slices.
- Unit-test coverage belongs to the task that extracts or reorganizes the relevant boundary. It is not carried as a separate cleanup task.
- There is no standalone CI-tightening task because the current CI already covers Ruby and Python linting, tests, package verification, and release automation reasonably well.
- Packaging and version preservation are folded into the Ruby and Python decomposition tasks rather than carried as a separate slice.
- `PLAT-04` makes MCP client-facing tool metadata a platform-owned concern so phased capability rollouts do not each invent their own decoration posture.
- `PLAT-05` is no longer framed as broad coverage for the current tool catalog. It prepares durable contract-test foundations for the staged replacement tool surface and is meant to be extended by capability-wave work.
- SketchUp-hosted smoke coverage remains defined, but intentionally deferred and low priority.
- `PLAT-07` is intentionally a spike, not a migration commitment. It is meant to produce host-runtime evidence quickly under local developer conditions, including validation of the correct client-to-SketchUp access path for the active environment.
- Tasks remain requirements-focused. They define what must be true when the task is complete, not how the implementation must be coded.
