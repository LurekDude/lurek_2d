-- content/examples/scene.lua
-- Scene stack management, transitions, depth sorting, and shared data.
-- Run: cargo run -- content/examples/scene.lua

--@api-stub: lurek.scene.new
-- Create a scene instance from a prototype table with lifecycle callbacks
do
  -- lurek.scene.new() sets up metatables so the instance inherits from the prototype.
  -- Provide lifecycle methods: enter, leave, pause, resume, process, draw, render, etc.
  local gameplay = lurek.scene.new({
    enter = function(self, params)
      self.level = params and params.level or 1
      self.score = 0
      self.enemies = {}
    end,
    process = function(self, dt)
      self.score = self.score + dt * 10
    end,
    draw = function(self)
      -- draw game world here
    end,
  })
  lurek.scene.push(gameplay, "none", 0, "linear", { level = 1 })
end

--@api-stub: lurek.scene.newScene
-- Alias for lurek.scene.new — creates a scene from an optional prototype table
do
  -- newScene is the older API name; both produce identical results.
  local pause_menu = lurek.scene.newScene({
    enter = function(self)
      self.paused_at = os.time()
    end,
    leave = function(self)
      lurek.log.info("unpaused after " .. (os.time() - self.paused_at) .. "s", "scene")
    end,
  })
  lurek.scene.pushOverlay(pause_menu)
end

--@api-stub: lurek.scene.define
-- Create a reusable scene constructor (factory function) from a prototype table
do
  -- define() returns a factory: each call produces a fresh instance inheriting prototype methods.
  -- Use this when you need multiple instances of the same scene type (e.g. procedural levels).
  local Level = lurek.scene.define({
    enter = function(self, params)
      self.id = params and params.id or 0
      self.tiles = {}
      self.timer = 0
    end,
    process = function(self, dt)
      self.timer = self.timer + dt
    end,
    leave = function(self)
      lurek.log.info("leaving level " .. self.id, "scene")
    end,
  })
  -- Each call to Level() creates an independent instance
  local lvl1 = Level()
  local lvl2 = Level()
  lurek.scene.push(lvl1, "none", 0, "linear", { id = 1 })
end

--@api-stub: lurek.scene.push
-- Push a new scene onto the stack, making it active (previous scene receives pause())
do
  -- push() adds to the top of the stack. The old scene gets pause(), new scene gets enter().
  -- Parameters: scene, transition type, duration, easing, params forwarded to enter().
  local menu = lurek.scene.new({
    enter = function(self, p)
      self.from = p and p.from or "unknown"
      lurek.log.info("menu entered from: " .. self.from, "scene")
    end,
  })
  lurek.scene.push(menu, "fade", 0.3, "ease_in_out", { from = "boot" })
end

--@api-stub: lurek.scene.pop
-- Pop the top scene off the stack, returning to the previous scene
do
  -- pop() removes the top scene. It receives leave(), the revealed scene receives resume().
  -- Commonly called when player presses Back or closes a menu.
  function lurek.process(dt)
    if lurek.scene.depth() > 1 and not lurek.scene.isTransitioning() then
      lurek.scene.pop("fade", 0.25, "linear")
    end
  end
end

--@api-stub: lurek.scene.switchTo
-- Replace the top scene without changing stack depth (old leaves, new enters)
do
  -- switchTo() is ideal for peer-level transitions: level1 -> level2, menu -> gameplay.
  -- The stack depth stays the same — no scene is added or removed.
  local next_level = lurek.scene.new({
    enter = function(self, params)
      self.score = params and params.score or 0
      self.level = params and params.level or 1
    end,
  })
  lurek.scene.switchTo(next_level, "wipe", 0.5, "ease_out", { score = 1240, level = 2 })
end

--@api-stub: LDepthSorter:clear
-- Remove ALL scenes from the stack (each receives leave() in order)
do
  -- clear() empties the entire stack. Use on shutdown or when returning to title screen.
  function lurek.quit()
    lurek.scene.clear()
    lurek.log.info("scene stack cleared on shutdown", "scene")
  end
end

--@api-stub: lurek.scene.popTo
-- Pop scenes until the named registered scene is on top
do
  -- popTo() unwinds the stack to a specific registered scene.
  -- Useful for "return to world map" from deeply nested menus.
  -- Returns false if the named scene is not on the stack.
  if lurek.scene.hasRegistered("world_map") and lurek.scene.depth() > 1 then
    local ok = lurek.scene.popTo("world_map")
    if not ok then
      lurek.log.warn("world_map not found on stack", "scene")
    end
  end
