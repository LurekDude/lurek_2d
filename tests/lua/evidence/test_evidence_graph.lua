-- test_evidence_graph.lua
-- Evidence test: lurek.graph Graph API contracts and PNG visual network evidence

local OUT = "tests/lua/evidence/output/graph/"

-- ── helpers ──────────────────────────────────────────────────────────────────

--- Build a graph from a position table and edge list.
--- positions: array of {x, y}
--- edges: array of {from_idx, to_idx}
--- Returns graph, nodes_array
local function build_graph(positions, edges)
    local g = lurek.graph.newGraph()
    local nodes = {}
    for i, pos in ipairs(positions) do
        local n = g:addNode()
        -- Store world position as node metadata
        n:setLabel(tostring(i))
        n:setX(pos.x)
        n:setY(pos.y)
        nodes[i] = n
    end
    for _, e in ipairs(edges) do
        g:addEdge(nodes[e[1]], nodes[e[2]])
    end
    return g, nodes
end

--- Render a graph as a PNG.
--- nodes_array: array of LuaNode with getX/getY
--- path: optional path table from findPath (array of Nodes in .nodes)
local function draw_graph(nodes_arr, edges_arr, path_nodes, iw, ih)
    local img = lurek.image.newImageData(iw, ih)
    img:fill(15, 20, 30, 255)

    -- Build set of path node indices for highlighting
    local path_set = {}
    if path_nodes then
        for _, n in ipairs(path_nodes) do
            path_set[n:getLabel()] = true
        end
    end

    -- Draw edges
    for _, e in ipairs(edges_arr) do
        local fn = e[1]
        local tn = e[2]
        local x1 = math.floor(fn:getX())
        local y1 = math.floor(fn:getY())
        local x2 = math.floor(tn:getX())
        local y2 = math.floor(tn:getY())
        img:drawLine(x1, y1, x2, y2, 60, 80, 100, 255)
    end

    -- Draw nodes
    for _, n in ipairs(nodes_arr) do
        local nx = math.floor(n:getX())
        local ny = math.floor(n:getY())
        local lbl = n:getLabel()
        local is_path = path_set[lbl]
        local r, g, b = 80, 120, 200
        if is_path then r, g, b = 220, 160, 60 end
        img:drawCircle(nx, ny, 5, r, g, b, 255)
        img:drawCircle(nx, ny, 3, 255, 255, 255, 255)
    end

    return img
end

-- ── tests ────────────────────────────────────────────────────────────────────

describe("Evidence: lurek.graph Graph creation", function()

    it("newGraph creates a Graph object", function()
        local g = lurek.graph.newGraph()
        expect_equal(g ~= nil, true)
        expect_equal(g:type(), "Graph")
    end)

    it("addNode returns a Node handle", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal(n ~= nil, true)
        expect_equal(n:type(), "Node")
    end)

    it("getNodeCount reflects additions", function()
        local g = lurek.graph.newGraph()
        expect_equal(g:getNodeCount(), 0)
        g:addNode()
        g:addNode()
        g:addNode()
        expect_equal(g:getNodeCount(), 3)
    end)

    it("addEdge / getEdgeCount reflect additions", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        expect_equal(g:getEdgeCount(), 0)
        g:addEdge(a, b)
        expect_equal(g:getEdgeCount(), 1)
    end)

    it("removeNode / hasNode round-trip", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        expect_equal(g:hasNode(n), true)
        g:removeNode(n)
        expect_equal(g:hasNode(n), false)
    end)

    it("hasEdge returns false after removeEdge", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local e = g:addEdge(a, b)
        expect_equal(g:hasEdge(e), true)
        g:removeEdge(e)
        expect_equal(g:hasEdge(e), false)
    end)
end)

