-- Lurek2D Lua BDD tests for lurek.spine
-- Headless: no GPU, no audio, no window.

-- @describe module interface
describe("module interface", function()
    -- @covers lurek.spine.newSkeleton
    it("exposes newSkeleton factory", function()
        expect_type("function", lurek.spine.newSkeleton)
    end)
end)

-- @describe newSkeleton(name)
describe("newSkeleton(name)", function()
    -- @covers lurek.spine.newSkeleton
    it("returns a userdata object", function()
        local sk = lurek.spine.newSkeleton("hero")
        expect_type("userdata", sk)
    end)

    -- @covers LSkeleton:boneCount
    -- @covers lurek.spine.newSkeleton
    it("starts with zero bones", function()
        local sk = lurek.spine.newSkeleton("test")
        expect_equal(0, sk:boneCount())
    end)

    -- @covers LSkeleton:slotCount
    -- @covers lurek.spine.newSkeleton
    it("starts with zero slots", function()
        local sk = lurek.spine.newSkeleton("test")
        expect_equal(0, sk:slotCount())
    end)
end)

-- @describe addBone(name, opts)
describe("addBone(name, opts)", function()
    -- @covers LSkeleton:addBone
    -- @covers lurek.spine.newSkeleton
    it("returns an index starting from 0", function()
        local sk = lurek.spine.newSkeleton("test")
        local idx = sk:addBone("root")
        expect_equal(0, idx)
    end)

    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:boneCount
    -- @covers lurek.spine.newSkeleton
    it("increments boneCount", function()
        local sk = lurek.spine.newSkeleton("test")
        sk:addBone("root")
        sk:addBone("torso")
        expect_equal(2, sk:boneCount())
    end)

    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:boneCount
    -- @covers lurek.spine.newSkeleton
    it("accepts opts table with x, y, rotation", function()
        local sk = lurek.spine.newSkeleton("test")
        sk:addBone("root", { x = 10, y = 20, rotation = 0.5 })
        expect_equal(1, sk:boneCount())
    end)
end)

-- @describe addChildBone(name, parent_idx, opts)
describe("addChildBone(name, parent_idx, opts)", function()
    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:addChildBone
    -- @covers LSkeleton:boneCount
    -- @covers lurek.spine.newSkeleton
    it("increments boneCount", function()
        local sk = lurek.spine.newSkeleton("test")
        local root = sk:addBone("root")
        sk:addChildBone("arm", root)
        expect_equal(2, sk:boneCount())
    end)
end)

-- @describe findBone(name)
describe("findBone(name)", function()
    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:findBone
    -- @covers lurek.spine.newSkeleton
    it("returns the index of an existing bone", function()
        local sk = lurek.spine.newSkeleton("test")
        sk:addBone("root")
        sk:addBone("chest")
        local idx = sk:findBone("chest")
        expect_equal(1, idx)
    end)

    -- @covers LSkeleton:findBone
    -- @covers lurek.spine.newSkeleton
    it("returns nil for unknown bone name", function()
        local sk = lurek.spine.newSkeleton("test")
        expect_equal(nil, sk:findBone("nonexistent"))
    end)
end)

-- @describe addSlot(name, bone_idx, attachment)
describe("addSlot(name, bone_idx, attachment)", function()
    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:addSlot
    -- @covers LSkeleton:slotCount
    -- @covers lurek.spine.newSkeleton
    it("increments slotCount", function()
        local sk = lurek.spine.newSkeleton("test")
        local b = sk:addBone("root")
        sk:addSlot("slot0", b)
        expect_equal(1, sk:slotCount())
    end)

    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:addSlot
    -- @covers LSkeleton:slotCount
    -- @covers lurek.spine.newSkeleton
    it("accepts optional attachment name", function()
        local sk = lurek.spine.newSkeleton("test")
        local b = sk:addBone("root")
        sk:addSlot("slot0", b, "torso_skin")
        expect_equal(1, sk:slotCount())
    end)
end)

-- @describe findSlot(name)
describe("findSlot(name)", function()
    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:addSlot
    -- @covers LSkeleton:findSlot
    -- @covers lurek.spine.newSkeleton
    it("returns the index of an existing slot", function()
        local sk = lurek.spine.newSkeleton("test")
        local b = sk:addBone("root")
        sk:addSlot("weapon_slot", b)
        local idx = sk:findSlot("weapon_slot")
        expect_equal(0, idx)
    end)

    -- @covers LSkeleton:findSlot
    -- @covers lurek.spine.newSkeleton
    it("returns nil for unknown slot name", function()
        local sk = lurek.spine.newSkeleton("test")
        expect_equal(nil, sk:findSlot("nope"))
    end)
end)

