# `stats` — Agent Reference (Lunasome)

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Lunasome (pure Lua, no Rust dependencies) |
| **Source** | `library/stats/init.lua` |
| **Lua Tests** | `tests/lua/library/test_library_stats.lua` |
| **Test count** | 70 tests — all passing |
| **Depends on** | `lurek.*` public API only |

## Summary

Comprehensive character-stats engine covering attributes, buffs, traits, skills,
perks, action points, morale, damage, and XP progression. `Sheet` is the
central object: it stores a named attribute map, an active `Buff` list, trait
and perk sets, a skill registry, and optional XP/level configuration. Attribute
values are derived rather than stored directly — `getStat(name)` sums base
value, all additive buff contributions, and then applies multiplicative modifiers
in a deterministic order, so callers always see the final effective value.

The `Buff` type carries a numeric magnitude, an affected attribute name, a
source label, a turn/second duration, and an optional tag for categorical
removal. `applyDamage(amount, type)` reduces the sheet's HP stat, respecting
resistances and armour values defined in the attribute map. `update(dt)` ticks
all buff durations and removes expired entries.

Higher-level subsystems sit on top of `Sheet`: `ActionPoints` tracks current
and maximum AP with `spend()` and `recover()` operations; `Morale` adds a
bounded morale bar with threshold-based state labels (`broken`, `shaken`,
`steady`, `inspired`); `LevelThresholds` maps XP totals to level breakpoints
and fires a configurable callback on level-up. `RaceDef` and `ClassDef` supply
modifiers and trait lists that can be applied to a fresh `Sheet` in one call.

## Architecture

```
Sheet (character stat sheet)
  │
  ├── attributes: { name → base_value }
  ├── getStat(name) → base + sum(additive buffs) * product(mult buffs)
  │
  ├── buffs[]: Buff { attr, magnitude, source, duration, tag }
  │
  ├── traits: { name → TraitDef }
  ├── skills: { name → Skill { rank, xp } }
  ├── perks: { name → Perk { effects[] } }
  ├── flags: { name → bool }
  │
  ├── ActionPoints { current, max, recover_per_turn }
  ├── Morale { value, max, state: broken|shaken|steady|inspired }
  │
  └── XP / Level
        └── LevelThresholds → thresholds[], on_level_up callback

RaceDef  ──── attribute modifiers + default traits
ClassDef ──── attribute modifiers + starting skills + default perks
```

## Source Files

| File | Purpose |
|------|---------|
| `library/stats/init.lua` | Full implementation — Sheet, Buff, TraitDef, RaceDef, ClassDef, Skill, Perk, ActionPoints, Morale, LevelThresholds |

## Key Types

| Type | Constructor | Purpose |
|------|-------------|--------|
| `Sheet` | `M.newSheet()` | Central character stat sheet with derived attribute resolution |
| `Buff` | `M.newBuff(stat, add, mul, duration, source)` | Timed additive/multiplicative stat modifier |
| `TraitDef` | `M.newTraitDef(buffs)` | Named trait with passive buff list |
| `Skill` | `M.newSkill(opts)` | Named skill with rank and XP |
| `Perk` | `M.newPerk(opts)` | Named perk with effect list |
| `ActionPoints` | `M.newActionPoints(max_val)` | AP resource with spend/recover |
| `Morale` | `M.newMorale(max_val)` | Bounded morale value with state labels |
| `TableThresholds` | `M.newTableThresholds(values)` | XP-to-level mapping from explicit threshold array |
| `LinearThresholds` | `M.newLinearThresholds(base, increment)` | XP-to-level mapping from linear formula |
| `defineRace` | `M.defineRace(name, def)` | Register a race archetype (attribute modifiers + trait list) |
| `defineClass` | `M.defineClass(name, def)` | Register a class archetype (attribute modifiers + starting skills/perks) |
