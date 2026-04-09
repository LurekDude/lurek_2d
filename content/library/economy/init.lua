--- @module library.economy
--- @description Pure-Lua resource economy system with named resources, overflow policies,
--- flow/decay/interest simulation, conversion rules with modifiers, and a ResourceManager.
--- Port of the Rust src/economy/ module.
local M = {}

---------------------------------------------------------------------------
-- OverflowPolicy helpers
---------------------------------------------------------------------------

local OVERFLOW_POLICIES = { clamp = true, lose = true, wrap = true }

--- Validate an overflow-policy string; defaults to "clamp".
--- @tparam string s
--- @treturn string
local function validate_overflow(s)
    if OVERFLOW_POLICIES[s] then return s end
    return "clamp"
end

---------------------------------------------------------------------------
-- Resource
---------------------------------------------------------------------------

local Resource = {}
Resource.__index = Resource

--- Create a new named resource.
--- @tparam string name   Resource name.
--- @tparam number capacity   Maximum value (-1 = unlimited).
--- @treturn Resource
function M.newResource(name, capacity)
    local r = setmetatable({}, Resource)
    r.name        = name or "resource"
    r.value       = 0
    r.capacity    = capacity or -1
    r.minimum     = 0
    r.flow_rate   = 0
    r.decay_rate  = 0
    r.decay_percent = 0
    r.interest_rate = 0
    r.upkeep      = 0
    r.overflow    = "clamp"
    r.group       = ""
    r.enabled     = true
    r.visible     = true
    r.locked      = false
    r.reserved    = 0
    return r
end

--- Clamp a value to [minimum, capacity].
function Resource:_clamp(v)
    if v < self.minimum then v = self.minimum end
    if self.capacity >= 0 and v > self.capacity then v = self.capacity end
    return v
end

--- @treturn string Resource name.
function Resource:getName() return self.name end

--- @treturn number Current resource value.
function Resource:getValue() return self.value end

--- Set the resource value (clamped).
--- @tparam number v
function Resource:setValue(v)
    self.value = self:_clamp(v)
end

--- @treturn number Capacity (-1 = unlimited).
function Resource:getCapacity() return self.capacity end

--- Set maximum capacity. Re-clamps value.
--- @tparam number c
function Resource:setCapacity(c)
    self.capacity = c
    self.value = self:_clamp(self.value)
end

--- @treturn number Minimum value.
function Resource:getMinimum() return self.minimum end

--- Set minimum value. Re-clamps value.
--- @tparam number m
function Resource:setMinimum(m)
    self.minimum = m
    self.value = self:_clamp(self.value)
end

--- @treturn string Overflow policy ("clamp", "lose", or "wrap").
function Resource:getOverflow() return self.overflow end

--- Set overflow policy.
--- @tparam string p  One of "clamp", "lose", "wrap".
function Resource:setOverflow(p) self.overflow = validate_overflow(p) end

--- @treturn number Flow rate per tick.
function Resource:getFlowRate() return self.flow_rate end

--- Set the per-second flow rate (income).
--- @tparam number r Flow rate.
function Resource:setFlowRate(r) self.flow_rate = r end

--- @treturn number Flat decay rate per tick.
function Resource:getDecayRate() return self.decay_rate end

--- Set the per-second flat decay rate.
--- @tparam number r Decay rate.
function Resource:setDecayRate(r) self.decay_rate = r end

--- @treturn number Proportional decay rate per tick.
function Resource:getDecayPercent() return self.decay_percent end

--- Set the per-second proportional decay (0.1 = 10%/s).
--- @tparam number p Decay percent.
function Resource:setDecayPercent(p) self.decay_percent = p end

--- @treturn number Interest rate per tick.
function Resource:getInterestRate() return self.interest_rate end

--- Set the per-second proportional interest rate.
--- @tparam number r Interest rate.
function Resource:setInterestRate(r) self.interest_rate = r end

--- @treturn number Upkeep cost per turn.
function Resource:getUpkeep() return self.upkeep end

