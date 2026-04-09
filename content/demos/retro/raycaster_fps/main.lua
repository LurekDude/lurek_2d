-- demos/retro/raycaster_fps/main.lua
-- Raycaster FPS � Wolfenstein-style smooth FPS with procedurally generated
--   textured walls (6 types), textured floor/ceiling gradient, distance fog,
--   weather overlays (rain/snow), billboard item sprites, depth buffer
-- Controls: WASD move/strafe, Q/E rotate, F1/F2/F3 weather, Escape quit
-- Run with: cargo run -- content/demos/retro/raycaster_fps

-- �� constants �������������������������������������������������
local SW, SH      = 960, 540        -- screen resolution
local RW, RH      = 320, 180        -- low-res render canvas
local FOV         = math.pi / 2.5   -- ~72� horizontal FOV
local MAX_DIST    = 16.0
local MOVE_SPEED  = 3.5
local ROT_SPEED   = 2.2
local MAP_W, MAP_H = 16, 16
local TEX_W, TEX_H = 64, 64         -- texture atlas size per texture
local NBANDS      = 16              -- floor/ceiling gradient bands

-- �� map �������������������������������������������������������
-- 0=empty, 1=stone, 2=brick, 3=blue_stone, 4=red_stone, 5=mossy, 6=gold
local MAP = {
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,2,2,0,0,3,0,0,3,0,0,2,2,0,1,
    1,0,2,0,0,0,3,0,0,3,0,0,0,2,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,4,0,0,0,0,0,0,0,0,0,0,4,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,4,0,0,0,0,0,0,0,0,0,0,4,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,5,0,0,0,6,0,0,6,0,0,0,5,0,1,
    1,0,5,5,0,0,6,0,0,6,0,0,5,5,0,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
}

-- Item pickup positions (cells that contain pickups, before we clear them)
local ITEM_CELLS = {
    {5, 4}, {11, 4}, {5, 11}, {11, 11},
}

-- �� wall tints (RGB, multiplied with greyscale texture) ��������
local WALL_TINT = {
    [1] = {0.60, 0.58, 0.55},  -- stone grey
    [2] = {0.76, 0.50, 0.28},  -- brick tan
    [3] = {0.32, 0.55, 0.75},  -- blue stone
    [4] = {0.72, 0.32, 0.32},  -- red stone
    [5] = {0.38, 0.68, 0.38},  -- mossy green
    [6] = {0.78, 0.65, 0.18},  -- yellow gold
}

-- �� state �����������������������������������������������������
local rc
local view_canvas
local px, py = 1.5, 1.5   -- player world position
local pa = 0.0             -- player angle

-- Textures: one image per wall type + floor + ceiling
local wall_textures = {}   -- wall_textures[1..6]
local floor_texture        -- floor image
local ceil_texture         -- ceiling image
-- Shared quads: since all textures are TEX_W�TEX_H, one set of quads suffices
local shared_quads = {}    -- shared_quads[0..TEX_W-1]

-- Weather
local weather    = "none"
local particles  = {}
local P_COUNT    = 60

-- Items
local items = {}
local score = 0
local msg_timer = 0.0

-- �� texture generators ����������������������������������������
-- All textures are greyscale (brightness only), setColor applies the tint.

local function noise2(px_, py_)
    return ((px_ * 37 + py_ * 53 + px_ * py_ * 3) % 29) / 29
end

-- Pattern 1: brick � horizontal mortar lines + offset vertical joints
local function makeBrickTex(bH, bW)
    local d = lurek.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        local row   = math.floor(py_ / bH)
        local off   = (row % 2 == 0) and 0 or math.floor(bW / 2)
        local my    = (py_ % bH == 0) or (py_ % bH == bH - 1)
        for px_ = 0, TEX_W - 1 do
            local mx = ((px_ + off) % bW == 0)
            local n  = noise2(px_, py_)
            local v
            if my or mx then
                v = math.floor(100 + n * 20)   -- mortar: dark grey
            else
                v = math.floor(200 + n * 40)   -- brick face: bright
            end
            v = math.max(0, math.min(255, v))
            d:setPixel(px_, py_, v, v, v, 255)
        end
    end
    return lurek.gfx.newImage(d)
end

-- Pattern 2: large stone blocks
local function makeStoneTex(bH, bW)
    local d = lurek.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        local row = math.floor(py_ / bH)
        local off = (row % 2 == 0) and 0 or math.floor(bW / 2)
        local gy  = py_ % bH
        for px_ = 0, TEX_W - 1 do
            local gx = (px_ + off) % bW
            local n  = noise2(px_, py_)
            -- Grout lines (edges)
            local in_grout = (gy < 2) or (gy > bH - 3) or (gx < 2) or (gx > bW - 3)
            -- Random surface dents
            local dent = noise2(px_ * 3, py_ * 3) > 0.8
            local v
            if in_grout then
                v = 85 + math.floor(n * 20)
            elseif dent then
                v = 150 + math.floor(n * 30)
            else
                v = 185 + math.floor(n * 45)
            end
            v = math.max(0, math.min(255, v))
            d:setPixel(px_, py_, v, v, v, 255)
        end
    end
    return lurek.gfx.newImage(d)
