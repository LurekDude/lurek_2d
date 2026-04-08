-- demos/showcase/pipeline_showcase/main.lua
-- Pipeline Showcase — demonstrates the full luna.scene + luna.entity + luna.ui
--   callback pipeline: ready, process, process_physics, process_late, render,
--   render_ui. Two scenes: a menu scene using GUI buttons and a simulation scene
--   using an ECS world that spawns and updates particles as entities.
-- Controls: Mouse to click buttons, ESC to go back to menu.
-- Run with: cargo run -- demos/showcase/pipeline_showcase

local W, H = 800, 600

-- ═══════════════════════════════════════════════════════════════════════════
-- ── MENU SCENE ─────────────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════

local MenuScene = {}
MenuScene.__index = MenuScene

function MenuScene.new()
    local self = setmetatable({}, MenuScene)
    self.btn_start  = nil
    self.btn_quit   = nil
    self.title_t    = 0   -- animation counter
    return self
end

function MenuScene:enter()
    luna.gfx.setBackgroundColor(0.06, 0.04, 0.14)
end

function MenuScene:ready()
    -- Called exactly once after the first process() tick — build GUI here.
    self.btn_start = luna.ui.newButton("► Start Simulation")
    self.btn_start:setPosition(W / 2 - 110, H / 2 - 30)
    self.btn_start:setSize(220, 44)
    self.btn_start:setOnClick(function()
        luna.scene.switchTo(SimScene.new(), nil, 0, nil)
    end)

    self.btn_quit = luna.ui.newButton("✕ Quit")
    self.btn_quit:setPosition(W / 2 - 70, H / 2 + 28)
    self.btn_quit:setSize(140, 36)
    self.btn_quit:setOnClick(function()
        luna.signal.quit()
    end)
end

function MenuScene:leave()
    -- Destroy GUI widgets when we leave (avoids dangling handles)
    if self.btn_start then self.btn_start:setVisible(false) end
    if self.btn_quit  then self.btn_quit:setVisible(false)  end
end

function MenuScene:process(dt)
    self.title_t = self.title_t + dt
    luna.ui.update(dt)
end

function MenuScene:render()
    local cx = W / 2
    local pulse = math.sin(self.title_t * 1.4) * 0.1 + 0.9

    luna.gfx.setColor(0.4 * pulse, 0.7 * pulse, 1.0)
    luna.gfx.print("PIPELINE SHOWCASE", cx - 148, H * 0.22, 3)

    luna.gfx.setColor(0.55, 0.55, 0.75)
    luna.gfx.print("luna.scene · luna.entity · luna.ui", cx - 148, H * 0.22 + 48, 1.3)
end

function MenuScene:render_ui()
    luna.ui.draw()

    luna.gfx.setColor(0.35, 0.35, 0.5)
    luna.gfx.print("Callbacks: ready  process  render  render_ui", 14, H - 22, 0.9)
end

-- GUI event forwarding
function MenuScene:mousepressed(x, y, btn)
    luna.ui.mousepressed(x, y, btn)
end

function MenuScene:mousereleased(x, y, btn)
    luna.ui.mousereleased(x, y, btn)
end

function MenuScene:mousemoved(x, y)
    luna.ui.mousemoved(x, y)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ── SIMULATION SCENE ───────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════

local SimScene = {}
SimScene.__index = SimScene

local MAX_PARTICLES = 120
local PHYSICS_TICK_LABEL_TTL = 0.6

function SimScene.new()
    local self = setmetatable({}, SimScene)
    self.world          = nil   -- luna.entity Universe
    self.physics_ticks  = 0     -- count this frame's physics steps
    self.late_calls     = 0     -- count late calls this second
    self.late_timer     = 0
    self.physics_label  = ""
    self.physics_label_ttl = 0
    self.spawn_timer    = 0
    self.lbl_status     = nil   -- GUI label widget
    self.btn_back       = nil
    return self
end

function SimScene:enter()
    luna.gfx.setBackgroundColor(0.04, 0.06, 0.10)
end

function SimScene:ready()
    -- One-time setup: ECS world + GUI
    self.world = luna.entity.newUniverse()

    -- Seed with a few particles
    for i = 1, 20 do
        self:_spawnParticle()
    end

    -- Status label (updated every frame in process_late)
    self.lbl_status = luna.ui.newLabel("…")
    self.lbl_status:setPosition(10, H - 30)
    self.lbl_status:setSize(W - 20, 24)

    self.btn_back = luna.ui.newButton("← Menu")
    self.btn_back:setPosition(W - 96, 8)
    self.btn_back:setSize(88, 30)
    self.btn_back:setOnClick(function()
        luna.scene.switchTo(MenuScene.new(), nil, 0, nil)
    end)
end

function SimScene:leave()
    if self.lbl_status then self.lbl_status:setVisible(false) end
    if self.btn_back    then self.btn_back:setVisible(false)   end
end

-- ── process: game logic ──────────────────────────────────────────────────

function SimScene:process(dt)
    -- Reset per-frame physics counter here so process_late can read it
    self.physics_ticks = 0
    self.spawn_timer = self.spawn_timer + dt

    if self.spawn_timer >= 0.25 then
        self.spawn_timer = 0
        local count = self.world:getEntityCount()
        if count < MAX_PARTICLES then
            self:_spawnParticle()
        end
    end

    luna.ui.update(dt)
end

-- ── process_physics: fixed-timestep ──────────────────────────────────────

