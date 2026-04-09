//! Integration tests for the `lurek.minimap.*` Lua API.

use lurek2d::engine::config::Config;
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(lurek2d::lua_api::SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    lurek2d::lua_api::create_lua_vm(state, &Config::default().modules).expect("VM creation failed")
}

// ── Factory and type ──

#[test]
fn minimap_new_basic() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(64, 48)
        assert(m:type() == "Minimap")
        assert(m:typeOf("Minimap"))
        assert(m:typeOf("Object"))
        assert(not m:typeOf("Image"))
    "#,
    )
    .exec()
    .expect("minimap_new_basic failed");
}

#[test]
fn minimap_new_with_display_size() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(100, 80, 200, 160)
        assert(m:getDisplayWidth() == 200)
        assert(m:getDisplayHeight() == 160)
    "#,
    )
    .exec()
    .expect("minimap_new_with_display_size failed");
}

// ── Grid dimensions ──

#[test]
fn minimap_grid_size() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(32, 24)
        assert(m:getGridWidth() == 32)
        assert(m:getGridHeight() == 24)
        local w, h = m:getGridSize()
        assert(w == 32 and h == 24)
    "#,
    )
    .exec()
    .expect("minimap_grid_size failed");
}

// ── Display size ──

#[test]
fn minimap_display_size() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(64, 64)
        m:setDisplaySize(256, 128)
        assert(m:getDisplayWidth() == 256)
        assert(m:getDisplayHeight() == 128)
        local w, h = m:getDisplaySize()
        assert(w == 256 and h == 128)
    "#,
    )
    .exec()
    .expect("minimap_display_size failed");
}

// ── Terrain ──

#[test]
fn minimap_terrain() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        -- default terrain is 0
        assert(m:getTerrain(1, 1) == 0)
        m:setTerrain(3, 4, 5)
        assert(m:getTerrain(3, 4) == 5)
    "#,
    )
    .exec()
    .expect("minimap_terrain failed");
}

#[test]
fn minimap_terrain_color() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        m:setTerrainColor(1, 0.2, 0.4, 0.6, 0.8)
        local r, g, b, a = m:getTerrainColor(1)
        assert(math.abs(r - 0.2) < 0.001)
        assert(math.abs(g - 0.4) < 0.001)
        assert(math.abs(b - 0.6) < 0.001)
        assert(math.abs(a - 0.8) < 0.001)
    "#,
    )
    .exec()
    .expect("minimap_terrain_color failed");
}

#[test]
fn minimap_terrain_color_default_alpha() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        m:setTerrainColor(2, 0.1, 0.2, 0.3)
        local r, g, b, a = m:getTerrainColor(2)
        assert(math.abs(a - 1.0) < 0.001, "alpha should default to 1.0")
    "#,
    )
    .exec()
    .expect("minimap_terrain_color_default_alpha failed");
}

// ── Fog of war ──

#[test]
fn minimap_fog_toggle() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        assert(not m:isFogEnabled())
        m:setFogEnabled(true)
        assert(m:isFogEnabled())
        m:setFogEnabled(false)
        assert(not m:isFogEnabled())
    "#,
    )
    .exec()
    .expect("minimap_fog_toggle failed");
}

#[test]
fn minimap_fog_level() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        -- default fog level is 0 (hidden)
        assert(m:getFogLevel(1, 1) == 0)
        m:setFogLevel(2, 3, 2) -- visible
        assert(m:getFogLevel(2, 3) == 2)
        m:setFogLevel(2, 3, 1) -- explored
        assert(m:getFogLevel(2, 3) == 1)
    "#,
    )
    .exec()
    .expect("minimap_fog_level failed");
}

#[test]
fn minimap_fog_color() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        m:setFogColor(0.1, 0.2, 0.3, 0.5)
        local r, g, b, a = m:getFogColor()
        assert(math.abs(r - 0.1) < 0.001)
        assert(math.abs(g - 0.2) < 0.001)
        assert(math.abs(b - 0.3) < 0.001)
        assert(math.abs(a - 0.5) < 0.001)
    "#,
    )
    .exec()
    .expect("minimap_fog_color failed");
}

#[test]
fn minimap_fog_data_bulk() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(3, 3)
        -- setFogData expects a flat table of w*h values, row-major, 1-based
        m:setFogData({
            2, 1, 0,
            0, 2, 1,
            1, 0, 2,
        })
        assert(m:getFogLevel(1, 1) == 2)
        assert(m:getFogLevel(2, 1) == 1)
        assert(m:getFogLevel(3, 1) == 0)
        assert(m:getFogLevel(1, 2) == 0)
        assert(m:getFogLevel(2, 2) == 2)
        assert(m:getFogLevel(3, 3) == 2)
    "#,
    )
    .exec()
    .expect("minimap_fog_data_bulk failed");
}

