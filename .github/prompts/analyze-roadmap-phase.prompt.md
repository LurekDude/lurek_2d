---
description: "End-to-end roadmap phase completion: Manager-orchestrated workflow that audits a phase file, builds an evidence matrix of every deliverable, routes gaps to specialist agents for implementation and tests, regenerates docs, re-audits to confirm all gates pass, then marks the phase done."
---

# Validate and Complete Roadmap Phase — End-to-End

## Purpose

The **Manager** owns this workflow from start to finish.
It runs audit → findings → fix plan → implementation → tests → documentation → re-audit → review → phase closure.
Nothing is skipped. Nothing is assumed done.

## Owner

`Manager` agent. All implementation, test, doc, and review steps are routed to the appropriate specialist — the Manager does not write code.

## Skills to Load

Load these **before starting any step**:

1. `.github/skills/roadmap-planning/SKILL.md` — phase format, acceptance gates, status symbols
2. `.github/skills/rust-coding/SKILL.md` — Rust conventions, visibility, public API patterns
3. `.github/skills/testing-rust/SKILL.md` — test patterns, what counts as coverage
4. `.github/skills/lua-api-design/SKILL.md` — `lurek.*` naming, parameter conventions
5. **Domain skill** — match to the phase topic:
   - Graphics / rendering → `gpu-programming`
   - Physics → `physics-engine`
   - Audio → `audio-integration`
   - Input / gamepad / touch → `input-handling`
   - Filesystem / assets → `asset-pipeline`
   - Font / text → `src/render/AGENT.md` (Font Rendering Patterns section)
   - Animation → `animation-system`
   - Timers, math, system, data → `lua-api-design`
   - OO Lua API (Phase 13+) → `lua-api-design`
   - Scene / ECS → `scene-management` / `ecs-architecture`

## Inputs

- `DRY_RUN` — optional `true` to stop after producing the Gap Report without implementing anything (default: `false`)

---

## Workflow Overview

```
PHASE 1 — Audit          → Manager reads phase, builds MDL, runs full source + test audit
PHASE 2 — Findings       → Manager publishes Evidence Matrix + Gap Report (route to user if DRY_RUN=true)
PHASE 3 — Fix Plan       → Manager decomposes gaps into agent-sized tasks with acceptance gates
PHASE 4 — Implementation → Developer / Renderer / Audio-Eng / Physicist implements BLOCKER gaps
PHASE 5 — Tests          → Tester writes missing Rust and Lua tests for every covered deliverable
PHASE 6 — Documentation  → Doc-Writer adds missing /// docstrings; regenerates API reference
PHASE 7 — Re-Audit       → Manager re-runs Stages 3–5 from Phase 1 to confirm all gaps closed
PHASE 8 — Review         → Reviewer runs quality gates and signs off
PHASE 9 — Phase Closure  → Manager updates phase file Status section; moves to done/ if all gates pass
```

Each phase is a checkpoint. Manager confirms acceptance gate before routing to the next phase.
If a gate fails, route back to the responsible agent — do not skip forward.

---

## PHASE 1 — Audit

### Stage 1 — Session Start

**Manager performs these steps before anything else:**

```powershell
git rev-parse --abbrev-ref HEAD        # confirm branch; write to work/branch.txt
git status                             # review working tree
```

Choose a session name from `PHASE_FILE` stem, e.g. `phase-04-audit`.
Create session folder `work/{session}/` with subfolders: `scripts/ handovers/ reports/ data/ content/examples/ other/ temp/ logs/`
Create `work/{session}/logs/agent_log.jsonl` (empty).

---

### Stage 3 — Parse the Phase File

Open `PHASE_FILE` and extract the following into an internal working record. Do not skip any field.

**3a — Header Metadata**: Record phase number, title, Priority, Estimated Scope, `Depends On`, `Blocks`.

**3b — Implementation Tasks Catalogue**: For every `### N.X` task block record:

| Field | What to capture |
|---|---|
| Task ID | `N.X` |
| Task title | The heading text |
| Listed files | Every path named in the `**Files**:` line |
| Described deliverables | Each new struct, enum, function, or Lua binding the task describes |
| Agent | Who owns it |

The result is the **Master Deliverable List (MDL)** — one row per discrete item.
A task describing 5 new Lua functions = 5 MDL rows.

