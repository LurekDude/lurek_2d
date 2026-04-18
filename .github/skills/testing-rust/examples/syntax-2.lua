describe("lurek.audio.newBus", function()  -- module function
    it("creates bus with given name", ...)
    it("rejects empty name", ...)           -- error path earns a bonus score point
end)

describe("AudioBus:setVolume", function()  -- UserData method
    it("stores volume", ...)
    it("clamps to [0,1]", ...)
end)
