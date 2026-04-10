-- Target rendering/drawing contract acceptance tests.
-- These assertions pin the intended public API from
-- work/rendering-drawing-current-state/reports/target-rendering-drawing-state.md.
-- Canonical constructors are asserted directly; legacy constructors are used only
-- as fallbacks to build objects for method-level contract checks.

local function try_call(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then
        return result
    end
    return nil
end

local function expect_image_data_contract(img)
    expect_not_nil(img, "draw_to_image should return an image object")
    if img ~= nil then
        if type(img.width) == "function" then
            expect_true(img:width() > 0, "image width should be positive")
        elseif type(img.getWidth) == "function" then
            expect_true(img:getWidth() > 0, "image width should be positive")
        end
    end
end

local function make_spine_subject()
    if lurek.spine ~= nil then
        if type(lurek.spine.new) == "function" then
            local sk = try_call(lurek.spine.new, { name = "contract" })
            if sk ~= nil then
                return sk
            end
        end
        if type(lurek.spine.newSkeleton) == "function" then
            return lurek.spine.newSkeleton("contract")
        end
    end
    error("No usable spine constructor available for contract test")
end

local function make_raycaster_subject()
    local rc = lurek.raycaster.new(8, 8)
    rc:setCell(5, 4, 1)
    return rc
end

local function make_ui_panel_subject()
    if lurek.ui ~= nil then
        if type(lurek.ui.panel) == "function" then
            local panel = try_call(lurek.ui.panel, {})
            if panel ~= nil then
                return panel
            end
        end
        if type(lurek.ui.newPanel) == "function" then
            return lurek.ui.newPanel()
        end
    end
    error("No usable UI panel constructor available for contract test")
end

local function make_particle_subject()
    if lurek.particle ~= nil and type(lurek.particle.new) == "function" then
        local ps = try_call(lurek.particle.new, { max_count = 8, emit_rate = 0 })
        if ps ~= nil then
            return ps
        end
    end
    if lurek.particles ~= nil and type(lurek.particles.newSystem) == "function" then
        return lurek.particles.newSystem({ maxParticles = 8, emissionRate = 0 })
    end
    error("No usable particle constructor available for contract test")
end

local function make_tilemap_subject()
    if lurek.tilemap ~= nil then
        if type(lurek.tilemap.new) == "function" then
            local map = try_call(lurek.tilemap.new, { width = 4, height = 4, tile_width = 16, tile_height = 16 })
            if map ~= nil then
                return map
            end
        end
        if type(lurek.tilemap.newTileMap) == "function" then
            local map = lurek.tilemap.newTileMap(4, 4)
            if type(map.setTile) == "function" then
                try_call(function()
                    map:setTile(1, 1, 1, 1)
                end)
            end
            return map
        end
    end
    error("No usable tilemap constructor available for contract test")
end

local function make_minimap_subject()
    if lurek.minimap ~= nil then
        if type(lurek.minimap.new) == "function" then
            local mini = try_call(lurek.minimap.new, {
                tile_data = {
                    1, 1, 0, 0,
                    0, 1, 1, 0,
                    0, 0, 1, 1,
                    1, 0, 0, 1,
                },
                width = 4,
                height = 4,
                pixel_size = 4,
            })
            if mini ~= nil then
                return mini
            end
        end
        if type(lurek.minimap.newMinimap) == "function" then
            local mini = lurek.minimap.newMinimap(4, 4, 64, 64)
            if type(mini.setTerrainData) == "function" then
                mini:setTerrainData({
                    1, 1, 0, 0,
                    0, 1, 1, 0,
                    0, 0, 1, 1,
                    1, 0, 0, 1,
                })
            end
            return mini
        end
    end
    error("No usable minimap constructor available for contract test")
end

local function make_overlay_subject()
    if lurek.overlay ~= nil then
        if type(lurek.overlay.new) == "function" then
            local ov = try_call(lurek.overlay.new)
            if ov ~= nil then
                return ov
            end
        end
        if type(lurek.overlay.newOverlay) == "function" then
            return lurek.overlay.newOverlay(64, 64)
        end
    end
    if lurek.effect ~= nil and type(lurek.effect.newOverlay) == "function" then
        return lurek.effect.newOverlay(64, 64)
    end
    error("No usable overlay constructor available for contract test")
end

local function make_parallax_subject()
    if lurek.parallax ~= nil then
        if type(lurek.parallax.new) == "function" then
            local bg = try_call(lurek.parallax.new, { layers = {} })
            if bg ~= nil then
                return bg
            end
        end
        if type(lurek.parallax.newSet) == "function" then
            local set = lurek.parallax.newSet("contract")
            if type(lurek.parallax.newLayer) == "function" and lurek.graphic ~= nil and type(lurek.graphic.newImage) == "function" then
                local img = lurek.graphic.newImage("assets/icon.png")
                local layer = try_call(lurek.parallax.newLayer, { texture = img })
                if layer ~= nil then
                    set:addLayer(layer)
                end
            end
            return set
        end
    end
    error("No usable parallax constructor available for contract test")
end

describe("target rendering/drawing contract: spine", function()
    it("exposes lurek.spine.load as the canonical constructor", function()
        expect_type("function", lurek.spine.load)
    end)

    it("skeleton objects expose render()", function()
        local sk = make_spine_subject()
        expect_type("function", sk.render)
        expect_no_error(function()
            sk:render()
        end)
    end)

    it("skeleton objects expose draw_to_image()", function()
        local sk = make_spine_subject()
        expect_type("function", sk.draw_to_image)
        local img = sk:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: raycaster", function()
    it("raycaster objects expose render()", function()
        local rc = make_raycaster_subject()
        expect_type("function", rc.render)
        expect_no_error(function()
            rc:render()
        end)
    end)

    it("raycaster objects expose draw_to_image()", function()
        local rc = make_raycaster_subject()
        expect_type("function", rc.draw_to_image)
        local img = rc:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: ui", function()
    it("exposes lurek.ui.panel as the canonical panel constructor", function()
        expect_type("function", lurek.ui.panel)
    end)

    it("panel widgets expose render() instead of relying only on lurek.ui.draw()", function()
        local panel = make_ui_panel_subject()
        expect_type("function", panel.render)
        expect_no_error(function()
            panel:render()
        end)
    end)
end)

describe("target rendering/drawing contract: particle", function()
    it("exposes lurek.particle.new as the canonical constructor", function()
        expect_type("table", lurek.particle)
        expect_type("function", lurek.particle.new)
    end)

    it("particle systems expose render()", function()
        local ps = make_particle_subject()
        expect_type("function", ps.render)
        expect_no_error(function()
            ps:render()
        end)
    end)

    it("particle systems expose draw_to_image()", function()
        local ps = make_particle_subject()
        expect_type("function", ps.draw_to_image)
        local img = ps:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: tilemap", function()
    it("exposes lurek.tilemap.load as the canonical loader", function()
        expect_type("function", lurek.tilemap.load)
    end)

    it("tilemaps expose render()", function()
        local map = make_tilemap_subject()
        expect_type("function", map.render)
        expect_no_error(function()
            map:render()
        end)
    end)

    it("tilemaps expose draw_to_image()", function()
        local map = make_tilemap_subject()
        expect_type("function", map.draw_to_image)
        local img = map:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: minimap", function()
    it("exposes lurek.minimap.new as the canonical constructor", function()
        expect_type("function", lurek.minimap.new)
    end)

    it("minimaps expose render()", function()
        local mini = make_minimap_subject()
        expect_type("function", mini.render)
        expect_no_error(function()
            mini:render()
        end)
    end)

    it("minimaps expose draw_to_image()", function()
        local mini = make_minimap_subject()
        expect_type("function", mini.draw_to_image)
        local img = mini:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: overlay", function()
    it("exposes lurek.overlay.new as the canonical constructor", function()
        expect_type("table", lurek.overlay)
        expect_type("function", lurek.overlay.new)
    end)

    it("overlays expose render()", function()
        local ov = make_overlay_subject()
        expect_type("function", ov.render)
        expect_no_error(function()
            ov:render()
        end)
    end)

    it("overlays expose draw_to_image()", function()
        local ov = make_overlay_subject()
        if type(ov.flash) == "function" then
            ov:flash(1, 1, 1, 1, 0.1)
        end
        expect_type("function", ov.draw_to_image)
        local img = ov:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: parallax", function()
    it("exposes lurek.parallax.new as the canonical constructor", function()
        expect_type("function", lurek.parallax.new)
    end)

    it("parallax sets expose render()", function()
        local bg = make_parallax_subject()
        expect_type("function", bg.render)
        expect_no_error(function()
            bg:render()
        end)
    end)
end)

describe("target rendering/drawing contract: entity", function()
    it("world objects expose render()", function()
        local world = lurek.entity.newUniverse()
        expect_type("function", world.render)
    end)

    it("world:render() dispatches render() and not draw() on systems", function()
        local world = lurek.entity.newUniverse()
        local render_count = 0
        local draw_count = 0

        local sys = {}
        function sys:render(_world)
            render_count = render_count + 1
        end

        function sys:draw(_world)
            draw_count = draw_count + 1
        end

        world:addSystem(sys)
        world:render()

        expect_equal(1, render_count)
        expect_equal(0, draw_count)
    end)
end)

test_summary()
