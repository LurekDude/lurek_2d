-- Idle Game — Lurek2D
-- Category: simulation
-- A complete idle/clicker game with auto-producers, upgrades, prestige, and achievements.

local W, H = 800, 600

-- ── States ──────────────────────────────────────────────────────────────
local STATE_TITLE = "TITLE"
local STATE_PLAYING = "PLAYING"
local STATE_PRESTIGE = "PRESTIGE_CONFIRM"
local state = STATE_TITLE

-- ── Economy ─────────────────────────────────────────────────────────────
local gold = 0
local display_gold = 0
local total_gold_earned = 0
local total_clicks = 0
local base_click = 1
local click_power_bonus = 0
local prestige_level = 0
local gold_per_second = 0

-- ── Auto-clicker definitions ────────────────────────────────────────────
local producers = {
    { name = "Cursor",  key = "c", base_cost = 15,     rate = 0.1,   owned = 0 },
    { name = "Worker",  key = "w", base_cost = 100,    rate = 1,     owned = 0 },
    { name = "Factory", key = "f", base_cost = 1000,   rate = 10,    owned = 0 },
    { name = "Robot",   key = "r", base_cost = 10000,  rate = 100,   owned = 0 },
    { name = "AI",      key = "a", base_cost = 100000, rate = 1000,  owned = 0 },
}

-- ── Click upgrades ──────────────────────────────────────────────────────
local click_upgrades = {
    { name = "Better Click", key = "b", base_cost = 50,  bonus = 1,  owned = 0 },
    { name = "Super Click",  key = "s", base_cost = 500, bonus = 10, owned = 0 },
}

-- ── Achievements ────────────────────────────────────────────────────────
local achievements = {
    { name = "First Click",     desc = "Click once",             check = function() return total_clicks >= 1 end,     unlocked = false },
    { name = "100 Gold",        desc = "Earn 100 gold total",    check = function() return total_gold_earned >= 100 end, unlocked = false },
    { name = "1K Producer",     desc = "1000/s production",      check = function() return gold_per_second >= 1000 end,  unlocked = false },
    { name = "Millionaire",     desc = "Earn 1M gold total",     check = function() return total_gold_earned >= 1000000 end, unlocked = false },
    { name = "Prestige Master", desc = "Prestige once",          check = function() return prestige_level >= 1 end,   unlocked = false },
}

-- ── Particles ───────────────────────────────────────────────────────────
local particles = {}
local sparkles = {}

-- ── Tweens / animation state ────────────────────────────────────────────
local button_scale = 1.0
local button_pulse_timer = 0
local gold_flash_timer = 0
local prestige_explosion = {}
local achievement_popup = nil
local achievement_popup_timer = 0

-- ── Conveyor animation ─────────────────────────────────────────────────
local conveyor_offset = 0

-- ── Helper: cost calculation ────────────────────────────────────────────
local function get_cost(base_cost, owned)
    return math.floor(base_cost * (1.15 ^ owned))
end

-- ── Helper: format large numbers ────────────────────────────────────────
local function fmt(n)
    if n >= 1000000000 then return string.format("%.2fB", n / 1000000000)
    elseif n >= 1000000 then return string.format("%.2fM", n / 1000000)
    elseif n >= 1000 then return string.format("%.1fK", n / 1000)
    else return string.format("%.0f", n) end
end

-- ── Helper: prestige multiplier ─────────────────────────────────────────
local function prestige_mult()
    return math.pow(2, prestige_level)
end

-- ── Helper: compute gold per second ─────────────────────────────────────
local function compute_gps()
    local gps = 0
    for _, p in ipairs(producers) do
        gps = gps + p.rate * p.owned
    end
    return gps * prestige_mult()
end

-- ── Helper: spawn click particles ───────────────────────────────────────
local function spawn_click_particles(x, y, count)
    for _ = 1, count do
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * 200,
            vy = -math.random() * 250 - 50,
            life = 1.0,
            size = math.random(4, 10),
            r = 1.0, g = 0.85, b = 0.2,
        })
    end
end

-- ── Helper: spawn purchase sparkles ─────────────────────────────────────
local function spawn_sparkles(x, y)
    for _ = 1, 8 do
        table.insert(sparkles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * 150,
            vy = (math.random() - 0.5) * 150,
            life = 0.6,
            size = math.random(3, 7),
        })
    end
end