end

-- Pattern 3: rough cracked stone
local function makeCrackedTex()
    local d = lurek.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        for px_ = 0, TEX_W - 1 do
            local n1 = noise2(px_,       py_)
            local n2 = noise2(px_ + 100, py_ + 100)
            local n3 = noise2(px_ * 2,   py_ * 2)
            -- Cracks: dark lines where both noise vals are small
            local crack = (n1 * n2 < 0.04)
            local v
            if crack then
                v = 70 + math.floor(n3 * 30)   -- crack: dark
            else
                v = 170 + math.floor((n1 + n2) * 35) -- surface
            end
            v = math.max(0, math.min(255, v))
            d:setPixel(px_, py_, v, v, v, 255)
        end
    end
    return lurek.gfx.newImage(d)
end

-- Pattern 4: mossy surface (dark with lighter patches)
local function makeMossyTex()
    local d = lurek.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        for px_ = 0, TEX_W - 1 do
            local n1 = noise2(px_,     py_)
            local n2 = noise2(px_ + 7, py_ + 13)
            local n3 = noise2(px_ * 3, py_ * 5)
            -- Mossy patches
            local m = (n1 + n2) / 2
            local v = math.floor(120 + m * 80 + n3 * 30)
            -- Occasional dark spots (holes in moss)
            if n3 > 0.85 then v = v - 60 end
            v = math.max(0, math.min(255, v))
            d:setPixel(px_, py_, v, v, v, 255)
        end
    end
    return lurek.gfx.newImage(d)
end

-- Floor texture: stone tiles with grout lines
local function makeFloorTex()
    local TILE = 16
    local d = lurek.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        for px_ = 0, TEX_W - 1 do
            local tx = px_ % TILE
            local ty = py_ % TILE
            local n  = noise2(math.floor(px_/TILE)*7, math.floor(py_/TILE)*11)
            local grout = (tx == 0) or (ty == 0)
            local v
            if grout then
                v = 55
            else
                v = 120 + math.floor(n * 50) + math.floor(noise2(px_,py_) * 20)
            end
            v = math.max(0, math.min(255, v))
            d:setPixel(px_, py_, v, v, v, 255)
        end
    end
    return lurek.gfx.newImage(d)
end

-- Ceiling texture: rough dark stone
local function makeCeilTex()
    local d = lurek.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        for px_ = 0, TEX_W - 1 do
            local n1 = noise2(px_, py_)
            local n2 = noise2(px_ + 50, py_ + 50)
            local stalactite = (n1 * noise2(px_ * 2, py_ * 4)) > 0.6
            local v = stalactite
                       and math.floor(40 + n2 * 30)
                       or  math.floor(90 + (n1 + n2) * 30)
            v = math.max(0, math.min(255, v))
            d:setPixel(px_, py_, v, v, v, 255)
        end
    end
    return lurek.gfx.newImage(d)
end

-- �� helpers ���������������������������������������������������
local function cellAt(x, y)
    local gx = math.floor(x)
    local gy = math.floor(y)
    if gx < 1 or gy < 1 or gx > MAP_W or gy > MAP_H then return 1 end
    return MAP[(gy - 1) * MAP_W + gx]
end

local function passable(v) return v == 0 end

local function initParticles()
    particles = {}
    for _ = 1, P_COUNT do
        particles[#particles + 1] = {
            x   = math.random(0, RW),
            y   = math.random(0, RH),
            vy  = math.random(60, 130),
            vx  = (weather == "snow") and math.random(-20, 20) or 0,
            len = (weather == "rain") and math.random(4, 10) or 2,
        }
    end
end

