--- @module library.battle
--- @description Pure-Lua turn-based battle system with combatants, actions,
--- status effects, initiative, damage types, and combat resolution.
--- Port of the Rust src/battle/ module.
local M = {}

---------------------------------------------------------------------------
-- StatusEffect
---------------------------------------------------------------------------

local StatusEffect = {}
StatusEffect.__index = StatusEffect

--- Create a new status effect.
--- @tparam string name
--- @tparam[opt=-1] number duration  Turns remaining (-1 = permanent).
--- @treturn StatusEffect
function M.newStatusEffect(name, duration)
    local e = setmetatable({}, StatusEffect)
    e.name     = name or ""
    e.duration = duration or -1
    e.stacks   = 1
    e.data     = {}
    return e
end

--- Get the effect name.
-- @return string
function StatusEffect:getName()       return self.name end
--- Get remaining duration (-1 = permanent).
-- @return number
function StatusEffect:getDuration()   return self.duration end
--- Set remaining duration.
-- @param v number
function StatusEffect:setDuration(v)  self.duration = v end
--- Get current stack count.
-- @return number
function StatusEffect:getStacks()     return self.stacks end
--- Set stack count.
-- @param v number
function StatusEffect:setStacks(v)    self.stacks = v end

--- Tick one turn. Returns true when the effect has just expired.
--- @treturn boolean
function StatusEffect:tickTurn()
    if self.duration > 0 then
        self.duration = self.duration - 1
        return self.duration == 0
    end
    return false
end

--- Is the effect expired?
--- @treturn boolean
function StatusEffect:isExpired()
    return self.duration == 0
end

---------------------------------------------------------------------------
-- CombatAction
---------------------------------------------------------------------------

local CombatAction = {}
CombatAction.__index = CombatAction

--- Create a new combat action.
--- @tparam string name
--- @treturn CombatAction
function M.newAction(name)
    local a = setmetatable({}, CombatAction)
    a.name             = name or ""
    a.damage_type      = "physical"
    a.base_damage      = 0
    a.accuracy         = 1.0
    a.cooldown         = 0
    a.current_cooldown = 0
    a.cost_hp          = 0
    a.cost_mp          = 0
    a.tags             = {}
    a.metadata         = {}
    return a
end

--- Get the action name.
-- @return string
function CombatAction:getName()           return self.name end
--- Get base damage value.
-- @return number
function CombatAction:getBaseDamage()     return self.base_damage end
--- Set base damage value.
-- @param v number
function CombatAction:setBaseDamage(v)    self.base_damage = v end
--- Get damage type string.
-- @return string
function CombatAction:getDamageType()     return self.damage_type end
--- Set damage type string (defaults to "physical").
-- @param v string
function CombatAction:setDamageType(v)    self.damage_type = v or "physical" end
--- Get accuracy clamped to [0, 1].
-- @return number
function CombatAction:getAccuracy()       return self.accuracy end
--- Set accuracy, clamped to [0, 1].
-- @param v number
function CombatAction:setAccuracy(v)
    if v < 0 then v = 0 end
    if v > 1 then v = 1 end
    self.accuracy = v
end
--- Get max cooldown turns.
-- @return number
function CombatAction:getCooldown()        return self.cooldown end
--- Set max cooldown turns.
-- @param v number
function CombatAction:setCooldown(v)       self.cooldown = v end
--- Get current remaining cooldown turns.
-- @return number
function CombatAction:getCurrentCooldown() return self.current_cooldown end
--- Get HP cost to use this action.
-- @return number
function CombatAction:getCostHp()          return self.cost_hp end
--- Set HP cost.
-- @param v number
function CombatAction:setCostHp(v)         self.cost_hp = v end
--- Get MP cost to use this action.
-- @return number
function CombatAction:getCostMp()          return self.cost_mp end
--- Set MP cost.
-- @param v number
function CombatAction:setCostMp(v)         self.cost_mp = v end

--- Is the action off cooldown?
--- @treturn boolean
function CombatAction:isReady()
    return self.current_cooldown == 0
end

--- Put the action on cooldown.
function CombatAction:useAction()
    self.current_cooldown = self.cooldown
end

--- Tick cooldown by one.
function CombatAction:tickCooldown()
    if self.current_cooldown > 0 then
        self.current_cooldown = self.current_cooldown - 1
    end
end

