# Tween & Easing

Animate values over time with easing functions, chaining, callbacks, and cancellation.

## Key Concepts

- **Tween**: Interpolate a value from A to B over a duration using an easing function.
- **Easing**: Shape the interpolation curve — linear, ease-in, ease-out, bounce, elastic, etc.
- **Chaining**: Queue tweens to play in sequence.
- **Table field tweens**: Animate `obj.x`, `obj.alpha` by reference.
- **Callbacks**: Fire `on_complete` when a tween finishes.

## Easing Functions

```lua
local ease = {}
function ease.linear(t)       return t end
function ease.inQuad(t)       return t * t end
function ease.outQuad(t)      return t * (2 - t) end
function ease.inOutQuad(t)    return t < 0.5 and 2*t*t or -1+(4-2*t)*t end
function ease.inCubic(t)      return t * t * t end
function ease.outCubic(t)     local u = t-1; return u*u*u + 1 end
function ease.inOutCubic(t)   return t<0.5 and 4*t*t*t or (t-1)*(2*t-2)*(2*t-2)+1 end
function ease.inExpo(t)       return t == 0 and 0 or 2^(10*(t-1)) end
function ease.outExpo(t)      return t == 1 and 1 or 1 - 2^(-10*t) end
function ease.inBack(t)       local s=1.70158; return t*t*((s+1)*t - s) end
function ease.outBack(t)      local s=1.70158; t=t-1; return t*t*((s+1)*t+s)+1 end
function ease.outBounce(t)
    if t < 1/2.75 then return 7.5625*t*t
    elseif t < 2/2.75 then t=t-1.5/2.75; return 7.5625*t*t+0.75
    elseif t < 2.5/2.75 then t=t-2.25/2.75; return 7.5625*t*t+0.9375
    else t=t-2.625/2.75; return 7.5625*t*t+0.984375 end
end
function ease.outElastic(t)
    if t == 0 or t == 1 then return t end
    return 2^(-10*t) * math.sin((t-0.075)*2*math.pi/0.3) + 1
end
```

## Tween Manager

```lua
local tweens = {}

local function tween_to(obj, field, target, duration, easing, on_complete)
    local t = {
        obj = obj, field = field,
        start_val = obj[field], target = target,
        duration = duration, elapsed = 0,
        easing = easing or ease.linear,
        on_complete = on_complete,
        active = true,
    }
    tweens[#tweens + 1] = t
    return t
end

local function update_tweens(dt)
    for i = #tweens, 1, -1 do
        local t = tweens[i]
        if t.active then
            t.elapsed = t.elapsed + dt
            local progress = math.min(1, t.elapsed / t.duration)
            local eased = t.easing(progress)
            t.obj[t.field] = t.start_val + (t.target - t.start_val) * eased
            if progress >= 1 then
                t.active = false
                if t.on_complete then t.on_complete() end
                table.remove(tweens, i)
            end
        end
    end
end
```

## Usage

```lua
local box = { x = 50, y = 100, alpha = 1 }

-- Slide box to x=400 over 1 second with bounce
tween_to(box, "x", 400, 1.0, ease.outBounce)

-- Fade out over 0.5 seconds, then remove
tween_to(box, "alpha", 0, 0.5, ease.outQuad, function()
    box.removed = true
end)
```

## Chaining

```lua
local function chain(steps)
    local i = 0
    local function run_next()
        i = i + 1
        if i > #steps then return end
        local s = steps[i]
        tween_to(s.obj, s.field, s.target, s.duration, s.easing, run_next)
    end
    run_next()
end

-- Example: move right, then down, then fade out
chain({
    { obj = box, field = "x",     target = 400, duration = 0.5, easing = ease.outQuad },
    { obj = box, field = "y",     target = 300, duration = 0.5, easing = ease.outQuad },
    { obj = box, field = "alpha", target = 0,   duration = 0.3, easing = ease.linear },
})
```

## Cancel

```lua
local function cancel_tween(t)
    t.active = false
end

local function cancel_all_for(obj)
    for _, t in ipairs(tweens) do
        if t.obj == obj then t.active = false end
    end
end
```

## Common Pitfalls

- **Tween on removed object** — cancel tweens when the object is destroyed. Nil field access crashes.
- **Overlapping tweens on same field** — two tweens fighting over `obj.x` causes jitter. Cancel the old one first.
- **Duration zero** — causes division by zero or instant snap. Guard with `math.max(0.001, duration)`.
- **Easing overshoot** — `outBack` and `outElastic` exceed the target value temporarily. Make sure visuals handle values > target.
- **Not updating tweens** — call `update_tweens(dt)` every frame in `luna.update`.
