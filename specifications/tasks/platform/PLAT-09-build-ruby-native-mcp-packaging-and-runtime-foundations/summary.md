# PLAT-09 Implementation Summary

## What Shipped

- Added a deterministic staged Ruby-native package foundation driven by [config/runtime_package_manifest.json](./../../../config/runtime_package_manifest.json).
- Added shared packaging helpers under [rakelib/release_support/](./../../../rakelib/release_support/) for:
  - runtime manifest loading
  - vendored gem fetch, checksum verification, unpack, and prune
  - staged package assembly
  - staged package verification
- Extended [rakelib/package.rake](./../../../rakelib/package.rake) with explicit transitional package targets:
  - `package:rbz:ruby_native`
  - `package:verify:ruby_native`
  - `package:verify:all`
- Updated [Rakefile](./../../../Rakefile), [.github/workflows/ci.yml](./../../../.github/workflows/ci.yml), and [rakelib/version.rake](./../../../rakelib/version.rake) so normal validation and release preparation exercise both the standard package and the staged Ruby-native package.
- Promoted the in-host runtime seams out of the spike posture:
  - [mcp_runtime_config.rb](./../../../src/su_mcp/mcp_runtime_config.rb)
  - [mcp_runtime_loader.rb](./../../../src/su_mcp/mcp_runtime_loader.rb)
  - [mcp_runtime_http_backend.rb](./../../../src/su_mcp/mcp_runtime_http_backend.rb)
  - [mcp_runtime_server.rb](./../../../src/su_mcp/mcp_runtime_server.rb)
  - [mcp_runtime_facade.rb](./../../../src/su_mcp/mcp_runtime_facade.rb)
- Rewired [main.rb](./../../../src/su_mcp/main.rb) to the promoted runtime foundation and removed the old `mcp_spike_*` runtime files and tests.
- Kept the menu and status wording explicitly transitional as `Experimental MCP Runtime`, leaving public tool-surface migration and final posture cleanup to `PLAT-10`.

## Validation

- Passed focused runtime and package seam tests covering manifest loading, vendored staging, archive-shape verification, staged runtime load verification, and promoted runtime wiring.
- Passed `bundle exec rake package:verify`
- Passed `bundle exec rake package:verify:ruby_native`
- Passed `bundle exec rake package:verify:all`
- Verified the release-prep path now preserves both RBZ artifacts in `dist/` instead of allowing the Ruby-native build to remove the standard package artifact.
- Verified the staged package verifier now executes the manifest-declared isolated staged-runtime load test rather than checking archive shape alone.
- Verified CI and release completion for the staged Ruby-native path, including production and upload of the generated artifact.
- Verified live SketchUp installation and startup of the staged Ruby-native RBZ, with the exposed native tool slice working consistently in-host.

## Docs And Metadata

- Updated [task.md](./task.md) status to `completed`
- Added implementation and validation notes to [task.md](./task.md)
- Added this `summary.md`
- No `README.md` or bridge-contract update was required because the public MCP tool surface and the supported Python/Ruby boundary were unchanged in this task

## Remaining Gaps

- Repo-wide `ruby:test` and `ruby:lint` still see unrelated untracked modeling and joinery files already present in the worktree. Those files were restored after temporary isolation for scoped validation and are not part of the PLAT-09 implementation itself.

## Manual Verification

- Completed in a live SketchUp host:
  - installed the staged Ruby-native RBZ
  - confirmed extension startup and runtime boot
  - confirmed the exposed native tools behaved consistently in host
