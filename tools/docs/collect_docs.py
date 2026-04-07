#!/usr/bin/env python3
"""
collect_docs.py — Luna2D rich structured API documentation collector.

Walks src/, parses every *.rs file, extracts public items together with
their /// doc comments, and generates a rich Markdown reference or reports
missing/incomplete documentation.

Usage:
    python tools/collect_docs.py                  # generate docs/API/api_generated.md
    python tools/collect_docs.py --report-missing # print items missing docs (exit 1 if any)
    python tools/collect_docs.py --suggest        # print starter /// lines for undocumented items
    python tools/collect_docs.py --output FILE    # custom output path
    python tools/collect_docs.py --src DIR        # custom source directory
    python tools/collect_docs.py --help

Exit codes:
    0  — success (or no issues when --report-missing is used)
    1  — missing docs or incomplete sections found (--report-missing only)
    2  — fatal error (bad arguments, missing source directory)
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

# ── Configuration ─────────────────────────────────────────────────────────────

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
SRC_DIR = WORKSPACE_ROOT / "src"
OUTPUT_FILE = WORKSPACE_ROOT / "docs" / "API" / "api_generated.md"

# Matches the beginning of a pub item declaration (at any indentation level).
_PUB_DECL_RE = re.compile(
    r"^pub(?:\([^)]*\))?\s+"
    r"(?:unsafe\s+|async\s+|const\s+|extern\s+\"[^\"]*\"\s+)?"
    r"(struct|enum|fn|trait|type|const|static|mod)"
    r"\s+([A-Za-z_][A-Za-z0-9_]*)"
)

# Matches an impl block header at the start of a stripped line.
_IMPL_HEADER_RE = re.compile(
    r"^impl(?:<[^>]*>)?\s+"
    r"(?:(?:[\w<>, :&'*]+)\s+for\s+)?"
    r"([A-Za-z_]\w*)"
)

# Matches a section header like `# Parameters` inside a doc comment.
_SECTION_RE = re.compile(r"^#\s+(.+?)\s*$")

# Matches a description-list item: `- \`name\` — description`
_ITEM_RE = re.compile(r"^-\s+`?([A-Za-z_][A-Za-z0-9_<>]*)`?\s*(?:—|–|--|-)\s+(.*)")


# ── Data classes ──────────────────────────────────────────────────────────────


@dataclass
class StructField:
    """One field parsed from a struct body."""

    name: str
    type_str: str
    is_pub: bool
    doc: str = ""


@dataclass
class EnumVariant:
    """One variant parsed from an enum body."""

    name: str
    doc: str = ""


@dataclass
class ApiItem:
    """One public Rust item found in a source file."""

    file: Path            # relative to WORKSPACE_ROOT
    line: int             # 1-based line of the declaration
    kind: str             # struct | enum | fn | trait | type | const | static | mod
    name: str             # identifier (may be prefixed: TypeName::method)
    signature: str        # full declaration up to { or ; (may span original lines)
    description: str      # first prose paragraph
    purpose: str          # second prose paragraph (may be "")
    sections: dict        # case-preserved section name -> list[str] of content lines
    raw_doc: list         # raw stripped lines of the full doc comment
    fields: list = field(default_factory=list)    # list[StructField]
    variants: list = field(default_factory=list)  # list[EnumVariant]

    @property
    def has_docs(self) -> bool:
        return bool(self.description)


# ── Helper: module path ──────────────────────────────────────────────────────


def _module_path(file_rel: Path) -> str:
    """Derive a Rust module path hint from a file's workspace-relative path."""
    parts = list(file_rel.with_suffix("").parts)
    # Drop leading "src" if present
    if parts and parts[0] == "src":
        parts = parts[1:]
    if parts and parts[-1] == "mod":
        parts = parts[:-1]
    if not parts or parts[0] in ("lib", "main"):
        return "root"
    return "::".join(parts)


