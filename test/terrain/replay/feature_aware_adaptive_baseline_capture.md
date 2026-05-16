# Feature-Aware Adaptive Baseline Capture

This replay corpus is intentionally generic and reusable across managed terrain tasks.
It creates live SketchUp terrain geometry through `TerrainSurfaceCommands`; it does not
depend on a saved scene or private backend state.

## Hosted Recapture

After deploying the changed runtime files into the SketchUp plugin and reloading them,
run this from the SketchUp Ruby console or the hosted Ruby bridge:

```ruby
plugin_root = File.expand_path('~/AppData/Roaming/SketchUp/SketchUp 2026/SketchUp/Plugins/su_mcp')
load File.join(plugin_root, 'terrain/probes/feature_aware_adaptive_baseline_capture.rb')

SU_MCP::Terrain::FeatureAwareAdaptiveBaselineCapture.capture_live!(
  replay_path: File.join(plugin_root, 'test/terrain/replay/feature_aware_adaptive_baseline.json'),
  results_path: File.join(plugin_root, 'test/terrain/replay/feature_aware_adaptive_baseline_results.json'),
  include_timing: true,
  include_quality: true,
  clear_existing: true
)
```

`clear_existing: true` removes only managed terrain owners whose `sourceElementId`
belongs to this replay corpus before recapture. This makes repeated runs idempotent
in the same SketchUp scene.

The result JSON records the fixture SHA, environment, terrain specs, face/vertex
counts, dirty-window and patch-scope evidence, simplification tolerance, max
simplification error, optional feature-local quality summary, and timing buckets:

`commandOutputPlanning`, `featureSelectionDiagnostics`, `dirtyWindowMapping`,
`adaptivePlanning`, `mutation`, `total`.

`include_quality: true` enables a harness-only fixed-budget live mesh sampler after
each command row. It records aggregate `featureQualitySummary` and
`harnessQualitySeconds`; command row `seconds` and `timingBuckets.total` remain
command-only wall time.

## Result Pack Comparison

Follow-on tasks can annotate a captured result pack with row verdicts by comparing it
to a previous hosted result pack:

```ruby
require 'json'
require_relative '../../src/su_mcp/terrain/probes/feature_aware_adaptive_baseline_result_classifier'

baseline = JSON.parse(File.read('test/terrain/replay/feature_aware_adaptive_baseline_results.json'))
current = JSON.parse(File.read('test/terrain/replay/feature_aware_adaptive_baseline_results_mta39.json'))
annotated = SU_MCP::Terrain::FeatureAwareAdaptiveBaselineResultClassifier.annotate(
  baseline_document: baseline,
  current_document: current
)
File.write('test/terrain/replay/feature_aware_adaptive_baseline_results_mta39.json', "#{JSON.pretty_generate(annotated)}\n")
```
