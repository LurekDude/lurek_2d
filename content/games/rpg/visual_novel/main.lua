-- ============================================================================
-- Visual Novel — Lurek2D
-- ============================================================================
-- Category : rpg
-- Source   : content/games/rpg/visual_novel/main.lua
-- Run with : cargo run -- content/games/rpg/visual_novel
-- ============================================================================
-- Branching narrative visual novel with 3 acts, 3 characters, affection
-- tracking, and multiple endings. Typewriter dialog, choice system, portraits.
-- Controls: space(advance) 1/2/3(choices) s(skip) tab(auto) h(history) esc(quit)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Input bindings
-- ---------------------------------------------------------------------------
local actions = {
    advance = "space",
    choice1 = "1",
    choice2 = "2",
    choice3 = "3",
    skip    = "s",
    auto    = "tab",
    history = "h",
    quit    = "escape",
}

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, SCENE = 2, CHOICE = 3, ENDING = 4 }
local current_state = STATE.TITLE

local TYPEWRITER_SPEED   = 0.03
local AUTO_ADVANCE_DELAY = 3.0
local LOG_MAX            = 10

local DIALOG_BOX_Y = SCREEN_H - 150
local DIALOG_BOX_H = 150

-- Character definitions
local CHARS = {
    Luna = { color = {0.35, 0.55, 0.95}, pos_x = 100, label = "Luna" },
    Sol  = { color = {0.95, 0.78, 0.20}, pos_x = 370, label = "Sol" },
    Nova = { color = {0.90, 0.40, 0.70}, pos_x = 620, label = "Nova" },
    Narrator = { color = {0.7, 0.7, 0.7}, pos_x = -1, label = "" },
}

-- Portrait dimensions
local PORTRAIT_W, PORTRAIT_H = 80, 120
local PORTRAIT_Y = 300

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local affection = { Luna = 0, Sol = 0, Nova = 0 }
local scene_index = 1
local dialog_index = 1
local scenes = {}

local typewriter_text   = ""
local typewriter_target = ""
local typewriter_timer  = 0
local text_fade_alpha   = 0

local current_speaker       = ""
local current_speaker_color = {1, 1, 1}

local choice_options  = {}
local choice_pulse    = 0

local dialog_log     = {}
local show_history   = false
local auto_advance   = false
local auto_timer     = 0
local skip_mode      = false

local visible_chars  = {}  -- which character portraits to show
local scene_bg       = {0.1, 0.1, 0.15}
local scene_label    = ""

local fps_visible    = true
local title_alpha    = 0
local title_pulse    = 0

-- Particles
local particles      = {}

-- Tween state
local portrait_tweens = { Luna = {x=0, alpha=0}, Sol = {x=0, alpha=0}, Nova = {x=0, alpha=0} }
local text_box_alpha  = 0

-- Camera
local camera = nil

-- Ending tracking
local ending_char = nil
local ending_timer = 0

-- ---------------------------------------------------------------------------
-- Particle helpers
-- ---------------------------------------------------------------------------
local function spawn_sparkle(x, y, count, r, g, b)
    for i = 1, (count or 10) do
        local angle = math.random() * math.pi * 2
        local speed = math.random(40, 130)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.5 + math.random() * 0.4,
            max_life = 0.9,
            size = math.random(2, 5),
            r = r or 1.0, g = g or 0.9, b = b or 0.5,
        })
    end
end

local function spawn_transition(count)
    for i = 1, (count or 20) do
        table.insert(particles, {
            x = math.random(0, SCREEN_W),
            y = math.random(0, SCREEN_H),
            vx = math.random(-30, 30),
            vy = math.random(-60, -20),
            life = 0.6 + math.random() * 0.6,
            max_life = 1.2,
            size = math.random(2, 4),
            r = 0.8, g = 0.85, b = 1.0,
        })
    end
end

local function spawn_ending_celebration()
    for i = 1, 40 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(60, 200)
        table.insert(particles, {
            x = SCREEN_W / 2, y = SCREEN_H / 2,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 1.0 + math.random() * 1.0,
            max_life = 2.0,
            size = math.random(3, 7),
            r = math.random() * 0.5 + 0.5,
            g = math.random() * 0.5 + 0.5,
            b = math.random() * 0.5 + 0.5,
        })
    end
end

local function update_particles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 40 * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end
end

