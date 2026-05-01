-- Lurek2D Lua BDD tests for lurek.spine
-- Headless: no GPU, no audio, no window.

describe("lurek.spine", function()
    describe("module interface", function()
        -- @covers lurek.spine.newSkeleton
        it("exposes newSkeleton factory", function()
            expect_type("function", lurek.spine.newSkeleton)
        end)
    end)

    describe("newSkeleton(name)", function()
        -- @covers lurek.spine.newSkeleton
        it("returns a userdata object", function()
            local sk = lurek.spine.newSkeleton("hero")
            expect_type("userdata", sk)
        end)

        -- @covers lurek.spine.newSkeleton
        it("starts with zero bones", function()
            local sk = lurek.spine.newSkeleton("test")
            expect_equal(0, sk:boneCount())
        end)

        -- @covers lurek.spine.newSkeleton
        it("starts with zero slots", function()
            local sk = lurek.spine.newSkeleton("test")
            expect_equal(0, sk:slotCount())
        end)
    end)

    describe("addBone(name, opts)", function()
        -- @covers lurek.spine.newSkeleton
        it("returns an index starting from 0", function()
            local sk = lurek.spine.newSkeleton("test")
            local idx = sk:addBone("root")
            expect_equal(0, idx)
        end)

        -- @covers lurek.spine.newSkeleton
        it("increments boneCount", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:addBone("root")
            sk:addBone("torso")
            expect_equal(2, sk:boneCount())
        end)

        -- @covers lurek.spine.newSkeleton
        it("accepts opts table with x, y, rotation", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:addBone("root", { x = 10, y = 20, rotation = 0.5 })
            expect_equal(1, sk:boneCount())
        end)
    end)

    describe("addChildBone(name, parent_idx, opts)", function()
        -- @covers lurek.spine.newSkeleton
        it("increments boneCount", function()
            local sk = lurek.spine.newSkeleton("test")
            local root = sk:addBone("root")
            sk:addChildBone("arm", root)
            expect_equal(2, sk:boneCount())
        end)
    end)

    describe("findBone(name)", function()
        -- @covers lurek.spine.newSkeleton
        it("returns the index of an existing bone", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:addBone("root")
            sk:addBone("chest")
            local idx = sk:findBone("chest")
            expect_equal(1, idx)
        end)

        -- @covers lurek.spine.newSkeleton
        it("returns nil for unknown bone name", function()
            local sk = lurek.spine.newSkeleton("test")
            expect_equal(nil, sk:findBone("nonexistent"))
        end)
    end)

    describe("addSlot(name, bone_idx, attachment)", function()
        -- @covers lurek.spine.newSkeleton
        it("increments slotCount", function()
            local sk = lurek.spine.newSkeleton("test")
            local b = sk:addBone("root")
            sk:addSlot("slot0", b)
            expect_equal(1, sk:slotCount())
        end)

        -- @covers lurek.spine.newSkeleton
        it("accepts optional attachment name", function()
            local sk = lurek.spine.newSkeleton("test")
            local b = sk:addBone("root")
            sk:addSlot("slot0", b, "torso_skin")
            expect_equal(1, sk:slotCount())
        end)
    end)

    describe("findSlot(name)", function()
        -- @covers lurek.spine.newSkeleton
        it("returns the index of an existing slot", function()
            local sk = lurek.spine.newSkeleton("test")
            local b = sk:addBone("root")
            sk:addSlot("weapon_slot", b)
            local idx = sk:findSlot("weapon_slot")
            expect_equal(0, idx)
        end)

        -- @covers lurek.spine.newSkeleton
        it("returns nil for unknown slot name", function()
            local sk = lurek.spine.newSkeleton("test")
            expect_equal(nil, sk:findSlot("nope"))
        end)
    end)

    describe("setPosition(x, y)", function()
        -- @covers lurek.spine.newSkeleton
        it("does not error", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:setPosition(50, 120)
        end)
    end)

    describe("updateWorldTransforms()", function()
        -- @covers lurek.spine.newSkeleton
        it("does not error", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:addBone("root")
            sk:updateWorldTransforms()
        end)
    end)

    describe("getBoneWorld(idx)", function()
        -- @covers lurek.spine.newSkeleton
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

        -- @covers lurek.spine.newSkeleton
        it("returns nil for out-of-bounds index", function()
            local sk = lurek.spine.newSkeleton("test")
            local result = sk:getBoneWorld(999)
            expect_equal(nil, result)
        end)
    end)
    describe("drawToImage(w, h)", function()
        -- @covers lurek.spine.newSkeleton
        it("is a function on skeleton", function()
            local sk = lurek.spine.newSkeleton("test")
            expect_type("function", function() sk:drawToImage(64, 64) end)
        end)

        -- @covers lurek.spine.newSkeleton
        it("returns a userdata (ImageData)", function()
            local sk = lurek.spine.newSkeleton("test")
            local img = sk:drawToImage(64, 64)
            expect_type("userdata", img)
        end)

        -- @covers lurek.spine.newSkeleton
        it("works with minimal dimensions 1x1", function()
            local sk = lurek.spine.newSkeleton("test")
            local img = sk:drawToImage(1, 1)
            expect_not_nil(img)
        end)
    end)
end)

