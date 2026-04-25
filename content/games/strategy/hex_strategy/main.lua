-- ============================================================
-- Hex Strategy — Resource expansion on a procedural hex map
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/hex_strategy
-- ============================================================

local W, H      = 800, 600
local HEX_SIZE  = 36
local OX, OY    = 400, 300
local MAP_RADIUS = 5

-- Terrain definitions
local TERRAIN = {
    grass    = { color = {0.3,0.7,0.25,1},   gold=1, wood=0, food=3, label="Grass"    },
    forest   = { color = {0.15,0.45,0.12,1}, gold=0, wood=3, food=1, label="Forest"   },
    water    = { color = {0.15,0.35,0.8,1},  gold=0, wood=0, food=2, label="Water"    },
    mountain = { color = {0.5,0.45,0.4,1},   gold=3, wood=0, food=0, label="Mountain" },
    desert   = { color = {0.85,0.75,0.4,1},  gold=2, wood=0, food=0, label="Desert"   },
}
local TERRAIN_KEYS = { "grass", "forest", "water", "mountain", "desert" }

-- Map
local hexes   = {}      -- key = "q,r" -> { q, r, terrain, owner, city }
local selected = nil

-- Player state
local resources = { gold = 50, wood = 20, food = 30 }
local owned     = 0
local turn_num  = 1
local score     = 0
local info_text = ""
local info_timer = 0

-- Particles
local expand_burst = nil
local city_sparkle = nil

-- ── Helpers ───────────────────────────────────────────────
local function hex_key(q, r) return q .. "," .. r end

local function hex_to_pixel(q, r)
    local x = HEX_SIZE * (1.732 * q + 0.866 * r)
    local y = HEX_SIZE * 1.5 * r
    return OX + x, OY + y
end

local function pixel_to_hex(px, py)
    local x, y = px - OX, py - OY
    local q = (x * 0.5774 - y / 3) / HEX_SIZE
    local r = y * 0.6667 / HEX_SIZE
    local rq = math.floor(q + 0.5)
    local rr = math.floor(r + 0.5)
    local rs = -rq - rr
    local dq = math.abs(rq - q)
    local dr = math.abs(rr - r)
    local ds = math.abs(rs - (-q - r))
    if dq > dr and dq > ds then rq = -rr - rs
    elseif dr > ds then rr = -rq - rs end
    return rq, rr
end