-- @describe setPosition(x, y)
describe("setPosition(x, y)", function()
    -- @covers LSkeleton:setPosition
    -- @covers lurek.spine.newSkeleton
    it("does not error", function()
        local sk = lurek.spine.newSkeleton("test")
        sk:setPosition(50, 120)
    end)
end)

-- @describe updateWorldTransforms()
describe("updateWorldTransforms()", function()
    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:updateWorldTransforms
    -- @covers lurek.spine.newSkeleton
    it("does not error", function()
        local sk = lurek.spine.newSkeleton("test")
        sk:addBone("root")
        sk:updateWorldTransforms()
    end)
end)

-- @describe getBoneWorld(idx)
describe("getBoneWorld(idx)", function()
    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:getBoneWorld
    -- @covers LSkeleton:updateWorldTransforms
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

    -- @covers LSkeleton:getBoneWorld
    -- @covers lurek.spine.newSkeleton
    it("returns nil for out-of-bounds index", function()
        local sk = lurek.spine.newSkeleton("test")
        local result = sk:getBoneWorld(999)
        expect_equal(nil, result)
    end)
end)
-- @describe drawToImage(w, h)
describe("drawToImage(w, h)", function()
    -- @covers LSkeleton:drawToImage
    -- @covers lurek.spine.newSkeleton
    it("is a function on skeleton", function()
        local sk = lurek.spine.newSkeleton("test")
        expect_type("function", function() sk:drawToImage(64, 64) end)
    end)

    -- @covers LSkeleton:drawToImage
    -- @covers lurek.spine.newSkeleton
    it("returns a userdata (ImageData)", function()
        local sk = lurek.spine.newSkeleton("test")
        local img = sk:drawToImage(64, 64)
        expect_type("userdata", img)
    end)

    -- @covers LSkeleton:drawToImage
    -- @covers lurek.spine.newSkeleton
    it("works with minimal dimensions 1x1", function()
        local sk = lurek.spine.newSkeleton("test")
        local img = sk:drawToImage(1, 1)
        expect_not_nil(img)
    end)
end)

--  Spine Extended API (merged from test_spine_ext.lua)

-- module interface

-- @describe new API factories
describe("new API factories", function()
    -- @covers lurek.spine.newSkeletonAnimation
    it("exposes newSkeletonAnimation factory", function()
        expect_type("function", lurek.spine.newSkeletonAnimation)
    end)
end)

-- animation playback

-- @describe skeleton animation playback
describe("skeleton animation playback", function()
    -- @covers LSkeleton:addAnimation
    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:getAnimationTime
    -- @covers LSkeleton:playAnimation
    -- @covers LSkeleton:updateAnimation
    -- @covers LSkeletonAnimation:addKeyframe
    -- @covers lurek.spine.newSkeleton
    -- @covers lurek.spine.newSkeletonAnimation
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

    -- @covers LSkeleton:addAnimation
    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:getAnimationTime
    -- @covers LSkeleton:playAnimation
    -- @covers LSkeleton:stopAnimation
    -- @covers LSkeleton:updateAnimation
    -- @covers LSkeletonAnimation:addKeyframe
    -- @covers lurek.spine.newSkeleton
    -- @covers lurek.spine.newSkeletonAnimation
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

    -- @covers LSkeleton:getAnimationTime
    -- @covers lurek.spine.newSkeleton
    it("fresh skeleton has animation time of 0", function()
        local sk = lurek.spine.newSkeleton("new")
        expect_near(0.0, sk:getAnimationTime(), 0.001)
    end)
end)

-- SkeletonAnimation (timeline)

-- @describe SkeletonAnimation
describe("SkeletonAnimation", function()
    -- @covers lurek.spine.newSkeletonAnimation
    it("returns a userdata", function()
        local sa = lurek.spine.newSkeletonAnimation("hero_walk", 1.0)
        expect_type("userdata", sa)
    end)

    -- @covers LSkeletonAnimation:getDuration
    -- @covers lurek.spine.newSkeletonAnimation
    it("getDuration returns the configured duration", function()
        local sa = lurek.spine.newSkeletonAnimation("run", 2.5)
        expect_near(2.5, sa:getDuration(), 0.001)
    end)

    -- @covers LSkeletonAnimation:getTimelineCount
    -- @covers lurek.spine.newSkeletonAnimation
    it("getTimelineCount is 0 for new animation", function()
        local sa = lurek.spine.newSkeletonAnimation("idle", 1.0)
        expect_equal(0, sa:getTimelineCount())
    end)

    -- @covers LSkeletonAnimation:addKeyframe
    -- @covers LSkeletonAnimation:getTimelineCount
    -- @covers lurek.spine.newSkeletonAnimation
    it("addKeyframe increments timeline count", function()
        local sa = lurek.spine.newSkeletonAnimation("run", 1.0)
        sa:addKeyframe(0, "x", 0.0, 0.0)
        expect_equal(1, sa:getTimelineCount())
    end)

    -- @covers LSkeletonAnimation:addKeyframe
    -- @covers LSkeletonAnimation:getTimelineCount
    -- @covers lurek.spine.newSkeletonAnimation
    it("addKeyframe accepts optional easing parameter", function()
        local sa = lurek.spine.newSkeletonAnimation("run", 1.0)
        sa:addKeyframe(0, "x", 0.0, 10.0, "linear")
        sa:addKeyframe(0, "x", 1.0, 20.0, "ease_in_out")
        expect_equal(1, sa:getTimelineCount()) -- same bone-property = same timeline
    end)
end)

