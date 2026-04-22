--- Lurek2D dialog sequencer ÔÇö typewriter text, branching choices, events.
--
-- A pure-Lua replacement for the former `lurek.dialog` Rust binding.
-- No engine dependencies; works in headless test VMs.
-- Optional: uses `lurek.log.debug()` when available for dialog progression tracing.
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
-- @status full
-- @see lurek.patterns.newEventBus  optional event bus mirror returned by `seq:getEventBus()`
-- @see lurek.event.newSignal      alternative scoped pub/sub backbone
-- @see lurek.i18n.t        translate `say`/`choice` text fields before passing them in
-- @see lurek.serial.toJson          serialise/deserialise script node arrays for persistence

local M = {}

-- Optional cross-VM EventBus factory (resolved once at load time).
local _bus_factory
if type(lurek) == "table" and type(lurek.patterns) == "table"
   and type(lurek.patterns.newEventBus) == "function" then
    _bus_factory = lurek.patterns.newEventBus
end

-- ÔöÇÔöÇÔöÇ Internal constants ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local DEFAULT_CPS = 20  -- characters per second
local MAX_JUMPS   = 100 -- max jumps per step() to prevent infinite loops

-- Optional logging (safe in headless tests where lurek may not exist)
local _log
pcall(function()
    _log = lurek and lurek.log
end)
local function log_debug(msg)
    if _log then _log.debug(msg) end
end

