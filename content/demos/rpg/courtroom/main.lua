-- Courtroom Drama / Debate Simulation
-- Present evidence, cross-examine witnesses, win cases!
-- Run with: cargo run -- content/demos/rpg/courtroom

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local state = "title"  -- State machine: title -> case_intro -> testimony -> question -> objection -> result
local current_case = 1
local testimony_idx = 1
local text_progress = 0
local credibility = 100
local jury_bar = 0
local score = 0
local selected_evidence = 1
local selected_question = 1
local show_evidence_panel = false
local flash_timer = 0
local flash_text = ""
local flash_color = {1, 1, 1}
local result_msg = ""
local cases = {}
local evidence_collected = {}

function lurek.init()
    cases = {
        {
            title = "The Missing Diamond",
            intro = "A priceless diamond vanished from the museum.\nThe security guard claims innocence.",
            witness = "Guard Bob",
            evidence = {
                { name = "Security Log",   desc = "Shows guard left post at 11:42 PM" },
                { name = "Fingerprint",    desc = "Guard's prints found on display case" },
                { name = "CCTV Footage",   desc = "Camera was disabled from 11:40-11:50" },
                { name = "Alibi Note",     desc = "Guard claims he was in bathroom" },
            },
            testimony = {
                { text = "I was at my post the entire night. Never left once.", contradiction = nil, press_reveal = "Well... maybe I stepped away briefly." },
                { text = "I never touched the display case. No reason to.", contradiction = 2, press_reveal = nil },
                { text = "The cameras were working fine all night.", contradiction = 3, press_reveal = nil },
                { text = "I stayed at my desk from 11 PM to midnight.", contradiction = 1, press_reveal = "Actually, I did use the bathroom around 11:40." },
            },
            questions = {
                { text = "Where exactly were you at 11:42 PM?", useful = true, response = "I... I was... at my post. Yes." },
                { text = "Do you usually touch the displays?", useful = false, response = "Never. That's not my job." },
                { text = "Who else had access that night?", useful = true, response = "Only me and the janitor. But the janitor left at 10." },
            },
        },
        {
            title = "The Poisoned Cake",
            intro = "A birthday cake was laced with sleeping pills.\nThe baker insists it wasn't her.",
            witness = "Baker Alice",
            evidence = {
                { name = "Pill Bottle",    desc = "Prescription sleeping pills, Alice's name" },
                { name = "Receipt",        desc = "Alice bought extra sugar that morning" },
                { name = "Kitchen Photo",  desc = "Shows pill residue near mixing bowl" },
                { name = "Text Messages",  desc = "Alice texted 'it will be done tonight'" },
            },
            testimony = {
                { text = "I baked the cake exactly as ordered. Vanilla and cream.", contradiction = nil, press_reveal = "I did add a special ingredient — love!" },
                { text = "I don't own any sleeping pills or medication.", contradiction = 1, press_reveal = nil },
                { text = "My kitchen was spotless. Nothing unusual.", contradiction = 3, press_reveal = nil },
                { text = "I had no contact with the victim that day.", contradiction = 4, press_reveal = "Well, I did text them about the party..." },
            },
            questions = {
                { text = "What exactly was in the cake?", useful = true, response = "Flour, eggs, sugar, vanilla... the usual." },
                { text = "Did anyone else enter your kitchen?", useful = true, response = "My assistant was there earlier, but left at noon." },
                { text = "Why did you buy extra sugar?", useful = false, response = "I was running low. Normal restocking." },
            },
        },
        {
            title = "The Forged Painting",
            intro = "A gallery sold a forgery for $2 million.\nThe art dealer claims he didn't know.",
            witness = "Dealer Victor",
            evidence = {
                { name = "Expert Report",   desc = "Paint contains modern synthetic pigments" },
                { name = "Bank Records",    desc = "Victor received $50K from unknown source" },
                { name = "Email Chain",     desc = "Victor wrote 'the client won't notice'" },
                { name = "Original Photo",  desc = "Real painting is 3 inches shorter" },
            },
            testimony = {
                { text = "I acquired the painting from a reputable auction house.", contradiction = nil, press_reveal = "Well, it was more of a private sale..." },
                { text = "I had the painting authenticated by professionals.", contradiction = 1, press_reveal = nil },
                { text = "I've never received any suspicious payments.", contradiction = 2, press_reveal = nil },
                { text = "I genuinely believed this was the real masterpiece.", contradiction = 3, press_reveal = "I had some doubts but trusted my source." },
            },
            questions = {
                { text = "Who authenticated the painting?", useful = true, response = "A colleague of mine... who I trust deeply." },
                { text = "How long have you been dealing art?", useful = false, response = "Twenty years. Spotless record." },
                { text = "Where is the original now?", useful = true, response = "I... don't know. That's not my problem." },
            },
        },
    }
    reset_case()
