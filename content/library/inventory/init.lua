--- Lurek2D inventory system — containers, weighted bags, slots, item stacks, equip slots, and item sets.
--
-- A pure-Lua replacement for the former `lurek.inventory` Rust binding.
-- Provides ItemStack, Container (fixed/unlimited/expandable), InvItem with tags,
-- Slot and SlotState, ItemSet, and a full Inventory with equip slots and subsystem flags.
--
-- Usage:
--   local inventory = require("library.inventory")
--   local bag = inventory.newContainer("bag", "unlimited", 0)
--   local sword = inventory.newItem("sword")
--   sword:setWeight(3.5)
--   sword:setStackLimit(1)
--   bag:addItem(sword, 1)
--
-- @module library.inventory

local M = {}

--- Optional engine logger. Uses lurek.log when running inside the engine,
-- silently no-ops in standalone Lua.
local _log
if lurek and lurek.log then
    _log = lurek.log
end
local function _info(msg)  if _log then _log.info(msg) end end
local function _warn(msg)  if _log then _log.warn(msg) end end

-- ─── SlotState ────────────────────────────────────────────────────────────────

--- Slot state constants.
-- @field Active Slot is actively usable.
-- @field Passive Slot is visible but locked.
-- @field Idle Slot is dormant / not yet unlocked.
M.SlotState = { Active = "active", Passive = "passive", Idle = "idle" }

-- ─── InvItem ──────────────────────────────────────────────────────────────────

--- Create a lightweight inventory item definition.
-- Each item has a type, weight, size, stack limit, tag set, and a property map.
-- @tparam string type_name Item type identifier (e.g. "sword").
-- @treturn table InvItem object.
function M.newItem(type_name)
    assert(type(type_name) == "string" and type_name ~= "", "newItem: type_name must be a non-empty string")
    local _weight      = 0.0
    local _size_w      = 1
    local _size_h      = 1
    local _stack_limit = 1
    local _tags        = {}   -- set: tag -> true
    local _props       = {}   -- key -> value

    local item = {}

    --- Return the type name.
    -- @treturn string
    function item:getType()       return type_name end

    --- Return item weight.
    -- @treturn number
    function item:getWeight()     return _weight end

    --- Set physical weight (must be non-negative).
    -- @tparam number w Weight value.
    function item:setWeight(w)
        w = w or 0.0
        assert(type(w) == "number" and w >= 0, "setWeight: weight must be a non-negative number")
        _weight = w
    end

    --- Return grid width.
    -- @treturn number
    function item:getSizeW()      return _size_w end

    --- Return grid height.
    -- @treturn number
    function item:getSizeH()      return _size_h end

    --- Set grid size (both dimensions clamped to >= 1).
    -- @tparam number w Width.
    -- @tparam number h Height.
    function item:setSize(w, h)
        _size_w = math.max(1, w or 1)
        _size_h = math.max(1, h or 1)
    end

    --- Return maximum items per stack.
    -- @treturn number
    function item:getStackLimit() return _stack_limit end

    --- Set maximum stack size (clamped to >= 1).
    -- @tparam number n Maximum stack count.
    function item:setStackLimit(n) _stack_limit = math.max(1, n or 1) end

    --- Return true if the item has the given tag.
    -- @tparam string tag Tag name.
    -- @treturn boolean
    function item:hasTag(tag)     return _tags[tag] == true end

    --- Add a tag (no-op if already present).
    -- @tparam string tag Tag name to add.
    function item:addTag(tag)
        assert(type(tag) == "string" and tag ~= "", "addTag: tag must be a non-empty string")
        _tags[tag] = true
    end

    --- Remove a tag. Returns true if tag existed.
    -- @tparam string tag Tag name to remove.
    -- @treturn boolean
    function item:removeTag(tag)
        if _tags[tag] then _tags[tag] = nil; return true end
        return false
    end

    --- Return all tag names as an array.
    -- @treturn table
    function item:getTags()
        local out = {}
        for t in pairs(_tags) do table.insert(out, t) end
        table.sort(out)
        return out
    end

    --- Set a generic property.
    -- @tparam string key Property key.
    -- @param val any Property value.
    function item:setProperty(key, val) _props[key] = val end

    --- Get a generic property.
    -- @tparam string key Property key.
    -- @treturn any
    function item:getProperty(key) return _props[key] end

    --- Deep-copy this item definition.
    -- @treturn table copy of InvItem
    function item:clone()
        local c = M.newItem(type_name)
        c:setWeight(_weight)
        c:setSize(_size_w, _size_h)
        c:setStackLimit(_stack_limit)
        for t in pairs(_tags)  do c:addTag(t) end
        for k, v in pairs(_props) do c:setProperty(k, v) end
        return c
    end

    return item
