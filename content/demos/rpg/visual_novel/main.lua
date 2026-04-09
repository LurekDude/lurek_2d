-- Visual Novel — Narrative branching with typewriter text, choices, and multiple endings
-- Run with: cargo run -- demos/rpg/visual_novel

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600

local scenes, current_scene, current_line
local char_index, char_timer
local choices_visible
local affection = { luna_char = 0, sol = 0, nova = 0 }
local skip_mode = false
local auto_timer = 0
local ending_text = nil

local CHAR_SPEED = 0.03
local AUTO_DELAY = 2.0

local CHAR_COLORS = {
    narrator = { 0.8, 0.8, 0.8 },
    luna_char = { 0.4, 0.6, 1.0 },
    sol   = { 1.0, 0.7, 0.2 },
    nova  = { 0.9, 0.3, 0.7 },
}

local CHAR_NAMES = {
    narrator = "",
    luna_char = "Luna",
    sol   = "Sol",
    nova  = "Nova",
}

local BG_COLORS = {
    garden  = { 0.1, 0.25, 0.12 },
    library = { 0.15, 0.1, 0.2 },
    cafe    = { 0.25, 0.15, 0.1 },
    stars   = { 0.02, 0.02, 0.08 },
    ending  = { 0.0, 0.0, 0.0 },
}

local function line(speaker, text, bg)
    return { speaker = speaker, text = text, bg = bg }
end

local function choice(prompt, options)
    return { speaker = "narrator", text = prompt, bg = nil, choices = options }
end

local function build_scenes()
    scenes = {
        intro = {
            line("narrator", "You find yourself at the entrance of a moonlit academy.", "garden"),
            line("narrator", "Three paths diverge before you, each leading to a different building."),
            choice("Where do you go?", {
                { text = "The Observatory (stargazing)", next = "meet_luna", var = "luna_char", val = 1 },
                { text = "The Library (quiet study)", next = "meet_sol", var = "sol", val = 1 },
                { text = "The Courtyard Cafe", next = "meet_nova", var = "nova", val = 1 },
            }),
        },
        meet_luna = {
            line("narrator", "The observatory dome is open, revealing a canvas of stars.", "stars"),
            line("luna_char", "Oh! I didn't expect company tonight."),
            line("luna_char", "I'm Luna. I come here to map constellations."),
            line("luna_char", "Do you know much about the stars?"),
            choice("How do you respond?", {
                { text = "I love stargazing!", next = "luna_talk", var = "luna_char", val = 2 },
                { text = "Not really, but I'd like to learn.", next = "luna_talk", var = "luna_char", val = 1 },
                { text = "I was just passing through.", next = "day2" },
            }),
        },
        luna_talk = {
            line("luna_char", "That's wonderful! Let me show you Orion.", "stars"),
            line("luna_char", "See those three stars in a row? That's the belt."),
            line("narrator", "Luna traces patterns in the sky with her finger, eyes sparkling."),
            line("luna_char", "I feel like we could be good friends."),
            { speaker = "narrator", text = "The night passes peacefully.", bg = nil, goto_scene = "day2" },
        },
        meet_sol = {
            line("narrator", "The library is vast, shelves reaching to vaulted ceilings.", "library"),
            line("sol", "Ah, another late-night reader? Rare these days."),
            line("sol", "I'm Sol. I'm researching ancient languages."),
            choice("What do you say?", {
                { text = "That sounds fascinating!", next = "sol_talk", var = "sol", val = 2 },
                { text = "Any recommendations?", next = "sol_talk", var = "sol", val = 1 },
                { text = "Just looking for a quiet place.", next = "day2" },
            }),
        },
        sol_talk = {
            line("sol", "Few people appreciate old texts anymore.", "library"),
            line("sol", "Here — this one has a puzzle cipher in the margins."),
            line("narrator", "Sol carefully opens a leather-bound tome, revealing strange symbols."),
            line("sol", "Perhaps we can decode it together sometime."),
            { speaker = "narrator", text = "You spend the evening reading side by side.", bg = nil, goto_scene = "day2" },
        },
        meet_nova = {
            line("narrator", "The courtyard cafe glows with warm lantern light.", "cafe"),
            line("nova", "Hey there! First time here? The cocoa is legendary."),
            line("nova", "I'm Nova. I basically live here."),
            choice("Your response?", {
                { text = "I'll have what you're having!", next = "nova_talk", var = "nova", val = 2 },
                { text = "It does smell amazing.", next = "nova_talk", var = "nova", val = 1 },
                { text = "Just passing through.", next = "day2" },
            }),
        },
        nova_talk = {
            line("nova", "Smart choice! Two cocoas coming up.", "cafe"),
            line("nova", "You know, I collect stories from everyone who visits."),
            line("narrator", "Nova laughs easily, filling the quiet courtyard with warmth."),
            line("nova", "Come back anytime — I'll save your seat."),
            { speaker = "narrator", text = "The evening ends with laughter and warm drinks.", bg = nil, goto_scene = "day2" },
        },
        day2 = {
            line("narrator", "The next morning, you spot all three at the fountain.", "garden"),
            line("luna_char", "Good morning! The sunrise was beautiful today."),
            line("sol", "I found another cipher last night — want to see?"),
            line("nova", "Forget ciphers, let's get breakfast!"),
            choice("Who do you spend the day with?", {
                { text = "Luna — explore the hills", next = "luna_end", var = "luna_char", val = 3 },
                { text = "Sol — decode the cipher", next = "sol_end", var = "sol", val = 3 },
                { text = "Nova — adventure in town", next = "nova_end", var = "nova", val = 3 },
            }),
        },
        luna_end = {
            line("narrator", "You and Luna hike to a hilltop overlooking the academy.", "stars"),
            line("luna_char", "From up here, you can see the whole valley."),
            line("luna_char", "I don't usually share this spot with anyone."),
            line("luna_char", "But with you... it feels right."),
            { speaker = "narrator", text = "", bg = nil, goto_scene = "finale" },
        },
        sol_end = {
            line("narrator", "Deep in the library, you and Sol crack the cipher.", "library"),
            line("sol", "It's a poem — about finding connection through knowledge."),
            line("sol", "I think the author meant... something like what we have."),
            line("sol", "A meeting of minds."),
            { speaker = "narrator", text = "", bg = nil, goto_scene = "finale" },
        },
        nova_end = {
            line("narrator", "Nova takes you on a whirlwind tour of the town.", "cafe"),
            line("nova", "Best day I've had in ages!"),
            line("nova", "Promise me we'll do this again?"),
            line("nova", "Life's too short for boring routines."),
            { speaker = "narrator", text = "", bg = nil, goto_scene = "finale" },
        },
        finale = {
            { speaker = "narrator", text = "", bg = "ending", goto_scene = "_ending" },
        },
    }
