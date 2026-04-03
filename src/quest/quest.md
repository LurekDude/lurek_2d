# quest — Quest Flags, Lore & Tech Tree Module

> **Lua namespace:** `luna.quest`
> **C++ module:** `src/modules/quest/`
> **Purpose:** Provides a global key-value flag store with observer callbacks for quest/progression tracking, a Lore encyclopedia for discoverable entries, and a TechTree for prerequisite-gated unlocks with resource costs. Flags support any Lua value type and can be observed for changes via glob-pattern matching.

## Reimplementation Notes

- The quest flags are a flat key→value store where values can be any Lua type (string, number, boolean, table)
- `on(pattern, callback)` registers an observer using glob patterns on key names — the callback fires when `set()`, `increment()`, or `toggle()` modifies a matching key
- `save()` serializes the entire flag store to a Lua table; `load(table)` restores it — designed for integration with `luna.savegame`
- `increment(key, amount?)` only works on numeric values — it returns the new value
- `toggle(key)` only works on boolean values — it returns the new value
- The Lore system is a singleton accessed via `getLore()` — there is only one Lore database per module instance
- TechTree nodes are defined with a table containing `{id, name?, group?, cost={}, requires={}, onUnlock=function, ...}`
- TechTree costs are string→number maps (e.g., `{gold=100, wood=50}`) — your game logic checks/deducts resources
- TechTree `onUnlock` callback is stored as a Lua registry reference and called when `unlock()` succeeds
- TechTree `canUnlock()` checks that all prerequisites are unlocked — it does NOT check resource costs (that's game logic)
- **Acquisition modes**: nodes support multiple ways to unlock — `"instant"` (pay cost and unlock), `"research"` (accumulate points over time via `addProgress()`), `"purchase"` (spend currency via `buy()`), `"event"` (unlocked by external game event), `"random"` (random chance when conditions met), `"salvage"` (unlock by collecting/analyzing items)
- **Prerequisite logic**: `requires` supports complex expressions — `requireMode = "all"` (default AND), `"any"` (OR — unlock if ANY prereq met), `"count"` (meet N of M prereqs via `requireCount`). This enables OpenXCOM-style branching where researching alien tech can unlock via multiple paths
- **Mutually exclusive groups**: `exclusiveGroup = "string"` — only one node per group can be unlocked. Unlocking one auto-locks others in the group (e.g., choose faction allegiance)
- **Random unlock gates**: `randomChance = 0.0–1.0` — probability of unlock succeeding when conditions are met. Failed attempts can be retried. `randomSeed` pins deterministic rolls per save
- **Hidden/revealed nodes**: `hidden = true` — node is invisible in tree UI until a reveal condition is met. `revealWhen = {prereq_ids}` — auto-reveals when listed nodes are unlocked
- **Research progress**: nodes with `mode = "research"` track progress via `addProgress(id, amount)`. Progress is capped at `researchCost` field. Supports multiple parallel research tracks via `researchSlot` assignment
- **Parallel research slots**: `setMaxResearchSlots(n)` limits simultaneous research. Each active research node occupies one slot. Multiple trees can share or have separate slot pools
- **Eras/epochs**: `era = "string"` groups nodes into progression eras. `lockEra(era)` / `unlockEra(era)` controls visibility/availability of entire eras
- **Node callbacks**: besides `onUnlock`, supports `onReveal`, `onProgressStart`, `onProgressTick`, `onProgressComplete`, `onLocked` (when mutually exclusive blocks it)
- **Serialization**: full tree state (unlocked, progress, revealed, locked exclusives) serializes to a Lua table for use with `luna.savegame`

## Dependencies

- None (standalone module — but typically used with `luna.savegame` for persistence)

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `set` | `key: string, value: any` | — | Set a flag value. Triggers observers matching the key |
| `get` | `key: string` | `any` | Get a flag value |
| `has` | `key: string` | `boolean` | Check if a flag key exists |
| `increment` | `key: string, amount?: number` | `number` | Add amount (default 1.0) to a numeric flag. Returns new value |
| `toggle` | `key: string` | `boolean` | Flip a boolean flag. Returns new value |
| `on` | `pattern: string, callback: function` | — | Register an observer for flag changes matching the glob pattern |
| `off` | `pattern: string` | — | Remove all observers for the given pattern |
| `clearObservers` | — | — | Remove all registered observers |
| `save` | — | `table` | Serialize the entire flag store to a Lua table |
| `load` | `data: table` | — | Restore the flag store from a previously saved table |
| `reset` | — | — | Clear all flags and observers |
| `getAll` | — | `table` | Get the full flag store as a key→value table |
| `getLore` | — | `Lore` | Get the singleton Lore database |
| `newTechTree` | `config?: table` | `TechTree` | Create a new tech tree. Optional config: `{maxResearchSlots=1}` |

---

## Type: Lore

A discoverable encyclopedia of entries organized by category.

**Accessed via:** `luna.quest.getLore()` (singleton)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `define` | `id: string, title: string, body: string, category?: string` | — | Define a lore entry. Category defaults to `""` |
| `discover` | `id: string` | — | Mark a lore entry as discovered/known |
| `isKnown` | `id: string` | `boolean` | Check if an entry has been discovered |
| `getAll` | — | `table` | Get all entries as `{id, title, body, category, discovered}` tables |
| `getByCategory` | `category: string` | `table` | Get all entries in a category |
| `getEntry` | `id: string` | `table \| nil` | Get a single entry by ID, or nil |

### Lore Entry Table Format

Each entry returned by `getAll()`, `getByCategory()`, or `getEntry()` is:

```lua
{
    id = "entry_id",         -- string: unique identifier
    title = "Entry Title",   -- string: display name
    body = "Long text...",   -- string: content
    category = "history",    -- string: grouping tag
    discovered = true        -- boolean: has player found this?
}
```

---

## Type: TechTree

A directed acyclic graph of unlockable nodes with prerequisites, resource costs, multiple acquisition modes, parallel research, and mutual exclusion. Supports complex scenarios like OpenXCOM research trees.

**Created by:** `luna.quest.newTechTree()`

### Node Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addNode` | `def: table` | — | Add a tech node (see Node Definition below) |
| `removeNode` | `id: string` | — | Remove a node and all edges referencing it |
| `getNode` | `id: string` | `table \| nil` | Get full node info table |
| `getNodes` | — | `table` | Get all nodes as `{id → node_table}` map |
| `getNodeCount` | — | `number` | Total number of nodes |

### Unlock & Status

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `canUnlock` | `id: string` | `boolean` | True if all prerequisites are met (respects `requireMode`). Does NOT check costs |
| `unlock` | `id: string` | `boolean` | Unlock a node. Returns false if prerequisites not met or excluded. Calls `onUnlock` callback. Auto-locks other nodes in same `exclusiveGroup` |
| `lock` | `id: string` | — | Re-lock a previously unlocked node. Useful for mutually exclusive re-selection |
| `isUnlocked` | `id: string` | `boolean` | Check if a node is unlocked |
| `isExcluded` | `id: string` | `boolean` | True if another node in the same exclusive group is already unlocked |
| `getAvailable` | — | `table<string>` | IDs of nodes whose prerequisites are met but not yet unlocked (excludes hidden/excluded) |
| `getUnlocked` | — | `table<string>` | IDs of all unlocked nodes |
| `getLocked` | — | `table<string>` | IDs of all locked (not yet unlocked) nodes |
| `progress` | — | `int, int` | Returns `(unlocked_count, total_count)` |

### Acquisition Modes

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `buy` | `id: string, resources: table` | `boolean, string?` | Attempt purchase unlock. Checks prerequisites AND verifies `resources` table covers `cost`. Returns `(ok, reason)`. The tree does NOT deduct resources — game code handles that after a true return |
| `canBuy` | `id: string, resources: table` | `boolean, string?` | Check if purchase is possible without unlocking. Returns `(ok, reason)` |
| `tryRandomUnlock` | `id: string, seed?: number` | `boolean` | For nodes with `randomChance`: roll dice and unlock if successful. `seed` pins the RNG result for deterministic saves. Returns true if unlocked |
| `salvage` | `id: string, items: table` | `boolean` | Unlock via item collection. Checks that `items` table contains all entries in node's `salvageRequires` list |

### Research Progress (Time-Based Acquisition)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `startResearch` | `id: string, slot?: number` | `boolean, string?` | Begin researching a node. Assigns to a research slot (auto-assigns if omitted). Returns `(ok, reason)`. Fails if no slots free or prerequisites not met |
| `pauseResearch` | `id: string` | — | Pause research on a node (keeps accumulated progress) |
| `cancelResearch` | `id: string` | — | Cancel research and reset progress to 0. Frees the slot |
| `addProgress` | `id: string, amount: number` | `boolean` | Add research points to a node. Auto-unlocks when progress ≥ `researchCost`. Returns true if just unlocked |
| `getProgress` | `id: string` | `number, number` | Returns `(current_progress, research_cost)` |
| `isResearching` | `id: string` | `boolean` | True if this node is actively being researched |
| `getResearchQueue` | — | `table` | List of `{id, progress, cost, slot, paused}` for all active/paused research |

### Research Slots

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setMaxResearchSlots` | `count: number` | — | Set maximum simultaneous research tracks (default 1) |
| `getMaxResearchSlots` | — | `number` | Get max slot count |
| `getActiveResearchCount` | — | `number` | Number of currently active (not paused) research jobs |
| `getFreeSlotCount` | — | `number` | Number of available research slots |

### Eras & Grouping

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `lockEra` | `era: string` | — | Lock all nodes in an era (prevents unlock/research) |
| `unlockEra` | `era: string` | — | Unlock an era (nodes become available if prerequisites met) |
| `isEraUnlocked` | `era: string` | `boolean` | Check if an era is accessible |
| `getEras` | — | `table<string>` | List all era names |
| `getNodesByEra` | `era: string` | `table<string>` | Get node IDs in a specific era |
| `getNodesByGroup` | `group: string` | `table<string>` | Get node IDs in a specific group |
| `getGroups` | — | `table<string>` | List all group names |

### Hidden / Revealed Nodes

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setHidden` | `id: string, hidden: boolean` | — | Hide/show a node |
| `isHidden` | `id: string` | `boolean` | Check if a node is hidden |
| `isRevealed` | `id: string` | `boolean` | True if a previously hidden node has been revealed |
| `reveal` | `id: string` | — | Manually reveal a hidden node. Fires `onReveal` callback |
| `checkRevealConditions` | — | `table<string>` | Check all hidden nodes and auto-reveal those whose `revealWhen` prereqs are met. Returns list of newly revealed IDs |
| `getVisibleNodes` | — | `table<string>` | Get IDs of all non-hidden (or revealed) nodes |

### Mutual Exclusion

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getExclusiveGroup` | `id: string` | `string \| nil` | Get the exclusive group of a node |
| `getExclusiveGroupMembers` | `group: string` | `table<string>` | Get all node IDs in an exclusive group |
| `getExclusiveGroups` | — | `table<string>` | List all exclusive group names |
| `getExcludedNodes` | — | `table<string>` | Get IDs of nodes excluded by mutual exclusion |

### Prerequisite Configuration

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setRequireMode` | `id: string, mode: string` | — | Set prerequisite logic: `"all"` (AND), `"any"` (OR), `"count"` (N of M) |
| `getRequireMode` | `id: string` | `string` | Get prerequisite mode |
| `setRequireCount` | `id: string, count: number` | — | For `"count"` mode: how many prereqs must be met |
| `checkPrerequisites` | `id: string` | `boolean, table<string>` | Check prereqs manually. Returns `(met, missing_ids)` |

### Callbacks

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `onNodeEvent` | `id: string, event: string, fn: function` | — | Register callback for node event. Events: `"unlock"`, `"lock"`, `"reveal"`, `"excluded"`, `"researchStart"`, `"researchComplete"`, `"researchTick"`, `"progressAdd"` |
| `onTreeEvent` | `event: string, fn: function` | — | Register global tree callback. Events: `"nodeUnlocked"`, `"eraUnlocked"`, `"researchComplete"`, `"allUnlocked"` |

### Serialization

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `save` | — | `table` | Serialize full tree state (unlocked, progress, revealed, research queue, era states) for savegame |
| `load` | `data: table` | — | Restore tree state from saved table |
| `toJSON` | — | `string` | Export tree structure as JSON (for editor integration) |

### Node Definition Table

```lua
{
    id = "iron_smelting",                    -- string: required, unique ID
    name = "Iron Smelting",                  -- string: optional display name (defaults to id)
    group = "metallurgy",                    -- string: optional grouping tag
    era = "classical",                       -- string: optional era/epoch for progression gating
    tier = 2,                                -- number: optional visual tier for layout (0-based)

    -- Prerequisites
    requires = { "copper_smelting" },         -- table: list of prerequisite node IDs
    requireMode = "all",                      -- string: "all" (AND), "any" (OR), "count" (N of M)
    requireCount = 1,                         -- number: for "count" mode — how many prereqs needed

    -- Costs
    cost = { gold = 100, research = 50 },     -- table: string→number resource costs (for buy/instant mode)

    -- Acquisition mode
    mode = "research",                        -- string: "instant", "research", "purchase", "event", "random", "salvage"
    researchCost = 200,                       -- number: total research points needed (for "research" mode)
    randomChance = 0.3,                       -- number: 0.0–1.0 probability (for "random" mode)
    salvageRequires = { "alien_alloy" },      -- table: item IDs needed (for "salvage" mode)

    -- Mutual exclusion
    exclusiveGroup = "faction_allegiance",    -- string: only one node per group can be unlocked

    -- Hidden / revealed
    hidden = true,                            -- boolean: invisible until revealed
    revealWhen = { "copper_smelting" },        -- table: auto-reveal when these nodes are unlocked

    -- Callbacks
    onUnlock = function(id) ... end,          -- function: fired on unlock
    onReveal = function(id) ... end,          -- function: fired on reveal
    onResearchStart = function(id) ... end,   -- function: fired when research begins
    onResearchTick = function(id, progress, cost) ... end,  -- function: fired on addProgress
}
```

---

## Usage Example

### Basic Flags & Lore

```lua
-- Quest flags
luna.quest.set("main_quest_stage", 1)
luna.quest.on("main_quest_*", function()
    print("Main quest flag changed!")
end)
luna.quest.increment("main_quest_stage")  -- prints notification, returns 2

-- Lore encyclopedia
local lore = luna.quest.getLore()
lore:define("ancient_ruins", "The Ancient Ruins", "Long ago, a civilization...", "history")
lore:discover("ancient_ruins")
```

### OpenXCOM-Style Research Tree

```lua
local tree = luna.quest.newTechTree()
tree:setMaxResearchSlots(3)  -- 3 parallel research tracks

-- Ancient era techs
tree:addNode({ id = "alien_materials", name = "Alien Materials", era = "invasion",
    mode = "salvage", salvageRequires = { "alien_alloy_sample" },
    onUnlock = function() print("Alien materials analyzed!") end })

tree:addNode({ id = "laser_weapons", name = "Laser Weapons", era = "invasion",
    mode = "research", researchCost = 500, requires = { "alien_materials" },
    cost = { scientists = 4 } })

tree:addNode({ id = "plasma_weapons", name = "Plasma Weapons", era = "invasion",
    mode = "research", researchCost = 1200, requires = { "laser_weapons" },
    hidden = true, revealWhen = { "laser_weapons" } })

-- Multiple paths to same tech (OR prerequisites)
tree:addNode({ id = "advanced_armor", name = "Advanced Armor", era = "invasion",
    mode = "research", researchCost = 800,
    requires = { "alien_materials", "laser_weapons", "plasma_weapons" },
    requireMode = "any" })  -- any ONE of these unlocks the prereq

-- Random discovery (alien autopsy gives 30% chance of psi discovery)
tree:addNode({ id = "psi_discovery", name = "Psionic Discovery", era = "invasion",
    mode = "random", randomChance = 0.3,
    requires = { "alien_materials" }, hidden = true, revealWhen = { "alien_materials" } })

-- Mutually exclusive faction choice
tree:addNode({ id = "ally_humans", name = "Human Alliance", era = "endgame",
    mode = "event", exclusiveGroup = "faction", requires = { "advanced_armor" } })
tree:addNode({ id = "ally_aliens", name = "Alien Pact", era = "endgame",
    mode = "event", exclusiveGroup = "faction", requires = { "psi_discovery" } })

-- Game loop: salvage triggers research chain
tree:salvage("alien_materials", { "alien_alloy_sample" })  -- unlocks immediately

-- Start parallel research
tree:startResearch("laser_weapons")
-- Each frame/turn, add progress
tree:addProgress("laser_weapons", 10)  -- returns true when complete

-- Auto-reveal hidden nodes
local revealed = tree:checkRevealConditions()  -- reveals plasma_weapons after laser_weapons unlocked

-- Try random discovery
tree:tryRandomUnlock("psi_discovery", os.time())  -- 30% chance
```

### Parallel Research with Slots

```lua
local tree = luna.quest.newTechTree()
tree:setMaxResearchSlots(2)

tree:addNode({ id = "tech_a", mode = "research", researchCost = 100 })
tree:addNode({ id = "tech_b", mode = "research", researchCost = 200 })
tree:addNode({ id = "tech_c", mode = "research", researchCost = 150 })

-- Start two research tracks in parallel
tree:startResearch("tech_a")  -- slot 1
tree:startResearch("tech_b")  -- slot 2
local ok, reason = tree:startResearch("tech_c")  -- fails: no free slots
print(ok, reason)  -- false, "no free research slots"

-- Progress both simultaneously
function advanceResearch(dt, sciencePerSecond)
    for _, r in ipairs(tree:getResearchQueue()) do
        if not r.paused then
            tree:addProgress(r.id, sciencePerSecond * dt)
        end
    end
end

-- Save/restore full state
local state = tree:save()
luna.savegame.set("tech_tree", state)
-- Later...
tree:load(luna.savegame.get("tech_tree"))
```

### Mutually Exclusive Branches

```lua
local tree = luna.quest.newTechTree()

-- Player must choose: magic or technology path
tree:addNode({ id = "magic_path", name = "Arcane Studies", exclusiveGroup = "path_choice",
    mode = "instant", cost = { gold = 500 } })
tree:addNode({ id = "tech_path", name = "Engineering", exclusiveGroup = "path_choice",
    mode = "instant", cost = { gold = 500 } })

-- Each path has unique subtrees
tree:addNode({ id = "fireball", requires = { "magic_path" }, mode = "research", researchCost = 100 })
tree:addNode({ id = "steam_engine", requires = { "tech_path" }, mode = "research", researchCost = 100 })

-- Choosing one excludes the other
tree:unlock("magic_path")
print(tree:isExcluded("tech_path"))  -- true
print(tree:canUnlock("steam_engine"))  -- false (tech_path is excluded)
```

### Extension Integration

The **Quest / Tech Tree Editor** panel (`luna2d.editor.questTree`) provides visual editing of tech trees with graph, table, and timeline views.

**Export formats:**

Node data exported to **Lua**:
```lua
return {
  nodes = {
    { id = "fire", name = "Fire Making", tier = 0, era = "Ancient",
      cost = { science = 20 }, rewards = { { type = "unlock", value = "Farm" } },
      prerequisites = {}, status = "completed" },
    -- ...
  },
  edges = {
    { from = "fire", to = "cooking" },
  },
}
```

Node data exported to **TOML**:
```toml
[nodes.fire]
name = "Fire Making"
tier = 0
era = "Ancient"
prerequisites = []

[nodes.fire.cost]
science = 20

[[nodes.fire.rewards]]
type = "unlock"
value = "Farm"

[edges]
fire = ["cooking"]
```

---

## Game Design Role

- **RPG main quests**: Track multi-stage story progression with flag-based state and observer callbacks.
- **Collectibles**: Count collected items via `increment()` flags; observe thresholds for rewards.
- **Achievement system**: Use flags as achievement trackers; observe patterns like `"achievement.*"` to fire unlock logic.
- **Tutorial gating**: Gate tutorial steps behind flags (`quest_stage >= 3`); observers advance the tutorial when conditions are met.
- **Narrative chapters**: Use the Lore system to unlock readable lore entries as the player discovers story elements.

---

## Module Boundaries

**vs luna.dialog** — Dialog sequences narrative text (typewriter, choices, branching). Quest tracks global *state* (flags). Dialog reads quest flags for conditional branches and writes them via `call` nodes. Dialog narrates; Quest tracks.

**vs luna.stats** — Stats holds numeric character attributes and combat data. Quest can use `increment()` flags to track quest-specific counters that don't belong on a character sheet (e.g. "enemies_killed_in_zone_3").

**vs luna.entity** — Entity manages game objects in an ECS. Quest flags represent abstract game state. An entity system reads quest flags to toggle world objects (e.g. open a door when `"bridge_repaired"` flag is true).

**vs luna.patterns (Observer)** — The global Observer pattern is a general pub/sub tool. Quest's `on(pattern)` is specifically scoped to flag key changes with glob matching.

**vs luna.filesystem / luna.savegame** — Quest's `save()` returns a Lua table. Register it as a savegame collector to persist quest state: `luna.savegame.register("quest", function() return luna.quest.save() end, function(data) luna.quest.load(data) end)`.

---

## Recipes & Workflows

- **RPG main quest**: Set `quest_stage` flag. Observe `"quest_stage"` to trigger cutscenes at milestones. Use TechTree for branching quest paths.
- **Collectible hunt**: `increment("stars_collected")` on pickup. Observe `"stars_collected"` to unlock rewards at thresholds (10, 50, 100).
- **Achievement system**: `set("achievement.first_kill", true)`. Observe `"achievement.*"` to show toast notifications.
- **Tutorial gating**: Check `get("tutorial_step")` to decide which hint to show. `increment("tutorial_step")` after each completed action.
- **Chapter unlocking**: Use TechTree eras: lock `"chapter_2"` era until the player completes `"chapter_1_boss"` flag.

---

## Planned / To Implement

- **W1**: Quest schema — structured quest definitions with objectives, rewards, and completion criteria beyond raw flags.
- **W1**: `activate()` / `advance()` / `complete()` — higher-level quest lifecycle API on top of raw flags.
- **W2**: Reactive observer — conditional triggers that fire when multiple flags satisfy a compound expression (e.g. `stars >= 10 AND boss_defeated`).
- **W2**: Journal serialisation — export quest log as a structured table for UI rendering (active quests, completed quests, objectives).
- **W3**: Quest editor — visual node editor for designing quest graphs with flag conditions and TechTree integration.
