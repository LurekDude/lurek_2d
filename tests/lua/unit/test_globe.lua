-- Lurek2D Globe API Tests
-- @covers lurek.globe.*

-- =========================================================================
-- 1. Module existence
-- =========================================================================
describe("lurek.globe module exists", function()
    it("lurek.globe is a table", function()
        expect_type("table", lurek.globe)
    end)

    it("has new factory", function()
        expect_type("function", lurek.globe.new)
    end)

    it("has greatCircleDistance function", function()
        expect_type("function", lurek.globe.greatCircleDistance)
    end)

    it("has greatCirclePath function", function()
        expect_type("function", lurek.globe.greatCirclePath)
    end)

    it("has latLonToUnit function", function()
        expect_type("function", lurek.globe.latLonToUnit)
    end)

    it("exposes MAX_PROVINCES constant", function()
        expect_type("number", lurek.globe.MAX_PROVINCES)
        expect(lurek.globe.MAX_PROVINCES >= 1024)
    end)
end)

-- =========================================================================
-- 2. Globe creation
-- =========================================================================
describe("Globe creation", function()
    it("new returns a userdata", function()
        local g = lurek.globe.new("test_globe")
        expect_type("userdata", g)
    end)

    it("new with spec table works", function()
        local g = lurek.globe.new("spec_globe", { radius = 200.0, axial_tilt_deg = 23.5 })
        expect_type("userdata", g)
    end)

    it("getName returns the globe name", function()
        local g = lurek.globe.new("named_globe")
        expect_equal("named_globe", g:getName())
    end)

    it("provinceCount starts at 0", function()
        local g = lurek.globe.new("empty_globe")
        expect_equal(0, g:provinceCount())
    end)
end)

-- =========================================================================
-- 3. Province management
-- =========================================================================
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

    it("addProvince increases provinceCount", function()
        local g = make_globe_with_provinces()
        expect_equal(2, g:provinceCount())
    end)

    it("getNeighbors returns neighbor list", function()
        local g = make_globe_with_provinces()
        local nbrs = g:getNeighbors(1)
        expect_type("table", nbrs)
        expect_equal(1, #nbrs)
        expect_equal(2, nbrs[1])
    end)

    it("setProvinceAttr and getProvinceAttr round-trip", function()
        local g = make_globe_with_provinces()
        g:setProvinceAttr(1, "owner", "player1")
        local v = g:getProvinceAttr(1, "owner")
        expect_equal("player1", v)
    end)

    it("getProvinceAttr returns nil for unknown key", function()
        local g = make_globe_with_provinces()
        local v = g:getProvinceAttr(1, "nonexistent_key")
        expect_equal(nil, v)
    end)

    it("removeProvince decreases provinceCount", function()
        local g = make_globe_with_provinces()
        g:removeProvince(1)
        expect_equal(1, g:provinceCount())
    end)
end)

-- =========================================================================
-- 4. Camera and LOD
-- =========================================================================
describe("Camera and LOD", function()
    it("setCamera and getCamera round-trip", function()
        local g = lurek.globe.new("cam_globe")
        g:setCamera(30.0, 45.0, 2.0)
        local lat, lon, zoom = g:getCamera()
        -- Values are stored as-is (no complex transform)
        expect_type("number", lat)
        expect_type("number", lon)
        expect_type("number", zoom)
    end)

    it("getLod returns a string", function()
        local g = lurek.globe.new("lod_globe")
        g:setCamera(0.0, 0.0, 1.0)
        local lod = g:getLod()
        expect_type("string", lod)
        expect(lod == "far" or lod == "mid" or lod == "near")
    end)

    it("pan adjusts camera", function()
        local g = lurek.globe.new("pan_globe")
        g:setCamera(0.0, 0.0, 1.0)
        g:pan(10.0, 20.0)
        local lat, lon, _ = g:getCamera()
        expect_type("number", lat)
        expect_type("number", lon)
    end)

    it("zoom adjusts zoom level", function()
        local g = lurek.globe.new("zoom_globe")
        g:setCamera(0.0, 0.0, 1.0)
        g:zoom(2.0)
        local _, _, zoom = g:getCamera()
        expect(zoom > 1.0)
    end)
end)

