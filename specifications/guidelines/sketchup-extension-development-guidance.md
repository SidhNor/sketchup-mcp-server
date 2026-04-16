# SketchUp Extension Development Guidance

## When to use this

Read this document when:

- implementing or refactoring Ruby extension code
- changing RBZ packaging behavior
- making technical decisions about SketchUp-extension structure or UX

Do not load it by default for Python-only MCP adapter work.

## Core guidance

### Keep the loader small

The root extension file should register the extension and little else. Runtime boot, menus, transport, and capability logic belong in the support tree.

### Keep one top-level namespace

SketchUp extensions share one Ruby process. Use one unique top-level namespace and avoid global variables, top-level helper methods, or generic constants.

### Preserve the standard SketchUp extension shape

Package the extension as:

- one root registration `.rb` file
- one support folder with the same base name

### Keep SketchUp behavior in Ruby

SketchUp API access, model mutation, entity traversal, serialization, and extension behavior belong in Ruby. Do not move SketchUp business rules into Python for convenience.

### Respect the undo stack

If one user action causes model changes, wrap those changes in `Sketchup::Model#start_operation` / `commit_operation` so the user gets one coherent undo step.

Do not make silent model changes outside deliberate user actions.

### Isolate SketchUp API-heavy code

As the extension grows, keep low-level SketchUp API usage in focused adapters, helpers, or command objects instead of scattering it across bootstrap and transport code.

### Respect SketchUp UX conventions

- put commands in the `Extensions` menu, typically under a submenu
- ensure toolbar commands are also reachable from menus
- avoid noisy or overly technical wording
- do not modify locked entities unless that is the explicit purpose of the tool
- use SketchUp length parsing and formatting instead of inventing your own unit handling

### Do not assume installed extension files are writable

Do not treat the installed support folder as an application data directory.

## Working checklist

Before merging Ruby extension changes, check:

- the loader is still minimal
- runtime behavior still lives in the support tree
- no new globals or top-level helpers were introduced
- model-changing user actions are wrapped as coherent undo operations
- RBZ layout is still correct

## Official references

- [Creating a SketchUp Extension](https://developer.sketchup.com/article-creating-a-sketchup-extension)
- [UX Guidelines](https://developer.sketchup.com/article-ux-guidelines)
- [Writing Your First Code](https://developer.sketchup.com/article-writing-your-first-code)
- [Extension Listing Pages](https://developer.sketchup.com/article-whentouselisting)
- [SketchUp Developer Center](https://developer.sketchup.com/)
