-- ============================================================================
-- Courtroom Drama — Ace Attorney-style courtroom debate game
-- Category: rpg
-- Engine:   Lurek2D
-- Controls: space(advance) o(objection) e(evidence) q(question)
--           1/2/3(choices) escape(quit)
-- States:   TITLE → CASE_INTRO → TESTIMONY → QUESTION → OBJECTION → VERDICT → GAME_OVER
-- ============================================================================

-- Action input mapping
local actions = {
    advance  = "space",
    objection = "o",
    evidence = "e",
    question = "q",
    choice1  = "1",
    choice2  = "2",
    choice3  = "3",
    quit     = "escape",
}

-- Game state
local state = "TITLE"
local current_case = 1
local credibility = 100
local jury_meter = 0
local jury_display = 0
local cred_display = 100
local show_evidence = false
local typewriter_text = ""
local typewriter_target = ""
local typewriter_timer = 0
local typewriter_speed = 1 / 25
local testimony_line = 1
local flash_alpha = 0
local flash_color = {1, 0.8, 0}
local objection_scale = 0
local objection_alpha = 0
local verdict_confetti = {}
local gavel_sparks = {}
local dialog_queue = {}
local dialog_index = 1
local question_mode = false
local objection_mode = false
local objection_result = ""
local objection_result_timer = 0
local case_won = false
local game_result = ""

-- Cases data
local cases = {
    {
        name = "The Missing Diamond",
        intro = {
            "Case 1: The Missing Diamond",
            "A priceless diamond vanished from the museum last night.",
            "The security guard claims he was at his post all evening.",
            "But something doesn't add up..."
        },
        witness = "Security Guard",
        testimony = {
            "I was stationed at the east wing entrance all night.",
            "I never left my post, not even for a minute.",
            "The security cameras were working fine the whole time.",
            "Nobody suspicious entered the building after 8 PM.",
            "I checked the diamond case at midnight — it was still there.",
        },
        contradiction_line = 3,
        correct_evidence = 1,
        evidence = {
            {name = "Security Footage", desc = "Camera logs show east wing camera offline 10:30-11:15 PM"},
            {name = "Visitor Log", desc = "Sign-in sheet with entries up to 9 PM"},
            {name = "Floor Plan", desc = "Museum layout showing all entrances"},
        },
        questions = {
            {text = "When exactly did you start your shift?", response = "I started at 6 PM sharp, as always."},
            {text = "Did anyone relieve you during the night?", response = "No, I was alone the entire shift."},
            {text = "Were there any power outages?", response = "N-no... everything was normal. I think."},
        },
        win_text = "The security footage proves the cameras WERE offline! The guard is lying!",
    },
    {
        name = "The Poisoned Cake",
        intro = {
            "Case 2: The Poisoned Cake",
            "A birthday cake at the Grand Hotel made three guests ill.",
            "The pastry chef insists every ingredient was fresh.",
            "Time to find the rotten truth..."
        },
        witness = "Pastry Chef",
        testimony = {
            "I prepared the cake myself using only the finest ingredients.",
            "I bought all supplies fresh from the market that morning.",
            "The recipe called for imported vanilla extract, which I used.",
            "I never left the kitchen while the cake was being prepared.",
            "The cake was served immediately after decoration.",
        },
        contradiction_line = 2,
        correct_evidence = 2,
        evidence = {
            {name = "Medical Report", desc = "Traces of expired almond extract found in patients"},
            {name = "Store Receipt", desc = "Receipt dated 3 days before the party, includes almond extract"},
            {name = "Kitchen Photo", desc = "Photo showing the kitchen workspace"},
        },
        questions = {
            {text = "What brand of vanilla did you use?", response = "It was... a common brand. I don't remember exactly."},
            {text = "Did you taste-test the cake?", response = "Of course! It tasted perfect to me."},
            {text = "Who else had access to the kitchen?", response = "Only my assistant, but she left at noon."},
        },
        win_text = "The receipt is dated THREE DAYS before the party! The ingredients were NOT fresh!",
    },
    {
        name = "Corporate Espionage",
        intro = {
            "Case 3: Corporate Espionage",
            "Classified blueprints were leaked to a rival company.",
            "The CEO claims he was in a board meeting during the breach.",
            "But the digital trail tells a different story..."
        },
        witness = "CEO",
        testimony = {
            "I was in the boardroom from 2 PM to 5 PM that day.",
            "The meeting was about quarterly projections, nothing unusual.",
            "I never accessed the classified server that afternoon.",
            "My assistant can confirm I was in the meeting the entire time.",
            "I only learned about the breach the following morning.",
        },
        contradiction_line = 3,
        correct_evidence = 3,
        evidence = {
            {name = "Meeting Minutes", desc = "Board meeting notes, signed by 4 attendees"},
            {name = "Badge Scan Log", desc = "CEO's keycard used at server room at 3:47 PM"},
            {name = "Email Logs", desc = "Email sent FROM CEO's account at 3:52 PM to rival company with attachment"},
        },
        questions = {
            {text = "Who else attended the meeting?", response = "The CFO, marketing director, and two board members."},
            {text = "Do you share your email credentials?", response = "Absolutely not! That would be a security violation."},
            {text = "When did you last visit the server room?", response = "Weeks ago! I rarely go there personally."},
        },
        win_text = "The email logs show a message sent FROM YOUR ACCOUNT at 3:52 PM — during the meeting you claim you never left!",
    },
}

