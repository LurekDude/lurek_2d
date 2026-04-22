# `library.stats`

*83 functions, 0 module fields documented.*

## Functions

### `newAttribute(base)`

Create a new attribute.

**Parameters**

- `base` *number* — Base value.

**Returns**

- *Attribute*

### `newBuff(stat, add, mul, duration, source)`

Create a new buff.

**Parameters**

- `stat` *string* — Attribute name.
- `add` *number* — Additive bonus.
- `mul` *number* — Multiplicative factor (default 1).
- `duration` *number* — Seconds (-1 = permanent).
- `source` *string* — Descriptive source.

**Returns**

- *Buff*

### `isExpired()`

Whether the buff has expired.

**Returns**

- *boolean*

### `newSkill(opts)`

Create a new skill.

**Parameters**

- `opts` *table|nil* — Optional: max_level, resource, cost, cooldown.

**Returns**

- *Skill*

### `newPerk(opts)`

Create a new perk.

**Parameters**

- `opts` *table|nil* — Optional: require_level, trait_name.

**Returns**

- *Perk*

### `newActionPoints(max_val)`

Create action points with the given maximum.

**Parameters**

- `max_val` *number* — Maximum (and initial) action points.

**Returns**

- *ActionPoints*

### `newMorale(max_val)`

Create a morale tracker with the given maximum (current starts at max).

**Parameters**

- `max_val` *number* — Maximum morale value.

**Returns**

- *Morale*

### `newTableThresholds(values)`

Create table-based XP thresholds (one value per level).

**Parameters**

- `values` *table* — Array of numbers; values[n] is XP required for level n.

**Returns**

- *LevelThresholds*

### `newLinearThresholds(base, increment)`

Create linear XP thresholds using the formula base + (level-1)*increment.

**Parameters**

- `base` *number* — XP required for level 1.
- `increment` *number* — Additional XP required per subsequent level.

**Returns**

- *LevelThresholds*

### `thresholdFor(level)`

Return the XP required to advance past the given level.

**Parameters**

- `level` *number* — Current level (1-based).

**Returns**

- *number* — XP threshold (math.huge if beyond the table).

### `newTraitDef(buffs)`

Create a trait definition.

**Parameters**

- `buffs` *table* — Array of {stat, add, mul} tables.

**Returns**

- *table* — TraitDef.

### `defineTrait(name, def)`

Register a named trait definition in the module registry.

**Parameters**

- `name` *string* — Unique trait name.
- `def` *table* — TraitDef created with M.newTraitDef.

### `defineRace(name, def)`

Register a named race archetype.

**Parameters**

- `name` *string* — Unique race name.
- `def` *table* — Table with optional keys: bases (stat overrides) and traits (list of trait names).

### `defineClass(name, def)`

Register a named class archetype.

**Parameters**

- `name` *string* — Unique class name.
- `def` *table* — Table with optional keys: bases (stat overrides) and traits (list of trait names).

### `getTraitNames()`

Return a sorted list of all registered trait names.

**Returns**

- *table* — Sorted array of strings.

### `getRaceNames()`

Return a sorted list of all registered race names.

**Returns**

- *table* — Sorted array of strings.

### `getClassNames()`

Return a sorted list of all registered class names.

**Returns**

- *table* — Sorted array of strings.

### `applyArchetypes(sheet, race_name, class_name)`

Apply race and/or class archetypes to an existing sheet. Base stat bonuses are added and listed traits are applied as permanent buffs.

**Parameters**

- `sheet` *Sheet* — The target sheet.
- `race_name` *string|nil* — Registered race name, or nil to skip.
- `class_name` *string|nil* — Registered class name, or nil to skip.

### `newSheet()`

Create a new character sheet.

**Returns**

- *Sheet*

### `define(name, base, opts)`

Define a named attribute.

**Parameters**

- `name` *string* — Attribute name.
- `base` *number* — Base value.
- `opts` *table|nil* — Optional: min, max, regen, growth.

### `get(name)`

Get effective value (base * multipliers + additive, clamped).

**Parameters**

- `name` *string* — Attribute name.

**Returns**

- *number|nil* — Effective value or nil if attribute not defined.

### `getBase(name)`

Get raw base value.

### `setBase(name, value)`

Set base value (clamped to min/max).

### `setMin(name, val)`

Set the minimum clamp value for an attribute.

**Parameters**

- `name` *string* — Attribute name.
- `val` *number* — New minimum.

### `setMax(name, val)`

Set the maximum clamp value for an attribute.

**Parameters**

- `name` *string* — Attribute name.
- `val` *number* — New maximum.

### `getMin(name)`

Get the current minimum clamp for an attribute.

**Parameters**

- `name` *string* — Attribute name.

**Returns**

- *number|nil*

### `getMax(name)`

Get the current maximum clamp for an attribute.

**Parameters**

- `name` *string* — Attribute name.

**Returns**

- *number|nil*

### `setRegen(name, val)`

Set the regeneration rate for an attribute.

**Parameters**