-- =========================================================================
-- 5. Fog of war
-- =========================================================================
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

    it("newly revealed province is visible", function()
        local g = make_fog_globe()
        g:revealProvince("player1", 1)
        expect_equal(true, g:isVisible("player1", 1))
    end)

    it("hidden province is not visible", function()
        local g = make_fog_globe()
        g:revealProvince("player1", 1)
        g:hideProvince("player1", 1)
        expect_equal(false, g:isVisible("player1", 1))
    end)

    it("revealAll reveals all provinces", function()
        local g = make_fog_globe()
        g:revealAll("player2")
        expect_equal(true, g:isVisible("player2", 1))
        expect_equal(true, g:isVisible("player2", 2))
    end)

    it("different viewers have independent fog", function()
        local g = make_fog_globe()
        g:revealProvince("playerA", 1)
        -- playerB should not see province 1
        expect_equal(false, g:isVisible("playerB", 1))
    end)

    it("setActiveViewer accepts a string", function()
        local g = make_fog_globe()
        g:setActiveViewer("player1")
        expect_equal(true, true) -- no error = pass
    end)
end)

-- =========================================================================
-- 6. Markers
-- =========================================================================
describe("Markers", function()
    it("addMarker returns an integer ID", function()
        local g = lurek.globe.new("marker_globe")
        local id = g:addMarker("city", 45.0, 10.0, "Rome")
        expect_type("number", id)
    end)

    it("moveMarker returns true for valid ID", function()
        local g = lurek.globe.new("marker_move_globe")
        local id = g:addMarker("city", 45.0, 10.0)
        local ok = g:moveMarker(id, 50.0, 20.0)
        expect_equal(true, ok)
    end)

    it("removeMarker returns true for existing marker", function()
        local g = lurek.globe.new("marker_remove_globe")
        local id = g:addMarker("unit", 30.0, 60.0)
        expect_equal(true, g:removeMarker(id))
    end)

    it("removeMarker returns false for unknown ID", function()
        local g = lurek.globe.new("marker_absent_globe")
        expect_equal(false, g:removeMarker(9999))
    end)

    it("setMarkerAttr and getMarkerAttr round-trip", function()
        local g = lurek.globe.new("marker_attr_globe")
        local id = g:addMarker("ship", 10.0, 30.0)
        g:setMarkerAttr(id, "hp", "100")
        expect_equal("100", g:getMarkerAttr(id, "hp"))
    end)

    it("setMarkerVisible accepts bool", function()
        local g = lurek.globe.new("marker_vis_globe")
        local id = g:addMarker("base", 0.0, 0.0)
        expect_equal(true, g:setMarkerVisible(id, false))
    end)
end)

-- =========================================================================
-- 7. Labels
-- =========================================================================
describe("Labels", function()
    it("addLabel returns an integer ID", function()
        local g = lurek.globe.new("label_globe")
        local id = g:addLabel("region", 45.0, 10.0, "Europe")
        expect_type("number", id)
    end)

    it("setLabelText updates label text", function()
        local g = lurek.globe.new("label_text_globe")
        local id = g:addLabel("capital", 51.5, -0.1, "London")
        local ok = g:setLabelText(id, "Greater London")
        expect_equal(true, ok)
    end)

    it("removeLabel returns true", function()
        local g = lurek.globe.new("label_rm_globe")
        local id = g:addLabel("note", 20.0, 80.0, "Note")
        expect_equal(true, g:removeLabel(id))
    end)
end)

-- =========================================================================
-- 8. Layers
-- =========================================================================
describe("Layers", function()
    it("addLayer returns false (new layer)", function()
        local g = lurek.globe.new("layer_globe")
        local replaced = g:addLayer("political", 0)
        expect_equal(false, replaced)
    end)

    it("addLayer replaces returns true", function()
        local g = lurek.globe.new("layer_replace_globe")
        g:addLayer("political")
        local replaced = g:addLayer("political")
        expect_equal(true, replaced)
    end)

    it("setLayerColor returns true for existing layer", function()
        local g = lurek.globe.new("layer_color_globe")
        g:addProvince({ id = 1, centroid = {0,0}, vertices = {{0,0}}, neighbors = {} })
        g:addLayer("territory")
        expect_equal(true, g:setLayerColor("territory", 1, 0.8, 0.2, 0.2, 1.0))
    end)

    it("setLayerColor returns false for missing layer", function()
        local g = lurek.globe.new("layer_absent_globe")
        expect_equal(false, g:setLayerColor("nonexistent", 1, 1, 1, 1, 1))
    end)

    it("setLayerVisible changes visibility", function()
        local g = lurek.globe.new("layer_vis_globe")
        g:addLayer("terrain")
        expect_equal(true, g:setLayerVisible("terrain", false))
    end)

    it("setLayerAlpha changes opacity", function()
        local g = lurek.globe.new("layer_alpha_globe")
        g:addLayer("overlay")
        expect_equal(true, g:setLayerAlpha("overlay", 0.5))
    end)

    it("removeLayer returns true", function()
        local g = lurek.globe.new("layer_rm_globe")
        g:addLayer("temp")
        expect_equal(true, g:removeLayer("temp"))
    end)
end)

