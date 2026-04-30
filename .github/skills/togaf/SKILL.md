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
- docs/architecture/togaf-research.md is the local source of truth for TOGAF work in this repo; treat it as an evidence-first research brief, not as a conformance claim.
- Start from TOGAF as a comparison lens, not a compliance target. The default question is how a concept maps to current repo artifacts, not how to force the repo into TOGAF ceremony.
- Keep TOGAF axes separate: ADM lifecycle, four architecture domains, Enterprise Continuum, architecture repository, deliverables, and governance answer different questions and should not be collapsed into one generic “framework” bucket.
- TOGAF 10 public material emphasizes the split between Fundamental Content and Series Guides; for this repo, stable constraints usually map better to fundamentals, while templates, workflows, and skill guidance map better to contextual guidance.
- For Lurek2D, Business/Data/Application/Technology should be reinterpreted against a product-plus-tooling repository instead of copied literally from enterprise IT wording.
- Compare TOGAF repository and governance concepts against docs/, .github/, tools/validate/, quality gates, and work/ artifacts before inventing new document types.
- Public TOGAF sources in this environment are incomplete; prefer official public Open Group pages first and explicitly mark when a claim depends on secondary summaries because library pages were access-controlled.
- Avoid checkbox gap analyses. If a TOGAF concept is too enterprise-heavy for this repo, say so directly and keep the output as a scoped comparison note.

## Companion File Index
- None.

## References
- docs/architecture/togaf-research.md
- docs/architecture/philosophy.md
- docs/architecture/cag-system.md
- .github/agents/architect.agent.md
- .github/agents/cag-architect.agent.md
