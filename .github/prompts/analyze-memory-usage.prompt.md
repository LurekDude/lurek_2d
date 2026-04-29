---
description: "Analyze memory growth, allocation churn, or resource lifetime issues in the engine."
agent: "Optimizer"
---
# Analyze Memory Usage

## Goal
- Identify where memory cost is coming from and which owner should act next.

## Inputs
- Repro scenario or command.
- Target subsystem.
- Observed memory symptom.
- Any profiler or log output.

## Steps
1. Load [skill: performance-profiling](../skills/performance-profiling/SKILL.md) and [skill: gpu-programming](../skills/gpu-programming/SKILL.md) before acting.
2. Gather only the relevant source material from profiler output, logs, resource lifetime code, cache paths, texture paths, and the narrow code slice for the symptom.
3. Quantify memory growth, long-lived allocations, or churn sources and distinguish CPU ownership from GPU ownership.
4. Explain the most likely controlling path, the confidence level, and the narrowest next validation or implementation step.

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
- /analyze-memory-usage subsystem=render symptom=steady_growth scenario=demo_smoke

## CAG Metadata
Mode: agent
Loads skills: performance-profiling, gpu-programming
Inputs required: Repro scenario or command., Target subsystem., Observed memory symptom., Any profiler or log output.
