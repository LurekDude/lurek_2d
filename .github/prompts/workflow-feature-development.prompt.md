---
description: "Full feature development workflow from design to merged code. Use when starting, extending, or refactoring a Lurek2D feature. Orchestrates design, implementation, lua_api registration, docstrings, tests, spec sync, tool validation, examples, changelog, and commit."
---

# Workflow: Feature Development

**Purpose**: Orchestrate the full lifecycle of a Lurek2D feature from architecture review through implementation, testing, documentation, tool validation, and a clean commit.
**Use When**: Adding a new feature, extending an existing module's API, or refactoring behaviour in one or more `src/` modules.
**Do Not Use When**: A single-line bug fix with no API surface change — use a direct edit instead.
**Scope**: Full repository.

## Inputs

- `FEATURE_DESC` — one paragraph describing the feature and its game-developer-facing value
- `AFFECTED_MODULES` — list of `src/` modules that will change (e.g., `physics/`, `lua_api/`)
- `PRIORITY` — `p1` (blocks other work), `p2` (normal), `p3` (nice-to-have)

## Steps

### Phase 0: Pre-flight — Architecture & Skills Review

1. Read `docs/architecture/philosophy.md`, `docs/architecture/engine-architecture.md`, and `docs/architecture/test-framework.md` in full before any implementation.
2. Load all skills relevant to the affected domain (e.g., `lua-api-design`, `lua-rust-bridge`, `testing-rust`, `rust-coding`, `module-architecture`).
3. Read `docs/specs/<module>.md` for every affected module — this is the single source of truth for current behaviour and API.
4. Confirm the feature fits within the binding constraints (A-01 … B-05). If it conflicts, stop and raise the conflict before proceeding.

### Phase 1: Design (Lua-Designer + Architect)

5. Load skill `lua-api-design/SKILL.md`.
6. Route to **Lua-Designer**: design the `lurek.*` API surface.
   - Provide: feature description, affected namespace, reference engine equivalent if any.
   - Get back: finalized function signatures, Lua usage example, parameter defaults.
7. Route to **Architect** if the feature needs a new module or changes module boundaries.
   - Provide: current dependency graph, proposed new module or boundary change.
   - Get back: approved module structure and dependency direction — DAG invariant confirmed.

### Phase 2: Implementation (Developer / Renderer / Physicist / Audio-Eng)

8. Identify the owning specialist:
   - `src/render/` → **Renderer**
   - `src/physics/` → **Physicist**
   - `src/audio/` → **Audio-Eng**
   - All other modules → **Developer**
9. Implement the feature in `src/<module>/`:
   - Domain logic lives **only** in `src/<module>/` — pure Rust, no mlua imports, no `impl LuaUserData`.
   - Per-frame code must not allocate on the heap.
   - Use `log::info!` / `log::debug!` / `log::warn!` / `log::error!` — never `println!`.
10. **Keep `mod.rs` minimal** — only `pub mod <submodule>;` declarations and re-exports. No logic, no trait implementations, no constants unless they are genuinely module-wide.
11. Update **`src/lua_api/<module>_api.rs`** to register every new public method:
    - The `pub fn register()` signature must be: `pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`.
    - The `lua_api` file is a **thin wrapper only**: one `add_method` call per public function, input validation at the boundary, `.map_err(LuaError::external)` on all Rust errors.
    - Clone `Rc` before moving into closures: `let state = state.clone();` then `move |...| { let s = state.borrow(); ... }`.
    - No business logic in `lua_api` — delegate immediately to the domain module.
12. **Update `src/<module>/IDEA.md`** to reflect the new capability:
    - Add or update the relevant section describing what was implemented, why, and any known trade-offs.
    - Keep it concise — this file is for future contributors, not end-user docs.

### Phase 3: Module Boundary & Overlap Check

13. Verify the feature lives **only** in the intended module — no parallel implementation in another module or `lua_api/` file.
14. Run `python tools/audit/audit_module.py <module>` and inspect for unexpected cross-module dependencies.
15. Gate: no duplicate API surface; no cycles introduced in the dependency graph.

