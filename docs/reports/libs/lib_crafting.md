# `library.crafting`

*142 functions, 0 module fields documented.*

## Functions

### `qualityFromStr(s)`

Convert string to Quality value.

### `qualityToStr(q)`

Quality to display string.

### `newIngredient(item_type, quantity)`

Create ingredient by item type.

**Parameters**

- `item_type` *string* — Item ID to require.
- `quantity` *number* — Positive count required (default 1).

**Returns**

- *Ingredient*

### `newIngredientTag(tag, quantity)`

Create ingredient by tag.

**Parameters**

- `tag` *string* — Tag selector string.
- `quantity` *number* — Positive count required (default 1).

**Returns**

- *Ingredient*

### `isTag()`

Return true if this ingredient selects by tag rather than item_type. **Precedence**: when both `tag` and `item_type` are non-empty, the tag takes precedence — matching code should check `isTag()` first.

**Returns**

- *boolean*

### `newRecipeOutput(item_type, quantity)`

Create a guaranteed recipe output with normal quality.

**Parameters**

- `item_type` *string* — Item ID produced.
- `quantity` *number* — Positive count produced (default 1).

**Returns**

- *RecipeOutput*

### `newRecipeOutputWithChance(item_type, quantity, chance)`

Create a probabilistic recipe output with an explicit chance.

**Parameters**

- `item_type` *string* — Item ID produced.
- `quantity` *number* — Positive count produced (default 1).
- `chance` *number* — Probability in [0, 1].

**Returns**

- *RecipeOutput*

### `newRecipe(id)`

Create a recipe with default metadata. A recipe holds: `id`, `recipe_type`, `name`, `description`, `category`, `station_type`, `station_level`, `time` (seconds), `cooldown`, `fuel_consumption_rate`, `ingredients` (list of Ingredient), `outputs` (list of RecipeOutput), `remainder_item`, `skill`, `skill_level`, `skill_xp`, `enabled`, `hand_craftable`, `tags`, `knowledge_mode`, `discovery_hint`, `grid_width`, `grid_height`, `grid_slots`, `grid_mirror`, `grid_rotation`, `required_nearby_stations`, `required_biome`, `required_location`, `orange/yellow/green/grey_threshold`, `upgrade_from`, `upgrade_to`, `alternatives`, `output_quality_scaling`, `random_modifier_pool`, `skill_up_curve`, `conditions`, `metadata`.

**Parameters**

- `id` *string* — Stable recipe identifier (must be non-empty).

**Returns**

- *Recipe*

### `hasTag(t)`

Return true if the recipe carries the given tag.

**Parameters**

- `t` *string*

**Returns**

- *boolean*

### `setGridSlot(x, y, item_type)`

Assign an item type to a shaped-recipe grid slot (0-based). Returns false with a warning if coordinates are out of bounds.

**Parameters**

- `x` *number* — Grid column (0-based, must be < grid_width).
- `y` *number* — Grid row (0-based, must be < grid_height).
- `item_type` *string* — Item ID expected in the slot.

**Returns**

- *boolean* — true if the slot was set, false if out of bounds.

### `addByproduct(item_type, quantity, chance)`

Add a byproduct output with a drop chance.

**Parameters**

- `item_type` *string*
- `quantity` *number*
- `chance` *number* — Probability in [0, 1].

### `addCondition(ctype, cvalue)`

Add a crafting condition requirement.

**Parameters**

- `ctype` *string* — Condition type key.
- `cvalue` *string* — Condition value.

### `newRecipeRegistry()`

Create an empty recipe registry.

**Returns**

- *RecipeRegistry*

### `add(recipe)`

Register a recipe in the registry.

**Parameters**

- `recipe` *Recipe* — The recipe to register.

### `remove(id)`

Remove a recipe by ID. Returns true if it existed.

**Parameters**

- `id` *string*

**Returns**

- *boolean*

### `ids()`

Return all recipe IDs in registration order.

**Returns**

- *table*

### `findByOutput(item_type)`

Find recipes that produce a specific item type.

**Parameters**

- `item_type` *string*

**Returns**

- *table* — list of Recipe

### `findByIngredient(item_type)`

Find recipes that consume a specific item type.

