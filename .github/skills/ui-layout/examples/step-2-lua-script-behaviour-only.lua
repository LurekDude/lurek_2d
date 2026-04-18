-- Load the layout and show it
local hud = lurek.ui.load_layout("content/layouts/games/combat_hud.toml")
lurek.ui.show(hud)

-- Attach callbacks by widget id
lurek.ui.on(hud, "end_turn_btn", "click", function()
    game.end_player_turn()
end)

lurek.ui.on(hud, "volume_slider", "change", function(value)
    lurek.audio.set_master_volume(value)
end)

-- Update widget text / values at runtime
lurek.ui.set_text(hud, "score_label",  tostring(game.score))
lurek.ui.set_value(hud, "hp_bar",      player.hp / player.max_hp)
lurek.ui.set_visible(hud, "ammo_badge", player.has_ranged_weapon)
