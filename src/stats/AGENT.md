# `stats` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Gameplay Systems |
| **Lua API** | `luna.stats` |
| **Source** | `src/stats/` |
| **Tests** | `tests/stats_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_stats.lua` |

## Summary

Flexible attribute system for entities combining buffs, derived stats,
traits, skills, perks, XP and levelling, action points, morale, and damage
resistances. `Sheet` is the per-entity container; it holds a map of named
`Attribute` objects, each with a base value, optional min/max constraints,
a regen rate, and an ordered stack of `Buff` objects. Buffs are resolved by
summing all Additive modifiers on top of the base value then multiplying by
all Multiplicative modifiers, with Replace and Override modes for special
cases. `Skill` nodes track level, accumulated XP, cooldown timers, and
resource costs; `LevelThreshold` entries define XP breakpoints at which Lua
callbacks fire. The global `StatsRegistry` stores named `TraitDef`
definitions (thresholds and effect tables) and `Archetype` templates that
seed a `Sheet` with a preset baseline, keeping game-specific stat names out
of engine code. Resistance maps enable fine-grained damage-type multipliers
(fire, ice, blunt, etc.) without hardcoded enums in the engine.

## Architecture

```
Sheet (character stats container)
  │
  ├── attributes: HashMap<String, Attribute>
  │     ├── base_value, constraints (min/max), regen_rate
  │     └── buffs: Vec<Buff>
  │           ├── StackMode: Replace | Add | Multiply | Override
  │           ├── value, duration/expires_at, source tag
  │           └── Resolution: sum additives, then multiply multiplicatives
  │
  ├── skills: HashMap<String, Skill>
  │     ├── level, xp, xp_threshold
  │     ├── cooldown_remaining, resource_cost reference
  │     └── Perk tree associations
  │
  ├── morale / action_points (optional subsystems)
  │  ├── resistances: HashMap<String, f64>
  │  └── level thresholds: Vec<LevelThreshold { xp, on_level_fn }>
  │
  └── StatsRegistry (global shared)
        ├── trait_types: HashMap<String, TraitDef>
        └── archetypes: HashMap<String, Archetype { base_attributes }>
```

## Source Files

| File | Purpose |
|------|---------|
| `attribute.rs` | Stat attributes, stack mode, and buff descriptors |
| `sheet.rs` | Character sheet (Sheet) and stats registry (StatsRegistry) |
| `skill.rs` | Skills, perks, trait definitions, action points, morale, and level thresholds |

## Submodules

### `stats::attribute`

Stat attributes, stack mode, and buff descriptors.

- **`StackMode`** (enum): How a buff stacks with existing buffs of the same name.
- **`Buff`** (struct): A single stat modifier attached to an attribute.
- **`Attribute`** (struct): A named stat attribute with base value, constraints, and regen.

### `stats::sheet`

Character sheet (Sheet) and stats registry (StatsRegistry).

- **`Sheet`** (struct): The central character sheet, holding all stat data.
- **`StatsRegistry`** (struct): Global registry for traits and archetypes. Separate from Sheet for sharing.

### `stats::skill`

Skills, perks, trait definitions, action points, morale, and level thresholds.

- **`Skill`** (struct): A named skill with cooldown, resource cost, and level tracking.
- **`Perk`** (struct): A named perk requiring a minimum level to acquire.
- **`TraitDef`** (struct): A named trait definition (a bundle of buff descriptors).
- **`ActionPoints`** (struct): Action point tracking for turn-based games.
- **`Morale`** (struct): Morale state with panic/berserk thresholds.
- **`LevelThresholds`** (enum): Level threshold setting: either a static table or a formula.

## Key Types

### Structs

#### `stats::skill::ActionPoints`

Action point tracking for turn-based games.

#### `stats::attribute::Attribute`

A named stat attribute with base value, constraints, and regen.

#### `stats::attribute::Buff`

A single stat modifier attached to an attribute.

#### `stats::skill::Morale`

Morale state with panic/berserk thresholds.

#### `stats::skill::Perk`

A named perk requiring a minimum level to acquire.

#### `stats::sheet::Sheet`

The central character sheet, holding all stat data.

#### `stats::skill::Skill`

A named skill with cooldown, resource cost, and level tracking.

#### `stats::sheet::StatsRegistry`

Global registry for traits and archetypes. Separate from Sheet for sharing.

#### `stats::skill::TraitDef`

A named trait definition (a bundle of buff descriptors).

### Enums

#### `stats::skill::LevelThresholds`

Level threshold setting: either a static table or a formula.

#### `stats::attribute::StackMode`

How a buff stacks with existing buffs of the same name.

## Lua API

Exposed under `luna.stats.*` by `src/lua_api/stats_api/`.

## stats — RPG Character Sheet & Stat System

> **Lua namespace:** `luna.stats`
> **C++ module:** `src/modules/stats/`
> **Purpose:** Full RPG character sheet system with attributes, buffs, derived stats, traits, skills, perks, levelling, XP, and serialisation. Provides a data-driven archetype system (races and classes) with trait bundles and buff stacking.

## Reimplementation Notes

