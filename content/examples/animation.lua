-- examples/animation.lua
-- lurek.animation � Sprite animation: frame pools, named clips, speed control, events.

-- �� Construction �������������������������������������������������������������

-- Create a new, empty animation controller. Clips and frames are added
-- manually before playback begins.
local anim = lurek.animation.new()

-- �� Frame Pools ���������������������������������������������������������������

-- addFrame(x, y, w, h) � integer
-- Adds one frame to the frame pool by source rectangle on a sprite sheet.
-- Returns the 0-based index into the pool.
local frame0 = anim:addFrame(0, 0, 64, 64)      -- first tile
local frame1 = anim:addFrame(64, 0, 64, 64)     -- second tile
local frame2 = anim:addFrame(128, 0, 64, 64)    -- third tile

-- addFramesFromGrid(tex_w, tex_h, frame_w, frame_h, start, count) � integer
-- Slices a sprite-sheet grid automatically. Returns the first index added.
-- All frames starting at index `start` (0-based) for `count` frames are added.
local sheet_w, sheet_h = 512, 64
local fw, fh = 64, 64
local first = anim:addFramesFromGrid(sheet_w, sheet_h, fw, fh, 0, 8)
-- Results in 8 frames at pool indices first..first+7

-- getFrameCount() � integer
-- Returns the total number of frames in the frame pool.
local total_frames = anim:getFrameCount()  -- e.g. 11 (3 manual + 8 grid)

-- �� Clips ���������������������������������������������������������������������

-- addClip(name, indices, fps, looping)
-- Defines a named clip from explicit frame pool indices.
-- indices is a Lua table of integer indices.
anim:addClip("idle", {0, 1, 2}, 8, true)       -- loops at 8 fps
anim:addClip("run", {3, 4, 5, 6, 7}, 12, true) -- loops at 12 fps
anim:addClip("jump", {8, 9, 10}, 10, false)    -- plays once

-- addClipFromGrid(name, tex_w, tex_h, frame_w, frame_h, start, count, fps, looping)
-- Convenience form that slices and registers in one call.
local anim2 = lurek.animation.new()
anim2:addClipFromGrid("run", 512, 64, 64, 64, 0, 8, 12, true)

-- getClipCount() � integer
local num_clips = anim:getClipCount()  -- 3

-- �� Playback ������������������������������������������������������������������

-- play(name) � boolean
-- Starts playback of the named clip. Returns false if the clip does not exist.
local ok = anim:play("idle")  -- true on success

-- pause() / resume() / stop()
-- Pause freezes the current frame; resume continues. Stop resets to frame 0.
anim:pause()
anim:resume()
anim:stop()

-- update(dt) � call every frame to advance animation time.
-- Typically called in lurek.process(dt).
anim:update(1/60)

-- �� State Queries �������������������������������������������������������������

-- isPlaying() � boolean
local playing = anim:isPlaying()

-- isLooping() � boolean � true if the current clip is set to loop
local looping = anim:isLooping()

-- getClip() � string? � name of the currently active clip, or nil
local clip_name = anim:getClip()

-- getCurrentFrame() � integer � 0-based position within the active clip
local frame_pos = anim:getCurrentFrame()

-- setFrame(index) � jump to a specific frame within the current clip
anim:setFrame(0)

-- �� Playback Speed ������������������������������������������������������������

-- getSpeed() � number � current speed multiplier (1.0 = normal)
local speed = anim:getSpeed()

-- setSpeed(speed) � set playback speed multiplier
anim:setSpeed(2.0)   -- double speed
anim:setSpeed(0.5)   -- half speed
anim:setSpeed(1.0)   -- restore normal

-- �� Current Frame Quad ��������������������������������������������������������

-- getQuad() � {x, y, w, h} or nil
-- Returns the source rectangle for the current animation frame.
-- Use this to pass the correct UV region to lurek.gfx.draw().
local quad = anim:getQuad()
if quad then
    -- quad.x, quad.y, quad.w, quad.h define the source crop on the sprite sheet
lurek.gfx.drawRegion(img, quad.x, quad.y, quad.w, quad.h, dest_x, dest_y)
end

-- �� Poll Events ���������������������������������������������������������������

-- pollEvents() � table of event tables
-- Drains all pending animation events accumulated since the last poll.
-- Event types:
"clip_end"  � the current clip reached its last frame (non-looping)
"loop_end"  � a looping clip completed one full cycle
-- Each event table may also contain a "frame" field with the 0-based index.
local events = anim:pollEvents()
for _, ev in ipairs(events) do
    if ev.type == "clip_end" then
        -- Return to idle when a one-shot clip finishes
        anim:play("idle")
    elseif ev.type == "loop_end" then
        -- A loop just completed � useful for triggering footstep sounds, etc.
    end
end

-- �� Sprite Sheet Pattern (typical lurek.process/lurek.render usage) ����������������

--[[
function lurek.init()
    img = lurek.gfx.newImage("character.png")
    anim = lurek.animation.new()
    anim:addClipFromGrid("idle", 512, 64, 64, 64,  0, 4, 6, true)
    anim:addClipFromGrid("run",  512, 64, 64, 64,  4, 6, 12, true)
    anim:addClipFromGrid("jump", 512, 64, 64, 64, 10, 4, 10, false)
    anim:play("idle")
    x, y = 100, 100
end

function lurek.process(dt)
    anim:update(dt)

    local events = anim:pollEvents()
    for _, ev in ipairs(events) do
        if ev.type == "clip_end" then
            anim:play("idle")  -- auto-return after jump
        end
    end

    -- Transition based on input
    if lurek.keyboard.isDown("right") then
        if anim:getClip() ~= "run" then anim:play("run") end
    else
        if anim:getClip() ~= "idle" and anim:getClip() ~= "jump" then
            anim:play("idle")
        end
    end
end

function lurek.render()
    local q = anim:getQuad()
    if q then
        lurek.gfx.drawRegion(img, q.x, q.y, q.w, q.h, x, y)
    end
end
]]
