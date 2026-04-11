#!/usr/bin/env python3
"""Generate docs/specs/<module>.md files for all top-level src modules.

This tool builds each spec from four sources of truth:
- src/<module>/AGENT.md
- src/<module>/AGENT.legacy.md (when present)
- the actual Rust source files under src/<module>/
- the Lua API parser in tools/docs/gen_lua_api.py

It intentionally keeps the generated prose conservative. The goal is to create
complete, maintainable module specs that match the current source tree without
inventing missing implementation details.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent.parent
SRC = ROOT / "src"
SPECS = ROOT / "docs" / "specs"
README = SPECS / "README.md"
SESSION_DATA = ROOT / "work" / "module-specs-20260411" / "data" / "module_inventory.json"


GROUPS = {
    "Foundations": {
        "math",
        "log",
        "data",
        "serial",
        "compute",
        "dataframe",
        "graph",
        "procgen",
        "patterns",
    },
    "Core Runtime": {
        "runtime",
        "event",
        "timer",
        "thread",
        "network",
        "filesystem",
    },
    "Platform Services": {
        "render",
        "audio",
        "physics",
        "input",
        "image",
        "window",
        "camera",
        "light",
        "effect",
    },
    "Feature Systems": {
        "ecs",
        "scene",
        "animation",
        "tween",
        "particle",
        "tilemap",
        "parallax",
        "minimap",
        "raycaster",
        "ui",
        "terminal",
        "ai",
        "pathfind",
        "save",
        "mods",
        "i18n",
        "automation",
        "sprite",
        "spine",
    },
    "Edge/Integration": {
        "app",
        "lua_api",
        "devtools",
        "debugbridge",
        "docs",
        "pipeline",
        "bin",
    },
}


ARCH_SECTION = {
    "Foundations": "docs/architecture/engine-architecture.md § Foundations",
    "Core Runtime": "docs/architecture/engine-architecture.md § Core Runtime",
    "Platform Services": "docs/architecture/engine-architecture.md § Platform Services",
    "Feature Systems": "docs/architecture/engine-architecture.md § Feature Systems",
    "Edge/Integration": "docs/architecture/engine-architecture.md § Edge / Integration",
}


PUB_ITEM_RE = re.compile(
    r"^pub(?:\([^)]*\))?\s+(?:unsafe\s+|async\s+|const\s+|extern\s+\"[^\"]*\"\s+)?"
    r"(struct|enum|trait|type|fn|const|static)\s+([A-Za-z_][A-Za-z0-9_]*)"
)
USE_RE = re.compile(r"(?:use\s+crate::|crate::)([A-Za-z_][A-Za-z0-9_]*)")
SET_RE = re.compile(r"\b(?:luna|lurek)\.set\(\s*\"([^\"]+)\"")


def load_lua_parser():
    spec = importlib.util.spec_from_file_location(
        "gen_lua_api", ROOT / "tools" / "docs" / "gen_lua_api.py"
    )
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def module_group(module: str) -> str:
    for group, modules in GROUPS.items():
        if module in modules:
            return group
    return "Edge/Integration"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig") if path.exists() else ""


def normalize_space(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def clean_doc_text(text: str) -> str:
    text = text.replace("```", " ")
    text = re.split(r"\s+#\s+(?:Fields|Variants|Returns|Parameters)\b", text, maxsplit=1)[0]
    text = normalize_space(text)
    if not text:
        return ""
    sentence_match = re.match(r"(.{1,240}?[.!?])(?:\s|$)", text)
    if sentence_match:
        return sentence_match.group(1).strip()
    return text[:240].rstrip()


def split_section(text: str, heading: str) -> str:
    pattern = re.compile(rf"^##\s+{re.escape(heading)}\s*$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        return ""
    start = match.end()
    rest = text[start:]
    next_heading = re.search(r"^##\s+", rest, re.MULTILINE)
    if next_heading:
        rest = rest[: next_heading.start()]
    return rest.strip()


def parse_agent_sections(text: str) -> dict:
    return {
        "module_info": split_section(text, "Module Info"),
        "module_purpose": split_section(text, "Module Purpose"),
        "files": split_section(text, "Files"),
        "key_types": split_section(text, "Key Types"),
        "purpose": split_section(text, "Purpose"),
        "source_files": split_section(text, "Source Files"),
        "lua_api_summary": split_section(text, "Lua API Summary"),
    }


def parse_bullet_pairs(section: str) -> dict[str, str]:
    items: dict[str, str] = {}
    for line in section.splitlines():
        stripped = line.strip()
        if not stripped.startswith("- "):
            continue
        body = stripped[2:]
        if ":" in body:
            left, right = body.split(":", 1)
        elif " - " in body:
            left, right = body.split(" - ", 1)
        else:
            continue
        key = left.strip().strip("`")
        value = right.strip()
        items[key] = value
    return items


def parse_legacy_table(section: str) -> dict[str, str]:
    items: dict[str, str] = {}
    for line in section.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        if len(cells) < 2:
            continue
        if cells[0].lower() in {"file", "type", "function", "method"}:
            continue
        if set(cells[0]) == {"-"}:
            continue
        key = cells[0].strip("`")
        items[key] = cells[1]
    return items


def parse_markdown_table(text: str) -> dict[str, str]:
    items: dict[str, str] = {}
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        if len(cells) < 2:
            continue
        if set(cells[0]) == {"-"}:
            continue
        items[cells[0].strip("`")] = cells[1]
    return items


def collect_doc_above(lines: list[str], index: int) -> str:
    docs: list[str] = []
    j = index - 1
    while j >= 0:
        stripped = lines[j].strip()
        if stripped.startswith("///"):
            docs.insert(0, stripped[3:].lstrip())
        elif stripped.startswith("#[") or stripped == "":
            pass
        else:
            break
        j -= 1
    return clean_doc_text(" ".join(docs))


def first_module_doc_line(lines: list[str]) -> str:
    parts: list[str] = []
    for raw in lines:
        stripped = raw.strip()
        if stripped.startswith("//!"):
            parts.append(stripped[3:].lstrip())
        elif parts:
            break
    return clean_doc_text(" ".join(parts))


def scan_module_sources(module: str) -> dict:
    module_dir = SRC / module
    file_info = []
    type_by_file: dict[str, list[dict]] = defaultdict(list)
    refs: set[str] = set()
    counts = {"struct": 0, "enum": 0}

    for path in sorted(module_dir.rglob("*.rs")):
        rel = path.relative_to(module_dir).as_posix()
        lines = read_text(path).splitlines()
        purpose = first_module_doc_line(lines)
        if not purpose:
            for idx, line in enumerate(lines):
                item = PUB_ITEM_RE.match(line)
                if item:
                    purpose = collect_doc_above(lines, idx)
                    break
        file_info.append({"file": rel, "purpose": purpose or "Public API and internal module logic."})

        for idx, line in enumerate(lines):
            item = PUB_ITEM_RE.match(line)
            if item:
                kind, name = item.group(1), item.group(2)
                desc = collect_doc_above(lines, idx)
                type_by_file[rel].append({"kind": kind, "name": name, "description": desc})
                if kind in counts:
                    counts[kind] += 1

            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("///") or stripped.startswith("//!"):
                continue
            for ref in USE_RE.findall(line):
                if ref != module and (SRC / ref).is_dir():
                    refs.add(ref)

    return {
        "files": file_info,
        "types_by_file": type_by_file,
        "references": sorted(refs),
        "counts": counts,
    }


def collect_lua_api(module: str, lua_parser, current_text: str, legacy_text: str) -> dict:
    all_functions = lua_parser.collect_all_functions(ROOT / "src" / "lua_api")
    funcs = all_functions.get(module, [])
    module_functions = []
    classes: dict[str, list[dict]] = defaultdict(list)
    namespace_prefixes: list[str] = []

    for fn in funcs:
        if fn.lua_name:
            if "." in fn.lua_name:
                namespace_prefixes.append(fn.lua_name.rsplit(".", 1)[0])
        entry = {
            "name": fn.name,
            "lua_name": fn.lua_name,
            "description": fn.description or "Lua-facing function documented in the binding source.",
        }
        if fn.kind == "function":
            module_functions.append(entry)
        else:
            owner = fn.owner_type or "Object"
            classes[owner].append(entry)

    namespace = namespace_prefixes[0] if namespace_prefixes else ""
    namespace_patterns = [
        re.search(r"Lua API path\(s\):[^\n]*`?(lurek\.[a-zA-Z0-9_.]+)`?", current_text),
        re.search(r"Lua bridge:.*?`(lurek\.[a-zA-Z0-9_.]+)`", current_text),
        re.search(r"\|\s*\*\*Lua API\*\*\s*\|\s*`(lurek\.[a-zA-Z0-9_.]+)`", legacy_text),
        re.search(r"`(lurek\.[a-zA-Z0-9_.]+)`", current_text),
    ]
    for match in namespace_patterns:
        if match:
            namespace = match.group(1)
            break
    api_file = ROOT / "src" / "lua_api" / f"{module}_api.rs"
    if not namespace and api_file.exists():
        text = read_text(api_file)
        match = SET_RE.search(text)
        if match:
            namespace = f"lurek.{match.group(1)}"

    return {
        "namespace": namespace,
        "module_functions": module_functions,
        "classes": dict(classes),
    }


def build_scope_boundary(module: str, refs: list[str], group: str) -> str:
    if refs:
        ref_text = ", ".join(f"`{r}`" for r in refs[:8])
        if len(refs) > 8:
            ref_text += ", and other adjacent modules"
        return (
            f"**Scope boundary**: This module currently depends on {ref_text}. "
            f"It stays within the {group} responsibility boundary defined in the architecture docs."
        )
    return (
        f"**Scope boundary**: This module currently acts as a mostly self-contained part of the {group} layer. "
        "Cross-module behavior should remain anchored to the top-level source files and Lua bindings listed below."
    )


def infer_tests(agent_info: str, legacy_text: str) -> tuple[str, str]:
    rust_tests = "none found in the workspace"
    lua_tests = "none found in the workspace"

    for line in agent_info.splitlines():
        stripped = line.strip()
        if stripped.startswith("- Rust test path(s):"):
            rust_tests = stripped.split(":", 1)[1].strip()
        if stripped.startswith("- Lua test path(s):"):
            lua_tests = stripped.split(":", 1)[1].strip()

    legacy_table = parse_markdown_table(legacy_text)
    if rust_tests == "none found in the workspace":
        rust_tests = legacy_table.get("**Rust Tests**", legacy_table.get("Rust Tests", rust_tests))
        rust_tests = normalize_space(rust_tests)
    if lua_tests == "none found in the workspace":
        lua_tests = legacy_table.get("**Lua Tests**", legacy_table.get("Lua Tests", lua_tests))
        lua_tests = normalize_space(lua_tests)

    return rust_tests, lua_tests


def merge_file_descriptions(current_section: str, legacy_section: str) -> dict[str, str]:
    merged = parse_bullet_pairs(current_section)
    for key, value in parse_legacy_table(legacy_section).items():
        merged.setdefault(key, value)
    return merged


def merge_key_types(current_section: str, legacy_section: str) -> dict[str, str]:
    merged = parse_bullet_pairs(current_section)
    for key, value in parse_legacy_table(legacy_section).items():
        merged.setdefault(key, value)
    return merged


def format_architecture(module: str, namespace: str, files: list[dict]) -> str:
    api_line = (
        f"{namespace}.* (Lua API — src/lua_api/{module}_api.rs)"
        if namespace
        else "No direct Lua namespace — consumed through app/runtime integration or other bindings"
    )
    lines = ["```", api_line, "    |", "    v", f"src/{module}/mod.rs"]
    for info in [f for f in files if f["file"] != "mod.rs"][:8]:
        stem = Path(info["file"]).stem
        lines.append(f"    |- {info['file']} - {stem}")
    if len(files) > 8:
        lines.append("    |- ...")
    lines.append("```")
    return "\n".join(lines)


def format_source_files(file_rows: list[dict], descriptions: dict[str, str]) -> str:
    lines = ["| File | Purpose |", "|------|---------|"]
    for row in file_rows:
        desc = descriptions.get(row["file"], row["purpose"]).replace("|", "\\|")
        lines.append(f"| `{row['file']}` | {desc} |")
    return "\n".join(lines)


def bullet_for_type(item: dict) -> str:
    desc = item["description"] or f"Public {item['kind']} in this submodule."
    return f"- **`{item['name']}`** ({item['kind']}): {desc}"


def format_submodules(module: str, file_rows: list[dict], descriptions: dict[str, str], types_by_file: dict[str, list[dict]]) -> str:
    chunks = []
    for row in file_rows:
        if row["file"] == "mod.rs":
            continue
        stem = Path(row["file"]).stem
        desc = descriptions.get(row["file"], row["purpose"]) or "Implements a focused part of the module surface."
        items = [item for item in types_by_file.get(row["file"], []) if item["kind"] in {"struct", "enum", "trait", "type"}]
        block = [f"### `{module}::{stem}`", "", desc]
        if items:
            block.append("")
            block.extend(bullet_for_type(item) for item in items[:10])
        else:
            block.append("")
            block.append("- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.")
        chunks.append("\n".join(block))
    return "\n\n".join(chunks)


def format_key_types(key_types: dict[str, str], source_types: dict[str, list[dict]]) -> str:
    if not key_types:
        flat_types = []
        for items in source_types.values():
            flat_types.extend([item for item in items if item["kind"] in {"struct", "enum", "trait", "type"}])
        for item in flat_types[:8]:
            key_types[item["name"]] = item["description"] or f"Public {item['kind']} in this module."

    if not key_types:
        return "This module does not expose reusable public Rust data types of its own. It is primarily entry-point or glue code."

    lines = ["### Public Types", ""]
    for name, desc in key_types.items():
        lines.append(f"#### `{name}`")
        lines.append("")
        lines.append(clean_doc_text(desc) or "Important public type in this module.")
        lines.append("")
    return "\n".join(lines).rstrip()


def format_lua_api(module: str, lua_api: dict) -> str:
    namespace = lua_api["namespace"]
    if not namespace and not lua_api["module_functions"] and not lua_api["classes"]:
        return (
            "This module does not expose a dedicated direct Lua namespace. It is consumed indirectly "
            "through higher-level engine callbacks, shared state, or other `lurek.*` surfaces."
        )

    lines = []
    if namespace:
        lines.append(f"Exposed under `{namespace}.*` by `src/lua_api/{module}_api.rs`.")
        lines.append("")

    if lua_api["module_functions"]:
        lines.append("### Module Functions")
        lines.append("")
        lines.append("| Function | Description |")
        lines.append("|----------|-------------|")
        for fn in lua_api["module_functions"]:
            label = fn["lua_name"] or f"{namespace}.{fn['name']}"
            lines.append(f"| `{label}` | {fn['description']} |")
        lines.append("")

    for class_name, methods in sorted(lua_api["classes"].items()):
        lines.append(f"### `{class_name}` Methods")
        lines.append("")
        lines.append("| Method | Description |")
        lines.append("|--------|-------------|")
        for method in methods:
            lines.append(f"| `{class_name.lower()}:{method['name']}(...)` | {method['description']} |")
        lines.append("")

    return "\n".join(lines).rstrip()


def format_example(namespace: str) -> str:
    if namespace:
        return "```lua\n" + (
            f"-- Minimal namespace check for {namespace}.\n"
            f"if {namespace} then\n"
            f"    -- Call the documented functions in the Lua API tables above.\n"
            "end\n"
        ) + "```"
    return "```lua\n-- This module has no dedicated direct Lua namespace.\n-- It is used indirectly through other engine systems.\n```"


def format_item_summary(counts: dict, lua_api: dict) -> str:
    lua_count = len(lua_api["module_functions"]) + sum(len(v) for v in lua_api["classes"].values())
    total = counts["struct"] + counts["enum"] + lua_count
    return "\n".join(
        [
            "| Kind | Count |",
            "|------|-------|",
            f"| `struct` | {counts['struct']} |",
            f"| `enum` | {counts['enum']} |",
            f"| `fn` (Lua API) | {lua_count} |",
            f"| **Total** | **{total}** |",
        ]
    )


def reference_note(group: str, dep_group: str) -> str:
    if group == dep_group:
        return "Same responsibility group; allowed when the dependency graph stays acyclic."
    return f"Cross-group dependency from {group} to {dep_group}."


def format_references(group: str, refs: list[str]) -> str:
    if not refs:
        return "| Module | Relationship | Notes |\n|--------|--------------|-------|\n| — | No top-level `crate::<module>` imports were detected in this module's source files. | Keep the source files as the primary dependency reference. |"
    lines = ["| Module | Relationship | Notes |", "|--------|--------------|-------|"]
    for ref in refs:
        dep_group = module_group(ref)
        lines.append(
            f"| `{ref}` | Imports or references `{ref}` from `src/{ref}/`. | {reference_note(group, dep_group)} |"
        )
    return "\n".join(lines)


def format_notes(namespace: str, module: str) -> str:
    notes = [
        f"- **Source of truth**: Keep this spec synchronized with `src/{module}/`, the matching AGENT files, and any relevant Lua bindings.",
        "- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.",
    ]
    if not namespace:
        notes.append("- **Lua surface**: This module has no dedicated direct `lurek.*` namespace and is typically consumed through higher integration layers.")
    return "\n".join(notes)


def build_spec(module: str, lua_parser) -> tuple[str, dict]:
    current_text = read_text(SRC / module / "AGENT.md")
    legacy_text = read_text(SRC / module / "AGENT.legacy.md")
    current = parse_agent_sections(current_text)
    legacy = parse_agent_sections(legacy_text)
    source = scan_module_sources(module)
    lua_api = collect_lua_api(module, lua_parser, current_text, legacy_text)
    group = module_group(module)
    rust_tests, lua_tests = infer_tests(current["module_info"], legacy_text)
    file_descriptions = merge_file_descriptions(current["files"], legacy["source_files"])
    key_types = merge_key_types(current["key_types"], legacy["key_types"])
    summary_text = current["module_purpose"] or current["purpose"] or legacy["purpose"]
    summary_text = summary_text.strip() or f"The `{module}` module is documented from the current source tree and AGENT metadata."
    summary_text = summary_text + "\n\n" + build_scope_boundary(module, source["references"], group)
    lua_field = f"`{lua_api['namespace']}`" if lua_api["namespace"] else "Indirect / none"

    architecture = format_architecture(module, lua_api["namespace"], source["files"])
    source_files = format_source_files(source["files"], file_descriptions)
    submodules = format_submodules(module, source["files"], file_descriptions, source["types_by_file"])
    key_types_text = format_key_types(key_types, source["types_by_file"])
    lua_api_text = format_lua_api(module, lua_api)
    example = format_example(lua_api["namespace"])
    item_summary = format_item_summary(source["counts"], lua_api)
    references = format_references(group, source["references"])
    notes = format_notes(lua_api["namespace"], module)

    content = f"""# `{module}` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | {group} |
