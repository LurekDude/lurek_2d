-- content/examples/scene.lua
-- Hand-written coverage of the lurek.scene API (53 items).
--
-- The scene module owns a stack of scene tables plus an inter-scene data
-- store, transition presets, lazy preloaders, and a DepthSorter for
-- z-ordered draw batching. Build scenes with `lurek.scene.define` /
-- `lurek.scene.new` and drive lifecycle methods (enter/leave/process/render)
-- via the engine callbacks shown in each snippet below.
--
-- Run: cargo run -- content/examples/scene.lua

-- â”€â”€ lurek.scene.* functions â”€â”€

--@api-stub: lurek.scene.push
-- Pushes a scene table onto the stack with an optional transition and easing.
-- Pause/enter callbacks fire automatically; the previous scene resumes only when this one is popped.
do -- lurek.scene.push
  local menu = lurek.scene.new({ enter = function(self, p) self.from = p and p.from end })
  lurek.scene.push(menu, "fade", 0.3, "ease_in_out", { from = "boot" })
  lurek.log.info("pushed menu, depth=" .. lurek.scene.depth(), "scene")
end

--@api-stub: lurek.scene.pop
-- Pops the top scene from the stack with an optional transition and easing.
-- Call from a "back" or pause-menu close handler; resume fires on the revealed scene.
do -- lurek.scene.pop
  function lurek.process(dt)
    if lurek.scene.depth() > 1 and not lurek.scene.isTransitioning() then
      lurek.scene.pop("fade", 0.25, "linear")
    end
  end
end

--@api-stub: lurek.scene.switchTo
-- Replaces the top scene with a new one, calling leave and enter callbacks.
-- Use for navigation that should NOT remember the previous scene (game-over â†’ menu).
do -- lurek.scene.switchTo
  local game_over = lurek.scene.new({ enter = function(self, p) self.score = p.score end })
  lurek.scene.switchTo(game_over, "fade", 0.5, "ease_out", { score = 1240 })
end

--@api-stub: lurek.scene.clear
-- Clears all scenes from the stack, calling leave on each.
-- Use when restarting a run from scratch or on a hard transition to the title screen.
do -- lurek.scene.clear
  function lurek.quit()
    lurek.scene.clear()
    lurek.log.info("scene stack cleared on shutdown", "scene")
  end
end

--@api-stub: lurek.scene.popTo
-- Pops scenes until the named scene is on top, calling leave on each removed.
-- Wire to a "back to map" button so nested menus collapse in one call.
do -- lurek.scene.popTo
  if lurek.scene.hasRegistered("world_map") and lurek.scene.depth() > 1 then
    lurek.scene.popTo("world_map")
  end
end

--@api-stub: lurek.scene.update
-- Updates the top scene and any active transition (legacy name; prefer `process`).
-- Only call manually if you bypass the engine main loop (e.g. in offline simulations or tests).
do -- lurek.scene.update
  local sim_dt = 1 / 60
  for _ = 1, 30 do
    lurek.scene.update(sim_dt)
  end
end

--@api-stub: lurek.scene.process
-- Calls `scene:ready(self)` once per scene on the first tick after enter, then `scene:process(dt)`.
-- Engine drives this every frame; call manually only when stepping a scene outside the main loop.
do -- lurek.scene.process
  local headless = lurek.scene.new({ process = function(self, dt) self.t = (self.t or 0) + dt end })
  lurek.scene.push(headless)
  lurek.scene.process(0.016)
end

--@api-stub: lurek.scene.processPhysics
-- Calls `scene:process_physics(dt)` on all active scenes (fixed timestep).
-- Use for deterministic physics: drive it from a fixed-step accumulator separate from process().
do -- lurek.scene.processPhysics
  local fixed_dt = 1 / 120
  function lurek.process(_)
    lurek.scene.processPhysics(fixed_dt)
  end
end

--@api-stub: lurek.scene.processLate
-- Calls `scene:process_late(dt)` on all active scenes (after process, before render).
-- Use for camera follow or UI layout that depends on this frame's player movement.
do -- lurek.scene.processLate
  function lurek.process(dt)
    lurek.scene.processLate(dt)
  end
end

--@api-stub: lurek.scene.draw
-- Draws all scenes in the stack from bottom to top (legacy name; prefer `render`).
-- Call inside `lurek.render` only when migrating older code; new scenes should implement `render`.
do -- lurek.scene.draw
  function lurek.draw()
    lurek.scene.draw()
  end
