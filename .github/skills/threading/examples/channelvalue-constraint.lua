-- Serialize a table: JSON or comma-separated string
local data = lurek.data.toJSON({ x = 10, y = 20 })
channel:push(data)

-- On the other side:
local result = lurek.data.fromJSON(channel:pop())