// ── Object types ──

#[test]
fn minimap_object_types() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        assert(m:getObjectTypeCount() == 0)
        local idx = m:addObjectType("unit", 1.0, 0.0, 0.0)
        assert(idx == 1) -- 1-based
        assert(m:getObjectTypeCount() == 1)
        local idx2 = m:addObjectType("building", 0.0, 0.0, 1.0, 0.8)
        assert(idx2 == 2)
        assert(m:getObjectTypeCount() == 2)
    "#,
    )
    .exec()
    .expect("minimap_object_types failed");
}

#[test]
fn minimap_object_type_visibility() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        local idx = m:addObjectType("unit", 1.0, 0.0, 0.0)
        assert(m:isObjectTypeVisible(idx))
        m:setObjectTypeVisible(idx, false)
        assert(not m:isObjectTypeVisible(idx))
    "#,
    )
    .exec()
    .expect("minimap_object_type_visibility failed");
}

// ── Objects ──

#[test]
fn minimap_objects() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(100, 100)
        local idx = m:addObjectType("unit", 1.0, 0.0, 0.0)
        assert(m:getObjectCount() == 0)
        m:setObject(1, 50.0, 60.0, idx)
        assert(m:getObjectCount() == 1)
        m:setObject(2, 70.0, 80.0, idx, 1) -- owner 1
        assert(m:getObjectCount() == 2)
        assert(m:removeObject(1))
        assert(m:getObjectCount() == 1)
        assert(not m:removeObject(999)) -- non-existent
        m:clearObjects()
        assert(m:getObjectCount() == 0)
    "#,
    )
    .exec()
    .expect("minimap_objects failed");
}

// ── Owner colors ──

#[test]
fn minimap_owner_colors() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        m:setOwnerColor(1, 0.0, 0.0, 1.0, 0.9)
        local r, g, b, a = m:getOwnerColor(1)
        assert(math.abs(r - 0.0) < 0.001)
        assert(math.abs(g - 0.0) < 0.001)
        assert(math.abs(b - 1.0) < 0.001)
        assert(math.abs(a - 0.9) < 0.001)
    "#,
    )
    .exec()
    .expect("minimap_owner_colors failed");
}

// ── Color mode ──

#[test]
fn minimap_color_mode() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        assert(m:getColorMode() == "terrain")
        m:setColorMode("political")
        assert(m:getColorMode() == "political")
        m:setColorMode("terrain")
        assert(m:getColorMode() == "terrain")
    "#,
    )
    .exec()
    .expect("minimap_color_mode failed");
}

#[test]
fn minimap_color_mode_invalid() {
    let lua = make_vm();
    let result = lua
        .load(
            r#"
        local m = luna.minimap.newMinimap(10, 10)
        m:setColorMode("invalid")
    "#,
        )
        .exec();
    assert!(result.is_err(), "invalid color mode should error");
}

// ── Zoom and pan ──

#[test]
fn minimap_zoom() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        assert(math.abs(m:getZoom() - 1.0) < 0.001)
        m:setZoom(2.5)
        assert(math.abs(m:getZoom() - 2.5) < 0.001)
    "#,
    )
    .exec()
    .expect("minimap_zoom failed");
}

#[test]
fn minimap_center() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        m:setCenter(5.0, 3.0)
        local cx, cy = m:getCenter()
        assert(math.abs(cx - 5.0) < 0.001)
        assert(math.abs(cy - 3.0) < 0.001)
    "#,
    )
    .exec()
    .expect("minimap_center failed");
}

// ── Viewport ──

#[test]
fn minimap_viewport_rect() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(100, 100)
        -- initially nil
        assert(m:getViewportRect() == nil)
        m:setViewportRect(10, 20, 30, 40)
        local vp = m:getViewportRect()
        assert(vp ~= nil)
        assert(vp.x == 10 and vp.y == 20 and vp.w == 30 and vp.h == 40)
        m:clearViewportRect()
        assert(m:getViewportRect() == nil)
    "#,
    )
    .exec()
    .expect("minimap_viewport_rect failed");
}

#[test]
fn minimap_viewport_visible() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        assert(m:isViewportVisible())
        m:setViewportVisible(false)
        assert(not m:isViewportVisible())
    "#,
    )
    .exec()
    .expect("minimap_viewport_visible failed");
}

