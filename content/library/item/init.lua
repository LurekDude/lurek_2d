--- Lurek2D item system — type catalog, items, stacks, pools, history, and analysis.
--
-- A pure-Lua replacement for the former `lurek.item` Rust binding.
-- Provides a type registry, Item objects with tags/stats/meta/owner, capacity-aware
-- Stacks with positional access, weighted ItemPools with bulk draws, bounded StackHistory,
-- a StackManager, and functional analysis helpers.
--
-- Usage:
--   local item = require("library.item")
--   item.defineType("sword", { category="weapon", base_stats={dmg=10}, base_tags={"equippable"} })
--   local it = item.newItem("sword")
--   it:addTag("cursed")
--   print(it:getStat("dmg"))  -- 10
--
-- @module library.item

local M = {}

-- ─── Optional logging (guarded) ───────────────────────────────────────────────

local _log_debug, _log_warn
do
    local ok = type(lurek) == "table" and type(lurek.log) == "table"
    if ok and type(lurek.log.debug) == "function" then
        _log_debug = function(msg) lurek.log.debug(msg) end
    else
        _log_debug = function() end
    end
    if ok and type(lurek.log.warn) == "function" then
        _log_warn = function(msg) lurek.log.warn(msg) end
    else
        _log_warn = function() end
    end
end

-- ─── Type registry ────────────────────────────────────────────────────────────

local _types = {}  -- name -> { category, base_stats, base_tags }

--- Clear all registered item types (useful between tests).
-- **Note**: Already-created Item objects retain their stats, tags, and category
-- from the definition that existed at creation time.  Clearing the registry does
-- NOT retroactively change existing items.
-- @treturn nil
function M.clearTypes()
    _types = {}
end

--- Register a new item type definition.
-- @tparam string name Unique type name (e.g. "sword").
-- @tparam table def Definition table: `{ name="", category="", base_stats={}, base_tags={}, metadata={} }`.
function M.defineType(name, def)
    if type(name) ~= "string" or name == "" then
        error("defineType: 'name' must be a non-empty string, got: " .. tostring(name), 2)
    end
    if type(def) ~= "table" then
        error("defineType: 'def' must be a table, got: " .. type(def), 2)
    end
    _types[name] = {
        name       = def.name       or name,
        category   = def.category   or "misc",
        base_stats = def.base_stats or {},
        base_tags  = def.base_tags  or {},
        metadata   = def.metadata   or {},
    }
    _log_debug("item.defineType: registered '" .. name .. "'")
end

--- Retrieve a registered type definition, or nil.
-- @tparam string name
-- @treturn table|nil
function M.getType(name)
    return _types[name]
end

--- Return a sorted list of all registered type names.
-- @treturn table
function M.getTypeNames()
    local names = {}
    for k in pairs(_types) do table.insert(names, k) end
    table.sort(names)
    return names
end

-- ─── Item object ──────────────────────────────────────────────────────────────