- The `Sheet` object is the central data container — it holds **attributes** (named float values with min/max/regen), **buffs** (additive/multiplicative, timed or permanent), **traits** (named buff bundles), **skills** (with cooldowns, resource costs, use/passive callbacks), **perks** (level-gated trait unlocks), **flags** (boolean tags), and **XP/level** progression.
- Buffs stack using a handle system: `addBuff()` returns an integer handle for later removal. Buffs have `add` (additive) and `mul` (multiplicative, default 1.0) components, optional `duration` (-1 = permanent), and a `source` string.
- Effective stat value = `(base + sum_of_adds) * product_of_muls`, clamped to [min, max].
- `defineDerived(name, fn)` registers a Lua function that computes a derived stat from the sheet itself.
- Traits are globally defined via `luna.stats.defineTrait()` and applied to sheets via `sheet:addTrait()`.
- Race/class archetypes are module-level definitions that apply base overrides and traits to new sheets.
- Archetypes can include `allowedSkills`, `forbiddenSkills`, `allowedPerks`, `forbiddenPerks` constraints (unordered string sets).
- `update(dt)` ticks timed buff durations (removing expired) and skill cooldowns.
- The observer pattern via `on(name, fn)` fires on attribute changes or `"levelup"` events.
- `snapshot()`/`restore()` enables full serialisation of sheet state.
- `recordUse(name)` tracks stat exercise counts, potentially triggering growth (use-based levelling pattern).
- `setLevelThresholds()` accepts either a table of XP thresholds or a function for computed thresholds.
- All names (attributes, traits, skills, perks, flags) are plain strings — no integer IDs.
- **Status effects** extend the buff system with periodic tick callbacks, stacking modes, and immunity lists. Effects can be positive (buffs) or negative (debuffs). Each effect has a unique name and manages its own tick timer.
- **Combat resolver** provides formula-based combat calculation (accuracy, damage, critical hits). Formulas are pluggable Lua functions — presets for X-COM style (hit chance from accuracy vs. dodge, cover modifier), Fallout style (threshold damage reduction), and d20 style (roll + modifier vs. defense class) are provided.
- **Resistance system** on Sheet: resistances are named float values (e.g. `"fire"`, `"poison"`) that reduce incoming damage by a flat amount or percentage.
- **Action points / time units**: Sheet can define a TU budget for turn-based games (X-COM, Fallout). Skills and actions consume TU. `beginTurn()` refills the pool.
- **Morale**: A special attribute with automatic modifiers from combat events (ally loss, critical hit, mission success). Morale threshold triggers panic/berserk flags.
- **Formation bonuses**: Static bonus tables describing adjacency bonuses when units are positioned in defined formations. Applied as temporary traits.

## Dependencies

- None (self-contained module)

## Module Functions

| Function | Signature | Returns | Description |
|----------|-----------|---------|-------------|
| `newSheet` | `newSheet([opts])` | `Sheet` | Create a new character sheet. Optional table `opts` with `race` (string) and/or `class` (string) to apply archetypes at creation time. |
| `defineTrait` | `defineTrait(name, buffs)` | — | Define a named trait as a table of buff descriptors: `{ {stat="str", add=5}, {stat="agi", mul=0.8} }`. |
| `defineRace` | `defineRace(name, def)` | — | Define a race archetype. `def` table: `{bases={str=10, agi=8}, traits={"nightvision"}}`. |
| `defineClass` | `defineClass(name, def)` | — | Define a class archetype with optional skill/perk constraints. `def` table: `{bases={str=5}, traits={"heavy_armor"}, allowedSkills={}, forbiddenSkills={}, allowedPerks={}, forbiddenPerks={}}`. |
| `getTraitNames` | `getTraitNames()` | `table<string>` | Returns all registered trait names. |
| `getRaceNames` | `getRaceNames()` | `table<string>` | Returns all registered race names. |
| `getClassNames` | `getClassNames()` | `table<string>` | Returns all registered class names. |
| `newStatusEffect` | `newStatusEffect(name, def)` | `StatusEffect` | Create a status effect. `def` table: `{duration, tickInterval, onApply, onTick, onExpire, stackMode, maxStacks, buffs}`. |
| `newCombatResolver` | `newCombatResolver(preset?)` | `CombatResolver` | Create a combat resolver. Optional preset: `"xcom"`, `"fallout"`, `"d20"`. |
| `defineFormation` | `defineFormation(name, def)` | — | Define a named formation bonus. `def` table: `{positions={{dx,dy},...}, bonuses={{stat="str",add=2},...}}`. |
| `getFormationNames` | `getFormationNames()` | `table<string>` | Returns all registered formation names. |

## Type: Sheet

The primary data object representing a character's full stat sheet.

### Attribute Management

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `define` | `define(name, base [, opts])` | — | Define a named attribute with base value. Optional `opts` table: `{min=N, max=N, regen=N, growth=N}`. |
| `get` | `get(name)` | `number` | Get effective value (base + buff adds × buff muls, clamped). |
| `getBase` | `getBase(name)` | `number` | Get raw base value without modifiers. |
| `setBase` | `setBase(name, value)` | — | Set the base value directly. |
| `setMin` | `setMin(name, val)` | — | Set minimum constraint for attribute. |
| `setMax` | `setMax(name, val)` | — | Set maximum constraint for attribute. |
| `getMin` | `getMin(name)` | `number` | Get minimum constraint. |
| `getMax` | `getMax(name)` | `number` | Get maximum constraint. |
| `setRegen` | `setRegen(name, rate)` | — | Set regeneration rate (per second). |
| `getRegen` | `getRegen(name)` | `number` | Get regeneration rate. |
| `getAttributes` | `getAttributes()` | `table<string>` | Get all defined attribute names. |

