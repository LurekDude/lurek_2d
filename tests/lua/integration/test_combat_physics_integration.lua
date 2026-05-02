-- Integration test: library.combat    lurek.physics.
--
-- Scope: Pairs combat Chassis (HP, armour, friendly-fire group masks) with
-- the lurek.physics rigid-body world. Each combatant owns a physics Body
-- whose position is queried via `lurek.physics.getBody`; combat resolves
-- "in-range" targets, sorts them by distance, applies CollisionGroupSet
-- friendly-fire filtering, and calls `Chassis:takeDamage` on survivors.
--
-- Fallback: `lurek.physics.newWorld(gx, gy)` is fully headless (no GPU /
-- window required     see tests/lua/unit/test_physics.lua). However, raycast
-- and shapecast resolve against attached colliders and the flat
-- `lurek.physics.newBody` wrapper does NOT attach a collider by default.
-- This test therefore uses position-based range queries via
-- `lurek.physics.getBody` rather than `World:raycastAll`. The combat side
-- of the integration (Chassis HP/armour, CollisionGroupSet masks) is the
-- focus; the physics side provides authoritative body positions.
--

local combat = require("library.combat")

local function make_target(world, x, y, hp, group_bit)
    local body = lurek.physics.newBody(world, x, y, "dynamic")
    -- newChassis expects a numeric body_id; LuaBody:getId() returns the integer handle
    local chassis = combat.newChassis(body:getId(), hp)
    chassis.group = group_bit
    return { body = body, chassis = chassis }
end

