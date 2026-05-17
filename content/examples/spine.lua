-- content/examples/spine.lua
-- Spine-like skeletal animation: bones, slots, skins, IK, keyframes, events, and blending.
-- Run: cargo run -- content/examples/spine.lua

-- =============================================================================
-- Module constructors
-- =============================================================================

--@api-stub: lurek.spine.newSkeleton
-- Creates a new empty skeleton with the given name
do
  -- A skeleton is the top-level rig object. You name it to identify
  -- which character or prop it belongs to (useful for debug logs).
  -- After creation, add bones to build the hierarchy.
  local hero = lurek.spine.newSkeleton("hero")

  -- Build a simple humanoid upper-body rig:
  -- root (hips) → torso → head, and torso → shoulder → hand
  local root  = hero:addBone("root", { x = 320, y = 400 })
  local torso = hero:addChildBone("torso", root, { y = -60 })
  hero:addChildBone("head", torso, { y = -30 })
  local shoulder = hero:addChildBone("shoulder", torso, { x = 20, y = -10 })
  hero:addChildBone("hand", shoulder, { x = 30 })

  lurek.log.info("hero rig: " .. hero:boneCount() .. " bones", "spine")
end

--@api-stub: lurek.spine.newSkeletonAnimation
-- Creates a new empty animation with the given name and duration
do
  -- Animations are independent objects. You define them with a name
  -- (used by playAnimation) and a total duration in seconds.
  -- Then add keyframes for each bone property you want to animate.
  local idle = lurek.spine.newSkeletonAnimation("idle", 1.5)

  -- Animate bone 0 (root) Y with a gentle breathing bob:
  -- start at 0, rise 4px at the midpoint, return to 0.
  idle:addKeyframe(0, "y", 0.0,  0, "ease_in_out")
  idle:addKeyframe(0, "y", 0.75, 4, "ease_in_out")
  idle:addKeyframe(0, "y", 1.5,  0, "ease_in_out")

  lurek.log.info("idle anim: " .. idle:getDuration() .. "s, " .. idle:getTimelineCount() .. " timeline(s)", "spine")
end

--@api-stub: lurek.spine.animationFromJson
-- Parses a JSON string into a SkeletonAnimation
do
  -- For data-driven workflows, animations can be loaded from JSON.
  -- This is useful when exporting from tools or storing clips in files.
  -- The format matches the Spine JSON animation structure.
  local json = [[
    {
      "name": "spin",
      "duration": 1.0,
      "timelines": [
        {
          "bone_idx": 0,
          "property": "rotation",
          "keys": [
            { "time": 0.0, "value": 0.0, "easing": "linear" },
            { "time": 1.0, "value": 6.28, "easing": "ease_out" }
          ]
        }
      ],
      "events": [
        { "time": 0.5, "name": "halfway_spin", "value": 1.0 }
      ]
    }
  ]]

  local clip = lurek.spine.animationFromJson(json)
  if clip then
    -- Successfully parsed; can now register with a skeleton via addAnimation.
    lurek.log.info("parsed JSON clip: duration=" .. clip:getDuration(), "spine")
  else
    lurek.log.warn("JSON parse failed — check format", "spine")
  end
end

-- =============================================================================
-- Skeleton: building the bone hierarchy
-- =============================================================================

--@api-stub: LSkeleton:addBone
-- Adds a root-level bone to this skeleton with optional transform properties
do
  -- addBone creates a root-level bone (no parent). Use it for the rig
  -- origin or for independent attachment points like particle emitters.
  -- The opts table sets the local transform: x, y, rotation, scale_x, scale_y.
  local sk = lurek.spine.newSkeleton("turret")

  -- Turret base sits at world center with no rotation
  local base = sk:addBone("base", { x = 400, y = 300 })

  -- A second root bone for an independent muzzle-flash emitter
  local flash = sk:addBone("muzzle_flash", { x = 450, y = 280, rotation = 0.0 })

  lurek.log.info("base=" .. base .. " flash=" .. flash, "spine")
end

