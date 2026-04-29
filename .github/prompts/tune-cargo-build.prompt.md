---
description: "Tune Cargo build or profile settings for a concrete build goal."
agent: "Build-Engineer"
tools: [tools/dev/parallel_cargo.py]
---
# Tune Cargo Build

## Goal
- Improve one build path without breaking correctness or release expectations.

## Inputs
- Target build goal.
- Profile or command.
- Observed cost or failure.
- Platform.

## Steps
1. Load [skill: build-system](../skills/build-system/SKILL.md), [skill: cross-platform](../skills/cross-platform/SKILL.md), and [skill: quality-pipeline](../skills/quality-pipeline/SKILL.md) before acting.
2. Read the current Cargo profiles, build tasks, and the command that exhibits the problem before changing knobs.
3. Change only the settings tied to the named goal, such as debug speed, release size, or CI stability, and keep platform behavior explicit.
4. Measure or validate the targeted build path after the first change instead of stacking many speculative tweaks.
5. Close with the before or after effect, any tradeoff introduced, and the commands that now represent the tuned path.

## Success Criteria
- [ ] The workflow outcome is complete: Improve one build path without breaking correctness or release expectations.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /tune-cargo-build goal=debug_iteration profile=dev

## CAG Metadata
Mode: agent
Loads skills: build-system, cross-platform, quality-pipeline
Inputs required: Target build goal., Profile or command., Observed cost or failure., Platform.
