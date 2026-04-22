-- content/examples/ecs.lua
-- Scaffolded coverage of the lurek.ecs API (47 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/ecs_api.rs   (Lua binding, arg types, return shape)
--   * src/ecs/                 (semantics, side effects)
--   * docs/specs/ecs.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/ecs.lua

-- ── lurek.ecs.* functions ──

--@api-stub: lurek.ecs.newUniverse
-- Creates a new empty ECS universe.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: lurek.ecs.newUniverse
  local _todo = "TODO: write a real lurek.ecs.newUniverse usage example"
  print(_todo)
end

-- ── Universe methods ──

--@api-stub: Universe:spawn
-- Creates a new entity and returns its packed ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:spawn
  local _todo = "TODO: write a real Universe:spawn usage example"
  print(_todo)
end

--@api-stub: Universe:kill
-- Destroys the entity with the given ID, freeing its slot for reuse.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:kill
  local _todo = "TODO: write a real Universe:kill usage example"
  print(_todo)
end

--@api-stub: Universe:isAlive
-- Returns true if the entity ID is currently alive.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:isAlive
  local _todo = "TODO: write a real Universe:isAlive usage example"
  print(_todo)
end

--@api-stub: Universe:get
-- Returns the component value for an entity, or nil if missing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:get
  local _todo = "TODO: write a real Universe:get usage example"
  print(_todo)
end

--@api-stub: Universe:has
-- Returns true if the entity has the named component.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:has
  local _todo = "TODO: write a real Universe:has usage example"
  print(_todo)
end

--@api-stub: Universe:remove
-- Removes a component from an entity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:remove
  local _todo = "TODO: write a real Universe:remove usage example"
  print(_todo)
end

--@api-stub: Universe:getComponents
-- Returns all component names for an entity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getComponents
  local _todo = "TODO: write a real Universe:getComponents usage example"
  print(_todo)
end

--@api-stub: Universe:query
-- Returns entity IDs that have all listed component names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:query
  local _todo = "TODO: write a real Universe:query usage example"
  print(_todo)
end

--@api-stub: Universe:getEntities
-- Returns all alive entity IDs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getEntities
  local _todo = "TODO: write a real Universe:getEntities usage example"
  print(_todo)
end

--@api-stub: Universe:getEntityCount
-- Returns the number of alive entities.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getEntityCount
  local _todo = "TODO: write a real Universe:getEntityCount usage example"
  print(_todo)
end

--@api-stub: Universe:removeSystem
-- Removes a system table from the universe.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:removeSystem
  local _todo = "TODO: write a real Universe:removeSystem usage example"
  print(_todo)
end

--@api-stub: Universe:update
-- Calls update(system, world, dt) on each registered system in priority order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:update
  local _todo = "TODO: write a real Universe:update usage example"
  print(_todo)
end

--@api-stub: Universe:render
-- Calls render(system, world) on each registered system in priority order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:render
  local _todo = "TODO: write a real Universe:render usage example"
  print(_todo)
end

--@api-stub: Universe:emit
-- Emits a named event to all systems that implement the handler, in priority order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:emit
  local _todo = "TODO: write a real Universe:emit usage example"
  print(_todo)
end

--@api-stub: Universe:getSystemCount
-- Returns the number of registered systems.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getSystemCount
  local _todo = "TODO: write a real Universe:getSystemCount usage example"
  print(_todo)
end

--@api-stub: Universe:clear
-- Removes all entities, components, tags, layers, and systems.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:clear
  local _todo = "TODO: write a real Universe:clear usage example"
  print(_todo)
end

--@api-stub: Universe:release
-- Releases all universe state, equivalent to clear.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:release
  local _todo = "TODO: write a real Universe:release usage example"
  print(_todo)
end

--@api-stub: Universe:addTag
-- Attaches a string tag to an entity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:addTag
  local _todo = "TODO: write a real Universe:addTag usage example"
  print(_todo)
end

--@api-stub: Universe:removeTag
-- Removes a string tag from an entity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:removeTag
  local _todo = "TODO: write a real Universe:removeTag usage example"
  print(_todo)
end

--@api-stub: Universe:hasTag
-- Returns true if the entity carries the given tag.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:hasTag
  local _todo = "TODO: write a real Universe:hasTag usage example"
  print(_todo)
end

--@api-stub: Universe:getTags
-- Returns all string tags for an entity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getTags
  local _todo = "TODO: write a real Universe:getTags usage example"
  print(_todo)
end

--@api-stub: Universe:getEntitiesByTag
-- Returns all alive entities with the given string tag.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getEntitiesByTag
  local _todo = "TODO: write a real Universe:getEntitiesByTag usage example"
  print(_todo)
end

--@api-stub: Universe:setLayer
-- Sets the layer for an entity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:setLayer
  local _todo = "TODO: write a real Universe:setLayer usage example"
  print(_todo)
end

--@api-stub: Universe:getLayer
-- Returns the layer for an entity, defaulting to zero.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getLayer
  local _todo = "TODO: write a real Universe:getLayer usage example"
  print(_todo)
end

--@api-stub: Universe:getEntitiesByLayer
-- Returns all alive entities on a specific layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getEntitiesByLayer
  local _todo = "TODO: write a real Universe:getEntitiesByLayer usage example"
  print(_todo)
end

--@api-stub: Universe:getEntitiesSorted
-- Returns all alive entities sorted by layer then ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getEntitiesSorted
  local _todo = "TODO: write a real Universe:getEntitiesSorted usage example"
  print(_todo)
end

--@api-stub: Universe:defineTag
-- Defines a bitmap tag name, returning its bit index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:defineTag
  local _todo = "TODO: write a real Universe:defineTag usage example"
  print(_todo)
end

--@api-stub: Universe:bitmapTag
-- Adds a bitmap tag to an entity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:bitmapTag
  local _todo = "TODO: write a real Universe:bitmapTag usage example"
  print(_todo)
end

--@api-stub: Universe:bitmapUntag
-- Removes a bitmap tag from an entity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:bitmapUntag
  local _todo = "TODO: write a real Universe:bitmapUntag usage example"
  print(_todo)
end

--@api-stub: Universe:hasBitmapTag
-- Returns true if the entity has the given bitmap tag.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:hasBitmapTag
  local _todo = "TODO: write a real Universe:hasBitmapTag usage example"
  print(_todo)
end

--@api-stub: Universe:queryBitmapTag
-- Returns all alive entities with the given bitmap tag.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:queryBitmapTag
  local _todo = "TODO: write a real Universe:queryBitmapTag usage example"
  print(_todo)
end

--@api-stub: Universe:queryBitmapAny
-- Returns all alive entities with any of the listed bitmap tags.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:queryBitmapAny
  local _todo = "TODO: write a real Universe:queryBitmapAny usage example"
  print(_todo)
end

--@api-stub: Universe:queryBitmapAll
-- Returns all alive entities with all of the listed bitmap tags.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:queryBitmapAll
  local _todo = "TODO: write a real Universe:queryBitmapAll usage example"
  print(_todo)
end

--@api-stub: Universe:getBitmapTagBit
-- Returns the bit index for a bitmap tag name, or nil if undefined.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getBitmapTagBit
  local _todo = "TODO: write a real Universe:getBitmapTagBit usage example"
  print(_todo)
end

--@api-stub: Universe:hasBlueprint
-- Returns true if a blueprint with the given name exists.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:hasBlueprint
  local _todo = "TODO: write a real Universe:hasBlueprint usage example"
  print(_todo)
end

--@api-stub: Universe:removeBlueprint
-- Removes a blueprint definition.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:removeBlueprint
  local _todo = "TODO: write a real Universe:removeBlueprint usage example"
  print(_todo)
end

--@api-stub: Universe:listBlueprints
-- Returns all defined blueprint names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:listBlueprints
  local _todo = "TODO: write a real Universe:listBlueprints usage example"
  print(_todo)
end

--@api-stub: Universe:getBlueprintComponents
-- Returns a deep copy of a blueprint's component table, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getBlueprintComponents
  local _todo = "TODO: write a real Universe:getBlueprintComponents usage example"
  print(_todo)
end

--@api-stub: Universe:getParent
-- Returns the parent entity ID, or nil if unparented.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getParent
  local _todo = "TODO: write a real Universe:getParent usage example"
  print(_todo)
end

--@api-stub: Universe:getChildren
-- Returns all direct child entity IDs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getChildren
  local _todo = "TODO: write a real Universe:getChildren usage example"
  print(_todo)
end

--@api-stub: Universe:killRecursive
-- Kills an entity and all its descendants recursively.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:killRecursive
  local _todo = "TODO: write a real Universe:killRecursive usage example"
  print(_todo)
end

--@api-stub: Universe:serialize
-- Serializes all alive entities to a Lua table snapshot.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:serialize
  local _todo = "TODO: write a real Universe:serialize usage example"
  print(_todo)
end

--@api-stub: Universe:deserialize
-- Restores entity state from a snapshot produced by serialize().
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:deserialize
  local _todo = "TODO: write a real Universe:deserialize usage example"
  print(_todo)
end

--@api-stub: Universe:flushObservers
-- Dispatches all pending component-add and component-remove events to registered callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:flushObservers
  local _todo = "TODO: write a real Universe:flushObservers usage example"
  print(_todo)
end

--@api-stub: Universe:getRelated
-- Returns all entity IDs reachable from `from` via the named relationship.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:getRelated
  local _todo = "TODO: write a real Universe:getRelated usage example"
  print(_todo)
end

--@api-stub: Universe:clearRelations
-- Removes all directed named relationships of type `name` from entity `from`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/ecs_api.rs and docs/specs/ecs.md).
do  -- TODO: Universe:clearRelations
  local _todo = "TODO: write a real Universe:clearRelations usage example"
  print(_todo)
end

