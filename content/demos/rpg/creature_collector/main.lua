-- Creature Collector — Lurek2D Demo
-- WASD to walk, random encounters, catch creatures
-- Run with: cargo run -- content/demos/rpg/creature_collector

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local TILE = 32
local COLS, ROWS = 25, 18
local map = {}
local player = { gx = 12, gy = 9 }
local moveCD = 0
local stepCount = 0
local encounterRate = 10

-- creatures database
local creatureDB = {
    { name = "Flamepup",  type = "fire",  hp = 40, atk = 12, def = 5,  color = { 1, 0.3, 0.1 } },
    { name = "Aquafin",   type = "water", hp = 45, atk = 9,  def = 8,  color = { 0.2, 0.5, 1 } },
    { name = "Leafling",  type = "grass", hp = 42, atk = 10, def = 7,  color = { 0.2, 0.8, 0.2 } },
    { name = "Emberclaw", type = "fire",  hp = 55, atk = 15, def = 6,  color = { 0.9, 0.15, 0 } },
    { name = "Tidalink",  type = "water", hp = 50, atk = 11, def = 10, color = { 0.1, 0.3, 0.9 } },
    { name = "Thornvine", type = "grass", hp = 48, atk = 13, def = 9,  color = { 0.1, 0.6, 0.15 } },
}

local party = {}
local state = "overworld"  -- "overworld", "battle"
local battle = {}
local battleLog = ""
local battleChoice = 1

local typeAdv = { fire = "grass", grass = "water", water = "fire" }

local function makeCreature(template, level)
    level = level or 1
    return {
        name = template.name,
        type = template.type,
        maxHp = template.hp + level * 3,
        hp = template.hp + level * 3,
        atk = template.atk + level,
        def = template.def + level,
        color = template.color,
        level = level,
    }
end

local function genMap()
    -- Procedural tile map: randomised distribution of terrain types
    for y = 1, ROWS do
        map[y] = {}
        for x = 1, COLS do
            local r = math.random()
            if r < 0.06 then map[y][x] = "water"
            elseif r < 0.15 then map[y][x] = "tree"
            elseif r < 0.25 then map[y][x] = "tallgrass"  -- encounter zone
            else map[y][x] = "grass"
            end
        end
    end
    map[player.gy][player.gx] = "grass"
end

local tileColors = {
    grass     = { 0.3, 0.6, 0.2 },
    tallgrass = { 0.2, 0.5, 0.15 },
    water     = { 0.2, 0.35, 0.7 },
    tree      = { 0.15, 0.4, 0.1 },
}

