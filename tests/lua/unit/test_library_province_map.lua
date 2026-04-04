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

test_summary()
