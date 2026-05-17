-- content/examples/animation.lua
-- lurek.animation API examples.
-- Run: cargo run -- content/examples/animation.lua

-- =============================================================================
-- Module-level constructors
-- =============================================================================

--@api-stub: lurek.animation.new
-- Creates an empty animation with no frames or clips
do
  -- Start by creating an empty animation, then define frames and clips manually.
  -- This is the most flexible approach for spritesheets with irregular layouts.
  local hero = lurek.animation.new()

  -- Add individual frame rectangles (x, y, w, h) from a spritesheet.
  -- Each frame returns its zero-based index for use in clip definitions.
  hero:addFrame(0, 0, 32, 32)   -- frame 0: idle pose
  hero:addFrame(32, 0, 32, 32)  -- frame 1: step left
  hero:addFrame(64, 0, 32, 32)  -- frame 2: step right

  -- A clip groups frame indices, sets playback FPS, and defines looping.
  -- "idle" uses frames {0, 1} at 4 FPS and loops forever.
  hero:addClip("idle", {0, 1}, 4, true)

  -- Start playing the clip by name. Returns false if the clip does not exist.
  hero:play("idle")
end

--@api-stub: lurek.animation.fromAseprite
-- Loads an animation from an Aseprite JSON export string
do
  -- Aseprite's "Export Sprite Sheet" produces a JSON file describing frames and tags.
  -- Pass the raw JSON string to fromAseprite to auto-create frames and clips
  -- from the "frameTags" array. Each tag becomes a named clip.
  local json = '{"frames":{"hero 0.ase":{"frame":{"x":0,"y":0,"w":32,"h":32},"duration":100}},'
    .. '"meta":{"size":{"w":32,"h":32},"frameTags":[{"name":"walk","from":0,"to":0,"direction":"forward"}]}}'
  local hero = lurek.animation.fromAseprite(json)
  assert(hero, "fromAseprite must return an animation")

  -- After loading, clips are ready to play by their Aseprite tag name.
  hero:play("walk")
end

--@api-stub: lurek.animation.newStateMachine
-- Creates an animation state machine by consuming an animation handle
do
  -- A state machine owns the animation and switches clips based on parameter-driven transitions.
  -- Useful for characters with idle/walk/run/jump states driven by gameplay variables.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:addClip("run", {0, 1}, 12, true)

  -- The second argument is the initial state name. After creation, the animation
  -- handle is consumed — use the state machine for all further playback control.
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  fsm:addState("run", "run", true)
  fsm:addTransition("idle", "run", "speed > 0.5")
end

--@api-stub: lurek.animation.newCurve
-- Creates an empty animation curve
do
  -- Animation curves interpolate a numeric value over time using keyframes.
  -- Use them for camera zoom, fade-in/out alpha, health bar smoothing, etc.
  local zoom = lurek.animation.newCurve()

  -- Each keyframe is (time, value). The curve interpolates between them.
  zoom:addKeyframe(0.0, 1.0)  -- at t=0, zoom is 1x
  zoom:addKeyframe(1.5, 2.0)  -- at t=1.5s, zoom is 2x

  -- eval() returns the interpolated value at any time position.
  local current = zoom:eval(0.75)
  lurek.log.info("camera zoom at t=0.75 -> " .. current, "anim")
end

--@api-stub: lurek.animation.newSyncGroup
-- Creates an empty animation synchronization group
do
  -- Sync groups coordinate playback across multiple animation handles.
  -- Use them for marching soldiers, synchronized dance moves, or formation units.
  local squad = lurek.animation.newSyncGroup()

  -- Add handles (or IDs) of animations that should stay in lockstep.
  squad:add(1)
  squad:add(2)
  lurek.log.info("synced animations: " .. squad:memberCount(), "anim")
end

--@api-stub: lurek.animation.newBlendLayerSet
-- Creates an empty blend layer set for layered animation playback
do
  -- Blend layers let you combine multiple clips on different body parts.
  -- A common pattern: "base" layer runs full-body locomotion, "upper" layer
  -- overrides the spine and arms for aiming or attacking.
  local bls = lurek.animation.newBlendLayerSet()

  -- Each layer has a name, clip, weight (0-1), and optional bone mask.
  -- Without a bone mask, the layer affects the whole skeleton.
  bls:addLayer("base", "run", 1.0)

  -- With a bone mask, only listed bones are affected by this layer.
  bls:addLayer("upper", "aim", 0.8, {"spine", "arm_r", "arm_l"})
end

--@api-stub: lurek.animation.buildCharacter
-- Builds a complete character animation bundle from a configuration table
do
  -- buildCharacter is a convenience function that creates an animation with
  -- grid-based frames, multiple clips, and optionally a state machine — all
  -- from a single declarative configuration table. Ideal for uniform spritesheets.
  local bundle = lurek.animation.buildCharacter({
    texW = 128,       -- spritesheet total width
    texH = 64,        -- spritesheet total height
    frameW = 32,      -- each frame cell width
    frameH = 32,      -- each frame cell height
    clips = {
      -- Each clip auto-slices frames from the grid starting at cell index "start"
      { name = "idle", start = 0, count = 2, fps = 4, looping = true, mode = "forward" },
      { name = "run",  start = 2, count = 4, fps = 10, looping = true, mode = "forward" },
      { name = "jump", start = 6, count = 2, fps = 8, looping = false, mode = "forward" },
    },
    -- Optional: define states and transitions to get a stateMachine in the bundle.
    states = {
      { name = "idle", clip = "idle", looping = true },
      { name = "run",  clip = "run",  looping = true },
      { name = "jump", clip = "jump", looping = false },
    },
    transitions = {
      { from = "idle", to = "run",  condition = "speed > 0.5" },
      { from = "run",  to = "idle", condition = "speed < 0.1" },
      { from = "idle", to = "jump", condition = "jumping == true" },
    },
    initialState = "idle",
  })

  -- The returned table has "animation" (always) and "stateMachine" (when states provided).
  if bundle and bundle.animation then
    lurek.log.info("character clips: " .. bundle.animation:getClipCount(), "anim")
  end
  if bundle and bundle.stateMachine then
    lurek.log.info("FSM initial state: " .. bundle.stateMachine:getState(), "anim")
  end
end

