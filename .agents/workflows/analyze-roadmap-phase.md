---
description: "Analyze one roadmap phase for readiness, gaps, and evidence strength."
---

# Analyze Roadmap Phase

## Goal
- Return a short phase audit that separates ready work from weakly supported work.

## Inputs
- Phase file or note path.
- Target persona or audience.
- Decision horizon.
- Known blockers or open questions.

## Steps
1. Load opportunity-discovery, roadmap-planning, and documentation before acting.
2. Gather only the relevant source material from the named roadmap or ideas artifact, linked docs, and related gaps.
3. Check whether the phase has a clear problem, why-now, dependencies, acceptance gate, and evidence strong enough to justify planning.
4. State what is ready, what is speculative, and the smallest next action to improve the phase.

## Success Criteria
- [ ] The data or source scope is explicit.
- [ ] Findings are evidence-backed.
- [ ] Assumptions and open questions are separated from facts.
- [ ] A next owner or next validation step is clear.

## Example Invocation
- /analyze-roadmap-phase path=ideas/render-phase.md
