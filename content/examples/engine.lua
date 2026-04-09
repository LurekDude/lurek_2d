-- examples/core-engine/main.lua
-- Core Engine Tour — every callback, Lua OOP methods, loops, and a fixed-rate physics tick.
-- Balls spawn under gravity, bounce off a ground platform, and vanish when they fall off-screen.
-- [Space] spawn ball | [Left-click] drop at cursor | [Esc] quit
-- Run: cargo run -- examples/core-engine

local world        -- physics World; created in lurek.init
local balls = {}   -- active Ball objects
local MAX   = 24   -- ball cap

-- ── Ball — table class demonstrating method (colon) syntax ───────────────────

local Ball = {}
Ball.__index = Ball

function Ball.new(w, x, y)
    local b = w:newCircleBody(x, y, 14, "dynamic")
    b:setRestitution(0.55)      -- how bouncy (0 = dead stop, 1 = elastic)
    b:setLinearDamping(0.06)    -- slight air resistance
    return setmetatable({
        body = b,
        r    = math.random() * 0.7 + 0.3,   -- random warm colour
        g    = math.random() * 0.5 + 0.2,
        bl   = math.random() * 0.4 + 0.1,
    }, Ball)
end

function Ball:pos()   return self.body:getX(), self.body:getY() end
function Ball:gone()  return self.body:getY() > lurek.window.getHeight() + 30 end

function Ball:draw()
    local x, y = self:pos()
    lurek.gfx.setColor(self.r,       self.g,       self.bl,       1)
    lurek.gfx.circle("fill", x, y, 14)
    lurek.gfx.setColor(self.r * 0.5, self.g * 0.5, self.bl * 0.5, 1)
    lurek.gfx.circle("line",  x, y, 14)
end

-- ── lurek.init — one-time startup ─────────────────────────────────────────────
function lurek.init()
    local w, h = lurek.window.getWidth(), lurek.window.getHeight()

    world = lurek.physics.newWorld(0, 500)       -- gravity 500 px/s² downward

    -- Static ground platform (a body + rectangular fixture)
    local ground = world:newBody(w / 2, h - 10, "static")
    world:addFixture(ground:getId(), "rectangle", 0, 0.4, 0.2, false, w, 20)

    -- Spawn first wave in a for loop
    for i = 1, 6 do
        balls[#balls + 1] = Ball.new(world, w * i / 7, 40 + i * 12)
    end

    lurek.log.info("core-engine: init — " .. #balls .. " balls created")
end

-- ── lurek.ready — after first frame is presented ───────────────────────────────
function lurek.ready()
    lurek.window.setTitle("Core Engine Tour — All Callbacks")
    lurek.log.info("core-engine: window ready")
end

-- ── lurek.process — variable-rate update; input polling and game logic ─────────
function lurek.process(dt)
    if lurek.keyboard.isDown("escape") then
        lurek.signal.quit()
    end
end

-- ── lurek.process_physics — FIXED timestep; advance the simulation here ────────
-- This runs at its own rate (e.g. 60 Hz) independent of the render frame rate.
function lurek.process_physics(dt)
    world:step(dt)
end

-- ── lurek.process_late — after physics; safe to read updated body positions ────
function lurek.process_late(dt)
    for i = #balls, 1, -1 do   -- backwards loop so removal doesn't skip items
        if balls[i]:gone() then
            table.remove(balls, i)
        end
    end
end

-- ── lurek.render — draw the game world ────────────────────────────────────────
function lurek.render()
    local w, h = lurek.window.getWidth(), lurek.window.getHeight()

    lurek.gfx.setColor(0.40, 0.30, 0.20, 1)
    lurek.gfx.rectangle("fill", 0, h - 20, w, 20)   -- ground

    for _, ball in ipairs(balls) do     -- ipairs loop over all active balls
        ball:draw()
    end
end

-- ── lurek.render_ui — HUD drawn on top of the world each frame ────────────────
function lurek.render_ui()
    local fps = lurek.time.getFPS()
    lurek.gfx.setColor(1, 1, 1, 0.9)
    lurek.gfx.print(string.format("Balls: %d / %d   FPS: %d", #balls, MAX, fps), 10, 10)
    lurek.gfx.print("[Space] spawn   [Click] drop at cursor   [Esc] quit",       10, 28)
end

-- ── Event callbacks ───────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "space" and #balls < MAX then
        local w = lurek.window.getWidth()
        balls[#balls + 1] = Ball.new(world, 50 + math.random(w - 100), 30)
    end
end

function lurek.mousepressed(x, y, btn)
    if btn == 1 and #balls < MAX then
        balls[#balls + 1] = Ball.new(world, x, y)
    end
end

function lurek.focus(focused)
    -- Window gained or lost keyboard focus — useful to pause/resume the game
    lurek.log.debug("core-engine: focus = " .. tostring(focused))
end
