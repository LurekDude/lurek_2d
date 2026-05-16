-- content/examples/spine.lua
-- lurek.spine API examples.
-- Run: cargo run -- content/examples/spine.lua

--@api-stub: lurek.spine.newSkeleton
-- Creates a new empty skeleton with the given name
do
  local hero = lurek.spine.newSkeleton("hero")
  local root = hero:addBone("root", { x = 320, y = 240 })
  hero:addChildBone("torso", root, { y = -40 })
  lurek.log.info("hero rig built with " .. hero:boneCount() .. " bones", "spine")
end

--@api-stub: lurek.spine.newSkeletonAnimation
-- Creates a new empty animation with the given name and duration
do
  local idle = lurek.spine.newSkeletonAnimation("idle", 1.5)
  idle:addKeyframe(0, "y", 0.0,  0, "ease_in_out")
  idle:addKeyframe(0, "y", 0.75, 4, "ease_in_out")
  idle:addKeyframe(0, "y", 1.5,  0, "ease_in_out")
end

-- Skeleton methods

--@api-stub: Skeleton:findBone
-- Finds and returns the bone in this skeleton by name or id.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  rig:addChildBone("head", 0)
  local head_idx = rig:findBone("head")
  if head_idx then lurek.log.debug("head bone at index " .. head_idx, "spine") end
end

--@api-stub: Skeleton:findSlot
-- Finds and returns the slot in this skeleton by name or id.
do
  local rig = lurek.spine.newSkeleton("npc")
  local b = rig:addBone("torso")
  rig:addSlot("chest", b, "shirt_default")
  local slot_idx = rig:findSlot("chest")
  if slot_idx then lurek.log.debug("chest slot at " .. slot_idx, "spine") end
end

--@api-stub: Skeleton:updateWorldTransforms
-- Advances world transforms this skeleton by the given delta time.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root", { x = 100, y = 100 })
  rig:addChildBone("arm", 0, { x = 20 })
  rig:setPosition(200, 150)
  rig:updateWorldTransforms()
end

--@api-stub: Skeleton:getBoneWorld
-- Returns the bone world of this skeleton.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("muzzle", { x = 50, y = 0 })
  rig:updateWorldTransforms()
  local t = rig:getBoneWorld(0)
  if t then lurek.log.info("muzzle world x=" .. t.x .. " y=" .. t.y, "spine") end
end

--@api-stub: Skeleton:setPosition
-- Sets the position of this skeleton.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  local player = { x = 0, y = 0 }
  function lurek.process(dt)
    player.x = player.x + 60 * dt
    rig:setPosition(player.x, player.y)
  end
end

--@api-stub: Skeleton:boneCount
-- Performs the bone count operation on this skeleton.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root"); rig:addChildBone("torso", 0); rig:addChildBone("head", 1)
  if rig:boneCount() < 3 then
    lurek.log.warn("rig is missing bones: " .. rig:boneCount(), "spine")
  end
end

--@api-stub: Skeleton:slotCount
-- Performs the slot count operation on this skeleton.
do
  local rig = lurek.spine.newSkeleton("npc")
  local b = rig:addBone("torso")
  rig:addSlot("chest", b); rig:addSlot("belt", b)
  lurek.log.info("rig exposes " .. rig:slotCount() .. " attachment slots", "spine")
end

--@api-stub: Skeleton:drawToImage
-- Draws or renders this skeleton to the current render target.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root", { x = 64, y = 64 })
  rig:addChildBone("arm", 0, { x = 32 })
  rig:updateWorldTransforms()
  local debug_tex = lurek.render.newImage(rig:drawToImage(128, 128))
  function lurek.draw() lurek.render.draw(debug_tex, 16, 16) end
end

--@api-stub: Skeleton:stopAnimation
-- Stops the current operation or playback on this skeleton.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  local walk = lurek.spine.newSkeletonAnimation("walk", 0.6)
  rig:addAnimation(walk)
  rig:playAnimation("walk", true)
  rig:stopAnimation()
end

--@api-stub: Skeleton:updateAnimation
-- Advances animation this skeleton by the given delta time.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  local clip = lurek.spine.newSkeletonAnimation("bob", 1.0)
  clip:addKeyframe(0, "y", 0, 0); clip:addKeyframe(0, "y", 1.0, 8)
  rig:addAnimation(clip); rig:playAnimation("bob", true)
  function lurek.process(dt) rig:updateAnimation(dt) end
end

--@api-stub: Skeleton:getAnimationTime
-- Returns the animation time of this skeleton.
do
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
-- Adds a animation to this skeleton.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addBone("root")
  local idle = lurek.spine.newSkeletonAnimation("idle", 1.0)
  local walk = lurek.spine.newSkeletonAnimation("walk", 0.6)
  rig:addAnimation(idle); rig:addAnimation(walk)
end

