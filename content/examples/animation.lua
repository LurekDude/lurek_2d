-- content/examples/animation.lua
-- Practical usage examples for the lurek.animation API (45 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.animation.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/animation.lua

print("[example] lurek.animation — 45 API entries")

-- ── lurek.animation.* free functions ──

--@api-stub: lurek.animation.new
-- Creates a new, empty Animation controller.
-- Call when you need to invoke new.
local ok, obj = pcall(function() return lurek.animation.new() end)
if ok and obj then print("created:", obj) end
print("lurek.animation.new ok=", ok)

--@api-stub: lurek.animation.fromAseprite
-- Parses an Aseprite JSON export string and builds an Animation with clips and frames.
-- Call when you need to invoke from aseprite.
local ok, obj = pcall(function() return lurek.animation.fromAseprite("json_str value") end)
if ok and obj then print("created:", obj) end
print("lurek.animation.fromAseprite ok=", ok)

--@api-stub: lurek.animation.newStateMachine
-- Creates an animation FSM from an Animation controller and an initial state name.
-- Call when you need to create a new state machine.
local ok, obj = pcall(function() return lurek.animation.newStateMachine(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.animation.newStateMachine ok=", ok)

--@api-stub: lurek.animation.newCurve
-- Creates a new empty [`AnimCurve`] with linear interpolation.
-- Call when you need to create a new curve.
local ok, obj = pcall(function() return lurek.animation.newCurve() end)
if ok and obj then print("created:", obj) end
print("lurek.animation.newCurve ok=", ok)

--@api-stub: lurek.animation.newSyncGroup
-- Creates a new empty [`AnimSyncGroup`].
-- Call when you need to create a new sync group.
local ok, obj = pcall(function() return lurek.animation.newSyncGroup() end)
if ok and obj then print("created:", obj) end
print("lurek.animation.newSyncGroup ok=", ok)

--@api-stub: lurek.animation.newBlendLayerSet
-- Creates a new empty [`BlendLayerSet`] for compositing multiple animation clips.
-- Call when you need to create a new blend layer set.
local ok, obj = pcall(function() return lurek.animation.newBlendLayerSet() end)
if ok and obj then print("created:", obj) end
print("lurek.animation.newBlendLayerSet ok=", ok)

-- ── Animation methods ──

--@api-stub: Animation:addFrame
-- Adds a single frame to the frame pool by source rectangle.
-- Call when you need to add frame.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:addFrame(0, 0, 100, 100) end)
  print("Animation:addFrame ->", ok, result)
end

--@api-stub: Animation:play
-- Starts playback of the named clip.
-- Call when you need to invoke play.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:play("name") end)
  print("Animation:play ->", ok, result)
end

--@api-stub: Animation:stop
-- Stops playback and resets to frame 0.
-- Call when you need to invoke stop.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:stop() end)
  print("Animation:stop ->", ok, result)
end

--@api-stub: Animation:pause
-- Pauses playback at the current frame.
-- Call when you need to invoke pause.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:pause() end)
  print("Animation:pause ->", ok, result)
end

--@api-stub: Animation:resume
-- Resumes playback from the current frame.
-- Call when you need to invoke resume.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:resume() end)
  print("Animation:resume ->", ok, result)
end

--@api-stub: Animation:update
-- Advances the animation by dt seconds.
-- Call when you need to invoke update.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Animation:update ->", ok, result)
end

--@api-stub: Animation:getQuad
-- Returns the source quad (x, y, w, h) for the current frame, or nil.
-- Call when you need to read quad.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:getQuad() end)
  print("Animation:getQuad ->", ok, result)
end

--@api-stub: Animation:pollEvents
-- Drains and returns all pending animation events as a table.
-- Call when you need to invoke poll events.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:pollEvents() end)
  print("Animation:pollEvents ->", ok, result)
end

--@api-stub: Animation:isPlaying
-- Returns true if a clip is currently playing.
-- Call when you need to check is playing.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:isPlaying() end)
  print("Animation:isPlaying ->", ok, result)
end

--@api-stub: Animation:isLooping
-- Returns true if the current clip is set to loop.
-- Call when you need to check is looping.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:isLooping() end)
  print("Animation:isLooping ->", ok, result)
end