function SimScene:process_physics(dt)
    self.physics_ticks = self.physics_ticks + 1

    -- Integrate each particle's velocity; bounce off walls
    local ids = self.world:getEntities()
    for _, id in ipairs(ids) do
        local pos = self.world:get(id, "pos")
        local vel = self.world:get(id, "vel")
        local radius = self.world:get(id, "radius") or 4

        if pos and vel then
            pos.x = pos.x + vel.vx * dt
            pos.y = pos.y + vel.vy * dt

            if pos.x - radius < 0 then
                pos.x = radius
                vel.vx = math.abs(vel.vx)
            elseif pos.x + radius > W then
                pos.x = W - radius
                vel.vx = -math.abs(vel.vx)
            end

            if pos.y - radius < 0 then
                pos.y = radius
                vel.vy = math.abs(vel.vy)
            elseif pos.y + radius > H - 40 then
                pos.y = H - 40 - radius
                vel.vy = -math.abs(vel.vy)
            end

            self.world:set(id, "pos", pos)
            self.world:set(id, "vel", vel)
        end
    end
end

-- ── process_late: post-logic, pre-render ─────────────────────────────────

function SimScene:process_late(dt)
    self.late_timer = self.late_timer + dt
    if self.late_timer >= 1.0 then
        self.late_timer = 0
        self.late_calls = 0
    end
    self.late_calls = self.late_calls + 1

    -- Update status label in process_late so it reflects the final state
    local count = self.world and self.world:getEntityCount() or 0
    local phys_dt = luna.time.getPhysicsDelta()
    local status = string.format(
        "entities: %d   physics_dt: %.4fs   ticks this frame: %d",
        count, phys_dt, self.physics_ticks
    )
    if self.lbl_status then
        self.lbl_status:setText(status)
    end
end

-- ── render: game world ───────────────────────────────────────────────────

function SimScene:render()
    if not self.world then return end

    local ids = self.world:getEntities()
    for _, id in ipairs(ids) do
        local pos    = self.world:get(id, "pos")
        local radius = self.world:get(id, "radius") or 4
        local color  = self.world:get(id, "color")

        if pos and color then
            luna.gfx.setColor(color.r, color.g, color.b, 0.85)
            -- Draw as filled circle via rectangle (approximate)
            local d = radius * 2
            luna.gfx.rect("fill", pos.x - radius, pos.y - radius, d, d)
        end
    end
end

-- ── render_ui: HUD overlay ───────────────────────────────────────────────

function SimScene:render_ui()
    -- Title banner
    luna.gfx.setColor(0.2, 0.4, 0.8, 0.9)
    luna.gfx.rect("fill", 0, 0, W, 44)
    luna.gfx.setColor(0.85, 0.9, 1.0)
    luna.gfx.print("Simulation Scene — ECS particles via process_physics", 10, 12, 1.1)

    -- Callback pipeline legend
    luna.gfx.setColor(0.3, 0.6, 0.3, 0.85)
    luna.gfx.rect("fill", 0, H - 44, W, 44)
    luna.gfx.setColor(0.8, 1.0, 0.8)
    luna.gfx.print(
        "process  →  process_physics (×N)  →  process_late  →  render  →  render_ui",
        10, H - 34, 0.95
    )

    luna.ui.draw()
end

-- GUI event forwarding
function SimScene:mousepressed(x, y, btn)
    luna.ui.mousepressed(x, y, btn)
end

function SimScene:mousereleased(x, y, btn)
    luna.ui.mousereleased(x, y, btn)
end

function SimScene:mousemoved(x, y)
    luna.ui.mousemoved(x, y)
end

-- ── internal helpers ─────────────────────────────────────────────────────

function SimScene:_spawnParticle()
    local id  = self.world:spawn()
    local r   = math.random(3, 9)
    local spd = math.random(40, 160)
    local ang = math.random() * math.pi * 2
    self.world:set(id, "pos",    { x = math.random(r, W - r), y = math.random(r, (H - 40) - r) })
    self.world:set(id, "vel",    { vx = math.cos(ang) * spd, vy = math.sin(ang) * spd })
    self.world:set(id, "radius", r)
    self.world:set(id, "color",  {
        r = math.random() * 0.6 + 0.4,
        g = math.random() * 0.6 + 0.2,
        b = math.random() * 0.8 + 0.2,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ── ENGINE CALLBACKS ───────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════

function luna.init()
    luna.window.setTitle("Pipeline Showcase")
    luna.scene.push(MenuScene.new())
end

-- Dispatched to active scene each frame
function luna.process_physics(dt)
    luna.scene.processPhysics(dt)
end

function luna.process(dt)
    luna.scene.process(dt)
end

function luna.process_late(dt)
    luna.scene.processLate(dt)
end

function luna.render()
    luna.scene.render()
end

function luna.render_ui()
    luna.scene.renderUi()
end

-- Input forwarded to active scene
function luna.keypressed(key)
    if key == "escape" then
        -- If we are on a non-menu scene, go back; otherwise quit
        luna.scene.pop()
    end
end

function luna.mousepressed(x, y, btn)
    local top = luna.scene.peek and luna.scene.peek()
    if top and top.mousepressed then top:mousepressed(x, y, btn) end
end

function luna.mousereleased(x, y, btn)
    local top = luna.scene.peek and luna.scene.peek()
    if top and top.mousereleased then top:mousereleased(x, y, btn) end
end

function luna.mousemoved(x, y)
    local top = luna.scene.peek and luna.scene.peek()
    if top and top.mousemoved then top:mousemoved(x, y) end
end