def _file_anchor(rel_path: Path, line: int) -> str:
    """Return a Markdown link label pointing to a source line."""
    fwd = str(rel_path).replace("\\", "/")
    return f"[line {line}]({fwd}#L{line})"


# ── Helper: module-level doc (//! comments) ───────────────────────────────────


def _collect_module_doc(path: Path) -> str:
    """Return the leading //! block of a file as a plain string."""
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return ""
    doc_parts: list[str] = []
    for raw in lines:
        stripped = raw.strip()
        if stripped.startswith("//!"):
            text = stripped[3:]
            doc_parts.append(text[1:] if text.startswith(" ") else text)
        elif doc_parts:
            break  # stop after the first non-//! line once we have started collecting
    return "\n".join(doc_parts).strip()


# ── Helper: parse doc comment into structured sections ────────────────────────


def _parse_doc_sections(
    raw_lines: list[str],
) -> tuple[str, str, dict[str, list[str]]]:
    """
    Split raw doc-comment lines into (description, purpose, sections).

    description -- first prose paragraph (before any blank line or section header)
    purpose     -- second prose paragraph, may be ""
    sections    -- dict mapping section name to content lines (blank-stripped)
    """
    if not raw_lines:
        return "", "", {}

    pre_lines: list[str] = []
    sections: dict[str, list[str]] = {}
    current_section: str | None = None

    for ln in raw_lines:
        m = _SECTION_RE.match(ln)
        if m:
            current_section = m.group(1)
            sections[current_section] = []
        elif current_section is not None:
            sections[current_section].append(ln)
        else:
            pre_lines.append(ln)

    # Strip leading/trailing blank lines from each section's content
    for key in sections:
        content = sections[key]
        while content and content[0] == "":
            content.pop(0)
        while content and content[-1] == "":
            content.pop()

    # Split pre-section lines into paragraphs (separated by blank lines)
    paragraphs: list[list[str]] = [[]]
    for ln in pre_lines:
        if ln == "":
            if paragraphs[-1]:
                paragraphs.append([])
        else:
            paragraphs[-1].append(ln)
    paragraphs = [p for p in paragraphs if p]

    description = " ".join(paragraphs[0]) if paragraphs else ""
    purpose = " ".join(paragraphs[1]) if len(paragraphs) > 1 else ""

    return description, purpose, sections


# ── Helper: collect multi-line signature ──────────────────────────────────────


def _collect_signature(lines: list[str], start: int, kind: str) -> str:
    """
    Collect the full item signature, joining continuation lines as needed.

    For fn: read until the first line that contains { or ;.
    For struct: read until { or ; or ( (tuple struct).
    For type/const/static: single line, cut at ;.
    For all others (enum, trait, mod): single declaration line, cut at { or ;.
    """
    if kind in ("type", "const", "static"):
        stripped = lines[start].strip()
        idx = stripped.find(";")
        return stripped[:idx].strip() if idx != -1 else stripped

    parts: list[str] = []
    j = start
    while j < len(lines) and j <= start + 30:
        stripped = lines[j].strip()
        parts.append(stripped)
        if kind == "fn":
            if "{" in stripped or ";" in stripped:
                break
        elif kind == "struct":
            if "{" in stripped or ";" in stripped or "(" in stripped:
                break
        else:
            # enum, trait, mod: single declaration line
            break
        j += 1

    full = " ".join(parts)

    # Cut at the appropriate terminator
    if kind == "fn":
        for sep in ["{", ";"]:
            idx = full.find(sep)
            if idx != -1:
                full = full[:idx]
                break
    elif kind == "struct":
        candidates = []
        for sep in ["{", ";", "("]:
            idx = full.find(sep)
            if idx != -1:
                candidates.append((idx, sep))
        if candidates:
            first_idx = min(candidates, key=lambda x: x[0])[0]
            full = full[:first_idx]
    else:
        for sep in ["{", ";"]:
            idx = full.find(sep)
            if idx != -1:
                full = full[:idx]
                break

    return full.strip()


# ── Helper: extract struct fields ─────────────────────────────────────────────


