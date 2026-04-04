-- Entity module Lua tests
-- All tests are headless-safe

local world = luna.entity.newUniverse()

-- ============================================================
-- Spawn and lifecycle
-- ============================================================
local a = world:spawn()
assert(a == 1, "first entity should be 1")
local b = world:spawn()
assert(b == 2, "second entity should be 2")
assert(world:isAlive(a), "entity a should be alive")
assert(world:getEntityCount() == 2, "should have 2 entities")

world:kill(a)
assert(not world:isAlive(a), "entity a should be dead after kill")
assert(world:getEntityCount() == 1, "should have 1 entity")

-- LIFO recycling
local c = world:spawn()
assert(c == a, "should recycle ID from kill (LIFO)")

-- ============================================================
-- Components
-- ============================================================
local e = world:spawn()
world:set(e, "hp", 100)
assert(world:get(e, "hp") == 100, "component get/set")
assert(world:has(e, "hp"), "has component")

world:set(e, "name", "Hero")
assert(world:get(e, "name") == "Hero", "string component")

local comps = world:getComponents(e)
assert(type(comps) == "table", "getComponents returns table")

world:remove(e, "hp")
assert(not world:has(e, "hp"), "component removed")
assert(world:get(e, "hp") == nil, "removed component is nil")

-- ============================================================
-- Query
-- ============================================================
local p = world:spawn()
world:set(p, "pos", {x=0, y=0})
world:set(p, "vel", {x=1, y=0})

local q = world:spawn()
world:set(q, "pos", {x=5, y=5})

local both = world:query("pos", "vel")
assert(#both == 1, "query both should find 1")
assert(both[1] == p, "should be entity p")

local all_pos = world:query("pos")
assert(#all_pos == 2, "query pos should find 2")

-- each
local count = 0
world:each("pos", function(id, val)
    count = count + 1
end)
assert(count == 2, "each should iterate 2 entities")

-- ============================================================
-- String Tags
-- ============================================================
world:addTag(p, "player")
world:addTag(q, "enemy")
assert(world:hasTag(p, "player"), "tag set")
assert(not world:hasTag(p, "enemy"), "tag not set")

local tags = world:getTags(p)
assert(#tags == 1, "one tag")
assert(tags[1] == "player", "correct tag")

local enemies = world:getEntitiesByTag("enemy")
assert(#enemies == 1 and enemies[1] == q, "getEntitiesByTag")

world:removeTag(p, "player")
assert(not world:hasTag(p, "player"), "tag removed")

-- ============================================================
-- Bitmap Tags
-- ============================================================
local bit = world:defineTag("fast")
assert(type(bit) == "number", "defineTag returns number")

world:bitmapTag(p, "fast")
world:bitmapTag(p, "strong")
world:bitmapTag(q, "fast")

assert(world:hasBitmapTag(p, "fast"), "bitmap tag set")
assert(world:hasBitmapTag(p, "strong"), "bitmap tag set")
assert(not world:hasBitmapTag(q, "strong"), "bitmap tag not set")

local fast_ones = world:queryBitmapTag("fast")
assert(#fast_ones == 2, "two fast entities")

local both_tags = world:queryBitmapAll({"fast", "strong"})
assert(#both_tags == 1 and both_tags[1] == p, "queryBitmapAll")

local any_tags = world:queryBitmapAny({"fast", "strong"})
assert(#any_tags == 2, "queryBitmapAny")

-- ============================================================
-- Layers
-- ============================================================
world:setLayer(p, 2)
world:setLayer(q, 0)
assert(world:getLayer(p) == 2, "layer set")
assert(world:getLayer(q) == 0, "layer set")

local layer0 = world:getEntitiesByLayer(0)
assert(#layer0 >= 1, "entities on layer 0")

local sorted = world:getEntitiesSorted()
assert(#sorted >= 2, "sorted has entities")
-- q has layer 0, p has layer 2 → q should come first
local found_q = false
local found_p = false
for i, id in ipairs(sorted) do
    if id == q then found_q = true end
    if id == p then
        found_p = true
        assert(found_q, "q (layer 0) should come before p (layer 2)")
    end
end

-- ============================================================
-- Blueprints
-- ============================================================
world:defineBlueprint("goblin", { hp = 30, speed = 100 })
assert(world:hasBlueprint("goblin"), "blueprint defined")

local g = world:spawnBlueprint("goblin")
assert(world:isAlive(g), "blueprint entity alive")
assert(world:get(g, "hp") == 30, "blueprint hp")
assert(world:get(g, "speed") == 100, "blueprint speed")

-- Deep copy isolation
world:set(g, "hp", 999)
local g2 = world:spawnBlueprint("goblin")
assert(world:get(g2, "hp") == 30, "blueprint isolation")

-- Extend blueprint
world:extendBlueprint("boss_goblin", "goblin", { hp = 200, boss = true })
local bg = world:spawnBlueprint("boss_goblin")
assert(world:get(bg, "hp") == 200, "extended blueprint override")
assert(world:get(bg, "speed") == 100, "extended blueprint inherited")
assert(world:get(bg, "boss") == true, "extended blueprint new field")

-- Blueprint with overrides at spawn
local g3 = world:spawnBlueprint("goblin", { hp = 50 })
assert(world:get(g3, "hp") == 50, "spawn override")
assert(world:get(g3, "speed") == 100, "spawn non-overridden")

-- List blueprints
local bps = world:listBlueprints()
assert(#bps >= 2, "at least 2 blueprints")

-- Remove blueprint
world:removeBlueprint("boss_goblin")
assert(not world:hasBlueprint("boss_goblin"), "blueprint removed")

-- Get blueprint components
local bp_comps = world:getBlueprintComponents("goblin")
assert(bp_comps ~= nil, "getBlueprintComponents returns table")
assert(bp_comps.hp == 30, "blueprint component value")

-- ============================================================
-- Systems
-- ============================================================
local update_count = 0
local draw_count = 0

local TestSys = {}
function TestSys:update(w, dt)
    update_count = update_count + 1
end
function TestSys:draw(w)
    draw_count = draw_count + 1
end

world:addSystem(TestSys)
assert(world:getSystemCount() == 1, "one system")

world:update(0.016)
assert(update_count == 1, "update called")

world:draw()
assert(draw_count == 1, "draw called")

-- Emit custom event
local custom_count = 0
local EventSys = {}
function EventSys:onHit(w, damage)
    custom_count = damage
end
world:addSystem(EventSys)
world:emit("onHit", 42)
assert(custom_count == 42, "emit custom event")

-- Remove system
world:removeSystem(TestSys)
assert(world:getSystemCount() == 1, "one system after remove")

-- ============================================================
-- Clear and Release
-- ============================================================
world:defineBlueprint("preserved", { val = 1 })
world:clear()
assert(world:getEntityCount() == 0, "cleared entities")
assert(world:hasBlueprint("preserved"), "blueprints preserved after clear")

print("All entity tests passed!")
