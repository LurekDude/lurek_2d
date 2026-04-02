# src/stats/

RPG character sheet: attributes, buffs, skills, perks, levels, action points.

## What This Module Contains

Sheet owns a map of named Attributes and provides derived-stat computation.
Attribute supports stacking Buffs with duration and StackMode (Add/Multiply/
Override/Max). Perk and TraitDef model character progression. LevelThresholds
defines XP tables.

## Files

| File | Purpose |
|------|---------|
| `attribute.rs` | Attribute, Buff, StackMode |
| `skill.rs` | Skill, Perk, TraitDef, ActionPoints, Morale, LevelThresholds |
| `sheet.rs` | Sheet, StatsRegistry |
| `mod.rs` | Facade — re-exports all sub-modules |

## Navigation

- **Owner agent**: `Developer`
- **Lua API bindings**: `src/lua_api/stats_api.rs` (if present)
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- No dependencies on other domain modules
- Must NOT import from other Tier 3 modules directly