-- ---------------------------------------------------------------------------
-- Typewriter helpers
-- ---------------------------------------------------------------------------
local function set_typewriter(text)
    typewriter_target = text
    typewriter_text   = ""
    typewriter_timer  = 0
    text_fade_alpha   = 0
end

local function typewriter_done()
    return #typewriter_text >= #typewriter_target
end

local function skip_typewriter()
    typewriter_text = typewriter_target
    text_fade_alpha = 1
end

-- ---------------------------------------------------------------------------
-- Dialog log
-- ---------------------------------------------------------------------------
local function add_to_log(speaker, text)
    table.insert(dialog_log, { speaker = speaker, text = text })
    while #dialog_log > LOG_MAX do
        table.remove(dialog_log, 1)
    end
end

-- ---------------------------------------------------------------------------
-- Tween helpers (simple lerp per frame)
-- ---------------------------------------------------------------------------
local function lerp(a, b, t)
    return a + (b - a) * t
end

local function update_portrait_tweens(dt)
    for name, tw in pairs(portrait_tweens) do
        local target_alpha = 0
        local target_x = 0
        for _, vc in ipairs(visible_chars) do
            if vc == name then
                target_alpha = 1
                target_x = CHARS[name].pos_x
                break
            end
        end
        local speed = dt * 5
        tw.alpha = lerp(tw.alpha, target_alpha, speed)
        if tw.alpha < 0.01 then tw.alpha = 0 end
        tw.x = lerp(tw.x, target_x, speed)
    end
    -- Text box
    local target_box = (current_state == STATE.SCENE or current_state == STATE.CHOICE) and 0.9 or 0
    text_box_alpha = lerp(text_box_alpha, target_box, dt * 6)
end

