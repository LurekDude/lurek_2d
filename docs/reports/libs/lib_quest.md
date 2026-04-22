# `library.quest`

A pure-Lua replacement for the former `lurek.quest` Rust binding.
No engine dependencies; works in headless test VMs.
Optional: uses `lurek.log.debug()` / `lurek.log.info()` when available for
quest state-change tracing.

**Quest lifecycle states and valid transitions**:

available → active  (via Quest:start)
active    → completed (via Quest:complete)
active    → failed    (via Quest:fail)

All other transitions are rejected and return false.

**Engine integrations** (all optional — inject from your game code):

* Event bus: attach `lurek.patterns.newEventBus()` via `QuestLog:setEventBus`
to receive `quest_started` / `quest_advanced` / `quest_completed` /
`quest_failed` events.
* Serialisation: `M.toJson(log)` / `M.fromJson(str)` round-trip the log
through `lurek.serial.toJson` / `lurek.serial.fromJson`.
* Persistence: register a custom collector with `lurek.save.SaveManager`
that calls `M.toJson(log)` on save and `M.fromJson(str)` on load.
* Time-limited objectives: drive expiry from a `lurek.timer.Scheduler` you
create in your game loop (call `QuestLog:failQuest(id)` from the callback);
this library does not require `lurek.timer` at runtime.

Usage:
local quest = require("library.quest")
local log = quest.newQuestLog()
local q = quest.newQuest("tutorial", "Tutorial Quest")
q.description = "Learn the basics"
local stage = quest.newQuestStage("s1", "First Steps")
local obj = quest.newObjective("talk_npc", "Talk to the guide", 1)
stage:addObjective(obj)
q:addStage(stage)
log:addQuest(q)
log:startQuest("tutorial")
log:advanceObjective("tutorial", "talk_npc", 1)

*56 functions, 0 module fields documented.*

