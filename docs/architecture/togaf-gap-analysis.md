# Lurek2D — TOGAF Gap Analysis

> Evaluates where current Lurek2D architecture already aligns with TOGAF-style concerns and where it does not.
> This file is intentionally scoped to documentation, governance, repository structure, and workflow artifacts.
> Companion docs: [togaf-research.md](togaf-research.md) · [togaf-mapping.md](togaf-mapping.md).

---

## Purpose

This document answers a different question than [togaf-mapping.md](togaf-mapping.md): not "what maps where", but "where is the current architecture already strong enough, and where would TOGAF-style work still expose gaps?"

The goal is to support later `Architect` and `CAG Architect` decisions without turning TOGAF into a checkbox program.

---

## Scope

This gap analysis covers:

- architecture principles and doctrine
- architecture repository structure
- governance and quality gates
- lifecycle and change-management surfaces
- stakeholder and capability framing

It does **not** score the engine implementation module by module, and it does **not** claim formal TOGAF adoption.

---

## Executive Summary

Lurek2D already has strong architecture discipline for a product repository. The strongest matches to TOGAF are:

- explicit principles and constraints
- a real architecture repository distributed across `docs/`, `.github/`, `tools/`, and `work/`
- strong implementation governance through validators, quality gates, and cross-artifact sync rules

The weakest areas are the ones TOGAF expects from an enterprise architecture practice rather than from a game engine repo:

- explicit stakeholder/capability architecture
- a named lifecycle method like ADM
- a formal deliverable/metamodel layer linking all architecture artifacts

That means the right next move is **lightweight TOGAF-aware structuring**, not enterprise process import.

---

## Scorecard

| Area | Current fit | Why |
| ---- | ----------- | --- |
| Principles and constraints | Strong | [philosophy.md](philosophy.md) already acts as binding architecture doctrine. |
| Runtime/application structure | Strong | [engine-architecture.md](engine-architecture.md) and [docs/specs/README.md](../specs/README.md) provide deep structural coverage. |
| Architecture repository | Strong | `docs/`, `.github/`, `tools/`, `work/`, and generated reports already form a reusable repository. |
| Implementation governance | Strong | validators, quality gates, changelog discipline, and review rules are concrete and enforceable. |
| Technology architecture | Strong | platform, stack, and build constraints are explicit and stable. |
| Business/stakeholder architecture | Partial | personas and onboarding exist, but capability/value-stream/stakeholder models are implicit. |
| Lifecycle method | Partial to weak | migration steps exist per document or session, but there is no unified architecture lifecycle. |
| Formal artifact metamodel | Weak | artifact relationships are real, but not expressed in one named metamodel or taxonomy. |

---

## What Already Aligns Well

### 1. Principle system

TOGAF assumes stable principles and design rules. Lurek2D already has this in unusually explicit form:

- Zen rules
- constraint IDs (`A-*`, `B-*`, `T-*`, `C-*`, `TST-*`, `Q-*`)
- source-of-truth architecture docs with clear ownership

This is one of the strongest existing matches.

### 2. Architecture repository shape

TOGAF expects a repository of reusable architecture assets, standards, and deliverables. Lurek2D already has a practical equivalent:

- `docs/architecture/` for doctrine and system views
- `docs/specs/` for module contracts
- `.github/` for AI/contributor governance
- `tools/validate/` and `tools/audit/` for enforcement
- `work/` for migration plans, briefs, evidence, and session logs

The main gap is naming/classification, not missing material.

### 3. Governance and enforcement

Many repos describe architecture but do not govern it. Lurek2D does both:

- `cargo test`
- `cargo clippy -- -D warnings`
- doc and coverage audits
- CAG validation
- cross-artifact sync rules
- changelog discipline

This is the best TOGAF-adjacent strength in the current repo.

### 4. Technology discipline

TOGAF expects technology choices to be explicit. Lurek2D already documents:

- desktop-only scope
- LuaJIT / Rust / wgpu / winit stack
- 2D-only rendering boundary
- plugin boundary direction
- build and test quality gates

This area does not need much new TOGAF-inspired structure.

---

## Main Gaps

### 1. Stakeholder and capability framing is implicit

The repo has personas and contributor workflows, but it does not yet maintain a stable architecture-level artifact that answers questions like:

- which stakeholder concerns are architecture-driving rather than operational
- which product capabilities are core versus optional
- which repo artifacts serve which stakeholder groups

Current closest substitutes:

- [handbook.md](../handbook.md) audience map
- [cag-system.md](cag-system.md) persona model
- [philosophy.md](philosophy.md) project identity and core idea

These are useful, but still distributed.

### 2. No explicit lifecycle method

Architecture work in Lurek2D is real, but it is not formalized as one lifecycle. Instead it is spread across:

- architecture docs
- work session plans
- changelog updates
- quality gates
- review and validation steps

That is workable, but it means TOGAF ADM can only be mapped loosely today.

### 3. No formal deliverable taxonomy or metamodel

