local function evidence_output_dir()
    local path = lurek.fs.getAppDir() .. "/tests/lua/golden/evidence_output/migrated_20"
    lurek.fs.createDirectory(path)
    return path
end

local out_dir = evidence_output_dir()

local function save_png(name, img)
    local path = out_dir .. "/" .. name .. ".png"
    img:savePng(path)
    return path
end

local function save_wav(name, sound)
    local path = out_dir .. "/" .. name .. ".wav"
    lurek.audio.saveWAV(sound, path)
    return path
end

describe("Migrated Evidence Tests 20", function()
    it("generates fixture_sprite_8x8", function()
        local img = lurek.img.newImageData(8, 8)
        img:fill(0, 0, 0, 0)
        img:setPixel(2, 2, 255, 255, 255, 255)
        img:setPixel(5, 2, 255, 255, 255, 255)
        img:setPixel(2, 5, 255, 255, 255, 255)
        img:setPixel(3, 6, 255, 255, 255, 255)
        img:setPixel(4, 6, 255, 255, 255, 255)
        img:setPixel(5, 5, 255, 255, 255, 255)
        local p = save_png("sprite_8x8", img)
        expect_evidence_created(p)
    end)

    it("generates fixture_sprite_16x16", function()
        local img = lurek.img.newImageData(16, 16)
        for i = 0, 15 do
            img:setPixel(7, i, 255, 0, 0, 255)
            img:setPixel(8, i, 255, 0, 0, 255)
            img:setPixel(i, 7, 0, 0, 255, 255)
            img:setPixel(i, 8, 0, 0, 255, 255)
        end
        local p = save_png("sprite_16x16", img)
        expect_evidence_created(p)
    end)

    it("generates fixture_sprite_32x32", function()
        local img = lurek.img.newImageData(32, 32)
        for y = 0, 31 do
            for x = 0, 31 do
                local dx = x - 15.5
                local dy = y - 15.5
                local dist = math.sqrt(dx*dx + dy*dy)
                local alpha = 255 - math.min(255, math.floor(dist * 16))
                img:setPixel(x, y, 0, 255, 0, alpha)
            end
        end
        local p = save_png("sprite_32x32", img)
        expect_evidence_created(p)
    end)

    it("generates fixture_sprite_64x64", function()
        local img = lurek.img.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 63 do
                local checker = (math.floor(x / 8) + math.floor(y / 8)) % 2 == 0
                if checker then
                    img:setPixel(x, y, 200, 200, 200, 255)
                else
                    img:setPixel(x, y, 50, 50, 50, 255)
                end
            end
        end
        local p = save_png("sprite_64x64", img)
        expect_evidence_created(p)
    end)

    it("generates fixture_tileset_128x128", function()
        local img = lurek.img.newImageData(128, 128)
        for ty = 0, 7 do
            for tx = 0, 7 do
                local r = tx * 36
                local g = ty * 36
                local b = 128
                for y = 0, 15 do
                    for x = 0, 15 do
                        img:setPixel(tx * 16 + x, ty * 16 + y, r, g, b, 255)
                    end
                end
            end
        end
        local p = save_png("tileset_128x128", img)
        expect_evidence_created(p)
    end)

    it("generates fixture_gradient_horizontal", function()
        local img = lurek.img.newImageData(256, 32)
        for y = 0, 31 do
            for x = 0, 255 do
                img:setPixel(x, y, x, 0, 255 - x, 255)
            end
        end
        local p = save_png("gradient_horizontal", img)
        expect_evidence_created(p)
    end)

    it("generates fixture_gradient_vertical", function()
        local img = lurek.img.newImageData(32, 256)
        for y = 0, 255 do
            for x = 0, 31 do
                img:setPixel(x, y, 0, y, 255 - y, 255)
            end
        end
        local p = save_png("gradient_vertical", img)
        expect_evidence_created(p)
    end)

    local function draw_bezier_to_image(curves_data, w, h)
        local bg = lurek.img.newImageData(w, h)
        bg:fill(25, 25, 25, 255)

        for _, cdata in ipairs(curves_data) do
            local pts, color = cdata[1], cdata[2]
            local flat_pts = {}
            for _, pt in ipairs(pts) do
                table.insert(flat_pts, pt.x)
                table.insert(flat_pts, pt.y)
            end
            local curve = lurek.math.newBezierCurve(flat_pts)

            -- draw lines connecting t-steps
            local segments = 100
            local last_x, last_y = curve:evaluate(0)
            for i = 1, segments do
                local t = i / segments
                local x, y = curve:evaluate(t)
                bg:drawLine(last_x, last_y, x, y, color[1], color[2], color[3], 255)
                last_x, last_y = x, y
            end

            -- draw points
            for _, pt in ipairs(pts) do
                bg:drawCircle(pt.x, pt.y, 3, 255, 100, 100, 255, true)
            end
        end
        return bg
    end

    it("generates evidence_math_bezier_curve", function()
        local curves = {
            {
                { {x=10,y=200}, {x=60,y=20}, {x=180,y=20}, {x=245,y=245} },
                {80, 80, 255}
            }
        }
        local img = draw_bezier_to_image(curves, 256, 256)
        local p = save_png("bezier_curve", img)
        expect_evidence_created(p)
    end)

    it("generates evidence_math_bezier_multiple", function()
        local curves = {
            {
                { {x=10,y=128}, {x=80,y=10}, {x=170,y=245}, {x=245,y=128} },
                {255, 80, 80}
            },
            {
                { {x=10,y=128}, {x=80,y=245}, {x=170,y=10}, {x=245,y=128} },
                {80, 255, 80}
            }
        }
        local img = draw_bezier_to_image(curves, 256, 256)
        local p = save_png("bezier_multiple_curves", img)
        expect_evidence_created(p)
    end)

    it("generates evidence_audio_stereo", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 2)
        -- Left 440, Right 880
        for i = 0, ns - 1 do
            local t = i / sr
            local fl = 440.0
            local fr = 880.0
            local left = math.sin(t * fl * math.pi * 2) * 0.5
            local right = math.sin(t * fr * math.pi * 2) * 0.5
            sound:setSample(i * 2 + 0, left)
            sound:setSample(i * 2 + 1, right)
        end
        local p = save_wav("stereo_two_tones", sound)
        expect_evidence_created(p)
    end)

    it("generates evidence_audio_frequency_sweep", function()
        local sr = 44100
        local ns = sr * 2
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        local sf = 100.0
        local ef = 4000.0
        for i = 0, ns - 1 do
            local t = i / sr
            local f = sf + (ef - sf) * (t / 2.0)
            local v = math.sin(t * f * math.pi * 2) * 0.5
            sound:setSample(i, v)
        end
        local p = save_wav("frequency_sweep_100_4000", sound)
        expect_evidence_created(p)
    end)

    it("generates evidence_audio_amplitude_envelope", function()
        local sr = 44100
        local ns = sr * 2
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local v = math.sin(t * 440.0 * math.pi * 2)
            local env = 1.0
            if t < 0.2 then
                env = t / 0.2
            elseif t > 1.5 then
                env = 1.0 - (t - 1.5) / 0.5
            end
            sound:setSample(i, v * env * 0.8)
        end
        local p = save_wav("amplitude_envelope", sound)
        expect_evidence_created(p)
    end)

    it("generates evidence_audio_square_wave", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local v = math.sin(t * 440.0 * math.pi * 2)
            sound:setSample(i, v > 0 and 0.4 or -0.4)
        end
        local p = save_wav("square_wave_440hz", sound)
        expect_evidence_created(p)
    end)

    it("generates evidence_audio_sawtooth_wave", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local phase = (t * 440.0) % 1.0
            local v = (phase * 2.0 - 1.0) * 0.4
            sound:setSample(i, v)
        end
        local p = save_wav("sawtooth_wave_440hz", sound)
        expect_evidence_created(p)
    end)

    it("generates evidence_audio_white_noise", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        local st = 12345
        for i = 0, ns - 1 do
            st = (st * 1103515245 + 12345) % 2147483648
            local rv = (st / 2147483648.0) * 2.0 - 1.0
            sound:setSample(i, rv * 0.2)
        end
        local p = save_wav("white_noise", sound)
        expect_evidence_created(p)
    end)

    it("generates evidence_audio_silence", function()
        local sr = 44100
        local ns = 22050
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            sound:setSample(i, 0.0)
        end
        local p = save_wav("silence_half_second", sound)
        expect_evidence_created(p)
    end)

    it("generates evidence_audio_waveform_visualization", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local v = math.sin(t * 440.0 * math.pi * 2) * 0.5
            sound:setSample(i, v)
        end
        local p = save_wav("waveform_sine_440hz_audio", sound)
        expect_evidence_created(p)
    end)

    it("generates evidence_noise_to_heightmap_render", function()
        local ng = lurek.math.newNoiseGenerator(7777)
        local size = 256
        local img = lurek.img.newImageData(size, size)

        for y = 0, size - 1 do
            for x = 0, size - 1 do
                -- Simplex 5 octaves mapping to [0,1]
                local scale = 0.01
                local amp = 1.0
                local freq = 1.0
                local max_amp = 0.0
                local v = 0.0
                for o = 1, 5 do
                    local ev = lurek.math.simplexNoise(x * scale * freq, y * scale * freq)
                    v = v + ev * amp
                    max_amp = max_amp + amp
                    amp = amp * 0.5
                    freq = freq * 2.0
                end
                v = v / max_amp
                -- Map [-1, 1] to [0, 1]
                local nv = (v + 1.0) / 2.0
                -- Coloring (water, sand, grass, rock, snow)
                local r, g, b = 255, 255, 255
                if nv < 0.4 then r,g,b = 0, 100, 200
                elseif nv < 0.45 then r,g,b = 200, 200, 100
                elseif nv < 0.7 then r,g,b = 34, 139, 34
                elseif nv < 0.9 then r,g,b = 100, 100, 100
                else r,g,b = 255, 250, 250 end
                img:setPixel(x, y, r, g, b, 255)
            end
        end

        local p = save_png("noise_heightmap_colored", img)
        expect_evidence_created(p)
    end)

    it("generates evidence_image_all_effects_grid", function()
        local tile = 64
        local cols = 5
        local rows = 4
        local canvas = lurek.img.newImageData(tile * cols, tile * rows)
        canvas:fill(30, 30, 30, 255)

        local function make_base()
            local img = lurek.img.newImageData(tile, tile)
            for y = 0, tile - 1 do
                for x = 0, tile - 1 do
                    img:setPixel(x, y, x * 4, y * 4, 128, 255)
                end
            end
            return img
        end

        local effects = {
            function(i) return i end,
            function(i) i:brightness(0.3); return i end,
            function(i) i:contrast(2.0); return i end,
            function(i) i:grayscale(); return i end,
            function(i) i:sepia(); return i end,
            function(i) i:invert(); return i end,
            function(i) i:threshold(128); return i end,
            function(i) i:posterize(4); return i end,
            function(i) i:tint(255, 0, 0, 127); return i end,
            function(i) i:saturation(0.0); return i end,
            function(i) i:gamma(0.5); return i end,
            function(i) i:gamma(2.2); return i end,
            function(i) i:noise(60); return i end,
            function(i) i:alphaMask(0.5); return i end,
            function(i) i:flipHorizontal(); return i end,
            function(i) i:flipVertical(); return i end,
            function(i) i:rotate90Cw(); return i end,
            function(i) i:blur(2); return i end,
            function(i) i:sharpen(); return i end,
            function(i)
                local c = i:crop(8, 8, 48, 48)
                c:resizeNearest(tile, tile)
                return c
            end
        }

        for i, apply in ipairs(effects) do
            local base = make_base()
            local res = apply(base)
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            canvas:paste(res, col * tile, row * tile)
        end
        local p = save_png("all_effects_grid", canvas)
        expect_evidence_created(p)
    end)

    it("generates evidence_tilemap_multi_layer", function()
        local tm = lurek.tilemap.newTileMap(16, 16, 8)
        local ground = tm:addLayer("ground", 10, 10)
        local objects = tm:addLayer("objects", 10, 10)
        tm:fill(ground, 1)
        tm:setTile(objects, 3, 3, 10)
        tm:setTile(objects, 5, 5, 11)
        tm:setTile(objects, 7, 2, 12)
        local img = tm:drawToImage(16)
        local p = save_png("multi_layer", img)
        expect_evidence_created(p)
    end)
end)

test_summary()
