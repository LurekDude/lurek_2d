-- content/examples/scene.lua
-- lurek.scene API examples.
-- Run: cargo run -- content/examples/scene.lua

--@api-stub: lurek.scene.push
-- Push a new scene onto the stack, making it the active scene
do
  local menu = lurek.scene.new({ enter = function(self, p) self.from = p and p.from end })
  lurek.scene.push(menu, "fade", 0.3, "ease_in_out", { from = "boot" })
  lurek.log.info("pushed menu, depth=" .. lurek.scene.depth(), "scene")
end

--@api-stub: lurek.scene.pop
-- Pop the top scene off the stack and return to the previous one
do
  function lurek.process(dt)
    if lurek.scene.depth() > 1 and not lurek.scene.isTransitioning() then
      lurek.scene.pop("fade", 0.25, "linear")
    end
  end
end

--@api-stub: lurek.scene.switchTo
-- Replace the current top scene with a different one without changing stack depth
do
  local game_over = lurek.scene.new({ enter = function(self, p) self.score = p.score end })
  lurek.scene.switchTo(game_over, "fade", 0.5, "ease_out", { score = 1240 })
end

--@api-stub: lurek.scene.clear
-- Remove all scenes from the stack
do
  function lurek.quit()
    lurek.scene.clear()
    lurek.log.info("scene stack cleared on shutdown", "scene")
  end
end

--@api-stub: lurek.scene.popTo
-- Pop scenes off the stack until the named registered scene is on top
do
  if lurek.scene.hasRegistered("world_map") and lurek.scene.depth() > 1 then
    lurek.scene.popTo("world_map")
  end
end

--@api-stub: lurek.scene.update
-- Advance any active transition animation and call `update(self, dt)` on the current top scene
do
  local sim_dt = 1 / 60
  for _ = 1, 30 do
    lurek.scene.update(sim_dt)
  end
end

--@api-stub: lurek.scene.process
-- Call `ready(self)` once on newly-pushed scenes, then call `process(self, dt)` on every active scene ordered by layer (lowest first)
do
  local headless = lurek.scene.new({ process = function(self, dt) self.t = (self.t or 0) + dt end })
  lurek.scene.push(headless)
  lurek.scene.process(0.016)
end

--@api-stub: lurek.scene.processPhysics
-- Call `process_physics(self, dt)` on every active scene ordered by layer
do
  local fixed_dt = 1 / 120
  function lurek.process(_)
    lurek.scene.processPhysics(fixed_dt)
  end
end

--@api-stub: lurek.scene.processLate
-- Call `process_late(self, dt)` on every active scene after all other processing
do
  function lurek.process(dt)
    lurek.scene.processLate(dt)
  end
end

--@api-stub: lurek.scene.draw
-- Call `draw(self)` on every scene in the stack from bottom to top
do
  function lurek.draw()
    lurek.scene.draw()
  end
end

--@api-stub: lurek.scene.render
-- Call `render(self)` on every scene in the stack from bottom to top
do
  function lurek.draw()
    lurek.scene.render()
  end
end

--@api-stub: lurek.scene.renderUi
-- Call `render_ui(self)` on every scene in the stack from bottom to top
do
  function lurek.draw_ui()
    lurek.scene.renderUi()
  end
end

--@api-stub: lurek.scene.getStackSize
-- Returns the total number of scenes currently on the stack, including overlays
do
  local n = lurek.scene.getStackSize()
  if n == 0 then
    lurek.log.warn("no active scene; pushing menu", "scene")
  end
end

--@api-stub: lurek.scene.depth
-- Alias for `getStackSize`
do
  if lurek.scene.depth() < 1 then
    lurek.scene.push(lurek.scene.new({}))
  end
end

--@api-stub: lurek.scene.isEmpty
-- Returns true if the scene stack contains no scenes at all
do
  if lurek.scene.isEmpty() then
    lurek.scene.push(lurek.scene.new({ enter = function() end }))
  end
end

--@api-stub: lurek.scene.getCurrent
-- Returns the scene table currently on top of the stack, or nil if the stack is empty
do
  local top = lurek.scene.getCurrent()
  if top and top.name then
    lurek.log.info("current scene: " .. top.name, "scene")
  end
