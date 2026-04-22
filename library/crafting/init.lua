--- @module library.crafting
--- @status full
--- Crafting system: recipes, ingredients, outputs, job queues, stations,
--- craft skills, perk trees, upgrade trees, modifier pools, and recipe knowledge.
--- Pure-Lua port of src/crafting/.
--- @see lurek.serial
--- @see lurek.patterns
--- @see lurek.event
--- @see lurek.log

local M = {}

-- Optional logging via lurek.log (no-op if unavailable).
-- Hardened against the prior bug where a non-nil `lurek` table with a nil
-- `lurek.log` would set `_log = nil` and crash later `_log.warn(...)` calls.
-- @see lurek.log
local _log
do
    local ok, log_mod = pcall(function() return lurek and lurek.log end)
    if ok and type(log_mod) == 'table' then
        _log = log_mod
    else
        _log = nil
    end
    if not _log then
        local noop = function() end
        _log = { info = noop, warn = noop, debug = noop, error = noop }
    end
end

M.Quality = {
    Normal     = 'normal',
    Fine       = 'fine',
    Superior   = 'superior',
    Excellent  = 'excellent',
    Masterwork = 'masterwork',
    Legendary  = 'legendary',
}

local quality_order = { 'normal', 'fine', 'superior', 'excellent', 'masterwork', 'legendary' }

--- Convert string to Quality value.
function M.qualityFromStr(s)
    for _, q in ipairs(quality_order) do if q == s then return s end end
    return nil
end

--- Quality to display string.
function M.qualityToStr(q) return q or 'normal' end

-- ÔöÇÔöÇ Helpers ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local function clamp01(v) return math.max(0, math.min(1, v)) end

-- ÔöÇÔöÇ Ingredient ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Ingredient = {}
Ingredient.__index = Ingredient

--- Create ingredient by item type.
--- @tparam string item_type  Item ID to require.
--- @tparam number quantity   Positive count required (default 1).
--- @treturn Ingredient
function M.newIngredient(item_type, quantity)
    quantity = quantity or 1
    if type(quantity) ~= 'number' or quantity <= 0 then
        _log.warn('newIngredient: quantity must be positive, got ' .. tostring(quantity))
        quantity = 1
    end
    return setmetatable({
        item_type = item_type or '',
        quantity  = quantity,
        consumed  = true,
        tag       = '',
    }, Ingredient)
end

--- Create ingredient by tag.
--- @tparam string tag       Tag selector string.
--- @tparam number quantity  Positive count required (default 1).
--- @treturn Ingredient
function M.newIngredientTag(tag, quantity)
    quantity = quantity or 1
    if type(quantity) ~= 'number' or quantity <= 0 then
        _log.warn('newIngredientTag: quantity must be positive, got ' .. tostring(quantity))
        quantity = 1
    end
    return setmetatable({
        item_type = '',
        quantity  = quantity,
        consumed  = true,
        tag       = tag or '',
    }, Ingredient)
end

--- Return true if this ingredient selects by tag rather than item_type.
--- **Precedence**: when both `tag` and `item_type` are non-empty, the tag
--- takes precedence — matching code should check `isTag()` first.
--- @treturn boolean
function Ingredient:isTag() return self.tag ~= '' end

-- ÔöÇÔöÇ RecipeOutput ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local RecipeOutput = {}
RecipeOutput.__index = RecipeOutput

--- Create a guaranteed recipe output with normal quality.
--- @tparam string item_type  Item ID produced.
--- @tparam number quantity   Positive count produced (default 1).
--- @treturn RecipeOutput
function M.newRecipeOutput(item_type, quantity)
    quantity = quantity or 1
    if type(quantity) ~= 'number' or quantity <= 0 then
        _log.warn('newRecipeOutput: quantity must be positive, got ' .. tostring(quantity))
        quantity = 1
    end
    return setmetatable({
        item_type   = item_type or '',
        quantity    = quantity,
        quality     = M.Quality.Normal,
        chance      = 1.0,
        is_byproduct = false,
    }, RecipeOutput)
end

--- Create a probabilistic recipe output with an explicit chance.
--- @tparam string item_type  Item ID produced.
--- @tparam number quantity   Positive count produced (default 1).
--- @tparam number chance     Probability in [0, 1].
--- @treturn RecipeOutput
function M.newRecipeOutputWithChance(item_type, quantity, chance)
    local o = M.newRecipeOutput(item_type, quantity)
    o.chance = clamp01(chance or 1.0)
    return o
end

-- ÔöÇÔöÇ Recipe ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Recipe = {}
Recipe.__index = Recipe

--- Create a recipe with default metadata.
---
--- A recipe holds: `id`, `recipe_type`, `name`, `description`, `category`,
--- `station_type`, `station_level`, `time` (seconds), `cooldown`,
--- `fuel_consumption_rate`, `ingredients` (list of Ingredient),
--- `outputs` (list of RecipeOutput), `remainder_item`, `skill`, `skill_level`,
--- `skill_xp`, `enabled`, `hand_craftable`, `tags`, `knowledge_mode`,
--- `discovery_hint`, `grid_width`, `grid_height`, `grid_slots`, `grid_mirror`,
--- `grid_rotation`, `required_nearby_stations`, `required_biome`,
--- `required_location`, `orange/yellow/green/grey_threshold`,
--- `upgrade_from`, `upgrade_to`, `alternatives`,
--- `output_quality_scaling`, `random_modifier_pool`, `skill_up_curve`,
--- `conditions`, `metadata`.
---
--- @tparam string id  Stable recipe identifier (must be non-empty).
--- @treturn Recipe
function M.newRecipe(id)
    return setmetatable({
        id                     = id,
        recipe_type            = '',
        name                   = id,
        description            = '',
        category               = '',
        station_type           = '',
        station_level          = 0,
        time                   = 1.0,
        cooldown               = 0,
        fuel_consumption_rate  = 0,
        ingredients            = {},
        outputs                = {},
        remainder_item         = '',
        skill                  = '',
        skill_level            = 0,
        skill_xp               = 0,
        enabled                = true,
        hand_craftable         = true,
        tags                   = {},
        knowledge_mode         = 'always',
        discovery_hint         = '',
        grid_width             = 0,
        grid_height            = 0,
        grid_slots             = {},
        grid_mirror            = false,
        grid_rotation          = false,
        required_nearby_stations = {},
        required_biome         = '',
        required_location      = '',
        orange_threshold       = 0,
        yellow_threshold       = 0,
        green_threshold        = 0,
        grey_threshold         = 0,
        upgrade_from           = '',
        upgrade_to             = {},
        alternatives           = {},
        output_quality_scaling = false,
        random_modifier_pool   = '',
        skill_up_curve         = 'linear',
        conditions             = {},
        metadata               = {},
    }, Recipe)