### Buff System

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addBuff` | `addBuff(stat, buffDef)` or `addBuff(buffDef)` | `int` | Add a buff. Returns integer handle. `buffDef` table: `{stat?, add?, mul?, duration?, source?}`. Two-arg form: `addBuff("str", {add=5})`. Single-table form: `addBuff({stat="str", add=5})`. |
| `removeBuff` | `removeBuff(handle)` | `boolean` | Remove a buff by its handle. Returns true if found. |
| `clearBuffs` | `clearBuffs([stat])` | — | Remove all buffs, or only buffs on a specific stat. |
| `getBuffs` | `getBuffs([stat])` | `table` | Get buff descriptors, optionally filtered by stat. Each entry: `{handle, stat, add, mul, duration, source}`. |

### Derived Stats

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `defineDerived` | `defineDerived(name, fn)` | — | Register a Lua function `fn(sheet)` that computes a derived value. |

### Traits

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addTrait` | `addTrait(name)` | — | Apply a trait (must be defined via `luna.stats.defineTrait()`). Applies all its buffs. |
| `removeTrait` | `removeTrait(name)` | — | Remove a trait and all its associated buffs. |
| `hasTrait` | `hasTrait(name)` | `boolean` | Check if trait is active. |
| `getActiveTraits` | `getActiveTraits()` | `table<string>` | Get all active trait names. |

### Skills

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `defineSkill` | `defineSkill(name, def)` | — | Define a skill. `def` table: `{maxLevel=N, resource="mana", cost=N, cooldown=N, use=fn, passive=fn}`. |
| `useSkill` | `useSkill(name)` | `boolean` | Attempt to use a skill (checks resource and cooldown). Calls `use` callback if available. |
| `getSkillLevel` | `getSkillLevel(name)` | `int` | Get current skill level. |
| `upgradeSkill` | `upgradeSkill(name)` | `int` | Increase skill level by 1 (up to maxLevel). Returns new level. |
| `getCooldownRemaining` | `getCooldownRemaining(name)` | `number` | Get remaining cooldown time in seconds. |
| `resetCooldown` | `resetCooldown(name)` | — | Reset skill cooldown to zero. |
| `hasSkill` | `hasSkill(name)` | `boolean` | Check if skill is defined on this sheet. |
| `getSkillNames` | `getSkillNames()` | `table<string>` | Get all defined skill names. |
| `activatePassive` | `activatePassive(name)` | — | Activate the passive callback for a named skill. |
| `deactivatePassive` | `deactivatePassive(name)` | — | Deactivate the passive callback for a named skill. |

### Perks

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `definePerk` | `definePerk(name, def)` | — | Define a perk. `def` table: `{requireLevel=N, trait="traitName"}`. |
| `addPerk` | `addPerk(name)` | `boolean` | Attempt to acquire a perk (checks level requirement). Returns true if successful. |
| `hasPerk` | `hasPerk(name)` | `boolean` | Check if perk has been acquired. |
| `getAvailablePerks` | `getAvailablePerks()` | `table<string>` | Get perk names where conditions are met but not yet acquired. |
| `getAcquiredPerks` | `getAcquiredPerks()` | `table<string>` | Get all acquired perk names. |

### Levelling & XP

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addXP` | `addXP(amount)` | — | Add experience points. May trigger one or more level-ups. |
| `getXP` | `getXP()` | `int` | Get total accumulated XP. |
| `setXP` | `setXP(amount)` | — | Set XP directly. |
| `getLevel` | `getLevel()` | `int` | Get current character level. |
| `setLevel` | `setLevel(lvl)` | — | Set level directly. |
| `setLevelThresholds` | `setLevelThresholds(thresholds)` | — | Set XP thresholds as a table `{100, 250, 500, ...}` or a function `fn(level) → requiredXP`. |

### Stat Exercise

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `recordUse` | `recordUse(name)` | — | Record a use of a stat, potentially triggering growth. |
| `getUseCount` | `getUseCount(name)` | `int` | Get total exercise count for a stat. |

### Flags

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setFlag` | `setFlag(name)` | — | Set a boolean flag. |
| `clearFlag` | `clearFlag(name)` | — | Clear a boolean flag. |
| `hasFlag` | `hasFlag(name)` | `boolean` | Check if flag is set. |
| `getFlags` | `getFlags()` | `table<string>` | Get all set flag names. |

### Observers & Updates

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `update` | `update(dt)` | — | Tick timed buffs (removing expired) and skill cooldowns by `dt` seconds. |
| `on` | `on(name, fn)` | — | Register observer callback. `name` can be an attribute name, `"*"` (any change), or `"levelup"`. |

### Serialisation

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `snapshot` | `snapshot()` | `table` | Serialise full sheet state for saving. |
| `restore` | `restore(data)` | — | Restore sheet state from a snapshot table. |

### Action Points / Time Units

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setActionPoints` | `setActionPoints(max, current?)` | — | Set the action point (TU) budget. `current` defaults to `max`. |
| `getActionPoints` | `getActionPoints()` | `current, max` | Get current and max action points. |
| `spendActionPoints` | `spendActionPoints(amount)` | `boolean` | Spend action points. Returns false if insufficient. |
| `beginTurn` | `beginTurn()` | — | Refill action points to max. Reset per-turn cooldowns. |
| `hasActionPoints` | `hasActionPoints(amount)` | `boolean` | Check if at least `amount` AP is available. |

### Morale

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setMorale` | `setMorale(value, max?)` | — | Set morale value. `max` defaults to 100. |
| `getMorale` | `getMorale()` | `current, max` | Get current and max morale. |
| `adjustMorale` | `adjustMorale(delta)` | — | Modify morale by `delta` (positive or negative). Clamps to [0, max]. |
| `setPanicThreshold` | `setPanicThreshold(value)` | — | Set morale level below which the unit panics (sets `"panic"` flag). |
| `setBerserkThreshold` | `setBerserkThreshold(value)` | — | Set morale level below which the unit goes berserk (sets `"berserk"` flag). |
| `checkMorale` | `checkMorale()` | `string\|nil` | Check morale state. Returns `"panic"`, `"berserk"`, or nil (normal). |

