--- @module library.stats
--- RPG character stat sheets with attributes, buffs, skills, perks, traits,
--- XP/levelling, action points, morale, resistances, encumbrance and initiative.
--- Pure-Lua port of src/stats/.
--- @status full

local M = {}

-- ÔöÇÔöÇ Enums ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- StackMode values (how duplicate buffs combine).
M.StackMode = { None = 'none', Duration = 'duration', Intensity = 'intensity' }

-- ÔöÇÔöÇ Helpers ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local function clamp(v, lo, hi)
    if lo and v < lo then return lo end
    if hi and v > hi then return hi end
    return v
end

-- ÔöÇÔöÇ Attribute ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Attribute = {}
Attribute.__index = Attribute

--- Create a new attribute.
--- @param base number Base value.
--- @treturn Attribute
function M.newAttribute(base)
    return setmetatable({
        base   = base or 0,
        min    = -math.huge,
        max    = nil,
        regen  = 0,
        growth = 0,
    }, Attribute)
end

-- ÔöÇÔöÇ Buff ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Buff = {}
Buff.__index = Buff

--- Create a new buff.
--- @param stat string Attribute name.
--- @param add number Additive bonus.
--- @param mul number Multiplicative factor (default 1).
--- @param duration number Seconds (-1 = permanent).
--- @param source string Descriptive source.
--- @treturn Buff
function M.newBuff(stat, add, mul, duration, source)
    local dur = duration or -1
    return setmetatable({
        stat      = stat or '',
        add       = add or 0,
        mul       = mul or 1,
        duration  = dur,
        source    = source or '',
        remaining = dur < 0 and -math.huge or dur,
    }, Buff)
end

--- Whether the buff has expired.
--- @treturn boolean
function Buff:isExpired()
    return self.duration >= 0 and self.remaining <= 0
end

-- ÔöÇÔöÇ Skill ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Skill = {}
Skill.__index = Skill

--- Create a new skill.
--- @param opts table|nil Optional: max_level, resource, cost, cooldown.
--- @treturn Skill
function M.newSkill(opts)
    opts = opts or {}
    return setmetatable({
        level              = 0,
        max_level          = opts.max_level or 10,
        resource           = opts.resource or '',
        cost               = opts.cost or 0,
        cooldown           = opts.cooldown or 0,
        cooldown_remaining = 0,
        passive_active     = false,
    }, Skill)
end

-- ÔöÇÔöÇ Perk ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Perk = {}
Perk.__index = Perk

--- Create a new perk.
--- @param opts table|nil Optional: require_level, trait_name.
--- @treturn Perk
function M.newPerk(opts)
    opts = opts or {}
    return setmetatable({
        require_level = opts.require_level or 0,
        trait_name    = opts.trait_name,
        acquired      = false,
    }, Perk)
end

-- ÔöÇÔöÇ ActionPoints ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local ActionPoints = {}
ActionPoints.__index = ActionPoints

--- Create action points with the given maximum.
--- @param max_val number Maximum (and initial) action points.
--- @treturn ActionPoints
function M.newActionPoints(max_val)
    return setmetatable({ current = max_val, max = max_val }, ActionPoints)
end

-- ÔöÇÔöÇ Morale ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local MoraleClass = {}
MoraleClass.__index = MoraleClass

--- Create a morale tracker with the given maximum (current starts at max).
--- @param max_val number Maximum morale value.
--- @treturn Morale
function M.newMorale(max_val)
    return setmetatable({
        current            = max_val,
        max                = max_val,
        panic_threshold    = 25,
        berserk_threshold  = 10,
    }, MoraleClass)
end

-- ÔöÇÔöÇ LevelThresholds ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local LevelThresholds = {}
LevelThresholds.__index = LevelThresholds

--- Create table-based XP thresholds (one value per level).
--- @param values table Array of numbers; values[n] is XP required for level n.
--- @treturn LevelThresholds
function M.newTableThresholds(values)
    return setmetatable({ kind = 'table', values = values }, LevelThresholds)
end

