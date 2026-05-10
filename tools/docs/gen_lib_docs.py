#!/usr/bin/env python3
"""gen_lib_docs.py — Generate Markdown API docs from Lurek2D library Lua files.

Scans ``content/library/**/init.lua`` for LDoc-style docstrings and emits:

* a single aggregate index at ``docs/library/lunasome.md`` (mirrors the
  layout of ``docs/api/lurek.md``)

LDoc tags recognised (see work/library-overhaul-20260418/reports/P6_doc_generator_spec.md):

* ``@module name``                    – module title
* ``@status full|partial|stub|proxy`` – implementation status badge
* ``@deprecated <text>``              – deprecation note (rendered alongside status)
* ``@local``                          – skip the function entirely
* ``@param name type description``    – function parameter
* ``@tparam type name description``   – LDoc-typed parameter (alias of @param)
* ``@treturn type description``       – typed return value
* ``@return description``             – untyped return value
* ``@field name type description``    – module/table field
* ``@usage``                          – followed by indented Lua code lines
* ``@see lurek.<ns>.<fn>``            – cross-link into ``docs/api/lurek.md``
* ``@see library.<name>.<fn>``        – cross-link into ``lunasome.md``
* ``@raise description``              – raised-error description
* ``@within section``                 – grouping label inside the module

Usage:
    python tools/docs/gen_lib_docs.py                  # generate docs/library/lunasome.md
    python tools/docs/gen_lib_docs.py --module dialog  # generate aggregate from one library
    python tools/docs/gen_lib_docs.py --check          # validate, exit 1 on errors
    python tools/docs/gen_lib_docs.py --no-aggregate   # skip lunasome.md
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# ── Configuration ─────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
LIB_DIR = REPO_ROOT / "library"
AGGREGATE_PATH = REPO_ROOT / "docs" / "library" / "lunasome.md"

VALID_STATUS = {"full", "partial", "stub", "proxy"}

# Runtime ``lurek.*`` namespaces (see P1 map). Used by ``--check`` to flag
# ``@see`` targets that point at a namespace that does not exist.
LUREK_NAMESPACES = {
    # P1 runtime-name shifts
    "img", "codec", "save", "time", "ecs", "mods", "fs",
    "pathfind", "postfx", "particles", "graphic", "i18n",
    "platform",
    # already-stable namespaces
    "audio", "window", "input", "math", "physics", "signal", "thread",
    "ai", "compute", "dataframe", "data", "graph", "tilemap", "scene",
    "minimap", "log", "debugbridge", "docs", "patterns", "animation",
    "simulator", "camera", "collision", "devtools", "effect", "engine",
    "light", "network", "parallax", "pipeline", "procgen", "raycaster",
    "spine", "sprite", "terminal", "tween", "ui", "automation",
    # legacy doc names still appearing in lua-api.md anchors
    "image", "save", "serial", "ecs", "mods", "filesystem", "pathfind",
    "render", "particle", "i18n", "system", "timer", "gfx", "keyboard",
    "mouse", "gamepad", "touch", "event",
}

# ── LDoc parser ───────────────────────────────────────────────────────────────


def _new_module_info() -> dict:
    return {
        "name": "",
        "description": "",
        "status": "",
        "deprecated": "",
        "fields": [],       # [{name,type,desc}]
        "see": [],          # [str]
        "functions": [],    # [function dict]
    }


def _new_function() -> dict:
    return {
        "name": "",
        "args": "",
        "desc": "",
        "params": [],     # [{name,type,desc}]
        "returns": [],    # [{type,desc}] (type may be empty for @return)
        "fields": [],     # [{name,type,desc}]
        "see": [],
        "raises": [],
        "usage": [],
        "within": "",
        "status": "",
        "deprecated": "",
        "decl_line": 0,   # source line of the `function ...` declaration
    }


_FUNC_RE = re.compile(r"^\s*function\s+([\w.:]+)\s*\((.*?)\)")
_M_ASSIGN_RE = re.compile(r"^\s*M\.([A-Za-z_][\w]*)\s*=")


def parse_ldoc(source: str) -> dict:
    """Parse a Lua source string and return the module info dict."""
    info = _new_module_info()
    lines = source.splitlines()
    n = len(lines)

    def peek_block(start: int) -> tuple[list[str], int]:
        block: list[str] = []
        j = start
        while j < n:
            s = lines[j].strip()
            if s.startswith("---"):
                block.append(s[3:].strip())
                j += 1
            elif s.startswith("--"):
                block.append(s[2:].strip())
                j += 1
            else:
                break
        return block, j

    def parse_function_block(block: list[str], func_line: str, decl_line: int) -> dict | None:
        m = _FUNC_RE.match(func_line)
        if not m:
            return None
        if any(b.strip() == "@local" for b in block):
            return None
        fn = _new_function()
        fn["name"] = m.group(1)
        fn["args"] = m.group(2)
        fn["decl_line"] = decl_line
        _consume_tags(block, fn)
        return fn

    # First pass: find the FIRST block carrying ``@module`` (or fall back to
    # the very first comment block in the file). Treat that as module-level.
    found_module_block = False
    i = 0
    while i < n:
        s = lines[i].strip()
        if s.startswith("---") or s.startswith("--"):
            block, end_i = peek_block(i)
            looks_like_func = end_i < n and bool(_FUNC_RE.match(lines[end_i].strip() or ""))
            has_module_tag = any(b.startswith("@module") for b in block)
            if has_module_tag or (i == 0 and not looks_like_func and not found_module_block):
                _consume_module_tags(block, info)
                found_module_block = True
                if has_module_tag:
                    break
                i = end_i
                continue
            # Skip past this block; it's a function block we'll parse below.
            i = end_i
            continue
        i += 1

    # Second pass: walk the file, emitting one function per `--- ... function`.
    i = 0
    while i < n:
        s = lines[i].strip()
        if s.startswith("---") or s.startswith("--"):
            block, end_i = peek_block(i)
            if end_i < n:
                func_line = lines[end_i].strip()
                if _FUNC_RE.match(func_line):
                    fn = parse_function_block(block, func_line, end_i + 1)
                    if fn:
                        info["functions"].append(fn)
                    i = end_i + 1
                    continue
            i = end_i
            continue
        i += 1

    return info


def _consume_module_tags(block: list[str], info: dict) -> None:
    desc: list[str] = []
    in_usage = False
    usage: list[str] = []
    for raw in block:
        if in_usage:
            if raw.startswith("@"):
                in_usage = False
            else:
                usage.append(raw)
                continue
        if raw.startswith("@module"):
            parts = raw.split(None, 1)
            if len(parts) > 1:
                info["name"] = parts[1].strip()
        elif raw.startswith("@status"):
            parts = raw.split(None, 1)
            if len(parts) > 1:
                info["status"] = parts[1].strip()
        elif raw.startswith("@deprecated"):
            parts = raw.split(None, 1)
            info["deprecated"] = parts[1].strip() if len(parts) > 1 else "true"
        elif raw.startswith("@field"):
            f = _parse_field(raw)
            if f:
                info["fields"].append(f)
        elif raw.startswith("@see"):
            parts = raw.split(None, 1)
            if len(parts) > 1:
                info["see"].append(parts[1].strip())
        elif raw.startswith("@usage"):
            in_usage = True
        elif raw.startswith("@"):
            continue
        else:
            desc.append(raw)
    if usage:
        if desc:
            desc.append("")
        desc.append("Usage:")
        desc.append("")
        desc.append("```lua")
        desc.extend(_dedent_usage(usage))
        desc.append("```")
    info["description"] = "\n".join(desc).strip()


def _consume_tags(block: list[str], fn: dict) -> None:
    desc: list[str] = []
    in_usage = False
    for raw in block:
        if in_usage:
            if raw.startswith("@"):
                in_usage = False
            else:
                fn["usage"].append(raw)
                continue
        if raw.startswith("@param"):
            p = _parse_param(raw)
            if p:
                fn["params"].append(p)
        elif raw.startswith("@tparam"):
            p = _parse_tparam(raw)
            if p:
                fn["params"].append(p)
        elif raw.startswith("@treturn"):
            r = _parse_treturn(raw)
            if r:
                fn["returns"].append(r)
        elif raw.startswith("@return"):
            parts = raw.split(None, 1)
            text = parts[1].strip() if len(parts) > 1 else ""
            if fn["returns"]:
                if text:
                    last = fn["returns"][-1]
                    last["desc"] = (last["desc"] + " " + text).strip()
            else:
                fn["returns"].append({"type": "", "desc": text})
        elif raw.startswith("@field"):
            f = _parse_field(raw)
            if f:
                fn["fields"].append(f)
        elif raw.startswith("@see"):
            parts = raw.split(None, 1)
            if len(parts) > 1:
                fn["see"].append(parts[1].strip())
        elif raw.startswith("@raise"):
            parts = raw.split(None, 1)
            if len(parts) > 1:
                fn["raises"].append(parts[1].strip())
        elif raw.startswith("@within"):
            parts = raw.split(None, 1)
            if len(parts) > 1:
                fn["within"] = parts[1].strip()
        elif raw.startswith("@status"):
            parts = raw.split(None, 1)
            if len(parts) > 1:
                fn["status"] = parts[1].strip()
        elif raw.startswith("@deprecated"):
            parts = raw.split(None, 1)
            fn["deprecated"] = parts[1].strip() if len(parts) > 1 else "true"
        elif raw.startswith("@local"):
            continue
        elif raw.startswith("@usage"):
            in_usage = True
        elif raw.startswith("@"):
            continue
        else:
            desc.append(raw)
    fn["desc"] = " ".join(d for d in desc if d).strip()


def _parse_param(raw: str) -> dict | None:
    parts = raw.split(None, 3)
    if len(parts) < 3:
        return None
    return {
        "name": parts[1],
        "type": parts[2] if len(parts) >= 3 else "",
        "desc": parts[3] if len(parts) > 3 else "",
    }


def _parse_tparam(raw: str) -> dict | None:
    parts = raw.split(None, 3)
    if len(parts) < 3:
        return None
    return {
        "name": parts[2],
        "type": parts[1],
        "desc": parts[3] if len(parts) > 3 else "",
    }


def _parse_treturn(raw: str) -> dict | None:
    parts = raw.split(None, 2)
    if len(parts) < 2:
        return None
    return {"type": parts[1], "desc": parts[2] if len(parts) > 2 else ""}


def _parse_field(raw: str) -> dict | None:
    parts = raw.split(None, 3)
    if len(parts) < 3:
        return None
    return {
        "name": parts[1],
        "type": parts[2],
        "desc": parts[3] if len(parts) > 3 else "",
    }


def _dedent_usage(usage: list[str]) -> list[str]:
    """Strip the smallest common leading whitespace from a usage block."""
    non_empty = [l for l in usage if l.strip()]
    if not non_empty:
        return list(usage)
    min_indent = min(len(l) - len(l.lstrip()) for l in non_empty)
    return [l[min_indent:] if l.strip() else "" for l in usage]


# ── Markdown rendering ────────────────────────────────────────────────────────


def _slug(target: str) -> str:
    """``lurek.serial.toJson`` → ``lurekcodectojson``. Strips non-alphanumerics."""
    return re.sub(r"[^a-z0-9]", "", target.lower())


def _render_see(see_list: list[str], from_libs_dir: bool) -> str:
    if not see_list:
        return ""
    rel_lua = "../../api/lurek.md" if from_libs_dir else "../api/lurek.md"
    rel_lib = "../library/lunasome.md" if from_libs_dir else "lunasome.md"
    out = []
    for tgt in see_list:
        head = tgt.split(None, 1)[0]
        rest_parts = tgt.split(None, 1)
        rest = rest_parts[1] if len(rest_parts) > 1 else ""
        if head.startswith("lurek."):
            link = f"[`{head}`]({rel_lua}#{_slug(head)})"
        elif head.startswith("library."):
            link = f"[`{head}`]({rel_lib}#{_slug(head)})"
        else:
            link = f"`{head}`"
        out.append(f"{link} — {rest}" if rest else link)
    return "See: " + ", ".join(out)


def _status_badge(status: str, deprecated: str) -> str:
    label_map = {
        "full": "",
        "partial": " *(partial)*",
        "stub": " *(stub — not yet implemented)*",
        "proxy": " *(proxy)*",
    }
    badge = label_map.get(status, "")
    if deprecated:
        badge += " *(deprecated)*"
    return badge


def _strip_module_prefix(full_name: str) -> str:
    return re.sub(r"^[^.:]+[.:]", "", full_name)


def _render_function(fn: dict, from_libs_dir: bool, heading_level: int) -> list[str]:
    out: list[str] = []
    short = _strip_module_prefix(fn["name"])
    badge = _status_badge(fn["status"], fn["deprecated"])
    h = "#" * heading_level
    out.append(f"{h} `{short}({fn['args']})`{badge}")
    out.append("")
    if fn["desc"]:
        out.append(fn["desc"])
        out.append("")
    if fn["params"]:
        out.append("**Parameters**")
        out.append("")
        for p in fn["params"]:
            t = f" *{p['type']}*" if p["type"] else ""
            d = f" — {p['desc']}" if p["desc"] else ""
            out.append(f"- `{p['name']}`{t}{d}")
        out.append("")
    if fn["returns"]:
        out.append("**Returns**")
        out.append("")
        for r in fn["returns"]:
            t = f"*{r['type']}*" if r["type"] else ""
            d = r["desc"]
            if t and d:
                out.append(f"- {t} — {d}")
            elif t:
                out.append(f"- {t}")
            else:
                out.append(f"- {d}")
        out.append("")
    if fn["fields"]:
        out.append("**Fields**")
        out.append("")
        for f in fn["fields"]:
            t = f" *{f['type']}*" if f["type"] else ""
            d = f" — {f['desc']}" if f["desc"] else ""
            out.append(f"- `{f['name']}`{t}{d}")
        out.append("")
    if fn["raises"]:
        out.append("**Raises**")
        out.append("")
        for r in fn["raises"]:
            out.append(f"- {r}")
        out.append("")
    see_line = _render_see(fn["see"], from_libs_dir)
    if see_line:
        out.append(see_line)
        out.append("")
    if fn["usage"]:
        out.append("```lua")
        out.extend(_dedent_usage(fn["usage"]))
        out.append("```")
        out.append("")
    return out


def _render_module_body(info: dict, from_libs_dir: bool, heading_level: int) -> list[str]:
    """Render module body without H1 title.

    ``heading_level`` is the level of subsection headers (Fields / Functions).
    Function entries render at ``heading_level + 1``.
    """
    out: list[str] = []
    if info["description"]:
        out.append(info["description"])
        out.append("")
    fn_count = len(info["functions"])
    field_count = len(info["fields"])
    out.append(f"*{fn_count} functions, {field_count} module fields documented.*")
    out.append("")
    see_line = _render_see(info["see"], from_libs_dir)
    if see_line:
        out.append(see_line)
        out.append("")
    if info["fields"]:
        out.append("#" * heading_level + " Fields")
        out.append("")
        for f in info["fields"]:
            t = f" *{f['type']}*" if f["type"] else ""
            d = f" — {f['desc']}" if f["desc"] else ""
            out.append(f"- `{f['name']}`{t}{d}")
        out.append("")
    if info["functions"]:
        # Group by @within (preserving first-seen order).
        groups: dict[str, list[dict]] = {}
        order: list[str] = []
        for fn in info["functions"]:
            key = fn["within"] or ""
            if key not in groups:
                groups[key] = []
                order.append(key)
            groups[key].append(fn)
        if order == [""]:
            out.append("#" * heading_level + " Functions")
            out.append("")
            for fn in info["functions"]:
                out.extend(_render_function(fn, from_libs_dir, heading_level + 1))
        else:
            out.append("#" * heading_level + " Functions")
            out.append("")
            for key in order:
                label = key if key else "General"
                out.append("#" * (heading_level + 1) + f" {label}")
                out.append("")
                for fn in groups[key]:
                    out.extend(_render_function(fn, from_libs_dir, heading_level + 2))
    return out


def render_module_md(module_name: str, info: dict) -> str:
    display = info["name"] or f"library.{module_name}"
    badge = _status_badge(info["status"], info["deprecated"])
    out: list[str] = [f"# `{display}`{badge}", ""]
    out.extend(_render_module_body(info, from_libs_dir=True, heading_level=2))
    return "\n".join(out).rstrip() + "\n"


def render_aggregate_md(modules: dict) -> str:
    out: list[str] = []
    out.append("# Lurek2D Library API Reference")
    out.append("")
    out.append("*Auto-generated by `tools/docs/gen_lib_docs.py`. Do not hand-edit.*")
    out.append("")
    out.append(
        "Documentation for the Lunasome standard library — pure-Lua modules under "
        "`content/library/` that ship with Lurek2D and consume only the public "
        "`lurek.*` API."
    )
    out.append("")
    out.append(
        "Cross-engine references (`See: lurek.…`) link into "
        "[`lua-api.md`](lua-api.md). Cross-library references "
        "(`See: library.…`) link within this file."
    )
    out.append("")
    total_fns = sum(len(info["functions"]) for _, info in modules.values())
    total_fields = sum(len(info["fields"]) for _, info in modules.values())
    out.append(f"*{len(modules)} libraries, {total_fns} functions, {total_fields} module fields.*")
    out.append("")
    out.append("---")
    out.append("")
    out.append("## Contents")
    out.append("")
    for module_name in sorted(modules.keys()):
        _, info = modules[module_name]
        display = info["name"] or f"library.{module_name}"
        fn_count = len(info["functions"])
        anchor = _slug(display)
        status = info["status"]
        suffix = ""
        if info["deprecated"]:
            suffix = " *(deprecated)*"
        elif status and status != "full":
            suffix = f" *({status})*"
        out.append(f"- [`{display}`](#{anchor}) — {fn_count} fn{suffix}")
    out.append("")
    out.append("---")
    out.append("")
    for module_name in sorted(modules.keys()):
        _, info = modules[module_name]
        display = info["name"] or f"library.{module_name}"
        badge = _status_badge(info["status"], info["deprecated"])
        out.append(f"## `{display}`{badge}")
        out.append("")
        out.extend(_render_module_body(info, from_libs_dir=False, heading_level=3))
        out.append("---")
        out.append("")
    return "\n".join(out).rstrip() + "\n"


# ── Module scanner ────────────────────────────────────────────────────────────


def scan_library() -> dict:
    """Walk ``content/library/`` and return ``{module_name: (path, info)}``."""
    results: dict[str, tuple[Path, dict]] = {}
    if not LIB_DIR.exists():
        return results
    for init_lua in sorted(LIB_DIR.glob("*/init.lua")):
        module_name = init_lua.parent.name
        source = init_lua.read_text(encoding="utf-8")
        info = parse_ldoc(source)
        if not info["name"]:
            info["name"] = f"library.{module_name}"
        results[module_name] = (init_lua, info)
    return results


# ── Validation (--check mode) ─────────────────────────────────────────────────


def _grep_public_assignments(source: str) -> set[str]:
    """Return the set of ``M.<name>`` symbols assigned in the source."""
    syms: set[str] = set()
    for line in source.splitlines():
        s = line.strip()
        m = _M_ASSIGN_RE.match(s)
        if m:
            syms.add(m.group(1))
            continue
        fm = re.match(r"^\s*function\s+M[.:]([A-Za-z_][\w]*)\s*\(", s)
        if fm:
            syms.add(fm.group(1))
    return syms


def _validate_module(module_name: str, path: Path, info: dict) -> list[tuple[str, str]]:
    errors: list[tuple[str, str]] = []
    rel = path.relative_to(REPO_ROOT).as_posix()

    # E001 missing-doc-block
    if not info["functions"] and not info["fields"]:
        errors.append(("E001", f"{rel} — module has no documented functions or fields"))

    # E005 invalid status
    status = info["status"]
    if status and status not in VALID_STATUS:
        errors.append((
            "E005",
            f"{rel} — invalid @status '{status}' (allowed: full|partial|stub|proxy)",
        ))

    # E003 undocumented public symbols
    src = path.read_text(encoding="utf-8")
    declared = _grep_public_assignments(src)
    documented_short = {_strip_module_prefix(fn["name"]) for fn in info["functions"]}
    documented_short |= {f["name"] for f in info["fields"]}
    for sym in sorted(declared - documented_short):
        if sym.startswith("_"):
            continue
        errors.append(("E003", f"{rel} — public symbol `M.{sym}` declared without doc block"))

    # E004 broken @see namespace
    def _check_see(tgt: str, where: str) -> None:
        head = tgt.split(None, 1)[0]
        if head.startswith("lurek."):
            tail = head[len("lurek."):]
            ns = tail.split(".")[0] if "." in tail else tail
            if ns and ns not in LUREK_NAMESPACES:
                errors.append(("E004", f"{where} — `@see {head}` references unknown "
                                       f"namespace `lurek.{ns}`"))

    for tgt in info["see"]:
        _check_see(tgt, rel)
    for fn in info["functions"]:
        for tgt in fn["see"]:
            _check_see(tgt, f"{rel}:{fn['decl_line']}")

    # E007 empty @usage block (function declared @usage with no code lines).
    src_lines = src.splitlines()
    for fn in info["functions"]:
        if fn["usage"]:
            continue
        # Walk back from decl_line to find any @usage tag in the preceding doc block.
        idx = fn["decl_line"] - 2
        while idx >= 0:
            s = src_lines[idx].strip()
            if not (s.startswith("---") or s.startswith("--")):
                break
            if "@usage" in s:
                errors.append(("E007", f"{rel}:{idx + 1} — `@usage` in `{fn['name']}` "
                                       f"has no code lines"))
                break
            idx -= 1

    return errors


# ── Generators ────────────────────────────────────────────────────────────────


def generate_per_module(modules: dict) -> int:
    """Retained for compatibility; per-library Markdown outputs are retired."""
    print("Per-library library pages are retired; aggregate-only output is canonical.")
    return 0


def generate_aggregate(modules: dict) -> None:
    md = render_aggregate_md(modules)
    AGGREGATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    AGGREGATE_PATH.write_text(md, encoding="utf-8", newline="\n")
    print(f"  → {AGGREGATE_PATH.relative_to(REPO_ROOT).as_posix()} "
          f"({len(modules)} libraries)")


# ── New API-style outputs (docs/api/library.md + docs/api/library.lua) ────────

API_MD_PATH  = REPO_ROOT / "docs" / "api" / "library.md"
API_LUA_PATH = REPO_ROOT / "docs" / "api" / "library.lua"


def _typed_args(fn: dict) -> str:
    """Build a typed argument string from fn["params"], falling back to fn["args"]."""
    if fn["params"]:
        parts = []
        for p in fn["params"]:
            t = p.get("type") or ""
            name = p["name"]
            if t:
                parts.append(f"{name} : {t}")
            else:
                parts.append(name)
        return ", ".join(parts)
    return fn.get("args", "") or ""


def _returns_str(fn: dict) -> str:
    """Build a compact return-type string."""
    rets = fn.get("returns", [])
    if not rets:
        return ""
    types = [r.get("type") or r.get("desc") or "" for r in rets]
    types = [t for t in types if t]
    return ", ".join(types) if types else ""


def _luacats_type(type_name: str) -> str:
    """Normalize LDoc type text into LuaCATS-safe type syntax."""
    t = (type_name or "any").strip()
    t = re.sub(r"[,.;:]+$", "", t).strip()
    if not t:
        return "any"
    aliases = {
        "Any": "any",
        "Arguments": "any",
        "Function": "function",
        "Table": "table",
        "String": "string",
        "Number": "number",
        "Boolean": "boolean",
    }
    t = aliases.get(t, t)
    if t.endswith("?"):
        base = t[:-1].strip() or "any"
        t = f"{base}|nil"
    return t


def _luacats_param_name(name: str) -> str:
    """Return a LuaCATS-safe parameter name, or empty for field-style LDoc tags."""
    name = (name or "").strip()
    if not name:
        return ""
    if name == "...":
        return name
    if "." in name:
        return ""
    return re.sub(r"[^A-Za-z0-9_]", "", name)


def _luacats_arg_names(args: str) -> set[str]:
    names: set[str] = set()
    for raw in (args or "").split(","):
        name = raw.strip()
        if not name:
            continue
        name = name.split("=", 1)[0].strip()
        if name == "...":
            names.add(name)
        else:
            names.add(re.sub(r"[^A-Za-z0-9_]", "", name))
    return names


def render_api_md(modules: dict) -> str:
    """Render docs/api/library.md in the same style as docs/api/lurek.md.

    Format mirrors docs/api/lurek.md:
      - Header with auto-gen note
      - Contents list with anchor links
      - Per-library H2 section with description blockquote + coverage line
      - Module-level functions in a single ```lua code block
      - Class method subsections as ### `ClassName` with their own code block
    """
    import datetime
    today = datetime.date.today().isoformat()
    total_fns = sum(len(info["functions"]) for _, info in modules.values())

    out: list[str] = []
    out.append("# Lunasome Library API Reference")
    out.append("")
    out.append(f"*Auto-generated by `tools/docs/gen_lib_docs.py`. Generated: {today}*")
    out.append(f"*{len(modules)} libraries, {total_fns} functions*")
    out.append("")
    out.append("---")
    out.append("")
    out.append("## Contents")
    out.append("")

    for module_name in sorted(modules.keys()):
        _, info = modules[module_name]
        display = info["name"] or f"library.{module_name}"
        fn_count = len(info["functions"])
        # Count classes (detect via `:` in raw function name)
        classes: set[str] = set()
        for fn in info["functions"]:
            if ":" in fn["name"]:
                classes.add(fn["name"].split(":")[0])
        class_str = f", {len(classes)} classes" if classes else ""
        # Anchor: just the module name (mirrors lurek.md using bare "render" not "lurekrender")
        anchor = module_name
        status = info["status"]
        suffix = ""
        if info["deprecated"]:
            suffix = " *(deprecated)*"
        elif status and status != "full":
            suffix = f" *({status})*"
        out.append(f"- [`{display}`](#{anchor}) — {fn_count} fn{class_str}{suffix}")

    out.append("")
    out.append("---")
    out.append("")

    for module_name in sorted(modules.keys()):
        _, info = modules[module_name]
        display = info["name"] or f"library.{module_name}"
        badge = _status_badge(info["status"], info["deprecated"])
        anchor = module_name

        # Split into module-level fns and class methods.
        # Use fn["name"] directly (e.g. "StatusEffect:getName") before stripping.
        module_fns: list[dict] = []
        class_methods: dict[str, list[dict]] = {}
        for fn in info["functions"]:
            raw = fn["name"]  # e.g. "M.newStatusEffect" or "StatusEffect:getName"
            if ":" in raw:
                cls = raw.split(":")[0]
                class_methods.setdefault(cls, []).append(fn)
            else:
                module_fns.append(fn)

        classes_count = len(class_methods)
        class_str = f", {classes_count} classes" if classes_count else ""
        coverage_note = f"*{len(info['functions'])} functions documented{class_str}*"

        out.append(f"## `{display}`{badge} {{#{anchor}}}")
        out.append("")
        if info["description"]:
            out.append(f"> {info['description']}")
            out.append("")
        out.append(coverage_note)
        out.append("")

        if module_fns:
            out.append("```lua")
            for fn in module_fns:
                short = _strip_module_prefix(fn["name"])
                args = _typed_args(fn)
                ret = _returns_str(fn)
                desc = fn["desc"].split("\n")[0].strip() if fn["desc"] else ""
                sig = f"{display}.{short}( {args} )"
                if ret:
                    sig += f" -> {ret}"
                if desc:
                    sig += f"  -- {desc}"
                out.append(sig)
            out.append("```")
            out.append("")

        for cls_name, cls_fns in class_methods.items():
            out.append(f"### `{cls_name}`")
            out.append("")
            out.append("```lua")
            for fn in cls_fns:
                # fn["name"] is e.g. "StatusEffect:getName"
                method = fn["name"].split(":")[1] if ":" in fn["name"] else fn["name"]
                args = _typed_args(fn)
                ret = _returns_str(fn)
                desc = fn["desc"].split("\n")[0].strip() if fn["desc"] else ""
                sig = f"{cls_name}:{method}( {args} )"
                if ret:
                    sig += f" -> {ret}"
                if desc:
                    sig += f"  -- {desc}"
                out.append(sig)
            out.append("```")
            out.append("")

        out.append("---")
        out.append("")

    return "\n".join(out).rstrip() + "\n"


