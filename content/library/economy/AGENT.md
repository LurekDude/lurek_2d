# `economy` — Agent Reference (Lunasome)

| Property              | Value                                                                                                                                                                                                                     |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tier**              | Tier 3 — Lunasome (pure Lua, no Rust dependencies)                                                                                                                                                                        |
| **Source**            | `library/economy/init.lua`                                                                                                                                                                                                |
| **Lua Tests**         | `tests/lua/library/test_library_economy.lua`                                                                                                                                                                              |
| **Depends on**        | `lurek.*` public API only                                                                                                                                                                                                 |
| **Status**            | full                                                                                                                                                                                                                      |
| **Optional bindings** | `lurek.math.clamp` (delegated by `Resource:_clamp` when available), `lurek.serial.toJson/fromJson` (recommended for save serialisation), `lurek.patterns.newEventBus` (transaction event bus from `manager:getEventBus()`) |

## Summary

Pure-Lua resource economy engine. `Resource` is the core unit: it tracks a
current balance subject to four optional simulated effects — linear flow
(income/expenditure per tick), flat decay, compound interest, and recurring
upkeep. A reserve floor prevents a balance from being spent below a held
amount. Overflow can be configured as `clamp` (default), `lose` (reject the
whole add on overflow), or `wrap` (modulo wrap).

`Modifier` objects encapsulate an additive, multiplicative, or override delta
on a conversion rate, enabling buff and penalty stacking with optional
duration-based expiry.

`ConversionRule` defines an exchange between two named resources: source,
destination, base rate, fee, min/max amount guards, cooldown timer, and an
attached `Modifier` list. `ResourceManager` owns all resources and conversion
rules and provides bulk tick, convert, exchange, and aggregation operations.

## Architecture

```
ResourceManager (tick, convert, exchange)
  │
  ├── resources: { name → Resource }
  │     ├── value, capacity, minimum
  │     ├── flow_rate, decay_rate, decay_percent, interest_rate, upkeep
  │     ├── overflow: "clamp" | "lose" | "wrap"
  │     ├── group, enabled, visible, locked
  │     └── reserved (prevents spending below held amount)
  │
  └── conversion_rules: ConversionRule[]
        ├── from, to, rate, fee
        ├── min_amount, max_amount
        ├── cooldown, cooldown_remaining
        └── modifiers: Modifier[]
              ├── mod_type: "multiply" | "add" | "set"
              ├── value, duration, remaining
              └── source, target

M.OverflowPolicy   ──  CLAMP | LOSE | WRAP
M.ModifierType     ──  MULTIPLY | ADD | SET
```

## Source Files

| File                       | Purpose                                                                                |
| -------------------------- | -------------------------------------------------------------------------------------- |
| `library/economy/init.lua` | Full implementation — Resource, Modifier, ConversionRule, ResourceManager, enum tables |

## Key Types

| Type               | Constructor                                        | Purpose                                                                      |
| ------------------ | -------------------------------------------------- | ---------------------------------------------------------------------------- |
| `Resource`         | `M.newResource(name, capacity)`                    | Named balance with flow, decay, interest, upkeep, overflow, and reservation  |
| `Modifier`         | `M.newModifier(mod_type, value, duration, source)` | Timed or permanent rate modifier ("multiply", "add", "set")                  |
| `ConversionRule`   | `M.newConversionRule(from, to, rate)`              | Exchange rule between two resources with fee, cooldown, and modifier stack   |
| `ResourceManager`  | `M.newManager()`                                   | Multi-resource container with tick, convert, exchange, and group aggregation |
| `M.OverflowPolicy` | enum table                                         | `CLAMP`, `LOSE`, `WRAP`                                                      |
| `M.ModifierType`   | enum table                                         | `MULTIPLY`, `ADD`, `SET`                                                     |

## API at a Glance

### Resource methods
`getName` · `getValue` · `setValue` · `getCapacity` · `setCapacity`
`getMinimum` · `setMinimum` · `getOverflow` · `setOverflow`
`getFlowRate` · `setFlowRate` · `getDecayRate` · `setDecayRate`
`getDecayPercent` · `setDecayPercent` · `getInterestRate` · `setInterestRate`
`getUpkeep` · `setUpkeep` · `getGroup` · `setGroup`
`isEnabled` · `setEnabled` · `isVisible` · `setVisible` · `isLocked` · `setLocked`
`getReserved` · `getAvailable` · `getNetRate`
`add` · `spend` · `canAfford` · `reserve` · `unreserve` · `tick`

### Modifier methods
`getType` · `getValue` · `setValue` · `getDuration` · `getRemaining`
`getSource` · `getTarget` · `setTarget`
`isExpired` · `isPermanent` · `update`

### ConversionRule methods
`getFrom` · `getTo` · `getRate` · `setRate` · `getFee` · `setFee`
`getCooldown` · `setCooldown` · `getMinAmount` · `setMinAmount`
`getMaxAmount` · `setMaxAmount` · `isOnCooldown` · `resetCooldown`
`startCooldown` · `updateCooldown` · `addModifier` · `removeModifier`
`getModifiers` · `clearModifiers` · `effectiveRate`

### ResourceManager methods
`newResource` · `getResource` · `hasResource` · `getResourceNames` · `removeResource`
`tick` · `turn` · `addConversionRule` · `getConversionRules`
`convert` · `exchange` · `totalByGroup`
`getValue` · `setValue` · `getCapacity` · `setCapacity` · `getMinimum` · `setMinimum`
`getFlowRate` · `setFlowRate` · `getDecayRate` · `setDecayRate`
`getDecayPercent` · `setDecayPercent` · `getInterestRate` · `setInterestRate`
`getUpkeep` · `setUpkeep` · `getNetRate` · `getOverflow` · `setOverflow`
`getGroup` · `setGroup` · `isEnabled` · `setEnabled` · `isVisible` · `setVisible`
`isLocked` · `setLocked` · `add` · `spend` · `canAfford` · `getAvailable`
`reserveAmount` · `unreserveAmount` · `getReserved`
`getPercent` · `isFull` · `isEmpty` · `canAffordAll` · `spendAll` · `reset`

## Port Status

Full parity with `src/economy/` (`resource.rs`, `modifier.rs`, `manager.rs`).
All public Rust types, methods, and enums are available in Lua.
