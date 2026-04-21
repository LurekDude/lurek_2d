--- Lurek2D cinematic library — multi-track scrubbable cutscene timeline.
--
-- Sequences `lurek.tween`, `lurek.camera`, `lurek.audio`, `lurek.event`,
-- and `library.dialog` clips into a single time-positioned timeline that
-- supports play/pause/seek/scrub/skip-to-label/branch.
--
-- Each track is a sorted list of clips: `{at, duration, kind, params,
-- on_apply, on_revert}`. The timeline owns its own clock — it does not use
-- `lurek.timer.Scheduler`.
--
-- @module library.cinematic
-- @status partial
-- @see lurek.tween         backbone for `track:tween` clips
-- @see lurek.camera        consumed by `track:cameraTo` / `track:shake`
-- @see lurek.audio         consumed by `track:audio` (one-shot fire)
-- @see lurek.event        consumed by `track:signal`
-- @see lurek.filesystem            timeline TOML loader (`fromToml`)
-- @see lurek.serial         JSON serialisation for `tl:export`
-- @see lurek.save      collector wiring for export/restore

local M = {}
local table_unpack = table.unpack or unpack

-- ─── Track ──────────────────────────────────────────────────────────────────

local Track = {}
Track.__index = Track

local function _new_track(timeline, name)
    return setmetatable({
        _name     = name,
        _timeline = timeline,
        _clips    = {},
    }, Track)
end

local function _sort_clips(self)
    table.sort(self._clips, function(a, b) return a.at < b.at end)
end

