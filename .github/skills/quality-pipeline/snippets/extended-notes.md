| Missing `docs/specs/*.md` | `validate_module_coverage.py` | — | `Doc-Writer` |
| Missing test coverage | `test_coverage.py`, `lua_api_test_coverage.py` | — | `Tester` |
| Lua test structure violation | `lua_test_structure_audit.py` | `lua_test_structure_audit.py --fix` for safe cases | `Tester` |
| Evidence/golden contract violation | `lua_evidence_golden_contract_audit.py` | `lua_evidence_golden_contract_audit.py --fix` for missing markers | `Tester` |
| Missing `@covers` markers | `lua_api_test_coverage.py` | `add_test_markers.py` | `Tester` |
| Missing example script | `example_coverage.py` | — | `Doc-Writer` (load `examples-management` skill) |
| Thin example | `example_coverage.py` | `expand_examples.py` | `Doc-Writer` |
| Game/demo structure error | `validate_game.py` | — | `Developer` (load `demo-creation` skill) |
| CAG schema violation | `cag_validate.py` | — | `CAG-Architect` |
| Lua API contract violation | `validate_lua_api.py` | — | `Developer` (load `lua-rust-bridge` skill) |
| Module architecture violation | `audit_module.py` | — | `Architect` |

### Quality Sweep Recipes
### Quick check (before any commit)

> See [quick-check-before-any-commit.ps1](quick-check-before-any-commit.ps1) for the example.

### Standard pre-commit sweep

> See [standard-pre-commit-sweep.ps1](standard-pre-commit-sweep.ps1) for the example.

### Single module deep audit

> See [single-module-deep-audit.ps1](single-module-deep-audit.ps1) for the example.

### Full project quality sweep

> See [full-project-quality-sweep.ps1](full-project-quality-sweep.ps1) for the example.

### Remediation loop

After a quality sweep, fix issues in priority order:

1. **Validators** (FAIL = blocking): fix structural violations first
2. **Audit ERRORs**: fix items that cause module FAIL verdicts
3. **Audit WARNINGs**: fix if count ≥ 3 for a module (triggers FAIL)
4. **Coverage gaps**: add missing tests, docstrings, examples
5. Re-run the sweep to verify all fixes

### Interpreting quality_report.py Output
The master dashboard shows four sections:

| Section | Source tool | PASS threshold |
|---|---|---|
| Rust doc coverage | `doc_audit.py` → `doc_coverage.py` | ≥ 95% |
| Lua doc coverage | `doc_audit.py` → `gen_lua_api_data.py` | ≥ 95% |
| Rust test coverage | `test_coverage.py` | ≥ 80% |
| Lua test coverage | `test_coverage.py` | ≥ 80% |

Overall verdict is **PASS** only when all four sections pass their thresholds.

### Integration with Commit Workflow
The system prompt mandates `cargo test && cargo clippy -- -D warnings` before every commit. This skill adds the Python quality tools as a recommended pre-commit layer:

1. Run `python tools/gen_all_docs.py` (regenerate docs)
2. Run `python tools/audit/quality_report.py` (check quality dashboard)
3. If PASS → proceed to `cargo test && cargo clippy`
4. If FAIL → use the Issue → Fix Routing table to remediate, then re-check
