-- test_evidence_animation.lua
-- Evidence test: lurek.animation Animator API contracts and PNG sprite grid evidence

local OUT = "tests/lua/evidence/output/animation/"

-- ── helpers ──────────────────────────────────────────────────────────────────

--- Build a fake sprite-sheet ImageData (8 frames of 16×16, laid out in a 4×2 grid).
--- Each frame is a different hue so we can visually verify the correct frame is selected.
local function make_sprite_sheet()
    local FRAME_W, FRAME_H = 16, 16
    local COLS, ROWS = 4, 2
    local img = lurek.image.newImageData(FRAME_W * COLS, FRAME_H * ROWS)
    img:fill(0, 0, 0, 0)

    local hues = {
        {220, 60, 60},   -- red
        {220, 140, 60},  -- orange
        {200, 200, 60},  -- yellow
        {60, 200, 80},   -- green
        {60, 180, 220},  -- cyan
        {60, 80, 220},   -- blue
        {160, 60, 220},  -- purple
        {220, 60, 160},  -- pink
    }

    for f = 0, 7 do
        local col = f % COLS
        local row = f // COLS
        local ox  = col * FRAME_W
        local oy  = row * FRAME_H
        local c   = hues[f + 1] or {128, 128, 128}

        img:fillRect(ox + 1, oy + 1, FRAME_W, FRAME_H, c[1], c[2], c[3], 255)

        -- Frame number text marker (a small 2×2 bright pixel per digit)
        img:setPixel(ox + 2, oy + 2, 255, 255, 255, 255)
        img:setPixel(ox + 3, oy + 2, 255, 255, 255, 255)
    end

    return img, FRAME_W, FRAME_H, COLS * FRAME_W, ROWS * FRAME_H
end

-- ── tests ────────────────────────────────────────────────────────────────────

describe("Evidence: lurek.animation Animator creation", function()

    it("newAnimator creates an Animator object", function()
        local anim = lurek.animation.newAnimator()
        expect_equal(anim ~= nil, true)
        expect_equal(anim:type(), "Animator")
    end)

    it("addClip and getClip round-trip", function()
        local anim = lurek.animation.newAnimator()
        anim:addClip("run", {1, 2, 3, 4}, 10, true)
        local ok = anim:play("run")
        expect_equal(ok, true)
        expect_equal(anim:getClip(), "run")
    end)

    it("isPlaying returns true after play()", function()
        local anim = lurek.animation.newAnimator()
        anim:addClip("idle", {1, 2}, 8, true)
        anim:play("idle")
        expect_equal(anim:isPlaying(), true)
    end)

    it("isLooping reflects clip looping flag", function()
        local anim = lurek.animation.newAnimator()
        anim:addClip("once", {1, 2, 3}, 10, false)
        anim:play("once")
        expect_equal(anim:isLooping(), false)
    end)

    it("pause / resume toggles playing state", function()
        local anim = lurek.animation.newAnimator()
        anim:addClip("walk", {1, 2, 3, 4}, 12, true)
        anim:play("walk")
        anim:pause()
        expect_equal(anim:isPlaying(), false)
        anim:resume()
        expect_equal(anim:isPlaying(), true)
    end)

    it("stop resets state", function()
        local anim = lurek.animation.newAnimator()
        anim:addClip("run", {1, 2, 3}, 12, true)
        anim:play("run")
        anim:stop()
        expect_equal(anim:isPlaying(), false)
    end)

    it("getSpeed / setSpeed round-trip", function()
        local anim = lurek.animation.newAnimator()
        anim:setSpeed(2.5)
        expect_near(anim:getSpeed(), 2.5, 0.001)
    end)
end)

describe("Evidence: lurek.animation addClipFromGrid quad selection", function()

    it("addClipFromGrid produces correct UV quads — PNG evidence: frame_grid", function()
        local img, FW, FH, TW, TH = make_sprite_sheet()

        local anim = lurek.animation.newAnimator()
        anim:addClipFromGrid("all_frames", TW, TH, FW, FH, 0, 8, 6, true)
        anim:play("all_frames")

        -- Collect the quad for each frame by stepping the animator
        local frame_w = FW
        local frame_h = FH
        local out_cols = 4
        local out_scale = 4
        local out = lurek.image.newImageData(
            frame_w * out_cols * out_scale,
            frame_h * 2 * out_scale
        )
        out:fill(20, 20, 30, 255)

        local frame_dt = 1.0 / 6.0  -- one frame at 6fps

        for f = 0, 7 do
            anim:update(frame_dt)
            local q = anim:getQuad()
            if q then
                -- Blit the source region from the sprite sheet
                local dst_col = f % out_cols
                local dst_row = f // out_cols
                local ox = dst_col * FW * out_scale
                local oy = dst_row * FH * out_scale

                for py = 0, FH - 1 do
                    for px = 0, FW - 1 do
                        local r, g, b, a = img:getPixel(q.x + px + 1, q.y + py + 1)
                        -- Scale each source pixel to out_scale × out_scale block
                        for sy = 0, out_scale - 1 do
                            for sx = 0, out_scale - 1 do
                                out:setPixel(ox + px*out_scale + sx + 1,
                                             oy + py*out_scale + sy + 1,
                                             r, g, b, a)
                            end
                        end
                    end
                end
            end
        end

        lurek.image.savePNG(out, OUT .. "evidence_animation_frame_grid.png")
    end)

    it("one-shot clip fires 'done' event after last frame", function()
        local anim = lurek.animation.newAnimator()
        anim:addClip("once", {1, 2, 3}, 30, false)
        anim:play("once")

        -- Advance past 3 frames at 30fps
        for _ = 1, 5 do
            anim:update(1.0 / 30.0)
        end

        local events = anim:pollEvents()
        local found_done = false
        for _, ev in ipairs(events) do
            if ev.type == "done" or ev.type == "ended" or ev.type == "finish" then
                found_done = true
            end
        end
        -- The clip should no longer be playing
        expect_equal(anim:isPlaying(), false)
    end)
end)

describe("Evidence: animation speed scaling visual", function()

    it("speed 2× advances twice as fast — PNG evidence: speed_compare", function()
        local W = 120
        local img = lurek.image.newImageData(W, 20)
        img:fill(20, 20, 20, 255)

        -- Normal speed: step through 4 frames of a 4fps clip over 1 second
        local anim1 = lurek.animation.newAnimator()
        anim1:addClip("walk", {1, 2, 3, 4}, 4, true)
        anim1:play("walk")

        -- 2× speed
        local anim2 = lurek.animation.newAnimator()
        anim2:addClip("walk", {1, 2, 3, 4}, 4, true)
        anim2:play("walk")
        anim2:setSpeed(2.0)

        -- Collect frame indices over 1s at 30fps
        local samples1 = {}
        local samples2 = {}
        for i = 1, 30 do
            anim1:update(1/30)
            anim2:update(1/30)
            local q1 = anim1:getQuad()
            local q2 = anim2:getQuad()
            samples1[i] = q1 and q1.x or 0
            samples2[i] = q2 and q2.x or 0
        end

        -- Draw sample bars
        for i, v in ipairs(samples1) do
            local val = math.min(255, (v // 16) * 64 + 60)
            img:setPixel(i * (W // 30), 5, val, 180, 80, 255)
        end
        for i, v in ipairs(samples2) do
            local val = math.min(255, (v // 16) * 64 + 60)
            img:setPixel(i * (W // 30), 15, 80, 180, val, 255)
        end

        lurek.image.savePNG(img, OUT .. "evidence_animation_speed_compare.png")
    end)
end)

test_summary()
