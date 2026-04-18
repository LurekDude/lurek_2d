-- ============================================================================
-- Dialog Demo — Complete dialog/conversation system with branching choices
-- Category: rpg
-- Engine:   Lurek2D
-- Controls: space(advance) 1/2/3(choices) tab(auto-advance) s(skip) escape(quit)
-- States:   TITLE → DIALOG → CHOICE → FINISHED
-- ============================================================================

-- Action input mapping
local actions = {
    advance = "space",
    choice1 = "1",
    choice2 = "2",
    choice3 = "3",
    auto    = "tab",
    skip    = "s",
    quit    = "escape",
}

-- ── constants ─────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 800, 600
local TYPEWRITER_SPEED = 1 / 25
local AUTO_ADVANCE_DELAY = 2.0
local LOG_MAX = 8
local DIALOG_BOX_Y = 420
local DIALOG_BOX_H = 160

-- Speaker color palette
local SPEAKER_COLORS = {
    Sage     = {0.3, 0.6, 1.0},
    Merchant = {1.0, 0.8, 0.2},
    Guard    = {1.0, 0.3, 0.25},
    System   = {0.7, 0.7, 0.7},
}

-- ── state ─────────────────────────────────────────────────────
local state = "TITLE"
local dialog_nodes = {}
local node_index = 1
local typewriter_text = ""
local typewriter_target = ""
local typewriter_timer = 0
local current_speaker = ""
local current_speaker_color = {1, 1, 1}
local dialog_log = {}
local choice_options = {}
local choice_selected = 1
local choice_pulse = 0
local auto_advance = false
local auto_timer = 0
local text_fade_alpha = 0
local scene_name = "forest"
local relationships = { sage = 0, merchant = 0, guard = 0 }
local flags = {}
local bubble_particles = {}
local sparkle_particles = {}
local title_alpha = 0
local title_prompt_alpha = 0
local fps_visible = true

-- ── dialog node constructors ──────────────────────────────────
local function say(speaker, text, next_id)
    return { type = "say", speaker = speaker, text = text, next_id = next_id }
end

local function choice(speaker, prompt, options)
    return { type = "choice", speaker = speaker, prompt = prompt, options = options }
end

local function wait(seconds, next_id)
    return { type = "wait", seconds = seconds, next_id = next_id, elapsed = 0 }
end

local function event(callback, next_id)
    return { type = "event", callback = callback, next_id = next_id }
end

-- ── particle helpers ──────────────────────────────────────────
local function spawn_bubble(x, y)
    for i = 1, 6 do
        table.insert(bubble_particles, {
            x = x + math.random(-20, 20),
            y = y + math.random(-10, 10),
            vy = -math.random(30, 70),
            vx = math.random(-15, 15),
            life = 0.6 + math.random() * 0.4,
            max_life = 1.0,
            size = math.random(3, 6),
            alpha = 0.8,
        })
    end
end

local function spawn_sparkle(x, y)
    for i = 1, 12 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(40, 120)
        table.insert(sparkle_particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.4 + math.random() * 0.3,
            max_life = 0.7,
            size = math.random(2, 5),
            r = 1.0,
            g = 0.85 + math.random() * 0.15,
            b = 0.3 + math.random() * 0.3,
        })
    end
end

-- ── typewriter helpers ────────────────────────────────────────
local function set_typewriter(text)
    typewriter_target = text
    typewriter_text = ""
    typewriter_timer = 0
    text_fade_alpha = 0
end

local function typewriter_done()
    return #typewriter_text >= #typewriter_target
end

local function skip_typewriter()
    typewriter_text = typewriter_target
    text_fade_alpha = 1
end

-- ── dialog log ────────────────────────────────────────────────
local function add_to_log(speaker, text)
    table.insert(dialog_log, { speaker = speaker, text = text })
    while #dialog_log > LOG_MAX do
        table.remove(dialog_log, 1)
    end
end

