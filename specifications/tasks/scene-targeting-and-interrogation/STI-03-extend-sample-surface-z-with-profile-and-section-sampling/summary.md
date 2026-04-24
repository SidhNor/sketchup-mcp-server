# STI-03 Implementation Summary

**Status**: `completed`
**Completed**: `2026-04-24`

## Delivered

- Replaced the public `sample_surface_z` invocation shape with canonical `target` plus `sampling`.
- Added finite `sampling.type` support for `points` and `profile` without top-level schema unions.
- Added profile path sample generation with `sampleCount` or `intervalMeters`, ordered evidence rows, distance/progress metadata, and a compact summary.
- Kept sampling read-only and evidence-only: no slope verdicts, fairness verdicts, terrain edit suggestions, or validation ownership moved into interrogation.
- Updated internal validation callers to use canonical point sampling instead of legacy `samplePoints`.
- Updated runtime schema, native contract fixtures, dispatcher coverage, HLD/PRD language, README usage guidance, and related task metadata references.

## Validation

- Live SketchUp-hosted matrix completed on `2026-04-24` with temporary fixtures only:
  - flat, sloped, triangulated terrain, profile, component-instance, and explicit ID target sampling passed
  - ordered profile summaries, mixed hit/miss ordering, cap-at-200, and structured refusal cases passed
  - unresolved `ignoreTargets`, nested sourceElementId resolution, and hidden-layer visibility defects were found and fixed in this implementation pass
  - a follow-up hosted matrix found nested target-ignore and hidden-ancestor visibility gaps; both were fixed with ancestry-aware target entries and descendant-aware ignore filtering
  - final focused hosted regression smoke passed for direct nested terrain/occluder targets, combined target ambiguity, ignoring nested occluders by sourceElementId/persistentId/entityId, hidden parent visibleOnly behavior, and hidden occluder visibleOnly behavior
  - overlapping terrain plus overlay returning `ambiguous` is accepted as intended behavior for multiple surviving z-clusters
- `bundle exec ruby -Itest test/scene_query/sample_surface_profile_generator_test.rb`
- `bundle exec ruby -Itest test/scene_query/sample_surface_evidence_test.rb`
- `bundle exec ruby -Itest test/scene_query/sample_surface_z_scene_query_commands_test.rb`
- `bundle exec ruby -Itest test/scene_validation/scene_validation_commands_test.rb`
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
- `bundle exec ruby -Itest test/runtime/tool_dispatcher_test.rb`
- `bundle exec ruby -Itest test/runtime/native/mcp_runtime_native_contract_test.rb`
- `bundle exec rake ruby:test` - 501 runs, 1812 assertions, 0 failures, 0 errors, 27 skips
- `bundle exec rake ruby:lint` - 132 files inspected, no offenses
- `bundle exec rake package:verify` - emitted `dist/su_mcp-0.18.0.rbz`
- `git diff --check`

Grok 4.20 codereview found no critical or high blockers after cleanup. Its contract-coverage and schema-description recommendations were addressed by adding native profile-refusal contract cases and documenting the 200-sample cap/refusal codes in the loader schema description.

## Remaining Manual Verification

- A skipped hosted smoke marker remains in `test/scene_query/sample_surface_profile_hosted_smoke_test.rb` as a reminder to automate or periodically rerun the hosted matrix.
- The live matrix covered realistic temporary terrain fixtures, but no persistent SketchUp-hosted automated fixture exists yet.
- Follow-up hosted coverage should include two instances of the same component definition with different transforms and nested `sourceElementId` targets.
