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
- tools/audit/audit_module.py is the entry point for whole-module quality sweeps, and its value comes from combining structural, documentation, testing, and code-quality checks in one repeatable pass.
- The audit checks thin mod.rs rules, file size, docs/specs presence, test coverage, wiki and example coverage, architecture direction, and wrapper leakage across the whole module surface.
- It also flags println/eprintln, tests in src/, unsafe without SAFETY, and bare unwrap hotspots, which makes it useful for release readiness even before a human deep review starts.
- Treat module audit as a readiness or review gate, not as a feature workflow; it should tell you whether a module is coherent enough to ship or hand off, not how to implement a new behavior.
- Use audit output to route work quickly: architecture findings to structure owners, contract drift to doc or spec owners, coverage gaps to test owners, and local code defects to the relevant implementation specialist.
- Pair audits with doc_coverage.py, test_coverage.py, wiki coverage, and validate_module_coverage.py when findings affect contracts or module inventory.
- A good audit read distinguishes blocking defects from informational drift; not every warning should force the same urgency or same owner.
- Audit findings should remain file-specific and evidence-based so follow-up work can stay narrow instead of turning one report into a repo-wide cleanup campaign.
- Because the audit crosses docs, tests, examples, and source rules, it is often the fastest way to see whether a module is internally consistent, not just compiling.
- If several findings point to the same structural mistake, report the shared root cause first instead of listing symptoms separately.
## Companion File Index

None - all guidance is inline.

## References
- tools/audit/audit_module.py
- tools/audit/doc_coverage.py
- tools/audit/test_coverage.py
- tools/validate/validate_module_coverage.py
