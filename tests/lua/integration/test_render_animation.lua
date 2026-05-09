-- Integration: animation frame progression controlling sprite draw coordinates
describe("animation + render integration", function()
    -- @integration lurek.animation.new
    -- @integration LAnimation:addFramesFromGrid
    -- @integration LAnimation:addClip
    -- @integration LAnimation:play
    -- @integration LAnimation:update
    -- @integration LAnimation:getCurrentFrame
    -- @integration lurek.render.setColor
    -- @integration lurek.render.rectangle
    it("animation frame index controls render source texture offset", function()
        local anim = lurek.animation.new()
        expect_type("userdata", anim, "animation constructor returns userdata")
        anim:addFramesFromGrid(64, 16, 16, 16, 0, 4)  -- 4 frames, 16px wide each
        anim:addClip("walk", {0, 1, 2, 3}, 8.0, false)
        anim:play("walk")

        -- Frame 0: offset 0
        anim:update(0.125)  -- 8 fps, so 0.125s = one frame
        local frame_idx = anim:getCurrentFrame()
            expect_equal(1, frame_idx, "frame 1 after one update at 8fps")
        expect_true(pcall(function()
            lurek.render.setColor(1, 1, 1, 1)
            lurek.render.rectangle("fill", frame_idx * 16, 0, 16, 16)
        end), "render accepts animation frame offset for sprite coords")
    end)

    -- @integration lurek.animation.new
    -- @integration LAnimation:addFramesFromGrid
    -- @integration LAnimation:addClip
    -- @integration LAnimation:play
    -- @integration LAnimation:update
    -- @integration LAnimation:getCurrentFrame
    -- @integration lurek.render.rectangle
    it("sequential animation updates produce consecutive sprite offsets", function()
        local anim = lurek.animation.new()
        expect_type("userdata", anim, "animation constructor returns userdata")
        anim:addFramesFromGrid(32, 16, 16, 16, 0, 2)
        anim:addClip("seq", {0, 1}, 5.0, false)
        anim:play("seq")

        local offsets = {}
        for i = 1, 4 do
            anim:update(0.25)  -- 5fps
            table.insert(offsets, anim:getCurrentFrame())
            expect_true(pcall(function()
                local src_x = anim:getCurrentFrame() * 16
                lurek.render.rectangle("fill", src_x, 0, 16, 16)
            end), "render call " .. i .. " with animation frame")
        end
        expect_equal(4, #offsets, "exactly 4 frame updates recorded")
        for i, f in ipairs(offsets) do
            expect_true(f >= 1, "frame index >= 1 at update step " .. i)
        end
    end)
end)

test_summary()
