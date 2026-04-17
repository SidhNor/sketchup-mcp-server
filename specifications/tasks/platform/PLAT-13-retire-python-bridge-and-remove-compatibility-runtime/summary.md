# Summary: PLAT-13 Retire Python Bridge And Remove Compatibility Runtime

## What Shipped

- Removed the repo-owned Python MCP adapter, bridge transport, bridge contract artifact, and all related Python and Ruby bridge tests.
- Recentered runtime and packaging on the MCP server inside SketchUp.
- Simplified packaging to one canonical staged RBZ path exposed through `package:rbz` and `package:verify`.
- Moved release automation to standalone `releaserc.toml` with CI-only installation of `python-semantic-release`.
- Reworked current-facing docs and workspace metadata so they describe the supported runtime rather than the retired bridge posture.
- Replaced bridge-fixture-backed response-shape checks with fixture files under `test/support/`.

## Validation

- Passed `bundle exec rake version:assert`
- Passed `bundle exec rake ruby:lint`
- Passed `bundle exec rake ruby:test`
- Passed `bundle exec rake package:verify`
- Passed `bundle exec rake ci`

## Remaining Manual Verification

- Install the canonical `dist/su_mcp-<version>.rbz` in SketchUp.
- Confirm the MCP server starts correctly from the packaged extension.
- Exercise representative MCP requests against the packaged runtime.
