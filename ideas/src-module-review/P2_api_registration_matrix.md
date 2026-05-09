# P2 API Registration Matrix

Owner: developer

Done When:
- Gating behavior is consistent with ModulesConfig and documented policy.
- Specs and changelog reflect final gating decisions.
- No unresolved mismatch remains for listed modules.

Inputs:
- src/lua_api/register.rs
- src/runtime/config.rs
- docs/specs/data.md
- docs/specs/dataframe.md
- docs/specs/province.md
- docs/specs/patterns.md

Produces:
- work/<session>/reports/p2_registration_decisions.md
- Updated specs and docs/CHANGELOG.md

Execution Steps:
1. Resolve data registration mismatch:
	- either gate data by modules.data
	- or remove/deprecate modules.data and document always-on behavior
2. Resolve dataframe mismatch:
	- either add modules.dataframe and gate registration
	- or document dataframe as intentionally always-on
3. Resolve province mismatch:
	- replace modules.image gate with dedicated modules.province gate
	- or explicitly document coupling as intentional
4. Resolve patterns mismatch:
	- decide whether patterns should have its own gate
	- remove pipeline coupling if not intentional
5. Run spec-to-binding check for high-delta areas:
	- ui
	- tilemap
	- input
6. Record one clear decision per mismatch with rationale and impact.

Out of Scope:
- Broad API redesign.
- New modules.
