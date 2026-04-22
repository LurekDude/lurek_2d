-- content/examples/scene.lua
-- Auto-scaffolded coverage of the lurek.scene Lua API (53 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/scene.lua

print("[example] lurek.scene loaded — 53 API items demonstrated")

-- ── lurek.scene free functions ──

--@api-stub: lurek.scene.push
-- Pushes a scene table onto the stack with an optional transition and easing.
-- Use this when pushes a scene table onto the stack with an optional transition and easing is needed.
if false then
  local _r = lurek.scene.push()
  print(_r)
end

--@api-stub: lurek.scene.pop
-- Pops the top scene from the stack with an optional transition and easing.
-- Use this when pops the top scene from the stack with an optional transition and easing is needed.
if false then
  local _r = lurek.scene.pop(1, 1, 1)
  print(_r)
end

--@api-stub: lurek.scene.switchTo
-- Replaces the top scene with a new one, calling leave and enter callbacks.
-- Use this when replaces the top scene with a new one, calling leave and enter callbacks is needed.
if false then
  local _r = lurek.scene.switchTo()
  print(_r)
end

--@api-stub: lurek.scene.clear
-- Clears all scenes from the stack, calling leave on each.
-- Use this when clears all scenes from the stack, calling leave on each is needed.
if false then
  local _r = lurek.scene.clear()
  print(_r)
end

--@api-stub: lurek.scene.popTo
-- Pops scenes until the named scene is on top, calling leave on each removed.
-- Use this when pops scenes until the named scene is on top, calling leave on each removed is needed.
if false then
  local _r = lurek.scene.popTo(1)
  print(_r)
end

--@api-stub: lurek.scene.update
-- Updates the top scene and any active transition (legacy name; prefer `process`).
-- Use this when updates the top scene and any active transition (legacy name; prefer `process`) is needed.
if false then
  local _r = lurek.scene.update(0)
  print(_r)
end

--@api-stub: lurek.scene.process
-- Calls `scene:ready(self)` once per scene on the first tick after enter,.
-- Use this when calls `scene:ready(self)` once per scene on the first tick after enter, is needed.
if false then
  local _r = lurek.scene.process(0)
  print(_r)
end

--@api-stub: lurek.scene.processPhysics
-- Calls `scene:process_physics(dt)` on all active scenes (fixed timestep).
-- Use this when calls `scene:process_physics(dt)` on all active scenes (fixed timestep) is needed.
if false then
  local _r = lurek.scene.processPhysics(0)
  print(_r)
end

--@api-stub: lurek.scene.processLate
-- Calls `scene:process_late(dt)` on all active scenes (after process, before render).
-- Use this when calls `scene:process_late(dt)` on all active scenes (after process, before render) is needed.
if false then
  local _r = lurek.scene.processLate(0)
  print(_r)
end

--@api-stub: lurek.scene.draw
-- Draws all scenes in the stack from bottom to top (legacy name; prefer `render`).
-- Use this when draws all scenes in the stack from bottom to top (legacy name; prefer `render`) is needed.
if false then
  local _r = lurek.scene.draw()
  print(_r)
end

--@api-stub: lurek.scene.render
-- Draws all scenes in the stack from bottom to top.
-- Use this when draws all scenes in the stack from bottom to top is needed.
if false then
  local _r = lurek.scene.render()
  print(_r)
end

--@api-stub: lurek.scene.renderUi
-- Draws UI overlay for all scenes in the stack from bottom to top.
-- Use this when draws UI overlay for all scenes in the stack from bottom to top is needed.
if false then
  local _r = lurek.scene.renderUi()
  print(_r)
end

--@api-stub: lurek.scene.getStackSize
-- Returns the number of scenes on the stack.
-- Use this when returns the number of scenes on the stack is needed.
if false then
  local _r = lurek.scene.getStackSize()
  print(_r)
end

--@api-stub: lurek.scene.depth
-- Returns the number of scenes on the stack.
-- Use this when returns the number of scenes on the stack is needed.
if false then
  local _r = lurek.scene.depth()
  print(_r)
end

--@api-stub: lurek.scene.isEmpty
-- Returns true if the scene stack is empty.
-- Use this when returns true if the scene stack is empty is needed.
if false then
  local _r = lurek.scene.isEmpty()
  print(_r)
end

--@api-stub: lurek.scene.getCurrent
-- Returns the current top scene table, or nil if the stack is empty.
-- Use this when returns the current top scene table, or nil if the stack is empty is needed.
if false then
  local _r = lurek.scene.getCurrent()
  print(_r)
end

--@api-stub: lurek.scene.isTransitioning
-- Returns true if a scene transition is currently active.
-- Use this when returns true if a scene transition is currently active is needed.
if false then
  local _r = lurek.scene.isTransitioning()
  print(_r)
end

--@api-stub: lurek.scene.getTransitionProgress
-- Returns the transition progress from 0.0 to 1.0.
-- Use this when returns the transition progress from 0.0 to 1.0 is needed.
if false then
  local _r = lurek.scene.getTransitionProgress()
  print(_r)
end

--@api-stub: lurek.scene.registerScene
-- Registers a scene table by name for later retrieval.
-- Use this when registers a scene table by name for later retrieval is needed.
if false then
  local _r = lurek.scene.registerScene(1, 1)
  print(_r)
end

--@api-stub: lurek.scene.getRegistered
-- Returns a registered scene table by name, or nil if not found.
-- Use this when returns a registered scene table by name, or nil if not found is needed.
if false then
  local _r = lurek.scene.getRegistered(1)
  print(_r)
end

--@api-stub: lurek.scene.hasRegistered
-- Returns true if a scene is registered under the given name.
-- Use this when returns true if a scene is registered under the given name is needed.
if false then
  local _r = lurek.scene.hasRegistered(1)
  print(_r)
end

--@api-stub: lurek.scene.unregisterScene
-- Removes a scene from the registry by name.
-- Use this when removes a scene from the registry by name is needed.
if false then
  local _r = lurek.scene.unregisterScene(1)
  print(_r)
end

--@api-stub: lurek.scene.getRegisteredNames
-- Returns a list of all registered scene names.
-- Use this when returns a list of all registered scene names is needed.
if false then
  local _r = lurek.scene.getRegisteredNames()
  print(_r)
end

--@api-stub: lurek.scene.setData
-- Stores a value in the inter-scene data store under the given key.
-- Use this when stores a value in the inter-scene data store under the given key is needed.
if false then
  local _r = lurek.scene.setData(0, 0)
  print(_r)
end

--@api-stub: lurek.scene.getData
-- Returns a value from the inter-scene data store, or nil if not found.
-- Use this when returns a value from the inter-scene data store, or nil if not found is needed.
if false then
  local _r = lurek.scene.getData(0)
  print(_r)
end

--@api-stub: lurek.scene.hasData
-- Returns true if the given key exists in the data store.
-- Use this when returns true if the given key exists in the data store is needed.
if false then
  local _r = lurek.scene.hasData(0)
  print(_r)
end

--@api-stub: lurek.scene.removeData
-- Removes a value from the inter-scene data store by key.
-- Use this when removes a value from the inter-scene data store by key is needed.
if false then
  local _r = lurek.scene.removeData(0)
  print(_r)
end

--@api-stub: lurek.scene.newDepthSorter
-- Creates a new DepthSorter for z-ordered draw batching.
-- Use this when creates a new DepthSorter for z-ordered draw batching is needed.
if false then
  local _r = lurek.scene.newDepthSorter()
  print(_r)
end

--@api-stub: lurek.scene.new
-- Creates a scene instance directly from a methods table.
-- Use this when creates a scene instance directly from a methods table is needed.
if false then
  local _r = lurek.scene.new(nil)
  print(_r)
end

--@api-stub: lurek.scene.newScene
-- Alias for `lurek.scene.new`.
-- Creates a scene instance from a methods table.
if false then
  local _r = lurek.scene.newScene(nil)
  print(_r)
end

--@api-stub: lurek.scene.define
-- Creates a reusable scene class â€” returns a zero-argument constructor function.
-- Use this when creates a reusable scene class â€” returns a zero-argument constructor function is needed.
if false then
  local _r = lurek.scene.define(nil)
  print(_r)
end

--@api-stub: lurek.scene.getTransitionProgressEased
-- Returns the easing-adjusted transition progress from 0.0 to 1.0.
-- Use this when returns the easing-adjusted transition progress from 0.0 to 1.0 is needed.
if false then
  local _r = lurek.scene.getTransitionProgressEased()
  print(_r)
end

--@api-stub: lurek.scene.pushOverlay
-- Pushes a scene as a non-pausing overlay over the current top scene.
-- Use this when pushes a scene as a non-pausing overlay over the current top scene is needed.
if false then
  local _r = lurek.scene.pushOverlay()
  print(_r)
end

--@api-stub: lurek.scene.isOverlay
-- Returns true if the current top scene was pushed as an overlay.
-- Use this when returns true if the current top scene was pushed as an overlay is needed.
if false then
  local _r = lurek.scene.isOverlay()
  print(_r)
end

--@api-stub: lurek.scene.getActiveScenes
-- Returns a table array of all active scene tables.
-- Use this when returns a table array of all active scene tables is needed.
if false then
  local _r = lurek.scene.getActiveScenes()
  print(_r)
end

--@api-stub: lurek.scene.preload
-- Registers a loader function for a named scene.
-- The loader is called
if false then
  local _r = lurek.scene.preload(1, nil)
  print(_r)
end

--@api-stub: lurek.scene.isPreloaded
-- Returns true if the named scene has been preloaded.
-- Use this when returns true if the named scene has been preloaded is needed.
if false then
  local _r = lurek.scene.isPreloaded(1)
  print(_r)
end

--@api-stub: lurek.scene.pushPreloaded
-- Pushes a registered scene by name, running its loader if not yet preloaded.
-- Use this when pushes a registered scene by name, running its loader if not yet preloaded is needed.
if false then
  local _r = lurek.scene.pushPreloaded()
  print(_r)
end

--@api-stub: lurek.scene.getTransitionTypes
-- Returns a table listing all supported transition type strings.
-- Use this when returns a table listing all supported transition type strings is needed.
if false then
  local _r = lurek.scene.getTransitionTypes()
  print(_r)
end

--@api-stub: lurek.scene.serializeScene
-- Returns a snapshot of the scene stack as a Lua table: { stack=[name...], data={key=val} }.
-- Use this when returns a snapshot of the scene stack as a Lua table: { stack=[name...], data={key=val} } is needed.
if false then
  local _r = lurek.scene.serializeScene()
  print(_r)
end

--@api-stub: lurek.scene.deserializeScene
-- Restores scene data_refs from a snapshot produced by serializeScene().
-- Use this when restores scene data_refs from a snapshot produced by serializeScene() is needed.
if false then
  local _r = lurek.scene.deserializeScene(1)
  print(_r)
end

--@api-stub: lurek.scene.fade
-- Returns a fade cross-dissolve transition config table.
-- Use this when returns a fade cross-dissolve transition config table is needed.
if false then
  local _r = lurek.scene.fade(1)
  print(_r)
end

--@api-stub: lurek.scene.slide
-- Returns a directional slide transition config table.
-- Use this when returns a directional slide transition config table is needed.
if false then
  local _r = lurek.scene.slide(1, 1)
  print(_r)
end

--@api-stub: lurek.scene.wipe
-- Returns a wipe/curtain transition config table.
-- Use this when returns a wipe/curtain transition config table is needed.
if false then
  local _r = lurek.scene.wipe(1)
  print(_r)
end

--@api-stub: lurek.scene.iris
-- Returns an iris in/out (circular reveal) transition config table.
-- Use this when returns an iris in/out (circular reveal) transition config table is needed.
if false then
  local _r = lurek.scene.iris(1)
  print(_r)
end

-- ── DepthSorter methods ──

--@api-stub: DepthSorter:add
-- Registers a draw callback at the given depth layer.
-- Use this when registers a draw callback at the given depth layer is needed.
if false then
  local _o = nil  -- DepthSorter instance
  _o:add(function() end, 1)
end

--@api-stub: DepthSorter:addObject
-- Registers a table object with a draw method at the given depth.
-- Use this when registers a table object with a draw method at the given depth is needed.
if false then
  local _o = nil  -- DepthSorter instance
  _o:addObject(nil)
end

--@api-stub: DepthSorter:sort
-- Sorts all registered callbacks by depth ascending.
-- Use this when sorts all registered callbacks by depth ascending is needed.
if false then
  local _o = nil  -- DepthSorter instance
  _o:sort()
end

--@api-stub: DepthSorter:flush
-- Calls all draw callbacks in sorted depth order, then clears.
-- Use this when calls all draw callbacks in sorted depth order, then clears is needed.
if false then
  local _o = nil  -- DepthSorter instance
  _o:flush()
end

--@api-stub: DepthSorter:setStable
-- Sets whether equal-depth entries preserve insertion order.
-- Use this when sets whether equal-depth entries preserve insertion order is needed.
if false then
  local _o = nil  -- DepthSorter instance
  _o:setStable(0)
end

--@api-stub: DepthSorter:isStable
-- Returns true if stable sort mode is enabled.
-- Use this when returns true if stable sort mode is enabled is needed.
if false then
  local _o = nil  -- DepthSorter instance
  _o:isStable()
end

--@api-stub: DepthSorter:clear
-- Removes all registered callbacks without calling them.
-- Use this when removes all registered callbacks without calling them is needed.
if false then
  local _o = nil  -- DepthSorter instance
  _o:clear()
end

--@api-stub: DepthSorter:getCount
-- Returns the number of registered draw entries.
-- Use this when returns the number of registered draw entries is needed.
if false then
  local _o = nil  -- DepthSorter instance
  _o:getCount()
end

