---
description: "End-to-end quality audit of one or more Lurek2D src/ modules. Validates spec, AGENT.md, Lua bridge separation, docstrings, example completeness, lib.rs/build.rs registration, tests, wiki, architecture, performance, and more. Each check produces PASS/WARNING/ERROR. After the audit report is complete, ALL findings are fixed automatically without requiring a separate request."
argument-hint: "Module name(s): physics, audio, all, foundations, core-runtime, platform-services, feature-systems, ..."
---

# Lurek2D Module Audit

Perform a comprehensive end-to-end quality audit on Lurek2D engine module(s).

## Skills

Load and follow these skills BEFORE any work:
```
.github/skills/module-audit/SKILL.md
.github/skills/lua-rust-bridge/SKILL.md
.github/skills/examples-management/SKILL.md
```

## Reference Documents

Load before checking any module:
1. `docs/architecture/engine-architecture.md` — group assignments, dependency rules
2. `docs/architecture/philosophy.md` — binding constraints (A-01 … B-05)
3. `src/lib.rs` — module registrations
4. `src/lua_api/mod.rs` — Lua API registrations and `create_lua_vm()`
5. `docs/specs/README.md` — spec sync contract

## Target Modules

The user will specify one of:
- **A single module**: `physics`, `audio`, `math`, etc.
- **Multiple modules**: `physics, audio, input`
- **A group**: `foundations`, `core-runtime`, `platform-services`, `feature-systems`, `edge`
- **All modules**: `all`

Resolve the target list using `src/lib.rs` registrations and `docs/architecture/engine-architecture.md` group assignments.

## Audit Checklist

Run every check below against each target module. Each check MUST produce exactly one verdict:

| Verdict | Meaning |
|---------|---------|
| **PASS** | Fully compliant, no action needed |
| **WARNING** | Minor issue or improvement opportunity — not blocking |
| **ERROR** | Structural deficiency, missing requirement, or rule violation — must fix |

### Scoring

A module **FAILS** the audit if it has:
- **1 or more ERRORs**, OR
- **3 or more WARNINGs**

---

### Phase 1 — Structure & Registration

| # | Check | What to verify |
|---|-------|----------------|
| S-01 | **lib.rs registration** | Module has `pub mod <name>;` in `src/lib.rs`. If it exposes Lua API, there is a corresponding `<name>_api.rs` or `<name>_api/` in `src/lua_api/` and it is registered in `create_lua_vm()` in `src/lua_api/mod.rs`. Missing either = ERROR. |
| S-02 | **build.rs watch** | If the module depends on any asset files, embedded resources, or generated code, those paths are declared in `build.rs` with `println!("cargo:rerun-if-changed=<path>")`. Missing watch rules for assets used at compile time = WARNING. |
| S-03 | **mod.rs simplicity** | `src/<module>/mod.rs` is a thin barrel file: re-exports (`pub mod`, `pub use`) and module-level `//!` doc comment only. No business logic (>30 lines of non-doc, non-reexport code = WARNING; >100 = ERROR). |
| S-04 | **File size limits** | No `.rs` file exceeds 2000 LOC unless there is a documented justification in AGENT.md. Files >1500 LOC = WARNING. Files >2000 LOC without justification = ERROR. |
| S-05 | **File naming** | File names use standard game-engine terminology (e.g., `body.rs`, `world.rs`, `mixer.rs`) not obscure or misleading names. Names should be recognisable to developers from other engines. |
| S-06 | **Module necessity** | Confirm the module genuinely needs Rust. If the entire module (or a significant part) could be implemented as a pure-Lua library in `content/library/`, flag WARNING with a recommendation. |
| S-07 | **Large crate dependencies** | Check if the module pulls in heavy external crates. If a lighter alternative exists or the dependency could be feature-gated, flag WARNING. |

### Phase 2 — AGENT.md Quality

**AGENT.md is a SHORT file** — its only job is to orient an AI agent entering the module. It contains a metadata table, a one-paragraph Purpose, a Source Files table, and a pointer to `docs/specs/<module>.md`. Do NOT check AGENT.md for Architecture diagrams, Key Types, Lua API tables, or Lua Examples — those belong in `docs/specs/<module>.md` (Phase 3).

Canonical short format (from `.github/skills/agent-md/SKILL.md`):
`# \`<module>\` — Agent Reference` → metadata table → `## Purpose` → `## Source Files` → `## Full Specification`