--- Set the per-second upkeep cost.
--- @tparam number u Upkeep cost.
function Resource:setUpkeep(u) self.upkeep = u end

--- @treturn string Resource group.
function Resource:getGroup() return self.group end

--- Set the group tag for this resource.
--- @tparam string g Group name.
function Resource:setGroup(g) self.group = g or "" end

--- @treturn boolean True if tick processing is enabled.
function Resource:isEnabled() return self.enabled end

--- Enable or disable tick processing.
--- @tparam boolean e Enabled state.
function Resource:setEnabled(e) self.enabled = e end

--- @treturn boolean UI visibility hint.
function Resource:isVisible() return self.visible end

--- Set the UI visibility hint.
--- @tparam boolean v Visibility.
function Resource:setVisible(v) self.visible = v end

--- @treturn boolean True if add/spend is blocked.
function Resource:isLocked() return self.locked end

--- Lock or unlock add/spend modifications.
--- @tparam boolean l Locked state.
function Resource:setLocked(l) self.locked = l end

--- @treturn number Amount currently reserved.
function Resource:getReserved() return self.reserved end

--- @treturn number Available = value - reserved.
function Resource:getAvailable() return self.value - self.reserved end

--- Net rate per tick (flow - decay - upkeep + interest - proportional_decay).
--- @treturn number
function Resource:getNetRate()
    return self.flow_rate - self.decay_rate - self.upkeep
           + (self.value * self.interest_rate)
           - (self.value * self.decay_percent)
end

--- Add amount to the resource. Returns the excess.
--- @tparam number amount
--- @treturn number excess
function Resource:add(amount)
    if self.locked then return amount end
    local new = self.value + amount
    if self.overflow == "lose" then
        if self.capacity >= 0 and new > self.capacity then
            return amount -- entire addition rejected
        end
        self.value = self:_clamp(new)
        return 0
    elseif self.overflow == "wrap" then
        if self.capacity >= 0 and new > self.capacity then
            local range = self.capacity - self.minimum
            if range > 0 then
                self.value = self.minimum + ((new - self.minimum) % range)
            else
                self.value = self.minimum
            end
        else
            self.value = self:_clamp(new)
        end
        return 0
    else -- "clamp"
        local clamped = self:_clamp(new)
        local excess = new - clamped
        if excess < 0 then excess = 0 end
        self.value = clamped
        return excess
    end
end

--- Spend an amount if available. Returns true on success.
--- @tparam number amount
--- @treturn boolean
function Resource:spend(amount)
    if self.locked then return false end
    if self:getAvailable() < amount then return false end
    self.value = self.value - amount
    return true
end

--- Check if the resource can afford the amount.
--- @tparam number amount
--- @treturn boolean
function Resource:canAfford(amount)
    return (not self.locked) and self:getAvailable() >= amount
end

--- Reserve an amount (reduces available without changing value).
--- @tparam number amount
function Resource:reserve(amount)
    self.reserved = self.reserved + amount
end

--- Release a reservation.
--- @tparam number amount
function Resource:unreserve(amount)
    self.reserved = self.reserved - amount
    if self.reserved < 0 then self.reserved = 0 end
end

--- Advance the resource by dt seconds (flow, decay, interest, proportional decay).
--- @tparam number dt
function Resource:tick(dt)
    if not self.enabled then return end
    self.value = self:_clamp(self.value + self:getNetRate() * dt)
end

---------------------------------------------------------------------------
-- ModifierType helpers
---------------------------------------------------------------------------

local MODIFIER_TYPES = { multiply = true, add = true, set = true }

local function validate_mod_type(s)
    if MODIFIER_TYPES[s] then return s end
    return "multiply"
end

---------------------------------------------------------------------------
-- Modifier
---------------------------------------------------------------------------

local Modifier = {}
Modifier.__index = Modifier

