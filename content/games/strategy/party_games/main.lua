-- ============================================================
-- Party Games — 4 mini-game party collection
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/party_games
-- ============================================================

local W, H   = 800, 600
local state  = "menu"   -- menu | reaction | memory | typing | math | scoreboard
local scores = { 0, 0, 0, 0 }   -- up to 4 players
local players= 2
local round  = 0
local MAX_ROUNDS = 3

-- ── Mini-game state ───────────────────────────────────────

-- Reaction game
local reaction = { signal = false, signal_timer = 0, wait = 0, winner = 0, done = false, show_time = 0 }

-- Memory game
local memory = {
    seq      = {},
    input    = {},
    showing  = false,
    idx      = 0,
    show_t   = 0,
    stage    = "show",  -- show | input
    winner   = 0,
    done     = false,
}

-- Typing game
local typing = {
    words   = { "LUREK", "PLASMA", "ROCKET", "BANANA", "WIZARD" },
    current = "",
    typed   = { "", "" },
    winner  = 0,
    done    = false,
}

-- Math game
local math_game = {
    q      = "",
    answer = 0,
    p1buf  = "",
    p2buf  = "",
    winner = 0,
    done   = false,
}

-- Current mini-game
local mini_order = { "reaction", "memory", "typing", "math" }
local mini_idx   = 0

local celebration_sys = nil
local flash_col       = nil
local flash_t         = 0

