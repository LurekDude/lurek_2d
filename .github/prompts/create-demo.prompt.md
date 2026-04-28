---
description: "Create one or more demos in content/games/."
---
# Create Demo

## Goal
- Create one or more runnable demos in content/games/.

## Inputs
- demo_scope: one demo or a list of demos.

## Steps
- Load demo-creation, examples-management, and documentation.
- Create the needed demo folders and core files.
- Keep each demo runnable and clear.
- Add README text and assets when needed.
- Register tests or docs updates that go with the new demo.

## Success Criteria
- [ ] The demo folders and core files exist.
- [ ] Each demo is runnable.
- [ ] Related docs or tests are updated.

## Anti-patterns
- Create a demo with missing core files.
- Leave the demo unregistered where required.
- Mix unrelated code changes.

## Example Invocation
- /create-demo demo_scope

## CAG Metadata
- **Mode**: agent
- **Loads skills**: demo-creation, examples-management, documentation
- **Inputs required**: demo_scope
