-- content/examples/animation.lua
-- Hand-written coverage of the lurek.animation API (45 items).
--
-- Animations are controllers built from a frame pool plus named clips.
-- Build them with `lurek.animation.new()` then drive them from
-- `lurek.process(dt)` (advance) and `lurek.render()` (consume the quad
-- via `:getQuad()` and pass it to `lurek.render.drawQuad`). State
-- machines and blend-layer sets layer richer behaviour on top.
--
-- Run: cargo run -- content/examples/animation.lua

-- â”€â”€ lurek.animation.* functions â”€â”€

--@api-stub: lurek.animation.new
-- Creates a new, empty Animation controller.
-- Call once at startup; populate it with `:addFrame` and `:addClip` before `:play`.
do -- lurek.animation.new
  local hero = lurek.animation.new()
  hero:addFrame(0, 0, 32, 32)
  hero:addFrame(32, 0, 32, 32)
  hero:addClip("idle", {0, 1}, 4, true)
  hero:play("idle")
end

--@api-stub: lurek.animation.fromAseprite
-- Parses an Aseprite JSON export string and builds an Animation with clips and frames.
-- Use when you author sprites in Aseprite and export the JSON sidecar alongside the sheet PNG.
do -- lurek.animation.fromAseprite
  local json = '{"frames":[],"meta":{"size":{"w":32,"h":32},"frameTags":[]}}'
  local hero = lurek.animation.fromAseprite(json)
  hero:play("walk")
end

--@api-stub: lurek.animation.newStateMachine
-- Creates an animation FSM from an Animation controller and an initial state name.
-- Build the Animation first; the FSM consumes it, so do not reuse the original handle afterwards.
do -- lurek.animation.newStateMachine
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 1, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
end

--@api-stub: lurek.animation.newCurve
-- Creates a new empty AnimCurve with linear interpolation.
-- Use for tween-style value tracks (camera zoom, light intensity) that are not full sprite clips.
do -- lurek.animation.newCurve
  local zoom = lurek.animation.newCurve()
  zoom:addKeyframe(0.0, 1.0)
  zoom:addKeyframe(1.5, 2.0)
  local current = zoom:eval(0.75)
  lurek.log.info("camera zoom at t=0.75 -> " .. current, "anim")
end

--@api-stub: lurek.animation.newSyncGroup
-- Creates a new empty AnimSyncGroup.
-- Use to keep a squad of enemies marching in lockstep so their footfalls line up visually.
do -- lurek.animation.newSyncGroup
  local squad = lurek.animation.newSyncGroup()
  squad:add(1)
  squad:add(2)
  lurek.log.info("synced animations: " .. squad:memberCount(), "anim")
end

--@api-stub: lurek.animation.newBlendLayerSet
-- Creates a new empty BlendLayerSet for compositing multiple animation clips.
-- Use for upper-body / lower-body splits: the legs run while the torso aims a weapon.
do -- lurek.animation.newBlendLayerSet
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "run", 1.0)
  bls:addLayer("upper", "aim", 0.8, {"spine", "arm_r"})
end

-- â”€â”€ Animation methods â”€â”€

--@api-stub: LAnimation:addFrame
-- Adds a single frame to the frame pool by source rectangle.
-- Use when frames are irregular sizes; for uniform grids prefer `:addFramesFromGrid`.
do -- Animation:addFrame
  local anim = lurek.animation.new()
  local idx = anim:addFrame(0, 0, 48, 64)
  anim:addFrame(48, 0, 48, 64)
  lurek.log.debug("added frame index=" .. idx, "anim")
end

--@api-stub: LAnimation:addFramesFromRects
-- Adds many frames from an array of rectangle tables `{x,y,w,h}`.
-- Use this when you already have frame rects from an atlas parser and want a single bulk append.
do -- Animation:addFramesFromRects
  local anim = lurek.animation.new()
  local added = anim:addFramesFromRects({
    { x = 0, y = 0, w = 32, h = 32 },
    { x = 32, y = 0, w = 32, h = 32 },
  })
  lurek.log.debug("added rect frames=" .. tostring(added), "anim")
