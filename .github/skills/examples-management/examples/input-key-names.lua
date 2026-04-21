-- CORRECT
if lurek.input.keyboard.isDown("space") then
if lurek.input.keyboard.isDown("escape") then
if lurek.input.keyboard.isDown("up") then     -- "up", "down", "left", "right"
if lurek.input.keyboard.isDown("w") then      -- single letter, lowercase

-- WRONG
if lurek.input.keyboard.isDown("Space") then  -- uppercase
if lurek.input.keyboard.isDown("SPACE") then  -- all-caps
if lurek.input.keyboard.isDown("VK_SPACE") then  -- platform key name
