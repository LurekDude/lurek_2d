-- Medical Simulation — Luna2D Demo
-- Perform surgery on patients: clean, cut layers, repair, suture

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local tools = {"antiseptic","scalpel","forceps","sutures","sponge"}
local tool_colors = {
    antiseptic = {0.2,0.8,1},
    scalpel    = {0.8,0.8,0.8},
    forceps    = {0.9,0.7,0.2},
    sutures    = {0.3,0.9,0.3},
    sponge     = {1,0.8,0.6},
}
local layer_names = {"skin","muscle","organ"}

local state, patients, current_patient
local selected_tool, message, msg_timer
local score, total_time, game_over

local function new_patient()
    return {
        layers = {skin=true, muscle=true, organ=true},
        cleaned_pre = false,
        cut_skin = false,
        cut_muscle = false,
        repaired = false,
        sutured = false,
        cleaned_post = false,
        done = false,
        heart_rate = 80,
        blood_pressure = 120,
        problem_x = 340 + math.random(0,120),
        problem_y = 250 + math.random(0,60),
        complications = 0,
        step = 1, -- 1=clean,2=cut skin,3=cut muscle,4=repair,5=suture,6=clean post
    }
end

local function show_msg(txt)
    message = txt
    msg_timer = 2
end

function luna.init()
    state = "playing"
    score = 0
    total_time = 0
    game_over = false
    selected_tool = nil
    message = nil
    msg_timer = 0
    patients = {}
    for i = 1, 5 do patients[i] = new_patient() end
    current_patient = 1
end

local function apply_tool(p, tool, mx, my)
    local on_body = mx > 200 and mx < 600 and my > 180 and my < 400
    local on_problem = math.abs(mx - p.problem_x) < 40 and math.abs(my - p.problem_y) < 40
    if not on_body then show_msg("Click on the patient!") return end

    if tool == "antiseptic" then
        if p.step == 1 then p.cleaned_pre = true; p.step = 2; show_msg("Area cleaned. Cut skin next.")
        elseif p.step == 6 then p.cleaned_post = true; p.step = 7; p.done = true; show_msg("Surgery complete!")
            score = score + math.floor(clamp(200 - p.complications * 30, 50, 200))
        else show_msg("Wrong step!"); p.complications = p.complications + 1 end
    elseif tool == "scalpel" then
        if p.step == 2 then p.cut_skin = true; p.layers.skin = false; p.step = 3; show_msg("Skin opened. Cut muscle.")
        elseif p.step == 3 then p.cut_muscle = true; p.layers.muscle = false; p.step = 4; show_msg("Muscle opened. Use forceps to repair.")
        else show_msg("Wrong step!"); p.complications = p.complications + 1 end
    elseif tool == "forceps" then
        if p.step == 4 and on_problem then p.repaired = true; p.step = 5; show_msg("Organ repaired! Suture now.")
        elseif p.step == 4 then show_msg("Aim at the red zone!")
        else show_msg("Wrong step!"); p.complications = p.complications + 1 end
    elseif tool == "sutures" then
        if p.step == 5 then p.sutured = true; p.layers.muscle = true; p.layers.skin = true; p.step = 6; show_msg("Sutured. Clean the wound.")
        else show_msg("Wrong step!"); p.complications = p.complications + 1 end
    elseif tool == "sponge" then
        if p.heart_rate < 70 then p.heart_rate = p.heart_rate + 5; show_msg("Vitals stabilized slightly.")
        else show_msg("Sponge: no effect right now.") end
    end
end

function luna.process(dt)
    if game_over then return end
    total_time = total_time + dt
    if msg_timer > 0 then msg_timer = msg_timer - dt end

    local p = patients[current_patient]
    if not p then game_over = true; return end
    if not p.done then
        p.heart_rate = p.heart_rate - (1 + p.complications * 0.8) * dt
        p.blood_pressure = p.blood_pressure - (0.5 + p.complications * 0.5) * dt
        if p.heart_rate < 30 then
            show_msg("Patient lost! Moving on...")
            p.done = true
            current_patient = current_patient + 1
        end
    end
end

function luna.mousepressed(mx, my, btn)
    if game_over then luna.load(); return end
    if btn ~= 1 then return end

    -- tool palette
    for i, t in ipairs(tools) do
        local ty = 180 + (i-1) * 60
        if mx > 640 and mx < 780 and my > ty and my < ty + 50 then
            selected_tool = t; return
        end
    end

    -- apply to patient
    local p = patients[current_patient]
    if p and not p.done and selected_tool then
        apply_tool(p, selected_tool, mx, my)
        if p.done then current_patient = current_patient + 1 end
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then luna.load() end
end

