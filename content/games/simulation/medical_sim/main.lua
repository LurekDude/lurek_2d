-- ============================================================================
-- Medical Sim — Lurek2D
-- ============================================================================
-- Category : simulation
-- Source   : content/games/simulation/medical_sim/main.lua
-- Run with : cargo run -- content/games/simulation/medical_sim
-- ============================================================================
-- Hospital management simulation: triage patients, assign staff, upgrade
-- departments, and maintain a 4+ star rating to win.
-- Controls: Mouse select, 1-4 assign dept, H hire, E equip, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, PLAYING = 2, VICTORY = 3, GAME_OVER = 4 }
local current_state = STATE.TITLE

-- Department IDs
local DEPT_ER      = 1
local DEPT_GENERAL = 2
local DEPT_SURGERY = 3
local DEPT_ICU     = 4

local DEPT_INFO = {
    [DEPT_ER]      = { name = "ER",      color = {0.85, 0.25, 0.25}, x = 40,  y = 120, w = 170, h = 200 },
    [DEPT_GENERAL] = { name = "General", color = {0.25, 0.75, 0.30}, x = 230, y = 120, w = 170, h = 200 },
    [DEPT_SURGERY] = { name = "Surgery", color = {0.25, 0.40, 0.85}, x = 420, y = 120, w = 170, h = 200 },
    [DEPT_ICU]     = { name = "ICU",     color = {0.85, 0.85, 0.85}, x = 610, y = 120, w = 170, h = 200 },
}

-- Conditions: name, target department, base treatment time (seconds)
local CONDITIONS = {
    { name = "Cold",         dept = DEPT_GENERAL, time = 5  },
    { name = "Fracture",     dept = DEPT_ER,      time = 10 },
    { name = "Appendicitis", dept = DEPT_SURGERY, time = 15 },
    { name = "Heart Attack", dept = DEPT_ICU,     time = 20 },
}

local PATIENT_INTERVAL_BASE = 8
local WRONG_DEPT_MULT       = 2.0
local EQUIP_REDUCTION       = 0.20

local INCOME_PER_PATIENT    = 20
local EMERGENCY_BONUS       = 10
local EMERGENCY_WINDOW      = 15
local HIRE_COST             = 100
local EQUIP_COST            = 200

local HAPPY_WAIT   = 20
local ANGRY_WAIT   = 40
local LEAVE_WAIT   = 60

local GOAL_TREATED = 50
local GOAL_RATING  = 4.0

-- Waiting area layout
local WAIT_X, WAIT_Y = 40, 360
local WAIT_COLS       = 10
local WAIT_CELL       = 32

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local gold       = 300
local displayGold = 300
local rating     = 3.0
local totalTreated = 0
local totalLeft    = 0
local ratingSum    = 0
local ratingCount  = 0

local patients     = {}   -- waiting area patients
local departments  = {}   -- departments[dept_id] = { patients={}, doctors={}, equip_level=0 }
local doctors      = {}   -- all doctors
local nextPatientTimer = 0

local selectedPatient = nil
local selectedDoctor  = nil

-- Particle & tween lists
local particles = {}
local tweens    = {}

-- Camera / FPS
local camera = nil
local fps    = 0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function spawnParticle(x, y, r, g, b, count, spread)
    for _ = 1, (count or 8) do
        local s = spread or 30
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * s * 2,
            vy = (math.random() - 0.5) * s * 2 - 20,
            life = 0.6 + math.random() * 0.4,
            maxLife = 1.0,
            r = r, g = g, b = b,
            size = 3 + math.random() * 3,
        })
    end
end

local function addTween(target, field, from, to, duration)
    table.insert(tweens, {
        target = target, field = field,
        from = from, to = to,
        duration = duration, elapsed = 0,
    })
end

local function updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end
end

