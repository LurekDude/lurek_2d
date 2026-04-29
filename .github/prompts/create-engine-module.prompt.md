---
description: "Create one new engine module with the required Rust, spec, and test structure."
agent: "Developer"
---
# Create Engine Module

## Goal
- Add one new engine module that matches repo structure rules.

## Inputs
- Module name.
- Responsibility.
- Public surface.
- Required tests or docs.

## Steps
1. Load [skill: module-architecture](../skills/module-architecture/SKILL.md), [skill: rust-coding](../skills/rust-coding/SKILL.md), and [skill: testing-rust](../skills/testing-rust/SKILL.md) before acting.
2. Read src/, docs/specs/, docs/specs/README.md, nearby module layouts, and the testing rules before editing.
3. Follow the mod.rs thin-file rule, place business logic in sibling files, add the matching spec, and keep dependencies pointed inward.
4. Run the narrowest build or test check that exercises the new module, then update required docs and changelog entries.

## Success Criteria
- [ ] The prompt goal was completed: Add one new engine module that matches repo structure rules.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-engine-module module=weather responsibility=2d_weather_state

## CAG Metadata
Mode: agent
Loads skills: module-architecture, rust-coding, testing-rust
Inputs required: Module name., Responsibility., Public surface., Required tests or docs.
