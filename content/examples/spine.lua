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
  local debug_tex = lurek.render.newImage(rig:drawToImage(128, 128))
  function lurek.draw() lurek.render.draw(debug_tex, 16, 16) end
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

--@api-stub: Skeleton:addBone
-- Adds a root bone to the skeleton at the given local position and angle.
-- Root bones have no parent; use addChildBone to build the hierarchy.
do  -- Skeleton:addBone
  local sk = lurek.spine.newSkeleton("hero")
  local bid = sk:addBone("root", { x = 0, y = 0 })
  lurek.log.info("root bone: " .. bid, "spine")
end

--@api-stub: Skeleton:addChildBone
-- Adds a child bone parented to an existing bone.
-- Position and angle are in the parent bone's local space.
do  -- Skeleton:addChildBone
  local sk = lurek.spine.newSkeleton("hero")
  local root = sk:addBone("root")
  local upper = sk:addChildBone("upper_arm", root, { x = 0, y = 20 })
  lurek.log.info("child bone: " .. upper, "spine")
end

--@api-stub: SkeletonAnimation:addEventKey
-- Adds a timed event key to the animation track at the given time offset.
-- Events fire in getEvents() so Lua can react to footsteps, sound cues, etc.
do  -- SkeletonAnimation:addEventKey
  local anim = lurek.spine.newSkeletonAnimation("walk", 1.0)
  anim:addKeyframe(0, "y", 0.0, 0)
  anim:addEventKey(0.5, "footstep")
  lurek.log.info("event key added at t=0.5", "spine")
end

--@api-stub: Skeleton:addIKConstraint
-- Adds an inverse-kinematics constraint between a chain of bones and a target bone.
-- chainLength specifies how many parent bones to include in the IK solve.
do  -- Skeleton:addIKConstraint
  local sk = lurek.spine.newSkeleton("hero")
  local root = sk:addBone("root")
  local lower = sk:addChildBone("lower_arm", root, { y = -30 })
  sk:addIKConstraint("arm_ik", {root, lower}, true)
  lurek.log.info("IK constraint added", "spine")
end

--@api-stub: SkeletonAnimation:addKeyframe
-- Adds a keyframe at the given time for a bone, specifying its local transform.
-- Keyframes are interpolated between by the animation playback system.
do  -- SkeletonAnimation:addKeyframe
  local anim = lurek.spine.newSkeletonAnimation("bob", 1.0)
  anim:addKeyframe(0, "y", 0.0,  0)
  anim:addKeyframe(0, "y", 0.5, 10)
  anim:addKeyframe(0, "y", 1.0,  0)
  lurek.log.info("keyframes: " .. anim:getTimelineCount(), "spine")
end

--@api-stub: Skeleton:addSlot
-- Adds a named slot to the skeleton, optionally parenting it to a bone.
-- Slots determine which sprite or attachment is drawn for each body part.
do  -- Skeleton:addSlot
  local sk = lurek.spine.newSkeleton("hero")
  local root = sk:addBone("root")
  local sid = sk:addSlot("body_slot", root, "body_sprite.png")
  lurek.log.info("slot: " .. sid, "spine")
end

--@api-stub: Skeleton:blendAnimation
-- Blends two animation tracks by weight for upper/lower-body splits.
-- weight=1 fully applies the secondary animation; 0 is equivalent to removing it.
do  -- Skeleton:blendAnimation
  local sk = lurek.spine.newSkeleton("hero")
  sk:addBone("root")
  local aim_clip = lurek.spine.newSkeletonAnimation("aim", 1.0)
  sk:blendAnimation(aim_clip, 0.0, 0.6)
  lurek.log.info("blend applied", "spine")
end

--@api-stub: Skeleton:playAnimation
-- Starts playback of a named animation on this skeleton.
-- loop=true repeats indefinitely; false plays once and freezes at the last frame.
do  -- Skeleton:playAnimation
  local sk = lurek.spine.newSkeleton("hero")
  sk:addBone("root")
  local idle = lurek.spine.newSkeletonAnimation("idle", 1.0)
  sk:addAnimation(idle)
  sk:playAnimation("idle", true)
  lurek.log.info("animation playing", "spine")
end