The repo clearly distinguishes architecture docs, specs, prompts, skills, validators, and work artifacts, but it does not yet say in one place:

- what the canonical artifact classes are
- which relationships between them are normative
- which artifact types are temporary versus permanent

This is partly implicit in [cag-system.md](cag-system.md), [docs/specs/README.md](../specs/README.md), and the system prompt, but not yet unified outside the CAG slice.

### 4. Requirements live in several places

Lurek2D has real requirements material, but it is not centralized:

- constraint IDs in [philosophy.md](philosophy.md)
- per-module contract requirements in specs
- workflow requirements in handbook and CAG docs
- change-specific requirements in `work/<session>/`

That is enough for a product repo, but it does not resemble a formal TOGAF-style requirements repository.

### 5. Governance evidence is distributed

The repo records governance evidence well, but in several places:

- `docs/CHANGELOG.md`
- work session logs
- audit output
- validation output
- tests and coverage reports

That keeps the system lightweight, but makes cross-session architecture governance harder to scan as one narrative.

---

## Gaps That Should Stay Gaps

Some TOGAF features are not automatically good fits here.

### 1. Do not force enterprise jargon into game-facing docs

Game authors and engine contributors need clarity, not enterprise ceremony. Keep TOGAF vocabulary inside architecture comparison docs, skills, or specialist prompts unless a term solves a real communication problem.

### 2. Do not create new artifacts that duplicate existing ones

The repo already has narrative architecture docs, module specs, validators, handbook workflow, and CAG contracts. New TOGAF-inspired files are justified only when they connect these artifacts more clearly than the current system can.

### 3. Do not formalize ADM for routine work

Small code fixes, local refactors, or narrow documentation updates do not need a full architecture lifecycle. If ADM-style checkpoints ever arrive, they should apply only to broad structural rework or cross-artifact governance changes.

### 4. Do not claim compliance without explicit criteria

The current repo should remain TOGAF-aware, not TOGAF-certified or TOGAF-compliant.

---

## Recommended Small Migration Path

The safest path is incremental and document-first.

### Step 1. Keep the TOGAF source set small

Treat these three files as the current source set:

- [togaf-research.md](togaf-research.md)
- [togaf-mapping.md](togaf-mapping.md)
- [togaf-gap-analysis.md](togaf-gap-analysis.md)

Acceptance condition: later TOGAF-aware work references these files instead of re-deriving the comparison from scratch.

### Step 2. Add a lightweight stakeholder/capability crosswalk only if repeated need appears

Do not create it preemptively. Create it only if later architecture sessions keep needing the same missing lens for personas, capabilities, and repo ownership.

Candidate artifact if needed later:

- `docs/architecture/togaf-stakeholder-capability-map.md`

### Step 3. Standardize architecture session outputs before standardizing lifecycle phases

If recurring architecture work becomes hard to compare across sessions, standardize the output shape first:

- problem statement
- affected artifacts
- ownership decision
- migration path
- contract impact
- risks

Only after that should the repo consider naming any ADM-like checkpoints.

### Step 4. Use TOGAF mostly for review and comparison, not for repo-wide renaming

Practical uses that fit this repo now:

- architecture reviews
- mapping external framework questions to existing artifacts
- identifying missing governance or repository structure
- designing specialist prompts and skills for large architecture tasks

### Step 5. Reassess after one real TOGAF-guided architecture change

The right test is not another abstract document. The right test is one future architecture task that uses this mapping and gap analysis to drive a real structural decision.

---

## Risks If TOGAF Is Over-Applied

| Risk | Why it matters in Lurek2D |
| ---- | ------------------------- |
| Ceremony creep | The repo is optimized for fast, explicit, AI-readable decisions, not architecture bureaucracy. |
| Duplicate doctrine | New TOGAF docs could restate [philosophy.md](philosophy.md) and [engine-architecture.md](engine-architecture.md) instead of clarifying them. |
| Vocabulary drift | Enterprise terms can obscure concrete engine constraints when they replace existing repo language. |
| Governance overload | Too many checkpoints would slow routine contributor work without improving decision quality. |

---

## Acceptance Conditions For Future TOGAF Work

Future TOGAF-aware changes should satisfy all of these:

1. Every TOGAF term maps to a real Lurek2D artifact or is explicitly marked as "no direct match".
2. No new doc duplicates an existing source-of-truth document.
3. Any new governance step is justified by repeated failure, ambiguity, or review churn.
4. Game-facing and code-facing docs remain in the current repo vocabulary unless TOGAF wording is truly more precise.
5. No file claims formal TOGAF compliance unless the repo later adopts explicit compliance criteria.

---

## First Safe Next Slice

The first safe next slice is **not** a broad TOGAF rollout.

It is one narrow experiment:

- on the next major architecture task, require the author to cite [togaf-mapping.md](togaf-mapping.md) and [togaf-gap-analysis.md](togaf-gap-analysis.md) when the problem spans principles, governance, repository structure, or stakeholder framing.

If that experiment improves clarity, the repo can later decide whether a fourth TOGAF-specific document is justified.