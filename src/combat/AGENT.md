# `combat` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Gameplay Systems |
| **Lua API** | `luna.combat` |
| **Source** | `src/combat/` |
| **Tests** | `tests/combat_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_combat.lua` |

## Summary

Vehicle-oriented combat primitives for chassis, turrets, weapons,
projectiles, projectile pools, and collision groups. The module stays
intentionally lightweight: it stores combat state and numeric IDs while the
Lua layer drives actual game rules and coordinates with `luna.physics` for
simulation. `Chassis` represents a vehicle body with a configurable set of
named `MountSlot` positions where `Turret` or `Weapon` objects attach, plus
`ArmorZone` multipliers that give different damage weights to hits on
different body regions. `Weapon` models a cooldown-based fire-rate system
paired with damage and range parameters; `Turret` wraps a Weapon with a
rotation angle and fire-arc constraint. `Projectile` and `ProjectilePool`
maintain a fixed-size slab of in-flight projectiles with alive/dead/collided
states, avoiding per-frame heap allocation. `CollisionGroupSet` maps named
groups to 16-bit rapier2d category bitmasks so scripts configure which
physics bodies interact with which projectiles using readable string names
instead of raw bitmask arithmetic.

## Architecture

```
CombatWorld
  ├── Chassis (HP, mount slots, armour zones)
  ├── Turret → Weapon
  ├── ProjectilePool
  └── CollisionGroupSet
```

## Source Files

| File | Purpose |
|------|---------|
| `chassis.rs` | Vehicle chassis with mount slots and armor zones |
| `collision_groups.rs` | Named collision group manager over physics category bits |
| `projectile.rs` | Projectile and ProjectilePool for efficient projectile management |
| `weapon.rs` | Turret and Weapon types for fire-rate-based combat |
| `world.rs` | CombatWorld: top-level coordinator for the vehicle/weapon/projectile combat... |

## Submodules

### `combat::chassis`

Vehicle chassis with mount slots and armor zones.

- **`MountSlot`** (struct): A slot on the chassis where turrets or weapons attach.
- **`ArmorZone`** (enum): Armor zone damage multiplier. Consult the module-level documentation for the broader usage context and preconditions.
- **`Chassis`** (struct): A vehicle chassis with health, armor, and mount slots.

### `combat::collision_groups`

Named collision group manager over physics category bits.

- **`CollisionGroupSet`** (struct): Maps named collision groups to 16-bit category bitmasks.

### `combat::projectile`

Projectile and ProjectilePool for efficient projectile management.

- **`MAX_POOL_SIZE`** (const): Maximum number of projectiles in a single pool.
- **`Projectile`** (struct): A single in-flight projectile. Consult the module-level documentation for the broader usage context and preconditions.
- **`ProjectilePool`** (struct): Pre-allocated pool of projectiles for efficient spawn/release cycling.

### `combat::weapon`

Turret and Weapon types for fire-rate-based combat.

- **`ProjectileType`** (enum): The type of projectile a weapon fires. Consult the module-level documentation for the broader usage context and...
- **`Turret`** (struct): A rotatable weapon mount attached to a chassis slot.
- **`Weapon`** (struct): A weapon that handles fire rate, ammo, burst, and damage.

### `combat::world`

CombatWorld: top-level coordinator for the vehicle/weapon/projectile combat system.

- **`CombatWorld`** (struct): Manages all combat entities: chassis, turrets, weapons, and projectile pools.

## Key Types

### Structs

#### `combat::chassis::Chassis`

A vehicle chassis with health, armor, and mount slots.

#### `combat::collision_groups::CollisionGroupSet`

Maps named collision groups to 16-bit category bitmasks.

#### `combat::world::CombatWorld`

Manages all combat entities: chassis, turrets, weapons, and projectile pools.

#### `combat::chassis::MountSlot`

A slot on the chassis where turrets or weapons attach.

#### `combat::projectile::Projectile`

A single in-flight projectile. Consult the module-level documentation for the broader usage context and preconditions.

#### `combat::projectile::ProjectilePool`

Pre-allocated pool of projectiles for efficient spawn/release cycling.

#### `combat::weapon::Turret`

A rotatable weapon mount attached to a chassis slot.

#### `combat::weapon::Weapon`

A weapon that handles fire rate, ammo, burst, and damage.

### Enums

#### `combat::chassis::ArmorZone`

