---
name: module-audit
description: "Load this skill when running end-to-end audits on src/ modules for docs, tests, architecture, wiki, or code quality. Skip it for feature work, game scripts, or pure Lua."
---
# module-audit

## Mission

Own the 12-phase module audit process: structure, documentation, testing, architecture, code quality checks, and the tools/audit/audit_module.py workflow.

## When To Load

- Running a full quality audit on a src/ module
- Checking a module against the 12-phase audit checklist
- Understanding the expected file structure and size limits
- Preparing a module for review or release

## When To Skip

- Implementing features -> use rust-coding skill
- Writing game scripts -> use lua-scripting skill
- Pure Lua work -> use lua-scripting skill

## Domain Knowledge
- `python tools/audit/audit_module.py <module>` is the entry point. It runs 12 phases: (1) mod.rs thinness, (2) file size limits, (3) docs/specs presence, (4) Lua API coverage, (5) test coverage, (6) wiki coverage, (7) example coverage, (8) dependency direction, (9) lua_api wrapper leakage, (10) println/eprintln hotspots, (11) unsafe without SAFETY comments, (12) bare unwrap in public paths. A module that passes all 12 is ready for release.
- Phase 9 (wrapper leakage) checks that no `src/<module>/` file imports from `src/lua_api/`. If it does, that is a T-02 violation — not a style issue, a blocking defect.
- Phase 3 (docs/specs presence) checks that `docs/specs/<module>.md` exists AND has non-empty Ownership and Invariants sections. A spec file with placeholder text fails this phase.
- Phase 4 (Lua API coverage) compares functions registered in `src/lua_api/<module>_api.rs` against `@covers` markers in `tests/lua/unit/test_<module>_*.lua`. Every registered function must have at least one test covering it.
- Phase 10 (println/eprintln) treats any `println!` in `src/<module>/` as a defect. Engine output must go through `src/log/` with proper level tagging. `eprintln!` in bin/ and tools/ is acceptable.
- Audit output format: each finding includes phase number, file path, line number, finding type (BLOCKING/WARNING/INFO), and description. BLOCKING findings must be resolved before merge. WARNING findings should be resolved. INFO findings are informational.
- Routing audit findings: BLOCKING dependency violations → Architect. BLOCKING coverage gaps → Tester. BLOCKING spec defects → Doc-Writer. Code-quality findings (unsafe, unwrap) → Developer. The Verifier decides accept/reject based on the full picture.
- Run `python tools/audit/doc_coverage.py --module <name>` alongside the main audit to get the documentation completeness score separately. The main audit reports presence; doc_coverage reports density.
- Use the audit as a pre-PR gate, not a post-merge cleanup job. A module that enters review with 12/12 phases passing costs half the reviewer time.
- When several audit findings share a root cause (e.g., all phase-3 failures trace to a missing spec), report the shared root cause first rather than listing 8 individual findings.
## Companion File Index

None - all guidance is inline.

## References
- tools/audit/audit_module.py
- tools/audit/doc_coverage.py
- tools/audit/test_coverage.py
- tools/validate/validate_module_coverage.py
