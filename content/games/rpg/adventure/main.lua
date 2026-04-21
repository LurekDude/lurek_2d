------------------------------------------------------------------------
-- The Lost Egg — Point-and-Click Adventure — Lurek2D
-- Category: rpg
-- Room-based exploration with inventory puzzles, item combining,
-- typewriter dialog, and atmospheric pixel-art-style rendering.
------------------------------------------------------------------------

-- Action input bindings:
-- up(w,up), down(s,down), left(a,left), right(d,right)
-- interact(e), tab, use_item(u), combine(c), quit(escape)

local STATE = { TITLE = 1, EXPLORING = 2, DIALOG = 3, INVENTORY = 4, PUZZLE = 5, WIN = 6 }

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local CHAR_DELAY      = 0.03
local INV_SLOT_W      = 64
local INV_SLOT_H      = 48
local INV_COLS        = 8
local INV_Y           = SCREEN_H - 60

------------------------------------------------------------------------
-- Room palettes
------------------------------------------------------------------------
local PALETTES = {
    bedroom  = { bg = {0.12, 0.10, 0.18}, wall = {0.22, 0.18, 0.30}, floor = {0.16, 0.12, 0.22}, accent = {0.55, 0.35, 0.20} },
    hallway  = { bg = {0.08, 0.08, 0.12}, wall = {0.18, 0.16, 0.20}, floor = {0.12, 0.10, 0.14}, accent = {0.40, 0.40, 0.50} },
    kitchen  = { bg = {0.15, 0.12, 0.08}, wall = {0.28, 0.22, 0.15}, floor = {0.20, 0.16, 0.10}, accent = {0.70, 0.50, 0.20} },
    garden   = { bg = {0.05, 0.15, 0.08}, wall = {0.10, 0.28, 0.12}, floor = {0.08, 0.22, 0.10}, accent = {0.40, 0.65, 0.25} },
    attic    = { bg = {0.10, 0.08, 0.06}, wall = {0.25, 0.20, 0.15}, floor = {0.15, 0.12, 0.08}, accent = {0.80, 0.65, 0.20} },
}

------------------------------------------------------------------------
-- Room definitions
------------------------------------------------------------------------
local ROOMS = {}

ROOMS.bedroom = {
    name = "Bedroom",
    exits = { right = "hallway" },
    hotspots = {
        { id = "bed",     x = 100, y = 200, w = 180, h = 120, desc = "A cozy bed with a plump pillow.", action = nil },
        { id = "pillow",  x = 140, y = 200, w = 80,  h = 40,  desc = "Something glints beneath the pillow...", action = "find_key" },
        { id = "drawer",  x = 420, y = 220, w = 100, h = 80,  desc = "A locked bedside drawer.", action = "open_drawer" },
        { id = "window",  x = 550, y = 100, w = 120, h = 160, desc = "Moonlight streams through the window." },
        { id = "rug",     x = 250, y = 380, w = 200, h = 60,  desc = "A dusty old rug with a faded pattern." },
    },
}

ROOMS.hallway = {
    name = "Hallway",
    exits = { left = "bedroom", right = "kitchen", down = "garden" },
    hotspots = {
        { id = "painting",   x = 200, y = 100, w = 120, h = 160, desc = "An old painting of a golden bird." },
        { id = "dark_wall",  x = 500, y = 80,  w = 140, h = 200, desc = "This section of wall looks different...", action = "reveal_attic" },
        { id = "coat_rack",  x = 60,  y = 150, w = 60,  h = 200, desc = "A coat rack with nothing on it." },
        { id = "floor_tile", x = 300, y = 400, w = 200, h = 40,  desc = "Scuff marks on the floor tiles." },
    },
}

ROOMS.kitchen = {
    name = "Kitchen",
    exits = { left = "hallway" },
    hotspots = {
        { id = "counter",  x = 80,  y = 200, w = 200, h = 80,  desc = "A cluttered kitchen counter." },
        { id = "knife",    x = 130, y = 210, w = 40,  h = 30,  desc = "A sturdy kitchen knife. Could be useful.", action = "get_knife" },
        { id = "rope",     x = 450, y = 300, w = 60,  h = 80,  desc = "A coil of rope hanging from a hook.", action = "get_rope" },
        { id = "stove",    x = 300, y = 180, w = 120, h = 100, desc = "An old wood-burning stove." },
        { id = "pantry",   x = 600, y = 150, w = 100, h = 200, desc = "Shelves of dusty jars and tins." },
    },
}

