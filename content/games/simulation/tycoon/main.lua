-- Tycoon — Lurek2D
-- Category: simulation
-- Business empire tycoon: buy ventures, hire managers, upgrade revenue, prestige to 1M gold.

local W, H = 800, 600

-- ── States ──────────────────────────────────────────────────────────────
local STATE_TITLE    = "TITLE"
local STATE_PLAYING  = "PLAYING"
local STATE_PRESTIGE = "PRESTIGE_CONFIRM"
local state = STATE_TITLE

-- ── Economy ─────────────────────────────────────────────────────────────
local gold = 500
local display_gold = 500
local total_gold = 0
local prestige_level = 0
local gold_per_second = 0

-- ── Interaction modes ───────────────────────────────────────────────────
local mode_manager  = false
local mode_upgrade  = false

-- ── Business definitions ────────────────────────────────────────────────
local businesses = {
    { name = "Lemonade Stand", key = "1", cost = 10,    revenue = 1,    cycle = 1,  owned = true,  level = 1, progress = 0, has_manager = false, upgraded = false, ready = false, slide_y = 0 },
    { name = "Pizza Shop",     key = "2", cost = 100,   revenue = 10,   cycle = 3,  owned = false, level = 0, progress = 0, has_manager = false, upgraded = false, ready = false, slide_y = 0 },
    { name = "Car Wash",       key = "3", cost = 500,   revenue = 50,   cycle = 6,  owned = false, level = 0, progress = 0, has_manager = false, upgraded = false, ready = false, slide_y = 0 },
    { name = "Bakery",         key = "4", cost = 2000,  revenue = 200,  cycle = 10, owned = false, level = 0, progress = 0, has_manager = false, upgraded = false, ready = false, slide_y = 0 },
    { name = "Hotel",          key = "5", cost = 10000, revenue = 1000, cycle = 15, owned = false, level = 0, progress = 0, has_manager = false, upgraded = false, ready = false, slide_y = 0 },
    { name = "Tech Company",   key = "6", cost = 50000, revenue = 5000, cycle = 20, owned = false, level = 0, progress = 0, has_manager = false, upgraded = false, ready = false, slide_y = 0 },
}

-- ── Particles ───────────────────────────────────────────────────────────
local particles = {}
local flash_particles = {}
local prestige_particles = {}

-- ── Tween state ─────────────────────────────────────────────────────────
local gold_tween_target = 500
local gold_tween_speed = 0
local title_pulse = 0
local unlock_slides = {}
---@type any
local _cam = nil

-- ── Helper: format number ───────────────────────────────────────────────
local function fmt(n)
    if n >= 1000000 then return string.format("%.2fM", n / 1000000)
    elseif n >= 1000 then return string.format("%.1fK", n / 1000)
    else return string.format("%.0f", n) end
end

-- ── Helper: prestige multiplier ─────────────────────────────────────────
local function prestige_mult()
    return math.pow(2, prestige_level)
end

-- ── Helper: effective revenue ───────────────────────────────────────────
local function effective_revenue(b)
    local base = b.revenue
    if b.upgraded then base = base * 2 end
    local level_bonus = 1 + (b.level - 1) * 0.5
    return base * level_bonus * prestige_mult()
end

-- ── Helper: manager cost ────────────────────────────────────────────────
local function manager_cost(b)
    return b.cost * 10
end

-- ── Helper: upgrade cost ────────────────────────────────────────────────
local function upgrade_cost(b)
    return math.floor(effective_revenue(b) * 5)
end

-- ── Helper: compute gold/second ─────────────────────────────────────────
local function compute_gps()
    local gps = 0
    for _, b in ipairs(businesses) do
        if b.owned then
            gps = gps + effective_revenue(b) / b.cycle
        end
    end
    return gps
end

-- ── Helper: business Y position ─────────────────────────────────────────
local function biz_y(idx)
    return 100 + (idx - 1) * 72
end

