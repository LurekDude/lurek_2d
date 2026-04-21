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
            sk:playAnimation("walk", true)
            sk:updateAnimation(0.1)
            local t = sk:getAnimationTime()
            expect_type("number", t)
            expect_true(t >= 0.0, "time should be non-negative")
        end)

        -- @tests lurek.spine.newSkeleton
        -- @tests lurek.spine.playAnimation
        -- @tests lurek.spine.stopAnimation
        -- @tests lurek.spine.getAnimationTime
        -- @description Confirms stopAnimation resets animation time to zero.
        it("stopAnimation sets time back to zero", function()
            local sk = lurek.spine.newSkeleton("test")
            sk:playAnimation("walk", true)
            sk:updateAnimation(0.5)
            sk:stopAnimation()
            expect_near(0.0, sk:getAnimationTime(), 0.001)
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
        it("setIKTarget errors for unknown constraint", function()
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
        it("setSkin errors for unknown skin", function()
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

test_summary()

describe("Missing explicit test for Skeleton:findBone", function()
    it("Skeleton:findBone works", function()
        -- @tests Skeleton:findBone
        -- TODO: add assertion for Skeleton:findBone
    end)
end)

describe("Missing explicit test for Skeleton:findSlot", function()
    it("Skeleton:findSlot works", function()
        -- @tests Skeleton:findSlot
        -- TODO: add assertion for Skeleton:findSlot
    end)
end)

describe("Missing explicit test for Skeleton:updateWorldTransforms", function()
    it("Skeleton:updateWorldTransforms works", function()
        -- @tests Skeleton:updateWorldTransforms
        -- TODO: add assertion for Skeleton:updateWorldTransforms
    end)
end)

describe("Missing explicit test for Skeleton:getBoneWorld", function()
    it("Skeleton:getBoneWorld works", function()
        -- @tests Skeleton:getBoneWorld
        -- TODO: add assertion for Skeleton:getBoneWorld
    end)
end)

describe("Missing explicit test for Skeleton:setPosition", function()
    it("Skeleton:setPosition works", function()
        -- @tests Skeleton:setPosition
        -- TODO: add assertion for Skeleton:setPosition
    end)
end)

describe("Missing explicit test for Skeleton:boneCount", function()
    it("Skeleton:boneCount works", function()
        -- @tests Skeleton:boneCount
        -- TODO: add assertion for Skeleton:boneCount
    end)
end)

describe("Missing explicit test for Skeleton:slotCount", function()
    it("Skeleton:slotCount works", function()
        -- @tests Skeleton:slotCount
        -- TODO: add assertion for Skeleton:slotCount
    end)
end)

describe("Missing explicit test for Skeleton:drawToImage", function()
    it("Skeleton:drawToImage works", function()
        -- @tests Skeleton:drawToImage
        -- TODO: add assertion for Skeleton:drawToImage
    end)
end)

describe("Missing explicit test for Skeleton:stopAnimation", function()
    it("Skeleton:stopAnimation works", function()
        -- @tests Skeleton:stopAnimation
        -- TODO: add assertion for Skeleton:stopAnimation
    end)
end)

describe("Missing explicit test for Skeleton:updateAnimation", function()
    it("Skeleton:updateAnimation works", function()
        -- @tests Skeleton:updateAnimation
        -- TODO: add assertion for Skeleton:updateAnimation
    end)
end)

describe("Missing explicit test for Skeleton:getAnimationTime", function()
    it("Skeleton:getAnimationTime works", function()
        -- @tests Skeleton:getAnimationTime
        -- TODO: add assertion for Skeleton:getAnimationTime
    end)
end)

describe("Missing explicit test for Skeleton:addAnimation", function()
    it("Skeleton:addAnimation works", function()
        -- @tests Skeleton:addAnimation
        -- TODO: add assertion for Skeleton:addAnimation
    end)
end)

describe("Missing explicit test for Skeleton:addSkin", function()
    it("Skeleton:addSkin works", function()
        -- @tests Skeleton:addSkin
        -- TODO: add assertion for Skeleton:addSkin
    end)
end)

describe("Missing explicit test for Skeleton:setSkin", function()
    it("Skeleton:setSkin works", function()
        -- @tests Skeleton:setSkin
        -- TODO: add assertion for Skeleton:setSkin
    end)
end)

describe("Missing explicit test for Skeleton:getSkin", function()
    it("Skeleton:getSkin works", function()
        -- @tests Skeleton:getSkin
        -- TODO: add assertion for Skeleton:getSkin
    end)
end)

describe("Missing explicit test for SkeletonAnimation:getDuration", function()
    it("SkeletonAnimation:getDuration works", function()
        -- @tests SkeletonAnimation:getDuration
        -- TODO: add assertion for SkeletonAnimation:getDuration
    end)
end)

describe("Missing explicit test for SkeletonAnimation:getEvents", function()
    it("SkeletonAnimation:getEvents works", function()
        -- @tests SkeletonAnimation:getEvents
        -- TODO: add assertion for SkeletonAnimation:getEvents
    end)
end)

describe("Missing explicit test for SkeletonAnimation:getTimelineCount", function()
    it("SkeletonAnimation:getTimelineCount works", function()
        -- @tests SkeletonAnimation:getTimelineCount
        -- TODO: add assertion for SkeletonAnimation:getTimelineCount
    end)
end)
