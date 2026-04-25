-- thread:start(arg1, arg2, ...) -- args become the `...` vararg in the worker script
local worker = lurek.thread.newThread("local inbox, outbox = ...")
local inbox = lurek.thread.newChannel()
local outbox = lurek.thread.newChannel()
worker:start(inbox, outbox)