**Parameters**

- `item_type` *string*

**Returns**

- *table* — list of Recipe

### `findByTag(tag)`

Find recipes carrying a specific tag.

**Parameters**

- `tag` *string*

**Returns**

- *table* — list of Recipe

### `forStation(station_type)`

Find recipes that require a specific station type.

**Parameters**

- `station_type` *string*

**Returns**

- *table* — list of Recipe

### `findByCategory(cat)`

Find recipes in a UI category.

**Parameters**

- `cat` *string*

**Returns**

- *table* — list of Recipe

### `findBySkill(name, max_level)`

Find recipes gated by a skill, optionally capped to max_level.

**Parameters**

- `name` *string*
- `max_level` *number|nil* — If set, only recipes at or below this level.

**Returns**

- *table* — list of Recipe

### `findHandCraftable()`

Find all hand-craftable recipes.

**Returns**

- *table* — list of Recipe

### `newStation(name, station_type)`

Create a crafting station with default state.

**Parameters**

- `name` *string* — Display name.
- `station_type` *string* — Stable station type identifier.

**Returns**

- *Station*

### `addFuel(amount)`

Add fuel, clamped to max_fuel. Negative amounts are ignored.

**Parameters**

- `amount` *number* — Fuel to add (must be non-negative).

**Returns**

- *number* — New fuel level.

### `consumeFuel(amount)`

Consume fuel. Returns false if insufficient or amount is invalid.

**Parameters**

- `amount` *number* — Fuel to consume (must be non-negative).

**Returns**

- *boolean* — true if fuel was consumed, false otherwise.

### `fuelPercent()`

Return fuel as a fraction of max_fuel in [0, 1].

**Returns**

- *number*

### `addModule(name)`

Install a named module. Returns false if at capacity or already present.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `addAttachment(name)`

Add a physical attachment. Returns false if at capacity or duplicate.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `upgrade()`

Increment station level. Returns false if already at max.

**Returns**

- *boolean*

### `newCraftSkill(name)`

Create a crafting skill with default linear progression.

**Parameters**

- `name` *string* — Skill name such as "smithing".

**Returns**

- *CraftSkill*

### `addXP(amount)`

Add XP and level up as many times as the XP allows.

**Parameters**

- `amount` *number* — XP to add.

**Returns**

- *number* — Levels gained.

### `grantPerkPoint()`

Grant one free perk point.

### `spendPerkPoint(perk_name)`

Spend a perk point to unlock a perk by name. Returns false if no points or perk not unlockable.

**Parameters**

- `perk_name` *string*

**Returns**

- *boolean*

### `hasPerk(name)`

Return true if the named perk is unlocked.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `addPerkToTree(node)`

Register a PerkNode in the skill perk tree.

**Parameters**

- `node` *PerkNode*

### `newPerkNode(name)`

Create a locked perk node.

**Parameters**

- `name` *string* — Stable perk identifier.

**Returns**

- *PerkNode*

### `canUnlock(skill_level, unlocked_perks)`

Return true if the perk can be unlocked now.

**Parameters**

- `skill_level` *number* — Current skill level.
- `unlocked_perks` *table* — List of already-unlocked perk names.

**Returns**

- *boolean*

### `newModifierEntry(name, weight)`

Create a weighted modifier entry.

**Parameters**

- `name` *string* — Stable modifier identifier.
- `weight` *number* — Relative selection weight (default 1).

**Returns**

- *ModifierEntry*

### `newModifierPool()`

Create an empty modifier pool.

**Returns**

- *ModifierPool*

### `roll()`

Select a random weighted modifier entry (non-deterministic).

**Returns**

- *ModifierEntry|nil* — nil if pool is empty.

### `draw()`

Alias for roll(). Select a random weighted modifier entry.

**Returns**

- *ModifierEntry|nil*

### `discover(recipe_id, source)`

Discover a recipe. Optional source label ("craft", "research", "loot", etc.).

**Parameters**

- `recipe_id` *string*
- `source` *string|nil*

**Returns**

- *boolean* — true if newly discovered

### `isKnown(id)`

Return true if the recipe is known (or auto-discover is enabled).

**Parameters**

- `id` *string*

**Returns**