-- =============================================================================
-- LAnimation methods — frame and clip management
-- =============================================================================

--@api-stub: Animation:addFrame
-- Adds a frame to this animation.
do
  -- Each frame is a rectangle region (x, y, w, h) in your spritesheet texture.
  -- Returns the zero-based index of the newly added frame.
  local anim = lurek.animation.new()
  local idx0 = anim:addFrame(0, 0, 48, 64)    -- large character frame
  local idx1 = anim:addFrame(48, 0, 48, 64)   -- second frame in row
  lurek.log.debug("added frames at indices " .. idx0 .. ", " .. idx1, "anim")
end

--@api-stub: Animation:addFramesFromRects
-- Adds a frames from rects to this animation.
do
  -- When frames have irregular sizes or positions (packed atlas), pass a table of rects.
  -- Each rect must have numeric x, y, w, h fields. Returns the number of frames added.
  local anim = lurek.animation.new()
  local added = anim:addFramesFromRects({
    { x = 0,  y = 0, w = 32, h = 32 },  -- standing
    { x = 34, y = 0, w = 30, h = 32 },  -- mid-step (slightly narrower)
    { x = 66, y = 0, w = 32, h = 32 },  -- full stride
  })
  lurek.log.debug("added " .. tostring(added) .. " irregular frames", "anim")
end

--@api-stub: Animation:addFramesFromGrid
-- Adds a frames from grid to this animation.
do
  -- For uniform spritesheets, addFramesFromGrid auto-calculates frame rects.
  -- Parameters: texture width, texture height, frame width, frame height,
  -- starting cell index (zero-based), and number of frames to add.
  local anim = lurek.animation.new()

  -- A 256x64 spritesheet with 32x32 cells has 8 columns x 2 rows = 16 cells.
  -- Import 8 frames starting from cell 0 (the first row).
  local n = anim:addFramesFromGrid(256, 64, 32, 32, 0, 8)
  lurek.log.info("imported " .. n .. " grid frames", "anim")
end

--@api-stub: Animation:addClip
-- Adds a clip to this animation.
do
  -- A clip groups frame indices into a named animation sequence.
  -- Parameters: name, frame indices table, FPS, looping flag, and optional mode.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)   -- 0
  anim:addFrame(32, 0, 32, 32)  -- 1
  anim:addFrame(64, 0, 32, 32)  -- 2
  anim:addFrame(96, 0, 32, 32)  -- 3

  -- Use frame indices to define which frames belong to each clip.
  -- Different clips can share the same frames.
  anim:addClip("walk", {0, 1, 2, 3}, 8, true)        -- loops at 8 FPS
  anim:addClip("idle", {0, 1}, 4, true)               -- slower 2-frame idle
  anim:addClip("hit_react", {2, 3, 0}, 12, false)    -- one-shot reaction

  anim:play("walk")
  lurek.log.info("clip count: " .. anim:getClipCount(), "anim")
end

--@api-stub: Animation:addClipFromGrid
-- Adds a clip from grid to this animation.
do
  -- Combines addFramesFromGrid + addClip in one call for uniform spritesheets.
  -- Internally slices the grid, creates frame entries, then registers the clip.
  local anim = lurek.animation.new()

  -- First add some base frames for other clips
  anim:addFramesFromGrid(128, 128, 32, 32, 0, 16)

  -- Now add a new clip that also auto-creates its own frames from the grid.
  -- "run" clip: 4 frames starting at cell 4, playing at 10 FPS, looping.
  anim:addClipFromGrid("run", 128, 128, 32, 32, 4, 4, 10, true)
  anim:play("run")
end

-- =============================================================================
-- LAnimation methods — playback control
-- =============================================================================

--@api-stub: Animation:play
-- Starts playback of on this animation.
do
  -- play() starts a named clip from the beginning. Returns true if the clip exists.
  -- Use this for hard-switching between animations (no crossfade).
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("walk", {0, 1}, 8, true)
  anim:addClip("attack", {0}, 12, false)

  -- Always check the return value if clip registration is dynamic.
  if not anim:play("walk") then
    lurek.log.warn("clip 'walk' not registered — check spritesheet setup", "anim")
  end
end

--@api-stub: Animation:stop
-- Stops the current operation or playback on this animation.
do
  -- stop() halts playback and resets internal state. The animation will not
  -- advance on update() until play() is called again.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")

  -- Stop when the character reaches a cutscene trigger.
  anim:stop()
end

--@api-stub: Animation:pause
-- Pauses the current operation or playback on this animation.
do
  -- pause() freezes playback at the current frame without resetting.
  -- Useful for pause menus or freeze-frame effects.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("walk", {0, 1}, 8, true)
  anim:play("walk")

  -- Game paused — freeze all animations in place.
  anim:pause()
end

--@api-stub: Animation:resume
-- Resumes a previously paused operation or playback on this animation.
do
  -- resume() continues from where pause() left off — same clip, same frame position.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("walk", {0, 1}, 8, true)
  anim:play("walk")
  anim:pause()

  -- Player unpauses the game.
  anim:resume()
end

--@api-stub: Animation:update
-- Advances this animation by the given delta time.
do
  -- Call update(dt) every frame to advance the animation clock.
  -- This drives frame switching based on the clip's FPS setting.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("walk", {0, 1}, 8, true)
  anim:play("walk")

  -- In your game loop, pass the frame delta time from lurek.process().
  function lurek.process(dt)
    anim:update(dt)
  end
end

--@api-stub: Animation:crossfade
-- Performs the crossfade operation on this animation.
do
  -- crossfade() smoothly blends from the current clip to a new clip over a duration.
  -- During the blend, getBlendState() returns interpolation data for rendering.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:addClip("run", {0, 1}, 8, true)
  anim:play("idle")

  -- Crossfade over 0.25 seconds for a smooth walk-to-run transition.
  -- Returns false if the target clip does not exist.
  local ok = anim:crossfade("run", 0.25)
  if ok then
    lurek.log.info("crossfade to 'run' started (0.25s blend)", "anim")
  end
end

-- =============================================================================
-- LAnimation methods — query state
-- =============================================================================

