# MTA-24 Live H2H Decision Probes - 2026-05-07

Source: SketchUp live SU_MCP_MTA24 group attributes plus live line/boundary height sampling.

Purpose: Corrected decision probes after fixing MTA-23 adaptive subdivision early-stop on unsplittable off-grid hard-anchor cells.

Invalidated prior MTA-23 rows removed from scene: `MTA24-H2H-COMPLEX-FLATTENED-BOUNDS-49-MTA23-20260507-221305`, `MTA24-H2H-CROSSFALL-PRESERVE-TANGENT-49-MTA23-20260507-221359`, `MTA24-H2H-HIGH-RELIEF-CROSSING-CONTROLS-49-MTA23-20260507-221603`.

| Case | Backend | Group | Faces | Vertices | Dense Ratio | Max Height Error | Stop/Status | Protected Crossings | Timing s | Sample Avg Abs Diff vs Current | Sample Max Abs Diff vs Current |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: |
| COMPLEX-FLATTENED-BOUNDS-MTA23FIX-49 | current | `MTA24-H2H-COMPLEX-FLATTENED-BOUNDS-MTA23FIX-49-CURRENT-20260507-222119` | 4500 | 2346 | 0.9766 | 0.0099 |  |  |  |  |  |
| COMPLEX-FLATTENED-BOUNDS-MTA23FIX-49 | mta23 | `MTA24-H2H-COMPLEX-FLATTENED-BOUNDS-MTA23FIX-49-MTA23-20260507-222120` | 4273 | 2212 | 0.9273 | 0.0497 | ok | 248 | 17.4456 | 0.0002 | 0.0056 |
| COMPLEX-FLATTENED-BOUNDS-MTA23FIX-49 | cdt | `MTA24-H2H-COMPLEX-FLATTENED-BOUNDS-MTA23FIX-49-CDT-20260507-222121` | 3173 | 1659 | 0.6886 | 0.0493 | residual_satisfied | 1 | 77.4726 | 0.0082 | 0.2859 |
| CROSSFALL-PRESERVE-TANGENT-MTA23FIX-49 | current | `MTA24-H2H-CROSSFALL-PRESERVE-TANGENT-MTA23FIX-49-CURRENT-20260507-222246` | 3968 | 2057 | 0.8611 | 0.0100 |  |  |  |  |  |
| CROSSFALL-PRESERVE-TANGENT-MTA23FIX-49 | mta23 | `MTA24-H2H-CROSSFALL-PRESERVE-TANGENT-MTA23FIX-49-MTA23-20260507-222247` | 3271 | 1679 | 0.7099 | 0.0493 | ok | 286 | 11.8447 | 0.0005 | 0.0054 |
| CROSSFALL-PRESERVE-TANGENT-MTA23FIX-49 | cdt | `MTA24-H2H-CROSSFALL-PRESERVE-TANGENT-MTA23FIX-49-CDT-20260507-222247` | 2344 | 1239 | 0.5087 | 0.0457 | residual_satisfied | 1 | 49.7467 | 0.0059 | 0.2461 |
| HIGH-RELIEF-CROSSING-CONTROLS-MTA23FIX-49 | current | `MTA24-H2H-HIGH-RELIEF-CROSSING-CONTROLS-MTA23FIX-49-CURRENT-20260507-222543` | 4675 | 2432 | 1.0145 | 0.0098 |  |  |  |  |  |
| HIGH-RELIEF-CROSSING-CONTROLS-MTA23FIX-49 | mta23 | `MTA24-H2H-HIGH-RELIEF-CROSSING-CONTROLS-MTA23FIX-49-MTA23-20260507-222544` | 4560 | 2363 | 0.9896 | 0.0497 | ok | 342 | 23.2018 | 0 | 0 |
| HIGH-RELIEF-CROSSING-CONTROLS-MTA23FIX-49 | cdt | `MTA24-H2H-HIGH-RELIEF-CROSSING-CONTROLS-MTA23FIX-49-CDT-20260507-222546` | 3796 | 1962 | 0.8238 | 0.0480 | residual_satisfied | 1 | 140.8366 | 0.0053 | 0.0842 |

## Notes

- These rows supersede the earlier decision-probe MTA-23 rows generated before the adaptive subdivision fix.
- The fix prevents unsplittable off-grid hard-anchor cells from stopping further height-error subdivision elsewhere.
- MTA-23 is now a credible but often near-dense baseline on these intersecting bounded edit probes.
- CDT remains substantially sparser than corrected MTA-23 in these probes, with similar max-height-error tolerance, but high-relief CDT exceeded the current Ruby runtime budget.
