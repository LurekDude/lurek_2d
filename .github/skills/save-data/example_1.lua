local function serialize(v, indent)
  indent = indent or ""
  if type(v) == "table" then
    local s = "{\n"
    for k, val in pairs(v) do
      local key = type(k) == "string" and ('["'..k..'"]') or ("[" .. k .. "]")
      s = s .. indent .. "  " .. key .. " = " .. serialize(val, indent .. "  ") .. ",\n"
    end
    return s .. indent .. "}"
  elseif type(v) == "string" then
    return string.format("%q", v)
  else
    return tostring(v)
  end
end

local function save(data)
  data.version = 1          -- mandatory version field
  luna.filesystem.write("save/slot1.lua", "return " .. serialize(data))
end

local function load_save()
  if not luna.filesystem.exists("save/slot1.lua") then return nil end
  local src = luna.filesystem.read("save/slot1.lua")
  local fn = load(src)
  return fn and fn() or nil
end