- `name` *string* — Attribute name.
- `val` *number* — Regen per second.

### `getRegen(name)`

Get the regeneration rate for an attribute.

**Parameters**

- `name` *string* — Attribute name.

**Returns**

- *number|nil*

### `getStatNames()`

Get all defined attribute names.

### `addBuff(stat, add, mul, duration, source, stack_mode)`

Add a buff to the sheet and return its numeric handle. When stack_mode is provided and a duplicate buff exists (same stat + source), the mode controls behavior: None rejects, Duration extends, Intensity increases.

**Parameters**

- `stat` *string* — Attribute to modify.
- `add` *number* — Additive bonus.
- `mul` *number* — Multiplicative factor (1 = no change).
- `duration` *number* — Seconds until expiry (-1 = permanent).
- `source` *string* — Descriptive label.
- `stack_mode` *string|nil* — StackMode value for duplicate handling (nil = always add).

**Returns**

- *number|nil* — Handle for later removal, or nil if rejected by StackMode.None.

### `removeBuff(handle)`

Remove a buff by its numeric handle.

**Parameters**

- `handle` *number* — Handle returned by addBuff.

**Returns**

- *boolean* — True if the buff was found and removed.

### `clearBuffs(stat)`

Remove all active buffs, or only those affecting a specific attribute.

**Parameters**

- `stat` *string|nil* — If given, only buffs for this attribute are removed.

### `getBuffs(stat)`

Return all active (non-expired) buffs as an array of info tables. Each entry has: handle, stat, add, mul, duration, remaining, source.

**Parameters**

- `stat` *string|nil* — If given, filter to buffs affecting this attribute.

**Returns**

- *table* — Array of buff-info tables.

### `getBuffCount(stat)`

Count active (non-expired) buffs, optionally limited to one attribute.

**Parameters**

- `stat` *string|nil* — If given, count only buffs for this attribute.

**Returns**

- *number*

### `applyTraitBuffs(trait_name)`

Apply a registered trait's permanent buffs to this sheet.

**Parameters**

- `trait_name` *string* — Name of a trait registered with M.defineTrait.

**Returns**

- *table* — Array of buff handles for the applied buffs.

### `removeTraitBuffs(trait_name)`

Remove all buffs that were applied by a named trait.

**Parameters**

- `trait_name` *string* — Trait to remove.

**Returns**

- *boolean* — True if the trait was active and its buffs were removed.

### `hasTrait(name)`

Return true if a named trait is currently active on this sheet.

**Parameters**

- `name` *string* — Trait name.

**Returns**

- *boolean*

### `getActiveTraits()`

Return a sorted list of all currently active trait names.

**Returns**

- *table* — Sorted array of strings.

### `defineSkill(name, opts)`

Define a named skill on this sheet.

**Parameters**

- `name` *string* — Skill name.
- `opts` *table|nil* — Options: max_level, resource, cost, cooldown.

### `learnSkill(name)`

Advance a skill by one level. Returns false if already at max level or unknown.

**Parameters**

- `name` *string* — Skill name.

**Returns**

- *boolean*

### `useSkill(name)`

Attempt to use a skill: deducts cost and starts cooldown. Returns false plus a reason string on failure.

**Parameters**

- `name` *string* — Skill name.

**Returns**

- *boolean,* — string|nil Success flag and optional failure reason.

### `getSkillLevel(name)`

Get the current level of a named skill (0 = not learned).

**Parameters**

- `name` *string* — Skill name.

**Returns**

- *number*

### `getCooldownRemaining(name)`

Get the remaining cooldown in seconds for a named skill.

**Parameters**

- `name` *string* — Skill name.

**Returns**

- *number* — Seconds remaining (0 when ready).

### `definePerk(name, opts)`

Define a named perk on this sheet.

**Parameters**

- `name` *string* — Perk name.
- `opts` *table|nil* — Options: require_level, trait_name.

### `acquirePerk(name)`

Acquire a perk if requirements are met. Returns false if already acquired or level too low.

**Parameters**

- `name` *string* — Perk name.

**Returns**

- *boolean*

### `hasPerk(name)`

Return true if a named perk has been acquired.

**Parameters**

- `name` *string* — Perk name.

**Returns**

- *boolean*

### `setFlag(name)`

Set a boolean flag on this sheet.

**Parameters**

- `name` *string* — Flag name.

### `clearFlag(name)`

Clear (remove) a boolean flag.

**Parameters**

- `name` *string* — Flag name.

### `hasFlag(name)`

Return true if a boolean flag is set.

**Parameters**

- `name` *string* — Flag name.

**Returns**

- *boolean*

### `getFlags()`

Return a sorted list of all set flag names.

**Returns**

- *table* — Sorted array of strings.

### `addXP(amount)`

Award XP and apply automatic level-ups. Returns the number of levels gained.

**Parameters**

- `amount` *number* — XP to award (must be non-negative).

**Returns**

- *number* — Levels gained (0 if none or invalid input).

### `getXP()`

Return the current accumulated XP.

