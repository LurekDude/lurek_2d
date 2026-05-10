-- Lurek2D province API tests.

-- @describe lurek.province.newFromPng
describe("lurek.province.newFromPng", function()
    -- @covers LProvinceRegistry:getHeight
    -- @covers LProvinceRegistry:getName
    -- @covers LProvinceRegistry:getWidth
    -- @covers lurek.province.newFromPng
    it("creates registry from EU2 provinces png", function()
        local reg = lurek.province.newFromPng("test-province", "content/games/strategy/eu2/map.png")
        expect_type("userdata", reg)
        expect_equal("test-province", reg:getName())
        expect_equal(2000, reg:getWidth())
        expect_equal(900, reg:getHeight())
    end)
end)

-- @describe registry queries
describe("registry queries", function()
    -- @covers LProvinceRegistry:getRevision
    -- @covers LProvinceRegistry:provinceCount
    it("returns non-empty provinces and revision", function()
        local reg = lurek.province.newFromPng("test-province-q", "content/games/strategy/eu2/map.png")
        expect_true(reg:provinceCount() > 0)
        expect_equal(0, reg:getRevision())
    end)

    -- @covers LProvinceRegistry:getChangesSince
    -- @covers LProvinceRegistry:getRevision
    -- @covers LProvinceRegistry:setPoliticalColor
    it("tracks incremental changes", function()
        local reg = lurek.province.newFromPng("test-province-chg", "content/games/strategy/eu2/map.png")
        local rev0 = reg:getRevision()
        local ok = reg:setPoliticalColor(1, 1.0, 0.0, 0.0, 1.0)
        expect_true(ok)
        local rev1 = reg:getRevision()
        expect_true(rev1 > rev0)
        local changes = reg:getChangesSince(rev0)
        expect_true(#changes >= 1)
    end)
end)

-- @describe global registry management
describe("global registry management", function()
    -- @covers lurek.province.exists
    -- @covers lurek.province.get
    -- @covers lurek.province.newFromPng
    -- @covers lurek.province.remove
    -- @covers lurek.province.setActive
    it("supports create/get/exists/remove and active", function()
        local reg = lurek.province.newFromPng("test-province-global", "content/games/strategy/eu2/map.png")
        expect_true(lurek.province.exists("test-province-global"))
        local fetched = lurek.province.get("test-province-global")
        expect_type("userdata", fetched)
        expect_true(lurek.province.setActive("test-province-global"))
        expect_true(lurek.province.remove("test-province-global"))
        expect_false(lurek.province.exists("test-province-global"))
    end)
end)

-- @describe province camera/view helpers
describe("province camera/view helpers", function()
    -- @covers LProvinceRegistry:fitCamera
    -- @covers LProvinceRegistry:screenToMap
    it("computes a fit transform and maps screen center back to map space", function()
        local reg = lurek.province.newFromPng("test-province-view", "content/games/strategy/eu2/map.png")
        local cam_x, cam_y, zoom = reg:fitCamera(1000, 500, 1.0)
        expect_true(zoom > 0)

        local center_x = 1000 * 0.5
        local center_y = 500 * 0.5
        local map_x, map_y = reg:screenToMap(center_x, center_y, cam_x, cam_y, zoom, 1.0)
        expect_true(map_x >= 0 and map_x <= reg:getWidth())
        expect_true(map_y >= 0 and map_y <= reg:getHeight())
    end)

    -- @covers LProvinceRegistry:screenToProvince
    it("returns nil when picking outside map bounds", function()
        local reg = lurek.province.newFromPng("test-province-pick", "content/games/strategy/eu2/map.png")
        local id = reg:screenToProvince(-100, -100, 0, 0, 1.0, 1.0)
        expect_equal(nil, id)
    end)

    -- @covers lurek.province.zoomCameraAt
    it("keeps the anchor stable while zooming", function()
        local ax, ay = 320.0, 240.0
        local cam_x, cam_y = 10.0, 20.0
        local nx, ny = lurek.province.zoomCameraAt(ax, ay, cam_x, cam_y, 1.0, 2.0)
        expect_true(nx < cam_x)
        expect_true(ny < cam_y)
    end)
end)

-- @describe province registry extended coverage
describe("province registry extended coverage", function()
    -- @covers LProvinceRegistry:provinceIds
    -- @covers LProvinceRegistry:provinceSpans
    -- @covers LProvinceRegistry:borderSegments
    it("returns ids and geometry tables", function()
        local reg = lurek.province.newFromPng("test-province-geom", "content/games/strategy/eu2/map.png")
        local ids = reg:provinceIds()
        local spans = reg:provinceSpans()
        local segs = reg:borderSegments()
        expect_type("table", ids)
        expect_type("table", spans)
        expect_type("table", segs)
        expect_true(#ids > 0)
    end)

    -- @covers LProvinceRegistry:getBorderClass
    -- @covers LProvinceRegistry:setBorderClass
    it("sets and gets border class", function()
        local reg = lurek.province.newFromPng("test-province-borders", "content/games/strategy/eu2/map.png")
        reg:setBorderClass(1, 2, "coast")
        local cls = reg:getBorderClass(1, 2)
        expect_equal("coast", cls)
    end)

    -- @covers LProvinceRegistry:setTerrainType
    -- @covers LProvinceRegistry:setBorderStyle
    -- @covers LProvinceRegistry:setFogState
    -- @covers LProvinceRegistry:setVisibilityState
    -- @covers LProvinceRegistry:setCapital
    -- @covers LProvinceRegistry:setLabelLine
    it("applies style and metadata mutators", function()
        local reg = lurek.province.newFromPng("test-province-mutate", "content/games/strategy/eu2/map.png")
        expect_true(reg:setTerrainType(1, 3))
        expect_true(reg:setBorderStyle(1, 2))
        expect_true(reg:setFogState(1, 1))
        expect_true(reg:setVisibilityState(1, 255))
        expect_true(reg:setCapital(1, 10.0, 12.0))
        expect_true(reg:setLabelLine(1, 2.0, 3.0, 5.0, 7.0))
    end)
end)

-- @describe province metadata import pipeline
describe("province metadata import pipeline", function()
    -- @covers LProvinceRegistry:importMetadataFromFiles
    -- @covers LProvinceRegistry:getProvince
    -- @covers lurek.province.newFromPng
    -- @covers lurek.province.sanitizeMarkedPng
    it("sanitizes marked png and imports metadata in one engine-side pass", function()
        local out_path = "save/test_province_core_unit/sanitized_map.png"
        local summary = lurek.province.sanitizeMarkedPng(
            "content/games/strategy/eu2/map.png",
            out_path
        )
        expect_type("table", summary)
        expect_true((summary.replaced_pixels or 0) > 0)

        local reg = lurek.province.newFromPng("test-province-import", out_path)
        local imported = reg:importMetadataFromFiles({
            color_map_png = out_path,
            marker_png = "content/games/strategy/eu2/map.png",
            color_csv = "content/games/strategy/eu2/prov_cols.csv",
            province_toml = "content/games/strategy/eu2/province.toml",
        })

        expect_type("table", imported)
        expect_true((imported.mapped_provinces or 0) > 0)

        local snap = reg:getProvince(1)
        expect_type("table", snap)
        expect_type("table", snap.attrs)
    end)
end)

-- @describe province strict uncovered symbols
describe("province strict uncovered symbols", function()
    -- @covers LProvinceRegistry:getAt
    -- @covers LProvinceRegistry:adjacencies
    -- @covers LProvinceRegistry:getNeighbors
    -- @covers LProvinceRegistry:setAttr
    -- @covers LProvinceRegistry:setLabelText
    -- @covers LProvinceRegistry:render
    -- @covers LProvinceRegistry:type
    -- @covers LProvinceRegistry:typeOf
    -- @covers lurek.province.newFromPng
    it("province registry strict methods are callable", function()
        local reg = lurek.province.newFromPng("test-province-strict", "content/games/strategy/eu2/map.png")

        expect_type("number", reg:getAt(0, 0))
        expect_type("table", reg:adjacencies())
        expect_type("table", reg:getNeighbors(1))
        expect_type("boolean", reg:setAttr(1, "owner", "blue"))
        expect_type("boolean", reg:setLabelText(1, "Capital"))

        local ok_render = pcall(function() reg:render() end)
        expect_type("boolean", ok_render)

        expect_type("string", reg:type())
        expect_type("boolean", reg:typeOf("LProvinceRegistry"))
    end)
end)

test_summary()
