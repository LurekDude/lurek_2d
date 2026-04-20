---
description: "Audit src/ for inline #[cfg(test)] blocks, thin-wrapper violations in src/lua_api/, and non-thin mod.rs files. Reports placement per TST-01..TST-04."
agent: Tester
loads_tools:
  - tools/audit/inline_test_audit.py
  - tools/audit/thin_wrapper_audit.py
  - tools/audit/thin_modrs_audit.py
  - tools/audit/test_coverage.py
---
# Audit Test Placement

## Goal

Audit the Lurek2D repository for violations of the binding testing constraints **TST-01..TST-04** (see [philosophy.md § Testing Constraints](../../docs/architecture/philosophy.md#testing-constraints)) and produce a per-violation report with remediation hints. The prompt finishes when every Success Criteria item below is checked.

Specifically flag:

- **TST-02** Inline `#[cfg(test)]` / `#[test]` blocks anywhere under `src/**/*.rs`.
- **TST-03** Business logic in `src/lua_api/*_api.rs` (closures exceeding the ~10-line threshold, or non-validate/delegate/convert code).
- **TST-04** `mod.rs` files containing function / struct / enum / trait / `impl` definitions (anything beyond `pub mod`, `pub use`, attributes, doc comments).
- **TST-01** Rust integration tests that duplicate `lurek.*`-reachable coverage (best-effort cross-check against `tests/lua/` `@covers` markers).

## Inputs

- `target_scope` — value supplied by the user invocation. Default: entire `src/` tree. Accepted forms: `src/`, `src/<module>/`, or a single `src/<module>/<file>.rs`.

## Steps

1. Load [skill: testing-rust](.github/skills/testing-rust/SKILL.md), [skill: lua-rust-bridge](.github/skills/lua-rust-bridge/SKILL.md), and [skill: module-architecture](.github/skills/module-architecture/SKILL.md) before reading any source files.
2. Resolve `target_scope`; default to `src/` when omitted.
3. Run the three audit scripts (added in session `testing-cleanup-20260420` phase P3 — if any of them is still missing, report that fact and stop so P3 can land first):
   - `python tools/audit/inline_test_audit.py --scope <target_scope>` — TST-02.
   - `python tools/audit/thin_wrapper_audit.py --scope <target_scope>` — TST-03.
   - `python tools/audit/thin_modrs_audit.py --scope <target_scope>` — TST-04.
4. For TST-01 cross-check, run `python tools/audit/test_coverage.py --format json` and flag Rust integration tests whose `@covers` surface is already covered in `tests/lua/`.
5. Aggregate findings into a single report grouped by constraint ID (TST-01..TST-04) and then by file. Include counts in the summary.
6. For each finding, include the recommended remediation (per the skill): relocate to `tests/rust/unit/<module>_tests.rs`, rewrite as Lua BDD test, extract business logic to `src/<module>/<file>.rs`, or move definitions out of `mod.rs`.
7. Write the report to `work/<session>/reports/test-placement-audit.md` and append one JSONL log entry per audit run to `work/<session>/logs/agent_log.jsonl`.
8. Do NOT modify `src/`, `tests/`, or `Cargo.toml` from inside this prompt — remediation is a separate task owned by `Tester` / `Developer` agents.

## Success Criteria

- [ ] All three audit scripts (or the report that they are missing pending P3) have run against `target_scope`.
- [ ] Report at `work/<session>/reports/test-placement-audit.md` lists every violation grouped by TST-01..TST-04 with file path, line, and remediation hint.
- [ ] Counts per constraint and a top-10 offenders list appear in the report summary.
- [ ] `python tools/validate/cag_validate.py` returns no new errors.

## Anti-patterns

- Auto-fixing violations during the audit — this prompt is read-only; remediation is a separate commit.
- Skipping the `tests/lua/` `@covers` cross-check — TST-01 is the most important constraint and will be under-reported otherwise.
- Running on the full `src/` tree when the user passed a narrower `target_scope` — respect the scope parameter.
- Running `git add .` instead of staging only the report file.
- Skipping the Success Criteria check before declaring the prompt done.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/audit-test-placement src/tween/` (or with no argument to audit the full `src/` tree).

## CAG Metadata

- **Mode**: agent
- **Loads skills**: testing-rust, lua-rust-bridge, module-architecture
- **Inputs required**: target_scope