--- Create linear XP thresholds using the formula base + (level-1)*increment.
--- @param base number XP required for level 1.
--- @param increment number Additional XP required per subsequent level.
--- @treturn LevelThresholds
function M.newLinearThresholds(base, increment)
    return setmetatable({ kind = 'linear', base = base or 100, increment = increment or 100 }, LevelThresholds)
end

--- Return the XP required to advance past the given level.
--- @param level number Current level (1-based).
--- @treturn number XP threshold (math.huge if beyond the table).
function LevelThresholds:thresholdFor(level)
    if self.kind == 'table' then
        return self.values[level] or math.huge
    else
        return self.base + (level - 1) * self.increment
    end
end

local function defaultThresholds()
    return M.newLinearThresholds(100, 100)
end

-- ÔöÇÔöÇ TraitDef ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Create a trait definition.
--- @param buffs table Array of {stat, add, mul} tables.
--- @treturn table TraitDef.
function M.newTraitDef(buffs)
    return { buffs = buffs or {} }
end

-- ÔöÇÔöÇ StatsRegistry (module-level) ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local _traits  = {}
local _races   = {}
local _classes = {}

--- Register a named trait definition in the module registry.
--- @param name string Unique trait name.
--- @param def table TraitDef created with M.newTraitDef.
function M.defineTrait(name, def) _traits[name]  = def end
--- Register a named race archetype.
--- @param name string Unique race name.
--- @param def table Table with optional keys: bases (stat overrides) and traits (list of trait names).
function M.defineRace(name, def)  _races[name]   = def end
--- Register a named class archetype.
--- @param name string Unique class name.
--- @param def table Table with optional keys: bases (stat overrides) and traits (list of trait names).
function M.defineClass(name, def) _classes[name] = def end