end

--@api-stub: LAnimation:play
-- Starts playback of the named clip.
-- Returns true on success; check the result before assuming the clip name was registered.
do -- Animation:play
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  if not anim:play("walk") then
    lurek.log.warn("clip 'walk' not registered", "anim")
  end
end

--@api-stub: LAnimation:stop
-- Stops playback and resets to frame 0.
-- Call when leaving a state (e.g. enemy died) so the next `:play` starts cleanly.
do -- Animation:stop
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  anim:stop()
end

--@api-stub: LAnimation:pause
-- Pauses playback at the current frame.
-- Use when the game opens a menu or a cutscene; resume later with `:resume`.
do -- Animation:pause
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  anim:pause()
end

--@api-stub: LAnimation:resume
-- Resumes playback from the current frame.
-- Pair with `:pause` around menu/dialog screens so animations pick up exactly where they stopped.
do -- Animation:resume
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  anim:pause()
  anim:resume()
end

--@api-stub: LAnimation:update
-- Advances the animation by dt seconds.
-- Call once per frame from `lurek.process(dt)`; never from `lurek.render` or you skew with the framerate.
do -- Animation:update
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  function lurek.process(dt) anim:update(dt) end
end

--@api-stub: LAnimation:getQuad
-- Returns the source quad (x, y, w, h) for the current frame, or nil.
-- Use the returned table directly as the source rect for `lurek.render.drawQuad` of the sprite-sheet.
do -- Animation:getQuad
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:play("idle")
  local q = anim:getQuad()
  if q then lurek.log.debug("frame quad w=" .. q.w .. " h=" .. q.h, "anim") end
end

--@api-stub: LAnimation:pollEvents
-- Drains and returns all pending animation events as a table.
-- Drain every frame; events include `frame_changed` and `clip_finished` and are dropped if not read.
do -- Animation:pollEvents
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("attack", {0}, 8, false)
  anim:play("attack")
  function lurek.process(dt)
    anim:update(dt)
    for _, ev in ipairs(anim:pollEvents()) do
      if ev.type == "clip_finished" then lurek.log.info("attack done", "anim") end
    end
  end
end

--@api-stub: LAnimation:isPlaying
-- Returns true if a clip is currently playing.
-- Use to gate input: don't accept a new attack command while the previous swing is still playing.
do -- Animation:isPlaying
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("swing", {0}, 6, false)
  anim:play("swing")
  if anim:isPlaying() then lurek.log.debug("swing in progress, ignoring input", "combat") end
end

--@api-stub: LAnimation:isLooping
-- Returns true if the current clip is set to loop.
-- Branch on this when deciding whether the AI should switch states automatically when the clip ends.
do -- Animation:isLooping
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 2, true)
  anim:play("idle")
  if not anim:isLooping() then lurek.log.warn("idle clip should loop but does not", "anim") end
end

--@api-stub: LAnimation:getClip
-- Returns the name of the currently playing clip, or nil.
-- Useful for debug overlays and for asserting state-machine transitions actually fired.
do -- Animation:getClip
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("run", {0}, 12, true)
  anim:play("run")
  local clip = anim:getClip()
  if clip then lurek.log.debug("now playing: " .. clip, "anim") end
end

--@api-stub: LAnimation:getSpeed
-- Returns the playback speed multiplier.
-- Read before changing it so you can restore the original after a brief slow-mo effect.
do -- Animation:getSpeed
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("run", {0}, 12, true)
  local previous = anim:getSpeed()
  anim:setSpeed(previous * 0.5)
end

--@api-stub: LAnimation:setSpeed
-- Sets the playback speed multiplier.
-- 1.0 is normal, 2.0 doubles fps, 0.0 freezes; negative values are clamped to 0.
do -- Animation:setSpeed
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("run", {0}, 12, true)
  anim:play("run")
  anim:setSpeed(2.0)
end

