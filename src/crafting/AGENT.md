# `crafting` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Gameplay Systems |
| **Lua API** | `luna.crafting` |
| **Source** | `src/crafting/` |
| **Tests** | `tests/crafting_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_crafting.lua` |

## Summary

Recipe-driven crafting primitives for gameplay systems: recipe definitions
and registries, ingredients and outputs, crafting stations, skill
progression, timed craft queues, recipe knowledge, modifier pools, upgrade
trees, and output quality tiers. A `Recipe` specifies one or more
`Ingredient` types with counts (some optional), one or more `RecipeOutput`
types with quality bands, a required station type and skill level, and a
time cost in seconds. `RecipeKnowledge` tracks which recipes a player has
discovered and groups them into UI categories. `CraftQueue` is a FIFO job
queue where concurrent crafting jobs drain toward completion each
`tick(dt)`. `CraftingStation` defines a workbench or furnace with a type,
fuel state, and optional module upgrades. `CraftingSkill` tracks XP, level,
and a DAG-based `UpgradeTree` of craftable perk nodes. `ModifierPool`
provides weighted random rolls on output properties for reroll-style
enchanting. `Quality` is a seven-tier enum from Junk through Legendary that
gates recipes and influences output stat variance.

## Architecture

```
RecipeRegistry (central recipe store)
  │
  ├── Recipe (definition)
  │     ├── ingredients: Vec<Ingredient { item_type, count, optional }>
  │     ├── outputs: Vec<RecipeOutput { item_type, count, quality }>
  │     ├── required_station_type, required_skill_level
  │     └── time_cost (seconds)
  │
  ├── RecipeKnowledge (per-player)
  │     ├── known_recipe_ids: HashSet<String>
  │     └── ui_groups: HashMap<category, Vec<recipe_id>>
  │
  ├── CraftQueue (timed job queue)
  │     └── jobs: VecDeque<CraftJob { recipe_id, station_ref, remaining, count }>
  │
  ├── CraftingStation
  │     ├── station_type, level, fuel
  │     ├── modules: Vec<StationModule>
  │     └── proximity_filter
  │
  ├── CraftingSkill (player progression)
  │     ├── xp, level, specializations
  │     └── perk_tree: UpgradeTree
  │
  ├── UpgradeTree (DAG)
  │     ├── nodes: HashMap<String, UpgradeNode>
  │     └── unlock/prerequisite edges
  │
  ├── ModifierPool (random property rolls)
  │     └── entries: Vec<(Modifier, weight)> → roll() → Vec<Modifier>
  │
  └── Quality (enum)
        └── Junk | Poor | Common | Uncommon | Rare | Epic | Legendary
```

## Source Files

