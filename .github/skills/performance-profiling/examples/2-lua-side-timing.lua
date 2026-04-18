local t = lurek.time.getTime()
doExpensiveThing()
print(string.format("%.2f ms", (lurek.time.getTime() - t) * 1000))
