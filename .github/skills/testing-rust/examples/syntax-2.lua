describe("lurek.audio.newBus", function()  -- module function
    it("creates bus with given name", function() end)
    it("rejects empty name", function() end)           -- error path earns a bonus score point
end)

describe("AudioBus:setVolume", function()  -- UserData method
    it("stores volume", function() end)
    it("clamps to [0,1]", function() end)
end)
