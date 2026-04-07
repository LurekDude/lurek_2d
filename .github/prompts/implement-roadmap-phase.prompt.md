---
description: "Complete phase implementation from a roadmap file. Runs pre-flight analysis of what already exists, audits external libraries so nothing is hand-rolled unnecessarily, aligns Lua API with API conventions, implements Rust bindings + full docstrings, writes Lua and Rust integration tests, runs all quality gates, generates API docs, and updates the phase file and architecture docs."
---

# Implement Roadmap Phase

## Purpose

End-to-end delivery of a single roadmap phase: read the phase file, understand what already exists, build a concrete implementation plan, write the code, document every public item, test everything, run quality gates, generate updated API docs, and mark the phase complete.

## Skills to Load

Load these skills **before** starting any step. Do not proceed without reading them:

1. `.github/skills/roadmap-planning/SKILL.md` — phase format, acceptance gates, status symbols
2. `.github/skills/lua-api-design/SKILL.md` — `luna.*` naming, parameter conventions, API alignment
3. `.github/skills/rust-coding/SKILL.md` — Rust conventions, error handling, visibility
4. `.github/skills/testing-rust/SKILL.md` — test patterns, float comparisons, headless safety
5. Load domain skill matching the phase: `gpu-programming`, `physics-engine`, `audio-integration`, `input-handling`, `asset-pipeline` — whichever applies; for font/text consult `src/graphics/AGENT.md` (Font Rendering Patterns section)

## Use When

- Picking up a phase that is `⬜ Not Started` or `🔄 In Progress`
- Producing a commit-ready implementation with tests, docs, and a phase status update

## Do Not Use When

- You only need to update the status of an already-completed phase → use `workflow-update-roadmap-phase`
- You are designing a brand-new phase that doesn't exist yet → use `create-roadmap-phase`
- You only need to add a single function → use `create-api-function`

## Inputs

- `SCOPE` — optional: `full` (all tasks in the phase) or a comma-separated list of task IDs to implement, e.g., `2.1, 2.3` (default: `full`)
- `DRY_RUN` — optional `true` to only produce the plan without writing any code (default: `false`)

---

## Step 1 — Read the Phase File

Open `PHASE_FILE` and extract:

- Phase number and title
- Priority, Estimated Scope, Depends On, Blocks
- Goal section (what changes and why)
- Current State Analysis table (what already exists)
- Every `### N.X` implementation task with its listed files and agent
- Acceptance Gates checklist

**Output**: Internal working list of all tasks with their file targets. Do not start implementation yet.

---

## Step 2 — Pre-Flight: Verify Dependencies Are Met

For every phase listed in `Depends On`:

1. Open that phase file
2. Check its `## Status` section — if it does not contain `✅ Complete` for all required tasks, **stop and report** which upstream tasks are unfinished
3. If `Depends On: Nothing` or all dependencies are complete, proceed

**Output**: PASS / FAIL with dependency names. Abort if FAIL.

---

## Step 3 — Codebase Audit: What Already Exists

Before writing a single line of new code, audit what Luna2D already has. This prevents re-implementing existing behaviour and exposes what can be extended rather than replaced.

### 3a — Source File Scan

For each file listed in the phase's task blocks:

1. Check if the file exists
2. If it exists, read its current `pub` API surface (function names, struct fields, trait impls)
3. Record: which tasks are already partially implemented vs fully absent

### 3b — Lua API Surface Scan

Run or simulate:
```
python tools/docs/collect_docs.py --report-missing
```

Read `docs/API/lua_api_reference_generated.md` (if present) and compare with phase's target API functions. Mark each target function as: `present` / `partial` / `missing`.

### 3c — API Convention Check

For every API function the phase intends to add:

2. Find the equivalent reference-engine entry for the target function
3. Record:
   - The reference function name and signature
   - The reference parameter order and semantics
   - Any notes on behaviour differences Luna2D is intentionally keeping
4. Your `luna.*` equivalent MUST:
   - Use consistent parameter **order** where there is a direct mapping
   - Use the same **semantic types** (e.g., angles in radians, colors as 0–1 floats, not 0–255)
    - Use `luna.<module>.<function>` naming — never external engine prefixes
   - Deviate from a similar game engine only when the system prompt explicitly allows it OR when the a similar game engine API has a known design flaw (document the reason in a code comment)

### 3d — External Library Audit

Open `Cargo.toml` and list the dependencies already present. For each task in the phase, answer:

> **"Is a crate in Cargo.toml already capable of doing this?"**

Examples:
- Physics body simulation → `rapier2d` is already vendored; do not write a custom solver
- Image loading → `image = 0.24` already handles PNG/JPEG/BMP; do not add another image crate
- Math types → `crate::math::Vec2` / `Mat3` already exist; do not introduce `glam` just for one phase
- Audio decoding → `rodio = 0.17` already supports WAV/OGG/MP3; do not write a custom decoder
- JSON serialization → `serde_json` is present; use it for save data, not a hand-rolled format

