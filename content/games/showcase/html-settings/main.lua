-- content/games/showcase/html-settings/main.lua
-- HTML Settings Demo â€” lurek.html showcase.
--
-- A full settings screen built in HTML with form-style widgets: toggles,
-- radio groups, and a range-slider-style widget (CSS custom element).
-- Changes are read back from the DOM and applied live.
-- Demonstrates: checkbox/radio handling, two-way DOM binding, setStyle.

local settings_doc
local settings = {
  fullscreen     = false,
  vsync          = true,
  music_vol      = 70,
  sfx_vol        = 85,
  quality        = "high",
}

local CSS = [[
* { margin:0; padding:0; box-sizing:border-box; font-family:sans-serif; }
body {
  background:#121220; color:#ddd;
  display:flex; justify-content:center; align-items:center; height:100%;
}
#panel {
  background:#1e1e32; border:1px solid #2d2d50; border-radius:12px;
  padding:32px 40px; width:480px;
}
h1  { font-size:22px; color:#7ec8e3; margin-bottom:24px; letter-spacing:1px; }
.section { margin-bottom:22px; }
.section h2 { font-size:13px; color:#888; text-transform:uppercase;
              letter-spacing:1px; margin-bottom:10px; }

.row { display:flex; align-items:center; justify-content:space-between;
       padding:8px 0; border-bottom:1px solid #2a2a40; }
.row:last-child { border-bottom:none; }
.row label  { font-size:15px; }

/* Toggle switch */
.toggle { width:44px; height:24px; background:#333; border-radius:12px;
          position:relative; cursor:pointer; transition:background 0.2s; }
.toggle.on { background:#3498db; }
.toggle::after { content:""; position:absolute; top:2px; left:2px;
                 width:20px; height:20px; border-radius:50%; background:#fff;
                 transition:left 0.15s; }
.toggle.on::after { left:22px; }

/* Radio group */
.radio-group { display:flex; gap:10px; }
.radio-btn {
  padding:5px 14px; border-radius:6px; font-size:13px; cursor:pointer;
  border:1px solid #444; background:#2a2a40; color:#aaa;
  transition:background 0.15s, border-color 0.15s;
}
.radio-btn.active { background:#1a4a7a; border-color:#3498db; color:#fff; }

/* Slider */
.slider-row { display:flex; align-items:center; gap:12px; }
.slider-track { flex:1; height:6px; background:#333; border-radius:3px; overflow:hidden; }
.slider-fill  { height:100%; background:#3498db; transition:width 0.05s; }
.slider-val   { font-size:13px; color:#aaa; width:30px; text-align:right; }

#apply-btn {
  margin-top:24px; width:100%; padding:11px; border-radius:8px;
  background:#3498db; color:#fff; font-size:15px; cursor:pointer;
  border:none; transition:background 0.15s;
}
#apply-btn:hover { background:#2980b9; }
]]

local function build_html()
  local function toggle(id, on)
    return string.format('<div class="toggle%s" id="%s"></div>', on and " on" or "", id)
  end
  local function radio_group(name, opts, current)
    local btns = {}
    for _, v in ipairs(opts) do
      btns[#btns+1] = string.format(
        '<div class="radio-btn%s" data-group="%s" data-val="%s">%s</div>',
        v==current and " active" or "", name, v, v)
    end
    return '<div class="radio-group">' .. table.concat(btns) .. '</div>'
  end
  local function slider(id, val)
    return string.format(
      '<div class="slider-row">'
      .. '<div class="slider-track" id="%s-track">'
      .. '<div class="slider-fill" id="%s-fill" style="width:%d%%"></div></div>'
      .. '<span class="slider-val" id="%s-val">%d</span></div>',
      id, id, val, id, val)
  end
  return [[
<div id="panel">
  <h1>Settings</h1>
  <div class="section">
    <h2>Display</h2>
    <div class="row"><label>Fullscreen</label>]] .. toggle("fs-toggle", settings.fullscreen) .. [[</div>
    <div class="row"><label>V-Sync</label>]]    .. toggle("vs-toggle", settings.vsync)       .. [[</div>
    <div class="row"><label>Quality</label>]]
    .. radio_group("quality", {"low","medium","high"}, settings.quality) .. [[</div>
  </div>
  <div class="section">
    <h2>Audio</h2>
    <div class="row"><label>Music Volume</label>]]  .. slider("music", settings.music_vol) .. [[</div>
    <div class="row"><label>SFX Volume</label>]]    .. slider("sfx",   settings.sfx_vol)   .. [[</div>
  </div>
  <button id="apply-btn">Apply &amp; Close</button>
</div>
]]
end

local function wire_events()
  -- Toggles.
  for _, id in ipairs({"fs-toggle", "vs-toggle"}) do
    local el = settings_doc:getElementById(id)
    if el then
      el:on("click", function()
        local is_on = el:hasClass("on")
        if is_on then el:removeClass("on") else el:addClass("on") end
        if id == "fs-toggle"  then settings.fullscreen = not is_on end
        if id == "vs-toggle"  then settings.vsync      = not is_on end
      end)
    end
  end

  -- Radio buttons.
  local radios = settings_doc:queryAll(".radio-btn")
  for _, btn in ipairs(radios) do
    btn:on("click", function()
      local group = btn:getAttribute("data-group")
      local val   = btn:getAttribute("data-val")
      -- Deactivate siblings.
      local siblings = settings_doc:queryAll('[data-group="' .. (group or "") .. '"]')
      for _, sib in ipairs(siblings) do sib:removeClass("active") end
      btn:addClass("active")
      if group == "quality" then settings.quality = val end
    end)
  end

  -- Apply button.
  local ab = settings_doc:getElementById("apply-btn")
  if ab then
    ab:on("click", function()
      -- In a real game you'd apply here; for the demo just print.
      print("Settings applied:", settings.fullscreen, settings.vsync, settings.quality)
    end)
  end
end

-- Fake slider dragging via mouse (simplified: clicking the track sets value).
local dragging_slider = nil

function lurek.load()
  local w = lurek.window.getWidth()
  local h = lurek.window.getHeight()
  settings_doc = lurek.html.newDocument(build_html(), { css=CSS, width=w, height=h })
  wire_events()
end

function lurek.update(dt)
  settings_doc:update(dt)
  if lurek.keyboard.isDown("escape") then lurek.event.quit() end
end

function lurek.draw()
  lurek.graphics.setColor(0.07, 0.07, 0.13, 1)
  lurek.graphics.rectangle("fill", 0, 0, lurek.window.getWidth(), lurek.window.getHeight())
  settings_doc:render()
end

function lurek.mousemoved(x, y)          settings_doc:mousemoved(x, y) end
function lurek.mousepressed(x, y, btn)   settings_doc:mousepressed(x, y, btn) end
function lurek.mousereleased(x, y, btn)  settings_doc:mousereleased(x, y, btn) end
function lurek.wheelmoved(dx, dy)        settings_doc:wheelmoved(dx, dy) end
function lurek.keypressed(key)           settings_doc:keypressed(key) end
function lurek.textinput(t)              settings_doc:textinput(t) end
function lurek.resize(w, h)              settings_doc:setViewport(w, h) end