def _extract_struct_fields(lines: list[str], item_start: int) -> list[StructField]:
    """Parse all fields from a struct body."""
    # Find the opening { of the struct body
    j = item_start
    while j < len(lines) and j < item_start + 10:
        stripped = lines[j].strip()
        if "{" in stripped and not stripped.startswith("#") and not stripped.startswith("///"):
            j += 1
            break
        if ";" in stripped:
            return []  # unit struct (no body)
        j += 1
    else:
        return []

    depth = 1
    fields: list[StructField] = []
    doc_ahead: list[str] = []

    while j < len(lines):
        stripped = lines[j].strip()

        if stripped.startswith("///"):
            text = stripped[3:]
            doc_ahead.append(text[1:] if text.startswith(" ") else text)
            j += 1
            continue

        if stripped.startswith("#[") or stripped.startswith("#!"):
            j += 1
            continue

        depth += stripped.count("{") - stripped.count("}")
        if depth <= 0:
            break

        if stripped:
            field_m = re.match(
                r"^(?:pub(?:\([^)]*\))?\s+)?([a-z_][a-zA-Z0-9_]*)\s*:\s*(.+)",
                stripped,
            )
            if field_m:
                is_pub = bool(re.match(r"^pub\b", stripped))
                fields.append(
                    StructField(
                        name=field_m.group(1),
                        type_str=field_m.group(2).strip().rstrip(","),
                        is_pub=is_pub,
                        doc=" ".join(doc_ahead).strip(),
                    )
                )
            if not stripped.startswith("///"):
                doc_ahead.clear()

        j += 1

    return fields


# ── Helper: extract enum variants ─────────────────────────────────────────────


def _extract_enum_variants(lines: list[str], item_start: int) -> list[EnumVariant]:
    """Parse all variant names from an enum body."""
    # Find the opening { of the enum body
    j = item_start
    while j < len(lines) and j < item_start + 5:
        if "{" in lines[j] and not lines[j].strip().startswith("#"):
            j += 1
            break
        j += 1
    else:
        return []

    depth = 1
    variants: list[EnumVariant] = []
    doc_ahead: list[str] = []

    while j < len(lines):
        stripped = lines[j].strip()

        if stripped.startswith("///"):
            if depth == 1:
                text = stripped[3:]
                doc_ahead.append(text[1:] if text.startswith(" ") else text)
            j += 1
            continue

        if stripped.startswith("#[") or stripped.startswith("#!"):
            # Skip attribute lines; do NOT count their braces
            # (attributes like #[error("{0}")] contain { } inside string args)
            j += 1
            continue

        old_depth = depth
        depth += stripped.count("{") - stripped.count("}")

        if old_depth == 1 and stripped:
            variant_m = re.match(r"^([A-Z][A-Za-z0-9_]*)", stripped)
            if variant_m:
                variants.append(
                    EnumVariant(
                        name=variant_m.group(1),
                        doc=" ".join(doc_ahead).strip(),
                    )
                )
            if not stripped.startswith("///"):
                doc_ahead.clear()

        if depth <= 0:
            break

        j += 1

    return variants


# ── Helper: impl context tracking ─────────────────────────────────────────────


def _get_impl_type(impl_stack: list[tuple[int, str]], brace_depth: int) -> str | None:
    """Return the innermost impl type name currently in scope."""
    for entry_depth, tname in reversed(impl_stack):
        if brace_depth >= entry_depth:
            return tname
    return None


def _trim_impl_stack(impl_stack: list[tuple[int, str]], brace_depth: int) -> None:
    """Remove impl-stack entries whose scope has been exited."""
    while impl_stack and impl_stack[-1][0] > brace_depth:
        impl_stack.pop()


# ── Parser ────────────────────────────────────────────────────────────────────


