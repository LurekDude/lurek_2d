# Particle Juice

On-hit sparks, walk dust, landing impact, death explosion, coin collect, and healing shimmer using lurek.particle.

## Key Concepts

- **Particle system**: Pre-configured emitter with lifetime, speed, color, and emission rate.
- **Burst vs steady**: Burst for one-shot effects (explosion), steady rate for ambient (rain, dust trail).
- **Juice feel**: Small particle bursts on every game event make the world feel responsive and alive.
- **Color over lifetime**: Fade alpha to 0 at end of life. Shift hue for fire/magic effects.

## Creating a Particle System

```lua
local function make_sparks()
    local ps = lurek.particle.newSystem(spark_img, 100)
    lurek.particle.setEmissionRate(ps, 0)
    lurek.particle.setLifetime(ps, 0.2, 0.5)
    lurek.particle.setSpeed(ps, 80, 200)
    lurek.particle.setSpread(ps, math.pi * 2)
    lurek.particle.setColors(ps, 1,1,0.5,1, 1,0.3,0,0)
    lurek.particle.setSizes(ps, 0.5, 0.1)
    return ps
end
```

## Effect Library

```lua
local effects = {}

-- On-hit sparks: burst 12 particles at hit position
effects.hit_sparks = function(x, y)
    local ps = make_sparks()
    lurek.particle.setPosition(ps, x, y)
    lurek.particle.emit(ps, 12)
    return ps
end

-- Walk dust: small puff at feet
effects.walk_dust = function(x, y)
    local ps = lurek.particle.newSystem(dust_img, 30)
    lurek.particle.setPosition(ps, x, y)
    lurek.particle.setEmissionRate(ps, 0)
    lurek.particle.setLifetime(ps, 0.3, 0.6)
    lurek.particle.setSpeed(ps, 10, 30)
    lurek.particle.setDirection(ps, -math.pi / 2)
    lurek.particle.setSpread(ps, math.pi / 4)
    lurek.particle.setColors(ps, 0.6,0.5,0.4,0.6, 0.6,0.5,0.4,0)
    lurek.particle.setSizes(ps, 0.4, 0.8)
    lurek.particle.emit(ps, 5)
    return ps
end

-- Landing impact: ring burst downward
effects.land_impact = function(x, y)
    local ps = lurek.particle.newSystem(dust_img, 40)
    lurek.particle.setPosition(ps, x, y)
    lurek.particle.setLifetime(ps, 0.2, 0.4)
    lurek.particle.setSpeed(ps, 40, 80)
    lurek.particle.setDirection(ps, 0)
    lurek.particle.setSpread(ps, math.pi)
    lurek.particle.setColors(ps, 0.7,0.6,0.5,0.8, 0.7,0.6,0.5,0)
    lurek.particle.emit(ps, 8)
    return ps
end

-- Death explosion: big burst
effects.death_explode = function(x, y)
    local ps = make_sparks()
    lurek.particle.setSpeed(ps, 100, 300)
    lurek.particle.setLifetime(ps, 0.3, 0.8)
    lurek.particle.setPosition(ps, x, y)
    lurek.particle.emit(ps, 30)
    return ps
end

-- Coin collect: gold sparkle upward
effects.coin_collect = function(x, y)
    local ps = lurek.particle.newSystem(sparkle_img, 20)
    lurek.particle.setPosition(ps, x, y)
    lurek.particle.setLifetime(ps, 0.4, 0.8)
    lurek.particle.setSpeed(ps, 30, 60)
    lurek.particle.setDirection(ps, -math.pi / 2)
    lurek.particle.setSpread(ps, math.pi / 6)
    lurek.particle.setColors(ps, 1,0.9,0.3,1, 1,0.8,0.1,0)
    lurek.particle.setSizes(ps, 0.6, 0.1)
    lurek.particle.emit(ps, 10)
    return ps
end
```

## Managing Active Effects

```lua
local active_particles = {}

local function spawn_effect(factory, x, y)
    local ps = factory(x, y)
    active_particles[#active_particles + 1] = ps
end

local function update_particles(dt)
    for i = #active_particles, 1, -1 do
        lurek.particle.update(active_particles[i], dt)
        if lurek.particle.getCount(active_particles[i]) == 0 then
            table.remove(active_particles, i)
        end
    end
end

local function draw_particles()
    for _, ps in ipairs(active_particles) do
        lurek.render.draw(ps, 0, 0)
    end
end
```

## Common Pitfalls

- **Never calling update** — particles freeze. Call `lurek.particle.update(ps, dt)` every frame.
- **Leaking finished systems** — remove from the active list when count reaches 0.
- **Too many particles** — each system has a max buffer. Keep bursts under 50 for casual effects.
- **Emission rate left on** — for burst effects, set `setEmissionRate(ps, 0)` and use `emit(ps, n)`.
- **Missing particle image** — each system needs a texture. Use a small 4×4 white pixel for generic particles.