--@api-stub: LSkeleton:addChildBone
-- Adds a child bone that inherits its parent's world transform
do
  -- Child bones form the skeleton hierarchy. Their local x/y/rotation
  -- are offsets relative to the parent. When the parent moves, children follow.
  local sk = lurek.spine.newSkeleton("arm_rig")
  local shoulder = sk:addBone("shoulder", { x = 200, y = 200 })

  -- Upper arm extends 40px down from shoulder
  local upper = sk:addChildBone("upper_arm", shoulder, { y = 40 })

  -- Forearm extends 35px further; rotation will rotate around the elbow
  local forearm = sk:addChildBone("forearm", upper, { y = 35 })

  -- Hand at the end of the chain
  sk:addChildBone("hand", forearm, { y = 25 })

  lurek.log.info("arm chain: " .. sk:boneCount() .. " bones", "spine")
end

--@api-stub: LSkeleton:addSlot
-- Adds an attachment slot to a specific bone
do
  -- Slots are named attachment points on bones. Each slot can hold one
  -- active attachment (sprite name). Skins remap which attachment shows.
  local sk = lurek.spine.newSkeleton("knight")
  local torso = sk:addBone("torso", { x = 320, y = 300 })
  local hand  = sk:addChildBone("hand", torso, { x = 30, y = 10 })

  -- Chest slot with a default armor sprite
  local chest_slot = sk:addSlot("chest", torso, "chainmail.png")

  -- Weapon slot on the hand bone — no default attachment (empty hand)
  local weapon_slot = sk:addSlot("weapon", hand)

  lurek.log.info("slots: chest=" .. chest_slot .. " weapon=" .. weapon_slot, "spine")
end

-- =============================================================================
-- Skeleton: querying bones and slots
-- =============================================================================

--@api-stub: LSkeleton:findBone
-- Searches for a bone by name and returns its zero-based index, or nil
do
  -- Use findBone to look up bone indices by name at runtime.
  -- This avoids hardcoding indices that may change as you edit the rig.
  local rig = lurek.spine.newSkeleton("enemy")
  rig:addBone("root")
  rig:addChildBone("head", 0, { y = -50 })
  rig:addChildBone("weapon_mount", 0, { x = 25 })

  local head_idx = rig:findBone("head")
  local mount_idx = rig:findBone("weapon_mount")
  local missing = rig:findBone("nonexistent")

  if head_idx then lurek.log.info("head bone index: " .. head_idx, "spine") end
  if not missing then lurek.log.info("missing bone returns nil as expected", "spine") end
end

--@api-stub: LSkeleton:findSlot
-- Searches for a slot by name and returns its zero-based index, or nil
do
  -- Like findBone, but for slots. Useful for runtime attachment swaps
  -- when you know the slot name but not the index.
  local rig = lurek.spine.newSkeleton("player")
  local torso = rig:addBone("torso")
  rig:addSlot("armor_slot", torso, "leather.png")
  rig:addSlot("cape_slot", torso)

  local armor_idx = rig:findSlot("armor_slot")
  if armor_idx then
    lurek.log.info("armor slot found at index " .. armor_idx, "spine")
  end
end

--@api-stub: LSkeleton:boneCount
-- Returns the total number of bones in this skeleton
do
  -- Useful for validation: assert your rig has the expected bone count
  -- after building it, or log it for debugging during development.
  local rig = lurek.spine.newSkeleton("vehicle")
  rig:addBone("chassis")
  rig:addChildBone("wheel_fl", 0, { x = -20, y = 10 })
  rig:addChildBone("wheel_fr", 0, { x =  20, y = 10 })
  rig:addChildBone("wheel_rl", 0, { x = -20, y = -10 })
  rig:addChildBone("wheel_rr", 0, { x =  20, y = -10 })

  assert(rig:boneCount() == 5, "vehicle rig should have 5 bones")
  lurek.log.info("vehicle bones: " .. rig:boneCount(), "spine")
end

--@api-stub: LSkeleton:slotCount
-- Returns the total number of slots in this skeleton
do
  -- Track how many visual attachment points the rig exposes.
  -- Each slot can display a different sprite depending on the active skin.
  local rig = lurek.spine.newSkeleton("mech")
  local body = rig:addBone("body")
  rig:addSlot("hull", body, "hull_base.png")
  rig:addSlot("left_arm", body, "arm_default.png")
  rig:addSlot("right_arm", body, "arm_default.png")
  rig:addSlot("cockpit", body, "cockpit_glass.png")

  lurek.log.info("mech has " .. rig:slotCount() .. " attachment slots", "spine")
end

