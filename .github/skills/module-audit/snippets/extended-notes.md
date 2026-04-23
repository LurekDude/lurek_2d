> See [s-01-lib-rs-registration.txt](s-01-lib-rs-registration.txt) for the example.

### S-02: mod.rs Simplicity

> See [s-02-mod-rs-simplicity.txt](s-02-mod-rs-simplicity.txt) for the example.

### S-03: File Size Limits

> See [s-03-file-size-limits.txt](s-03-file-size-limits.txt) for the example.

### S-04–S-06: Structural Checks

Run manually by reviewing file names, checking if pure-Lua alternative exists, and scanning `Cargo.toml` for heavy dependencies used only by this module.

### D-01–D-05: Docstring Checks

> See [d-01-d-05-docstring-checks.txt](d-01-d-05-docstring-checks.txt) for the example.

### T-01–T-07: Test Coverage

> See [t-01-t-07-test-coverage.txt](t-01-t-07-test-coverage.txt) for the example.

### R-01–R-05: Architecture Compliance

> See [r-01-r-05-architecture-compliance.txt](r-01-r-05-architecture-compliance.txt) for the example.

### Q-01–Q-06: Code Quality

> See [q-01-q-06-code-quality.txt](q-01-q-06-code-quality.txt) for the example.

### Python Validation Tool
The audit runner automates checks across 12 phases using a single-pass file analyzer
(each `.rs` file is read exactly once per run). **Every invocation always writes a
per-module Markdown report to `logs/quality/<module>.md`** — nothing large ever
goes to stdout, so the VS Code pipe never blocks.

> See [python-validation-tool.ps1](python-validation-tool.ps1) for the example.

Exit code: 0 = all PASS, 1 = any FAIL, 2 = argument error.
Run time: ~0.12 s per module, under 5 s for all 46 modules.

### What every report contains (`logs/quality/<module>.md`)

> See [what-every-report-contains-docs-quality.txt](what-every-report-contains-docs-quality.txt) for the example.

Automated checks: S-01..S-04, A-01..A-07, A-04b, SP-01..SP-06, D-01..D-09,
B-01..B-06, R-01..R-03, T-01..T-05, W-01..W-02, W-04..W-05, Q-01, Q-03..Q-04,
Q-07, I-03. Manual checks are flagged as `🔵 MANUAL` in the report.

### CAG Audit → Fix → Verify Loop
When an agent needs to fix module quality issues, follow this loop:

### Step 1 — Generate reports

> See [step-1-generate-reports.ps1](step-1-generate-reports.ps1) for the example.

### Step 2 — Read the report

Open `logs/quality/<module>.md`. The **Action Items** section at the top lists
every ❌ Error and ⚠️ Warning checkbox with **a precise fix instruction** — file
path, method name, and what to do. Read all errors before writing any code.

### Step 3 — Fix by check ID in priority order

#### B-02 / B-03: struct/impl in lua_api
The report names the exact struct: `impl LuaUserData for LuaFoo`.
1. Move the `struct LuaFoo` definition to `src/<module>/foo.rs`
2. Move the `impl LuaUserData for LuaFoo` block to the same file
3. Add `pub use foo::LuaFoo;` in `src/<module>/mod.rs`
4. Remove from `src/lua_api/<module>_api.rs`

#### B-04: closure body too large
The report names the function and LOC: `'load' (28 LOC, line 42)`.
1. Extract the closure body into a domain method: `pub fn load(...) -> ... { ... }`
   in `src/<module>/mod.rs` or a dedicated file
2. Replace the closure body with a single delegation call:
   `let r = s.borrow_mut().load(arg)?; Ok(r)`

#### SP-04: Functions missing from spec / stale in spec
The report names missing functions explicitly.
1. For each missing: add a row to `## Lua API` in `docs/specs/<module>.md` with
   signature, parameters, return type, and one-line description
2. For each stale: remove the row from `## Lua API`

#### SP-05: Types missing/stale in Key Types
Reports `Types not in spec: Clock, Scheduler`.
1. Add a `### Clock` section to `## Key Types` in `docs/specs/<module>.md`

#### W-02: Missing from content/examples/<module>.lua
The report names the exact function names.
1. Add `lurek.<module>.<funcName>(...)` call to `content/examples/<module>.lua`
2. Prefix each call with a one-line realistic use-case comment

#### W-04: Example–spec sync mismatch
Reports which side has the extra entries.
1. Sync by adding to whichever side is missing

#### T-04: assert_eq! on floats
The report gives exact file:line.
Replace `assert_eq!(a, b)` with `assert!((a - b).abs() < 1e-5)`.

#### T-03: test_ prefix on test names
The report lists the exact function names.
Rename `fn test_foo_bar()` → `fn foo_bar_expected()` using search-replace.

#### D-06: Missing //! on lua_api file
First line of `src/lua_api/<module>_api.rs` must be: `//! <module> Lua API — registers lurek.<module>.* bindings.`

#### D-08: Rustdoc sections in lua_api
Find `# Parameters` / `# Returns` in `src/lua_api/<module>_api.rs`.
Replace with `/// @param name : type` and `/// @return type` format.

#### D-09: Missing section separators
Add `// ── funcName ──────────────────────────────────────` before each `tbl.set` block.

### Step 4 — Re-run and verify

> See [step-4-re-run-and-verify.ps1](step-4-re-run-and-verify.ps1) for the example.

### Batch fix strategy

For multiple modules, read all reports first to identify patterns, then fix the
most common error type across all modules before re-running batch mode:

> See [batch-fix-strategy.ps1](batch-fix-strategy.ps1) for the example.

### Report Template
The `--docs-quality` flag writes a Markdown report to `logs/quality/<module>.md`.
The `stdout` report format (without `--docs-quality`) shows:

> See [report-template.txt](report-template.txt) for the example.

### Batch Mode
When auditing multiple modules with `--all`, the tool:
1. Runs all 64 checks per module
2. Writes `logs/quality/<module>.md` for each module (if `--docs-quality` flag set)
3. Prints a batch summary to stdout:

> See [batch-mode.txt](batch-mode.txt) for the example.

Use `Get-ChildItem logs/quality/` to verify all reports were written.

### Post-Audit Fix Workflow
See **CAG Audit → Fix → Verify Loop** above for the full agent workflow.
Summary of fix priority:

1. **Read** `logs/quality/<module>.md` — the Action Items section is the work queue
2. **Fix ERRORs** — blocking; must fix all before merge
3. **Fix WARNINGs** — reduce until fewer than 3 remain
4. **Re-run** `python tools/audit/audit_module.py <module> --docs-quality` after each fix batch
5. **Never run full build** during fixes — use `cargo check`
6. **Scoped tests only** — `cargo test --test <module>_tests` — never bare `cargo test`
7. **Commit when clean** — only after Status shows 🟢 PASS in `logs/quality/<module>.md`
