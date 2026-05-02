-- test_evidence_easing.lua
-- Evidence test: All easing curves plotted as images

local OUT = "tests/output/easing/"

local EASINGS = {
    "linear", "inQuad", "outQuad", "inOutQuad",
    "inCubic", "outCubic", "inOutCubic",
    "inSine", "outSine", "inOutSine",
    "inExpo", "outExpo",
    "outBounce",
    "inElastic", "outElastic",
    "inBack", "outBack",
}

-- Distinct colors for each easing curve (R, G, B)
local COLORS = {
    {255, 255, 255}, {255, 0, 0},     {0, 255, 0},     {0, 0, 255},
    {255, 255, 0},   {255, 0, 255},   {0, 255, 255},
    {255, 128, 0},   {128, 255, 0},   {0, 128, 255},
    {255, 0, 128},   {128, 0, 255},
    {0, 255, 128},
    {200, 200, 100}, {100, 200, 200},
    {200, 100, 200}, {180, 180, 180},
}

describe("Evidence: Easing curves", function()

    -- @evidence file
    it("plots all easing curves on combined image", function()
        local W, H = 800, 600
        local margin = 40
        local plotW = W - margin * 2
        local plotH = H - margin * 2

        local img = lurek.image.newImageData(W, H)
        -- Dark background
        img:drawRect(0, 0, W, H, 30, 30, 40, 255)

        -- Axes
        for x = margin, margin + plotW do
            img:setPixel(x, margin + plotH, 100, 100, 100, 255)
            img:setPixel(x, margin, 60, 60, 60, 255)
        end
        for y = margin, margin + plotH do
            img:setPixel(margin, y, 100, 100, 100, 255)
            img:setPixel(margin + plotW, y, 60, 60, 60, 255)
        end

        -- Plot each curve
        local steps = 200
        for ci, name in ipairs(EASINGS) do
            local col = COLORS[ci] or {200, 200, 200}
            for i = 0, steps do
                local t = i / steps
                local ok, val = pcall(lurek.math.applyEasing, name, t)
                if ok then
                    local px = math.floor(margin + t * plotW)
                    local py = math.floor(margin + plotH - val * plotH)
                    px = math.max(0, math.min(W - 3, px))
                    py = math.max(0, math.min(H - 3, py))
                    img:drawRect(px, py, 2, 2, col[1], col[2], col[3], 255)
                end
            end
        end

        lurek.image.savePNG(img, OUT .. "easing_all_curves.png")
    end)

    -- @evidence file
    it("saves individual easing curve images", function()
        local W, H = 256, 128
        local margin = 8
        local plotW = W - margin * 2
        local plotH = H - margin * 2
        local saved = 0

        for _, name in ipairs(EASINGS) do
            local img = lurek.image.newImageData(W, H)
            img:drawRect(0, 0, W, H, 20, 20, 30, 255)

            -- Axis lines
            img:drawLine(margin, margin + plotH, margin + plotW, margin + plotH, 80, 80, 80, 255)
            img:drawLine(margin, margin, margin, margin + plotH, 80, 80, 80, 255)

            -- Plot curve
            local steps = 200
            for i = 0, steps do
                local t = i / steps
                local ok, val = pcall(lurek.math.applyEasing, name, t)
                if ok then
                    local px = math.floor(margin + t * plotW)
                    local py = math.floor(margin + plotH - val * plotH)
                    px = math.max(0, math.min(W - 3, px))
                    py = math.max(0, math.min(H - 3, py))
                    img:drawRect(px, py, 2, 2, 100, 200, 255, 255)
                end
            end

            lurek.image.savePNG(img, OUT .. "easing_" .. name .. ".png")
            saved = saved + 1
        end

    end)

end)



-- ================================================================
-- Merged from: test_evidence_easing.lua
-- ================================================================

-- test_evidence_easing.lua
-- Evidence test: All easing curves plotted as images

local OUT = "tests/output/easing/"

local EASINGS = {
    "linear", "inQuad", "outQuad", "inOutQuad",
    "inCubic", "outCubic", "inOutCubic",
    "inSine", "outSine", "inOutSine",
    "inExpo", "outExpo",
    "outBounce",
    "inElastic", "outElastic",
    "inBack", "outBack",
}

-- Distinct colors for each easing curve (R, G, B)
local COLORS = {
    {255, 255, 255}, {255, 0, 0},     {0, 255, 0},     {0, 0, 255},
    {255, 255, 0},   {255, 0, 255},   {0, 255, 255},
    {255, 128, 0},   {128, 255, 0},   {0, 128, 255},
    {255, 0, 128},   {128, 0, 255},
    {0, 255, 128},
    {200, 200, 100}, {100, 200, 200},
    {200, 100, 200}, {180, 180, 180},
}