end

-- ─── ItemStack ────────────────────────────────────────────────────────────────

--- Create a counted stack of a single item type.
-- @tparam table inv_item InvItem definition.
-- @tparam number quantity Initial count (clamped to 0..max).
-- @tparam number max_quantity Maximum stack size (clamped to >= 1).
-- @treturn table ItemStack object.
function M.newItemStack(inv_item, quantity, max_quantity)
    assert(inv_item ~= nil, "newItemStack: inv_item must not be nil")
    quantity = quantity or 1
    assert(type(quantity) == "number" and quantity >= 0, "newItemStack: quantity must be a non-negative number")
    local _item  = inv_item
    local _max   = math.max(1, max_quantity or inv_item:getStackLimit())
    local _qty   = math.min(quantity, _max)

    local stack = {}

    --- Return the underlying InvItem.
    -- @treturn table
    function stack:getItem()        return _item end

    --- Return current quantity.
    -- @treturn number
    function stack:getQuantity()    return _qty end

    --- Directly set quantity (clamped 0..max).
    -- @tparam number n New quantity.
    function stack:setQuantity(n)   _qty = math.max(0, math.min(n, _max)) end

    --- Return max quantity.
    -- @treturn number
    function stack:getStackLimit()  return _max end

    --- Return true when stack holds max items.
    -- @treturn boolean
    function stack:isFull()         return _qty >= _max end

    --- Return true when stack is empty.
    -- @treturn boolean
    function stack:isEmpty()        return _qty == 0 end

    --- Add n items. Returns overflow (items that did not fit).
    -- @tparam number n Items to add.
    -- @treturn number overflow count
    function stack:add(n)
        assert(type(n) == "number" and n >= 0, "ItemStack:add: n must be non-negative")
        local space = _max - _qty
        local added = math.min(n, space)
        _qty = _qty + added
        return n - added
    end

    --- Remove n items. Returns count actually removed.
    -- @tparam number n Items to remove.
    -- @treturn number
    function stack:remove(n)
        assert(type(n) == "number" and n >= 0, "ItemStack:remove: n must be non-negative")
        local taken = math.min(n, _qty)
        _qty = _qty - taken
        return taken
    end

    --- Split n items off into a new stack. Returns nil if n invalid.
    -- @tparam number n Items to split off.
    -- @treturn table|nil new ItemStack
    function stack:split(n)
        if n <= 0 or n > _qty then return nil end
        _qty = _qty - n
        return M.newItemStack(_item, n, _max)
    end

    --- Merge another stack into this one. Returns leftover count.
    -- @tparam table other ItemStack to merge from.
    -- @treturn number
    function stack:merge(other)
        local leftover = self:add(other:getQuantity())
        other:setQuantity(leftover)
        return leftover
    end

    return stack
end

-- ─── Slot ─────────────────────────────────────────────────────────────────────

