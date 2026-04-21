-- content/examples/spine.lua
-- Lurek2D lurek.spine API Reference
-- Run with: cargo run -- content/examples/spine

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- The returned Skeleton owns all bones, slots, and animation state for one
-- character rig.  Add bones with addBone / addChildBone before use.
local skel = lurek.spine.newSkeleton("hero")

-- After creating the clip, add BoneTimeline keyframes to it, then register it
-- with the skeleton via addAnimation so it can be played by name.
local walk_clip = lurek.spine.newSkeletonAnimation("walk", 0.6)
local run_clip  = lurek.spine.newSkeletonAnimation("run",  0.35)

-- -----------------------------------------------------------------------------
-- Skeleton methods
-- -----------------------------------------------------------------------------

-- Look up a bone index by name when you need to pass it to getBoneWorld or
-- set an IK target without hard-coding a positional index.
local torso_idx = skel:findBone("torso")
local head_idx  = skel:findBone("head")
local missing   = skel:findBone("wing")   -- nil: skeleton has no wing bone

if head_idx then
    -- position a floating nameplate above the head bone each frame
    local w = skel:getBoneWorld(head_idx)
    if w then
        -- nameplate_y = w.y - 20
    end
end

-- Use this before swapping a slot's attachment at runtime, for example to
-- change the weapon sprite without rebuilding the whole rig.
local sword_slot_idx = skel:findSlot("hand_right")
local shield_slot_idx = skel:findSlot("hand_left")

if sword_slot_idx then
    print("sword slot found at index", sword_slot_idx)
end

-- Must be called after moving the root or changing any local bone transform.
-- Without it, getBoneWorld returns the pose from the previous frame.
skel:setPosition(200, 300)
skel:updateWorldTransforms()
-- all getBoneWorld calls below this point reflect the new root position

-- Use this to anchor a particle emitter or UI label to a specific bone each frame.
-- Returns fields: x, y, rotation, scale_x, scale_y
local tip_idx = skel:findBone("hand_right")
if tip_idx then
    local w = skel:getBoneWorld(tip_idx)
    if w then
        print(string.format("sword tip: x=%.1f  y=%.1f  rot=%.2f", w.x, w.y, w.rotation))
        -- spawn a sword-trail particle at w.x, w.y each frame
    end
end

-- Call this every frame with the character's current world position so that
-- all child bones follow.  Internally calls updateWorldTransforms for you.
skel:setPosition(320, 240)
-- after setPosition the whole rig has moved: no extra updateWorldTransforms needed

-- Use this to validate a loaded rig, or to iterate every bone when you need
-- to build a debug overlay that draws each bone's world position as a dot.
local bone_n = skel:boneCount()
print("rig has", bone_n, "bones")

for i = 1, bone_n do
    local w = skel:getBoneWorld(i)
    if w then
        -- draw_debug_dot(w.x, w.y)
    end
end

-- Useful when you loop over every slot to apply a tint to the whole character,
-- for example a hit-flash effect that tints every attachment red for one frame.
local slot_n = skel:slotCount()
print("rig has", slot_n, "slots")
-- for i = 1, slot_n do skel:setSlotColor(i, 1, 0.2, 0.2, 1) end  -- red flash

-- Handy during rig setup to verify the bone hierarchy looks correct before
-- connecting real sprite attachments.  Pass the output image size in pixels.
local debug_img = skel:drawToImage(256, 256)
-- debug_img is an ImageData you can pass to lurek.render.drawImage()
-- to display the stick-figure preview on screen during development

-- Call when the character lands after a jump: freeze the pose at the current
-- keyframe, then start the landing animation from a known static pose.
skel:stopAnimation()
-- the rig now holds the last evaluated pose; no further keyframes are applied
-- until playAnimation is called again

-- Call once per frame inside lurek.process(dt) to drive the walk/run cycle.
-- The skeleton evaluates and blends keyframes, then updates all bone poses.
--[[
function lurek.process(dt)
    skel:updateAnimation(dt)       -- advance the active clip by one frame delta
    skel:updateWorldTransforms()   -- propagate the new poses to world space
end
]]

-- Use this to trigger game events tied to specific keyframe timestamps,
-- such as playing a footstep sound when the foot-down keyframe passes.
skel:updateAnimation(0.016)
local t = skel:getAnimationTime()
if t > 0.3 and t < 0.32 then
    -- play footstep sound at the foot-down keyframe
    print("footstep cue at t=", t)
end

-- Register every clip the character needs (walk, run, attack, idle) once
-- during init so playAnimation can start them by name later.
skel:addAnimation(walk_clip)
skel:addAnimation(run_clip)
print("registered animations: walk, run")

-- Create one skin per equipment loadout.  Skin names are referenced by setSkin
-- when the player equips or removes gear in the inventory screen.
skel:addSkin("default")
skel:addSkin("armored")
skel:addSkin("undead")
print("skins registered: default, armored, undead")

-- Returns true when the skin exists and was applied; false if not found.
-- Call this when the player equips heavy armour or transforms into undead form.
local ok = skel:setSkin("armored")
if ok then
    print("hero skin switched to armored")
else
    print("skin not found -- keeping current skin")
end

-- Read this when saving the character's loadout so the correct skin can be
-- restored on load without hard-coding assumptions about the default state.
local current_skin = skel:getSkin()
if current_skin then
    print("saving skin:", current_skin)   -- "armored"
    -- save_data.skin = current_skin
end

-- -----------------------------------------------------------------------------
-- SkeletonAnimation methods
-- -----------------------------------------------------------------------------

-- Use this to calculate when an animation will loop so you can schedule
-- a follow-up event (sound, particle burst) exactly at the end of the clip.
local walk_dur = walk_clip:getDuration()
print(string.format("walk clip lasts %.2f s -- schedule footstep at %.2f s",
    walk_dur, walk_dur * 0.5))

-- Verify this after building or loading a clip to confirm all expected bones
-- have keyframe data before registering the animation with the skeleton.
local tl = walk_clip:getTimelineCount()
print("walk clip has", tl, "bone timelines")
if tl == 0 then
    print("WARNING: no timelines -- clip was not built correctly")
end

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SkeletonAnimation methods
-- -----------------------------------------------------------------------------

-- Returns a list of event names that fall in the half-open interval `(from, to]`.
skeletonAnimation_stub:getEvents(from, to)
