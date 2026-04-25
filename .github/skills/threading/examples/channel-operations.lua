local ch = lurek.thread.newChannel()
local value = "payload"

ch:push(value)        -- non-blocking send; value: nil|bool|number|string
ch:pop()              -- non-blocking receive; returns nil if empty
ch:demand()           -- BLOCKING receive; use in workers, NOT in lurek.update()
ch:peek()             -- non-destructive peek at front; returns nil if empty
ch:getCount()         -- number of items waiting
ch:clear()            -- drain all items
