---
name: threading
description: "Load this skill when designing or implementing multi-threaded Lua behaviour in Luna2D using the luna.thread API: spawning worker threads, using Channel for inter-VM communication, handling errors in background threads, or understanding which luna.* modules are safe to use in worker VMs. Use for: background computation, async file I/O in workers, producer-consumer patterns, parallel data processing. Skip it for Rust-side thread management internals (see src/thread/AGENT.md), or for general game scripting (use lua-scripting)."
---

# Threading — Luna2D

## Load When

- Adding background computation or I/O to a game via `luna.thread.newThread()`
- Designing a producer-consumer or work-queue pattern with `Channel`
- Working out which `luna.*` API is safe to call from a worker thread Lua VM
- Handling errors thrown in a background thread
- Explaining the threading model to a new contributor

## Owns

- Luna2D threading model: one Lua VM per thread, no shared state
- `luna.thread.*` Lua API patterns
- `Channel` communication patterns (push / pop / demand)
- Worker VM module restrictions
- Error reporting from worker VMs back to the main VM
- When to use threads vs when to stay single-threaded

---

## Threading Model

Luna2D uses **one Lua VM per thread**. Worker threads cannot share `SharedState` with the main game thread. This eliminates data races at the cost of requiring explicit message passing for all cross-thread communication.

```
Main Game Thread
├── Lua VM (full luna.* API)
├── SharedState (Rc<RefCell<>>)
├── GpuRenderer, Mixer, Physics
└── luna.update() / luna.draw()

Worker Thread N
├── Separate Lua VM (restricted API)
├── No SharedState access
└── Channel ◄────────► Main Thread Channel
```

**Key consequence**: The main thread is the only thread that can call `luna.gfx.*`, `luna.audio.*`, `luna.physics.*`, and `luna.input.*`. Workers send results back via `Channel` and the main thread applies them.

---

## Core API

### Spawning a thread

```lua
-- luna.thread.newThread(code: string) -> Thread
-- code is a complete Lua script string; it runs in an isolated VM
local worker = luna.thread.newThread([[
    local inbox  = ...   -- first argument via thread:start()
    local outbox = ...   -- second argument

    while true do
        local task = inbox:demand()   -- blocking: wait for work
        if task == "quit" then break end

        local result = task * 2  -- do work
        outbox:push(result)
    end
]])
```

### Creating a channel

```lua
-- luna.thread.newChannel() -> Channel
-- Channels are MPMC (many producer, many consumer), thread-safe
local inbox  = luna.thread.newChannel()
local outbox = luna.thread.newChannel()
```

### Starting a thread

```lua
-- thread:start(arg1, arg2, ...) -- args become the `...` vararg in the worker script
worker:start(inbox, outbox)
```

### Channel operations

```lua
ch:push(value)        -- non-blocking send; value: nil|bool|number|string
ch:pop()              -- non-blocking receive; returns nil if empty
ch:demand()           -- BLOCKING receive; use in workers, NOT in luna.update()
ch:peek()             -- non-destructive peek at front; returns nil if empty
ch:getCount()         -- number of items waiting
ch:clear()            -- drain all items
```

---

## ChannelValue Constraint

**Channels carry only these Lua types:**

| Lua type | Transmitted as |
|----------|---------------|
| `nil` | nil |
| `boolean` | bool |
| `number` | f64 |
| `string` | heap-copied string |
| UserData | **NOT supported** — will error |
| table | **NOT supported** — serialize to string first |

To pass structured data:
```lua
-- Serialize a table: JSON or comma-separated string
local data = luna.data.toJSON({ x = 10, y = 20 })
channel:push(data)

-- On the other side:
local result = luna.data.fromJSON(channel:pop())
```

---

## Worker VM — Safe Modules

Worker threads get an isolated VM with only these `luna.*` modules available:

| Module | Available in worker? | Notes |
|--------|---------------------|-------|
| `luna.math` | ✅ Full | Safe (pure computation) |
| `luna.thread` | ✅ Full | Channels, thread control |
| `luna.time` | ✅ Read-only | `luna.time.getTime()`, `luna.time.getDelta()` |
| `luna.fs` | ✅ Read-only | File reads only; no write |
| `luna.platform` | ✅ Read-only | OS info, `getProcessorCount()` |
| `luna.gfx` | ❌ | GPU resources are main-thread only |
| `luna.audio` | ❌ | Audio is main-thread only |
| `luna.physics` | ❌ | Physics world is main-thread only |
| `luna.input` | ❌ | Input state is main-thread only |
| `luna.data` | ✅ Full | Compression, hashing, encoding |
| `luna.img` | ✅ Full | CPU-side pixel data only |
| Standard libs | Subset | No `os`, `io`, `loadfile`, `dofile` |

---

## Error Handling in Workers

Errors in the worker VM do **not** propagate to the main thread automatically. Wrap worker code in `pcall` and send errors back via channel:

```lua
-- Worker script:
local inbox  = ...
local outbox = ...
local errors = ...  -- error channel

while true do
    local task = inbox:demand()
    if task == "quit" then break end

    local ok, result = pcall(function()
        return processTask(task)
    end)

    if ok then
        outbox:push(result)
    else
        errors:push("worker error: " .. tostring(result))
    end
end
```

```lua
-- Main thread checks error channel each frame:
function luna.process(dt)
    local err = errors:pop()
    if err then
        print("Background error: " .. err)
    end
    -- ...
end
```

---

## Patterns

### Work Queue

```lua
local queue   = luna.thread.newChannel()
local results = luna.thread.newChannel()

local worker  = luna.thread.newThread([[
    local q, r = ...
    while true do
        local item = q:demand()
        if item == nil then break end
        r:push(expensiveCompute(item))
    end
]])
worker:start(queue, results)

-- Main thread: post work
queue:push(42)

-- Main thread: collect results each frame (non-blocking)
function luna.process(dt)
    local result = results:pop()
    if result then applyResult(result) end
end
```

### Background Save

```lua
local saveChannel = luna.thread.newChannel()

local saver = luna.thread.newThread([[
    local ch = ...
    while true do
        local json = ch:demand()
        if json == nil then break end
        luna.fs.write("save.json", json)
    end
]])
saver:start(saveChannel)

-- Trigger save from main thread (non-blocking):
saveChannel:push(luna.data.toJSON(gameState))
```

---

## Rules

- **Never call `channel:demand()` in `luna.update()`.** It blocks the game loop. Use `channel:pop()` (non-blocking) in `luna.update()` and `channel:demand()` in workers.
- **Threads do not auto-stop** when the main thread exits a scope. Send a `"quit"` message as the shutdown signal.
- **No shared mutable state.** If two pieces of code need to share a Lua value, use a Channel.
- **Each `luna.thread.newThread()` call creates a new Lua VM.** Startup cost is small but non-zero — create workers at load time, not inside `luna.update()`.
- **Resource keys (TextureKey, etc.) cannot cross threads** — they are opaque IDs for main-thread resources.