-- ── Helper: spawn prestige explosion ────────────────────────────────────
local function spawn_prestige_explosion()
    for _ = 1, 60 do
        local angle = math.random() * math.pi * 2
        local speed = math.random() * 400 + 100
        table.insert(prestige_explosion, {
            x = W / 2, y = H / 2,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 1.5,
            size = math.random(5, 14),
            r = math.random() * 0.5 + 0.5,
            g = math.random() * 0.3 + 0.7,
            b = math.random() * 0.5,
        })
    end
end

-- ── Helper: do click ────────────────────────────────────────────────────
local function do_click()
    local power = (base_click + click_power_bonus) * prestige_mult()
    gold = gold + power
    total_gold_earned = total_gold_earned + power
    total_clicks = total_clicks + 1
    button_pulse_timer = 0.15
    button_scale = 1.3
    spawn_click_particles(W / 2, H / 2 - 20, math.min(12, 4 + math.floor(power / 10)))
end

-- ── Helper: buy producer ────────────────────────────────────────────────
local function buy_producer(idx)
    local p = producers[idx]
    local cost = get_cost(p.base_cost, p.owned)
    if gold >= cost then
        gold = gold - cost
        p.owned = p.owned + 1
        gold_per_second = compute_gps()
        spawn_sparkles(680, 120 + (idx - 1) * 55)
    end
end

-- ── Helper: buy click upgrade ───────────────────────────────────────────
local function buy_click_upgrade(idx)
    local u = click_upgrades[idx]
    local cost = get_cost(u.base_cost, u.owned)
    if gold >= cost then
        gold = gold - cost
        u.owned = u.owned + 1
        click_power_bonus = click_power_bonus + u.bonus
        spawn_sparkles(680, 410 + (idx - 1) * 55)
    end
end

-- ── Helper: do prestige ─────────────────────────────────────────────────
local function do_prestige()
    if gold >= 1000000 then
        prestige_level = prestige_level + 1
        gold = 0
        display_gold = 0
        click_power_bonus = 0
        for _, p in ipairs(producers) do p.owned = 0 end
        for _, u in ipairs(click_upgrades) do u.owned = 0 end
        gold_per_second = 0
        spawn_prestige_explosion()
        state = STATE_PLAYING
    end
end

-- ── Helper: check achievements ──────────────────────────────────────────
local function check_achievements()
    for _, a in ipairs(achievements) do
        if not a.unlocked and a.check() then
            a.unlocked = true
            achievement_popup = a.name
            achievement_popup_timer = 3.0
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- Engine callbacks
-- ══════════════════════════════════════════════════════════════════════════

