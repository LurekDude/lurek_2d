#!/usr/bin/env python3
"""
gen_docs_lua.py -- Generate Lua API reference from docs/logs/lua_api_data.json.

Each function/method is rendered in a Lua code block:
    name( param : type, optional : type? ) -> ReturnType  -- description

Usage:
    python tools/gen_docs_lua.py                   # -> docs/API/lua-api.md
    python tools/gen_docs_lua.py --output FILE
    python tools/gen_docs_lua.py --check           # coverage check only
"""
import argparse, json, re, sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
INPUT_FILE  = WORKSPACE_ROOT / "docs" / "logs" / "lua_api_data.json"
OUTPUT_FILE = WORKSPACE_ROOT / "docs" / "API" / "lua-api.md"

_MODULE_ORDER = [
    "graphics","graphics_ext","window","input","timer","math","math_ext",
    "audio","physics","filesystem","particle","event","system","thread",
    "ai","compute","dataframe","data","image","sound","graph","tilemap",
    "dialog","entity","scene","pathfinding","postfx",
    "minimap","savegame","modding","localization",
    "stats","inventory","crafting","cardgame","combat",
    "log","debug","battle","debugbridge","docs","item","patterns","quest","resource",
]

# Maps the internal json/module key → actual registered Lua namespace.
# These modules register under a different name than their source folder.
_LUA_NAMESPACE = {
    "timer":      "time",       # luna.time.* (registered as "time" in timer_api.rs)
    "event":      "signal",     # luna.signal.* (registered as "signal" in event_api.rs)
    "automation": "simulator",  # luna.simulator.* (registered as "simulator" in automation_api.rs)
}


def _parse_params(params_doc, inferred_sig):
    """Return list of (name, type, is_optional) from params_doc + inferred_sig."""
    sig_inner = re.sub(r"^\(|\)$", "", (inferred_sig or "").strip())
    sig_parts = []
    for token in re.split(r",\s*", sig_inner):
        token = token.strip()
        if not token:
            continue
        is_opt = token.startswith("[") or token.endswith("]")
        sig_parts.append((token.strip("[] "), is_opt))

    type_map = {}
    for line in (params_doc or "").split("\n"):
        # Only extract type when it is explicitly backtick-enclosed: `name` — `Type`: desc
        m = re.match(r"\s*-\s*`?([a-zA-Z_]\w*)`?\s*[\u2014\u2013-]+\s*`([A-Za-z][A-Za-z0-9_?]*)`", line)
        if m:
            type_map[m.group(1)] = m.group(2).rstrip("?")

    return [(n, type_map.get(n, ""), o) for n, o in sig_parts]


def _parse_return_type(returns_doc):
    """Extract return type from returns_doc.

    Only returns a type when it is clearly a type name, not prose.
    Priority: backtick-enclosed type at start (`Type` -- ...) or `Type: description`.
    """
    if not returns_doc:
        return ""
    first = returns_doc.strip().split("\n")[0].strip()

    # Pattern 1: starts with backtick-type: `Type` or `Type` -- desc
    m = re.match(r"`([A-Za-z][A-Za-z0-9_?]*)`", first)
    if m:
        t = m.group(1)
        # Exclude prose words and Lua primitives that are usually values, not types
        if t.lower() not in ("the","a","an","this","true","false","nil","none","it"):
            return t

    # Pattern 2: CamelCase type name at start: TypeName -- desc or TypeName: ...
    m = re.match(r"^([A-Z][A-Za-z0-9]+)(?:\s*[\u2014\u2013:-]|\s*$)", first)
    if m:
        t = m.group(1)
        # Must look like a type (CamelCase or known primitives), not a sentence start
        return t

    return ""


