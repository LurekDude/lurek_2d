-- .github/skills/html-css/examples/quickstart.lua
-- Minimal lurek.html HUD example â€” the skeleton every html-* game starts from.
-- Load this file to understand the create â†’ update â†’ draw â†’ input lifecycle.

local hud

-- â”€â”€ create â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function lurek.load()
    hud = lurek.html.newDocument([[
        <div id="hud">
            <p id="score">Score: <span id="val">0</span></p>
        </div>
    ]], {
        css   = "#hud { position: fixed; top: 8px; right: 8px; color: #fff; font-size: 20px; }",
        width = lurek.window.getWidth(),
        height = lurek.window.getHeight(),
    })
    hud:relayout()
end

-- â”€â”€ resize â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function lurek.resize(w, h)
    hud:setViewport(w, h)
end

-- â”€â”€ update â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local score = 0
function lurek.update(dt)
    score = score + dt * 10
    local val = hud:getElementById("val")
    if val then val:setText(string.format("%d", math.floor(score))) end
    hud:update(dt)
end

-- â”€â”€ draw â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function lurek.draw()
    -- draw game world here â€¦
    hud:draw()  -- overlay on top
end

-- â”€â”€ input forwarding â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function lurek.mousepressed(x, y, btn)
    if hud:mousepressed(x, y, btn) then return end  -- UI consumed â€” skip game
    -- â€¦ game click logic
end

function lurek.mousereleased(x, y, btn)
    hud:mousereleased(x, y, btn)
end

function lurek.mousemoved(x, y, dx, dy)
    hud:mousemoved(x, y)
end
