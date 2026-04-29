# Size: PLAT-18 Implement Initial MCP Prompts Guidance Surface

**Task ID**: `PLAT-18`  
**Title**: Implement Initial MCP Prompts Guidance Surface  
**Status**: calibrated
**Created**: 2026-04-28  
**Last Updated**: 2026-04-29  

**Related Task**: [task.md](./task.md)  
**Related Plan**: [plan.md](./plan.md)
**Related Summary**: [summary.md](./summary.md)

---

<!-- SIZE:IDENTITY:START -->
## Identity

- **Task Archetype**: archetype:platform
- **Primary Scope Area**: scope:platform
- **Likely Systems Touched**:
  - systems:runtime-dispatch
  - systems:public-contract
  - systems:docs
  - systems:test-support
- **Validation Modes**: validation:contract, validation:docs-check, validation:public-client-smoke
- **Likely Analog Class**: native-mcp-public-guidance-surface-implementation

### Identity Notes
- This is a platform implementation task for an initial MCP prompts surface. It must preserve `tools/list` baseline safety semantics and avoid moving core tool rules into prompts.
<!-- SIZE:IDENTITY:END -->

---

<!-- SIZE:INITIAL-SHAPE:START -->
## Initial Shape Seed

> Filled early. Use suspicion-level judgment only. Do not overstate confidence.