| # | Check | What to verify |
|---|-------|----------------|
| A-01 | **AGENT.md exists** | `src/<module>/AGENT.md` file is present. Missing = ERROR. |
| A-02 | **Template structure** | AGENT.md follows the short format: H1 heading → metadata table → `## Purpose` → `## Source Files` → `## Full Specification`. Missing any of these five elements = ERROR. |
| A-03 | **Purpose quality** | `## Purpose` is 2–5 sentences that let an agent decide in seconds whether to open this module or a different one. Missing or single-word stub = ERROR. Overly vague = WARNING. |
| A-04 | **Source Files sync** | Every `.rs` file in `src/<module>/` is listed in the `## Source Files` table with a one-line description. Missing or stale file entries = ERROR. |
| A-05 | **Spec pointer** | `## Full Specification` section exists and contains a link to `docs/specs/<module>.md`. Missing or broken pointer = ERROR. |
| A-06 | **No over-stuffing** | AGENT.md does NOT contain full Architecture diagrams, Key Types tables, full Lua API tables, or Lua Examples sections — those belong in `docs/specs/<module>.md`. If present in AGENT.md = WARNING (content is in the wrong file). |
| A-07 | **Group label** | The metadata table includes a `**Group**` row with the correct group assignment matching `docs/architecture/engine-architecture.md`. Wrong or missing = ERROR. |

### Phase 3 — Technical Specification (`docs/specs/<module>.md`)

`docs/specs/<module>.md` is the **canonical full technical reference**. AGENT.md is intentionally a short overview — all architecture detail, type documentation, Lua API tables, examples, and cross-module references live here.

Required spec sections (from `.github/skills/agent-md/SKILL.md`): `## Summary` · `## Architecture` · `## Source Files` · `## Submodules` · `## Key Types` (Structs + Enums) · `## Lua API` · `## Lua Examples`.

| # | Check | What to verify |
|---|-------|----------------|
| SP-01 | **Spec file exists** | `docs/specs/<module>.md` is present. Missing = ERROR. |
| SP-02 | **Required sections** | Spec contains: `## Summary`, `## Architecture` (ASCII diagram or equivalent), `## Source Files`, `## Submodules`, `## Key Types`, `## Lua API` (if module has Lua API), `## Lua Examples`. Any required section absent = ERROR. |
| SP-03 | **Summary quality** | `## Summary` is 500–1000 characters covering: what the module does, how it works, key design decisions, and scope boundaries. Too short (<300 chars) = ERROR. |
| SP-04 | **Lua API completeness** | Every `tbl.set("funcName", ...)` entry in `src/lua_api/<module>_api.rs` appears in the spec's `## Lua API` section with correct parameter signature and return type. Grep `tbl.set(` to enumerate live bindings, then diff against spec. Missing entries = ERROR. Stale entries (in spec but not in code) = ERROR. |
| SP-05 | **Type accuracy** | Every public struct and enum listed in `## Key Types` matches the live Rust source. Use `grep -n "^pub struct\|^pub enum"` in `src/<module>/` to enumerate; diff against spec. Missing or renamed types = ERROR. |
| SP-06 | **Architecture sync** | Spec group assignment and dependency list match `docs/architecture/engine-architecture.md`. Contradictions = ERROR. |
| SP-07 | **Cross-module refs** | All cross-module references in the spec resolve to real modules present in `src/lib.rs`. Stale references = WARNING. |
| SP-08 | **Spec quality** | Spec is not a stub (`TODO`, placeholder paragraphs). Stub spec = WARNING. |

### Phase 4 — Docstrings

#### Domain module (`src/<module>/`)

| # | Check | What to verify |
|---|-------|----------------|
| D-01 | **Module-level docs** | Every `.rs` file in `src/<module>/` has a `//!` module-level doc comment. Missing = ERROR. |
| D-02 | **Public item docs** | Every `pub struct`, `pub enum`, `pub fn`, `pub trait`, `pub type`, `pub const` has a `///` doc comment. Run `python tools/docs/collect_docs.py --report-missing` scoped to the module. Any findings = ERROR. |
| D-03 | **Structured sections** | Docstrings for structs include `# Fields`, enums include `# Variants`, functions include `# Parameters` and `# Returns` where applicable. Missing structured sections = WARNING. |
| D-04 | **Doc quality** | Doc comments are not stub/placeholder text (e.g., "TODO", "undocumented"). Stubs = WARNING. |
| D-05 | **Validation tool** | `python tools/docs/collect_docs.py --report-missing` reports zero findings for `src/<module>/`. Any findings = ERROR. |