-- �� load ������������������������������������������������������
function lurek.init()
    lurek.window.setTitle("Raycaster FPS")
    lurek.gfx.setBackgroundColor(0.02, 0.02, 0.04)

    -- Build raycaster grid (items are open cells here)
    rc = lurek.raycaster.new(MAP_W, MAP_H)
    rc:setCells(MAP)

    -- Extract item positions
    for _, pos in ipairs(ITEM_CELLS) do
        items[#items + 1] = {
            x = pos[1] + 0.5, y = pos[2] + 0.5, collected = false
        }
    end

    -- Generate textures
    wall_textures[1] = makeStoneTex(10, 20)  -- stone: tall blocks
    wall_textures[2] = makeBrickTex(8, 16)   -- brick: standard
    wall_textures[3] = makeStoneTex(14, 12)  -- blue stone: narrower blocks
    wall_textures[4] = makeCrackedTex()       -- red: cracked
    wall_textures[5] = makeMossyTex()         -- mossy
    wall_textures[6] = makeBrickTex(10, 12)  -- gold: wide bricks
    floor_texture    = makeFloorTex()
    ceil_texture     = makeCeilTex()

    -- Build shared quads (one per texture column 0..TEX_W-1)
    for s = 0, TEX_W - 1 do
        shared_quads[s] = lurek.gfx.newQuad(s, 0, 1, TEX_H, TEX_W, TEX_H)
    end

    -- Low-res render canvas
    view_canvas = lurek.gfx.newCanvas(RW, RH)

    -- Default weather
    weather = "rain"
    initParticles()

    px, py = 1.5, 1.5
    pa = 0.0
end

-- �� update ����������������������������������������������������
function lurek.process(dt)
    -- Movement
    local dx, dy = 0, 0
    if lurek.keyboard.isDown("w") then
        dx = dx + math.cos(pa) * MOVE_SPEED * dt
        dy = dy + math.sin(pa) * MOVE_SPEED * dt
    end
    if lurek.keyboard.isDown("s") then
        dx = dx - math.cos(pa) * MOVE_SPEED * dt
        dy = dy - math.sin(pa) * MOVE_SPEED * dt
    end
    if lurek.keyboard.isDown("a") then
        dx = dx + math.cos(pa - math.pi / 2) * MOVE_SPEED * dt
        dy = dy + math.sin(pa - math.pi / 2) * MOVE_SPEED * dt
    end
    if lurek.keyboard.isDown("d") then
        dx = dx + math.cos(pa + math.pi / 2) * MOVE_SPEED * dt
        dy = dy + math.sin(pa + math.pi / 2) * MOVE_SPEED * dt
    end
    -- Collision slide
    if passable(cellAt(px + dx + 0.25, py)) and passable(cellAt(px + dx - 0.25, py)) then
        px = px + dx
    end
    if passable(cellAt(px, py + dy + 0.25)) and passable(cellAt(px, py - dy - 0.25)) then
        py = py + dy
    end
    -- Rotation
    if lurek.keyboard.isDown("q") then pa = pa - ROT_SPEED * dt end
    if lurek.keyboard.isDown("e") then pa = pa + ROT_SPEED * dt end

    -- Item pickup
    for _, it in ipairs(items) do
        if not it.collected then
            local d2 = (px - it.x)^2 + (py - it.y)^2
            if d2 < 0.5 * 0.5 then
                it.collected = true
                score = score + 100
                msg_timer = 2.0
            end
        end
    end
    if msg_timer > 0 then msg_timer = msg_timer - dt end

    -- Weather particles
    if weather ~= "none" then
        for _, p in ipairs(particles) do
            p.y = p.y + p.vy * dt
            p.x = p.x + (p.vx or 0) * dt
            if p.y > RH + p.len then
                p.y = -p.len
                p.x = math.random(0, RW)
            end
            if p.x < 0  then p.x = RW end
            if p.x > RW then p.x = 0  end
        end
    end
end