**3c — Acceptance Gates**: Copy every gate from `## Acceptance Gates` verbatim.

**3d — Existing Status Section**: If `## Status` is present, note which tasks are ✅ / 🔄 / ⬜ / ❌ already.

---

### Stage 4 — Dependency Pre-Check

For every phase in `Depends On`:
2. Read its `## Status` section
3. All tasks ✅ → **SATISFIED**; any ⬜ or 🔄 → **UNMET**

Output dependency table:

| Depends On | File Found | Status | Verdict |
|---|---|---|---|
| Phase N | path | summary | SATISFIED / UNMET |

If UNMET: include `⚠️ Dependency Warning` in the report. Do not abort — continue auditing the current phase.

---

### Stage 5 — Source Code Audit

For every MDL row, search `src/` for implementation evidence.

**5a — Rust Check**: For each Rust type or function:
- Locate the file listed in the task; check it exists
- Search for the expected symbol (exact name, not fuzzy)
- Check visibility (`pub` / `pub(crate)`) and presence of `///` docstring
- Record: file found, symbol found (line number), visibility, docstring

**5b — Lua Binding Check**: For each `lurek.*` function:
- Locate `src/lua_api/<module>_api.rs`
- Search for registration — `.set("name", lua.create_function(...))` or equivalent
- Verify name matches spec exactly (lowercase, correct namespace)
- Record: file found, binding registered (line number), name matches

**5c — API Surface Completeness**: Read the full `register()` function. Cross-check every MDL item appears. Note extra items that belong to earlier phases (not a problem — just note).

---

### Stage 6 — Test Coverage Audit

For every MDL row, search `tests/` for coverage evidence.

**6a — Rust Integration Tests**:
- Open `tests/<module>_tests.rs`
- Search for `#[test]` functions exercising the deliverable (use exact symbol name)
- Check assertions are meaningful (not just `assert!(true)`)
- Record: test name, what it asserts, present / missing / partial

**6b — Lua Tests**:
- Check `tests/lua/` for `.lua` files calling the `lurek.*` functions from this phase
- Record: filename, which functions are called, present / missing / N/A (Rust-internal)

**6c — Test Quality Flags** (do not block on these):
- Assertions without meaningful check
- `assert_eq!` on `f32` without epsilon (violates Lurek2D convention)
- `#[ignore]` without explanation

---

### Stage 7 — Acceptance Gates Check

For each gate from Stage 3c:

| Gate | How to Verify |
|---|---|
| `cargo build` succeeds | Run `cargo build` and capture result |
| `cargo test` passes | Run `cargo test <module>_tests` and capture result |
| Named Lua test present | Check file exists; no missing `lurek.*` calls |
| API docs updated | `docs/API/lua_api_reference_generated.md` contains each `lurek.*` function from MDL |
| `cargo clippy -- -D warnings` passes | Run and capture result |

Verdict per gate: **PASS** (with evidence) / **FAIL** (with reason) / **UNVERIFIED** (note what would confirm it).

---

## PHASE 2 — Findings

### Stage 8 — Evidence Matrix

Produce the complete matrix. One row per MDL entry. **Do not aggregate — one deliverable, one row.**

```markdown
| # | Deliverable | Rust Impl | File | Line | Docstring | Lua Binding | Binding Line | Rust Test | Lua Test |
|---|---|---|---|---|---|---|---|---|---|
| N.X.1 | name | ✅/❌/⚠️ | path | N | ✅/❌ | ✅/❌/N/A | N | ✅/❌/⚠️ | ✅/❌/N/A |
```

Legend: ✅ correct | ❌ missing | ⚠️ incomplete or low quality | N/A not applicable

---

### Stage 9 — Gap Report

Every ❌ and ⚠️ from the matrix becomes one gap row:

```markdown
| Gap # | Item | Gap Type | Severity | File to Fix | Recommendation |
|---|---|---|---|---|---|
| G-01 | lurek.audio.seek() | Missing Lua binding | BLOCKER | src/lua_api/audio_api.rs | Register in register() |
| G-02 | AudioSource.seek() | Missing docstring | WARNING | src/audio/mixer.rs | Add /// comment |
| G-03 | test_seek_position | Missing Rust test | WARNING | tests/rust/unit/audio_tests.rs | Add #[test] for seek round-trip |
```

