luna.filesystem.write("save/slot1.tmp", "return " .. serialize(data))
luna.filesystem.write("save/slot1.lua", luna.filesystem.read("save/slot1.tmp"))
