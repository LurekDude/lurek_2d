# `library.economy`

*126 functions, 0 module fields documented.*

## Functions

### `newResource(name, capacity)`

Create a new named resource.

**Parameters**

- `name` *string* — Resource name (must be a non-empty string).
- `capacity` *number* — Maximum value (-1 = unlimited, must be >= -1).

**Returns**

- *Resource*

### `_clamp(v)`

Clamp a value to [minimum, capacity]. Delegates to `lurek.math.clamp` when the engine binding is available; falls back to the inline branchy form when running outside Lurek2D.

### `getName()`

**Returns**

- *string* — Resource name.

### `getValue()`

**Returns**

- *number* — Current resource value.

### `setValue(v)`

Set the resource value (clamped).

**Parameters**

- `v` *number*

### `getCapacity()`

**Returns**

- *number* — Capacity (-1 = unlimited).

### `setCapacity(c)`

Set maximum capacity. Re-clamps value.

**Parameters**

- `c` *number* — New capacity (>= -1; -1 = unlimited).

### `getMinimum()`

**Returns**

- *number* — Minimum value.

### `setMinimum(m)`

Set minimum value. Re-clamps value.

**Parameters**

- `m` *number* — New minimum.

### `getOverflow()`

**Returns**

- *string* — Overflow policy ("clamp", "lose", or "wrap").

### `setOverflow(p)`

Set overflow policy.

**Parameters**

- `p` *string* — One of "clamp", "lose", "wrap".

### `getFlowRate()`

**Returns**

- *number* — Flow rate per tick.

### `setFlowRate(r)`

Set the per-second flow rate (income).

**Parameters**

- `r` *number* — Flow rate.

### `getDecayRate()`

**Returns**

- *number* — Flat decay rate per tick.

### `setDecayRate(r)`

Set the per-second flat decay rate.

**Parameters**

- `r` *number* — Decay rate.

### `getDecayPercent()`

**Returns**

- *number* — Proportional decay rate per tick.

### `setDecayPercent(p)`

Set the per-second proportional decay (0.1 = 10%/s).

**Parameters**

- `p` *number* — Decay percent.

### `getInterestRate()`

**Returns**

- *number* — Interest rate per tick.

### `setInterestRate(r)`

Set the per-second proportional interest rate.

**Parameters**

- `r` *number* — Interest rate.

### `getUpkeep()`

**Returns**

- *number* — Upkeep cost per turn.

### `setUpkeep(u)`

Set the per-second upkeep cost.

**Parameters**

- `u` *number* — Upkeep cost.

### `getGroup()`

**Returns**

- *string* — Resource group.

### `setGroup(g)`

Set the group tag for this resource.

**Parameters**

- `g` *string* — Group name.

### `isEnabled()`

**Returns**

- *boolean* — True if tick processing is enabled.

### `setEnabled(e)`

Enable or disable tick processing.

**Parameters**

- `e` *boolean* — Enabled state.

### `isVisible()`

**Returns**

- *boolean* — UI visibility hint.

### `setVisible(v)`

Set the UI visibility hint.

**Parameters**

- `v` *boolean* — Visibility.

### `isLocked()`

**Returns**

- *boolean* — True if add/spend is blocked.

### `setLocked(l)`

Lock or unlock add/spend modifications.

**Parameters**

- `l` *boolean* — Locked state.

### `getReserved()`

**Returns**

- *number* — Amount currently reserved.

### `getAvailable()`

**Returns**

- *number* — Available = value - reserved.

### `getNetRate()`

Net rate per tick (flow - decay - upkeep + interest - proportional_decay). The result is clamped so that applying it for one second will not drive the resource below its minimum.

**Returns**

- *number*

### `add(amount)`

Add amount to the resource. Returns the excess.

**Parameters**

- `amount` *number* — Amount to add (must be non-negative).

**Returns**

- *number* — excess  Amount that did not fit.

### `spend(amount)`

Spend an amount if available. Returns true on success.

**Parameters**

- `amount` *number* — Amount to spend (must be non-negative).

