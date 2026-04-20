# Test Migration Roadmap (TST-01..TST-04)

> Status: live planning doc, born 2026-04-20 in session `testing-cleanup-20260420`.
> Pilots landed: tween (P5), raycaster (P6), timer mod.rs (P7).

## 1. Goals

- Bring `src/` to **0 inline `#[cfg(test)]` blocks**, **0 thin-wrapper VIOLATIONs**, and **0 thin `mod.rs` VIOLATIONs**, satisfying [TST-01..TST-04 in philosophy.md § Testing Constraints](philosophy.md#testing-constraints).
- Every behaviour reachable via `lurek.*` MUST be tested in `tests/lua/` (TST-01); internal Rust-only behaviour migrates to `tests/rust/unit/<module>_tests.rs` (TST-02).
- Keep `src/lua_api/<module>_api.rs` thin (TST-03) and `src/**/mod.rs` declarations-only (TST-04). End state: `inline_test_audit.py`, `thin_wrapper_audit.py`, and `thin_modrs_audit.py` all exit 0.

## 2. Current baseline (post-pilots)

Counts as of 2026-04-20 (session P8), captured from `python tools/audit/inline_test_audit.py`, `…/thin_wrapper_audit.py`, `…/thin_modrs_audit.py`:

- **Inline `#[cfg(test)]`**: 172 blocks across 31 modules, 1197 `#[test]` fns. Pilots reduced raw count from baseline 178.
- **Thin-wrapper VIOLATIONs**: 5 files (41 SUSPECT, 4 CLEAN — 50 scanned).
- **Thin `mod.rs` VIOLATIONs**: 7 files (44 CLEAN — 51 scanned).

Top 15 modules by inline-block count:

| module     | inline blocks | top file (#[test] fns) | wrapper status (`<module>_api.rs`) | mod.rs status |
| ---------- | ------------: | ---------------------- | ---------------------------------- | ------------- |
| ai         |            27 | —                      | SUSPECT (score 2)                  | CLEAN         |
| pathfind   |            18 | —                      | CLEAN/SUSPECT                      | CLEAN         |
| effect     |            13 | —                      | CLEAN/SUSPECT                      | CLEAN         |
| tilemap    |            12 | `mapgen.rs` (27)       | CLEAN/SUSPECT                      | CLEAN         |
| animation  |            10 | —                      | SUSPECT (score 2)                  | CLEAN         |
| image      |             9 | `effects.rs` (31)      | CLEAN/SUSPECT                      | CLEAN (visualization/mod.rs VIOLATION) |
| network    |             9 | —                      | **VIOLATION**                      | CLEAN         |
| physics    |             7 | —                      | CLEAN/SUSPECT                      | CLEAN         |
| graph      |             6 | —                      | CLEAN/SUSPECT                      | CLEAN         |
| particle   |             6 | —                      | CLEAN/SUSPECT                      | CLEAN         |
| spine      |             6 | `skeleton.rs` (24)     | CLEAN/SUSPECT                      | CLEAN         |
| terminal   |             6 | —                      | **VIOLATION**                      | CLEAN         |
| audio      |             5 | —                      | SUSPECT (score 2)                  | **VIOLATION** |
| devtools   |             5 | —                      | SUSPECT (score 2)                  | CLEAN         |
| docs       |             5 | —                      | n/a                                | CLEAN         |

Plus tail: i18n 3, parallax 3, app 2, debugbridge 2, filesystem 2, math 2, minimap 2, render 2, save 2, scene 2, then data/input/mods/procgen/runtime/sprite at 1 each.

Other `mod.rs` VIOLATIONs (post-P7): `src/lua_api/mod.rs` (469 lines), `src/math/mod.rs` (170), `src/log/mod.rs` (110), `src/audio/mod.rs` (108), `src/ui/mod.rs` (79), `src/image/visualization/mod.rs` (51), `src/window/mod.rs` (34).

Wrapper VIOLATIONs: `src/lua_api/{mods_api,network_api,terminal_api,ui_api,patterns_api}.rs`.

## 3. Migration waves

Sorted by inline-block density and grouped into seven waves. Module entries show `inline blocks` → est. `#[test]` count, plus any wrapper / mod.rs co-violation to fix in the same wave.

### Wave W1 — Heavy modules (~80 blocks, ~250+ tests)

- `ai` — 27 blocks, ~120 tests; co-fix `lua_api/ai_api.rs` SUSPECT review.
- `pathfind` — 18 blocks, ~80 tests.
- `effect` — 13 blocks, ~50 tests.
- `tilemap` — 12 blocks, `mapgen.rs` alone has 27 tests.
- `animation` — 10 blocks, ~40 tests; co-fix `animation_api.rs` SUSPECT.

### Wave W2 — Medium-high (~43 blocks, ~150 tests)

- `image` — 9 blocks, `effects.rs` 31 tests; co-fix `image/visualization/mod.rs` VIOLATION.
- `network` — 9 blocks; **co-fix `network_api.rs` VIOLATION (W5 candidate, do here for atomic split)**.
- `physics` — 7 blocks.
- `graph` — 6 blocks.
- `particle` — 6 blocks.
- `spine` — 6 blocks, `skeleton.rs` 24 tests.

### Wave W3 — Medium (~26 blocks, ~80 tests)

- `terminal` — 6 blocks; **co-fix `terminal_api.rs` VIOLATION**.
- `audio` — 5 blocks, ~20 tests; **co-fix `audio/mod.rs` VIOLATION**.
- `devtools` — 5 blocks.
- `docs` — 5 blocks (likely Rust-internal — most go to `tests/rust/unit/`).
- `i18n` — 3 blocks, `catalog.rs` 18 tests.
- `parallax` — 3 blocks.

### Wave W4 — Light tail (~17 blocks, ~80 tests)

- `app` 2 (`app.rs` 19 tests), `debugbridge` 2, `filesystem` 2, `math` 2, `minimap` 2, `render` 2 (`shader.rs` 17 tests), `save` 2 (`save_manager.rs` 21 tests), `scene` 2 (`transition.rs` 26 tests), then `data`, `input` (`keyboard.rs` 20 tests), `mods` (`mod_manager.rs` 17 tests), `procgen`, `runtime`, `sprite` at 1 each.

### Wave W5 — Thin-wrapper VIOLATION refactors (residue from W2/W3)

- `src/lua_api/ui_api.rs` (score 4, 128 hotspots) — biggest split.
- `src/lua_api/patterns_api.rs` (score 3, 72 hotspots).
- `src/lua_api/mods_api.rs`, `network_api.rs`, `terminal_api.rs` — only if not absorbed into W2/W3 atomic commits.

### Wave W6 — Thin `mod.rs` VIOLATIONs (residue post-P7)

- `src/lua_api/mod.rs` (469 lines, 169 stray) — largest, schedule first.
- `src/math/mod.rs`, `src/log/mod.rs`, `src/audio/mod.rs` (do alongside W3 audio wave), `src/ui/mod.rs`, `src/image/visualization/mod.rs` (do alongside W2 image wave), `src/window/mod.rs`.

### Wave W7 (optional / stretch) — SUSPECT thin-wrapper sweep

- 41 SUSPECT files in `src/lua_api/`. Promote to VIOLATION-grade only when a second smell appears (long fn, stdcoll import, hotspot count > 50). Triage pass; do not block TST-03 closure on this wave.

## 4. Per-wave done-when gates

For every wave W*x*:

1. `python tools/audit/inline_test_audit.py` reports **0 blocks for every module in the wave**.
2. `cargo test --test engine_tests` and `cargo test --test lua_tests` both exit 0.
3. Clippy clean for touched files only — scope via `cargo clippy --lib --tests -p lurek2d -- -D warnings` filtered to changed paths in PR review. **Note**: global clippy currently reports ~168 ambient errors on `refactor/src-migration-v2`; that backlog is tracked separately and must clear before TST gates can be enforced repo-wide.
4. For waves with co-violations: rerun the matching `thin_wrapper_audit.py` / `thin_modrs_audit.py` and confirm the listed file moved out of VIOLATION.
5. Each wave commits per `type(scope): description` (one logical change per commit) and adds a `docs/CHANGELOG.md` bullet.

## 5. Tooling

- [`tools/audit/inline_test_audit.py`](../../tools/audit/inline_test_audit.py) — walks `src/**/*.rs`, lists every inline `#[cfg(test)]` block with suggested target under `tests/rust/unit/<module>_tests.rs` (and `tests/lua/unit/test_<module>.lua` when a matching `lua_api/<module>_api.rs` exists).
- [`tools/audit/thin_wrapper_audit.py`](../../tools/audit/thin_wrapper_audit.py) — scores `src/lua_api/*_api.rs` for non-registration long fns, hotspots outside Lua closures, and `std::collections::*` imports → CLEAN / SUSPECT / VIOLATION.
- [`tools/audit/thin_modrs_audit.py`](../../tools/audit/thin_modrs_audit.py) — flags any `src/**/mod.rs` carrying definitions or > 5 stray non-trivial lines.
- Slash command [`/audit-test-placement`](../../.github/prompts/audit-test-placement.prompt.md) wraps the three scripts behind a single Copilot Chat invocation.
- **Manual harness registration**: every new file under `tests/lua/` MUST be added explicitly to `tests/lua/harness.rs` — there is no auto-discovery. See [test-framework.md](test-framework.md#test-placement) for the registration contract.

## 6. Open risks

- **Ambient clippy backlog (~168 errors)** on `refactor/src-migration-v2` masks per-wave clippy regressions; until cleared, gate §4(3) is enforced per-file in PR review only.
- **Manual `tests/lua/harness.rs` registration is fragile** — easy to land a `tests/lua/unit/test_*.lua` file that is never actually executed. Each wave that adds Lua coverage MUST grep `harness.rs` for the new filename before commit.
- **Private-item cascades** — some inline tests reach `pub(super)` or private items. Migration to `tests/rust/unit/` requires `pub(crate)` exposure or test-only `#[doc(hidden)]` re-exports; budget extra time for `ai`, `pathfind`, `effect`, and `tilemap/mapgen.rs`.
