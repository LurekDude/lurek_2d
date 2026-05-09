-- Integration: effect overlay ambient state bridged to light world
describe("effect + light ambient bridge", function()
    -- @integration LOverlay:getAmbientColor
    -- @integration LOverlay:pullAmbientFromLight
    -- @integration lurek.effect.newOverlay
    -- @integration lurek.light.setAmbient
    it("pullAmbientFromLight copies light ambient into overlay", function()
        lurek.light.setAmbient(0.12, 0.34, 0.56, 0.78)
        local ov = lurek.effect.newOverlay()
        ov:pullAmbientFromLight()
        local r, g, b, a = ov:getAmbientColor()
        expect_near(r, 0.12, 0.001)
        expect_near(g, 0.34, 0.001)
        expect_near(b, 0.56, 0.001)
        expect_near(a, 0.78, 0.001)
    end)

    -- @integration LOverlay:pushAmbientToLight
    -- @integration LOverlay:setAmbientColor
    -- @integration lurek.effect.newOverlay
    -- @integration lurek.light.getAmbient
    it("pushAmbientToLight copies overlay ambient into light world", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientColor(0.21, 0.22, 0.23, 0.24)
        ov:pushAmbientToLight()
        local r, g, b, a = lurek.light.getAmbient()
        expect_near(r, 0.21, 0.001)
        expect_near(g, 0.22, 0.001)
        expect_near(b, 0.23, 0.001)
        expect_near(a, 0.24, 0.001)
    end)

    -- @integration LOverlay:getAmbientColor
    -- @integration LOverlay:setAmbientColor
    -- @integration LOverlay:syncAmbientWithLight
    -- @integration lurek.effect.newOverlay
    -- @integration lurek.light.getAmbient
    -- @integration lurek.light.setAmbient
    it("syncAmbientWithLight avg resolves and writes both sides", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientColor(0.2, 0.2, 0.2, 0.2)
        lurek.light.setAmbient(0.8, 0.6, 0.4, 1.0)
        ov:syncAmbientWithLight("avg")

        local orr, org, orb, ora = ov:getAmbientColor()
        local lr, lg, lb, la = lurek.light.getAmbient()
        expect_near(orr, 0.5, 0.001)
        expect_near(org, 0.4, 0.001)
        expect_near(orb, 0.3, 0.001)
        expect_near(ora, 0.6, 0.001)
        expect_near(lr, 0.5, 0.001)
        expect_near(lg, 0.4, 0.001)
        expect_near(lb, 0.3, 0.001)
        expect_near(la, 0.6, 0.001)
    end)
end)

test_summary()
