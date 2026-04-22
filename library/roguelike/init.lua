--- Lurek2D roguelike library — FOV, energy scheduler, and goal maps.
--
-- Pure-Lua runtime queries that turn `lurek.tilemap` into a roguelike:
--
--   * `Fov`       — symmetric recursive-shadowcasting field of view.
--   * `Scheduler` — discrete energy/speed turn scheduler (not Δt-based).
--   * `GoalMap`   — multi-source Dijkstra distance field with flee inversion.
--
-- All three subsystems are independent — pick what you need.
--
-- @module library.roguelike
-- @status full
-- @see lurek.tilemap          attach FOV/GoalMap blockers via `:attachTilemap`
-- @see lurek.pathfind      preferred Dijkstra backend; in-Lua fallback used otherwise
-- @see lurek.math.bresenham   line-of-sight helper (re-exported as `M.bresenham`)
-- @see lurek.save         scheduler/FOV state collectors

local M = {}

local table_unpack = table.unpack or unpack
local floor, abs   = math.floor, math.abs
local huge         = math.huge

-- ─── FOV (recursive shadowcasting) ──────────────────────────────────────────
--
-- Symmetric shadowcasting for square grids (Bjorn Bergstrom variant).
-- 8-octant recursive scan. See: http://www.roguebasin.com/index.php?title=FOV_using_recursive_shadowcasting

local Fov = {}
Fov.__index = Fov

local _OCT = {
    {  1,  0,  0,  1 }, {  0,  1,  1,  0 },
    {  0, -1,  1,  0 }, { -1,  0,  0,  1 },
    { -1,  0,  0, -1 }, {  0, -1, -1,  0 },
    {  0,  1, -1,  0 }, {  1,  0,  0, -1 },
}

--- Construct a new FOV instance.
-- @param opts table? `{algorithm, range=8, light_walls=true}`. `algorithm` is
--   informational; only "shadowcast" is implemented.
-- @treturn Fov
function M.newFov(opts)
    opts = opts or {}
    return setmetatable({
        _range       = opts.range or 8,
        _light_walls = opts.light_walls ~= false,
        _algorithm   = opts.algorithm or "shadowcast",
        _blocker     = nil,         -- (x,y) -> bool
        _visible     = {},          -- key(x,y) -> true
        _explored    = {},          -- key(x,y) -> true
        _origin_x    = 0,
        _origin_y    = 0,
    }, Fov)
end

local function _key(x, y) return x * 100000 + y end

--- Set a custom blocker function.
function Fov:setBlocker(fn)
    self._blocker = fn
    return self
end

--- Attach to a tilemap and treat the supplied tile ids as blockers on the
-- given layer. `tilemap` is queried via `tilemap:getTile(layer, x, y)` if the
-- method is present; otherwise via the table-indexed `tilemap[layer][y][x]`.
function Fov:attachTilemap(tilemap, layer, blocker_ids)
    layer = layer or 1
    blocker_ids = blocker_ids or { 1 }
    local ids = {}
    for _, v in ipairs(blocker_ids) do ids[v] = true end

    local has_method = type(tilemap) == "userdata"
        or (type(tilemap) == "table" and type(tilemap.getTile) == "function")

    self._blocker = function(x, y)
        local id
        if has_method then
            local ok, v = pcall(function() return tilemap:getTile(layer, x, y) end)
            id = ok and v or nil
        else
            local row = tilemap[layer] and tilemap[layer][y]
            id = row and row[x]
        end
        return id ~= nil and ids[id] == true
    end
    return self
end

local function _is_blocker(self, x, y)
    if not self._blocker then return false end
    return self._blocker(x, y) and true or false
end

local function _set_visible(self, x, y)
    local k = _key(x, y)
    self._visible[k]  = true
    self._explored[k] = true
end

