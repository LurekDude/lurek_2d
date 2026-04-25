describe("lurek.audio.newBus", function()     -- scanner recognizes pattern
    it("creates bus with given name", function() end)
    it("bus is retrievable by name", function() end)
    it("rejects empty name", function()
        expect_error(function() lurek.audio.newBus("") end)
    end)
    it("rejects duplicate name", function() end)
end)

describe("AudioBus:setVolume", function()     -- UserData method pattern
    it("stores value correctly", function() end)
    it("clamps to [0,1]", function() end)
end)