-- ---------------------------------------------------------------------------
-- Scene / Dialog data builder
-- ---------------------------------------------------------------------------
local function build_scenes()
    local S = {}

    -- ===================================================================
    -- ACT 1 — ARRIVALS
    -- ===================================================================
    S[1] = {
        label = "Act 1 — The Academy",
        bg = {0.08, 0.10, 0.20},
        chars = {},
        dialog = {
            { speaker = "Narrator", text = "The Academy of Astral Studies stands tall against the twilight sky." },
            { speaker = "Narrator", text = "You arrive at the gates, letter of acceptance in hand." },
        },
    }

    -- Scene 2: Meet Luna
    S[2] = {
        label = "The Library",
        bg = {0.10, 0.08, 0.18},
        chars = {"Luna"},
        dialog = {
            { speaker = "Luna", text = "Oh! I didn't hear you come in... Welcome to the Grand Library." },
            { speaker = "Luna", text = "I'm Luna. I've been cataloging these texts for three years now." },
            { speaker = "Luna", text = "Every book has a story beyond its pages... if you know where to look." },
            { speaker = "Narrator", text = "Luna brushes a strand of hair behind her ear, cheeks slightly pink." },
        },
        choice = {
            speaker = "Luna",
            prompt = "She gestures at the towering shelves. What do you say?",
            options = {
                { text = "This collection is incredible. Could you show me your favorites?",
                  target_scene = 3, affection = {Luna = 15} },
                { text = "I'm more interested in the restricted section, actually.",
                  target_scene = 3, affection = {Luna = 5, Sol = -5} },
                { text = "Books are fine, but I prefer hands-on experience.",
                  target_scene = 3, affection = {Sol = 10} },
            },
        },
    }

    -- Scene 3: Meet Sol
    S[3] = {
        label = "The Training Grounds",
        bg = {0.18, 0.14, 0.06},
        chars = {"Sol"},
        dialog = {
            { speaker = "Sol", text = "Hey there, new recruit! Name's Sol. Welcome to the real Academy." },
            { speaker = "Sol", text = "Books and theories are fine, but out here? This is where legends are made." },
            { speaker = "Narrator", text = "Sol spins a practice sword with practiced ease, grinning." },
        },
        choice = {
            speaker = "Sol",
            prompt = "Sol tosses you a wooden sword. How do you respond?",
            options = {
                { text = "Show me what you've got! I learn best by doing.",
                  target_scene = 4, affection = {Sol = 15} },
                { text = "I'd rather observe first and understand the technique.",
                  target_scene = 4, affection = {Luna = 10} },
                { text = "Is there a scientific explanation for combat magic?",
                  target_scene = 4, affection = {Nova = 10, Sol = -5} },
            },
        },
    }

    -- Scene 4: Meet Nova
    S[4] = {
        label = "The Observatory",
        bg = {0.06, 0.06, 0.16},
        chars = {"Nova"},
        dialog = {
            { speaker = "Nova", text = "Fascinating. Another variable enters the equation." },
            { speaker = "Narrator", text = "A woman in a lab coat peers at you through tinted goggles." },
            { speaker = "Nova", text = "I'm Nova. I study the anomalies — energy patterns most people ignore." },
            { speaker = "Nova", text = "The Academy thinks I'm eccentric. They might be right." },
        },
        choice = {
            speaker = "Nova",
            prompt = "Nova adjusts a strange instrument on her desk. What catches your eye?",
            options = {
                { text = "What kind of anomalies? I'd love to hear more.",
                  target_scene = 5, affection = {Nova = 15} },
                { text = "The Academy should fund your research more.",
                  target_scene = 5, affection = {Nova = 10, Luna = 5} },
                { text = "Sounds dangerous. Are you sure it's safe?",
                  target_scene = 5, affection = {Sol = 10, Nova = -5} },
            },
        },
    }

    -- Scene 5: Act 1 wrap-up — all three together
    S[5] = {
        label = "The Courtyard",
        bg = {0.10, 0.10, 0.16},
        chars = {"Luna", "Sol", "Nova"},
        dialog = {
            { speaker = "Narrator", text = "A week passes. You find yourself drawn to the courtyard each evening." },
            { speaker = "Luna", text = "I found a reference to the Astral Convergence in Volume 47..." },
            { speaker = "Sol", text = "Convergence? Sounds like it could be an adventure!" },
            { speaker = "Nova", text = "It's not an adventure. It's a catastrophic energy event." },
            { speaker = "Narrator", text = "The three exchange glances. Something is coming." },
        },
        choice = {
            speaker = "Narrator",
            prompt = "The atmosphere is tense. Who do you spend the evening with?",
            options = {
                { text = "Help Luna research the Convergence in the library.",
                  target_scene = 6, affection = {Luna = 20, Sol = -5} },
                { text = "Train with Sol to prepare for whatever comes.",
                  target_scene = 6, affection = {Sol = 20, Luna = -5} },
                { text = "Assist Nova with her energy readings in the lab.",
                  target_scene = 6, affection = {Nova = 20, Sol = -5} },
            },
        },
    }

    -- ===================================================================
    -- ACT 2 — THE CRISIS
    -- ===================================================================
    S[6] = {
        label = "Act 2 — The Surge",
        bg = {0.15, 0.05, 0.08},
        chars = {"Luna", "Sol", "Nova"},
        dialog = {
            { speaker = "Narrator", text = "A blinding light splits the sky above the Academy." },
            { speaker = "Nova", text = "The Convergence — it's happening NOW! My instruments are overloading!" },
            { speaker = "Sol", text = "The east wing is collapsing! People are trapped!" },
            { speaker = "Luna", text = "The ancient texts — they hold the key to stopping this! I need help!" },
            { speaker = "Narrator", text = "Energy crackles through the air. You must choose." },
        },
        choice = {
            speaker = "Narrator",
            prompt = "Three paths. Three friends. Who do you help?",
            options = {
                { text = "Rush to the library with Luna — the answer is in the texts.",
                  target_scene = 7, affection = {Luna = 20, Nova = -5} },
                { text = "Follow Sol to rescue the trapped students.",
                  target_scene = 8, affection = {Sol = 20, Luna = -5} },
                { text = "Stay with Nova — her science can stop this at the source.",
                  target_scene = 9, affection = {Nova = 20, Sol = -5} },
            },
        },
    }

    -- Scene 7: Luna path
    S[7] = {
        label = "The Library — Under Siege",
        bg = {0.12, 0.06, 0.18},
        chars = {"Luna"},
        dialog = {
            { speaker = "Luna", text = "Thank you for coming. I can't do this alone." },
            { speaker = "Narrator", text = "Shelves topple around you as the building shakes." },
            { speaker = "Luna", text = "Here! Volume 47, page 892... the containment ritual!" },
            { speaker = "Luna", text = "Hold this steady while I read the incantation..." },
            { speaker = "Narrator", text = "Luna's voice trembles but grows stronger with each word." },
            { speaker = "Luna", text = "It's working! The energy is stabilizing around the library!" },
            { speaker = "Narrator", text = "Luna clutches your hand, eyes bright with relief and gratitude." },
        },
    }

    -- Scene 8: Sol path
    S[8] = {
        label = "The East Wing — Rescue",
        bg = {0.18, 0.08, 0.04},
        chars = {"Sol"},
        dialog = {
            { speaker = "Sol", text = "Stay close! The corridor is unstable!" },
            { speaker = "Narrator", text = "Debris rains down. Sol shields you with one arm." },
            { speaker = "Sol", text = "I can hear them! Three students, behind that wall!" },
            { speaker = "Sol", text = "On three — we push together! One... two... THREE!" },
            { speaker = "Narrator", text = "The wall gives way. Dusty, coughing students stumble out." },
            { speaker = "Sol", text = "We did it. Couldn't have done it without you, partner." },
            { speaker = "Narrator", text = "Sol claps your shoulder, beaming with fierce pride." },
        },
    }

    -- Scene 9: Nova path
    S[9] = {
        label = "The Observatory — Containment",
        bg = {0.04, 0.06, 0.18},
        chars = {"Nova"},
        dialog = {
            { speaker = "Nova", text = "The resonance frequency is off the charts. Help me recalibrate!" },
            { speaker = "Narrator", text = "Sparks fly from Nova's instruments. The air hums." },
            { speaker = "Nova", text = "Turn that dial to 7.3... no, 7.31! Precision matters!" },
            { speaker = "Nova", text = "The harmonic is aligning... almost there..." },
            { speaker = "Narrator", text = "A burst of light, then silence. The surge fades." },
            { speaker = "Nova", text = "We neutralized the source. The data... this changes everything." },
            { speaker = "Narrator", text = "Nova removes her goggles, eyes wide with wonder and gratitude." },
        },
    }

    -- ===================================================================
    -- ACT 3 — RESOLUTION (determined by highest affection at runtime)
    -- ===================================================================
    -- These are set dynamically based on affection.

    return S
