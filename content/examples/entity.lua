-- examples/entity.lua
-- luna.entity — Lightweight ECS with entity lifecycle, components, tags, layers, and blueprints.
-- All luna.entity API methods demonstrated with code and comments.
-- This file is documentation code, not a runnable game.

-- ── Creating a Universe ───────────────────────────────────────────────────────

-- newUniverse() → Universe
-- The Universe is the root ECS container; all entities, components, and
-- systems are owned by it. Multiple universes can coexist.
local world = luna.entity.newUniverse()

-- ── Entity Lifecycle ──────────────────────────────────────────────────────────

-- spawn() → integer — create a new entity and return its packed ID
local e1 = world:spawn()
local e2 = world:spawn()

-- isAlive(id) → boolean
local alive = world:isAlive(e1)  -- true

-- kill(id) — destroy the entity; its slot may be reused
world:kill(e2)
print(world:isAlive(e2))  -- false

-- getEntityCount() → integer
local count = world:getEntityCount()  -- 1

-- getEntities() → {integer,...} — all alive entity IDs
local ids = world:getEntities()

-- ── Components ────────────────────────────────────────────────────────────────

-- set(id, name, value) — attach or update a component; value is any Lua value
world:set(e1, "position", { x = 100, y = 200 })
world:set(e1, "velocity", { vx = 0, vy = 0 })
world:set(e1, "health", 100)

-- get(id, name) → value? — retrieve component value or nil
local pos = world:get(e1, "position")   -- {x=100, y=200}
local hp  = world:get(e1, "health")     -- 100

-- has(id, name) → boolean
local has_pos = world:has(e1, "position")  -- true

-- remove(id, name) — detach a component
world:remove(e1, "velocity")

-- getComponents(id) → {string,...} — all component names on this entity
local comp_names = world:getComponents(e1)  -- {"position", "health"}

-- ── Query ─────────────────────────────────────────────────────────────────────

-- query("comp1", "comp2", ...) → {integer,...}
-- Returns all entity IDs that have ALL the listed components.
local e3 = world:spawn()
world:set(e3, "position", { x = 50, y = 50 })
world:set(e3, "velocity", { vx = 10, vy = 0 })
world:set(e3, "health", 80)

local movers = world:query("position", "velocity")
-- Returns {e3} (e1 has position but not velocity any more)

-- each(name, fn) — iterate every entity that has a component, calling fn(id, value)
world:each("health", function(id, hp)
    if hp <= 0 then
        world:kill(id)
    end
end)

-- ── String Tags ───────────────────────────────────────────────────────────────

-- String tags are ad-hoc labels that don't carry data.
-- addTag(id, tag)
world:addTag(e1, "player")
world:addTag(e1, "active")

-- hasTag(id, tag) → boolean
print(world:hasTag(e1, "player"))  -- true

-- getTags(id) → {string,...}
local tags = world:getTags(e1)

-- getEntitiesByTag(tag) → {integer,...}
local players = world:getEntitiesByTag("player")

-- removeTag(id, tag)
world:removeTag(e1, "active")

-- ── Bitmap Tags (fast bit-field membership) ───────────────────────────────────

-- defineTag(name) → bit_index — register a named bit in the bitmap
local ENEMY  = world:defineTag("enemy")
local FLYING = world:defineTag("flying")

-- bitmapTag(id, name) / bitmapUntag(id, name)
world:bitmapTag(e3, "enemy")
world:bitmapTag(e3, "flying")

-- hasBitmapTag(id, name) → boolean
print(world:hasBitmapTag(e3, "enemy"))  -- true

-- queryBitmapTag(name) → {integer,...} — all entities with this bit tag
local enemies = world:queryBitmapTag("enemy")

-- queryBitmapAny(names_table) → entities with ANY of the listed bits
local airborne_or_enemy = world:queryBitmapAny({"enemy", "flying"})

-- queryBitmapAll(names_table) → entities with ALL of the listed bits
local flying_enemies = world:queryBitmapAll({"enemy", "flying"})

