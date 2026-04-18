| `lurek.physics` | ❌ | Physics world is main-thread only |
| `lurek.input` | ❌ | Input state is main-thread only |
| `lurek.data` | ✅ Full | Compression, hashing, encoding |
| `lurek.img` | ✅ Full | CPU-side pixel data only |
| Standard libs | Subset | No `os`, `io`, `loadfile`, `dofile` |

---

### Error Handling in Workers
Errors in the worker VM do **not** propagate to the main thread automatically. Wrap worker code in `pcall` and send errors back via channel:

> See [examples/error-handling-in-workers.lua](examples/error-handling-in-workers.lua) for the example.

> See [examples/error-handling-in-workers-2.lua](examples/error-handling-in-workers-2.lua) for the example.

---

### Patterns
### Work Queue

> See [examples/work-queue.lua](examples/work-queue.lua) for the example.

### Background Save

> See [examples/background-save.lua](examples/background-save.lua) for the example.

---

### Rules
- **Never call `channel:demand()` in `lurek.update()`.** It blocks the game loop. Use `channel:pop()` (non-blocking) in `lurek.update()` and `channel:demand()` in workers.
- **Threads do not auto-stop** when the main thread exits a scope. Send a `"quit"` message as the shutdown signal.
- **No shared mutable state.** If two pieces of code need to share a Lua value, use a Channel.
- **Each `lurek.thread.newThread()` call creates a new Lua VM.** Startup cost is small but non-zero — create workers at load time, not inside `lurek.update()`.
- **Resource keys (TextureKey, etc.) cannot cross threads** — they are opaque IDs for main-thread resources.
