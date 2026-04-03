--- Luna2D province map — Voronoi province generation and map modes.
--
-- Thin proxy around `luna.province` (the engine's GPU-accelerated province
-- rendering module).  All compute-heavy operations (Voronoi generation,
-- pixel adjacency scanning, border tracing) remain in the engine.
-- This module exposes a stable `require("library.province_map")` namespace
-- and can layer pure-Lua domain logic on top.
--
-- Usage:
--   local province_map = require("library.province_map")
--   local map  = province_map.generate({ width=200, height=150, provinces=40, seed=7 })
--   local data = province_map.newData()
--   data:setProperty(pid, "terrain", "forest")
--
-- @module library.province_map

local M = {}

local _prov = luna.province   -- engine binding (stays in Rust)

-- ─── Generation ───────────────────────────────────────────────────────────────

--- Generate a new province map.
-- @param opts table { width, height, provinces, seed }
-- @treturn table ProvinceMap handle.
function M.generate(opts)
    return _prov.generate(opts)
end

-- ─── Property data ────────────────────────────────────────────────────────────

--- Create a new property data store for attaching per-province values.
-- @treturn table ProvinceData handle.
function M.newData()
    return _prov.newData()
end

-- ─── Pass-through helpers ─────────────────────────────────────────────────────

--- Expose the underlying engine province module for direct access if needed.
-- @treturn table luna.province table.
function M.engine()
    return _prov
end

return M
