# MTA-24 Live H2H Intersecting Bounded Edits - 2026-05-07

Source: SketchUp live SU_MCP_MTA24 group attributes.

Scenario: Single bumpy/crossfall terrain with intersecting bounded edit intents: diagonal corridor, bounded planar pad, circular target, fairing envelope, fixed/survey controls, and protected bounds intersecting the corridor.

| Case | Backend | Group | Faces | Vertices | Dense Ratio | Max Height Error | Stop/Status | Protected Crossings | Constraint Coverage | Timing s |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| BUMPY-INTERSECTING-BOUNDED-EDITS-49 | current | `MTA24-H2H-BUMPY-INTERSECTING-BOUNDED-EDITS-49-CURRENT-20260507-220237` | 4730 | 2459 | 1.0265 | 0.0100 |  |  |  |  |
| BUMPY-INTERSECTING-BOUNDED-EDITS-49 | mta23 | `MTA24-H2H-BUMPY-INTERSECTING-BOUNDED-EDITS-49-MTA23-20260507-220238` | 3945 | 2033 | 0.8561 | 0.0499 | ok | 334 |  | 11.9568 |
| BUMPY-INTERSECTING-BOUNDED-EDITS-49 | cdt | `MTA24-H2H-BUMPY-INTERSECTING-BOUNDED-EDITS-49-CDT-20260507-220240` | 2895 | 1512 | 0.6283 | 0.0497 | residual_satisfied | 1 |  | 56.9699 |

## Notes

- This is an addendum to the earlier 16-case live matrix, not a replacement for it.
- The probe intentionally combines intersecting edit intents on one terrain, including a protected bounded region that intersects the corridor.
- CDT satisfied residual error but still reports conservative hard/constraint geometry flags on this scenario.
