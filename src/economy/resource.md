# resource — Resource Management & Economy Module

> **Lua namespace:** `luna.resource`
> **C++ module:** `src/modules/resource/`
> **Purpose:** Provides a full economy/resource management system with named resources that have capacity, flow rates, decay, interest, upkeep, overflow policies, reservations, and lock states. Resources are grouped into ResourceManagers that support bulk operations, resource-to-resource conversion via rules with fees/cooldowns/modifiers, and cross-manager exchange trading.

## Reimplementation Notes

- Resource values are clamped to `[minimum, capacity]` on every mutation; capacity of -1 means unlimited
- The `tick(dt)` method applies four rate components per second: `flowRate` (income), `decayRate` (flat loss), `decayPercent` (proportional loss), `interestRate` (proportional gain), and `upkeep` (flat cost)
- Net rate formula: `flowRate - decayRate - upkeep + (value * interestRate) - (value * decayPercent)`
- OverflowPolicy controls what happens when `add()` exceeds capacity: `"clamp"` (default, excess lost), `"lose"` (entire add rejected), `"wrap"` (wraps around from minimum)
- `reserve(amount)` earmarks value that `spend()` and `canAfford()` will not touch — `getAvailable()` = `value - reserved`
- `isLocked()` blocks `add()` and `spend()` — useful for temporarily freezing a resource
- `isEnabled()` controls whether `tick()` processes this resource — disabled resources are frozen in time
- `isVisible()` is a pure UI hint flag with no engine behavior
- Modifiers attach to ConversionRules and scale the effective rate — they can be timed (expire after duration)
- ConversionRules have cooldowns, fees, min/max amount constraints, and attached Modifiers
- ResourceManager `exchange()` is atomic — both sides must afford their amounts or nothing happens
- ResourceManager `turn()` is a convenience for `tick(1.0)` — designed for turn-based games

## Dependencies

- None (standalone module)

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newResourceManager` | — | `ResourceManager` | Create an empty resource container |
| `newModifier` | `type: string, value: number, duration?: number, source?: string` | `Modifier` | Create a rate modifier. Type: `"multiply"`, `"add"`, or `"set"`. Duration ≤ 0 = permanent |
| `newConversionRule` | `from: string, to: string, rate?: number` | `ConversionRule` | Create a conversion rule. Default rate 1.0 |

---

## Type: Resource

A single named numeric resource with rates, capacity, overflow policy, and reservation system.

**Created by:** `ResourceManager:newResource(name, capacity?)`

### Identity & Value

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName` | — | `string` | Resource name as registered with the manager |
| `getValue` | — | `number` | Current stored value |
| `setValue` | `value: number` | — | Set value directly, clamped to [minimum, capacity] |
| `getCapacity` | — | `number` | Value ceiling (-1 = unlimited) |
| `setCapacity` | `capacity: number` | — | Set ceiling. Pass -1 for unlimited |
| `getMinimum` | — | `number` | Value floor (default 0) |
| `setMinimum` | `minimum: number` | — | Set value floor |

### Overflow Policy

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getOverflow` | — | `string` | Current policy: `"clamp"`, `"lose"`, or `"wrap"` |
| `setOverflow` | `policy: string` | — | Set overflow policy |

### Rates

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getFlowRate` | — | `number` | Flat per-second income |
| `setFlowRate` | `rate: number` | — | Set flat income rate |
| `getDecayRate` | — | `number` | Flat per-second loss |
| `setDecayRate` | `rate: number` | — | Set flat loss rate |
| `getDecayPercent` | — | `number` | Proportional per-second loss (0.1 = 10%/s) |
| `setDecayPercent` | `percent: number` | — | Set proportional decay |
| `getInterestRate` | — | `number` | Proportional per-second gain (0.05 = 5%/s) |
| `setInterestRate` | `rate: number` | — | Set proportional interest |
| `getUpkeep` | — | `number` | Flat per-second maintenance cost |
| `setUpkeep` | `upkeep: number` | — | Set maintenance cost |
| `getNetRate` | — | `number` | Computed: flowRate - decayRate - upkeep + (value × interest) - (value × decay%) |

