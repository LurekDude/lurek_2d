--- BDD tests for library.economy
local eco = require("library.economy")

---------------------------------------------------------------------------
-- Resource
---------------------------------------------------------------------------

-- @description Verifies resource defaults, value clamps, flow and reserve math, visibility or locking flags, and per-resource economic state helpers.
describe("Resource", function()
    -- @covers library.economy.newResource
    -- @description Verifies new resources start with the expected name, value, capacity, overflow policy, and visibility or lock defaults.
    it("creates with defaults", function()
        local r = eco.newResource("gold", 1000)
        expect_equal(r:getName(), "gold")
        expect_equal(r:getValue(), 0)
        expect_equal(r:getCapacity(), 1000)
        expect_equal(r:getMinimum(), 0)
        expect_equal(r:getOverflow(), "clamp")
        expect_equal(r:isEnabled(), true)
        expect_equal(r:isVisible(), true)
        expect_equal(r:isLocked(), false)
        expect_equal(r:getReserved(), 0)
    end)

    -- @covers library.economy.newResource
    -- @description Confirms setting a value above capacity clamps the stored value to the configured maximum.
    it("clamps value to capacity", function()
        local r = eco.newResource("hp", 100)
        r:setValue(150)
        expect_equal(r:getValue(), 100)
    end)

    -- @covers library.economy.newResource
    -- @description Confirms resource values also clamp upward to the configured minimum floor.
    it("clamps value to minimum", function()
        local r = eco.newResource("hp", 100)
        r:setMinimum(10)
        r:setValue(5)
        expect_equal(r:getValue(), 10)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies clamp overflow keeps the resource at capacity and returns the excess amount.
    it("add returns excess with clamp overflow", function()
        local r = eco.newResource("gold", 100)
        r:setValue(90)
        local excess = r:add(20)
        expect_equal(r:getValue(), 100)
        expect_equal(excess, 10)
    end)

    -- @covers library.economy.newResource
    -- @description Checks lose overflow rejects additions that would exceed capacity and reports the full rejected amount.
    it("add rejects all with lose overflow", function()
        local r = eco.newResource("gold", 100)
        r:setOverflow("lose")
        r:setValue(90)
        local excess = r:add(20)
        expect_equal(r:getValue(), 90) -- unchanged
        expect_equal(excess, 20) -- full amount returned
    end)

    -- @covers library.economy.newResource
    -- @description Confirms wrap overflow cycles values back through the resource range instead of clamping.
    it("add wraps with wrap overflow", function()
        local r = eco.newResource("gold", 100)
        r:setOverflow("wrap")
        r:setValue(90)
        local excess = r:add(20)
        -- new = 110, range = 100-0 = 100, wrapped = 0 + (110 % 100) = 10
        expect_equal(r:getValue(), 10)
        expect_equal(excess, 0)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies spending succeeds only when enough unreserved value is available and deducts the spent amount.
    it("spend checks available", function()
        local r = eco.newResource("gold", 100)
        r:add(50)
        expect_equal(r:spend(30), true)
        expect_equal(r:getValue(), 20)
        expect_equal(r:spend(30), false) -- can't afford
    end)

    -- @covers library.economy.newResource
    -- @description Checks reservations reduce the spendable balance used by spend and getAvailable.
    it("spend respects reservations", function()
        local r = eco.newResource("gold", 100)
        r:add(50)
        r:reserve(30)
        expect_equal(r:getAvailable(), 20)
        expect_equal(r:spend(25), false) -- only 20 available
        expect_equal(r:spend(20), true)
    end)

    -- @covers library.economy.newResource
    -- @description Confirms locked resources reject both additions and spending while preserving the existing value.
    it("locked resource rejects add and spend", function()
        local r = eco.newResource("gold", 100)
        r:add(50)
        r:setLocked(true)
        expect_equal(r:add(10), 10) -- rejected
        expect_equal(r:getValue(), 50) -- unchanged
        expect_equal(r:spend(10), false) -- rejected
    end)

    -- @covers library.economy.newResource
    -- @description Verifies ticking a resource applies its configured flat flow rate over elapsed time.
    it("tick applies net rate", function()
        local r = eco.newResource("gold", 1000)
        r:add(100)
        r:setFlowRate(10)
        r:tick(1.0)
        expect_equal(r:getValue(), 110)
    end)

    -- @covers library.economy.newResource
    -- @description Checks ticking also combines decay and interest terms into the final net value change.
    it("tick applies decay and interest", function()
        local r = eco.newResource("gold", 1000)
        r:add(100)
        r:setDecayRate(5)
        r:setInterestRate(0.1) -- 10% of value = 10
        r:tick(1.0)
        -- net = 0 - 5 - 0 + 10 - 0 = 5, value = 105
        expect_equal(r:getValue(), 105)
    end)

    -- @covers library.economy.newResource
    -- @description Confirms disabled resources ignore tick updates entirely.
    it("tick does nothing when disabled", function()
        local r = eco.newResource("gold", 1000)
        r:add(100)
        r:setFlowRate(10)
        r:setEnabled(false)
        r:tick(1.0)
        expect_equal(r:getValue(), 100)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies canAfford reflects the currently available, unreserved amount.
    it("canAfford checks available", function()
        local r = eco.newResource("gold", 100)
        r:add(50)
        expect_equal(r:canAfford(50), true)
        expect_equal(r:canAfford(51), false)
    end)

    -- @covers library.economy.newResource
    -- @description Checks unreserving more than the reserved amount clamps reservations back to zero.
    it("unreserve clamps to zero", function()
        local r = eco.newResource("gold", 100)
        r:reserve(10)
        r:unreserve(20)
        expect_equal(r:getReserved(), 0)
    end)

    -- @covers library.economy.newResource
    -- @description Confirms unlimited-capacity resources accept arbitrarily large values when capacity is set to -1.
    it("unlimited capacity (-1)", function()
        local r = eco.newResource("xp", -1)
        r:add(999999)
        expect_equal(r:getValue(), 999999)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies getNetRate combines flat flow, decay, upkeep, interest, and percentage decay into one result.
    it("net rate formula correct", function()
        local r = eco.newResource("gold", 1000)
        r:add(200)
        r:setFlowRate(10)
        r:setDecayRate(3)
        r:setUpkeep(2)
        r:setInterestRate(0.05)  -- 200 * 0.05 = 10
        r:setDecayPercent(0.01)  -- 200 * 0.01 = 2
        -- net = 10 - 3 - 2 + 10 - 2 = 13
        expect_equal(r:getNetRate(), 13)
    end)

    -- @covers library.economy.newResource
    -- @description Checks lowering capacity reclamps the current resource value to the new maximum.
    it("setCapacity reclamps value", function()
        local r = eco.newResource("gold", 200)
        r:add(150)
        r:setCapacity(100)
        expect_equal(r:getValue(), 100)
    end)

    -- @covers library.economy.newResource
    -- @description Confirms the group metadata getter and setter round-trip custom grouping labels.
    it("group getter/setter", function()
        local r = eco.newResource("gold", 100)
        expect_equal(r:getGroup(), "")
        r:setGroup("currency")
        expect_equal(r:getGroup(), "currency")
    end)
end)

---------------------------------------------------------------------------
-- Modifier
---------------------------------------------------------------------------

-- @description Covers modifier creation, duration and expiration behavior, source tagging, and mutable modifier values.
describe("Modifier", function()
    -- @covers library.economy.newModifier
    -- @description Verifies modifiers preserve type, value, duration, permanence, and source defaults on creation.
    it("creates with defaults", function()
        local m = eco.newModifier("add", 5, -1, "buff")
        expect_equal(m:getType(), "add")
        expect_equal(m:getValue(), 5)
        expect_equal(m:getDuration(), -1)
        expect_equal(m:isPermanent(), true)
        expect_equal(m:isExpired(), false)
    end)

    -- @covers library.economy.newModifier
    -- @description Checks finite-duration modifiers expire only after enough elapsed time has been applied.
    it("expires after duration", function()
        local m = eco.newModifier("multiply", 1.5, 3, "potion")
        expect_equal(m:isExpired(), false)
        m:update(2)
        expect_equal(m:isExpired(), false)
        expect_equal(m:getRemaining(), 1)
        m:update(2)
        expect_equal(m:isExpired(), true)
        expect_equal(m:getRemaining(), 0)
    end)

    -- @covers library.economy.newModifier
    -- @description Confirms modifiers can record and return a target resource identifier.
    it("target getter/setter", function()
        local m = eco.newModifier("set", 100, -1, "override")
        m:setTarget("gold")
        expect_equal(m:getTarget(), "gold")
    end)

    -- @covers library.economy.newModifier
    -- @description Verifies unknown modifier types fall back to the multiply type instead of preserving invalid input.
    it("unknown type defaults to multiply", function()
        local m = eco.newModifier("bogus", 2, -1, "")
        expect_equal(m:getType(), "multiply")
    end)
end)

---------------------------------------------------------------------------
-- ConversionRule
---------------------------------------------------------------------------

-- @description Tests conversion rule rates, cooldown timers, reset semantics, and the derived effective-rate path.
describe("ConversionRule", function()
    -- @covers library.economy.newConversionRule
    -- @description Verifies conversion rules expose their endpoints, base rate, fee default, and initial cooldown state.
    it("creates with defaults", function()
        local rule = eco.newConversionRule("gold", "gems", 0.1)
        expect_equal(rule:getFrom(), "gold")
        expect_equal(rule:getTo(), "gems")
        expect_equal(rule:getRate(), 0.1)
        expect_equal(rule:getFee(), 0)
        expect_equal(rule:isOnCooldown(), false)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Confirms conversion-rule cooldowns start, decrement over time, and eventually clear.
    it("cooldown cycle", function()
        local rule = eco.newConversionRule("a", "b", 1)
        rule:setCooldown(5)
        rule:startCooldown()
        expect_equal(rule:isOnCooldown(), true)
        rule:updateCooldown(3)
        expect_equal(rule:isOnCooldown(), true)
        rule:updateCooldown(3)
        expect_equal(rule:isOnCooldown(), false)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Checks additive and multiplicative modifiers both contribute to the effective conversion rate.
    it("effectiveRate with modifiers", function()
        local rule = eco.newConversionRule("a", "b", 10)
        rule:addModifier(eco.newModifier("add", 5, -1, ""))
        rule:addModifier(eco.newModifier("multiply", 2, -1, ""))
        -- effective = (10 + 5) * 2 = 30
        expect_equal(rule:effectiveRate(), 30)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Verifies set modifiers override previously accumulated rate adjustments.
    it("effectiveRate set modifier wins", function()
        local rule = eco.newConversionRule("a", "b", 10)
        rule:addModifier(eco.newModifier("add", 5, -1, ""))
        rule:addModifier(eco.newModifier("set", 42, -1, ""))
        expect_equal(rule:effectiveRate(), 42)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Confirms expired modifiers are ignored when computing a rule's effective rate.
    it("expired modifiers ignored", function()
        local rule = eco.newConversionRule("a", "b", 10)
        local m = eco.newModifier("add", 100, 1, "")
        m:update(2) -- expire it
        rule:addModifier(m)
        expect_equal(rule:effectiveRate(), 10) -- only base
    end)

    -- @covers library.economy.newConversionRule
    -- @description Checks removing and clearing modifiers updates the modifier list as expected.
    it("removeModifier and clearModifiers", function()
        local rule = eco.newConversionRule("a", "b", 10)
        rule:addModifier(eco.newModifier("add", 1, -1, ""))
        rule:addModifier(eco.newModifier("add", 2, -1, ""))
        expect_equal(#rule:getModifiers(), 2)
        rule:removeModifier(1)
        expect_equal(#rule:getModifiers(), 1)
        rule:clearModifiers()
        expect_equal(#rule:getModifiers(), 0)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Verifies conversion rules store and report explicit minimum and maximum allowed source amounts.
    it("min/max amount", function()
        local rule = eco.newConversionRule("a", "b", 1)
        rule:setMinAmount(5)
        rule:setMaxAmount(50)
        expect_equal(rule:getMinAmount(), 5)
        expect_equal(rule:getMaxAmount(), 50)
    end)
end)

---------------------------------------------------------------------------
-- ResourceManager
---------------------------------------------------------------------------

-- @description Exercises manager-level resource creation, transfers, batch spending, exchange, delegation to resource properties, and reset behavior.
describe("ResourceManager", function()
    -- @covers library.economy.newManager
    -- @description Verifies managers can create named resources, report resource existence, and list managed resource names.
    it("creates and manages resources", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 1000)
        mgr:newResource("wood", 500)
        expect_equal(mgr:hasResource("gold"), true)
        expect_equal(mgr:hasResource("iron"), false)
        expect_equal(#mgr:getResourceNames(), 2)
    end)

    -- @covers library.economy.newManager
    -- @description Confirms manager add and spend helpers delegate correctly to the underlying resource values.
    it("add and spend through manager", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 100)
        mgr:add("gold", 50)
        expect_equal(mgr:getValue("gold"), 50)
        expect_equal(mgr:spend("gold", 30), true)
        expect_equal(mgr:getValue("gold"), 20)
    end)

    -- @covers library.economy.newManager
    -- @covers library.economy.newConversionRule
    -- @description Checks managers can execute a conversion rule and move value between source and destination resources.
    it("conversion with rule", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 1000)
        mgr:newResource("gems", 100)
        mgr:add("gold", 500)
        local rule = eco.newConversionRule("gold", "gems", 0.1)
        mgr:addConversionRule(rule)
        local ok = mgr:convert("gold", "gems", 100)
        expect_equal(ok, true)
        expect_equal(mgr:getValue("gold"), 400)
        expect_equal(mgr:getValue("gems"), 10)
    end)

    -- @covers library.economy.newManager
    -- @covers library.economy.newConversionRule
    -- @description Verifies conversion fees are included in the total source amount spent during conversion.
    it("conversion respects fee", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 1000)
        mgr:newResource("gems", 100)
        mgr:add("gold", 500)
        local rule = eco.newConversionRule("gold", "gems", 0.1)
        rule:setFee(10)
        mgr:addConversionRule(rule)
        local ok = mgr:convert("gold", "gems", 100)
        expect_equal(ok, true)
        -- cost = 100 + 10 fee = 110
        expect_equal(mgr:getValue("gold"), 390)
        expect_equal(mgr:getValue("gems"), 10)
    end)

    -- @covers library.economy.newManager
    -- @covers library.economy.newConversionRule
    -- @description Confirms conversion attempts fail while the relevant rule remains on cooldown.
    it("conversion fails on cooldown", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 1000)
        mgr:newResource("gems", 100)
        mgr:add("gold", 500)
        local rule = eco.newConversionRule("gold", "gems", 0.1)
        rule:setCooldown(5)
        mgr:addConversionRule(rule)
        expect_equal(mgr:convert("gold", "gems", 100), true)
        expect_equal(mgr:convert("gold", "gems", 100), false) -- on cooldown
    end)

    -- @covers library.economy.newManager
    -- @covers library.economy.newConversionRule
    -- @description Checks manager conversions enforce conversion rule minimum and maximum amount bounds.
    it("conversion fails outside min/max amount", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 1000)
        mgr:newResource("gems", 100)
        mgr:add("gold", 500)
        local rule = eco.newConversionRule("gold", "gems", 0.1)
        rule:setMinAmount(10)
        rule:setMaxAmount(50)
        mgr:addConversionRule(rule)
        expect_equal(mgr:convert("gold", "gems", 5), false) -- below min
        expect_equal(mgr:convert("gold", "gems", 60), false) -- above max
        expect_equal(mgr:convert("gold", "gems", 20), true) -- within range
    end)

    -- @covers library.economy.newManager
    -- @description Verifies manager ticking advances each managed resource according to its configured rates.
    it("tick advances all resources", function()
        local mgr = eco.newManager()
        local r = mgr:newResource("gold", 1000)
        mgr:add("gold", 100)
        mgr:setFlowRate("gold", 10)
        mgr:tick(1.0)
        expect_equal(mgr:getValue("gold"), 110)
    end)

    -- @covers library.economy.newManager
    -- @covers library.economy.newConversionRule
    -- @description Confirms manager ticking also advances rule cooldowns so later conversions can succeed again.
    it("tick advances cooldowns", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 1000)
        mgr:newResource("gems", 100)
        mgr:add("gold", 500)
        local rule = eco.newConversionRule("gold", "gems", 0.1)
        rule:setCooldown(2)
        mgr:addConversionRule(rule)
        mgr:convert("gold", "gems", 10) -- starts cooldown
        expect_equal(mgr:convert("gold", "gems", 10), false)
        mgr:tick(2)
        expect_equal(mgr:convert("gold", "gems", 10), true)
    end)

    -- @covers library.economy.newManager
    -- @description Checks grouped resource totals sum only resources assigned to the requested group.
    it("totalByGroup sums correctly", function()
        local mgr = eco.newManager()
        local r1 = mgr:newResource("gold", 1000)
        r1:setGroup("currency")
        mgr:add("gold", 100)
        local r2 = mgr:newResource("silver", 1000)
        r2:setGroup("currency")
        mgr:add("silver", 50)
        local r3 = mgr:newResource("wood", 500)
        r3:setGroup("material")
        mgr:add("wood", 200)
        expect_equal(mgr:totalByGroup("currency"), 150)
        expect_equal(mgr:totalByGroup("material"), 200)
    end)

    -- @covers library.economy.newManager
    -- @description Verifies the manager percent helper reports the resource fill percentage from current value and capacity.
    it("getPercent returns value/cap * 100", function()
        local mgr = eco.newManager()
        mgr:newResource("hp", 200)
        mgr:add("hp", 100)
        expect_equal(mgr:getPercent("hp"), 50)
    end)

    -- @covers library.economy.newManager
    -- @description Confirms manager isFull and isEmpty delegate to the current state of the named resource.
    it("isFull and isEmpty", function()
        local mgr = eco.newManager()
        mgr:newResource("hp", 100)
        expect_equal(mgr:isEmpty("hp"), true)
        expect_equal(mgr:isFull("hp"), false)
        mgr:add("hp", 100)
        expect_equal(mgr:isFull("hp"), true)
        expect_equal(mgr:isEmpty("hp"), false)
    end)

    -- @covers library.economy.newManager
    -- @description Checks canAffordAll and spendAll validate and deduct batches of resource requirements atomically.
    it("canAffordAll and spendAll", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 1000)
        mgr:newResource("wood", 500)
        mgr:add("gold", 100)
        mgr:add("wood", 50)
        local needs = { gold = 50, wood = 30 }
        expect_equal(mgr:canAffordAll(needs), true)
        expect_equal(mgr:spendAll(needs), true)
        expect_equal(mgr:getValue("gold"), 50)
        expect_equal(mgr:getValue("wood"), 20)
        -- can't afford again
        expect_equal(mgr:spendAll(needs), false)
    end)

    -- @covers library.economy.newManager
    -- @description Verifies removing a resource drops it from manager lookup and existence checks.
    it("removeResource removes", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 100)
        expect_equal(mgr:hasResource("gold"), true)
        mgr:removeResource("gold")
        expect_equal(mgr:hasResource("gold"), false)
    end)

    -- @covers library.economy.newManager
    -- @description Confirms reset clears both managed resources and registered conversion rules.
    it("reset clears everything", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 100)
        mgr:addConversionRule(eco.newConversionRule("a", "b", 1))
        mgr:reset()
        expect_equal(mgr:hasResource("gold"), false)
        expect_equal(#mgr:getConversionRules(), 0)
    end)

    -- @covers library.economy.newManager
    -- @description Checks exchanges transfer both requested resources atomically when both sides can afford the trade.
    it("exchange atomically swaps", function()
        local mgr1 = eco.newManager()
        local mgr2 = eco.newManager()
        mgr1:newResource("gold", 1000)
        mgr1:newResource("wood", 1000)
        mgr2:newResource("gold", 1000)
        mgr2:newResource("wood", 1000)
        mgr1:add("gold", 100)
        mgr2:add("wood", 200)
        local ok = mgr1:exchange(mgr2, "gold", 50, "wood", 100)
        expect_equal(ok, true)
        expect_equal(mgr1:getValue("gold"), 50)
        expect_equal(mgr1:getValue("wood"), 100)
        expect_equal(mgr2:getValue("wood"), 100)
        expect_equal(mgr2:getValue("gold"), 50)
    end)

    -- @covers library.economy.newManager
    -- @description Verifies exchange fails cleanly when either manager lacks enough of the offered resource.
    it("exchange fails if either side can't afford", function()
        local mgr1 = eco.newManager()
        local mgr2 = eco.newManager()
        mgr1:newResource("gold", 1000)
        mgr2:newResource("wood", 1000)
        mgr1:add("gold", 10)
        mgr2:add("wood", 5)
        expect_equal(mgr1:exchange(mgr2, "gold", 100, "wood", 5), false)
    end)

    -- @covers library.economy.newManager
    -- @description Confirms manager delegation helpers update overflow policy, group, enabled state, and locked state on a resource.
    it("manager delegation: overflow, group, enabled, locked", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 100)
        mgr:setOverflow("gold", "lose")
        expect_equal(mgr:getOverflow("gold"), "lose")
        mgr:setGroup("gold", "money")
        expect_equal(mgr:getGroup("gold"), "money")
        mgr:setEnabled("gold", false)
        expect_equal(mgr:isEnabled("gold"), false)
        mgr:setLocked("gold", true)
        expect_equal(mgr:isLocked("gold"), true)
    end)

    -- @covers library.economy.newManager
    -- @description Checks manager reserve helpers keep reserved and available amounts in sync.
    it("manager delegation: reserve/unreserve", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 100)
        mgr:add("gold", 80)
        mgr:reserveAmount("gold", 30)
        expect_equal(mgr:getReserved("gold"), 30)
        expect_equal(mgr:getAvailable("gold"), 50)
        mgr:unreserveAmount("gold", 10)
        expect_equal(mgr:getReserved("gold"), 20)
    end)
end)

---------------------------------------------------------------------------
-- Additional coverage tests
---------------------------------------------------------------------------

-- @description Adds focused coverage for modifier source metadata and direct value mutation helpers.
describe("Modifier (extra coverage)", function()
    -- @covers library.economy.newModifier
    -- @description Verifies modifiers retain the source tag they were constructed with.
    it("getSource returns source tag", function()
        local m = eco.newModifier("add", 5, -1, "ironforge")
        expect_equal(m:getSource(), "ironforge")
    end)

    -- @covers library.economy.newModifier
    -- @description Confirms modifier values can be updated after construction through setValue.
    it("setValue updates the modifier value", function()
        local m = eco.newModifier("add", 5, -1, "")
        m:setValue(42)
        expect_equal(m:getValue(), 42)
    end)
end)

-- @description Extends conversion rule coverage around cooldown getters, explicit rate updates, and cooldown reset.
describe("ConversionRule (extra coverage)", function()
    -- @covers library.economy.newConversionRule
    -- @description Checks the cooldown getter returns the configured conversion-rule cooldown duration.
    it("getCooldown returns configured cooldown", function()
        local rule = eco.newConversionRule("a", "b", 1)
        rule:setCooldown(3)
        expect_equal(rule:getCooldown(), 3)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Verifies setRate updates both the base rate and the effective rate when no modifiers are active.
    it("setRate updates the base rate", function()
        local rule = eco.newConversionRule("a", "b", 1)
        rule:setRate(5)
        expect_equal(rule:getRate(), 5)
        expect_equal(rule:effectiveRate(), 5)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Confirms resetCooldown clears an active conversion cooldown immediately.
    it("resetCooldown clears mid-cooldown timer", function()
        local rule = eco.newConversionRule("a", "b", 1)
        rule:setCooldown(10)
        rule:startCooldown()
        expect_equal(rule:isOnCooldown(), true)
        rule:resetCooldown()
        expect_equal(rule:isOnCooldown(), false)
    end)
end)

-- @description Adds manager coverage for turn updates, net-rate access, visibility, affordability, and delegated percentage or capacity setters.
describe("ResourceManager (extra coverage)", function()
    -- @covers library.economy.newManager
    -- @description Verifies turn advances resource simulation by a fixed one-second step.
    it("turn() advances resources by one second", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 1000)
        mgr:add("gold", 100)
        mgr:setFlowRate("gold", 10)
        mgr:turn()
        expect_equal(mgr:getValue("gold"), 110)
    end)

    -- @covers library.economy.newManager
    -- @description Checks getNetRate delegates the computed net rate of a named resource through the manager.
    it("getNetRate delegates to resource", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 1000)
        mgr:add("gold", 200)
        mgr:setFlowRate("gold", 10)
        mgr:setDecayRate("gold", 3)
        -- net = 10 - 3 = 7
        expect_equal(mgr:getNetRate("gold"), 7)
    end)

    -- @covers library.economy.newManager
    -- @description Confirms manager visibility helpers round-trip the visibility state of a resource.
    it("isVisible and setVisible delegate correctly", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 100)
        expect_equal(mgr:isVisible("gold"), true)
        mgr:setVisible("gold", false)
        expect_equal(mgr:isVisible("gold"), false)
    end)

    -- @covers library.economy.newManager
    -- @description Verifies manager canAfford delegates resource affordability and returns false for missing resources.
    it("canAfford delegates to resource available", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 100)
        mgr:add("gold", 50)
        expect_equal(mgr:canAfford("gold", 50), true)
        expect_equal(mgr:canAfford("gold", 51), false)
        -- non-existent resource returns false
        expect_equal(mgr:canAfford("iron", 1), false)
    end)

    -- @covers library.economy.newManager
    -- @description Checks decay-percent delegation updates and reports percentage-based decay on a resource.
    it("getDecayPercent/setDecayPercent delegate", function()
        local mgr = eco.newManager()
        mgr:newResource("mana", 500)
        mgr:setDecayPercent("mana", 0.05)
        expect_equal(mgr:getDecayPercent("mana"), 0.05)
    end)

    -- @covers library.economy.newManager
    -- @description Verifies interest-rate delegation updates and returns interest settings for a resource.
    it("getInterestRate/setInterestRate delegate", function()
        local mgr = eco.newManager()
        mgr:newResource("bank", 10000)
        mgr:setInterestRate("bank", 0.02)
        expect_equal(mgr:getInterestRate("bank"), 0.02)
    end)

    -- @covers library.economy.newManager
    -- @description Confirms upkeep delegation round-trips upkeep costs through the manager surface.
    it("getUpkeep/setUpkeep delegate", function()
        local mgr = eco.newManager()
        mgr:newResource("food", 200)
        mgr:setUpkeep("food", 5)
        expect_equal(mgr:getUpkeep("food"), 5)
    end)

    -- @covers library.economy.newManager
    -- @description Checks capacity delegation updates and reports the maximum capacity of a managed resource.
    it("getCapacity/setCapacity delegate", function()
        local mgr = eco.newManager()
        mgr:newResource("wood", 100)
        mgr:setCapacity("wood", 500)
        expect_equal(mgr:getCapacity("wood"), 500)
    end)

    -- @covers library.economy.newManager
    -- @description Verifies minimum-value delegation updates and reports a resource's lower clamp.
    it("getMinimum/setMinimum delegate", function()
        local mgr = eco.newManager()
        mgr:newResource("hp", 100)
        mgr:setMinimum("hp", 10)
        expect_equal(mgr:getMinimum("hp"), 10)
    end)

    -- @covers library.economy.newManager
    -- @description Confirms reserved and available amounts stay consistent after reserving and unreserving through the manager.
    it("getReserved/getAvailable consistent with reserveAmount/unreserveAmount", function()
        local mgr = eco.newManager()
        mgr:newResource("gold", 1000)
        mgr:add("gold", 100)
        mgr:reserveAmount("gold", 40)
        expect_equal(mgr:getReserved("gold"), 40)
        expect_equal(mgr:getAvailable("gold"), 60)
        mgr:unreserveAmount("gold", 15)
        expect_equal(mgr:getReserved("gold"), 25)
    end)
end)

