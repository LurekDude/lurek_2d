-- demos/showcase/pipeline_showcase/main.lua
-- Pipeline Showcase — demonstrates the full luna.scene + luna.entity + luna.ui
--   callback pipeline: ready, process, process_physics, process_late, render,
--   render_ui. Uses luna.scene.define() for clean scene class creation.
-- Controls: Mouse to click buttons, ESC to go back.
-- Run with: cargo run -- demos/showcase/pipeline_showcase

local W, H = 800, 600

-- ═══════════════════════════════════════════════════════════════════════════
-- ── MENU SCENE ─────────────────────────────────────────────────════════════
-- ═══════════════════════════════════════════════════════════════════════════

-- luna.scene.define() returns a constructor function — call MenuScene() to instantiate.
local MenuScene = luna.scene.define({})

function MenuScene:enter()
    luna.gfx.setBackgroundColor(0.07, 0.08, 0.14)

    self.btn_start = luna.ui.newButton("▶ Start Simulation")
    self.btn_start:setPosition(W / 2 - 110, H / 2 - 30)
    self.btn_start:setSize(220, 44)
    self.btn_start:setOnClick(function()
        luna.scene.switchTo(SimScene(), nil, 0, nil)
    end)

    self.btn_quit = luna.ui.newButton("✕ Quit")
    self.btn_quit:setPosition(W / 2 - 70, H / 2 + 28)
    self.btn_quit:setSize(140, 36)
    self.btn_quit:setOnClick(function()
        luna.signal.quit()
    end)
end

function MenuScene:leave()
    if self.btn_start then self.btn_start:setVisible(false) end
    if self.btn_quit  then self.btn_quit:setVisible(false)  end
end

function MenuScene:process(dt)
    self.title_t = (self.title_t or 0) + dt
    luna.ui.update(dt)
end

function MenuScene:render()
    local cx    = W / 2
    local pulse = math.sin((self.title_t or 0) * 1.4) * 0.1 + 0.9

    luna.gfx.setColor(0.4 * pulse, 0.7 * pulse, 1.0)
    luna.gfx.print("PIPELINE SHOWCASE", cx - 148, H * 0.22, 3)

    luna.gfx.setColor(0.55, 0.55, 0.75)
    luna.gfx.print("luna.scene.define · luna.entity · luna.ui", cx - 148, H * 0.22 + 48, 1.3)
end

function MenuScene:render_ui()
    luna.ui.draw()
end

function MenuScene:mousepressed(x, y, btn)  luna.ui.mousepressed(x, y, btn)  end
function MenuScene:mousereleased(x, y, btn) luna.ui.mousereleased(x, y, btn) end
function MenuScene:mousemoved(x, y)         luna.ui.mousemoved(x, y)         end

-- ═══════════════════════════════════════════════════════════════════════════
-- ── SIMULATION SCENE ────────────────────────────────────────────════════════
-- ═══════════════════════════════════════════════════════════════════════════

-- SimScene — all 6 pipeline callbacks; uses luna.entity Universe for ECS particles.
local SimScene = luna.scene.define({})

local MAX_PARTICLES = 120

function SimScene:enter()
    luna.gfx.setBackgroundColor(0.04, 0.06, 0.10)
end

function SimScene:ready()
    self.world         = luna.entity.newUniverse()
    self.physics_ticks = 0
    self.spawn_timer   = 0
    self.late_calls    = 0
    self.late_timer    = 0

    for _ = 1, 20 do self:_spawnParticle() end

    self.lbl_status = luna.ui.newLabel("")
    self.lbl_status:setPosition(10, H - 80)
    self.lbl_status:setSize(W - 20, 22)

    self.btn_back = luna.ui.newButton("← Menu")
    self.btn_back:setPosition(W - 110, 6)
    self.btn_back:setSize(100, 32)
    self.btn_back:setOnClick(function()
        luna.scene.switchTo(MenuScene(), nil, 0, nil)
    end)
end

function SimScene:leave()
    if self.lbl_status then self.lbl_status:setVisible(false) end
    if self.btn_back    then self.btn_back:setVisible(false)   end
end

-- ── process: game logic ─────────────────────────────────────────────────────

function SimScene:process(dt)
    self.physics_ticks = 0
    self.spawn_timer = (self.spawn_timer or 0) + dt
    if self.spawn_timer >= 0.25 then
        self.spawn_timer = 0
        if self.world:getEntityCount() < MAX_PARTICLES then
            self:_spawnParticle()
        end
    end
    luna.ui.update(dt)
end

-- ── process_physics: fixed-timestep ECS update ──────────────────────────────