--@api-stub: Skeleton:addSkin
-- Adds a skin to this skeleton.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addSkin("default"); rig:addSkin("armoured")
  rig:setSkinMapping("armoured", "chest", "plate_chest")
end

--@api-stub: Skeleton:setSkin
-- Sets the skin of this skeleton.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addSkin("default"); rig:addSkin("night")
  if not rig:setSkin("night") then
    lurek.log.warn("night skin missing, staying on default", "spine")
  end
end

--@api-stub: Skeleton:getSkin
-- Returns the skin of this skeleton.
do
  local rig = lurek.spine.newSkeleton("npc")
  rig:addSkin("default"); rig:setSkin("default")
  local current = rig:getSkin() or "default"
  lurek.log.info("active skin: " .. current, "spine")
end

-- SkeletonAnimation methods

--@api-stub: SkeletonAnimation:getDuration
-- Returns the duration of this skeleton animation.
do
  local clip = lurek.spine.newSkeletonAnimation("attack", 0.45)
  local timer = 0
  function lurek.process(dt)
    timer = timer + dt
    if timer >= clip:getDuration() then timer = 0 end
  end
end

--@api-stub: SkeletonAnimation:getEvents
-- Returns the events of this skeleton animation.
do
  local clip = lurek.spine.newSkeletonAnimation("walk", 0.8)
  clip:addEventKey(0.2, "footstep_left"); clip:addEventKey(0.6, "footstep_right")
  local prev = 0
  function lurek.process(dt)
    local now = prev + dt
    for _, ev in ipairs(clip:getEvents(prev, now) or {}) do lurek.log.debug("event " .. ev.name, "spine") end
    prev = now % clip:getDuration()
  end
end

--@api-stub: SkeletonAnimation:getTimelineCount
-- Returns the number of timeline items in this skeleton animation.
do
  local clip = lurek.spine.newSkeletonAnimation("idle", 1.0)
  clip:addKeyframe(0, "y", 0, 0); clip:addKeyframe(0, "y", 0.5, 4)
  clip:addKeyframe(1, "rotation", 0, 0); clip:addKeyframe(1, "rotation", 0.5, 0.1)
  lurek.log.info("idle clip uses " .. clip:getTimelineCount() .. " timelines", "spine")
end

--@api-stub: Skeleton:addBone
-- Adds a bone to this skeleton.
do
  local sk = lurek.spine.newSkeleton("hero")
  local bid = sk:addBone("root", { x = 0, y = 0 })
  lurek.log.info("root bone: " .. bid, "spine")
end

--@api-stub: Skeleton:addChildBone
-- Adds a child bone to this skeleton.
do
  local sk = lurek.spine.newSkeleton("hero")
  local root = sk:addBone("root")
  local upper = sk:addChildBone("upper_arm", root, { x = 0, y = 20 })
  lurek.log.info("child bone: " .. upper, "spine")
end

--@api-stub: SkeletonAnimation:addEventKey
-- Adds a event key to this skeleton animation.
do
  local anim = lurek.spine.newSkeletonAnimation("walk", 1.0)
  anim:addKeyframe(0, "y", 0.0, 0)
  anim:addEventKey(0.5, "footstep")
  lurek.log.info("event key added at t=0.5", "spine")
end

--@api-stub: Skeleton:addIKConstraint
-- Adds a ik constraint to this skeleton.
do
  local sk = lurek.spine.newSkeleton("hero")
  local root = sk:addBone("root")
  local lower = sk:addChildBone("lower_arm", root, { y = -30 })
  sk:addIKConstraint("arm_ik", {root, lower}, true)
  lurek.log.info("IK constraint added", "spine")
end

--@api-stub: SkeletonAnimation:addKeyframe
-- Adds a keyframe to this skeleton animation.
do
  local anim = lurek.spine.newSkeletonAnimation("bob", 1.0)
  anim:addKeyframe(0, "y", 0.0,  0)
  anim:addKeyframe(0, "y", 0.5, 10)
  anim:addKeyframe(0, "y", 1.0,  0)
  lurek.log.info("keyframes: " .. anim:getTimelineCount(), "spine")
end

--@api-stub: Skeleton:addSlot
-- Adds a slot to this skeleton.
do
  local sk = lurek.spine.newSkeleton("hero")
  local root = sk:addBone("root")
  local sid = sk:addSlot("body_slot", root, "body_sprite.png")
  lurek.log.info("slot: " .. sid, "spine")
end

--@api-stub: Skeleton:blendAnimation
-- Performs the blend animation operation on this skeleton.
do
  local sk = lurek.spine.newSkeleton("hero")
  sk:addBone("root")
  local aim_clip = lurek.spine.newSkeletonAnimation("aim", 1.0)
  sk:blendAnimation(aim_clip, 0.0, 0.6)
  lurek.log.info("blend applied", "spine")
end

