---
description: "Rewrite content/examples/<module>.lua files as scenario-driven learning examples. Each example tells a coherent story about WHEN and WHY you use the API — not a dry enumeration of every function. Processes 4 modules per batch."
---

# Flesh Out Example Files — Scenario-Driven Approach

**Purpose**: Replace every `--@api-stub:` block in `content/examples/<module>.lua` with real,
working scenario code. The primary audience is a game developer who has never used this module before.

**Use When**: A module example file has `--@api-stub:` lines remaining.
**Do Not Use When**: The example has zero `--@api-stub:` lines and `--stubs` shows nothing.
**Scope**: `content/examples/<module>.lua` only — no `src/` changes.

---

## THE IRON LAW — EVERY STUB BECOMES REAL CODE

> **Every single `--@api-stub:` block MUST be fleshed out with working Lua code before you finish.**

The stub generator (`example_add_missing.py`) creates one `--@api-stub:` block per API item.
Your job is to flesh out **all of them** — not just the interesting ones, not just the common ones —
**every single one**, with real contextual code that shows the API in use.

### EXACT TRANSFORMATION RULE — per stub, line by line

Given an original stub block:

```lua
-- ---- Stub: SaveManager:setSchemaVersion ----------------------------------
--@api-stub: SaveManager:setSchemaVersion
-- Sets the current schema version for new saves
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- saveManager_stub:setSchemaVersion(version)
-- (replace saveManager_stub with your real SaveManager instance above)
```

Apply exactly these changes:

| Line | Action | Result |
|------|--------|--------|
| `-- ---- Stub: ...` header | **KEEP** unchanged | `-- ---- Stub: SaveManager:setSchemaVersion --` |
| `--@api-stub: ...` marker | **KEEP** unchanged | `--@api-stub: SaveManager:setSchemaVersion` |
| `-- <original one-line docstring>` | **REMOVE** | _(deleted)_ |
| `-- TODO: replace this stub...` line | **REMOVE** | _(deleted)_ |
| `-- stub_name:method(...)` dummy call | **REMOVE** | _(deleted)_ |
| `-- (replace stub_name with ...)` line | **REMOVE** | _(deleted)_ |
| _(nothing here before)_ | **ADD** 1-3 comment lines describing WHEN and WHY | `-- Increment this whenever you add or remove fields...` |
| _(nothing here before)_ | **ADD** 5-15 lines of real Lua code | `mgr:setSchemaVersion(3)` ... |

**Result after transformation:**

```lua
-- ---- Stub: SaveManager:setSchemaVersion ----------------------------------
--@api-stub: SaveManager:setSchemaVersion
-- Increment this whenever you add or remove fields that require a migration
-- step so older save files can be detected and upgraded automatically.
mgr:setSchemaVersion(3)
print("current schema version:", mgr:getSchemaVersion())
```

### Critical rules for the replacement code

- **NOT a one-liner + print.** The code must be 5-15 lines showing a realistic use case.
- **NOT a test.** Do not write `if result then print("ok")`. Show the API doing real game work.
- **Real variables.** Use game-domain names: `player_hp`, `slot1`, `walk_clip`, not `x`, `val`, `result`.
- **Context flows between stubs.** Objects created in an earlier stub are reused in later stubs.
  e.g. `local mgr = lurek.save.newSaveManager()` at the top is used by every `SaveManager:*` stub below.
- **The `--@api-stub:` marker line is NEVER removed.** Coverage counting depends on it.
- **The original one-line docstring IS removed.** Replace it with a better contextual comment.

---

## THE CARDINAL RULE — USE CASES FIRST

> **Every example must answer: "What am I building, and why do I need this API to build it?"**

An example file is NOT an API index. It is a short story about building something real.
The coverage tool (`example_coverage.py`) is a MINIMUM completeness bar — passing it means nothing
if the resulting code is incomprehensible. Both must pass:
1. **Coverage** — every public API item is called at least once with real arguments
2. **Clarity** — a developer reading the file for the first time understands the use case

### THE SINGLE WORST ANTI-PATTERN — do not do this under any circumstances

```lua
-- BAD: this teaches NOTHING. Why does Signal:type() exist? Who calls it? When?
local sig2 = lurek.event.newSignal()
print("type: " .. sig2:type())
```

```lua
-- BAD: API enumeration masquerading as documentation
local fw = lurek.devtools.newFileWatcher("conf.toml")
fw:onChanged(function() print("changed") end)
fw:check()
fw:cancel()
```

