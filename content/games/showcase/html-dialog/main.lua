-- content/games/showcase/html-dialog/main.lua
-- HTML Dialog Demo â€” lurek.html showcase.
--
-- An NPC stands in the world.  Click it to open an RPG-style dialog box built
-- in HTML/CSS with choice buttons.  Selecting a choice advances the
-- conversation tree or closes the dialog.
-- Demonstrates: conditional DOM updates, button event handlers, appendHtml.

local dialog_doc
local dialog_open = false
local npc_x, npc_y = 400, 300
local npc_r = 36

local CONVO = {
  {
    text    = "Hail, traveller!  What brings you to these lands?",
    choices = {
      { label="Just passing through.", next=2 },
      { label="I seek the ancient relic.", next=3 },
      { label="[Leave]", next=nil },
    },
  },
  {
    text    = "Safe travels then.  The road north is clear.",
    choices = { { label="Thanks. Goodbye.", next=nil } },
  },
  {
    text    = "Ahâ€¦ the Relic of Dawn.  Seek the ruined tower east of here.",
    choices = {
      { label="Thank you, wise one.", next=nil },
      { label="Is it dangerous?", next=4 },
    },
  },
  {
    text    = "Very.  Many have entered.  Few return.",
    choices = { { label="I'll be careful. Farewell.", next=nil } },
  },
}

local CSS = [[
* { margin:0; padding:0; box-sizing:border-box; }
#dialog-box {
  position:absolute; bottom:40px; left:50%; transform:translateX(-50%);
  width:680px; background:#1a1a2e; border:2px solid #f5a623;
  border-radius:10px; padding:20px 24px; font-family:serif;
}
#npc-name  { color:#f5a623; font-size:15px; font-weight:bold; margin-bottom:8px; }
#npc-text  { color:#e0e0e0; font-size:17px; line-height:1.5; margin-bottom:16px; }
.choices   { display:flex; flex-direction:column; gap:8px; }
.choice-btn {
  background:#0f3460; color:#e0e0e0; border:1px solid #3498db;
  border-radius:6px; padding:9px 14px; font-size:15px; cursor:pointer;
  text-align:left; transition:background 0.15s;
}
.choice-btn:hover { background:#1d4080; color:#fff; }
]]

local function open_dialog(node_idx)
  local node = CONVO[node_idx]
  if not node then
    dialog_doc:setHtml("")
    dialog_open = false
    return
  end
  dialog_open = true

  local btns = {}
  for i, c in ipairs(node.choices) do
    btns[#btns+1] = string.format(
      '<button class="choice-btn" data-next="%s" data-idx="%d">%s</button>',
      tostring(c.next or "nil"), i, c.label
    )
  end

  local html = string.format([[
<div id="dialog-box">
  <div id="npc-name">Village Elder</div>
  <div id="npc-text">%s</div>
  <div class="choices">%s</div>
</div>
]], node.text, table.concat(btns))

  dialog_doc:setHtml(html)
  dialog_doc:relayout()

  -- Wire choice buttons.
  local buttons = dialog_doc:queryAll(".choice-btn")
  for _, btn in ipairs(buttons) do
    btn:on("click", function()
      local next_str = btn:getAttribute("data-next")
      local next_idx = (next_str and next_str ~= "nil") and tonumber(next_str) or nil
      if next_idx then
        open_dialog(next_idx)
      else
        dialog_doc:setHtml("")
        dialog_open = false
      end
    end)
  end
end

function lurek.load()
  local w = lurek.window.getWidth()
  local h = lurek.window.getHeight()
  dialog_doc = lurek.html.newDocument("", { css=CSS, width=w, height=h })
end

function lurek.update(dt)
  if dialog_open then dialog_doc:update(dt) end
  if lurek.keyboard.isDown("escape") then
    if dialog_open then
      dialog_doc:setHtml("")
      dialog_open = false
    else
      lurek.event.quit()
    end
  end
end

function lurek.draw()
  -- World background.
  lurek.graphics.setColor(0.13, 0.16, 0.22, 1)
  lurek.graphics.rectangle("fill", 0, 0, lurek.window.getWidth(), lurek.window.getHeight())

  -- Ground patch.
  lurek.graphics.setColor(0.2, 0.45, 0.2, 1)
  lurek.graphics.ellipse("fill", npc_x, npc_y + npc_r, npc_r * 1.6, npc_r * 0.4)

  -- NPC circle body.
  lurek.graphics.setColor(0.6, 0.4, 0.2, 1)
  lurek.graphics.circle("fill", npc_x, npc_y, npc_r)
  lurek.graphics.setColor(1, 0.85, 0.6, 1)
  lurek.graphics.circle("fill", npc_x, npc_y - npc_r * 0.6, npc_r * 0.45)

  -- Prompt.
  lurek.graphics.setColor(1, 0.9, 0.3, 1)
  if not dialog_open then
    lurek.graphics.print("Click to talk", npc_x - 46, npc_y - npc_r - 22)
  end

  -- HTML dialog.
  if dialog_open then dialog_doc:render() end
end

function lurek.mousepressed(x, y, btn)
  if dialog_open then
    local consumed = dialog_doc:mousepressed(x, y, btn)
    if consumed then return end
  end
  -- Click on NPC opens dialog.
  local dx = x - npc_x
  local dy = y - npc_y
  if dx*dx + dy*dy <= npc_r*npc_r then
    open_dialog(1)
  end
end

function lurek.mousereleased(x, y, btn) dialog_doc:mousereleased(x, y, btn) end
function lurek.mousemoved(x, y) dialog_doc:mousemoved(x, y) end
function lurek.resize(w, h) dialog_doc:setViewport(w, h) end
