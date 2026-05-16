-- content/examples/animation.lua
-- lurek.animation API examples.
-- Run: cargo run -- content/examples/animation.lua

--@api-stub: lurek.animation.new
-- Creates an empty animation with no frames or clips
do
  local hero = lurek.animation.new()
  hero:addFrame(0, 0, 32, 32)
  hero:addFrame(32, 0, 32, 32)
  hero:addClip("idle", {0, 1}, 4, true)
  hero:play("idle")
end

--@api-stub: lurek.animation.fromAseprite
-- Loads an animation from an Aseprite JSON export string
do
  local json = '{"frames":[],"meta":{"size":{"w":32,"h":32},"frameTags":[]}}'
  local hero = lurek.animation.fromAseprite(json)
  hero:play("walk")
end

--@api-stub: lurek.animation.newStateMachine
-- Creates an animation state machine by consuming an animation handle
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 1, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
end

--@api-stub: lurek.animation.newCurve
-- Creates an empty animation curve
do
  local zoom = lurek.animation.newCurve()
  zoom:addKeyframe(0.0, 1.0)
  zoom:addKeyframe(1.5, 2.0)
  local current = zoom:eval(0.75)
  lurek.log.info("camera zoom at t=0.75 -> " .. current, "anim")
end

--@api-stub: lurek.animation.newSyncGroup
-- Creates an empty animation synchronization group
do
  local squad = lurek.animation.newSyncGroup()
  squad:add(1)
  squad:add(2)
  lurek.log.info("synced animations: " .. squad:memberCount(), "anim")
end

--@api-stub: lurek.animation.newBlendLayerSet
-- Creates an empty blend layer set for layered animation playback
do
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "run", 1.0)
  bls:addLayer("upper", "aim", 0.8, {"spine", "arm_r"})
end

-- Animation methods

--@api-stub: Animation:addFrame
-- Adds a frame to this animation.
do
  local anim = lurek.animation.new()
  local idx = anim:addFrame(0, 0, 48, 64)
  anim:addFrame(48, 0, 48, 64)
  lurek.log.debug("added frame index=" .. idx, "anim")
end

--@api-stub: Animation:addFramesFromRects
-- Adds a frames from rects to this animation.
do
  local anim = lurek.animation.new()
  local added = anim:addFramesFromRects({
    { x = 0, y = 0, w = 32, h = 32 },
    { x = 32, y = 0, w = 32, h = 32 },
  })
  lurek.log.debug("added rect frames=" .. tostring(added), "anim")
end

--@api-stub: Animation:play
-- Starts playback of on this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  if not anim:play("walk") then
    lurek.log.warn("clip 'walk' not registered", "anim")
  end
end

--@api-stub: Animation:stop
-- Stops the current operation or playback on this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  anim:stop()
end

--@api-stub: Animation:pause
-- Pauses the current operation or playback on this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  anim:pause()
end

--@api-stub: Animation:resume
-- Resumes a previously paused operation or playback on this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  anim:pause()
  anim:resume()
end

--@api-stub: Animation:update
-- Advances this animation by the given delta time.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  function lurek.process(dt) anim:update(dt) end
end

--@api-stub: Animation:getQuad
-- Returns the quad of this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:play("idle")
  local q = anim:getQuad()
  if q then lurek.log.debug("frame quad w=" .. q.w .. " h=" .. q.h, "anim") end
end

--@api-stub: Animation:pollEvents
-- Performs the poll events operation on this animation.
do
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

--@api-stub: Animation:isPlaying
-- Returns true if this animation playing.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("swing", {0}, 6, false)
  anim:play("swing")
  if anim:isPlaying() then lurek.log.debug("swing in progress, ignoring input", "combat") end
end

--@api-stub: Animation:isLooping
-- Returns true if this animation looping.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 2, true)
  anim:play("idle")
  if not anim:isLooping() then lurek.log.warn("idle clip should loop but does not", "anim") end
end

