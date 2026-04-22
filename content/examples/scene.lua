-- content/examples/scene.lua
-- Practical usage examples for the lurek.scene API (53 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.scene.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/scene.lua

print("[example] lurek.scene — 53 API entries")

-- ── lurek.scene.* free functions ──

--@api-stub: lurek.scene.push
-- Pushes a scene table onto the stack with an optional transition and easing.
-- Call when you need to invoke push.
local ok, err = pcall(function() lurek.scene.push() end)
if not ok then print("mutator skipped:", err) end
print("lurek.scene.push done=", ok)

--@api-stub: lurek.scene.pop
-- Pops the top scene from the stack with an optional transition and easing.
-- Call when you need to invoke pop.
local ok, err = pcall(function() lurek.scene.pop(nil, 1.0, nil) end)
if not ok then print("skipped:", err) end
print("lurek.scene.pop cleared=", ok)

--@api-stub: lurek.scene.switchTo
-- Replaces the top scene with a new one, calling leave and enter callbacks.
-- Call when you need to invoke switch to.
local ok, result = pcall(function() return lurek.scene.switchTo() end)
if ok then print("lurek.scene.switchTo ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.clear
-- Clears all scenes from the stack, calling leave on each.
-- Call when you need to invoke clear.
local ok, err = pcall(function() lurek.scene.clear() end)
if not ok then print("skipped:", err) end
print("lurek.scene.clear cleared=", ok)

--@api-stub: lurek.scene.popTo
-- Pops scenes until the named scene is on top, calling leave on each removed.
-- Call when you need to invoke pop to.
local ok, err = pcall(function() lurek.scene.popTo("name") end)
if not ok then print("skipped:", err) end
print("lurek.scene.popTo cleared=", ok)

--@api-stub: lurek.scene.update
-- Updates the top scene and any active transition (legacy name; prefer `process`).
-- Call when you need to invoke update.
local ok, err = pcall(function() lurek.scene.update(1.0) end)
if not ok then print("set skipped:", err) end
print("lurek.scene.update applied=", ok)

--@api-stub: lurek.scene.process
-- Calls `scene:ready(self)` once per scene on the first tick after enter,.
-- Call when you need to invoke process.
local ok, result = pcall(function() return lurek.scene.process(1.0) end)
if ok then print("lurek.scene.process ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.processPhysics
-- Calls `scene:process_physics(dt)` on all active scenes (fixed timestep).
-- Call when you need to invoke process physics.
local ok, result = pcall(function() return lurek.scene.processPhysics(1.0) end)
if ok then print("lurek.scene.processPhysics ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.processLate
-- Calls `scene:process_late(dt)` on all active scenes (after process, before render).
-- Call when you need to invoke process late.
local ok, result = pcall(function() return lurek.scene.processLate(1.0) end)
if ok then print("lurek.scene.processLate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.draw
-- Draws all scenes in the stack from bottom to top (legacy name; prefer `render`).
-- Call when you need to invoke draw.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.scene.draw() end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.scene.draw drawn=", ok)

--@api-stub: lurek.scene.render
-- Draws all scenes in the stack from bottom to top.
-- Call when you need to invoke render.
local ok, result = pcall(function() return lurek.scene.render() end)
if ok then print("lurek.scene.render ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.renderUi
-- Draws UI overlay for all scenes in the stack from bottom to top.
-- Call when you need to invoke render ui.
local ok, result = pcall(function() return lurek.scene.renderUi() end)
if ok then print("lurek.scene.renderUi ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.getStackSize
-- Returns the number of scenes on the stack.
-- Call when you need to read stack size.
local ok, value = pcall(function() return lurek.scene.getStackSize() end)
local v = ok and value or "(unavailable)"
print("lurek.scene.getStackSize ->", v)

--@api-stub: lurek.scene.depth
-- Returns the number of scenes on the stack.
-- Call when you need to invoke depth.
local ok, result = pcall(function() return lurek.scene.depth() end)
if ok then print("lurek.scene.depth ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.isEmpty
-- Returns true if the scene stack is empty.
-- Call when you need to check is empty.
local ok, result = pcall(function() return lurek.scene.isEmpty() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.scene.isEmpty ok=", ok)

--@api-stub: lurek.scene.getCurrent
-- Returns the current top scene table, or nil if the stack is empty.
-- Call when you need to read current.
local ok, value = pcall(function() return lurek.scene.getCurrent() end)
local v = ok and value or "(unavailable)"
print("lurek.scene.getCurrent ->", v)

--@api-stub: lurek.scene.isTransitioning
-- Returns true if a scene transition is currently active.
-- Call when you need to check is transitioning.
local ok, result = pcall(function() return lurek.scene.isTransitioning() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.scene.isTransitioning ok=", ok)

--@api-stub: lurek.scene.getTransitionProgress
-- Returns the transition progress from 0.0 to 1.0.
-- Call when you need to read transition progress.
local ok, value = pcall(function() return lurek.scene.getTransitionProgress() end)
local v = ok and value or "(unavailable)"
print("lurek.scene.getTransitionProgress ->", v)

--@api-stub: lurek.scene.registerScene
-- Registers a scene table by name for later retrieval.
-- Call when you need to invoke register scene.
local ok, err = pcall(function() lurek.scene.registerScene("name", nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.scene.registerScene done=", ok)

--@api-stub: lurek.scene.getRegistered
-- Returns a registered scene table by name, or nil if not found.
-- Call when you need to read registered.
local ok, value = pcall(function() return lurek.scene.getRegistered("name") end)
local v = ok and value or "(unavailable)"
print("lurek.scene.getRegistered ->", v)

--@api-stub: lurek.scene.hasRegistered
-- Returns true if a scene is registered under the given name.
-- Call when you need to check has registered.
local ok, result = pcall(function() return lurek.scene.hasRegistered("name") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.scene.hasRegistered ok=", ok)

--@api-stub: lurek.scene.unregisterScene
-- Removes a scene from the registry by name.
-- Call when you need to invoke unregister scene.
local ok, result = pcall(function() return lurek.scene.unregisterScene("name") end)
if ok then print("lurek.scene.unregisterScene ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.getRegisteredNames
-- Returns a list of all registered scene names.
-- Call when you need to read registered names.
local ok, value = pcall(function() return lurek.scene.getRegisteredNames() end)
local v = ok and value or "(unavailable)"
print("lurek.scene.getRegisteredNames ->", v)

--@api-stub: lurek.scene.setData
-- Stores a value in the inter-scene data store under the given key.
-- Call when you need to assign data.
local ok, err = pcall(function() lurek.scene.setData("key", nil) end)
if not ok then print("set skipped:", err) end
print("lurek.scene.setData applied=", ok)

--@api-stub: lurek.scene.getData
-- Returns a value from the inter-scene data store, or nil if not found.
-- Call when you need to read data.
local ok, value = pcall(function() return lurek.scene.getData("key") end)
local v = ok and value or "(unavailable)"
print("lurek.scene.getData ->", v)

--@api-stub: lurek.scene.hasData
-- Returns true if the given key exists in the data store.
-- Call when you need to check has data.
local ok, result = pcall(function() return lurek.scene.hasData("key") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.scene.hasData ok=", ok)

--@api-stub: lurek.scene.removeData
-- Removes a value from the inter-scene data store by key.
-- Call when you need to remove data.
local ok, err = pcall(function() lurek.scene.removeData("key") end)
if not ok then print("skipped:", err) end
print("lurek.scene.removeData cleared=", ok)

--@api-stub: lurek.scene.newDepthSorter
-- Creates a new DepthSorter for z-ordered draw batching.
-- Call when you need to create a new depth sorter.
local ok, obj = pcall(function() return lurek.scene.newDepthSorter() end)
if ok and obj then print("created:", obj) end
print("lurek.scene.newDepthSorter ok=", ok)

--@api-stub: lurek.scene.new
-- Creates a scene instance directly from a methods table.
-- Call when you need to invoke new.
local ok, obj = pcall(function() return lurek.scene.new(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.scene.new ok=", ok)

--@api-stub: lurek.scene.newScene
-- Alias for `lurek.scene.new`.
-- Creates a scene instance from a methods table.
local ok, obj = pcall(function() return lurek.scene.newScene(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.scene.newScene ok=", ok)

--@api-stub: lurek.scene.define
-- Creates a reusable scene class â€” returns a zero-argument constructor function.
-- Call when you need to invoke define.
local ok, result = pcall(function() return lurek.scene.define(nil) end)
if ok then print("lurek.scene.define ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.getTransitionProgressEased
-- Returns the easing-adjusted transition progress from 0.0 to 1.0.
-- Call when you need to read transition progress eased.
local ok, value = pcall(function() return lurek.scene.getTransitionProgressEased() end)
local v = ok and value or "(unavailable)"
print("lurek.scene.getTransitionProgressEased ->", v)

--@api-stub: lurek.scene.pushOverlay
-- Pushes a scene as a non-pausing overlay over the current top scene.
-- Call when you need to invoke push overlay.
local ok, err = pcall(function() lurek.scene.pushOverlay() end)
if not ok then print("mutator skipped:", err) end
print("lurek.scene.pushOverlay done=", ok)

--@api-stub: lurek.scene.isOverlay
-- Returns true if the current top scene was pushed as an overlay.
-- Call when you need to check is overlay.
local ok, result = pcall(function() return lurek.scene.isOverlay() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.scene.isOverlay ok=", ok)

--@api-stub: lurek.scene.getActiveScenes
-- Returns a table array of all active scene tables.
-- Call when you need to read active scenes.
local ok, value = pcall(function() return lurek.scene.getActiveScenes() end)
local v = ok and value or "(unavailable)"
print("lurek.scene.getActiveScenes ->", v)

--@api-stub: lurek.scene.preload
-- Registers a loader function for a named scene.
-- The loader is called.
local ok, result = pcall(function() return lurek.scene.preload("name", nil) end)
if ok then print("lurek.scene.preload ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.isPreloaded
-- Returns true if the named scene has been preloaded.
-- Call when you need to check is preloaded.
local ok, result = pcall(function() return lurek.scene.isPreloaded("name") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.scene.isPreloaded ok=", ok)

--@api-stub: lurek.scene.pushPreloaded
-- Pushes a registered scene by name, running its loader if not yet preloaded.
-- Call when you need to invoke push preloaded.
local ok, err = pcall(function() lurek.scene.pushPreloaded() end)
if not ok then print("mutator skipped:", err) end
print("lurek.scene.pushPreloaded done=", ok)

--@api-stub: lurek.scene.getTransitionTypes
-- Returns a table listing all supported transition type strings.
-- Call when you need to read transition types.
local ok, value = pcall(function() return lurek.scene.getTransitionTypes() end)
local v = ok and value or "(unavailable)"
print("lurek.scene.getTransitionTypes ->", v)

--@api-stub: lurek.scene.serializeScene
-- Returns a snapshot of the scene stack as a Lua table: { stack=[name...], data={key=val} }.
-- Call when you need to invoke serialize scene.
local ok, obj = pcall(function() return lurek.scene.serializeScene() end)
if ok and obj then print("created:", obj) end
print("lurek.scene.serializeScene ok=", ok)

--@api-stub: lurek.scene.deserializeScene
-- Restores scene data_refs from a snapshot produced by serializeScene().
-- Call when you need to invoke deserialize scene.
local ok, obj = pcall(function() return lurek.scene.deserializeScene(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.scene.deserializeScene ok=", ok)

--@api-stub: lurek.scene.fade
-- Returns a fade cross-dissolve transition config table.
-- Call when you need to invoke fade.
local ok, result = pcall(function() return lurek.scene.fade(1.0) end)
if ok then print("lurek.scene.fade ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.slide
-- Returns a directional slide transition config table.
-- Call when you need to invoke slide.
local ok, result = pcall(function() return lurek.scene.slide("direction", 1.0) end)
if ok then print("lurek.scene.slide ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.wipe
-- Returns a wipe/curtain transition config table.
-- Call when you need to invoke wipe.
local ok, result = pcall(function() return lurek.scene.wipe(1.0) end)
if ok then print("lurek.scene.wipe ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.scene.iris
-- Returns an iris in/out (circular reveal) transition config table.
-- Call when you need to invoke iris.
local ok, result = pcall(function() return lurek.scene.iris(1.0) end)
if ok then print("lurek.scene.iris ->", result)
else print("unavailable:", result) end

-- ── DepthSorter methods ──

--@api-stub: DepthSorter:add
-- Registers a draw callback at the given depth layer.
-- Call when you need to invoke add.
-- Build a DepthSorter via the appropriate lurek.scene.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.scene.newDepthSorter(...)
if instance then
  local ok, result = pcall(function() return instance:add(function() end, nil) end)
  print("DepthSorter:add ->", ok, result)
end

--@api-stub: DepthSorter:addObject
-- Registers a table object with a draw method at the given depth.
-- Call when you need to add object.
-- Build a DepthSorter via the appropriate lurek.scene.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.scene.newDepthSorter(...)
if instance then
  local ok, result = pcall(function() return instance:addObject(nil) end)
  print("DepthSorter:addObject ->", ok, result)
end

--@api-stub: DepthSorter:sort
-- Sorts all registered callbacks by depth ascending.
-- Call when you need to invoke sort.
-- Build a DepthSorter via the appropriate lurek.scene.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.scene.newDepthSorter(...)
if instance then
  local ok, result = pcall(function() return instance:sort() end)
  print("DepthSorter:sort ->", ok, result)
end

--@api-stub: DepthSorter:flush
-- Calls all draw callbacks in sorted depth order, then clears.
-- Call when you need to invoke flush.
-- Build a DepthSorter via the appropriate lurek.scene.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.scene.newDepthSorter(...)
if instance then
  local ok, result = pcall(function() return instance:flush() end)
  print("DepthSorter:flush ->", ok, result)
end

--@api-stub: DepthSorter:setStable
-- Sets whether equal-depth entries preserve insertion order.
-- Call when you need to assign stable.
-- Build a DepthSorter via the appropriate lurek.scene.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.scene.newDepthSorter(...)
if instance then
  local ok, result = pcall(function() return instance:setStable({}) end)
  print("DepthSorter:setStable ->", ok, result)
end

--@api-stub: DepthSorter:isStable
-- Returns true if stable sort mode is enabled.
-- Call when you need to check is stable.
-- Build a DepthSorter via the appropriate lurek.scene.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.scene.newDepthSorter(...)
if instance then
  local ok, result = pcall(function() return instance:isStable() end)
  print("DepthSorter:isStable ->", ok, result)
end

--@api-stub: DepthSorter:clear
-- Removes all registered callbacks without calling them.
-- Call when you need to invoke clear.
-- Build a DepthSorter via the appropriate lurek.scene.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.scene.newDepthSorter(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("DepthSorter:clear ->", ok, result)
end

--@api-stub: DepthSorter:getCount
-- Returns the number of registered draw entries.
-- Call when you need to read count.
-- Build a DepthSorter via the appropriate lurek.scene.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.scene.newDepthSorter(...)
if instance then
  local ok, result = pcall(function() return instance:getCount() end)
  print("DepthSorter:getCount ->", ok, result)
end

