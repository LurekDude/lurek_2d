--- Lurek2D loot library — designer-friendly weighted RNG, drop DSL, and pity timers.
--
-- A pure-Lua loot table system built on `lurek.math.RandomGenerator`. Provides:
--
--   * `LootTable` — Walker–Vose alias-method weighted RNG with O(1) sampling.
--   * `DropSet`   — composable, conditional, multi-roll drop DSL.
--   * `Pity`      — guaranteed-after-N-misses helper for streak protection.
--   * `Modifier`  — luck/level/zone weight multipliers applied as a temporary view.
--
-- Usage:
--   local loot = require("library.loot")
--   local tbl  = loot.fromList({
--       {id="gold", weight=60},
--       {id="ring", weight=10, meta={tier="rare"}},
--   })
--   local id, meta = tbl:sample()
--
-- @module library.loot
-- @status full
-- @see lurek.math.newRandomGenerator   default RNG source for sampling
-- @see lurek.serial.fromToml             designer-authored loot tables (`fromToml`)
-- @see lurek.filesystem.read                    sandboxed file load for `fromToml`
-- @see lurek.save                   `Pity:save`/`restore` collector wiring

local M = {}

local table_unpack = table.unpack or unpack
local floor        = math.floor

-- ─── Module RNG (resolved lazily; falls back to math.random on hostile envs) ───

local _default_rng

local function _get_default_rng()
    if _default_rng then return _default_rng end
    if type(lurek) == "table" and type(lurek.math) == "table"
       and type(lurek.math.newRandomGenerator) == "function" then
        local ok, rng = pcall(lurek.math.newRandomGenerator)
        if ok and rng then _default_rng = rng end
    end
    if not _default_rng then
        -- Fallback shim with the same `:random()` contract.
        _default_rng = { random = function(_) return math.random() end }
    end
    return _default_rng
end

--- Install a custom default RNG used by `LootTable:sample` when no rng arg is passed.
-- @param rng userdata|table A `RandomGenerator` or any object implementing `:random()` → [0,1).
function M.setDefaultRng(rng)
    _default_rng = rng
end

--- Get the module's current default RNG (resolves on first use).
-- @treturn userdata|table The RNG instance.
function M.getDefaultRng()
    return _get_default_rng()
end

local function _rng_uniform(rng)
    rng = rng or _get_default_rng()
    if type(rng.random) == "function" then return rng:random() end
    return math.random()
end

-- ─── LootTable ────────────────────────────────────────────────────────────────

local LootTable = {}
LootTable.__index = LootTable

