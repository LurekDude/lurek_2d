--- Luna2D item system — type catalog, pools, stacks, and history.
--
-- A pure-Lua replacement for the former `luna.item` Rust binding.
-- Provides weighted loot pools, typed item instances, stack primitives,
-- stack builders, managers, and a bounded event history.
--
-- Usage:
--   local item = require("library.item")
--   item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={"equippable"} })
--   local it = item.newItem("sword")
--   print(it:getStat("dmg"))  -- 10
--
-- @module library.item

local M = {}

-- ─── Type registry ────────────────────────────────────────────────────────────

local _types = {}  -- name → { category, base_stats, base_tags }

--- Clear all registered item types.
function M.clearTypes()
    _types = {}
end

--- Register a new item type.
-- @param name string Unique type name (e.g. "sword").
-- @param def table Definition: { category, base_stats={}, base_tags={} }
function M.defineType(name, def)
    _types[name] = {
        category   = def.category  or "misc",
        base_stats = def.base_stats or {},
        base_tags  = def.base_tags  or {},
    }
end

--- Retrieve a registered type definition.
-- @param name string Type name.
-- @treturn table|nil Type definition, or nil if not registered.
function M.getType(name)
    return _types[name]
end

--- Return a sorted list of all registered type names.
-- @treturn table Array of strings.
function M.getTypeNames()
    local names = {}
    for k in pairs(_types) do
        table.insert(names, k)
    end
    table.sort(names)
    return names
end

-- ─── Item object ──────────────────────────────────────────────────────────────

--- Create a new item instance of the given type.
-- Stats are initialised from base_stats; tags from base_tags.
-- @param type_name string Registered type name.
-- @treturn table Item object.
function M.newItem(type_name)
    local def = _types[type_name] or { category="misc", base_stats={}, base_tags={} }

    -- copy base stats and tags so each instance is independent
    local stats = {}
    for k, v in pairs(def.base_stats) do stats[k] = v end
    local tags = {}
    for _, t in ipairs(def.base_tags) do tags[t] = true end

    local it = {}

    --- Return the type name of this item.
    -- @treturn string
    function it:getType()
        return type_name
    end

    --- Return the value of a stat, or nil if not set.
    -- @param key string Stat name.
    -- @treturn number|nil
    function it:getStat(key)
        return stats[key]
    end

    --- Set or override a stat value.
    -- @param key string Stat name.
    -- @param val number New value.
    function it:setStat(key, val)
        stats[key] = val
    end

    --- Return true if this item has the given tag.
    -- @param tag string Tag name (e.g. "equippable").
    -- @treturn boolean
    function it:hasTag(tag)
        return tags[tag] == true
    end

    return it
end

-- ─── Stack ────────────────────────────────────────────────────────────────────