--@api-stub: Animation:getClip
-- Returns the clip of this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("run", {0}, 12, true)
  anim:play("run")
  local clip = anim:getClip()
  if clip then lurek.log.debug("now playing: " .. clip, "anim") end
end

--@api-stub: Animation:getSpeed
-- Returns the speed of this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("run", {0}, 12, true)
  local previous = anim:getSpeed()
  anim:setSpeed(previous * 0.5)
end

--@api-stub: Animation:setSpeed
-- Sets the speed of this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("run", {0}, 12, true)
  anim:play("run")
  anim:setSpeed(2.0)
end

--@api-stub: Animation:getFrameCount
-- Returns the number of frame items in this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  if anim:getFrameCount() ~= 2 then lurek.log.error("frame pool wrong size", "anim") end
end

--@api-stub: Animation:getClipCount
-- Returns the number of clip items in this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  lurek.log.info("clips registered: " .. anim:getClipCount(), "anim")
end

--@api-stub: Animation:getCurrentFrame
-- Returns the current frame of this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  if anim:getCurrentFrame() == 3 then lurek.audio.play(lurek.audio.newSource("tests/rust/fixtures/sine_mono_44100.wav")) end
end

--@api-stub: Animation:setFrame
-- Sets the frame of this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("walk", {0}, 8, true)
  anim:play("walk")
  anim:setFrame(0)
end

--@api-stub: Animation:getBlendState
-- Returns the blend state of this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:play("idle")
  local bs = anim:getBlendState()
  if bs then lurek.log.debug("crossfade blend=" .. bs.blend, "anim") end
end

--@api-stub: Animation:drawToImage
-- Draws or renders this animation to the current render target.
do
  pcall(function()
    local anim = lurek.animation.new()
    anim:addFrame(0, 0, 32, 32)
    anim:addClip("idle", {0}, 4, true)
    anim:play("idle")
    local thumb = anim:drawToImage(64, 64)
    lurek.image.savePNG(thumb, "save/anim_thumb.png")
  end)
end

-- AnimStateMachine methods

--@api-stub: AnimStateMachine:update
-- Advances this anim state machine by the given delta time.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32); anim:addClip("idle", {0}, 4, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  function lurek.process(dt) fsm:update(dt) end
end

--@api-stub: AnimStateMachine:getState
-- Returns the state of this anim state machine.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32); anim:addClip("idle", {0}, 4, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  if fsm:getState() ~= "idle" then lurek.log.warn("unexpected initial state", "anim") end
end

--@api-stub: AnimStateMachine:forceState
-- Performs the force state operation on this anim state machine.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32); anim:addClip("idle", {0}, 4, true); anim:addClip("dead", {0}, 1, false)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true); fsm:addState("dead", "dead", false)
  if not fsm:forceState("dead") then lurek.log.error("dead state missing", "anim") end
end

--@api-stub: AnimStateMachine:setParam
-- Sets the param of this anim state machine.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32); anim:addClip("idle", {0}, 4, true); anim:addClip("run", {0}, 8, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true); fsm:addState("run", "run", true)
  fsm:addTransition("idle", "run", "speed > 0.5")
  function lurek.process(dt) fsm:setParam("speed", 1.2); fsm:update(dt) end
end