### Resistances

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setResistance` | `setResistance(type, value)` | — | Set a named resistance value (0–1 range for percentage, or flat amount). |
| `getResistance` | `getResistance(type)` | `number` | Get resistance value for a damage type. Returns 0 if not defined. |
| `getResistanceNames` | `getResistanceNames()` | `table<string>` | Get all defined resistance type names. |
| `applyDamage` | `applyDamage(stat, amount, damageType?)` | `number` | Apply damage to a stat, reduced by resistance. Returns actual damage dealt. |

### Status Effects

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `applyEffect` | `applyEffect(effect)` | `boolean` | Apply a StatusEffect to this sheet. Returns false if immune. |
| `removeEffect` | `removeEffect(name)` | — | Remove a status effect by name. |
| `hasEffect` | `hasEffect(name)` | `boolean` | Check if a status effect is active. |
| `getActiveEffects` | `getActiveEffects()` | `table<string>` | Get names of all active status effects. |
| `addImmunity` | `addImmunity(effectName)` | — | Make this sheet immune to a named status effect. |
| `removeImmunity` | `removeImmunity(effectName)` | — | Remove immunity to a status effect. |
| `isImmune` | `isImmune(effectName)` | `boolean` | Check if immune to a named status effect. |

### Initiative & Encumbrance

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setInitiative` | `setInitiative(value)` | — | Set base initiative value (used for turn order). |
| `getInitiative` | `getInitiative()` | `number` | Get effective initiative (base + buffs). |
| `rollInitiative` | `rollInitiative()` | `number` | Roll initiative with randomness: `initiative + random(1, 10)`. |
| `setEncumbrance` | `setEncumbrance(current, max)` | — | Set current and max carrying capacity. |
| `getEncumbrance` | `getEncumbrance()` | `current, max` | Get current and max carrying capacity. |
| `isEncumbered` | `isEncumbered()` | `boolean` | Check if current weight exceeds max capacity. |
| `getEncumbrancePenalty` | `getEncumbrancePenalty()` | `number` | Get movement/AP penalty factor from encumbrance (1.0 = no penalty). |

### Formation

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `applyFormation` | `applyFormation(name)` | — | Apply a defined formation's bonuses as temporary traits. |
| `removeFormation` | `removeFormation()` | — | Remove any active formation bonuses. |
| `getActiveFormation` | `getActiveFormation()` | `string\|nil` | Get the name of the active formation, or nil. |

## Buff Descriptor Format

```lua
{
    stat     = "str",     -- target attribute name
    add      = 5.0,       -- additive bonus (default 0)
    mul      = 1.0,       -- multiplicative factor (default 1.0)
    duration = 10.0,      -- seconds until expiry (-1 = permanent)
    source   = "potion",  -- descriptive source string
}
```

## Type: StatusEffect

A named time-limited effect that applies buffs and periodic tick callbacks to a Sheet. Supports stacking modes and immunity.

**Created by:** `luna.stats.newStatusEffect(name, def)`

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `getName` | `getName()` | `string` | Get the effect name. |
| `getDuration` | `getDuration()` | `number` | Get total duration in seconds (-1 = permanent). |
| `getTimeRemaining` | `getTimeRemaining()` | `number` | Get remaining duration. |
| `getTickInterval` | `getTickInterval()` | `number` | Get seconds between tick callbacks. |
| `getStackMode` | `getStackMode()` | `string` | Get stacking mode: `"none"` (reapply resets), `"duration"` (extends time), `"intensity"` (adds stacks). |
| `getStacks` | `getStacks()` | `int` | Get current stack count. |
| `getMaxStacks` | `getMaxStacks()` | `int` | Get maximum stack count. |
| `isPositive` | `isPositive()` | `boolean` | Get whether this is a buff (true) or debuff (false). |

### StatusEffect Definition Table

```lua
{
    duration     = 10.0,         -- seconds (-1 = permanent)
    tickInterval = 2.0,          -- seconds between onTick calls (0 = no ticking)
    stackMode    = "intensity",  -- "none", "duration", "intensity"
    maxStacks    = 3,            -- max stacks for "intensity" mode
    positive     = false,        -- true = buff, false = debuff
    buffs = {                    -- buffs applied while effect is active
        { stat = "str", add = -3 },
    },
    onApply  = function(sheet, effect)  end,  -- called when first applied
    onTick   = function(sheet, effect)        -- called every tickInterval
        sheet:applyDamage("hp", 5, "poison")
    end,
    onExpire = function(sheet, effect)  end,  -- called when duration ends
}
```

---

## Type: CombatResolver

Calculates combat outcomes using pluggable formulas for accuracy, damage, and critical hits. Provides presets for common RPG combat systems.

**Created by:** `luna.stats.newCombatResolver(preset?)`

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `resolve` | `resolve(attacker, defender [, opts])` | `table` | Calculate combat. Returns `{hit, critical, damage, damageType, details}`. `attacker`/`defender` are Sheet objects. |
| `setAccuracyFormula` | `setAccuracyFormula(fn)` | — | Set hit chance formula: `fn(attacker, defender, opts) → number (0–1)`. |
| `setDamageFormula` | `setDamageFormula(fn)` | — | Set damage formula: `fn(attacker, defender, opts) → number`. |
| `setCriticalFormula` | `setCriticalFormula(fn)` | — | Set critical hit formula: `fn(attacker, defender, opts) → number (0–1)`. |
| `setCriticalMultiplier` | `setCriticalMultiplier(mult)` | — | Set damage multiplier on critical hits (default 2.0). |
| `getCriticalMultiplier` | `getCriticalMultiplier()` | `number` | Get critical multiplier. |
| `setDamageType` | `setDamageType(type)` | — | Set default damage type string (e.g. `"physical"`, `"fire"`). Used by `applyDamage` for resistance lookup. |
| `getDamageType` | `getDamageType()` | `string` | Get default damage type. |
| `setCoverModifier` | `setCoverModifier(modifier)` | — | Set cover accuracy reduction (X-COM style). 0.0 = full cover, 1.0 = no cover. |
| `applyResult` | `applyResult(defender, result)` | — | Apply a combat result to a defender Sheet (deals damage, applies effects). |

