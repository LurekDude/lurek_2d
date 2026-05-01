---
name: solution-options
description: "Load this skill when solving a high-level problem needs 2 to 4 real options, trade-off checks, and one chosen path. Skip it for direct implementation, routine planning, or narrow bug fixing."
---
# solution-options

## Mission
- Own option-building, trade-off comparison, elimination, and final path selection for hard design problems.

## When To Load
- A high-level problem has more than one plausible solution.
- An architect must compare options before handing off implementation.
- Constraints, migration cost, or risk make a single-path answer unsafe.
- A human decision point is needed because the trade-off is real.

## When To Skip
- Direct implementation work.
- Routine planning where the target shape is already accepted.
- Narrow debugging where the next step is a local fix, not an option set.
- Review work that only checks an already chosen path.

## Domain Knowledge
- Start by naming the problem, the non-negotiable constraints, and the evidence already known; options built on a fuzzy problem usually collapse into wording variants.
- Build 2 to 4 options only; fewer often hides the trade-off, more usually dilutes the decision and adds fake symmetry.
- Each option should be structurally distinct, not the same plan with minor wording changes.
- Keep one conservative option and one higher-upside option when both are credible, because that exposes the real risk appetite of the choice.
- Eliminate options that break repo constraints early instead of carrying them through the whole comparison.
- Compare options against the same frame: correctness, architecture fit, migration cost, validation path, long-term maintenance, and user-facing impact when relevant.
- If one option depends on unknown facts, name the missing fact and decide whether it blocks selection or can be isolated as a follow-up check.
- Stop at a chosen path plus handoff shape; this skill is for decision quality, not for implementation detail.
- When the best option still needs a human call, surface the trade-off clearly and keep the decision point explicit.
- End with one selected option, why the others lost, the main residual risk, and the next owner.

## Companion File Index
- None.

## References
- .github/agents/architect.agent.md
- .github/agents/solver.agent.md
- .github/skills/module-architecture/SKILL.md
- .github/skills/enterprise-architecture/SKILL.md
