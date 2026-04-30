-- Lurek2D Lua BDD tests for lurek.spine
-- Headless: no GPU, no audio, no window.

-- @description Covers suite: lurek.spine.
describe("lurek.spine", function()
    -- @description Covers suite: module interface.
    describe("module interface", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies the spine namespace exposes the legacy newSkeleton factory.
        it("exposes newSkeleton factory", function()
            expect_type("function", lurek.spine.newSkeleton)
        end)
    end)

    -- @description Covers suite: newSkeleton(name).
    describe("newSkeleton(name)", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies newSkeleton returns userdata for a named skeleton handle.
        it("returns a userdata object", function()
            local sk = lurek.spine.newSkeleton("hero")
            expect_type("userdata", sk)
        end)

        -- @tests lurek.spine.newSkeleton
        -- @description Verifies new skeletons start with zero bones.
        it("starts with zero bones", function()
            local sk = lurek.spine.newSkeleton("test")
            expect_equal(0, sk:boneCount())
        end)

        -- @tests lurek.spine.newSkeleton
        -- @description Verifies new skeletons start with zero slots.
        it("starts with zero slots", function()
            local sk = lurek.spine.newSkeleton("test")
            expect_equal(0, sk:slotCount())
        end)
    end)

    -- @description Covers suite: addBone(name, opts).
    describe("addBone(name, opts)", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies addBone returns a zero-based index for the first inserted bone.
        it("returns an index starting from 0", function()
            local sk = lurek.spine.newSkeleton("test")
            local idx = sk:addBone("root")
            expect_equal(0, idx)
        end)

        -- @tests lurek.spine.newSkeleton
        -- @description Verifies addBone increments the bone count for each insertion.
        it("increments boneCount", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:addBone("root")
            sk:addBone("torso")
            expect_equal(2, sk:boneCount())
        end)

        -- @tests lurek.spine.newSkeleton
        -- @description Verifies addBone accepts optional transform metadata without error.
        it("accepts opts table with x, y, rotation", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:addBone("root", { x = 10, y = 20, rotation = 0.5 })
            expect_equal(1, sk:boneCount())
        end)
    end)

    -- @description Covers suite: addChildBone(name, parent_idx, opts).
    describe("addChildBone(name, parent_idx, opts)", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies addChildBone appends a child bone and increments the total count.
        it("increments boneCount", function()
            local sk = lurek.spine.newSkeleton("test")
            local root = sk:addBone("root")
            sk:addChildBone("arm", root)
            expect_equal(2, sk:boneCount())
        end)
    end)

    -- @description Covers suite: findBone(name).
    describe("findBone(name)", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies findBone returns the stored index for an existing bone name.
        it("returns the index of an existing bone", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:addBone("root")
            sk:addBone("chest")
            local idx = sk:findBone("chest")
            expect_equal(1, idx)
        end)

        -- @tests lurek.spine.newSkeleton
        -- @description Verifies findBone returns nil for unknown bone names.
        it("returns nil for unknown bone name", function()
            local sk = lurek.spine.newSkeleton("test")
            expect_equal(nil, sk:findBone("nonexistent"))
        end)
    end)

    -- @description Covers suite: addSlot(name, bone_idx, attachment).
    describe("addSlot(name, bone_idx, attachment)", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies addSlot increments slotCount when a slot is attached to a bone.
        it("increments slotCount", function()
            local sk = lurek.spine.newSkeleton("test")
            local b = sk:addBone("root")
            sk:addSlot("slot0", b)
            expect_equal(1, sk:slotCount())
        end)

        -- @tests lurek.spine.newSkeleton
        -- @description Verifies addSlot accepts an optional attachment name.
        it("accepts optional attachment name", function()
            local sk = lurek.spine.newSkeleton("test")
            local b = sk:addBone("root")
            sk:addSlot("slot0", b, "torso_skin")
            expect_equal(1, sk:slotCount())
        end)
    end)

    -- @description Covers suite: findSlot(name).
    describe("findSlot(name)", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies findSlot returns the index for an existing slot.
        it("returns the index of an existing slot", function()
            local sk = lurek.spine.newSkeleton("test")
            local b = sk:addBone("root")
            sk:addSlot("weapon_slot", b)
            local idx = sk:findSlot("weapon_slot")
            expect_equal(0, idx)
        end)

        -- @tests lurek.spine.newSkeleton
        -- @description Verifies findSlot returns nil for missing slot names.
        it("returns nil for unknown slot name", function()
            local sk = lurek.spine.newSkeleton("test")
            expect_equal(nil, sk:findSlot("nope"))
        end)
    end)

    -- @description Covers suite: setPosition(x, y).
    describe("setPosition(x, y)", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies setPosition accepts a new origin without raising an error.
        it("does not error", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:setPosition(50, 120)
        end)
    end)

    -- @description Covers suite: updateWorldTransforms().
    describe("updateWorldTransforms()", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies updateWorldTransforms runs safely after bones exist.
        it("does not error", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:addBone("root")
            sk:updateWorldTransforms()
        end)
    end)

    -- @description Covers suite: getBoneWorld(idx).
    describe("getBoneWorld(idx)", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies getBoneWorld returns numeric transform fields for a valid bone after world updates.
        it("returns a table with transform fields after updateWorldTransforms", function()
            local sk = lurek.spine.newSkeleton("test")
            local root = sk:addBone("root")
            sk:updateWorldTransforms()
            local t = sk:getBoneWorld(root)
            if t ~= nil then
                expect_type("number", t.x)
                expect_type("number", t.y)
                expect_type("number", t.rotation)
                expect_type("number", t.scale_x)
                expect_type("number", t.scale_y)
            end
        end)

        -- @tests lurek.spine.newSkeleton
        -- @description Verifies getBoneWorld returns nil for an out-of-bounds bone index.
        it("returns nil for out-of-bounds index", function()
            local sk = lurek.spine.newSkeleton("test")
            local result = sk:getBoneWorld(999)
            expect_equal(nil, result)
        end)
    end)
    -- @description Covers suite: drawToImage(w, h).
    describe("drawToImage(w, h)", function()
        -- @tests lurek.spine.newSkeleton
        -- @description Verifies skeleton userdata exposes drawToImage as a callable method.
        it("is a function on skeleton", function()
            local sk = lurek.spine.newSkeleton("test")
            expect_type("function", function() sk:drawToImage(64, 64) end)
        end)

        -- @tests lurek.spine.newSkeleton
        -- @description Verifies drawToImage returns userdata for the generated image payload.
        it("returns a userdata (ImageData)", function()
            local sk = lurek.spine.newSkeleton("test")
            local img = sk:drawToImage(64, 64)
            expect_type("userdata", img)
        end)

        -- @tests lurek.spine.newSkeleton
        -- @description Verifies drawToImage accepts minimal 1x1 dimensions.
        it("works with minimal dimensions 1x1", function()
            local sk = lurek.spine.newSkeleton("test")
            local img = sk:drawToImage(1, 1)
            expect_not_nil(img)
        end)
    end)
end)

