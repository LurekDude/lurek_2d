# `crafting` — Agent Reference (Lunasome)

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Lunasome (pure Lua, no Rust dependencies) |
| **Source** | `library/crafting/init.lua` |
| **Lua Tests** | `tests/lua/library/test_library_crafting.lua` |
| **Depends on** | `luna.*` public API only |

## Summary

Crafting system with recipes, timed craft queues, upgrade trees, and recipe
knowledge management. `Recipe` holds the ingredient list, output, category,
required station, and skill level threshold. `RecipeRegistry` is the global
index of all registered recipes; it supports filtering by category, station,
and skill level as well as sub-group organisation via `RecipeGroup`.

A `CraftJob` tracks one in-progress recipe: it stores elapsed `progress` against
`total_time`, supports pause/resume, and computes a 0–1 `percent()`. `CraftQueue`
manages a pool of `CraftJob` instances subject to two limits: `max_jobs`
(total queue depth) and `setMaxConcurrent(n)` (how many jobs advance in
parallel each `update(dt)` tick). Completed job IDs accumulate until drained by
`collectCompleted()`; `ids()` and `queuedIds()` return snapshots of all
queued or pending job IDs.

`CraftSkill` models a player skill with a name, XP, level, and specializations.
`canUse(recipe)` checks the skill level threshold; `skillUpChance()` computes
promotion probability; `addSpecialization`/`getSpecializations` manage the
specialization list; and `getSpeedBonus`/`getQualityBonus`/`getYieldBonus`
return computed bonuses for the current level. `M.CraftSkillRarity` provides
four named tiers: `COMMON`, `UNCOMMON`, `RARE`, `EPIC`.

`UpgradeTree` organises `UpgradeNode` instances in a dependency DAG in
insertion order. `unlock()` checks that the parent node is already unlocked
before allowing progression; `availableUpgrades(unlocked_set, level)` returns
the filtered subset visible to the player; `getAllNodes()` returns all nodes as
a flat array. `RecipeKnowledge` tracks discovered recipes with source labels,
optional prototyping state, `research(id, scrap)` gated by a configurable cost;
`forget(id)` removes a known recipe and `setAutoDiscover`/`isAutoDiscover`
control automatic discovery. `ModifierPool` is a full weighted-entry pool:
`draw()` selects a modifier by weight; `remove()`, `getTotalWeight()`,
`getEntries()`, `getModifiers()`, `count()`, `getName`/`setName` expose the full
set of management operations. `RecipeGroup` is a named, ordered collection of
recipe IDs with `addRecipe`, `removeRecipe`, `get`, `contains`, and icon/order
metadata.

## Architecture

```
RecipeRegistry (global recipe index)
  │
  ├── recipes: { id → Recipe }
  │     ├── ingredients: { item_type → count }
  │     ├── output_type, output_count
  │     ├── category, station, skill_level
  │
  └── groups: { name → RecipeGroup }

Station (craft station)
  ├── name, station_type, level / max_level
  ├── fuel / max_fuel / fuel_rate
  ├── modules[], module_limit  /  attachments[], attachment_limit
  ├── stats: { key → value },  efficiency: number
  ├── canProcess(recipe) / effectiveTime(recipe) / effectiveLevel()
  └── isInRange(px, py) / moduleSlotCount() / setModuleSlotCount(n) / getModuleAt(slot)

CraftQueue (parallel timed queue)
  │
  ├── max_jobs: upper bound on queue depth
  ├── max_concurrent: parallel advance limit
  ├── jobs[]: CraftJob { progress, total_time, paused }
  └── ids() / queuedIds() → snapshot arrays

CraftSkill
  ├── name, level, xp, specializations[]
  ├── canUse(recipe) / skillUpChance()
  └── getSpeedBonus / getQualityBonus / getYieldBonus

M.CraftSkillRarity  ──  COMMON | UNCOMMON | RARE | EPIC

UpgradeTree (node DAG)
  ├── nodes: { id → UpgradeNode }
  ├── unlock(id) / availableUpgrades(set, level)
  └── getAllNodes() → flat array

RecipeKnowledge
  ├── known: { recipe_id → true }
  ├── forget(id) / setAutoDiscover(bool) / isAutoDiscover()
  └── research_costs: { recipe_id → number }

ModifierPool (full weighted pool)
  ├── entries[]: ModifierEntry { name, weight }
  └── draw() / remove() / getTotalWeight() / getEntries() / count()

RecipeGroup (named ordered collection)
  ├── ids[]: recipe_id[]
  └── addRecipe / removeRecipe / get / contains / icon / order
```

## Source Files

| File | Purpose |
|------|---------|
| `library/crafting/init.lua` | Full implementation — Recipe, RecipeRegistry, Station, CraftJob, CraftQueue, UpgradeNode, UpgradeTree, RecipeKnowledge, RecipeGroup, ModifierPool, CraftSkill |

## Key Types

| Type | Constructor | Purpose |
|------|-------------|---------|
| `Recipe` | `M.newRecipe(id)` | Ingredient list + output + category/station/skill metadata |
| `Ingredient` | `M.newIngredient(item_type, qty)` / `M.newIngredientTag(tag, qty)` | Recipe input requirement (item or tag-based) |
| `RecipeOutput` | `M.newRecipeOutput(item_type, qty)` / `M.newRecipeOutputWithChance(item_type, qty, chance)` | Recipe output with quality and drop chance |
| `RecipeRegistry` | `M.newRecipeRegistry()` | Global recipe index with filtering by category, station, skill, tag |
| `Station` | `M.newStation(name, station_type)` | Craft station with level, fuel, modules, attachments, efficiency, `active`/`requires_cover`/`has_cover` flags; `canProcess`/`effectiveTime`/`effectiveLevel`/`isInRange` |
| `CraftJob` | `M.newCraftJob(id, recipe_id, total_time, quantity)` | Single in-progress timed craft with pause/resume |
| `CraftQueue` | `M.newCraftQueue(max_jobs)` | Parallel job pool with concurrency limit; exposes `ids()` and `queuedIds()` |
| `CraftSkill` | `M.newCraftSkill(name)` | Crafting skill with XP, level, specializations, perk tree, and bonus computation |
| `PerkNode` | `M.newPerkNode(name)` | Skill perk tree node with level requirement and prerequisites |
| `UpgradeNode` | `M.newUpgradeNode(id, name)` | Node in upgrade DAG with cost, `required_level`, `prerequisites`, effects, and unlock state |
| `UpgradeTree` | `M.newUpgradeTree(name)` | DAG of UpgradeNodes; unlock, BFS path, `getAllNodes()`, `availableUpgrades()` |
| `RecipeKnowledge` | `M.newRecipeKnowledge()` | Per-player recipe discovery, prototype, research, forget, and auto-discover |
| `RecipeGroup` | `M.newRecipeGroup(name, ids)` | Named ordered collection of recipe IDs with icon and order metadata |
| `ModifierEntry` | `M.newModifierEntry(name, weight)` | Single weighted entry for a modifier pool |
| `ModifierPool` | `M.newModifierPool()` | Weighted modifier pool with `roll()`/`draw()`, `remove()`, and management operations |
| `M.Quality` | enum table | Quality tiers: `Normal` `Fine` `Superior` `Excellent` `Masterwork` `Legendary` |
| `M.CraftSkillRarity` | enum table | Skill rarity tier constants: `COMMON` `UNCOMMON` `RARE` `EPIC` |
