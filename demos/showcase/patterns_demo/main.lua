-- Module availability guard (added by fix_nil_module_demos.py)
if not luna.patterns then
    function luna.init()
        luna.gfx.setBackgroundColor(0.08, 0.08, 0.12)
        luna.gfx.print("luna.patterns is not available in this build", 180, 270)
    end
    return
end

-- Patterns Demo — Luna2D example
-- Demonstrates the 6 design patterns: EventBus, ObjectPool, CommandStack,
-- ServiceLocator, Factory, SimpleState (FSM).

-- ===================================================================
-- Setup
-- ===================================================================
local bus   = luna.patterns.newEventBus()
local pool  = luna.patterns.newObjectPool()
local cmds  = luna.patterns.newCommandStack()
local loc   = luna.patterns.newServiceLocator()
local fac   = luna.patterns.newFactory()
local fsm   = luna.patterns.newSimpleState()

local log = {}
local function add_log(msg)
    table.insert(log, msg)
    if #log > 16 then table.remove(log, 1) end
end

-- ===================================================================
-- Wire up patterns
-- ===================================================================

-- EventBus: game events
bus:on("spawn", function(kind)
    add_log("EventBus: spawned " .. kind)
end, 0)

-- ObjectPool: bullet recycling
for i = 1, 5 do
    pool:add({ id = i, alive = false })
end

-- Factory: named constructors
fac:register("enemy", function(hp)
    return { kind = "enemy", hp = hp or 10, alive = true }
end)
fac:register("coin", function(value)
    return { kind = "coin", value = value or 1 }
end)

-- ServiceLocator: DI
loc:provide("score", { value = 0 })
loc:provide("difficulty", { level = 1 })

-- SimpleState: game FSM
fsm:addState("menu", {
    enter = function() add_log("FSM: entered menu") end,
    exit  = function() add_log("FSM: left menu") end,
})
fsm:addState("play", {
    enter  = function() add_log("FSM: game started!") end,
    exit   = function() add_log("FSM: game paused/ended") end,
    update = function(dt) end,
})
fsm:addState("gameover", {
    enter = function() add_log("FSM: game over!") end,
})

-- ===================================================================
-- Callbacks
-- ===================================================================
local x = 100

function luna.init()
    luna.window.setTitle("Patterns Demo")
    fsm:transitionTo("menu")
end

function luna.process(dt)
    fsm:update(dt)
end

function luna.render()
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print("Patterns Demo", 20, 20)
    luna.gfx.print("State: " .. (fsm:getCurrent() or "none"), 20, 40)
    luna.gfx.print("[1] Spawn enemy  [2] Acquire bullet  [3] Move +10", 20, 60)
    luna.gfx.print("[U] Undo  [R] Redo  [SPACE] Toggle play/menu  [G] Game over", 20, 78)

    local score = loc:locate("score")
    luna.gfx.print("Score: " .. (score and score.value or 0), 20, 100)
    luna.gfx.print("x = " .. x, 200, 100)
    luna.gfx.print("Pool: " .. pool:getAvailableCount() .. " avail / " .. pool:getActiveCount() .. " active", 20, 118)
    luna.gfx.print("History: " .. cmds:getHistorySize() .. " cmds", 300, 118)

    luna.gfx.setColor(0.7, 0.85, 1)
    for i, msg in ipairs(log) do
        luna.gfx.print(msg, 30, 140 + (i - 1) * 18)
    end
end

function luna.keypressed(key)
    if key == "1" then
        local e = fac:create("enemy", 25)
        bus:emit("spawn", e.kind)
        local score = loc:locate("score")
        if score then score.value = score.value + 5 end

    elseif key == "2" then
        local bullet = pool:acquire()
        if bullet then
            add_log("Pool: acquired bullet #" .. bullet.id)
        else
            add_log("Pool: empty!")
        end

    elseif key == "3" then
        local old = x
        cmds:execute("move",
            function() x = x + 10 end,
            function() x = x - 10 end)
        add_log("Cmd: move " .. old .. " -> " .. x)

    elseif key == "u" then
        if cmds:undo() then
            add_log("Cmd: undo -> x=" .. x)
        else
            add_log("Cmd: nothing to undo")
        end

    elseif key == "r" then
        if cmds:redo() then
            add_log("Cmd: redo -> x=" .. x)
        else
            add_log("Cmd: nothing to redo")
        end

    elseif key == "space" then
        local cur = fsm:getCurrent()
        if cur == "menu" then
            fsm:transitionTo("play")
        else
            fsm:transitionTo("menu")
        end

    elseif key == "g" then
        fsm:transitionTo("gameover")

    elseif key == "escape" then
        luna.signal.quit()
    end
end
