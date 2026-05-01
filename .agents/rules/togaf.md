---
description: "Load when researching TOGAF, mapping repo architecture to TOGAF concepts, or writing TOGAF-aware gap analysis and governance notes. Skip for generic architecture work with no TOGAF angle."
alwaysApply: false
---

# togaf

## Mission
- Own TOGAF terminology, source handling, and repo-to-TOGAF comparison logic.

## When To Load
- Research TOGAF concepts: ADM, Fundamental Content, architecture domains, Enterprise Continuum, or governance.
- Compare Lurek2D docs, CAG artifacts, or validation rules to TOGAF concepts.
- Write TOGAF-aware architecture notes, gap analysis, or adoption cautions.
- Decide whether a TOGAF concept should stay an analysis lens or become a repo convention.

## When To Skip
- High-level architecture work that does not mention TOGAF.
- Module-boundary design or dependency fixes.
- Engine implementation, testing, or API naming.

## Domain Knowledge
- docs/architecture/togaf-research.md is the local source of truth for TOGAF work in this repo; treat it as an evidence-first research brief, not as a conformance claim.
- Start from TOGAF as a comparison lens, not a compliance target.
- Keep TOGAF axes separate: ADM lifecycle, four architecture domains, Enterprise Continuum, architecture repository, deliverables, and governance.
- TOGAF 10 public material emphasizes the split between Fundamental Content and Series Guides; for this repo, stable constraints usually map better to fundamentals.
- For Lurek2D, Business/Data/Application/Technology should be reinterpreted against a product-plus-tooling repository instead of copied literally from enterprise IT wording.
- Compare TOGAF repository and governance concepts against docs/, .agents/, tools/validate/, quality gates, and work/ artifacts before inventing new document types.
- Avoid checkbox gap analyses. If a TOGAF concept is too enterprise-heavy for this repo, say so directly.

## References
- docs/architecture/togaf-research.md
- docs/architecture/philosophy.md
- docs/architecture/cag-system.md
