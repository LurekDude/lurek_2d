--- Lurek2D narrative library — Ink-flavoured branching narrative interpreter.
--
-- Pure-Lua implementation of a usable subset of inkle's Ink scripting language.
-- Supports knots, diverts, sticky/regular choices, variables, conditional
-- choices, inline `{var}` and `{fn(arg)}` substitution, tags, visit counters,
-- and save/resume.
--
-- Supported Ink subset:
--
--   === knot_name ===            -- knot header
--   Plain prose lines.            -- emitted by continue()
--   -> next_knot                  -- divert
--   -> END   (or -> DONE)         -- end story
--   * text                        -- one-shot choice
--   + text                        -- sticky choice (re-selectable)
--   * { condition } text          -- conditional choice
--   { variable } / { fn(args) }   -- inline value substitution
--   # tag                         -- attach tag to last emitted line
--   VAR name = value              -- declare initial variable
--   ~ name = expr                 -- run-line variable assignment
--   // line comment               -- ignored
--
-- Usage:
--   local narrative = require("library.narrative")
--   local story = narrative.compile([[
--       === START ===
--       Hello, {player_name}.
--       * Greet the king | -> COURT
--       * Leave silently | -> END
--       === COURT ===
--       The court applauds. # music:fanfare
--       -> END
--   ]]):start()
--
-- @module library.narrative
-- @status partial
-- @see lurek.filesystem.read         load `.ink` files
-- @see lurek.serial.toJson    precompile / save state serialisation
-- @see lurek.save        wire `story:save`/`resume` into a SaveManager
-- @see lurek.i18n.t  used by `M.localiseStory` for {loc:key} markers
-- @see lurek.event          optional trace event sink

local M = {}

local table_unpack = table.unpack or unpack

-- ─── helpers ─────────────────────────────────────────────────────────────────

