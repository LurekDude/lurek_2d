---@diagnostic disable: undefined-global
function lurek.init()
    -- library init first
    item.clearTypes()
    item.defineType("sword", { category = "weapon", base_stats = { attack = 10 } })
    inv = inventory.new(20)
    -- then window + graphics setup
    lurek.window.setTitle("Loot Demo")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.1)
end
