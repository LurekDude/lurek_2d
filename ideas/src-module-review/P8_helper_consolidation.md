# P8 Helper Consolidation

Owner: developer

Done When:
- Wave 1 helper set is implemented with tests/examples.
- Wave 2 helper set is planned with owner and acceptance criteria.
- Rust helper consolidation tasks are split into independent small PR-sized items.

Inputs:
- content/library/*
- src/<module>/* for rust helper items

Produces:
- work/<session>/reports/p8_helper_delivery_plan.md
- New or updated helper modules in content/library/

Execution Steps:
1. Wave 1 (ship first):
	- input_action_map
	- audio_manager
	- sprite_animator and anim_controller
	- camera_follow_config
	- tween_chain
	- particle_presets
	- window_config_helper
2. Wave 2 (next):
	- music_player
	- tween_color
	- viewport_setup
	- fs_json_helper
	- camera_follow_walker
	- one_way_platform
	- terrain_explosion
	- image_utils
	- parallax_presets
	- save_utils
	- net_sync
	- i18n_loader
3. Rust helper consolidation backlog:
	- structured log line formatter unification
	- SinkLevel parse cleanup
	- effect enum parse/name centralization
	- light enum parser centralization
4. For each helper, define:
	- target path
	- minimal API
	- one usage example
	- one automated test entry

Out of Scope:
- Rewriting existing game content to force helper adoption in one pass.
