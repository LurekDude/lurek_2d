-- Dialog Demo – Luna2D dialog sequencer example
-- Demonstrates typewriter text, choices, events, and call nodes.

local dialog = require("library.dialog")

local seq
local log_lines = {}

local function log(msg)
    table.insert(log_lines, msg)
    if #log_lines > 12 then table.remove(log_lines, 1) end
end

function luna.init()
    seq = dialog.newSequencer()
    seq:setSpeed(25) -- 25 characters per second

    -- Register event callbacks
    seq:on("line", function(speaker, text)
        log("[line] " .. speaker .. ": " .. text)
    end)
    seq:on("choice", function()
        log("[choice] Waiting for player input...")
    end)
    seq:on("finished", function()
        log("[finished] Dialog complete!")
    end)

    -- Load a script with say, choice, wait, and call nodes
    seq:load({
        { type = "say", speaker = "Guide", text = "Welcome to the Luna2D dialog demo!" },
        { type = "say", speaker = "Guide", text = "This shows typewriter text, choices, and events." },
        { type = "choice", text = "How do you feel about it?", options = {
            { label = "Awesome!", branch = {
                { type = "say", speaker = "Guide", text = "Glad you like it!" },
                { type = "call", fn = function() log("[call] Player chose Awesome!") end },
            }},
            { label = "Tell me more", branch = {
                { type = "say", speaker = "Guide", text = "The sequencer handles typewriter reveal, choices, waits, and callbacks." },
                { type = "say", speaker = "Guide", text = "All from simple Lua tables." },
            }},
            { label = "Not sure yet", branch = {
                { type = "wait", time = 1.0 },
                { type = "say", speaker = "Guide", text = "Take your time!" },
            }},
        }},
        { type = "say", speaker = "Guide", text = "Thanks for trying the dialog system!" },
    })
    seq:start()
end

function luna.process(dt)
    if seq and seq:isActive() then
        seq:update(dt)
    end
end

function luna.render()
    -- Background
    luna.gfx.setBackgroundColor(0.12, 0.12, 0.18, 1)

    -- Title
    luna.gfx.setColor(0.6, 0.8, 1.0, 1)
    luna.gfx.print("Dialog Demo", 20, 15)
    luna.gfx.setColor(0.5, 0.5, 0.6, 1)
    luna.gfx.print("Space=advance  1-9=choose  S=skip  R=restart", 20, 40)

    -- Dialog box
    local bx, by, bw, bh = 40, 80, 720, 160
    luna.gfx.setColor(0.15, 0.15, 0.22, 0.95)
    luna.gfx.rectangle("fill", bx, by, bw, bh)
    luna.gfx.setColor(0.4, 0.5, 0.7, 1)
    luna.gfx.rectangle("line", bx, by, bw, bh)

    if seq then
        local state = seq:getState()

        -- Speaker name
        if state == "typing" or state == "waiting" then
            luna.gfx.setColor(1, 0.85, 0.3, 1)
            luna.gfx.print(seq:currentSpeaker(), bx + 15, by + 10)
            -- Revealed text
            luna.gfx.setColor(1, 1, 1, 1)
            luna.gfx.print(seq:revealedText(), bx + 15, by + 40)
            -- State indicator
            luna.gfx.setColor(0.5, 0.5, 0.5, 1)
            if state == "typing" then
                luna.gfx.print("...", bx + bw - 40, by + bh - 25)
            else
                luna.gfx.print("[Space to continue]", bx + bw - 180, by + bh - 25)
            end
        elseif state == "choice" then
            luna.gfx.setColor(1, 0.85, 0.3, 1)
            luna.gfx.print(seq:getChoiceText(), bx + 15, by + 10)
            local labels = seq:getChoiceLabels()
            for i, label in ipairs(labels) do
                luna.gfx.setColor(0.7, 0.9, 1, 1)
                luna.gfx.print(i .. ". " .. label, bx + 30, by + 30 + i * 25)
            end
        elseif state == "paused" then
            luna.gfx.setColor(0.7, 0.7, 0.7, 1)
            luna.gfx.print("(waiting...)", bx + 15, by + 40)
        elseif state == "done" then
            luna.gfx.setColor(0.5, 0.7, 0.5, 1)
            luna.gfx.print("Dialog complete. Press R to restart.", bx + 15, by + 40)
        elseif state == "idle" then
            luna.gfx.setColor(0.5, 0.5, 0.5, 1)
            luna.gfx.print("Press Space to start.", bx + 15, by + 40)
        end
    end

    -- Event log
    luna.gfx.setColor(0.3, 0.3, 0.4, 1)
    luna.gfx.rectangle("fill", 40, 260, 720, 310)
    luna.gfx.setColor(0.5, 0.5, 0.6, 1)
    luna.gfx.print("Event Log:", 50, 265)
    luna.gfx.setColor(0.8, 0.8, 0.8, 1)
    for i, line in ipairs(log_lines) do
        luna.gfx.print(line, 50, 280 + i * 20)
    end
end

function luna.keypressed(key)
    if not seq then return end
    if key == "space" then
        seq:advance()
    elseif key == "s" then
        seq:skip()
    elseif key == "r" then
        luna.load() -- restart
    elseif seq:isWaitingForChoice() then
        local n = tonumber(key)
        if n and n >= 1 then
            local labels = seq:getChoiceLabels()
            if n <= #labels then
                seq:choose(n)
            end
        end
    end
end
