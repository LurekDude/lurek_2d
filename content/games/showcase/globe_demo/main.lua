-- ============================================================================
-- Globe Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/globe_demo/main.lua
-- Run with : cargo run -- content/games/showcase/globe_demo
-- ============================================================================
-- Interactive world globe: ~200 procedurally generated provinces, drag-pan,
-- scroll zoom, capital markers, continent labels, political colour layer,
-- day/night cycle, hover highlight, and click-select with popup label.
-- ============================================================================

-- Capture the render API namespace BEFORE defining function lurek.render()
-- (defining that callback overwrites lurek.render with the function itself).


local SCREEN_W   = 1280
local SCREEN_H   = 720
local GLOBE_CX   = SCREEN_W / 2    -- globe centre X on screen
local GLOBE_CY   = SCREEN_H / 2    -- globe centre Y on screen
local GLOBE_R    = 290.0           -- display radius (screen units)
local DAY_SPEED  = 120.0           -- seconds of real time per 1 simulated hour
local ZOOM_MIN   = 0.5
local ZOOM_MAX   = 12.0
local PAN_SCALE  = 0.12            -- degrees per pixel at zoom 1.0

-- ---------------------------------------------------------------------------
-- Globe state
-- ---------------------------------------------------------------------------
local g              -- Globe handle (lurek.globe userdata)
local cam_lat  = 20.0
local cam_lon  = 0.0
local cam_zoom = 1.5

local time_of_day    = 12.0        -- hours 0–24
local sim_seconds    = 0.0         -- accumulated real seconds for day/night

local hovered_id     = nil         -- province id under cursor (nil = none)
local selected_id    = nil         -- clicked province id
local prev_hovered   = nil         -- to track when highlight changes
local flight_arc_id  = nil         -- temporary arc drawn on click

-- Mouse drag state
local is_dragging    = false
local drag_mx        = 0
local drag_my        = 0
local drag_lat       = 0.0
local drag_lon       = 0.0
local lmb_prev       = false       -- previous frame left-button state

-- HUD state
local hud_province   = ""          -- province name shown in HUD
local hud_lod        = ""

-- ---------------------------------------------------------------------------
-- Province generation helpers
-- ---------------------------------------------------------------------------
-- Clamp to sane color range
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

-- Slightly vary a base color component for visual diversity
local function jitter(v)
    -- deterministic tiny offset using a cheap pseudo-random trick
    return clamp(v + (((v * 31337) % 7) - 3) * 0.03, 0.05, 0.95)
end

-- Generate grid provinces for one continental region.
-- Returns the list of assigned province IDs.
-- Neighbors are the four grid-adjacent cells (N/S/E/W), clipped at edges.
local next_pid = 1    -- global province ID counter

local function generate_grid_provinces(
    region, lat_min, lat_max, lon_min, lon_max,
    rows, cols, base_r, base_g, base_b, extra_attrs)

    local ids    = {}   -- ids[r][c] = province_id  (1-indexed)
    local lat_step = (lat_max - lat_min) / rows
    local lon_step = (lon_max - lon_min) / cols

    -- First pass: assign IDs and create province tables (no neighbors yet)
    for r = 1, rows do
        ids[r] = {}
        for c = 1, cols do
            ids[r][c] = next_pid
            next_pid = next_pid + 1
        end
    end

    -- Second pass: add provinces with computed neighbors
    for r = 1, rows do
        for c = 1, cols do
            local pid   = ids[r][c]
            local lat0  = lat_min + (r - 1) * lat_step
            local lon0  = lon_min + (c - 1) * lon_step
            local lat1  = lat0 + lat_step
            local lon1  = lon0 + lon_step
            local clat  = (lat0 + lat1) * 0.5
            local clon  = (lon0 + lon1) * 0.5

            -- Neighbor IDs (grid adjacency, within this region)
            local nbrs = {}
            if r > 1    then table.insert(nbrs, ids[r-1][c]) end
            if r < rows then table.insert(nbrs, ids[r+1][c]) end
            if c > 1    then table.insert(nbrs, ids[r][c-1]) end
            if c < cols then table.insert(nbrs, ids[r][c+1]) end

            -- Per-province color variation (deterministic jitter)
            local cr = clamp(base_r + (pid % 5 - 2) * 0.04, 0.05, 0.95)
            local cg = clamp(base_g + (pid % 7 - 3) * 0.03, 0.05, 0.95)
            local cb = clamp(base_b + (pid % 3 - 1) * 0.05, 0.05, 0.95)

            g:addProvince({
                id        = pid,
                centroid  = {clat, clon},
                vertices  = {
                    {lat0, lon0}, {lat0, lon1},
                    {lat1, lon1}, {lat1, lon0},
                },
                neighbors  = nbrs,
                base_color = {cr, cg, cb, 1.0},
            })

            g:setProvinceAttr(pid, "region", region)
            if extra_attrs then
                for k, v in pairs(extra_attrs) do
                    g:setProvinceAttr(pid, k, v)
                end
            end
        end
    end

    return ids