--- Return a sorted list of all registered trait names.
--- @treturn table Sorted array of strings.
function M.getTraitNames()
    local out = {} for k in pairs(_traits) do out[#out+1] = k end table.sort(out) return out
end
--- Return a sorted list of all registered race names.
--- @treturn table Sorted array of strings.
function M.getRaceNames()
    local out = {} for k in pairs(_races) do out[#out+1] = k end table.sort(out) return out
end
--- Return a sorted list of all registered class names.
--- @treturn table Sorted array of strings.
function M.getClassNames()
    local out = {} for k in pairs(_classes) do out[#out+1] = k end table.sort(out) return out
end

--- Apply race and/or class archetypes to an existing sheet.
--- Base stat bonuses are added and listed traits are applied as permanent buffs.
--- @param sheet Sheet The target sheet.
--- @param race_name string|nil Registered race name, or nil to skip.
--- @param class_name string|nil Registered class name, or nil to skip.
function M.applyArchetypes(sheet, race_name, class_name)
    local function apply(archetype)
        if not archetype then return end
        if archetype.bases then
            for stat, val in pairs(archetype.bases) do
                local attr = sheet._attributes[stat]
                if attr then
                    attr.base = attr.base + val
                else
                    sheet:define(stat, val)
                end
            end
        end
        if archetype.traits then
            for _, tname in ipairs(archetype.traits) do
                local tdef = _traits[tname]
                if tdef then sheet:applyTraitBuffs(tname) end
            end
        end
    end
    if race_name  then apply(_races[race_name])  end
    if class_name then apply(_classes[class_name]) end
end

-- ÔöÇÔöÇ Sheet ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Sheet = {}
Sheet.__index = Sheet

--- Create a new character sheet.
--- @treturn Sheet
function M.newSheet()
    return setmetatable({
        _attributes        = {},
        _buffs             = {},
        _buff_counter      = 0,
        _use_counts        = {},
        _active_traits     = {},
        _skills            = {},
        _perks             = {},
        _flags             = {},
        xp                 = 0,
        level              = 1,
        level_thresholds   = defaultThresholds(),
        action_points      = nil,
        morale             = nil,
        _resistances       = {},
        encumbrance        = nil,
        initiative         = 10,
        active_formation   = nil,
        _formation_handles = {},
    }, Sheet)
end

-- ÔöÇÔöÇ Attributes ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Define a named attribute.
--- @param name string Attribute name.
--- @param base number Base value.
--- @param opts table|nil Optional: min, max, regen, growth.
function Sheet:define(name, base, opts)
    opts = opts or {}
    local attr = M.newAttribute(base)
    if opts.min    then attr.min    = opts.min    end
    if opts.max    then attr.max    = opts.max    end
    if opts.regen  then attr.regen  = opts.regen  end
    if opts.growth then attr.growth = opts.growth end
    self._attributes[name] = attr
end

--- Get effective value (base + buffs, clamped).
--- @param name string
--- @treturn number|nil
function Sheet:get(name)
    local attr = self._attributes[name]
    if not attr then return nil end
    local add_sum  = 0
    local mul_prod = 1
    for _, buff in pairs(self._buffs) do
        if buff.stat == name and not buff:isExpired() then
            add_sum  = add_sum  + buff.add
            mul_prod = mul_prod * buff.mul
        end
    end
    local effective = (attr.base + add_sum) * mul_prod
    return clamp(effective, attr.min, attr.max)
end

--- Get raw base value.
function Sheet:getBase(name)
    local attr = self._attributes[name]
    return attr and attr.base or nil
end

--- Set base value (clamped to min/max).
function Sheet:setBase(name, value)
    local attr = self._attributes[name]
    if not attr then return false end
    attr.base = clamp(value, attr.min, attr.max)
    return true
end

--- Set the minimum clamp value for an attribute.
--- @param name string Attribute name.
--- @param val number New minimum.
function Sheet:setMin(name, val)
    local a = self._attributes[name]; if a then a.min = val end
end
--- Set the maximum clamp value for an attribute.
--- @param name string Attribute name.
--- @param val number New maximum.
function Sheet:setMax(name, val)
    local a = self._attributes[name]; if a then a.max = val end
end
--- Get the current minimum clamp for an attribute.
--- @param name string Attribute name.
--- @treturn number|nil
function Sheet:getMin(name)
    local a = self._attributes[name]; return a and a.min
end
--- Get the current maximum clamp for an attribute.
--- @param name string Attribute name.
--- @treturn number|nil
function Sheet:getMax(name)
    local a = self._attributes[name]; return a and a.max
end
--- Set the regeneration rate for an attribute.
--- @param name string Attribute name.
--- @param val number Regen per second.
function Sheet:setRegen(name, val)
    local a = self._attributes[name]; if a then a.regen = val end
end
--- Get the regeneration rate for an attribute.
--- @param name string Attribute name.
--- @treturn number|nil
function Sheet:getRegen(name)
    local a = self._attributes[name]; return a and a.regen
end

--- Get all defined attribute names.
function Sheet:getStatNames()
    local out = {}
    for k in pairs(self._attributes) do out[#out+1] = k end
    table.sort(out)
    return out
end

-- ÔöÇÔöÇ Buffs ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Add a buff to the sheet and return its numeric handle.
--- @param stat string Attribute to modify.
--- @param add number Additive bonus.
--- @param mul number Multiplicative factor (1 = no change).
--- @param duration number Seconds until expiry (-1 = permanent).
--- @param source string Descriptive label.
--- @treturn number Handle for later removal.
function Sheet:addBuff(stat, add, mul, duration, source)
    self._buff_counter = self._buff_counter + 1
    local handle = self._buff_counter
    self._buffs[handle] = M.newBuff(stat, add, mul, duration, source)
    return handle
end

--- Remove a buff by its numeric handle.
--- @param handle number Handle returned by addBuff.
--- @treturn boolean True if the buff was found and removed.
function Sheet:removeBuff(handle)
    if self._buffs[handle] then self._buffs[handle] = nil; return true end
    return false
end

--- Remove all active buffs, or only those affecting a specific attribute.
--- @param stat string|nil If given, only buffs for this attribute are removed.
function Sheet:clearBuffs(stat)
    if not stat then
        self._buffs = {}
    else
        for h, b in pairs(self._buffs) do
            if b.stat == stat then self._buffs[h] = nil end
        end
    end
end

--- Return all active (non-expired) buffs as an array of info tables.
--- Each entry has: handle, stat, add, mul, duration, remaining, source.
--- @param stat string|nil If given, filter to buffs affecting this attribute.
--- @treturn table Array of buff-info tables.
function Sheet:getBuffs(stat)
    local out = {}
    for h, b in pairs(self._buffs) do
        if not b:isExpired() and (not stat or b.stat == stat) then
            out[#out+1] = {
                handle    = h,
                stat      = b.stat,
                add       = b.add,
                mul       = b.mul,
                duration  = b.duration,
                remaining = b.remaining,
                source    = b.source,
            }
        end
    end
    return out
end

--- Count active (non-expired) buffs, optionally limited to one attribute.
--- @param stat string|nil If given, count only buffs for this attribute.
--- @treturn number
function Sheet:getBuffCount(stat)
    local n = 0
    for _, b in pairs(self._buffs) do
        if not b:isExpired() and (not stat or b.stat == stat) then n = n + 1 end
    end
    return n
end

-- ÔöÇÔöÇ Traits ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Apply a registered trait's permanent buffs to this sheet.
--- @param trait_name string Name of a trait registered with M.defineTrait.
--- @treturn table Array of buff handles for the applied buffs.
function Sheet:applyTraitBuffs(trait_name)
    local tdef = _traits[trait_name]
    if not tdef then return {} end
    local handles = {}
    for _, entry in ipairs(tdef.buffs or {}) do
        local h = self:addBuff(entry.stat or entry[1], entry.add or entry[2] or 0, entry.mul or entry[3] or 1, -1, 'trait:' .. trait_name)
        handles[#handles+1] = h
    end
    self._active_traits[trait_name] = handles
    return handles
end

--- Remove all buffs that were applied by a named trait.
--- @param trait_name string Trait to remove.
--- @treturn boolean True if the trait was active and its buffs were removed.
function Sheet:removeTraitBuffs(trait_name)
    local handles = self._active_traits[trait_name]
    if not handles then return false end
    for _, h in ipairs(handles) do self._buffs[h] = nil end
    self._active_traits[trait_name] = nil
    return true
end

--- Return true if a named trait is currently active on this sheet.
--- @param name string Trait name.
--- @treturn boolean
function Sheet:hasTrait(name) return self._active_traits[name] ~= nil end

--- Return a sorted list of all currently active trait names.
--- @treturn table Sorted array of strings.
function Sheet:getActiveTraits()
    local out = {}
    for k in pairs(self._active_traits) do out[#out+1] = k end
    table.sort(out)
    return out
end

-- ÔöÇÔöÇ Skills ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Define a named skill on this sheet.
--- @param name string Skill name.
--- @param opts table|nil Options: max_level, resource, cost, cooldown.
function Sheet:defineSkill(name, opts)
    self._skills[name] = M.newSkill(opts)
end

--- Advance a skill by one level. Returns false if already at max level or unknown.
--- @param name string Skill name.
--- @treturn boolean
function Sheet:learnSkill(name)
    local sk = self._skills[name]
    if not sk then return false end
    if sk.level >= sk.max_level then return false end
    sk.level = sk.level + 1
    return true
end

--- Attempt to use a skill: deducts cost and starts cooldown.
--- Returns false plus a reason string on failure.
--- @param name string Skill name.
--- @treturn boolean, string|nil Success flag and optional failure reason.
function Sheet:useSkill(name)
    local sk = self._skills[name]
    if not sk then return false, 'unknown skill' end
    if sk.level < 1 then return false, 'not learned' end
    if sk.cooldown_remaining > 0 then return false, 'on cooldown' end
    if sk.resource ~= '' and sk.cost > 0 then
        local cur = self:get(sk.resource)
        if not cur or cur < sk.cost then return false, 'not enough resource' end
        self:setBase(sk.resource, self:getBase(sk.resource) - sk.cost)
    end
    sk.cooldown_remaining = sk.cooldown
    return true
end

--- Get the current level of a named skill (0 = not learned).
--- @param name string Skill name.
--- @treturn number
function Sheet:getSkillLevel(name)
    local sk = self._skills[name]
    return sk and sk.level or 0
end

--- Get the remaining cooldown in seconds for a named skill.
--- @param name string Skill name.
--- @treturn number Seconds remaining (0 when ready).
function Sheet:getCooldownRemaining(name)
    local sk = self._skills[name]
    return sk and sk.cooldown_remaining or 0
end

-- ÔöÇÔöÇ Perks ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Define a named perk on this sheet.
--- @param name string Perk name.
--- @param opts table|nil Options: require_level, trait_name.
function Sheet:definePerk(name, opts)
    self._perks[name] = M.newPerk(opts)
end

--- Acquire a perk if requirements are met. Returns false if already acquired or level too low.
--- @param name string Perk name.
--- @treturn boolean
function Sheet:acquirePerk(name)
    local pk = self._perks[name]
    if not pk then return false end
    if pk.acquired then return false end
    if self.level < pk.require_level then return false end
    pk.acquired = true
    if pk.trait_name then self:applyTraitBuffs(pk.trait_name) end
    return true
end

--- Return true if a named perk has been acquired.
--- @param name string Perk name.
--- @treturn boolean
function Sheet:hasPerk(name)
    local pk = self._perks[name]
    return pk and pk.acquired or false
end

-- ÔöÇÔöÇ Flags ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Set a boolean flag on this sheet.
--- @param name string Flag name.
function Sheet:setFlag(name)   self._flags[name] = true end
--- Clear (remove) a boolean flag.
--- @param name string Flag name.
function Sheet:clearFlag(name) self._flags[name] = nil  end
--- Return true if a boolean flag is set.
--- @param name string Flag name.
--- @treturn boolean
function Sheet:hasFlag(name)   return self._flags[name] == true end
--- Return a sorted list of all set flag names.
--- @treturn table Sorted array of strings.
function Sheet:getFlags()
    local out = {}
    for k in pairs(self._flags) do out[#out+1] = k end
    table.sort(out)
    return out
end

-- ÔöÇÔöÇ XP / Level ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Award XP and apply automatic level-ups. Returns the number of levels gained.
--- @param amount number XP to award.
--- @treturn number Levels gained (0 if none).
function Sheet:addXP(amount)
    self.xp = self.xp + (amount or 0)
    local gained = 0
    while true do
        local threshold = self.level_thresholds:thresholdFor(self.level)
        if self.xp >= threshold then
            self.xp = self.xp - threshold
            self.level = self.level + 1
            gained = gained + 1
        else
            break
        end
    end
    return gained
end

--- Return the current accumulated XP.
--- @treturn number
function Sheet:getXP()    return self.xp    end
--- Directly set the accumulated XP (does not trigger level-ups).
--- @param v number
function Sheet:setXP(v)   self.xp = v       end
--- Return the current level.
--- @treturn number
function Sheet:getLevel() return self.level  end
--- Directly set the character level.
--- @param v number
function Sheet:setLevel(v) self.level = v    end
--- Replace the level threshold configuration.
--- @param t LevelThresholds New thresholds object.
function Sheet:setLevelThresholds(t) self.level_thresholds = t end

-- ÔöÇÔöÇ Use tracking ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Record a use of a stat for use-based levelling. Applies growth if configured.
--- @param name string Attribute name.
function Sheet:recordUse(name)
    self._use_counts[name] = (self._use_counts[name] or 0) + 1
    local attr = self._attributes[name]
    if attr and attr.growth > 0 then
        attr.base = attr.base + attr.growth
        if attr.max then attr.base = math.min(attr.base, attr.max) end
    end
end

--- Return the number of recorded uses of an attribute.
--- @param name string Attribute name.
--- @treturn number
function Sheet:getUseCount(name)
    return self._use_counts[name] or 0
end

-- ÔöÇÔöÇ Action Points ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Initialise action points with the given maximum (current also set to max).
--- @param max_val number Maximum AP.
function Sheet:setActionPoints(max_val)
    self.action_points = M.newActionPoints(max_val)
end

--- Return current and maximum action points.
--- @treturn number, number Current AP, maximum AP.
function Sheet:getActionPoints()
    if not self.action_points then return 0, 0 end
    return self.action_points.current, self.action_points.max
end

--- Spend action points. Returns false if insufficient AP.
--- @param amount number AP to spend.
--- @treturn boolean
function Sheet:spendActionPoints(amount)
    if not self.action_points then return false end
    if self.action_points.current < amount then return false end
    self.action_points.current = self.action_points.current - amount
    return true
end

--- Reset current AP to maximum (call at the start of each turn).
function Sheet:beginTurn()
    if self.action_points then
        self.action_points.current = self.action_points.max
    end
end

--- Recover AP (partial restore), capped at maximum. Returns new current value.
--- @param amount number AP to recover.
--- @treturn number New current AP.
function Sheet:recoverActionPoints(amount)
    if not self.action_points then return 0 end
    self.action_points.current = math.min(self.action_points.current + amount, self.action_points.max)
    return self.action_points.current
end

-- ÔöÇÔöÇ Morale ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Initialise the morale tracker with the given maximum.
--- @param max_val number Maximum morale value.
function Sheet:setMorale(max_val)
    self.morale = M.newMorale(max_val)
end

--- Return current and maximum morale values.
--- @treturn number, number Current morale, maximum morale.
function Sheet:getMorale()
    if not self.morale then return 0, 0 end
    return self.morale.current, self.morale.max
end

--- Adjust morale by a delta (positive or negative), clamped to [0, max].
--- @param delta number Change amount.
function Sheet:adjustMorale(delta)
    if not self.morale then return end
    self.morale.current = clamp(self.morale.current + delta, 0, self.morale.max)
end

--- Set the morale value below which the unit enters panic.
--- @param val number Panic threshold.
function Sheet:setPanicThreshold(val)
    if self.morale then self.morale.panic_threshold = val end
end

--- Set the morale value below which the unit goes berserk.
--- @param val number Berserk threshold.
function Sheet:setBerserkThreshold(val)
    if self.morale then self.morale.berserk_threshold = val end
end

--- Evaluate morale level and update panic/berserk flags.
--- @treturn string|nil "panic", "berserk", or nil if morale is normal.
function Sheet:checkMorale()
    if not self.morale then return nil end
    local cur = self.morale.current
    if cur <= self.morale.berserk_threshold then
        self:setFlag('berserk'); self:clearFlag('panic')
        return 'berserk'
    elseif cur <= self.morale.panic_threshold then
        self:setFlag('panic'); self:clearFlag('berserk')
        return 'panic'
    else
        self:clearFlag('panic'); self:clearFlag('berserk')
        return nil
    end
end

-- ÔöÇÔöÇ Resistances ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Set resistance to a damage type (clamped to [0, 1]).
--- @param dtype string Damage type name (e.g. "fire").
--- @param val number Resistance fraction (0 = none, 1 = immune).
function Sheet:setResistance(dtype, val)
    self._resistances[dtype] = clamp(val, 0, 1)
end

--- Return the resistance fraction for a damage type (default 0).
--- @param dtype string Damage type name.
--- @treturn number
function Sheet:getResistance(dtype)
    return self._resistances[dtype] or 0
end

--- Apply damage to an attribute, reduced by resistance. Returns actual damage dealt.
--- @param stat string Attribute to damage (typically "hp").
--- @param amount number Raw incoming damage.
--- @param dtype string|nil Damage type for resistance lookup.
--- @treturn number Actual damage applied after resistance.
function Sheet:applyDamage(stat, amount, dtype)
    local attr = self._attributes[stat]
    if not attr then return 0 end
    local resistance = dtype and (self._resistances[dtype] or 0) or 0
    local actual = math.max(amount * (1 - resistance), 0)
    attr.base = math.max(attr.base - actual, attr.min)
    return actual
end

-- ÔöÇÔöÇ Encumbrance ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Set current encumbrance and its maximum capacity.
--- @param cur number Current carried weight.
--- @param max_val number Maximum capacity before encumbered.
function Sheet:setEncumbrance(cur, max_val)
    self.encumbrance = { cur, max_val }
end

--- Return current and maximum encumbrance values.
--- @treturn number, number Current weight, maximum capacity.
function Sheet:getEncumbrance()
    if not self.encumbrance then return 0, 0 end
    return self.encumbrance[1], self.encumbrance[2]
end

--- Return true if current weight exceeds the encumbrance limit.
--- @treturn boolean
function Sheet:isEncumbered()
    if not self.encumbrance then return false end
    return self.encumbrance[1] > self.encumbrance[2]
end

-- ÔöÇÔöÇ Initiative ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Set the sheet's base initiative value.
--- @param val number Initiative value.
function Sheet:setInitiative(val) self.initiative = val end
--- Return the current initiative value.
--- @treturn number
function Sheet:getInitiative()    return self.initiative end

-- ÔöÇÔöÇ Update (tick) ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Advance time: tick buff durations, skill cooldowns, apply regen.
--- @param dt number Elapsed seconds.
function Sheet:update(dt)
    -- Tick buffs
    for h, b in pairs(self._buffs) do
        if b.duration >= 0 then
            b.remaining = b.remaining - dt
            if b.remaining <= 0 then self._buffs[h] = nil end
        end
    end
    -- Clean active_traits handles
    for tname, handles in pairs(self._active_traits) do
        local alive = {}
        for _, h in ipairs(handles) do
            if self._buffs[h] then alive[#alive+1] = h end
        end
        if #alive == 0 then
            self._active_traits[tname] = nil
        else
            self._active_traits[tname] = alive
        end
    end
    -- Tick skill cooldowns
    for _, sk in pairs(self._skills) do
        if sk.cooldown_remaining > 0 then
            sk.cooldown_remaining = math.max(sk.cooldown_remaining - dt, 0)
        end
    end
    -- Apply regen
    for name, attr in pairs(self._attributes) do
        if attr.regen ~= 0 then
            attr.base = attr.base + attr.regen * dt
            if attr.max then attr.base = math.min(attr.base, attr.max) end
            attr.base = math.max(attr.base, attr.min)
        end
    end
end

-- ÔöÇÔöÇ Snapshot / Restore ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Capture a snapshot of the sheet's core state (attributes, XP, level, flags, resistances, AP, morale).
--- @treturn table Snapshot table suitable for Sheet:restore.
function Sheet:snapshot()
    local attrs = {}
    for name, attr in pairs(self._attributes) do
        attrs[name] = { base = attr.base, min = attr.min, max = attr.max, regen = attr.regen, growth = attr.growth }
    end
    local snap = {
        attributes = attrs,
        xp         = self.xp,
        level      = self.level,
        flags      = {},
        resistances = {},
    }
    for k in pairs(self._flags) do snap.flags[#snap.flags+1] = k end
    for k, v in pairs(self._resistances) do snap.resistances[k] = v end
    if self.action_points then
        snap.action_points = { current = self.action_points.current, max = self.action_points.max }
    end
    if self.morale then
        snap.morale = { current = self.morale.current, max = self.morale.max,
                        panic_threshold = self.morale.panic_threshold,
                        berserk_threshold = self.morale.berserk_threshold }
    end
    return snap
end

--- Restore sheet state from a snapshot previously created by Sheet:snapshot.
--- @param snap table Snapshot table created by Sheet:snapshot.
function Sheet:restore(snap)
    self._attributes = {}
    for name, data in pairs(snap.attributes or {}) do
        local attr = M.newAttribute(data.base)
        attr.min    = data.min    or -math.huge
        attr.max    = data.max
        attr.regen  = data.regen  or 0
        attr.growth = data.growth or 0
        self._attributes[name] = attr
    end
    self.xp    = snap.xp    or 0
    self.level = snap.level or 1
    self._flags = {}
    for _, k in ipairs(snap.flags or {}) do self._flags[k] = true end
    self._resistances = {}
    for k, v in pairs(snap.resistances or {}) do self._resistances[k] = v end
    if snap.action_points then
        self.action_points = M.newActionPoints(snap.action_points.max)
        self.action_points.current = snap.action_points.current
    end
    if snap.morale then
        self.morale = M.newMorale(snap.morale.max)
        self.morale.current           = snap.morale.current
        self.morale.panic_threshold   = snap.morale.panic_threshold
        self.morale.berserk_threshold = snap.morale.berserk_threshold
    end
end

return M
