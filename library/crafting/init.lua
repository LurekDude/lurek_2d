--- Luna2D crafting system — recipes, ingredient matching, and queues.
--
-- Stub module. Full implementation pending.
-- Replaces the former `luna.crafting` Rust binding.
--
-- @module library.crafting
-- @status stub

local M = {}

--- Create a new crafting table that holds registered recipes.
-- @treturn table CraftingTable object.
function M.newTable()
    error("library.crafting: not yet implemented — stub only")
end

--- Create a recipe definition.
-- @param id string Unique recipe identifier.
-- @param def table { inputs={}, output={}, time=1.0 }
-- @treturn table Recipe definition.
function M.newRecipe(id, def)
    error("library.crafting: not yet implemented — stub only")
end

return M
