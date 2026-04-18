> See [snippets/refcell-borrow-diagnosis.txt](snippets/refcell-borrow-diagnosis.txt) for the example.

**Pattern**: Two code paths are simultaneously active that both borrow SharedState.

**Typical cause**: A Lua callback is invoked WHILE SharedState is already borrowed by the caller:

> See [examples/refcell-borrow-diagnosis-2.rs](examples/refcell-borrow-diagnosis-2.rs) for the example.

**Fix**: Release the borrow before invoking any Lua callback:

> See [examples/refcell-borrow-diagnosis-3.rs](examples/refcell-borrow-diagnosis-3.rs) for the example.

---

### Diagnostic Log Placement
> See [examples/diagnostic-log-placement.rs](examples/diagnostic-log-placement.rs) for the example.

**Rule**: `log::debug!` calls have near-zero cost when the log level is above debug (which is the default). Safe to leave in code as long as they don't format complex values.