local function _cast(self, row, start_slope, end_slope, xx, xy, yx, yy)
    if start_slope < end_slope then return end
    local r2 = self._range * self._range
    local new_start = start_slope
    for distance = row, self._range do
        local blocked = false
        local prev_blocked
        for delta = -distance, 0 do
            local dy = -distance
            local dx = delta
            local lx = self._origin_x + dx * xx + dy * xy
            local ly = self._origin_y + dx * yx + dy * yy
            local l_slope = (dx - 0.5) / (dy + 0.5)
            local r_slope = (dx + 0.5) / (dy - 0.5)
            if start_slope < r_slope then
                -- skip
            elseif end_slope > l_slope then
                break
            else
                if dx * dx + dy * dy <= r2 then
                    if self._light_walls or not _is_blocker(self, lx, ly) then
                        _set_visible(self, lx, ly)
                    end
                end
                if blocked then
                    if _is_blocker(self, lx, ly) then
                        new_start = r_slope
                    else
                        blocked = false
                        start_slope = new_start
                    end
                else
                    if _is_blocker(self, lx, ly) and distance < self._range then
                        blocked = true
                        _cast(self, distance + 1, start_slope, l_slope, xx, xy, yx, yy)
                        new_start = r_slope
                    end
                end
                prev_blocked = _is_blocker(self, lx, ly)
            end
        end
        if blocked then break end
        if prev_blocked == nil then
            -- nothing scanned this row; we're outside the cone
        end
    end
end

--- Recompute visibility from `(ox, oy)`.
function Fov:compute(ox, oy)
    self._visible = {}
    self._origin_x = ox
    self._origin_y = oy
    _set_visible(self, ox, oy)
    for _, oc in ipairs(_OCT) do
        _cast(self, 1, 1.0, 0.0, oc[1], oc[2], oc[3], oc[4])
    end
    return self
end

function Fov:isVisible(x, y)
    return self._visible[_key(x, y)] == true
end

function Fov:isExplored(x, y)
    return self._explored[_key(x, y)] == true
end

function Fov:resetExplored()
    self._explored = {}
    return self
end

function Fov:eachVisible(fn)
    for k in pairs(self._visible) do
        local x = floor(k / 100000)
        local y = k - x * 100000
        fn(x, y)
    end
    return self
end

