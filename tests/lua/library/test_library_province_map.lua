--- BDD tests for library.province_map
--- Covers: Province, AdjacencyEdge, ProvinceDefinition, BorderSegment,
---         BorderStyle, ProvinceMap, EventBus, MapMode, free functions.

package.path = "./library/?/init.lua;" .. package.path

local pm = require("library.province_map")

dofile("tests/lua/init.lua")

-- ── Province ─────────────────────────────────────────────────────────────

describe("Province", function()
    it("new with defaults", function()
        local p = pm.newProvince(1, {255, 0, 0})
        expect_equal(p.id, 1)
        expect_equal(p.color[1], 255)
        expect_equal(p.area, 0)
        expect_equal(p.name, nil)
    end)

    it("fields are writable", function()
        local p = pm.newProvince(2, {0, 128, 0})
        p.area = 100
        p.name = "Greenland"
        p.centroid = {x = 50, y = 60}
        expect_equal(p.area, 100)
        expect_equal(p.name, "Greenland")
        expect_equal(p.centroid.x, 50)
    end)
end)

-- ── AdjacencyEdge ────────────────────────────────────────────────────────

describe("AdjacencyEdge", function()
    it("new with default fields", function()
        local e = pm.newAdjacencyEdge(1, 2)
        expect_equal(e.province_a, 1)
        expect_equal(e.province_b, 2)
        expect_equal(e.border_length, 0)
    end)

    it("tags can be added and checked", function()
        local e = pm.newAdjacencyEdge(3, 4)
        pm.addEdgeTag(e, "river")
        expect_equal(pm.hasEdgeTag(e, "river"), true)
        expect_equal(pm.hasEdgeTag(e, "mountain"), false)
    end)
end)

-- ── ProvinceDefinition ───────────────────────────────────────────────────

describe("ProvinceDefinition", function()
    it("new with defaults", function()
        local d = pm.newProvinceDefinition(1, {10, 20, 30}, {x = 5, y = 10})
        expect_equal(d.id, 1)
        expect_equal(d.color[2], 20)
        expect_equal(d.center.x, 5)
        expect_equal(#d.neighbors, 0)
    end)
end)

-- ── BorderSegment ────────────────────────────────────────────────────────

describe("BorderSegment", function()
    it("new with defaults", function()
        local b = pm.newBorderSegment(1, 2)
        expect_equal(b.province_a, 1)
        expect_equal(b.province_b, 2)
        expect_equal(#b.points, 0)
    end)
end)

-- ── BorderStyle ──────────────────────────────────────────────────────────

describe("BorderStyle", function()
    it("new with defaults", function()
        local s = pm.newBorderStyle()
        expect_equal(s.width, 1.0)
        expect_equal(s.dashed, false)
        expect_equal(#s.color, 4)
    end)
end)

-- ── MapMode & ColorFn ────────────────────────────────────────────────────

describe("MapMode", function()
    it("new with source color", function()
        local mode = pm.newMapMode("political")
        expect_equal(mode.name, "political")
        expect_equal(mode.color_fn, "source_color")
    end)

    it("fixed color fn", function()
        local fn = pm.newFixedColorFn({[1] = {255,0,0}})
        expect_equal(fn.type, "fixed")
        expect_equal(fn.colors[1][1], 255)
    end)

    it("gradient color fn", function()
        local fn = pm.newGradientColorFn({}, {0,0,0}, {255,255,255}, 0, 100)
        expect_equal(fn.type, "gradient")
        expect_equal(fn.max_val, 100)
    end)

    it("category color fn", function()
        local fn = pm.newCategoryColorFn({}, {}, {64, 64, 64})
        expect_equal(fn.type, "category")
        expect_equal(fn.default_color[1], 64)
    end)
end)

-- ── ProvinceMap ──────────────────────────────────────────────────────────

describe("ProvinceMap", function()
    it("new with dimensions", function()
        local map = pm.newProvinceMap(100, 200)
        expect_equal(map:width(), 100)
        expect_equal(map:height(), 200)
        expect_equal(map:provinceCount(), 0)
    end)

    it("insertProvince and getProvince", function()
        local map = pm.newProvinceMap(10, 10)
        local p = pm.newProvince(5, {255, 0, 0})
        map:insertProvince(p)
        expect_equal(map:provinceCount(), 1)
        expect_equal(map:getProvince(5).color[1], 255)
        expect_equal(map:getProvince(99), nil)
    end)

    it("provinceIds returns sorted list", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(3, {0,0,0}))
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        local ids = map:provinceIds()
        expect_equal(ids[1], 1)
        expect_equal(ids[2], 2)
        expect_equal(ids[3], 3)
    end)

    it("setPixel and getProvinceAt", function()
        local map = pm.newProvinceMap(4, 4)
        map:setPixel(1, 2, 7)
        expect_equal(map:getProvinceAt(1, 2), 7)
        expect_equal(map:getProvinceAt(0, 0), nil)
        expect_equal(map:getProvinceAt(-1, 0), nil)
    end)

    it("insertAdjacency and getAdjacency", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        expect_equal(map:adjacencyCount(), 1)
        local edge = map:getAdjacency(1, 2)
        expect_equal(edge.province_a, 1)
        -- symmetric lookup
        local edge2 = map:getAdjacency(2, 1)
        expect_equal(edge2.province_a, 1)
    end)

    it("getNeighbors returns sorted ids", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 3))
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        local nbrs = map:getNeighbors(1)
        expect_equal(nbrs[1], 2)
        expect_equal(nbrs[2], 3)
    end)

    it("distance between centroids", function()
        local map = pm.newProvinceMap(100, 100)
        local a = pm.newProvince(1, {0,0,0})
        a.centroid = {x = 0, y = 0}
        local b = pm.newProvince(2, {0,0,0})
        b.centroid = {x = 3, y = 4}
        map:insertProvince(a)
        map:insertProvince(b)
        expect_near(map:distance(1, 2), 5.0, 0.001)
    end)
end)