end

--@api-stub: lurek.scene.isTransitioning
-- Returns true if a scene transition animation is currently playing
do
  function lurek.process(_)
    if lurek.scene.isTransitioning() then
      return
    end
  end
end

--@api-stub: lurek.scene.getTransitionProgress
-- Returns the raw linear progress (0
do
  function lurek.process(_)
    local p = lurek.scene.getTransitionProgress()
    if p > 0 and p < 1 then
      lurek.log.debug("transition " .. string.format("%.2f", p), "scene")
    end
  end
end

--@api-stub: lurek.scene.queueTransition
-- Queue a transition to play automatically after the current one finishes
do
  lurek.scene.push(lurek.scene.new({}), "fade", 0.4, "linear")
  lurek.scene.queueTransition("wipe", 0.35, "ease_out")
end

--@api-stub: lurek.scene.getQueuedTransitionCount
-- Returns the number of transitions waiting in the queue behind the currently-playing transition
do
  local queued = lurek.scene.getQueuedTransitionCount()
  lurek.log.debug("queued transitions=" .. queued, "scene")
end

--@api-stub: lurek.scene.clearQueuedTransitions
-- Discard all queued transitions without affecting the currently-playing transition (if any)
do
  lurek.scene.clearQueuedTransitions()
end

--@api-stub: lurek.scene.registerScene
-- Register a scene table under a unique name for later retrieval via `getRegistered`, navigation via `popTo`, or deferred push via `pushPreloaded`
do
  local options = lurek.scene.new({ enter = function() end })
  lurek.scene.registerScene("options", options)
  lurek.scene.registerScene("world_map", lurek.scene.new({}))
end

--@api-stub: lurek.scene.getRegistered
-- Retrieve a previously registered scene table by its name, or nil if no scene is registered under that name
do
  lurek.scene.registerScene("inventory", lurek.scene.new({ slots = {} }))
  local inv = lurek.scene.getRegistered("inventory")
  if inv then inv.slots[1] = "potion" end
end

--@api-stub: lurek.scene.hasRegistered
-- Check whether a scene is registered under the given name
do
  if not lurek.scene.hasRegistered("credits") then
    lurek.scene.registerScene("credits", lurek.scene.new({}))
  end
end

--@api-stub: lurek.scene.unregisterScene
-- Remove a scene registration by name
do
  lurek.scene.registerScene("tutorial", lurek.scene.new({}))
  lurek.scene.unregisterScene("tutorial")
end

--@api-stub: lurek.scene.getRegisteredNames
-- Returns an array of all currently registered scene name strings
do
  for _, name in ipairs(lurek.scene.getRegisteredNames()) do
    lurek.log.info("registered scene: " .. name, "scene")
  end
end

--@api-stub: lurek.scene.setData
-- Store an arbitrary Lua value in the scene module's shared data map, keyed by a string name
do
  lurek.scene.setData("player", { hp = 100, gold = 25 })
  lurek.scene.setData("difficulty", "normal")
end

--@api-stub: lurek.scene.getData
-- Retrieve a value from the shared data map by key, or nil if the key has not been set
do
  lurek.scene.setData("score", 1240)
  local score = lurek.scene.getData("score") or 0
  if score > 1000 then lurek.log.info("high score!", "scene") end
end

--@api-stub: lurek.scene.hasData
-- Check whether a key exists in the shared scene data map without retrieving its value
do
  if not lurek.scene.hasData("player") then
    lurek.scene.setData("player", { hp = 100 })
  end
end

--@api-stub: lurek.scene.removeData
-- Remove a key and its associated value from the shared scene data map
do
  lurek.scene.setData("checkpoint", { x = 320, y = 240 })
  lurek.scene.removeData("checkpoint")
end

--@api-stub: lurek.scene.newDepthSorter
-- Create a new `LDepthSorter` instance for collecting drawable items and flushing them in depth-sorted (painter's algorithm) order
do
  local sorter = lurek.scene.newDepthSorter()
  sorter:setStable(true)
  lurek.log.debug("sorter ready, count=" .. sorter:getCount(), "render")
end

--@api-stub: lurek.scene.new
-- Create a new scene instance from an optional prototype table
do
  local title = lurek.scene.new({
    enter = function(self) self.t = 0 end,
    process = function(self, dt) self.t = self.t + dt end,
  })
  lurek.scene.push(title)
end

--@api-stub: lurek.scene.newScene
-- Alias for `lurek
do
  local pause = lurek.scene.newScene({ enter = function(self) self.paused_at = os.time() end })
  lurek.scene.pushOverlay(pause)
end

--@api-stub: lurek.scene.define
-- Create a reusable scene constructor function from a prototype table
do
  local Level = lurek.scene.define({
    enter = function(self) self.enemies = {} end,
    process = function(self, dt) end,
  })
  lurek.scene.push(Level())
  lurek.scene.push(Level())
end

--@api-stub: lurek.scene.getTransitionProgressEased
-- Returns the eased progress (0
do

  function lurek.draw()
    local p = lurek.scene.getTransitionProgressEased()
    lurek.render.setColor(0, 0, 0, 1 - p)
  end
end

--@api-stub: lurek.scene.pushOverlay
-- Push a scene as a transparent overlay on top of the current scene
do
  local hud = lurek.scene.new({ render = function(self) end })
  lurek.scene.pushOverlay(hud, "fade", 0.2)
end

--@api-stub: lurek.scene.isOverlay
-- Returns true if the current top scene was pushed via `pushOverlay`
do
  if lurek.scene.isOverlay() then
    lurek.log.debug("top is overlay; world still ticking", "scene")
  end
end

--@api-stub: lurek.scene.getActiveScenes
-- Returns a Lua array of all active scene tables ordered by their layer value (lowest layer first)
do
  for _, s in ipairs(lurek.scene.getActiveScenes()) do
    if s.on_resize then s:on_resize(1280, 720) end
  end
end

--@api-stub: lurek.scene.setCurrentLayer
-- Set the rendering layer of the current top scene
do
  lurek.scene.push(lurek.scene.new({}))
  lurek.scene.setCurrentLayer(5)
end

--@api-stub: lurek.scene.getCurrentLayer
-- Get the rendering layer of the current top scene
do
  local layer = lurek.scene.getCurrentLayer()
  lurek.log.debug("current layer=" .. tostring(layer), "scene")
end

--@api-stub: lurek.scene.preload
-- Register a deferred-loading function for a scene
do
  lurek.scene.preload("level_01", function()
    lurek.scene.registerScene("level_01", lurek.scene.new({ name = "level_01" }))
  end)
end

--@api-stub: lurek.scene.isPreloaded
-- Returns true if the named preload loader has already been executed at least once
do
  if not lurek.scene.isPreloaded("level_01") then
    lurek.log.info("level_01 not yet loaded; will load on first push", "scene")
  end
end

--@api-stub: lurek.scene.pushPreloaded
-- Push a preloaded scene onto the stack by name
do
  lurek.scene.preload("level_02", function()
    lurek.scene.registerScene("level_02", lurek.scene.new({ name = "level_02" }))
  end)
  lurek.scene.pushPreloaded("level_02", "fade", 0.4, "ease_in_out", { from_save = false })
end

--@api-stub: lurek.scene.getTransitionTypes
-- Returns a Lua array of all supported transition type name strings
do
  local options = lurek.scene.getTransitionTypes()
  for i, t in ipairs(options) do
    lurek.log.debug(i .. ": " .. t, "scene")
  end
end

--@api-stub: lurek.scene.serializeScene
-- Capture the current scene stack state as a serializable snapshot table
do
  lurek.scene.setData("player", { hp = 75, gold = 12 })
  local snap = lurek.scene.serializeScene()
  lurek.log.info("snapshot has " .. #snap.stack .. " scenes", "save")
end

--@api-stub: lurek.scene.deserializeScene
-- Restore shared scene data from a previously-serialized snapshot table
do
  local snap = { stack = {}, data = { player = { hp = 30, gold = 99 } } }
  lurek.scene.deserializeScene(snap)
  local p = lurek.scene.getData("player")
  lurek.log.info("restored hp=" .. p.hp, "save")
end

--@api-stub: lurek.scene.fade
-- Helper sub-table `lurek
do
  local cfg = lurek.scene.transitions.fade(0.4)
  lurek.scene.push(lurek.scene.new({}), cfg.type, cfg.duration, "ease_in_out")
end

--@api-stub: lurek.scene.slide
-- Create a directional slide transition descriptor table
do
  local next_page = lurek.scene.transitions.slide("right", 0.3)
  lurek.scene.push(lurek.scene.new({}), next_page.type, next_page.duration)
end

--@api-stub: lurek.scene.wipe
-- Create a horizontal wipe transition descriptor table
do
  local cfg = lurek.scene.transitions.wipe(0.6)
  lurek.scene.switchTo(lurek.scene.new({ name = "chapter_2" }), cfg.type, cfg.duration)
end

--@api-stub: lurek.scene.iris
-- Create an iris (circle) transition descriptor table
do
  local cfg = lurek.scene.transitions.iris(0.8)
  lurek.scene.switchTo(lurek.scene.new({ name = "game_over" }), cfg.type, cfg.duration, "ease_out")
end

-- DepthSorter methods

--@api-stub: DepthSorter:add
-- Adds a  to this depth sorter.
do
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() lurek.log.debug("draw sky", "render") end, -100)
  sorter:add(function() lurek.log.debug("draw player", "render") end, 0)
  sorter:add(function() lurek.log.debug("draw fog", "render") end, 100)
end

--@api-stub: DepthSorter:addObject
-- Adds a object to this depth sorter.
do
  local sorter = lurek.scene.newDepthSorter()
  local enemy = { depth = 10, drawSorted = function(self) lurek.log.debug("enemy", "render") end }
  sorter:addObject(enemy)
end

--@api-stub: DepthSorter:sort
-- Sorts the items in this depth sorter according to their sort key.
do
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() end, 50)
  sorter:add(function() end, -10)
  sorter:sort()
