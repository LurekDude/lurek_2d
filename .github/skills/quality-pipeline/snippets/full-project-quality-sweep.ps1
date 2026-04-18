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
