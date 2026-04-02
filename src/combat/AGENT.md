# src/combat/

Vehicle, weapon, and projectile combat system.

## What This Module Contains

CombatWorld coordinates vehicle chassis, turrets/weapons, and projectile pools.
Collision groups manage rapier filtering. Damage uses typed DamageFalloff curves.

## Files

| File | Purpose |
|------|---------|
| `types.rs` | Damage primitives, armour zones, mount slots, projectile types |
| `chassis.rs` | Chassis struct with health and mount slot management |
| `weapon.rs` | Weapon and Turret firing components |
| `projectile.rs` | Projectile, pool, and collision group management |
| `world.rs` | CombatWorld top-level coordinator |

## Navigation

- **Owner agent**: `Developer`
- **Lua API bindings**: `src/lua_api/combat_api.rs` (if present)
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- Delegates to `physics`, `stats`, `event`, `math`, `entity`, `timer`, `inventory`
- Must NOT import from other Tier 3 modules directly (use Lua for integration)
