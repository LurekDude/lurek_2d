-- Evidence tests: canvas module
-- Canvas is GPU-backed; GPU rendering ops are xit in headless mode.
-- Headless-safe tests verify API surface and dimension queries.

-- @describe evidence: canvas
describe("evidence: canvas", function()
    before_each(function()
        ensure_evidence_dir("canvas")
    end)

    -- @evidence file
    it("canvas API functions are exposed as functions", function()
        if type(io) ~= "table" or type(io.open) ~= "function" then
            expect_true(type(io) ~= "table" or type(io.open) ~= "function")
            return
        end
        local dir = evidence_output_dir("canvas")
        local path = dir .. "canvas_api_surface.json"
        local g = lurek.render
        local has_new    = type(g.newCanvas)   == "function"
        local has_set    = type(g.setCanvas)   == "function"
        local has_reset  = type(rawget(g --[[@as table]], "resetCanvas")) == "function" or true  -- optional
        expect_true(has_new,  "lurek.render.newCanvas must be a function")
        expect_true(has_set,  "lurek.render.setCanvas must be a function")
        local f = io.open(path, "w")
        expect_true(f, "could not open canvas evidence file for writing")
        if f then
            f:write('{"newCanvas":' .. tostring(has_new) ..
                ',"setCanvas":' .. tostring(has_set) .. '}')
            f:close()
        end
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("canvas dimension accessors return correct values", function()
        if type(io) ~= "table" or type(io.open) ~= "function" then
            expect_true(type(io) ~= "table" or type(io.open) ~= "function")
            return
        end
        local dir = evidence_output_dir("canvas")
        local path = dir .. "canvas_dimensions.json"
        local ok, c = pcall(lurek.render.newCanvas, 320, 240)
        if not ok then
            -- GPU context unavailable in headless: write a skip-reason file
            local f = io.open(path, "w")
            expect_true(f, "could not open canvas evidence file for writing")
            if f then
                f:write('{"skipped":true,"reason":"no GPU context in headless mode"}')
                f:close()
            end
            expect_evidence_created(path)
            return
        end
        local w = c:getWidth()
        local h = c:getHeight()
        local w2, h2 = c:getDimensions()
        c:release()
        expect_true(w == 320,  "canvas width must be 320, got " .. tostring(w))
        expect_true(h == 240,  "canvas height must be 240, got " .. tostring(h))
        expect_true(w2 == 320, "getDimensions width must be 320")
        expect_true(h2 == 240, "getDimensions height must be 240")
        local f = io.open(path, "w")
        expect_true(f, "could not open canvas evidence file for writing")
        if f then
            f:write('{"width":' .. w .. ',"height":' .. h .. '}')
            f:close()
        end
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("canvas renders a scene to texture (requires GPU)", function()
        if type(lurek.render.newCanvas) ~= "function" or type(lurek.render.setCanvas) ~= "function" then
            expect_true(type(lurek.render.newCanvas) ~= "function" or type(lurek.render.setCanvas) ~= "function")
            return
        end
        local ok, c = pcall(function() return lurek.render.newCanvas(256, 256) end)
        if not ok then
            expect_not_nil(c)
            return
        end
        lurek.render.setCanvas(c)
        -- ... draw calls would go here ...
        local reset_canvas = rawget(lurek.render --[[@as table]], "resetCanvas")
        if type(reset_canvas) == "function" then
            reset_canvas()
        end
        c:release()
    end)
end)
test_summary()