end

--@api-stub: lurek.scene.render
-- Draws all scenes in the stack from bottom to top.
-- Always call this from `lurek.render`; overlays draw on top of the background scene automatically.
do -- lurek.scene.render
  function lurek.draw()
    lurek.scene.render()
  end
end

--@api-stub: lurek.scene.renderUi
-- Draws UI overlay for all scenes in the stack from bottom to top.
-- Pair with `lurek.scene.render` so HUD/menus draw above world content.
do -- lurek.scene.renderUi
  function lurek.draw_ui()
    lurek.scene.renderUi()
  end
end

--@api-stub: lurek.scene.getStackSize
-- Returns the number of scenes on the stack.
-- Use in debug overlays or to gate "back" actions before popping.
do -- lurek.scene.getStackSize
  local n = lurek.scene.getStackSize()
  if n == 0 then
    lurek.log.warn("no active scene; pushing menu", "scene")
  end
end

--@api-stub: lurek.scene.depth
-- Returns the number of scenes on the stack.
-- Ergonomic alias for `getStackSize`; prefer it in game code.
do -- lurek.scene.depth
  if lurek.scene.depth() < 1 then
    lurek.scene.push(lurek.scene.new({}))
  end
end

--@api-stub: lurek.scene.isEmpty
-- Returns true if the scene stack is empty.
-- Check at startup before the first push to decide whether to load from a save.
do -- lurek.scene.isEmpty
  if lurek.scene.isEmpty() then
    lurek.scene.push(lurek.scene.new({ enter = function() end }))
  end
end

--@api-stub: lurek.scene.getCurrent
-- Returns the current top scene table, or nil if the stack is empty.
-- Use to dispatch input or read scene-local state from outside the scene's own methods.
do -- lurek.scene.getCurrent
  local top = lurek.scene.getCurrent()
  if top and top.name then
    lurek.log.info("current scene: " .. top.name, "scene")
  end
end

--@api-stub: lurek.scene.isTransitioning
-- Returns true if a scene transition is currently active.
-- Gate input or further push/pop calls so transitions are not interrupted mid-blend.
do -- lurek.scene.isTransitioning
  function lurek.process(_)
    if lurek.scene.isTransitioning() then
      return
    end
  end
end

--@api-stub: lurek.scene.getTransitionProgress
-- Returns the transition progress from 0.0 to 1.0.
-- Use the raw value to drive custom audio fade or shader uniforms during a transition.
do -- lurek.scene.getTransitionProgress
  function lurek.process(_)
    local p = lurek.scene.getTransitionProgress()
    if p > 0 and p < 1 then
      lurek.log.debug("transition " .. string.format("%.2f", p), "scene")
    end
  end
end

--@api-stub: lurek.scene.registerScene
-- Registers a scene table by name for later retrieval.
-- Register at boot so popTo / pushPreloaded / getRegistered can resolve scenes by name.
do -- lurek.scene.registerScene
  local options = lurek.scene.new({ enter = function() end })
  lurek.scene.registerScene("options", options)
  lurek.scene.registerScene("world_map", lurek.scene.new({}))
end

--@api-stub: lurek.scene.getRegistered
-- Returns a registered scene table by name, or nil if not found.
-- Use to fetch a scene without re-creating it, then push or read fields on it.
do -- lurek.scene.getRegistered
  lurek.scene.registerScene("inventory", lurek.scene.new({ slots = {} }))
  local inv = lurek.scene.getRegistered("inventory")
  if inv then inv.slots[1] = "potion" end
end

--@api-stub: lurek.scene.hasRegistered
-- Returns true if a scene is registered under the given name.
-- Guard popTo / pushPreloaded calls so they do not silently no-op on a typo.
do -- lurek.scene.hasRegistered
  if not lurek.scene.hasRegistered("credits") then
    lurek.scene.registerScene("credits", lurek.scene.new({}))
  end
end

--@api-stub: lurek.scene.unregisterScene
-- Removes a scene from the registry by name.
-- Call when a scene is no longer reachable (e.g. after finishing a one-shot tutorial).
do -- lurek.scene.unregisterScene
  lurek.scene.registerScene("tutorial", lurek.scene.new({}))
  lurek.scene.unregisterScene("tutorial")
end

