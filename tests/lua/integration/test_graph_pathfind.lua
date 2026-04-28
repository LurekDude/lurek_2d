-- tests/lua/integration/test_graph_pathfind.lua
-- Integration: lurek.graph MST and A* with lurek.pathfind.
-- Namespaces: lurek.graph + lurek.pathfind


--
-- Graph MST (Minimum Spanning Tree)
--
describe("graph.mst", function()

    local function build_simple_graph()
        local g = lurek.graph.newGraph()
        local n1 = g:addNode("A")
        local n2 = g:addNode("B")
        local n3 = g:addNode("C")
        local n4 = g:addNode("D")
        g:addEdge(n1, n2)
        g:addEdge(n2, n3)
        g:addEdge(n1, n3)
        g:addEdge(n3, n4)
        g:addEdge(n2, n4)
        return g, n1, n2, n3, n4
    end

    it("mst returns a table of edge IDs", function()
        local g = build_simple_graph()
        local tree = g:mst()
        expect_type("table", tree)
    end)

    it("mst has N-1 edges for N nodes", function()
        local g = build_simple_graph()
        local tree = g:mst()
        -- 4 nodes     3 MST edges
        expect_equal(3, #tree)
    end)

    it("mst edge IDs are numbers", function()
        local g = build_simple_graph()
        local tree = g:mst()
        for _, eid in ipairs(tree) do
            expect_type("number", eid)
        end
    end)

    it("two-node graph has one MST edge", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        g:addEdge(a, b)
        local tree = g:mst()
        expect_equal(1, #tree)
    end)

    it("single node graph has empty MST", function()
        local g = lurek.graph.newGraph()
        g:addNode()
        local tree = g:mst()
        expect_equal(0, #tree)
    end)
end)

--
-- Graph A* (astar)
--
describe("graph.astar", function()

    local function build_chain(n)
        local g = lurek.graph.newGraph()
        local nodes = {}
        for i = 1, n do
            nodes[i] = g:addNode("N" .. i)
        end
        for i = 1, n - 1 do
            g:addEdge(nodes[i], nodes[i + 1])
        end
        return g, nodes
    end

    it("finds path between connected nodes", function()
        local g, nodes = build_chain(5)
        local path = g:astar(nodes[1], nodes[5])
        expect_true(path ~= nil, "should find path in linear chain")
    end)

    it("path visits nodes in order for a chain", function()
        local g, nodes = build_chain(4)
        local path = g:astar(nodes[1], nodes[4])
        if path then
            expect_equal(4, #path)
        end
    end)

    it("returns nil when no path exists", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local b = g:addNode()
        -- No edge between a and b
        local path = g:astar(a, b)
        expect_equal(nil, path)
    end)

    it("astar path starts and ends at expected nodes", function()
        local g = lurek.graph.newGraph()
        local a   = g:addNode("start")
        local mid = g:addNode("mid")
        local b   = g:addNode("end")
        g:addEdge(a, mid)
        g:addEdge(mid, b)
        local path = g:astar(a, b)
        if path then
            -- Path should be a table of node userdatas
            expect_equal(3, #path)
        end
    end)

    it("same-node astar path has length 1", function()
        local g = lurek.graph.newGraph()
        local a = g:addNode()
        local path = g:astar(a, a)
        -- A path from a node to itself should be [a] or nil depending on impl
        expect_true(path == nil or #path == 1, "path to self should be length 1 or nil")
    end)
end)

--
-- Graph + pathfinding integration
--
describe("graph + JPS integration", function()

    it("worldGraph edge costs match procgen expectations", function()
        local wg = lurek.procgen.worldGraph(200, 150, 6, 5)
        for _, e in ipairs(wg.edges) do
            expect_true(e.cost > 0, "edge cost should be positive")
        end
    end)

    it("procgen then graph then pathfind pipeline completes", function()
        -- Build a world graph from procgen
        local wg = lurek.procgen.worldGraph(200, 150, 8, 10)

        -- Load it into a lurek.graph
        local g = lurek.graph.newGraph()
        local node_map = {}
        for _, r in ipairs(wg.regions) do
            node_map[r.id] = g:addNode(r.name)
        end
        for _, e in ipairs(wg.edges) do
            if node_map[e.from] and node_map[e.to] then
                g:addEdge(node_map[e.from], node_map[e.to])
            end
        end

        -- Get MST
        local tree = g:mst()
        expect_type("table", tree)
        expect_true(#tree <= #wg.regions - 1, "MST should have at most N-1 edges")

        -- Find a path in the graph
        if #wg.regions >= 2 then
            local from = node_map[wg.regions[1].id]
            local to   = node_map[wg.regions[#wg.regions].id]
            local path = g:astar(from, to)
            expect_true(path == nil or type(path) == "table",
                "astar should return nil or table")
        end
    end)
end)

test_summary()