-- ── conversation data ─────────────────────────────────────────
local function build_conversation()
    local nodes = {}

    -- Scene 1: Forest — Meet the Sage
    nodes[1]  = event(function() scene_name = "forest" end, 2)
    nodes[2]  = say("Sage", "Ah, a traveler. The forest has been expecting you.", 3)
    nodes[3]  = say("Sage", "I am the Sage of these woods. I sense many questions within you.", 4)
    nodes[4]  = choice("Sage", "What would you like to know?", {
        { text = "Tell me about the merchant in town.", next_id = 5 },
        { text = "What dangers lie ahead at the gate?", next_id = 10 },
        { text = "I seek wisdom, nothing more.", next_id = 15 },
    })

    -- Branch: Ask about merchant
    nodes[5]  = event(function() relationships.sage = relationships.sage + 1; flags.asked_merchant = true end, 6)
    nodes[6]  = say("Sage", "The merchant is shrewd but fair. Approach with respect.", 7)
    nodes[7]  = say("Sage", "He values honesty above all. Remember that.", 8)
    nodes[8]  = wait(0.5, 9)
    nodes[9]  = say("Sage", "Go now. The path to town lies east. Safe travels.", 20)

    -- Branch: Ask about the gate
    nodes[10] = event(function() relationships.sage = relationships.sage + 1; flags.asked_gate = true end, 11)
    nodes[11] = say("Sage", "The eastern gate is guarded by a stern warrior.", 12)
    nodes[12] = say("Sage", "He trusts no one easily. But there are ways to earn his respect.", 13)
    nodes[13] = say("Sage", "Show courage, not aggression. Words can open doors that swords cannot.", 14)
    nodes[14] = wait(0.5, 20)

    -- Branch: Seek wisdom
    nodes[15] = event(function() relationships.sage = relationships.sage + 2; flags.sought_wisdom = true end, 16)
    nodes[16] = say("Sage", "Wisdom... a rare request from one so young.", 17)
    nodes[17] = say("Sage", "The world is shaped by choices. Every fork in the road defines you.", 18)
    nodes[18] = say("Sage", "Remember: patience reveals truth, haste invites ruin.", 19)
    nodes[19] = wait(0.8, 20)

    -- Scene 2: Shop — Meet the Merchant
    nodes[20] = event(function() scene_name = "shop" end, 21)
    nodes[21] = say("Merchant", "Welcome, welcome! Step inside, friend!", 22)

    if flags.asked_merchant then
        nodes[22] = say("Merchant", "Hmm, the Sage sent you? Then you must be worth my time.", 23)
    else
        nodes[22] = say("Merchant", "A new face! I do hope you have coin to spend.", 23)
    end

    nodes[23] = say("Merchant", "I have the finest goods this side of the mountain.", 24)
    nodes[24] = choice("Merchant", "What catches your eye?", {
        { text = "I need a sturdy shield for the road.", next_id = 25 },
        { text = "Do you have any rare potions?", next_id = 30 },
        { text = "Actually, I just want information.", next_id = 35 },
    })

    -- Branch: Buy shield
    nodes[25] = say("Merchant", "Ah, a practical choice! This oak shield has seen many battles.", 26)
    nodes[26] = choice("Merchant", "Fifty gold pieces. What say you?", {
        { text = "Deal! I'll take it.", next_id = 27 },
        { text = "Too steep. How about thirty?", next_id = 28 },
    })
    nodes[27] = event(function() relationships.merchant = relationships.merchant + 1; flags.bought_shield = true end, 29)
    nodes[28] = event(function() relationships.merchant = relationships.merchant - 1; flags.haggled = true end, 29)
    nodes[29] = say("Merchant", "Pleasure doing business. Safe travels, friend!", 40)

    -- Branch: Potions
    nodes[30] = say("Merchant", "Potions? Now we are talking! I have three in stock.", 31)
    nodes[31] = say("Merchant", "A healing draught, a potion of courage, and... liquid luck.", 32)
    nodes[32] = choice("Merchant", "Which interests you?", {
        { text = "The healing draught, please.", next_id = 33 },
        { text = "Liquid luck sounds useful.", next_id = 34 },
    })
    nodes[33] = event(function() relationships.merchant = relationships.merchant + 1; flags.got_healing = true end, 39)
    nodes[34] = event(function() relationships.merchant = relationships.merchant + 1; flags.got_luck = true end, 39)

    -- Branch: Information
    nodes[35] = say("Merchant", "Information? Hmm, that costs too, you know.", 36)
    nodes[36] = say("Merchant", "But since you seem earnest... the guard at the gate has a weakness.", 37)
    nodes[37] = say("Merchant", "He respects those who speak plainly. No flattery, no tricks.", 38)
    nodes[38] = event(function() relationships.merchant = relationships.merchant + 2; flags.merchant_info = true end, 40)

    nodes[39] = say("Merchant", "A fine choice! Use it wisely.", 40)

    -- Scene 3: Gate — Encounter the Guard
    nodes[40] = event(function() scene_name = "gate" end, 41)
    nodes[41] = say("Guard", "Halt! No one passes without my say-so.", 42)

    if flags.asked_gate or flags.merchant_info then
        nodes[42] = say("Guard", "...Wait. You carry yourself differently than most travelers.", 43)
    else
        nodes[42] = say("Guard", "State your business. Quickly.", 43)
    end

    nodes[43] = choice("Guard", "The guard blocks your path. What do you do?", {
        { text = "I mean no harm. I seek passage peacefully.", next_id = 44 },
        { text = "Step aside, or face the consequences.", next_id = 50 },
        { text = "The Sage and Merchant both vouch for me.", next_id = 55 },
    })

    -- Branch: Peaceful
    nodes[44] = say("Guard", "Peaceful, you say? Words are cheap.", 45)
    nodes[45] = choice("Guard", "Prove your sincerity.", {
        { text = "I have traveled far and helped many along the way.", next_id = 46 },
        { text = "Search me. I carry no weapons of war.", next_id = 48 },
    })
    nodes[46] = event(function() relationships.guard = relationships.guard + 1 end, 47)
    nodes[47] = say("Guard", "...Very well. Your eyes tell no lies. You may pass.", 60)
    nodes[48] = event(function() relationships.guard = relationships.guard + 2 end, 49)
    nodes[49] = say("Guard", "Bold move. Honest, too. Proceed.", 60)

    -- Branch: Threaten
    nodes[50] = say("Guard", "HA! You dare threaten ME?", 51)
    nodes[51] = event(function() relationships.guard = relationships.guard - 3 end, 52)
    nodes[52] = say("Guard", "I've dealt with a hundred fools braver than you.", 53)
    nodes[53] = say("Guard", "...But you have spirit. I'll grant you that.", 54)
    nodes[54] = say("Guard", "Fine. Pass. But watch yourself inside the walls.", 60)

    -- Branch: Vouch
    nodes[55] = say("Guard", "The Sage AND the Merchant? That's... unusual.", 56)
    if flags.sought_wisdom and (flags.merchant_info or flags.bought_shield) then
        nodes[56] = event(function() relationships.guard = relationships.guard + 3 end, 57)
        nodes[57] = say("Guard", "If they both trust you... then perhaps I should as well.", 58)
        nodes[58] = say("Guard", "Welcome, traveler. The city gates are open to you.", 60)
    else
        nodes[56] = say("Guard", "I need more than names. But you've piqued my interest.", 57)
        nodes[57] = event(function() relationships.guard = relationships.guard + 1 end, 58)
        nodes[58] = say("Guard", "Fine. Enter. But I'll be watching.", 60)
    end

    -- Finale
    nodes[59] = wait(0.5, 60)
    nodes[60] = event(function() scene_name = "gate" end, 61)
    nodes[61] = say("System", "Your journey through the gate is complete.", 62)
    nodes[62] = say("System", string.format("Relationships — Sage: %+d  Merchant: %+d  Guard: %+d",
        relationships.sage, relationships.merchant, relationships.guard), 63)

    local total = relationships.sage + relationships.merchant + relationships.guard
    if total >= 5 then
        nodes[63] = say("System", "The people trust you. A bright future awaits beyond the walls.", 64)
    elseif total >= 0 then
        nodes[63] = say("System", "You made your way through, though not all were convinced.", 64)
    else
        nodes[63] = say("System", "Suspicion follows you. The road ahead will not be easy.", 64)
    end

    nodes[64] = say("System", "Thank you for playing the Dialog Demo!", -1)

    return nodes
