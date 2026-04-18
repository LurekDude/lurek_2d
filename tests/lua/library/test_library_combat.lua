--- BDD tests for library.combat
--- Covers: CollisionGroupSet, MountSlot, Chassis, Turret, Weapon,
---         Projectile, ProjectilePool, CombatWorld.

package.path = "./content/library/?/init.lua;" .. package.path

local combat = require("library.combat")

dofile("tests/lua/init.lua")

-- â”€â”€ CollisionGroupSet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests collision group registration, symmetric collision masks, group enumeration, reset behavior, and mask computation for enabled interactions.
describe("CollisionGroupSet", function()
    -- @covers library.combat.newCollisionGroupSet
    -- @description Verifies group definitions allocate successive power-of-two bitmasks for collision filtering.
    it("defineGroup assigns power-of-2 bits", function()
        local cgs = combat.newCollisionGroupSet()
        local b1 = cgs:defineGroup("players")
        local b2 = cgs:defineGroup("enemies")
        local b3 = cgs:defineGroup("projectiles")
        expect_equal(b1, 1)
        expect_equal(b2, 2)
        expect_equal(b3, 4)
    end)

    -- @covers library.combat.newCollisionGroupSet
    -- @description Confirms getGroupBit returns the assigned bit for known groups and nil for missing ones.
    it("getGroupBit returns correct bit", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("a")
        expect_equal(cgs:getGroupBit("a"), 1)
        expect_equal(cgs:getGroupBit("missing"), nil)
    end)

    -- @covers library.combat.newCollisionGroupSet
    -- @description Checks collision relationships can be overridden symmetrically and queried back.
    it("setCollides and getCollides", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("friends")
        cgs:defineGroup("foes")
        cgs:setCollides("friends", "friends", false)
        expect_equal(cgs:getCollides("friends", "friends"), false)
        expect_equal(cgs:getCollides("friends", "foes"), true)
    end)

    -- @covers library.combat.newCollisionGroupSet
    -- @description Verifies group counting and name enumeration reflect all defined collision groups.
    it("groupCount and groupNames", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("a")
        cgs:defineGroup("b")
        expect_equal(cgs:groupCount(), 2)
        local names = cgs:groupNames()
        expect_equal(#names, 2)
    end)

    -- @covers library.combat.newCollisionGroupSet
    -- @description Confirms reset clears all registered groups and group-bit lookups.
    it("reset clears everything", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("x")
        cgs:reset()
        expect_equal(cgs:groupCount(), 0)
        expect_equal(cgs:getGroupBit("x"), nil)
    end)

    -- @covers library.combat.newCollisionGroupSet
    -- @description Checks duplicate group definitions fail cleanly instead of reassigning a bit.
    it("duplicate group returns nil", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("a")
        local b, err = cgs:defineGroup("a")
        expect_equal(b, nil)
    end)

    -- @covers library.combat.newCollisionGroupSet
    -- @description Verifies computeMask includes only the groups currently configured to collide with the requested group.
    it("computeMask includes colliding groups", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("a")
        cgs:defineGroup("b")
        cgs:defineGroup("c")
        cgs:setCollides("a", "c", false)
        local mask = cgs:computeMask("a")
        -- a(1) collides with a(1) and b(2) but not c(4) â†’ mask = 3
        expect_equal(mask, 3)
    end)
end)

-- â”€â”€ MountSlot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies mount slot construction, default size class selection, and default full-circle firing arc values.
describe("MountSlot", function()
    -- @covers library.combat.newMountSlot
    -- @description Verifies mount slots preserve id, position, and explicit size class values.
    it("creates with defaults", function()
        local s = combat.newMountSlot("turret_1", 10, 20, "large")
        expect_equal(s.id, "turret_1")
        expect_equal(s.x, 10)
        expect_equal(s.y, 20)
        expect_equal(s.size_class, "large")
    end)

    -- @covers library.combat.newMountSlot
    -- @description Confirms omitted size class and firing arc arguments fall back to medium and a full-circle arc.
    it("arc defaults to full circle and size_class defaults to medium", function()
        local s = combat.newMountSlot("gun", 5, -3)
        expect_equal(s.size_class, "medium")
        expect_near(s.arc_min, -math.pi, 0.001)
        expect_near(s.arc_max, math.pi, 0.001)
    end)
end)

-- â”€â”€ Chassis â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers chassis durability, armor, slot registration, lethal damage, healing clamps, and per-zone armor lookup helpers.
describe("Chassis", function()
    -- @covers library.combat.newChassis
    -- @description Verifies chassis start with matching HP and max HP and are not destroyed initially.
    it("new with max_hp", function()
        local c = combat.newChassis(1, 100)
        expect_equal(c.hp, 100)
        expect_equal(c.max_hp, 100)
        expect_equal(c.destroyed, false)
    end)

    -- @covers library.combat.newChassis
    -- @description Checks nonlethal damage subtracts HP, returns actual damage taken, and keeps the chassis alive.
    it("takeDamage reduces hp and returns actual", function()
        local c = combat.newChassis(1, 50)
        local actual = c:takeDamage(30)
        expect_equal(actual, 30)
        expect_equal(c.hp, 20)
        expect_equal(c:isDead(), false)
    end)

    -- @covers library.combat.newChassis
    -- @description Confirms lethal damage clamps HP to zero and marks the chassis destroyed.
    it("takeDamage beyond hp sets destroyed", function()
        local c = combat.newChassis(1, 10)
        local actual = c:takeDamage(25)
        expect_equal(actual, 10)
        expect_equal(c.hp, 0)
        expect_equal(c:isDead(), true)
    end)

    -- @covers library.combat.newChassis
    -- @description Verifies healing restores only missing HP up to the maximum.
    it("heal clamps to max_hp", function()
        local c = combat.newChassis(1, 100)
        c:takeDamage(60)
        local healed = c:heal(80)
        expect_equal(healed, 60)
        expect_equal(c.hp, 100)
    end)

    -- @covers library.combat.newChassis
    -- @covers library.combat.newMountSlot
    -- @description Checks chassis can register mount slots and retrieve them by id.
    it("addSlot and getSlot", function()
        local c = combat.newChassis(1, 100)
        c:addSlot(combat.newMountSlot("s1", 0, 0, "small"))
        expect_equal(#c:getSlots(), 1)
        expect_equal(c:getSlot("s1").size_class, "small")
        expect_equal(c:getSlot("missing"), nil)
    end)

    -- @covers library.combat.newChassis
    -- @description Confirms armor can be stored per zone and defaults to zero for unset zones.
    it("armor get/set", function()
        local c = combat.newChassis(1, 100)
        c:setArmor("front", 50)
        expect_equal(c:getArmor("front"), 50)
        expect_equal(c:getArmor("rear"), 0)
    end)
end)

-- â”€â”€ Turret â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises turret targeting, arc clamping, aiming detection, angular update output, and the full getter or setter surface for turret state.
describe("Turret", function()
    -- @covers library.combat.newTurret
    -- @description Verifies turrets start with the supplied body and joint ids plus default speed and destroyed state.
    it("new with defaults", function()
        local t = combat.newTurret(10, 20)
        expect_equal(t.body_id, 10)
        expect_equal(t.joint_id, 20)
        expect_equal(t.turn_speed, 1.0)
        expect_equal(t.destroyed, false)
    end)

    -- @covers library.combat.newTurret
    -- @description Checks aimAtAngle stores the desired target angle for later updates.
    it("aimAtAngle sets target", function()
        local t = combat.newTurret(1, 2)
        t:aimAtAngle(1.5)
        expect_equal(t.target_angle, 1.5)
    end)

    -- @covers library.combat.newTurret
    -- @description Verifies clampToArc constrains target angles to the configured turret arc.
    it("clampToArc clamps angle", function()
        local t = combat.newTurret(1, 2)
        t.arc_min = -1.0
        t.arc_max = 1.0
        expect_equal(t:clampToArc(2.0), 1.0)
        expect_equal(t:clampToArc(-2.0), -1.0)
        expect_equal(t:clampToArc(0.5), 0.5)
    end)

    -- @covers library.combat.newTurret
    -- @description Confirms update returns angular velocity when the target angle exceeds the maximum turn step.
    it("update returns angular velocity", function()
        local t = combat.newTurret(1, 2)
        t.turn_speed = 2.0
        t:aimAtAngle(1.0)
        local vel = t:update(0.1, 0)
        -- diff = 1.0, max_step = 0.2, diff > max_step â†’ return turn_speed = 2.0
        expect_equal(vel, 2.0)
    end)

    -- @covers library.combat.newTurret
    -- @description Checks update returns nil when the turret has no target angle to turn toward.
    it("update returns nil without target", function()
        local t = combat.newTurret(1, 2)
        expect_equal(t:update(0.1, 0), nil)
    end)

    -- @covers library.combat.newTurret
    -- @description Verifies turrets without a target are considered aimed already.
    it("isAimed returns true when no target set", function()
        local t = combat.newTurret(1, 2)
        expect_equal(t:isAimed(0.01), true)
    end)

    -- @covers library.combat.newTurret
    -- @description Confirms isAimed returns true when the target angle lies within the allowed arc.
    it("isAimed returns true when target is within arc", function()
        local t = combat.newTurret(1, 2)
        t.arc_min = -1.0
        t.arc_max = 1.0
        t:aimAtAngle(0.5)  -- 0.5 is inside [-1, 1], clamp(0.5)=0.5, diff=0
        expect_equal(t:isAimed(0.01), true)
    end)

    -- @covers library.combat.newTurret
    -- @description Checks isAimed reports false when the target lies outside the turret arc after clamping.
    it("isAimed returns false when target is outside arc", function()
        local t = combat.newTurret(1, 2)
        t.arc_min = -1.0
        t.arc_max = 1.0
        t:aimAtAngle(2.0)  -- clamp(2.0)=1.0, diff=1.0 > 0.01
        expect_equal(t:isAimed(0.01), false)
    end)

    -- @covers library.combat.newTurret
    -- @description Verifies the turret getter and setter surface round-trips speed, arc, target, size class, and destroyed state.
    it("Turret getters and setters", function()
        local t = combat.newTurret(5, 6)
        t:setTurnSpeed(3.0)
        expect_equal(t:getTurnSpeed(), 3.0)
        t:setArcMin(-0.5)
        expect_equal(t:getArcMin(), -0.5)
        t:setArcMax(0.5)
        expect_equal(t:getArcMax(), 0.5)
        t:setTargetAngle(0.3)
        expect_equal(t:getTargetAngle(), 0.3)
        t:setTargetAngle(nil)
        expect_equal(t:getTargetAngle(), nil)
        t:setSizeClass("large")
        expect_equal(t:getSizeClass(), "large")
        t:setDestroyed(true)
        expect_equal(t:isDestroyed(), true)
        t:setDestroyed(false)
        expect_equal(t:isDestroyed(), false)
    end)
end)

-- â”€â”€ Weapon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates weapon defaults, firing and cooldown flow, reload logic, burst-fire state, ammo exhaustion checks, and weapon property accessors.
describe("Weapon", function()
    -- @covers library.combat.newWeapon
    -- @description Verifies weapons start with the expected default name, ammo mode, and ready-to-fire state.
    it("new with defaults", function()
        local w = combat.newWeapon("Laser")
        expect_equal(w.name, "Laser")
        expect_equal(w.ammo, -1)
        expect_equal(w:canFire(), true)
    end)

    -- @covers library.combat.newWeapon
    -- @description Checks firing a weapon consumes ammo and applies a cooldown based on fire rate.
    it("fire consumes ammo and sets cooldown", function()
        local w = combat.newWeapon("Gun")
        w.ammo = 5
        w.max_ammo = 10
        w.fire_rate = 2.0
        expect_equal(w:fire(0.016), true)
        expect_equal(w.ammo, 4)
        expect_equal(w:canFire(), false)  -- cooldown active
    end)

    -- @covers library.combat.newWeapon
    -- @description Confirms weapon cooldown timers tick down and clamp at zero.
    it("updateCooldown reduces cooldown", function()
        local w = combat.newWeapon("Gun")
        w.cooldown_remaining = 0.5
        w:updateCooldown(0.3)
        expect_near(w.cooldown_remaining, 0.2, 0.001)
        w:updateCooldown(0.3)
        expect_equal(w.cooldown_remaining, 0)
    end)

    -- @covers library.combat.newWeapon
    -- @description Verifies reload without an explicit amount restores ammo back to the maximum.
    it("reload refills to max", function()
        local w = combat.newWeapon("Gun")
        w.ammo = 0
        w.max_ammo = 10
        w:reload()
        expect_equal(w.ammo, 10)
    end)

    -- @covers library.combat.newWeapon
    -- @description Checks partial reload amounts add rounds without exceeding max ammo.
    it("reload with amount adds rounds", function()
        local w = combat.newWeapon("Gun")
        w.ammo = 3
        w.max_ammo = 10
        w:reload(5)
        expect_equal(w.ammo, 8)
    end)

    -- @covers library.combat.newWeapon
    -- @description Confirms weapons with infinite ammo never report themselves out of ammo.
    it("isOutOfAmmo with infinite ammo", function()
        local w = combat.newWeapon("Laser")
        expect_equal(w:isOutOfAmmo(), false)
    end)

    -- @covers library.combat.newWeapon
    -- @description Verifies finite-ammo weapons report out-of-ammo correctly at zero remaining rounds.
    it("isOutOfAmmo with finite ammo", function()
        local w = combat.newWeapon("Gun")
        w.ammo = 0
        w.max_ammo = 5
        expect_equal(w:isOutOfAmmo(), true)
    end)

    -- @covers library.combat.newWeapon
    -- @description Checks startFiring and stopFiring toggle the active firing state.
    it("startFiring and stopFiring", function()
        local w = combat.newWeapon("Gun")
        w:startFiring()
        expect_equal(w:isFiring(), true)
        w:stopFiring()
        expect_equal(w:isFiring(), false)
    end)

    -- @covers library.combat.newWeapon
    -- @description Confirms newly created weapons expose the documented default damage, range, and projectile speed values.
    it("defaults match Rust: damage_amount=10 range=500 projectile_speed=300", function()
        local w = combat.newWeapon("TestGun")
        expect_equal(w.damage_amount, 10.0)
        expect_equal(w.range, 500.0)
        expect_equal(w.projectile_speed, 300.0)
    end)

    -- @covers library.combat.newWeapon
    -- @description Verifies the first shot of a burst weapon seeds remaining burst shots and applies burst delay cooldown.
    it("fire with burst_size=3 sets burst_remaining and uses burst_delay", function()
        local w = combat.newWeapon("Burst")
        w.burst_size = 3
        w.burst_delay = 0.1
        w.fire_rate = 1.0
        -- First shot: burst_remaining was 0, set to max(0, 3-1)=2, cooldown=burst_delay
        expect_equal(w:fire(0), true)
        expect_equal(w.burst_remaining, 2)
        expect_near(w.cooldown_remaining, 0.1, 0.001)
    end)

    -- @covers library.combat.newWeapon
    -- @description Confirms stopping fire clears remaining burst state as well as the firing flag.
    it("stopFiring resets burst_remaining to 0", function()
        local w = combat.newWeapon("Burst")
        w.burst_size = 3
        w.burst_remaining = 2
        w:stopFiring()
        expect_equal(w.burst_remaining, 0)
        expect_equal(w:isFiring(), false)
    end)

    -- @covers library.combat.newWeapon
    -- @description Checks the weapon getter and setter surface round-trips all major weapon tuning fields and enums.
    it("Weapon getters and setters", function()
        local w = combat.newWeapon("Test")
        expect_equal(w:getName(), "Test")
        w:setName("Updated")
        expect_equal(w:getName(), "Updated")
        w:setFireRate(5.0)
        expect_equal(w:getFireRate(), 5.0)
        w:setAmmo(20)
        expect_equal(w:getAmmo(), 20)
        w:setMaxAmmo(30)
        expect_equal(w:getMaxAmmo(), 30)
        w:setBurstSize(4)
        expect_equal(w:getBurstSize(), 4)
        w:setBurstDelay(0.05)
        expect_near(w:getBurstDelay(), 0.05, 0.001)
        w:setSpread(0.2)
        expect_near(w:getSpread(), 0.2, 0.001)
        w:setDamageAmount(25.0)
        expect_equal(w:getDamageAmount(), 25.0)
        w:setDamageType("explosive")
        expect_equal(w:getDamageType(), "explosive")
        w:setPenetration(10)
        expect_equal(w:getPenetration(), 10)
        w:setRange(800)
        expect_equal(w:getRange(), 800)
        w:setProjectileSpeed(400)
        expect_equal(w:getProjectileSpeed(), 400)
        w:setProjectileType(combat.ProjectileType.Homing)
        expect_equal(w:getProjectileType(), combat.ProjectileType.Homing)
    end)
end)

-- â”€â”€ Projectile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Focuses on pooled projectile instances to verify reset behavior and active-update bookkeeping for lifetime and traveled distance.
describe("Projectile", function()
    -- @covers library.combat.newProjectilePool
    -- @description Verifies releasing a projectile resets pooled projectile fields back to their default inactive state.
    it("reset clears all fields and restores projectile_type to Ballistic", function()
        local pool = combat.newProjectilePool(2, combat.ProjectileType.Homing)
        local idx = pool:spawn(0, 0, 0, 100, 10, "kinetic", 500)
        local p = pool:get(idx)
        p.lifetime = 0.5
        p.distance_traveled = 100
        pool:release(idx)
        -- release calls p:reset()
        expect_equal(p.active, false)
        expect_equal(p.lifetime, 0)
        expect_equal(p.distance_traveled, 0)
        expect_equal(p.projectile_type, combat.ProjectileType.Ballistic)
    end)

    -- @covers library.combat.newProjectilePool
    -- @description Confirms inactive projectiles ignore update calls and do not accumulate distance.
    it("update does nothing when projectile is inactive", function()
        local pool = combat.newProjectilePool(2)
        local idx = pool:spawn(0, 0, 0, 100, 10, "k", 500)
        local p = pool:get(idx)
        pool:release(idx)  -- deactivate
        p:update(1.0, 0, 0, 0)
        expect_equal(p.distance_traveled, 0)
    end)

    -- @covers library.combat.newProjectilePool
    -- @description Checks active projectile updates advance both lifetime and traveled distance based on speed and elapsed time.
    it("update advances lifetime and distance when active", function()
        local pool = combat.newProjectilePool(2)
        local idx = pool:spawn(0, 0, 0, 200, 10, "k", 500)
        local p = pool:get(idx)
        p:update(0.5, 0, 0, 0)
        expect_near(p.lifetime, 0.5, 0.001)
        expect_near(p.distance_traveled, 100.0, 0.01)
    end)
end)

-- â”€â”€ ProjectilePool â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests projectile pool allocation, exhaustion, release safety, pooled lookup, pool-size clamping, and active-slot bookkeeping.
describe("ProjectilePool", function()
    -- @covers library.combat.newProjectilePool
    -- @description Verifies projectile pools start with all slots free and no active projectiles.
    it("new creates pool with free slots", function()
        local pool = combat.newProjectilePool(10)
        expect_equal(pool:freeCount(), 10)
        expect_equal(pool:activeCount(), 0)
    end)

    -- @covers library.combat.newProjectilePool
    -- @description Checks spawning and releasing a projectile updates active and free slot counts.
    it("spawn and release", function()
        local pool = combat.newProjectilePool(5)
        local idx = pool:spawn(0, 0, 0, 100, 10, "kinetic", 500)
        expect_equal(idx ~= nil, true)
        expect_equal(pool:activeCount(), 1)
        expect_equal(pool:freeCount(), 4)
        pool:release(idx)
        expect_equal(pool:activeCount(), 0)
        expect_equal(pool:freeCount(), 5)
    end)

    -- @covers library.combat.newProjectilePool
    -- @description Confirms getActive returns the indices of all currently active projectile slots.
    it("getActive returns active indices", function()
        local pool = combat.newProjectilePool(5)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        local active = pool:getActive()
        expect_equal(#active, 2)
    end)

    -- @covers library.combat.newProjectilePool
    -- @description Verifies resetAll releases every active projectile and restores full capacity.
    it("resetAll releases all", function()
        local pool = combat.newProjectilePool(5)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:resetAll()
        expect_equal(pool:activeCount(), 0)
        expect_equal(pool:freeCount(), 5)
    end)

    -- @covers library.combat.newProjectilePool
    -- @description Checks oversized pool requests clamp to the module's maximum supported pool size.
    it("pool capped at MAX_POOL_SIZE", function()
        local pool = combat.newProjectilePool(9999)
        expect_equal(pool.pool_size, 1024)
    end)

    -- @covers library.combat.newProjectilePool
    -- @description Confirms spawn returns nil once all projectile slots are exhausted.
    it("spawn returns nil when exhausted", function()
        local pool = combat.newProjectilePool(2)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        local idx = pool:spawn(0, 0, 0, 100, 10, "k", 500)
        expect_equal(idx, nil)
    end)

    -- @covers library.combat.newProjectilePool
    -- @description Verifies pooled projectile lookup exposes the stored projectile speed, damage, and damage type fields.
    it("get returns projectile data", function()
        local pool = combat.newProjectilePool(5)
        local idx = pool:spawn(0, 0, 0, 200, 25, "explosive", 800)
        local p = pool:get(idx)
        expect_equal(p.speed, 200)
        expect_equal(p.damage_amount, 25)
        expect_equal(p.damage_type, "explosive")
    end)

    -- @covers library.combat.newProjectilePool
    -- @description Checks releasing an already inactive slot is a harmless no-op that does not duplicate free slots.
    it("release of already-inactive slot is a no-op", function()
        local pool = combat.newProjectilePool(3)
        local idx = pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:release(idx)
        local free_before = pool:freeCount()
        pool:release(idx)  -- second release must not add idx again
        expect_equal(pool:freeCount(), free_before)
    end)
end)

-- â”€â”€ CombatWorld â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies combat world aggregation of chassis, turrets, weapons, and pools together with updates, cleanup, counters, and reset behavior.
describe("CombatWorld", function()
    -- @covers library.combat.newCombatWorld
    -- @description Verifies new combat worlds start with empty chassis, turret, weapon, and pool collections.
    it("new creates empty world", function()
        local w = combat.newCombatWorld()
        expect_equal(#w.chassis_list, 0)
        expect_equal(#w.turrets, 0)
        expect_equal(#w.weapons, 0)
    end)

    -- @covers library.combat.newCombatWorld
    -- @covers library.combat.newChassis
    -- @description Confirms combat worlds can add chassis and retrieve them by their assigned index.
    it("add and get chassis", function()
        local w = combat.newCombatWorld()
        local c = combat.newChassis(1, 100)
        local idx = w:addChassis(c)
        expect_equal(idx, 1)
        expect_equal(w:getChassis(1).hp, 100)
    end)

    -- @covers library.combat.newCombatWorld
    -- @covers library.combat.newTurret
    -- @description Checks combat worlds can add turrets and fetch them again by index.
    it("add and get turret", function()
        local w = combat.newCombatWorld()
        local idx = w:addTurret(combat.newTurret(1, 2))
        expect_equal(idx, 1)
        expect_equal(w:getTurret(1).body_id, 1)
    end)

    -- @covers library.combat.newCombatWorld
    -- @covers library.combat.newWeapon
    -- @description Verifies combat worlds can add weapons and retrieve them later by index.
    it("add and get weapon", function()
        local w = combat.newCombatWorld()
        local idx = w:addWeapon(combat.newWeapon("Cannon"))
        expect_equal(idx, 1)
        expect_equal(w:getWeapon(1).name, "Cannon")
    end)

    -- @covers library.combat.newCombatWorld
    -- @covers library.combat.newProjectilePool
    -- @description Confirms projectile pools can be registered in the combat world and accessed by index.
    it("add and get pool", function()
        local w = combat.newCombatWorld()
        local pool = combat.newProjectilePool(5)
        local idx = w:addPool(pool)
        expect_equal(idx, 1)
        expect_equal(w:getPool(1).pool_size, 5)
    end)

    -- @covers library.combat.newCombatWorld
    -- @covers library.combat.newChassis
    -- @description Checks activeChassisCount excludes chassis that have already been destroyed.
    it("activeChassisCount excludes destroyed", function()
        local w = combat.newCombatWorld()
        w:addChassis(combat.newChassis(1, 100))
        local c2 = combat.newChassis(2, 50)
        c2:takeDamage(50)
        w:addChassis(c2)
        expect_equal(w:activeChassisCount(), 1)
    end)

    -- @covers library.combat.newCombatWorld
    -- @covers library.combat.newProjectilePool
    -- @description Verifies activeProjectileCount sums active projectiles across all registered pools.
    it("activeProjectileCount sums across pools", function()
        local w = combat.newCombatWorld()
        local pool = combat.newProjectilePool(10)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        w:addPool(pool)
        expect_equal(w:activeProjectileCount(), 2)
    end)

    -- @covers library.combat.newCombatWorld
    -- @covers library.combat.newWeapon
    -- @description Confirms world updates tick weapon cooldowns for weapons stored in the world.
    it("update ticks weapon cooldowns", function()
        local w = combat.newCombatWorld()
        local wpn = combat.newWeapon("Gun")
        wpn.cooldown_remaining = 1.0
        w:addWeapon(wpn)
        w:update(0.5)
        expect_near(w:getWeapon(1).cooldown_remaining, 0.5, 0.001)
    end)

    -- @covers library.combat.newCombatWorld
    -- @description Verifies reset clears all combat-world collections back to their empty state.
    it("reset clears everything", function()
        local w = combat.newCombatWorld()
        w:addChassis(combat.newChassis(1, 100))
        w:addWeapon(combat.newWeapon("X"))
        w:reset()
        expect_equal(#w.chassis_list, 0)
        expect_equal(#w.weapons, 0)
    end)

    -- @covers library.combat.newCombatWorld
    -- @covers library.combat.newChassis
    -- @description Checks cleanup removes destroyed chassis while preserving surviving entries.
    it("cleanup removes destroyed chassis", function()
        local w = combat.newCombatWorld()
        w:addChassis(combat.newChassis(1, 100))
        local c2 = combat.newChassis(2, 10)
        c2:takeDamage(10)
        w:addChassis(c2)
        w:addChassis(combat.newChassis(3, 100))
        w:cleanup()
        expect_equal(#w.chassis_list, 2)
    end)
end)

-- â”€â”€ Enums â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Confirms the combat module exports the expected projectile and armor-zone enum string constants.
describe("Enums", function()
    -- @covers library.combat.ProjectileType
    -- @covers library.combat.ArmorZone
    -- @description Confirms the projectile-type enum exports each supported projectile behavior string.
    it("ProjectileType has all variants", function()
        expect_equal(combat.ProjectileType.Ballistic, "ballistic")
        expect_equal(combat.ProjectileType.Homing, "homing")
        expect_equal(combat.ProjectileType.Ray, "ray")
        expect_equal(combat.ProjectileType.Area, "area")
        expect_equal(combat.ProjectileType.Beam, "beam")
    end)

    -- @covers library.combat.ArmorZone
    -- @description Verifies the armor-zone enum exposes the expected named zone strings.
    it("ArmorZone has all variants", function()
        expect_equal(combat.ArmorZone.Front, "front")
        expect_equal(combat.ArmorZone.Rear, "rear")
        expect_equal(combat.ArmorZone.Side, "side")
    end)
end)

-- ── Bug fix: collision group overflow error message ──────────────────────────

describe("CollisionGroupSet overflow", function()
    -- @covers library.combat.newCollisionGroupSet
    -- @description Verifies that exceeding the 16-group limit returns a descriptive error mentioning bitmask overflow.
    it("returns descriptive error when exceeding 16 groups", function()
        local cgs = combat.newCollisionGroupSet()
        for i = 1, 16 do
            local b, err = cgs:defineGroup("g" .. i)
            expect_equal(b ~= nil, true)
        end
        local b, err = cgs:defineGroup("g17")
        expect_equal(b, nil)
        expect_equal(type(err), "string")
        -- Error should mention limit and overflow
        expect_equal(err:find("16") ~= nil, true)
        expect_equal(err:find("overflow") ~= nil, true)
    end)

    -- @covers library.combat.newCollisionGroupSet
    -- @description Verifies empty group name is rejected with a descriptive error.
    it("rejects empty group name", function()
        local cgs = combat.newCollisionGroupSet()
        local b, err = cgs:defineGroup("")
        expect_equal(b, nil)
        expect_equal(err:find("non%-empty") ~= nil, true)
    end)
end)

-- ── Bug fix: turret arc snapping ─────────────────────────────────────────────

describe("Turret arc snapping", function()
    -- @covers library.combat.newTurret
    -- @description Verifies turret update snaps to arc_max when target is above the arc.
    it("update snaps to arc_max when target exceeds arc", function()
        local t = combat.newTurret(1, 2)
        t.turn_speed = 10.0
        t.arc_min = -1.0
        t.arc_max = 1.0
        -- Target at 2.0 rad is outside arc; effective target should be 1.0
        t:aimAtAngle(2.0)
        -- current_angle = 0.0, effective target = 1.0, diff = 1.0
        local vel = t:update(0.01, 0.0)
        -- diff=1.0, max_step=0.1, so vel = turn_speed = 10.0
        expect_equal(vel, 10.0)
    end)

    -- @covers library.combat.newTurret
    -- @description Verifies turret update snaps to arc_min when target is below the arc.
    it("update snaps to arc_min when target is below arc", function()
        local t = combat.newTurret(1, 2)
        t.turn_speed = 10.0
        t.arc_min = -1.0
        t.arc_max = 1.0
        -- Target at -3.0 is outside arc; effective = -1.0
        t:aimAtAngle(-3.0)
        local vel = t:update(0.01, 0.0)
        -- diff=-1.0, max_step=0.1, vel = -turn_speed = -10.0
        expect_equal(vel, -10.0)
    end)

    -- @covers library.combat.newTurret
    -- @description When current_angle is already at the clamped target, velocity is small (snap).
    it("update reaches clamped boundary exactly", function()
        local t = combat.newTurret(1, 2)
        t.turn_speed = 10.0
        t.arc_min = -1.0
        t.arc_max = 1.0
        t:aimAtAngle(5.0)  -- outside arc; effective = 1.0
        -- current_angle is already at 1.0 → diff = 0, vel = 0
        local vel = t:update(0.1, 1.0)
        expect_near(vel, 0.0, 0.01)
    end)
end)

-- ── Bug fix: weapon burst inter-burst cooldown ───────────────────────────────

describe("Weapon burst cooldown", function()
    -- @covers library.combat.newWeapon
    -- @description After the last burst shot, cooldown should be 1/fire_rate (inter-burst), not burst_delay.
    it("last burst shot applies fire_rate cooldown, not burst_delay", function()
        local w = combat.newWeapon("BurstGun")
        w.burst_size = 3
        w.burst_delay = 0.05
        w.fire_rate = 2.0  -- inter-burst cooldown = 1/2 = 0.5s

        -- Shot 1: starts new burst, burst_remaining = 2, cooldown = burst_delay
        expect_equal(w:fire(0), true)
        expect_equal(w.burst_remaining, 2)
        expect_near(w.cooldown_remaining, 0.05, 0.001)

        -- Expire cooldown
        w:updateCooldown(0.05)

        -- Shot 2: burst_remaining 2→1, cooldown = burst_delay (still mid-burst)
        expect_equal(w:fire(0), true)
        expect_equal(w.burst_remaining, 1)
        expect_near(w.cooldown_remaining, 0.05, 0.001)

        -- Expire cooldown
        w:updateCooldown(0.05)

        -- Shot 3 (last in burst): burst_remaining 1→0, cooldown = 1/fire_rate = 0.5
        expect_equal(w:fire(0), true)
        expect_equal(w.burst_remaining, 0)
        expect_near(w.cooldown_remaining, 0.5, 0.001)
    end)

    -- @covers library.combat.newWeapon
    -- @description Single-shot weapon (burst_size=1) still uses fire_rate cooldown.
    it("burst_size=1 always uses fire_rate cooldown", function()
        local w = combat.newWeapon("SingleShot")
        w.burst_size = 1
        w.fire_rate = 4.0  -- 1/4 = 0.25s cooldown
        expect_equal(w:fire(0), true)
        expect_near(w.cooldown_remaining, 0.25, 0.001)
    end)
end)

-- ── Input validation ─────────────────────────────────────────────────────────

describe("Input validation", function()
    -- @covers library.combat.newWeapon
    -- @description Verifies newWeapon rejects nil and empty names.
    it("newWeapon rejects empty name", function()
        expect_error(function() combat.newWeapon("") end)
    end)

    -- @covers library.combat.newWeapon
    -- @description Verifies newWeapon rejects nil name.
    it("newWeapon rejects nil name", function()
        expect_error(function() combat.newWeapon(nil) end)
    end)

    -- @covers library.combat.newChassis
    -- @description Verifies newChassis rejects negative HP.
    it("newChassis rejects negative max_hp", function()
        expect_error(function() combat.newChassis(1, -10) end)
    end)

    -- @covers library.combat.newChassis
    -- @description Verifies newChassis rejects non-number body_id.
    it("newChassis rejects non-number body_id", function()
        expect_error(function() combat.newChassis("bad", 100) end)
    end)

    -- @covers library.combat.newTurret
    -- @description Verifies newTurret rejects non-number arguments.
    it("newTurret rejects non-number body_id", function()
        expect_error(function() combat.newTurret(nil, 2) end)
    end)

    -- @covers library.combat.newMountSlot
    -- @description Verifies newMountSlot rejects empty id.
    it("newMountSlot rejects empty id", function()
        expect_error(function() combat.newMountSlot("") end)
    end)

    -- @covers library.combat.newChassis
    -- @description Verifies takeDamage rejects negative amounts.
    it("takeDamage rejects negative amount", function()
        local c = combat.newChassis(1, 100)
        expect_error(function() c:takeDamage(-5) end)
    end)

    -- @covers library.combat.newProjectilePool
    -- @description Verifies pool rejects size < 1.
    it("newProjectilePool rejects zero pool_size", function()
        expect_error(function() combat.newProjectilePool(0) end)
    end)
end)

-- ── Pool exhaustion and DEFAULT_POOL_SIZE ────────────────────────────────────

describe("ProjectilePool defaults", function()
    -- @covers library.combat.newProjectilePool
    -- @description Verifies DEFAULT_POOL_SIZE is exported and used when pool_size is nil.
    it("DEFAULT_POOL_SIZE is 64 and used when pool_size is nil", function()
        expect_equal(combat.DEFAULT_POOL_SIZE, 64)
        local pool = combat.newProjectilePool()
        expect_equal(pool.pool_size, 64)
    end)
end)

test_summary()