-- ── EventBus ─────────────────────────────────────────────────────────────

describe("EventBus", function()
    it("new starts empty", function()
        local bus = pm.newEventBus()
        expect_equal(bus:isEmpty(), true)
        expect_equal(bus:poll(), nil)
    end)

    it("emit and poll events", function()
        local bus = pm.newEventBus()
        bus:emitMapLoaded()
        bus:emitProvinceAdded(5)
        expect_equal(bus:isEmpty(), false)
        local e1 = bus:poll()
        expect_equal(e1.name, "map_loaded")
        local e2 = bus:poll()
        expect_equal(e2.name, "province_added")
        expect_equal(e2.data.id, 5)
        expect_equal(bus:isEmpty(), true)
    end)

    it("drain returns all and empties", function()
        local bus = pm.newEventBus()
        bus:emitProvinceRemoved(1)
        bus:emitAdjacencyDetected(2, 3)
        local all = bus:drain()
        expect_equal(#all, 2)
        expect_equal(bus:isEmpty(), true)
    end)

    it("all emit methods work", function()
        local bus = pm.newEventBus()
        bus:emitMapLoaded()
        bus:emitProvinceAdded(1)
        bus:emitProvinceRemoved(1)
        bus:emitAdjacencyDetected(1, 2)
        bus:emitAdjacencyChanged(1, 2)
        bus:emitAdjacencyRemoved(1, 2)
        bus:emitBordersExtracted(10)
        bus:emitMapModeApplied("political")
        bus:emitPositionsCalculated()
        bus:emitProvinceSelected(1)
        bus:emitProvinceDeselected(1)
        bus:emitProvinceHovered(1)
        local all = bus:drain()
        expect_equal(#all, 12)
    end)
end)

-- ── Free Functions ───────────────────────────────────────────────────────

describe("Free Functions", function()
    it("colorToId encodes RGB", function()
        expect_equal(pm.colorToId(255, 0, 0), 16711680)
        expect_equal(pm.colorToId(0, 255, 0), 65280)
        expect_equal(pm.colorToId(0, 0, 255), 255)
        expect_equal(pm.colorToId(1, 2, 3), 66051)
    end)

    it("loadFromDefinitions builds map", function()
        local defs = {
            {id = 1, color = {255,0,0}, center = {x = 10, y = 20}, neighbors = {2}, name = "Alpha"},
            {id = 2, color = {0,255,0}, center = {x = 50, y = 60}, neighbors = {1, 3}},
            {id = 3, color = {0,0,255}, center = {x = 80, y = 90}, neighbors = {2}},
        }
        local map = pm.loadFromDefinitions(defs, 100, 100)
        expect_equal(map:provinceCount(), 3)
        expect_equal(map:getProvince(1).name, "Alpha")
        expect_equal(map:adjacencyCount(), 2)
        local nbrs = map:getNeighbors(2)
        expect_equal(#nbrs, 2)
    end)

    it("detectAdjacency scans pixel grid", function()
        local map = pm.newProvinceMap(3, 3)
        map:insertProvince(pm.newProvince(1, {255,0,0}))
        map:insertProvince(pm.newProvince(2, {0,255,0}))
        -- top row province 1, bottom row province 2
        map:setPixel(0, 0, 1)
        map:setPixel(1, 0, 1)
        map:setPixel(2, 0, 1)
        map:setPixel(0, 1, 2)
        map:setPixel(1, 1, 2)
        map:setPixel(2, 1, 2)
        pm.detectAdjacency(map)
        expect_equal(map:adjacencyCount(), 1)
        local edge = map:getAdjacency(1, 2)
        expect_equal(edge ~= nil, true)
        expect_equal(edge.border_length > 0, true)
    end)

    it("extractAllBorders returns segments", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(2, 3))
        local borders = pm.extractAllBorders(map)
        expect_equal(#borders, 2)
    end)

    it("extractBordersWithTag filters by tag", function()
        local map = pm.newProvinceMap(10, 10)
        local e1 = pm.newAdjacencyEdge(1, 2)
        e1.tags["river"] = true
        map:insertAdjacency(e1)
        map:insertAdjacency(pm.newAdjacencyEdge(2, 3))
        local rivers = pm.extractBordersWithTag(map, "river")
        expect_equal(#rivers, 1)
    end)

    it("calculateCapital returns centroid", function()
        local map = pm.newProvinceMap(10, 10)
        local p = pm.newProvince(1, {0,0,0})
        p.centroid = {x = 25, y = 35}
        map:insertProvince(p)
        local cap = pm.calculateCapital(map, 1)
        expect_equal(cap.x, 25)
        expect_equal(cap.y, 35)
    end)

    it("calculateAllPositions syncs center to centroid", function()
        local map = pm.newProvinceMap(10, 10)
        local p = pm.newProvince(1, {0,0,0})
        p.centroid = {x = 10, y = 20}
        p.center = {x = 0, y = 0}
        map:insertProvince(p)
        pm.calculateAllPositions(map)
        expect_equal(map:getProvince(1).center.x, 10)
        expect_equal(map:getProvince(1).center.y, 20)
    end)
end)

-- ── Province extended ──────────────────────────────────────────────────────

describe("Province.faction", function()
    it("setFaction / getFaction", function()
        local p = pm.newProvince(1, {0,0,0})
        expect_equal(p:getFaction(), nil)
        p:setFaction("blue")
        expect_equal(p:getFaction(), "blue")
    end)

    it("setDefenseRating / getDefenseRating", function()
        local p = pm.newProvince(1, {0,0,0})
        p:setDefenseRating(75)
        expect_equal(p:getDefenseRating(), 75)
    end)

    it("addBuilding / hasBuilding / getBuildings / removeBuilding", function()
        local p = pm.newProvince(1, {0,0,0})
        p:addBuilding("barracks")
        p:addBuilding("market")
        expect_equal(p:hasBuilding("barracks"), true)
        expect_equal(p:hasBuilding("castle"), false)
        expect_equal(#p:getBuildings(), 2)
        expect_equal(p:removeBuilding("market"), true)
        expect_equal(#p:getBuildings(), 1)
    end)

    it("setResource / getResource / getResources", function()
        local p = pm.newProvince(1, {0,0,0})
        p:setResource("gold", 50)
        p:setResource("wood", 30)
        expect_equal(p:getResource("gold"), 50)
        expect_equal(p:getResource("stone"), 0)
        local all = p:getResources()
        expect_equal(all.gold, 50)
    end)
end)

-- ── ProvinceMap extended ──────────────────────────────────────────────────

describe("ProvinceMap.findRoute", function()
    local function make_chain(n)
        local map = pm.newProvinceMap(10, 10)
        for i = 1, n do
            map:insertProvince(pm.newProvince(i, {0,0,0}))
        end
        for i = 1, n - 1 do
            map:insertAdjacency(pm.newAdjacencyEdge(i, i + 1))
        end
        return map
    end

    it("direct adjacency returns two-element path", function()
        local map = make_chain(2)
        local path = map:findRoute(1, 2)
        expect_equal(#path, 2)
        expect_equal(path[1], 1)
        expect_equal(path[2], 2)
    end)

    it("chain path returns ordered ids", function()
        local map = make_chain(4)
        local path = map:findRoute(1, 4)
        expect_equal(path[1], 1)
        expect_equal(path[#path], 4)
        expect_equal(#path, 4)
    end)

    it("same province returns single-element path", function()
        local map = make_chain(3)
        local path = map:findRoute(2, 2)
        expect_equal(#path, 1)
        expect_equal(path[1], 2)
    end)

    it("unreachable returns nil", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(5, {0,0,0}))
        expect_equal(map:findRoute(1, 5), nil)
    end)

    it("passable_fn can block an edge", function()
        local map = make_chain(3)
        -- block 1-2 edge
        local path = map:findRoute(1, 3, function(e)
            return not (e.province_a == 1 and e.province_b == 2)
        end)
        expect_equal(path, nil)
    end)
end)

describe("ProvinceMap.faction_queries", function()
    it("getProvincesByFaction returns matching IDs", function()
        local map = pm.newProvinceMap(10, 10)
        for i = 1, 5 do
            local p = pm.newProvince(i, {0,0,0})
            p:setFaction(i <= 3 and "red" or "blue")
            map:insertProvince(p)
        end
        local reds = map:getProvincesByFaction("red")
        expect_equal(#reds, 3)
        expect_equal(reds[1], 1)
    end)

    it("totalResourceForFaction sums across provinces", function()
        local map = pm.newProvinceMap(10, 10)
        for i = 1, 3 do
            local p = pm.newProvince(i, {0,0,0})
            p:setFaction("red")
            p:setResource("gold", i * 10)
            map:insertProvince(p)
        end
        expect_equal(map:totalResourceForFaction("red", "gold"), 60)
    end)

    it("getUncontrolledProvinces", function()
        local map = pm.newProvinceMap(10, 10)
        local a = pm.newProvince(1, {0,0,0}); a:setFaction("red"); map:insertProvince(a)
        local b = pm.newProvince(2, {0,0,0}); map:insertProvince(b)
        local unc = map:getUncontrolledProvinces()
        expect_equal(#unc, 1)
        expect_equal(unc[1], 2)
    end)
end)

describe("ProvinceMap.setAdjacent", function()
    it("creates new edge", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        local edge = map:setAdjacent(1, 2, {river = true})
        expect_equal(edge ~= nil, true)
        expect_equal(edge.tags.river, true)
        expect_equal(map:adjacencyCount(), 1)
    end)

    it("updates existing edge with new tags", function()
        local map = pm.newProvinceMap(10, 10)
        map:setAdjacent(1, 2, {road = true})
        map:setAdjacent(1, 2, {wall = true})
        local edge = map:getAdjacency(1, 2)
        expect_equal(edge.tags.road, true)
        expect_equal(edge.tags.wall, true)
    end)
end)

describe("ProvinceMap.graph_analysis", function()
    it("findIsolatedProvinces returns unconnected ids", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        map:insertProvince(pm.newProvince(3, {0,0,0}))
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        local iso = map:findIsolatedProvinces()
        expect_equal(#iso, 1)
        expect_equal(iso[1], 3)
    end)

    it("getConnectedComponents partitions provinces", function()
        local map = pm.newProvinceMap(10, 10)
        for i = 1, 4 do map:insertProvince(pm.newProvince(i, {0,0,0})) end
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(3, 4))
        local comps = map:getConnectedComponents()
        expect_equal(#comps, 2)
    end)
end)

describe("ColorFn_apply", function()
    it("applyGradientColor interpolates", function()
        local fn = pm.newGradientColorFn({[1]=0}, {0,0,0}, {255,255,255}, 0, 100)
        local c0 = pm.applyGradientColor(fn, 1)
        expect_equal(c0[1], 0)
        fn.values[1] = 100
        local c1 = pm.applyGradientColor(fn, 1)
        expect_equal(c1[1], 255)
    end)

    it("applyCategoryColor selects by category", function()
        local fn = pm.newCategoryColorFn(
            {[1]="hot"}, {hot={255,0,0}}, {0,0,0})
        local c = pm.applyCategoryColor(fn, 1)
        expect_equal(c[1], 255)
        local def = pm.applyCategoryColor(fn, 99)
        expect_equal(def[1], 0)
    end)
end)

describe("allFactions", function()
    it("returns sorted faction list", function()
        local map = pm.newProvinceMap(10, 10)
        for i, f in ipairs({"green","blue","red","blue"}) do
            local p = pm.newProvince(i, {0,0,0})
            p:setFaction(f)
            map:insertProvince(p)
        end
        local factions = pm.allFactions(map)
        expect_equal(factions[1], "blue")
        expect_equal(factions[2], "green")
        expect_equal(factions[3], "red")
    end)
end)

-- ── Province extended ──────────────────────────────────────────────────────

describe("Province.faction", function()
    it("setFaction / getFaction", function()
        local p = pm.newProvince(1, {0,0,0})
        expect_equal(p:getFaction(), nil)
        p:setFaction("blue")
        expect_equal(p:getFaction(), "blue")
    end)

    it("setDefenseRating / getDefenseRating", function()
        local p = pm.newProvince(1, {0,0,0})
        p:setDefenseRating(75)
        expect_equal(p:getDefenseRating(), 75)
    end)

    it("addBuilding / hasBuilding / getBuildings / removeBuilding", function()
        local p = pm.newProvince(1, {0,0,0})
        p:addBuilding("barracks")
        p:addBuilding("market")
        expect_equal(p:hasBuilding("barracks"), true)
        expect_equal(p:hasBuilding("castle"), false)
        expect_equal(#p:getBuildings(), 2)
        expect_equal(p:removeBuilding("market"), true)
        expect_equal(#p:getBuildings(), 1)
    end)

    it("setResource / getResource / getResources", function()
        local p = pm.newProvince(1, {0,0,0})
        p:setResource("gold", 50)
        p:setResource("wood", 30)
        expect_equal(p:getResource("gold"), 50)
        expect_equal(p:getResource("stone"), 0)
        local all = p:getResources()
        expect_equal(all.gold, 50)
    end)
end)

-- ── ProvinceMap extended ──────────────────────────────────────────────────

describe("ProvinceMap.findRoute", function()
    local function make_chain(n)
        local map = pm.newProvinceMap(10, 10)
        for i = 1, n do
            map:insertProvince(pm.newProvince(i, {0,0,0}))
        end
        for i = 1, n - 1 do
            map:insertAdjacency(pm.newAdjacencyEdge(i, i + 1))
        end
        return map
    end

    it("direct adjacency returns two-element path", function()
        local map = make_chain(2)
        local path = map:findRoute(1, 2)
        expect_equal(#path, 2)
        expect_equal(path[1], 1)
        expect_equal(path[2], 2)
    end)

    it("chain path returns ordered ids", function()
        local map = make_chain(4)
        local path = map:findRoute(1, 4)
        expect_equal(path[1], 1)
        expect_equal(path[#path], 4)
        expect_equal(#path, 4)
    end)

    it("same province returns single-element path", function()
        local map = make_chain(3)
        local path = map:findRoute(2, 2)
        expect_equal(#path, 1)
        expect_equal(path[1], 2)
    end)

    it("unreachable returns nil", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(5, {0,0,0}))
        expect_equal(map:findRoute(1, 5), nil)
    end)

    it("passable_fn can block an edge", function()
        local map = make_chain(3)
        -- block 1-2 edge
        local path = map:findRoute(1, 3, function(e)
            return not (e.province_a == 1 and e.province_b == 2)
        end)
        expect_equal(path, nil)
    end)
end)

describe("ProvinceMap.faction_queries", function()
    it("getProvincesByFaction returns matching IDs", function()
        local map = pm.newProvinceMap(10, 10)
        for i = 1, 5 do
            local p = pm.newProvince(i, {0,0,0})
            p:setFaction(i <= 3 and "red" or "blue")
            map:insertProvince(p)
        end
        local reds = map:getProvincesByFaction("red")
        expect_equal(#reds, 3)
        expect_equal(reds[1], 1)
    end)

    it("totalResourceForFaction sums across provinces", function()
        local map = pm.newProvinceMap(10, 10)
        for i = 1, 3 do
            local p = pm.newProvince(i, {0,0,0})
            p:setFaction("red")
            p:setResource("gold", i * 10)
            map:insertProvince(p)
        end
        expect_equal(map:totalResourceForFaction("red", "gold"), 60)
    end)

    it("getUncontrolledProvinces", function()
        local map = pm.newProvinceMap(10, 10)
        local a = pm.newProvince(1, {0,0,0}); a:setFaction("red"); map:insertProvince(a)
        local b = pm.newProvince(2, {0,0,0}); map:insertProvince(b)
        local unc = map:getUncontrolledProvinces()
        expect_equal(#unc, 1)
        expect_equal(unc[1], 2)
    end)
end)

describe("ProvinceMap.setAdjacent", function()
    it("creates new edge", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        local edge = map:setAdjacent(1, 2, {river = true})
        expect_equal(edge ~= nil, true)
        expect_equal(edge.tags.river, true)
        expect_equal(map:adjacencyCount(), 1)
    end)

    it("updates existing edge with new tags", function()
        local map = pm.newProvinceMap(10, 10)
        map:setAdjacent(1, 2, {road = true})
        map:setAdjacent(1, 2, {wall = true})
        local edge = map:getAdjacency(1, 2)
        expect_equal(edge.tags.road, true)
        expect_equal(edge.tags.wall, true)
    end)
end)

describe("ProvinceMap.graph_analysis", function()
    it("findIsolatedProvinces returns unconnected ids", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        map:insertProvince(pm.newProvince(3, {0,0,0}))
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        local iso = map:findIsolatedProvinces()
        expect_equal(#iso, 1)
        expect_equal(iso[1], 3)
    end)

    it("getConnectedComponents partitions provinces", function()
        local map = pm.newProvinceMap(10, 10)
        for i = 1, 4 do map:insertProvince(pm.newProvince(i, {0,0,0})) end
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(3, 4))
        local comps = map:getConnectedComponents()
        expect_equal(#comps, 2)
    end)
end)

describe("ColorFn_apply", function()
    it("applyGradientColor interpolates", function()
        local fn = pm.newGradientColorFn({[1]=0}, {0,0,0}, {255,255,255}, 0, 100)
        local c0 = pm.applyGradientColor(fn, 1)
        expect_equal(c0[1], 0)
        fn.values[1] = 100
        local c1 = pm.applyGradientColor(fn, 1)
        expect_equal(c1[1], 255)
    end)

    it("applyCategoryColor selects by category", function()
        local fn = pm.newCategoryColorFn(
            {[1]="hot"}, {hot={255,0,0}}, {0,0,0})
        local c = pm.applyCategoryColor(fn, 1)
        expect_equal(c[1], 255)
        local def = pm.applyCategoryColor(fn, 99)
        expect_equal(def[1], 0)
    end)
end)

describe("allFactions", function()
    it("returns sorted faction list", function()
        local map = pm.newProvinceMap(10, 10)
        for i, f in ipairs({"green","blue","red","blue"}) do
            local p = pm.newProvince(i, {0,0,0})
            p:setFaction(f)
            map:insertProvince(p)
        end
        local factions = pm.allFactions(map)
        expect_equal(factions[1], "blue")
        expect_equal(factions[2], "green")
        expect_equal(factions[3], "red")
    end)
end)

-- ── Gap coverage ──────────────────────────────────────────────────────────

describe("ProvinceMap.removeProvince", function()
    it("removes an existing province and returns true", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(7, {0,0,0}))
        expect_equal(map:provinceCount(), 1)
        expect_equal(map:removeProvince(7), true)
        expect_equal(map:provinceCount(), 0)
        expect_equal(map:getProvince(7), nil)
    end)

    it("returns false for missing province", function()
        local map = pm.newProvinceMap(10, 10)
        expect_equal(map:removeProvince(99), false)
    end)
end)

describe("ProvinceMap.removeAdjacency", function()
    it("removes an existing edge and returns true", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        expect_equal(map:adjacencyCount(), 1)
        expect_equal(map:removeAdjacency(1, 2), true)
        expect_equal(map:adjacencyCount(), 0)
        expect_equal(map:getAdjacency(1, 2), nil)
    end)

    it("symmetric: removeAdjacency(b, a) also works", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(3, 5))
        expect_equal(map:removeAdjacency(5, 3), true)
    end)

    it("returns false for missing edge", function()
        local map = pm.newProvinceMap(10, 10)
        expect_equal(map:removeAdjacency(1, 2), false)
    end)
end)

describe("totalEdgeCount", function()
    it("mirrors adjacencyCount", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(2, 3))
        expect_equal(pm.totalEdgeCount(map), 2)
        expect_equal(pm.totalEdgeCount(map), map:adjacencyCount())
    end)
end)

describe("ProvinceMap.pixelLookup", function()
    it("returns the internal lookup table", function()
        local map = pm.newProvinceMap(2, 2)
        map:setPixel(0, 0, 5)
        map:setPixel(1, 1, 9)
        local tbl = map:pixelLookup()
        expect_type("table", tbl)
        -- index 1 = pixel (0,0), index 4 = pixel (1,1) for 2-wide map
        expect_equal(tbl[1], 5)
        expect_equal(tbl[4], 9)
    end)
end)

describe("extractBordersByProperty", function()
    it("returns segments where property differs", function()
        local map = pm.newProvinceMap(10, 10)
        local a = pm.newProvince(1, {0,0,0}); a.terrain = "forest"
        local b = pm.newProvince(2, {0,0,0}); b.terrain = "plains"
        local c = pm.newProvince(3, {0,0,0}); c.terrain = "forest"
        map:insertProvince(a)
        map:insertProvince(b)
        map:insertProvince(c)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))  -- different
        map:insertAdjacency(pm.newAdjacencyEdge(1, 3))  -- same terrain
        local segs = pm.extractBordersByProperty(map, function(p) return p.terrain end)
        expect_equal(#segs, 1)
        expect_equal(segs[1].province_a, 1)
        expect_equal(segs[1].province_b, 2)
    end)

    it("returns empty when all properties match", function()
        local map = pm.newProvinceMap(10, 10)
        local a = pm.newProvince(1, {0,0,0}); a.biome = "arctic"
        local b = pm.newProvince(2, {0,0,0}); b.biome = "arctic"
        map:insertProvince(a)
        map:insertProvince(b)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        local segs = pm.extractBordersByProperty(map, function(p) return p.biome end)
        expect_equal(#segs, 0)
    end)
end)

describe("detectAdjacencyWithTags", function()
    it("detects normal adjacency and tags edges via tag pixels", function()
        -- 3x1 pixel strip: [prov1][tag_pixel][prov2]
        -- tag pixel (id=99) should cause the edge between 1 and 2 to get tag "river"
        local map = pm.newProvinceMap(3, 1)
        map:insertProvince(pm.newProvince(1, {255,0,0}))
        map:insertProvince(pm.newProvince(2, {0,255,0}))
        map:setPixel(0, 0, 1)
        map:setPixel(1, 0, 99)   -- tag pixel
        map:setPixel(2, 0, 2)
        pm.detectAdjacencyWithTags(map, {[99] = "river"})
        local edge = map:getAdjacency(1, 2)
        expect_equal(edge ~= nil, true)
        expect_equal(edge.tags.river, true)
    end)

    it("with empty tag table behaves like detectAdjacency", function()
        local map = pm.newProvinceMap(2, 1)
        map:insertProvince(pm.newProvince(1, {255,0,0}))
        map:insertProvince(pm.newProvince(2, {0,255,0}))
        map:setPixel(0, 0, 1)
        map:setPixel(1, 0, 2)
        pm.detectAdjacencyWithTags(map, {})
        expect_equal(map:adjacencyCount(), 1)
        local edge = map:getAdjacency(1, 2)
        expect_equal(edge.border_length > 0, true)
    end)
end)

describe("adjacencyToGraph", function()
    it("produces nodes and edges from the adjacency table", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(2, 3))
        local g = pm.adjacencyToGraph(map)
        expect_equal(#g.nodes, 3)
        expect_equal(#g.edges, 2)
    end)

    it("nodes are sorted", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(5, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(1, 5))
        local g = pm.adjacencyToGraph(map)
        expect_equal(g.nodes[1], 1)
        expect_equal(g.nodes[2], 2)
        expect_equal(g.nodes[3], 5)
    end)

    it("empty map returns empty graph", function()
        local map = pm.newProvinceMap(10, 10)
        local g = pm.adjacencyToGraph(map)
        expect_equal(#g.nodes, 0)
        expect_equal(#g.edges, 0)
    end)
end)

describe("resolveProvinceColors", function()
    it("source color mode returns normalised rgb", function()
        local map = pm.newProvinceMap(10, 10)
        local p = pm.newProvince(1, {255, 0, 128})
        map:insertProvince(p)
        local mode = pm.newMapMode("src", pm.MapModeColorFn.SourceColor)
        local colors = pm.resolveProvinceColors(map, mode)
        expect_equal(colors[1] ~= nil, true)
        expect_near(colors[1][1], 1.0, 0.01)
        expect_near(colors[1][2], 0.0, 0.01)
        expect_near(colors[1][3], 128/255.0, 0.01)
        expect_equal(colors[1][4], 1.0)
    end)

    it("fixed color mode picks per-province colour", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        local fn = pm.newFixedColorFn({[1] = {0.2, 0.4, 0.6, 1.0}})
        local mode = pm.newMapMode("fixed", fn)
        local colors = pm.resolveProvinceColors(map, mode)
        expect_near(colors[1][1], 0.2, 0.001)
        expect_near(colors[1][2], 0.4, 0.001)
    end)

    it("gradient mode interpolates", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        local fn = pm.newGradientColorFn({[1]=50}, {0,0,0}, {255,255,255}, 0, 100)
        local mode = pm.newMapMode("grad", fn)
        local colors = pm.resolveProvinceColors(map, mode)
        -- value=50 out of 100 => t=0.5 => rgb ~= 127.5/255 ~= 0.5
        expect_near(colors[1][1], 0.5, 0.01)
    end)

    it("category mode resolves by category", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        local fn = pm.newCategoryColorFn({[1]="hot"}, {hot={255,0,0}}, {0,0,0})
        local mode = pm.newMapMode("cat", fn)
        local colors = pm.resolveProvinceColors(map, mode)
        expect_near(colors[1][1], 255/255.0, 0.001)
        expect_near(colors[1][2], 0.0, 0.001)
    end)
end)

test_summary()
