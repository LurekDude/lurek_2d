-- content/examples/spine.lua
-- Hand-written coverage of the lurek.spine API (20 items).
--
-- The lurek.spine namespace builds skeletal-animation rigs out of bones,
-- slots, skins and keyframe timelines; `newSkeleton` produces a Skeleton
-- userdata that owns an animation library, while `newSkeletonAnimation`
-- produces a clip that can be added to one or more skeletons.
--
-- Run: cargo run -- content/examples/spine.lua

-- ── lurek.spine.* functions ──

--@api-stub: lurek.spine.newSkeleton
-- Creates a new empty skeleton with the given name.
-- Build the bone hierarchy with addBone/addChildBone right after construction; the name is used in logs and lookups.
do  -- lurek.spine.newSkeleton
  local hero = lurek.spine.newSkeleton("hero")
  local root = hero:addBone("root", { x = 320, y = 240 })
  hero:addChildBone("torso", root, { y = -40 })
  lurek.log.info("hero rig built with " .. hero:boneCount() .. " bones", "spine")
end

--@api-stub: lurek.spine.newSkeletonAnimation
-- Creates a new empty SkeletonAnimation clip with the given name and duration.
-- Pick a duration that matches the longest keyframe time you intend to add; loops wrap modulo this value.
do  -- lurek.spine.newSkeletonAnimation
  local idle = lurek.spine.newSkeletonAnimation("idle", 1.5)
  idle:addKeyframe(0, "y", 0.0,  0, "ease_in_out")
  idle:addKeyframe(0, "y", 0.75, 4, "ease_in_out")
  idle:addKeyframe(0, "y", 1.5,  0, "ease_in_out")
end

-- ── Skeleton methods ──

--@api-stub: Skeleton:findBone
-- Returns the index of the named bone, or nil if not found.
-- Cache the returned index at load time; later per-frame calls should reuse it instead of looking up by name.
do  -- Skeleton:findBone
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  rig:addChildBone("head", 0)
  local head_idx = rig:findBone("head")
  if head_idx then lurek.log.debug("head bone at index " .. head_idx, "spine") end
end

--@api-stub: Skeleton:findSlot
-- Returns the index of the named slot, or nil if not found.
-- Use to resolve attachment slots before swapping skins or reading slot attachment names at runtime.
do  -- Skeleton:findSlot
  local rig = lurek.spine.newSkeleton("npc")
  local b = rig:addBone("torso")
  rig:addSlot("chest", b, "shirt_default")
  local slot_idx = rig:findSlot("chest")
  if slot_idx then lurek.log.debug("chest slot at " .. slot_idx, "spine") end
end

--@api-stub: Skeleton:updateWorldTransforms
-- Propagates local transforms down the bone hierarchy to compute world positions.
-- Call after mutating bones via setPosition or IK before reading world positions or rendering.
do  -- Skeleton:updateWorldTransforms
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root", { x = 100, y = 100 })
  rig:addChildBone("arm", 0, { x = 20 })
  rig:setPosition(200, 150)
  rig:updateWorldTransforms()
end

--@api-stub: Skeleton:getBoneWorld
-- Returns the world-space transform of a bone as a table, or nil if out of range.
-- The result has x, y, rotation, scale_x, scale_y — handy for spawning particles or muzzle flashes at a bone.
do  -- Skeleton:getBoneWorld
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("muzzle", { x = 50, y = 0 })
  rig:updateWorldTransforms()
  local t = rig:getBoneWorld(0)
  if t then lurek.log.info("muzzle world x=" .. t.x .. " y=" .. t.y, "spine") end
end

--@api-stub: Skeleton:setPosition
-- Sets the root bone position and propagates world transforms.
-- Use once per frame to follow the player or world entity that owns the rig; updateWorldTransforms is implied.
do  -- Skeleton:setPosition
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  local player = { x = 0, y = 0 }
  function lurek.process(dt)
    player.x = player.x + 60 * dt
    rig:setPosition(player.x, player.y)
  end
end

--@api-stub: Skeleton:boneCount
-- Returns the total number of bones.
-- Useful as a sanity check after loading a rig from data, or when iterating timelines by index.
do  -- Skeleton:boneCount
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root"); rig:addChildBone("torso", 0); rig:addChildBone("head", 1)
  if rig:boneCount() < 3 then
    lurek.log.warn("rig is missing bones: " .. rig:boneCount(), "spine")
  end
end

--@api-stub: Skeleton:slotCount
-- Returns the total number of slots.
-- Pair with findSlot to validate that every named slot expected by the art pipeline is present.
do  -- Skeleton:slotCount
  local rig = lurek.spine.newSkeleton("npc")
  local b = rig:addBone("torso")
  rig:addSlot("chest", b); rig:addSlot("belt", b)
  lurek.log.info("rig exposes " .. rig:slotCount() .. " attachment slots", "spine")
end

--@api-stub: Skeleton:drawToImage
-- Renders the skeleton as a stick-figure debug view into a new ImageData.
-- Use for tooling or in-game debug overlays; promote the result to a texture with newImage to draw it on screen.
do  -- Skeleton:drawToImage
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root", { x = 64, y = 64 })
  rig:addChildBone("arm", 0, { x = 32 })
  rig:updateWorldTransforms()
  local debug_tex
  function lurek.init() debug_tex = lurek.render.newImage(rig:drawToImage(128, 128)) end
  function lurek.render() lurek.render.draw(debug_tex, 16, 16) end
