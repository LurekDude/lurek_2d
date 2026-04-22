---
name: quality-pipeline
description: "Load this skill when running quality checks, interpreting audit/coverage results, or remediating issues found by Lurek2D's Python analysis tools. Covers the full audit→diagnose→fix→verify cycle: which tools to run, what their output means, which agent or fixer script handles each issue type, and how to compose tools into a quality sweep. Skip it for implementing features, writing game scripts, or CAG file editing."
---
# quality-pipeline

## Mission

# Quality Pipeline Skill

## When To Load

- Running quality checks before a commit or code review
- Interpreting output from audit, coverage, or validation tools
- Deciding which fixer script to use for a class of issues
- Planning a quality sweep across the project
- Investigating why `quality_report.py` shows a FAIL verdict

## When To Skip

- Skip it for implementing features, writing game scripts, or CAG file editing.

## Domain Knowledge

### Owns
- The audit→diagnose→fix→verify quality cycle for Lurek2D
- Knowing which Python tool to run for each quality concern
- Interpreting tool output and mapping issues to the correct fixer or agent
- Composing multi-tool quality sweeps at different granularities (single module → full project)
- Quality pipeline integration with the commit quality gate

### Do Not Own
- Individual tool internals — see `tools/README.md` and subfolder READMEs
- CAG validation — see `tools-cag-validation` skill
- Module-specific audit deep-dives — see `module-audit` skill
- Test writing — see `testing-rust` skill
- Docstring writing — see `documentation` skill

### Tool Categories
### 1. Generators — produce reference docs (run first)

> See [snippets/1-generators-produce-reference-docs-run.ps1](snippets/1-generators-produce-reference-docs-run.ps1) for the example.

This orchestrates all doc generators under `tools/docs/`. Always run this before auditing — auditors read generated output.

### 2. Validators — structural contract checks (binary PASS/FAIL)

| Tool | Checks | When to run |
|---|---|---|
| `tools/validate/cag_validate.py` | `.github/` CAG files | After any `.github/` edit |
| `tools/validate/validate_lua_api.py` | `src/lua_api/*.rs` contract compliance | After any lua_api edit |
| `tools/validate/validate_game.py` | Game/demo directory structure | After any `content/demos/` or `content/examples/` edit |
| `tools/validate/validate_module_coverage.py` | Every `src/` module has a `docs/specs/*.md` | After creating/renaming modules |
| `tools/validate/check_callbacks.py` | Callback doc generation integrity | After editing callback docs |

### 3. Auditors — measure quality metrics

| Tool | Measures | Output |
|---|---|---|
| `tools/audit/quality_report.py` | **Master dashboard** — aggregates doc + test + module audits | PASS/FAIL verdict |
| `tools/audit/doc_audit.py` | Rust + Lua documentation completeness | % coverage |
| `tools/audit/doc_coverage.py` | `///` docstring coverage | `logs/doc_coverage.json` |
| `tools/audit/docstring_audit.py` | Per-file Lua API docstring quality | `logs/docstring_audit.json` |
| `tools/audit/test_coverage.py` | API-to-test cross-reference | `logs/test_coverage.json` |
| `tools/audit/lua_api_test_coverage.py` | Lua test `@covers` marker coverage | `logs/lua_api_test_coverage.json` |
| `tools/audit/lua_test_structure_audit.py` | Lua test structure rules (`@description`, legacy markers, `test_summary()`) | stdout / JSON |
| `tools/audit/lua_evidence_golden_contract_audit.py` | Lua evidence/golden contract rules (`@evidence`, mixed prechecks, compare-only goldens) | stdout / JSON |
| `tools/audit/example_coverage.py` | Content/examples vs Lua API coverage | stdout |
| `tools/audit/integration_coverage.py` | Integration test module-pair matrix | stdout |
| `tools/audit/audit_module.py` | 12-phase per-module quality audit | `docs/quality/<module>.md` |
| `tools/audit/validate_agent_md.py` | AGENT.md structural validation | stdout |
| `tools/audit/count_gaps.py` | Missing-doc items per `lurek.*` module | stdout |

### 4. Fixers — automated remediation

| Tool | Fixes | Triggered by |
|---|---|---|
| `tools/fix/add_lua_docstrings_auto.py` | Missing `///` stubs in `lua_api/*.rs` | `docstring_audit.py` |
| `tools/fix/docstring_fix.py` | Malformed docstrings from audit JSON | `docstring_audit.py` |
| `tools/fix/fix_docstrings.py` | Missing `# Parameters`/`# Returns` sections | `doc_coverage.py --report-missing` |
| `tools/fix/improve_lua_docstrings.py` | Low-quality stub `///` descriptions | `docstring_audit.py` |
| `tools/fix/format_examples.py` | Example code style | `example_coverage.py` |
| `tools/fix/expand_examples.py` | Thin examples needing more API usage | `example_coverage.py` |
| `tools/fix/add_test_markers.py` | Missing `@covers` annotations | `lua_api_test_coverage.py` |

### Issue → Fix Routing
When a tool reports an issue, use this table to determine the remediation path:

| Issue type | Detected by | Automated fix | Agent if manual |
|---|---|---|---|
| Missing `///` docstring | `doc_coverage.py`, `docstring_audit.py` | `add_lua_docstrings_auto.py` | `Doc-Writer` |
| Low-quality docstring stub | `docstring_audit.py` | `improve_lua_docstrings.py` | `Doc-Writer` |
| Missing `# Parameters`/`# Returns` | `doc_coverage.py --report-missing` | `fix_docstrings.py` | `Doc-Writer` |
| Malformed docstring | `docstring_audit.py` | `docstring_fix.py` | `Doc-Writer` |
| Missing AGENT.md | `validate_agent_md.py`, `audit_module.py` | — | `Developer` (load `agent-md` skill) |

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/1-generators-produce-reference-docs-run.ps1](snippets/1-generators-produce-reference-docs-run.ps1) — 1. Generators — produce reference docs (run first)
- [snippets/quick-check-before-any-commit.ps1](snippets/quick-check-before-any-commit.ps1) — Quick check (before any commit)
- [snippets/standard-pre-commit-sweep.ps1](snippets/standard-pre-commit-sweep.ps1) — Standard pre-commit sweep
- [snippets/single-module-deep-audit.ps1](snippets/single-module-deep-audit.ps1) — Single module deep audit
- [snippets/full-project-quality-sweep.ps1](snippets/full-project-quality-sweep.ps1) — Full project quality sweep
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