end

-- ---------------------------------------------------------------------------
-- Determine ending and go to it
-- ---------------------------------------------------------------------------
local function determine_ending()
    local best = "Luna"
    if affection.Sol > affection[best] then best = "Sol" end
    if affection.Nova > affection[best] then best = "Nova" end
    ending_char = best
    ending_timer = 0
    current_state = STATE.ENDING
    spawn_ending_celebration()
end

-- ---------------------------------------------------------------------------
-- Advance to next dialog line or choice, or next scene
-- ---------------------------------------------------------------------------
local function advance()
    local sc = scenes[scene_index]
    if not sc then determine_ending(); return end

    -- If still in dialog lines
    if dialog_index <= #sc.dialog then
        local line = sc.dialog[dialog_index]
        add_to_log(line.speaker, line.text)
        dialog_index = dialog_index + 1
        if dialog_index <= #sc.dialog then
            -- Show next line
            local next_line = sc.dialog[dialog_index]
            current_speaker = next_line.speaker
            current_speaker_color = (CHARS[next_line.speaker] or CHARS.Narrator).color
            set_typewriter(next_line.text)
        elseif sc.choice then
            -- Move to choice
            current_state = STATE.CHOICE
            current_speaker = sc.choice.speaker
            current_speaker_color = (CHARS[sc.choice.speaker] or CHARS.Narrator).color
            set_typewriter(sc.choice.prompt)
            choice_options = sc.choice.options
            choice_pulse = 0
        else
            -- No choice, go to next scene
            scene_index = scene_index + 1
            dialog_index = 1
            if scenes[scene_index] then
                enter_scene()
            else
                determine_ending()
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Enter a scene
-- ---------------------------------------------------------------------------
function enter_scene()
    local sc = scenes[scene_index]
    if not sc then determine_ending(); return end
    current_state = STATE.SCENE
    scene_label = sc.label
    scene_bg = sc.bg
    visible_chars = sc.chars or {}
    dialog_index = 1

    -- Initialize portrait tweens off-screen
    for name, tw in pairs(portrait_tweens) do
        tw.alpha = 0
        tw.x = CHARS[name].pos_x - 60
    end

    spawn_transition(25)

    if #sc.dialog > 0 then
        local first = sc.dialog[1]
        current_speaker = first.speaker
        current_speaker_color = (CHARS[first.speaker] or CHARS.Narrator).color
        set_typewriter(first.text)
    end
end

