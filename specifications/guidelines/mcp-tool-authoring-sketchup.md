# MCP Tool Authoring Standard for SketchUp Modeling

This document defines strong guidance for shaping MCP tools and schemas for the SketchUp modeling surface.

It is intended to keep the public contract coherent, stable, agent-friendly, and evolution-safe as the tool surface grows. The emphasis is on writing better tool definitions and better schemas, not on mirroring underlying implementation details.

---

## 1. Design for clear contract boundaries

A tool should represent a distinct modeling capability or workflow-facing action, not a thin wrapper over internal APIs.

Prefer tools that express domain intent, such as semantic creation, validation, inspection, alignment, replacement, or controlled mutation. Avoid exposing raw low-level SketchUp or Ruby operations as first-class public tools unless the abstraction genuinely requires it.

A strong tool boundary should make these questions easy to answer:

- What is this tool for?
- What is it not for?
- What kind of request belongs here?
- How is it different from neighboring tools?

If two tools could plausibly be used for the same request without a clear preference, the boundary is probably too weak.

---

## 2. Prefer extending existing tools over creating new public ones

The public tool surface should stay compact.

When new capability is needed, first prefer:

1. extending an existing nested section
2. adding a small, well-owned sub-object
3. adding a narrowly scoped enum value
4. adding a new optional field only when ownership is clear

Create a new public tool only when the new capability represents a genuinely distinct workflow or contract boundary, not just another variant of an existing tool.

A good public surface grows by deepening existing semantic tools, not by multiplying near-duplicates.

---

## 3. Keep top-level payloads shallow and stable

Top-level fields should be few, durable, and conceptually strong.

Prefer a small number of owned sections over many flat sibling attributes.

### Guidance

- Target **3–8 top-level fields** for most tools
- Avoid flat payloads with large numbers of sibling keys
- Prefer nesting by ownership, not by implementation layer
- Keep top-level vocabulary stable over time

Good:

```json
{
  "metadata": {...},
  "definition": {...},
  "hosting": {...},
  "placement": {...},
  "representation": {...},
  "lifecycle": {...}
}
```

Bad:

```json
{
  "family": "...",
  "tag": "...",
  "replaceTarget": "...",
  "parentCollection": "...",
  "hostEdgeId": "...",
  "terrainFollow": true,
  "materialPolicy": "...",
  "assetPreference": "..."
}
```

The first shape makes ownership obvious. The second forces readers to infer it.

---

## 4. Keep object shapes compact

Large objects with too many sibling fields become harder to understand, harder to extend cleanly, and easier to misuse.

### Guidance

- Ideal: **4–8 sibling attributes**
- Acceptable: up to **10–12**
- Warning zone: above **12**
- Refactor trigger: **15+**

If an object becomes too large, it usually means one of the following:

- it contains multiple concerns
- selector, action, and policy are mixed together
- it needs a nested sub-object
- it is turning into a catch-all bucket

Avoid `options`, `misc`, `advanced`, `config`, or `extra` objects that exist only to absorb overflow.

---

## 5. Nest by ownership, not by implementation detail

Nested objects should reflect conceptual ownership.

This is especially important for tools like `create_site_element`, where long-term durability depends on preserving section discipline.

### Example ownership model

- `metadata`: durable business identity and workflow state
- `definition`: intrinsic semantic recipe for the atomic element family
- `hosting`: terrain, edge, boundary, or host conformity
- `placement`: scene parent context and transform intent
- `representation`: visual, material, asset, or structural realization
- `lifecycle`: create, adopt, replace, rebuild, or modify semantics

A field belongs where its meaning naturally lives, not where it happens to be convenient to place.

---

## 6. Preserve section ownership rigorously

Section ownership is one of the most important forms of contract discipline.

For example:

- adoption and replacement targets belong in `lifecycle`
- terrain, boundary, edge, and host conformity belong in `hosting`
- parent context and transform intent belong in `placement`
- family semantics belong in `definition`
- visual richness and material policy belong in `representation`

Do not move a concept into a different section just because that section already exists in the request being edited.

If ownership drifts, the schema may remain technically valid while becoming conceptually incoherent.

---

## 7. Keep MCP parameter roots provider-compatible

Every public tool declaration must use a simple top-level parameter schema:

- top-level `type: "object"`
- top-level `properties`
- optional top-level `required`
- no top-level `anyOf`, `oneOf`, `allOf`, `not`, or root `enum`

Provider function/tool validators may reject top-level schema composition even when the MCP server can render it. Conditional usage should be communicated through small enums, field descriptions, examples, and runtime structured refusals with `allowedValues`, not root schema branches.

Recovery-only request shapes must not be advertised as alternate public schema branches. Keep the canonical public contract in the tool schema and handle recognizable mistakes inside runtime validation or recovery seams.