-- �� draw ������������������������������������������������������
function lurek.render()
    lurek.gfx.setCanvas(view_canvas)

    -- �� Ceiling bands (horizon�top: lighter�darker) ������������
    local half_h = math.floor(RH / 2)
    local band_h = math.max(1, math.ceil(half_h / NBANDS))
    for b = 0, NBANDS - 1 do
        local t  = b / NBANDS              -- 0=top, 1=horizon
        local br = 0.035 + t * 0.055       -- top=dark, horizon=lighter
        local strip_y = b * band_h
        -- Sample ceiling texture column (repeating tile effect per band)
        local tex_row = math.floor(t * (TEX_H - 1))
        local tv = noise2(b * 3, 0) * 0.025
        lurek.gfx.setColor(br + tv, br + tv, br * 1.1 + tv)
        lurek.gfx.rectangle("fill", 0, strip_y, RW, band_h + 1)
    end

    -- �� Floor bands (horizon�bottom: darker�lighter) �����������
    for b = 0, NBANDS - 1 do
        local t  = b / NBANDS               -- 0=horizon, 1=bottom
        local br = 0.05 + t * 0.15          -- darker at horizon, lighter near player
        local checker = (b % 2 == 0) and 1.0 or 0.88    -- checkerboard illusion
        local strip_y = half_h + b * band_h
        lurek.gfx.setColor(br * 0.95 * checker, br * 0.85 * checker, br * 0.68 * checker)
        lurek.gfx.rectangle("fill", 0, strip_y, RW, band_h + 1)
    end

    -- �� Cast all rays ������������������������������������������
    local rays  = rc:castRaysFlat(px, py, pa, FOV, RW, MAX_DIST)
    local depth = {}   -- depth buffer for sprite occlusion

    for col = 1, RW do
        local base      = (col - 1) * 5 + 1
        local dist      = rays[base]
        local cv        = math.floor(rays[base + 2])
        local side      = rays[base + 3]
        local tex_u     = rays[base + 4]

        depth[col] = dist

        if dist < MAX_DIST and cv > 0 then
            local wall_h, draw_start =
                lurek.raycaster.projectColumn(dist, FOV, RH)

            -- Distance fog brightness
            local bright = lurek.raycaster.distanceShade(dist, MAX_DIST)
            -- Side walls darker (simulates directional light)
            if side == 1 then bright = bright * 0.65 end

            -- Wall color tint
            local wt = WALL_TINT[cv] or {0.55, 0.55, 0.55}

            lurek.gfx.setColor(
                wt[1] * bright,
                wt[2] * bright,
                wt[3] * bright
            )

            -- Texture strip: map tex_u [0,1] to column [0,TEX_W-1]
            local strip = math.max(0, math.min(TEX_W - 1, math.floor(tex_u * TEX_W)))
            local q     = shared_quads[strip]
            local tex   = wall_textures[cv] or wall_textures[1]
            local wy    = wall_h / TEX_H    -- vertical scale

            lurek.gfx.drawq(tex, q, col - 1, math.floor(draw_start), 0, 1, wy)
        end
    end

    -- �� Billboard item sprites ���������������������������������
    for _, it in ipairs(items) do
        if not it.collected then
            local proj = rc:projectSprite(it.x, it.y, px, py, pa, FOV, RW)
            if proj and proj.visible then
                local col = math.floor(proj.screen_x)
                local sz  = math.floor(proj.scale * RH * 0.45)
                if sz > 1 and depth[col] and proj.distance < depth[col] then
                    local bd = lurek.raycaster.distanceShade(proj.distance, MAX_DIST)
                    local sy = math.floor(RH / 2 - sz / 2)
                    -- Gold orb body
                    lurek.gfx.setColor(1.0 * bd, 0.82 * bd, 0.08 * bd)
                    lurek.gfx.rectangle("fill", col - math.floor(sz/2), sy, sz, sz)
                    -- Orb highlight
                    lurek.gfx.setColor(1.0, 1.0, 0.6, 0.7)
                    local hi = math.max(1, math.floor(sz * 0.25))
                    lurek.gfx.rectangle("fill",
                        col - math.floor(sz/2) + hi, sy + hi, hi * 2, hi * 2)
                end
            end
        end
    end

    -- �� Weather overlay ����������������������������������������
    if weather == "rain" then
        lurek.gfx.setColor(0.55, 0.70, 0.90, 0.50)
        for _, p in ipairs(particles) do
            lurek.gfx.rectangle("fill", math.floor(p.x), math.floor(p.y),
                               1, math.floor(p.len))
        end
    elseif weather == "snow" then
        lurek.gfx.setColor(0.95, 0.97, 1.0, 0.75)
        for _, p in ipairs(particles) do
            lurek.gfx.rectangle("fill", math.floor(p.x), math.floor(p.y), 2, 2)
        end
    end

    -- �� Fog vignette (darkens screen edges) �������������������
    lurek.gfx.setColor(0, 0, 0, 0.40)
    lurek.gfx.rectangle("fill", 0,        0,   RW, RH / 6)
    lurek.gfx.rectangle("fill", 0, RH * 5/6,   RW, RH / 6)

    lurek.gfx.setCanvas(nil)
    lurek.gfx.setColor(1, 1, 1, 1)

    -- Upscale low-res canvas to full window
    lurek.gfx.draw(view_canvas, 0, 0, 0, SW / RW, SH / RH)

    -- �� HUD ���������������������������������������������������
    lurek.gfx.setColor(0.9, 0.9, 0.9)
    lurek.gfx.print("Score: " .. score, 12, 12)
    lurek.gfx.print("Weather [" .. weather .. "]  F1=none  F2=rain  F3=snow", 12, 32)
    lurek.gfx.print("WASD move   Q/E rotate   Escape quit", 12, 52)

    if msg_timer > 0 then
        lurek.gfx.setColor(1.0, 0.85, 0.1)
        lurek.gfx.print("+ 100  ITEM COLLECTED!", SW / 2 - 90, SH / 2 - 20)
    end
end

-- �� keypressed ������������������������������������������������
function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "f1" then weather = "none";  particles = {} end
    if key == "f2" then weather = "rain";  initParticles() end
    if key == "f3" then weather = "snow";  initParticles() end
end