If a capability is **not** covered by existing crates and you need a new one:
- Check the phase file's "New Dependencies" section first
- Choose a mature, well-maintained crate (check crates.io download counts and last-published date)
- Add it following the pinned-semver convention: `crate = "1"` not `crate = "1.0.0"`
- Add a `# Purpose` comment in Cargo.toml explaining why it was added
- Do not add more than one new crate per logical need (no duplicate crates for the same purpose)

**Output**: Table — task → existing crate that covers it (or "needs new crate: X").

---

## Step 4 — Implementation Plan

Produce a numbered plan before writing any code. Each plan item must include:

| # | Task ID | Files Changed | New? | Crate Used | Counterpart | Estimated LoC |
|---|---|---|---|---|---|---|

Rules:
- Order tasks by dependency (a task that creates a type before a task that uses it)
- Flag tasks that modify existing `pub` API (breaking change risk)
- Flag tasks that require changes to `SharedState` (affects all modules)
- Flag tasks that need a new `DrawCommand` variant (requires GPU pipeline change)

If `DRY_RUN=true`, stop here and print the plan. Do not proceed to implementation.

---

## Step 5 — Implement Each Task

Work through the plan in order. For every task:

### 5a — Write the Rust Code

Follow the rules from the `rust-coding` skill:

- `pub` for cross-module types, `pub(crate)` for internal
- No `unsafe` without a `// SAFETY:` comment
- `EngineError` variant (thiserror-derived) for engine-level errors; `LuaResult<T>` for Lua bindings
- Absolute imports: `crate::module::Type`
- Run `cargo fmt` after every file is written
- Do NOT use `println!` in engine code — use `log::debug!`, `log::info!`, etc.

### 5b — Write the Lua Binding

Follow the rules from the `lua-api-design` skill:

Every new Lua-facing function must:

```rust
// Pattern: clone Rc before moving into closure
let state_clone = Rc::clone(&state);
luna.set("functionName", lua.create_function(move |_, args: (T1, T2)| {
    let s = state_clone.borrow();
    // ...
    Ok(result)
})?)?;
```

- Return type is always `LuaResult<T>`
- Error messages must include the function name: `"luna.module.function: <reason>"`
- Key names lowercase: `"space"`, `"return"`, `"left"` — never virtual key codes
- Colors as `(r, g, b, a)` in 0.0–1.0 range — never 0–255

### 5c — Write Doc Comments

**Every** new or modified `pub` item requires a `///` doc comment:

- `pub struct` — one-sentence summary + field descriptions
- `pub fn` — one-sentence summary; mention the Lua binding name if one exists (`/// Called by \`luna.gfx.newCanvas()\``)
- `pub enum` — one-sentence summary + every variant documented
- Modules (`mod.rs`, `lib.rs`) — `//!` module-level doc at top of file

Run after implementing all tasks:
```
python tools/docs/collect_docs.py --report-missing
```

Zero missing docs is required before proceeding to Step 6.

### 5d — Update `DrawCommand` Queue (graphics phases only)


Never render inside a Lua closure — push to the queue, process after `luna.draw()` returns.

---

## Step 6 — Write Tests

Tests are **not optional**. Every public Rust API function and every new `luna.*` Lua function requires at least one test.

### 6a — Rust Integration Tests

File: `tests/<module>_tests.rs`

Rules from `testing-rust` skill:
- Test names: `test_<function>_<scenario>` (snake_case)
- Float comparisons: `assert!((a - b).abs() < 1e-5)` — NEVER `assert_eq!` on `f32`
- Tests must NOT open windows, play audio, or write outside `target/`
- For `SharedState`-dependent tests, construct a minimal `SharedState::new()` directly
- Test edge cases: empty input, zero values, boundary values, invalid handles

Minimum coverage:
- Happy path (normal usage)
- Error path (invalid argument, missing resource)
- Round-trip where applicable (set → get → assert)

### 6b — Lua API Tests

File: Any `.lua` file under `tests/lua/` or a new `tests/lua/<module>_tests.lua`

Rules:
- Must be headless-safe: no window, no GPU, no audio device
- Use `luna.<module>.*` calls only — never external engine prefixes
- Assert return values explicitly: `assert(result == expected, "message")`
- Cover: creation, mutation, query, destruction
- If a function call is expected to error, wrap in `pcall` and assert the error

Example structure:
```lua
-- tests/lua/<module>_tests.lua
local passed = 0
local failed = 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        print("FAIL: " .. name .. " — " .. tostring(err))
    end
end

-- Tests
test("newThing creates valid handle", function()
    local h = luna.<module>.newThing()
    assert(type(h) == "number" and h > 0, "expected positive integer handle")
end)

-- Report
print(string.format("Results: %d passed, %d failed", passed, failed))
assert(failed == 0, "some Lua tests failed")
```

---

## Step 7 — Quality Gates

Run all gates in order. Each must pass before proceeding. Do not skip even one.

```powershell
# Gate 1: Compilation
cargo build

# Gate 2: All tests pass
cargo test

# Gate 3: Clippy with zero warnings treated as errors
cargo clippy -- -D warnings

# Gate 4: Format check
cargo fmt --check

# Gate 5: Doc coverage — zero missing public items
python tools/docs/collect_docs.py --report-missing

# Gate 6: API reference regeneration
python tools/docs/collect_docs.py
```