ROOMS.garden = {
    name = "Garden",
    exits = { up = "hallway" },
    hotspots = {
        { id = "tree",     x = 500, y = 60,  w = 160, h = 300, desc = "A tall oak tree. A nest sits high in the branches.", action = "climb_tree" },
        { id = "flowers",  x = 80,  y = 350, w = 200, h = 100, desc = "Wildflowers swaying in the breeze." },
        { id = "fountain", x = 250, y = 200, w = 120, h = 120, desc = "A cracked stone fountain, dry." },
        { id = "gate",     x = 700, y = 200, w = 40,  h = 200, desc = "An iron gate. Locked from the other side." },
    },
}

ROOMS.attic = {
    name = "Attic",
    exits = { down = "hallway" },
    hotspots = {
        { id = "pedestal",  x = 320, y = 200, w = 160, h = 140, desc = "An ornate stone pedestal with an egg-shaped indent.", action = "place_egg" },
        { id = "chest",     x = 80,  y = 300, w = 120, h = 80,  desc = "An empty wooden chest covered in dust." },
        { id = "cobwebs",   x = 500, y = 80,  w = 200, h = 100, desc = "Thick cobwebs draped across the rafters." },
        { id = "portrait",  x = 600, y = 200, w = 100, h = 140, desc = "A portrait of a woman holding a golden egg." },
    },
}

------------------------------------------------------------------------
-- Game state
------------------------------------------------------------------------
local game_state    = STATE.TITLE
local current_room  = "bedroom"
local selected_idx  = 1
local inventory     = {}
local inv_selected  = 0
local combine_mode  = false
local combine_first = nil
local flags         = {
    key_found       = false,
    drawer_opened   = false,
    flashlight_got  = false,
    attic_revealed  = false,
    knife_got       = false,
    rope_got        = false,
    hook_made       = false,
    nest_reached    = false,
    egg_got         = false,
    egg_placed      = false,
}

-- Dialog / typewriter
local dialog        = { full = "", shown = "", timer = 0, active = false, char_idx = 0 }
-- Tweens
local pickup_anim   = { active = false, x = 0, y = 0, alpha = 1, text = "" }
-- Particles
local sparkle_ps    = nil
local burst_ps      = nil
local dust_ps       = nil
-- Title
local title_blink   = 0

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
local function has_item(name)
    for _, v in ipairs(inventory) do if v == name then return true end end
    return false
end

local function remove_item(name)
    for i, v in ipairs(inventory) do
        if v == name then table.remove(inventory, i) return end
    end
end

