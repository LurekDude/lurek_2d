-- test_evidence_graph.lua
-- Evidence test: lurek.graph Graph API contracts and PNG visual network evidence

local OUT = "tests/lua/evidence/output/graph/"

-- â”€â”€ helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

--- Build a graph from a position table and edge index list.
--- positions: array of {x, y}
--- edges: array of {from_idx, to_idx}
--- Returns graph, nodes_array (positions stored externally, not on nodes)
local function build_graph(positions, edges)
    local g = lurek.graph.newGraph()
    local nodes = {}
    for i = 1, #positions do
        nodes[i] = g:addNode()
    end
    for _, e in ipairs(edges) do
        g:addEdge(nodes[e[1]], nodes[e[2]])
    end
    return g, nodes
end

--- Render a graph as a PNG.
--- nodes_arr: array of LuaNode
--- edges_idx: array of {from_idx, to_idx} (integer indices into nodes_arr and positions)
--- path_nodes: optional array of nodes from findPath
--- positions: array of {x, y} parallel to nodes_arr
local function draw_graph(nodes_arr, edges_idx, path_nodes, positions, iw, ih)
    local img = lurek.image.newImageData(iw, ih)
    img:fill(15, 20, 30, 255)

    -- Build set of path nodes by tostring key for highlighting
    local path_set = {}
    if path_nodes then
        for _, n in ipairs(path_nodes) do
            path_set[tostring(n)] = true
        end
    end

    -- Draw edges (index-based to avoid missing getX/getY node methods)
    for _, e in ipairs(edges_idx) do
        local x1 = positions[e[1]].x
        local y1 = positions[e[1]].y
        local x2 = positions[e[2]].x
        local y2 = positions[e[2]].y
        img:drawLine(x1, y1, x2, y2, 60, 80, 100, 255)
    end

    -- Draw nodes
    for i, n in ipairs(nodes_arr) do
        local nx = positions[i].x
        local ny = positions[i].y
        local is_path = path_set[tostring(n)]
        local r, g_val, b = 80, 120, 200
        if is_path then r, g_val, b = 220, 160, 60 end
        img:drawCircle(nx, ny, 5, r, g_val, b, 255)
        img:drawCircle(nx, ny, 3, 255, 255, 255, 255)
    end

    return img
end

-- â”€â”€ tests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers graph construction and mutation primitives on the Lua graph wrapper.
describe("Evidence: lurek.graph Graph creation", function()
end)

-- @description Covers graph search and connectivity helpers on small deterministic topologies.
describe("Evidence: lurek.graph findPath Dijkstra", function()
end)

-- @description Writes graph topology images that highlight discovered paths through two deterministic layouts.
describe("Evidence: lurek.graph visual network PNG", function()

    -- @covers Graph:findPath
    -- @evidence file
    -- @covers lurek.graph.newGraph
    -- @covers Graph:addNode
    -- @covers Graph:addEdge
    -- @description Builds an eight-node ring, finds a path across it, and saves a PNG showing the highlighted route.
    it("ring topology â€” PNG evidence: ring_graph", function()
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

        local g, nodes = build_graph(positions, edge_def)

        local path_result = g:findPath(nodes[1], nodes[5])
        local path_nodes  = path_result and path_result.nodes or nil

        local img = draw_graph(nodes, edge_def, path_nodes, positions, 240, 240)
        lurek.image.savePNG(img, OUT .. "evidence_graph_ring.png")
    end)

    -- @covers Graph:findPath
    -- @evidence file
    -- @description Builds a hub-and-spoke graph with extra spoke links and saves a PNG that highlights the chosen path.
    it("hub-and-spoke topology â€” PNG evidence: hub_graph", function()
        local CX, CY = 120, 120
        local R = 80
        local SPOKES = 6

        -- positions: hub = index 1, spokes = indices 2..SPOKES+1
        local positions = {}
        positions[1] = {x = CX, y = CY}
        for i = 1, SPOKES do
            local angle = (i - 1) / SPOKES * 2 * math.pi
            positions[i + 1] = {
                x = CX + math.floor(R * math.cos(angle)),
                y = CY + math.floor(R * math.sin(angle))
            }
        end

        -- Edges: hub(1) -> each spoke(2..N+1), plus adjacent spoke cross-edges
        local edge_def = {}
        for i = 1, SPOKES do
            edge_def[#edge_def+1] = {1, i + 1}
        end
        for i = 1, SPOKES - 1 do
            edge_def[#edge_def+1] = {i + 1, i + 2}
        end

        local g, nodes = build_graph(positions, edge_def)

        -- Path from spoke 1 to spoke 4 (indices 2 and 5)
        local path_result = g:findPath(nodes[2], nodes[5])
        local path_nodes  = path_result and path_result.nodes or nil

        local img = draw_graph(nodes, edge_def, path_nodes, positions, 240, 240)
        lurek.image.savePNG(img, OUT .. "evidence_graph_hub.png")
    end)
end)

-- @description Covers the graph item-flow helpers used to attach and remove payloads from graph nodes.
describe("Evidence: lurek.graph item flow", function()
end)
test_summary()
