# tools/audit — Quality Auditing & Coverage Analytics

Scripts that **measure** code quality, documentation coverage, and test
coverage — producing reports that tell you what still needs work.

## Scripts

### Master dashboards — aggregate multiple sub-tools

| Script              | Purpose                                   | Sub-tools called                                              | Output        |
| ------------------- | ----------------------------------------- | ------------------------------------------------------------- | ------------- |
| `quality_report.py` | Overall quality dashboard (PASS/FAIL)     | `doc_audit`, `test_coverage`, `module_audit`, `validate_game` | stdout / JSON |
| `doc_audit.py`      | Documentation audit (Rust + Lua combined) | `collect_docs`, `gen_lua_api_data`                            | stdout / JSON |

### Docstring coverage — measure and report docstring completeness

| Script               | Purpose                                      | Output                           |
| -------------------- | -------------------------------------------- | -------------------------------- |
| `doc_coverage.py`    | Rust + Lua `///` docstring coverage metrics  | `docs/logs/doc_coverage.json`    |
| `docstring_audit.py` | Per-file Lua API docstring quality audit     | `docs/logs/docstring_audit.json` |
| `count_gaps.py`      | Count missing-doc items per `lurek.*` module | stdout                           |

### Test coverage — measure test completeness

| Script                                  | Purpose                                                                                             | Output                                 |
| --------------------------------------- | --------------------------------------------------------------------------------------------------- | -------------------------------------- |
| `test_coverage.py`                      | Cross-reference `pub` items vs test files                                                           | `docs/logs/test_coverage.json`         |
| `lua_api_test_coverage.py`              | Lua API test coverage (via `@covers` markers)                                                       | `docs/logs/lua_api_test_coverage.json` |
| `lua_test_structure_audit.py`           | Lua test structure audit: `@description` placement, legacy markers, and `test_summary()` ending     | stdout / JSON                          |
| `lua_evidence_golden_contract_audit.py` | Evidence/golden contract audit: mixed prechecks, missing `@evidence`, and golden generation logic   | stdout / JSON                          |
| `unit_test_api_coverage.py`             | Unit test API coverage metrics                                                                      | stdout                                 |
| `example_coverage.py`                   | Cross-reference `content/examples/` vs Lua API; exits 1 if any gaps (`--report` for CI)             | stdout / JSON                          |
| `example_add_missing.py`                | Append stub blocks for uncovered API items to example files; use with `flesh-out-example.prompt.md` | patches `.lua` files                   |
| `integration_coverage.py`               | Integration test module-pair heat map                                                               | stdout / JSON                          |

### Module quality — end-to-end module audits

| Script                 | Purpose                                                           | Output                            |
| ---------------------- | ----------------------------------------------------------------- | --------------------------------- |
| `audit_module.py`      | 12-phase module quality audit (PASS/WARN/ERROR)                   | `docs/quality/<module>.md` / JSON |
| `validate_agent_md.py` | Validate merged docs/specs module references (legacy script name) | stdout / JSON                     |
| `module_audit.py`      | Module restructuring & reference audit                            | stdout / JSON                     |

### Specialised audits

| Script                 | Purpose                          | Output                      |
| ---------------------- | -------------------------------- | --------------------------- |
| `gen_coverage_gaps.py` | Rust→Lua API coverage gap report | `docs/API/coverage_gaps.md` |
| `golden_test.py`       | Deterministic output diff tests  | stdout / JSON               |
| `stress_report.py`     | Stress test timing report        | stdout / JSON               |
| `test_analytics.py`    | Test execution trend analysis    | stdout                      |

### CAG layer audits

| Script                    | Purpose                                                                                                                | Output                  |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| `cag_link_check.py`       | Walk every `.github/**/*.md`, extract markdown links + backtick paths, and report broken targets by category.          | stdout / JSON (`--report`) |
| `cag_coverage.py`         | Required-section + frontmatter-field coverage matrix for every CAG file type.                                          | stdout / markdown / JSON |
| `cag_persona_matrix.py`   | 6 × N persona ↔ agent matrix from frontmatter; flags 0-persona agents and 0-agent personas.                            | stdout / markdown / JSON |

Companion validator: `tools/validate/cag_validate.py` (rule engine for the
same files; the audit tools above are read-only analytics).

### Internal helpers

| Script                                  | Purpose                                                  |
| --------------------------------------- | -------------------------------------------------------- |
| `annotate_tests.py`                     | Add annotation metadata to test files                    |
| `lua_test_structure_audit.py`           | Audit/fix Lua BDD comment and `test_summary()` structure |
| `lua_evidence_golden_contract_audit.py` | Audit/fix Lua evidence and golden contract markers       |
| `parse_test_log.py`                     | Parse Rust test execution logs                           |

## Common usage

```powershell
# --- Master dashboards ---
python tools/audit/quality_report.py            # overall quality PASS/FAIL
python tools/audit/doc_audit.py                  # combined Rust+Lua docs audit

# --- Docstring coverage ---
python tools/audit/doc_coverage.py               # docstring coverage %
python tools/audit/doc_coverage.py --report-missing  # list missing items
python tools/audit/docstring_audit.py            # per-file Lua API quality

# --- Test coverage ---
python tools/audit/test_coverage.py              # Rust test coverage
python tools/audit/test_coverage.py --suggest    # suggest new tests
python tools/audit/lua_api_test_coverage.py --report  # Lua test coverage
python tools/audit/lua_test_structure_audit.py   # Lua test structure audit
python tools/audit/lua_test_structure_audit.py --fix  # normalize legacy syntax + test_summary placement
python tools/audit/lua_evidence_golden_contract_audit.py        # evidence/golden contract audit
python tools/audit/lua_evidence_golden_contract_audit.py --fix  # add obvious missing @evidence markers
python tools/audit/example_coverage.py           # content/examples/ coverage
python tools/audit/integration_coverage.py       # integration test heatmap

# --- Module audits ---
python tools/audit/audit_module.py physics       # one module
python tools/audit/audit_module.py --all         # all modules
python tools/audit/audit_module.py --all --docs-quality  # all + docs quality
python tools/audit/validate_agent_md.py --all    # validate all merged module specs
python tools/audit/validate_agent_md.py --module audio  # one module

# --- CAG layer audits ---
python tools/audit/cag_link_check.py                              # broken-link report
python tools/audit/cag_link_check.py --strict                     # exit 1 on any broken link
python tools/audit/cag_coverage.py --type agent --format markdown # per-type coverage matrix
python tools/audit/cag_persona_matrix.py --format markdown        # persona x agent matrix
```
