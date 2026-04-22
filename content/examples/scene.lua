-- content/examples/scene.lua
-- Scaffolded coverage of the lurek.scene API (53 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/scene_api.rs   (Lua binding, arg types, return shape)
--   * src/scene/                 (semantics, side effects)
--   * docs/specs/scene.md        (canonical reference)
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
-- Run: cargo run -- content/examples/scene.lua

-- ── lurek.scene.* functions ──

--@api-stub: lurek.scene.push
-- Pushes a scene table onto the stack with an optional transition and easing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.push
  local _todo = "TODO: write a real lurek.scene.push usage example"
  print(_todo)
end

--@api-stub: lurek.scene.pop
-- Pops the top scene from the stack with an optional transition and easing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.pop
  local _todo = "TODO: write a real lurek.scene.pop usage example"
  print(_todo)
end

--@api-stub: lurek.scene.switchTo
-- Replaces the top scene with a new one, calling leave and enter callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.switchTo
  local _todo = "TODO: write a real lurek.scene.switchTo usage example"
  print(_todo)
end

--@api-stub: lurek.scene.clear
-- Clears all scenes from the stack, calling leave on each.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.clear
  local _todo = "TODO: write a real lurek.scene.clear usage example"
  print(_todo)
end

--@api-stub: lurek.scene.popTo
-- Pops scenes until the named scene is on top, calling leave on each removed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.popTo
  local _todo = "TODO: write a real lurek.scene.popTo usage example"
  print(_todo)
end

--@api-stub: lurek.scene.update
-- Updates the top scene and any active transition (legacy name; prefer `process`).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.update
  local _todo = "TODO: write a real lurek.scene.update usage example"
  print(_todo)
end

--@api-stub: lurek.scene.process
-- Calls `scene:ready(self)` once per scene on the first tick after enter,.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.process
  local _todo = "TODO: write a real lurek.scene.process usage example"
  print(_todo)
end

--@api-stub: lurek.scene.processPhysics
-- Calls `scene:process_physics(dt)` on all active scenes (fixed timestep).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.processPhysics
  local _todo = "TODO: write a real lurek.scene.processPhysics usage example"
  print(_todo)
end

--@api-stub: lurek.scene.processLate
-- Calls `scene:process_late(dt)` on all active scenes (after process, before render).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.processLate
  local _todo = "TODO: write a real lurek.scene.processLate usage example"
  print(_todo)
end

--@api-stub: lurek.scene.draw
-- Draws all scenes in the stack from bottom to top (legacy name; prefer `render`).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.draw
  local _todo = "TODO: write a real lurek.scene.draw usage example"
  print(_todo)
end

--@api-stub: lurek.scene.render
-- Draws all scenes in the stack from bottom to top.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.render
  local _todo = "TODO: write a real lurek.scene.render usage example"
  print(_todo)
end

--@api-stub: lurek.scene.renderUi
-- Draws UI overlay for all scenes in the stack from bottom to top.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.renderUi
  local _todo = "TODO: write a real lurek.scene.renderUi usage example"
  print(_todo)
end

--@api-stub: lurek.scene.getStackSize
-- Returns the number of scenes on the stack.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.getStackSize
  local _todo = "TODO: write a real lurek.scene.getStackSize usage example"
  print(_todo)
end

--@api-stub: lurek.scene.depth
-- Returns the number of scenes on the stack.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.depth
  local _todo = "TODO: write a real lurek.scene.depth usage example"
  print(_todo)
end

--@api-stub: lurek.scene.isEmpty
-- Returns true if the scene stack is empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.isEmpty
  local _todo = "TODO: write a real lurek.scene.isEmpty usage example"
  print(_todo)
end

--@api-stub: lurek.scene.getCurrent
-- Returns the current top scene table, or nil if the stack is empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.getCurrent
  local _todo = "TODO: write a real lurek.scene.getCurrent usage example"
  print(_todo)
end

--@api-stub: lurek.scene.isTransitioning
-- Returns true if a scene transition is currently active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.isTransitioning
  local _todo = "TODO: write a real lurek.scene.isTransitioning usage example"
  print(_todo)
end

--@api-stub: lurek.scene.getTransitionProgress
-- Returns the transition progress from 0.0 to 1.0.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.getTransitionProgress
  local _todo = "TODO: write a real lurek.scene.getTransitionProgress usage example"
  print(_todo)
end

--@api-stub: lurek.scene.registerScene
-- Registers a scene table by name for later retrieval.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.registerScene
  local _todo = "TODO: write a real lurek.scene.registerScene usage example"
  print(_todo)
end

--@api-stub: lurek.scene.getRegistered
-- Returns a registered scene table by name, or nil if not found.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.getRegistered
  local _todo = "TODO: write a real lurek.scene.getRegistered usage example"
  print(_todo)
end

--@api-stub: lurek.scene.hasRegistered
-- Returns true if a scene is registered under the given name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.hasRegistered
  local _todo = "TODO: write a real lurek.scene.hasRegistered usage example"
  print(_todo)
end

--@api-stub: lurek.scene.unregisterScene
-- Removes a scene from the registry by name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.unregisterScene
  local _todo = "TODO: write a real lurek.scene.unregisterScene usage example"
  print(_todo)
end

--@api-stub: lurek.scene.getRegisteredNames
-- Returns a list of all registered scene names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.getRegisteredNames
  local _todo = "TODO: write a real lurek.scene.getRegisteredNames usage example"
  print(_todo)
end

--@api-stub: lurek.scene.setData
-- Stores a value in the inter-scene data store under the given key.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.setData
  local _todo = "TODO: write a real lurek.scene.setData usage example"
  print(_todo)
end

--@api-stub: lurek.scene.getData
-- Returns a value from the inter-scene data store, or nil if not found.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.getData
  local _todo = "TODO: write a real lurek.scene.getData usage example"
  print(_todo)
end

--@api-stub: lurek.scene.hasData
-- Returns true if the given key exists in the data store.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.hasData
  local _todo = "TODO: write a real lurek.scene.hasData usage example"
  print(_todo)
end

--@api-stub: lurek.scene.removeData
-- Removes a value from the inter-scene data store by key.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.removeData
  local _todo = "TODO: write a real lurek.scene.removeData usage example"
  print(_todo)
end

--@api-stub: lurek.scene.newDepthSorter
-- Creates a new DepthSorter for z-ordered draw batching.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.newDepthSorter
  local _todo = "TODO: write a real lurek.scene.newDepthSorter usage example"
  print(_todo)
end

--@api-stub: lurek.scene.new
-- Creates a scene instance directly from a methods table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.new
  local _todo = "TODO: write a real lurek.scene.new usage example"
  print(_todo)
end

--@api-stub: lurek.scene.newScene
-- Alias for `lurek.scene.new`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.newScene
  local _todo = "TODO: write a real lurek.scene.newScene usage example"
  print(_todo)
end

--@api-stub: lurek.scene.define
-- Creates a reusable scene class â€” returns a zero-argument constructor function.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.define
  local _todo = "TODO: write a real lurek.scene.define usage example"
  print(_todo)
end

--@api-stub: lurek.scene.getTransitionProgressEased
-- Returns the easing-adjusted transition progress from 0.0 to 1.0.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.getTransitionProgressEased
  local _todo = "TODO: write a real lurek.scene.getTransitionProgressEased usage example"
  print(_todo)
end

--@api-stub: lurek.scene.pushOverlay
-- Pushes a scene as a non-pausing overlay over the current top scene.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.pushOverlay
  local _todo = "TODO: write a real lurek.scene.pushOverlay usage example"
  print(_todo)
end

--@api-stub: lurek.scene.isOverlay
-- Returns true if the current top scene was pushed as an overlay.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.isOverlay
  local _todo = "TODO: write a real lurek.scene.isOverlay usage example"
  print(_todo)
end

--@api-stub: lurek.scene.getActiveScenes
-- Returns a table array of all active scene tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.getActiveScenes
  local _todo = "TODO: write a real lurek.scene.getActiveScenes usage example"
  print(_todo)
end

--@api-stub: lurek.scene.preload
-- Registers a loader function for a named scene.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.preload
  local _todo = "TODO: write a real lurek.scene.preload usage example"
  print(_todo)
end

--@api-stub: lurek.scene.isPreloaded
-- Returns true if the named scene has been preloaded.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.isPreloaded
  local _todo = "TODO: write a real lurek.scene.isPreloaded usage example"
  print(_todo)
end

--@api-stub: lurek.scene.pushPreloaded
-- Pushes a registered scene by name, running its loader if not yet preloaded.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.pushPreloaded
  local _todo = "TODO: write a real lurek.scene.pushPreloaded usage example"
  print(_todo)
end

--@api-stub: lurek.scene.getTransitionTypes
-- Returns a table listing all supported transition type strings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.getTransitionTypes
  local _todo = "TODO: write a real lurek.scene.getTransitionTypes usage example"
  print(_todo)
end

--@api-stub: lurek.scene.serializeScene
-- Returns a snapshot of the scene stack as a Lua table: { stack=[name...], data={key=val} }.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.serializeScene
  local _todo = "TODO: write a real lurek.scene.serializeScene usage example"
  print(_todo)
end

--@api-stub: lurek.scene.deserializeScene
-- Restores scene data_refs from a snapshot produced by serializeScene().
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.deserializeScene
  local _todo = "TODO: write a real lurek.scene.deserializeScene usage example"
  print(_todo)
end

--@api-stub: lurek.scene.fade
-- Returns a fade cross-dissolve transition config table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.fade
  local _todo = "TODO: write a real lurek.scene.fade usage example"
  print(_todo)
end

--@api-stub: lurek.scene.slide
-- Returns a directional slide transition config table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.slide
  local _todo = "TODO: write a real lurek.scene.slide usage example"
  print(_todo)
end

--@api-stub: lurek.scene.wipe
-- Returns a wipe/curtain transition config table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.wipe
  local _todo = "TODO: write a real lurek.scene.wipe usage example"
  print(_todo)
end

--@api-stub: lurek.scene.iris
-- Returns an iris in/out (circular reveal) transition config table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: lurek.scene.iris
  local _todo = "TODO: write a real lurek.scene.iris usage example"
  print(_todo)
end

-- ── DepthSorter methods ──

--@api-stub: DepthSorter:add
-- Registers a draw callback at the given depth layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: DepthSorter:add
  local _todo = "TODO: write a real DepthSorter:add usage example"
  print(_todo)
end

--@api-stub: DepthSorter:addObject
-- Registers a table object with a draw method at the given depth.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: DepthSorter:addObject
  local _todo = "TODO: write a real DepthSorter:addObject usage example"
  print(_todo)
end

--@api-stub: DepthSorter:sort
-- Sorts all registered callbacks by depth ascending.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: DepthSorter:sort
  local _todo = "TODO: write a real DepthSorter:sort usage example"
  print(_todo)
end

--@api-stub: DepthSorter:flush
-- Calls all draw callbacks in sorted depth order, then clears.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: DepthSorter:flush
  local _todo = "TODO: write a real DepthSorter:flush usage example"
  print(_todo)
end

--@api-stub: DepthSorter:setStable
-- Sets whether equal-depth entries preserve insertion order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: DepthSorter:setStable
  local _todo = "TODO: write a real DepthSorter:setStable usage example"
  print(_todo)
end

--@api-stub: DepthSorter:isStable
-- Returns true if stable sort mode is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: DepthSorter:isStable
  local _todo = "TODO: write a real DepthSorter:isStable usage example"
  print(_todo)
end

--@api-stub: DepthSorter:clear
-- Removes all registered callbacks without calling them.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: DepthSorter:clear
  local _todo = "TODO: write a real DepthSorter:clear usage example"
  print(_todo)
end

--@api-stub: DepthSorter:getCount
-- Returns the number of registered draw entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/scene_api.rs and docs/specs/scene.md).
do  -- TODO: DepthSorter:getCount
  local _todo = "TODO: write a real DepthSorter:getCount usage example"
  print(_todo)
end