--@api-stub: AnimStateMachine:getQuad
-- Returns the quad of this anim state machine.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32); anim:addClip("idle", {0}, 4, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  function lurek.draw()
    local q = fsm:getQuad()
    if q then lurek.log.debug("fsm quad w=" .. q.w, "anim") end
  end
end

-- BlendLayerSet methods

--@api-stub: BlendLayerSet:removeLayer
-- Removes a layer from this blend layer set.
do
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  bls:addLayer("upper", "aim", 0.5, {"spine"})
  bls:removeLayer("upper")
end

--@api-stub: BlendLayerSet:setWeight
-- Sets the weight of this blend layer set.
do
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  bls:addLayer("aim", "aim", 0.0, {"spine", "arm_r"})
  local aim_strength = 0.7
  bls:setWeight("aim", aim_strength)
end

--@api-stub: BlendLayerSet:getWeight
-- Returns the weight of this blend layer set.
do
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("aim", "aim", 0.5, {"spine"})
  local w = bls:getWeight("aim")
  if w and w > 0.5 then lurek.log.debug("aim layer dominant", "anim") end
end

--@api-stub: BlendLayerSet:setMask
-- Sets the mask of this blend layer set.
do
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("aim", "aim_pistol", 1.0, {"arm_r"})
  bls:setMask("aim", {"spine", "arm_l", "arm_r"})
end

--@api-stub: BlendLayerSet:listLayers
-- Performs the list layers operation on this blend layer set.
do
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  bls:addLayer("aim", "aim", 0.6, {"arm_r"})
  for _, layer in ipairs(bls:listLayers()) do
    lurek.log.debug(layer.name .. " weight=" .. layer.weight, "anim")
  end
end

--@api-stub: BlendLayerSet:len
-- Performs the len operation on this blend layer set.
do
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "idle", 1.0)
  if bls:len() == 0 then lurek.log.warn("blend set has no layers", "anim") end
end

-- AnimCurve methods

--@api-stub: AnimCurve:addKeyframe
-- Adds a keyframe to this anim curve.
do
  local fade = lurek.animation.newCurve()
  fade:addKeyframe(0.0, 0.0)
  fade:addKeyframe(0.5, 1.0)
  fade:addKeyframe(1.0, 0.0)
end

--@api-stub: AnimCurve:eval
-- Performs the eval operation on this anim curve.
do
  local fade = lurek.animation.newCurve()
  fade:addKeyframe(0.0, 0.0); fade:addKeyframe(1.0, 1.0)
  local alpha = fade:eval(0.25)
  function lurek.draw() lurek.render.setColor(1, 1, 1, alpha) end
end

--@api-stub: AnimCurve:setEasing
-- Sets the easing of this anim curve.
do
  local curve = lurek.animation.newCurve()
  curve:addKeyframe(0.0, 0.0); curve:addKeyframe(1.0, 1.0)
  curve:setEasing("ease_in_out")
end

--@api-stub: AnimCurve:keyframeCount
-- Performs the keyframe count operation on this anim curve.
do
  local curve = lurek.animation.newCurve()
  curve:addKeyframe(0.0, 0.0)
  if curve:keyframeCount() < 2 then lurek.log.warn("curve needs at least two keyframes", "anim") end
end

--@api-stub: AnimCurve:clear
-- Clears all items from this anim curve.
do
  local curve = lurek.animation.newCurve()
  curve:addKeyframe(0.0, 0.5); curve:addKeyframe(1.0, 1.0)
  curve:clear()
end

-- AnimSyncGroup methods

--@api-stub: AnimSyncGroup:add
-- Adds a  to this anim sync group.
do
  local squad = lurek.animation.newSyncGroup()
  squad:add(1)
  squad:add(2)
  squad:add(3)
end

--@api-stub: AnimSyncGroup:remove
-- Removes a  from this anim sync group.
do
  local squad = lurek.animation.newSyncGroup()
  squad:add(1); squad:add(2)
  squad:remove(1)
end

--@api-stub: AnimSyncGroup:clear
-- Clears all items from this anim sync group.
do
  local squad = lurek.animation.newSyncGroup()
  squad:add(1); squad:add(2); squad:add(3)
  squad:clear()
end

--@api-stub: AnimSyncGroup:memberCount
-- Performs the member count operation on this anim sync group.
do
  local squad = lurek.animation.newSyncGroup()
  squad:add(1); squad:add(2)
  if squad:memberCount() > 0 then lurek.log.info("squad alive: " .. squad:memberCount(), "anim") end
end

--@api-stub: AnimCurve:setCustomEasing
-- Sets the custom easing of this anim curve.
do
  if lurek.animation.newCurve then
    local c = lurek.animation.newCurve()
    c:setCustomEasing(function(t)
      -- Smoothstep
      return t * t * (3 - 2 * t)
    end)
    lurek.log.debug("custom easing attached", "anim")
  end
