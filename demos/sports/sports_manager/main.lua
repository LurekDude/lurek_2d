-- Sports Manager — 2D Data-Driven Football Management
-- Manage roster, tactics, training, transfers, play a 10-match season

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local state = "menu" -- menu, roster, formation, match, match_log, transfer, training, table, season_end
local team_name = "Luna FC"
local budget = 200
local season_match = 1
local TOTAL_MATCHES = 10
local selected = 1
local scroll = 0
local formation = "4-4-2"
local formations = { "4-4-2", "4-3-3", "3-5-2" }
local form_idx = 1
local players = {}
local opponents = {}
local league = {}
local match_log = {}
local match_result = ""
local transfer_list = {}
local menu_items = { "Play Match", "Roster", "Formation", "Training", "Transfers", "League Table" }

local function rand_name()
    local first = {"Alex","Ben","Carlos","Dan","Erik","Fabio","George","Hugo","Ivan","Jake","Kyle","Leo","Max","Niko","Oscar","Pete","Quinn","Rafa","Sam","Tom"}
    local last = {"Silva","Chen","Muller","Park","Roy","Ali","Cruz","Ito","Berg","Diaz","Lam","Voss","Hale","Nash","Cole","Webb","Fox","Reed","Shaw","Dunn"}
    return first[math.random(1, #first)] .. " " .. last[math.random(1, #last)]
end

local function rand_stat() return math.random(30, 85) end

local function make_player()
    return {
        name = rand_name(),
        speed = rand_stat(), power = rand_stat(), stamina = rand_stat(), skill = rand_stat(),
        morale = math.random(60, 100), injured = false, injury_days = 0,
        value = 0,
    }
end

local function calc_value(p)
    return math.floor((p.speed + p.power + p.stamina + p.skill) / 4 * 0.5)
end

local function team_overall(roster)
    local total = 0
    local n = 0
    for _, p in ipairs(roster) do
        if not p.injured then
            total = total + p.speed + p.power + p.stamina + p.skill
            n = n + 1
        end
    end
    return n > 0 and math.floor(total / n) or 30
end

function luna.init()
    for i = 1, 11 do
        local p = make_player()
        p.value = calc_value(p)
        players[i] = p
    end
    -- Generate opponents
    for i = 1, TOTAL_MATCHES do
        local opp = { name = "Team " .. string.char(64 + i), roster = {} }
        for j = 1, 11 do
            opp.roster[j] = make_player()
        end
        opponents[i] = opp
    end
    -- League table
    league = {}
    league[#league + 1] = { name = team_name, w = 0, d = 0, l = 0, gf = 0, ga = 0, pts = 0 }
    for _, opp in ipairs(opponents) do
        league[#league + 1] = { name = opp.name, w = 0, d = 0, l = 0, gf = 0, ga = 0, pts = 0 }
    end
    gen_transfers()
end

function gen_transfers()
    transfer_list = {}
    for i = 1, 5 do
        local p = make_player()
        p.value = calc_value(p)
        transfer_list[i] = p
    end
end

local function simulate_match(opp)
    local my_ovr = team_overall(players)
    local opp_ovr = team_overall(opp.roster)
    local morale_bonus = 0
    for _, p in ipairs(players) do
        morale_bonus = morale_bonus + (p.morale - 50) / 500
    end
    -- Formation bonus
    local form_bonus = 0
    if formation == "4-3-3" then form_bonus = 3  -- attacking
    elseif formation == "3-5-2" then form_bonus = 1 end
    my_ovr = my_ovr + morale_bonus + form_bonus
    local diff = my_ovr - opp_ovr
    local my_goals = clamp(math.floor(math.random(0, 4) + diff / 20), 0, 7)
    local opp_goals = clamp(math.floor(math.random(0, 3) - diff / 25), 0, 7)

    -- Generate play-by-play
    match_log = {}
    match_log[#match_log + 1] = "=== " .. team_name .. " vs " .. opp.name .. " ==="
    match_log[#match_log + 1] = "Formation: " .. formation .. "  |  Team OVR: " .. math.floor(my_ovr) .. " vs " .. math.floor(opp_ovr)
    match_log[#match_log + 1] = ""
    local events = {"attack", "intercept", "shot", "save", "foul", "corner"}
    for minute = 1, 90, math.random(5, 15) do
        local ev = events[math.random(1, #events)]
        local actor = minute % 2 == 0 and players[math.random(1, #players)].name or "Opponent"
        match_log[#match_log + 1] = minute .. "' - " .. actor .. ": " .. ev
    end
    -- Goals
    for i = 1, my_goals do
        local scorer = players[math.random(1, #players)]
        local min = math.random(1, 90)
        match_log[#match_log + 1] = min .. "' GOAL! " .. scorer.name .. " scores for " .. team_name .. "!"
        scorer.morale = clamp(scorer.morale + 5, 0, 100)
    end
    for i = 1, opp_goals do
        local min = math.random(1, 90)
        match_log[#match_log + 1] = min .. "' GOAL! " .. opp.name .. " scores."
    end
    match_log[#match_log + 1] = ""
    match_log[#match_log + 1] = "FULL TIME: " .. team_name .. " " .. my_goals .. " - " .. opp_goals .. " " .. opp.name

    -- Update league
    local my_entry = league[1]
    my_entry.gf = my_entry.gf + my_goals
    my_entry.ga = my_entry.ga + opp_goals
    -- Find opponent entry
    local opp_entry = nil
    for _, e in ipairs(league) do
        if e.name == opp.name then opp_entry = e; break end
    end
    if opp_entry then
        opp_entry.gf = opp_entry.gf + opp_goals
        opp_entry.ga = opp_entry.ga + my_goals
    end
    if my_goals > opp_goals then
        my_entry.w = my_entry.w + 1; my_entry.pts = my_entry.pts + 3
        if opp_entry then opp_entry.l = opp_entry.l + 1 end
        match_result = "WIN!"
    elseif my_goals < opp_goals then
        my_entry.l = my_entry.l + 1
        if opp_entry then opp_entry.w = opp_entry.w + 1; opp_entry.pts = opp_entry.pts + 3 end
        match_result = "LOSS"
        for _, p in ipairs(players) do p.morale = clamp(p.morale - 3, 0, 100) end
    else
        my_entry.d = my_entry.d + 1; my_entry.pts = my_entry.pts + 1
        if opp_entry then opp_entry.d = opp_entry.d + 1; opp_entry.pts = opp_entry.pts + 1 end
        match_result = "DRAW"
    end

    -- Simulate other matches (random results for AI teams)
    for i, opp2 in ipairs(opponents) do
        if i ~= season_match then
            local e2 = nil
            for _, e in ipairs(league) do if e.name == opp2.name then e2 = e; break end end
            if e2 then
                local r = math.random(1, 3)
                if r == 1 then e2.w = e2.w + 1; e2.pts = e2.pts + 3; e2.gf = e2.gf + 2; e2.ga = e2.ga + 1
                elseif r == 2 then e2.d = e2.d + 1; e2.pts = e2.pts + 1; e2.gf = e2.gf + 1; e2.ga = e2.ga + 1
                else e2.l = e2.l + 1; e2.gf = e2.gf + 0; e2.ga = e2.ga + 2 end
            end
        end
    end

    -- Injury chance
    for _, p in ipairs(players) do
        if math.random() < 0.1 then
            p.injured = true
            p.injury_days = math.random(1, 3)
            match_log[#match_log + 1] = "INJURY: " .. p.name .. " out for " .. p.injury_days .. " match(es)"
        end
    end
end

function luna.keypressed(key)
    if key == "escape" then
        if state == "menu" then luna.signal.quit()
        else state = "menu"; selected = 1; scroll = 0 end
        return
    end

    if state == "menu" then
        if key == "up" then selected = selected - 1; if selected < 1 then selected = #menu_items end
        elseif key == "down" then selected = selected + 1; if selected > #menu_items then selected = 1 end
        elseif key == "return" then
            local item = menu_items[selected]
            if item == "Play Match" then
                if season_match <= TOTAL_MATCHES then
                    simulate_match(opponents[season_match])
                    season_match = season_match + 1
                    -- Heal injuries
                    for _, p in ipairs(players) do
                        if p.injured then
                            p.injury_days = p.injury_days - 1
                            if p.injury_days <= 0 then p.injured = false end
                        end
                    end
                    state = "match_log"
                    scroll = 0
                    if season_match > TOTAL_MATCHES then
                        state = "season_end"
                    end
                end
            elseif item == "Roster" then state = "roster"; selected = 1
            elseif item == "Formation" then state = "formation"
            elseif item == "Training" then state = "training"; selected = 1
            elseif item == "Transfers" then state = "transfer"; selected = 1
            elseif item == "League Table" then state = "table"
            end
        end
    elseif state == "roster" then
        if key == "up" then selected = selected - 1; if selected < 1 then selected = #players end
        elseif key == "down" then selected = selected + 1; if selected > #players then selected = 1 end
        end
    elseif state == "formation" then
        if key == "left" or key == "up" then form_idx = form_idx - 1; if form_idx < 1 then form_idx = #formations end
        elseif key == "right" or key == "down" then form_idx = form_idx + 1; if form_idx > #formations then form_idx = 1 end
        elseif key == "return" then formation = formations[form_idx]; state = "menu"; selected = 1 end
    elseif state == "training" then
        if key == "up" then selected = selected - 1; if selected < 1 then selected = #players end
        elseif key == "down" then selected = selected + 1; if selected > #players then selected = 1 end
        elseif key == "return" then
            local p = players[selected]
            if not p.injured and budget >= 10 then
                budget = budget - 10
                local stat = math.random(1, 4)
                if stat == 1 then p.speed = clamp(p.speed + math.random(1, 5), 0, 99)
                elseif stat == 2 then p.power = clamp(p.power + math.random(1, 5), 0, 99)
                elseif stat == 3 then p.stamina = clamp(p.stamina + math.random(1, 5), 0, 99)
                else p.skill = clamp(p.skill + math.random(1, 5), 0, 99) end
                p.morale = clamp(p.morale + 3, 0, 100)
                p.value = calc_value(p)
            end
        end
    elseif state == "transfer" then
        if key == "up" then selected = selected - 1; if selected < 1 then selected = #transfer_list end
        elseif key == "down" then selected = selected + 1; if selected > #transfer_list then selected = 1 end
        elseif key == "return" and #transfer_list > 0 then
            local p = transfer_list[selected]
            if budget >= p.value then
                budget = budget - p.value
                players[#players + 1] = p
                table.remove(transfer_list, selected)
                if selected > #transfer_list then selected = clamp(#transfer_list, 1, 99) end
            end
        elseif key == "s" and #players > 11 then
            -- Sell last player
            local sold = table.remove(players)
            budget = budget + sold.value
        end
    elseif state == "match_log" then
        if key == "up" then scroll = clamp(scroll - 1, 0, #match_log)
        elseif key == "down" then scroll = clamp(scroll + 1, 0, clamp(#match_log - 20, 0, 999))
        elseif key == "return" then state = "menu"; selected = 1 end
    elseif state == "season_end" or state == "table" then
        if key == "return" then state = "menu"; selected = 1 end
    end
end

function luna.render()
    luna.gfx.setBackgroundColor(0.06, 0.08, 0.12)

    -- Header
    luna.gfx.setColor(0.3, 0.8, 0.4, 1)
    luna.gfx.print(team_name .. " — Sports Manager", 10, 5, 1.2)
    luna.gfx.setColor(0.8, 0.8, 0.6, 1)
    luna.gfx.print("Budget: " .. budget .. "  |  Match " .. clamp(season_match, 1, TOTAL_MATCHES) .. "/" .. TOTAL_MATCHES .. "  |  Formation: " .. formation, 10, 28, 0.75)

    local Y = 55

    if state == "menu" then
        luna.gfx.setColor(1, 0.9, 0.5, 1)
        luna.gfx.print("Main Menu", 30, Y, 1.2)
        for i, item in ipairs(menu_items) do
            local iy = Y + 30 + (i - 1) * 28
            if i == selected then
                luna.gfx.setColor(0.2, 0.3, 0.5, 1)
                luna.gfx.rectangle("fill", 25, iy - 2, 300, 24)
                luna.gfx.setColor(1, 1, 0.6, 1)
            else
                luna.gfx.setColor(0.8, 0.8, 0.8, 1)
            end
            luna.gfx.print("> " .. item, 35, iy, 1)
        end
        luna.gfx.setColor(0.5, 0.5, 0.5, 1)
        luna.gfx.print("Up/Down=select  Enter=confirm  Esc=back/quit", 30, 400, 0.7)

    elseif state == "roster" then
        luna.gfx.setColor(1, 0.9, 0.5, 1)
        luna.gfx.print("Roster  (OVR: " .. team_overall(players) .. ")", 30, Y, 1)
        luna.gfx.setColor(0.6, 0.6, 0.6, 1)
        luna.gfx.print("#   Name               SPD  PWR  STA  SKL  MOR  Status", 30, Y + 25, 0.65)
        for i, p in ipairs(players) do
            local py = Y + 42 + (i - 1) * 20
            if i == selected then
                luna.gfx.setColor(0.2, 0.3, 0.5, 1)
                luna.gfx.rectangle("fill", 25, py - 1, 720, 18)
            end
            local status = p.injured and "INJURED" or "OK"
            local clr = p.injured and {0.9, 0.3, 0.3} or {0.8, 0.9, 0.8}
            luna.gfx.setColor(clr[1], clr[2], clr[3], 1)
            local line = string.format("%-3d %-18s %3d  %3d  %3d  %3d  %3d  %s", i, p.name, p.speed, p.power, p.stamina, p.skill, p.morale, status)
            luna.gfx.print(line, 30, py, 0.6)
        end

    elseif state == "formation" then
        luna.gfx.setColor(1, 0.9, 0.5, 1)
        luna.gfx.print("Select Formation", 30, Y, 1.2)
        for i, f in ipairs(formations) do
            local fy = Y + 40 + (i - 1) * 35
            if i == form_idx then
                luna.gfx.setColor(0.2, 0.4, 0.6, 1)
                luna.gfx.rectangle("fill", 30, fy - 2, 200, 28)
                luna.gfx.setColor(1, 1, 0.6, 1)
            else
                luna.gfx.setColor(0.7, 0.7, 0.7, 1)
            end
            luna.gfx.print(f, 40, fy, 1.2)
        end
        luna.gfx.setColor(0.5, 0.5, 0.5, 1)
        luna.gfx.print("Up/Down=select  Enter=confirm", 30, 250, 0.75)

    elseif state == "training" then
        luna.gfx.setColor(1, 0.9, 0.5, 1)
        luna.gfx.print("Training (10 budget per session)", 30, Y, 1)
        for i, p in ipairs(players) do
            local py = Y + 30 + (i - 1) * 20
            if i == selected then
                luna.gfx.setColor(0.2, 0.3, 0.5, 1)
                luna.gfx.rectangle("fill", 25, py - 1, 500, 18)
                luna.gfx.setColor(1, 1, 0.6, 1)
            else
                luna.gfx.setColor(0.7, 0.8, 0.7, 1)
            end
            luna.gfx.print(string.format("%-18s SPD:%d PWR:%d STA:%d SKL:%d", p.name, p.speed, p.power, p.stamina, p.skill), 30, py, 0.65)
        end
        luna.gfx.setColor(0.5, 0.5, 0.5, 1)
        luna.gfx.print("Enter=train selected player (random stat +1-5)", 30, 400, 0.7)

    elseif state == "transfer" then
        luna.gfx.setColor(1, 0.9, 0.5, 1)
        luna.gfx.print("Transfer Market", 30, Y, 1)
        if #transfer_list == 0 then
            luna.gfx.setColor(0.7, 0.7, 0.7, 1)
            luna.gfx.print("No players available.", 30, Y + 30, 0.9)
        end
        for i, p in ipairs(transfer_list) do
            local py = Y + 30 + (i - 1) * 22
            if i == selected then
                luna.gfx.setColor(0.2, 0.3, 0.5, 1)
                luna.gfx.rectangle("fill", 25, py - 1, 600, 20)
                luna.gfx.setColor(1, 1, 0.6, 1)
            else
                luna.gfx.setColor(0.7, 0.7, 0.8, 1)
            end
            luna.gfx.print(string.format("%-18s SPD:%d PWR:%d STA:%d SKL:%d  Cost:%d", p.name, p.speed, p.power, p.stamina, p.skill, p.value), 30, py, 0.65)
        end
        luna.gfx.setColor(0.5, 0.5, 0.5, 1)
        luna.gfx.print("Enter=buy  S=sell last player  Esc=back", 30, 400, 0.7)

    elseif state == "match_log" then
        luna.gfx.setColor(1, 0.9, 0.5, 1)
        luna.gfx.print("Match Result: " .. match_result, 30, Y, 1.2)
        local max_lines = 20
        for i = 1, max_lines do
            local idx = i + scroll
            if idx <= #match_log then
                luna.gfx.setColor(0.8, 0.85, 0.9, 1)
                luna.gfx.print(match_log[idx], 30, Y + 25 + (i - 1) * 18, 0.65)
            end
        end
        luna.gfx.setColor(0.5, 0.5, 0.5, 1)
        luna.gfx.print("Up/Down=scroll  Enter=continue", 30, 430, 0.7)

    elseif state == "table" then
        luna.gfx.setColor(1, 0.9, 0.5, 1)
        luna.gfx.print("League Table", 30, Y, 1.2)
        -- Sort by points
        table.sort(league, function(a, b) return a.pts > b.pts end)
        luna.gfx.setColor(0.6, 0.6, 0.6, 1)
        luna.gfx.print("#   Team               W   D   L   GF  GA  PTS", 30, Y + 30, 0.7)
        for i, e in ipairs(league) do
            local ey = Y + 50 + (i - 1) * 22
            if e.name == team_name then luna.gfx.setColor(0.4, 1, 0.5, 1)
            else luna.gfx.setColor(0.8, 0.8, 0.8, 1) end
            luna.gfx.print(string.format("%-3d %-18s %2d  %2d  %2d  %2d  %2d  %3d", i, e.name, e.w, e.d, e.l, e.gf, e.ga, e.pts), 30, ey, 0.65)
        end
        luna.gfx.setColor(0.5, 0.5, 0.5, 1)
        luna.gfx.print("Enter=back", 30, 400, 0.7)

    elseif state == "season_end" then
        table.sort(league, function(a, b) return a.pts > b.pts end)
        luna.gfx.setColor(1, 0.85, 0.3, 1)
        luna.gfx.print("Season Complete!", 200, 100, 2)
        local pos = 1
        for i, e in ipairs(league) do
            if e.name == team_name then pos = i; break end
        end
        luna.gfx.setColor(0.9, 0.9, 0.9, 1)
        luna.gfx.print(team_name .. " finished in position #" .. pos, 180, 200, 1.2)
        luna.gfx.print("W:" .. league[1].w .. " D:" .. league[1].d .. " L:" .. league[1].l, 250, 240, 1)
        luna.gfx.setColor(0.5, 1, 0.5, 1)
        luna.gfx.print("Press ENTER", 300, 340, 1)
    end

    luna.gfx.setColor(0.4, 0.4, 0.4, 1)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), 730, 5, 0.6)
end
