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
- Where to find signals in this repo: `ideas/` is the primary discovery backlog — scan all subdirectories (`ideas/rust/`, `ideas/extension/`, `ideas/plugins/`, `ideas/simulation/`, `ideas/tests/`). Secondary signals: `logs/quality/` for repeated lint or test failures, `tools/audit/` outputs for coverage gaps, `docs/specs/` TODO sections, and any spec file that has not been touched in many commits (drift signal).
- How to cluster signals: group by affected layer (Foundations, Core Runtime, Platform Services, Feature Systems, Edge/Integration). Within a layer, group by pain type: missing capability, fragile boundary, documentation gap, test gap, or tooling gap. One cluster = one opportunity card. Avoid naming the solution in the opportunity title — keep it as a problem statement.
- How to write an opportunity card: title (problem statement, not solution), evidence list (file paths, audit results, or issue references), affected layer and module, estimated author impact (which personas: EngDev, GameDev, Modder, GameTest, EngTest), confidence level (low/medium/high), and next validation action (what to run or read to confirm the gap). No opportunity is complete without a validation action.
- Ranking formula: score each opportunity on (impact × leverage × confidence) / dependency cost. Impact = how many personas are affected. Leverage = how many future tasks unblock. Confidence = strength of evidence (audit output = high, single idea note = low). Dependency cost = how many other changes must land first.
- How to distinguish an opportunity from a task: an opportunity is a problem shape that could be solved multiple ways. A task is a specific solution already chosen. Discovery ends when you have a ranked, anchored opportunity list — it hands off to `planner` (for task breakdown) or `architect` (for solution design). Do not merge phases.
- Freshness check: before generating new opportunities, run `python tools/audit/test_coverage.py` and `python tools/audit/doc_coverage.py`. These produce the most up-to-date gap data. Discovery from stale notes without checking current audit output often produces already-resolved opportunities.
- Output shape: a ranked list where each entry has: rank, problem title, evidence, affected area, personas, confidence, validation action, and suggested next owner. Deliver as a `work/<session>/reports/opportunities.md` file, not as inline chat prose, so the planner can act on it.
## Companion File Index
- None.

## References
- ideas/
- logs/reports/
- tools/audit/
- docs/architecture/
- src/
