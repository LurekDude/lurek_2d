# `src/resource/` — Resource Economy System

## Purpose

Named resources with capacity, flow rates, decay, interest, upkeep, overflow
policies, reservations, and conversion rules. Designed for RTS, management,
survival, and RPG economy patterns (gold, wood, mana, food, etc.).

## Files

| File | Purpose |
|------|---------|
| `resource.rs` | `Resource`, `OverflowPolicy` — single numeric resource with ticks |
| `modifier.rs` | `ModifierType`, `Modifier`, `ConversionRule` — rate modifiers |
| `manager.rs` | `ResourceManager` — multi-resource economy coordinator |

## Tier

**Tier 3** (gameplay-specific). Must not be imported by Tier 1 or Tier 2 modules.