### Grouping

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getGroup` | — | `string` | Group tag for aggregate queries |
| `setGroup` | `group: string` | — | Set group tag |

### State Flags

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `isEnabled` | — | `boolean` | True if tick processing is active |
| `setEnabled` | `enabled: boolean` | — | Enable/disable tick processing |
| `isVisible` | — | `boolean` | UI visibility hint (no engine behavior) |
| `setVisible` | `visible: boolean` | — | Set visibility hint |
| `isLocked` | — | `boolean` | True if add/spend are blocked |
| `setLocked` | `locked: boolean` | — | Lock/unlock modifications |

### Operations

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getReserved` | — | `number` | Total amount held in reserve |
| `getAvailable` | — | `number` | Value minus reserved — safe amount to spend |
| `add` | `amount: number` | `number` | Add to value. Returns excess per overflow policy. Returns full amount if locked |
| `spend` | `amount: number` | `boolean` | Deduct if available ≥ amount. Returns false if locked/insufficient |
| `canAfford` | `amount: number` | `boolean` | True if available ≥ amount |
| `reserve` | `amount: number` | — | Increase reserved budget |
| `unreserve` | `amount: number` | — | Decrease reserved budget (floored at 0) |
| `tick` | `dt: number` | — | Apply all rates for dt seconds. No-op when disabled |

---

## Type: Modifier

A rate modifier that can be attached to ConversionRules. Can be permanent or time-limited.

**Created by:** `luna.resource.newModifier(type, value, duration?, source?)`

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getType` | — | `string` | `"multiply"`, `"add"`, or `"set"` |
| `getValue` | — | `number` | Modifier magnitude |
| `setValue` | `value: number` | — | Update magnitude in place |
| `getDuration` | — | `number` | Total lifetime in seconds (≤ 0 = permanent) |
| `getRemaining` | — | `number` | Seconds until expiry |
| `getSource` | — | `string` | Informational creator tag |
| `getTarget` | — | `string` | Optional target identifier |
| `setTarget` | `target: string` | — | Set target identifier |
| `isExpired` | — | `boolean` | True if countdown reached zero |
| `isPermanent` | — | `boolean` | True if duration ≤ 0 |
| `update` | `dt: number` | — | Advance expiry countdown |

---

## Type: ConversionRule

A rule for converting one resource type to another with rate, fees, cooldowns, and modifier support.

**Created by:** `luna.resource.newConversionRule(from, to, rate?)`

### Core Properties

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getFrom` | — | `string` | Source resource name |
| `getTo` | — | `string` | Destination resource name |
| `getRate` | — | `number` | Base output-per-input rate |
| `setRate` | `rate: number` | — | Set base conversion rate |
| `getFee` | — | `number` | Flat fee deducted from source per conversion |
| `setFee` | `fee: number` | — | Set flat fee |

### Constraints

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getMinAmount` | — | `number` | Minimum per-conversion amount (0 = no min) |
| `setMinAmount` | `min: number` | — | Set minimum amount |
| `getMaxAmount` | — | `number` | Maximum per-conversion amount (≤ 0 = unlimited) |
| `setMaxAmount` | `max: number` | — | Set maximum amount |
| `getCooldown` | — | `number` | Cooldown duration in seconds |
| `setCooldown` | `seconds: number` | — | Set cooldown |
| `getCooldownRemaining` | — | `number` | Seconds until ready again |
| `resetCooldown` | — | — | Reset cooldown to full duration |

### State & Query

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `isEnabled` | — | `boolean` | False if rule is suspended |
| `setEnabled` | `enabled: boolean` | — | Enable/disable rule |
| `canConvert` | `amount: number` | `boolean` | True if enabled, not on cooldown, and within amount bounds |
| `getEffectiveRate` | — | `number` | Base rate after applying all attached Modifiers |

### Modifiers

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addModifier` | `modifier: Modifier` | — | Attach a modifier that scales the effective rate |
| `removeModifier` | `modifier: Modifier` | — | Detach a modifier |
| `tick` | `dt: number` | — | Advance cooldown timer and prune expired modifiers |