**Returns**

- *boolean* — True if the spend succeeded.

### `canAfford(amount)`

Check if the resource can afford the amount.

**Parameters**

- `amount` *number*

**Returns**

- *boolean*

### `reserve(amount)`

Reserve an amount (reduces available without changing value). Reserved is clamped so it cannot exceed the current value.

**Parameters**

- `amount` *number* — Amount to reserve (must be non-negative).

### `unreserve(amount)`

Release a reservation. Clamped to [0, value].

**Parameters**

- `amount` *number* — Amount to unreserve (must be non-negative).

### `tick(dt)`

Advance the resource by dt seconds (flow, decay, interest, proportional decay).

**Parameters**

- `dt` *number* — Elapsed seconds (must be non-negative).

### `newModifier(mod_type, value, duration, source)`

Create a new modifier.

**Parameters**

- `mod_type` *string* — "multiply", "add", or "set" (defaults to "multiply" if invalid).
- `value` *number* — Modifier value.
- `duration` *number* — Duration in seconds (<= 0 = permanent).
- `source` *string* — Source tag for identifying the modifier origin.

**Returns**

- *Modifier*

### `getType()`

Return the modifier type ("multiply", "add", or "set").

**Returns**

- *string*

### `getValue()`

Return the modifier value.

**Returns**

- *number*

### `setValue(v)`

Set the modifier value.

**Parameters**

- `v` *number* — New value.

### `getDuration()`

Return the total duration (<= 0 = permanent).

**Returns**

- *number*

### `getRemaining()`

Return remaining time before expiry.

**Returns**

- *number*

### `getSource()`

Return the source tag.

**Returns**

- *string*

### `getTarget()`

Return the target identifier.

**Returns**

- *string*

### `setTarget(t)`

Set the target identifier.

**Parameters**

- `t` *string* — Target name.

### `isExpired()`

Return true if the modifier has expired.

**Returns**

- *boolean*

### `isPermanent()`

Return true if the modifier is permanent (duration <= 0).

**Returns**

- *boolean*

### `update(dt)`

Advance the expiry countdown.

**Parameters**

- `dt` *number* — Elapsed seconds.

### `newConversionRule(from, to, rate)`

Create a conversion rule.

**Parameters**

- `from` *string* — Source resource name (non-empty string).
- `to` *string* — Target resource name (non-empty string).
- `rate` *number* — Conversion rate (defaults to 1).

**Returns**

- *ConversionRule*

### `getFrom()`

Return the source resource name.

**Returns**

- *string*

### `getTo()`

Return the destination resource name.

**Returns**

- *string*

### `getRate()`

Return the base conversion rate.

**Returns**

- *number*

### `setRate(r)`

Set the base conversion rate.

**Parameters**

- `r` *number* — New rate.

### `getFee()`

Return the fee applied per conversion.

**Returns**

- *number*

### `setFee(f)`

Set the fee applied per conversion.

**Parameters**

- `f` *number* — Fee amount.

### `getCooldown()`

Return the cooldown duration in seconds.

**Returns**

- *number*

### `setCooldown(c)`

Set the cooldown duration in seconds.

**Parameters**

- `c` *number* — Cooldown seconds.

### `getMinAmount()`

Return the minimum allowed conversion amount.

**Returns**

- *number*

### `setMinAmount(m)`

Set the minimum allowed conversion amount.

**Parameters**

- `m` *number* — Minimum amount.

### `getMaxAmount()`

Return the maximum allowed conversion amount.

**Returns**

- *number*

### `setMaxAmount(m)`

Set the maximum allowed conversion amount.

**Parameters**

- `m` *number* — Maximum amount.

### `isOnCooldown()`

Return true if the rule is currently on cooldown.

**Returns**

- *boolean*

### `resetCooldown()`

Reset the cooldown timer to zero.

### `startCooldown()`

Trigger the cooldown period.

### `updateCooldown(dt)`

Advance the cooldown timer.

**Parameters**

- `dt` *number* — Elapsed seconds.