-- ---------------------------------------------------------------------------
-- Select a choice
-- ---------------------------------------------------------------------------
local function select_choice(idx)
    if current_state ~= STATE.CHOICE then return end
    if idx < 1 or idx > #choice_options then return end

    local opt = choice_options[idx]
    add_to_log("You", opt.text)
    spawn_sparkle(SCREEN_W / 2, DIALOG_BOX_Y + 20 + idx * 28, 15, 1, 0.9, 0.4)

    -- Apply affection changes
    if opt.affection then
        for name, delta in pairs(opt.affection) do
            affection[name] = math.max(0, math.min(100, (affection[name] or 0) + delta))
        end
    end

    -- Navigate to target scene
    if opt.target_scene then
        scene_index = opt.target_scene
    else
        scene_index = scene_index + 1
    end
    dialog_index = 1
    choice_options = {}

    if scenes[scene_index] then
        enter_scene()
    else
        determine_ending()
    end
end

-- ---------------------------------------------------------------------------
-- lurek.init
-- ---------------------------------------------------------------------------

-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("Visual Novel — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.08, 0.12)
    camera = lurek.camera.new()
    title_alpha = 0
end

-- ---------------------------------------------------------------------------
-- lurek.ready
-- ---------------------------------------------------------------------------
local function _ready_setup()

end

-- ---------------------------------------------------------------------------
-- lurek.process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    -- FPS toggle
    if lurek.input.keyboard.isDown("f3") then fps_visible = not fps_visible end

    -- Update particles
    update_particles(dt)

    -- Update portrait tweens
    update_portrait_tweens(dt)

    -- Typewriter
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

    -- Choice pulse
    choice_pulse = choice_pulse + dt * 4
    if choice_pulse > math.pi * 2 then choice_pulse = choice_pulse - math.pi * 2 end

    -- ── TITLE state ───────────────────────────────────────────
    if current_state == STATE.TITLE then
        title_alpha = math.min(title_alpha + dt * 2, 1)
        title_pulse = 0.5 + math.sin(lurek.timer.getTime() * 3) * 0.4
        if lurek.input.keyboard.isDown("return") or lurek.input.keyboard.isDown(actions.advance) then
            -- Start game
            affection = { Luna = 0, Sol = 0, Nova = 0 }
            dialog_log = {}
            particles = {}
            ending_char = nil
            scenes = build_scenes()
            scene_index = 1
            dialog_index = 1
            enter_scene()
        end
        return
    end

    -- Quit
    if lurek.input.keyboard.isDown(actions.quit) then lurek.event.quit() end

    -- History toggle
    if lurek.input.keyboard.isDown(actions.history) then
        show_history = not show_history
    end

    -- Skip mode toggle
    if lurek.input.keyboard.isDown(actions.skip) then
        skip_mode = not skip_mode
    end

    -- Auto-advance toggle
    if lurek.input.keyboard.isDown(actions.auto) then
        auto_advance = not auto_advance
        auto_timer = 0
    end

    -- ── SCENE state ───────────────────────────────────────────
    if current_state == STATE.SCENE then
        -- Skip mode: instantly complete text
        if skip_mode and not typewriter_done() then
            skip_typewriter()
        end

        if typewriter_done() then
            -- Auto advance
            if auto_advance then
                auto_timer = auto_timer + dt
                if auto_timer >= AUTO_ADVANCE_DELAY then
                    auto_timer = 0
                    advance()
                end
            end
            -- Manual advance
            if lurek.input.keyboard.isDown(actions.advance) then
                auto_timer = 0
                advance()
            end
            -- Skip mode auto-advance to next choice
            if skip_mode then advance() end
        end

    -- ── CHOICE state ──────────────────────────────────────────
    elseif current_state == STATE.CHOICE then
        skip_mode = false  -- disable skip at choices
        if lurek.input.keyboard.isDown(actions.choice1) then select_choice(1) end
        if lurek.input.keyboard.isDown(actions.choice2) then select_choice(2) end
        if lurek.input.keyboard.isDown(actions.choice3) then select_choice(3) end

    -- ── ENDING state ──────────────────────────────────────────
    elseif current_state == STATE.ENDING then
        ending_timer = ending_timer + dt
        -- Celebration particles
        if ending_timer < 3 and math.random() < 0.15 then
            local ec = CHARS[ending_char] or CHARS.Luna
            spawn_sparkle(math.random(100, 700), math.random(50, 400), 3,
                          ec.color[1], ec.color[2], ec.color[3])
        end
        if lurek.input.keyboard.isDown(actions.advance) then
            current_state = STATE.TITLE
            title_alpha = 0
        end
    end
end

-- ---------------------------------------------------------------------------
-- lurek.render — backgrounds + character portraits
-- ---------------------------------------------------------------------------
function lurek.draw()
    if current_state == STATE.TITLE then return end

    -- Scene background
    lurek.render.setColor(scene_bg[1], scene_bg[2], scene_bg[3], 1)
    rect("fill", 0, 0, SCREEN_W, SCREEN_H)

    -- Mood overlay: subtle gradient rectangles
    local t = lurek.timer.getTime()
    lurek.render.setColor(scene_bg[1] * 1.3, scene_bg[2] * 1.3, scene_bg[3] * 1.3, 0.3)
    rect("fill", 0, 0, SCREEN_W, 80)

    -- Ambient particles (floating motes)
    lurek.render.setColor(1, 1, 0.9, 0.15 + math.sin(t * 1.5) * 0.08)
    for i = 1, 6 do
        local mx = 80 + i * 120 + math.sin(t * 0.4 + i * 1.7) * 40
        local my = 120 + math.cos(t * 0.6 + i * 2.3) * 50
        circ("fill", mx, my, 2)
    end

    -- Ground area
    lurek.render.setColor(scene_bg[1] * 0.6, scene_bg[2] * 0.6, scene_bg[3] * 0.6, 1)
    rect("fill", 0, PORTRAIT_Y + PORTRAIT_H + 10, SCREEN_W, SCREEN_H - PORTRAIT_Y - PORTRAIT_H - 10)

    -- Character portraits (colored rectangles with name labels)
    for name, tw in pairs(portrait_tweens) do
        if tw.alpha > 0.02 then
            local ch = CHARS[name]
            local px = tw.x
            local py = PORTRAIT_Y

            -- Shadow
            lurek.render.setColor(0, 0, 0, 0.3 * tw.alpha)
            rect("fill", px + 4, py + 4, PORTRAIT_W, PORTRAIT_H)

            -- Body
            lurek.render.setColor(ch.color[1], ch.color[2], ch.color[3], tw.alpha)
            rect("fill", px, py, PORTRAIT_W, PORTRAIT_H)

            -- Inner highlight
            lurek.render.setColor(ch.color[1] * 1.3, ch.color[2] * 1.3, ch.color[3] * 1.3,
                                  tw.alpha * 0.5)
            rect("fill", px + 8, py + 8, PORTRAIT_W - 16, 30)

            -- Border
            lurek.render.setColor(1, 1, 1, tw.alpha * 0.4)
            rect("line", px, py, PORTRAIT_W, PORTRAIT_H)

            -- Name label below portrait
            lurek.render.setColor(ch.color[1], ch.color[2], ch.color[3], tw.alpha)
            text_(ch.label, px + 10, py + PORTRAIT_H + 5, 0, 0.85, 0.85)
        end
    end

    -- Draw particles (world-space)
    for _, p in ipairs(particles) do
        local alpha = (p.life / p.max_life) * 0.8
        lurek.render.setColor(p.r, p.g, p.b, alpha)
        circ("fill", p.x, p.y, p.size)
    end
end

-- ---------------------------------------------------------------------------
-- lurek.render_ui — dialog box, text, choices, affection, history
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    local t = lurek.timer.getTime()

    -- FPS
    if fps_visible then
        lurek.render.setColor(0.6, 0.6, 0.6, 0.5)
        text_(string.format("FPS: %d", lurek.timer.getFPS()), 10, 10)
    end

    -- ── TITLE screen ──────────────────────────────────────────
    if current_state == STATE.TITLE then
        lurek.render.setColor(0.08, 0.08, 0.14, 1)
        rect("fill", 0, 0, SCREEN_W, SCREEN_H)

        -- Title text
        lurek.render.setColor(0.5, 0.4, 0.9, title_alpha)
        text_("VISUAL NOVEL", 220, 160, 0, 3, 3)

        lurek.render.setColor(0.7, 0.6, 0.85, title_alpha * 0.8)
        text_("THREE PATHS, ONE STORY", 240, 230, 0, 1.2, 1.2)

        -- Character previews
        local preview_y = 300
        for i, name in ipairs({"Luna", "Sol", "Nova"}) do
            local ch = CHARS[name]
            local px = 160 + (i - 1) * 200
            lurek.render.setColor(ch.color[1], ch.color[2], ch.color[3], title_alpha * 0.7)
            rect("fill", px, preview_y, 60, 80)
            lurek.render.setColor(ch.color[1], ch.color[2], ch.color[3], title_alpha)
            text_(ch.label, px + 5, preview_y + 85, 0, 0.8, 0.8)
        end

        lurek.render.setColor(0.8, 0.8, 0.9, title_pulse)
        text_("PRESS SPACE TO BEGIN", 270, 440, 0, 1.1, 1.1)

        lurek.render.setColor(0.5, 0.5, 0.6, title_alpha * 0.5)
        text_("Space=Advance  1/2/3=Choose  S=Skip  Tab=Auto  H=History  Esc=Quit",
                           95, 530, 0, 0.8, 0.8)
        return
    end

    -- ── ENDING screen ─────────────────────────────────────────
    if current_state == STATE.ENDING then
        local ec = CHARS[ending_char] or CHARS.Luna

        -- Background tint
        lurek.render.setColor(ec.color[1] * 0.15, ec.color[2] * 0.15, ec.color[3] * 0.15, 1)
        rect("fill", 0, 0, SCREEN_W, SCREEN_H)

        -- Ending title
        lurek.render.setColor(ec.color[1], ec.color[2], ec.color[3], 1)
        text_(ending_char .. " Ending", 260, 120, 0, 2.5, 2.5)

        -- Ending description
        local desc = ""
        if ending_char == "Luna" then
            desc = "You stay at the Academy, helping Luna catalog the ancient archives.\nTogether, you uncover knowledge lost for centuries.\nThe library becomes your shared sanctuary — quiet, warm, infinite."
        elseif ending_char == "Sol" then
            desc = "You and Sol set out beyond the Academy walls, seeking adventure.\nEvery horizon holds a new challenge, and you face them together.\nThe road is long, but with Sol at your side, it's never dull."
        elseif ending_char == "Nova" then
            desc = "You join Nova's research team, diving into the unknown.\nThe anomalies reveal a deeper truth about the world's energy.\nTogether, you stand on the edge of a breakthrough that changes everything."
        end
        lurek.render.setColor(0.85, 0.85, 0.9, 1)
        local desc_y = 200
        for line in desc:gmatch("[^\n]+") do
            text_(line, 120, desc_y, 0, 0.9, 0.9)
            desc_y = desc_y + 28
        end

        -- Affection summary
        local sum_y = 340
        lurek.render.setColor(0.6, 0.6, 0.7, 0.7)
        text_("— Affection —", 330, sum_y, 0, 0.9, 0.9)
        sum_y = sum_y + 30
        for _, name in ipairs({"Luna", "Sol", "Nova"}) do
            local ch = CHARS[name]
            lurek.render.setColor(ch.color[1], ch.color[2], ch.color[3], 0.9)
            text_(string.format("%s: %d", name, affection[name]), 340, sum_y, 0, 0.9, 0.9)
            -- Affection bar
            lurek.render.setColor(ch.color[1], ch.color[2], ch.color[3], 0.3)
            rect("fill", 430, sum_y + 2, 150, 12)
            lurek.render.setColor(ch.color[1], ch.color[2], ch.color[3], 0.8)
            rect("fill", 430, sum_y + 2, 150 * (affection[name] / 100), 12)
            sum_y = sum_y + 26
        end

        -- Ending particles
        for _, p in ipairs(particles) do
            local alpha = (p.life / p.max_life) * 0.7
            lurek.render.setColor(p.r, p.g, p.b, alpha)
            circ("fill", p.x, p.y, p.size)
        end

        lurek.render.setColor(0.7, 0.7, 0.8, 0.5 + math.sin(t * 3) * 0.3)
        text_("Press SPACE to return to title", 260, 520, 0, 0.9, 0.9)
        return
    end

    -- ── Scene label (top right) ───────────────────────────────
    lurek.render.setColor(0.6, 0.6, 0.7, 0.5)
    text_(scene_label, 610, 15, 0, 0.8, 0.8)

    -- ── Affection bars (top left) ─────────────────────────────
    local bar_y = 35
    for _, name in ipairs({"Luna", "Sol", "Nova"}) do
        local ch = CHARS[name]
        lurek.render.setColor(ch.color[1], ch.color[2], ch.color[3], 0.7)
        text_(name, 10, bar_y, 0, 0.65, 0.65)
        -- Bar background
        lurek.render.setColor(0.2, 0.2, 0.25, 0.5)
        rect("fill", 55, bar_y + 2, 80, 8)
        -- Bar fill
        lurek.render.setColor(ch.color[1], ch.color[2], ch.color[3], 0.7)
        rect("fill", 55, bar_y + 2, 80 * (affection[name] / 100), 8)
        bar_y = bar_y + 16
    end

    -- ── Auto / Skip indicators ────────────────────────────────
    if auto_advance then
        lurek.render.setColor(0.3, 0.8, 0.4, 0.6 + math.sin(t * 4) * 0.3)
        text_("AUTO", 740, 10, 0, 0.8, 0.8)
    end
    if skip_mode then
        lurek.render.setColor(0.9, 0.6, 0.2, 0.6 + math.sin(t * 5) * 0.3)
        text_("SKIP", 740, 28, 0, 0.8, 0.8)
    end

    -- ── History overlay ───────────────────────────────────────
    if show_history then
        -- Semi-transparent background
        lurek.render.setColor(0, 0, 0, 0.8)
        rect("fill", 30, 80, SCREEN_W - 60, 320)
        lurek.render.setColor(0.4, 0.4, 0.5, 0.6)
        rect("line", 30, 80, SCREEN_W - 60, 320)

        lurek.render.setColor(0.7, 0.7, 0.8, 0.9)
        text_("— Dialog History (H to close) —", 270, 88, 0, 0.85, 0.85)

        for i, entry in ipairs(dialog_log) do
            local col = (CHARS[entry.speaker] or CHARS.Narrator).color
            local ly = 115 + (i - 1) * 22
            lurek.render.setColor(col[1], col[2], col[3], 0.8)
            local prefix = entry.speaker
            local line = prefix .. ": " .. entry.text
            if #line > 90 then line = string.sub(line, 1, 87) .. "..." end
            text_(line, 45, ly, 0, 0.75, 0.75)
        end
    end

    -- ── Dialog box ────────────────────────────────────────────
    if text_box_alpha > 0.02 then
        -- Box background
        lurek.render.setColor(0.04, 0.04, 0.07, text_box_alpha)
        rect("fill", 0, DIALOG_BOX_Y, SCREEN_W, DIALOG_BOX_H)
        -- Box top border
        lurek.render.setColor(0.35, 0.35, 0.45, text_box_alpha * 0.6)
        rect("fill", 0, DIALOG_BOX_Y, SCREEN_W, 2)

        -- Speaker name tab
        if current_speaker ~= "" and current_speaker ~= "Narrator" then
            local sc = current_speaker_color
            lurek.render.setColor(sc[1] * 0.3, sc[2] * 0.3, sc[3] * 0.3, text_box_alpha * 0.9)
            rect("fill", 20, DIALOG_BOX_Y - 26, #current_speaker * 11 + 16, 24)
            lurek.render.setColor(sc[1], sc[2], sc[3], text_box_alpha)
            text_(current_speaker, 28, DIALOG_BOX_Y - 22, 0, 0.95, 0.95)
        end

        -- Dialog text
        lurek.render.setColor(0.9, 0.9, 0.95, text_fade_alpha * text_box_alpha)
        text_(typewriter_text, 30, DIALOG_BOX_Y + 18, 0, 0.9, 0.9)

        -- Advance indicator
        if typewriter_done() and current_state == STATE.SCENE then
            local blink = 0.4 + math.sin(t * 5) * 0.4
            lurek.render.setColor(0.7, 0.7, 0.8, blink)
            text_("▼", SCREEN_W - 40, DIALOG_BOX_Y + DIALOG_BOX_H - 25, 0, 1, 1)
        end
    end

    -- ── Choice options ────────────────────────────────────────
    if current_state == STATE.CHOICE and #choice_options > 0 then
        for i, opt in ipairs(choice_options) do
            local cy = DIALOG_BOX_Y + 50 + (i - 1) * 30
            local pulse_alpha = 0.7 + math.sin(choice_pulse + i * 0.8) * 0.2

            -- Choice background
            lurek.render.setColor(0.12, 0.12, 0.18, pulse_alpha * 0.6)
            rect("fill", 40, cy - 2, SCREEN_W - 80, 24)

            -- Number key indicator
            lurek.render.setColor(0.6, 0.5, 0.9, pulse_alpha)
            text_(string.format("[%d]", i), 50, cy, 0, 0.85, 0.85)

            -- Choice text
            lurek.render.setColor(0.9, 0.88, 0.95, pulse_alpha)
            text_(opt.text, 90, cy, 0, 0.85, 0.85)
        end
    end
end
