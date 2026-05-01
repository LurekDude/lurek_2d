---
description: "Analyze frame time, draw cost, or render-pipeline hotspots in one scenario."
agent: "Verifier"
---
# Analyze Render Performance

## Goal
- Locate the dominant render cost for one frame-time problem.

## Inputs
- Render scenario.
- Observed frame-time issue.
- Target backend path or effect.
- Any profiling output.

## Steps
1. Load [skill: performance-profiling](../skills/performance-profiling/SKILL.md) and [skill: gpu-programming](../skills/gpu-programming/SKILL.md) before acting.
2. Gather only the relevant source material from render traces, frame captures, GPU validation output, render code, and the scenario that reproduces the issue.
3. Break the cost down into passes, draw submission, resource updates, or synchronization so the main bottleneck is explicit.
4. Return the most likely controlling render path, any missing measurement, and the next narrow validation step.

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
- /analyze-render-performance scenario=particle_test symptom=frame_spike

## CAG Metadata
Mode: agent
Loads skills: performance-profiling, gpu-programming
Inputs required: Render scenario., Observed frame-time issue., Target backend path or effect., Any profiling output.
