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

Execution Steps:
1. Execute coverage wave in priority order:
	- ui
	- render
	- math
	- docs
	- audio
	- network
	- tilemap
	- patterns
	- physics
	- terminal
2. For each module, add assertion-backed tests before adding broad smoke references.
3. Reduce pending/xit in evidence tests:
	- convert to executable assertions where stable
	- keep only justified skips with reason
4. Tooling task:
	- add optional strict mode distinguishing reference vs asserted coverage
5. Rebuild missing-name matrix and publish delta from previous run.

Out of Scope:
- Full test architecture rewrite.
- Non-coverage feature work.
