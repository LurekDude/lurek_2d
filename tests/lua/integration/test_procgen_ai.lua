-- tests/lua/integration/test_procgen_ai.lua
-- Integration: procedurally generated maps used with lurek.ai behaviours.
-- Namespaces: lurek.procgen + lurek.ai


-- ─────────────────────────────────────────────
-- WorldGraph Reachability (AI-style BFS)
-- ─────────────────────────────────────────────
describe("procgen worldGraph + ai navigation concepts", function()

    it("worldGraph edges form a connected-ish graph", function()
        local wg = lurek.procgen.worldGraph(300, 200, 10, 1)
        -- Build adjacency list from edges
        local adj = {}
        for _, r in ipairs(wg.regions) do adj[r.id] = {} end
        for _, e in ipairs(wg.edges) do
            table.insert(adj[e.from], e.to)
            if e.bidirectional then
                table.insert(adj[e.to], e.from)
            end
        end
        -- BFS from first region
        local start = wg.regions[1].id
        local visited = { [start] = true }
        local queue = { start }
        while #queue > 0 do
            local curr = table.remove(queue, 1)
            for _, next_id in ipairs(adj[curr] or {}) do
                if not visited[next_id] then
                    visited[next_id] = true
                    table.insert(queue, next_id)
                end
            end
        end
        -- At least half the regions should be reachable from start
        local reachable_count = 0
        for _ in pairs(visited) do reachable_count = reachable_count + 1 end
        expect_true(reachable_count >= math.max(1, #wg.regions / 2),
            "expected at least half of regions reachable, got " .. reachable_count)
    end)

    it("BSP rooms can host spawn points (room centers)", function()
        local d = lurek.procgen.bspDungeon({ width = 60, height = 40, seed = 3 })
        local spawns = {}
        for _, r in ipairs(d.rooms) do
            table.insert(spawns, {
                x = r.x + math.floor(r.w / 2),
                y = r.y + math.floor(r.h / 2)
            })
        end
        expect_equal(#d.rooms, #spawns)
        for _, sp in ipairs(spawns) do
            expect_type("number", sp.x)
            expect_type("number", sp.y)
            expect_true(sp.x >= 0 and sp.x < 60, "spawn x out of bounds")
            expect_true(sp.y >= 0 and sp.y < 40, "spawn y out of bounds")
        end
    end)

    it("heightmap can define zone biomes for AI awareness", function()
        local hm = lurek.procgen.heightmap({ width = 16, height = 16, seed = 5 })
        -- Classify zones: < 0.3 = water, 0.3..0.7 = land, > 0.7 = mountain
        local water_count, land_count, mountain_count = 0, 0, 0
        for _, v in ipairs(hm.cells) do
            if v < 0.3 then water_count = water_count + 1
            elseif v < 0.7 then land_count = land_count + 1
            else mountain_count = mountain_count + 1 end
        end
        -- At least one zone should be non-empty (any mix is OK)
        expect_true(water_count + land_count + mountain_count == 16 * 16)
    end)

    it("name generator produces unique names for AI actors", function()
        local training = { "Goblin", "Orc", "Troll", "Bandit", "Knight", "Archer", "Mage", "Warrior" }
        local names = lurek.procgen.generateNames(training, 20, 3, 10, 42)
        expect_equal(20, #names)
        -- Check all are strings
        for _, n in ipairs(names) do
            expect_type("string", n)
        end
        -- Check for at least some variety (not all identical)
        local name_set = {}
        for _, n in ipairs(names) do name_set[n] = true end
        local unique = 0
        for _ in pairs(name_set) do unique = unique + 1 end
        expect_true(unique > 1, "expected some variety in generated names, got " .. unique)
    end)

    it("L-system produces patrol path segments for AI movement", function()
        local segs = lurek.procgen.lsystemSegments(
            { axiom = "F+F+F+F", rules = { F = "F+F-F-FF+F+F-F" }, iterations = 1 },
            90, 5.0
        )
        expect_type("table", segs)
        expect_true(#segs > 0, "expected at least one segment")
        for _, s in ipairs(segs) do
            expect_type("number", s.x1)
            expect_type("number", s.y1)
            expect_type("number", s.x2)
            expect_type("number", s.y2)
        end
    end)

    it("noise map can initialize AI threat/cover grid", function()
        local m = lurek.procgen.noiseMap(20, 20, { seed = 11, scale_x = 0.2, scale_y = 0.2 })
        local threat = {}
        for _, v in ipairs(m) do
            -- High values = exposed, low = cover
            table.insert(threat, v > 0.6 and "exposed" or "cover")
        end
        expect_equal(400, #threat)
    end)
end)

-- ─────────────────────────────────────────────
-- WFC grid as AI domain knowledge layout
-- ─────────────────────────────────────────────
describe("wfcGenerate provides tile layout for AI", function()

    it("tile counts are within expected range", function()
        local tiles = {
            { id = 0, weight = 1.0 },  -- floor
            { id = 1, weight = 0.5 },  -- wall
            { id = 2, weight = 0.3 },  -- treasure
        }
        local adj = { [0] = { 0, 1, 2 }, [1] = { 0, 1 }, [2] = { 0 } }
        local g = lurek.procgen.wfcGenerate({ width = 12, height = 12, tiles = tiles, adjacencies = adj, seed = 9 })
        local counts = { [0] = 0, [1] = 0, [2] = 0 }
        for _, c in ipairs(g.cells) do
            counts[c] = (counts[c] or 0) + 1
        end
        -- Total cells should equal w*h
        expect_equal(144, counts[0] + counts[1] + (counts[2] or 0))
    end)
end)

test_summary()
