-- examples/spine.lua
-- luna.spine — Hierarchical bone skeleton for 2D character animation rigs.
-- Build skeletons at runtime, attach slots, query world transforms, and
-- integrate with the graphics pipeline for frame-by-frame bone-driven rendering.
-- All luna.spine API methods demonstrated with code and comments.

-- ── Creating a Skeleton ───────────────────────────────────────────────────────

-- luna.spine.newSkeleton(name) → Skeleton
-- name: identifier string for this skeleton
local skel = luna.spine.newSkeleton("character")

-- ── Adding Bones ──────────────────────────────────────────────────────────────

-- addBone(name, opts?) → bone_index (integer, 1-based)
-- opts: {x, y, rotation, scale_x, scale_y}  (all optional, default 0/1)
-- Returns the index of the newly added root bone.

local torso_idx = skel:addBone("torso", { x = 0, y = 0, scale_x = 1.0, scale_y = 1.0 })
local head_idx  = skel:addBone("head",  { x = 0, y = 32, rotation = 0.0 })
local arm_l_idx = skel:addBone("arm_l", { x = -24, y = 8 })
local arm_r_idx = skel:addBone("arm_r", { x =  24, y = 8 })

-- addChildBone(name, parent_index, opts?) → bone_index
-- Attach a bone as a child of parent_index.
local forearm_l = skel:addChildBone("forearm_l", arm_l_idx, { x = -20, y = 0, rotation = 0.0 })
local forearm_r = skel:addChildBone("forearm_r", arm_r_idx, { x =  20, y = 0, rotation = 0.0 })
local hand_l    = skel:addChildBone("hand_l",    forearm_l, { x = -12, y = 0 })
local hand_r    = skel:addChildBone("hand_r",    forearm_r, { x =  12, y = 0 })

-- ── Adding Slots ──────────────────────────────────────────────────────────────

-- addSlot(name, bone_index, attachment?) → slot_index
-- attachment is an optional string identifier for the sprite region.
local torso_slot = skel:addSlot("torso_slot", torso_idx, "torso")
local head_slot  = skel:addSlot("head_slot",  head_idx,  "head")
local larm_slot  = skel:addSlot("arm_l_slot", arm_l_idx, "arm")
local rarm_slot  = skel:addSlot("arm_r_slot", arm_r_idx, "arm")

-- ── Querying Bones ────────────────────────────────────────────────────────────

-- findBone(name) → integer?   — look up bone index by name; nil if not found
local found_head = skel:findBone("head")     -- head_idx
local missing    = skel:findBone("unknown")  -- nil

-- findSlot(name) → integer?   — look up slot index by name; nil if not found
local slot_idx = skel:findSlot("torso_slot")

-- boneCount  — total number of bones (property-style accessor)
local bone_n = skel:boneCount()

-- slotCount  — total number of slots
local slot_n = skel:slotCount()

-- ── World Transforms ─────────────────────────────────────────────────────────

-- updateWorldTransforms()  — propagate all local transforms into world space.
-- MUST be called after setting any bone position/rotation before reading getBoneWorld.
skel:updateWorldTransforms()

-- getBoneWorld(bone_index) → {x, y, rotation, scale_x, scale_y} | nil
-- Returns the computed world-space transform for a bone.
-- Returns nil if the index is out of range.
local head_world = skel:getBoneWorld(head_idx)
if head_world then
    print(("head world: x=%.1f y=%.1f rot=%.2f"):format(
        head_world.x, head_world.y, head_world.rotation))
end

-- ── Positioning the Skeleton ──────────────────────────────────────────────────

-- setPosition(x, y)  — moves the entire skeleton root in world space
skel:setPosition(200, 300)

-- Recompute world transforms after repositioning
skel:updateWorldTransforms()

-- ── Typical Game Integration ──────────────────────────────────────────────────

--[[
-- Pre-defined sub-image quads for each body part in the spritesheet
local sprites = {}   -- sprites["head"], sprites["torso"], sprites["arm"], etc.
local sheet         -- luna.gfx.newImage("characters.png")

-- Animate a bone angle over time
local angle = 0
function luna.process(dt)
    angle = angle + dt * 1.5
    -- oscillate the left arm bone
    -- (bone data is stored inside the Rust skeleton; set via opts then update)
    skel:updateWorldTransforms()
end

function luna.render()
    -- Draw each slot's sprite at its bone's world transform
    local n = skel:boneCount()
    for i = 1, n do
        local w = skel:getBoneWorld(i)
        if w then
            -- local quad = sprites[attachment_at_slot(i)]
            -- luna.gfx.draw(sheet, quad, w.x, w.y, w.rotation, w.scale_x, w.scale_y)
        end
    end
end
]]