def render_luacats(modules: dict) -> str:
    """Render docs/api/library.lua LuaCATS stubs in the same style as docs/api/lurek.lua."""
    out: list[str] = []
    out.append("---@meta")
    out.append("--- Auto-generated Lunasome library API documentation for LuaCATS.")
    out.append("")
    out.append("library = {}")
    out.append("")

    # Declare built-in Lua types so LSP recognizes them in annotations
    out.append("---@class number")
    out.append("---@class string")
    out.append("---@class boolean")
    out.append("---@class table")
    out.append("---@class function")
    out.append("---@class thread")
    out.append("---@class userdata")
    out.append("---@class nil")
    out.append("")

    declared_classes: set[str] = {"number", "string", "boolean", "table", "function", "thread", "userdata", "nil"}
    referenced_types: set[str] = set()
    for _, info in modules.values():
        for fn in info["functions"]:
            raw_name = fn["name"]
            if ":" in raw_name:
                cls = raw_name.split(":", 1)[0]
                if cls not in declared_classes:
                    out.append(f"---@class {cls}")
                    out.append(f"{cls} = {{}}")
                    out.append("")
                    declared_classes.add(cls)
            for p in fn.get("params", []):
                for token in re.findall(r"[A-Z][A-Za-z0-9_]*", _luacats_type(p.get("type", ""))):
                    referenced_types.add(token)
            for r in fn.get("returns", []):
                for token in re.findall(r"[A-Z][A-Za-z0-9_]*", _luacats_type(r.get("type", ""))):
                    referenced_types.add(token)

    for type_name in sorted(referenced_types - declared_classes):
        out.append(f"---@class {type_name}")
        out.append(f"{type_name} = {{}}")
        out.append("")

    for module_name in sorted(modules.keys()):
        _, info = modules[module_name]
        display = info["name"] or f"library.{module_name}"
        out.append(f"---@class {display}")
        out.append(f"library.{module_name} = {{}}")
        out.append("")

        nested_tables: set[str] = set()
        for fn in info["functions"]:
            raw_name = fn["name"]
            if ":" in raw_name:
                continue
            short_name = _strip_module_prefix(raw_name)
            parts = short_name.split(".")
            for depth in range(1, len(parts)):
                nested_tables.add(".".join(parts[:depth]))

        for nested in sorted(nested_tables, key=lambda value: (value.count("."), value)):
            out.append(f"---@class {display}.{nested}")
            out.append(f"{display}.{nested} = {{}}")
            out.append("")

        for fn in info["functions"]:
            raw_name = fn["name"]
            arg_names = _luacats_arg_names(fn.get("args", ""))

            # Docstring
            if fn["desc"]:
                first_line = fn["desc"].split("\n")[0]
                out.append(f"--- {first_line}")
            for p in fn["params"]:
                name = _luacats_param_name(p["name"])
                if not name:
                    continue
                if arg_names and name != "..." and name not in arg_names:
                    continue
                t = _luacats_type(p["type"])
                out.append(f"---@param {name} {t}")
            for r in fn["returns"]:
                t = _luacats_type(r["type"] if r["type"] else "any")
                out.append(f"---@return {t}")
            if not fn["returns"]:
                out.append("---@return nil")

            # Function declaration
            if ":" in raw_name:
                cls = raw_name.split(":", 1)[0]
                method = raw_name.split(":", 1)[1]
                args = fn["args"]
                out.append(f"function {cls}:{method}({args}) end")
            else:
                short = _strip_module_prefix(raw_name)
                args = fn["args"]
                out.append(f"function {display}.{short}({args}) end")
            out.append("")

    return "\n".join(out).rstrip() + "\n"