--@api-stub: LAnimation:getFrameCount
-- Returns the total number of frames in the frame pool.
-- Use as a sanity check after `:addFramesFromGrid` to confirm the sheet was sliced correctly.
do -- Animation:getFrameCount
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  if anim:getFrameCount() ~= 2 then lurek.log.error("frame pool wrong size", "anim") end
end

--@api-stub: LAnimation:getClipCount
-- Returns the number of registered clips.
-- Helpful in tooling to verify an Aseprite import populated all expected clips.
do -- Animation:getClipCount
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  lurek.log.info("clips registered: " .. anim:getClipCount(), "anim")
end

--@api-stub: LAnimation:getCurrentFrame
-- Returns the current position within the active clip (0-based).
-- Use to drive frame-locked logic such as triggering a footstep sound on frame 3 of "walk".
do -- Animation:getCurrentFrame
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  if anim:getCurrentFrame() == 3 then lurek.audio.play(lurek.audio.newSource("tests/rust/fixtures/sine_mono_44100.wav")) end
end

--@api-stub: LAnimation:setFrame
-- Sets the playback position within the current clip.
-- Use to scrub an editor timeline or to align two animations at a specific frame.
do -- Animation:setFrame
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  anim:setFrame(0)
end

--@api-stub: LAnimation:getBlendState
-- Returns the two quads and blend factor during a crossfade, or nil when not blending.
-- During a crossfade, draw both quads with alpha = blend / (1 - blend) for a soft transition.
do -- Animation:getBlendState
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:play("idle")
  local bs = anim:getBlendState()
  if bs then lurek.log.debug("crossfade blend=" .. bs.blend, "anim") end
end

--@api-stub: LAnimation:drawToImage
-- Renders the current animation frame into a new ImageData (white bg, blue frame rect).
-- Use to bake a debug thumbnail of the current frame for tooling or screenshot tests.
do -- Animation:drawToImage
  pcall(function()
    local anim = lurek.animation.new()
    anim:addFrame(0, 0, 32, 32)
    anim:addClip("idle", {0}, 4, true)
    anim:play("idle")
    local thumb = anim:drawToImage(64, 64)
    lurek.image.savePNG(thumb, "save/anim_thumb.png")
  end)
end

-- â”€â”€ AnimStateMachine methods â”€â”€

--@api-stub: LAnimStateMachine:update
-- Advances the FSM by `dt` seconds, evaluating transitions.
-- Call from `lurek.process(dt)`; transitions fire only here, never inside `setParam`.
do -- AnimStateMachine:update
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32); anim:addClip("idle", {0}, 4, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  function lurek.process(dt) fsm:update(dt) end
end

--@api-stub: LAnimStateMachine:getState
-- Returns the name of the currently active state.
-- Use for HUD overlays and for asserting that gameplay parameter changes flipped the state as expected.
do -- AnimStateMachine:getState
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32); anim:addClip("idle", {0}, 4, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  if fsm:getState() ~= "idle" then lurek.log.warn("unexpected initial state", "anim") end
end

--@api-stub: LAnimStateMachine:forceState
-- Immediately jumps to the named state, bypassing transition conditions.
-- Use sparingly â€” for spawn, respawn, and cutscene exits. Returns true if the target state existed.
do -- AnimStateMachine:forceState
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32); anim:addClip("idle", {0}, 4, true); anim:addClip("dead", {0}, 1, false)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true); fsm:addState("dead", "dead", false)
  if not fsm:forceState("dead") then lurek.log.error("dead state missing", "anim") end
end

--@api-stub: LAnimStateMachine:setParam
-- Sets an FSM parameter value (number, boolean, or integer supported).
-- Push gameplay variables (speed, hp, jumping) here every frame so registered transitions can react.
do -- AnimStateMachine:setParam
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32); anim:addClip("idle", {0}, 4, true); anim:addClip("run", {0}, 8, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true); fsm:addState("run", "run", true)
  fsm:addTransition("idle", "run", "speed > 0.5")
  function lurek.process(dt) fsm:setParam("speed", 1.2); fsm:update(dt) end
