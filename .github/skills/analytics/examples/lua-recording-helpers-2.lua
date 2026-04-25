---@diagnostic disable: undefined-global
-- Usage in game scripts:
local T = require("lib/telemetry")
T.init()

-- Record meaningful events
T.event("game_start",    { level = currentLevel })
T.event("player_died",   { x = player.x, y = player.y, cause = "spike", attempt = attempt })
T.event("level_complete",{ level = n, duration = elapsed, attempts = attempts })
T.event("item_picked",   { item = name, x = player.x, y = player.y })
T.event("boss_killed",   { boss = name, hp_remaining = boss.hp, time = elapsed })
