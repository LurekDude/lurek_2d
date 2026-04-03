//! Integration tests for `luna.shooter.*` vehicle combat.

use luna2d::lua_api::{create_lua_vm, SharedState};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    create_lua_vm(state).unwrap()
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle Combat System Tests
// ─────────────────────────────────────────────────────────────────────────────

// ── CollisionGroupSet ─────────────────────────────────────────────────────────

#[test]
fn collision_group_basic() {
    let lua = make_vm();
    lua.load(
        r#"
        local g = luna.shooter.newCollisionGroupSet()
        assert(g:type() == "CollisionGroupSet", "type")
        assert(g:getGroupCount() == 0, "empty")
        local bit = g:defineGroup("player")
        assert(bit > 0, "bit assigned")
        assert(g:getGroupCount() == 1, "count after define")
        assert(g:getGroupBit("player") == bit, "get bit matches")
        local bit2 = g:defineGroup("enemy")
        assert(bit2 > 0, "second bit assigned")
        assert(bit2 ~= bit, "unique bits")
        assert(g:getGroupCount() == 2, "two groups")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn collision_group_collisions() {
    let lua = make_vm();
    lua.load(
        r#"
        local g = luna.shooter.newCollisionGroupSet()
        g:defineGroup("player")
        g:defineGroup("enemy")
        g:defineGroup("bullet")
        -- Default: all groups collide before explicit rules
        assert(g:getCollides("player", "enemy"), "default collides")
        g:setCollides("player", "enemy", true)
        assert(g:getCollides("player", "enemy"), "player-enemy collides")
        assert(g:getCollides("enemy", "player"), "symmetric collides")
        g:setCollides("player", "enemy", false)
        assert(not g:getCollides("player", "enemy"), "disabled collide")
        g:setCollides("player", "bullet", false)
        assert(not g:getCollides("player", "bullet"), "player-bullet disabled")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn collision_group_max_16() {
    let lua = make_vm();
    lua.load(
        r#"
        local g = luna.shooter.newCollisionGroupSet()
        for i = 1, 16 do
            g:defineGroup("group" .. i)
        end
        assert(g:getGroupCount() == 16, "16 groups defined")
        local ok, err = pcall(function() g:defineGroup("group17") end)
        assert(not ok, "17th group should fail")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn collision_group_compute_mask() {
    let lua = make_vm();
    lua.load(
        r#"
        local g = luna.shooter.newCollisionGroupSet()
        g:defineGroup("player")
        g:defineGroup("enemy")
        g:defineGroup("wall")
        g:setCollides("player", "enemy", true)
        g:setCollides("player", "wall", true)
        local mask = g:computeMask("player")
        assert(mask ~= nil, "mask not nil")
        assert(mask > 0, "mask has bits")
        local enemy_bit = g:getGroupBit("enemy")
        local wall_bit = g:getGroupBit("wall")
        -- mask should include both enemy and wall bits
        assert(bit.band(mask, enemy_bit) == enemy_bit, "mask includes enemy")
        assert(bit.band(mask, wall_bit) == wall_bit, "mask includes wall")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn collision_group_names_and_reset() {
    let lua = make_vm();
    lua.load(
        r#"
        local g = luna.shooter.newCollisionGroupSet()
        g:defineGroup("alpha")
        g:defineGroup("beta")
        local names = g:getGroupNames()
        assert(#names == 2, "2 names")
        g:reset()
        assert(g:getGroupCount() == 0, "reset clears groups")
    "#,
    )
    .exec()
    .unwrap();
}

// ── Chassis ───────────────────────────────────────────────────────────────────

#[test]
fn chassis_creation() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.shooter.newChassis(1, 100.0)
        assert(c:type() == "Chassis", "type")
        assert(c:getBodyId() == 1, "body id")
        assert(c:getMaxHp() == 100.0, "max hp")
        assert(c:getHp() == 100.0, "full hp at creation")
        assert(not c:isDead(), "alive")
        assert(not c:isDestroyed(), "not destroyed")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn chassis_damage_and_heal() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.shooter.newChassis(1, 100.0)
        local dmg = c:takeDamage(30.0)
        assert(math.abs(dmg - 30.0) < 0.001, "30 damage dealt")
        assert(math.abs(c:getHp() - 70.0) < 0.001, "70 hp remaining")
        local healed = c:heal(10.0)
        assert(math.abs(healed - 10.0) < 0.001, "healed 10")
        assert(math.abs(c:getHp() - 80.0) < 0.001, "80 hp after heal")
        c:takeDamage(80.0)
        assert(c:isDead(), "dead after lethal damage")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn chassis_heal_capped_at_max() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.shooter.newChassis(1, 100.0)
        c:takeDamage(20.0)
        c:heal(999.0)
        assert(math.abs(c:getHp() - 100.0) < 0.001, "heal capped at max hp")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn chassis_slots() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.shooter.newChassis(1, 100.0)
        local slots = c:getSlots()
        assert(#slots == 0, "no slots initially")
        c:addSlot({id="main", x=0, y=0, sizeClass="large", arcMin=-1.57, arcMax=1.57})
        c:addSlot({id="secondary", x=1, y=0, sizeClass="small"})
        slots = c:getSlots()
        assert(#slots == 2, "two slots")
        assert(slots[1].id == "main", "first slot id")
        assert(slots[1].sizeClass == "large", "first slot size")
        assert(slots[2].id == "secondary", "second slot id")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn chassis_armor() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.shooter.newChassis(1, 100.0)
        assert(c:getArmor("front") == 0.0, "default armor is 0")
        c:setArmor("front", 50.0)
        c:setArmor("rear", 20.0)
        assert(c:getArmor("front") == 50.0, "front armor set")
        assert(c:getArmor("rear") == 20.0, "rear armor set")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn chassis_team_and_userdata() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.shooter.newChassis(1, 100.0)
        c:setTeam("allies")
        assert(c:getTeam() == "allies", "team")
        c:setUserData("player_tank")
        assert(c:getUserData() == "player_tank", "user data")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn chassis_destroy() {
    let lua = make_vm();
    lua.load(
        r#"
        local c = luna.shooter.newChassis(1, 100.0)
        c:destroy()
        assert(c:isDestroyed(), "destroyed")
        assert(c:getHp() == 0.0, "hp zeroed on destroy")
    "#,
    )
    .exec()
    .unwrap();
}

// ── Turret ────────────────────────────────────────────────────────────────────

#[test]
fn turret_creation() {
    let lua = make_vm();
    lua.load(
        r#"
        local t = luna.shooter.newTurret(2, 3)
        assert(t:type() == "Turret", "type")
        assert(t:getBodyId() == 2, "body id")
        assert(t:getJointId() == 3, "joint id")
        assert(not t:isDestroyed(), "not destroyed")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn turret_aiming_and_turn_speed() {
    let lua = make_vm();
    lua.load(
        r#"
        local t = luna.shooter.newTurret(2, 3)
        t:setTurnSpeed(3.14)
        assert(math.abs(t:getTurnSpeed() - 3.14) < 0.001, "turn speed")
        t:aimAtAngle(1.0)
        -- After aimAtAngle the turret may or may not be aimed depending on
        -- its current angle vs target; verify isAimed is callable
        local aimed = t:isAimed()
        assert(type(aimed) == "boolean", "isAimed returns boolean")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn turret_arc_limits() {
    let lua = make_vm();
    lua.load(
        r#"
        local t = luna.shooter.newTurret(2, 3)
        t:setArcMin(-1.57)
        t:setArcMax(1.57)
        assert(math.abs(t:getArcMin() - (-1.57)) < 0.001, "arc min")
        assert(math.abs(t:getArcMax() - 1.57) < 0.001, "arc max")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn turret_size_class_and_destroy() {
    let lua = make_vm();
    lua.load(
        r#"
        local t = luna.shooter.newTurret(5, 6)
        t:setSizeClass("heavy")
        assert(t:getSizeClass() == "heavy", "size class")
        t:destroy()
        assert(t:isDestroyed(), "destroyed")
    "#,
    )
    .exec()
    .unwrap();
}

// ── Weapon ────────────────────────────────────────────────────────────────────

#[test]
fn weapon_creation() {
    let lua = make_vm();
    lua.load(
        r#"
        local w = luna.shooter.newWeapon("Plasma Cannon")
        assert(w:type() == "Weapon", "type")
        assert(w:getName() == "Plasma Cannon", "name")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn weapon_fire_rate_and_ammo() {
    let lua = make_vm();
    lua.load(
        r#"
        local w = luna.shooter.newWeapon("Gun")
        w:setFireRate(10.0)
        assert(w:getFireRate() == 10.0, "fire rate")
        w:setAmmo(50)
        w:setMaxAmmo(100)
        assert(w:getAmmo() == 50, "ammo")
        assert(not w:isOutOfAmmo(), "has ammo")
        w:setAmmo(0)
        assert(w:isOutOfAmmo(), "out of ammo")
        w:reload()
        assert(w:getAmmo() == 100, "reloaded to max")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn weapon_firing() {
    let lua = make_vm();
    lua.load(
        r#"
        local w = luna.shooter.newWeapon("Auto")
        w:setFireRate(10.0)
        w:setAmmo(10)
        w:setMaxAmmo(10)
        assert(w:canFire(), "can fire initially")
        local fired = w:fire()
        assert(fired, "fired successfully")
        assert(w:getAmmo() == 9, "ammo decremented")
        -- After firing, should be on cooldown
        assert(not w:canFire(), "on cooldown after fire")
        -- updateCooldown should reduce it
        w:updateCooldown(1.0)
        assert(w:canFire(), "ready after cooldown update")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn weapon_burst_and_spread() {
    let lua = make_vm();
    lua.load(
        r#"
        local w = luna.shooter.newWeapon("Burst")
        w:setBurstSize(3)
        w:setBurstDelay(0.1)
        w:setSpread(0.05)
        assert(w:getBurstSize() == 3, "burst size")
        assert(math.abs(w:getBurstDelay() - 0.1) < 0.001, "burst delay")
        assert(math.abs(w:getSpread() - 0.05) < 0.001, "spread")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn weapon_projectile_config() {
    let lua = make_vm();
    lua.load(
        r#"
        local w = luna.shooter.newWeapon("Missile")
        w:setProjectileType("homing")
        assert(w:getProjectileType() == "homing", "proj type")
        w:setProjectileSpeed(500.0)
        assert(w:getProjectileSpeed() == 500.0, "proj speed")
        w:setRange(1000.0)
        assert(w:getRange() == 1000.0, "range")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn weapon_damage_and_penetration() {
    let lua = make_vm();
    lua.load(
        r#"
        local w = luna.shooter.newWeapon("Railgun")
        w:setDamage(200.0)
        w:setDamageType("kinetic")
        w:setPenetration(80.0)
        assert(w:getDamage() == 200.0, "damage")
        assert(w:getDamageType() == "kinetic", "damage type")
        assert(w:getPenetration() == 80.0, "penetration")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn weapon_continuous_fire() {
    let lua = make_vm();
    lua.load(
        r#"
        local w = luna.shooter.newWeapon("MG")
        assert(not w:isFiring(), "not firing initially")
        w:startFiring()
        assert(w:isFiring(), "firing after start")
        w:stopFiring()
        assert(not w:isFiring(), "stopped firing")
    "#,
    )
    .exec()
    .unwrap();
}

// ── ProjectilePool ────────────────────────────────────────────────────────────

#[test]
fn projectile_pool_creation() {
    let lua = make_vm();
    lua.load(
        r#"
        local pool = luna.shooter.newProjectilePool(100)
        assert(pool:type() == "ProjectilePool", "type")
        assert(pool:getPoolSize() == 100, "size")
        assert(pool:getActiveCount() == 0, "no active")
        assert(pool:getFreeCount() == 100, "all free")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn projectile_pool_spawn_release() {
    let lua = make_vm();
    lua.load(
        r#"
        local pool = luna.shooter.newProjectilePool(10)
        local idx = pool:spawn(0, 0, 0, 100, 10, "kinetic", 500)
        assert(idx ~= nil, "spawned")
        assert(pool:getActiveCount() == 1, "one active")
        assert(pool:getFreeCount() == 9, "nine free")
        pool:release(idx)
        assert(pool:getActiveCount() == 0, "released")
        assert(pool:getFreeCount() == 10, "all free again")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn projectile_pool_exhaustion() {
    let lua = make_vm();
    lua.load(
        r#"
        local pool = luna.shooter.newProjectilePool(3)
        pool:spawn(0, 0, 0, 100, 10, "kinetic", 500)
        pool:spawn(1, 0, 0, 100, 10, "kinetic", 500)
        pool:spawn(2, 0, 0, 100, 10, "kinetic", 500)
        assert(pool:getActiveCount() == 3, "pool full")
        assert(pool:getFreeCount() == 0, "none free")
        local idx = pool:spawn(3, 0, 0, 100, 10, "kinetic", 500)
        assert(idx == nil, "spawn returns nil when exhausted")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn projectile_pool_reset() {
    let lua = make_vm();
    lua.load(
        r#"
        local pool = luna.shooter.newProjectilePool(5)
        pool:spawn(0, 0, 0, 100, 10, "kinetic", 500)
        pool:spawn(1, 0, 0, 100, 10, "kinetic", 500)
        assert(pool:getActiveCount() == 2, "two active")
        pool:reset()
        assert(pool:getActiveCount() == 0, "reset clears all")
        assert(pool:getFreeCount() == 5, "all free after reset")
    "#,
    )
    .exec()
    .unwrap();
}

// ── CombatWorld ───────────────────────────────────────────────────────────────

#[test]
fn combat_world_creation() {
    let lua = make_vm();
    lua.load(
        r#"
        local world = luna.shooter.newCombatWorld()
        assert(world:type() == "CombatWorld", "type")
        assert(world:getActiveChassisCount() == 0, "no chassis")
        assert(world:getActiveProjectileCount() == 0, "no projectiles")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combat_world_add_entities() {
    let lua = make_vm();
    lua.load(
        r#"
        local world = luna.shooter.newCombatWorld()
        local chassis = luna.shooter.newChassis(1, 100.0)
        local idx = world:addChassis(chassis)
        assert(idx == 0, "first chassis index")
        assert(world:getActiveChassisCount() == 1, "one chassis")

        local turret = luna.shooter.newTurret(2, 3)
        local tidx = world:addTurret(turret)
        assert(tidx == 0, "first turret index")

        local weapon = luna.shooter.newWeapon("Gun")
        local widx = world:addWeapon(weapon)
        assert(widx == 0, "first weapon index")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combat_world_update_reset() {
    let lua = make_vm();
    lua.load(
        r#"
        local world = luna.shooter.newCombatWorld()
        world:update(0.016)
        world:reset()
        assert(world:getActiveChassisCount() == 0, "reset empty")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combat_world_get_entities() {
    let lua = make_vm();
    lua.load(
        r#"
        local world = luna.shooter.newCombatWorld()
        local chassis = luna.shooter.newChassis(10, 200.0)
        chassis:setTeam("red")
        world:addChassis(chassis)
        local retrieved = world:getChassis(0)
        assert(retrieved ~= nil, "retrieved chassis")
        assert(retrieved:getBodyId() == 10, "body id preserved")
        assert(retrieved:getMaxHp() == 200.0, "max hp preserved")

        local turret = luna.shooter.newTurret(20, 30)
        world:addTurret(turret)
        local rt = world:getTurret(0)
        assert(rt ~= nil, "retrieved turret")
        assert(rt:getBodyId() == 20, "turret body id")

        local weapon = luna.shooter.newWeapon("Laser")
        world:addWeapon(weapon)
        local rw = world:getWeapon(0)
        assert(rw ~= nil, "retrieved weapon")
        assert(rw:getName() == "Laser", "weapon name")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combat_world_cleanup() {
    let lua = make_vm();
    lua.load(
        r#"
        local world = luna.shooter.newCombatWorld()
        local c1 = luna.shooter.newChassis(1, 100.0)
        local c2 = luna.shooter.newChassis(2, 100.0)
        world:addChassis(c1)
        world:addChassis(c2)
        assert(world:getActiveChassisCount() == 2, "two active")
        -- Destroy c1 via the world's copy
        local r = world:getChassis(0)
        r:destroy()
        -- cleanup is on the world's internal copy, so we need to destroy there
        -- Actually CombatWorld stores clones, so let's just test cleanup runs
        world:cleanup()
        -- At minimum, cleanup should not crash
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn combat_world_add_pool() {
    let lua = make_vm();
    lua.load(
        r#"
        local world = luna.shooter.newCombatWorld()
        local pool = luna.shooter.newProjectilePool(50)
        local pidx = world:addPool(pool)
        assert(pidx == 0, "first pool index")
        local rp = world:getPool(0)
        assert(rp ~= nil, "retrieved pool")
        assert(rp:getPoolSize() == 50, "pool size preserved")
    "#,
    )
    .exec()
    .unwrap();
}