--- Create a new item instance.
-- Stats and tags are copied from the type definition; modifications are per-instance.
-- If `type_name` is not registered, a warning is logged and the item receives
-- default `misc` category with empty stats/tags.
-- @tparam string type_name Registered type name (or any string for ad-hoc items).
-- @treturn table Item object.
function M.newItem(type_name)
    if type(type_name) ~= "string" or type_name == "" then
        error("newItem: 'type_name' must be a non-empty string, got: " .. tostring(type_name), 2)
    end
    local def = _types[type_name]
    if not def then
        _log_warn("item.newItem: type '" .. type_name .. "' is not registered; using defaults")
        def = { category="misc", base_stats={}, base_tags={} }
    end
    _log_debug("item.newItem: created '" .. type_name .. "'")

    local _stats = {}
    for k, v in pairs(def.base_stats) do _stats[k] = v end
    local _tags = {}
    for _, t in ipairs(def.base_tags) do _tags[t] = true end
    local _meta  = {}   -- string -> any metadata
    for k, v in pairs(def.metadata or {}) do _meta[k] = v end
    local _owner    = nil  -- arbitrary owner reference
    local _counters = {}   -- named integer counters
    local _slot     = ""   -- current slot/position name
    local _name     = def.name or type_name  -- display name

    local it = {}

    --- Return the type name.
    -- @treturn string
    function it:getType()       return type_name end

    --- Return the category from the type registry.
    -- @treturn string
    function it:getCategory()   return def.category end

    -- ── Stats ──────────────────────────────────────────────────────────────

    --- Return the value of a stat, or nil if not set.
    -- @tparam string key
    -- @treturn number|nil
    function it:getStat(key)    return _stats[key] end

    --- Set or override a stat value.
    -- @tparam string key
    -- @tparam number val
    function it:setStat(key, val)
        if type(key) ~= "string" or key == "" then
            error("setStat: 'key' must be a non-empty string, got: " .. tostring(key), 2)
        end
        _stats[key] = val
    end

    --- Add delta to an existing stat (creates stat at delta if absent).
    -- @tparam string key
    -- @tparam number delta
    function it:addStat(key, delta)
        if type(key) ~= "string" or key == "" then
            error("addStat: 'key' must be a non-empty string, got: " .. tostring(key), 2)
        end
        _stats[key] = (_stats[key] or 0) + delta
    end

    --- Remove a stat entirely.
    -- @tparam string key
    function it:removeStat(key)    _stats[key] = nil end

    --- Return all current stats as a shallow copy.
    -- @treturn table key->value map
    function it:getStats()
        local out = {}
        for k, v in pairs(_stats) do out[k] = v end
        return out
    end

    -- ── Tags ──────────────────────────────────────────────────────────────

    --- Return true if this item has the given tag.
    -- @tparam string tag
    -- @treturn boolean
    function it:hasTag(tag)     return _tags[tag] == true end

    --- Add a tag (no-op if already present).
    -- @tparam string tag
    function it:addTag(tag)     _tags[tag] = true end

    --- Remove a tag. Returns true if tag existed.
    -- @tparam string tag
    -- @treturn boolean
    function it:removeTag(tag)
        if _tags[tag] then _tags[tag] = nil; return true end
        return false
    end

    --- Return all tag names as a sorted array.
    -- @treturn table
    function it:getTags()
        local out = {}
        for t in pairs(_tags) do table.insert(out, t) end
        table.sort(out)
        return out
    end

    -- ── Metadata ──────────────────────────────────────────────────────────

    --- Set a metadata value.
    -- @tparam string key
    -- @param val any
    function it:setMeta(key, val)  _meta[key] = val end

    --- Get a metadata value, or nil.
    -- @tparam string key
    -- @treturn any
    function it:getMeta(key)       return _meta[key] end

    -- ── Owner ─────────────────────────────────────────────────────────────

    --- Set the owner reference.
    -- @param owner any
    function it:setOwner(owner) _owner = owner end

    --- Return the owner reference.
    -- @treturn any
    function it:getOwner()      return _owner end

    -- ── Name / Slot ───────────────────────────────────────────────────────

    --- Return the display name (seeds from type def; may differ from type name).
    -- @treturn string
    function it:getName()       return _name end

    --- Set the display name.
    -- @tparam string n
    function it:setName(n)      _name = n end

    --- Return the current slot/position name.
    -- @treturn string
    function it:getSlot()       return _slot end

    --- Set the slot/position name.
    -- @tparam string s
    function it:setSlot(s)      _slot = s end

    -- ── Counters ──────────────────────────────────────────────────────────

    --- Get a named integer counter (0 if not set).
    -- @tparam string key
    -- @treturn number
    function it:getCounter(key)      return _counters[key] or 0 end

    --- Set a named integer counter.
    -- @tparam string key
    -- @tparam number val
    function it:setCounter(key, val) _counters[key] = val end

    --- Add delta to a named counter and return the new value.
    -- @tparam string key
    -- @tparam number delta
    -- @treturn number
    function it:addCounter(key, delta)
        _counters[key] = (_counters[key] or 0) + delta
        return _counters[key]
    end

    --- Remove a named counter entry.
    -- @tparam string key
    function it:removeCounter(key)   _counters[key] = nil end

    --- Return all counters as a shallow copy.
    -- @treturn table  key -> number
    function it:getCounters()
        local out = {}
        for k, v in pairs(_counters) do out[k] = v end
        return out
    end

    -- ── Clone ─────────────────────────────────────────────────────────────

    --- Deep-copy this item instance (stats, tags, meta, counters, slot, name — NOT owner).
    -- @treturn table new Item
    function it:clone()
        local c = M.newItem(type_name)
        for k, v in pairs(_stats)    do c:setStat(k, v) end
        for t in pairs(_tags)        do c:addTag(t) end
        for k, v in pairs(_meta)     do c:setMeta(k, v) end
        for k, v in pairs(_counters) do c:setCounter(k, v) end
        c:setSlot(_slot)
        c:setName(_name)
        return c
    end

    return it
end

-- ─── Stack (LIFO with positional access) ─────────────────────────────────────