-- =============================================================================
-- Skeleton: world transforms and positioning
-- =============================================================================

--@api-stub: LSkeleton:setPosition
-- Sets the root bone world position, shifting the entire skeleton
do
  -- setPosition moves the skeleton's root to the given world coordinates.
  -- Call this every frame to follow your game entity's position.
  local rig = lurek.spine.newSkeleton("player")
  rig:addBone("root")
  rig:addChildBone("head", 0, { y = -40 })

  -- Simulate a player walking right at 120 px/s
  local px = 100
  function lurek.process(dt)
    px = px + 120 * dt
    rig:setPosition(px, 300)
    -- After moving, recompute transforms before drawing
    rig:updateWorldTransforms()
  end
end

--@api-stub: LSkeleton:updateWorldTransforms
-- Recomputes world transforms for all bones in hierarchy order
do
  -- You must call updateWorldTransforms after any change to bone
  -- positions, rotations, IK targets, or skeleton position.
  -- It propagates parent transforms down the tree.
  local rig = lurek.spine.newSkeleton("crane")
  local base = rig:addBone("base", { x = 200, y = 400 })
  local arm  = rig:addChildBone("arm", base, { y = -80, rotation = 0.3 })
  rig:addChildBone("hook", arm, { y = -60 })

  -- Move the whole crane and resolve the hierarchy
  rig:setPosition(300, 400)
  rig:updateWorldTransforms()

  -- Now getBoneWorld will return correct world positions
  local hook = rig:getBoneWorld(2)
  if hook then
    lurek.log.info("hook world pos: " .. hook.x .. ", " .. hook.y, "spine")
  end
end

--@api-stub: LSkeleton:getBoneWorld
-- Returns the world-space transform of a bone after hierarchy resolution
do
  -- After updateWorldTransforms, getBoneWorld gives you the final
  -- position, rotation, and scale of any bone in world space.
  -- Common use: spawn projectiles at a weapon bone's world position.
  local rig = lurek.spine.newSkeleton("shooter")
  local body   = rig:addBone("body", { x = 320, y = 240 })
  local arm    = rig:addChildBone("arm", body, { x = 20, y = -10, rotation = -0.2 })
  local muzzle = rig:addChildBone("muzzle", arm, { x = 40 })

  rig:updateWorldTransforms()

  local muzzle_world = rig:getBoneWorld(2)
  if muzzle_world then
    -- Use muzzle_world.x, muzzle_world.y to spawn a bullet
    lurek.log.info(string.format(
      "muzzle at (%.1f, %.1f) rot=%.2f",
      muzzle_world.x, muzzle_world.y, muzzle_world.rotation
    ), "spine")
  end
end

-- =============================================================================
-- Skeleton: animation playback
-- =============================================================================

--@api-stub: LSkeleton:addAnimation
-- Registers a SkeletonAnimation so it can be played by name
do
  -- You must register animations with addAnimation before calling
  -- playAnimation. This transfers ownership of the animation to the skeleton.
  -- After addAnimation, the original variable should not be reused.
  local rig = lurek.spine.newSkeleton("guard")
  rig:addBone("root")

  local idle = lurek.spine.newSkeletonAnimation("idle", 2.0)
  idle:addKeyframe(0, "y", 0.0, 0, "ease_in_out")
  idle:addKeyframe(0, "y", 1.0, 3, "ease_in_out")
  idle:addKeyframe(0, "y", 2.0, 0, "ease_in_out")

  local alert = lurek.spine.newSkeletonAnimation("alert", 0.3)
  alert:addKeyframe(0, "y", 0.0, 0, "linear")
  alert:addKeyframe(0, "y", 0.15, -5, "ease_out")
  alert:addKeyframe(0, "y", 0.3, 0, "linear")

  -- Register both; now "idle" and "alert" are playable by name
  rig:addAnimation(idle)
  rig:addAnimation(alert)
  lurek.log.info("guard has idle + alert animations registered", "spine")
end

