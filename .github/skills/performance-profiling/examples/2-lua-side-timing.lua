---@diagnostic disable: undefined-global
local t = lurek.timer.getTime()
doExpensiveThing()
print(string.format("%.2f ms", (lurek.timer.getTime() - t) * 1000))
