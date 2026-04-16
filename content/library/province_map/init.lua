--- @module library.province_map
--- Province-map data model: provinces, adjacency edges, definitions,
--- borders, event bus, map modes, positions, routing, and faction helpers.
--- Pure-Lua port and extension of src/province_map/.
--- @status full

local M = {}

-- ── Province ──────────────────────────────────────────────────────────────

local Province = {}
Province.__index = Province

--- Create a new province.
-- @param id     number  Unique province ID (from RGB colour).
-- @param color  table   {r, g, b} colour table.
-- @treturn Province
function M.newProvince(id, color)
    return setmetatable({
        id             = id,
        color          = color or {0, 0, 0},
        area           = 0,
        centroid       = {x = 0, y = 0},
        bounding_box   = {x = 0, y = 0, w = 0, h = 0},
        center         = {x = 0, y = 0},
        name           = nil,
        faction        = nil,
        defense_rating = 0,
        buildings      = {},
        resources      = {},
    }, Province)
end

--- Set the faction that controls this province.
-- @param f string|nil
function Province:setFaction(f)   self.faction = f          end
--- Get the controlling faction.
-- @treturn string|nil
function Province:getFaction()    return self.faction        end

--- Set the defense rating (0–100).
-- @param v number
function Province:setDefenseRating(v) self.defense_rating = v end
--- Get the defense rating.
-- @treturn number
function Province:getDefenseRating()  return self.defense_rating end