--@api-stub: LSkeleton:playAnimation
-- Starts playing a named animation, optionally looping
do
  -- playAnimation starts a registered clip. Pass true for looping
  -- (idle, walk) or false for one-shot (attack, death).
  -- Returns false if the animation name is not registered.
  local rig = lurek.spine.newSkeleton("hero")
  rig:addBone("root")

  local walk = lurek.spine.newSkeletonAnimation("walk", 0.6)
  walk:addKeyframe(0, "y", 0.0, 0); walk:addKeyframe(0, "y", 0.3, -3)
  walk:addKeyframe(0, "y", 0.6, 0)
  rig:addAnimation(walk)

  -- Start the walk cycle looping
  local ok = rig:playAnimation("walk", true)
  if not ok then
    lurek.log.warn("walk animation not found!", "spine")
  end

  -- Trying a non-existent animation returns false safely
  local bad = rig:playAnimation("fly", true)
  lurek.log.info("play 'fly' result: " .. tostring(bad), "spine")
end

--@api-stub: LSkeleton:updateAnimation
-- Advances the current animation by delta time, applying bone transforms
do
  -- Call updateAnimation every frame in lurek.process to advance playback.
  -- It samples keyframes at the current time and applies values to bones.
  local rig = lurek.spine.newSkeleton("bobber")
  rig:addBone("root", { x = 320, y = 240 })

  local bob = lurek.spine.newSkeletonAnimation("bob", 1.0)
  bob:addKeyframe(0, "y", 0.0, 0, "ease_in_out")
  bob:addKeyframe(0, "y", 0.5, 8, "ease_in_out")
  bob:addKeyframe(0, "y", 1.0, 0, "ease_in_out")

  rig:addAnimation(bob)
  rig:playAnimation("bob", true)

  function lurek.process(dt)
    -- Advance time and apply bone changes each frame
    rig:updateAnimation(dt)
    rig:updateWorldTransforms()
  end
end

--@api-stub: LSkeleton:getAnimationTime
-- Returns the current playback time of the active animation in seconds
do
  -- Use getAnimationTime to trigger gameplay events at specific frames.
  -- Example: spawn a hitbox when the attack animation reaches frame 0.2s.
  local rig = lurek.spine.newSkeleton("warrior")
  rig:addBone("root")

  local slash = lurek.spine.newSkeletonAnimation("slash", 0.5)
  slash:addKeyframe(0, "rotation", 0.0, 0.0, "linear")
  slash:addKeyframe(0, "rotation", 0.25, -1.2, "ease_out")
  slash:addKeyframe(0, "rotation", 0.5, 0.0, "ease_in")
  rig:addAnimation(slash)
  rig:playAnimation("slash", false)

  local hit_spawned = false
  function lurek.process(dt)
    rig:updateAnimation(dt)
    -- Spawn hitbox at the swing's peak (0.2s mark)
    if not hit_spawned and rig:getAnimationTime() >= 0.2 then
      hit_spawned = true
      lurek.log.info("SLASH HIT FRAME — spawn damage hitbox", "spine")
    end
  end
end

--@api-stub: LSkeleton:stopAnimation
-- Stops the currently playing animation and resets playback state
do
  -- stopAnimation halts playback immediately. The skeleton keeps its
  -- current pose (bones stay where they were when stopped).
  -- Use this when interrupting animations (e.g. stun, death).
  local rig = lurek.spine.newSkeleton("enemy")
  rig:addBone("root")

  local patrol = lurek.spine.newSkeletonAnimation("patrol", 2.0)
  patrol:addKeyframe(0, "x", 0.0, 0); patrol:addKeyframe(0, "x", 2.0, 100)
  rig:addAnimation(patrol)
  rig:playAnimation("patrol", true)

  -- Simulate: enemy gets stunned, stop the patrol animation
  local stunned = true
  if stunned then
    rig:stopAnimation()
    lurek.log.info("patrol stopped — enemy is stunned", "spine")
  end
end

