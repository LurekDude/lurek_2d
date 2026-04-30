---
name: enterprise-architecture
description: "Load this skill when writing, comparing, or governing high-level architecture across docs, artifacts, stakeholders, and validation rules. Skip it for module-level boundary fixes, engine implementation, or framework-specific TOGAF analysis."
---
# enterprise-architecture

## Mission
- Own high-level architecture doctrine, governance, artifact mapping, and cross-document structure above single-module design.

## When To Load
- Write or revise docs/architecture/ as system-level doctrine.
- Compare architecture principles, artifacts, and governance across repo surfaces.
- Decide where a rule belongs between docs/architecture, docs/specs, .github, tools/validate, and work/ artifacts.
- Map stakeholder, capability, repository, or lifecycle concerns without dropping straight into code structure.

## When To Skip
- Module boundaries, dependency direction, or crate layout.
- Engine implementation work.
- Pure TOGAF terminology or TOGAF gap analysis with no broader architecture decision.

## Domain Knowledge
- In this repo, architecture is not only src/ structure; the active architecture contract spans docs/architecture, docs/specs, .github, tools/validate, and the quality gates that keep them in sync.
- Keep principle, structure, governance, and workflow distinct. philosophy.md owns binding constraints, engine-architecture.md owns runtime structure, cag-system.md owns the CAG layer contract, and specs own per-module contracts.
- Use docs/architecture for stable design assumptions and repo-level doctrine, not for module-by-module API inventory or transient implementation detail.
- Treat .github plus validation tooling as part of the architecture repository for contributor behavior; do not reduce architecture review to Rust import graphs only.
- When a proposed architecture change touches validation, authorship, or artifact ownership, describe the effect on docs, agents, prompts, specs, and reports instead of only the code layout.
- Work artifacts under work/{session}/ are evidence and planning surfaces, not permanent doctrine; promote only settled rules into docs/architecture or .github contracts.
- External architecture frameworks should be mapped onto existing repo artifacts before inventing new deliverables or ceremony.
- Keep enterprise architecture framing lightweight for this repo: prefer precise mappings, constraints, and review gates over heavyweight organization-process cargo cults.

## Companion File Index
- None.

## References
- docs/architecture/philosophy.md
- docs/architecture/engine-architecture.md
- docs/architecture/cag-system.md
- docs/specs/README.md
- .github/copilot-instructions.md
