---
name: quality-pipeline
description: "Load this skill when running quality checks, interpreting audit/coverage results, or remediating issues found by Lurek2D's Python analysis tools. Covers the full audit→diagnose→fix→verify cycle: which tools to run, what their output means, which agent or fixer script handles each issue type, and how to compose tools into a quality sweep. Skip it for implementing features, writing game scripts, or CAG file editing."
---

# Quality Pipeline Skill

## Owns

- The audit→diagnose→fix→verify quality cycle for Lurek2D
- Knowing which Python tool to run for each quality concern
- Interpreting tool output and mapping issues to the correct fixer or agent
- Composing multi-tool quality sweeps at different granularities (single module → full project)
- Quality pipeline integration with the commit quality gate

## Load When

- Running quality checks before a commit or code review
- Interpreting output from audit, coverage, or validation tools
- Deciding which fixer script to use for a class of issues
- Planning a quality sweep across the project
- Investigating why `quality_report.py` shows a FAIL verdict

## Do Not Own

- Individual tool internals — see `tools/README.md` and subfolder READMEs
- CAG validation — see `tools-cag-validation` skill
- Module-specific audit deep-dives — see `module-audit` skill
- Test writing — see `testing-rust` skill
- Docstring writing — see `documentation` skill

## Tool Categories

### 1. Generators — produce reference docs (run first)

```powershell
python tools/gen_all_docs.py
```

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
| `tools/audit/doc_coverage.py` | `///` docstring coverage | `docs/logs/doc_coverage.json` |
| `tools/audit/docstring_audit.py` | Per-file Lua API docstring quality | `docs/logs/docstring_audit.json` |
| `tools/audit/test_coverage.py` | API-to-test cross-reference | `docs/logs/test_coverage.json` |
| `tools/audit/lua_api_test_coverage.py` | Lua test `@covers` marker coverage | `docs/logs/lua_api_test_coverage.json` |
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

## Issue → Fix Routing

When a tool reports an issue, use this table to determine the remediation path:

| Issue type | Detected by | Automated fix | Agent if manual |
|---|---|---|---|
| Missing `///` docstring | `doc_coverage.py`, `docstring_audit.py` | `add_lua_docstrings_auto.py` | `Doc-Writer` |
| Low-quality docstring stub | `docstring_audit.py` | `improve_lua_docstrings.py` | `Doc-Writer` |
| Missing `# Parameters`/`# Returns` | `doc_coverage.py --report-missing` | `fix_docstrings.py` | `Doc-Writer` |
| Malformed docstring | `docstring_audit.py` | `docstring_fix.py` | `Doc-Writer` |
| Missing AGENT.md | `validate_agent_md.py`, `audit_module.py` | — | `Developer` (load `agent-md` skill) |
| AGENT.md structural error | `validate_agent_md.py` | — | `Developer` (load `agent-md` skill) |
| Missing `docs/specs/*.md` | `validate_module_coverage.py` | — | `Doc-Writer` |
| Missing test coverage | `test_coverage.py`, `lua_api_test_coverage.py` | — | `Tester` |
| Missing `@covers` markers | `lua_api_test_coverage.py` | `add_test_markers.py` | `Tester` |
| Missing example script | `example_coverage.py` | — | `Doc-Writer` (load `examples-management` skill) |
| Thin example | `example_coverage.py` | `expand_examples.py` | `Doc-Writer` |
| Game/demo structure error | `validate_game.py` | — | `Developer` (load `demo-creation` skill) |
| CAG schema violation | `cag_validate.py` | — | `CAG-Architect` |
| Lua API contract violation | `validate_lua_api.py` | — | `Developer` (load `lua-rust-bridge` skill) |
| Module architecture violation | `audit_module.py` | — | `Architect` |

## Quality Sweep Recipes

### Quick check (before any commit)

```powershell
cargo test ; cargo clippy -- -D warnings
```

### Standard pre-commit sweep

```powershell
python tools/gen_all_docs.py
python tools/audit/quality_report.py
python tools/validate/cag_validate.py
cargo test ; cargo clippy -- -D warnings
```

### Single module deep audit

```powershell
python tools/audit/audit_module.py <module> --docs-quality
python tools/audit/validate_agent_md.py --module <module>
python tools/audit/test_coverage.py --suggest
```

### Full project quality sweep

```powershell
# 1. Generate all docs (so auditors read fresh data)
python tools/gen_all_docs.py

# 2. Structural validators
python tools/validate/cag_validate.py
python tools/validate/validate_module_coverage.py
python tools/validate/validate_lua_api.py src/lua_api/

# 3. Documentation coverage
python tools/audit/doc_coverage.py
python tools/audit/docstring_audit.py
python tools/audit/doc_audit.py

# 4. Test coverage
python tools/audit/test_coverage.py
python tools/audit/lua_api_test_coverage.py --report
python tools/audit/example_coverage.py

# 5. Module audits
python tools/audit/audit_module.py --all --docs-quality
python tools/audit/validate_agent_md.py --all

# 6. Master dashboard (reads cached output from steps 3-5)
python tools/audit/quality_report.py

# 7. Quality gate
cargo test ; cargo clippy -- -D warnings
```

### Remediation loop

After a quality sweep, fix issues in priority order:

1. **Validators** (FAIL = blocking): fix structural violations first
2. **Audit ERRORs**: fix items that cause module FAIL verdicts
3. **Audit WARNINGs**: fix if count ≥ 3 for a module (triggers FAIL)
4. **Coverage gaps**: add missing tests, docstrings, examples
5. Re-run the sweep to verify all fixes

## Interpreting quality_report.py Output

The master dashboard shows four sections:

| Section | Source tool | PASS threshold |
|---|---|---|
| Rust doc coverage | `doc_audit.py` → `doc_coverage.py` | ≥ 95% |
| Lua doc coverage | `doc_audit.py` → `gen_lua_api_data.py` | ≥ 95% |
| Rust test coverage | `test_coverage.py` | ≥ 80% |
| Lua test coverage | `test_coverage.py` | ≥ 80% |

Overall verdict is **PASS** only when all four sections pass their thresholds.

## Integration with Commit Workflow

The system prompt mandates `cargo test && cargo clippy -- -D warnings` before every commit. This skill adds the Python quality tools as a recommended pre-commit layer:

1. Run `python tools/gen_all_docs.py` (regenerate docs)
2. Run `python tools/audit/quality_report.py` (check quality dashboard)
3. If PASS → proceed to `cargo test && cargo clippy`
4. If FAIL → use the Issue → Fix Routing table to remediate, then re-check
