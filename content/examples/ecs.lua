-- content/examples/ecs.lua
-- lurek.ecs API examples: entity-component-system universe with entities, components, systems, tags, blueprints, hierarchy, relations, and serialization.
-- Run: cargo run -- content/examples/ecs.lua

--@api-stub: lurek.ecs.newUniverse
-- Creates an empty ECS universe for entity, component, system, and relationship management
do
  -- newUniverse() is the entry point to the entire ECS.
  -- A universe holds all entities, components, systems, tags, blueprints, and relations.
  -- You typically create one universe per game world (or one per scene).
  local world = lurek.ecs.newUniverse()

  -- Immediately usable: spawn an entity and assign data
  local hero = world:spawn()
  world:set(hero, "position", { x = 0, y = 0 })
  lurek.log.info("universe ready, first id=" .. hero, "ecs")
end

-- Universe methods

--@api-stub: Universe:spawn
-- Creates a new entity and returns its numeric id
do
  local world = lurek.ecs.newUniverse()

  -- spawn() returns a unique integer id for the new entity.
  -- Entities are lightweight — just an id. All data lives in components.
  local enemy = world:spawn()

  -- Assign components immediately after spawn to define what the entity IS.
  -- "position" makes it spatial, "health" makes it damageable.
  world:set(enemy, "position", { x = 320, y = 240 })
  world:set(enemy, "health",   { hp = 5, max = 5 })
end

--@api-stub: Universe:kill
-- Deletes an entity and removes all its components from the universe
do
  local world = lurek.ecs.newUniverse()
  local bullet = world:spawn()
  world:set(bullet, "position", { x = 100, y = 100 })

  -- kill() removes the entity and all its components.
  -- After kill(), the id is no longer valid — isAlive() returns false.
  -- Use this when a projectile hits, an enemy dies, or a particle expires.
  world:kill(bullet)
end

--@api-stub: Universe:isAlive
-- Returns true if an entity id currently exists in this universe
do
  local world = lurek.ecs.newUniverse()
  local id = world:spawn()
  world:kill(id)

  -- isAlive() is essential for deferred logic. If you store an entity id
  -- and process it later (next frame, after a timer), always check isAlive()
  -- before accessing components — the entity may have been killed.
  if not world:isAlive(id) then
    lurek.log.debug("target already destroyed, skip damage", "ecs")
  end
end

--@api-stub: Universe:get
-- Returns a component value table from an entity (or nil if absent)
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "position", { x = 10, y = 20 })

  -- get() returns the SAME table reference stored in the universe.
  -- Mutating the returned table directly changes the component in-place.
  -- This avoids repeated set() calls for small updates.
  local pos = world:get(e, "position")
  pos.x = pos.x + 1  -- modifies the component directly

  -- Returns nil if the entity does not have that component.
  local vel = world:get(e, "velocity")
  if vel == nil then
    lurek.log.debug("entity has no velocity component", "ecs")
  end
end

--@api-stub: Universe:has
-- Returns true if an entity has a named component
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "stunned", { ticks = 30 })

  -- has() is a fast existence check without retrieving the data.
  -- Use it to guard logic: skip AI for stunned entities, skip rendering
  -- for invisible ones, skip movement for frozen ones.
  if world:has(e, "stunned") then
    lurek.log.debug("entity stunned — skipping AI this frame", "ecs")
  end
end

--@api-stub: Universe:remove
-- Removes a named component from an entity
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "burning", { ticks = 60, dps = 2 })

  -- remove() detaches a component. The entity stays alive — it just loses
  -- that behavior. Use this for expiring status effects, unequipping items,
  -- or switching entity states (remove "idle", set "attacking").
  world:remove(e, "burning")

  -- After removal, has() returns false and get() returns nil.
  assert(not world:has(e, "burning"))
end

--@api-stub: Universe:getComponents
-- Returns an array of component name strings currently stored on an entity
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "position", { x = 0, y = 0 })
  world:set(e, "sprite",   { path = "img/hero.png" })
  world:set(e, "health",   { hp = 10, max = 10 })

  -- getComponents() returns {"position", "sprite", "health"} (order may vary).
  -- Useful for debug inspectors, serialization filters, or dynamic UI panels.
  for _, name in ipairs(world:getComponents(e)) do
    lurek.log.debug("component: " .. name, "inspect")
  end
end

