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
- tools/audit/audit_module.py is the entry point for whole-module quality sweeps.
- The audit checks thin mod.rs rules, file size, docs/specs presence, test coverage, wiki/example coverage, architecture direction, and wrapper leakage.
- It also flags println/eprintln, tests in src/, unsafe without SAFETY, and bare unwrap hotspots.
- Use audit output to route work: Architect for structure, Spec-Owner or Doc-Writer for contracts, Tester for coverage, Developer for code defects.
- Pair audits with doc_coverage.py, test_coverage.py, and validate_module_coverage.py when findings affect contracts.
- Treat module audit as a release/readiness gate, not a feature workflow.
- The audit layer is valuable because it crosses structure, docs, tests, examples, wiki, and code quality in one sweep instead of treating them as isolated checks.
- Findings should route to the right owner quickly: structure to Architect, contract drift to Spec-Owner, docs to Doc-Writer, and code fixes to Developer or specialists.
- The skill owns whole-module readiness checks, not feature development.
## Companion File Index

None - all guidance is inline.

## References
- tools/audit/audit_module.py
- tools/audit/doc_coverage.py
- tools/audit/test_coverage.py
- tools/validate/validate_module_coverage.py