def collect_items_from_file(path: Path) -> list[ApiItem]:
    """Return all public items (with structured doc comments) from one .rs file."""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        print(f"[ERROR] Cannot read {path}: {e}", file=sys.stderr)
        return []

    lines = text.splitlines()
    rel_path = path.relative_to(WORKSPACE_ROOT)
    items: list[ApiItem] = []

    brace_depth: int = 0
    impl_stack: list[tuple[int, str]] = []  # (entry_depth_after_opening, type_name)
    doc_buffer: list[str] = []

    i = 0
    while i < len(lines):
        raw = lines[i]
        stripped = raw.strip()

        # ── Doc comments ────────────────────────────────────────────────────
        if stripped.startswith("///"):
            text_part = stripped[3:]
            doc_buffer.append(text_part[1:] if text_part.startswith(" ") else text_part)
            i += 1
            continue

        # ── Attribute lines: preserve doc buffer, skip brace counting ───────
        if stripped.startswith("#[") or stripped.startswith("#!"):
            i += 1
            continue

        # ── Blank lines and regular comments: clear doc buffer ──────────────
        if not stripped or (stripped.startswith("//") and not stripped.startswith("///")):
            doc_buffer.clear()
            i += 1
            continue

        # ── Compute net braces for this line ─────────────────────────────────
        net_braces = stripped.count("{") - stripped.count("}")

        # ── Impl block header ────────────────────────────────────────────────
        impl_m = _IMPL_HEADER_RE.match(stripped)
        if impl_m and not stripped.startswith("pub"):
            type_name = impl_m.group(1)
            if net_braces > 0:
                impl_stack.append((brace_depth + 1, type_name))
            brace_depth += net_braces
            _trim_impl_stack(impl_stack, brace_depth)
            doc_buffer.clear()
            i += 1
            continue

        # ── Pub item declaration ─────────────────────────────────────────────
        pub_m = _PUB_DECL_RE.match(stripped)
        if pub_m:
            kind = pub_m.group(1)
            name = pub_m.group(2)
            item_line = i + 1  # 1-based

            impl_type = _get_impl_type(impl_stack, brace_depth)
            sig = _collect_signature(lines, i, kind)
            description, purpose, sections = _parse_doc_sections(doc_buffer)
            full_name = f"{impl_type}::{name}" if impl_type else name

            item_fields: list[StructField] = []
            item_variants: list[EnumVariant] = []
            if kind == "struct":
                item_fields = _extract_struct_fields(lines, i)
            elif kind == "enum":
                item_variants = _extract_enum_variants(lines, i)

            items.append(
                ApiItem(
                    file=rel_path,
                    line=item_line,
                    kind=kind,
                    name=full_name,
                    signature=sig,
                    description=description,
                    purpose=purpose,
                    sections=sections,
                    raw_doc=list(doc_buffer),
                    fields=item_fields,
                    variants=item_variants,
                )
            )
            doc_buffer.clear()
        else:
            # Any other code line: clear doc buffer
            doc_buffer.clear()

        # ── Update brace depth ───────────────────────────────────────────────
        brace_depth += net_braces
        _trim_impl_stack(impl_stack, brace_depth)

        i += 1

    return items


def collect_all(src_dir: Path = SRC_DIR) -> list[ApiItem]:
    """Walk src_dir and return all public items sorted by file then line."""
    all_items: list[ApiItem] = []
    for rs_file in sorted(src_dir.rglob("*.rs")):
        all_items.extend(collect_items_from_file(rs_file))
    return all_items


def collect_module_docs(src_dir: Path = SRC_DIR) -> dict[str, str]:
    """Return a dict mapping module path to module-level //! doc string."""
    result: dict[str, str] = {}
    for rs_file in sorted(src_dir.rglob("*.rs")):
        rel = rs_file.relative_to(WORKSPACE_ROOT)
        mod_path = _module_path(rel)
        doc = _collect_module_doc(rs_file)
        if doc:
            result[mod_path] = doc
    return result