---------------------------------------------------------------------------
-- Combatant
---------------------------------------------------------------------------

local Combatant = {}
Combatant.__index = Combatant

--- Create a new combatant.
--- @tparam string name
--- @treturn Combatant
function M.newCombatant(name)
    local c = setmetatable({}, Combatant)
    c.name           = name or ""
    c.team           = "player"
    c.hp             = 100
    c.max_hp         = 100
    c.mp             = 50
    c.max_mp         = 50
    c.speed          = 10
    c.level          = 1
    c.alive          = true
    c.stats          = {}
    c.resistances    = {}
    c.status_effects = {}
    c.actions        = {}
    c.metadata       = {}
    return c
end

--- Get combatant name.
-- @return string
function Combatant:getName()     return self.name end
--- Get team identifier string.
-- @return string
function Combatant:getTeam()     return self.team end
--- Set team identifier (defaults to "player").
-- @param v string
function Combatant:setTeam(v)    self.team = v or "player" end
--- Get current HP.
-- @return number
function Combatant:getHp()       return self.hp end
--- Set current HP directly (use takeDamage/heal for safe HP changes).
-- @param v number
function Combatant:setHp(v)      self.hp = v end
--- Get maximum HP.
-- @return number
function Combatant:getMaxHp()    return self.max_hp end
--- Set maximum HP.
-- @param v number
function Combatant:setMaxHp(v)   self.max_hp = v end
--- Get current MP.
-- @return number
function Combatant:getMp()       return self.mp end
--- Set current MP.
-- @param v number
function Combatant:setMp(v)      self.mp = v end
--- Get maximum MP.
-- @return number
function Combatant:getMaxMp()    return self.max_mp end
--- Set maximum MP.
-- @param v number
function Combatant:setMaxMp(v)   self.max_mp = v end
--- Get speed (used for initiative ordering; higher = sooner).
-- @return number
function Combatant:getSpeed()    return self.speed end
--- Set speed.
-- @param v number
function Combatant:setSpeed(v)   self.speed = v end
--- Get combatant level.
-- @return number
function Combatant:getLevel()    return self.level end
--- Set combatant level.
-- @param v number
function Combatant:setLevel(v)   self.level = v end

--- Is the combatant alive?
--- @treturn boolean
function Combatant:isAlive()
    return self.alive and self.hp > 0
end

--- Apply damage, factoring in resistance. Resistance is a multiplier (default 1.0).
--- @tparam number amount
--- @tparam[opt="physical"] string damage_type
--- @treturn number actual damage dealt
function Combatant:takeDamage(amount, damage_type)
    damage_type = damage_type or "physical"
    local resistance = self.resistances[damage_type] or 1.0
    local actual = amount * resistance
    if actual < 0 then actual = 0 end
    self.hp = self.hp - actual
    if self.hp < 0 then self.hp = 0 end
    if self.hp <= 0 then self.alive = false end
    return actual
end

--- Heal the combatant.
--- @tparam number amount
--- @treturn number actual amount healed
function Combatant:heal(amount)
    local before = self.hp
    self.hp = self.hp + amount
    if self.hp > self.max_hp then self.hp = self.max_hp end
    return self.hp - before
end