**Returns**

- *number*

### `setXP(v)`

Directly set the accumulated XP (does not trigger level-ups).

**Parameters**

- `v` *number*

### `getLevel()`

Return the current level.

**Returns**

- *number*

### `setLevel(v)`

Directly set the character level.

**Parameters**

- `v` *number*

### `setLevelThresholds(t)`

Replace the level threshold configuration.

**Parameters**

- `t` *LevelThresholds* — New thresholds object.

### `recordUse(name)`

Record a use of a stat for use-based levelling. Applies growth if configured.

**Parameters**

- `name` *string* — Attribute name.

### `getUseCount(name)`

Return the number of recorded uses of an attribute.

**Parameters**

- `name` *string* — Attribute name.

**Returns**

- *number*

### `setActionPoints(max_val)`

Initialise action points with the given maximum (current also set to max).

**Parameters**

- `max_val` *number* — Maximum AP.

### `getActionPoints()`

Return current and maximum action points.

**Returns**

- *number,* — number Current AP, maximum AP.

### `spendActionPoints(amount)`

Spend action points. Returns false if insufficient AP.

**Parameters**

- `amount` *number* — AP to spend.

**Returns**

- *boolean*

### `beginTurn()`

Reset current AP to maximum (call at the start of each turn).

### `recoverActionPoints(amount)`

Recover AP (partial restore), capped at maximum. Returns new current value.

**Parameters**

- `amount` *number* — AP to recover.

**Returns**

- *number* — New current AP.

### `setMorale(max_val)`

Initialise the morale tracker with the given maximum.

**Parameters**

- `max_val` *number* — Maximum morale value.

### `getMorale()`

Return current and maximum morale values.

**Returns**

- *number,* — number Current morale, maximum morale.

### `adjustMorale(delta)`

Adjust morale by a delta (positive or negative), clamped to [0, max].

**Parameters**

- `delta` *number* — Change amount.

### `setPanicThreshold(val)`

Set the morale value below which the unit enters panic.

**Parameters**

- `val` *number* — Panic threshold.

### `setBerserkThreshold(val)`

Set the morale value below which the unit goes berserk.

**Parameters**

- `val` *number* — Berserk threshold.

### `checkMorale()`

Evaluate morale level and update panic/berserk flags.

**Returns**

- *string|nil* — "panic", "berserk", or nil if morale is normal.

### `setResistance(dtype, val)`

Set resistance to a damage type (clamped to [0, 1]).

**Parameters**

- `dtype` *string* — Damage type name (e.g. "fire").
- `val` *number* — Resistance fraction (0 = none, 1 = immune).

### `getResistance(dtype)`

Return the resistance fraction for a damage type (default 0).

**Parameters**

- `dtype` *string* — Damage type name.

**Returns**

- *number*

### `applyDamage(stat, amount, dtype)`

Apply damage to an attribute, reduced by resistance. Returns actual damage dealt.

**Parameters**

- `stat` *string* — Attribute to damage (typically "hp").
- `amount` *number* — Raw incoming damage.
- `dtype` *string|nil* — Damage type for resistance lookup.

**Returns**

- *number* — Actual damage applied after resistance.

### `setEncumbrance(cur, max_val)`

Set current encumbrance and its maximum capacity.

**Parameters**

- `cur` *number* — Current carried weight.
- `max_val` *number* — Maximum capacity before encumbered.

### `getEncumbrance()`

Return current and maximum encumbrance values.

**Returns**

- *number,* — number Current weight, maximum capacity.

### `isEncumbered()`

Return true if current weight exceeds the encumbrance limit.

**Returns**

- *boolean*

### `setInitiative(val)`

Set the sheet's base initiative value.

**Parameters**

- `val` *number* — Initiative value.

### `getInitiative()`

Return the current initiative value.

**Returns**

- *number*

### `update(dt)`

Advance time: tick buff durations, skill cooldowns, apply regen.

**Parameters**

- `dt` *number* — Elapsed seconds.

### `snapshot()`

Capture a snapshot of the sheet's core state (attributes, XP, level, flags, resistances, AP, morale).

**Returns**

- *table* — Snapshot table suitable for Sheet:restore.

### `restore(snap)`

Restore sheet state from a snapshot previously created by Sheet:snapshot.

**Parameters**

- `snap` *table* — Snapshot table created by Sheet:snapshot.

### `snapshotToJson(snap)`

Encode a snapshot table to a JSON string via `lurek.serial.toJson`.

**Parameters**

- `snap` *table* — Snapshot produced by `Sheet:snapshot`.

**Returns**

- *string* — JSON-encoded snapshot.

See: [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson)

### `snapshotFromJson(str)`

Decode a JSON snapshot string back into a Lua table via `lurek.serial.fromJson`. The returned table can be passed to `Sheet:restore`.

**Parameters**

- `str` *string* — JSON-encoded snapshot.

**Returns**

- *table* — Decoded snapshot.

See: [`lurek.serial.fromJson`](../lua-api.md#lurekcodecfromjson)