def render_json(items: list[ApiItem], src_dir: Path = SRC_DIR) -> str:
    """Produce structured JSON with all items plus module-level docs."""
    module_docs = collect_module_docs(src_dir)
    items_list = []
    for item in items:
        obj = {
            "file": str(item.file).replace("\\", "/"),
            "line": item.line,
            "kind": item.kind,
            "name": item.name,
            "signature": item.signature,
            "description": item.description,
            "purpose": item.purpose,
            "sections": item.sections,
            "has_docs": item.has_docs,
        }
        if item.kind == "struct" and item.fields:
            obj["fields"] = [
                {"name": f.name, "type": f.type_str, "is_pub": f.is_pub, "doc": f.doc}
                for f in item.fields
            ]
        if item.kind == "enum" and item.variants:
            obj["variants"] = [
                {"name": v.name, "doc": v.doc}
                for v in item.variants
            ]
        items_list.append(obj)

    return json.dumps(
        {"module_docs": module_docs, "items": items_list},
        indent=2,
        ensure_ascii=False,
    )


# ── Markdown section renderer ─────────────────────────────────────────────────


def _render_section(name: str, content: list[str]) -> list[str]:
    """Render one doc-comment section to Markdown lines."""
    out: list[str] = []
    name_lower = name.lower()

    if name_lower == "parameters":
        out += ["**Parameters:**", ""]
        out += ["| Parameter | Description |", "|-----------|-------------|"]
        for ln in content:
            m = _ITEM_RE.match(ln)
            if m:
                out.append(f"| `{m.group(1)}` | {m.group(2).strip()} |")
        out.append("")

    elif name_lower == "fields":
        out += ["**Fields:**", ""]
        out += ["| Field | Description |", "|-------|-------------|"]
        for ln in content:
            m = _ITEM_RE.match(ln)
            if m:
                out.append(f"| `{m.group(1)}` | {m.group(2).strip()} |")
        out.append("")

    elif name_lower == "variants":
        out += ["**Variants:**", ""]
        out += ["| Variant | Description |", "|---------|-------------|"]
        for ln in content:
            m = _ITEM_RE.match(ln)
            if m:
                out.append(f"| `{m.group(1)}` | {m.group(2).strip()} |")
        out.append("")

    elif name_lower == "returns":
        text = " ".join(ln for ln in content if ln)
        out += [f"**Returns:** {text}", ""]

    elif name_lower == "examples":
        out += ["**Examples:**", ""]
        for ln in content:
            out.append(ln)
        out.append("")

    elif name_lower == "errors":
        out += ["**Errors:**", ""]
        for ln in content:
            out.append(ln)
        out.append("")

    else:
        out += [f"**{name}:**", ""]
        for ln in content:
            out.append(ln)
        out.append("")

    return out


def _render_auto_fields(fields: list[StructField]) -> list[str]:
    """Render auto-extracted struct fields as a Markdown table."""
    out = ["**Fields:**", ""]
    out += ["| Field | Type | Description |", "|-------|------|-------------|"]
    for f in fields:
        if f.is_pub:
            desc = f.doc if f.doc else ""
            out.append(f"| `{f.name}` | `{f.type_str}` | {desc} |")
        else:
            out.append(f"| `{f.name}` | | *(private)* |")
    out.append("")
    return out


def _render_auto_variants(variants: list[EnumVariant]) -> list[str]:
    """Render auto-extracted enum variants as a Markdown table."""
    out = ["**Variants:**", ""]
    out += ["| Variant | Description |", "|---------|-------------|"]
    for v in variants:
        out.append(f"| `{v.name}` | {v.doc} |")
    out.append("")
    return out


# ── Markdown renderer ─────────────────────────────────────────────────────────


