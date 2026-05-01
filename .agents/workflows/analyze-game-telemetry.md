---
description: "Analyze game telemetry, SQL results, or DataFrame outputs for balance or KPI questions."
---

# Analyze Game Telemetry

## Goal
- Produce evidence-backed telemetry findings for a concrete game question.

## Inputs
- Telemetry source or report path.
- Question or metric target.
- Relevant cohort, segment, or time window.
- Balance or KPI concern.

## Steps
1. Load analytics before acting.
2. Gather only the relevant source material from logs/, logs/data/, SQL exports, DataFrame outputs, and any linked balance notes.
3. Compute the key metrics, trends, and outliers for the named question, then separate measured facts from interpretation.
4. Tie each result to likely game balance, economy, or content implications and note what extra data would change the conclusion.

## Success Criteria
- [ ] The data or source scope is explicit.
- [ ] Findings are evidence-backed and quantified where possible.
- [ ] Assumptions and open questions are separated from facts.
- [ ] A next owner or next validation step is clear.

## Anti-patterns
- Give generic advice with no repo evidence or measured signal.
- Mix facts, guesses, and recommendations into one vague paragraph.
- Jump to implementation before identifying the owner.

## Example Invocation
- /analyze-game-telemetry source=logs/data/session.csv metric=retention
