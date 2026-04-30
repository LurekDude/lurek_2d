# Lurek2D — TOGAF Mapping

> Maps TOGAF concepts onto the architecture artifacts that already exist in Lurek2D.
> This file is a crosswalk, not a conformance claim.
> Companion docs: [togaf-research.md](togaf-research.md) (source limits and terminology) · [togaf-gap-analysis.md](togaf-gap-analysis.md) (fit, gaps, and next steps).

---

## Purpose

This document answers one narrow question: if someone uses TOGAF as an analysis lens, where do those concepts land in the current Lurek2D repository?

The goal is not to rename the repo around TOGAF. The goal is to make later architecture work precise:

- which TOGAF concepts already have a clear Lurek2D analogue
- which concepts only partially map
- which concepts should stay external vocabulary rather than become repo doctrine

---

## How To Read This Map

- `Closest analogue` means the nearest real Lurek2D artifact, not a promise of formal TOGAF compliance.
- `Strong` means the repo already has a stable, named artifact or rule set that serves roughly the same purpose.
- `Partial` means the repo has the material, but it is distributed, informal, or missing a standard frame.
- `No direct match` means the concept should remain external vocabulary unless later work proves that a new artifact is needed.

When this map conflicts with a source-of-truth architecture doc, the source-of-truth doc wins.

---

## Mapping Summary

Lurek2D already has strong equivalents for three TOGAF concerns:

- stable architecture principles and constraints
- architecture repository structure
- implementation governance and quality gates

Lurek2D is materially weaker in the areas where TOGAF assumes an enterprise practice rather than a product repo:

- explicit stakeholder and capability architecture
- a formal lifecycle method like ADM
- a named metamodel for architecture deliverables and relationships

That means TOGAF is most useful here as a **comparison language for docs, governance, and repository structure**, not as a process template to copy directly.

---

## TOGAF 10 Structure Crosswalk

The public TOGAF 10 material separates `Fundamental Content` from `Series Guides`. Lurek2D already has a similar split in practice, even though it does not use TOGAF names.

| TOGAF concept | Closest Lurek2D analogue | Status | Notes |
| ------------- | ------------------------ | ------ | ----- |
| `Fundamental Content` | [philosophy.md](philosophy.md), [engine-architecture.md](engine-architecture.md), [test-framework.md](test-framework.md), [cag-system.md](cag-system.md) | Strong | These files define stable principles, structure, and governance contracts. |
| `Series Guides` | [handbook.md](../handbook.md), skills under `/.github/skills/`, prompts under `/.github/prompts/`, authoring templates under [templates/](templates/) | Strong | These are context-specific operating guides rather than first-principles doctrine. |
| Stable core versus configurable practice | Constraint IDs in [philosophy.md](philosophy.md) versus workflow-specific guidance in handbook/CAG docs | Strong | This split already exists and should stay explicit. |

Interpretation rule: TOGAF fundamentals map best to binding architecture docs, while guide-like TOGAF material maps best to handbook, CAG skills, prompts, and templates.

---

## Four Architecture Domains

TOGAF's four-domain model does not map literally to an engine repository, but it does provide a useful decomposition lens.