--- Create a named stack (LIFO collection of item objects).
-- @param name string Stack identifier (used for debugging).
-- @treturn table Stack object.
function M.newStack(name)
    local items = {}  -- array, index 1 = bottom, #items = top

    local stack = {}

    --- Push an item onto the top.
    -- @param it table Item object.
    function stack:push(it)
        table.insert(items, it)
    end

    --- Pop and return the top item, or nil if empty.
    -- @treturn table|nil
    function stack:pop()
        return table.remove(items)
    end

    --- Pop and return the top item (alias for pop).
    -- @treturn table|nil
    function stack:popTop()
        return table.remove(items)
    end

    --- Return the number of items in the stack.
    -- @treturn number
    function stack:size()
        return #items
    end

    --- Remove all items.
    function stack:clear()
        items = {}
    end

    --- Peek at the top item without removing it.
    -- @treturn table|nil
    function stack:peek()
        return items[#items]
    end

    --- Return the wrapped item (for single-item slot stacks).
    -- Equivalent to peek(); provided for container slot compat.
    -- @treturn table|nil
    function stack:getItem()
        return items[#items]
    end

    return stack
end

-- ─── Weighted item pool ───────────────────────────────────────────────────────

--- Create a weighted loot pool for random item draws.
-- @treturn table ItemPool object.
function M.newItemPool()
    local _entries = {}  -- { type_name, weight } list
    local _total   = 0

    local pool = {}

    --- Add a type to the pool with a given weight.
    -- @param type_name string Registered type name.
    -- @param weight number Relative probability weight.
    function pool:addType(type_name, weight)
        table.insert(_entries, { type_name = type_name, weight = weight })
        _total = _total + weight
    end

    --- Draw a random item from the pool (weighted).
    -- @treturn table Item object, or a "misc" item if pool is empty.
    function pool:draw()
        if #_entries == 0 or _total == 0 then
            return M.newItem("unknown")
        end
        local r = math.random() * _total
        local cumulative = 0
        for _, entry in ipairs(_entries) do
            cumulative = cumulative + entry.weight
            if r <= cumulative then
                return M.newItem(entry.type_name)
            end
        end
        -- fallback (floating-point edge case)
        return M.newItem(_entries[#_entries].type_name)
    end

    return pool
end

-- ─── Stack builder ────────────────────────────────────────────────────────────

--- Create a stack builder for constructing stacks from a recipe.
-- @treturn table StackBuilder object.
function M.newStackBuilder()
    local _recipe = {}  -- { type_name, count } ordered list

    local builder = {}

    --- Add items of a type to the recipe.
    -- @param type_name string Registered type name.
    -- @param count number Number of items to add.
    function builder:add(type_name, count)
        table.insert(_recipe, { type_name = type_name, count = count or 1 })
    end

    --- Build the stack from the current recipe.
    -- @param name string Name assigned to the resulting stack.
    -- @treturn table Stack populated with the recipe items.
    function builder:build(name)
        local s = M.newStack(name)
        for _, entry in ipairs(_recipe) do
            for _ = 1, entry.count do
                s:push(M.newItem(entry.type_name))
            end
        end
        return s
    end

    return builder
end

-- ─── History (bounded event log) ─────────────────────────────────────────────

--- Create a bounded event history.
-- @param max_entries number Maximum number of entries to retain.
-- @treturn table History object.
function M.newHistory(max_entries)
    local _log = {}
    max_entries = max_entries or 50

    local history = {}

    --- Record a custom event.
    -- @param container string Container or source label.
    -- @param label string Action label (e.g. "picked_up_sword").
    -- @param size_after number Count or size value for context.
    function history:recordCustom(container, label, size_after)
        table.insert(_log, {
            container  = container,
            label      = label,
            size_after = size_after or 0,
        })
        while #_log > max_entries do
            table.remove(_log, 1)
        end
    end

    --- Return all recorded entries (oldest first).
    -- Each entry has: container, label, size_after.
    -- @treturn table Array of entry tables.
    function history:entries()
        local result = {}
        for _, e in ipairs(_log) do
            table.insert(result, e)
        end
        return result
    end

    --- Clear all entries.
    function history:clear()
        _log = {}
    end

    return history
end

-- ─── Stack manager ────────────────────────────────────────────────────────────

--- Create a named-stack manager that holds multiple stacks by key.
-- @treturn table StackManager object.
function M.newStackManager()
    local _stacks = {}

    local manager = {}

    --- Register a stack under a name.
    -- @param name string Key for this stack.
    -- @param stack table Stack object.
    function manager:addStack(name, stack)
        _stacks[name] = stack
    end

    --- Retrieve a stack by name.
    -- @param name string Key.
    -- @treturn table|nil Stack, or nil if not found.
    function manager:getStack(name)
        return _stacks[name]
    end

    --- Return a list of all registered stack names.
    -- @treturn table Array of strings.
    function manager:keys()
        local result = {}
        for k in pairs(_stacks) do
            table.insert(result, k)
        end
        return result
    end

    return manager
end

-- ─── Stat ranking ─────────────────────────────────────────────────────────────

--- Return the 0-based indices of the top N items ranked by a stat.
-- Indices reference the original items array.
-- @param items table Array of item objects.
-- @param stat string Stat name to rank by (descending).
-- @param n number Number of top items to return.
-- @treturn table Array of 0-based integer indices.
function M.findNOfStat(items, stat, n)
    -- build (value, 0-based-index) pairs
    local scored = {}
    for i, it in ipairs(items) do
        table.insert(scored, { val = it:getStat(stat) or 0, idx = i - 1 })
    end
    table.sort(scored, function(a, b) return a.val > b.val end)

    local result = {}
    for i = 1, math.min(n, #scored) do
        table.insert(result, scored[i].idx)
    end
    return result
end

return M
