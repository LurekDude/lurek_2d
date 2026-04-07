---
description: "End-to-end quality audit of one or more Luna2D src/ modules. Validates docstrings, AGENT.md, structure, tests, docs, wiki, architecture, performance, and more. Each check produces PASS/WARNING/ERROR."
argument-hint: "Module name(s): physics, audio, all, tier1, ..."
---

# Luna2D Module Audit

Perform a comprehensive end-to-end quality audit on Luna2D engine module(s).

## Skill

Load and follow the module-audit skill BEFORE any work:
```
.github/skills/module-audit/SKILL.md
```

## Target Modules

The user will specify one of:
- **A single module**: `physics`, `audio`, `math`, etc.
- **Multiple modules**: `physics, audio, input`
- **A tier**: `tier1`, `tier2`, `tier3`, `baseline`
- **All modules**: `all`

Resolve the target list using `src/lib.rs` registrations and `docs/architecture/engine-architecture.md` tier assignments.

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
| S-01 | **lib.rs registration** | Module has `pub mod <name>;` in `src/lib.rs`. If it exposes Lua API, there is a corresponding `<name>_api.rs` or `<name>_api/` in `src/lua_api/` and it is registered in `create_lua_vm()`. |
| S-02 | **mod.rs simplicity** | `src/<module>/mod.rs` is a thin barrel file: re-exports (`pub mod`, `pub use`) and module-level `//!` doc comment only. No business logic (>30 lines of non-doc, non-reexport code = WARNING; >100 = ERROR). |
| S-03 | **File size limits** | No `.rs` file exceeds 2000 LOC unless there is a documented justification in AGENT.md. Files >1500 LOC = WARNING. Files >2000 LOC without justification = ERROR. |
| S-04 | **File naming** | File names use standard game-engine terminology (e.g., `body.rs`, `world.rs`, `mixer.rs`) not obscure or misleading names. Names should be recognisable to developers from other engines. |
| S-05 | **Module necessity** | Confirm the module genuinely needs Rust. If the entire module (or a significant part) could be implemented as a pure-Lua library in `library/`, flag WARNING with a recommendation. |
| S-06 | **Large crate dependencies** | Check if the module pulls in heavy external crates. If a lighter alternative exists or the dependency could be feature-gated, flag WARNING. |

### Phase 2 — AGENT.md Quality

| # | Check | What to verify |
|---|-------|----------------|
| A-01 | **AGENT.md exists** | `src/<module>/AGENT.md` file is present. Missing = ERROR. |
| A-02 | **Template structure** | AGENT.md follows the canonical template: property table → Summary → Architecture → Source Files → Submodules → Key Types → Lua API → Item Summary. Missing required sections = ERROR. |
| A-03 | **Summary quality** | Summary section is 500–1000 characters and gives an AI agent complete understanding of the module's purpose, scope, and design decisions. Too short (<300 chars) = ERROR. Too long (>1500 chars) = WARNING. |
| A-04 | **Content sync** | Every `.rs` file in the module folder is listed in the Source Files table. Every public struct/enum is listed in Key Types. Stale or missing entries = ERROR. |
| A-05 | **Lua examples** | AGENT.md includes a Lua code examples section at the bottom showing how to use the module from game scripts. Missing = WARNING (ERROR if Lua API exists). |
| A-06 | **Tier label** | The property table includes the correct Tier assignment matching `docs/architecture/engine-architecture.md`. Wrong or missing = ERROR. |

### Phase 3 — Docstrings

| # | Check | What to verify |
|---|-------|----------------|
| D-01 | **Module-level docs** | Every `.rs` file has a `//!` module-level doc comment. Missing = ERROR. |
| D-02 | **Public item docs** | Every `pub struct`, `pub enum`, `pub fn`, `pub trait`, `pub type`, `pub const` has a `///` doc comment. Missing = ERROR. Use `python tools/docs/collect_docs.py --report-missing` scoped to the module. |
| D-03 | **Structured sections** | Docstrings for structs include `# Fields`, enums include `# Variants`, functions include `# Parameters` and `# Returns` where applicable. Missing structured sections = WARNING. |
| D-04 | **Doc quality** | Doc comments are not stub/placeholder text (e.g., "TODO", "Consult the module-level documentation"). Stubs = WARNING. |
| D-05 | **Validation tool** | Run `python tools/docs/collect_docs.py --report-missing` and confirm zero findings for this module. Any findings = ERROR. |

### Phase 4 — Architecture Compliance

| # | Check | What to verify |
|---|-------|----------------|
| R-01 | **Tier placement** | Module is in the correct tier per `docs/architecture/engine-architecture.md`. Modules in wrong tier = ERROR. |
| R-02 | **Dependency direction** | Module imports only from allowed tiers. Tier 1 may only import `math`+`engine`. Tier 2 may import Baseline+Tier 1. No same-tier cross-imports. Violations = ERROR. |
| R-03 | **No lua_api import** | Domain modules never import `lua_api`. Violations = ERROR. |
| R-04 | **Design assumptions** | Module does not violate any constraint from `docs/architecture/philosophy.md` (e.g., no 3D, no mobile, no unsafe without SAFETY comment). Violations = ERROR. |
| R-05 | **Module overlap** | Module does not duplicate purpose/scope with another module (e.g., audio vs sound). If overlap exists, flag WARNING with merge/split recommendation. |

### Phase 5 — Test Coverage

