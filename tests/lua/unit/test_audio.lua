-- Luna2D Audio API Tests

describe("luna.audio module exists", function()
    it("luna.audio is a table", function()
        expect_type("table", luna.audio)
    end)
end)

describe("luna.audio functions exist", function()
    it("setMasterVolume is a function", function()
        expect_type("function", luna.audio.setMasterVolume)
    end)

    it("getMasterVolume is a function", function()
        expect_type("function", luna.audio.getMasterVolume)
    end)

    it("newSource is a function", function()
        expect_type("function", luna.audio.newSource)
    end)
end)

describe("luna.audio volume", function()
    it("setMasterVolume accepts 0..1 range", function()
        expect_no_error(function()
            luna.audio.setMasterVolume(0.5)
        end)
    end)

    it("getMasterVolume returns a number", function()
        local vol = luna.audio.getMasterVolume()
        expect_type("number", vol)
    end)

    it("setMasterVolume/getMasterVolume roundtrip", function()
        luna.audio.setMasterVolume(0.75)
        expect_near(0.75, luna.audio.getMasterVolume(), 0.01)
        luna.audio.setMasterVolume(1.0) -- reset
    end)

    it("setMasterVolume clamps to valid range", function()
        luna.audio.setMasterVolume(0.0)
        expect_near(0.0, luna.audio.getMasterVolume(), 0.01)
        luna.audio.setMasterVolume(1.0)
        expect_near(1.0, luna.audio.getMasterVolume(), 0.01)
    end)
end)

test_summary()
