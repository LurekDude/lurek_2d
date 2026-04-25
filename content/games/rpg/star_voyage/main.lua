-- ============================================================================
-- Star Voyage — Lurek2D
-- ============================================================================
-- Category : rpg
-- Source   : content/games/rpg/star_voyage/main.lua
-- Run with : cargo run -- content/games/rpg/star_voyage
-- ============================================================================
-- Space exploration RPG inspired by Star Control 2 (PC 1994).
-- Navigate a starfield, dock at alien worlds, and hold branching dialog.
-- Controls: WASD/Arrows thrust+turn, Space interact, Escape quit
-- ============================================================================

local dialog = require("library.dialog")

local W, H = 960, 540

-- ── Stars (parallax background) ───────────────────────────────────────────
local STAR_COUNT = 180
local stars      = {}

-- ── Ship physics ──────────────────────────────────────────────────────────
local THRUST      = 140
local ROT_SPEED   = 2.4
local DRAG        = 0.985
local DOCK_DIST   = 45

-- ── Planets ───────────────────────────────────────────────────────────────
local planets = {
    { name="Vela Prime",  x=300, y=180, r=26, color={0.9,0.5,0.2}, visited=false,
      dialog = {
          { node="line", speaker="Velan", text="Greetings, traveller. You approach Vela Prime." },
          { node="choice", options={"What do you trade?", "Tell me of the galaxy."} },
          { node="call", fn=function(c)
              if c==1 then
                  return {{ node="line", speaker="Velan", text="We deal in rare minerals from the outer belt." }}
              else
                  return {{ node="line", speaker="Velan", text="A darkness spreads beyond the Rim. Beware." }}
              end
          end },
      }
    },
    { name="Keth Station", x=660, y=120, r=20, color={0.4,0.8,0.9}, visited=false,
      dialog = {
          { node="line", speaker="Commander Keth", text="Station Keth welcomes you. Fuel is scarce." },
          { node="line", speaker="Commander Keth", text="The Ur-Quan have been spotted near the nebula." },
      }
    },
    { name="Myrrh World",  x=200, y=390, r=30, color={0.3,0.8,0.35}, visited=false,
      dialog = {
          { node="line", speaker="Elder", text="We are a peaceful people. Why do you disturb us?" },
          { node="choice", options={"We seek allies.", "We mean no harm."} },
          { node="call", fn=function(c)
              if c==1 then
                  return {{ node="line", speaker="Elder", text="Then prove it. Drive off the pirates near Keth." }}
              else
                  return {{ node="line", speaker="Elder", text="Then go in peace, stranger." }}
              end
          end },
      }
    },
    { name="Debris Field", x=750, y=380, r=18, color={0.6,0.6,0.6}, visited=false,
      dialog = {
          { node="line", speaker="Signal Beacon", text="Automated distress signal: vessel disabled. No survivors." },
      }
    },
    { name="Homeworld",   x=480, y=270, r=35, color={0.2,0.4,0.9}, visited=false,
      dialog = {
          { node="line", speaker="Admiral", text="Commander, you have returned! Report your findings." },
          { node="choice", options={"Vela trades minerals.", "Keth warns of Ur-Quan.", "Myrrh wants help."} },
          { node="call", fn=function(c)
              local t = {
                  "Noted. We will seek trade routes.",
                  "Alert! Mobilise the fleet.",
                  "Dispatch a patrol to Keth. Well done.",
              }
              return {{ node="line", speaker="Admiral", text=t[c] or "Understood." }}
          end },
      }
    },
}

-- ── State ─────────────────────────────────────────────────────────────────
local STATE = { SPACE = 1, DIALOG = 2 }
local state = STATE.SPACE

local ship = { x=W/2, y=H/2, vx=0, vy=0, angle=0 }
local fuel   = 100
local active_planet = nil

-- Dialog sequencer
local seq          = nil ---@type any
local dlg_line     = ""
local dlg_speaker  = ""
local dlg_choices  = {}

-- Camera offset (world-space)
local cam_x, cam_y = 0, 0
local WORLD_W, WORLD_H = 1400, 1000

-- ── Helpers ───────────────────────────────────────────────────────────────
local function world_to_screen(wx, wy)
    return wx - cam_x + W/2, wy - cam_y + H/2
end
local function dist2(ax,ay,bx,by) return (ax-bx)^2+(ay-by)^2 end

-- ── Load ──────────────────────────────────────────────────────────────────
-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("Star Voyage — Lurek2D")
    lurek.render.setBackgroundColor(0.02, 0.02, 0.08)

    local rng = lurek.math.newRandomGenerator(99)
    for i = 1, STAR_COUNT do
        stars[i] = {
            wx = rng:random() * WORLD_W,
            wy = rng:random() * WORLD_H,
            r  = rng:random() * 1.8 + 0.6,
            br = 0.4 + rng:random() * 0.6,
            layer = rng:randomInt(1,3),  -- parallax depth
        }
    end
end

local function start_dialog(planet)
    active_planet = planet
    state = STATE.DIALOG
    seq = dialog.newSequencer()
    seq:setSpeed(28)
    seq:on("line", function(speaker, text)
        dlg_speaker = speaker
        dlg_line    = text
        dlg_choices = {}
    end)
    seq:on("choice", function(opts)
        dlg_choices = opts
    end)
    seq:load(planet.dialog)
    seq:start()
    planet.visited = true
end