### Combat Resolver Presets

| Preset | Hit Formula | Damage Formula | Description |
|--------|------------|----------------|-------------|
| `"xcom"` | `accuracy / (accuracy + dodge) * cover` | `baseDamage - armor/2` | X-COM-style percentage hit chance with cover and armor. |
| `"fallout"` | `skill% - distance_penalty` | `baseDamage - damageThreshold` | Fallout-style skill-based accuracy with damage threshold (DT). |
| `"d20"` | `roll(1,20) + modifier >= AC` | `roll(dice) + bonus` | d20 system with armor class and dice-based damage. |

### Combat Result Table

```lua
{
    hit         = true,          -- whether the attack connected
    critical    = false,         -- whether it was a critical hit
    damage      = 15,            -- final damage amount
    damageType  = "physical",    -- damage type string
    details     = {              -- breakdown for UI/logs
        hitChance    = 0.75,
        critChance   = 0.05,
        rawDamage    = 20,
        resistance   = 5,
        coverMod     = 1.0,
    },
}
```

---

## Usage Example

```lua
-- Define traits and archetypes
luna.stats.defineTrait("nightvision", {
    { stat = "perception", add = 3 }
})
luna.stats.defineRace("elf", {
    bases = { agi = 12, int = 10 },
    traits = { "nightvision" }
})
luna.stats.defineClass("mage", {
    bases = { int = 5 },
    traits = {},
    allowedSkills = { "fireball", "heal" }
})

-- Create character sheet with archetypes
local sheet = luna.stats.newSheet({ race = "elf", class = "mage" })

-- Define attributes
sheet:define("hp", 100, { min = 0, max = 200, regen = 1.0 })
sheet:define("mana", 50, { min = 0, max = 100, regen = 0.5 })
sheet:define("str", 8)

-- Define a derived stat
sheet:defineDerived("damage", function(self)
    return self:get("str") * 2 + 5
end)

-- Add a timed buff
local handle = sheet:addBuff("str", { add = 10, duration = 30, source = "potion" })

-- Define and use a skill
sheet:defineSkill("fireball", {
    maxLevel = 5,
    resource = "mana",
    cost = 15,
    cooldown = 2.0,
    use = function(sheet)
        print("Fireball cast! Damage: " .. sheet:get("damage"))
    end
})

-- Level-up observer
sheet:on("levelup", function(sheet, newLevel)
    print("Level up! Now level " .. newLevel)
end)

-- Game loop
function luna.update(dt)
    sheet:update(dt)  -- tick buffs and cooldowns
end
```

### Status Effects & Combat

```lua
-- Define a poison effect
local poison = luna.stats.newStatusEffect("poison", {
    duration = 10.0,
    tickInterval = 2.0,
    stackMode = "intensity",
    maxStacks = 3,
    positive = false,
    buffs = { { stat = "str", add = -2 } },
    onTick = function(sheet, effect)
        sheet:applyDamage("hp", 3 * effect:getStacks(), "poison")
    end,
    onExpire = function(sheet)
        print("Poison wore off")
    end,
})

-- Apply to sheet
sheet:setResistance("poison", 0.25)   -- 25% poison resistance
sheet:applyEffect(poison)

-- Combat with X-COM preset
local combat = luna.stats.newCombatResolver("xcom")
combat:setCoverModifier(0.5)  -- half cover

local result = combat:resolve(attacker, defender)
if result.hit then
    combat:applyResult(defender, result)
    print("Hit for " .. result.damage .. " damage!")
end
```

### Action Points & Turn-Based

```lua
-- Set up action points (X-COM time units)
sheet:setActionPoints(60)
sheet:setMorale(80, 100)
sheet:setPanicThreshold(20)
sheet:setInitiative(12)

-- Turn start
sheet:beginTurn()  -- refills AP

-- Actions consume AP
if sheet:spendActionPoints(25) then  -- 25 TU for a shot
    sheet:useSkill("aimed_shot")
end

-- Check morale after ally loss
sheet:adjustMorale(-30)
local state = sheet:checkMorale()
if state == "panic" then
    print("Unit panics!")
end

-- Initiative-based turn order
local order = {}
for _, unit in ipairs(units) do
    table.insert(order, { unit = unit, init = unit.sheet:rollInitiative() })
end
table.sort(order, function(a, b) return a.init > b.init end)
```

---

## Game Design Role

- **RPG character attributes**: Define strength, agility, intelligence, HP, mana with base values, min/max constraints, and regeneration.
- **Modifier stacking**: Additive and multiplicative buffs from equipment, potions, and abilities — all resolved automatically.
- **Temporary buffs**: Timed buffs expire via `update(dt)`; permanent buffs persist until explicitly removed.
- **Derived stats**: Computed values like "damage" that depend on other attributes — always up-to-date.
- **Skills & perks**: Cooldown-managed skills with resource costs; level-gated perk unlocks.
- **Traits & archetypes**: Race/class definitions bundle base stats and trait buffs for quick character creation.
- **Level system**: XP accumulation with configurable thresholds; `"levelup"` observer for triggering rewards.
- **Change callbacks**: Observe any stat change or level-up to trigger UI updates, achievements, or game logic.

---

## Module Boundaries

**vs luna.inventory** — Inventory manages items and equipment slots. When an item is equipped, its stat bonuses are applied as buffs on the Sheet. Inventory tracks *which items*; Stats tracks *what effect they have*.

