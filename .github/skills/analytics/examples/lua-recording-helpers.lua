-- lib/telemetry.lua: include in game scripts
local Telemetry = {}
local _file = "game.log"
local _start = lurek.time.getTime()

function Telemetry.init()
    lurek.fs.write(_file, "")  -- clear on session start
end

function Telemetry.event(name, data)
    local ts = lurek.time.getTime() - _start
    local parts = { string.format('timestamp=%.3f event="%s"', ts, name) }
    for k, v in pairs(data or {}) do
        if type(v) == "string" then
            parts[#parts+1] = string.format('%s="%s"', k, v)
        else
            parts[#parts+1] = string.format('%s=%s', k, tostring(v))
        end
    end
    lurek.fs.append(_file, table.concat(parts, " ") .. "\n")
end

return Telemetry