function lurek.init()
    lurek.window.setTitle("Idle Game — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.06, 0.1)
    _cam:setPosition(W, H)

    lurek.input.bind("click",        "space")
    lurek.input.bind("cursor_buy",   "c")
    lurek.input.bind("worker_buy",   "w")
    lurek.input.bind("factory_buy",  "f")
    lurek.input.bind("robot_buy",    "r")
    lurek.input.bind("ai_buy",       "a")
    lurek.input.bind("better_click", "b")
    lurek.input.bind("super_click",  "s")
    lurek.input.bind("prestige",     "p")
    lurek.input.bind("quit",         "escape")
end

local function _ready_setup()
    gold_per_second = compute_gps()
end

function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- ── TITLE state ─────────────────────────────────────────────────────
    if state == STATE_TITLE then
        if lurek.input.wasActionPressed("click") then
            state = STATE_PLAYING
        end
        return
    end

    -- ── PRESTIGE_CONFIRM state ──────────────────────────────────────────
    if state == STATE_PRESTIGE then
        if lurek.input.wasActionPressed("click") then
            do_prestige()
        elseif lurek.input.wasActionPressed("quit") then
            state = STATE_PLAYING
        end
        return
    end

    -- ── PLAYING state ───────────────────────────────────────────────────

    -- Manual click
    if lurek.input.wasActionPressed("click") then
        do_click()
    end

    -- Auto-production
    local auto_income = gold_per_second * dt
    gold = gold + auto_income
    total_gold_earned = total_gold_earned + auto_income

    -- Smooth gold display
    local diff = gold - display_gold
    if math.abs(diff) < 0.5 then
        display_gold = gold
    else
        display_gold = display_gold + diff * math.min(1, dt * 12)
    end

    -- Buy producers
    if lurek.input.wasActionPressed("cursor_buy")  then buy_producer(1) end
    if lurek.input.wasActionPressed("worker_buy")  then buy_producer(2) end
    if lurek.input.wasActionPressed("factory_buy") then buy_producer(3) end
    if lurek.input.wasActionPressed("robot_buy")   then buy_producer(4) end
    if lurek.input.wasActionPressed("ai_buy")      then buy_producer(5) end

    -- Buy click upgrades
    if lurek.input.wasActionPressed("better_click") then buy_click_upgrade(1) end
    if lurek.input.wasActionPressed("super_click")  then buy_click_upgrade(2) end

    -- Prestige
    if lurek.input.wasActionPressed("prestige") and gold >= 1000000 then
        state = STATE_PRESTIGE
    end

    -- Button pulse tween
    if button_pulse_timer > 0 then
        button_pulse_timer = button_pulse_timer - dt
        button_scale = 1.0 + 0.3 * (button_pulse_timer / 0.15)
    else
        button_scale = 1.0
    end

    -- Gold flash
    if gold_flash_timer > 0 then
        gold_flash_timer = gold_flash_timer - dt
    end

    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 300 * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end

    -- Update sparkles
    for i = #sparkles, 1, -1 do
        local s = sparkles[i]
        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt
        s.life = s.life - dt
        if s.life <= 0 then table.remove(sparkles, i) end
    end

    -- Update prestige explosion
    for i = #prestige_explosion, 1, -1 do
        local e = prestige_explosion[i]
        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt
        e.life = e.life - dt
        if e.life <= 0 then table.remove(prestige_explosion, i) end
    end

    -- Achievement popup timer
    if achievement_popup_timer > 0 then
        achievement_popup_timer = achievement_popup_timer - dt
        if achievement_popup_timer <= 0 then achievement_popup = nil end
    end

    -- Conveyor animation
    conveyor_offset = (conveyor_offset + dt * 40) % 20

    -- Check achievements
    check_achievements()
end

-- ── Render: game world visuals ──────────────────────────────────────────
function lurek.draw()
    if state == STATE_TITLE then
        -- Title screen
        lurek.render.print("IDLE GAME", W / 2 - 120, H / 3, { size = 48, color = {1, 0.85, 0.2, 1} })
        lurek.render.print("CLICK YOUR WAY TO RICHES", W / 2 - 170, H / 3 + 60, { size = 20, color = {0.7, 0.7, 0.8, 1} })
        lurek.render.print("[SPACE] to Start", W / 2 - 80, H * 2 / 3, { size = 18, color = {0.5, 0.5, 0.6, 1} })
        return
    end

    -- ── Click button (center) ───────────────────────────────────────────
    local bx, by = W / 2 - 50, H / 2 - 70
    local bw, bh = 100, 100
    local sx = bw * button_scale
    local sy = bh * button_scale
    local ox = bx - (sx - bw) / 2
    local oy = by - (sy - bh) / 2

    -- Button glow
    lurek.render.rectangle(ox - 4, oy - 4, sx + 8, sy + 8, { color = {1, 0.85, 0.2, 0.3}, filled = true })
    -- Button body
    lurek.render.rectangle(ox, oy, sx, sy, { color = {1, 0.75, 0.1, 1}, filled = true })
    -- Button border
    lurek.render.rectangle(ox, oy, sx, sy, { color = {1, 0.95, 0.5, 1}, filled = false })
    -- Coin symbol
    lurek.render.print("$", ox + sx / 2 - 14, oy + sy / 2 - 18, { size = 36, color = {0.1, 0.05, 0, 1} })

    -- Click particles (gold coins)
    for _, p in ipairs(particles) do
        local alpha = math.max(0, p.life)
        lurek.render.rectangle(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size,
            { color = {p.r, p.g, p.b, alpha}, filled = true })
    end

    -- Sparkles (purchase feedback)
    for _, s in ipairs(sparkles) do
        local alpha = math.max(0, s.life / 0.6)
        lurek.render.rectangle(s.x - s.size / 2, s.y - s.size / 2, s.size, s.size,
            { color = {0.4, 1, 0.5, alpha}, filled = true })
    end

    -- Prestige explosion
    for _, e in ipairs(prestige_explosion) do
        local alpha = math.max(0, e.life / 1.5)
        lurek.render.rectangle(e.x - e.size / 2, e.y - e.size / 2, e.size, e.size,
            { color = {e.r, e.g, e.b, alpha}, filled = true })
    end

    -- Conveyor belt decoration at bottom
    local cy = H - 30
    for x = -20, W, 20 do
        local cx = x + conveyor_offset
        lurek.render.rectangle(cx, cy, 10, 6, { color = {0.25, 0.22, 0.3, 0.6}, filled = true })
    end
    lurek.render.rectangle(0, cy - 2, W, 2, { color = {0.35, 0.3, 0.4, 0.8}, filled = true })
end

-- ── Render UI: panels, stats, upgrades ──────────────────────────────────
function lurek.draw_ui()
    if state == STATE_TITLE then return end

    -- ── Gold display (top center) ───────────────────────────────────────
    local gold_color = gold_flash_timer > 0 and {1, 1, 0.5, 1} or {1, 0.85, 0.2, 1}
    lurek.render.print("Gold: " .. fmt(display_gold), W / 2 - 80, 20, { size = 28, color = gold_color })

    -- ── Production rate ─────────────────────────────────────────────────
    lurek.render.print(fmt(gold_per_second) .. "/s", W / 2 - 30, 55, { size = 16, color = {0.6, 0.8, 0.6, 1} })

    -- ── Click power ─────────────────────────────────────────────────────
    local total_click = (base_click + click_power_bonus) * prestige_mult()
    lurek.render.print("Click: +" .. fmt(total_click), W / 2 - 40, H / 2 + 50, { size = 14, color = {0.8, 0.8, 0.9, 1} })
    lurek.render.print("[SPACE]", W / 2 - 28, H / 2 + 70, { size = 12, color = {0.5, 0.5, 0.6, 1} })

    -- ── Upgrade panel (right side) ──────────────────────────────────────
    local px, py = 560, 90
    lurek.render.rectangle(px - 10, py - 10, 240, 450, { color = {0.12, 0.1, 0.16, 0.85}, filled = true })
    lurek.render.rectangle(px - 10, py - 10, 240, 450, { color = {0.3, 0.25, 0.4, 0.8}, filled = false })
    lurek.render.print("— PRODUCERS —", px + 30, py, { size = 14, color = {0.7, 0.7, 0.9, 1} })

    for i, p in ipairs(producers) do
        local cost = get_cost(p.base_cost, p.owned)
        local affordable = gold >= cost
        local cy = py + 20 + i * 50
        local name_color = affordable and {0.9, 0.9, 1, 1} or {0.5, 0.5, 0.6, 1}
        local cost_color = affordable and {0.4, 1, 0.4, 1} or {1, 0.4, 0.4, 1}
        local rate_display = p.rate * p.owned * prestige_mult()

        lurek.render.print("[" .. string.upper(p.key) .. "] " .. p.name, px, cy, { size = 13, color = name_color })
        lurek.render.print("Cost: " .. fmt(cost), px + 130, cy, { size = 11, color = cost_color })
        lurek.render.print("x" .. p.owned .. "  +" .. fmt(rate_display) .. "/s", px, cy + 16, { size = 11, color = {0.6, 0.7, 0.6, 1} })
    end

    -- ── Click upgrades ──────────────────────────────────────────────────
    local cuy = py + 300
    lurek.render.print("— CLICK POWER —", px + 25, cuy, { size = 14, color = {0.7, 0.7, 0.9, 1} })

    for i, u in ipairs(click_upgrades) do
        local cost = get_cost(u.base_cost, u.owned)
        local affordable = gold >= cost
        local uy = cuy + 10 + i * 45
        local name_color = affordable and {0.9, 0.9, 1, 1} or {0.5, 0.5, 0.6, 1}
        local cost_color = affordable and {0.4, 1, 0.4, 1} or {1, 0.4, 0.4, 1}

        lurek.render.print("[" .. string.upper(u.key) .. "] " .. u.name, px, uy, { size = 13, color = name_color })
        lurek.render.print("Cost: " .. fmt(cost) .. "  x" .. u.owned, px + 130, uy, { size = 11, color = cost_color })
    end

    -- ── Stats panel (left side) ─────────────────────────────────────────
    local sx, sy = 10, 90
    lurek.render.rectangle(sx, sy - 10, 190, 170, { color = {0.12, 0.1, 0.16, 0.85}, filled = true })
    lurek.render.rectangle(sx, sy - 10, 190, 170, { color = {0.3, 0.25, 0.4, 0.8}, filled = false })
    lurek.render.print("— STATS —", sx + 50, sy, { size = 14, color = {0.7, 0.7, 0.9, 1} })
    lurek.render.print("Total Earned: " .. fmt(total_gold_earned), sx + 10, sy + 25, { size = 12, color = {0.7, 0.7, 0.8, 1} })
    lurek.render.print("Clicks: " .. total_clicks, sx + 10, sy + 45, { size = 12, color = {0.7, 0.7, 0.8, 1} })
    lurek.render.print("Gold/s: " .. fmt(gold_per_second), sx + 10, sy + 65, { size = 12, color = {0.7, 0.7, 0.8, 1} })
    lurek.render.print("Prestige: " .. prestige_level .. " (x" .. fmt(prestige_mult()) .. ")", sx + 10, sy + 85, { size = 12, color = {1, 0.85, 0.2, 1} })

    -- Prestige hint
    if gold >= 1000000 then
        lurek.render.print("[P] PRESTIGE AVAILABLE!", sx + 10, sy + 115, { size = 13, color = {1, 0.5, 1, 1} })
    else
        local pct = math.min(100, gold / 1000000 * 100)
        lurek.render.print("Prestige at 1M (" .. string.format("%.1f%%", pct) .. ")", sx + 10, sy + 115, { size = 11, color = {0.5, 0.4, 0.6, 1} })
    end

    -- ── Achievements (bottom-left) ──────────────────────────────────────
    local ax, ay = 10, 290
    lurek.render.rectangle(ax, ay - 10, 190, 140, { color = {0.12, 0.1, 0.16, 0.85}, filled = true })
    lurek.render.rectangle(ax, ay - 10, 190, 140, { color = {0.3, 0.25, 0.4, 0.8}, filled = false })
    lurek.render.print("— ACHIEVEMENTS —", ax + 30, ay, { size = 14, color = {0.7, 0.7, 0.9, 1} })

    for i, a in ipairs(achievements) do
        local badge_color = a.unlocked and {0.3, 1, 0.4, 1} or {0.35, 0.35, 0.4, 1}
        local icon = a.unlocked and "[*] " or "[ ] "
        lurek.render.print(icon .. a.name, ax + 10, ay + 10 + i * 20, { size = 11, color = badge_color })
    end

    -- ── Achievement popup ───────────────────────────────────────────────
    if achievement_popup then
        local pop_alpha = math.min(1, achievement_popup_timer)
        lurek.render.rectangle(W / 2 - 120, H - 70, 240, 40, { color = {0.15, 0.4, 0.15, pop_alpha * 0.9}, filled = true })
        lurek.render.rectangle(W / 2 - 120, H - 70, 240, 40, { color = {0.3, 1, 0.4, pop_alpha}, filled = false })
        lurek.render.print("Achievement: " .. achievement_popup, W / 2 - 100, H - 58, { size = 14, color = {0.3, 1, 0.4, pop_alpha} })
    end

    -- ── Prestige confirm overlay ────────────────────────────────────────
    if state == STATE_PRESTIGE then
        lurek.render.rectangle(0, 0, W, H, { color = {0, 0, 0, 0.7}, filled = true })
        lurek.render.rectangle(W / 2 - 180, H / 2 - 80, 360, 160, { color = {0.15, 0.1, 0.2, 1}, filled = true })
        lurek.render.rectangle(W / 2 - 180, H / 2 - 80, 360, 160, { color = {1, 0.85, 0.2, 1}, filled = false })
        lurek.render.print("PRESTIGE?", W / 2 - 60, H / 2 - 55, { size = 24, color = {1, 0.85, 0.2, 1} })
        lurek.render.print("Reset all progress for", W / 2 - 90, H / 2 - 15, { size = 14, color = {0.8, 0.8, 0.9, 1} })
        lurek.render.print("permanent 2x production!", W / 2 - 100, H / 2 + 5, { size = 14, color = {0.8, 0.8, 0.9, 1} })
        lurek.render.print("[SPACE] Confirm    [ESC] Cancel", W / 2 - 120, H / 2 + 40, { size = 13, color = {0.6, 0.6, 0.7, 1} })
    end

    -- ── FPS ─────────────────────────────────────────────────────────────
    lurek.render.print("FPS: " .. lurek.timer.getFPS(), 5, 5, { size = 11, color = {0.4, 0.4, 0.5, 0.7} })
end