--@api-stub: Animation:getQuad
-- Returns the quad of this animation.
do
  -- getQuad() returns the current frame's texture rectangle as {x, y, w, h}.
  -- Use this to set the source rect when drawing a sprite with lurek.render.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("idle", {0, 1}, 4, true)
  anim:play("idle")

  -- In your draw callback, read the current quad for the sprite source rect.
  local q = anim:getQuad()
  if q then
    -- q.x, q.y = top-left corner in spritesheet; q.w, q.h = frame dimensions
    lurek.log.debug("drawing frame at (" .. q.x .. "," .. q.y .. ") size " .. q.w .. "x" .. q.h, "anim")
  end
end

--@api-stub: Animation:pollEvents
-- Performs the poll events operation on this animation.
do
  -- pollEvents() drains animation events since the last call.
  -- Events include "clip_finished" (one-shot clips) and "frame_changed".
  -- Use this to trigger sound effects on specific frames or detect attack end.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addFrame(64, 0, 32, 32)
  anim:addClip("attack", {0, 1, 2}, 12, false)  -- one-shot, does not loop
  anim:play("attack")

  function lurek.process(dt)
    anim:update(dt)
    -- Poll events every frame after update to catch animation signals.
    for _, ev in ipairs(anim:pollEvents()) do
      if ev.type == "clip_finished" then
        -- The attack animation ended — return to idle state.
        lurek.log.info("attack finished, switching to idle", "combat")
      end
    end
  end
end

--@api-stub: Animation:isPlaying
-- Returns true if this animation playing.
do
  -- isPlaying() checks if the animation is actively advancing frames.
  -- Use this to prevent input during attack animations or to gate state changes.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("swing", {0, 1}, 10, false)  -- one-shot swing
  anim:play("swing")

  -- Block player input while the attack animation is still playing.
  if anim:isPlaying() then
    lurek.log.debug("swing in progress — ignoring movement input", "combat")
  end
end

--@api-stub: Animation:isLooping
-- Returns true if this animation looping.
do
  -- isLooping() returns whether the currently active clip has looping enabled.
  -- Useful for determining if you need to manually handle clip end.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 2, true)
  anim:addClip("death", {0}, 1, false)
  anim:play("idle")

  -- Looping clips never fire "clip_finished" events — they just wrap around.
  if anim:isLooping() then
    lurek.log.debug("current clip loops — no need to poll for end", "anim")
  end
end

--@api-stub: Animation:getClip
-- Returns the clip of this animation.
do
  -- getClip() returns the name of the currently active clip, or nil if none.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("run", {0}, 12, true)
  anim:addClip("idle", {0}, 4, true)
  anim:play("run")

  -- Check what clip is active before deciding on transitions.
  local clip = anim:getClip()
  if clip == "run" then
    lurek.log.debug("character is running", "anim")
  end
end

--@api-stub: Animation:getSpeed
-- Returns the speed of this animation.
do
  -- getSpeed() returns the current playback speed multiplier (default 1.0).
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("run", {0}, 12, true)
  anim:play("run")

  -- Save the original speed before applying slow-motion.
  local original = anim:getSpeed()
  lurek.log.debug("current speed multiplier: " .. original, "anim")
end

--@api-stub: Animation:setSpeed
-- Sets the speed of this animation.
do
  -- setSpeed() multiplies the clip's base FPS. Use for slow-motion, fast-forward,
  -- or tying animation speed to character velocity.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("run", {0, 1}, 12, true)
  anim:play("run")

  -- Speed up animation as the character accelerates.
  local velocity = 5.0
  local max_speed = 10.0
  anim:setSpeed(velocity / max_speed * 2.0)  -- scale from 0x to 2x

  -- Slow motion: half speed for dramatic effect.
  anim:setSpeed(0.5)
end

--@api-stub: Animation:getFrameCount
-- Returns the number of frame items in this animation.
do
  -- getFrameCount() returns the total number of frame rectangles stored.
  -- Useful for validation after loading or building frame pools.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addFrame(64, 0, 32, 32)

  if anim:getFrameCount() ~= 3 then
    lurek.log.error("expected 3 frames in the pool", "anim")
  end
end

--@api-stub: Animation:getClipCount
-- Returns the number of clip items in this animation.
do
  -- getClipCount() returns how many named clips are registered.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:addClip("walk", {0}, 8, true)
  anim:addClip("attack", {0}, 12, false)

  lurek.log.info("registered " .. anim:getClipCount() .. " clips", "anim")
end

--@api-stub: Animation:getCurrentFrame
-- Returns the current frame of this animation.
do
  -- getCurrentFrame() returns the zero-based index of the frame being displayed.
  -- Use for syncing sound effects or hitboxes to specific frames.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)   -- 0: wind-up
  anim:addFrame(32, 0, 32, 32)  -- 1: contact
  anim:addFrame(64, 0, 32, 32)  -- 2: follow-through
  anim:addClip("slash", {0, 1, 2}, 10, false)
  anim:play("slash")

  -- Frame 1 is the "contact" frame — spawn hitbox and play sound here.
  if anim:getCurrentFrame() == 1 then
    lurek.log.info("slash contact frame — deal damage now", "combat")
  end
end

--@api-stub: Animation:setFrame
-- Sets the frame of this animation.
do
  -- setFrame() jumps directly to a specific frame index. Useful for manual
  -- scrubbing, syncing to external timelines, or showing a specific pose.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)   -- 0: closed door
  anim:addFrame(32, 0, 32, 32)  -- 1: partially open
  anim:addFrame(64, 0, 32, 32)  -- 2: fully open
  anim:addClip("door", {0, 1, 2}, 4, false)
  anim:play("door")

  -- Skip to the last frame instantly (door already open on level load).
  anim:setFrame(2)
end

--@api-stub: Animation:getBlendState
-- Returns the blend state of this animation.
do
  -- getBlendState() returns crossfade information during a transition.
  -- The table has "from" (quad), "to" (quad), and "blend" (0-1 factor).
  -- Returns nil when no crossfade is active.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:addClip("run", {1}, 8, true)
  anim:play("idle")
  anim:crossfade("run", 0.3)

  -- During crossfade, render both frames with alpha blending.
  local bs = anim:getBlendState()
  if bs then
    -- bs.blend goes from 0 (fully "from") to 1 (fully "to") over the duration.
    lurek.log.debug("crossfade progress: " .. string.format("%.0f%%", bs.blend * 100), "anim")
  end