-- ÔöÇÔöÇÔöÇ Sequencer object ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Create a new dialog sequencer.
-- The sequencer runs a list of dialog nodes one at a time, revealing
-- typewriter-style text, pausing for choices, and firing named callbacks.
--
-- States:
--   "idle"    ÔÇö no script loaded or sequence ended, not started
--   "typing"  ÔÇö revealing the current line character by character
--   "waiting" ÔÇö current line fully revealed, waiting for advance()
--   "choice"  ÔÇö waiting for the player to call choose(index)
--   "paused"  ÔÇö a "wait" node is counting down
--   "done"    ÔÇö sequence finished
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
    local _handlers   = {}   -- event_name -> list of callbacks (canonical fallback)
    local _bus        = nil  -- optional lurek.patterns EventBus mirror (lazy)
    if _bus_factory then
        local ok, bus = pcall(_bus_factory)
        if ok then _bus = bus end
    end
    local _pending_nodes = nil  -- nodes injected mid-sequence by a branch
    local _jump_count    = 0    -- jump counter for loop detection

    -- ÔöÇÔöÇ private helpers ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    local function fire(event, ...)
        local list = _handlers[event]
        if list then
            for _, fn in ipairs(list) do
                fn(...)
            end
        end
        -- Optional mirror to lurek.patterns EventBus so external listeners
        -- subscribed via seq:getEventBus() also receive the event. Failures
        -- are silently demoted (the canonical _handlers path is unaffected).
        if _bus and _bus.emit then
            local args = {...}   -- capture varargs for LuaJIT closure (cannot use ... inside nested fn)
            pcall(function() _bus:emit(event, unpack(args)) end)
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
            log_debug("dialog: sequence done")
            set_state("done")
            fire("finished")
            fire("done")
            return
        end

        local node = _nodes[_pc]
        _pc = _pc + 1

        -- cond predicate: skip node when condition returns false (pcall for safety)
        if type(node.cond) == "function" then
            local ok, result = pcall(node.cond)
            if not ok then
                log_debug("dialog: cond() threw: " .. tostring(result))
            end
            if not ok or not result then
                step()
                return
            end
        end

        if node.type == "say" then
            _speaker  = node.speaker or ""
            _text     = node.text or ""
            _revealed = 0.0
            set_state("typing")
            log_debug("dialog: say [" .. _speaker .. "]")
            fire("line", _speaker, _text)

        elseif node.type == "choice" then
            _choice_txt  = node.text or ""
            _choice_opts = node.options or {}
            set_state("choice")
            log_debug("dialog: choice (" .. #_choice_opts .. " options)")
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

        elseif node.type == "event" then
            -- fire named hook then continue immediately
            fire("event", node.name, node.data)
            step()

        elseif node.type == "jump" then
            _jump_count = _jump_count + 1
            if _jump_count > MAX_JUMPS then
                log_debug("dialog: jump loop detected (>" .. MAX_JUMPS .. " jumps), forcing done")
                set_state("done")
                fire("finished")
                fire("done")
                return
            end
            -- find the node whose .label matches node.target and jump to it
            local target = node.target or node.label
            log_debug("dialog: jump -> " .. tostring(target))
            for i, n in ipairs(_nodes) do
                if n.label == target then
                    _pc = i
                    break
                end
            end
            step()

        else
            -- unknown node type: skip silently
            step()
        end
    end

    -- ÔöÇÔöÇ public API ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    --- Load a new script, replacing any existing one.
    -- Call start() afterwards to begin playback.
    -- @tparam table nodes Array of node tables (nil treated as empty).
    function seq:load(nodes)
        if nodes ~= nil and type(nodes) ~= "table" then
            error("dialog:load() expects a table of nodes, got " .. type(nodes), 2)
        end
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
        _jump_count    = 0
    end

    --- Begin playback from the first node.
    function seq:start()
        _jump_count = 0
        if #_nodes == 0 then
            set_state("done")
            fire("finished")
            fire("done")
            return
        end
        _pc = 1
        set_state("idle")
        log_debug("dialog: start (" .. #_nodes .. " nodes)")
        step()
    end

    --- Advance per-frame. Call every frame while isActive() is true.
    -- @tparam number dt Delta time in seconds (clamped to >= 0).
    function seq:update(dt)
        if type(dt) ~= "number" then
            error("dialog:update() expects a number dt, got " .. type(dt), 2)
        end
        if dt <= 0 then return end
        if _state == "typing" then
            local old_revealed = _revealed
            _revealed = _revealed + _cps * dt
            if _revealed >= #_text then
                _revealed = #_text
                set_state("waiting")
            end
            -- fire "typewrite(char, full_text)" once per newly revealed character
            local old_count = math.floor(old_revealed)
            local new_count = math.floor(_revealed)
            for i = old_count + 1, new_count do
                fire("typewrite", string.sub(_text, i, i), _text)
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
    -- @tparam number index 1-based index into getChoiceLabels().
    function seq:choose(index)
        if _state ~= "choice" then return end
        if type(index) ~= "number" then
            error("dialog:choose() expects a number index, got " .. type(index), 2)
        end
        index = math.floor(index)
        if index < 1 or index > #_choice_opts then
            error("dialog:choose() index " .. index .. " out of range 1.." .. #_choice_opts, 2)
        end
        local opt = _choice_opts[index]
        if not opt then return end

        log_debug("dialog: chose option " .. index .. " [" .. (opt.label or "") .. "]")

        -- inject branch nodes
        if opt.branch and #opt.branch > 0 then
            _pending_nodes = opt.branch
        end

        set_state("idle")
        step()
    end

    --- Set the typewriter reveal speed.
    -- @tparam number cps Characters per second (default: 20).
    function seq:setSpeed(cps)
        if cps ~= nil and type(cps) ~= "number" then
            error("dialog:setSpeed() expects a number, got " .. type(cps), 2)
        end
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
    -- Events: "line" (speaker, text), "choice" (), "finished" (), "done" (),
    -- "event" (name, data), "typewrite" (char, full_text).
    -- @tparam string event Event name.
    -- @tparam function fn Callback function.
    function seq:on(event, fn)
        if type(event) ~= "string" then
            error("dialog:on() expects a string event name, got " .. type(event), 2)
        end
        if type(fn) ~= "function" then
            error("dialog:on() expects a function callback, got " .. type(fn), 2)
        end
        if not _handlers[event] then
            _handlers[event] = {}
        end
        table.insert(_handlers[event], fn)
    end

    --- Unregister all callbacks for a named event.
    -- @tparam string event Event name.
    function seq:off(event)
        if type(event) ~= "string" then
            error("dialog:off() expects a string event name, got " .. type(event), 2)
        end
        _handlers[event] = nil
    end

    --- Return the optional `lurek.patterns` EventBus mirror, or nil when the
    -- engine is not present. External systems can subscribe to any of the
    -- sequencer's events through the bus without going through `seq:on()`.
    -- The canonical event delivery path remains the local handler table, so
    -- the bus is purely a parallel observer channel.
    -- @treturn table|nil EventBus instance, or nil when unavailable.
    -- @see lurek.patterns.newEventBus
    function seq:getEventBus()
        return _bus
    end

    return seq
end


-- ÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉ
-- NODE CONSTRUCTOR HELPERS
-- ÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉ

--- Create a `say` dialog node (spoken line with typewriter reveal).
-- @param actor string Speaker name.
-- @param text string Line to reveal.
-- @param opts table Optional extra fields merged into the node (e.g. cond, label).
-- @treturn table Node table: { type="say", speaker, text, ... }.
function M.say(actor, text, opts)
    local node = {}
    if opts then for k, v in pairs(opts) do node[k] = v end end
    node.type    = "say"
    node.speaker = actor or ""
    node.text    = text  or ""
    return node
end

--- Create a `choice` dialog node (branching prompt).
-- @param prompt string Prompt text shown above options.
-- @param options table Array of { label, branch } tables.
-- @param opts table Optional extra fields merged into the node.
-- @treturn table Node table: { type="choice", text, options, ... }.
function M.choice(prompt, options, opts)
    local node = {}
    if opts then for k, v in pairs(opts) do node[k] = v end end
    node.type    = "choice"
    node.text    = prompt  or ""
    node.options = options or {}
    return node
end

--- Create a `wait` dialog node (timed pause).
-- @param seconds number Duration of the pause in seconds.
-- @param opts table Optional extra fields merged into the node.
-- @treturn table Node table: { type="wait", time, ... }.
function M.wait(seconds, opts)
    local node = {}
    if opts then for k, v in pairs(opts) do node[k] = v end end
    node.type = "wait"
    node.time = seconds or 1.0
    return node
end

--- Create an `event` dialog node (named hook signal).
-- When executed, fires `seq:on("event", fn)` with (name, data) then advances.
-- @param name string Event name.
-- @param data any Optional payload passed to the callback.
-- @param opts table Optional extra fields merged into the node.
-- @treturn table Node table: { type="event", name, data, ... }.
function M.event(name, data, opts)
    local node = {}
    if opts then for k, v in pairs(opts) do node[k] = v end end
    node.type = "event"
    node.name = name
    node.data = data
    return node
end

--- Create a `call` dialog node (inline Lua callback).
-- When executed, calls `fn()` immediately and advances without pausing.
-- @param fn function Callback to invoke.
-- @param opts table Optional extra fields merged into the node.
-- @treturn table Node table: { type="call", fn, ... }.
function M.call(fn, opts)
    local node = {}
    if opts then for k, v in pairs(opts) do node[k] = v end end
    node.type = "call"
    node.fn   = fn
    return node
end

--- Create a `jump` dialog node (label-based control transfer).
-- Execution resumes at the first node in the current script whose `.label`
-- field equals `target`. Unknown targets are silently skipped.
-- @param target string Target label name.
-- @param opts table Optional extra fields merged into the node.
-- @treturn table Node table: { type="jump", target, ... }.
function M.jump(target, opts)
    local node = {}
    if opts then for k, v in pairs(opts) do node[k] = v end end
    node.type   = "jump"
    node.target = target
    return node
end

-- ÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉ
-- PARITY ADDITIONS ÔÇö Phase 2A  (dialog)
-- ÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉ

--- Dialog-graph node-type enum.
-- @field SAY
-- @field CHOICE
-- @field WAIT
-- @field EVENT
-- @field CALL
-- @field JUMP
M.NodeType = {
    SAY    = "say",
    CHOICE = "choice",
    WAIT   = "wait",
    EVENT  = "event",
    CALL   = "call",
    JUMP   = "jump",
}

--- Sequencer runtime-state enum.
-- Matches the strings returned by seq:getState().
-- @field IDLE
-- @field TYPING
-- @field WAITING
-- @field CHOICE
-- @field PAUSED
-- @field DONE
-- @field RUNNING Legacy alias for TYPING.
-- @field WAITING_CHOICE Legacy alias for CHOICE.
M.SequencerState = {
    IDLE           = "idle",
    TYPING         = "typing",
    WAITING        = "waiting",
    CHOICE         = "choice",
    PAUSED         = "paused",
    DONE           = "done",
    -- Legacy aliases (pre-2A names kept for backward compatibility)
    RUNNING        = "typing",
    WAITING_CHOICE = "choice",
}

return M