end

local function get_current_bg()
    local scene = scenes[current_scene]
    if not scene then return BG_COLORS.garden end
    for i = current_line, 1, -1 do
        if scene[i] and scene[i].bg and BG_COLORS[scene[i].bg] then
            return BG_COLORS[scene[i].bg]
        end
    end
    return BG_COLORS.garden
end

local function go_to_scene(name)
    if name == "_ending" then
        -- Evaluate the ending by finding the character with the highest affection score.
        -- Affection is accumulated through dialogue choices (each choice awards 1–3 points).
        -- The same character must be picked more often to unlock the "True Connection" ending.
        local best = "luna_char"
        if affection.sol > affection[best] then best = "sol" end
        if affection.nova > affection[best] then best = "nova" end
        ending_text = "ENDING: You formed the strongest bond with " .. CHAR_NAMES[best] .. ".\n\n"
        if affection[best] >= 5 then
            ending_text = ending_text .. '"True Connection" ending achieved.'
        elseif affection[best] >= 3 then
            ending_text = ending_text .. '"Good Friends" ending achieved.'
        else
            ending_text = ending_text .. '"Passing Acquaintance" ending.'
        end
        return
    end
    current_scene = name
    current_line = 1
    char_index = 0
    char_timer = 0
    choices_visible = false
    auto_timer = 0
end

local function advance()
    if ending_text then return end
    local scene = scenes[current_scene]
    if not scene then return end
    local entry = scene[current_line]
    if not entry then return end

    -- if full text not shown, show it all
    if char_index < #entry.text then
        char_index = #entry.text
        return
    end

    -- if choices, don't advance
    if entry.choices then
        choices_visible = true
        return
    end

    -- goto scene redirect
    if entry.goto_scene then
        go_to_scene(entry.goto_scene)
        return
    end

    -- next line
    if current_line < #scene then
        current_line = current_line + 1
        char_index = 0
        char_timer = 0
        choices_visible = false
        auto_timer = 0
    end
end

function luna.init()
    luna.window.setTitle("Visual Novel")
    luna.gfx.setBackgroundColor(0.1, 0.15, 0.1)
    build_scenes()
    go_to_scene("intro")
end

function luna.process(dt)
    if ending_text then return end
    local scene = scenes[current_scene]
    if not scene then return end
    local entry = scene[current_line]
    if not entry then return end

    -- Typewriter effect: char_index tracks how many characters have been revealed.
    -- Each frame, accumulate dt into char_timer and emit one character per CHAR_SPEED
    -- seconds. In skip_mode the speed drops to 5 ms per char — effectively instant.
    -- Using a while loop handles cases where dt > CHAR_SPEED (low-fps drops).
    if char_index < #entry.text then
        char_timer = char_timer + dt
        local spd = skip_mode and 0.005 or CHAR_SPEED
        while char_timer >= spd and char_index < #entry.text do
            char_timer = char_timer - spd
            char_index = char_index + 1
        end
    else
        -- Auto-advance: when the full line is visible and the player holds Space,
        -- wait 0.3 s (enough to glance at the line) then move on automatically.
        -- Choice nodes are excluded — the player must pick an option manually.
        if skip_mode and not entry.choices then
            auto_timer = auto_timer + dt
            if auto_timer > 0.3 then advance() end
        end
    end