local function add_item(name)
    if not has_item(name) then inventory[#inventory + 1] = name end
end

local function show_dialog(text)
    dialog.full     = text
    dialog.shown    = ""
    dialog.timer    = 0
    dialog.char_idx = 0
    dialog.active   = true
    game_state      = STATE.DIALOG
end

local function start_pickup_anim(x, y, text)
    pickup_anim.active = true
    pickup_anim.x      = x
    pickup_anim.y      = y
    pickup_anim.alpha  = 1.0
    pickup_anim.text   = text
    lurek.tween.to(pickup_anim, 0.8, { y = y - 40, alpha = 0 })
end

local function get_room()
    return ROOMS[current_room]
end

local function get_palette()
    return PALETTES[current_room]
end

local function clamp_selected()
    local room = get_room()
    if #room.hotspots == 0 then selected_idx = 0 return end
    if selected_idx < 1 then selected_idx = #room.hotspots end
    if selected_idx > #room.hotspots then selected_idx = 1 end
end

------------------------------------------------------------------------
-- Puzzle logic
------------------------------------------------------------------------
local function try_interact(hotspot)
    local act = hotspot.action
    if not act then
        show_dialog(hotspot.desc)
        return
    end

    if act == "find_key" then
        if flags.key_found then
            show_dialog("Nothing else under the pillow.")
        else
            flags.key_found = true
            add_item("key")
            sparkle_ps:emit(hotspot.x + hotspot.w / 2, hotspot.y + hotspot.h / 2, 15)
            start_pickup_anim(hotspot.x + hotspot.w / 2, hotspot.y, "+Key")
            show_dialog("You found a small brass key hidden under the pillow!")
        end

    elseif act == "open_drawer" then
        if flags.drawer_opened then
            show_dialog("The drawer is empty now.")
        elseif not has_item("key") then
            show_dialog("The drawer is locked. You need a key.")
        else
            flags.drawer_opened = true
            remove_item("key")
            add_item("flashlight")
            sparkle_ps:emit(hotspot.x + hotspot.w / 2, hotspot.y + hotspot.h / 2, 15)
            start_pickup_anim(hotspot.x + hotspot.w / 2, hotspot.y, "+Flashlight")
            show_dialog("You unlock the drawer with the key and find a flashlight inside!")
        end

    elseif act == "reveal_attic" then
        if flags.attic_revealed then
            show_dialog("The hidden door to the attic stands open.")
        elseif not has_item("flashlight") then
            show_dialog("It's too dark to see anything here. You need a light source.")
        else
            flags.attic_revealed = true
            ROOMS.hallway.exits.up = "attic"
            burst_ps:emit(hotspot.x + hotspot.w / 2, hotspot.y + hotspot.h / 2, 25)
            dust_ps:emit(hotspot.x + hotspot.w / 2, hotspot.y + hotspot.h, 20)
            show_dialog("The flashlight reveals a hidden door! It creaks open to reveal stairs to the attic.")
        end

    elseif act == "get_knife" then
        if flags.knife_got then
            show_dialog("You already took the knife.")
        else
            flags.knife_got = true
            add_item("knife")
            sparkle_ps:emit(hotspot.x + hotspot.w / 2, hotspot.y + hotspot.h / 2, 12)
            start_pickup_anim(hotspot.x + hotspot.w / 2, hotspot.y, "+Knife")
            show_dialog("You pick up the sturdy kitchen knife.")
        end

    elseif act == "get_rope" then
        if flags.rope_got then
            show_dialog("The hook is empty — you already took the rope.")
        else
            flags.rope_got = true
            add_item("rope")
            sparkle_ps:emit(hotspot.x + hotspot.w / 2, hotspot.y + hotspot.h / 2, 12)
            start_pickup_anim(hotspot.x + hotspot.w / 2, hotspot.y, "+Rope")
            show_dialog("You take the coil of rope.")
        end

    elseif act == "climb_tree" then
        if flags.nest_reached then
            show_dialog("The nest is empty now.")
        elseif not flags.hook_made then
            show_dialog("The lowest branch is too high to reach. You need something to help you climb.")
        else
            flags.nest_reached = true
            flags.egg_got = true
            remove_item("grappling_hook")
            add_item("golden_egg")
            sparkle_ps:emit(hotspot.x + hotspot.w / 2, hotspot.y + 40, 20)
            start_pickup_anim(hotspot.x + hotspot.w / 2, hotspot.y + 40, "+Golden Egg")
            show_dialog("You throw the grappling hook and climb the tree! Inside the nest gleams a beautiful golden egg!")
        end

    elseif act == "place_egg" then
        if flags.egg_placed then
            show_dialog("The egg rests on the pedestal, glowing softly.")
        elseif not has_item("golden_egg") then
            show_dialog("The pedestal has an egg-shaped indent. Something belongs here...")
        else
            flags.egg_placed = true
            remove_item("golden_egg")
            burst_ps:emit(hotspot.x + hotspot.w / 2, hotspot.y + hotspot.h / 2, 40)
            sparkle_ps:emit(hotspot.x + hotspot.w / 2, hotspot.y, 30)
            game_state = STATE.WIN
        end

    else
        show_dialog(hotspot.desc)
    end
end

local function try_combine()
    if combine_first and inv_selected > 0 and inv_selected <= #inventory then
        local second = inventory[inv_selected]
        local a, b = combine_first, second
        if (a == "knife" and b == "rope") or (a == "rope" and b == "knife") then
            remove_item("knife")
            remove_item("rope")
            add_item("grappling_hook")
            flags.hook_made = true
            combine_mode = false
            combine_first = nil
            show_dialog("You tie the knife to the rope, fashioning a crude grappling hook!")
        else
            combine_mode = false
            combine_first = nil
            show_dialog("Those items don't combine into anything useful.")
        end
    end
end

------------------------------------------------------------------------
-- Init
------------------------------------------------------------------------
function lurek.init()
    lurek.input.addAction("up",        {"w", "up"})
    lurek.input.addAction("down",      {"s", "down"})
    lurek.input.addAction("left",      {"a", "left"})
    lurek.input.addAction("right",     {"d", "right"})
    lurek.input.addAction("interact",  {"e"})
    lurek.input.addAction("tab",       {"tab"})
    lurek.input.addAction("use_item",  {"u"})
    lurek.input.addAction("combine",   {"c"})
    lurek.input.addAction("quit",      {"escape"})

    -- Particle systems
    sparkle_ps = lurek.particle.new({
        maxParticles = 25, lifetime = 0.6,
        speed = 40, spread = 6.28,
        sizeStart = 4, sizeEnd = 1,
        colorStart = {1.0, 0.95, 0.5, 1.0},
        colorEnd   = {1.0, 0.80, 0.2, 0.0},
    })
    burst_ps = lurek.particle.new({
        maxParticles = 35, lifetime = 0.5,
        speed = 90, spread = 6.28,
        sizeStart = 6, sizeEnd = 2,
        colorStart = {1.0, 0.7, 0.2, 1.0},
        colorEnd   = {0.8, 0.3, 0.1, 0.0},
    })
    dust_ps = lurek.particle.new({
        maxParticles = 20, lifetime = 0.8,
        speed = 30, spread = 3.14,
        sizeStart = 5, sizeEnd = 8,
        colorStart = {0.6, 0.5, 0.4, 0.6},
        colorEnd   = {0.5, 0.4, 0.3, 0.0},
    })
end

function lurek.ready()
    game_state = STATE.TITLE
end

------------------------------------------------------------------------
-- Process
------------------------------------------------------------------------
lurek.process(function(dt)
    title_blink = title_blink + dt

    -- Quit
    if lurek.input.wasActionPressed("quit") then
        if game_state == STATE.INVENTORY then
            game_state = STATE.EXPLORING
        elseif game_state == STATE.DIALOG then
            dialog.active = false
            game_state = STATE.EXPLORING
        else
            lurek.event.quit()
        end
        return
    end

    -- Title
    if game_state == STATE.TITLE then
        if lurek.input.wasActionPressed("interact") then
            game_state = STATE.EXPLORING
        end
        return
    end

    -- Win
    if game_state == STATE.WIN then return end

    -- Dialog typewriter
    if game_state == STATE.DIALOG then
        if dialog.active then
            dialog.timer = dialog.timer + dt
            while dialog.timer >= CHAR_DELAY and dialog.char_idx < #dialog.full do
                dialog.char_idx = dialog.char_idx + 1
                dialog.shown = string.sub(dialog.full, 1, dialog.char_idx)
                dialog.timer = dialog.timer - CHAR_DELAY
            end
            if lurek.input.wasActionPressed("interact") then
                if dialog.char_idx < #dialog.full then
                    dialog.shown = dialog.full
                    dialog.char_idx = #dialog.full
                else
                    dialog.active = false
                    game_state = STATE.EXPLORING
                end
            end
        end
        return
    end

    -- Inventory mode
    if game_state == STATE.INVENTORY then
        if lurek.input.wasActionPressed("left") then
            inv_selected = inv_selected - 1
            if inv_selected < 1 then inv_selected = math.max(1, #inventory) end
        end
        if lurek.input.wasActionPressed("right") then
            inv_selected = inv_selected + 1
            if inv_selected > #inventory then inv_selected = 1 end
        end
        if lurek.input.wasActionPressed("combine") then
            if combine_mode then
                try_combine()
            else
                if inv_selected > 0 and inv_selected <= #inventory then
                    combine_mode = true
                    combine_first = inventory[inv_selected]
                    show_dialog("Select another item to combine with " .. combine_first .. ".")
                    game_state = STATE.INVENTORY
                    dialog.active = false
                end
            end
        end
        if lurek.input.wasActionPressed("interact") then
            game_state = STATE.EXPLORING
        end
        return
    end

    -- Exploring
    if game_state == STATE.EXPLORING then
        local room = get_room()

        -- Tab cycles hotspots
        if lurek.input.wasActionPressed("tab") then
            selected_idx = selected_idx + 1
            clamp_selected()
        end

        -- Interact with selected hotspot
        if lurek.input.wasActionPressed("interact") then
            if selected_idx >= 1 and selected_idx <= #room.hotspots then
                try_interact(room.hotspots[selected_idx])
            end
        end

        -- Use item on hotspot
        if lurek.input.wasActionPressed("use_item") then
            if inv_selected > 0 and inv_selected <= #inventory then
                if selected_idx >= 1 and selected_idx <= #room.hotspots then
                    try_interact(room.hotspots[selected_idx])
                end
            end
        end

        -- Open inventory
        if lurek.input.wasActionPressed("combine") then
            game_state = STATE.INVENTORY
            if #inventory > 0 and inv_selected == 0 then inv_selected = 1 end
        end

        -- Room navigation
        local exits = room.exits
        if lurek.input.wasActionPressed("up") and exits.up then
            current_room = exits.up
            selected_idx = 1
        end
        if lurek.input.wasActionPressed("down") and exits.down then
            current_room = exits.down
            selected_idx = 1
        end
        if lurek.input.wasActionPressed("left") and exits.left then
            current_room = exits.left
            selected_idx = 1
        end
        if lurek.input.wasActionPressed("right") and exits.right then
            current_room = exits.right
            selected_idx = 1
        end
    end

    -- Pickup animation tween update
    if pickup_anim.active and pickup_anim.alpha <= 0.01 then
        pickup_anim.active = false
    end

    -- Update particles
    sparkle_ps:update(dt)
    burst_ps:update(dt)
    dust_ps:update(dt)
    lurek.tween.update(dt)

    -- Camera + window
    lurek.camera.setPosition(0, 0)
    local pal = get_palette()
    lurek.render.setBackgroundColor(pal.bg[1], pal.bg[2], pal.bg[3])
    local fps = lurek.timer.getFPS()
    lurek.window.setTitle("The Lost Egg — Lurek2D [FPS: " .. fps .. "]")
end)

------------------------------------------------------------------------
-- Draw helpers
------------------------------------------------------------------------
local function draw_room_bg()
    local pal = get_palette()
    -- Floor
    lurek.render.setColor(pal.floor[1], pal.floor[2], pal.floor[3], 1)
    lurek.render.rectangle(0, SCREEN_H * 0.55, SCREEN_W, SCREEN_H * 0.45)
    -- Walls
    lurek.render.setColor(pal.wall[1], pal.wall[2], pal.wall[3], 1)
    lurek.render.rectangle(0, 0, SCREEN_W, SCREEN_H * 0.55)
    -- Wall trim
    lurek.render.setColor(pal.accent[1], pal.accent[2], pal.accent[3], 1)
    lurek.render.rectangle(0, SCREEN_H * 0.55 - 4, SCREEN_W, 4)
    -- Side walls
    lurek.render.setColor(pal.wall[1] * 0.7, pal.wall[2] * 0.7, pal.wall[3] * 0.7, 1)
    lurek.render.rectangle(0, 0, 30, SCREEN_H * 0.55)
    lurek.render.rectangle(SCREEN_W - 30, 0, 30, SCREEN_H * 0.55)
end

local function draw_hotspot(hs, idx)
    local room = get_room()
    local pal = get_palette()
    local is_sel = (idx == selected_idx)

    -- Object body
    if is_sel then
        lurek.render.setColor(pal.accent[1], pal.accent[2], pal.accent[3], 0.9)
    else
        lurek.render.setColor(pal.accent[1] * 0.6, pal.accent[2] * 0.6, pal.accent[3] * 0.6, 0.7)
    end
    lurek.render.rectangle(hs.x, hs.y, hs.w, hs.h)

    -- Border
    if is_sel then
        local pulse = 0.7 + 0.3 * math.sin(title_blink * 4)
        lurek.render.setColor(1, 1, 0.6, pulse)
        lurek.render.rectangleLines(hs.x - 2, hs.y - 2, hs.w + 4, hs.h + 4, 2)
    end

    -- Label
    lurek.render.setColor(1, 1, 1, is_sel and 1 or 0.6)
    lurek.render.print(hs.id, hs.x + 4, hs.y + hs.h + 4, 12)
end

local function draw_exit_arrows()
    local room = get_room()
    local exits = room.exits
    local a = 0.4 + 0.3 * math.sin(title_blink * 3)
    lurek.render.setColor(1, 1, 1, a)
    if exits.left then
        lurek.render.print("<", 8, SCREEN_H / 2 - 10, 24)
    end
    if exits.right then
        lurek.render.print(">", SCREEN_W - 24, SCREEN_H / 2 - 10, 24)
    end
    if exits.up then
        lurek.render.print("^", SCREEN_W / 2 - 8, 8, 24)
    end
    if exits.down then
        lurek.render.print("v", SCREEN_W / 2 - 8, SCREEN_H - 80, 24)
    end
end

local function draw_room_objects()
    local room = get_room()
    -- Room-specific decorations
    if current_room == "bedroom" then
        -- Bed frame
        lurek.render.setColor(0.35, 0.22, 0.12, 1)
        lurek.render.rectangle(90, 190, 200, 140)
        -- Pillow
        lurek.render.setColor(0.85, 0.80, 0.70, 1)
        lurek.render.rectangle(140, 195, 80, 35)
    elseif current_room == "hallway" then
        -- Floor runner
        lurek.render.setColor(0.35, 0.12, 0.12, 0.5)
        lurek.render.rectangle(50, 430, SCREEN_W - 100, 30)
    elseif current_room == "kitchen" then
        -- Counter top
        lurek.render.setColor(0.5, 0.4, 0.3, 1)
        lurek.render.rectangle(70, 195, 220, 10)
    elseif current_room == "garden" then
        -- Grass tufts
        for i = 0, 15 do
            local gx = (i * 53 + 17) % SCREEN_W
            local gy = 400 + (i * 7) % 80
            lurek.render.setColor(0.15, 0.45, 0.15, 0.6)
            lurek.render.rectangle(gx, gy, 8, 16)
        end
        -- Tree trunk
        lurek.render.setColor(0.35, 0.22, 0.10, 1)
        lurek.render.rectangle(560, 180, 30, 200)
        -- Canopy
        lurek.render.setColor(0.12, 0.40, 0.12, 0.9)
        lurek.render.circle(575, 120, 80)
    elseif current_room == "attic" then
        -- Rafters
        lurek.render.setColor(0.30, 0.22, 0.12, 0.8)
        lurek.render.rectangle(0, 30, SCREEN_W, 12)
        lurek.render.rectangle(0, 70, SCREEN_W, 8)
        -- Pedestal
        if flags.egg_placed then
            lurek.render.setColor(0.95, 0.85, 0.3, 1)
            lurek.render.circle(400, 250, 20)
        end
    end
end

------------------------------------------------------------------------
-- Render (world)
------------------------------------------------------------------------
lurek.render(function()
    if game_state == STATE.TITLE then
        -- Title screen background
        lurek.render.setColor(0.05, 0.03, 0.08, 1)
        lurek.render.rectangle(0, 0, SCREEN_W, SCREEN_H)

        -- Decorative border
        lurek.render.setColor(0.6, 0.45, 0.15, 0.6)
        lurek.render.rectangleLines(40, 40, SCREEN_W - 80, SCREEN_H - 80, 3)
        lurek.render.rectangleLines(50, 50, SCREEN_W - 100, SCREEN_H - 100, 1)

        -- Title
        lurek.render.setColor(0.95, 0.85, 0.3, 1)
        lurek.render.print("THE LOST EGG", SCREEN_W / 2 - 100, 180, 32)
        lurek.render.setColor(0.7, 0.6, 0.3, 1)
        lurek.render.print("A Point & Click Adventure", SCREEN_W / 2 - 120, 230, 16)

        -- Golden egg icon
        lurek.render.setColor(0.95, 0.82, 0.2, 1)
        lurek.render.circle(SCREEN_W / 2, 320, 30)
        lurek.render.setColor(1, 0.95, 0.5, 0.5)
        lurek.render.circle(SCREEN_W / 2 - 8, 310, 8)

        -- Blink prompt
        local blink = math.sin(title_blink * 3) > 0
        if blink then
            lurek.render.setColor(0.8, 0.8, 0.6, 0.9)
            lurek.render.print("Press [E] to begin", SCREEN_W / 2 - 80, 440, 14)
        end
        return
    end

    if game_state == STATE.WIN then
        lurek.render.setColor(0.02, 0.01, 0.05, 1)
        lurek.render.rectangle(0, 0, SCREEN_W, SCREEN_H)

        local glow = 0.7 + 0.3 * math.sin(title_blink * 2)
        lurek.render.setColor(0.95, 0.85, 0.3, glow)
        lurek.render.circle(SCREEN_W / 2, 250, 50)
        lurek.render.setColor(1, 0.95, 0.5, 0.4 * glow)
        lurek.render.circle(SCREEN_W / 2, 250, 70)

        lurek.render.setColor(1, 0.95, 0.6, 1)
        lurek.render.print("YOU FOUND THE GOLDEN EGG!", SCREEN_W / 2 - 140, 360, 20)
        lurek.render.setColor(0.7, 0.65, 0.4, 0.8)
        lurek.render.print("The ancient mystery is solved.", SCREEN_W / 2 - 120, 400, 14)
        lurek.render.print("Press [Escape] to quit.", SCREEN_W / 2 - 90, 440, 12)

        -- Draw particles on win screen
        sparkle_ps:draw()
        burst_ps:draw()
        return
    end

    -- Normal room rendering
    draw_room_bg()
    draw_room_objects()

    -- Hotspots
    local room = get_room()
    for i, hs in ipairs(room.hotspots) do
        draw_hotspot(hs, i)
    end

    -- Exit arrows
    draw_exit_arrows()

    -- Particles
    sparkle_ps:draw()
    burst_ps:draw()
    dust_ps:draw()

    -- Pickup animation
    if pickup_anim.active then
        lurek.render.setColor(1, 1, 0.6, pickup_anim.alpha)
        lurek.render.print(pickup_anim.text, pickup_anim.x - 20, pickup_anim.y, 16)
    end
end)

------------------------------------------------------------------------
-- Render UI
------------------------------------------------------------------------
lurek.render_ui(function()
    if game_state == STATE.TITLE or game_state == STATE.WIN then return end

    -- Room name banner
    local room = get_room()
    lurek.render.setColor(0, 0, 0, 0.7)
    lurek.render.rectangle(0, 0, SCREEN_W, 28)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print(room.name, 10, 6, 16)

    -- Selected hotspot description
    if game_state == STATE.EXPLORING and selected_idx >= 1 and selected_idx <= #room.hotspots then
        local hs = room.hotspots[selected_idx]
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.rectangle(0, 28, SCREEN_W, 22)
        lurek.render.setColor(0.9, 0.85, 0.6, 1)
        lurek.render.print("[" .. selected_idx .. "] " .. hs.id .. ": " .. hs.desc, 10, 32, 12)
    end

    -- Inventory bar
    lurek.render.setColor(0, 0, 0, 0.8)
    lurek.render.rectangle(0, INV_Y, SCREEN_W, 60)
    lurek.render.setColor(0.4, 0.35, 0.2, 1)
    lurek.render.line(0, INV_Y, SCREEN_W, INV_Y, 2)

    -- Inventory label
    lurek.render.setColor(0.8, 0.75, 0.5, 1)
    lurek.render.print("Inventory [C]", 10, INV_Y + 4, 11)

    -- Items
    for i, item in ipairs(inventory) do
        local sx = 10 + (i - 1) * (INV_SLOT_W + 4)
        local sy = INV_Y + 18

        if i == inv_selected then
            lurek.render.setColor(0.8, 0.7, 0.2, 0.8)
            lurek.render.rectangleLines(sx - 2, sy - 2, INV_SLOT_W + 4, INV_SLOT_H - 14, 2)
        end

        -- Item background
        lurek.render.setColor(0.15, 0.12, 0.08, 0.9)
        lurek.render.rectangle(sx, sy, INV_SLOT_W, INV_SLOT_H - 16)

        -- Item name
        lurek.render.setColor(1, 0.95, 0.7, 1)
        local display_name = item:gsub("_", " ")
        lurek.render.print(display_name, sx + 3, sy + 6, 10)
    end

    -- Combine mode indicator
    if combine_mode then
        lurek.render.setColor(1, 0.6, 0.1, 0.9)
        lurek.render.print("COMBINE MODE — select second item", SCREEN_W / 2 - 130, INV_Y - 18, 12)
    end

    -- Dialog box
    if game_state == STATE.DIALOG and dialog.active then
        -- Background
        lurek.render.setColor(0, 0, 0, 0.85)
        lurek.render.rectangle(40, SCREEN_H / 2 - 50, SCREEN_W - 80, 100)
        -- Border
        lurek.render.setColor(0.6, 0.5, 0.2, 1)
        lurek.render.rectangleLines(40, SCREEN_H / 2 - 50, SCREEN_W - 80, 100, 2)
        -- Text (typewriter)
        lurek.render.setColor(0.95, 0.9, 0.8, 1)
        lurek.render.print(dialog.shown, 60, SCREEN_H / 2 - 30, 14)
        -- Continue hint
        if dialog.char_idx >= #dialog.full then
            local blink = math.sin(title_blink * 4) > 0
            if blink then
                lurek.render.setColor(0.7, 0.65, 0.4, 0.8)
                lurek.render.print("[E] continue", SCREEN_W - 180, SCREEN_H / 2 + 30, 11)
            end
        end
    end

    -- Inventory screen overlay
    if game_state == STATE.INVENTORY then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.rectangle(0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(0.08, 0.06, 0.12, 0.95)
        lurek.render.rectangle(100, 100, SCREEN_W - 200, SCREEN_H - 260)
        lurek.render.setColor(0.6, 0.5, 0.2, 1)
        lurek.render.rectangleLines(100, 100, SCREEN_W - 200, SCREEN_H - 260, 2)

        lurek.render.setColor(0.95, 0.85, 0.4, 1)
        lurek.render.print("INVENTORY", 320, 115, 20)

        lurek.render.setColor(0.7, 0.65, 0.5, 0.8)
        lurek.render.print("[Left/Right] Select   [C] Combine   [E] Close", 180, 140, 11)

        for i, item in ipairs(inventory) do
            local ix = 140 + ((i - 1) % 4) * 150
            local iy = 175 + math.floor((i - 1) / 4) * 60

            if i == inv_selected then
                lurek.render.setColor(0.8, 0.7, 0.2, 0.9)
                lurek.render.rectangleLines(ix - 4, iy - 4, 140, 50, 2)
            end

            lurek.render.setColor(0.15, 0.12, 0.08, 0.9)
            lurek.render.rectangle(ix, iy, 132, 42)

            lurek.render.setColor(1, 0.95, 0.7, 1)
            local display_name = item:gsub("_", " ")
            lurek.render.print(display_name, ix + 8, iy + 14, 13)
        end

        if #inventory == 0 then
            lurek.render.setColor(0.5, 0.5, 0.5, 0.7)
            lurek.render.print("No items yet.", 320, 220, 14)
        end
    end

    -- Controls hint
    if game_state == STATE.EXPLORING then
        lurek.render.setColor(0.5, 0.5, 0.5, 0.5)
        lurek.render.print("[Tab] Cycle   [E] Interact   [C] Inventory   [Arrows] Move", 140, SCREEN_H - 14, 10)
    end
end)
