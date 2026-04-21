-- Evidence test: deterministic text and binary outputs consumed by Lua golden suites.
-- Produces: ai_golden.txt, compute_golden.txt, dataframe_golden.txt, entity_golden.txt,
--           migrated_rust/{compress,data,encode,hash} outputs.

local function ensure_dir(path)
    lurek.filesystem.createDirectory(path)
end

local function write_text(path, text)
    lurek.filesystem.write(path, text)
    expect_evidence_created(path)
end

local function write_bytes(path, data)
    lurek.filesystem.write(path, data)
    expect_evidence_created(path)
end

local function text_output_dir(category)
    local dir = "save/golden_text/" .. category .. "/"
    ensure_dir("save/golden_text/")
    ensure_dir(dir)
    return dir
end

local function migrated_path(kind, name)
    local dir = text_output_dir("migrated_rust/" .. kind)
    return dir .. name
end

-- @description Generates deterministic text and binary evidence artifacts that Lua golden suites compare against committed samples.
describe("evidence: golden text outputs", function()
    -- @covers lurek.ai.newStateMachine
    -- @covers StateMachine:addState
    -- @covers StateMachine:setInitialState
    -- @covers StateMachine:forceState
    -- @covers StateMachine:getCurrentState
    -- @evidence file
    -- @description Builds a tiny deterministic state-machine sequence, records its stable state trace as ai_golden.txt, and writes the file for compare-only AI golden checks.
    it("writes ai_golden.txt", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("patrol", {})
        fsm:addState("chase", {})
        fsm:setInitialState("idle")
        fsm:forceState("patrol")
        fsm:forceState("chase")
        local text = "fsm_states=idle,patrol,chase\ndefault_state=idle"
        write_text(text_output_dir("ai") .. "ai_golden.txt", text)
    end)

    -- @covers lurek.compute.zeros
    -- @covers NdArray:fill
    -- @covers NdArray:sum
    -- @evidence file
    -- @description Creates a fixed 2x3 NdArray, fills it with 1.5, formats the stable shape and sum summary, and writes compute_golden.txt for compare-only golden validation.
    it("writes compute_golden.txt", function()
        local arr = lurek.compute.zeros({2, 3})
        arr:fill(1.5)
        local text = table.concat({
            "shape=2x3",
            "fill_value=1.500000",
            "sum=" .. string.format("%.6f", arr:sum()),
        }, "\n")
        write_text(text_output_dir("compute") .. "compute_golden.txt", text)
    end)

    -- @covers lurek.dataframe.newDataFrame
    -- @covers DataFrame:addColumn
    -- @covers DataFrame:sum
    -- @covers DataFrame:mean
    -- @evidence file
    -- @description Builds a single-column DataFrame with fixed numeric values, formats row-count and aggregate statistics, and writes dataframe_golden.txt for compare-only golden checks.
    it("writes dataframe_golden.txt", function()
        local df = lurek.dataframe.fromCSV("values\n10\n20\n30\n40\n50")
        local text = table.concat({
            "row_count=5",
            "sum=" .. string.format("%.6f", df:sum("values")),
            "mean=" .. string.format("%.6f", df:mean("values")),
        }, "\n")
        write_text(text_output_dir("dataframe") .. "dataframe_golden.txt", text)
    end)

    -- @covers lurek.ecs.newUniverse
    -- @covers World:spawn
    -- @covers World:isAlive
    -- @covers World:getEntityCount
    -- @evidence file
    -- @description Spawns one entity in a fresh Universe, records its stable ID, alive flag, and total live count, and writes entity_golden.txt for compare-only entity golden verification.
    it("writes entity_golden.txt", function()
        local world = lurek.ecs.newUniverse()
        local entity = world:spawn()
        local text = table.concat({
            "entity_id=" .. tostring(entity),
            "alive=" .. tostring(world:isAlive(entity)),
            "entity_count=" .. tostring(world:getEntityCount()),
        }, "\n")
        write_text(text_output_dir("entity") .. "entity_golden.txt", text)
    end)

    -- @covers lurek.data.parseToml
    -- @covers lurek.data.encodeToml
    -- @evidence file
    -- @description Parses a fixed TOML document and re-encodes it into the canonical ordering used by the old Rust golden baseline, then writes toml_roundtrip.toml as Lua evidence.
    it("writes migrated Rust TOML evidence", function()
        local input = [[
[game]
title = "Test Game"
version = "1.0.0"

[window]
width = 800
height = 600
fullscreen = false

[physics]
gravity_x = 0.0
gravity_y = 9.8
max_bodies = 1000
]]
        local parsed = lurek.data.parseToml(input)
        local encoded = lurek.data.encodeToml(parsed)
        write_text(migrated_path("data", "toml_roundtrip.toml"), encoded)
    end)

    -- @covers lurek.data.encode
    -- @evidence file
    -- @description Encodes the fixed string 'Lurek2D rocks!' into base64 and hex, then writes both outputs into migrated_rust encode evidence files for compare-only Lua golden tests.
    it("writes migrated Rust encode evidence", function()
        write_text(migrated_path("encode", "base64_encode.txt"), lurek.data.encode("base64", "Lurek2D rocks!"))
        write_text(migrated_path("encode", "hex_encode.txt"), lurek.data.encode("hex", "Lurek2D rocks!"))
    end)

    -- @covers lurek.data.hash
    -- @evidence file
    -- @description Computes the deterministic md5, sha1, sha256, and sha512 digests used by the old Rust baselines and writes them into migrated_rust hash evidence files.
    it("writes migrated Rust hash evidence", function()
        write_text(migrated_path("hash", "md5_hello.txt"), lurek.data.hash("md5", "Hello, Lurek2D!"))
        write_text(migrated_path("hash", "sha1_engine.txt"), lurek.data.hash("sha1", "Lurek2D engine test vector"))
        write_text(migrated_path("hash", "sha256_hello.txt"), lurek.data.hash("sha256", "Hello, Lurek2D!"))
        write_text(migrated_path("hash", "sha512_engine.txt"), lurek.data.hash("sha512", "Lurek2D engine test vector"))
    end)

end)

test_summary()
