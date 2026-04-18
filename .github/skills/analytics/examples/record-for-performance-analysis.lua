local _frameTimes = {}

function lurek.process(dt)
    _frameTimes[#_frameTimes+1] = dt * 1000  -- ms
    if #_frameTimes >= 600 then              -- every 10s at 60fps
        local avg = 0
        local max = 0
        for _, t in ipairs(_frameTimes) do
            avg = avg + t
            if t > max then max = t end
        end
        avg = avg / #_frameTimes
        T.event("perf_sample", { avg_ms = string.format("%.2f", avg), max_ms = string.format("%.2f", max) })
        _frameTimes = {}
    end
end