end

--@api-stub: Skeleton:stopAnimation
-- Stops the current skeletal animation.
-- Call when leaving an AI state (e.g. cancel walk on death) so the playhead does not advance further.
do  -- Skeleton:stopAnimation
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  local walk = lurek.spine.newSkeletonAnimation("walk", 0.6)
  rig:addAnimation(walk)
  rig:playAnimation("walk", true)
  rig:stopAnimation()
end

--@api-stub: Skeleton:updateAnimation
-- Advances the playing animation by `dt` seconds and applies keyframes.
-- Call from lurek.process(dt) so timelines stay frame-rate independent.
do  -- Skeleton:updateAnimation
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  local clip = lurek.spine.newSkeletonAnimation("bob", 1.0)
  clip:addKeyframe(0, "y", 0, 0); clip:addKeyframe(0, "y", 1.0, 8)
  rig:addAnimation(clip); rig:playAnimation("bob", true)
  function lurek.process(dt) rig:updateAnimation(dt) end
end

--@api-stub: Skeleton:getAnimationTime
-- Returns the current playback time in seconds of the active animation.
-- Use to sync external systems (audio, VFX, gameplay) to the animation's current playhead.
do  -- Skeleton:getAnimationTime
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  local clip = lurek.spine.newSkeletonAnimation("attack", 0.4)
  rig:addAnimation(clip); rig:playAnimation("attack", false)
  function lurek.process(dt)
    rig:updateAnimation(dt)
    if rig:getAnimationTime() > 0.2 then lurek.log.debug("attack past hit-frame", "spine") end
  end
end

--@api-stub: Skeleton:addAnimation
-- Adds a SkeletonAnimation to this skeleton's library.
-- Build all clips at load time then refer to them by name via playAnimation; the animation is consumed by this call.
do  -- Skeleton:addAnimation
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  local idle = lurek.spine.newSkeletonAnimation("idle", 1.0)
  local walk = lurek.spine.newSkeletonAnimation("walk", 0.6)
  rig:addAnimation(idle); rig:addAnimation(walk)
end

--@api-stub: Skeleton:addSkin
-- Registers a new empty skin by name.
-- Create one skin per visual variant (e.g. "default", "armoured"), then populate via setSkinMapping.
do  -- Skeleton:addSkin
  local rig = lurek.spine.newSkeleton("npc")
  rig:addSkin("default"); rig:addSkin("armoured")
  rig:setSkinMapping("armoured", "chest", "plate_chest")
end

--@api-stub: Skeleton:setSkin
-- Activates the named skin for attachment lookups.
-- Returns true on success; switch skins when the player equips a new outfit or reaches a new chapter.
do  -- Skeleton:setSkin
  local rig = lurek.spine.newSkeleton("npc")
  rig:addSkin("default"); rig:addSkin("night")
  if not rig:setSkin("night") then
    lurek.log.warn("night skin missing, staying on default", "spine")
  end
end

--@api-stub: Skeleton:getSkin
-- Returns the name of the currently active skin, or nil.
-- Persist this value with the save game so the rig restores the same look on reload.
do  -- Skeleton:getSkin
  local rig = lurek.spine.newSkeleton("npc")
  rig:addSkin("default"); rig:setSkin("default")
  local current = rig:getSkin() or "default"
  lurek.log.info("active skin: " .. current, "spine")
end

-- ── SkeletonAnimation methods ──

--@api-stub: SkeletonAnimation:getDuration
-- Returns the total duration of the animation in seconds.
-- Use to schedule follow-up state transitions (e.g. queue idle once attack completes).
do  -- SkeletonAnimation:getDuration
  local clip = lurek.spine.newSkeletonAnimation("attack", 0.45)
  local timer = 0
  function lurek.process(dt)
    timer = timer + dt
    if timer >= clip:getDuration() then timer = 0 end
  end
end

--@api-stub: SkeletonAnimation:getEvents
-- Returns a list of event names that fall in the half-open interval `(from, to]`.
-- Poll with the playhead window each frame to fire footsteps, hit-frames, or sound cues exactly once.
do  -- SkeletonAnimation:getEvents
  local clip = lurek.spine.newSkeletonAnimation("walk", 0.8)
  clip:addEventKey(0.2, "footstep_left"); clip:addEventKey(0.6, "footstep_right")
  local prev = 0
  function lurek.process(dt)
    local now = prev + dt
    for _, ev in ipairs(clip:getEvents(prev, now)) do lurek.log.debug("event " .. ev.name, "spine") end
    prev = now % clip:getDuration()
  end
end

--@api-stub: SkeletonAnimation:getTimelineCount
-- Returns the number of bone timelines in this animation.
-- Use as a quick complexity check when loading content; very large clips may need profiling.
do  -- SkeletonAnimation:getTimelineCount
  local clip = lurek.spine.newSkeletonAnimation("idle", 1.0)
  clip:addKeyframe(0, "y", 0, 0); clip:addKeyframe(0, "y", 0.5, 4)
  clip:addKeyframe(1, "rotation", 0, 0); clip:addKeyframe(1, "rotation", 0.5, 0.1)
  lurek.log.info("idle clip uses " .. clip:getTimelineCount() .. " timelines", "spine")
end