end

--@api-stub: lurek.scene.pushOverlay
-- Push a scene as a transparent overlay (underlying scene keeps updating and drawing)
do
  -- Overlays do NOT pause the scene below. Both update and render simultaneously.
  -- Perfect for pause menus, dialog boxes, inventory screens, debug panels.
  local dialog = lurek.scene.new({
    enter = function(self, params)
      self.text = params and params.text or "..."
      self.alpha = 0
    end,
    process = function(self, dt)
      self.alpha = math.min(1, self.alpha + dt * 3)
    end,
    render_ui = function(self)
      -- draw semi-transparent background and dialog text
    end,
  })
  lurek.scene.pushOverlay(dialog, "fade", 0.2, "ease_out", { text = "Save game?" })
end

--@api-stub: lurek.scene.pushPreloaded
-- Push a preloaded scene by name (runs its loader if not yet executed)
do
  -- Combines deferred loading with stack navigation in one call.
  -- If the loader hasn't run yet, it runs first, then the scene is pushed.
  lurek.scene.preload("boss_arena", function()
    lurek.scene.registerScene("boss_arena", lurek.scene.new({
      enter = function(self) self.boss_hp = 500 end,
    }))
  end)
  lurek.scene.pushPreloaded("boss_arena", "iris", 0.6, "ease_in_out", { from_save = false })
end

--@api-stub: lurek.scene.depth
-- Returns the total number of scenes on the stack (alias for getStackSize)
do
  -- depth() and getStackSize() are interchangeable. Returns 0 when stack is empty.
  if lurek.scene.depth() < 1 then
    lurek.scene.push(lurek.scene.new({ enter = function() end }))
    lurek.log.info("pushed initial scene, depth=" .. lurek.scene.depth(), "scene")
  end
end

--@api-stub: lurek.scene.getStackSize
-- Returns the total number of scenes on the stack, including overlays
do
  -- Use to assert expected navigation depth or detect stack corruption.
  local n = lurek.scene.getStackSize()
  if n == 0 then
    lurek.log.warn("no active scene; push a menu", "scene")
  elseif n > 10 then
    lurek.log.warn("stack depth " .. n .. " — possible leak", "scene")
  end
end

--@api-stub: lurek.scene.isEmpty
-- Returns true if the scene stack contains no scenes at all
do
  -- Guard against pop on empty stack, or detect when game should quit.
  if lurek.scene.isEmpty() then
    local boot = lurek.scene.new({ enter = function(self) self.ready = true end })
    lurek.scene.push(boot)
  end
end

--@api-stub: lurek.scene.getCurrent
-- Returns the scene table on top of the stack, or nil if empty
do
  -- Inspect or call methods on the active scene directly.
  local top = lurek.scene.getCurrent()
  if top then
    lurek.log.info("current scene: " .. (top.name or "unnamed"), "scene")
    if top.on_resize then
      top:on_resize(1280, 720)
    end
  end
end

--@api-stub: lurek.scene.isOverlay
-- Returns true if the current top scene was pushed via pushOverlay
do
  -- Use to decide whether to render the scene below or handle input differently.
  if lurek.scene.isOverlay() then
    lurek.log.debug("top is overlay; world still ticking beneath", "scene")
  end
end

--@api-stub: lurek.scene.getActiveScenes
-- Returns a Lua array of all active scene tables ordered by layer (lowest first)
do
  -- Iterate all scenes for custom broadcast (e.g. window resize notification).
  for _, s in ipairs(lurek.scene.getActiveScenes()) do
    if s.on_resize then
      s:on_resize(1280, 720)
    end
  end
end

--@api-stub: lurek.scene.setCurrentLayer
-- Set the rendering layer of the current top scene (higher = drawn later)
do
  -- Layers control draw order when multiple scenes are active simultaneously.
  -- Game world at layer 0, HUD overlay at layer 10.
  lurek.scene.push(lurek.scene.new({ name = "hud" }))
  lurek.scene.setCurrentLayer(10)
end

--@api-stub: lurek.scene.getCurrentLayer
-- Get the rendering layer of the current top scene (0 if empty or unset)
do
  local layer = lurek.scene.getCurrentLayer()
  lurek.log.debug("current scene layer=" .. layer, "scene")
