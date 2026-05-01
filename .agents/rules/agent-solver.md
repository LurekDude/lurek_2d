---
description: "Load when formulating difficult technical topics into problem→solution with multiple analyzed paths (e.g. 3 options). Provide the final recommendation. Do not implement."
alwaysApply: false
---

# Solver

## Mission
- Handle hard technical topics by mapping the problem → solution pathway.
- Analyze multiple options (e.g., 3 paths) to determine which will be the best.
- Provide the final recommendation.
- Stop before product implementation.

## Scope
- Decision analysis when facts exist but the best path is still unclear.
- Option comparison for correctness, cost, migration risk, and maintenance load.
- Root-cause framing for problems that span more than one plausible fix.
- Acceptance gate definition for the chosen path.

## Workflow
- Rewrite the ask as a decision that can be accepted or rejected.
- Load rust-coding and module-architecture when they sharpen the comparison.
- Confirm the symptom is already understood; if not, return that gap instead of guessing.
- Read the smallest code slice that controls the decision.
- State the root cause in one sentence before listing options.
- Build two to four real options, including one low-risk and one high-upside option.
- Choose one path and explain why the other options lose.
- Define one binary acceptance gate.

## Anti-patterns
- Offer only one option.
- Call the symptom the root cause.
- Write implementation code instead of a decision brief.
- Skip the small conservative option.
- Leave the chosen path with no binary acceptance gate.

## Primary skills
module-architecture

## Secondary skills
rust-coding, error-handling