--@api-stub: Universe:query
-- Returns entity ids that have ALL listed component names (varargs)
do
  local world = lurek.ecs.newUniverse()

  -- Set up a few entities with different component combinations
  local mover = world:spawn()
  world:set(mover, "position", { x = 0, y = 0 })
  world:set(mover, "velocity", { x = 1, y = 0 })

  local static = world:spawn()
  world:set(static, "position", { x = 50, y = 50 })
  -- no velocity — this entity won't appear in a movement query

  -- query() with multiple names = AND filter. Only entities with ALL
  -- listed components are returned. This is the core of system iteration.
  for _, id in ipairs(world:query("position", "velocity")) do
    local p, v = world:get(id, "position"), world:get(id, "velocity")
    p.x, p.y = p.x + v.x, p.y + v.y
  end

  -- Single-component query also works: find everything that has "position"
  local all_spatial = world:query("position")
  lurek.log.debug("spatial entities=" .. #all_spatial, "ecs")
end

--@api-stub: Universe:getEntities
-- Returns all live entity ids in this universe
do
  local world = lurek.ecs.newUniverse()
  for _ = 1, 5 do world:spawn() end

  -- getEntities() returns every alive entity regardless of components.
  -- Use for global operations: save-all, debug dump, or despawn-all.
  local all = world:getEntities()
  lurek.log.info("total entities=" .. #all, "ecs")
end

--@api-stub: Universe:getEntityCount
-- Returns the number of live entities in this universe
do
  local world = lurek.ecs.newUniverse()
  for _ = 1, 12 do world:spawn() end

  -- getEntityCount() is O(1) — use it for budget checks, HUD display,
  -- or deciding whether to spawn more enemies.
  local count = world:getEntityCount()
  if count > 1000 then
    lurek.log.warn("entity budget exceeded! count=" .. count, "ecs")
  end
end

--@api-stub: Universe:removeSystem
-- Removes a previously registered system table from this universe
do
  local world = lurek.ecs.newUniverse()
  local ai_system = {
    update = function(self, w, dt)
      -- AI logic here
    end
  }
  world:addSystem(ai_system, { priority = 50 })

  -- removeSystem() unregisters a system. Pass the SAME table reference.
  -- Use this for toggling systems: remove AI during cutscenes,
  -- remove physics during menus, remove rendering during loading.
  world:removeSystem(ai_system)
end

--@api-stub: Universe:update
-- Runs all registered update-phase systems with a frame delta time
do
  local world = lurek.ecs.newUniverse()

  -- Systems are plain Lua tables with an `update(self, world, dt)` method.
  -- The ECS calls them in priority order every frame.
  local move_system = {
    update = function(self, w, dt)
      for _, id in ipairs(w:query("position", "velocity")) do
        local p, v = w:get(id, "position"), w:get(id, "velocity")
        p.x, p.y = p.x + v.x * dt, p.y + v.y * dt
      end
    end
  }
  world:addSystem(move_system, { priority = 10 })

  -- Hook world:update(dt) into lurek.process — the engine calls this each frame.
  -- dt is the frame delta in seconds (e.g. ~0.016 at 60 FPS).
  function lurek.process(dt) world:update(dt) end
end

--@api-stub: Universe:render
-- Runs all registered render-phase systems (render or draw callbacks)
do
  local world = lurek.ecs.newUniverse()

  -- Render systems use `render(self, world)` or `draw(self, world)`.
  -- They run after update, in priority order, during the draw pass.
  local draw_system = {
    render = function(self, w)
      for _, id in ipairs(w:query("position", "sprite")) do
        local p = w:get(id, "position")
        lurek.render.rectangle("fill", p.x, p.y, 16, 16)
      end
    end
  }
  world:addSystem(draw_system, { priority = 100 })

  -- Hook into lurek.draw — the engine calls this for the render pass.
  function lurek.draw() world:render() end
end

--@api-stub: Universe:emit
-- Dispatches a named event to all systems that define a matching method
do
  local world = lurek.ecs.newUniverse()

  -- emit() calls event-named functions on every registered system.
  -- Systems opt-in by defining a method with that name.
  -- The system receives (self, world, ...extra_args).
  local hp_system = {
    damage = function(self, w, id, amount)
      local h = w:get(id, "health")
      if h then
        h.hp = h.hp - amount
        if h.hp <= 0 then w:kill(id) end
      end
    end
  }
  world:addSystem(hp_system)

  local target = world:spawn()
  world:set(target, "health", { hp = 10, max = 10 })

  -- emit("damage", target, 3) calls hp_system:damage(world, target, 3)
  world:emit("damage", target, 3)
  lurek.log.info("hp after hit=" .. world:get(target, "health").hp, "ecs")
end

--@api-stub: Universe:getSystemCount
-- Returns the number of registered systems in this universe
do
  local world = lurek.ecs.newUniverse()
  world:addSystem({ update = function() end })
  world:addSystem({ render = function() end })

  -- getSystemCount() is useful for debug overlays or verifying setup.
  lurek.log.info("systems registered=" .. world:getSystemCount(), "ecs")
end

--@api-stub: Universe:clear
-- Clears all entities, components, systems, and state from this universe
do
  local world = lurek.ecs.newUniverse()
  for _ = 1, 5 do world:spawn() end

  -- clear() resets the universe to empty. Use when restarting a level,
  -- transitioning scenes, or cleaning up before deserialize.
  world:clear()
  lurek.log.info("after clear count=" .. world:getEntityCount(), "ecs")
end

--@api-stub: Universe:release
-- Releases universe contents (alias for clear — frees all state)
do
  local world = lurek.ecs.newUniverse()
  world:spawn()

  -- release() is identical to clear(). Call it when you are done
  -- with a universe and want to free memory (e.g. leaving a scene).
  world:release()
end

--@api-stub: Universe:addTag
-- Adds a string tag to an entity for categorical grouping
do
  local world = lurek.ecs.newUniverse()
  local hero = world:spawn()

  -- Tags are lightweight string labels. Unlike components, they carry no data.
  -- Use them for categorical queries: "player", "enemy", "collectible", "boss".
  world:addTag(hero, "player")
  world:addTag(hero, "alive")

  -- An entity can have many tags simultaneously.
  -- Tags persist until explicitly removed or the entity is killed.
end

--@api-stub: Universe:removeTag
-- Removes a string tag from an entity
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:addTag(e, "alive")

  -- removeTag() strips one tag. Use for state transitions:
  -- entity dies → remove "alive", add "dead" for corpse rendering.
  world:removeTag(e, "alive")
  assert(not world:hasTag(e, "alive"))
end

--@api-stub: Universe:hasTag
-- Returns true if an entity has a given string tag
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:addTag(e, "player")

  -- hasTag() is a quick boolean check, useful in collision callbacks
  -- or conditional logic without needing a full query.
  if world:hasTag(e, "player") then
    lurek.log.debug("hit the player entity!", "ecs")
  end
end

--@api-stub: Universe:getTags
-- Returns an array of all string tags assigned to an entity
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:addTag(e, "player")
  world:addTag(e, "invincible")

  -- getTags() returns all tags as an array. Useful for debug display
  -- or serialization of entity state.
  for _, t in ipairs(world:getTags(e)) do
    lurek.log.debug("tag: " .. t, "tags")
  end
end

--@api-stub: Universe:getEntitiesByTag
-- Returns all entity ids that have a specific string tag
do
  local world = lurek.ecs.newUniverse()
  for _ = 1, 3 do
    local id = world:spawn()
    world:addTag(id, "enemy")
  end

  -- getEntitiesByTag() is a fast lookup — indexed by the tag system.
  -- Use it when you need all entities of a category (all enemies, all pickups).
  local enemies = world:getEntitiesByTag("enemy")
  lurek.log.info("enemy count=" .. #enemies, "ecs")
end

--@api-stub: Universe:setLayer
-- Assigns a numeric render layer to an entity for draw ordering
do
  local world = lurek.ecs.newUniverse()
  local floor = world:spawn()
  local actor = world:spawn()

  -- Layers are integers used for sorting during rendering.
  -- Lower numbers draw first (behind), higher numbers draw last (in front).
  -- Typical setup: 0=background, 10=actors, 20=particles, 30=UI.
  world:setLayer(floor, 0)
  world:setLayer(actor, 10)
end

--@api-stub: Universe:getLayer
-- Returns the numeric layer assigned to an entity
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:setLayer(e, 5)

  -- getLayer() reads back the assigned layer. Default is 0 if never set.
  local layer = world:getLayer(e)
  if layer >= 5 then
    lurek.log.debug("entity is in foreground layer", "ecs")
  end
end

--@api-stub: Universe:getEntitiesByLayer
-- Returns all entity ids assigned to a specific numeric layer
do
  local world = lurek.ecs.newUniverse()
  for i = 1, 4 do
    local id = world:spawn()
    world:setLayer(id, i % 2)  -- alternates between layer 0 and 1
  end

  -- getEntitiesByLayer() returns entities in that exact layer.
  -- Use for layer-specific logic: only update layer-0 backgrounds,
  -- or only check collisions within the same layer.
  local fg = world:getEntitiesByLayer(1)
  lurek.log.debug("layer 1 entities=" .. #fg, "ecs")
end

--@api-stub: Universe:getEntitiesSorted
-- Returns all live entities sorted by layer (ascending) for draw ordering
do
  local world = lurek.ecs.newUniverse()
  local a = world:spawn(); world:setLayer(a, 2)
  local b = world:spawn(); world:setLayer(b, 0)
  local c = world:spawn(); world:setLayer(c, 1)

  -- getEntitiesSorted() returns ids sorted by layer value (low to high).
  -- Iterate this for correct back-to-front rendering without manual sorting.
  local order = world:getEntitiesSorted()
  for _, id in ipairs(order) do
    lurek.log.debug("draw entity=" .. id .. " layer=" .. world:getLayer(id), "ecs")
  end
end

--@api-stub: Universe:defineTag
-- Defines a bitmap tag name and assigns it a bit slot for fast queries
do
  local world = lurek.ecs.newUniverse()

  -- Bitmap tags are a high-performance alternative to string tags.
  -- defineTag() reserves a bit index (max 64 tags per universe).
  -- Use them for hot-path checks: collision masks, visibility flags, etc.
  local bit_player = world:defineTag("player")
  local bit_enemy  = world:defineTag("enemy")
  lurek.log.info("player bit=" .. bit_player .. " enemy bit=" .. bit_enemy, "ecs")
end

--@api-stub: Universe:bitmapTag
-- Adds a bitmap tag to an entity (defines the tag automatically if needed)
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("solid")
  local block = world:spawn()

  -- bitmapTag() sets the bit on the entity's tag mask.
  -- If the tag was not previously defined, it auto-defines it.
  -- Return value is not used; check hasBitmapTag() to confirm the tag was set.
  world:bitmapTag(block, "solid")
  lurek.log.debug("solid tag applied: " .. tostring(world:hasBitmapTag(block, "solid")), "ecs")
end

--@api-stub: Universe:bitmapUntag
-- Removes a bitmap tag from an entity
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("invincible")
  local hero = world:spawn()
  world:bitmapTag(hero, "invincible")

  -- bitmapUntag() clears the bit. Use for timed power-ups:
  -- set "invincible" on pickup, clear it after 5 seconds.
  world:bitmapUntag(hero, "invincible")
  assert(not world:hasBitmapTag(hero, "invincible"))
end

--@api-stub: Universe:hasBitmapTag
-- Returns true if an entity has a given bitmap tag
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("solid")
  local block = world:spawn()
  world:bitmapTag(block, "solid")

  -- hasBitmapTag() is a single bitmask AND — extremely fast.
  -- Ideal for per-frame collision filtering or physics layer checks.
  if world:hasBitmapTag(block, "solid") then
    lurek.log.debug("block is solid — apply collision", "phys")
  end
end

--@api-stub: Universe:queryBitmapTag
-- Returns all entities that have one specific bitmap tag
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("enemy")
  for _ = 1, 4 do
    local id = world:spawn()
    world:bitmapTag(id, "enemy")
  end

  -- queryBitmapTag() scans all entities using bitmask checks.
  -- Faster than string-tag queries for large entity counts.
  for _, id in ipairs(world:queryBitmapTag("enemy")) do
    lurek.log.debug("enemy=" .. id, "ai")
  end
end

--@api-stub: Universe:queryBitmapAny
-- Returns entities that have ANY of the listed bitmap tags (OR query)
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("enemy")
  world:defineTag("hazard")
  local a = world:spawn(); world:bitmapTag(a, "enemy")
  local b = world:spawn(); world:bitmapTag(b, "hazard")

  -- queryBitmapAny() returns entities matching at least ONE tag from the list.
  -- Use for "anything dangerous" queries in collision response.
  local danger = world:queryBitmapAny({ "enemy", "hazard" })
  lurek.log.info("dangerous entities=" .. #danger, "ai")
end

--@api-stub: Universe:queryBitmapAll
-- Returns entities that have ALL of the listed bitmap tags (AND query)
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("solid")
  world:defineTag("visible")
  local block = world:spawn()
  world:bitmapTag(block, "solid")
  world:bitmapTag(block, "visible")

  -- queryBitmapAll() requires EVERY listed tag to be present.
  -- Use for intersection queries: "solid AND visible" = drawable collidables.
  for _, id in ipairs(world:queryBitmapAll({ "solid", "visible" })) do
    lurek.log.debug("draw solid block=" .. id, "ecs")
  end
end

--@api-stub: Universe:getBitmapTagBit
-- Returns the bit index assigned to a bitmap tag name (or nil if undefined)
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("player")

  -- getBitmapTagBit() lets you inspect the internal bit layout.
  -- Returns nil if the tag name was never defined.
  local bit = world:getBitmapTagBit("player")
  if bit then lurek.log.info("player tag stored at bit " .. bit, "ecs") end

  local unknown = world:getBitmapTagBit("nonexistent")
  assert(unknown == nil)
end

--@api-stub: Universe:hasBlueprint
-- Returns true if a named blueprint is registered in this universe
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("goblin", { health = { hp = 3, max = 3 } })

  -- hasBlueprint() checks if a template is available for spawning.
  -- Use it to guard data-driven spawning from mods or level files.
  if world:hasBlueprint("goblin") then
    lurek.log.info("goblin blueprint ready for spawning", "ecs")
  end
end

--@api-stub: Universe:removeBlueprint
-- Removes a named blueprint from this universe
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("goblin", { health = { hp = 3, max = 3 } })

  -- removeBlueprint() unregisters a template. Returns true if one was removed.
  -- Use when unloading a mod or resetting level-specific templates.
  world:removeBlueprint("goblin")
  assert(not world:hasBlueprint("goblin"))
end

--@api-stub: Universe:listBlueprints
-- Returns an array of all registered blueprint names
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("goblin", { health = { hp = 3, max = 3 } })
  world:defineBlueprint("orc",    { health = { hp = 7, max = 7 } })

  -- listBlueprints() returns names of all templates. Useful for editors,
  -- spawn menus, or validating that all required templates loaded.
  for _, name in ipairs(world:listBlueprints()) do
    lurek.log.debug("blueprint: " .. name, "ecs")
  end
end

--@api-stub: Universe:getBlueprintComponents
-- Returns the component table stored in a blueprint definition
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("goblin", { health = { hp = 3, max = 3 }, speed = { value = 80 } })

  -- getBlueprintComponents() returns the template's component table.
  -- Use to preview or display blueprint data in editors or tooltips.
  local comps = world:getBlueprintComponents("goblin")
  if comps then
    lurek.log.info("goblin starts at hp=" .. comps.health.hp .. " speed=" .. comps.speed.value, "ecs")
  end
end

--@api-stub: Universe:getParent
-- Returns the parent entity id for a child (or nil if no parent)
do
  local world = lurek.ecs.newUniverse()
  local parent = world:spawn()
  local child  = world:spawn()
  world:setParent(child, parent)

  -- getParent() reads the hierarchy link. Returns nil for root entities.
  -- Use for scene graph traversal: weapons attached to hands, UI to panels.
  if world:getParent(child) == parent then
    lurek.log.debug("child is attached to parent", "scene")
  end
end

--@api-stub: Universe:getChildren
-- Returns an array of child entity ids for a parent entity
do
  local world = lurek.ecs.newUniverse()
  local root = world:spawn()
  for _ = 1, 3 do
    local c = world:spawn()
    world:setParent(c, root)
  end

  -- getChildren() returns direct children only (not recursive).
  -- Use for inventory slots, UI container children, or limb hierarchies.
  local kids = world:getChildren(root)
  for _, id in ipairs(kids) do
    lurek.log.debug("child=" .. id, "scene")
  end
end

--@api-stub: Universe:killRecursive
-- Kills an entity and all of its descendant children recursively
do
  local world = lurek.ecs.newUniverse()
  local wagon = world:spawn()
  local driver = world:spawn(); world:setParent(driver, wagon)
  local cargo  = world:spawn(); world:setParent(cargo, wagon)

  -- killRecursive() destroys the entity AND every child in its subtree.
  -- Use when destroying a composite object: a vehicle kills its passengers,
  -- a UI panel kills its child widgets.
  world:killRecursive(wagon)
  assert(not world:isAlive(wagon))
  assert(not world:isAlive(driver))
  assert(not world:isAlive(cargo))
end

--@api-stub: Universe:serialize
-- Serializes the entire universe state into a Lua table snapshot
do
  local world = lurek.ecs.newUniverse()
  local hero = world:spawn()
  world:set(hero, "position", { x = 5, y = 7 })
  world:set(hero, "inventory", { gold = 42 })

  -- serialize() captures all entities and their components as a plain table.
  -- The result can be saved to disk (via lurek.save or lurek.data.encode)
  -- and later restored with deserialize().
  local snapshot = world:serialize()
  lurek.log.info("snapshot entries=" .. #snapshot, "save")
end

--@api-stub: Universe:deserialize
-- Replaces universe state from a previously serialized snapshot
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "position", { x = 1, y = 2 })

  -- Save state, destroy everything, then restore from snapshot.
  -- This is the save/load workflow: serialize → write to file → read → deserialize.
  local snap = world:serialize()
  world:clear()
  assert(world:getEntityCount() == 0)

  world:deserialize(snap)
  assert(world:getEntityCount() > 0)
  lurek.log.info("deserialized entity count=" .. world:getEntityCount(), "save")
end

--@api-stub: Universe:flushObservers
-- Delivers queued component add/remove events to registered observer callbacks
do
  local world = lurek.ecs.newUniverse()

  -- Observers are deferred: component changes queue events, flushObservers()
  -- delivers them. This prevents infinite recursion (observer adds component → triggers observer).
  -- Call flushObservers() once per frame after all mutations are done.
  world:onComponentAdded("health", function(id, name)
    lurek.log.info("health added to entity " .. id, "ecs")
  end)

  local e = world:spawn()
  world:set(e, "health", { hp = 10, max = 10 })  -- queues the event

  -- Flush delivers queued events to callbacks NOW
  world:flushObservers()
end

--@api-stub: Universe:getRelated
-- Returns target entity ids linked from an entity by a named relation
do
  local world = lurek.ecs.newUniverse()
  local hero = world:spawn()
  local sword = world:spawn()
  local shield = world:spawn()
  world:addRelation(hero, "equips", sword)
  world:addRelation(hero, "equips", shield)

  -- getRelated() returns all targets for a directed relation.
  -- Relations are many-to-many: one entity can relate to multiple targets
  -- under the same relation name. Use for equipment, allies, quest links.
  for _, item in ipairs(world:getRelated(hero, "equips")) do
    lurek.log.debug("equipped item=" .. item, "ecs")
  end
end

--@api-stub: Universe:clearRelations
-- Removes all targets for one named relation from an entity
do
  local world = lurek.ecs.newUniverse()
  local boss = world:spawn()
  for _ = 1, 3 do
    local m = world:spawn()
    world:addRelation(boss, "minions", m)
  end

  -- clearRelations() removes all links under that relation name.
  -- Use when a boss dies and all minion links should be severed.
  world:clearRelations(boss, "minions")
  assert(#world:getRelated(boss, "minions") == 0)
end

--@api-stub: Universe:addRelation
-- Adds a named directed relation from one entity to another
do
  local world = lurek.ecs.newUniverse()
  local parent = world:spawn()
  local child  = world:spawn()

  -- addRelation(from, name, to) creates a directed link.
  -- Relations are separate from hierarchy (setParent). Use them for
  -- game-logic links: "child_of", "owns", "targets", "heals".
  world:addRelation(child, "child_of", parent)
  world:addRelation(parent, "owns", child)
  lurek.log.info("relations established", "ecs")
end

--@api-stub: Universe:addSystem
-- Registers a Lua system table with optional priority, phase, name, and dependencies
do
  local world = lurek.ecs.newUniverse()

  -- Systems are tables with update/render/draw methods and optional metadata.
  -- The `opts` table controls execution order and phase assignment.
  local physics_sys = {
    update = function(self, w, dt)
      for _, id in ipairs(w:query("position", "velocity")) do
        local p, v = w:get(id, "position"), w:get(id, "velocity")
        p.x = p.x + v.x * dt
        p.y = p.y + v.y * dt
      end
    end
  }

  -- priority: lower runs first. phase: groups systems for updatePhase().
  -- name: for debugging. after: dependency ordering (runs after listed systems).
  world:addSystem(physics_sys, {
    priority = 10,
    phase = "update",
    name = "physics",
  })
  lurek.log.info("system count: " .. world:getSystemCount(), "ecs")
end

--@api-stub: Universe:defineBlueprint
-- Defines a named entity blueprint (template) from a component table
do
  local world = lurek.ecs.newUniverse()

  -- Blueprints are component templates. Define once, spawn many.
  -- The component table maps component names to their default values.
  -- When spawned, each entity gets a deep copy of these defaults.
  world:defineBlueprint("enemy", {
    health   = { hp = 100, max = 100 },
    position = { x = 0, y = 0 },
    ai       = { state = "patrol", aggro_range = 150 },
  })
  lurek.log.info("enemy blueprint defined", "ecs")
end

--@api-stub: Universe:each
-- Iterates entities with one component, calling a callback for each match
do
  local world = lurek.ecs.newUniverse()
  local e1 = world:spawn(); world:set(e1, "damage_flash", { timer = 0.2 })
  local e2 = world:spawn(); world:set(e2, "damage_flash", { timer = 0.5 })

  -- each() is a callback-style iterator for a single component.
  -- The callback receives (entity_id, component_value).
  -- Simpler than query() when you only need one component.
  world:each("damage_flash", function(eid, flash)
    lurek.log.info("entity " .. eid .. " flash timer=" .. flash.timer, "ecs")
  end)
end

--@api-stub: Universe:extendBlueprint
-- Defines a blueprint that inherits from a parent and applies overrides
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("unit", {
    health   = { hp = 100, max = 100 },
    position = { x = 0, y = 0 },
  })

  -- extendBlueprint(child_name, parent_name, overrides) creates inheritance.
  -- The child inherits all parent components and applies overrides on top.
  -- Use for enemy variants: goblin → goblin_shaman (more hp, adds mana).
  world:extendBlueprint("boss", "unit", {
    health = { hp = 500, max = 500 },  -- overrides parent hp
  })

  -- "boss" now has position from "unit" and boosted health
  local comps = world:getBlueprintComponents("boss")
  lurek.log.info("boss hp=" .. comps.health.hp, "ecs")
end

--@api-stub: Universe:hasRelation
-- Returns true if a specific directed relation exists between two entities
do
  local world = lurek.ecs.newUniverse()
  local a = world:spawn()
  local b = world:spawn()
  world:addRelation(a, "ally", b)

  -- hasRelation() checks one specific link. Use for "is X allied with Y?"
  -- or "does player have quest from NPC?" checks.
  local allied = world:hasRelation(a, "ally", b)
  lurek.log.info("a allied with b: " .. tostring(allied), "ecs")

  -- Relations are directional: a→b exists, but b→a does not (unless added).
  assert(not world:hasRelation(b, "ally", a))
end

--@api-stub: Universe:onComponentAdded
-- Registers a callback fired when a specific component is added to any entity
do
  local world = lurek.ecs.newUniverse()

  -- onComponentAdded() registers an observer. The callback is queued
  -- (not called immediately) and delivered during flushObservers().
  -- Use for reactive systems: auto-add physics body when "collider" appears.
  world:onComponentAdded("health", function(eid, comp_name)
    lurek.log.info("health component added to entity " .. eid, "ecs")
  end)

  local e = world:spawn()
  world:set(e, "health", { hp = 100, max = 100 })
  world:flushObservers()  -- delivers the queued event
end

--@api-stub: Universe:onComponentRemoved
-- Registers a callback fired when a specific component is removed from any entity
do
  local world = lurek.ecs.newUniverse()

  -- onComponentRemoved() fires when remove() is called or an entity is killed.
  -- Use for cleanup: release physics bodies, stop sounds, remove UI elements.
  world:onComponentRemoved("sprite", function(eid, comp_name)
    lurek.log.info("sprite removed from entity " .. eid .. " — freeing texture", "ecs")
  end)

  local e = world:spawn()
  world:set(e, "sprite", { path = "hero.png" })
  world:remove(e, "sprite")
  world:flushObservers()  -- delivers the queued remove event
end

--@api-stub: Universe:queryNot
-- Returns entities matching required components but EXCLUDING forbidden ones
do
  local world = lurek.ecs.newUniverse()
  local alive = world:spawn()
  world:set(alive, "health", { hp = 100 })
  world:set(alive, "position", { x = 0, y = 0 })

  local dead = world:spawn()
  world:set(dead, "position", { x = 50, y = 50 })
  world:set(dead, "dead_marker", {})

  -- queryNot(required, excluded) is a powerful filter.
  -- First table = required components (AND), second = excluded (NOT).
  -- Here: entities with "position" but WITHOUT "dead_marker".
  local active = world:queryNot({ "position" }, { "dead_marker" })
  lurek.log.info("active entities (alive with position)=" .. #active, "ecs")
end

--@api-stub: Universe:removeRelation
-- Removes a specific directed relation between two entities
do
  local world = lurek.ecs.newUniverse()
  local a = world:spawn()
  local b = world:spawn()
  world:addRelation(a, "ally", b)

  -- removeRelation() removes one specific link (from, name, to).
  -- Use when an alliance breaks, an item is unequipped, or a quest ends.
  world:removeRelation(a, "ally", b)
  assert(not world:hasRelation(a, "ally", b))
  lurek.log.info("alliance broken", "ecs")
end

--@api-stub: Universe:set
-- Stores or replaces a component value on an entity
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()

  -- set(id, name, value) stores any Lua value as a component.
  -- Tables are the most common: they hold structured data.
  -- Primitives (numbers, strings, booleans) also work.
  world:set(e, "position", { x = 100, y = 200 })
  world:set(e, "velocity", { vx = 5, vy = 0 })
  world:set(e, "name", "goblin_01")       -- string component
  world:set(e, "layer", 3)                -- number component
  world:set(e, "active", true)            -- boolean component

  -- Calling set() again on the same component REPLACES the value.
  world:set(e, "position", { x = 999, y = 999 })
  lurek.log.info("position replaced, x=" .. world:get(e, "position").x, "ecs")
end

--@api-stub: Universe:setParent
-- Sets the parent entity for a child (or nil to detach)
do
  local world = lurek.ecs.newUniverse()
  local parent = world:spawn()
  local child  = world:spawn()

  -- setParent(child, parent) establishes a hierarchy link.
  -- Pass nil as parent to detach: setParent(child, nil).
  -- Use for scene graphs, UI tree, or composite game objects.
  world:setParent(child, parent)
  lurek.log.info("parent of child: " .. world:getParent(child), "ecs")

  -- Detach the child
  world:setParent(child, nil)
  assert(world:getParent(child) == nil)
end

--@api-stub: Universe:spawnBlueprint
-- Spawns an entity from a named blueprint with optional component overrides
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("goblin", {
    health   = { hp = 40, max = 40 },
    position = { x = 0, y = 0 },
    ai       = { state = "patrol" },
  })

  -- spawnBlueprint() creates an entity with all blueprint components pre-set.
  -- Pass an override table to customize the spawn (e.g. different position).
  -- Overrides merge with blueprint defaults.
  local e = world:spawnBlueprint("goblin", { position = { x = 300, y = 200 } })

  local pos = world:get(e, "position")
  local hp  = world:get(e, "health")
  lurek.log.info("spawned goblin at x=" .. pos.x .. " hp=" .. hp.hp, "ecs")
end

--@api-stub: Universe:spawnBulk
-- Spawns multiple entities from a blueprint in a single call
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("particle", {
    position = { x = 0, y = 0 },
    lifetime = { remaining = 1.0 },
  })

  -- spawnBulk(name, count, overrides) spawns N entities from a blueprint.
  -- Much faster than calling spawnBlueprint() in a loop.
  -- Use for particle bursts, wave spawning, or populating grids.
  local ids = world:spawnBulk("particle", 50, {})
  lurek.log.info("bulk spawned " .. #ids .. " particles", "ecs")
end

-- Universe type introspection

--@api-stub: Universe:type
-- Returns the Lua-visible type name string for this universe handle
do
  local world = lurek.ecs.newUniverse()

  -- type() returns "LUniverse" — the internal Lua userdata type name.
  -- Useful for debug printing or polymorphic type checks.
  lurek.log.info("type=" .. world:type(), "ecs")
end

--@api-stub: Universe:queryMulti
-- Iterates entities matching multiple components via callback (avoids table allocation)
do
  local world = lurek.ecs.newUniverse()
  local a = world:spawn()
  world:set(a, "pos", { x = 1, y = 2 })
  world:set(a, "vel", { x = 3, y = 4 })

  -- queryMulti() is a callback-based multi-component query.
  -- Unlike query() which returns a table of ids, queryMulti() calls
  -- your function directly with (id, comp1, comp2, ...) — zero allocation.
  -- Use in hot loops where GC pressure matters.
  world:queryMulti({ "pos", "vel" }, function(id, pos, vel)
    pos.x = pos.x + vel.x
    pos.y = pos.y + vel.y
  end)

  local pos = world:get(a, "pos")
  lurek.log.info("after queryMulti: x=" .. pos.x .. " y=" .. pos.y, "ecs")
end

--@api-stub: Universe:getDirtyEntities
-- Returns entity ids marked dirty by recent component mutations
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "hp", 50)

  -- getDirtyEntities() returns ids that had components added, removed, or replaced
  -- since the last flush. Use for incremental updates: only re-render changed entities,
  -- only re-sync changed state to network.
  local dirty = world:getDirtyEntities()
  lurek.log.info("dirty count=" .. #dirty, "ecs")

  -- After flushObservers(), the dirty list resets.
  world:flushObservers()
  lurek.log.info("after flush dirty=" .. #world:getDirtyEntities(), "ecs")
end

--@api-stub: Universe:updatePhase
-- Runs only systems assigned to a specific named phase
do
  local world = lurek.ecs.newUniverse()

  -- Phases let you split the frame into logical stages.
  -- Each system is assigned a phase via addSystem opts. updatePhase()
  -- runs only systems in that phase, in priority order.
  local InputSys = {
    update = function(self, w, dt)
      lurek.log.debug("processing input", "ecs")
    end
  }
  local LogicSys = {
    update = function(self, w, dt)
      lurek.log.debug("running game logic", "ecs")
    end
  }

  world:addSystem(InputSys, { phase = "pre_update", priority = 0 })
  world:addSystem(LogicSys, { phase = "update",     priority = 10 })

  -- Call phases in order — gives you explicit control over execution stages.
  function lurek.process(dt)
    world:updatePhase("pre_update", dt)
    world:updatePhase("update", dt)
  end
end

--@api-stub: Universe:snapshot
-- Serializes the universe into a snapshot table (alias for serialize)
do
  local world = lurek.ecs.newUniverse()
  local hero = world:spawn()
  world:set(hero, "hp", 42)
  world:set(hero, "gold", 100)

  -- snapshot() and serialize() are equivalent. Both produce a table
  -- that can be stored and later applied with applySnapshot() or deserialize().
  local snap = world:snapshot()
  world:clear()
  world:applySnapshot(snap)
  lurek.log.info("restored entity count=" .. world:getEntityCount(), "ecs")
end

--@api-stub: Universe:applySnapshot
-- Restores universe state from a previously captured snapshot table
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "score", 99)

  -- applySnapshot() replaces universe state from a snapshot.
  -- Pair with snapshot() for undo/redo, quicksave, or state rollback.
  local snap = world:snapshot()
  world:clear()
  world:applySnapshot(snap)

  local ids = world:getEntities()
  lurek.log.info("restored score=" .. world:get(ids[1], "score"), "ecs")
end

--@api-stub: LUniverse:type
-- Returns the Lua-visible type name for this universe handle
do
  local u = lurek.ecs.newUniverse()
  -- Returns "LUniverse" — the registered Lua userdata type name.
  local t = u:type()
  assert(t == "LUniverse")
end

--@api-stub: LUniverse:typeOf
-- Returns whether this universe handle matches a supported type name
do
  local u = lurek.ecs.newUniverse()
  -- typeOf() checks against "LUniverse" and "Object" (base type).
  -- Use for runtime polymorphism when handling mixed userdata.
  assert(u:typeOf("LUniverse") == true)
  assert(u:typeOf("Object") == true)
  assert(u:typeOf("SomethingElse") == false)
end

--@api-stub: LUniverse:takeSnapshotDiff
-- Returns and clears accumulated ECS snapshot diff data (adds, removes, deletes)
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "hp", 10)     -- triggers added_components entry
  world:remove(e, "hp")      -- triggers removed_components entry
  world:kill(e)              -- triggers deleted_entities entry

  -- takeSnapshotDiff() returns a table with four arrays:
  --   added_components: {entity_id, name} pairs for new components
  --   removed_components: {entity_id, name} pairs for removed components
  --   deleted_entities: ids of killed entities
  --   dirty_entities: ids of any mutated entities
  -- Use for network replication: send only the diff instead of full state.
  local diff = world:takeSnapshotDiff()
  lurek.log.info(
    "diff: added=" .. #diff.added_components ..
    " removed=" .. #diff.removed_components ..
    " deleted=" .. #diff.deleted_entities,
    "ecs"
  )
end

print("content/examples/ecs.lua")

-- =============================================================================
-- STUBS: 65 uncovered lurek.ecs API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LUniverse methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LUniverse:spawn -----------------------------------------------
--@api-stub: LUniverse:spawn
-- Creates a new entity in this universe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:spawn()  -- -> integer
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:kill ------------------------------------------------
--@api-stub: LUniverse:kill
-- Deletes an entity and removes its components from this universe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:kill(1)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:isAlive ---------------------------------------------
--@api-stub: LUniverse:isAlive
-- Returns whether an entity id currently exists in this universe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:isAlive(1)  -- -> boolean
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:set -------------------------------------------------
--@api-stub: LUniverse:set
-- Stores or replaces a component value on an entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:set(1, "hero", 42)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:get -------------------------------------------------
--@api-stub: LUniverse:get
-- Returns a component value from an entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:get(1, "hero")  -- -> LuaValue
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:has -------------------------------------------------
--@api-stub: LUniverse:has
-- Returns whether an entity has a named component.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:has(1, "hero")  -- -> boolean
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:remove ----------------------------------------------
--@api-stub: LUniverse:remove
-- Removes a named component from an entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:remove(1, "hero")
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getComponents ---------------------------------------
--@api-stub: LUniverse:getComponents
-- Returns component names currently stored on an entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getComponents(1)  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:query -----------------------------------------------
--@api-stub: LUniverse:query
-- Returns entities that have all component names passed as varargs.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:query(...)  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:each ------------------------------------------------
--@api-stub: LUniverse:each
-- Iterates entities with one component and calls a Lua callback for each match.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:each("hero", function() end)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getEntities -----------------------------------------
--@api-stub: LUniverse:getEntities
-- Returns all live entity ids in this universe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getEntities()  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getEntityCount --------------------------------------
--@api-stub: LUniverse:getEntityCount
-- Returns the number of live entities in this universe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getEntityCount()  -- -> integer
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:addSystem -------------------------------------------
--@api-stub: LUniverse:addSystem
-- Registers a Lua system table with optional phase, priority, name, and dependency metadata.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:addSystem(system, [opts])
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:removeSystem ----------------------------------------
--@api-stub: LUniverse:removeSystem
-- Removes a previously registered Lua system table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:removeSystem(system)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:update ----------------------------------------------
--@api-stub: LUniverse:update
-- Runs registered update-phase systems with a frame delta.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:update(0.016)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:render ----------------------------------------------
--@api-stub: LUniverse:render
-- Runs registered render-phase systems using their render or draw callbacks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:render()
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:emit ------------------------------------------------
--@api-stub: LUniverse:emit
-- Calls matching event-named functions on registered systems.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:emit(...)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getSystemCount --------------------------------------
--@api-stub: LUniverse:getSystemCount
-- Returns the number of registered systems.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getSystemCount()  -- -> integer
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:updatePhase -----------------------------------------
--@api-stub: LUniverse:updatePhase
-- Runs registered systems assigned to a named phase.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:updatePhase(phase, 0.016)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getDirtyEntities ------------------------------------
--@api-stub: LUniverse:getDirtyEntities
-- Returns entities marked dirty by recent ECS mutations.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getDirtyEntities()  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:queryMulti ------------------------------------------
--@api-stub: LUniverse:queryMulti
-- Iterates entities that have all component names from a table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:queryMulti(names_table, function() end)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:snapshot --------------------------------------------
--@api-stub: LUniverse:snapshot
-- Serializes this universe into a Lua table snapshot.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:snapshot()  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:applySnapshot ---------------------------------------
--@api-stub: LUniverse:applySnapshot
-- Replaces this universe state from a Lua table snapshot.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:applySnapshot(snapshot)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:clear -----------------------------------------------
--@api-stub: LUniverse:clear
-- Clears all entities, components, systems, and ECS state from this universe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:clear()
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:release ---------------------------------------------
--@api-stub: LUniverse:release
-- Releases universe contents by clearing all ECS state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:release()
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:addTag ----------------------------------------------
--@api-stub: LUniverse:addTag
-- Adds a string tag to an entity. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:addTag(1, "enemy")
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:removeTag -------------------------------------------
--@api-stub: LUniverse:removeTag
-- Removes a string tag from an entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:removeTag(1, "enemy")
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:hasTag ----------------------------------------------
--@api-stub: LUniverse:hasTag
-- Returns whether an entity has a string tag.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:hasTag(1, "enemy")  -- -> boolean
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getTags ---------------------------------------------
--@api-stub: LUniverse:getTags
-- Returns string tags assigned to an entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getTags(1)  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getEntitiesByTag ------------------------------------
--@api-stub: LUniverse:getEntitiesByTag
-- Returns entities that have a string tag.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getEntitiesByTag("enemy")  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:setLayer --------------------------------------------
--@api-stub: LUniverse:setLayer
-- Assigns a numeric layer to an entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:setLayer(1, 1)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getLayer --------------------------------------------
--@api-stub: LUniverse:getLayer
-- Returns the numeric layer assigned to an entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getLayer(1)  -- -> integer
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getEntitiesByLayer ----------------------------------
--@api-stub: LUniverse:getEntitiesByLayer
-- Returns entities assigned to a numeric layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getEntitiesByLayer(1)  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getEntitiesSorted -----------------------------------
--@api-stub: LUniverse:getEntitiesSorted
-- Returns live entities sorted by ECS layer and stable entity ordering.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getEntitiesSorted()  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:defineTag -------------------------------------------
--@api-stub: LUniverse:defineTag
-- Defines a bitmap tag name and assigns it a bit slot.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:defineTag("hero")  -- -> integer
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:bitmapTag -------------------------------------------
--@api-stub: LUniverse:bitmapTag
-- Adds a bitmap tag to an entity, defining the tag if needed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:bitmapTag(1, "hero")  -- -> integer
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:bitmapUntag -----------------------------------------
--@api-stub: LUniverse:bitmapUntag
-- Removes a bitmap tag from an entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:bitmapUntag(1, "hero")
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:hasBitmapTag ----------------------------------------
--@api-stub: LUniverse:hasBitmapTag
-- Returns whether an entity has a bitmap tag.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:hasBitmapTag(1, "hero")  -- -> boolean
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:queryBitmapTag --------------------------------------
--@api-stub: LUniverse:queryBitmapTag
-- Returns entities with one bitmap tag.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:queryBitmapTag("hero")  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:queryBitmapAny --------------------------------------
--@api-stub: LUniverse:queryBitmapAny
-- Returns entities with at least one bitmap tag from a list.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:queryBitmapAny(names)  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:queryBitmapAll --------------------------------------
--@api-stub: LUniverse:queryBitmapAll
-- Returns entities that have every bitmap tag from a list.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:queryBitmapAll(names)  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getBitmapTagBit -------------------------------------
--@api-stub: LUniverse:getBitmapTagBit
-- Returns the bit index assigned to a bitmap tag name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getBitmapTagBit("hero")  -- -> LuaValue
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:defineBlueprint -------------------------------------
--@api-stub: LUniverse:defineBlueprint
-- Defines a named entity blueprint from a component table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:defineBlueprint("hero", components)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:extendBlueprint -------------------------------------
--@api-stub: LUniverse:extendBlueprint
-- Defines a blueprint that inherits from a parent blueprint and applies overrides.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:extendBlueprint("hero", parent, overrides)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:spawnBlueprint --------------------------------------
--@api-stub: LUniverse:spawnBlueprint
-- Spawns an entity from a named blueprint with optional component overrides.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:spawnBlueprint("hero", [overrides])  -- -> integer
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:hasBlueprint ----------------------------------------
--@api-stub: LUniverse:hasBlueprint
-- Returns whether a named blueprint exists.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:hasBlueprint("hero")  -- -> boolean
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:removeBlueprint -------------------------------------
--@api-stub: LUniverse:removeBlueprint
-- Removes a named blueprint from this universe.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:removeBlueprint("hero")  -- -> boolean
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:listBlueprints --------------------------------------
--@api-stub: LUniverse:listBlueprints
-- Returns names of all registered blueprints.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:listBlueprints()  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getBlueprintComponents ------------------------------
--@api-stub: LUniverse:getBlueprintComponents
-- Returns the component table stored for a blueprint.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getBlueprintComponents("hero")  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:setParent -------------------------------------------
--@api-stub: LUniverse:setParent
-- Sets or clears the parent entity for a child entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:setParent(child_id, [parent_id])
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getParent -------------------------------------------
--@api-stub: LUniverse:getParent
-- Returns the parent entity id for a child entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getParent(child_id)  -- -> LuaValue
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getChildren -----------------------------------------
--@api-stub: LUniverse:getChildren
-- Returns child entity ids for a parent entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getChildren(parent_id)  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:killRecursive ---------------------------------------
--@api-stub: LUniverse:killRecursive
-- Deletes an entity and all descendant entities in its hierarchy.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:killRecursive(1)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:queryNot --------------------------------------------
--@api-stub: LUniverse:queryNot
-- Returns entities that include one component set and exclude another component set.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:queryNot(with_tbl, without_tbl)  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:serialize -------------------------------------------
--@api-stub: LUniverse:serialize
-- Serializes this universe into a Lua table snapshot.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:serialize()  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:deserialize -----------------------------------------
--@api-stub: LUniverse:deserialize
-- Replaces this universe state from a serialized Lua snapshot.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:deserialize(snapshot)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:onComponentAdded ------------------------------------
--@api-stub: LUniverse:onComponentAdded
-- Registers a callback for queued component-add events with a given component name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:onComponentAdded("hero", cb)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:onComponentRemoved ----------------------------------
--@api-stub: LUniverse:onComponentRemoved
-- Registers a callback for queued component-remove events with a given component name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:onComponentRemoved("hero", cb)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:flushObservers --------------------------------------
--@api-stub: LUniverse:flushObservers
-- Delivers queued component add and remove events to registered observer callbacks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:flushObservers()
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:spawnBulk -------------------------------------------
--@api-stub: LUniverse:spawnBulk
-- Spawns multiple entities from a blueprint using shared optional overrides.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:spawnBulk("hero", 10, [overrides])  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:addRelation -----------------------------------------
--@api-stub: LUniverse:addRelation
-- Adds a named directed relation from one entity to another.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:addRelation(from, "hero", to)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:getRelated ------------------------------------------
--@api-stub: LUniverse:getRelated
-- Returns targets linked from an entity by a named relation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:getRelated(from, "hero")  -- -> table
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:removeRelation --------------------------------------
--@api-stub: LUniverse:removeRelation
-- Removes a named directed relation between two entities.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:removeRelation(from, "hero", to)
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:clearRelations --------------------------------------
--@api-stub: LUniverse:clearRelations
-- Removes every target for one named relation from an entity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:clearRelations(from, "hero")
-- (replace lUniverse_stub with your real LUniverse instance above)

-- ---- Stub: LUniverse:hasRelation -----------------------------------------
--@api-stub: LUniverse:hasRelation
-- Returns whether a named directed relation exists between two entities.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lUniverse_stub:hasRelation(from, "hero", to)  -- -> boolean
-- (replace lUniverse_stub with your real LUniverse instance above)
