--- Lurek2D rhythm library — BPM-locked event sequencer over `lurek.audio`.
--
-- Turns audio playhead time into beat-grid scheduling for rhythm games and
-- music-reactive levels. Two main pieces:
--
--   * `Clock`  — beat clock with BPM, swing, ramp, and audio-source binding.
--   * `M.judge` — judgement window scoring for player input timing.
--
-- The clock is independent of `lurek.timer.Scheduler` (which is wall-time
-- based) — beat math accounts for BPM ramps and audio source seeks.
--
-- @module library.rhythm
-- @status full
-- @see lurek.audio       Source playhead drives `M.fromAudio` and `:syncToAudio`
-- @see lurek.timer        `getMicroTime` powers default `M.judge` hit time
-- @see lurek.event      optional emit on `rhythm.bar`/`rhythm.beat`/`rhythm.miss`
-- @see lurek.save    `clock:dump` collector wiring

local M = {}

local table_unpack = table.unpack or unpack
local floor, abs   = math.floor, math.abs

-- ─── helpers ─────────────────────────────────────────────────────────────────

local function _now()
    if lurek and lurek.timer and lurek.timer.getMicroTime then
        local ok, t = pcall(lurek.timer.getMicroTime)
        if ok and type(t) == "number" then return t end
    end
    return os.clock()
end

local function _beats_per_second(bpm) return bpm / 60.0 end

-- ─── Clock ───────────────────────────────────────────────────────────────────

local Clock = {}
Clock.__index = Clock

local function _new_clock(bpm, opts)
    opts = opts or {}
    return setmetatable({
        _bpm           = bpm,
        _target_bpm    = nil,
        _ramp_t        = 0,
        _ramp_dur      = 0,
        _start_bpm     = bpm,
        _subdivision   = opts.subdivision or 4,
        _swing         = opts.swing or 0,
        _latency       = (opts.latency_ms or 0) / 1000.0,
        _running       = false,
        _t             = 0,    -- seconds since start (clock-local)
        _audio_src     = nil,
        _audio_anchor  = 0,    -- audio time at last anchor
        _local_anchor  = 0,
        _last_beat_int = -1,
        _last_bar_int  = -1,
        _handles       = {},   -- list of scheduler entries
        _next_id       = 1,
    }, Clock)
end

--- Build a free-running BPM clock.
function M.newClock(bpm, opts)
    if type(bpm) ~= "number" or bpm <= 0 then
        error("rhythm.newClock: bpm must be > 0", 2)
    end
    return _new_clock(bpm, opts)
end

--- Build a clock anchored to an `lurek.audio` Source's playhead.
function M.fromAudio(source, bpm, opts)
    local c = _new_clock(bpm, opts)
    c._audio_src = source
    return c
end

function Clock:setBpm(bpm)
    if bpm <= 0 then error("setBpm: bpm must be > 0", 2) end
    self._bpm        = bpm
    self._target_bpm = nil
    self._ramp_dur   = 0
    return self
end

function Clock:rampBpm(target, seconds)
    if target <= 0 or seconds <= 0 then
        error("rampBpm: positive target & seconds required", 2)
    end
    self._target_bpm = target
    self._start_bpm  = self._bpm
    self._ramp_t     = 0
    self._ramp_dur   = seconds
    return self
end

function Clock:getBpm() return self._bpm end

function Clock:setSwing(amount) self._swing = amount or 0; return self end

function Clock:start()
    self._running       = true
    self._t             = 0
    self._last_beat_int = -1
    self._last_bar_int  = -1
    if self._audio_src and self._audio_src.getPosition then
        local ok, pos = pcall(function() return self._audio_src:getPosition() end)
        self._audio_anchor = ok and pos or 0
    end
    self._local_anchor = 0
    return self
end

function Clock:stop()       self._running = false; return self end
function Clock:isRunning()  return self._running end

local function _advance_bpm_ramp(self, dt)
    if not self._target_bpm then return end
    self._ramp_t = self._ramp_t + dt
    if self._ramp_t >= self._ramp_dur then
        self._bpm        = self._target_bpm
        self._target_bpm = nil
        return
    end
    local f = self._ramp_t / self._ramp_dur
    self._bpm = self._start_bpm + (self._target_bpm - self._start_bpm) * f
end

function Clock:update(dt)
    if not self._running then return self end
    _advance_bpm_ramp(self, dt)

    if self._audio_src and self._audio_src.getPosition then
        local ok, pos = pcall(function() return self._audio_src:getPosition() end)
        if ok and pos then
            self._t = (pos - self._audio_anchor) + self._local_anchor
        else
            self._t = self._t + dt
        end
    else
        self._t = self._t + dt
    end

    -- Fire scheduler handles whose target beat has been crossed.
    local beat_now = self:getBeat()
    local beat_int_now = floor(beat_now)
    if beat_int_now > self._last_beat_int then
        self._last_beat_int = beat_int_now
        if lurek and lurek.event and lurek.event.push then
            pcall(lurek.event.push, "rhythm.beat", beat_int_now)
        end
    end
    local bar_int_now = floor(beat_now / self._subdivision)
    if bar_int_now > self._last_bar_int then
        self._last_bar_int = bar_int_now
        if lurek and lurek.event and lurek.event.push then
            pcall(lurek.event.push, "rhythm.bar", bar_int_now)
        end
    end

    for _, h in ipairs(self._handles) do
        if not h.cancelled then
            if h.kind == "every" then
                local subdiv = h.division
                local target_beat = math.floor(beat_now * subdiv / self._subdivision + 1e-9)
                while h.last_step < target_beat do
                    h.last_step = h.last_step + 1
                    h.fn(h.last_step)
                end
            elseif h.kind == "at" then
                if not h.fired and beat_now >= h.beat then
                    h.fired = true
                    h.fn(h.beat)
                end
            elseif h.kind == "pattern" then
                local subdiv = #h.string
                local steps_per_bar = subdiv
                local pos_in_bar = (beat_now / self._subdivision) * steps_per_bar
                local step_now = floor(pos_in_bar)
                while h.last_step < step_now do
                    h.last_step = h.last_step + 1
                    local idx = (h.last_step % subdiv) + 1
                    if h.string:sub(idx, idx) == "x" then
                        h.fn(h.last_step)
                    end
                end
            end
        end
    end

    return self
