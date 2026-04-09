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

-- ─── SlotState ────────────────────────────────────────────────────────────────

--- Slot state constants.
-- @field Active Slot is actively usable.
-- @field Passive Slot is visible but locked.
-- @field Idle Slot is dormant / not yet unlocked.
M.SlotState = { Active = "active", Passive = "passive", Idle = "idle" }

-- ─── InvItem ──────────────────────────────────────────────────────────────────

--- Create a lightweight inventory item definition.
-- Each item has a type, weight, size, stack limit, tag set, and a property map.
-- @param type_name string Item type identifier (e.g. "sword").
-- @treturn table InvItem object.
function M.newItem(type_name)
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

    --- Set physical weight.
    -- @param w number
    function item:setWeight(w)    _weight = w or 0.0 end

    --- Return grid width.
    -- @treturn number
    function item:getSizeW()      return _size_w end

    --- Return grid height.
    -- @treturn number
    function item:getSizeH()      return _size_h end

    --- Set grid size.
    -- @param w number Width.
    -- @param h number Height.
    function item:setSize(w, h)   _size_w = w or 1; _size_h = h or 1 end

    --- Return maximum items per stack.
    -- @treturn number
    function item:getStackLimit() return _stack_limit end

    --- Set maximum stack size.
    -- @param n number
    function item:setStackLimit(n) _stack_limit = math.max(1, n or 1) end

    --- Return true if the item has the given tag.
    -- @param tag string
    -- @treturn boolean
    function item:hasTag(tag)     return _tags[tag] == true end

    --- Add a tag (no-op if already present).
    -- @param tag string
    function item:addTag(tag)     _tags[tag] = true end

    --- Remove a tag. Returns true if tag existed.
    -- @param tag string
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
    -- @param key string
    -- @param val any
    function item:setProperty(key, val) _props[key] = val end

    --- Get a generic property.
    -- @param key string
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
-- @param inv_item table InvItem definition.
-- @param quantity number Initial count.
-- @param max_quantity number Maximum stack size (clamped to >= 1).
-- @treturn table ItemStack object.
function M.newItemStack(inv_item, quantity, max_quantity)
    local _item  = inv_item
    local _max   = math.max(1, max_quantity or inv_item:getStackLimit())
    local _qty   = math.min(quantity or 1, _max)

    local stack = {}

    --- Return the underlying InvItem.
    -- @treturn table
    function stack:getItem()        return _item end

    --- Return current quantity.
    -- @treturn number
    function stack:getQuantity()    return _qty end

    --- Directly set quantity (clamped 0..max).
    -- @param n number
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
    -- @param n number
    -- @treturn number overflow count
    function stack:add(n)
        local space = _max - _qty
        local added = math.min(n, space)
        _qty = _qty + added
        return n - added
    end

    --- Remove n items. Returns count actually removed.
    -- @param n number
    -- @treturn number
    function stack:remove(n)
        local taken = math.min(n, _qty)
        _qty = _qty - taken
        return taken
    end

    --- Split n items off into a new stack. Returns nil if n invalid.
    -- @param n number
    -- @treturn table|nil new ItemStack
    function stack:split(n)
        if n <= 0 or n > _qty then return nil end
        _qty = _qty - n
        return M.newItemStack(_item, n, _max)
    end

    --- Merge another stack into this one. Returns leftover count.
    -- @param other table ItemStack
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
-- @param slot_type string Filter type ("any" = accept all).
-- @param state string SlotState value.
-- @treturn table Slot object.
function M.newSlot(slot_type, state)
    local _type  = slot_type or "any"
    local _state = state or M.SlotState.Active
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
    -- @param s string SlotState constant
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
    -- @param item table InvItem
    -- @treturn boolean
    function slot:canAccept(item)
        if _type ~= "any" and _type ~= item:getType() and not item:hasTag(_type) then
            return false
        end
        return item:getSizeW() <= _cap_w and item:getSizeH() <= _cap_h
    end

    --- Place an ItemStack. Returns false if item not accepted.
    -- @param s table ItemStack
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
-- @param name string Container identifier.
-- @param mode string "fixed" | "unlimited" | "expandable"
-- @param slot_count number Initial number of slots (ignored for unlimited).
-- @treturn table Container object.
function M.newContainer(name, mode, slot_count)
    mode = mode or "unlimited"
    slot_count = slot_count or 0
    local _slots      = {}
    local _wt_limit   = 0.0   -- 0 = unlimited
    local _max_slots  = (mode == "fixed") and slot_count or 0

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

    --- Set weight limit. 0 = unlimited.
    -- @param w number
    function container:setWeightLimit(w) _wt_limit = w or 0.0 end

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
    -- @param idx number 1-based
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
    -- @param sl table Slot object
    function container:addSlot(sl)
        if mode == "fixed" and #_slots >= _max_slots then return end
        table.insert(_slots, sl)
    end

    --- Expand by n new empty slots (expandable mode only). Returns true if any added.
    -- @param n number
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

    --- Auto-place item quantity. Merges into existing stacks first, then fills empty slots.
    -- @param inv_item table InvItem
    -- @param quantity number
    -- @treturn boolean true if fully placed
    function container:addItem(inv_item, quantity)
        quantity = quantity or 1
        local remaining = quantity

        -- merge into existing stacks
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
                    return false
                end
            end
        end
        return true
    end

    --- Count all items of a given type across all slots.
    -- @param type_name string
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
    -- @param type_name string
    -- @param qty number
    -- @treturn boolean
    function container:hasItem(type_name, qty)
        return self:countItem(type_name) >= (qty or 1)
    end

    --- Remove up to qty items of type_name. Returns count removed.
    -- @param type_name string
    -- @param qty number
    -- @treturn number
    function container:removeItem(type_name, qty)
        qty = qty or 1
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
        return qty - remaining
    end

    --- Return all items with the given tag.
    -- @param tag string
    -- @treturn table Array of InvItem
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
    -- @param idx number 1-based slot index.
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
-- @param name string Display name.
-- @treturn table ItemSet object.
function M.newItemSet(name)
    local _reqs = {}  -- { tag, slot_filter } list

    local iset = {}

    --- Return the set name.
    -- @treturn string
    function iset:getName()             return name end

    --- Add a requirement: at least one equip slot must hold an item with `tag`.
    -- @param tag string Required tag.
    -- @param slot_filter string Check only this slot name, or "" for any.
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
    -- @param equip_slots table
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
    -- @param name string
    -- @param container table Container object
    function inv:addContainer(name, container)
        if not _containers[name] then table.insert(_cont_order, name) end
        _containers[name] = container
    end

    --- Get a container by name.
    -- @param name string
    -- @treturn table|nil
    function inv:getContainer(name)  return _containers[name] end

    --- Remove a container. Returns true if it existed.
    -- @param name string
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
    -- @param name string
    -- @param slot table Slot object
    function inv:addEquipSlot(name, slot)
        if not _equip_slots[name] then table.insert(_equip_order, name) end
        _equip_slots[name] = slot
    end

    --- Get an equip slot by name.
    -- @param name string
    -- @treturn table|nil
    function inv:getEquipSlot(name)  return _equip_slots[name] end

    --- Remove an equip slot. Returns true if it existed.
    -- @param name string
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
    -- @param slot_name string
    -- @param stack table ItemStack
    -- @treturn boolean
    function inv:equip(slot_name, stack)
        local sl = _equip_slots[slot_name]
        if not sl then return false end
        return sl:setStack(stack)
    end

    --- Unequip a slot and return its InvItem (not the full stack). Returns nil if empty.
    -- @param slot_name string
    -- @treturn table|nil InvItem
    function inv:unequip(slot_name)
        local sl = _equip_slots[slot_name]
        if not sl then return nil end
        local st = sl:takeStack()
        return st and st:getItem() or nil
    end

    -- ── Item Sets ────────────────────────────────────────────────────────────

    --- Register an item set.
    -- @param iset table ItemSet object
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
    -- @param name string
    function inv:enableSubsystem(name)
        if _subsystems[name] ~= nil then _subsystems[name] = true end
    end

    --- Disable a named subsystem.
    -- @param name string
    function inv:disableSubsystem(name)
        if _subsystems[name] ~= nil then _subsystems[name] = false end
    end

    --- Return true if the named subsystem is active.
    -- @param name string
    -- @treturn boolean
    function inv:isSubsystemEnabled(name) return _subsystems[name] == true end

    -- ── Cross-container queries ───────────────────────────────────────────────

    --- Count items of a type across ALL containers.
    -- @param type_name string
    -- @treturn number
    function inv:countItem(type_name)
        local total = 0
        for _, c in pairs(_containers) do
            total = total + c:countItem(type_name)
        end
        return total
    end

    --- Return true if total count >= qty across all containers.
    -- @param type_name string
    -- @param qty number
    -- @treturn boolean
    function inv:hasItem(type_name, qty)
        return self:countItem(type_name) >= (qty or 1)
    end

    --- Remove qty items of type_name from whichever containers have them.
    -- @param type_name string
    -- @param qty number
    -- @treturn boolean true if full amount removed
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
    -- @param from_name string Source container name.
    -- @param from_idx number Source slot index (1-based).
    -- @param to_name string Destination container name.
    -- @param to_idx number Destination slot index (1-based).
    -- @treturn boolean true on success
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
    -- @param container_name string Container name.
    -- @param slot_idx number 1-based slot index of the source stack.
    -- @param quantity number Number of items to split off.
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
    -- @param container_name string Container name.
    -- @param from_slot number 1-based source slot index.
    -- @param to_slot number 1-based destination slot index.
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
    -- @param container_a string First container name.
    -- @param slot_a number 1-based slot index in container_a.
    -- @param container_b string Second container name.
    -- @param slot_b number 1-based slot index in container_b.
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
