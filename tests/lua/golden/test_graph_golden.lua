-- Lurek2D Golden Test: Graph Algorithms on Fixed Graphs
-- Tests BFS/DFS/Dijkstra produce deterministic traversal results.
-- @golden lurek.graph.newGraph
-- @golden lurek.graph.addNode
-- @golden lurek.graph.addEdge
-- @golden lurek.graph.bfs
-- @golden lurek.graph.dfs
-- @golden lurek.graph.dijkstra
-- @golden lurek.graph.hasCycle

describe("golden: BFS traversal on simple tree", function()
    it("BFS from root visits all nodes", function()
        local g = lurek.graph.newGraph()
        g:addNode("A")
        g:addNode("B")
        g:addNode("C")
        g:addNode("D")
        g:addEdge("A", "B", 1)
        g:addEdge("A", "C", 1)
        g:addEdge("B", "D", 1)

        local visited = g:bfs("A")
        expect_not_nil(visited, "BFS returned result")
        -- All 4 nodes should be visited
        expect_equal(4, #visited, "BFS visits all 4 nodes")
        -- First node is always the root
        expect_equal("A", visited[1], "BFS starts at root A")
    end)
end)

describe("golden: DFS traversal on simple tree", function()
    it("DFS from root visits all nodes", function()
        local g = lurek.graph.newGraph()
        g:addNode("A")
        g:addNode("B")
        g:addNode("C")
        g:addEdge("A", "B", 1)
        g:addEdge("A", "C", 1)

        local visited = g:dfs("A")
        expect_not_nil(visited, "DFS returned result")
        expect_equal(3, #visited, "DFS visits all 3 nodes")
        expect_equal("A", visited[1], "DFS starts at A")
    end)
end)

describe("golden: Dijkstra shortest path", function()
    it("finds minimum cost path in weighted graph", function()
        local g = lurek.graph.newGraph()
        g:addNode("A")
        g:addNode("B")
        g:addNode("C")
        g:addNode("D")
        -- A→B=1, A→C=4, B→C=2, B→D=5, C→D=1
        g:addEdge("A", "B", 1)
        g:addEdge("A", "C", 4)
        g:addEdge("B", "C", 2)
        g:addEdge("B", "D", 5)
        g:addEdge("C", "D", 1)

        local path, cost = g:dijkstra("A", "D")
        expect_not_nil(path, "Dijkstra found path")
        -- Shortest: A→B(1)→C(2)→D(1) = cost 4
        expect_near(4.0, cost, 0.001, "optimal cost = 4")
    end)
end)

describe("golden: cycle detection", function()
    it("DAG has no cycle", function()
        local g = lurek.graph.newGraph()
        g:addNode("A")
        g:addNode("B")
        g:addNode("C")
        g:addEdge("A", "B", 1)
        g:addEdge("B", "C", 1)

        local has_cycle = g:hasCycle()
        expect_equal(false, has_cycle, "DAG has no cycle")
    end)

    it("cyclic graph detected", function()
        local g = lurek.graph.newGraph()
        g:addNode("A")
        g:addNode("B")
        g:addNode("C")
        g:addEdge("A", "B", 1)
        g:addEdge("B", "C", 1)
        g:addEdge("C", "A", 1)  -- creates cycle

        local has_cycle = g:hasCycle()
        expect_equal(true, has_cycle, "cyclic graph detected")
    end)
end)

test_summary()
