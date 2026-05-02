-- test_evidence_spine.lua
-- Evidence test: Spine skeleton creation, bone hierarchy, and rendering

local OUT = "tests/output/spine/"

describe("Evidence: Spine skeleton", function()

    -- @evidence file
    it("renders a stick figure skeleton", function()
        local sk = lurek.spine.newSkeleton("stick_figure")

        -- Build a simple biped skeleton
        local torso = sk:addBone("torso",  { length = 50 })
        local head  = sk:addChildBone("head",   torso, { length = 20, rotation = 0 })
        local hip   = sk:addChildBone("hip",    torso, { length = 10, rotation = 180 })
        local l_arm = sk:addChildBone("l_arm",  torso, { length = 35, rotation = -45 })
        local r_arm = sk:addChildBone("r_arm",  torso, { length = 35, rotation = 45 })
        local l_leg = sk:addChildBone("l_leg",  hip,   { length = 40, rotation = 160 })
        local r_leg = sk:addChildBone("r_leg",  hip,   { length = 40, rotation = 200 })
        local l_lo  = sk:addChildBone("l_lower", l_leg, { length = 40, rotation = 20 })
        local r_lo  = sk:addChildBone("r_lower", r_leg, { length = 40, rotation = -20 })

        -- Add slots for attachments
        sk:addSlot("head_slot",  head,  "circle")
        sk:addSlot("body_slot",  torso, "rect")

        sk:setPosition(128, 80)
        sk:updateWorldTransforms()

        local img = sk:drawToImage(256, 256)
        lurek.image.savePNG(img, OUT .. "skeleton_stick_figure.png")
    end)

    -- @evidence file
    it("demonstrates bone world-transform queries", function()
        local sk = lurek.spine.newSkeleton("query_test")
        local root = sk:addBone("root",  { length = 40 })
        local child = sk:addChildBone("child", root, { length = 30, rotation = 45 })

        sk:setPosition(64, 64)
        sk:updateWorldTransforms()

        local world = sk:getBoneWorld(root)
        if world then
        end

        local img = sk:drawToImage(128, 128)
        lurek.image.savePNG(img, OUT .. "bone_operations.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_spine.lua
-- ================================================================

-- test_evidence_spine.lua
-- Evidence test: Spine skeleton creation, bone hierarchy, and rendering

local OUT = "tests/output/spine/"

describe("Evidence: Spine skeleton", function()

    -- @evidence file
    it("renders a stick figure skeleton", function()
        local sk = lurek.spine.newSkeleton("stick_figure")

        -- Build a simple biped skeleton
        local torso = sk:addBone("torso",  { length = 50 })
        local head  = sk:addChildBone("head",   torso, { length = 20, rotation = 0 })
        local hip   = sk:addChildBone("hip",    torso, { length = 10, rotation = 180 })
        local l_arm = sk:addChildBone("l_arm",  torso, { length = 35, rotation = -45 })
        local r_arm = sk:addChildBone("r_arm",  torso, { length = 35, rotation = 45 })
        local l_leg = sk:addChildBone("l_leg",  hip,   { length = 40, rotation = 160 })
        local r_leg = sk:addChildBone("r_leg",  hip,   { length = 40, rotation = 200 })
        local l_lo  = sk:addChildBone("l_lower", l_leg, { length = 40, rotation = 20 })
        local r_lo  = sk:addChildBone("r_lower", r_leg, { length = 40, rotation = -20 })

        -- Add slots for attachments
        sk:addSlot("head_slot",  head,  "circle")
        sk:addSlot("body_slot",  torso, "rect")

        sk:setPosition(128, 80)
        sk:updateWorldTransforms()

        local img = sk:drawToImage(256, 256)
        lurek.image.savePNG(img, OUT .. "skeleton_stick_figure.png")
    end)

    -- @evidence file
    it("demonstrates bone world-transform queries", function()
        local sk = lurek.spine.newSkeleton("query_test")
        local root = sk:addBone("root",  { length = 40 })
        local child = sk:addChildBone("child", root, { length = 30, rotation = 45 })

        sk:setPosition(64, 64)
        sk:updateWorldTransforms()

        local world = sk:getBoneWorld(root)
        if world then
        end

        local img = sk:drawToImage(128, 128)
        lurek.image.savePNG(img, OUT .. "bone_operations.png")
    end)

end)
test_summary()