--@api-stub: Skeleton:setIKTarget
-- Sets the world-space target position for a named IK constraint.
-- Call each frame to drive the IK end-effector toward the desired position.
do  -- Skeleton:setIKTarget
  local sk = lurek.spine.newSkeleton("hero")
  local root = sk:addBone("root")
  local lower = sk:addChildBone("lower_arm", root, { y = -30 })
  sk:addIKConstraint("arm_ik", {root, lower}, true)
  sk:setIKTarget("arm_ik", 40, 10)
  lurek.log.info("IK target set", "spine")
end

--@api-stub: Skeleton:setSkinMapping
-- Maps a skin name to a set of slot replacements for costume swapping.
-- Calling setSkin("winter") swaps all slots registered under that mapping.
do  -- Skeleton:setSkinMapping
  local sk = lurek.spine.newSkeleton("hero")
  local root = sk:addBone("root")
  sk:addSlot("body_slot", root, "hero_default.png")
  sk:setSkinMapping("winter", "body_slot", "hero_winter.png")
  sk:setSkin("winter")
  lurek.log.info("skin mapping set", "spine")
end

-- =============================================================================
-- STUBS: 4 uncovered lurek.spine API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LSkeleton methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSkeleton:type ------------------------------------------------
--@api-stub: LSkeleton:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:type()  -- -> string
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:typeOf ----------------------------------------------
--@api-stub: LSkeleton:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:typeOf("hero")  -- -> boolean
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- -----------------------------------------------------------------------------
-- LSkeletonAnimation methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSkeletonAnimation:type ---------------------------------------
--@api-stub: LSkeletonAnimation:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeletonAnimation_stub:type()  -- -> string
-- (replace lSkeletonAnimation_stub with your real LSkeletonAnimation instance above)

-- ---- Stub: LSkeletonAnimation:typeOf -------------------------------------
--@api-stub: LSkeletonAnimation:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeletonAnimation_stub:typeOf("hero")  -- -> boolean
-- (replace lSkeletonAnimation_stub with your real LSkeletonAnimation instance above)

