---
description: "Review entity lifecycle patterns for correctness: spawn, alive check, kill, ID recycling, blueprint usage, and layer organization. Use wh..."
agent: Reviewer
---
# Review Entity Lifecycle

## Goal

Review entity lifecycle patterns for correctness: spawn, alive check, kill, ID recycling, blueprint usage, and layer organization. Use wh... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- (none) — this prompt takes no required arguments.

## Steps

1. **Check ID management**
2. IDs are sequential on first spawn (1, 2, 3, ...)
3. Killed IDs recycle in LIFO order (last killed = first reused)
4. Verify `is_alive()` check before entity access
5. Confirm no stale ID references after kill
6. **Check lifecycle ordering**
7. Entities spawned during `lurek.update()` only — never during `lurek.draw()`
8. Entities killed during `lurek.update()` only — never during `lurek.draw()`
9. Blueprint application happens at spawn time
10. **Check tag/layer usage**
11. Bitmap tags for fast group membership queries
12. Layers for spatial/functional entity grouping

## Success Criteria

- [ ] No stale ID references in game logic
- [ ] All mutations happen in `lurek.update()`, not `lurek.draw()`
- [ ] ID recycling follows LIFO order
- [ ] Blueprint patterns are copy-on-spawn
- [ ] Tests cover the full lifecycle

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/review-entity-lifecycle`

## CAG Metadata

- **Mode**: agent
