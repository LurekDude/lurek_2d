# `quest` — Agent Reference (Lunasome)

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Lunasome (pure Lua, no Rust dependencies) |
| **Source** | `library/quest/init.lua` |
| **Lua Tests** | `tests/lua/library/test_library_quest.lua` |
| **Depends on** | `lurek.*` public API only |

## Summary

Quest tracking system with staged objectives, journal entries, metadata, and
reward management. `Quest` is the central data object: it holds a list of
`QuestStage` entries each containing one or more `Objective` instances. Stages
advance sequentially while objectives within a stage may be completed in any
order.

**Quest lifecycle** (runtime status strings): `"available"` → `"active"` →
`"completed"` | `"failed"`. Use `quest:start()`, `quest:complete()`, and
`quest:fail()` to drive transitions. `QuestLog:resetQuest(id)` reverts a quest
back to `"available"` with stage index 1 and all objective progress cleared.

**Objective lifecycle** (runtime status strings): `"pending"` → `"active"` →
`"done"` | `"skipped"` | `"failed"`. `Objective:advance(n)` and
`Objective:setProgress(n)` drive progress automatically. `Objective` supports
free tagging with `addTag(tag)` and `removeTag(tag)` for arbitrary flags such as
`"hidden"` or `"bonus"`.

> **Status enum note** — `M.QuestStatus` and `M.ObjectiveStatus` expose
> compatibility constants (`LOCKED`, `ACTIVE`, `COMPLETED`, `FAILED`) that map
> to the strings `"locked"`, `"active"`, `"completed"`, `"failed"`. These
> constants do **not** match the runtime strings used by the library itself
> (`"available"`, `"pending"`, `"done"`). Use the runtime strings when
> comparing `quest.status` or `objective.status` in game logic.

`QuestLog` is the session-level container for all quests. It provides
start/complete/fail/reset lifecycle operations and convenience queries:
`activeIds()`, `completedIds()`, `failedIds()`, `activeCount()`,
`completedCount()`. Reward strings are attached per quest via `setQuestReward`
and retrieved with `getQuestReward`; reward fulfilment is the game script's
responsibility.

Both `Quest` and `QuestLog` carry no GPU, physics, or audio dependencies, making
the module fully operational in headless Lua test VMs.

## Architecture

```
QuestLog (session container)
  │
  └── quests: { id → Quest }
        │
        ├── status: "available" | "active" | "completed" | "failed"
        ├── stages: { QuestStage }
        │     └── objectives: { Objective }
        │           ├── status: "pending" | "active" | "done" | "skipped" | "failed"
        │           ├── current / required  (numeric progress)
        │           ├── tags: string[]      (addTag / removeTag)
        │           ├── mandatory: bool
        │           └── visible: bool
        │
        ├── journal: { index, text, tag }[]
        ├── metadata: { key → value }
        └── reward: string
```

## Source Files

| File | Purpose |
|------|---------|
| `library/quest/init.lua` | Full implementation — Quest, QuestStage, Objective, QuestLog, status enums |

## Key Types

| Type | Constructor | Purpose |
|------|-------------|---------|
| `Quest` | `M.newQuest(id, title)` | Quest with stages, journal, metadata, and reward |
| `QuestStage` | `M.newQuestStage(id, name)` | Sequential stage containing one or more objectives |
| `Objective` | `M.newObjective(id, description, required)` | Trackable goal with progress counter and tags |
| `QuestLog` | `M.newQuestLog()` | Session container with lifecycle operations and query helpers |
| `M.QuestStatus` | enum table | Compatibility constants: LOCKED, ACTIVE, COMPLETED, FAILED |
| `M.ObjectiveStatus` | enum table | Compatibility constants: LOCKED, ACTIVE, COMPLETED, FAILED |

## API Surface

### Objective

