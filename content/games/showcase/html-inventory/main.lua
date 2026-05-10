-- content/games/showcase/html-inventory/main.lua
-- HTML Inventory Demo â€” lurek.html showcase.
--
-- Shows a 4x5 inventory grid built entirely with HTML/CSS.  Click a slot to
-- "equip" the item (border highlights).  Item tooltips appear on hover via
-- CSS :hover.  Demonstrates: newDocument, querySelector, addClass/removeClass,
-- on(), event callbacks, and DOM mutation.

local inv_doc
local selected_slot = nil

-- 20 item slots; some are pre-filled.
local ITEMS = {
  {name="Sword",  icon="âš”",  rarity="rare"},
  {name="Shield", icon="đź›ˇ",  rarity="common"},
  {name="Potion", icon="đź§Ş",  rarity="common"},
  {name="Bow",    icon="đźŹą",  rarity="uncommon"},
  {name="Helm",   icon="â›‘",  rarity="uncommon"},
  {name="Ring",   icon="đź’Ť",  rarity="rare"},
  {name="Scroll", icon="đź“ś",  rarity="common"},
  {name="Amulet", icon="đź”®",  rarity="epic"},
}

local function build_html()
  local rows = {}
  for i = 1, 20 do
    local item = ITEMS[i]
    if item then
      rows[#rows+1] = string.format(
        '<div class="slot filled" data-slot="%d" data-name="%s" data-rarity="%s">'
        .. '<span class="icon">%s</span>'
        .. '<span class="label">%s</span>'
        .. '</div>',
        i, item.name, item.rarity, item.icon, item.name
      )
    else
      rows[#rows+1] = string.format('<div class="slot empty" data-slot="%d"></div>', i)
    end
  end
  return '<div id="panel"><h2>Inventory</h2><div id="grid">'
      .. table.concat(rows) .. '</div>'
      .. '<p id="info">Click an item to equip it.</p></div>'
end

local CSS = [[
* { margin:0; padding:0; box-sizing:border-box; }
body { background:#1a1a2e; font-family:sans-serif; display:flex;
       justify-content:center; align-items:center; height:100%; }

#panel { background:#16213e; padding:24px; border-radius:12px;
         border:1px solid #0f3460; }
h2 { color:#e94560; margin-bottom:14px; font-size:18px; letter-spacing:1px; }

#grid { display:grid; grid-template-columns:repeat(4,72px); gap:8px; }

.slot {
  width:72px; height:72px; border-radius:8px;
  border:2px solid #0f3460; background:#0f3460;
  display:flex; flex-direction:column; align-items:center;
  justify-content:center; cursor:pointer; user-select:none;
  transition:border-color 0.15s, transform 0.1s;
}
.slot:hover { border-color:#e94560; transform:scale(1.06); }
.slot.selected { border-color:#f5a623; background:#1d1f3a; }
.slot.empty { opacity:0.3; cursor:default; }
.icon  { font-size:28px; line-height:1; }
.label { color:#aaa; font-size:10px; margin-top:4px; }

.slot[data-rarity="rare"]     { border-color:#3498db; }
.slot[data-rarity="uncommon"] { border-color:#2ecc71; }
.slot[data-rarity="epic"]     { border-color:#9b59b6; }

#info { color:#aaa; font-size:13px; margin-top:14px; text-align:center; }
]]

local event_handles = {}

function lurek.init()
  local w = lurek.window.getWidth()
  local h = lurek.window.getHeight()
  inv_doc = lurek.html.newDocument(build_html(), { css=CSS, width=w, height=h })
  if not inv_doc then
    return
  end

  -- Wire up click handlers for all filled slots.
  local slots = inv_doc:queryAll(".slot.filled")
  for _, slot in ipairs(slots) do
    local h_ev = slot:on("click", function()
      -- Deselect previous.
      if selected_slot then selected_slot:removeClass("selected") end
      slot:addClass("selected")
      selected_slot = slot
      local info = inv_doc:getElementById("info")
      if info then
        local nm = slot:getAttribute("data-name") or "?"
        local rr = slot:getAttribute("data-rarity") or ""
        info:setText("Equipped: " .. nm .. "  (" .. rr .. ")")
      end
    end)
    event_handles[#event_handles+1] = h_ev
  end
end

function lurek.process(dt)
  if inv_doc then
    inv_doc:update(dt)
  end
  if lurek.input.keyboard.isDown("escape") then lurek.event.quit() end
end

function lurek.draw()
  lurek.render.setColor(0.1, 0.1, 0.18, 1)
  lurek.render.rectangle("fill", 0, 0, lurek.window.getWidth(), lurek.window.getHeight())
  if inv_doc then inv_doc:render() end
end

function lurek.mousemoved(x, y) if inv_doc then inv_doc:mousemoved(x, y) end end
function lurek.mousepressed(x, y, btn) if inv_doc then inv_doc:mousepressed(x, y, btn) end end
function lurek.mousereleased(x, y, btn) if inv_doc then inv_doc:mousereleased(x, y, btn) end end
function lurek.resize(w, h) if inv_doc then inv_doc:setViewport(w, h) end end