describe("Evidence: lurek.graph findPath Dijkstra", function()

    it("findPath finds a path in a linear chain", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        local c = g:addNode()
        g:addEdge(a, b)
        g:addEdge(b, c)

        local result = g:findPath(a, c)
        expect_equal(result ~= nil, true)
        expect_equal(#result.nodes >= 2, true)
    end)

    it("findPath returns nil when no path exists", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        -- No edges between a and b
        local result = g:findPath(a, b)
        expect_equal(result == nil, true)
    end)

    it("getDistance returns correct hop count on unweighted chain", function()
        local g = lurek.graph.newGraph()
        local nodes = {}
        for i = 1, 5 do nodes[i] = g:addNode() end
        for i = 1, 4 do g:addEdge(nodes[i], nodes[i+1]) end

        local dist = g:getDistance(nodes[1], nodes[5])
        expect_equal(dist ~= nil, true)
        expect_equal(dist >= 4, true)  -- at least 4 hops
    end)

    it("getNeighbors returns direct connections", function()
        local g = lurek.graph.newGraph()
        local hub = g:addNode()
        local s1  = g:addNode()
        local s2  = g:addNode()
        local s3  = g:addNode()
        g:addEdge(hub, s1)
        g:addEdge(hub, s2)
        g:addEdge(hub, s3)

        local nb = g:getNeighbors(hub)
        expect_equal(#nb, 3)
    end)

    it("getReachable returns all nodes in connected graph", function()
        local g = lurek.graph.newGraph()
        local nodes = {}
        for i = 1, 6 do nodes[i] = g:addNode() end
        for i = 1, 5 do g:addEdge(nodes[i], nodes[i+1]) end

        local reachable = g:getReachable(nodes[1])
        expect_equal(#reachable >= 5, true)
    end)

    it("getComponents detects disconnected subgraphs", function()
        local g = lurek.graph.newGraph()
        -- Two separate chains
        local a1 = g:addNode()
        local a2 = g:addNode()
        g:addEdge(a1, a2)

        local b1 = g:addNode()
        local b2 = g:addNode()
        g:addEdge(b1, b2)

        local comps = g:getComponents()
        expect_equal(#comps, 2)
    end)
end)

describe("Evidence: lurek.graph visual network PNG", function()

    it("ring topology — PNG evidence: ring_graph", function()
        -- 8-node ring
        local N = 8
        local R = 90
        local CX, CY = 120, 120
        local positions = {}
        for i = 1, N do
            local angle = (i - 1) / N * 2 * math.pi
            positions[i] = {
                x = CX + math.floor(R * math.cos(angle)),
                y = CY + math.floor(R * math.sin(angle))
            }
        end
        local edge_def = {}
        for i = 1, N do
            edge_def[i] = {i, i % N + 1}
        end

        local g = lurek.graph.newGraph()
        local nodes = {}
        for i, pos in ipairs(positions) do
            local n = g:addNode()
            n:setLabel(tostring(i))
            n:setX(pos.x)
            n:setY(pos.y)
            nodes[i] = n
        end
        local edges = {}
        for _, e in ipairs(edge_def) do
            local ed = g:addEdge(nodes[e[1]], nodes[e[2]])
            edges[#edges+1] = {nodes[e[1]], nodes[e[2]]}
        end

        local path_result = g:findPath(nodes[1], nodes[5])
        local path_nodes  = path_result and path_result.nodes or nil

        local img = draw_graph(nodes, edges, path_nodes, 240, 240)
        lurek.image.savePNG(img, OUT .. "evidence_graph_ring.png")
    end)

    it("hub-and-spoke topology — PNG evidence: hub_graph", function()
        local CX, CY = 120, 120
        local R = 80
        local SPOKES = 6

        local g = lurek.graph.newGraph()
        local hub = g:addNode()
        hub:setLabel("H")
        hub:setX(CX)
        hub:setY(CY)

        local spoke_nodes = {hub}
        local edges = {}

        for i = 1, SPOKES do
            local angle = (i - 1) / SPOKES * 2 * math.pi
            local n = g:addNode()
            n:setLabel(tostring(i))
            n:setX(CX + math.floor(R * math.cos(angle)))
            n:setY(CY + math.floor(R * math.sin(angle)))
            spoke_nodes[#spoke_nodes+1] = n
            g:addEdge(hub, n)
            edges[#edges+1] = {hub, n}
            -- Cross edges between spokes
            if i > 1 then
                g:addEdge(spoke_nodes[i], n)
                edges[#edges+1] = {spoke_nodes[i], n}
            end
        end

        -- Path from spoke 1 to spoke 4
        local path_result = g:findPath(spoke_nodes[2], spoke_nodes[5])
        local path_nodes  = path_result and path_result.nodes or nil

        local img = draw_graph(spoke_nodes, edges, path_nodes, 240, 240)
        lurek.image.savePNG(img, OUT .. "evidence_graph_hub.png")
    end)
end)

describe("Evidence: lurek.graph item flow", function()

    it("createItem / addItem / getItems round-trip", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        local item = g:createItem("ore", -1)
        local ok = g:addItem(item, n)
        expect_equal(ok, true)
        expect_equal(g:hasItem(item), true)
    end)

    it("removeItem removes the item", function()
        local g = lurek.graph.newGraph()
        local n = g:addNode()
        local item = g:createItem("ore", -1)
        g:addItem(item, n)
        g:removeItem(item)
        expect_equal(g:hasItem(item), false)
    end)
end)

test_summary()