-- ── Utils ────────────────────────────────────────────────
local function rand_seq(n)
    local t = {}
    for _ = 1, n do t[#t+1] = math.random(1, 4) end
    return t
end

local function gen_math()
    local a = math.random(2, 12)
    local b = math.random(2, 12)
    local op = math.random(1, 3)
    if op == 1 then return a .. " + " .. b, a + b
    elseif op == 2 then return a .. " × " .. b, a * b
    else
        local big = math.max(a, b)
        local sml = math.min(a, b)
        return big .. " - " .. sml, big - sml
    end
end

local function flash(r, g, b)
    flash_col = { r, g, b, 0.7 }
    flash_t   = 0.3
end

local function next_mini()
    mini_idx = mini_idx + 1
    if mini_idx > #mini_order then
        mini_idx = 1
        round    = round + 1
    end
    if round > MAX_ROUNDS then
        state = "scoreboard"
        if celebration_sys then celebration_sys:emit(W/2, H/2, 60) end
        return
    end
    state = mini_order[mini_idx]

    -- Reset mini-games
    if state == "reaction" then
        reaction = { signal = false, signal_timer = 0, wait = math.random() * 3 + 1, winner = 0, done = false, show_time = 0 }
    elseif state == "memory" then
        local seq = rand_seq(3 + round)
        memory = {
            seq = seq, input = {}, showing = true, idx = 1,
            show_t = 0.8, stage = "show", winner = 0, done = false
        }
    elseif state == "typing" then
        local w = typing.words[math.random(#typing.words)]
        typing = { words = typing.words, current = w, typed = { "", "" }, winner = 0, done = false }
    elseif state == "math" then
        local q, ans = gen_math()
        math_game = { q = q, answer = ans, p1buf = "", p2buf = "", winner = 0, done = false }
    end
end

-- ── Input bindings ────────────────────────────────────────
-- Player 1: keys 1-4 for memory, Z for reaction, Enter for submit
-- Player 2: WASD or numpad for memory, Shift for reaction, Space for submit
lurek.input.bind("p1_r",    "z")       -- reaction buzzer P1
lurek.input.bind("p2_r",    "shift")   -- reaction buzzer P2
lurek.input.bind("p1_1",    "1") ; lurek.input.bind("p1_2","2")
lurek.input.bind("p1_3",    "3") ; lurek.input.bind("p1_4","4")
lurek.input.bind("p2_1",    "kp1") ; lurek.input.bind("p2_2","kp2")
lurek.input.bind("p2_3",    "kp3") ; lurek.input.bind("p2_4","kp4")
lurek.input.bind("start",   "space")
lurek.input.bind("quit",    "escape")

-- ── Init ──────────────────────────────────────────────────

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
    lurek.window.setTitle("Party Games — Lurek2D")
    lurek.render.setBackgroundColor(0.06, 0.04, 0.12)
    math.randomseed(os.time())

    celebration_sys = lurek.particle.newSystem({
        maxParticles = 200,
        emitRate     = 0,
        lifetime     = { 0.5, 1.5 },
        speed        = { 80, 300 },
        startColor   = { 1.0, 0.9, 0.1, 1.0 },
        endColor     = { 0.8, 0.2, 0.0, 0.0 },
        startSize    = 8, endSize = 1,
        spread       = math.pi * 2,
    })
end

-- ── Process ───────────────────────────────────────────────
function lurek.process(dt)
    if celebration_sys then celebration_sys:update(dt) end
    if flash_t > 0 then flash_t = flash_t - dt end

    if lurek.input.wasActionPressed("quit") then lurek.event.quit() return end

    -- Menu
    if state == "menu" then
        if lurek.input.wasActionPressed("start") then
            round    = 1
            mini_idx = 0
            scores   = { 0, 0 }
            next_mini()
        end
        return
    end

    -- Scoreboard
    if state == "scoreboard" then return end

    -- ── Reaction ──────────────────────────────────────────
    if state == "reaction" then
        if reaction.done then
            if lurek.input.wasActionPressed("start") then next_mini() end
            return
        end
        if not reaction.signal then
            reaction.wait = reaction.wait - dt
            if reaction.wait <= 0 then
                reaction.signal = true
                reaction.signal_timer = os.clock()
            end
        else
            if lurek.input.wasActionPressed("p1_r") then
                local t = os.clock() - reaction.signal_timer
                reaction.winner    = 1
                reaction.done      = true
                reaction.show_time = t
                scores[1]          = scores[1] + 1
                flash(0.2, 0.9, 0.3)
            elseif lurek.input.wasActionPressed("p2_r") then
                local t = os.clock() - reaction.signal_timer
                reaction.winner    = 2
                reaction.done      = true
                reaction.show_time = t
                scores[2]          = scores[2] + 1
                flash(0.2, 0.3, 0.9)
            end
        end
        return
    end

    -- ── Memory ────────────────────────────────────────────
    if state == "memory" then
        if memory.done then
            if lurek.input.wasActionPressed("start") then next_mini() end
            return
        end
        if memory.stage == "show" then
            memory.show_t = memory.show_t - dt
            if memory.show_t <= 0 then
                memory.idx = memory.idx + 1
                if memory.idx > #memory.seq then
                    memory.stage = "input"
                    memory.idx   = 1
                else
                    memory.show_t = 0.7
                end
            end
        end
        return
    end

    -- ── Typing ────────────────────────────────────────────
    if state == "typing" then
        if typing.done then
            if lurek.input.wasActionPressed("start") then next_mini() end
        end
        return
    end

    -- ── Math ──────────────────────────────────────────────
    if state == "math" then
        if math_game.done then
            if lurek.input.wasActionPressed("start") then next_mini() end
        end
        return
    end
end

-- Helper to handle text input for math and typing (simplified polling)
function lurek.process(dt)
    if state ~= "typing" and state ~= "math" then return end

    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local digits  = "0123456789"
    local charset = (state == "typing") and letters or digits

    for i = 1, #charset do
        local ch = charset:sub(i, i)
        local key = (charset == digits) and "kp" .. ch or ch:lower()
        -- P1 types with lowercase keys, P2 with numpad (math) or shifted letters
        -- Simplified: just detect letter keypresses via lurek.input polling by name
    end

    -- Typing P1: regular keyboard letters
    if state == "typing" and not typing.done then
        -- Detect backspace
        -- We implement a basic approach: check each letter key
        local word = typing.current
        for i = 1, #word do
            local ch = word:sub(i, i):lower()
            if lurek.input.wasActionPressed(ch) then
                typing.typed[1] = typing.typed[1] .. word:sub(i, i)
                if typing.typed[1] == word then
                    typing.winner  = 1
                    typing.done    = true
                    scores[1]      = scores[1] + 1
                    flash(0.2, 0.9, 0.3)
                end
            end
        end
    end

    if state == "math" and not math_game.done then
        for _, d in ipairs({"0","1","2","3","4","5","6","7","8","9"}) do
            if lurek.input.wasActionPressed(d) then
                math_game.p1buf = math_game.p1buf .. d
                local n = tonumber(math_game.p1buf)
                if n and n == math_game.answer then
                    math_game.winner = 1
                    math_game.done   = true
                    scores[1]        = scores[1] + 1
                    flash(0.2, 0.9, 0.3)
                end
            end
        end
    end
end

-- ── Render world ──────────────────────────────────────────
function lurek.draw()
    if celebration_sys then celebration_sys:draw() end
    -- Flash overlay
    if flash_t > 0 and flash_col then
        local a = flash_t / 0.3 * flash_col[4]
        rect(0, 0, W, H, { color = { flash_col[1], flash_col[2], flash_col[3], a } })
    end
end

-- ── Render UI ─────────────────────────────────────────────
function lurek.draw_ui()
    if state == "menu" then
        text_("PARTY GAMES", 240, 180, { color = {1,0.8,0.2,1}, size = 48 })
        text_("Press SPACE to start", 268, 280, { color = {0.7,0.7,0.7,1}, size = 18 })
        text_("2 Players: P1=Z buzzer  P2=Shift buzzer", 180, 340, { color = {0.5,0.5,0.5,1}, size = 14 })
        return
    end

    if state == "scoreboard" then
        text_("FINAL SCORES", 250, 140, { color = {1,0.9,0.2,1}, size = 36 })
        text_("P1: " .. scores[1] .. " pts", 260, 230, { color = {0.2,0.8,0.4,1}, size = 28 })
        text_("P2: " .. scores[2] .. " pts", 260, 280, { color = {0.3,0.5,1.0,1}, size = 28 })
        local winner = scores[1] > scores[2] and "Player 1 Wins!" or scores[2] > scores[1] and "Player 2 Wins!" or "It's a Tie!"
        text_(winner, 270, 360, { color = {1,1,1,1}, size = 26 })
        return
    end

    -- Header
    text_("Round " .. round .. "/" .. MAX_ROUNDS, 20, 14, { color = {0.7,0.7,0.8,1}, size = 14 })
    text_("P1: " .. scores[1], 300, 14, { color = {0.3,0.9,0.4,1}, size = 14 })
    text_("P2: " .. scores[2], 420, 14, { color = {0.3,0.5,1.0,1}, size = 14 })

    if state == "reaction" then
        text_("REACTION GAME", 270, 80, { color = {1,0.7,0.2,1}, size = 24 })
        if not reaction.signal then
            text_("Wait for the signal...", 250, 200, { color = {0.6,0.6,0.6,1}, size = 20 })
        else
            rect(100, 180, 600, 120, { color = {0.1,0.8,0.2,0.9} })
            text_("NOW! P1=Z  P2=Shift", 240, 225, { color = {0,0,0,1}, size = 24 })
        end
        if reaction.done then
            text_("Player " .. reaction.winner .. " wins! (" .. string.format("%.3f", reaction.show_time) .. "s)", 180, 340, { color = {1,1,1,1}, size = 20 })
            text_("Space=continue", 320, 380, { color = {0.5,0.5,0.5,1}, size = 14 })
        end

    elseif state == "memory" then
        text_("MEMORY GAME", 280, 80, { color = {0.6,0.8,1.0,1}, size = 24 })
        if memory.stage == "show" and memory.idx <= #memory.seq then
            local num = memory.seq[memory.idx]
            rect(350, 200, 80, 80, { color = {0.2,0.5,0.9,1} })
            text_(tostring(num), 376, 228, { color = {1,1,1,1}, size = 36 })
            text_("Watch the sequence!", 270, 320, { color = {0.7,0.7,0.7,1}, size = 16 })
        elseif memory.stage == "input" then
            text_("Repeat the sequence! P1: keys 1-4", 200, 240, { color = {1,0.8,0.3,1}, size = 18 })
        end
        if memory.done then
            text_("Player " .. memory.winner .. " remembered it!", 220, 340, { color = {1,1,1,1}, size = 20 })
            text_("Space=continue", 320, 380, { color = {0.5,0.5,0.5,1}, size = 14 })
        end

    elseif state == "typing" then
        text_("TYPING RACE", 290, 80, { color = {0.9,0.6,1.0,1}, size = 24 })
        text_("Type: " .. typing.current, 280, 200, { color = {1,1,1,1}, size = 28 })
        text_("P1: " .. typing.typed[1], 200, 280, { color = {0.3,0.9,0.4,1}, size = 22 })
        if typing.done then
            text_("Player " .. typing.winner .. " wins!", 290, 360, { color = {1,1,1,1}, size = 22 })
            text_("Space=continue", 320, 400, { color = {0.5,0.5,0.5,1}, size = 14 })
        end

    elseif state == "math" then
        text_("MATH DUEL", 300, 80, { color = {1.0,0.8,0.3,1}, size = 28 })
        text_(math_game.q .. " = ?", 310, 200, { color = {1,1,1,1}, size = 32 })
        text_("P1 answer: " .. math_game.p1buf, 220, 300, { color = {0.3,0.9,0.4,1}, size = 20 })
        text_("Type digits to answer", 260, 360, { color = {0.5,0.5,0.5,1}, size = 14 })
        if math_game.done then
            text_("Player " .. math_game.winner .. " wins!", 290, 420, { color = {1,1,1,1}, size = 22 })
            text_("Space=continue", 320, 456, { color = {0.5,0.5,0.5,1}, size = 14 })
        end
    end
end