end

function reset_case()
    testimony_idx = 1
    text_progress = 0
    credibility = 100
    jury_bar = 0
    selected_evidence = 1
    selected_question = 1
    show_evidence_panel = false
    flash_timer = 0
    evidence_collected = {}
    local c = cases[current_case]
    for i, ev in ipairs(c.evidence) do
        evidence_collected[i] = true
    end
end

local function flash(txt, r, g, b)
    flash_text = txt
    flash_timer = 1.5
    flash_color = {r, g, b}
end

local function current_testimony()
    local c = cases[current_case]
    if testimony_idx <= #c.testimony then
        return c.testimony[testimony_idx]
    end
    return nil
end

local function advance_testimony()
    local c = cases[current_case]
    testimony_idx = testimony_idx + 1
    text_progress = 0
    if testimony_idx > #c.testimony then
        -- Check win/lose
        if jury_bar >= 100 then
            result_msg = "GUILTY! You won the case!"
            score = score + 1
        else
            result_msg = "NOT GUILTY. The defendant walks free."
        end
        state = "result"
    end
end

function lurek.process(dt)
    if flash_timer > 0 then flash_timer = flash_timer - dt end
    if state == "testimony" then
        local t = current_testimony()
        if t then
            local full_len = #t.text
            if text_progress < full_len then
                text_progress = text_progress + dt * 40
                if text_progress > full_len then text_progress = full_len end
            end
        end
    end
end

function lurek.keypressed(key)
    if state == "title" then
        if key == "return" then
            state = "case_intro"
        elseif key == "escape" then
            lurek.signal.quit()
        end
    elseif state == "case_intro" then
        if key == "return" then
            state = "testimony"
        end
    elseif state == "testimony" then
        if key == "e" then
            show_evidence_panel = not show_evidence_panel
        elseif key == "p" then
            -- Press witness
            local t = current_testimony()
            if t and t.press_reveal then
                flash("PRESS: " .. t.press_reveal, 1, 1, 0.5)
                t.press_reveal = nil
            else
                flash("Nothing new revealed.", 0.7, 0.7, 0.7)
            end
        elseif show_evidence_panel then
            local c = cases[current_case]
            if key == "up" then
                selected_evidence = selected_evidence - 1
                if selected_evidence < 1 then selected_evidence = #c.evidence end
            elseif key == "down" then
                selected_evidence = selected_evidence + 1
                if selected_evidence > #c.evidence then selected_evidence = 1 end
            elseif key == "return" then
                -- Present evidence
                local t = current_testimony()
                if t then
                    if t.contradiction == selected_evidence then
                        flash("OBJECTION! Evidence contradicts testimony!", 1, 0.3, 0.1)
                        jury_bar = jury_bar + 35
                        show_evidence_panel = false
                        advance_testimony()
                    else
                        flash("Irrelevant evidence! Credibility -15", 0.8, 0.2, 0.2)
                        credibility = credibility - 15
                        show_evidence_panel = false
                        if credibility <= 0 then
                            result_msg = "You lost all credibility! Case dismissed."
                            state = "result"
                        end
                    end
                end
            end
        elseif key == "return" then
            advance_testimony()
        elseif key == "q" then
            state = "question"
        end
    elseif state == "question" then
        local c = cases[current_case]
        if key == "up" then
            selected_question = selected_question - 1
            if selected_question < 1 then selected_question = #c.questions end
        elseif key == "down" then
            selected_question = selected_question + 1
            if selected_question > #c.questions then selected_question = 1 end
        elseif key == "return" then
            local q = c.questions[selected_question]
            if q.useful then
                flash(c.witness .. ": " .. q.response, 0.8, 1, 0.8)
                jury_bar = jury_bar + 10
            else
                flash(c.witness .. ": " .. q.response, 0.7, 0.7, 0.7)
            end
            state = "testimony"
        elseif key == "escape" then
            state = "testimony"
        end
    elseif state == "result" then
        if key == "return" then
            current_case = current_case + 1
            if current_case > #cases then
                state = "title"
                current_case = 1
                score = 0
            else
                reset_case()
                state = "case_intro"
            end
        end
    end
