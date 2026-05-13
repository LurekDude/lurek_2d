--[[
sprite_animator.lua – Simple sprite-sheet animation helper for Lurek2D.

Wraps a lurek.sprite SpriteSheet (or row/column index logic) and handles:
- Named animation clips with frame ranges, fps, and loop flags.
- Playback state: play, pause, stop, setClip.
- Per-frame callbacks: onFrame, onLoop, onEnd.

Usage:
    local SpriteAnimator = require("library.sprite.sprite_animator")

    local anim = SpriteAnimator.new(spritesheet, {
        idle  = { row = 1, from = 1, to = 4,  fps = 8,  loop = true  },
        run   = { row = 2, from = 1, to = 8,  fps = 12, loop = true  },
        jump  = { row = 3, from = 1, to = 6,  fps = 10, loop = false },
        death = { row = 4, from = 1, to = 5,  fps = 6,  loop = false },
    })

    anim:play("idle")
    -- In update(dt):
    anim:update(dt)
    -- To draw the current frame (returns row, col):
    local row, col = anim:currentFrame()
    lurek.sprite.draw(sheet, x, y, row, col)
--]]

local SpriteAnimator = {}
SpriteAnimator.__index = SpriteAnimator
---@class SpriteAnimator
---@field private _clips    table
---@field private _clip     string|nil
---@field private _def      table|nil
---@field private _frame    integer
---@field private _elapsed  number
---@field private _playing  boolean
---@field private _onFrame  function|nil
---@field private _onLoop   function|nil
---@field private _onEnd    function|nil

function SpriteAnimator.new(clips)
    local self = setmetatable({}, SpriteAnimator)

    self._clips       = clips or {}
    self._clip        = nil   -- current clip name
    self._def         = nil   -- current clip definition
    self._frame       = 1     -- current frame index within clip (1-based)
    self._elapsed     = 0.0   -- accumulated time since last frame advance
    self._playing     = false
    self._onFrame     = nil   -- fn(row, col, clip_name)
    self._onLoop      = nil   -- fn(clip_name)
    self._onEnd       = nil   -- fn(clip_name)

    return self
end

--- Plays (or restarts) the named clip.
--- @param name string  Clip name.
--- @param restart boolean?  If true, restart even if same clip is already playing (default true).
function SpriteAnimator:play(name, restart)
    if restart == nil then restart = true end
    local def = self._clips[name]
    if not def then
        return
    end
    if self._clip == name and not restart and self._playing then
        return
    end
    self._clip    = name
    self._def     = def
    self._frame   = def.from or 1
    self._elapsed = 0.0
    self._playing = true
end

--- Pauses playback without resetting the frame counter.
function SpriteAnimator:pause()
    self._playing = false
end

--- Resumes paused playback from the current frame.
function SpriteAnimator:resume()
    if self._def then
        self._playing = true
    end
end

--- Stops playback and resets to the first frame of the current clip.
function SpriteAnimator:stop()
    self._playing = false
    if self._def then
        self._frame = self._def.from or 1
    end
    self._elapsed = 0.0
end

--- Returns true if the animator is currently playing.
--- @return boolean
function SpriteAnimator:isPlaying()
    return self._playing
end

--- Returns the active clip name, or nil.
--- @return string|nil
function SpriteAnimator:currentClip()
    return self._clip
end

--- Returns the current (row, col) frame to draw.
--- Row is the clip's row; col is the current frame index within the clip.
--- @return integer row, integer col
function SpriteAnimator:currentFrame()
    if not self._def then
        return 1, 1
    end
    return self._def.row or 1, self._frame
end

--- Advances playback time by dt seconds.
--- @param dt number  Delta time in seconds.
function SpriteAnimator:update(dt)
    if not self._playing or not self._def then
        return
    end

    local def     = self._def
    local fps     = def.fps or 8
    local from    = def.from or 1
    local to      = def.to or from
    local looping = (def.loop ~= false)  -- default true

    self._elapsed = self._elapsed + dt

    local frame_time = 1.0 / fps
    while self._elapsed >= frame_time do
        self._elapsed = self._elapsed - frame_time

        -- Advance frame
        self._frame = self._frame + 1
        if self._frame > to then
            if looping then
                self._frame = from
                if self._onLoop then
                    self._onLoop(self._clip)
                end
            else
                self._frame   = to
                self._playing = false
                if self._onEnd then
                    self._onEnd(self._clip)
                end
                break
            end
        end

        if self._onFrame then
            self._onFrame(def.row or 1, self._frame, self._clip)
        end
    end
end

--- Sets a callback fired on each new frame. fn(row, col, clip_name)
--- @param fn function
function SpriteAnimator:onFrame(fn)
    self._onFrame = fn
end

--- Sets a callback fired when a looping clip loops. fn(clip_name)
--- @param fn function
function SpriteAnimator:onLoop(fn)
    self._onLoop = fn
end

--- Sets a callback fired when a non-looping clip ends. fn(clip_name)
--- @param fn function
function SpriteAnimator:onEnd(fn)
    self._onEnd = fn
end

--- Adds or replaces a named clip definition.
--- @param name string  Clip name.
--- @param def  table   { row, from, to, fps, loop? }
function SpriteAnimator:addClip(name, def)
    self._clips[name] = def
end

--- Returns the frame duration in seconds for the current clip.
--- @return number
function SpriteAnimator:frameDuration()
    if not self._def then
        return 0.125
    end
    return 1.0 / (self._def.fps or 8)
end

--- Returns the total duration in seconds for the current clip (one full pass).
--- @return number
function SpriteAnimator:clipDuration()
    if not self._def then
        return 0
    end
    local from = self._def.from or 1
    local to   = self._def.to   or from
    local fps  = self._def.fps  or 8
    return (to - from + 1) / fps
end

return SpriteAnimator