--@api-stub: lurek.scene.getRegisteredNames
-- Returns a list of all registered scene names.
-- Use to build a debug scene-selector UI or to assert the expected set in tests.
do -- lurek.scene.getRegisteredNames
  for _, name in ipairs(lurek.scene.getRegisteredNames()) do
    lurek.log.info("registered scene: " .. name, "scene")
  end
end

--@api-stub: lurek.scene.setData
-- Stores a value in the inter-scene data store under the given key.
-- Use to pass run state (score, player loadout) between scenes without globals.
do -- lurek.scene.setData
  lurek.scene.setData("player", { hp = 100, gold = 25 })
  lurek.scene.setData("difficulty", "normal")
end

--@api-stub: lurek.scene.getData
-- Returns a value from the inter-scene data store, or nil if not found.
-- Read in the next scene's `enter` to restore shared state across the transition.
do -- lurek.scene.getData
  lurek.scene.setData("score", 1240)
  local score = lurek.scene.getData("score") or 0
  if score > 1000 then lurek.log.info("high score!", "scene") end
end

--@api-stub: lurek.scene.hasData
-- Returns true if the given key exists in the data store.
-- Distinguish "missing key" from "value is nil/false" without explicit sentinels.
do -- lurek.scene.hasData
  if not lurek.scene.hasData("player") then
    lurek.scene.setData("player", { hp = 100 })
  end
end

--@api-stub: lurek.scene.removeData
-- Removes a value from the inter-scene data store by key.
-- Clean up transient run data (e.g. last-checkpoint) when returning to the title.
do -- lurek.scene.removeData
  lurek.scene.setData("checkpoint", { x = 320, y = 240 })
  lurek.scene.removeData("checkpoint")
end

--@api-stub: lurek.scene.newDepthSorter
-- Creates a new DepthSorter for z-ordered draw batching.
-- Build one per scene in `enter` and call :flush() inside the scene's render method.
do -- lurek.scene.newDepthSorter
  local sorter = lurek.scene.newDepthSorter()
  sorter:setStable(true)
  lurek.log.debug("sorter ready, count=" .. sorter:getCount(), "render")
end

--@api-stub: lurek.scene.new
-- Creates a scene instance directly from a methods table.
-- Use for one-off scenes (title screen, game over) where no constructor reuse is needed.
do -- lurek.scene.new
  local title = lurek.scene.new({
    enter = function(self) self.t = 0 end,
    process = function(self, dt) self.t = self.t + dt end,
  })
  lurek.scene.push(title)
end

--@api-stub: lurek.scene.newScene
-- Alias for `lurek.scene.new`.
-- Prefer `new` in new code; this alias exists for compatibility with older scripts.
do -- lurek.scene.newScene
  local pause = lurek.scene.newScene({ enter = function(self) self.paused_at = os.time() end })
  lurek.scene.pushOverlay(pause)
end

--@api-stub: lurek.scene.define
-- Creates a reusable scene class â€” returns a zero-argument constructor function.
-- Use when many scenes share the same methods (e.g. one Level class for many level files).
do -- lurek.scene.define
  local Level = lurek.scene.define({
    enter = function(self) self.enemies = {} end,
    process = function(self, dt) end,
  })
  lurek.scene.push(Level())
  lurek.scene.push(Level())
end

--@api-stub: lurek.scene.getTransitionProgressEased
-- Returns the easing-adjusted transition progress from 0.0 to 1.0.
-- Use for visual blends (alpha, slide offset) so the curve matches the easing chosen on push.
do -- lurek.scene.getTransitionProgressEased

  function lurek.draw()
    local p = lurek.scene.getTransitionProgressEased()
    lurek.render.setColor(0, 0, 0, 1 - p)
  end
end

--@api-stub: lurek.scene.pushOverlay
-- Pushes a scene as a non-pausing overlay over the current top scene.
-- Use for HUD-style modals: the world keeps simulating beneath the overlay.
do -- lurek.scene.pushOverlay
  local hud = lurek.scene.new({ render = function(self) end })
  lurek.scene.pushOverlay(hud, "fade", 0.2)
end

--@api-stub: lurek.scene.isOverlay
-- Returns true if the current top scene was pushed as an overlay.
-- Branch input handling: overlays often consume only some keys and forward the rest.
do -- lurek.scene.isOverlay
  if lurek.scene.isOverlay() then
    lurek.log.debug("top is overlay; world still ticking", "scene")
  end
end

