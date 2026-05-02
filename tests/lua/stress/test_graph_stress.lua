-- Lurek2D Stress Test: Graph Flow Simulation
-- Tests large graph creation, edge traversal, and simulation ticks

describe("graph stress: large graph creation", function()
    it("creates a 500-node chain graph", function()
        local g = lurek.graph.newGraph()

        local nodes = {}
        for i = 1, 500 do
            nodes[i] = g:addNode("processor", 100)
        end

        -- Connect in chain
        for i = 1, 499 do
            g:addEdge(nodes[i], nodes[i + 1])
        end

        local stats = g:getStats()
        expect_equal(500, stats.nodes, "500 nodes created")
        expect_equal(499, stats.edges, "499 edges created")
    end)

    it("creates a mesh-connected graph", function()
        local g = lurek.graph.newGraph()

        -- 20x20 grid = 400 nodes
        local size = 20
        local nodes = {}
        for i = 1, size * size do
            nodes[i] = g:addNode("processor", 50)
        end

        -- Connect horizontally and vertically
        local edges = 0
        for row = 0, size - 1 do
            for col = 0, size - 1 do
                local id = row * size + col + 1
                if col < size - 1 then
                    g:addEdge(nodes[id], nodes[id + 1])
                    edges = edges + 1
                end
                if row < size - 1 then
                    g:addEdge(nodes[id], nodes[id + size])
                    edges = edges + 1
                end
            end
        end

        local stats = g:getStats()
        expect_equal(400, stats.nodes, "400 nodes in grid")
        expect_equal(edges, stats.edges, "correct edge count")
    end)
end)

describe("graph stress: simulation ticks", function()
    it("runs 100 ticks on a 200-node pipeline", function()
        local g = lurek.graph.newGraph()

        local nodes = {}
        for i = 1, 200 do
            nodes[i] = g:addNode("processor", 100)
        end

        -- Linear pipeline
        for i = 1, 199 do
            g:addEdge(nodes[i], nodes[i + 1])
        end

        -- Add items at the source
        for i = 1, 50 do
            local item = g:createItem("resource")
            g:addItem(item, nodes[1])
        end

        -- Run 100 simulation ticks
        for tick = 1, 100 do
            g:update(1.0)
        end

        expect_true(true, "100 ticks completed without error")
    end)
end)
test_summary()