def render_markdown(items: list[ApiItem], src_dir: Path = SRC_DIR) -> str:
    """Produce the full rich API reference Markdown document."""
    # ── Coverage stats ────────────────────────────────────────────────────────
    total = len(items)
    documented = sum(1 for i in items if i.has_docs)
    pct = (documented / total * 100) if total else 0.0

    lines: list[str] = [
        "# Luna2D — Generated API Reference",
        "",
        "> Auto-generated by `tools/collect_docs.py`. Do not edit by hand.",
        "> Re-run the tool after changing source files.",
        "",
        f"> **Coverage:** {documented}/{total} public items documented ({pct:.0f}%)",
        "",
    ]

    # ── Table of Contents ─────────────────────────────────────────────────────
    lines += ["## Contents", ""]
    seen_modules: list[str] = []
    for item in items:
        mod = _module_path(item.file)
        if not seen_modules or seen_modules[-1] != mod:
            seen_modules.append(mod)

    for mod in seen_modules:
        anchor = mod.replace("::", "-").replace("_", "-").lower()
        lines.append(f"- [`{mod}`](#{anchor})")
    lines += ["", "---", ""]

    current_file: Path | None = None

    for item in items:
        # ── Module header (once per file) ────────────────────────────────────
        if item.file != current_file:
            if current_file is not None:
                lines.append("")

            current_file = item.file
            mod = _module_path(item.file)
            abs_path = WORKSPACE_ROOT / item.file
            fwd_rel = str(item.file).replace("\\", "/")

            anchor = mod.replace("::", "-").replace("_", "-").lower()
            lines += [f"## Module: `{mod}` {{#{anchor}}}", ""]
            lines += [f"*Source: `{fwd_rel}`*", ""]

            module_doc = _collect_module_doc(abs_path)
            if module_doc:
                lines += [module_doc, ""]

            lines.append("---")
            lines.append("")

        # ── Item heading ─────────────────────────────────────────────────────
        anchor = _file_anchor(item.file, item.line)
        lines.append(f"### `{item.kind} {item.name}`  · {anchor}")
        lines.append("")

        # ── Description ──────────────────────────────────────────────────────
        if item.description:
            lines.append(item.description)
            lines.append("")
        else:
            lines.append("*No documentation.*")
            lines.append("")

        # ── Purpose (second paragraph) ───────────────────────────────────────
        if item.purpose:
            lines.append(item.purpose)
            lines.append("")

        # ── Signature ────────────────────────────────────────────────────────
        if item.kind != "mod":
            lines += ["**Signature:**", "```rust", item.signature, "```", ""]

        # ── Doc-comment sections ──────────────────────────────────────────────
        section_names_lower = {k.lower() for k in item.sections}

        for sec_name, sec_content in item.sections.items():
            lines += _render_section(sec_name, sec_content)

        # ── Auto-generated fields (if no # Fields doc section) ───────────────
        if item.kind == "struct" and item.fields and "fields" not in section_names_lower:
            lines += _render_auto_fields(item.fields)

        # ── Auto-generated variants (if no # Variants doc section) ───────────
        if item.kind == "enum" and item.variants and "variants" not in section_names_lower:
            lines += _render_auto_variants(item.variants)

        lines += ["---", ""]

    return "\n".join(lines)


# ── Missing-doc reporter ──────────────────────────────────────────────────────


def _has_explicit_params(sig: str) -> bool:
    """Return True if a fn has parameters other than self variants and Lua plumbing."""
    # Pre-normalise _:()\n patterns so the [^)]* regex isn't confused by the
    # closing paren inside `_: ()` — the unit-tuple "no Lua args" marker.
    sig_norm = re.sub(r"_\s*:\s*\(\)", "_: __UNIT__", sig)
    # Anchor to fn name to skip pub(super)/pub(crate) visibility qualifiers.
    m = re.search(r"\bfn\s+\w+(?:<[^>]*>)?\s*\(([^)]*)\)", sig_norm)
    if not m:
        return False
    params_str = m.group(1).strip()
    if not params_str:
        return False
    for param in params_str.split(","):
        p = param.strip()
        if not p:
            continue
        # Skip self variants
        if re.match(r"^(&\s*(mut\s+)?)?self\s*$", p):
            continue
        # Skip Lua VM context: lua: &Lua, _lua: &Lua, _lua: &mlua::Lua
        if re.match(r"^_?lua\s*:\s*&\s*(mut\s+)?(?:mlua::)?Lua\b", p):
            continue
        # Skip unit-tuple args: _: () → normalised to _: __UNIT__
        if p == "_: __UNIT__":
            continue
        # Skip Lua registration plumbing: luna: &Table/&mlua::Table
        if re.match(r"^_?\w+\s*:\s*&\s*(mut\s+)?(?:mlua::)?Table\b", p):
            continue
        # Skip shared-state plumbing: _state: Rc<...>, Arc<...>
        # Skip Lua registration plumbing: luna: &Table/&mlua::Table
        if re.match(r"^_?\w+\s*:\s*&\s*(mut\s+)?(?:mlua::)?Table\b", p):
            continue
        # Skip shared-state plumbing: _state: Rc<...>, Arc<...>
        if re.match(r"^_?\w+\s*:\s*(?:Rc<|Arc<)", p):
            continue
        return True
    return False