--@api-stub: LSkeleton:blendAnimation
-- Blends an animation pose onto the skeleton with a weight factor
do
  -- blendAnimation samples an animation at a given time and mixes it
  -- onto the current bone state. Weight 0.0 = no effect, 1.0 = full override.
  -- Use this for layered animations: e.g. aim-layer on top of walk.
  local rig = lurek.spine.newSkeleton("soldier")
  local body = rig:addBone("body", { x = 320, y = 300 })
  rig:addChildBone("arm", body, { x = 20, rotation = 0.0 })

  -- Base walk animation (registered and playing)
  local walk = lurek.spine.newSkeletonAnimation("walk", 0.8)
  walk:addKeyframe(0, "y", 0.0, 0); walk:addKeyframe(0, "y", 0.4, -4)
  walk:addKeyframe(0, "y", 0.8, 0)
  rig:addAnimation(walk)
  rig:playAnimation("walk", true)

  -- Aim-up layer: rotates the arm bone upward (NOT registered — used for blending)
  local aim_up = lurek.spine.newSkeletonAnimation("aim_up", 1.0)
  aim_up:addKeyframe(1, "rotation", 0.0, -0.8, "linear")
  aim_up:addKeyframe(1, "rotation", 1.0, -0.8, "linear")

  -- Blend 60% aim on top of whatever walk is doing
  rig:updateAnimation(0.0)
  rig:blendAnimation(aim_up, 0.0, 0.6)
  lurek.log.info("walk + 60% aim blend applied", "spine")
end

-- =============================================================================
-- Skeleton: skins (visual equipment variants)
-- =============================================================================

--@api-stub: LSkeleton:addSkin
-- Registers a new named skin for slot-attachment remapping
do
  -- Skins let you swap the visual appearance of slots without changing
  -- the rig structure. Define one skin per equipment set or costume.
  local rig = lurek.spine.newSkeleton("hero")
  local body = rig:addBone("body")
  rig:addSlot("chest", body, "shirt.png")
  rig:addSlot("legs", body, "pants.png")
  rig:addSlot("helmet", body)

  -- Register skins: "default" for starting gear, "iron" for upgrades
  rig:addSkin("default")
  rig:addSkin("iron")
  rig:addSkin("gold")
  lurek.log.info("3 skins registered on hero", "spine")
end

--@api-stub: LSkeleton:setSkinMapping
-- Maps a slot to a specific attachment within a skin
do
  -- setSkinMapping tells the engine: "when skin X is active, slot Y
  -- should display attachment Z". Build your equipment system this way.
  local rig = lurek.spine.newSkeleton("hero")
  local body = rig:addBone("body")
  rig:addSlot("chest", body, "shirt.png")
  rig:addSlot("weapon", body, "fists.png")

  rig:addSkin("default")
  rig:addSkin("warrior")
  rig:addSkin("mage")

  -- Warrior skin: plate armor + sword
  rig:setSkinMapping("warrior", "chest", "plate_armor.png")
  rig:setSkinMapping("warrior", "weapon", "broadsword.png")

  -- Mage skin: robe + staff
  rig:setSkinMapping("mage", "chest", "mystic_robe.png")
  rig:setSkinMapping("mage", "weapon", "oak_staff.png")

  lurek.log.info("skin mappings configured for warrior and mage", "spine")
end

--@api-stub: LSkeleton:setSkin
-- Activates a named skin, applying its slot-attachment mappings
do
  -- setSkin switches the active costume. All slots immediately update
  -- to show the attachments defined for that skin.
  -- Returns false if the skin name was never registered.
  local rig = lurek.spine.newSkeleton("hero")
  local body = rig:addBone("body")
  rig:addSlot("chest", body, "shirt.png")

  rig:addSkin("default")
  rig:addSkin("winter")
  rig:setSkinMapping("winter", "chest", "fur_coat.png")

  -- Player enters snow biome → switch to winter gear
  local success = rig:setSkin("winter")
  if success then
    lurek.log.info("switched to winter skin", "spine")
  end

  -- Trying a non-existent skin is safe (returns false)
  local bad = rig:setSkin("summer")
  lurek.log.info("set unknown skin: " .. tostring(bad), "spine")
end

--@api-stub: LSkeleton:getSkin
-- Returns the name of the currently active skin, or nil
do
  -- getSkin lets you check which costume is active, for example to
  -- show the correct portrait in the UI or save to a profile.
  local rig = lurek.spine.newSkeleton("hero")
  rig:addSkin("default")
  rig:addSkin("legendary")
  rig:setSkin("legendary")

  local current = rig:getSkin()
  if current then
    lurek.log.info("active skin: " .. current, "spine")
  else
    lurek.log.info("no skin active (using default attachments)", "spine")
  end
end

-- =============================================================================
-- Skeleton: inverse kinematics
-- =============================================================================