See: [`lurek.patterns.newEventBus`](../lua-api.md#lurekpatternsneweventbus), [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson), [`lurek.serial.fromJson`](../lua-api.md#lurekcodecfromjson), [`lurek.save.SaveManager`](../lua-api.md#lureksavegamesavemanager), [`lurek.timer.Scheduler`](../lua-api.md#lurektimescheduler)

## Functions

### `newObjective(id, description, required)`

Create a new objective with 0/required progress.

**Parameters**

- `id` *string* — Unique identifier within the parent quest.
- `description` *string* — Human-readable display text.
- `required` *number* — Required count to mark as done.

**Returns**

- *Objective*

### `advance(amount)`

Advance progress by amount. Automatically marks the objective as "done" when current >= required. Does nothing if already done or failed.

**Parameters**

- `amount` *number* — Amount to advance (default 1). Must be positive.

**Returns**

- *number* — New progress value.

### `setProgress(value)`

Set progress directly. Clamps to [0, required].

**Parameters**

- `value` *number* — New progress value.

### `isComplete()`

Returns true if this objective is considered complete (done or skipped).

**Returns**

- *boolean*

### `addTag(tag)`

Add a tag. Has no effect if already present.

**Parameters**

- `tag` *string* — Tag to add.

### `hasTag(tag)`

Returns true if the given tag is present.

**Parameters**

- `tag` *string* — Tag to check.

**Returns**

- *boolean*

### `newQuestStage(id, name)`

Create a new empty quest stage.

**Parameters**

- `id` *string* — Unique stage identifier.
- `name` *string* — Display name for this stage.

**Returns**

- *QuestStage*

### `addObjective(obj)`

Add an objective to this stage.

**Parameters**

- `obj` *Objective* — Objective to add.

### `getObjective(id)`

Get an objective by id.

**Parameters**

- `id` *string* — Objective id to find.

**Returns**

- *Objective|nil*

### `getObjectives()`

Get all objectives in this stage.

**Returns**

- *table* — Array of Objective objects.

### `objectiveCount()`

Return the number of objectives in this stage.

**Returns**

- *number*

### `clearObjectives()`

Remove all objectives from this stage.

### `hasObjective(id)`

Returns true if this stage contains an objective with the given id.

**Parameters**

- `id` *string* — Objective id to check.

**Returns**

- *boolean*

### `isComplete()`

Returns true when all mandatory objectives in this stage are complete.

**Returns**

- *boolean*

### `newQuest(id, title, max_journal_entries)`

Create a new quest in the "available" state. Valid status transitions: available → active → completed | failed.

**Parameters**

- `id` *string* — Unique identifier (non-empty).
- `title` *string* — Display title (non-empty).
- `max_journal_entries` *number* — Maximum journal entries to keep. nil = unlimited.

**Returns**

- *Quest*

### `addStage(stage)`

Add a stage to the quest (in order).

**Parameters**

- `stage` *QuestStage* — Stage to add.

### `getCurrentStage()`

Get the currently active stage, if any.

**Returns**

- *QuestStage|nil*

### `getStage(id)`

Get a stage by id.

**Parameters**

- `id` *string* — Stage id to find.

**Returns**

- *QuestStage|nil*

### `nextStage()`

Advance to the next stage. Returns true on success, false if already at last stage.

**Returns**

- *boolean*

### `gotoStage(id)`

Jump to the stage with the given id. Returns false if not found.

**Parameters**

- `id` *string* — Stage id to jump to.

**Returns**

- *boolean*

### `advanceObjective(obj_id, amount, stage_id)`

Advance progress on an objective in the current stage (or a specific stage). Returns false if objective not found in the target stage.

**Parameters**

- `obj_id` *string* — Objective id.
- `amount` *number* — Amount to advance (default 1).
- `stage_id` *string* — If provided, search this stage instead of the current one.

**Returns**

- *boolean*

### `setObjectiveStatus(obj_id, status)`

Set status of an objective across all stages. Returns false if not found.

**Parameters**

- `obj_id` *string* — Objective id.
- `status` *string* — New status ("pending", "active", "done", "skipped", "failed").

**Returns**

- *boolean*

### `start()`

Start the quest (transition from "available" to "active").

**Returns**

- *boolean* — true if the transition was valid.

### `complete()`

Mark the quest as completed (transition from "active" to "completed").

**Returns**

- *boolean* — true if the transition was valid.

### `fail()`

Mark the quest as failed (transition from "active" to "failed").

**Returns**

- *boolean* — true if the transition was valid.

### `addJournalEntry(text, tag)`

Append a journal entry. Returns the entry's index. If `max_journal_entries` was set on the quest, the oldest entries are removed to stay within the limit.

**Parameters**

- `text` *string* — Journal text body.
- `tag` *string* — Optional tag.

**Returns**

- *number* — Entry index.

### `setMeta(key, value)`

Set a metadata key-value pair.

**Parameters**

- `key` *string* — Metadata key.
- `value` *string* — Metadata value.

### `getMeta(key)`

Get a metadata value by key.

**Parameters**

- `key` *string* — Metadata key.

**Returns**

- *string|nil*

### `completionPercent()`

Returns percentage of mandatory objectives that are Done across all stages (0.0-100.0). Returns 0.0 when there are no mandatory objectives.

**Returns**

- *number* — Completion percent.

### `activeObjectiveIds()`

Returns the IDs of all objectives currently "active" across all stages.

**Returns**

- *table* — Array of objective id strings.

### `resetObjective(id)`

Reset an objective back to "active" (in progress). Returns false if not found.

**Parameters**

- `id` *string* — Objective id.

**Returns**

- *boolean*

### `allObjectivesComplete()`

Return true if every mandatory objective in the quest is complete.

**Returns**

- *boolean*

### `newQuestLog()`

Create an empty quest log.

**Returns**

- *QuestLog*

### `setEventBus(bus)`

Attach an event bus to receive quest lifecycle notifications. The bus must implement an `emit(name, payload)` method (e.g. `lurek.patterns.newEventBus()`). Pass `nil` to detach. Emitted events: `"quest_started"`, `"quest_advanced"`, `"quest_completed"`, `"quest_failed"`. The payload table contains at least `{ id = quest_id }` plus event-specific fields.

**Parameters**

- `bus` *table|nil* — Event bus instance, or nil to clear.

See: [`lurek.patterns.newEventBus`](../lua-api.md#lurekpatternsneweventbus)

### `getEventBus()`

Get the currently attached event bus (nil when none).

**Returns**

- *table|nil*

### `addQuest(quest)`

Register a quest. If a quest with the same id already exists, it is replaced.

**Parameters**

- `quest` *Quest* — Quest to add.

### `getQuest(id)`

Get a quest by id.

**Parameters**

- `id` *string* — Quest id.

**Returns**

- *Quest|nil*

### `removeQuest(id)`

Remove a quest by id. Returns true if removed, false if not found.

**Parameters**

- `id` *string* — Quest id.

**Returns**

- *boolean*

### `questIds()`

List ids of all quests in insertion order.

**Returns**

- *table* — Array of quest id strings.

### `questsWithStatus(status)`

List ids of all quests with the given status.

**Parameters**

- `status` *string* — Status to filter by.

**Returns**

- *table* — Array of quest id strings.

### `questCount()`

Total number of registered quests.

**Returns**

- *number*

### `startQuest(id)`

Start quest by id (available -> active). Returns false if not found or invalid transition. Emits `"quest_started"` on the attached event bus.

**Parameters**

- `id` *string* — Quest id.

**Returns**

- *boolean*

### `completeQuest(id)`

Complete quest by id (active -> completed). Returns false if not found or invalid transition. Emits `"quest_completed"` on the attached event bus.

**Parameters**

- `id` *string* — Quest id.

**Returns**

- *boolean*

### `failQuest(id)`

Fail quest by id (active -> failed). Returns false if not found or invalid transition. Emits `"quest_failed"` on the attached event bus.

**Parameters**

- `id` *string* — Quest id.

**Returns**

- *boolean*

### `activeIds()`

IDs of all active quests.

**Returns**

- *table* — Array of quest id strings.

### `completedIds()`

IDs of all completed quests.

**Returns**

- *table* — Array of quest id strings.

### `failedIds()`

IDs of all failed quests.

**Returns**

- *table* — Array of quest id strings.

### `advanceObjective(quest_id, obj_id, amount, stage_id)`

Advance an objective in a specific quest. Returns false if quest or objective not found. Emits `"quest_advanced"` on the attached event bus when the underlying objective accepted the progress change.

**Parameters**

- `quest_id` *string* — Quest id.
- `obj_id` *string* — Objective id.
- `amount` *number* — Amount to advance (default 1).
- `stage_id` *string* — If provided, advance in this stage instead of the current one.

**Returns**

- *boolean*

### `resetQuest(id)`

Reset a quest back to "available" with the first stage active and all objective progress cleared to zero.

**Parameters**

- `id` *string* — Quest id.

**Returns**

- *boolean* — true if the quest was found.

### `setQuestReward(id, reward)`

Set the reward description string on a quest.

**Parameters**

- `id` *string* — Quest id.
- `reward` *string* — Reward description.

### `getQuestReward(id)`

Get the reward description of a quest.

**Parameters**

- `id` *string* — Quest id.

**Returns**

- *string* — Reward description, or nil if quest not found.

### `activeCount()`

Count active quests (status == "in_progress").

**Returns**

- *number*

### `completedCount()`

Count completed quests.

**Returns**

- *number*

### `removeTag(tag)`

Remove a tag from this objective. Returns true if the tag was present.

**Parameters**

- `tag` *string*

**Returns**

- *boolean*

### `toJson(log)`

Encode a `QuestLog` to a JSON string via `lurek.serial.toJson`.

**Parameters**

- `log` *QuestLog*

**Returns**

- *string* — JSON-encoded log.

See: [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson)

### `fromJson(str, into)`

Decode a JSON-encoded log into a fresh `QuestLog`. The optional `into` argument lets the caller reuse an existing log (its quests are replaced).

**Parameters**

- `str` *string* — JSON-encoded log produced by `M.toJson`.
- `into` *QuestLog* — Existing log to populate; a new one is created when nil.

**Returns**

- *QuestLog*

See: [`lurek.serial.fromJson`](../lua-api.md#lurekcodecfromjson)
