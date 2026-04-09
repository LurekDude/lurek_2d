-- demos/retro/dungeon_crawler/main.lua
-- Dungeon Crawler — Eye of Beholder / Dungeon Master grid-step dungeon with
--   procedurally textured walls (4 types), floor/ceiling, smooth lerp turns,
--   flickering torches, weather modes, collectible orbs, minimap
-- Controls: W/S forward/back, Q/E turn left/right (90°), F1/F2/F3 weather
-- Run with: cargo run -- demos/retro/dungeon_crawler

-- ── constants ─────────────────────────────────────────────────
local SW, SH       = 800, 600
local VW, VH       = 320, 240        -- 3D viewport (left panel)
local FOV          = math.pi / 2     -- 90° classic dungeon FOV
local MAX_DIST     = 8.0
local LERP_SPEED   = 9.0
local MAP_W, MAP_H = 12, 12
local TEX_W, TEX_H = 64, 64
local NBANDS       = 12              -- floor/ceiling bands

-- ── dungeon map ────────────────────────────────────────────────
-- 0=open 1=stone 2=brick 3=mossy 4=magic
local DMAP = {
    1,1,1,1,1,1,1,1,1,1,1,1,
    1,0,0,0,1,0,0,0,0,0,0,1,
    1,0,2,0,1,0,2,2,2,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,1,
    1,1,0,1,1,1,1,0,1,1,1,1,
    1,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,3,0,0,3,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,1,
    1,0,1,1,1,0,0,1,1,1,0,1,
    1,0,0,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,0,0,0,0,1,
    1,1,1,1,1,1,1,1,1,1,1,1,
}

-- Spawn positions for torches and items (grid coords)
local TORCH_CELLS = { {2,2}, {10,2}, {2,6}, {10,6}, {5,9}, {8,9} }
local ITEM_CELLS  = { {5,5}, {8,5}, {5,9}, {8,9} }

-- ── facing tables ─────────────────────────────────────────────
-- East=1 (angle 0), South=2 (angle π/2), West=3 (angle π), North=4 (angle 3π/2)
local FACE_DX    = { 1,  0, -1,  0 }
local FACE_DY    = { 0,  1,  0, -1 }
local FACE_NAME  = { "East", "South", "West", "North" }

-- ── player state ──────────────────────────────────────────────
local gx, gy      = 2, 2
local facing      = 1           -- 1=E 2=S 3=W 4=N
local turn_acc    = 0           -- accumulated quarter-turns (never normalized)
local target_angle = 0.0        -- turn_acc × π/2
local visual_angle = 0.0        -- lerped render angle
local vis_x, vis_y = 2.5, 2.5  -- lerped world-space position

-- Settled: both position and angle have converged
local settled = true

-- ── world objects ──────────────────────────────────────────────
local torches = {}              -- {x, y} world-space centers
local items   = {}              -- {gx, gy, wx, wy, collected}
local score   = 0

-- ── environment ───────────────────────────────────────────────
local env_mode     = "normal"   -- "normal", "wind", "rain"
local flicker_t    = 0.0
local FLICKER_RATE = 0.10

-- ── engine objects ─────────────────────────────────────────────
local rc
local view_canvas

-- Textures + shared quads
local wall_textures = {}
local shared_quads  = {}

-- Wall tints (greyscale textures, setColor applies tint)
local WALL_TINT = {
    [1] = {0.58, 0.56, 0.53},   -- stone
    [2] = {0.74, 0.50, 0.28},   -- brick
    [3] = {0.40, 0.62, 0.38},   -- mossy
    [4] = {0.42, 0.38, 0.80},   -- magic/blue
}

-- ── HUD log ───────────────────────────────────────────────────
local log_lines = {}
local function logAdd(s)
    table.insert(log_lines, 1, s)
    if #log_lines > 7 then log_lines[8] = nil end
end

-- ── texture generators ────────────────────────────────────────
local function noise2(px_, py_)
    return ((px_ * 37 + py_ * 53 + px_ * py_ * 3) % 29) / 29
end

local function makeBrickTex(bH, bW)
    local d = luna.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        local row = math.floor(py_ / bH)
        local off = (row % 2 == 0) and 0 or math.floor(bW / 2)
        local my  = (py_ % bH == 0) or (py_ % bH == bH - 1)
        for px_ = 0, TEX_W - 1 do
            local mx = ((px_ + off) % bW == 0)
            local n  = noise2(px_, py_)
            local v  = (my or mx) and math.floor(90 + n * 20)
                                   or  math.floor(195 + n * 45)
            d:setPixel(px_, py_, math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), 255)
        end
    end
    return luna.gfx.newImage(d)
