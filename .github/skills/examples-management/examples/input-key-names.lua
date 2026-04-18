-- CORRECT
if lurek.keyboard.isDown("space") then
if lurek.keyboard.isDown("escape") then
if lurek.keyboard.isDown("up") then     -- "up", "down", "left", "right"
if lurek.keyboard.isDown("w") then      -- single letter, lowercase

-- WRONG
if lurek.keyboard.isDown("Space") then  -- uppercase
if lurek.keyboard.isDown("SPACE") then  -- all-caps
if lurek.keyboard.isDown("VK_SPACE") then  -- platform key name