| Method | Signature | Description |
|--------|-----------|-------------|
| `advance` | `(amount?)` → `number` | Advance progress by amount (default 1); auto-completes at required |
| `setProgress` | `(value)` | Set progress directly; clamps to [0, required] |
| `isComplete` | `()` → `bool` | True if status is "done" or "skipped" |
| `addTag` | `(tag)` | Add a tag string; no-op if duplicate |
| `removeTag` | `(tag)` → `bool` | Remove a tag; returns true if it was present |
| `hasTag` | `(tag)` → `bool` | True if the tag is present |

### QuestStage

| Method | Signature | Description |
|--------|-----------|-------------|
| `addObjective` | `(obj)` | Append an objective |
| `getObjective` | `(id)` → `Objective\|nil` | Find by id |
| `getObjectives` | `()` → `table` | All objectives array |
| `objectiveCount` | `()` → `number` | Objective count |
| `clearObjectives` | `()` | Remove all objectives |
| `hasObjective` | `(id)` → `bool` | True if an objective with that id exists |
| `isComplete` | `()` → `bool` | True when all mandatory objectives are complete |

### Quest

| Method | Signature | Description |
|--------|-----------|-------------|
| `addStage` | `(stage)` | Append a stage |
| `getCurrentStage` | `()` → `QuestStage\|nil` | Active stage |
| `getStage` | `(id)` → `QuestStage\|nil` | Find stage by id |
| `nextStage` | `()` → `bool` | Advance to next stage |
| `gotoStage` | `(id)` → `bool` | Jump to named stage |
| `start` | `()` | available → active |
| `complete` | `()` | → completed |
| `fail` | `()` | → failed |
| `advanceObjective` | `(obj_id, amount?)` → `bool` | Advance named objective across all stages |
| `setObjectiveStatus` | `(obj_id, status)` → `bool` | Directly set objective status |
| `resetObjective` | `(id)` → `bool` | Reset named objective back to "active" |
| `allObjectivesComplete` | `()` → `bool` | True if every mandatory objective is done |
| `completionPercent` | `()` → `number` | 0–100 percent of mandatory objectives done |
| `activeObjectiveIds` | `()` → `table` | IDs of objectives currently "active" |
| `addJournalEntry` | `(text, tag?)` → `number` | Append journal entry; returns index |
| `setMeta` | `(key, value)` | Set metadata key-value |
| `getMeta` | `(key)` → `string\|nil` | Get metadata value |

### QuestLog

| Method | Signature | Description |
|--------|-----------|-------------|
| `addQuest` | `(quest)` | Register quest; replaces if same id |
| `getQuest` | `(id)` → `Quest\|nil` | Look up quest |
| `removeQuest` | `(id)` → `bool` | Remove quest |
| `questIds` | `()` → `table` | All ids in insertion order |
| `questsWithStatus` | `(status)` → `table` | IDs with matching status string |
| `questCount` | `()` → `number` | Total registered quests |
| `startQuest` | `(id)` → `bool` | available → active |
| `completeQuest` | `(id)` → `bool` | → completed |
| `failQuest` | `(id)` → `bool` | → failed |
| `resetQuest` | `(id)` → `bool` | Revert to available, stage 1, progress 0 |
| `advanceObjective` | `(quest_id, obj_id, amount?)` → `bool` | Advance objective in named quest |
| `activeIds` | `()` → `table` | IDs of all active quests |
| `completedIds` | `()` → `table` | IDs of all completed quests |
| `failedIds` | `()` → `table` | IDs of all failed quests |
| `activeCount` | `()` → `number` | Count of active quests |
| `completedCount` | `()` → `number` | Count of completed quests |
| `setQuestReward` | `(id, reward)` | Set reward description string |
| `getQuestReward` | `(id)` → `string\|nil` | Get reward description |

## Test Coverage

`tests/lua/library/test_library_quest.lua` — 56 tests, 0 failures.

Covers: Objective lifecycle, QuestStage management, Quest stages/objectives/journal/metadata,
QuestLog CRUD/lifecycle/queries, `resetQuest`, reward helpers, `activeCount`/`completedCount`,
`removeTag`, `getObjectives`, and status enum tables.
