# Platform Tasks

## Source HLD

These tasks are derived from:

- [Platform Architecture and Repo Structure](../../hlds/hld-platform-architecture-and-repo-structure.md)

## Task Set Intent

This task set covers the product-agnostic platform work required to implement the platform HLD.

It does not cover the product-capability implementation tasks from the semantic scene modeling, Asset Exemplar reuse, or validation/review HLDs.

The authoritative task set is the folder-based set below.

The current post-seeding breakdown is intentionally smaller than the recovered 10-task set. It reflects the revised platform HLD, the current repository baseline, and a refinement pass against hidden task coupling:

- 4 core delivery tasks
- 2 deferred low-priority tasks for contract coverage and SketchUp-hosted verification

## Task Order

### Core Delivery Path

1. [PLAT-01 Decompose Ruby Runtime Boundaries](PLAT-01-decompose-ruby-runtime-boundaries/task.md)
2. [PLAT-02 Extract Ruby SketchUp Adapters and Serializers](PLAT-02-extract-ruby-sketchup-adapters-and-serializers/task.md)
3. [PLAT-03 Decompose Python MCP Adapter](PLAT-03-decompose-python-mcp-adapter/task.md)
4. [PLAT-04 Expand Platform Unit Test Coverage](PLAT-04-expand-platform-unit-test-coverage/task.md)

### Deferred Low-Priority Tasks

5. [PLAT-05 Add Python/Ruby Contract Coverage](PLAT-05-add-python-ruby-contract-coverage/task.md)
6. [PLAT-06 Add SketchUp-Hosted Smoke and Fixture Coverage](PLAT-06-add-sketchup-hosted-smoke-and-fixture-coverage/task.md)

## Dependency Summary

| Task | Depends On | Unblocks |
| --- | --- | --- |
| `PLAT-01` | revised platform HLD | `PLAT-02`, `PLAT-03`, initial `PLAT-04`, `PLAT-05`, `PLAT-06` |
| `PLAT-02` | `PLAT-01` | capability work, Ruby-side extracted boundaries for `PLAT-04`, `PLAT-06` |
| `PLAT-03` | `PLAT-01` | Python-side extracted boundaries for `PLAT-04`, `PLAT-05` |
| `PLAT-04` | initial extraction work from `PLAT-01`; extracted reviewable boundaries from `PLAT-02` and `PLAT-03` as they become available | main always-on verification path |
| `PLAT-05` | `PLAT-01`, `PLAT-03` | deferred boundary confidence work |
| `PLAT-06` | `PLAT-01`, `PLAT-02` | deferred runtime-hosted confidence work |

## Notes

- This rewritten set is current-state-aware. It assumes the repo already has a working dual-runtime baseline, packaging, semantic release, and basic CI.
- The main delivery path is decomposition plus unit-test expansion, not “invent the platform from scratch.”
- `PLAT-01` and `PLAT-02` remain separate on purpose after refinement; the Ruby hotspot is shared, but boundary decomposition and SketchUp adapter extraction are still distinct deliverable slices.
- `PLAT-04` is a rolling verification track that should expand alongside extracted Ruby and Python boundaries rather than wait as a purely end-loaded cleanup task.
- There is no standalone CI-tightening task because the current CI already covers Ruby and Python linting, tests, package verification, and release automation reasonably well.
- Packaging and version preservation are folded into the Ruby and Python decomposition tasks rather than carried as a separate slice.
- Contract coverage and SketchUp-hosted smoke coverage remain defined, but intentionally deferred and low priority.
- Tasks remain requirements-focused. They define what must be true when the task is complete, not how the implementation must be coded.
