# P7 Plugin Candidates

Owner: build-engineer

Done When:
- Plugin-gate plan exists with order, risk, and rollback strategy.
- Binary impact is measured per candidate gate.
- First extraction wave scope is approved.

Inputs:
- Cargo.toml
- src/lua_api/mod.rs and register.rs
- Affected module roots under src/

Produces:
- work/<session>/reports/p7_plugin_plan.md
- work/<session>/reports/p7_size_impact.md

Execution Steps:
1. Define high-impact gate strategy for:
	- network
	- audio
	- particle
2. Define optional gate strategy for:
	- raycaster
	- procgen
	- dataframe
	- parallax
	- pipeline
	- i18n
3. Add build/profile checks to measure binary-size delta per gate.
4. Publish extraction order, blockers, and fallback for each module.
5. Identify API/documentation changes required by each gate.

Out of Scope:
- Full extraction implementation in this planning doc.