def generate_api_files(modules: dict) -> None:
    """Generate docs/api/library.md and docs/api/library.lua."""
    api_dir = API_MD_PATH.parent
    api_dir.mkdir(parents=True, exist_ok=True)

    md = render_api_md(modules)
    API_MD_PATH.write_text(md, encoding="utf-8", newline="\n")
    print(f"  → {API_MD_PATH.relative_to(REPO_ROOT).as_posix()} ({len(modules)} libraries)")

    lua = render_luacats(modules)
    API_LUA_PATH.write_text(lua, encoding="utf-8", newline="\n")
    print(f"  → {API_LUA_PATH.relative_to(REPO_ROOT).as_posix()} (LuaCATS stubs)")


def run_check(modules: dict) -> int:
    by_code: dict[str, list[str]] = {}
    by_module: dict[str, int] = {}
    total_fn = 0
    for module_name in sorted(modules.keys()):
        path, info = modules[module_name]
        total_fn += len(info["functions"])
        mod_errs = _validate_module(module_name, path, info)
        if mod_errs:
            by_module[module_name] = len(mod_errs)
        for code, msg in mod_errs:
            by_code.setdefault(code, []).append(msg)

    if not by_code:
        print(f"OK: {len(modules)} libraries, {total_fn} functions, 0 errors.")
        return 0

    total_errors = sum(len(v) for v in by_code.values())
    print(f"FAIL: {len(modules)} libraries, {total_fn} functions, "
          f"{total_errors} errors across {len(by_code)} categories.\n")
    code_descriptions = {
        "E001": "missing-doc-block",
        "E002": "param-mismatch",
        "E003": "undocumented-public",
        "E004": "broken-see-link",
        "E005": "invalid-status",
        "E006": "invalid-field",
        "E007": "empty-usage",
    }
    for code in sorted(by_code.keys()):
        msgs = by_code[code]
        print(f"[{code}] {code_descriptions.get(code, '')} — {len(msgs)} occurrence(s)")
        for m in msgs:
            print(f"    {m}")
        print()
    print("Top offenders by total errors:")
    for mod, count in sorted(by_module.items(), key=lambda kv: -kv[1])[:10]:
        print(f"    {count:4d}  {mod}")
    return 1


# ── Entry point ───────────────────────────────────────────────────────────────


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--check", action="store_true",
                        help="Validate docstrings; exit 1 on any error")
    parser.add_argument("--module", metavar="NAME",
                        help="Process only the named library (e.g. dialog)")
    parser.add_argument("--no-aggregate", action="store_true",
                        help="Skip writing docs/library/lunasome.md")
    parser.add_argument("--api", action="store_true",
                        help="Generate docs/api/library.md + docs/api/library.lua")
    args = parser.parse_args()

    modules = scan_library()
    if not modules:
        print(f"No library modules found under {LIB_DIR}", file=sys.stderr)
        return 1

    if args.module:
        if args.module not in modules:
            print(f"Module '{args.module}' not found in content/library/", file=sys.stderr)
            return 1
        modules = {args.module: modules[args.module]}

    if args.check:
        return run_check(modules)

    if not args.no_aggregate:
        print("Generating aggregate library reference …")
        generate_aggregate(modules)

    print("Generating API docs (library.md + library.lua) …")
    generate_api_files(modules)

    return 0


if __name__ == "__main__":
    sys.exit(main())