--@api-stub: Animation:getClip
-- Returns the name of the currently playing clip, or nil.
-- Call when you need to read clip.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:getClip() end)
  print("Animation:getClip ->", ok, result)
end

--@api-stub: Animation:getSpeed
-- Returns the playback speed multiplier.
-- Call when you need to read speed.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:getSpeed() end)
  print("Animation:getSpeed ->", ok, result)
end

--@api-stub: Animation:setSpeed
-- Sets the playback speed multiplier.
-- Call when you need to assign speed.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:setSpeed(nil) end)
  print("Animation:setSpeed ->", ok, result)
end

--@api-stub: Animation:getFrameCount
-- Returns the total number of frames in the frame pool.
-- Call when you need to read frame count.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:getFrameCount() end)
  print("Animation:getFrameCount ->", ok, result)
end

--@api-stub: Animation:getClipCount
-- Returns the number of registered clips.
-- Call when you need to read clip count.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:getClipCount() end)
  print("Animation:getClipCount ->", ok, result)
end

--@api-stub: Animation:getCurrentFrame
-- Returns the current position within the active clip (0-based).
-- Call when you need to read current frame.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:getCurrentFrame() end)
  print("Animation:getCurrentFrame ->", ok, result)
end

--@api-stub: Animation:setFrame
-- Sets the playback position within the current clip.
-- Call when you need to assign frame.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:setFrame(1) end)
  print("Animation:setFrame ->", ok, result)
end

--@api-stub: Animation:getBlendState
-- Returns the two quads and blend factor during a crossfade, or nil when not blending.
-- Call when you need to read blend state.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:getBlendState() end)
  print("Animation:getBlendState ->", ok, result)
end

--@api-stub: Animation:drawToImage
-- Renders the current animation frame into a new ImageData (white bg, blue frame rect).
-- Call when you need to render to image.
-- Build a Animation via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage(100, 100) end)
  print("Animation:drawToImage ->", ok, result)
end

-- ── AnimStateMachine methods ──

--@api-stub: AnimStateMachine:update
-- Advances the FSM by `dt` seconds, evaluating transitions.
-- Call when you need to invoke update.
-- Build a AnimStateMachine via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("AnimStateMachine:update ->", ok, result)
end

--@api-stub: AnimStateMachine:getState
-- Returns the name of the currently active state.
-- Call when you need to read state.
-- Build a AnimStateMachine via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:getState() end)
  print("AnimStateMachine:getState ->", ok, result)
end

--@api-stub: AnimStateMachine:forceState
-- Immediately jumps to the named state, bypassing transition conditions.
-- Call when you need to invoke force state.
-- Build a AnimStateMachine via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:forceState("name") end)
  print("AnimStateMachine:forceState ->", ok, result)
end

--@api-stub: AnimStateMachine:setParam
-- Sets an FSM parameter value (number, boolean, or integer supported).
-- Call when you need to assign param.
-- Build a AnimStateMachine via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:setParam("name", nil) end)
  print("AnimStateMachine:setParam ->", ok, result)
end

--@api-stub: AnimStateMachine:getQuad
-- Returns the source quad for the current animation frame, or nil.
-- Call when you need to read quad.
-- Build a AnimStateMachine via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimStateMachine(...)
if instance then
  local ok, result = pcall(function() return instance:getQuad() end)
  print("AnimStateMachine:getQuad ->", ok, result)
end

-- ── BlendLayerSet methods ──

--@api-stub: BlendLayerSet:removeLayer
-- Removes a blend layer by name.
-- Call when you need to remove layer.
-- Build a BlendLayerSet via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newBlendLayerSet(...)
if instance then
  local ok, result = pcall(function() return instance:removeLayer("name") end)
  print("BlendLayerSet:removeLayer ->", ok, result)
end

--@api-stub: BlendLayerSet:setWeight
-- Sets the blend weight of a named layer (clamped to [0, 1]).
-- Call when you need to assign weight.
-- Build a BlendLayerSet via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newBlendLayerSet(...)
if instance then
  local ok, result = pcall(function() return instance:setWeight("name", nil) end)
  print("BlendLayerSet:setWeight ->", ok, result)
end

