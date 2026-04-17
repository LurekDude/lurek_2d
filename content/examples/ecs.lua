-- content/examples/ecs.lua
-- Lurek2D lurek.ecs API Reference
-- Run with: cargo run -- content/examples/ecs

-- =============================================================================
-- STUBS: 57 uncovered lurek.ecs API item(s)
-- =============================================================================

-- ---- Stub: lurek.ecs.newUniverse -----------------------------------------
--@api-stub: lurek.ecs.newUniverse
-- Create a fresh ECS universe for a dungeon level -- all entities,
-- systems, and blueprints live inside this container.
local world = lurek.ecs.newUniverse()
print("universe created:", world ~= nil)

-- Pre-define a blueprint that systems and spawn calls will reference
world:defineTag("enemy")
world:defineTag("player")

-- Blueprint helper used in blueprint stubs below
local hero_bp = {
    position = { x = 0, y = 0 },
    health   = { hp = 100 },
    speed    = { value = 200 },
}

-- -----------------------------------------------------------------------------
-- Universe methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Universe:spawn ------------------------------------------------
--@api-stub: Universe:spawn
-- Spawn a player entity and attach position and health components
-- in a single call using a pre-defined blueprint table.
local e = world:spawn(hero_bp)
print("spawned entity:", e)

-- ---- Stub: Universe:kill -------------------------------------------------
--@api-stub: Universe:kill
-- Kill an entity when its health drops to zero -- the slot is freed
-- and can be reused for the next spawned creature.
local temp = world:spawn({ position = { x = 10, y = 10 } })
world:kill(temp)
print("temp entity alive:", world:isAlive(temp))

-- ---- Stub: Universe:isAlive ----------------------------------------------
--@api-stub: Universe:isAlive
-- Guard update logic with an alive check so a system does not process
-- an entity that was killed earlier in the same frame.
if world:isAlive(e) then
    print("entity", e, "is alive -- processing OK")
end

-- ---- Stub: Universe:set --------------------------------------------------
--@api-stub: Universe:set
-- Attach a velocity component to an existing entity when the player
-- presses move for the first time, enabling kinematic systems.
world:set(e, "velocity", { vx = 150, vy = 0 })
print("velocity set:", world:has(e, "velocity"))

-- ---- Stub: Universe:get --------------------------------------------------
--@api-stub: Universe:get
-- Read the health component to display the player's HP on the HUD
-- without holding a separate reference to the health table.
local hp = world:get(e, "health")
print("player hp:", hp and hp.hp or "missing")

-- ---- Stub: Universe:has --------------------------------------------------
--@api-stub: Universe:has
-- Guard a system that only applies to entities with a velocity so
-- static props are silently skipped each tick.
if world:has(e, "velocity") then
    print("entity has velocity -- movement system applies")
end

-- ---- Stub: Universe:remove -----------------------------------------------
--@api-stub: Universe:remove
-- Strip the velocity component from an entity that becomes stunned
-- so the movement system stops updating it.
world:remove(e, "velocity")
print("velocity removed:", world:has(e, "velocity"))

-- ---- Stub: Universe:getComponents ----------------------------------------
--@api-stub: Universe:getComponents
-- List all component names on a selected entity in the debug inspector
-- so a developer can verify that spawning applied the right blueprint.
local comps = world:getComponents(e)
print("components on entity", e, ":")
for _, name in ipairs(comps) do print("  -", name) end

