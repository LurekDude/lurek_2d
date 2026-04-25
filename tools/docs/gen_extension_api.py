"""
gen_extension_api.py -- Convert logs/data/lua_api_data.json to
extensions/vscode/data/lurek-api.json for the VS Code IntelliSense extension.

Input:
    logs/data/lua_api_data.json   (produced by gen_lua_api_data.py, step 2 of gen_all_docs.py)

Output:
    extensions/vscode/data/lurek-api.json

Run this script whenever the Lurek API changes, or let gen_all_docs.py call it automatically:
    python tools/docs/gen_extension_api.py

The extension reads ONLY from the output JSON -- no runtime parsing of Rust or Lua source,
no hardcoded module/function names in the TypeScript extension code.

Usage:
    python tools/docs/gen_extension_api.py [--input PATH] [--output PATH] [--verbose]
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import date

# Engine callbacks (game script slot functions).
# Stable Lurek contracts -- not extracted from source.
CALLBACKS: list[dict] = [
    {"name": "load", "signature": "function lurek.load()", "description": "Called once after the game script is loaded.", "parameters": []},
    {"name": "update", "signature": "function lurek.update(dt)", "description": "Called every frame. `dt` is elapsed seconds.", "parameters": [{"name": "dt", "type": "number", "description": "Delta time in seconds", "optional": False}]},
    {"name": "draw", "signature": "function lurek.draw()", "description": "Called every frame for rendering. All draw calls must happen here.", "parameters": []},
    {"name": "keypressed", "signature": "function lurek.keypressed(key)", "description": "Called when a keyboard key is pressed.", "parameters": [{"name": "key", "type": "string", "description": "Key name", "optional": False}]},
    {"name": "keyreleased", "signature": "function lurek.keyreleased(key)", "description": "Called when a keyboard key is released.", "parameters": [{"name": "key", "type": "string", "description": "Key name", "optional": False}]},
    {"name": "textinput", "signature": "function lurek.textinput(text)", "description": "Called when text input is received.", "parameters": [{"name": "text", "type": "string", "description": "Input character(s)", "optional": False}]},
    {"name": "mousepressed", "signature": "function lurek.mousepressed(x, y, button)", "description": "Called when a mouse button is pressed.", "parameters": [{"name": "x", "type": "number", "description": "Mouse X", "optional": False}, {"name": "y", "type": "number", "description": "Mouse Y", "optional": False}, {"name": "button", "type": "number", "description": "Button index (1=left, 2=right, 3=middle)", "optional": False}]},
    {"name": "mousereleased", "signature": "function lurek.mousereleased(x, y, button)", "description": "Called when a mouse button is released.", "parameters": [{"name": "x", "type": "number", "description": "Mouse X", "optional": False}, {"name": "y", "type": "number", "description": "Mouse Y", "optional": False}, {"name": "button", "type": "number", "description": "Button index", "optional": False}]},
    {"name": "mousemoved", "signature": "function lurek.mousemoved(x, y, dx, dy)", "description": "Called when the mouse cursor moves.", "parameters": [{"name": "x", "type": "number", "description": "X", "optional": False}, {"name": "y", "type": "number", "description": "Y", "optional": False}, {"name": "dx", "type": "number", "description": "X delta", "optional": False}, {"name": "dy", "type": "number", "description": "Y delta", "optional": False}]},
    {"name": "wheelmoved", "signature": "function lurek.wheelmoved(x, y)", "description": "Called on mouse wheel scroll.", "parameters": [{"name": "x", "type": "number", "description": "Horizontal scroll", "optional": False}, {"name": "y", "type": "number", "description": "Vertical scroll", "optional": False}]},
    {"name": "gamepadpressed", "signature": "function lurek.gamepadpressed(id, button)", "description": "Called when a gamepad button is pressed.", "parameters": [{"name": "id", "type": "number", "description": "Gamepad ID", "optional": False}, {"name": "button", "type": "string", "description": "Button name", "optional": False}]},
    {"name": "gamepadreleased", "signature": "function lurek.gamepadreleased(id, button)", "description": "Called when a gamepad button is released.", "parameters": [{"name": "id", "type": "number", "description": "Gamepad ID", "optional": False}, {"name": "button", "type": "string", "description": "Button name", "optional": False}]},
    {"name": "gamepadaxis", "signature": "function lurek.gamepadaxis(id, axis, value)", "description": "Called when a gamepad axis changes.", "parameters": [{"name": "id", "type": "number", "description": "Gamepad ID", "optional": False}, {"name": "axis", "type": "string", "description": "Axis name", "optional": False}, {"name": "value", "type": "number", "description": "Axis value", "optional": False}]},
    {"name": "joystickadded", "signature": "function lurek.joystickadded(id)", "description": "Called when a gamepad is connected.", "parameters": [{"name": "id", "type": "number", "description": "Device ID", "optional": False}]},
    {"name": "joystickremoved", "signature": "function lurek.joystickremoved(id)", "description": "Called when a gamepad is disconnected.", "parameters": [{"name": "id", "type": "number", "description": "Device ID", "optional": False}]},
    {"name": "focus", "signature": "function lurek.focus(has_focus)", "description": "Called when window gains or loses focus.", "parameters": [{"name": "has_focus", "type": "boolean", "description": "True if focused", "optional": False}]},
    {"name": "visible", "signature": "function lurek.visible(is_visible)", "description": "Called when window visibility changes.", "parameters": [{"name": "is_visible", "type": "boolean", "description": "True if visible", "optional": False}]},
    {"name": "resize", "signature": "function lurek.resize(w, h)", "description": "Called when the window is resized.", "parameters": [{"name": "w", "type": "number", "description": "New width", "optional": False}, {"name": "h", "type": "number", "description": "New height", "optional": False}]},
    {"name": "quit", "signature": "function lurek.quit()", "description": "Called when the window is about to close. Return true to cancel.", "parameters": []},
    {"name": "init", "signature": "function lurek.init()", "description": "Called once when the engine initialises, before the first frame.", "parameters": []},
    {"name": "ready", "signature": "function lurek.ready()", "description": "Called once after init, when the window and GPU are ready.", "parameters": []},
    {"name": "process", "signature": "function lurek.process(dt)", "description": "Called every frame for game logic. `dt` is elapsed seconds.", "parameters": [{"name": "dt", "type": "number", "description": "Delta time in seconds", "optional": False}]},
    {"name": "process_late", "signature": "function lurek.process_late(dt)", "description": "Called every frame after process, for late updates (camera follow, etc).", "parameters": [{"name": "dt", "type": "number", "description": "Delta time in seconds", "optional": False}]},
    {"name": "process_physics", "signature": "function lurek.process_physics(dt)", "description": "Called at fixed physics timestep rate.", "parameters": [{"name": "dt", "type": "number", "description": "Fixed delta time", "optional": False}]},
    {"name": "fixedUpdate", "signature": "function lurek.fixedUpdate(dt)", "description": "Alias for process_physics — called at fixed timestep rate.", "parameters": [{"name": "dt", "type": "number", "description": "Fixed delta time", "optional": False}]},
    {"name": "draw_ui", "signature": "function lurek.draw_ui()", "description": "Called every frame after draw, for UI overlay rendering.", "parameters": []},
    {"name": "exit", "signature": "function lurek.exit()", "description": "Called when the engine is shutting down, after quit.", "parameters": []},
    {"name": "touchpressed", "signature": "function lurek.touchpressed(id, x, y, dx, dy, pressure)", "description": "Called when a touch begins.", "parameters": [{"name": "id", "type": "number", "description": "Touch ID", "optional": False}, {"name": "x", "type": "number", "description": "X", "optional": False}, {"name": "y", "type": "number", "description": "Y", "optional": False}, {"name": "dx", "type": "number", "description": "X delta", "optional": False}, {"name": "dy", "type": "number", "description": "Y delta", "optional": False}, {"name": "pressure", "type": "number", "description": "Pressure", "optional": False}]},
    {"name": "touchmoved", "signature": "function lurek.touchmoved(id, x, y, dx, dy, pressure)", "description": "Called when a touch point moves.", "parameters": [{"name": "id", "type": "number", "description": "Touch ID", "optional": False}, {"name": "x", "type": "number", "description": "X", "optional": False}, {"name": "y", "type": "number", "description": "Y", "optional": False}, {"name": "dx", "type": "number", "description": "X delta", "optional": False}, {"name": "dy", "type": "number", "description": "Y delta", "optional": False}, {"name": "pressure", "type": "number", "description": "Pressure", "optional": False}]},
    {"name": "touchreleased", "signature": "function lurek.touchreleased(id, x, y, dx, dy, pressure)", "description": "Called when a touch ends.", "parameters": [{"name": "id", "type": "number", "description": "Touch ID", "optional": False}, {"name": "x", "type": "number", "description": "X", "optional": False}, {"name": "y", "type": "number", "description": "Y", "optional": False}, {"name": "dx", "type": "number", "description": "X delta", "optional": False}, {"name": "dy", "type": "number", "description": "Y delta", "optional": False}, {"name": "pressure", "type": "number", "description": "Pressure", "optional": False}]},
    {"name": "textedited", "signature": "function lurek.textedited(text, start, length)", "description": "Called when IME composition text changes.", "parameters": [{"name": "text", "type": "string", "description": "Composition text", "optional": False}, {"name": "start", "type": "number", "description": "Cursor start", "optional": False}, {"name": "length", "type": "number", "description": "Selection length", "optional": False}]},
]

KEY_NAMES: list[str] = [
    "space", "return", "escape", "backspace", "tab", "delete", "insert",
    "home", "end", "pageup", "pagedown",
    "up", "down", "left", "right",
    "a","b","c","d","e","f","g","h","i","j","k","l","m",
    "n","o","p","q","r","s","t","u","v","w","x","y","z",
    "0","1","2","3","4","5","6","7","8","9",
    "kp0","kp1","kp2","kp3","kp4","kp5","kp6","kp7","kp8","kp9",
    "kpperiod","kpdivide","kpmultiply","kpminus","kpplus","kpenter","kpequals",
    "f1","f2","f3","f4","f5","f6","f7","f8","f9","f10","f11","f12",
    "lshift","rshift","lctrl","rctrl","lalt","ralt","lgui","rgui",
    "capslock","scrolllock","numlock","printscreen","pause",
    "semicolon","equals","comma","minus","period","slash",
    "backquote","leftbracket","backslash","rightbracket","quote",
]

GAMEPAD_BUTTONS: list[str] = [
    "a","b","x","y","back","start","guide",
    "leftshoulder","rightshoulder","lefttrigger","righttrigger",
    "leftstick","rightstick","dpup","dpdown","dpleft","dpright",
]

GAMEPAD_AXES: list[str] = [
    "leftx","lefty","rightx","righty","triggerleft","triggerright",
]

# Enum string values for common "mode" parameters.
# Kept in the script (not hardcoded in TypeScript) so they update with each release.
BUILTIN_ENUMS: dict[str, list[str]] = {
    "DrawMode":       ["fill", "line"],
    "BlendMode":      ["alpha", "add", "subtract", "multiply", "replace", "screen", "none"],
    "FilterMode":     ["nearest", "linear"],
    "WrapMode":       ["clamp", "repeat", "mirroredrepeat", "clampzero"],
    "AlignMode":      ["left", "center", "right", "justify"],
    "LineJoin":       ["miter", "bevel", "none"],
    "LineCap":        ["butt", "square", "none"],
    "ArcType":        ["pie", "open", "closed"],
    "BodyType":       ["static", "dynamic", "kinematic"],
    "JointType":      ["revolute", "prismatic", "distance", "weld", "friction", "motor", "rope", "pulley", "gear", "mouse"],
    "EasingFunction": ["linear", "quadIn", "quadOut", "quadInOut", "cubicIn", "cubicOut", "cubicInOut",
                       "sineIn", "sineOut", "sineInOut", "elasticIn", "elasticOut", "elasticInOut",
                       "bounceIn", "bounceOut", "bounceInOut", "backIn", "backOut", "backInOut"],
    "SourceType":     ["static", "stream", "queue"],
}


def _build_signature(full_path: str, params: list[dict]) -> str:
    parts = [f"[{p['name']}]" if p.get("optional") else p["name"] for p in params]
    return f"{full_path}({', '.join(parts)})"


def _convert_function(raw: dict) -> dict:
    """Convert one function entry from lua_api_data.json to the extension schema."""
    is_method = raw.get("kind", "function") == "method"
    full_path = raw.get("lua_name", raw["name"])
    owner = raw.get("owner_type") or None

    params: list[dict] = []
    for tp in raw.get("typed_params", []):
        pname = (tp[0] if tp else "arg").rstrip("?")
        ptype = (tp[1] if len(tp) > 1 else "any").rstrip("?")
        optional = bool(tp[2]) if len(tp) > 2 else False
        params.append({"name": pname, "type": ptype, "description": "", "optional": optional})

    ret = raw.get("inferred_return") or "nil"
    sig = raw.get("inferred_sig") or _build_signature(full_path, params)

    return {
        "name": raw["name"],
        "fullPath": full_path,
        "signature": sig,
        "description": raw.get("description", ""),
        "parameters": params,
        "returns": ret,
        "returnType": ret,
        "isMethod": is_method,
        "objectType": owner,
    }


def convert(data: dict, verbose: bool = False) -> dict:
    """Convert lua_api_data.json content to the extension-ready dict."""
    api_root = data.get("lua_api", data)
    raw_modules: dict = api_root.get("modules", {})

    modules_out: list[dict] = []
    classes_out: dict[str, dict] = {}

    for mod_name, mod_data in sorted(raw_modules.items()):
        functions: list[dict] = []
        for raw_fn in mod_data.get("functions", []):
            fn = _convert_function(raw_fn)
            if fn["isMethod"] and fn["objectType"]:
                cls = fn["objectType"]
                if cls not in classes_out:
                    classes_out[cls] = {"name": cls, "description": "", "methods": []}
                classes_out[cls]["methods"].append(fn)
            else:
                functions.append(fn)

        # Also extract methods from the classes dict (lua_api_data.json stores methods
        # under mod_data["classes"][ClassName]["methods"], not in mod_data["functions"]).
        for class_name, class_data in mod_data.get("classes", {}).items():
            cls_desc = class_data.get("description", "")
            if class_name not in classes_out:
                classes_out[class_name] = {"name": class_name, "description": cls_desc, "methods": []}
            elif cls_desc and not classes_out[class_name]["description"]:
                classes_out[class_name]["description"] = cls_desc
            for raw_method in class_data.get("methods", []):
                fn = _convert_function(raw_method)
                classes_out[class_name]["methods"].append(fn)

        modules_out.append({
            "name": mod_name,
            "description": mod_data.get("description", ""),
            "functions": functions,
            "methods": [],
        })

    if verbose:
        total_fn  = sum(len(m["functions"]) for m in modules_out)
        total_mth = sum(len(c["methods"]) for c in classes_out.values())
        print(f"  Modules   : {len(modules_out)}")
        print(f"  Classes   : {len(classes_out)}")
        print(f"  Functions : {total_fn}")
        print(f"  Methods   : {total_mth}")

    return {
        "version": "auto-generated",
        "generated": str(date.today()),
        "modules": modules_out,
        "classes": sorted(classes_out.values(), key=lambda c: c["name"]),
        "enums": BUILTIN_ENUMS,
        "callbacks": CALLBACKS,
        "keyNames": KEY_NAMES,
        "gamepadButtons": GAMEPAD_BUTTONS,
        "gamepadAxes": GAMEPAD_AXES,
    }


def main() -> int:
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    parser = argparse.ArgumentParser(
        description="Convert logs/data/lua_api_data.json -> extensions/vscode/data/lurek-api.json."
    )
    parser.add_argument("--input",   default=os.path.join(repo_root, "logs", "data", "lua_api_data.json"))
    parser.add_argument("--output",  default=os.path.join(repo_root, "extensions", "vscode", "data", "lurek-api.json"))
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f"ERROR: {args.input} not found. Run `python tools/gen_all_docs.py` first.", file=sys.stderr)
        return 1

    print(f"Reading  {args.input} ...")
    with open(args.input, encoding="utf-8") as fh:
        raw_data = json.load(fh)

    print("Converting ...")
    output = convert(raw_data, verbose=args.verbose)

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    print(f"Writing  {args.output} ...")
    with open(args.output, "w", encoding="utf-8") as fh:
        json.dump(output, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    n_mod = len(output["modules"])
    n_cls = len(output["classes"])
    n_fn  = sum(len(m["functions"]) for m in output["modules"])
    n_mth = sum(len(c["methods"]) for c in output["classes"])
    size_kb = os.path.getsize(args.output) // 1024
    print(f"Done. {n_mod} modules, {n_cls} classes, {n_fn} functions, {n_mth} methods -- {size_kb} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
