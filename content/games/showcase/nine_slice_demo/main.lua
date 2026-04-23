-- Nine Slice Demo — Lurek2D
-- Category: showcase
-- Visual demonstration of 9-slice (9-patch) UI panel scaling techniques
-- Controls: Arrows resize | 1-5 styles | G grid | C compare | Escape quit
-- Run with: cargo run -- content/games/showcase/nine_slice_demo

-- ── Constants ──────────────────────────────────────────────────────────

local SCREEN_W, SCREEN_H = 800, 600
local SLICE              = 16          -- corner size in pixels
local MIN_PANEL_W        = 48
local MIN_PANEL_H        = 48
local MAX_PANEL_W        = 500
local MAX_PANEL_H        = 400
local RESIZE_STEP        = 10
local TWEEN_SPEED        = 0.25

-- ── Panel styles ───────────────────────────────────────────────────────
local STYLES = {
    { name = "Simple Border",   border = {0.85,0.85,0.85}, fill = {0.15,0.15,0.20}, corner = {0.85,0.85,0.85}, thick = 2 },
    { name = "Rounded Light",   border = {0.50,0.70,0.90}, fill = {0.10,0.12,0.18}, corner = {0.35,0.55,0.75}, thick = 2 },
    { name = "Thick Frame",     border = {0.90,0.75,0.30}, fill = {0.12,0.10,0.08}, corner = {0.90,0.75,0.30}, thick = 4 },
    { name = "Double Border",   border = {0.60,0.90,0.60}, fill = {0.08,0.14,0.08}, corner = {0.60,0.90,0.60}, thick = 2 },
    { name = "Decorative",      border = {0.90,0.50,0.90}, fill = {0.14,0.08,0.14}, corner = {1.00,0.85,0.30}, thick = 3 },
}

-- Scale demo row sizes
local SCALE_SIZES = {
    {  50,  50 },
    { 100,  75 },
    { 150, 100 },
    { 200, 140 },
    { 300, 200 },
}

-- ── State ──────────────────────────────────────────────────────────────
local state           = "TITLE"
local current_style   = 1
local panel_w         = 200
local panel_h         = 150
local target_w        = 200
local target_h        = 150
local show_grid       = false

local title_alpha       = 0
local title_prompt_alpha = 0
local title_prompt_dir   = 1

local particles = {}
local tweens    = {}

-- ── Helpers ────────────────────────────────────────────────────────────

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

-- ── Tween engine ───────────────────────────────────────────────────────

local function tween_add(tbl, key, target, dur, ease)
    ease = ease or "linear"
    -- remove existing tween on same key
    for i = #tweens, 1, -1 do
        if tweens[i].tbl == tbl and tweens[i].key == key then
            table.remove(tweens, i)
        end
    end
    table.insert(tweens, {
        tbl = tbl, key = key,
        start = tbl[key], target = target,
        duration = dur, elapsed = 0, ease = ease,
    })
end

local function ease_apply(e, t)
    if e == "ease_out"    then return 1 - (1 - t) * (1 - t) end
    if e == "ease_in"     then return t * t end
    if e == "ease_in_out" then
        if t < 0.5 then return 2 * t * t end
        return 1 - ((-2 * t + 2) * (-2 * t + 2)) / 2
    end
    return t
end

local function tweens_update(dt)
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        local t = clamp(tw.elapsed / tw.duration, 0, 1)
        t = ease_apply(tw.ease, t)
        tw.tbl[tw.key] = lerp(tw.start, tw.target, t)
        if tw.elapsed >= tw.duration then
            tw.tbl[tw.key] = tw.target
            table.remove(tweens, i)
        else
            i = i + 1
        end
    end
end

-- ── Particles ──────────────────────────────────────────────────────────

local function particle_spawn(x, y, count, r, g, b, life, spread)
    spread = spread or 50
    for _ = 1, count do
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * spread,
            vy = (math.random() - 0.5) * spread - 20,
            life = life or 0.8, max_life = life or 0.8,
            r = r, g = g, b = b,
            size = 2 + math.random() * 3,
        })
    end
