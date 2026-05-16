# Summary: MTA-39 Add Feature-Aware Tolerance And Density Fields

**Task ID**: `MTA-39`
**Status**: `completed`
**Completed**: `2026-05-16`

## Shipped Local Behavior

- Added `FeatureAwareAdaptivePolicy`, a pure Ruby adaptive-output policy for local simplification
  tolerance, target cell-size pressure, deterministic fingerprinting, and compact aggregate
  fallback/coverage summaries.
- Wired production adaptive planning so selected in-memory feature geometry is requested even when
  CDT output is disabled.
- Threaded the feature-aware policy into `TerrainOutputPlan` adaptive subdivision while preserving
  the existing adaptive patch/cell production path, PatchLifecycle ownership, dirty-window
  replacement scope, registry/readback, and no-delete mutation safety.
- Local tolerance now tightens around hard/protected/firm feature pressure, with monotone strictest
  aggregation so soft/fairing pressure cannot weaken stricter policy.
- Density pressure now subdivides bounded rectangle/circle feature windows toward target cell size
  without expanding dirty-window replacement to distant feature regions.
- Extended internal replay evidence and result documents with compact `adaptivePolicySummary`
  fields for tolerance range, density-hit count, hard/protected hit count, and fallback counts.
- Added harness-only feature quality sampling for replay captures. It is opt-in through
  `include_quality: true`, uses a fixed sample budget capped at 256, records
  `featureQualitySummary` and `harnessQualitySeconds`, and does not enter public command wall time.
- Added a reusable probe-side result classifier. After review follow-up it uses `policy_applied`
  only when policy evidence and captured quality evidence are both present; no-quality repeat packs
  remain neutral instead of overclaiming quality improvement.
- Kept public terrain command request and response shapes unchanged; new policy and replay evidence
  remains internal to probes/result packs.

## Validation Evidence

- Focused post-review terrain/probe slice:
  - `45 runs, 1046 assertions, 0 failures, 0 errors, 0 skips`
- Focused review-fix slice:
  - `11 runs, 46 assertions, 0 failures, 0 errors, 0 skips`
- Full Ruby tests after review fixes:
  - `bundle exec rake ruby:test`
  - `1446 runs, 17390 assertions, 0 failures, 0 errors, 41 skips`
- Full Ruby lint after review fixes:
  - `bundle exec rake ruby:lint`
  - `360 files inspected, no offenses detected`
- Package verification:
  - `bundle exec rake package:verify`
  - produced `dist/su_mcp-1.8.0.rbz`
- Scoped diff check for MTA-39 terrain/task paths was clean before the final summary update; no
  whitespace or patch-format issues were present in the scoped implementation paths.

## Code Review

- Deterministic/local review was run through tests, lint, package verification, manual file review,
  and scoped diff checks.
- Earlier review found a real `TerrainOutputPlan.subdivide_cell` complexity increase. Follow-up
  moved split-pressure calculation into `FeatureAwareAdaptivePolicy#split_pressure_for` and
  `TerrainOutputPlan.adaptive_split_probe`, then reran focused tests and lint.
- Final PAL codereview with `model: "gpt-5.4"` completed after the corridor experiment revert.
  It found two medium findings and one low maintainability finding:
  - The quality-sampler test double did not match SketchUp's `model.entities.to_a` contract.
  - The classifier still risked positive-sounding `policy_applied` verdicts without captured
    quality evidence.
  - `FeatureAwareAdaptivePolicy#summary` cumulative counters needed clearer planning-pass intent.
- Follow-up changes addressed all findings:
  - The sampler fake now exposes an entities collection with `to_a`.
  - `policy_applied` now requires `featureQualitySummary.status == "captured"`.
  - The policy summary has an explicit planning-pass counter comment.
- Focused post-review checks and the full Ruby test/lint gates passed after those changes.
- Hosted replay was not rerun after the final PAL fixes because the fixes were limited to
  harness/test/classifier semantics, result-pack annotation, and a policy-summary comment; the
  deployed production SketchUp output path did not change after the prior hosted capture.

## Contract And Docs

