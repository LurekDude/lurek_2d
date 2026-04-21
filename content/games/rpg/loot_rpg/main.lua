-- ============================================================
-- Loot RPG — Dungeon crawler loot game
-- Category: rpg
-- Engine:   Lurek2D
-- ============================================================

-- States
local STATE_TITLE     = "TITLE"
local STATE_ROOM      = "ROOM"
local STATE_COMBAT    = "COMBAT"
local STATE_LOOT      = "LOOT"
local STATE_GAME_OVER = "GAME_OVER"

local state = STATE_TITLE

-- Camera & particles
local cam          = nil
local lootSparkle  = nil
local combatFlash  = nil

-- Tween handles
local hpBarTween   = nil
local lootGlowTween = nil

-- Player
local player = {
    hp            = 100,
    maxHp         = 100,
    baseHp        = 100,
    gold          = 0,
    floor         = 1,
    room          = 0,
    roomsPerFloor = 5,
    equipment     = { weapon = nil, armor = nil, helm = nil, boots = nil, accessory = nil },
    backpack      = {},
    maxWeight     = 20.0,
}

-- Combat state
local combat = {
    enemyHp    = 0,
    enemyMaxHp = 0,
    enemyDmg   = 0,
    enemyName  = "",
    log        = {},
    turn       = 0,
    done       = false,
    won        = false,
}

-- Loot & UI state
local pendingLoot    = {}
local hpBarDisplay   = { value = 1.0 }
local lootGlow       = { alpha = 0.0 }
local scrollOffset   = 0
local titleBlink     = 0

-- Item definitions
local ITEM_TYPES = {
    { slot = "weapon",    name = "Sword",  statKey = "damage",  baseMin = 5,  baseMax = 15, weight = 2.0 },
    { slot = "armor",     name = "Shield", statKey = "defense", baseMin = 3,  baseMax = 10, weight = 3.5 },
    { slot = "helm",      name = "Helmet", statKey = "defense", baseMin = 2,  baseMax = 7,  weight = 1.5 },
    { slot = "boots",     name = "Boots",  statKey = "speed",   baseMin = 1,  baseMax = 5,  weight = 1.0 },
    { slot = "accessory", name = "Ring",   statKey = "hpBonus", baseMin = 5,  baseMax = 25, weight = 0.2 },
}

local RARITIES = {
    { name = "Common",    color = {1.0, 1.0, 1.0, 1.0}, mult = 1.0, weight = 60 },
    { name = "Rare",      color = {0.3, 0.5, 1.0, 1.0}, mult = 1.5, weight = 25 },
    { name = "Epic",      color = {0.7, 0.3, 1.0, 1.0}, mult = 2.0, weight = 12 },
    { name = "Legendary", color = {1.0, 0.6, 0.0, 1.0}, mult = 3.0, weight = 3  },
}

local ENEMY_NAMES = { "Goblin", "Skeleton", "Slime", "Orc", "Wraith", "Troll", "Vampire", "Demon" }

-- ============================================================
-- Helpers
-- ============================================================

local function pickRarity()
    local total = 0
    for _, r in ipairs(RARITIES) do total = total + r.weight end
    local roll = math.random() * total
    local acc  = 0
    for _, r in ipairs(RARITIES) do
        acc = acc + r.weight
        if roll <= acc then return r end
    end
    return RARITIES[1]
end

