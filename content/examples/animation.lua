-- content/examples/animation.lua
-- Scaffolded coverage of the lurek.animation API (45 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/animation_api.rs   (Lua binding, arg types, return shape)
--   * src/animation/                 (semantics, side effects)
--   * docs/specs/animation.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/animation.lua

-- ── lurek.animation.* functions ──

--@api-stub: lurek.animation.new
-- Creates a new, empty Animation controller.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: lurek.animation.new
  local _todo = "TODO: write a real lurek.animation.new usage example"
  print(_todo)
end

--@api-stub: lurek.animation.fromAseprite
-- Parses an Aseprite JSON export string and builds an Animation with clips and frames.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: lurek.animation.fromAseprite
  local _todo = "TODO: write a real lurek.animation.fromAseprite usage example"
  print(_todo)
end

--@api-stub: lurek.animation.newStateMachine
-- Creates an animation FSM from an Animation controller and an initial state name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: lurek.animation.newStateMachine
  local _todo = "TODO: write a real lurek.animation.newStateMachine usage example"
  print(_todo)
end

--@api-stub: lurek.animation.newCurve
-- Creates a new empty [`AnimCurve`] with linear interpolation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: lurek.animation.newCurve
  local _todo = "TODO: write a real lurek.animation.newCurve usage example"
  print(_todo)
end

--@api-stub: lurek.animation.newSyncGroup
-- Creates a new empty [`AnimSyncGroup`].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: lurek.animation.newSyncGroup
  local _todo = "TODO: write a real lurek.animation.newSyncGroup usage example"
  print(_todo)
end

--@api-stub: lurek.animation.newBlendLayerSet
-- Creates a new empty [`BlendLayerSet`] for compositing multiple animation clips.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: lurek.animation.newBlendLayerSet
  local _todo = "TODO: write a real lurek.animation.newBlendLayerSet usage example"
  print(_todo)
end

-- ── Animation methods ──

--@api-stub: Animation:addFrame
-- Adds a single frame to the frame pool by source rectangle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:addFrame
  local _todo = "TODO: write a real Animation:addFrame usage example"
  print(_todo)
end

--@api-stub: Animation:play
-- Starts playback of the named clip.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:play
  local _todo = "TODO: write a real Animation:play usage example"
  print(_todo)
end

--@api-stub: Animation:stop
-- Stops playback and resets to frame 0.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:stop
  local _todo = "TODO: write a real Animation:stop usage example"
  print(_todo)
end

--@api-stub: Animation:pause
-- Pauses playback at the current frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:pause
  local _todo = "TODO: write a real Animation:pause usage example"
  print(_todo)
end

--@api-stub: Animation:resume
-- Resumes playback from the current frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:resume
  local _todo = "TODO: write a real Animation:resume usage example"
  print(_todo)
end

--@api-stub: Animation:update
-- Advances the animation by dt seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:update
  local _todo = "TODO: write a real Animation:update usage example"
  print(_todo)
end

--@api-stub: Animation:getQuad
-- Returns the source quad (x, y, w, h) for the current frame, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:getQuad
  local _todo = "TODO: write a real Animation:getQuad usage example"
  print(_todo)
end

--@api-stub: Animation:pollEvents
-- Drains and returns all pending animation events as a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:pollEvents
  local _todo = "TODO: write a real Animation:pollEvents usage example"
  print(_todo)
end

--@api-stub: Animation:isPlaying
-- Returns true if a clip is currently playing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:isPlaying
  local _todo = "TODO: write a real Animation:isPlaying usage example"
  print(_todo)
end

--@api-stub: Animation:isLooping
-- Returns true if the current clip is set to loop.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:isLooping
  local _todo = "TODO: write a real Animation:isLooping usage example"
  print(_todo)
end

--@api-stub: Animation:getClip
-- Returns the name of the currently playing clip, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:getClip
  local _todo = "TODO: write a real Animation:getClip usage example"
  print(_todo)
end

--@api-stub: Animation:getSpeed
-- Returns the playback speed multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:getSpeed
  local _todo = "TODO: write a real Animation:getSpeed usage example"
  print(_todo)
end

--@api-stub: Animation:setSpeed
-- Sets the playback speed multiplier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:setSpeed
  local _todo = "TODO: write a real Animation:setSpeed usage example"
  print(_todo)
end

--@api-stub: Animation:getFrameCount
-- Returns the total number of frames in the frame pool.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:getFrameCount
  local _todo = "TODO: write a real Animation:getFrameCount usage example"
  print(_todo)
end

--@api-stub: Animation:getClipCount
-- Returns the number of registered clips.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:getClipCount
  local _todo = "TODO: write a real Animation:getClipCount usage example"
  print(_todo)
end

--@api-stub: Animation:getCurrentFrame
-- Returns the current position within the active clip (0-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:getCurrentFrame
  local _todo = "TODO: write a real Animation:getCurrentFrame usage example"
  print(_todo)
end

--@api-stub: Animation:setFrame
-- Sets the playback position within the current clip.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:setFrame
  local _todo = "TODO: write a real Animation:setFrame usage example"
  print(_todo)
end

--@api-stub: Animation:getBlendState
-- Returns the two quads and blend factor during a crossfade, or nil when not blending.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:getBlendState
  local _todo = "TODO: write a real Animation:getBlendState usage example"
  print(_todo)
end

--@api-stub: Animation:drawToImage
-- Renders the current animation frame into a new ImageData (white bg, blue frame rect).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: Animation:drawToImage
  local _todo = "TODO: write a real Animation:drawToImage usage example"
  print(_todo)
end

-- ── AnimStateMachine methods ──

--@api-stub: AnimStateMachine:update
-- Advances the FSM by `dt` seconds, evaluating transitions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimStateMachine:update
  local _todo = "TODO: write a real AnimStateMachine:update usage example"
  print(_todo)
end

--@api-stub: AnimStateMachine:getState
-- Returns the name of the currently active state.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimStateMachine:getState
  local _todo = "TODO: write a real AnimStateMachine:getState usage example"
  print(_todo)
end

--@api-stub: AnimStateMachine:forceState
-- Immediately jumps to the named state, bypassing transition conditions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimStateMachine:forceState
  local _todo = "TODO: write a real AnimStateMachine:forceState usage example"
  print(_todo)
end

--@api-stub: AnimStateMachine:setParam
-- Sets an FSM parameter value (number, boolean, or integer supported).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimStateMachine:setParam
  local _todo = "TODO: write a real AnimStateMachine:setParam usage example"
  print(_todo)
end

--@api-stub: AnimStateMachine:getQuad
-- Returns the source quad for the current animation frame, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimStateMachine:getQuad
  local _todo = "TODO: write a real AnimStateMachine:getQuad usage example"
  print(_todo)
end

-- ── BlendLayerSet methods ──

--@api-stub: BlendLayerSet:removeLayer
-- Removes a blend layer by name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: BlendLayerSet:removeLayer
  local _todo = "TODO: write a real BlendLayerSet:removeLayer usage example"
  print(_todo)
end

--@api-stub: BlendLayerSet:setWeight
-- Sets the blend weight of a named layer (clamped to [0, 1]).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: BlendLayerSet:setWeight
  local _todo = "TODO: write a real BlendLayerSet:setWeight usage example"
  print(_todo)
end

--@api-stub: BlendLayerSet:getWeight
-- Returns the blend weight of a named layer, or nil if not found.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: BlendLayerSet:getWeight
  local _todo = "TODO: write a real BlendLayerSet:getWeight usage example"
  print(_todo)
end

--@api-stub: BlendLayerSet:setMask
-- Replaces the bone mask of a layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: BlendLayerSet:setMask
  local _todo = "TODO: write a real BlendLayerSet:setMask usage example"
  print(_todo)
end

--@api-stub: BlendLayerSet:listLayers
-- Returns an ordered array of layer info tables: {name, clip_name, weight, bones}.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: BlendLayerSet:listLayers
  local _todo = "TODO: write a real BlendLayerSet:listLayers usage example"
  print(_todo)
end

--@api-stub: BlendLayerSet:len
-- Returns the number of blend layers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: BlendLayerSet:len
  local _todo = "TODO: write a real BlendLayerSet:len usage example"
  print(_todo)
end

-- ── AnimCurve methods ──

--@api-stub: AnimCurve:addKeyframe
-- Inserts a keyframe at the given time.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimCurve:addKeyframe
  local _todo = "TODO: write a real AnimCurve:addKeyframe usage example"
  print(_todo)
end

--@api-stub: AnimCurve:eval
-- Returns the interpolated value at the given time using the curve's easing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimCurve:eval
  local _todo = "TODO: write a real AnimCurve:eval usage example"
  print(_todo)
end

--@api-stub: AnimCurve:setEasing
-- Sets the easing kind applied between all keyframe segments.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimCurve:setEasing
  local _todo = "TODO: write a real AnimCurve:setEasing usage example"
  print(_todo)
end

--@api-stub: AnimCurve:keyframeCount
-- Returns the number of keyframes currently stored.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimCurve:keyframeCount
  local _todo = "TODO: write a real AnimCurve:keyframeCount usage example"
  print(_todo)
end

--@api-stub: AnimCurve:clear
-- Removes all keyframes from this animation curve, resetting it to empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimCurve:clear
  local _todo = "TODO: write a real AnimCurve:clear usage example"
  print(_todo)
end

-- ── AnimSyncGroup methods ──

--@api-stub: AnimSyncGroup:add
-- Adds an animation handle to the group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimSyncGroup:add
  local _todo = "TODO: write a real AnimSyncGroup:add usage example"
  print(_todo)
end

--@api-stub: AnimSyncGroup:remove
-- Removes an animation handle from the group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimSyncGroup:remove
  local _todo = "TODO: write a real AnimSyncGroup:remove usage example"
  print(_todo)
end

--@api-stub: AnimSyncGroup:clear
-- Removes all animation handles from the group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimSyncGroup:clear
  local _todo = "TODO: write a real AnimSyncGroup:clear usage example"
  print(_todo)
end

--@api-stub: AnimSyncGroup:memberCount
-- Returns the number of animations currently in the group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/animation_api.rs and docs/specs/animation.md).
do  -- TODO: AnimSyncGroup:memberCount
  local _todo = "TODO: write a real AnimSyncGroup:memberCount usage example"
  print(_todo)
end