end

local function particles_update(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 30 * dt   -- slight gravity
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

-- ── 9-slice draw ───────────────────────────────────────────────────────

local function draw_nine_slice(x, y, w, h, style)
    local s   = STYLES[style]
    local br  = s.border
    local fl  = s.fill
    local cr  = s.corner
    local thk = s.thick
    local sl  = SLICE

    -- center fill
    lurek.render.setColor(fl[1], fl[2], fl[3], 1)
    lurek.render.rectangle(x + sl, y + sl, w - sl * 2, h - sl * 2)

    -- edges (stretch)
    lurek.render.setColor(br[1], br[2], br[3], 1)
    -- top edge
    lurek.render.rectangle(x + sl, y, w - sl * 2, thk)
    lurek.render.rectangle(x + sl, y + thk, w - sl * 2, sl - thk)
    -- bottom edge
    lurek.render.rectangle(x + sl, y + h - sl, w - sl * 2, sl - thk)
    lurek.render.rectangle(x + sl, y + h - thk, w - sl * 2, thk)
    -- left edge
    lurek.render.rectangle(x, y + sl, thk, h - sl * 2)
    lurek.render.rectangle(x + thk, y + sl, sl - thk, h - sl * 2)
    -- right edge
    lurek.render.rectangle(x + w - sl, y + sl, sl - thk, h - sl * 2)
    lurek.render.rectangle(x + w - thk, y + sl, thk, h - sl * 2)

    -- edge fill (between border and center)
    lurek.render.setColor(fl[1] + 0.05, fl[2] + 0.05, fl[3] + 0.05, 1)
    lurek.render.rectangle(x + thk, y + thk, sl - thk, sl - thk)        -- inner TL
    lurek.render.rectangle(x + w - sl, y + thk, sl - thk, sl - thk)     -- inner TR
    lurek.render.rectangle(x + thk, y + h - sl, sl - thk, sl - thk)     -- inner BL
    lurek.render.rectangle(x + w - sl, y + h - sl, sl - thk, sl - thk)  -- inner BR

    -- corners (fixed size)
    lurek.render.setColor(cr[1], cr[2], cr[3], 1)
    lurek.render.rectangle(x, y, sl, thk)                              -- TL top
    lurek.render.rectangle(x, y, thk, sl)                              -- TL left
    lurek.render.rectangle(x + w - sl, y, sl, thk)                     -- TR top
    lurek.render.rectangle(x + w - thk, y, thk, sl)                    -- TR right
    lurek.render.rectangle(x, y + h - thk, sl, thk)                    -- BL bottom
    lurek.render.rectangle(x, y + h - sl, thk, sl)                     -- BL left
    lurek.render.rectangle(x + w - sl, y + h - thk, sl, thk)           -- BR bottom
    lurek.render.rectangle(x + w - thk, y + h - sl, thk, sl)           -- BR right

    -- double-border style: inner line
    if style == 4 then
        local off = thk + 2
        lurek.render.setColor(br[1] * 0.6, br[2] * 0.6, br[3] * 0.6, 0.7)
        lurek.render.rectangle(x + off, y + off, w - off * 2, 1)
        lurek.render.rectangle(x + off, y + h - off - 1, w - off * 2, 1)
        lurek.render.rectangle(x + off, y + off, 1, h - off * 2)
        lurek.render.rectangle(x + w - off - 1, y + off, 1, h - off * 2)
    end
end

-- draw slice grid overlay
local function draw_grid_overlay(x, y, w, h)
    local sl = SLICE
    lurek.render.setColor(1, 1, 0, 0.4)
    -- vertical lines at slice boundaries
    lurek.render.rectangle(x + sl, y, 1, h)
    lurek.render.rectangle(x + w - sl, y, 1, h)
    -- horizontal lines at slice boundaries
    lurek.render.rectangle(x, y + sl, w, 1)
    lurek.render.rectangle(x, y + h - sl, w, 1)
    -- label zones
    lurek.render.setColor(1, 1, 0, 0.6)
    lurek.render.print("C", x + 3, y + 2, 9)                               -- corner TL
    lurek.render.print("C", x + w - sl + 3, y + 2, 9)                      -- corner TR
    lurek.render.print("C", x + 3, y + h - sl + 2, 9)                      -- corner BL
    lurek.render.print("C", x + w - sl + 3, y + h - sl + 2, 9)             -- corner BR
    lurek.render.print("H", x + w * 0.5 - 4, y + 2, 9)                     -- edge top
    lurek.render.print("H", x + w * 0.5 - 4, y + h - sl + 2, 9)            -- edge bottom
    lurek.render.print("V", x + 3, y + h * 0.5 - 5, 9)                     -- edge left
    lurek.render.print("V", x + w - sl + 3, y + h * 0.5 - 5, 9)            -- edge right
    lurek.render.print("FILL", x + w * 0.5 - 12, y + h * 0.5 - 5, 9)       -- center
end

-- draw a naively stretched panel for comparison
local function draw_stretched(x, y, w, h, style)
    local s = STYLES[style]
    lurek.render.setColor(s.fill[1], s.fill[2], s.fill[3], 1)
    lurek.render.rectangle(x, y, w, h)
    lurek.render.setColor(s.border[1], s.border[2], s.border[3], 1)
    lurek.render.rectangle(x, y, w, s.thick)
    lurek.render.rectangle(x, y + h - s.thick, w, s.thick)
    lurek.render.rectangle(x, y, s.thick, h)
    lurek.render.rectangle(x + w - s.thick, y, s.thick, h)
end

-- ── Input bindings ─────────────────────────────────────────────────────

lurek.input.bind("resize_left",  "left")
lurek.input.bind("resize_right", "right")
lurek.input.bind("resize_up",    "up")
lurek.input.bind("resize_down",  "down")
lurek.input.bind("style_1",      "1")
lurek.input.bind("style_2",      "2")
lurek.input.bind("style_3",      "3")
lurek.input.bind("style_4",      "4")
lurek.input.bind("style_5",      "5")
lurek.input.bind("toggle_grid",  "g")
lurek.input.bind("compare",      "c")
lurek.input.bind("quit",         "escape")

local function switch_style(n)
    if n == current_style then return end
    current_style = n
    local s = STYLES[n]
    particle_spawn(SCREEN_W * 0.5, SCREEN_H * 0.35, 18, s.corner[1], s.corner[2], s.corner[3], 0.9, 70)
end

-- ── Callbacks ──────────────────────────────────────────────────────────

function lurek.init()
    SCREEN_W, SCREEN_H = lurek.window.getDimensions()
    lurek.render.setBackgroundColor(0.1, 0.08, 0.12)
    math.randomseed(os.time())
end

local function _ready_setup()
    lurek.window.setTitle("Nine Slice Demo — Lurek2D")
    tween_add(_G, "title_alpha", 1, 0.7, "ease_out")
end

function lurek.process(dt)
    tweens_update(dt)
    particles_update(dt)

    -- style switch / resize / quit (from removed lurek.input.on blocks)
    for i = 1, 5 do
        if lurek.input.wasActionPressed("style_" .. i) then
            if state ~= "TITLE" then switch_style(i) end
        end
    end
    if lurek.input.wasActionPressed("toggle_grid") then
        if state ~= "TITLE" then show_grid = not show_grid end
    end
    if lurek.input.wasActionPressed("compare") then
        if state == "EDITING" then state = "COMPARE"
        elseif state == "COMPARE" then state = "EDITING" end
    end
    if lurek.input.wasActionPressed("resize_left") then
        if state == "TITLE" then state = "EDITING"
        else target_w = clamp(target_w - RESIZE_STEP, MIN_PANEL_W, MAX_PANEL_W); tween_add(_G, "panel_w", target_w, TWEEN_SPEED, "ease_out") end
    end
    if lurek.input.wasActionPressed("resize_right") then
        if state == "TITLE" then state = "EDITING"
        else target_w = clamp(target_w + RESIZE_STEP, MIN_PANEL_W, MAX_PANEL_W); tween_add(_G, "panel_w", target_w, TWEEN_SPEED, "ease_out") end
    end
    if lurek.input.wasActionPressed("resize_up") then
        if state == "TITLE" then state = "EDITING"
        else target_h = clamp(target_h - RESIZE_STEP, MIN_PANEL_H, MAX_PANEL_H); tween_add(_G, "panel_h", target_h, TWEEN_SPEED, "ease_out") end
    end
    if lurek.input.wasActionPressed("resize_down") then
        if state == "TITLE" then state = "EDITING"
        else target_h = clamp(target_h + RESIZE_STEP, MIN_PANEL_H, MAX_PANEL_H); tween_add(_G, "panel_h", target_h, TWEEN_SPEED, "ease_out") end
    end
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    if state == "TITLE" then
        title_prompt_alpha = title_prompt_alpha + title_prompt_dir * dt * 2
        if title_prompt_alpha >= 1   then title_prompt_alpha = 1;   title_prompt_dir = -1 end
        if title_prompt_alpha <= 0.2 then title_prompt_alpha = 0.2; title_prompt_dir =  1 end
        return
    end

    -- update FPS in title bar
    lurek.window.setTitle(string.format(
        "Nine Slice Demo | Style: %s | %dx%d | FPS: %d",
        STYLES[current_style].name, math.floor(panel_w), math.floor(panel_h),
        lurek.timer.getFPS()
    ))
end

-- ── Render: world-space (empty for this UI demo) ───────────────────────

function lurek.draw()
    -- nothing in world space for this showcase
end

-- ── Render UI ──────────────────────────────────────────────────────────

function lurek.draw_ui()
    -- ── TITLE state ────────────────────────────────────────────────────
    if state == "TITLE" then
        lurek.render.setColor(1, 1, 1, title_alpha)
        lurek.render.print("NINE SLICE DEMO", SCREEN_W * 0.5 - 120, SCREEN_H * 0.5 - 70, 28)

        lurek.render.setColor(0.7, 0.6, 0.9, title_alpha * 0.9)
        lurek.render.print("SCALABLE UI PANELS", SCREEN_W * 0.5 - 100, SCREEN_H * 0.5 - 30, 18)

        lurek.render.setColor(0.5, 0.5, 0.6, title_prompt_alpha * 0.8)
        lurek.render.print("Press any arrow key to begin", SCREEN_W * 0.5 - 110, SCREEN_H * 0.5 + 20, 14)
        return
    end

    local pw = math.floor(panel_w)
    local ph = math.floor(panel_h)

    -- ── COMPARE state ──────────────────────────────────────────────────
    if state == "COMPARE" then
        local gap   = 40
        local total = pw * 2 + gap
        local sx    = math.floor((SCREEN_W - total) * 0.5)
        local sy    = math.floor((SCREEN_H * 0.45 - ph) * 0.5) + 30

        -- stretched version
        lurek.render.setColor(0.6, 0.6, 0.6, 0.8)
        lurek.render.print("Stretched (naive)", sx + pw * 0.5 - 55, sy - 22, 13)
        draw_stretched(sx, sy, pw, ph, current_style)

        -- 9-slice version
        local nx = sx + pw + gap
        lurek.render.setColor(0.6, 0.6, 0.6, 0.8)
        lurek.render.print("9-Slice (correct)", nx + pw * 0.5 - 55, sy - 22, 13)
        draw_nine_slice(nx, sy, pw, ph, current_style)
        if show_grid then draw_grid_overlay(nx, sy, pw, ph) end

        -- hint
        lurek.render.setColor(0.5, 0.5, 0.5, 0.6)
        lurek.render.print("Press C to return to editing", SCREEN_W * 0.5 - 100, sy + ph + 20, 12)
    else
        -- ── EDITING state ──────────────────────────────────────────────
        -- center panel
        local px = math.floor((SCREEN_W - pw) * 0.5)
        local py = math.floor((SCREEN_H * 0.55 - ph) * 0.5) + 10
        draw_nine_slice(px, py, pw, ph, current_style)
        if show_grid then draw_grid_overlay(px, py, pw, ph) end

        -- content text inside panel
        local text_margin = SLICE + 6
        local text_w = pw - text_margin * 2
        if text_w > 30 then
            lurek.render.setColor(0.8, 0.8, 0.85, 0.9)
            local sample = "The 9-slice technique keeps corners crisp and edges smooth at any panel size."
            -- simple word-wrap
            local words = {}
            for w in sample:gmatch("%S+") do words[#words + 1] = w end
            local lines = {}
            local line = ""
            for _, w in ipairs(words) do
                local test = (line == "") and w or (line .. " " .. w)
                if #test * 7 > text_w then
                    lines[#lines + 1] = line
                    line = w
                else
                    line = test
                end
            end
            if line ~= "" then lines[#lines + 1] = line end
            for li, l in ipairs(lines) do
                lurek.render.print(l, px + text_margin, py + text_margin + (li - 1) * 16, 12)
            end
        end

        -- size label
        lurek.render.setColor(0.9, 0.9, 0.9, 0.8)
        lurek.render.print(
            string.format("Width: %d  Height: %d", pw, ph),
            px + pw * 0.5 - 55, py + ph + 8, 12
        )
    end

    -- ── Scale demo row (bottom) ────────────────────────────────────────
    local row_y = SCREEN_H - 85
    lurek.render.setColor(0.5, 0.5, 0.6, 0.6)
    lurek.render.print("Scale comparison:", 10, row_y - 18, 11)

    local rx = 10
    for _, sz in ipairs(SCALE_SIZES) do
        local sw, sh = sz[1], sz[2]
        -- scale down to fit row
        local scale = math.min(1, 70 / sh)
        local dw = math.floor(sw * scale)
        local dh = math.floor(sh * scale)
        draw_nine_slice(rx, row_y, dw, dh, current_style)
        lurek.render.setColor(0.5, 0.5, 0.5, 0.5)
        lurek.render.print(string.format("%dx%d", sw, sh), rx, row_y + dh + 2, 9)
        rx = rx + dw + 12
    end

    -- ── Particles (screen space) ───────────────────────────────────────
    for _, p in ipairs(particles) do
        local a = clamp(p.life / p.max_life, 0, 1)
        lurek.render.setColor(p.r, p.g, p.b, a)
        lurek.render.rectangle(p.x - p.size * 0.5, p.y - p.size * 0.5, p.size, p.size)
    end

    -- ── Style selector bar ─────────────────────────────────────────────
    lurek.render.setColor(0, 0, 0, 0.45)
    lurek.render.rectangle(0, 0, SCREEN_W, 28)
    for i, s in ipairs(STYLES) do
        local bx = 10 + (i - 1) * 155
        if i == current_style then
            lurek.render.setColor(s.corner[1], s.corner[2], s.corner[3], 1)
        else
            lurek.render.setColor(0.45, 0.45, 0.45, 0.7)
        end
        lurek.render.print(string.format("[%d] %s", i, s.name), bx, 6, 12)
    end

    -- ── Controls hint ──────────────────────────────────────────────────
    lurek.render.setColor(0.4, 0.4, 0.45, 0.5)
    lurek.render.print(
        "Arrows: resize | 1-5: style | G: grid | C: compare | ESC: quit",
        10, SCREEN_H - 16, 10
    )
end