Armor zone damage multiplier. Consult the module-level documentation for the broader usage context and preconditions.

#### `combat::weapon::ProjectileType`

The type of projectile a weapon fires. Consult the module-level documentation for the broader usage context and...

## Constants

- **`MAX_POOL_SIZE`** — Maximum number of projectiles in a single pool.

## Lua API

Exposed under `luna.combat.*` by `src/lua_api/combat_api/`.

### From `combat_system`

| Function | Returns | Description |
|---|---|---|
| `newCollisionGroupSet()` | `CollisionGroupSet` | Named collision-group masks and rules |
| `newChassis(bodyId, maxHp)` | `Chassis` | Vehicle body state with slots, armor, and HP |
| `newTurret(bodyId, jointId)` | `Turret` | Rotatable mount with arc limits and turn speed |
| `newWeapon(name)` | `Weapon` | Fire-rate weapon with ammo, spread, and projectile config |
| `newProjectilePool(size, projectileType?)` | `ProjectilePool` | Fixed-size projectile pool |
| `newCombatWorld()` | `CombatWorld` | Container for chassis, turrets, weapons, and pools |

## combat — Vehicle Combat Minigame

> **Lua namespace:** `luna.combat`
> **Rust module:** `src/combat/`

This module exposes the currently implemented vehicle-combat surface: chassis,
turrets, weapons, projectile pools, collision groups, and a lightweight
`CombatWorld` coordinator.

It is intentionally narrower than a full combat framework. The Rust side stores
combat state and physics identifiers. Lua scripts coordinate with `luna.physics`
and other modules when they need world creation, movement, or effects.

## Implemented Constructors

| Function | Returns | Description |
|---|---|---|
| `newCollisionGroupSet()` | `CollisionGroupSet` | Named collision-group masks and rules |
| `newChassis(bodyId, maxHp)` | `Chassis` | Vehicle body state with slots, armor, and HP |
| `newTurret(bodyId, jointId)` | `Turret` | Rotatable mount with arc limits and turn speed |
| `newWeapon(name)` | `Weapon` | Fire-rate weapon with ammo, spread, and projectile config |
| `newProjectilePool(size, projectileType?)` | `ProjectilePool` | Fixed-size projectile pool |
| `newCombatWorld()` | `CombatWorld` | Container for chassis, turrets, weapons, and pools |

## Implemented Objects

- `CollisionGroupSet`: define groups, enable or disable collisions, compute masks
- `Chassis`: health, armor, slots, user data, destroyed state
- `Turret`: turn speed, arc limits, aim target, size class, destroyed state
- `Weapon`: fire rate, ammo, burst behavior, projectile config, cooldowns
- `ProjectilePool`: spawn, release, reset, active/free counts
- `CombatWorld`: add/get entities, active counts, update cooldowns, cleanup, reset

## Notes

- The Rust module does not directly import other Tier 3 gameplay modules.
- `ProjectileType` supports `ballistic`, `homing`, `ray`, `area`, and `beam` as configuration tags.
- `MAX_POOL_SIZE` is `1024` per projectile pool.
- Turn-based battles now live in `src/battle/` and Lua exposes them under `luna.battle.*`.

---

## Type: Chassis

A vehicle body with mount slots for turrets and fixed weapons.

**Created by:** `luna.combat.newChassis()`

### Movement

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getBody` | — | `Body` | Get the underlying physics body |
| `getPosition` | — | `number, number` | Get chassis world position (x, y) |
| `getAngle` | — | `number` | Get chassis rotation in radians |
| `setLinearVelocity` | `vx: number, vy: number` | — | Set velocity (delegates to physics body) |
| `setAngularVelocity` | `omega: number` | — | Set angular velocity |
| `applyForce` | `fx: number, fy: number` | — | Apply force at center of mass |
| `applyTorque` | `torque: number` | — | Apply rotational torque |

### Mount Slots

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getSlots` | — | `table` | List all mount slots: `{id, x, y, sizeClass, arcMin, arcMax, occupied}` |
| `getSlot` | `slotId: string` | `table \| nil` | Get a specific slot definition |
| `attachTurret` | `slotId: string, turret: Turret` | — | Attach a turret to a mount slot. Creates a revolute joint |
| `detachTurret` | `slotId: string` | `Turret \| nil` | Remove and return the turret from a slot |
| `attachWeapon` | `slotId: string, weapon: Weapon` | — | Attach a fixed weapon directly (no turret rotation) |
| `getTurret` | `slotId: string` | `Turret \| nil` | Get the turret in a slot |
| `getWeapon` | `slotId: string` | `Weapon \| nil` | Get the fixed weapon in a slot |