end

--@api-stub: Animation:drawToImage
-- Draws or renders this animation to the current render target.
do
  -- drawToImage() rasterizes the current frame into an ImageData of given size.
  -- Useful for generating thumbnails, inventory icons, or preview images.
  pcall(function()
    local anim = lurek.animation.new()
    anim:addFrame(0, 0, 32, 32)
    anim:addClip("idle", {0}, 4, true)
    anim:play("idle")

    -- Render current frame to a 64x64 image for a character select screen.
    local thumbnail = anim:drawToImage(64, 64)
    lurek.log.info("generated thumbnail: " .. tostring(thumbnail), "anim")
  end)
end

--@api-stub: LAnimation:drawPreviewGrid
-- Draws a debug grid of all frames in this animation atlas at the given position and scale.
do
  -- drawPreviewGrid() renders ALL frames into a grid image for debugging.
  -- Parameters: number of columns, and pixel size per cell.
  -- Returns an ImageData you can display or save.
  local anim = lurek.animation.new()
  anim:addFramesFromGrid(128, 64, 32, 32, 0, 8)

  -- Show all 8 frames in a 4-column grid, 24px per cell.
  local preview = anim:drawPreviewGrid(4, 24)
  lurek.log.info("preview grid generated: " .. tostring(preview), "anim")
end

--@api-stub: LAnimation:getClipMode
-- Returns the current clip mode string, either "loop", "once", or "pingpong".
do
  -- getClipMode() queries the playback direction for a named clip.
  -- Returns "forward", "reverse", or "pingpong", or nil if the clip does not exist.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("walk", {0, 1}, 8, true, "pingpong")

  local mode = anim:getClipMode("walk")
  lurek.log.debug("walk clip mode: " .. tostring(mode), "anim")  -- "pingpong"
end

--@api-stub: LAnimation:setClipMode
-- Sets the clip playback mode to "loop", "once", or "pingpong" for this animation.
do
  -- setClipMode() changes direction for an existing clip at runtime.
  -- Modes: "forward" (default), "reverse" (last to first), "pingpong" (bounce).
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("idle", {0, 1}, 4, true)

  -- Switch idle to pingpong for a gentle breathing bob effect.
  anim:setClipMode("idle", "pingpong")
  lurek.log.info("idle mode now: " .. tostring(anim:getClipMode("idle")), "anim")
end

--@api-stub: LAnimation:type
-- Returns the Lua-visible type name for this animation handle
do
  local anim = lurek.animation.new()
  local t = anim:type()
  lurek.log.info("LAnimation:type = " .. t, "animation")  -- "LAnimation"
end

--@api-stub: LAnimation:typeOf
-- Returns whether this animation handle matches a supported type name
do
  local anim = lurek.animation.new()
  -- typeOf() checks against "LAnimation" and the generic "Object" base.
  lurek.log.info("is LAnimation: " .. tostring(anim:typeOf("LAnimation")), "animation")
  lurek.log.info("is Object: " .. tostring(anim:typeOf("Object")), "animation")
  lurek.log.info("is wrong: " .. tostring(anim:typeOf("Unknown")), "animation")
end

-- =============================================================================
-- LAnimStateMachine methods
-- =============================================================================

--@api-stub: AnimStateMachine:addState
-- Adds a state to this anim state machine.
do
  -- Each state maps a name to a clip and a looping flag.
  -- The state machine plays the associated clip when that state is active.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:addClip("run", {0, 1}, 12, true)
  anim:addClip("death", {1}, 1, false)

  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)   -- loops
  fsm:addState("run", "run", true)     -- loops
  fsm:addState("death", "death", false) -- plays once, stays on last frame
end

--@api-stub: AnimStateMachine:addTransition
-- Adds a transition to this anim state machine.
do
  -- Transitions define conditions that trigger automatic state changes.
  -- Conditions reference parameters set via setParam() and use comparison operators.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:addClip("run", {0, 1}, 12, true)

  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  fsm:addState("run", "run", true)

  -- When "speed" parameter exceeds 0.5, transition from idle to run.
  fsm:addTransition("idle", "run", "speed > 0.5")
  -- When "speed" drops below 0.1, transition back to idle.
  fsm:addTransition("run", "idle", "speed < 0.1")
end

--@api-stub: AnimStateMachine:update
-- Advances this anim state machine by the given delta time.
do
  -- update(dt) evaluates transition conditions and advances the animation.
  -- Call this every frame from lurek.process().
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)

  function lurek.process(dt)
    -- First set parameters from gameplay, then update the FSM.
    fsm:update(dt)
  end
end

--@api-stub: AnimStateMachine:getState
-- Returns the state of this anim state machine.
do
  -- getState() returns the name of the currently active state.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)

  -- Use the current state to drive gameplay logic (e.g., damage only in "attack" state).
  local state = fsm:getState()
  if state == "idle" then
    lurek.log.debug("character is idle", "anim")
  end
end

--@api-stub: AnimStateMachine:forceState
-- Performs the force state operation on this anim state machine.
do
  -- forceState() immediately jumps to a state, bypassing transition conditions.
  -- Use for interrupts like taking damage, dying, or cutscene overrides.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:addClip("dead", {0}, 1, false)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  fsm:addState("dead", "dead", false)

  -- Character died — force into death state regardless of current state.
  if not fsm:forceState("dead") then
    lurek.log.error("'dead' state not registered", "anim")
  end
end