end

--@api-stub: lurek.scene.update
-- Advance active transition and call update(self, dt) on the top scene
do
  -- Call once per frame from your main loop. Drives scene logic and transition timing.
  -- dt should come from lurek.timer.getDelta() or a fixed timestep.
  local sim_dt = 1 / 60
  for _ = 1, 30 do
    lurek.scene.update(sim_dt)
  end
end

--@api-stub: lurek.scene.process
-- Call ready() once on new scenes, then process(self, dt) on every active scene by layer
do
  -- process() is for deterministic game-logic ticks at a fixed time step.
  -- All active scenes (including overlays and underlying ones) receive this callback.
  local logic = lurek.scene.new({
    process = function(self, dt)
      self.t = (self.t or 0) + dt
    end,
  })
  lurek.scene.push(logic)
  lurek.scene.process(1 / 60)
end

--@api-stub: lurek.scene.processPhysics
-- Call process_physics(self, dt) on every active scene ordered by layer
do
  -- Run after your physics world step so scenes can react to collisions,
  -- apply forces, or sync sprite positions with physics bodies.
  local fixed_dt = 1 / 120
  function lurek.process(_)
    lurek.scene.processPhysics(fixed_dt)
  end
end

--@api-stub: lurek.scene.processLate
-- Call process_late(self, dt) on every active scene after all other processing
do
  -- Ideal for camera follow, HUD sync, deferred cleanup, or anything that
  -- depends on final positions of game objects after physics and logic.
  function lurek.process(dt)
    lurek.scene.processLate(dt)
  end
end

--@api-stub: lurek.scene.draw
-- Call draw(self) on every scene from bottom to top (legacy draw callback)
do
  -- Legacy draw path. Prefer render() + renderUi() for world/screen separation.
  function lurek.draw()
    lurek.scene.draw()
  end
end

--@api-stub: lurek.scene.render
-- Call render(self) on every scene from bottom to top (world-space rendering)
do
  -- Preferred world-space callback: draw sprites, tilemaps, particles here.
  -- Runs before renderUi().
  function lurek.draw()
    lurek.scene.render()
  end
end

--@api-stub: lurek.scene.renderUi
-- Call render_ui(self) on every scene from bottom to top (screen-space HUD)
do
  -- Screen-space HUD: health bars, score, menus. Draws on top of render().
  function lurek.draw_ui()
    lurek.scene.renderUi()
  end
end

--@api-stub: lurek.scene.isTransitioning
-- Returns true if a scene transition animation is currently playing
do
  -- Block input or skip certain logic during transitions to prevent glitches.
  function lurek.process(_)
    if lurek.scene.isTransitioning() then
      return -- skip game logic while transitioning
    end
    -- normal game logic here
  end
end

--@api-stub: lurek.scene.getTransitionProgress
-- Returns the raw linear progress (0.0 to 1.0) of the current transition
do
  -- Linear progress ignores easing. Returns 0 when no transition is active.
  -- Use getTransitionProgressEased() for smooth non-linear values.
  function lurek.process(_)
    local p = lurek.scene.getTransitionProgress()
    if p > 0 and p < 1 then
      lurek.log.debug(string.format("transition %.0f%%", p * 100), "scene")
    end
  end
end

--@api-stub: lurek.scene.getTransitionProgressEased
-- Returns the eased progress (0.0 to 1.0) with the easing curve applied
do
  -- Use this for smooth animation values (e.g. fading a black overlay).
  function lurek.draw()
    local p = lurek.scene.getTransitionProgressEased()
    if p > 0 then
      -- Draw a black overlay that fades out as transition progresses
      lurek.render.setColor(0, 0, 0, 1 - p)
    end
  end
end

--@api-stub: lurek.scene.queueTransition
-- Queue a transition to play after the current one finishes (FIFO order)
do
  -- Multiple queued transitions execute sequentially for cinematic sequences.
  -- e.g. fade-out then slide-in for a dramatic scene change.
  lurek.scene.push(lurek.scene.new({}), "fade", 0.4, "linear")
  lurek.scene.queueTransition("wipe", 0.35, "ease_out")
  lurek.scene.queueTransition("fade", 0.2, "linear")
end

--@api-stub: lurek.scene.getQueuedTransitionCount
-- Returns the number of transitions waiting in the queue
do
  local queued = lurek.scene.getQueuedTransitionCount()
  if queued > 0 then
    lurek.log.debug("still " .. queued .. " transitions queued", "scene")
  end