-- ── Update ────────────────────────────────────────────────────────────────
function lurek.update(dt)
    if state == STATE.DIALOG then
        seq:update(dt)
        return
    end

    -- Ship controls
    if lurek.input.isActionDown("a") or lurek.input.isActionDown("left") then
        ship.angle = ship.angle - ROT_SPEED * dt
    end
    if lurek.input.isActionDown("d") or lurek.input.isActionDown("right") then
        ship.angle = ship.angle + ROT_SPEED * dt
    end
    if lurek.input.isActionDown("w") or lurek.input.isActionDown("up") then
        ship.vx = ship.vx + math.cos(ship.angle) * THRUST * dt
        ship.vy = ship.vy + math.sin(ship.angle) * THRUST * dt
        fuel = math.max(0, fuel - dt * 2)
    end

    ship.vx = ship.vx * DRAG
    ship.vy = ship.vy * DRAG

    -- World-wrap
    ship.x = (ship.x + ship.vx*dt) % WORLD_W
    ship.y = (ship.y + ship.vy*dt) % WORLD_H

    -- Camera tracks ship
    cam_x = ship.x
    cam_y = ship.y

    -- Check proximity to planets for dock prompt
    active_planet = nil
    for _, p in ipairs(planets) do
        if dist2(ship.x, ship.y, p.x, p.y) < (DOCK_DIST + p.r)^2 then
            active_planet = p
        end
    end
end

-- ── Draw ──────────────────────────────────────────────────────────────────
function lurek.draw()
    -- Stars (layered parallax)
    for _, s in ipairs(stars) do
        local px = (s.wx - cam_x * (0.2 + s.layer * 0.15)) % W
        local py = (s.wy - cam_y * (0.2 + s.layer * 0.15)) % H
        lurek.render.setColor(s.br, s.br, s.br)
        circ("fill", px, py, s.r)
    end

    -- Planets
    for _, p in ipairs(planets) do
        local sx, sy = world_to_screen(p.x, p.y)
        -- only draw if roughly on screen
        if sx > -80 and sx < W+80 and sy > -80 and sy < H+80 then
            lurek.render.setColor(p.color[1] * 0.4, p.color[2] * 0.4, p.color[3] * 0.4)
            circ("fill", sx, sy, p.r + 6)    -- atmosphere glow
            lurek.render.setColor(p.color[1], p.color[2], p.color[3])
            circ("fill", sx, sy, p.r)
            if p.visited then
                lurek.render.setColor(0.5, 1, 0.5, 0.7)
                circ("line", sx, sy, p.r + 3)
            end
            lurek.render.setColor(1, 1, 1, 0.9)
            text_(p.name, sx - 35, sy + p.r + 4)
        end
    end

    -- Ship
    local ss_x, ss_y = world_to_screen(ship.x, ship.y)
    local SA  = ship.angle
    local SZ  = 12
    lurek.render.setColor(0.8, 0.9, 1)
    -- Simple triangle ship
    lurek.render.polygon("fill",
        ss_x + math.cos(SA)*SZ,     ss_y + math.sin(SA)*SZ,
        ss_x + math.cos(SA+2.4)*SZ*0.6, ss_y + math.sin(SA+2.4)*SZ*0.6,
        ss_x + math.cos(SA-2.4)*SZ*0.6, ss_y + math.sin(SA-2.4)*SZ*0.6
    )

    -- Dock prompt
    if active_planet and state == STATE.SPACE then
        lurek.render.setColor(1, 1, 0, 0.9)
        text_("Press Space to dock at " .. active_planet.name, W/2 - 140, H - 44)
    end

    -- HUD
    lurek.render.setColor(0, 0, 0, 0.55)
    rect("fill", 0, 0, W, 26)
    lurek.render.setColor(0.4, 0.8, 1)
    text_(string.format("Fuel: %d%%   Pos: (%d,%d)", math.floor(fuel), math.floor(ship.x), math.floor(ship.y)), 10, 5)
    local visited = 0; for _, p in ipairs(planets) do if p.visited then visited = visited + 1 end end
    text_(string.format("Worlds visited: %d / %d", visited, #planets), W - 220, 5)

    -- Dialog overlay
    if state == STATE.DIALOG then
        lurek.render.setColor(0.04, 0.06, 0.18, 0.92)
        rect("fill", 20, H - 160, W - 40, 148)
        lurek.render.setColor(0.4, 0.7, 1)
        rect("line", 20, H - 160, W - 40, 148)
        -- Portrait placeholder
        if active_planet then
            local pc = active_planet.color
            lurek.render.setColor(pc[1], pc[2], pc[3])
            circ("fill", 58, H - 94, 30)
        end
        lurek.render.setColor(0.4, 0.7, 1)
        text_(dlg_speaker, 96, H - 152)
        lurek.render.setColor(0.9, 0.9, 1)
        text_(dlg_line, 96, H - 130, { 0, 1, 1, 0 })
        -- Choices
        if #dlg_choices > 0 then
            for i, opt in ipairs(dlg_choices) do
                lurek.render.setColor(1, 1, 0)
                text_(i .. ". " .. opt, 96, H - 130 + (i-1)*20 + 16)
            end
            lurek.render.setColor(0.5, 0.5, 0.5)
            text_("[1/2/3] choose", W - 180, H - 26)
        else
            lurek.render.setColor(0.5, 0.5, 0.5)
            text_("[Space] continue", W - 200, H - 26)
        end
    end
end

-- ── Keypressed ────────────────────────────────────────────────────────────
function lurek._keypressed(key)
    if key == "escape" then lurek.event.quit() end
    if state == STATE.SPACE then
        if key == "space" and active_planet then
            start_dialog(active_planet)
        end
    elseif state == STATE.DIALOG then
        if key == "space" or key == "return" then
            if #dlg_choices == 0 then
                local ok = seq:advance()
                if not ok then state = STATE.SPACE end
            end
        end
        for i = 1, 3 do
            if key == tostring(i) and dlg_choices[i] then
                seq:choose(i)
                dlg_choices = {}
            end
        end
    end
end
