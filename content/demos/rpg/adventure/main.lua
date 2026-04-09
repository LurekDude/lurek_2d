-- Point-and-Click Adventure Demo — explore rooms, collect items, solve puzzles
-- Mouse click to interact | Escape to quit
-- Run with: cargo run -- content/demos/rpg/adventure

-- ── State ────────────────────────────────────────────────────────
-- Game state: rooms table built in defineRooms(), currentRoom is the active
-- room key, inventory tracks collected items, dialog* drives the typewriter.
local rooms = {}
local currentRoom = "bedroom"
local inventory = {}
local dialogText = ""
local dialogTimer = 0
local dialogSpeed = 0.03
local dialogFull = ""
local dialogIdx = 0
local hoverObj = nil

local function hasItem(name)
    for _, item in ipairs(inventory) do
        if item == name then return true end
    end
    return false
end

local function addItem(name)
    if not hasItem(name) then
        table.insert(inventory, name)
    end
end

local function showDialog(text)
    dialogFull = text
    dialogIdx = 0
    dialogText = ""
    dialogTimer = 0
end

-- ── Room definitions ────────────────────────────────────────────
-- Each room has a bg colour and an objects list. Every object can have:
--   look   → passive description shown on click
--   action → function called on click (item pickup, locked door, etc.)
--   exit   → room key string; clicking teleports to that room
local function defineRooms()
    rooms = {
        bedroom = {
            bg = {0.18, 0.15, 0.22},
            objects = {
                { id = "bed", x = 50, y = 280, w = 180, h = 100, color = {0.4, 0.25, 0.3},
                  label = "Bed", look = "A cozy bed with rumpled sheets." },
                { id = "dresser", x = 300, y = 300, w = 80, h = 80, color = {0.5, 0.35, 0.2},
                  label = "Dresser", look = "An old wooden dresser.",
                  action = function()
                      if not hasItem("key") then
                          addItem("key")
                          showDialog("You found a rusty key inside the drawer!")
                      else
                          showDialog("The drawer is empty now.")
                      end
                  end },
                { id = "lamp", x = 260, y = 260, w = 30, h = 50, color = {0.8, 0.7, 0.3},
                  label = "Lamp", look = "A small bedside lamp. It flickers." },
                { id = "window_br", x = 500, y = 150, w = 100, h = 120, color = {0.3, 0.4, 0.6},
                  label = "Window", look = "Moonlight streams through the window." },
                { id = "door_hall", x = 700, y = 250, w = 60, h = 140, color = {0.45, 0.3, 0.2},
                  label = "Door to Hallway", exit = "hallway" },
            },
        },
        hallway = {
            bg = {0.15, 0.15, 0.18},
            objects = {
                { id = "painting", x = 200, y = 150, w = 120, h = 90, color = {0.5, 0.4, 0.5},
                  label = "Painting", look = "A faded portrait of someone you don't recognize." },
                { id = "table_hw", x = 400, y = 340, w = 100, h = 60, color = {0.4, 0.3, 0.2},
                  label = "Table", look = "A small hallway table with a vase on it." },
                { id = "vase", x = 430, y = 300, w = 30, h = 40, color = {0.3, 0.5, 0.7},
                  label = "Vase", look = "A blue ceramic vase. Pretty, but empty." },
                { id = "door_bedroom", x = 50, y = 250, w = 60, h = 140, color = {0.45, 0.3, 0.2},
                  label = "Door to Bedroom", exit = "bedroom" },
                { id = "door_garden", x = 700, y = 250, w = 60, h = 140, color = {0.3, 0.4, 0.2},
                  label = "Garden Door",
                  action = function()
                      if hasItem("key") then
                          showDialog("You unlock the garden door with the rusty key!")
                          currentRoom = "garden"
                      else
                          showDialog("The door is locked. You need a key.")
                      end
                  end },
                { id = "rug", x = 300, y = 420, w = 200, h = 40, color = {0.5, 0.2, 0.2},
                  label = "Rug", look = "A worn red rug stretches across the hallway." },
            },
        },
        garden = {
            bg = {0.1, 0.2, 0.1},
            objects = {
                { id = "tree", x = 100, y = 180, w = 60, h = 200, color = {0.3, 0.5, 0.2},
                  label = "Tree", look = "A tall oak tree sways gently in the breeze." },
                { id = "tree_top", x = 70, y = 100, w = 120, h = 100, color = {0.2, 0.6, 0.2},
                  label = "Tree Top", look = "Thick green foliage." },
                { id = "fountain", x = 350, y = 280, w = 100, h = 80, color = {0.4, 0.5, 0.6},
                  label = "Fountain", look = "A stone fountain. The water sparkles in the moonlight." },
                { id = "flowers", x = 550, y = 380, w = 80, h = 40, color = {0.8, 0.3, 0.4},
                  label = "Flowers", look = "Beautiful red roses. They smell wonderful." },
                { id = "bench", x = 500, y = 300, w = 100, h = 40, color = {0.45, 0.35, 0.2},
                  label = "Bench", look = "A wooden garden bench. Perfect for stargazing." },
                { id = "gem", x = 380, y = 320, w = 20, h = 20, color = {0.3, 0.9, 0.9},
                  label = "Shiny Gem",
                  action = function()
                      if not hasItem("gem") then
                          addItem("gem")
                          showDialog("You pick up a glowing gem from the fountain! You win!")
                      else
                          showDialog("You already have the gem. Congratulations!")
                      end
                  end },
                { id = "door_back", x = 50, y = 400, w = 60, h = 100, color = {0.45, 0.3, 0.2},
                  label = "Back Inside", exit = "hallway" },
            },
        },
    }