end

local function makeStoneTex(bH, bW)
    local d = luna.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        local row = math.floor(py_ / bH)
        local off = (row % 2 == 0) and 0 or math.floor(bW / 2)
        local gy_ = py_ % bH
        for px_ = 0, TEX_W - 1 do
            local gx_ = (px_ + off) % bW
            local n   = noise2(px_, py_)
            local grout = (gy_ < 2) or (gy_ > bH - 3) or (gx_ < 2) or (gx_ > bW - 3)
            local dent  = noise2(px_*3, py_*3) > 0.82
            local v = grout and math.floor(80 + n * 20)
                      or dent and math.floor(145 + n * 30)
                      or            math.floor(185 + n * 50)
            d:setPixel(px_, py_, math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), 255)
        end
    end
    return luna.gfx.newImage(d)
end

local function makeMossyTex()
    local d = luna.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        for px_ = 0, TEX_W - 1 do
            local n1 = noise2(px_, py_)
            local n2 = noise2(px_ + 7, py_ + 13)
            local n3 = noise2(px_ * 3, py_ * 5)
            local m  = (n1 + n2) / 2
            local v  = math.floor(115 + m * 85 + n3 * 30)
            if n3 > 0.87 then v = v - 55 end
            d:setPixel(px_, py_, math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), 255)
        end
    end
    return luna.gfx.newImage(d)
end

local function makeMagicTex()
    local d = luna.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        for px_ = 0, TEX_W - 1 do
            local n1 = noise2(px_, py_)
            local n2 = noise2(px_ + 30, py_ + 20)
            -- Glowing rune-like pattern
            local rune = (math.floor(px_ / 8) + math.floor(py_ / 8)) % 2 == 0
            local v = rune and math.floor(200 + n1 * 50)
                            or math.floor(100 + n2 * 60)
            d:setPixel(px_, py_, math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), 255)
        end
    end
    return luna.gfx.newImage(d)
end

local function makeFloorTex()
    local TILE = 16
    local d = luna.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        for px_ = 0, TEX_W - 1 do
            local tx = px_ % TILE
            local ty = py_ % TILE
            local n  = noise2(math.floor(px_/TILE)*7, math.floor(py_/TILE)*11)
            local grout = (tx == 0) or (ty == 0)
            local v = grout and 55 or math.floor(115 + n * 55 + noise2(px_,py_) * 20)
            d:setPixel(px_, py_, math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), 255)
        end
    end
    return luna.gfx.newImage(d)
end

local function makeCeilTex()
    local d = luna.img.newImageData(TEX_W, TEX_H)
    for py_ = 0, TEX_H - 1 do
        for px_ = 0, TEX_W - 1 do
            local n1 = noise2(px_, py_)
            local n2 = noise2(px_ + 50, py_ + 50)
            local stala = (n1 * noise2(px_*2, py_*4)) > 0.6
            local v = stala and math.floor(30 + n2*25) or math.floor(80 + (n1+n2)*28)
            d:setPixel(px_, py_, math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), math.max(0,math.min(255,v)), 255)
        end
    end
    return luna.gfx.newImage(d)
end

-- ── helpers ───────────────────────────────────────────────────
local function mapCell(cx, cy)
    if cx < 1 or cy < 1 or cx > MAP_W or cy > MAP_H then return 1 end
    return DMAP[(cy - 1) * MAP_W + cx]
end

local function passable(v) return v == 0 end

local function lerp(a, b, t_)
    return a + (b - a) * t_
end

-- ── settlement check ──────────────────────────────────────────
local function isSettled()
    return settled
end

-- ── movement actions (snapped to grid) ────────────────────────
local function tryMove(fwd)
    if not isSettled() then return end
    local dx = FACE_DX[facing] * (fwd and 1 or -1)
    local dy = FACE_DY[facing] * (fwd and 1 or -1)
    local nx, ny = gx + dx, gy + dy
    if passable(mapCell(nx, ny)) then
        gx, gy = nx, ny
    end
end

local function turnRight()
    if not isSettled() then return end
    turn_acc      = turn_acc + 1
    target_angle  = turn_acc * (math.pi / 2)
    facing        = facing % 4 + 1
    settled       = false