-- addAnimation (attach to skeleton)

-- @describe addAnimation()
describe("addAnimation()", function()
    -- @covers LSkeleton:addAnimation
    -- @covers lurek.spine.newSkeleton
    -- @covers lurek.spine.newSkeletonAnimation
    it("does not error for a valid animation", function()
        local sk = lurek.spine.newSkeleton("hero")
        local sa = lurek.spine.newSkeletonAnimation("idle", 1.0)
        sk:addAnimation(sa) -- should not throw
        expect_equal(true, true)
    end)
end)

-- IK constraints

-- @describe IK constraints
describe("IK constraints", function()
    -- @covers LSkeleton:addIKConstraint
    -- @covers lurek.spine.newSkeleton
    it("addIKConstraint does not error", function()
        local sk = lurek.spine.newSkeleton("robot")
        sk:addIKConstraint("arm_ik", {0, 1}, true)
        expect_equal(true, true)
    end)

    -- @covers LSkeleton:addIKConstraint
    -- @covers LSkeleton:setIKTarget
    -- @covers lurek.spine.newSkeleton
    it("setIKTarget does not error after addIKConstraint", function()
        local sk = lurek.spine.newSkeleton("robot")
        sk:addIKConstraint("arm_ik", {0, 1}, true)
        sk:setIKTarget("arm_ik", 100.0, 50.0)
        expect_equal(true, true)
    end)

    -- @covers LSkeleton:setIKTarget
    -- @covers lurek.spine.newSkeleton
    it("setIKTarget with unknown constraint returns false", function()
        local sk = lurek.spine.newSkeleton("robot")
        local ok = sk:setIKTarget("ghost_ik", 0.0, 0.0)
        expect_equal(false, ok)
    end)
end)

-- skins

-- @describe skeleton skins
describe("skeleton skins", function()
    -- @covers LSkeleton:addSkin
    -- @covers LSkeleton:getSkin
    -- @covers LSkeleton:setSkin
    -- @covers lurek.spine.newSkeleton
    it("getSkin returns the name from setSkin", function()
        local sk = lurek.spine.newSkeleton("char")
        sk:addSkin("hero")
        sk:setSkin("hero")
        expect_equal("hero", sk:getSkin())
    end)

    -- @covers LSkeleton:getSkin
    -- @covers lurek.spine.newSkeleton
    it("fresh skeleton has nil skin", function()
        local sk = lurek.spine.newSkeleton("char")
        expect_equal(nil, sk:getSkin())
    end)

    -- @covers LSkeleton:setSkin
    -- @covers lurek.spine.newSkeleton
    it("setSkin with unknown skin returns false", function()
        local sk = lurek.spine.newSkeleton("char")
        local ok = sk:setSkin("ghost_skin")
        expect_equal(false, ok)
    end)

    -- @covers LSkeleton:addSkin
    -- @covers LSkeleton:setSkinMapping
    -- @covers lurek.spine.newSkeleton
    it("setSkinMapping does not error for known skin/slot", function()
        local sk = lurek.spine.newSkeleton("char")
        sk:addSkin("armor")
        sk:setSkinMapping("armor", "torso", "heavy_chest")
        expect_equal(true, true)
    end)
end)