end

--@api-stub: LAnimStateMachine:getQuad
-- Returns the source quad for the current animation frame, or nil.
-- Drive sprite rendering off this rather than the underlying Animation; the FSM owns the active clip.
do -- AnimStateMachine:getQuad
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32); anim:addClip("idle", {0}, 4, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  function lurek.draw() local q = fsm:getQuad(); if q then lurek.log.debug("fsm quad w=" .. q.w, "anim") end end
end

-- â”€â”€ BlendLayerSet methods â”€â”€

--@api-stub: LBlendLayerSet:removeLayer
-- Removes a blend layer by name.
-- Call when a body part is destroyed (e.g. arm severed) so its clip stops contributing.
do -- BlendLayerSet:removeLayer
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  bls:addLayer("upper", "aim", 0.5, {"spine"})
  bls:removeLayer("upper")
end

--@api-stub: LBlendLayerSet:setWeight
-- Sets the blend weight of a named layer (clamped to [0, 1]).
-- Drive this from gameplay (e.g. crouch amount, aim strength) for smooth blend transitions.
do -- BlendLayerSet:setWeight
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  bls:addLayer("aim", "aim", 0.0, {"spine", "arm_r"})
  local aim_strength = 0.7
  bls:setWeight("aim", aim_strength)
end

--@api-stub: LBlendLayerSet:getWeight
-- Returns the blend weight of a named layer, or nil if not found.
-- Use to read back the current blend after `setWeight` has clamped your input.
do -- BlendLayerSet:getWeight
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("aim", "aim", 0.5, {"spine"})
  local w = bls:getWeight("aim")
  if w and w > 0.5 then lurek.log.debug("aim layer dominant", "anim") end
end

--@api-stub: LBlendLayerSet:setMask
-- Replaces the bone mask of a layer.
-- Call when the active weapon changes â€” pistol uses {arm_r}, rifle uses {spine, arm_l, arm_r}.
do -- BlendLayerSet:setMask
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("aim", "aim_pistol", 1.0, {"arm_r"})
  bls:setMask("aim", {"spine", "arm_l", "arm_r"})
end

--@api-stub: LBlendLayerSet:listLayers
-- Returns an ordered array of layer info tables: {name, clip_name, weight, bones}.
-- Iterate this from your skeletal animator to drive each layer's contribution to the final pose.
do -- BlendLayerSet:listLayers
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  bls:addLayer("aim", "aim", 0.6, {"arm_r"})
  for _, layer in ipairs(bls:listLayers()) do
    lurek.log.debug(layer.name .. " weight=" .. layer.weight, "anim")
  end
end

--@api-stub: LBlendLayerSet:len
-- Returns the number of blend layers.
-- Cheap probe for editor/debug HUDs without iterating the full layer list.
do -- BlendLayerSet:len
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  if bls:len() == 0 then lurek.log.warn("blend set has no layers", "anim") end
end

-- â”€â”€ AnimCurve methods â”€â”€

--@api-stub: LAnimCurve:addKeyframe
-- Inserts a keyframe at the given time.
-- Times do not need to be sorted; the curve sorts and de-duplicates them on insert.
do -- AnimCurve:addKeyframe
  local fade = lurek.animation.newCurve()
  fade:addKeyframe(0.0, 0.0)
  fade:addKeyframe(0.5, 1.0)
  fade:addKeyframe(1.0, 0.0)
end

--@api-stub: LAnimCurve:eval
-- Returns the interpolated value at the given time using the curve's easing.
-- Out-of-range `t` is clamped to the first/last keyframe value; an empty curve returns 0.
do -- AnimCurve:eval
  local fade = lurek.animation.newCurve()
  fade:addKeyframe(0.0, 0.0); fade:addKeyframe(1.0, 1.0)
  local alpha = fade:eval(0.25)
  function lurek.draw() lurek.render.setColor(1, 1, 1, alpha) end
end

--@api-stub: LAnimCurve:setEasing
-- Sets the easing kind applied between all keyframe segments.
-- Accepts "step", "linear", "ease_in", "ease_out", "ease_in_out"; unknown names raise an error.
do -- AnimCurve:setEasing
  local curve = lurek.animation.newCurve()
  curve:addKeyframe(0.0, 0.0); curve:addKeyframe(1.0, 1.0)
  curve:setEasing("ease_in_out")
end

--@api-stub: LAnimCurve:keyframeCount
-- Returns the number of keyframes currently stored.
-- Useful as a guard before `:eval` to avoid relying on the empty-curve 0.0 fallback.
do -- AnimCurve:keyframeCount
  local curve = lurek.animation.newCurve()
  curve:addKeyframe(0.0, 0.0)
  if curve:keyframeCount() < 2 then lurek.log.warn("curve needs at least two keyframes", "anim") end
end

--@api-stub: LAnimCurve:clear
-- Removes all keyframes from this animation curve, resetting it to empty.
-- Call when a new sequence loads so the curve can be rebuilt without allocating a new instance.
do -- AnimCurve:clear
  local curve = lurek.animation.newCurve()
  curve:addKeyframe(0.0, 0.5); curve:addKeyframe(1.0, 1.0)
  curve:clear()
end

-- â”€â”€ AnimSyncGroup methods â”€â”€

--@api-stub: LAnimSyncGroup:add
-- Adds an animation handle to the group.
-- Handles are integers returned by `lurek.animation.new()`; duplicates are silently ignored.
do -- AnimSyncGroup:add
  local squad = lurek.animation.newSyncGroup()
  squad:add(1)
  squad:add(2)
  squad:add(3)
end

--@api-stub: LAnimSyncGroup:remove
-- Removes an animation handle from the group.
-- Call when an entity is despawned so the group does not try to advance a stale handle.
do -- AnimSyncGroup:remove
  local squad = lurek.animation.newSyncGroup()
  squad:add(1); squad:add(2)
  squad:remove(1)
end

--@api-stub: LAnimSyncGroup:clear
-- Removes all animation handles from the group.
-- Call on scene change so the next level starts with an empty sync group.
do -- AnimSyncGroup:clear
  local squad = lurek.animation.newSyncGroup()
  squad:add(1); squad:add(2); squad:add(3)
  squad:clear()
end

--@api-stub: LAnimSyncGroup:memberCount
-- Returns the number of animations currently in the group.
-- Use for HUD debug ("X enemies marching") and to skip processing when the group is empty.
do -- AnimSyncGroup:memberCount
  local squad = lurek.animation.newSyncGroup()
  squad:add(1); squad:add(2)
  if squad:memberCount() > 0 then lurek.log.info("squad alive: " .. squad:memberCount(), "anim") end
end

--@api-stub: LAnimCurve:setCustomEasing
-- Attach a Lua function as the easing for this curve. The function receives a
-- normalised t in [0,1] and must return the eased value (also in [0,1]).
do -- AnimCurve:setCustomEasing
  if lurek.animation.newCurve then
    local c = lurek.animation.newCurve()
    c:setCustomEasing(function(t)
      -- Smoothstep
      return t * t * (3 - 2 * t)
    end)
    lurek.log.debug("custom easing attached", "anim")
  end
end

--@api-stub: LAnimation:addClip
-- Adds a named clip defined by a sequence of frame indices, FPS, and looping flag.
-- Clips reference frames already in the pool; multiple clips can share frames.
do -- Animation:addClip
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("walk", {0, 1}, 8, true)
  anim:play("walk")
  lurek.log.info("clip count: " .. anim:getClipCount(), "anim")
end

--@api-stub: LAnimation:addClipFromGrid
-- Adds a named clip by specifying the row (or range) in a sprite-sheet grid.
-- Calculates frame indices automatically from the grid layout registered via addFramesFromGrid.
do -- Animation:addClipFromGrid
  local anim = lurek.animation.new()
  anim:addFramesFromGrid(128, 128, 32, 32, 0, 16)
  anim:addClipFromGrid("run", 128, 128, 32, 32, 0, 4, 8, true)
  anim:play("run")
  lurek.log.info("clip from grid added", "anim")
end

--@api-stub: LAnimation:addFramesFromGrid
-- Populates the frame pool from a uniform grid, adding count frames starting at offset.
-- Use instead of addFrame when the sprite sheet has regular tile-size cells.
do -- Animation:addFramesFromGrid
  local anim = lurek.animation.new()
  local n = anim:addFramesFromGrid(64, 64, 32, 32, 0, 8)
  lurek.log.info("frames added: " .. n, "anim")
end

--@api-stub: LBlendLayerSet:addLayer
-- Adds a named blend layer with a clip name, initial weight, and optional bone mask.
-- Layers above index 0 blend onto the base; use masks to restrict to upper-body bones.
do -- BlendLayerSet:addLayer
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 64, 64)
  anim:addClip("run", {0}, 8, true)
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "run", 1.0)
  bls:addLayer("aim", "aim", 0.9, {"spine", "arm_r"})
  lurek.log.info("layers: " .. bls:len(), "anim")