| TOGAF domain | Lurek2D equivalent | Closest source-of-truth artifacts | Status |
| ------------ | ------------------ | --------------------------------- | ------ |
| `Business Architecture` | Product identity, contributor workflow, persona coverage, and value proposition | [philosophy.md](philosophy.md) (`Core Idea`, `Project Identity`), [handbook.md](../handbook.md), [cag-system.md](cag-system.md#4-six-persona-model) | Partial |
| `Data Architecture` | Config formats, serialization rules, save/load boundaries, generated-doc data, and spec metadata | [philosophy.md](philosophy.md) (`B-05`, `Zen Rule 10`), [engine-architecture.md](engine-architecture.md) (`State Architecture`, `Configuration System`, `Filesystem`), [docs/specs/README.md](../specs/README.md) | Partial |
| `Application Architecture` | Runtime subsystem structure, Lua binding surface, extension architecture, and CAG support layer | [engine-architecture.md](engine-architecture.md), [vscode-architecture.md](vscode-architecture.md), [cag-system.md](cag-system.md) | Strong |
| `Technology Architecture` | Rust/LuaJIT/wgpu stack, desktop-only constraints, build and validation tooling | [philosophy.md](philosophy.md) (`A-*`, `B-*` constraints), [handbook.md](../handbook.md), [tools/README.md](../../tools/README.md) | Strong |

Interpretation rule: `Business Architecture` is the weakest direct fit because Lurek2D is a product-plus-tooling repo, not an enterprise operating model. Treat personas, contributor workflow, and product constraints as the closest valid substitute.

---

## ADM Crosswalk

Lurek2D does not implement TOGAF ADM as a named lifecycle. The closest analogue is a distributed architecture workflow spread across docs, work artifacts, quality gates, and review rules.

| ADM area | Closest Lurek2D equivalent | Status | Notes |
| -------- | -------------------------- | ------ | ----- |
| `Preliminary` | [philosophy.md](philosophy.md), [cag-system.md](cag-system.md), [.github/copilot-instructions.md](../../.github/copilot-instructions.md) | Strong | Core constraints, operating doctrine, and discovery rules already exist. |
| `Architecture Vision` | [philosophy.md](philosophy.md) (`Core Idea`, `Project Identity`), [README.md](../../README.md), [handbook.md](../handbook.md) | Partial | Vision exists, but not as one named architecture-vision artifact. |
| `Business Architecture` | Contributor/persona framing in [handbook.md](../handbook.md) and [cag-system.md](cag-system.md) | Partial | Good persona coverage, weak explicit stakeholder/capability modeling. |
| `Information Systems Architecture` | [engine-architecture.md](engine-architecture.md), [docs/specs/README.md](../specs/README.md), module specs | Strong | Runtime structure and module contracts are already documented in depth. |
| `Technology Architecture` | [philosophy.md](philosophy.md), [handbook.md](../handbook.md), build/test tasks, `tools/` | Strong | Technology choices and quality gates are explicit and binding. |
| `Opportunities and Solutions` | [plugins.md](plugins.md), `work/<session>/` plans, architecture proposals | Partial | The repo has proposal surfaces, but no standard TOGAF-style solution catalog. |
| `Migration Planning` | `work/<session>/` plans, ordered migration notes in architecture docs, [docs/CHANGELOG.md](../CHANGELOG.md) | Partial | Migration exists, but is session-driven rather than phase-driven. |
| `Implementation Governance` | quality gates, validators, reviewer checks, cross-artifact sync table | Strong | This is one of the best existing matches. |
| `Architecture Change Management` | changelog discipline, design-assumption updates, docs/spec sync, CAG sweep rules | Partial | Strong control exists, but not under one named architecture change process. |
| `Requirements Management` | constraint IDs, specs, issue/work artifacts, source-of-truth docs | Partial | Requirements exist, but there is no single formal requirements repository. |

Interpretation rule: future TOGAF-aware work should not invent an ADM clone unless repeated architecture sessions prove a real need for explicit phase gates.

---

## Architecture Repository Crosswalk

TOGAF assumes an architecture repository holding reusable assets, standards, deliverables, and governance material. Lurek2D already has a strong lightweight equivalent.

| TOGAF repository concern | Closest Lurek2D surface | Status | Notes |
| ------------------------ | ----------------------- | ------ | ----- |
| Architecture repository | `docs/`, `.github/`, `tools/validate/`, `tools/audit/`, `work/`, `logs/reports/` | Strong | The repository is distributed, but structurally real. |
| Architecture views | [engine-architecture.md](engine-architecture.md), [render-command-architecture.md](render-command-architecture.md), [vscode-architecture.md](vscode-architecture.md), [test-framework.md](test-framework.md) | Strong | Each view focuses on one architectural slice. |
| Standards information base | [philosophy.md](philosophy.md), [.github/copilot-instructions.md](../../.github/copilot-instructions.md), validator rules | Strong | Binding constraints and quality gates already fill this role. |
| Reference library | [templates/](templates/), handbook, skills, prompts, examples, module specs | Strong | These are reusable guidance assets. |
| Governance log / evidence | [docs/CHANGELOG.md](../CHANGELOG.md), `work/<session>/logs/agent_log.jsonl`, validation output | Partial | Evidence exists, but governance logs are split across several surfaces. |
| Architecture continuum | constraint docs, templates, shared patterns, module-group model | Partial | Reusable architectural assets exist, but are not named or classified as a continuum. |
| Solutions continuum | `src/`, `extensions/vscode/`, `content/`, `library/`, distribution scripts | Partial | Concrete solutions exist, but no formal continuum taxonomy is used. |
| Formal metamodel | No direct single artifact | No direct match | Specs and docs imply relationships, but the repo has no explicit architecture metamodel. |

Interpretation rule: the repo already behaves like an architecture repository. The main missing piece is explicit classification, not raw documentation volume.

---

## Governance Crosswalk

Lurek2D is unusually strong on governance for a product repository. The controls are lightweight, but real.

| TOGAF governance concern | Lurek2D equivalent | Status |
| ------------------------ | ------------------ | ------ |
| Architecture principles | Constraint IDs and Zen rules in [philosophy.md](philosophy.md) | Strong |
| Role and ownership definition | agent scopes, docs ownership, cross-artifact sync rules | Strong |
| Standards compliance | `cargo test`, `cargo clippy -- -D warnings`, doc/coverage audits, CAG validation | Strong |
| Change control | [docs/CHANGELOG.md](../CHANGELOG.md), work session artifacts, PR discipline in [CONTRIBUTING.md](../../CONTRIBUTING.md) | Partial |
| Exception handling | explicit rule-amendment model in [philosophy.md](philosophy.md) | Strong |
| Architecture review checkpoints | reviewer flow, architecture docs, quality gates, CAG sweep | Partial |

Interpretation rule: if future TOGAF work needs a strong anchor, governance is the right one. The repo already has enforceable controls without importing enterprise-heavy ceremony.

---

## Lurek2D Artifact Families In TOGAF Terms

The most stable crosswalk for future work is this artifact family map:

| Lurek2D artifact family | TOGAF-like role |
| ----------------------- | --------------- |
| `docs/architecture/*.md` | architecture principles, structure views, governance doctrine |
| `docs/specs/*.md` | architecture and solution detail at module-contract level |
| `/.github/` | architecture capability support, guidance system, role workflow, validation contract |
| `tools/validate/` and `tools/audit/` | governance enforcement and compliance checks |
| `work/<session>/` | migration planning, evidence, session architecture notes |
| `content/`, `library/`, `extensions/vscode/`, `src/` | realized solution assets |

This is the safest base for later TOGAF-oriented prompts, skills, or review checklists.

---

## What This Map Does Not Claim

- It does not claim that Lurek2D is TOGAF-compliant.
- It does not claim one-to-one terminology matches.
- It does not justify adding enterprise process overhead by default.
- It does not replace the source-of-truth architecture docs already in this repo.

Use this file only to translate TOGAF vocabulary into current Lurek2D artifacts with the least possible distortion.