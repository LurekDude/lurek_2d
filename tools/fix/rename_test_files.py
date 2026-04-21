"""
tools/fix/rename_test_files.py
Renames test Lua files from old namespace names to new namespace names,
updates tests/lua/harness.rs paths and function names, and updates all
text references across the project.

Run from repo root: python tools/fix/rename_test_files.py
"""
import os, re, pathlib, shutil

ROOT = pathlib.Path("C:/Users/tombl/Documents/luna2d")
TESTS_LUA = ROOT / "tests" / "lua"

# (old relative path from tests/lua, new relative path from tests/lua)
# Target does NOT exist for these - simple renames
RENAMES = [
    # UNIT
    ("unit/test_ecs.lua",             "unit/test_ecs.lua"),
    ("unit/test_runtime.lua",             "unit/test_runtime.lua"),
    ("unit/test_runtime_platform.lua",             "unit/test_runtime_platform.lua"),
    ("unit/test_physics_collision.lua",          "unit/test_physics_collision.lua"),
    ("unit/test_render.lua",           "unit/test_render.lua"),
    ("unit/test_render_pipeline.lua",          "unit/test_render_pipeline.lua"),
    ("unit/test_i18n.lua",       "unit/test_i18n.lua"),
    ("unit/test_mods.lua",            "unit/test_mods.lua"),
    ("unit/test_pathfind.lua",        "unit/test_pathfind.lua"),
    ("unit/test_save.lua",           "unit/test_save.lua"),
    # Conflicts: test_event.lua and test_effect.lua already exist
    ("unit/test_event_signal.lua",             "unit/test_event_signal.lua"),
    ("unit/test_effect_api.lua",                 "unit/test_effect_api.lua"),
    ("unit/test_effect_overlay.lua",            "unit/test_effect_overlay.lua"),
    ("unit/test_effect_postfx.lua",             "unit/test_effect_postfx.lua"),

    # INTEGRATION
    ("integration/test_ecs_ai.lua",            "integration/test_ecs_ai.lua"),
    ("integration/test_ecs_render.lua",       "integration/test_ecs_render.lua"),
    ("integration/test_ecs_physics.lua",        "integration/test_ecs_physics.lua"),
    ("integration/test_render_animation.lua",    "integration/test_render_animation.lua"),
    ("integration/test_render_camera.lua",       "integration/test_render_camera.lua"),
    ("integration/test_light_render.lua",        "integration/test_light_render.lua"),
    ("integration/test_i18n_ui.lua",       "integration/test_i18n_ui.lua"),
    ("integration/test_math_render.lua",         "integration/test_math_render.lua"),
    ("integration/test_pathfind_ecs.lua",    "integration/test_pathfind_ecs.lua"),
    ("integration/test_save_ecs_scene.lua", "integration/test_save_ecs_scene.lua"),
    ("integration/test_save_tilemap.lua",      "integration/test_save_tilemap.lua"),
    ("integration/test_scene_ecs.lua",          "integration/test_scene_ecs.lua"),
    ("integration/test_event_entity.lua",         "integration/test_event_entity.lua"),
    ("integration/test_tilemap_pathfind.lua",   "integration/test_tilemap_pathfind.lua"),
    ("integration/test_ai_pathfind.lua",        "integration/test_ai_pathfind.lua"),
    ("integration/test_ai_ecs_scene.lua",       "integration/test_ai_ecs_scene.lua"),
    ("integration/test_tween_ecs.lua",          "integration/test_tween_ecs.lua"),
    ("integration/test_runtime_system.lua",                "integration/test_runtime_system.lua"),
    ("integration/test_save_ecs.lua",           "integration/test_save_ecs.lua"),

    # GOLDEN
    ("golden/test_ecs_golden.lua",              "golden/test_ecs_golden.lua"),
    ("golden/test_render_golden.lua",            "golden/test_render_golden.lua"),
    # Conflict: test_pathfind_golden.lua exists â€” use distinct name for grid test
    ("golden/test_pathfind_golden_grid.lua",         "golden/test_pathfind_golden_grid.lua"),

    # EVIDENCE
    ("evidence/test_evidence_render_draw_cmds.lua", "evidence/test_evidence_render_draw_cmds.lua"),
    ("evidence/test_evidence_render_drawing.lua",   "evidence/test_evidence_render_drawing.lua"),
    ("evidence/test_evidence_render_graphics.lua",          "evidence/test_evidence_render_graphics.lua"),
    ("evidence/test_evidence_effect_overlay.lua",           "evidence/test_evidence_effect_overlay.lua"),
    # Conflict: test_evidence_pathfind.lua exists (13 lines) â€” rename large one to _extended
    ("evidence/test_evidence_pathfind_extended.lua",       "evidence/test_evidence_pathfind_extended.lua"),
    ("evidence/test_evidence_effect_postfx.lua",            "evidence/test_evidence_effect_postfx.lua"),
    ("evidence/test_evidence_effect_types.lua",      "evidence/test_evidence_effect_types.lua"),

    # SECURITY
    ("security/test_save_validation.lua",        "security/test_save_validation.lua"),

    # STRESS
    ("stress/test_ecs_bulk_spawn.lua",            "stress/test_ecs_bulk_spawn.lua"),
    ("stress/test_ecs_stress.lua",                "stress/test_ecs_stress.lua"),
    ("stress/test_render_stress.lua",              "stress/test_render_stress.lua"),
    ("stress/test_pathfind_stress.lua",           "stress/test_pathfind_stress.lua"),
    ("stress/test_save_stress.lua",              "stress/test_save_stress.lua"),
    ("stress/test_event_stress.lua",                "stress/test_event_stress.lua"),
]

