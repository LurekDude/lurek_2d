-- ============================================================================
-- Docs Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/docs_demo/main.lua
-- Run with : cargo run -- content/games/showcase/docs_demo
-- ============================================================================
-- Interactive API documentation browser: navigate 12 lurek.* namespaces,
-- view function signatures with syntax highlighting, search, bookmark,
-- and browse history — all rendered as an in-engine reference tool.
-- Controls: Up/Down navigate, Enter select, / search, B bookmark,
--           H history, Tab bookmarks list, Left/Right paginate, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local SIDEBAR_W   = 200
local PANEL_X     = SIDEBAR_W + 10
local PANEL_W     = SCREEN_W - SIDEBAR_W - 20
local ITEM_H      = 24
local FUNCS_PER_PAGE = 6
local HEADER_H    = 50
local FOOTER_H    = 30

local STATE = { TITLE = 1, BROWSING = 2, SEARCH = 3, BOOKMARKS = 4, HISTORY = 5 }
local current_state = STATE.TITLE

-- ---------------------------------------------------------------------------
-- Colors
-- ---------------------------------------------------------------------------
local COL = {
    bg           = { 0.08, 0.06, 0.10 },
    sidebar_bg   = { 0.10, 0.08, 0.14 },
    sidebar_sel  = { 0.20, 0.14, 0.30 },
    sidebar_text = { 0.70, 0.70, 0.80 },
    sidebar_hi   = { 0.90, 0.85, 1.00 },
    panel_bg     = { 0.12, 0.10, 0.16 },
    func_name    = { 1.00, 0.90, 0.30 },   -- yellow
    param        = { 0.40, 0.90, 0.95 },   -- cyan
    ret_type     = { 0.40, 0.90, 0.50 },   -- green
    desc         = { 0.65, 0.65, 0.75 },
    header       = { 0.50, 0.70, 1.00 },
    search_bg    = { 0.15, 0.12, 0.20 },
    bookmark     = { 1.00, 0.75, 0.20 },
    history      = { 0.60, 0.80, 1.00 },
    bar_bg       = { 0.20, 0.18, 0.25 },
    bar_fill     = { 0.30, 0.80, 0.50 },
    bar_partial  = { 0.90, 0.70, 0.20 },
    muted        = { 0.45, 0.45, 0.55 },
    white        = { 1.00, 1.00, 1.00 },
}

