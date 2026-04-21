-- ============================================================================
-- Dungeon Eye — Lurek2D
-- ============================================================================
-- Category : rpg
-- Source   : content/games/rpg/dungeon_eye/main.lua
-- Run with : cargo run -- content/games/rpg/dungeon_eye
-- ============================================================================
-- First-person dungeon crawler inspired by Eye of the Beholder (PC 1992).
-- Raycaster rendering, grid-based movement, items and inventory.
-- Controls: W/S move, A/D turn, Space/E interact, I inventory, Escape quit
-- ============================================================================

local item      = require("library.item")
local inventory = require("library.inventory")

local W, H = 800, 640
local VIEW_W, VIEW_H = 480, 360   -- raycaster viewport
local VIEW_X, VIEW_Y = 0, 0
local PANEL_X = VIEW_W             -- right panel X
local STATUS_Y = VIEW_H            -- bottom status strip Y

-- ── Dungeon map ───────────────────────────────────────────────────────────
-- 1=wall, 0=floor, 2=door, 3=item spawn, 4=enemy, 5=exit
local MAP = {
    "111111111111111",
    "100000000000001",
    "101110011001101",
    "100010010001001",
    "111010010001001",
    "100010000001001",
    "100011110011001",
    "100000000000001",
    "101110011001101",
    "100000000000001",
    "100011110001001",
    "100000000001001",
    "101110011001001",
    "100000000000051",
    "111111111111111",
}
local MAP_W = #MAP[1]
local MAP_H = #MAP

local function map_at(mx, my)
    if mx < 1 or mx > MAP_W or my < 1 or my > MAP_H then return 1 end
    local ch = MAP[my]:sub(mx, mx)
    return tonumber(ch) or 1
end
local function is_wall(mx, my)
    local t = map_at(mx, my)
    return t == 1
end

-- ── Player ────────────────────────────────────────────────────────────────
local player = {
    mx = 2, my = 2,         -- grid position
    dir = 0,                -- 0=N 1=E 2=S 3=W
    hp = 30, max_hp = 30,
    inv = nil,
    log = {},
}
local DIR_DX = { [0]=0,  [1]=1, [2]=0,  [3]=-1 }
local DIR_DY = { [0]=-1, [1]=0, [2]=1,  [3]=0  }
local DIR_NAME = { [0]="North", [1]="East", [2]="South", [3]="West" }