local function generateItem(floorLevel)
    local base   = ITEM_TYPES[math.random(#ITEM_TYPES)]
    local rarity = pickRarity()
    local rawStat = math.random(base.baseMin, base.baseMax) + math.floor(floorLevel * 1.2)
    local stat    = math.floor(rawStat * rarity.mult)
    return {
        name    = rarity.name .. " " .. base.name,
        slot    = base.slot,
        statKey = base.statKey,
        stat    = stat,
        rarity  = rarity,
        weight  = base.weight,
    }
end

local function backpackWeight()
    local w = 0
    for _, item in ipairs(player.backpack) do w = w + item.weight end
    return w
end

local function getGearStats()
    local stats = { damage = 0, defense = 0, speed = 0, hpBonus = 0 }
    for _, item in pairs(player.equipment) do
        if item then stats[item.statKey] = stats[item.statKey] + item.stat end
    end
    return stats
end

local function recalcMaxHp()
    local gs = getGearStats()
    player.maxHp = player.baseHp + gs.hpBonus
    if player.hp > player.maxHp then player.hp = player.maxHp end
end

local function autoEquip()
    for _, item in ipairs(player.backpack) do
        local current = player.equipment[item.slot]
        if not current or item.stat > current.stat then
            player.equipment[item.slot] = item
        end
    end
    recalcMaxHp()
end

local function startCombat()
    state = STATE_COMBAT
    local floorMult = 1 + (player.floor - 1) * 0.4
    local baseEnemyHp  = math.random(30, 60) * floorMult
    local baseEnemyDmg = math.random(5, 15)  * floorMult

    combat.enemyName  = ENEMY_NAMES[math.random(#ENEMY_NAMES)] .. " (Lv" .. player.floor .. ")"
    combat.enemyHp    = math.floor(baseEnemyHp)
    combat.enemyMaxHp = combat.enemyHp
    combat.enemyDmg   = math.floor(baseEnemyDmg)
    combat.log        = {}
    combat.turn       = 0
    combat.done       = false
    combat.won        = false
end

local function processCombatTurn()
    if combat.done then return end
    combat.turn = combat.turn + 1
    local gs = getGearStats()

    -- Player attacks
    local playerDmg = math.max(1, gs.damage + math.random(0, 3))
    combat.enemyHp  = combat.enemyHp - playerDmg
    table.insert(combat.log, "You dealt " .. playerDmg .. " damage.")

    if combatFlash then combatFlash:emit(400, 300, 5) end

    if combat.enemyHp <= 0 then
        combat.enemyHp = 0
        combat.done = true
        combat.won  = true
        table.insert(combat.log, combat.enemyName .. " defeated!")
        player.gold = player.gold + math.random(2, 5) * player.floor
        return
    end

    -- Enemy attacks
    local enemyHit = math.max(1, combat.enemyDmg - math.floor(gs.defense * 0.5) + math.random(-2, 2))
    player.hp = player.hp - enemyHit
    table.insert(combat.log, combat.enemyName .. " dealt " .. enemyHit .. " damage.")

    -- Tween HP bar
    local targetRatio = math.max(0, player.hp / player.maxHp)
    if hpBarTween then hpBarTween:cancel() end
    hpBarTween = lurek.tween.to(hpBarDisplay, 0.3, { value = targetRatio })

    if player.hp <= 0 then
        player.hp   = 0
        combat.done = true
        combat.won  = false
        table.insert(combat.log, "You have been slain...")
    end
end

local function generateLoot()
    pendingLoot = {}
    local count = math.random(1, 3)
    for i = 1, count do
        table.insert(pendingLoot, generateItem(player.floor))
    end
    state = STATE_LOOT

    lootGlow.alpha = 0.0
    if lootGlowTween then lootGlowTween:cancel() end
    lootGlowTween = lurek.tween.to(lootGlow, 0.6, { alpha = 1.0 })

    if lootSparkle then lootSparkle:emit(400, 300, 20) end
end

local function collectLoot()
    for _, item in ipairs(pendingLoot) do
        if backpackWeight() + item.weight <= player.maxWeight then
            table.insert(player.backpack, item)
        end
    end
    pendingLoot = {}
    recalcMaxHp()
end

local function enterNextRoom()
    if state == STATE_TITLE then
        state        = STATE_ROOM
        player.room  = 0
        player.floor = 1
        player.hp    = player.baseHp
        player.maxHp = player.baseHp
        player.gold  = 0
        player.backpack  = {}
        player.equipment = { weapon = nil, armor = nil, helm = nil, boots = nil, accessory = nil }
        hpBarDisplay.value = 1.0
        scrollOffset = 0
    end

    if state == STATE_ROOM then
        player.room = player.room + 1
        if player.room > player.roomsPerFloor then
            player.room  = 1
            player.floor = player.floor + 1
        end
        lurek.window.setTitle("Loot RPG — Floor " .. player.floor .. " Room " .. player.room)
        startCombat()
    end
end

-- ============================================================
-- Input bindings
-- ============================================================

lurek.input.bind("next_room", "space")
lurek.input.bind("equip",     "e")
lurek.input.bind("buy",       "b")
lurek.input.bind("quit",      "escape")

-- ============================================================
-- Callbacks
-- ============================================================

lurek.init(function()
    lurek.render.setBackgroundColor(0.08, 0.06, 0.12, 1.0)
    cam = lurek.camera.new()
    math.randomseed(os.time())

    lootSparkle = lurek.particle.newSystem({
        maxParticles = 60,
        emitRate     = 0,
        lifetime     = { 0.4, 1.0 },
        speed        = { 20, 80 },
        startColor   = { 1.0, 0.85, 0.2, 1.0 },
        endColor     = { 1.0, 0.5, 0.0, 0.0 },
        startSize    = 4,
        endSize      = 1,
        spread       = math.pi * 2,
    })

    combatFlash = lurek.particle.newSystem({
        maxParticles = 30,
        emitRate     = 0,
        lifetime     = { 0.15, 0.4 },
        speed        = { 40, 120 },
        startColor   = { 1.0, 0.2, 0.2, 1.0 },
        endColor     = { 0.8, 0.0, 0.0, 0.0 },
        startSize    = 5,
        endSize      = 2,
        spread       = math.pi * 2,
    })
end)

lurek.process(function(dt)
    titleBlink = titleBlink + dt

    if lootSparkle then lootSparkle:update(dt) end
    if combatFlash then combatFlash:update(dt) end

    if lurek.input.isActionJustPressed("quit") then
        lurek.event.quit()
        return
    end

    if state == STATE_TITLE then
        if lurek.input.isActionJustPressed("next_room") then
            enterNextRoom()
            enterNextRoom()
        end

    elseif state == STATE_COMBAT then
        if lurek.input.isActionJustPressed("next_room") then
            if combat.done then
                if combat.won then
                    generateLoot()
                else
                    state = STATE_GAME_OVER
                end
            else
                processCombatTurn()
            end
        end

    elseif state == STATE_LOOT then
        if lurek.input.isActionJustPressed("next_room") then
            collectLoot()
            state = STATE_ROOM
            enterNextRoom()
        end
        if lurek.input.isActionJustPressed("equip") then
            collectLoot()
            autoEquip()
        end

    elseif state == STATE_ROOM then
        if lurek.input.isActionJustPressed("equip") then autoEquip() end
        if lurek.input.isActionJustPressed("buy") then
            if player.gold >= 5 then
                player.gold = player.gold - 5
                player.hp   = math.min(player.hp + 30, player.maxHp)
                hpBarDisplay.value = player.hp / player.maxHp
            end
        end
        if lurek.input.isActionJustPressed("next_room") then enterNextRoom() end

    elseif state == STATE_GAME_OVER then
        if lurek.input.isActionJustPressed("next_room") then
            state = STATE_TITLE
            lurek.window.setTitle("Loot RPG — Lurek2D")
        end
    end

    if lurek.input.isKeyDown("up") then
        scrollOffset = math.max(0, scrollOffset - 1)
    elseif lurek.input.isKeyDown("down") then
        scrollOffset = scrollOffset + 1
    end
end)

-- ============================================================
-- Render (world)
-- ============================================================

lurek.render(function()
    if lootSparkle then lootSparkle:draw() end
    if combatFlash then combatFlash:draw() end
end)

-- ============================================================
-- Render UI
-- ============================================================

local function renderHUD()
    local barW, barH, barX, barY = 200, 18, 20, 12
    lurek.render.drawRect(barX, barY, barW, barH, { color = {0.2, 0.0, 0.0, 1.0} })
    lurek.render.drawRect(barX, barY, math.floor(barW * hpBarDisplay.value), barH, { color = {0.1, 0.8, 0.2, 1.0} })
    lurek.render.drawText("HP: " .. math.max(0, player.hp) .. "/" .. player.maxHp, barX + 4, barY + 2, { color = {1, 1, 1, 1}, size = 12 })
    lurek.render.drawText("Gold: " .. player.gold, 240, 14, { color = {1.0, 0.85, 0.2, 1.0}, size = 14 })
    lurek.render.drawText("F" .. player.floor .. " R" .. player.room, 340, 14, { color = {0.7, 0.7, 0.7, 1.0}, size = 14 })
    local gs = getGearStats()
    lurek.render.drawText(string.format("DMG:%d DEF:%d SPD:%d", gs.damage, gs.defense, gs.speed), 440, 14, { color = {0.6, 0.6, 0.8, 1.0}, size = 12 })
end

local function renderEquipmentSidebar()
    local sx, sy = 600, 80
    lurek.render.drawText("== GEAR ==", sx, sy, { color = {0.8, 0.8, 0.6, 1.0}, size = 14 })
    sy = sy + 22
    local slots = { "weapon", "armor", "helm", "boots", "accessory" }
    local labels = { weapon = "Weapon", armor = "Armor", helm = "Helm", boots = "Boots", accessory = "Ring" }
    for _, slot in ipairs(slots) do
        local item  = player.equipment[slot]
        local label = labels[slot] .. ": "
        if item then
            lurek.render.drawText(label .. item.name, sx, sy, { color = item.rarity.color, size = 12 })
            lurek.render.drawText("  +" .. item.stat .. " " .. item.statKey, sx, sy + 14, { color = {0.5, 0.5, 0.5, 1.0}, size = 11 })
            sy = sy + 32
        else
            lurek.render.drawText(label .. "(empty)", sx, sy, { color = {0.4, 0.4, 0.4, 1.0}, size = 12 })
            sy = sy + 22
        end
    end
end

local function renderTitle()
    local alpha = 0.5 + 0.5 * math.sin(titleBlink * 3)
    lurek.render.drawText("LOOT RPG", 280, 180, { color = {1.0, 0.85, 0.2, 1.0}, size = 48 })
    lurek.render.drawText("Dungeon Crawler", 310, 240, { color = {0.7, 0.7, 0.7, 1.0}, size = 20 })
    lurek.render.drawText("Press SPACE to begin", 290, 340, { color = {1.0, 1.0, 1.0, alpha}, size = 18 })
    lurek.render.drawText("Controls: SPACE=action  E=equip  B=buy potion  ESC=quit", 160, 500, { color = {0.5, 0.5, 0.5, 1.0}, size = 14 })
end

local function renderCombat()
    renderHUD()
    lurek.render.drawText(combat.enemyName, 300, 80, { color = {1.0, 0.3, 0.3, 1.0}, size = 22 })

    local ePct = math.max(0, combat.enemyHp / combat.enemyMaxHp)
    lurek.render.drawRect(300, 110, 200, 16, { color = {0.3, 0.0, 0.0, 1.0} })
    lurek.render.drawRect(300, 110, math.floor(200 * ePct), 16, { color = {0.9, 0.2, 0.2, 1.0} })
    lurek.render.drawText(combat.enemyHp .. "/" .. combat.enemyMaxHp, 310, 112, { color = {1, 1, 1, 1}, size = 12 })

    local logY    = 160
    local startIdx = math.max(1, #combat.log - 11)
    for i = startIdx, #combat.log do
        local c = {0.8, 0.8, 0.8, 1.0}
        if string.find(combat.log[i], "You dealt")  then c = {0.3, 1.0, 0.3, 1.0} end
        if string.find(combat.log[i], "dealt") and not string.find(combat.log[i], "You") then c = {1.0, 0.4, 0.4, 1.0} end
        if string.find(combat.log[i], "defeated")   then c = {1.0, 0.85, 0.2, 1.0} end
        if string.find(combat.log[i], "slain")      then c = {1.0, 0.0, 0.0, 1.0} end
        lurek.render.drawText(combat.log[i], 50, logY, { color = c, size = 14 })
        logY = logY + 18
    end

    if combat.done then
        if combat.won then
            lurek.render.drawText("Victory! Press SPACE for loot", 250, 420, { color = {1.0, 0.85, 0.2, 1.0}, size = 18 })
        else
            lurek.render.drawText("Press SPACE to continue...", 270, 420, { color = {0.7, 0.7, 0.7, 1.0}, size = 18 })
        end
    else
        lurek.render.drawText("Press SPACE to attack", 290, 420, { color = {1.0, 1.0, 1.0, 0.7}, size = 16 })
    end
    renderEquipmentSidebar()
end

local function renderLoot()
    renderHUD()
    lurek.render.drawText("== LOOT FOUND ==", 300, 80, { color = {1.0, 0.85, 0.2, lootGlow.alpha}, size = 24 })

    local y = 130
    for _, item in ipairs(pendingLoot) do
        lurek.render.drawText(item.name, 200, y, { color = item.rarity.color, size = 16 })
        lurek.render.drawText(item.statKey .. ": +" .. item.stat .. "  wt: " .. item.weight, 460, y, { color = {0.7, 0.7, 0.7, 1.0}, size = 14 })
        y = y + 28
    end

    lurek.render.drawText("Press SPACE to collect & continue", 230, 360, { color = {0.8, 0.8, 0.8, 1.0}, size = 16 })
    lurek.render.drawText("Press E to collect & auto-equip",   240, 390, { color = {0.6, 0.8, 1.0, 1.0}, size = 16 })
    lurek.render.drawText("Backpack: " .. string.format("%.1f", backpackWeight()) .. " / " .. player.maxWeight .. " kg", 260, 430, { color = {0.5, 0.5, 0.5, 1.0}, size = 14 })
    renderEquipmentSidebar()
end

local function renderRoom()
    renderHUD()
    lurek.render.drawText("Floor " .. player.floor .. " — Room " .. player.room .. "/" .. player.roomsPerFloor, 260, 100, { color = {0.9, 0.9, 0.9, 1.0}, size = 22 })
    lurek.render.drawText("Press SPACE to enter next room", 260, 160, { color = {0.7, 0.7, 0.7, 1.0}, size = 16 })
    lurek.render.drawText("E = auto-equip best   B = buy potion (5g)", 210, 190, { color = {0.5, 0.5, 0.5, 1.0}, size = 14 })

    lurek.render.drawText("== BACKPACK ==", 50, 240, { color = {0.8, 0.8, 0.6, 1.0}, size = 16 })
    lurek.render.drawText(string.format("Weight: %.1f / %.1f", backpackWeight(), player.maxWeight), 50, 260, { color = {0.6, 0.6, 0.6, 1.0}, size = 12 })

    local y = 285
    local visible  = 10
    local startIdx = math.min(scrollOffset + 1, math.max(1, #player.backpack - visible + 1))
    for i = startIdx, math.min(startIdx + visible - 1, #player.backpack) do
        local item    = player.backpack[i]
        local equipped = (player.equipment[item.slot] == item)
        local prefix   = equipped and "[E] " or "    "
        lurek.render.drawText(prefix .. item.name, 50, y, { color = item.rarity.color, size = 13 })
        lurek.render.drawText(item.statKey .. ": +" .. item.stat, 280, y, { color = {0.6, 0.6, 0.6, 1.0}, size = 12 })
        y = y + 20
    end
    if #player.backpack > visible then
        lurek.render.drawText("Up/Down to scroll", 50, y + 10, { color = {0.4, 0.4, 0.4, 1.0}, size = 11 })
    end
    renderEquipmentSidebar()
end

local function renderGameOver()
    lurek.render.drawText("GAME OVER", 300, 140, { color = {1.0, 0.2, 0.2, 1.0}, size = 36 })
    local cleared = (player.floor - 1) * player.roomsPerFloor + player.room
    lurek.render.drawText("Floor: " .. player.floor .. "  Rooms cleared: " .. cleared, 240, 220, { color = {0.8, 0.8, 0.8, 1.0}, size = 16 })
    lurek.render.drawText("Gold: " .. player.gold, 350, 250, { color = {1.0, 0.85, 0.2, 1.0}, size = 16 })
    lurek.render.drawText("Items: " .. #player.backpack, 340, 280, { color = {0.7, 0.7, 0.7, 1.0}, size = 16 })
    local gs = getGearStats()
    lurek.render.drawText(string.format("Final stats — DMG:%d DEF:%d SPD:%d HP+:%d", gs.damage, gs.defense, gs.speed, gs.hpBonus), 180, 320, { color = {0.6, 0.6, 0.6, 1.0}, size = 14 })
    lurek.render.drawText("Press SPACE to return to title", 260, 400, { color = {1.0, 1.0, 1.0, 0.6}, size = 16 })
end

lurek.render_ui(function()
    local fps = lurek.timer.getFPS()
    lurek.render.drawText("FPS: " .. math.floor(fps), 720, 8, { color = {0.5, 0.5, 0.5, 1.0}, size = 12 })

    if state == STATE_TITLE     then renderTitle()
    elseif state == STATE_COMBAT   then renderCombat()
    elseif state == STATE_LOOT     then renderLoot()
    elseif state == STATE_ROOM     then renderRoom()
    elseif state == STATE_GAME_OVER then renderGameOver()
    end
end)
