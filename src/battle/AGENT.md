# `battle` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Gameplay Systems |
| **Lua API** | `luna.battle` |
| **Source** | `src/battle/` |
| **Tests** | `tests/battle_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_battle.lua` |

## Summary

The battle module implements turn-based combat as a self-contained Tier 3
gameplay system.  A `CombatBattle` holds a list of `Combatant` instances and
drives the full fight lifecycle: rolling initiative order at the start of a
round, resolving `CombatAction` declarations against the active target's
resistances and status conditions, applying HP/MP damage (or healing) and
recording each `CombatResult` in the battle log, then advancing to the next
combatant's turn.

`CombatAction` represents a single attack, skill, or ability: it carries a
`DamageType` for resistance matching, a base power value, an accuracy rating,
a cost (MP or other resource), and an optional cooldown.  `StatusEffect`
attaches temporary modifiers to a combatant — a `remaining_turns` counter
ticks down each round until the effect expires.  `DamageType` variants (Normal,
Fire, Ice, Lightning, Poison, Healing, True) map to per-combatant resistance
floats so that elemental strengths and weaknesses are a data decision, not code.

The module does not own rendering or audio — script callbacks on battle events
(`on_turn_start`, `on_action_resolved`, `on_combatant_defeated`) are where the
game adds visual and sound effects.  This keeps the Rust core pure logic that
is fully testable without a window or GPU.

## Architecture

```
CombatBattle (battle state machine)
  │
  ├── combatants: Vec<Combatant>
  │     ├── id, name, hp, max_hp, mp, max_mp
  │     ├── speed (for initiative order)
  │     ├── resistances: HashMap<DamageType, f32>
  │     └── statuses: Vec<StatusEffect>
  │
  ├── Turn ordering
  │     ├── Initiative roll → sorted by speed + RNG
  │     └── turn_index tracks current combatant
  │
  ├── Action resolution (resolve_action)
  │     ├── Accuracy check → miss or hit
  │     ├── Resistance lookup → damage multiplier
  │     ├── HP/MP delta applied to target
  │     └── CombatResult appended to log
  │
  ├── Status management
  │     ├── StatusEffect { name, remaining_turns, ... }
  │     └── tick_statuses() — decrements and removes expired effects
  │
  └── Log: Vec<CombatResult>
        ├── actor_id, target_id
        ├── action_name, damage_dealt
        └── miss flag, defeated flag
```

## Source Files

| File | Purpose |
|------|---------|
| `action.rs` | CombatAction: named attack or skill with cooldown, cost, and accuracy |
| `battle.rs` | CombatBattle: manages full turn-based battle lifecycle with turn ordering and... |
| `combatant.rs` | Combatant: a single participant in a turn-based battle with HP, MP, statuses,... |
| `types.rs` | Turn-based battle primitive types: damage kinds, status effects, and action... |

## Submodules

### `battle::action`

CombatAction: named attack or skill with cooldown, cost, and accuracy.

- **`CombatAction`** (struct): A turn-based combat action that a combatant can take.  Represents an attack, skill, or ability with damage type, base...

### `battle::battle`

CombatBattle: manages full turn-based battle lifecycle with turn ordering and action resolution.

- **`CombatBattle`** (struct): Manages a full turn-based battle with turn ordering and action resolution.  Holds the combatant list, tracks turn order...

### `battle::combatant`

Combatant: a single participant in a turn-based battle with HP, MP, statuses, and actions.

- **`Combatant`** (struct): A participant in turn-based battle. Consult the module-level documentation for the broader usage context and...

### `battle::types`

Turn-based battle primitive types: damage kinds, status effects, and action results.

- **`DamageType`** (enum): Kind of damage used for resistance lookups.  Matched against a combatant's `resistances` map during `take_damage`. The...
- **`StatusEffect`** (struct): An active status effect on a combatant. Consult the module-level documentation for the broader usage context and...
- **`CombatResult`** (struct): Result of a single turn-based combat action.  Returned by `CombatBattle::resolve_action` and appended to the battle...

## Key Types

### Structs

#### `battle::action::CombatAction`

A turn-based combat action that a combatant can take.  Represents an attack, skill, or ability with damage type, base...

#### `battle::battle::CombatBattle`

Manages a full turn-based battle with turn ordering and action resolution.  Holds the combatant list, tracks turn order...

#### `battle::types::CombatResult`

Result of a single turn-based combat action.  Returned by `CombatBattle::resolve_action` and appended to the battle...

#### `battle::combatant::Combatant`

A participant in turn-based battle. Consult the module-level documentation for the broader usage context and...

#### `battle::types::StatusEffect`

An active status effect on a combatant. Consult the module-level documentation for the broader usage context and...

### Enums

#### `battle::types::DamageType`

Kind of damage used for resistance lookups.  Matched against a combatant's `resistances` map during `take_damage`. The...

## Lua API

Exposed under `luna.battle.*` by `src/lua_api/battle_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 1 |
| `mod` | 4 |
| `struct` | 5 |
| **Total** | **10** |

