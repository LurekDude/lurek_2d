# `library.combat`

*97 functions, 0 module fields documented.*

## Functions

### `newCollisionGroupSet()`

Creates an empty collision-group set.

**Returns**

- CollisionGroupSet New instance with no groups or rules.

### `defineGroup(name)`

Defines a named group and returns its power-of-two category bit. Returns nil plus an error string if the name is empty, taken, or the 16-group limit has been reached (bitmask overflow protection).

**Parameters**

- `name` *string* — Unique group name (non-empty).

**Returns**

- *number|nil* — Category bit, or nil on error.
- *string|nil* — Error message when first return is nil.

### `getGroupBit(name)`

Returns the category bit for the named group, or nil.

**Parameters**

- `name` *string* — Group name.

**Returns**

- number|nil Category bit or nil.

### `setCollides(group_a, group_b, collides)`

Sets whether two named groups should collide with each other.

**Parameters**

- `group_a` *string* — First group name.
- `group_b` *string* — Second group name.
- `collides` *boolean* — True to enable collision.

**Returns**

- boolean True on success; false if either group is unknown.

### `getCollides(group_a, group_b)`

Returns whether two named groups collide (defaults to true).

**Parameters**

- `group_a` *string* — First group name.
- `group_b` *string* — Second group name.

**Returns**

- boolean True if the groups collide.

### `computeMask(group)`

Computes the collision filter mask bits for the named group.

**Parameters**

- `group` *string* — Group name.

**Returns**

- number Bitmask of all colliding groups.

### `groupCount()`

Returns the number of defined groups.

**Returns**

- number Group count.

### `groupNames()`

Returns an array of all defined group names.

**Returns**

- table Array of group name strings.

### `reset()`

Clears all groups and collision rules.

### `newMountSlot(id, x, y, size_class)`

Creates a new turret or weapon mount slot.

**Parameters**

- `id` *string* — Unique slot identifier (non-empty).
- `x` *number* — Local X offset from chassis centre (default 0).
- `y` *number* — Local Y offset from chassis centre (default 0).
- `size_class` *string* — Size class: 'small', 'medium', or 'large' (default 'medium').

**Returns**

- *table* — MountSlot with arc_min=-pi, arc_max=pi defaults.

### `newChassis(body_id, max_hp)`

Creates a new chassis with the given physics body ID and maximum hit points.

**Parameters**

- `body_id` *number* — Physics body ID.
- `max_hp` *number* — Maximum hit points (must be >= 0; HP starts at max_hp).

**Returns**

- *Chassis* — New chassis instance.

### `addSlot(slot)`

Appends a mount slot to this chassis.

**Parameters**

- `slot` *table* — A MountSlot created by newMountSlot.

### `getSlot(id)`

Returns the mount slot with the given ID, or nil.

**Parameters**

- `id` *string* — Slot identifier.

**Returns**

- table|nil The matching MountSlot or nil.

### `getSlots()`

Returns an ordered array of all mount slots.

**Returns**

- table Array of MountSlot tables.

### `takeDamage(amount)`

Applies damage to the chassis, clamping HP to zero. Sets destroyed=true if HP reaches zero.

**Parameters**

- `amount` *number* — Damage to apply (must be >= 0).

**Returns**

- *number* — Actual damage dealt.

### `heal(amount)`

Heals the chassis, clamping HP to max_hp.

**Parameters**

- `amount` *number* — HP to restore.

**Returns**

- number Actual amount healed.

### `isDead()`

Returns true if the chassis is destroyed or HP has reached zero.

**Returns**

- boolean True if dead.

### `getArmor(zone)`

Returns the armor value for the named zone (defaults to 0).

**Parameters**

- `zone` *string* — Zone name, e.g. 'front', 'rear', 'side'.

**Returns**

- number Armor value.

### `setArmor(zone, value)`

Sets the armor value for the named zone.

**Parameters**

- `zone` *string* — Zone name.
- `value` *number* — Armor value.

### `newTurret(body_id, joint_id)`

Creates a new turret with the given physics body and joint IDs.

**Parameters**

- `body_id` *number* — Physics body ID for the turret plate.
- `joint_id` *number* — Revolute joint ID connecting turret to chassis.

**Returns**

- *Turret* — New turret with default arc [-pi, pi].

### `update(dt, current_angle)`

Updates the turret toward its target angle, snapping to the closest arc boundary when the target lies outside [arc_min, arc_max]. Returns the desired angular velocity, or nil if no target is set.

**Parameters**

- `dt` *number* — Delta time in seconds.
- `current_angle` *number* — Current turret angle in radians.

**Returns**

- *number|nil* — Angular velocity or nil.

### `aimAtAngle(angle)`

Sets the desired target angle for the turret.

**Parameters**

- `angle` *number* — Target angle in radians.

### `isAimed(tolerance)`

Returns true if the target angle is within the turret arc and tolerance. Mirrors Rust: checks whether clamp_to_arc(target) Ôëł target. Returns true when no target is set.

**Parameters**

- `tolerance` *number* — Maximum allowed arc-boundary deviation in radians.