---

## 8. Separate selectors, actions, constraints, and output options

These are different kinds of information and should not be blended.

### Distinct roles

- **selector**: what to operate on
- **action**: what to do
- **constraints or policy**: how strict, safe, or flexible execution should be
- **output options**: how much or what kind of result data to return

Good:

```json
{
  "target_selector": {...},
  "transform": {...},
  "constraints": {
    "ambiguity_policy": "fail"
  },
  "output_options": {
    "response_format": "concise"
  }
}
```

Bad:

```json
{
  "target": "west fence",
  "mode": "smart",
  "strict": true
}
```

When these roles are separated, tool definitions are easier to understand and easier to extend.

---

## 9. Reuse shared shapes across tools

Consistency across tools is more valuable than local cleverness.

When the same conceptual pattern appears in multiple tools, prefer a shared shape rather than inventing a new one.

Common candidates for reuse:

- `target_selector`
- `reference_selector`
- `ambiguity_policy`
- `constraints`
- `output_options`
- result fields such as `warnings`, `affected_entities`, and `status`

Shared shapes reduce cognitive load, improve consistency, and make the contract easier to evolve.

---

## 10. Use explicit, domain-meaningful field names

Field names should communicate business or modeling intent rather than transport or implementation detail.

Prefer names such as:

- `target_selector`
- `replace_target`
- `terrain_conformity`
- `host_surface`
- `preserve_identity`
- `response_format`

Avoid vague or generic names such as:

- `data`
- `config`
- `options`
- `mode`
- `smart`
- `advanced`
- `target`
- `info`

Longer but clearer names are usually better than shorter ambiguous names.

---

## 11. Prefer explicit objects over overloaded strings

Do not compress multiple decisions into a single string field when those decisions have structure.

Bad:

```json
{
  "target": "west boundary edge",
  "mode": "adaptive"
}
```

Better:

```json
{
  "target_selector": {
    "by": "collection_and_tag",
    "collection": "west_boundary",
    "tag": "primary_edge"
  },
  "hosting": {
    "conform_to": "edge_path",
    "offset_mm": 120
  }
}
```

Structured objects clarify meaning, improve extensibility, and reduce ambiguity.

---

## 12. Use enums aggressively, but keep them small and clean

Enums are one of the best ways to make a schema explicit.

### Guidance

- Prefer enums for stable conceptual sets
- Keep enums small, ideally **3–9 values**
- Avoid bloated enums that mix unrelated concepts
- Avoid vague values such as `smart`, `auto`, `adaptive`, or `default` unless their meaning is truly narrow and stable

Good:

```json
"ambiguity_policy": {
  "type": "string",
  "enum": ["fail", "first", "largest", "all"]
}
```

Bad enums usually hide unclear ownership or mixed concerns.

---

## 13. Use booleans only for truly binary meaning

Booleans are appropriate when the concept is genuinely binary and stable.

Good examples:

- `preview_only`
- `preserve_identity`
- `include_children`

Poor examples:

- `smart`
- `strict`
- `safe`
- `adaptive`

If the meaning of `true` requires explanation, the field may need to become an enum or nested object.

---

## 14. Prefer discriminated shapes for meaningfully different modes

When a request can take one of several meaningfully different forms, make that explicit in the shape.

For example, different lifecycle modes should be structured clearly:

```json
{
  "lifecycle": {
    "mode": "replace",
    "replace_target": {...}
  }
}
```

This is better than relying on loosely related optional fields whose interaction must be inferred.

The more different the modes are semantically, the more they should be visible in the schema.

---

## 15. Descriptions should be precise, bounded, and contrastive

Each tool description should make the boundary of the tool clear.

A strong description usually includes:

1. what the tool does
2. when it should be used
3. when it should not be used
4. what neighboring abstraction it is intentionally not replacing

Example pattern:

> Creates or updates a managed site element from a semantic definition. Use when the request concerns semantic scene objects such as fences, paths, curbs, or hosted site elements. Do not use for low-level primitive geometry or direct staged asset instancing.

Descriptions should reduce ambiguity between neighboring tools.

---

## 16. Put subtle usage rules in field descriptions, not only external docs

If a field has a non-obvious ownership rule or a subtle boundary, document it at the field level.

Examples:

- `lifecycle.replace_target`: use only when preserving business identity while replacing scene realization
- `hosting.edge_reference`: describes host geometry for conformity, not lifecycle targets
- `placement.parent_context`: scene organization target, not host relationship

Important constraints should be visible where the decision is made.

---

## 17. Default outputs should be compact and chainable

Default outputs should contain enough information for the next reasoning step, but should not dump excessive data.

Prefer results that include:

- `status`
- `warnings`
- semantic summary
- stable handles or references where needed
- affected or matched entities
- identity continuity where relevant

