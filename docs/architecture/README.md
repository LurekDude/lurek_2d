# Lurek2D — Architecture Documentation Index

Navigation for `docs/architecture/`. These files describe the engine's design, runtime, test strategy, tooling, and the CAG layer that customises AI-assisted work on the repo. The discovery index that points here from every chat session is [.github/copilot-instructions.md](../../.github/copilot-instructions.md); per-module contracts live in [docs/specs/](../specs/); contributor onboarding lives in [docs/handbook.md](../handbook.md).

---

## Reading Order

For a new contributor, read top-down:

1. [philosophy.md](philosophy.md) — Zen rules, binding constraints (A/B/T/C/Q IDs), retired decisions. **Source of truth.**
2. [engine-architecture.md](engine-architecture.md) — module groups, boot sequence, frame model, state, module file-structure standard.
3. [render-command-architecture.md](render-command-architecture.md) — the three-layer `RenderCommand` pipeline and per-module output catalogue.
4. [test-framework.md](test-framework.md) — two-layer Rust+Lua test model, golden/evidence suites, coverage tooling.
5. [vscode-architecture.md](vscode-architecture.md) — live description of the shipping VS Code extension.
6. [cag-system.md](cag-system.md) — CAG layer doctrine, validator rules, end-of-session sweep contract.
7. [plugins.md](plugins.md) — plugin architecture (Proposed): core-vs-plugin boundary, load tiers, candidate matrix, migration plan.

For contributor onboarding (clone → build → first game → first engine change), see [docs/handbook.md](../handbook.md).

---

## File Index

| File                                                             | Purpose                                                                                                                                                      | Primary Audience                               |     Length |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------- | ---------: |
| [philosophy.md](philosophy.md)                                   | Binding constraints, Zen rules, retired decisions. Every other architecture doc refers back here.                                                            | EngDev · GameDev · Modder · GameTest · EngTest | ~260 lines |
| [engine-architecture.md](engine-architecture.md)                 | Module groups, complete module inventory, boot + frame + state, Lua binding architecture, subsystem pipelines. Canonical for module file-structure standard. | EngDev · GameDev                               | ~790 lines |
| [render-command-architecture.md](render-command-architecture.md) | Three-layer `RenderCommand` design, per-module output catalogue, render-module refactoring plan.                                                             | EngDev · GameDev                               | ~890 lines |
| [test-framework.md](test-framework.md)                           | Rust + Lua test architecture, BDD framework, golden/evidence suites, coverage tooling, CI gates.                                                             | EngTest · GameTest · EngDev                    | ~980 lines |
| [vscode-architecture.md](vscode-architecture.md)                 | Shipping `extensions/vscode/` design: activation, commands, debug bridge, MCP server, webview editors.                                                       | EngDev · GameDev                               | ~535 lines |
| [cag-system.md](cag-system.md)                                   | CAG layer (`.github/`) file-type catalog, discovery flow, persona matrix, validator & tooling, sweep contract.                                               | All six personas                               | ~295 lines |
| [plugins.md](plugins.md)                                         | Plugin architecture (Proposed): core-vs-plugin boundary, Tier A/B/C load mechanism, candidate matrix, migration plan, comparison to other engines.           | EngDev · Modder                                | ~370 lines |

---

## Cross-Artifact Sync

The system prompt at [.github/copilot-instructions.md](../../.github/copilot-instructions.md) carries the authoritative **Cross-Artifact Sync** table — use it whenever you change Rust code, Lua bindings, library init, or CAG files. Per-module contracts (types, functions, `lurek.*` reference, test paths) live in [docs/specs/<module>.md](../specs/); generated API references live in [logs/reports/](../../logs/reports/) and [docs/api/lurek.md](../lua-api.md). Architecture docs above describe *how the pieces fit*; specs describe *what each module is*.

---

## When to Edit What

| You changed…                                                                                      | Update this arch doc                                                                                       |
| ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| A Rust module (`src/<module>/`)                                                                   | [docs/specs/<module>.md](../specs/) (always); [philosophy.md](philosophy.md) only if a binding rule moves. |
| Render pipeline, `RenderCommand` variant, pass structure                                          | [render-command-architecture.md](render-command-architecture.md)                                           |
| Module group assignment, boot sequence, frame order, state layout, module file-structure standard | [engine-architecture.md](engine-architecture.md)                                                           |
| Test strategy, new test tier, golden/evidence rules, harness registration                         | [test-framework.md](test-framework.md)                                                                     |
| VS Code extension commands, MCP server, providers, debug bridge                                   | [vscode-architecture.md](vscode-architecture.md)                                                           |
| `.github/` layer (agent, skill, prompt, validator, persona matrix)                                | [cag-system.md](cag-system.md) and the system prompt                                                       |
| Plugin boundary, feature flag, plugin ABI                                                         | [plugins.md](plugins.md)                                                                                   |

Always also add a bullet under the current version in [docs/CHANGELOG.md](../CHANGELOG.md).
