-- content/games/showcase/html-hud/main.lua
-- HTML HUD Demo â€” lurek.html showcase.
--
-- A player dot moves to the mouse cursor.  The HUD overlaid in pure HTML/CSS
-- shows a live health bar (slowly drains), a score counter, and a timer.
-- Demonstrates:  newDocument, getElementById, setStyle, setText, draw, update.

local hud
local health  = 100
local score   = 0
local timer   = 0
local px, py  = 400, 300

local HUD_HTML = [[
<div id="hud">
  <div class="row">
    <span class="label">HP</span>
    <div id="hp-bg"><div id="hp-bar"></div></div>
    <span id="hp-val">100</span>
  </div>
  <div class="row">
    <span class="label">Score</span>
    <span id="score-val">0</span>
  </div>
  <div class="row">
    <span class="label">Time</span>
    <span id="timer-val">0s</span>
  </div>
</div>
]]

local HUD_CSS = [[
* { margin:0; padding:0; box-sizing:border-box; }
body { font-family:sans-serif; }

#hud {
  position:absolute; top:16px; left:16px;
  display:flex; flex-direction:column; gap:8px;
  background:rgba(0,0,0,0.55); padding:12px 16px; border-radius:8px;
}
.row { display:flex; align-items:center; gap:8px; }
.label { color:#aaa; font-size:13px; width:46px; }
#hp-bg  { width:160px; height:14px; background:#444; border-radius:6px; overflow:hidden; }
#hp-bar { height:100%; width:100%; background:#2ecc71; transition:width 0.15s, background 0.3s; }
#hp-val, #score-val, #timer-val { color:#fff; font-size:14px; min-width:40px; }
]]

function lurek.load()
  hud = lurek.html.newDocument(HUD_HTML, {
    css    = HUD_CSS,
    width  = lurek.window.getWidth(),
    height = lurek.window.getHeight(),
  })
end

function lurek.update(dt)
  timer  = timer  + dt
  score  = score  + math.floor(dt * 150)
  health = math.max(0, health - dt * 4)

  local pct = health / 100
  local bar = hud:getElementById("hp-bar")
  if bar then
    bar:setStyle("width", math.floor(pct * 100) .. "%")
    local col = pct > 0.5 and "#2ecc71" or (pct > 0.25 and "#f39c12" or "#e74c3c")
    bar:setStyle("background", col)
  end

  local hv = hud:getElementById("hp-val")
  if hv then hv:setText(math.floor(health) .. "") end

  local sv = hud:getElementById("score-val")
  if sv then sv:setText(tostring(score)) end

  local tv = hud:getElementById("timer-val")
  if tv then tv:setText(math.floor(timer) .. "s") end

  hud:update(dt)

  if lurek.keyboard.isDown("escape") then lurek.event.quit() end
end

function lurek.draw()
  -- Background
  lurek.graphics.setColor(0.1, 0.12, 0.18, 1)
  lurek.graphics.rectangle("fill", 0, 0, lurek.window.getWidth(), lurek.window.getHeight())

  -- Player dot
  lurek.graphics.setColor(0.2, 0.65, 1, 1)
  lurek.graphics.circle("fill", px, py, 20)
  lurek.graphics.setColor(1, 1, 1, 0.4)
  lurek.graphics.circle("line", px, py, 20)

  -- HTML HUD on top
  hud:render()
end

function lurek.mousemoved(x, y)
  px, py = x, y
  hud:mousemoved(x, y)
end

function lurek.mousepressed(x, y, btn)
  hud:mousepressed(x, y, btn)
end

function lurek.mousereleased(x, y, btn)
  hud:mousereleased(x, y, btn)
end

function lurek.resize(w, h)
  hud:setViewport(w, h)
end