end

--- Append an ingredient requirement to the recipe.
-- @param ing Ingredient

function Recipe:addIngredient(ing) self.ingredients[#self.ingredients+1] = ing end
--- Append an output definition to the recipe.
-- @param out RecipeOutput

function Recipe:addOutput(out)     self.outputs[#self.outputs+1] = out end
--- Remove all ingredients from this recipe.

function Recipe:clearIngredients() self.ingredients = {} end
--- Remove all outputs from this recipe.

function Recipe:clearOutputs()     self.outputs = {} end

--- Return the tag list for this recipe.
-- @treturn table

function Recipe:getTags() return self.tags end
--- Return true if the recipe carries the given tag.
-- @param t string
-- @treturn boolean
function Recipe:hasTag(t)
    for _, tag in ipairs(self.tags) do if tag == t then return true end end
    return false
end

--- Assign an item type to a shaped-recipe grid slot (0-based).
--- Returns false with a warning if coordinates are out of bounds.
--- @tparam number x         Grid column (0-based, must be < grid_width).
--- @tparam number y         Grid row (0-based, must be < grid_height).
--- @tparam string item_type Item ID expected in the slot.
--- @treturn boolean true if the slot was set, false if out of bounds.
function Recipe:setGridSlot(x, y, item_type)
    if self.grid_width <= 0 or self.grid_height <= 0 then
        _log.warn('setGridSlot: grid dimensions not set (width=' .. tostring(self.grid_width) .. ', height=' .. tostring(self.grid_height) .. ')')
        return false
    end
    if type(x) ~= 'number' or x < 0 or x >= self.grid_width then
        _log.warn('setGridSlot: x=' .. tostring(x) .. ' out of bounds [0, ' .. tostring(self.grid_width - 1) .. ']')
        return false
    end
    if type(y) ~= 'number' or y < 0 or y >= self.grid_height then
        _log.warn('setGridSlot: y=' .. tostring(y) .. ' out of bounds [0, ' .. tostring(self.grid_height - 1) .. ']')
        return false
    end
    self.grid_slots[y * self.grid_width + x] = item_type
    return true
end

--- Add a byproduct output with a drop chance.
-- @param item_type string
-- @param quantity  number
-- @param chance    number  Probability in [0, 1].
function Recipe:addByproduct(item_type, quantity, chance)
    local o = M.newRecipeOutputWithChance(item_type, quantity, chance)
    o.is_byproduct = true
    self.outputs[#self.outputs+1] = o
end

--- Add a crafting condition requirement.
-- @param ctype  string  Condition type key.
-- @param cvalue string  Condition value.
function Recipe:addCondition(ctype, cvalue)
    self.conditions[#self.conditions+1] = { type = ctype, value = cvalue }
end

--- Return the conditions list.
-- @treturn table

function Recipe:getConditions() return self.conditions end

-- ÔöÇÔöÇ RecipeRegistry ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local RecipeRegistry = {}
RecipeRegistry.__index = RecipeRegistry

--- Create an empty recipe registry.
-- @treturn RecipeRegistry
function M.newRecipeRegistry()
    return setmetatable({ recipes = {}, order = {} }, RecipeRegistry)
end

--- Register a recipe in the registry.
--- @tparam Recipe recipe  The recipe to register.
function RecipeRegistry:add(recipe)
    if not recipe or not recipe.id or recipe.id == '' then
        _log.warn('RecipeRegistry:add: recipe must have a non-empty id')
        return
    end
    _log.debug('RecipeRegistry: registered recipe "' .. recipe.id .. '"')
    self.recipes[recipe.id] = recipe
    self.order[#self.order+1] = recipe.id
end

--- Look up a recipe by ID.
-- @param id string
-- @treturn Recipe|nil

function RecipeRegistry:get(id) return self.recipes[id] end

--- Remove a recipe by ID. Returns true if it existed.
-- @param id string
-- @treturn boolean
function RecipeRegistry:remove(id)
    if not self.recipes[id] then return false end
    self.recipes[id] = nil
    for i, oid in ipairs(self.order) do
        if oid == id then table.remove(self.order, i); break end
    end
    return true
end

--- Return the number of registered recipes.
-- @treturn number

function RecipeRegistry:count() return #self.order end

--- Return all recipe IDs in registration order.
-- @treturn table
function RecipeRegistry:ids()
    local out = {}
    for _, id in ipairs(self.order) do out[#out+1] = id end
    return out
end

--- Find recipes that produce a specific item type.
-- @param item_type string
-- @treturn table  list of Recipe
function RecipeRegistry:findByOutput(item_type)
    local out = {}
    for _, id in ipairs(self.order) do
        local r = self.recipes[id]
        for _, o in ipairs(r.outputs) do
            if o.item_type == item_type then out[#out+1] = r; break end
        end
    end
    return out
end

--- Find recipes that consume a specific item type.
-- @param item_type string
-- @treturn table  list of Recipe
function RecipeRegistry:findByIngredient(item_type)
    local out = {}
    for _, id in ipairs(self.order) do
        local r = self.recipes[id]
        for _, ing in ipairs(r.ingredients) do
            if ing.item_type == item_type then out[#out+1] = r; break end
        end
    end
    return out
end

--- Find recipes carrying a specific tag.
-- @param tag string
-- @treturn table  list of Recipe
function RecipeRegistry:findByTag(tag)
    local out = {}
    for _, id in ipairs(self.order) do
        local r = self.recipes[id]
        if r:hasTag(tag) then out[#out+1] = r end
    end
    return out
end

--- Find recipes that require a specific station type.
-- @param station_type string
-- @treturn table  list of Recipe
function RecipeRegistry:forStation(station_type)
    local out = {}
    for _, id in ipairs(self.order) do
        local r = self.recipes[id]
        if r.station_type == station_type then out[#out+1] = r end
    end
    return out
end

--- Find recipes in a UI category.
-- @param cat string
-- @treturn table  list of Recipe
function RecipeRegistry:findByCategory(cat)
    local out = {}
    for _, id in ipairs(self.order) do
        local r = self.recipes[id]
        if r.category == cat then out[#out+1] = r end
    end
    return out
end

--- Find recipes gated by a skill, optionally capped to max_level.
-- @param name      string
-- @param max_level number|nil  If set, only recipes at or below this level.
-- @treturn table  list of Recipe
function RecipeRegistry:findBySkill(name, max_level)
    local out = {}
    for _, id in ipairs(self.order) do
        local r = self.recipes[id]
        if r.skill == name then
            if not max_level or r.skill_level <= max_level then
                out[#out+1] = r
            end
        end
    end
    return out
end

--- Find all hand-craftable recipes.
-- @treturn table  list of Recipe
function RecipeRegistry:findHandCraftable()
    local out = {}
    for _, id in ipairs(self.order) do
        local r = self.recipes[id]
        if r.hand_craftable then out[#out+1] = r end
    end
    return out
end

-- ÔöÇÔöÇ CraftJob ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
-- removed duplicate factory: original at line 416 (M.newCraftJob)
-- removed duplicate factory: original at line 450 (M.newCraftQueue)
-- The canonical CraftJob/CraftQueue definitions live further down in this
-- file (search for "ÔöÇÔöÇ CraftJob"). The earlier blocks were silently shadowed
-- at module load and are removed in P7 batch A. See work/library-overhaul-20260418/
-- reports/P0_library_audit.md ┬º2.4 for the original defect citation.

-- ÔöÇÔöÇ Station ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Station = {}
Station.__index = Station

--- Create a crafting station with default state.
-- @param name         string  Display name.
-- @param station_type string  Stable station type identifier.
-- @treturn Station
function M.newStation(name, station_type)
    return setmetatable({
        name             = name,
        station_type     = station_type,
        level            = 1,
        max_level        = 10,
        active           = true,
        fuel             = 0,
        max_fuel         = 100,
        fuel_rate        = 1.0,
        modules          = {},
        module_limit     = 4,
        attachments      = {},
        attachment_limit = 6,
        stats            = {},
        efficiency       = 1.0,
        requires_cover   = false,
        has_cover        = false,
        metadata         = {},
    }, Station)
end

--- Add fuel, clamped to max_fuel. Negative amounts are ignored.
--- @tparam number amount  Fuel to add (must be non-negative).
--- @treturn number  New fuel level.
function Station:addFuel(amount)
    if type(amount) ~= 'number' or amount < 0 then
        _log.warn('Station:addFuel: amount must be non-negative, got ' .. tostring(amount))
        return self.fuel
    end
    self.fuel = math.min(self.fuel + amount, self.max_fuel)
    return self.fuel
end

--- Consume fuel. Returns false if insufficient or amount is invalid.
--- @tparam number amount  Fuel to consume (must be non-negative).
--- @treturn boolean  true if fuel was consumed, false otherwise.
function Station:consumeFuel(amount)
    if type(amount) ~= 'number' or amount < 0 then
        _log.warn('Station:consumeFuel: amount must be non-negative, got ' .. tostring(amount))
        return false
    end
    if self.fuel < amount then
        _log.debug('Station:consumeFuel: insufficient fuel (' .. tostring(self.fuel) .. ' < ' .. tostring(amount) .. ')')
        return false
    end
    self.fuel = self.fuel - amount
    return true
end

--- Return true if fuel >= amount.
-- @param amount number
-- @treturn boolean

function Station:hasFuel(amount) return self.fuel >= amount end

--- Return fuel as a fraction of max_fuel in [0, 1].
-- @treturn number
function Station:fuelPercent()
    if self.max_fuel <= 0 then return 0 end
    return self.fuel / self.max_fuel
end

local function list_has(list, name)
    for _, v in ipairs(list) do if v == name then return true end end
    return false
end

local function list_remove(list, name)
    for i, v in ipairs(list) do if v == name then table.remove(list, i); return true end end
    return false
end

--- Install a named module. Returns false if at capacity or already present.
-- @param name string
-- @treturn boolean
function Station:addModule(name)
    if #self.modules >= self.module_limit then return false end
    if list_has(self.modules, name) then return false end
    self.modules[#self.modules+1] = name
    return true
end

--- Remove a named module. Returns true if found.
-- @param name string
-- @treturn boolean

function Station:removeModule(name) return list_remove(self.modules, name) end
--- Return true if the station has the named module installed.
-- @param name string
-- @treturn boolean

function Station:hasModule(name)    return list_has(self.modules, name) end

--- Add a physical attachment. Returns false if at capacity or duplicate.
-- @param name string
-- @treturn boolean
function Station:addAttachment(name)
    if #self.attachments >= self.attachment_limit then return false end
    if list_has(self.attachments, name) then return false end
    self.attachments[#self.attachments+1] = name
    return true
end

--- Remove an attachment. Returns true if found.
-- @param name string
-- @treturn boolean

function Station:removeAttachment(name) return list_remove(self.attachments, name) end
--- Return true if the station has the named attachment.
-- @param name string
-- @treturn boolean

function Station:hasAttachment(name)    return list_has(self.attachments, name) end

--- Set an arbitrary named stat.
-- @param k string
-- @param v number

function Station:setStat(k, v)  self.stats[k] = v end
--- Get a named stat (0 if not set).
-- @param k string
-- @treturn number

function Station:getStat(k)     return self.stats[k] or 0 end

--- Return true if the station can be upgraded further.
-- @treturn boolean

function Station:canUpgrade() return self.level < self.max_level end

--- Increment station level. Returns false if already at max.
-- @treturn boolean
function Station:upgrade()
    if not self:canUpgrade() then return false end
    self.level = self.level + 1
    return true
end

--- Set the station efficiency multiplier (clamped to >= 0).
-- @param val number

function Station:setEfficiency(val) self.efficiency = math.max(0, val) end

-- ÔöÇÔöÇ CraftSkill ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local CraftSkill = {}
CraftSkill.__index = CraftSkill

--- Create a crafting skill with default linear progression.
-- @param name string  Skill name such as "smithing".
-- @treturn CraftSkill
function M.newCraftSkill(name)
    return setmetatable({
        name         = name,
        level        = 1,
        max_level    = 100,
        xp           = 0,
        xp_curve     = 'linear',
        perk_points  = 0,
        perks        = {},
        perk_tree    = {},
    }, CraftSkill)
end

local function xp_for_level(curve, l)
    if curve == 'quadratic' then return l * l * 100
    else return l * 100 end
end

--- Add XP and level up as many times as the XP allows.
-- @param amount number  XP to add.
-- @treturn number  Levels gained.
function CraftSkill:addXP(amount)
    self.xp = self.xp + amount
    local gained = 0
    while self.level < self.max_level do
        local required = xp_for_level(self.xp_curve, self.level)
        if self.xp >= required then
            self.xp = self.xp - required
            self.level = self.level + 1
            gained = gained + 1
        else break end
    end
    return gained
end

--- Set the XP curve name ("linear" or "quadratic").
-- @param name string

function CraftSkill:setXPCurve(name)  self.xp_curve = name end
--- Return the current skill level.
-- @treturn number

function CraftSkill:getLevel()        return self.level end
--- Return current XP within the current level.
-- @treturn number

function CraftSkill:getXP()           return self.xp end

--- Grant one free perk point.
function CraftSkill:grantPerkPoint()
    self.perk_points = self.perk_points + 1
end

--- Spend a perk point to unlock a perk by name. Returns false if no points or perk not unlockable.
-- @param perk_name string
-- @treturn boolean
function CraftSkill:spendPerkPoint(perk_name)
    if self.perk_points < 1 then return false end
    -- check perk tree
    local node = self.perk_tree[perk_name]
    if node then
        if not node:canUnlock(self.level, self.perks) then return false end
        node:unlock()
    end
    self.perk_points = self.perk_points - 1
    self.perks[#self.perks+1] = perk_name
    return true
end

--- Return true if the named perk is unlocked.
-- @param name string
-- @treturn boolean
function CraftSkill:hasPerk(name)
    for _, p in ipairs(self.perks) do if p == name then return true end end
    return false
end

--- Register a PerkNode in the skill perk tree.
-- @param node PerkNode
function CraftSkill:addPerkToTree(node)
    self.perk_tree[node.name] = node
end

--- Return the perk tree table.
-- @treturn table

function CraftSkill:getPerkTree() return self.perk_tree end

-- ÔöÇÔöÇ CraftSkillRarity enum ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Rarity tiers used to classify crafting skills or unlock conditions.
M.CraftSkillRarity = {
    COMMON   = 'common',
    UNCOMMON = 'uncommon',
    RARE     = 'rare',
    EPIC     = 'epic',
}

-- ÔöÇÔöÇ PerkNode ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local PerkNode = {}
PerkNode.__index = PerkNode

--- Create a locked perk node.
-- @param name string  Stable perk identifier.
-- @treturn PerkNode
function M.newPerkNode(name)
    return setmetatable({
        name           = name,
        description    = '',
        required_level = 0,
        cost           = 1,
        unlocked       = false,
        prerequisites  = {},
        bonuses        = {},
    }, PerkNode)
end

--- Return true if the perk can be unlocked now.
-- @param skill_level    number  Current skill level.
-- @param unlocked_perks table   List of already-unlocked perk names.
-- @treturn boolean
function PerkNode:canUnlock(skill_level, unlocked_perks)
    if self.unlocked then return false end
    if skill_level < self.required_level then return false end
    for _, prereq in ipairs(self.prerequisites) do
        local found = false
        for _, p in ipairs(unlocked_perks) do if p == prereq then found = true; break end end
        if not found then return false end
    end
    return true
end

--- Mark the perk as unlocked.

function PerkNode:unlock() self.unlocked = true end

-- ÔöÇÔöÇ UpgradeNode/Tree ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
-- removed duplicate factory: original at line 821 (M.newUpgradeNode)
-- removed duplicate factory: original at line 835 (M.newUpgradeTree)
-- The canonical UpgradeNode/UpgradeTree definitions live further down (around
-- line ~1100 / ~1145). The earlier blocks were silently shadowed at module
-- load and are removed in P7 batch A. The first UpgradeTree:availableUpgrades
-- method was already unreachable at runtime because the second
-- `local UpgradeTree = {}` rebinding wiped the metatable. See
-- work/library-overhaul-20260418/reports/P0_library_audit.md ┬º2.4.

-- ÔöÇÔöÇ ModifierEntry/Pool ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local ModifierEntry = {}
ModifierEntry.__index = ModifierEntry

--- Create a weighted modifier entry.
-- @param name   string  Stable modifier identifier.
-- @param weight number  Relative selection weight (default 1).
-- @treturn ModifierEntry
function M.newModifierEntry(name, weight)
    return setmetatable({ name = name, weight = weight or 1, bonuses = {} }, ModifierEntry)
end

local ModifierPool = {}
ModifierPool.__index = ModifierPool

--- Create an empty modifier pool.
-- @treturn ModifierPool
function M.newModifierPool()
    return setmetatable({ entries = {} }, ModifierPool)
end

--- Add a ModifierEntry to the pool.
-- @param entry ModifierEntry

function ModifierPool:add(entry) self.entries[#self.entries+1] = entry end

--- Select a random weighted modifier entry (non-deterministic).
-- @treturn ModifierEntry|nil  nil if pool is empty.
function ModifierPool:roll()
    if #self.entries == 0 then return nil end
    local total = 0
    for _, e in ipairs(self.entries) do total = total + e.weight end
    if total <= 0 then return nil end
    local r = math.random() * total
    local acc = 0
    for _, e in ipairs(self.entries) do
        acc = acc + e.weight
        if r <= acc then return e end
    end
    return self.entries[#self.entries]
end

--- Alias for roll(). Select a random weighted modifier entry.
-- @treturn ModifierEntry|nil
function ModifierPool:draw() return self:roll() end

-- ÔöÇÔöÇ RecipeKnowledge ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local RecipeKnowledge = {}
RecipeKnowledge.__index = RecipeKnowledge

function M.newRecipeKnowledge()
    return setmetatable({ known = {}, groups = {} }, RecipeKnowledge)
end

--- Discover a recipe. Optional source label ("craft", "research", "loot", etc.).
-- @param recipe_id string
-- @param source    string|nil
-- @treturn boolean true if newly discovered
function RecipeKnowledge:discover(recipe_id, source)
    if self.known[recipe_id] then return false end
    self.known[recipe_id] = true
    if source then
        self.sources = self.sources or {}
        self.sources[recipe_id] = source
    end
    return true
end

--- Return true if the recipe is known (or auto-discover is enabled).
-- @param id string
-- @treturn boolean
function RecipeKnowledge:isKnown(id)
    if self._auto_discover then return true end
    return self.known[id] == true
end

--- Return the number of discovered recipes.
-- @treturn number
function RecipeKnowledge:knownCount()
    local n = 0
    for _ in pairs(self.known) do n = n + 1 end
    return n
end

--- Return all known recipe IDs sorted alphabetically.
-- @treturn table
function RecipeKnowledge:knownIds()
    local out = {}
    for id in pairs(self.known) do out[#out+1] = id end
    table.sort(out)
    return out
end

--- Register a named group of recipe IDs for UI organisation.
-- @param name string
-- @param ids  table  list of recipe ID strings
function RecipeKnowledge:addGroup(name, ids)
    self.groups[name] = ids
end

--- Return the recipe ID list for a named group (nil if unknown).
-- @param name string
-- @treturn table|nil

function RecipeKnowledge:getGroup(name) return self.groups[name] end

--- Return (known_count, total_count) for a named group.
-- @param name string
-- @treturn number  known count
-- @treturn number  total count
function RecipeKnowledge:groupProgress(name)
    local ids = self.groups[name]
    if not ids then return 0, 0 end
    local known = 0
    for _, id in ipairs(ids) do
        if self.known[id] then known = known + 1 end
    end
    return known, #ids
end

-- ÔöÇÔöÇ RecipeGroup ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
-- removed duplicate factory: original at line 977 (M.newRecipeGroup)
-- The earlier plain-table version was silently shadowed by the proper
-- RecipeGroup class defined further down (search for "RecipeGroup: proper
-- object"). Removing the dead earlier version preserves runtime behavior;
-- the canonical definition exposes addRecipe/removeRecipe/getRecipes/etc.
-- See work/library-overhaul-20260418/reports/P0_library_audit.md ┬º2.4.

-- ÔöÇÔöÇ CraftJob ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local CraftJob = {}
CraftJob.__index = CraftJob

--- Create a new craft job tracking a recipe in progress.
-- @param id          number  unique job id
-- @param recipe_id   string
-- @param total_time  number  seconds to complete
-- @param quantity    number  units to produce
-- @treturn CraftJob
function M.newCraftJob(id, recipe_id, total_time, quantity)
    return setmetatable({
        id          = id,
        recipe_id   = recipe_id,
        total_time  = total_time or 1.0,
        quantity    = quantity or 1,
        progress    = 0.0,
        completed   = false,
        paused      = false,
    }, CraftJob)
end

--- Advance the job by dt seconds. Returns true when newly completed.
-- @param dt number
-- @treturn boolean
function CraftJob:advance(dt)
    if self.completed or self.paused then return false end
    self.progress = self.progress + dt
    if self.progress >= self.total_time then
        self.progress  = self.total_time
        self.completed = true
        return true
    end
    return false
end

--- Return completion fraction 0ÔÇô1.
-- @treturn number
function CraftJob:percent()
    if self.total_time <= 0 then return 1 end
    return math.min(self.progress / self.total_time, 1)
end

--- Pause the job (stops time advancing).
function CraftJob:pause()  self.paused = true  end
--- Resume the job.
function CraftJob:resume() self.paused = false end
--- Return true if the job is completed.
-- @treturn boolean
function CraftJob:isCompleted() return self.completed end
--- Return true if the job is paused.
-- @treturn boolean
function CraftJob:isPaused() return self.paused end
--- Return remaining seconds.
-- @treturn number
function CraftJob:remaining() return math.max(0, self.total_time - self.progress) end

-- ÔöÇÔöÇ CraftQueue ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local CraftQueue = {}
CraftQueue.__index = CraftQueue

--- Create a new craft queue.
-- @param max_jobs number  maximum total queued jobs (default 5)
-- @treturn CraftQueue
function M.newCraftQueue(max_jobs)
    return setmetatable({
        _max_jobs       = max_jobs or 5,
        _max_concurrent = max_jobs or 5,  -- default = same as max_jobs
        _next_id        = 1,
        _jobs           = {},
        _completed      = {},
    }, CraftQueue)
end

--- Set how many jobs can advance in parallel (must be <= max_jobs).
-- @param n number
function CraftQueue:setMaxConcurrent(n) self._max_concurrent = n end
--- Get the maximum concurrent job count.
-- @treturn number
function CraftQueue:maxJobs() return self._max_jobs end

--- Enqueue a new craft job. Returns the job id, or nil if queue is full.
-- @param recipe_id   string
-- @param total_time  number
-- @param quantity    number
-- @treturn number|nil
function CraftQueue:enqueue(recipe_id, total_time, quantity)
    if #self._jobs >= self._max_jobs then return nil end
    local id = self._next_id; self._next_id = self._next_id + 1
    self._jobs[#self._jobs+1] = M.newCraftJob(id, recipe_id, total_time or 1.0, quantity or 1)
    return id
end

--- Cancel a job by id. Returns true if the job was removed.
-- @param id number
-- @treturn boolean
function CraftQueue:cancel(id)
    for i, job in ipairs(self._jobs) do
        if job.id == id then table.remove(self._jobs, i); return true end
    end
    return false
end

--- Advance all jobs by dt seconds. Returns list of newly-completed job IDs.
--- Completed jobs are automatically removed from the active job list.
--- Use `collectCompleted()` to retrieve and clear the cumulative completion log.
--- @tparam number dt  Delta time in seconds.
--- @treturn table  List of job IDs that completed this tick.
function CraftQueue:update(dt)
    local done = {}
    local active = 0
    for _, job in ipairs(self._jobs) do
        if not job.completed then
            if active < self._max_concurrent then
                active = active + 1
                if job:advance(dt) then
                    self._completed[#self._completed+1] = job.id
                    done[#done+1] = job.id
                    _log.debug('CraftQueue: job ' .. tostring(job.id) .. ' (' .. tostring(job.recipe_id) .. ') completed')
                end
            end
        end
    end
    -- Auto-remove completed jobs from the active list
    if #done > 0 then
        local kept = {}
        for _, job in ipairs(self._jobs) do
            if not job.completed then kept[#kept+1] = job end
        end
        self._jobs = kept
    end
    return done
end

--- Remove and return all completed job ids since last collect.
-- @treturn table
function CraftQueue:collectCompleted()
    local out = self._completed
    self._completed = {}
    -- also prune completed jobs from active list
    local kept = {}
    for _, job in ipairs(self._jobs) do
        if not job.completed then kept[#kept+1] = job end
    end
    self._jobs = kept
    return out
end

--- Get a job by id (active jobs only).
-- @param id number
-- @treturn CraftJob|nil
function CraftQueue:getJob(id)
    for _, job in ipairs(self._jobs) do
        if job.id == id then return job end
    end
    return nil
end

--- Return total active job count (not including completed-but-uncollected).
-- @treturn number
function CraftQueue:count()
    local n = 0
    for _, job in ipairs(self._jobs) do if not job.completed then n = n+1 end end
    return n
end

--- Return true if the queue is full.
-- @treturn boolean
function CraftQueue:isFull() return self:count() >= self._max_jobs end

--- Return sorted list of active (not-completed) job IDs.
-- @treturn table
function CraftQueue:activeIds()
    local out = {}
    for _, job in ipairs(self._jobs) do
        if not job.completed then out[#out+1] = job.id end
    end
    return out
end

--- Return all active jobs as summary tuples.
-- @treturn table  list of {id, recipe_id, quantity, percent, completed}
function CraftQueue:allJobs()
    local out = {}
    for _, job in ipairs(self._jobs) do
        out[#out+1] = {job.id, job.recipe_id, job.quantity, job:percent(), job.completed}
    end
    return out
end

--- Clear all jobs from the queue.
function CraftQueue:clear()
    self._jobs      = {}
    self._completed = {}
end

-- ÔöÇÔöÇ UpgradeNode ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local UpgradeNode = {}
UpgradeNode.__index = UpgradeNode

--- Create a new upgrade node.
-- @param id   string
-- @param name string
-- @treturn UpgradeNode
function M.newUpgradeNode(id, name)
    return setmetatable({
        id              = id,
        name            = name or id,
        description     = '',
        unlocked        = false,
        cost            = 0,
        required_level  = 0,
        prerequisites   = {},
        effects         = {},
        tags            = {},
    }, UpgradeNode)
end

--- Set the unlock cost.
-- @param cost number
function UpgradeNode:setCost(cost) self.cost = cost end
--- Get the unlock cost.
-- @treturn number
function UpgradeNode:getCost() return self.cost end
--- Add an effect to this node.
-- @param effect string
function UpgradeNode:addEffect(effect) self.effects[#self.effects+1] = effect end
--- Get all effects.
-- @treturn table
function UpgradeNode:getEffects() return self.effects end
--- Add a tag.
-- @param tag string
function UpgradeNode:addTag(tag) self.tags[tag] = true end
--- Check if the node has a tag.
-- @param tag string
-- @treturn boolean
function UpgradeNode:hasTag(tag) return self.tags[tag] == true end
--- Return true when unlocked.
-- @treturn boolean
function UpgradeNode:isUnlocked() return self.unlocked end

-- ÔöÇÔöÇ UpgradeTree ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local UpgradeTree = {}
UpgradeTree.__index = UpgradeTree

--- Create a new upgrade tree.
-- @param name string
-- @treturn UpgradeTree
function M.newUpgradeTree(name)
    return setmetatable({
        name   = name,
        _nodes = {},
        _edges = {},   -- parent_id Ôćĺ {child_id, ...}
        _order = {},   -- insertion order for nodeIds()
        _parent = {},  -- child_id Ôćĺ parent_id
    }, UpgradeTree)
end

--- Add a node to the tree.
-- @param node UpgradeNode
function UpgradeTree:addNode(node)
    self._nodes[node.id] = node
    self._order[#self._order+1] = node.id
end

--- Add a directed edge from_id Ôćĺ to_id.
-- @param from_id string
-- @param to_id   string
function UpgradeTree:addEdge(from_id, to_id)
    if not self._edges[from_id] then self._edges[from_id] = {} end
    self._edges[from_id][#self._edges[from_id]+1] = to_id
    self._parent[to_id] = from_id
end

--- Look up a node by ID.
-- @param id string
-- @treturn UpgradeNode|nil
function UpgradeTree:getNode(id) return self._nodes[id] end

--- Get children of a node (sorted).
-- @param id string
-- @treturn table
function UpgradeTree:getChildren(id)
    local out = {}
    for _, cid in ipairs(self._edges[id] or {}) do out[#out+1] = cid end
    table.sort(out)
    return out
end

--- Get root nodes (no parent).
-- @treturn table sorted IDs
function UpgradeTree:getRootNodes()
    local out = {}
    for _, nid in ipairs(self._order) do
        if not self._parent[nid] then out[#out+1] = nid end
    end
    return out
end

--- Get parent ID (or nil if root).
-- @param id string
-- @treturn string|nil
function UpgradeTree:getParent(id) return self._parent[id] end

--- Return true if a node can be unlocked.
-- All rules: node exists, not already unlocked, parent (if any) is unlocked.
-- @param id string
-- @treturn boolean
function UpgradeTree:canUnlock(id)
    local node = self._nodes[id]
    if not node or node.unlocked then return false end
    local parent = self._parent[id]
    if parent then
        local pnode = self._nodes[parent]
        if not pnode or not pnode.unlocked then return false end
    end
    return true
end

--- Unlock a node. Returns true on success.
-- @param id string
-- @treturn boolean
function UpgradeTree:unlock(id)
    if not self:canUnlock(id) then return false end
    self._nodes[id].unlocked = true
    return true
end

--- Reset a node (re-lock it). Returns true if it was unlocked.
-- @param id string
-- @treturn boolean
function UpgradeTree:resetNode(id)
    local node = self._nodes[id]
    if not node or not node.unlocked then return false end
    node.unlocked = false
    return true
end

--- Return sorted list of unlocked node IDs.
-- @treturn table
function UpgradeTree:getUnlockedIds()
    local out = {}
    for _, nid in ipairs(self._order) do
        if self._nodes[nid].unlocked then out[#out+1] = nid end
    end
    return out
end

--- Return all node IDs in insertion order.
-- @treturn table
function UpgradeTree:nodeIds() return self._order end

--- Return total node count.
-- @treturn number
function UpgradeTree:count() return #self._order end

--- BFS path from node `from` to node `to`. Returns nil if not reachable.
-- @param from string
-- @param to   string
-- @treturn table|nil  ordered list of node IDs
function UpgradeTree:getPath(from, to)
    if from == to then return {from} end
    local visited = {[from]=true}
    local prev    = {}
    local queue   = {from}
    local head    = 1
    while head <= #queue do
        local cur = queue[head]; head = head+1
        for _, child in ipairs(self._edges[cur] or {}) do
            if not visited[child] then
                visited[child] = true
                prev[child]    = cur
                if child == to then
                    local path = {}
                    local node = to
                    while node do
                        table.insert(path, 1, node)
                        node = prev[node]
                    end
                    return path
                end
                queue[#queue+1] = child
            end
        end
    end
    return nil
end

--- Return all nodes that are not yet unlocked and whose parent (if any) is unlocked,
-- filtered by optional player_level requirement.
-- @param unlocked_set table   set of unlocked node IDs (e.g. {a=true, b=true})
-- @param player_level number  player's current level
-- @treturn table  list of UpgradeNode
function UpgradeTree:availableUpgrades(unlocked_set, player_level)
    local out = {}
    for _, nid in ipairs(self._order) do
        local node = self._nodes[nid]
        if not (unlocked_set[nid] or node.unlocked) then
            local parent_ok = true
            if self._parent[nid] then
                parent_ok = unlocked_set[self._parent[nid]] or (self._nodes[self._parent[nid]] and self._nodes[self._parent[nid]].unlocked)
            end
            local level_ok = (not node.required_level) or (player_level and player_level >= node.required_level)
            if parent_ok and level_ok then
                out[#out+1] = node
            end
        end
    end
    return out
end

-- ÔöÇÔöÇ RecipeKnowledge extended ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Allow a player to "prototype" a recipe (partial knowledge before full discovery).
-- @param recipe_id string
function RecipeKnowledge:prototype(recipe_id)
    if not self.known[recipe_id] then
        self.prototyped  = self.prototyped or {}
        self.prototyped[recipe_id] = true
    end
end

--- Return true if the recipe has been prototyped.
-- @param recipe_id string
-- @treturn boolean
function RecipeKnowledge:isPrototyped(recipe_id)
    return (self.prototyped or {})[recipe_id] == true
end

--- Set a research cost for a recipe.
-- @param recipe_id string
-- @param cost      number
function RecipeKnowledge:setResearchCost(recipe_id, cost)
    self.research_costs = self.research_costs or {}
    self.research_costs[recipe_id] = cost
end

--- Get research cost for a recipe (0 if not set).
-- @param recipe_id string
-- @treturn number
function RecipeKnowledge:getResearchCost(recipe_id)
    return (self.research_costs or {})[recipe_id] or 0
end

--- Attempt to research a recipe by spending scrap resources.
-- Returns true and discovers the recipe if scrap >= research cost.
-- @param recipe_id string
-- @param scrap     number
-- @treturn boolean
function RecipeKnowledge:research(recipe_id, scrap)
    local cost = self:getResearchCost(recipe_id)
    if scrap >= cost then
        return self:discover(recipe_id, "research")
    end
    return false
end

--- Get the source that originally discovered a recipe ("research", "craft", etc.).
-- @param recipe_id string
-- @treturn string|nil
function RecipeKnowledge:getSource(recipe_id)
    return (self.sources or {})[recipe_id]
end


-- ÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉ
-- PARITY ADDITIONS ÔÇö Phase 2A  (crafting)
-- ÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉ

-- ÔöÇÔöÇ CraftSkill: missing methods ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- XP required to reach next level.
-- @treturn number
function CraftSkill:getXpToNext()
    local needed = xp_for_level(self.xp_curve, self.level)
    return math.max(0, needed - self.xp)
end

--- Force-set the skill level and reset XP to 0.
-- @param level number  Clamped to max_level.
function CraftSkill:setLevel(level)
    self.level = math.min(level or 1, self.max_level)
    self.xp = 0
end

--- Return true if this skill satisfies a recipe's skill gate.
-- Accepts a recipe table with .skill and .skill_level fields.
-- @param recipe table
-- @treturn boolean
function CraftSkill:canUse(recipe)
    if not recipe.skill or recipe.skill == "" then return true end
    return recipe.skill == self.name and self.level >= (recipe.skill_level or 0)
end

--- WoW-style difficulty colour for a recipe.
-- Returns "orange", "yellow", "green", or "grey".
-- @param recipe table
-- @treturn string
function CraftSkill:recipeColor(recipe)
    local lvl = self.level
    if (recipe.orange_threshold or 0) > 0 and lvl < recipe.orange_threshold then return "orange" end
    if (recipe.yellow_threshold or 0) > 0 and lvl < recipe.yellow_threshold then return "yellow" end
    if (recipe.green_threshold  or 0) > 0 and lvl < recipe.green_threshold  then return "green"  end
    return "grey"
end

--- Probability (0-1) of a skill-up when crafting this recipe.
-- @param recipe table
-- @treturn number
function CraftSkill:skillUpChance(recipe)
    local c = self:recipeColor(recipe)
    if c == "orange" then return 1.0
    elseif c == "yellow" then return 0.6
    elseif c == "green"  then return 0.2
    else return 0.0 end
end

--- Register a specialization branch (no-op if already present).
-- @param name string
function CraftSkill:addSpecialization(name)
    self.specializations = self.specializations or {}
    for _, s in ipairs(self.specializations) do if s == name then return end end
    self.specializations[#self.specializations+1] = name
end

--- Return the list of registered specialization branches.
-- @treturn table
function CraftSkill:getSpecializations()
    return self.specializations or {}
end

--- Lock in a chosen specialization. Returns false if already specialised or name unknown.
-- @param name string
-- @treturn boolean
function CraftSkill:chooseSpecialization(name)
    if self.specialization then return false end
    for _, s in ipairs(self.specializations or {}) do
        if s == name then self.specialization = name; return true end
    end
    return false
end

--- Return the current specialization (or nil if none).
-- @treturn string|nil
function CraftSkill:getSpecialization()
    return self.specialization
end

--- Return perks available at the current skill level from the perk tree.
-- @treturn table  list of PerkNode
function CraftSkill:availablePerks()
    local out = {}
    for _, node in pairs(self.perk_tree or {}) do
        if not node.unlocked and node.required_level <= self.level then
            out[#out+1] = node
        end
    end
    return out
end

--- Computed speed bonus from unlocked perks.
-- @treturn number
function CraftSkill:getSpeedBonus()
    local total = 0
    for _, node in pairs(self.perk_tree or {}) do
        if node.unlocked and node.speed_bonus then total = total + node.speed_bonus end
    end
    return total
end

--- Computed quality bonus from unlocked perks.
-- @treturn number
function CraftSkill:getQualityBonus()
    local total = 0
    for _, node in pairs(self.perk_tree or {}) do
        if node.unlocked and node.quality_bonus then total = total + node.quality_bonus end
    end
    return total
end

--- Computed yield bonus from unlocked perks.
-- @treturn number
function CraftSkill:getYieldBonus()
    local total = 0
    for _, node in pairs(self.perk_tree or {}) do
        if node.unlocked and node.yield_bonus then total = total + node.yield_bonus end
    end
    return total
end

-- ÔöÇÔöÇ CraftQueue: missing methods ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Return all job IDs regardless of state.
-- @treturn table
function CraftQueue:ids()
    local out = {}
    local jobs = self._jobs or self.jobs or {}
    for _, job in ipairs(jobs) do out[#out+1] = job.id end
    return out
end

--- Return IDs of queued (waiting) jobs.
-- @treturn table
function CraftQueue:queuedIds()
    local out = {}
    local jobs = self._jobs or self.jobs or {}
    for _, job in ipairs(jobs) do
        if job.status == "queued" then out[#out+1] = job.id end
    end
    return out
end

-- ÔöÇÔöÇ Station: missing methods ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Effective level = base level + count of installed attachments.
-- @treturn number
function Station:effectiveLevel()
    return self.level + #(self.attachments or {})
end

--- Effective craft time after applying station efficiency.
-- @param recipe table  Must have a .time field.
-- @treturn number
function Station:effectiveTime(recipe)
    local eff = self.efficiency or 1.0
    if eff <= 0 then eff = 0.001 end
    return recipe.time / eff
end

--- Return true if the station can process a recipe.
-- @param recipe table
-- @treturn boolean
function Station:canProcess(recipe)
    if self.active == false then return false end
    local rtype = recipe.station_type or ""
    if rtype ~= "" and rtype ~= self.station_type then return false end
    return self:effectiveLevel() >= (recipe.station_level or 0)
end

--- Return true if world position is within proximity_radius.
-- @param px number
-- @param py number
-- @treturn boolean
function Station:isInRange(px, py)
    local x, y = self.x or 0, self.y or 0
    local r = self.proximity_radius or 0
    local dx, dy = x - px, y - py
    return dx*dx + dy*dy <= r*r
end

--- Return the current module slot capacity.
-- @treturn number
function Station:moduleSlotCount()
    return self.module_limit or #(self.modules or {})
end

--- Set the module slot capacity.
-- @param n number
function Station:setModuleSlotCount(n)
    self.module_limit = n or 0
end

--- Return the module name at a 1-based slot index.
-- @param slot number  1-based.
-- @treturn string|nil
function Station:getModuleAt(slot)
    return (self.modules or {})[slot]
end

-- ÔöÇÔöÇ UpgradeTree: missing method ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Return all nodes in insertion order.
-- @treturn table  list of UpgradeNode
function UpgradeTree:getAllNodes()
    local out = {}
    for _, nid in ipairs(self._order or {}) do
        if self._nodes and self._nodes[nid] then out[#out+1] = self._nodes[nid] end
    end
    return out
end

-- ÔöÇÔöÇ ModifierPool: missing methods ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Remove modifier by name. Returns true if found.
-- @param name string
-- @treturn boolean
function ModifierPool:remove(name)
    for i, e in ipairs(self.entries) do
        if e.name == name then table.remove(self.entries, i); return true end
    end
    return false
end

--- Return sum of all entry weights.
-- @treturn number
function ModifierPool:getTotalWeight()
    local total = 0
    for _, e in ipairs(self.entries) do total = total + (e.weight or 0) end
    return total
end

--- Return a copy of the entries list.
-- @treturn table
function ModifierPool:getEntries()
    local out = {}
    for _, e in ipairs(self.entries) do out[#out+1] = e end
    return out
end

--- Alias for getEntries (matches Rust get_modifiers).
-- @treturn table
function ModifierPool:getModifiers()
    return self:getEntries()
end

--- Return the number of entries.
-- @treturn number
function ModifierPool:count()
    return #self.entries
end

--- Get the pool name.
-- @treturn string
function ModifierPool:getName()
    return self.name or ""
end

--- Set the pool name.
-- @param name string
function ModifierPool:setName(name)
    self.name = name
end

-- ÔöÇÔöÇ RecipeKnowledge: missing methods ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Remove knowledge of a recipe. Returns true if it was known.
-- @param recipe_id string
-- @treturn boolean
function RecipeKnowledge:forget(recipe_id)
    if self.known[recipe_id] then
        self.known[recipe_id] = nil
        if self.sources then self.sources[recipe_id] = nil end
        return true
    end
    return false
end

--- Enable or disable auto-discover mode.
-- @param enabled boolean
function RecipeKnowledge:setAutoDiscover(enabled)
    self._auto_discover = enabled
end

--- Return true if auto-discover is enabled.
-- @treturn boolean
function RecipeKnowledge:isAutoDiscover()
    return self._auto_discover == true
end

--- Wipe all discovered recipes and prototypes.
function RecipeKnowledge:clear()
    self.known = {}
    self.sources = {}
    self.prototyped = {}
end

-- ÔöÇÔöÇ RecipeGroup: proper object ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local RecipeGroup = {}
RecipeGroup.__index = RecipeGroup

--- Create a named group of recipes.
-- Replaces the plain-table version; .ids is kept for backward compat.
-- @param name string
-- @param ids  table|nil  initial recipe IDs
-- @treturn RecipeGroup
function M.newRecipeGroup(name, ids)
    local obj = setmetatable({
        name  = name or "",
        icon  = "",
        order = 0,
        ids   = {},
        _rids = {},
    }, RecipeGroup)
    for _, id in ipairs(ids or {}) do obj:addRecipe(id) end
    return obj
end

--- Add a recipe ID (no-op if already present).
-- @param recipe_id string
function RecipeGroup:addRecipe(recipe_id)
    for _, id in ipairs(self._rids) do if id == recipe_id then return end end
    self._rids[#self._rids+1] = recipe_id
    self.ids[#self.ids+1] = recipe_id
end

--- Remove a recipe ID. Returns true if found.
-- @param recipe_id string
-- @treturn boolean
function RecipeGroup:removeRecipe(recipe_id)
    for i, id in ipairs(self._rids) do
        if id == recipe_id then
            table.remove(self._rids, i)
            for j, eid in ipairs(self.ids) do
                if eid == recipe_id then table.remove(self.ids, j); break end
            end
            return true
        end
    end
    return false
end

--- Return all recipe IDs.
-- @treturn table
function RecipeGroup:getRecipes()
    local out = {}
    for _, id in ipairs(self._rids) do out[#out+1] = id end
    return out
end

--- Return the number of recipes.
-- @treturn number
function RecipeGroup:count()
    return #self._rids
end

--- Check whether a recipe ID is in the group.
-- @param recipe_id string
-- @treturn boolean
function RecipeGroup:contains(recipe_id)
    for _, id in ipairs(self._rids) do if id == recipe_id then return true end end
    return false
end

--- Set the icon identifier.
-- @param icon string
function RecipeGroup:setIcon(icon) self.icon = icon end
--- Get the icon identifier.
-- @treturn string
function RecipeGroup:getIcon() return self.icon end
--- Set the sort order.
-- @param order number
function RecipeGroup:setOrder(order) self.order = order end
--- Get the sort order.
-- @treturn number
function RecipeGroup:getOrder() return self.order end

return M
