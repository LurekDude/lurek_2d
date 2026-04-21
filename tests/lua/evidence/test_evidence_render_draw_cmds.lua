-- test_evidence_render_draw_cmds.lua
-- Evidence test: new lurek.render draw commands (bezier curves, gradient rect,
-- colored polygon, iso cube tile, hex tile, sort group, bevel rect, layers, path).

-- @description Covers suite: Evidence: lurek.render new GPU draw commands.
describe("Evidence: lurek.render new GPU draw commands", function()

    -- ── Quad Bézier ──────────────────────────────────────────────────────────
    -- @covers lurek.render.drawQuadBezier
    it("drawQuadBezier: no error on valid call", function()
        local ok = pcall(lurek.render.drawQuadBezier,
            0, 0,     -- start
            100, -50, -- control
            200, 0,   -- end
            {r=1, g=1, b=0, a=1}, -- color
            2.0        -- line_width
        )
        expect_equal(ok, true)
    end)

    -- @covers lurek.render.drawQuadBezier
    it("drawQuadBezier: default line_width (no error)", function()
        local ok = pcall(lurek.render.drawQuadBezier,
            0, 0, 50, -80, 100, 0, {r=0, g=1, b=0, a=1}
        )
        expect_equal(ok, true)
    end)

    -- ── Cubic Bézier ─────────────────────────────────────────────────────────
    -- @covers lurek.render.drawCubicBezier
    it("drawCubicBezier: no error on valid call", function()
        local ok = pcall(lurek.render.drawCubicBezier,
            0, 0,
            33, -60, 66, -60,
            100, 0,
            {r=1, g=0, b=1, a=1}, 1.5
        )
        expect_equal(ok, true)
    end)

    -- ── Draw Path ────────────────────────────────────────────────────────────
    -- @covers lurek.render.drawPath
    it("drawPath: open path no error", function()
        local ok = pcall(lurek.render.drawPath,
            {0, 0, 50, 30, 100, 10, 150, 60},
            {r=0, g=0.8, b=1, a=1},
            false, 2.0
        )
        expect_equal(ok, true)
    end)

    -- @covers lurek.render.drawPath
    it("drawPath: closed path no error", function()
        local ok = pcall(lurek.render.drawPath,
            {0, 0, 60, 0, 60, 60, 0, 60},
            {r=1, g=0.5, b=0, a=1},
            true
        )
        expect_equal(ok, true)
    end)

    -- ── Gradient Rect ────────────────────────────────────────────────────────
    -- @covers lurek.render.drawGradientRect
    it("drawGradientRect: vertical gradient no error", function()
        local ok = pcall(lurek.render.drawGradientRect,
            10, 10, 200, 100,
            {r=1, g=0, b=0, a=1},  -- top-left
            {r=1, g=0, b=0, a=1},  -- top-right
            {r=0, g=0, b=1, a=1},  -- bottom-right
            {r=0, g=0, b=1, a=1}   -- bottom-left
        )
        expect_equal(ok, true)
    end)

    -- @covers lurek.render.drawGradientRect
    it("drawGradientRect: corner gradient no error", function()
        local c = {r=0, g=0, b=0, a=1}
        local ok = pcall(lurek.render.drawGradientRect,
            0, 0, 64, 64,
            {r=1,g=0,b=0,a=1}, {r=0,g=1,b=0,a=1},
            {r=0,g=0,b=1,a=1}, {r=1,g=1,b=0,a=1}
        )
        expect_equal(ok, true)
    end)

    -- ── Colored Polygon ──────────────────────────────────────────────────────
    -- @covers lurek.render.drawColoredPolygon
    it("drawColoredPolygon: triangle no error", function()
        local verts = {
            {x=100, y=0,   r=1, g=0, b=0, a=1},
            {x=200, y=200, r=0, g=1, b=0, a=1},
            {x=0,   y=200, r=0, g=0, b=1, a=1},
        }
        local ok = pcall(lurek.render.drawColoredPolygon, verts)
        expect_equal(ok, true)
    end)

    -- ── Isometric Cube Tile ──────────────────────────────────────────────────
    -- @covers lurek.render.drawIsoCubeTile
    it("drawIsoCubeTile: no error", function()
        local ok = pcall(lurek.render.drawIsoCubeTile,
            200, 150, 32,
            {r=0.8, g=0.8, b=0.8, a=1},  -- top
            {r=0.5, g=0.5, b=0.5, a=1},  -- left
            {r=0.6, g=0.6, b=0.6, a=1}   -- right
        )
        expect_equal(ok, true)
    end)

    -- ── Hex Tile ─────────────────────────────────────────────────────────────
    -- @covers lurek.render.drawHexTile
    it("drawHexTile: flat-top no error", function()
        local ok = pcall(lurek.render.drawHexTile,
            150, 150, 30,
            "flat",
            {r=0.2, g=0.6, b=0.2, a=1}
        )
        expect_equal(ok, true)
    end)

    -- @covers lurek.render.drawHexTile
    it("drawHexTile: pointy-top with border no error", function()
        local ok = pcall(lurek.render.drawHexTile,
            300, 150, 30,
            "pointy",
            {r=0.3, g=0.5, b=0.8, a=1},
            {r=0.1, g=0.1, b=0.1, a=1},
            2.0
        )
        expect_equal(ok, true)
    end)

    -- ── Sort Group ───────────────────────────────────────────────────────────
    -- @covers lurek.render.beginSortGroup
    -- @covers lurek.render.pushSortKey
    -- @covers lurek.render.flushSortGroup
    it("sort group: begin / pushKey / flush no error", function()
        local ok = pcall(function()
            lurek.render.beginSortGroup(42)
            lurek.render.pushSortKey(0.5)
            lurek.render.flushSortGroup(42)
        end)
        expect_equal(ok, true)
    end)

    -- ── Bevel Rect ───────────────────────────────────────────────────────────
    -- @covers lurek.render.drawBevelRect
    it("drawBevelRect: minimal call no error", function()
        local ok = pcall(lurek.render.drawBevelRect,
            50, 50, 120, 80
        )
        expect_equal(ok, true)
    end)

    -- @covers lurek.render.drawBevelRect
    it("drawBevelRect: with bevel size and style opts no error", function()
        local ok = pcall(lurek.render.drawBevelRect,
            10, 10, 200, 100, 6, {
                fillColor      = {r=0.7, g=0.7, b=0.9, a=1},
                highlight      = {r=1,   g=1,   b=1,   a=0.6},
                shadow         = {r=0.2, g=0.2, b=0.2, a=0.8},
            }
        )
        expect_equal(ok, true)
    end)

    -- ── Layer Push / Pop ─────────────────────────────────────────────────────
    -- @covers lurek.render.pushLayer
    -- @covers lurek.render.popLayer
    it("pushLayer / popLayer: no error", function()
        local ok = pcall(function()
            lurek.render.pushLayer("add", 0.8)
            lurek.render.popLayer()
        end)
        expect_equal(ok, true)
    end)

    -- @covers lurek.render.pushLayer
    it("pushLayer: default args (no blend, no alpha) no error", function()
        local ok = pcall(function()
            lurek.render.pushLayer()
            lurek.render.popLayer()
        end)
        expect_equal(ok, true)
    end)

end)
test_summary()