end

--@api-stub: Animation:addClip
-- Adds a clip to this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addFrame(32, 0, 32, 32)
  anim:addClip("walk", {0, 1}, 8, true)
  anim:play("walk")
  lurek.log.info("clip count: " .. anim:getClipCount(), "anim")
end

--@api-stub: Animation:addClipFromGrid
-- Adds a clip from grid to this animation.
do
  local anim = lurek.animation.new()
  anim:addFramesFromGrid(128, 128, 32, 32, 0, 16)
  anim:addClipFromGrid("run", 128, 128, 32, 32, 0, 4, 8, true)
  anim:play("run")
  lurek.log.info("clip from grid added", "anim")
end

--@api-stub: Animation:addFramesFromGrid
-- Adds a frames from grid to this animation.
do
  local anim = lurek.animation.new()
  local n = anim:addFramesFromGrid(64, 64, 32, 32, 0, 8)
  lurek.log.info("frames added: " .. n, "anim")
end

--@api-stub: BlendLayerSet:addLayer
-- Adds a layer to this blend layer set.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 64, 64)
  anim:addClip("run", {0}, 8, true)
  local bls = lurek.animation.newBlendLayerSet()
  bls:addLayer("base", "run", 1.0)
  bls:addLayer("aim", "aim", 0.9, {"spine", "arm_r"})
  lurek.log.info("layers: " .. bls:len(), "anim")
end

--@api-stub: AnimStateMachine:addState
-- Adds a state to this anim state machine.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 1, true)
  anim:addClip("run", {0}, 8, true)
  local fsm = lurek.animation.newStateMachine(anim, "idle")
  fsm:addState("idle", "idle", true)
  fsm:addState("run", "run", true)
  lurek.log.info("state machine ready", "anim")
end

--@api-stub: AnimStateMachine:addTransition
-- Adds a transition to this anim state machine.
do
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

--@api-stub: Animation:crossfade
-- Performs the crossfade operation on this animation.
do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 32, 32)
  anim:addClip("idle", {0}, 4, true)
  anim:addClip("run", {0}, 8, true)
  anim:play("idle")
  anim:crossfade("run", 0.2)
  lurek.log.info("crossfade started", "anim")
end

-- -----------------------------------------------------------------------------
-- BlendLayerSet methods
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LAnimCurve methods
-- -----------------------------------------------------------------------------

--@api-stub: LAnimCurve:type
-- Returns the Lua-visible type name for this animation curve handle
do
  local anim_curve_obj = lurek.animation.newCurve()
  local t = anim_curve_obj:type()
  lurek.log.info("LAnimCurve:type = " .. t, "animation")
end
--@api-stub: LAnimCurve:typeOf
-- Returns whether this animation curve handle matches a supported type name
do
  local anim_curve_obj = lurek.animation.newCurve()
  lurek.log.info("is LAnimCurve: " .. tostring(anim_curve_obj:typeOf("LAnimCurve")), "animation")
  lurek.log.info("is wrong: " .. tostring(anim_curve_obj:typeOf("Unknown")), "animation")
end
--@api-stub: LAnimStateMachine:type
-- Returns the Lua-visible type name for this animation state machine handle
do
  local anim_state_machine_obj = lurek.animation.newStateMachine(lurek.animation.new(), "idle")
  local t = anim_state_machine_obj:type()
  lurek.log.info("LAnimStateMachine:type = " .. t, "animation")
end
--@api-stub: LAnimStateMachine:typeOf
-- Returns whether this animation state machine handle matches a supported type name
do
  local anim_state_machine_obj = lurek.animation.newStateMachine(lurek.animation.new(), "idle")
  lurek.log.info("is LAnimStateMachine: " .. tostring(anim_state_machine_obj:typeOf("LAnimStateMachine")), "animation")
  lurek.log.info("is wrong: " .. tostring(anim_state_machine_obj:typeOf("Unknown")), "animation")
