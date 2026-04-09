# Audio Manager

BGM playback, crossfade, SFX with volume/pitch variation, spatial audio, and mute groups.

## Key Concepts

- **BGM**: One background music track at a time. Crossfade between tracks on scene change.
- **SFX**: Short one-shot sounds. Play with volume, optional pitch randomization.
- **Spatial audio**: Attenuate volume by distance from listener. Pan left/right by x-offset.
- **Mute groups**: Separate volume channels (master, music, sfx) the player can adjust.
- **Priority**: Limit concurrent SFX to prevent audio overload.

## Volume Channels

```lua
local volumes = { master = 1.0, music = 0.8, sfx = 1.0 }

local function effective_volume(group)
    return volumes.master * (volumes[group] or 1.0)
end
```

## BGM Playback

```lua
local current_bgm = nil
local bgm_source = nil

local function play_bgm(track, loop)
    if current_bgm == track then return end
    if bgm_source then luna.audio.stop(bgm_source) end
    bgm_source = luna.audio.newSource(track, "stream")
    luna.audio.setVolume(bgm_source, effective_volume("music"))
    luna.audio.setLooping(bgm_source, loop ~= false)
    luna.audio.play(bgm_source)
    current_bgm = track
end

local function stop_bgm()
    if bgm_source then luna.audio.stop(bgm_source) end
    bgm_source = nil
    current_bgm = nil
end
```

## BGM Crossfade

```lua
local fade = { old = nil, new = nil, timer = 0, duration = 1.0 }

local function crossfade_bgm(track, duration)
    fade.old = bgm_source
    fade.duration = duration or 1.0
    fade.timer = 0
    fade.new = luna.audio.newSource(track, "stream")
    luna.audio.setVolume(fade.new, 0)
    luna.audio.setLooping(fade.new, true)
    luna.audio.play(fade.new)
    current_bgm = track
end

local function update_crossfade(dt)
    if not fade.old then return end
    fade.timer = fade.timer + dt
    local t = math.min(1, fade.timer / fade.duration)
    luna.audio.setVolume(fade.old, (1 - t) * effective_volume("music"))
    luna.audio.setVolume(fade.new, t * effective_volume("music"))
    if t >= 1 then
        luna.audio.stop(fade.old)
        bgm_source = fade.new
        fade.old = nil
    end
end
```

## SFX with Pitch Variation

```lua
local sfx_cache = {}

local function play_sfx(name, volume, pitch_range)
    if not sfx_cache[name] then
        sfx_cache[name] = luna.audio.newSource("sfx/" .. name .. ".wav", "static")
    end
    local src = sfx_cache[name]:clone()
    luna.audio.setVolume(src, (volume or 1.0) * effective_volume("sfx"))
    if pitch_range then
        local p = 1.0 + (math.random() * 2 - 1) * pitch_range
        luna.audio.setPitch(src, p)
    end
    luna.audio.play(src)
end
```

## Distance-Based Spatial Audio

```lua
local function play_spatial(name, sx, sy, listener_x, listener_y, max_dist)
    max_dist = max_dist or 400
    local dist = math.sqrt((sx - listener_x)^2 + (sy - listener_y)^2)
    if dist > max_dist then return end
    local vol = 1.0 - (dist / max_dist)
    play_sfx(name, vol)
end
```

## Common Pitfalls

- **Stacking identical BGM** — always check `current_bgm == track` before restarting.
- **SFX spam** — limit concurrent instances per sound (e.g., max 3 coin pickup sounds at once).
- **Volume after settings change** — when player adjusts volume sliders, update currently playing sources.
- **Stream vs static** — use `"stream"` for long BGM, `"static"` for short SFX. Streaming short files wastes overhead.
- **Forgetting to stop old BGM** — always stop or fade before playing new. Overlapping BGMs sound broken.