Both pass coverage. Both are useless. A developer learns nothing.

### GOOD PATTERN — scenario-first grouping

Group related functions into a named scenario block. The block title names the USE CASE.
Every function in the group exists because the scenario needs it.

```lua
-- ---- Scenario: schedule bullet despawn ----------------------------------------
-- A bullet fired from the player should self-destruct after 3 seconds.
-- lurek.timer.newScheduler creates the scheduler; after() queues the callback;
-- cancel() lets us abort early if the bullet hits something first.

local sched = lurek.timer.newScheduler()
local despawn_id = sched:after(3.0, function()
    print("bullet removed from world")
end)

-- Simulate 1 second of game time passing
sched:update(1.0)
print("pending timers: " .. sched:count())

-- Enemy was hit -- cancel the auto-despawn early
local cancelled = sched:cancel(despawn_id)
print("despawn cancelled: " .. tostring(cancelled))
```

Now the reader knows: Scheduler + after() + cancel() = "fire-and-forget with early abort".

---

## SCENARIO DESIGN RULES

### Rule 1 — Name every scenario block with a real game task

```lua
-- ---- Scenario: auto-save player progress ----------------------------------------
-- ---- Scenario: hot-reload a config file during development ----------------------
-- ---- Scenario: pub-sub hit/heal events between game systems ---------------------
-- ---- Scenario: throttle pathfind requests to 5 per second ----------------------
```

Use `-- ----` (plain ASCII dashes). No Unicode characters.

### Rule 2 — Rarely-useful methods ("housekeeping APIs") can be grouped

Functions like `:type()`, `:typeOf()`, `:count()`, getters that report state — group them
into a single "utility" block at the end of their scenario:

```lua
-- -- Utility queries on the scheduler
print("scheduler type:  " .. sched:type())
print("pending timers:  " .. sched:count())
```

Do NOT give `:type()` its own scenario. It is not a use case.

### Rule 3 — Objects must be constructed in the same block they are used

Never write `local sig2 = lurek.event.newSignal()` as a free-standing line with no follow-up.
If you construct an object it must be used non-trivially in the same block.

### Rule 4 — Use game-domain values everywhere

| WRONG | RIGHT |
|-------|-------|
| `0`, `1`, `true`, `nil` | `100` (hp), `0.016` (delta time), `"hero_walk.png"` |
| `"test"` | `"player_died"`, `"level_complete"` |
| `"TODO"` | never |
| `local x = func()` with no print/use | always store AND print/use |

### Rule 5 — Only guard truly destructive calls

```lua
-- These cannot execute in a running headless example -- wrap them
if false then
    lurek.event.quit()
    lurek.window.close()
end
```

Everything else must be actually called.

---

## FILE STRUCTURE — per stub block

Each stub block in the file transforms from this:

```lua
-- ---- Stub: ModuleName:method -----------------------------------------------
--@api-stub: ModuleName:method
-- One-line auto-generated docstring.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- stub_object:method(args)
-- (replace stub_object with your real instance above)
```

To exactly this (no more, no less):

```lua
-- ---- Stub: ModuleName:method -----------------------------------------------
--@api-stub: ModuleName:method
-- 1-3 lines explaining WHEN to use this and WHY, written for a game developer.
-- Focus on the game context, not the technical definition.
local result = real_object:method(real_game_args)
-- 5-15 lines of real game logic: conditionals, loops, print of meaningful values,
-- comments showing what happens next in a real game (e.g. -- spawn particle here)
-- Objects from earlier stubs in the same file are reused here.
```

**The file is NOT restructured into scenario blocks. Each stub stays in its original position.
The header line (`-- ---- Stub:`) and `--@api-stub:` marker are NEVER moved or removed.**

---

## EXECUTION MODEL

Process exactly **4 modules per outer batch**. Never load more than one module spec at a time.