-- ---------------------------------------------------------------------------
-- API Data (12 namespaces, 4–8 functions each = 50 total, 42 documented)
-- ---------------------------------------------------------------------------
local namespaces = {
    { name = "render", funcs = {
        { name = "setColor",           params = "r, g, b, a",   ret = "nil",     desc = "Set the active draw color for subsequent primitives" },
        { name = "rectangle",          params = "mode, x, y, w, h", ret = "nil", desc = "Draw a filled or outlined rectangle" },
        { name = "circle",             params = "mode, x, y, r", ret = "nil",    desc = "Draw a filled or outlined circle" },
        { name = "line",               params = "x1, y1, x2, y2", ret = "nil",  desc = "Draw a line segment between two points" },
        { name = "print",              params = "text, x, y",   ret = "nil",     desc = "Render a text string at the given position" },
        { name = "setFont",            params = "font",          ret = "nil",    desc = "Set the active font for text rendering" },
    }},
    { name = "input", funcs = {
        { name = "bind",               params = "action, keys",  ret = "nil",    desc = "Bind an action name to one or more key codes" },
        { name = "wasActionPressed",   params = "action",        ret = "bool",   desc = "True if the action was pressed this frame" },
        { name = "isActionDown",       params = "action",        ret = "bool",   desc = "True while the action key is held down" },
        { name = "getMousePosition",   params = "",              ret = "x, y",   desc = "Return the current mouse cursor position" },
        { name = "isMousePressed",     params = "button",        ret = "bool",   desc = "True if the mouse button was clicked this frame" },
    }},
    { name = "physics", funcs = {
        { name = "newWorld",           params = "gx, gy",        ret = "World",  desc = "Create a new physics simulation world" },
        { name = "newBody",            params = "world, x, y, type", ret = "Body", desc = "Add a rigid body to the physics world" },
        { name = "newRectangleShape",  params = "w, h",          ret = "Shape",  desc = "Create a rectangle collision shape" },
        { name = "newCircleShape",     params = "radius",        ret = "Shape",  desc = "Create a circle collision shape" },
        { name = "newFixture",         params = "body, shape, density", ret = "Fixture", desc = "" },
        { name = "setGravity",         params = "gx, gy",        ret = "nil",    desc = "Change world gravity vector at runtime" },
    }},
    { name = "audio", funcs = {
        { name = "newSource",          params = "path, type",    ret = "Source", desc = "Load an audio file as a playable source" },
        { name = "play",               params = "source",        ret = "nil",    desc = "Start playing an audio source" },
        { name = "stop",               params = "source",        ret = "nil",    desc = "Stop a currently playing source" },
        { name = "setVolume",          params = "source, vol",   ret = "nil",    desc = "Set playback volume (0.0 to 1.0)" },
    }},
    { name = "window", funcs = {
        { name = "setTitle",           params = "title",         ret = "nil",    desc = "Set the window title bar text" },
        { name = "getWidth",           params = "",              ret = "number", desc = "Return the window width in pixels" },
        { name = "getHeight",          params = "",              ret = "number", desc = "Return the window height in pixels" },
        { name = "setFullscreen",      params = "enabled",       ret = "nil",    desc = "Toggle fullscreen mode on or off" },
    }},
    { name = "timer", funcs = {
        { name = "getDelta",           params = "",              ret = "number", desc = "Return the time elapsed since last frame" },
        { name = "getFPS",             params = "",              ret = "number", desc = "Return the current frames per second" },
        { name = "getTime",            params = "",              ret = "number", desc = "Return seconds since engine start" },
        { name = "after",              params = "delay, fn",     ret = "Timer",  desc = "" },
    }},
    { name = "camera", funcs = {
        { name = "attach",             params = "",              ret = "nil",    desc = "Begin camera-transformed drawing" },
        { name = "detach",             params = "",              ret = "nil",    desc = "End camera-transformed drawing" },
        { name = "setPosition",        params = "x, y",          ret = "nil",   desc = "Move camera to a world position" },
        { name = "setZoom",            params = "scale",         ret = "nil",    desc = "Set camera zoom level" },
    }},
    { name = "particles", funcs = {
        { name = "newSystem",          params = "config",        ret = "System", desc = "Create a new particle emitter system" },
        { name = "emit",               params = "count",         ret = "nil",    desc = "Burst-emit a number of particles" },
        { name = "update",             params = "dt",            ret = "nil",    desc = "Advance particle simulation by dt" },
        { name = "draw",               params = "",              ret = "nil",    desc = "Render all active particles" },
        { name = "moveTo",             params = "x, y",          ret = "nil",   desc = "" },
    }},
    { name = "tween", funcs = {
        { name = "to",                 params = "dur, fn, opts", ret = "Tween", desc = "Animate a value over duration with easing" },
        { name = "update",             params = "dt",            ret = "nil",    desc = "Advance all active tweens by delta time" },
        { name = "cancel",             params = "tween",         ret = "nil",    desc = "Cancel a running tween immediately" },
        { name = "sequence",           params = "tweens",        ret = "Tween", desc = "Chain multiple tweens in order" },
    }},
    { name = "tilemap", funcs = {
        { name = "load",               params = "path",          ret = "Map",   desc = "Load a tilemap from a file" },
        { name = "draw",               params = "map, ox, oy",   ret = "nil",   desc = "Render the tilemap with offset" },
        { name = "getTile",            params = "map, x, y",     ret = "Tile",  desc = "Query the tile at grid coordinates" },
        { name = "setTile",            params = "map, x, y, id", ret = "nil",   desc = "" },
        { name = "getLayerCount",      params = "map",           ret = "number", desc = "Return number of layers in the map" },
    }},
    { name = "scene", funcs = {
        { name = "push",               params = "name",          ret = "nil",    desc = "Push a new scene onto the stack" },
        { name = "pop",                params = "",              ret = "nil",     desc = "Pop the top scene from the stack" },
        { name = "switch",             params = "name",          ret = "nil",    desc = "Replace the current scene" },
        { name = "current",            params = "",              ret = "string", desc = "" },
    }},
    { name = "math", funcs = {
        { name = "lerp",               params = "a, b, t",       ret = "number", desc = "Linear interpolation between a and b" },
        { name = "clamp",              params = "v, lo, hi",     ret = "number", desc = "Constrain a value to a range" },
        { name = "distance",           params = "x1,y1,x2,y2",  ret = "number", desc = "Euclidean distance between two points" },
        { name = "random",             params = "min, max",      ret = "number", desc = "" },
        { name = "normalize",          params = "x, y",          ret = "x, y",  desc = "Return a unit vector from the input" },
        { name = "angle",              params = "x1,y1,x2,y2",  ret = "number", desc = "Angle in radians between two points" },
    }},
}

