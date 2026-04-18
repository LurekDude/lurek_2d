local imap = lurek.pathfinding.newInfluenceMap(40, 30, 16)

-- Add named layers
imap:addLayer("player_threat")
imap:addLayer("enemy_presence")

-- Stamp values (position, radius, strength, layer)
imap:stamp(player.x, player.y, 80, 1.0, "player_threat")
imap:stamp(enemy.x, enemy.y, 40, 0.8, "enemy_presence")

-- Propagate influence across cells
imap:propagate("player_threat", 0.7)   -- decay factor

-- Decay over time
imap:decay("player_threat", 0.95, dt)

-- Query to find best position (minimize player_threat, maximize cover)
local sx, sy = imap:findMin("player_threat")   -- safest cell
