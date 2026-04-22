# `library.battle`

*96 functions, 0 module fields documented.*

## Functions

### `newStatusEffect(name, duration)`

Create a new status effect.

**Parameters**

- `name` *string* — Effect identifier (must be a non-empty string).
- `duration` *number* — Turns remaining (-1 = permanent).

**Returns**

- *StatusEffect*

### `getName()`

Get the effect name.

**Returns**

- *string*

### `getDuration()`

Get remaining duration (-1 = permanent).

**Returns**

- *number*

### `setDuration(v)`

Set remaining duration.

**Parameters**

- `v` *number*

### `getStacks()`

Get current stack count.

**Returns**

- *number*

### `setStacks(v)`

Set stack count.

**Parameters**

- `v` *number*

### `tickTurn()`

Tick one turn. Returns true when the effect has just expired.

**Returns**

- *boolean*

### `isExpired()`

Is the effect expired?

**Returns**

- *boolean*

### `newAction(name)`

Create a new combat action.

**Parameters**

- `name` *string* — Action identifier (must be a non-empty string).

**Returns**

- *CombatAction*

### `getName()`

Get the action name.

**Returns**

- *string*

### `getBaseDamage()`

Get base damage value.

**Returns**

- *number*

### `setBaseDamage(v)`

Set base damage value.

**Parameters**

- `v` *number*

### `getDamageType()`

Get damage type string.

**Returns**

- *string*

### `setDamageType(v)`

Set damage type string (defaults to "physical").

**Parameters**

- `v` *string*

### `getAccuracy()`

Get accuracy clamped to [0, 1].

**Returns**

- *number*

### `setAccuracy(v)`

Set accuracy, clamped to [0, 1].

**Parameters**

- `v` *number*

### `getCooldown()`

Get max cooldown turns.

**Returns**

- *number*

### `setCooldown(v)`

Set max cooldown turns.

**Parameters**

- `v` *number*

### `getCurrentCooldown()`

Get current remaining cooldown turns.

**Returns**

- *number*

### `getCostHp()`

Get HP cost to use this action.

**Returns**

- *number*

### `setCostHp(v)`

Set HP cost.

**Parameters**

- `v` *number*

### `getCostMp()`

Get MP cost to use this action.

**Returns**

- *number*

### `setCostMp(v)`

Set MP cost.

**Parameters**

- `v` *number*

### `isReady()`

Is the action off cooldown?

**Returns**

- *boolean*

### `useAction()`

Put the action on cooldown.

### `tickCooldown()`

Tick cooldown by one.

### `newCombatant(name)`

Create a new combatant.

**Parameters**

- `name` *string* — Combatant identifier (must be a non-empty string).

**Returns**

- *Combatant*

### `getName()`

Get combatant name.

**Returns**

- *string*

### `getTeam()`

Get team identifier string.

**Returns**

- *string*

### `setTeam(v)`

Set team identifier (defaults to "player").

**Parameters**

- `v` *string*

### `getHp()`

Get current HP.

**Returns**

- *number*

### `setHp(v)`

Set current HP directly (use takeDamage/heal for safe HP changes).

**Parameters**

- `v` *number*

### `getMaxHp()`

Get maximum HP.

**Returns**

- *number*

### `setMaxHp(v)`

Set maximum HP.

**Parameters**

- `v` *number*

### `getMp()`

Get current MP.

**Returns**

- *number*

### `setMp(v)`

Set current MP.

**Parameters**

- `v` *number*

### `getMaxMp()`

Get maximum MP.

**Returns**

- *number*

### `setMaxMp(v)`

Set maximum MP.

**Parameters**

- `v` *number*

### `getSpeed()`

Get speed (used for initiative ordering; higher = sooner).

**Returns**

- *number*

### `setSpeed(v)`

Set speed.

**Parameters**

- `v` *number*

### `getLevel()`

Get combatant level.

**Returns**

- *number*

### `setLevel(v)`

Set combatant level.

**Parameters**

- `v` *number*

### `isAlive()`

Is the combatant alive?

**Returns**

- *boolean*

### `takeDamage(amount, damage_type)`

Apply damage, factoring in resistance. Resistance is a multiplier (default 1.0).

**Parameters**

- `amount` *number* — Raw damage amount (must be >= 0).
- `damage_type` *string*

**Returns**

- *number* — actual damage dealt

### `heal(amount)`

Heal the combatant.

**Parameters**

- `amount` *number* — Heal amount (must be >= 0).

**Returns**

- *number* — actual amount healed

### `addStatus(name, duration)`

Add or stack a status effect.

**Parameters**

- `name` *string* — Effect name (must be a non-empty string).
- `duration` *number*

### `removeStatus(name)`

Remove a status effect by name.

**Parameters**

- `name` *string*

### `hasStatus(name)`

Check if a status is active.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `tickStatuses()`

Tick all status effects, removing expired ones.

**Returns**

- *table* — Array of expired status names.

### `getStatuses()`

Get array of {name, duration, stacks} tables.

**Returns**

- *table*

### `getStat(name)`

Get a named stat value (defaults to 0).

**Parameters**

- `name` *string*

**Returns**

- *number*

### `setStat(name, value)`

Set a named stat.

**Parameters**

- `name` *string*
- `value` *number*