--- Create a new modifier.
--- @tparam string mod_type  "multiply", "add", or "set".
--- @tparam number value     Modifier value.
--- @tparam number duration  Duration (<= 0 = permanent).
--- @tparam string source    Source tag.
--- @treturn Modifier
function M.newModifier(mod_type, value, duration, source)
    local m = setmetatable({}, Modifier)
    m.mod_type  = validate_mod_type(mod_type or "multiply")
    m.value     = value or 0
    m.duration  = duration or -1
    m.remaining = (m.duration > 0) and m.duration or 0
    m.source    = source or ""
    m.target    = ""
    return m
end

--- Return the modifier type ("multiply", "add", or "set").
--- @treturn string
function Modifier:getType()      return self.mod_type end

--- Return the modifier value.
--- @treturn number
function Modifier:getValue()     return self.value end

--- Set the modifier value.
--- @tparam number v New value.
function Modifier:setValue(v)    self.value = v end

--- Return the total duration (<= 0 = permanent).
--- @treturn number
function Modifier:getDuration()  return self.duration end

--- Return remaining time before expiry.
--- @treturn number
function Modifier:getRemaining() return self.remaining end

--- Return the source tag.
--- @treturn string
function Modifier:getSource()    return self.source end

--- Return the target identifier.
--- @treturn string
function Modifier:getTarget()    return self.target end

--- Set the target identifier.
--- @tparam string t Target name.
function Modifier:setTarget(t)   self.target = t or "" end

--- Return true if the modifier has expired.
--- @treturn boolean
function Modifier:isExpired()
    return self.duration > 0 and self.remaining <= 0
end

--- Return true if the modifier is permanent (duration <= 0).
--- @treturn boolean
function Modifier:isPermanent()
    return self.duration <= 0
end

--- Advance the expiry countdown.
--- @tparam number dt Elapsed seconds.
function Modifier:update(dt)
    if self.duration > 0 then
        self.remaining = self.remaining - dt
        if self.remaining < 0 then self.remaining = 0 end
    end
end

---------------------------------------------------------------------------
-- ConversionRule
---------------------------------------------------------------------------

local ConversionRule = {}
ConversionRule.__index = ConversionRule

--- Create a conversion rule.
--- @tparam string from      Source resource name.
--- @tparam string to        Target resource name.
--- @tparam number rate      Conversion rate.
--- @treturn ConversionRule
function M.newConversionRule(from, to, rate)
    local r = setmetatable({}, ConversionRule)
    r.from              = from
    r.to                = to
    r.rate              = rate or 1
    r.fee               = 0
    r.cooldown          = 0
    r.cooldown_remaining = 0
    r.min_amount        = 0
    r.max_amount        = math.huge
    r.modifiers         = {}
    return r
end

--- Return the source resource name.
--- @treturn string
function ConversionRule:getFrom()       return self.from end

--- Return the destination resource name.
--- @treturn string
function ConversionRule:getTo()         return self.to end

--- Return the base conversion rate.
--- @treturn number
function ConversionRule:getRate()       return self.rate end

--- Set the base conversion rate.
--- @tparam number r New rate.
function ConversionRule:setRate(r)      self.rate = r end

--- Return the fee applied per conversion.
--- @treturn number
function ConversionRule:getFee()        return self.fee end

--- Set the fee applied per conversion.
--- @tparam number f Fee amount.
function ConversionRule:setFee(f)       self.fee = f end

--- Return the cooldown duration in seconds.
--- @treturn number
function ConversionRule:getCooldown()   return self.cooldown end

--- Set the cooldown duration in seconds.
--- @tparam number c Cooldown seconds.
function ConversionRule:setCooldown(c)  self.cooldown = c end

--- Return the minimum allowed conversion amount.
--- @treturn number
function ConversionRule:getMinAmount()  return self.min_amount end

--- Set the minimum allowed conversion amount.
--- @tparam number m Minimum amount.
function ConversionRule:setMinAmount(m) self.min_amount = m end

--- Return the maximum allowed conversion amount.
--- @treturn number
function ConversionRule:getMaxAmount()  return self.max_amount end

