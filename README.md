# SketchUp MCP

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=SidhNor_sketchup-mcp-server&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=SidhNor_sketchup-mcp-server)

SketchUp MCP is an open-source **SketchUp extension + MCP server** that gives AI assistants and automation clients a reliable way to explore, measure, and edit 3D scenes.

If you are building agentic design workflows, planning tools, or model-aware copilots, this project provides a practical bridge between **MCP clients** and **real SketchUp production models**.

## Why people use it

SketchUp MCP is built for teams that want structured 3D workflows instead of brittle one-off scripts.

Typical usage patterns include:

- Site and model discovery through structured scene-query tools
- Option exploration and rapid 3D concept iteration
- Semantic authoring for domain elements (paths, structures, terrain-linked objects)
- Managed terrain lifecycle workflows (create, adopt, edit)
- Model measurement and validation checks in iterative design loops

## What you can do with it

- Interrogate scene state with explicit inventory, targeting, and measurement tools
- Author and update semantic site elements through stable MCP contracts
- Build and edit managed terrain surfaces with create/adopt/edit flows backed by tiled heightmap
  state and adaptive derived SketchUp output
- Curate, discover, and instantiate staged asset exemplars as editable scene objects
- Orchestrate structured model edits (grouping, reparenting, transforms, materials)
- Integrate SketchUp into iterative, agent-assisted planning and design workflows

## Who this is for

- Engineers building MCP clients for design/construction workflows
- Teams experimenting with AI-assisted 3D planning and authoring
- Contributors interested in SketchUp automation, runtime design, and tool contracts

## Project status

This repository is actively developed and includes runtime code plus product/architecture documentation.

Current direction lives in:

- Platform HLD: [`specifications/hlds/hld-platform-architecture-and-repo-structure.md`](specifications/hlds/hld-platform-architecture-and-repo-structure.md)
- Domain analysis: [`specifications/domain-analysis.md`](specifications/domain-analysis.md)
- Capability HLDs and tasks: [`specifications/hlds/`](specifications/hlds/) and [`specifications/tasks/`](specifications/tasks/)

## Documentation map

Start here, then branch by need:

1. Project orientation + setup: this README
2. MCP contract and payload details: [`docs/mcp-tool-reference.md`](docs/mcp-tool-reference.md)
3. Contributor operating guidance: [`AGENTS.md`](AGENTS.md)
4. Architecture and roadmap context: [`specifications/`](specifications/)

> A dedicated docs site may be added later; currently, authoritative docs are versioned in this repository.

## Quick start (local development)

Install dependencies:

```bash
bundle install
```

The extension loader is `src/su_mcp.rb`, which registers `src/su_mcp/main.rb` with SketchUp.

For local development, load the extension from this repository by symlinking or copying `src/` into SketchUp's `Plugins` directory.

When loaded in SketchUp, the extension adds one **Managed Terrain** toolbar for
managed-terrain tools. It contains **Target Height Brush**, **Local Fairing**,
and **Corridor Transition** buttons. All three open the shared Managed Terrain
panel, which keeps selected-terrain and status feedback visible while switching
between tool settings. Bounded brush controls use slider plus numeric input
pairs; direct numeric radius and blend values can exceed the slider's ergonomic
`100m` range when otherwise valid. Corridor Transition captures explicit start
and end controls, supports numeric endpoint X/Y/elevation edits, includes
Recapture and Sample Terrain actions for each endpoint, and exposes width plus
side-blend settings before Apply. Applies route through the existing managed
terrain edit command path for the currently selected managed terrain surface.

Build the RBZ package:

```bash
bundle exec rake package:rbz
```

Verify staged package layout:

```bash
bundle exec rake package:verify
```

Package output: `dist/su_mcp-<version>.rbz` (`<version>` comes from `VERSION`).

## Validation and release

Run local CI-equivalent checks:

```bash
bundle exec rake ci
```

This runs:

- `version:assert`
- `ruby:lint`
- `ruby:test`
- `package:verify`

Release automation is CI-owned and configured in [`releaserc.toml`](releaserc.toml) using `python-semantic-release`.

Prepare a local versioned artifact:

```bash
NEW_VERSION=0.1.1 bundle exec rake release:prepare
```

## Console logging

Runtime logs use `SketchUp MCP:` followed by a JSON event containing a UTC timestamp,
severity, component, event name, and message. The default threshold is `info`;
logging does not automatically open the Ruby Console. Use **Open Ruby Console**
from the extension menu to view output.

Under **Extensions → SketchUp MCP**, use **Filter Ruby Console Logs...** to choose
the minimum severity and optional comma-separated component, tool, and request ID
filters. Blank fields match all values. **Reset Ruby Console Log Filters** restores
the default `info` threshold. **Clear Ruby Console** clears the entire native
console, including messages from other extensions, without changing the filters.

The native Ruby Console has no supported API for per-line text colors. Severity
is recorded in each event's `level` field. No additional log window is opened.