---

## Type: ResourceManager

A container for named resources with bulk operations, conversion, and cross-manager trading.

**Created by:** `luna.resource.newResourceManager()`

### Resource Lifecycle

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `newResource` | `name: string, capacity?: number` | `Resource` | Create and register a resource. Capacity -1 = unlimited |
| `getResource` | `name: string` | `Resource \| nil` | Get a resource by name |
| `hasResource` | `name: string` | `boolean` | Check if a resource is registered |
| `getResources` | — | `table<Resource>` | Array of all registered resources |
| `getResourcesByGroup` | `group: string` | `table<Resource>` | Resources sharing a group tag |

### Direct Operations

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `add` | `name: string, amount: number` | `number` | Add to named resource. Returns overflow |
| `spend` | `name: string, amount: number` | `boolean` | Deduct from named resource |
| `canAfford` | `name: string, amount: number` | `boolean` | Check if named resource can afford amount |
| `reserve` | `name: string, amount: number` | — | Reserve budget on named resource |
| `unreserve` | `name: string, amount: number` | — | Unreserve on named resource |
| `getAvailable` | `name: string` | `number` | Get available (value - reserved) for named resource |
| `getNetRate` | `name: string` | `number` | Get computed net rate for named resource |
| `getTotalByGroup` | `group: string` | `number` | Sum of all values in a group |

### Conversion & Trade

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `convert` | `from: string, to: string, amount: number` | `boolean` | Convert via a registered ConversionRule |
| `exchange` | `other: ResourceManager, giveName: string, giveAmt: number, recvName: string, recvAmt: number` | `boolean` | Atomic trade between two managers |
| `addConversionRule` | `rule: ConversionRule` | — | Register a conversion rule |
| `getConversionRule` | `from: string, to: string` | `ConversionRule \| nil` | Look up a conversion rule |

### Time Progression

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `tick` | `dt: number` | — | Call tick(dt) on all enabled resources |
| `turn` | — | — | Convenience for tick(1.0) — turn-based games |

---

## Enums

### ModifierType

| Value | String | Description |
|---|---|---|
| 0 | `"multiply"` | Multiply the base rate by the modifier value |
| 1 | `"add"` | Add the modifier value to the base rate |
| 2 | `"set"` | Override the base rate with the modifier value |

### OverflowPolicy

| Value | String | Description |
|---|---|---|
| 0 | `"clamp"` | Excess is silently lost, value set to capacity |
| 1 | `"lose"` | Entire add is rejected if it would overflow |
| 2 | `"wrap"` | Value wraps around from minimum |

---

## Usage Example

```lua
local mgr = luna.resource.newResourceManager()

-- Create resources
local gold = mgr:newResource("gold", 10000)   -- max 10,000
local wood = mgr:newResource("wood", -1)       -- unlimited
gold:setFlowRate(5)   -- +5 gold/second income
wood:setDecayRate(1)  -- -1 wood/second rot

-- Group resources
gold:setGroup("currency")
wood:setGroup("material")

-- Add and spend
mgr:add("gold", 500)
mgr:spend("gold", 100)  -- true
mgr:canAfford("gold", 9999)  -- false

-- Conversion: 10 wood → 1 gold
local rule = luna.resource.newConversionRule("wood", "gold", 0.1)
rule:setCooldown(5)  -- 5 second cooldown between conversions
mgr:addConversionRule(rule)
mgr:convert("wood", "gold", 100)  -- converts 100 wood into 10 gold

-- Trade between managers
local npc = luna.resource.newResourceManager()
npc:newResource("gold", -1)
npc:add("gold", 1000)
mgr:exchange(npc, "wood", 50, "gold", 100)  -- give 50 wood, receive 100 gold

-- Tick in game loop
function luna.update(dt)
    mgr:tick(dt)
end
```
