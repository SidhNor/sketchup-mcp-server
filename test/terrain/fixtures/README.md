# Adaptive Terrain Regression Fixtures

This directory contains the MTA-22 adaptive terrain benchmark fixture pack.

The JSON fixture file is recipe-first and result-set aware:

- `cases` records terrain dimensions, spacing, deterministic terrain traits, and ordered edit
  controls.
- `baselineResults` records the compact MTA-21 baseline result row for each case.
- `coverageLimitations` records named terrain or edit-family gaps that are not represented by the
  current baseline pack.

Baseline result rows record compact metrics and probes: face counts or ranges, dense-equivalent
counts, dense ratios, profile checks, topology checks, seam checks, diagnostics, known residuals,
provenance, limitations, and timing summaries when practical. They intentionally do not store raw
SketchUp objects, live entity identifiers, generated geometry, full point clouds, raw triangles, or
adaptive output internals.

Hosted-sensitive facts come from the MTA-21 hosted validation checklist and summary. Cases that
cannot be replayed by the pure Ruby terrain helpers are marked as provenance-only with MTA-21
source references so MTA-23 can consume the same evidence without mistaking it for local proof.

Pure Ruby local replay remains a deterministic support path, not the authoritative MTA-21 baseline
when it diverges from hosted or provenance-backed result rows. MTA-23 should produce candidate
result sets with the same compact row shape and compare those rows against `baselineResults`.
