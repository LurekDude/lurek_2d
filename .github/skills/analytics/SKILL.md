---
name: analytics
description: "Load this skill when collecting, parsing, or acting on diagnostic data from Lurek2D log files, performance counters, telemetry events, or game session records: structuring game events for analysis, extracting performance metrics from RUST_LOG output, finding crash patterns, using data to drive game balance or design decisions, or building an in-game telemetry pipeline. Use for: log parsing, session event recording, crash frequency analysis, performance histogram analysis, data-driven game balance. Skip it for live runtime debugging (use dev-debugging skill) or setting up log output (use logging skill)."
---
# analytics

## Mission

# Analytics — Lurek2D

## When To Load

- Parsing `RUST_LOG` output or `game.log` files to find crash patterns or regressions
- Designing an in-game telemetry event pipeline (what to record, how to store it)
- Analysing performance data to find frame spikes or slow sections
- Using play data to make game balance or design decisions
- Correlating player behaviour with game design outcomes
- Reporting session statistics after a playtest

## When To Skip

- Skip it for live runtime debugging (use dev-debugging skill) or setting up log output (use logging skill).

## Domain Knowledge

### Owns
- In-game event recording pipeline (Lua side)
- Log file parsing strategies for Rust engine output
- Performance counter collection (FPS, draw calls, GC, physics step time)
- Session event schema conventions
- Offline analysis workflow (PowerShell / Python scripts on log files)
- Decision heuristics: what data to collect, how to act on findings

---

### Two Tiers of Analytics
| Tier | Source | Analysis | Use for |
|------|--------|----------|---------|
| **Engine telemetry** | `RUST_LOG` output, debug overlay | Offline grep/awk/Python | Performance regressions, crash frequency |
| **Game telemetry** | Custom `lua.filesystem.append()` calls in scripts | Offline parse + visualise | Balance, funnel analysis, UX issues |

---

### Tier 1: Engine Log Analysis
### Collecting engine logs

> See [snippets/collecting-engine-logs.ps1](snippets/collecting-engine-logs.ps1) for the example.

### Extracting frame times

> See [snippets/extracting-frame-times.ps1](snippets/extracting-frame-times.ps1) for the example.

### Finding errors and warnings

> See [snippets/finding-errors-and-warnings.ps1](snippets/finding-errors-and-warnings.ps1) for the example.

### Finding performance spikes (Python)

> See [examples/finding-performance-spikes-python.py](examples/finding-performance-spikes-python.py) for the example.

---

### Tier 2: Game Telemetry Pipeline
### Event schema

Define events as TOML structures recorded per-session. Keep it flat and human-readable:

> See [snippets/event-schema.txt](snippets/event-schema.txt) for the example.

### Lua recording helpers

> See [examples/lua-recording-helpers.lua](examples/lua-recording-helpers.lua) for the example.

> See [examples/lua-recording-helpers-2.lua](examples/lua-recording-helpers-2.lua) for the example.

---

### What Events to Record
### Always record

| Event | Key fields | Use for |
|-------|-----------|---------|
| `game_start` | level, version | Session funnel |
| `player_died` | x, y, cause | Death heatmaps, difficulty spikes |
| `level_complete` | level, duration, attempts | Pacing analysis |
| `game_quit` | reason (menu/esc/crash) | Drop-off funnel |

### Record when tuning balance

| Event | Key fields | Use for |

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/collecting-engine-logs.ps1](snippets/collecting-engine-logs.ps1) — Collecting engine logs
- [snippets/extracting-frame-times.ps1](snippets/extracting-frame-times.ps1) — Extracting frame times
- [snippets/finding-errors-and-warnings.ps1](snippets/finding-errors-and-warnings.ps1) — Finding errors and warnings
- [examples/finding-performance-spikes-python.py](examples/finding-performance-spikes-python.py) — Finding performance spikes (Python)
- [snippets/event-schema.txt](snippets/event-schema.txt) — Event schema
- [examples/lua-recording-helpers.lua](examples/lua-recording-helpers.lua) — Lua recording helpers
- [examples/lua-recording-helpers-2.lua](examples/lua-recording-helpers-2.lua) — Lua recording helpers
- [examples/record-for-performance-analysis.lua](examples/record-for-performance-analysis.lua) — Record for performance analysis
- [examples/death-heatmap-python.py](examples/death-heatmap-python.py) — Death heatmap (Python)
- [snippets/level-completion-funnel-powershell.ps1](snippets/level-completion-funnel-powershell.ps1) — Level completion funnel (PowerShell)
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