### Phase 4: Testing — Lua-First (Tester)

16. Load skill `testing-rust/SKILL.md`.
17. Write tests in Lua BDD format (`tests/lua/<category>/test_<module>_<name>.lua`) for **every** new `lurek.*` function:
    - Register the new test in `tests/lua/harness.rs` with `#[test] fn lua_test_<category>_<name>()`.
    - Each test file must end with `test_summary()`.
    - Lua tests must not call GPU, audio, or window APIs.
18. Write Rust unit tests (`tests/rust/unit/<module>_<scenario>_<expected>.rs`) **only** for private internals not reachable from Lua: internal `struct` field defaults, non-public helpers, invariants that cannot survive the Lua call boundary.
19. Gate: `cargo test --test lua_tests` passes with new tests present; `cargo test --test <module>_tests` passes if Rust tests were added.

### Phase 5: DocString Audit — Rust & Lua (Doc-Writer)

20. Every `.rs` file added or modified must have a **file-level `//!` comment** covering: purpose, subsystem membership, architecture note, typical usage sequence.
21. For every `pub struct`, `pub enum`, and `pub fn` added or modified:
    - Write a full `///` description — behaviour, design rationale, edge cases, call sequence.
    - Include `# Parameters`, `# Fields` / `# Variants`, and `# Returns` sections where applicable (machine-readable — never omit them).
22. Lua API files (`src/lua_api/<module>_api.rs`) must use inline `@param name : type` and `@return type` annotations (gold standard: `src/lua_api/timer_api.rs`) — **not** `# Parameters` / `# Returns` rustdoc sections.
23. Gate: `python tools/docs/collect_docs.py --report-missing` exits 0 — no public items lack a doc comment.

### Phase 6: Module Spec Update

24. Update (or create) `docs/specs/<module>.md` using the canonical section order:
    - `## General Info` — group, source path, Lua API path(s), test paths.
    - `## Summary` — accurate multi-paragraph description of the implemented behaviour.
    - `## Files`, `## Types`, `## Functions` — match the implementation exactly.
    - `## Lua API Reference` — list every `lurek.*` function with signatures and brief descriptions.
    - `## References` and `## Notes` — actual dependency edges and important caveats.
25. For each design / spec `.md` that drove implementation and now lives in `src/<module>/`:
    - Copy its content to `docs/API/<module>-design.md` (preserving tables, examples, rationale).
    - Delete the original from `src/<module>/`. Gate: no spec-only `.md` files remain inside `src/`.
26. Gate: `docs/specs/<module>.md` accurately describes the implemented module.

### Phase 7: Spec & Coverage Tool Validation

27. Run the following tools and resolve all errors before continuing:
    ```powershell
    python tools/audit/validate_agent_md.py --module <module>   # spec structure
    python tools/docs/collect_docs.py --report-missing           # docstring gaps
    python tools/audit/test_coverage.py --suggest                # test gaps
    python tools/docs/gen_docs_lua.py                            # regenerate Lua API ref
    python tools/gen_all_docs.py                                 # full doc pipeline
    ```
28. Gate: `validate_agent_md.py` exits 0; `collect_docs.py` exits 0; no HIGH/ERROR test coverage gaps.

### Phase 8: Content Examples

29. Check whether the new `lurek.*` API warrants a new or updated example in `content/examples/`:
    - If no example file exists for the affected namespace, create `content/examples/<module>.lua`.
    - The example must be a focused single-file script demonstrating the new API in the simplest possible way — no game loop required unless the feature requires it.
    - If a demo in `content/demos/` uses the affected API, update it if the function signatures changed.
30. Gate: `content/examples/<module>.lua` exists and demonstrates the new surface.

### Phase 9: Review (Reviewer)

31. Route to **Reviewer** with:
    - Full list of changed files.
    - Test results (`cargo test` output).
    - Documentation and spec updates.
