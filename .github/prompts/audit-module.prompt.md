---
description: "End-to-end quality audit of one or more Lurek2D src/ modules. Validates spec, AGENT.md, Lua bridge separation, docstrings, example comple..."
agent: Reviewer
tools: [tools/audit/audit_module.py, tools/audit/test_coverage.py, tools/docs/collect_docs.py, tools/validate/validate_lua_api.py]
---
# Audit Module

## Goal

End-to-end quality audit of one or more Lurek2D src/ modules. Validates spec, AGENT.md, Lua bridge separation, docstrings, example comple... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `Module` — value supplied by the user invocation.
- `expected` — value supplied by the user invocation.
- `module` — value supplied by the user invocation.
- `name` — value supplied by the user invocation.
- `scenario` — value supplied by the user invocation.
- `subject` — value supplied by the user invocation.

## Steps

1. Load [skill: agent-md](.github/skills/agent-md/SKILL.md), [skill: documentation](.github/skills/documentation/SKILL.md), [skill: examples-management](.github/skills/examples-management/SKILL.md), [skill: logging](.github/skills/logging/SKILL.md), [skill: lua-rust-bridge](.github/skills/lua-rust-bridge/SKILL.md), [skill: module-audit](.github/skills/module-audit/SKILL.md) before changing any files.
2. **Fix all ERRORs first**, phase by phase (Phase 1 → Phase 12)
3. For missing `docs/specs/<module>.md`: create from the canonical template — do not copy AGENT.md verbatim; the spec must add full type tables, Lua API tables with signatures, and architecture detail not in AGENT.md
4. For missing example coverage (W-02): grep `tbl.set(` to get the authoritative function list, then add each missing function to `content/examples/<module>.lua` with a realistic multi-line use-case comment written in the voice of a game developer
5. For bridge violations (B-02 … B-06): extract logic to domain module first, then thin the closure to a single delegation call
6. For docstring gaps: run `python tools/docs/collect_docs.py --report-missing` after each fix to confirm zero findings before moving on
7. **Address WARNINGs by priority** after all ERRORs are resolved
8. Re-run `python tools/audit/audit_module.py <name>` to confirm resolution
9. Do NOT run full `cargo build` or `cargo test` during fixes — use `cargo check` and scoped `cargo test --test <module>_tests`
10. Update `docs/CHANGELOG.md` before committing any fix
11. Which findings were fixed (check ID → what was changed)
12. Which findings were skipped and why (e.g., false positive, out-of-scope)

## Success Criteria

- [ ] The `Reviewer` agent has produced the artifacts named in Goal.
- [ ] `python tools/validate/cag_validate.py` returns no new errors.

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/audit-module <Module> <expected> <module> <name> <scenario> <subject>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: agent-md, documentation, examples-management, logging, lua-rust-bridge, module-audit
- **Inputs required**: Module, expected, module, name, scenario, subject