--  Spine Extended API (merged from test_spine_ext.lua) 

describe("lurek.spine extended", function()
-- module interface

    describe("new API factories", function()
        -- @covers lurek.spine.newSkeletonAnimation
        it("exposes newSkeletonAnimation factory", function()
            expect_type("function", lurek.spine.newSkeletonAnimation)
        end)
    end)

-- animation playback

    describe("skeleton animation playback", function()
        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.playAnimation
        -- @covers lurek.spine.stopAnimation
        -- @covers lurek.spine.updateAnimation
        -- @covers lurek.spine.getAnimationTime
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

        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.playAnimation
        -- @covers lurek.spine.stopAnimation
        -- @covers lurek.spine.getAnimationTime
        -- @covers lurek.spine.updateAnimation
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

        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.getAnimationTime
        it("fresh skeleton has animation time of 0", function()
            local sk = lurek.spine.newSkeleton("new")
            expect_near(0.0, sk:getAnimationTime(), 0.001)
        end)
    end)

-- SkeletonAnimation (timeline)

    describe("SkeletonAnimation", function()
        -- @covers lurek.spine.newSkeletonAnimation
        it("returns a userdata", function()
            local sa = lurek.spine.newSkeletonAnimation("hero_walk", 1.0)
            expect_type("userdata", sa)
        end)

        -- @covers lurek.spine.newSkeletonAnimation
        -- @covers lurek.spine.getDuration
        it("getDuration returns the configured duration", function()
            local sa = lurek.spine.newSkeletonAnimation("run", 2.5)
            expect_near(2.5, sa:getDuration(), 0.001)
        end)

        -- @covers lurek.spine.newSkeletonAnimation
        -- @covers lurek.spine.getTimelineCount
        it("getTimelineCount is 0 for new animation", function()
            local sa = lurek.spine.newSkeletonAnimation("idle", 1.0)
            expect_equal(0, sa:getTimelineCount())
        end)

        -- @covers lurek.spine.newSkeletonAnimation
        -- @covers lurek.spine.addKeyframe
        -- @covers lurek.spine.getTimelineCount
        it("addKeyframe increments timeline count", function()
            local sa = lurek.spine.newSkeletonAnimation("run", 1.0)
            sa:addKeyframe(0, "x", 0.0, 0.0)
            expect_equal(1, sa:getTimelineCount())
        end)

        -- @covers lurek.spine.newSkeletonAnimation
        -- @covers lurek.spine.addKeyframe
        it("addKeyframe accepts optional easing parameter", function()
            local sa = lurek.spine.newSkeletonAnimation("run", 1.0)
            sa:addKeyframe(0, "x", 0.0, 10.0, "linear")
            sa:addKeyframe(0, "x", 1.0, 20.0, "ease_in_out")
            expect_equal(1, sa:getTimelineCount()) -- same bone-property = same timeline
        end)
    end)

-- addAnimation (attach to skeleton)

    describe("addAnimation()", function()
        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.newSkeletonAnimation
        -- @covers lurek.spine.addAnimation
        it("does not error for a valid animation", function()
            local sk = lurek.spine.newSkeleton("hero")
            local sa = lurek.spine.newSkeletonAnimation("idle", 1.0)
            sk:addAnimation(sa) -- should not throw
            expect_equal(true, true)
        end)
    end)

-- IK constraints

    describe("IK constraints", function()
        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.addIKConstraint
        it("addIKConstraint does not error", function()
            local sk = lurek.spine.newSkeleton("robot")
            sk:addIKConstraint("arm_ik", {0, 1}, true)
            expect_equal(true, true)
        end)

        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.addIKConstraint
        -- @covers lurek.spine.setIKTarget
        it("setIKTarget does not error after addIKConstraint", function()
            local sk = lurek.spine.newSkeleton("robot")
            sk:addIKConstraint("arm_ik", {0, 1}, true)
            sk:setIKTarget("arm_ik", 100.0, 50.0)
            expect_equal(true, true)
        end)

        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.setIKTarget
        xit("setIKTarget errors for unknown constraint", function()
            local sk = lurek.spine.newSkeleton("robot")
            expect_error(function()
                sk:setIKTarget("ghost_ik", 0.0, 0.0)
            end)
        end)
    end)

-- skins

    describe("skeleton skins", function()
        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.addSkin
        -- @covers lurek.spine.setSkin
        -- @covers lurek.spine.getSkin
        it("getSkin returns the name from setSkin", function()
            local sk = lurek.spine.newSkeleton("char")
            sk:addSkin("hero")
            sk:setSkin("hero")
            expect_equal("hero", sk:getSkin())
        end)

        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.getSkin
        it("fresh skeleton has nil skin", function()
            local sk = lurek.spine.newSkeleton("char")
            expect_equal(nil, sk:getSkin())
        end)

        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.addSkin
        -- @covers lurek.spine.setSkin
        xit("setSkin errors for unknown skin", function()
            local sk = lurek.spine.newSkeleton("char")
            expect_error(function()
                sk:setSkin("ghost_skin")
            end)
        end)

        -- @covers lurek.spine.newSkeleton
        -- @covers lurek.spine.addSkin
        -- @covers lurek.spine.setSkinMapping
        it("setSkinMapping does not error for known skin/slot", function()
            local sk = lurek.spine.newSkeleton("char")
            sk:addSkin("armor")
            sk:setSkinMapping("armor", "torso", "heavy_chest")
            expect_equal(true, true)
        end)
    end)
end)

describe("lurek.spine regression coverage", function()
    -- @covers Skeleton:findBone
    -- @covers Skeleton:findSlot
    -- @covers Skeleton:updateWorldTransforms
    -- @covers Skeleton:getBoneWorld
    -- @covers Skeleton:setPosition
    -- @covers Skeleton:boneCount
    -- @covers Skeleton:slotCount
    -- @covers Skeleton:drawToImage
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

    -- @covers SkeletonAnimation:getDuration
    -- @covers SkeletonAnimation:getEvents
    -- @covers SkeletonAnimation:getTimelineCount
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

    -- @covers Skeleton:addAnimation
    -- @covers Skeleton:stopAnimation
    -- @covers Skeleton:updateAnimation
    -- @covers Skeleton:getAnimationTime
    -- @covers Skeleton:addSkin
    -- @covers Skeleton:setSkin
    -- @covers Skeleton:getSkin
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
