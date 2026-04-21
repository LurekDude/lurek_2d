-- Social Deduction — Among Us-style social deduction game
-- Category: rpg

-- ── Constants ──────────────────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 800, 600
local PLAYER_SPEED = 140
local VISION_RADIUS = 180
local TASK_HOLD_TIME = 2.0
local TASK_COUNT = 8
local PLAYER_COUNT = 6
local PLAYER_RADIUS = 12
local TASK_RADIUS = 14
local KILL_RANGE = 40
local SABOTAGE_VISION = 80
local SABOTAGE_DURATION = 8.0

-- ── States ─────────────────────────────────────────────────────────────────
local STATE_TITLE = "TITLE"
local STATE_TASK_PHASE = "TASK_PHASE"
local STATE_MEETING = "MEETING"
local STATE_VOTING = "VOTING"
local STATE_RESULT = "RESULT"
local STATE_GAME_OVER = "GAME_OVER"

-- ── Ship map rooms (center x, y, w, h, name) ──────────────────────────────
local rooms = {
    { x = 200, y = 150, w = 160, h = 120, name = "Bridge" },
    { x = 500, y = 150, w = 140, h = 120, name = "Shields" },
    { x = 100, y = 350, w = 140, h = 120, name = "Engine" },
    { x = 350, y = 350, w = 140, h = 100, name = "Medbay" },
    { x = 600, y = 350, w = 140, h = 120, name = "Reactor" },
    { x = 350, y = 520, w = 160, h = 100, name = "Cafeteria" },
}

-- ── Task locations ─────────────────────────────────────────────────────────
local task_positions = {
    { x = 180, y = 130, room = "Bridge",    label = "Calibrate nav" },
    { x = 240, y = 180, room = "Bridge",    label = "Swipe card" },
    { x = 490, y = 140, room = "Shields",   label = "Prime shields" },
    { x = 90,  y = 340, room = "Engine",    label = "Fuel engine" },
    { x = 130, y = 400, room = "Engine",    label = "Align output" },
    { x = 340, y = 340, room = "Medbay",    label = "Scan sample" },
    { x = 610, y = 370, room = "Reactor",   label = "Start reactor" },
    { x = 370, y = 540, room = "Cafeteria", label = "Empty garbage" },
}

-- ── Player colors ──────────────────────────────────────────────────────────
local player_colors = {
    { 0.2, 0.6, 1.0 },   -- blue (player)
    { 1.0, 0.3, 0.3 },   -- red
    { 0.3, 1.0, 0.3 },   -- green
    { 1.0, 1.0, 0.3 },   -- yellow
    { 1.0, 0.5, 0.0 },   -- orange
    { 0.8, 0.3, 1.0 },   -- purple
}

local player_names = { "You", "Red", "Green", "Yellow", "Orange", "Purple" }

-- ── Game state ─────────────────────────────────────────────────────────────
local state = STATE_TITLE
local players = {}
local tasks = {}
local tasks_completed = 0
local traitor_index = 1
local is_player_traitor = false
local current_task_progress = 0
local current_task_index = nil
local meeting_caller = nil
local votes = {}
local vote_result = nil
local vote_timer = 0
local sabotage_active = false
local sabotage_timer = 0
local sabotage_cooldown = 0
local game_message = ""
local game_winner = ""
local dt = 0
local frame_count = 0
local vision_pulse = 0
local title_alpha = 0
local result_timer = 0

-- ── Input bindings ─────────────────────────────────────────────────────────
lurek.input.bind("up", "w")
lurek.input.bind("down", "s")
lurek.input.bind("left", "a")
lurek.input.bind("right", "d")
lurek.input.bind("interact", "e")
lurek.input.bind("meeting", "m")
lurek.input.bind("vote1", "1")
lurek.input.bind("vote2", "2")
lurek.input.bind("vote3", "3")
lurek.input.bind("vote4", "4")
lurek.input.bind("vote5", "5")
lurek.input.bind("vote6", "6")
lurek.input.bind("quit", "escape")