def _build_call(fn, prefix):
    """Return (call_str, desc) for one function/method entry."""
    desc = (fn.get("description", "") or "").rstrip(".")

    # Prefer explicitly typed params from @param docstring tags
    typed = fn.get("typed_params")  # None = field absent (old data), [] = no params
    if typed is not None:
        parts = []
        for item in typed:
            name, lua_type = item[0], item[1]
            part = f"{name} : {lua_type}" if lua_type else name
            parts.append(part)
        args = "( " + ", ".join(parts) + " )" if parts else "()"
    else:
        # Legacy fallback: use inferred_sig param names + params_doc types
        params = _parse_params(fn.get("params_doc", ""), fn.get("inferred_sig", "()"))
        parts = []
        for name, typ, is_opt in params:
            part = f"{name} : {typ}" if typ else name
            parts.append(part)
        args = "( " + ", ".join(parts) + " )" if parts else "()"

    # Return type: prefer inferred_return, fall back to returns_doc
    ret = fn.get("inferred_return") or _parse_return_type(fn.get("returns_doc", ""))

    # Suppress uninformative "any" — try to infer from function name or omit entirely
    if ret == "any":
        fn_name = fn.get("name", "")
        if fn_name.startswith("new") and len(fn_name) > 3 and fn_name[3].isupper():
            # e.g. newImage -> Image, newBody -> Body, newWorld -> World
            ret = fn_name[3:]
        else:
            ret = ""

    call = f"{prefix}{args}"
    if ret:
        call += f" -> {ret}"
    return call, desc


def _code_block(entries):
    """entries = [(call_str, desc)] -> ```lua ... ``` lines."""
    if not entries:
        return []
    lines = []
    for call, desc in entries:
        if desc:
            lines.append(f"{call}  -- {desc}")
        else:
            lines.append(call)
    return ["```lua"] + lines + ["```"]


def _callbacks():
    CB = [
        ("function luna.load()",                                                   "Called once after the script is loaded."),
        ("function luna.update( dt : number )",                                    "Called every frame; dt = elapsed seconds."),
        ("function luna.draw()",                                                   "Called every frame for rendering."),
        ("function luna.keypressed( key : string, scancode : string, isrepeat : boolean )", "Key press event."),
        ("function luna.keyreleased( key : string, scancode : string )",           "Key release event."),
        ("function luna.textinput( text : string )",                               "Unicode character typed."),
        ("function luna.mousepressed( x : number, y : number, button : number )", "Mouse button press."),
        ("function luna.mousereleased( x : number, y : number, button : number )","Mouse button release."),
        ("function luna.wheelmoved( x : number, y : number )",                    "Mouse wheel scroll."),
        ("function luna.gamepadpressed( id : number, button : string )",          "Gamepad button press."),
        ("function luna.gamepadreleased( id : number, button : string )",         "Gamepad button release."),
        ("function luna.gamepadaxis( id : number, axis : string, value : number )","Gamepad axis; value in -1..1."),
        ("function luna.joystickadded( id : number )",                            "Gamepad connected."),
        ("function luna.joystickremoved( id : number )",                          "Gamepad disconnected."),
        ("function luna.touchpressed( id, x : number, y : number, dx : number, dy : number, pressure : number )", "Touch begin."),
        ("function luna.touchmoved(  id, x : number, y : number, dx : number, dy : number, pressure : number )", "Touch move."),
        ("function luna.touchreleased(id, x : number, y : number, dx : number, dy : number, pressure : number )", "Touch end."),
        ("function luna.focus( focused : boolean )",                              "Window focus change."),
        ("function luna.visible( visible : boolean )",                            "Window show/hide."),
        ("function luna.resize( w : number, h : number )",                        "Window resized."),
        ("function luna.quit()",                                                   "Return true to cancel quit."),
        ("function luna.errorhandler( msg : string )",                            "Unhandled Lua error."),
    ]
    out = ["## Callbacks","",
           "All callbacks are optional. Define any in `main.lua` and the engine calls them automatically.",
           ""]
    return out + _code_block(CB)


