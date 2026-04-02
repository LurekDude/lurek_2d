# `src/quest/` — Quest & Objective Tracking

## Purpose

RPG-style quest system with stages, objectives, conditions, and a player journal.
Tracks `Quest` completion progress through `Objective` trees and records
narrative entries in a `QuestLog`.

## Files

| File | Purpose |
|------|---------|
| `status.rs` | `QuestStatus`, `ObjectiveStatus` enums |
| `objective.rs` | `Objective`, `QuestStage` — conditions and stage grouping |
| `journal.rs` | `JournalEntry` — dated narrative note |
| `quest.rs` | `Quest` — definition with stages and completion tracking |
| `log.rs` | `QuestLog` — collection of quests and journal |

## Tier

**Tier 3** (gameplay-specific). Must not be imported by Tier 1 or Tier 2 modules.
