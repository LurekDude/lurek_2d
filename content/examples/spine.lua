-- content/examples/spine.lua
-- Practical usage examples for the lurek.spine API (20 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.spine.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/spine.lua

print("[example] lurek.spine — 20 API entries")

-- ── lurek.spine.* free functions ──

--@api-stub: lurek.spine.newSkeleton
-- Creates a new empty skeleton with the given name.
-- Call when you need to create a new skeleton.
local ok, obj = pcall(function() return lurek.spine.newSkeleton("name") end)
if ok and obj then print("created:", obj) end
print("lurek.spine.newSkeleton ok=", ok)

--@api-stub: lurek.spine.newSkeletonAnimation
-- Creates a new empty SkeletonAnimation clip with the given name and duration.
-- Call when you need to create a new skeleton animation.
local ok, obj = pcall(function() return lurek.spine.newSkeletonAnimation("name", 1.0) end)
if ok and obj then print("created:", obj) end
print("lurek.spine.newSkeletonAnimation ok=", ok)

-- ── Skeleton methods ──

--@api-stub: Skeleton:findBone
-- Returns the index of the named bone, or nil if not found.
-- Call when you need to invoke find bone.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:findBone("name") end)
  print("Skeleton:findBone ->", ok, result)
end

--@api-stub: Skeleton:findSlot
-- Returns the index of the named slot, or nil if not found.
-- Call when you need to invoke find slot.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:findSlot("name") end)
  print("Skeleton:findSlot ->", ok, result)
end

--@api-stub: Skeleton:updateWorldTransforms
-- Propagates local transforms down the bone hierarchy to compute world positions.
-- Call when you need to invoke update world transforms.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:updateWorldTransforms() end)
  print("Skeleton:updateWorldTransforms ->", ok, result)
end

--@api-stub: Skeleton:getBoneWorld
-- Returns the world-space transform of a bone as a table, or nil if out of range.
-- Call when you need to read bone world.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:getBoneWorld(1) end)
  print("Skeleton:getBoneWorld ->", ok, result)
end

--@api-stub: Skeleton:setPosition
-- Sets the root bone position and propagates world transforms.
-- Call when you need to assign position.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:setPosition(0, 0) end)
  print("Skeleton:setPosition ->", ok, result)
end

--@api-stub: Skeleton:boneCount
-- Returns the total number of bones.
-- Call when you need to invoke bone count.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:boneCount() end)
  print("Skeleton:boneCount ->", ok, result)
end

--@api-stub: Skeleton:slotCount
-- Returns the total number of slots.
-- Call when you need to invoke slot count.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:slotCount() end)
  print("Skeleton:slotCount ->", ok, result)
end

--@api-stub: Skeleton:drawToImage
-- Renders the skeleton as a stick-figure debug view into a new ImageData.
-- Call when you need to render to image.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:drawToImage(100, 100) end)
  print("Skeleton:drawToImage ->", ok, result)
end

--@api-stub: Skeleton:stopAnimation
-- Stops the current skeletal animation.
-- Call when you need to invoke stop animation.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:stopAnimation() end)
  print("Skeleton:stopAnimation ->", ok, result)
end

--@api-stub: Skeleton:updateAnimation
-- Advances the playing animation by `dt` seconds and applies keyframes.
-- Call when you need to invoke update animation.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:updateAnimation(1.0) end)
  print("Skeleton:updateAnimation ->", ok, result)
end

--@api-stub: Skeleton:getAnimationTime
-- Returns the current playback time in seconds of the active animation.
-- Call when you need to read animation time.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:getAnimationTime() end)
  print("Skeleton:getAnimationTime ->", ok, result)
end

--@api-stub: Skeleton:addAnimation
-- Adds a SkeletonAnimation to this skeleton's library.
-- Call when you need to add animation.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:addAnimation(nil) end)
  print("Skeleton:addAnimation ->", ok, result)
end

--@api-stub: Skeleton:addSkin
-- Registers a new empty skin by name.
-- Call when you need to add skin.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:addSkin("name") end)
  print("Skeleton:addSkin ->", ok, result)
end

--@api-stub: Skeleton:setSkin
-- Activates the named skin for attachment lookups.
-- Call when you need to assign skin.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:setSkin("name") end)
  print("Skeleton:setSkin ->", ok, result)
end

--@api-stub: Skeleton:getSkin
-- Returns the name of the currently active skin, or nil.
-- Call when you need to read skin.
-- Build a Skeleton via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeleton(...)
if instance then
  local ok, result = pcall(function() return instance:getSkin() end)
  print("Skeleton:getSkin ->", ok, result)
end

-- ── SkeletonAnimation methods ──

--@api-stub: SkeletonAnimation:getDuration
-- Returns the total duration of the animation in seconds.
-- Call when you need to read duration.
-- Build a SkeletonAnimation via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeletonAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:getDuration() end)
  print("SkeletonAnimation:getDuration ->", ok, result)
end

--@api-stub: SkeletonAnimation:getEvents
-- Returns a list of event names that fall in the half-open interval `(from, to]`.
-- Call when you need to read events.
-- Build a SkeletonAnimation via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeletonAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:getEvents(nil, nil) end)
  print("SkeletonAnimation:getEvents ->", ok, result)
end

--@api-stub: SkeletonAnimation:getTimelineCount
-- Returns the number of bone timelines in this animation.
-- Call when you need to read timeline count.
-- Build a SkeletonAnimation via the appropriate lurek.spine.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.spine.newSkeletonAnimation(...)
if instance then
  local ok, result = pcall(function() return instance:getTimelineCount() end)
  print("SkeletonAnimation:getTimelineCount ->", ok, result)
end

