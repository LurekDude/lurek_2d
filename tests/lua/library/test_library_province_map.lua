--- BDD tests for library.province_map
--- Covers: Province, AdjacencyEdge, ProvinceDefinition, BorderSegment,
---         BorderStyle, ProvinceMap, EventBus, MapMode, free functions.

package.path = "./content/library/?/init.lua;" .. package.path

local pm = require("library.province_map")


-- â”€â”€ Province â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies province defaults, ids, colours, terrain metadata, and basic province-level getters or setters.
describe("Province", function()
    -- @covers library.province_map.newProvince
    -- @description Verifies case: new with defaults.
    it("new with defaults", function()
        local p = pm.newProvince(1, {255, 0, 0})
        expect_equal(p.id, 1)
        expect_equal(p.color[1], 255)
        expect_equal(p.area, 0)
        expect_equal(p.name, nil)
    end)

    -- @description Verifies case: fields are writable.
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

-- â”€â”€ AdjacencyEdge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers adjacency edge creation, border metadata, and tag storage for province-to-province connections.
describe("AdjacencyEdge", function()
    -- @covers library.province_map.newAdjacencyEdge
    -- @description Verifies case: new with default fields.
    it("new with default fields", function()
        local e = pm.newAdjacencyEdge(1, 2)
        expect_equal(e.province_a, 1)
        expect_equal(e.province_b, 2)
        expect_equal(e.border_length, 0)
    end)

    -- @description Verifies case: tags can be added and checked.
    it("tags can be added and checked", function()
        local e = pm.newAdjacencyEdge(3, 4)
        pm.addEdgeTag(e, "river")
        expect_equal(pm.hasEdgeTag(e, "river"), true)
        expect_equal(pm.hasEdgeTag(e, "mountain"), false)
    end)
end)

-- â”€â”€ ProvinceDefinition â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests province-definition helpers that capture import-ready province metadata before map insertion.
describe("ProvinceDefinition", function()
    -- @covers library.province_map.newProvinceDefinition
    -- @description Verifies case: new with defaults.
    it("new with defaults", function()
        local d = pm.newProvinceDefinition(1, {10, 20, 30}, {x = 5, y = 10})
        expect_equal(d.id, 1)
        expect_equal(d.color[2], 20)
        expect_equal(d.center.x, 5)
        expect_equal(#d.neighbors, 0)
    end)
end)

-- â”€â”€ BorderSegment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies border-segment construction used for extracted and rendered province boundaries.
describe("BorderSegment", function()
    -- @covers library.province_map.newBorderSegment
    -- @description Verifies case: new with defaults.
    it("new with defaults", function()
        local b = pm.newBorderSegment(1, 2)
        expect_equal(b.province_a, 1)
        expect_equal(b.province_b, 2)
        expect_equal(#b.points, 0)
    end)
end)

-- â”€â”€ BorderStyle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Confirms the border-style enum exposes the expected symbolic styles for map rendering and export.
describe("BorderStyle", function()
    -- @covers library.province_map.BorderStyle
    -- @description Verifies case: new with defaults.
    it("new with defaults", function()
        local s = pm.newBorderStyle()
        expect_equal(s.width, 1.0)
        expect_equal(s.dashed, false)
        expect_equal(#s.color, 4)
    end)
end)

-- â”€â”€ MapMode & ColorFn â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers map-mode creation and the color-function wrappers that drive per-province visualisation.
describe("MapMode", function()
    -- @covers library.province_map.newMapMode
    -- @description Verifies case: new with source color.
    it("new with source color", function()
        local mode = pm.newMapMode("political")
        expect_equal(mode.name, "political")
        expect_equal(mode.color_fn, "source_color")
    end)

    -- @description Verifies case: fixed color fn.
    it("fixed color fn", function()
        local fn = pm.newFixedColorFn({[1] = {255,0,0}})
        expect_equal(fn.type, "fixed")
        expect_equal(fn.colors[1][1], 255)
    end)

    -- @description Verifies case: gradient color fn.
    it("gradient color fn", function()
        local fn = pm.newGradientColorFn({}, {0,0,0}, {255,255,255}, 0, 100)
        expect_equal(fn.type, "gradient")
        expect_equal(fn.max_val, 100)
    end)

    -- @description Verifies case: category color fn.
    it("category color fn", function()
        local fn = pm.newCategoryColorFn({}, {}, {64, 64, 64})
        expect_equal(fn.type, "category")
        expect_equal(fn.default_color[1], 64)
    end)
end)

-- â”€â”€ ProvinceMap â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises core province-map storage including provinces, adjacency, pixels, counts, and direct lookup helpers.
describe("ProvinceMap", function()
    -- @covers library.province_map.newProvinceMap
    -- @description Verifies case: new with dimensions.
    it("new with dimensions", function()
        local map = pm.newProvinceMap(100, 200)
        expect_equal(map:width(), 100)
        expect_equal(map:height(), 200)
        expect_equal(map:provinceCount(), 0)
    end)

    -- @description Verifies case: insertProvince and getProvince.
    it("insertProvince and getProvince", function()
        local map = pm.newProvinceMap(10, 10)
        local p = pm.newProvince(5, {255, 0, 0})
        map:insertProvince(p)
        expect_equal(map:provinceCount(), 1)
        expect_equal(map:getProvince(5).color[1], 255)
        expect_equal(map:getProvince(99), nil)
    end)

    -- @description Verifies case: provinceIds returns sorted list.
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

    -- @description Verifies case: setPixel and getProvinceAt.
    it("setPixel and getProvinceAt", function()
        local map = pm.newProvinceMap(4, 4)
        map:setPixel(1, 2, 7)
        expect_equal(map:getProvinceAt(1, 2), 7)
        expect_equal(map:getProvinceAt(0, 0), nil)
        expect_equal(map:getProvinceAt(-1, 0), nil)
    end)

    -- @description Verifies case: insertAdjacency and getAdjacency.
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

    -- @description Verifies case: getNeighbors returns sorted ids.
    it("getNeighbors returns sorted ids", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 3))
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        local nbrs = map:getNeighbors(1)
        expect_equal(nbrs[1], 2)
        expect_equal(nbrs[2], 3)
    end)

    -- @description Verifies case: distance between centroids.
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

-- â”€â”€ EventBus â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests the province-map event bus for subscriptions, publications, and listener removal flow.
describe("EventBus", function()
    -- @covers library.province_map.newEventBus
    -- @description Verifies case: new starts empty.
    it("new starts empty", function()
        local bus = pm.newEventBus()
        expect_equal(bus:isEmpty(), true)
        expect_equal(bus:poll(), nil)
    end)

    -- @description Verifies case: emit and poll events.
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

    -- @description Verifies case: drain returns all and empties.
    it("drain returns all and empties", function()
        local bus = pm.newEventBus()
        bus:emitProvinceRemoved(1)
        bus:emitAdjacencyDetected(2, 3)
        local all = bus:drain()
        expect_equal(#all, 2)
        expect_equal(bus:isEmpty(), true)
    end)

    -- @description Verifies case: all emit methods work.
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

-- â”€â”€ Free Functions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers free-function helpers that derive adjacency and border data from province-map structures.
describe("Free Functions", function()
    -- @covers library.province_map.detectAdjacency
    -- @covers library.province_map.extractBorders
    -- @description Verifies case: colorToId encodes RGB.
    it("colorToId encodes RGB", function()
        expect_equal(pm.colorToId(255, 0, 0), 16711680)
        expect_equal(pm.colorToId(0, 255, 0), 65280)
        expect_equal(pm.colorToId(0, 0, 255), 255)
        expect_equal(pm.colorToId(1, 2, 3), 66051)
    end)

    -- @description Verifies case: loadFromDefinitions builds map.
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

    -- @description Verifies case: detectAdjacency scans pixel grid.
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

    -- @description Verifies case: extractAllBorders returns segments.
    it("extractAllBorders returns segments", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(2, 3))
        local borders = pm.extractAllBorders(map)
        expect_equal(#borders, 2)
    end)

    -- @description Verifies case: extractBordersWithTag filters by tag.
    it("extractBordersWithTag filters by tag", function()
        local map = pm.newProvinceMap(10, 10)
        local e1 = pm.newAdjacencyEdge(1, 2)
        e1.tags["river"] = true
        map:insertAdjacency(e1)
        map:insertAdjacency(pm.newAdjacencyEdge(2, 3))
        local rivers = pm.extractBordersWithTag(map, "river")
        expect_equal(#rivers, 1)
    end)

    -- @description Verifies case: calculateCapital returns centroid.
    it("calculateCapital returns centroid", function()
        local map = pm.newProvinceMap(10, 10)
        local p = pm.newProvince(1, {0,0,0})
        p.centroid = {x = 25, y = 35}
        map:insertProvince(p)
        local cap = pm.calculateCapital(map, 1)
        expect_equal(cap.x, 25)
        expect_equal(cap.y, 35)
    end)

    -- @description Verifies case: calculateAllPositions syncs center to centroid.
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

-- â”€â”€ Province extended â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies province faction, defense, building, and resource helpers that extend province state beyond its base identity.
describe("Province.faction", function()
    -- @covers library.province_map.newProvince
    -- @description Verifies case: setFaction / getFaction.
    it("setFaction / getFaction", function()
        local p = pm.newProvince(1, {0,0,0})
        expect_equal(p:getFaction(), nil)
        p:setFaction("blue")
        expect_equal(p:getFaction(), "blue")
    end)

    -- @description Verifies case: setDefenseRating / getDefenseRating.
    it("setDefenseRating / getDefenseRating", function()
        local p = pm.newProvince(1, {0,0,0})
        p:setDefenseRating(75)
        expect_equal(p:getDefenseRating(), 75)
    end)

    -- @description Verifies case: addBuilding / hasBuilding / getBuildings / removeBuilding.
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

    -- @description Verifies case: setResource / getResource / getResources.
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

-- â”€â”€ ProvinceMap extended â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests route finding across direct, chained, blocked, and unreachable province graphs, including passable-edge predicates.
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

    -- @description Verifies case: direct adjacency returns two-element path.
    it("direct adjacency returns two-element path", function()
        local map = make_chain(2)
        local path = map:findRoute(1, 2)
        expect_equal(#path, 2)
        expect_equal(path[1], 1)
        expect_equal(path[2], 2)
    end)

    -- @description Verifies case: chain path returns ordered ids.
    it("chain path returns ordered ids", function()
        local map = make_chain(4)
        local path = map:findRoute(1, 4)
        expect_equal(path[1], 1)
        expect_equal(path[#path], 4)
        expect_equal(#path, 4)
    end)

    -- @description Verifies case: same province returns single-element path.
    it("same province returns single-element path", function()
        local map = make_chain(3)
        local path = map:findRoute(2, 2)
        expect_equal(#path, 1)
        expect_equal(path[1], 2)
    end)

    -- @description Verifies case: unreachable returns nil.
    it("unreachable returns nil", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(5, {0,0,0}))
        expect_equal(map:findRoute(1, 5), nil)
    end)

    -- @description Verifies case: passable_fn can block an edge.
    it("passable_fn can block an edge", function()
        local map = make_chain(3)
        -- block 1-2 edge
        local path = map:findRoute(1, 3, function(e)
            return not (e.province_a == 1 and e.province_b == 2)
        end)
        expect_equal(path, nil)
    end)
end)

-- @description Covers faction-centric queries such as province listing, per-faction resource totals, and uncontrolled province discovery.
describe("ProvinceMap.faction_queries", function()
    -- @covers library.province_map.newProvinceMap
    -- @description Verifies case: getProvincesByFaction returns matching IDs.
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

    -- @description Verifies case: totalResourceForFaction sums across provinces.
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

    -- @description Verifies case: getUncontrolledProvinces.
    it("getUncontrolledProvinces", function()
        local map = pm.newProvinceMap(10, 10)
        local a = pm.newProvince(1, {0,0,0}); a:setFaction("red"); map:insertProvince(a)
        local b = pm.newProvince(2, {0,0,0}); map:insertProvince(b)
        local unc = map:getUncontrolledProvinces()
        expect_equal(#unc, 1)
        expect_equal(unc[1], 2)
    end)
end)

-- @description Verifies adjacency creation and in-place edge tag updates through the setAdjacent convenience helper.
describe("ProvinceMap.setAdjacent", function()
    -- @covers library.province_map.newProvinceMap
    -- @description Verifies case: creates new edge.
    it("creates new edge", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        local edge = map:setAdjacent(1, 2, {river = true})
        expect_equal(edge ~= nil, true)
        expect_equal(edge.tags.river, true)
        expect_equal(map:adjacencyCount(), 1)
    end)

    -- @description Verifies case: updates existing edge with new tags.
    it("updates existing edge with new tags", function()
        local map = pm.newProvinceMap(10, 10)
        map:setAdjacent(1, 2, {road = true})
        map:setAdjacent(1, 2, {wall = true})
        local edge = map:getAdjacency(1, 2)
        expect_equal(edge.tags.road, true)
        expect_equal(edge.tags.wall, true)
    end)
end)

-- @description Tests graph-analysis helpers that find isolated provinces and connected components from adjacency data.
describe("ProvinceMap.graph_analysis", function()
    -- @covers library.province_map.newProvinceMap
    -- @description Verifies case: findIsolatedProvinces returns unconnected ids.
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

    -- @description Verifies case: getConnectedComponents partitions provinces.
    it("getConnectedComponents partitions provinces", function()
        local map = pm.newProvinceMap(10, 10)
        for i = 1, 4 do map:insertProvince(pm.newProvince(i, {0,0,0})) end
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(3, 4))
        local comps = map:getConnectedComponents()
        expect_equal(#comps, 2)
    end)
end)

-- @description Covers direct application of gradient and category colour functions to province ids.
describe("ColorFn_apply", function()
    -- @covers library.province_map.applyGradientColor
    -- @covers library.province_map.applyCategoryColor
    -- @description Verifies case: applyGradientColor interpolates.
    it("applyGradientColor interpolates", function()
        local fn = pm.newGradientColorFn({[1]=0}, {0,0,0}, {255,255,255}, 0, 100)
        local c0 = pm.applyGradientColor(fn, 1)
        expect_equal(c0[1], 0)
        fn.values[1] = 100
        local c1 = pm.applyGradientColor(fn, 1)
        expect_equal(c1[1], 255)
    end)

    -- @description Verifies case: applyCategoryColor selects by category.
    it("applyCategoryColor selects by category", function()
        local fn = pm.newCategoryColorFn(
            {[1]="hot"}, {hot={255,0,0}}, {0,0,0})
        local c = pm.applyCategoryColor(fn, 1)
        expect_equal(c[1], 255)
        local def = pm.applyCategoryColor(fn, 99)
        expect_equal(def[1], 0)
    end)
end)

-- @description Verifies faction enumeration returns unique faction names in sorted order.
describe("allFactions", function()
    -- @covers library.province_map.allFactions
    -- @description Verifies case: returns sorted faction list.
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

-- â”€â”€ Gap coverage â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests province removal for both existing and missing province ids.
describe("ProvinceMap.removeProvince", function()
    -- @covers library.province_map.newProvinceMap
    -- @description Verifies case: removes an existing province and returns true.
    it("removes an existing province and returns true", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(7, {0,0,0}))
        expect_equal(map:provinceCount(), 1)
        expect_equal(map:removeProvince(7), true)
        expect_equal(map:provinceCount(), 0)
        expect_equal(map:getProvince(7), nil)
    end)

    -- @description Verifies case: returns false for missing province.
    it("returns false for missing province", function()
        local map = pm.newProvinceMap(10, 10)
        expect_equal(map:removeProvince(99), false)
    end)
end)

-- @description Covers adjacency removal, including symmetric edge ids and missing-edge behavior.
describe("ProvinceMap.removeAdjacency", function()
    -- @covers library.province_map.newProvinceMap
    -- @description Verifies case: removes an existing edge and returns true.
    it("removes an existing edge and returns true", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        expect_equal(map:adjacencyCount(), 1)
        expect_equal(map:removeAdjacency(1, 2), true)
        expect_equal(map:adjacencyCount(), 0)
        expect_equal(map:getAdjacency(1, 2), nil)
    end)

    -- @description Verifies case: symmetric: removeAdjacency(b, a) also works.
    it("symmetric: removeAdjacency(b, a) also works", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(3, 5))
        expect_equal(map:removeAdjacency(5, 3), true)
    end)

    -- @description Verifies case: returns false for missing edge.
    it("returns false for missing edge", function()
        local map = pm.newProvinceMap(10, 10)
        expect_equal(map:removeAdjacency(1, 2), false)
    end)
end)

-- @description Verifies the totalEdgeCount helper mirrors the map's adjacency count.
describe("totalEdgeCount", function()
    -- @covers library.province_map.totalEdgeCount
    -- @description Verifies case: mirrors adjacencyCount.
    it("mirrors adjacencyCount", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(2, 3))
        expect_equal(pm.totalEdgeCount(map), 2)
        expect_equal(pm.totalEdgeCount(map), map:adjacencyCount())
    end)
end)

-- @description Tests direct access to the internal pixel lookup table after province ids are written into map pixels.
describe("ProvinceMap.pixelLookup", function()
    -- @covers library.province_map.newProvinceMap
    -- @description Verifies case: returns the internal lookup table.
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

-- @description Verifies border extraction filtered by province properties only returns segments where the derived property differs across the edge.
describe("extractBordersByProperty", function()
    -- @covers library.province_map.extractBordersByProperty
    -- @description Verifies case: returns segments where property differs.
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

    -- @description Verifies case: returns empty when all properties match.
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

-- @description Covers adjacency detection that also maps special tag pixels into edge tags such as rivers.
describe("detectAdjacencyWithTags", function()
    -- @covers library.province_map.detectAdjacencyWithTags
    -- @description Verifies case: detects normal adjacency and tags edges via tag pixels.
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

    -- @description Verifies case: with empty tag table behaves like detectAdjacency.
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

-- @description Tests graph conversion from map adjacency data, including sorted nodes and empty-map behavior.
describe("adjacencyToGraph", function()
    -- @covers library.province_map.adjacencyToGraph
    -- @description Verifies case: produces nodes and edges from the adjacency table.
    it("produces nodes and edges from the adjacency table", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(2, 3))
        local g = pm.adjacencyToGraph(map)
        expect_equal(#g.nodes, 3)
        expect_equal(#g.edges, 2)
    end)

    -- @description Verifies case: nodes are sorted.
    it("nodes are sorted", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertAdjacency(pm.newAdjacencyEdge(5, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(1, 5))
        local g = pm.adjacencyToGraph(map)
        expect_equal(g.nodes[1], 1)
        expect_equal(g.nodes[2], 2)
        expect_equal(g.nodes[3], 5)
    end)

    -- @description Verifies case: empty map returns empty graph.
    it("empty map returns empty graph", function()
        local map = pm.newProvinceMap(10, 10)
        local g = pm.adjacencyToGraph(map)
        expect_equal(#g.nodes, 0)
        expect_equal(#g.edges, 0)
    end)
end)

-- @description Verifies province color resolution for source, fixed, gradient, and category-based map modes.
describe("resolveProvinceColors", function()
    -- @covers library.province_map.resolveProvinceColors
    -- @description Verifies case: source color mode returns normalised rgb.
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

    -- @description Verifies case: fixed color mode picks per-province colour.
    it("fixed color mode picks per-province colour", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        local fn = pm.newFixedColorFn({[1] = {0.2, 0.4, 0.6, 1.0}})
        local mode = pm.newMapMode("fixed", fn)
        local colors = pm.resolveProvinceColors(map, mode)
        expect_near(colors[1][1], 0.2, 0.001)
        expect_near(colors[1][2], 0.4, 0.001)
    end)

    -- @description Verifies case: gradient mode interpolates.
    it("gradient mode interpolates", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        local fn = pm.newGradientColorFn({[1]=50}, {0,0,0}, {255,255,255}, 0, 100)
        local mode = pm.newMapMode("grad", fn)
        local colors = pm.resolveProvinceColors(map, mode)
        -- value=50 out of 100 => t=0.5 => rgb ~= 127.5/255 ~= 0.5
        expect_near(colors[1][1], 0.5, 0.01)
    end)

    -- @description Verifies case: category mode resolves by category.
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

-- ── Adjacency bidirectionality ────────────────────────────────────────────

-- @description Verifies that adjacency edges are bidirectional and normalised.
describe("Adjacency.bidirectionality", function()
    -- @description Verifies case: insertAdjacency normalises edge direction.
    it("insertAdjacency normalises edge direction", function()
        local map = pm.newProvinceMap(10, 10)
        -- Manually create an edge with reversed order (5 > 2).
        local edge = { province_a = 5, province_b = 2, border_length = 0,
                       border_segments = {}, tags = {}, passable = true, movement_cost = 1.0 }
        map:insertAdjacency(edge)
        -- After insertion, province_a should be the smaller ID.
        expect_equal(edge.province_a, 2)
        expect_equal(edge.province_b, 5)
        -- Lookup works from both directions.
        expect_equal(map:getAdjacency(2, 5) ~= nil, true)
        expect_equal(map:getAdjacency(5, 2) ~= nil, true)
    end)

    -- @description Verifies case: setAdjacent stores normalised edge.
    it("setAdjacent stores normalised edge", function()
        local map = pm.newProvinceMap(10, 10)
        local edge = map:setAdjacent(10, 3)
        expect_equal(edge.province_a, 3)
        expect_equal(edge.province_b, 10)
    end)

    -- @description Verifies case: getNeighbors returns both sides of an edge.
    it("getNeighbors returns both sides of an edge", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        map:setAdjacent(1, 2)
        -- Querying from either side should find the other.
        local nbrs1 = map:getNeighbors(1)
        local nbrs2 = map:getNeighbors(2)
        expect_equal(#nbrs1, 1)
        expect_equal(nbrs1[1], 2)
        expect_equal(#nbrs2, 1)
        expect_equal(nbrs2[1], 1)
    end)
end)

-- ── Pixel coordinate system ───────────────────────────────────────────────

-- @description Verifies pixel coordinate system, 0-based addressing, and auto-adjacency on setPixel.
describe("Pixel.coordinates", function()
    -- @description Verifies case: pixel_lookup uses 1-based index internally.
    it("pixel_lookup uses 1-based index internally", function()
        local map = pm.newProvinceMap(3, 3)
        map:setPixel(0, 0, 10)   -- index = 0*3 + 0 + 1 = 1
        map:setPixel(2, 1, 20)   -- index = 1*3 + 2 + 1 = 6
        local tbl = map:pixelLookup()
        expect_equal(tbl[1], 10)
        expect_equal(tbl[6], 20)
    end)

    -- @description Verifies case: out-of-bounds setPixel is silently ignored.
    it("out-of-bounds setPixel is silently ignored", function()
        local map = pm.newProvinceMap(2, 2)
        map:setPixel(-1, 0, 1)
        map:setPixel(0, 2, 1)
        map:setPixel(2, 0, 1)
        -- No pixels should be set.
        expect_equal(map:getProvinceAt(0, 0), nil)
    end)

    -- @description Verifies case: setPixel auto-detects adjacency bidirectionally.
    it("setPixel auto-detects adjacency bidirectionally", function()
        local map = pm.newProvinceMap(3, 1)
        map:setPixel(0, 0, 1)
        map:setPixel(2, 0, 2)
        -- No adjacency yet (pixels are not neighbours).
        expect_equal(map:adjacencyCount(), 0)
        -- Set middle pixel to province 3 — adjacent to both 1 and 2.
        map:setPixel(1, 0, 3)
        expect_equal(map:getAdjacency(1, 3) ~= nil, true)
        expect_equal(map:getAdjacency(2, 3) ~= nil, true)
    end)

    -- @description Verifies case: setPixel adjacency checks all four directions.
    it("setPixel adjacency checks all four directions", function()
        local map = pm.newProvinceMap(3, 3)
        -- Place province 1 at center neighbours.
        map:setPixel(1, 0, 1)  -- above
        map:setPixel(0, 1, 1)  -- left
        map:setPixel(2, 1, 1)  -- right
        map:setPixel(1, 2, 1)  -- below
        -- Place province 2 in the center — should detect adjacency with 1.
        map:setPixel(1, 1, 2)
        local edge = map:getAdjacency(1, 2)
        expect_equal(edge ~= nil, true)
    end)
end)

-- ── Input validation ──────────────────────────────────────────────────────

-- @description Verifies that invalid inputs are rejected with assertions.
describe("Input.validation", function()
    -- @description Verifies case: newProvince rejects non-number id.
    it("newProvince rejects non-number id", function()
        expect_error(function() pm.newProvince("bad", {0,0,0}) end)
    end)

    -- @description Verifies case: newAdjacencyEdge rejects non-number ids.
    it("newAdjacencyEdge rejects non-number ids", function()
        expect_error(function() pm.newAdjacencyEdge("a", 1) end)
    end)

    -- @description Verifies case: setFaction rejects non-string, non-nil.
    it("setFaction rejects non-string, non-nil", function()
        local p = pm.newProvince(1, {0,0,0})
        expect_error(function() p:setFaction(123) end)
    end)

    -- @description Verifies case: setResource rejects negative amount.
    it("setResource rejects negative amount", function()
        local p = pm.newProvince(1, {0,0,0})
        expect_error(function() p:setResource("gold", -5) end)
    end)

    -- @description Verifies case: colorToId rejects out-of-range values.
    it("colorToId rejects out-of-range values", function()
        expect_error(function() pm.colorToId(256, 0, 0) end)
        expect_error(function() pm.colorToId(0, -1, 0) end)
    end)

    -- @description Verifies case: setAdjacent rejects non-number ids.
    it("setAdjacent rejects non-number ids", function()
        local map = pm.newProvinceMap(10, 10)
        expect_error(function() map:setAdjacent("a", 1) end)
    end)

    -- @description Verifies case: findRoute rejects non-number ids.
    it("findRoute rejects non-number ids", function()
        local map = pm.newProvinceMap(10, 10)
        expect_error(function() map:findRoute("a", 1) end)
    end)
end)

-- ── Route finding edge cases ──────────────────────────────────────────────

-- @description Additional route finding edge cases beyond the basic suite.
describe("ProvinceMap.findRoute.edge_cases", function()
    -- @description Verifies case: route avoids impassable edge.
    it("route avoids impassable edge and takes detour", function()
        -- Diamond: 1-2, 1-3, 2-4, 3-4.  Block 1-2 edge.
        local map = pm.newProvinceMap(10, 10)
        for i = 1, 4 do map:insertProvince(pm.newProvince(i, {0,0,0})) end
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(1, 3))
        map:insertAdjacency(pm.newAdjacencyEdge(2, 4))
        map:insertAdjacency(pm.newAdjacencyEdge(3, 4))
        -- Block 1→2 direct edge.
        local path = map:findRoute(1, 4, function(e)
            return not (e.province_a == 1 and e.province_b == 2)
        end)
        expect_equal(path ~= nil, true)
        expect_equal(path[1], 1)
        expect_equal(path[#path], 4)
        -- Detour goes through 3.
        expect_equal(path[2], 3)
    end)

    -- @description Verifies case: route through single-node graph.
    it("route through single-node graph", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(42, {0,0,0}))
        local path = map:findRoute(42, 42)
        expect_equal(#path, 1)
        expect_equal(path[1], 42)
    end)

    -- @description Verifies case: route in disconnected components returns nil.
    it("route in disconnected components returns nil", function()
        local map = pm.newProvinceMap(10, 10)
        for i = 1, 4 do map:insertProvince(pm.newProvince(i, {0,0,0})) end
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        map:insertAdjacency(pm.newAdjacencyEdge(3, 4))
        expect_equal(map:findRoute(1, 4), nil)
    end)

    -- @description Verifies case: all edges impassable returns nil.
    it("all edges impassable returns nil", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        map:insertAdjacency(pm.newAdjacencyEdge(1, 2))
        local path = map:findRoute(1, 2, function() return false end)
        expect_equal(path, nil)
    end)
end)

-- ── Dual representation sync ──────────────────────────────────────────────

-- @description Verifies that adjacency and getNeighbors stay in sync across all mutation paths.
describe("DualRepresentation.sync", function()
    -- @description Verifies case: setAdjacent is reflected in getNeighbors.
    it("setAdjacent is reflected in getNeighbors", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        map:insertProvince(pm.newProvince(3, {0,0,0}))
        map:setAdjacent(1, 2)
        map:setAdjacent(1, 3)
        local nbrs = map:getNeighbors(1)
        expect_equal(#nbrs, 2)
        expect_equal(nbrs[1], 2)
        expect_equal(nbrs[2], 3)
    end)

    -- @description Verifies case: removeAdjacency removes from getNeighbors.
    it("removeAdjacency removes from getNeighbors", function()
        local map = pm.newProvinceMap(10, 10)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        map:setAdjacent(1, 2)
        expect_equal(#map:getNeighbors(1), 1)
        map:removeAdjacency(1, 2)
        expect_equal(#map:getNeighbors(1), 0)
    end)

    -- @description Verifies case: pixel-based adjacency is visible in getNeighbors.
    it("pixel-based adjacency is visible in getNeighbors", function()
        local map = pm.newProvinceMap(2, 1)
        map:insertProvince(pm.newProvince(1, {0,0,0}))
        map:insertProvince(pm.newProvince(2, {0,0,0}))
        map:setPixel(0, 0, 1)
        map:setPixel(1, 0, 2)
        -- setPixel auto-creates adjacency edges.
        local nbrs = map:getNeighbors(1)
        expect_equal(#nbrs, 1)
        expect_equal(nbrs[1], 2)
    end)

    -- @description Verifies case: detectAdjacency edges are visible in getNeighbors.
    it("detectAdjacency edges are visible in getNeighbors", function()
        local map = pm.newProvinceMap(2, 1)
        map:insertProvince(pm.newProvince(10, {0,0,0}))
        map:insertProvince(pm.newProvince(20, {0,0,0}))
        -- Use raw pixel_lookup to bypass auto-adjacency, then detect manually.
        map.pixel_lookup[1] = 10
        map.pixel_lookup[2] = 20
        pm.detectAdjacency(map)
        local nbrs = map:getNeighbors(10)
        expect_equal(#nbrs, 1)
        expect_equal(nbrs[1], 20)
    end)
end)

test_summary()