**vs luna.quest** — Quest tracks game-progress flags ("boss_defeated", "stars_collected"). Stats tracks character-level numeric data (HP, strength, XP). They integrate when quest rewards grant XP or stat boosts.

**vs luna.entity** — Entity provides an ECS. A Sheet can be a component on a player or enemy entity. Systems read/write the Sheet during gameplay logic.

**vs luna.ai** — AI reads Sheet values (HP, morale, action points) to make decisions. An AI behavior tree might check `sheet:get("hp")` to decide whether to flee or fight.

---

## Recipes & Workflows

- **RPG character**: Define race + class archetypes. Create sheet with `newSheet({race="elf", class="mage"})`. Add attributes, skills, and perks.
- **Enemy scaling**: Create enemy sheets with base stats scaled by player level. Use multiplicative buffs for difficulty tiers.
- **Status effects**: Create StatusEffects for poison, burn, stun. Apply them to sheets during combat. Tick effects via `update(dt)`.
- **Boss phases**: Observe HP attribute. When HP drops below thresholds (75%, 50%, 25%), trigger phase transitions with new buff sets and skill activations.
- **Skill trees**: Use perks with level gates. Each acquired perk applies a trait that grants passive buffs or skill unlocks.

---

## Planned / To Implement

- **W1**: Stat definition helpers — preset stat templates for common RPG archetypes (warrior, mage, rogue).
- **W1**: Buff system polish — buff merging for same-source buffs, buff priority ordering.
- **W2**: Set bonuses — integration with `luna.inventory` ItemSets to automatically apply trait bundles when set conditions are met.
- **W2**: Stat change events — fire structured events (stat name, old value, new value, source) for analytics and replay.
- **W3**: Stat history — record stat changes over time for post-game analysis and replay visualization.

## Reimplementation Notes

- The `Sheet` object is the central data container — it holds **attributes** (named float values with min/max/regen), **buffs** (additive/multiplicative, timed or permanent), **traits** (named buff bundles), **skills** (with cooldowns, resource costs, use/passive callbacks), **perks** (level-gated trait unlocks), **flags** (boolean tags), and **XP/level** progression.
- Buffs stack using a handle system: `addBuff()` returns an integer handle for later removal. Buffs have `add` (additive) and `mul` (multiplicative, default 1.0) components, optional `duration` (-1 = permanent), and a `source` string.
- Effective stat value = `(base + sum_of_adds) * product_of_muls`, clamped to [min, max].
- `defineDerived(name, fn)` registers a Lua function that computes a derived stat from the sheet itself.
- Traits are globally defined via `luna.stats.defineTrait()` and applied to sheets via `sheet:addTrait()`.
- Race/class archetypes are module-level definitions that apply base overrides and traits to new sheets.
- Archetypes can include `allowedSkills`, `forbiddenSkills`, `allowedPerks`, `forbiddenPerks` constraints (unordered string sets).
- `update(dt)` ticks timed buff durations (removing expired) and skill cooldowns.
- The observer pattern via `on(name, fn)` fires on attribute changes or `"levelup"` events.
- `snapshot()`/`restore()` enables full serialisation of sheet state.
- `recordUse(name)` tracks stat exercise counts, potentially triggering growth (use-based levelling pattern).
- `setLevelThresholds()` accepts either a table of XP thresholds or a function for computed thresholds.
- All names (attributes, traits, skills, perks, flags) are plain strings — no integer IDs.
- **Status effects** extend the buff system with periodic tick callbacks, stacking modes, and immunity lists. Effects can be positive (buffs) or negative (debuffs). Each effect has a unique name and manages its own tick timer.
- **Combat resolver** provides formula-based combat calculation (accuracy, damage, critical hits). Formulas are pluggable Lua functions — presets for X-COM style (hit chance from accuracy vs. dodge, cover modifier), Fallout style (threshold damage reduction), and d20 style (roll + modifier vs. defense class) are provided.
- **Resistance system** on Sheet: resistances are named float values (e.g. `"fire"`, `"poison"`) that reduce incoming damage by a flat amount or percentage.
- **Action points / time units**: Sheet can define a TU budget for turn-based games (X-COM, Fallout). Skills and actions consume TU. `beginTurn()` refills the pool.
- **Morale**: A special attribute with automatic modifiers from combat events (ally loss, critical hit, mission success). Morale threshold triggers panic/berserk flags.
- **Formation bonuses**: Static bonus tables describing adjacency bonuses when units are positioned in defined formations. Applied as temporary traits.

## Dependencies

- None (self-contained module)

## Module Functions

| Function | Signature | Returns | Description |
|----------|-----------|---------|-------------|
| `newSheet` | `newSheet([opts])` | `Sheet` | Create a new character sheet. Optional table `opts` with `race` (string) and/or `class` (string) to apply archetypes at creation time. |
| `defineTrait` | `defineTrait(name, buffs)` | — | Define a named trait as a table of buff descriptors: `{ {stat="str", add=5}, {stat="agi", mul=0.8} }`. |
| `defineRace` | `defineRace(name, def)` | — | Define a race archetype. `def` table: `{bases={str=10, agi=8}, traits={"nightvision"}}`. |
| `defineClass` | `defineClass(name, def)` | — | Define a class archetype with optional skill/perk constraints. `def` table: `{bases={str=5}, traits={"heavy_armor"}, allowedSkills={}, forbiddenSkills={}, allowedPerks={}, forbiddenPerks={}}`. |
| `getTraitNames` | `getTraitNames()` | `table<string>` | Returns all registered trait names. |
| `getRaceNames` | `getRaceNames()` | `table<string>` | Returns all registered race names. |
| `getClassNames` | `getClassNames()` | `table<string>` | Returns all registered class names. |
| `newStatusEffect` | `newStatusEffect(name, def)` | `StatusEffect` | Create a status effect. `def` table: `{duration, tickInterval, onApply, onTick, onExpire, stackMode, maxStacks, buffs}`. |
| `newCombatResolver` | `newCombatResolver(preset?)` | `CombatResolver` | Create a combat resolver. Optional preset: `"xcom"`, `"fallout"`, `"d20"`. |
| `defineFormation` | `defineFormation(name, def)` | — | Define a named formation bonus. `def` table: `{positions={{dx,dy},...}, bonuses={{stat="str",add=2},...}}`. |
| `getFormationNames` | `getFormationNames()` | `table<string>` | Returns all registered formation names. |

