# tools/audit — Quality Auditing & Coverage Analytics

Scripts that **measure** code quality, documentation coverage, and test
coverage — producing reports that tell you what still needs work.

## Scripts

| Script | Purpose | Output |
|---|---|---|
| `audit_module.py` | End-to-end quality audit for a module (PASS/WARN/ERROR) | stdout / JSON |
| `count_gaps.py` | Count missing-doc items per `lurek.*` module | stdout |
| `doc_audit.py` | Audit Rust `///` doc comment quality | stdout / JSON |
| `doc_coverage.py` | Rust + Lua docstring coverage analytics | `docs/logs/doc_coverage.json` |
| `docstring_audit.py` | Detailed per-file docstring audit | `docs/logs/docstring_audit.json` |
| `gen_coverage_gaps.py` | Generate a coverage gap report | `docs/API/coverage_gaps.md` |
| `golden_test.py` | Run and diff golden output tests | stdout / JSON |
| `integration_coverage.py` | Integration test coverage matrix | stdout |
| `module_audit.py` | Module structure and src/AGENT.md coverage audit | stdout / JSON |
| `quality_report.py` | Overall quality metrics report | stdout / JSON |
| `stress_report.py` | Parse and summarise stress test output | stdout / JSON |
| `test_coverage.py` | Cross-reference API functions vs test files | `docs/logs/test_coverage.json` |
| `validate_agent_md.py` | Validate `src/<module>/AGENT.md` structure (M-01–M-12) | stdout / JSON |

## Common usage

```powershell
# Full module quality audit
python tools/audit/audit_module.py physics
python tools/audit/audit_module.py --tier 1

# Docstring coverage
python tools/audit/doc_coverage.py
python tools/audit/doc_coverage.py --report-missing

# Test coverage
python tools/audit/test_coverage.py
python tools/audit/test_coverage.py --suggest

# Validate AGENT.md files
python tools/audit/validate_agent_md.py
python tools/audit/validate_agent_md.py --module audio
```