-- ---------------------------------------------------------------------------
-- Derived counts
-- ---------------------------------------------------------------------------
local total_funcs = 0
local documented_funcs = 0
for _, ns in ipairs(namespaces) do
    for _, fn in ipairs(ns.funcs) do
        total_funcs = total_funcs + 1
        if fn.desc ~= "" then documented_funcs = documented_funcs + 1 end
    end
end

-- ---------------------------------------------------------------------------
-- Navigation state
-- ---------------------------------------------------------------------------
local selected_ns    = 1
local selected_func  = 1
local current_page   = 1
local sidebar_scroll_y = 0
local panel_offset_x   = 0

-- ---------------------------------------------------------------------------
-- Search state
-- ---------------------------------------------------------------------------
local search_query   = ""
local search_results = {}

-- ---------------------------------------------------------------------------
-- Bookmarks & History
-- ---------------------------------------------------------------------------
local bookmarks = {}   -- { {ns_idx, func_idx}, ... }
local history   = {}   -- last 10 viewed: { {ns_idx, func_idx}, ... }
local MAX_HISTORY = 10

-- ---------------------------------------------------------------------------
-- Particles
-- ---------------------------------------------------------------------------
local ps_page   = nil
local ps_search = nil

-- ---------------------------------------------------------------------------
-- Tween / animation
-- ---------------------------------------------------------------------------
local title_alpha  = 0
local title_scale  = 0.5
local coverage_bar = 0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t) return a + (b - a) * t end

local function total_pages(ns_idx)
    local count = #namespaces[ns_idx].funcs
    return math.ceil(count / FUNCS_PER_PAGE)
end