local function startBattle()
    local tmpl = creatureDB[math.random(1, #creatureDB)]
    local lvl = math.random(1, 3)
    local wild = makeCreature(tmpl, lvl)
    battle = {
        wild = wild,
        activeIdx = 1,
        turn = "player", -- "player", "enemy", "result"
        result = "",
    }
    battleLog = "A wild " .. wild.name .. " (Lv" .. lvl .. ") appeared!"
    battleChoice = 1
    state = "battle"
end

local function getMultiplier(atkType, defType)
    -- Type triangle: fire beats grass, grass beats water, water beats fire
    if typeAdv[atkType] == defType then return 1.5 end
    if typeAdv[defType] == atkType then return 0.6 end
    return 1.0
end

local function doAttack(attacker, defender)
    local mult = getMultiplier(attacker.type, defender.type)
    local dmg = math.floor(clamp(attacker.atk * mult - defender.def * 0.5, 1, 999))
    defender.hp = clamp(defender.hp - dmg, 0, defender.maxHp)
    return dmg, mult
end

function lurek.init()
    lurek.window.setTitle("Creature Collector")
    lurek.gfx.setBackgroundColor(0.05, 0.08, 0.05)
    genMap()
    -- starter creature
    party[1] = makeCreature(creatureDB[1], 3)
end

function lurek.process(dt)
    if state == "overworld" then
        moveCD = moveCD - dt
        if moveCD <= 0 then
            local dx, dy = 0, 0
            if lurek.keyboard.isDown("w") then dy = -1
            elseif lurek.keyboard.isDown("s") then dy = 1
            elseif lurek.keyboard.isDown("a") then dx = -1
            elseif lurek.keyboard.isDown("d") then dx = 1
            end
            if dx ~= 0 or dy ~= 0 then
                local nx, ny = player.gx + dx, player.gy + dy
                if nx >= 1 and nx <= COLS and ny >= 1 and ny <= ROWS then
                    local t = map[ny][nx]
                    if t ~= "water" and t ~= "tree" then
                        player.gx, player.gy = nx, ny
                        moveCD = 0.13
                        stepCount = stepCount + 1
                        if t == "tallgrass" and stepCount >= encounterRate then
                            stepCount = 0
                            startBattle()
                        end
                    end
                end
            end
        end
    end
end

function lurek.render()
    if state == "overworld" then
        -- map
        for y = 1, ROWS do
            for x = 1, COLS do
                local t = map[y][x]
                local c = tileColors[t] or tileColors.grass
                lurek.gfx.setColor(c[1], c[2], c[3], 1)
                lurek.gfx.rectangle("fill", (x - 1) * TILE, (y - 1) * TILE, TILE - 1, TILE - 1)
            end
        end

        -- player
        lurek.gfx.setColor(1, 0.85, 0.2, 1)
        lurek.gfx.circle("fill", (player.gx - 0.5) * TILE, (player.gy - 0.5) * TILE, 12)

        -- HUD
        lurek.gfx.setColor(0, 0, 0, 0.6)
        lurek.gfx.rectangle("fill", 0, ROWS * TILE, 800, 40)
        lurek.gfx.setColor(1, 1, 1, 1)
        local partyStr = "Party: "
        for i, c in ipairs(party) do
            partyStr = partyStr .. c.name .. "(HP:" .. c.hp .. "/" .. c.maxHp .. ") "
        end
        lurek.gfx.print(partyStr, 10, ROWS * TILE + 5)
        lurek.gfx.print("Steps to encounter: ~" .. (encounterRate - stepCount), 10, ROWS * TILE + 22)

    elseif state == "battle" then
        local active = party[battle.activeIdx]
        local wild = battle.wild

        -- background
        lurek.gfx.setColor(0.1, 0.15, 0.1, 1)
        lurek.gfx.rectangle("fill", 0, 0, 800, 600)

        -- wild creature (right)
        lurek.gfx.setColor(wild.color[1], wild.color[2], wild.color[3], 1)
        lurek.gfx.circle("fill", 580, 180, 45)
        lurek.gfx.setColor(1, 1, 1, 1)
        lurek.gfx.print(wild.name .. " Lv" .. wild.level .. " [" .. wild.type .. "]", 500, 100)
        -- hp bar
        lurek.gfx.setColor(0.3, 0.3, 0.3, 1)
        lurek.gfx.rectangle("fill", 500, 130, 160, 12)
        local whp = clamp(wild.hp / wild.maxHp, 0, 1)
        lurek.gfx.setColor(1 - whp, whp, 0.1, 1)
        lurek.gfx.rectangle("fill", 500, 130, 160 * whp, 12)
        lurek.gfx.setColor(1, 1, 1, 1)
        lurek.gfx.print(wild.hp .. "/" .. wild.maxHp, 520, 145)

        -- player creature (left)
        if active then
            lurek.gfx.setColor(active.color[1], active.color[2], active.color[3], 1)
            lurek.gfx.circle("fill", 200, 350, 45)
            lurek.gfx.setColor(1, 1, 1, 1)
            lurek.gfx.print(active.name .. " Lv" .. active.level .. " [" .. active.type .. "]", 100, 270)
            lurek.gfx.setColor(0.3, 0.3, 0.3, 1)
            lurek.gfx.rectangle("fill", 100, 300, 160, 12)
            local php = clamp(active.hp / active.maxHp, 0, 1)
            lurek.gfx.setColor(1 - php, php, 0.1, 1)
            lurek.gfx.rectangle("fill", 100, 300, 160 * php, 12)
            lurek.gfx.setColor(1, 1, 1, 1)
            lurek.gfx.print(active.hp .. "/" .. active.maxHp, 120, 315)
        end

        -- battle log
        lurek.gfx.setColor(0, 0, 0, 0.7)
        lurek.gfx.rectangle("fill", 20, 440, 760, 50)
        lurek.gfx.setColor(1, 1, 0.7, 1)
        lurek.gfx.print(battleLog, 30, 450)

        -- menu
        if battle.turn == "player" then
            local opts = { "Attack", "Capture", "Run" }
            lurek.gfx.setColor(0, 0, 0, 0.8)
            lurek.gfx.rectangle("fill", 20, 500, 760, 90)
            for i, opt in ipairs(opts) do
                if i == battleChoice then
                    lurek.gfx.setColor(1, 1, 0.3, 1)
                    lurek.gfx.print("> " .. opt, 30 + (i - 1) * 200, 530)
                else
                    lurek.gfx.setColor(0.7, 0.7, 0.7, 1)
                    lurek.gfx.print("  " .. opt, 30 + (i - 1) * 200, 530)
                end
            end
        elseif battle.turn == "result" then
            lurek.gfx.setColor(0, 0, 0, 0.8)
            lurek.gfx.rectangle("fill", 20, 500, 760, 90)
            lurek.gfx.setColor(0.3, 1, 0.5, 1)
            lurek.gfx.print(battle.result, 30, 520)
            lurek.gfx.setColor(0.7, 0.7, 0.7, 1)
            lurek.gfx.print("Press SPACE to continue", 30, 550)
        end
    end
end

local function enemyTurn()
    local active = party[battle.activeIdx]
    if not active or active.hp <= 0 then return end
    local dmg, mult = doAttack(battle.wild, active)
    local effStr = mult > 1 and " Super effective!" or (mult < 1 and " Not very effective..." or "")
    battleLog = battle.wild.name .. " attacks for " .. dmg .. " dmg!" .. effStr
    if active.hp <= 0 then
        battleLog = battleLog .. " " .. active.name .. " fainted!"
        -- find next alive
        local found = false
        for i = 1, #party do
            if party[i].hp > 0 then battle.activeIdx = i; found = true; break end
        end
        if not found then
            battle.turn = "result"
            battle.result = "All creatures fainted... You blacked out!"
        end
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end

    if state == "battle" then
        if battle.turn == "player" then
            if key == "left" then battleChoice = clamp(battleChoice - 1, 1, 3) end
            if key == "right" then battleChoice = clamp(battleChoice + 1, 1, 3) end
            if key == "space" or key == "return" then
                local active = party[battle.activeIdx]
                if battleChoice == 1 then -- Attack
                    local dmg, mult = doAttack(active, battle.wild)
                    local effStr = mult > 1 and " Super effective!" or (mult < 1 and " Not very effective..." or "")
                    battleLog = active.name .. " attacks for " .. dmg .. " dmg!" .. effStr
                    if battle.wild.hp <= 0 then
                        battle.turn = "result"
                        battle.result = "You defeated " .. battle.wild.name .. "! " .. active.name .. " gains experience."
                        active.atk = active.atk + 1
                        active.maxHp = active.maxHp + 2
                        active.hp = clamp(active.hp + 5, 0, active.maxHp)
                    else
                        battle.turn = "enemy"
                    end
                elseif battleChoice == 2 then -- Capture
                    if #party >= 3 then
                        battleLog = "Party is full! (max 3)"
                    else
                        local chance = 0.3 + 0.5 * (1 - battle.wild.hp / battle.wild.maxHp)
                        if math.random() < chance then
                            local caught = makeCreature(battle.wild, battle.wild.level)
                            caught.hp = battle.wild.hp
                            table.insert(party, caught)
                            battle.turn = "result"
                            battle.result = "Caught " .. caught.name .. "! Added to party."
                        else
                            battleLog = "Capture failed!"
                            battle.turn = "enemy"
                        end
                    end
                elseif battleChoice == 3 then -- Run
                    if math.random() < 0.7 then
                        state = "overworld"
                        battleLog = ""
                        return
                    else
                        battleLog = "Couldn't escape!"
                        battle.turn = "enemy"
                    end
                end
            end
        elseif battle.turn == "enemy" then
            enemyTurn()
            if battle.turn ~= "result" then battle.turn = "player" end
        elseif battle.turn == "result" then
            if key == "space" then
                state = "overworld"
            end
        end
    end
end