def _has_return_type(sig: str) -> bool:
    """Return True if a fn signature has a non-trivial return type.

    ``LuaResult<()>`` is treated as "no meaningful return" because it just
    signals Lua error/ok without returning a value to Lua scripts.
    """
    m = re.search(r"\)\s*->\s*(.+)$", sig.strip())
    if not m:
        return False
    ret = m.group(1).strip()
    if not ret or ret == "()":
        return False
    # LuaResult<()> wraps a unit — no actual return value to document
    if re.match(r"^LuaResult\s*<\s*\(\)\s*>$", ret):
        return False
    return True


def _has_tagged_params(raw_doc: list) -> bool:
    """Return True if any ``@param`` tag is present in the raw doc lines."""
    return any(ln.strip().startswith("@param") for ln in raw_doc)


def _has_tagged_return(raw_doc: list) -> bool:
    """Return True if any ``@return`` tag is present in the raw doc lines."""
    return any(ln.strip().startswith("@return") for ln in raw_doc)


def report_missing(items: list[ApiItem]) -> int:
    """
    Print all items that lack documentation or are missing expected sections.

    Returns 1 if any [ERROR] or [WARN] lines were emitted, 0 otherwise.
    """
    print("[INFO] Scanning src/ ...")
    print()

    error_count = 0
    warn_count = 0

    for item in items:
        fwd = str(item.file).replace("\\", "/")
        loc = f"{fwd}:{item.line}"
        kind_name = f"{item.kind} {item.name}"

        if not item.description:
            print(f"[ERROR] {loc:<50}  {kind_name} -- no documentation at all")
            error_count += 1
            continue

        has = {s.lower() for s in item.sections}

        if item.kind == "fn":
            if _has_explicit_params(item.signature) and "parameters" not in has and not _has_tagged_params(item.raw_doc):
                print(f"[WARN]  {loc:<50}  {kind_name} -- missing # Parameters section")
                warn_count += 1
            if _has_return_type(item.signature) and "returns" not in has and not _has_tagged_return(item.raw_doc):
                print(f"[WARN]  {loc:<50}  {kind_name} -- missing # Returns section")
                warn_count += 1

        elif item.kind == "struct":
            pub_fields = [f for f in item.fields if f.is_pub]
            if pub_fields and "fields" not in has:
                print(f"[WARN]  {loc:<50}  {kind_name} -- missing # Fields section")
                warn_count += 1

        elif item.kind == "enum":
            if item.variants and "variants" not in has:
                print(f"[WARN]  {loc:<50}  {kind_name} -- missing # Variants section")
                warn_count += 1

    total = len(items)
    missing = error_count
    missing_sections = warn_count

    print()
    print(
        f"[INFO] Total items: {total}  |  "
        f"Missing docs: {missing}  |  "
        f"Missing sections: {missing_sections}"
    )

    return 1 if (error_count > 0 or warn_count > 0) else 0


# ── Suggestion helper ─────────────────────────────────────────────────────────