- *boolean*

### `knownCount()`

Return the number of discovered recipes.

**Returns**

- *number*

### `knownIds()`

Return all known recipe IDs sorted alphabetically.

**Returns**

- *table*

### `addGroup(name, ids)`

Register a named group of recipe IDs for UI organisation.

**Parameters**

- `name` *string*
- `ids` *table* — list of recipe ID strings

### `groupProgress(name)`

Return (known_count, total_count) for a named group.

**Parameters**

- `name` *string*

**Returns**

- *number* — known count
- *number* — total count

### `newCraftJob(id, recipe_id, total_time, quantity)`

Create a new craft job tracking a recipe in progress.

**Parameters**

- `id` *number* — unique job id
- `recipe_id` *string*
- `total_time` *number* — seconds to complete
- `quantity` *number* — units to produce

**Returns**

- *CraftJob*

### `advance(dt)`

Advance the job by dt seconds. Returns true when newly completed.

**Parameters**

- `dt` *number*

**Returns**

- *boolean*

### `percent()`

Return completion fraction 0ÔÇô1.

**Returns**

- *number*

### `pause()`

Pause the job (stops time advancing).

### `resume()`

Resume the job.

### `isCompleted()`

Return true if the job is completed.

**Returns**

- *boolean*

### `isPaused()`

Return true if the job is paused.

**Returns**

- *boolean*

### `remaining()`

Return remaining seconds.

**Returns**

- *number*

### `newCraftQueue(max_jobs)`

Create a new craft queue.

**Parameters**

- `max_jobs` *number* — maximum total queued jobs (default 5)

**Returns**

- *CraftQueue*

### `setMaxConcurrent(n)`

Set how many jobs can advance in parallel (must be <= max_jobs).

**Parameters**

- `n` *number*

### `maxJobs()`

Get the maximum concurrent job count.

**Returns**

- *number*

### `enqueue(recipe_id, total_time, quantity)`

Enqueue a new craft job. Returns the job id, or nil if queue is full.

**Parameters**

- `recipe_id` *string*
- `total_time` *number*
- `quantity` *number*

**Returns**

- *number|nil*

### `cancel(id)`

Cancel a job by id. Returns true if the job was removed.

**Parameters**

- `id` *number*

**Returns**

- *boolean*

### `update(dt)`

Advance all jobs by dt seconds. Returns list of newly-completed job IDs. Completed jobs are automatically removed from the active job list. Use `collectCompleted()` to retrieve and clear the cumulative completion log.

**Parameters**

- `dt` *number* — Delta time in seconds.

**Returns**

- *table* — List of job IDs that completed this tick.

### `collectCompleted()`

Remove and return all completed job ids since last collect.

**Returns**

- *table*

### `getJob(id)`

Get a job by id (active jobs only).

**Parameters**

- `id` *number*

**Returns**

- *CraftJob|nil*

### `count()`

Return total active job count (not including completed-but-uncollected).

**Returns**

- *number*

### `isFull()`

Return true if the queue is full.

**Returns**

- *boolean*

### `activeIds()`

Return sorted list of active (not-completed) job IDs.

**Returns**

- *table*

### `allJobs()`

Return all active jobs as summary tuples.

**Returns**

- *table* — list of {id, recipe_id, quantity, percent, completed}

### `clear()`

Clear all jobs from the queue.

### `newUpgradeNode(id, name)`

Create a new upgrade node.

**Parameters**

- `id` *string*
- `name` *string*

**Returns**

- *UpgradeNode*

### `setCost(cost)`

Set the unlock cost.

**Parameters**

- `cost` *number*

### `getCost()`

Get the unlock cost.

**Returns**

- *number*

### `addEffect(effect)`

Add an effect to this node.

**Parameters**

- `effect` *string*

### `getEffects()`

Get all effects.

**Returns**

- *table*

### `addTag(tag)`

Add a tag.

**Parameters**

- `tag` *string*

### `hasTag(tag)`

Check if the node has a tag.

**Parameters**

- `tag` *string*

**Returns**

- *boolean*

### `isUnlocked()`

Return true when unlocked.

**Returns**

- *boolean*

### `newUpgradeTree(name)`

Create a new upgrade tree.

