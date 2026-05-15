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
  clear_existing: true
)
```

`clear_existing: true` removes only managed terrain owners whose `sourceElementId`
belongs to this replay corpus before recapture. This makes repeated runs idempotent
in the same SketchUp scene.

The result JSON records the fixture SHA, environment, terrain specs, face/vertex
counts, dirty-window and patch-scope evidence, simplification tolerance, max
simplification error, and timing buckets:

`commandOutputPlanning`, `featureSelectionDiagnostics`, `dirtyWindowMapping`,
`adaptivePlanning`, `mutation`, `total`.
