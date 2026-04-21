--- Example usage for library.economy.
-- Run from project root with: lua content/library/economy/example.lua
-- @module example.economy

package.path = "content/?.lua;content/?/init.lua;" .. package.path
local economy = require("library.economy")

print("[example.economy] === Scenario 1: a single resource with capacity ===")

local gold = economy.newResource("gold", 1000)  -- capacity 1000
gold:setValue(250)
print(string.format("  gold value=%.0f cap=%d available=%.0f",
    gold:getValue(), gold:getCapacity(), gold:getAvailable()))

local excess = gold:add(900)
print(string.format("  add 900 -> value=%.0f, excess=%.0f (clamped to capacity)",
    gold:getValue(), excess))

local spent = gold:spend(120)
print(string.format("  spend 120 -> ok=%s value=%.0f",
    tostring(spent), gold:getValue()))

print("[example.economy] === Scenario 2: flow + decay tick ===")

local mana = economy.newResource("mana", 100)
mana:setValue(50)
mana:setFlowRate(5)     -- +5 per second regen
mana:setDecayRate(1)    -- -1 per second drain
for t = 1, 4 do
    mana:tick(1.0)
    print(string.format("  tick %d  mana=%.1f net=%.1f/s",
        t, mana:getValue(), mana:getNetRate()))
end

print("[example.economy] === Scenario 3: reserve / unreserve ===")

local wood = economy.newResource("wood", -1)  -- unbounded
wood:setValue(80)
wood:reserve(30)
print(string.format("  value=%.0f reserved=%.0f available=%.0f",
    wood:getValue(), wood.reserved, wood:getAvailable()))
wood:unreserve(10)
print(string.format("  after unreserve(10): available=%.0f", wood:getAvailable()))

print("[example.economy] === Scenario 4: ResourceManager + conversion rule ===")

local mgr = economy.newManager()
mgr:newResource("ore",   500):setValue(100)
mgr:newResource("ingot", 500):setValue(0)

-- 2 ore -> 1 ingot, fee 0
local rule = economy.newConversionRule("ore", "ingot", 0.5)
rule.min_amount = 2
rule.max_amount = 100
mgr:addConversionRule(rule)

local ok = mgr:convert("ore", "ingot", 20)
print(string.format("  convert 20 ore -> ingot: ok=%s, ore=%.0f, ingot=%.0f",
    tostring(ok),
    mgr:getResource("ore"):getValue(),
    mgr:getResource("ingot"):getValue()))

print("[example.economy] === Scenario 5: tick all resources via manager ===")

mgr:newResource("food", 100):setValue(20)
mgr:getResource("food"):setFlowRate(2)
mgr:getResource("food"):setDecayPercent(0.05)  -- 5% drain per second
for t = 1, 3 do
    mgr:tick(1.0)
    print(string.format("  tick %d  food=%.2f", t, mgr:getResource("food"):getValue()))
end
print("  resources tracked: " .. table.concat(mgr:getResourceNames(), ", "))

print("[example.economy] === Scenario 6: optional event bus & codec snapshot ===")

local bus = mgr:getEventBus()
if bus then
    bus:on("spent", function(name, amount)
        print(string.format("  [bus] spent %.0f from %s", amount, name))
    end)
    bus:emit("spent", "gold", 50)  -- caller-side emit
else
    print("  no lurek.patterns.newEventBus — bus disabled (pure-Lua mode)")
end

local ok_codec, codec = pcall(require, "lurek.serial")
if ok_codec and codec and codec.toJson then
    local snap = {}
    for _, n in ipairs(mgr:getResourceNames()) do
        snap[n] = mgr:getResource(n):getValue()
    end
    print("  codec.toJson snapshot: " .. codec.toJson(snap))
else
    local parts = {}
    for _, n in ipairs(mgr:getResourceNames()) do
        parts[#parts+1] = string.format("%s=%.1f", n, mgr:getResource(n):getValue())
    end
    print("  no lurek.serial — manual snapshot: { " .. table.concat(parts, ", ") .. " }")
end

print("[example.economy] done.")
