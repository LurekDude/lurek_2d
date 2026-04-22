python tools/audit/test_coverage.py                  # coverage metrics → logs/test_coverage.json
python tools/audit/integration_coverage.py           # Lua integration coverage map
python tools/docs/collect_docs.py --report-missing  # undocumented public items (exit 1 if any)
python tools/audit/quality_report.py                 # combined quality snapshot
python tools/audit/lua_api_test_coverage.py          # per-function API coverage (marker + heuristic)
python tools/audit/test_analytics.py --worst 10     # 10 lowest-scoring modules (planned)