-- @description Confirms exported overflow and modifier enums expose the expected string constants used by resource logic.
describe("Enum constants", function()
    -- @covers library.economy.OverflowPolicy
    -- @covers library.economy.ModifierType
    -- @description Verifies the exported overflow-policy enum matches the string values used by resource overflow handling.
    it("OverflowPolicy values are correct strings", function()
        expect_equal(eco.OverflowPolicy.CLAMP, "clamp")
        expect_equal(eco.OverflowPolicy.LOSE,  "lose")
        expect_equal(eco.OverflowPolicy.WRAP,  "wrap")
    end)

    -- @covers library.economy.ModifierType
    -- @description Confirms the exported modifier-type enum matches the strings used by modifier evaluation.
    it("ModifierType values are correct strings", function()
        expect_equal(eco.ModifierType.MULTIPLY, "multiply")
        expect_equal(eco.ModifierType.ADD,      "add")
        expect_equal(eco.ModifierType.SET,      "set")
    end)
end)

---------------------------------------------------------------------------
-- Bug-fix regression tests
---------------------------------------------------------------------------

-- @description Regression tests for bugs found in audit: decay clamping, set-modifier short-circuit,
-- expired conversion rates, wrap overflow edge case, and reserve bounds.
describe("Bug-fix regressions", function()
    -- @covers library.economy.newResource
    -- @description Verifies getNetRate clamps so resource cannot go below minimum even with heavy decay.
    it("getNetRate clamps to prevent going below minimum", function()
        local r = eco.newResource("energy", 100)
        r:add(10)
        r:setMinimum(0)
        r:setDecayPercent(5.0) -- 500% per second — way more than value
        local net = r:getNetRate()
        -- net should be clamped to -(value - minimum) = -10
        expect_equal(net, -10)
        -- After tick, value should be at minimum, not negative
        r:tick(1.0)
        expect_equal(r:getValue(), 0)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies getNetRate clamps with non-zero minimum floor.
    it("getNetRate clamps to non-zero minimum", function()
        local r = eco.newResource("hp", 100)
        r:add(15)
        r:setMinimum(10)
        r:setDecayRate(100) -- massive flat decay
        local net = r:getNetRate()
        -- net should be clamped to -(15 - 10) = -5
        expect_equal(net, -5)
        r:tick(1.0)
        expect_equal(r:getValue(), 10)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Verifies set-modifier short-circuit: when a set modifier exists, add/multiply do not affect the rate.
    it("effectiveRate short-circuits on set modifier", function()
        local rule = eco.newConversionRule("a", "b", 10)
        rule:addModifier(eco.newModifier("add", 100, -1, "big_add"))
        rule:addModifier(eco.newModifier("multiply", 50, -1, "big_mul"))
        rule:addModifier(eco.newModifier("set", 7, -1, "override"))
        -- set wins regardless of add/multiply
        expect_equal(rule:effectiveRate(), 7)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Verifies expired set modifier does NOT override the base rate.
    it("expired set modifier does not override rate", function()
        local rule = eco.newConversionRule("a", "b", 10)
        local m = eco.newModifier("set", 999, 1, "temp_override")
        m:update(2) -- expire it
        rule:addModifier(m)
        -- expired set should be ignored, base rate applies
        expect_equal(rule:effectiveRate(), 10)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Verifies effectiveRate ignores expired set but uses non-expired add/multiply.
    it("effectiveRate with mixed expired set and live add", function()
        local rule = eco.newConversionRule("a", "b", 10)
        local set_mod = eco.newModifier("set", 999, 1, "expired_set")
        set_mod:update(2) -- expire
        rule:addModifier(set_mod)
        rule:addModifier(eco.newModifier("add", 5, -1, "live_add"))
        -- expired set ignored, add applies: (10 + 5) * 1 = 15
        expect_equal(rule:effectiveRate(), 15)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies wrap overflow handles degenerate case where capacity < minimum.
    it("wrap overflow with capacity < minimum clamps safely", function()
        local r = eco.newResource("test", 5)
        r:setOverflow("wrap")
        r:setMinimum(10) -- degenerate: minimum > capacity
        r:setValue(5) -- _clamp gives capacity=5
        local excess = r:add(10)
        -- With degenerate range, should clamp safely, not crash or produce NaN
        expect_equal(excess, 0)
        -- Value should be something valid (clamped)
        local v = r:getValue()
        expect_equal(type(v), "number")
        expect_equal(v == v, true) -- not NaN
    end)

    -- @covers library.economy.newResource
    -- @description Verifies wrap overflow with capacity == minimum (zero range) clamps safely.
    it("wrap overflow with zero range (capacity == minimum)", function()
        local r = eco.newResource("test", 10)
        r:setOverflow("wrap")
        r:setMinimum(10) -- range = 0
        r:setValue(10)
        local excess = r:add(5)
        expect_equal(excess, 0)
        expect_equal(r:getValue(), 10)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies reserve clamps so reserved cannot exceed current value.
    it("reserve clamps to value", function()
        local r = eco.newResource("gold", 100)
        r:add(30)
        r:reserve(50) -- try to reserve more than value
        expect_equal(r:getReserved(), 30) -- clamped to value
        expect_equal(r:getAvailable(), 0)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies unreserve clamps reserved to value after value decreases.
    it("unreserve clamps reserved to value", function()
        local r = eco.newResource("gold", 100)
        r:add(50)
        r:reserve(40)
        expect_equal(r:getReserved(), 40)
        -- Now unreserve a small amount — reserved stays within value
        r:unreserve(5)
        expect_equal(r:getReserved(), 35)
    end)
end)

---------------------------------------------------------------------------
-- Input validation tests
---------------------------------------------------------------------------

-- @description Validates that factory functions reject invalid inputs with clear error messages.
describe("Input validation", function()
    -- @covers library.economy.newResource
    -- @description Verifies newResource rejects nil and empty-string names.
    it("newResource rejects nil name", function()
        expect_error(function() eco.newResource(nil, 100) end)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies newResource rejects empty-string names.
    it("newResource rejects empty name", function()
        expect_error(function() eco.newResource("", 100) end)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies newResource rejects invalid capacity.
    it("newResource rejects capacity below -1", function()
        expect_error(function() eco.newResource("gold", -2) end)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies add rejects negative amounts.
    it("add rejects negative amount", function()
        local r = eco.newResource("gold", 100)
        expect_error(function() r:add(-5) end)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies spend rejects negative amounts.
    it("spend rejects negative amount", function()
        local r = eco.newResource("gold", 100)
        r:add(50)
        expect_error(function() r:spend(-5) end)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies reserve rejects negative amounts.
    it("reserve rejects negative amount", function()
        local r = eco.newResource("gold", 100)
        expect_error(function() r:reserve(-5) end)
    end)

    -- @covers library.economy.newResource
    -- @description Verifies unreserve rejects negative amounts.
    it("unreserve rejects negative amount", function()
        local r = eco.newResource("gold", 100)
        expect_error(function() r:unreserve(-5) end)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Verifies newConversionRule rejects empty source name.
    it("newConversionRule rejects empty from", function()
        expect_error(function() eco.newConversionRule("", "b", 1) end)
    end)

    -- @covers library.economy.newConversionRule
    -- @description Verifies newConversionRule rejects empty target name.
    it("newConversionRule rejects empty to", function()
        expect_error(function() eco.newConversionRule("a", "", 1) end)
    end)
end)
test_summary()
