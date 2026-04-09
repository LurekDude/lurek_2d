# `combat` — Agent Reference (Lunasome)

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Lunasome (pure Lua, no Rust dependencies) |
| **Source** | `library/combat/init.lua` |
| **Lua Tests** | `tests/lua/library/test_library_combat.lua` |
| **Depends on** | `lurek.*` public API only |

## Summary

Action-combat engine modelling vehicles, chassis, turrets, weapons, and
projectiles. `Chassis` is the armoured body: it stores zone-based armour
values (Front, Rear, Side), a mount-slot list for turret attachment, and a
damage/heal accumulator. Each mount point carries a positional offset and an
optional field-of-fire arc so turret placement has spatial meaning.

`Turret` wraps aim state; it rotates toward a target angle and exposes a full
getter/setter API covering `getTurnSpeed`/`setTurnSpeed`, `getArcMin`/`setArcMin`,
`getArcMax`/`setArcMax`, `getTargetAngle`/`setTargetAngle`,
`getSizeClass`/`setSizeClass`, and `isDestroyed`/`setDestroyed`.

`Weapon` owns fire rate, ammo, burst, spread, range, and damage tracking.
Full getter/setter pairs cover every field: `getName`/`setName`,
`getFireRate`/`setFireRate`, `getAmmo`/`setAmmo`, `getMaxAmmo`/`setMaxAmmo`,
`getBurstSize`/`setBurstSize`, `getBurstDelay`/`setBurstDelay`,
`getSpread`/`setSpread`, `getDamageAmount`/`setDamageAmount`,
`getDamageType`/`setDamageType`, `getPenetration`/`setPenetration`,
`getRange`/`setRange`, `getProjectileSpeed`/`setProjectileSpeed`,
and `getProjectileType`/`setProjectileType`.

Firing generates a `Projectile` placed into a `ProjectilePool`; pools manage
spawn/release cycling with a fixed-capacity free list. `CombatWorld` is the
top-level container: it holds chassis, turrets, weapons, and projectile pools,
updating weapon cooldowns each frame. `CollisionGroupSet` maps human-readable
group names to power-of-2 category bits and tracks which groups collide.

## Architecture

```
CombatWorld (frame-ticked simulation)
  │
  ├── chassis_list[]: Chassis
  │     ├── armor: { front, rear, side } → value
  │     └── slots: { id, x, y, size_class, arc_min, arc_max }
  │
  ├── turrets[]: Turret
  │     ├── target_angle, turn_speed, arc_min, arc_max
  │     └── weapon (index managed externally)
  │
  ├── weapons[]: Weapon
  │     ├── fire_rate, ammo, burst_size, spread, range
  │     └── fire() → produces projectile spawn request
  │
  ├── pools[]: ProjectilePool
  │     ├── projectiles[]: Projectile { active, speed, lifetime, distance_traveled }
  │     └── spawn/release free-list cycling
  │
  └── collision_groups: CollisionGroupSet → bit-mask per group name
```

## Source Files

| File | Purpose |
|------|---------|
| `library/combat/init.lua` | Full implementation — Chassis, Turret, Weapon, Projectile, ProjectilePool, CombatWorld, CollisionGroupSet |

## Key Types

| Type | Constructor | Purpose |
|------|-------------|---------|
| `CollisionGroupSet` | `M.newCollisionGroupSet()` | Maps group names to power-of-2 category bits; tracks collision rules |
| `MountSlot` | `M.newMountSlot(id, x, y, size_class)` | Positional slot with arc limits for turret attachment |
| `Chassis` | `M.newChassis(body_id, max_hp)` | Armoured body with zone armor, mount slots, HP, and destroy state |
| `Turret` | `M.newTurret(body_id, joint_id)` | Rotating weapon platform with arc, aim, and full getter/setter API |
| `Weapon` | `M.newWeapon(name)` | Fire rate, ammo, burst, spread, and range with full getter/setter API |
| `Projectile` | (created internally by `ProjectilePool`) | Single in-flight projectile slot with lifetime and distance tracking |
| `ProjectilePool` | `M.newProjectilePool(pool_size, projectile_type)` | Fixed-capacity free-list pool for spawning/releasing projectiles |
| `CombatWorld` | `M.newCombatWorld()` | Top-level simulation container: chassis, turrets, weapons, pools |
