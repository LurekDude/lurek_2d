describe("lurek.audio.newBus", function()     -- scanner recognizes pattern
    it("creates bus with given name", ...)
    it("bus is retrievable by name", ...)
    it("rejects empty name", function()
        expect_error(function() lurek.audio.newBus("") end)
    end)
    it("rejects duplicate name", ...)
end)

describe("AudioBus:setVolume", function()     -- UserData method pattern
    it("stores value correctly", ...)
    it("clamps to [0,1]", ...)
end)
