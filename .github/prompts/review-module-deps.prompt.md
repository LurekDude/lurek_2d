---
description: "Review module dependencies for direction, ownership, and unnecessary coupling."
agent: "Architect"
---
# Review Module Deps

## Goal
- Assess whether module dependencies are still aligned with the intended architecture.

## Inputs
- Target module set.
- Dependency concern.
- Any desired boundary outcome.

## Steps
1. Load [skill: module-architecture](../skills/module-architecture/SKILL.md) before acting.
2. Read the named modules, their public edges, docs/specs, and any recent dependency changes.
3. Look for dependency inversion failures, utility creep, hidden cycles, and domain logic leaking through thin wrappers.
4. Return the clearest dependency risks, the clean boundary direction, and the smallest safe refactor path.

## Success Criteria
- [ ] Findings were listed first, or the prompt states clearly that no findings were found.
- [ ] Each finding is tied to a file, behavior, or missing proof.
- [ ] Missing validation or test coverage is called out.
- [ ] Residual risk or next owner is explicit.

## Anti-patterns
- Lead with summary instead of findings.
- Treat style nits as more important than behavior, safety, or contract drift.
- Declare the area clean without checking tests, validation, or missing proof.

## Example Invocation
- /review-module-deps modules=render,lua_api

## CAG Metadata
Mode: agent
Loads skills: module-architecture
Inputs required: Target module set., Dependency concern., Any desired boundary outcome.