#### Lua API file (`src/lua_api/<module>_api.rs`)

| # | Check | What to verify |
|---|-------|----------------|
| D-06 | **Lua API file docs** | `src/lua_api/<module>_api.rs` exists and has a `//!` module-level doc comment. Missing = ERROR. |
| D-07 | **`@param`/`@return` annotations** | Every function exposed via `tbl.set("funcName", ...)` has `/// @param name : type` for each argument and `/// @return type` immediately before the `tbl.set(...)` call. Check gold standard `src/lua_api/timer_api.rs`. Missing annotations = WARNING. |
| D-08 | **No rustdoc sections in Lua API** | `src/lua_api/<module>_api.rs` must NOT use `# Parameters`, `# Returns`, `# Fields`, or `# Variants` rustdoc sections. These are machine-read only in domain files. Violations = ERROR. |
| D-09 | **Section separators** | Each exposed function group is prefixed with `// ── funcName ──────────────────────` comment separator. Missing separators in files with ≥3 functions = WARNING. |

### Phase 5 — Lua↔Rust Bridge Integrity

The Lua API file (`src/lua_api/<module>_api.rs`) is a **registration-only wrapper**. All business logic lives exclusively in `src/<module>/`.

| # | Check | What to verify |
|---|-------|----------------|
| B-01 | **Dedicated API file** | Lua bindings for this module live in a dedicated `src/lua_api/<module>_api.rs` file. Bindings embedded in another module's api file = ERROR. |
| B-02 | **Registration-only** | The api file contains only `pub fn register(lua, luna, state)`, closure bodies that immediately delegate to domain methods, and parameter extraction. Any freestanding function beyond `register()`, any struct definition, or any algorithm exceeding 10 LOC per closure = ERROR. |
| B-03 | **`impl LuaUserData` placement** | Every `impl LuaUserData` block for a domain type lives in `src/<module>/`, NOT in `src/lua_api/`. Violations = ERROR. |
| B-04 | **No business logic in closures** | Closure bodies contain at most: parameter extraction, a single call to a domain method, and result wrapping. Control flow, state mutation, or multi-step logic inside a closure body = WARNING. Use `python tools/validate/validate_lua_api.py` to assist. |
| B-05 | **Rc clone pattern** | Every closure that captures `state` first does `let s = state.clone();` before the `move` closure, not inside it. Violations (state cloned inside closure, or state not cloned before a move) = ERROR. |
| B-06 | **Flat registration body** | `tbl.set(...)` calls are NOT wrapped in `{ }` block expressions. Each binding is a direct flat statement sequence `let s = state.clone(); tbl.set(...)?;`. Block-wrapped bindings = ERROR. |

### Phase 6 — Architecture Compliance

| # | Check | What to verify |
|---|-------|----------------|
| R-01 | **Group placement** | Module is in the correct group per `docs/architecture/engine-architecture.md`. Modules in wrong group = ERROR. |
| R-02 | **Dependency direction** | Module imports only from allowed lower groups per the five-group model in `docs/architecture/engine-architecture.md`. Upward imports and forbidden cross-group imports = ERROR. |
| R-03 | **No lua_api import** | Domain modules never import `lua_api`. Violations = ERROR. |
| R-04 | **Design assumptions** | Module does not violate any constraint from `docs/architecture/philosophy.md` (e.g., no 3D, no mobile, no unsafe without SAFETY comment). Violations = ERROR. |
| R-05 | **Module overlap** | Module does not duplicate purpose/scope with another module (e.g., audio vs sound). If overlap exists, flag WARNING with merge/split recommendation. |

### Phase 7 — Test Coverage