**Returns**

- boolean True if within tolerance or no target is set.

### `clampToArc(angle)`

Clamps an angle to the turret arc limits [arc_min, arc_max].

**Parameters**

- `angle` *number* — Angle in radians.

**Returns**

- number Clamped angle.

### `newWeapon(name)`

Creates a new weapon with default values. Defaults: fire_rate=1, ammo=-1 (infinite), damage_amount=10, range=500, projectile_speed=300, burst_size=1.

**Parameters**

- `name` *string* — Weapon display name (non-empty).

**Returns**

- *Weapon* — New weapon instance.

### `canFire()`

Returns true if the weapon is ready to fire.

**Returns**

- boolean True when cooldown elapsed and ammo is available.

### `fire(dt)`

Attempts to fire the weapon. Returns true if a shot was produced. Consumes one ammo token, applies cooldown, and manages burst state. Intra-burst shots use burst_delay; after the last burst shot, inter-burst cooldown (1/fire_rate) is applied.

**Parameters**

- `dt` *number* — Delta time (unused; kept for API parity with Rust).

**Returns**

- *boolean* — True if a shot was fired.

### `startFiring()`

Activates continuous firing mode.

### `stopFiring()`

Deactivates firing and resets burst_remaining to zero.

### `isFiring()`

Returns true when the weapon is in firing mode.

**Returns**

- boolean Firing state.

### `updateCooldown(dt)`

Ticks the cooldown timer by dt seconds.

**Parameters**

- `dt` *number* — Delta time in seconds.

### `reload(amount)`

Reloads ammo. Full reload when amount is nil; partial reload otherwise. Clamped to max_ammo when max_ammo > 0.

**Parameters**

- `amount` *number|nil* — Rounds to add, or nil for a full reload.

### `isOutOfAmmo()`

Returns true when finite ammo reaches zero.

**Returns**

- boolean True when ammo == 0 and not infinite.

### `reset()`

Resets this projectile to its inactive default state. Clears all fields including projectile_type (restored to Ballistic).

### `update(dt, body_x, body_y, body_angle)`

Updates lifetime and distance_traveled for an active projectile. Does nothing if the projectile is not active.

**Parameters**

- `dt` *number* — Delta time in seconds.
- `body_x` *number* — Current X position (passed for physics parity).
- `body_y` *number* — Current Y position.
- `body_angle` *number* — Current angle in radians.

### `newProjectilePool(pool_size, projectile_type)`

Creates a new projectile pool with the given capacity. Defaults to DEFAULT_POOL_SIZE (64) when pool_size is nil; capped at MAX_POOL_SIZE (1024).

**Parameters**

- `pool_size` *number* — Pool capacity (default 64, max 1024).
- `projectile_type` *string* — ProjectileType for this pool (default Ballistic).

**Returns**

- *ProjectilePool* — New pool with all slots free.

### `spawn(x, y, angle, speed, damage, damage_type, range)`

Spawns a projectile from the free pool.

**Parameters**

- `x` *number* — Spawn X position.
- `y` *number* — Spawn Y position.
- `angle` *number* — Launch angle in radians.
- `speed` *number* — Travel speed in world units per second.
- `damage` *number* — Damage dealt on hit.
- `damage_type` *string* — Damage type tag.
- `range` *number* — Maximum range before expiry.

**Returns**

- number|nil Projectile index, or nil if the pool is exhausted.

### `release(idx)`

Returns a projectile slot to the free pool. Does nothing if the slot is already inactive (prevents double-free).

**Parameters**

- `idx` *number* — 1-based projectile index.

### `activeCount()`

Returns the number of currently active projectiles.

**Returns**

- number Active count.

### `freeCount()`

Returns the number of free slots.

**Returns**

- number Free count.

### `getActive()`

Returns an array of 1-based indices for all active projectiles.

**Returns**

- table Array of active indices.

### `get(idx)`

Returns the projectile at the given 1-based index, or nil if out of range.

**Parameters**

- `idx` *number* — 1-based slot index.

**Returns**

- table|nil Projectile table or nil.

### `resetAll()`

Releases all active projectiles back to the free pool.

### `newCombatWorld()`

Creates an empty combat world. This is a logical container only — broad-phase hit detection and shape queries should be performed against a real physics world via `lurek.physics.newWorld():raycast()` / `:shapecast()` and the resulting contacts then mapped back onto chassis/turret/weapon entities here.

**Returns**

- CombatWorld New world with no entities.