local function _build_alias(weights)
    -- Walker–Vose alias method. Returns (prob[], alias[]).
    local n = #weights
    if n == 0 then return {}, {} end
    local total = 0
    for i = 1, n do total = total + weights[i] end
    if total <= 0 then
        error("loot: total weight must be > 0", 3)
    end
    local prob, alias = {}, {}
    local scaled = {}
    for i = 1, n do scaled[i] = weights[i] * n / total end
    local small, large = {}, {}
    for i = 1, n do
        if scaled[i] < 1.0 then small[#small + 1] = i
        else                    large[#large + 1] = i end
    end
    while #small > 0 and #large > 0 do
        local s = small[#small]; small[#small] = nil
        local l = large[#large]; large[#large] = nil
        prob[s]  = scaled[s]
        alias[s] = l
        scaled[l] = scaled[l] + scaled[s] - 1.0
        if scaled[l] < 1.0 then small[#small + 1] = l
        else                    large[#large + 1] = l end
    end
    while #large > 0 do
        local l = large[#large]; large[#large] = nil
        prob[l] = 1.0; alias[l] = l
    end
    while #small > 0 do
        local s = small[#small]; small[#small] = nil
        prob[s] = 1.0; alias[s] = s
    end
    return prob, alias
end

--- Create an empty weighted loot table.
-- @treturn LootTable
function M.newTable()
    local t = setmetatable({
        _ids     = {},
        _weights = {},
        _meta    = {},
        _index   = {},  -- id -> position
        _dirty   = true,
        _prob    = nil,
        _alias   = nil,
    }, LootTable)
    return t
end

--- Bulk-build a loot table from a list of `{id, weight, meta?}` entries.
-- @param entries table Array of `{id=string, weight=number, meta=table?}`.
-- @treturn LootTable
function M.fromList(entries)
    local t = M.newTable()
    for _, e in ipairs(entries) do
        t:add(e.id, e.weight, e.meta)
    end
    return t
end

--- Load a loot table from a TOML file via `lurek.filesystem.read` + `lurek.serial.fromToml`.
-- The file must contain an `entries = [...]` array.
-- @param path string Sandboxed game-path to a TOML file.
-- @treturn LootTable
-- @raise descriptive error on missing engine bindings or malformed file.
function M.fromToml(path)
    if type(lurek) ~= "table" or type(lurek.filesystem) ~= "table"
       or type(lurek.filesystem.read) ~= "function" then
        error("loot.fromToml: lurek.filesystem.read unavailable", 2)
    end
    if type(lurek.serial) ~= "table" or type(lurek.serial.fromToml) ~= "function" then
        error("loot.fromToml: lurek.serial.fromToml unavailable", 2)
    end
    local ok_read, src = pcall(lurek.filesystem.read, path)
    if not ok_read then error("loot.fromToml: read failed: " .. tostring(src), 2) end
    local ok_parse, data = pcall(lurek.serial.fromToml, src)
    if not ok_parse then error("loot.fromToml: parse failed: " .. tostring(data), 2) end
    if type(data) ~= "table" or type(data.entries) ~= "table" then
        error("loot.fromToml: expected top-level 'entries' array", 2)
    end
    return M.fromList(data.entries)
end

--- Combine multiple LootTables into a single new one. Identical IDs sum weights.
-- @param ... LootTable Two or more tables.
-- @treturn LootTable
function M.merge(...)
    local out = M.newTable()
    local sets = {...}
    for _, t in ipairs(sets) do
        for i, id in ipairs(t._ids) do
            local w = t._weights[i]
            local existing = out._index[id]
            if existing then
                out._weights[existing] = out._weights[existing] + w
                out._dirty = true
            else
                out:add(id, w, t._meta[i])
            end
        end
    end
    return out
end

--- Add or accumulate an entry. Triggers alias rebuild on next sample.
-- @param id string Unique entry identifier.
-- @param weight number Positive weight.
-- @param meta table? Opaque user data returned alongside `id` from `:sample`.
-- @treturn LootTable self for chaining.
function LootTable:add(id, weight, meta)
    if type(id) ~= "string" then error("LootTable:add: id must be a string", 2) end
    if type(weight) ~= "number" or weight <= 0 then
        error("LootTable:add: weight must be a positive number", 2)
    end
    local existing = self._index[id]
    if existing then
        self._weights[existing] = self._weights[existing] + weight
        if meta ~= nil then self._meta[existing] = meta end
    else
        local n = #self._ids + 1
        self._ids[n]     = id
        self._weights[n] = weight
        self._meta[n]    = meta
        self._index[id]  = n
    end
    self._dirty = true
    return self
end

--- Remove an entry by id.
-- @param id string Entry identifier.
-- @treturn boolean true if removed.
function LootTable:remove(id)
    local pos = self._index[id]
    if not pos then return false end
    table.remove(self._ids, pos)
    table.remove(self._weights, pos)
    table.remove(self._meta, pos)
    self._index = {}
    for i, v in ipairs(self._ids) do self._index[v] = i end
    self._dirty = true
    return true
end

--- Adjust an entry's weight (rebuilds alias on next sample).
-- @param id string
-- @param w number new positive weight.
-- @treturn LootTable self
function LootTable:setWeight(id, w)
    local pos = self._index[id]
    if not pos then error("LootTable:setWeight: unknown id '"..tostring(id).."'", 2) end
    if type(w) ~= "number" or w <= 0 then
        error("LootTable:setWeight: weight must be > 0", 2)
    end
    self._weights[pos] = w
    self._dirty = true
    return self
end

--- O(1) sample one entry from the alias table.
-- @param rng userdata|table? Optional `RandomGenerator` (defaults to module RNG).
-- @treturn string id
-- @treturn table? meta (may be nil)
function LootTable:sample(rng)
    local n = #self._ids
    if n == 0 then error("LootTable:sample: table is empty", 2) end
    if self._dirty then
        self._prob, self._alias = _build_alias(self._weights)
        self._dirty = false
    end
    local u = _rng_uniform(rng) * n
    local i = floor(u) + 1
    if i > n then i = n end
    local frac = u - floor(u)
    local choice = (frac < self._prob[i]) and i or self._alias[i]
    return self._ids[choice], self._meta[choice]
end

--- Bulk draw N samples.
-- @param n integer Number of draws (must be >= 0).
-- @param rng userdata|table?
-- @param opts table? `{unique=true}` for sampling without replacement.
-- @treturn table Array of ids (length n).
-- @raise on `unique=true` when n exceeds the entry count.
function LootTable:sampleN(n, rng, opts)
    if type(n) ~= "number" or n < 0 then
        error("LootTable:sampleN: n must be >= 0", 2)
    end
    n = floor(n)
    opts = opts or {}
    local out = {}
    if opts.unique then
        if n > #self._ids then
            error("LootTable:sampleN: unique=true but n > entries", 2)
        end
        local pool = M.newTable()
        for i, id in ipairs(self._ids) do
            pool:add(id, self._weights[i], self._meta[i])
        end
        for _ = 1, n do
            local id = pool:sample(rng)
            out[#out + 1] = id
            pool:remove(id)
        end
    else
        for _ = 1, n do
            out[#out + 1] = self:sample(rng)
        end
    end
    return out
end

--- Current weight of an entry.
-- @param id string
-- @treturn number Weight, or 0 if unknown.
function LootTable:weightOf(id)
    local p = self._index[id]
    return p and self._weights[p] or 0
end

--- Total weight of all entries.
-- @treturn number
function LootTable:totalWeight()
    local s = 0
    for i = 1, #self._weights do s = s + self._weights[i] end
    return s
end

--- Normalised probability of an entry (0..1).
-- @param id string
-- @treturn number
function LootTable:probability(id)
    local total = self:totalWeight()
    if total <= 0 then return 0 end
    return self:weightOf(id) / total
end

--- Snapshot of all entry ids.
-- @treturn table Array of ids.
function LootTable:ids()
    local out = {}
    for i, v in ipairs(self._ids) do out[i] = v end
    return out
end

--- Deep-copy this table.
-- @treturn LootTable
function LootTable:clone()
    local c = M.newTable()
    for i, id in ipairs(self._ids) do
        local m = self._meta[i]
        local mcopy = nil
        if type(m) == "table" then
            mcopy = {}
            for k, v in pairs(m) do mcopy[k] = v end
        else
            mcopy = m
        end
        c:add(id, self._weights[i], mcopy)
    end
    return c
end

-- ─── DropSet ──────────────────────────────────────────────────────────────────

local DropSet = {}
DropSet.__index = DropSet

--- Create a composable drop description.
-- @treturn DropSet
function M.newDrop()
    return setmetatable({
        _clauses = {},   -- ordered list of clause records
        _gates   = {},   -- stack of pending predicates wrapping subsequent clauses
    }, DropSet)
end

local function _push_clause(self, clause)
    -- Attach current gate predicates to the clause.
    if #self._gates > 0 then
        local gates = {}
        for i, g in ipairs(self._gates) do gates[i] = g end
        clause.gates = gates
    end
    self._clauses[#self._clauses + 1] = clause
end

--- Roll a loot table N times.
-- @param tbl LootTable
-- @param opts table? `{count=1, chance=1.0, tag=nil}`.
-- @treturn DropSet self
function DropSet:roll(tbl, opts)
    opts = opts or {}
    _push_clause(self, {
        kind   = "roll",
        tbl    = tbl,
        count  = opts.count  or 1,
        chance = opts.chance or 1.0,
        tag    = opts.tag,
    })
    return self
end

--- Always emit `id × count`.
-- @param id string
-- @param count integer? defaults 1.
-- @treturn DropSet self
function DropSet:guarantee(id, count)
    _push_clause(self, { kind = "guarantee", id = id, count = count or 1 })
    return self
end

--- Gate the next clauses on a predicate `fn(context) -> bool`.
-- The gate persists for all subsequent `:roll`/`:guarantee` calls in the chain.
-- @param fn function(context) -> bool
-- @treturn DropSet self
function DropSet:when(fn)
    self._gates[#self._gates + 1] = fn
    return self
end

--- Execute all clauses against `context` and return the resolved drop list.
-- @param context table Arbitrary context passed to gate predicates.
-- @param rng userdata|table?
-- @treturn table List of `{id=string, count=integer, meta=table?}`.
function DropSet:resolve(context, rng)
    rng = rng or _get_default_rng()
    local out = {}
    for _, c in ipairs(self._clauses) do
        local pass = true
        if c.gates then
            for _, g in ipairs(c.gates) do
                if not g(context) then pass = false; break end
            end
        end
        if pass then
            if c.kind == "guarantee" then
                out[#out + 1] = { id = c.id, count = c.count }
            elseif c.kind == "roll" then
                if _rng_uniform(rng) <= c.chance then
                    for _ = 1, c.count do
                        local id, meta = c.tbl:sample(rng)
                        out[#out + 1] = { id = id, count = 1, meta = meta, tag = c.tag }
                    end
                end
            end
        end
    end
    return out
end

--- Human-readable explanation of which clauses would fire.
-- @param context table
-- @treturn string
function DropSet:explain(context)
    local lines = {}
    for i, c in ipairs(self._clauses) do
        local pass = true
        if c.gates then
            for _, g in ipairs(c.gates) do
                if not g(context) then pass = false; break end
            end
        end
        local marker = pass and "[on]" or "[off]"
        if c.kind == "guarantee" then
            lines[#lines + 1] = string.format("%s %d. guarantee %s ×%d", marker, i, c.id, c.count)
        else
            lines[#lines + 1] = string.format("%s %d. roll table (count=%d, chance=%.2f)",
                marker, i, c.count, c.chance)
        end
    end
    return table.concat(lines, "\n")
end

-- ─── Pity ─────────────────────────────────────────────────────────────────────

local Pity = {}
Pity.__index = Pity

--- Guarantee `target_id` is forced after `threshold` consecutive misses.
-- @param target_id string Id whose appearance resets the counter.
-- @param threshold integer Misses before pity fires (must be >= 1).
-- @treturn Pity
function M.newPity(target_id, threshold)
    if type(target_id) ~= "string" then error("newPity: id must be a string", 2) end
    if type(threshold) ~= "number" or threshold < 1 then
        error("newPity: threshold must be >= 1", 2)
    end
    return setmetatable({
        _target    = target_id,
        _threshold = floor(threshold),
        _counter   = 0,
        _primed    = false,
    }, Pity)
end

--- Notice a draw result. Returns true when pity is now primed and should
-- force `target_id` on the next draw.
-- @param result_id string The id that just dropped.
-- @treturn boolean primed
function Pity:notice(result_id)
    if result_id == self._target then
        self._counter = 0
        self._primed  = false
    else
        self._counter = self._counter + 1
        if self._counter >= self._threshold then
            self._primed = true
        end
    end
    return self._primed
end

--- Reset the pity counter to 0.
function Pity:reset()
    self._counter = 0
    self._primed  = false
    return self
end

--- Current miss counter.
-- @treturn integer
function Pity:getCounter() return self._counter end

--- True when pity will fire on the next draw.
-- @treturn boolean
function Pity:isPrimed() return self._primed end

--- Serialise to a save blob.
-- @treturn table
function Pity:save()
    return {
        target    = self._target,
        threshold = self._threshold,
        counter   = self._counter,
        primed    = self._primed,
    }
end

--- Restore from a save blob.
-- @param blob table Output of `Pity:save`.
-- @treturn Pity self
function Pity:restore(blob)
    if type(blob) ~= "table" then error("Pity:restore: blob must be a table", 2) end
    self._target    = blob.target    or self._target
    self._threshold = blob.threshold or self._threshold
    self._counter   = blob.counter   or 0
    self._primed    = blob.primed    or false
    return self
end

-- ─── Modifier ────────────────────────────────────────────────────────────────

local Modifier = {}
Modifier.__index = Modifier

--- Stack of named weight multipliers applied to a LootTable view.
-- @treturn Modifier
function M.newModifier()
    return setmetatable({ _fns = {} }, Modifier)
end

--- Add a multiplier function.
-- @param name string label.
-- @param fn function `(entry, context) -> multiplier`.
-- @treturn Modifier self
function Modifier:add(name, fn)
    self._fns[#self._fns + 1] = { name = name, fn = fn }
    return self
end

--- Produce a temporary LootTable with adjusted weights. Original is untouched.
-- @param tbl LootTable
-- @param context table Passed to each multiplier.
-- @treturn LootTable
function Modifier:apply(tbl, context)
    local out = M.newTable()
    for i, id in ipairs(tbl._ids) do
        local entry = { id = id, weight = tbl._weights[i], meta = tbl._meta[i] }
        local w = entry.weight
        for _, m in ipairs(self._fns) do
            w = w * (m.fn(entry, context) or 1.0)
        end
        if w > 0 then
            out:add(id, w, tbl._meta[i])
        end
    end
    return out
end

-- ─── Re-exports ──────────────────────────────────────────────────────────────

M.LootTable = LootTable
M.DropSet   = DropSet
M.Pity      = Pity
M.Modifier  = Modifier
M._unpack   = table_unpack  -- exposed for harness compat

return M
