-- @module library.cardgame
--- @status full
--- Card game system: card types, cards, stacks (decks/hands/zones), slots,
--- card pools, stack manager, deck builder, history, and card groups.
--- Pure-Lua port of src/cardgame/.
--- @see lurek.math
--- @see lurek.tween
--- @see lurek.event
--- @see lurek.log

local M = {}

--- Optional logging (uses lurek.log when running inside Lurek2D).
-- @see lurek.log
local function _log_info(msg)
    if lurek and lurek.log and lurek.log.info then
        lurek.log.info("[cardgame] " .. msg)
    end
end
local function _log_debug(msg)
    if lurek and lurek.log and lurek.log.debug then
        lurek.log.debug("[cardgame] " .. msg)
    end
end

-- ������ ID counter ������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

local _next_id = 1

-- ������ Card Type Registry ������������������������������������������������������������������������������������������������������������������������������������������������������������

local _card_types = {}

--- Return the current value of the internal ID counter (next ID to assign).
--- Lua doubles are exact up to 2^53 (9007199254740992).
--- @treturn number  Current counter value.
function M.getIdCounter() return _next_id end

--- Reset the ID counter to 1.  Call between game sessions to reclaim the
--- integer range.  Does NOT invalidate already-created cards � callers must
--- ensure no stale references remain.
function M.resetIdCounter()
    _next_id = 1
    _log_info("ID counter reset to 1")
end