--@api-stub: lurek.scene.getActiveScenes
-- Returns a table array of all active scene tables.
-- Use to broadcast a custom event (resize, mute) to every active scene at once.
do -- lurek.scene.getActiveScenes
  for _, s in ipairs(lurek.scene.getActiveScenes()) do
    if s.on_resize then s:on_resize(1280, 720) end
  end
end

--@api-stub: lurek.scene.preload
-- Registers a loader function for a named scene.
-- Define heavy asset loads (textures, audio) here so pushPreloaded runs them lazily.
do -- lurek.scene.preload
  lurek.scene.preload("level_01", function()
    lurek.scene.registerScene("level_01", lurek.scene.new({ name = "level_01" }))
  end)
end

--@api-stub: lurek.scene.isPreloaded
-- Returns true if the named scene has been preloaded.
-- Show a loading spinner while the loader has not yet run.
do -- lurek.scene.isPreloaded
  if not lurek.scene.isPreloaded("level_01") then
    lurek.log.info("level_01 not yet loaded; will load on first push", "scene")
  end
end

--@api-stub: lurek.scene.pushPreloaded
-- Pushes a registered scene by name, running its loader if not yet preloaded.
-- Use from a "Start Game" button so first-push pays the load cost, subsequent pushes are instant.
do -- lurek.scene.pushPreloaded
  lurek.scene.preload("level_02", function()
    lurek.scene.registerScene("level_02", lurek.scene.new({ name = "level_02" }))
  end)
  lurek.scene.pushPreloaded("level_02", "fade", 0.4, "ease_in_out", { from_save = false })
end

--@api-stub: lurek.scene.getTransitionTypes
-- Returns a table listing all supported transition type strings.
-- Use to build a dropdown in a settings menu so players can pick their preferred transition.
do -- lurek.scene.getTransitionTypes
  local options = lurek.scene.getTransitionTypes()
  for i, t in ipairs(options) do
    lurek.log.debug(i .. ": " .. t, "scene")
  end
end

--@api-stub: lurek.scene.serializeScene
-- Returns a snapshot of the scene stack as a Lua table: { stack=[name...], data={key=val} }.
-- Capture before quitting so the next launch can restore the run via deserializeScene.
do -- lurek.scene.serializeScene
  lurek.scene.setData("player", { hp = 75, gold = 12 })
  local snap = lurek.scene.serializeScene()
  lurek.log.info("snapshot has " .. #snap.stack .. " scenes", "save")
end

--@api-stub: lurek.scene.deserializeScene
-- Restores scene data_refs from a snapshot produced by serializeScene().
-- Call before pushing the first scene so its `enter` can read the restored data store.
do -- lurek.scene.deserializeScene
  local snap = { stack = {}, data = { player = { hp = 30, gold = 99 } } }
  lurek.scene.deserializeScene(snap)
  local p = lurek.scene.getData("player")
  lurek.log.info("restored hp=" .. p.hp, "save")
end

--@api-stub: lurek.scene.fade
-- Returns a fade cross-dissolve transition config table.
-- Capture the cfg once, then forward its fields into push/switchTo for consistent timing.
do -- lurek.scene.fade
  local cfg = lurek.scene.transitions.fade(0.4)
  lurek.scene.push(lurek.scene.new({}), cfg.type, cfg.duration, "ease_in_out")
end

--@api-stub: lurek.scene.slide
-- Returns a directional slide transition config table.
-- Pick a direction matching the player's intent ("right" for next-page, "left" for back).
do -- lurek.scene.slide
  local next_page = lurek.scene.transitions.slide("right", 0.3)
  lurek.scene.push(lurek.scene.new({}), next_page.type, next_page.duration)
end

--@api-stub: lurek.scene.wipe
-- Returns a wipe/curtain transition config table.
-- Use for dramatic chapter breaks where the screen should be obscured longer than a fade.
do -- lurek.scene.wipe
  local cfg = lurek.scene.transitions.wipe(0.6)
  lurek.scene.switchTo(lurek.scene.new({ name = "chapter_2" }), cfg.type, cfg.duration)
end

--@api-stub: lurek.scene.iris
-- Returns an iris in/out (circular reveal) transition config table.
-- Classic "spotlight" close used for game-over or player-death reveals.
do -- lurek.scene.iris
  local cfg = lurek.scene.transitions.iris(0.8)
  lurek.scene.switchTo(lurek.scene.new({ name = "game_over" }), cfg.type, cfg.duration, "ease_out")
end

-- â”€â”€ DepthSorter methods â”€â”€

--@api-stub: LDepthSorter:add
-- Registers a draw callback at the given depth layer.
-- Lower depth draws first (background); reuse one sorter per scene and clear() between frames.
do -- DepthSorter:add
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() lurek.log.debug("draw sky", "render") end, -100)
  sorter:add(function() lurek.log.debug("draw player", "render") end, 0)
  sorter:add(function() lurek.log.debug("draw fog", "render") end, 100)
