---
description: "Analyze physics step cost, collision pressure, or world-update slowdowns."
agent: "Verifier"
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
1. Load [skill: performance-profiling](../skills/performance-profiling/SKILL.md) before acting.
2. Gather only the relevant source material from physics traces, tests, demo content, and the owning src/physics code path.
3. Quantify broad-phase, narrow-phase, stepping, or data conversion cost as far as the available evidence allows.
4. State the likely hotspot, the confidence level, and which owner should validate or change it next.

## Success Criteria
- [ ] The data or source scope is explicit.
- [ ] Findings are evidence-backed and quantified where possible.
- [ ] Assumptions and open questions are separated from facts.
- [ ] A next owner or next validation step is clear.

## Anti-patterns
- Give generic advice with no repo evidence or measured signal.
- Mix facts, guesses, and recommendations into one vague paragraph.
- Jump to implementation before identifying the owner and the evidence strength.

## Example Invocation
- /analyze-physics-performance scenario=stacked_crates symptom=low_fps

## CAG Metadata
Mode: agent
Loads skills: performance-profiling
Inputs required: Physics scenario., Observed slowdown., Relevant test or demo., Any timing capture.
