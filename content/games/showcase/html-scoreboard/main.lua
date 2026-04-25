-- content/games/showcase/html-scoreboard/main.lua
-- HTML Scoreboard Demo â€” lurek.html showcase.
--
-- A live leaderboard rendered as an HTML <table>.  Every two seconds a new
-- score arrives and the table is rebuilt and re-sorted, with the top entry
-- highlighted in gold.
-- Demonstrates: dynamic HTML rebuilding, table markup, addClass, queryAll.

local board_doc
local scores = {
  { name="Aria",     pts=12450 },
  { name="Colt",     pts=9870  },
  { name="Vex",      pts=8320  },
  { name="Dusk",     pts=7200  },
  { name="Prism",    pts=6100  },
  { name="Echo",     pts=4450  },
  { name="Flint",    pts=3980  },
  { name="Gale",     pts=2010  },
}

local NAMES_POOL = {
  "Nova","Raze","Blaze","Frost","Storm","Jade","Kai","Lyric","Myst","Onyx",
}
local tick = 0
local UPDATE_EVERY = 2  -- seconds

local CSS = [[
* { margin:0; padding:0; box-sizing:border-box; font-family:sans-serif; }
body {
  background:#0d0d1a; display:flex;
  justify-content:center; align-items:flex-start; padding-top:60px;
}
#board {
  background:#141428; border:1px solid #2d2d50;
  border-radius:12px; padding:28px 36px; min-width:460px;
}
h1 { color:#f5a623; font-size:22px; letter-spacing:2px;
     text-align:center; margin-bottom:20px; }

table { width:100%; border-collapse:collapse; }
thead th {
  color:#888; font-size:12px; text-transform:uppercase; letter-spacing:1px;
  padding-bottom:10px; border-bottom:1px solid #2d2d50; text-align:left;
}
thead th.right { text-align:right; }

tbody tr { border-bottom:1px solid #1e1e38; transition:background 0.2s; }
tbody tr:hover { background:#1e1e38; }

tbody td { padding:11px 4px; font-size:15px; color:#ccc; }
.rank  { color:#666; font-size:13px; width:32px; }
.score { text-align:right; color:#3498db; font-weight:bold; font-size:15px; }

.gold   td { color:#f5a623 !important; }
.silver td { color:#c0c0c0 !important; }
.bronze td { color:#cd7f32 !important; }
.gold   .score { color:#f5c842 !important; }

.badge { font-size:18px; }
]]

local MEDALS = {"đźĄ‡","đźĄ","đźĄ‰"}

local function build_table_html()
  -- Sort descending.
  table.sort(scores, function(a, b) return a.pts > b.pts end)

  local rows = {}
  for i, s in ipairs(scores) do
    local medal_cls = (i == 1) and "gold" or (i == 2) and "silver" or (i == 3) and "bronze" or ""
    local badge     = MEDALS[i] or ""
    rows[#rows+1] = string.format(
      '<tr class="%s">'
      .. '<td class="rank badge">%s</td>'
      .. '<td>%s</td>'
      .. '<td class="score">%s</td>'
      .. '</tr>',
      medal_cls, badge ~= "" and badge or tostring(i), s.name,
      string.format("%d", s.pts)
    )
  end

  return [[
<div id="board">
  <h1>đźŹ† Scoreboard</h1>
  <table>
    <thead><tr>
      <th></th><th>Player</th><th class="right">Score</th>
    </tr></thead>
    <tbody>]] .. table.concat(rows) .. [[</tbody>
  </table>
</div>
]]
end

local function refresh()
  board_doc:setHtml(build_table_html())
  board_doc:relayout()
end

function lurek.load()
  local w = lurek.window.getWidth()
  local h = lurek.window.getHeight()
  board_doc = lurek.html.newDocument(build_table_html(), { css=CSS, width=w, height=h })
end

function lurek.update(dt)
  tick = tick + dt
  if tick >= UPDATE_EVERY then
    tick = tick - UPDATE_EVERY
    -- Simulate a new score arriving.
    local nm  = NAMES_POOL[math.random(#NAMES_POOL)]
    local pts = math.random(1000, 15000)
    -- Either update an existing entry or push a new one (cap at 10).
    local found = false
    for _, s in ipairs(scores) do
      if s.name == nm then s.pts = pts; found = true; break end
    end
    if not found then
      if #scores >= 10 then table.remove(scores, #scores) end
      scores[#scores+1] = { name=nm, pts=pts }
    end
    refresh()
  end

  board_doc:update(dt)
  if lurek.keyboard.isDown("escape") then lurek.event.quit() end
end

function lurek.draw()
  lurek.graphics.setColor(0.05, 0.05, 0.1, 1)
  lurek.graphics.rectangle("fill", 0, 0, lurek.window.getWidth(), lurek.window.getHeight())
  board_doc:draw()
end

function lurek.mousemoved(x, y)           board_doc:mousemoved(x, y) end
function lurek.mousepressed(x, y, btn)    board_doc:mousepressed(x, y, btn) end
function lurek.mousereleased(x, y, btn)   board_doc:mousereleased(x, y, btn) end
function lurek.resize(w, h)               board_doc:setViewport(w, h) end
