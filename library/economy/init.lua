--- Luna2D economy system — resource flow, capacity, decay, and conversions.
--
-- Stub module. Full implementation pending.
-- Replaces the former `luna.economy` Rust binding.
--
-- @module library.economy
-- @status stub

local M = {}

--- Create a new economy world to manage named resource pools.
-- @treturn table EconomyWorld object.
function M.newWorld()
    error("library.economy: not yet implemented — stub only")
end

--- Create a named resource pool.
-- @param name string Resource name.
-- @param opts table { capacity, initial, decay_rate, interest_rate }
-- @treturn table Resource object.
function M.newResource(name, opts)
    error("library.economy: not yet implemented — stub only")
end

return M