Severity:
- **BLOCKER** — feature absent, binding missing, or acceptance gate hard FAIL
- **WARNING** — present but incomplete (docstring, test, visibility)
- **NOTE** — style/quality issue; does not affect correctness

### Stage 10 — Audit Verdict

```
AUDIT VERDICT: ✅ COMPLETE | 🔄 PARTIAL | ❌ NOT READY

MDL rows: N  |  BLOCKER: N  |  WARNING: N  |  NOTE: N
```

**✅ COMPLETE**: 0 BLOCKERs, 0 failing gates → skip to PHASE 8 (Review).

**🔄 PARTIAL** or **❌ NOT READY**: continue to PHASE 3.

> If `DRY_RUN=true`: stop here. Present the Evidence Matrix + Gap Report to the user and await instruction.

---

## PHASE 3 — Fix Plan

Manager decomposes the Gap Report into agent-sized tasks. One task per gap cluster (group by file and agent).

### Fix Plan Format

```markdown
## Fix Plan

| Fix # | Gaps | Agent | Files | Acceptance Gate |
|---|---|---|---|---|
| F-01 | G-01 | Developer | src/lua_api/audio_api.rs | lurek.audio.seek() callable from Lua; returns correct value |
| F-02 | G-02 | Developer | src/audio/mixer.rs | /// docstring present on AudioSource::seek |
| F-03 | G-03 | Tester | tests/rust/unit/audio_tests.rs | test_seek_position passes in cargo test |
```

**Grouping rules**:
- Same file + same agent → one Fix task
- BLOCKER gaps before WARNING gaps
- Implementation before tests before docs

Manager presents the Fix Plan and waits for user confirmation before proceeding to PHASE 4.

---

## PHASE 4 — Implementation

Manager routes each Fix task to the appropriate specialist agent with a **five-bullet handoff**:

```
1. Task: what to implement (exact function names, file paths, line numbers from audit)
2. Context: relevant MDL items, current gap IDs
3. Constraints: Lurek2D conventions — lurek.* namespace, pub fn register() pattern, no unsafe
4. Files: exact file paths to edit
5. Done-when: binary acceptance gate for this fix task
```

**Routing table**:
| Fix type | Route to |
|---|---|
| Missing Rust struct / fn | `Developer` |
| Missing Lua binding | `Developer` |
| Graphics RenderCommand | `Renderer` |
| Physics body / world | `Physicist` |
| Audio mixer | `Audio-Eng` |
| Input state | `Developer` |

After each fix task returns:
1. Verify the done-when gate (read the file; confirm symbol exists)
2. If gate passes → mark Fix as done; route next Fix
3. If gate fails → route back to the same agent with the failure evidence

---

## PHASE 5 — Tests

Route to **Tester** after all BLOCKER implementation fixes are confirmed.

Handoff to Tester:
```
1. Task: write missing Rust and Lua tests for every WARNING-level gap in the Gap Report
2. Context: Gap Report (G-* items with gap type "Missing Rust test" / "Missing Lua test")
3. Constraints: headless-safe only; float comparisons use (a - b).abs() < 1e-5; no assert_eq! on f32
4. Files: tests/<module>_tests.rs and tests/lua/<module>.lua
5. Done-when: cargo test <module>_tests passes with 0 failures; new tests cover every G-* test gap
```

After Tester returns:
- Run `cargo test <module>_tests` — must pass
- Gate fail → route back to Tester with failure output

---

## PHASE 6 — Documentation

Route to **Doc-Writer** after all tests pass.

Handoff to Doc-Writer:
```
1. Task: add missing /// docstrings for every WARNING-level docstring gap; regenerate API reference
2. Context: Gap Report (G-* items with gap type "Missing docstring")
3. Constraints: one-sentence summary + optional detail; no # Examples unless runnable and tested
4. Files: all Rust files listed in docstring gaps; then run: python tools/docs/gen_lua_api.py
5. Done-when: python tools/docs/collect_docs.py --report-missing shows 0 missing for this module; API ref regenerated
```

After Doc-Writer returns:
- Run `python tools/docs/collect_docs.py --report-missing | Select-String "<module>"` — must show 0 missing
- Gate fail → route back to Doc-Writer

---

## PHASE 7 — Re-Audit

Manager re-runs the full audit (Stages 5–7 from PHASE 1) against the current codebase.

