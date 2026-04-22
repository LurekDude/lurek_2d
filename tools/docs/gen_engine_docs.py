#!/usr/bin/env python3
"""
gen_engine_docs.py — Generate per-module documentation for Lurek2D Rust engine source.

Reads all src/**/*.rs EXCEPT src/lua_api/ and produces one Markdown file per
top-level module (e.g. src/timer/*.rs → docs/reports/engine/timer.md).

Parses standard Rust docstring conventions as used in this codebase:

    //! module-level doc (mod.rs or file header)
    /// One-line or multi-line summary.
    ///
    /// # Fields
    /// - `name` — `Type`.
    ///
    /// # Variants
    /// - `Name` — Variant description.
    ///
    /// # Parameters
    /// - `name` — `Type`.
    ///
    /// # Returns
    /// `ReturnType`

    pub struct / pub enum / pub fn / pub trait / pub type

Output goes to docs/reports/engine/<module>.md.
Intended audience: Lurek2D engine contributors (Rust developers).

Usage:
    python tools/gen_engine_docs.py                     # all modules → docs/reports/engine/
    python tools/gen_engine_docs.py --module timer      # single module
    python tools/gen_engine_docs.py --src DIR           # custom source root (default: src/)
    python tools/gen_engine_docs.py --output DIR        # custom output dir
    python tools/gen_engine_docs.py --dry-run           # print to stdout, write nothing
    python tools/gen_engine_docs.py --check             # report missing docs, exit 1 if any

Exit codes:
    0 — success
    1 — missing docs found (--check only)
    2 — fatal error
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_SRC = _ROOT / "src"
DEFAULT_OUT = _ROOT / "docs" / "reports" / "engine"
EXCLUDE_DIR = "lua_api"

# ---------------------------------------------------------------------------
# Regex patterns
# ---------------------------------------------------------------------------

# /// docstring line
_DOC_LINE_RE = re.compile(r"^\s*///(.*)$")

# //! module-level docstring line
_MOD_DOC_RE = re.compile(r"^\s*//!(.*)$")

# pub struct Foo   /   pub struct Foo<T>
_PUB_STRUCT_RE = re.compile(r"^\s*pub\s+struct\s+(\w+)")

# pub enum Foo
_PUB_ENUM_RE = re.compile(r"^\s*pub\s+enum\s+(\w+)")

# pub fn foo(  (not pub fn in impl block — we collect it regardless)
_PUB_FN_RE = re.compile(r"^\s*pub\s+fn\s+(\w+)\s*(?:<[^>]+>)?\s*\(([^)]*)\)(?:\s*->\s*(.+?))?(?:\s*\{|;|where)")

# pub trait Foo
_PUB_TRAIT_RE = re.compile(r"^\s*pub\s+trait\s+(\w+)")

# pub type Alias = ...
_PUB_TYPE_RE = re.compile(r"^\s*pub\s+type\s+(\w+)")

# # Section  (inside a docstring)
_SECTION_RE = re.compile(r"^#\s+([A-Z][A-Za-z ]+?)\s*$")

# - `name` — `Type`.   (structured list item in Fields / Parameters / Variants)
_LIST_ITEM_RE = re.compile(r"^-\s+`([^`]+)`\s*(?:—|-{1,2}|–)\s+(.*)")

# impl Foo  (to track current impl context)
_IMPL_RE = re.compile(r"^\s*impl(?:<[^>]+>)?\s+(\w+)")

# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class DocSection:
    """A structured section inside a docstring (Fields, Parameters, Returns, Variants)."""
    title: str
    items: List[Tuple[str, str]] = field(default_factory=list)  # (name, description)
    raw: str = ""  # for Returns which is a single value, not a list


@dataclass
class ParsedDoc:
    """Fully parsed docstring for one public item."""
    summary: str
    details: List[str] = field(default_factory=list)
    sections: List[DocSection] = field(default_factory=list)

    @property
    def description(self) -> str:
        parts = [self.summary] + self.details
        return " ".join(p for p in parts if p).strip()


@dataclass
class RustItem:
    """One public Rust item (struct, enum, fn, trait, type) with its documentation."""
    kind: str            # struct | enum | fn | trait | type
    name: str
    signature: str       # raw declaration line (simplified)
    doc: Optional[ParsedDoc]
    impl_owner: Optional[str] = None   # set when fn is inside impl Xxx


@dataclass
class RustModule:
    """One Lurek2D module (top-level src/<module>/ directory)."""
    name: str
    module_doc: Optional[ParsedDoc]
    items: List[RustItem] = field(default_factory=list)
    source_files: List[Path] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Doc parsing
# ---------------------------------------------------------------------------


def _parse_doc(raw_lines: List[str]) -> ParsedDoc:
    """
    Parse a list of raw docstring text lines (already stripped of ///) into
    a ParsedDoc with summary, details, and structured sections.
    """
    doc = ParsedDoc(summary="")
    current_section: Optional[DocSection] = None
    past_summary = False

    for raw in raw_lines:
        line = raw.strip()

        # Section header inside docstring: # Fields / # Parameters / etc.
        m = _SECTION_RE.match(line)
        if m:
            title = m.group(1).strip()
            current_section = DocSection(title=title)
            doc.sections.append(current_section)
            past_summary = True
            continue

        if current_section is not None:
            # Inside a structured section
            if line == "":
                current_section = None
                continue
            m = _LIST_ITEM_RE.match(line)
            if m:
                current_section.items.append((m.group(1), m.group(2).rstrip(".")))
            else:
                # Plain text in section (e.g. Returns value: `f32`)
                cleaned = line.lstrip("`").rstrip("`.,")
                if cleaned:
                    current_section.raw = line
            continue

        # Regular paragraph text
        if line == "":
            past_summary = True
            continue

        if not past_summary and not doc.summary:
            doc.summary = line
            past_summary = True
        else:
            doc.details.append(line)

    return doc


def _collect_doc_above(lines: List[str], idx: int) -> Optional[ParsedDoc]:
    """
    Collect consecutive /// lines immediately above line `idx` and parse them.
    Returns None if there are no doc lines above.
    """
    raw: List[str] = []
    j = idx - 1
    # Skip blank lines  and attributes (#[...]) immediately above
    while j >= 0:
        s = lines[j].strip()
        if s == "" or s.startswith("#["):
            j -= 1
            continue
        break

    while j >= 0:
        s = lines[j].strip()
        m = _DOC_LINE_RE.match(lines[j])
        if m:
            raw.insert(0, m.group(1))
            j -= 1
        else:
            break

    if not raw:
        return None
    return _parse_doc(raw)


def _collect_module_doc(lines: List[str]) -> Optional[ParsedDoc]:
    """Collect the //! doc block from the top of the file."""
    raw: List[str] = []
    for line in lines:
        s = line.strip()
        if s == "":
            if raw:
                break  # end of opening //! block
            continue
        m = _MOD_DOC_RE.match(line)
        if m:
            raw.append(m.group(1))
        else:
            break
    return _parse_doc(raw) if raw else None


# ---------------------------------------------------------------------------
# File parser
# ---------------------------------------------------------------------------


def _parse_file(path: Path) -> Tuple[Optional[ParsedDoc], List[RustItem]]:
    """
    Parse a single .rs file.
    Returns (module_doc, items).
    """
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        print(f"ERROR: cannot read {path}: {e}", file=sys.stderr)
        return None, []

    lines = text.splitlines()
    module_doc = _collect_module_doc(lines)
    items: List[RustItem] = []

    # Track current impl block to attribute methods to their type
    impl_owner: Optional[str] = None
    brace_depth = 0
    impl_entry_depth = 0

    for i, line in enumerate(lines):
        s = line.strip()

        # Track impl block ownership (for fn items inside impl)
        if impl_owner is None:
            m = _IMPL_RE.match(s)
            if m and not s.startswith("impl LuaUserData"):  # skip lua_api impls
                impl_owner = m.group(1)
                impl_entry_depth = brace_depth

        prev_depth = brace_depth
        brace_depth += s.count("{") - s.count("}")
        if impl_owner is not None and brace_depth <= impl_entry_depth and prev_depth > impl_entry_depth:
            impl_owner = None

        # --- pub struct ---
        m = _PUB_STRUCT_RE.match(s)
        if m:
            doc = _collect_doc_above(lines, i)
            items.append(RustItem(
                kind="struct", name=m.group(1),
                signature=s.split("{")[0].strip().split("where")[0].strip(),
                doc=doc,
            ))
            continue

        # --- pub enum ---
        m = _PUB_ENUM_RE.match(s)
        if m:
            doc = _collect_doc_above(lines, i)
            items.append(RustItem(
                kind="enum", name=m.group(1),
                signature=s.split("{")[0].strip().split("where")[0].strip(),
                doc=doc,
            ))
            continue

        # --- pub fn ---
        m = _PUB_FN_RE.match(s)
        if m:
            doc = _collect_doc_above(lines, i)
            raw_sig = s.split("{")[0].strip().split("where")[0].strip()
            items.append(RustItem(
                kind="fn", name=m.group(1),
                signature=raw_sig,
                doc=doc,
                impl_owner=impl_owner,
            ))
            continue

        # --- pub trait ---
        m = _PUB_TRAIT_RE.match(s)
        if m:
            doc = _collect_doc_above(lines, i)
            items.append(RustItem(
                kind="trait", name=m.group(1),
                signature=s.split("{")[0].strip().split("where")[0].strip(),
                doc=doc,
            ))
            continue

        # --- pub type ---
        m = _PUB_TYPE_RE.match(s)
        if m:
            doc = _collect_doc_above(lines, i)
            items.append(RustItem(
                kind="type", name=m.group(1),
                signature=s.rstrip(";").strip(),
                doc=doc,
            ))
            continue

    return module_doc, items


# ---------------------------------------------------------------------------
# Module assembler
# ---------------------------------------------------------------------------


def _build_module(module_name: str, files: List[Path]) -> RustModule:
    """Aggregate docs from all files in one top-level module directory."""
    merged_doc: Optional[ParsedDoc] = None
    all_items: List[RustItem] = []

    for path in sorted(files):
        mod_doc, items = _parse_file(path)
        # mod.rs supplies the primary module doc
        if path.name == "mod.rs" and mod_doc:
            merged_doc = mod_doc
        elif merged_doc is None and mod_doc:
            merged_doc = mod_doc
        all_items.extend(items)

    return RustModule(
        name=module_name,
        module_doc=merged_doc,
        items=all_items,
        source_files=files,
    )


def _collect_module_files(src: Path, module_filter: Optional[str]) -> Dict[str, List[Path]]:
    """
    Walk src/ (excluding lua_api/) and group .rs files by top-level module directory.
    Files directly in src/ (no subdirectory) use their stem as the module name.
    Returns {module_name: [paths...]}
    """
    modules: Dict[str, List[Path]] = {}
    for rs_file in sorted(src.rglob("*.rs")):
        try:
            rel = rs_file.relative_to(src)
        except ValueError:
            continue
        parts = rel.parts
        if not parts:
            continue

        # File directly in src/ (e.g. src/lib.rs, or a flat test fixtures dir)
        if len(parts) == 1:
            top = Path(parts[0]).stem
        else:
            top = parts[0]

        if top == EXCLUDE_DIR:
            continue
        if module_filter and top != module_filter:
            continue
        modules.setdefault(top, []).append(rs_file)
    return modules


# ---------------------------------------------------------------------------
# Markdown rendering
# ---------------------------------------------------------------------------


def _render_doc_sections(doc: ParsedDoc) -> List[str]:
    """Render the structured sections (Fields, Parameters, Returns, Variants) of a doc."""
    out: List[str] = []
    for sec in doc.sections:
        title = sec.title
        if sec.items:
            out.append(f"\n**{title}**\n")
            out.append("| Name | Type / Description |")
            out.append("|---|---|")
            for name, desc in sec.items:
                out.append(f"| `{name}` | {desc} |")
        elif sec.raw:
            out.append(f"\n**{title}** `{sec.raw.strip('` ')}`\n")
    return out


def render_module(mod: RustModule) -> str:
    """Render a RustModule to Markdown."""
    out: List[str] = []

    out.append(f"# luna2d::{mod.name}\n")
    out.append(f"_Source: `src/{mod.name}/`_\n")

    if mod.module_doc:
        desc = mod.module_doc.description
        if desc:
            out.append(f"\n{desc}\n")

    # Group items by kind
    structs = [i for i in mod.items if i.kind == "struct"]
    enums = [i for i in mod.items if i.kind == "enum"]
    traits = [i for i in mod.items if i.kind == "trait"]
    free_fns = [i for i in mod.items if i.kind == "fn" and not i.impl_owner]
    types = [i for i in mod.items if i.kind == "type"]

    # --- Structs ---
    if structs:
        out.append("\n## Types\n")
        for item in structs:
            out.append(f"### `{item.name}`\n")
            if item.doc:
                if item.doc.summary:
                    out.append(f"{item.doc.description}\n")
                out.extend(_render_doc_sections(item.doc))

            # Methods belonging to this struct
            methods = [i for i in mod.items if i.kind == "fn" and i.impl_owner == item.name]
            if methods:
                out.append("\n#### Methods\n")
                for m in methods:
                    out.append(f"##### `{m.signature}`\n")
                    if m.doc:
                        if m.doc.summary:
                            out.append(f"{m.doc.description}\n")
                        out.extend(_render_doc_sections(m.doc))
                    out.append("")

            out.append("---\n")

    # --- Enums ---
    if enums:
        out.append("\n## Enums\n")
        for item in enums:
            out.append(f"### `{item.name}`\n")
            if item.doc:
                if item.doc.summary:
                    out.append(f"{item.doc.description}\n")
                out.extend(_render_doc_sections(item.doc))
            out.append("---\n")

    # --- Traits ---
    if traits:
        out.append("\n## Traits\n")
        for item in traits:
            out.append(f"### `{item.name}`\n")
            if item.doc:
                if item.doc.summary:
                    out.append(f"{item.doc.description}\n")
            out.append("---\n")

    # --- Type aliases ---
    if types:
        out.append("\n## Type Aliases\n")
        for item in types:
            out.append(f"### `{item.signature}`\n")
            if item.doc and item.doc.summary:
                out.append(f"{item.doc.description}\n")
            out.append("")

    # --- Free functions ---
    if free_fns:
        out.append("\n## Functions\n")
        for item in free_fns:
            out.append(f"### `{item.signature}`\n")
            if item.doc:
                if item.doc.summary:
                    out.append(f"{item.doc.description}\n")
                out.extend(_render_doc_sections(item.doc))
            out.append("---\n")

    return "\n".join(out)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def _ensure_utf8_stdout() -> None:
    """Reconfigure stdout/stderr to UTF-8 on Windows for Unicode doc output."""
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")


def main(argv=None) -> int:
    _ensure_utf8_stdout()
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument(
        "--src", type=Path, default=DEFAULT_SRC,
        help="Source root directory (default: src/)",
    )
    ap.add_argument(
        "--output", "-o", type=Path, default=DEFAULT_OUT,
        help="Output directory (default: docs/reports/engine/)",
    )
    ap.add_argument("--module", "-m", help="Process only this module (e.g. timer)")
    ap.add_argument("--dry-run", action="store_true", help="Print to stdout, write no files")
    ap.add_argument(
        "--check", action="store_true",
        help="Report public items without /// docs; exit 1 if any found",
    )
    args = ap.parse_args(argv)

    module_files = _collect_module_files(args.src, args.module)
    if not module_files:
        print(f"No .rs files found under {args.src}", file=sys.stderr)
        return 2

    missing = 0
    written = 0

    for module_name, files in sorted(module_files.items()):
        mod = _build_module(module_name, files)

        if args.check:
            for item in mod.items:
                if item.doc is None:
                    print(f"  MISSING  {module_name}::{item.name}   ({item.kind})")
                    missing += 1
            continue

        md = render_module(mod)

        if args.dry_run:
            print(f"\n{'=' * 64}")
            print(f"  MODULE : luna2d::{module_name}")
            print(f"  FILES  : {len(files)} file(s)")
            print("=" * 64)
            print(md)
        else:
            args.output.mkdir(parents=True, exist_ok=True)
            out_file = args.output / f"{module_name}.md"
            out_file.write_text(md, encoding="utf-8")
            print(f"  wrote  {out_file.relative_to(_ROOT)}")
            written += 1

    if args.check:
        if missing:
            print(f"\n{missing} undocumented public item(s) found.")
            return 1
        print("All public items documented.")
        return 0

    if not args.dry_run:
        print(f"\nGenerated {written} module doc(s) → {args.output}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
