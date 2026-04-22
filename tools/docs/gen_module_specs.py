#!/usr/bin/env python3
"""Generate merged docs/specs/<module>.md files for top-level src modules.

This tool treats docs/specs/<module>.md as the canonical long-form module
reference. During the AGENT.md retirement migration it can seed missing manual
content from src/<module>/AGENT.md or src/<module>/AGENT.legacy.md, but after
that transition it continues to work from the existing spec plus source code.

Manual sections preserved from the existing spec when present:
- General Info
- Summary
- Notes

Auto-collected sections rebuilt from source code and Lua binding data:
- Files
- Types
- Functions
- Lua API Reference
- References
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Optional


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
        "globe",
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


SECTION_ALIASES = {
    "general_info": ["General Info", "Module Info"],
    "summary": ["Summary", "Module Purpose", "Purpose"],
    "files": ["Files", "Source Files"],
    "types": ["Types", "Key Types"],
    "functions": ["Functions"],
    "lua_api": ["Lua API Reference", "Lua API", "Lua API Summary"],
    "references": ["References"],
    "notes": ["Notes", "Constraints"],
}


USE_RE = re.compile(r"(?:use\s+crate::|crate::)([A-Za-z_][A-Za-z0-9_]*)")
TYPE_RE = re.compile(
    r'^\s*pub(?:\([^)]*\))?\s+'
    r'(?:unsafe\s+|async\s+|const\s+|extern\s+"[^\"]*"\s+)?'
    r'(struct|enum|trait|type)\s+([A-Za-z_][A-Za-z0-9_]*)'
)
FUNCTION_RE = re.compile(
    r'^\s*pub(?:\([^)]*\))?\s+'
    r'(?:unsafe\s+|async\s+|const\s+)?fn\s+([A-Za-z_][A-Za-z0-9_]*)'
)
IMPL_RE = re.compile(
    r'^\s*impl(?:<[^>{}]+>)?\s+'
    r'(?:(?:[A-Za-z_][A-Za-z0-9_:<>]+)\s+for\s+)?'
    r'([A-Za-z_][A-Za-z0-9_:<>]*)'
)
SET_RE = re.compile(r'\b(?:lurek|lurek)\.set\(\s*"([^\"]+)"')


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
    sentence_match = re.match(r"(.{1,280}?[.!?])(?:\s|$)", text)
    if sentence_match:
        return sentence_match.group(1).strip()
    return text[:280].rstrip()


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
    rest = re.sub(r"(^|\n)---+\s*(?=\n|$)", "\n", rest)
    return rest.strip()


def parse_doc_sections(text: str) -> dict[str, str]:
    sections: dict[str, str] = {}
    for key, aliases in SECTION_ALIASES.items():
        sections[key] = ""
        for alias in aliases:
            body = split_section(text, alias)
            if body:
                sections[key] = body
                break
    return sections


def normalize_pair_key(text: str) -> str:
    key = text.strip().strip("`")
    key = re.sub(r"\s+\([^)]*\)$", "", key)
    key = key.strip().strip("`")
    return key


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
        key = normalize_pair_key(left)
        value = right.strip()
        if key and value:
            items[key] = value
    return items


def parse_markdown_table(section: str) -> dict[str, str]:
    items: dict[str, str] = {}
    for line in section.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        if len(cells) < 2:
            continue
        if set(cells[0]) == {"-"}:
            continue
        header = cells[0].lower()
        if header in {"file", "type", "function", "method", "module", "property", "kind"}:
            continue
        key = normalize_pair_key(cells[0])
        value = cells[1].strip()
        if key and value:
            items[key] = value
    return items


def parse_section_pairs(section: str) -> dict[str, str]:
    merged = parse_markdown_table(section)
    merged.update(parse_bullet_pairs(section))
    return merged


def collect_doc_above(lines: list[str], index: int) -> str:
    docs: list[str] = []
    j = index - 1
    while j >= 0:
        stripped = lines[j].strip()
        if stripped.startswith("///"):
            docs.insert(0, stripped[3:].lstrip())
        elif stripped.startswith("#") or stripped == "":
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


def normalize_impl_target(raw: str) -> str:
    target = raw.split("<", 1)[0].strip().rstrip("{")
    return target.split("::")[-1]


def scan_module_sources(module: str) -> dict:
    module_dir = SRC / module
    file_info = []
    types_by_file: dict[str, list[dict]] = defaultdict(list)
    functions_by_file: dict[str, list[dict]] = defaultdict(list)
    refs: set[str] = set()
    counts = {"struct": 0, "enum": 0, "function": 0}

    for path in sorted(module_dir.rglob("*.rs")):
        rel = path.relative_to(module_dir).as_posix()
        lines = read_text(path).splitlines()
        purpose = first_module_doc_line(lines)
        if not purpose:
            for idx, line in enumerate(lines):
                if TYPE_RE.match(line) or FUNCTION_RE.match(line):
                    purpose = collect_doc_above(lines, idx)
                    break
        file_info.append({"file": rel, "purpose": purpose or "Public API and internal module logic."})

        brace_depth = 0
        pending_impl: Optional[str] = None
        impl_stack: list[dict[str, object]] = []

        for idx, line in enumerate(lines):
            stripped = line.strip()
            is_comment = stripped.startswith("//")

            if not is_comment:
                impl_match = IMPL_RE.match(line)
                if impl_match:
                    pending_impl = normalize_impl_target(impl_match.group(1))

                type_match = TYPE_RE.match(line)
                if type_match:
                    kind, name = type_match.group(1), type_match.group(2)
                    desc = collect_doc_above(lines, idx)
                    types_by_file[rel].append(
                        {
                            "kind": kind,
                            "name": name,
                            "description": desc,
                            "qualified": f"{module}::{Path(rel).stem}::{name}",
                        }
                    )
                    if kind in counts:
                        counts[kind] += 1

                fn_match = FUNCTION_RE.match(line)
                if fn_match:
                    fn_name = fn_match.group(1)
                    desc = collect_doc_above(lines, idx)
                    owner = impl_stack[-1]["name"] if impl_stack else None
                    label = f"{owner}::{fn_name}" if owner else fn_name
                    functions_by_file[rel].append(
                        {
                            "name": label,
                            "description": desc,
                            "qualified": f"{module}::{Path(rel).stem}::{label}",
                        }
                    )
                    counts["function"] += 1

                for ref in USE_RE.findall(line):
                    if ref != module and (SRC / ref).is_dir():
                        refs.add(ref)

            opens = line.count("{")
            closes = line.count("}")
            if pending_impl and opens > closes:
                impl_stack.append({"name": pending_impl, "depth": brace_depth + opens - closes})
                pending_impl = None
            brace_depth += opens - closes
            while impl_stack and brace_depth < int(impl_stack[-1]["depth"]):
                impl_stack.pop()

    return {
        "files": file_info,
        "types_by_file": types_by_file,
        "functions_by_file": functions_by_file,
        "references": sorted(refs),
        "counts": counts,
    }


def collect_lua_api(module: str, lua_parser, seed_texts: list[str]) -> dict:
    all_functions = lua_parser.collect_all_functions(ROOT / "src" / "lua_api")
    funcs = all_functions.get(module, [])
    module_functions = []
    classes: dict[str, list[dict]] = defaultdict(list)
    namespace_prefixes: list[str] = []

    for fn in funcs:
        if fn.lua_name and "." in fn.lua_name:
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
    for text in seed_texts:
        if not text:
            continue
        for pattern in [
            r"`(lurek\.[A-Za-z0-9_.]+)`",
            r"Namespace:\s*`(lurek\.[A-Za-z0-9_.]+)`",
            r"Primary Lua namespace:\s*`(lurek\.[A-Za-z0-9_.]+)`",
        ]:
            match = re.search(pattern, text)
            if match:
                namespace = match.group(1)
                break
        if namespace:
            break

    api_file = ROOT / "src" / "lua_api" / f"{module}_api.rs"
    api_dir = ROOT / "src" / "lua_api" / f"{module}_api"
    if not namespace and api_file.exists():
        match = SET_RE.search(read_text(api_file))
        if match:
            namespace = f"lurek.{match.group(1)}"

    binding_path = ""
    if api_file.exists():
        binding_path = api_file.relative_to(ROOT).as_posix()
    elif api_dir.is_dir():
        binding_path = api_dir.relative_to(ROOT).as_posix() + "/"

    return {
        "namespace": namespace,
        "binding_path": binding_path,
        "module_functions": module_functions,
        "classes": dict(classes),
    }


def normalize_info_key(key: str) -> str:
    lowered = key.lower().replace("`", "")
    lowered = re.sub(r"[^a-z0-9]+", " ", lowered)
    return normalize_space(lowered)


def build_info_maps(spec_text: str, spec_sections: dict[str, str], agent_text: str, agent_sections: dict[str, str], legacy_text: str) -> list[dict[str, str]]:
    maps = [
        parse_section_pairs(spec_sections["general_info"]),
        parse_section_pairs(agent_sections["general_info"]),
        parse_markdown_table(spec_text),
        parse_markdown_table(agent_text),
        parse_markdown_table(legacy_text),
    ]
    normalized_maps: list[dict[str, str]] = []
    for info_map in maps:
        normalized_maps.append({normalize_info_key(k): v for k, v in info_map.items()})
    return normalized_maps


def lookup_info(info_maps: list[dict[str, str]], *labels: str) -> str:
    normalized_labels = [normalize_info_key(label) for label in labels]
    for info_map in info_maps:
        for label in normalized_labels:
            if label in info_map:
                return info_map[label]
    return ""


def combine_pair_maps(*sections: str) -> dict[str, str]:
    merged: dict[str, str] = {}
    for section in sections:
        for key, value in parse_section_pairs(section).items():
            merged.setdefault(key, value)
    return merged


def first_non_empty(*values: str) -> str:
    for value in values:
        if value and value.strip():
            return value.strip()
    return ""


def strip_backticks(text: str) -> str:
    return text.replace("`", "").strip()


def build_scope_boundary(module: str, refs: list[str], group: str) -> str:
    if refs:
        ref_text = ", ".join(f"`{ref}`" for ref in refs[:8])
        if len(refs) > 8:
            ref_text += ", and adjacent engine modules"
        return (
            f"This module primarily collaborates with {ref_text}. "
            f"Its responsibility should stay inside the {group} group rather than absorb behavior owned by those neighbors."
        )
    return (
        f"This module is mostly self-contained inside the {group} group. "
        "Cross-module behavior should stay in the referenced Rust source files and Lua bindings rather than being duplicated here."
    )


def resolve_item_description(overrides: dict[str, str], *keys: str, fallback: str) -> str:
    for key in keys:
        normalized = normalize_pair_key(key)
        if normalized in overrides:
            return overrides[normalized]
    return fallback


def format_general_info(module: str, group: str, rust_tests: str, lua_tests: str, lua_api: dict) -> str:
    lua_paths = f"`{lua_api['binding_path']}`" if lua_api["binding_path"] else "None direct"
    namespace = f"`{lua_api['namespace']}`" if lua_api["namespace"] else "None direct"
    return "\n".join(
        [
            f"- Module group: `{strip_backticks(group)}`",
            f"- Source path: `src/{module}/`",
            f"- Lua API path(s): {lua_paths}",
            f"- Primary Lua namespace: {namespace}",
            f"- Rust test path(s): {strip_backticks(rust_tests) or 'None found in the workspace'}",
            f"- Lua test path(s): {strip_backticks(lua_tests) or 'None found in the workspace'}",
        ]
    )


def format_files(file_rows: list[dict], overrides: dict[str, str]) -> str:
    lines = []
    for row in file_rows:
        desc = resolve_item_description(overrides, row["file"], fallback=row["purpose"])
        lines.append(f"- `{row['file']}`: {desc}")
    return "\n".join(lines)


def format_types(module: str, file_rows: list[dict], types_by_file: dict[str, list[dict]], overrides: dict[str, str]) -> str:
    lines: list[str] = []
    for row in file_rows:
        for item in types_by_file.get(row["file"], []):
            desc = resolve_item_description(
                overrides,
                item["qualified"],
                f"{Path(row['file']).stem}::{item['name']}",
                item["name"],
                fallback=item["description"] or f"Public {item['kind']} in `{row['file']}`.",
            )
            lines.append(f"- `{item['name']}` (`{item['kind']}`, `{row['file']}`): {desc}")
    if not lines:
        return "- No public Rust types are currently exposed from this module."
    return "\n".join(lines)


def format_functions(module: str, file_rows: list[dict], functions_by_file: dict[str, list[dict]], overrides: dict[str, str]) -> str:
    lines: list[str] = []
    for row in file_rows:
        for item in functions_by_file.get(row["file"], []):
            desc = resolve_item_description(
                overrides,
                item["qualified"],
                f"{Path(row['file']).stem}::{item['name']}",
                item["name"],
                fallback=item["description"] or f"Public function or method declared in `{row['file']}`.",
            )
            lines.append(f"- `{item['name']}` (`{row['file']}`): {desc}")
    if not lines:
        return "- No public Rust functions are currently exposed from this module."
    return "\n".join(lines)


def format_lua_api(lua_api: dict) -> str:
    if not lua_api["namespace"] and not lua_api["module_functions"] and not lua_api["classes"]:
        return "- No dedicated direct `lurek.*` namespace is exposed by this module."

    lines: list[str] = []
    if lua_api["binding_path"]:
        lines.append(f"- Binding path(s): `{lua_api['binding_path']}`")
    if lua_api["namespace"]:
        lines.append(f"- Namespace: `{lua_api['namespace']}`")

    if lua_api["module_functions"]:
        lines.extend(["", "### Module Functions"])
        for fn in lua_api["module_functions"]:
            label = fn["lua_name"] or fn["name"]
            lines.append(f"- `{label}`: {fn['description']}")

    for class_name, methods in sorted(lua_api["classes"].items()):
        lines.extend(["", f"### `{class_name}` Methods"])
        for method in methods:
            lines.append(f"- `{class_name}:{method['name']}`: {method['description']}")

    return "\n".join(lines).strip()


def reference_note(group: str, dep_group: str) -> str:
    if group == dep_group:
        return f"Dependency stays inside `{group}` and should remain acyclic."
    return f"Cross-group dependency from `{group}` into `{dep_group}`."


def format_references(group: str, refs: list[str], overrides: dict[str, str]) -> str:
    if not refs:
        return "- No top-level `crate::<module>` imports were detected in this module's Rust source files."

    lines = []
    for ref in refs:
        desc = resolve_item_description(
            overrides,
            ref,
            fallback=f"Imports or references `src/{ref}/`. {reference_note(group, module_group(ref))}",
        )
        lines.append(f"- `{ref}`: {desc}")
    return "\n".join(lines)


def build_default_notes(module: str, lua_api: dict) -> str:
    lines = [
        f"- Keep this module reference synchronized with `src/{module}/` and any matching Lua bindings.",
        "- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.",
    ]
    if not lua_api["namespace"]:
        lines.append("- This module has no dedicated direct `lurek.*` namespace and is usually consumed through higher integration layers.")
    return "\n".join(lines)


def build_spec(module: str, lua_parser) -> tuple[str, dict]:
    spec_path = SPECS / f"{module}.md"
    spec_text = read_text(spec_path)
    agent_text = read_text(SRC / module / "AGENT.md")
    legacy_text = read_text(SRC / module / "AGENT.legacy.md")

    spec_sections = parse_doc_sections(spec_text)
    agent_sections = parse_doc_sections(agent_text)
    legacy_sections = parse_doc_sections(legacy_text)
    source = scan_module_sources(module)
    lua_api = collect_lua_api(module, lua_parser, [spec_text, agent_text, legacy_text])

    info_maps = build_info_maps(spec_text, spec_sections, agent_text, agent_sections, legacy_text)
    rust_tests = lookup_info(info_maps, "Rust test path(s)", "Rust Tests") or "None found in the workspace"
    lua_tests = lookup_info(info_maps, "Lua test path(s)", "Lua Tests") or "None found in the workspace"

    group = module_group(module)
    if group == "Edge/Integration":
        # Fall back to spec/agent metadata only if not explicitly in GROUPS
        meta_group = lookup_info(info_maps, "Module group", "Group")
        if meta_group and module not in {m for mods in GROUPS.values() for m in mods}:
            group = meta_group
    summary_text = first_non_empty(spec_sections["summary"], agent_sections["summary"], legacy_sections["summary"])
    if not summary_text:
        summary_text = (
            f"The `{module}` module is documented from the current source tree and existing module reference data.\n\n"
            f"{build_scope_boundary(module, source['references'], group)}"
        )
    elif "\n\n" not in summary_text:
        summary_text = summary_text + "\n\n" + build_scope_boundary(module, source["references"], group)

    file_overrides = combine_pair_maps(spec_sections["files"], agent_sections["files"], legacy_sections["files"])
    type_overrides = combine_pair_maps(spec_sections["types"], agent_sections["types"], legacy_sections["types"])
    function_overrides = combine_pair_maps(spec_sections["functions"], legacy_sections["functions"])
    reference_overrides = combine_pair_maps(spec_sections["references"], legacy_sections["references"])
    notes_text = first_non_empty(spec_sections["notes"], legacy_sections["notes"])
    if not notes_text or "AGENT" in notes_text:
        notes_text = build_default_notes(module, lua_api)

    general_info = format_general_info(module, group, rust_tests, lua_tests, lua_api)
    files_text = format_files(source["files"], file_overrides)
    types_text = format_types(module, source["files"], source["types_by_file"], type_overrides)
    functions_text = format_functions(module, source["files"], source["functions_by_file"], function_overrides)
    lua_api_text = format_lua_api(lua_api)
    references_text = format_references(group, source["references"], reference_overrides)

    content = f"""# {module}