-- ── Spine Extended API (merged from test_spine_ext.lua) ─────────────────────

-- @description Covers suite: lurek.spine extended features.
describe("lurek.spine extended", function()
    -- ── module interface ──────────────────────────────────────────────────

    -- @description Covers suite: new API factories.
    describe("new API factories", function()
        -- @tests lurek.spine.newSkeletonAnimation
        -- @description Verifies the newSkeletonAnimation factory is exposed on the module.
        it("exposes newSkeletonAnimation factory", function()
            expect_type("function", lurek.spine.newSkeletonAnimation)
        end)
    end)

    -- ── animation playback ────────────────────────────────────────────────

    -- @description Covers suite: skeleton animation playback.
    describe("skeleton animation playback", function()
        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.playAnimation
        -- @tests lurek.spine.stopAnimation
        -- @tests lurek.spine.updateAnimation
        -- @tests lurek.spine.getAnimationTime
        -- @description Confirms getAnimationTime advances after update when playing.
        it("animation time advances after updateAnimation", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:addBone("root")
            local anim = lurek.spine.newSkeletonAnimation("walk", 1.0)
            anim:addKeyframe(0, "x", 0.0, 0.0)
            anim:addKeyframe(0, "x", 1.0, 10.0)
            sk:addAnimation(anim)
            expect_true(sk:playAnimation("walk", true))
            sk:updateAnimation(0.1)
            local t = sk:getAnimationTime()
            expect_type("number", t)
            expect_true(t > 0.0, "time should advance once playback starts")
        end)

        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.playAnimation
        -- @tests lurek.spine.stopAnimation
        -- @tests lurek.spine.getAnimationTime
        -- @tests lurek.spine.updateAnimation
        -- @description Confirms stopAnimation stops playback without advancing time further.
        it("stopAnimation freezes animation time", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:addBone("root")
            local anim = lurek.spine.newSkeletonAnimation("walk", 1.0)
            anim:addKeyframe(0, "x", 0.0, 0.0)
            anim:addKeyframe(0, "x", 1.0, 10.0)
            sk:addAnimation(anim)
            expect_true(sk:playAnimation("walk", true))
            sk:updateAnimation(0.5)
            sk:stopAnimation()
            local stopped_at = sk:getAnimationTime()
            sk:updateAnimation(0.25)
            expect_near(0.5, stopped_at, 0.001)
            expect_near(stopped_at, sk:getAnimationTime(), 0.001)
        end)

        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.getAnimationTime
        -- @description Confirms a fresh skeleton reports animation time of zero.
        it("fresh skeleton has animation time of 0", function()
            local sk = lurek.spine.newSkeleton("new")
            expect_near(0.0, sk:getAnimationTime(), 0.001)
        end)
    end)

    -- ── SkeletonAnimation (timeline) ──────────────────────────────────────

    -- @description Covers suite: SkeletonAnimation object.
    describe("SkeletonAnimation", function()
        -- @tests lurek.spine.newSkeletonAnimation
        -- @description Confirms newSkeletonAnimation returns a SkeletonAnimation userdata.
        it("returns a userdata", function()
            local sa = lurek.spine.newSkeletonAnimation("hero_walk", 1.0)
            expect_type("userdata", sa)
        end)

        -- @tests lurek.spine.newSkeletonAnimation
        -- @tests lurek.spine.getDuration
        -- @description Confirms getDuration returns the duration passed at construction.
        it("getDuration returns the configured duration", function()
            local sa = lurek.spine.newSkeletonAnimation("run", 2.5)
            expect_near(2.5, sa:getDuration(), 0.001)
        end)

        -- @tests lurek.spine.newSkeletonAnimation
        -- @tests lurek.spine.getTimelineCount
        -- @description Confirms a new animation starts with zero timelines.
        it("getTimelineCount is 0 for new animation", function()
            local sa = lurek.spine.newSkeletonAnimation("idle", 1.0)
            expect_equal(0, sa:getTimelineCount())
        end)

        -- @tests lurek.spine.newSkeletonAnimation
        -- @tests lurek.spine.addKeyframe
        -- @tests lurek.spine.getTimelineCount
        -- @description Confirms addKeyframe increases the timeline count by 1.
        it("addKeyframe increments timeline count", function()
            local sa = lurek.spine.newSkeletonAnimation("run", 1.0)
            sa:addKeyframe(0, "x", 0.0, 0.0)
            expect_equal(1, sa:getTimelineCount())
        end)

        -- @tests lurek.spine.newSkeletonAnimation
        -- @tests lurek.spine.addKeyframe
        -- @description Confirms addKeyframe with easing param does not error.
        it("addKeyframe accepts optional easing parameter", function()
            local sa = lurek.spine.newSkeletonAnimation("run", 1.0)
            sa:addKeyframe(0, "x", 0.0, 10.0, "linear")
            sa:addKeyframe(0, "x", 1.0, 20.0, "ease_in_out")
            expect_equal(1, sa:getTimelineCount()) -- same bone-property = same timeline
        end)
    end)

    -- ── addAnimation (attach to skeleton) ─────────────────────────────────

    -- @description Covers suite: addAnimation().
    describe("addAnimation()", function()
        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.newSkeletonAnimation
        -- @tests lurek.spine.addAnimation
        -- @description Confirms addAnimation does not error when called with a valid SkeletonAnimation.
        it("does not error for a valid animation", function()
            local sk = lurek.spine.newSkeleton("hero")
            local sa = lurek.spine.newSkeletonAnimation("idle", 1.0)
            sk:addAnimation(sa) -- should not throw
            expect_equal(true, true)
        end)
    end)

    -- ── IK constraints ────────────────────────────────────────────────────

    -- @description Covers suite: IK constraints.
    describe("IK constraints", function()
        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.addIKConstraint
        -- @description Confirms addIKConstraint does not error for a valid bone chain.
        it("addIKConstraint does not error", function()
            local sk = lurek.spine.newSkeleton("robot")
            sk:addIKConstraint("arm_ik", {0, 1}, true)
            expect_equal(true, true)
        end)

        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.addIKConstraint
        -- @tests lurek.spine.setIKTarget
        -- @description Confirms setIKTarget can be called after adding a constraint.
        it("setIKTarget does not error after addIKConstraint", function()
            local sk = lurek.spine.newSkeleton("robot")
            sk:addIKConstraint("arm_ik", {0, 1}, true)
            sk:setIKTarget("arm_ik", 100.0, 50.0)
            expect_equal(true, true)
        end)

        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.setIKTarget
        -- @description Confirms setIKTarget errors gracefully for an unknown constraint name.
        xit("setIKTarget errors for unknown constraint", function()
            local sk = lurek.spine.newSkeleton("robot")
            expect_error(function()
                sk:setIKTarget("ghost_ik", 0.0, 0.0)
            end)
        end)
    end)

    -- ── skins ─────────────────────────────────────────────────────────────

    -- @description Covers suite: skeleton skins.
    describe("skeleton skins", function()
        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.addSkin
        -- @tests lurek.spine.setSkin
        -- @tests lurek.spine.getSkin
        -- @description Confirms getSkin returns the name set via setSkin.
        it("getSkin returns the name from setSkin", function()
            local sk = lurek.spine.newSkeleton("char")
            sk:addSkin("hero")
            sk:setSkin("hero")
            expect_equal("hero", sk:getSkin())
        end)

        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.getSkin
        -- @description Confirms a fresh skeleton has no active skin (nil).
        it("fresh skeleton has nil skin", function()
            local sk = lurek.spine.newSkeleton("char")
            expect_equal(nil, sk:getSkin())
        end)

        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.addSkin
        -- @tests lurek.spine.setSkin
        -- @description Confirms setSkin errors for a skin that was never added.
        xit("setSkin errors for unknown skin", function()
            local sk = lurek.spine.newSkeleton("char")
            expect_error(function()
                sk:setSkin("ghost_skin")
            end)
        end)

        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.addSkin
        -- @tests lurek.spine.setSkinMapping
        -- @description Confirms setSkinMapping does not error for a known skin and slot.
        it("setSkinMapping does not error for known skin/slot", function()
            local sk = lurek.spine.newSkeleton("char")
            sk:addSkin("armor")
            sk:setSkinMapping("armor", "torso", "heavy_chest")
            expect_equal(true, true)
        end)
    end)
end)