end
--@api-stub: LAnimSyncGroup:type
-- Returns the Lua-visible type name for this animation sync group handle
do
  local anim_sync_group_obj = lurek.animation.newSyncGroup()
  local t = anim_sync_group_obj:type()
  lurek.log.info("LAnimSyncGroup:type = " .. t, "animation")
end
--@api-stub: LAnimSyncGroup:typeOf
-- Returns whether this animation sync group handle matches a supported type name
do
  local anim_sync_group_obj = lurek.animation.newSyncGroup()
  lurek.log.info("is LAnimSyncGroup: " .. tostring(anim_sync_group_obj:typeOf("LAnimSyncGroup")), "animation")
  lurek.log.info("is wrong: " .. tostring(anim_sync_group_obj:typeOf("Unknown")), "animation")
end
--@api-stub: LAnimation:type
-- Returns the Lua-visible type name for this animation handle
do
  local animation_obj = lurek.animation.new()
  local t = animation_obj:type()
  lurek.log.info("LAnimation:type = " .. t, "animation")
end
--@api-stub: LAnimation:typeOf
-- Returns whether this animation handle matches a supported type name
do
  local animation_obj = lurek.animation.new()
  lurek.log.info("is LAnimation: " .. tostring(animation_obj:typeOf("LAnimation")), "animation")
  lurek.log.info("is wrong: " .. tostring(animation_obj:typeOf("Unknown")), "animation")
end
--@api-stub: LBlendLayerSet:type
-- Returns the Lua-visible type name for this blend layer set handle
do
  local blend_layer_set_obj = lurek.animation.newBlendLayerSet()
  local t = blend_layer_set_obj:type()
  lurek.log.info("LBlendLayerSet:type = " .. t, "animation")
end
--@api-stub: LBlendLayerSet:typeOf
-- Returns whether this blend layer set handle matches a supported type name
do
  local blend_layer_set_obj = lurek.animation.newBlendLayerSet()
  lurek.log.info("is LBlendLayerSet: " .. tostring(blend_layer_set_obj:typeOf("LBlendLayerSet")), "animation")
  lurek.log.info("is wrong: " .. tostring(blend_layer_set_obj:typeOf("Unknown")), "animation")
end

do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 16, 16)
  anim:addFrame(16, 0, 16, 16)
  anim:addClip("walk", {0, 1}, 8, true, "pingpong")
  lurek.log.info("walk mode: " .. tostring(anim:getClipMode("walk")), "anim")
end

do
  local anim = lurek.animation.new()
  anim:addFrame(0, 0, 16, 16)
  anim:addClip("idle", {0}, 4, true)
  anim:setClipMode("idle", "reverse")
  lurek.log.info("idle mode: " .. tostring(anim:getClipMode("idle")), "anim")
end

do
  local anim = lurek.animation.new()
  anim:addFramesFromGrid(64, 32, 16, 16, 0, 8)
  local img = anim:drawPreviewGrid(4, 20)
  lurek.log.info("preview image userdata: " .. tostring(img), "anim")
end

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


--@api-stub: LAnimation:drawPreviewGrid
-- Draws a debug grid of all frames in this animation atlas at the given position and scale.
do
  local anim = lurek.animation.new("assets/player.png", 64, 64)
  anim:drawPreviewGrid(0, 0, 2)
end

--@api-stub: LAnimation:getClipMode
-- Returns the current clip mode string, either "loop", "once", or "pingpong".
do
  local anim = lurek.animation.new("assets/player.png", 64, 64)
  local mode = anim:getClipMode()
  lurek.log.debug("clip mode=" .. mode, "anim")
end

--@api-stub: LAnimation:setClipMode
-- Sets the clip playback mode to "loop", "once", or "pingpong" for this animation.
do
  local anim = lurek.animation.new("assets/player.png", 64, 64)
  anim:setClipMode("pingpong")
end