-- Spawn verdict confetti
local function spawn_confetti()
    for i = 1, 60 do
        table.insert(verdict_confetti, {
            x = math.random(50, 750),
            y = -math.random(10, 200),
            vy = math.random(80, 200),
            vx = math.random(-40, 40),
            size = math.random(3, 7),
            r = math.random() * 0.5 + 0.5,
            g = math.random() * 0.5 + 0.5,
            b = math.random() * 0.3,
        })
    end
end

-- Spawn gavel sparks
local function spawn_gavel_sparks()
    for i = 1, 20 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(60, 180)
        table.insert(gavel_sparks, {
            x = 400, y = 100,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.5 + math.random() * 0.3,
            max_life = 0.8,
            size = math.random(2, 5),
        })
    end
end

-- Set typewriter target
local function set_typewriter(text)
    typewriter_target = text
    typewriter_text = ""
    typewriter_timer = 0
end

-- Start a case
local function start_case(n)
    current_case = n
    state = "CASE_INTRO"
    dialog_queue = cases[n].intro
    dialog_index = 1
    testimony_line = 1
    show_evidence = false
    question_mode = false
    objection_mode = false
    objection_result = ""
    set_typewriter(dialog_queue[1])
end

-- Start testimony phase
local function start_testimony()
    state = "TESTIMONY"
    testimony_line = 1
    set_typewriter(cases[current_case].testimony[1])
end

-- Process objection result
local function process_objection(evidence_index)
    local c = cases[current_case]
    objection_mode = false
    if evidence_index == c.correct_evidence and testimony_line == c.contradiction_line then
        objection_result = "CORRECT"
        jury_meter = math.min(100, jury_meter + 25)
        flash_color = {1, 0.9, 0.2}
        flash_alpha = 1
        objection_scale = 3
        objection_alpha = 1
        set_typewriter(c.win_text)
        objection_result_timer = 3
        spawn_gavel_sparks()
    else
        objection_result = "WRONG"
        credibility = math.max(0, credibility - 20)
        flash_color = {1, 0.2, 0.1}
        flash_alpha = 0.8
        objection_scale = 2
        objection_alpha = 1
        if credibility <= 0 then
            set_typewriter("Your credibility is shattered! Case dismissed!")
            objection_result_timer = 3
        else
            set_typewriter("OBJECTION OVERRULED! That evidence is irrelevant! (-20 credibility)")
            objection_result_timer = 2.5
        end
    end
end

function lurek.init()
    lurek.window.setTitle("Courtroom Drama — Lurek2D")
    lurek.render.setBackgroundColor(0.15, 0.1, 0.08)
end