## Type: Sheet

The primary data object representing a character's full stat sheet.

### Attribute Management

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `define` | `define(name, base [, opts])` | — | Define a named attribute with base value. Optional `opts` table: `{min=N, max=N, regen=N, growth=N}`. |
| `get` | `get(name)` | `number` | Get effective value (base + buff adds × buff muls, clamped). |
| `getBase` | `getBase(name)` | `number` | Get raw base value without modifiers. |
| `setBase` | `setBase(name, value)` | — | Set the base value directly. |
| `setMin` | `setMin(name, val)` | — | Set minimum constraint for attribute. |
| `setMax` | `setMax(name, val)` | — | Set maximum constraint for attribute. |
| `getMin` | `getMin(name)` | `number` | Get minimum constraint. |
| `getMax` | `getMax(name)` | `number` | Get maximum constraint. |
| `setRegen` | `setRegen(name, rate)` | — | Set regeneration rate (per second). |
| `getRegen` | `getRegen(name)` | `number` | Get regeneration rate. |
| `getAttributes` | `getAttributes()` | `table<string>` | Get all defined attribute names. |

### Buff System

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addBuff` | `addBuff(stat, buffDef)` or `addBuff(buffDef)` | `int` | Add a buff. Returns integer handle. `buffDef` table: `{stat?, add?, mul?, duration?, source?}`. Two-arg form: `addBuff("str", {add=5})`. Single-table form: `addBuff({stat="str", add=5})`. |
| `removeBuff` | `removeBuff(handle)` | `boolean` | Remove a buff by its handle. Returns true if found. |
| `clearBuffs` | `clearBuffs([stat])` | — | Remove all buffs, or only buffs on a specific stat. |
| `getBuffs` | `getBuffs([stat])` | `table` | Get buff descriptors, optionally filtered by stat. Each entry: `{handle, stat, add, mul, duration, source}`. |

### Derived Stats

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `defineDerived` | `defineDerived(name, fn)` | — | Register a Lua function `fn(sheet)` that computes a derived value. |

### Traits

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addTrait` | `addTrait(name)` | — | Apply a trait (must be defined via `luna.stats.defineTrait()`). Applies all its buffs. |
| `removeTrait` | `removeTrait(name)` | — | Remove a trait and all its associated buffs. |
| `hasTrait` | `hasTrait(name)` | `boolean` | Check if trait is active. |
| `getActiveTraits` | `getActiveTraits()` | `table<string>` | Get all active trait names. |

### Skills

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `defineSkill` | `defineSkill(name, def)` | — | Define a skill. `def` table: `{maxLevel=N, resource="mana", cost=N, cooldown=N, use=fn, passive=fn}`. |
| `useSkill` | `useSkill(name)` | `boolean` | Attempt to use a skill (checks resource and cooldown). Calls `use` callback if available. |
| `getSkillLevel` | `getSkillLevel(name)` | `int` | Get current skill level. |
| `upgradeSkill` | `upgradeSkill(name)` | `int` | Increase skill level by 1 (up to maxLevel). Returns new level. |
| `getCooldownRemaining` | `getCooldownRemaining(name)` | `number` | Get remaining cooldown time in seconds. |
| `resetCooldown` | `resetCooldown(name)` | — | Reset skill cooldown to zero. |
| `hasSkill` | `hasSkill(name)` | `boolean` | Check if skill is defined on this sheet. |
| `getSkillNames` | `getSkillNames()` | `table<string>` | Get all defined skill names. |
| `activatePassive` | `activatePassive(name)` | — | Activate the passive callback for a named skill. |
| `deactivatePassive` | `deactivatePassive(name)` | — | Deactivate the passive callback for a named skill. |

### Perks

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `definePerk` | `definePerk(name, def)` | — | Define a perk. `def` table: `{requireLevel=N, trait="traitName"}`. |
| `addPerk` | `addPerk(name)` | `boolean` | Attempt to acquire a perk (checks level requirement). Returns true if successful. |
| `hasPerk` | `hasPerk(name)` | `boolean` | Check if perk has been acquired. |
| `getAvailablePerks` | `getAvailablePerks()` | `table<string>` | Get perk names where conditions are met but not yet acquired. |
| `getAcquiredPerks` | `getAcquiredPerks()` | `table<string>` | Get all acquired perk names. |

### Levelling & XP

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addXP` | `addXP(amount)` | — | Add experience points. May trigger one or more level-ups. |
| `getXP` | `getXP()` | `int` | Get total accumulated XP. |
| `setXP` | `setXP(amount)` | — | Set XP directly. |
| `getLevel` | `getLevel()` | `int` | Get current character level. |
| `setLevel` | `setLevel(lvl)` | — | Set level directly. |
| `setLevelThresholds` | `setLevelThresholds(thresholds)` | — | Set XP thresholds as a table `{100, 250, 500, ...}` or a function `fn(level) → requiredXP`. |

### Stat Exercise

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `recordUse` | `recordUse(name)` | — | Record a use of a stat, potentially triggering growth. |
| `getUseCount` | `getUseCount(name)` | `int` | Get total exercise count for a stat. |

### Flags

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setFlag` | `setFlag(name)` | — | Set a boolean flag. |
| `clearFlag` | `clearFlag(name)` | — | Clear a boolean flag. |
| `hasFlag` | `hasFlag(name)` | `boolean` | Check if flag is set. |
| `getFlags` | `getFlags()` | `table<string>` | Get all set flag names. |