function Fov:visibleCells()
    local out = {}
    for k in pairs(self._visible) do
        local x = floor(k / 100000)
        local y = k - x * 100000
        out[#out + 1] = { x = x, y = y }
    end
    return out
end

function Fov:export()
    local visible = {}
    for k in pairs(self._visible)  do visible[#visible + 1]  = k end
    local explored = {}
    for k in pairs(self._explored) do explored[#explored + 1] = k end
    return { range = self._range, origin = { self._origin_x, self._origin_y },
             visible = visible, explored = explored }
end

-- ─── Energy / action Scheduler ──────────────────────────────────────────────

local Scheduler = {}
Scheduler.__index = Scheduler

--- Create an action-cost (energy) scheduler.
-- Each actor has a `speed` value; on each `:next()` call the actor with the
-- highest accumulated energy goes. Internal clock advances by the minimum
-- ticks needed to bring at least one actor's energy >= 100.
-- @treturn Scheduler
function M.newScheduler()
    return setmetatable({
        _actors = {},   -- { actor=..., speed=..., energy=0 }
        _index  = {},   -- actor -> position
        _clock  = 0,
    }, Scheduler)
end

function Scheduler:add(actor, speed)
    if self._index[actor] then
        error("Scheduler:add: actor already present", 2)
    end
    if type(speed) ~= "number" or speed <= 0 then
        error("Scheduler:add: speed must be > 0", 2)
    end
    local rec = { actor = actor, speed = speed, energy = 0 }
    self._actors[#self._actors + 1] = rec
    self._index[actor] = #self._actors
    return self
end

function Scheduler:remove(actor)
    local pos = self._index[actor]
    if not pos then return self end
    table.remove(self._actors, pos)
    self._index = {}
    for i, rec in ipairs(self._actors) do self._index[rec.actor] = i end
    return self
end

function Scheduler:setSpeed(actor, speed)
    local pos = self._index[actor]
    if not pos then error("Scheduler:setSpeed: unknown actor", 2) end
    self._actors[pos].speed = speed
    return self
end

local function _advance(self)
    -- find smallest ticks needed for any actor to reach 100 energy
    local need = huge
    for _, r in ipairs(self._actors) do
        local deficit = 100 - r.energy
        if deficit > 0 then
            local t = deficit / r.speed
            if t < need then need = t end
        else
            need = 0; break
        end
    end
    if need == huge then need = 0 end
    for _, r in ipairs(self._actors) do
        r.energy = r.energy + r.speed * need
    end
    self._clock = self._clock + need
    return need
end

--- Pop the next-to-act actor. Returns the actor and ticks advanced this call.
function Scheduler:next()
    if #self._actors == 0 then
        error("Scheduler:next: no actors", 2)
    end
    local advanced = _advance(self)
    -- pick the actor with the highest energy (tie-break: insertion order)
    local best, best_idx
    for i, r in ipairs(self._actors) do
        if not best or r.energy > best.energy then
            best, best_idx = r, i
        end
    end
    best.energy = best.energy - 100
    return best.actor, advanced, best_idx
end

--- Peek at the next actor without consuming a turn.
function Scheduler:peek()
    if #self._actors == 0 then return nil, 0 end
    local need = huge
    local best
    for _, r in ipairs(self._actors) do
        local deficit = 100 - r.energy
        local t = (deficit > 0) and (deficit / r.speed) or 0
        if t < need then need = t; best = r end
    end
    return best and best.actor or nil, (need == huge) and 0 or need
end

--- Take `n` consecutive turns and return the actors in order.
function Scheduler:tick(n)
    n = n or 1
    local out = {}
    for _ = 1, n do
        if #self._actors == 0 then break end
        out[#out + 1] = self:next()
    end
    return out
end

function Scheduler:reset()
    self._clock = 0
    for _, r in ipairs(self._actors) do r.energy = 0 end
    return self
end

function Scheduler:save()
    local actors = {}
    for i, r in ipairs(self._actors) do
        actors[i] = { speed = r.speed, energy = r.energy }
    end
    return { clock = self._clock, actors = actors }
end

function Scheduler:restore(blob)
    if type(blob) ~= "table" then error("Scheduler:restore: blob required", 2) end
    self._clock = blob.clock or 0
    for i, r in ipairs(self._actors) do
        local saved = blob.actors and blob.actors[i]
        if saved then
            r.speed  = saved.speed  or r.speed
            r.energy = saved.energy or r.energy
        end
    end
    return self
end

-- ─── GoalMap (Dijkstra distance field) ──────────────────────────────────────

local GoalMap = {}
GoalMap.__index = GoalMap

--- Construct a goal map of the given grid dimensions.
function M.newGoalMap(width, height)
    if type(width) ~= "number" or type(height) ~= "number"
       or width <= 0 or height <= 0 then
        error("newGoalMap: width and height must be > 0", 2)
    end
    return setmetatable({
        _w        = floor(width),
        _h        = floor(height),
        _blocker  = function() return false end,
        _sources  = {},       -- {{x,y,weight}, ...}
        _dist     = nil,      -- 2D array dist[y][x] = number or nil
        _dirty    = true,
    }, GoalMap)
end

function GoalMap:setBlocker(fn) self._blocker = fn or function() return false end; return self end

function GoalMap:attachTilemap(tilemap, layer, blocker_ids)
    layer = layer or 1
    blocker_ids = blocker_ids or { 1 }
    local ids = {}
    for _, v in ipairs(blocker_ids) do ids[v] = true end
    local has_method = type(tilemap) == "userdata"
        or (type(tilemap) == "table" and type(tilemap.getTile) == "function")
    self._blocker = function(x, y)
        local id
        if has_method then
            local ok, v = pcall(function() return tilemap:getTile(layer, x, y) end)
            id = ok and v or nil
        else
            local row = tilemap[layer] and tilemap[layer][y]
            id = row and row[x]
        end
        return id ~= nil and ids[id] == true
    end
    return self
end

function GoalMap:setSources(positions)
    self._sources = {}
    for _, p in ipairs(positions) do
        self._sources[#self._sources + 1] = { x = p[1] or p.x, y = p[2] or p.y, w = p[3] or p.weight or 0 }
    end
    self._dirty = true
    return self
end

function GoalMap:addSource(x, y, w)
    self._sources[#self._sources + 1] = { x = x, y = y, w = w or 0 }
    self._dirty = true
    return self
end

function GoalMap:clearSources()
    self._sources = {}
    self._dirty = true
    return self
end

local function _bake_dijkstra(self)
    local w, h = self._w, self._h
    local dist = {}
    for y = 1, h do
        dist[y] = {}
        for x = 1, w do dist[y][x] = huge end
    end
    -- Naive multi-source BFS (4-neighbour). For typical roguelike grids this
    -- is fast enough; optimise later with a heap if needed.
    local frontier = {}
    for _, s in ipairs(self._sources) do
        if s.x >= 1 and s.x <= w and s.y >= 1 and s.y <= h then
            dist[s.y][s.x] = s.w
            frontier[#frontier + 1] = { s.x, s.y, s.w }
        end
    end
    local head = 1
    local DIRS = { {1,0}, {-1,0}, {0,1}, {0,-1} }
    while head <= #frontier do
        local cell = frontier[head]; head = head + 1
        local cx, cy, cd = cell[1], cell[2], cell[3]
        for _, d in ipairs(DIRS) do
            local nx, ny = cx + d[1], cy + d[2]
            if nx >= 1 and nx <= w and ny >= 1 and ny <= h
               and not self._blocker(nx, ny) then
                local nd = cd + 1
                if nd < dist[ny][nx] then
                    dist[ny][nx] = nd
                    frontier[#frontier + 1] = { nx, ny, nd }
                end
            end
        end
    end
    self._dist  = dist
    self._dirty = false
end

function GoalMap:bake()
    if #self._sources == 0 then
        error("GoalMap:bake: no sources set", 2)
    end
    -- Try lurek.pathfind façade first (P1 advertised but signature varies).
    local lp = lurek and lurek.pathfind
    if type(lp) == "table" and type(lp.dijkstra) == "function" then
        local ok, dist = pcall(function()
            return lp.dijkstra({
                width = self._w, height = self._h,
                sources = self._sources, blocker = self._blocker,
            })
        end)
        if ok and type(dist) == "table" then
            self._dist = dist
            self._dirty = false
            return self
        end
    end
    _bake_dijkstra(self)
    return self
end

local function _ensure(self)
    if self._dirty then self:bake() end
end

function GoalMap:distanceAt(x, y)
    _ensure(self)
    local row = self._dist[y]
    if not row then return huge end
    return row[x] or huge
end

local function _step_toward(self, x, y, sign)
    _ensure(self)
    local best_dx, best_dy = 0, 0
    local cur = self:distanceAt(x, y)
    if cur == huge then return 0, 0 end
    local target = cur
    for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        local nx, ny = x + d[1], y + d[2]
        local nd = self:distanceAt(nx, ny)
        local effective = sign * nd
        local current_eff = sign * target
        if nd ~= huge and effective < current_eff then
            target = nd
            best_dx, best_dy = d[1], d[2]
        end
    end
    return best_dx, best_dy
end

--- Unit step toward the nearest goal cell.
function GoalMap:gradientAt(x, y)
    return _step_toward(self, x, y, 1)
end

--- Unit step away from goals, scaled by `fear` (default 1.2).
function GoalMap:flee(x, y, fear)
    fear = fear or 1.2
    -- Invert the distance field locally and pick the steepest descent.
    _ensure(self)
    local cur = self:distanceAt(x, y)
    if cur == huge then return 0, 0 end
    local best_dx, best_dy = 0, 0
    local best_score = -huge
    for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        local nx, ny = x + d[1], y + d[2]
        local nd = self:distanceAt(nx, ny)
        if nd ~= huge then
            local score = nd * fear
            if score > best_score then
                best_score = score; best_dx = d[1]; best_dy = d[2]
            end
        end
    end
    return best_dx, best_dy
end

-- ─── Module-level helpers ───────────────────────────────────────────────────

--- Bresenham line of grid points from (x0,y0) to (x1,y1).
-- Falls back to a Lua implementation if `lurek.math.bresenham` is unavailable.
function M.bresenham(x0, y0, x1, y1)
    if lurek and lurek.math and type(lurek.math.bresenham) == "function" then
        local ok, res = pcall(lurek.math.bresenham, x0, y0, x1, y1)
        if ok and type(res) == "table" then return res end
    end
    local out = {}
    local dx = abs(x1 - x0); local sx = x0 < x1 and 1 or -1
    local dy = -abs(y1 - y0); local sy = y0 < y1 and 1 or -1
    local err = dx + dy
    local x, y = x0, y0
    while true do
        out[#out + 1] = { x = x, y = y }
        if x == x1 and y == y1 then break end
        local e2 = 2 * err
        if e2 >= dy then err = err + dy; x = x + sx end
        if e2 <= dx then err = err + dx; y = y + sy end
    end
    return out
end

--- True if `fov` reports an unbroken line from (x0,y0) to (x1,y1) is visible.
function M.lineOfSight(fov, x0, y0, x1, y1)
    local pts = M.bresenham(x0, y0, x1, y1)
    for _, p in ipairs(pts) do
        if not fov:isVisible(p.x, p.y) then return false end
    end
    return true
end

M.Fov       = Fov
M.Scheduler = Scheduler
M.GoalMap   = GoalMap
M._unpack   = table_unpack

return M