# harness.rs function name replacements for old namespace terms in fn names.
# Applied as whole-word regex replacements in fn names only.
# Ordered from most specific to most general.
HARNESS_FN_RENAMES = [
    # path-specific first (longer patterns)
    ("savegame_entity_scene",  "save_ecs_scene"),
    ("savegame_entity_stress", "save_entity_stress"),  # keep entity here as concept
    ("savegame_validation",    "save_validation"),
    ("savegame_tilemap",       "save_tilemap"),
    ("savegame_stress",        "save_stress"),
    ("savegame",               "save"),
    ("signal_entity",          "event_entity"),
    ("signal_stress",          "event_stress"),
    ("signal",                 "event_signal"),  # standalone signal â†’ event_signal
    ("entity_bulk_spawn",      "ecs_bulk_spawn"),
    ("entity_stress",          "ecs_stress"),
    ("entity_ai",              "ecs_ai"),
    ("entity_scene",           "ecs_scene"),
    ("entity_physics",         "ecs_physics"),
    ("entity_serialization",   "ecs_serialization"),
    ("entity_query",           "ecs_query"),
    ("entity_system",          "ecs_system"),
    ("entity_observers",       "ecs_observers"),
    ("entity_relationships",   "ecs_relationships"),
    ("entity_graphics",        "ecs_render"),
    ("entity",                 "ecs"),            # standalone entity
    ("pathfinding_entity",     "pathfind_ecs"),
    ("tilemap_pathfinding",    "tilemap_pathfind"),
    ("ai_pathfinding",         "ai_pathfind"),
    ("pathfinding_stress",     "pathfind_stress"),
    ("pathfinding_golden",     "pathfind_golden_grid"),
    ("pathfinding",            "pathfind"),       # standalone pathfinding
    ("graphics_animation",     "render_animation"),
    ("graphics_camera",        "render_camera"),
    ("graphics_stress",        "render_stress"),
    ("graphics_golden",        "render_golden"),
    ("graphics",               "render"),         # standalone graphics
    ("graphic_draw_cmds",      "render_draw_cmds"),
    ("graphic_drawing",        "render_drawing"),
    ("light_graphics",         "light_render"),
    ("math_graphics",          "math_render"),
    ("postfx_types",           "effect_types"),
    ("postfx_stack",           "effect_stack"),
    ("postfx",                 "effect_postfx"),  # standalone postfx
    ("overlay_water",          "effect_overlay_water"),
    ("overlay",                "effect_overlay"), # standalone overlay
    ("_fx",                    "_effect_api"),    # test_effect_api â†’ test_effect_api
    ("localization_ui",        "i18n_ui"),
    ("localization",           "i18n"),
    ("modding",                "mods"),
    ("collision_helpers",      "physics_collision_helpers"),
    ("collision",              "physics_collision"),
    ("rendering_drawing",      "render_pipeline_drawing"),
    ("rendering",              "render_pipeline"),
    ("save_entity",            "save_ecs"),
    # system â†’ runtime (only unit/integration system, not data_system)
    ("lua_integration_system", "lua_integration_runtime_system"),
    ("lua_test_system",        "lua_test_runtime_platform"),
]


