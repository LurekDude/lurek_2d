"""Manual patching of all 18 remaining."""
import os

replacements = {
    "src/lua_api/ai_api.rs": ("lurek.set(\"ai\"", '/// Provides comprehensive artificial intelligence routines and types.\n    lurek.set("ai"'),
    "src/lua_api/automation_api.rs": ("lurek.set(\"automation\"", '/// Provides automation scripts playback for tests.\n    lurek.set("automation"'),
    "src/lua_api/camera_api.rs": ('"newCamera",', '/// Creates a new camera object to view the game world.\n        "newCamera",'),
    "src/lua_api/data_api.rs": ('"newByteData",', '/// Instantiates a raw byte data container object.\n        "newByteData",'),
    "src/lua_api/input_api.rs": ("lurek.set(\"input\"", '/// Provides input handling devices and event streams.\n    lurek.set("input"'),
    "src/lua_api/minimap_api.rs": ("lurek.set(\"minimap\"", '/// Provides minimap rendering and overlay functionalities.\n    lurek.set("minimap"'),
    "src/lua_api/mods_api.rs": ("lurek.set(\"mods\"", '/// Provides features for discovering and configuring game modifications.\n    lurek.set("mods"'),
    "src/lua_api/particle_api.rs": ("lurek.set(\"particle\"", '/// Provides high performance particle emission rendering and updating.\n    lurek.set("particle"'),
    "src/lua_api/pipeline_api.rs": ("lurek.set(\"pipeline\"", '/// Provides pipeline task scheduling and sequencing workflows.\n    lurek.set("pipeline"'),
    "src/lua_api/raycaster_api.rs": ("lurek.set(\"raycaster\"", '/// Provides raycast intersections and 2.5D visual rendering.\n    lurek.set("raycaster"'),
    "src/lua_api/render_api.rs": ("lurek.set(\"graphic\"", '/// Provides graphic rendering interfaces for sprites, primitives, and buffers.\n    lurek.set("graphic"'),
    "src/lua_api/save_api.rs": ("lurek.set(\"save\"", '/// Provides read and write access for local save game persistence.\n    lurek.set("save"'),
    "src/lua_api/scene_api.rs": ("lurek.set(\"scene\"", '/// Provides scene lifecycle flow execution and state.\n    lurek.set("scene"'),
    "src/lua_api/serial_api.rs": ("lurek.set(\"serial\"", '/// Provides serialization primitives and configuration parsers.\n    lurek.set("serial"'),
    "src/lua_api/thread_api.rs": ("lurek.set(\"thread\"", '/// Provides background processing loops with message channels.\n    lurek.set("thread"'),
    "src/lua_api/tilemap_api.rs": ("lurek.set(\"tilemap\"", '/// Provides tile based level chunks, layouts and rendering.\n    lurek.set("tilemap"'),
    "src/lua_api/timer_api.rs": ("lurek.set(\"timer\"", '/// Provides frame rate independent time, delta time, and schedulers.\n    lurek.set("timer"'),
    "src/lua_api/window_api.rs": ("lurek.set(\"window\"", '/// Provides platform window controls, styling and displays.\n    lurek.set("window"')
}

for path, (target, replace) in replacements.items():
    if not os.path.exists(path):
        continue
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    # remove old added things so we don't duplicate
    text = text.replace('/// Namespace containing the ai API module.\n\n', '')
    text = text.replace('/// Namespace containing the ai API module.\n', '')
    # Just replace target exactly with the new version
    text = text.replace(target, replace)

    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