32. Gate: Reviewer signs off — no CRITICAL/HIGH issues remain.

### Phase 10: Changelog & Version Bump

33. Update `docs/CHANGELOG.md`:
    - Add an entry under the current version using the `Added / Changed / Fixed / Removed` format.
    - One line per logical change.
34. Determine the version increment:
    - **MINOR** bump if new `lurek.*` functions were added (backwards-compatible new API).
    - **PATCH** bump if only internal refactors, doc, or tooling changed.
    - **MAJOR** bump only if existing Lua scripts or `conf.toml` must be ported.
35. Update `Cargo.toml` `[package] version` for MINOR or MAJOR bumps; also update `tools/dist/installer.nsi` (`!define APP_VERSION`) and `tools/dist/dist.ps1` (`$Version`).

### Phase 11: Commit

36. Confirm current branch: `git rev-parse --abbrev-ref HEAD`.
37. Review exactly which files changed: `git status` and `git diff --stat`.
38. Stage **only** files directly modified by this feature — **never `git add .`**.
39. Commit with: `type(scope): description` (types: `feat` `fix` `refactor` `test` `docs` `chore`).
40. Gate: `cargo test && cargo clippy -- -D warnings` passes before pushing.

## Outputs

- Working Rust implementation in `src/<module>/` — domain logic only, no mlua
- Thin `src/lua_api/<module>_api.rs` wrapper registering all new public methods
- Updated `src/<module>/IDEA.md`
- Minimal `src/<module>/mod.rs` — declarations only
- File-level `//!` on every `.rs` file touched
- Lua BDD tests in `tests/lua/` registered in `tests/lua/harness.rs`
- Rust unit tests in `tests/rust/unit/` only for private internals
- Expanded docstrings on all public items; `python tools/docs/collect_docs.py --report-missing` exits 0
- Updated `docs/specs/<module>.md`; spec MDs removed from `src/`
- Regenerated `docs/API/lua-api.md` via `python tools/gen_all_docs.py`
- `content/examples/<module>.lua` demonstrating the new API
- `docs/CHANGELOG.md` entry; `Cargo.toml` version bumped if MINOR/MAJOR
- Clean commit of only the modified files with a conventional commit message

## Acceptance

- [ ] Feature lives only in the target module — no overlapping implementation elsewhere
- [ ] `src/<module>/mod.rs` contains only `pub mod` declarations and re-exports
- [ ] `src/lua_api/<module>_api.rs` registers all new public methods as thin wrappers
- [ ] `src/<module>/IDEA.md` updated with new capability description
- [ ] Every `.rs` file has a file-level `//!` description
- [ ] `cargo check` — 0 errors during development
- [ ] `cargo test --test lua_tests` — Lua tests pass with new tests registered in harness
- [ ] `cargo test --test <module>_tests` — Rust unit tests pass (only where Lua cannot reach)
- [ ] `python tools/docs/collect_docs.py --report-missing` exits 0
- [ ] `python tools/audit/validate_agent_md.py --module <module>` exits 0
- [ ] `docs/specs/<module>.md` General Info, Files, Types, Functions, and Lua API Reference are accurate
- [ ] `content/examples/<module>.lua` exists and demonstrates the new API surface
- [ ] `docs/CHANGELOG.md` has an entry; `Cargo.toml` version bumped if MINOR/MAJOR
- [ ] `git add` staged only modified files; conventional commit message applied
- [ ] `cargo test && cargo clippy -- -D warnings` passes at final gate
- [ ] Reviewer signoff — no CRITICAL/HIGH issues

## References

**Required Skills**: `lua-api-design`, `rust-coding`, `module-architecture`
**Suggested Agents**: `Manager`, `Lua-Designer`, `Developer`, `Tester`, `Reviewer`
**Related Prompts**: `design-api-surface.prompt.md`, `create-api-function.prompt.md`, `run-quality-gates.prompt.md`
