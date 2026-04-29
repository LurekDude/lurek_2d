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
- ideas/ is the current discovery backlog surface; there is no formal docs/roadmap/ tree yet.
- Use repo evidence first: ideas/, logs/reports/, audit outputs, coverage gaps, docs drift, and content pain points.
- Cluster repeated signals into one opportunity family instead of duplicating the same gap many times.
- Separate evidence-backed opportunities from speculative ideas and mark confidence explicitly.
- Rank by impact, leverage, confidence, and dependency cost, not novelty alone.
- A roadmap-ready opportunity needs a clear problem, likely owner, and validation gate, not just a feature name.
- The best raw inputs today are ideas/, audit reports, coverage gaps, docs drift, and user-facing friction in content and tooling, not a formal roadmap tree.
- Discovery output should say which ideas are evidence-backed now and which still need telemetry or repo research.
- The skill owns opportunity shaping and gap clustering, not phase planning or solution implementation.
## Companion File Index
- None.

## References
- ideas/
- logs/reports/
- tools/audit/
- docs/architecture/
- src/
