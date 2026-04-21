-- Placeholder evidence suite for migrated math artifacts.
-- Reserves the math evidence output path until concrete Lua-side artifact producers replace this temporary scaffold.

local OUT = "tests/lua/evidence/output/math/"

-- @description Placeholder math evidence suite; no concrete math evidence cases have been migrated into this file yet.
describe("evidence: math", function()
    before_each(function()
        ensure_evidence_dir("math")
    end)

    -- @description Placeholder: math evidence cases pending migration.
    pending("math noise / terrain evidence cases pending migration from Rust")
end)
test_summary()
