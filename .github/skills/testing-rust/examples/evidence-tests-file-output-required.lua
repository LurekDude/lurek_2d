-- CORRECT: evidence test creates a real file
local OUT = "tests/lua/evidence/output/particle/"

it("emitter generates particles and saves PNG evidence", function()
    local em = lurek.particle.newEmitter({ rate = 10, lifetime = 1.0 })
    for _ = 1, 60 do em:update(1/60) end
    local img = em:toImageData(256, 256)
    lurek.image.savePNG(img, OUT .. "emitter_basic.png")
    -- Pass: file was saved without error
end)

-- WRONG: no file written → invalid evidence test
it("emitter runs without crashing", function()
    local em = lurek.particle.newEmitter({ rate = 10, lifetime = 1.0 })
    em:update(0.016)
    -- No file saved → this is NOT an evidence test, it is a unit test
end)