local function updateTweens(dt)
    for i = #tweens, 1, -1 do
        local t = tweens[i]
        t.elapsed = t.elapsed + dt
        local pct = math.min(t.elapsed / t.duration, 1)
        t.target[t.field] = t.from + (t.to - t.from) * pct
        if pct >= 1 then table.remove(tweens, i) end
    end
end

local function calcRating()
    if ratingCount == 0 then return 3.0 end
    return math.max(1.0, math.min(5.0, ratingSum / ratingCount))
end

local function patientArrivalInterval()
    local r = calcRating()
    return PATIENT_INTERVAL_BASE * (3.0 / math.max(r, 1.0))
end

local function createDoctor(id, dept)
    return { id = id, dept = dept, busy = false, treatTimer = 0, patient = nil }
end

local function initGame()
    gold = 300
    displayGold = 300
    rating = 3.0
    totalTreated = 0
    totalLeft = 0
    ratingSum = 0
    ratingCount = 0
    patients = {}
    departments = {}
    doctors = {}
    particles = {}
    tweens = {}
    nextPatientTimer = 3
    selectedPatient = nil
    selectedDoctor = nil

    for d = 1, 4 do
        departments[d] = { patients = {}, doctors = {}, equip_level = 0 }
    end

    -- Start with 4 doctors, one per department
    for d = 1, 4 do
        local doc = createDoctor(d, d)
        table.insert(doctors, doc)
        table.insert(departments[d].doctors, doc)
    end
end