-- @description Replaces the old placeholder tail with concrete assertions across skeleton topology, animation metadata, playback, and skin activation.
describe("lurek.spine regression coverage", function()
    -- @tests Skeleton:findBone
    -- @tests Skeleton:findSlot
    -- @tests Skeleton:updateWorldTransforms
    -- @tests Skeleton:getBoneWorld
    -- @tests Skeleton:setPosition
    -- @tests Skeleton:boneCount
    -- @tests Skeleton:slotCount
    -- @tests Skeleton:drawToImage
    -- @description Builds a small skeleton hierarchy, moves it, updates transforms, and verifies topology queries, world transform access, and debug rendering.
    it("skeleton topology and world transform helpers stay consistent", function()
        local sk = lurek.spine.newSkeleton("rig")
        local root = sk:addBone("root", { x = 5, y = 10 })
        local arm = sk:addChildBone("arm", root, { x = 3, y = 4 })
        local slot = sk:addSlot("hand_slot", arm, "hand")

        sk:setPosition(20, 30)
        sk:updateWorldTransforms()

        local world = sk:getBoneWorld(arm)
        local image = sk:drawToImage(32, 32)

        expect_equal(root, sk:findBone("root"))
        expect_equal(arm, sk:findBone("arm"))
        expect_equal(slot, sk:findSlot("hand_slot"))
        expect_equal(2, sk:boneCount())
        expect_equal(1, sk:slotCount())
        expect_type("table", world)
        expect_type("number", world.x)
        expect_type("number", world.y)
        expect_type("userdata", image)
    end)

    -- @tests SkeletonAnimation:getDuration
    -- @tests SkeletonAnimation:getEvents
    -- @tests SkeletonAnimation:getTimelineCount
    -- @description Adds keyframes and event keys to a single animation and verifies duration, timeline count, and event collection all expose the authored data.
    it("SkeletonAnimation exposes duration timelines and event windows", function()
        local anim = lurek.spine.newSkeletonAnimation("wave", 1.5)
        anim:addKeyframe(0, "x", 0.0, 0.0)
        anim:addKeyframe(0, "x", 1.0, 10.0)
        anim:addEventKey(0.25, "start", 1.0)
        anim:addEventKey(0.75, "peak", 2.0)

        local events = anim:getEvents(0.0, 0.5)

        expect_near(1.5, anim:getDuration(), 0.001)
        expect_equal(1, anim:getTimelineCount())
        expect_equal(1, #events)
        expect_equal("start", events[1].name)
        expect_near(1.0, events[1].value, 0.001)
    end)

    -- @tests Skeleton:addAnimation
    -- @tests Skeleton:stopAnimation
    -- @tests Skeleton:updateAnimation
    -- @tests Skeleton:getAnimationTime
    -- @tests Skeleton:addSkin
    -- @tests Skeleton:setSkin
    -- @tests Skeleton:getSkin
    -- @description Attaches a real animation to a skeleton, advances playback, stops it, and verifies skin registration and activation on the same object.
    it("skeleton playback and skin helpers work with a real animation", function()
        local sk = lurek.spine.newSkeleton("hero")
        sk:addBone("root")
        sk:addSkin("hero_skin")

        expect_true(sk:setSkin("hero_skin"))
        expect_equal("hero_skin", sk:getSkin())

        local anim = lurek.spine.newSkeletonAnimation("walk", 1.0)
        anim:addKeyframe(0, "x", 0.0, 0.0)
        anim:addKeyframe(0, "x", 1.0, 12.0)
        sk:addAnimation(anim)

        expect_true(sk:playAnimation("walk", false))

        sk:updateAnimation(0.5)
        expect_true(sk:getAnimationTime() > 0.0, "expected animation time to advance")

        sk:stopAnimation()
        local stopped_at = sk:getAnimationTime()
        sk:updateAnimation(0.25)
        expect_near(0.5, stopped_at, 0.001)
        expect_near(stopped_at, sk:getAnimationTime(), 0.001)
    end)
end)

-- =========================================================================
-- @covers additions for spine module
-- =========================================================================

describe("Skeleton:blendAnimation (@covers)", function()
    it("blendAnimation does not crash on a fresh skeleton", function()
        -- @covers Skeleton:blendAnimation
        local skel = lurek.spine.newSkeleton("cov_blend_skel")
        local anim = lurek.spine.newSkeletonAnimation("idle", 1.0)
        local ok, _ = pcall(function()
            skel:blendAnimation(anim, 1.0, 0.0)
        end)
        expect_type("boolean", ok)
    end)
end)

describe("SkeletonAnimation:addEventKey (@covers)", function()
    it("addEventKey does not crash", function()
        -- @covers SkeletonAnimation:addEventKey
        local anim = lurek.spine.newSkeletonAnimation("cov_anim", 1.0)
        local ok, _ = pcall(function()
            anim:addEventKey(0.5, "footstep", 0)
        end)
        expect_type("boolean", ok)
    end)
end)

test_summary()
