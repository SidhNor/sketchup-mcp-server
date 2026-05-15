# Summary: MTA-38 Establish Feature-Aware Adaptive Baseline, Policy, And Validation Harness

**Task ID**: `MTA-38`
**Status**: `completed`
**Completed**: `2026-05-16`

## Outcome

MTA-38 established the reusable feature-aware adaptive terrain baseline that later managed terrain
tasks can rerun after implementation changes. The baseline is generic and intentionally not named
after this task in runtime/probe artifacts.

The durable replay source is
`test/terrain/replay/feature_aware_adaptive_baseline.json`. It contains exact public terrain
command payloads, terrain dimensions, spacing, placement, stable source IDs, canonical rows, and
heavy timing terrains. It does not depend on a saved SketchUp scene or private backend state.

The canonical captured result is
`test/terrain/replay/feature_aware_adaptive_baseline_results.json`. Three repeatability captures
are also checked in beside it:

- `feature_aware_adaptive_baseline_results_repeat_1.json`
- `feature_aware_adaptive_baseline_results_repeat_2.json`
- `feature_aware_adaptive_baseline_results_repeat_3.json`

## Delivered Behavior

- Added `FeatureOutputPolicyDiagnostics`, a JSON-safe internal diagnostic object for feature-view
  digest, output policy fingerprint, selected feature counts/kinds/strengths, affected-window
  summary, intersection summary, local tolerance policy, and diagnostic-only marker.
- Added optional diagnostic attachment to `TerrainOutputPlan` while keeping public terrain command
  responses compact and unchanged.
- Extended `TerrainFeaturePlanner` context so output planning can record selected feature views.
- Added internal baseline evidence capture to `TerrainSurfaceCommands` for feature digest, policy
  fingerprint, feature context summary, dirty window, patch scope, rendering summary, simplification
  tolerance, max simplification error, and timing buckets.
- Added generic timing capture for:
  - `commandOutputPlanning`
  - `featureSelectionDiagnostics`
  - `dirtyWindowMapping`
  - `adaptivePlanning`
  - `mutation`
  - `total`
- Added adaptive mesh-generator timing exposure for create and dirty edit paths.
- Added reusable hosted replay/capture infrastructure:
  - `FeatureAwareAdaptiveBaselineReplay`
  - `FeatureAwareAdaptiveBaselineCapture`
  - `FeatureAwareAdaptiveBaselineResultDocument`
- Added documentation for the hosted recapture entrypoint at
  `test/terrain/replay/feature_aware_adaptive_baseline_capture.md`.
- Raised terrain creation ceilings to support the heavy baseline:
  - `MAX_TERRAIN_SAMPLES = 65_536`
  - `MAX_TERRAIN_COLUMNS = 256`
  - `MAX_TERRAIN_ROWS = 256`
- Updated adoption sampler test expectations for the raised ceiling.

## Hosted Capture

The live hosted capture was run through deployed SketchUp plugin files and real
`TerrainSurfaceCommands` geometry creation/editing. Files were copied into the installed SketchUp
plugin, reloaded, and executed through the SketchUp Ruby bridge.

The reusable capture command is:

```ruby
plugin_root = File.expand_path('~/AppData/Roaming/SketchUp/SketchUp 2026/SketchUp/Plugins/su_mcp')
load File.join(plugin_root, 'terrain/probes/feature_aware_adaptive_baseline_capture.rb')

SU_MCP::Terrain::FeatureAwareAdaptiveBaselineCapture.capture_live!(
  replay_path: File.join(plugin_root, 'test/terrain/replay/feature_aware_adaptive_baseline.json'),
  results_path: File.join(plugin_root, 'test/terrain/replay/feature_aware_adaptive_baseline_results.json'),
  include_timing: true,
  clear_existing: true
)
```

`clear_existing: true` removes the canonical terrain and timing terrains by `sourceElementId`
before recapture, making repeated runs independent of existing scene leftovers.

## Repeatability Evidence

Three full live captures were run after fixing the repeatability clear-path bug. Each valid run
produced `18` accepted rows and `0` refusals. Geometry counts were identical across runs.

| Run | Row Sum | Refusals |
|---|---:|---:|
| 1 | `85.1113s` | `0` |
| 2 | `85.2140s` | `0` |
| 3 | `87.3607s` | `0` |

Representative heavy rows:

| Row | Run 1 | Run 2 | Run 3 | Faces |
|---|---:|---:|---:|---:|
| large create | `9.9107s` | `9.5563s` | `10.3971s` | `76200` |
| large local edit | `3.0215s` | `3.0573s` | `3.2766s` | `18878` |
| large corridor | `13.8595s` | `13.6560s` | `14.0200s` | `72240` |
| large planar pad | `12.7412s` | `13.5101s` | `12.8010s` | `67562` |
| large survey control | `13.1386s` | `13.0247s` | `13.6863s` | `67622` |
| large fairing | `13.1293s` | `12.8978s` | `13.6859s` | `53648` |
| wide create | `3.3248s` | `3.3703s` | `3.5352s` | `31734` |
| wide half corridor | `5.7017s` | `5.8316s` | `5.7991s` | `31914` |
| wide fairing | `7.3694s` | `7.3559s` | `7.1229s` | `24326` |

The result rows also record per-phase timing buckets, face/vertex counts, dirty-window summary,
affected patch scope, simplification tolerance, and max simplification error.

## Review Findings

- Grok review after the main implementation found no blocking issues.
- Low findings were addressed:
  - replaced a hosted placement fallback `Struct` with `Geom::Transformation.new(point)`;
  - made timing terrain handling explicit;
  - tightened adaptive-state guards with `payload_kind`.
- `$task-review` deterministic checks found no L1 lint violations, no probe dead code, and no
  security findings.
- Bugbot L2 structural findings were reviewed and treated as non-blocking: they were optional
  internal keywords, test-helper signature churn, expected complexity growth for the harness, or
  pre-existing probe smell posture.
- Fresh RuboCop and full tests passed after the review fixes.

## Validation Evidence

- Focused MTA-38 validation:
  - `bundle exec ruby -Itest -e 'ARGV.each { |path| require File.expand_path(path) }' ...`
  - `176 runs, 8926 assertions, 0 failures, 0 errors, 0 skips`
- Full Ruby tests:
  - `bundle exec rake ruby:test`
  - `1404 runs, 16750 assertions, 0 failures, 0 errors, 40 skips`
- Full Ruby lint:
  - `bundle exec rake ruby:lint`
  - `348 files inspected, no offenses detected`
- Package verification:
  - `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.8.0.rbz`
- Focused hosted/replay/capture RuboCop:
  - no offenses.

## Contract And Docs

- Public MCP terrain tool names, schemas, dispatcher routes, and public response shapes were not
  changed.
- Contract guard tests were expanded to keep diagnostics, timing, patch scope, registry internals,
  and feature-selection diagnostics out of public responses.
- The recapture mechanism is documented in the replay folder so MTA-39 through MTA-44 can rerun it
  without relying on chat history.

## Residual Risk

- The reusable replay harness is intentionally broad and is flagged by `tldr smells` as a probe
  god-class. This is accepted for now because it is a durable test/probe surface, not production
  terrain behavior, and it is covered by schema, replay, capture, and live hosted validation.
- Timing values are wall-clock SketchUp measurements and should be compared as repeated-run bands,
  not exact single-run constants.
