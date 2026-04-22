-- content/examples/spine.lua
-- Scaffolded coverage of the lurek.spine API (20 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/spine_api.rs   (Lua binding, arg types, return shape)
--   * src/spine/                 (semantics, side effects)
--   * docs/specs/spine.md        (canonical reference)
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
-- Run: cargo run -- content/examples/spine.lua

-- ── lurek.spine.* functions ──

--@api-stub: lurek.spine.newSkeleton
-- Creates a new empty skeleton with the given name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: lurek.spine.newSkeleton
  local _todo = "TODO: write a real lurek.spine.newSkeleton usage example"
  print(_todo)
end

--@api-stub: lurek.spine.newSkeletonAnimation
-- Creates a new empty SkeletonAnimation clip with the given name and duration.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: lurek.spine.newSkeletonAnimation
  local _todo = "TODO: write a real lurek.spine.newSkeletonAnimation usage example"
  print(_todo)
end

-- ── Skeleton methods ──

--@api-stub: Skeleton:findBone
-- Returns the index of the named bone, or nil if not found.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:findBone
  local _todo = "TODO: write a real Skeleton:findBone usage example"
  print(_todo)
end

--@api-stub: Skeleton:findSlot
-- Returns the index of the named slot, or nil if not found.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:findSlot
  local _todo = "TODO: write a real Skeleton:findSlot usage example"
  print(_todo)
end

--@api-stub: Skeleton:updateWorldTransforms
-- Propagates local transforms down the bone hierarchy to compute world positions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:updateWorldTransforms
  local _todo = "TODO: write a real Skeleton:updateWorldTransforms usage example"
  print(_todo)
end

--@api-stub: Skeleton:getBoneWorld
-- Returns the world-space transform of a bone as a table, or nil if out of range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:getBoneWorld
  local _todo = "TODO: write a real Skeleton:getBoneWorld usage example"
  print(_todo)
end

--@api-stub: Skeleton:setPosition
-- Sets the root bone position and propagates world transforms.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:setPosition
  local _todo = "TODO: write a real Skeleton:setPosition usage example"
  print(_todo)
end

--@api-stub: Skeleton:boneCount
-- Returns the total number of bones.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:boneCount
  local _todo = "TODO: write a real Skeleton:boneCount usage example"
  print(_todo)
end

--@api-stub: Skeleton:slotCount
-- Returns the total number of slots.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:slotCount
  local _todo = "TODO: write a real Skeleton:slotCount usage example"
  print(_todo)
end

--@api-stub: Skeleton:drawToImage
-- Renders the skeleton as a stick-figure debug view into a new ImageData.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:drawToImage
  local _todo = "TODO: write a real Skeleton:drawToImage usage example"
  print(_todo)
end

--@api-stub: Skeleton:stopAnimation
-- Stops the current skeletal animation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:stopAnimation
  local _todo = "TODO: write a real Skeleton:stopAnimation usage example"
  print(_todo)
end

--@api-stub: Skeleton:updateAnimation
-- Advances the playing animation by `dt` seconds and applies keyframes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:updateAnimation
  local _todo = "TODO: write a real Skeleton:updateAnimation usage example"
  print(_todo)
end

--@api-stub: Skeleton:getAnimationTime
-- Returns the current playback time in seconds of the active animation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:getAnimationTime
  local _todo = "TODO: write a real Skeleton:getAnimationTime usage example"
  print(_todo)
end

--@api-stub: Skeleton:addAnimation
-- Adds a SkeletonAnimation to this skeleton's library.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:addAnimation
  local _todo = "TODO: write a real Skeleton:addAnimation usage example"
  print(_todo)
end

--@api-stub: Skeleton:addSkin
-- Registers a new empty skin by name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:addSkin
  local _todo = "TODO: write a real Skeleton:addSkin usage example"
  print(_todo)
end

--@api-stub: Skeleton:setSkin
-- Activates the named skin for attachment lookups.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:setSkin
  local _todo = "TODO: write a real Skeleton:setSkin usage example"
  print(_todo)
end

--@api-stub: Skeleton:getSkin
-- Returns the name of the currently active skin, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: Skeleton:getSkin
  local _todo = "TODO: write a real Skeleton:getSkin usage example"
  print(_todo)
end

-- ── SkeletonAnimation methods ──

--@api-stub: SkeletonAnimation:getDuration
-- Returns the total duration of the animation in seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: SkeletonAnimation:getDuration
  local _todo = "TODO: write a real SkeletonAnimation:getDuration usage example"
  print(_todo)
end

--@api-stub: SkeletonAnimation:getEvents
-- Returns a list of event names that fall in the half-open interval `(from, to]`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: SkeletonAnimation:getEvents
  local _todo = "TODO: write a real SkeletonAnimation:getEvents usage example"
  print(_todo)
end

--@api-stub: SkeletonAnimation:getTimelineCount
-- Returns the number of bone timelines in this animation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/spine_api.rs and docs/specs/spine.md).
do  -- TODO: SkeletonAnimation:getTimelineCount
  local _todo = "TODO: write a real SkeletonAnimation:getTimelineCount usage example"
  print(_todo)
end