## General Info

{general_info}

## Summary

{summary_text}

## Files

{files_text}

## Types

{types_text}

## Functions

{functions_text}

## Lua API Reference

{lua_api_text}

## References

{references_text}

## Notes

{notes_text}
"""

    inventory = {
        "group": group,
        "namespace": lua_api["namespace"],
        "rust_tests": rust_tests,
        "lua_tests": lua_tests,
        "references": source["references"],
        "file_count": len(source["files"]),
        "type_count": sum(len(items) for items in source["types_by_file"].values()),
        "function_count": sum(len(items) for items in source["functions_by_file"].values()),
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
    parser = argparse.ArgumentParser(description="Generate merged docs/specs/*.md files for top-level src modules.")
    parser.add_argument("--module", action="append", help="Only generate the named module (can be repeated).")
    args = parser.parse_args()

    lua_parser = load_lua_parser()
    modules = sorted(p.name for p in SRC.iterdir() if p.is_dir())
    if args.module:
        selected = set(args.module)
        modules = [module for module in modules if module in selected]

    SPECS.mkdir(parents=True, exist_ok=True)
    SESSION_DATA.parent.mkdir(parents=True, exist_ok=True)

    inventory: dict[str, dict] = {}
    for module in modules:
        content, meta = build_spec(module, lua_parser)
        (SPECS / f"{module}.md").write_text(content.rstrip() + "\n", encoding="utf-8")
        inventory[module] = meta

    if not args.module:
        rewrite_readme(sorted(p.name for p in SRC.iterdir() if p.is_dir()))

    SESSION_DATA.write_text(json.dumps(inventory, indent=2, sort_keys=True), encoding="utf-8")
    print(f"Generated {len(modules)} module spec files.")


if __name__ == "__main__":
    main()