describe("Evidence: Easing curves", function()

    -- @evidence file
    it("plots all easing curves on combined image", function()
        local W, H = 800, 600
        local margin = 40
        local plotW = W - margin * 2
        local plotH = H - margin * 2

        local img = lurek.image.newImageData(W, H)
        -- Dark background
        img:drawRect(0, 0, W, H, 30, 30, 40, 255)

        -- Axes
        for x = margin, margin + plotW do
            img:setPixel(x, margin + plotH, 100, 100, 100, 255)
            img:setPixel(x, margin, 60, 60, 60, 255)
        end
        for y = margin, margin + plotH do
            img:setPixel(margin, y, 100, 100, 100, 255)
            img:setPixel(margin + plotW, y, 60, 60, 60, 255)
        end

        -- Plot each curve
        local steps = 200
        for ci, name in ipairs(EASINGS) do
            local col = COLORS[ci] or {200, 200, 200}
            for i = 0, steps do
                local t = i / steps
                local ok, val = pcall(lurek.math.applyEasing, name, t)
                if ok then
                    local px = math.floor(margin + t * plotW)
                    local py = math.floor(margin + plotH - val * plotH)
                    px = math.max(0, math.min(W - 3, px))
                    py = math.max(0, math.min(H - 3, py))
                    img:drawRect(px, py, 2, 2, col[1], col[2], col[3], 255)
                end
            end
        end

        lurek.image.savePNG(img, OUT .. "easing_all_curves.png")
    end)

    -- @evidence file
    it("saves individual easing curve images", function()
        local W, H = 256, 128
        local margin = 8
        local plotW = W - margin * 2
        local plotH = H - margin * 2
        local saved = 0

        for _, name in ipairs(EASINGS) do
            local img = lurek.image.newImageData(W, H)
            img:drawRect(0, 0, W, H, 20, 20, 30, 255)

            -- Axis lines
            img:drawLine(margin, margin + plotH, margin + plotW, margin + plotH, 80, 80, 80, 255)
            img:drawLine(margin, margin, margin, margin + plotH, 80, 80, 80, 255)

            -- Plot curve
            local steps = 200
            for i = 0, steps do
                local t = i / steps
                local ok, val = pcall(lurek.math.applyEasing, name, t)
                if ok then
                    local px = math.floor(margin + t * plotW)
                    local py = math.floor(margin + plotH - val * plotH)
                    px = math.max(0, math.min(W - 3, px))
                    py = math.max(0, math.min(H - 3, py))
                    img:drawRect(px, py, 2, 2, 100, 200, 255, 255)
                end
            end

            lurek.image.savePNG(img, OUT .. "easing_" .. name .. ".png")
            saved = saved + 1
        end

    end)

end)

-- ================================================================
-- Merged from: test_easing_evidence.lua
-- ================================================================

-- test_evidence_easing.lua
-- Evidence test: All easing curves plotted as images

local OUT = "tests/output/easing/"

local EASINGS = {
    "linear", "inQuad", "outQuad", "inOutQuad",
    "inCubic", "outCubic", "inOutCubic",
    "inSine", "outSine", "inOutSine",
    "inExpo", "outExpo",
    "outBounce",
    "inElastic", "outElastic",
    "inBack", "outBack",
}

-- Distinct colors for each easing curve (R, G, B)
local COLORS = {
    {255, 255, 255}, {255, 0, 0},     {0, 255, 0},     {0, 0, 255},
    {255, 255, 0},   {255, 0, 255},   {0, 255, 255},
    {255, 128, 0},   {128, 255, 0},   {0, 128, 255},
    {255, 0, 128},   {128, 0, 255},
    {0, 255, 128},
    {200, 200, 100}, {100, 200, 200},
    {200, 100, 200}, {180, 180, 180},
}

describe("Evidence: Easing curves", function()

    -- @evidence file
    it("plots all easing curves on combined image", function()
        local W, H = 800, 600
        local margin = 40
        local plotW = W - margin * 2
        local plotH = H - margin * 2

        local img = lurek.image.newImageData(W, H)
        -- Dark background
        img:drawRect(0, 0, W, H, 30, 30, 40, 255)

        -- Axes
        for x = margin, margin + plotW do
            img:setPixel(x, margin + plotH, 100, 100, 100, 255)
            img:setPixel(x, margin, 60, 60, 60, 255)
        end
        for y = margin, margin + plotH do
            img:setPixel(margin, y, 100, 100, 100, 255)
            img:setPixel(margin + plotW, y, 60, 60, 60, 255)
        end

        -- Plot each curve
        local steps = 200
        for ci, name in ipairs(EASINGS) do
            local col = COLORS[ci] or {200, 200, 200}
            for i = 0, steps do
                local t = i / steps
                local ok, val = pcall(lurek.math.applyEasing, name, t)
                if ok then
                    local px = math.floor(margin + t * plotW)
                    local py = math.floor(margin + plotH - val * plotH)
                    px = math.max(0, math.min(W - 3, px))
                    py = math.max(0, math.min(H - 3, py))
                    img:drawRect(px, py, 2, 2, col[1], col[2], col[3], 255)
                end
            end
        end

        lurek.image.savePNG(img, OUT .. "easing_all_curves.png")
    end)

    -- @evidence file
    it("saves individual easing curve images", function()
        local W, H = 256, 128
        local margin = 8
        local plotW = W - margin * 2
        local plotH = H - margin * 2
        local saved = 0

        for _, name in ipairs(EASINGS) do
            local img = lurek.image.newImageData(W, H)
            img:drawRect(0, 0, W, H, 20, 20, 30, 255)

            -- Axis lines
            img:drawLine(margin, margin + plotH, margin + plotW, margin + plotH, 80, 80, 80, 255)
            img:drawLine(margin, margin, margin, margin + plotH, 80, 80, 80, 255)

            -- Plot curve
            local steps = 200
            for i = 0, steps do
                local t = i / steps
                local ok, val = pcall(lurek.math.applyEasing, name, t)
                if ok then
                    local px = math.floor(margin + t * plotW)
                    local py = math.floor(margin + plotH - val * plotH)
                    px = math.max(0, math.min(W - 3, px))
                    py = math.max(0, math.min(H - 3, py))
                    img:drawRect(px, py, 2, 2, 100, 200, 255, 255)
                end
            end

            lurek.image.savePNG(img, OUT .. "easing_" .. name .. ".png")
            saved = saved + 1
        end

    end)

end)