--- Create a single inventory slot (holds one ItemStack).
-- @tparam string slot_type Filter type ("any" = accept all).
-- @tparam string state SlotState value.
-- @treturn table Slot object.
function M.newSlot(slot_type, state)
    local _type  = slot_type or "any"
    local _state = state or M.SlotState.Active
    assert(type(_type) == "string", "newSlot: slot_type must be a string")
    local _stack = nil   -- ItemStack or nil
    local _cap_w = 1
    local _cap_h = 1

    local slot = {}

    --- Return slot type filter.
    -- @treturn string
    function slot:getSlotType()   return _type end

    --- Return current state.
    -- @treturn string
    function slot:getState()      return _state end

    --- Set state.
    -- @tparam string s SlotState constant.
    function slot:setState(s)     _state = s end

    --- Return true if no item is held.
    -- @treturn boolean
    function slot:isEmpty()       return _stack == nil end

    --- Return the held ItemStack, or nil.
    -- @treturn table|nil
    function slot:getStack()      return _stack end

    --- Return the held InvItem (unwrapped), or nil.
    -- @treturn table|nil
    function slot:getItem()
        return _stack and _stack:getItem() or nil
    end

    --- Return true if the item fits size constraints and type filter.
    -- Items are accepted if the slot type is "any", or the item type matches
    -- the slot type, or the item carries a tag matching the slot type.
    -- @tparam table item InvItem to test.
    -- @treturn boolean
    function slot:canAccept(item)
        if _type ~= "any" and _type ~= item:getType() and not item:hasTag(_type) then
            return false
        end
        return item:getSizeW() <= _cap_w and item:getSizeH() <= _cap_h
    end

    --- Place an ItemStack. Returns false if item not accepted.
    -- @tparam table s ItemStack to place.
    -- @treturn boolean
    function slot:setStack(s)
        if not self:canAccept(s:getItem()) then return false end
        _stack = s
        return true
    end

    --- Remove and return the held stack.
    -- @treturn table|nil
    function slot:takeStack()
        local s = _stack; _stack = nil; return s
    end

    --- Clear the slot.
    function slot:clear()         _stack = nil end

    return slot
end

-- ─── Container ────────────────────────────────────────────────────────────────

