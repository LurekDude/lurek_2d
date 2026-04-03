--- Luna2D dialog sequencer — typewriter text, branching choices, events.
--
-- A pure-Lua replacement for the former `luna.dialog` Rust binding.
-- No engine dependencies; works in headless test VMs.
--
-- Usage:
--   local dialog = require("library.dialog")
--   local seq = dialog.newSequencer()
--   seq:setSpeed(25)
--   seq:on("line", function(speaker, text) print(speaker..": "..text) end)
--   seq:load({ {type="say",speaker="Alice",text="Hello!"} })
--   seq:start()
--   -- each frame: seq:update(dt)
--   -- on input:   seq:advance()  /  seq:choose(1)
--
-- @module library.dialog

local M = {}

-- ─── Internal constants ───────────────────────────────────────────────────────

local DEFAULT_CPS = 20  -- characters per second

-- ─── Node executor helpers ────────────────────────────────────────────────────

--- Flatten nested branch nodes into a linear sequence with jump markers.
-- Choices embed a jump-table so execution can branch then reconverge.
-- @local
local function flatten(nodes, out, next_after)
    out = out or {}
    for _, node in ipairs(nodes) do
        table.insert(out, node)
    end
    -- next_after is appended after this block converges (used by choice branches)
    return out
end

-- ─── Sequencer object ─────────────────────────────────────────────────────────