### Armor & Health

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getHealth` | — | `number` | Current health |
| `getMaxHealth` | — | `number` | Maximum health |
| `setHealth` | `hp: number` | — | Set current health (clamped to 0..max) |
| `getArmor` | `zone?: string` | `number` | Get armor value. Zone: `"front"`, `"rear"`, `"side"`, `"top"` (default: average) |
| `setArmor` | `zone: string, value: number` | — | Set armor for a zone |
| `isDead` | — | `boolean` | True if health ≤ 0 |
| `onDamage` | `callback: function` | — | Register damage callback: `fn(chassis, damage, source)` |
| `onDeath` | `callback: function` | — | Register death callback: `fn(chassis, lastDamage)` |

### State

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getTeam` | — | `string` | Get collision team/faction |
| `setTeam` | `team: string` | — | Set collision team (used for group filtering) |
| `getUserData` | — | `any` | Get user-attached data |
| `setUserData` | `data: any` | — | Attach arbitrary data |
| `destroy` | — | — | Remove chassis and all attached turrets/weapons from the world |
| `isDestroyed` | — | `boolean` | True if chassis has been destroyed |

### Chassis Definition Table

```lua
{
    x = 100, y = 200,               -- number: spawn position
    shape = "rectangle",             -- string: "rectangle", "circle", "polygon"
    width = 60, height = 30,         -- number: for rectangle shape
    radius = 20,                     -- number: for circle shape
    vertices = {...},                -- table: for polygon shape (array of x,y pairs)
    mass = 500,                      -- number: body mass in kg
    maxHealth = 1000,                -- number: starting/max health
    armor = {                        -- table: per-zone armor values
        front = 50, rear = 20, side = 30, top = 10
    },
    team = "player",                 -- string: collision team/faction
    slots = {                        -- table: mount slot definitions
        { id = "turret_main", x = 0, y = -5, sizeClass = "large", arcMin = -180, arcMax = 180 },
        { id = "turret_rear", x = -20, y = 0, sizeClass = "small", arcMin = 90, arcMax = 270 },
        { id = "fixed_mg", x = 15, y = 0, sizeClass = "small", arcMin = -10, arcMax = 10 },
    },
    linearDamping = 0.5,             -- number: physics damping
    angularDamping = 0.8,            -- number: rotational damping
}
```

---

## Type: Turret

A rotatable weapon mount that attaches to a chassis slot via a revolute joint.

**Created by:** `luna.combat.newTurret()`

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getBody` | — | `Body` | Get the turret's physics body |
| `getAngle` | — | `number` | Get turret rotation relative to chassis (radians) |
| `getWorldAngle` | — | `number` | Get turret absolute world rotation |
| `aimAt` | `x: number, y: number` | — | Rotate turret toward a world position (uses motor drive, respects turn speed and arc limits) |
| `setAngle` | `angle: number` | — | Set turret angle directly (clamped to arc limits) |
| `isAimed` | `tolerance?: number` | `boolean` | True if turret is within tolerance of aim target (default 0.05 rad) |
| `getTurnSpeed` | — | `number` | Rotation speed in radians/second |
| `setTurnSpeed` | `speed: number` | — | Set rotation speed |
| `attachWeapon` | `weapon: Weapon` | — | Mount a weapon on this turret |
| `getWeapon` | — | `Weapon \| nil` | Get the mounted weapon |
| `detachWeapon` | — | `Weapon \| nil` | Remove and return the weapon |
| `getChassis` | — | `Chassis \| nil` | Get the parent chassis |
| `destroy` | — | — | Destroy turret body and joint |

### Turret Definition Table

```lua
{
    shape = "rectangle",             -- string: turret body shape
    width = 15, height = 10,         -- number: turret dimensions
    mass = 50,                       -- number: turret mass
    turnSpeed = 1.5,                 -- number: radians/second rotation speed
    sizeClass = "large",             -- string: must match slot sizeClass to attach
}
```

---

## Type: Weapon

Handles fire rate, ammunition, burst patterns, and projectile spawning.

**Created by:** `luna.combat.newWeapon()`

### Firing

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `fire` | `targetX?: number, targetY?: number` | `boolean` | Attempt to fire. Returns false if on cooldown or out of ammo. For homing projectiles, target position is the initial track point |
| `canFire` | — | `boolean` | True if not on cooldown and has ammo |
| `startFiring` | `targetX?: number, targetY?: number` | — | Begin continuous fire (for automatic weapons) |
| `stopFiring` | — | — | Stop continuous fire |
| `isFiring` | — | `boolean` | True if weapon is in continuous fire mode |

### Ammunition

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getAmmo` | — | `number` | Current ammo count (-1 = infinite) |
| `setAmmo` | `count: number` | — | Set ammo count |
| `getMaxAmmo` | — | `number` | Maximum ammo capacity |
| `reload` | `amount?: number` | — | Add ammo (default: refill to max) |
| `isOutOfAmmo` | — | `boolean` | True if ammo = 0 |