- Public MCP terrain tool names, schemas, dispatcher routes, request shapes, and response shapes did
  not change.
- Contract no-leak coverage was expanded for `adaptivePolicySummary`, tolerance/density summaries,
  fallback counts, and target-density vocabulary.
- User-facing setup/tool docs were reviewed by scope and were not updated because no public
  contract changed.
- The reusable hosted capture note was extended with `include_quality: true` and explains that
  `harnessQualitySeconds` is separate from command row timing.

## Hosted Verification Status

- Hosted/live SketchUp verification was run through the reusable MTA-38 replay harness after
  deployment.
- Replay terrain origins were `x=320m`, `x=420m`, and `x=465m`, satisfying the requested
  `x >= 50m` placement constraint.
- Three fresh MTA-39 repeat captures were recorded:
  - `feature_aware_adaptive_baseline_results_mta39_run_1.json`: `18/18` accepted, `0` refusals,
    total row time `81.0398s`.
  - `feature_aware_adaptive_baseline_results_mta39_run_2.json`: `18/18` accepted, `0` refusals,
    total row time `82.8589s`.
  - `feature_aware_adaptive_baseline_results_mta39_run_3.json`: `18/18` accepted, `0` refusals,
    total row time `84.0005s`.
- After the classifier review fix, those no-quality repeat packs annotate as `18 neutral` because
  they prove timing/scope stability but do not contain feature-local quality samples.
- Three-run timing comparison against MTA-38 repeat captures:
  - MTA-38 mean total `85.8953s`.
  - MTA-39 repeat mean total `82.6330s`.
  - Aggregate delta `-3.8%`.
- All repeat rows included `adaptivePolicySummary`; no hosted row changed dirty-window scope or
  patch scope versus the MTA-38 baseline.
- Face-count growth was localized to feature-pressure rows. Largest increases in repeat captures
  were large planar `+2142`, large survey `+3446`, and large fairing `+4240`; create rows stayed
  unchanged.

## Feature Quality Capture

- A harness-only quality capture was run after fixing an owner-local/world-coordinate sampler bug
  found during the first invalid quality run.
- Valid quality result pack:
  - `feature_aware_adaptive_baseline_results_mta39_quality.json`
  - `18/18` accepted, `0` refusals.
  - `15` rows with captured quality, `3` rows `not_applicable`.
  - Command row time `88.354s`.
  - Harness-only quality sampling time `16.888s`, recorded separately from command timing.
  - Annotated verdicts after review fix: `15 policy_applied`, `3 neutral`.
- Target-region rows were 100% within local tolerance in the captured sampler evidence.
- Planar and fairing rows were mostly within local tolerance, but corridor-involved rows exposed a
  local quality gap. The generic sampler is useful for future tasks, but corridor quality needs a
  domain-specific proof that separates flat corridor interiors from falloff/caps/overlaps.

## Reverted Experiments

- A strength-aware fairing-density experiment was tested and reverted. It reduced fairing faces only
  trivially and produced noisy/slower hosted timing.
- A corridor-pressure experiment was tested and reverted. Treating corridor pressure as broad local
  density removed `unsupportedFeatureGeometry` fallbacks but added roughly `+9k` to `+13k` faces on
  large/wide corridor-involved rows while barely improving local quality. Visual/domain inspection
  confirmed that a pure corridor interior should be flat and low-face; detail belongs at falloff,
  caps, and later overlap-aware feature logic.
- The temporary corridor experiment result pack was removed from the closeout artifact surface. The
  shipped policy supports rectangle/circle pressure only and records corridor pressure as an
  unsupported-feature fallback.

## Remaining Gaps

- Corridor-specific adaptive output remains a follow-on task. It should distinguish flat corridor
  interior representation from falloff/cap/overlap detail instead of broad corridor density
  pressure.
- Exact hard/protected topology, forced subdivision masks, diagonal optimization, seam lattice
  changes, sparse detail tiles, and CDT islands remain out of scope for MTA-40 and later tasks.
- The hosted repeat timing delta is evidence, not a hard performance guarantee; the credible claim
  is scope stability plus no observed repeat-run regression in this environment.