local function dist_sq(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    return dx * dx + dy * dy
end

-- Resolve all targets within `range` of (sx, sy) sorted nearest-first.
-- Filters by collision-group bitmask: targets whose `group` AND `mask` is
-- nonzero are eligible (friendly-fire toggle is encoded in `mask`).
local function resolve_targets(world, targets, sx, sy, range, mask)
    local out = {}
    local r2 = range * range
    for _, t in ipairs(targets) do
        local x, y = lurek.physics.getBody(world, t.body)
        local d2 = dist_sq(sx, sy, x, y)
        if d2 <= r2 and (t.chassis.group % (mask + 1)) > 0 then
            -- bitwise AND emulation: works because group bits are powers of two
            -- and we test a single bit per target.
            local hit = false
            local g, m = t.chassis.group, mask
            while g > 0 do
                if g % 2 == 1 and m % 2 == 1 then hit = true; break end
                g = math.floor(g / 2); m = math.floor(m / 2)
            end
            if hit then out[#out + 1] = { target = t, d2 = d2 } end
        end
    end
    table.sort(out, function(a, b) return a.d2 < b.d2 end)
    return out
end

describe("integration: library.combat    lurek.physics", function()

    it("damage is applied to a chassis whose physics body is in range", function()
        local world = lurek.physics.newWorld(0, 0)
        local cgs = combat.newCollisionGroupSet()
        local enemy_bit = cgs:defineGroup("enemies")

        local t = make_target(world, 10, 0, 100, enemy_bit)
        local hits = resolve_targets(world, { t }, 0, 0, 20, enemy_bit)

        expect_equal(1, #hits)
        hits[1].target.chassis:takeDamage(25)
        expect_equal(75, t.chassis.hp)
    end)

    it("no-op when the only target is outside attack range", function()
        local world = lurek.physics.newWorld(0, 0)
        local cgs = combat.newCollisionGroupSet()
        local enemy_bit = cgs:defineGroup("enemies")

        local t = make_target(world, 100, 0, 100, enemy_bit)
        local hits = resolve_targets(world, { t }, 0, 0, 5, enemy_bit)
        expect_equal(0, #hits)
        expect_equal(100, t.chassis.hp)
    end)

    it("multiple targets are sorted nearest-first", function()
        local world = lurek.physics.newWorld(0, 0)
        local cgs = combat.newCollisionGroupSet()
        local enemy_bit = cgs:defineGroup("enemies")

        local far  = make_target(world, 8, 0, 100, enemy_bit)
        local near = make_target(world, 2, 0, 100, enemy_bit)
        local mid  = make_target(world, 5, 0, 100, enemy_bit)

        local hits = resolve_targets(world, { far, near, mid }, 0, 0, 20, enemy_bit)
        expect_equal(3, #hits)
        expect_near(4.0,  hits[1].d2, 1e-5)
        expect_near(25.0, hits[2].d2, 1e-5)
        expect_near(64.0, hits[3].d2, 1e-5)
        expect_equal(near, hits[1].target)
        expect_equal(mid,  hits[2].target)
        expect_equal(far,  hits[3].target)
    end)

    -- a player chassis at point-blank range receives no damage.
    it("friendly-fire OFF spares same-group chassis", function()
        local world = lurek.physics.newWorld(0, 0)
        local cgs = combat.newCollisionGroupSet()
        local player_bit = cgs:defineGroup("players")
        local enemy_bit  = cgs:defineGroup("enemies")

        local ally  = make_target(world, 1, 0, 100, player_bit)
        local enemy = make_target(world, 2, 0, 100, enemy_bit)

        -- Attack mask hits only enemies (friendly-fire OFF).
        local hits = resolve_targets(world, { ally, enemy }, 0, 0, 20, enemy_bit)
        expect_equal(1, #hits)
        expect_equal(enemy, hits[1].target)
    end)

    it("friendly-fire ON includes same-group chassis", function()
        local world = lurek.physics.newWorld(0, 0)
        local cgs = combat.newCollisionGroupSet()
        local player_bit = cgs:defineGroup("players")
        local enemy_bit  = cgs:defineGroup("enemies")

        local ally  = make_target(world, 1, 0, 100, player_bit)
        local enemy = make_target(world, 2, 0, 100, enemy_bit)

        local hits = resolve_targets(world, { ally, enemy }, 0, 0, 20,
            player_bit + enemy_bit)
        expect_equal(2, #hits)
    end)

    it("physics.step rejects a non-numeric dt", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_error(function()
            lurek.physics.step(world, "not a number")
        end)
    end)

end)




-- ================================================================
-- Merged from: test_integration_combat_physics.lua
-- ================================================================

-- Integration test: library.combat    lurek.physics.
--
-- Scope: Pairs combat Chassis (HP, armour, friendly-fire group masks) with
-- the lurek.physics rigid-body world. Each combatant owns a physics Body
-- whose position is queried via `lurek.physics.getBody`; combat resolves
-- "in-range" targets, sorts them by distance, applies CollisionGroupSet
-- friendly-fire filtering, and calls `Chassis:takeDamage` on survivors.
--
-- Fallback: `lurek.physics.newWorld(gx, gy)` is fully headless (no GPU /
-- window required     see tests/lua/unit/test_physics.lua). However, raycast
-- and shapecast resolve against attached colliders and the flat
-- `lurek.physics.newBody` wrapper does NOT attach a collider by default.
-- This test therefore uses position-based range queries via
-- `lurek.physics.getBody` rather than `World:raycastAll`. The combat side
-- of the integration (Chassis HP/armour, CollisionGroupSet masks) is the
-- focus; the physics side provides authoritative body positions.
--

local combat = require("library.combat")

local function make_target(world, x, y, hp, group_bit)
    local body = lurek.physics.newBody(world, x, y, "dynamic")
    local chassis = combat.newChassis(body:getId(), hp)
    chassis.group = group_bit
    return { body = body, chassis = chassis }
end

local function dist_sq(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    return dx * dx + dy * dy
end

-- Resolve all targets within `range` of (sx, sy) sorted nearest-first.
-- Filters by collision-group bitmask: targets whose `group` AND `mask` is
-- nonzero are eligible (friendly-fire toggle is encoded in `mask`).
local function resolve_targets(world, targets, sx, sy, range, mask)
    local out = {}
    local r2 = range * range
    for _, t in ipairs(targets) do
        local x, y = lurek.physics.getBody(world, t.body)
        local d2 = dist_sq(sx, sy, x, y)
        if d2 <= r2 and (t.chassis.group % (mask + 1)) > 0 then
            -- bitwise AND emulation: works because group bits are powers of two
            -- and we test a single bit per target.
            local hit = false
            local g, m = t.chassis.group, mask
            while g > 0 do
                if g % 2 == 1 and m % 2 == 1 then hit = true; break end
                g = math.floor(g / 2); m = math.floor(m / 2)
            end
            if hit then out[#out + 1] = { target = t, d2 = d2 } end
        end
    end
    table.sort(out, function(a, b) return a.d2 < b.d2 end)
    return out
end

describe("integration: library.combat    lurek.physics", function()

    it("damage is applied to a chassis whose physics body is in range", function()
        local world = lurek.physics.newWorld(0, 0)
        local cgs = combat.newCollisionGroupSet()
        local enemy_bit = cgs:defineGroup("enemies")

        local t = make_target(world, 10, 0, 100, enemy_bit)
        local hits = resolve_targets(world, { t }, 0, 0, 20, enemy_bit)

        expect_equal(1, #hits)
        hits[1].target.chassis:takeDamage(25)
        expect_equal(75, t.chassis.hp)
    end)

    it("no-op when the only target is outside attack range", function()
        local world = lurek.physics.newWorld(0, 0)
        local cgs = combat.newCollisionGroupSet()
        local enemy_bit = cgs:defineGroup("enemies")

        local t = make_target(world, 100, 0, 100, enemy_bit)
        local hits = resolve_targets(world, { t }, 0, 0, 5, enemy_bit)
        expect_equal(0, #hits)
        expect_equal(100, t.chassis.hp)
    end)

    it("multiple targets are sorted nearest-first", function()
        local world = lurek.physics.newWorld(0, 0)
        local cgs = combat.newCollisionGroupSet()
        local enemy_bit = cgs:defineGroup("enemies")

        local far  = make_target(world, 8, 0, 100, enemy_bit)
        local near = make_target(world, 2, 0, 100, enemy_bit)
        local mid  = make_target(world, 5, 0, 100, enemy_bit)

        local hits = resolve_targets(world, { far, near, mid }, 0, 0, 20, enemy_bit)
        expect_equal(3, #hits)
        expect_near(4.0,  hits[1].d2, 1e-5)
        expect_near(25.0, hits[2].d2, 1e-5)
        expect_near(64.0, hits[3].d2, 1e-5)
        expect_equal(near, hits[1].target)
        expect_equal(mid,  hits[2].target)
        expect_equal(far,  hits[3].target)
    end)

    -- a player chassis at point-blank range receives no damage.
    it("friendly-fire OFF spares same-group chassis", function()
        local world = lurek.physics.newWorld(0, 0)
        local cgs = combat.newCollisionGroupSet()
        local player_bit = cgs:defineGroup("players")
        local enemy_bit  = cgs:defineGroup("enemies")

        local ally  = make_target(world, 1, 0, 100, player_bit)
        local enemy = make_target(world, 2, 0, 100, enemy_bit)

        -- Attack mask hits only enemies (friendly-fire OFF).
        local hits = resolve_targets(world, { ally, enemy }, 0, 0, 20, enemy_bit)
        expect_equal(1, #hits)
        expect_equal(enemy, hits[1].target)
    end)

    it("friendly-fire ON includes same-group chassis", function()
        local world = lurek.physics.newWorld(0, 0)
        local cgs = combat.newCollisionGroupSet()
        local player_bit = cgs:defineGroup("players")
        local enemy_bit  = cgs:defineGroup("enemies")

        local ally  = make_target(world, 1, 0, 100, player_bit)
        local enemy = make_target(world, 2, 0, 100, enemy_bit)

        local hits = resolve_targets(world, { ally, enemy }, 0, 0, 20,
            player_bit + enemy_bit)
        expect_equal(2, #hits)
    end)

    it("physics.step rejects a non-numeric dt", function()
        local world = lurek.physics.newWorld(0, 0)
        expect_error(function()
            lurek.physics.step(world, "not a number")
        end)
    end)

end)
test_summary()