local function _ready_setup() end)

function lurek.process(dt)
    local fps = lurek.timer.getFPS()
    lurek.window.setTitle(string.format("Courtroom Drama — Lurek2D | FPS: %d", fps))

    -- Quit
    if lurek.input.keyboard.isDown(actions.quit) then
        lurek.event.signal("quit")
        return
    end

    -- Typewriter update
    if #typewriter_text < #typewriter_target then
        typewriter_timer = typewriter_timer + dt
        while typewriter_timer >= typewriter_speed and #typewriter_text < #typewriter_target do
            typewriter_timer = typewriter_timer - typewriter_speed
            typewriter_text = typewriter_target:sub(1, #typewriter_text + 1)
        end
    end

    -- Flash decay
    if flash_alpha > 0 then
        flash_alpha = math.max(0, flash_alpha - dt * 3)
    end

    -- Objection text tween
    if objection_alpha > 0 then
        objection_scale = math.max(1, objection_scale - dt * 6)
        if objection_scale <= 1 then
            objection_alpha = math.max(0, objection_alpha - dt * 1.5)
        end
    end

    -- Jury meter smooth tween
    if jury_display < jury_meter then
        jury_display = math.min(jury_meter, jury_display + dt * 60)
    elseif jury_display > jury_meter then
        jury_display = math.max(jury_meter, jury_display - dt * 60)
    end

    -- Credibility smooth tween
    if cred_display > credibility then
        cred_display = math.max(credibility, cred_display - dt * 40)
    elseif cred_display < credibility then
        cred_display = math.min(credibility, cred_display + dt * 40)
    end

    -- Confetti update
    for i = #verdict_confetti, 1, -1 do
        local p = verdict_confetti[i]
        p.y = p.y + p.vy * dt
        p.x = p.x + p.vx * dt
        if p.y > 650 then table.remove(verdict_confetti, i) end
    end

    -- Gavel sparks update
    for i = #gavel_sparks, 1, -1 do
        local s = gavel_sparks[i]
        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt
        s.vy = s.vy + 300 * dt
        s.life = s.life - dt
        if s.life <= 0 then table.remove(gavel_sparks, i) end
    end

    -- Objection result timer
    if objection_result_timer > 0 then
        objection_result_timer = objection_result_timer - dt
        if objection_result_timer <= 0 then
            if credibility <= 0 then
                state = "VERDICT"
                case_won = false
                set_typewriter("GUILTY! The defense has lost all credibility.")
                spawn_gavel_sparks()
            elseif objection_result == "CORRECT" then
                if jury_meter >= 100 then
                    state = "VERDICT"
                    case_won = true
                    set_typewriter("NOT GUILTY! The defense has proven the witness unreliable!")
                    spawn_confetti()
                    spawn_gavel_sparks()
                else
                    set_typewriter(cases[current_case].testimony[testimony_line])
                end
            else
                set_typewriter(cases[current_case].testimony[testimony_line])
            end
            objection_result = ""
        end
        return
    end

    -- State machine input
    if state == "TITLE" then
        if lurek.input.keyboard.isDown(actions.advance) then
            credibility = 100
            cred_display = 100
            jury_meter = 0
            jury_display = 0
            current_case = 1
            start_case(1)
        end

    elseif state == "CASE_INTRO" then
        if lurek.input.keyboard.isDown(actions.advance) and #typewriter_text >= #typewriter_target then
            dialog_index = dialog_index + 1
            if dialog_index > #dialog_queue then
                start_testimony()
            else
                set_typewriter(dialog_queue[dialog_index])
            end
        end

    elseif state == "TESTIMONY" then
        if objection_mode then
            -- Selecting evidence for objection
            for idx = 1, 3 do
                local key = actions["choice" .. idx]
                if lurek.input.keyboard.isDown(key) then
                    process_objection(idx)
                end
            end
            if lurek.input.keyboard.isDown(actions.evidence) then
                objection_mode = false
                set_typewriter(cases[current_case].testimony[testimony_line])
            end
        elseif question_mode then
            -- Choosing question
            for idx = 1, 3 do
                local key = actions["choice" .. idx]
                if lurek.input.keyboard.isDown(key) then
                    question_mode = false
                    local q = cases[current_case].questions[idx]
                    if q then
                        set_typewriter(q.response)
                    end
                end
            end
            if lurek.input.keyboard.isDown(actions.question) then
                question_mode = false
                set_typewriter(cases[current_case].testimony[testimony_line])
            end
        else
            -- Normal testimony navigation
            if lurek.input.keyboard.isDown(actions.advance) and #typewriter_text >= #typewriter_target then
                testimony_line = testimony_line + 1
                local c = cases[current_case]
                if testimony_line > #c.testimony then
                    testimony_line = 1
                end
                set_typewriter(c.testimony[testimony_line])
            end

            if lurek.input.keyboard.isDown(actions.objection) then
                objection_mode = true
                flash_color = {1, 0.6, 0}
                flash_alpha = 0.6
                objection_scale = 3
                objection_alpha = 1
                set_typewriter("Select evidence (1/2/3) or press E to cancel:")
            end

            if lurek.input.keyboard.isDown(actions.question) then
                question_mode = true
                set_typewriter("Choose a question (1/2/3) or press Q to cancel:")
            end

            if lurek.input.keyboard.isDown(actions.evidence) then
                show_evidence = not show_evidence
            end
        end

    elseif state == "VERDICT" then
        if lurek.input.keyboard.isDown(actions.advance) and #typewriter_text >= #typewriter_target then
            if case_won then
                if current_case < 3 then
                    start_case(current_case + 1)
                else
                    state = "GAME_OVER"
                    game_result = "WIN"
                    set_typewriter("All cases won! You are the greatest attorney!")
                    spawn_confetti()
                end
            else
                state = "GAME_OVER"
                game_result = "LOSE"
                set_typewriter("Justice was not served today... Try again?")
            end
        end

    elseif state == "GAME_OVER" then
        if lurek.input.keyboard.isDown(actions.advance) then
            state = "TITLE"
            verdict_confetti = {}
            gavel_sparks = {}
        end
    end
end

-- Draw courtroom scene elements
function lurek.draw()
    -- Courtroom background walls
    lurek.render.setColor(0.25, 0.18, 0.12, 1)
    lurek.render.rectangle("fill", 0, 0, 800, 600)

    -- Wood paneling
    lurek.render.setColor(0.35, 0.22, 0.12, 1)
    lurek.render.rectangle("fill", 0, 400, 800, 200)

    -- Judge's bench (top center)
    lurek.render.setColor(0.4, 0.25, 0.1, 1)
    lurek.render.rectangle("fill", 280, 40, 240, 80)
    lurek.render.setColor(0.5, 0.32, 0.15, 1)
    lurek.render.rectangle("fill", 290, 45, 220, 70)
    -- Judge silhouette
    lurek.render.setColor(0.15, 0.1, 0.08, 1)
    lurek.render.circle("fill", 400, 55, 18)
    lurek.render.rectangle("fill", 385, 73, 30, 35)
    -- Gavel
    lurek.render.setColor(0.55, 0.35, 0.15, 1)
    lurek.render.rectangle("fill", 440, 75, 25, 8)
    lurek.render.rectangle("fill", 450, 65, 8, 20)

    -- Witness stand (right)
    lurek.render.setColor(0.38, 0.24, 0.12, 1)
    lurek.render.rectangle("fill", 580, 150, 160, 120)
    lurek.render.setColor(0.45, 0.3, 0.15, 1)
    lurek.render.rectangle("fill", 590, 155, 140, 50)
    -- Witness silhouette
    if state == "TESTIMONY" or state == "QUESTION" then
        lurek.render.setColor(0.2, 0.15, 0.1, 1)
        lurek.render.circle("fill", 660, 155, 20)
        lurek.render.rectangle("fill", 645, 175, 30, 40)
    end

    -- Defense desk (left)
    lurek.render.setColor(0.38, 0.24, 0.12, 1)
    lurek.render.rectangle("fill", 40, 280, 200, 80)
    lurek.render.setColor(0.45, 0.3, 0.15, 1)
    lurek.render.rectangle("fill", 50, 285, 180, 35)
    -- Defense attorney silhouette
    lurek.render.setColor(0.1, 0.15, 0.3, 1)
    lurek.render.circle("fill", 140, 275, 18)
    lurek.render.rectangle("fill", 125, 293, 30, 40)

    -- Prosecution desk (right lower)
    lurek.render.setColor(0.38, 0.24, 0.12, 1)
    lurek.render.rectangle("fill", 540, 280, 200, 80)
    lurek.render.setColor(0.45, 0.3, 0.15, 1)
    lurek.render.rectangle("fill", 550, 285, 180, 35)
    -- Prosecutor silhouette
    lurek.render.setColor(0.3, 0.1, 0.1, 1)
    lurek.render.circle("fill", 640, 275, 18)
    lurek.render.rectangle("fill", 625, 293, 30, 40)

    -- Gallery railing
    lurek.render.setColor(0.5, 0.33, 0.18, 1)
    lurek.render.rectangle("fill", 0, 395, 800, 8)

    -- Gallery audience silhouettes
    lurek.render.setColor(0.18, 0.13, 0.1, 0.7)
    for i = 0, 9 do
        local gx = 40 + i * 75
        lurek.render.circle("fill", gx, 430, 12)
        lurek.render.rectangle("fill", gx - 10, 442, 20, 25)
    end

    -- Gavel sparks (particles)
    for _, s in ipairs(gavel_sparks) do
        local a = s.life / s.max_life
        lurek.render.setColor(1, 0.8, 0.2, a)
        lurek.render.rectangle("fill", s.x - s.size/2, s.y - s.size/2, s.size, s.size)
    end

    -- Flash effect overlay
    if flash_alpha > 0 then
        lurek.render.setColor(flash_color[1], flash_color[2], flash_color[3], flash_alpha * 0.4)
        lurek.render.rectangle("fill", 0, 0, 800, 600)
    end
end

-- Draw UI elements
function lurek.draw_ui()
    if state == "TITLE" then
        -- Title screen
        lurek.render.setColor(0.9, 0.75, 0.3, 1)
        lurek.render.print("COURTROOM DRAMA", 200, 160, 0, 2.5, 2.5)

        lurek.render.setColor(0.7, 0.55, 0.25, 1)
        lurek.render.print("ORDER IN THE COURT!", 260, 230, 0, 1.3, 1.3)

        lurek.render.setColor(0.8, 0.7, 0.5, 1)
        lurek.render.print("Present evidence. Question witnesses.", 220, 310, 0, 1, 1)
        lurek.render.print("Expose contradictions. Win the case.", 225, 335, 0, 1, 1)

        lurek.render.setColor(0.6, 0.5, 0.3, 0.6 + math.sin(lurek.timer.getTime() * 3) * 0.4)
        lurek.render.print("Press SPACE to begin", 300, 420, 0, 1, 1)

        lurek.render.setColor(0.5, 0.4, 0.3, 0.5)
        lurek.render.print("O=Objection  E=Evidence  Q=Question  1/2/3=Choose", 155, 520, 0, 0.85, 0.85)
        return
    end

    if state == "GAME_OVER" then
        if game_result == "WIN" then
            lurek.render.setColor(1, 0.85, 0.2, 1)
            lurek.render.print("CASE CLOSED!", 270, 150, 0, 2.2, 2.2)
        else
            lurek.render.setColor(0.8, 0.2, 0.15, 1)
            lurek.render.print("CASE LOST", 290, 150, 0, 2.2, 2.2)
        end

        lurek.render.setColor(0.8, 0.7, 0.5, 1)
        lurek.render.print(typewriter_text, 140, 260, 0, 1, 1)

        lurek.render.setColor(0.6, 0.5, 0.3, 0.6 + math.sin(lurek.timer.getTime() * 3) * 0.4)
        lurek.render.print("Press SPACE to return to title", 260, 420, 0, 1, 1)

        -- Confetti (particles)
        for _, c in ipairs(verdict_confetti) do
            lurek.render.setColor(c.r, c.g, c.b, 0.9)
            lurek.render.rectangle("fill", c.x, c.y, c.size, c.size)
        end
        return
    end

    -- Case info bar (top)
    lurek.render.setColor(0.1, 0.07, 0.05, 0.85)
    lurek.render.rectangle("fill", 0, 0, 800, 32)
    lurek.render.setColor(0.9, 0.75, 0.3, 1)
    lurek.render.print("Case " .. current_case .. ": " .. cases[current_case].name, 10, 8, 0, 0.9, 0.9)

    -- Jury meter bar (top right)
    local jury_x, jury_y, jury_w = 500, 6, 180
    lurek.render.setColor(0.3, 0.3, 0.3, 0.8)
    lurek.render.rectangle("fill", jury_x, jury_y, jury_w, 18)
    local fill_w = (jury_display / 100) * jury_w
    local jr = 0.2 + 0.6 * (1 - jury_display / 100)
    local jg = 0.3 + 0.7 * (jury_display / 100)
    lurek.render.setColor(jr, jg, 0.2, 1)
    lurek.render.rectangle("fill", jury_x, jury_y, fill_w, 18)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Jury: " .. math.floor(jury_display) .. "%", jury_x + 5, jury_y + 2, 0, 0.75, 0.75)

    -- Credibility bar (below jury)
    local cr_x, cr_y, cr_w = 695, 6, 95
    lurek.render.setColor(0.3, 0.3, 0.3, 0.8)
    lurek.render.rectangle("fill", cr_x, cr_y, cr_w, 18)
    local cr_fill = (cred_display / 100) * cr_w
    local cr_r = 0.2 + 0.8 * (1 - cred_display / 100)
    local cr_g = 0.8 * (cred_display / 100)
    lurek.render.setColor(cr_r, cr_g, 0.15, 1)
    lurek.render.rectangle("fill", cr_x, cr_y, cr_fill, 18)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Cred:" .. math.floor(cred_display), cr_x + 3, cr_y + 2, 0, 0.7, 0.7)

    -- Testimony line indicator
    if state == "TESTIMONY" then
        lurek.render.setColor(0.6, 0.5, 0.3, 0.7)
        lurek.render.print("Statement " .. testimony_line .. "/" .. #cases[current_case].testimony, 10, 580, 0, 0.75, 0.75)
    end

    -- Main text box
    lurek.render.setColor(0.08, 0.06, 0.04, 0.92)
    lurek.render.rectangle("fill", 40, 460, 720, 110)
    lurek.render.setColor(0.6, 0.45, 0.2, 0.8)
    lurek.render.rectangle("line", 40, 460, 720, 110)

    -- Speaker label
    if state == "TESTIMONY" and not question_mode and not objection_mode and objection_result == "" then
        lurek.render.setColor(1, 0.85, 0.3, 1)
        lurek.render.print(cases[current_case].witness .. ":", 55, 468, 0, 0.85, 0.85)
    elseif state == "CASE_INTRO" then
        lurek.render.setColor(0.8, 0.6, 0.2, 1)
        lurek.render.print("Judge:", 55, 468, 0, 0.85, 0.85)
    end

    -- Typewriter text
    lurek.render.setColor(0.9, 0.85, 0.75, 1)
    lurek.render.print(typewriter_text, 55, 490, 0, 0.9, 0.9)

    -- Advance prompt
    if #typewriter_text >= #typewriter_target and not question_mode and not objection_mode and objection_result == "" then
        lurek.render.setColor(0.5, 0.4, 0.3, 0.5 + math.sin(lurek.timer.getTime() * 4) * 0.3)
        lurek.render.print("▼", 730, 548, 0, 1, 1)
    end

    -- Question mode choices
    if question_mode then
        lurek.render.setColor(0.1, 0.08, 0.05, 0.9)
        lurek.render.rectangle("fill", 260, 300, 320, 140)
        lurek.render.setColor(0.7, 0.55, 0.25, 0.9)
        lurek.render.rectangle("line", 260, 300, 320, 140)

        lurek.render.setColor(1, 0.85, 0.3, 1)
        lurek.render.print("QUESTION WITNESS", 310, 308, 0, 1, 1)

        local questions = cases[current_case].questions
        for i = 1, math.min(3, #questions) do
            lurek.render.setColor(0.85, 0.75, 0.55, 1)
            lurek.render.print(i .. ". " .. questions[i].text, 275, 325 + (i - 1) * 28, 0, 0.7, 0.7)
        end
    end

    -- Objection mode evidence selection
    if objection_mode then
        lurek.render.setColor(0.15, 0.05, 0.02, 0.92)
        lurek.render.rectangle("fill", 180, 180, 440, 180)
        lurek.render.setColor(1, 0.4, 0.1, 0.9)
        lurek.render.rectangle("line", 180, 180, 440, 180)

        lurek.render.setColor(1, 0.5, 0.15, 1)
        lurek.render.print("PRESENT EVIDENCE", 310, 188, 0, 1.1, 1.1)

        local ev = cases[current_case].evidence
        for i = 1, math.min(3, #ev) do
            lurek.render.setColor(1, 0.9, 0.6, 1)
            lurek.render.print(i .. ". " .. ev[i].name, 200, 215 + (i - 1) * 42, 0, 0.9, 0.9)
            lurek.render.setColor(0.7, 0.6, 0.4, 0.8)
            lurek.render.print("   " .. ev[i].desc, 200, 233 + (i - 1) * 42, 0, 0.65, 0.65)
        end
    end

    -- Evidence panel (toggle)
    if show_evidence and not objection_mode then
        lurek.render.setColor(0.08, 0.06, 0.04, 0.92)
        lurek.render.rectangle("fill", 500, 40, 280, 200)
        lurek.render.setColor(0.6, 0.45, 0.2, 0.8)
        lurek.render.rectangle("line", 500, 40, 280, 200)

        lurek.render.setColor(1, 0.85, 0.3, 1)
        lurek.render.print("EVIDENCE", 590, 48, 0, 1, 1)

        local ev = cases[current_case].evidence
        for i = 1, #ev do
            lurek.render.setColor(0.9, 0.8, 0.5, 1)
            lurek.render.print(i .. ". " .. ev[i].name, 515, 68 + (i - 1) * 50, 0, 0.85, 0.85)
            lurek.render.setColor(0.65, 0.55, 0.35, 0.8)
            lurek.render.print(ev[i].desc, 525, 86 + (i - 1) * 50, 0, 0.6, 0.6)
        end
    end

    -- Controls hint
    if state == "TESTIMONY" and not question_mode and not objection_mode and objection_result == "" then
        lurek.render.setColor(0.5, 0.4, 0.3, 0.5)
        lurek.render.print("O=Object  E=Evidence  Q=Question  Space=Next", 210, 580, 0, 0.7, 0.7)
    end

    -- OBJECTION! text overlay (tweened)
    if objection_alpha > 0 then
        lurek.render.setColor(1, 0.3, 0.05, objection_alpha)
        local os_x = 400 - 80 * objection_scale
        local os_y = 200 - 15 * objection_scale
        lurek.render.print("OBJECTION!", os_x, os_y, 0, objection_scale * 1.5, objection_scale * 1.5)
    end

    -- Verdict state
    if state == "VERDICT" then
        if case_won then
            lurek.render.setColor(0.2, 0.8, 0.3, 1)
            lurek.render.print("NOT GUILTY", 270, 200, 0, 2, 2)
        else
            lurek.render.setColor(0.9, 0.2, 0.15, 1)
            lurek.render.print("GUILTY", 310, 200, 0, 2, 2)
        end

        -- Confetti (particles)
        for _, c in ipairs(verdict_confetti) do
            lurek.render.setColor(c.r, c.g, c.b, 0.9)
            lurek.render.rectangle("fill", c.x, c.y, c.size, c.size)
        end
    end
end
