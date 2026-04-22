-- content/examples/ecs.lua
-- Practical usage examples for the lurek.ecs API (47 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.ecs.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/ecs.lua

print("[example] lurek.ecs — 47 API entries")

-- ── lurek.ecs.* free functions ──

--@api-stub: lurek.ecs.newUniverse
-- Creates a new empty ECS universe.
-- Call when you need to create a new universe.
local ok, obj = pcall(function() return lurek.ecs.newUniverse() end)
if ok and obj then print("created:", obj) end
print("lurek.ecs.newUniverse ok=", ok)

-- ── Universe methods ──

--@api-stub: Universe:spawn
-- Creates a new entity and returns its packed ID.
-- Call when you need to invoke spawn.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:spawn() end)
  print("Universe:spawn ->", ok, result)
end

--@api-stub: Universe:kill
-- Destroys the entity with the given ID, freeing its slot for reuse.
-- Call when you need to invoke kill.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:kill(1) end)
  print("Universe:kill ->", ok, result)
end

--@api-stub: Universe:isAlive
-- Returns true if the entity ID is currently alive.
-- Call when you need to check is alive.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:isAlive(1) end)
  print("Universe:isAlive ->", ok, result)
end

--@api-stub: Universe:get
-- Returns the component value for an entity, or nil if missing.
-- Call when you need to invoke get.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:get(1, "name") end)
  print("Universe:get ->", ok, result)
end

--@api-stub: Universe:has
-- Returns true if the entity has the named component.
-- Call when you need to invoke has.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:has(1, "name") end)
  print("Universe:has ->", ok, result)
end

--@api-stub: Universe:remove
-- Removes a component from an entity.
-- Call when you need to invoke remove.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:remove(1, "name") end)
  print("Universe:remove ->", ok, result)
end

--@api-stub: Universe:getComponents
-- Returns all component names for an entity.
-- Call when you need to read components.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getComponents(1) end)
  print("Universe:getComponents ->", ok, result)
end

--@api-stub: Universe:query
-- Returns entity IDs that have all listed component names.
-- Call when you need to invoke query.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:query({}) end)
  print("Universe:query ->", ok, result)
end

--@api-stub: Universe:getEntities
-- Returns all alive entity IDs.
-- Call when you need to read entities.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getEntities() end)
  print("Universe:getEntities ->", ok, result)
end

--@api-stub: Universe:getEntityCount
-- Returns the number of alive entities.
-- Call when you need to read entity count.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getEntityCount() end)
  print("Universe:getEntityCount ->", ok, result)
end

--@api-stub: Universe:removeSystem
-- Removes a system table from the universe.
-- Call when you need to remove system.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:removeSystem(nil) end)
  print("Universe:removeSystem ->", ok, result)
end

--@api-stub: Universe:update
-- Calls update(system, world, dt) on each registered system in priority order.
-- Call when you need to invoke update.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Universe:update ->", ok, result)
end

--@api-stub: Universe:render
-- Calls render(system, world) on each registered system in priority order.
-- Call when you need to invoke render.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:render() end)
  print("Universe:render ->", ok, result)
end

--@api-stub: Universe:emit
-- Emits a named event to all systems that implement the handler, in priority order.
-- Call when you need to invoke emit.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:emit({}) end)
  print("Universe:emit ->", ok, result)
end

--@api-stub: Universe:getSystemCount
-- Returns the number of registered systems.
-- Call when you need to read system count.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getSystemCount() end)
  print("Universe:getSystemCount ->", ok, result)
end

--@api-stub: Universe:clear
-- Removes all entities, components, tags, layers, and systems.
-- Blueprints are preserved.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Universe:clear ->", ok, result)
end

--@api-stub: Universe:release
-- Releases all universe state, equivalent to clear.
-- Call when you need to invoke release.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("Universe:release ->", ok, result)
end

--@api-stub: Universe:addTag
-- Attaches a string tag to an entity.
-- Call when you need to add tag.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:addTag(1, "tag") end)
  print("Universe:addTag ->", ok, result)
end

--@api-stub: Universe:removeTag
-- Removes a string tag from an entity.
-- Call when you need to remove tag.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:removeTag(1, "tag") end)
  print("Universe:removeTag ->", ok, result)
end

--@api-stub: Universe:hasTag
-- Returns true if the entity carries the given tag.
-- Call when you need to check has tag.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:hasTag(1, "tag") end)
  print("Universe:hasTag ->", ok, result)
end

--@api-stub: Universe:getTags
-- Returns all string tags for an entity.
-- Call when you need to read tags.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getTags(1) end)
  print("Universe:getTags ->", ok, result)
end

--@api-stub: Universe:getEntitiesByTag
-- Returns all alive entities with the given string tag.
-- Call when you need to read entities by tag.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getEntitiesByTag("tag") end)
  print("Universe:getEntitiesByTag ->", ok, result)
end

--@api-stub: Universe:setLayer
-- Sets the layer for an entity.
-- Call when you need to assign layer.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:setLayer(1, nil) end)
  print("Universe:setLayer ->", ok, result)
end

--@api-stub: Universe:getLayer
-- Returns the layer for an entity, defaulting to zero.
-- Call when you need to read layer.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getLayer(1) end)
  print("Universe:getLayer ->", ok, result)
end

