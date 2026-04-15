# IDEA.md — `event` module

> Migrated from `ideas/features/event.md`.
> Status checked against `src/event/` and `src/lua_api/event_api.rs`.

---

## Features

### ✅ DONE — Once-Only Listeners
**Source**: features/event.md — Feature Gaps #6 / Suggestions #1

No `signal:once(name, fn)` found that auto-disconnects after first invocation. Currently
callers must manually disconnect inside the callback. Extremely common pattern.

---

### ✅ DONE — Deferred / Next-Frame Posting
**Source**: features/event.md — Feature Gaps #4 / Suggestions #2

No `queue:postDeferred(name, data)` API. Deferred events process at the start of the next
frame, preventing re-entrant event chains where an event handler emits the same event again.

---

### ✅ DONE — Event History (Debug Mode)
**Source**: features/event.md — Feature Gaps #5 / Suggestions #3

No `queue:enableHistory(maxEvents)` found. A rolling event log would enable post-hoc
debugging of event-driven bugs. Should be disabled in release builds.

---

### ✅ DONE — Wildcard Signal Subscriptions
**Source**: features/event.md — Feature Gaps #7 / Suggestions #5

✅ DONE (2026-04-15) — Added `subscribe_wildcard` + `get_wildcard_handles` to Signal, `connect` method on LuaSignal in event_api.rs. Glob matching via internal `glob_match` function.

---

### ✅ DONE — Event Filtering Predicate
**Source**: features/event.md — Feature Gaps #1

No filter predicate on connect: `signal:connect("health_change", fn, {filter=fn})`. Callers
must filter inside every handler. A built-in predicate would reduce boilerplate.
