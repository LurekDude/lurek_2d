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
- docs/architecture/togaf.md is the authoritative TOGAF alignment doc for this repo; it defines the four-domain mapping, artifact taxonomy, governance model, and scope boundaries. Read it first.
- Start from TOGAF as a comparison lens, not a compliance target. Lurek2D is TOGAF-aware, not TOGAF-certified.
- Keep TOGAF axes separate: four architecture domains, architecture repository, governance, and scope boundaries.
- For Lurek2D, Business/Data/Application/Technology should be reinterpreted against a product-plus-tooling repository — see §2 of togaf.md for the established mappings.
- Compare TOGAF repository and governance concepts against docs/, .agents/, tools/validate/, quality gates, and work/ artifacts before inventing new document types.
- Avoid checkbox gap analyses. If a TOGAF concept is too enterprise-heavy for this repo, name the mismatch explicitly and move on.

## References
- docs/architecture/togaf.md
- docs/architecture/philosophy.md
- docs/architecture/cag-system.md