end

function Clock:syncToAudio(source)
    self._audio_src = source
    if source and source.getPosition then
        local ok, pos = pcall(function() return source:getPosition() end)
        self._audio_anchor = ok and pos or 0
    end
    self._local_anchor = self._t
    return self
end

--- Fractional beats since `:start()`.
function Clock:getBeat()
    return self._t * _beats_per_second(self._bpm)
end

function Clock:getBar()
    return self:getBeat() / self._subdivision
end

function Clock:getPhase(division)
    division = division or self._subdivision
    local beats = self:getBeat() * (division / self._subdivision)
    return beats - floor(beats)
end

function Clock:beatTimeRemaining(division)
    division = division or self._subdivision
    local phase = self:getPhase(division)
    local seconds_per_step = 60.0 / (self._bpm * (division / self._subdivision))
    return (1.0 - phase) * seconds_per_step
end

function Clock:isOnBeat(division, tolerance)
    division  = division  or self._subdivision
    tolerance = tolerance or 0.05
    local phase = self:getPhase(division)
    return phase < tolerance or (1 - phase) < tolerance
end

function Clock:nearestBeat(division)
    division = division or self._subdivision
    local beats = self:getBeat() * (division / self._subdivision)
    local nearest = math.floor(beats + 0.5)
    local err_beats = beats - nearest
    local seconds_per_step = 60.0 / (self._bpm * (division / self._subdivision))
    return nearest * (self._subdivision / division), err_beats * seconds_per_step
end

-- ─── Scheduler API on the clock ─────────────────────────────────────────────

function Clock:every(division, fn)
    local h = {
        kind = "every", division = division, fn = fn,
        last_step = math.floor(self:getBeat() * division / self._subdivision),
        cancelled = false,
        id = self._next_id,
    }
    self._next_id = self._next_id + 1
    self._handles[#self._handles + 1] = h
    return h
end

function Clock:at(beat, fn)
    if beat < self:getBeat() then
        error("Clock:at: beat is in the past", 2)
    end
    local h = {
        kind = "at", beat = beat, fn = fn, fired = false,
        cancelled = false, id = self._next_id,
    }
    self._next_id = self._next_id + 1
    self._handles[#self._handles + 1] = h
    return h
end

function Clock:pattern(str, fn)
    if type(str) ~= "string" or #str == 0 then
        error("Clock:pattern: string must be non-empty", 2)
    end
    local h = {
        kind = "pattern", string = str, fn = fn,
        last_step = -1, cancelled = false, id = self._next_id,
    }
    self._next_id = self._next_id + 1
    self._handles[#self._handles + 1] = h
    return h
end

function Clock:cancel(handle)
    if not handle then return false end
    handle.cancelled = true
    for i, h in ipairs(self._handles) do
        if h.id == handle.id then table.remove(self._handles, i); return true end
    end
    return false
end

function Clock:cancelAll()
    self._handles = {}
    return self
end

function Clock:dump()
    return {
        bpm = self._bpm, beat = self:getBeat(), bar = self:getBar(),
        phase = self:getPhase(), running = self._running,
    }
end

-- ─── Judgement scoring ──────────────────────────────────────────────────────

local _windows = { perfect = 0.025, great = 0.05, good = 0.10 }

function M.setJudgementWindows(w)
    if type(w) ~= "table" then error("setJudgementWindows: table required", 2) end
    _windows.perfect = w.perfect or _windows.perfect
    _windows.great   = w.great   or _windows.great
    _windows.good    = w.good    or _windows.good
end

function M.getJudgementWindows()
    return { perfect = _windows.perfect, great = _windows.great, good = _windows.good }
end

--- Judge a player input against the nearest beat at `division`.
-- @param clock Clock
-- @param division integer Beat subdivision (e.g. 4 = quarter notes, 8 = 8ths).
-- @param hit_time number? Time of the hit (defaults to now via `lurek.timer`).
-- @treturn string verdict — `"perfect" | "great" | "good" | "miss"`.
-- @treturn number error_seconds — signed offset (negative = early).
function M.judge(clock, division, hit_time)
    division = division or clock._subdivision
    local now = hit_time or _now()
    -- Translate `now` into clock time when the hit occurred.
    -- For simplicity we trust the clock's own `_t` if `hit_time` was omitted.
    local _, err_seconds = clock:nearestBeat(division)
    if hit_time then
        local seconds_per_step = 60.0 / (clock._bpm * (division / clock._subdivision))
        local beats = (clock._t + (now - _now())) * _beats_per_second(clock._bpm)
                      * (division / clock._subdivision)
        local nearest = math.floor(beats + 0.5)
        err_seconds = (beats - nearest) * seconds_per_step
    end
    local mag = abs(err_seconds)
    if mag <= _windows.perfect then return "perfect", err_seconds end
    if mag <= _windows.great   then return "great",   err_seconds end
    if mag <= _windows.good    then return "good",    err_seconds end
    if lurek and lurek.event and lurek.event.push then
        pcall(lurek.event.push, "rhythm.miss", err_seconds)
    end
    return "miss", err_seconds
end

M.Clock   = Clock
M._unpack = table_unpack

return M
