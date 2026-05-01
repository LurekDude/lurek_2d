---
description: "Create a new playable game demo or test demo under content/games/."
---

# Create Demo

## Goal
- Create one working game demo with tests and harness registration.

## Inputs
- Demo name and purpose.
- Core mechanics to demonstrate.

## Steps
1. Load lua-scripting before acting.
2. Read content/games/ for existing demo patterns and content/examples/ for API references.
3. Create content/games/<name>/main.lua with clear init/process/render/input/teardown separation.
4. Create tests/lua/content/games/test_<name>.lua and add a smoke test.
5. Register in tests/lua/harness.rs as lua_demo_<name>.
6. Add a #[ignore] screenshot entry in tests/demo_smoke_tests.rs.
7. Run the demo under the harness to confirm it starts and runs without error.

## Success Criteria
- [ ] Demo runs without Lua errors.
- [ ] Test registered in harness.rs.
- [ ] Smoke test added to demo_smoke_tests.rs.
- [ ] No bare globals used.

## Example Invocation
- /create-demo name=asteroids mechanics=movement,shooting,score