end

--@api-stub: lurek.scene.clearQueuedTransitions
-- Discard all queued transitions without affecting the current one
do
  -- Cancel a planned transition sequence mid-way (e.g. player skips cutscene).
  lurek.scene.clearQueuedTransitions()
  lurek.log.debug("transition queue cleared", "scene")
end

--@api-stub: lurek.scene.getTransitionTypes
-- Returns a Lua array of all supported transition type name strings
do
  -- Discover available transitions at runtime or build a picker UI.
  local types = lurek.scene.getTransitionTypes()
  for i, name in ipairs(types) do
    lurek.log.debug(i .. ": " .. name, "scene")
  end
  -- Expected: "none", "fade", "slideleft", "slideright", "slideup", "slidedown",
  --           "wipe", "iris", "zoom", "crossfade"
end

--@api-stub: lurek.scene.fade
-- Transition helper: build a fade descriptor table
do
  -- lurek.scene.transitions.fade() returns {type="fade", duration=...}
  -- Pass its fields to push/switchTo for convenience.
  local cfg = lurek.scene.transitions.fade(0.4)
  local title = lurek.scene.new({ name = "title" })
  lurek.scene.push(title, cfg.type, cfg.duration, "ease_in_out")
end

--@api-stub: lurek.scene.slide
-- Transition helper: build a directional slide descriptor table
do
  -- direction: "left", "right", "up", "down". New scene slides in from that edge.
  local cfg = lurek.scene.transitions.slide("right", 0.3)
  local next_page = lurek.scene.new({ name = "page_2" })
  lurek.scene.push(next_page, cfg.type, cfg.duration)
end

--@api-stub: lurek.scene.wipe
-- Transition helper: build a horizontal wipe descriptor table
do
  -- A wipe bar sweeps across the screen to reveal the new scene.
  local cfg = lurek.scene.transitions.wipe(0.6)
  lurek.scene.switchTo(lurek.scene.new({ name = "chapter_2" }), cfg.type, cfg.duration)
end

--@api-stub: lurek.scene.iris
-- Transition helper: build a circular iris descriptor table
do
  -- Classic cartoon-style circle aperture that opens or closes.
  local cfg = lurek.scene.transitions.iris(0.8)
  lurek.scene.switchTo(lurek.scene.new({ name = "game_over" }), cfg.type, cfg.duration, "ease_out")
end

--@api-stub: lurek.scene.registerScene
-- Register a scene table under a unique name for later retrieval or navigation
do
  -- Registering does NOT push the scene. Use for popTo(), getRegistered(), pushPreloaded().
  local options = lurek.scene.new({
    enter = function(self) self.volume = 0.8 end,
  })
  lurek.scene.registerScene("options", options)
  lurek.scene.registerScene("world_map", lurek.scene.new({ name = "world_map" }))
end

--@api-stub: lurek.scene.getRegistered
-- Retrieve a registered scene table by name, or nil if not found
do
  -- Does not affect the stack. Use to inspect or modify a registered scene.
  lurek.scene.registerScene("inventory", lurek.scene.new({ slots = {} }))
  local inv = lurek.scene.getRegistered("inventory")
  if inv then
    inv.slots[1] = "health_potion"
    inv.slots[2] = "iron_sword"
  end
end

--@api-stub: lurek.scene.hasRegistered
-- Check whether a scene is registered under the given name
do
  if not lurek.scene.hasRegistered("credits") then
    lurek.scene.registerScene("credits", lurek.scene.new({
      enter = function(self) self.scroll_y = 0 end,
    }))
  end
end

--@api-stub: lurek.scene.unregisterScene
-- Remove a scene registration by name (does not pop if active)
do
  -- Removes only the name mapping. If the scene is on the stack, it stays there.
  lurek.scene.registerScene("tutorial", lurek.scene.new({}))
  lurek.scene.unregisterScene("tutorial")
  lurek.log.debug("tutorial unregistered", "scene")
end

--@api-stub: lurek.scene.getRegisteredNames
-- Returns an array of all currently registered scene name strings
do
  -- Useful for debugging or building dynamic scene-selection menus.
  for _, name in ipairs(lurek.scene.getRegisteredNames()) do
    lurek.log.info("registered: " .. name, "scene")
  end
end