--@api-stub: Universe:getEntitiesByLayer
-- Returns all alive entities on a specific layer.
-- Call when you need to read entities by layer.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getEntitiesByLayer(nil) end)
  print("Universe:getEntitiesByLayer ->", ok, result)
end

--@api-stub: Universe:getEntitiesSorted
-- Returns all alive entities sorted by layer then ID.
-- Call when you need to read entities sorted.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getEntitiesSorted() end)
  print("Universe:getEntitiesSorted ->", ok, result)
end

--@api-stub: Universe:defineTag
-- Defines a bitmap tag name, returning its bit index.
-- Call when you need to invoke define tag.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:defineTag("name") end)
  print("Universe:defineTag ->", ok, result)
end

--@api-stub: Universe:bitmapTag
-- Adds a bitmap tag to an entity.
-- Call when you need to invoke bitmap tag.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:bitmapTag(1, "name") end)
  print("Universe:bitmapTag ->", ok, result)
end

--@api-stub: Universe:bitmapUntag
-- Removes a bitmap tag from an entity.
-- Call when you need to invoke bitmap untag.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:bitmapUntag(1, "name") end)
  print("Universe:bitmapUntag ->", ok, result)
end

--@api-stub: Universe:hasBitmapTag
-- Returns true if the entity has the given bitmap tag.
-- Call when you need to check has bitmap tag.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:hasBitmapTag(1, "name") end)
  print("Universe:hasBitmapTag ->", ok, result)
end

--@api-stub: Universe:queryBitmapTag
-- Returns all alive entities with the given bitmap tag.
-- Call when you need to invoke query bitmap tag.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:queryBitmapTag("name") end)
  print("Universe:queryBitmapTag ->", ok, result)
end

--@api-stub: Universe:queryBitmapAny
-- Returns all alive entities with any of the listed bitmap tags.
-- Call when you need to invoke query bitmap any.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:queryBitmapAny("names") end)
  print("Universe:queryBitmapAny ->", ok, result)
end

--@api-stub: Universe:queryBitmapAll
-- Returns all alive entities with all of the listed bitmap tags.
-- Call when you need to invoke query bitmap all.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:queryBitmapAll("names") end)
  print("Universe:queryBitmapAll ->", ok, result)
end

--@api-stub: Universe:getBitmapTagBit
-- Returns the bit index for a bitmap tag name, or nil if undefined.
-- Call when you need to read bitmap tag bit.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getBitmapTagBit("name") end)
  print("Universe:getBitmapTagBit ->", ok, result)
end

--@api-stub: Universe:hasBlueprint
-- Returns true if a blueprint with the given name exists.
-- Call when you need to check has blueprint.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:hasBlueprint("name") end)
  print("Universe:hasBlueprint ->", ok, result)
end

--@api-stub: Universe:removeBlueprint
-- Removes a blueprint definition.
-- Call when you need to remove blueprint.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:removeBlueprint("name") end)
  print("Universe:removeBlueprint ->", ok, result)
end

--@api-stub: Universe:listBlueprints
-- Returns all defined blueprint names.
-- Call when you need to invoke list blueprints.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:listBlueprints() end)
  print("Universe:listBlueprints ->", ok, result)
end

--@api-stub: Universe:getBlueprintComponents
-- Returns a deep copy of a blueprint's component table, or nil.
-- Call when you need to read blueprint components.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getBlueprintComponents("name") end)
  print("Universe:getBlueprintComponents ->", ok, result)
end

--@api-stub: Universe:getParent
-- Returns the parent entity ID, or nil if unparented.
-- Call when you need to read parent.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getParent(1) end)
  print("Universe:getParent ->", ok, result)
end

--@api-stub: Universe:getChildren
-- Returns all direct child entity IDs.
-- Call when you need to read children.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getChildren(1) end)
  print("Universe:getChildren ->", ok, result)
end

--@api-stub: Universe:killRecursive
-- Kills an entity and all its descendants recursively.
-- Call when you need to invoke kill recursive.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:killRecursive(1) end)
  print("Universe:killRecursive ->", ok, result)
end

--@api-stub: Universe:serialize
-- Serializes all alive entities to a Lua table snapshot.
-- Call when you need to invoke serialize.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:serialize() end)
  print("Universe:serialize ->", ok, result)
end

--@api-stub: Universe:deserialize
-- Restores entity state from a snapshot produced by serialize().
-- Call when you need to invoke deserialize.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:deserialize(nil) end)
  print("Universe:deserialize ->", ok, result)
end

--@api-stub: Universe:flushObservers
-- Dispatches all pending component-add and component-remove events to registered callbacks.
-- Call when you need to invoke flush observers.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:flushObservers() end)
  print("Universe:flushObservers ->", ok, result)
end

--@api-stub: Universe:getRelated
-- Returns all entity IDs reachable from `from` via the named relationship.
-- Call when you need to read related.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:getRelated(nil, "name") end)
  print("Universe:getRelated ->", ok, result)
end

--@api-stub: Universe:clearRelations
-- Removes all directed named relationships of type `name` from entity `from`.
-- Call when you need to invoke clear relations.
-- Build a Universe via the appropriate lurek.ecs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.ecs.newUniverse(...)
if instance then
  local ok, result = pcall(function() return instance:clearRelations(nil, "name") end)
  print("Universe:clearRelations ->", ok, result)
end