local function draw_vitals(p)
    luna.gfx.setColor(1,1,1,1)
    luna.gfx.print("Heart Rate: " .. math.floor(p.heart_rate), 20, 420, 1)
    local hr_pct = clamp((p.heart_rate - 30) / 70, 0, 1)
    luna.gfx.setColor(0.3,0.3,0.3,1)
    luna.gfx.rectangle("fill", 20, 440, 160, 14)
    luna.gfx.setColor(1 - hr_pct, hr_pct, 0.2, 1)
    luna.gfx.rectangle("fill", 20, 440, 160 * hr_pct, 14)

    luna.gfx.setColor(1,1,1,1)
    luna.gfx.print("Blood Pressure: " .. math.floor(p.blood_pressure), 20, 465, 1)
    local bp_pct = clamp((p.blood_pressure - 60) / 80, 0, 1)
    luna.gfx.setColor(0.3,0.3,0.3,1)
    luna.gfx.rectangle("fill", 20, 485, 160, 14)
    luna.gfx.setColor(1 - bp_pct, bp_pct, 0.2, 1)
    luna.gfx.rectangle("fill", 20, 485, 160 * bp_pct, 14)
end

local function draw_patient(p)
    -- table
    luna.gfx.setColor(0.4,0.35,0.3,1)
    luna.gfx.rectangle("fill", 200, 360, 400, 40)
    -- body outline
    luna.gfx.setColor(0.9,0.75,0.65,1)
    if p.layers.skin then
        luna.gfx.rectangle("fill", 250, 200, 300, 160)
    end
    if not p.layers.skin and p.layers.muscle then
        luna.gfx.setColor(0.7,0.25,0.2,1)
        luna.gfx.rectangle("fill", 250, 200, 300, 160)
    end
    if not p.layers.skin and not p.layers.muscle then
        luna.gfx.setColor(0.8,0.4,0.4,1)
        luna.gfx.rectangle("fill", 250, 200, 300, 160)
        -- problem zone
        if not p.repaired then
            luna.gfx.setColor(1,0.1,0.1, 0.5 + 0.3 * math.sin(luna.time.getTime() * 5))
            luna.gfx.circle("fill", p.problem_x, p.problem_y, 20)
        else
            luna.gfx.setColor(0.2,1,0.2,0.6)
            luna.gfx.circle("fill", p.problem_x, p.problem_y, 20)
        end
    end
    -- body outline
    luna.gfx.setColor(0.2,0.2,0.2,1)
    luna.gfx.rectangle("line", 250, 200, 300, 160)
    -- step label
    local steps = {"1: Clean area","2: Cut skin","3: Cut muscle","4: Remove/repair","5: Suture","6: Clean wound","Done!"}
    luna.gfx.setColor(1,1,0.6,1)
    luna.gfx.print("Step: " .. (steps[p.step] or "Done!"), 250, 185, 1)
end

function luna.render()
    luna.gfx.setBackgroundColor(0.15,0.18,0.22)

    if game_over then
        luna.gfx.setColor(1,1,1,1)
        luna.gfx.print("ALL PATIENTS COMPLETE", 260, 220, 1.5)
        luna.gfx.print("Score: " .. score, 320, 270, 1.4)
        luna.gfx.print("Time: " .. math.floor(total_time) .. "s", 320, 310, 1)
        luna.gfx.print("Press R to restart", 300, 370, 1)
        return
    end

    luna.gfx.setColor(1,1,1,1)
    luna.gfx.print("MEDICAL SIM — Patient " .. current_patient .. "/5", 20, 10, 1.2)
    luna.gfx.print("Score: " .. score, 20, 40, 1)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), 700, 10, 0.8)

    local p = patients[current_patient]
    if p then
        draw_patient(p)
        draw_vitals(p)
    end

    -- tool palette
    luna.gfx.setColor(0.2,0.2,0.25,1)
    luna.gfx.rectangle("fill", 630, 170, 160, 320)
    luna.gfx.setColor(1,1,1,1)
    luna.gfx.print("TOOLS", 680, 155, 1)
    for i, t in ipairs(tools) do
        local ty = 180 + (i-1) * 60
        local c = tool_colors[t]
        if selected_tool == t then
            luna.gfx.setColor(1,1,0.3,0.4)
            luna.gfx.rectangle("fill", 640, ty, 140, 50)
        end
        luna.gfx.setColor(c[1],c[2],c[3],1)
        luna.gfx.rectangle("fill", 645, ty + 5, 40, 40)
        luna.gfx.setColor(1,1,1,1)
        luna.gfx.print(t, 690, ty + 15, 0.9)
    end

    -- message
    if message and msg_timer > 0 then
        luna.gfx.setColor(1,1,0.5,1)
        luna.gfx.print(message, 220, 520, 1)
    end

    luna.gfx.setColor(0.6,0.6,0.6,1)
    luna.gfx.print("[R] Restart   [ESC] Quit", 20, 570, 0.8)
end