| File | Purpose |
|------|---------|
| `ingredient.rs` | Recipe ingredients and output definitions |
| `knowledge.rs` | Recipe knowledge tracking and UI grouping for crafting |
| `modifier_pool.rs` | Weighted modifier pools for random item property rolls (Path of Exile /... |
| `quality.rs` | Quality tier enum for crafted item outputs |
| `queue.rs` | Craft job queue for timed crafting operations |
| `recipe.rs` | Recipe definition and the central recipe registry |
| `skill.rs` | Player crafting skill with XP, level progression, specializations, and perk tree |
| `station.rs` | Crafting station: type, level, proximity, modules, attachments, and fuel |
| `upgrade.rs` | Upgrade tree: directed acyclic graph for weapon/item progression (Monster... |

## Submodules

### `crafting::ingredient`

Recipe ingredients and output definitions.

- **`Ingredient`** (struct): An ingredient required by a recipe. Consult the module-level documentation for the broader usage context and...
- **`RecipeOutput`** (struct): Output produced by a recipe. Consult the module-level documentation for the broader usage context and preconditions.

### `crafting::knowledge`

Recipe knowledge tracking and UI grouping for crafting.

- **`RecipeKnowledge`** (struct): Tracks which recipes a player has discovered or unlocked.
- **`RecipeGroup`** (struct): Named grouping of recipes for UI organisation and bulk operations.

### `crafting::modifier_pool`

Weighted modifier pools for random item property rolls (Path of Exile / Minecraft Enchanting pattern).

- **`ModifierEntry`** (struct): A single weighted entry in a modifier pool.
- **`ModifierPool`** (struct): A named pool of weighted modifiers that can be rolled to produce random item properties.

### `crafting::quality`

Quality tier enum for crafted item outputs.

- **`Quality`** (enum): Output quality tiers for crafted items. Consult the module-level documentation for the broader usage context and...

### `crafting::queue`

Craft job queue for timed crafting operations.

- **`CraftJob`** (struct): A single in-progress or queued crafting job.
- **`CraftQueue`** (struct): Queue that holds and ticks active craft jobs.

### `crafting::recipe`

Recipe definition and the central recipe registry.

- **`Recipe`** (struct): Defines how inputs are combined to produce outputs.
- **`RecipeRegistry`** (struct): Central registry for all known recipes. Consult the module-level documentation for the broader usage context and...

### `crafting::skill`

Player crafting skill with XP, level progression, specializations, and perk tree.

- **`PerkNode`** (struct): A single node in the perk tree (Skyrim pattern).
- **`CraftSkill`** (struct): Player crafting skill in a profession, with XP tracking and optional perk/spec trees.

### `crafting::station`

Crafting station: type, level, proximity, modules, attachments, and fuel.

- **`Station`** (struct): A crafting station that filters and processes recipes.

### `crafting::upgrade`

Upgrade tree: directed acyclic graph for weapon/item progression (Monster Hunter pattern).

- **`UpgradeNode`** (struct): A single node in an upgrade tree. Consult the module-level documentation for the broader usage context and...
- **`UpgradeTree`** (struct): Directed acyclic graph of upgrades for weapons or equipment.

## Key Types

### Structs

#### `crafting::queue::CraftJob`

A single in-progress or queued crafting job.

#### `crafting::queue::CraftQueue`

Queue that holds and ticks active craft jobs.

#### `crafting::skill::CraftSkill`

Player crafting skill in a profession, with XP tracking and optional perk/spec trees.

#### `crafting::ingredient::Ingredient`

An ingredient required by a recipe. Consult the module-level documentation for the broader usage context and...

#### `crafting::modifier_pool::ModifierEntry`

A single weighted entry in a modifier pool.

#### `crafting::modifier_pool::ModifierPool`

A named pool of weighted modifiers that can be rolled to produce random item properties.

#### `crafting::skill::PerkNode`

A single node in the perk tree (Skyrim pattern).

#### `crafting::recipe::Recipe`

Defines how inputs are combined to produce outputs.

#### `crafting::knowledge::RecipeGroup`

Named grouping of recipes for UI organisation and bulk operations.

#### `crafting::knowledge::RecipeKnowledge`

Tracks which recipes a player has discovered or unlocked.

#### `crafting::ingredient::RecipeOutput`

Output produced by a recipe. Consult the module-level documentation for the broader usage context and preconditions.

#### `crafting::recipe::RecipeRegistry`

Central registry for all known recipes. Consult the module-level documentation for the broader usage context and...

#### `crafting::station::Station`

A crafting station that filters and processes recipes.

#### `crafting::upgrade::UpgradeNode`

A single node in an upgrade tree. Consult the module-level documentation for the broader usage context and...

#### `crafting::upgrade::UpgradeTree`

Directed acyclic graph of upgrades for weapons or equipment.

### Enums

#### `crafting::quality::Quality`

Output quality tiers for crafted items. Consult the module-level documentation for the broader usage context and...

## Lua API

Exposed under `luna.crafting.*` by `src/lua_api/crafting_api/`.

## crafting — Universal Crafting Backend System

> **Lua namespace:** `luna.crafting`
> **C++ module:** `src/modules/crafting/`
> **Purpose:** Data-driven crafting engine that supports recipes (shaped, shapeless, smelting, currency-style), crafting stations with tiers and proximity, crafting skills with XP/progression, timed and instant crafting, quality tiers and random modifiers, item modification/upgrade/repair, custom Lua scripts per recipe, crafting groups, entity modification via crafting, and random crafting events. Designed to be universal across genres: sandbox (Minecraft), survival (Terraria/Valheim/Don't Starve/Rust), RPG (WoW/Skyrim/PoE), farming sim (Stardew Valley), factory automation (Factorio), action-RPG (Monster Hunter), and MMO (New World).

## Research Foundation — 12-Game Crafting Analysis

This module's design is informed by analysis of crafting systems in 12 commercially successful games across different genres. The universal patterns extracted are:

### Crafting Paradigm Taxonomy

| Archetype | Example Games | Core Primitive |
|-----------|---------------|----------------|
| Spatial Grid | Minecraft | Slot grid → shaped pattern matching |
| List-Based | Terraria, Stardew, Factorio, Rust, Valheim, MHW, Don't Starve, New World | Ingredient multiset → output |
| Currency-State | Path of Exile | Item state machine + orb transitions |
| Skill-Gated | WoW, Skyrim, New World | Profession skill level gates recipes |
| Factory-Throughput | Factorio | Recipe + machine speed → production rate |
| Prototype-Unlock | Don't Starve | One-time station visit → permanent knowledge |
| Weapon-Tree | Monster Hunter: World | Branching DAG upgrade graph |

### Universal Primitives (All 12 Games)

Every crafting system reduces to five primitives:
1. **ItemRef** — typed item identifier + quantity + optional quality
2. **Recipe** — N inputs → M outputs + constraints
3. **Station** — recipe filter + capability level + proximity
4. **CraftContext** — player state + station state + inventory snapshot
5. **CraftResult** — deterministic or probabilistic output set + side effects

### Key Genre Patterns

| Pattern | Games Using It | This Module's Support |
|---------|---------------|----------------------|
| Shaped grid recipes | Minecraft | `RecipeType.SHAPED` with grid dimensions |
| Proximity-union of stations | Terraria | `setProximityRadius()` + station queries |
| Station upgrade tiers | Valheim, New World | `Station:setLevel()` + recipe `minStationLevel` |
| Time-based production | Factorio, Stardew, Minecraft furnace | `CraftJob` with duration + queue |
| Skill color bands (Orange→Grey) | WoW | Configurable skill-up probability curves |
| Blueprint/prototype discovery | Rust, Don't Starve | `RecipeKnowledge` unlock system |
| Quality aging over time | Stardew Cask | `CraftJob` with quality progression |
| Currency item modification | Path of Exile | `ModificationRecipe` type |
| Weapon upgrade tree | Monster Hunter: World | `UpgradeTree` DAG structure |
| Nutritional point algebra | Don't Starve Crock Pot | Tag-based ingredient scoring |
| Factory speed × modules | Factorio | Station speed multiplier + module slots |
| Gear Score range | New World | Skill-dependent quality range rolls |
| Perk tree unlocks | Skyrim | `CraftSkill` perk prerequisites |
| Reforging/rerolling | Terraria, PoE | `ModificationRecipe` with RNG modifiers |
| Fortify stacking loops | Skyrim | Modifier sources composable |

## Reimplementation Notes

- This is a NEW module — no `src/modules/crafting/` exists yet (needs full 12-step scaffold)
- Integrates with `luna.inventory` for ingredient checking and output placement — does NOT duplicate inventory logic
- Integrates with `luna.resource` for resource-type costs (gold, energy, fuel) — recipes can consume both items and resources
- Integrates with `luna.entity` for entity modification recipes (enchanting, upgrading, repairing entity components)
- Integrates with `luna.event` for crafting events: `craftstart`, `craftcomplete`, `craftfail`, `craftdiscovery`
- All recipe definitions are data-driven (Lua tables or TOML files loaded at runtime) — no hardcoded recipes in C++
- The C++ engine provides the recipe registry, validation pipeline, crafting queue, skill tracking, and station management
- Custom Lua scripts per recipe execute in a sandboxed environment via `onCraft`, `onComplete`, `canCraft` callbacks
- Random events use a seeded RNG per craft operation for deterministic replay in multiplayer/save scenarios
- Max 65536 recipes per registry (uint16 ID space, CSF-010)
- Max 256 crafting stations per world (uint8 ID space, CSF-010)
- Max 64 crafting skills per player (uint8 ID space, CSF-010)
- Max 1024 active craft jobs in queue (CSF-010)
- Recipe IDs are strings, but internally hashed to uint32 for fast lookup
- `CraftContext` is a snapshot — it does NOT hold live references to inventory; validate again before consuming
- All Lua callbacks are stored as Lua registry references (same pattern as `luna.inventory`)
- Station proximity uses squared-distance checks to avoid sqrt per frame
- Shaped recipe matching supports mirror/rotation variants via flags
- Tag-based ingredient matching (e.g., `#planks` matches any wood type) avoids N² recipe duplication
- Quality tiers are a configurable enum (default: Normal/Fine/Superior/Excellent/Masterwork/Legendary)
- Crafting skill XP gain uses configurable probability curves (constant, linear, WoW color-band, custom Lua function)

## Dependencies

- `luna.inventory` (ingredient checking, item consumption, output placement)
- `luna.resource` (resource-type cost/reward, fuel consumption)
- `luna.entity` (entity modification recipes — enchanting, upgrading, repairing)
- `luna.event` (crafting lifecycle events)
- `luna.timer` (timed crafting jobs, cooldowns)
- `luna.math` (RNG for probabilistic outputs, quality rolls)

---

## Module Functions

### Registry

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newRegistry` | — | `RecipeRegistry` | Create an empty recipe registry |
| `newRecipe` | `id: string, recipeType?: string` | `Recipe` | Create a recipe definition. Default type: `"shapeless"` |
| `newStation` | `stationType: string, level?: int` | `Station` | Create a crafting station with type and optional level |
| `newCraftSkill` | `name: string` | `CraftSkill` | Create a crafting skill tracker |
| `newCraftQueue` | `maxJobs?: int` | `CraftQueue` | Create a craft job queue. Default max: 1024 |
| `newUpgradeTree` | `name: string` | `UpgradeTree` | Create a weapon/item upgrade DAG |
| `newRecipeGroup` | `name: string` | `RecipeGroup` | Create a named recipe group for UI organization |

### Utility

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `loadRecipes` | `path: string` | `number` | Load recipes from a Lua or TOML file. Returns count loaded |
| `loadRecipesFromTable` | `recipes: table` | `number` | Load recipes from an in-memory table array. Returns count loaded |
| `setQualityTiers` | `tiers: table<string>` | — | Configure quality tier names (ordered low→high). Default: `{"normal","fine","superior","excellent","masterwork","legendary"}` |
| `getQualityTiers` | — | `table<string>` | Get current quality tier names |
| `setDefaultRNG` | `rng: RandomGenerator` | — | Set the RNG used for probabilistic crafting (deterministic seed for multiplayer) |

---

## Type: Recipe

A single recipe definition specifying inputs, outputs, station requirements, skill gates, timing, and custom logic.

**Created by:** `luna.crafting.newRecipe()`

### RecipeType Values

| Type | Description | Pattern Source |
|---|---|---|
| `"shapeless"` | Unordered ingredient list → output; most common pattern | Terraria, Stardew, WoW, Valheim |
| `"shaped"` | Grid-based spatial arrangement; ingredients must occupy specific slots | Minecraft |
| `"smelting"` | Single input + fuel → output over time | Minecraft furnace, Valheim smelter |
| `"modification"` | Apply transform to existing item (reforge, enchant, augment) | PoE orbs, Terraria reforging |
| `"upgrade"` | Upgrade item along a DAG tree node | Monster Hunter weapon trees |
| `"combination"` | Pair-combine two items → discover result | Skyrim alchemy, MHW consumables |
| `"disassembly"` | Break down item → recover partial materials | Rust recycler, Factorio recycler |
| `"aging"` | Time-based quality progression (no active crafting) | Stardew Cask |
| `"transmutation"` | Convert resource types via conversion rules | WoW alchemy transmutation |

### Recipe Definition

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getId` | — | `string` | Unique recipe identifier |
| `getRecipeType` | — | `string` | Recipe type (see RecipeType values) |
| `setRecipeType` | `type: string` | — | Set recipe type |
| `getName` | — | `string` | Display name |
| `setName` | `name: string` | — | Set display name |
| `getDescription` | — | `string` | Recipe description text |
| `setDescription` | `desc: string` | — | Set description |
| `getCategory` | — | `string` | Recipe category for UI grouping |
| `setCategory` | `cat: string` | — | Set category |

### Input Specification

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addInput` | `itemType: string, quantity?: int, quality?: string` | — | Add a required ingredient by exact item type |
| `addTagInput` | `tag: string, quantity?: int` | — | Add a tag-based ingredient (any item with this tag satisfies it, e.g., `"#planks"`) |
| `addResourceInput` | `resourceName: string, amount: number` | — | Add a resource cost (from `luna.resource`) |
| `addFuelInput` | `fuelTag?: string, burnTime?: number` | — | Add fuel requirement (for smelting recipes) |
| `addCatalystInput` | `itemType: string, quantity?: int` | — | Add a catalyst (consumed with configurable % chance, default 0% = not consumed) |
| `setCatalystConsumeChance` | `itemType: string, chance: number` | — | Set probability (0.0–1.0) that a catalyst is consumed |
| `getInputs` | — | `table` | Get all inputs as array of `{type, itemType/tag/resource, quantity, quality?, catalyst?}` |
| `clearInputs` | — | — | Remove all inputs |
| `setGrid` | `width: int, height: int` | — | Set shaped recipe grid dimensions (for `"shaped"` type) |
| `setGridSlot` | `x: int, y: int, itemType: string` | — | Set ingredient at grid position (1-based) |
| `setGridMirror` | `enabled: boolean` | — | Allow horizontal mirror matching for shaped recipes |
| `setGridRotation` | `enabled: boolean` | — | Allow 90°/180°/270° rotation matching for shaped recipes |

### Output Specification

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addOutput` | `itemType: string, quantity?: int, quality?: string` | — | Add a deterministic output item |
| `addResourceOutput` | `resourceName: string, amount: number` | — | Add a resource reward (to `luna.resource`) |
| `addProbabilisticOutput` | `itemType: string, quantity: int, chance: number, quality?: string` | — | Add output with probability (0.0–1.0). Rolled per craft |
| `addRandomModifier` | `modifierPool: string, chance?: number` | — | On craft, roll a random modifier from the named pool (default chance 1.0) |
| `setOutputQualityScaling` | `enabled: boolean` | — | If true, output quality is influenced by crafter's skill level |
| `addByproduct` | `itemType: string, quantity: int, chance: number` | — | Add a byproduct (bonus output, independent of main outputs) |
| `setRemainderItem` | `itemType: string` | — | Item returned to inventory after crafting (e.g., empty bucket after milk recipe) |
| `getOutputs` | — | `table` | Get all outputs as array |

### Station & Location Requirements

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setStationType` | `type: string` | — | Required station type (e.g., `"forge"`, `"alchemy_table"`) |
| `getStationType` | — | `string` | Get required station type |
| `setMinStationLevel` | `level: int` | — | Minimum station tier required (Valheim/New World pattern) |
| `getMinStationLevel` | — | `int` | Get minimum station level |
| `setRequiredBiome` | `biome: string` | — | Must be in this biome to craft (Terraria pattern) |
| `setRequiredLocation` | `location: string` | — | Must be at this named location |
| `addRequiredNearbyStation` | `stationType: string` | — | Additional station that must be within proximity radius (Terraria union pattern) |
| `setHandCraftable` | `enabled: boolean` | — | Whether this recipe can be crafted without a station |

### Skill Requirements

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setSkillRequirement` | `skillName: string, level: int` | — | Minimum skill level required to attempt this recipe |
| `getSkillRequirement` | — | `string, int` | Get required skill name and level |
| `setSkillXP` | `skillName: string, amount: number` | — | XP granted on successful craft |
| `getSkillXP` | — | `string, number` | Get skill XP reward |
| `setSkillUpCurve` | `curve: string` | — | Probability curve for skill-up: `"constant"`, `"linear"`, `"wow_color"`, `"custom"` |
| `setOrangeThreshold` | `level: int` | — | Skill level below which always grants XP (WoW orange) |
| `setYellowThreshold` | `level: int` | — | Skill level for ~60% XP chance (WoW yellow) |
| `setGreenThreshold` | `level: int` | — | Skill level for ~20% XP chance (WoW green) |
| `setGreyThreshold` | `level: int` | — | Skill level above which never grants XP (WoW grey) |

### Timing

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setCraftTime` | `seconds: number` | — | Time to complete craft (0 = instant) |
| `getCraftTime` | — | `number` | Get craft time |
| `setCooldown` | `seconds: number` | — | Cooldown after crafting before recipe can be used again |
| `getCooldown` | — | `number` | Get cooldown |
| `setFuelConsumptionRate` | `rate: number` | — | Fuel consumed per second during timed crafting |

### Conditions & Custom Logic

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setCanCraftCallback` | `fn: function` | — | Custom Lua predicate: `fn(context) → boolean, string?`. Called during validation; return false + reason to block |
| `setOnCraftCallback` | `fn: function` | — | Custom Lua script: `fn(context, result)`. Called when craft begins (for timed) or completes (for instant) |
| `setOnCompleteCallback` | `fn: function` | — | Custom Lua script: `fn(context, result)`. Called when timed craft finishes |
| `setOnFailCallback` | `fn: function` | — | Custom Lua script: `fn(context, reason)`. Called when craft fails |
| `setRandomEventCallback` | `fn: function` | — | Custom Lua script: `fn(context, rng) → event?`. Called per craft to generate random events |
| `addCondition` | `condType: string, value: any` | — | Add a named condition. Built-in types: `"time_of_day"`, `"weather"`, `"quest_flag"`, `"entity_state"` |
| `getConditions` | — | `table` | Get all conditions |

### Knowledge / Discovery

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setKnowledgeMode` | `mode: string` | — | How recipe is discovered: `"always"`, `"on_pickup"`, `"blueprint"`, `"prototype"`, `"skill_level"`, `"quest"`, `"discovery"` |
| `getKnowledgeMode` | — | `string` | Get knowledge mode |
| `setDiscoveryHint` | `hint: string` | — | Hint text shown before recipe is discovered |

### Recipe Linkage

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setUpgradeFrom` | `recipeId: string` | — | This recipe upgrades the output of another recipe (MHW weapon tree pattern) |
| `setUpgradeTo` | `recipeIds: table<string>` | — | Recipes this output can be upgraded to (branching DAG) |
| `setAlternatives` | `recipeIds: table<string>` | — | Alternative recipes producing equivalent output (for stonecutter-style selection) |

---

## Type: Station

A crafting station with type, level, proximity detection, module slots, and speed modifiers.

**Created by:** `luna.crafting.newStation()`

### Identity & Level

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getStationType` | — | `string` | Station type identifier |
| `setStationType` | `type: string` | — | Set station type |
| `getLevel` | — | `int` | Current station level/tier |
| `setLevel` | `level: int` | — | Set station level |
| `getMaxLevel` | — | `int` | Maximum upgrade level |
| `setMaxLevel` | `level: int` | — | Set max level |
| `upgrade` | — | `boolean` | Increment level by 1; returns false if already at max |

### Speed & Modifiers

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getSpeedMultiplier` | — | `number` | Crafting speed multiplier (1.0 = normal) |
| `setSpeedMultiplier` | `mult: number` | — | Set speed multiplier. Higher = faster. Rust model: `2^(stationLevel - recipeLevel)` |
| `getOutputMultiplier` | — | `number` | Output quantity multiplier (Factorio productivity module pattern) |
| `setOutputMultiplier` | `mult: number` | — | Set output multiplier (e.g., 1.1 = 10% bonus output chance) |
| `getQualityBonus` | — | `number` | Bonus to quality roll (New World Azoth pattern) |
| `setQualityBonus` | `bonus: number` | — | Set quality bonus |

### Module Slots (Factorio Pattern)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getModuleSlotCount` | — | `int` | Number of module slots |
| `setModuleSlotCount` | `count: int` | — | Set module slot count |
| `insertModule` | `slot: int, moduleType: string` | `boolean` | Insert a module. Types: `"speed"`, `"productivity"`, `"efficiency"`, `"quality"` |
| `removeModule` | `slot: int` | `string?` | Remove module; returns type or nil |
| `getModule` | `slot: int` | `string?` | Get module type at slot |

### Proximity (Terraria Pattern)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setPosition` | `x: number, y: number` | — | Set station world position |
| `getPosition` | — | `number, number` | Get station world position |
| `setProximityRadius` | `radius: number` | — | Radius within which this station is considered "nearby" |
| `getProximityRadius` | — | `number` | Get proximity radius |
| `isInRange` | `x: number, y: number` | `boolean` | Check if a point is within proximity radius |

### Physical Upgrades (Valheim Pattern)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addAttachment` | `attachmentType: string` | `boolean` | Add a physical upgrade attachment (e.g., "chopping_block"). Returns false if duplicate |
| `removeAttachment` | `attachmentType: string` | `boolean` | Remove an attachment |
| `getAttachments` | — | `table<string>` | List all attached upgrades |
| `getEffectiveLevel` | — | `int` | Station level considering attachments (base level + attachment count or custom formula) |
| `setLevelFormula` | `fn: function` | — | Custom Lua function: `fn(baseLevel, attachments) → effectiveLevel` |

### Station State

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `isActive` | — | `boolean` | Whether station is powered/usable |
| `setActive` | `active: boolean` | — | Enable/disable the station |
| `setRequiresCover` | `enabled: boolean` | — | Whether station needs roof/cover (Valheim pattern) |
| `hasCover` | — | `boolean` | Check if station has cover (game logic sets this) |
| `setCover` | `covered: boolean` | — | Set cover state |
| `getFuelLevel` | — | `number` | Current fuel amount |
| `setFuelLevel` | `amount: number` | — | Set fuel amount |
| `addFuel` | `amount: number` | — | Add fuel |
| `consumeFuel` | `amount: number` | `boolean` | Consume fuel; returns false if insufficient |

---

## Type: CraftSkill

A player's crafting skill in a specific profession, with XP tracking, level progression, specializations, and perk trees.

**Created by:** `luna.crafting.newCraftSkill()`

### Core Progression

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName` | — | `string` | Skill/profession name |
| `getLevel` | — | `int` | Current skill level |
| `getMaxLevel` | — | `int` | Maximum skill level |
| `setMaxLevel` | `level: int` | — | Set max level |
| `getXP` | — | `number` | Current XP |
| `getXPForNextLevel` | — | `number` | XP required for next level |
| `addXP` | `amount: number` | `boolean` | Add XP; returns true if leveled up |
| `setXPCurve` | `curve: string` | — | XP-to-level formula: `"linear"`, `"quadratic"`, `"exponential"`, `"custom"` |
| `setCustomXPCurve` | `fn: function` | — | Custom: `fn(level) → xpRequired` |

### Skill-Up Probability (WoW Model)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getSkillUpChance` | `recipe: Recipe` | `number` | Calculate skill-up probability for this recipe (0.0–1.0) |
| `getRecipeColor` | `recipe: Recipe` | `string` | Get recipe difficulty color: `"orange"`, `"yellow"`, `"green"`, `"grey"` |

### Specializations (WoW/Skyrim Pattern)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addSpecialization` | `name: string` | — | Define a specialization branch |
| `chooseSpecialization` | `name: string` | `boolean` | Lock in a specialization; returns false if already specialized or name invalid |
| `getSpecialization` | — | `string?` | Get chosen specialization or nil |
| `getAvailableSpecializations` | — | `table<string>` | List available specializations |

### Perk Tree (Skyrim Pattern)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addPerk` | `perkId: string, requiredLevel: int, prerequisites?: table<string>` | — | Define a perk node with level requirement and prerequisite perks |
| `unlockPerk` | `perkId: string` | `boolean` | Unlock a perk; returns false if prerequisites not met or level too low |
| `hasPerk` | `perkId: string` | `boolean` | Check if perk is unlocked |
| `getPerks` | — | `table` | Get all defined perks with unlock status |
| `getAvailablePerks` | — | `table<string>` | Get perks whose prerequisites are met but not yet unlocked |

### Mastery Bonuses

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getSpeedBonus` | — | `number` | Crafting speed bonus from skill level (0.0 = no bonus) |
| `getQualityBonus` | — | `number` | Quality roll bonus from skill level |
| `getYieldBonus` | — | `number` | Output yield bonus from skill level (New World pattern: up to 30% at max) |
| `setMasteryBonuses` | `fn: function` | — | Custom: `fn(level, maxLevel) → {speed, quality, yield}` |

---

## Type: RecipeRegistry

Central recipe storage with lookup, filtering, and availability queries.

**Created by:** `luna.crafting.newRegistry()`

### Recipe Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `register` | `recipe: Recipe` | — | Register a recipe. Errors if ID already exists |
| `unregister` | `recipeId: string` | — | Remove a recipe |
| `get` | `recipeId: string` | `Recipe?` | Look up recipe by ID |
| `getAll` | — | `table<Recipe>` | Get all registered recipes |
| `getCount` | — | `int` | Total registered recipes |

### Queries

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getByStation` | `stationType: string` | `table<Recipe>` | All recipes requiring this station type |
| `getByCategory` | `category: string` | `table<Recipe>` | All recipes in a category |
| `getByOutput` | `itemType: string` | `table<Recipe>` | All recipes producing this item |
| `getByInput` | `itemType: string` | `table<Recipe>` | All recipes requiring this item as input |
| `getByTag` | `tag: string` | `table<Recipe>` | All recipes using this tag-based ingredient |
| `getBySkill` | `skillName: string, maxLevel?: int` | `table<Recipe>` | All recipes for a skill, optionally filtered by max required level |
| `getByGroup` | `groupName: string` | `table<Recipe>` | All recipes in a named group |

### Availability Queries

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getCraftable` | `context: table` | `table<Recipe>` | All recipes the player can craft right now. Context: `{inventory, skills, knownRecipes, station?, resources?}` |
| `getDiscovered` | `knownRecipes: table` | `table<Recipe>` | All recipes the player has discovered |
| `getUndiscovered` | `knownRecipes: table` | `table<Recipe>` | All recipes not yet discovered |
| `getByDifficulty` | `skillName: string, skillLevel: int` | `table<{recipe, color}>` | Recipes with WoW-style difficulty color |

### Validation

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `validate` | `recipeId: string, context: table` | `boolean, string?` | Full validation: inputs, station, skill, conditions. Returns (true) or (false, reason) |
| `validateInputs` | `recipeId: string, inventory: Inventory` | `boolean, string?` | Check if inventory has all required inputs |
| `validateStation` | `recipeId: string, station: Station?` | `boolean, string?` | Check if station meets requirements |
| `validateSkill` | `recipeId: string, skills: table` | `boolean, string?` | Check if skills meet requirements |
| `validateConditions` | `recipeId: string, context: table` | `boolean, string?` | Check custom conditions |

---

## Type: CraftQueue

Manages active crafting jobs (timed crafts), with priority, cancellation, and progress tracking.

**Created by:** `luna.crafting.newCraftQueue()`

### Queue Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `submit` | `recipe: Recipe, context: table, station?: Station` | `CraftJob` | Submit a craft job. Validates and begins immediately or queues |
| `cancel` | `jobId: int` | `boolean` | Cancel a queued or in-progress job; returns consumed partial inputs if applicable |
| `update` | `dt: number` | `table<CraftResult>` | Tick all active jobs; returns array of completed results this frame |
| `getActiveJobs` | — | `table<CraftJob>` | Get all in-progress jobs |
| `getQueuedJobs` | — | `table<CraftJob>` | Get all waiting jobs |
| `getJobCount` | — | `int` | Total jobs (active + queued) |
| `clear` | — | — | Cancel all jobs |
| `setMaxConcurrent` | `n: int` | — | Max simultaneous active jobs (default 1) |

### CraftJob Fields

| Field | Type | Description |
|---|---|---|
| `id` | `int` | Unique job ID |
| `recipeId` | `string` | Recipe being crafted |
| `progress` | `number` | 0.0 to 1.0 completion ratio |
| `elapsed` | `number` | Seconds elapsed |
| `duration` | `number` | Total craft time (after speed modifiers) |
| `status` | `string` | `"queued"`, `"active"`, `"complete"`, `"cancelled"`, `"failed"` |
| `station` | `Station?` | Station used (nil for hand crafting) |
| `qualityResult` | `string?` | Resolved quality tier (determined at completion) |

---

## Type: RecipeKnowledge

Tracks which recipes a player has discovered/unlocked, supporting multiple discovery mechanisms.

### Knowledge Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `discover` | `recipeId: string, source?: string` | — | Mark recipe as known. Source: `"pickup"`, `"blueprint"`, `"prototype"`, `"skill"`, `"quest"`, `"research"`, `"npc"` |
| `forget` | `recipeId: string` | — | Remove recipe knowledge (for wipe mechanics like Rust) |
| `isKnown` | `recipeId: string` | `boolean` | Check if recipe is discovered |
| `getKnown` | — | `table<string>` | Get all known recipe IDs |
| `getKnownCount` | — | `int` | Count of known recipes |
| `setAutoDiscover` | `enabled: boolean` | — | Auto-discover all recipes (Terraria/Valheim "always visible" mode) |
| `isAutoDiscover` | — | `boolean` | Check if auto-discovery is enabled |

### Prototype System (Don't Starve Pattern)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `prototype` | `recipeId: string, station: Station` | `boolean` | Prototype a recipe at a station; permanently learns it. Returns false if wrong station |
| `isPrototyped` | `recipeId: string` | `boolean` | Check if recipe has been prototyped |
| `getPrototypeSanityBonus` | — | `number` | Sanity/XP bonus for first prototype (configurable) |
| `setPrototypeSanityBonus` | `bonus: number` | — | Set prototype bonus |

### Blueprint System (Rust Pattern)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `research` | `recipeId: string, scrapCost: number` | `boolean` | Research a recipe by consuming scrap/resources. Returns false if can't afford |
| `setResearchCost` | `recipeId: string, cost: number` | — | Set scrap cost for researching this recipe |
| `getResearchCost` | `recipeId: string` | `number` | Get research cost |

---

## Type: UpgradeTree

A directed acyclic graph (DAG) of item upgrades for weapon/equipment progression (Monster Hunter pattern).

**Created by:** `luna.crafting.newUpgradeTree()`

### Tree Construction

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addNode` | `nodeId: string, recipeId: string, outputItemType: string` | — | Add an upgrade node |
| `addEdge` | `fromNode: string, toNode: string` | — | Connect two nodes (from → to upgrade path) |
| `getRootNodes` | — | `table<string>` | Get all root nodes (no incoming edges) |
| `getChildren` | `nodeId: string` | `table<string>` | Get available upgrades from this node |
| `getParent` | `nodeId: string` | `string?` | Get the prerequisite node |
| `getNode` | `nodeId: string` | `table?` | Get node data including recipe and output |
| `canUpgrade` | `nodeId: string, context: table` | `boolean, string?` | Check if upgrade is possible given current inventory/skills |
| `getPath` | `fromNode: string, toNode: string` | `table<string>?` | Get upgrade path between two nodes (nil if no path) |
| `getAllNodes` | — | `table` | Get all nodes with edges |

---

## Type: RecipeGroup

Named grouping of recipes for UI organization and bulk operations.

**Created by:** `luna.crafting.newRecipeGroup()`

### Group Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName` | — | `string` | Group name |
| `setName` | `name: string` | — | Set group name |
| `getIcon` | — | `string` | Icon identifier for UI |
| `setIcon` | `icon: string` | — | Set icon |
| `addRecipe` | `recipeId: string` | — | Add recipe to group |
| `removeRecipe` | `recipeId: string` | — | Remove recipe from group |
| `getRecipes` | — | `table<string>` | Get all recipe IDs in group |
| `getOrder` | — | `int` | Sort order for UI |
| `setOrder` | `order: int` | — | Set sort order |

---

## Type: ModifierPool

Named collection of random modifiers that can be applied to crafted items (Terraria reforging, PoE affixes).

### Pool Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName` | — | `string` | Pool identifier |
| `addModifier` | `name: string, weight: int, effects: table` | — | Add a modifier with weighted probability. Effects: `{stat=string, value=number, type=string}` |
| `removeModifier` | `name: string` | — | Remove a modifier |
| `roll` | `rng?: RandomGenerator` | `table` | Roll a random modifier from the pool (weighted) |
| `getModifiers` | — | `table` | Get all modifiers with weights |
| `getTotalWeight` | — | `int` | Sum of all weights |

---

## Crafting Modes

Different games use fundamentally different crafting interaction patterns. This module supports all of them through configuration.

### Mode: Minecraft-Style (Grid/Shaped)

```lua
local registry = luna.crafting.newRegistry()

-- Define a shaped 3x3 recipe
local pickaxe = luna.crafting.newRecipe("diamond_pickaxe", "shaped")
pickaxe:setName("Diamond Pickaxe")
pickaxe:setGrid(3, 3)
pickaxe:setGridSlot(1, 1, "diamond")
pickaxe:setGridSlot(2, 1, "diamond")
pickaxe:setGridSlot(3, 1, "diamond")
pickaxe:setGridSlot(2, 2, "stick")
pickaxe:setGridSlot(2, 3, "stick")
pickaxe:setGridMirror(true)
pickaxe:addOutput("diamond_pickaxe", 1)
pickaxe:setHandCraftable(false)
pickaxe:setStationType("crafting_table")
pickaxe:setKnowledgeMode("on_pickup")
registry:register(pickaxe)

-- Shapeless recipe (any arrangement)
local planks = luna.crafting.newRecipe("oak_planks", "shapeless")
planks:addInput("oak_log", 1)
planks:addOutput("oak_plank", 4)
planks:setHandCraftable(true)
planks:setKnowledgeMode("always")
registry:register(planks)
```

### Mode: Terraria-Style (Station Proximity)

```lua
-- Station proximity union
local anvil = luna.crafting.newStation("iron_anvil", 1)
anvil:setPosition(100, 200)
anvil:setProximityRadius(128)  -- ~9 tiles

local forge = luna.crafting.newStation("hellforge", 2)
forge:setPosition(116, 200)
forge:setProximityRadius(128)

-- Recipe requiring nearby forge + anvil
local blade = luna.crafting.newRecipe("nights_edge", "shapeless")
blade:addInput("lights_bane", 1)
blade:addInput("muramasa", 1)
blade:addInput("blade_of_grass", 1)
blade:addInput("fiery_greatsword", 1)
blade:setStationType("iron_anvil")
blade:addRequiredNearbyStation("hellforge")
blade:addOutput("nights_edge", 1)
blade:addRandomModifier("weapon_prefixes", 0.75)  -- 75% chance modifier on first craft
blade:setKnowledgeMode("always")
registry:register(blade)
```

### Mode: WoW-Style (Skill-Gated Profession)

```lua
-- Skill setup
local blacksmithing = luna.crafting.newCraftSkill("blacksmithing")
blacksmithing:setMaxLevel(300)
blacksmithing:setXPCurve("linear")
blacksmithing:addSpecialization("armorsmith")
blacksmithing:addSpecialization("weaponsmith")

-- Skill-gated recipe with color bands
local thorium_helm = luna.crafting.newRecipe("thorium_helm", "shapeless")
thorium_helm:addInput("thorium_bar", 12)
thorium_helm:addInput("star_ruby", 1)
thorium_helm:setStationType("forge")
thorium_helm:addOutput("thorium_helm", 1)
thorium_helm:setSkillRequirement("blacksmithing", 250)
thorium_helm:setSkillXP("blacksmithing", 1)
thorium_helm:setSkillUpCurve("wow_color")
thorium_helm:setOrangeThreshold(250)
thorium_helm:setYellowThreshold(260)
thorium_helm:setGreenThreshold(275)
thorium_helm:setGreyThreshold(290)
registry:register(thorium_helm)
```

### Mode: Valheim-Style (Station Tiers + Upgrades)

```lua
-- Station with attachment upgrades
local workbench = luna.crafting.newStation("workbench", 1)
workbench:setMaxLevel(5)
workbench:setRequiresCover(true)
workbench:setCover(true)

workbench:addAttachment("chopping_block")  -- +1 effective level
workbench:addAttachment("tanning_rack")    -- +1 effective level
-- effectiveLevel = 1 + 2 = 3

-- Recipe requires workbench level 3
local iron_sword = luna.crafting.newRecipe("iron_sword", "shapeless")
iron_sword:addInput("iron", 20)
iron_sword:addInput("wood", 3)
iron_sword:addInput("leather", 2)
iron_sword:setStationType("workbench")
iron_sword:setMinStationLevel(3)
iron_sword:addOutput("iron_sword", 1)
iron_sword:setKnowledgeMode("always")
registry:register(iron_sword)
```

### Mode: Factorio-Style (Factory Throughput)

```lua
-- Station with speed/productivity modules
local assembler = luna.crafting.newStation("assembling_machine", 3)
assembler:setSpeedMultiplier(1.25)  -- Assembling Machine 3 base speed
assembler:setModuleSlotCount(4)
assembler:insertModule(1, "speed")       -- +50% speed each
assembler:insertModule(2, "speed")
assembler:insertModule(3, "productivity") -- +4% output each
assembler:insertModule(4, "productivity")

-- Timed recipe
local green_circuit = luna.crafting.newRecipe("electronic_circuit", "shapeless")
green_circuit:addInput("iron_plate", 1)
green_circuit:addInput("copper_cable", 3)
green_circuit:setCraftTime(0.5)  -- base 0.5 seconds
green_circuit:addOutput("electronic_circuit", 1)
green_circuit:setStationType("assembling_machine")
registry:register(green_circuit)

-- Queue handles throughput
local queue = luna.crafting.newCraftQueue(100)
-- production_rate = (machineSpeed / craftTime) * (1 + productivityBonus)
```

### Mode: Stardew-Style (Time + Quality Aging)

```lua
-- Aging recipe (Cask)
local wine_aging = luna.crafting.newRecipe("iridium_wine", "aging")
wine_aging:addInput("wine", 1)
wine_aging:setCraftTime(56 * 24 * 60)  -- 56 in-game days in minutes
wine_aging:addOutput("wine", 1)
wine_aging:setOutputQualityScaling(true)
wine_aging:setStationType("cask")
-- Quality progression over time: normal → silver → gold → iridium
registry:register(wine_aging)
```

### Mode: PoE-Style (Currency Modification)

```lua
-- Modification recipe (orb applied to existing item)
local chaos_orb = luna.crafting.newRecipe("chaos_reroll", "modification")
chaos_orb:addInput("chaos_orb", 1)   -- consumed
chaos_orb:addCatalystInput("rare_item", 1)  -- target item (not consumed by default)
chaos_orb:setCatalystConsumeChance("rare_item", 0.0)  -- item modified, not consumed
chaos_orb:addRandomModifier("rare_affixes", 1.0)  -- always reroll all mods
chaos_orb:setOnCraftCallback(function(ctx, result)
    -- Reroll all modifiers on the target item
    local item = ctx.catalysts["rare_item"]
    item:clearModifiers()
    for i = 1, math.random(4, 6) do
        item:addModifier(ctx.registry:getModifierPool("rare_affixes"):roll(ctx.rng))
    end
end)
chaos_orb:setKnowledgeMode("always")
registry:register(chaos_orb)
```

### Mode: Monster Hunter-Style (Upgrade Tree)

```lua
-- Weapon upgrade tree (DAG)
local tree = luna.crafting.newUpgradeTree("great_sword")
tree:addNode("iron_sword_1", "forge_iron_sword_1", "iron_sword_1")
tree:addNode("iron_sword_2", "upgrade_iron_sword_2", "iron_sword_2")
tree:addNode("iron_sword_3", "upgrade_iron_sword_3", "iron_sword_3")
tree:addNode("steel_sword_1", "upgrade_steel_sword", "steel_sword")
tree:addNode("bone_sword_1", "forge_bone_sword_1", "bone_sword_1")
tree:addNode("bone_sword_2", "upgrade_bone_sword_2", "bone_sword_2")

-- Linear chain
tree:addEdge("iron_sword_1", "iron_sword_2")
tree:addEdge("iron_sword_2", "iron_sword_3")
-- Branch
tree:addEdge("iron_sword_3", "steel_sword_1")
-- Separate tree root
tree:addEdge("bone_sword_1", "bone_sword_2")
```

### Mode: Rust-Style (Blueprint Research + Workbench Tiers)

```lua
-- Blueprint research
local knowledge = luna.crafting.RecipeKnowledge()
knowledge:setResearchCost("ak47", 750)  -- 750 scrap

-- Research at research table
local success = knowledge:research("ak47", player_scrap)

-- Workbench speed scaling: 2^(stationTier - recipeTier)
local bench = luna.crafting.newStation("workbench", 3)
bench:setSpeedMultiplier(1.0)  -- base; actual speed calculated from tier difference

local ak = luna.crafting.newRecipe("ak47", "shapeless")
ak:addInput("metal_fragments", 50)
ak:addInput("wood", 200)
ak:addInput("high_quality_metal", 25)
ak:addInput("metal_spring", 4)
ak:setCraftTime(45)  -- base 45 seconds at same tier
ak:setStationType("workbench")
ak:setMinStationLevel(3)
ak:addOutput("ak47", 1)
ak:setKnowledgeMode("blueprint")
registry:register(ak)
```

### Mode: Don't Starve-Style (Prototype + Point-Based Cooking)

```lua
-- Prototype system
local knowledge = luna.crafting.RecipeKnowledge()
local science_machine = luna.crafting.newStation("science_machine", 1)

-- First time crafting near science machine = permanent unlock
knowledge:prototype("log_suit", science_machine)
-- Returns true + prototypeSanityBonus
-- From now on, player can craft log_suit anywhere

-- Crock Pot point-based cooking
local meatballs = luna.crafting.newRecipe("meatballs", "combination")
meatballs:setOnCraftCallback(function(ctx, result)
    -- Point algebra: need meat >= 0.5, no restrictions on filler
    local meat_pts = 0
    for _, input in ipairs(ctx.inputs) do
        meat_pts = meat_pts + (input.tags["meat"] or 0)
    end
    if meat_pts < 0.5 then
        return false, "Not enough meat"
    end
    return true
end)
```

---

## Crafting Pipeline (Internal Flow)

```
Player Action: "Craft [recipe_id]"
         │
         ▼
  ┌─────────────────────┐
  │ 1. VALIDATE INPUTS  │ ← Check inventory has all ingredients
  │    validateInputs()  │   Check resources (luna.resource)
  └─────────┬───────────┘   Check catalysts present
            │
            ▼
  ┌─────────────────────┐
  │ 2. VALIDATE STATION │ ← Check station type matches
  │    validateStation() │   Check station level ≥ minLevel
  └─────────┬───────────┘   Check proximity (Terraria union)
            │                Check cover (Valheim)
            ▼                Check fuel (smelting)
  ┌─────────────────────┐
  │ 3. VALIDATE SKILL   │ ← Check skill level ≥ requirement
  │    validateSkill()   │   Check specialization (WoW)
  └─────────┬───────────┘   Check perk prerequisites (Skyrim)
            │
            ▼
  ┌─────────────────────┐
  │ 4. VALIDATE CONDS   │ ← Run canCraftCallback (custom Lua)
  │    validateConds()   │   Check conditions (biome, weather, quest flags)
  └─────────┬───────────┘   Run random event callback
            │
            ▼
  ┌─────────────────────┐
  │ 5. CONSUME INPUTS   │ ← Remove items from inventory
  │    consumeInputs()   │   Deduct resources
  └─────────┬───────────┘   Check catalyst consumption chance
            │                Consume fuel (smelting)
            ▼
  ┌─────────────────────────────────────────┐
  │ 6. RESOLVE OUTPUTS                      │
  │    If instant:                          │
  │      → deterministic outputs            │
  │      → probabilistic output rolls       │
  │      → quality roll (skill-dependent)   │
  │      → random modifier roll             │
  │      → byproduct rolls                  │
  │      → remainder items                  │
  │    If timed:                            │
  │      → Create CraftJob in CraftQueue   │
  │      → Outputs resolved on completion   │
  └─────────┬───────────────────────────────┘
            │
            ▼
  ┌──────────────────────┐
  │ 7. APPLY SIDE EFFECTS│ ← Add XP to CraftSkill
  │                      │   Fire onCraft/onComplete callback
  └─────────┬────────────┘   Fire luna.event "craftcomplete"
            │                Update RecipeKnowledge (first-craft discovery)
            ▼
      CraftResult {
        success, outputs, consumed,
        skillXP, qualityTier, modifiers,
        randomEvent, byproducts
      }
```

---

## Entity Modification via Crafting

Crafting can modify existing entities through the `luna.entity` integration. This supports enchanting, repairing, upgrading, and modifying entity components.

### Entity Modification Recipes

```lua
-- Enchant a weapon (adds component data)
local enchant_fire = luna.crafting.newRecipe("enchant_fire_weapon", "modification")
enchant_fire:addInput("fire_essence", 3)
enchant_fire:addResourceInput("mana", 50)
enchant_fire:setStationType("enchanting_table")
enchant_fire:setSkillRequirement("enchanting", 15)
enchant_fire:setOnCraftCallback(function(ctx, result)
    local entity = ctx.targetEntity
    if entity:hasComponent("weapon") then
        local weapon = entity:getComponent("weapon")
        weapon.element = "fire"
        weapon.elementDamage = 25 + ctx.skills["enchanting"] * 2
        entity:addComponent("particle_trail", {effect = "fire_trail"})
        return true
    end
    return false, "Target must be a weapon"
end)
registry:register(enchant_fire)

-- Repair an item (restore durability)
local repair_armor = luna.crafting.newRecipe("repair_armor", "modification")
repair_armor:addInput("repair_kit", 1)
repair_armor:setStationType("workbench")
repair_armor:setOnCraftCallback(function(ctx, result)
    local entity = ctx.targetEntity
    if entity:hasComponent("durability") then
        local dur = entity:getComponent("durability")
        dur.current = dur.max
        return true
    end
    return false, "Target has no durability"
end)
registry:register(repair_armor)

-- Upgrade item along tree (Monster Hunter pattern)
local upgrade_sword = luna.crafting.newRecipe("upgrade_iron_sword_2", "upgrade")
upgrade_sword:addInput("iron_ore", 5)
upgrade_sword:addInput("monster_bone", 3)
upgrade_sword:addResourceInput("zenny", 500)
upgrade_sword:setStationType("smithy")
upgrade_sword:setOnCraftCallback(function(ctx, result)
    local entity = ctx.targetEntity
    local weapon = entity:getComponent("weapon")
    weapon.attack = weapon.attack + 20
    weapon.sharpness = "green"
    weapon.rarity = weapon.rarity + 1
    return true
end)
registry:register(upgrade_sword)
```

---

## Random Events System

Each craft can trigger random events via the `setRandomEventCallback`. Events are rolled using the seeded RNG for reproducibility.

### Built-in Event Types

| Event | Description | Pattern Source |
|---|---|---|
| `critical_success` | Double output quantity or quality tier bump | General RPG |
| `ingredient_preserved` | One ingredient not consumed (refunded) | Terraria Alchemy Table (33% chance) |
| `bonus_byproduct` | Extra item dropped alongside main output | Factorio productivity |
| `quality_upgrade` | Output quality increased by one tier | New World skill bonus |
| `tool_damage` | Crafting tool loses durability | Survival games |
| `discovery` | Discover a related recipe | Skyrim alchemy |
| `contamination` | Output gains a negative modifier | Risk/reward |
| `critical_failure` | Inputs consumed but no output | Hardcore mode |
| `rare_material_return` | Rare ingredient partially returned | Economy balance |
| `inspiration` | Temporary crafting speed buff | Stardew Valley "lucky day" |

### Random Event Example

```lua
local recipe = luna.crafting.newRecipe("steel_sword", "shapeless")
-- ... inputs/outputs ...

recipe:setRandomEventCallback(function(ctx, rng)
    local roll = rng:random()

    -- 5% critical success
    if roll < 0.05 then
        return {
            type = "critical_success",
            message = "Masterful craftsmanship!",
            qualityBoost = 1,  -- bump quality tier
        }
    end

    -- 10% ingredient preservation
    if roll < 0.15 then
        local preserved = ctx.inputs[rng:random(1, #ctx.inputs)]
        return {
            type = "ingredient_preserved",
            message = "Careful work preserved a " .. preserved.itemType,
            preservedItem = preserved,
        }
    end

    -- 2% critical failure (if hardcore mode)
    if ctx.hardcoreMode and roll > 0.98 then
        return {
            type = "critical_failure",
            message = "The craft failed catastrophically!",
            destroyOutputs = true,
        }
    end

    return nil  -- no event
end)
```

---

## Disassembly / Recycling

Crafting supports reverse recipes for breaking down items into components.

```lua
local recycle_sword = luna.crafting.newRecipe("recycle_iron_sword", "disassembly")
recycle_sword:addInput("iron_sword", 1)
recycle_sword:addOutput("iron_ore", 3)                  -- 60% of original cost
recycle_sword:addProbabilisticOutput("leather", 1, 0.5)  -- 50% chance leather
recycle_sword:setStationType("recycler")
recycle_sword:setCraftTime(5.0)
registry:register(recycle_sword)
```

---

## Recipe File Format (TOML)

Recipes can be loaded from TOML files for data-driven content:

```toml
[[recipe]]
id = "iron_sword"
name = "Iron Sword"
type = "shapeless"
category = "weapons"
group = "swords"
station = "forge"
min_station_level = 1
craft_time = 0
knowledge_mode = "always"

[[recipe.input]]
item = "iron_ingot"
quantity = 3

[[recipe.input]]
item = "wood"
quantity = 1

[[recipe.output]]
item = "iron_sword"
quantity = 1

[recipe.skill]
name = "blacksmithing"
required_level = 5
xp = 25
curve = "wow_color"
orange = 5
yellow = 15
green = 25
grey = 35

[[recipe]]
id = "health_potion"
name = "Health Potion"
type = "shapeless"
category = "potions"
station = "alchemy_table"
craft_time = 3.0
knowledge_mode = "skill_level"

[[recipe.input]]
item = "red_herb"
quantity = 2

[[recipe.input]]
tag = "#mushroom"
quantity = 1

[[recipe.output]]
item = "health_potion"
quantity = 1

[[recipe.probabilistic_output]]
item = "empty_vial"
quantity = 1
chance = 0.3

[recipe.condition]
type = "time_of_day"
value = "night"
```

## Recipe File Format (Lua)

```lua
return {
    {
        id = "iron_sword",
        name = "Iron Sword",
        type = "shapeless",
        category = "weapons",
        group = "swords",
        station = "forge",
        min_station_level = 1,
        inputs = {
            {item = "iron_ingot", quantity = 3},
            {item = "wood", quantity = 1},
        },
        outputs = {
            {item = "iron_sword", quantity = 1},
        },
        skill = {
            name = "blacksmithing",
            required_level = 5,
            xp = 25,
            curve = "wow_color",
            orange = 5, yellow = 15, green = 25, grey = 35,
        },
    },
}
```

---

## Crafting Groups

Groups organize recipes for UI presentation. Games use different organizational models:

| Model | Games | Implementation |
|---|---|---|
| Category tabs | Terraria, Stardew, Don't Starve | `RecipeGroup` per tab |
| Profession lists | WoW, New World | `RecipeGroup` per profession |
| Station menus | Valheim, Minecraft | Group by station type |
| Tech tree | Factorio | Group by research dependency |
| Weapon type trees | Monster Hunter | Group by weapon class |

```lua
-- Organize recipes into groups
local swords = luna.crafting.newRecipeGroup("swords")
swords:setIcon("sword_icon")
swords:setOrder(1)
swords:addRecipe("iron_sword")
swords:addRecipe("steel_sword")
swords:addRecipe("mithril_sword")

local potions = luna.crafting.newRecipeGroup("potions")
potions:setIcon("potion_icon")
potions:setOrder(2)
potions:addRecipe("health_potion")
potions:addRecipe("mana_potion")
```

---

## Quality System

Configurable quality tiers that affect output properties. Multiple quality models supported:

### Quality Models from Research

| Model | Games | Description |
|---|---|---|
| None | Terraria, Rust | Binary: item exists or not |
| Star tiers | Stardew Valley | Normal / Silver★ / Gold★★ / Iridium★★★ |
| Named tiers | Skyrim | Fine → Superior → Exquisite → Flawless → Epic → Legendary |
| Gear Score | New World | Numeric range determined by material tier × skill level |
| Affix state | PoE | Normal / Magic / Rare / Unique / Corrupted |
| Upgrade levels | Valheim | Item L1 → L2 → L3 → L4 |

### Quality Configuration

```lua
-- Default quality tiers
luna.crafting.setQualityTiers({
    "normal", "fine", "superior", "excellent", "masterwork", "legendary"
})

-- Quality roll depends on crafter's skill
-- Higher skill = better chance of higher quality
-- Formula: qualityIndex = clamp(skillLevel / maxSkillLevel * #tiers + stationBonus + rng, 1, #tiers)
```

---

## Enums

### RecipeType
`"shapeless"`, `"shaped"`, `"smelting"`, `"modification"`, `"upgrade"`, `"combination"`, `"disassembly"`, `"aging"`, `"transmutation"`

### KnowledgeMode
`"always"`, `"on_pickup"`, `"blueprint"`, `"prototype"`, `"skill_level"`, `"quest"`, `"discovery"`

### SkillUpCurve
`"constant"`, `"linear"`, `"wow_color"`, `"custom"`

### XPCurve
`"linear"`, `"quadratic"`, `"exponential"`, `"custom"`

### ModuleType
`"speed"`, `"productivity"`, `"efficiency"`, `"quality"`

### CraftJobStatus
`"queued"`, `"active"`, `"complete"`, `"cancelled"`, `"failed"`

### ConditionType
`"time_of_day"`, `"weather"`, `"quest_flag"`, `"entity_state"`, `"biome"`, `"location"`, `"custom"`

### RandomEventType
`"critical_success"`, `"ingredient_preserved"`, `"bonus_byproduct"`, `"quality_upgrade"`, `"tool_damage"`, `"discovery"`, `"contamination"`, `"critical_failure"`, `"rare_material_return"`, `"inspiration"`

---

## Usage Examples

### Complete RPG Crafting Setup

```lua
function luna.load()
    -- Create registry and load recipes from file
    craftRegistry = luna.crafting.newRegistry()
    local count = craftRegistry:loadRecipes("data/recipes.toml")
    print("Loaded " .. count .. " recipes")

    -- Set up crafting skills
    playerSkills = {
        blacksmithing = luna.crafting.newCraftSkill("blacksmithing"),
        alchemy = luna.crafting.newCraftSkill("alchemy"),
        enchanting = luna.crafting.newCraftSkill("enchanting"),
    }
    playerSkills.blacksmithing:setMaxLevel(100)
    playerSkills.blacksmithing:setXPCurve("quadratic")
    playerSkills.blacksmithing:addSpecialization("armorsmith")
    playerSkills.blacksmithing:addSpecialization("weaponsmith")

    -- Set up recipe knowledge
    knowledge = luna.crafting.RecipeKnowledge()
    knowledge:setAutoDiscover(false)  -- must learn recipes

    -- Create craft queue for timed recipes
    craftQueue = luna.crafting.newCraftQueue(64)
    craftQueue:setMaxConcurrent(3)  -- 3 simultaneous crafts

    -- Place stations in world
    forge = luna.crafting.newStation("forge", 2)
    forge:setPosition(400, 300)
    forge:setProximityRadius(64)
    forge:addAttachment("bellows")  -- increases effective level

    -- Set up quality tiers
    luna.crafting.setQualityTiers({
        "common", "uncommon", "rare", "epic", "legendary"
    })
end

function luna.update(dt)
    -- Process timed crafts
    local completed = craftQueue:update(dt)
    for _, result in ipairs(completed) do
        if result.success then
            for _, output in ipairs(result.outputs) do
                playerInventory:addItem(output.item, output.quantity)
            end
            if result.randomEvent then
                handleRandomEvent(result.randomEvent)
            end
        end
    end
end

-- Attempt to craft
function tryCraft(recipeId)
    local context = {
        inventory = playerInventory,
        skills = playerSkills,
        knownRecipes = knowledge:getKnown(),
        station = forge,
        resources = playerResources,
    }

    local ok, reason = craftRegistry:validate(recipeId, context)
    if not ok then
        showMessage("Cannot craft: " .. reason)
        return
    end

    local recipe = craftRegistry:get(recipeId)
    if recipe:getCraftTime() > 0 then
        -- Timed craft → queue
        local job = craftQueue:submit(recipe, context, forge)
        showProgressBar(job)
    else
        -- Instant craft → immediate result
        local result = craftRegistry:craft(recipeId, context, forge)
        for _, output in ipairs(result.outputs) do
            playerInventory:addItem(output.item, output.quantity)
        end
    end
end
```

### Survival Crafting with Discovery

```lua
-- Don't Starve-style prototype discovery
function discoverRecipe(recipeId, station)
    if knowledge:isKnown(recipeId) then
        -- Already known, craft anywhere
        return tryCraft(recipeId)
    end

    -- Must be near prototyper station to learn
    local recipe = craftRegistry:get(recipeId)
    if recipe:getKnowledgeMode() == "prototype" then
        local ok = knowledge:prototype(recipeId, station)
        if ok then
            local bonus = knowledge:getPrototypeSanityBonus()
            player.sanity = player.sanity + bonus
            showMessage("Learned: " .. recipe:getName() .. "!")
        end
    end
end

-- Terraria-style available recipe list
function getAvailableRecipes()
    local nearbyStations = {}
    for _, station in ipairs(worldStations) do
        if station:isInRange(player.x, player.y) then
            table.insert(nearbyStations, station)
        end
    end

    local context = {
        inventory = playerInventory,
        skills = playerSkills,
        knownRecipes = knowledge:getKnown(),
        nearbyStations = nearbyStations,
    }

    return craftRegistry:getCraftable(context)
end
```

### Factory Automation

```lua
-- Factorio-style production chain
local assembler1 = luna.crafting.newStation("assembling_machine", 1)
assembler1:setSpeedMultiplier(0.5)   -- tier 1 = 0.5x
assembler1:setModuleSlotCount(2)

local assembler3 = luna.crafting.newStation("assembling_machine", 3)
assembler3:setSpeedMultiplier(1.25)  -- tier 3 = 1.25x
assembler3:setModuleSlotCount(4)
assembler3:insertModule(1, "speed")
assembler3:insertModule(2, "speed")
assembler3:insertModule(3, "productivity")
assembler3:insertModule(4, "productivity")

-- Each assembler runs its own CraftQueue
local queue1 = luna.crafting.newCraftQueue(1)
local queue3 = luna.crafting.newCraftQueue(1)
queue1:setMaxConcurrent(1)  -- 1 recipe per machine

-- Submit continuous production
queue1:submit(craftRegistry:get("iron_gear"), inputBelt1, assembler1)
queue3:submit(craftRegistry:get("electronic_circuit"), inputBelt3, assembler3)

-- In update loop, completed items go to output belt/chest
function luna.update(dt)
    for _, result in ipairs(queue1:update(dt)) do
        outputBelt1:addItem(result.outputs[1])
        -- Re-submit for continuous production
        queue1:submit(craftRegistry:get("iron_gear"), inputBelt1, assembler1)
    end
end
```

---

## Extension Integration

The **Luna2D VS Code Extension** provides a **Crafting Editor** panel for visual recipe design and testing.

### Editor Features

- **Recipe Designer** with drag-and-drop ingredient/output slots
- **Grid Editor** for shaped recipes (Minecraft-style) with mirror/rotation preview
- **Station Configuration** panel with tier and attachment management
- **Skill Tree Visualizer** for perk prerequisites (Skyrim-style DAG)
- **Upgrade Tree Editor** with node/edge graph (Monster Hunter weapon trees)
- **Quality Tier Configuration** with preview of roll probabilities
- **Recipe Group Organizer** with drag-and-drop ordering
- **Live Crafting Simulator** — test recipes against mock inventory/skills without running the game
- **Recipe File Editor** — TOML/Lua syntax highlighting with validation

### Export Formats

**Lua format** (`recipes.lua`):
```lua
return {
    recipes = { ... },
    stations = { ... },
    skills = { ... },
    groups = { ... },
    quality_tiers = { ... },
}
```

**TOML format** (`recipes.toml`):
```toml
[meta]
version = 1

[[recipe]]
id = "..."

## Research Foundation — 12-Game Crafting Analysis

This module's design is informed by analysis of crafting systems in 12 commercially successful games across different genres. The universal patterns extracted are:

### Crafting Paradigm Taxonomy

| Archetype | Example Games | Core Primitive |
|-----------|---------------|----------------|
| Spatial Grid | Minecraft | Slot grid → shaped pattern matching |
| List-Based | Terraria, Stardew, Factorio, Rust, Valheim, MHW, Don't Starve, New World | Ingredient multiset → output |
| Currency-State | Path of Exile | Item state machine + orb transitions |
| Skill-Gated | WoW, Skyrim, New World | Profession skill level gates recipes |
| Factory-Throughput | Factorio | Recipe + machine speed → production rate |
| Prototype-Unlock | Don't Starve | One-time station visit → permanent knowledge |
| Weapon-Tree | Monster Hunter: World | Branching DAG upgrade graph |

### Universal Primitives (All 12 Games)

Every crafting system reduces to five primitives:
1. **ItemRef** — typed item identifier + quantity + optional quality
2. **Recipe** — N inputs → M outputs + constraints
3. **Station** — recipe filter + capability level + proximity
4. **CraftContext** — player state + station state + inventory snapshot
5. **CraftResult** — deterministic or probabilistic output set + side effects

### Key Genre Patterns

| Pattern | Games Using It | This Module's Support |
|---------|---------------|----------------------|
| Shaped grid recipes | Minecraft | `RecipeType.SHAPED` with grid dimensions |
| Proximity-union of stations | Terraria | `setProximityRadius()` + station queries |
| Station upgrade tiers | Valheim, New World | `Station:setLevel()` + recipe `minStationLevel` |
| Time-based production | Factorio, Stardew, Minecraft furnace | `CraftJob` with duration + queue |
| Skill color bands (Orange→Grey) | WoW | Configurable skill-up probability curves |
| Blueprint/prototype discovery | Rust, Don't Starve | `RecipeKnowledge` unlock system |
| Quality aging over time | Stardew Cask | `CraftJob` with quality progression |
| Currency item modification | Path of Exile | `ModificationRecipe` type |
| Weapon upgrade tree | Monster Hunter: World | `UpgradeTree` DAG structure |
| Nutritional point algebra | Don't Starve Crock Pot | Tag-based ingredient scoring |
| Factory speed × modules | Factorio | Station speed multiplier + module slots |
| Gear Score range | New World | Skill-dependent quality range rolls |
| Perk tree unlocks | Skyrim | `CraftSkill` perk prerequisites |
| Reforging/rerolling | Terraria, PoE | `ModificationRecipe` with RNG modifiers |
| Fortify stacking loops | Skyrim | Modifier sources composable |

## Crafting Paradigm Taxonomy

| Archetype | Example Games | Core Primitive |
|-----------|---------------|----------------|
| Spatial Grid | Minecraft | Slot grid → shaped pattern matching |
| List-Based | Terraria, Stardew, Factorio, Rust, Valheim, MHW, Don't Starve, New World | Ingredient multiset → output |
| Currency-State | Path of Exile | Item state machine + orb transitions |
| Skill-Gated | WoW, Skyrim, New World | Profession skill level gates recipes |
| Factory-Throughput | Factorio | Recipe + machine speed → production rate |
| Prototype-Unlock | Don't Starve | One-time station visit → permanent knowledge |
| Weapon-Tree | Monster Hunter: World | Branching DAG upgrade graph |

## Universal Primitives (All 12 Games)

Every crafting system reduces to five primitives:
1. **ItemRef** — typed item identifier + quantity + optional quality
2. **Recipe** — N inputs → M outputs + constraints
3. **Station** — recipe filter + capability level + proximity
4. **CraftContext** — player state + station state + inventory snapshot
5. **CraftResult** — deterministic or probabilistic output set + side effects

## Key Genre Patterns

| Pattern | Games Using It | This Module's Support |
|---------|---------------|----------------------|
| Shaped grid recipes | Minecraft | `RecipeType.SHAPED` with grid dimensions |
| Proximity-union of stations | Terraria | `setProximityRadius()` + station queries |
| Station upgrade tiers | Valheim, New World | `Station:setLevel()` + recipe `minStationLevel` |
| Time-based production | Factorio, Stardew, Minecraft furnace | `CraftJob` with duration + queue |
| Skill color bands (Orange→Grey) | WoW | Configurable skill-up probability curves |
| Blueprint/prototype discovery | Rust, Don't Starve | `RecipeKnowledge` unlock system |
| Quality aging over time | Stardew Cask | `CraftJob` with quality progression |
| Currency item modification | Path of Exile | `ModificationRecipe` type |
| Weapon upgrade tree | Monster Hunter: World | `UpgradeTree` DAG structure |
| Nutritional point algebra | Don't Starve Crock Pot | Tag-based ingredient scoring |
| Factory speed × modules | Factorio | Station speed multiplier + module slots |
| Gear Score range | New World | Skill-dependent quality range rolls |
| Perk tree unlocks | Skyrim | `CraftSkill` perk prerequisites |
| Reforging/rerolling | Terraria, PoE | `ModificationRecipe` with RNG modifiers |
| Fortify stacking loops | Skyrim | Modifier sources composable |

## Reimplementation Notes

- This is a NEW module — no `src/modules/crafting/` exists yet (needs full 12-step scaffold)
- Integrates with `luna.inventory` for ingredient checking and output placement — does NOT duplicate inventory logic
- Integrates with `luna.resource` for resource-type costs (gold, energy, fuel) — recipes can consume both items and resources
- Integrates with `luna.entity` for entity modification recipes (enchanting, upgrading, repairing entity components)
- Integrates with `luna.event` for crafting events: `craftstart`, `craftcomplete`, `craftfail`, `craftdiscovery`
- All recipe definitions are data-driven (Lua tables or TOML files loaded at runtime) — no hardcoded recipes in C++
- The C++ engine provides the recipe registry, validation pipeline, crafting queue, skill tracking, and station management
- Custom Lua scripts per recipe execute in a sandboxed environment via `onCraft`, `onComplete`, `canCraft` callbacks
- Random events use a seeded RNG per craft operation for deterministic replay in multiplayer/save scenarios
- Max 65536 recipes per registry (uint16 ID space, CSF-010)
- Max 256 crafting stations per world (uint8 ID space, CSF-010)
- Max 64 crafting skills per player (uint8 ID space, CSF-010)
- Max 1024 active craft jobs in queue (CSF-010)
- Recipe IDs are strings, but internally hashed to uint32 for fast lookup
- `CraftContext` is a snapshot — it does NOT hold live references to inventory; validate again before consuming
- All Lua callbacks are stored as Lua registry references (same pattern as `luna.inventory`)
- Station proximity uses squared-distance checks to avoid sqrt per frame
- Shaped recipe matching supports mirror/rotation variants via flags
- Tag-based ingredient matching (e.g., `#planks` matches any wood type) avoids N² recipe duplication
- Quality tiers are a configurable enum (default: Normal/Fine/Superior/Excellent/Masterwork/Legendary)
- Crafting skill XP gain uses configurable probability curves (constant, linear, WoW color-band, custom Lua function)

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 1 |
| `mod` | 9 |
| `struct` | 15 |
| **Total** | **25** |