end

local function draw_portrait(speaker, side)
    if speaker == "narrator" then return end
    local c = CHAR_COLORS[speaker] or { 0.5, 0.5, 0.5 }
    local px = (side == "left") and 60 or (W - 120)
    local py = H - 260
    -- body
    luna.gfx.setColor(c[1], c[2], c[3], 0.9)
    luna.gfx.rectangle("fill", px, py + 40, 60, 80)
    -- head
    luna.gfx.circle("fill", px + 30, py + 20, 25)
    -- eyes
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.circle("fill", px + 22, py + 16, 4)
    luna.gfx.circle("fill", px + 38, py + 16, 4)
    luna.gfx.setColor(0, 0, 0, 1)
    luna.gfx.circle("fill", px + 23, py + 17, 2)
    luna.gfx.circle("fill", px + 39, py + 17, 2)
end

function luna.render()
    -- background
    local bg = get_current_bg()
    luna.gfx.setColor(bg[1], bg[2], bg[3], 1)
    luna.gfx.rectangle("fill", 0, 0, W, H)

    if ending_text then
        luna.gfx.setColor(1, 1, 1, 1)
        luna.gfx.print(ending_text, W / 2 - 180, H / 2 - 40, 1.1)
        luna.gfx.setColor(0.7, 0.7, 0.7, 1)
        luna.gfx.print("Press R to replay", W / 2 - 60, H / 2 + 60, 1)
        return
    end

    local scene = scenes[current_scene]
    if not scene then return end
    local entry = scene[current_line]
    if not entry then return end

    -- portrait
    local side = (entry.speaker == "nova" or entry.speaker == "sol") and "right" or "left"
    draw_portrait(entry.speaker, side)

    -- dialog box
    luna.gfx.setColor(0, 0, 0, 0.75)
    luna.gfx.rectangle("fill", 30, H - 160, W - 60, 130)
    luna.gfx.setColor(0.5, 0.5, 0.7, 1)
    luna.gfx.rectangle("line", 30, H - 160, W - 60, 130)

    -- speaker name
    local name = CHAR_NAMES[entry.speaker] or ""
    if name ~= "" then
        local nc = CHAR_COLORS[entry.speaker] or { 1, 1, 1 }
        luna.gfx.setColor(nc[1], nc[2], nc[3], 1)
        luna.gfx.print(name, 50, H - 155, 1.1)
    end

    -- text (typewriter)
    local shown = string.sub(entry.text, 1, char_index)
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print(shown, 50, H - 130, 1)

    -- choices
    if choices_visible and entry.choices then
        for i, ch in ipairs(entry.choices) do
            local cy = H - 160 - (#entry.choices - i + 1) * 40
            -- highlight on hover
            local mx, my = luna.mouse.getPosition()
            local hover = mx > 60 and mx < 500 and my > cy and my < cy + 32
            if hover then
                luna.gfx.setColor(0.3, 0.3, 0.5, 0.9)
            else
                luna.gfx.setColor(0.15, 0.15, 0.25, 0.9)
            end
            luna.gfx.rectangle("fill", 60, cy, 440, 32)
            luna.gfx.setColor(1, 1, 0.8, 1)
            luna.gfx.print(i .. ". " .. ch.text, 75, cy + 6, 1)
        end
    end

    -- controls hint
    luna.gfx.setColor(0.5, 0.5, 0.5, 0.6)
    luna.gfx.print("Space=Advance  Tab=Skip  Click=Choose", 10, 10, 0.8)

    -- affection display
    local ay = 10
    for _, key in ipairs({"luna_char", "sol", "nova"}) do
        if affection[key] > 0 then
            local nc = CHAR_COLORS[key]
            luna.gfx.setColor(nc[1], nc[2], nc[3], 0.7)
            local hearts = ""
            for h = 1, clamp(affection[key], 0, 5) do hearts = hearts .. "<3 " end
            luna.gfx.print(CHAR_NAMES[key] .. ": " .. hearts, W - 200, ay, 0.8)
            ay = ay + 18
        end
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" and ending_text then
        affection = { luna_char = 0, sol = 0, nova = 0 }
        ending_text = nil
        build_scenes()
        go_to_scene("intro")
        return
    end
    if key == "space" then advance() end
    if key == "tab" then skip_mode = not skip_mode end
end

function luna.mousepressed(mx, my, button)
    if ending_text then return end
    local scene = scenes[current_scene]
    if not scene then return end
    local entry = scene[current_line]
    if not entry or not choices_visible or not entry.choices then
        advance()
        return
    end

    for i, ch in ipairs(entry.choices) do
        local cy = H - 160 - (#entry.choices - i + 1) * 40
        if mx > 60 and mx < 500 and my > cy and my < cy + 32 then
            if ch.var then
                affection[ch.var] = affection[ch.var] + (ch.val or 1)
            end
            go_to_scene(ch.next)
            return
        end
    end
end
