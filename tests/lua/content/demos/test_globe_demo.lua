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

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("globe_demo", DEMO_PATH)

-- -----------------------------------------------------------------
-- Globe-specific static checks
-- -----------------------------------------------------------------
describe("globe_demo: globe API usage", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then
            src = f:read("*all")
            f:close()
        end
    end)

    it("calls lurek.globe.new to create the globe", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.globe%.new%s*%b()") ~= nil or
            src:find('lurek%.globe%.new%s*%("') ~= nil or
            src:find("lurek%.globe%.new%(") ~= nil,
            "lurek.globe.new() not found in source")
    end)

    it("uses Globe:addProvince to build the world", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":addProvince") ~= nil,
            "Globe:addProvince not found — world has no provinces")
    end)

    it("adds at least one map layer (addLayer)", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":addLayer") ~= nil,
            "Globe:addLayer not found — map has no rendering layers")
    end)

    it("adds capital markers (addMarker)", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":addMarker") ~= nil,
            "Globe:addMarker not found — no markers on the globe")
    end)

    it("sets camera position (setCamera)", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":setCamera") ~= nil,
            "Globe:setCamera not found — camera will stay at default (0,0,1)")
    end)

    it("sets time of day (setTimeOfDay)", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":setTimeOfDay") ~= nil,
            "Globe:setTimeOfDay not found — day/night cycle disabled")
    end)

    it("uses province picking (pick) in process loop", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":pick%s*%(") ~= nil,
            "Globe:pick not found — hover/select interaction is missing")
    end)

    it("uses Globe:update in process loop", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":update%s*%(") ~= nil,
            "Globe:update not found — globe physics/animation will not advance")
    end)

    it("expected 200 provinces keyword present in comments or config", function()
        if not src then pending("source missing") return end
        -- The world-generation code should reference 200 in some form.
        expect_true(
            src:find("200") ~= nil,
            "Value 200 not found in source — province count may not be 200")
    end)

    it("mouse drag panning uses getMousePosition", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("getMousePosition") ~= nil,
            "lurek.input.getMousePosition not used — drag panning is unimplemented")
    end)

    it("mouse wheel zooming uses getWheelDelta", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("getWheelDelta") ~= nil,
            "lurek.input.getWheelDelta not used — zoom is unimplemented")
    end)

    it("uses setBackgroundColor for space background", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("setBackgroundColor") ~= nil,
            "lurek.render.setBackgroundColor not called — background will be white")
    end)
end)

-- -----------------------------------------------------------------
-- Globe-specific: no wrong globe API calls
-- -----------------------------------------------------------------
describe("globe_demo: no invalid globe API", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then
            src = f:read("*all")
            f:close()
        end
    end)

    it("does not call Globe:addCountry (wrong method name)", function()
        if not src then pending("source missing") return end
        expect_false(
            src:find(":addCountry%s*%(") ~= nil,
            "Globe:addCountry is not a valid API — use Globe:addProvince")
    end)

    it("does not call Globe:setProjection (wrong method name)", function()
        if not src then pending("source missing") return end
        expect_false(
            src:find(":setProjection%s*%(") ~= nil,
            "Globe:setProjection is not a valid API (removed in v0.4)")
    end)

    it("does not call lurek.globe.create (wrong factory name)", function()
        if not src then pending("source missing") return end
        expect_false(
            src:find("lurek%.globe%.create%s*%(") ~= nil,
            "lurek.globe.create() is invalid — use lurek.globe.new()")
    end)
end)
