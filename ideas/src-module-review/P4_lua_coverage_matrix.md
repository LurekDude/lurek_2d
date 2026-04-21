# P4 — Lua Test-Coverage Matrix (READ-ONLY)

- **Session**: `src-module-review-20260418`
- **Phase**: P4 (Tester, read-only)
- **Branch**: `refactor/src-migration-v2`
- **Inputs**: `src/lua_api/*.rs` (49 modules, 3622 names) · `tests/lua/**/*.lua` (348 files) · `tests/lua/harness.rs`
- **Tool**: `python tools/audit/test_coverage.py --json --output work/src-module-review-20260418/data/p4_test_coverage.json`
- **Builder**: `work/src-module-review-20260418/scripts/p4_build_matrix.py`
- **Source data**: `work/src-module-review-20260418/data/p4_matrix.json`

## Status legend

- **COVERED** — `lua_name` appears in ≥1 test file within ±3 lines of an `assert`/`expect_*` call (heuristic for non-trivial assertion context).
- **PARTIAL** — `lua_name` appears in ≥1 test file but with no nearby assertion (e.g. set-up call, comment, or smoke reference only).
- **MISSING** — `lua_name` does NOT appear in any `tests/lua/**/*.lua` file (taken verbatim from `test_coverage.py` `uncovered_items`).

**Important caveat — `assertion_context_check` heuristic.** `tools/audit/test_coverage.py` only distinguishes covered vs uncovered (substring match anywhere). The COVERED/PARTIAL split below is a *new* P4-only heuristic; see Section 5 for tool-vs-manual reconciliation. The split is intentionally conservative: many PARTIAL entries are likely COVERED in practice (e.g. methods on objects whose name appears once on the constructor-line and is then aliased to a local variable used in subsequent asserts).

## Section 1 — Per-module matrix

| Family | Module | Total | Covered | Partial | Missing | Coverage % | Tool reports MISSING (uncovered_items) |
|---|---|---:|---:|---:|---:|---:|---:|
| E | `ai` | 254 | 51 | 197 | 6 | 97.6% | 6 |
| D | `animation` | 46 | 4 | 39 | 3 | 93.5% | 3 |
| C | `audio` | 212 | 53 | 141 | 18 | 91.5% | 18 |
| B | `automation` | 28 | 0 | 28 | 0 | 100.0% | 0 |
| D | `camera` | 41 | 1 | 30 | 10 | 75.6% | 10 |
| E | `collision` | 4 | 4 | 0 | 0 | 100.0% | 0 |
| F | `compute` | 67 | 8 | 55 | 4 | 94.0% | 4 |
| A | `data` | 42 | 18 | 21 | 3 | 92.9% | 3 |
| F | `dataframe` | 64 | 12 | 51 | 1 | 98.4% | 1 |
| F | `debugbridge` | 14 | 12 | 2 | 0 | 100.0% | 0 |
| F | `devtools` | 48 | 33 | 12 | 3 | 93.8% | 3 |
| F | `docs` | 75 | 13 | 38 | 24 | 68.0% | 24 |
| B | `ecs` | 57 | 9 | 47 | 1 | 98.2% | 1 |
| D | `effect` | 142 | 6 | 129 | 7 | 95.1% | 7 |
| B | `engine` | 10 | 8 | 0 | 2 | 80.0% | 2 |
| A | `event` | 22 | 2 | 20 | 0 | 100.0% | 0 |
| C | `filesystem` | 49 | 6 | 40 | 3 | 93.9% | 3 |
| F | `graph` | 112 | 4 | 106 | 2 | 98.2% | 2 |
| C | `i18n` | 31 | 0 | 26 | 5 | 83.9% | 5 |
| C | `image` | 67 | 0 | 62 | 5 | 92.5% | 5 |
| C | `input` | 81 | 30 | 51 | 0 | 100.0% | 0 |
| D | `light` | 85 | 18 | 61 | 6 | 92.9% | 6 |
| A | `log` | 18 | 14 | 4 | 0 | 100.0% | 0 |
| A | `math` | 179 | 55 | 94 | 30 | 83.2% | 30 |
| E | `minimap` | 56 | 2 | 54 | 0 | 100.0% | 0 |
| F | `mods` | 40 | 0 | 31 | 9 | 77.5% | 9 |
| C | `network` | 40 | 6 | 19 | 15 | 62.5% | 15 |
| D | `parallax` | 43 | 3 | 38 | 2 | 95.3% | 2 |
| D | `particle` | 86 | 1 | 79 | 6 | 93.0% | 6 |
| E | `pathfind` | 73 | 4 | 64 | 5 | 93.2% | 5 |
| B | `patterns` | 170 | 22 | 135 | 13 | 92.4% | 13 |
| E | `physics` | 160 | 128 | 19 | 13 | 91.9% | 13 |
| D | `pipeline` | 60 | 3 | 47 | 10 | 83.3% | 10 |
| E | `procgen` | 29 | 27 | 1 | 1 | 96.6% | 1 |
| E | `raycaster` | 41 | 14 | 27 | 0 | 100.0% | 0 |
| D | `render` | 183 | 10 | 131 | 42 | 77.0% | 42 |
| C | `save` | 23 | 0 | 20 | 3 | 87.0% | 3 |
| B | `scene` | 52 | 46 | 6 | 0 | 100.0% | 0 |
| A | `serial` | 10 | 0 | 10 | 0 | 100.0% | 0 |
| E | `spine` | 19 | 2 | 17 | 0 | 100.0% | 0 |
| D | `sprite` | 18 | 5 | 13 | 0 | 100.0% | 0 |
| C | `system` | 25 | 0 | 23 | 2 | 92.0% | 2 |
| F | `terminal` | 82 | 27 | 42 | 13 | 84.1% | 13 |
| A | `thread` | 37 | 6 | 31 | 0 | 100.0% | 0 |
| E | `tilemap` | 135 | 35 | 85 | 15 | 88.9% | 15 |
| A | `timer` | 41 | 4 | 35 | 2 | 95.1% | 2 |
| D | `tween` | 35 | 19 | 16 | 0 | 100.0% | 0 |
| F | `ui` | 366 | 4 | 319 | 43 | 88.3% | 43 |
| C | `window` | 50 | 45 | 1 | 4 | 92.0% | 4 |
| — | **TOTAL** | **3622** | **774** | **2517** | **331** | **90.9%** | **331** |