--- Create a named container managing a list of slots.
-- For expandable mode, `max_slots` caps how far `expand()` can grow.
-- @tparam string name Container identifier.
-- @tparam string mode "fixed" | "unlimited" | "expandable".
-- @tparam number slot_count Initial number of slots (ignored for unlimited).
-- @tparam[opt] number max_slots Upper slot cap for expandable mode (defaults to slot_count).
-- @treturn table Container object.
function M.newContainer(name, mode, slot_count, max_slots)
    mode = mode or "unlimited"
    assert(mode == "fixed" or mode == "unlimited" or mode == "expandable",
        "newContainer: mode must be 'fixed', 'unlimited', or 'expandable'")
    slot_count = math.max(0, slot_count or 0)
    local _slots      = {}
    local _wt_limit   = 0.0   -- 0 = unlimited
    local _max_slots  = 0
    if mode == "fixed" then
        _max_slots = slot_count
    elseif mode == "expandable" then
        _max_slots = math.max(slot_count, max_slots or slot_count)
    end
    -- 0 for unlimited means unbounded

    -- seed initial slots
    for i = 1, slot_count do
        _slots[i] = M.newSlot("any", M.SlotState.Active)
    end

    local container = {}

    --- Return the container name.
    -- @treturn string
    function container:getName()       return name end

    --- Return the container mode string.
    -- @treturn string
    function container:getMode()       return mode end

    --- Return the number of slots.
    -- @treturn number
    function container:slotCount()     return #_slots end

    --- Return max slot count. 0 = unbounded.
    -- @treturn number
    function container:getCapacity()   return _max_slots end

    --- Set weight limit (must be non-negative). 0 = unlimited.
    -- @tparam number w Weight limit.
    function container:setWeightLimit(w)
        w = w or 0.0
        assert(type(w) == "number" and w >= 0, "setWeightLimit: value must be non-negative")
        _wt_limit = w
    end

    --- Return weight limit. 0 = unlimited.
    -- @treturn number
    function container:getWeightLimit()  return _wt_limit end

    --- Return current total weight.
    -- @treturn number
    function container:getCurrentWeight()
        local total = 0
        for _, sl in ipairs(_slots) do
            local st = sl:getStack()
            if st then
                total = total + st:getItem():getWeight() * st:getQuantity()
            end
        end
        return total
    end

    --- Alias for getCurrentWeight.
    -- @treturn number
    function container:totalWeight()   return self:getCurrentWeight() end

    --- Return true if all slots are occupied (fixed/expandable) or weight limit reached.
    -- @treturn boolean
    function container:isFull()
        if _wt_limit > 0 then
            if self:getCurrentWeight() >= _wt_limit then return true end
        end
        if mode == "unlimited" then return false end
        for _, sl in ipairs(_slots) do
            if sl:isEmpty() then return false end
        end
        return true
    end

    --- Get a slot by 1-based index.
    -- @tparam number idx 1-based slot index.
    -- @treturn table|nil
    function container:getSlot(idx)    return _slots[idx] end

    --- Return all slots array.
    -- @treturn table
    function container:getSlots()
        local out = {}
        for _, sl in ipairs(_slots) do table.insert(out, sl) end
        return out
    end

    --- Add slot (respects mode limits).
    -- @tparam table sl Slot object.
    function container:addSlot(sl)
        if mode == "fixed" and #_slots >= _max_slots then return end
        if mode == "expandable" and _max_slots > 0 and #_slots >= _max_slots then return end
        table.insert(_slots, sl)
    end

    --- Set the upper slot capacity (expandable mode only).
    -- Clamped so it cannot be less than the current slot count.
    -- @tparam number n New maximum slot count.
    function container:setCapacity(n)
        if mode ~= "expandable" then return end
        _max_slots = math.max(#_slots, n or 0)
    end

    --- Expand by n new empty slots (expandable mode only). Returns true if any added.
    -- Respects the max-slot capacity; stops adding once the limit is reached.
    -- @tparam number n Number of slots to add.
    -- @treturn boolean
    function container:expand(n)
        if mode ~= "expandable" then return false end
        local added = 0
        for _ = 1, n do
            if _max_slots > 0 and #_slots >= _max_slots then break end
            table.insert(_slots, M.newSlot("any", M.SlotState.Active))
            added = added + 1
        end
        return added > 0
    end

    --- Auto-place item quantity. Merges into ALL existing matching stacks first,
    -- then fills empty slots. For unlimited containers, auto-grows as needed.
    -- @tparam table inv_item InvItem definition.
    -- @tparam number quantity Number of items to add (must be > 0).
    -- @treturn boolean true if fully placed.
    function container:addItem(inv_item, quantity)
        quantity = quantity or 1
        assert(type(quantity) == "number" and quantity > 0, "addItem: quantity must be a positive number")
        local remaining = quantity

        -- merge into ALL existing matching stacks (not just the first)
        for _, sl in ipairs(_slots) do
            if remaining == 0 then break end
            local st = sl:getStack()
            if st and st:getItem():getType() == inv_item:getType() and not st:isFull() then
                remaining = st:add(remaining)
            end
        end

        -- place in empty slots
        while remaining > 0 do
            local limit = inv_item:getStackLimit()
            local to_place = math.min(remaining, limit)
            local placed = false
            for _, sl in ipairs(_slots) do
                if sl:isEmpty() and sl:canAccept(inv_item) then
                    sl:setStack(M.newItemStack(inv_item, to_place, limit))
                    placed = true
                    remaining = remaining - to_place
                    break
                end
            end
            if not placed then
                -- auto-grow for unlimited
                if mode == "unlimited" then
                    local new_sl = M.newSlot("any", M.SlotState.Active)
                    table.insert(_slots, new_sl)
                    new_sl:setStack(M.newItemStack(inv_item, to_place, limit))
                    remaining = remaining - to_place
                else
                    _warn("addItem: could not place " .. remaining .. "x " .. inv_item:getType() .. " in '" .. name .. "'")
                    return false
                end
            end
        end
        _info("addItem: placed " .. quantity .. "x " .. inv_item:getType() .. " in '" .. name .. "'")
        return true
    end

    --- Count all items of a given type across all slots.
    -- @tparam string type_name Item type to count.
    -- @treturn number
    function container:countItem(type_name)
        local total = 0
        for _, sl in ipairs(_slots) do
            local st = sl:getStack()
            if st and st:getItem():getType() == type_name then
                total = total + st:getQuantity()
            end
        end
        return total
    end

    --- Return true if >= qty of type_name present.
    -- @tparam string type_name Item type.
    -- @tparam number qty Required count.
    -- @treturn boolean
    function container:hasItem(type_name, qty)
        return self:countItem(type_name) >= (qty or 1)
    end

    --- Remove up to qty items of type_name. Returns count removed.
    -- @tparam string type_name Item type to remove.
    -- @tparam number qty Maximum items to remove.
    -- @treturn number
    function container:removeItem(type_name, qty)
        qty = qty or 1
        assert(type(qty) == "number" and qty > 0, "removeItem: qty must be a positive number")
        local remaining = qty
        for _, sl in ipairs(_slots) do
            if remaining == 0 then break end
            local st = sl:getStack()
            if st and st:getItem():getType() == type_name then
                local taken = st:remove(remaining)
                remaining = remaining - taken
                if st:isEmpty() then sl:clear() end
            end
        end
        local removed = qty - remaining
        if removed > 0 then
            _info("removeItem: removed " .. removed .. "x " .. type_name .. " from '" .. name .. "'")
        end
        return removed
    end

    --- Return all items with the given tag.
    -- @tparam string tag Tag to filter by.
    -- @treturn table Array of InvItem.
    function container:findByTag(tag)
        local out = {}
        for _, sl in ipairs(_slots) do
            local it = sl:getItem()
            if it and it:hasTag(tag) then table.insert(out, it) end
        end
        return out
    end

    --- Return a summary list of {type_name, quantity} aggregated across slots.
    -- @treturn table Array of {type_name, total_qty}
    function container:toItemList()
        local agg = {}
        for _, sl in ipairs(_slots) do
            local st = sl:getStack()
            if st then
                local t = st:getItem():getType()
                agg[t] = (agg[t] or 0) + st:getQuantity()
            end
        end
        local out = {}
        for t, q in pairs(agg) do table.insert(out, {type_name=t, quantity=q}) end
        table.sort(out, function(a,b) return a.type_name < b.type_name end)
        return out
    end


    --- Remove the slot at a 1-based index. Shifts subsequent slots down.
    -- @tparam number idx 1-based slot index.
    -- @treturn boolean true if the slot was removed, false if out of range.
    function container:removeSlot(idx)
        if idx < 1 or idx > #_slots then return false end
        table.remove(_slots, idx)
        return true
    end

    return container
end

-- ─── ItemSet ──────────────────────────────────────────────────────────────────

--- Create a named item set (bonus condition).
-- All requirements must be satisfied simultaneously for the set to be active.
-- @tparam string name Display name.
-- @treturn table ItemSet object.
function M.newItemSet(name)
    local _reqs = {}  -- { tag, slot_filter } list

    local iset = {}

    --- Return the set name.
    -- @treturn string
    function iset:getName()             return name end

    --- Add a requirement: at least one equip slot must hold an item with `tag`.
    -- @tparam string tag Required tag.
    -- @tparam string slot_filter Check only this slot name, or "" for any.
    function iset:addRequirement(tag, slot_filter)
        table.insert(_reqs, { tag = tag, slot_filter = slot_filter or "" })
    end

    --- Return all requirements as array of {tag, slot_filter}.
    -- @treturn table
    function iset:getRequirements()
        local out = {}
        for _, r in ipairs(_reqs) do table.insert(out, {tag=r.tag, slot_filter=r.slot_filter}) end
        return out
    end

    --- Check if all requirements are satisfied given an equip_slots table {name -> Slot}.
    -- @tparam table equip_slots Map of slot name to Slot.
    -- @treturn boolean
    function iset:isSatisfied(equip_slots)
        for _, req in ipairs(_reqs) do
            local found = false
            for slot_name, sl in pairs(equip_slots) do
                if (req.slot_filter == "" or slot_name == req.slot_filter) then
                    local it = sl:getItem()
                    if it and it:hasTag(req.tag) then found = true; break end
                end
            end
            if not found then return false end
        end
        return true
    end

    return iset
end

-- ─── Inventory ────────────────────────────────────────────────────────────────

--- Create a top-level inventory managing containers, equip slots, item sets, and subsystem flags.
-- @treturn table Inventory object.
function M.newInventory()
    local _containers   = {}   -- name -> Container
    local _cont_order   = {}
    local _equip_slots  = {}   -- name -> Slot
    local _equip_order  = {}
    local _item_sets    = {}   -- array of ItemSet
    local _subsystems   = { weight=false, size=false, stacking=false, sets=false }

    local inv = {}

    -- ── Containers ──────────────────────────────────────────────────────────

    --- Register a container. Replaces any existing container with the same name.
    -- @tparam string name Container name.
    -- @tparam table container Container object.
    function inv:addContainer(name, container)
        if not _containers[name] then table.insert(_cont_order, name) end
        _containers[name] = container
    end

    --- Get a container by name.
    -- @tparam string name Container name.
    -- @treturn table|nil
    function inv:getContainer(name)  return _containers[name] end

    --- Remove a container. Returns true if it existed.
    -- @tparam string name Container name.
    -- @treturn boolean
    function inv:removeContainer(name)
        if not _containers[name] then return false end
        _containers[name] = nil
        for i, n in ipairs(_cont_order) do
            if n == name then table.remove(_cont_order, i); break end
        end
        return true
    end

    --- Return container names in insertion order.
    -- @treturn table
    function inv:containerNames()
        local out = {}
        for _, n in ipairs(_cont_order) do table.insert(out, n) end
        return out
    end

    -- ── Equip Slots ─────────────────────────────────────────────────────────

    --- Add or replace a named equip slot.
    -- @tparam string name Slot name.
    -- @tparam table slot Slot object.
    function inv:addEquipSlot(name, slot)
        if not _equip_slots[name] then table.insert(_equip_order, name) end
        _equip_slots[name] = slot
    end

    --- Get an equip slot by name.
    -- @tparam string name Slot name.
    -- @treturn table|nil
    function inv:getEquipSlot(name)  return _equip_slots[name] end

    --- Remove an equip slot. Returns true if it existed.
    -- @tparam string name Slot name.
    -- @treturn boolean
    function inv:removeEquipSlot(name)
        if not _equip_slots[name] then return false end
        _equip_slots[name] = nil
        for i, n in ipairs(_equip_order) do
            if n == name then table.remove(_equip_order, i); break end
        end
        return true
    end

    --- Return equip slot names in insertion order.
    -- @treturn table
    function inv:equipSlotNames()
        local out = {}
        for _, n in ipairs(_equip_order) do table.insert(out, n) end
        return out
    end

    --- Equip an ItemStack into the named slot. Returns false if slot missing or item rejected.
    -- @tparam string slot_name Equip slot name.
    -- @tparam table stack ItemStack to equip.
    -- @treturn boolean
    function inv:equip(slot_name, stack)
        local sl = _equip_slots[slot_name]
        if not sl then return false end
        local ok = sl:setStack(stack)
        if ok then
            _info("equip: " .. stack:getItem():getType() .. " -> '" .. slot_name .. "'")
        end
        return ok
    end

    --- Unequip a slot and return its InvItem (not the full stack). Returns nil if empty.
    -- @tparam string slot_name Equip slot name.
    -- @treturn table|nil InvItem
    function inv:unequip(slot_name)
        local sl = _equip_slots[slot_name]
        if not sl then return nil end
        local st = sl:takeStack()
        if st then
            _info("unequip: " .. st:getItem():getType() .. " <- '" .. slot_name .. "'")
        end
        return st and st:getItem() or nil
    end

    -- ── Item Sets ────────────────────────────────────────────────────────────

    --- Register an item set.
    -- @tparam table iset ItemSet object.
    function inv:addItemSet(iset)   table.insert(_item_sets, iset) end

    --- Return all registered item sets.
    -- @treturn table
    function inv:getItemSets()
        local out = {}
        for _, s in ipairs(_item_sets) do table.insert(out, s) end
        return out
    end

    --- Return only the currently active item sets (all requirements met).
    -- @treturn table
    function inv:getActiveSets()
        local out = {}
        for _, s in ipairs(_item_sets) do
            if s:isSatisfied(_equip_slots) then table.insert(out, s) end
        end
        return out
    end

    -- ── Subsystems ───────────────────────────────────────────────────────────

    --- Enable a named subsystem ("weight", "size", "stacking", "sets").
    -- @tparam string name Subsystem name.
    function inv:enableSubsystem(name)
        if _subsystems[name] ~= nil then _subsystems[name] = true end
    end

    --- Disable a named subsystem.
    -- @tparam string name Subsystem name.
    function inv:disableSubsystem(name)
        if _subsystems[name] ~= nil then _subsystems[name] = false end
    end

    --- Return true if the named subsystem is active.
    -- @tparam string name Subsystem name.
    -- @treturn boolean
    function inv:isSubsystemEnabled(name) return _subsystems[name] == true end

    -- ── Cross-container queries ───────────────────────────────────────────────

    --- Count items of a type across ALL containers.
    -- @tparam string type_name Item type.
    -- @treturn number
    function inv:countItem(type_name)
        local total = 0
        for _, c in pairs(_containers) do
            total = total + c:countItem(type_name)
        end
        return total
    end

    --- Return true if total count >= qty across all containers.
    -- @tparam string type_name Item type.
    -- @tparam number qty Required count.
    -- @treturn boolean
    function inv:hasItem(type_name, qty)
        return self:countItem(type_name) >= (qty or 1)
    end

    --- Remove qty items of type_name from whichever containers have them.
    -- @tparam string type_name Item type.
    -- @tparam number qty Items to remove.
    -- @treturn boolean true if full amount removed.
    function inv:removeFromAny(type_name, qty)
        if not self:hasItem(type_name, qty) then return false end
        local remaining = qty
        for _, c in pairs(_containers) do
            if remaining == 0 then break end
            local avail = c:countItem(type_name)
            if avail > 0 then
                local take = math.min(avail, remaining)
                c:removeItem(type_name, take)
                remaining = remaining - take
            end
        end
        return remaining == 0
    end

    --- Transfer a stack from one container slot to another (1-based indices).
    -- @tparam string from_name Source container name.
    -- @tparam number from_idx Source slot index (1-based).
    -- @tparam string to_name Destination container name.
    -- @tparam number to_idx Destination slot index (1-based).
    -- @treturn boolean true on success.
    function inv:transfer(from_name, from_idx, to_name, to_idx)
        local fc = _containers[from_name]
        local tc = _containers[to_name]
        if not fc or not tc then return false end
        local from_slot = fc:getSlot(from_idx)
        local to_slot   = tc:getSlot(to_idx)
        if not from_slot or not to_slot then return false end
        if from_slot:isEmpty() then return false end
        if not to_slot:isEmpty() then return false end
        local st = from_slot:takeStack()
        if not to_slot:setStack(st) then
            from_slot:setStack(st) -- restore
            return false
        end
        return true
    end


    -- ── Stack management ─────────────────────────────────────────────────────

    --- Split `quantity` items from the stack at `slot_idx` in `container_name`
    -- into the first empty compatible slot in the same container.
    -- Returns true if the split succeeded.
    -- @tparam string container_name Container name.
    -- @tparam number slot_idx 1-based slot index of the source stack.
    -- @tparam number quantity Number of items to split off.
    -- @treturn boolean
    function inv:splitStack(container_name, slot_idx, quantity)
        local c = _containers[container_name]
        if not c then return false end
        local from_sl = c:getSlot(slot_idx)
        if not from_sl or from_sl:isEmpty() then return false end
        local st = from_sl:getStack()
        local new_stack = st:split(quantity)
        if not new_stack then return false end
        -- place in first empty compatible slot in the same container
        for i = 1, c:slotCount() do
            if i ~= slot_idx then
                local sl = c:getSlot(i)
                if sl and sl:isEmpty() and sl:canAccept(new_stack:getItem()) then
                    sl:setStack(new_stack)
                    return true
                end
            end
        end
        -- No free slot — undo the split
        st:add(quantity)
        return false
    end

    --- Merge the stack at `from_slot` into `to_slot` within `container_name`.
    -- If the destination is empty, the source stack is moved into it.
    -- Returns true if any items were merged or moved.
    -- @tparam string container_name Container name.
    -- @tparam number from_slot 1-based source slot index.
    -- @tparam number to_slot 1-based destination slot index.
    -- @treturn boolean
    function inv:mergeStacks(container_name, from_slot, to_slot)
        local c = _containers[container_name]
        if not c then return false end
        if from_slot == to_slot then return false end
        local sl_from = c:getSlot(from_slot)
        local sl_to   = c:getSlot(to_slot)
        if not sl_from or not sl_to then return false end
        if sl_from:isEmpty() then return false end
        local st_from = sl_from:getStack()
        if sl_to:isEmpty() then
            sl_from:takeStack()
            sl_to:setStack(st_from)
            return true
        end
        local st_to = sl_to:getStack()
        if st_to:getItem():getType() ~= st_from:getItem():getType() then
            return false
        end
        local leftover = st_to:merge(st_from)
        if leftover == 0 then sl_from:clear() end
        return true
    end

    --- Swap items between two container slots (may be in different containers).
    -- Returns true on success.
    -- @tparam string container_a First container name.
    -- @tparam number slot_a 1-based slot index in container_a.
    -- @tparam string container_b Second container name.
    -- @tparam number slot_b 1-based slot index in container_b.
    -- @treturn boolean
    function inv:swap(container_a, slot_a, container_b, slot_b)
        local ca = _containers[container_a]
        local cb = _containers[container_b]
        if not ca or not cb then return false end
        local sla = ca:getSlot(slot_a)
        local slb = cb:getSlot(slot_b)
        if not sla or not slb then return false end
        local st_a = sla:takeStack()
        local st_b = slb:takeStack()
        if st_a then slb:setStack(st_a) end
        if st_b then sla:setStack(st_b) end
        return true
    end

    return inv
end


-- ─── ContainerMode enum ─────────────────────────────────────────────────────

--- Container storage-mode constants matching the Rust `ContainerMode` enum.
-- Pass these string values to `newContainer()`.
-- @field fixed Fixed number of slots that cannot grow.
-- @field unlimited Unlimited slots that grow on demand.
-- @field expandable Starts at a base count; can grow up to max_slots.
M.ContainerMode = {
    fixed      = "fixed",
    unlimited  = "unlimited",
    expandable = "expandable",
}

return M
