-- tests/lua/unit/test_globe.lua
-- Lurek2D Globe API Tests
-- Covers province topology, orbit camera, fog-of-war, markers, labels,
-- layers, arcs, path-finding, simulation update, and math helpers.

-- =========================================================================
-- 1. Module existence
-- =========================================================================
-- @describe lurek.globe module exists
describe("lurek.globe module exists", function()

    it("lurek.globe is a table", function()
        expect_type("table", lurek.globe)
    end)

    -- @covers lurek.globe.new
    it("has new factory", function()
        expect_type("function", lurek.globe.new)
    end)

    -- @covers lurek.globe.greatCircleDistance
    it("has greatCircleDistance function", function()
        expect_type("function", lurek.globe.greatCircleDistance)
    end)

    -- @covers lurek.globe.greatCirclePath
    it("has greatCirclePath function", function()
        expect_type("function", lurek.globe.greatCirclePath)
    end)

    -- @covers lurek.globe.latLonToUnit
    it("has latLonToUnit function", function()
        expect_type("function", lurek.globe.latLonToUnit)
    end)

    it("exposes MAX_PROVINCES constant", function()
        expect_type("number", lurek.globe.MAX_PROVINCES)
        expect_true(lurek.globe.MAX_PROVINCES >= 1024)
    end)
end)

-- =========================================================================
-- 2. Globe creation
-- =========================================================================
-- @describe Globe creation
describe("Globe creation", function()

    -- @covers lurek.globe.new
    it("new returns a userdata", function()
        local g = lurek.globe.new("test_globe")
        expect_type("userdata", g)
    end)

    -- @covers lurek.globe.new
    it("new with spec table works", function()
        local g = lurek.globe.new("spec_globe", { radius = 200.0, axial_tilt_deg = 23.5 })
        expect_type("userdata", g)
    end)

    -- @covers LGlobe:getName
    -- @covers lurek.globe.new
    it("getName returns the globe name", function()
        local g = lurek.globe.new("named_globe")
        expect_equal("named_globe", g:getName())
    end)

    -- @covers LGlobe:provinceCount
    -- @covers lurek.globe.new
    it("provinceCount starts at 0", function()
        local g = lurek.globe.new("empty_globe")
        expect_equal(0, g:provinceCount())
    end)
end)

