# P2 Thin-wrapper Offenders

Owner: developer

Done When:
- Business logic and heavy IO are moved out of lua_api wrappers.
- lua_api layer keeps only binding and conversion code.
- Tests pass and docs stay synced.

Inputs:
- src/lua_api/audio_api.rs
- src/lua_api/docs_api.rs
- src/lua_api/image_api.rs
- src/lua_api/ui_api.rs
- src/lua_api/render_api.rs
- src/lua_api/pipeline_api.rs
- src/lua_api/system_api.rs

Produces:
- Refactored domain helpers in src/<module>/
- Leaner lua_api wrappers

Execution Steps:
1. IO pull-down tasks:
	- audio_api: move soundfont read and wav write to audio domain helper
	- docs_api: move scan/export fs logic to docs domain helper
	- image_api: move png save fs logic to image domain helper
	- ui_api: move layout file read to ui domain helper
	- render_api: move bitmap font read path to render domain helper
2. State-machine pull-down tasks:
	- pipeline_api: move retry loop logic to pipeline domain
	- system_api: move parseArgs loop to system/runtime domain
3. Add quick regression tests for moved behaviors.
4. Verify lua API surface remains backward-compatible unless migration note is added.

Out of Scope:
- Renaming public APIs without migration.
- Unrelated formatting refactors.
