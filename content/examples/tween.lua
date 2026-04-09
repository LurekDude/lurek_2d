-- examples/tween.lua
-- Luna2D property tweening — luna.tween examples
--
-- Run with:  cargo run -- examples
--
-- This script shows the full luna.tween API in a headless scripting context.
-- All tweens are updated manually; no window or GPU is required.

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function fmt(v) return string.format("%.2f", v) end

local function step(dt)
    luna.tween.update(dt)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 1. Basic single-field tween
-- ──────────────────────────────────────────────────────────────────────────────
print("=== 1. Basic tween ===")
do
    local obj = { x = 0 }

    luna.tween.tween(1.0, obj, { x = 100 }, "linear")
        :onComplete(function()
            print("  done — x = " .. fmt(obj.x))  -- should be 100.00
        end)

    step(0.25); print("  t=0.25  x=" .. fmt(obj.x))  -- ~25.00
    step(0.25); print("  t=0.50  x=" .. fmt(obj.x))  -- ~50.00
    step(0.50); print("  t=1.00  x=" .. fmt(obj.x))  -- ~100.00
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 2. Multiple fields, cubic easing
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 2. Multi-field tween with cubicOut ===")
do
    local sprite = { x = 0, y = 0, alpha = 0 }

    luna.tween.tween(1.0, sprite, { x = 320, y = 240, alpha = 1 }, "cubicOut")

    step(0.5)
    print(string.format("  mid: x=%.1f  y=%.1f  alpha=%.3f",
        sprite.x, sprite.y, sprite.alpha))
    step(0.5)
    print(string.format("  end: x=%.1f  y=%.1f  alpha=%.3f",
        sprite.x, sprite.y, sprite.alpha))
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 3. Repeat + yoyo (bounce)
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 3. Repeat + yoyo ===")
do
    local obj = { x = 0 }
    local cycle = 0

    luna.tween.tween(1.0, obj, { x = 100 }, "sineInOut")
        :setRepeat(3)   -- 4 cycles total
        :setYoyo(true)
        :onUpdate(function(_t)
            -- called every tick
        end)
        :onComplete(function()
            print("  bounce finished — x=" .. fmt(obj.x))
        end)

    for i = 1, 8 do
        step(0.5)
        print(string.format("  t=%.1f  x=%s", i * 0.5, fmt(obj.x)))
    end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 4. Pause / resume
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 4. Pause and resume ===")
do
    luna.tween.cancelAll()
    local obj = { x = 0 }
    local t = luna.tween.tween(2.0, obj, { x = 200 }, "linear")

    step(0.5)
    print("  before pause: x=" .. fmt(obj.x))  -- ~50
    t:pause()
    step(1.0)                                    -- frozen
    print("  after 1s paused: x=" .. fmt(obj.x))
    t:resume()
    step(1.5)
    print("  after resume + 1.5s: x=" .. fmt(obj.x))  -- ~200
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 5. Sequence
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 5. Sequence ===")
do
    luna.tween.cancelAll()
    local obj = { x = 0, alpha = 1 }

    luna.tween.sequence()
        :tween(0.5, obj, { x = 200 },   "quadOut")
        :delay(0.2)
        :tween(0.5, obj, { alpha = 0 }, "quadIn")
        :callback(function()
            print("  seq done — x=" .. fmt(obj.x) .. " alpha=" .. fmt(obj.alpha))
        end)
        :start()

    step(0.6);  print("  step1 done: x=" .. fmt(obj.x))   -- ~200
    step(0.8);  print("  step2 done: alpha=" .. fmt(obj.alpha))  -- ~0
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 6. Parallel
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 6. Parallel ===")
do
    luna.tween.cancelAll()
    local a = { x = 0 }
    local b = { y = 0 }
    local c = { scale = 1 }

    luna.tween.parallel()
        :tween(1.0, a, { x = 100 }, "linear")
        :tween(0.5, b, { y = 200 }, "cubicOut")
        :tween(1.5, c, { scale = 2 }, "elasticOut")
        :onComplete(function()
            print(string.format("  par done — a.x=%.0f b.y=%.0f c.scale=%.2f",
                a.x, b.y, c.scale))
        end)
        :start()

    step(0.5)
    print(string.format("  0.5s: a.x=%.1f  b.y=%.1f  c.scale=%.3f",
        a.x, b.y, c.scale))
    step(1.5)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 7. Standalone delay
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 7. Delay ===")
do
    luna.tween.cancelAll()
    luna.tween.delay(0.5, function()
        print("  delay fired after 0.5 s")
    end)
    step(0.3); step(0.3)  -- second step triggers it
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 8. Custom easing
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 8. Custom easing ===")
do
    luna.tween.cancelAll()

    -- Overshoot spring
    luna.tween.registerEasing("spring", function(t)
        return 1 - math.cos(t * math.pi * 4.5) * (1 - t)
    end)

    local obj = { x = 0 }
    luna.tween.tween(1.0, obj, { x = 100 }, "spring")

    for i = 1, 4 do
        step(0.25)
        print(string.format("  t=%.2f  x=%s", i * 0.25, fmt(obj.x)))
    end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 9. Easing name introspection
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 9. getEasingNames ===")
do
    local names = luna.tween.getEasingNames()
    print("  available easings (" .. #names .. "):")
    for _, n in ipairs(names) do
        io.write("    " .. n .. "\n")
    end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 10. Cancel and onCancel
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 10. Cancel ===")
do
    luna.tween.cancelAll()
    local obj = { x = 0 }
    local t = luna.tween.tween(5.0, obj, { x = 1000 })
    t:onCancel(function()
        print("  onCancel fired — x=" .. fmt(obj.x))
    end)
    step(0.5)
    t:cancel()
    step(5.0)  -- should not advance
    print("  isActive after cancel: " .. tostring(t:isActive()))
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 11. getActiveCount and getProgress
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 11. getActiveCount + getProgress ===")
do
    luna.tween.cancelAll()
    local a = { x = 0 }
    local b = { y = 0 }
    local t1 = luna.tween.tween(2.0, a, { x = 100 }, "linear")
    local t2 = luna.tween.tween(2.0, b, { y = 200 }, "linear")
    print("  active at start: " .. luna.tween.getActiveCount())  -- 2
    step(1.0)
    print(string.format("  progress t1=%.2f  t2=%.2f",
        t1:getProgress(), t2:getProgress()))  -- ~0.5 each
    step(1.0)
    print("  active after completion: " .. luna.tween.getActiveCount())  -- 0
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 12. Sequence cancel and isActive
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 12. Sequence cancel + isActive ===")
do
    luna.tween.cancelAll()
    local obj = { x = 0 }
    local seq = luna.tween.sequence()
        :tween(1.0, obj, { x = 100 }, "linear")
        :tween(1.0, obj, { x = 200 }, "linear")
        :start()
    print("  seq active: " .. tostring(seq:isActive()))  -- true
    step(0.5)
    seq:cancel()
    print("  seq active after cancel: " .. tostring(seq:isActive()))  -- false
    step(2.0)  -- no further animation
    print("  obj.x after cancel: " .. fmt(obj.x))  -- < 100
end

-- ──────────────────────────────────────────────────────────────────────────────
-- 13. Parallel add(), cancel, and isActive
-- ──────────────────────────────────────────────────────────────────────────────
print("\n=== 13. Parallel add() + cancel + isActive ===")
do
    luna.tween.cancelAll()
    local a = { scale = 1 }
    local b = { alpha = 1 }

    -- Build two standalone tweens and hand them to parallel via :add()
    local tw_a = luna.tween.tween(1.0, a, { scale = 3 }, "quadOut")
    local tw_b = luna.tween.tween(0.5, b, { alpha = 0 }, "linear")

    local par = luna.tween.parallel()
        :add(tw_a)
        :add(tw_b)
        :onComplete(function()
            print("  par done — scale=" .. fmt(a.scale) .. " alpha=" .. fmt(b.alpha))
        end)
        :start()

    print("  par active: " .. tostring(par:isActive()))  -- true
    step(0.3)
    par:cancel()
    print("  par active after cancel: " .. tostring(par:isActive()))  -- false
end

print("\nAll examples complete.")