--- Add or stack a status effect.
--- @tparam string name
--- @tparam[opt=-1] number duration
function Combatant:addStatus(name, duration)
    duration = duration or -1
    for _, e in ipairs(self.status_effects) do
        if e.name == name then
            e.stacks = e.stacks + 1
            if duration > e.duration then e.duration = duration end
            return
        end
    end
    self.status_effects[#self.status_effects + 1] = M.newStatusEffect(name, duration)
end

--- Remove a status effect by name.
--- @tparam string name
function Combatant:removeStatus(name)
    local new = {}
    for _, e in ipairs(self.status_effects) do
        if e.name ~= name then new[#new + 1] = e end
    end
    self.status_effects = new
end

--- Check if a status is active.
--- @tparam string name
--- @treturn boolean
function Combatant:hasStatus(name)
    for _, e in ipairs(self.status_effects) do
        if e.name == name then return true end
    end
    return false
end

--- Tick all status effects, removing expired ones.
--- @treturn table Array of expired status names.
function Combatant:tickStatuses()
    local expired = {}
    for _, e in ipairs(self.status_effects) do
        e:tickTurn()
    end
    local new = {}
    for _, e in ipairs(self.status_effects) do
        if e:isExpired() then
            expired[#expired + 1] = e.name
        else
            new[#new + 1] = e
        end
    end
    self.status_effects = new
    return expired
end

--- Get array of {name, duration, stacks} tables.
--- @treturn table
function Combatant:getStatuses()
    local out = {}
    for _, e in ipairs(self.status_effects) do
        out[#out + 1] = { name = e.name, duration = e.duration, stacks = e.stacks }
    end
    return out
end

--- Get a named stat value (defaults to 0).
--- @tparam string name
--- @treturn number
function Combatant:getStat(name)
    return self.stats[name] or 0
end

--- Set a named stat.
--- @tparam string name
--- @tparam number value
function Combatant:setStat(name, value)
    self.stats[name] = value
end

--- Get damage resistance for a type (defaults to 1.0 = full damage).
--- @tparam string dtype
--- @treturn number
function Combatant:getResistance(dtype)
    return self.resistances[dtype] or 1.0
end

--- Set damage resistance for a type.
--- @tparam string dtype
--- @tparam number value
function Combatant:setResistance(dtype, value)
    self.resistances[dtype] = value
end

--- HP as a percentage (0-100).
--- @treturn number
function Combatant:getHpPercent()
    if self.max_hp <= 0 then return 0 end
    local pct = (self.hp / self.max_hp) * 100
    if pct < 0 then pct = 0 end
    if pct > 100 then pct = 100 end
    return pct
end

--- MP as a percentage (0-100).
--- @treturn number
function Combatant:getMpPercent()
    if self.max_mp <= 0 then return 0 end
    local pct = (self.mp / self.max_mp) * 100
    if pct < 0 then pct = 0 end
    if pct > 100 then pct = 100 end
    return pct
end

--- Add a combat action (clone of the action).
--- @tparam CombatAction action
function Combatant:addAction(action)
    -- shallow clone to avoid shared mutation
    local a = setmetatable({}, CombatAction)
    for k, v in pairs(action) do a[k] = v end
    a.tags     = {}; for i, t in ipairs(action.tags or {}) do a.tags[i] = t end
    a.metadata = {}; for k2, v2 in pairs(action.metadata or {}) do a.metadata[k2] = v2 end
    self.actions[#self.actions + 1] = a
end

--- Get an action by name.
--- @tparam string name
--- @treturn CombatAction|nil
function Combatant:getAction(name)
    for _, a in ipairs(self.actions) do
        if a.name == name then return a end
    end
    return nil
end

--- Check if the combatant has an action.
--- @tparam string name
--- @treturn boolean
function Combatant:hasAction(name)
    return self:getAction(name) ~= nil
end

--- Tick all action cooldowns.
function Combatant:tickCooldowns()
    for _, a in ipairs(self.actions) do
        a:tickCooldown()
    end
end

--- Get array of action names.
--- @treturn table
function Combatant:getActionNames()
    local names = {}
    for _, a in ipairs(self.actions) do names[#names + 1] = a.name end
    return names
end

--- Get array of status effect names.
--- @treturn table
function Combatant:getStatusNames()
    local names = {}
    for _, e in ipairs(self.status_effects) do names[#names + 1] = e.name end
    return names
end

--- Get metadata value.
--- @tparam string key
--- @treturn string|nil
function Combatant:getMeta(key) return self.metadata[key] end

--- Set metadata value.
--- @tparam string key  @tparam string value
function Combatant:setMeta(key, value) self.metadata[key] = value end

---------------------------------------------------------------------------
-- CombatBattle
---------------------------------------------------------------------------

local CombatBattle = {}
CombatBattle.__index = CombatBattle

--- Create a new battle.
--- @tparam[opt=""] string name
--- @treturn CombatBattle
function M.newBattle(name)
    local b = setmetatable({}, CombatBattle)
    b.name        = name or ""
    b.combatants  = {}
    b.turn_index  = 1  -- 1-indexed
    b.turn_count  = 0
    b.over        = false
    b.winner_team = nil
    b.log         = {}
    return b
end

--- Get battle display name.
-- @return string
function CombatBattle:getName()   return self.name end
--- Get total number of combatants (alive and dead).
-- @return number
function CombatBattle:getCount()  return #self.combatants end
--- Get total completed turn count.
-- @return number
function CombatBattle:getTurnCount() return self.turn_count end
--- Returns true when the battle has ended.
-- @return boolean
function CombatBattle:isOver()    return self.over end
--- Returns the winning team name, or nil if not yet over.
-- @return string|nil
function CombatBattle:getWinner() return self.winner_team end
--- Returns the battle log as an array of strings.
-- @return table
function CombatBattle:getLog()    return self.log end

--- Add a log entry.
--- @tparam string msg
function CombatBattle:addToLog(msg)
    self.log[#self.log + 1] = msg
end

--- Add a combatant (shallow clone).
--- @tparam Combatant c
function CombatBattle:addCombatant(c)
    -- clone combatant
    local clone = setmetatable({}, Combatant)
    for k, v in pairs(c) do clone[k] = v end
    clone.stats = {}; for k2, v2 in pairs(c.stats or {}) do clone.stats[k2] = v2 end
    clone.resistances = {}; for k2, v2 in pairs(c.resistances or {}) do clone.resistances[k2] = v2 end
    clone.metadata = {}; for k2, v2 in pairs(c.metadata or {}) do clone.metadata[k2] = v2 end
    -- deep clone status effects
    clone.status_effects = {}
    for _, e in ipairs(c.status_effects or {}) do
        local se = M.newStatusEffect(e.name, e.duration)
        se.stacks = e.stacks
        clone.status_effects[#clone.status_effects + 1] = se
    end
    -- deep clone actions
    clone.actions = {}
    for _, a in ipairs(c.actions or {}) do
        local ac = setmetatable({}, CombatAction)
        for k2, v2 in pairs(a) do ac[k2] = v2 end
        ac.tags = {}; for i, t in ipairs(a.tags or {}) do ac.tags[i] = t end
        ac.metadata = {}; for k2, v2 in pairs(a.metadata or {}) do ac.metadata[k2] = v2 end
        clone.actions[#clone.actions + 1] = ac
    end
    self.combatants[#self.combatants + 1] = clone
end

--- Get a combatant by name (returns reference inside battle).
--- @tparam string name
--- @treturn Combatant|nil
function CombatBattle:getCombatant(name)
    for _, c in ipairs(self.combatants) do
        if c.name == name then return c end
    end
    return nil
end

--- Sort combatants by speed (descending).
function CombatBattle:sortInitiative()
    table.sort(self.combatants, function(a, b)
        return a.speed > b.speed
    end)
end

--- Get the current alive combatant.
--- @treturn Combatant|nil
function CombatBattle:getCurrentCombatant()
    local alive = {}
    for _, c in ipairs(self.combatants) do
        if c:isAlive() then alive[#alive + 1] = c end
    end
    if #alive == 0 then return nil end
    local idx = ((self.turn_index - 1) % #alive) + 1
    return alive[idx]
end

--- Advance to next turn. Returns false if battle is over.
--- @treturn boolean
function CombatBattle:nextTurn()
    local alive_count = 0
    for _, c in ipairs(self.combatants) do
        if c:isAlive() then alive_count = alive_count + 1 end
    end
    if alive_count == 0 then return false end
    self.turn_index = (self.turn_index % alive_count) + 1
    self.turn_count = self.turn_count + 1
    self:_checkBattleOver()
    return not self.over
end

--- Check if battle is over (one team or fewer alive).
function CombatBattle:_checkBattleOver()
    local teams = {}
    for _, c in ipairs(self.combatants) do
        if c:isAlive() then
            teams[c.team] = true
        end
    end
    local count = 0
    local last_team = nil
    for t, _ in pairs(teams) do
        count = count + 1
        last_team = t
    end
    if count <= 1 then
        self.over = true
        self.winner_team = last_team
    end
end

--- Resolve an attack.
--- @tparam string attacker_name
--- @tparam string action_name
--- @tparam string target_name
--- @treturn table|nil CombatResult table or nil if invalid.
function CombatBattle:attack(attacker_name, action_name, target_name)
    local atk = self:getCombatant(attacker_name)
    if not atk then return nil end
    local action = atk:getAction(action_name)
    if not action then return nil end
    if not action:isReady() then return nil end

    local hit = math.random() <= action.accuracy
    local damage = hit and action.base_damage or 0
    local damage_type = action.damage_type
    action:useAction()

    local target = self:getCombatant(target_name)
    if not target then return nil end

    local actual = hit and target:takeDamage(damage, damage_type) or 0
    local died = not target:isAlive()

    local msg
    if hit then
        msg = string.format("%s dealt %.1f to %s", attacker_name, actual, target_name)
    else
        msg = string.format("%s missed %s", attacker_name, target_name)
    end
    self.log[#self.log + 1] = msg

    self:_checkBattleOver()

    return {
        attacker   = attacker_name,
        target     = target_name,
        action     = action_name,
        hit        = hit,
        damage     = actual,
        damageType = damage_type,
        targetDied = died,
        message    = msg,
    }
end

--- Get names of all alive combatants.
--- @treturn table
function CombatBattle:getAliveNames()
    local names = {}
    for _, c in ipairs(self.combatants) do
        if c:isAlive() then names[#names + 1] = c.name end
    end
    return names
end

--- Get names of all combatants.
--- @treturn table
function CombatBattle:getAllNames()
    local names = {}
    for _, c in ipairs(self.combatants) do names[#names + 1] = c.name end
    return names
end

--- Remove a combatant by name.
--- @tparam string name
--- @treturn boolean
function CombatBattle:removeCombatant(name)
    for i, c in ipairs(self.combatants) do
        if c.name == name then
            table.remove(self.combatants, i)
            return true
        end
    end
    return false
end

--- Force-end the battle with a specified winner.
--- @tparam[opt] string winner
function CombatBattle:forceEnd(winner)
    self.over = true
    self.winner_team = winner
end

--- Tick all combatant statuses.
function CombatBattle:tickAllStatuses()
    for _, c in ipairs(self.combatants) do
        c:tickStatuses()
    end
end

--- Tick all combatant action cooldowns.
function CombatBattle:tickAllActions()
    for _, c in ipairs(self.combatants) do
        c:tickCooldowns()
    end
end


-- ═══════════════════════════════════════════════════════════════════════
-- PARITY ADDITIONS — Phase 2A  (battle)
-- ═══════════════════════════════════════════════════════════════════════

--- Damage type enum.
-- @field Physical
-- @field Fire
-- @field Ice
-- @field Lightning
-- @field Poison
-- @field Arcane
-- @field Custom
M.DamageType = {
    Physical  = "physical",
    Fire      = "fire",
    Ice       = "ice",
    Lightning = "lightning",
    Poison    = "poison",
    Arcane    = "arcane",
    Heal      = "heal",
    True      = "true",
    Custom    = "custom",
}

-- ── CombatAction: tag and metadata ops ────────────────────────────────

--- Add a tag to this action (no-op if already present).
-- @param tag string
function CombatAction:addTag(tag)
    self.tags      = self.tags or {}
    self.tags[tag] = true
end

--- Remove a tag. Returns true if it existed.
-- @param tag string
-- @treturn boolean
function CombatAction:removeTag(tag)
    if self.tags and self.tags[tag] then
        self.tags[tag] = nil
        return true
    end
    return false
end

--- Return true if the action has the given tag.
-- @param tag string
-- @treturn boolean
function CombatAction:hasTag(tag)
    return (self.tags or {})[tag] == true
end

--- Return a sorted list of all tags on this action.
-- @treturn table
function CombatAction:getTags()
    local out = {}
    for t in pairs(self.tags or {}) do out[#out+1] = t end
    table.sort(out)
    return out
end

--- Get a metadata value (string key -> any).
-- @param key string
-- @treturn any
function CombatAction:getMeta(key)
    return (self.metadata or {})[key]
end

--- Set a metadata value.
-- @param key string
-- @param val any
function CombatAction:setMeta(key, val)
    self.metadata      = self.metadata or {}
    self.metadata[key] = val
end

-- ── StatusEffect: metadata ops ────────────────────────────────────────

--- Get a metadata value from the status effect's data table.
-- @param key string
-- @treturn any
function StatusEffect:getMeta(key)
    return (self.data or {})[key]
end

--- Set a metadata value.
-- @param key string
-- @param val any
function StatusEffect:setMeta(key, val)
    self.data      = self.data or {}
    self.data[key] = val
end

--- Alias: getMetadata (matches Rust name).
-- @param key string
-- @treturn any
function StatusEffect:getMetadata(key)
    return self:getMeta(key)
end

--- Alias: setMetadata (matches Rust name).
-- @param key string
-- @param val any
function StatusEffect:setMetadata(key, val)
    self:setMeta(key, val)
end

return M