local function hex_neighbors(q, r)
    local dirs = {{1,0},{-1,0},{0,1},{0,-1},{1,-1},{-1,1}}
    local out = {}
    for _, d in ipairs(dirs) do out[#out+1] = {q+d[1], r+d[2]} end
    return out
end

local function is_adjacent_to_owned(q, r)
    for _, n in ipairs(hex_neighbors(q, r)) do
        local h = hexes[hex_key(n[1], n[2])]
        if h and h.owner == "player" then return true end
    end
    return false
end

local function show_info(msg)
    info_text  = msg
    info_timer = 3.0
end

-- ── Map generation ────────────────────────────────────────
local function gen_map()
    math.randomseed(os.time())
    for q = -MAP_RADIUS, MAP_RADIUS do
        for r = -MAP_RADIUS, MAP_RADIUS do
            if math.abs(q + r) <= MAP_RADIUS then
                local d = math.max(math.abs(q), math.abs(r), math.abs(q+r))
                local t_key
                if d == 0 then
                    t_key = "grass"  -- start center
                else
                    local roll = math.random()
                    if roll < 0.35 then t_key = "grass"
                    elseif roll < 0.55 then t_key = "forest"
                    elseif roll < 0.65 then t_key = "water"
                    elseif roll < 0.80 then t_key = "mountain"
                    else t_key = "desert" end
                end
                local key = hex_key(q, r)
                hexes[key] = { q=q, r=r, terrain=t_key, owner=nil, city=false }
            end
        end
    end
    -- Player starts at (0,0)
    hexes["0,0"].owner = "player"
    owned = 1
end

-- ── Next turn ─────────────────────────────────────────────
local function next_turn()
    turn_num = turn_num + 1
    -- Collect resources from owned hexes
    for _, h in pairs(hexes) do
        if h.owner == "player" then
            local t = TERRAIN[h.terrain]
            local mult = h.city and 2 or 1
            resources.gold = resources.gold + t.gold * mult
            resources.wood = resources.wood + t.wood * mult
            resources.food = resources.food + t.food * mult
        end
    end
    score = score + owned * 5
    show_info("Turn " .. turn_num .. " — collected resources")
end

-- ── Input bindings ────────────────────────────────────────
lurek.input.bind("click",      "mouse1")
lurek.input.bind("build_city", "c")
lurek.input.bind("next_turn",  "n")
lurek.input.bind("quit",       "escape")

-- ── Init ──────────────────────────────────────────────────

-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("Hex Strategy — Lurek2D")
    lurek.render.setBackgroundColor(0.04, 0.06, 0.1)

    expand_burst = lurek.particle.newSystem({
        maxParticles = 20,
        emitRate = 0, lifetime = {0.3,0.6}, speed = {20,70},
        startColor = {0.4,0.9,0.4,1}, endColor = {0.1,0.4,0.1,0},
        startSize = 4, endSize = 1, spread = math.pi*2
    })

    city_sparkle = lurek.particle.newSystem({
        maxParticles = 16,
        emitRate = 0, lifetime = {0.4,0.8}, speed = {10,40},
        startColor = {1,0.9,0.3,1}, endColor = {0.8,0.5,0.0,0},
        startSize = 4, endSize = 1, spread = math.pi*2
    })

    gen_map()
end

-- ── Process ───────────────────────────────────────────────
function lurek.process(dt)
    if expand_burst then expand_burst:update(dt) end
    if city_sparkle then city_sparkle:update(dt) end
    if info_timer > 0 then info_timer = info_timer - dt end

    if lurek.input.wasActionPressed("quit") then lurek.event.quit() return end
    if lurek.input.wasActionPressed("next_turn") then next_turn() return end

    local mx, my = lurek.input.getPosition()
    local hq, hr = pixel_to_hex(mx, my)
    local hkey   = hex_key(hq, hr)
    local hex    = hexes[hkey]

    -- Select hex
    if lurek.input.wasActionPressed("click") then
        if hex then
            selected = hex
            -- If unowned and adjacent to owned: expand (cost 30g + 10w)
            if hex.owner == nil and is_adjacent_to_owned(hq, hr) then
                if resources.gold >= 30 and resources.wood >= 10 then
                    resources.gold = resources.gold - 30
                    resources.wood = resources.wood - 10
                    hex.owner      = "player"
                    owned          = owned + 1
                    local px, py   = hex_to_pixel(hq, hr)
                    if expand_burst then expand_burst:emit(px + W/2 - OX, py + H/2 - OY, 8) end
                    show_info("Claimed " .. TERRAIN[hex.terrain].label)
                else
                    show_info("Need 30 gold + 10 wood to expand")
                end
            end
        end
    end

    -- Build city on selected owned hex (cost 50g + 20w + 20f)
    if lurek.input.wasActionPressed("build_city") then
        if selected and selected.owner == "player" and not selected.city then
            if resources.gold >= 50 and resources.wood >= 20 and resources.food >= 20 then
                resources.gold = resources.gold - 50
                resources.wood = resources.wood - 20
                resources.food = resources.food - 20
                selected.city  = true
                local px, py   = hex_to_pixel(selected.q, selected.r)
                if city_sparkle then city_sparkle:emit(px + W/2 - OX, py + H/2 - OY, 10) end
                show_info("City built! Double resources from this hex")
                score = score + 50
            else
                show_info("City needs 50g + 20w + 20f")
            end
        elseif selected and selected.city then
            show_info("City already built here")
        end
    end
end

-- ── Render ────────────────────────────────────────────────
function lurek.draw()
    -- Draw each hex
    for _, h in pairs(hexes) do
        local cx, cy = hex_to_pixel(h.q, h.r)
        local sx, sy = cx - OX + W/2, cy - OY + H/2
        local t   = TERRAIN[h.terrain]
        local col = { t.color[1], t.color[2], t.color[3], 1.0 }
        if h.owner == "player" then col = { math.min(1, col[1]+0.15), math.min(1,col[2]+0.15), math.min(1,col[3]+0.15), 1 } end

        -- Flat-hex approximation using two overlapping rects (diamond)
        local hw = HEX_SIZE * 0.9
        local hh = HEX_SIZE * 0.78
        rect(sx - hw/2, sy - hh/2, hw, hh, { color = col })

        if selected and selected.q == h.q and selected.r == h.r then
            rect(sx - hw/2 - 2, sy - hh/2 - 2, hw + 4, hh + 4, { color = {1,1,0.3,0.35} })
        end

        -- City marker
        if h.city then
            circ(sx, sy, 8, { color = {1,0.85,0.2,1}, segments = 6 })
        end

        -- Player border dot
        if h.owner == "player" and not h.city then
            circ(sx, sy, 5, { color = {0.4,0.7,1.0,0.9}, segments = 6 })
        end
    end

    if expand_burst then expand_burst:draw() end
    if city_sparkle then city_sparkle:draw() end
end

-- ── Render UI ─────────────────────────────────────────────
function lurek.draw_ui()
    rect(0, 0, W, 44, { color = {0.06,0.08,0.08,0.92} })
    text_("Gold:" .. math.floor(resources.gold), 10, 8, { color = {1,0.85,0.2,1}, size = 13 })
    text_("Wood:" .. math.floor(resources.wood), 110, 8, { color = {0.5,0.8,0.3,1}, size = 13 })
    text_("Food:" .. math.floor(resources.food), 210, 8, { color = {0.85,0.55,0.2,1}, size = 13 })
    text_("Hexes:" .. owned, 310, 8, { color = {0.7,0.7,1,1}, size = 13 })
    text_("Turn:" .. turn_num, 410, 8, { color = {1,1,1,1}, size = 13 })
    text_("Score:" .. score, 510, 8, { color = {1,0.9,0.4,1}, size = 13 })
    text_("Click adj hex=expand(30g+10w)  C=city(50g+20w+20f)  N=next turn", 10, 26, { color = {0.4,0.4,0.4,1}, size = 11 })

    if selected then
        local t = TERRAIN[selected.terrain]
        local lbl = t.label .. " — gold:" .. t.gold .. " wood:" .. t.wood .. " food:" .. t.food
        if selected.city then lbl = lbl .. " [CITY ×2]" end
        text_(lbl, 10, H - 20, { color = {0.7,0.9,1,1}, size = 12 })
    end

    if info_timer > 0 then
        local a = math.min(1.0, info_timer)
        text_(info_text, W/2 - 140, H/2 - 16, { color = {1,1,0.6,a}, size = 18 })
    end
end