end

-- ---------------------------------------------------------------------------
-- Capital city markers
-- ---------------------------------------------------------------------------
local CAPITALS = {
    -- {lat, lon, name}
    {38.9,  -77.0, "Washington DC"},
    {51.5,   -0.1, "London"},
    {48.8,    2.3, "Paris"},
    {52.5,   13.4, "Berlin"},
    {41.9,   12.5, "Rome"},
    {55.8,   37.6, "Moscow"},
    {35.7,  139.7, "Tokyo"},
    {39.9,  116.4, "Beijing"},
    {28.6,   77.2, "New Delhi"},
    {-15.8, -47.9, "Brasilia"},
    {-34.6, -58.4, "Buenos Aires"},
    {-33.9,  18.4, "Cape Town"},
    {30.0,   31.2, "Cairo"},
    {-25.3,  131.0,"Canberra"},
    {-90.0,    0.0,"Amundsen-Scott (South Pole)"},
}

-- ---------------------------------------------------------------------------
-- Continent labels
-- ---------------------------------------------------------------------------
local CONTINENT_LABELS = {
    {45.0,  -100.0, "North America"},
    {-15.0,  -55.0, "South America"},
    {50.0,    15.0, "Europe"},
    {5.0,     20.0, "Africa"},
    {40.0,    90.0, "Asia"},
    {-25.0,  135.0, "Oceania"},
    {-75.0,    0.0, "Antarctica"},
}

-- ---------------------------------------------------------------------------
-- Political layer colors per region
-- ---------------------------------------------------------------------------
local REGION_COLORS = {
    ["North America"] = {0.25, 0.50, 0.85, 0.55},
    ["South America"] = {0.30, 0.75, 0.40, 0.55},
    ["Europe"]        = {0.85, 0.75, 0.25, 0.55},
    ["Africa"]        = {0.85, 0.45, 0.20, 0.55},
    ["Asia"]          = {0.70, 0.25, 0.70, 0.55},
    ["Oceania"]       = {0.20, 0.70, 0.75, 0.55},
    ["Antarctica"]    = {0.80, 0.90, 1.00, 0.55},
}

