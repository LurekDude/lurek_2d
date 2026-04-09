-- Idle Game: Incremental clicker with generators, upgrades, and prestige
-- Click to earn, buy generators, prestige for multipliers
-- Run with: cargo run -- demos/simulation/idle_game

local SCREEN_W, SCREEN_H = 800, 600

local coins = 0
local total_earned = 0
local total_clicked = 0
local prestige_mult = 1
local prestige_count = 0
local click_power = 1

local generators = {
    { name = "Cursor",  base_cost = 15,   cps = 0.1,  count = 0, cost = 15 },
    { name = "Worker",  base_cost = 100,  cps = 1,    count = 0, cost = 100 },
    { name = "Factory", base_cost = 500,  cps = 8,    count = 0, cost = 500 },
    { name = "Mine",    base_cost = 3000, cps = 47,   count = 0, cost = 3000 },
    { name = "Lab",     base_cost = 15000, cps = 260, count = 0, cost = 15000 },
}

local upgrades = {
    { name = "Double Click", cost = 50,  bought = false, desc = "Click = 2x", apply = function() click_power = click_power * 2 end },
    { name = "Cursor x2",   cost = 200, bought = false, desc = "Cursor 2x",  apply = function() generators[1].cps = generators[1].cps * 2 end },
    { name = "Worker x2",   cost = 1000, bought = false, desc = "Worker 2x", apply = function() generators[2].cps = generators[2].cps * 2 end },
    { name = "Super Click", cost = 5000, bought = false, desc = "Click = 5x", apply = function() click_power = click_power * 5 end },
    { name = "Factory x2",  cost = 10000, bought = false, desc = "Factory 2x", apply = function() generators[3].cps = generators[3].cps * 2 end },
}

local big_button = { x = 60, y = 120, w = 200, h = 200 }
local click_particles = {}
local pulse = 0

local function format_num(n)
    if n < 1000 then
        return tostring(math.floor(n * 10) / 10)
    elseif n < 1000000 then
        return tostring(math.floor(n / 100) / 10) .. "K"
    elseif n < 1000000000 then
        return tostring(math.floor(n / 100000) / 10) .. "M"
    else
        return tostring(math.floor(n / 100000000) / 10) .. "B"
    end
end

local function get_cps()
    local cps = 0
    for _, g in ipairs(generators) do
        cps = cps + g.cps * g.count
    end
    return cps * prestige_mult
end

function luna.init() end

