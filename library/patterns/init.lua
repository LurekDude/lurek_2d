--- Deprecated: renamed to library.scheduler.
-- @module library.patterns
-- @deprecated 0.6.0 — use require("library.scheduler") instead.
-- @status proxy
-- @see library.scheduler
--
-- This module previously contained a coroutine scheduler. The name collided
-- with the unrelated `lurek.patterns` Rust namespace (EventBus, ObjectPool,
-- CommandStack, SimpleState, ...). The implementation has moved verbatim to
-- `library.scheduler`. This stub forwards `require` calls and emits a
-- one-shot deprecation warning so existing scripts keep working unchanged.
--
-- Migration: replace `require("library.patterns")` with
-- `require("library.scheduler")` at your call sites.

local log = (lurek and lurek.log and lurek.log.warn) or print
log("[library.patterns] deprecated; use library.scheduler instead.")
return require("library.scheduler")
