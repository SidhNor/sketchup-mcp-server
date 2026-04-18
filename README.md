# SketchUp MCP

This repository ships an MCP server inside a SketchUp extension.

- The extension code lives under `src/`.
- MCP tool registration and SketchUp behavior are both owned in Ruby.
- The packaged artifact is a single staged RBZ built from the vendored support tree.

## Repo Structure

```text
.
├── .github/
│   └── workflows/
├── config/
│   └── runtime_package_manifest.json
├── rakelib/
│   ├── package.rake
│   ├── release_support.rb
│   ├── ruby.rake
│   ├── version.rake
│   └── release_support/
├── specifications/
│   ├── adrs/
│   ├── guidelines/
│   ├── hlds/
│   ├── prds/
│   └── tasks/
├── src/
│   ├── su_mcp.rb
│   └── su_mcp/
│       ├── adapters/
│       ├── developer/
│       ├── editing/
│       ├── modeling/
│       ├── runtime/
│       │   └── native/
│       ├── scene_query/
│       └── semantic/
└── test/
    ├── adapters/
    ├── editing/
    ├── modeling/
    ├── release_support/
    ├── runtime/
    │   └── native/
    ├── scene_query/
    ├── semantic/
    └── support/
```

Key root files:

- `Rakefile`: canonical local validation and packaging entrypoints
- `releaserc.toml`: CI-owned semantic-release configuration
- `VERSION`: release version source of truth
- `AGENTS.md`: contributor/repo operating guidance

## Local Development

Install Ruby tooling:

```bash
bundle install
```

The extension entrypoint is `src/su_mcp.rb`, which registers `src/su_mcp/main.rb` with SketchUp. On load, the extension installs menu actions for the MCP server and attempts to start it automatically when the staged vendored support tree is present.

For local development, load the extension from this repository by symlinking or copying the `src/` contents into SketchUp's `Plugins` directory.

Build the canonical RBZ package:

```bash
bundle exec rake package:rbz
```

Verify the staged package layout:

```bash
bundle exec rake package:verify
```

The package output is `dist/su_mcp-<version>.rbz`, where the version comes from `VERSION`.

## Current Tool Surface

The current MCP surface includes scene inspection, semantic scene modeling, and editing helpers such as:

- `get_scene_info`
- `list_entities`
- `get_entity_info`
- `find_entities`
- `sample_surface_z`
- `create_site_element`
- `set_entity_metadata`
- `create_group`
- `reparent_entities`
- `delete_entities`
- `transform_entities`
- `set_material`
- `boolean_operation`
- `eval_ruby`

Public geometric dimensions for `create_site_element` are interpreted and returned in meters, independent of the active SketchUp model unit display settings.
The public `create_site_element` request is sectioned: `elementType`, `metadata`, `definition`, `hosting`, `placement`, `representation`, and `lifecycle`, with optional `sceneProperties` for wrapper `name` and `tag`.
The hierarchy-maintenance surface is intentionally narrow: `create_group` creates a plain group container, optionally grouping supplied child groups or component instances, and `reparent_entities` explicitly reparents supported groups or component instances using the same compact target-reference contract (`sourceElementId`, `persistentId`, `entityId`).
`list_entities` is an explicit inventory tool that now requires `scopeSelector` (`top_level`, `selection`, or `children_of_target`) plus optional `outputOptions`.
`find_entities` is an exact-match targeting tool that now requires `targetSelector` with nested `identity`, `attributes`, and `metadata` sections.
`delete_entities` replaces `delete_component` and deletes one explicitly referenced supported group or component instance, returning structured `operation` and `affectedEntities.deleted` data.

## Local Validation

Run the local CI task set:

```bash
bundle exec rake ci
```

This runs:

- `version:assert`
- `ruby:lint`
- `ruby:test`
- `package:verify`

## Release Automation

Release automation is CI-owned and uses `python-semantic-release` from the standalone [`releaserc.toml`](./releaserc.toml) configuration. Normal development, testing, and package verification do not require a repo-local Python environment.

Prepare a local versioned artifact:

```bash
NEW_VERSION=0.1.1 bundle exec rake release:prepare
```

This syncs the version files and verifies the canonical RBZ package.

## VS Code Tasks

The workspace includes tasks for:

- `bundle install`
- `bundle exec rake ci`
- `bundle exec rake package:verify`
- launching SketchUp via the `SKETCHUP_EXECUTABLE` environment variable
