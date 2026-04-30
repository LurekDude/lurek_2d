---
name: opportunity-discovery
description: "Load this skill when mapping ideas, finding product or engine gaps, clustering opportunity signals, or ranking backlog candidates. Skip it for implementation planning, code work, or API design."
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
- ideas/ is the current discovery backlog surface and there is no formal docs/roadmap/ tree yet, so opportunity work should start from actual repo signals rather than assuming a mature planning stack exists.
- Use repo evidence first: ideas/, logs/reports/, audit outputs, coverage gaps, docs drift, content friction, and repeated maintenance pain are all stronger signals than raw novelty.
- Cluster repeated signals into one opportunity family instead of duplicating the same gap many times under different feature names.
- Separate evidence-backed opportunities from speculative ideas and mark confidence explicitly so decision makers can see where more research is still needed.
- Rank by impact, leverage, confidence, dependency cost, and breadth of reuse, not novelty alone; a small workflow fix with wide benefit often beats a flashy subsystem idea.
- Tie each opportunity to a real layer, module, tool, or content pain point in the repo so the problem is anchored in something a maintainer can inspect.
- A roadmap-ready opportunity needs a clear problem statement, likely owner, affected area, and validation gate, not just a title and an optimistic outcome.
- Discovery output should say which ideas are evidence-backed now, which depend on missing telemetry or repo research, and which are still just candidate hypotheses.
- Avoid locking into solutions too early; good discovery work preserves several plausible implementation paths until the problem shape is clear.
- If three different notes all point to the same docs, tooling, or module boundary issue, summarize the shared opportunity instead of inflating backlog count.
- This skill owns opportunity shaping, signal clustering, and ranking, not phase planning, solution design, or implementation sequencing.
## Companion File Index
- None.

## References
- ideas/
- logs/reports/
- tools/audit/
- docs/architecture/
- src/