#[test]
fn minimap_viewport_color() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        m:setViewportColor(0.5, 0.6, 0.7, 0.3)
        local r, g, b, a = m:getViewportColor()
        assert(math.abs(r - 0.5) < 0.001)
        assert(math.abs(g - 0.6) < 0.001)
        assert(math.abs(b - 0.7) < 0.001)
        assert(math.abs(a - 0.3) < 0.001)
    "#,
    )
    .exec()
    .expect("minimap_viewport_color failed");
}

// ── Pings ──

#[test]
fn minimap_pings() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        assert(m:getPingCount() == 0)
        m:addPing(5, 5, 2.0)
        assert(m:getPingCount() == 1)
        m:addPing(3, 3, 1.0, 0.0, 1.0, 0.0, 1.0)
        assert(m:getPingCount() == 2)
    "#,
    )
    .exec()
    .expect("minimap_pings failed");
}

#[test]
fn minimap_pings_expire() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        m:addPing(5, 5, 1.0)
        assert(m:getPingCount() == 1)
        m:update(0.5)
        assert(m:getPingCount() == 1)
        m:update(0.6) -- dt = 0.5 + 0.6 = 1.1 > 1.0, should expire
        assert(m:getPingCount() == 0)
    "#,
    )
    .exec()
    .expect("minimap_pings_expire failed");
}

// ── Markers ──

#[test]
fn minimap_markers() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        assert(m:getMarkerCount() == 0)
        local id = m:addMarker(3.0, 4.0, "Objective A")
        assert(m:getMarkerCount() == 1)
        assert(m:hasMarker(id))
        assert(m:getMarkerDescription(id) == "Objective A")
        local id2 = m:addMarker(7.0, 8.0)
        assert(m:getMarkerCount() == 2)
        assert(m:removeMarker(id))
        assert(m:getMarkerCount() == 1)
        assert(not m:hasMarker(id))
        assert(m:getMarkerDescription(id) == nil)
    "#,
    )
    .exec()
    .expect("minimap_markers failed");
}

#[test]
fn minimap_marker_with_color() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        local id = m:addMarker(1.0, 2.0, "Quest", 0.0, 1.0, 0.0, 0.5)
        assert(m:hasMarker(id))
        assert(m:getMarkerDescription(id) == "Quest")
    "#,
    )
    .exec()
    .expect("minimap_marker_with_color failed");
}

// ── Anti-alias ──

#[test]
fn minimap_anti_alias() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        assert(not m:isAntiAlias())
        m:setAntiAlias(true)
        assert(m:isAntiAlias())
    "#,
    )
    .exec()
    .expect("minimap_anti_alias failed");
}

// ── Coordinate conversion ──

#[test]
fn minimap_coord_conversion() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10, 100, 100)
        -- grid (0,0) at minimap position (0,0) should map to screen (0,0)
        local sx, sy = m:gridToScreen(0, 0, 0, 0)
        assert(type(sx) == "number")
        assert(type(sy) == "number")
        -- round-trip with identity-like transform
        local gx, gy = m:screenToGrid(sx, sy, 0, 0)
        assert(math.abs(gx - 0) < 0.01)
        assert(math.abs(gy - 0) < 0.01)
    "#,
    )
    .exec()
    .expect("minimap_coord_conversion failed");
}

// ── Update ──

#[test]
fn minimap_update() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        -- just ensure it doesn't crash
        m:update(0.016)
        m:update(0.033)
    "#,
    )
    .exec()
    .expect("minimap_update failed");
}

// ── Combined workflow ──