end

local function turnLeft()
    if not isSettled() then return end
    turn_acc      = turn_acc - 1
    target_angle  = turn_acc * (math.pi / 2)
    facing        = (facing - 2 + 4) % 4 + 1
    settled       = false
end

-- ── load ──────────────────────────────────────────────────────
function luna.init()
    luna.window.setTitle("Dungeon Crawler")
    luna.gfx.setBackgroundColor(0.02, 0.02, 0.04)

    -- Build raycaster
    rc = luna.raycaster.new(MAP_W, MAP_H)
    rc:setCells(DMAP)

    -- Spawn torches
    for _, pos in ipairs(TORCH_CELLS) do
        torches[#torches + 1] = { x = pos[1] + 0.5, y = pos[2] + 0.5 }
    end

    -- Spawn items
    for _, pos in ipairs(ITEM_CELLS) do
        items[#items + 1] = {
            gx = pos[1], gy = pos[2],
            x  = pos[1] + 0.5, y = pos[2] + 0.5,
            collected = false
        }
    end

    -- Generate textures
    wall_textures[1] = makeStoneTex(10, 20)
    wall_textures[2] = makeBrickTex(8,  16)
    wall_textures[3] = makeMossyTex()
    wall_textures[4] = makeMagicTex()
    wall_textures.floor   = makeFloorTex()
    wall_textures.ceiling = makeCeilTex()

    -- Build shared quads
    for s = 0, TEX_W - 1 do
        shared_quads[s] = luna.gfx.newQuad(s, 0, 1, TEX_H, TEX_W, TEX_H)
    end

    view_canvas = luna.gfx.newCanvas(VW, VH)
    vis_x = gx + 0.5
    vis_y = gy + 0.5
    visual_angle = 0.0

    logAdd("You enter the dungeon...")
    logAdd("Find the four glowing orbs.")
end

-- ── update ────────────────────────────────────────────────────
function luna.process(dt)
    -- Smooth lerp
    local t_ = math.min(1.0, LERP_SPEED * dt)
    local tgx = gx + 0.5
    local tgy = gy + 0.5

    vis_x = lerp(vis_x, tgx, t_)
    vis_y = lerp(vis_y, tgy, t_)
    visual_angle = lerp(visual_angle, target_angle, t_)

    -- Check settled
    local pos_ok   = math.abs(vis_x - tgx) < 0.006 and
                     math.abs(vis_y - tgy) < 0.006
    local angle_ok = math.abs(visual_angle - target_angle) < 0.006
    settled = pos_ok and angle_ok

    if settled then
        vis_x = tgx; vis_y = tgy
        visual_angle = target_angle
    end

    -- Torch flicker timer
    flicker_t = flicker_t + dt
    if flicker_t > 1000 then flicker_t = 0 end

    -- Item pickup
    for _, it in ipairs(items) do
        if not it.collected and it.gx == gx and it.gy == gy then
            it.collected = true
            score = score + 200
            logAdd("You found a magic orb! +" .. 200)
        end
    end
end

-- ── draw ──────────────────────────────────────────────────────
function luna.render()
    luna.gfx.setCanvas(view_canvas)

    -- ── Ceiling bands ─────────────────────────────────────────
    local ceil_h  = math.floor(VH / 2)
    local band_px = math.max(1, math.ceil(ceil_h / NBANDS))
    for b = 0, NBANDS - 1 do
        local t_ = b / NBANDS        -- 0=top 1=horizon
        local br = 0.03 + t_ * 0.05
        local nv = noise2(b * 5, 0) * 0.015
        luna.gfx.setColor(br + nv, br + nv, br * 1.1 + nv)
        luna.gfx.rectangle("fill", 0, b * band_px, VW, band_px + 1)
    end

    -- ── Floor bands ───────────────────────────────────────────
    for b = 0, NBANDS - 1 do
        local t_ = b / NBANDS        -- 0=horizon 1=bottom
        local br = 0.04 + t_ * 0.14
        local checker = (b % 2 == 0) and 1.0 or 0.88
        luna.gfx.setColor(
            br * 0.92 * checker,
            br * 0.82 * checker,
            br * 0.66 * checker
        )
        luna.gfx.rectangle("fill", 0, ceil_h + b * band_px, VW, band_px + 1)
    end

    -- ── Cast rays ─────────────────────────────────────────────
    local rays  = rc:castRaysFlat(vis_x, vis_y, visual_angle, FOV, VW, MAX_DIST)
    local depth = {}

    for col = 1, VW do
        local base  = (col - 1) * 5 + 1
        local dist  = rays[base]
        local cv    = math.floor(rays[base + 2])
        local side  = rays[base + 3]
        local tex_u = rays[base + 4]

        depth[col] = dist

        if dist < MAX_DIST and cv > 0 then
            local wall_h, draw_start =
                luna.raycaster.projectColumn(dist, FOV, VH)

            local bright = luna.raycaster.distanceShade(dist, MAX_DIST)
            if side == 1 then bright = bright * 0.68 end

            -- Add torch light from nearby torches
            local torch_add = 0.0
            for _, torch in ipairs(torches) do
                local ray_a = visual_angle + (col / VW - 0.5) * FOV
                local hx = vis_x + math.cos(ray_a) * dist
                local hy = vis_y + math.sin(ray_a) * dist
                local td2 = (hx - torch.x)^2 + (hy - torch.y)^2
                if td2 < 12.0 then
                    local flk = 1.0
                    if env_mode ~= "normal" then
                        local rate = (env_mode == "wind") and 35 or 22
                        flk = 0.72 + 0.28 * math.sin(flicker_t * rate + torch.x * 6.5)
                    end
                    torch_add = torch_add + (1.0 / (1.0 + td2 * 0.55)) * flk
                end
            end
            torch_add = math.min(0.60, torch_add)

            local wt = WALL_TINT[cv] or {0.55, 0.55, 0.55}
            luna.gfx.setColor(
                math.min(1.0, wt[1] * bright + torch_add * 0.90),
                math.min(1.0, wt[2] * bright + torch_add * 0.48),
                math.min(1.0, wt[3] * bright + torch_add * 0.08)
            )

            local strip = math.max(0, math.min(TEX_W-1, math.floor(tex_u * TEX_W)))
            local q     = shared_quads[strip]
            local tex   = wall_textures[cv] or wall_textures[1]
            luna.gfx.drawq(tex, q, col - 1, math.floor(draw_start), 0, 1, wall_h / TEX_H)
        end
    end

    -- ── Torch sprites ─────────────────────────────────────────
    for _, torch in ipairs(torches) do
        local proj = rc:projectSprite(torch.x, torch.y, vis_x, vis_y,
                                       visual_angle, FOV, VW)
        if proj and proj.visible and depth[math.floor(proj.screen_x)] then
            local col = math.floor(proj.screen_x)
            if proj.distance < depth[col] then
                local sz  = math.max(2, math.floor(proj.scale * VH * 0.12))
                local sx  = col - math.floor(sz/2)
                local sy  = math.floor(VH/2 - sz * 1.4)
                local bd  = luna.raycaster.distanceShade(proj.distance, MAX_DIST)
                local flk = 1.0
                if env_mode ~= "normal" then
                    local rate = (env_mode == "wind") and 38 or 24
                    flk = 0.68 + 0.32 * math.sin(flicker_t * rate + torch.x * 5.3)
                end
                luna.gfx.setColor(1.0*bd*flk, 0.52*bd*flk, 0.04*bd)
                luna.gfx.rectangle("fill", sx, sy, sz, math.floor(sz * 1.6))
                -- Glow halo
                luna.gfx.setColor(1.0*bd*flk, 0.40*bd*flk, 0.02, 0.35)
                local halo = math.floor(sz * 2.2)
                luna.gfx.rectangle("fill", col - math.floor(halo/2),
                    sy - math.floor(sz*0.3), halo, math.floor(sz*2))
            end
        end
    end

    -- ── Item orb sprites ──────────────────────────────────────
    for _, it in ipairs(items) do
        if not it.collected then
            local proj = rc:projectSprite(it.x, it.y, vis_x, vis_y,
                                           visual_angle, FOV, VW)
            if proj and proj.visible and depth[math.floor(proj.screen_x)] then
                local col = math.floor(proj.screen_x)
                if proj.distance < depth[col] then
                    local sz = math.max(3, math.floor(proj.scale * VH * 0.30))
                    local sx = col - math.floor(sz/2)
                    local sy = math.floor(VH/2 - sz/2)
                    local bd = luna.raycaster.distanceShade(proj.distance, MAX_DIST)
                    -- Pulsing cyan orb
                    local pulse = 0.8 + 0.2 * math.sin(flicker_t * 3.5 + it.x)
                    luna.gfx.setColor(0.5*bd*pulse, 0.92*bd*pulse, 1.0*bd*pulse)
                    luna.gfx.rectangle("fill", sx, sy, sz, sz)
                    luna.gfx.setColor(0.85*pulse, 1.0*pulse, 1.0*pulse, 0.75)
                    local hi = math.max(1, math.floor(sz*0.22))
                    luna.gfx.rectangle("fill", sx+hi, sy+hi, hi*2, hi*2)
                end
            end
        end
    end

    -- ── Rain drips ────────────────────────────────────────────
    if env_mode == "rain" then
        luna.gfx.setColor(0.50, 0.62, 0.85, 0.30)
        for i = 1, 18 do
            local rx = (i * 19 + math.floor(flicker_t * 60)) % VW
            local ry = (i * 31 + math.floor(flicker_t * 90)) % VH
            luna.gfx.rectangle("fill", rx, ry, 1, 5)
        end
    end

    -- ── Edge fog ──────────────────────────────────────────────
    luna.gfx.setColor(0, 0, 0, 0.30)
    luna.gfx.rectangle("fill", 0, 0,      VW, VH / 7)
    luna.gfx.rectangle("fill", 0, VH*6/7, VW, VH / 7)

    luna.gfx.setCanvas(nil)
    luna.gfx.setColor(1, 1, 1, 1)

    -- Blit 3D view to left 60% of screen
    local scx = (SW * 0.60) / VW
    local scy = SH / VH
    luna.gfx.draw(view_canvas, 0, 0, 0, scx, scy)

    -- ── Right panel HUD ───────────────────────────────────────
    local hx = math.floor(SW * 0.61)

    luna.gfx.setColor(0.10, 0.09, 0.12)
    luna.gfx.rectangle("fill", hx, 0, SW - hx, SH)

    luna.gfx.setColor(0.85, 0.75, 0.48)
    luna.gfx.print("=== DUNGEON ===", hx + 6, 14)
    luna.gfx.setColor(0.80, 0.80, 0.80)
    luna.gfx.print("Facing : " .. FACE_NAME[facing],  hx + 6, 40)
    luna.gfx.print("Pos    : " .. gx .. ", " .. gy,   hx + 6, 58)
    luna.gfx.print("Score  : " .. score,               hx + 6, 76)
    luna.gfx.print("Env    : " .. env_mode,            hx + 6, 94)

    -- Minimap
    local mm_x  = hx + 6
    local mm_y  = 118
    local mc    = 13   -- cell pixel size
    for cy = 1, MAP_H do
        for cx = 1, MAP_W do
            local v = mapCell(cx, cy)
            if v > 0 then
                luna.gfx.setColor(0.38, 0.36, 0.34)
            else
                luna.gfx.setColor(0.13, 0.12, 0.14)
            end
            luna.gfx.rectangle("fill",
                mm_x + (cx-1)*mc, mm_y + (cy-1)*mc, mc-1, mc-1)
        end
    end
    -- Player marker
    luna.gfx.setColor(0.95, 0.78, 0.20)
    luna.gfx.rectangle("fill",
        mm_x + (gx-1)*mc + 3, mm_y + (gy-1)*mc + 3, mc-5, mc-5)

    -- Log
    local log_y = mm_y + MAP_H * mc + 10
    luna.gfx.setColor(0.52, 0.72, 0.52)
    luna.gfx.print("── Events ──", mm_x, log_y)
    luna.gfx.setColor(0.70, 0.82, 0.70)
    for i, line in ipairs(log_lines) do
        luna.gfx.print(line, mm_x, log_y + i * 19)
    end

    -- Controls
    luna.gfx.setColor(0.42, 0.42, 0.42)
    luna.gfx.print("W/S move  Q/E turn", mm_x, SH - 40)
    luna.gfx.print("F1 clear F2 wind F3 rain", mm_x, SH - 22)
end

-- ── keypressed ────────────────────────────────────────────────
function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "w" then tryMove(true)  end
    if key == "s" then tryMove(false) end
    if key == "q" then turnLeft()     end
    if key == "e" then turnRight()    end
    if key == "f1" then env_mode = "normal"; logAdd("Torches burn steady.") end
    if key == "f2" then env_mode = "wind";   logAdd("Cold wind howls...") end
    if key == "f3" then env_mode = "rain";   logAdd("Rain drips down walls.") end
end