--@api-stub: LSkeleton:addIKConstraint
-- Adds an IK constraint controlling a chain of bones toward a target
do
  -- IK constraints make a chain of bones reach toward a target point.
  -- Useful for arms reaching for objects, legs planting on terrain, etc.
  -- The chain array lists bone indices from root to tip of the IK chain.
  local rig = lurek.spine.newSkeleton("robot")
  local shoulder = rig:addBone("shoulder", { x = 300, y = 200 })
  local upper    = rig:addChildBone("upper_arm", shoulder, { y = 40 })
  local forearm  = rig:addChildBone("forearm", upper, { y = 35 })

  -- Create a 2-bone IK chain (upper_arm → forearm) with positive bend
  local ik_idx = rig:addIKConstraint("reach_ik", {upper, forearm}, true)
  lurek.log.info("IK constraint index: " .. ik_idx, "spine")
end

--@api-stub: LSkeleton:setIKTarget
-- Sets the world-space target for a named IK constraint
do
  -- After adding an IK constraint, call setIKTarget to tell it where
  -- to reach. Then call updateWorldTransforms to solve the chain.
  -- Example: hand follows mouse cursor or reaches for a pickup item.
  local rig = lurek.spine.newSkeleton("grabber")
  local shoulder = rig:addBone("shoulder", { x = 300, y = 200 })
  local upper    = rig:addChildBone("upper_arm", shoulder, { y = 40 })
  local hand     = rig:addChildBone("hand", upper, { y = 35 })

  rig:addIKConstraint("grab_ik", {upper, hand}, true)

  -- Move the hand toward a pickup item at (380, 260)
  local found = rig:setIKTarget("grab_ik", 380, 260)
  if found then
    rig:updateWorldTransforms()
    local hand_pos = rig:getBoneWorld(2)
    if hand_pos then
      lurek.log.info(string.format("hand reaching toward (380,260), now at (%.0f,%.0f)",
        hand_pos.x, hand_pos.y), "spine")
    end
  end
end

-- =============================================================================
-- Skeleton: rendering
-- =============================================================================

--@api-stub: LSkeleton:drawToImage
-- Renders the skeleton into an in-memory image for debug or UI preview
do
  -- drawToImage rasterizes the skeleton rig into a pixel buffer.
  -- Use it for debug overlays, inventory previews, or portrait icons.
  -- The result is an LImage that can be drawn with lurek.render.draw.
  local rig = lurek.spine.newSkeleton("preview_char")
  local root = rig:addBone("root", { x = 64, y = 100 })
  rig:addChildBone("torso", root, { y = -30 })
  rig:addChildBone("head", 1, { y = -20 })
  rig:addChildBone("arm_l", 1, { x = -15, y = -5 })
  rig:addChildBone("arm_r", 1, { x = 15, y = -5 })
  rig:updateWorldTransforms()

  -- Render at 128x128 for an inventory portrait
  local portrait = rig:drawToImage(128, 128)
  local tex = lurek.render.newImage(portrait)
  function lurek.draw()
    lurek.render.draw(tex, 16, 16)
  end
end

-- =============================================================================
-- SkeletonAnimation: keyframes and timelines
-- =============================================================================

--@api-stub: LSkeletonAnimation:addKeyframe
-- Adds a keyframe to a bone property timeline with value and easing
do
  -- Keyframes define the motion curve for one bone property over time.
  -- Properties: "x", "y", "rotation", "scale_x", "scale_y".
  -- Easing: "linear", "ease_in", "ease_out", "ease_in_out", "step".
  local anim = lurek.spine.newSkeletonAnimation("jump", 0.8)

  -- Bone 0 (root) Y: crouch → launch → hang → land
  anim:addKeyframe(0, "y", 0.0,   0, "ease_in")     -- start at ground
  anim:addKeyframe(0, "y", 0.15, -5, "ease_out")    -- crouch anticipation
  anim:addKeyframe(0, "y", 0.4,  40, "ease_out")    -- peak of jump
  anim:addKeyframe(0, "y", 0.8,   0, "ease_in")     -- land

  -- Bone 0 rotation: slight tilt during jump
  anim:addKeyframe(0, "rotation", 0.0, 0.0, "linear")
  anim:addKeyframe(0, "rotation", 0.4, 0.1, "ease_in_out")
  anim:addKeyframe(0, "rotation", 0.8, 0.0, "linear")

  lurek.log.info("jump clip: " .. anim:getTimelineCount() .. " timelines", "spine")
end

