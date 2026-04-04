-- Luna2D Audio API Tests

describe("luna.audio module exists", function()
    it("luna.audio is a table", function()
        expect_type("table", luna.audio)
    end)
end)

describe("luna.audio functions exist", function()
    it("setVolume is a function", function()
        expect_type("function", luna.audio.setVolume)
    end)

    it("getVolume is a function", function()
        expect_type("function", luna.audio.getVolume)
    end)

    it("newSource is a function", function()
        expect_type("function", luna.audio.newSource)
    end)
end)

describe("luna.audio volume", function()
    it("setVolume accepts 0..1 range", function()
        expect_no_error(function()
            luna.audio.setVolume(0.5)
        end)
    end)

    it("getVolume returns a number", function()
        local vol = luna.audio.getVolume()
        expect_type("number", vol)
    end)

    it("setVolume/getVolume roundtrip", function()
        luna.audio.setVolume(0.75)
        expect_near(0.75, luna.audio.getVolume(), 0.01)
        luna.audio.setVolume(1.0) -- reset
    end)

    it("setVolume clamps to valid range", function()
        luna.audio.setVolume(0.0)
        expect_near(0.0, luna.audio.getVolume(), 0.01)
        luna.audio.setVolume(1.0)
        expect_near(1.0, luna.audio.getVolume(), 0.01)
    end)
end)

test_summary()
