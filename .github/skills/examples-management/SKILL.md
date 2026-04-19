---
name: examples-management
description: "Load this skill when adding, modifying, or reviewing content in the content/examples/ or content/demos/ directories: game example scripts, demo folder structure, conf.lua, or README files. Use for ensuring examples are self-contained, well-commented, and demonstrate one API concept. Skip it for engine Rust code, tests, documentation under docs/, or CAG work."
---
# examples-management

## Mission

# Examples Management — Lurek2D

## When To Load

- Adding a new Lua example to `content/examples/` or demo to `content/demos/`
- Reviewing an existing example for correctness or code quality
- Understanding the difference between `content/examples/` and `content/demos/`
- Writing conf.toml for a demo
- Linking an example to the API documentation pipeline
- Setting up an example to work as a smoke test

## When To Skip

- Skip it for engine Rust code, tests, documentation under docs/, or CAG work.

## Domain Knowledge

### Owns
- `content/examples/` vs `content/demos/` structure and naming rules
- Example file self-contained requirement and comment style
- Demo folder layout (conf.lua, main.lua, assets, README)
- Examples ↔ API documentation pipeline integration
- Smoke test support pattern (`--smoke` flag + `lurek.signal.quit()`)
- `content/examples/README.md` and `content/demos/README.md` maintenance

### Two-Folder Model
| Folder | Purpose | Scope | Format |
|--------|---------|-------|--------|
| `content/examples/` | Minimal single-file API demonstrations | One `.lua` file per API area | ~30–100 lines, no conf.lua |
| `content/demos/` | Larger showcase games/feature demos | Full game directory (conf.toml + main.lua + assets) | 100–500+ lines, multiple files |

**Rule**: An `content/examples/` file shows one API namespace in the simplest possible way. A `content/demos/` folder is a small, complete game or feature showcase.

### content/examples/ File Structure
> See [snippets/content-examples-file-structure.txt](snippets/content-examples-file-structure.txt) for the example.

**Example file template:**

> See [examples/content-examples-file-structure-2.lua](examples/content-examples-file-structure-2.lua) for the example.

**Required elements:**
- Top comment block: file path, one-line purpose, run command
- Small section comments `-- ── section ──` before `load`, `update`, `draw`
- No `conf.toml` (uses default window settings)
- Self-contained: no external assets unless they are embedded in the engine

### content/demos/ Folder Structure
> See [snippets/content-demos-folder-structure.txt](snippets/content-demos-folder-structure.txt) for the example.

**conf.toml template:**
> See [examples/content-demos-folder-structure-2.lua](examples/content-demos-folder-structure-2.lua) for the example.

### What Makes a Good Example
| Quality | Description |
|---------|-------------|
| **Scenario-driven** | Each section is a named game task ("schedule bullet despawn"), not a function name |
| **Self-contained** | Runs with `cargo run -- content/examples/<file>` without extra setup |
| **Answers WHY** | The reader understands when and why they would reach for each function |
| **Game values** | All arguments are realistic: `hp=100`, `"hero_walk.png"`, not `0`, `""`, `nil` |
| **Coverage + clarity** | `example_coverage.py` passing is the floor, not the ceiling |

### The scenario pattern — ALWAYS write this way

> See [examples/the-scenario-pattern-always-write-this.lua](examples/the-scenario-pattern-always-write-this.lua) for the example.

### FORBIDDEN patterns — never write these

> See [examples/forbidden-patterns-never-write-these.lua](examples/forbidden-patterns-never-write-these.lua) for the example.

The test: "if I showed this to a developer who has never heard of this engine, would they
understand what game problem this solves?" If NO, rewrite it as a scenario.

### Adding a New Example (Checklist)
**Minimal example** (one `.lua` file):

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/content-examples-file-structure.txt](snippets/content-examples-file-structure.txt) — content/examples/ File Structure
- [examples/content-examples-file-structure-2.lua](examples/content-examples-file-structure-2.lua) — content/examples/ File Structure
- [snippets/content-demos-folder-structure.txt](snippets/content-demos-folder-structure.txt) — content/demos/ Folder Structure
- [examples/content-demos-folder-structure-2.lua](examples/content-demos-folder-structure-2.lua) — content/demos/ Folder Structure
- [examples/the-scenario-pattern-always-write-this.lua](examples/the-scenario-pattern-always-write-this.lua) — The scenario pattern — ALWAYS write this way
- [examples/forbidden-patterns-never-write-these.lua](examples/forbidden-patterns-never-write-these.lua) — FORBIDDEN patterns — never write these
- [snippets/examples-and-api-documentation.ps1](snippets/examples-and-api-documentation.ps1) — Examples and API Documentation
- [snippets/smoke-testing.ps1](snippets/smoke-testing.ps1) — Smoke Testing
- [examples/smoke-testing-2.lua](examples/smoke-testing-2.lua) — Smoke Testing
- [snippets/examples-readme.md](snippets/examples-readme.md) — Examples README
- [examples/input-key-names.lua](examples/input-key-names.lua) — Input Key Names
- [examples/color-values.lua](examples/color-values.lua) — Color Values
- [examples/rectangle-draw-mode.lua](examples/rectangle-draw-mode.lua) — Rectangle Draw Mode
- [examples/physics-body-types.lua](examples/physics-body-types.lua) — Physics Body Types
- [snippets/step-1-check-gaps.ps1](snippets/step-1-check-gaps.ps1) — Step 1 — Check gaps
- [snippets/step-2-append-stubs-for-missing.ps1](snippets/step-2-append-stubs-for-missing.ps1) — Step 2 — Append stubs for missing API
- [snippets/step-3-flesh-out-stubs-with.txt](snippets/step-3-flesh-out-stubs-with.txt) — Step 3 — Flesh out stubs with real code
- [snippets/step-3-flesh-out-stubs-with-2.txt](snippets/step-3-flesh-out-stubs-with-2.txt) — Step 3 — Flesh out stubs with real code
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