--@api-stub: AnimStateMachine:setParam
-- Sets the param of this anim state machine.
do
  -- setParam() updates a named variable that transitions evaluate against.
  -- Supports numbers, booleans, and integers.
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:addClip("run", {0, 1}, 12, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  fsm:addState("run", "run", true)
  fsm:addTransition("idle", "run", "speed > 0.5")
  fsm:addTransition("run", "idle", "speed < 0.1")

  -- Each frame, feed gameplay variables into the FSM before update.
  function lurek.process(dt)
    local player_speed = 1.2  -- from physics or input
    fsm:setParam("speed", player_speed)
    fsm:update(dt)
  end
end

--@api-stub: AnimStateMachine:getQuad
-- Returns the quad of this anim state machine.
do
  -- getQuad() returns the current frame rect from the FSM's internal animation.
  -- Use this for rendering — it returns the same {x, y, w, h} table as Animation:getQuad().
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("idle", {0, 1}, 4, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)

  function lurek.draw()
    local q = fsm:getQuad()
    if q then
      -- Use q.x, q.y, q.w, q.h as the source rect for lurek.render.draw()
      lurek.log.debug("FSM frame: " .. q.w .. "x" .. q.h, "anim")
    end
  end
end

--@api-stub: LAnimStateMachine:type
-- Returns the Lua-visible type name for this animation state machine handle
do
  local fsm = lurek.animation.newStateMachine(lurek.animation.new(), "idle")
  local t = fsm:type()
  lurek.log.info("LAnimStateMachine:type = " .. t, "animation")  -- "LAnimStateMachine"
end

--@api-stub: LAnimStateMachine:typeOf
-- Returns whether this animation state machine handle matches a supported type name
do
  local fsm = lurek.animation.newStateMachine(lurek.animation.new(), "idle")
  lurek.log.info("is LAnimStateMachine: " .. tostring(fsm:typeOf("LAnimStateMachine")), "animation")
  lurek.log.info("is Object: " .. tostring(fsm:typeOf("Object")), "animation")
  lurek.log.info("is wrong: " .. tostring(fsm:typeOf("Unknown")), "animation")
end

-- =============================================================================
-- LBlendLayerSet methods
-- =============================================================================

--@api-stub: BlendLayerSet:addLayer
-- Adds a layer to this blend layer set.
do
  -- addLayer() registers a named blend layer with a clip, weight, and optional bone mask.
  -- Layers are evaluated in order — later layers override earlier ones on shared bones.
  local bls = lurek.animation.newBlendLayerSet()

  -- Base layer: full-body locomotion at full weight, no mask (affects everything).
  bls:addLayer("base", "run", 1.0)

  -- Upper-body aim layer: affects only spine and arms, blended at 90%.
  -- The bone mask limits which joints this layer controls.
  bls:addLayer("aim", "aim_rifle", 0.9, {"spine", "arm_r", "arm_l", "hand_r"})

  lurek.log.info("blend layers: " .. bls:len(), "anim")
end

--@api-stub: BlendLayerSet:removeLayer
-- Removes a layer from this blend layer set.
do
  -- removeLayer() removes a layer by name. Returns true if the layer existed.
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  bls:addLayer("upper", "aim", 0.5, {"spine"})

  -- Player holsters weapon — remove the aim layer.
  bls:removeLayer("upper")
  lurek.log.info("layers after remove: " .. bls:len(), "anim")
end

--@api-stub: BlendLayerSet:setWeight
-- Sets the weight of this blend layer set.
do
  -- setWeight() changes a layer's blend influence at runtime.
  -- Smoothly ramping weight creates fade-in/fade-out transitions between layers.
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  bls:addLayer("aim", "aim", 0.0, {"spine", "arm_r"})  -- start at 0 (invisible)

  -- Gradually bring in the aim layer as the player holds right-click.
  local aim_strength = 0.7
  bls:setWeight("aim", aim_strength)
end

--@api-stub: BlendLayerSet:getWeight
-- Returns the weight of this blend layer set.
do
  -- getWeight() returns the current weight for a named layer, or nil if not found.
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("aim", "aim", 0.5, {"spine"})

  local w = bls:getWeight("aim")
  if w and w > 0.5 then
    lurek.log.debug("aim layer is dominant (weight=" .. w .. ")", "anim")
  end
end

--@api-stub: BlendLayerSet:setMask
-- Sets the mask of this blend layer set.
do
  -- setMask() replaces a layer's bone mask at runtime.
  -- Use this to expand/shrink which body parts an animation affects.
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("aim", "aim_pistol", 1.0, {"arm_r"})  -- pistol: right arm only

  -- Player switches to two-handed rifle — expand mask to both arms and spine.
  bls:setMask("aim", {"spine", "arm_l", "arm_r", "hand_l", "hand_r"})
end

--@api-stub: BlendLayerSet:listLayers
-- Performs the list layers operation on this blend layer set.
do
  -- listLayers() returns an array of all layer details for debugging or UI display.
  -- Each entry has: name, clip_name, weight, and bones.
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "run", 1.0)
  bls:addLayer("aim", "aim_rifle", 0.8, {"spine", "arm_r"})

  for _, layer in ipairs(bls:listLayers()) do
    lurek.log.debug(layer.name .. " -> clip=" .. layer.clip_name .. " weight=" .. layer.weight, "anim")
  end
end

--@api-stub: BlendLayerSet:len
-- Performs the len operation on this blend layer set.
do
  -- len() returns the total number of layers currently registered.
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  bls:addLayer("upper", "wave", 0.5, {"arm_r"})

  if bls:len() == 0 then
    lurek.log.warn("blend set empty — character will have no animation", "anim")
  else
    lurek.log.info("active blend layers: " .. bls:len(), "anim")
  end
end

--@api-stub: LBlendLayerSet:type
-- Returns the Lua-visible type name for this blend layer set handle
do
  local bls = lurek.animation.newBlendLayerSet()
  local t = bls:type()
  lurek.log.info("LBlendLayerSet:type = " .. t, "animation")  -- "LBlendLayerSet"
end

--@api-stub: LBlendLayerSet:typeOf
-- Returns whether this blend layer set handle matches a supported type name
do
  local bls = lurek.animation.newBlendLayerSet()
  lurek.log.info("is LBlendLayerSet: " .. tostring(bls:typeOf("LBlendLayerSet")), "animation")
  lurek.log.info("is Object: " .. tostring(bls:typeOf("Object")), "animation")
  lurek.log.info("is wrong: " .. tostring(bls:typeOf("Unknown")), "animation")
end

-- =============================================================================
-- LAnimCurve methods
-- =============================================================================

--@api-stub: AnimCurve:addKeyframe
-- Adds a keyframe to this anim curve.
do
  -- Keyframes define (time, value) control points. The curve interpolates between them.
  -- Time does not need to start at 0 — it is just a parameter axis.
  local fade = lurek.animation.newCurve()

  -- Fade-in-out envelope: silent -> full -> silent over 2 seconds.
  fade:addKeyframe(0.0, 0.0)   -- start silent
  fade:addKeyframe(0.3, 1.0)   -- ramp up quickly
  fade:addKeyframe(1.7, 1.0)   -- hold at full
  fade:addKeyframe(2.0, 0.0)   -- fade out at the end
