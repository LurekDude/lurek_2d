-- Serialize a table: JSON or comma-separated string
local channel = lurek.thread.newChannel()
local data = lurek.serial.toJson({ x = 10, y = 20 })
channel:push(data)

-- On the other side:
local result = lurek.serial.fromJson(channel:pop())