local function spawnPatient()
    local cond = CONDITIONS[math.random(1, #CONDITIONS)]
    local p = {
        condition = cond,
        arrivalTime = 0,
        waitTime = 0,
        assigned = false,
        dept = nil,
        treating = false,
        treatProgress = 0,
        treatDuration = cond.time,
        displayProgress = 0,
    }
    table.insert(patients, p)
    -- Arrival glow particle
    local idx = #patients
    local col = ((idx - 1) % WAIT_COLS)
    local row = math.floor((idx - 1) / WAIT_COLS)
    local px = WAIT_X + col * WAIT_CELL + WAIT_CELL * 0.5
    local py = WAIT_Y + row * WAIT_CELL + WAIT_CELL * 0.5
    spawnParticle(px, py, 0.3, 0.9, 1.0, 6, 20)
end

local function findFreeDoctorInDept(deptId)
    for _, doc in ipairs(departments[deptId].doctors) do
        if not doc.busy then return doc end
    end
    return nil
end

local function startTreatment(patient, deptId)
    local doc = findFreeDoctorInDept(deptId)
    if not doc then
        table.insert(departments[deptId].patients, patient)
        return
    end
    local duration = patient.condition.time
    -- Wrong department penalty
    if patient.condition.dept ~= deptId then
        duration = duration * WRONG_DEPT_MULT
    end
    -- Equipment reduction
    local equip = departments[deptId].equip_level
    duration = duration * (1.0 - equip * EQUIP_REDUCTION)
    duration = math.max(duration, 1)

    patient.treating = true
    patient.treatDuration = duration
    patient.treatProgress = 0
    patient.displayProgress = 0
    doc.busy = true
    doc.patient = patient
    doc.treatTimer = duration
    addTween(patient, "displayProgress", 0, 1, duration)

    -- Treatment sparkle
    local di = DEPT_INFO[deptId]
    spawnParticle(di.x + di.w * 0.5, di.y + di.h * 0.5, 1.0, 1.0, 0.4, 10, 40)
end

local function completeTreatment(doc)
    local patient = doc.patient
    doc.busy = false
    doc.patient = nil
    doc.treatTimer = 0
    totalTreated = totalTreated + 1

    -- Income
    local income = INCOME_PER_PATIENT
    if patient.waitTime < EMERGENCY_WINDOW then
        income = income + EMERGENCY_BONUS
    end
    gold = gold + income
    addTween({ displayGold = displayGold }, "displayGold", displayGold, gold, 0.5)
    displayGold = gold

    -- Rating contribution
    local sat = 5.0
    if patient.waitTime > HAPPY_WAIT then sat = 3.0 end
    if patient.waitTime > ANGRY_WAIT then sat = 1.5 end
    ratingSum = ratingSum + sat
    ratingCount = ratingCount + 1
    rating = calcRating()

    -- Sparkle on completion
    local di = DEPT_INFO[doc.dept]
    spawnParticle(di.x + di.w * 0.5, di.y + di.h * 0.5, 0.2, 1.0, 0.3, 12, 35)

    -- Try treating next queued patient
    local queue = departments[doc.dept].patients
    if #queue > 0 then
        local next_p = table.remove(queue, 1)
        startTreatment(next_p, doc.dept)
    end
end

-- ---------------------------------------------------------------------------
-- Input bindings
-- ---------------------------------------------------------------------------

function lurek.init()
    lurek.window.setTitle("Medical Sim — Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.1, 0.12)
    camera = lurek.camera.new()

    lurek.input.bind("assign_er",      "1")
    lurek.input.bind("assign_general", "2")
    lurek.input.bind("assign_surgery", "3")
    lurek.input.bind("assign_icu",     "4")
    lurek.input.bind("hire",           "h")
    lurek.input.bind("equip",          "e")
    lurek.input.bind("select",         "mouse1")
    lurek.input.bind("quit",           "escape")
end

-- ---------------------------------------------------------------------------
-- Ready
-- ---------------------------------------------------------------------------
local function _ready_setup()
    initGame()
end

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    fps = lurek.timer.getFPS()

    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- ---- TITLE ----
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("select") then
            current_state = STATE.PLAYING
            initGame()
        end
        return
    end

    -- ---- VICTORY / GAME_OVER ----
    if current_state == STATE.VICTORY or current_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("select") then
            current_state = STATE.TITLE
        end
        return
    end

    -- ---- PLAYING ----

    -- Spawn patients
    nextPatientTimer = nextPatientTimer - dt
    if nextPatientTimer <= 0 then
        spawnPatient()
        nextPatientTimer = patientArrivalInterval()
    end

    -- Update waiting patients
    for i = #patients, 1, -1 do
        local p = patients[i]
        if not p.assigned then
            p.waitTime = p.waitTime + dt
            if p.waitTime >= LEAVE_WAIT then
                -- Patient leaves
                table.remove(patients, i)
                totalLeft = totalLeft + 1
                ratingSum = ratingSum + 0.5
                ratingCount = ratingCount + 1
                rating = calcRating()
                -- Emergency flash for leaving patient
                spawnParticle(WAIT_X + 50, WAIT_Y + 10, 1.0, 0.2, 0.2, 15, 50)
                if selectedPatient == p then selectedPatient = nil end
            end
        end
    end

    -- Update treatments
    for _, doc in ipairs(doctors) do
        if doc.busy and doc.patient then
            doc.treatTimer = doc.treatTimer - dt
            doc.patient.treatProgress = 1.0 - (doc.treatTimer / doc.patient.treatDuration)
            if doc.treatTimer <= 0 then
                completeTreatment(doc)
            end
        end
    end

    -- Selection via click
    if lurek.input.wasActionPressed("select") then
        local mx, my = lurek.input.mouse.getPosition()
        local found = false

        -- Check if clicking a waiting patient
        for i, p in ipairs(patients) do
            if not p.assigned then
                local col = ((i - 1) % WAIT_COLS)
                local row = math.floor((i - 1) / WAIT_COLS)
                local px = WAIT_X + col * WAIT_CELL
                local py = WAIT_Y + row * WAIT_CELL
                if mx >= px and mx < px + WAIT_CELL and my >= py and my < py + WAIT_CELL then
                    selectedPatient = p
                    selectedDoctor = nil
                    found = true
                    break
                end
            end
        end

        -- Check if clicking a doctor icon (shown inside departments)
        if not found then
            for d = 1, 4 do
                local di = DEPT_INFO[d]
                for j, doc in ipairs(departments[d].doctors) do
                    local dx = di.x + 8 + (j - 1) * 24
                    local dy = di.y + di.h - 30
                    if mx >= dx and mx < dx + 20 and my >= dy and my < dy + 20 then
                        selectedDoctor = doc
                        selectedPatient = nil
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end

        if not found then
            selectedPatient = nil
            selectedDoctor = nil
        end
    end

    -- Assign patient to department 1-4
    local assign_actions = { "assign_er", "assign_general", "assign_surgery", "assign_icu" }
    for d = 1, 4 do
        if lurek.input.wasActionPressed(assign_actions[d]) then
            if selectedPatient and not selectedPatient.assigned then
                selectedPatient.assigned = true
                selectedPatient.dept = d
                -- Remove from waiting list
                for i = #patients, 1, -1 do
                    if patients[i] == selectedPatient then
                        table.remove(patients, i)
                        break
                    end
                end
                startTreatment(selectedPatient, d)
                selectedPatient = nil
            elseif selectedDoctor then
                -- Re-assign doctor to new department
                local oldDept = selectedDoctor.dept
                if oldDept ~= d and not selectedDoctor.busy then
                    -- Remove from old department
                    local oldList = departments[oldDept].doctors
                    for i = #oldList, 1, -1 do
                        if oldList[i] == selectedDoctor then
                            table.remove(oldList, i)
                            break
                        end
                    end
                    selectedDoctor.dept = d
                    table.insert(departments[d].doctors, selectedDoctor)
                    selectedDoctor = nil
                end
            end
        end
    end

    -- Hire doctor
    if lurek.input.wasActionPressed("hire") then
        if gold >= HIRE_COST then
            gold = gold - HIRE_COST
            displayGold = gold
            local doc = createDoctor(#doctors + 1, 1)
            table.insert(doctors, doc)
            table.insert(departments[1].doctors, doc)
            spawnParticle(400, 500, 0.4, 0.8, 1.0, 10, 40)
        end
    end

    -- Equipment upgrade (upgrades dept with most doctors or dept 1)
    if lurek.input.wasActionPressed("equip") then
        if gold >= EQUIP_COST then
            -- Find which department to upgrade: one with lowest equip_level
            local bestD, bestLvl = 1, 999
            for d = 1, 4 do
                if departments[d].equip_level < bestLvl then
                    bestD = d
                    bestLvl = departments[d].equip_level
                end
            end
            if departments[bestD].equip_level < 4 then
                gold = gold - EQUIP_COST
                displayGold = gold
                departments[bestD].equip_level = departments[bestD].equip_level + 1
                local di = DEPT_INFO[bestD]
                spawnParticle(di.x + di.w * 0.5, di.y + 20, 1.0, 0.85, 0.2, 15, 45)
            end
        end
    end

    -- Check win/lose
    if totalTreated >= GOAL_TREATED then
        if calcRating() >= GOAL_RATING then
            current_state = STATE.VICTORY
        else
            current_state = STATE.GAME_OVER
        end
    end
    if ratingCount > 10 and calcRating() < 1.5 then
        current_state = STATE.GAME_OVER
    end

    -- Update particles & tweens
    updateParticles(dt)
    updateTweens(dt)
end

-- ---------------------------------------------------------------------------
-- Render (world-space)
-- ---------------------------------------------------------------------------
function lurek.draw()
    if current_state ~= STATE.PLAYING then return end

    -- Draw departments
    for d = 1, 4 do
        local di = DEPT_INFO[d]
        local c = di.color
        -- Background
        lurek.render.rectangle(di.x, di.y, di.w, di.h, c[1] * 0.3, c[2] * 0.3, c[3] * 0.3, 0.8)
        -- Border
        lurek.render.rectangle(di.x, di.y, di.w, 2, c[1], c[2], c[3], 1)
        lurek.render.rectangle(di.x, di.y + di.h - 2, di.w, 2, c[1], c[2], c[3], 1)
        lurek.render.rectangle(di.x, di.y, 2, di.h, c[1], c[2], c[3], 1)
        lurek.render.rectangle(di.x + di.w - 2, di.y, 2, di.h, c[1], c[2], c[3], 1)

        -- Department name
        lurek.render.print(di.name, di.x + 6, di.y + 6, 14, c[1], c[2], c[3], 1)

        -- Equipment level indicator
        for e = 1, departments[d].equip_level do
            lurek.render.rectangle(di.x + di.w - 12 * e, di.y + 6, 8, 8, 1.0, 0.85, 0.2, 1)
        end

        -- Queued patients
        for j, p in ipairs(departments[d].patients) do
            local px = di.x + 10 + (j - 1) * 18
            local py = di.y + 30
            lurek.render.rectangle(px, py, 14, 14, 0.9, 0.9, 0.3, 0.8)
            lurek.render.print(p.condition.name:sub(1, 1), px + 2, py + 1, 10, 0, 0, 0, 1)
        end

        -- Doctors
        for j, doc in ipairs(departments[d].doctors) do
            local dx = di.x + 8 + (j - 1) * 24
            local dy = di.y + di.h - 30
            local da = doc.busy and 0.5 or 1.0
            lurek.render.rectangle(dx, dy, 20, 20, 0.2, 0.6, 0.9, da)
            lurek.render.print("D", dx + 5, dy + 3, 12, 1, 1, 1, da)

            -- Treatment progress bar
            if doc.busy and doc.patient then
                local prog = doc.patient.displayProgress or doc.patient.treatProgress
                lurek.render.rectangle(dx, dy - 8, 20, 4, 0.3, 0.3, 0.3, 1)
                lurek.render.rectangle(dx, dy - 8, 20 * prog, 4, 0.2, 1.0, 0.3, 1)
            end

            -- Selection highlight
            if doc == selectedDoctor then
                lurek.render.rectangle(dx - 2, dy - 2, 24, 24, 1, 1, 0, 0.5)
            end
        end
    end

    -- Draw waiting area background
    lurek.render.rectangle(WAIT_X - 4, WAIT_Y - 24, WAIT_COLS * WAIT_CELL + 8, 90, 0.15, 0.15, 0.18, 0.8)
    lurek.render.print("WAITING AREA", WAIT_X, WAIT_Y - 20, 12, 0.7, 0.7, 0.7, 1)

    -- Draw waiting patients
    for i, p in ipairs(patients) do
        if not p.assigned then
            local col = ((i - 1) % WAIT_COLS)
            local row = math.floor((i - 1) / WAIT_COLS)
            local px = WAIT_X + col * WAIT_CELL
            local py = WAIT_Y + row * WAIT_CELL

            -- Color based on urgency
            local r, g, b = 0.5, 0.9, 0.5
            if p.waitTime > HAPPY_WAIT then r, g, b = 0.9, 0.8, 0.2 end
            if p.waitTime > ANGRY_WAIT then r, g, b = 0.9, 0.3, 0.2 end

            lurek.render.rectangle(px + 2, py + 2, WAIT_CELL - 4, WAIT_CELL - 4, r, g, b, 0.9)
            lurek.render.print(p.condition.name:sub(1, 1), px + 8, py + 8, 12, 0, 0, 0, 1)

            -- Selection highlight
            if p == selectedPatient then
                lurek.render.rectangle(px, py, WAIT_CELL, WAIT_CELL, 1, 1, 0, 0.4)
            end
        end
    end

    -- Draw particles
    for _, p in ipairs(particles) do
        local a = math.max(0, p.life / p.maxLife)
        lurek.render.rectangle(p.x - p.size * 0.5, p.y - p.size * 0.5, p.size, p.size, p.r, p.g, p.b, a)
    end
end

-- ---------------------------------------------------------------------------
-- Render UI (screen-space HUD & menus)
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    -- ---- TITLE SCREEN ----
    if current_state == STATE.TITLE then
        lurek.render.print("MEDICAL SIM", 200, 180, 48, 0.9, 0.3, 0.3, 1)
        lurek.render.print("SAVE LIVES", 260, 240, 28, 0.8, 0.8, 0.8, 1)
        lurek.render.print("Click to start", 310, 340, 16, 0.6, 0.6, 0.6, 1)
        lurek.render.print("1-4: Assign dept | H: Hire | E: Equip", 200, 400, 14, 0.5, 0.5, 0.5, 1)
        return
    end

    -- ---- VICTORY SCREEN ----
    if current_state == STATE.VICTORY then
        lurek.render.print("VICTORY!", 280, 200, 44, 0.2, 1.0, 0.3, 1)
        local msg = string.format("Treated %d patients — Rating: %.1f stars", totalTreated, calcRating())
        lurek.render.print(msg, 180, 270, 18, 0.9, 0.9, 0.9, 1)
        lurek.render.print("Click to return to title", 280, 360, 16, 0.6, 0.6, 0.6, 1)
        return
    end

    -- ---- GAME OVER SCREEN ----
    if current_state == STATE.GAME_OVER then
        lurek.render.print("GAME OVER", 260, 200, 44, 0.9, 0.2, 0.2, 1)
        local msg = string.format("Treated %d / %d — Rating: %.1f stars", totalTreated, GOAL_TREATED, calcRating())
        lurek.render.print(msg, 190, 270, 18, 0.9, 0.9, 0.9, 1)
        lurek.render.print("Click to return to title", 280, 360, 16, 0.6, 0.6, 0.6, 1)
        return
    end

    -- ---- HUD ----
    -- Top bar background
    lurek.render.rectangle(0, 0, SCREEN_W, 28, 0.08, 0.08, 0.10, 0.9)

    -- Gold
    lurek.render.print(string.format("Gold: %d", gold), 10, 6, 14, 1.0, 0.85, 0.2, 1)

    -- Rating (stars)
    local r = calcRating()
    local starStr = string.format("Rating: %.1f", r)
    local starColor = r >= 4 and {0.2, 1.0, 0.3} or (r >= 2.5 and {0.9, 0.8, 0.2} or {0.9, 0.2, 0.2})
    lurek.render.print(starStr, 160, 6, 14, starColor[1], starColor[2], starColor[3], 1)

    -- Patients treated
    lurek.render.print(string.format("Treated: %d / %d", totalTreated, GOAL_TREATED), 340, 6, 14, 0.8, 0.8, 0.8, 1)

    -- Doctors count
    lurek.render.print(string.format("Doctors: %d", #doctors), 530, 6, 14, 0.5, 0.7, 1.0, 1)

    -- FPS
    lurek.render.print(string.format("FPS: %d", fps), SCREEN_W - 80, 6, 14, 0.4, 0.4, 0.4, 1)

    -- Bottom instructions
    lurek.render.rectangle(0, SCREEN_H - 22, SCREEN_W, 22, 0.08, 0.08, 0.10, 0.8)
    lurek.render.print("Click patient/doctor then 1-4 assign | H: Hire (100g) | E: Equip (200g) | Esc: Quit",
        10, SCREEN_H - 18, 12, 0.5, 0.5, 0.5, 1)

    -- Selection info
    if selectedPatient then
        local info = string.format("Selected: %s (wait %.0fs)", selectedPatient.condition.name, selectedPatient.waitTime)
        lurek.render.print(info, 10, SCREEN_H - 42, 14, 1.0, 1.0, 0.4, 1)
    elseif selectedDoctor then
        local info = string.format("Selected: Doctor #%d [%s] %s",
            selectedDoctor.id, DEPT_INFO[selectedDoctor.dept].name,
            selectedDoctor.busy and "(busy)" or "(idle)")
        lurek.render.print(info, 10, SCREEN_H - 42, 14, 0.4, 0.8, 1.0, 1)
    end
end
