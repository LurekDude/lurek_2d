# `library.patterns` *(proxy)* *(deprecated)*

This module previously contained a coroutine scheduler. The name collided
with the unrelated `lurek.patterns` Rust namespace (EventBus, ObjectPool,
CommandStack, SimpleState, ...). The implementation has moved verbatim to
`library.scheduler`. This stub forwards `require` calls and emits a
one-shot deprecation warning so existing scripts keep working unchanged.

Migration: replace `require("library.patterns")` with
`require("library.scheduler")` at your call sites.

*0 functions, 0 module fields documented.*

See: [`library.scheduler`](../library-docs.md#libraryscheduler)
