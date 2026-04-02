# src/quest/

Quest and objective tracking system.

## What This Module Contains

QuestLog owns a collection of Quests. Each Quest has QuestStages containing
Objectives. ObjectiveStatus and QuestStatus track progress. JournalEntry
records narrative notes with timestamps.

## Files

| File | Purpose |
|------|---------|
| `status.rs` | QuestStatus, ObjectiveStatus |
| `objective.rs` | Objective, QuestStage |
| `journal.rs` | JournalEntry |
| `quest.rs` | Quest |
| `log.rs` | QuestLog |
| `mod.rs` | Facade — re-exports all sub-modules |

## Navigation

- **Owner agent**: `Developer`
- **Lua API bindings**: `src/lua_api/quest_api.rs` (if present)
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- No dependencies on other domain modules
- Must NOT import from other Tier 3 modules directly