### Configuration

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getFireRate` | — | `number` | Rounds per second |
| `setFireRate` | `rate: number` | — | Set fire rate |
| `getCooldown` | — | `number` | Remaining cooldown in seconds |
| `getBurstSize` | — | `number` | Rounds per burst (1 = semi-auto) |
| `setBurstSize` | `count: number` | — | Set burst size |
| `getBurstDelay` | — | `number` | Delay between rounds in a burst |
| `getSpread` | — | `number` | Angular spread in radians (0 = perfectly accurate) |
| `setSpread` | `radians: number` | — | Set angular spread |
| `getDamage` | — | `table` | Damage table: `{amount, type, penetration}` |
| `setDamage` | `damage: table` | — | Set damage table |
| `getRange` | — | `number` | Maximum projectile range/lifetime distance |
| `setRange` | `range: number` | — | Set range |
| `getProjectilePool` | — | `ProjectilePool` | Get the pool used for spawning projectiles |
| `setTrailEmitter` | `emitter: ParticleEmitter?` | — | Set particle emitter for projectile trails |
| `setImpactEmitter` | `emitter: ParticleEmitter?` | — | Set particle emitter for impact effects |
| `setMuzzleEmitter` | `emitter: ParticleEmitter?` | — | Set particle emitter for muzzle flash |
| `onHit` | `callback: function` | — | Register hit callback: `fn(weapon, target, point, normal, damage)` |

### Weapon Definition Table

```lua
{
    name = "Plasma Cannon",          -- string: display name
    projectileType = "ballistic",    -- string: "ballistic", "homing", "ray", "area", "beam"
    fireRate = 2.0,                  -- number: rounds per second
    damage = { amount = 50, type = "plasma", penetration = 10 },
    ammo = 100,                      -- number: starting ammo (-1 = infinite)
    maxAmmo = 100,                   -- number: max ammo capacity
    spread = 0.05,                   -- number: angular spread in radians
    range = 800,                     -- number: max range in world units
    burstSize = 3,                   -- number: rounds per burst
    burstDelay = 0.05,               -- number: delay between burst rounds
    projectileSpeed = 600,           -- number: projectile velocity (for ballistic/homing)
    projectileSize = 4,              -- number: projectile body radius

    -- Homing-specific
    trackingStrength = 5.0,          -- number: PID gain (higher = more aggressive tracking)
    turnRate = 3.0,                  -- number: max angular velocity for homing

    -- Area-specific
    blastRadius = 100,               -- number: area-of-effect radius
    falloff = "quadratic",           -- string: "none", "linear", "quadratic"

    -- Beam-specific
    beamWidth = 5,                   -- number: beam width for rendering
    damagePerSecond = 200,           -- number: continuous damage rate

    -- Ray-specific
    piercing = false,                -- boolean: if true, hits all bodies along ray
}
```

---

## Type: ProjectilePool

Pre-allocated pool of physics bodies for efficient projectile spawning.

**Created by:** `luna.combat.newProjectilePool()`

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `spawn` | `x: number, y: number, angle: number, speed: number` | `Projectile \| nil` | Get a projectile from the pool and launch it. Returns nil if pool is exhausted |
| `release` | `projectile: Projectile` | — | Return a projectile to the pool (called automatically on hit/expiry) |
| `getActive` | — | `table<Projectile>` | List all currently active projectiles |
| `getActiveCount` | — | `number` | Number of active projectiles |
| `getPoolSize` | — | `number` | Total pool capacity |
| `getFreeCount` | — | `number` | Number of available projectiles in pool |
| `update` | `dt: number` | — | Update all active projectiles (movement, homing, lifetime). Called by `luna.combat.update()` |
| `reset` | — | — | Release all active projectiles back to pool |

### ProjectilePool Definition Table

```lua
{
    poolSize = 200,                  -- number: max simultaneous projectiles (max 1024)
    bodyShape = "circle",            -- string: "circle" or "rectangle"
    radius = 3,                      -- number: for circle shape
    width = 8, height = 2,           -- number: for rectangle shape
    density = 1.0,                   -- number: body density
    isBullet = true,                 -- boolean: enable CCD for fast projectiles
    isSensor = false,                -- boolean: if true, detects overlap without physical collision
    lifetime = 3.0,                  -- number: max seconds before auto-release
    collisionGroup = "projectile",   -- string: collision group name
}
```

---

## Type: Projectile

A single in-flight projectile from a pool.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getBody` | — | `Body` | Get the physics body |
| `getPosition` | — | `number, number` | Current world position |
| `getVelocity` | — | `number, number` | Current velocity |
| `getAngle` | — | `number` | Current heading angle |
| `getSpeed` | — | `number` | Current speed magnitude |
| `getLifetime` | — | `number` | Time alive in seconds |
| `getDistanceTraveled` | — | `number` | Total distance traveled |
| `getSource` | — | `Weapon` | The weapon that fired this projectile |
| `setTarget` | `x: number, y: number` | — | Set/update homing target position |
| `setTargetBody` | `body: Body` | — | Set homing target to track a physics body continuously |
| `isActive` | — | `boolean` | True if not yet released back to pool |
| `release` | — | — | Manually release back to pool |