def rename_file(old_rel: str, new_rel: str) -> bool:
    old = TESTS_LUA / old_rel
    new = TESTS_LUA / new_rel
    if not old.exists():
        print(f"  SKIP (not found): {old_rel}")
        return False
    if new.exists():
        print(f"  SKIP (target exists): {old_rel} â†’ {new_rel}")
        return False
    new.parent.mkdir(parents=True, exist_ok=True)
    old.rename(new)
    print(f"  RENAMED: {old_rel} â†’ {new_rel}")
    return True


def update_harness(renames: list) -> None:
    harness = ROOT / "tests" / "lua" / "harness.rs"
    text = harness.read_text(encoding="utf-8")
    orig = text

    # 1. Update run_lua_test() path strings
    for old_rel, new_rel in renames:
        # old_rel uses forward slashes; harness uses forward slashes
        old_path = old_rel.replace("\\", "/")
        new_path = new_rel.replace("\\", "/")
        text = text.replace(f'"{old_path}"', f'"{new_path}"')

    # 2. Update function names â€” apply from most specific to most general
    # Work only on fn name tokens, not in strings
    def replace_fn_name(t: str, old_part: str, new_part: str) -> str:
        # Match fn name occurrences: word boundary replacements in fn declarations
        # and call sites. We replace the token inside identifier-like contexts.
        # Use negative lookbehind/ahead for word chars to avoid partial matches.
        pattern = re.compile(r'\b' + re.escape(old_part) + r'\b')
        return pattern.sub(new_part, t)

    for old_part, new_part in HARNESS_FN_RENAMES:
        text = replace_fn_name(text, old_part, new_part)

    if text != orig:
        harness.write_text(text, encoding="utf-8")
        changed = sum(1 for a, b in zip(orig.splitlines(), text.splitlines()) if a != b)
        print(f"  harness.rs: {changed} lines updated")
    else:
        print("  harness.rs: no changes")


def update_text_references(renames: list) -> None:
    """Replace old filename references in all project text files."""
    EXTS = {".lua", ".rs", ".md", ".txt", ".toml", ".py", ".json"}
    SKIP_DIRS = {"build", "target", ".git", "node_modules", "work"}

    # Build mapping from old basename â†’ new basename (for text search)
    basename_map = {}
    for old_rel, new_rel in renames:
        old_name = pathlib.Path(old_rel).name  # e.g. test_event_signal.lua
        new_name = pathlib.Path(new_rel).name
        if old_name != new_name:
            basename_map[old_name] = new_name
            # Also map without .lua extension
            basename_map[old_name[:-4]] = new_name[:-4]

    # Also map full relative paths
    path_map = {}
    for old_rel, new_rel in renames:
        if old_rel != new_rel:
            path_map[old_rel.replace("\\", "/")] = new_rel.replace("\\", "/")

    total_files, total_lines = 0, 0
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in filenames:
            fp = pathlib.Path(dirpath) / fn
            if fp.suffix not in EXTS:
                continue
            try:
                orig = fp.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue
            text = orig
            # Replace full relative paths first
            for old_p, new_p in path_map.items():
                text = text.replace(old_p, new_p)
            # Replace bare basenames (with word boundary)
            for old_b, new_b in basename_map.items():
                if old_b in text:
                    text = re.sub(r'\b' + re.escape(old_b) + r'\b', new_b, text)
            if text != orig:
                try:
                    fp.write_text(text, encoding="utf-8")
                    lines = sum(1 for a, b in zip(orig.splitlines(), text.splitlines()) if a != b)
                    print(f"  CHANGED: {fp.relative_to(ROOT)} ({lines} lines)")
                    total_files += 1
                    total_lines += lines
                except Exception as e:
                    print(f"  ERROR: {fp}: {e}")
    print(f"Text refs: {total_files} files, {total_lines} lines updated")


def main():
    print("=== Phase 1: Rename files ===")
    actually_renamed = []
    for old_rel, new_rel in RENAMES:
        if rename_file(old_rel, new_rel):
            actually_renamed.append((old_rel, new_rel))

    print(f"\n=== Phase 2: Update harness.rs ===")
    update_harness(RENAMES)  # Use all renames (even skipped ones need path updates)

    print(f"\n=== Phase 3: Update text references ===")
    update_text_references(RENAMES)

    print(f"\nDone. {len(actually_renamed)} files renamed.")


if __name__ == "__main__":
    main()