_KIND_HINTS: dict[str, str] = {
    "struct": "Represents {name}.",
    "enum": "Variants of {name}.",
    "fn": "Performs the {name} operation.",
    "trait": "Trait implemented by {name} types.",
    "type": "Type alias for {name}.",
    "const": "Constant value {name}.",
    "static": "Static value {name}.",
    "mod": "Module {name}.",
}


def suggest_docstring(item: ApiItem) -> str:
    """Return a minimal starter /// doc comment for an undocumented item."""
    base_name = item.name.split("::")[-1]
    template = _KIND_HINTS.get(item.kind, "Item {name}.")
    text = template.format(name=base_name)
    doc_lines = [f"/// {text}"]

    if item.kind == "fn":
        if _has_explicit_params(item.signature):
            doc_lines += ["///", "/// # Parameters", "/// - `param` — description"]
        if _has_return_type(item.signature):
            doc_lines += ["///", "/// # Returns", "/// Description of return value."]

    elif item.kind == "struct" and item.fields:
        pub_fields = [f for f in item.fields if f.is_pub]
        if pub_fields:
            doc_lines += ["///", "/// # Fields"]
            for f in pub_fields:
                doc_lines.append(f"/// - `{f.name}` — description")

    elif item.kind == "enum" and item.variants:
        doc_lines += ["///", "/// # Variants"]
        for v in item.variants:
            doc_lines.append(f"/// - `{v.name}` — description")

    return "\n".join(doc_lines)


def print_suggestions(items: list[ApiItem]) -> None:
    """Print starter /// lines for all items that currently lack docs."""
    missing = [i for i in items if not i.has_docs]
    if not missing:
        print("[OK] Nothing to suggest — all items are documented.")
        return

    print(f"[INFO] Starter doc suggestions for {len(missing)} item(s):\n")
    for item in missing:
        fwd = str(item.file).replace("\\", "/")
        print(f"  # {fwd}:{item.line}  ({item.kind} {item.name})")
        print(f"  {suggest_docstring(item)}")
        print()


# ── CLI ───────────────────────────────────────────────────────────────────────


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="collect_docs.py",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument(
        "--report-missing",
        action="store_true",
        help=(
            "Print public items that lack /// doc comments or expected sections "
            "(# Parameters, # Returns, # Fields, # Variants). "
            "Exit 1 if any issues are found."
        ),
    )
    p.add_argument(
        "--suggest",
        action="store_true",
        help="Print minimal starter /// doc lines for all undocumented public items.",
    )
    p.add_argument(
        "--json",
        action="store_true",
        help="Output structured JSON instead of Markdown (includes module docs).",
    )
    p.add_argument(
        "--output",
        metavar="FILE",
        default=str(OUTPUT_FILE),
        help=f"Output path for the generated Markdown (default: {OUTPUT_FILE}).",
    )
    p.add_argument(
        "--src",
        metavar="DIR",
        default=str(SRC_DIR),
        help=f"Source directory to scan (default: {SRC_DIR}).",
    )
    return p


def main() -> int:
    args = build_parser().parse_args()
    src_dir = Path(args.src)

    if not src_dir.exists():
        print(f"[ERROR] Source directory not found: {src_dir}", file=sys.stderr)
        return 2

    print(f"[INFO] Scanning {src_dir} ...")
    items = collect_all(src_dir)
    print(f"[INFO] Found {len(items)} public items across {src_dir}.")

    if args.report_missing:
        return report_missing(items)

    if args.suggest:
        print_suggestions(items)
        return 0

    if args.json:
        output = Path(args.output)
        output.parent.mkdir(parents=True, exist_ok=True)
        j = render_json(items, src_dir)
        output.write_text(j, encoding="utf-8")
        print(f"[OK] Generated JSON for {len(items)} items -> {output}")
        return 0

    # Default: generate full Markdown
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    md = render_markdown(items, src_dir)
    output.write_text(md, encoding="utf-8")
    print(f"[OK] Generated {len(items)} items -> {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
