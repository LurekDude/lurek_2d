-- Entity module Lua tests
-- Headless-safe. Each describe block creates a fresh Universe.

describe("Spawn and lifecycle", function()
    -- @covers Universe:spawn
    -- @covers Universe:kill
    -- @covers Universe:isAlive
    -- @covers Universe:getEntityCount
    it("spawns entities with sequential IDs", function()
        local world = lurek.ecs.newUniverse()
        local a = world:spawn()
        expect_equal(1, a)
        local b = world:spawn()
        expect_equal(2, b)
        expect_true(world:isAlive(a))
        expect_equal(2, world:getEntityCount())

        world:kill(a)
        expect_false(world:isAlive(a))
        expect_equal(1, world:getEntityCount())

        -- LIFO recycling: recycled slot gets incremented generation (stale detection)
        local c = world:spawn()
        expect_true(world:isAlive(c), "recycled entity is alive")
        expect_true(c ~= a, "recycled id differs from stale id (generational)")
    end)
end)

describe("Components", function()
    -- @covers Universe:get
    -- @covers Universe:has
    -- @covers Universe:remove
    -- @covers Universe:getComponents
    it("stores and retrieves component values", function()
        local world = lurek.ecs.newUniverse()
        local e = world:spawn()

        world:set(e, "hp", 100)
        expect_equal(100, world:get(e, "hp"))
        expect_true(world:has(e, "hp"))

        world:set(e, "name", "Hero")
        expect_equal("Hero", world:get(e, "name"))

        local comps = world:getComponents(e)
        expect_type("table", comps)

        world:remove(e, "hp")
        expect_false(world:has(e, "hp"))
        expect_equal(nil, world:get(e, "hp"))
    end)
end)