--- Create a named stack with optional capacity limit.
-- Acts as both a LIFO stack and a positional list.
-- @tparam string name Identifier for debugging.
-- @tparam[opt=0] number capacity Max item count. 0 = unlimited.
-- @treturn table Stack object.
function M.newStack(name, capacity)
    if type(name) ~= "string" or name == "" then
        error("newStack: 'name' must be a non-empty string, got: " .. tostring(name), 2)
    end
    if capacity ~= nil and (type(capacity) ~= "number" or capacity < 0) then
        error("newStack: 'capacity' must be a non-negative number, got: " .. tostring(capacity), 2)
    end
    local _items = {}   -- index 1 = bottom, #_items = top
    local _cap   = capacity or 0

    local stack = {}

    --- Return the stack name.
    -- @treturn string
    function stack:getName()    return name end

    --- Return number of items.
    -- @treturn number
    function stack:size()       return #_items end

    --- Return capacity (0 = unlimited).
    -- @treturn number
    function stack:getCapacity() return _cap end

    --- Set or update capacity (0 = unlimited).
    -- @tparam number n
    function stack:setCapacity(n) _cap = n or 0 end

    --- Return true if at capacity.
    -- @treturn boolean
    function stack:isFull()
        return _cap > 0 and #_items >= _cap
    end

    --- Remove all items.
    function stack:clear()      _items = {} end

    -- ── Push / Pop (LIFO top) ──────────────────────────────────────────────

    --- Push item onto top (returns false if capacity full).
    -- @tparam table it Item object.
    -- @treturn boolean
    function stack:push(it)
        if _cap > 0 and #_items >= _cap then return false end
        table.insert(_items, it)
        return true
    end

    --- Push item onto bottom. Returns false if full.
    -- @tparam table it Item object.
    -- @treturn boolean
    function stack:pushBottom(it)
        if _cap > 0 and #_items >= _cap then return false end
        table.insert(_items, 1, it)
        return true
    end

    --- Pop and return top item, or nil if empty.
    -- @treturn table|nil
    function stack:pop()        return table.remove(_items) end

    --- Alias for pop.
    -- @treturn table|nil
    function stack:popTop()     return table.remove(_items) end

    --- Remove and return bottom item, or nil if empty.
    -- @treturn table|nil
    function stack:popBottom()  return table.remove(_items, 1) end

    --- Peek at bottom item without removing it.
    -- @treturn table|nil
    function stack:peekBottom() return _items[1] end

    --- Peek at top item without removing it.
    -- @treturn table|nil
    function stack:peek()       return _items[#_items] end

    --- Alias for peek (slot compat).
    -- @treturn table|nil
    function stack:getItem()    return _items[#_items] end

    --- Peek at item at 1-based index without removing. Returns nil if out of range.
    -- @tparam number idx 1-based.
    -- @treturn table|nil
    function stack:peekAt(idx)  return _items[idx] end

    --- Remove and return item at 1-based index. Returns nil if out of range.
    -- @tparam number idx
    -- @treturn table|nil
    function stack:removeAt(idx)
        if idx < 1 or idx > #_items then return nil end
        return table.remove(_items, idx)
    end

    --- Insert item at 1-based position. Returns false if full or index invalid.
    -- @tparam number idx Position (1 = bottom, #items+1 = top).
    -- @tparam table it Item object.
    -- @treturn boolean
    function stack:insertAt(idx, it)
        if _cap > 0 and #_items >= _cap then return false end
        if idx < 1 or idx > #_items + 1 then return false end
        table.insert(_items, idx, it)
        return true
    end

    --- Return the first item for which predicate(item) is true. Nil if none.
    -- @tparam function pred
    -- @treturn table|nil
    function stack:findFirst(pred)
        for _, it in ipairs(_items) do
            if pred(it) then return it end
        end
        return nil
    end

    --- Return a shallow copy of all items (bottom to top).
    -- @treturn table
    function stack:getItems()
        local out = {}
        for _, it in ipairs(_items) do table.insert(out, it) end
        return out
    end

    return stack
end

-- ─── Weighted item pool ───────────────────────────────────────────────────────

--- Create a weighted loot pool.
-- Supports weighted draw, bulk multi-draw, and unique-draw operations.
-- @treturn table ItemPool object.
function M.newItemPool()
    local _entries = {}   -- array of { type_name, weight }
    local _total   = 0

    local pool = {}

    --- Return number of entries.
    -- @treturn number
    function pool:size()       return #_entries end

    --- Return true if the pool has no entries.
    -- @treturn boolean
    function pool:isEmpty()    return #_entries == 0 end

    --- Return the sum of all entry weights.
    -- @treturn number
    function pool:totalWeight() return _total end

    --- Return all entries as array of {type_name, weight}.
    -- @treturn table
    function pool:getEntries()
        local out = {}
        for _, e in ipairs(_entries) do
            table.insert(out, { type_name = e.type_name, weight = e.weight })
        end
        return out
    end

    --- Add a type with a given weight. If type already present, adds another entry.
    -- @tparam string type_name
    -- @tparam number weight Must be > 0.
    function pool:addType(type_name, weight)
        if type(type_name) ~= "string" or type_name == "" then
            error("pool:addType: 'type_name' must be a non-empty string, got: " .. tostring(type_name), 2)
        end
        if type(weight) ~= "number" or weight <= 0 then
            error("pool:addType: 'weight' must be a positive number, got: " .. tostring(weight), 2)
        end
        table.insert(_entries, { type_name = type_name, weight = weight })
        _total = _total + weight
        _log_debug("pool:addType: added '" .. type_name .. "' weight=" .. weight)
    end

    --- Update the weight of the first matching entry. Returns false if not found.
    -- @tparam string type_name
    -- @tparam number weight Must be > 0.
    -- @treturn boolean
    function pool:setWeight(type_name, weight)
        if type(weight) ~= "number" or weight <= 0 then
            error("pool:setWeight: 'weight' must be a positive number, got: " .. tostring(weight), 2)
        end
        for _, e in ipairs(_entries) do
            if e.type_name == type_name then
                _total = _total - e.weight + weight
                e.weight = weight
                return true
            end
        end
        return false
    end

    --- Remove the first entry of type_name. Returns false if not found.
    -- @tparam string type_name
    -- @treturn boolean
    function pool:remove(type_name)
        for i, e in ipairs(_entries) do
            if e.type_name == type_name then
                _total = _total - e.weight
                table.remove(_entries, i)
                return true
            end
        end
        return false
    end

    --- Draw one random item (weighted). Returns nil if pool is empty or total weight is zero.
    -- @treturn table|nil Item object, or nil on empty/zero-weight pool.
    function pool:draw()
        if #_entries == 0 or _total <= 0 then
            _log_warn("pool:draw: pool is empty or has zero total weight")
            return nil
        end
        local r = math.random() * _total
        local cum = 0
        for _, e in ipairs(_entries) do
            cum = cum + e.weight
            if r <= cum then
                _log_debug("pool:draw: drew '" .. e.type_name .. "'")
                return M.newItem(e.type_name)
            end
        end
        return M.newItem(_entries[#_entries].type_name)
    end

    --- Draw n items (with replacement). Entries from an empty pool are skipped (nil).
    -- @tparam number n
    -- @treturn table Array of Item objects (may contain nil entries if pool is empty).
    function pool:drawTypes(n)
        local out = {}
        for _ = 1, n do table.insert(out, self:draw()) end
        return out
    end

    --- Draw up to n unique type names (no type drawn twice), returns array of Items.
    -- If n exceeds the number of distinct types in the pool, returns all distinct types.
    -- @tparam number n Maximum unique types to draw.
    -- @treturn table Array of Item objects (length <= n).
    function pool:drawUniqueTypes(n)
        local seen = {}
        local out  = {}
        -- collect unique type_names first
        local unique_entries = {}
        for _, e in ipairs(_entries) do
            if not seen[e.type_name] then
                seen[e.type_name] = true
                table.insert(unique_entries, e)
            end
        end
        -- shuffle (Fisher-Yates)
        for i = #unique_entries, 2, -1 do
            local j = math.random(i)
            unique_entries[i], unique_entries[j] = unique_entries[j], unique_entries[i]
        end
        for i = 1, math.min(n, #unique_entries) do
            table.insert(out, M.newItem(unique_entries[i].type_name))
        end
        return out
    end

    return pool
end

-- ─── Stack builder ────────────────────────────────────────────────────────────

--- Create a stack builder for constructing stacks from a recipe list.
-- @treturn table StackBuilder object.
function M.newStackBuilder()
    local _recipe = {}

    local builder = {}

    --- Add items of a type to the recipe.
    -- @tparam string type_name
    -- @tparam number count
    function builder:add(type_name, count)
        table.insert(_recipe, { type_name = type_name, count = count or 1 })
    end

    --- Build the stack from the current recipe.
    -- @tparam string name Stack name.
    -- @treturn table Stack
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

-- ─── StackHistory ─────────────────────────────────────────────────────────────

--- Action constants for StackHistory entries.
M.HistoryAction = {
    Push   = "push",
    Pop    = "pop",
    Clear  = "clear",
    Custom = "custom",
}

--- Create a bounded event history for stack operations.
-- @tparam[opt=50] number max_entries Maximum entries to retain.
-- @treturn table StackHistory object.
function M.newStackHistory(max_entries)
    local _log   = {}
    max_entries  = max_entries or 50

    local history = {}

    local function push_entry(e)
        table.insert(_log, e)
        while #_log > max_entries do table.remove(_log, 1) end
    end

    --- Record a push action.
    -- @tparam string source Stack name or label.
    -- @tparam string item_type Type name of pushed item.
    -- @tparam number size_after Stack size after the push.
    function history:recordPush(source, item_type, size_after)
        push_entry({ action=M.HistoryAction.Push, source=source, item_type=item_type, size_after=size_after or 0 })
    end

    --- Record a pop action.
    -- @tparam string source
    -- @tparam string item_type
    -- @tparam number size_after
    function history:recordPop(source, item_type, size_after)
        push_entry({ action=M.HistoryAction.Pop, source=source, item_type=item_type, size_after=size_after or 0 })
    end

    --- Record a clear action.
    -- @tparam string source
    function history:recordClear(source)
        push_entry({ action=M.HistoryAction.Clear, source=source, item_type="", size_after=0 })
    end

    --- Record a custom event.
    -- @tparam string source
    -- @tparam string label
    -- @tparam number size_after
    function history:recordCustom(source, label, size_after)
        push_entry({ action=M.HistoryAction.Custom, source=source, item_type=label, size_after=size_after or 0 })
    end

    --- Return all recorded entries (oldest first).
    -- Each entry has: action, source, item_type, size_after.
    -- @treturn table
    function history:entries()
        local out = {}
        for _, e in ipairs(_log) do table.insert(out, e) end
        return out
    end

    --- Return the last n entries, or all if n > count.
    -- @tparam number n
    -- @treturn table
    function history:getLastN(n)
        local out = {}
        local start = math.max(1, #_log - n + 1)
        for i = start, #_log do table.insert(out, _log[i]) end
        return out
    end

    --- Clear all log entries.
    function history:clear()   _log = {} end

    --- Return number of entries.
    -- @treturn number
    function history:count()   return #_log end

    --- Return true if no events have been recorded.
    -- @treturn boolean
    function history:isEmpty() return #_log == 0 end

    --- Return the most recent entry, or nil if empty.
    -- @treturn table|nil
    function history:last()    return _log[#_log] end

    --- Return all entries matching a specific source name.
    -- @tparam string source
    -- @treturn table
    function history:entriesFor(source)
        local out = {}
        for _, e in ipairs(_log) do
            if e.source == source then out[#out+1] = e end
        end
        return out
    end

    return history
end

-- ─── Stack manager ────────────────────────────────────────────────────────────

--- Create a named-stack manager.
-- @treturn table StackManager object.
function M.newStackManager()
    local _stacks = {}

    local manager = {}

    --- Register a stack.
    -- @tparam string name
    -- @tparam table stack
    function manager:addStack(name, stack)   _stacks[name] = stack end

    --- Retrieve a stack by name.
    -- @tparam string name
    -- @treturn table|nil
    function manager:getStack(name)          return _stacks[name] end

    --- Remove a stack. Returns true if existed.
    -- @tparam string name
    -- @treturn boolean
    function manager:removeStack(name)
        if not _stacks[name] then return false end
        _stacks[name] = nil
        return true
    end

    --- Return all registered stack names.
    -- @treturn table
    function manager:keys()
        local out = {}
        for k in pairs(_stacks) do table.insert(out, k) end
        table.sort(out)
        return out
    end

    --- Return true if a stack with this name exists.
    -- @tparam string name
    -- @treturn boolean
    function manager:hasStack(name) return _stacks[name] ~= nil end

    --- Create and register a new empty unlimited stack.
    -- @tparam string name
    function manager:createStack(name)
        _stacks[name] = M.newStack(name)
    end

    --- Create and register a new empty stack with a capacity limit.
    -- @tparam string name
    -- @tparam number capacity
    function manager:createStackCapped(name, capacity)
        _stacks[name] = M.newStack(name, capacity)
    end

    --- Return total number of items across all stacks.
    -- @treturn number
    function manager:totalItems()
        local n = 0
        for _, s in pairs(_stacks) do n = n + s:size() end
        return n
    end

    --- Move item at 1-based index from one stack to the top of another.
    -- Returns the moved item on success, or nil plus an error string on failure.
    -- @tparam string from Source stack name.
    -- @tparam number index 1-based index.
    -- @tparam string to Destination stack name.
    -- @treturn table|nil
    -- @treturn string|nil
    function manager:moveItem(from, index, to)
        local src = _stacks[from]
        if not src then return nil, "stack '" .. from .. "' not found" end
        local dst = _stacks[to]
        if not dst then return nil, "stack '" .. to .. "' not found" end
        if dst:isFull() then return nil, "stack '" .. to .. "' is full" end
        local it = src:removeAt(index)
        if not it then return nil, "index " .. index .. " out of range in '" .. from .. "'" end
        dst:push(it)
        return it
    end

    --- Move the first item of a given type from one stack to the top of another.
    -- Returns the moved item on success, or nil plus an error string on failure.
    -- @tparam string from Source stack name.
    -- @tparam string item_type Type name to search for.
    -- @tparam string to Destination stack name.
    -- @treturn table|nil
    -- @treturn string|nil
    function manager:moveItemByType(from, item_type, to)
        local src = _stacks[from]
        if not src then return nil, "stack '" .. from .. "' not found" end
        local idx = nil
        for i, it in ipairs(src:getItems()) do
            if it.getType and it:getType() == item_type then idx = i; break end
        end
        if not idx then return nil, "type '" .. item_type .. "' not found in '" .. from .. "'" end
        return self:moveItem(from, idx, to)
    end

    --- Move the top item from one stack to the top of another.
    -- Returns the moved item on success, or nil plus an error string on failure.
    -- @tparam string from
    -- @tparam string to
    -- @treturn table|nil
    -- @treturn string|nil
    function manager:moveTop(from, to)
        local src = _stacks[from]
        if not src then return nil, "stack '" .. from .. "' not found" end
        if src:size() == 0 then return nil, "stack '" .. from .. "' is empty" end
        return self:moveItem(from, src:size(), to)
    end

    return manager
end

-- ─── Slot (bounded named position) ────────────────────────────────────────────

--- Create a named slot with optional capacity limit.
-- A slot is a bounded named position that holds zero or more items.
-- @tparam string name Identifier for this slot.
-- @tparam[opt=0] number capacity Max item count; nil or 0 = unlimited.
-- @treturn table Slot object.
function M.newSlot(name, capacity)
    local _items = {}
    local _cap   = capacity or 0

    local slot = {}

    --- Return the slot name.
    -- @treturn string
    function slot:getName()     return name end

    --- Return number of items in the slot.
    -- @treturn number
    function slot:size()        return #_items end

    --- Return true if the slot is empty.
    -- @treturn boolean
    function slot:isEmpty()     return #_items == 0 end

    --- Return true if the slot is at capacity.
    -- @treturn boolean
    function slot:isFull()      return _cap > 0 and #_items >= _cap end

    --- Return capacity (0 = unlimited).
    -- @treturn number
    function slot:getCapacity() return _cap end

    --- Set or update capacity (0 = unlimited).
    -- @tparam number n
    function slot:setCapacity(n) _cap = n or 0 end

    --- Add an item to the slot. Returns true on success, false if at capacity.
    -- @tparam table it Item object.
    -- @treturn boolean
    function slot:push(it)
        if _cap > 0 and #_items >= _cap then return false end
        table.insert(_items, it)
        return true
    end

    --- Remove and return the last item, or nil if empty.
    -- @treturn table|nil
    function slot:pop()         return table.remove(_items) end

    --- Remove and return the item at 1-based index, or nil if out of range.
    -- @tparam number index
    -- @treturn table|nil
    function slot:removeAt(index)
        if index < 1 or index > #_items then return nil end
        return table.remove(_items, index)
    end

    --- Peek at the last item without removing it.
    -- @treturn table|nil
    function slot:peek()        return _items[#_items] end

    --- Peek at item at 1-based index without removing it.
    -- @tparam number index
    -- @treturn table|nil
    function slot:peekAt(index) return _items[index] end

    --- Remove all items and return them as an array.
    -- @treturn table
    function slot:clear()
        local out = {}
        for _, it in ipairs(_items) do out[#out+1] = it end
        _items = {}
        return out
    end

    --- Return a shallow copy of all items.
    -- @treturn table
    function slot:items()
        local out = {}
        for _, it in ipairs(_items) do out[#out+1] = it end
        return out
    end

    --- Return true if any item has the given tag.
    -- @tparam string tag
    -- @treturn boolean
    function slot:hasItemWithTag(tag)
        for _, it in ipairs(_items) do
            if it.hasTag and it:hasTag(tag) then return true end
        end
        return false
    end

    --- Return true if any item is of the given type.
    -- @tparam string item_type
    -- @treturn boolean
    function slot:hasItemOfType(item_type)
        for _, it in ipairs(_items) do
            if it.getType and it:getType() == item_type then return true end
        end
        return false
    end

    return slot
end

-- ─── Stat ranking ─────────────────────────────────────────────────────────────

--- Return 0-based indices of the top N items ranked by a stat (descending).
-- @tparam table items Array of Item objects.
-- @tparam string stat Stat name.
-- @tparam number n How many to return.
-- @treturn table Array of 0-based integer indices.
function M.findNOfStat(items, stat, n)
    local scored = {}
    for i, it in ipairs(items) do
        table.insert(scored, { val = it:getStat(stat) or 0, idx = i - 1 })
    end
    table.sort(scored, function(a, b) return a.val > b.val end)
    local result = {}
    for i = 1, math.min(n, #scored) do table.insert(result, scored[i].idx) end
    return result
end

-- ─── Grouping helpers ─────────────────────────────────────────────────────────

--- Group items by a stat value. Returns map {value -> array of Items}.
-- Items without the stat are grouped under the key false.
-- @tparam table items Array of Item objects.
-- @tparam string stat_key
-- @treturn table
function M.groupByStat(items, stat_key)
    local out = {}
    for _, it in ipairs(items) do
        local v = it:getStat(stat_key)
        local k = v ~= nil and v or false
        if not out[k] then out[k] = {} end
        table.insert(out[k], it)
    end
    return out
end

--- Group items by tag prefix. Returns map {prefix_value -> array of Items}.
-- A tag matches if it starts with `prefix` (e.g. prefix "tier:" matches "tier:1", "tier:2").
-- Items with no matching tag go under key "".
-- @tparam table items Array of Item objects.
-- @tparam string prefix Tag prefix to filter on.
-- @treturn table
function M.groupByTagPrefix(items, prefix)
    local out = {}
    for _, it in ipairs(items) do
        local matched = ""
        for _, t in ipairs(it:getTags()) do
            if t:sub(1, #prefix) == prefix then matched = t; break end
        end
        if not out[matched] then out[matched] = {} end
        table.insert(out[matched], it)
    end
    return out
end

--- Find runs (consecutive sequences) of items sharing the same stat value.
-- Returns array of {value, start_idx, length} (1-based start_idx).
-- @tparam table items Array of Item objects.
-- @tparam string stat_key
-- @treturn table
function M.findSequences(items, stat_key)
    local out = {}
    if #items == 0 then return out end
    local cur_val   = items[1]:getStat(stat_key)
    local cur_start = 1
    local cur_len   = 1
    for i = 2, #items do
        local v = items[i]:getStat(stat_key)
        if v == cur_val then
            cur_len = cur_len + 1
        else
            if cur_len > 1 then
                table.insert(out, { value=cur_val, start_idx=cur_start, length=cur_len })
            end
            cur_val   = v
            cur_start = i
            cur_len   = 1
        end
    end
    if cur_len > 1 then
        table.insert(out, { value=cur_val, start_idx=cur_start, length=cur_len })
    end
    return out
end


-- ═══════════════════════════════════════════════════════════════════════
-- PARITY ADDITIONS — Phase 2A  (item)
-- ═══════════════════════════════════════════════════════════════════════

-- ── Stack: missing methods ────────────────────────────────────────────
-- Note: Stack methods below are added via the Stack metatable reference.
-- Because Stack is defined as a closure (not a metatable), we patch the
-- prototype at module level by wrapping newStack to inject extra methods.

local _orig_newStack = M.newStack
function M.newStack(name, capacity)
    local stack = _orig_newStack(name, capacity)

    --- Return true if the stack has no items.
    -- @treturn boolean
    function stack:isEmpty()
        return self:size() == 0
    end

    --- Pop n items from the top. Returns array of items (may be shorter if stack runs out).
    -- @tparam number n
    -- @treturn table
    function stack:popMany(n)
        local out = {}
        for _ = 1, n do
            local item = self:pop()
            if item == nil then break end
            out[#out+1] = item
        end
        return out
    end

    --- Move item at index `from` to index `to` (both 1-based). Returns false if invalid.
    -- @tparam number from
    -- @tparam number to
    -- @treturn boolean
    function stack:moveWithin(from, to)
        local items = self:getItems()
        if from < 1 or from > #items or to < 1 or to > #items then return false end
        local item = table.remove(items, from)
        table.insert(items, to, item)
        -- Rebuild internal state by clearing and re-pushing
        self:clear()
        for _, it in ipairs(items) do self:push(it) end
        return true
    end

    --- Return all items whose type matches. Uses item:getType().
    -- @tparam string type_name
    -- @treturn table
    function stack:searchByType(type_name)
        local out = {}
        for _, it in ipairs(self:getItems()) do
            if it.getType and it:getType() == type_name then out[#out+1] = it end
        end
        return out
    end

    --- Return all items that have the given tag.
    -- @tparam string tag
    -- @treturn table
    function stack:searchByTag(tag)
        local out = {}
        for _, it in ipairs(self:getItems()) do
            if it.hasTag and it:hasTag(tag) then out[#out+1] = it end
        end
        return out
    end

    --- Return all items in the given category.
    -- @tparam string cat
    -- @treturn table
    function stack:searchByCategory(cat)
        local out = {}
        for _, it in ipairs(self:getItems()) do
            if it.getCategory and it:getCategory() == cat then out[#out+1] = it end
        end
        return out
    end

    --- Return first item with the given type (or nil).
    -- @tparam string type_name
    -- @treturn table|nil
    function stack:findByType(type_name)
        for _, it in ipairs(self:getItems()) do
            if it.getType and it:getType() == type_name then return it end
        end
        return nil
    end

    --- Return first item with the given tag (or nil).
    -- @tparam string tag
    -- @treturn table|nil
    function stack:findByTag(tag)
        for _, it in ipairs(self:getItems()) do
            if it.hasTag and it:hasTag(tag) then return it end
        end
        return nil
    end

    --- Count items with the given type.
    -- @tparam string type_name
    -- @treturn number
    function stack:countByType(type_name)
        local n = 0
        for _, it in ipairs(self:getItems()) do
            if it.getType and it:getType() == type_name then n = n + 1 end
        end
        return n
    end

    --- Count items in the given category.
    -- @tparam string cat
    -- @treturn number
    function stack:countByCategory(cat)
        local n = 0
        for _, it in ipairs(self:getItems()) do
            if it.getCategory and it:getCategory() == cat then n = n + 1 end
        end
        return n
    end

    --- Count items with the given tag.
    -- @tparam string tag
    -- @treturn number
    function stack:countByTag(tag)
        local n = 0
        for _, it in ipairs(self:getItems()) do
            if it.hasTag and it:hasTag(tag) then n = n + 1 end
        end
        return n
    end

    --- Sort items ascending by a numeric stat. Items without the stat sort last.
    -- @tparam string stat
    function stack:sortByStat(stat)
        local items = self:getItems()
        table.sort(items, function(a, b)
            local va = (a.getStat and a:getStat(stat)) or math.huge
            local vb = (b.getStat and b:getStat(stat)) or math.huge
            return va < vb
        end)
        self:clear()
        for _, it in ipairs(items) do self:push(it) end
    end

    --- Sort items descending by a numeric stat.
    -- @tparam string stat
    function stack:sortByStatDesc(stat)
        local items = self:getItems()
        table.sort(items, function(a, b)
            local va = (a.getStat and a:getStat(stat)) or -math.huge
            local vb = (b.getStat and b:getStat(stat)) or -math.huge
            return va > vb
        end)
        self:clear()
        for _, it in ipairs(items) do self:push(it) end
    end

    --- Sort items by category (alphabetical).
    function stack:sortByCategory()
        local items = self:getItems()
        table.sort(items, function(a, b)
            local ca = (a.getCategory and a:getCategory()) or ""
            local cb = (b.getCategory and b:getCategory()) or ""
            return ca < cb
        end)
        self:clear()
        for _, it in ipairs(items) do self:push(it) end
    end

    --- Sort items by type name (alphabetical).
    function stack:sortByName()
        local items = self:getItems()
        table.sort(items, function(a, b)
            local ta = (a.getType and a:getType()) or ""
            local tb = (b.getType and b:getType()) or ""
            return ta < tb
        end)
        self:clear()
        for _, it in ipairs(items) do self:push(it) end
    end

    --- Shuffle items in-place (Fisher-Yates).
    function stack:shuffle()
        local items = self:getItems()
        for i = #items, 2, -1 do
            local j = math.random(1, i)
            items[i], items[j] = items[j], items[i]
        end
        self:clear()
        for _, it in ipairs(items) do self:push(it) end
    end

    --- Return the type names of the top n items (without removing).
    -- @tparam number n
    -- @treturn table type name strings, top-first
    function stack:peekTopNTypes(n)
        local items = self:getItems()
        local out = {}
        for i = #items, math.max(1, #items - n + 1), -1 do
            local it = items[i]
            out[#out+1] = it and it.getType and it:getType() or ""
        end
        return out
    end

    return stack
end

-- ── StackBuilder: missing methods ─────────────────────────────────────

local _orig_newStackBuilder = M.newStackBuilder
function M.newStackBuilder()
    local builder     = _orig_newStackBuilder()
    local _required   = {}   -- type_name -> true
    local _banned     = {}   -- type_name -> true
    local _with_items = {}   -- pre-built items from addWith()
    local _shuffle    = false
    -- Capture the base build before we override it.
    local _base_build = builder.build

    --- Add items with per-item stat overrides and extra tags.
    -- Unlike add(), overrides are applied immediately to pre-built item instances.
    -- @tparam string type_name
    -- @tparam number count
    -- @tparam[opt] table stat_overrides key->value stat map.
    -- @tparam[opt] table extra_tags list of tag strings.
    function builder:addWith(type_name, count, stat_overrides, extra_tags)
        for _ = 1, (count or 1) do
            local it = M.newItem(type_name)
            for k, v in pairs(stat_overrides or {}) do it:setStat(k, v) end
            for _, t in ipairs(extra_tags or {})    do it:addTag(t) end
            _with_items[#_with_items+1] = it
        end
    end

    --- Enable or disable Fisher-Yates shuffle after build.
    -- @tparam boolean enabled
    function builder:setShuffleOnBuild(enabled)
        _shuffle = enabled == true
    end

    --- Require that a specific type appears at least once.
    -- @tparam string type_name
    function builder:requireType(type_name)
        _required[type_name] = true
    end

    --- Ban a specific type from appearing.
    -- @tparam string type_name
    function builder:banType(type_name)
        _banned[type_name] = true
    end

    --- Remove a ban on a type.
    -- @tparam string type_name
    function builder:removeBannedType(type_name)
        _banned[type_name] = nil
    end

    --- Build the stack from recipe entries plus addWith items.
    -- Applies shuffleOnBuild if enabled.
    -- @tparam string name Stack name.
    -- @treturn table Stack
    function builder:build(name)
        local s = _base_build(self, name)
        for _, it in ipairs(_with_items) do s:push(it) end
        if _shuffle then s:shuffle() end
        return s
    end

    --- Validate the current recipe + addWith items against required/banned constraints.
    -- Returns nil on success, or an error string on failure.
    -- @treturn string|nil
    function builder:validateEntries()
        local s = self:build("__validate_tmp__")
        return self:validateStack(s)
    end

    --- Validate a pre-built stack against required/banned constraints.
    -- Returns nil on success, or an error string on failure.
    -- @tparam table stack
    -- @treturn string|nil
    function builder:validateStack(stack)
        for _, it in ipairs(stack:getItems()) do
            local t = it.getType and it:getType() or ""
            if _banned[t] then return "banned type: " .. t end
        end
        for req in pairs(_required) do
            if stack:countByType(req) == 0 then return "missing required type: " .. req end
        end
        return nil
    end

    --- Build the stack with a custom name (alias for build).
    -- @tparam string name
    -- @treturn table Stack
    function builder:buildNamed(name)
        return self:build(name)
    end

    return builder
end

-- ── HistoryAction: add missing variants ──────────────────────────────

M.HistoryAction.Moved   = "moved"
M.HistoryAction.Shuffled = "shuffled"
M.HistoryAction.Sorted  = "sorted"
M.HistoryAction.Built   = "built"

-- ── Module-level free functions ────────────────────────────────────────

--- Group items by category. Returns table: category -> {Item, ...}.
-- @tparam table items list of Item objects.
-- @treturn table
function M.groupByCategory(items)
    local out = {}
    for _, it in ipairs(items) do
        local cat = (it.getCategory and it:getCategory()) or "misc"
        if not out[cat] then out[cat] = {} end
        out[cat][#out[cat]+1] = it
    end
    return out
end

--- Return items where getStat(stat) >= n.
-- @tparam table items
-- @tparam string stat
-- @tparam number n
-- @treturn table
function M.findAtLeastNOfStat(items, stat, n)
    local out = {}
    for _, it in ipairs(items) do
        local v = it.getStat and it:getStat(stat) or 0
        if (v or 0) >= n then out[#out+1] = it end
    end
    return out
end

--- Group items by shared tag prefix. Returns table: prefix -> {Item, ...}.
-- A "tag group" is a set of items that share at least one tag.
-- @tparam table items
-- @treturn table tag -> {Item, ...}
function M.findTagGroups(items)
    local out = {}
    for _, it in ipairs(items) do
        if it.getTags then
            for _, tag in ipairs(it:getTags()) do
                if not out[tag] then out[tag] = {} end
                out[tag][#out[tag]+1] = it
            end
        end
    end
    return out
end

--- Return 1-based indices sorted by a stat.
-- @tparam table items
-- @tparam string stat
-- @tparam boolean ascending true = lowest first (default), false = highest first.
-- @treturn table indices
function M.sortedIndicesByStat(items, stat, ascending)
    if ascending == nil then ascending = true end
    local indices = {}
    for i = 1, #items do indices[#indices+1] = i end
    table.sort(indices, function(a, b)
        local va = (items[a].getStat and items[a]:getStat(stat)) or 0
        local vb = (items[b].getStat and items[b]:getStat(stat)) or 0
        if ascending then return (va or 0) < (vb or 0)
        else return (va or 0) > (vb or 0) end
    end)
    return indices
end

--- Return 1-based indices sorted by category (alphabetical).
-- @tparam table items
-- @treturn table indices
function M.sortedIndicesByCategory(items)
    local indices = {}
    for i = 1, #items do indices[#indices+1] = i end
    table.sort(indices, function(a, b)
        local ca = (items[a].getCategory and items[a]:getCategory()) or ""
        local cb = (items[b].getCategory and items[b]:getCategory()) or ""
        return ca < cb
    end)
    return indices
end

return M
