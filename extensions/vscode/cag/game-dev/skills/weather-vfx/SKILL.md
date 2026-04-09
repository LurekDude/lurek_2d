# Weather VFX

Rain particles, snow drift, wind force, lightning flash with thunder SFX, and fog overlay.

## Key Concepts

- **Particle-based weather**: Rain and snow are particle systems with gravity and wind influence.
- **Wind force**: Global wind vector that affects particle horizontal velocity and can influence gameplay.
- **Lightning**: Screen-wide flash (draw white rect at high alpha), followed by thunder SFX with distance delay.
- **Fog overlay**: Semi-transparent gradient rectangle drawn over the scene for atmosphere.
- **Layered rendering**: Weather draws after the world but before HUD.

## Wind

```lua
local weather = { wind_x = 0, wind_y = 0 }

local function set_wind(x, y)
    weather.wind_x = x
    weather.wind_y = y
end
```

## Rain System

```lua
local rain_drops = {}
local RAIN_COUNT = 300
local RAIN_SPEED = 500
local RAIN_LENGTH = 8

local function init_rain(screen_w, screen_h)
    for i = 1, RAIN_COUNT do
        rain_drops[i] = {
            x = math.random() * screen_w,
            y = math.random() * screen_h,
            speed = RAIN_SPEED + math.random() * 100,
        }
    end
end

local function update_rain(dt, screen_w, screen_h)
    for _, d in ipairs(rain_drops) do
        d.x = d.x + weather.wind_x * dt
        d.y = d.y + d.speed * dt
        if d.y > screen_h then
            d.y = -RAIN_LENGTH
            d.x = math.random() * screen_w
        end
        if d.x > screen_w then d.x = 0 end
        if d.x < 0 then d.x = screen_w end
    end
end

local function draw_rain()
    luna.gfx.setColor(0.6, 0.7, 0.9, 0.5)
    for _, d in ipairs(rain_drops) do
        luna.gfx.line(d.x, d.y, d.x + weather.wind_x * 0.02, d.y + RAIN_LENGTH)
    end
    luna.gfx.setColor(1, 1, 1, 1)
end
```

## Snow System

```lua
local snowflakes = {}
local SNOW_COUNT = 200

local function init_snow(screen_w, screen_h)
    for i = 1, SNOW_COUNT do
        snowflakes[i] = {
            x = math.random() * screen_w,
            y = math.random() * screen_h,
            size = 1 + math.random() * 2,
            drift = (math.random() - 0.5) * 30,
            speed = 20 + math.random() * 40,
        }
    end
end

local function update_snow(dt, screen_w, screen_h)
    for _, s in ipairs(snowflakes) do
        s.x = s.x + (s.drift + weather.wind_x) * dt
        s.y = s.y + s.speed * dt
        if s.y > screen_h then
            s.y = -s.size
            s.x = math.random() * screen_w
        end
        if s.x > screen_w then s.x = 0 end
        if s.x < 0 then s.x = screen_w end
    end
end

local function draw_snow()
    luna.gfx.setColor(1, 1, 1, 0.8)
    for _, s in ipairs(snowflakes) do
        luna.gfx.circle("fill", s.x, s.y, s.size)
    end
    luna.gfx.setColor(1, 1, 1, 1)
end
```

## Lightning Flash + Thunder

```lua
local lightning = { flash = 0, thunder_timer = -1 }

local function trigger_lightning()
    lightning.flash = 1.0
    local distance = 0.5 + math.random() * 2.0  -- 0.5–2.5 seconds delay
    lightning.thunder_timer = distance
end

local function update_lightning(dt)
    if lightning.flash > 0 then
        lightning.flash = lightning.flash - dt * 5  -- quick decay
    end
    if lightning.thunder_timer > 0 then
        lightning.thunder_timer = lightning.thunder_timer - dt
        if lightning.thunder_timer <= 0 then
            play_sfx("thunder", 0.8, 0.15)
            lightning.thunder_timer = -1
        end
    end
end

local function draw_lightning(screen_w, screen_h)
    if lightning.flash > 0 then
        luna.gfx.setColor(1, 1, 1, lightning.flash * 0.7)
        luna.gfx.rectangle("fill", 0, 0, screen_w, screen_h)
        luna.gfx.setColor(1, 1, 1, 1)
    end
end
```

## Fog Overlay

```lua
local function draw_fog(screen_w, screen_h, density)
    density = density or 0.3
    luna.gfx.setColor(0.5, 0.5, 0.6, density)
    luna.gfx.rectangle("fill", 0, 0, screen_w, screen_h)
    luna.gfx.setColor(1, 1, 1, 1)
end
```

## Common Pitfalls

- **Weather in screen space** — rain/snow should not move with the camera. Draw after popping camera transform.
- **Too many particles** — 300 rain drops is fine; 3000 tanks FPS. Profile and cap.
- **Lightning every frame** — trigger randomly with low probability per frame: `if math.random() < 0.002 then trigger_lightning() end`.
- **Thunder without delay** — real thunder arrives after the flash. Use distance-based timer for immersion.
- **Fog blocks gameplay** — keep density low (0.1–0.3). Too thick and players can't see hazards.