-- ── Helpers ────────────────────────────────────────────────────────────────
local function dist(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function alive_count()
    local n = 0
    for i = 1, PLAYER_COUNT do
        if players[i].alive then n = n + 1 end
    end
    return n
end

local function alive_crew_count()
    local n = 0
    for i = 1, PLAYER_COUNT do
        if players[i].alive and i ~= traitor_index then n = n + 1 end
    end
    return n
end

local function spawn_particles(x, y, r, g, b, count)
    for _ = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 30 + math.random() * 60
        lurek.particle.emit(x, y, math.cos(angle) * speed, math.sin(angle) * speed, r, g, b, 1.0, 0.6 + math.random() * 0.4)
    end
end

-- ── Initialization ─────────────────────────────────────────────────────────
local function init_game()
    math.randomseed(os.time())

    -- assign traitor
    traitor_index = math.random(1, PLAYER_COUNT)
    is_player_traitor = (traitor_index == 1)

    -- create players
    players = {}
    local spawn_positions = {
        { x = 350, y = 540 }, { x = 380, y = 540 }, { x = 320, y = 560 },
        { x = 400, y = 560 }, { x = 340, y = 520 }, { x = 390, y = 520 },
    }
    for i = 1, PLAYER_COUNT do
        players[i] = {
            x = spawn_positions[i].x,
            y = spawn_positions[i].y,
            alive = true,
            color = player_colors[i],
            name = player_names[i],
            target_task = nil,
            ai_timer = 0,
            ai_wander_x = 0,
            ai_wander_y = 0,
            tasks_done = 0,
            near_kill_timer = 0,
            suspicion = {},
        }
        for j = 1, PLAYER_COUNT do
            players[i].suspicion[j] = 0
        end
    end

    -- create tasks
    tasks = {}
    for i = 1, TASK_COUNT do
        tasks[i] = {
            x = task_positions[i].x,
            y = task_positions[i].y,
            label = task_positions[i].label,
            room = task_positions[i].room,
            completed = false,
        }
    end

    tasks_completed = 0
    current_task_progress = 0
    current_task_index = nil
    sabotage_active = false
    sabotage_timer = 0
    sabotage_cooldown = 15
    votes = {}
    vote_result = nil
    vote_timer = 0
    game_message = ""
    game_winner = ""
    frame_count = 0
    vision_pulse = 0
    result_timer = 0
end

-- ── AI behavior ────────────────────────────────────────────────────────────
local function update_ai(i)
    local p = players[i]
    if not p.alive then return end

    p.ai_timer = p.ai_timer - dt

    -- traitor AI
    if i == traitor_index then
        -- look for isolated targets
        local target = nil
        local best_dist = 999999
        for j = 1, PLAYER_COUNT do
            if j ~= i and players[j].alive then
                local d = dist(p.x, p.y, players[j].x, players[j].y)
                if d < KILL_RANGE * 1.5 then
                    -- check no witnesses nearby
                    local witnessed = false
                    for k = 1, PLAYER_COUNT do
                        if k ~= i and k ~= j and players[k].alive then
                            if dist(p.x, p.y, players[k].x, players[k].y) < VISION_RADIUS then
                                witnessed = true
                                break
                            end
                        end
                    end
                    if not witnessed and d < best_dist then
                        best_dist = d
                        target = j
                    end
                end
            end
        end

        if target then
            -- eliminate target
            players[target].alive = false
            spawn_particles(players[target].x, players[target].y, 1.0, 0.1, 0.1, 20)
            -- increase suspicion for nearby players
            for k = 1, PLAYER_COUNT do
                if k ~= i and players[k].alive then
                    if dist(p.x, p.y, players[k].x, players[k].y) < VISION_RADIUS * 1.2 then
                        players[k].suspicion[i] = players[k].suspicion[i] + 30
                    end
                end
            end
            -- check win
            if alive_crew_count() <= 1 then
                state = STATE_GAME_OVER
                game_winner = "traitor"
                game_message = player_names[traitor_index] .. " (Traitor) wins!"
                return
            end
        end

        -- sabotage logic
        if not sabotage_active then
            sabotage_cooldown = sabotage_cooldown - dt
            if sabotage_cooldown <= 0 then
                sabotage_active = true
                sabotage_timer = SABOTAGE_DURATION
                sabotage_cooldown = 20 + math.random() * 10
                spawn_particles(p.x, p.y, 0.5, 0.0, 0.5, 15)
            end
        end

        -- wander like a crewmate (blend in)
        if p.ai_timer <= 0 then
            local rx = rooms[math.random(1, #rooms)]
            p.ai_wander_x = rx.x + math.random(-30, 30)
            p.ai_wander_y = rx.y + math.random(-30, 30)
            p.ai_timer = 3 + math.random() * 4
        end
    else
        -- crew AI: go to tasks or wander
        if p.ai_timer <= 0 then
            -- pick a random incomplete task
            local available = {}
            for t = 1, TASK_COUNT do
                if not tasks[t].completed then
                    available[#available + 1] = t
                end
            end
            if #available > 0 then
                p.target_task = available[math.random(1, #available)]
                local tk = tasks[p.target_task]
                p.ai_wander_x = tk.x + math.random(-10, 10)
                p.ai_wander_y = tk.y + math.random(-10, 10)
            else
                local rx = rooms[math.random(1, #rooms)]
                p.ai_wander_x = rx.x + math.random(-30, 30)
                p.ai_wander_y = rx.y + math.random(-30, 30)
            end
            p.ai_timer = 2 + math.random() * 3
        end

        -- complete task if near it
        if p.target_task and not tasks[p.target_task].completed then
            local tk = tasks[p.target_task]
            if dist(p.x, p.y, tk.x, tk.y) < TASK_RADIUS * 2 then
                p.near_kill_timer = p.near_kill_timer + dt
                if p.near_kill_timer >= TASK_HOLD_TIME then
                    tasks[p.target_task].completed = true
                    tasks_completed = tasks_completed + 1
                    p.tasks_done = p.tasks_done + 1
                    p.target_task = nil
                    p.near_kill_timer = 0
                    spawn_particles(tk.x, tk.y, 0.3, 1.0, 0.5, 12)
                    if tasks_completed >= TASK_COUNT then
                        state = STATE_GAME_OVER
                        game_winner = "crew"
                        game_message = "All tasks complete! Crew wins!"
                    end
                end
            else
                p.near_kill_timer = 0
            end
        end
    end

    -- movement toward wander target
    local dx = p.ai_wander_x - p.x
    local dy = p.ai_wander_y - p.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d > 4 then
        local speed = PLAYER_SPEED * 0.7
        p.x = p.x + (dx / d) * speed * dt
        p.y = p.y + (dy / d) * speed * dt
    end
    p.x = clamp(p.x, 20, 750)
    p.y = clamp(p.y, 20, 620)
end

-- ── Voting logic ───────────────────────────────────────────────────────────
local function start_meeting(caller_idx)
    meeting_caller = caller_idx
    state = STATE_MEETING
    votes = {}
    vote_result = nil
    vote_timer = 0
    -- AI votes
    for i = 2, PLAYER_COUNT do
        if players[i].alive and i ~= traitor_index then
            -- vote for most suspicious
            local max_sus, max_idx = -1, nil
            for j = 1, PLAYER_COUNT do
                if j ~= i and players[j].alive and players[i].suspicion[j] > max_sus then
                    max_sus = players[i].suspicion[j]
                    max_idx = j
                end
            end
            if max_idx and max_sus > 5 then
                votes[i] = max_idx
            else
                -- random vote or skip
                local alive_list = {}
                for j = 1, PLAYER_COUNT do
                    if j ~= i and players[j].alive then
                        alive_list[#alive_list + 1] = j
                    end
                end
                if #alive_list > 0 and math.random() > 0.3 then
                    votes[i] = alive_list[math.random(1, #alive_list)]
                end
            end
        elseif i == traitor_index and players[i].alive then
            -- traitor votes for a random crewmate
            local crew = {}
            for j = 1, PLAYER_COUNT do
                if j ~= i and players[j].alive then
                    crew[#crew + 1] = j
                end
            end
            if #crew > 0 then
                votes[i] = crew[math.random(1, #crew)]
            end
        end
    end
    -- transition to voting after brief pause
    lurek.tween.to(1.5, function(t)
        vote_timer = t
    end, { ease = "linear", on_complete = function()
        state = STATE_VOTING
    end })
end

local function tally_votes()
    local counts = {}
    for i = 1, PLAYER_COUNT do counts[i] = 0 end
    for _, target in pairs(votes) do
        if target then counts[target] = counts[target] + 1 end
    end
    local max_count, max_idx = 0, nil
    local tied = false
    for i = 1, PLAYER_COUNT do
        if counts[i] > max_count then
            max_count = counts[i]
            max_idx = i
            tied = false
        elseif counts[i] == max_count and counts[i] > 0 then
            tied = true
        end
    end
    if tied or max_count == 0 then
        vote_result = { eliminated = nil, message = "No majority — nobody was eliminated." }
    else
        players[max_idx].alive = false
        local msg = player_names[max_idx] .. " was eliminated."
        if max_idx == traitor_index then
            msg = msg .. " They were the Traitor!"
        else
            msg = msg .. " They were a Crewmate."
        end
        vote_result = { eliminated = max_idx, message = msg }
        spawn_particles(400, 300, 1.0, 0.5, 0.0, 25)
    end
    -- check win conditions after vote
    if not players[traitor_index].alive then
        state = STATE_GAME_OVER
        game_winner = "crew"
        game_message = "Traitor eliminated! Crew wins!"
    elseif alive_crew_count() <= 1 then
        state = STATE_GAME_OVER
        game_winner = "traitor"
        game_message = player_names[traitor_index] .. " (Traitor) wins!"
    else
        state = STATE_RESULT
        result_timer = 3.0
    end
end

-- ── Callbacks ──────────────────────────────────────────────────────────────
lurek.init(function()
    lurek.window.setTitle("Social Deduction — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.08, 0.12)
    lurek.tween.to(1.0, function(t) title_alpha = t end, { ease = "outQuad" })
end)

lurek.ready(function()
end)

lurek.process(function(delta)
    dt = delta
    frame_count = frame_count + 1

    if lurek.input.pressed("quit") then
        lurek.event.quit()
        return
    end

    -- ── Title ──────────────────────────────────────────────────────────
    if state == STATE_TITLE then
        if lurek.input.pressed("interact") then
            init_game()
            state = STATE_TASK_PHASE
            if is_player_traitor then
                game_message = "You are the TRAITOR. Eliminate the crew!"
            else
                game_message = "You are a Crewmate. Complete tasks and find the traitor!"
            end
        end
        return
    end

    -- ── Task phase ─────────────────────────────────────────────────────
    if state == STATE_TASK_PHASE then
        local p = players[1]
        if not p.alive then
            state = STATE_GAME_OVER
            game_winner = "traitor"
            game_message = "You were eliminated! " .. player_names[traitor_index] .. " was the traitor."
            return
        end

        -- player movement
        local mx, my = 0, 0
        if lurek.input.down("up")    then my = my - 1 end
        if lurek.input.down("down")  then my = my + 1 end
        if lurek.input.down("left")  then mx = mx - 1 end
        if lurek.input.down("right") then mx = mx + 1 end
        if mx ~= 0 or my ~= 0 then
            local len = math.sqrt(mx * mx + my * my)
            p.x = clamp(p.x + (mx / len) * PLAYER_SPEED * dt, 20, 750)
            p.y = clamp(p.y + (my / len) * PLAYER_SPEED * dt, 20, 620)
        end

        -- camera follow
        lurek.camera.setPosition(p.x - SCREEN_W / 2, p.y - SCREEN_H / 2)

        -- task interaction
        if lurek.input.down("interact") then
            if is_player_traitor then
                -- traitor: eliminate nearby player
                for j = 2, PLAYER_COUNT do
                    if players[j].alive and j ~= traitor_index and dist(p.x, p.y, players[j].x, players[j].y) < KILL_RANGE then
                        local witnessed = false
                        for k = 2, PLAYER_COUNT do
                            if k ~= j and players[k].alive and k ~= 1 then
                                if dist(p.x, p.y, players[k].x, players[k].y) < VISION_RADIUS then
                                    witnessed = true
                                    break
                                end
                            end
                        end
                        players[j].alive = false
                        spawn_particles(players[j].x, players[j].y, 1.0, 0.1, 0.1, 20)
                        if witnessed then
                            for k = 2, PLAYER_COUNT do
                                if players[k].alive and k ~= 1 then
                                    players[k].suspicion[1] = players[k].suspicion[1] + 50
                                end
                            end
                        end
                        if alive_crew_count() <= 1 then
                            state = STATE_GAME_OVER
                            game_winner = "traitor"
                            game_message = "You eliminated the crew! Traitor wins!"
                        end
                        break
                    end
                end
            else
                -- crewmate: complete tasks
                local near_task = nil
                for t = 1, TASK_COUNT do
                    if not tasks[t].completed and dist(p.x, p.y, tasks[t].x, tasks[t].y) < TASK_RADIUS * 2 then
                        near_task = t
                        break
                    end
                end
                if near_task then
                    current_task_index = near_task
                    current_task_progress = current_task_progress + dt
                    if current_task_progress >= TASK_HOLD_TIME then
                        tasks[near_task].completed = true
                        tasks_completed = tasks_completed + 1
                        current_task_progress = 0
                        current_task_index = nil
                        spawn_particles(tasks[near_task].x, tasks[near_task].y, 0.3, 1.0, 0.5, 15)
                        if tasks_completed >= TASK_COUNT then
                            state = STATE_GAME_OVER
                            game_winner = "crew"
                            game_message = "All tasks complete! Crew wins!"
                        end
                    end
                else
                    current_task_progress = 0
                    current_task_index = nil
                end
            end
        else
            current_task_progress = 0
            current_task_index = nil
        end

        -- call meeting
        if lurek.input.pressed("meeting") then
            start_meeting(1)
            return
        end

        -- sabotage timer
        if sabotage_active then
            sabotage_timer = sabotage_timer - dt
            vision_pulse = vision_pulse + dt * 4
            if sabotage_timer <= 0 then
                sabotage_active = false
                vision_pulse = 0
            end
        end

        -- update AI
        for i = 2, PLAYER_COUNT do
            update_ai(i)
        end

        -- fade game message
        if #game_message > 0 then
            -- message displayed until state change
        end
    end

    -- ── Voting state ───────────────────────────────────────────────────
    if state == STATE_VOTING then
        if not votes[1] then
            for v = 1, 6 do
                if lurek.input.pressed("vote" .. v) then
                    if players[v].alive and v ~= 1 then
                        votes[1] = v
                        -- animate then tally
                        lurek.tween.to(1.0, function() end, { ease = "outQuad", on_complete = function()
                            tally_votes()
                        end })
                    end
                end
            end
        end
    end

    -- ── Result display ─────────────────────────────────────────────────
    if state == STATE_RESULT then
        result_timer = result_timer - dt
        if result_timer <= 0 then
            state = STATE_TASK_PHASE
            game_message = ""
        end
    end

    -- ── Game over ──────────────────────────────────────────────────────
    if state == STATE_GAME_OVER then
        if lurek.input.pressed("interact") then
            state = STATE_TITLE
            title_alpha = 1.0
        end
    end

    -- FPS title
    if frame_count % 30 == 0 then
        lurek.window.setTitle("Social Deduction — " .. tostring(math.floor(1 / dt)) .. " FPS")
    end
end)

-- ── Render (world space) ───────────────────────────────────────────────────
lurek.render(function()
    if state == STATE_TITLE or state == STATE_GAME_OVER then return end

    local px, py = players[1].x, players[1].y
    local vis = sabotage_active and (SABOTAGE_VISION + math.sin(vision_pulse) * 15) or VISION_RADIUS

    -- draw rooms
    for _, rm in ipairs(rooms) do
        local rx, ry = rm.x - rm.w / 2, rm.y - rm.h / 2
        lurek.render.setColor(0.15, 0.18, 0.25, 0.8)
        lurek.render.rectangle("fill", rx, ry, rm.w, rm.h)
        lurek.render.setColor(0.3, 0.35, 0.45, 1.0)
        lurek.render.rectangle("line", rx, ry, rm.w, rm.h)
        lurek.render.setColor(0.4, 0.5, 0.6, 0.6)
        lurek.render.print(rm.name, rm.x - 20, rm.y - rm.h / 2 + 4)
    end

    -- corridors (simple connecting lines)
    lurek.render.setColor(0.12, 0.14, 0.2, 0.6)
    lurek.render.rectangle("fill", 260, 190, 240, 20)
    lurek.render.rectangle("fill", 190, 210, 20, 140)
    lurek.render.rectangle("fill", 340, 250, 20, 100)
    lurek.render.rectangle("fill", 490, 210, 20, 140)
    lurek.render.rectangle("fill", 260, 400, 90, 20)
    lurek.render.rectangle("fill", 420, 400, 180, 20)
    lurek.render.rectangle("fill", 340, 420, 20, 100)

    -- draw tasks
    for t = 1, TASK_COUNT do
        local tk = tasks[t]
        local d = dist(px, py, tk.x, tk.y)
        if d < vis + 30 then
            if tk.completed then
                lurek.render.setColor(0.2, 0.5, 0.3, 0.4)
                lurek.render.rectangle("fill", tk.x - TASK_RADIUS, tk.y - TASK_RADIUS, TASK_RADIUS * 2, TASK_RADIUS * 2)
                lurek.render.setColor(0.3, 0.8, 0.4, 0.7)
                lurek.render.print("✓", tk.x - 4, tk.y - 6)
            else
                lurek.render.setColor(1.0, 0.9, 0.2, 0.8)
                lurek.render.rectangle("fill", tk.x - TASK_RADIUS, tk.y - TASK_RADIUS, TASK_RADIUS * 2, TASK_RADIUS * 2)
                lurek.render.setColor(0.9, 0.8, 0.1, 1.0)
                lurek.render.rectangle("line", tk.x - TASK_RADIUS, tk.y - TASK_RADIUS, TASK_RADIUS * 2, TASK_RADIUS * 2)
                lurek.render.setColor(0.3, 0.2, 0.0, 1.0)
                lurek.render.print("!", tk.x - 3, tk.y - 6)
            end
        end
    end

    -- draw players
    for i = 1, PLAYER_COUNT do
        local p = players[i]
        local d = dist(px, py, p.x, p.y)
        if i == 1 or d < vis then
            if p.alive then
                local c = p.color
                lurek.render.setColor(c[1], c[2], c[3], 1.0)
                lurek.render.circle("fill", p.x, p.y, PLAYER_RADIUS)
                lurek.render.setColor(c[1] * 0.7, c[2] * 0.7, c[3] * 0.7, 1.0)
                lurek.render.circle("line", p.x, p.y, PLAYER_RADIUS)
                -- name label
                lurek.render.setColor(1, 1, 1, 0.7)
                lurek.render.print(p.name, p.x - 10, p.y - PLAYER_RADIUS - 14)
            else
                -- dead body / X mark
                lurek.render.setColor(0.6, 0.1, 0.1, 0.8)
                lurek.render.print("X", p.x - 5, p.y - 6)
            end
        end
    end
end)

-- ── Render UI (screen space) ───────────────────────────────────────────────
lurek.render_ui(function()
    -- ── Title screen ───────────────────────────────────────────────────
    if state == STATE_TITLE then
        lurek.render.setColor(0.9, 0.1, 0.15, title_alpha)
        lurek.render.print("SOCIAL DEDUCTION", 240, 180)
        lurek.render.setColor(0.7, 0.7, 0.8, title_alpha * 0.8)
        lurek.render.print("TRUST NO ONE", 300, 230)
        lurek.render.setColor(0.5, 0.5, 0.6, 0.5 + math.sin(frame_count * 0.05) * 0.3)
        lurek.render.print("Press E to start", 310, 350)
        return
    end

    -- ── Game over screen ───────────────────────────────────────────────
    if state == STATE_GAME_OVER then
        local cr, cg, cb = 0.2, 0.8, 0.3
        if game_winner == "traitor" then cr, cg, cb = 0.9, 0.15, 0.15 end
        lurek.render.setColor(cr, cg, cb, 1.0)
        lurek.render.print("GAME OVER", 320, 200)
        lurek.render.setColor(0.9, 0.9, 0.95, 0.9)
        lurek.render.print(game_message, 200, 260)
        lurek.render.setColor(0.5, 0.5, 0.6, 0.5 + math.sin(frame_count * 0.05) * 0.3)
        lurek.render.print("Press E to return to title", 270, 400)
        return
    end

    -- ── Vision overlay (darkened edges) ────────────────────────────────
    if state == STATE_TASK_PHASE then
        local vis = sabotage_active and (SABOTAGE_VISION + math.sin(vision_pulse) * 15) or VISION_RADIUS
        -- darken screen edges to simulate limited vision
        lurek.render.setColor(0.0, 0.0, 0.0, 0.4)
        lurek.render.rectangle("fill", 0, 0, 30, SCREEN_H)
        lurek.render.rectangle("fill", SCREEN_W - 30, 0, 30, SCREEN_H)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, 30)
        lurek.render.rectangle("fill", 0, SCREEN_H - 30, SCREEN_W, 30)

        if sabotage_active then
            lurek.render.setColor(0.1, 0.0, 0.15, 0.3 + math.sin(vision_pulse) * 0.1)
            lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
            lurek.render.setColor(1.0, 0.3, 0.3, 0.9)
            lurek.render.print("⚠ SABOTAGE — LIGHTS OUT ⚠", 280, 10)
        end

        -- task progress bar
        if current_task_index then
            local bw, bh = 120, 14
            local bx, by = SCREEN_W / 2 - bw / 2, SCREEN_H - 60
            local pct = current_task_progress / TASK_HOLD_TIME
            lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
            lurek.render.rectangle("fill", bx, by, bw, bh)
            lurek.render.setColor(0.2, 0.9, 0.4, 0.9)
            lurek.render.rectangle("fill", bx, by, bw * pct, bh)
            lurek.render.setColor(0.8, 0.8, 0.8, 1.0)
            lurek.render.print(tasks[current_task_index].label, bx, by - 16)
        end

        -- HUD: task counter
        lurek.render.setColor(0.9, 0.9, 0.95, 0.9)
        lurek.render.print("Tasks: " .. tasks_completed .. " / " .. TASK_COUNT, 10, 10)
        lurek.render.print("Alive: " .. alive_count() .. " / " .. PLAYER_COUNT, 10, 28)

        -- role indicator
        if is_player_traitor then
            lurek.render.setColor(1.0, 0.2, 0.2, 0.9)
            lurek.render.print("ROLE: TRAITOR", SCREEN_W - 130, 10)
        else
            lurek.render.setColor(0.3, 0.7, 1.0, 0.9)
            lurek.render.print("ROLE: CREWMATE", SCREEN_W - 140, 10)
        end

        -- controls hint
        lurek.render.setColor(0.5, 0.5, 0.6, 0.5)
        lurek.render.print("WASD move | E interact | M meeting", 220, SCREEN_H - 20)

        -- game message
        if #game_message > 0 then
            lurek.render.setColor(1.0, 0.9, 0.4, 0.9)
            lurek.render.print(game_message, 140, 50)
        end
    end

    -- ── Meeting / Voting UI ────────────────────────────────────────────
    if state == STATE_MEETING or state == STATE_VOTING or state == STATE_RESULT then
        -- background panel
        lurek.render.setColor(0.1, 0.1, 0.15, 0.95)
        lurek.render.rectangle("fill", 80, 60, 640, 480)
        lurek.render.setColor(0.4, 0.4, 0.5, 1.0)
        lurek.render.rectangle("line", 80, 60, 640, 480)

        lurek.render.setColor(1.0, 0.8, 0.2, 1.0)
        lurek.render.print("EMERGENCY MEETING", 290, 80)

        if meeting_caller then
            lurek.render.setColor(0.7, 0.7, 0.8, 0.7)
            lurek.render.print("Called by: " .. player_names[meeting_caller], 310, 105)
        end

        -- player list
        for i = 1, PLAYER_COUNT do
            local py = 140 + (i - 1) * 55
            local c = player_colors[i]

            if players[i].alive then
                lurek.render.setColor(c[1], c[2], c[3], 1.0)
                lurek.render.circle("fill", 130, py + 15, 12)
                lurek.render.setColor(0.9, 0.9, 0.95, 1.0)
                lurek.render.print(i .. ". " .. player_names[i], 155, py + 6)

                -- show votes
                if votes[i] then
                    lurek.render.setColor(0.6, 0.6, 0.7, 0.8)
                    lurek.render.print("voted: " .. player_names[votes[i]], 350, py + 6)
                end
            else
                lurek.render.setColor(0.4, 0.2, 0.2, 0.6)
                lurek.render.circle("fill", 130, py + 15, 12)
                lurek.render.setColor(0.5, 0.3, 0.3, 0.6)
                lurek.render.print(i .. ". " .. player_names[i] .. " [ELIMINATED]", 155, py + 6)
            end
        end

        if state == STATE_VOTING and not votes[1] then
            lurek.render.setColor(0.8, 0.9, 1.0, 0.6 + math.sin(frame_count * 0.08) * 0.3)
            lurek.render.print("Press 1-6 to cast your vote", 270, 490)
        end

        if state == STATE_RESULT and vote_result then
            lurek.render.setColor(1.0, 0.6, 0.2, 1.0)
            lurek.render.print(vote_result.message, 180, 460)
        end
    end
end)