### `getResistance(dtype)`

Get damage resistance for a type (defaults to 1.0 = full damage).

**Parameters**

- `dtype` *string*

**Returns**

- *number*

### `setResistance(dtype, value)`

Set damage resistance for a type.

**Parameters**

- `dtype` *string*
- `value` *number*

### `getHpPercent()`

HP as a percentage (0-100).

**Returns**

- *number*

### `getMpPercent()`

MP as a percentage (0-100).

**Returns**

- *number*

### `addAction(action)`

Add a combat action (deep clone of the action).

**Parameters**

- `action` *CombatAction* — The action to clone and add.

### `getAction(name)`

Get an action by name.

**Parameters**

- `name` *string*

**Returns**

- *CombatAction|nil*

### `hasAction(name)`

Check if the combatant has an action.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `tickCooldowns()`

Tick all action cooldowns.

### `getActionNames()`

Get array of action names.

**Returns**

- *table*

### `getStatusNames()`

Get array of status effect names.

**Returns**

- *table*

### `getMeta(key)`

Get metadata value.

**Parameters**

- `key` *string*

**Returns**

- *any|nil*

### `setMeta(key, value)`

Set metadata value.

**Parameters**

- `key` *string*
- `value` *any*

### `newBattle(name)`

Create a new battle.

**Parameters**

- `name` *string* — Battle display name.

**Returns**

- *CombatBattle*

### `getName()`

Get battle display name.

**Returns**

- *string*

### `getCount()`

Get total number of combatants (alive and dead).

**Returns**

- *number*

### `getTurnCount()`

Get total completed turn count.

**Returns**

- *number*

### `isOver()`

Returns true when the battle has ended.

**Returns**

- *boolean*

### `getWinner(auto_detect)`

Returns the winning team name, or nil if not yet over. When auto_detect is true, checks battle state before returning.

**Parameters**

- `auto_detect` *boolean* — Run battle-over check first.

**Returns**

- *string|nil*

### `getLog()`

Returns the battle log as an array of strings.

**Returns**

- *table*

### `addToLog(msg)`

Add a log entry.

**Parameters**

- `msg` *string*

### `addCombatant(c)`

Add a combatant (deep clone).

**Parameters**

- `c` *Combatant* — The combatant to clone and add.

### `getCombatant(name)`

Get a combatant by name (returns reference inside battle).

**Parameters**

- `name` *string*

**Returns**

- *Combatant|nil*

### `sortInitiative()`

Sort combatants by speed (descending).

### `getCurrentCombatant()`

Get the current alive combatant.

**Returns**

- *Combatant|nil*

### `nextTurn()`

Advance to next turn. Returns false if battle is over.

**Returns**

- *boolean*

### `_checkBattleOver()`

Check if battle is over (one team or fewer alive).

### `attack(attacker_name, action_name, target_name)`

Resolve an attack. TODO(P4 lift): switch to lurek.math.newRng() for seedable, deterministic battle replays. Currently uses the global Lua RNG which makes saves non-deterministic across reloads.

**Parameters**

- `attacker_name` *string*
- `action_name` *string*
- `target_name` *string*

**Returns**

- *table|nil* — CombatResult table or nil if invalid.

See: [`lurek.math`](../lua-api.md#lurekmath)

```lua
local r = battle:attack("hero", "slash", "goblin")
if r and r.hit then print(r.message) end
```

### `getAliveNames()`

Get names of all alive combatants.

**Returns**

- *table*

### `getAllNames()`

Get names of all combatants.

**Returns**

- *table*

### `removeCombatant(name)`

Remove a combatant by name.

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `forceEnd(winner)`

Force-end the battle with a specified winner.

**Parameters**

- `winner` *string*

### `tickAllStatuses()`

Tick all combatant statuses.

### `tickAllActions()`

Tick all combatant action cooldowns.

### `resolve()`

Resolve end-of-round bookkeeping: tick all statuses, tick all cooldowns, and check whether the battle has ended.

**Returns**

- *boolean* — true if the battle is still in progress

### `addTag(tag)`

Add a tag to this action (no-op if already present).

**Parameters**

- `tag` *string*

### `removeTag(tag)`

Remove a tag. Returns true if it existed.

**Parameters**

- `tag` *string*

**Returns**

- *boolean*

### `hasTag(tag)`

Return true if the action has the given tag.

**Parameters**

- `tag` *string*

**Returns**

- *boolean*

### `getTags()`

Return a sorted list of all tags on this action.

**Returns**

- *table*

### `getMeta(key)`

Get a metadata value (string key -> any).

**Parameters**

- `key` *string*

**Returns**

- *any*

### `setMeta(key, val)`

Set a metadata value.

**Parameters**

- `key` *string*
- `val` *any*

### `getMeta(key)`

Get a metadata value from the status effect's data table.

**Parameters**

- `key` *string*

**Returns**

- *any*

### `setMeta(key, val)`

Set a metadata value.

**Parameters**

- `key` *string*
- `val` *any*

### `getMetadata(key)`

Alias: getMetadata (matches Rust name).

**Parameters**

- `key` *string*

**Returns**

- *any*

### `setMetadata(key, val)`

Alias: setMetadata (matches Rust name).

**Parameters**

- `key` *string*
- `val` *any*
