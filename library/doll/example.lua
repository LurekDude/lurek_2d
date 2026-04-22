--- Example usage for library.doll.
-- Run from project root with: lua content/library/doll/example.lua
-- This example does NOT call any rendering API; it only assembles a
-- composite doll, builds a sorted draw list, and inspects parts.
-- @module example.doll

package.path = "content/?.lua;content/?/init.lua;" .. package.path
local doll = require("library.doll")

print("[example.doll] === Scenario 1: build a humanoid template ===")

local human = doll.newTemplate("Humanoid")
human:addSocket("body",  "torso", 0,   0, 0, 0)
human:addSocket("head",  "head",  0, -16, 0, 1)
human:addSocket("arm_l", "arm",  -8,  -4, 0, 0)
human:addSocket("arm_r", "arm",   8,  -4, 0, 2)
human:addSocket("weapon","weapon",10, -2, 0, 3)
print(string.format("  template '%s' sockets: %d (%s)",
    human:getName(), human:getSocketCount(),
    table.concat(human:getSocketNames(), ", ")))

print("[example.doll] === Scenario 2: create parts with type filters ===")

local function make_part(type_name, draw_order, color)
    local p = doll.newPart()
    p:setPartType(type_name)
    p:setDrawOrder(draw_order)
    p:setColor(color[1], color[2], color[3], 1)
    p:setAttribute("debug_name", type_name .. "_part")
    return p
end

local torso = make_part("torso",  0, {0.4, 0.6, 0.9})
local head  = make_part("head",   1, {1.0, 0.8, 0.7})
local sword = make_part("weapon", 5, {0.9, 0.9, 0.95})
local arm_l = make_part("arm",    0, {0.4, 0.6, 0.9})
local arm_r = make_part("arm",    2, {0.4, 0.6, 0.9})

print(string.format("  built 5 parts (torso, head, sword, arm_l, arm_r)"))

print("[example.doll] === Scenario 3: instantiate doll & attach parts ===")

local hero = doll.newDoll(human)
hero:setPosition(100, 200)
hero:setRotation(0.0)

local ok_body  = hero:attach("body",   torso)
local ok_head  = hero:attach("head",   head)
local ok_arm_l = hero:attach("arm_l",  arm_l)
local ok_arm_r = hero:attach("arm_r",  arm_r)
local ok_weap  = hero:attach("weapon", sword)
print(string.format("  attaches OK: body=%s head=%s arm_l=%s arm_r=%s weap=%s",
    tostring(ok_body), tostring(ok_head),
    tostring(ok_arm_l), tostring(ok_arm_r), tostring(ok_weap)))

-- Type-mismatch sanity check
local bad = doll.newPart(); bad:setPartType("decal")
local ok_bad = hero:attach("head", bad)  -- "head" socket only accepts "head"
print(string.format("  type-mismatch attach refused: %s", tostring(not ok_bad)))

print("[example.doll] === Scenario 4: empty vs filled sockets ===")

local empty = hero:getEmptySockets()
local filled = hero:getAttachedSockets()
table.sort(filled)
print(string.format("  attached(%d): %s", #filled, table.concat(filled, ", ")))
print(string.format("  empty(%d):    %s", #empty,
    #empty == 0 and "<none>" or table.concat(empty, ", ")))

print("[example.doll] === Scenario 5: get sorted draw list (z-order) ===")

local list = hero:getDrawList()
print(string.format("  draw list entries: %d (sorted by combined draw order)", #list))
for i, entry in ipairs(list) do
    print(string.format("    %d  socket=%-7s type=%-7s order=%-3d at (%.1f,%.1f)",
        i,
        entry.socketName or "?",
        entry.part:getPartType(),
        (entry.drawOrder or 0),
        entry.x or 0, entry.y or 0))
end

print("[example.doll] === Scenario 6: detach & swap weapon ===")

local removed = hero:detach("weapon")
print(string.format("  detached weapon part type=%s", removed and removed:getPartType()))
local axe = make_part("weapon", 6, {0.6, 0.4, 0.2})
axe:setAttribute("name", "Iron Axe")
hero:attach("weapon", axe)
print(string.format("  swapped weapon — new type=%s name=%s",
    hero:getPartAt("weapon"):getPartType(),
    hero:getPartAt("weapon"):getAttribute("name")))

print("[example.doll] done.")