--@api-stub: BlendLayerSet:getWeight
-- Returns the blend weight of a named layer, or nil if not found.
-- Call when you need to read weight.
-- Build a BlendLayerSet via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newBlendLayerSet(...)
if instance then
  local ok, result = pcall(function() return instance:getWeight("name") end)
  print("BlendLayerSet:getWeight ->", ok, result)
end

--@api-stub: BlendLayerSet:setMask
-- Replaces the bone mask of a layer.
-- Call when you need to assign mask.
-- Build a BlendLayerSet via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newBlendLayerSet(...)
if instance then
  local ok, result = pcall(function() return instance:setMask("name", nil) end)
  print("BlendLayerSet:setMask ->", ok, result)
end

--@api-stub: BlendLayerSet:listLayers
-- Returns an ordered array of layer info tables: {name, clip_name, weight, bones}.
-- Call when you need to invoke list layers.
-- Build a BlendLayerSet via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newBlendLayerSet(...)
if instance then
  local ok, result = pcall(function() return instance:listLayers() end)
  print("BlendLayerSet:listLayers ->", ok, result)
end

--@api-stub: BlendLayerSet:len
-- Returns the number of blend layers.
-- Call when you need to invoke len.
-- Build a BlendLayerSet via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newBlendLayerSet(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("BlendLayerSet:len ->", ok, result)
end

-- ── AnimCurve methods ──

--@api-stub: AnimCurve:addKeyframe
-- Inserts a keyframe at the given time.
-- If a keyframe at the same time already.
-- Build a AnimCurve via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimCurve(...)
if instance then
  local ok, result = pcall(function() return instance:addKeyframe(nil, nil) end)
  print("AnimCurve:addKeyframe ->", ok, result)
end

--@api-stub: AnimCurve:eval
-- Returns the interpolated value at the given time using the curve's easing.
-- Call when you need to invoke eval.
-- Build a AnimCurve via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimCurve(...)
if instance then
  local ok, result = pcall(function() return instance:eval(nil) end)
  print("AnimCurve:eval ->", ok, result)
end

--@api-stub: AnimCurve:setEasing
-- Sets the easing kind applied between all keyframe segments.
-- Call when you need to assign easing.
-- Build a AnimCurve via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimCurve(...)
if instance then
  local ok, result = pcall(function() return instance:setEasing(nil) end)
  print("AnimCurve:setEasing ->", ok, result)
end

--@api-stub: AnimCurve:keyframeCount
-- Returns the number of keyframes currently stored.
-- Call when you need to invoke keyframe count.
-- Build a AnimCurve via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimCurve(...)
if instance then
  local ok, result = pcall(function() return instance:keyframeCount() end)
  print("AnimCurve:keyframeCount ->", ok, result)
end

--@api-stub: AnimCurve:clear
-- Removes all keyframes from this animation curve, resetting it to empty.
-- Call when you need to invoke clear.
-- Build a AnimCurve via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimCurve(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("AnimCurve:clear ->", ok, result)
end

-- ── AnimSyncGroup methods ──

--@api-stub: AnimSyncGroup:add
-- Adds an animation handle to the group.
-- Call when you need to invoke add.
-- Build a AnimSyncGroup via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimSyncGroup(...)
if instance then
  local ok, result = pcall(function() return instance:add(nil) end)
  print("AnimSyncGroup:add ->", ok, result)
end

--@api-stub: AnimSyncGroup:remove
-- Removes an animation handle from the group.
-- Call when you need to invoke remove.
-- Build a AnimSyncGroup via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimSyncGroup(...)
if instance then
  local ok, result = pcall(function() return instance:remove(nil) end)
  print("AnimSyncGroup:remove ->", ok, result)
end

--@api-stub: AnimSyncGroup:clear
-- Removes all animation handles from the group.
-- Call when you need to invoke clear.
-- Build a AnimSyncGroup via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimSyncGroup(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("AnimSyncGroup:clear ->", ok, result)
end

--@api-stub: AnimSyncGroup:memberCount
-- Returns the number of animations currently in the group.
-- Call when you need to invoke member count.
-- Build a AnimSyncGroup via the appropriate lurek.animation.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.animation.newAnimSyncGroup(...)
if instance then
  local ok, result = pcall(function() return instance:memberCount() end)
  print("AnimSyncGroup:memberCount ->", ok, result)
end