--@api-stub: LSkeletonAnimation:poseAt
-- Samples all timelines at a given time and returns the computed pose as an array of bone-property-value entries
do
  local clip = lurek.spine.newSkeletonAnimation("probe", 1.0)
  clip:addKeyframe(0, "x", 0.0, 0.0, "linear")
  clip:addKeyframe(0, "x", 1.0, 10.0, "linear")
  local pose = clip:poseAt(0.5)
  lurek.log.debug("poseAt entries=" .. #pose, "spine")
end

--@api-stub: LSkeletonAnimation:reverse
-- Creates a new animation that plays this animation's keyframes in reverse order
do
  local clip = lurek.spine.newSkeletonAnimation("walk", 1.0)
  clip:addKeyframe(0, "y", 0.0, 0.0, "linear")
  clip:addKeyframe(0, "y", 1.0, 4.0, "linear")
  local rev = clip:reverse()
  lurek.log.debug("reversed clip duration=" .. rev:getDuration(), "spine")
end

--@api-stub: lurek.spine.animationFromJson
-- Parses a JSON string into a SkeletonAnimation
do
  local json = [[
    {
      "name":"json_clip",
      "duration":1.0,
      "timelines":[
        {"bone_idx":0,"property":"rotation","keys":[
          {"time":0.0,"value":0.0,"easing":"linear"},
          {"time":1.0,"value":1.57,"easing":"ease_out"}
        ]}
      ],
      "events":[{"time":0.5,"name":"hit","value":1.0}]
    }
  ]]
  local clip = lurek.spine.animationFromJson(json)
  if clip ~= nil then
    lurek.log.info("animationFromJson ok", "spine")
  end
end

--@api-stub: Skeleton:playAnimation
-- Starts playback of animation on this skeleton.
do
  local sk = lurek.spine.newSkeleton("hero")
  sk:addBone("root")
  local idle = lurek.spine.newSkeletonAnimation("idle", 1.0)
  sk:addAnimation(idle)
  sk:playAnimation("idle", true)
  lurek.log.info("animation playing", "spine")
end

--@api-stub: Skeleton:setIKTarget
-- Sets the ik target of this skeleton.
do
  local sk = lurek.spine.newSkeleton("hero")
  local root = sk:addBone("root")
  local lower = sk:addChildBone("lower_arm", root, { y = -30 })
  sk:addIKConstraint("arm_ik", {root, lower}, true)
  sk:setIKTarget("arm_ik", 40, 10)
  lurek.log.info("IK target set", "spine")
end

--@api-stub: Skeleton:setSkinMapping
-- Sets the skin mapping of this skeleton.
do
  local sk = lurek.spine.newSkeleton("hero")
  local root = sk:addBone("root")
  sk:addSlot("body_slot", root, "hero_default.png")
  sk:setSkinMapping("winter", "body_slot", "hero_winter.png")
  sk:setSkin("winter")
  lurek.log.info("skin mapping set", "spine")
end

-- -----------------------------------------------------------------------------
-- LSkeleton methods
-- -----------------------------------------------------------------------------

--@api-stub: LSkeleton:type
-- Returns the type name of this userdata object
do
  local skeleton_obj = lurek.spine.newSkeleton("test")
  local t = skeleton_obj:type()
  lurek.log.info("LSkeleton:type = " .. t, "spine")
end
--@api-stub: LSkeleton:typeOf
-- Checks whether this object is of the given type name
do
  local skeleton_obj = lurek.spine.newSkeleton("test")
  lurek.log.info("is LSkeleton: " .. tostring(skeleton_obj:typeOf("LSkeleton")), "spine")
  lurek.log.info("is wrong: " .. tostring(skeleton_obj:typeOf("Unknown")), "spine")
end
--@api-stub: LSkeletonAnimation:type
-- Returns the type name of this userdata object
do
  local ok ---@type boolean
  local skeleton_animation_obj ---@type LSkeletonAnimation?
  ok, skeleton_animation_obj = pcall(lurek.spine.newSkeletonAnimation, "assets/hero.skel", 1.0)
  if not ok then skeleton_animation_obj = nil end
  local t = skeleton_animation_obj and skeleton_animation_obj:type() or "LSkeletonAnimation"
  lurek.log.info("LSkeletonAnimation:type = " .. t, "spine")
end
--@api-stub: LSkeletonAnimation:typeOf
-- Checks whether this object is of the given type name
do
  local ok2 ---@type boolean
  local skeleton_animation_obj2 ---@type LSkeletonAnimation?
  ok2, skeleton_animation_obj2 = pcall(lurek.spine.newSkeletonAnimation, "assets/hero.skel", 1.0)
  if not ok2 then skeleton_animation_obj2 = nil end
  lurek.log.info("is LSkeletonAnimation: " .. tostring(skeleton_animation_obj2 and skeleton_animation_obj2:typeOf("LSkeletonAnimation") or false), "spine")
  lurek.log.info("is wrong: " .. tostring(skeleton_animation_obj2 and skeleton_animation_obj2:typeOf("Unknown") or false), "spine")
end


