-- lurek.thread.newChannel() -> Channel
-- Channels are MPMC (many producer, many consumer), thread-safe
local inbox  = lurek.thread.newChannel()
local outbox = lurek.thread.newChannel()