--@api-stub: LSkeletonAnimation:getTimelineCount
-- Returns the number of bone-property timelines in this animation
do
  -- Each unique (bone_idx, property) pair gets its own timeline.
  -- Use this to verify your animation is structured as expected.
  local run = lurek.spine.newSkeletonAnimation("run", 0.5)

  -- Bone 0: Y bounce
  run:addKeyframe(0, "y", 0.0, 0); run:addKeyframe(0, "y", 0.25, -6)
  run:addKeyframe(0, "y", 0.5, 0)

  -- Bone 1: arm swing rotation
  run:addKeyframe(1, "rotation", 0.0, 0.3); run:addKeyframe(1, "rotation", 0.25, -0.3)
  run:addKeyframe(1, "rotation", 0.5, 0.3)

  -- Bone 2: leg rotation
  run:addKeyframe(2, "rotation", 0.0, -0.4); run:addKeyframe(2, "rotation", 0.25, 0.4)
  run:addKeyframe(2, "rotation", 0.5, -0.4)

  -- Should be 3 timelines: (0,y), (1,rotation), (2,rotation)
  lurek.log.info("run timelines: " .. run:getTimelineCount(), "spine")
end

--@api-stub: LSkeletonAnimation:getDuration
-- Returns the total duration of this animation in seconds
do
  -- getDuration returns what you passed to newSkeletonAnimation.
  -- Use it to know when a one-shot animation finishes, or to
  -- normalize time for progress bars and UI feedback.
  local death = lurek.spine.newSkeletonAnimation("death", 1.2)
  death:addKeyframe(0, "rotation", 0.0, 0.0)
  death:addKeyframe(0, "rotation", 1.2, 1.57)

  -- Show a "respawn in X seconds" countdown based on animation length
  local respawn_delay = death:getDuration() + 2.0
  lurek.log.info("respawn after " .. respawn_delay .. "s (anim=" .. death:getDuration() .. "s + 2s wait)", "spine")
end

-- =============================================================================
-- SkeletonAnimation: events
-- =============================================================================

--@api-stub: LSkeletonAnimation:addEventKey
-- Inserts an event trigger at a specific time in the animation
do
  -- Events are named triggers embedded in the timeline. They fire when
  -- playback crosses their time. Use them for sound effects, particles,
  -- hitbox activation, footstep dust, etc.
  local walk = lurek.spine.newSkeletonAnimation("walk", 0.8)
  walk:addKeyframe(0, "y", 0.0, 0); walk:addKeyframe(0, "y", 0.4, -2)
  walk:addKeyframe(0, "y", 0.8, 0)

  -- Footstep events at each foot-plant frame
  walk:addEventKey(0.1, "footstep_left")        -- no value → defaults to 0
  walk:addEventKey(0.5, "footstep_right")

  -- Hit-frame event with a damage value payload
  local attack = lurek.spine.newSkeletonAnimation("attack", 0.4)
  attack:addKeyframe(0, "rotation", 0.0, 0.0)
  attack:addKeyframe(0, "rotation", 0.2, -1.5)
  attack:addKeyframe(0, "rotation", 0.4, 0.0)
  attack:addEventKey(0.2, "deal_damage", 25.0)  -- 25 damage at hit frame

  lurek.log.info("walk has footstep events; attack has damage event", "spine")
end

--@api-stub: LSkeletonAnimation:getEvents
-- Collects all events that fire within a time range
do
  -- Call getEvents(from, to) each frame with previous and current time.
  -- It returns an array of {name, value} tables for events in that window.
  -- This lets you trigger game logic in sync with the animation.
  local clip = lurek.spine.newSkeletonAnimation("combo", 1.0)
  clip:addKeyframe(0, "rotation", 0.0, 0.0)
  clip:addKeyframe(0, "rotation", 1.0, 6.28)
  clip:addEventKey(0.2, "swing_whoosh")
  clip:addEventKey(0.35, "hit_connect", 15.0)
  clip:addEventKey(0.7, "swing_whoosh")
  clip:addEventKey(0.85, "hit_connect", 20.0)

  local prev_time = 0
  function lurek.process(dt)
    local now = prev_time + dt
    local events = clip:getEvents(prev_time, now)
    for _, ev in ipairs(events) do
      if ev.name == "swing_whoosh" then
        lurek.log.debug("play whoosh sfx", "spine")
      elseif ev.name == "hit_connect" then
        lurek.log.debug("deal " .. ev.value .. " damage", "spine")
      end
    end
    prev_time = now
    if now >= clip:getDuration() then prev_time = 0 end
  end
