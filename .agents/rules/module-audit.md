---
description: "Load when running end-to-end audits on src/ modules for docs, tests, architecture, wiki, or code quality. Skip for feature work, game scripts, or pure Lua."
alwaysApply: false
---

# module-audit

## Mission
- Own the 12-phase module audit process: structure, documentation, testing, architecture, and code quality.

## When To Load
- Run a full quality audit on a src/ module.
- Check a module against the 12-phase audit checklist.
- Understand expected file structure and size limits.
- Prepare a module for review or release.

## When To Skip
- Implementing features → use rust-coding skill.
- Writing game scripts → use lua-scripting skill.
- Pure Lua work → use lua-scripting skill.

## Domain Knowledge
- tools/audit/audit_module.py is the entry point for whole-module quality sweeps; its value comes from combining structural, documentation, testing, and code-quality checks in one repeatable pass.
- The audit checks thin mod.rs rules, file size, docs/specs presence, test coverage, wiki and example coverage, architecture direction, and wrapper leakage.
- It also flags println/eprintln, tests in src/, unsafe without SAFETY, and bare unwrap hotspots.
- Treat module audit as a readiness or review gate, not as a feature workflow.
- Use audit output to route work quickly: architecture findings to structure owners, contract drift to doc or spec owners, coverage gaps to test owners.
- Pair audits with doc_coverage.py, test_coverage.py, wiki coverage, and validate_module_coverage.py.
- A good audit read distinguishes blocking defects from informational drift.
- If several findings point to the same structural mistake, report the shared root cause first.

## References
- tools/audit/audit_module.py
- tools/audit/doc_coverage.py
- tools/audit/test_coverage.py
- tools/validate/validate_module_coverage.py
