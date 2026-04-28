---
description: "Design a new lurek.* API surface."
---
# Design Api Surface

## Goal
- Design a clear new lurek.* API surface.

## Inputs
- api_goal: the user-facing capability to add.

## Steps
- Load lua-api-design, lua-scripting, and documentation.
- Read the nearest existing API patterns first.
- Draft examples early.
- Define names, params, returns, defaults, and callbacks.
- Note migration impact for breaking changes.
- Hand off implementation details to the next owner.

## Success Criteria
- [ ] The API shape is clear.
- [ ] Examples exist.
- [ ] Breaking-change impact is stated when relevant.

## Anti-patterns
- Copy another engine without checking repo patterns.
- Design the API with no example.
- Hide breaking changes.

## Example Invocation
- /design-api-surface api_goal

## CAG Metadata
- **Mode**: agent
- **Loads skills**: lua-api-design, lua-scripting, documentation
- **Inputs required**: api_goal
