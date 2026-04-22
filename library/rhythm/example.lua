-- content/library/rhythm/example.lua
-- Self-contained rhythm example — 120 BPM clock driving every/pattern hooks
-- and judging simulated key presses against the beat grid.

local rhythm = require("library.rhythm")

-- ─── 1. 120 BPM clock, 4-step subdivision ──────────────────────────────────

local clock = rhythm.newClock(120, { subdivision = 4 })

print(string.format("BPM = %d  sec/beat = %.3f", clock:getBpm(), 60/clock:getBpm()))

-- ─── 2. Hook callbacks ─────────────────────────────────────────────────────

local quarter_hits = 0
clock:every(4, function(beat)
    quarter_hits = quarter_hits + 1
    print(string.format("[every 4] quarter beat #%d", beat))
end)

clock:pattern("x.x.xxx.", function(step)
    print(string.format("[pattern] step %d (one bar = 8 steps)", step))
end)

local one_shot_seen = false
clock:at(2.0, function(b)
    one_shot_seen = true
    print(string.format("[at 2.0]   one-shot fired at beat %.2f", b))
end)

-- ─── 3. Simulate 4 seconds of song time (8 beats at 120 BPM) ────────────────

clock:start()
print("--- simulate 4 seconds (8 beats) at dt=0.05s ---")
local steps = 80
for _ = 1, steps do clock:update(0.05) end

print(string.format("\nelapsed beats = %.2f", clock:getBeat()))
print(string.format("quarter hits  = %d", quarter_hits))
print(string.format("one-shot fired = %s", tostring(one_shot_seen)))

-- ─── 4. Judgement — score five fake hits ──────────────────────────────────

print("\n--- judge five fake hits ---")
rhythm.setJudgementWindows({ perfect = 0.030, great = 0.060, good = 0.120 })
for _ = 1, 5 do
    local verdict, err = rhythm.judge(clock, 4)
    print(string.format("  verdict=%-7s  err=%+0.0f ms",
        verdict, err * 1000))
    clock:update(0.07)
end

-- ─── 5. BPM ramp ───────────────────────────────────────────────────────────

clock:rampBpm(180, 1.0)
for _ = 1, 20 do clock:update(0.05) end
print(string.format("\nafter 1.0s ramp: BPM = %.1f", clock:getBpm()))

return clock