-- ── Helper: which business is clicked ───────────────────────────────────
local function biz_at_mouse()
    local mx, my = lurek.input.mouse.getPosition()
    for i, b in ipairs(businesses) do
        if b.owned then
            local y = biz_y(i) + b.slide_y
            if mx >= 40 and mx <= 540 and my >= y and my <= y + 56 then
                return i
            end
        end
    end
    return nil
end

-- ── Particle spawners ───────────────────────────────────────────────────
local function spawn_gold_burst(x, y, count)
    for _ = 1, count do
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * 220,
            vy = -math.random() * 200 - 60,
            life = 1.0,
            size = math.random(4, 10),
            r = 1.0, g = 0.85, b = 0.2,
        })
    end
end

local function spawn_upgrade_flash(x, y)
    for _ = 1, 12 do
        table.insert(flash_particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * 180,
            vy = (math.random() - 0.5) * 180,
            life = 0.7,
            size = math.random(3, 8),
            r = 0.3, g = 1.0, b = 0.5,
        })
    end
end

local function spawn_prestige_explosion()
    for _ = 1, 80 do
        local angle = math.random() * math.pi * 2
        local speed = math.random() * 450 + 120
        table.insert(prestige_particles, {
            x = W / 2, y = H / 2,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 1.8,
            size = math.random(5, 16),
            r = math.random() * 0.4 + 0.6,
            g = math.random() * 0.4 + 0.6,
            b = math.random() * 0.3,
        })
    end
end