| # | Check | What to verify |
|---|-------|----------------|
| T-01 | **Rust test file exists** | Integration test file exists: `tests/rust/unit/<module>_tests.rs` or `tests/rust/ext/<module>_tests.rs` AND is registered in `Cargo.toml` `[[test]]`. Missing = ERROR. |
| T-02 | **Lua test file exists** | If module has Lua API: `tests/lua/unit/test_<module>.lua` exists AND is registered in `tests/lua/harness.rs`. Missing = ERROR. |
| T-03 | **Test naming** | Tests follow `<subject>_<scenario>_<expected>` convention. No `test_` prefix. Violations = WARNING. |
| T-04 | **Float comparisons** | No `assert_eq!` on `f32`/`f64` values — must use `abs() < epsilon`. Violations = ERROR. |
| T-05 | **Test adequacy** | At least one test per public function/method. Significantly undertested modules = WARNING. |
| T-06 | **Golden tests** | For modules with deterministic visual/audio/text output (graphics, audio, text rendering), golden tests exist in `tests/rust/golden/`. Missing for qualifying modules = WARNING. |
| T-07 | **Tests pass** | Run `cargo test --test <module>_tests` and (if exists) `cargo test lua_test_<module>`. Any failure = ERROR. |

### Phase 8 — Documentation, Examples & Wiki

#### Example file completeness (tool-assisted)

| # | Check | What to verify |
|---|-------|----------------|
| W-01 | **Example file exists** | `content/examples/<module>.lua` is present. Missing = ERROR. |
| W-02 | **API surface coverage** | Every function exposed via `tbl.set("funcName", ...)` in `src/lua_api/<module>_api.rs` appears in `content/examples/<module>.lua`. **Tool steps**: (1) `grep -n 'tbl\.set(' src/lua_api/<module>_api.rs` to enumerate all bound names; (2) for each name, `grep -c '"funcName"' content/examples/<module>.lua`; (3) flag any function with zero hits as missing. Missing functions = ERROR. |
| W-03 | **Use-case comments** | Each function call in `content/examples/<module>.lua` has a one-line comment explaining the real use case, not just a parameter recap. Comments like `-- call foo` or `-- example` = WARNING. Each call should read like documentation (`-- start a slow-motion timer that fires after 3 in-game seconds`). Missing or trivial comments = WARNING. |
| W-04 | **Example–spec sync** | The function list in `content/examples/<module>.lua` and in `docs/specs/<module>.md`'s Lua API table refer to the same set of public functions. Any function present in one but absent from the other = WARNING. |

#### Wiki & supplementary docs

| # | Check | What to verify |
|---|-------|----------------|
| W-05 | **Wiki page** | `docs/wiki/<Module>-API.md` exists with examples, function reference, and getting-started guidance. Quality should match Engine A wiki standard: clear examples, parameter tables, return values. Missing = WARNING; exists but low quality = WARNING. |
| W-06 | **Changelog entry** | Any recent change to this module's public API or behaviour has a corresponding entry in `docs/CHANGELOG.md`. Missing = WARNING. |

### Phase 9 — Code Quality

| # | Check | What to verify |
|---|-------|----------------|
| Q-01 | **No println!** | Module uses `log::info!`/`warn!`/`error!`/`debug!` — never `println!` or `eprintln!`. Violations = ERROR. |
| Q-02 | **Logger levels** | Log messages use appropriate severity levels per the logging table in the system prompt. Misuse = WARNING. |
| Q-03 | **No unsafe** | No `unsafe` blocks without `// SAFETY:` comment. Violations = ERROR. |
| Q-04 | **Error handling** | Functions return `Result<T, EngineError>` or `LuaResult<T>`. No `.unwrap()` in non-test code (`.expect()` with message is acceptable for initialization). Bare `.unwrap()` = WARNING. |
| Q-05 | **Rust best practices** | No obvious anti-patterns: unnecessary clones, redundant allocations in hot paths, unused imports, dead code. Issues = WARNING. |
| Q-06 | **Clippy clean** | `cargo clippy --lib -- -D warnings` produces no warnings for this module's files. Warnings = ERROR. |

### Phase 10 — Performance

| # | Check | What to verify |
|---|-------|----------------|
| P-01 | **Performance doc** | If module is covered in `docs/performance/`, verify the analysis is current and recommendations are implemented or tracked. Stale analysis = WARNING. |
| P-02 | **Hot-path allocations** | Per-frame code paths do not allocate on the heap. Allocations in `update`/`draw`/`step` paths = WARNING. |
| P-03 | **Buffer pre-allocation** | Growable buffers (Vec, HashMap) are pre-allocated at startup rather than grown per-frame. Missing pre-allocation = WARNING. |

### Phase 11 — Integration & Extension

