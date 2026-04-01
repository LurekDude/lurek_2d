local dirty = false
local save_timer = 0
local SAVE_INTERVAL = 30  -- seconds

function luna.update(dt)
  save_timer = save_timer + dt
  if dirty and save_timer >= SAVE_INTERVAL then
    save(game_state)
    dirty = false
    save_timer = 0
  end
end