end

--@api-stub: LAnimStateMachine:addState
-- Adds a named state to the FSM with an associated clip name and looping flag.
-- States drive Animation playback; transitions switch between them automatically.
do -- AnimStateMachine:addState
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 1, true)
  anim:addClip("run", {0}, 8, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  fsm:addState("run", "run", true)
  lurek.log.info("state machine ready", "anim")
end

--@api-stub: LAnimStateMachine:addTransition
-- Adds a parameter-driven transition from one FSM state to another.
-- The transition fires when setParam changes the named parameter to match the trigger value.
do -- AnimStateMachine:addTransition
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 1, true)
  anim:addClip("run", {0}, 8, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  fsm:addState("run", "run", true)
  fsm:addTransition("idle", "run", "speed > 0")
  lurek.log.info("transition added", "anim")
end

--@api-stub: LAnimation:crossfade
-- Blends from the current clip to a new clip over a given duration in seconds.
-- Smoother than an instant play() switch; the blend weight transitions linearly.
do -- Animation:crossfade
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:addClip("run", {0}, 8, true)
  anim:play("idle")
  anim:crossfade("run", 0.2)
  lurek.log.info("crossfade started", "anim")
end

-- =============================================================================
-- COVERAGE: 10 uncovered lurek.animation API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- BlendLayerSet methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- COVERAGE: 10 uncovered lurek.animation API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LAnimCurve methods
-- -----------------------------------------------------------------------------

-- ---- Example: LAnimCurve:type -----------------------------------------------
--@api-stub: LAnimCurve:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LAnimCurve:type
  local anim_curve_obj = lurek.animation.newCurve()
  local t = anim_curve_obj:type()
  lurek.log.info("LAnimCurve:type = " .. t, "animation")
end
--@api-stub: LAnimCurve:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LAnimCurve:typeOf
  local anim_curve_obj = lurek.animation.newCurve()
  lurek.log.info("is LAnimCurve: " .. tostring(anim_curve_obj:typeOf("LAnimCurve")), "animation")
  lurek.log.info("is wrong: " .. tostring(anim_curve_obj:typeOf("Unknown")), "animation")
end
--@api-stub: LAnimStateMachine:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LAnimStateMachine:type
  local anim_state_machine_obj = lurek.animation.newStateMachine(lurek.animation.new(), "idle")
  local t = anim_state_machine_obj:type()
  lurek.log.info("LAnimStateMachine:type = " .. t, "animation")
end
--@api-stub: LAnimStateMachine:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LAnimStateMachine:typeOf
  local anim_state_machine_obj = lurek.animation.newStateMachine(lurek.animation.new(), "idle")
  lurek.log.info("is LAnimStateMachine: " .. tostring(anim_state_machine_obj:typeOf("LAnimStateMachine")), "animation")
  lurek.log.info("is wrong: " .. tostring(anim_state_machine_obj:typeOf("Unknown")), "animation")
end
--@api-stub: LAnimSyncGroup:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LAnimSyncGroup:type
  local anim_sync_group_obj = lurek.animation.newSyncGroup()
  local t = anim_sync_group_obj:type()
  lurek.log.info("LAnimSyncGroup:type = " .. t, "animation")
end
--@api-stub: LAnimSyncGroup:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LAnimSyncGroup:typeOf
  local anim_sync_group_obj = lurek.animation.newSyncGroup()
  lurek.log.info("is LAnimSyncGroup: " .. tostring(anim_sync_group_obj:typeOf("LAnimSyncGroup")), "animation")
  lurek.log.info("is wrong: " .. tostring(anim_sync_group_obj:typeOf("Unknown")), "animation")
end
--@api-stub: LAnimation:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LAnimation:type
  local animation_obj = lurek.animation.new()
  local t = animation_obj:type()
  lurek.log.info("LAnimation:type = " .. t, "animation")
end
--@api-stub: LAnimation:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LAnimation:typeOf
  local animation_obj = lurek.animation.new()
  lurek.log.info("is LAnimation: " .. tostring(animation_obj:typeOf("LAnimation")), "animation")
  lurek.log.info("is wrong: " .. tostring(animation_obj:typeOf("Unknown")), "animation")
end
--@api-stub: LBlendLayerSet:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do -- LBlendLayerSet:type
  local blend_layer_set_obj = lurek.animation.newBlendLayerSet()
  local t = blend_layer_set_obj:type()
  lurek.log.info("LBlendLayerSet:type = " .. t, "animation")
end
--@api-stub: LBlendLayerSet:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do -- LBlendLayerSet:typeOf
  local blend_layer_set_obj = lurek.animation.newBlendLayerSet()
  lurek.log.info("is LBlendLayerSet: " .. tostring(blend_layer_set_obj:typeOf("LBlendLayerSet")), "animation")
  lurek.log.info("is wrong: " .. tostring(blend_layer_set_obj:typeOf("Unknown")), "animation")
end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

--@api-stub: LAnimation:getClipMode
-- Returns current playback mode for a clip.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 16, 16)
  anim:addFrame(16, 0, 16, 16)
  anim:addClip("walk", {0, 1}, 8, true, "pingpong")
  lurek.log.info("walk mode: " .. tostring(anim:getClipMode("walk")), "anim")
