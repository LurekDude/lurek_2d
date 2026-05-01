---
name: togaf
description: "Load this skill when researching TOGAF, mapping repo architecture to TOGAF concepts, or writing TOGAF-aware gap analysis and governance notes. Skip it for generic architecture work with no TOGAF angle, module structure fixes, or engine implementation."
---
# togaf

## Mission
- Own TOGAF terminology, source handling, and repo-to-TOGAF comparison logic.

## When To Load
- Research TOGAF concepts such as ADM, Fundamental Content, Series Guides, architecture domains, Enterprise Continuum, repository, or governance.
- Compare Lurek2D docs, CAG artifacts, or validation rules to TOGAF concepts.
- Write TOGAF-aware architecture notes, gap analysis, or adoption cautions.
- Decide whether a TOGAF concept should stay an analysis lens or become a repo convention.

## When To Skip
- High-level architecture work that does not mention TOGAF or enterprise architecture frameworks.
- Module-boundary design or dependency fixes.
- Engine implementation, testing, or API naming.

## Domain Knowledge
- docs/architecture/togaf.md is the authoritative TOGAF alignment doc for this repo. Read it before any architecture comparison or TOGAF-aware task — it defines the four-domain mapping, artifact taxonomy, governance model, and scope boundaries. Never claim Lurek2D is TOGAF-compliant; the doc describes a TOGAF-aware architecture, not a certified one.
- **How to apply the ADM lens.** The Architecture Development Method is a lifecycle, not a checklist. When assessing Lurek2D, ask: where does the repo express architecture requirements (binding constraints in copilot-instructions.md), where does it capture architecture decisions (docs/architecture/philosophy.md), and where does it review and gate changes (	tttools/validate/cag_validate.py, cargo clippy, quality gates)? Those three points map loosely to ADM phases A (Architecture Vision), C/D (component architecture), and F/G (governance). Do not try to run every ADM phase literally; extract the structural comparison value.
- **How to map the four architecture domains.** For Lurek2D, translate B/D/A/T concretely: Business = contributor workflow, persona coverage (EngDev/GameDev/Modder/etc.), product adoption goals, and license constraints. Data = Lua/TOML/JSON serialized formats, lurek.serial, lurek.save, runtime state contracts, and generated docs schemas. Application = runtime subsystems (src/<module>/), Lua API surface (lurek.*), CAG agent layer, VS Code extension, and library modules. Technology = Rust 1.78+, LuaJIT via mlua 0.9, wgpu 22, winit 0.30, rapier2d 0.32, rodio 0.17, fontdue 0.9, and the CI toolchain. Use these translations when writing architecture views or gap analyses.
- **How to identify gaps using TOGAF.** Run the four-domain lens against the current docs inventory: does each domain have a governing spec (docs/architecture/philosophy.md covers Technology constraints well; Business stakeholder mapping is thin)? Does the architecture repository (docs/, .github/, 	ttools/validate/) contain viewpoints for all four domains? When a domain is poorly documented, that is the gap to surface, not a requirement to add TOGAF boilerplate.
- **How to use Enterprise Continuum.** Map architecture assets on the spectrum from generic (binding constraints like T-01, T-02, A-01 that any similar engine project might adopt) to specific (CAG agent routing tables, exact tool commands, persona matrix). Generic assets belong in docs/architecture/; specific assets belong in agent/skill files and specs. This helps decide where to document a new convention.
- **Architecture repository mapping.** Lurek2D already has a lightweight architecture repository. The mapping is: Architecture Principles = binding constraints in copilot-instructions.md. Architecture Decisions = docs/architecture/philosophy.md. Standards = quality gates and validator rules. Building blocks = module specs in docs/specs/ and CAG skills in .github/skills/. Solutions = content/games/ and library/ modules. When TOGAF asks for a repository artifact, look for an existing equivalent before proposing a new document.
- **Governance and change control.** TOGAF governance maps to the repo quality gates and CAG validator chain. Architecture compliance checking = python ttttools/validate/cag_validate.py + cargo clippy. Change requests = GitHub issues/PRs with label and milestone assignment. Architecture board = manager.agent.md + architect.agent.md routing. When assessing governance gaps, check whether the validator enforces the constraint or whether the constraint only exists as prose in a doc.
- Avoid checkbox gap analyses. If a TOGAF concept has no meaningful Lurek2D equivalent (e.g., procurement governance, organizational unit mapping), name the mismatch explicitly and scope the comparison note rather than forcing a mapping that adds no insight.
## Companion File Index
- None.

## References
- docs/architecture/togaf.md
- docs/architecture/philosophy.md
- docs/architecture/cag-system.md
- .github/agents/aarchitect.agent.md
- .github/agents/cag-aarchitect.agent.md