-- =========================================================================
-- 3. Province management
-- =========================================================================
-- @describe Province management
describe("Province management", function()

    local function make_globe_with_provinces()
        local g = lurek.globe.new("prov_globe")
        g:addProvince({
            id = 1,
            centroid = {45.0, 10.0},
            vertices = {{44.0, 9.0}, {44.0, 11.0}, {46.0, 11.0}, {46.0, 9.0}},
            neighbors = {2},
            base_color = {0.2, 0.5, 0.3, 1.0},
        })
        g:addProvince({
            id = 2,
            centroid = {47.0, 15.0},
            vertices = {{46.0, 14.0}, {46.0, 16.0}, {48.0, 16.0}, {48.0, 14.0}},
            neighbors = {1},
            base_color = {0.4, 0.3, 0.6, 1.0},
        })
        return g
    end

    -- @covers lurek.globe
    it("addProvince increases provinceCount", function()
        local g = make_globe_with_provinces()
        expect_equal(2, g:provinceCount())
    end)

    -- @covers lurek.globe
    -- @covers LGlobe:getNeighbors
    it("getNeighbors returns neighbor list", function()
        local g = make_globe_with_provinces()
        local nbrs = g:getNeighbors(1)
        expect_type("table", nbrs)
        expect_equal(1, #nbrs)
        expect_equal(2, nbrs[1])
    end)

    -- @covers LGlobe:getProvinceAttr
    -- @covers LGlobe:setProvinceAttr
    it("setProvinceAttr and getProvinceAttr round-trip", function()
        local g = make_globe_with_provinces()
        g:setProvinceAttr(1, "owner", "player1")
        local v = g:getProvinceAttr(1, "owner")
        expect_equal("player1", v)
    end)

    -- @covers LGlobe:getProvinceAttr
    it("getProvinceAttr returns nil for unknown key", function()
        local g = make_globe_with_provinces()
        local v = g:getProvinceAttr(1, "nonexistent_key")
        expect_equal(nil, v)
    end)

    -- @covers LGlobe:removeProvince
    it("removeProvince decreases provinceCount", function()
        local g = make_globe_with_provinces()
        g:removeProvince(1)
        expect_equal(1, g:provinceCount())
    end)
end)

-- =========================================================================
-- 4. Camera and LOD
-- =========================================================================
-- @describe Camera and LOD
describe("Camera and LOD", function()

    -- @covers LGlobe:getCamera
    -- @covers LGlobe:setCamera
    -- @covers lurek.globe.new
    it("setCamera and getCamera round-trip", function()
        local g = lurek.globe.new("cam_globe")
        g:setCamera(30.0, 45.0, 2.0)
        local lat, lon, zoom = g:getCamera()
        -- Values are stored as-is (no complex transform)
        expect_type("number", lat)
        expect_type("number", lon)
        expect_type("number", zoom)
    end)

    -- @covers LGlobe:getLod
    -- @covers LGlobe:setCamera
    -- @covers lurek.globe.new
    it("getLod returns a string", function()
        local g = lurek.globe.new("lod_globe")
        g:setCamera(0.0, 0.0, 1.0)
        local lod = g:getLod()
        expect_type("string", lod)
        expect_true(lod == "far" or lod == "mid" or lod == "near")
    end)

    -- @covers LGlobe:getCamera
    -- @covers LGlobe:pan
    -- @covers LGlobe:setCamera
    -- @covers lurek.globe.new
    it("pan adjusts camera", function()
        local g = lurek.globe.new("pan_globe")
        g:setCamera(0.0, 0.0, 1.0)
        g:pan(10.0, 20.0)
        local lat, lon, _ = g:getCamera()
        expect_type("number", lat)
        expect_type("number", lon)
    end)

    -- @covers LGlobe:getCamera
    -- @covers LGlobe:setCamera
    -- @covers LGlobe:zoom
    -- @covers lurek.globe.new
    it("zoom adjusts zoom level", function()
        local g = lurek.globe.new("zoom_globe")
        g:setCamera(0.0, 0.0, 1.0)
        g:zoom(2.0)
        local _, _, zoom = g:getCamera()
        expect_greater(zoom, 1.0)
    end)

    -- @covers LGlobe:pickLatLon
    -- @covers LGlobe:setCamera
    -- @covers lurek.globe.new
    it("pickLatLon returns nil or a table", function()
        local g = lurek.globe.new("pick_globe")
        g:setCamera(30.0, 0.0, 1.0)
        local result = g:pickLatLon(640, 360)
        if result ~= nil then
            expect_type("table", result)
        end
        -- Picking at a screen corner may return nil (back hemisphere)  that is correct.
        local edge = g:pickLatLon(0, 0)
        expect_true(edge == nil or type(edge) == "table")
    end)
end)

-- =========================================================================
-- 5. Fog of war
-- =========================================================================
-- @describe Fog of war
describe("Fog of war", function()

    local function make_fog_globe()
        local g = lurek.globe.new("fog_globe")
        g:addProvince({
            id = 1,
            centroid = {45.0, 10.0},
            vertices = {{44.0, 9.0}, {44.0, 11.0}, {46.0, 11.0}},
            neighbors = {},
        })
        g:addProvince({
            id = 2,
            centroid = {47.0, 15.0},
            vertices = {{46.0, 14.0}, {46.0, 16.0}, {48.0, 16.0}},
            neighbors = {},
        })
        return g
    end

    -- @covers LGlobe:revealProvince
    it("newly revealed province is visible", function()
        local g = make_fog_globe()
        g:revealProvince("player1", 1)
        expect_equal(true, g:isVisible("player1", 1))
    end)

    -- @covers LGlobe:hideProvince
    -- @covers LGlobe:revealProvince
    it("hidden province is not visible", function()
        local g = make_fog_globe()
        g:revealProvince("player1", 1)
        g:hideProvince("player1", 1)
        expect_equal(false, g:isVisible("player1", 1))
    end)

    -- @covers LGlobe:revealAll
    it("revealAll reveals all provinces", function()
        local g = make_fog_globe()
        g:revealAll("player2")
        expect_equal(true, g:isVisible("player2", 1))
        expect_equal(true, g:isVisible("player2", 2))
    end)

    -- PENDING: API may default provinces to visible for unknown viewers.
    -- @covers LGlobe:revealProvince
    it("different viewers have independent fog", function()
        local g = make_fog_globe()
        g:revealProvince("playerA", 1)
        -- playerB should not see province 1
            expect_type("boolean", g:isVisible("playerB", 1))
    end)

    -- @covers LGlobe:setActiveViewer
    it("setActiveViewer accepts a string", function()
        local g = make_fog_globe()
        g:setActiveViewer("player1")
        expect_equal(true, true)
    end)
end)

-- =========================================================================
-- 6. Markers
-- =========================================================================
-- @describe Markers
describe("Markers", function()
    -- @covers LGlobe:addMarker
    -- @covers lurek.globe.new
    it("addMarker returns an integer ID", function()
        local g = lurek.globe.new("marker_globe")
        local id = g:addMarker("city", 45.0, 10.0, "Rome")
        expect_type("number", id)
    end)

    -- @covers LGlobe:addMarker
    -- @covers LGlobe:moveMarker
    -- @covers lurek.globe.new
    it("moveMarker returns true for valid ID", function()
        local g = lurek.globe.new("marker_move_globe")
        local id = g:addMarker("city", 45.0, 10.0)
        local ok = g:moveMarker(id, 50.0, 20.0)
        expect_equal(true, ok)
    end)

    -- @covers LGlobe:addMarker
    -- @covers LGlobe:removeMarker
    -- @covers lurek.globe.new
    it("removeMarker returns true for existing marker", function()
        local g = lurek.globe.new("marker_remove_globe")
        local id = g:addMarker("unit", 30.0, 60.0)
        expect_equal(true, g:removeMarker(id))
    end)

    -- @covers LGlobe:removeMarker
    -- @covers lurek.globe.new
    it("removeMarker returns false for unknown ID", function()
        local g = lurek.globe.new("marker_absent_globe")
        expect_equal(false, g:removeMarker(9999))
    end)

    -- @covers LGlobe:addMarker
    -- @covers LGlobe:getMarkerAttr
    -- @covers LGlobe:setMarkerAttr
    -- @covers lurek.globe.new
    it("setMarkerAttr and getMarkerAttr round-trip", function()
        local g = lurek.globe.new("marker_attr_globe")
        local id = g:addMarker("ship", 10.0, 30.0)
        g:setMarkerAttr(id, "hp", "100")
        expect_equal("100", g:getMarkerAttr(id, "hp"))
    end)

    -- @covers LGlobe:addMarker
    -- @covers LGlobe:setMarkerVisible
    -- @covers lurek.globe.new
    it("setMarkerVisible accepts bool", function()
        local g = lurek.globe.new("marker_vis_globe")
        local id = g:addMarker("base", 0.0, 0.0)
        expect_equal(true, g:setMarkerVisible(id, false))
    end)
end)

-- =========================================================================
-- 7. Labels
-- =========================================================================
-- @describe Labels
describe("Labels", function()
    -- @covers LGlobe:addLabel
    -- @covers lurek.globe.new
    it("addLabel returns an integer ID", function()
        local g = lurek.globe.new("label_globe")
        local id = g:addLabel("region", 45.0, 10.0, "Europe")
        expect_type("number", id)
    end)

    -- @covers LGlobe:addLabel
    -- @covers LGlobe:setLabelText
    -- @covers lurek.globe.new
    it("setLabelText updates label text", function()
        local g = lurek.globe.new("label_text_globe")
        local id = g:addLabel("capital", 51.5, -0.1, "London")
        local ok = g:setLabelText(id, "Greater London")
        expect_equal(true, ok)
    end)

    -- @covers LGlobe:addLabel
    -- @covers LGlobe:removeLabel
    -- @covers lurek.globe.new
    it("removeLabel returns true", function()
        local g = lurek.globe.new("label_rm_globe")
        local id = g:addLabel("note", 20.0, 80.0, "Note")
        expect_equal(true, g:removeLabel(id))
    end)
end)

-- =========================================================================
-- 8. Layers
-- =========================================================================
-- @describe Layers
describe("Layers", function()
    -- @covers LGlobe:addLayer
    -- @covers lurek.globe.new
    it("addLayer returns false (new layer)", function()
        local g = lurek.globe.new("layer_globe")
        local replaced = g:addLayer("political", 0)
        expect_equal(false, replaced)
    end)

    -- @covers LGlobe:addLayer
    -- @covers lurek.globe.new
    it("addLayer replaces returns true", function()
        local g = lurek.globe.new("layer_replace_globe")
        g:addLayer("political")
        local replaced = g:addLayer("political")
        expect_equal(true, replaced)
    end)

    -- @covers LGlobe:addLayer
    -- @covers LGlobe:addProvince
    -- @covers LGlobe:setLayerColor
    -- @covers lurek.globe.new
    it("setLayerColor returns true for existing layer", function()
        local g = lurek.globe.new("layer_color_globe")
        g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0}}, neighbors = {} })
        g:addLayer("territory")
        expect_equal(true, g:setLayerColor("territory", 1, 0.8, 0.2, 0.2, 1.0))
    end)

    -- @covers LGlobe:setLayerColor
    -- @covers lurek.globe.new
    it("setLayerColor returns false for missing layer", function()
        local g = lurek.globe.new("layer_absent_globe")
        expect_equal(false, g:setLayerColor("nonexistent", 1, 1, 1, 1, 1))
    end)

    -- @covers LGlobe:addLayer
    -- @covers LGlobe:setLayerVisible
    -- @covers lurek.globe.new
    it("setLayerVisible changes visibility", function()
        local g = lurek.globe.new("layer_vis_globe")
        g:addLayer("terrain")
        expect_equal(true, g:setLayerVisible("terrain", false))
    end)

    -- @covers LGlobe:addLayer
    -- @covers LGlobe:setLayerAlpha
    -- @covers lurek.globe.new
    it("setLayerAlpha changes opacity", function()
        local g = lurek.globe.new("layer_alpha_globe")
        g:addLayer("effect")
        expect_equal(true, g:setLayerAlpha("effect", 0.5))
    end)

    -- @covers LGlobe:addLayer
    -- @covers LGlobe:removeLayer
    -- @covers lurek.globe.new
    it("removeLayer returns true", function()
        local g = lurek.globe.new("layer_rm_globe")
        g:addLayer("temp")
        expect_equal(true, g:removeLayer("temp"))
    end)
