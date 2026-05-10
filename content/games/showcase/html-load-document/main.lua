local ui
local score = 0
local elapsed = 0
local pulses = 0
local theme_a = true
local px, py = 640, 360

local function set_text(id, value)
  if not ui then
    return
  end
  local el = ui:getElementById(id)
  if el then
    el:setText(value)
  end
end

local function set_status(text)
  set_text("status-val", text)
end

local function wire_events()
  local panel = ui:getElementById("panel")
  local theme_btn = ui:getElementById("theme-btn")
  local pulse_btn = ui:getElementById("pulse-btn")

  if theme_btn and panel then
    theme_btn:on("click", function()
      theme_a = not theme_a
      if theme_a then
        panel:addClass("theme-a")
        panel:removeClass("theme-b")
        set_status("theme: A")
      else
        panel:addClass("theme-b")
        panel:removeClass("theme-a")
        set_status("theme: B")
      end
    end)
  end

  if pulse_btn then
    pulse_btn:on("click", function()
      pulses = pulses + 1
      set_text("pulse-val", tostring(pulses))
      set_status("pulse from html button")
    end)
  end

  ui:on("keydown", function(ev)
    if ev and ev.key == "t" and theme_btn then
      theme_btn:focus()
    end
  end)
end

function lurek.init()
  lurek.window.setTitle("HTML LoadDocument Demo")

  if not lurek.html or type(lurek.html.loadDocument) ~= "function" then
    return
  end

  ui = lurek.html.loadDocument("ui/hud.html", {
    cssPath = "ui/hud.css",
    width = lurek.window.getWidth(),
    height = lurek.window.getHeight(),
  })

  if not ui then
    return
  end

  wire_events()
  set_status("ready")
end

function lurek.process(dt)
  elapsed = elapsed + dt
  score = score + math.floor(dt * 120)

  if ui then
    set_text("score-val", tostring(score))
    set_text("time-val", string.format("%.1fs", elapsed))
    ui:update(dt)
  end

  if lurek.input.keyboard.isDown("space") then
    pulses = pulses + 1
    set_text("pulse-val", tostring(pulses))
    set_status("pulse from keyboard")
  end

  if lurek.input.keyboard.isDown("escape") then
    lurek.event.quit()
  end
end

function lurek.draw()
  lurek.render.setColor(0.08, 0.11, 0.16, 1)
  lurek.render.rectangle("fill", 0, 0, lurek.window.getWidth(), lurek.window.getHeight())

  lurek.render.setColor(0.18, 0.35, 0.55, 0.7)
  lurek.render.rectangle("fill", 120, 120, 1040, 470)

  lurek.render.setColor(0.2, 0.75, 0.95, 1)
  lurek.render.circle("fill", px, py, 18)

  if ui then
    ui:render()
  end
end

function lurek.mousemoved(x, y)
  px, py = x, y
  if ui then
    ui:mousemoved(x, y)
  end
end

function lurek.mousepressed(x, y, button)
  if ui then
    ui:mousepressed(x, y, button)
  end
end

function lurek.mousereleased(x, y, button)
  if ui then
    ui:mousereleased(x, y, button)
  end
end

function lurek.keypressed(key)
  if ui then
    ui:keypressed(key)
  end
end

function lurek.textinput(text)
  if ui then
    ui:textinput(text)
  end
end

function lurek.wheelmoved(dx, dy)
  if ui then
    ui:wheelmoved(dx, dy)
  end
end

function lurek.resize(w, h)
  if ui then
    ui:setViewport(w, h)
  end
end
