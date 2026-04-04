--- BDD tests for library.combat
--- Covers: CollisionGroupSet, MountSlot, Chassis, Turret, Weapon,
---         Projectile, ProjectilePool, CombatWorld.

package.path = "./library/?/init.lua;" .. package.path

local combat = require("library.combat")

dofile("tests/lua/init.lua")

-- ── CollisionGroupSet ────────────────────────────────────────────────────

describe("CollisionGroupSet", function()
    it("defineGroup assigns power-of-2 bits", function()
        local cgs = combat.newCollisionGroupSet()
        local b1 = cgs:defineGroup("players")
        local b2 = cgs:defineGroup("enemies")
        local b3 = cgs:defineGroup("projectiles")
        expect_equal(b1, 1)
        expect_equal(b2, 2)
        expect_equal(b3, 4)
    end)

    it("getGroupBit returns correct bit", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("a")
        expect_equal(cgs:getGroupBit("a"), 1)
        expect_equal(cgs:getGroupBit("missing"), nil)
    end)

    it("setCollides and getCollides", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("friends")
        cgs:defineGroup("foes")
        cgs:setCollides("friends", "friends", false)
        expect_equal(cgs:getCollides("friends", "friends"), false)
        expect_equal(cgs:getCollides("friends", "foes"), true)
    end)

    it("groupCount and groupNames", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("a")
        cgs:defineGroup("b")
        expect_equal(cgs:groupCount(), 2)
        local names = cgs:groupNames()
        expect_equal(#names, 2)
    end)

    it("reset clears everything", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("x")
        cgs:reset()
        expect_equal(cgs:groupCount(), 0)
        expect_equal(cgs:getGroupBit("x"), nil)
    end)

    it("duplicate group returns nil", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("a")
        local b, err = cgs:defineGroup("a")
        expect_equal(b, nil)
    end)

    it("computeMask includes colliding groups", function()
        local cgs = combat.newCollisionGroupSet()
        cgs:defineGroup("a")
        cgs:defineGroup("b")
        cgs:defineGroup("c")
        cgs:setCollides("a", "c", false)
        local mask = cgs:computeMask("a")
        -- a(1) collides with a(1) and b(2) but not c(4) → mask = 3
        expect_equal(mask, 3)
    end)
end)

-- ── MountSlot ────────────────────────────────────────────────────────────

describe("MountSlot", function()
    it("creates with defaults", function()
        local s = combat.newMountSlot("turret_1", 10, 20, "large")
        expect_equal(s.id, "turret_1")
        expect_equal(s.x, 10)
        expect_equal(s.y, 20)
        expect_equal(s.size_class, "large")
    end)
end)

-- ── Chassis ──────────────────────────────────────────────────────────────

describe("Chassis", function()
    it("new with max_hp", function()
        local c = combat.newChassis(1, 100)
        expect_equal(c.hp, 100)
        expect_equal(c.max_hp, 100)
        expect_equal(c.destroyed, false)
    end)

    it("takeDamage reduces hp and returns actual", function()
        local c = combat.newChassis(1, 50)
        local actual = c:takeDamage(30)
        expect_equal(actual, 30)
        expect_equal(c.hp, 20)
        expect_equal(c:isDead(), false)
    end)

    it("takeDamage beyond hp sets destroyed", function()
        local c = combat.newChassis(1, 10)
        local actual = c:takeDamage(25)
        expect_equal(actual, 10)
        expect_equal(c.hp, 0)
        expect_equal(c:isDead(), true)
    end)

    it("heal clamps to max_hp", function()
        local c = combat.newChassis(1, 100)
        c:takeDamage(60)
        local healed = c:heal(80)
        expect_equal(healed, 60)
        expect_equal(c.hp, 100)
    end)

    it("addSlot and getSlot", function()
        local c = combat.newChassis(1, 100)
        c:addSlot(combat.newMountSlot("s1", 0, 0, "small"))
        expect_equal(#c:getSlots(), 1)
        expect_equal(c:getSlot("s1").size_class, "small")
        expect_equal(c:getSlot("missing"), nil)
    end)

    it("armor get/set", function()
        local c = combat.newChassis(1, 100)
        c:setArmor("front", 50)
        expect_equal(c:getArmor("front"), 50)
        expect_equal(c:getArmor("rear"), 0)
    end)
end)

-- ── Turret ───────────────────────────────────────────────────────────────

describe("Turret", function()
    it("new with defaults", function()
        local t = combat.newTurret(10, 20)
        expect_equal(t.body_id, 10)
        expect_equal(t.joint_id, 20)
        expect_equal(t.turn_speed, 1.0)
        expect_equal(t.destroyed, false)
    end)

    it("aimAtAngle sets target", function()
        local t = combat.newTurret(1, 2)
        t:aimAtAngle(1.5)
        expect_equal(t.target_angle, 1.5)
    end)

    it("clampToArc clamps angle", function()
        local t = combat.newTurret(1, 2)
        t.arc_min = -1.0
        t.arc_max = 1.0
        expect_equal(t:clampToArc(2.0), 1.0)
        expect_equal(t:clampToArc(-2.0), -1.0)
        expect_equal(t:clampToArc(0.5), 0.5)
    end)

    it("update returns angular velocity", function()
        local t = combat.newTurret(1, 2)
        t.turn_speed = 2.0
        t:aimAtAngle(1.0)
        local vel = t:update(0.1, 0)
        -- diff = 1.0, max_step = 0.2, diff > max_step → return turn_speed = 2.0
        expect_equal(vel, 2.0)
    end)

    it("update returns nil without target", function()
        local t = combat.newTurret(1, 2)
        expect_equal(t:update(0.1, 0), nil)
    end)
end)

-- ── Weapon ───────────────────────────────────────────────────────────────

describe("Weapon", function()
    it("new with defaults", function()
        local w = combat.newWeapon("Laser")
        expect_equal(w.name, "Laser")
        expect_equal(w.ammo, -1)
        expect_equal(w:canFire(), true)
    end)

    it("fire consumes ammo and sets cooldown", function()
        local w = combat.newWeapon("Gun")
        w.ammo = 5
        w.max_ammo = 10
        w.fire_rate = 2.0
        expect_equal(w:fire(0.016), true)
        expect_equal(w.ammo, 4)
        expect_equal(w:canFire(), false)  -- cooldown active
    end)

    it("updateCooldown reduces cooldown", function()
        local w = combat.newWeapon("Gun")
        w.cooldown_remaining = 0.5
        w:updateCooldown(0.3)
        expect_near(w.cooldown_remaining, 0.2, 0.001)
        w:updateCooldown(0.3)
        expect_equal(w.cooldown_remaining, 0)
    end)

    it("reload refills to max", function()
        local w = combat.newWeapon("Gun")
        w.ammo = 0
        w.max_ammo = 10
        w:reload()
        expect_equal(w.ammo, 10)
    end)

    it("reload with amount adds rounds", function()
        local w = combat.newWeapon("Gun")
        w.ammo = 3
        w.max_ammo = 10
        w:reload(5)
        expect_equal(w.ammo, 8)
    end)

    it("isOutOfAmmo with infinite ammo", function()
        local w = combat.newWeapon("Laser")
        expect_equal(w:isOutOfAmmo(), false)
    end)

    it("isOutOfAmmo with finite ammo", function()
        local w = combat.newWeapon("Gun")
        w.ammo = 0
        w.max_ammo = 5
        expect_equal(w:isOutOfAmmo(), true)
    end)

    it("startFiring and stopFiring", function()
        local w = combat.newWeapon("Gun")
        w:startFiring()
        expect_equal(w:isFiring(), true)
        w:stopFiring()
        expect_equal(w:isFiring(), false)
    end)
end)

-- ── ProjectilePool ───────────────────────────────────────────────────────

describe("ProjectilePool", function()
    it("new creates pool with free slots", function()
        local pool = combat.newProjectilePool(10)
        expect_equal(pool:freeCount(), 10)
        expect_equal(pool:activeCount(), 0)
    end)

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

    it("getActive returns active indices", function()
        local pool = combat.newProjectilePool(5)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        local active = pool:getActive()
        expect_equal(#active, 2)
    end)

    it("resetAll releases all", function()
        local pool = combat.newProjectilePool(5)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:resetAll()
        expect_equal(pool:activeCount(), 0)
        expect_equal(pool:freeCount(), 5)
    end)

    it("pool capped at MAX_POOL_SIZE", function()
        local pool = combat.newProjectilePool(9999)
        expect_equal(pool.pool_size, 1024)
    end)

    it("spawn returns nil when exhausted", function()
        local pool = combat.newProjectilePool(2)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        local idx = pool:spawn(0, 0, 0, 100, 10, "k", 500)
        expect_equal(idx, nil)
    end)

    it("get returns projectile data", function()
        local pool = combat.newProjectilePool(5)
        local idx = pool:spawn(0, 0, 0, 200, 25, "explosive", 800)
        local p = pool:get(idx)
        expect_equal(p.speed, 200)
        expect_equal(p.damage_amount, 25)
        expect_equal(p.damage_type, "explosive")
    end)
end)

-- ── CombatWorld ──────────────────────────────────────────────────────────

describe("CombatWorld", function()
    it("new creates empty world", function()
        local w = combat.newCombatWorld()
        expect_equal(#w.chassis_list, 0)
        expect_equal(#w.turrets, 0)
        expect_equal(#w.weapons, 0)
    end)

    it("add and get chassis", function()
        local w = combat.newCombatWorld()
        local c = combat.newChassis(1, 100)
        local idx = w:addChassis(c)
        expect_equal(idx, 1)
        expect_equal(w:getChassis(1).hp, 100)
    end)

    it("add and get turret", function()
        local w = combat.newCombatWorld()
        local idx = w:addTurret(combat.newTurret(1, 2))
        expect_equal(idx, 1)
        expect_equal(w:getTurret(1).body_id, 1)
    end)

    it("add and get weapon", function()
        local w = combat.newCombatWorld()
        local idx = w:addWeapon(combat.newWeapon("Cannon"))
        expect_equal(idx, 1)
        expect_equal(w:getWeapon(1).name, "Cannon")
    end)

    it("activeChassisCount excludes destroyed", function()
        local w = combat.newCombatWorld()
        w:addChassis(combat.newChassis(1, 100))
        local c2 = combat.newChassis(2, 50)
        c2:takeDamage(50)
        w:addChassis(c2)
        expect_equal(w:activeChassisCount(), 1)
    end)

    it("activeProjectileCount sums across pools", function()
        local w = combat.newCombatWorld()
        local pool = combat.newProjectilePool(10)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        pool:spawn(0, 0, 0, 100, 10, "k", 500)
        w:addPool(pool)
        expect_equal(w:activeProjectileCount(), 2)
    end)

    it("update ticks weapon cooldowns", function()
        local w = combat.newCombatWorld()
        local wpn = combat.newWeapon("Gun")
        wpn.cooldown_remaining = 1.0
        w:addWeapon(wpn)
        w:update(0.5)
        expect_near(w:getWeapon(1).cooldown_remaining, 0.5, 0.001)
    end)

    it("reset clears everything", function()
        local w = combat.newCombatWorld()
        w:addChassis(combat.newChassis(1, 100))
        w:addWeapon(combat.newWeapon("X"))
        w:reset()
        expect_equal(#w.chassis_list, 0)
        expect_equal(#w.weapons, 0)
    end)

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

-- ── Enums ────────────────────────────────────────────────────────────────

describe("Enums", function()
    it("ProjectileType has all variants", function()
        expect_equal(combat.ProjectileType.Ballistic, "ballistic")
        expect_equal(combat.ProjectileType.Homing, "homing")
        expect_equal(combat.ProjectileType.Ray, "ray")
        expect_equal(combat.ProjectileType.Area, "area")
        expect_equal(combat.ProjectileType.Beam, "beam")
    end)

    it("ArmorZone has all variants", function()
        expect_equal(combat.ArmorZone.Front, "front")
        expect_equal(combat.ArmorZone.Rear, "rear")
        expect_equal(combat.ArmorZone.Side, "side")
    end)
end)

test_summary()