end

--@api-stub: AnimCurve:eval
-- Performs the eval operation on this anim curve.
do
  -- eval(t) returns the interpolated value at time t.
  -- Values outside the keyframe range are clamped to the nearest keyframe value.
  local fade = lurek.animation.newCurve()
  fade:addKeyframe(0.0, 0.0)
  fade:addKeyframe(1.0, 1.0)

  -- Sample at various points to drive visual properties.
  local alpha_25 = fade:eval(0.25)  -- approx 0.25 with linear interpolation
  local alpha_75 = fade:eval(0.75)  -- approx 0.75
  lurek.log.info("alpha at 25%: " .. string.format("%.2f", alpha_25), "anim")
end

--@api-stub: AnimCurve:setEasing
-- Sets the easing of this anim curve.
do
  -- setEasing() changes how the curve interpolates between keyframes.
  -- Modes: "step", "linear", "ease_in", "ease_out", "ease_in_out".
  local curve = lurek.animation.newCurve()
  curve:addKeyframe(0.0, 0.0)
  curve:addKeyframe(1.0, 1.0)

  -- "ease_in_out" gives smooth acceleration and deceleration — good for UI transitions.
  curve:setEasing("ease_in_out")

  -- "step" snaps to the next keyframe value — good for pixel-art frame timing.
  -- curve:setEasing("step")
end

--@api-stub: AnimCurve:setCustomEasing
-- Sets the custom easing of this anim curve.
do
  -- setCustomEasing() lets you provide a Lua function for the interpolation.
  -- The function receives t (0-1) and returns the eased value (0-1).
  local curve = lurek.animation.newCurve()
  curve:addKeyframe(0.0, 0.0)
  curve:addKeyframe(1.0, 1.0)

  -- Smoothstep easing: starts slow, speeds up, then slows down.
  curve:setCustomEasing(function(t)
    return t * t * (3 - 2 * t)
  end)

  -- Pass nil to remove custom easing and revert to the built-in mode.
  -- curve:setCustomEasing(nil)
end

--@api-stub: AnimCurve:keyframeCount
-- Performs the keyframe count operation on this anim curve.
do
  -- keyframeCount() returns the number of keyframes in the curve.
  -- A curve needs at least 2 keyframes to interpolate.
  local curve = lurek.animation.newCurve()
  curve:addKeyframe(0.0, 0.0)

  if curve:keyframeCount() < 2 then
    lurek.log.warn("curve needs at least 2 keyframes to produce a useful interpolation", "anim")
  end

  curve:addKeyframe(1.0, 1.0)
  lurek.log.debug("keyframes: " .. curve:keyframeCount(), "anim")  -- 2
end

--@api-stub: AnimCurve:clear
-- Clears all items from this anim curve.
do
  -- clear() removes all keyframes, resetting the curve for reuse.
  local curve = lurek.animation.newCurve()
  curve:addKeyframe(0.0, 0.5)
  curve:addKeyframe(1.0, 1.0)

  -- Rebuild the curve with new control points (e.g., difficulty changed).
  curve:clear()
  curve:addKeyframe(0.0, 0.0)
  curve:addKeyframe(2.0, 1.0)  -- slower ramp for easier difficulty
end

--@api-stub: LAnimCurve:type
-- Returns the Lua-visible type name for this animation curve handle
do
  local curve = lurek.animation.newCurve()
  local t = curve:type()
  lurek.log.info("LAnimCurve:type = " .. t, "animation")  -- "LAnimCurve"
end

--@api-stub: LAnimCurve:typeOf
-- Returns whether this animation curve handle matches a supported type name
do
  local curve = lurek.animation.newCurve()
  lurek.log.info("is LAnimCurve: " .. tostring(curve:typeOf("LAnimCurve")), "animation")
  lurek.log.info("is Object: " .. tostring(curve:typeOf("Object")), "animation")
  lurek.log.info("is wrong: " .. tostring(curve:typeOf("Unknown")), "animation")
end

-- =============================================================================
-- LAnimSyncGroup methods
-- =============================================================================

--@api-stub: AnimSyncGroup:add
-- Adds a  to this anim sync group.
do
  -- add() registers an animation handle in the sync group.
  -- All members will be coordinated to stay on the same playback phase.
  local squad = lurek.animation.newSyncGroup()
  squad:add(1)  -- soldier 1's animation handle
  squad:add(2)  -- soldier 2's animation handle
  squad:add(3)  -- soldier 3's animation handle
end

--@api-stub: AnimSyncGroup:remove
-- Removes a  from this anim sync group.
do
  -- remove() detaches a handle from the group. It will no longer be synchronized.
  local squad = lurek.animation.newSyncGroup()
  squad:add(1)
  squad:add(2)

  -- Soldier 1 broke formation — unsync their animation.
  squad:remove(1)
end

--@api-stub: AnimSyncGroup:clear
-- Clears all items from this anim sync group.
do
  -- clear() removes all members at once. Useful when disbanding a group.
  local squad = lurek.animation.newSyncGroup()
  squad:add(1)
  squad:add(2)
  squad:add(3)

  -- Battle ended — disband the synchronized formation.
  squad:clear()
end

--@api-stub: AnimSyncGroup:memberCount
-- Performs the member count operation on this anim sync group.
do
  -- memberCount() returns how many handles are currently tracked.
  local squad = lurek.animation.newSyncGroup()
  squad:add(1)
  squad:add(2)

  if squad:memberCount() > 0 then
    lurek.log.info("synchronized squad size: " .. squad:memberCount(), "anim")
  end
end

--@api-stub: LAnimSyncGroup:type
-- Returns the Lua-visible type name for this animation sync group handle
do
  local sg = lurek.animation.newSyncGroup()
  local t = sg:type()
  lurek.log.info("LAnimSyncGroup:type = " .. t, "animation")  -- "LAnimSyncGroup"
end

