local function migrate(data)
  if data.version == nil or data.version < 2 then
    data.new_field = data.new_field or 0
    data.version = 2
  end
  return data
end
