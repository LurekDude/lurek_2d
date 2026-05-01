---
description: "Create one Lua or game example that demonstrates a concrete lurek.* API, pattern, or gameplay concept."
agent: "Content-Maker"
---
# Create Example

## Goal
- Add one runnable example in `content/examples/` with clear, single-concept teaching value.

## Inputs
- Example name.
- What to teach: either `target=<API or pattern>` (API-focused) or `concept=<gameplay concept>` (gameplay-focused).
- Audience level.
- Required assets or setup.

## Steps
1. Load [skill: examples-management](../skills/examples-management/SKILL.md), [skill: lua-scripting](../skills/lua-scripting/SKILL.md), and [skill: documentation](../skills/documentation/SKILL.md) before acting.
2. Read `content/examples/`, nearby examples, the matching API docs or spec (`docs/specs/`), and any asset constraints before writing anything.
3. Choose scope: if `target=` was given, the example shows exactly one API call or pattern; if `concept=` was given, the example shows one gameplay mechanic using the minimum set of `lurek.*` systems it actually needs. One example, one teaching goal.
4. Use the real API exactly as shipped, keep the file small, and add only the README text needed for discovery and running. Do not scaffold toward a library or demo — use `/create-demo` for that.
5. Run `cargo test --test examples_load_test` and confirm any required registration or doc cross-links stay in sync.

## Success Criteria
- [ ] The example runs without errors via the examples load test.
- [ ] The example teaches exactly one API call, pattern, or gameplay concept.
- [ ] Required sync files (README, registration, cross-links) were updated.
- [ ] No generated artifacts were edited by hand.

## Anti-patterns
- Teaching two or more concepts in one example — split into two `/create-example` calls instead.
- Expanding a Lua example into a demo or mini-game — use `/create-demo` instead.
- Skipping the load test because the example looks correct visually.
- Editing `docs/api/lurek.lua` or other generated outputs by hand.

## Example Invocation
- /create-example name=timers target=timer.after
- /create-example name=camera_follow concept=smooth_follow_camera

## CAG Metadata
Mode: agent
Loads skills: examples-management, lua-scripting, documentation
Inputs required: Example name., What to teach (target= or concept=)., Audience level., Required assets or setup.