| # | Check | What to verify |
|---|-------|----------------|
| T-01 | **Rust test file exists** | Integration test file exists: `tests/unit/<module>_tests.rs` or `tests/ext/<module>_tests.rs` (check `Cargo.toml` `[[test]]` entries). Missing = ERROR. |
| T-02 | **Lua test file exists** | If module has Lua API: `tests/lua/unit/test_<module>.lua` exists AND is registered in `tests/lua/harness.rs`. Missing = ERROR. |
| T-03 | **Test naming** | Tests follow `<subject>_<scenario>_<expected>` convention. No `test_` prefix. Violations = WARNING. |
| T-04 | **Float comparisons** | No `assert_eq!` on `f32`/`f64` values — must use `abs() < epsilon`. Violations = ERROR. |
| T-05 | **Test adequacy** | At least one test per public function/method. Significantly undertested modules = WARNING. |
| T-06 | **Golden tests** | For modules with deterministic visual/audio/text output (graphics, audio, text rendering), golden tests exist in `tests/rust/golden/`. Missing for qualifying modules = WARNING. |
| T-07 | **Tests pass** | Run `cargo test --test <module>_tests` and (if exists) `cargo test lua_test_<module>`. Any failure = ERROR. |

### Phase 6 — Documentation & Wiki

| # | Check | What to verify |
|---|-------|----------------|
| W-02 | **Wiki page** | `wiki/<Module>-API.md` page exists with examples, function reference, and getting-started guidance. Quality should match love2D wiki standard: clear examples, parameter tables, return values. Missing = WARNING; exists but low quality = WARNING. |
| W-03 | **Example game** | At least one example in `examples/` demonstrates this module's features, OR a test game in `tests/` exercises the module end-to-end. Missing = WARNING. |

### Phase 7 — Code Quality

| # | Check | What to verify |
|---|-------|----------------|
| Q-01 | **No println!** | Module uses `log::info!`/`warn!`/`error!`/`debug!` — never `println!` or `eprintln!`. Violations = ERROR. |
| Q-02 | **Logger levels** | Log messages use appropriate severity levels per the logging table in the system prompt. Misuse = WARNING. |
| Q-03 | **No unsafe** | No `unsafe` blocks without `// SAFETY:` comment. Violations = ERROR. |
| Q-04 | **Error handling** | Functions return `Result<T, EngineError>` or `LuaResult<T>`. No `.unwrap()` in non-test code (`.expect()` with message is acceptable for initialization). Bare `.unwrap()` = WARNING. |
| Q-05 | **Rust best practices** | No obvious anti-patterns: unnecessary clones, redundant allocations in hot paths, unused imports, dead code. Issues = WARNING. |
| Q-06 | **Clippy clean** | `cargo clippy --lib -- -D warnings` produces no warnings for this module's files. Warnings = ERROR. |

### Phase 8 — Performance

| # | Check | What to verify |
|---|-------|----------------|
| P-01 | **Performance doc** | If module is covered in `docs/performance/`, verify the analysis is current and recommendations are implemented or tracked. Stale analysis = WARNING. |
| P-02 | **Hot-path allocations** | Per-frame code paths do not allocate on the heap. Allocations in `update`/`draw`/`step` paths = WARNING. |
| P-03 | **Buffer pre-allocation** | Growable buffers (Vec, HashMap) are pre-allocated at startup rather than grown per-frame. Missing pre-allocation = WARNING. |

### Phase 9 — Integration & Extension

| # | Check | What to verify |
|---|-------|----------------|
| I-01 | **Lua API usability** | Module's Lua API follows `luna.*` conventions: sensible defaults, optional parameters, lowercase key names. Violations = WARNING. |
| I-02 | **Extension panel** | If module has or could have a VS Code extension panel (world editor, particle editor, etc.), verify it exposes structured data (TOML/JSON) for tool integration. No structured I/O where expected = WARNING. |
| I-03 | **Config integration** | If module has configurable settings, they are exposed via `conf.lua` / `ModulesConfig` and documented. Missing config integration = WARNING. |

### Phase 10 — Localization & Logging

| # | Check | What to verify |
|---|-------|----------------|
| L-01 | **Log message externalization** | All user-facing log strings are consistent and follow engine logging conventions. Hardcoded display strings that should be configurable = WARNING. |
| L-02 | **TOML message catalog** | If a global TOML-based message catalog exists in `engine/cfg/`, verify this module's messages are registered. If no catalog system exists yet, flag as WARNING and note the gap for future implementation. |

---

## Output Format

For each module audited, produce a report in this exact format:

```
## Module: <name> — <PASS|FAIL>

| # | Check | Verdict | Details |
|---|-------|---------|---------|
| S-01 | lib.rs registration | PASS | Registered as `pub mod <name>` |
| S-02 | mod.rs simplicity | WARNING | mod.rs has 45 lines of logic — consider extracting |
| ... | ... | ... | ... |

### Score: X PASS / Y WARNING / Z ERROR → **PASS** or **FAIL**

### Required Actions (ERRORs)
1. ...

### Recommended Improvements (WARNINGs)
1. ...
```

## After Audit

If the user requests fixes:
1. Fix all ERRORs first, one phase at a time
2. Then address WARNINGs by priority
3. Re-run affected checks to confirm resolution
4. Do NOT run full `cargo build` or `cargo test` during fixes — use `cargo check` and scoped `cargo test --test <module>_tests`