end

function lurek.init()
    lurek.window.setTitle("Point-and-Click Adventure")
    lurek.gfx.setBackgroundColor(0.15, 0.15, 0.2)
    defineRooms()
    showDialog("You wake up in your bedroom. Something feels different tonight...")
end

function lurek.process(dt)
    -- ── Typewriter effect ────────────────────────────────────────
    -- Reveal dialogFull one character at a time using dialogSpeed (seconds/char).
    if dialogIdx < #dialogFull then
        dialogTimer = dialogTimer + dt
        while dialogTimer >= dialogSpeed and dialogIdx < #dialogFull do
            dialogTimer = dialogTimer - dialogSpeed
            dialogIdx = dialogIdx + 1
            dialogText = string.sub(dialogFull, 1, dialogIdx)
        end
    end

    -- ── Hover detection ──────────────────────────────────────────
    -- Walk the object list each frame; AABB check against mouse position.
    local mx, my = lurek.mouse.getPosition()
    hoverObj = nil
    local room = rooms[currentRoom]
    if room then
        for _, obj in ipairs(room.objects) do
            if mx >= obj.x and mx <= obj.x + obj.w and my >= obj.y and my <= obj.y + obj.h then
                hoverObj = obj
            end
        end
    end
end

function lurek.render()
    local room = rooms[currentRoom]
    if not room then return end

    -- room background
    lurek.gfx.setBackgroundColor(room.bg[1], room.bg[2], room.bg[3])

    -- floor
    lurek.gfx.setColor(room.bg[1] * 0.7, room.bg[2] * 0.7, room.bg[3] * 0.7, 1)
    lurek.gfx.rectangle("fill", 0, 460, 800, 40)

    -- objects
    for _, obj in ipairs(room.objects) do
        local c = obj.color
        local hover = (hoverObj == obj)
        if hover then
            lurek.gfx.setColor(c[1] + 0.2, c[2] + 0.2, c[3] + 0.2, 1)
        else
            lurek.gfx.setColor(c[1], c[2], c[3], 1)
        end
        lurek.gfx.rectangle("fill", obj.x, obj.y, obj.w, obj.h)
        if hover then
            lurek.gfx.setColor(1, 1, 0.5, 1)
            lurek.gfx.rectangle("line", obj.x - 1, obj.y - 1, obj.w + 2, obj.h + 2)
        end
    end

    -- hover label
    if hoverObj then
        local mx, my = lurek.mouse.getPosition()
        lurek.gfx.setColor(0, 0, 0, 0.7)
        lurek.gfx.rectangle("fill", mx + 10, my - 22, #hoverObj.label * 8 + 10, 20)
        lurek.gfx.setColor(1, 1, 0.8, 1)
        lurek.gfx.print(hoverObj.label, mx + 15, my - 20)
    end

    -- inventory bar
    lurek.gfx.setColor(0.1, 0.1, 0.12, 0.9)
    lurek.gfx.rectangle("fill", 0, 520, 800, 80)
    lurek.gfx.setColor(0.3, 0.3, 0.35, 1)
    lurek.gfx.line(0, 520, 800, 520)
    lurek.gfx.setColor(0.7, 0.7, 0.7, 1)
    lurek.gfx.print("Inventory:", 10, 530)
    for i, item in ipairs(inventory) do
        local ix = 20 + (i - 1) * 90
        lurek.gfx.setColor(0.25, 0.25, 0.3, 1)
        lurek.gfx.rectangle("fill", ix, 550, 80, 30)
        lurek.gfx.setColor(0.8, 0.8, 0.5, 1)
        lurek.gfx.rectangle("line", ix, 550, 80, 30)
        lurek.gfx.setColor(1, 1, 1, 1)
        lurek.gfx.print(item, ix + 8, 557)
    end

    -- dialog box
    if #dialogText > 0 then
        lurek.gfx.setColor(0, 0, 0, 0.85)
        lurek.gfx.rectangle("fill", 50, 460, 700, 50)
        lurek.gfx.setColor(0.8, 0.8, 0.6, 1)
        lurek.gfx.rectangle("line", 50, 460, 700, 50)
        lurek.gfx.setColor(1, 1, 1, 1)
        lurek.gfx.print(dialogText, 65, 475)
    end

    -- room name
    lurek.gfx.setColor(1, 1, 1, 0.4)
    lurek.gfx.print(string.upper(currentRoom), 700, 10)

    -- cursor
    local mx, my = lurek.mouse.getPosition()
    lurek.gfx.setColor(1, 1, 1, 0.6)
    lurek.gfx.circle("line", mx, my, 6)
end

-- ── Click handler ───────────────────────────────────────────────
-- Left-click resolves in priority order:
--   1. If dialog is still animating → skip to full text
--   2. No hover → dismiss dialog
--   3. exit → room transition
--   4. action → execute callback (pickup, unlock)
--   5. look → show passive description
function lurek.mousepressed(x, y, button)
    if button ~= 1 then return end

    -- skip dialog animation
    if dialogIdx < #dialogFull then
        dialogIdx = #dialogFull
        dialogText = dialogFull
        return
    end

    if not hoverObj then
        showDialog("")
        return
    end

    local obj = hoverObj
    if obj.exit then
        currentRoom = obj.exit
        showDialog("You enter the " .. obj.exit .. ".")
    elseif obj.action then
        obj.action()
    elseif obj.look then
        showDialog(obj.look)
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
end