---

## Type: CollisionGroupSet

Named collision group manager abstracting physics simulation libraries's 16-bit category/mask system.

**Created by:** `luna.combat.newCollisionGroupSet()`

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `defineGroup` | `name: string` | `number` | Register a named group and return its category bit. Max 16 groups |
| `getGroupBit` | `name: string` | `number` | Get the category bit for a named group |
| `setCollides` | `groupA: string, groupB: string, collides: boolean` | — | Set whether two groups collide with each other |
| `getCollides` | `groupA: string, groupB: string` | `boolean` | Check if two groups collide |
| `setTeamCollision` | `team: string, collidesWithSelf: boolean` | — | Set whether members of the same team collide |
| `applyToFixture` | `fixture: Fixture, group: string, team?: string` | — | Apply category and mask bits to a physics fixture |
| `getGroups` | — | `table<string>` | List all defined group names |
| `getGroupCount` | — | `number` | Number of defined groups |
| `reset` | — | — | Clear all group definitions |

### Typical Group Setup

```lua
local groups = luna.combat.newCollisionGroupSet()
groups:defineGroup("player")
groups:defineGroup("enemy")
groups:defineGroup("playerProjectile")
groups:defineGroup("enemyProjectile")
groups:defineGroup("wall")
groups:defineGroup("pickup")

-- Player projectiles hit enemies and walls, not player or other player projectiles
groups:setCollides("playerProjectile", "enemy", true)
groups:setCollides("playerProjectile", "wall", true)
groups:setCollides("playerProjectile", "player", false)
groups:setCollides("playerProjectile", "playerProjectile", false)

-- Enemy projectiles hit player and walls
groups:setCollides("enemyProjectile", "player", true)
groups:setCollides("enemyProjectile", "wall", true)
groups:setCollides("enemyProjectile", "enemy", false)

-- Pickups only collide with player
groups:setCollides("pickup", "player", true)
groups:setCollides("pickup", "wall", false)
groups:setCollides("pickup", "enemy", false)
```

---

## Enums

### Projectile Type

| Value | Description |
|---|---|
| `"ballistic"` | Standard physics projectile — affected by gravity, travels in arc/line |
| `"homing"` | Steers toward a target using PID-like controller with configurable tracking |
| `"ray"` | Instant hitscan — raycast from barrel to range, no travel time |
| `"area"` | Explodes on impact — deals damage in a radius with falloff |
| `"beam"` | Continuous ray — deals damage per second while active |

### Damage Falloff

| Value | Description |
|---|---|
| `"none"` | Full damage at all distances within radius |
| `"linear"` | Damage decreases linearly from center to edge |
| `"quadratic"` | Damage decreases quadratically (inverse square) from center |

### Armor Zone