end

--@api-stub: LAnimation:setClipMode
-- Updates playback mode for a clip after creation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 16, 16)
  anim:addClip("idle", {0}, 4, true)
  anim:setClipMode("idle", "reverse")
  lurek.log.info("idle mode: " .. tostring(anim:getClipMode("idle")), "anim")
end

--@api-stub: LAnimation:drawPreviewGrid
-- Renders all frame rectangles into a debug preview grid image.
do
  local anim = lurek.animation.new()
  anim:addFramesFromGrid(64, 32, 16, 16, 0, 8)
  local img = anim:drawPreviewGrid(4, 20)
  lurek.log.info("preview image userdata: " .. tostring(img), "anim")
end

--@api-stub: lurek.animation.buildCharacter
-- Builds an Animation + optional AnimStateMachine from one setup table.
do
  local bundle = lurek.animation.buildCharacter({
    texW = 64,
    texH = 32,
    frameW = 16,
    frameH = 16,
    clips = {
      { name = "idle", start = 0, count = 2, fps = 4, looping = true, mode = "forward" },
      { name = "run", start = 2, count = 2, fps = 10, looping = true, mode = "pingpong" },
    },
    states = {
      { name = "idle", clip = "idle", looping = true },
      { name = "run", clip = "run", looping = true },
    },
    transitions = {
      { from = "idle", to = "run", condition = "speed > 0.5" },
    },
    initialState = "idle",
  })
  if bundle and bundle.animation then
    lurek.log.info("character bundle clips: " .. tostring(bundle.animation:getClipCount()), "anim")
  end
end

