---
name: analytics
description: "Load this skill when collecting, parsing, or acting on diagnostic data from Luna2D log files, performance counters, telemetry events, or game session records: structuring game events for analysis, extracting performance metrics from RUST_LOG output, finding crash patterns, using data to drive game balance or design decisions, or building an in-game telemetry pipeline. Use for: log parsing, session event recording, crash frequency analysis, performance histogram analysis, data-driven game balance. Skip it for live runtime debugging (use dev-debugging skill) or setting up log output (use logging skill)."
---

# Analytics — Luna2D

## Load When

- Parsing `RUST_LOG` output or `game.log` files to find crash patterns or regressions
- Designing an in-game telemetry event pipeline (what to record, how to store it)
- Analysing performance data to find frame spikes or slow sections
- Using play data to make game balance or design decisions
- Correlating player behaviour with game design outcomes
- Reporting session statistics after a playtest

## Owns

- In-game event recording pipeline (Lua side)
- Log file parsing strategies for Rust engine output
- Performance counter collection (FPS, draw calls, GC, physics step time)
- Session event schema conventions
- Offline analysis workflow (PowerShell / Python scripts on log files)
- Decision heuristics: what data to collect, how to act on findings

---

## Two Tiers of Analytics

| Tier | Source | Analysis | Use for |
|------|--------|----------|---------|
| **Engine telemetry** | `RUST_LOG` output, debug overlay | Offline grep/awk/Python | Performance regressions, crash frequency |
| **Game telemetry** | Custom `lua.filesystem.append()` calls in scripts | Offline parse + visualise | Balance, funnel analysis, UX issues |

---

## Tier 1: Engine Log Analysis

### Collecting engine logs

```powershell
# Record a full session with debug output
$env:RUST_LOG = "luna2d=debug,wgpu_core=warn"
cargo run -- demos/my_game 2>&1 | Tee-Object logs/session.log
```

### Extracting frame times

```powershell
# Engine logs frame time at debug level — extract and summarise
Select-String "frame_time" logs/session.log |
    ForEach-Object { ($_ -split "=")[1].Trim().TrimEnd("ms") } |
    Measure-Object -Average -Maximum -Minimum
```

### Finding errors and warnings

```powershell
# All errors in a session
Select-String "\[ERROR\]" logs/session.log

# Warning frequency (top 10 most common)
Select-String "\[WARN\]" logs/session.log |
    ForEach-Object { ($_ -split "]")[-1].Trim() } |
    Group-Object | Sort-Object -Property Count -Descending |
    Select-Object -First 10
```

### Finding performance spikes (Python)

```python
# tools/session_analysis.py
import re, statistics, pathlib

log = pathlib.Path("logs/session.log").read_text()
times = [float(m) for m in re.findall(r"frame_time=(\d+\.\d+)ms", log)]

if times:
    print(f"frames: {len(times)}")
    print(f"avg: {statistics.mean(times):.2f}ms")
    print(f"p95: {sorted(times)[int(len(times)*0.95)]:.2f}ms")
    print(f"max: {max(times):.2f}ms")
    spikes = [t for t in times if t > 33.3]   # > 2 frames at 60fps
    print(f"frame spikes >33ms: {len(spikes)}")
```

---

## Tier 2: Game Telemetry Pipeline

### Event schema

Define events as TOML structures recorded per-session. Keep it flat and human-readable:

```
-- Each line in game.log is a TOML-style event:
-- timestamp=12.34 event="player_died" x=320 y=128 cause="spike" level=3
-- timestamp=45.67 event="level_complete" level=3 attempts=2 duration=93.4
```

### Lua recording helpers

```lua
-- lib/telemetry.lua: include in game scripts
local Telemetry = {}
local _file = "game.log"
local _start = luna.time.getTime()

function Telemetry.init()
    luna.fs.write(_file, "")  -- clear on session start
end

function Telemetry.event(name, data)
    local ts = luna.time.getTime() - _start
    local parts = { string.format('timestamp=%.3f event="%s"', ts, name) }
    for k, v in pairs(data or {}) do
        if type(v) == "string" then
            parts[#parts+1] = string.format('%s="%s"', k, v)
        else
            parts[#parts+1] = string.format('%s=%s', k, tostring(v))
        end
    end
    luna.fs.append(_file, table.concat(parts, " ") .. "\n")
end

return Telemetry
```