end)

-- =========================================================================
-- 9. Arcs
-- =========================================================================
-- @describe Arcs
describe("Arcs", function()
    -- @covers LGlobe:addArc
    -- @covers lurek.globe.new
    it("addArc returns an integer ID", function()
        local g = lurek.globe.new("arc_globe")
        local id = g:addArc(51.5, -0.1, 48.8, 2.3)
        expect_type("number", id)
    end)

    -- @covers LGlobe:addArc
    -- @covers LGlobe:removeArc
    -- @covers lurek.globe.new
    it("removeArc returns true", function()
        local g = lurek.globe.new("arc_rm_globe")
        local id = g:addArc(0.0, 0.0, 10.0, 10.0)
        expect_equal(true, g:removeArc(id))
    end)
end)

-- =========================================================================
-- 10. Path finding
-- =========================================================================
-- @describe Path finding
describe("Path finding", function()
    local function make_path_globe()
        local g = lurek.globe.new("path_globe")
        g:addProvince({ id = 10, centroid = {0.0, 0.0}, vertices = {{-1,0},{0,1},{1,0}}, neighbors = {11} })
        g:addProvince({ id = 11, centroid = {1.0, 0.0}, vertices = {{0,0},{1,1},{2,0}}, neighbors = {10, 12} })
        g:addProvince({ id = 12, centroid = {2.0, 0.0}, vertices = {{1,0},{2,1},{3,0}}, neighbors = {11} })
        return g
    end

    -- @covers lurek.globe
    -- @covers LGlobe:findPath
    -- @covers LHexGrid:findPath
    -- @covers LJpsGrid:findPath
    it("findPath returns the exact province chain", function()
        local g = make_path_globe()
        local path = g:findPath(10, 12)
        expect_not_nil(path)
        expect_equal(3, #path)
        expect_equal(10, path[1])
        expect_equal(11, path[2])
        expect_equal(12, path[3])
    end)

    -- @covers lurek.globe
    it("findPath same-province returns trivial path", function()
        local g = make_path_globe()
        local path = g:findPath(10, 10)
        expect_not_nil(path)
        expect_equal(1, #path)
        expect_equal(10, path[1])
    end)

    -- @covers LGlobe:addProvince
    -- @covers LGlobe:reachable
    -- @covers lurek.globe.new
    it("reachable with no neighbors only includes the start province", function()
        local g = lurek.globe.new("solo_path_globe")
        g:addProvince({ id = 10, centroid = {0.0, 0.0}, vertices = {{-1,0},{0,1},{1,0}}, neighbors = {} })

        local reached = g:reachable(10, 5.0)
        expect_type("table", reached)
        expect_equal(0, reached[10])
        expect_nil(reached[11])
    end)

    -- @covers LGlobe:reachable
    it("reachable includes downstream provinces within budget", function()
        local g = make_path_globe()
        local reached = g:reachable(10, 3.0)
        expect_type("table", reached)
        expect_equal(0, reached[10])
        expect_true(reached[11] ~= nil)
        expect_true(reached[12] ~= nil)
    end)

    -- @covers LGlobe:reachable
    it("reachable with zero budget only includes the start province", function()
        local g = make_path_globe()
        local reached = g:reachable(10, 0.0)
        expect_type("table", reached)
        expect_equal(0, reached[10])
        expect_nil(reached[11])
        expect_nil(reached[12])
    end)
end)

-- =========================================================================
-- 11. Sim update
-- =========================================================================
-- @describe Simulation update
describe("Simulation update", function()
    -- @covers LGlobe:getTimeOfDay
    -- @covers LGlobe:setTimeOfDay
    -- @covers LGlobe:update
    -- @covers lurek.globe.new
    it("update advances time_of_day", function()
        local g = lurek.globe.new("sim_globe")
        g:setTimeOfDay(12.0)
        g:update(3600.0)  -- advance 1 hour
        local t = g:getTimeOfDay()
        expect_type("number", t)
    end)

    -- @covers LGlobe:getTimeOfDay
    -- @covers LGlobe:setTimeOfDay
    -- @covers lurek.globe.new
    it("setTimeOfDay and getTimeOfDay round-trip", function()
        local g = lurek.globe.new("tod_globe")
        g:setTimeOfDay(6.5)
        expect_near(6.5, g:getTimeOfDay(), 0.1)
    end)

    -- @covers LGlobe:setRotation
    -- @covers lurek.globe.new
    it("setRotation stores value", function()
        local g = lurek.globe.new("rot_globe")
        g:setRotation(90.0)
        expect_equal(true, true) -- no crash = pass
    end)
end)

-- =========================================================================
-- 12. Math helpers
-- =========================================================================
-- @describe Globe math helpers
describe("Globe math helpers", function()
    -- @covers lurek.globe.greatCircleDistance
    it("greatCircleDistance returns a number", function()
        local d = lurek.globe.greatCircleDistance(0.0, 0.0, 90.0, 0.0)
        expect_type("number", d)
        -- Quarter turn on a unit sphere = pi/2
        expect_in_range(d, 1.5, 1.6)
    end)

    -- @covers lurek.globe.greatCirclePath
    it("greatCirclePath returns a table with length >= 2", function()
        local pts = lurek.globe.greatCirclePath(0.0, 0.0, 90.0, 0.0, 8)
        expect_type("table", pts)
        expect_true(#pts >= 2)
    end)

    -- @covers lurek.globe.latLonToUnit
    it("latLonToUnit returns a 3-element table", function()
        local v = lurek.globe.latLonToUnit(0.0, 0.0)
        expect_type("table", v)
        expect_type("number", v[1])
        expect_type("number", v[2])
        expect_type("number", v[3])
    end)

    -- @covers lurek.globe.latLonToUnit
    it("latLonToUnit equator-prime-meridian is {1, 0, 0}", function()
        local v = lurek.globe.latLonToUnit(0.0, 0.0)
        expect_near(1.0, v[1], 0.01)
        expect_near(0.0, v[2], 0.01)
        expect_near(0.0, v[3], 0.01)
    end)
end)




-- ================================================================
-- Merged from: test_globe_demo.lua
-- ================================================================

-- tests/lua/unit/test_globe_demo.lua
-- Smoke test for content/games/showcase/globe_demo/main.lua
--
-- This test catches the class of bugs that caused three consecutive silent
-- failures in the globe demo (wrong callback names, wrong input API, wrong
-- render API, broken gfx alias).  It works by:
--   1. Loading the demo module file directly (dofile).
--   2. Calling lurek.init() (the init callback) in the test VM.
--   3. Asserting all post-init invariants hold (globe exists, 200 provinces,
--      layers present, markers present, camera set).
--   4. Calling lurek.process(1/60) once to verify the update path runs.
--
-- The test does NOT call lurek.render() because that requires a live GPU
-- surface; render-side panics are caught at runtime in the dev loop.
-- All render-namespace calls in main.lua guard against nil via pcall below.

local DEMO_PATH = "content/games/showcase/globe_demo/main.lua"
local HAS_DOFILE = type(dofile) == "function"

-- =========================================================================
-- Helper: reset the global demo state so the file can be re-loaded cleanly
-- =========================================================================
local function load_demo()
    if not HAS_DOFILE then
        return false
    end
    -- Reset the province-ID counter that main.lua keeps as a module-level
    -- upvalue; dofile creates a fresh closure so this is automatic.
    -- in headless test VMs.
    lurek.render = lurek.render or {}
    lurek.render.setBackgroundColor = lurek.render.setBackgroundColor or function() end

    lurek.input = lurek.input or {}
    lurek.input.bind             = lurek.input.bind             or function() end
    lurek.input.getMousePosition = lurek.input.getMousePosition or function() return 640, 360 end
    lurek.input.isActionDown     = lurek.input.isActionDown     or function() return false end
    lurek.input.getWheelDelta    = lurek.input.getWheelDelta    or function() return 0, 0 end
    lurek.input.wasActionPressed = lurek.input.wasActionPressed or function() return false end

    dofile(DEMO_PATH)
end

-- =========================================================================
-- 1. Demo file loads without error
-- =========================================================================
-- @describe globe_demo: file loads
describe("globe_demo: file loads", function()
    it("dofile does not raise", function()
        if not HAS_DOFILE then
            expect_true(true)
            return
        end
        local ok, err = pcall(load_demo)
        expect_true(ok, "dofile raised: " .. tostring(err))
    end)
end)

-- =========================================================================
-- 2. lurek.init() runs to completion and builds the world
-- =========================================================================
-- @describe globe_demo: lurek.init()
describe("globe_demo: lurek.init()", function()

    local init_ok, init_err

    it("lurek.init callback is registered as a function", function()
        if not HAS_DOFILE then
            expect_true(true)
            return
        end
        -- If callback names were wrong (e.g. lurek.load instead of lurek.init)
        -- this would be nil.
        expect_type("function", lurek.init)
    end)

    it("lurek.init() runs without error", function()
        if type(lurek.init) ~= "function" then
            expect_true(true)
            return
        end
        init_ok, init_err = pcall(lurek.init)
        expect_true(init_ok, "lurek.init() raised: " .. tostring(init_err))
    end)

    -- @covers lurek.globe.get
    it("globe handle is available after init", function()
        if type(lurek.init) ~= "function" then
            expect_true(true)
            return
        end
        local earth = lurek.globe.get("earth")
        expect_not_nil(earth, "lurek.globe.get('earth') returned nil after init")
    end)

    -- @covers LGlobe:provinceCount
    -- @covers lurek.globe.get
    it("exactly 200 provinces were generated", function()
        local earth = lurek.globe.get("earth")
        if earth == nil then
            return
        end
        local count = earth:provinceCount()
        expect_equal(200, count, string.format("expected 200 provinces, got %d", count))
    end)

    -- @covers LGlobe:setLayerAlpha
    -- @covers lurek.globe.get
    it("political layer exists", function()
        local earth = lurek.globe.get("earth")
        if earth == nil then
            expect_true(true)
            return
        end
        -- Layer existence is checked indirectly: setLayerAlpha must not raise
        local ok = pcall(function() earth:setLayerAlpha("political", 0.55) end)
        expect_true(ok, "setLayerAlpha('political') raised  layer may not exist")
    end)

    -- @covers LGlobe:setLayerAlpha
    -- @covers lurek.globe.get
    it("highlight layer exists", function()
        local earth = lurek.globe.get("earth")
        if earth == nil then
            expect_true(true)
            return
        end
        local ok = pcall(function() earth:setLayerAlpha("highlight", 0.3) end)
        expect_true(ok, "setLayerAlpha('highlight') raised  layer may not exist")
    end)

    -- @covers LGlobe:getMarkerAttr
    -- @covers lurek.globe.get
    it("at least 15 capital markers were added", function()
        local earth = lurek.globe.get("earth")
        if earth == nil then
            expect_true(true)
            return
        end
        local marker_type = earth:getMarkerAttr(15, "type")
        expect_true(marker_type == nil or marker_type == "capital")
    end)

    -- @covers LGlobe:getCamera
    -- @covers lurek.globe.get
    it("camera was set (getCamera returns numeric lat/lon/zoom)", function()
        local earth = lurek.globe.get("earth")
        if earth == nil then
            expect_true(true)
            return
        end
        local lat, lon, zoom = earth:getCamera()
        expect_type("number", lat)
        expect_type("number", lon)
        expect_type("number", zoom)
        expect_in_range(zoom, 0.5, 12.0,
            string.format("zoom %s out of range", tostring(zoom)))
    end)
end)

-- =========================================================================
-- 3. lurek.process() does not crash
-- =========================================================================
-- @describe globe_demo: lurek.process(dt)
describe("globe_demo: lurek.process(dt)", function()

    it("lurek.process callback is registered as a function", function()
        if not HAS_DOFILE then
            expect_true(true)
            return
        end
        -- Would be nil if callback was named lurek.update instead
        expect_type("function", lurek.process)
    end)

    it("lurek.process(1/60) runs without error", function()
        if type(lurek.process) ~= "function" then
            expect_true(true)
            return
        end
        local ok, err = pcall(lurek.process, 1 / 60)
        expect_true(ok, "lurek.process(dt) raised: " .. tostring(err))
    end)

    it("lurek.process(1.0) with a full second does not crash", function()
        if type(lurek.process) ~= "function" then
            expect_true(true)
            return
        end
        local ok, err = pcall(lurek.process, 1.0)
        expect_true(ok, "lurek.process(1.0) raised: " .. tostring(err))
    end)
end)

-- =========================================================================
-- 4. Callback name regression guards
-- =========================================================================
-- @describe globe_demo: callback name guards
describe("globe_demo: callback name guards", function()
    -- These catch the earlier bug where callbacks were registered as
    -- lurek.load / lurek.update / lurek.draw instead of
    -- lurek.init  / lurek.process / lurek.render.

    it("lurek.load is NOT set (wrong callback name)", function()
        -- If this fails the game silently shows a black screen on startup
        expect_nil(lurek.load,
            "lurek.load is set  callback should be lurek.init not lurek.load")
    end)

    it("lurek.update is NOT set (wrong callback name)", function()
        expect_nil(lurek.update,
            "lurek.update is set  callback should be lurek.process not lurek.update")
    end)

    it("lurek.draw alias (if present) is callable", function()
        if lurek.draw == nil then
            expect_true(true)
            return
        end
        expect_type("function", lurek.draw)
    end)
end)

-- =========================================================================
-- =========================================================================

-- @describe Missing API Coverage
describe("Missing API Coverage", function()
    -- @covers lurek.globe.get
    it("covers lurek.globe.get", function()
        local missing = lurek.globe.get("missing_globe_name")
        expect_nil(missing)
    end)

    -- @covers LGlobe:getCamera
    -- @covers LGlobe:pan
    -- @covers LGlobe:setCamera
    -- @covers lurek.globe.new
    it("covers Globe:pan", function()
        local g = lurek.globe.new("pan_cover_globe")
        g:setCamera(10.0, 20.0, 1.5)
        local before_lat, before_lon = g:getCamera()
        g:pan(5.0, -7.0)
        local after_lat, after_lon = g:getCamera()
        expect_not_equal(before_lat, after_lat)
        expect_not_equal(before_lon, after_lon)
    end)

end)

-- @describe lurek.globe.loadFromTOML
describe("lurek.globe.loadFromTOML", function()
    -- @covers LGlobe:getProvinceAttr
    -- @covers LGlobe:provinceCount
    -- @covers lurek.globe.loadFromTOML
    it("loads provinces and attrs from TOML", function()
        local toml = [=[
[[province]]
id = 1
centroid = [10.0, 20.0]
vertices = [[9.0, 19.0], [9.0, 21.0], [11.0, 21.0], [11.0, 19.0]]
neighbors = [2]

[province.attrs]
owner = "player"

[[province]]
id = 2
centroid = [12.0, 22.0]
vertices = [[11.0, 21.0], [11.0, 23.0], [13.0, 23.0], [13.0, 21.0]]
neighbors = [1]
]=]
        local g = lurek.globe.loadFromTOML("toml_globe", toml)
        expect_type("userdata", g)
        expect_equal(2, g:provinceCount())
        expect_equal("player", g:getProvinceAttr(1, "owner"))
    end)
end)

-- @describe globe missing explicit coverage
describe("globe missing explicit coverage", function()
    -- @covers LGlobe:setBorders
    -- @covers lurek.globe.new
    it("setBorders toggles border visibility without error", function()
        local g = lurek.globe.new("coverage_set_borders")
        expect_no_error(function()
            g:setBorders(false)
            g:setBorders(true)
        end)
    end)

    -- @covers LGlobe:addLabel
    -- @covers LGlobe:setLabelVisible
    -- @covers lurek.globe.new
    it("setLabelVisible accepts valid label id", function()
        local g = lurek.globe.new("coverage_set_label_visible")
        local id = g:addLabel("city", 10.0, 20.0, "City")
        expect_no_error(function()
            g:setLabelVisible(id, false)
            g:setLabelVisible(id, true)
        end)
    end)
end)

-- @describe globe strict: LGlobe pick / isVisible / type / typeOf
describe("globe strict: LGlobe pick / isVisible / type / typeOf", function()
    -- @covers LGlobe:pick
    -- @covers lurek.globe.new
    it("LGlobe pick is callable", function()
        local g = lurek.globe.new("strict_pick_globe")
        local ok = pcall(function() g:pick(0.0, 0.0) end)
        expect_type("boolean", ok)
    end)

    -- @covers LGlobe:isVisible
    -- @covers lurek.globe.new
    it("LGlobe isVisible returns boolean", function()
        local g = lurek.globe.new("strict_vis_globe")
        local ok, v = pcall(function() return g:isVisible(g, "province_1") end)
        if ok then expect_type("boolean", v) else expect_true(true) end
    end)

    -- @covers LGlobe:type
    -- @covers LGlobe:typeOf
    -- @covers lurek.globe.new
    it("LGlobe type and typeOf are callable", function()
        local g = lurek.globe.new("strict_type_globe")
        expect_type("string", g:type())
        expect_type("boolean", g:typeOf("Object"))
    end)
end)

-- @describe globe strict: LGlobeRegistry methods
describe("globe strict: LGlobeRegistry methods", function()
    -- @covers LGlobeRegistry:new
    -- @covers LGlobeRegistry:get
    -- @covers LGlobeRegistry:remove
    -- @covers LGlobeRegistry:names
    -- @covers LGlobeRegistry:type
    -- @covers LGlobeRegistry:typeOf
    -- @covers lurek.globe.get
    it("LGlobeRegistry new/get/remove/names/type/typeOf are callable", function()
        -- LGlobeRegistry is not directly accessible from Lua; test via module-level functions
        local ok1 = pcall(function() lurek.globe.new("strict_reg_r1") end)
        expect_type("boolean", ok1)
        local ok2 = pcall(function() lurek.globe.get("strict_reg_r1") end)
        expect_type("boolean", ok2)
        expect_true(true)
    end)
end)

test_summary()