describe("Query", function()
    it("queries entities by components", function()
        local world = lurek.ecs.newUniverse()
        local p = world:spawn()
        world:set(p, "pos", {x=0, y=0})
        world:set(p, "vel", {x=1, y=0})

        local q = world:spawn()
        world:set(q, "pos", {x=5, y=5})

        local both = world:query("pos", "vel")
        expect_equal(1, #both)
        expect_equal(p, both[1])

        local all_pos = world:query("pos")
        expect_equal(2, #all_pos)
    end)

    it("iterates matching entities with each()", function()
        local world = lurek.ecs.newUniverse()
        local p = world:spawn()
        world:set(p, "pos", {x=0, y=0})
        local q = world:spawn()
        world:set(q, "pos", {x=5, y=5})

        local count = 0
        world:each("pos", function(id, val)
            count = count + 1
        end)
        expect_equal(2, count)
    end)
end)

describe("String Tags", function()
    -- @covers Universe:addTag
    -- @covers Universe:removeTag
    -- @covers Universe:hasTag
    -- @covers Universe:getTags
    -- @covers Universe:getEntitiesByTag
    it("adds, queries, and removes string tags", function()
        local world = lurek.ecs.newUniverse()
        local p = world:spawn()
        local q = world:spawn()

        world:addTag(p, "player")
        world:addTag(q, "enemy")

        expect_true(world:hasTag(p, "player"))
        expect_false(world:hasTag(p, "enemy"))

        local tags = world:getTags(p)
        expect_equal(1, #tags)
        expect_equal("player", tags[1])

        local enemies = world:getEntitiesByTag("enemy")
        expect_equal(1, #enemies)
        expect_equal(q, enemies[1])

        world:removeTag(p, "player")
        expect_false(world:hasTag(p, "player"))
    end)
end)

describe("Bitmap Tags", function()
    -- @covers Universe:defineTag
    -- @covers Universe:bitmapTag
    -- @covers Universe:bitmapUntag
    -- @covers Universe:hasBitmapTag
    -- @covers Universe:queryBitmapTag
    -- @covers Universe:queryBitmapAny
    -- @covers Universe:queryBitmapAll
    -- @covers Universe:getBitmapTagBit
    it("defines and queries bitmap tags", function()
        local world = lurek.ecs.newUniverse()
        local p = world:spawn()
        local q = world:spawn()

        local bit = world:defineTag("fast")
        expect_type("number", bit)

        world:bitmapTag(p, "fast")
        world:bitmapTag(p, "strong")
        world:bitmapTag(q, "fast")

        expect_true(world:hasBitmapTag(p, "fast"))
        expect_true(world:hasBitmapTag(p, "strong"))
        expect_false(world:hasBitmapTag(q, "strong"))

        local fast_ones = world:queryBitmapTag("fast")
        expect_equal(2, #fast_ones)

        local both_tags = world:queryBitmapAll({"fast", "strong"})
        expect_equal(1, #both_tags)
        expect_equal(p, both_tags[1])

        local any_tags = world:queryBitmapAny({"fast", "strong"})
        expect_equal(2, #any_tags)
    end)

    it("removes bitmap tags with bitmapUntag", function()
        local world = lurek.ecs.newUniverse()
        local entity = world:spawn()

        world:bitmapTag(entity, "fast")
        world:bitmapTag(entity, "strong")
        expect_true(world:hasBitmapTag(entity, "strong"))

        world:bitmapUntag(entity, "strong")

        expect_false(world:hasBitmapTag(entity, "strong"))
        expect_true(world:hasBitmapTag(entity, "fast"))
    end)
end)

describe("Layers", function()
    -- @covers Universe:setLayer
    -- @covers Universe:getLayer
    -- @covers Universe:getEntitiesByLayer
    -- @covers Universe:getEntitiesSorted
    it("assigns layers and returns entities sorted by layer", function()
        local world = lurek.ecs.newUniverse()
        local p = world:spawn()
        local q = world:spawn()

        expect_equal(0, world:getLayer(p))
        expect_equal(0, world:getLayer(q))

        world:setLayer(p, 2)
        expect_equal(2, world:getLayer(p))
        expect_equal(0, world:getLayer(q))

        local layer0 = world:getEntitiesByLayer(0)
        expect_true(#layer0 >= 1)

        local sorted = world:getEntitiesSorted()
        expect_true(#sorted >= 2)

        -- q has layer 0, p has layer 2 -> q must come first
        local found_q = false
        for i, id in ipairs(sorted) do
            if id == q then found_q = true end
            if id == p then
                expect_true(found_q)
            end
        end
    end)
end)

describe("Blueprints", function()
    it("defines blueprints and spawns entities from them", function()
        local world = lurek.ecs.newUniverse()
        world:defineBlueprint("goblin", { hp = 30, speed = 100 })
        expect_true(world:hasBlueprint("goblin"))

        local g = world:spawnBlueprint("goblin")
        expect_true(world:isAlive(g))
        expect_equal(30, world:get(g, "hp"))
        expect_equal(100, world:get(g, "speed"))
    end)

    it("blueprints provide deep-copy isolation", function()
        local world = lurek.ecs.newUniverse()
        world:defineBlueprint("goblin", { hp = 30, speed = 100 })

        local g = world:spawnBlueprint("goblin")
        world:set(g, "hp", 999)
        local g2 = world:spawnBlueprint("goblin")
        expect_equal(30, world:get(g2, "hp"))
    end)

    it("extends blueprints with overrides", function()
        local world = lurek.ecs.newUniverse()
        world:defineBlueprint("goblin", { hp = 30, speed = 100 })
        world:extendBlueprint("boss_goblin", "goblin", { hp = 200, boss = true })

        local bg = world:spawnBlueprint("boss_goblin")
        expect_equal(200, world:get(bg, "hp"))
        expect_equal(100, world:get(bg, "speed"))
        expect_equal(true, world:get(bg, "boss"))
    end)

    it("spawnBlueprint accepts per-spawn field overrides", function()
        local world = lurek.ecs.newUniverse()
        world:defineBlueprint("goblin", { hp = 30, speed = 100 })

        local g = world:spawnBlueprint("goblin", { hp = 50 })
        expect_equal(50, world:get(g, "hp"))
        expect_equal(100, world:get(g, "speed"))
    end)

    it("lists and removes blueprints", function()
        local world = lurek.ecs.newUniverse()
        world:defineBlueprint("goblin", { hp = 30 })
        world:defineBlueprint("boss", { hp = 200 })

        local bps = world:listBlueprints()
        expect_true(#bps >= 2)

        world:removeBlueprint("boss")
        expect_false(world:hasBlueprint("boss"))
    end)

    it("getBlueprintComponents returns component table", function()
        local world = lurek.ecs.newUniverse()
        world:defineBlueprint("goblin", { hp = 30 })

        local bp_comps = world:getBlueprintComponents("goblin")
        expect_true(bp_comps ~= nil)
        expect_equal(30, bp_comps.hp)
    end)
end)

describe("Systems", function()
    it("dispatches update and draw to registered systems", function()
        local world = lurek.ecs.newUniverse()
        local update_count = 0
        local draw_count = 0

        local TestSys = {}
        function TestSys:update(w, dt) update_count = update_count + 1 end
        function TestSys:draw(w) draw_count = draw_count + 1 end

        world:addSystem(TestSys)
        expect_equal(1, world:getSystemCount())

        world:update(0.016)
        expect_equal(1, update_count)

        world:emit("draw")
        expect_equal(1, draw_count)
    end)

    it("emits custom events to systems", function()
        local world = lurek.ecs.newUniverse()
        local custom_count = 0

        local EventSys = {}
        function EventSys:onHit(w, damage) custom_count = damage end
        world:addSystem(EventSys)

        world:emit("onHit", 42)
        expect_equal(42, custom_count)
    end)

    it("removeSystem removes by reference", function()
        local world = lurek.ecs.newUniverse()

        local SysA = {}
        function SysA:update() end
        local SysB = {}
        function SysB:update() end

        world:addSystem(SysA)
        world:addSystem(SysB)
        expect_equal(2, world:getSystemCount())

        world:removeSystem(SysA)
        expect_equal(1, world:getSystemCount())
    end)
end)

describe("Clear and Release", function()
    it("clear() removes entities but preserves blueprints", function()
        local world = lurek.ecs.newUniverse()
        world:spawn()
        world:spawn()
        world:defineBlueprint("preserved", { val = 1 })

        world:clear()
        expect_equal(0, world:getEntityCount())
        expect_true(world:hasBlueprint("preserved"))
    end)
end)

-- parent-child hierarchy

describe("parent-child hierarchy", function()
    -- @covers Universe:setParent
    -- @covers Universe:getParent
    -- @covers Universe:getChildren
    -- @covers Universe:killRecursive
    it("setParent / getParent round-trip", function()
        local world = lurek.ecs.newUniverse()
        local parent = world:spawn()
        local child  = world:spawn()
        world:setParent(child, parent)
        expect_equal(parent, world:getParent(child))
    end)

    it("getParent returns nil for entity with no parent", function()
        local world = lurek.ecs.newUniverse()
        local e = world:spawn()
        expect_nil(world:getParent(e))
    end)

    it("getChildren returns table containing child", function()
        local world = lurek.ecs.newUniverse()
        local parent = world:spawn()
        local child  = world:spawn()
        world:setParent(child, parent)
        local children = world:getChildren(parent)
        expect_type("table", children)
        local found = false
        for _, id in ipairs(children) do
            if id == child then found = true end
        end
        expect_true(found, "child id should appear in getChildren")
    end)

    it("getChildren returns empty table when no children attached", function()
        local world = lurek.ecs.newUniverse()
        local e = world:spawn()
        local children = world:getChildren(e)
        expect_type("table", children)
        expect_equal(0, #children)
    end)

    it("setParent accepts nil to detach a child", function()
        local world = lurek.ecs.newUniverse()
        local parent = world:spawn()
        local child = world:spawn()

        world:setParent(child, parent)
        world:setParent(child, nil)

        expect_nil(world:getParent(child))
        expect_equal(0, #world:getChildren(parent))
    end)

    it("killRecursive kills parent and all children", function()
        local world = lurek.ecs.newUniverse()
        local parent = world:spawn()
        local child1 = world:spawn()
        local child2 = world:spawn()
        world:setParent(child1, parent)
        world:setParent(child2, parent)
        world:killRecursive(parent)
        expect_false(world:isAlive(parent))
        expect_false(world:isAlive(child1))
        expect_false(world:isAlive(child2))
    end)
end)

-- getEntities

describe("World.getEntities", function()
    -- @covers Universe:getEntities
    it("getEntities returns a table", function()
        local world = lurek.ecs.newUniverse()
        local result = world:getEntities()
        expect_type("table", result)
    end)

    it("getEntities includes spawned entities", function()
        local world = lurek.ecs.newUniverse()
        local e1 = world:spawn()
        local e2 = world:spawn()
        local all = world:getEntities()
        local found_e1, found_e2 = false, false
        for _, id in ipairs(all) do
            if id == e1 then found_e1 = true end
            if id == e2 then found_e2 = true end
        end
        expect_true(found_e1, "e1 in getEntities")
        expect_true(found_e2, "e2 in getEntities")
    end)

    it("getEntities does not include killed entities", function()
        local world = lurek.ecs.newUniverse()
        local e = world:spawn()
        world:kill(e)
        local all = world:getEntities()
        local found = false
        for _, id in ipairs(all) do
            if id == e then found = true end
        end
        expect_false(found, "killed entity should not appear in getEntities")
    end)
end)

-- getBitmapTagBit

describe("World.getBitmapTagBit", function()
    it("getBitmapTagBit returns a number for a defined tag", function()
        local world = lurek.ecs.newUniverse()
        world:defineTag("collidable")
        local bit = world:getBitmapTagBit("collidable")
        expect_type("number", bit)
    end)
end)

--  component observers (merged from test_entity_observers.lua) 

describe("lurek.ecs", function()
    describe("component observers", function()
        -- @covers lurek.ecs.newUniverse
        -- @covers lurek.ecs.onComponentAdded
        -- @covers lurek.ecs.flushObservers
        it("onComponentAdded fires after flushObservers", function()
            local w = lurek.ecs.newUniverse()
            local fired = 0
            local last_id = nil
            local last_name = nil
            w:onComponentAdded("hp", function(id, name)
                fired = fired + 1
                last_id = id
                last_name = name
            end)
            local e = w:spawn()
            w:set(e, "hp", 100)
            expect_equal(0, fired) -- not fired yet
            w:flushObservers()
            expect_equal(1, fired)
            expect_equal(e, last_id)
            expect_equal("hp", last_name)
        end)

        -- @covers lurek.ecs.onComponentRemoved
        -- @covers lurek.ecs.flushObservers
        it("onComponentRemoved fires after flushObservers", function()
            local w = lurek.ecs.newUniverse()
            local fired = 0
            w:onComponentRemoved("hp", function(id, name)
                fired = fired + 1
            end)
            local e = w:spawn()
            w:set(e, "hp", 50)
            w:flushObservers()   -- consume add event
            w:remove(e, "hp")
            expect_equal(0, fired) -- not yet
            w:flushObservers()
            expect_equal(1, fired)
        end)

        -- @covers lurek.ecs.onComponentAdded
        it("removing absent component does not fire remove event", function()
            local w = lurek.ecs.newUniverse()
            local fired = 0
            w:onComponentRemoved("hp", function() fired = fired + 1 end)
            local e = w:spawn()
            -- hp never set
            w:remove(e, "hp")
            w:flushObservers()
            expect_equal(0, fired)
        end)

        -- @covers lurek.ecs.onComponentAdded
        it("multiple observers on same component all fire", function()
            local w = lurek.ecs.newUniverse()
            local count = 0
            w:onComponentAdded("pos", function() count = count + 1 end)
            w:onComponentAdded("pos", function() count = count + 1 end)
            local e = w:spawn()
            w:set(e, "pos", {x=0,y=0})
            w:flushObservers()
            expect_equal(2, count)
        end)
    end)
end)

--  queryNot (merged from test_entity_query_not.lua) 

describe("lurek.ecs", function()
    describe("queryNot", function()
        -- @covers lurek.ecs.newUniverse
        -- @covers lurek.ecs.queryNot
        it("returns entities that have required and NOT excluded components", function()
            local w = lurek.ecs.newUniverse()
            local e1 = w:spawn()
            local e2 = w:spawn()
            local e3 = w:spawn()
            w:set(e1, "Health", {hp = 100})
            w:set(e1, "Visible", true)
            w:set(e2, "Health", {hp = 50})
            -- e3 has no components
            -- queryNot: has Health, does NOT have Visible
            local res = w:queryNot({"Health"}, {"Visible"})
            expect_equal(1, #res)
            expect_equal(e2, res[1])
        end)

        -- @covers lurek.ecs.queryNot
        it("empty without-list behaves like query", function()
            local w = lurek.ecs.newUniverse()
            local e1 = w:spawn()
            local e2 = w:spawn()
            w:set(e1, "Speed", 5)
            w:set(e2, "Speed", 10)
            local res = w:queryNot({"Speed"}, {})
            expect_equal(2, #res)
        end)

        -- @covers lurek.ecs.queryNot
        it("empty with-list returns all entities without excluded component", function()
            local w = lurek.ecs.newUniverse()
            local e1 = w:spawn()
            local e2 = w:spawn()
            local e3 = w:spawn()
            w:set(e1, "Invisible", true)
            -- e2, e3 have no Invisible component
            local res = w:queryNot({}, {"Invisible"})
            -- e2 and e3 should appear
            expect_equal(2, #res)
        end)

        -- @covers lurek.ecs.queryNot
        it("excludes entities with any of the excluded components", function()
            local w = lurek.ecs.newUniverse()
            local e1 = w:spawn()
            local e2 = w:spawn()
            local e3 = w:spawn()
            w:set(e1, "Health", 10)
            w:set(e2, "Health", 10)
            w:set(e2, "Dead", true)
            w:set(e3, "Health", 10)
            w:set(e3, "Frozen", true)
            local res = w:queryNot({"Health"}, {"Dead", "Frozen"})
            expect_equal(1, #res)
            expect_equal(e1, res[1])
        end)
    end)
end)

--  relationships (merged from test_entity_relationships.lua) 

describe("lurek.patterns.RelationshipManager", function()
    -- @covers lurek.patterns.RelationshipManager.getValue
    it("getValue defaults to zero for unknown pairs", function()
        local rm = lurek.patterns.newRelationshipManager()
        expect_near(0.0, rm:getValue(1, 2), 1e-5)
    end)

    -- @covers lurek.patterns.newRelationshipManager
    -- @covers lurek.patterns.RelationshipManager.setValue
    -- @covers lurek.patterns.RelationshipManager.getValue
    it("stores and retrieves numeric values between entity pairs", function()
        local rm = lurek.patterns.newRelationshipManager()
        local a, b = 1, 2
        rm:setValue(a, b, 75.0)
        expect_near(75.0, rm:getValue(a, b), 1e-5)
    end)

    -- @covers lurek.patterns.RelationshipManager.adjustValue
    it("adjustValue changes the value by delta", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:setValue(1, 2, 50.0)
        rm:adjustValue(1, 2, -10.0)
        expect_near(40.0, rm:getValue(1, 2), 1e-5)
    end)

    -- @covers lurek.patterns.RelationshipManager.defineType
    -- @covers lurek.patterns.RelationshipManager.setLevel
    -- @covers lurek.patterns.RelationshipManager.getLevel
    it("supports named relationship type levels", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Faction", {"enemy", "neutral", "ally"}, "neutral")
        local ok = rm:setLevel(1, 2, "Faction", "ally")
        expect_equal(true, ok)
        expect_equal("ally", rm:getLevel(1, 2, "Faction"))
    end)

    -- @covers lurek.patterns.RelationshipManager.setLevel
    it("setLevel returns false for unknown type", function()
        local rm = lurek.patterns.newRelationshipManager()
        expect_equal(false, rm:setLevel(1, 2, "Unknown", "ally"))
    end)

    -- @covers lurek.patterns.RelationshipManager.setLevel
    it("setLevel returns false for invalid level", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Faction", {"enemy", "ally"}, "ally")
        expect_equal(false, rm:setLevel(1, 2, "Faction", "neutral"))
    end)

    -- @covers lurek.patterns.RelationshipManager.getLevel
    it("getLevel returns default when unset", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Faction", {"enemy", "neutral", "ally"}, "neutral")
        expect_equal("neutral", rm:getLevel(1, 2, "Faction"))
    end)

    -- @covers lurek.patterns.RelationshipManager.removePair
    -- @covers lurek.patterns.RelationshipManager.pairCount
    it("removePair resets to defaults and decrements pairCount", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:setValue(1, 2, 100.0)
        expect_equal(1, rm:pairCount())
        rm:removePair(1, 2)
        expect_equal(0, rm:pairCount())
        expect_near(0.0, rm:getValue(1, 2), 1e-5)
    end)

    -- @covers lurek.patterns.RelationshipManager.pairCount
    it("pairCount tracks stored pairs", function()
        local rm = lurek.patterns.newRelationshipManager()
        expect_equal(0, rm:pairCount())
        rm:setValue(1, 2, 5.0)
        expect_equal(1, rm:pairCount())
    end)

    -- @covers lurek.patterns.RelationshipManager.typeNames
    it("typeNames returns all defined type names", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Friendship", {"stranger","friend","bestfriend"})
        rm:defineType("Faction", {"enemy","ally"})
        local names = rm:typeNames()
        expect_equal(2, #names)
    end)

    -- @covers lurek.patterns.RelationshipManager.removeType
    it("removeType removes the relationship type", function()
        local rm = lurek.patterns.newRelationshipManager()
        rm:defineType("Mood", {"happy", "sad"}, "happy")
        rm:removeType("Mood")
        local names = rm:typeNames()
        expect_equal(0, #names)
        expect_equal(false, rm:setLevel(1, 2, "Mood", "sad"))
    end)
end)

-- ============================================================
-- ECS Universe directed relationship API
-- ============================================================
describe("lurek.ecs Universe directed relationships", function()

    -- @covers lurek.ecs.addRelation
    -- @covers lurek.ecs.getRelated
    it("addRelation and getRelated round-trip", function()
        local u = lurek.ecs.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        u:addRelation(e1, "owns", e2)
        local related = u:getRelated(e1, "owns")
        expect_equal(1, #related)
        expect_equal(e2, related[1])
    end)

    -- @covers lurek.ecs.hasRelation
    it("hasRelation returns true when relation exists", function()
        local u = lurek.ecs.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        u:addRelation(e1, "enemy", e2)
        expect_equal(true, u:hasRelation(e1, "enemy", e2))
    end)

    -- @covers lurek.ecs.hasRelation
    it("hasRelation returns false when relation does not exist", function()
        local u = lurek.ecs.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        expect_equal(false, u:hasRelation(e1, "ally", e2))
    end)

    -- @covers lurek.ecs.removeRelation
    it("removeRelation removes a specific link", function()
        local u = lurek.ecs.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        u:addRelation(e1, "ally", e2)
        u:removeRelation(e1, "ally", e2)
        expect_equal(false, u:hasRelation(e1, "ally", e2))
    end)

    -- @covers lurek.ecs.clearRelations
    it("clearRelations removes all links of a type", function()
        local u = lurek.ecs.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        local e3 = u:spawn()
        u:addRelation(e1, "friend", e2)
        u:addRelation(e1, "friend", e3)
        u:clearRelations(e1, "friend")
        expect_equal(0, #u:getRelated(e1, "friend"))
    end)

    -- @covers lurek.ecs.addRelation
    it("addRelation is idempotent  no duplicate links", function()
        local u = lurek.ecs.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        u:addRelation(e1, "link", e2)
        u:addRelation(e1, "link", e2)
        expect_equal(1, #u:getRelated(e1, "link"))
    end)

    -- @covers lurek.ecs.addRelation
    it("directed links are not symmetric", function()
        local u = lurek.ecs.newUniverse()
        local e1 = u:spawn()
        local e2 = u:spawn()
        u:addRelation(e1, "owns", e2)
        expect_equal(0, #u:getRelated(e2, "owns"))
    end)

end)

--  serialization (merged from test_entity_serialization.lua) 

describe("lurek.ecs", function()
    describe("serialize and deserialize", function()
        -- @covers lurek.ecs.newUniverse
        -- @covers lurek.ecs.serialize
        -- @covers lurek.ecs.deserialize
        it("serialize returns a table with entities and bitmap_tags", function()
            local w = lurek.ecs.newUniverse()
            local e = w:spawn()
            w:set(e, "name", "hero")
            local snap = w:serialize()
            expect_equal("table", type(snap))
            expect_equal("table", type(snap.entities))
            expect_equal("table", type(snap.bitmap_tags))
        end)

        -- @covers lurek.ecs.serialize
        it("serialized entity count matches world entity count", function()
            local w = lurek.ecs.newUniverse()
            w:spawn() w:spawn() w:spawn()
            local snap = w:serialize()
            expect_equal(3, #snap.entities)
        end)

        -- @covers lurek.ecs.deserialize
        it("deserialize restores component values", function()
            local w = lurek.ecs.newUniverse()
            local e1 = w:spawn()
            w:set(e1, "hp", 42)
            local snap = w:serialize()
            -- Clear and restore
            w:clear()
            w:deserialize(snap)
            expect_equal(1, w:getEntityCount())
            local ids = w:getEntities()
            local hp = w:get(ids[1], "hp")
            expect_equal(42, hp)
        end)

        -- @covers lurek.ecs.deserialize
        it("deserialize restores string tags", function()
            local w = lurek.ecs.newUniverse()
            local e = w:spawn()
            w:addTag(e, "enemy")
            w:addTag(e, "active")
            local snap = w:serialize()
            w:clear()
            w:deserialize(snap)
            local enemies = w:getEntitiesByTag("enemy")
            expect_equal(1, #enemies)
        end)

        -- @covers lurek.ecs.deserialize
        it("deserialize preserves registered blueprints", function()
            local w = lurek.ecs.newUniverse()
            w:defineBlueprint("Enemy", {hp = 10, speed = 5})
            local snap = w:serialize()
            w:clear()
            w:deserialize(snap)
            expect_equal(true, w:hasBlueprint("Enemy"))
        end)
    end)
end)

--  system priority (merged from test_entity_system_priority.lua) 

describe("lurek.ecs", function()
    describe("system priority", function()
        -- @covers lurek.ecs.newUniverse
        -- @covers lurek.ecs.addSystem
        -- @covers lurek.ecs.update
        it("systems dispatch in ascending priority order", function()
            local w = lurek.ecs.newUniverse()
            local order = {}
            local sys_a = {
                update = function(self, world, dt)
                    table.insert(order, "A")
                end
            }
            local sys_b = {
                update = function(self, world, dt)
                    table.insert(order, "B")
                end
            }
            local sys_c = {
                update = function(self, world, dt)
                    table.insert(order, "C")
                end
            }
            -- Add in reverse order; lower priority = runs first
            w:addSystem(sys_c, {priority = 30})
            w:addSystem(sys_a, {priority = 10})
            w:addSystem(sys_b, {priority = 20})
            w:update(0.016)
            expect_equal("A", order[1])
            expect_equal("B", order[2])
            expect_equal("C", order[3])
        end)

        -- @covers lurek.ecs.addSystem
        it("systems default to priority 0 when not specified", function()
            local w = lurek.ecs.newUniverse()
            local order = {}
            local sys_default = { update = function() table.insert(order, "default") end }
            local sys_negative = { update = function() table.insert(order, "early") end }
            w:addSystem(sys_default)            -- priority 0
            w:addSystem(sys_negative, {priority = -1})  -- runs before
            w:update(0)
            expect_equal("early", order[1])
            expect_equal("default", order[2])
        end)

        -- @covers lurek.ecs.getSystemCount
        it("getSystemCount increments correctly with priority", function()
            local w = lurek.ecs.newUniverse()
            expect_equal(0, w:getSystemCount())
            local s1 = { update = function() end }
            local s2 = { update = function() end }
            w:addSystem(s1, {priority = 5})
            w:addSystem(s2, {priority = 1})
            expect_equal(2, w:getSystemCount())
        end)
    end)
end)


-- [merged from test_ecs_regress_relationship_default.lua]
-- Regression: RelationshipManager:defineType must not panic when the optional
-- default_level argument is omitted or empty. Before the fix, an empty default
-- string tripped a debug_assert in RelationType::new.

describe("RelationshipManager regression: empty default_level", function()
    -- @covers lurek.patterns.newRelationshipManager
    -- @covers lurek.patterns.RelationshipManager.defineType
    -- @covers lurek.patterns.RelationshipManager.typeNames
    it("defineType without default_level does not panic", function()
        local rm = lurek.patterns.newRelationshipManager()
        expect_no_error(function()
            rm:defineType("diplomacy", { "war", "neutral", "alliance" })
        end)
        local names = rm:typeNames()
        expect_equal(1, #names)
        expect_equal("diplomacy", names[1])
    end)

    -- @covers lurek.patterns.RelationshipManager.defineType
    xit("defineType rejects empty levels table with a Lua error (not a panic)", function()
        local rm = lurek.patterns.newRelationshipManager()
        expect_error(function()
            rm:defineType("bad", {})
        end)
    end)
end)

test_summary()
