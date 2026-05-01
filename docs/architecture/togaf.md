# Lurek2D — TOGAF Architecture

**Target-state document.** This file describes how Lurek2D implements TOGAF-aligned architecture. Authoritative, not aspirational. TOGAF-aware — not TOGAF-certified.

Companion documents: [philosophy.md](philosophy.md) · [engine-architecture.md](engine-architecture.md) · [cag-system.md](cag-system.md)

---

## Table of Contents

1. [Architecture Principles](#architecture-principles)
2. [Four Architecture Domains](#four-architecture-domains)
3. [Architecture Repository](#architecture-repository)
4. [Governance](#governance)
5. [WHY / HOW / WHAT Layer Model](#why--how--what-layer-model)
6. [Scope Boundaries](#scope-boundaries)
7. [References](#references)

---

## Architecture Principles

The primary principles document is [philosophy.md](philosophy.md) — the Lurek2D equivalent of a TOGAF architecture-principles register.

Key characteristics:
- Every principle has a stable constraint code (`T-xx`, `A-xx`, `B-xx`, `C-xx`, `TST-xx`). Codes never change; new principles are added at the end of their group.
- Principles are enforced by tooling: `cargo clippy`, validators (`tools/validate/`), and quality gates — not just documented.
- Exceptions require a documented rationale in the amendment model in `philosophy.md`. Silent workarounds are not accepted.
- The system-prompt (`.github/copilot-instructions.md`) is the always-in-context binding constraint summary. Explanation belongs in architecture docs and skills.

---

## Four Architecture Domains

### Business Architecture

- **Personas:** EngDev, GameDev, Modder, GameTest, EngTest. Every capability decision is evaluated against these five groups. Documented in [docs/handbook.md](../handbook.md) and the CAG persona model in [cag-system.md](cag-system.md).
- **Product identity:** Lurek2D is a single-binary 2D Rust runtime for Lua game scripts. Scope constraints are binding (no mobile, no WASM, no 3D pipeline, no embedded editor, no platform SDKs in core) via `A-*` constraints in `philosophy.md`.
- **Contributor workflow:** canonical lifecycle in [docs/handbook.md](../handbook.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md).

### Data Architecture

- **Serialisation rule:** TOML for human-authored config; JSON for external interop only; never YAML — constraint `B-05`.
- **Save/load boundary:** `lurek.serial` and `lurek.save` own all serialised format contracts. Module specs in `docs/specs/` document each module's data surface.
- **Generated data:** `logs/data/lua_api_data.json` is the machine-readable API data source. `docs/api/lurek.lua` and `docs/api/library.lua` are generated — never edited by hand. Changes flow from `src/lua_api/*_api.rs` through `python tools/gen_all_docs.py`.
- **Config schemas:** TOML layout files in `content/layouts/` validated by `tools/ui/` scripts.

### Application Architecture

Two core files:

| File | Covers |
|------|--------|
| [engine-architecture.md](engine-architecture.md) | Runtime subsystems, module groups, dependency tier graph |
| [docs/specs/README.md](../specs/README.md) | Index of module-level contracts (one spec per module) |

**Module group structure (constraint T-01, no exceptions):**

```
Foundations → Core Runtime → Platform Services → Feature Systems → Edge/Integration
```

No imports may go upward across tier boundaries (constraint `T-02`: no cycles). `src/lua_api/` is a boundary layer — domain code never imports from it.

The Lua API surface (`lurek.*`) is the canonical public interface for game authors. Defined in `src/lua_api/`, governed by the `lua-api-design` skill, documented via `docs/api/lurek.lua`.

The VS Code extension is an opt-in developer experience layer, not part of the engine binary (constraint `A-01`). Its architecture is in [vscode-architecture.md](vscode-architecture.md).

### Technology Architecture

| Component | Version / choice | Constraint |
|-----------|-----------------|------------|
| Language | Rust stable 1.78+ | — |
| Lua runtime | LuaJIT via mlua 0.9 (`lua54` CI fallback only) | `B-01` |
| Renderer | wgpu 22 — no OpenGL/Vulkan-direct/Metal-direct | `B-02` |
| Windowing | winit 0.30 | — |
| Physics | rapier2d 0.32 | — |
| Audio | rodio 0.17 | — |
| Font | fontdue 0.9 | — |
| Platform | Desktop only (Windows, Linux, macOS) | `A-02` |
| Graphics | 2D only | `A-03` |
| Platform SDKs | Not in core binary | `A-04` |

Performance target: 60 FPS at 1080p on integrated GPU.

---

## Architecture Repository

| Repository surface | TOGAF equivalent | Contents |
|--------------------|-----------------|----------|
| `docs/architecture/` | Architecture views and principles | Doctrine, domain views, governance contracts |
| `docs/specs/` | Information Systems Architecture detail | One spec per module: surface, invariants, error contracts |
| `.github/` | Architecture capability support system | Agents, skills, prompts, system prompt |
| `tools/validate/` + `tools/audit/` | Compliance and governance enforcement | Validators, coverage audits, link checks |
| `work/<session>/` | Migration planning and evidence | Plans, briefs, reports, session logs |
| `docs/CHANGELOG.md` | Change governance log | Every behavioural change recorded |

### Artifact Families

| Artifact family | Architecture role |
|----------------|-----------------|
| `docs/architecture/*.md` | Architecture principles, structural views, governance doctrine |
| `docs/specs/*.md` | Module-contract layer (application and data domains) |
| `.github/agents/*.agent.md` | Agent ownership (WHY layer) |
| `.github/skills/*/SKILL.md` | Domain knowledge and HOW-TO (HOW layer) |
| `.github/prompts/*.prompt.md` | Concrete step-by-step instructions (WHAT layer) |
| `.github/copilot-instructions.md` | Always-in-context binding constraint summary |
| `tools/validate/` | Principle enforcement and compliance checks |
| `work/<session>/` | Temporary migration and planning artefacts; archived after close |

---

## Governance

### Quality Gates (run before every commit)

```powershell
cargo test
cargo clippy -- -D warnings
python tools/validate/cag_validate.py
python tools/audit/cag_link_check.py --strict
```

All must exit 0. Zero warnings allowed.

### Change Control

| Change | Action required |
|--------|----------------|
| Any behavioural change | Entry in `docs/CHANGELOG.md` in the same commit |
| API change | Sync to `docs/specs/<module>.md`, regenerate docs via `python tools/gen_all_docs.py`, update affected examples and library modules |
| Constraint addition or removal | Update `.github/copilot-instructions.md` and `docs/architecture/philosophy.md` together |
| New module | Add `docs/specs/<module>.md` and update `docs/specs/README.md` |

### Architecture Review Checkpoints

Changes that affect module group boundaries (`T-01`), dependency direction (`T-02`), or any `A-*` or `B-*` scope constraint require an architecture decision recorded in the relevant spec or `philosophy.md`. Enforced via the CAG layer's quality sweep and agent ownership rules.

### Role Ownership

| Agent | Owns |
|-------|------|
| `architect` | Structural and module-boundary decisions |
| `cag-architect` | `.github/` and the CAG layer |
| `manager` | Routing and cross-agent coordination |
| `developer` | Rust engine code |

Cross-agent routing: [.github/agents/README.md](../../.github/agents/README.md).

---

## WHY / HOW / WHAT Layer Model

The CAG layer implements a three-layer information architecture (full spec in [cag-system.md § WHY / HOW / WHAT Layer Doctrine](cag-system.md#why--how--what-layer-doctrine)):

| Layer | File type | Question answered |
|-------|-----------|-----------------|
| **WHY** | Agent `.agent.md` | Why does this role exist? What is it responsible for? |
| **HOW** | Skill `SKILL.md` | How do you do the work? What domain knowledge applies? |
| **WHAT** | Prompt `.prompt.md` | What exact steps produce the outcome? |

No layer duplicates another's content. This enforces separation of concerns across the AI-support layer.

---

## Scope Boundaries

These TOGAF concepts have no direct Lurek2D equivalent and are intentionally out of scope:

- **Formal ADM phases** — architecture work uses work sessions and quality gates, not a named lifecycle method.
- **Enterprise stakeholder models** — the five personas cover the contributor and user surface.
- **Architecture metamodel / taxonomy** — artifact relationships are governed but not expressed in a named metamodel. The artifact family table above is the closest equivalent.
- **Formal TOGAF compliance** — the project is TOGAF-aware; not TOGAF-certified. No conformance statements are made.

Adding TOGAF-style artefacts for these areas is only justified when repeated architecture sessions expose a concrete gap that existing docs cannot fill.

---

## References

| File | Role |
|------|------|
| [philosophy.md](philosophy.md) | Binding constraints and architecture principles |
| [engine-architecture.md](engine-architecture.md) | Application architecture view |
| [cag-system.md](cag-system.md) | CAG layer architecture and governance |
| [test-framework.md](test-framework.md) | Test placement rules and quality gates |
| [vscode-architecture.md](vscode-architecture.md) | VS Code extension architecture |
| [plugins.md](plugins.md) | Plugin boundary and extension surface |
| [render-command-architecture.md](render-command-architecture.md) | Renderer architectural view |
| [docs/specs/README.md](../specs/README.md) | Module spec catalog |
| [docs/handbook.md](../handbook.md) | Contributor workflow |
| [.github/agents/README.md](../../.github/agents/README.md) | Agent routing and ownership |
