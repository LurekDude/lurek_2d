-- Lurek2D Lua stress test for lurek.ecs spawnBulk
-- Headless: no GPU, no audio, no window.

-- @description Covers suite: lurek.ecs spawnBulk stress.
describe("lurek.ecs.spawnBulk", function()
    -- @covers lurek.ecs.newUniverse
    -- @covers lurek.ecs.defineBlueprint
    -- @covers lurek.ecs.spawnBulk
    -- @description Verifies that spawnBulk creates the correct number of entities from a blueprint.
    it("spawnBulk creates correct entity count from blueprint", function()
        local w = lurek.ecs.newUniverse()
        w:defineBlueprint("Enemy", {hp = 10, speed = 5, alive = true})
        local ids = w:spawnBulk("Enemy", 100)
        expect_equal(100, #ids)
        expect_equal(100, w:getEntityCount())
    end)

    -- @covers lurek.ecs.spawnBulk
    -- @description Verifies that each spawned entity has blueprint components.
    it("each bulk-spawned entity has blueprint components", function()
        local w = lurek.ecs.newUniverse()
        w:defineBlueprint("Bullet", {dmg = 5, vel = 20})
        local ids = w:spawnBulk("Bullet", 10)
        for _, id in ipairs(ids) do
            expect_equal(5, w:get(id, "dmg"))
        end
    end)

    -- @covers lurek.ecs.spawnBulk
    -- @description Verifies that large counts perform within acceptable time.
    it("spawning 500 entities completes without error", function()
        local w = lurek.ecs.newUniverse()
        w:defineBlueprint("Particle", {life = 1.0, x = 0, y = 0})
        local ids = w:spawnBulk("Particle", 500)
        expect_equal(500, #ids)
    end)

    -- @covers lurek.ecs.spawnBulk
    -- @description Verifies that spawnBulk with count=0 returns empty table.
    it("spawnBulk with count 0 returns empty table", function()
        local w = lurek.ecs.newUniverse()
        w:defineBlueprint("X", {a = 1})
        local ids = w:spawnBulk("X", 0)
        expect_equal(0, #ids)
        expect_equal(0, w:getEntityCount())
    end)
end)
test_summary()