-- ================================================================
-- Merged from: test_evidence_easing.lua
-- ================================================================

-- test_evidence_easing.lua
-- Evidence test: All easing curves plotted as images

local OUT = "tests/output/easing/"

local EASINGS = {
    "linear", "inQuad", "outQuad", "inOutQuad",
    "inCubic", "outCubic", "inOutCubic",
    "inSine", "outSine", "inOutSine",
    "inExpo", "outExpo",
    "outBounce",
    "inElastic", "outElastic",
    "inBack", "outBack",
}

-- Distinct colors for each easing curve (R, G, B)
local COLORS = {
    {255, 255, 255}, {255, 0, 0},     {0, 255, 0},     {0, 0, 255},
    {255, 255, 0},   {255, 0, 255},   {0, 255, 255},
    {255, 128, 0},   {128, 255, 0},   {0, 128, 255},
    {255, 0, 128},   {128, 0, 255},
    {0, 255, 128},
    {200, 200, 100}, {100, 200, 200},
    {200, 100, 200}, {180, 180, 180},
}

describe("Evidence: Easing curves", function()

    -- @evidence file
    it("plots all easing curves on combined image", function()
        local W, H = 800, 600
        local margin = 40
        local plotW = W - margin * 2
        local plotH = H - margin * 2

        local img = lurek.image.newImageData(W, H)
        -- Dark background
        img:drawRect(0, 0, W, H, 30, 30, 40, 255)

        -- Axes
        for x = margin, margin + plotW do
            img:setPixel(x, margin + plotH, 100, 100, 100, 255)
            img:setPixel(x, margin, 60, 60, 60, 255)
        end
        for y = margin, margin + plotH do
            img:setPixel(margin, y, 100, 100, 100, 255)
            img:setPixel(margin + plotW, y, 60, 60, 60, 255)
        end

        -- Plot each curve
        local steps = 200
        for ci, name in ipairs(EASINGS) do
            local col = COLORS[ci] or {200, 200, 200}
            for i = 0, steps do
                local t = i / steps
                local ok, val = pcall(lurek.math.applyEasing, name, t)
                if ok then
                    local px = math.floor(margin + t * plotW)
                    local py = math.floor(margin + plotH - val * plotH)
                    px = math.max(0, math.min(W - 3, px))
                    py = math.max(0, math.min(H - 3, py))
                    img:drawRect(px, py, 2, 2, col[1], col[2], col[3], 255)
                end
            end
        end

        lurek.image.savePNG(img, OUT .. "easing_all_curves.png")
    end)

    -- @evidence file
    it("saves individual easing curve images", function()
        local W, H = 256, 128
        local margin = 8
        local plotW = W - margin * 2
        local plotH = H - margin * 2
        local saved = 0

        for _, name in ipairs(EASINGS) do
            local img = lurek.image.newImageData(W, H)
            img:drawRect(0, 0, W, H, 20, 20, 30, 255)

            -- Axis lines
            img:drawLine(margin, margin + plotH, margin + plotW, margin + plotH, 80, 80, 80, 255)
            img:drawLine(margin, margin, margin, margin + plotH, 80, 80, 80, 255)

            -- Plot curve
            local steps = 200
            for i = 0, steps do
                local t = i / steps
                local ok, val = pcall(lurek.math.applyEasing, name, t)
                if ok then
                    local px = math.floor(margin + t * plotW)
                    local py = math.floor(margin + plotH - val * plotH)
                    px = math.max(0, math.min(W - 3, px))
                    py = math.max(0, math.min(H - 3, py))
                    img:drawRect(px, py, 2, 2, 100, 200, 255, 255)
                end
            end

            lurek.image.savePNG(img, OUT .. "easing_" .. name .. ".png")
            saved = saved + 1
        end

    end)

end)
test_summary()
