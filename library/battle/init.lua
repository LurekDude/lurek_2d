--- Luna2D battle system — turn-based battles, combatants, and actions.
--
-- Stub module. Full implementation pending.
-- Replaces the former `luna.battle` Rust binding.
--
-- @module library.battle
-- @status stub

local M = {}

--- Create a new battle instance.
-- @param opts table { combatants={}, turn_order="speed" }
-- @treturn table Battle object.
function M.newBattle(opts)
    error("library.battle: not yet implemented — stub only")
end

--- Create a new combatant definition.
-- @param id string Unique combatant identifier.
-- @param def table { name, stats={hp, speed, atk, def} }
-- @treturn table Combatant definition.
function M.newCombatant(id, def)
    error("library.battle: not yet implemented — stub only")
end

return M