Configure session-only filters in the Ruby Console:

```ruby
SU_MCP::RuntimeLogger.configure(min_level: :warn)
SU_MCP::RuntimeLogger.configure(
  min_level: :debug, components: ['developer'], tools: ['eval_ruby'], request_ids: [42]
)
SU_MCP::RuntimeLogger.configure(since: Time.now.utc - 300, until_time: Time.now.utc + 300)
SU_MCP::RuntimeLogger.configure # Reset to defaults.
```

Each configuration replaces the previous filters. Filters combine with AND; values
within each list combine with OR. Time bounds accept Ruby `Time` values and apply
to newly emitted events, with no historical storage or replay.

Runtime callers can supply context with `RuntimeLogger.emit`:

```ruby
SU_MCP::RuntimeLogger.emit(
  'Ruby evaluation failed', level: :error, component: 'developer', event: 'tool.failed',
  tool: 'eval_ruby', request_id: 42, duration_ms: 12, outcome: 'failed'
)
```

HTTP `tools/call` requests emit `tool.completed` events in the `tools`
component with the JSON-RPC request ID, tool name, monotonic duration in milliseconds,
`succeeded`, `failed`, or `refused` outcome, and `response_chars` (the length of the
result text sent to the client, when there is one). They also carry estimated token
counts: `request_tokens_est` for the tool arguments the model wrote and
`response_tokens_est` for the result text it reads back. Estimates divide characters by
4.9 (measured on this server's JSON with an o200k tokenizer); Claude's tokenizer usually
counts JSON somewhat higher, so treat them as a floor, not billing figures. Only sizes
are logged, never the arguments or results themselves. Successes use `info`, failures use
`error`, and refusals use `warn`. Runtime request exceptions also emit
`request.failed` diagnostics without dumping the full request. Exception messages
can still contain source excerpts supplied by Ruby. Completion events contain no
tool arguments or results. Batched requests emit one completion event per tool
call, each with its own request ID and duration. Notification-only batches and
single-response batches preserve the pinned runtime SDK's existing response shape.
Each MCP `initialize` request emits a `client.initialized` event in the `transport`
component with `client` set to the client's reported `name/version`.

Transport messages use the `transport` component, with transport and runtime
lifecycle failures classified as `error`. Remaining string-only logging calls stay
`info` events in the `runtime` component. Tool and request filters match only events
whose callers supply that context.
Messages longer than 2,000 characters are truncated before they reach the Ruby
Console, because large console writes stall SketchUp's UI thread. `eval_ruby`
logs only the result's class, length, and a 200-character preview; the full
result is still returned to the client.
These filters cover this extension's logger, not messages printed directly by
SketchUp, evaluated scripts, or other extensions. Console logging writes no log
files and adds no MCP diagnostics tools; see the opt-in usage log below.

## Usage log (opt-in)

Set `SKETCHUP_MCP_USAGE_LOG` to a file path before starting SketchUp to append one
JSON line per `client.initialized` and `tool.completed` event to that file. Each line
holds a UTC timestamp, the event name, and the same context as the console event:
client, tool name, request ID, outcome, duration, `response_chars`, and the estimated
token counts. Tool
arguments and results are never written. The log is off when the variable is unset
or empty, and write failures are ignored so they never interrupt a SketchUp command.

The log is meant for measuring which tools clients use together and how large their
responses are, to guide token-cost work on the tool surface:

```bash
# macOS: start SketchUp from a shell so it inherits the variable (adjust the version).
SKETCHUP_MCP_USAGE_LOG=/tmp/su_mcp_usage.jsonl \
  "/Applications/SketchUp 2025/SketchUp.app/Contents/MacOS/SketchUp"

# Later, from this repository:
bundle exec rake "mcp:usage_graph[/tmp/su_mcp_usage.jsonl]"
```

On Windows, set the variable in PowerShell (`$env:SKETCHUP_MCP_USAGE_LOG = "C:\temp\su_mcp_usage.jsonl"`)
and start `SketchUp.exe` from the same session.

## Repository layout

```text
.
├── src/                  # SketchUp extension runtime and MCP server
├── test/                 # Runtime and packaging tests
├── specifications/       # HLDs, PRDs, tasks, and engineering guidance
├── rakelib/              # Packaging, release, and project rake tasks
├── config/               # Runtime package assembly configuration
└── docs/                 # User-facing reference material
```

## Contributing

Contributions are welcome—runtime features, contract hardening, tests, and docs all help.

Before opening a PR, review:

- [`AGENTS.md`](AGENTS.md) for repository working agreements
- [`specifications/guidelines/ryby-coding-guidelines.md`](specifications/guidelines/ryby-coding-guidelines.md) for Ruby coding expectations
- [`docs/mcp-tool-reference.md`](docs/mcp-tool-reference.md) when changing tool contracts

When public tool behavior changes, update runtime code, tests, and user-facing docs in the same change.