| Value | Description |
|---|---|
| `"front"` | Forward-facing armor (0° ± 45°) |
| `"rear"` | Rear armor (180° ± 45°) |
| `"side"` | Side armor (90° ± 45°, both sides) |
| `"top"` | Top armor (used for area/splash damage) |

---

## Usage Example

### Building a Tank

```lua
local world = luna.physics.newWorld(0, 0, true)
local groups = luna.combat.newCollisionGroupSet()
groups:defineGroup("player")
groups:defineGroup("enemy")
groups:defineGroup("playerProjectile")
groups:defineGroup("wall")
groups:setCollides("playerProjectile", "enemy", true)
groups:setCollides("playerProjectile", "wall", true)
groups:setCollides("playerProjectile", "player", false)

-- Create chassis
local tank = luna.combat.newChassis(world, {
    x = 200, y = 300,
    shape = "rectangle", width = 60, height = 30,
    mass = 800, maxHealth = 1500,
    armor = { front = 100, rear = 30, side = 50, top = 20 },
    team = "player",
    slots = {
        { id = "main_gun", x = 0, y = -8, sizeClass = "large", arcMin = -180, arcMax = 180 },
        { id = "coaxial_mg", x = 10, y = -5, sizeClass = "small", arcMin = -5, arcMax = 5 },
    },
})
groups:applyToFixture(tank:getBody():getFixtures()[1], "player")

-- Create turret
local turret = luna.combat.newTurret({
    shape = "rectangle", width = 20, height = 12,
    mass = 80, turnSpeed = 1.2, sizeClass = "large",
})
tank:attachTurret("main_gun", turret)

-- Create projectile pool
local shellPool = luna.combat.newProjectilePool(world, {
    poolSize = 50, bodyShape = "circle", radius = 4,
    density = 5.0, isBullet = true, lifetime = 4.0,
    collisionGroup = "playerProjectile",
})

-- Create weapon with particle effects
local mainGun = luna.combat.newWeapon({
    name = "120mm Cannon",
    projectileType = "ballistic",
    fireRate = 0.5, damage = { amount = 200, type = "kinetic", penetration = 80 },
    ammo = 40, maxAmmo = 40, spread = 0.02, range = 1200,
    projectileSpeed = 800, projectileSize = 4,
})
mainGun:setMuzzleEmitter(muzzleFlash)    -- from luna.particles
mainGun:setImpactEmitter(explosionFx)
mainGun:setTrailEmitter(smokeTrail)

mainGun:onHit(function(weapon, target, px, py, normal, damage)
    print(string.format("Hit at (%.0f, %.0f) for %d damage", px, py, damage.amount))
end)

turret:attachWeapon(mainGun)
```

### Combat Loop

```lua
function luna.update(dt)
    -- Aim turret at mouse
    local mx, my = luna.mouse.getPosition()
    turret:aimAt(mx, my)

    -- Fire on click
    if luna.mouse.isDown(1) then
        mainGun:fire(mx, my)
    end

    -- Update all combat systems (projectiles, homing, cooldowns)
    luna.combat.update(dt)

    -- Physics step
    world:update(dt)
end
```

### Homing Missiles

```lua
local missilePool = luna.combat.newProjectilePool(world, {
    poolSize = 20, bodyShape = "rectangle", width = 12, height = 3,
    density = 0.5, isBullet = true, lifetime = 8.0,
})

local launcher = luna.combat.newWeapon({
    name = "Missile Launcher",
    projectileType = "homing",
    fireRate = 1.0, damage = { amount = 150, type = "explosive" },
    ammo = 8, maxAmmo = 8, projectileSpeed = 300,
    trackingStrength = 4.0, turnRate = 2.5,
    blastRadius = 60, falloff = "linear",  -- missiles also have area damage on impact
})

-- Fire at enemy body — missile tracks it continuously
launcher:fire()
local missiles = missilePool:getActive()
for _, missile in ipairs(missiles) do
    missile:setTargetBody(enemyBody)
end
```

### Area-of-Effect Weapons

```lua
-- Grenade launcher
local grenadeWeapon = luna.combat.newWeapon({
    name = "Grenade Launcher",
    projectileType = "area",
    fireRate = 0.8, damage = { amount = 80, type = "explosive" },
    ammo = -1, projectileSpeed = 400,
    blastRadius = 120, falloff = "quadratic",
})

-- Manual area damage (not from a weapon)
local hitList = luna.combat.applyAreaDamage(world, 500, 300, 150,
    { amount = 300, type = "explosive" }, "linear")
print(#hitList .. " bodies hit by explosion")
```