end

--@api-stub: LDepthSorter:addObject
-- Registers a table object with a draw method at the given depth.
-- Object's `depth` field selects the layer; its `drawSorted` method is invoked on flush.
do -- DepthSorter:addObject
  local sorter = lurek.scene.newDepthSorter()
  local enemy = { depth = 10, drawSorted = function(self) lurek.log.debug("enemy", "render") end }
  sorter:addObject(enemy)
end

--@api-stub: LDepthSorter:sort
-- Sorts all registered callbacks by depth ascending.
-- Call manually only if you want to inspect order before flush; flush() also sorts.
do -- DepthSorter:sort
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() end, 50)
  sorter:add(function() end, -10)
  sorter:sort()
end

--@api-stub: LDepthSorter:flush
-- Calls all draw callbacks in sorted depth order, then clears.
-- Drive this from `lurek.render`: rebuild + flush every frame so depth is always current.
do -- DepthSorter:flush
  local sorter = lurek.scene.newDepthSorter()
  function lurek.draw()
    sorter:add(function() lurek.log.debug("frame draw", "render") end, 0)
    sorter:flush()
  end
end

--@api-stub: LDepthSorter:setStable
-- Sets whether equal-depth entries preserve insertion order.
-- Enable when sprites at the same depth must draw in submission order (UI lists, particle bursts).
do -- DepthSorter:setStable
  local sorter = lurek.scene.newDepthSorter()
  sorter:setStable(true)
  sorter:add(function() lurek.log.debug("a", "render") end, 0)
  sorter:add(function() lurek.log.debug("b", "render") end, 0)
end

--@api-stub: LDepthSorter:isStable
-- Returns true if stable sort mode is enabled.
-- Branch on this in tests or in code that conditionally relies on insertion-order semantics.
do -- DepthSorter:isStable
  local sorter = lurek.scene.newDepthSorter()
  if not sorter:isStable() then
    sorter:setStable(true)
  end
end

--@api-stub: LDepthSorter:clear
-- Removes all registered callbacks without calling them.
-- Use to abandon a frame mid-build (e.g. paused) without drawing partial content.
do -- DepthSorter:clear
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() end, 0)
  sorter:clear()
  lurek.log.debug("cleared, count=" .. sorter:getCount(), "render")
end

--@api-stub: LDepthSorter:getCount
-- Returns the number of registered draw entries.
-- Use in debug overlays to detect runaway add() calls (forgot to flush?).
do -- DepthSorter:getCount
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() end, 0)
  sorter:add(function() end, 1)
  if sorter:getCount() > 1000 then lurek.log.warn("sorter overflow", "render") end
end

-- =============================================================================
-- COVERAGE: 2 uncovered lurek.scene API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DepthSorter methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- COVERAGE: 2 uncovered lurek.scene API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LDepthSorter methods
-- -----------------------------------------------------------------------------

-- ---- Example: LDepthSorter:type ---------------------------------------------
--@api-stub: LDepthSorter:type
-- Returns the type name of this object.
-- lDepthSorter_Example:type()  -- -> string
-- Useful for runtime type inspection and debug logging.
-- do  -- LDepthSorter:type
--   local sorter = lurek.scene.newDepthSorter()
--   local t = sorter:type()
--   lurek.log.info("LDepthSorter:type = " .. t, "scene")
-- end
--@api-stub: LDepthSorter:typeOf
-- Returns true if this object is of the given type.
-- lDepthSorter_Example:typeOf("hero")  -- -> boolean
-- Use for runtime polymorphism and defensive checks.
-- do  -- LDepthSorter:typeOf
--   local sorter = lurek.scene.newDepthSorter()
--   lurek.log.info("is LDepthSorter: " .. tostring(sorter:typeOf("LDepthSorter")), "scene")
--   lurek.log.info("is unknown: " .. tostring(sorter:typeOf("Unknown")), "scene")
-- end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

