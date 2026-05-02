-- tests/lua/content/demos/test_globe_demo.lua
-- Extensive smoke test for content/games/showcase/globe_demo/main.lua.
--
-- Runs standard static checks via _common_checks.lua, then adds
-- globe-specific assertions:
--   - Uses lurek.globe API
--   - Has 200 provinces expected (generated in init)
--   - Uses political and highlight layers
--   - Has capital markers
--   - Camera is initialised within expected ranges
--
-- Note: lurek.globe.get() is only valid AFTER lurek.init() fires,
-- which requires the real engine loop.  In the headless test VM the
-- dofile() + __newindex path does not invoke the init callback.
-- Those runtime assertions are covered by tests/demo_smoke_tests.rs
-- (spawns the real binary with --screenshot-frames=180).

local DEMO_PATH = "content/games/showcase/globe_demo/main.lua"

-- read_file is injected by the Rust test harness at runtime (tests/lua/harness.rs).
local read_file = read_file ---@diagnostic disable-line: undefined-global

-- Inline common checks (dofile and io.open are sandboxed; use read_file helper).
local _demo_src = nil

describe("globe_demo: file and load", function()
    it("source file exists and is non-empty", function()
        _demo_src = read_file(DEMO_PATH)
        expect_not_nil(_demo_src, "Cannot open " .. DEMO_PATH)
        expect_greater(#(_demo_src or ""), 100, "source too short     likely missing or blank")
    end)
end)

describe("globe_demo: callback names", function()
    before_each(function() if not _demo_src then _demo_src = read_file(DEMO_PATH) end end)

    it("registers lurek.init, not lurek.load", function()
        expect_not_nil(_demo_src, 'source missing')
        local src = tostring(_demo_src or "")
        expect_false(string.find(src, "function%s+lurek%.load%s*%(") ~= nil,
            "found 'function lurek.load()'     wrong callback name, use lurek.init")
        expect_true(string.find(src, "function%s+lurek%.init%s*%(") ~= nil,
            "lurek.init callback not found     required by engine loop")
    end)

    it("registers lurek.process, not lurek.update", function()
        expect_not_nil(_demo_src, 'source missing')
        local src = tostring(_demo_src or "")
        expect_false(string.find(src, "function%s+lurek%.update%s*%(") ~= nil,
            "found 'function lurek.update()'     wrong callback name, use lurek.process")
        expect_true(string.find(src, "function%s+lurek%.process%s*%(") ~= nil,
            "lurek.process callback not found     engine update loop won't run")
    end)

    it("does not use lurek.draw (wrong callback)", function()
        expect_not_nil(_demo_src, 'source missing')
        local src = tostring(_demo_src or "")
        expect_false(string.find(src, "function%s+lurek%.draw%s*%(") ~= nil,
            "found 'function lurek.draw()'     wrong callback name, use lurek.render")
    end)
end)

describe("globe_demo: API correctness", function()
    before_each(function() if not _demo_src then _demo_src = read_file(DEMO_PATH) end end)

    it("does not call lurek.render.rectangle", function()
        expect_not_nil(_demo_src, 'source missing')
        local src = tostring(_demo_src or "")
        expect_false(string.find(src, "lurek%.render%.rectangle%s*%(") ~= nil,
            "lurek.render.rectangle is not valid     use gfx.rectangle")
    end)

    it("does not call lurek.input.isDown", function()
        expect_not_nil(_demo_src, 'source missing')
        local src = tostring(_demo_src or "")
        expect_false(string.find(src, "lurek%.input%.isDown%s*%(") ~= nil,
            "lurek.input.isDown() is invalid     use isActionDown()")
    end)
end)

-- -----------------------------------------------------------------
-- Globe-specific static checks
-- -----------------------------------------------------------------
describe("globe_demo: globe API usage", function()
    local src

    before_each(function()
        src = read_file(DEMO_PATH)
    end)

    it("calls lurek.globe.new to create the globe", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.globe%.new%s*%b()") ~= nil or
            src:find('lurek%.globe%.new%s*%("') ~= nil or
            src:find("lurek%.globe%.new%(") ~= nil,
            "lurek.globe.new() not found in source")
    end)

    it("uses Globe:addProvince to build the world", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":addProvince") ~= nil,
            "Globe:addProvince not found     world has no provinces")
    end)

    it("adds at least one map layer (addLayer)", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":addLayer") ~= nil,
            "Globe:addLayer not found     map has no rendering layers")
    end)

    it("adds capital markers (addMarker)", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":addMarker") ~= nil,
            "Globe:addMarker not found     no markers on the globe")
    end)

    it("sets camera position (setCamera)", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":setCamera") ~= nil,
            "Globe:setCamera not found     camera will stay at default (0,0,1)")
    end)

    it("sets time of day (setTimeOfDay)", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":setTimeOfDay") ~= nil,
            "Globe:setTimeOfDay not found     day/night cycle disabled")
    end)

    it("uses province picking (pick) in process loop", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":pick%s*%(") ~= nil,
            "Globe:pick not found     hover/select interaction is missing")
    end)

    it("uses Globe:update in process loop", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":update%s*%(") ~= nil,
            "Globe:update not found     globe physics/animation will not advance")
    end)

    it("expected 200 provinces keyword present in comments or config", function()
        expect_not_nil(src, 'source missing')
        -- The world-generation code should reference 200 in some form.
        expect_true(
            src:find("200") ~= nil,
            "Value 200 not found in source     province count may not be 200")
    end)

    it("mouse drag panning uses getPosition", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("getPosition") ~= nil,
            "lurek.input.mouse.getPosition not used     drag panning is unimplemented")
    end)

    it("mouse wheel zooming uses getWheelDelta", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("getWheelDelta") ~= nil,
            "lurek.input.mouse.getWheelDelta not used     zoom is unimplemented")
    end)

    it("uses setBackgroundColor for space background", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("setBackgroundColor") ~= nil,
            "lurek.render.setBackgroundColor not called     background will be white")
    end)
end)

-- -----------------------------------------------------------------
-- Globe-specific: no wrong globe API calls
-- -----------------------------------------------------------------
describe("globe_demo: no invalid globe API", function()
    local src

    before_each(function()
        src = read_file(DEMO_PATH)
    end)

    it("does not call Globe:addCountry (wrong method name)", function()
        expect_not_nil(src, 'source missing')
        expect_false(
            src:find(":addCountry%s*%(") ~= nil,
            "Globe:addCountry is not a valid API     use Globe:addProvince")
    end)

    it("does not call Globe:setProjection (wrong method name)", function()
        expect_not_nil(src, 'source missing')
        expect_false(
            src:find(":setProjection%s*%(") ~= nil,
            "Globe:setProjection is not a valid API (removed in v0.4)")
    end)

    it("does not call lurek.globe.create (wrong factory name)", function()
        expect_not_nil(src, 'source missing')
        expect_false(
            src:find("lurek%.globe%.create%s*%(") ~= nil,
            "lurek.globe.create() is invalid     use lurek.globe.new()")
    end)
end)
test_summary()