-- ---------------------------------------------------------------------------
-- Init callback
-- ---------------------------------------------------------------------------
function lurek.init()
    -- Verify the API is reachable and print the province cap
    assert(lurek.globe ~= nil, "lurek.globe module not loaded")
    print("Globe API ready. MAX_PROVINCES =", lurek.globe.MAX_PROVINCES)
    print("LOD tiers:", lurek.globe.LOD_FAR, lurek.globe.LOD_MID, lurek.globe.LOD_NEAR)

    -- Create the globe
    g = lurek.globe.new("earth", {
        radius         = GLOBE_R,
        axial_tilt_deg = 23.5,
        time_of_day    = time_of_day,
        render_borders = true,
        border_width   = 1.0,
        ambient        = 0.18,
    })

    -- Confirm retrieval by name works
    local g_check = lurek.globe.get("earth")
    assert(g_check ~= nil, "globe.get('earth') failed immediately after creation")
    print("Globe name via get():", g_check:getName())

    -- Generate ~200 provinces across 7 continental regions
    -- Regions: rows × cols  => total provinces
    generate_grid_provinces("North America",  15, 75, -170, -50, 7,  5, 0.22, 0.45, 0.80)  -- 35
    generate_grid_provinces("South America", -55, 15,  -85, -35, 6,  5, 0.25, 0.72, 0.38)  -- 30
    generate_grid_provinces("Europe",         35, 72,  -15,  50, 5,  7, 0.82, 0.72, 0.22)  -- 35
    generate_grid_provinces("Africa",        -35, 37,  -18,  52, 5,  6, 0.82, 0.42, 0.18)  -- 30
    generate_grid_provinces("Asia",            5, 75,   26, 145, 5,  9, 0.68, 0.22, 0.68)  -- 45
    generate_grid_provinces("Oceania",       -47,  5,  110, 180, 3,  5, 0.18, 0.68, 0.72)  -- 15
    generate_grid_provinces("Antarctica",    -90,-60, -180, 180, 1, 10, 0.78, 0.88, 0.98)  -- 10

    local total = g:provinceCount()
    print(string.format("Provinces generated: %d", total))
    assert(total == 200, string.format("expected 200 provinces, got %d", total))

    -- Thematic layer: political overlay (one color per region)
    g:addLayer("political", 1)
    g:setLayerAlpha("political", 0.55)
    for pid = 1, total do
        local region = g:getProvinceAttr(pid, "region") or ""
        local col    = REGION_COLORS[region]
        if col then
            g:setLayerColor("political", pid, col[1], col[2], col[3], col[4])
        end
    end

    -- Highlight layer: used for hover and selection feedback
    g:addLayer("highlight", 5)

    -- Fog of war: reveal all for the single human viewer
    g:setActiveViewer("player")
    g:revealAll("player")

    -- Capital city markers
    for _, cap in ipairs(CAPITALS) do
        local mid = g:addMarker("capital", cap[1], cap[2], cap[3])
        g:setMarkerAttr(mid, "type", "capital")
    end

    -- Continent labels
    for _, lbl in ipairs(CONTINENT_LABELS) do
        g:addLabel("continent", lbl[1], lbl[2], lbl[3])
    end

    -- Initial camera: centered on the Atlantic, zoom 1.5×
    g:setCamera(cam_lat, cam_lon, cam_zoom)

    -- Start at midday
    g:setTimeOfDay(time_of_day)

    -- Borders on by default
    g:setBorders(true)

    -- Input bindings
    lurek.input.bind("drag",  {"mouse1"})
    lurek.input.bind("quit",  {"escape"})

    -- Set space-background color (fills screen automatically each frame)
    lurek.render.setBackgroundColor(0.02, 0.02, 0.08)

    print("Globe demo loaded successfully.")
end