def _render_module(mod_name, mod_data):
    lua_ns = _LUA_NAMESPACE.get(mod_name, mod_name)
    out = []
    anchor = mod_name.replace("_","-")
    out.append(f"## `luna.{lua_ns}` {{#{anchor}}}")
    out.append("")
    desc = (mod_data.get("description","") or "").strip()
    if desc:
        for i, para in enumerate(desc.split("\n\n")[:2]):
            if i: out.append(">")
            for line in para.strip().splitlines():
                out.append(f"> {line}" if line.strip() else ">")
        out.append("")

    fns = mod_data.get("functions",[])
    cls = mod_data.get("classes",{})

    # Per-module coverage stat
    all_items = list(fns)
    for cls_data in cls.values():
        all_items += cls_data.get("methods", [])
    n_total = len(all_items)
    n_documented = sum(1 for it in all_items if (it.get("description","") or "").strip())
    if n_total:
        mod_pct = round(n_documented / n_total * 100)
        out.append(f"*Coverage: {n_documented}/{n_total} items documented ({mod_pct}%)*")
        out.append("")

    if fns:
        entries = [_build_call(fn, f"luna.{lua_ns}.{fn['name']}") for fn in sorted(fns, key=lambda f:f["name"])]
        out += _code_block(entries)
        out.append("")

    for cls_name, cls_data in sorted(cls.items()):
        out.append(f"### `{cls_name}`")
        out.append("")
        cd = (cls_data.get("description", "") or "").strip()
        if cd:
            # Show first sentence of the class description
            first_line = cd.split("\n")[0].strip()
            # Clean up "Lua-facing `X` userdata" boilerplate to something readable
            first_line = re.sub(r"Lua-facing `[^`]+` userdata[., ]*", "", first_line).strip()
            if first_line:
                out.append(first_line)
                out.append("")
            else:
                # Keep original if stripping left nothing useful
                out.append(cd.split("\n")[0].strip())
                out.append("")
        methods = cls_data.get("methods",[])
        if methods:
            entries = [_build_call(m, f"{cls_name}:{m['name']}") for m in sorted(methods, key=lambda f:f["name"])]
            out += _code_block(entries)
            out.append("")
    return out


def generate(data):
    mods = data["lua_api"]["modules"]
    s    = data["lua_api"]["summary"]
    gen  = data["meta"]["generated"][:10]
    ver  = data["meta"]["version"]

    seen, ordered = set(), []
    for m in _MODULE_ORDER:
        if m in mods: seen.add(m); ordered.append(m)
    for m in sorted(mods):
        if m not in seen: ordered.append(m)

    out = []
    out += ["# Luna2D Lua API Reference","",
            f"*Auto-generated by `tools/gen_docs_lua.py`. Version: `{ver}` | Generated: {gen}*",
            f"*Coverage: {s['documented']}/{s['total_functions']} functions documented ({s['coverage_pct']}%)*",
            "","---","","## Contents",""]

    for m in ordered:
        anchor = m.replace("_","-")
        lua_ns = _LUA_NAMESPACE.get(m, m)
        n_fns = len(mods[m].get("functions",[]))
        n_cls = len(mods[m].get("classes",{}))
        parts = ([f"{n_fns} fn"] if n_fns else []) + ([f"{n_cls} class{'es' if n_cls!=1 else ''}"] if n_cls else [])
        suffix = " \u2014 " + ", ".join(parts) if parts else ""
        out.append(f"- [`luna.{lua_ns}`](#{anchor}){suffix}")

    out += ["","---",""]
    out += _callbacks()
    out += ["","---",""]

    for m in ordered:
        out += _render_module(m, mods[m])
        out += ["---",""]

    out.append("*Generated by `tools/gen_docs_lua.py`. Do not edit by hand.*")
    return "\n".join(out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--input",  default=str(INPUT_FILE))
    p.add_argument("--output", default=str(OUTPUT_FILE))
    p.add_argument("--check",  action="store_true")
    args = p.parse_args()

    inp = Path(args.input)
    if not inp.exists():
        print(f"[ERROR] Not found: {inp}\nRun python tools/gen_api_data.py first.", file=sys.stderr)
        return 1

    data = json.loads(inp.read_text(encoding="utf-8"))

    if args.check:
        s = data["lua_api"]["summary"]
        print(f"Coverage: {s['documented']}/{s['total_functions']} ({s['coverage_pct']}%)")
        return 0 if s["coverage_pct"] >= 80 else 1

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    content = generate(data)
    out.write_text(content, encoding="utf-8")
    print(f"[OK] Generated {out} ({content.count(chr(10))} lines)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
