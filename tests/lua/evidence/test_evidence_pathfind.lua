-- Placeholder evidence suite for migrated pathfinding artifacts.
-- Keeps the pathfind evidence output location and pending migration scope explicit until real Lua evidence cases land here.

local OUT = "tests/lua/evidence/output/pathfind/"

-- @description Placeholder pathfinding evidence suite; the concrete pathfind evidence cases have not been migrated into this file yet.
describe("evidence: pathfind", function()
    before_each(function()
        ensure_evidence_dir("pathfind")
    end)

    -- @description Placeholder: pathfind evidence cases pending migration.
    pending("pathfind heatmap / flow-field evidence cases pending migration from Rust")
end)
test_summary()
