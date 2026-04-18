"""P7 tools-awareness audit.

Walks tools/**/*.{py,sh,ps1}, records docstring presence and current
description, checks subfolder READMEs for script mentions, and
cross-references CAG artifacts (.github/**) for tool references.

Usage: python work/cag-system-overhaul-20260418/scripts/p7_tools_audit.py [--write]

Outputs:
  work/cag-system-overhaul-20260418/reports/P7_tools_inventory.md
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
TOOLS = ROOT / "tools"
GITHUB = ROOT / ".github"
REPORT = ROOT / "work/cag-system-overhaul-20260418/reports/P7_tools_inventory.md"

EXTS = {".py", ".sh", ".ps1"}


@dataclass
class ScriptInfo:
    rel: str
    subdir: str
    name: str
    ext: str
    size: int
    lines: int
    has_docstring: bool
    desc: str
    referenced_by: list[str] = field(default_factory=list)


def first_nonempty(lines: list[str]) -> str:
    for line in lines:
        s = line.strip()
        if s:
            return s
    return ""


def detect_py_doc(text: str) -> tuple[bool, str]:
    # Skip shebang and __future__/encoding/blank
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        s = lines[i].strip()
        if s.startswith("#!") or s.startswith("# -*-") or s == "":
            i += 1
            continue
        break
    if i >= len(lines):
        return False, ""
    line = lines[i].lstrip()
    for q in ('"""', "'''"):
        if line.startswith(q):
            # extract first line of docstring
            rest = line[3:]
            if q in rest:
                return True, rest.split(q, 1)[0].strip()
            # multi-line
            for j in range(i + 1, len(lines)):
                if q in lines[j]:
                    break
            return True, rest.strip() or first_nonempty(lines[i + 1 : i + 5])
    return False, ""


def detect_sh_doc(text: str) -> tuple[bool, str]:
    lines = text.splitlines()
    i = 0
    if i < len(lines) and lines[i].startswith("#!"):
        i += 1
    # Need at least one comment block describing purpose/usage
    block: list[str] = []
    while i < len(lines):
        s = lines[i].strip()
        if s.startswith("#"):
            block.append(s.lstrip("#").strip())
            i += 1
            continue
        if s == "":
            i += 1
            if block:
                break
            continue
        break
    text_block = " ".join(block).lower()
    has = any(k in text_block for k in ("purpose:", "usage:", "synopsis", "description"))
    return has, first_nonempty(block)


def detect_ps1_doc(text: str) -> tuple[bool, str]:
    # Look for <# .SYNOPSIS / .DESCRIPTION #> in first 30 lines, or # comment header
    head = "\n".join(text.splitlines()[:40])
    if "<#" in head and (".SYNOPSIS" in head or ".DESCRIPTION" in head):
        m = re.search(r"\.SYNOPSIS\s*\n\s*(.+)", head)
        if m:
            return True, m.group(1).strip()
        return True, ""
    # fallback: leading # Purpose:/Usage: comment block
    return detect_sh_doc(text)


def gather_scripts() -> list[ScriptInfo]:
    out: list[ScriptInfo] = []
    for p in sorted(TOOLS.rglob("*")):
        if not p.is_file() or p.suffix not in EXTS:
            continue
        rel = p.relative_to(ROOT).as_posix()
        try:
            text = p.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            text = p.read_text(encoding="utf-8", errors="replace")
        if p.suffix == ".py":
            has, desc = detect_py_doc(text)
        elif p.suffix == ".sh":
            has, desc = detect_sh_doc(text)
        else:
            has, desc = detect_ps1_doc(text)
        rel_to_tools = p.relative_to(TOOLS)
        subdir = rel_to_tools.parts[0] if len(rel_to_tools.parts) > 1 else "<root>"
        out.append(
            ScriptInfo(
                rel=rel,
                subdir=subdir,
                name=p.name,
                ext=p.suffix,
                size=len(text.encode("utf-8")),
                lines=text.count("\n") + 1,
                has_docstring=has,
                desc=desc[:160],
            )
        )
    return out