end

local function draw_bar(label, x, y, w, h, value, max, r, g, b)
    lurek.render.setColor(0.2, 0.2, 0.2, 1)
    lurek.render.rectangle("fill", x, y, w, h)
    local pct = clamp(value / max, 0, 1)
    lurek.render.setColor(r, g, b, 1)
    lurek.render.rectangle("fill", x, y, w * pct, h)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print(label .. ": " .. math.floor(value) .. "/" .. max, x, y - 16, 0.7)
end

function lurek.render()
    lurek.render.setBackgroundColor(0.08, 0.06, 0.12)

    if state == "title" then
        lurek.render.setColor(1, 0.85, 0.3, 1)
        lurek.render.print("COURTROOM DRAMA", 200, 120, 2)
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
        lurek.render.print("Present evidence. Cross-examine witnesses.", 200, 200, 1)
        lurek.render.print("Win 3 cases to become a legendary attorney!", 200, 230, 1)
        lurek.render.setColor(0.6, 1, 0.6, 1)
        lurek.render.print("Press ENTER to begin", 260, 320, 1.2)
        return
    end

    local c = cases[current_case]

    if state == "case_intro" then
        lurek.render.setColor(1, 0.8, 0.3, 1)
        lurek.render.print("Case " .. current_case .. ": " .. c.title, 150, 100, 1.5)
        lurek.render.setColor(0.9, 0.9, 0.9, 1)
        lurek.render.print(c.intro, 150, 180, 1)
        lurek.render.setColor(0.8, 0.8, 0.6, 1)
        lurek.render.print("Witness: " .. c.witness, 150, 260, 1)
        lurek.render.setColor(0.5, 1, 0.5, 1)
        lurek.render.print("Press ENTER to start cross-examination", 150, 340, 1)
        return
    end

    if state == "result" then
        lurek.render.setColor(1, 1, 0.5, 1)
        lurek.render.print("VERDICT", 300, 100, 2)
        lurek.render.setColor(0.9, 0.9, 0.9, 1)
        lurek.render.print(result_msg, 150, 200, 1.2)
        lurek.render.print("Score: " .. score .. " / " .. #cases, 150, 260, 1)
        lurek.render.setColor(0.5, 1, 0.5, 1)
        lurek.render.print("Press ENTER to continue", 220, 340, 1)
        return
    end

    -- Courtroom scene
    -- Judge bench
    lurek.render.setColor(0.35, 0.2, 0.1, 1)
    lurek.render.rectangle("fill", 250, 20, 300, 50)
    lurek.render.setColor(1, 0.9, 0.7, 1)
    lurek.render.print("JUDGE", 370, 30, 1)

    -- Witness stand
    lurek.render.setColor(0.3, 0.25, 0.15, 1)
    lurek.render.rectangle("fill", 550, 90, 120, 40)
    lurek.render.setColor(0.9, 0.8, 0.6, 1)
    lurek.render.print(c.witness, 560, 100, 0.7)

    -- Bars
    draw_bar("Credibility", 20, 30, 180, 14, credibility, 100, 0.2, 0.7, 1)
    draw_bar("Jury Persuasion", 20, 65, 180, 14, jury_bar, 100, 0.2, 0.9, 0.3)

    -- Testimony
    if state == "testimony" then
        local t = current_testimony()
        if t then
            lurek.render.setColor(0.15, 0.12, 0.2, 1)
            lurek.render.rectangle("fill", 30, 150, 540, 80)
            lurek.render.setColor(0.25, 0.2, 0.3, 1)
            lurek.render.rectangle("line", 30, 150, 540, 80)
            lurek.render.setColor(1, 0.9, 0.7, 1)
            lurek.render.print(c.witness .. " (" .. testimony_idx .. "/" .. #c.testimony .. "):", 40, 155, 0.8)
            local visible = string.sub(t.text, 1, math.floor(text_progress))
            lurek.render.setColor(1, 1, 1, 1)
            lurek.render.print('"' .. visible .. '"', 40, 180, 0.9)
        end
    end

    -- Evidence panel
    if show_evidence_panel and state == "testimony" then
        lurek.render.setColor(0.1, 0.1, 0.18, 0.95)
        lurek.render.rectangle("fill", 20, 250, 300, 150)
        lurek.render.setColor(0.4, 0.4, 0.6, 1)
        lurek.render.rectangle("line", 20, 250, 300, 150)
        lurek.render.setColor(1, 0.85, 0.4, 1)
        lurek.render.print("Evidence (Up/Down, Enter to present):", 30, 255, 0.75)
        for i, ev in ipairs(c.evidence) do
            local ey = 275 + (i - 1) * 28
            if i == selected_evidence then
                lurek.render.setColor(0.3, 0.3, 0.5, 1)
                lurek.render.rectangle("fill", 25, ey - 2, 290, 24)
                lurek.render.setColor(1, 1, 0.6, 1)
            else
                lurek.render.setColor(0.7, 0.7, 0.7, 1)
            end
            lurek.render.print(i .. ". " .. ev.name .. " — " .. ev.desc, 35, ey, 0.65)
        end
    end

    -- Question menu
    if state == "question" then
        lurek.render.setColor(0.1, 0.1, 0.18, 0.95)
        lurek.render.rectangle("fill", 20, 250, 500, 130)
        lurek.render.setColor(1, 0.85, 0.4, 1)
        lurek.render.print("Cross-examine (Up/Down, Enter):", 30, 255, 0.8)
        for i, q in ipairs(c.questions) do
            local qy = 280 + (i - 1) * 30
            if i == selected_question then
                lurek.render.setColor(0.3, 0.3, 0.5, 1)
                lurek.render.rectangle("fill", 25, qy - 2, 490, 26)
                lurek.render.setColor(1, 1, 0.6, 1)
            else
                lurek.render.setColor(0.8, 0.8, 0.8, 1)
            end
            lurek.render.print(q.text, 35, qy, 0.8)
        end
    end

    -- Controls
    lurek.render.setColor(0.5, 0.5, 0.5, 1)
    lurek.render.print("E=evidence | P=press | Q=question | Enter=next | Esc=quit", 30, 450, 0.65)
    lurek.render.print("Case " .. current_case .. "/" .. #cases .. "  |  Testimony " .. testimony_idx .. "/" .. #c.testimony, 30, 435, 0.65)

    -- Flash
    if flash_timer > 0 then
        local a = clamp(flash_timer, 0, 1)
        lurek.render.setColor(0, 0, 0, 0.7 * a)
        lurek.render.rectangle("fill", 50, 400, 700, 35)
        lurek.render.setColor(flash_color[1], flash_color[2], flash_color[3], a)
        lurek.render.print(flash_text, 60, 405, 0.85)
    end

    lurek.render.setColor(0.5, 0.5, 0.5, 1)
    lurek.render.print("FPS: " .. lurek.time.getFPS(), 700, 5, 0.6)
end
