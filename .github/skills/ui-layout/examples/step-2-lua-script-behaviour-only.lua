-- Behaviour-only sketch: wire the widget handles returned by your layout loader,
-- then use the current widget setters/callbacks directly.
local game = { score = 120, end_player_turn = function() end }
local player = { hp = 75, max_hp = 100, has_ranged_weapon = true }

local hud = {} ---@type any
local end_turn_btn = {} ---@type any
local volume_slider = {} ---@type any
local score_label = {} ---@type any
local hp_bar = {} ---@type any
local ammo_badge = {} ---@type any

hud:setVisible(true)
end_turn_btn:setOnClick(function()
    game.end_player_turn()
end)

volume_slider:setOnChange(function(value)
    lurek.audio.setMasterVolume(value)
end)

score_label:setText(tostring(game.score))
hp_bar:setValue(player.hp / player.max_hp)
ammo_badge:setVisible(player.has_ranged_weapon)