See: [`lurek.physics`](../lua-api.md#lurekphysics), [`lurek.math`](../lua-api.md#lurekmath)

### `addChassis(chassis)`

Adds a chassis and returns its 1-based index.

**Parameters**

- `chassis` *table* — A Chassis created by newChassis.

**Returns**

- number 1-based index.

### `getChassis(idx)`

Returns the chassis at the given 1-based index, or nil.

**Parameters**

- `idx` *number* — 1-based index.

**Returns**

- table|nil Chassis or nil.

### `addTurret(turret)`

Adds a turret and returns its 1-based index.

**Parameters**

- `turret` *table* — A Turret created by newTurret.

**Returns**

- number 1-based index.

### `getTurret(idx)`

Returns the turret at the given 1-based index, or nil.

**Parameters**

- `idx` *number* — 1-based index.

**Returns**

- table|nil Turret or nil.

### `addWeapon(weapon)`

Adds a weapon and returns its 1-based index.

**Parameters**

- `weapon` *table* — A Weapon created by newWeapon.

**Returns**

- number 1-based index.

### `getWeapon(idx)`

Returns the weapon at the given 1-based index, or nil.

**Parameters**

- `idx` *number* — 1-based index.

**Returns**

- table|nil Weapon or nil.

### `addPool(pool)`

Adds a projectile pool and returns its 1-based index.

**Parameters**

- `pool` *table* — A ProjectilePool created by newProjectilePool.

**Returns**

- number 1-based index.

### `getPool(idx)`

Returns the projectile pool at the given 1-based index, or nil.

**Parameters**

- `idx` *number* — 1-based index.

**Returns**

- table|nil ProjectilePool or nil.

### `activeProjectileCount()`

Returns the total number of active projectiles across all pools.

**Returns**

- number Active projectile count.

### `activeChassisCount()`

Returns the number of non-destroyed chassis.

**Returns**

- number Live chassis count.

### `update(dt)`

Updates all weapon cooldowns by dt seconds.

**Parameters**

- `dt` *number* — Delta time in seconds.

### `reset()`

Clears all combat entities and resets collision groups.

### `cleanup()`

Removes destroyed chassis from the list. Warning: invalidates stored 1-based indices after the call.

### `getName()`

Returns the weapon display name. @return string Name.

### `setName(v)`

Sets the weapon display name. @param v string Name.

### `getFireRate()`

Returns fire rate in rounds/s. @return number Fire rate.

### `setFireRate(v)`

Sets fire rate in rounds/s. @param v number Fire rate.

### `getAmmo()`

Returns current ammo count (-1 = infinite). @return number Ammo.

### `setAmmo(v)`

Sets current ammo count. @param v number Ammo.

### `getMaxAmmo()`

Returns maximum ammo capacity. @return number Max ammo.

### `setMaxAmmo(v)`

Sets maximum ammo capacity. @param v number Max ammo.

### `getBurstSize()`

Returns burst size (rounds per burst). @return number Burst size.

### `setBurstSize(v)`

Sets burst size. @param v number Burst size.

### `getBurstDelay()`

Returns delay between burst rounds in seconds. @return number Burst delay.

### `setBurstDelay(v)`

Sets burst delay in seconds. @param v number Burst delay.

### `getBurstRemaining()`

Returns remaining rounds in current burst. @return number Burst remaining.

### `setBurstRemaining(v)`

Sets remaining rounds in current burst. @param v number Value.

### `getSpread()`

Returns angular spread in radians. @return number Spread.

### `setSpread(v)`

Sets angular spread in radians. @param v number Spread.

### `getDamageAmount()`

Returns damage per hit. @return number Damage amount.

### `setDamageAmount(v)`

Sets damage per hit. @param v number Damage amount.

### `getDamageType()`

Returns damage type tag. @return string Damage type.

### `setDamageType(v)`

Sets damage type tag. @param v string Damage type.

### `getPenetration()`

Returns armor penetration value. @return number Penetration.

### `setPenetration(v)`

Sets armor penetration value. @param v number Penetration.

### `getRange()`

Returns maximum range in world units. @return number Range.

### `setRange(v)`

Sets maximum range in world units. @param v number Range.

### `getProjectileSpeed()`

Returns projectile travel speed. @return number Speed.

### `setProjectileSpeed(v)`

Sets projectile travel speed. @param v number Speed.

### `getProjectileType()`

Returns projectile type enum value. @return string ProjectileType.

### `setProjectileType(v)`

Sets projectile type. @param v string ProjectileType value.

### `getTurnSpeed()`

Returns the turret rotation speed in radians/s. @return number Turn speed.

### `setTurnSpeed(v)`

Sets the turret rotation speed. @param v number Turn speed in radians/s.

### `getArcMin()`

Returns the minimum arc angle in radians. @return number arc_min.

### `setArcMin(v)`

Sets the minimum arc angle in radians. @param v number arc_min.

### `getArcMax()`

Returns the maximum arc angle in radians. @return number arc_max.

### `setArcMax(v)`

Sets the maximum arc angle in radians. @param v number arc_max.

### `getTargetAngle()`

Returns the current target angle, or nil. @return number|nil Target angle in radians.

### `setTargetAngle(v)`

Sets the target angle (nil clears the target). @param v number|nil Target angle.

### `getSizeClass()`

Returns the turret size class. @return string Size class.

### `setSizeClass(v)`

Sets the turret size class. @param v string Size class.

### `isDestroyed()`

Returns true if this turret is destroyed. @return boolean Destroyed flag.

### `setDestroyed(v)`

Sets the destroyed flag. @param v boolean Destroyed state.
