--- Luna2D inventory system — containers, weighted bags, and slots.
--
-- A pure-Lua replacement for the former `luna.inventory` Rust binding.
-- Provides lightweight inventory containers that hold InvItem objects,
-- support weight limits, and expose named slot views.
--
-- Usage:
--   local inventory = require("library.inventory")
--   local bag = inventory.newContainer("bag", "dynamic", 30)
--   bag:setWeightLimit(20.0)
--   local inv_item = inventory.newItem("sword")
--   inv_item:setWeight(3.5)
--   bag:addItem(inv_item)
--
-- @module library.inventory

local M = {}

-- ─── InvItem ──────────────────────────────────────────────────────────────────

--- Create a lightweight inventory item wrapper.
-- InvItem carries a type name and weight; it is distinct from a full Item object.
-- @param type_name string Item type name.
-- @treturn table InvItem object.
function M.newItem(type_name)
    local weight = 0.0

    local inv_item = {}

    --- Return the type name.
    -- @treturn string
    function inv_item:getType()
        return type_name
    end

    --- Set the physical weight of this item.
    -- @param w number Weight in units.
    function inv_item:setWeight(w)
        weight = w or 0.0
    end

    --- Return the weight.
    -- @treturn number
    function inv_item:getWeight()
        return weight
    end

    return inv_item
end

-- ─── Slot ─────────────────────────────────────────────────────────────────────

--- Create a standalone named slot that can hold one item.
-- Standalone slots are independent of containers; useful for equipment tracking.
-- @param name string Slot identifier.
-- @param slot_type string Slot category (e.g. "weapon", "armor", "active").
-- @treturn table Slot object.
function M.newSlot(name, slot_type)
    local _item  = nil

    local slot = {}

    --- Return the slot name.
    -- @treturn string
    function slot:getName()
        return name
    end

    --- Return the slot type.
    -- @treturn string
    function slot:getSlotType()
        return slot_type
    end

    --- Set the item held in this slot.
    -- @param item table InvItem object, or nil to clear.
    function slot:setItem(item)
        _item = item
    end

    --- Return the held item, or nil if empty.
    -- @treturn table|nil
    function slot:getItem()
        return _item
    end

    --- Return true if this slot is empty.
    -- @treturn boolean
    function slot:isEmpty()
        return _item == nil
    end

    return slot
end

-- ─── Container slot (internal) ───────────────────────────────────────────────

--- @local
-- Wrap a single InvItem as a container-slot view compatible with :getSlots().
local function make_container_slot(inv_item)
    local slot = {}

    function slot:isEmpty()
        return inv_item == nil
    end

    -- Container slots expose a micro-stack with a single :getItem() method.
    function slot:getStack()
        if inv_item == nil then return nil end
        local micro = {}
        function micro:getItem()
            return inv_item
        end
        function micro:size()
            return 1
        end
        return micro
    end

    function slot:getInvItem()
        return inv_item
    end

    return slot
end

-- ─── Container ────────────────────────────────────────────────────────────────

--- Create a named container that holds InvItem objects.
-- @param name string Container identifier.
-- @param container_type string Layout type: "dynamic" (unlimited slots), or a fixed count.
-- @param capacity number Maximum number of item slots. 0 = unlimited.
-- @treturn table Container object.
function M.newContainer(name, container_type, capacity)
    local _items        = {}   -- array of InvItem
    local _weight_limit = math.huge
    local _total_weight = 0.0
    capacity = capacity or 0

    local container = {}

    --- Set the maximum total weight this container can carry.
    -- @param w number Weight limit. 0 = unlimited.
    function container:setWeightLimit(w)
        _weight_limit = (w and w > 0) and w or math.huge
    end

    --- Return the current combined weight of all items.
    -- @treturn number
    function container:getCurrentWeight()
        return _total_weight
    end

    --- Return the weight limit.
    -- @treturn number math.huge if unlimited.
    function container:getWeightLimit()
        return _weight_limit
    end

    --- Add an InvItem to this container.
    -- Raises if the capacity or weight limit would be exceeded.
    -- @param inv_item table InvItem object.
    function container:addItem(inv_item)
        if capacity > 0 and #_items >= capacity then
            error("container '"..name.."' is full ("..capacity.." slots)")
        end
        local w = inv_item:getWeight()
        if _total_weight + w > _weight_limit then
            error("container '"..name.."' weight limit exceeded")
        end
        table.insert(_items, inv_item)
        _total_weight = _total_weight + w
    end

    --- Return all slots as an array of container-slot objects.
    -- Each slot exposes :isEmpty(), :getStack(), :getInvItem().
    -- @treturn table Array of slot objects.
    function container:getSlots()
        local slots = {}
        for _, it in ipairs(_items) do
            table.insert(slots, make_container_slot(it))
        end
        return slots
    end

    --- Return true if at least one item of the given type exists.
    -- @param type_name string Type name to search for.
    -- @treturn boolean
    function container:hasItem(type_name)
        for _, it in ipairs(_items) do
            if it:getType() == type_name then return true end
        end
        return false
    end

    --- Remove up to `count` items of the given type. Returns number removed.
    -- @param type_name string Type name to remove.
    -- @param count number Maximum items to remove.
    -- @treturn number Actual number removed.
    function container:removeItem(type_name, count)
        count = count or 1
        local removed = 0
        local i = 1
        while i <= #_items and removed < count do
            if _items[i]:getType() == type_name then
                _total_weight = _total_weight - _items[i]:getWeight()
                table.remove(_items, i)
                removed = removed + 1
            else
                i = i + 1
            end
        end
        return removed
    end

    --- Return the number of items currently held.
    -- @treturn number
    function container:count()
        return #_items
    end

    return container
end

-- ─── Inventory ────────────────────────────────────────────────────────────────

--- Create a named inventory that can hold multiple named containers.
-- @treturn table Inventory object.
function M.newInventory()
    local _containers = {}

    local inv = {}

    --- Register a container under a name.
    -- @param name string Key for this container.
    -- @param container table Container object.
    function inv:addContainer(name, container)
        _containers[name] = container
    end

    --- Retrieve a registered container by name.
    -- @param name string Key.
    -- @treturn table|nil Container, or nil if not found.
    function inv:getContainer(name)
        return _containers[name]
    end

    --- Return a list of all container names.
    -- @treturn table Array of strings.
    function inv:containerNames()
        local result = {}
        for k in pairs(_containers) do
            table.insert(result, k)
        end
        return result
    end

    return inv
end

return M