end

--@api-stub: DepthSorter:flush
-- Flushes all pending output from this depth sorter immediately.
do
  local sorter = lurek.scene.newDepthSorter()
  function lurek.draw()
    sorter:add(function() lurek.log.debug("frame draw", "render") end, 0)
    sorter:flush()
  end
end

--@api-stub: DepthSorter:setStable
-- Sets the stable of this depth sorter.
do
  local sorter = lurek.scene.newDepthSorter()
  sorter:setStable(true)
  sorter:add(function() lurek.log.debug("a", "render") end, 0)
  sorter:add(function() lurek.log.debug("b", "render") end, 0)
end

--@api-stub: DepthSorter:isStable
-- Returns true if this depth sorter stable.
do
  local sorter = lurek.scene.newDepthSorter()
  if not sorter:isStable() then
    sorter:setStable(true)
  end
end

--@api-stub: DepthSorter:clear
-- Clears all items from this depth sorter.
do
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() end, 0)
  sorter:clear()
  lurek.log.debug("cleared, count=" .. sorter:getCount(), "render")
end

--@api-stub: DepthSorter:getCount
-- Returns the total count of items held by this depth sorter.
do
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() end, 0)
  sorter:add(function() end, 1)
  if sorter:getCount() > 1000 then lurek.log.warn("sorter overflow", "render") end
end

-- -----------------------------------------------------------------------------
-- DepthSorter methods
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LDepthSorter methods
-- -----------------------------------------------------------------------------


--@api-stub: LDepthSorter:type
-- Returns the Lua-visible type name string for this depth sorter handle.
do
  local ds = lurek.scene.newDepthSorter()
  lurek.log.info(ds:type(), "scene")
end

--@api-stub: LDepthSorter:typeOf
-- Returns true if this depth sorter handle matches the given type name string.
do
  local ds = lurek.scene.newDepthSorter()
  lurek.log.info(tostring(ds:typeOf("LDepthSorter")), "scene")
end
