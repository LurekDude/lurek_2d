# P4 Lua Coverage Matrix

Owner: Tester

Done When:
- Coverage wave executed for top-gap modules.
- Strict coverage mode proposal is implemented or explicitly deferred with reason.
- Pending/xit debt reduced with measurable count delta.

Inputs:
- tools/audit/test_coverage.py
- tests/lua/**/*.lua

Produces:
- work/<session>/reports/p4_coverage_wave.md
- Updated module priority table

Current Baseline (2026-05-09):
- strict marker coverage: 99.3% (4461/4518)
- hybrid coverage: 99.8% (4510/4518)
- describe coverage: 3.8% (172/4518)
- orphaned markers: 140
- unresolved describe targets: 82

Execution Steps:
1. Execute coverage wave in priority order:
	- network (lowest strict coverage)
	- province (second-lowest strict coverage)
	- render (strict gap + large API)
	- input (strict gap + medium API)
	- event (strict gap + nil/error sensitivity)
	- audio (high unresolved describe sample)
	- data (high unresolved describe sample)
	- docs (test-only namespace cleanup)
	- battle/crafting/collision marker aliases (orphan cleanup cluster)
	- ui (large module, low describe density)
2. For each module, add assertion-backed tests before adding broad smoke references.
3. Reduce pending/xit in evidence tests:
	- convert to executable assertions where stable
	- keep only justified skips with reason
4. Tooling task:
	- add optional strict mode distinguishing reference vs asserted coverage
5. Rebuild missing-name matrix and publish delta from previous run.

Latest Delta Notes:
- strict parser now supports describe("lurek.x.y", ...)
- describe-score is now available per method and per module in `logs/data/lua_api_test_coverage.json`
- CI now has strict coverage gate + describe threshold gate

Out of Scope:
- Full test architecture rewrite.
- Non-coverage feature work.