--- Register or overwrite a card type definition.
--- @tparam string name  Type name used as registry key (must be non-empty).
--- @tparam table def  CardTypeDef table to store.
function M.defineCardType(name, def)
    assert(type(name) == "string" and #name > 0, "defineCardType: name must be a non-empty string")
    assert(type(def) == "table", "defineCardType: def must be a table")
    def.name = name
    _card_types[name] = def
    _log_info("registered card type '" .. name .. "'")
end

--- Look up a card type by name; returns nil if not found.
--- @param name string  Registry key.
--- @treturn table|nil  CardTypeDef or nil.
function M.getCardType(name) return _card_types[name] end

--- Return a sorted list of all registered type names.
--- @treturn table  Alphabetically sorted array of name strings.
function M.getCardTypeNames()
    local out = {}
    for k in pairs(_card_types) do out[#out+1] = k end
    table.sort(out)
    return out
end

--- Clear all card type definitions from the module registry.
function M.clearCardTypes() _card_types = {} end

-- ������ CardTypeDef ���������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

--- Create a new card type definition (blueprint).
---
--- CardTypeDef fields:
--- @tfield string name       Type name (set automatically on registration).
--- @tfield string category   Card category (e.g. "creature", "spell").
--- @tfield string subtype    Optional subtype within category.
--- @tfield string rarity     Rarity tier (e.g. "common", "rare", "legendary").
--- @tfield table base_stats  Default stat values copied to new cards {[stat_name]=number}.
--- @tfield table base_tags   Default tags copied to new cards (array of strings).
--- @tfield table metadata    Arbitrary key-value metadata {[string]=string}.
--- @tfield number|nil max_per_deck  Maximum copies allowed per deck (nil = unlimited).
---
--- @tparam string name Type name (must be non-empty).
--- @treturn table CardTypeDef.
function M.newCardTypeDef(name)
    assert(type(name) == "string" and #name > 0, "newCardTypeDef: name must be a non-empty string")
    return {
        name         = name,
        category     = '',
        subtype      = '',
        rarity       = '',
        base_stats   = {},
        base_tags    = {},
        metadata     = {},
        max_per_deck = nil,
    }
end

-- ������ Card ������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

---@class LCard
---@field id number
---@field card_type string
---@field name string
---@field category string
---@field subtype string
---@field rarity string
---@field stats table<string, number>
---@field tags string[]
---@field counters table<string, number>
---@field metadata table<string, string>
---@field owner string
---@field controller string
---@field slot string
---@field face_up boolean
---@field tapped boolean
---@field tile_x number
---@field tile_y number
---@field tile_w number
---@field tile_h number
local Card = {}
Card.__index = Card

--- Create a new card instance.  Seeds fields from the registry if the type
--- is defined.  Each card receives a unique auto-incrementing integer ID.
---
--- Card fields:
--- @tfield number id         Unique card identifier (auto-assigned).
--- @tfield string card_type  Registered type name.
--- @tfield string name       Display name (defaults to card_type).
--- @tfield string category   Card category (e.g. "creature", "spell").
--- @tfield string subtype    Optional subtype within category.
--- @tfield string rarity     Rarity tier string.
--- @tfield table stats       Per-instance stat overrides {[stat_name]=number}.
--- @tfield table tags        Array of tag strings.
--- @tfield table counters    Named counters {[string]=number}.
--- @tfield table metadata    Arbitrary key-value metadata {[string]=string}.
--- @tfield string owner      Owner identifier.
--- @tfield string controller Current controller identifier.
--- @tfield string slot       Slot assignment name.
--- @tfield boolean face_up   Whether the card is face-up (default false).
--- @tfield boolean tapped    Whether the card is tapped/exhausted (default false).
--- @tfield number tile_x     Board grid X position (default 0).
--- @tfield number tile_y     Board grid Y position (default 0).
--- @tfield number tile_w     Board grid width in cells (default 1).
--- @tfield number tile_h     Board grid height in cells (default 1).
---
--- @tparam string card_type  Registered type name.
--- @treturn LCard
function M.newCard(card_type)
    assert(type(card_type) == "string", "newCard: card_type must be a string")
    local id = _next_id
    _next_id = _next_id + 1
    _log_debug("created card #" .. id .. " type='" .. card_type .. "'")
    local c = setmetatable({
        id         = id,
        card_type  = card_type,
        name       = card_type,
        category   = '',
        subtype    = '',
        rarity     = '',
        stats      = {},
        tags       = {},
        counters   = {},
        metadata   = {},
        owner      = '',
        controller = '',
        slot       = '',
        face_up    = false,
        tapped     = false,
        tile_x     = 0,
        tile_y     = 0,
        tile_w     = 1,
        tile_h     = 1,
    }, Card)
    local def = _card_types[card_type]
    if def then
        c.name     = def.name or card_type
        c.category = def.category or ''
        c.subtype  = def.subtype or ''
        c.rarity   = def.rarity or ''
        for k, v in pairs(def.base_stats or {}) do c.stats[k] = v end
        for _, t in ipairs(def.base_tags or {}) do c.tags[#c.tags+1] = t end
        for k, v in pairs(def.metadata or {}) do c.metadata[k] = v end
    end
    return c
end

--- Return the numeric stat value for key, or 0 if not set.
--- @param key string
--- @treturn number
function Card:getStat(key) return self.stats[key] or 0 end
--- Set a numeric stat to an exact value.
--- @param key string
--- @param val number
function Card:setStat(key, val) self.stats[key] = val end
--- Add delta to a stat and return the new value.
--- @param key string
--- @param delta number
--- @treturn number
function Card:addStat(key, delta)
    self.stats[key] = (self.stats[key] or 0) + delta
    return self.stats[key]
end
--- Remove a stat entry entirely.
--- @param key string
function Card:removeStat(key) self.stats[key] = nil end

--- Return true if the tag is present on this card.
--- @param tag string
--- @treturn boolean
function Card:hasTag(tag)
    for _, t in ipairs(self.tags) do if t == tag then return true end end
    return false
end
--- Add a tag if not already present.
--- @param tag string
function Card:addTag(tag)
    if not self:hasTag(tag) then self.tags[#self.tags+1] = tag end
end
--- Remove the first occurrence of tag; returns true if it was present.
--- @param tag string
--- @treturn boolean
function Card:removeTag(tag)
    for i, t in ipairs(self.tags) do
        if t == tag then table.remove(self.tags, i); return true end
    end
    return false
end

--- Return the named counter value, or 0 if not set.
--- @param key string
--- @treturn number
function Card:getCounter(key)    return self.counters[key] or 0 end
--- Set a named counter to an exact value.
--- @param key string
--- @param v number
function Card:setCounter(key, v) self.counters[key] = v end
--- Add delta to a counter and return the new value.
--- @param key string
--- @param delta number
--- @treturn number
function Card:addCounter(key, delta)
    self.counters[key] = (self.counters[key] or 0) + delta
    return self.counters[key]
end
--- Remove a counter entry entirely.
--- @param key string
function Card:removeCounter(key) self.counters[key] = nil end

--- Return a metadata string, or nil if not set.
--- @param key string
--- @treturn string|nil
function Card:getMeta(key) return self.metadata[key] end
--- Store an arbitrary metadata string.
--- @param key string
--- @param val string
function Card:setMeta(key, val) self.metadata[key] = val end

--- Reset stats from the registered type definition, discarding per-instance overrides.
function Card:resetStats()
    local def = _card_types[self.card_type]
    if def then
        self.stats = {}
        for k, v in pairs(def.base_stats or {}) do self.stats[k] = v end
    end
end

--- Flip the card face (toggles face_up).
function Card:flip()    self.face_up = not self.face_up end
--- Tap this card (mark as used/exhausted).
function Card:tap()     self.tapped  = true  end
--- Untap this card (reset exhausted state).
function Card:untap()   self.tapped  = false end
--- Return true if the card is face-up.
-- @treturn boolean
function Card:isFaceUp()   return self.face_up end
--- Return true if the card is tapped.
-- @treturn boolean
function Card:isTapped()   return self.tapped  end
--- Set the rarity tier string.
-- @param r string  e.g. "common", "rare", "legendary"
function Card:setRarity(r) self.rarity = r end
--- Get the rarity tier string.
-- @treturn string
function Card:getRarity()  return self.rarity end
--- Set the tile grid position for board layout.
-- @param x number
-- @param y number
function Card:setTilePosition(x, y) self.tile_x = x; self.tile_y = y end
--- Get the tile grid position.
-- @treturn number, number  x, y
function Card:getTilePosition() return self.tile_x, self.tile_y end

-- ������ Stack ���������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

---@class LCardStack
---@field name string
---@field cards LCard[]
---@field _cap number|nil
---@field ordered boolean
---@field public boolean
---@field size fun(self: LCardStack): number
local Stack = {}
Stack.__index = Stack

--- Create a new unbounded Stack.
---
--- Stack fields:
--- @tfield string name     Stack display name.
--- @tfield table cards     Internal card array (use methods to access).
--- @tfield boolean ordered Whether the stack preserves insertion order (default true).
--- @tfield boolean public  Whether the stack contents are publicly visible (default false).
---
--- @tparam string name  LCardStack name.
--- @treturn LCardStack
function M.newStack(name)
    assert(type(name) == "string" and #name > 0, "newStack: name must be a non-empty string")
    return setmetatable({
        name     = name,
        cards    = {},
        _cap     = nil,
        ordered  = true,
        public   = false,
    }, Stack)
end

--- Create a new Stack with a fixed capacity limit.
--- @tparam string name  LCardStack name.
--- @tparam number cap  Maximum LCard count (must be >= 1).
--- @treturn LCardStack
function M.newStackWithCapacity(name, cap)
    assert(type(cap) == "number" and cap >= 1, "newStackWithCapacity: cap must be >= 1")
    local s = M.newStack(name)
    s._cap = cap
    return s
end

--- Return the number of cards.
--- @treturn number
function Stack:size()     return #self.cards end
--- Return true when the stack contains no cards.
--- @treturn boolean
function Stack:isEmpty()  return #self.cards == 0 end
--- Return true when the stack has reached its capacity limit.
--- @treturn boolean
function Stack:isFull()   return self._cap ~= nil and #self.cards >= self._cap end
--- Return the capacity limit, or nil for unlimited.
--- @treturn number|nil
function Stack:capacity() return self._cap end
--- Set or remove the capacity limit (nil = unlimited).
--- @param cap number|nil
function Stack:setCapacity(cap) self._cap = cap end

--- Push a card onto the top of the stack; returns false when full.
--- @param card LCard
--- @treturn boolean
function Stack:pushTop(card)
    if self:isFull() then return false end
    self.cards[#self.cards+1] = card; return true
end
--- Push a card onto the bottom of the stack; returns false when full.
--- @param card LCard
--- @treturn boolean
function Stack:pushBottom(card)
    if self:isFull() then return false end
    table.insert(self.cards, 1, card); return true
end
--- Remove and return the top card, or nil if empty.
--- @treturn LCard|nil
function Stack:popTop()
    if #self.cards == 0 then return nil end
    return table.remove(self.cards)
end
--- Remove and return the bottom card, or nil if empty.
--- @treturn LCard|nil
function Stack:popBottom()
    if #self.cards == 0 then return nil end
    return table.remove(self.cards, 1)
end
--- Pop up to n cards from the top and return them.
--- @param n number
--- @treturn table  Array of LCard (may be shorter than n if LCardStack empties).
function Stack:popMany(n)
    local out = {}
    for _ = 1, math.min(n, #self.cards) do
        out[#out+1] = table.remove(self.cards)
    end
    return out
end

--- Return the top card without removing it.
--- @treturn LCard|nil
function Stack:peekTop()    return self.cards[#self.cards] end
--- Return the bottom card without removing it.
--- @treturn LCard|nil
function Stack:peekBottom() return self.cards[1] end
--- Return the card at the given 1-based index without removing it.
--- @param idx number
--- @treturn LCard|nil
function Stack:peekAt(idx)  return self.cards[idx] end

--- Insert card at position idx (1-based, clamped); returns false when full.
--- @param idx number
--- @param card LCard
--- @treturn boolean
function Stack:insertAt(idx, card)
    if self:isFull() then return false end
    idx = math.max(1, math.min(idx, #self.cards + 1))
    table.insert(self.cards, idx, card)
    return true
end
--- Remove and return the card at 1-based position idx, or nil if out of range.
--- @param idx number
--- @treturn LCard|nil
function Stack:removeAt(idx)
    if idx < 1 or idx > #self.cards then return nil end
    return table.remove(self.cards, idx)
end
--- Move a card from one 1-based index to another within the same stack.
--- @param from number
--- @param to number
--- @treturn boolean
function Stack:moveWithin(from, to)
    if from < 1 or from > #self.cards or to < 1 or to > #self.cards then return false end
    local card = table.remove(self.cards, from)
    table.insert(self.cards, to, card)
    return true
end
--- Clear all cards and return them.
--- @treturn table  Array of the removed cards.
function Stack:clear()
    local old = self.cards; self.cards = {}; return old
end

--- Return a list of 1-based indices of cards with the given type name.
--- @param card_type string
--- @treturn table  Array of integer indices.
function Stack:searchByType(card_type)
    local out = {}
    for i, c in ipairs(self.cards) do if c.card_type == card_type then out[#out+1] = i end end
    return out
end
--- Return a list of 1-based indices of cards that have the given tag.
--- @param tag string
--- @treturn table  Array of integer indices.
function Stack:searchByTag(tag)
    local out = {}
    for i, c in ipairs(self.cards) do if c:hasTag(tag) then out[#out+1] = i end end
    return out
end
--- Return a list of 1-based indices of cards with the given category.
--- @param cat string
--- @treturn table  Array of integer indices.
function Stack:searchByCategory(cat)
    local out = {}
    for i, c in ipairs(self.cards) do if c.category == cat then out[#out+1] = i end end
    return out
end
--- Return the 1-based index of the first card with the given type, or nil.
--- @param card_type string
--- @treturn number|nil
function Stack:findByType(card_type)
    for i, c in ipairs(self.cards) do if c.card_type == card_type then return i end end
    return nil
end
--- Return the 1-based index of the first card with the given tag, or nil.
--- @param tag string
--- @treturn number|nil
function Stack:findByTag(tag)
    for i, c in ipairs(self.cards) do if c:hasTag(tag) then return i end end
    return nil
end
--- Return all Card objects with the given category.
--- @param cat string
--- @treturn table  Array of LCard objects.
function Stack:findByCategoryAll(cat)
    local out = {}
    for _, c in ipairs(self.cards) do if c.category == cat then out[#out+1] = c end end
    return out
end
--- Return all Card objects with the given type name.
--- @tparam string type_name
--- @treturn table  Array of LCard objects.
function Stack:findByTypeAll(type_name)
    local out = {}
    for _, c in ipairs(self.cards) do if c.card_type == type_name then out[#out+1] = c end end
    return out
end
--- Return all Card objects that have the given tag.
--- @tparam string tag
--- @treturn table  Array of LCard objects.
function Stack:findByTagAll(tag)
    local out = {}
    for _, c in ipairs(self.cards) do if c:hasTag(tag) then out[#out+1] = c end end
    return out
end
--- Remove and return the Card with the given id, or nil if not found.
--- @param id number
--- @treturn LCard|nil
function Stack:removeById(id)
    for i, c in ipairs(self.cards) do
        if c.id == id then return table.remove(self.cards, i) end
    end
    return nil
end
--- Return true if a card with the given id is in the stack.
--- @param id number
--- @treturn boolean
function Stack:containsId(id)
    for _, c in ipairs(self.cards) do if c.id == id then return true end end
    return false
end

--- Return the count of cards with the given type name.
--- @param t string
--- @treturn number
function Stack:countByType(t)
    local n = 0
    for _, c in ipairs(self.cards) do if c.card_type == t then n = n + 1 end end
    return n
end
--- Return the count of cards with the given category.
--- @param cat string
--- @treturn number
function Stack:countByCategory(cat)
    local n = 0
    for _, c in ipairs(self.cards) do if c.category == cat then n = n + 1 end end
    return n
end
--- Return the count of cards that have the given tag.
--- @param tag string
--- @treturn number
function Stack:countByTag(tag)
    local n = 0
    for _, c in ipairs(self.cards) do if c:hasTag(tag) then n = n + 1 end end
    return n
end

--- Sort cards by a named stat in ascending order (in-place).
--- @param stat string
function Stack:sortByStat(stat)
    table.sort(self.cards, function(a, b) return a:getStat(stat) < b:getStat(stat) end)
end
--- Sort cards by a named stat in descending order (in-place).
--- @param stat string
function Stack:sortByStatDesc(stat)
    table.sort(self.cards, function(a, b) return a:getStat(stat) > b:getStat(stat) end)
end
--- Sort cards alphabetically by category field (in-place).
function Stack:sortByCategory()
    table.sort(self.cards, function(a, b) return a.category < b.category end)
end
--- Sort cards alphabetically by name field (in-place).
function Stack:sortByName()
    table.sort(self.cards, function(a, b) return a.name < b.name end)
end

--- Shuffle cards into a random order using Fisher-Yates.
-- TODO(P4 lift): replace with lurek.math.shuffle when available so the
-- shuffle becomes seedable and decoupled from the global RNG state.
-- @see lurek.math
function Stack:shuffle()
    local n = #self.cards
    for i = n, 2, -1 do
        local j = math.random(1, i)
        self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
    end
    _log_debug("shuffled stack '" .. self.name .. "' (" .. n .. " cards)")
end

--- Return the raw card array (by reference).
--- @treturn table
function Stack:items() return self.cards end
--- Return the type names of the top n cards (topmost first).
--- @param n number
--- @treturn table  Array of type name strings.
function Stack:peekTopNTypes(n)
    local out = {}
    local start = math.max(1, #self.cards - n + 1)
    for i = #self.cards, start, -1 do
        out[#out+1] = self.cards[i].card_type
    end
    return out
end

--- Return a shallow copy of the card array for later restoration.
--- @treturn table
function Stack:snapshotCards()
    local out = {}
    for _, c in ipairs(self.cards) do out[#out+1] = c end
    return out
end
--- Replace the card array with a previously snapshotted copy.
--- @param cards table
function Stack:restoreCards(cards) self.cards = cards end

--- Return true when the stack preserves insertion order.
--- @treturn boolean
function Stack:isOrdered()    return self.ordered end
--- Set whether the stack preserves order.
--- @param b boolean
function Stack:setOrdered(b)  self.ordered = b end
--- Return true when the stack contents are publicly visible.
--- @treturn boolean
function Stack:isPublic()     return self.public end
--- Set whether the stack is publicly visible.
--- @param b boolean
function Stack:setPublic(b)   self.public = b end
--- Rename the stack.
--- @param n string
function Stack:setName(n)     self.name = n end

-- ������ Slot ������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

local Slot = {}
Slot.__index = Slot

--- Create a new unbounded Slot.
---
--- Slot fields:
--- @tfield string name  Slot display name.
--- @tfield table items  Internal item array (use methods to access).
---
--- @tparam string name  Slot name.
--- @treturn Slot
function M.newSlot(name)
    assert(type(name) == "string" and #name > 0, "newSlot: name must be a non-empty string")
    return setmetatable({ name = name, _cap = nil, items = {} }, Slot)
end
--- Create a new Slot with a fixed capacity limit.
--- @tparam string name  Slot name.
--- @tparam number cap  Maximum item count (must be >= 1).
--- @treturn Slot
function M.newSlotWithCapacity(name, cap)
    assert(type(cap) == "number" and cap >= 1, "newSlotWithCapacity: cap must be >= 1")
    local s = M.newSlot(name)
    s._cap = cap
    return s
end

--- Return true when the slot contains no items.
--- @treturn boolean
function Slot:isEmpty()  return #self.items == 0 end
--- Return true when the slot has reached its capacity.
--- @treturn boolean
function Slot:isFull()   return self._cap ~= nil and #self.items >= self._cap end
--- Return the number of items in the slot.
--- @treturn number
function Slot:size()     return #self.items end
--- Return the capacity limit, or nil for unlimited.
--- @treturn number|nil
function Slot:capacity() return self._cap end
--- Set or remove the capacity limit (nil = unlimited).
--- @param cap number|nil
function Slot:setCapacity(cap) self._cap = cap end

--- Push a card into the slot; returns true on success, false+error when full.
--- @param card LCard
--- @treturn boolean
function Slot:push(card)
    if self:isFull() then return false, 'slot is full' end
    self.items[#self.items+1] = card
    return true
end
--- Remove and return the last pushed card, or nil if empty.
--- @treturn LCard|nil
function Slot:pop()
    if #self.items == 0 then return nil end
    return table.remove(self.items)
end
--- Remove and return the item at 1-based index, or nil if out of range.
--- @param idx number
--- @treturn LCard|nil
function Slot:removeAt(idx)
    if idx < 1 or idx > #self.items then return nil end
    return table.remove(self.items, idx)
end
--- Return the last pushed item without removing it.
--- @treturn LCard|nil
function Slot:peek()      return self.items[#self.items] end
--- Return the item at 1-based index without removing it.
--- @param idx number
--- @treturn LCard|nil
function Slot:peekAt(idx) return self.items[idx] end
--- Clear all items and return them.
--- @treturn table
function Slot:clear()
    local old = self.items; self.items = {}; return old
end
--- Return the raw items array (by reference).
--- @treturn table
function Slot:getItems() return self.items end

--- Return true if any item in the slot has the given tag.
--- @param tag string
--- @treturn boolean
function Slot:hasItemWithTag(tag)
    for _, c in ipairs(self.items) do if c:hasTag(tag) then return true end end
    return false
end
--- Return true if any item in the slot has the given type name.
--- @param t string
--- @treturn boolean
function Slot:hasItemOfType(t)
    for _, c in ipairs(self.items) do if c.card_type == t then return true end end
    return false
end

-- ������ CardPool ������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

local PoolEntry = {}
PoolEntry.__index = PoolEntry

local CardPool = {}
CardPool.__index = CardPool

--- Create a new empty CardPool.
---
--- CardPool fields:
--- @tfield string name            Pool display name.
--- @tfield table entries          Internal weighted entry list.
--- @tfield table rarity_weights   Per-rarity draw weights for drawByRarity.
---
--- @tparam string name  Pool name.
--- @treturn CardPool
function M.newCardPool(name)
    assert(type(name) == "string" and #name > 0, "newCardPool: name must be a non-empty string")
    return setmetatable({ name = name, entries = {}, rarity_weights = {} }, CardPool)
end

--- Add a type with a draw weight (minimum 1).
--- @tparam string type_name  LCard type name (must be non-empty).
--- @tparam number weight  Draw weight (clamped to minimum 1).
function CardPool:add(type_name, weight)
    assert(type(type_name) == "string" and #type_name > 0, "CardPool:add: type_name must be a non-empty string")
    assert(weight == nil or type(weight) == "number", "CardPool:add: weight must be a number or nil")
    self.entries[#self.entries+1] = { type_name = type_name, weight = math.max(1, weight or 1) }
end
--- Remove all entries for the given type name.
--- @param type_name string
function CardPool:remove(type_name)
    for i = #self.entries, 1, -1 do
        if self.entries[i].type_name == type_name then table.remove(self.entries, i) end
    end
end
--- Update the weight for an existing type entry (no-op if not found).
--- @param type_name string
--- @param weight number
function CardPool:setWeight(type_name, weight)
    for _, e in ipairs(self.entries) do
        if e.type_name == type_name then e.weight = math.max(1, weight) end
    end
end
--- Rename the pool.
--- @param n string
function CardPool:setName(n)  self.name = n end
--- Set a per-rarity draw weight used by drawByRarity.
--- @param rarity string
--- @param weight number
function CardPool:setRarityWeight(rarity, weight) self.rarity_weights[rarity] = weight end

--- Return the sum of all entry weights.
--- @treturn number
function CardPool:totalWeight()
    local t = 0
    for _, e in ipairs(self.entries) do t = t + e.weight end
    return t
end
--- Return the number of distinct entries in the pool.
--- @treturn number
function CardPool:size()    return #self.entries end
--- Return true when the pool has no entries.
--- @treturn boolean
function CardPool:isEmpty() return #self.entries == 0 end
--- Return the draw weight for a type name, or 0 if not present.
--- @param type_name string
--- @treturn number
function CardPool:getWeight(type_name)
    for _, e in ipairs(self.entries) do if e.type_name == type_name then return e.weight end end
    return 0
end
--- Return an array of all type name strings in pool insertion order.
--- @treturn table
function CardPool:getTypeNames()
    local out = {}
    for _, e in ipairs(self.entries) do out[#out+1] = e.type_name end
    return out
end

local function weighted_pick(entries)
    local total = 0
    for _, e in ipairs(entries) do total = total + e.weight end
    if total <= 0 then return nil end
    local r = math.random() * total
    local acc = 0
    for _, e in ipairs(entries) do
        acc = acc + e.weight
        if r <= acc then return e end
    end
    return entries[#entries]
end

--- Draw n type names by weighted random selection (with replacement).
--- @tparam number n  Number of draws.
--- @treturn table  Array of type name strings.
function CardPool:drawTypes(n)
    local out = {}
    for _ = 1, n do
        local e = weighted_pick(self.entries)
        if e then out[#out+1] = e.type_name end
    end
    _log_debug("pool '" .. self.name .. "' drew " .. #out .. " types")
    return out
end
--- Draw n Card instances by weighted random selection (with replacement).
--- @param n number
--- @treturn table  Array of LCard objects.
function CardPool:drawItems(n)
    local types = self:drawTypes(n)
    local out = {}
    for _, t in ipairs(types) do out[#out+1] = M.newCard(t) end
    return out
end
--- Draw up to n unique type names by weighted selection without replacement.
--- @param n number
--- @treturn table  Array of distinct type name strings.
function CardPool:drawUniqueTypes(n)
    local avail = {}
    for _, e in ipairs(self.entries) do avail[#avail+1] = { type_name = e.type_name, weight = e.weight } end
    local out = {}
    for _ = 1, math.min(n, #avail) do
        local e = weighted_pick(avail)
        if e then
            out[#out+1] = e.type_name
            for j = #avail, 1, -1 do
                if avail[j].type_name == e.type_name then table.remove(avail, j) end
            end
        end
    end
    return out
end
--- Draw up to n unique Card instances by weighted selection without replacement.
--- @param n number
--- @treturn table  Array of LCard objects.
function CardPool:drawUniqueItems(n)
    local types = self:drawUniqueTypes(n)
    local out = {}
    for _, t in ipairs(types) do out[#out+1] = M.newCard(t) end
    return out
end
--- Draw n Card instances using a fixed random seed for reproducibility.
--- Saves and restores the global RNG state across the call so callers
--- outside the seeded scope continue to observe the global RNG sequence.
-- TODO(P4 lift): use lurek.math.newRng()/lurek.math.shuffle when available
-- to avoid touching the global RNG entirely.
-- @see lurek.math
-- @param n number
-- @param seed number
-- @treturn table  Array of LCard objects.
function CardPool:drawItemsSeeded(n, seed)
    -- Pin the global RNG to the requested seed for the duration of the draw,
    -- then restore the previous state so external callers are not perturbed.
    -- math.random() does not expose its state portably across Lua 5.1/5.4 +
    -- LuaJIT, so we sample a fresh seed from the current stream as a proxy
    -- restore point. Determinism inside this call is preserved by the
    -- explicit randomseed(seed) below.
    local restore_seed = math.random(1, 2147483647)
    math.randomseed(seed)
    local out = self:drawItems(n)
    math.randomseed(restore_seed)
    return out
end
--- Draw cards matching a rarity distribution table {rarity=count,...}.
--- @param distribution table  Map of rarity string to draw count.
--- @treturn table  Array of LCard objects.
function CardPool:drawByRarity(distribution)
    local out = {}
    for rarity, count in pairs(distribution) do
        local rarity_entries = {}
        for _, e in ipairs(self.entries) do
            local def = _card_types[e.type_name]
            if def and def.rarity == rarity then
                rarity_entries[#rarity_entries+1] = e
            end
        end
        for _ = 1, count do
            local e = weighted_pick(rarity_entries)
            if e then out[#out+1] = M.newCard(e.type_name) end
        end
    end
    return out
end

-- ������ StackManager ������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

local StackManager = {}
StackManager.__index = StackManager

--- Create a new empty StackManager.
--- @treturn StackManager
function M.newStackManager()
    return setmetatable({ stacks = {} }, StackManager)
end

--- Register an existing stack under a name.
--- @param name string
--- @param stack LCardStack
function StackManager:addStack(name, stack)       self.stacks[name] = stack end
--- Create and register a new unbounded stack.
--- @param name string
function StackManager:createStack(name)            self.stacks[name] = M.newStack(name) end
--- Create and register a new capacity-limited stack.
--- @param name string
--- @param cap number
function StackManager:createStackCapped(name, cap) self.stacks[name] = M.newStackWithCapacity(name, cap) end
--- Deregister and return a stack, or nil if not found.
--- @param name string
--- @treturn LCardStack|nil
function StackManager:removeStack(name)
    local s = self.stacks[name]; self.stacks[name] = nil; return s
end
--- Return true if a stack with the given name is registered.
--- @param name string
--- @treturn boolean
function StackManager:hasStack(name)  return self.stacks[name] ~= nil end
--- Return the registered Stack, or nil if not found.
--- @param name string
--- @treturn LCardStack|nil
function StackManager:getStack(name)  return self.stacks[name] end

--- Return a sorted list of all registered stack names.
--- @treturn table
function StackManager:stackNames()
    local out = {}
    for k in pairs(self.stacks) do out[#out+1] = k end
    table.sort(out)
    return out
end

--- Return the total number of cards across all registered stacks.
--- @treturn number
function StackManager:totalItems()
    local n = 0
    for _, s in pairs(self.stacks) do n = n + s:size() end
    return n
end

--- Move the card at idx in from_name to the top of to_name.
--- @param from_name string
--- @param idx number  1-based index.
--- @param to_name string
--- @treturn LCard|nil, string|nil  Moved LCard or nil+error.
function StackManager:moveItem(from_name, idx, to_name)
    local from_s = self.stacks[from_name]
    local to_s = self.stacks[to_name]
    if not from_s or not to_s then return nil, 'stack not found' end
    local card = from_s:removeAt(idx)
    if not card then return nil, 'invalid index' end
    if not to_s:pushTop(card) then
        from_s:insertAt(idx, card)
        return nil, 'destination full'
    end
    return card
end

--- Move the first card of a given type from one stack to another.
--- @param from_name string
--- @param card_type string
--- @param to_name string
--- @treturn LCard|nil, string|nil
function StackManager:moveItemByType(from_name, card_type, to_name)
    local from_s = self.stacks[from_name]
    if not from_s then return nil, 'stack not found' end
    local idx = from_s:findByType(card_type)
    if not idx then return nil, 'type not found' end
    return self:moveItem(from_name, idx, to_name)
end

--- Move the top card from one stack to another.
--- @param from_name string
--- @param to_name string
--- @treturn LCard|nil, string|nil
function StackManager:moveTop(from_name, to_name)
    local from_s = self.stacks[from_name]
    if not from_s or from_s:isEmpty() then return nil, 'empty or not found' end
    return self:moveItem(from_name, from_s:size(), to_name)
end

-- ������ BuildEntry ������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

--- Create a new build entry for use with DeckBuilder.
--- @param type_name string  LCard type to include.
--- @param count number  Number of copies.
--- @treturn table  BuildEntry.
function M.newBuildEntry(type_name, count)
    return {
        type_name      = type_name,
        count          = count or 1,
        stat_overrides = {},
        extra_tags     = {},
        extra_metadata = {},
    }
end

-- ������ DeckBuilder ���������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

local DeckBuilder = {}
DeckBuilder.__index = DeckBuilder

--- Create a new DeckBuilder.
--- @param name string  Default name for the constructed deck.
--- @treturn DeckBuilder
function M.newDeckBuilder(name)
    return setmetatable({
        name                = name,
        entries             = {},
        shuffle_on_build    = false,
        min_size            = 0,
        max_size            = 0,
        max_copies          = 0,
        per_type_limits     = {},
        required_types      = {},
        banned_types        = {},
        banned_categories   = {},
        max_per_category    = {},
        required_tags       = {},
        required_categories = {},
    }, DeckBuilder)
end

--- Add count copies of type_name to the build list.
--- @tparam string type_name  LCard type name (must be non-empty).
--- @tparam number count  Number of copies (must be >= 1).
function DeckBuilder:add(type_name, count)
    assert(type(type_name) == "string" and #type_name > 0, "DeckBuilder:add: type_name must be a non-empty string")
    assert(type(count) == "number" and count >= 1, "DeckBuilder:add: count must be >= 1")
    self.entries[#self.entries+1] = M.newBuildEntry(type_name, count)
end

--- Add count copies with per-card stat overrides and extra tags.
--- @param type_name string
--- @param count number
--- @param stat_overrides table  Map of stat_name ��� value.
--- @param extra_tags table  Array of tag strings.
function DeckBuilder:addWith(type_name, count, stat_overrides, extra_tags)
    local e = M.newBuildEntry(type_name, count)
    e.stat_overrides = stat_overrides or {}
    e.extra_tags = extra_tags or {}
    self.entries[#self.entries+1] = e
end

--- Mark a card type as required (must appear at least once in the deck).
--- @param t string
function DeckBuilder:requireType(t)
    self.required_types[#self.required_types+1] = t
end
--- Add a type to the ban list; validateEntries will report it as an error.
--- @param t string
function DeckBuilder:banType(t)
    self.banned_types[#self.banned_types+1] = t
end
--- Remove a type from the ban list; returns true if it was present.
--- @param t string
--- @treturn boolean
function DeckBuilder:removeBannedType(t)
    for i, v in ipairs(self.banned_types) do
        if v == t then table.remove(self.banned_types, i); return true end
    end
    return false
end
--- Override the global max_copies limit for a specific type.
--- @param t string
--- @param max_val number
function DeckBuilder:setMaxCopiesForType(t, max_val)
    self.per_type_limits[t] = max_val
end
--- Require that at least min_count cards with the given tag appear.
--- @param tag string
--- @param min_count number
function DeckBuilder:addRequiredTag(tag, min_count)
    self.required_tags[#self.required_tags+1] = { tag, min_count }
end
--- Require a specific count range for cards of a given category.
--- @param cat string
--- @param min_count number
--- @param max_count number|nil
function DeckBuilder:addRequiredCategory(cat, min_count, max_count)
    self.required_categories[#self.required_categories+1] = { cat, min_count, max_count }
end

--- Validate the builder's entries against all constraints.
--- @treturn table  Array of error strings (empty = valid).
function DeckBuilder:validateEntries()
    local errors = {}
    local total = 0
    local type_counts = {}
    for _, e in ipairs(self.entries) do
        total = total + e.count
        type_counts[e.type_name] = (type_counts[e.type_name] or 0) + e.count
        for _, bt in ipairs(self.banned_types) do
            if e.type_name == bt then
                errors[#errors+1] = 'banned type: ' .. bt
            end
        end
    end
    if self.min_size > 0 and total < self.min_size then
        errors[#errors+1] = 'below min size'
    end
    if self.max_size > 0 and total > self.max_size then
        errors[#errors+1] = 'exceeds max size'
    end
    if self.max_copies > 0 then
        for t, cnt in pairs(type_counts) do
            local lim = self.per_type_limits[t] or self.max_copies
            if cnt > lim then errors[#errors+1] = 'too many copies: ' .. t end
        end
    end
    for _, rt in ipairs(self.required_types) do
        if not type_counts[rt] then errors[#errors+1] = 'missing required type: ' .. rt end
    end
    return errors
end

--- Validate an already-built Stack against size constraints.
--- @param stack LCardStack
--- @treturn table  Array of error strings.
function DeckBuilder:validateStack(stack)
    local errors = {}
    local total = stack:size()
    if self.min_size > 0 and total < self.min_size then errors[#errors+1] = 'below min size' end
    if self.max_size > 0 and total > self.max_size then errors[#errors+1] = 'exceeds max size' end
    return errors
end

--- Build and return a Stack using the builder's own name.
--- @treturn LCardStack
function DeckBuilder:build() return self:buildNamed(self.name) end

--- Build and return a Stack with a custom name.
--- @tparam string stack_name
--- @treturn LCardStack
function DeckBuilder:buildNamed(stack_name)
    local stack = M.newStack(stack_name)
    for _, entry in ipairs(self.entries) do
        for _ = 1, entry.count do
            local card = M.newCard(entry.type_name)
            for k, v in pairs(entry.stat_overrides) do card:setStat(k, v) end
            for _, t in ipairs(entry.extra_tags) do card:addTag(t) end
            for k, v in pairs(entry.extra_metadata) do card:setMeta(k, v) end
            stack:pushTop(card)
        end
    end
    if self.shuffle_on_build then stack:shuffle() end
    _log_info("built deck '" .. stack_name .. "' with " .. stack:size() .. " cards")
    return stack
end

-- ������ HistoryAction constructors ������������������������������������������������������������������������������������������������������������������������������������

M.HistoryAction = {}
--- Create a Pushed action recording which card was pushed.
--- @param card_type string
--- @param item_name string
--- @treturn table
function M.HistoryAction.pushed(card_type, item_name)
    return { kind = 'pushed', card_type = card_type, item_name = item_name }
end
--- Create a Popped action recording which card was popped.
--- @param card_type string
--- @param item_name string
--- @treturn table
function M.HistoryAction.popped(card_type, item_name)
    return { kind = 'popped', card_type = card_type, item_name = item_name }
end
--- Create a Moved action recording an inter-stack card transfer.
--- @param card_type string
--- @param item_name string
--- @param from_stack string
--- @param to_stack string
--- @treturn table
function M.HistoryAction.moved(card_type, item_name, from_stack, to_stack)
    return { kind = 'moved', card_type = card_type, item_name = item_name, from_stack = from_stack, to_stack = to_stack }
end
--- Create a Shuffled action.
--- @treturn table
function M.HistoryAction.shuffled() return { kind = 'shuffled' } end
--- Create a Sorted action recording the sort field.
--- @param by string
--- @treturn table
function M.HistoryAction.sorted(by) return { kind = 'sorted', by = by } end
--- Create a Cleared action.
--- @treturn table
function M.HistoryAction.cleared()  return { kind = 'cleared' } end
--- Create a Built action recording how many cards were built.
--- @param count number
--- @treturn table
function M.HistoryAction.built(count) return { kind = 'built', count = count } end
--- Create a user-defined Custom action.
--- @param label string
--- @treturn table
function M.HistoryAction.custom(label) return { kind = 'custom', label = label } end

-- ������ StackHistory ������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

local StackHistory = {}
StackHistory.__index = StackHistory

--- Create a new unlimited StackHistory.
--- @treturn StackHistory
function M.newStackHistory()
    return setmetatable({ _entries = {}, max_size = nil, _next_seq = 0 }, StackHistory)
end
--- Create a StackHistory that keeps only the most recent max_size entries.
--- @param max_size number
--- @treturn StackHistory
function M.newStackHistoryWithMaxSize(max_size)
    local h = M.newStackHistory()
    h.max_size = max_size
    return h
end

--- Append an action entry to the log.
--- @param stack_name string
--- @param action table  A HistoryAction table.
--- @param size_after number  LCardStack size after the action.
function StackHistory:record(stack_name, action, size_after)
    local entry = { seq = self._next_seq, stack_name = stack_name, action = action, size_after = size_after }
    self._next_seq = self._next_seq + 1
    self._entries[#self._entries+1] = entry
    if self.max_size and #self._entries > self.max_size then
        table.remove(self._entries, 1)
    end
end

--- Append a user-defined label as a Custom action.
--- @param stack_name string
--- @param label string
--- @param size_after number
function StackHistory:recordCustom(stack_name, label, size_after)
    self:record(stack_name, M.HistoryAction.custom(label), size_after)
end

--- Return the number of recorded entries.
--- @treturn number
function StackHistory:len()     return #self._entries end
--- Return true when no entries have been recorded.
--- @treturn boolean
function StackHistory:isEmpty() return #self._entries == 0 end
--- Return the entries array (oldest first).
--- @treturn table
function StackHistory:entries() return self._entries end
--- Return the most recent entry, or nil if empty.
--- @treturn table|nil
function StackHistory:last()    return self._entries[#self._entries] end

--- Return all entries for the given stack name.
--- @param stack_name string
--- @treturn table  Array of history entry tables.
function StackHistory:entriesFor(stack_name)
    local out = {}
    for _, e in ipairs(self._entries) do
        if e.stack_name == stack_name then out[#out+1] = e end
    end
    return out
end

--- Clear all recorded entries.
function StackHistory:clear() self._entries = {} end

-- ������ CardGroup ���������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������

local CardGroup = {}
CardGroup.__index = CardGroup

--- Create a new CardGroup with a label, index list, and optional score.
--- @param label string  Human-readable group label.
--- @param indices table  Array of 1-based indices into a LCard list.
--- @param score number|nil  Optional numeric score (default 0).
--- @treturn CardGroup
function M.newCardGroup(label, indices, score)
    return setmetatable({ label = label, indices = indices or {}, score = score or 0 }, CardGroup)
end

--- Collect the actual card objects referenced by this group's indices.
--- @param cards table  Flat array of LCard objects.
--- @treturn table  Array of LCard objects.
function CardGroup:itemsFrom(cards)
    local out = {}
    for _, idx in ipairs(self.indices) do
        if cards[idx] then out[#out+1] = cards[idx] end
    end
    return out
end

--- Return the number of cards in the group.
-- @treturn number
function CardGroup:size() return #self.indices end
--- Return true when the group has no cards.
-- @treturn boolean
function CardGroup:isEmpty() return #self.indices == 0 end
--- Return the highest value of a stat across grouped cards.
-- @param cards table  flat LCard list
-- @param stat  string
-- @treturn number
function CardGroup:maxStat(cards, stat)
    local m = nil
    for _, idx in ipairs(self.indices) do
        local c = cards[idx]
        if c then
            local v = c:getStat(stat)
            if not m or v > m then m = v end
        end
    end
    return m or 0
end
--- Return the sum of a stat across grouped cards.
-- @param cards table
-- @param stat  string
-- @treturn number
function CardGroup:totalStat(cards, stat)
    local s = 0
    for _, idx in ipairs(self.indices) do
        local c = cards[idx]
        if c then s = s + c:getStat(stat) end
    end
    return s
end
--- Return true if every card in the group has the given tag.
-- @param cards table
-- @param tag   string
-- @treturn boolean
function CardGroup:allHaveTag(cards, tag)
    for _, idx in ipairs(self.indices) do
        local c = cards[idx]
        if not c or not c:hasTag(tag) then return false end
    end
    return true
end

-- ������ M.checkDeckLimit ������������������������������������������������������������������������������������������������������������������������������������������������������������������

--- Validate that a card list does not exceed per-type max_per_deck limits.
-- Returns nil on success or an error string describing the first violation.
-- @param cards table  list of LCard objects
-- @treturn string|nil
function M.checkDeckLimit(cards)
    local counts = {}
    for _, c in ipairs(cards) do
        counts[c.card_type] = (counts[c.card_type] or 0) + 1
    end
    for ctype, count in pairs(counts) do
        local def = M.getCardType(ctype)
        if def and def.max_per_deck and count > def.max_per_deck then
            return string.format("'%s' exceeds max_per_deck (%d > %d)", ctype, count, def.max_per_deck)
        end
    end
    return nil
end


-- Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�
-- PARITY ADDITIONS ��� Phase 2A  (cardgame)
-- Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�Լ�

-- ������ HistoryAction: add missing variants ������������������������������������������������������������������������������������������

M.HistoryAction = M.HistoryAction or {}
M.HistoryAction.Moved   = "moved"
M.HistoryAction.Shuffled = "shuffled"
M.HistoryAction.Sorted  = "sorted"
M.HistoryAction.Built   = "built"

-- ������ Module-level analytics free functions ���������������������������������������������������������������������������������������

--- Group card-like items by category field.
-- Returns table: category -> {item,...}.
-- @param items table  list of objects with a .category field or getCategory()
-- @treturn table
function M.groupByCategory(items)
    local out = {}
    for _, it in ipairs(items) do
        local cat = (it.getCategory and it:getCategory()) or it.category or "misc"
        if not out[cat] then out[cat] = {} end
        out[cat][#out[cat]+1] = it
    end
    return out
end

--- Return items where getStat(stat) >= n.
-- @param items table
-- @param stat  string
-- @param n     number
-- @treturn table
function M.findAtLeastNOfStat(items, stat, n)
    local out = {}
    for _, it in ipairs(items) do
        local v = (it.getStat and it:getStat(stat)) or (it.stats and it.stats[stat]) or 0
        if (v or 0) >= n then out[#out+1] = it end
    end
    return out
end

--- Return each unique tag that appears on more than one item, with the items list.
-- @param items table
-- @treturn table  tag -> {item,...}
function M.findTagGroups(items)
    local tag_map = {}
    for _, it in ipairs(items) do
        local tags = {}
        if it.getTags then
            tags = it:getTags()
        elseif it.tags then
            for t in pairs(it.tags) do tags[#tags+1] = t end
        end
        for _, t in ipairs(tags) do
            if not tag_map[t] then tag_map[t] = {} end
            tag_map[t][#tag_map[t]+1] = it
        end
    end
    -- keep only tags shared by >1 item
    local out = {}
    for t, grp in pairs(tag_map) do
        if #grp > 1 then out[t] = grp end
    end
    return out
end

--- Return 1-based indices sorted by a stat (ascending).
-- @param items table
-- @param stat  string
-- @treturn table  indices
function M.sortedIndicesByStat(items, stat)
    local indices = {}
    for i = 1, #items do indices[i] = i end
    table.sort(indices, function(a, b)
        local va = (items[a].getStat and items[a]:getStat(stat)) or (items[a].stats and items[a].stats[stat]) or 0
        local vb = (items[b].getStat and items[b]:getStat(stat)) or (items[b].stats and items[b].stats[stat]) or 0
        return (va or 0) < (vb or 0)
    end)
    return indices
end

--- Return 1-based indices sorted by category (alphabetical).
-- @param items table
-- @treturn table  indices
function M.sortedIndicesByCategory(items)
    local indices = {}
    for i = 1, #items do indices[i] = i end
    table.sort(indices, function(a, b)
        local ca = (items[a].getCategory and items[a]:getCategory()) or items[a].category or ""
        local cb = (items[b].getCategory and items[b]:getCategory()) or items[b].category or ""
        return ca < cb
    end)
    return indices
end

-- ������ Missing parity analysis functions ���������������������������������������������������������������������������������������������������������������

--- Group 1-based indices of items by the integer value of a named stat.
--- Returns a map of stat_value (floored to integer) ��� array of 1-based indices.
--- @param items table  List of LCard objects.
--- @param stat string  Stat name to group by.
--- @treturn table  {[stat_value] = {1-based indices}}.
function M.groupByStat(items, stat)
    local out = {}
    for i, it in ipairs(items) do
        local v = math.floor((it.getStat and it:getStat(stat)) or (it.stats and it.stats[stat]) or 0)
        if not out[v] then out[v] = {} end
        out[v][#out[v]+1] = i
    end
    return out
end

--- Group 1-based indices by the value portion of a prefixed tag.
--- Tags of the form "prefix:value" are grouped under "value".
--- Tags that do not start with prefix: are ignored.
--- @param items table  List of LCard objects.
--- @param prefix string  Tag prefix to match (e.g. "suit" matches "suit:hearts").
--- @treturn table  {[tag_value] = {1-based indices}}.
function M.groupByTagPrefix(items, prefix)
    local search = prefix .. ":"
    local out = {}
    for i, it in ipairs(items) do
        local tags = (type(it.tags) == "table") and it.tags or {}
        for _, t in ipairs(tags) do
            if t:sub(1, #search) == search then
                local val = t:sub(#search + 1)
                if not out[val] then out[val] = {} end
                out[val][#out[val]+1] = i
                break
            end
        end
    end
    return out
end

--- Find all groups where exactly n items share the same integer stat value.
--- Analogous to "n-of-a-kind" detection in card games.
--- @param items table  List of LCard objects.
--- @param stat string  Stat name to compare.
--- @param n number  Exact group size required.
--- @treturn table  Array of CardGroup objects (one per qualifying set).
function M.findNOfStat(items, stat, n)
    local by_val = M.groupByStat(items, stat)
    local out = {}
    for val, indices in pairs(by_val) do
        if #indices == n then
            out[#out+1] = M.newCardGroup(
                string.format("%dx%s|%d", n, stat, val),
                indices,
                n * 100 + math.abs(val)
            )
        end
    end
    return out
end

--- Find all runs of consecutive integer stat values with length >= min_run.
--- Useful for "straight" or sequential-run detection in card games.
--- Each run is returned as a CardGroup whose indices reference the original list.
--- @param items table  List of LCard objects.
--- @param stat string  Stat name to use for sequencing.
--- @param min_run number  Minimum run length to include.
--- @treturn table  Array of CardGroup objects (one per run found).
function M.findSequences(items, stat, min_run)
    if #items == 0 or (min_run or 0) == 0 then return {} end
    local pairs_list = {}
    for i, it in ipairs(items) do
        local v = math.floor((it.getStat and it:getStat(stat)) or (it.stats and it.stats[stat]) or 0)
        pairs_list[#pairs_list+1] = { v = v, i = i }
    end
    table.sort(pairs_list, function(a, b) return a.v < b.v end)
    local runs = {}
    local run_start = 1
    local prev_val = pairs_list[1].v
    for pos = 2, #pairs_list + 1 do
        local is_consecutive = pos <= #pairs_list and pairs_list[pos].v == prev_val + 1
        if not is_consecutive then
            local run_len = pos - run_start
            if run_len >= min_run then
                local indices = {}
                for k = run_start, pos - 1 do
                    indices[#indices+1] = pairs_list[k].i
                end
                local start_val = pairs_list[run_start].v
                runs[#runs+1] = M.newCardGroup(
                    string.format("seq%d|%s+%d", run_len, stat, start_val),
                    indices,
                    run_len * 100 + math.abs(start_val)
                )
            end
            run_start = pos
        end
        if pos <= #pairs_list then
            prev_val = pairs_list[pos].v
        end
    end
    return runs
end


return M
