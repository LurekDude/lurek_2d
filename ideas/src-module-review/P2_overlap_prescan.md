# P2 Overlap Pre-scan

Owner: architect

Done When:
- Boundary decisions are documented for all high-risk overlaps.
- Each overlap has one owner module and one integration path.
- Follow-up implementation tickets are created with acceptance gates.

Inputs:
- docs/specs/*.md (affected modules)
- src/<module>/* for overlap pairs

Produces:
- work/<session>/reports/p2_overlap_contract.md

Execution Steps:
1. Lock boundary for tween vs animation.
2. Lock ownership stack for data, serial, save, network serialization usage.
3. Decide strategy for math vs procgen RNG/noise overlap:
	- shared implementation
	- or explicit separate ownership with reason
4. Lock pipeline vs graph boundary for DAG/data-structure responsibilities.
5. Lock scene vs ecs boundary for lifecycle and orchestration.
6. Define filesystem ownership policy to remove repeated direct fs logic.
7. For each decision, define implementation phase and owner.

Out of Scope:
- Code refactor in this phase.
- New feature additions.