-- ── Update particles list ───────────────────────────────────────────────
local function update_particles(list, dt)
    local i = 1
    while i <= #list do
        local p = list[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 300 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(list, i)
        else
            i = i + 1
        end
    end
end

-- ── Buy business ────────────────────────────────────────────────────────
local function buy_business(idx)
    local b = businesses[idx]
    if b.owned then return end
    if gold >= b.cost then
        gold = gold - b.cost
        b.owned = true
        b.level = 1
        b.progress = 0
        b.slide_y = 60
        table.insert(unlock_slides, { idx = idx, timer = 0.4 })
        spawn_upgrade_flash(290, biz_y(idx) + 28)
        gold_per_second = compute_gps()
    end
end

-- ── Hire manager ────────────────────────────────────────────────────────
local function hire_manager(idx)
    local b = businesses[idx]
    if not b.owned or b.has_manager then return end
    local cost = manager_cost(b)
    if gold >= cost then
        gold = gold - cost
        b.has_manager = true
        spawn_upgrade_flash(290, biz_y(idx) + 28)
    end
end

-- ── Upgrade business ────────────────────────────────────────────────────
local function upgrade_business(idx)
    local b = businesses[idx]
    if not b.owned then return end
    if b.level < 5 then
        local cost = upgrade_cost(b)
        if gold >= cost then
            gold = gold - cost
            b.level = b.level + 1
            gold_per_second = compute_gps()
            spawn_upgrade_flash(290, biz_y(idx) + 28)
        end
    elseif not b.upgraded then
        local cost = upgrade_cost(b)
        if gold >= cost then
            gold = gold - cost
            b.upgraded = true
            gold_per_second = compute_gps()
            spawn_upgrade_flash(290, biz_y(idx) + 28)
        end
    end
end

-- ── Collect gold ────────────────────────────────────────────────────────
local function collect_ready()
    for i, b in ipairs(businesses) do
        if b.owned and b.ready then
            local rev = effective_revenue(b)
            gold = gold + rev
            total_gold = total_gold + rev
            b.ready = false
            b.progress = 0
            gold_tween_target = gold
            spawn_gold_burst(540, biz_y(i) + 28, math.min(20, 6 + math.floor(rev / 50)))
        end
    end
end

-- ── Do prestige ─────────────────────────────────────────────────────────
local function do_prestige()
    prestige_level = prestige_level + 1
    gold = 500
    display_gold = 500
    gold_tween_target = 500
    total_gold = 0
    for _, b in ipairs(businesses) do
        if b.name == "Lemonade Stand" then
            b.owned = true; b.level = 1
        else
            b.owned = false; b.level = 0
        end
        b.progress = 0; b.ready = false
        b.has_manager = false; b.upgraded = false
        b.slide_y = 0
    end
    gold_per_second = compute_gps()
    spawn_prestige_explosion()
    state = STATE_PLAYING
end

-- ══════════════════════════════════════════════════════════════════════════
-- Engine callbacks
-- ══════════════════════════════════════════════════════════════════════════

function lurek.init()
    lurek.window.setTitle("Tycoon — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.06, 0.1)
    _cam = lurek.camera.new()
    _cam:setPosition(W, H)

    lurek.input.bind("buy1",     "1")
    lurek.input.bind("buy2",     "2")
    lurek.input.bind("buy3",     "3")
    lurek.input.bind("buy4",     "4")
    lurek.input.bind("buy5",     "5")
    lurek.input.bind("buy6",     "6")
    lurek.input.bind("manage",   "m")
    lurek.input.bind("upgrade",  "u")
    lurek.input.bind("collect",  "space")
    lurek.input.bind("prestige", "p")
    lurek.input.bind("select",   "mouse1")
    lurek.input.bind("quit",     "escape")
end

local function _ready_setup()
    gold_per_second = compute_gps()
end

function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then
        if state == STATE_PRESTIGE then
            state = STATE_PLAYING
            return
        end
        lurek.event.quit()
        return
    end

    -- ── TITLE ───────────────────────────────────────────────────────────
    if state == STATE_TITLE then
        title_pulse = title_pulse + dt * 2.5
        if lurek.input.wasActionPressed("collect") or lurek.input.wasActionPressed("select") then
            state = STATE_PLAYING
        end
        return
    end

    -- ── PRESTIGE_CONFIRM ────────────────────────────────────────────────
    if state == STATE_PRESTIGE then
        if lurek.input.wasActionPressed("collect") then
            do_prestige()
        end
        update_particles(prestige_particles, dt)
        return
    end

    -- ── PLAYING ─────────────────────────────────────────────────────────

    -- Mode toggles
    mode_manager = lurek.input.isActionDown("manage")
    mode_upgrade = lurek.input.isActionDown("upgrade")

    -- Buy businesses
    for i = 1, 6 do
        if lurek.input.wasActionPressed("buy" .. i) then
            buy_business(i)
        end
    end

    -- Mouse click interactions
    if lurek.input.wasActionPressed("select") then
        local idx = biz_at_mouse()
        if idx then
            if mode_manager then
                hire_manager(idx)
            elseif mode_upgrade then
                upgrade_business(idx)
            end
        end
    end

    -- Collect with space
    if lurek.input.wasActionPressed("collect") then
        collect_ready()
    end

    -- Prestige
    if lurek.input.wasActionPressed("prestige") and gold >= 100000 then
        state = STATE_PRESTIGE
    end

    -- Progress all owned businesses
    for _, b in ipairs(businesses) do
        if b.owned and not b.ready then
            b.progress = b.progress + dt / b.cycle
            if b.progress >= 1.0 then
                b.progress = 1.0
                b.ready = true
                if b.has_manager then
                    local rev = effective_revenue(b)
                    gold = gold + rev
                    total_gold = total_gold + rev
                    b.ready = false
                    b.progress = 0
                    gold_tween_target = gold
                end
            end
        end
    end

    -- Tween display gold toward actual gold
    if display_gold ~= gold then
        local diff = gold - display_gold
        local step = math.max(1, math.abs(diff) * 5 * dt)
        if math.abs(diff) < 1 then
            display_gold = gold
        elseif diff > 0 then
            display_gold = display_gold + step
        else
            display_gold = display_gold - step
        end
    end

    -- Unlock slide tweens
    local si = 1
    while si <= #unlock_slides do
        local s = unlock_slides[si]
        s.timer = s.timer - dt
        local b = businesses[s.idx]
        if s.timer <= 0 then
            b.slide_y = 0
            table.remove(unlock_slides, si)
        else
            b.slide_y = s.timer / 0.4 * 60
            si = si + 1
        end
    end

    -- Update gold/sec
    gold_per_second = compute_gps()

    -- Particles
    update_particles(particles, dt)
    update_particles(flash_particles, dt)
    update_particles(prestige_particles, dt)
end

-- ══════════════════════════════════════════════════════════════════════════
-- Render — business bars and progress
-- ══════════════════════════════════════════════════════════════════════════

local function rect(x,y,w,h,r,g,b,a)
    lurek.render.setColor(r or 1, g or 1, b or 1, a or 1)
    lurek.render.rectangle("fill", x, y, w, h)
end
local function circ(x,y,radius,r,g,b,a)
    lurek.render.setColor(r or 1, g or 1, b or 1, a or 1)
    lurek.render.circle("fill", x, y, radius)
end
local function text_(str,x,y,_sz,r,g,b,a)
    lurek.render.setColor(r or 1, g or 1, b or 1, a or 1)
    lurek.render.print(tostring(str), x, y)
end

function lurek.draw()
    -- ── TITLE ───────────────────────────────────────────────────────────
    if state == STATE_TITLE then
        local pulse = 0.7 + 0.3 * math.sin(title_pulse)
        text_("TYCOON", W / 2 - 120, H / 2 - 80, 52, 1.0, 0.85, 0.2, pulse)
        text_("BUILD YOUR EMPIRE", W / 2 - 130, H / 2, 22, 0.7, 0.7, 0.7, pulse * 0.8)
        text_("Press SPACE to start", W / 2 - 100, H / 2 + 60, 16, 0.5, 0.5, 0.5, 0.6)
        return
    end

    -- ── PRESTIGE_CONFIRM ────────────────────────────────────────────────
    if state == STATE_PRESTIGE then
        rect(W / 2 - 200, H / 2 - 80, 400, 160, 0.1, 0.08, 0.15, 0.95)
        text_("PRESTIGE?", W / 2 - 70, H / 2 - 60, 28, 1.0, 0.85, 0.2, 1.0)
        text_("Reset all for 2x multiplier", W / 2 - 120, H / 2 - 20, 16, 0.8, 0.8, 0.8, 1.0)
        text_("Current mult: " .. string.format("%dx", math.floor(prestige_mult() * 2)), W / 2 - 80, H / 2 + 10, 16, 0.5, 1.0, 0.5, 1.0)
        text_("SPACE = confirm  |  ESC = cancel", W / 2 - 140, H / 2 + 50, 14, 0.6, 0.6, 0.6, 0.8)
        -- Prestige particles
        for _, p in ipairs(prestige_particles) do
            local a = math.max(0, p.life / 1.8)
            rect(p.x, p.y, p.size, p.size, p.r, p.g, p.b, a)
        end
        return
    end

    -- ── PLAYING: business bars ──────────────────────────────────────────
    for i, b in ipairs(businesses) do
        local y = biz_y(i) + b.slide_y
        if b.owned then
            -- Background bar
            rect(40, y, 500, 56, 0.14, 0.12, 0.18, 0.9)

            -- Progress fill
            local fill_w = math.floor(496 * math.min(1, b.progress))
            local pr, pg, pb = 0.2, 0.6, 0.3
            if b.ready then pr, pg, pb = 1.0, 0.85, 0.2 end
            rect(42, y + 2, fill_w, 52, pr, pg, pb, 0.6)

            -- Name and level
            local label = b.name .. " Lv." .. b.level
            if b.upgraded then label = label .. " [2x]" end
            text_(label, 50, y + 6, 16, 1.0, 1.0, 1.0, 1.0)

            -- Revenue info
            local rev_text = fmt(effective_revenue(b)) .. "g / " .. b.cycle .. "s"
            text_(rev_text, 50, y + 30, 13, 0.8, 0.8, 0.6, 0.9)

            -- Manager badge
            if b.has_manager then
                rect(460, y + 6, 70, 18, 0.2, 0.5, 0.8, 0.8)
                text_("AUTO", 472, y + 8, 12, 1.0, 1.0, 1.0, 1.0)
            end

            -- Ready indicator
            if b.ready then
                rect(460, y + 32, 70, 18, 1.0, 0.85, 0.2, 0.9)
                text_("READY!", 466, y + 34, 12, 0.1, 0.08, 0.05, 1.0)
            end
        else
            -- Locked business
            rect(40, y, 500, 56, 0.1, 0.08, 0.12, 0.5)
            text_("[" .. b.key .. "] " .. b.name .. " — " .. fmt(b.cost) .. "g", 50, y + 18, 15, 0.4, 0.4, 0.4, 0.7)
        end
    end

    -- Gold-burst particles
    for _, p in ipairs(particles) do
        local a = math.max(0, p.life)
        rect(p.x, p.y, p.size, p.size, p.r, p.g, p.b, a)
    end

    -- Upgrade flash particles
    for _, p in ipairs(flash_particles) do
        local a = math.max(0, p.life / 0.7)
        rect(p.x, p.y, p.size, p.size, p.r, p.g, p.b, a)
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- Render UI — gold, stats, controls
-- ══════════════════════════════════════════════════════════════════════════

function lurek.draw_ui()
    if state == STATE_TITLE then return end
    if state == STATE_PRESTIGE then return end

    -- Gold display (tweened)
    text_("Gold: " .. fmt(math.floor(display_gold)), 580, 20, 22, 1.0, 0.85, 0.2, 1.0)
    text_(fmt(gold_per_second) .. " g/s", 580, 50, 14, 0.7, 0.7, 0.5, 0.9)

    -- Stats panel
    local owned_count = 0
    local manager_count = 0
    for _, b in ipairs(businesses) do
        if b.owned then owned_count = owned_count + 1 end
        if b.has_manager then manager_count = manager_count + 1 end
    end
    text_("Businesses: " .. owned_count .. "/6", 580, 90, 13, 0.6, 0.6, 0.6, 0.8)
    text_("Managers:   " .. manager_count, 580, 110, 13, 0.6, 0.6, 0.6, 0.8)
    text_("Total:      " .. fmt(total_gold), 580, 130, 13, 0.6, 0.6, 0.6, 0.8)
    if prestige_level > 0 then
        text_("Prestige:   " .. prestige_level .. "x (" .. math.floor(prestige_mult()) .. "x)", 580, 150, 13, 0.5, 1.0, 0.5, 0.8)
    end

    -- Mode indicator
    if mode_manager then
        rect(575, 180, 200, 24, 0.2, 0.5, 0.8, 0.8)
        text_("MODE: HIRE MANAGER (click biz)", 580, 183, 11, 1.0, 1.0, 1.0, 1.0)
    elseif mode_upgrade then
        rect(575, 180, 200, 24, 0.2, 0.8, 0.3, 0.8)
        text_("MODE: UPGRADE (click biz)", 580, 183, 11, 1.0, 1.0, 1.0, 1.0)
    end

    -- Prestige hint
    if gold >= 100000 then
        text_("[P] PRESTIGE AVAILABLE!", 580, 220, 14, 1.0, 0.5, 0.2, 0.8 + 0.2 * math.sin(lurek.timer.getTime() * 4))
    end

    -- Controls reminder
    text_("1-6: Buy  |  SPACE: Collect", 40, H - 40, 12, 0.4, 0.4, 0.4, 0.6)
    text_("M+Click: Manager  |  U+Click: Upgrade", 40, H - 24, 12, 0.4, 0.4, 0.4, 0.6)

    -- FPS
    text_("FPS: " .. lurek.timer.getFPS(), W - 80, H - 20, 11, 0.3, 0.3, 0.3, 0.5)
end