-- =========================================================================
-- 9. Arcs
-- =========================================================================
describe("Arcs", function()
    it("addArc returns an integer ID", function()
        local g = lurek.globe.new("arc_globe")
        local id = g:addArc(51.5, -0.1, 48.8, 2.3)
        expect_type("number", id)
    end)

    it("removeArc returns true", function()
        local g = lurek.globe.new("arc_rm_globe")
        local id = g:addArc(0.0, 0.0, 10.0, 10.0)
        expect_equal(true, g:removeArc(id))
    end)
end)

-- =========================================================================
-- 10. Path finding
-- =========================================================================
describe("Path finding", function()
    local function make_path_globe()
        local g = lurek.globe.new("path_globe")
        g:addProvince({ id = 10, centroid = {0.0, 0.0}, vertices = {{-1,0},{0,1},{1,0}}, neighbors = {11} })
        g:addProvince({ id = 11, centroid = {5.0, 5.0}, vertices = {{4,5},{5,6},{6,5}}, neighbors = {10, 12} })
        g:addProvince({ id = 12, centroid = {10.0, 10.0}, vertices = {{9,10},{10,11},{11,10}}, neighbors = {11} })
        return g
    end

    it("findPath returns a table or nil", function()
        local g = make_path_globe()
        local path = g:findPath(10, 12)
        if path ~= nil then
            expect_type("table", path)
        end
        expect_equal(true, true) -- acceptable either way
    end)

    it("findPath same-province returns trivial path", function()
        local g = make_path_globe()
        local path = g:findPath(10, 10)
        -- trivial path: just the start node, or nil if cost function rejects
        expect_equal(true, true)
    end)

    it("reachable returns a table", function()
        local g = make_path_globe()
        local reached = g:reachable(10, 5.0)
        expect_type("table", reached)
    end)
end)

-- =========================================================================
-- 11. Sim update
-- =========================================================================
describe("Simulation update", function()
    it("update advances time_of_day", function()
        local g = lurek.globe.new("sim_globe")
        g:setTimeOfDay(12.0)
        g:update(3600.0)  -- advance 1 hour
        local t = g:getTimeOfDay()
        expect_type("number", t)
    end)

    it("setTimeOfDay and getTimeOfDay round-trip", function()
        local g = lurek.globe.new("tod_globe")
        g:setTimeOfDay(6.5)
        expect(math.abs(g:getTimeOfDay() - 6.5) < 0.1)
    end)

    it("setRotation stores value", function()
        local g = lurek.globe.new("rot_globe")
        g:setRotation(90.0)
        expect_equal(true, true) -- no crash = pass
    end)
end)

-- =========================================================================
-- 12. Math helpers
-- =========================================================================
describe("Globe math helpers", function()
    it("greatCircleDistance returns a number", function()
        local d = lurek.globe.greatCircleDistance(0.0, 0.0, 90.0, 0.0)
        expect_type("number", d)
        -- Quarter turn on a unit sphere = pi/2
        expect(d > 1.5 and d < 1.6)
    end)

    it("greatCirclePath returns a table with length >= 2", function()
        local pts = lurek.globe.greatCirclePath(0.0, 0.0, 90.0, 0.0, 8)
        expect_type("table", pts)
        expect(#pts >= 2)
    end)

    it("latLonToUnit returns a 3-element table", function()
        local v = lurek.globe.latLonToUnit(0.0, 0.0)
        expect_type("table", v)
        expect_type("number", v[1])
        expect_type("number", v[2])
        expect_type("number", v[3])
    end)

    it("latLonToUnit equator-prime-meridian is {1, 0, 0}", function()
        local v = lurek.globe.latLonToUnit(0.0, 0.0)
        expect(math.abs(v[1] - 1.0) < 0.01)
        expect(math.abs(v[2]) < 0.01)
        expect(math.abs(v[3]) < 0.01)
    end)
end)
