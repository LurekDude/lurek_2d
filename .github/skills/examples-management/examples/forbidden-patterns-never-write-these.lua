---@diagnostic disable: undefined-global
-- FORBIDDEN: function-name scenario (teaches what, not why or when)
-- lurek.timer.after
-- Schedules a callback.
local id = sched:after(2.0, function() end)

-- FORBIDDEN: lone constructor with trivial method chain
local sig2 = lurek.event.newSignal()
print("type: " .. sig2:type())   -- sig2 exists only to demonstrate :type()

-- FORBIDDEN: nil / zero args for meaningful parameters
-- lurek.physics.newBody(nil, 0, 0)