| # | Check | What to verify |
|---|-------|----------------|
| I-01 | **Lua API usability** | Module's Lua API follows `lurek.*` conventions: sensible defaults, optional parameters, lowercase key names. Violations = WARNING. |
| I-02 | **Extension panel** | If module has or could have a VS Code extension panel (world editor, particle editor, etc.), verify it exposes structured data (TOML/JSON) for tool integration. No structured I/O where expected = WARNING. |
| I-03 | **Config integration** | If module has configurable settings, they are exposed via `conf.toml` / `ModulesConfig` and documented. Missing config integration = WARNING. |

### Phase 12 — Localization & Logging

| # | Check | What to verify |
|---|-------|----------------|
| L-01 | **Log message externalization** | All user-facing log strings are consistent and follow engine logging conventions. Hardcoded display strings that should be configurable = WARNING. |
| L-02 | **TOML message catalog** | If a global TOML-based message catalog exists in `engine/cfg/`, verify this module's messages are registered. If no catalog system exists yet, flag as WARNING and note the gap for future implementation. |

---

## Validation Tool Runs (mandatory for every audit)

Run these tools in order and include their output in the report:

```powershell
# 1. Docstring coverage — domain module
python tools/docs/collect_docs.py --report-missing   # scope to module manually

# 2. Lua API validation (checks @param/@return coverage and bridge hygiene)
python tools/validate/validate_lua_api.py

# 3. Test coverage meta-analysis
python tools/audit/test_coverage.py

# 4. Full module audit runner (PASS/WARN/ERROR per check)
python tools/audit/audit_module.py <name>

# 5. Lua API surface enumeration (compare against content/examples/<module>.lua)
grep -n "tbl\.set(" src/lua_api/<module>_api.rs
```

Any tool that is unavailable should be noted as SKIP in the report.

---

## Output Format

For each module audited, produce a report in this exact format:

```
## Module: <name> — <PASS|FAIL>

| # | Check | Verdict | Details |
|---|-------|---------|---------|
| S-01 | lib.rs registration | PASS | Registered as `pub mod <name>`; api registered in create_lua_vm() |
| S-02 | build.rs watch | PASS | No asset dependencies |
| SP-01 | Spec file exists | ERROR | docs/specs/<name>.md is missing — must create |
| B-02 | Registration-only | WARNING | lua_api file contains 35-line closure with embedded sort logic |
| W-02 | API surface coverage | ERROR | lurek.<name>.newFoo, lurek.<name>.destroyFoo missing from content/examples/<name>.lua |
| ... | ... | ... | ... |

### Score: X PASS / Y WARNING / Z ERROR → **PASS** or **FAIL**

### Required Actions (ERRORs)
1. Create `docs/specs/<name>.md` with all required sections (SP-01)
2. Move sort logic from lua_api closure to `src/<name>/` domain method (B-02)
3. Add lurek.<name>.newFoo and lurek.<name>.destroyFoo to content/examples/<name>.lua with use-case comments (W-02)

### Recommended Improvements (WARNINGs)
1. ...
```

---

## Fix Workflow — AUTOMATIC (runs after every audit)

**After the audit report is complete, immediately begin fixing all findings without waiting for a separate user request.** The fix workflow is mandatory whenever any module produces WARNING or ERROR verdicts.

Fix order:

1. **Fix all ERRORs first**, phase by phase (Phase 1 → Phase 12)
2. For missing `docs/specs/<module>.md`: create from the canonical template — do not copy AGENT.md verbatim; the spec must add full type tables, Lua API tables with signatures, and architecture detail not in AGENT.md
3. For missing example coverage (W-02): grep `tbl.set(` to get the authoritative function list, then add each missing function to `content/examples/<module>.lua` with a realistic multi-line use-case comment written in the voice of a game developer
4. For bridge violations (B-02 … B-06): extract logic to domain module first, then thin the closure to a single delegation call
5. For docstring gaps: run `python tools/docs/collect_docs.py --report-missing` after each fix to confirm zero findings before moving on
6. **Address WARNINGs by priority** after all ERRORs are resolved
7. Re-run `python tools/audit/audit_module.py <name>` to confirm resolution
8. Do NOT run full `cargo build` or `cargo test` during fixes — use `cargo check` and scoped `cargo test --test <module>_tests`
9. Update `docs/CHANGELOG.md` before committing any fix

**After all fixes are applied**, confirm with `cargo check` and report a final summary showing:
- Which findings were fixed (check ID → what was changed)
- Which findings were skipped and why (e.g., false positive, out-of-scope)
- Final PASS/FAIL status per module