--- Add a building to this province.
-- @param building string
function Province:addBuilding(b)
    self.buildings[#self.buildings+1] = b
end
--- Get all buildings.
-- @treturn table
function Province:getBuildings()
    local out = {}
    for _, b in ipairs(self.buildings) do out[#out+1] = b end
    return out
end
--- Return true if the province has the given building.
-- @param b string
-- @treturn boolean
function Province:hasBuilding(b)
    for _, x in ipairs(self.buildings) do if x == b then return true end end
    return false
end
--- Remove a building by name. Returns true if removed.
-- @param b string
-- @treturn boolean
function Province:removeBuilding(b)
    for i, x in ipairs(self.buildings) do
        if x == b then table.remove(self.buildings, i); return true end
    end
    return false
end

--- Set a produced resource amount.
-- @param res    string
-- @param amount number
function Province:setResource(res, amount) self.resources[res] = amount end
--- Get a produced resource amount (0 if not set).
-- @param res string
-- @treturn number
function Province:getResource(res) return self.resources[res] or 0 end
--- Get the full resource table.
-- @treturn table
function Province:getResources()
    local out = {}
    for k, v in pairs(self.resources) do out[k] = v end
    return out
end

-- ── AdjacencyEdge ─────────────────────────────────────────────────────────

--- Create a new adjacency edge between two provinces.
-- @param province_a number
-- @param province_b number
-- @treturn table
function M.newAdjacencyEdge(province_a, province_b)
    local a, b = province_a, province_b
    if a > b then a, b = b, a end
    return {
        province_a      = a,
        province_b      = b,
        border_length   = 0,
        border_segments = {},
        tags            = {},
        passable        = true,
        movement_cost   = 1.0,
    }
end

--- Add a tag to an adjacency edge.
-- @param edge table
-- @param tag  string
function M.addEdgeTag(edge, tag) edge.tags[tag] = true end
--- Remove a tag from an adjacency edge.
-- @param edge table
-- @param tag  string
function M.removeEdgeTag(edge, tag) edge.tags[tag] = nil end
--- Check if an adjacency edge has a tag.
-- @param edge table
-- @param tag  string
-- @treturn boolean
function M.hasEdgeTag(edge, tag) return edge.tags[tag] == true end

-- ── ProvinceDefinition ────────────────────────────────────────────────────

--- Create a province definition (lightweight descriptor for map building).
-- @param id     number
-- @param color  table
-- @param center table  {x, y}
-- @treturn table
function M.newProvinceDefinition(id, color, center)
    return {
        id        = id,
        color     = color or {0, 0, 0},
        center    = center or {x = 0, y = 0},
        neighbors = {},
        name      = nil,
        faction   = nil,
    }
end

-- ── BorderSegment ─────────────────────────────────────────────────────────

--- Create a border segment between two provinces.
-- @param province_a number
-- @param province_b number
-- @treturn table
function M.newBorderSegment(province_a, province_b)
    return {
        province_a = province_a,
        province_b = province_b,
        points     = {},
        tags       = {},
    }
end

-- ── BorderStyle ───────────────────────────────────────────────────────────

--- Create a border style descriptor.
-- @treturn table
function M.newBorderStyle()
    return {
        width  = 1.0,
        color  = {0, 0, 0, 1},
        dashed = false,
    }
end

-- ── MapModeColorFn ────────────────────────────────────────────────────────

--- Sentinel table for built-in map mode colour functions.
-- Use M.MapModeColorFn.SourceColor to derive province colours from their
-- source-image RGB values (the default rendering mode).
M.MapModeColorFn = {
    SourceColor = 'source_color',
}

--- Create a fixed colour map mode (each province has a fixed colour).
-- @param province_colors table  {[id] = {r, g, b}}
-- @treturn table
function M.newFixedColorFn(province_colors)
    return { type = 'fixed', colors = province_colors or {} }
end

--- Create a gradient colour map mode.
-- @param values     table   {[id] = number}
-- @param min_color  table   {r, g, b}
-- @param max_color  table   {r, g, b}
-- @param min_val    number
-- @param max_val    number
-- @treturn table
function M.newGradientColorFn(values, min_color, max_color, min_val, max_val)
    return {
        type      = 'gradient',
        values    = values or {},
        min_color = min_color or {0, 0, 0},
        max_color = max_color or {255, 255, 255},
        min_val   = min_val or 0,
        max_val   = max_val or 1,
    }
end

--- Apply a gradient colour function to a province, returning a {r,g,b} colour.
-- @param fn    table  gradient colour function
-- @param id    number province id
-- @treturn table {r, g, b}
function M.applyGradientColor(fn, id)
    local v = fn.values[id] or fn.min_val
    local t = (v - fn.min_val) / math.max(fn.max_val - fn.min_val, 1e-9)
    t = math.max(0, math.min(1, t))
    local r = fn.min_color[1] + t * (fn.max_color[1] - fn.min_color[1])
    local g = fn.min_color[2] + t * (fn.max_color[2] - fn.min_color[2])
    local b = fn.min_color[3] + t * (fn.max_color[3] - fn.min_color[3])
    return {math.floor(r+0.5), math.floor(g+0.5), math.floor(b+0.5)}
end

--- Create a category colour map mode.
-- @param categories    table  {[id] = category_string}
-- @param colors        table  {[category_string] = {r, g, b}}
-- @param default_color table  {r, g, b}
-- @treturn table
function M.newCategoryColorFn(categories, colors, default_color)
    return {
        type          = 'category',
        categories    = categories or {},
        colors        = colors or {},
        default_color = default_color or {128, 128, 128},
    }
end

--- Apply a category colour function to a province.
-- @param fn table category colour function
-- @param id number province id
-- @treturn table {r, g, b}
function M.applyCategoryColor(fn, id)
    local cat = fn.categories[id]
    if cat and fn.colors[cat] then return fn.colors[cat] end
    return fn.default_color
end

-- ── MapMode ───────────────────────────────────────────────────────────────

--- Create a named map mode.
-- @param name     string
-- @param color_fn table|string
-- @treturn table
function M.newMapMode(name, color_fn)
    return {
        name     = name,
        color_fn = color_fn or M.MapModeColorFn.SourceColor,
    }
end

-- ── ProvinceMap ───────────────────────────────────────────────────────────

local ProvinceMap = {}
ProvinceMap.__index = ProvinceMap

--- Create a new empty province map.
-- @param width  number pixel width
-- @param height number pixel height
-- @treturn ProvinceMap
function M.newProvinceMap(width, height)
    return setmetatable({
        _width       = width or 0,
        _height      = height or 0,
        provinces    = {},
        pixel_lookup = {},
        adjacency    = {},
    }, ProvinceMap)
end

--- Return the map width in pixels.
-- @treturn number
function ProvinceMap:width()  return self._width  end
--- Return the map height in pixels.
-- @treturn number
function ProvinceMap:height() return self._height end

--- Insert or replace a province.
-- @param province Province
function ProvinceMap:insertProvince(province)
    self.provinces[province.id] = province
end

--- Remove a province by ID. Returns true if it existed.
-- @param id number
-- @treturn boolean
function ProvinceMap:removeProvince(id)
    if self.provinces[id] then
        self.provinces[id] = nil
        return true
    end
    return false
end

--- Look up a province by ID.
-- @param id number
-- @treturn Province|nil
function ProvinceMap:getProvince(id)
    return self.provinces[id]
end

--- Return the total number of provinces.
-- @treturn number
function ProvinceMap:provinceCount()
    local n = 0
    for _ in pairs(self.provinces) do n = n + 1 end
    return n
end

--- Return a sorted list of all province IDs.
-- @treturn table
function ProvinceMap:provinceIds()
    local ids = {}
    for id in pairs(self.provinces) do ids[#ids+1] = id end
    table.sort(ids)
    return ids
end

--- Set pixel at (x, y) to the given province ID.
-- @param x          number 0-based
-- @param y          number 0-based
-- @param province_id number
function ProvinceMap:setPixel(x, y, province_id)
    if x < 0 or x >= self._width or y < 0 or y >= self._height then return end
    self.pixel_lookup[y * self._width + x + 1] = province_id
end

--- Return the province ID at pixel (x, y).
-- @param x number 0-based
-- @param y number 0-based
-- @treturn number|nil
function ProvinceMap:getProvinceAt(x, y)
    if x < 0 or x >= self._width or y < 0 or y >= self._height then return nil end
    return self.pixel_lookup[y * self._width + x + 1]
end

local function adj_key(a, b)
    if a > b then a, b = b, a end
    return a .. ':' .. b
end

--- Insert an adjacency edge.
-- @param edge table AdjacencyEdge
function ProvinceMap:insertAdjacency(edge)
    local key = adj_key(edge.province_a, edge.province_b)
    self.adjacency[key] = edge
end

--- Remove an adjacency edge. Returns true if removed.
-- @param a number
-- @param b number
-- @treturn boolean
function ProvinceMap:removeAdjacency(a, b)
    local key = adj_key(a, b)
    if self.adjacency[key] then
        self.adjacency[key] = nil
        return true
    end
    return false
end

--- Get the adjacency edge between two provinces.
-- @param a number
-- @param b number
-- @treturn table|nil
function ProvinceMap:getAdjacency(a, b)
    return self.adjacency[adj_key(a, b)]
end

--- Return the total number of adjacency edges.
-- @treturn number
function ProvinceMap:adjacencyCount()
    local n = 0
    for _ in pairs(self.adjacency) do n = n + 1 end
    return n
end

--- Return a sorted list of neighbour province IDs for the given province.
-- @param id number
-- @treturn table
function ProvinceMap:getNeighbors(id)
    local out = {}
    for _, edge in pairs(self.adjacency) do
        if not (edge.province_a == id or edge.province_b == id) then
            -- skip
        else
            local nid = edge.province_a == id and edge.province_b or edge.province_a
            out[#out+1] = nid
        end
    end
    table.sort(out)
    return out
end

--- Set adjacency between two provinces (creates or updates edge).
-- @param a    number
-- @param b    number
-- @param tags table optional {tag=true, ...}
function ProvinceMap:setAdjacent(a, b, tags)
    local edge = self:getAdjacency(a, b)
    if not edge then
        edge = M.newAdjacencyEdge(a, b)
        self:insertAdjacency(edge)
    end
    if tags then
        for t in pairs(tags) do edge.tags[t] = true end
    end
    return edge
end

--- Euclidean centroid distance between two provinces.
-- @param a number
-- @param b number
-- @treturn number
function ProvinceMap:distance(a, b)
    local pa = self.provinces[a]
    local pb = self.provinces[b]
    if not pa or not pb then return 0 end
    local dx = pa.centroid.x - pb.centroid.x
    local dy = pa.centroid.y - pb.centroid.y
    return math.sqrt(dx * dx + dy * dy)
end

--- Return the raw pixel-lookup table.
-- @treturn table
function ProvinceMap:pixelLookup() return self.pixel_lookup end

--- BFS route from province `from_id` to `to_id`.
-- Returns an ordered list of province IDs forming the path, or nil if unreachable.
-- Passable edges (passable == true) and optional cost filter are respected.
-- @param from_id      number
-- @param to_id        number
-- @param passable_fn  function|nil  passable_fn(edge) → boolean (nil = all passable)
-- @treturn table|nil  ordered province ID list including from_id and to_id
function ProvinceMap:findRoute(from_id, to_id, passable_fn)
    if from_id == to_id then return {from_id} end
    passable_fn = passable_fn or function(e) return e.passable ~= false end
    local visited = {[from_id] = true}
    local prev    = {}
    local queue   = {from_id}
    local head    = 1
    while head <= #queue do
        local cur = queue[head]; head = head + 1
        for _, edge in pairs(self.adjacency) do
            local a, b = edge.province_a, edge.province_b
            if a == cur or b == cur then
                local nbr = a == cur and b or a
                if not visited[nbr] and passable_fn(edge) then
                    visited[nbr] = true
                    prev[nbr]    = cur
                    if nbr == to_id then
                        -- reconstruct
                        local path = {}
                        local node = to_id
                        while node do
                            table.insert(path, 1, node)
                            node = prev[node]
                        end
                        return path
                    end
                    queue[#queue+1] = nbr
                end
            end
        end
    end
    return nil
end

--- Return all province IDs controlled by the given faction.
-- @param faction string
-- @treturn table sorted list of province IDs
function ProvinceMap:getProvincesByFaction(faction)
    local out = {}
    for id, prov in pairs(self.provinces) do
        if prov:getFaction() == faction then out[#out+1] = id end
    end
    table.sort(out)
    return out
end

--- Sum a resource across all provinces belonging to a faction.
-- @param faction  string
-- @param resource string
-- @treturn number
function ProvinceMap:totalResourceForFaction(faction, resource)
    local total = 0
    for _, prov in pairs(self.provinces) do
        if prov:getFaction() == faction then
            total = total + prov:getResource(resource)
        end
    end
    return total
end

--- Get all provinces whose faction field is nil (uncontrolled).
-- @treturn table sorted list of province IDs
function ProvinceMap:getUncontrolledProvinces()
    local out = {}
    for id, prov in pairs(self.provinces) do
        if not prov:getFaction() then out[#out+1] = id end
    end
    table.sort(out)
    return out
end

--- Get all provinces with no adjacency edges (isolated islands).
-- @treturn table sorted list of province IDs
function ProvinceMap:findIsolatedProvinces()
    local has_edge = {}
    for _, edge in pairs(self.adjacency) do
        has_edge[edge.province_a] = true
        has_edge[edge.province_b] = true
    end
    local out = {}
    for id in pairs(self.provinces) do
        if not has_edge[id] then out[#out+1] = id end
    end
    table.sort(out)
    return out
end

--- Get connected components (list of lists of province IDs).
-- @treturn table  list of component tables (sorted IDs inside each)
function ProvinceMap:getConnectedComponents()
    local visited = {}
    local components = {}
    for id in pairs(self.provinces) do
        if not visited[id] then
            local comp = {}
            local queue = {id}
            visited[id] = true
            local head = 1
            while head <= #queue do
                local cur = queue[head]; head = head + 1
                comp[#comp+1] = cur
                for _, edge in pairs(self.adjacency) do
                    local a, b = edge.province_a, edge.province_b
                    if a == cur or b == cur then
                        local nbr = a == cur and b or a
                        if not visited[nbr] then
                            visited[nbr] = true
                            queue[#queue+1] = nbr
                        end
                    end
                end
            end
            table.sort(comp)
            components[#components+1] = comp
        end
    end
    return components
end

-- ── ProvinceMapEventBus ───────────────────────────────────────────────────

local EventBus = {}
EventBus.__index = EventBus

--- Create a new event bus for province map events.
-- @treturn EventBus
function M.newEventBus()
    return setmetatable({ events = {} }, EventBus)
end

local function emit(self, name, data)
    self.events[#self.events+1] = { name = name, data = data }
end

--- Emit a map-loaded event with province count.
-- @param count number
function EventBus:emitMapLoaded(count)         emit(self, 'map_loaded',          {count = count or 0}) end
--- Emit a province-added event.
-- @param id number
function EventBus:emitProvinceAdded(id)        emit(self, 'province_added',      {id = id}) end
--- Emit a province-removed event.
-- @param id number
function EventBus:emitProvinceRemoved(id)      emit(self, 'province_removed',    {id = id}) end
--- Emit adjacency-detected with edge count.
-- @param edge_count number
function EventBus:emitAdjacencyDetected(edge_count)
    emit(self, 'adjacency_detected', {edge_count = edge_count or 0})
end
--- Emit adjacency-changed for two provinces.
-- @param a number
-- @param b number
function EventBus:emitAdjacencyChanged(a, b)   emit(self, 'adjacency_changed',   {a = a, b = b}) end
--- Emit adjacency-removed for two provinces.
-- @param a number
-- @param b number
function EventBus:emitAdjacencyRemoved(a, b)   emit(self, 'adjacency_removed',   {a = a, b = b}) end
--- Emit borders-extracted with segment count.
-- @param count number
function EventBus:emitBordersExtracted(count)  emit(self, 'borders_extracted',   {segment_count = count or 0}) end
--- Emit map-mode-applied with mode name.
-- @param name string
function EventBus:emitMapModeApplied(name)     emit(self, 'map_mode_applied',    {name = name}) end
--- Emit positions-calculated with province count.
-- @param count number
function EventBus:emitPositionsCalculated(count)
    emit(self, 'positions_calculated', {count = count or 0})
end
--- Emit province-selected at map position.
-- @param id number
-- @param x  number
-- @param y  number
function EventBus:emitProvinceSelected(id, x, y) emit(self, 'province_selected', {id = id, x = x or 0, y = y or 0}) end
--- Emit province-deselected.
-- @param id number
function EventBus:emitProvinceDeselected(id)   emit(self, 'province_deselected', {id = id}) end
--- Emit province-hovered at map position.
-- @param id number
-- @param x  number
-- @param y  number
function EventBus:emitProvinceHovered(id, x, y) emit(self, 'province_hovered',  {id = id, x = x or 0, y = y or 0}) end
--- Emit faction-changed for a province.
-- @param id         number
-- @param old_faction string|nil
-- @param new_faction string|nil
function EventBus:emitFactionChanged(id, old_faction, new_faction)
    emit(self, 'faction_changed', {id = id, old_faction = old_faction, new_faction = new_faction})
end

--- Poll one event from the queue. Returns nil when empty.
-- @treturn table|nil  {name, data}
function EventBus:poll()
    if #self.events == 0 then return nil end
    return table.remove(self.events, 1)
end

--- Return true if no events are queued.
-- @treturn boolean
function EventBus:isEmpty() return #self.events == 0 end

--- Drain and return all queued events.
-- @treturn table
function EventBus:drain()
    local out = self.events
    self.events = {}
    return out
end

--- Return the number of queued events.
-- @treturn number
function EventBus:size() return #self.events end

-- ── Free Functions ─────────────────────────────────────────────────────────

--- Derive a province ID from an RGB colour.
-- @param r number 0–255
-- @param g number 0–255
-- @param b number 0–255
-- @treturn number
function M.colorToId(r, g, b)
    return r * 65536 + g * 256 + b
end

--- Build a ProvinceMap from a list of province definitions.
-- @param defs   table  list of definition tables
-- @param width  number
-- @param height number
-- @treturn ProvinceMap
function M.loadFromDefinitions(defs, width, height)
    local map = M.newProvinceMap(width, height)
    for _, def in ipairs(defs) do
        local p = M.newProvince(def.id, def.color)
        if def.center then
            p.center   = { x = def.center.x or def.center[1] or 0,
                           y = def.center.y or def.center[2] or 0 }
            p.centroid = { x = p.center.x, y = p.center.y }
        end
        p.name = def.name
        if def.faction then p:setFaction(def.faction) end
        map:insertProvince(p)
    end
    for _, def in ipairs(defs) do
        if def.neighbors then
            for _, nid in ipairs(def.neighbors) do
                if not map:getAdjacency(def.id, nid) then
                    map:insertAdjacency(M.newAdjacencyEdge(def.id, nid))
                end
            end
        end
    end
    return map
end

--- Detect province adjacencies from a pixel-lookup grid (single-pass O(w*h)).
-- @param map ProvinceMap
function M.detectAdjacency(map)
    local w = map:width()
    local h = map:height()
    local seen = {}
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local id = map:getProvinceAt(x, y)
            if id then
                for _, d in ipairs({{1,0},{0,1}}) do
                    local nx, ny = x + d[1], y + d[2]
                    local nid = map:getProvinceAt(nx, ny)
                    if nid and nid ~= id then
                        local key = adj_key(id, nid)
                        local edge = map:getAdjacency(id, nid)
                        if not edge then
                            edge = M.newAdjacencyEdge(id, nid)
                            map:insertAdjacency(edge)
                            seen[key] = true
                        end
                        edge.border_length = edge.border_length + 1
                    end
                end
            end
        end
    end
end

--- Extract border segments for all adjacency edges.
-- @param map ProvinceMap
-- @treturn table list of BorderSegment
function M.extractAllBorders(map)
    local borders = {}
    for _, edge in pairs(map.adjacency) do
        borders[#borders+1] = M.newBorderSegment(edge.province_a, edge.province_b)
    end
    return borders
end

--- Extract border segments for edges that have a specific tag.
-- @param map ProvinceMap
-- @param tag string
-- @treturn table list of BorderSegment
function M.extractBordersWithTag(map, tag)
    local borders = {}
    for _, edge in pairs(map.adjacency) do
        if edge.tags[tag] then
            borders[#borders+1] = M.newBorderSegment(edge.province_a, edge.province_b)
        end
    end
    return borders
end

--- Get the centroid position of the province as the capital point.
-- @param map ProvinceMap
-- @param id  number
-- @treturn table|nil {x, y}
function M.calculateCapital(map, id)
    local prov = map:getProvince(id)
    if not prov then return nil end
    return { x = prov.centroid.x, y = prov.centroid.y }
end

--- Set all province center positions to their centroid.
-- @param map ProvinceMap
function M.calculateAllPositions(map)
    for _, prov in pairs(map.provinces) do
        prov.center = { x = prov.centroid.x, y = prov.centroid.y }
    end
end

--- Count total adjacency edges across all provinces in the map.
-- @param map ProvinceMap
-- @treturn number
function M.totalEdgeCount(map)
    return map:adjacencyCount()
end

--- Get all unique faction names present in the map.
-- @param map ProvinceMap
-- @treturn table sorted list of faction strings
function M.allFactions(map)
    local seen = {}
    for _, prov in pairs(map.provinces) do
        if prov:getFaction() then seen[prov:getFaction()] = true end
    end
    local out = {}
    for f in pairs(seen) do out[#out+1] = f end
    table.sort(out)
    return out
end


-- ═══════════════════════════════════════════════════════════════════════
-- PARITY ADDITIONS — Phase 2A  (province_map)
-- ═══════════════════════════════════════════════════════════════════════

--- Return all border segments where the two bordering provinces have different
--- values according to prop_fn.
-- @param map     ProvinceMap
-- @param prop_fn function  fn(province) -> value
-- @treturn table  list of BorderSegment tables
function M.extractBordersByProperty(map, prop_fn)
    local out = {}
    for _, edge in pairs(map.adjacency) do
        local pa = map.provinces[edge.province_a]
        local pb = map.provinces[edge.province_b]
        if pa and pb and prop_fn(pa) ~= prop_fn(pb) then
            local seg = M.newBorderSegment(edge.province_a, edge.province_b)
            for tag in pairs(edge.tags) do seg.tags[tag] = true end
            out[#out+1] = seg
        end
    end
    return out
end

--- Detect province adjacencies from a pixel-lookup grid and tag the resulting
--- edges based on special tag-pixel IDs.
--
-- `tag_pixel_colors` maps province IDs that act as tag pixels to their tag
-- string.  When a tag pixel is adjacent to two distinct non-tag provinces,
-- those provinces' shared edge is created (if absent) and tagged.
--
-- @param map              ProvinceMap
-- @param tag_pixel_colors table  {[province_id] = tag_string}
function M.detectAdjacencyWithTags(map, tag_pixel_colors)
    tag_pixel_colors = tag_pixel_colors or {}

    -- Pass 1: normal adjacency (same algorithm as detectAdjacency)
    local w = map:width()
    local h = map:height()
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local id = map:getProvinceAt(x, y)
            if id and not tag_pixel_colors[id] then
                for _, d in ipairs({{1,0},{0,1}}) do
                    local nx, ny = x + d[1], y + d[2]
                    local nid = map:getProvinceAt(nx, ny)
                    if nid and nid ~= id and not tag_pixel_colors[nid] then
                        local edge = map:getAdjacency(id, nid)
                        if not edge then
                            edge = M.newAdjacencyEdge(id, nid)
                            map:insertAdjacency(edge)
                        end
                        edge.border_length = edge.border_length + 1
                    end
                end
            end
        end
    end

    -- Pass 2: for each tag pixel, collect adjacent non-tag province IDs and
    -- tag every pair's edge with this pixel's tag string.
    if next(tag_pixel_colors) then
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                local tag_id = map:getProvinceAt(x, y)
                if tag_id and tag_pixel_colors[tag_id] then
                    local tag = tag_pixel_colors[tag_id]
                    local touching = {}
                    for _, d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
                        local nx, ny = x + d[1], y + d[2]
                        local nid = map:getProvinceAt(nx, ny)
                        if nid and nid ~= 0 and not tag_pixel_colors[nid] then
                            touching[nid] = true
                        end
                    end
                    local list = {}
                    for pid in pairs(touching) do list[#list+1] = pid end
                    for i = 1, #list do
                        for j = i + 1, #list do
                            local a, b = list[i], list[j]
                            if not map:getAdjacency(a, b) then
                                map:insertAdjacency(M.newAdjacencyEdge(a, b))
                            end
                            map:getAdjacency(a, b).tags[tag] = true
                        end
                    end
                end
            end
        end
    end
end

--- Convert a province map's adjacency structure to a generic graph table.
-- Each unique province that appears in at least one edge becomes a node.
-- Each adjacency edge becomes one undirected entry in the edges list.
-- @param map ProvinceMap
-- @treturn table  { nodes = {province_id,...}, edges = {{a, b},...} }
function M.adjacencyToGraph(map)
    local nodes_set = {}
    local edges = {}
    local seen = {}

    for _, edge in pairs(map.adjacency) do
        local a, b = edge.province_a, edge.province_b
        nodes_set[a] = true
        nodes_set[b] = true
        local key = a < b and (a .. "::" .. b) or (b .. "::" .. a)
        if not seen[key] then
            seen[key] = true
            edges[#edges+1] = { a = a, b = b }
        end
    end

    local nodes = {}
    for id in pairs(nodes_set) do nodes[#nodes+1] = id end
    table.sort(nodes)
    return { nodes = nodes, edges = edges }
end

--- Resolve a colour for each province using the given map mode.
-- Returns a table mapping province ID to a normalised {r, g, b, a} float
-- colour (each component in the 0–1 range).
-- @param map  ProvinceMap
-- @param mode table  MapMode created with M.newMapMode
-- @treturn table  {[province_id] = {r, g, b, a}}
function M.resolveProvinceColors(map, mode)
    local out = {}
    local color_fn = mode.color_fn
    for id, prov in pairs(map.provinces) do
        local color
        if color_fn == M.MapModeColorFn.SourceColor then
            color = {
                prov.color[1] / 255.0,
                prov.color[2] / 255.0,
                prov.color[3] / 255.0,
                1.0,
            }
        elseif type(color_fn) == "table" then
            if color_fn.type == "fixed" then
                color = color_fn.colors[id] or {0.5, 0.5, 0.5, 1.0}
            elseif color_fn.type == "gradient" then
                local c = M.applyGradientColor(color_fn, id)
                color = {c[1] / 255.0, c[2] / 255.0, c[3] / 255.0, 1.0}
            elseif color_fn.type == "category" then
                local c = M.applyCategoryColor(color_fn, id)
                color = {c[1] / 255.0, c[2] / 255.0, c[3] / 255.0, 1.0}
            else
                color = {0.5, 0.5, 0.5, 1.0}
            end
        else
            color = {0.5, 0.5, 0.5, 1.0}
        end
        out[id] = color
    end
    return out
end

-- ── Engine-accelerated constructor ────────────────────────────────────────

--- Build a ProvinceMap from a PNG province-colour map using the Rust engine.
--
-- This replaces the Lua `setPixel` loop + `detectAdjacency` pass with a single
-- Rust O(w×h) scan. For a 2400×1200 map with 3000 provinces the typical speedup
-- is 100×–300× vs the pure-Lua path (from ~2–8 s down to ~15–30 ms).
--
-- Each unique non-black RGB pixel in the PNG is automatically assigned a
-- sequential province ID starting at 1. Pure-black pixels (0, 0, 0) become
-- background (ID 0). The returned ProvinceMap has its `pixel_lookup` field
-- replaced by the engine grid (so `getProvinceAt` delegates to it), and all
-- adjacency edges are pre-populated from the single Rust scan.
--
-- Requires `lurek.img` to be available (Platform Services tier).
--
-- @param png_path  string  path relative to the game folder (e.g. "maps/europe.png")
-- @param defs      table   optional list of province definition tables as accepted
--                          by `M.loadFromDefinitions` — used to attach names,
--                          factions, and other metadata. Pass nil to skip.
-- @treturn ProvinceMap
function M.newFromPng(png_path, defs)
    assert(lurek and lurek.img and lurek.img.newProvinceGrid,
        "province_map.newFromPng requires lurek.img.newProvinceGrid (engine support)")

    -- Load via the Rust engine — single O(w×h) scan, zero Lua table allocations.
    local grid = lurek.img.newProvinceGrid(png_path)
    local w    = grid:getWidth()
    local h    = grid:getHeight()

    -- Build the ProvinceMap shell.
    local map = M.newProvinceMap(w, h)

    -- Replace pixel_lookup with an engine-backed accessor.
    -- Existing callers of getProvinceAt / setPixel still work transparently:
    -- getProvinceAt now delegates to the Rust grid for reads;
    -- setPixel still writes to the legacy Lua table as a fallback.
    map._engine_grid = grid
    local original_getProvinceAt = ProvinceMap.getProvinceAt
    function map:getProvinceAt(x, y)
        return self._engine_grid:getAt(x, y)
    end

    -- Populate adjacency edges from the engine scan (no second Lua pass needed).
    for _, adj in ipairs(grid:adjacencies()) do
        local edge = M.newAdjacencyEdge(adj.province_a, adj.province_b)
        edge.border_length = adj.border_pixels
        map:insertAdjacency(edge)
    end

    -- Attach province metadata from definitions if provided.
    if defs then
        for _, def in ipairs(defs) do
            local p = M.newProvince(def.id, def.color)
            if def.center then
                p.center   = { x = def.center.x or def.center[1] or 0,
                               y = def.center.y or def.center[2] or 0 }
                p.centroid = { x = p.center.x, y = p.center.y }
            end
            p.name = def.name
            if def.faction then p:setFaction(def.faction) end
            map:insertProvince(p)
        end
    end

    return map
end

return M
