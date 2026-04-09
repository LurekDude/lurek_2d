local HUD = {}
HUD.__index = HUD

function HUD.new(player)
    return setmetatable({ player = player }, HUD)
end

function HUD:draw()
    local p = self.player
    -- HP bar background
    luna.gfx.setColor(0.3, 0.3, 0.3, 1)
    luna.gfx.rectangle("fill", 10, 10, 104, 14)
    -- HP bar fill
    local ratio = p.hp / p.max_hp
    luna.gfx.setColor(0.2, 0.8, 0.2, 1)
    luna.gfx.rectangle("fill", 12, 12, 100 * ratio, 10)
    -- Label
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("HP: " .. p.hp .. "/" .. p.max_hp, 120, 10)
end

return HUD
