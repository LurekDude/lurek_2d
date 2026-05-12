
local R = lurek.render

local MAP_W = 2000
local MAP_H = 900
local PIXEL_SIZE = 8
local SANITIZED_MAP_PATH = "save/eu2/map_sanitized.png"

local reg = nil

local cam = { x = 0, y = 0, zoom = 1.0 }
local drag = { active = false, sx = 0, sy = 0, cx = 0, cy = 0 }
local hovered_gid = nil
local selected_gid = nil
local map_mode = "terrain"
local draw_labels = true
local ui_font = nil

local function reg_call(method, ...)
    if not reg then
        return nil
    end
    local fn = reg[method]
    if type(fn) ~= "function" then
        return nil
    end
    local ok, a, b, c, d, e = pcall(fn, reg, ...)
    if not ok then
        return nil
    end
    return a, b, c, d, e
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function fit_camera()
    local ww, hh = lurek.window.getDimensions()
    if reg and reg.fitCamera then
        local x, y, z = reg:fitCamera(ww, hh, PIXEL_SIZE)
        cam.x, cam.y, cam.zoom = x, y, z
        return
    end

    local sw = MAP_W * PIXEL_SIZE
    local sh = MAP_H * PIXEL_SIZE
    cam.zoom = math.min(ww / sw, hh / sh)
    cam.x = (ww - sw * cam.zoom) * 0.5
    cam.y = (hh - sh * cam.zoom) * 0.5
end

local function hover_info(gid)
    if not gid then
        return nil
    end
    local snap = reg_call("getProvince", gid)
    if type(snap) ~= "table" then
        return nil
    end
    local attrs = snap.attrs or {}
    local gameid = attrs.game_id
    local terrain = attrs.terrain or "unknown"
    local name = attrs.name or ("Province " .. tostring(gameid or gid))
    return {
        gameid = gameid,
        terrain = terrain,
        name = tostring(name):gsub("_", " "),
    }
end

function lurek.init()
    local ok_font, f = pcall(R.newFont, "fonts/OpenSans.ttf", 18)
    if ok_font and f then
        ui_font = f
        R.setFont(ui_font)
    end

    lurek.province.sanitizeMarkedPng("map.png", SANITIZED_MAP_PATH)
    reg = lurek.province.newFromPng("eu2", SANITIZED_MAP_PATH)
    lurek.province.setActive("eu2")
    reg:importMetadataFromFiles({
        color_map_png = SANITIZED_MAP_PATH,
        marker_png = "map.png",
        color_csv = "prov_cols.csv",
        province_toml = "province.toml",
        water_terrain_tokens = { "sea", "river" },
        water_terrain_type = 0,
        land_terrain_type = 1,
        set_political_colors = true,
        set_label_text = true,
        set_capitals = true,
        set_label_lines = true,
    })
    fit_camera()
end

function lurek.update(dt)
    local mx, my = lurek.input.mouse.getPosition()
    if drag.active then
        cam.x = drag.cx + (mx - drag.sx)
        cam.y = drag.cy + (my - drag.sy)
    end

    if reg and reg.screenToProvince then
        hovered_gid = reg:screenToProvince(mx, my, cam.x, cam.y, cam.zoom, PIXEL_SIZE)
    else
        local s = cam.zoom * PIXEL_SIZE
        local px = math.floor((mx - cam.x) / s)
        local py = math.floor((my - cam.y) / s)

        if px >= 0 and py >= 0 and px < MAP_W and py < MAP_H then
            local gid = reg_call("getAt", px, py) or 0
            hovered_gid = gid ~= 0 and gid or nil
        else
            hovered_gid = nil
        end
    end
end

function lurek.process(dt)
    lurek.update(dt)
end

function lurek.mousepressed(x, y, button)
    if button == 1 then
        drag.active = true
        drag.sx, drag.sy = x, y
        drag.cx, drag.cy = cam.x, cam.y
    end
end

function lurek.mousereleased(x, y, button)
    if button ~= 1 then return end
    local dx = x - drag.sx
    local dy = y - drag.sy
    drag.active = false
    if dx * dx + dy * dy <= 16 then
        selected_gid = hovered_gid
    end
end

function lurek.wheelmoved(dx, dy)
    if dy == 0 then return end
    local mx, my = lurek.input.mouse.getPosition()
    local old = cam.zoom
    cam.zoom = clamp(cam.zoom * (dy > 0 and 1.12 or (1.0 / 1.12)), 0.02, 12.0)
    if lurek.province and lurek.province.zoomCameraAt then
        cam.x, cam.y = lurek.province.zoomCameraAt(mx, my, cam.x, cam.y, old, cam.zoom)
    else
        local s = cam.zoom / old
        cam.x = mx - (mx - cam.x) * s
        cam.y = my - (my - cam.y) * s
    end
end

function lurek.keypressed(key)
    if key == "escape" then
        lurek.event.quit()
    elseif key == "1" then
        map_mode = "political"
    elseif key == "2" then
        map_mode = "terrain"
    elseif key == "3" then
        map_mode = "visibility"
    elseif key == "l" then
        draw_labels = not draw_labels
    end
end

local function draw_hud()
    if ui_font then
        R.setFont(ui_font)
    end

    local fps = lurek.timer.getFPS()
    local stats = R.getStats()

    R.setColor(0, 0, 0, 0.70)
    R.rectangle("fill", 8, 8, 760, 76)
    R.setColor(1, 1, 1, 1)
    R.print("EU2 province renderer: Rust GPU path (lurek.province)", 14, 14)
    R.print("Map mode [1/2/3]: " .. map_mode .. "   Labels [L]: " .. tostring(draw_labels), 14, 34)
    R.print(string.format("FPS: %d  Draw calls: %d  Batched: %d", fps, stats.gpu_draw_calls or 0, stats.batched_draws or 0), 14, 54)

    if hovered_gid then
        local info = hover_info(hovered_gid) or {}
        local gameid = info.gameid
        local name = info.name or ("Province " .. tostring(gameid or hovered_gid))
        local terrain = info.terrain or "unknown"
        local neighbors = reg_call("getNeighbors", hovered_gid) or {}

        local ww, hh = lurek.window.getDimensions()
        local tx, ty = ww - 360, hh - 98
        R.setColor(0, 0, 0, 0.78)
        R.rectangle("fill", tx, ty, 352, 90)
        R.setColor(1, 0.86, 0.35, 1)
        R.print(name, tx + 8, ty + 8)
        R.setColor(0.8, 0.8, 0.8, 1)
        R.print("Grid: " .. tostring(hovered_gid) .. "  ID: " .. tostring(gameid or "-") .. "  terrain: " .. terrain, tx + 8, ty + 30)
        R.print("Neighbors: " .. tostring(#neighbors) .. "  Selected: " .. tostring(selected_gid or "-"), tx + 8, ty + 52)
    end
end

local function render_frame()
    local ww, hh = lurek.window.getDimensions()

    reg_call("render", {
        x = cam.x,
        y = cam.y,
        zoom = cam.zoom,
        pixel_size = PIXEL_SIZE,
        screen_w = ww,
        screen_h = hh,
        map_mode = map_mode,
        draw_fills = true,
        draw_borders = true,
        draw_labels = draw_labels,
        draw_capitals = true,
        border_width = 1.0,
        hovered_id = hovered_gid,
        selected_id = selected_gid,
    })

    draw_hud()
end

function lurek.draw()
    render_frame()
end

function lurek.render()
    render_frame()
end
