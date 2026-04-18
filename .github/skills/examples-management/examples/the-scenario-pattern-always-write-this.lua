-- ---- Scenario: schedule bullet auto-despawn -------------------------------------
-- Bullets in a shoot-em-up should self-destruct after 3 seconds unless they hit
-- something. lurek.timer.newScheduler + after() handles this; cancel() aborts early.

local sched = lurek.timer.newScheduler()
local id = sched:after(3.0, function()
    print("bullet removed from world after 3 seconds")
end)
sched:update(1.0)
print("timers still pending: " .. sched:count())

local hit_enemy = true
if hit_enemy then
    local ok = sched:cancel(id)
    print("early despawn cancelled: " .. tostring(ok))
end