--@api-stub: lurek.scene.preload
-- Register a deferred-loading function (runs on first pushPreloaded call)
do
  -- The loader does NOT run immediately. It runs lazily on first push.
  -- Use this to spread heavy initialization across loading screens.
  lurek.scene.preload("dungeon_01", function()
    -- Heavy asset loading happens here, only when the scene is first needed
    local dungeon = lurek.scene.new({
      enter = function(self) self.room = 1 end,
      name = "dungeon_01",
    })
    lurek.scene.registerScene("dungeon_01", dungeon)
  end)
end

--@api-stub: lurek.scene.isPreloaded
-- Returns true if the named preload loader has already executed
do
  -- Once a loader runs, subsequent pushPreloaded calls skip it.
  if not lurek.scene.isPreloaded("dungeon_01") then
    lurek.log.info("dungeon_01 not yet loaded; will load on first push", "scene")
  end
end

--@api-stub: lurek.scene.setData
-- Store a value in the scene module's shared data map (keyed by string)
do
  -- Shared data lets scenes pass information without direct references.
  -- Common pattern: menu sets data, gameplay reads it in enter().
  lurek.scene.setData("player", { hp = 100, gold = 25, name = "Hero" })
  lurek.scene.setData("difficulty", "normal")
  lurek.scene.setData("selected_level", 3)
end

--@api-stub: lurek.scene.getData
-- Retrieve a value from the shared data map by key, or nil if unset
do
  -- Commonly used in enter() to read parameters from the previous scene.
  lurek.scene.setData("score", 1240)
  local score = lurek.scene.getData("score") or 0
  if score > 1000 then
    lurek.log.info("high score: " .. score, "scene")
  end
end

--@api-stub: lurek.scene.hasData
-- Check whether a key exists in the shared data map
do
  -- Check before reading to distinguish nil from "never set".
  if not lurek.scene.hasData("player") then
    lurek.scene.setData("player", { hp = 100, gold = 0 })
  end
end

--@api-stub: lurek.scene.removeData
-- Remove a key and its value from the shared data map
do
  -- Clean up transient data (e.g. checkpoint cleared after use).
  lurek.scene.setData("checkpoint", { x = 320, y = 240 })
  lurek.scene.removeData("checkpoint")
end

--@api-stub: lurek.scene.serializeScene
-- Capture the scene stack state as a serializable snapshot table
do
  -- Returns {stack = {...}, data = {...}} for save/load workflows.
  -- The stack contains registered names; data is the shared key-value map.
  lurek.scene.setData("player", { hp = 75, gold = 12 })
  local snap = lurek.scene.serializeScene()
  lurek.log.info("snapshot: " .. #snap.stack .. " scenes, data keys present", "save")
end

--@api-stub: lurek.scene.deserializeScene
-- Restore shared data from a previously-serialized snapshot table
do
  -- Only the data map is restored; rebuild the stack manually by pushing scenes.
  local snap = { stack = {}, data = { player = { hp = 30, gold = 99 } } }
  lurek.scene.deserializeScene(snap)
  local p = lurek.scene.getData("player")
  if p then
    lurek.log.info("restored hp=" .. p.hp .. " gold=" .. p.gold, "save")
  end
end

--@api-stub: lurek.scene.newDepthSorter
-- Create an LDepthSorter for collecting drawables and flushing in depth order
do
  -- Allocate one per scene or per rendering pass. Lower depth = drawn first (behind).
  local sorter = lurek.scene.newDepthSorter()
  sorter:setStable(true)
  lurek.log.debug("sorter ready, count=" .. sorter:getCount(), "render")
end

--@api-stub: LDepthSorter:add
-- Register a draw callback at a given depth value for back-to-front rendering
do
  -- Lower depth values draw first (behind), higher values draw last (on top).
  -- Use for simple draw calls where each entity has a z-layer.
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() lurek.log.debug("draw sky bg", "render") end, -100)
  sorter:add(function() lurek.log.debug("draw player", "render") end, 0)
  sorter:add(function() lurek.log.debug("draw foreground fog", "render") end, 100)
  sorter:flush()
end