| Dimension | Seed (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds a complementary prompt catalog surface without changing modeling tool behavior. |
| Technical Change Surface | 2 | Likely touches native runtime prompt registration, protocol tests, docs, and package/client smoke; tool schemas should remain stable. |
| Hidden Complexity Suspicion | 1 | Staged MCP SDK support for prompts/list and prompts/get was confirmed; remaining complexity is catalog wiring and prompt content control. |
| Validation Burden Suspicion | 2 | Requires contract/docs proof and likely a client smoke; no SketchUp geometry proof expected. |
| Dependency / Coordination Suspicion | 2 | Depends on prior platform contract hardening and MTA-15 guidance needs. |
| Scope Volatility Suspicion | 1 | Initial catalog is fixed to two static no-argument prompts; resources and third prompts are deferred. |
| Confidence | 3 | SDK/runtime prompt support was confirmed in the staged package; implementation should remain small if scope stays fixed. |

### Early Signals
- User feedback and staged SDK inspection suggest prompts are likely small; the initial catalog is fixed to managed_terrain_edit_workflow and terrain_profile_qa_workflow.
- The task explicitly preserves tool descriptions/schema as the baseline-safe surface.
- Analog PLAT-14/16/17 shows public MCP contract work must keep runtime, docs, and tests aligned.
- Current runtime has tool descriptions and schemas but no project-owned prompt catalog yet; the staged MCP SDK already supports prompt methods.

### Early Estimate Notes
- Seed was refreshed during planning after PLAT-18 changed from evaluation to initial prompt-surface implementation.
<!-- SIZE:INITIAL-SHAPE:END -->

---

<!-- SIZE:PREDICTED:START -->
## Predicted Profile

> Filled during task planning. This is the main pre-implementation estimate.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Adds a new discoverable MCP prompt surface with two workflow prompts, but does not change modeling behavior, tool calls, request shapes, or response shapes. |
| Technical Change Surface | 2 | Expected changes are concentrated in native prompt catalog support, `McpRuntimeLoader` server assembly, runtime tests, docs, and package/runtime validation. Dispatcher, commands, SketchUp adapters, and terrain behavior stay unchanged. |
| Implementation Friction Risk | 2 | The implementation should be small, but friction can come from mapping the local catalog seam to the packaged Ruby SDK prompt APIs and keeping prompt content out of loader/docs duplication. |
| Validation Burden Risk | 2 | Needs catalog tests, SDK-backed `prompts/list`/`prompts/get` proof before full completion can be claimed, unchanged `tools/list` checks, docs review, lint, tests, and package verification. No SketchUp geometry matrix is expected. |
| Dependency / Coordination Risk | 2 | Prompt body implementation depends on finalized `MTA-15` wording, and full protocol proof depends on the packaged SDK/runtime path that is absent in this checkout. |
| Discovery / Ambiguity Risk | 2 | The prompt count and boundaries are fixed, but exact prompt body wording, staged SDK API behavior, and test fixture placement still need implementation-time confirmation. |
| Scope Volatility Risk | 1 | Scope is intentionally fixed to two static no-argument prompts; resources, prompt arguments, completions, embedded content, and dynamic scene-state prompts are explicitly excluded. |
| Rework Risk | 2 | Review may require prompt wording revisions or SDK integration adjustments, especially if prompt text duplicates docs or implies unsupported terrain behavior. |
| Confidence | 2 | Planning is concrete and external SDK evidence supports the path, but confidence remains medium because `MTA-15` wording is not completed and the local vendored runtime is unavailable for immediate transport proof. |

### Top Assumptions

- `MTA-15` will provide stable enough safe-terrain-edit and profile-QA wording before PLAT-18 prompt bodies are implemented.
- The packaged Ruby MCP SDK path supports registering prompts through the documented `MCP::Prompt` / `MCP::Server` APIs.
- Prompt bodies remain static, no-argument, text-only guidance and do not need scene access, resources, images, or argument completion.
- Existing `tools/list`, tool schemas, dispatcher routing, and command behavior stay unchanged.
- `RuntimePackageStageBuilder` continues copying the full support tree, so a new runtime-native prompt catalog file stages without package-task changes.

### Estimate Breakers

- The staged MCP SDK version in the packaged runtime lacks, changes, or misbehaves around prompt registration, forcing custom protocol handling or an SDK/package update.
- `MTA-15` wording remains unsettled or expands into richer examples that make prompt content ownership and duplication contentious.
- Review decides prompt bodies must include dynamic arguments, resources, examples with generated scene state, or client-specific orchestration guidance.
- SDK-backed tests cannot be run in any practical environment before closeout, leaving only mocked catalog proof for a new public MCP surface.
- Adding prompts unexpectedly changes advertised capabilities or `tools/list` behavior, requiring broader compatibility work.

### Predicted Signals

- The draft plan limits implementation to a small prompt catalog seam and SDK registration through `McpRuntimeLoader`.
- External research confirms `prompts/list` and `prompts/get` are official MCP methods and supported by the official Ruby SDK.
- The local checkout lacks `vendor/ruby`, matching prior native-runtime validation gaps where transport tests skip until a staged runtime is available.
- `PLAT-17` actuals warn that public MCP surfaces need runtime/docs/test parity and representative client smoke to avoid drift.
- `MTA-15` is intentionally the content source for the terrain guidance, so PLAT-18 should not invent prompt wording independently.

### Predicted Estimate Notes

- The predicted shape is moderate despite the small code footprint because this is an additive public MCP surface, not just internal refactoring.
- Validation burden stays at `2`, not `3`, because prompts are static and do not require SketchUp-hosted geometry, persistence, undo, or performance proof unless SDK integration exposes a runtime blocker.
- Confidence is held at `2` until both finalized `MTA-15` wording and staged SDK-backed prompt protocol proof are available.
<!-- SIZE:PREDICTED:END -->

---

<!-- SIZE:CHALLENGE:START -->
## Challenge Review

> Filled when the estimate is pressure-tested through external review, premortem, or controlled consensus.

### Agreed Drivers

- Functional scope remains moderate: this is a new MCP prompt surface, but it is limited to two static no-argument prompts and does not change modeling behavior or existing tool contracts.
- Technical change surface remains moderate-low: implementation is concentrated in prompt catalog support, `McpRuntimeLoader` server assembly, tests, docs, and package/runtime proof.
- Dependency risk remains moderate because prompt body content is intentionally gated on finalized `MTA-15` wording.
- Validation burden remains moderate because at least one real SDK-backed `prompts/list` and `prompts/get` proof is now a completion gate, but no SketchUp geometry, persistence, undo, migration, or performance validation is expected.
- Scope volatility remains low because resources, prompt arguments, completions, embedded content, dynamic prompt generation, and client-specific wrappers are explicitly excluded.

### Contested Drivers

- Whether SDK-backed prompt proof should raise validation burden above `2`. The premortem tightened the gate, but this is still a routine protocol smoke unless SDK integration fails or requires package/runtime changes.
- Whether waiting for `MTA-15` wording should raise dependency risk above `2`. It can delay implementation, but it is a known sequencing dependency with a clear mitigation rather than cross-team integration churn.
- Whether prompt wording review creates higher rework. The plan reduces this by making prompt bodies depend on finalized `MTA-15` and by avoiding duplicated full prompt text in docs.

### Missing Evidence

- Finalized `MTA-15` wording that prompt bodies will cite.
- Actual staged Ruby MCP SDK behavior for `MCP::Prompt` registration in this package path.
- SDK-backed `prompts/list` and `prompts/get` runtime or package-smoke output.
- Final docs diff proving prompt availability is documented without duplicating prompt bodies.

### Recommendation

- Confirm the predicted profile.
- Do not resize or split before implementation.
- Treat SDK-backed prompt protocol proof and finalized `MTA-15` wording as implementation gates, not optional polish.

### Challenge Notes

- Premortem converted the main validation weakness into a carried gate: catalog-only tests are insufficient for claiming a public prompt surface is complete.
- No predicted scores changed. The validation gate became stricter, but the expected implementation and validation shape still fits `2` unless SDK integration fails.
- If SDK-backed prompt support is unavailable in the packaged runtime, that is an estimate breaker and should trigger split, SDK/package investigation, or task status caveat rather than custom JSON-RPC handling.
<!-- SIZE:CHALLENGE:END -->

---

<!-- SIZE:DRIFT:START -->
## Drift Log

> Append only. Log only material changes that affect estimate shape, risk, confidence, or validation burden.

| Date | Phase / Checkpoint | Event Type | Severity (1-3) | Dimension Affected | Predictable Earlier? | Notes |
|---|---|---|---:|---|---|---|

### Drift Notes
- No material drift recorded yet.
<!-- SIZE:DRIFT:END -->

---

<!-- SIZE:ACTUAL:START -->
## Actual Profile

> Filled at the end of implementation. Do not overwrite predicted values.

| Dimension | Score (0-4) | Notes |
|---|---:|---|
| Functional Scope | 2 | Shipped a new public MCP prompt surface with two discoverable workflow prompts. No modeling behavior, tool calls, terrain solvers, or existing tool contracts changed. |
| Technical Change Surface | 2 | Touched the native prompt catalog seam, `McpRuntimeLoader` server assembly, runtime tests, docs posture tests, and MCP reference docs. Dispatcher, runtime command factory, commands, adapters, and packaging code remained unchanged. |
| Actual Implementation Friction | 1 | Core implementation followed the planned SDK-backed path. The only local surprise was that prompt template blocks execute in SDK prompt class context, requiring message objects to be built before the block captures them. |
| Actual Validation Burden | 3 | Routine catalog, loader, docs, full test, lint, package, and diff checks passed, but real SDK-backed `prompts/get` smoke exposed one integration bug and required a small fix/rerun loop. No hosted SketchUp matrix was required. |
| Actual Dependency Drag | 1 | `MTA-15` was already completed and supplied stable terrain guidance. The top-level `vendor/ruby` path was absent, but the staged package vendor runtime under `tmp/package/ruby_native/vendor/ruby` was available for protocol proof. |
| Actual Discovery Encountered | 1 | SDK API shape was confirmed from the staged package, and one execution-context detail was discovered during real transport validation. Prompt count, ownership boundary, and docs strategy stayed clear. |
| Actual Scope Volatility | 0 | Scope stayed fixed to two static no-argument text prompts. No resources, prompt arguments, completions, dynamic scene-state prompts, or client wrappers were added. |
| Actual Rework | 1 | Rework was limited to adjusting prompt message construction after `prompts/get` failed in the SDK smoke. No code review follow-up or architectural rewrite was needed. |
| Final Confidence in Completeness | 4 | Completion is strongly supported by focused tests, real SDK-backed prompt discovery/retrieval smoke, full Ruby tests, lint, package verification, clean diff check, docs coverage, and external codereview with no findings. |

### Actual Notes

- The dominant actual failure mode was SDK template execution-context mismatch, caught only by real `prompts/get` proof.
- A later MTA-16-aware wording consensus caused a small prompt-text revisit, but it stayed within the existing low rework score and did not change implementation shape.
- No material implementation drift was recorded because the fix stayed inside the predicted SDK-integration risk envelope.
- Live SketchUp validation was not needed because the task changed static prompt protocol behavior only.
<!-- SIZE:ACTUAL:END -->

---

<!-- SIZE:VALIDATION-EVIDENCE:START -->
## Validation Evidence Summary

> Fill only the sections that are relevant. Say `not applicable` where needed.

### Automated Validation
- `bundle exec ruby -Itest test/runtime/native/prompt_catalog_test.rb`
  - 4 runs, 39 assertions, 0 failures, 0 errors, 0 skips.
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
  - 50 runs, 400 assertions, 0 failures, 0 errors, 8 skips.
- `bundle exec ruby -Itest test/runtime/public_mcp_contract_posture_test.rb`
  - 6 runs, 48 assertions, 0 failures, 0 errors, 0 skips.
- SDK-backed staged-runtime smoke using `tmp/package/ruby_native/vendor/ruby`
  - verified `prompts/list` returned both prompt names
  - verified `prompts/get` returned a text-only `user` message
- `bundle exec rake ruby:test`
  - 800 runs, 4055 assertions, 0 failures, 0 errors, 37 skips.
- `bundle exec rake ruby:lint`
  - 204 files inspected, no offenses detected.
- `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.0.0.rbz`.
- `git diff --check`
  - clean.
- Post-closeout MTA-16-aware prompt wording refresh:
  - `bundle exec ruby -Itest test/runtime/native/prompt_catalog_test.rb`
    - 4 runs, 39 assertions, 0 failures, 0 errors, 0 skips.
  - `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
    - 50 runs, 400 assertions, 0 failures, 0 errors, 8 skips.
  - `bundle exec rubocop --cache false src/su_mcp/runtime/native/prompt_catalog.rb test/runtime/native/prompt_catalog_test.rb`
    - 2 files inspected, no offenses detected.
  - `git diff --check`
    - clean.

### Hosted / Manual Validation
- Not applicable. No SketchUp-hosted scene behavior, geometry mutation, persistence, undo behavior, or runtime menu/server lifecycle behavior changed.

### Performance Validation
- Not applicable. Prompts are static text and are constructed during server assembly.

### Migration / Compatibility Validation
- Existing `tools/list` inventory and tool schemas remained covered by loader tests.
- Prompt protocol compatibility was proven against the staged Ruby MCP SDK runtime.

### Operational / Rollout Validation
- Package verification passed and staged the runtime support tree with the new prompt catalog file.
 
### Validation Notes
- Normal test runs still skip SDK-backed transport tests when `test/runtime/vendor/ruby` is absent; the required protocol proof was run against the available staged package vendor runtime.
- PAL codereview with `model: "grok-4.20"` reported no critical, high, medium, or low findings.
- A later wording consensus with `gpt-5.4`, `grok-4.20`, and `grok-4` recommended adding concise MTA-16-aware `planar_region_fit` guidance and softening evidence/acceptance wording. This was a wording-only follow-up and did not change scores.
<!-- SIZE:VALIDATION-EVIDENCE:END -->

---

<!-- SIZE:DELTA:START -->
## Estimation Delta Review

> Filled during final calibration. Compare prediction to actual behavior.

### What The Estimate Got Right

- The functional and technical scope matched prediction: a new additive prompt surface with two static no-argument prompts, native runtime registration, tests, docs, and no command or SketchUp adapter changes.
- The prompt body and docs boundary stayed stable: prompts provide reusable workflow guidance without becoming hidden required context for ordinary tool calls.
- The SDK-backed proof requirement was correctly identified as the main completion gate.

### What Was Underestimated

- Validation burden was slightly underestimated. The real `prompts/get` smoke found a prompt-template execution-context bug after catalog and stubbed loader tests were green.
- Future estimates for SDK-backed public protocol surfaces should assume at least one real transport retrieval path can catch issues that stubs miss.

### What Was Overestimated

- Dependency drag was overestimated. `MTA-15` was complete by implementation time, and the staged package vendor runtime was available for protocol proof even though top-level `vendor/ruby` remained absent.
- Prompt wording rework was overestimated; codereview accepted the guidance boundary without follow-up changes.
- A later MTA-16-aware wording review did create a small text-only follow-up, but it remained within the predicted rework envelope and did not require score changes.

### Early-Visible Signals

- The plan already identified SDK prompt API behavior and staged runtime proof as possible friction points.
- The local checkout's absent top-level `vendor/ruby` correctly predicted skipped default SDK tests, but package staging still supplied a usable proof path.

### Genuinely Unknowable Details

- The SDK prompt template execution context was not obvious until `prompts/get` ran through the real SDK.

### Future Analog Guidance

- Retrieve this task for additive native MCP guidance surfaces that add protocol methods without changing tool schemas or scene behavior.
- Treat real SDK-backed `list` plus `get` proof as mandatory for future prompt/resource surfaces; catalog-only and stubbed server tests are insufficient.
- Dominant actual failure mode: SDK integration mismatch at retrieval time despite static catalog tests passing.
- Useful facets: `archetype:platform`, `scope:runtime-transport`, `systems:public-contract`, `systems:test-support`, `validation:contract`, `validation:public-client-smoke`, `host:not-needed`, `contract:no-public-shape-change`, `friction:low`, `rework:low`, `confidence:high`.
<!-- SIZE:DELTA:END -->

---

<!-- SIZE:TAGS:START -->
## Retrieval Tags

- `archetype:platform`
- `scope:platform`
- `scope:runtime-transport`
- `systems:runtime-dispatch`
- `systems:public-contract`
- `systems:docs`
- `systems:test-support`
- `validation:contract`
- `validation:docs-check`
- `validation:public-client-smoke`
- `host:not-needed`
- `contract:runtime-dispatch`
- `contract:docs-examples`
- `contract:no-public-shape-change`
- `risk:contract-drift`
- `volatility:medium`
- `friction:medium`
- `rework:medium`
- `confidence:medium`
<!-- SIZE:TAGS:END -->