-- getBitmapTagBit(name) → integer? — retrieve the bit index
local bit = world:getBitmapTagBit("enemy")

-- bitmapUntag(id, name)
world:bitmapUntag(e3, "flying")

-- ── Layers ────────────────────────────────────────────────────────────────────

-- setLayer(id, layer) — assign a numeric layer (default 0)
world:setLayer(e1, 2)  -- render layer 2

-- getLayer(id) → integer
local layer = world:getLayer(e1)  -- 2

-- getEntitiesByLayer(layer) → {integer,...}
local layer2 = world:getEntitiesByLayer(2)

-- getEntitiesSorted() → {integer,...} — all entities sorted by layer then ID
local sorted = world:getEntitiesSorted()

-- ── Hierarchies (Parent / Child) ──────────────────────────────────────────────

local parent_id = world:spawn()
local child1    = world:spawn()
local child2    = world:spawn()

-- setParent(child_id, parent_id?) — nil removes the parent relationship
world:setParent(child1, parent_id)
world:setParent(child2, parent_id)

-- getParent(id) → integer? — parent entity ID or nil
local par = world:getParent(child1)

-- getChildren(parent_id) → {integer,...}
local children = world:getChildren(parent_id)

-- killRecursive(id) — destroy entity and all descendants
world:killRecursive(parent_id)

-- ── Blueprints ────────────────────────────────────────────────────────────────

-- defineBlueprint(name, components_table)
-- Blueprints define reusable entity templates.
world:defineBlueprint("enemy_basic", {
    health   = 50,
    speed    = 80,
    position = { x = 0, y = 0 },
    faction  = "enemy",
})

-- extendBlueprint(name, parent, overrides) — inherit + override
world:extendBlueprint("enemy_boss", "enemy_basic", {
    health = 500,
    speed  = 30,
    size   = 3,
})

-- hasBlueprint(name) → boolean
print(world:hasBlueprint("enemy_boss"))  -- true

-- listBlueprints() → {string,...}
local bp_names = world:listBlueprints()

-- getBlueprintComponents(name) → table? — deep copy of the component table
local bp_comps = world:getBlueprintComponents("enemy_basic")

-- spawnBlueprint(name, overrides?) → integer — new entity from blueprint
local boss = world:spawnBlueprint("enemy_boss", { position = { x = 400, y = 200 } })

-- removeBlueprint(name)
world:removeBlueprint("enemy_basic")

-- ── Systems ───────────────────────────────────────────────────────────────────

-- Systems are plain Lua tables with update(self, world, dt) and/or draw(self, world) methods.
-- The universe calls update() and draw() on each registered system in order.

local MovementSystem = {}
MovementSystem.__index = MovementSystem

function MovementSystem.new()
    return setmetatable({}, MovementSystem)
end

function MovementSystem:update(ecs, dt)
    local entities = ecs:query("position", "velocity")
    for _, id in ipairs(entities) do
        local pos = ecs:get(id, "position")
        local vel = ecs:get(id, "velocity")
        pos.x = pos.x + vel.vx * dt
        pos.y = pos.y + vel.vy * dt
        ecs:set(id, "position", pos)
    end
end

-- addSystem(system_table) — register a system
world:addSystem(MovementSystem.new())

-- update(dt) — dispatches to all systems' update method
world:update(1/60)

-- draw() — dispatches to all systems' draw method (if defined)
world:draw()

-- emit(event_name, ...) — broadcast a named event to all system handlers
-- System tables that implement the event name as a method will be called.
world:emit("on_collision", e1, e3)  -- calls system:on_collision(world, e1, e3)

-- getSystemCount() → integer
local sys_count = world:getSystemCount()

-- removeSystem(system_table)
local my_sys = MovementSystem.new()
world:addSystem(my_sys)
world:removeSystem(my_sys)

-- ── Clearing / Release ────────────────────────────────────────────────────────

-- clear() — destroy all entities, components, tags, layers, and systems
-- (blueprints are preserved)
world:clear()

-- release() — equivalent to clear; frees all universe state
world:release()