--@api-stub: LAnimSyncGroup:typeOf
-- Returns whether this animation sync group handle matches a supported type name
do
  local sg = lurek.animation.newSyncGroup()
  lurek.log.info("is LAnimSyncGroup: " .. tostring(sg:typeOf("LAnimSyncGroup")), "animation")
  lurek.log.info("is Object: " .. tostring(sg:typeOf("Object")), "animation")
  lurek.log.info("is wrong: " .. tostring(sg:typeOf("Unknown")), "animation")
end

print("content/examples/animation.lua")

-- =============================================================================
-- STUBS: 47 uncovered lurek.animation API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAnimCurve methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAnimCurve:addKeyframe ----------------------------------------
--@api-stub: LAnimCurve:addKeyframe
-- Adds a keyframe to the curve. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimCurve_stub:addKeyframe(t, 1.0)
-- (replace lAnimCurve_stub with your real LAnimCurve instance above)

-- ---- Stub: LAnimCurve:eval -----------------------------------------------
--@api-stub: LAnimCurve:eval
-- Evaluates the curve at a time or normalized position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimCurve_stub:eval(t)  -- -> number
-- (replace lAnimCurve_stub with your real LAnimCurve instance above)

-- ---- Stub: LAnimCurve:setEasing ------------------------------------------
--@api-stub: LAnimCurve:setEasing
-- Sets the built-in easing mode used between keyframes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimCurve_stub:setEasing(mode)
-- (replace lAnimCurve_stub with your real LAnimCurve instance above)

-- ---- Stub: LAnimCurve:keyframeCount --------------------------------------
--@api-stub: LAnimCurve:keyframeCount
-- Returns the number of keyframes stored in this curve.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimCurve_stub:keyframeCount()  -- -> integer
-- (replace lAnimCurve_stub with your real LAnimCurve instance above)

-- ---- Stub: LAnimCurve:setCustomEasing ------------------------------------
--@api-stub: LAnimCurve:setCustomEasing
-- Sets or clears a Lua callback used to evaluate custom easing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimCurve_stub:setCustomEasing(func)
-- (replace lAnimCurve_stub with your real LAnimCurve instance above)

-- ---- Stub: LAnimCurve:clear ----------------------------------------------
--@api-stub: LAnimCurve:clear
-- Removes all keyframes from this curve.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimCurve_stub:clear()
-- (replace lAnimCurve_stub with your real LAnimCurve instance above)

-- -----------------------------------------------------------------------------
-- LAnimStateMachine methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAnimStateMachine:update --------------------------------------
--@api-stub: LAnimStateMachine:update
-- Advances the animation state machine and its owned animation playback.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimStateMachine_stub:update(0.016)
-- (replace lAnimStateMachine_stub with your real LAnimStateMachine instance above)

-- ---- Stub: LAnimStateMachine:getState ------------------------------------
--@api-stub: LAnimStateMachine:getState
-- Returns the current animation state name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimStateMachine_stub:getState()  -- -> string
-- (replace lAnimStateMachine_stub with your real LAnimStateMachine instance above)

-- ---- Stub: LAnimStateMachine:forceState ----------------------------------
--@api-stub: LAnimStateMachine:forceState
-- Forces the state machine into a named state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimStateMachine_stub:forceState("hero")  -- -> boolean
-- (replace lAnimStateMachine_stub with your real LAnimStateMachine instance above)

-- ---- Stub: LAnimStateMachine:addState ------------------------------------
--@api-stub: LAnimStateMachine:addState
-- Adds a state that plays a named animation clip.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimStateMachine_stub:addState("hero", clip, looping)
-- (replace lAnimStateMachine_stub with your real LAnimStateMachine instance above)

-- ---- Stub: LAnimStateMachine:addTransition -------------------------------
--@api-stub: LAnimStateMachine:addTransition
-- Adds a named-condition transition between two animation states.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimStateMachine_stub:addTransition(from_state, to_state, condition)
-- (replace lAnimStateMachine_stub with your real LAnimStateMachine instance above)

-- ---- Stub: LAnimStateMachine:setParam ------------------------------------
--@api-stub: LAnimStateMachine:setParam
-- Sets a boolean, integer, or numeric state machine parameter.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimStateMachine_stub:setParam("hero", 42)
-- (replace lAnimStateMachine_stub with your real LAnimStateMachine instance above)

-- ---- Stub: LAnimStateMachine:getQuad -------------------------------------
--@api-stub: LAnimStateMachine:getQuad
-- Returns the current frame rectangle from the state machine's owned animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimStateMachine_stub:getQuad()  -- -> LuaValue
-- (replace lAnimStateMachine_stub with your real LAnimStateMachine instance above)

-- -----------------------------------------------------------------------------
-- LAnimSyncGroup methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAnimSyncGroup:add --------------------------------------------
--@api-stub: LAnimSyncGroup:add
-- Adds an animation-like handle to the sync group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimSyncGroup_stub:add(handle)
-- (replace lAnimSyncGroup_stub with your real LAnimSyncGroup instance above)

-- ---- Stub: LAnimSyncGroup:remove -----------------------------------------
--@api-stub: LAnimSyncGroup:remove
-- Removes an animation-like handle from the sync group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimSyncGroup_stub:remove(handle)
-- (replace lAnimSyncGroup_stub with your real LAnimSyncGroup instance above)

-- ---- Stub: LAnimSyncGroup:clear ------------------------------------------
--@api-stub: LAnimSyncGroup:clear
-- Removes all members from the sync group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimSyncGroup_stub:clear()
-- (replace lAnimSyncGroup_stub with your real LAnimSyncGroup instance above)

-- ---- Stub: LAnimSyncGroup:memberCount ------------------------------------
--@api-stub: LAnimSyncGroup:memberCount
-- Returns the number of handles tracked by the sync group.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimSyncGroup_stub:memberCount()  -- -> integer
-- (replace lAnimSyncGroup_stub with your real LAnimSyncGroup instance above)

