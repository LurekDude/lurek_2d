# Lurek2D — Architecture Index

Navigation for `docs/architecture2/`. These files describe the engine design, module structure, rendering pipeline, test strategy, VS Code extension, CAG layer, plugin model, and TOGAF alignment. The discovery index loaded every session is [.github/copilot-instructions.md](../../.github/copilot-instructions.md). Per-module contracts live in [docs/specs/](../specs/). Contributor onboarding is in [docs/handbook.md](../handbook.md).

---

## Table of Contents

1. [Reading Order](#reading-order)
2. [File Index](#file-index)
3. [Cross-Artifact Sync](#cross-artifact-sync)
4. [When to Edit What](#when-to-edit-what)

---

## Reading Order

For a new contributor, read top-down:

1. [philosophy.md](philosophy.md) — Zen rules, binding constraints, retired decisions. Source of truth.
2. [engine-architecture.md](engine-architecture.md) — Module groups, boot sequence, frame model, state, pipelines.
3. [render-command-architecture.md](render-command-architecture.md) — Three-layer render pipeline and per-module output catalogue.
4. [test-framework.md](test-framework.md) — Two-layer Rust + Lua test model, placement rules, coverage tooling.
5. [vscode-architecture.md](vscode-architecture.md) — VS Code extension: activation, providers, debug bridge, MCP server.
6. [cag-system.md](cag-system.md) — CAG layer doctrine, file types, discovery flow, persona model, validator.
7. [plugins.md](plugins.md) — Plugin architecture (Proposed): tiers, loading options, candidate matrix, migration plan.
8. [togaf.md](togaf.md) — TOGAF-aligned architecture: four-domain mapping, artifact taxonomy, governance.

For contributor onboarding (clone → build → first game → first engine change), see [docs/handbook.md](../handbook.md).

---

## File Index

| File | Purpose | Primary Audience |
|------|---------|-----------------|
| [philosophy.md](philosophy.md) | Binding constraints, Zen rules, retired decisions | EngDev · GameDev · Modder |
| [engine-architecture.md](engine-architecture.md) | Module groups, module inventory, boot, frame, state, Lua binding architecture | EngDev · GameDev |
| [render-command-architecture.md](render-command-architecture.md) | Three-layer render design, per-module output catalogue | EngDev · GameDev |
| [test-framework.md](test-framework.md) | Rust + Lua test architecture, placement rules, coverage tooling, CI gates | EngTest · GameTest · EngDev |
| [vscode-architecture.md](vscode-architecture.md) | VS Code extension: services, providers, debug bridge, MCP server, webview editors | EngDev · GameDev |
| [cag-system.md](cag-system.md) | CAG layer: file-type catalog, discovery flow, persona matrix, validator and tooling | All personas |
| [plugins.md](plugins.md) | Plugin architecture (Proposed): core/plugin boundary, tiers, candidates, migration | EngDev · Modder |
| [togaf.md](togaf.md) | TOGAF-aligned view: four domains, artifact taxonomy, governance, scope boundaries | Architect · EngDev |

---

## Cross-Artifact Sync

The system prompt at [.github/copilot-instructions.md](../../.github/copilot-instructions.md) carries the authoritative Cross-Artifact Sync table. Use it whenever you change Rust code, Lua bindings, library init, or CAG files. Per-module contracts live in [docs/specs/](../specs/). Generated API references are in [docs/api/](../api/) — never edit by hand; regenerate via `python tools/gen_all_docs.py`.

---

## When to Edit What

| You changed… | Update this arch doc |
|---|---|
| A Rust module `src/<module>/` | [docs/specs/&lt;module&gt;.md](../specs/) (always); [philosophy.md](philosophy.md) only if a binding rule moves |
| Render pipeline, `RenderCommand` variant, pass structure | [render-command-architecture.md](render-command-architecture.md) |
| Module group assignment, boot sequence, frame order, state layout | [engine-architecture.md](engine-architecture.md) |
| Test strategy, new test tier, golden/evidence rules, harness registration | [test-framework.md](test-framework.md) |
| VS Code extension commands, MCP server, providers, debug bridge | [vscode-architecture.md](vscode-architecture.md) |
| `.github/` layer (agent, skill, prompt, validator, persona matrix) | [cag-system.md](cag-system.md) and the system prompt |
| Plugin boundary, feature flag, plugin ABI | [plugins.md](plugins.md) |
| TOGAF alignment, four-domain mapping, governance, scope boundaries | [togaf.md](togaf.md) |

Always add a bullet under the current version in [docs/CHANGELOG.md](../CHANGELOG.md).
