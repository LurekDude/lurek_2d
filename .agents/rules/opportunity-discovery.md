---
description: "Load when mapping ideas, finding product or engine gaps, clustering opportunity signals, or ranking backlog candidates. Skip for implementation planning, code work, or API design."
alwaysApply: false
---

# opportunity-discovery

## Mission
- Own gap finding, idea clustering, and evidence-backed opportunity ranking.

## When To Load
- Review ideas/.
- Find feature or tooling gaps.
- Rank backlog candidates.
- Turn scattered notes into opportunity themes.

## When To Skip
- Implementation planning.
- Code changes.
- API design.

## Domain Knowledge
- ideas/ is the current discovery backlog surface and there is no formal docs/roadmap/ tree yet.
- Use repo evidence first: ideas/, logs/reports/, audit outputs, coverage gaps, docs drift, content friction, and repeated maintenance pain.
- Cluster repeated signals into one opportunity family instead of duplicating the same gap many times.
- Separate evidence-backed opportunities from speculative ideas and mark confidence explicitly.
- Rank by impact, leverage, confidence, dependency cost, and breadth of reuse, not novelty alone.
- Tie each opportunity to a real layer, module, tool, or content pain point in the repo.
- A roadmap-ready opportunity needs a clear problem statement, likely owner, affected area, and validation gate.
- Avoid locking into solutions too early.
- If three different notes all point to the same docs, tooling, or module boundary issue, summarize the shared opportunity.

## References
- ideas/
- logs/reports/
- tools/audit/
- docs/architecture/
- src/