def gather_cag_refs() -> dict[str, list[str]]:
    """Return mapping script_path → [cag_file references]."""
    refs: dict[str, list[str]] = {}
    cag_files = list(GITHUB.rglob("*.md"))
    for cf in cag_files:
        try:
            text = cf.read_text(encoding="utf-8")
        except Exception:
            continue
        for m in re.finditer(r"tools/[A-Za-z0-9_./\-]+\.(?:py|sh|ps1)", text):
            tool = m.group(0)
            refs.setdefault(tool, []).append(cf.relative_to(ROOT).as_posix())
    return refs


def gather_root_readme_refs() -> set[str]:
    """Tool paths mentioned in tools/README.md or any subfolder README.md."""
    out: set[str] = set()
    for rd in TOOLS.rglob("README.md"):
        try:
            text = rd.read_text(encoding="utf-8")
        except Exception:
            continue
        # match any script name; collect just basenames + relative paths
        for m in re.finditer(r"`?([A-Za-z0-9_./\-]+\.(?:py|sh|ps1))`?", text):
            out.add(m.group(1))
    return out


def subfolder_status(scripts: list[ScriptInfo]) -> list[tuple[str, bool, list[str], list[str]]]:
    """List (subdir, has_readme, scripts_in_folder, missing_from_readme)."""
    by_dir: dict[str, list[str]] = {}
    for s in scripts:
        by_dir.setdefault(s.subdir, []).append(s.name)
    out = []
    for subdir, names in sorted(by_dir.items()):
        if subdir == "<root>":
            continue
        rd = TOOLS / subdir / "README.md"
        has = rd.exists()
        missing: list[str] = []
        if has:
            try:
                text = rd.read_text(encoding="utf-8")
            except Exception:
                text = ""
            for n in names:
                if n not in text:
                    missing.append(n)
        else:
            missing = list(names)
        out.append((subdir, has, sorted(names), missing))
    return out


def write_report(scripts: list[ScriptInfo], refs: dict[str, list[str]]) -> str:
    # attach refs
    for s in scripts:
        s.referenced_by = sorted(set(refs.get(s.rel, [])))

    lines: list[str] = []
    lines.append("# P7 Tools Inventory\n")
    lines.append(f"Generated: walked {len(scripts)} script(s) under `tools/`.\n")

    missing_doc = [s for s in scripts if not s.has_docstring]
    unref = [s for s in scripts if not s.referenced_by]
    lines.append(
        f"- Scripts without docstring/header: **{len(missing_doc)}**\n"
        f"- Scripts unreferenced by any `.github/` artifact: **{len(unref)}**\n"
    )

    lines.append("\n## Per-script status\n")
    lines.append("| Path | Doc? | Refs | Description |\n|---|:--:|:--:|---|")
    for s in scripts:
        flag = "✅" if s.has_docstring else "❌"
        lines.append(f"| `{s.rel}` | {flag} | {len(s.referenced_by)} | {s.desc or '—'} |")

    lines.append("\n## Per-subfolder status\n")
    lines.append("| Subdir | README | Scripts | Missing from README |\n|---|:--:|---|---|")
    for sub, has, names, miss in subfolder_status(scripts):
        flag = "✅" if has else "❌"
        miss_s = ", ".join(f"`{n}`" for n in miss) if miss else "—"
        lines.append(f"| `{sub}/` | {flag} | {len(names)} | {miss_s} |")

    lines.append("\n## Action list\n")
    if missing_doc:
        lines.append("### Need docstring/header\n")
        for s in missing_doc:
            lines.append(f"- `{s.rel}`")
    else:
        lines.append("- ✅ All scripts have docstrings/headers.\n")
    if unref:
        lines.append("\n### Unreferenced by any agent/skill/prompt\n")
        for s in unref:
            lines.append(f"- `{s.rel}` — {s.desc or '(no desc)'}")
    else:
        lines.append("\n- ✅ All scripts referenced by at least one CAG artifact.\n")

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    text = "\n".join(lines) + "\n"
    REPORT.write_text(text, encoding="utf-8")
    return text


def main() -> int:
    scripts = gather_scripts()
    refs = gather_cag_refs()
    write_report(scripts, refs)
    missing = sum(1 for s in scripts if not s.has_docstring)
    unref = sum(1 for s in scripts if s.rel not in refs)
    print(f"scripts={len(scripts)} missing_doc={missing} unreferenced={unref}")
    print(f"report={REPORT.relative_to(ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