**This is not optional.** Every deliverable must be re-checked after implementation.

Produce an updated Evidence Matrix and Gap Report.

**Re-Audit Gate**:
- Zero BLOCKER gaps → proceed to PHASE 8
- Any remaining BLOCKER → route back to Phase 4 with the specific failing gap; do not proceed
- Only WARNING/NOTE remain → proceed with note in the final report

---

## PHASE 8 — Review

Route to **Reviewer** with the following handoff:
```
1. Task: quality gate review of all files touched during this phase completion run
2. Context: list of all files modified (from the Fix Plan); Evidence Matrix (post re-audit)
3. Constraints: cargo build, cargo test, cargo clippy -- -D warnings must all pass; lurek.* namespace; no unsafe without SAFETY comment
4. Files: all files modified in Phases 4–6
5. Done-when: Reviewer sign-off with 0 BLOCKER findings; WARN/NOTE findings documented but do not block
```

Run quality gates before routing:
```powershell
cargo test
cargo clippy -- -D warnings
cargo fmt --check
```

All must pass. If any fail, fix before routing to Reviewer.

After Reviewer returns:
- 0 BLOCKER findings → proceed to PHASE 9
- Any BLOCKER → route back to Developer with Reviewer's findings; re-run quality gates before re-routing

---

## PHASE 9 — Phase Closure

### Stage 11 — Update Phase File Status Section

Update `PHASE_FILE` — insert or replace `## Status` immediately after the header block (before `## Goal`):

```markdown
## Status

**Completed**: YYYY-MM-DD
**Verdict**: ✅ Complete

| Task | Status | Evidence |
|---|---|---|
| N.1 Name | ✅ Complete | src/path/file.rs:NN — impl + test + docstring |
| N.2 Name | ✅ Complete | src/path/file.rs:NN |
```

Rules:
- If `## Status` already exists, replace it in place — never create a second one
- Never delete original task bodies or As-Built notes
- Preserve all `## Implementation Tasks` content unchanged

### Stage 12 — Move to Done

If ALL acceptance gates pass and Reviewer gave sign-off:

```powershell
```


### Stage 13 — Commit

Stage only the files touched in this entire workflow:

```powershell
# Quality gate before commit
cargo test
cargo clippy -- -D warnings

# Stage only affected files — NEVER git add .

git commit -m "feat(<module>): phase NN complete — <one-line summary>"
```

### Stage 14 — Log Entry

Append to `work/{session}/logs/agent_log.jsonl`:

```json
{"timestamp":"ISO8601","agent":"Manager","session":"session-name","phase":"phase-NN full completion","skills_used":[],"instructions_loaded":[],"tools_used":[],"commands_run":["cargo test","cargo clippy","git commit"],"result":"PASS","findings":[],"handover_to":"none"}
```

---

## Final Output Checklist

Before calling the workflow complete, confirm every item:

- [ ] MDL built — every deliverable in the phase file has a row
- [ ] Evidence Matrix complete — every MDL row has evidence entries
- [ ] Gap Report complete — every ❌ and ⚠️ has a gap row
- [ ] Fix Plan presented and approved
- [ ] All BLOCKER fixes implemented and gates verified
- [ ] All missing tests written and `cargo test` passes
- [ ] All missing docstrings added and `--report-missing` shows 0 for this module
- [ ] Re-Audit run — zero BLOCKERs in updated Evidence Matrix
- [ ] Reviewer sign-off with 0 BLOCKER findings
- [ ] `cargo build`, `cargo test`, `cargo clippy -- -D warnings`, `cargo fmt --check` all pass
- [ ] Phase file `## Status` section updated
- [ ] Commit made with correctly staged files
- [ ] Agent log entry appended

---

## References

- Phase file format: `.github/skills/roadmap-planning/SKILL.md`
- Rust conventions: `.github/skills/rust-coding/SKILL.md`
- Test patterns: `.github/skills/testing-rust/SKILL.md`
- Lua API registry: `src/lua_api/<module>_api.rs` → `pub fn register()`
- API reference: `docs/API/lua_api_reference_generated.md`
- Agents: `Developer` (impl) | `Tester` (tests) | `Doc-Writer` (docs) | `Reviewer` (sign-off) | `Renderer` / `Physicist` / `Audio-Eng` (domain)