## Section 2 — Top 10 missing-count offenders (P3-* priority)

These modules carry the highest absolute missing-count and become the first test-authoring targets when the cargo blocker is resolved. Roll the missing names into the matching P3-* family commit per PLAN.md §4.

| Rank | Family | Module | Missing | Total | Coverage % | Suggested phase |
|---:|---|---|---:|---:|---:|---|
| 1 | F | `ui` | 43 | 366 | 88.3% | P3-F |
| 2 | D | `render` | 42 | 183 | 77.0% | P3-D |
| 3 | A | `math` | 30 | 179 | 83.2% | P3-A |
| 4 | F | `docs` | 24 | 75 | 68.0% | P3-F |
| 5 | C | `audio` | 18 | 212 | 91.5% | P3-C |
| 6 | C | `network` | 15 | 40 | 62.5% | P3-C |
| 7 | E | `tilemap` | 15 | 135 | 88.9% | P3-E |
| 8 | B | `patterns` | 13 | 170 | 92.4% | P3-B |
| 9 | E | `physics` | 13 | 160 | 91.9% | P3-E |
| 10 | F | `terminal` | 13 | 82 | 84.1% | P3-F |

## Section 3 — Full MISSING-name list per module

Full list is in companion file [`work/src-module-review-20260418/data/P4_missing_names_full.md`](../data/P4_missing_names_full.md) to keep this report under the 500-line cap. Each entry there is formatted for direct P3-* developer consumption (one line per missing name, with file:line back-reference).

## Section 4 — `tests/lua/harness.rs` registration drift

Per repo convention, `tests/lua/harness.rs` registers each Lua test file MANUALLY. Drift in either direction is a real-bug surface.

### 4.1 — Files on disk but NOT registered in harness (orphan tests — never run)

- `tests/lua/unit/test_runtime.lua`

### 4.2 — Harness references to files that DO NOT exist (broken `run_lua_test()` paths)

- `tests/lua/examples/test_examples.lua`

**Total drift: 1 (orphan) + 1 (broken) = 2.**

## Section 5 — Tool-vs-manual reconciliation notes

`tools/audit/test_coverage.py` and the P4 manual matrix agree EXACTLY on the MISSING set (331 names) — the matrix's MISSING column is sourced verbatim from the tool's `uncovered_items`. There is no disagreement on the binary covered/uncovered axis.

The disagreements that do exist are limitations of `test_coverage.py`, not bugs in the matrix:

1. **No COVERED/PARTIAL distinction.** The tool counts a name as covered if its lowercase substring appears anywhere in any `*.lua` test file. The P4 matrix's `PARTIAL` column (2517 names) calls out cases where the name appears but no `assert`/`expect_*` lives within ±3 lines. **Follow-up**: extend `test_coverage.py` with an optional `--strict` mode that distinguishes assertion-adjacent references from incidental ones (issue this as a tooling enhancement, NOT a P3-* blocker).
2. **Substring false positives.** Short Lua names (e.g. `new`, `update`, `draw`, `set`, `get`) match almost every test file. The matrix inherits this — the COVERED/PARTIAL/MISSING totals over-count short-named methods. The MISSING column is unaffected (a name truly absent is truly absent). **Follow-up**: use the `owner_type` column from `gen_lua_api` to scope short-name searches to test files that mention the owner.
3. **No per-file attribution.** Both the tool and this matrix only know whether a name is tested SOMEWHERE; they do not pinpoint which test file. P3-* developers needing this should `grep_search` for `<lua_name>` under `tests/lua/<module>/`.
4. **`compute_api` registers as `lurek.compute`** (not `lurek.compute` despite some doc references) — the matrix uses the registration name. This matches repo memory; no follow-up needed.
5. **`data_api` and `dataframe_api` always-on** regardless of `ModulesConfig` flags — both modules appear in the matrix unconditionally. This matches repo memory; flag for P2 thin-wrapper audit, not P4.
6. **Module name normalisation.** The tool maps `src/lua_api/<m>_api.rs` to module `<m>` (so `engine_api.rs` → `engine`, `system_api.rs` → `system`). The PLAN.md family table calls module B `engine` (file lives at `src/engine/`); families are assigned via `FAMILY` map in `p4_build_matrix.py` — manual and tool agree.

### Top 5 modules where PARTIAL is suspiciously high (>80%)

These are the modules where the COVERED/PARTIAL split is least trustworthy due to short-name substring noise; reviewers should weight them lower when prioritising:

| Module | Total | Partial | Partial % |
|---|---:|---:|---:|
| `automation` | 28 | 28 | 100.0% |
| `minimap` | 56 | 54 | 96.4% |
| `graph` | 112 | 106 | 94.6% |
| `image` | 67 | 62 | 92.5% |
| `system` | 25 | 23 | 92.0% |

---

**Phase result**: PASS (READ-ONLY, no test files created or modified).

**Next**: Manager appends JSONL log entry, holds matrix until cargo blocker (MSVC BuildTools) is resolved. P3-* family Developers consume Section 3 (companion file) and Section 4 (harness drift) when authoring/registering tests in their family commit.