local function page_funcs(ns_idx, page)
    local ns = namespaces[ns_idx]
    local start_i = (page - 1) * FUNCS_PER_PAGE + 1
    local end_i   = math.min(start_i + FUNCS_PER_PAGE - 1, #ns.funcs)
    local result = {}
    for i = start_i, end_i do
        result[#result + 1] = { idx = i, fn = ns.funcs[i] }
    end
    return result
end

local function add_history(ns_idx, func_idx)
    -- Remove duplicate if exists
    for i = #history, 1, -1 do
        if history[i][1] == ns_idx and history[i][2] == func_idx then
            table.remove(history, i)
        end
    end
    table.insert(history, 1, { ns_idx, func_idx })
    if #history > MAX_HISTORY then
        table.remove(history)
    end
end

local function is_bookmarked(ns_idx, func_idx)
    for _, bm in ipairs(bookmarks) do
        if bm[1] == ns_idx and bm[2] == func_idx then return true end
    end
    return false
end

local function toggle_bookmark(ns_idx, func_idx)
    for i, bm in ipairs(bookmarks) do
        if bm[1] == ns_idx and bm[2] == func_idx then
            table.remove(bookmarks, i)
            return
        end
    end
    bookmarks[#bookmarks + 1] = { ns_idx, func_idx }
end

local function do_search(query)
    search_results = {}
    if query == "" then return end
    local q = query:lower()
    for ni, ns in ipairs(namespaces) do
        for fi, fn in ipairs(ns.funcs) do
            if fn.name:lower():find(q, 1, true)
                or fn.params:lower():find(q, 1, true)
                or fn.desc:lower():find(q, 1, true)
                or ns.name:lower():find(q, 1, true) then
                search_results[#search_results + 1] = { ns_idx = ni, func_idx = fi }
            end
        end
    end
end

local function set_color(c, alpha)
    lurek.render.setColor(c[1], c[2], c[3], alpha or 1.0)
end

-- ---------------------------------------------------------------------------
-- Input bindings
-- ---------------------------------------------------------------------------
local function bind_inputs()
    lurek.input.bind("nav_up",    { "up" })
    lurek.input.bind("nav_down",  { "down" })
    lurek.input.bind("nav_left",  { "left" })
    lurek.input.bind("nav_right", { "right" })
    lurek.input.bind("select",    { "return" })
    lurek.input.bind("search",    { "/" })
    lurek.input.bind("bookmark",  { "b" })
    lurek.input.bind("history",   { "h" })
    lurek.input.bind("quit",      { "escape" })
end

-- ── Initialization ─────────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Docs Demo — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.06, 0.10)
    bind_inputs()

    -- Particle: page turn sparkle
    ps_page = lurek.particle.newSystem({
        maxParticles = 40, emissionRate = 0,
        lifetimeMin = 0.3, lifetimeMax = 0.7,
        speedMin = 30, speedMax = 80, direction = -1.57, spread = 2.0,
        sizes = { 3, 1 }, colors = { 0.8, 0.7, 1.0, 1.0, 0.4, 0.3, 0.8, 0.0 },
    })

    -- Particle: search result glow
    ps_search = lurek.particle.newSystem({
        maxParticles = 30, emissionRate = 0,
        lifetimeMin = 0.4, lifetimeMax = 0.8,
        speedMin = 10, speedMax = 40, direction = 0, spread = 6.28,
        sizes = { 4, 2, 0 }, colors = { 1.0, 0.9, 0.3, 0.8, 0.4, 0.9, 0.5, 0.0 },
    })

    -- Title entrance tween
    lurek.tween.to(0.8, function(t)
        title_alpha = t
        title_scale = lerp(0.5, 1.0, t)
    end, { ease = "outBack" })
end

-- ── Update ─────────────────────────────────────────────────────────────────
function lurek.process(dt)
    ps_page:update(dt)
    ps_search:update(dt)
    lurek.tween.update(dt)

    -- ── TITLE ──────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("select") then
            current_state = STATE.BROWSING
            -- Animate coverage bar
            lurek.tween.to(1.0, function(t)
                coverage_bar = t
            end, { ease = "outQuad" })
            -- Slide panel in
            lurek.tween.to(0.4, function(t)
                panel_offset_x = lerp(PANEL_W, 0, t)
            end, { ease = "outCubic" })
        end
        return
    end

    -- ── BROWSING ───────────────────────────────────────────────
    if current_state == STATE.BROWSING then
        if lurek.input.wasActionPressed("quit") then
            lurek.event.quit()
        end
        if lurek.input.wasActionPressed("nav_up") then
            selected_func = selected_func - 1
            if selected_func < 1 then
                selected_ns = ((selected_ns - 2) % #namespaces) + 1
                selected_func = #namespaces[selected_ns].funcs
                current_page = total_pages(selected_ns)
                -- Page turn sparkle
                ps_page:moveTo(SIDEBAR_W * 0.5, SCREEN_H * 0.5)
                ps_page:emit(15)
            end
            local page_start = (current_page - 1) * FUNCS_PER_PAGE + 1
            if selected_func < page_start then
                current_page = math.max(1, current_page - 1)
            end
            -- Smooth sidebar scroll
            local target_y = (selected_ns - 1) * ITEM_H
            lurek.tween.to(0.2, function(t)
                sidebar_scroll_y = lerp(sidebar_scroll_y, target_y, t)
            end, { ease = "outQuad" })
        end
        if lurek.input.wasActionPressed("nav_down") then
            selected_func = selected_func + 1
            if selected_func > #namespaces[selected_ns].funcs then
                selected_ns = (selected_ns % #namespaces) + 1
                selected_func = 1
                current_page = 1
                ps_page:moveTo(SIDEBAR_W * 0.5, SCREEN_H * 0.5)
                ps_page:emit(15)
            end
            local page_end = current_page * FUNCS_PER_PAGE
            if selected_func > page_end then
                current_page = math.min(total_pages(selected_ns), current_page + 1)
            end
            local target_y = (selected_ns - 1) * ITEM_H
            lurek.tween.to(0.2, function(t)
                sidebar_scroll_y = lerp(sidebar_scroll_y, target_y, t)
            end, { ease = "outQuad" })
        end
        if lurek.input.wasActionPressed("nav_left") then
            current_page = math.max(1, current_page - 1)
            selected_func = (current_page - 1) * FUNCS_PER_PAGE + 1
            lurek.tween.to(0.3, function(t)
                panel_offset_x = lerp(20, 0, t)
            end, { ease = "outQuad" })
            ps_page:moveTo(PANEL_X + PANEL_W * 0.5, SCREEN_H * 0.5)
            ps_page:emit(10)
        end
        if lurek.input.wasActionPressed("nav_right") then
            current_page = math.min(total_pages(selected_ns), current_page + 1)
            selected_func = (current_page - 1) * FUNCS_PER_PAGE + 1
            lurek.tween.to(0.3, function(t)
                panel_offset_x = lerp(-20, 0, t)
            end, { ease = "outQuad" })
            ps_page:moveTo(PANEL_X + PANEL_W * 0.5, SCREEN_H * 0.5)
            ps_page:emit(10)
        end
        if lurek.input.wasActionPressed("select") then
            add_history(selected_ns, selected_func)
        end
        if lurek.input.wasActionPressed("search") then
            current_state = STATE.SEARCH
            search_query = ""
            search_results = {}
        end
        if lurek.input.wasActionPressed("bookmark") then
            toggle_bookmark(selected_ns, selected_func)
        end
        if lurek.input.wasActionPressed("history") then
            current_state = STATE.HISTORY
        end
        return
    end

    -- ── SEARCH ─────────────────────────────────────────────────
    if current_state == STATE.SEARCH then
        if lurek.input.wasActionPressed("quit") then
            current_state = STATE.BROWSING
        end
        -- Text input via character callback
        local ch = lurek.input.getTextInput()
        if ch and #ch > 0 then
            search_query = search_query .. ch
            do_search(search_query)
            if #search_results > 0 then
                ps_search:moveTo(PANEL_X + PANEL_W * 0.5, 120)
                ps_search:emit(8)
            end
        end
        if lurek.input.wasActionPressed("nav_up") then
            -- Remove last character (backspace behavior)
            if #search_query > 0 then
                search_query = search_query:sub(1, -2)
                do_search(search_query)
            end
        end
        if lurek.input.wasActionPressed("select") and #search_results > 0 then
            local r = search_results[1]
            selected_ns = r.ns_idx
            selected_func = r.func_idx
            current_page = math.ceil(r.func_idx / FUNCS_PER_PAGE)
            add_history(selected_ns, selected_func)
            current_state = STATE.BROWSING
        end
        return
    end

    -- ── BOOKMARKS ──────────────────────────────────────────────
    if current_state == STATE.BOOKMARKS then
        if lurek.input.wasActionPressed("quit") then
            current_state = STATE.BROWSING
        end
        if lurek.input.wasActionPressed("select") and #bookmarks > 0 then
            local bm = bookmarks[1]
            selected_ns = bm[1]
            selected_func = bm[2]
            current_page = math.ceil(bm[2] / FUNCS_PER_PAGE)
            add_history(selected_ns, selected_func)
            current_state = STATE.BROWSING
        end
        return
    end

    -- ── HISTORY ────────────────────────────────────────────────
    if current_state == STATE.HISTORY then
        if lurek.input.wasActionPressed("quit") then
            current_state = STATE.BROWSING
        end
        if lurek.input.wasActionPressed("select") and #history > 0 then
            local h = history[1]
            selected_ns = h[1]
            selected_func = h[2]
            current_page = math.ceil(h[2] / FUNCS_PER_PAGE)
            current_state = STATE.BROWSING
        end
        return
    end
end

-- ── Draw (game scene) ──────────────────────────────────────────────────────
function lurek.render()
    lurek.camera.attach()

    if current_state == STATE.TITLE then
        -- Title text
        set_color(COL.header, title_alpha)
        lurek.render.print("DOCS BROWSER", SCREEN_W * 0.5 - 100, SCREEN_H * 0.30)
        set_color(COL.param, title_alpha * 0.8)
        lurek.render.print("EXPLORE THE API", SCREEN_W * 0.5 - 90, SCREEN_H * 0.30 + 36)
        set_color(COL.muted, title_alpha * 0.5)
        lurek.render.print("Press ENTER to begin", SCREEN_W * 0.5 - 95, SCREEN_H * 0.60)
        set_color(COL.desc, title_alpha * 0.4)
        lurek.render.print(string.format("%d namespaces  |  %d functions", #namespaces, total_funcs),
            SCREEN_W * 0.5 - 110, SCREEN_H * 0.68)
    end

    -- Particles (world-space)
    lurek.render.setColor(1, 1, 1, 1)
    ps_page:draw()
    ps_search:draw()

    lurek.camera.detach()
end

-- ── Draw UI (overlays) ─────────────────────────────────────────────────────
function lurek.render_ui()
    if current_state == STATE.TITLE then return end

    local fps = lurek.timer.getFPS()

    -- ── Header ─────────────────────────────────────────────────
    set_color(COL.sidebar_bg)
    lurek.render.rectangle("fill", 0, 0, SCREEN_W, HEADER_H)
    set_color(COL.header)
    lurek.render.print("lurek.* API Reference", 12, 14)
    set_color(COL.muted)
    lurek.render.print(string.format("FPS: %d", fps), SCREEN_W - 80, 14)

    -- State indicator
    local state_label = ({ "TITLE", "BROWSING", "SEARCH", "BOOKMARKS", "HISTORY" })[current_state]
    set_color(COL.param, 0.6)
    lurek.render.print(state_label, SCREEN_W * 0.5 - 30, 14)

    -- ── Sidebar ────────────────────────────────────────────────
    set_color(COL.sidebar_bg)
    lurek.render.rectangle("fill", 0, HEADER_H, SIDEBAR_W, SCREEN_H - HEADER_H - FOOTER_H)

    for i, ns in ipairs(namespaces) do
        local y = HEADER_H + 8 + (i - 1) * ITEM_H - sidebar_scroll_y

        if y >= HEADER_H - ITEM_H and y < SCREEN_H - FOOTER_H then
            -- Selection highlight
            if i == selected_ns and current_state == STATE.BROWSING then
                set_color(COL.sidebar_sel)
                lurek.render.rectangle("fill", 4, y - 2, SIDEBAR_W - 8, ITEM_H)
            end

            -- Namespace name
            if i == selected_ns then
                set_color(COL.sidebar_hi)
            else
                set_color(COL.sidebar_text)
            end
            lurek.render.print(string.format("lurek.%s", ns.name), 12, y + 2)

            -- Function count badge
            set_color(COL.muted, 0.6)
            lurek.render.print(string.format("(%d)", #ns.funcs), SIDEBAR_W - 36, y + 2)
        end
    end

    -- Sidebar divider
    set_color(COL.muted, 0.3)
    lurek.render.line(SIDEBAR_W, HEADER_H, SIDEBAR_W, SCREEN_H - FOOTER_H)

    -- ── Main panel ─────────────────────────────────────────────
    if current_state == STATE.BROWSING then
        local px = PANEL_X + panel_offset_x
        local py = HEADER_H + 10
        local ns = namespaces[selected_ns]

        -- Namespace title
        set_color(COL.func_name)
        lurek.render.print(string.format("lurek.%s", ns.name), px, py)
        py = py + 30

        -- Functions for current page
        local funcs = page_funcs(selected_ns, current_page)
        for _, entry in ipairs(funcs) do
            local fn = entry.fn
            local is_sel = (entry.idx == selected_func)
            local is_bm  = is_bookmarked(selected_ns, entry.idx)

            -- Selection background
            if is_sel then
                set_color(COL.sidebar_sel, 0.5)
                lurek.render.rectangle("fill", px - 4, py - 2, PANEL_W - 8, 60)
            end

            -- Bookmark indicator
            if is_bm then
                set_color(COL.bookmark)
                lurek.render.print("*", px - 12, py)
            end

            -- Function signature: name(params) → ret
            set_color(COL.func_name)
            lurek.render.print(fn.name, px, py)
            local name_w = #fn.name * 8
            set_color(COL.white, 0.7)
            lurek.render.print("(", px + name_w, py)
            set_color(COL.param)
            lurek.render.print(fn.params, px + name_w + 8, py)
            local params_w = #fn.params * 8
            set_color(COL.white, 0.7)
            lurek.render.print(")", px + name_w + 8 + params_w, py)

            -- Return type
            if fn.ret ~= "" then
                set_color(COL.muted, 0.5)
                lurek.render.print(" -> ", px + name_w + 16 + params_w, py)
                set_color(COL.ret_type)
                lurek.render.print(fn.ret, px + name_w + 48 + params_w, py)
            end

            -- Description
            py = py + 18
            if fn.desc ~= "" then
                set_color(COL.desc)
                lurek.render.print(fn.desc, px + 8, py)
            else
                set_color(COL.muted, 0.4)
                lurek.render.print("(no description)", px + 8, py)
            end

            py = py + 28
        end

        -- Page indicator
        local pages = total_pages(selected_ns)
        if pages > 1 then
            set_color(COL.muted)
            lurek.render.print(string.format("Page %d/%d  (Left/Right)", current_page, pages),
                px, SCREEN_H - FOOTER_H - 28)
        end
    end

    -- ── Search overlay ─────────────────────────────────────────
    if current_state == STATE.SEARCH then
        set_color(COL.search_bg, 0.95)
        lurek.render.rectangle("fill", PANEL_X - 5, HEADER_H, PANEL_W + 10, SCREEN_H - HEADER_H - FOOTER_H)

        set_color(COL.header)
        lurek.render.print("SEARCH", PANEL_X + 10, HEADER_H + 10)

        -- Search input box
        set_color(COL.bar_bg)
        lurek.render.rectangle("fill", PANEL_X + 10, HEADER_H + 34, PANEL_W - 20, 24)
        set_color(COL.white)
        lurek.render.print("> " .. search_query .. "_", PANEL_X + 14, HEADER_H + 38)

        -- Results
        local ry = HEADER_H + 70
        set_color(COL.muted)
        lurek.render.print(string.format("%d results", #search_results), PANEL_X + 10, ry)
        ry = ry + 24

        local shown = math.min(#search_results, 8)
        for i = 1, shown do
            local r = search_results[i]
            local ns = namespaces[r.ns_idx]
            local fn = ns.funcs[r.func_idx]

            set_color(COL.muted, 0.5)
            lurek.render.print(string.format("lurek.%s.", ns.name), PANEL_X + 14, ry)
            set_color(COL.func_name)
            local prefix_w = (#ns.name + 7) * 8
            lurek.render.print(fn.name, PANEL_X + 14 + prefix_w, ry)

            ry = ry + 22
        end

        set_color(COL.muted, 0.4)
        lurek.render.print("Up=backspace | Enter=go | Esc=cancel", PANEL_X + 10, SCREEN_H - FOOTER_H - 28)
    end

    -- ── Bookmarks overlay ──────────────────────────────────────
    if current_state == STATE.BOOKMARKS then
        set_color(COL.search_bg, 0.95)
        lurek.render.rectangle("fill", PANEL_X - 5, HEADER_H, PANEL_W + 10, SCREEN_H - HEADER_H - FOOTER_H)

        set_color(COL.bookmark)
        lurek.render.print("BOOKMARKS", PANEL_X + 10, HEADER_H + 10)

        if #bookmarks == 0 then
            set_color(COL.muted)
            lurek.render.print("No bookmarks yet. Press B to bookmark.", PANEL_X + 10, HEADER_H + 40)
        else
            local by = HEADER_H + 40
            for i, bm in ipairs(bookmarks) do
                local ns = namespaces[bm[1]]
                local fn = ns.funcs[bm[2]]
                set_color(COL.bookmark, 0.8)
                lurek.render.print(string.format("%d. lurek.%s.%s", i, ns.name, fn.name), PANEL_X + 14, by)
                by = by + 22
            end
        end

        set_color(COL.muted, 0.4)
        lurek.render.print("Enter=go | Esc=back", PANEL_X + 10, SCREEN_H - FOOTER_H - 28)
    end

    -- ── History overlay ────────────────────────────────────────
    if current_state == STATE.HISTORY then
        set_color(COL.search_bg, 0.95)
        lurek.render.rectangle("fill", PANEL_X - 5, HEADER_H, PANEL_W + 10, SCREEN_H - HEADER_H - FOOTER_H)

        set_color(COL.history)
        lurek.render.print("HISTORY (last 10)", PANEL_X + 10, HEADER_H + 10)

        if #history == 0 then
            set_color(COL.muted)
            lurek.render.print("No history yet. Press Enter on a function.", PANEL_X + 10, HEADER_H + 40)
        else
            local hy = HEADER_H + 40
            for i, h in ipairs(history) do
                local ns = namespaces[h[1]]
                local fn = ns.funcs[h[2]]
                set_color(COL.history, 0.7)
                lurek.render.print(string.format("%d. lurek.%s.%s", i, ns.name, fn.name), PANEL_X + 14, hy)
                hy = hy + 22
            end
        end

        set_color(COL.muted, 0.4)
        lurek.render.print("Enter=go | Esc=back", PANEL_X + 10, SCREEN_H - FOOTER_H - 28)
    end

    -- ── Footer — coverage bar ──────────────────────────────────
    set_color(COL.sidebar_bg)
    lurek.render.rectangle("fill", 0, SCREEN_H - FOOTER_H, SCREEN_W, FOOTER_H)

    -- Coverage text
    local pct = math.floor((documented_funcs / total_funcs) * 100 + 0.5)
    set_color(COL.white, 0.8)
    lurek.render.print(string.format("%d/%d functions documented (%d%%)", documented_funcs, total_funcs, pct),
        12, SCREEN_H - FOOTER_H + 8)

    -- Coverage bar
    local bar_x, bar_w = 320, 200
    local bar_y, bar_h = SCREEN_H - FOOTER_H + 8, 14
    set_color(COL.bar_bg)
    lurek.render.rectangle("fill", bar_x, bar_y, bar_w, bar_h)
    local fill_w = bar_w * (documented_funcs / total_funcs) * coverage_bar
    if pct >= 80 then
        set_color(COL.bar_fill)
    else
        set_color(COL.bar_partial)
    end
    lurek.render.rectangle("fill", bar_x, bar_y, fill_w, bar_h)

    -- Controls hint
    set_color(COL.muted, 0.5)
    lurek.render.print("/=search  B=mark  H=hist  Tab=marks", SCREEN_W - 280, SCREEN_H - FOOTER_H + 8)
end

-- ── Keyboard text input for search ─────────────────────────────────────────
function lurek.keypressed(key)
    if current_state == STATE.SEARCH then
        if key == "backspace" and #search_query > 0 then
            search_query = search_query:sub(1, -2)
            do_search(search_query)
        end
    end
    if current_state == STATE.BROWSING then
        if key == "tab" then
            current_state = STATE.BOOKMARKS
        end
    end
end

function lurek.textinput(text)
    if current_state == STATE.SEARCH then
        search_query = search_query .. text
        do_search(search_query)
        if #search_results > 0 then
            ps_search:moveTo(PANEL_X + PANEL_W * 0.5, 120)
            ps_search:emit(8)
        end
    end
end
