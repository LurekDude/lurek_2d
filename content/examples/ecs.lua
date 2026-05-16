-- content/examples/ecs.lua
-- lurek.ecs API examples.
-- Run: cargo run -- content/examples/ecs.lua

--@api-stub: lurek.ecs.newUniverse
-- Creates an empty ECS universe for entity, component, system, and relationship management
do
  local world = lurek.ecs.newUniverse()
  local hero = world:spawn()
  world:set(hero, "position", { x = 0, y = 0 })
  lurek.log.info("universe ready, first id=" .. hero, "ecs")
end

-- Universe methods

--@api-stub: Universe:spawn
-- Performs the spawn operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  local enemy = world:spawn()
  world:set(enemy, "position", { x = 320, y = 240 })
  world:set(enemy, "health",   { hp = 5, max = 5 })
end

--@api-stub: Universe:kill
-- Performs the kill operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  local bullet = world:spawn()
  world:set(bullet, "position", { x = 100, y = 100 })
  world:kill(bullet)
end

--@api-stub: Universe:isAlive
-- Returns true if this universe alive.
do
  local world = lurek.ecs.newUniverse()
  local id = world:spawn()
  world:kill(id)
  if not world:isAlive(id) then lurek.log.debug("target gone", "ecs") end
end

--@api-stub: Universe:get
-- Returns the  of this universe.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "position", { x = 10, y = 20 })
  local pos = world:get(e, "position")
  pos.x = pos.x + 1
end

--@api-stub: Universe:has
-- Returns true if this universe has a .
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "stunned", { ticks = 30 })
  if world:has(e, "stunned") then lurek.log.debug("skip ai", "ecs") end
end

--@api-stub: Universe:remove
-- Removes a  from this universe.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "burning", { ticks = 60 })
  world:remove(e, "burning")
end

--@api-stub: Universe:getComponents
-- Returns the components of this universe.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "position", { x = 0, y = 0 })
  world:set(e, "sprite",   { path = "img/hero.png" })
  for _, name in ipairs(world:getComponents(e)) do lurek.log.debug(name, "inspect") end
end

--@api-stub: Universe:query
-- Performs the query operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "position", { x = 0, y = 0 })
  world:set(e, "velocity", { x = 1, y = 0 })
  for _, id in ipairs(world:query("position", "velocity")) do
    local p, v = world:get(id, "position"), world:get(id, "velocity")
    p.x, p.y = p.x + v.x, p.y + v.y
  end
end