end

-- ── process current node ──────────────────────────────────────
local function process_node()
    local node = dialog_nodes[node_index]
    if not node then
        state = "FINISHED"
        return
    end

    if node.type == "say" then
        state = "DIALOG"
        current_speaker = node.speaker
        current_speaker_color = SPEAKER_COLORS[node.speaker] or {1, 1, 1}
        set_typewriter(node.text)
        spawn_bubble(120, DIALOG_BOX_Y - 10)

    elseif node.type == "choice" then
        state = "CHOICE"
        current_speaker = node.speaker
        current_speaker_color = SPEAKER_COLORS[node.speaker] or {1, 1, 1}
        set_typewriter(node.prompt)
        choice_options = node.options
        choice_selected = 1
        choice_pulse = 0

    elseif node.type == "wait" then
        node.elapsed = 0
        state = "DIALOG"

    elseif node.type == "event" then
        node.callback()
        if node.next_id == -1 then
            state = "FINISHED"
        else
            node_index = node.next_id
            process_node()
        end
    end
end

-- ── advance dialog ────────────────────────────────────────────
local function advance_dialog()
    local node = dialog_nodes[node_index]
    if not node then state = "FINISHED"; return end

    if node.type == "say" then
        add_to_log(node.speaker, node.text)
        if node.next_id == -1 then
            state = "FINISHED"
        else
            node_index = node.next_id
            process_node()
        end

    elseif node.type == "wait" then
        if node.next_id == -1 then
            state = "FINISHED"
        else
            node_index = node.next_id
            process_node()
        end
    end