### `addModifier(m)`

Add a modifier to this rule.

**Parameters**

- `m` *Modifier* — Modifier to add.

### `removeModifier(index)`

Remove a modifier by 1-based index. Returns true if removed.

**Parameters**

- `index` *number* — 1-based index.

**Returns**

- *boolean*

### `getModifiers()`

Return the modifier array.

**Returns**

- *table*

### `clearModifiers()`

Clear all modifiers from this rule.

### `effectiveRate()`

Compute effective conversion rate after applying modifiers. Modifier application order: if any non-expired "set" modifier exists, the last one wins immediately (short-circuits add/multiply computation). Otherwise: additive modifiers sum onto the base rate, then multiplicative modifiers scale the result.

**Returns**

- *number* — Effective rate after modifiers.

### `newManager()`

Create a new resource manager.

**Returns**

- *ResourceManager*

### `getEventBus()`

Return (or lazily create) an optional `lurek.patterns` EventBus that callers can subscribe to for transaction-style notifications. Returns nil when the engine binding is unavailable. The library does not auto-emit events on this bus — callers may emit on it from their own wrappers without breaking pure-Lua tests.

**Returns**

- *table|nil* — EventBus instance, or nil when `lurek.patterns.newEventBus` is missing.

See: [`lurek.patterns.newEventBus`](../lua-api.md#lurekpatternsneweventbus)

### `newResource(name, capacity)`

Create (or return existing) resource.

**Parameters**

- `name` *string*
- `capacity` *number*

**Returns**

- *Resource*

### `getResource(name)`

**Parameters**

- `name` *string*

**Returns**

- *Resource|nil*

### `hasResource(name)`

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `getResourceNames()`

**Returns**

- *table* — Array of resource names.

### `removeResource(name)`

Remove a resource by name.

**Parameters**

- `name` *string*

### `tick(dt)`

Tick all enabled resources and advance conversion rule cooldowns / modifiers.

**Parameters**

- `dt` *number*

### `turn()`

Turn: equivalent to tick(1.0).

### `addConversionRule(rule)`

Add a conversion rule.

**Parameters**

- `rule` *ConversionRule*

### `getConversionRules()`

**Returns**

- *table* — Array of ConversionRule.

### `convert(from, to, amount)`

Convert resources using the first matching rule.

**Parameters**

- `from` *string*
- `to` *string*
- `amount` *number*

**Returns**

- *boolean*

### `exchange(other, give_name, give_amount, get_name, get_amount)`

Direct two-way exchange between two managers (atomic).

**Parameters**

- `other` *ResourceManager*
- `give_name` *string* — Resource to give.
- `give_amount` *number*
- `get_name` *string* — Resource to receive.
- `get_amount` *number*

**Returns**

- *boolean*

### `totalByGroup(group)`

Sum of values for all resources in a group.

**Parameters**

- `group` *string*

**Returns**

- *number*

### `getPercent(name)`

Percent full (0-100) for a resource, 0 if capacity <= 0.

**Parameters**

- `name` *string*

**Returns**

- *number*

### `isFull(name)`

Is the resource at capacity?

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `isEmpty(name)`

Is the resource at minimum?

**Parameters**

- `name` *string*

**Returns**

- *boolean*

### `canAffordAll(needs)`

Check if all resources in the table can be afforded.

**Parameters**

- `needs` *table* — {name = amount, ...}

**Returns**

- *boolean*

### `spendAll(needs)`

Atomically spend all resources in the table.

**Parameters**

- `needs` *table* — {name = amount, ...}

**Returns**

- *boolean*

### `reset()`

Clear all resources and conversion rules.

### `getValue(name)`

Return the current value of a named resource (0 if not found).

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*

### `setValue(name, v)`

Set the value of a named resource (clamped).

**Parameters**

- `name` *string* — Resource name.
- `v` *number* — New value.

### `getCapacity(name)`

Return the capacity of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*

### `setCapacity(name, c)`

Set the capacity of a named resource.

**Parameters**

- `name` *string* — Resource name.
- `c` *number* — New capacity.

### `getMinimum(name)`

Return the minimum value of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*

### `setMinimum(name, m)`

Set the minimum value of a named resource.

**Parameters**

- `name` *string* — Resource name.
- `m` *number* — New minimum.

### `getFlowRate(name)`

Return the flow rate of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*

### `setFlowRate(name, rate)`

Set the flow rate of a named resource.

**Parameters**

- `name` *string* — Resource name.
- `rate` *number* — Flow rate.

### `getDecayRate(name)`

Return the flat decay rate of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*

### `setDecayRate(name, rate)`

Set the flat decay rate of a named resource.

**Parameters**

- `name` *string* — Resource name.
- `rate` *number* — Decay rate.

### `getDecayPercent(name)`

Return the proportional decay rate of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*

### `setDecayPercent(name, pct)`

Set the proportional decay rate of a named resource.

**Parameters**

- `name` *string* — Resource name.
- `pct` *number* — Decay percent.

### `getInterestRate(name)`

Return the interest rate of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*

### `setInterestRate(name, rate)`

Set the interest rate of a named resource.

**Parameters**

- `name` *string* — Resource name.
- `rate` *number* — Interest rate.

### `getUpkeep(name)`

Return the upkeep cost of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*

### `setUpkeep(name, u)`

Set the upkeep cost of a named resource.

**Parameters**

- `name` *string* — Resource name.
- `u` *number* — Upkeep cost.

### `getNetRate(name)`

Return the net rate (flow - decay - upkeep + interest - decay%) of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*

### `getOverflow(name)`

Return the overflow policy of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *string*

### `setOverflow(name, policy)`

Set the overflow policy of a named resource.

**Parameters**

- `name` *string* — Resource name.
- `policy` *string* — One of "clamp", "lose", "wrap".

### `getGroup(name)`

Return the group tag of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *string*

### `setGroup(name, g)`

Set the group tag of a named resource.

**Parameters**

- `name` *string* — Resource name.
- `g` *string* — Group name.

### `isEnabled(name)`

Return whether tick processing is enabled for a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *boolean*

### `setEnabled(name, v)`

Enable or disable tick processing for a named resource.

**Parameters**

- `name` *string* — Resource name.
- `v` *boolean* — Enabled state.

### `isVisible(name)`

Return the UI visibility hint of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *boolean*

### `setVisible(name, v)`

Set the UI visibility hint of a named resource.

**Parameters**

- `name` *string* — Resource name.
- `v` *boolean* — Visibility.

### `isLocked(name)`

Return whether a named resource is locked against modifications.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *boolean*

### `setLocked(name, v)`

Lock or unlock add/spend for a named resource.

**Parameters**

- `name` *string* — Resource name.
- `v` *boolean* — Locked state.

### `add(name, amount)`

Add an amount to a named resource. Returns excess that did not fit.

**Parameters**

- `name` *string* — Resource name.
- `amount` *number* — Amount to add.

**Returns**

- *number* — excess

### `spend(name, amount)`

Spend an amount from a named resource. Returns true on success.

**Parameters**

- `name` *string* — Resource name.
- `amount` *number* — Amount to spend.

**Returns**

- *boolean*

### `canAfford(name, amount)`

Return true if the named resource has enough available funds.

**Parameters**

- `name` *string* — Resource name.
- `amount` *number* — Amount required.

**Returns**

- *boolean*

### `getAvailable(name)`

Return the available amount (value - reserved) of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*

### `reserveAmount(name, amount)`

Increase the reservation on a named resource.

**Parameters**

- `name` *string* — Resource name.
- `amount` *number* — Amount to reserve.

### `unreserveAmount(name, amount)`

Decrease the reservation on a named resource (floored at 0).

**Parameters**

- `name` *string* — Resource name.
- `amount` *number* — Amount to release.

### `getReserved(name)`

Return the reserved amount of a named resource.

**Parameters**

- `name` *string* — Resource name.

**Returns**

- *number*