--- Create a new dialog sequencer.
-- The sequencer runs a list of dialog nodes one at a time, revealing
-- typewriter-style text, pausing for choices, and firing named callbacks.
--
-- States:
--   "idle"    — no script loaded or sequence ended, not started
--   "typing"  — revealing the current line character by character
--   "waiting" — current line fully revealed, waiting for advance()
--   "choice"  — waiting for the player to call choose(index)
--   "paused"  — a "wait" node is counting down
--   "done"    — sequence finished
--
-- @treturn table Sequencer object.
function M.newSequencer()
    local seq = {}
    local _nodes      = {}   -- flat array of node tables from load()
    local _pc         = 1    -- program counter (current node index)
    local _state      = "idle"
    local _cps        = DEFAULT_CPS
    local _revealed   = 0.0  -- chars revealed (float for fractional advance)
    local _speaker    = ""
    local _text       = ""
    local _choice_txt = ""
    local _choice_opts= {}   -- {label, branch} list
    local _wait_timer = 0.0
    local _handlers   = {}   -- event_name → list of callbacks
    local _pending_nodes = nil  -- nodes injected mid-sequence by a branch

    -- ── private helpers ────────────────────────────────────────────────────

    local function fire(event, ...)
        local list = _handlers[event]
        if list then
            for _, fn in ipairs(list) do
                fn(...)
            end
        end
    end

    local function set_state(s)
        _state = s
    end

    --- Advance PC to the next node, or finish if none.
    local function step()
        if _pending_nodes and #_pending_nodes > 0 then
            -- inject branch nodes before continuing main sequence
            local branch = _pending_nodes
            -- after branch, resume from _pc (already incremented)
            local remaining = {}
            for i = _pc, #_nodes do
                table.insert(remaining, _nodes[i])
            end
            _nodes = branch
            for _, n in ipairs(remaining) do
                table.insert(_nodes, n)
            end
            _pc = 1
            _pending_nodes = nil
        end

        if _pc > #_nodes then
            set_state("done")
            fire("finished")
            return
        end

        local node = _nodes[_pc]
        _pc = _pc + 1

        if node.type == "say" then
            _speaker  = node.speaker or ""
            _text     = node.text or ""
            _revealed = 0.0
            set_state("typing")
            fire("line", _speaker, _text)

        elseif node.type == "choice" then
            _choice_txt  = node.text or ""
            _choice_opts = node.options or {}
            set_state("choice")
            fire("choice")

        elseif node.type == "wait" then
            _wait_timer = node.time or 1.0
            set_state("paused")

        elseif node.type == "call" then
            if type(node.fn) == "function" then
                node.fn()
            end
            -- call nodes don't pause; run next immediately
            step()

        else
            -- unknown node type: skip silently
            step()
        end
    end

    -- ── public API ─────────────────────────────────────────────────────────

    --- Load a new script, replacing any existing one.
    -- Call start() afterwards to begin playback.
    -- @param nodes table Array of node tables.
    function seq:load(nodes)
        _nodes   = nodes or {}
        _pc      = 1
        _state   = "idle"
        _revealed = 0.0
        _speaker  = ""
        _text     = ""
        _choice_txt  = ""
        _choice_opts = {}
        _wait_timer  = 0.0
        _pending_nodes = nil
    end

    --- Begin playback from the first node.
    function seq:start()
        if #_nodes == 0 then
            set_state("done")
            fire("finished")
            return
        end
        _pc = 1
        set_state("idle")
        step()
    end

    --- Advance per-frame. Call every frame while isActive() is true.
    -- @param dt number Delta time in seconds.
    function seq:update(dt)
        if _state == "typing" then
            _revealed = _revealed + _cps * dt
            if _revealed >= #_text then
                _revealed = #_text
                set_state("waiting")
            end

        elseif _state == "paused" then
            _wait_timer = _wait_timer - dt
            if _wait_timer <= 0 then
                step()
            end
        end
    end

    --- Advance past the current line (when state == "waiting" or "typing").
    -- If typing, skips to full reveal first. If waiting, moves to next node.
    function seq:advance()
        if _state == "typing" then
            _revealed = #_text
            set_state("waiting")
        elseif _state == "waiting" then
            step()
        end
    end

    --- Skip the entire current line instantly (advances to "waiting").
    function seq:skip()
        if _state == "typing" or _state == "waiting" then
            _revealed = #_text
            set_state("waiting")
        end
    end

    --- Select a choice option by 1-based index.
    -- Only valid when state == "choice".
    -- @param index number 1-based index into getChoiceLabels().
    function seq:choose(index)
        if _state ~= "choice" then return end
        local opt = _choice_opts[index]
        if not opt then return end

        -- inject branch nodes
        if opt.branch and #opt.branch > 0 then
            _pending_nodes = opt.branch
        end

        set_state("idle")
        step()
    end

    --- Set the typewriter reveal speed.
    -- @param cps number Characters per second (default: 20).
    function seq:setSpeed(cps)
        _cps = cps or DEFAULT_CPS
    end

    --- Get the current reveal speed.
    -- @treturn number Characters per second.
    function seq:getSpeed()
        return _cps
    end

    --- Get the current state string.
    -- @treturn string One of: "idle", "typing", "waiting", "choice", "paused", "done".
    function seq:getState()
        return _state
    end

    --- Returns true while the sequence is in progress (not idle or done).
    -- @treturn boolean
    function seq:isActive()
        return _state ~= "idle" and _state ~= "done"
    end

    --- Returns true when a choice is pending player input.
    -- @treturn boolean
    function seq:isWaitingForChoice()
        return _state == "choice"
    end

    --- Returns the speaker name of the current "say" node.
    -- @treturn string
    function seq:currentSpeaker()
        return _speaker
    end

    --- Returns the full text of the current "say" node.
    -- @treturn string
    function seq:currentText()
        return _text
    end

    --- Returns only the revealed portion of the current text.
    -- @treturn string
    function seq:revealedText()
        local n = math.floor(_revealed)
        return string.sub(_text, 1, n)
    end

    --- Returns the prompt text of the current "choice" node.
    -- @treturn string
    function seq:getChoiceText()
        return _choice_txt
    end

    --- Returns an array of choice labels for the current "choice" node.
    -- @treturn table Array of strings.
    function seq:getChoiceLabels()
        local labels = {}
        for _, opt in ipairs(_choice_opts) do
            table.insert(labels, opt.label or "")
        end
        return labels
    end

    --- Register a callback for a named event.
    -- Events: "line" (speaker, text), "choice" (), "finished" ()
    -- @param event string Event name.
    -- @param fn function Callback function.
    function seq:on(event, fn)
        if not _handlers[event] then
            _handlers[event] = {}
        end
        table.insert(_handlers[event], fn)
    end

    --- Unregister all callbacks for a named event.
    -- @param event string Event name.
    function seq:off(event)
        _handlers[event] = nil
    end

    return seq
end

return M