If any gate fails:

- Fix the failure before continuing
- For Clippy warnings: fix the lint; do not use `#[allow(...)]` unless the lint is a false positive and you add a comment explaining why
- For formatting failures: run `cargo fmt` (not `--check`) and re-stage the changed files

---

## Step 8 — Update Architecture Documentation

Open `docs/architecture/engine-architecture.md`. If the phase:

- **Added a new module**: add it to the module list with one-sentence description and its dependency direction
- **Changed SharedState fields**: update the SharedState section
- **Added a `DrawCommand` variant**: update the draw pipeline section
- **Added a new crate dependency**: update the "Dependencies" table
- **Changed any public `luna.*` function signature**: note the change in the API surface section

Only update sections that actually changed. Do not touch sections unrelated to the phase.

---

## Step 9 — Update the Phase File

Open `PHASE_FILE`. Insert or update a `## Status` section immediately after the leading metadata block (the `> **Priority**` block), before `## Goal`:

```markdown
## Status

**As of**: YYYY-MM-DD
- Task N.1 — ✅ Complete: <what was done, one line>
- Task N.2 — ✅ Complete: <what was done>
- Task N.3 — 🔄 In Progress: <what remains or what blocked it>
- Task N.4 — ⬜ Not Started
```

Status symbols:

| Symbol | Meaning |
|---|---|
| ✅ | Complete — all acceptance gates pass |
| 🔄 | In Progress — work done but gates not fully passing |
| ⬜ | Not Started |
| ❌ | Cancelled — explain why in a note |

If ALL tasks are ✅ Complete, append a `## Retrospective` section at the bottom:

```markdown
## Retrospective

**Completed**: YYYY-MM-DD
**Actual scope**: N files modified, N files added
**Deviations from plan**: <list any tasks that were changed in scope or skipped, with reason>
**New discoveries**: <any findings that should feed into a future phase>
```

---

## Step 10 — Commit

Stage only the files directly changed by this phase. Do not `git add .`.

```powershell
# Confirm branch
git rev-parse --abbrev-ref HEAD

# Stage only phase-related files
git add src/... tests/... docs/...

# Commit
git commit -m "feat(<module>): implement phase N — <phase title>"
```

Commit message rules:
- Type: `feat` for new functionality, `fix` for corrections, `docs` for doc-only
- Scope: the primary module changed (`graphics`, `physics`, `audio`, `input`, `lua_api`, `engine`)
- Description: imperative mood, ≤72 chars, mentions the phase

---

## Acceptance Gates

The phase is not done until every item below is checked:

- [ ] `cargo build` succeeds with zero errors
- [ ] `cargo test` passes — all existing tests still pass; new tests for all new functions present
- [ ] `cargo clippy -- -D warnings` produces zero warnings
- [ ] `cargo fmt --check` produces zero diffs
- [ ] `python tools/docs/collect_docs.py --report-missing` exits 0 (zero missing public docs)
- [ ] `python tools/docs/collect_docs.py` completes and `docs/API/lua_api_reference_generated.md` is updated
- [ ] Every new `luna.*` function appears in `docs/API/lua_api_reference_generated.md`
- [ ] Every new `luna.*` function has a corresponding Lua test in `tests/lua/`
- [ ] Every new Rust public function has a corresponding Rust test in `tests/<module>_tests.rs`
- [ ] API parity check passed: new functions use same parameter order and semantics as a similar game engine equivalents
- [ ] No external library capability is hand-rolled (the crate audit table from Step 3d is satisfied)
- [ ] `docs/architecture/engine-architecture.md` reflects any structural changes
- [ ] Phase file `## Status` section is up to date with ✅ for all completed tasks
- [ ] Commit staged with only relevant files

---

## Agent Routing Reference

| What the task touches | Route to |
|---|---|
| `src/graphics/` | **Renderer** |
| `src/physics/` | **Physicist** |
| `src/audio/` | **Audio-Eng** |
| `src/lua_api/` | **Developer** (binding wiring) + domain specialist |
| `tests/` | **Tester** |
| `docs/` | **Doc-Writer** |
| Module boundary or new crate decision | **Architect** |
| Lua API signature design choices | **Lua-Designer** |
| `Cargo.toml` dependency additions | **Developer** + **Architect** sign-off |

---

## References

- `docs/architecture/engine-architecture.md` — module map, dependency direction, SharedState layout
- `.github/skills/roadmap-planning/SKILL.md` — phase format and acceptance gate rules
- `.github/skills/lua-api-design/SKILL.md` — API naming, `luna.*` conventions, API alignment rules
- `.github/skills/rust-coding/SKILL.md` — Rust code style and safety rules
- `.github/skills/testing-rust/SKILL.md` — test writing patterns
- `references/similar-engine-ref/` — a similar game engine source for direct API comparison
- `tools/docs/collect_docs.py` — run to check and generate API docs
- `tools/validate/cag_validate.py` — run to validate CAG layer after any `.github/` edits
