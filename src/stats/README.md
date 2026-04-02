# `src/stats/` — RPG Character Sheet & Stat System

## Purpose

Flexible attribute system with buffs, derived stats, traits, skills, perks,
XP/levelling, action points, morale, and resistances.

## Files

| File | Purpose |
|------|---------|
| `attribute.rs` | `Attribute`, `Buff`, `StackMode` — numeric stat with buff system |
| `skill.rs` | `Skill`, `Perk`, `TraitDef`, `ActionPoints`, `Morale`, `LevelThresholds` |
| `sheet.rs` | `Sheet`, `StatsRegistry` — character sheet holding all stat data |

## Tier

**Tier 3** (gameplay-specific). Must not be imported by Tier 1 or Tier 2 modules.