#[test]
fn minimap_full_workflow() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(32, 32, 200, 200)

        -- Set terrain
        for x = 1, 32 do
            for y = 1, 32 do
                m:setTerrain(x, y, (x + y) % 4)
            end
        end
        m:setTerrainColor(0, 0.0, 0.5, 0.0)
        m:setTerrainColor(1, 0.3, 0.3, 0.3)
        m:setTerrainColor(2, 0.0, 0.0, 0.8)
        m:setTerrainColor(3, 0.8, 0.8, 0.0)

        -- Enable fog
        m:setFogEnabled(true)
        m:setFogColor(0.0, 0.0, 0.0, 0.7)
        for x = 1, 10 do
            for y = 1, 10 do
                m:setFogLevel(x, y, 2)
            end
        end

        -- Add object types
        local unitType = m:addObjectType("unit", 0.0, 1.0, 0.0)
        local buildingType = m:addObjectType("building", 0.0, 0.0, 1.0)

        -- Place objects
        m:setObject(1, 5.0, 5.0, unitType, 0)
        m:setObject(2, 10.0, 10.0, buildingType, 1)

        -- Set owner colors
        m:setOwnerColor(0, 0.0, 1.0, 0.0)
        m:setOwnerColor(1, 1.0, 0.0, 0.0)

        -- Configure viewport
        m:setViewportRect(0, 0, 16, 12)
        m:setViewportColor(1.0, 1.0, 1.0, 0.8)

        -- Add a ping and marker
        m:addPing(15, 15, 3.0, 1.0, 0.0, 0.0)
        local markerId = m:addMarker(20.0, 20.0, "Base", 0.0, 0.0, 1.0)

        -- Set zoom
        m:setZoom(1.5)
        m:setCenter(16, 16)

        -- Verify state
        assert(m:getObjectCount() == 2)
        assert(m:getPingCount() == 1)
        assert(m:getMarkerCount() == 1)
        assert(m:isFogEnabled())
        assert(math.abs(m:getZoom() - 1.5) < 0.001)

        -- Update
        m:update(0.016)

        -- Verify ping still alive
        assert(m:getPingCount() == 1)
    "#,
    )
    .exec()
    .expect("minimap_full_workflow failed");
}

// ── setTerrainData ──

#[test]
fn minimap_terrain_data_bulk() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(3, 2)
        -- 3x2 grid, row-major: row 1 = types 1,2,3; row 2 = types 4,5,6
        m:setTerrainData({1, 2, 3, 4, 5, 6})
        assert(m:getTerrain(1, 1) == 1)
        assert(m:getTerrain(2, 1) == 2)
        assert(m:getTerrain(3, 1) == 3)
        assert(m:getTerrain(1, 2) == 4)
        assert(m:getTerrain(2, 2) == 5)
        assert(m:getTerrain(3, 2) == 6)
    "#,
    )
    .exec()
    .expect("minimap_terrain_data_bulk failed");
}

// ── Tile descriptions ──

#[test]
fn minimap_tile_descriptions() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(5, 5)
        assert(m:getTileDescription(0) == nil)
        m:setTileDescription(0, "Water")
        m:setTileDescription(1, "Grass")
        assert(m:getTileDescription(0) == "Water")
        assert(m:getTileDescription(1) == "Grass")
        assert(m:getTileDescription(2) == nil)
        -- overwrite
        m:setTileDescription(0, "Deep water")
        assert(m:getTileDescription(0) == "Deep water")
    "#,
    )
    .exec()
    .expect("minimap_tile_descriptions failed");
}

// ── getHoverInfo ──

#[test]
fn minimap_hover_info() {
    let lua = make_vm();
    lua.load(
        r#"
        -- 4x4 grid, 100x100 display, centered at (2,2)
        local m = luna.minimap.newMinimap(4, 4, 100, 100)
        m:setTerrainData({1,1,1,1, 1,2,2,1, 1,2,2,1, 1,1,1,1})
        m:setTileDescription(1, "Plains")
        m:setTileDescription(2, "Forest")

        -- screen coords outside minimap should return nil
        assert(m:getHoverInfo(-10, -10, 0, 0) == nil)
        assert(m:getHoverInfo(110, 110, 0, 0) == nil)

        -- top-left cell (0,0 in grid) = terrain 1 → "Plains"
        local info = m:getHoverInfo(1, 1, 0, 0)
        assert(info == "Plains", "expected Plains got " .. tostring(info))

        -- terrain type with no description → nil
        local m2 = luna.minimap.newMinimap(4, 4, 100, 100)
        m2:setTerrain(1, 1, 99)
        assert(m2:getHoverInfo(1, 1, 0, 0) == nil)
    "#,
    )
    .exec()
    .expect("minimap_hover_info failed");
}

// ── setClickable / isClickable ──

#[test]
fn minimap_clickable() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        -- default is true
        assert(m:isClickable())
        m:setClickable(false)
        assert(not m:isClickable())
        m:setClickable(true)
        assert(m:isClickable())
    "#,
    )
    .exec()
    .expect("minimap_clickable failed");
}

// ── getCenterX / getCenterY ──

#[test]
fn minimap_center_individual_getters() {
    let lua = make_vm();
    lua.load(
        r#"
        local m = luna.minimap.newMinimap(10, 10)
        m:setCenter(3.5, 7.25)
        assert(math.abs(m:getCenterX() - 3.5) < 0.001)
        assert(math.abs(m:getCenterY() - 7.25) < 0.001)
    "#,
    )
    .exec()
    .expect("minimap_center_individual_getters failed");
}
