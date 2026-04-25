-- CORRECT
if lurek.input.keyboard.isDown("space") then end
if lurek.input.keyboard.isDown("escape") then end
if lurek.input.keyboard.isDown("up") then end     -- "up", "down", "left", "right"
if lurek.input.keyboard.isDown("w") then end      -- single letter, lowercase

-- WRONG
if lurek.input.keyboard.isDown("Space") then end  -- uppercase
if lurek.input.keyboard.isDown("SPACE") then end  -- all-caps
if lurek.input.keyboard.isDown("VK_SPACE") then end  -- platform key name