local function _push(self, clip)
    clip.at       = clip.at       or 0
    clip.duration = clip.duration or 0
    clip.fired    = false
    clip.applied  = false
    self._clips[#self._clips + 1] = clip
    _sort_clips(self)
    self._timeline:_recompute_duration()
    return self
end

--- Add a generic clip table.
-- @param clip table `{at, duration, kind, params, on_apply, on_revert}`.
function Track:add(clip)
    if type(clip) ~= "table" or type(clip.at) ~= "number" then
        error("Track:add: clip must include numeric 'at'", 2)
    end
    return _push(self, clip)
end

--- Tween clip. Wraps `lurek.tween` if available; always applies final value
-- if the engine binding is missing (so logic-only tests still pass).
function Track:tween(at, duration, target, props, easing)
    return _push(self, {
        kind     = "tween",
        at       = at,
        duration = duration,
        target   = target,
        props    = props,
        easing   = easing,
        on_apply = function(clip)
            if lurek and lurek.tween and lurek.tween.to then
                pcall(lurek.tween.to, clip.target, clip.duration,
                    clip.props, clip.easing)
            else
                for k, v in pairs(clip.props) do clip.target[k] = v end
            end
        end,
        on_revert = function(clip)
            -- Best effort: snap back to recorded initial values if any.
            if clip._initial then
                for k, v in pairs(clip._initial) do clip.target[k] = v end
            end
        end,
        reversible = true,
    })
end

--- Camera move clip.
function Track:cameraTo(at, duration, x, y, zoom, easing)
    return _push(self, {
        kind = "camera", at = at, duration = duration,
        params = { x = x, y = y, zoom = zoom, easing = easing },
        on_apply = function(clip)
            local cam = lurek and lurek.camera
            if cam and cam.setPosition then pcall(cam.setPosition, clip.params.x, clip.params.y) end
            if cam and cam.setZoom and clip.params.zoom then pcall(cam.setZoom, clip.params.zoom) end
        end,
        reversible = true,
    })
end

--- Camera shake clip.
function Track:shake(at, duration, intensity)
    return _push(self, {
        kind = "shake", at = at, duration = duration, intensity = intensity,
        on_apply = function(clip)
            local cam = lurek and lurek.camera
            if cam and cam.shake then pcall(cam.shake, clip.duration, clip.intensity) end
        end,
        reversible = false,
    })
end

--- Dialog clip — fires once forward only.
function Track:dialog(at, line)
    return _push(self, {
        kind = "dialog", at = at, duration = 0, line = line,
        on_apply = function(clip)
            local cb = clip._timeline._dialog_handler
            if cb then cb(clip.line) end
        end,
        reversible = false,
    })
end

--- Audio clip — fires once forward only.
function Track:audio(at, source, opts)
    opts = opts or {}
    return _push(self, {
        kind = "audio", at = at, duration = opts.duration or 0,
        source = source, opts = opts,
        on_apply = function(clip)
            local au = lurek and lurek.audio
            if au and au.play then pcall(au.play, clip.source, clip.opts) end
        end,
        reversible = false,
    })
end

--- Signal clip — emits via `lurek.event.push` (or queues for later read).
function Track:signal(at, name, ...)
    local args = { ... }
    return _push(self, {
        kind = "signal", at = at, duration = 0, name = name, args = args,
        on_apply = function(clip)
            local s = lurek and lurek.event
            if s and s.push then pcall(s.push, clip.name, table_unpack(clip.args)) end
        end,
        reversible = false,
    })
end

--- Generic Lua callback. Mark `reversible = true` to allow backward seeks.
function Track:call(at, fn, opts)
    opts = opts or {}
    return _push(self, {
        kind = "call", at = at, duration = 0, fn = fn,
        on_apply = function(clip) clip.fn(clip._timeline) end,
        reversible = opts.reversible == true,
    })
end

--- Wait clip — pauses the timeline until `predicate_fn()` returns true.
function Track:wait(at, predicate_fn)
    return _push(self, {
        kind = "wait", at = at, duration = 0, predicate = predicate_fn,
        reversible = true,
    })
end

--- Remove a clip by reference.
function Track:remove(clip)
    for i, c in ipairs(self._clips) do
        if c == clip then table.remove(self._clips, i); break end
    end
    self._timeline:_recompute_duration()
    return self
end

-- ─── Timeline ───────────────────────────────────────────────────────────────

local Timeline = {}
Timeline.__index = Timeline

--- Create a new timeline.
-- @param opts table? `{loop=false, autoStart=false, timeScale=1.0}`.
-- @treturn Timeline
function M.newTimeline(opts)
    opts = opts or {}
    local tl = setmetatable({
        _tracks       = {},
        _track_order  = {},
        _t            = 0,
        _last_t       = 0,
        _duration     = 0,
        _playing      = false,
        _finished     = false,
        _scale        = opts.timeScale or 1.0,
        _loop         = opts.loop or false,
        _labels       = {},   -- name -> at
        _on_complete  = {},
        _on_track_enter = {},
        _branches     = {},
        _next_handle  = 1,
        _dialog_handler = nil,
    }, Timeline)
    if opts.autoStart then tl._playing = true end
    return tl
end

--- Load a timeline from a TOML file via `lurek.filesystem.read` + `lurek.serial.fromToml`.
function M.fromToml(path)
    if not (lurek and lurek.filesystem and lurek.filesystem.read) then
        error("cinematic.fromToml: lurek.filesystem.read unavailable", 2)
    end
    if not (lurek.serial and lurek.serial.fromToml) then
        error("cinematic.fromToml: lurek.serial.fromToml unavailable", 2)
    end
    local ok, src = pcall(lurek.filesystem.read, path)
    if not ok then error("cinematic.fromToml: "..tostring(src), 2) end
    local ok2, data = pcall(lurek.serial.fromToml, src)
    if not ok2 then error("cinematic.fromToml: "..tostring(data), 2) end
    return M.fromTable(data)
end

--- Build a timeline from a declarative spec table.
function M.fromTable(spec)
    local tl = M.newTimeline(spec.opts)
    for _, tdef in ipairs(spec.tracks or {}) do
        local tr = tl:track(tdef.name or "main")
        for _, c in ipairs(tdef.clips or {}) do tr:add(c) end
    end
    return tl
end

--- Get-or-create a track by name.
function Timeline:track(name)
    if self._tracks[name] then return self._tracks[name] end
    local tr = _new_track(self, name)
    self._tracks[name] = tr
    self._track_order[#self._track_order + 1] = name
    return tr
end

function Timeline:tracks()
    local out = {}
    for i, n in ipairs(self._track_order) do out[i] = self._tracks[n] end
    return out
end

--- Recompute total duration from the latest clip end.
function Timeline:_recompute_duration()
    local max = 0
    for _, tr in pairs(self._tracks) do
        for _, c in ipairs(tr._clips) do
            local e = (c.at or 0) + (c.duration or 0)
            if e > max then max = e end
        end
    end
    self._duration = max
end

--- Bind a dialog handler `fn(line)` invoked by `track:dialog` clips.
function Timeline:setDialogHandler(fn)
    self._dialog_handler = fn
    return self
end

function Timeline:play()    self._playing = true;  self._finished = false; return self end
function Timeline:pause()   self._playing = false; return self end
function Timeline:resume()  self._playing = true;  return self end
function Timeline:stop()    self._playing = false; self._t = 0; self._finished = false; return self end
function Timeline:isPlaying()  return self._playing end
function Timeline:isFinished() return self._finished end
function Timeline:getTime()    return self._t end
function Timeline:getDuration() return self._duration end
function Timeline:setTimeScale(s) self._scale = s; return self end

--- Add a labelled cue point.
function Timeline:label(at, name)
    self._labels[name] = at
    return self
end

--- Add a branch — `child_timeline` runs at `at` only when `predicate(tl)` is true.
function Timeline:branch(at, predicate, child)
    self._branches[#self._branches + 1] = { at = at, predicate = predicate, child = child, fired = false }
    return self
end

local function _fire_clips(self, t0, t1)
    -- Forward direction only: fire clips whose `at` falls in (t0, t1].
    for _, name in ipairs(self._track_order) do
        local tr = self._tracks[name]
        for _, c in ipairs(tr._clips) do
            if not c.fired and c.at > t0 and c.at <= t1 then
                if c.kind == "wait" then
                    if not c.predicate() then
                        -- Block timeline — clamp t and pause progression.
                        self._t = c.at
                        self._playing = false
                        return false
                    else
                        c.fired = true
                    end
                else
                    if c.on_apply then
                        c._timeline = self
                        if c.kind == "tween" and c.target and c.props then
                            c._initial = c._initial or {}
                            for k in pairs(c.props) do
                                c._initial[k] = c._initial[k] == nil and c.target[k] or c._initial[k]
                            end
                        end
                        local ok, err = pcall(c.on_apply, c)
                        if not ok and lurek and lurek.log then
                            pcall(lurek.log.warn, "cinematic clip failed: "..tostring(err))
                        end
                    end
                    c.fired   = true
                    c.applied = true
                    local hs = self._on_track_enter[name]
                    if hs then for _, h in ipairs(hs) do h.fn(c) end end
                end
            end
        end
    end
    return true
end

local function _revert_after(self, target_t)
    -- Backward seek: revert reversible clips that were applied past target_t.
    -- Non-reversible applied clips raise an error.
    for _, name in ipairs(self._track_order) do
        local tr = self._tracks[name]
        for _, c in ipairs(tr._clips) do
            if c.applied and c.at > target_t then
                if c.reversible then
                    if c.on_revert then pcall(c.on_revert, c) end
                    c.fired   = false
                    c.applied = false
                else
                    error(string.format(
                        "cinematic: cannot rewind past non-reversible '%s' clip at %.3f",
                        c.kind, c.at), 3)
                end
            end
        end
    end
end

local function _eval_branches(self, t0, t1)
    for _, b in ipairs(self._branches) do
        if not b.fired and b.at > t0 and b.at <= t1 then
            b.fired = true
            if b.predicate(self) then
                b.child:play()
                self._child = b.child
            end
        end
    end
end

--- Advance timeline by `dt`. Call once per frame from `lurek.process`.
function Timeline:update(dt)
    if not self._playing then
        if self._child then self._child:update(dt) end
        return self
    end
    local t0 = self._t
    local t1 = t0 + dt * self._scale
    if t1 < 0 then t1 = 0 end
    if t1 > self._duration then t1 = self._duration end

    if t1 < t0 then
        _revert_after(self, t1)
        self._t = t1
    else
        if not _fire_clips(self, t0, t1) then return self end
        _eval_branches(self, t0, t1)
        self._t = t1
    end

    if self._child then self._child:update(dt) end

    if not self._finished and self._t >= self._duration and self._scale > 0 then
        self._finished = true
        self._playing = self._loop
        if self._loop then self._t = 0; self:_reset_clip_flags() end
        for _, h in ipairs(self._on_complete) do h.fn(self) end
    end
    return self
end

function Timeline:_reset_clip_flags()
    for _, tr in pairs(self._tracks) do
        for _, c in ipairs(tr._clips) do
            c.fired = false; c.applied = false
        end
    end
end

--- Seek to absolute time.
function Timeline:setTime(t)
    if t < 0 then t = 0 end
    if t > self._duration then t = self._duration end
    if t < self._t then
        _revert_after(self, t)
        self._t = t
    else
        _fire_clips(self, self._t, t)
        _eval_branches(self, self._t, t)
        self._t = t
    end
    return self
end

function Timeline:scrub(delta) return self:setTime(self._t + delta) end
function Timeline:rewind()     return self:setTime(0) end

function Timeline:skipTo(label)
    local at = self._labels[label]
    if not at then error("Timeline:skipTo: unknown label '"..tostring(label).."'", 2) end
    return self:setTime(at)
end

function Timeline:onComplete(fn)
    local h = { id = self._next_handle, fn = fn, kind = "complete" }
    self._next_handle = self._next_handle + 1
    self._on_complete[#self._on_complete + 1] = h
    return h
end

function Timeline:onTrackEnter(name, fn)
    self._on_track_enter[name] = self._on_track_enter[name] or {}
    local h = { id = self._next_handle, fn = fn, kind = "track" }
    self._next_handle = self._next_handle + 1
    self._on_track_enter[name][#self._on_track_enter[name] + 1] = h
    return h
end

function Timeline:offHandle(handle)
    if not handle then return end
    if handle.kind == "complete" then
        for i, h in ipairs(self._on_complete) do
            if h.id == handle.id then table.remove(self._on_complete, i); return end
        end
    elseif handle.kind == "track" then
        for _, list in pairs(self._on_track_enter) do
            for i, h in ipairs(list) do
                if h.id == handle.id then table.remove(list, i); return end
            end
        end
    end
end

function Timeline:export()
    return {
        t = self._t, scale = self._scale, duration = self._duration,
        playing = self._playing, finished = self._finished,
    }
end

M.Track    = Track
M.Timeline = Timeline
M._unpack  = table_unpack

return M
