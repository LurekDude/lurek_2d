-- Social Deduction — Among Us style with AI players
-- Complete tasks or vote out the traitor to win
-- Run with: cargo run -- content/demos/rpg/social_deduction

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600
local TASK_COUNT = 8
local VISION_RADIUS = 180

local phase       -- "task" or "meeting"
local phase_timer
local progress
local players
local traitor_id
local player_id = 1
local meeting_votes
local meeting_timer
local eliminated
local game_over, game_result
local tasks
local sabotage_cooldown
local message, msg_timer

local COLORS = {
    {0.3, 0.5, 1.0}, {1.0, 0.3, 0.3}, {0.3, 1.0, 0.4},
    {1.0, 0.9, 0.2}, {0.9, 0.4, 0.9}, {1.0, 0.6, 0.2},
}
local NAMES = { "You", "Red", "Lime", "Gold", "Pink", "Orange" }

local function dist(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function init_game()
    phase = "task"
    phase_timer = 0
    progress = 0
    game_over = false
    game_result = ""
    eliminated = {}
    meeting_votes = {}
    meeting_timer = 0
    sabotage_cooldown = 0
    message = nil
    msg_timer = 0

    players = {}
    for i = 1, 6 do
        players[i] = {
            x = 100 + math.random(0, 600),
            y = 100 + math.random(0, 400),
            alive = true, speed = 80,
            target_x = 0, target_y = 0, move_timer = 0,
            doing_task = false, task_timer = 0,
        }
    end

    traitor_id = math.random(1, 6)

    tasks = {}
    for i = 1, TASK_COUNT do
        tasks[i] = {
            x = 60 + math.random(0, 680),
            y = 60 + math.random(0, 480),
            done = false, active = false, timer = 0,
        }
    end
end

function lurek.init()
    lurek.window.setTitle("Social Deduction")
    lurek.render.setBackgroundColor(0.08, 0.08, 0.12)
    init_game()
end

local function alive_count()
    local n = 0
    for i = 1, 6 do if players[i].alive then n = n + 1 end end
    return n
end

local function set_msg(text)
    message = text
    msg_timer = 3
end

local function call_meeting()
    phase = "meeting"
    meeting_timer = 10
    meeting_votes = {}
    for i = 1, 6 do
        if players[i].alive and i ~= player_id then
            -- AI vote: traitor votes randomly, others have small chance to guess right
            local vote
            if i == traitor_id then
                repeat vote = math.random(1, 6) until vote ~= i and players[vote].alive
            else
                if math.random() < 0.25 then
                    vote = traitor_id
                else
                    repeat vote = math.random(1, 6) until vote ~= i and players[vote].alive
                end
            end
            meeting_votes[i] = vote
        end
    end
end

local function update_ai(p, i, dt)
    if not p.alive or i == player_id then return end

    p.move_timer = p.move_timer - dt
    if p.move_timer <= 0 then
        p.target_x = 60 + math.random(0, 680)
        p.target_y = 60 + math.random(0, 480)
        p.move_timer = 1.5 + math.random() * 3
    end

    local dx = p.target_x - p.x
    local dy = p.target_y - p.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d > 3 then
        p.x = p.x + (dx / d) * p.speed * dt
        p.y = p.y + (dy / d) * p.speed * dt
    end

    -- AI doing tasks (non-traitor)
    if i ~= traitor_id then
        for _, t in ipairs(tasks) do
            if not t.done and dist(p, t) < 30 then
                t.timer = t.timer + dt
                if t.timer > 2 then
                    t.done = true
                    progress = progress + 1
                end
            end
        end
    end

    p.x = clamp(p.x, 10, W - 10)
    p.y = clamp(p.y, 10, H - 10)
end

function lurek.process(dt)
    if game_over then return end
    msg_timer = msg_timer - dt
    if msg_timer < 0 then message = nil end
    sabotage_cooldown = clamp(sabotage_cooldown - dt, 0, 99)

    if phase == "task" then
        local me = players[player_id]
        if me.alive then
            local spd = 120
            if lurek.keyboard.isDown("w") or lurek.keyboard.isDown("up") then me.y = me.y - spd * dt end
            if lurek.keyboard.isDown("s") or lurek.keyboard.isDown("down") then me.y = me.y + spd * dt end
            if lurek.keyboard.isDown("a") or lurek.keyboard.isDown("left") then me.x = me.x - spd * dt end
            if lurek.keyboard.isDown("d") or lurek.keyboard.isDown("right") then me.x = me.x + spd * dt end
            me.x = clamp(me.x, 10, W - 10)
            me.y = clamp(me.y, 10, H - 10)
        end

        for i = 2, 6 do update_ai(players[i], i, dt) end

        -- check player near task
        if me.alive then
            for _, t in ipairs(tasks) do
                if not t.done and dist(me, t) < 35 then
                    t.active = true
                end
            end
        end

        -- progress check
        if progress >= TASK_COUNT then
            game_over = true
            game_result = "CREW WINS — All tasks complete!"
        end

        phase_timer = phase_timer + dt
        if phase_timer > 30 then
            call_meeting()
        end

    elseif phase == "meeting" then
        meeting_timer = meeting_timer - dt
        if meeting_timer <= 0 then
            -- tally votes
            local tally = {}
            for i = 1, 6 do tally[i] = 0 end
            for _, v in pairs(meeting_votes) do
                tally[v] = tally[v] + 1
            end
            local best, best_count = 0, 0
            for i = 1, 6 do
                if tally[i] > best_count then best = i; best_count = tally[i] end
            end
            if best > 0 and best_count >= 2 then
                players[best].alive = false
                eliminated[#eliminated + 1] = best
                if best == traitor_id then
                    game_over = true
                    game_result = "CREW WINS — Traitor voted out!"
                    return
                end
                set_msg(NAMES[best] .. " was eliminated. They were NOT the traitor.")
            else
                set_msg("No consensus — nobody eliminated.")
            end
            if alive_count() <= 2 then
                game_over = true
                game_result = "TRAITOR WINS — Too few crew remain!"
                return
            end
            phase = "task"
            phase_timer = 0
        end
    end
end

local function draw_task_phase()
    local me = players[player_id]
    -- tasks
    for _, t in ipairs(tasks) do
        if not t.done then
            local visible = dist(me, t) < VISION_RADIUS
            if visible then
                lurek.render.setColor(1, 1, 0.3, 0.8)
                lurek.render.rectangle("fill", t.x - 10, t.y - 10, 20, 20)
                lurek.render.setColor(0, 0, 0, 1)
                lurek.render.print("!", t.x - 3, t.y - 8, 1)
            end
        else
            lurek.render.setColor(0.2, 0.5, 0.2, 0.5)
            lurek.render.rectangle("line", t.x - 10, t.y - 10, 20, 20)
        end
    end

    -- players
    for i = 1, 6 do
        local p = players[i]
        if p.alive then
            local visible = (i == player_id) or (dist(me, p) < VISION_RADIUS)
            if visible then
                local c = COLORS[i]
                lurek.render.setColor(c[1], c[2], c[3], 1)
                lurek.render.circle("fill", p.x, p.y, 14)
                lurek.render.setColor(1, 1, 1, 0.9)
                lurek.render.print(NAMES[i], p.x - 10, p.y - 28, 0.7)
            end
        end
    end

    -- vision circle
    lurek.render.setColor(1, 1, 1, 0.08)
    lurek.render.circle("line", me.x, me.y, VISION_RADIUS)

    -- HUD
    lurek.render.setColor(0.2, 0.2, 0.3, 0.8)
    lurek.render.rectangle("fill", 0, 0, W, 36)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Tasks: " .. progress .. "/" .. TASK_COUNT, 10, 8, 1)
    -- progress bar
    lurek.render.setColor(0.3, 0.3, 0.3, 1)
    lurek.render.rectangle("fill", 200, 10, 200, 16)
    lurek.render.setColor(0.2, 0.9, 0.3, 1)
    lurek.render.rectangle("fill", 200, 10, 200 * (progress / TASK_COUNT), 16)

    lurek.render.setColor(1, 1, 1, 1)
    local role = (player_id == traitor_id) and "TRAITOR" or "CREW"
    lurek.render.print("Role: " .. role, 500, 8, 1)
    lurek.render.print("M=Meeting  WASD=Move", 10, H - 22, 0.8)
    if player_id == traitor_id then
        lurek.render.setColor(1, 0.3, 0.3, 1)
        lurek.render.print("S=Sabotage", 680, 8, 1)
    end
end

local function draw_meeting()
    lurek.render.setColor(0.15, 0.15, 0.25, 1)
    lurek.render.rectangle("fill", 50, 50, W - 100, H - 100)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("EMERGENCY MEETING", W / 2 - 90, 70, 1.5)
    lurek.render.print("Time: " .. math.floor(meeting_timer), W / 2 - 20, 100, 1)
    lurek.render.print("Click a name to vote", W / 2 - 65, 120, 0.9)

    local y = 160
    for i = 1, 6 do
        local p = players[i]
        local c = COLORS[i]
        if p.alive then
            lurek.render.setColor(c[1], c[2], c[3], 1)
            lurek.render.circle("fill", 120, y + 10, 12)
            lurek.render.setColor(1, 1, 1, 1)
            lurek.render.print(NAMES[i], 145, y, 1.2)
            if meeting_votes[player_id] == i then
                lurek.render.setColor(1, 1, 0, 1)
                lurek.render.print(" <-- YOUR VOTE", 260, y, 1)
            end
        else
            lurek.render.setColor(0.4, 0.4, 0.4, 1)
            lurek.render.print(NAMES[i] .. " (eliminated)", 145, y, 1)
        end
        y = y + 45
    end
end

function lurek.render()
    if game_over then
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print(game_result, W / 2 - 140, H / 2 - 20, 1.3)
        lurek.render.print("Press R to restart", W / 2 - 60, H / 2 + 20, 1)
        return
    end
    if phase == "task" then
        draw_task_phase()
    else
        draw_meeting()
    end
    if message and msg_timer > 0 then
        lurek.render.setColor(1, 1, 0.5, clamp(msg_timer, 0, 1))
        lurek.render.print(message, W / 2 - 120, H / 2, 1)
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" and game_over then init_game(); return end
    if game_over then return end

    if phase == "task" and key == "m" then
        call_meeting()
    end
    if phase == "task" and key == "s" and player_id == traitor_id and sabotage_cooldown <= 0 then
        -- sabotage: undo a completed task
        for i = #tasks, 1, -1 do
            if tasks[i].done then
                tasks[i].done = false
                progress = progress - 1
                sabotage_cooldown = 10
                set_msg("You sabotaged a system!")
                break
            end
        end
    end
end

function lurek.mousepressed(mx, my, button)
    if game_over then return end
    if phase == "task" then
        -- click on task to complete it
        local me = players[player_id]
        for _, t in ipairs(tasks) do
            if not t.done and math.abs(me.x - t.x) < 35 and math.abs(me.y - t.y) < 35 then
                if player_id ~= traitor_id then
                    t.done = true
                    progress = progress + 1
                    set_msg("Task complete!")
                else
                    set_msg("Traitors can't do real tasks!")
                end
                break
            end
        end
    elseif phase == "meeting" then
        -- click player name to vote
        local y = 160
        for i = 1, 6 do
            if players[i].alive and i ~= player_id then
                if mx > 100 and mx < 400 and my > y - 10 and my < y + 30 then
                    meeting_votes[player_id] = i
                end
            end
            y = y + 45
        end
    end
end