```lua
-- Usage in game scripts:
local T = require("lib/telemetry")
T.init()

-- Record meaningful events
T.event("game_start",    { level = currentLevel })
T.event("player_died",   { x = player.x, y = player.y, cause = "spike", attempt = attempt })
T.event("level_complete",{ level = n, duration = elapsed, attempts = attempts })
T.event("item_picked",   { item = name, x = player.x, y = player.y })
T.event("boss_killed",   { boss = name, hp_remaining = boss.hp, time = elapsed })
```

---

## What Events to Record

### Always record

| Event | Key fields | Use for |
|-------|-----------|---------|
| `game_start` | level, version | Session funnel |
| `player_died` | x, y, cause | Death heatmaps, difficulty spikes |
| `level_complete` | level, duration, attempts | Pacing analysis |
| `game_quit` | reason (menu/esc/crash) | Drop-off funnel |

### Record when tuning balance

| Event | Key fields | Use for |
|-------|-----------|---------|
| `item_picked` | item, location | Loot spawn placement |
| `shop_purchase` | item, gold_spent | Economy balance |
| `ability_used` | ability, context | Ability utility |
| `boss_attempt` | boss, attempt_num | Boss difficulty calibration |

### Record for performance analysis

```lua
local _frameTimes = {}

function luna.process(dt)
    _frameTimes[#_frameTimes+1] = dt * 1000  -- ms
    if #_frameTimes >= 600 then              -- every 10s at 60fps
        local avg = 0
        local max = 0
        for _, t in ipairs(_frameTimes) do
            avg = avg + t
            if t > max then max = t end
        end
        avg = avg / #_frameTimes
        T.event("perf_sample", { avg_ms = string.format("%.2f", avg), max_ms = string.format("%.2f", max) })
        _frameTimes = {}
    end
end
```

---

## Offline Analysis Workflow

### Death heatmap (Python)

```python
# Parse death events and print ASCII heatmap
import re, pathlib
from collections import Counter

log = pathlib.Path("logs/game.log").read_text()
deaths = re.findall(r'event="player_died" x=(\d+) y=(\d+)', log)

# Bucket into 64px grid cells
grid = Counter()
for x, y in deaths:
    grid[(int(x)//64, int(y)//64)] += 1

# Print top death zones
for (cx, cy), count in grid.most_common(10):
    print(f"  cell ({cx*64}, {cy*64}): {count} deaths")
```

### Level completion funnel (PowerShell)

```powershell
$log = Get-Content "logs/game.log"
$levels = 1..10
foreach ($lvl in $levels) {
    $starts    = ($log | Select-String "event=.game_start. level=$lvl").Count
    $completes = ($log | Select-String "event=.level_complete. level=$lvl").Count
    $rate = if ($starts -gt 0) { int } else { 0 }
    Write-Host "Level $lvl  starts=$starts  completes=$completes  rate=$rate%"
}
```

---

## Acting on Findings

| Finding | Typical cause | Design action |
|---------|--------------|---------------|
| Death cluster at one map point | Invisible hazard, unfair spike | Move hazard, add visual cue, reduce damage |
| Level 3 completion rate < 30% | Too hard | Add checkpoint, reduce enemy HP, slow projectiles |
| Ability used < 2% of sessions | Hard to access, not useful | Better UI/hint, buff ability, tutorial |
| Frame spikes every ~60s | GC collect, shader recompile | Move GC to level load, pre-warm shader |
| Crash always after 30+ minutes | Memory leak, accumulating draw state | Profile allocation rate, audit resource release |

---

## Privacy Rule

**Never record personal or identifying information in telemetry.** Luna2D is a desktop runtime with no network layer. All logs stay on the local machine unless the game explicitly uploads them. Record only gameplay events, positions, and performance data.