### Ray/Hitscan Weapons

```lua
local railgun = luna.combat.newWeapon({
    name = "Railgun",
    projectileType = "ray",
    fireRate = 0.3, damage = { amount = 500, type = "kinetic", penetration = 200 },
    ammo = 10, maxAmmo = 10, range = 2000,
    piercing = true,  -- passes through multiple targets
})
```

### Beam Weapons

```lua
local laser = luna.combat.newWeapon({
    name = "Mining Laser",
    projectileType = "beam",
    damagePerSecond = 100, range = 400,
    beamWidth = 3, ammo = -1,
})
laser:startFiring()  -- continuous fire
-- ... later
laser:stopFiring()
```

### Performance: Object Budget Management

```lua
function luna.update(dt)
    luna.combat.update(dt)

    -- Monitor active counts
    local projectiles = luna.combat.getActiveProjectileCount()
    local vehicles = luna.combat.getActiveVehicleCount()

    -- Throttle spawning if over budget
    if projectiles > 800 then
        -- Reduce fire rates or skip low-priority spawns
        print("WARNING: approaching projectile pool limit")
    end

    world:update(dt)
end
```

---

## Extension Integration

The combat module integrates with several extension panels for visual authoring:

### Entity Designer (`luna2d.editor.entityDesigner`)

Chassis, turret, and weapon prefabs can be composed using the Entity Designer's component system. Relevant component templates:

| Component | Fields | Usage |
|---|---|---|
| `Physics` | density, friction, restitution, fixedRotation | Chassis body properties |
| `Health` | max, current, regenRate, invincibleTime | Chassis armor/health values |
| `Movement` | speed, jumpForce | Chassis drive speed |
| `Particle` | emitter, offset | Muzzle flash and impact effects |

### Particle Designer (`luna2d.editor.particleDesigner`)

Visual effects for weapons are authored in the Particle Designer panel:
- **Muzzle flash**: short-lived burst preset (e.g., `sparks`)
- **Projectile trail**: continuous emission preset (e.g., `smoke`)
- **Impact effect**: one-shot burst preset (e.g., `explosion`)

Presets are loaded via `luna.particles.loadFile()` and attached to weapons using `setMuzzleEmitter()`, `setTrailEmitter()`, `setImpactEmitter()`.

### Graph Editor (`luna2d.editor.graphEditor`)

Damage flow and weapon upgrade trees can be modeled as node graphs:
- **Node types**: Weapon, DamageType, ArmorZone, Modifier
- **Edge types**: DealsDamage, Resists, Upgrades

## Implemented Objects

- `CollisionGroupSet`: define groups, enable or disable collisions, compute masks
- `Chassis`: health, armor, slots, user data, destroyed state
- `Turret`: turn speed, arc limits, aim target, size class, destroyed state
- `Weapon`: fire rate, ammo, burst behavior, projectile config, cooldowns
- `ProjectilePool`: spawn, release, reset, active/free counts
- `CombatWorld`: add/get entities, active counts, update cooldowns, cleanup, reset

## Notes

- The Rust module does not directly import other Tier 3 gameplay modules.
- `ProjectileType` supports `ballistic`, `homing`, `ray`, `area`, and `beam` as configuration tags.
- `MAX_POOL_SIZE` is `1024` per projectile pool.
- Turn-based battles now live in `src/battle/` and Lua exposes them under `luna.battle.*`.

---

## Type: Chassis

A vehicle body with mount slots for turrets and fixed weapons.

**Created by:** `luna.combat.newChassis()`

### Movement

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getBody` | — | `Body` | Get the underlying physics body |
| `getPosition` | — | `number, number` | Get chassis world position (x, y) |
| `getAngle` | — | `number` | Get chassis rotation in radians |
| `setLinearVelocity` | `vx: number, vy: number` | — | Set velocity (delegates to physics body) |
| `setAngularVelocity` | `omega: number` | — | Set angular velocity |
| `applyForce` | `fx: number, fy: number` | — | Apply force at center of mass |
| `applyTorque` | `torque: number` | — | Apply rotational torque |

### Mount Slots

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getSlots` | — | `table` | List all mount slots: `{id, x, y, sizeClass, arcMin, arcMax, occupied}` |
| `getSlot` | `slotId: string` | `table \| nil` | Get a specific slot definition |
| `attachTurret` | `slotId: string, turret: Turret` | — | Attach a turret to a mount slot. Creates a revolute joint |
| `detachTurret` | `slotId: string` | `Turret \| nil` | Remove and return the turret from a slot |
| `attachWeapon` | `slotId: string, weapon: Weapon` | — | Attach a fixed weapon directly (no turret rotation) |
| `getTurret` | `slotId: string` | `Turret \| nil` | Get the turret in a slot |
| `getWeapon` | `slotId: string` | `Weapon \| nil` | Get the fixed weapon in a slot |

