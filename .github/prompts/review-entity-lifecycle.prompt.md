---
description: "Review entity lifecycle patterns."
---

# Review Entity Lifecycle

## Goal
- Review entity lifecycle patterns for correctness: spawn, alive check, kill, ID recycling, blueprint usage, and layer organization. Use wh...

## Inputs
- None.

## Steps
- **Check ID management**
- IDs are sequential on first spawn (1, 2, 3, ...)
- Killed IDs recycle in LIFO order (last killed = first reused)
- Verify is_alive() check before entity access
- Confirm no stale ID references after kill
- **Check lifecycle ordering**
- Entities spawned during lurek.update() only never during lurek.draw()
- Entities killed during lurek.update() only never during lurek.draw()
- Blueprint application happens at spawn time
- **Check tag/layer usage**
- Bitmap tags for fast group membership queries
- Layers for spatial/functional entity grouping

## Success Criteria
- [ ] No stale ID references in game logic
- [ ] All mutations happen in lurek.update(), not lurek.draw()
- [ ] ID recycling follows LIFO order
- [ ] Blueprint patterns are copy-on-spawn
- [ ] Tests cover the full lifecycle

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /review-entity-lifecycle

## CAG Metadata
- **Mode**: agent