--@api-stub: LDepthSorter:addObject
-- Register a game object table (must have depth field and drawSorted method)
do
  -- Object must expose: numeric `depth` field + `drawSorted(self)` method.
  -- Ideal for entity-based architectures where objects manage their own drawing.
  local sorter = lurek.scene.newDepthSorter()
  local enemy = {
    depth = 10,
    drawSorted = function(self)
      lurek.log.debug("draw enemy at depth " .. self.depth, "render")
    end,
  }
  local coin = {
    depth = 5,
    drawSorted = function(self)
      lurek.log.debug("draw coin at depth " .. self.depth, "render")
    end,
  }
  sorter:addObject(enemy)
  sorter:addObject(coin)
  sorter:flush() -- coin draws first (depth 5), then enemy (depth 10)
end

--@api-stub: LDepthSorter:sort
-- Sort all entries by depth without executing callbacks (inspect order before drawing)
do
  -- Normally flush() sorts automatically. Use sort() only to inspect order before draw.
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() end, 50)
  sorter:add(function() end, -10)
  sorter:add(function() end, 25)
  sorter:sort()
  -- Entries are now ordered: -10, 25, 50 (but not yet drawn)
end

--@api-stub: LDepthSorter:flush
-- Sort all entries, execute callbacks in depth order, then clear for next frame
do
  -- Standard one-call render path. Call once per frame inside draw() or render().
  local sorter = lurek.scene.newDepthSorter()
  function lurek.draw()
    -- Each frame: add entities, then flush to draw in correct order
    sorter:add(function() lurek.log.debug("ground", "render") end, 0)
    sorter:add(function() lurek.log.debug("player", "render") end, 5)
    sorter:add(function() lurek.log.debug("clouds", "render") end, 99)
    sorter:flush()
    -- sorter is now empty, ready for next frame
  end
end

--@api-stub: LDepthSorter:clear
-- Discard all pending entries without executing any draw callbacks
do
  -- Use when a scene is interrupted or destroyed before its normal flush call.
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() end, 0)
  sorter:add(function() end, 1)
  sorter:clear()
  lurek.log.debug("cleared, count=" .. sorter:getCount(), "render") -- count=0
end

--@api-stub: LDepthSorter:getCount
-- Returns the number of draw entries queued for the next flush
do
  -- Useful for debugging or deciding whether to skip an empty render pass.
  local sorter = lurek.scene.newDepthSorter()
  sorter:add(function() end, 0)
  sorter:add(function() end, 1)
  sorter:add(function() end, 2)
  local count = sorter:getCount()
  if count == 0 then
    lurek.log.debug("nothing to draw, skip flush", "render")
  else
    lurek.log.debug("flushing " .. count .. " entries", "render")
    sorter:flush()
  end
end

--@api-stub: LDepthSorter:setStable
-- Enable or disable stable sorting (preserves insertion order at equal depth)
do
  -- Stable sort prevents visual flickering between overlapping sprites at the same layer.
  -- Unstable is slightly faster but may swap equal-depth items between frames.
  local sorter = lurek.scene.newDepthSorter()
  sorter:setStable(true)
  -- These two items at depth 0 will always draw in insertion order (a before b)
  sorter:add(function() lurek.log.debug("sprite_a", "render") end, 0)
  sorter:add(function() lurek.log.debug("sprite_b", "render") end, 0)
  sorter:flush()
end

--@api-stub: LDepthSorter:isStable
-- Returns true if stable sorting is enabled
do
  local sorter = lurek.scene.newDepthSorter()
  if not sorter:isStable() then
    sorter:setStable(true)
    lurek.log.debug("enabled stable sort", "render")
  end
end

--@api-stub: LDepthSorter:type
-- Returns the type name string "LDepthSorter"
do
  local ds = lurek.scene.newDepthSorter()
  lurek.log.info("type: " .. ds:type(), "scene") -- "LDepthSorter"
end

--@api-stub: LDepthSorter:typeOf
-- Check whether this object matches a given type name
do
  -- Accepts "LDepthSorter" or "Object".
  local ds = lurek.scene.newDepthSorter()
  lurek.log.info("is LDepthSorter: " .. tostring(ds:typeOf("LDepthSorter")), "scene") -- true
  lurek.log.info("is Object: " .. tostring(ds:typeOf("Object")), "scene")             -- true
  lurek.log.info("is Sprite: " .. tostring(ds:typeOf("Sprite")), "scene")             -- false
end

print("content/examples/scene.lua")

-- ---- Stub: lurek.scene.clear --------------------------------------------
--@api-stub: lurek.scene.clear
-- Removes all entities and components from the active scene.
do
  lurek.scene.clear()
  lurek.log.debug("scene cleared", "example")
end