--@api-stub: Universe:getEntities
-- Returns the entities of this universe.
do
  local world = lurek.ecs.newUniverse()
  for _ = 1, 5 do world:spawn() end
  local all = world:getEntities()
  lurek.log.info("total entities=" .. #all, "ecs")
end

--@api-stub: Universe:getEntityCount
-- Returns the number of entity items in this universe.
do
  local world = lurek.ecs.newUniverse()
  for _ = 1, 12 do world:spawn() end
  if world:getEntityCount() > 1000 then lurek.log.warn("entity budget exceeded", "ecs") end
end

--@api-stub: Universe:removeSystem
-- Removes a system from this universe.
do
  local world = lurek.ecs.newUniverse()
  local ai_system = { update = function() end }
  world:addSystem(ai_system, { priority = 50 })
  world:removeSystem(ai_system)
end

--@api-stub: Universe:update
-- Advances this universe by the given delta time.
do
  local world = lurek.ecs.newUniverse()
  local move_system = {
    update = function(_, w, dt)
      for _, id in ipairs(w:query("position", "velocity")) do
        local p, v = w:get(id, "position"), w:get(id, "velocity")
        p.x, p.y = p.x + v.x * dt, p.y + v.y * dt
      end
    end
  }
  world:addSystem(move_system, { priority = 10 })
  function lurek.process(dt) world:update(dt) end
end

--@api-stub: Universe:render
-- Draws or renders this universe to the current render target.
do
  local world = lurek.ecs.newUniverse()
  local draw_system = {
    render = function(_, w)
      for _, id in ipairs(w:query("position", "sprite")) do
        local p = w:get(id, "position")
        lurek.render.rectangle("fill", p.x, p.y, 16, 16)
      end
    end
  }
  world:addSystem(draw_system, { priority = 100 })
  function lurek.draw() world:render() end
end

--@api-stub: Universe:emit
-- Performs the emit operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  local hp_system = {
    damage = function(_, w, id, amount)
      local h = w:get(id, "health"); h.hp = h.hp - amount
    end
  }
  world:addSystem(hp_system)
  local target = world:spawn(); world:set(target, "health", { hp = 10, max = 10 })
  world:emit("damage", target, 3)
end

--@api-stub: Universe:getSystemCount
-- Returns the number of system items in this universe.
do
  local world = lurek.ecs.newUniverse()
  world:addSystem({ update = function() end })
  world:addSystem({ render = function() end })
  lurek.log.info("systems registered=" .. world:getSystemCount(), "ecs")
end

--@api-stub: Universe:clear
-- Clears all items from this universe.
do
  local world = lurek.ecs.newUniverse()
  for _ = 1, 5 do world:spawn() end
  world:clear()
  lurek.log.info("after clear count=" .. world:getEntityCount(), "ecs")
end

--@api-stub: Universe:release
-- Performs the release operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  world:spawn()
  world:release()
end

--@api-stub: Universe:addTag
-- Adds a tag to this universe.
do
  local world = lurek.ecs.newUniverse()
  local hero = world:spawn()
  world:addTag(hero, "player")
  world:addTag(hero, "alive")
end

--@api-stub: Universe:removeTag
-- Removes a tag from this universe.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:addTag(e, "alive")
  world:removeTag(e, "alive")
end

--@api-stub: Universe:hasTag
-- Returns true if this universe has a tag.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:addTag(e, "player")
  if world:hasTag(e, "player") then lurek.log.debug("hit player", "ecs") end
end

--@api-stub: Universe:getTags
-- Returns the tags of this universe.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:addTag(e, "player"); world:addTag(e, "invincible")
  for _, t in ipairs(world:getTags(e)) do lurek.log.debug(t, "tags") end
end

--@api-stub: Universe:getEntitiesByTag
-- Returns the entities by tag of this universe.
do
  local world = lurek.ecs.newUniverse()
  for _ = 1, 3 do local id = world:spawn(); world:addTag(id, "enemy") end
  local enemies = world:getEntitiesByTag("enemy")
  lurek.log.info("enemy count=" .. #enemies, "ecs")
end

--@api-stub: Universe:setLayer
-- Sets the layer of this universe.
do
  local world = lurek.ecs.newUniverse()
  local floor = world:spawn(); world:setLayer(floor, 0)
  local actor = world:spawn(); world:setLayer(actor, 10)
end

--@api-stub: Universe:getLayer
-- Returns the layer of this universe.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn(); world:setLayer(e, 5)
  if world:getLayer(e) >= 5 then lurek.log.debug("foreground", "ecs") end
end

--@api-stub: Universe:getEntitiesByLayer
-- Returns the entities by layer of this universe.
do
  local world = lurek.ecs.newUniverse()
  for i = 1, 4 do local id = world:spawn(); world:setLayer(id, i % 2) end
  local fg = world:getEntitiesByLayer(1)
  lurek.log.debug("layer1=" .. #fg, "ecs")
end

--@api-stub: Universe:getEntitiesSorted
-- Returns the entities sorted of this universe.
do
  local world = lurek.ecs.newUniverse()
  local a = world:spawn(); world:setLayer(a, 2)
  local b = world:spawn(); world:setLayer(b, 0)
  local order = world:getEntitiesSorted()
  for _, id in ipairs(order) do lurek.log.debug("draw=" .. id, "ecs") end
end

--@api-stub: Universe:defineTag
-- Performs the define tag operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  local bit_player = world:defineTag("player")
  local bit_enemy  = world:defineTag("enemy")
  lurek.log.info("player bit=" .. bit_player .. " enemy bit=" .. bit_enemy, "ecs")
end

--@api-stub: Universe:bitmapTag
-- Performs the bitmap tag operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("solid")
  local block = world:spawn()
  world:bitmapTag(block, "solid")
end

--@api-stub: Universe:bitmapUntag
-- Performs the bitmap untag operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("invincible")
  local hero = world:spawn(); world:bitmapTag(hero, "invincible")
  world:bitmapUntag(hero, "invincible")
end

--@api-stub: Universe:hasBitmapTag
-- Returns true if this universe has a bitmap tag.
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("solid")
  local block = world:spawn(); world:bitmapTag(block, "solid")
  if world:hasBitmapTag(block, "solid") then lurek.log.debug("collide", "phys") end
end

--@api-stub: Universe:queryBitmapTag
-- Performs the query bitmap tag operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("enemy")
  for _ = 1, 4 do local id = world:spawn(); world:bitmapTag(id, "enemy") end
  for _, id in ipairs(world:queryBitmapTag("enemy")) do lurek.log.debug("enemy=" .. id, "ai") end
end

--@api-stub: Universe:queryBitmapAny
-- Performs the query bitmap any operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("enemy"); world:defineTag("hazard")
  local a = world:spawn(); world:bitmapTag(a, "enemy")
  local b = world:spawn(); world:bitmapTag(b, "hazard")
  local danger = world:queryBitmapAny({ "enemy", "hazard" })
  lurek.log.info("danger count=" .. #danger, "ai")
end

--@api-stub: Universe:queryBitmapAll
-- Performs the query bitmap all operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("solid"); world:defineTag("visible")
  local b = world:spawn(); world:bitmapTag(b, "solid"); world:bitmapTag(b, "visible")
  for _, id in ipairs(world:queryBitmapAll({ "solid", "visible" })) do
    lurek.log.debug("draw block=" .. id, "ecs")
  end
end

--@api-stub: Universe:getBitmapTagBit
-- Returns the bitmap tag bit of this universe.
do
  local world = lurek.ecs.newUniverse()
  world:defineTag("player")
  local bit = world:getBitmapTagBit("player")
  if bit then lurek.log.info("player tag stored at bit " .. bit, "ecs") end
end

--@api-stub: Universe:hasBlueprint
-- Returns true if this universe has a blueprint.
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("goblin", { health = { hp = 3, max = 3 } })
  if world:hasBlueprint("goblin") then lurek.log.info("goblin ready", "ecs") end
end

--@api-stub: Universe:removeBlueprint
-- Removes a blueprint from this universe.
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("goblin", { health = { hp = 3, max = 3 } })
  world:removeBlueprint("goblin")
end

--@api-stub: Universe:listBlueprints
-- Performs the list blueprints operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("goblin", { health = { hp = 3, max = 3 } })
  world:defineBlueprint("orc",    { health = { hp = 7, max = 7 } })
  for _, name in ipairs(world:listBlueprints()) do lurek.log.debug(name, "blueprint") end
end

--@api-stub: Universe:getBlueprintComponents
-- Returns the blueprint components of this universe.
do
  local world = lurek.ecs.newUniverse()
  world:defineBlueprint("goblin", { health = { hp = 3, max = 3 } })
  local comps = world:getBlueprintComponents("goblin")
  if comps then lurek.log.info("goblin starts at hp=" .. comps.health.hp, "ecs") end
end

--@api-stub: Universe:getParent
-- Returns the parent of this universe.
do
  local world = lurek.ecs.newUniverse()
  local parent = world:spawn()
  local child  = world:spawn()
  world:setParent(child, parent)
  if world:getParent(child) == parent then lurek.log.debug("attached", "scene") end
end

--@api-stub: Universe:getChildren
-- Returns the children of this universe.
do
  local world = lurek.ecs.newUniverse()
  local root = world:spawn()
  for _ = 1, 3 do local c = world:spawn(); world:setParent(c, root) end
  for _, id in ipairs(world:getChildren(root)) do lurek.log.debug("child=" .. id, "scene") end
end

--@api-stub: Universe:killRecursive
-- Performs the kill recursive operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  local wagon = world:spawn()
  local driver = world:spawn(); world:setParent(driver, wagon)
  world:killRecursive(wagon)
end

--@api-stub: Universe:serialize
-- Performs the serialize operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  local hero = world:spawn(); world:set(hero, "position", { x = 5, y = 7 })
  local snapshot = world:serialize()
  lurek.log.info("snapshot entries=" .. #snapshot, "save")
end

--@api-stub: Universe:deserialize
-- Performs the deserialize operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn(); world:set(e, "position", { x = 1, y = 2 })
  local snap = world:serialize()
  world:clear()
  world:deserialize(snap)
end

--@api-stub: Universe:flushObservers
-- Performs the flush observers operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  world:onComponentAdded("health", function(id) lurek.log.info("hp added to " .. id, "ecs") end)
  local e = world:spawn(); world:set(e, "health", { hp = 10, max = 10 })
  function lurek.process() world:flushObservers() end
end

--@api-stub: Universe:getRelated
-- Returns the related of this universe.
do
  local world = lurek.ecs.newUniverse()
  local hero = world:spawn()
  local sword = world:spawn(); world:addRelation(hero, "wields", sword)
  for _, item in ipairs(world:getRelated(hero, "wields")) do lurek.log.debug("equipped=" .. item, "ecs") end
end

--@api-stub: Universe:clearRelations
-- Clears all relations items from this universe.
do
  local world = lurek.ecs.newUniverse()
  local boss = world:spawn()
  for _ = 1, 3 do local m = world:spawn(); world:addRelation(boss, "minions", m) end
  world:clearRelations(boss, "minions")
end

--@api-stub: Universe:addRelation
-- Adds a relation to this universe.
do
  local u = lurek.ecs.newUniverse()
  local parent = u:spawn()
  local child  = u:spawn()
  u:addRelation(child, "child_of", parent)
  lurek.log.info("relation added", "ecs")
end

--@api-stub: Universe:addSystem
-- Adds a system to this universe.
do
  local u = lurek.ecs.newUniverse()
  u:addSystem({
    query = {"Position", "Velocity"},
    run = function(entity, pos, vel)
      lurek.log.info("system tick", "ecs")
    end,
  })
  lurek.log.info("system count: " .. u:getSystemCount(), "ecs")
end

--@api-stub: Universe:defineBlueprint
-- Performs the define blueprint operation on this universe.
do
  local u = lurek.ecs.newUniverse()
  u:defineBlueprint("enemy", {Health={max=100}, Position={x=0,y=0}})
  lurek.log.info("blueprint defined", "ecs")
end

--@api-stub: Universe:each
-- Performs the each operation on this universe.
do
  local u = lurek.ecs.newUniverse()
  local e = u:spawn()
  u:set(e, "Tag", {})
  u:each("Tag", function(eid, tag)
    lurek.log.info("entity: " .. eid, "ecs")
  end)
end

--@api-stub: Universe:extendBlueprint
-- Performs the extend blueprint operation on this universe.
do
  local u = lurek.ecs.newUniverse()
  u:defineBlueprint("unit", {Health={max=100}, Position={x=0,y=0}})
  u:extendBlueprint("boss", "unit", {Health={max=500}})
  lurek.log.info("boss extended from unit", "ecs")
end

--@api-stub: Universe:hasRelation
-- Returns true if this universe has a relation.
do
  local u = lurek.ecs.newUniverse()
  local a = u:spawn(); local b = u:spawn()
  u:addRelation(a, "ally", b)
  lurek.log.info("has ally: " .. tostring(u:hasRelation(a, "ally", b)), "ecs")
end

--@api-stub: Universe:onComponentAdded
-- Fires the callback registered for the component added event on this universe.
do
  local u = lurek.ecs.newUniverse()
  u:onComponentAdded("Health", function(eid, comp)
    lurek.log.info("health added to " .. eid, "ecs")
  end)
  local e = u:spawn()
  u:set(e, "Health", {hp=100})
end

--@api-stub: Universe:onComponentRemoved
-- Fires the callback registered for the component removed event on this universe.
do
  local u = lurek.ecs.newUniverse()
  u:onComponentRemoved("Sprite", function(eid)
    lurek.log.info("sprite removed from " .. eid, "ecs")
  end)
  local e = u:spawn()
  u:set(e, "Sprite", {path="hero.png"})
  u:remove(e, "Sprite")
end

--@api-stub: Universe:queryNot
-- Performs the query not operation on this universe.
do
  local u = lurek.ecs.newUniverse()
  local e1 = u:spawn(); u:set(e1, "Health", {hp=100})
  local e2 = u:spawn()
  local uninjured = u:queryNot({}, {"Health"})
  lurek.log.info("without health: " .. #uninjured, "ecs")
end

--@api-stub: Universe:removeRelation
-- Removes a relation from this universe.
do
  local u = lurek.ecs.newUniverse()
  local a = u:spawn(); local b = u:spawn()
  u:addRelation(a, "ally", b)
  u:removeRelation(a, "ally", b)
  lurek.log.info("relation removed", "ecs")
end

--@api-stub: Universe:set
-- Sets the  of this universe.
do
  local u = lurek.ecs.newUniverse()
  local e = u:spawn()
  u:set(e, "Position", {x=100, y=200})
  u:set(e, "Velocity", {vx=5, vy=0})
  lurek.log.info("components set on entity " .. e, "ecs")
end

--@api-stub: Universe:setParent
-- Sets the parent of this universe.
do
  local u = lurek.ecs.newUniverse()
  local parent = u:spawn()
  local child  = u:spawn()
  u:setParent(child, parent)
  lurek.log.info("parent: " .. u:getParent(child), "ecs")
end

--@api-stub: Universe:spawnBlueprint
-- Performs the spawn blueprint operation on this universe.
do
  local u = lurek.ecs.newUniverse()
  u:defineBlueprint("goblin", {Health={max=40}, Position={x=0,y=0}})
  local e = u:spawnBlueprint("goblin", {Position={x=300,y=200}})
  lurek.log.info("spawned blueprint entity: " .. e, "ecs")
end

--@api-stub: Universe:spawnBulk
-- Performs the spawn bulk operation on this universe.
do
  local u = lurek.ecs.newUniverse()
  u:defineBlueprint("bulk_unit", {Health={max=100}, Position={x=0,y=0}})
  local ids = u:spawnBulk("bulk_unit", 50, {})
  lurek.log.info("bulk spawned: " .. #ids, "ecs")
end

-- -----------------------------------------------------------------------------
-- Universe methods
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LUniverse methods
-- -----------------------------------------------------------------------------

-- LUniverse:type / LUniverse:typeOf
-- Inspect the runtime type name and confirm object type at runtime.
--@api-stub: Universe:type
-- Returns the Lua-visible type name string for this universe handle.
do
  local world = lurek.ecs.newUniverse()
  lurek.log.info("type=" .. world:type(), "ecs")
  lurek.log.info("typeOf Universe: " .. tostring(world:typeOf("Universe")), "ecs")
end

--@api-stub: Universe:queryMulti
-- Performs the query multi operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  local a = world:spawn()
  world:set(a, "pos", { x = 1, y = 2 })
  world:set(a, "vel", { x = 3, y = 4 })
  world:queryMulti({ "pos", "vel" }, function(id, pos, vel)
    pos.x = pos.x + vel.x
    pos.y = pos.y + vel.y
  end)
end

--@api-stub: Universe:getDirtyEntities
-- Returns the dirty entities of this universe.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "hp", 50)
  local dirty = world:getDirtyEntities()
  lurek.log.info("dirty count=" .. #dirty, "ecs")
  world:flushObservers()
  lurek.log.info("after flush dirty=" .. #world:getDirtyEntities(), "ecs")
end

--@api-stub: Universe:updatePhase
-- Advances phase this universe by the given delta time.
do
  local world = lurek.ecs.newUniverse()
  local InputSys = { update = function(self, w, dt) lurek.log.debug("input", "ecs") end }
  local LogicSys = { update = function(self, w, dt) lurek.log.debug("logic", "ecs") end }
  world:addSystem(InputSys, { phase = "pre_update", priority = 0 })
  world:addSystem(LogicSys, { phase = "update",     priority = 10 })
  function lurek.process(dt)
    world:updatePhase("pre_update", dt)
    world:updatePhase("update",     dt)
  end
end

--@api-stub: Universe:snapshot
-- Performs the snapshot operation on this universe.
do
  local world = lurek.ecs.newUniverse()
  local hero = world:spawn()
  world:set(hero, "hp", 42)
  local snap = world:snapshot()
  world:clear()
  world:applySnapshot(snap)
  lurek.log.info("restored entity count=" .. world:getEntityCount(), "ecs")
end

--@api-stub: Universe:applySnapshot
-- Applies snapshot to this universe.
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn(); world:set(e, "score", 99)
  local snap = world:snapshot()
  world:clear()
  world:applySnapshot(snap)
  local ids = world:getEntities()
  lurek.log.info("score=" .. world:get(ids[1], "score"), "ecs")
end


--@api-stub: LUniverse:type
-- Returns the Lua-visible type name for this universe handle
do
  local u = lurek.ecs.newUniverse()
  local t = u:type()
end

--@api-stub: LUniverse:typeOf
-- Returns whether this universe handle matches a supported type name
do
  local u = lurek.ecs.newUniverse()
  local ok = u:typeOf("LUniverse")
end

--@api-stub: LUniverse:takeSnapshotDiff
-- Returns and clears accumulated ECS snapshot diff data
do
  local world = lurek.ecs.newUniverse()
  local e = world:spawn()
  world:set(e, "hp", 10)
  world:remove(e, "hp")
  world:kill(e)
  local diff = world:takeSnapshotDiff()
  lurek.log.info(
    "diff add=" .. #diff.added_components ..
    " rem=" .. #diff.removed_components ..
    " del=" .. #diff.deleted_entities,
    "ecs"
  )
end