Avoid returning large raw structures by default unless the tool is explicitly for deep inspection.

Support heavier results through explicit output options such as:

- `response_format: concise | detailed`
- `include_children`
- `include_metadata`
- `include_geometry_summary`

---

## 18. Mutation tools should return structured result envelopes

Mutating tools should return more than success or failure.

Preferred result contents:

- `status`
- `operation`
- `affected_entities`
- `warnings`
- `errors`
- `identity` or continuity metadata where relevant

Example:

```json
{
  "status": "success",
  "operation": {
    "name": "create_site_element",
    "kind": "replace"
  },
  "affected_entities": {
    "created": [...],
    "modified": [...],
    "deleted": [...]
  },
  "identity": {
    "managed_object_id": "fence-west-01",
    "preserved_from": "..."
  },
  "warnings": []
}
```

This makes results more useful, more debuggable, and easier to build on.

---

## 19. Make safety and ambiguity policies explicit

Do not rely on implicit safety behavior.

Common policy fields include:

- `ambiguity_policy`
- `preview_only`
- `fail_if_missing`
- `allow_partial_success`
- `collision_policy`
- `replace_policy`

These should be represented explicitly in the schema when they materially affect behavior.

Destructive or safety-relevant tools should also be clearly marked in metadata and descriptions.

---

## 20. Prefer additive evolution and stable vocabulary

Stable public vocabulary is a major source of clarity.

Once the contract adopts terms such as:

- `hosting`
- `placement`
- `representation`
- `lifecycle`
- `target_selector`

avoid introducing casual synonyms such as:

- `context`
- `location`
- `rendering`
- `mode`
- `target`

Prefer additive evolution over renaming. Avoid aliases unless absolutely necessary.

A schema can grow safely when its vocabulary remains stable and well-owned.

---

## 21. Avoid exposing raw internals as the public contract

The public schema should reflect domain semantics, not the accident of how the backend happens to implement them.

Avoid making public fields revolve around:

- raw Ruby method structure
- low-level SketchUp entity internals unless required
- transport convenience over domain meaning
- internal shortcuts that bypass the semantic contract

The public tool surface should teach the domain, not the backend.

---

## 22. Keep escape hatches visibly second-class

If an escape hatch such as `eval_ruby` exists, it should remain clearly exceptional.

It should not shape the rest of the contract, and it should not become a substitute for improving the primary tool surface.

Escape hatches are useful for rare cases and debugging, but they should remain explicitly outside the main contract discipline.

---

## 23. Prefer examples for complex or highly nested tools

Any tool with nested sections, conditional fields, or multiple semantic modes should have examples near the contract definition or in adjacent guidance.

Useful example types:

- minimal valid request
- advanced request
- example showing correct section ownership
- example showing a common misplacement and the corrected version

Examples are especially important when the request shape is sectioned or when similar tools sit close together.

---

## 24. Anti-patterns to avoid

Avoid the following recurring contract failures:

- adding a new public tool for a case that belongs in an existing semantic tool
- flattening ownership into many sibling fields
- placing lifecycle targets in `hosting`
- placing terrain conformity in `placement`
- placing identity transition semantics in `metadata`
- introducing vague `options`, `misc`, `advanced`, or `smart` fields
- inventing one-off selector grammars for individual tools
- returning `success: true` without meaningful result detail
- naming tools or fields after low-level backend internals
- making neighboring tools overlap without a clear boundary

These patterns create drift, ambiguity, and long-term contract erosion.

---

## 25. Preferred standard for authoring new or revised tools

When shaping a new or revised tool, aim for the following qualities:

- distinct purpose
- minimal top-level shape
- strong ownership boundaries
- shared selector and result patterns
- explicit policy fields where behavior meaningfully varies
- compact default outputs
- stable naming and vocabulary
- examples for non-obvious shapes
- no unnecessary overlap with neighboring tools

A good tool definition should feel unsurprising once the rest of the tool surface is understood.

---

## 26. Practical heuristics

Use these as strong defaults:

- Keep top-level input to **3–8 major fields**
- Keep most objects under **10–12 sibling attributes**
- Prefer **nested ownership sections** over flat payloads
- Prefer **explicit enums** over vague strings
- Keep **shared shapes** consistent across tools
- Make **descriptions contrastive**, not generic
- Make **outputs chainable**, not merely successful
- Prefer **stable vocabulary** over local convenience
- Extend existing semantic tools before adding new public tools

These heuristics are not rigid laws, but deviating from them should require a clear reason.

---

## Closing principle

The SketchUp MCP surface should evolve by becoming deeper and clearer, not wider and noisier.

Strong tools are not just valid schemas. They are durable semantic contracts with clear boundaries, stable ownership, compact shapes, predictable outputs, and vocabulary that stays coherent as the system grows.
