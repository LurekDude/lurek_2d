python tools/audit/lua_api_test_coverage.py                # per-module coverage bars
python tools/audit/lua_api_test_coverage.py --json         # JSON output
python tools/audit/lua_api_test_coverage.py --markdown     # Markdown report
python tools/audit/lua_api_test_coverage.py --suggest      # suggest missing markers
python tools/audit/lua_api_test_coverage.py --strict --threshold 40  # exit 1 if below 40%
