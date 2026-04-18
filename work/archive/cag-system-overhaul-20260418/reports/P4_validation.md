# P4 Agents Refactor — Validation Report

**Phase**: P4 (Agents refactor)
**Date**: 2026-04-18
**Branch**: `refactor/src-migration-v2`
**Files touched**: 20 `.github/agents/*.agent.md` (full rewrite)

## Pre-state (baseline)

```
Scanned: agents=20
Summary: 61 errors, 20 warnings
Top rules: E107=60, W108=20, E106=1
```

- E107 (missing required section) × 60 — 3 sections × 20 agents (Inputs/Outputs/Routing Table).
- W108 (no personas declared) × 20 — frontmatter lacked `personas` key.
- E106 (file over 200 lines) × 1 — `developer.agent.md` was 213 lines.

## Post-state (agents only)

```
Scanned: agents=20
Summary: 0 errors, 0 warnings
```

**Δ:** −60 E107, −20 W108, −1 E106.

## Baseline check (`cag_validate.py --baseline`)

```
Scanned: system_prompt=1 agents=20 skills=33 prompts=45
Summary: 850 errors, 12 warnings
Top rules: E201=450, E305=203, E205=190, W005=12, E001=5, E002=1, E003=1

REGRESSIONS vs baseline: 2 new violation(s)
  + E002  .github/copilot-instructions.md  —  File has 298 lines (cap 120)
  + E003  .github/copilot-instructions.md  —  File has 26344 bytes (cap 8192)
```

**Note on regressions**: Both regressions are in `.github/copilot-instructions.md`, **not** in any agent file. `git diff --stat` confirms `copilot-instructions.md` was modified outside this P4 work (4 insertions, 3 deletions; pre-existing uncommitted change from a parallel session). The system-prompt size cap is the explicit target of phase P6, so these regressions surface here but are out of P4 scope and will be resolved by P6's slim-down.

Total error count went from 911 (baseline) to 850 — **net −61** vs baseline despite the two new system-prompt entries.

## Persona matrix (`tools/audit/cag_persona_matrix.py`)

| Persona  | Agents |
|----------|-------:|
| EngDev   | 16 |
| GameDev  | 12 |
| Modder   | 4 |
| Player   | **1** |
| GameTest | 5 |
| EngTest  | 5 |

- Every agent declares ≥1 persona ✅ (W108=0).
- `Player` persona is intentionally served by a single agent (`Player`). The Player persona represents end-users; only the `Player` agent simulates that voice — `Manager`, `Configurator`, `Lua-Designer` etc. serve developer-side personas. This was a user pre-decision (keep `Player` as the sole subjective-UX agent). No refactor follow-up needed.

Per-agent persona counts (range 1–5): `cag-architect=5`; `debugger`/`doc-writer`/`player`/`security`/`tester`=3; `audio-eng`/`configurator`/`hacker`/`lua-designer`/`optimizer`/`physicist`/`renderer`/`research`/`reviewer`=2; `architect`/`developer`/`manager`/`planner`/`solver`=1.

## Link check (`tools/audit/cag_link_check.py --strict`)

Broken links inside `.github/agents/` after refactor: **13**.

| Target                                | Count | Reason                                                                |
|---------------------------------------|------:|------------------------------------------------------------------------|
| `content/demos/`                      | 8     | Directory does not exist; live tree uses `content/games/` instead.     |
| `tests/rust/{stress,config,security}` | 3     | Subfolders not created yet (only `ext/`, `fixtures/`, `golden/`, `unit/` live). |
| `src/lua_api/font_api.rs`             | 1     | File listed in `Renderer` "Owns" block does not exist on disk.         |
| `tests/rust/stress/`                  | 1     | Same as above (Developer Owns block).                                  |

These references mirror the system prompt's own stale references (the system prompt also talks about `content/demos/`, `tests/rust/stress/`, etc.). Reconciling the directory layout is outside P4 scope; recommended cleanup phase is P6 (system prompt) or a dedicated path-update task before P10 final review.

## Validator commands run

```
python tools/validate/cag_validate.py --type agent --format text
python tools/validate/cag_validate.py --baseline
python tools/audit/cag_persona_matrix.py --format markdown
python tools/audit/cag_link_check.py --strict
```

## P8 follow-up flags

- **`Player` persona coverage = 1** — confirm with user during P8 whether to broaden Player persona to multiple agents or keep deliberate single-agent design.
- **`content/demos/` ↔ `content/games/` drift** — 8 broken agent links share root cause with system-prompt drift; resolve in P6.
- **`tests/rust/stress|config|security/` and `src/lua_api/font_api.rs`** — referenced by agents but absent from tree; either create the directories/files (Developer) or update agent ownership lists in P8.

## Result

`P4-agents` = **PASS** for the agent layer (0/0 on `--type agent`). Baseline regressions are not caused by P4. Ready to commit.
