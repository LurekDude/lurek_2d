-- content/examples/repl.lua
-- lurek.repl API examples.
-- Run: cargo run -- content/examples/repl.lua

--@api-stub: lurek.repl.new
-- Creates a release-safe REPL session with bounded command history
do
  local repl = lurek.repl.new(32)
  repl:eval("example_repl_value = 10")
end

--@api-stub: LReplSession:eval
-- Evaluates Lua code and records the input in this REPL history
do
  local repl = lurek.repl.new(8)
  local value = repl:eval("6 * 7")
  lurek.log.info("repl value " .. value, "repl")
end

--@api-stub: LReplSession:history
-- Returns the recorded REPL input history in oldest-first order
do
  local repl = lurek.repl.new(8)
  repl:eval("1 + 1")
  local history = repl:history()
  lurek.log.info("repl history entries " .. tostring(#history), "repl")
end

--@api-stub: LReplSession:clear
-- Clears all entries from this REPL session history
do
  local repl = lurek.repl.new(8)
  repl:eval("2 + 2")
  repl:clear()
end

--@api-stub: LReplSession:len
-- Returns the number of entries stored in this REPL history
do
  local repl = lurek.repl.new(8)
  repl:eval("3 + 3")
  lurek.log.info("repl length " .. tostring(repl:len()), "repl")
end

--@api-stub: LReplSession:complete
-- Returns completion candidates that begin with the supplied prefix
do
  local repl = lurek.repl.new(8)
  local matches = repl:complete("lurek.re")
  lurek.log.info("repl completions " .. tostring(#matches), "repl")
end

--@api-stub: LReplSession:type
-- Returns the Lua-visible type name for this REPL session handle
do
  local repl = lurek.repl.new(8)
  lurek.log.info("repl type " .. repl:type(), "repl")
end

--@api-stub: LReplSession:typeOf
-- Returns whether this REPL session handle matches a supported type name
do
  local repl = lurek.repl.new(8)
  if repl:typeOf("LReplSession") then
    lurek.log.info("repl session ready", "repl")
  end
end