-- ---- Stub: Universe:query ------------------------------------------------
--@api-stub: Universe:query
-- Retrieve every entity with both position and health components to
-- drive the AI update pass for all living combatants.
local combatants = world:query({ "position", "health" })
print("combatants found:", #combatants)

-- ---- Stub: Universe:each -------------------------------------------------
--@api-stub: Universe:each
-- Iterate all entities with a health component and heal them by 5 HP
-- when the player activates a regen shrine.
world:each("health", function(id, h)
    h.hp = math.min(h.hp + 5, 100)
end)
print("regen applied to all health entities")

-- ---- Stub: Universe:getEntities ------------------------------------------
--@api-stub: Universe:getEntities
-- Retrieve all alive entity IDs to drive a global debug overlay that
-- draws a dot at each entity's world position.
local all = world:getEntities()
print("total alive entities:", #all)

-- ---- Stub: Universe:getEntityCount ---------------------------------------
--@api-stub: Universe:getEntityCount
-- Read the count before and after a bulk spawn to confirm the right
-- number of enemies were created for the room.
print("entity count:", world:getEntityCount())

-- ---- Stub: Universe:addSystem --------------------------------------------
--@api-stub: Universe:addSystem
-- Register the movement system with priority 10 so it runs before
-- the collision system at priority 20 each frame.
local movement_sys = {
    update = function(self, univ, dt)
        univ:each("position", function(id, pos)
            local vel = univ:get(id, "velocity")
            if vel then
                pos.x = pos.x + vel.vx * dt
                pos.y = pos.y + vel.vy * dt
            end
        end)
    end
}
world:addSystem(movement_sys, { priority = 10 })
print("systems:", world:getSystemCount())

-- ---- Stub: Universe:removeSystem -----------------------------------------
--@api-stub: Universe:removeSystem
-- Unregister the debug render system in release builds so the overhead
-- of iterating all entities for debug drawing is eliminated.
world:removeSystem(movement_sys)
print("systems after remove:", world:getSystemCount())

-- ---- Stub: Universe:update -----------------------------------------------
--@api-stub: Universe:update
-- Tick all registered systems for one frame -- call from lurek.process()
-- with the frame delta so physics and movement advance correctly.
world:addSystem(movement_sys, { priority = 10 })
world:update(0.016)

-- ---- Stub: Universe:render -----------------------------------------------
--@api-stub: Universe:render
-- Call the render() method on every system in priority order from
-- inside lurek.render() so sprite and particle systems draw this frame.
world:render()

-- ---- Stub: Universe:emit -------------------------------------------------
--@api-stub: Universe:emit
-- Broadcast a "on_room_clear" event to all systems so the loot and
-- door systems can react without knowing about each other.
world:emit("on_room_clear", { room_id = 7, bonus = true })

-- ---- Stub: Universe:getSystemCount ---------------------------------------
--@api-stub: Universe:getSystemCount
-- Read system count after loading a level to validate that all expected
-- systems are registered before the first frame runs.
print("active systems:", world:getSystemCount())

-- ---- Stub: Universe:clear ------------------------------------------------
--@api-stub: Universe:clear
-- Wipe all entities, tags, and layers when transitioning to a new dungeon
-- floor -- blueprints survive for the next room spawn.
world:clear()
print("universe cleared, entities:", world:getEntityCount())

-- Repopulate for subsequent stubs
local e = world:spawn(hero_bp)
world:set(e, "velocity", { vx = 0, vy = 0 })

-- ---- Stub: Universe:release ----------------------------------------------
--@api-stub: Universe:release
-- Fully reset the universe at session end to release all component
-- memory before the level scene is popped from the stack.
local tmp_world = lurek.ecs.newUniverse()
tmp_world:spawn({ position = { x = 0, y = 0 } })
tmp_world:release()
print("temp universe released")

-- ---- Stub: Universe:addTag -----------------------------------------------
--@api-stub: Universe:addTag
-- Tag the player entity as "player" so event handlers and enemy AI
-- can find it by tag without storing a global entity ID.
world:addTag(e, "player")
print("has player tag:", world:hasTag(e, "player"))

-- ---- Stub: Universe:removeTag --------------------------------------------
--@api-stub: Universe:removeTag
-- Remove the "invincible" tag when a power-up expires so the damage
-- system starts processing hits again.
world:addTag(e, "invincible")
world:removeTag(e, "invincible")
print("invincible removed:", world:hasTag(e, "invincible"))

-- ---- Stub: Universe:hasTag -----------------------------------------------
--@api-stub: Universe:hasTag
-- Guard the damage handler so invincible entities take no damage even
-- if they are inside the hit radius.
if not world:hasTag(e, "invincible") then
    print("entity takes damage")
end

-- ---- Stub: Universe:getTags ----------------------------------------------
--@api-stub: Universe:getTags
-- List all string tags on the player entity in the debug inspector
-- to verify power-up logic applied the correct tags.
local tags = world:getTags(e)
print("entity tags:")
for _, t in ipairs(tags) do print("  -", t) end

-- ---- Stub: Universe:getEntitiesByTag -------------------------------------
--@api-stub: Universe:getEntitiesByTag
-- Retrieve all "enemy" entities at room-clear check time to confirm
-- none remain before unlocking the exit door.
local enemies = world:getEntitiesByTag("enemy")
print("enemies alive:", #enemies)

-- ---- Stub: Universe:setLayer ---------------------------------------------
--@api-stub: Universe:setLayer
-- Assign layer 2 to flying entities so the renderer draws them above
-- ground-layer sprites without a custom z-component.
world:setLayer(e, 2)
print("layer:", world:getLayer(e))

-- ---- Stub: Universe:getLayer ---------------------------------------------
--@api-stub: Universe:getLayer
-- Read the entity's layer to determine the draw order in the depth
-- sorter without reading a separate z-component.
print("entity layer:", world:getLayer(e))  -- 2

-- ---- Stub: Universe:getEntitiesByLayer -----------------------------------
--@api-stub: Universe:getEntitiesByLayer
-- Retrieve all entities on layer 0 (ground) to drive the tile shadow
-- system that only processes ground-level sprites.
local ground = world:getEntitiesByLayer(0)
print("entities on layer 0:", #ground)

-- ---- Stub: Universe:getEntitiesSorted ------------------------------------
--@api-stub: Universe:getEntitiesSorted
-- Get the full entity list sorted by layer then ID to feed the
-- painter's-order renderer without a separate sort step.
local sorted = world:getEntitiesSorted()
print("sorted entity count:", #sorted)

-- ---- Stub: Universe:defineTag --------------------------------------------
--@api-stub: Universe:defineTag
-- Allocate a bitmap tag slot for "on_fire" so the fire propagation
-- system can query it with a bitwise mask instead of a string scan.
local on_fire_bit = world:defineTag("on_fire")
print("on_fire bitmap bit:", on_fire_bit)

-- ---- Stub: Universe:bitmapTag --------------------------------------------
--@api-stub: Universe:bitmapTag
-- Set the "on_fire" bitmap tag on an entity when a fireball hits so
-- the DOT system can find all burning entities with a single bitmask query.
world:bitmapTag(e, "on_fire")
print("on_fire set:", world:hasBitmapTag(e, "on_fire"))

-- ---- Stub: Universe:bitmapUntag ------------------------------------------
--@api-stub: Universe:bitmapUntag
-- Clear the "on_fire" bitmap tag when a water bucket extinguishes
-- the flame so the DOT system stops dealing damage.
world:bitmapUntag(e, "on_fire")
print("on_fire cleared:", world:hasBitmapTag(e, "on_fire"))

-- ---- Stub: Universe:hasBitmapTag -----------------------------------------
--@api-stub: Universe:hasBitmapTag
-- Check whether an entity currently has the "player" bitmap tag to
-- drive an enemy aggro scan faster than a string-tag search.
world:bitmapTag(e, "player")
print("has player bitmap:", world:hasBitmapTag(e, "player"))

-- ---- Stub: Universe:queryBitmapTag ---------------------------------------
--@api-stub: Universe:queryBitmapTag
-- Find all entities with the "player" bitmap tag in O(n) without
-- scanning component tables -- ideal for enemy target acquisition.
local players = world:queryBitmapTag("player")
print("player entities:", #players)

-- ---- Stub: Universe:queryBitmapAny ---------------------------------------
--@api-stub: Universe:queryBitmapAny
-- Return all entities that are either on_fire or poisoned to drive
-- a status-effect system with a single combined query.
local affected = world:queryBitmapAny({ "on_fire", "player" })
print("affected by any tag:", #affected)

-- ---- Stub: Universe:queryBitmapAll ---------------------------------------
--@api-stub: Universe:queryBitmapAll
-- Find entities that have BOTH the "player" and "stunned" bitmap tags
-- so the stun-recovery system skips non-stunned players.
world:bitmapTag(e, "stunned")
local stunned_players = world:queryBitmapAll({ "player", "stunned" })
print("stunned players:", #stunned_players)
world:bitmapUntag(e, "stunned")

-- ---- Stub: Universe:getBitmapTagBit --------------------------------------
--@api-stub: Universe:getBitmapTagBit
-- Look up the bit index for "on_fire" to perform raw bitwise math
-- when building a combined status mask for the particle system.
local bit_idx = world:getBitmapTagBit("on_fire")
print("on_fire bit index:", bit_idx)

-- ---- Stub: Universe:hasBlueprint -----------------------------------------
--@api-stub: Universe:hasBlueprint
-- Guard a spawn call to print a clear error when a blueprint name
-- is missing from the registry rather than crashing silently.
local has_hero = world:hasBlueprint("hero")
print("hero blueprint exists:", has_hero)

-- ---- Stub: Universe:removeBlueprint --------------------------------------
--@api-stub: Universe:removeBlueprint
-- Remove a one-time tutorial blueprint after it is used so it cannot
-- be accidentally re-spawned in later rooms.
if world:hasBlueprint("tutorial_enemy") then
    world:removeBlueprint("tutorial_enemy")
    print("tutorial_enemy blueprint removed")
end

-- ---- Stub: Universe:listBlueprints ---------------------------------------
--@api-stub: Universe:listBlueprints
-- Enumerate all blueprint names during level load to verify the
-- content pipeline included every expected enemy and item template.
local bps = world:listBlueprints()
print("registered blueprints:")
for _, name in ipairs(bps) do print("  -", name) end

-- ---- Stub: Universe:getBlueprintComponents -------------------------------
--@api-stub: Universe:getBlueprintComponents
-- Read the hero blueprint's component table to display its default
-- stats in a character creation preview screen.
local hero_comps = world:getBlueprintComponents("hero_bp")
if hero_comps then
    print("hero blueprint has", #hero_comps, "component types")
end

-- ---- Stub: Universe:getParent --------------------------------------------
--@api-stub: Universe:getParent
-- Walk up the entity hierarchy to find the root vehicle entity from
-- a mounted weapon entity.
local parent = world:getParent(e)
print("entity parent:", parent or "none (root)")

-- ---- Stub: Universe:getChildren ------------------------------------------
--@api-stub: Universe:getChildren
-- List all direct children of the player entity to find mounted weapons,
-- status effect emitters, and attached companions.
local children = world:getChildren(e)
print("entity children:", #children)

-- ---- Stub: Universe:killRecursive ----------------------------------------
--@api-stub: Universe:killRecursive
-- Kill a vehicle entity together with all its mounted child entities
-- in one call so none are left as orphaned alive entities.
local vehicle = world:spawn({ position = { x = 100, y = 100 } })
local cannon  = world:spawn({ parent = vehicle })
world:killRecursive(vehicle)
print("vehicle alive:", world:isAlive(vehicle))
print("cannon alive:", world:isAlive(cannon))

-- ---- Stub: Universe:queryNot ---------------------------------------------
--@api-stub: Universe:queryNot
-- Find all entities that have a position but no velocity so the
-- static-prop system can skip movement calculations for them.
local statics = world:queryNot({ "position" }, { "velocity" })
print("static (pos, no vel) entities:", #statics)

-- ---- Stub: Universe:serialize --------------------------------------------
--@api-stub: Universe:serialize
-- Snapshot all alive entities and their components before writing a
-- save file so the dungeon state survives a session quit.
local snapshot = world:serialize()
print("snapshot entity count:", #snapshot)

-- ---- Stub: Universe:deserialize ------------------------------------------
--@api-stub: Universe:deserialize
-- Restore the universe from a save snapshot on load -- the game
-- resumes in exactly the same room state as when it was saved.
world:clear()
world:deserialize(snapshot)
print("universe restored, entities:", world:getEntityCount())

-- ---- Stub: Universe:onComponentAdded -------------------------------------
--@api-stub: Universe:onComponentAdded
-- Register a hook so the audio system plays a sound every time
-- a "burning" component is added anywhere in the universe.
world:onComponentAdded("burning", function(id)
    print("entity", id, "caught fire -- play sizzle sound")
end)

-- ---- Stub: Universe:onComponentRemoved -----------------------------------
--@api-stub: Universe:onComponentRemoved
-- Register a hook so the particle system stops the fire emitter as
-- soon as the "burning" component is removed.
world:onComponentRemoved("burning", function(id)
    print("entity", id, "fire extinguished -- stop particles")
end)

-- ---- Stub: Universe:flushObservers ---------------------------------------
--@api-stub: Universe:flushObservers
-- Dispatch all pending add/remove events after the batch spawn so
-- observer systems see the new entities before the first update tick.
local e2 = world:spawn({ position = { x = 50, y = 50 } })
world:set(e2, "burning", { duration = 3.0 })
world:flushObservers()
print("observers flushed")

-- ---- Stub: Universe:spawnBulk --------------------------------------------
--@api-stub: Universe:spawnBulk
-- Spawn 20 identical skeleton enemies from the skeleton blueprint
-- at room entry to fill the encounter without a loop.
local skeleton_bp = { position = { x = 0, y = 0 }, health = { hp = 30 } }
local skeletons = world:spawnBulk(skeleton_bp, 5)
print("bulk spawned:", #skeletons, "skeletons")
for _, sid in ipairs(skeletons) do
    world:addTag(sid, "enemy")
end

-- ---- Stub: Universe:addRelation ------------------------------------------
--@api-stub: Universe:addRelation
-- Record an "aggro" relationship from each spawned skeleton toward
-- the player so the AI system can find targets without a global search.
local player_e = world:spawn(hero_bp)
for _, sid in ipairs(skeletons) do
    world:addRelation(sid, "aggro", player_e)
end
print("aggro relations set on", #skeletons, "skeletons")

-- ---- Stub: Universe:getRelated -------------------------------------------
--@api-stub: Universe:getRelated
-- Retrieve all entities that the first skeleton has an "aggro" relation
-- to so the AI can pick the nearest one as its movement target.
local first = skeletons[1]
if first then
    local targets = world:getRelated(first, "aggro")
    print("skeleton aggro targets:", #targets)
end

-- ---- Stub: Universe:removeRelation ---------------------------------------
--@api-stub: Universe:removeRelation
-- Break the aggro link when the player uses an invisibility scroll
-- so enemies stop chasing them.
if first then
    world:removeRelation(first, "aggro", player_e)
    print("aggro removed from skeleton 1")
end

-- ---- Stub: Universe:clearRelations ---------------------------------------
--@api-stub: Universe:clearRelations
-- Remove all "aggro" relations from a confused skeleton so it no
-- longer has a target after the confusion effect expires.
if first then
    world:clearRelations(first, "aggro")
    print("all aggro cleared from skeleton 1")
end

-- ---- Stub: Universe:hasRelation ------------------------------------------
--@api-stub: Universe:hasRelation
-- Check whether a guard still has a "patrol_path" relation to a
-- waypoint entity before queueing a move command.
local waypoint = world:spawn({ position = { x = 200, y = 50 } })
world:addRelation(first or e, "patrol_path", waypoint)
print("has patrol relation:", world:hasRelation(first or e, "patrol_path", waypoint))