**Parameters**

- `name` *string*

**Returns**

- *UpgradeTree*

### `addNode(node)`

Add a node to the tree.

**Parameters**

- `node` *UpgradeNode*

### `addEdge(from_id, to_id)`

Add a directed edge from_id Ôćĺ to_id.

**Parameters**

- `from_id` *string*
- `to_id` *string*

### `getNode(id)`

Look up a node by ID.

**Parameters**

- `id` *string*

**Returns**

- *UpgradeNode|nil*

### `getChildren(id)`

Get children of a node (sorted).

**Parameters**

- `id` *string*

**Returns**

- *table*

### `getRootNodes()`

Get root nodes (no parent).

**Returns**

- *table* — sorted IDs

### `getParent(id)`

Get parent ID (or nil if root).

**Parameters**

- `id` *string*

**Returns**

- *string|nil*

### `canUnlock(id)`

Return true if a node can be unlocked. All rules: node exists, not already unlocked, parent (if any) is unlocked.

**Parameters**

- `id` *string*

**Returns**

- *boolean*

### `unlock(id)`

Unlock a node. Returns true on success.

**Parameters**

- `id` *string*

**Returns**

- *boolean*

### `resetNode(id)`

Reset a node (re-lock it). Returns true if it was unlocked.

**Parameters**

- `id` *string*

**Returns**

- *boolean*

### `getUnlockedIds()`

Return sorted list of unlocked node IDs.

**Returns**

- *table*

### `nodeIds()`

Return all node IDs in insertion order.

**Returns**

- *table*

### `count()`

Return total node count.

**Returns**

- *number*

### `getPath(from, to)`

BFS path from node `from` to node `to`. Returns nil if not reachable.

**Parameters**

- `from` *string*
- `to` *string*

**Returns**

- *table|nil* — ordered list of node IDs

### `availableUpgrades(unlocked_set, player_level)`

Return all nodes that are not yet unlocked and whose parent (if any) is unlocked, filtered by optional player_level requirement.

**Parameters**

- `unlocked_set` *table* — set of unlocked node IDs (e.g. {a=true, b=true})
- `player_level` *number* — player's current level

**Returns**

- *table* — list of UpgradeNode

### `prototype(recipe_id)`

Allow a player to "prototype" a recipe (partial knowledge before full discovery).

**Parameters**

- `recipe_id` *string*

### `isPrototyped(recipe_id)`

Return true if the recipe has been prototyped.

**Parameters**

- `recipe_id` *string*

**Returns**

- *boolean*

### `setResearchCost(recipe_id, cost)`

Set a research cost for a recipe.

**Parameters**

- `recipe_id` *string*
- `cost` *number*

### `getResearchCost(recipe_id)`

Get research cost for a recipe (0 if not set).

**Parameters**

- `recipe_id` *string*

**Returns**

- *number*

### `research(recipe_id, scrap)`

Attempt to research a recipe by spending scrap resources. Returns true and discovers the recipe if scrap >= research cost.

**Parameters**

- `recipe_id` *string*
- `scrap` *number*

**Returns**

- *boolean*

### `getSource(recipe_id)`

Get the source that originally discovered a recipe ("research", "craft", etc.).

**Parameters**

- `recipe_id` *string*

**Returns**

- *string|nil*

### `getXpToNext()`

XP required to reach next level.

**Returns**

- *number*

### `setLevel(level)`

Force-set the skill level and reset XP to 0.

**Parameters**

- `level` *number* — Clamped to max_level.

### `canUse(recipe)`

Return true if this skill satisfies a recipe's skill gate. Accepts a recipe table with .skill and .skill_level fields.

**Parameters**

- `recipe` *table*

**Returns**

- *boolean*

### `recipeColor(recipe)`

WoW-style difficulty colour for a recipe. Returns "orange", "yellow", "green", or "grey".

**Parameters**

- `recipe` *table*

**Returns**

- *string*

### `skillUpChance(recipe)`

Probability (0-1) of a skill-up when crafting this recipe.

**Parameters**

- `recipe` *table*

**Returns**

- *number*

### `addSpecialization(name)`

Register a specialization branch (no-op if already present).

**Parameters**