--- Set the maximum allowed conversion amount.
--- @tparam number m Maximum amount.
function ConversionRule:setMaxAmount(m) self.max_amount = m end

--- Return true if the rule is currently on cooldown.
--- @treturn boolean
function ConversionRule:isOnCooldown()
    return self.cooldown_remaining > 0
end

--- Reset the cooldown timer to zero.
function ConversionRule:resetCooldown()
    self.cooldown_remaining = 0
end

--- Trigger the cooldown period.
function ConversionRule:startCooldown()
    self.cooldown_remaining = self.cooldown
end

--- Advance the cooldown timer.
--- @tparam number dt Elapsed seconds.
function ConversionRule:updateCooldown(dt)
    if self.cooldown_remaining > 0 then
        self.cooldown_remaining = self.cooldown_remaining - dt
        if self.cooldown_remaining < 0 then self.cooldown_remaining = 0 end
    end
end

--- Add a modifier to this rule.
--- @tparam Modifier m Modifier to add.
function ConversionRule:addModifier(m)
    self.modifiers[#self.modifiers + 1] = m
end

--- Remove a modifier by 1-based index. Returns true if removed.
--- @tparam number index 1-based index.
--- @treturn boolean
function ConversionRule:removeModifier(index)
    if index >= 1 and index <= #self.modifiers then
        table.remove(self.modifiers, index)
        return true
    end
    return false
end

--- Return the modifier array.
--- @treturn table
function ConversionRule:getModifiers()
    return self.modifiers
end

--- Clear all modifiers from this rule.
function ConversionRule:clearModifiers()
    self.modifiers = {}
end

--- Compute effective conversion rate after applying modifiers.
--- @treturn number
function ConversionRule:effectiveRate()
    local add_total = 0
    local mul_total = 1
    local set_val   = nil
    for _, m in ipairs(self.modifiers) do
        if not m:isExpired() then
            if m.mod_type == "add" then
                add_total = add_total + m.value
            elseif m.mod_type == "multiply" then
                mul_total = mul_total * m.value
            elseif m.mod_type == "set" then
                set_val = m.value -- last wins
            end
        end
    end
    if set_val ~= nil then
        return set_val
    end
    return (self.rate + add_total) * mul_total
end

---------------------------------------------------------------------------
-- ResourceManager
---------------------------------------------------------------------------

local ResourceManager = {}
ResourceManager.__index = ResourceManager

--- Create a new resource manager.
--- @treturn ResourceManager
function M.newManager()
    local mgr = setmetatable({}, ResourceManager)
    mgr.resources        = {}
    mgr.conversion_rules = {}
    return mgr
end

--- Create (or return existing) resource.
--- @tparam string name
--- @tparam number capacity
--- @treturn Resource
function ResourceManager:newResource(name, capacity)
    if not self.resources[name] then
        self.resources[name] = M.newResource(name, capacity)
    end
    return self.resources[name]
end

--- @tparam string name
--- @treturn Resource|nil
function ResourceManager:getResource(name)
    return self.resources[name]
end

--- @tparam string name
--- @treturn boolean
function ResourceManager:hasResource(name)
    return self.resources[name] ~= nil
end

--- @treturn table Array of resource names.
function ResourceManager:getResourceNames()
    local names = {}
    for k, _ in pairs(self.resources) do
        names[#names + 1] = k
    end
    return names
end

--- Remove a resource by name.
--- @tparam string name
function ResourceManager:removeResource(name)
    self.resources[name] = nil
end

--- Tick all enabled resources and advance conversion rule cooldowns / modifiers.
--- @tparam number dt
function ResourceManager:tick(dt)
    for _, r in pairs(self.resources) do
        r:tick(dt)
    end
    for _, rule in ipairs(self.conversion_rules) do
        rule:updateCooldown(dt)
        for _, m in ipairs(rule.modifiers) do
            m:update(dt)
        end
    end
end

--- Turn: equivalent to tick(1.0).
function ResourceManager:turn()
    self:tick(1.0)
end

--- Add a conversion rule.
--- @tparam ConversionRule rule
function ResourceManager:addConversionRule(rule)
    self.conversion_rules[#self.conversion_rules + 1] = rule
end

--- @treturn table Array of ConversionRule.
function ResourceManager:getConversionRules()
    return self.conversion_rules
end

--- Convert resources using the first matching rule.
--- @tparam string from
--- @tparam string to
--- @tparam number amount
--- @treturn boolean
function ResourceManager:convert(from, to, amount)
    -- find first matching rule
    local rule = nil
    for _, r in ipairs(self.conversion_rules) do
        if r.from == from and r.to == to then
            rule = r
            break
        end
    end
    if not rule then return false end
    if rule:isOnCooldown() then return false end
    if amount < rule.min_amount or amount > rule.max_amount then return false end

    local eff_rate   = rule:effectiveRate()
    local total_cost = amount + rule.fee
    local src = self.resources[from]
    local dst = self.resources[to]
    if not src or not dst then return false end
    if not src:canAfford(total_cost) then return false end

    local output = amount * eff_rate
    src:spend(total_cost)
    dst:add(output)
    rule:startCooldown()
    return true
end

--- Direct two-way exchange between two managers (atomic).
--- @tparam ResourceManager other
--- @tparam string give_name  Resource to give.
--- @tparam number give_amount
--- @tparam string get_name   Resource to receive.
--- @tparam number get_amount
--- @treturn boolean
function ResourceManager:exchange(other, give_name, give_amount, get_name, get_amount)
    local my_r  = self.resources[give_name]
    local oth_r = other.resources[get_name]
    if not my_r or not oth_r then return false end
    if not my_r:canAfford(give_amount) then return false end
    if not oth_r:canAfford(get_amount) then return false end
    -- atomic
    my_r:spend(give_amount)
    oth_r:spend(get_amount)
    local my_recv = self.resources[get_name]
    if my_recv then my_recv:add(get_amount) end
    local oth_recv = other.resources[give_name]
    if oth_recv then oth_recv:add(give_amount) end
    return true
end

--- Sum of values for all resources in a group.
--- @tparam string group
--- @treturn number
function ResourceManager:totalByGroup(group)
    local total = 0
    for _, r in pairs(self.resources) do
        if r.group == group then total = total + r.value end
    end
    return total
end

--- Percent full (0-100) for a resource, 0 if capacity <= 0.
--- @tparam string name
--- @treturn number
function ResourceManager:getPercent(name)
    local r = self.resources[name]
    if not r then return 0 end
    if r.capacity <= 0 then return 0 end
    local pct = (r.value / r.capacity) * 100
    if pct < 0 then pct = 0 end
    if pct > 100 then pct = 100 end
    return pct
end

--- Is the resource at capacity?
--- @tparam string name
--- @treturn boolean
function ResourceManager:isFull(name)
    local r = self.resources[name]
    if not r then return false end
    if r.capacity < 0 then return false end
    return r.value >= r.capacity
end

--- Is the resource at minimum?
--- @tparam string name
--- @treturn boolean
function ResourceManager:isEmpty(name)
    local r = self.resources[name]
    if not r then return true end
    return r.value <= r.minimum
end

--- Check if all resources in the table can be afforded.
--- @tparam table needs  {name = amount, ...}
--- @treturn boolean
function ResourceManager:canAffordAll(needs)
    for name, amount in pairs(needs) do
        local r = self.resources[name]
        if not r or not r:canAfford(amount) then return false end
    end
    return true
end

--- Atomically spend all resources in the table.
--- @tparam table needs  {name = amount, ...}
--- @treturn boolean
function ResourceManager:spendAll(needs)
    if not self:canAffordAll(needs) then return false end
    for name, amount in pairs(needs) do
        self.resources[name]:spend(amount)
    end
    return true
end

--- Clear all resources and conversion rules.
function ResourceManager:reset()
    self.resources = {}
    self.conversion_rules = {}
end

-- Convenience accessors on manager (delegate to named resource)

--- Return the current value of a named resource (0 if not found).
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getValue(name)
    local r = self.resources[name]
    return r and r.value or 0
end

--- Set the value of a named resource (clamped).
--- @tparam string name Resource name.
--- @tparam number v New value.
function ResourceManager:setValue(name, v)
    local r = self.resources[name]
    if r then r:setValue(v) end
end

--- Return the capacity of a named resource.
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getCapacity(name)
    local r = self.resources[name]
    return r and r.capacity or 0
end

--- Set the capacity of a named resource.
--- @tparam string name Resource name.
--- @tparam number c New capacity.
function ResourceManager:setCapacity(name, c)
    local r = self.resources[name]
    if r then r:setCapacity(c) end
end

--- Return the minimum value of a named resource.
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getMinimum(name)
    local r = self.resources[name]
    return r and r.minimum or 0
end

--- Set the minimum value of a named resource.
--- @tparam string name Resource name.
--- @tparam number m New minimum.
function ResourceManager:setMinimum(name, m)
    local r = self.resources[name]
    if r then r:setMinimum(m) end
end

--- Return the flow rate of a named resource.
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getFlowRate(name)
    local r = self.resources[name]
    return r and r.flow_rate or 0
end

--- Set the flow rate of a named resource.
--- @tparam string name Resource name.
--- @tparam number rate Flow rate.
function ResourceManager:setFlowRate(name, rate)
    local r = self.resources[name]
    if r then r.flow_rate = rate end
end

--- Return the flat decay rate of a named resource.
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getDecayRate(name)
    local r = self.resources[name]
    return r and r.decay_rate or 0
end

--- Set the flat decay rate of a named resource.
--- @tparam string name Resource name.
--- @tparam number rate Decay rate.
function ResourceManager:setDecayRate(name, rate)
    local r = self.resources[name]
    if r then r.decay_rate = rate end
end

--- Return the proportional decay rate of a named resource.
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getDecayPercent(name)
    local r = self.resources[name]
    return r and r.decay_percent or 0
end

--- Set the proportional decay rate of a named resource.
--- @tparam string name Resource name.
--- @tparam number pct Decay percent.
function ResourceManager:setDecayPercent(name, pct)
    local r = self.resources[name]
    if r then r.decay_percent = pct end
end

--- Return the interest rate of a named resource.
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getInterestRate(name)
    local r = self.resources[name]
    return r and r.interest_rate or 0
end

--- Set the interest rate of a named resource.
--- @tparam string name Resource name.
--- @tparam number rate Interest rate.
function ResourceManager:setInterestRate(name, rate)
    local r = self.resources[name]
    if r then r.interest_rate = rate end
end

--- Return the upkeep cost of a named resource.
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getUpkeep(name)
    local r = self.resources[name]
    return r and r.upkeep or 0
end

--- Set the upkeep cost of a named resource.
--- @tparam string name Resource name.
--- @tparam number u Upkeep cost.
function ResourceManager:setUpkeep(name, u)
    local r = self.resources[name]
    if r then r.upkeep = u end
end

--- Return the net rate (flow - decay - upkeep + interest - decay%) of a named resource.
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getNetRate(name)
    local r = self.resources[name]
    return r and r:getNetRate() or 0
end

--- Return the overflow policy of a named resource.
--- @tparam string name Resource name.
--- @treturn string
function ResourceManager:getOverflow(name)
    local r = self.resources[name]
    return r and r.overflow or "clamp"
end

--- Set the overflow policy of a named resource.
--- @tparam string name Resource name.
--- @tparam string policy One of "clamp", "lose", "wrap".
function ResourceManager:setOverflow(name, policy)
    local r = self.resources[name]
    if r then r:setOverflow(policy) end
end

--- Return the group tag of a named resource.
--- @tparam string name Resource name.
--- @treturn string
function ResourceManager:getGroup(name)
    local r = self.resources[name]
    return r and r.group or ""
end

--- Set the group tag of a named resource.
--- @tparam string name Resource name.
--- @tparam string g Group name.
function ResourceManager:setGroup(name, g)
    local r = self.resources[name]
    if r then r:setGroup(g) end
end

--- Return whether tick processing is enabled for a named resource.
--- @tparam string name Resource name.
--- @treturn boolean
function ResourceManager:isEnabled(name)
    local r = self.resources[name]
    return r and r.enabled or false
end

--- Enable or disable tick processing for a named resource.
--- @tparam string name Resource name.
--- @tparam boolean v Enabled state.
function ResourceManager:setEnabled(name, v)
    local r = self.resources[name]
    if r then r.enabled = v end
end

--- Return the UI visibility hint of a named resource.
--- @tparam string name Resource name.
--- @treturn boolean
function ResourceManager:isVisible(name)
    local r = self.resources[name]
    return r and r.visible or false
end

--- Set the UI visibility hint of a named resource.
--- @tparam string name Resource name.
--- @tparam boolean v Visibility.
function ResourceManager:setVisible(name, v)
    local r = self.resources[name]
    if r then r.visible = v end
end

--- Return whether a named resource is locked against modifications.
--- @tparam string name Resource name.
--- @treturn boolean
function ResourceManager:isLocked(name)
    local r = self.resources[name]
    return r and r.locked or false
end

--- Lock or unlock add/spend for a named resource.
--- @tparam string name Resource name.
--- @tparam boolean v Locked state.
function ResourceManager:setLocked(name, v)
    local r = self.resources[name]
    if r then r.locked = v end
end

--- Add an amount to a named resource. Returns excess that did not fit.
--- @tparam string name Resource name.
--- @tparam number amount Amount to add.
--- @treturn number excess
function ResourceManager:add(name, amount)
    local r = self.resources[name]
    if not r then return amount end
    return r:add(amount)
end

--- Spend an amount from a named resource. Returns true on success.
--- @tparam string name Resource name.
--- @tparam number amount Amount to spend.
--- @treturn boolean
function ResourceManager:spend(name, amount)
    local r = self.resources[name]
    if not r then return false end
    return r:spend(amount)
end

--- Return true if the named resource has enough available funds.
--- @tparam string name Resource name.
--- @tparam number amount Amount required.
--- @treturn boolean
function ResourceManager:canAfford(name, amount)
    local r = self.resources[name]
    if not r then return false end
    return r:canAfford(amount)
end

--- Return the available amount (value - reserved) of a named resource.
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getAvailable(name)
    local r = self.resources[name]
    return r and r:getAvailable() or 0
end

--- Increase the reservation on a named resource.
--- @tparam string name Resource name.
--- @tparam number amount Amount to reserve.
function ResourceManager:reserveAmount(name, amount)
    local r = self.resources[name]
    if r then r:reserve(amount) end
end

--- Decrease the reservation on a named resource (floored at 0).
--- @tparam string name Resource name.
--- @tparam number amount Amount to release.
function ResourceManager:unreserveAmount(name, amount)
    local r = self.resources[name]
    if r then r:unreserve(amount) end
end

--- Return the reserved amount of a named resource.
--- @tparam string name Resource name.
--- @treturn number
function ResourceManager:getReserved(name)
    local r = self.resources[name]
    return r and r.reserved or 0
end


-- ═══════════════════════════════════════════════════════════════════════
-- PARITY ADDITIONS — Phase 2A  (economy)
-- ═══════════════════════════════════════════════════════════════════════

--- Resource-cap overflow policy enum.
-- @field CLAMP
-- @field LOSE
-- @field WRAP
M.OverflowPolicy = {
    CLAMP = "clamp",
    LOSE  = "lose",
    WRAP  = "wrap",
}

--- Modifier application type enum.
-- @field MULTIPLY
-- @field ADD
-- @field SET
M.ModifierType = {
    MULTIPLY = "multiply",
    ADD      = "add",
    SET      = "set",
}

return M