local function _trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function _split_lines(src)
    local out = {}
    for line in (src .. "\n"):gmatch("([^\n]*)\n") do
        out[#out + 1] = line
    end
    return out
end

local function _is_blank(s) return s:match("^%s*$") ~= nil end

-- ─── compiler ────────────────────────────────────────────────────────────────

local function _compile(src)
    local knots = {}    -- knot_name -> { nodes = {...} }
    local order = {}    -- ordered list of knot names
    local current = nil

    local function ensure_knot(name)
        if not knots[name] then
            knots[name] = { name = name, nodes = {} }
            order[#order + 1] = name
        end
        return knots[name]
    end

    local lines = _split_lines(src)
    for lineno, raw in ipairs(lines) do
        local line = raw
        -- strip comments
        local cidx = line:find("//", 1, true)
        if cidx then line = line:sub(1, cidx - 1) end
        line = _trim(line)

        if line == "" then
            -- skip
        elseif line:match("^===%s*[%w_]+%s*===$") or line:match("^===%s*[%w_]+%s*=*$") then
            local name = line:match("^===%s*([%w_]+)")
            current = ensure_knot(name)
        elseif line:sub(1, 4) == "VAR " then
            local name, val = line:match("^VAR%s+([%w_]+)%s*=%s*(.+)$")
            if not name then
                error(string.format("narrative: line %d: malformed VAR: %s", lineno, raw), 3)
            end
            ensure_knot("__decl__").nodes[#ensure_knot("__decl__").nodes + 1] = {
                kind = "var_decl", name = name, expr = val,
            }
        elseif line:sub(1, 1) == "~" then
            current = current or ensure_knot("START")
            local body = _trim(line:sub(2))
            current.nodes[#current.nodes + 1] = { kind = "set", expr = body }
        elseif line:sub(1, 2) == "->" then
            current = current or ensure_knot("START")
            local target = _trim(line:sub(3))
            current.nodes[#current.nodes + 1] = { kind = "divert", target = target }
        elseif line:sub(1, 1) == "*" or line:sub(1, 1) == "+" then
            current = current or ensure_knot("START")
            local sticky = line:sub(1, 1) == "+"
            local body = _trim(line:sub(2))
            -- Optional condition: { cond } text...
            local cond_expr, rest = body:match("^{%s*(.-)%s*}%s*(.*)$")
            local text = rest or body
            -- Optional inline divert: text | -> knot
            local divert_to
            local pipe = text:find("|", 1, true)
            if pipe then
                local lhs = _trim(text:sub(1, pipe - 1))
                local rhs = _trim(text:sub(pipe + 1))
                local d = rhs:match("^%->%s*(.+)$")
                if d then
                    text = lhs
                    divert_to = _trim(d)
                end
            end
            -- Tag inline at end: text # tag
            local tags = {}
            text = text:gsub("%s*#%s*([%w_:%-%.]+)", function(t)
                tags[#tags + 1] = t; return ""
            end)
            text = _trim(text)
            current.nodes[#current.nodes + 1] = {
                kind = "choice", text = text, sticky = sticky,
                cond_expr = cond_expr, divert_to = divert_to, tags = tags,
            }
        elseif line:sub(1, 1) == "#" then
            current = current or ensure_knot("START")
            current.nodes[#current.nodes + 1] = {
                kind = "tag", name = _trim(line:sub(2)),
            }
        else
            -- Prose line. Inline `# tag` markers attach to it.
            current = current or ensure_knot("START")
            local tags = {}
            local text = line:gsub("%s*#%s*([%w_:%-%.]+)", function(t)
                tags[#tags + 1] = t; return ""
            end)
            current.nodes[#current.nodes + 1] = {
                kind = "line", text = _trim(text), tags = tags,
            }
        end
    end

    if not knots["START"] and not knots["ENTRY"] then
        -- Allow first declared knot to act as entry.
        if #order == 0 then
            error("narrative: no knots in source", 3)
        end
    end
    return { knots = knots, order = order }
end

-- ─── expression evaluator ────────────────────────────────────────────────────

-- Evaluates an expression string against the story's variable + bound function
-- environment. Uses the host Lua `load` with a sandboxed `_ENV`.
local function _eval(expr, story)
    local env = {}
    setmetatable(env, { __index = function(_, k)
        local v = story._vars[k]
        if v ~= nil then return v end
        local fn = story._fns[k]
        if fn then return fn end
        return nil
    end, __newindex = function(_, k, v) story._vars[k] = v end })

    local chunk, err
    if _VERSION == "Lua 5.1" then
        chunk, err = loadstring("return " .. expr)
        if not chunk then chunk, err = loadstring(expr) end
        if chunk then setfenv(chunk, env) end
    else
        chunk, err = load("return " .. expr, "narr_expr", "t", env)
        if not chunk then chunk, err = load(expr, "narr_expr", "t", env) end
    end
    if not chunk then
        error("narrative: bad expression '"..expr.."': "..tostring(err), 3)
    end
    local ok, val = pcall(chunk)
    if not ok then
        error("narrative: expression failed '"..expr.."': "..tostring(val), 3)
    end
    return val
end

-- Substitutes `{expr}` markers in a prose line using the given story's env.
local function _substitute(text, story)
    return (text:gsub("{(.-)}", function(expr)
        local v = _eval(expr, story)
        if v == nil then return "" end
        return tostring(v)
    end))
end

-- ─── Story object ────────────────────────────────────────────────────────────

local Story = {}
Story.__index = Story

local function _new_story(prog)
    return setmetatable({
        _prog        = prog,
        _vars        = {},
        _fns         = {},
        _visits      = {},   -- knot -> count
        _last_visit  = {},   -- knot -> turn number
        _turn        = 0,
        _knot        = nil,
        _pc          = 0,
        _ended       = false,
        _pending_choices = nil,
        _last_tags   = {},
        _trace       = false,
        _tag_handlers      = {},
        _var_handlers      = {},
        _next_handle_id    = 1,
    }, Story)
end

local function _apply_var_decls(story)
    local decls = story._prog.knots["__decl__"]
    if not decls then return end
    for _, n in ipairs(decls.nodes) do
        if n.kind == "var_decl" then
            local ok, val = pcall(_eval, n.expr, story)
            story._vars[n.name] = ok and val or n.expr
        end
    end
end

--- Compile Ink-subset source into a Story program (not yet started).
-- @param source string
-- @treturn Story
-- @raise on parse error.
function M.compile(source)
    if type(source) ~= "string" then error("compile: source must be string", 2) end
    local prog = _compile(source)
    return _new_story(prog)
end

--- Load and compile a .ink file via `lurek.filesystem.read`.
-- @param path string
-- @treturn Story
function M.loadFile(path)
    if type(lurek) ~= "table" or type(lurek.filesystem) ~= "table"
       or type(lurek.filesystem.read) ~= "function" then
        error("narrative.loadFile: lurek.filesystem.read unavailable", 2)
    end
    local ok, src = pcall(lurek.filesystem.read, path)
    if not ok then error("narrative.loadFile: "..tostring(src), 2) end
    return M.compile(src)
end

--- Produce a serialisable AST blob (cacheable).
-- @param source string
-- @treturn table bytecode
function M.precompile(source)
    return _compile(source)
end

--- Restore a precompiled program into a fresh Story.
-- @param blob table
-- @treturn Story
function M.fromBytecode(blob)
    if type(blob) ~= "table" or type(blob.knots) ~= "table" then
        error("fromBytecode: expected precompile() output", 2)
    end
    return _new_story(blob)
end

--- Reset to the entry knot. Defaults to `START` (or first declared knot).
-- @param knot string?
-- @treturn Story self
function Story:start(knot)
    self._vars       = {}
    self._fns        = self._fns or {}
    self._visits     = {}
    self._last_visit = {}
    self._turn       = 0
    self._ended      = false
    self._pending_choices = nil
    self._last_tags  = {}
    _apply_var_decls(self)

    knot = knot or "START"
    if not self._prog.knots[knot] then
        -- fallback to first non-decl knot
        for _, name in ipairs(self._prog.order) do
            if name ~= "__decl__" then knot = name; break end
        end
    end
    self:gotoKnot(knot)
    return self
end

--- True while there is more prose to emit before the next choice or end.
-- @treturn boolean
function Story:canContinue()
    if self._ended or self._pending_choices then return false end
    return self._knot ~= nil
end

--- True when the playhead is at a choice point.
function Story:isAtChoice() return self._pending_choices ~= nil end

--- True when the story has reached `-> END`.
function Story:isEnded() return self._ended end

local function _gather_choices(self)
    local out = {}
    local nodes = self._prog.knots[self._knot].nodes
    while self._pc <= #nodes do
        local n = nodes[self._pc]
        if n.kind ~= "choice" then break end
        local available = true
        if n.cond_expr then
            local ok, v = pcall(_eval, n.cond_expr, self)
            available = ok and v and true or false
        end
        out[#out + 1] = {
            text      = _substitute(n.text, self),
            available = available,
            tags      = n.tags or {},
            sticky    = n.sticky,
            divert_to = n.divert_to,
            _pc       = self._pc,
        }
        self._pc = self._pc + 1
    end
    return out
end

--- Emit the next prose line; returns nil at choice points or end.
-- Also returns the tag list attached to the line.
-- @treturn string?, table tags
function Story:continue()
    if self._ended then return nil, {} end
    if self._pending_choices then return nil, {} end
    if not self._knot then return nil, {} end

    local nodes = self._prog.knots[self._knot].nodes
    while self._pc <= #nodes do
        local n = nodes[self._pc]
        self._pc = self._pc + 1

        if n.kind == "line" then
            self._last_tags = n.tags or {}
            for _, t in ipairs(self._last_tags) do
                local hs = self._tag_handlers[t]
                if hs then for _, h in ipairs(hs) do h.fn(t) end end
            end
            if self._trace and lurek and lurek.log then
                lurek.log.debug("[narrative] line: "..n.text)
            end
            return _substitute(n.text, self), self._last_tags
        elseif n.kind == "tag" then
            self._last_tags[#self._last_tags + 1] = n.name
            local hs = self._tag_handlers[n.name]
            if hs then for _, h in ipairs(hs) do h.fn(n.name) end end
        elseif n.kind == "set" then
            -- assignment: parse "name = expr"
            local name, expr = n.expr:match("^([%w_]+)%s*=%s*(.+)$")
            if name then
                local ok, v = pcall(_eval, expr, self)
                if ok then
                    local prev = self._vars[name]
                    self._vars[name] = v
                    local hs = self._var_handlers[name]
                    if hs then for _, h in ipairs(hs) do h.fn(v, prev) end end
                end
            end
        elseif n.kind == "divert" then
            self:gotoKnot(n.target)
            if self._ended then return nil, {} end
            nodes = self._prog.knots[self._knot].nodes
        elseif n.kind == "choice" then
            -- step back so _gather_choices sees it
            self._pc = self._pc - 1
            self._pending_choices = _gather_choices(self)
            return nil, {}
        end
    end
    -- end of knot without divert -> implicit END
    self._ended = true
    return nil, {}
end

--- Drain prose until a choice or end, returning the joined string.
-- @param sep string? Line separator (default "\n").
-- @treturn string
function Story:continueAll(sep)
    sep = sep or "\n"
    local buf = {}
    while self:canContinue() do
        local s = self:continue()
        if s and s ~= "" then buf[#buf + 1] = s end
    end
    return table.concat(buf, sep)
end

--- Get the current pending choice list.
-- @treturn table Array of `{text, available, tags, index}`.
function Story:getChoices()
    if not self._pending_choices then return {} end
    local out = {}
    for i, c in ipairs(self._pending_choices) do
        out[i] = { text = c.text, available = c.available, tags = c.tags, index = i }
    end
    return out
end

--- Select a choice by 1-based index. Raises if not available.
-- @param index integer
-- @treturn Story self
function Story:choose(index)
    if not self._pending_choices then
        error("Story:choose: not at a choice point", 2)
    end
    local c = self._pending_choices[index]
    if not c then
        error("Story:choose: choice index "..tostring(index).." out of range", 2)
    end
    if not c.available then
        error("Story:choose: choice "..tostring(index).." is not available", 2)
    end
    self._pending_choices = nil
    self._pc = c._pc + 1   -- advance past the choice
    if c.divert_to then
        self:gotoKnot(c.divert_to)
    end
    return self
end

--- Set a variable.
function Story:setVar(name, value)
    local prev = self._vars[name]
    self._vars[name] = value
    local hs = self._var_handlers[name]
    if hs then for _, h in ipairs(hs) do h.fn(value, prev) end end
    return self
end

--- Get a variable.
function Story:getVar(name) return self._vars[name] end

--- Snapshot of all variables (shallow copy).
function Story:listVars()
    local out = {}
    for k, v in pairs(self._vars) do out[k] = v end
    return out
end

--- Bind a Lua function callable from inside `{name(arg)}` markers.
function Story:bindFunction(name, fn)
    self._fns[name] = fn
    return self
end

--- Register a tag handler. Returns an opaque handle for `offTag`.
function Story:onTag(tag, fn)
    self._tag_handlers[tag] = self._tag_handlers[tag] or {}
    local h = { id = self._next_handle_id, fn = fn, tag = tag, kind = "tag" }
    self._next_handle_id = self._next_handle_id + 1
    self._tag_handlers[tag][#self._tag_handlers[tag] + 1] = h
    return h
end

--- Remove a previously registered tag handler.
function Story:offTag(handle)
    if not handle then return end
    local list = self._tag_handlers[handle.tag]
    if not list then return end
    for i, h in ipairs(list) do
        if h.id == handle.id then table.remove(list, i); return end
    end
end

--- Register a variable-change handler.
function Story:onVarChange(name, fn)
    self._var_handlers[name] = self._var_handlers[name] or {}
    local h = { id = self._next_handle_id, fn = fn, name = name, kind = "var" }
    self._next_handle_id = self._next_handle_id + 1
    self._var_handlers[name][#self._var_handlers[name] + 1] = h
    return h
end

--- Jump to a knot. Records the visit and turn counter.
function Story:gotoKnot(name)
    if name == "END" or name == "DONE" then
        self._ended = true
        self._knot = nil
        return self
    end
    if not self._prog.knots[name] then
        error("narrative: unknown knot '"..tostring(name).."'", 2)
    end
    self._turn = self._turn + 1
    self._visits[name] = (self._visits[name] or 0) + 1
    self._last_visit[name] = self._turn
    self._knot = name
    self._pc   = 1
    self._pending_choices = nil
    return self
end

--- Visit count of a knot.
function Story:visit(knot) return self._visits[knot] or 0 end

--- Turns since a knot was last visited (math.huge if never).
function Story:turnsSince(knot)
    local t = self._last_visit[knot]
    if not t then return math.huge end
    return self._turn - t
end

Story.divertTo = Story.gotoKnot

--- Toggle trace logging via `lurek.log.debug` (requires it to be available).
function Story:trace(enable)
    self._trace = enable ~= false
    return self
end

--- Profile the current story state (visits + var counts).
function Story:dumpProfile()
    local var_count = 0
    for _ in pairs(self._vars) do var_count = var_count + 1 end
    return {
        turn = self._turn, knot = self._knot, ended = self._ended,
        visits = self._visits, var_count = var_count,
    }
end

--- Serialise full state (vars, visits, knot, pc) for `lurek.save`.
function Story:save()
    local vars = {}
    for k, v in pairs(self._vars) do
        if type(v) == "number" or type(v) == "string" or type(v) == "boolean" then
            vars[k] = v
        end
    end
    local visits = {}
    for k, v in pairs(self._visits) do visits[k] = v end
    return {
        vars = vars, visits = visits, turn = self._turn,
        knot = self._knot, pc = self._pc, ended = self._ended,
    }
end

--- Restore from a save blob.
function Story:resume(state)
    if type(state) ~= "table" then error("Story:resume: blob required", 2) end
    self._vars   = state.vars   or {}
    self._visits = state.visits or {}
    self._turn   = state.turn   or 0
    self._knot   = state.knot
    self._pc     = state.pc or 1
    self._ended  = state.ended or false
    self._pending_choices = nil
    return self
end

-- ─── module helpers ──────────────────────────────────────────────────────────

--- Parse a `# tag1 # tag2` style string into an array.
function M.parseTagList(str)
    local out = {}
    for t in str:gmatch("#%s*([%w_:%-%.]+)") do
        out[#out + 1] = t
    end
    return out
end

--- Pick a weighted choice from a `{ {text, weight} ... }` list using rng.
function M.weightedChoice(choices, rng)
    if not choices or #choices == 0 then return nil end
    local total = 0
    for _, c in ipairs(choices) do total = total + (c.weight or 1) end
    local u = (rng and rng:random() or math.random()) * total
    local acc = 0
    for _, c in ipairs(choices) do
        acc = acc + (c.weight or 1)
        if u <= acc then return c end
    end
    return choices[#choices]
end

--- Format a list of values as natural prose: "a, b, and c".
function M.formatList(values, conjunction)
    conjunction = conjunction or "and"
    local n = #values
    if n == 0 then return "" end
    if n == 1 then return tostring(values[1]) end
    if n == 2 then return values[1] .. " " .. conjunction .. " " .. values[2] end
    local out = {}
    for i = 1, n - 1 do out[i] = tostring(values[i]) end
    return table.concat(out, ", ") .. ", " .. conjunction .. " " .. tostring(values[n])
end

--- Attach a `{loc:KEY}` localisation pre-processor using `lurek.i18n.t`.
function M.localiseStory(story, locale)
    if not (lurek and lurek.i18n and lurek.i18n.t) then
        return story
    end
    if locale and lurek.i18n.setLanguage then
        pcall(lurek.i18n.setLanguage, locale)
    end
    -- Wrap continue to translate {loc:key} markers post-substitution.
    local orig = story.continue
    story.continue = function(self)
        local line, tags = orig(self)
        if line then
            line = (line:gsub("{loc:([%w_%.]+)}", function(k)
                local ok, v = pcall(lurek.i18n.t, k)
                return ok and v or k
            end))
        end
        return line, tags
    end
    return story
end

M.Story    = Story
M._unpack  = table_unpack

return M
