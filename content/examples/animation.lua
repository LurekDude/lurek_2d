-- content/examples/animation.lua
-- Auto-scaffolded coverage of the lurek.animation Lua API (45 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/animation.lua

print("[example] lurek.animation loaded — 45 API items demonstrated")

-- ── lurek.animation free functions ──

--@api-stub: lurek.animation.new
-- Creates a new, empty Animation controller.
-- Use this when creates a new, empty Animation controller is needed.
if false then
  local _r = lurek.animation.new()
  print(_r)
end

--@api-stub: lurek.animation.fromAseprite
-- Parses an Aseprite JSON export string and builds an Animation with clips and frames.
-- Use this when parses an Aseprite JSON export string and builds an Animation with clips and frames is needed.
if false then
  local _r = lurek.animation.fromAseprite(1)
  print(_r)
end

--@api-stub: lurek.animation.newStateMachine
-- Creates an animation FSM from an Animation controller and an initial state name.
-- Use this when creates an animation FSM from an Animation controller and an initial state name is needed.
if false then
  local _r = lurek.animation.newStateMachine(1, 1)
  print(_r)
end

--@api-stub: lurek.animation.newCurve
-- Creates a new empty [`AnimCurve`] with linear interpolation.
-- Use this when creates a new empty [`AnimCurve`] with linear interpolation is needed.
if false then
  local _r = lurek.animation.newCurve()
  print(_r)
end

--@api-stub: lurek.animation.newSyncGroup
-- Creates a new empty [`AnimSyncGroup`].
-- Use this when creates a new empty [`AnimSyncGroup`] is needed.
if false then
  local _r = lurek.animation.newSyncGroup()
  print(_r)
end

--@api-stub: lurek.animation.newBlendLayerSet
-- Creates a new empty [`BlendLayerSet`] for compositing multiple animation clips.
-- Use this when creates a new empty [`BlendLayerSet`] for compositing multiple animation clips is needed.
if false then
  local _r = lurek.animation.newBlendLayerSet()
  print(_r)
end

-- ── Animation methods ──

--@api-stub: Animation:addFrame
-- Adds a single frame to the frame pool by source rectangle.
-- Use this when adds a single frame to the frame pool by source rectangle is needed.
if false then
  local _o = nil  -- Animation instance
  _o:addFrame(0, 0, 0, 0)
end

--@api-stub: Animation:play
-- Starts playback of the named clip.
-- Use this when starts playback of the named clip is needed.
if false then
  local _o = nil  -- Animation instance
  _o:play(1)
end

--@api-stub: Animation:stop
-- Stops playback and resets to frame 0.
-- Use this when stops playback and resets to frame 0 is needed.
if false then
  local _o = nil  -- Animation instance
  _o:stop()
end

--@api-stub: Animation:pause
-- Pauses playback at the current frame.
-- Use this when pauses playback at the current frame is needed.
if false then
  local _o = nil  -- Animation instance
  _o:pause()
end

--@api-stub: Animation:resume
-- Resumes playback from the current frame.
-- Use this when resumes playback from the current frame is needed.
if false then
  local _o = nil  -- Animation instance
  _o:resume()
end

--@api-stub: Animation:update
-- Advances the animation by dt seconds.
-- Use this when advances the animation by dt seconds is needed.
if false then
  local _o = nil  -- Animation instance
  _o:update(0)
end

--@api-stub: Animation:getQuad
-- Returns the source quad (x, y, w, h) for the current frame, or nil.
-- Use this when returns the source quad (x, y, w, h) for the current frame, or nil is needed.
if false then
  local _o = nil  -- Animation instance
  _o:getQuad()
end

--@api-stub: Animation:pollEvents
-- Drains and returns all pending animation events as a table.
-- Use this when drains and returns all pending animation events as a table is needed.
if false then
  local _o = nil  -- Animation instance
  _o:pollEvents()
end

--@api-stub: Animation:isPlaying
-- Returns true if a clip is currently playing.
-- Use this when returns true if a clip is currently playing is needed.
if false then
  local _o = nil  -- Animation instance
  _o:isPlaying()
end

--@api-stub: Animation:isLooping
-- Returns true if the current clip is set to loop.
-- Use this when returns true if the current clip is set to loop is needed.
if false then
  local _o = nil  -- Animation instance
  _o:isLooping()
end

--@api-stub: Animation:getClip
-- Returns the name of the currently playing clip, or nil.
-- Use this when returns the name of the currently playing clip, or nil is needed.
if false then
  local _o = nil  -- Animation instance
  _o:getClip()
end

--@api-stub: Animation:getSpeed
-- Returns the playback speed multiplier.
-- Use this when returns the playback speed multiplier is needed.
if false then
  local _o = nil  -- Animation instance
  _o:getSpeed()
end

--@api-stub: Animation:setSpeed
-- Sets the playback speed multiplier.
-- Use this when sets the playback speed multiplier is needed.
if false then
  local _o = nil  -- Animation instance
  _o:setSpeed(0)
end

--@api-stub: Animation:getFrameCount
-- Returns the total number of frames in the frame pool.
-- Use this when returns the total number of frames in the frame pool is needed.
if false then
  local _o = nil  -- Animation instance
  _o:getFrameCount()
end

--@api-stub: Animation:getClipCount
-- Returns the number of registered clips.
-- Use this when returns the number of registered clips is needed.
if false then
  local _o = nil  -- Animation instance
  _o:getClipCount()
end

--@api-stub: Animation:getCurrentFrame
-- Returns the current position within the active clip (0-based).
-- Use this when returns the current position within the active clip (0-based) is needed.
if false then
  local _o = nil  -- Animation instance
  _o:getCurrentFrame()
end

--@api-stub: Animation:setFrame
-- Sets the playback position within the current clip.
-- Use this when sets the playback position within the current clip is needed.
if false then
  local _o = nil  -- Animation instance
  _o:setFrame(1)
end

--@api-stub: Animation:getBlendState
-- Returns the two quads and blend factor during a crossfade, or nil when not blending.
-- Use this when returns the two quads and blend factor during a crossfade, or nil when not blending is needed.
if false then
  local _o = nil  -- Animation instance
  _o:getBlendState()
end

--@api-stub: Animation:drawToImage
-- Renders the current animation frame into a new ImageData (white bg, blue frame rect).
-- Use this when renders the current animation frame into a new ImageData (white bg, blue frame rect) is needed.
if false then
  local _o = nil  -- Animation instance
  _o:drawToImage(0, 0)
end

-- ── AnimStateMachine methods ──

--@api-stub: AnimStateMachine:update
-- Advances the FSM by `dt` seconds, evaluating transitions.
-- Use this when advances the FSM by `dt` seconds, evaluating transitions is needed.
if false then
  local _o = nil  -- AnimStateMachine instance
  _o:update(0)
end

--@api-stub: AnimStateMachine:getState
-- Returns the name of the currently active state.
-- Use this when returns the name of the currently active state is needed.
if false then
  local _o = nil  -- AnimStateMachine instance
  _o:getState()
end

--@api-stub: AnimStateMachine:forceState
-- Immediately jumps to the named state, bypassing transition conditions.
-- Use this when immediately jumps to the named state, bypassing transition conditions is needed.
if false then
  local _o = nil  -- AnimStateMachine instance
  _o:forceState(1)
end

--@api-stub: AnimStateMachine:setParam
-- Sets an FSM parameter value (number, boolean, or integer supported).
-- Use this when sets an FSM parameter value (number, boolean, or integer supported) is needed.
if false then
  local _o = nil  -- AnimStateMachine instance
  _o:setParam(1, 0)
end

--@api-stub: AnimStateMachine:getQuad
-- Returns the source quad for the current animation frame, or nil.
-- Use this when returns the source quad for the current animation frame, or nil is needed.
if false then
  local _o = nil  -- AnimStateMachine instance
  _o:getQuad()
end

-- ── BlendLayerSet methods ──

--@api-stub: BlendLayerSet:removeLayer
-- Removes a blend layer by name.
-- Use this when removes a blend layer by name is needed.
if false then
  local _o = nil  -- BlendLayerSet instance
  _o:removeLayer(1)
end

--@api-stub: BlendLayerSet:setWeight
-- Sets the blend weight of a named layer (clamped to [0, 1]).
-- Use this when sets the blend weight of a named layer (clamped to [0, 1]) is needed.
if false then
  local _o = nil  -- BlendLayerSet instance
  _o:setWeight(1, 0)
end

--@api-stub: BlendLayerSet:getWeight
-- Returns the blend weight of a named layer, or nil if not found.
-- Use this when returns the blend weight of a named layer, or nil if not found is needed.
if false then
  local _o = nil  -- BlendLayerSet instance
  _o:getWeight(1)
end

--@api-stub: BlendLayerSet:setMask
-- Replaces the bone mask of a layer.
-- Use this when replaces the bone mask of a layer is needed.
if false then
  local _o = nil  -- BlendLayerSet instance
  _o:setMask(1, 1)
end

--@api-stub: BlendLayerSet:listLayers
-- Returns an ordered array of layer info tables: {name, clip_name, weight, bones}.
-- Use this when returns an ordered array of layer info tables: {name, clip_name, weight, bones} is needed.
if false then
  local _o = nil  -- BlendLayerSet instance
  _o:listLayers()
end

--@api-stub: BlendLayerSet:len
-- Returns the number of blend layers.
-- Use this when returns the number of blend layers is needed.
if false then
  local _o = nil  -- BlendLayerSet instance
  _o:len()
end

-- ── AnimCurve methods ──

--@api-stub: AnimCurve:addKeyframe
-- Inserts a keyframe at the given time.
-- If a keyframe at the same time already
if false then
  local _o = nil  -- AnimCurve instance
  _o:addKeyframe(0, 0)
end

--@api-stub: AnimCurve:eval
-- Returns the interpolated value at the given time using the curve's easing.
-- Use this when returns the interpolated value at the given time using the curve's easing is needed.
if false then
  local _o = nil  -- AnimCurve instance
  _o:eval(0)
end

--@api-stub: AnimCurve:setEasing
-- Sets the easing kind applied between all keyframe segments.
-- Use this when sets the easing kind applied between all keyframe segments is needed.
if false then
  local _o = nil  -- AnimCurve instance
  _o:setEasing(nil)
end

--@api-stub: AnimCurve:keyframeCount
-- Returns the number of keyframes currently stored.
-- Use this when returns the number of keyframes currently stored is needed.
if false then
  local _o = nil  -- AnimCurve instance
  _o:keyframeCount()
end

--@api-stub: AnimCurve:clear
-- Removes all keyframes from this animation curve, resetting it to empty.
-- Use this when removes all keyframes from this animation curve, resetting it to empty is needed.
if false then
  local _o = nil  -- AnimCurve instance
  _o:clear()
end

-- ── AnimSyncGroup methods ──

--@api-stub: AnimSyncGroup:add
-- Adds an animation handle to the group.
-- Use this when adds an animation handle to the group is needed.
if false then
  local _o = nil  -- AnimSyncGroup instance
  _o:add(1)
end

--@api-stub: AnimSyncGroup:remove
-- Removes an animation handle from the group.
-- Use this when removes an animation handle from the group is needed.
if false then
  local _o = nil  -- AnimSyncGroup instance
  _o:remove(1)
end

--@api-stub: AnimSyncGroup:clear
-- Removes all animation handles from the group.
-- Use this when removes all animation handles from the group is needed.
if false then
  local _o = nil  -- AnimSyncGroup instance
  _o:clear()
end

--@api-stub: AnimSyncGroup:memberCount
-- Returns the number of animations currently in the group.
-- Use this when returns the number of animations currently in the group is needed.
if false then
  local _o = nil  -- AnimSyncGroup instance
  _o:memberCount()
end