-- =============================================================================
-- STUBS: 28 uncovered lurek.spine API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LSkeleton methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSkeleton:addBone ---------------------------------------------
--@api-stub: LSkeleton:addBone
-- Adds a root bone with optional local transform and returns its index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:addBone("hero", [opts])  -- -> integer
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:addChildBone ----------------------------------------
--@api-stub: LSkeleton:addChildBone
-- Adds a child bone attached to a parent and returns its index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:addChildBone("hero", parent_idx, [opts])  -- -> integer
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:addSlot ---------------------------------------------
--@api-stub: LSkeleton:addSlot
-- Adds a slot bound to a bone and returns its index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:addSlot("hero", bone_idx, [attachment])  -- -> integer
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:findBone --------------------------------------------
--@api-stub: LSkeleton:findBone
-- Returns the index of the named bone, or nil if not found.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:findBone("hero")  -- -> integer?
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:findSlot --------------------------------------------
--@api-stub: LSkeleton:findSlot
-- Returns the index of the named slot, or nil if not found.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:findSlot("hero")  -- -> integer?
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:updateWorldTransforms -------------------------------
--@api-stub: LSkeleton:updateWorldTransforms
-- Propagates local transforms down the bone hierarchy to compute world positions.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:updateWorldTransforms()
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:getBoneWorld ----------------------------------------
--@api-stub: LSkeleton:getBoneWorld
-- Returns the world-space transform of a bone as a table, or nil if out of range.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:getBoneWorld(1)  -- -> table?
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:setPosition -----------------------------------------
--@api-stub: LSkeleton:setPosition
-- Sets the root bone position and propagates world transforms.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:setPosition(0.0, 0.0)
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:boneCount -------------------------------------------
--@api-stub: LSkeleton:boneCount
-- Returns the total number of bones.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:boneCount()  -- -> integer
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:slotCount -------------------------------------------
--@api-stub: LSkeleton:slotCount
-- Returns the total number of slots.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:slotCount()  -- -> integer
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:drawToImage -----------------------------------------
--@api-stub: LSkeleton:drawToImage
-- Renders the skeleton as a stick-figure debug view into a new ImageData.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:drawToImage(64.0, 64.0)  -- -> ImageData
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:playAnimation ---------------------------------------
--@api-stub: LSkeleton:playAnimation
-- Starts playback of the named skeletal animation clip.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:playAnimation("hero", [looping])  -- -> boolean
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:stopAnimation ---------------------------------------
--@api-stub: LSkeleton:stopAnimation
-- Stops the current skeletal animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:stopAnimation()
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:updateAnimation -------------------------------------
--@api-stub: LSkeleton:updateAnimation
-- Advances the playing animation by `dt` seconds and applies keyframes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:updateAnimation(0.016)
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:getAnimationTime ------------------------------------
--@api-stub: LSkeleton:getAnimationTime
-- Returns the current playback time in seconds of the active animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:getAnimationTime()  -- -> number
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:addAnimation ----------------------------------------
--@api-stub: LSkeleton:addAnimation
-- Adds a SkeletonAnimation to this skeleton's library.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:addAnimation(anim_ud)
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:addIKConstraint -------------------------------------
--@api-stub: LSkeleton:addIKConstraint
-- Adds a two-bone IK constraint and returns its index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:addIKConstraint("hero", chain_tbl, [bend_positive])  -- -> integer
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:setIKTarget -----------------------------------------
--@api-stub: LSkeleton:setIKTarget
-- Sets the world-space target position for the named IK constraint.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:setIKTarget("hero", 0.0, 0.0)  -- -> boolean
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:addSkin ---------------------------------------------
--@api-stub: LSkeleton:addSkin
-- Registers a new empty skin by name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:addSkin("hero")
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:setSkin ---------------------------------------------
--@api-stub: LSkeleton:setSkin
-- Activates the named skin for attachment lookups.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:setSkin("hero")  -- -> boolean
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:getSkin ---------------------------------------------
--@api-stub: LSkeleton:getSkin
-- Returns the name of the currently active skin, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:getSkin()  -- -> string?
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:setSkinMapping --------------------------------------
--@api-stub: LSkeleton:setSkinMapping
-- Registers a slot-to-attachment mapping in the named skin.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:setSkinMapping(skin, "slot1", attachment)
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- ---- Stub: LSkeleton:blendAnimation --------------------------------------
--@api-stub: LSkeleton:blendAnimation
-- Evaluates `anim` at `time` and blends the result into this skeleton
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeleton_stub:blendAnimation(anim_ud, time, [blend_weight])
-- (replace lSkeleton_stub with your real LSkeleton instance above)

-- -----------------------------------------------------------------------------
-- LSkeletonAnimation methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSkeletonAnimation:addKeyframe --------------------------------
--@api-stub: LSkeletonAnimation:addKeyframe
-- Adds a keyframe to the bone timeline for the given property and bone index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeletonAnimation_stub:addKeyframe()
-- (replace lSkeletonAnimation_stub with your real LSkeletonAnimation instance above)

-- ---- Stub: LSkeletonAnimation:getDuration --------------------------------
--@api-stub: LSkeletonAnimation:getDuration
-- Returns the total duration of the animation in seconds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeletonAnimation_stub:getDuration()  -- -> number
-- (replace lSkeletonAnimation_stub with your real LSkeletonAnimation instance above)

-- ---- Stub: LSkeletonAnimation:addEventKey --------------------------------
--@api-stub: LSkeletonAnimation:addEventKey
-- Adds a named event marker at `time` seconds in the animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeletonAnimation_stub:addEventKey(time, "hero", [value])
-- (replace lSkeletonAnimation_stub with your real LSkeletonAnimation instance above)

-- ---- Stub: LSkeletonAnimation:getEvents ----------------------------------
--@api-stub: LSkeletonAnimation:getEvents
-- Returns a list of event names that fall in the half-open interval `(from, to]`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeletonAnimation_stub:getEvents(from, to)
-- (replace lSkeletonAnimation_stub with your real LSkeletonAnimation instance above)

-- ---- Stub: LSkeletonAnimation:getTimelineCount ---------------------------
--@api-stub: LSkeletonAnimation:getTimelineCount
-- Returns the number of bone timelines in this animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSkeletonAnimation_stub:getTimelineCount()  -- -> integer
-- (replace lSkeletonAnimation_stub with your real LSkeletonAnimation instance above)
