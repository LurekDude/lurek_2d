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

**Audit tool:** tools/audit/audit_module.py NAME runs a 12-phase audit. Use --all for all modules, --json for machine-readable output. Each phase produces PASS, WARN, or ERROR.

**12-phase checks:** (1) Structure: mod.rs exists and is valid, (2) Mod.rs size: max 30 lines normal, max 100 absolute (ERROR if >100), (3) File size: max 2000 LOC (ERROR), max 1500 (WARNING), (4) Docstrings: /// on all pub items, (5) AGENT.md sync: module has a docs/specs/<module>.md, (6) Test coverage: tests exist for pub functions, (7) Architecture: tier hierarchy respected, no upward imports, (8) Code quality: no println!/eprintln!, unsafe needs // SAFETY:, .unwrap() = WARNING, (9) Lua API: if lua_api/<module>_api.rs exists, docstrings complete, (10) Wiki: wiki/<module>.md exists and is current, (11) Examples: content/examples/<module>.lua exists, (12) Performance: no known hot-path violations.

**mod.rs rules:** must contain ONLY pub mod, pub use, attributes, and doc comments. No function definitions, no struct definitions, no impl blocks.

**Architecture tier enforcement:** no use crate::lua_api in domain modules. Domain (src/<module>/) must not import the binding layer. Higher tiers may import lower tiers but never the reverse.

**Forbidden patterns:** no #[cfg(test)] in src/ (tests go in tests/rust/unit/), no println!/eprintln! (use log::* macros), no bare .unwrap() without justification comment.

## Companion File Index

None - all guidance is inline.

## References

- tools/audit/audit_module.py - 12-phase module audit tool
- tools/audit/doc_coverage.py - docstring coverage metrics
- tools/audit/test_coverage.py - test coverage metrics

