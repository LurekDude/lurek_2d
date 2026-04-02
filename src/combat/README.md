# `src/combat/` — Vehicle & Projectile Combat System

## Purpose

Modular vehicle, weapon, and projectile combat. Builds vehicles from chassis +
turrets + weapons; fires projectiles (ballistic, homing, ray, area, beam);
manages collision groups; coordinates damage resolution.

Delegates to existing modules: `physics` for bodies/raycasting,
`stats` for damage/buffs, `event` for broadcasting, `math` for geometry.

## Architecture

```
CombatWorld
  ├── Chassis (HP, mount slots, armour zones)
  │     └── Turret → Weapon → ProjectilePool
  └── CollisionGroupSet (mask management)
```

## Files

| File | Purpose |
|------|---------|
| `types.rs` | `Damage`, `DamageFalloff`, `ArmorZone`, `MountSlot`, `ProjectileType` |
| `chassis.rs` | `Chassis` — vehicle body with mount slots and health |
| `weapon.rs` | `Weapon`, `Turret` — firing components |
| `projectile.rs` | `Projectile`, `ProjectilePool`, `CollisionGroupSet` |
| `world.rs` | `CombatWorld` — top-level simulation coordinator |

## Tier

**Tier 3** (gameplay-specific). Must not be imported by Tier 1 or Tier 2 modules.
