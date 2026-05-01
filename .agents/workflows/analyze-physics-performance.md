---
description: "Analyze physics step cost, collision pressure, or world-update slowdowns."
---

# Analyze Physics Performance

## Goal
- Identify the main source of physics cost in one scenario.

## Inputs
- Physics scenario.
- Observed slowdown.
- Relevant test or demo.
- Any timing capture.

## Steps
1. Load performance-profiling before acting.
2. Gather relevant source material from physics traces, tests, demo content, and the owning src/physics code path.
3. Quantify broad-phase, narrow-phase, stepping, or data conversion cost as far as the available evidence allows.
4. State the likely hotspot, the confidence level, and which owner should validate or change it next.

## Success Criteria
- [ ] The data or source scope is explicit.
- [ ] Findings are evidence-backed and quantified where possible.
- [ ] Assumptions and open questions are separated from facts.
- [ ] A next owner or next validation step is clear.

## Example Invocation
- /analyze-physics-performance scenario=stacked_crates symptom=low_fps