end

-- =============================================================================
-- SkeletonAnimation: sampling and manipulation
-- =============================================================================

--@api-stub: LSkeletonAnimation:poseAt
-- Samples all timelines at a given time and returns the pose as a table
do
  -- poseAt lets you inspect the animation's computed values at any time
  -- without applying them to a skeleton. Useful for tools, previews,
  -- or procedural logic that needs to know where a bone would be.
  local clip = lurek.spine.newSkeletonAnimation("wave", 1.0)
  clip:addKeyframe(0, "x", 0.0, 0.0, "linear")
  clip:addKeyframe(0, "x", 1.0, 50.0, "linear")
  clip:addKeyframe(0, "y", 0.0, 0.0, "ease_in_out")
  clip:addKeyframe(0, "y", 0.5, 20.0, "ease_in_out")
  clip:addKeyframe(0, "y", 1.0, 0.0, "ease_in_out")

  -- Sample at the midpoint
  local pose = clip:poseAt(0.5)
  for _, entry in ipairs(pose) do
    -- Each entry: { bone_idx = number, property = string, value = number }
    lurek.log.debug(string.format(
      "bone %d %s = %.2f", entry.bone_idx, entry.property, entry.value
    ), "spine")
  end
end

--@api-stub: LSkeletonAnimation:reverse
-- Creates a new animation that plays keyframes in reverse order
do
  -- reverse() produces a new animation with the same duration but
  -- keyframes flipped in time. Use it for door-close from door-open,
  -- or sheathe-weapon from draw-weapon, without authoring twice.
  local door_open = lurek.spine.newSkeletonAnimation("door_open", 0.6)
  door_open:addKeyframe(0, "rotation", 0.0, 0.0, "ease_out")
  door_open:addKeyframe(0, "rotation", 0.6, 1.57, "ease_out")

  -- Generate the close animation automatically
  local door_close = door_open:reverse()
  lurek.log.info("door_open duration: " .. door_open:getDuration(), "spine")
  lurek.log.info("door_close duration: " .. door_close:getDuration(), "spine")

  -- Both clips can be registered on a door skeleton:
  local door = lurek.spine.newSkeleton("door")
  door:addBone("hinge", { x = 100, y = 200 })
  door:addAnimation(door_open)
  door:addAnimation(door_close)
end

-- =============================================================================
-- Type introspection
-- =============================================================================

--@api-stub: LSkeletonAnimation:type
-- Returns the type name of this userdata object
do
  -- type() returns "LSkeleton" — useful for generic object handling
  -- when you receive an unknown userdata and need to identify it.
  local sk = lurek.spine.newSkeleton("test")
  lurek.log.info("LSkeleton:type() = " .. sk:type(), "spine")
end

--@api-stub: LSkeletonAnimation:typeOf
-- Checks whether this object is of the given type name
do
  -- typeOf checks identity. Supports "LSkeleton" and the base "Object".
  -- Use it for safe downcasting in generic code paths.
  local sk = lurek.spine.newSkeleton("test")
  assert(sk:typeOf("LSkeleton") == true)
  assert(sk:typeOf("Object") == true)
  assert(sk:typeOf("LImage") == false)
  lurek.log.info("typeOf checks pass", "spine")
end

--@api-stub: LSkeletonAnimation:type
-- Returns the type name of this userdata object
do
  -- Same pattern: type() on an animation returns "LSkeletonAnimation".
  local clip = lurek.spine.newSkeletonAnimation("test_clip", 1.0)
  lurek.log.info("LSkeletonAnimation:type() = " .. clip:type(), "spine")
end

--@api-stub: LSkeletonAnimation:typeOf
-- Checks whether this object is of the given type name
do
  -- Supports "LSkeletonAnimation" and "Object".
  local clip = lurek.spine.newSkeletonAnimation("test_clip", 1.0)
  assert(clip:typeOf("LSkeletonAnimation") == true)
  assert(clip:typeOf("Object") == true)
  assert(clip:typeOf("LSkeleton") == false)
  lurek.log.info("animation typeOf checks pass", "spine")
end

print("content/examples/spine.lua")

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
