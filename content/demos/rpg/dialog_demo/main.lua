-- Dialog Demo – Lurek2D dialog sequencer example
-- Demonstrates typewriter text, choices, events, and call nodes.
-- Run with: cargo run -- content/demos/rpg/dialog_demo

local dialog = require("library.dialog")

local seq
local log_lines = {}

local function log(msg)
    table.insert(log_lines, msg)
    if #log_lines > 12 then table.remove(log_lines, 1) end
end

function lurek.init()
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
        { type = "say", speaker = "Guide", text = "Welcome to the Lurek2D dialog demo!" },
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

function lurek.process(dt)
    if seq and seq:isActive() then
        seq:update(dt)
    end
end

function lurek.render()
    -- Background
    lurek.render.setBackgroundColor(0.12, 0.12, 0.18, 1)

    -- Title
    lurek.render.setColor(0.6, 0.8, 1.0, 1)
    lurek.render.print("Dialog Demo", 20, 15)
    lurek.render.setColor(0.5, 0.5, 0.6, 1)
    lurek.render.print("Space=advance  1-9=choose  S=skip  R=restart", 20, 40)

    -- Dialog box
    local bx, by, bw, bh = 40, 80, 720, 160
    lurek.render.setColor(0.15, 0.15, 0.22, 0.95)
    lurek.render.rectangle("fill", bx, by, bw, bh)
    lurek.render.setColor(0.4, 0.5, 0.7, 1)
    lurek.render.rectangle("line", bx, by, bw, bh)

    if seq then
        local state = seq:getState()

        -- Speaker name
        if state == "typing" or state == "waiting" then
            lurek.render.setColor(1, 0.85, 0.3, 1)
            lurek.render.print(seq:currentSpeaker(), bx + 15, by + 10)
            -- Revealed text
            lurek.render.setColor(1, 1, 1, 1)
            lurek.render.print(seq:revealedText(), bx + 15, by + 40)
            -- State indicator
            lurek.render.setColor(0.5, 0.5, 0.5, 1)
            if state == "typing" then
                lurek.render.print("...", bx + bw - 40, by + bh - 25)
            else
                lurek.render.print("[Space to continue]", bx + bw - 180, by + bh - 25)
            end
        elseif state == "choice" then
            lurek.render.setColor(1, 0.85, 0.3, 1)
            lurek.render.print(seq:getChoiceText(), bx + 15, by + 10)
            local labels = seq:getChoiceLabels()
            for i, label in ipairs(labels) do
                lurek.render.setColor(0.7, 0.9, 1, 1)
                lurek.render.print(i .. ". " .. label, bx + 30, by + 30 + i * 25)
            end
        elseif state == "paused" then
            lurek.render.setColor(0.7, 0.7, 0.7, 1)
            lurek.render.print("(waiting...)", bx + 15, by + 40)
        elseif state == "done" then
            lurek.render.setColor(0.5, 0.7, 0.5, 1)
            lurek.render.print("Dialog complete. Press R to restart.", bx + 15, by + 40)
        elseif state == "idle" then
            lurek.render.setColor(0.5, 0.5, 0.5, 1)
            lurek.render.print("Press Space to start.", bx + 15, by + 40)
        end
    end

    -- Event log
    lurek.render.setColor(0.3, 0.3, 0.4, 1)
    lurek.render.rectangle("fill", 40, 260, 720, 310)
    lurek.render.setColor(0.5, 0.5, 0.6, 1)
    lurek.render.print("Event Log:", 50, 265)
    lurek.render.setColor(0.8, 0.8, 0.8, 1)
    for i, line in ipairs(log_lines) do
        lurek.render.print(line, 50, 280 + i * 20)
    end
end

function lurek.keypressed(key)
    if not seq then return end
    if key == "space" then
        seq:advance()
    elseif key == "s" then
        seq:skip()
    elseif key == "r" then
        lurek.signal.restart() -- restart
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