### Observers & Updates

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `update` | `update(dt)` | — | Tick timed buffs (removing expired) and skill cooldowns by `dt` seconds. |
| `on` | `on(name, fn)` | — | Register observer callback. `name` can be an attribute name, `"*"` (any change), or `"levelup"`. |

### Serialisation

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `snapshot` | `snapshot()` | `table` | Serialise full sheet state for saving. |
| `restore` | `restore(data)` | — | Restore sheet state from a snapshot table. |

### Action Points / Time Units

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setActionPoints` | `setActionPoints(max, current?)` | — | Set the action point (TU) budget. `current` defaults to `max`. |
| `getActionPoints` | `getActionPoints()` | `current, max` | Get current and max action points. |
| `spendActionPoints` | `spendActionPoints(amount)` | `boolean` | Spend action points. Returns false if insufficient. |
| `beginTurn` | `beginTurn()` | — | Refill action points to max. Reset per-turn cooldowns. |
| `hasActionPoints` | `hasActionPoints(amount)` | `boolean` | Check if at least `amount` AP is available. |

### Morale

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setMorale` | `setMorale(value, max?)` | — | Set morale value. `max` defaults to 100. |
| `getMorale` | `getMorale()` | `current, max` | Get current and max morale. |
| `adjustMorale` | `adjustMorale(delta)` | — | Modify morale by `delta` (positive or negative). Clamps to [0, max]. |
| `setPanicThreshold` | `setPanicThreshold(value)` | — | Set morale level below which the unit panics (sets `"panic"` flag). |
| `setBerserkThreshold` | `setBerserkThreshold(value)` | — | Set morale level below which the unit goes berserk (sets `"berserk"` flag). |
| `checkMorale` | `checkMorale()` | `string\|nil` | Check morale state. Returns `"panic"`, `"berserk"`, or nil (normal). |

### Resistances

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setResistance` | `setResistance(type, value)` | — | Set a named resistance value (0–1 range for percentage, or flat amount). |
| `getResistance` | `getResistance(type)` | `number` | Get resistance value for a damage type. Returns 0 if not defined. |
| `getResistanceNames` | `getResistanceNames()` | `table<string>` | Get all defined resistance type names. |
| `applyDamage` | `applyDamage(stat, amount, damageType?)` | `number` | Apply damage to a stat, reduced by resistance. Returns actual damage dealt. |

### Status Effects

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `applyEffect` | `applyEffect(effect)` | `boolean` | Apply a StatusEffect to this sheet. Returns false if immune. |
| `removeEffect` | `removeEffect(name)` | — | Remove a status effect by name. |
| `hasEffect` | `hasEffect(name)` | `boolean` | Check if a status effect is active. |
| `getActiveEffects` | `getActiveEffects()` | `table<string>` | Get names of all active status effects. |
| `addImmunity` | `addImmunity(effectName)` | — | Make this sheet immune to a named status effect. |
| `removeImmunity` | `removeImmunity(effectName)` | — | Remove immunity to a status effect. |
| `isImmune` | `isImmune(effectName)` | `boolean` | Check if immune to a named status effect. |

### Initiative & Encumbrance

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setInitiative` | `setInitiative(value)` | — | Set base initiative value (used for turn order). |
| `getInitiative` | `getInitiative()` | `number` | Get effective initiative (base + buffs). |
| `rollInitiative` | `rollInitiative()` | `number` | Roll initiative with randomness: `initiative + random(1, 10)`. |
| `setEncumbrance` | `setEncumbrance(current, max)` | — | Set current and max carrying capacity. |
| `getEncumbrance` | `getEncumbrance()` | `current, max` | Get current and max carrying capacity. |
| `isEncumbered` | `isEncumbered()` | `boolean` | Check if current weight exceeds max capacity. |
| `getEncumbrancePenalty` | `getEncumbrancePenalty()` | `number` | Get movement/AP penalty factor from encumbrance (1.0 = no penalty). |

### Formation

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `applyFormation` | `applyFormation(name)` | — | Apply a defined formation's bonuses as temporary traits. |
| `removeFormation` | `removeFormation()` | — | Remove any active formation bonuses. |
| `getActiveFormation` | `getActiveFormation()` | `string\|nil` | Get the name of the active formation, or nil. |

## Attribute Management

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `define` | `define(name, base [, opts])` | — | Define a named attribute with base value. Optional `opts` table: `{min=N, max=N, regen=N, growth=N}`. |
| `get` | `get(name)` | `number` | Get effective value (base + buff adds × buff muls, clamped). |
| `getBase` | `getBase(name)` | `number` | Get raw base value without modifiers. |
| `setBase` | `setBase(name, value)` | — | Set the base value directly. |
| `setMin` | `setMin(name, val)` | — | Set minimum constraint for attribute. |
| `setMax` | `setMax(name, val)` | — | Set maximum constraint for attribute. |
| `getMin` | `getMin(name)` | `number` | Get minimum constraint. |
| `getMax` | `getMax(name)` | `number` | Get maximum constraint. |
| `setRegen` | `setRegen(name, rate)` | — | Set regeneration rate (per second). |
| `getRegen` | `getRegen(name)` | `number` | Get regeneration rate. |
| `getAttributes` | `getAttributes()` | `table<string>` | Get all defined attribute names. |

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 2 |
| `mod` | 3 |
| `struct` | 9 |
| **Total** | **14** |

