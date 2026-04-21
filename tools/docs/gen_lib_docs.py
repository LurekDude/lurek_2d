#!/usr/bin/env python3
"""gen_lib_docs.py — Generate Markdown API docs from Lurek2D library Lua files.

Scans ``content/library/**/init.lua`` for LDoc-style docstrings and emits:

* one Markdown page per library at ``docs/API/libs/lib_<name>.md``
* a single aggregate index at ``docs/API/library-docs.md`` (mirrors the
  layout of ``docs/API/lua-api.md``)
* (optional) a wiki mirror under ``docs/wiki/`` if that folder exists

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
* ``@see lurek.<ns>.<fn>``            – cross-link into ``lua-api.md``
* ``@see library.<name>.<fn>``        – cross-link into ``library-docs.md``
* ``@raise description``              – raised-error description
* ``@within section``                 – grouping label inside the module

Usage:
    python tools/docs/gen_lib_docs.py                  # generate all
    python tools/docs/gen_lib_docs.py --module dialog  # just one library
    python tools/docs/gen_lib_docs.py --check          # validate, exit 1 on errors
    python tools/docs/gen_lib_docs.py --no-aggregate   # skip library-docs.md
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# ── Configuration ─────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
LIB_DIR = REPO_ROOT / "content" / "library"
OUT_DIR = REPO_ROOT / "docs" / "API" / "libs"
AGGREGATE_PATH = REPO_ROOT / "docs" / "API" / "library-docs.md"
WIKI_DIR = REPO_ROOT / "docs" / "wiki"

VALID_STATUS = {"full", "partial", "stub", "proxy"}

# Runtime ``lurek.*`` namespaces (see P1 map). Used by ``--check`` to flag
# ``@see`` targets that point at a namespace that does not exist.
LUREK_NAMESPACES = {
    # P1 runtime-name shifts
    "img", "codec", "savegame", "time", "entity", "modding", "fs",
    "pathfinding", "postfx", "particles", "graphic", "localization",
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
    rel_lua = "../lua-api.md" if from_libs_dir else "lua-api.md"
    rel_lib = "../library-docs.md" if from_libs_dir else "library-docs.md"
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
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    written = 0
    for module_name in sorted(modules.keys()):
        path, info = modules[module_name]
        md = render_module_md(module_name, info)
        out_path = OUT_DIR / f"lib_{module_name}.md"
        out_path.write_text(md, encoding="utf-8", newline="\n")
        written += 1
        print(f"  → {out_path.relative_to(REPO_ROOT).as_posix()} "
              f"({len(info['functions'])} fn, {len(info['fields'])} fields)")
        if WIKI_DIR.exists():
            wiki_path = WIKI_DIR / f"Library-{module_name.replace('_', '-').title()}.md"
            wiki_path.write_text(md, encoding="utf-8", newline="\n")
    return written


def generate_aggregate(modules: dict) -> None:
    md = render_aggregate_md(modules)
    AGGREGATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    AGGREGATE_PATH.write_text(md, encoding="utf-8", newline="\n")
    print(f"  → {AGGREGATE_PATH.relative_to(REPO_ROOT).as_posix()} "
          f"({len(modules)} libraries)")


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
                        help="Skip writing docs/API/library-docs.md")
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

    print(f"Generating per-library docs → {OUT_DIR.relative_to(REPO_ROOT).as_posix()}/")
    generate_per_module(modules)

    if not args.no_aggregate and not args.module:
        print("Generating aggregate library reference …")
        generate_aggregate(modules)

    return 0


if __name__ == "__main__":
    sys.exit(main())