-- -----------------------------------------------------------------------------
-- LAnimation methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LAnimation:addFrame -------------------------------------------
--@api-stub: LAnimation:addFrame
-- Adds one frame rectangle to this animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:addFrame(0.0, 0.0, 64.0, 64.0)  -- -> integer
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:addFramesFromGrid ----------------------------------
--@api-stub: LAnimation:addFramesFromGrid
-- Adds frames by slicing a texture grid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:addFramesFromGrid(tw, th, fw, fh, start, 10)  -- -> integer
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:addFramesFromRects ---------------------------------
--@api-stub: LAnimation:addFramesFromRects
-- Adds frames from an array of rectangle tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:addFramesFromRects(rects)  -- -> integer
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:addClip --------------------------------------------
--@api-stub: LAnimation:addClip
-- Adds a named clip using existing frame indices.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:addClip()
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:addClipFromGrid ------------------------------------
--@api-stub: LAnimation:addClipFromGrid
-- Adds frames from a texture grid and creates a clip that references the new frames.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:addClipFromGrid()
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:play -----------------------------------------------
--@api-stub: LAnimation:play
-- Starts playback of a named clip. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:play("hero")  -- -> boolean
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:stop -----------------------------------------------
--@api-stub: LAnimation:stop
-- Stops playback and resets animation playback state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:stop()
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:pause ----------------------------------------------
--@api-stub: LAnimation:pause
-- Pauses animation playback without changing the current clip.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:pause()
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:resume ---------------------------------------------
--@api-stub: LAnimation:resume
-- Resumes playback of a paused animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:resume()
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:update ---------------------------------------------
--@api-stub: LAnimation:update
-- Advances animation playback and records any frame or clip events.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:update(0.016)
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:getQuad --------------------------------------------
--@api-stub: LAnimation:getQuad
-- Returns the current frame rectangle as a table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:getQuad()  -- -> LuaValue
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:pollEvents -----------------------------------------
--@api-stub: LAnimation:pollEvents
-- Drains animation events produced since the previous poll.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:pollEvents()  -- -> table
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:isPlaying ------------------------------------------
--@api-stub: LAnimation:isPlaying
-- Returns whether this animation is currently playing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:isPlaying()  -- -> boolean
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:isLooping ------------------------------------------
--@api-stub: LAnimation:isLooping
-- Returns whether the current clip loops.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:isLooping()  -- -> boolean
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:getSpeed -------------------------------------------
--@api-stub: LAnimation:getSpeed
-- Returns the animation playback speed multiplier.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:getSpeed()  -- -> number
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:setSpeed -------------------------------------------
--@api-stub: LAnimation:setSpeed
-- Sets the animation playback speed multiplier.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:setSpeed(120.0)
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:getFrameCount --------------------------------------
--@api-stub: LAnimation:getFrameCount
-- Returns the number of frame rectangles stored in this animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:getFrameCount()  -- -> integer
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:getClipCount ---------------------------------------
--@api-stub: LAnimation:getClipCount
-- Returns the number of named clips stored in this animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:getClipCount()  -- -> integer
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:getCurrentFrame ------------------------------------
--@api-stub: LAnimation:getCurrentFrame
-- Returns the current frame index. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:getCurrentFrame()  -- -> integer
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:getClip --------------------------------------------
--@api-stub: LAnimation:getClip
-- Returns the named clip definition from this animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:getClip(clip_name)  -- -> table
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:setFrame -------------------------------------------
--@api-stub: LAnimation:setFrame
-- Sets the current frame index directly.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:setFrame(1)
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:crossfade ------------------------------------------
--@api-stub: LAnimation:crossfade
-- Starts a crossfade from the current clip to another clip.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:crossfade(clip_name, duration)  -- -> boolean
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:getBlendState --------------------------------------
--@api-stub: LAnimation:getBlendState
-- Returns current crossfade rectangles and blend factor when a crossfade is active.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:getBlendState()  -- -> LuaValue
-- (replace lAnimation_stub with your real LAnimation instance above)

-- ---- Stub: LAnimation:drawToImage ----------------------------------------
--@api-stub: LAnimation:drawToImage
-- Rasterizes the current animation frame into an image userdata.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lAnimation_stub:drawToImage(64.0, 64.0)  -- -> LImageData
-- (replace lAnimation_stub with your real LAnimation instance above)

-- -----------------------------------------------------------------------------
-- LBlendLayerSet methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LBlendLayerSet:addLayer ---------------------------------------
--@api-stub: LBlendLayerSet:addLayer
-- Adds a weighted animation blend layer with an optional bone mask.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBlendLayerSet_stub:addLayer("hero", clip_name, weight, [bones])  -- -> boolean
-- (replace lBlendLayerSet_stub with your real LBlendLayerSet instance above)

-- ---- Stub: LBlendLayerSet:removeLayer ------------------------------------
--@api-stub: LBlendLayerSet:removeLayer
-- Removes a blend layer by name. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBlendLayerSet_stub:removeLayer("hero")  -- -> boolean
-- (replace lBlendLayerSet_stub with your real LBlendLayerSet instance above)

-- ---- Stub: LBlendLayerSet:setWeight --------------------------------------
--@api-stub: LBlendLayerSet:setWeight
-- Sets the blend weight for an existing layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBlendLayerSet_stub:setWeight("hero", weight)  -- -> boolean
-- (replace lBlendLayerSet_stub with your real LBlendLayerSet instance above)

-- ---- Stub: LBlendLayerSet:getWeight --------------------------------------
--@api-stub: LBlendLayerSet:getWeight
-- Returns the weight for a blend layer when it exists.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBlendLayerSet_stub:getWeight("hero")  -- -> LuaValue
-- (replace lBlendLayerSet_stub with your real LBlendLayerSet instance above)

-- ---- Stub: LBlendLayerSet:setMask ----------------------------------------
--@api-stub: LBlendLayerSet:setMask
-- Replaces a layer bone mask from a table of bone names.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBlendLayerSet_stub:setMask("hero", bones)  -- -> boolean
-- (replace lBlendLayerSet_stub with your real LBlendLayerSet instance above)

-- ---- Stub: LBlendLayerSet:listLayers -------------------------------------
--@api-stub: LBlendLayerSet:listLayers
-- Returns all blend layers with names, clip names, weights, and bone masks.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBlendLayerSet_stub:listLayers()  -- -> table
-- (replace lBlendLayerSet_stub with your real LBlendLayerSet instance above)

-- ---- Stub: LBlendLayerSet:len --------------------------------------------
--@api-stub: LBlendLayerSet:len
-- Returns the number of blend layers.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lBlendLayerSet_stub:len()  -- -> integer
-- (replace lBlendLayerSet_stub with your real LBlendLayerSet instance above)
