python tools/audit/lua_api_test_coverage.py              # summary with per-module bars
python tools/audit/lua_api_test_coverage.py --json        # JSON output
python tools/audit/lua_api_test_coverage.py --markdown    # markdown report
python tools/audit/lua_api_test_coverage.py --suggest     # show uncovered functions
python tools/audit/lua_api_test_coverage.py --strict --threshold 40  # CI gate
