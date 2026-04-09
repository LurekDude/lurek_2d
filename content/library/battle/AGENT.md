# `battle` — Agent Reference (Lunasome)

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Lunasome (pure Lua, no Rust dependencies) |
| **Source** | `library/battle/init.lua` |
| **Lua Tests** | `tests/lua/library/test_library_battle.lua` |
| **Depends on** | `luna.*` public API only |

## Summary

Turn-based battle engine with combatants, initiative ordering, named combat
actions, status effects, and typed damage. `Combatant` stores HP, MP,
resistances, active status effects, and a list of `CombatAction` instances
with typed accessors for all stat fields. `CombatBattle` holds the combatant
list, tracks turn order, logs events to an append-only log, and exposes
resolution helpers such as `sortInitiative()` and `attack()`.

`CombatAction` owns one action blueprint: fire rate, accuracy, cooldown, HP
and MP costs, damage values, and an extensible tag+metadata table. Tag methods
(`addTag`, `removeTag`, `hasTag`, `getTags`) allow scripts to mark actions with
arbitrary flags such as `"projectile"` or `"aoe"`. `StatusEffect` tracks a
named effect with a turn-based duration, stack count, and its own metadata
table; the `getMetadata`/`setMetadata` alias aligns naming with the Rust module.
`M.DamageType` provides named constants (Physical, Fire, Ice, Lightning, Poison,
Arcane, Heal, True, Custom) for use with `Combatant:takeDamage()`.

The library carries no GPU, audio, or engine state; all types are plain Lua
tables usable in headless test VMs.

## Architecture

```
CombatBattle (round orchestration)
  │
  ├── combatants[]: Combatant  (sorted by speed for initiative)
  ├── turn_index: number
  └── log[]: string

Combatant
  │
  ├── stats: { name → value }      (getStat / setStat)
  ├── resistances: { dtype → factor }
  ├── status_effects[]: StatusEffect
  │     ├── name, duration, stacks
  │     └── metadata: { key → value }  (getMeta / getMetadata)
  └── actions[]: CombatAction
        ├── damage, accuracy, cooldown, cost_hp, cost_mp
        ├── tags: { tag → true }    (addTag / removeTag / hasTag)
        └── metadata: { key → value }  (getMeta / setMeta)

M.DamageType  ──  Physical | Fire | Ice | Lightning | Poison | Arcane | Heal | True | Custom
```

## Source Files

| File | Purpose |
|------|---------|
| `library/battle/init.lua` | Full implementation — Combatant, CombatBattle, CombatAction, StatusEffect, DamageType |

## Key Types

| Type | Constructor | Purpose |
|------|-------------|--------|
| `Combatant` | `M.newCombatant(name)` | Combatant with HP, MP, stats, status effects, and resistances |
| `CombatBattle` | `M.newBattle(name)` | Turn-order container; holds combatants and drives round execution |
| `CombatAction` | `M.newAction(name)` | Named action with damage, cooldown, accuracy, tags, and metadata |
| `StatusEffect` | `M.newStatusEffect(name, duration)` | Timed status modifier with stacks, duration, and metadata |
| `M.DamageType` | enum table | Named damage type constants used with `takeDamage()` |