| **Status** | Implemented |
| **Lua API** | {lua_field} |
| **Source** | `src/{module}/` |
| **Rust Tests** | {rust_tests} |
| **Lua Tests** | {lua_tests} |
| **Architecture** | `{ARCH_SECTION[group]}` |

---

## Summary

{summary_text}

---

## Architecture

{architecture}

---

## Source Files

{source_files}

---

## Submodules

{submodules}

---

## Key Types

{key_types_text}

---

## Lua API

{lua_api_text}

---

## Lua Examples

{example}

---

## Item Summary

{item_summary}

---

## References

{references}

---

## Notes

{notes}
"""

    inventory = {
        "group": group,
        "namespace": lua_api["namespace"],
        "rust_tests": rust_tests,
        "lua_tests": lua_tests,
        "references": source["references"],
        "file_count": len(source["files"]),
        "lua_api_count": len(lua_api["module_functions"]) + sum(len(v) for v in lua_api["classes"].values()),
    }
    return content, inventory


def rewrite_readme(modules: list[str]) -> None:
    text = read_text(README)
    marker = "## Modules\n"
    if marker not in text:
        return
    prefix = text[: text.index(marker) + len(marker)]
    lines = [f"- [{module}]({module}.md)" for module in modules]
    README.write_text(prefix + "\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate docs/specs/*.md for all top-level src modules.")
    parser.add_argument("--module", action="append", help="Only generate the named module (can be repeated).")
    args = parser.parse_args()

    lua_parser = load_lua_parser()
    modules = sorted(p.name for p in SRC.iterdir() if p.is_dir())
    if args.module:
        selected = set(args.module)
        modules = [m for m in modules if m in selected]

    SPECS.mkdir(parents=True, exist_ok=True)
    SESSION_DATA.parent.mkdir(parents=True, exist_ok=True)

    inventory: dict[str, dict] = {}
    for module in modules:
        content, meta = build_spec(module, lua_parser)
        (SPECS / f"{module}.md").write_text(content, encoding="utf-8")
        inventory[module] = meta

    if not args.module:
        rewrite_readme(sorted(p.name for p in SRC.iterdir() if p.is_dir()))

    SESSION_DATA.write_text(json.dumps(inventory, indent=2, sort_keys=True), encoding="utf-8")
    print(f"Generated {len(modules)} module spec files.")


if __name__ == "__main__":
    main()