### Armor & Health

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getHealth` | — | `number` | Current health |
| `getMaxHealth` | — | `number` | Maximum health |
| `setHealth` | `hp: number` | — | Set current health (clamped to 0..max) |
| `getArmor` | `zone?: string` | `number` | Get armor value. Zone: `"front"`, `"rear"`, `"side"`, `"top"` (default: average) |
| `setArmor` | `zone: string, value: number` | — | Set armor for a zone |
| `isDead` | — | `boolean` | True if health ≤ 0 |
| `onDamage` | `callback: function` | — | Register damage callback: `fn(chassis, damage, source)` |
| `onDeath` | `callback: function` | — | Register death callback: `fn(chassis, lastDamage)` |

### State

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getTeam` | — | `string` | Get collision team/faction |
| `setTeam` | `team: string` | — | Set collision team (used for group filtering) |
| `getUserData` | — | `any` | Get user-attached data |
| `setUserData` | `data: any` | — | Attach arbitrary data |
| `destroy` | — | — | Remove chassis and all attached turrets/weapons from the world |
| `isDestroyed` | — | `boolean` | True if chassis has been destroyed |

### Chassis Definition Table

```lua
{
    x = 100, y = 200,               -- number: spawn position
    shape = "rectangle",             -- string: "rectangle", "circle", "polygon"
    width = 60, height = 30,         -- number: for rectangle shape
    radius = 20,                     -- number: for circle shape
    vertices = {...},                -- table: for polygon shape (array of x,y pairs)
    mass = 500,                      -- number: body mass in kg
    maxHealth = 1000,                -- number: starting/max health
    armor = {                        -- table: per-zone armor values
        front = 50, rear = 20, side = 30, top = 10
    },
    team = "player",                 -- string: collision team/faction
    slots = {                        -- table: mount slot definitions
        { id = "turret_main", x = 0, y = -5, sizeClass = "large", arcMin = -180, arcMax = 180 },
        { id = "turret_rear", x = -20, y = 0, sizeClass = "small", arcMin = 90, arcMax = 270 },
        { id = "fixed_mg", x = 15, y = 0, sizeClass = "small", arcMin = -10, arcMax = 10 },
    },
    linearDamping = 0.5,             -- number: physics damping
    angularDamping = 0.8,            -- number: rotational damping
}
```

---

## Movement

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getBody` | — | `Body` | Get the underlying physics body |
| `getPosition` | — | `number, number` | Get chassis world position (x, y) |
| `getAngle` | — | `number` | Get chassis rotation in radians |
| `setLinearVelocity` | `vx: number, vy: number` | — | Set velocity (delegates to physics body) |
| `setAngularVelocity` | `omega: number` | — | Set angular velocity |
| `applyForce` | `fx: number, fy: number` | — | Apply force at center of mass |
| `applyTorque` | `torque: number` | — | Apply rotational torque |

## Mount Slots

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getSlots` | — | `table` | List all mount slots: `{id, x, y, sizeClass, arcMin, arcMax, occupied}` |
| `getSlot` | `slotId: string` | `table \| nil` | Get a specific slot definition |
| `attachTurret` | `slotId: string, turret: Turret` | — | Attach a turret to a mount slot. Creates a revolute joint |
| `detachTurret` | `slotId: string` | `Turret \| nil` | Remove and return the turret from a slot |
| `attachWeapon` | `slotId: string, weapon: Weapon` | — | Attach a fixed weapon directly (no turret rotation) |
| `getTurret` | `slotId: string` | `Turret \| nil` | Get the turret in a slot |
| `getWeapon` | `slotId: string` | `Weapon \| nil` | Get the fixed weapon in a slot |

## Item Summary

| Kind | Count |
|------|-------|
| `const` | 1 |
| `enum` | 2 |
| `mod` | 5 |
| `struct` | 8 |
| **Total** | **16** |