- `name` *string*

### `getSpecializations()`

Return the list of registered specialization branches.

**Returns**

- *table*

### `chooseSpecialization(name)`

Lock in a chosen specialization. Returns false if already specialised or name unknown.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `getSpecialization()`

Return the current specialization (or nil if none).

**Returns**

- *string|nil*

### `availablePerks()`

Return perks available at the current skill level from the perk tree.

**Returns**

- *table* — list of PerkNode

### `getSpeedBonus()`

Computed speed bonus from unlocked perks.

**Returns**

- *number*

### `getQualityBonus()`

Computed quality bonus from unlocked perks.

**Returns**

- *number*

### `getYieldBonus()`

Computed yield bonus from unlocked perks.

**Returns**

- *number*

### `ids()`

Return all job IDs regardless of state.

**Returns**

- *table*

### `queuedIds()`

Return IDs of queued (waiting) jobs.

**Returns**

- *table*

### `effectiveLevel()`

Effective level = base level + count of installed attachments.

**Returns**

- *number*

### `effectiveTime(recipe)`

Effective craft time after applying station efficiency.

**Parameters**

- `recipe` *table* — Must have a .time field.

**Returns**

- *number*

### `canProcess(recipe)`

Return true if the station can process a recipe.

**Parameters**

- `recipe` *table*

**Returns**

- *boolean*

### `isInRange(px, py)`

Return true if world position is within proximity_radius.

**Parameters**

- `px` *number*
- `py` *number*

**Returns**

- *boolean*

### `moduleSlotCount()`

Return the current module slot capacity.

**Returns**

- *number*

### `setModuleSlotCount(n)`

Set the module slot capacity.

**Parameters**

- `n` *number*

### `getModuleAt(slot)`

Return the module name at a 1-based slot index.

**Parameters**

- `slot` *number* — 1-based.

**Returns**

- *string|nil*

### `getAllNodes()`

Return all nodes in insertion order.

**Returns**

- *table* — list of UpgradeNode

### `remove(name)`

Remove modifier by name. Returns true if found.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `getTotalWeight()`

Return sum of all entry weights.

**Returns**

- *number*

### `getEntries()`

Return a copy of the entries list.

**Returns**

- *table*

### `getModifiers()`

Alias for getEntries (matches Rust get_modifiers).

**Returns**

- *table*

### `count()`

Return the number of entries.

**Returns**

- *number*

### `getName()`

Get the pool name.

**Returns**

- *string*

### `setName(name)`

Set the pool name.

**Parameters**

- `name` *string*

### `forget(recipe_id)`

Remove knowledge of a recipe. Returns true if it was known.

**Parameters**

- `recipe_id` *string*

**Returns**

- *boolean*

### `setAutoDiscover(enabled)`

Enable or disable auto-discover mode.

**Parameters**

- `enabled` *boolean*

### `isAutoDiscover()`

Return true if auto-discover is enabled.

**Returns**

- *boolean*

### `clear()`

Wipe all discovered recipes and prototypes.

### `newRecipeGroup(name, ids)`

Create a named group of recipes. Replaces the plain-table version; .ids is kept for backward compat.

**Parameters**

- `name` *string*
- `ids` *table|nil* — initial recipe IDs

**Returns**

- *RecipeGroup*

### `addRecipe(recipe_id)`

Add a recipe ID (no-op if already present).

**Parameters**

- `recipe_id` *string*

### `removeRecipe(recipe_id)`

Remove a recipe ID. Returns true if found.

**Parameters**

- `recipe_id` *string*

**Returns**

- *boolean*

### `getRecipes()`

Return all recipe IDs.

**Returns**

- *table*

### `count()`

Return the number of recipes.

**Returns**

- *number*

### `contains(recipe_id)`

Check whether a recipe ID is in the group.

**Parameters**

- `recipe_id` *string*

**Returns**

- *boolean*

### `setIcon(icon)`

Set the icon identifier.

**Parameters**

- `icon` *string*

### `getIcon()`

Get the icon identifier.

**Returns**

- *string*

### `setOrder(order)`

Set the sort order.

**Parameters**

- `order` *number*

### `getOrder()`

Get the sort order.

**Returns**

- *number*