function luna.process(dt)
    -- Auto-generation
    local earned = get_cps() * dt
    coins = coins + earned
    total_earned = total_earned + earned

    -- Particle update
    pulse = pulse + dt * 3
    local new_parts = {}
    for _, p in ipairs(click_particles) do
        p.y = p.y - 40 * dt
        p.life = p.life - dt
        if p.life > 0 then new_parts[#new_parts + 1] = p end
    end
    click_particles = new_parts
end

function luna.mousepressed(mx, my, button)
    if button == 1 then
        -- Big button click
        if mx >= big_button.x and mx <= big_button.x + big_button.w and
           my >= big_button.y and my <= big_button.y + big_button.h then
            local earned = click_power * prestige_mult
            coins = coins + earned
            total_earned = total_earned + earned
            total_clicked = total_clicked + 1
            click_particles[#click_particles + 1] = {
                x = mx, y = my, text = "+" .. format_num(earned), life = 1.0
            }
        end

        -- Generator buttons
        for i, g in ipairs(generators) do
            local by = 120 + (i - 1) * 52
            if mx >= 320 and mx <= 560 and my >= by and my <= by + 44 then
                if coins >= g.cost then
                    coins = coins - g.cost
                    g.count = g.count + 1
                    -- Exponential cost curve: each purchase raises price by ~15%
                    -- Classic idle game scaling that ensures progression stays interesting
                    g.cost = math.floor(g.base_cost * (1.15 ^ g.count))
                end
            end
        end

        -- Upgrade buttons
        for i, u in ipairs(upgrades) do
            local by = 120 + (i - 1) * 42
            if mx >= 590 and mx <= 790 and my >= by and my <= by + 34 then
                if not u.bought and coins >= u.cost then
                    coins = coins - u.cost
                    u.bought = true
                    u.apply()
                end
            end
        end

        -- Prestige button
        if mx >= 60 and mx <= 260 and my >= 500 and my <= 540 then
            if total_earned >= 10000 then
                prestige_count = prestige_count + 1
                -- Prestige multiplier doubles with each reset: 2^n means run 1=2×, run 2=4×, etc.
                prestige_mult = 2 ^ prestige_count
                coins = 0
                total_earned = 0
                total_clicked = 0
                click_power = 1
                for _, g in ipairs(generators) do
                    g.count = 0
                    g.cost = g.base_cost
                end
                for _, u in ipairs(upgrades) do
                    u.bought = false
                end
            end
        end
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
end

function luna.render()
    luna.gfx.setBackgroundColor(0.1, 0.08, 0.15)

    -- Coins display
    luna.gfx.setColor(1, 0.85, 0.1, 1)
    luna.gfx.print(format_num(coins) .. " coins", 60, 20, 2.5)
    luna.gfx.setColor(0.7, 0.7, 0.7, 1)
    luna.gfx.print(format_num(get_cps()) .. " per second", 60, 65)
    luna.gfx.print("Click power: " .. format_num(click_power * prestige_mult), 60, 85)

    -- Big button
    local s = 1.0 + math.sin(pulse) * 0.03
    local bx = big_button.x + big_button.w / 2
    local by = big_button.y + big_button.h / 2
    local hw = big_button.w / 2 * s
    local hh = big_button.h / 2 * s
    luna.gfx.setColor(0.9, 0.7, 0.1, 1)
    luna.gfx.circle("fill", bx, by, hw)
    luna.gfx.setColor(1, 0.85, 0.2, 1)
    luna.gfx.circle("fill", bx, by, hw - 6)
    luna.gfx.setColor(0.3, 0.2, 0, 1)
    luna.gfx.print("CLICK", bx - 30, by - 10, 1.5)

    -- Click particles
    for _, p in ipairs(click_particles) do
        luna.gfx.setColor(1, 1, 0.3, p.life)
        luna.gfx.print(p.text, p.x, p.y, 1.2)
    end

    -- Generator panel
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("GENERATORS", 350, 95, 1.2)
    for i, g in ipairs(generators) do
        local by = 120 + (i - 1) * 52
        local affordable = coins >= g.cost
        if affordable then
            luna.gfx.setColor(0.15, 0.3, 0.15, 1)
        else
            luna.gfx.setColor(0.2, 0.15, 0.15, 1)
        end
        luna.gfx.rectangle("fill", 320, by, 240, 44)
        luna.gfx.setColor(0.4, 0.4, 0.4, 1)
        luna.gfx.rectangle("line", 320, by, 240, 44)
        luna.gfx.setColor(1, 1, 1, affordable and 1 or 0.4)
        luna.gfx.print(g.name .. " (" .. g.count .. ")", 328, by + 4)
        luna.gfx.setColor(0.7, 0.7, 0.5, 1)
        luna.gfx.print("Cost: " .. format_num(g.cost) .. "  +" .. format_num(g.cps * prestige_mult) .. "/s", 328, by + 22)
    end

    -- Upgrades panel
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("UPGRADES", 640, 95, 1.2)
    for i, u in ipairs(upgrades) do
        local by = 120 + (i - 1) * 42
        if u.bought then
            luna.gfx.setColor(0.15, 0.15, 0.25, 1)
        elseif coins >= u.cost then
            luna.gfx.setColor(0.15, 0.25, 0.35, 1)
        else
            luna.gfx.setColor(0.15, 0.12, 0.12, 1)
        end
        luna.gfx.rectangle("fill", 590, by, 200, 34)
        luna.gfx.setColor(0.4, 0.4, 0.4, 1)
        luna.gfx.rectangle("line", 590, by, 200, 34)
        if u.bought then
            luna.gfx.setColor(0.4, 0.7, 0.4, 1)
            luna.gfx.print(u.name .. " [OWNED]", 598, by + 4)
        else
            luna.gfx.setColor(1, 1, 1, coins >= u.cost and 1 or 0.4)
            luna.gfx.print(u.name .. " - " .. format_num(u.cost), 598, by + 4)
        end
        luna.gfx.setColor(0.6, 0.6, 0.6, 1)
        luna.gfx.print(u.desc, 598, by + 18)
    end

    -- Prestige button
    luna.gfx.setColor(0.5, 0.2, 0.6, total_earned >= 10000 and 1 or 0.3)
    luna.gfx.rectangle("fill", 60, 500, 200, 40)
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("PRESTIGE (10K req)", 75, 508)

    -- Stats
    luna.gfx.setColor(0.6, 0.6, 0.6, 1)
    luna.gfx.print("Total earned: " .. format_num(total_earned), 60, 400)
    luna.gfx.print("Total clicks: " .. total_clicked, 60, 418)
    luna.gfx.print("Prestige: x" .. prestige_mult .. " (" .. prestige_count .. ")", 60, 436)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), 60, 460)
end
