# STI-01 Implementation Summary

## Delivered

- Added the public `find_entities` bridge contract cases for `unique`, `none`, `ambiguous`, and malformed-query behavior.
- Implemented Ruby-owned MVP targeting in `SceneQueryCommands`, backed by the new `TargetingQuery` helper and compact match serialization in `SceneQuerySerializer`.
- Added adapter support for queryable top-level entity enumeration used by Ruby-side targeting.
- Added Python MCP registration for `find_entities` with a typed nested `query` model and thin request forwarding to the Ruby bridge.

## Tests Added

- Ruby command coverage for query validation, supported match paths, exact-match AND semantics, resolution states, and string-typed identifiers.
- Ruby adapter and dispatcher coverage for the new targeting path.
- Python tool coverage for tool registration, nested schema visibility, passthrough query shaping, and request-id propagation.
- Ruby and Python contract coverage for the new shared bridge cases.

## Implementation Notes

- `sourceElementId` remains best-effort and is surfaced only when present on entity attributes.
- The targeting summary contract is intentionally separate from the broader scene-inspection serializer shape.
- The FastMCP schema assertion uses the registered tool's `parameters` schema, dereferenced in tests, because that is the local introspection surface exposed by the installed FastMCP version.
