# Summary: PLAT-19 Restructure Managed Terrain Support Tree

**Task ID**: `PLAT-19`  
**Title**: `Restructure Managed Terrain Support Tree`  
**Status**: `completed`  
**Completed**: `2026-05-08`

## Shipped Behavior

- Reorganized the managed terrain runtime from a flat `src/su_mcp/terrain/`
  implementation root into explicit ownership folders:
  `commands`, `contracts`, `state`, `storage`, `adoption`, `edits`, `regions`,
  `features`, `output`, `evidence`, `probes`, and existing `ui`.
- Moved source-owned terrain tests into mirrored `test/terrain/` ownership
  folders and placed cross-cutting coverage under explicit `contracts`,
  `integration`, `fixtures`, or `ui` areas.
- Used an implementation-time structural guard to prove the ownership folders,
  empty terrain source root, and empty flat terrain test root during the move;
  removed it before closeout so the exact PLAT-19 taxonomy does not become a
  permanent policy lock.
- Rewrote direct `require_relative` paths in terrain source, terrain tests, test
  support, runtime native catalog, runtime command factory, and UI command
  handoff paths.
- Updated path-only validation command references in the adaptive terrain
  regression fixture metadata.

## Contract And Behavior Disposition

- Public MCP tool names, input schemas, command methods, Ruby constants,
  refusal payloads, and success response shapes were intentionally unchanged.
- `create_terrain_surface` and `edit_terrain_surface` still route through the
  native catalog, dispatcher, command factory, and `SU_MCP::Terrain` command
  target.
- No compatibility root loaders were added because repository consumers were
  updated directly.
- No terrain algorithm, storage, output, evidence, UI behavior, undo behavior,
  or package staging semantics were changed.

## Validation Evidence

- Red baseline before the move:
  - `bundle exec ruby -Itest test/terrain/integration/support_tree_structure_test.rb`
  - Failed as expected because the terrain source root had 51 Ruby files, the
    planned ownership folders were missing, and terrain tests were still flat.
- Temporary structural guard after the move:
  - `bundle exec ruby -Itest test/terrain/integration/support_tree_structure_test.rb`
  - `3 runs, 8 assertions, 0 failures, 0 errors, 0 skips`
- Terrain recursive suite:
  - `bundle exec ruby -Itest -e 'Dir["test/terrain/**/*_test.rb"].sort.each { |path| load path }'`
  - `445 runs, 6271 assertions, 0 failures, 0 errors, 3 skips`
- Focused terrain contract and command tests:
  - `bundle exec ruby -Itest test/terrain/contracts/terrain_contract_stability_test.rb`
  - `9 runs, 857 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/terrain/commands/terrain_surface_commands_test.rb`
  - `28 runs, 169 assertions, 0 failures, 0 errors, 0 skips`
- Runtime integration:
  - `bundle exec ruby -Itest test/runtime/tool_dispatcher_test.rb`
  - `22 runs, 45 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/runtime/runtime_command_factory_test.rb`
  - `5 runs, 6 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec ruby -Itest test/runtime/native/mcp_runtime_loader_test.rb`
  - `50 runs, 404 assertions, 0 failures, 0 errors, 8 skips`
  - `bundle exec ruby -Itest test/runtime/native/mcp_runtime_native_contract_test.rb`
  - `25 runs, 2 assertions, 0 failures, 0 errors, 24 skips`
  - `bundle exec ruby -Itest test/runtime/public_mcp_contract_posture_test.rb`
  - `7 runs, 58 assertions, 0 failures, 0 errors, 0 skips`
- Package and lint:
  - `bundle exec ruby -Itest test/release_support/runtime_package_stage_builder_test.rb`
  - `3 runs, 9 assertions, 0 failures, 0 errors, 0 skips`
  - `bundle exec rake package:verify`
  - Passed and produced `dist/su_mcp-1.4.0.rbz`
  - `bundle exec rubocop --cache false src/su_mcp/terrain src/su_mcp/runtime/native/native_tool_catalog.rb src/su_mcp/runtime/runtime_command_factory.rb test/terrain test/support/adaptive_terrain_regression_fixtures.rb test/support/terrain_survey_correction_evaluation.rb test/runtime/native/mcp_runtime_loader_test.rb test/release_support/runtime_package_stage_builder_test.rb`
  - `121 files inspected, no offenses detected`
- Stale path checks:
  - Old flat `src/su_mcp/terrain/*.rb` and `test/terrain/*_test.rb` references
    were swept and path-only fixture/test references were updated.
  - `find src/su_mcp/terrain -maxdepth 1 -type f -name '*.rb' -print` returned
    no files.
  - `find test/terrain -maxdepth 1 -type f -name '*_test.rb' -print` returned
    no files.
  - The temporary structural guard was removed after these direct checks and the
    recursive terrain suite passed with the final test tree.

## Codereview

- Ran `mcp__pal__codereview` with `model: "grok-4.3"` on the completed change
  set and validation evidence.
- Result: no critical, high, medium, or low findings.
- Follow-up changes required by codereview: none.

## Hosted SketchUp Verification

- Live or hosted SketchUp verification was skipped.
- Rationale: the implemented change is a mechanical file move and
  `require_relative` rewrite with no command behavior, UI behavior, storage,
  output, undo, package layout, or public contract semantics changed. The task
  plan explicitly did not require hosted smoke for this in-scope refactor when
  Ruby/runtime/package validation passed.

## Docs And Metadata

- `task.md` status was updated to `completed`.
- `plan.md` status was updated to `implemented`.
- Platform task index metadata already includes PLAT-19 as the managed terrain
  support-tree cleanup task.
- User-facing MCP docs and README did not require changes because public tool
  names, arguments, setup paths, examples, and response behavior were unchanged.

## Remaining Gaps

- None for the in-scope mechanical restructure.