function SimScene:process_physics(dt)
    self.physics_ticks = (self.physics_ticks or 0) + 1
    if not self.world then return end

    local ids = self.world:getEntities()
    for _, id in ipairs(ids) do
        local pos = self.world:get(id, "pos")
        local vel = self.world:get(id, "vel")
        if pos and vel then
            pos.x = pos.x + vel.x * dt
            pos.y = pos.y + vel.y * dt

            -- Bounce off walls
            local radius = self.world:get(id, "radius") or 4
            if pos.x - radius < 0   then pos.x = radius;     vel.x = math.abs(vel.x)  end
            if pos.x + radius > W   then pos.x = W - radius; vel.x = -math.abs(vel.x) end
            if pos.y - radius < 50  then pos.y = 50 + radius; vel.y = math.abs(vel.y) end
            if pos.y + radius > H - 50 then pos.y = H - 50 - radius; vel.y = -math.abs(vel.y) end

            self.world:set(id, "pos", pos)
            self.world:set(id, "vel", vel)
        end
    end
end

-- ── process_late: post-logic, pre-render ────────────────────────────────────

function SimScene:process_late(dt)
    local count   = self.world and self.world:getEntityCount() or 0
    local phys_dt = luna.time.getPhysicsDelta()
    local status  = string.format(
        "entities: %d   physics_dt: %.4fs   ticks this frame: %d",
        count, phys_dt, self.physics_ticks
    )
    if self.lbl_status then self.lbl_status:setText(status) end
end

-- ── render: game world ──────────────────────────────────────────────────────

function SimScene:render()
    if not self.world then return end
    for _, id in ipairs(self.world:getEntities()) do
        local pos    = self.world:get(id, "pos")
        local radius = self.world:get(id, "radius") or 4
        local color  = self.world:get(id, "color")
        if pos and color then
            luna.gfx.setColor(color.r, color.g, color.b, 0.85)
            local d = radius * 2
            luna.gfx.rect("fill", pos.x - radius, pos.y - radius, d, d)
        end
    end
end

-- ── render_ui: HUD overlay ──────────────────────────────────────────────────

function SimScene:render_ui()
    luna.gfx.setColor(0.2, 0.4, 0.8, 0.9)
    luna.gfx.rect("fill", 0, 0, W, 44)
    luna.gfx.setColor(0.85, 0.9, 1.0)
    luna.gfx.print("Simulation Scene — ECS particles via process_physics", 10, 12, 1.1)

    luna.gfx.setColor(0.3, 0.6, 0.3, 0.85)
    luna.gfx.rect("fill", 0, H - 44, W, 44)
    luna.gfx.setColor(0.8, 1.0, 0.8)
    luna.gfx.print(
        "process  →  process_physics (×N)  →  process_late  →  render  →  render_ui",
        10, H - 34, 0.95
    )

    luna.ui.draw()
end

function SimScene:mousepressed(x, y, btn)  luna.ui.mousepressed(x, y, btn)  end
function SimScene:mousereleased(x, y, btn) luna.ui.mousereleased(x, y, btn) end
function SimScene:mousemoved(x, y)         luna.ui.mousemoved(x, y)         end

-- ── Internal: spawn one particle entity ─────────────────────────────────────

function SimScene:_spawnParticle()
    if not self.world then return end
    local id = self.world:newEntity()
    self.world:set(id, "pos",    { x = math.random(20, W - 20), y = math.random(60, H - 60) })
    self.world:set(id, "vel",    { x = math.random(-120, 120),  y = math.random(-120, 120)  })
    self.world:set(id, "radius", math.random(3, 8))
    self.world:set(id, "color",  {
        r = math.random() * 0.6 + 0.4,
        g = math.random() * 0.6 + 0.4,
        b = math.random() * 0.6 + 0.4,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ── ENGINE CALLBACKS ───────────────────────────────────────────════════════
-- ═══════════════════════════════════════════════════════════════════════════

function luna.init()
    luna.window.setTitle("Pipeline Showcase")
    luna.scene.push(MenuScene())   -- instantiate via luna.scene.define()
end

-- Dispatch pipeline callbacks to the active scene
function luna.process_physics(dt) luna.scene.processPhysics(dt) end
function luna.process(dt)         luna.scene.process(dt)        end
function luna.process_late(dt)    luna.scene.processLate(dt)    end
function luna.render()            luna.scene.render()           end
function luna.render_ui()         luna.scene.renderUi()         end

function luna.keypressed(key)
    if key == "escape" then
        if luna.scene.getStackSize() > 1 then
            luna.scene.pop()
        end
    end
end

function luna.mousepressed(x, y, btn)
    local scene = luna.scene.getCurrent()
    if scene and scene.mousepressed then scene:mousepressed(x, y, btn) end
end

function luna.mousereleased(x, y, btn)
    local scene = luna.scene.getCurrent()
    if scene and scene.mousereleased then scene:mousereleased(x, y, btn) end
end

function luna.mousemoved(x, y, dx, dy)
    local scene = luna.scene.getCurrent()
    if scene and scene.mousemoved then scene:mousemoved(x, y) end
end