end

-- ── select choice ─────────────────────────────────────────────
local function select_choice(idx)
    local node = dialog_nodes[node_index]
    if not node or node.type ~= "choice" then return end
    if idx < 1 or idx > #node.options then return end

    local opt = node.options[idx]
    add_to_log(current_speaker, node.prompt)
    add_to_log("You", opt.text)
    spawn_sparkle(SCREEN_W / 2, DIALOG_BOX_Y + 30 + idx * 28)

    if opt.next_id == -1 then
        state = "FINISHED"
    else
        node_index = opt.next_id
        process_node()
    end
end

-- ── lurek.init ────────────────────────────────────────────────
lurek.init(function()
    lurek.window.setTitle("Dialog Demo — Lurek2D")
    lurek.gfx.setBackgroundColor(0.1, 0.1, 0.15)
    title_alpha = 0
    title_prompt_alpha = 0
end)

-- ── lurek.ready ───────────────────────────────────────────────
lurek.ready(function()
end)

-- ── lurek.process ─────────────────────────────────────────────
lurek.process(function(dt)
    -- FPS display
    if lurek.input.isPressed("f3") then fps_visible = not fps_visible end

    -- Typewriter update
    if #typewriter_text < #typewriter_target then
        typewriter_timer = typewriter_timer + dt
        while typewriter_timer >= TYPEWRITER_SPEED and #typewriter_text < #typewriter_target do
            typewriter_timer = typewriter_timer - TYPEWRITER_SPEED
            typewriter_text = string.sub(typewriter_target, 1, #typewriter_text + 1)
        end
        text_fade_alpha = math.min(text_fade_alpha + dt * 4, 1)
    else
        text_fade_alpha = math.min(text_fade_alpha + dt * 4, 1)
    end

    -- Choice highlight pulse (tween-like)
    choice_pulse = choice_pulse + dt * 4
    if choice_pulse > math.pi * 2 then choice_pulse = choice_pulse - math.pi * 2 end

    -- Update particles: bubbles
    for i = #bubble_particles, 1, -1 do
        local p = bubble_particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.alpha = p.life / p.max_life * 0.6
        if p.life <= 0 then table.remove(bubble_particles, i) end
    end

    -- Update particles: sparkles
    for i = #sparkle_particles, 1, -1 do
        local p = sparkle_particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 100 * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(sparkle_particles, i) end
    end

    -- Title state
    if state == "TITLE" then
        title_alpha = math.min(title_alpha + dt * 2, 1)
        title_prompt_alpha = 0.5 + math.sin(lurek.timer.getTime() * 3) * 0.4
        if lurek.input.isPressed("return") then
            state = "DIALOG"
            relationships = { sage = 0, merchant = 0, guard = 0 }
            flags = {}
            dialog_log = {}
            node_index = 1
            dialog_nodes = build_conversation()
            process_node()
        end
        return
    end

    -- Quit
    if lurek.input.isPressed(actions.quit) then lurek.signal.quit() end

    -- Skip typewriter
    if lurek.input.isPressed(actions.skip) then
        skip_typewriter()
    end

    -- Auto advance toggle
    if lurek.input.isPressed(actions.auto) then
        auto_advance = not auto_advance
        auto_timer = 0
    end

    -- Wait node processing
    local node = dialog_nodes[node_index]
    if node and node.type == "wait" then
        node.elapsed = (node.elapsed or 0) + dt
        if node.elapsed >= node.seconds then
            advance_dialog()
        end
        return
    end

    -- State: DIALOG
    if state == "DIALOG" then
        if typewriter_done() then
            if auto_advance then
                auto_timer = auto_timer + dt
                if auto_timer >= AUTO_ADVANCE_DELAY then
                    auto_timer = 0
                    advance_dialog()
                end
            end
            if lurek.input.isPressed(actions.advance) then
                auto_timer = 0
                advance_dialog()
            end
        end

    -- State: CHOICE
    elseif state == "CHOICE" then
        if lurek.input.isPressed(actions.choice1) then select_choice(1) end
        if lurek.input.isPressed(actions.choice2) then select_choice(2) end
        if lurek.input.isPressed(actions.choice3) then select_choice(3) end

    -- State: FINISHED
    elseif state == "FINISHED" then
        if lurek.input.isPressed(actions.advance) then
            state = "TITLE"
            title_alpha = 0
        end
    end
end)

-- ── lurek.render — background scenes ──────────────────────────
lurek.render(function()
    if state == "TITLE" then return end

    if scene_name == "forest" then
        -- Sky gradient
        lurek.render.setColor(0.08, 0.12, 0.22, 1)
        lurek.render.drawRect("fill", 0, 0, SCREEN_W, SCREEN_H)
        -- Ground
        lurek.render.setColor(0.12, 0.25, 0.1, 1)
        lurek.render.drawRect("fill", 0, 340, SCREEN_W, 260)
        -- Trees
        for i = 0, 6 do
            local tx = 50 + i * 120
            -- Trunk
            lurek.render.setColor(0.3, 0.2, 0.1, 1)
            lurek.render.drawRect("fill", tx - 8, 220, 16, 120)
            -- Canopy
            lurek.render.setColor(0.1, 0.35 + i * 0.02, 0.12, 1)
            lurek.render.drawCircle("fill", tx, 200, 40)
            lurek.render.drawCircle("fill", tx - 25, 220, 30)
            lurek.render.drawCircle("fill", tx + 25, 220, 30)
        end
        -- Path
        lurek.render.setColor(0.25, 0.2, 0.12, 1)
        lurek.render.drawRect("fill", 320, 340, 160, 260)
        -- Fireflies
        local t = lurek.timer.getTime()
        for i = 1, 5 do
            local fx = 100 + i * 130 + math.sin(t * 0.8 + i) * 30
            local fy = 180 + math.cos(t * 1.1 + i * 2) * 40
            lurek.render.setColor(0.9, 1.0, 0.4, 0.4 + math.sin(t * 3 + i) * 0.3)
            lurek.render.drawCircle("fill", fx, fy, 3)
        end

    elseif scene_name == "shop" then
        -- Indoor walls
        lurek.render.setColor(0.22, 0.16, 0.1, 1)
        lurek.render.drawRect("fill", 0, 0, SCREEN_W, SCREEN_H)
        -- Floor
        lurek.render.setColor(0.3, 0.22, 0.12, 1)
        lurek.render.drawRect("fill", 0, 350, SCREEN_W, 250)
        -- Shelves
        for i = 0, 3 do
            local sx = 60 + i * 190
            lurek.render.setColor(0.4, 0.28, 0.15, 1)
            lurek.render.drawRect("fill", sx, 100, 120, 12)
            lurek.render.drawRect("fill", sx, 180, 120, 12)
            lurek.render.drawRect("fill", sx, 260, 120, 12)
            -- Items on shelves
            for j = 0, 2 do
                lurek.render.setColor(0.5 + j * 0.15, 0.3, 0.2, 1)
                lurek.render.drawRect("fill", sx + 10 + j * 35, 85, 20, 15)
                lurek.render.setColor(0.3, 0.5 + j * 0.1, 0.2, 1)
                lurek.render.drawRect("fill", sx + 10 + j * 35, 165, 18, 15)
            end
        end
        -- Counter
        lurek.render.setColor(0.45, 0.3, 0.15, 1)
        lurek.render.drawRect("fill", 200, 310, 400, 40)
        lurek.render.setColor(0.5, 0.35, 0.18, 1)
        lurek.render.drawRect("fill", 210, 315, 380, 30)
        -- Lantern glow
        local t = lurek.timer.getTime()
        local glow = 0.15 + math.sin(t * 2) * 0.05
        lurek.render.setColor(1, 0.8, 0.3, glow)
        lurek.render.drawCircle("fill", 400, 60, 80)

    elseif scene_name == "gate" then
        -- Dusk sky
        lurek.render.setColor(0.15, 0.08, 0.18, 1)
        lurek.render.drawRect("fill", 0, 0, SCREEN_W, SCREEN_H)
        -- Ground
        lurek.render.setColor(0.2, 0.18, 0.12, 1)
        lurek.render.drawRect("fill", 0, 360, SCREEN_W, 240)
        -- Wall
        lurek.render.setColor(0.35, 0.3, 0.25, 1)
        lurek.render.drawRect("fill", 0, 100, 300, 260)
        lurek.render.drawRect("fill", 500, 100, 300, 260)
        -- Gate arch
        lurek.render.setColor(0.25, 0.2, 0.15, 1)
        lurek.render.drawRect("fill", 300, 100, 200, 40)
        -- Gate opening
        lurek.render.setColor(0.05, 0.03, 0.08, 1)
        lurek.render.drawRect("fill", 320, 140, 160, 220)
        -- Torches
        for _, tx in ipairs({280, 520}) do
            lurek.render.setColor(0.4, 0.25, 0.1, 1)
            lurek.render.drawRect("fill", tx - 4, 140, 8, 50)
            local t = lurek.timer.getTime()
            local flicker = 0.7 + math.sin(t * 6 + tx) * 0.3
            lurek.render.setColor(1, 0.6, 0.15, flicker)
            lurek.render.drawCircle("fill", tx, 132, 12)
            lurek.render.setColor(1, 0.9, 0.3, flicker * 0.5)
            lurek.render.drawCircle("fill", tx, 132, 20)
        end
        -- Stars
        local t = lurek.timer.getTime()
        for i = 1, 8 do
            local sx = 50 + i * 95
            local sy = 20 + (i % 3) * 25
            lurek.render.setColor(1, 1, 0.9, 0.3 + math.sin(t * 2 + i) * 0.2)
            lurek.render.drawCircle("fill", sx, sy, 2)
        end
    end
end)

-- ── lurek.render_ui — dialog box, speakers, choices, log ──────
lurek.render_ui(function()
    local t = lurek.timer.getTime()

    -- FPS counter
    if fps_visible then
        lurek.render.setColor(0.6, 0.6, 0.6, 0.5)
        lurek.render.print(string.format("FPS: %d", lurek.timer.getFPS()), 10, 10)
    end

    -- Title screen
    if state == "TITLE" then
        lurek.render.setColor(0.3, 0.5, 1, title_alpha)
        lurek.render.print("DIALOG DEMO", 240, 180, 0, 3, 3)

        lurek.render.setColor(0.6, 0.7, 0.9, title_alpha * 0.8)
        lurek.render.print("A branching conversation system", 230, 260, 0, 1, 1)

        lurek.render.setColor(0.8, 0.85, 1, title_prompt_alpha)
        lurek.render.print("PRESS ENTER", 330, 380, 0, 1.2, 1.2)

        lurek.render.setColor(0.5, 0.5, 0.6, title_alpha * 0.5)
        lurek.render.print("Space=Advance  1/2/3=Choose  Tab=Auto  S=Skip", 170, 500, 0, 0.85, 0.85)
        return
    end

    -- Finished screen
    if state == "FINISHED" then
        lurek.render.setColor(0.3, 0.5, 1, 1)
        lurek.render.print("JOURNEY COMPLETE", 220, 200, 0, 2, 2)
        lurek.render.setColor(0.7, 0.7, 0.8, 0.6 + math.sin(t * 3) * 0.3)
        lurek.render.print("Press SPACE to return to title", 250, 320, 0, 1, 1)

        -- Show final relationships
        lurek.render.setColor(0.3, 0.6, 1, 0.8)
        lurek.render.print(string.format("Sage: %+d", relationships.sage), 320, 380, 0, 0.9, 0.9)
        lurek.render.setColor(1, 0.8, 0.2, 0.8)
        lurek.render.print(string.format("Merchant: %+d", relationships.merchant), 320, 405, 0, 0.9, 0.9)
        lurek.render.setColor(1, 0.3, 0.25, 0.8)
        lurek.render.print(string.format("Guard: %+d", relationships.guard), 320, 430, 0, 0.9, 0.9)
        return
    end

    -- Dialog log (top-left, last 8 lines)
    for i, entry in ipairs(dialog_log) do
        local col = SPEAKER_COLORS[entry.speaker] or {0.7, 0.7, 0.7}
        local y = 40 + (i - 1) * 18
        local log_alpha = 0.3 + (i / #dialog_log) * 0.4
        lurek.render.setColor(col[1], col[2], col[3], log_alpha)
        local prefix = entry.speaker == "You" and "You" or entry.speaker
        local line = prefix .. ": " .. entry.text
        if #line > 80 then line = string.sub(line, 1, 77) .. "..." end
        lurek.render.print(line, 15, y, 0, 0.7, 0.7)
    end

    -- Scene label (top right)
    lurek.render.setColor(0.5, 0.5, 0.6, 0.5)
    local scene_labels = { forest = "The Forest", shop = "The Shop", gate = "The Gate" }
    lurek.render.print(scene_labels[scene_name] or scene_name, 680, 40, 0, 0.85, 0.85)

    -- Auto advance indicator
    if auto_advance then
        lurek.render.setColor(0.3, 0.8, 0.4, 0.6 + math.sin(t * 4) * 0.3)
        lurek.render.print("AUTO", 740, 10, 0, 0.8, 0.8)
    end

    -- Dialog box background
    lurek.render.setColor(0.05, 0.05, 0.08, 0.9)
    lurek.render.drawRect("fill", 20, DIALOG_BOX_Y, SCREEN_W - 40, DIALOG_BOX_H)
    -- Border
    lurek.render.setColor(0.3, 0.3, 0.4, 0.6)
    lurek.render.drawRect("line", 20, DIALOG_BOX_Y, SCREEN_W - 40, DIALOG_BOX_H)

    -- Speaker name above dialog box
    if current_speaker ~= "" then
        local sc = current_speaker_color
        -- Speaker name background tab
        lurek.render.setColor(sc[1] * 0.3, sc[2] * 0.3, sc[3] * 0.3, 0.8)
        lurek.render.drawRect("fill", 30, DIALOG_BOX_Y - 26, #current_speaker * 10 + 16, 24)
        lurek.render.setColor(sc[1], sc[2], sc[3], 1)
        lurek.render.print(current_speaker, 38, DIALOG_BOX_Y - 22, 0, 0.9, 0.9)
    end

    -- Typewriter text (with fade-in tween)
    lurek.render.setColor(0.9, 0.9, 0.95, text_fade_alpha)
    lurek.render.print(typewriter_text, 40, DIALOG_BOX_Y + 20, 0, 0.95, 0.95)

    -- Advance prompt
    if state == "DIALOG" and typewriter_done() then
        lurek.render.setColor(0.5, 0.5, 0.7, 0.4 + math.sin(t * 4) * 0.3)
        lurek.render.print("▼", SCREEN_W - 55, DIALOG_BOX_Y + DIALOG_BOX_H - 25, 0, 1, 1)
    end

    -- Choice display
    if state == "CHOICE" then
        for i, opt in ipairs(choice_options) do
            local is_sel = (i == choice_selected)
            local pulse_val = is_sel and (0.15 + math.sin(choice_pulse) * 0.1) or 0
            local cy = DIALOG_BOX_Y + 50 + (i - 1) * 28

            -- Choice highlight background (tween pulse)
            if is_sel then
                lurek.render.setColor(0.2 + pulse_val, 0.25 + pulse_val, 0.4 + pulse_val, 0.5)
                lurek.render.drawRect("fill", 35, cy - 3, SCREEN_W - 80, 24)
            end

            -- Choice number
            lurek.render.setColor(0.8, 0.7, 0.3, 1)
            lurek.render.print(i .. ".", 45, cy, 0, 0.9, 0.9)
            -- Choice text
            local alpha = is_sel and 1.0 or 0.6
            lurek.render.setColor(0.9, 0.9, 0.95, alpha)
            lurek.render.print(opt.text, 70, cy, 0, 0.9, 0.9)
        end
    end

    -- Bubble particles (speech appear effect)
    for _, p in ipairs(bubble_particles) do
        lurek.render.setColor(current_speaker_color[1], current_speaker_color[2],
            current_speaker_color[3], p.alpha)
        lurek.render.drawCircle("fill", p.x, p.y, p.size)
    end

    -- Sparkle particles (choice selected)
    for _, p in ipairs(sparkle_particles) do
        local a = p.life / p.max_life
        lurek.render.setColor(p.r, p.g, p.b, a)
        lurek.render.drawRect("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end
end)