-- ── Enemies ───────────────────────────────────────────────────────────────
local enemies = {}
local function spawn_enemies()
    for ey = 1, MAP_H do
        for ex = 1, MAP_W do
            if map_at(ex, ey) == 4 then
                enemies[#enemies+1] = { mx=ex, my=ey, hp=8, max_hp=8, dead=false }
            end
        end
    end
end

-- Item spawn points (replaced by actual items after init)
local item_drops = {}

-- ── Raycaster setup ───────────────────────────────────────────────────────
local raycaster = nil
local rc_floor_key = nil

-- ── State ─────────────────────────────────────────────────────────────────
local STATE = { EXPLORE = 1, COMBAT = 2, INVENTORY = 3, DEAD = 4, WIN = 5 }
local state = STATE.EXPLORE
local combat_enemy = nil
local combat_msg   = ""
local combat_timer = 0
local show_inv     = false
local inv_cursor   = 1
local move_anim    = 0      -- brief animation timer for movement flash

-- ── Helpers ───────────────────────────────────────────────────────────────
local function push_log(msg)
    table.insert(player.log, 1, msg)
    if #player.log > 5 then table.remove(player.log) end
end

local function facing_tile()
    return player.mx + DIR_DX[player.dir], player.my + DIR_DY[player.dir]
end

-- ── Load ──────────────────────────────────────────────────────────────────
function lurek.load()
    lurek.window.setTitle("Dungeon Eye — Lurek2D")
    lurek.render.setBackgroundColor(0.03, 0.02, 0.06)

    -- Define item types
    item.clearTypes()
    item.defineType("health_potion", {
        category   = "consumable",
        base_stats = { heal = 12 },
        rarity     = "common",
    })
    item.defineType("torch", {
        category   = "misc",
        base_stats = { light = 5 },
        rarity     = "common",
    })
    item.defineType("sword", {
        category   = "weapon",
        base_stats = { attack = 6 },
        rarity     = "uncommon",
    })
    item.defineType("shield", {
        category   = "armor",
        base_stats = { defense = 4 },
        rarity     = "uncommon",
    })
    item.defineType("magic_key", {
        category   = "key",
        base_stats = {},
        rarity     = "rare",
    })

    -- Inventory
    player.inv = inventory.new(16)

    -- Seed inventory with a torch
    inventory.add(player.inv, item.create("torch"))

    -- Spawn item drops at '3' tiles
    local drop_types = { "health_potion", "sword", "shield", "health_potion" }
    local di = 1
    for ey = 1, MAP_H do
        for ex = 1, MAP_W do
            if map_at(ex, ey) == 3 then
                local dt = drop_types[di] or "health_potion"
                item_drops[#item_drops+1] = {
                    mx = ex, my = ey,
                    inst = item.create(dt),
                    collected = false,
                }
                di = di + 1
            end
        end
    end

    spawn_enemies()

    -- Raycaster (first-person view)
    raycaster = lurek.raycaster.new({
        map_width  = MAP_W,
        map_height = MAP_H,
        view_width  = VIEW_W,
        view_height = VIEW_H,
        fov         = 66,
    })
    -- Feed wall data
    for ry = 1, MAP_H do
        for rx = 1, MAP_W do
            raycaster:setCell(rx, ry, is_wall(rx, ry) and 1 or 0)
        end
    end

    push_log("You descend into the dungeon...")
    push_log("Find the exit and escape!")
end

-- ── Update ────────────────────────────────────────────────────────────────
function lurek.update(dt)
    if move_anim > 0 then move_anim = move_anim - dt end
    if combat_timer > 0 then
        combat_timer = combat_timer - dt
        if combat_timer <= 0 and state == STATE.COMBAT then
            state = STATE.EXPLORE
        end
    end
end

local function try_move(nx, ny)
    if is_wall(nx, ny) then
        push_log("Blocked.")
        return
    end
    -- Enemy on tile?
    for _, e in ipairs(enemies) do
        if not e.dead and e.mx == nx and e.my == ny then
            state = STATE.COMBAT
            combat_enemy = e
            -- Attack
            local dmg = 5 + math.random(3)
            e.hp = e.hp - dmg
            push_log(string.format("You hit for %d! Enemy HP: %d", dmg, math.max(0, e.hp)))
            if e.hp <= 0 then
                e.dead = true
                push_log("Enemy slain!")
                state = STATE.EXPLORE
                combat_enemy = nil
                -- small heal chance
                if math.random() < 0.3 then
                    inventory.add(player.inv, item.create("health_potion"))
                    push_log("Found a health potion!")
                end
            else
                -- Enemy counter-attack
                local edm = 2 + math.random(2)
                player.hp = math.max(0, player.hp - edm)
                push_log(string.format("Enemy hits you for %d! Your HP: %d", edm, player.hp))
                if player.hp == 0 then state = STATE.DEAD end
                combat_timer = 0.6
            end
            move_anim = 0.12
            return
        end
    end
    -- Items on tile?
    for _, d in ipairs(item_drops) do
        if not d.collected and d.mx == nx and d.my == ny then
            if inventory.add(player.inv, d.inst) then
                d.collected = true
                push_log("Picked up: " .. d.inst.type_id)
            else
                push_log("Inventory full!")
            end
        end
    end
    -- Exit?
    if map_at(nx, ny) == 5 then
        state = STATE.WIN
        push_log("You found the exit! VICTORY!")
        return
    end
    player.mx, player.my = nx, ny
    move_anim = 0.08
end

-- ── Draw ──────────────────────────────────────────────────────────────────
function lurek.draw()
    -- ── Raycaster viewport ──────────────────────────────────────────────
    local dir_angle_map = { [0]=math.pi*1.5, [1]=0, [2]=math.pi*0.5, [3]=math.pi }
    local view_angle = dir_angle_map[player.dir]

    raycaster:setCamera(player.mx - 0.5, player.my - 0.5, view_angle)
    raycaster:render()

    -- Floor
    lurek.render.setColor(0.18, 0.14, 0.10)
    lurek.render.rectangle("fill", VIEW_X, VIEW_Y + VIEW_H/2, VIEW_W, VIEW_H/2)
    -- Ceiling
    lurek.render.setColor(0.06, 0.06, 0.12)
    lurek.render.rectangle("fill", VIEW_X, VIEW_Y, VIEW_W, VIEW_H/2)

    -- Draw raycaster strips
    lurek.render.setColor(1, 1, 1)
    lurek.render.draw(raycaster, VIEW_X, VIEW_Y)

    -- Movement flash
    if move_anim > 0 then
        lurek.render.setColor(1, 1, 1, move_anim * 3)
        lurek.render.rectangle("fill", VIEW_X, VIEW_Y, VIEW_W, VIEW_H)
    end

    -- Minimap (top-right corner of view)
    local mm_scale = 8
    local mm_ox    = VIEW_W - MAP_W * mm_scale - 4
    local mm_oy    = 4
    for ry = 1, MAP_H do
        for rx = 1, MAP_W do
            local t = map_at(rx, ry)
            if t == 1 then
                lurek.render.setColor(0.6, 0.6, 0.6, 0.85)
            elseif t == 5 then
                lurek.render.setColor(0.1, 1, 0.4, 0.9)
            else
                lurek.render.setColor(0.12, 0.1, 0.08, 0.7)
            end
            lurek.render.rectangle("fill", mm_ox + (rx-1)*mm_scale, mm_oy + (ry-1)*mm_scale, mm_scale-1, mm_scale-1)
        end
    end
    -- Player dot
    lurek.render.setColor(1, 1, 0)
    lurek.render.circle("fill",
        mm_ox + (player.mx-0.5)*mm_scale,
        mm_oy + (player.my-0.5)*mm_scale, 3)
    -- Enemy dots
    for _, e in ipairs(enemies) do
        if not e.dead then
            lurek.render.setColor(1, 0.2, 0.2)
            lurek.render.circle("fill", mm_ox + (e.mx-0.5)*mm_scale, mm_oy + (e.my-0.5)*mm_scale, 2)
        end
    end

    -- ── Right panel ─────────────────────────────────────────────────────
    lurek.render.setColor(0.06, 0.04, 0.10)
    lurek.render.rectangle("fill", PANEL_X, 0, W - PANEL_X, VIEW_H)
    lurek.render.setColor(0.4, 0.3, 0.6)
    lurek.render.rectangle("line", PANEL_X, 0, W - PANEL_X, VIEW_H)

    -- HP bar
    lurek.render.setColor(0.6, 0.1, 0.1)
    lurek.render.rectangle("fill", PANEL_X + 8, 10, 120, 14)
    local hp_frac = player.hp / player.max_hp
    lurek.render.setColor(0.1, 0.8, 0.2)
    lurek.render.rectangle("fill", PANEL_X + 8, 10, 120 * hp_frac, 14)
    lurek.render.setColor(1, 1, 1)
    lurek.render.print(string.format("HP %d/%d", player.hp, player.max_hp), PANEL_X + 12, 10)

    -- Direction
    lurek.render.setColor(0.8, 0.75, 0.55)
    lurek.render.print("Facing: " .. DIR_NAME[player.dir], PANEL_X + 8, 32)
    lurek.render.print(string.format("Pos: %d,%d", player.mx, player.my), PANEL_X + 8, 48)

    -- Inventory panel header
    lurek.render.setColor(0.9, 0.8, 0.5)
    lurek.render.print("Inventory [I]", PANEL_X + 8, 72)
    local slots = inventory.getSlots(player.inv)
    local shown = 0
    for i, slot in ipairs(slots) do
        if slot then
            lurek.render.setColor(show_inv and (i == inv_cursor and {1,1,0} or {0.8,0.8,0.7}) or {0.6,0.6,0.55})
            lurek.render.print(string.format("%d. %s", i, slot.type_id), PANEL_X + 12, 86 + shown * 16)
            shown = shown + 1
        end
        if shown >= 10 then break end
    end
    if shown == 0 then
        lurek.render.setColor(0.4, 0.4, 0.4)
        lurek.render.print("(empty)", PANEL_X + 12, 90)
    end

    -- Use item hint
    if show_inv then
        lurek.render.setColor(0.5, 1, 0.5)
        lurek.render.print("[U] use  [Esc] close", PANEL_X + 8, VIEW_H - 24)
    end

    -- ── Bottom status strip ─────────────────────────────────────────────
    lurek.render.setColor(0.04, 0.04, 0.08)
    lurek.render.rectangle("fill", 0, STATUS_Y, W, H - STATUS_Y)
    lurek.render.setColor(0.5, 0.45, 0.3)
    lurek.render.line(0, STATUS_Y, W, STATUS_Y)

    for i, msg in ipairs(player.log) do
        local alpha = 1 - (i-1) * 0.18
        lurek.render.setColor(0.85, 0.8, 0.65, alpha)
        lurek.render.print(msg, 10, STATUS_Y + 6 + (i-1) * 18)
    end

    -- Combat overlay
    if state == STATE.COMBAT and combat_enemy then
        lurek.render.setColor(0.7, 0.1, 0.1, 0.8)
        lurek.render.rectangle("fill", VIEW_W/2 - 80, VIEW_H/2 - 20, 160, 40)
        lurek.render.setColor(1, 0.3, 0.3)
        lurek.render.print("COMBAT!", VIEW_W/2 - 32, VIEW_H/2 - 8, 0, 1.3)
    end

    -- Game over / win
    if state == STATE.DEAD or state == STATE.WIN then
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle("fill", VIEW_W/2 - 150, VIEW_H/2 - 36, 300, 72)
        if state == STATE.WIN then
            lurek.render.setColor(0.2, 1, 0.4)
            lurek.render.print("YOU ESCAPED!", VIEW_W/2 - 60, VIEW_H/2 - 14, 0, 1.5)
        else
            lurek.render.setColor(1, 0.2, 0.2)
            lurek.render.print("YOU DIED", VIEW_W/2 - 46, VIEW_H/2 - 14, 0, 1.5)
        end
        lurek.render.setColor(1, 1, 1)
        lurek.render.print("Escape to quit", VIEW_W/2 - 52, VIEW_H/2 + 14)
    end
end

-- ── Keypressed ────────────────────────────────────────────────────────────
function lurek.keypressed(key)
    if key == "escape" then
        if show_inv then
            show_inv = false
        else
            lurek.event.quit()
        end
    end

    if state == STATE.DEAD or state == STATE.WIN then return end

    if key == "i" then
        show_inv = not show_inv
    end

    if show_inv then
        local slots = inventory.getSlots(player.inv)
        local filled = {}
        for i, s in ipairs(slots) do if s then filled[#filled+1] = i end end
        if key == "up"   then inv_cursor = math.max(1, inv_cursor - 1) end
        if key == "down" then inv_cursor = math.min(#filled, inv_cursor + 1) end
        if (key == "u" or key == "return") and filled[inv_cursor] then
            local slot_idx = filled[inv_cursor]
            local s = slots[slot_idx]
            if s and s.base_stats and s.base_stats.heal then
                player.hp = math.min(player.max_hp, player.hp + s.base_stats.heal)
                push_log(string.format("Used %s, healed %d HP", s.type_id, s.base_stats.heal))
                inventory.remove(player.inv, slot_idx)
            else
                push_log(string.format("Cannot use %s here.", s and s.type_id or "?"))
            end
        end
        return
    end

    if state ~= STATE.EXPLORE then return end

    if key == "w" or key == "up" then
        local fx, fy = facing_tile()
        try_move(fx, fy)
    elseif key == "s" or key == "down" then
        -- Step backward
        local bdir = (player.dir + 2) % 4
        local bx = player.mx + DIR_DX[bdir]
        local by = player.my + DIR_DY[bdir]
        try_move(bx, by)
    elseif key == "a" or key == "left" then
        player.dir = (player.dir - 1 + 4) % 4
    elseif key == "d" or key == "right" then
        player.dir = (player.dir + 1) % 4
    elseif key == "space" or key == "e" then
        -- Interact with facing tile (doors / items)
        local fx, fy = facing_tile()
        push_log(string.format("Facing %s (%d,%d): tile %d", DIR_NAME[player.dir], fx, fy, map_at(fx, fy)))
    end
end