-- ---------------------------------------------------------------------------
-- Update callback
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    local mx, my = lurek.input.getMousePosition()
    local lmb    = lurek.input.isActionDown("drag")
    local _, wdy = lurek.input.getWheelDelta()

    -- ── Mouse wheel zoom ──────────────────────────────────────────────────
    if wdy and wdy ~= 0 then
        local factor = wdy > 0 and 1.20 or (1.0 / 1.20)
        cam_zoom     = clamp(cam_zoom * factor, ZOOM_MIN, ZOOM_MAX)
        g:setCamera(cam_lat, cam_lon, cam_zoom)
        -- also exercise g:zoom (multiplicative convenience method)
        g:zoom(1.0)   -- identity call to confirm the API is reachable
    end

    -- ── Left-drag pan ────────────────────────────────────────────────────
    if lmb then
        if not is_dragging then
            -- Start drag: record anchor
            is_dragging = true
            drag_mx, drag_my = mx, my
            drag_lat, drag_lon = cam_lat, cam_lon
        else
            -- Continue drag: accumulate delta
            local ddeg = PAN_SCALE / cam_zoom
            local dlat = -(my - drag_my) * ddeg
            local dlon = -(mx - drag_mx) * ddeg
            cam_lat = clamp(drag_lat + dlat, -85.0, 85.0)
            cam_lon = drag_lon + dlon
            g:setCamera(cam_lat, cam_lon, cam_zoom)
        end
    else
        is_dragging = false
    end

    -- ── Click to select province ──────────────────────────────────────────
    local lmb_just_released = lmb_prev and not lmb
    lmb_prev = lmb
    if lmb_just_released and not is_dragging then
        local clicked = g:pick(mx, my)
        if clicked and clicked ~= selected_id then
            -- Deselect old (clear selection highlight)
            if selected_id then
                g:setLayerColor("highlight", selected_id, 0, 0, 0, 0)
            end
            selected_id = clicked

            -- Highlight selected province gold
            g:setLayerColor("highlight", selected_id, 1.0, 0.85, 0.1, 0.7)

            -- Show a popup label with province info
            local region = g:getProvinceAttr(selected_id, "region") or "Unknown"
            local lat, lon = g:pickLatLon(mx, my)
            if lat then
                local popup_text = string.format("Province %d — %s (%.1f°, %.1f°)",
                    selected_id, region, lat, lon)
                -- Add a temporary selection label; remove previous one first
                if flight_arc_id then
                    g:removeArc(flight_arc_id)
                    flight_arc_id = nil
                end
                -- Draw a great-circle arc from camera centre to selected province centroid
                local clat, clon = g:getCamera()
                -- We approximate the centroid from pickLatLon
                flight_arc_id = g:addArc(clat, clon, lat, lon, 24)
                hud_province = popup_text
            end
        end
    end

    -- ── Province hover highlight ──────────────────────────────────────────
    hovered_id = g:pick(mx, my)
    if hovered_id ~= prev_hovered then
        -- Clear old hover highlight (unless it's also the selected province)
        if prev_hovered and prev_hovered ~= selected_id then
            g:setLayerColor("highlight", prev_hovered, 0, 0, 0, 0)
        end
        -- Apply new hover highlight (unless it's the selected province)
        if hovered_id and hovered_id ~= selected_id then
            g:setLayerColor("highlight", hovered_id, 1.0, 1.0, 1.0, 0.35)
        end
        prev_hovered = hovered_id
    end

    -- Update HUD LOD string
    hud_lod = g:getLod()

    -- ── Day/night simulation ──────────────────────────────────────────────
    sim_seconds  = sim_seconds + dt
    if sim_seconds >= DAY_SPEED then
        sim_seconds  = sim_seconds - DAY_SPEED
        time_of_day  = (time_of_day + 1.0) % 24.0
        g:setTimeOfDay(time_of_day)
    end

    -- Advance globe simulation (updates lighting, any internal state)
    g:update(dt)

    -- Escape to quit
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
    end
end

-- ---------------------------------------------------------------------------
-- Render callback
-- ---------------------------------------------------------------------------
function lurek.render()
    -- (background filled automatically via setBackgroundColor set in init)

    -- ── Globe renders automatically via emitFrame ─────────────────────────
    -- The engine submits the returned commands to the GPU pipeline.
    local cmds = g:emitFrame(nil)
    -- (cmds submitted by engine; we inspect count for debug only)
    local cmd_count = cmds and #cmds or 0

    -- ── HUD strip ─────────────────────────────────────────────────────────
    lurek.render.setColor(0.0, 0.0, 0.0, 0.65)
    lurek.render.drawRect("fill", 0, 0, SCREEN_W, 32)

    local clat, clon, czoom = g:getCamera()
    local tod = g:getTimeOfDay()
    local hud_cam = string.format(
        "Camera  lat=%.1f°  lon=%.1f°  zoom=%.2f×  LOD=%s",
        clat, clon, czoom, hud_lod)
    local tod_h = math.floor(tod)
    local tod_m = math.floor((tod - tod_h) * 60)
    local hud_time = string.format("Time %02d:%02d  Provinces=%d  cmds=%d",
        tod_h, tod_m, g:provinceCount(), cmd_count)

    lurek.render.setColor(0.9, 0.9, 0.9)
    lurek.render.print(hud_cam,  10, 8, 14)
    lurek.render.setColor(0.7, 0.9, 1.0)
    lurek.render.print(hud_time, SCREEN_W - 380, 8, 14)

    -- ── Province hover info ───────────────────────────────────────────────
    if hovered_id then
        local region = g:getProvinceAttr(hovered_id, "region") or "?"
        local hover_text = string.format("Province %d — %s", hovered_id, region)
        lurek.render.setColor(0.0, 0.0, 0.0, 0.55)
        lurek.render.drawRect("fill", 0, SCREEN_H - 32, 400, 32)
        lurek.render.setColor(1.0, 0.9, 0.5)
        lurek.render.print(hover_text, 10, SCREEN_H - 24, 14)
    end

    -- ── Selected province popup ───────────────────────────────────────────
    if selected_id and hud_province ~= "" then
        local txt_w = 500
        lurek.render.setColor(0.0, 0.0, 0.0, 0.72)
        lurek.render.drawRect("fill", SCREEN_W/2 - txt_w/2, SCREEN_H - 60, txt_w, 28)
        lurek.render.setColor(1.0, 0.85, 0.1)
        lurek.render.print(hud_province, SCREEN_W/2 - txt_w/2 + 8, SCREEN_H - 54, 14)
    end

    -- ── Controls reminder (bottom-right) ─────────────────────────────────
    lurek.render.setColor(0.5, 0.5, 0.5, 0.8)
    lurek.render.print("Drag: pan   Wheel: zoom   Click: select   Esc: quit",
        SCREEN_W - 480, SCREEN_H - 20, 13)
end