```
for each module in batch:
    1. run: python tools/audit/example_coverage.py --module <module> --stubs
       -> get the list of all --@api-stub: blocks that need replacing

    2. run: python tools/audit/example_coverage.py --module <module> --missing
       -> also check for items not even stubbed

    3. read docs/specs/<module>.md
       -> understand what the module DOES (not just function signatures)

    4. read the existing content/examples/<module>.lua
       -> note every --@api-stub: block: these ALL must become real code

    5. PLAN scenarios first (do not write code yet):
       - Every --@api-stub: item must belong to exactly one scenario
       - Group related API items into 3-7 real game tasks
       - Minor getters/setters -> group into a "utility queries" block at end of nearest scenario
       - NO STUB MAY BE LEFT BEHIND

    6. Edit each stub block in-place (do NOT restructure the file):
       - KEEP the `-- ---- Stub:` header line unchanged
       - KEEP the `--@api-stub:` marker line unchanged
       - REMOVE the original one-line docstring
       - REMOVE the `-- TODO: replace this stub...` line
       - REMOVE the `-- stub_name:method(args)` dummy call line
       - REMOVE the `-- (replace stub_name with ...)` line
       - ADD 1-3 contextual comment lines (WHEN / WHY to use this API)
       - ADD 5-15 lines of real, contextual Lua code
       - Objects created in early stubs are reused by later stubs in the same file

    7. run: python tools/audit/example_coverage.py --module <module>
       - Must show 0 in Stub column before moving to next module
       - Must show 100% before moving to next module

    8. run: python tools/audit/example_coverage.py --module <module> --stubs
       - Must show: 0 items with "-- TODO:" remaining
       - All --@api-stub: markers are still present (coverage counter reads them)
```

---

## ANTI-PATTERNS CHECKLIST — FAIL ANY OF THESE AND REWRITE

| Anti-pattern | Why it fails |
|---|---|
| Any `--@api-stub:` line remaining in file | stub not replaced — incomplete work |
| Any `-- TODO: replace this stub` line remaining | stub not replaced — incomplete work |
| `local x = func()` with no print/use | invisible result — user cannot see what happened |
| `print("type: " .. obj:type())` as standalone section | type() has no standalone use case; group it |
| A scenario with only one function | that is not a scenario; group it with related calls |
| Args of `nil`, `0`, `""` for non-trivial params | teaches nothing about valid input |
| A scenario named after the function, not after the task | rewrite: "lurek.timer.after" -> "schedule bullet despawn" |
| More than 8 free-standing `print(...)` lines with no code between them | enumeration, not an example |

---

## QUALITY GATES (must ALL pass before committing)

1. **No stubs** — `python tools/audit/example_coverage.py --module <module> --stubs` prints "No stub blocks remaining."
2. **Full coverage** — `python tools/audit/example_coverage.py --module <module>` shows Stub column = 0 and % = 100%
3. **Scenario count** — at least 3 distinct named scenarios in the file
4. **Game values** — no `nil`, `"TODO"`, meaningless `0` for important params
5. **ASCII only** — no Unicode characters in any comment line
6. **Reader test** — a developer who has never seen this module can read the file and know: what the module is for, when to use each function, what the return values mean

---

## Batch Execution Order

Process in batches of 4, smallest-first:

| Batch | Modules                                      |
|-------|----------------------------------------------|
| 1     | collision(4), spine(19), sprite(18), save(23)      |
| 2     | system(25), procgen(29), automation(28), tween(35) |
| 3     | thread(37), mods(40), network(40), raycaster(41)   |
| 4     | camera(41), window(50), i18n(31), parallax(43)     |
| 5     | debugbridge(14), minimap(56), scene(52), ecs(57)   |
| 6     | data(42), compute(67), dataframe(64), image(67)    |
| 7     | docs(75), pipeline(60), pathfind(73), animation(46)|
| 8     | input(81), light(85), particle(86), terminal(82)   |
| 9     | filesystem(49), devtools(48), graph(112), effect(142) |
| 10    | physics(160), patterns(170), tilemap(135), render(183) |
| 11    | ai(254), ui(366)                              |

---

## Outputs

- All `content/examples/<module>.lua` files at 100% coverage with 0 stubs
- `python tools/audit/example_coverage.py --stubs` prints "No stub blocks remaining."
- `python tools/audit/example_coverage.py --summary` shows Stub column = 0 for all modules
- Each file has at least 3 named scenario blocks
- Reader test passes: the file reads like a short tutorial, not a function list


**Purpose**: Write `content/examples/<module>.lua` files that teach users *when* and *why* to use
each API. The primary audience is a game developer who has never used this module before.
**Use When**: A module example has `-- STUBS:` sections or 0% coverage in `example_coverage.py`.
**Do Not Use When**: The example already covers 100% (`example_coverage.py --module <name>`).
**Scope**: `content/examples/<module>.lua` only — no `src/` changes.

---
