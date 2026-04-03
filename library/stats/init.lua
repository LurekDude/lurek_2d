--- Luna2D stats system — character attributes, derived stats, and modifiers.
--
-- Stub module. Full implementation pending.
-- Replaces the former `luna.stats` Rust binding.
--
-- @module library.stats
-- @status stub

local M = {}

--- Create a new stat sheet for a character or entity.
-- @param base table Base attribute values: { str=10, dex=10, ... }
-- @treturn table StatSheet object.
function M.newSheet(base)
    error("library.stats: not yet implemented — stub only")
end

--- Create a flat modifier that adds or multiplies a stat.
-- @param stat string Stat name.
-- @param mode string "add" or "mul".
-- @param value number Modifier value.
-- @treturn table Modifier object.
function M.newModifier(stat, mode, value)
    error("library.stats: not yet implemented — stub only")
end

return M
