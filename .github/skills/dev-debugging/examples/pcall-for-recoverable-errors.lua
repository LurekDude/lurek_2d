-- Wrap risky code in pcall to handle errors without crashing
local ok, err = pcall(function()
    lurek.render.newImage("missing.png")
end)
if not ok then
    print("Failed to load image: " .. tostring(err))
    -- use fallback image
end
