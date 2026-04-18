local before = collectgarbage("count")
doFrame()
local after = collectgarbage("count")
if after - before > 50 then   -- >50KB allocated this frame
    print("GC pressure: " .. (after - before) .. " KB")
end