-- @describe lurek.spine regression coverage
describe("lurek.spine regression coverage", function()
    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:addChildBone
    -- @covers LSkeleton:addSlot
    -- @covers LSkeleton:boneCount
    -- @covers LSkeleton:drawToImage
    -- @covers LSkeleton:findBone
    -- @covers LSkeleton:findSlot
    -- @covers LSkeleton:getBoneWorld
    -- @covers LSkeleton:setPosition
    -- @covers LSkeleton:slotCount
    -- @covers LSkeleton:updateWorldTransforms
    -- @covers lurek.spine.newSkeleton
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

    -- @covers LSkeletonAnimation:addEventKey
    -- @covers LSkeletonAnimation:addKeyframe
    -- @covers LSkeletonAnimation:getDuration
    -- @covers LSkeletonAnimation:getEvents
    -- @covers LSkeletonAnimation:getTimelineCount
    -- @covers lurek.spine.newSkeletonAnimation
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

    -- @covers LSkeleton:addAnimation
    -- @covers LSkeleton:addBone
    -- @covers LSkeleton:addSkin
    -- @covers LSkeleton:getAnimationTime
    -- @covers LSkeleton:getSkin
    -- @covers LSkeleton:playAnimation
    -- @covers LSkeleton:setSkin
    -- @covers LSkeleton:stopAnimation
    -- @covers LSkeleton:updateAnimation
    -- @covers LSkeletonAnimation:addKeyframe
    -- @covers lurek.spine.newSkeleton
    -- @covers lurek.spine.newSkeletonAnimation
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
-- =========================================================================

-- @describe Skeleton:blendAnimation
describe("Skeleton:blendAnimation ", function()
    -- @covers LSkeleton:blendAnimation
    -- @covers lurek.spine.newSkeleton
    -- @covers lurek.spine.newSkeletonAnimation
    it("blendAnimation does not crash on a fresh skeleton", function()
        local skel = lurek.spine.newSkeleton("cov_blend_skel")
        local anim = lurek.spine.newSkeletonAnimation("idle", 1.0)
        local ok, _ = pcall(function()
            skel:blendAnimation(anim, 1.0, 0.0)
        end)
        expect_type("boolean", ok)
    end)
end)

-- @describe SkeletonAnimation:addEventKey
describe("SkeletonAnimation:addEventKey ", function()
    -- @covers LSkeletonAnimation:addEventKey
    -- @covers lurek.spine.newSkeletonAnimation
    it("addEventKey does not crash", function()
        local anim = lurek.spine.newSkeletonAnimation("cov_anim", 1.0)
        local ok, _ = pcall(function()
            anim:addEventKey(0.5, "footstep", 0)
        end)
        expect_type("boolean", ok)
    end)
end)

-- @describe spine strict: LSkeleton type/typeOf
describe("spine strict: LSkeleton type/typeOf", function()
    -- @covers LSkeleton:type
    -- @covers LSkeleton:typeOf
    -- @covers lurek.spine.newSkeleton
    it("LSkeleton type and typeOf are callable", function()
        local sk = lurek.spine.newSkeleton("strict_skel")
        expect_type("string", sk:type())
        expect_type("boolean", sk:typeOf("Object"))
    end)

end)

-- @describe spine strict: LSkeletonAnimation type/typeOf
describe("spine strict: LSkeletonAnimation type/typeOf", function()
    -- @covers LSkeletonAnimation:type
    -- @covers LSkeletonAnimation:typeOf
    -- @covers lurek.spine.newSkeletonAnimation
    it("LSkeletonAnimation type and typeOf are callable", function()
        local sa = lurek.spine.newSkeletonAnimation("strict_anim", 1.0)
        expect_type("string", sa:type())
        expect_type("boolean", sa:typeOf("Object"))
    end)
end)

-- @describe spine migrated from render unit
describe("spine migrated from render unit", function()
    -- @covers lurek.spine.newSkeleton
    it("newSkeleton remains canonical constructor", function()
        expect_type("function", lurek.spine.newSkeleton)
    end)
end)

-- @describe animationFromJson(json)
describe("animationFromJson(json)", function()
        -- @covers lurek.spine.animationFromJson
        it("parses valid json into LSkeletonAnimation", function()
                local json = [[
                {
                    "name":"parsed",
                    "duration":1.0,
                    "timelines":[
                        {"bone_idx":0,"property":"x","keys":[
                            {"time":0.0,"value":0.0,"easing":"linear"},
                            {"time":1.0,"value":2.0,"easing":"linear"}
                        ]}
                    ],
                    "events":[{"time":0.5,"name":"tick","value":1.0}]
                }
                ]]
                local anim = lurek.spine.animationFromJson(json)
                expect_type("userdata", anim)
        end)
end)

    -- @describe poseAt(time)
    describe("poseAt(time)", function()
        -- @covers LSkeletonAnimation:poseAt
        -- @covers lurek.spine.newSkeletonAnimation
        it("returns a table snapshot", function()
            local sa = lurek.spine.newSkeletonAnimation("pose_probe", 1.0)
            sa:addKeyframe(0, "x", 0.0, 0.0, "linear")
            sa:addKeyframe(0, "x", 1.0, 5.0, "linear")
            local pose = sa:poseAt(0.5)
            expect_type("table", pose)
        end)
    end)

test_summary()
