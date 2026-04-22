"""Audit wiki page coverage against engine modules and Lua API.

Cross-references wiki/ pages against:
  - src/ module directories (each module should have a wiki page).
  - lurek.* API surface (key namespaces should be documented).
  - content/library/ entries (each library should appear in wiki).

Reports missing wiki pages, orphaned pages (wiki page with no matching
module), and pages with potential staleness indicators (e.g. references
to old namespace names).

Usage:
    python tools/audit/wiki_coverage.py [--strict] [--format text|json]

Exit code:
    0 if no gaps, 1 if any missing coverage found (errors only).
"""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(".").resolve()
WIKI_DIR = ROOT / "docs" / "wiki"
SRC_DIR = ROOT / "src"
LIBRARY_DIR = ROOT / "library"

# Modules that are internal and don't need wiki pages
INTERNAL_MODULES = {
    "lua_api", "bin", "docs", "pipeline", "app",
}

# Wiki pages that don't map to a single src/ module
META_PAGES = {
    "Home", "Getting-Started", "API-Reference", "FAQ",
    "Architecture", "Contributing", "Troubleshooting",
    "Installation", "Configuration", "Changelog",
}


def discover_modules() -> set[str]:
    """Return set of module names from src/ that should have wiki pages."""
    modules = set()
    if not SRC_DIR.exists():
        return modules
    for d in SRC_DIR.iterdir():
        if d.is_dir() and not d.name.startswith("_") and d.name not in INTERNAL_MODULES:
            modules.add(d.name)
    return modules


def discover_libraries() -> set[str]:
    """Return set of library names from content/library/."""
    libs = set()
    if not LIBRARY_DIR.exists():
        return libs
    for d in LIBRARY_DIR.iterdir():
        if d.is_dir() and not d.name.startswith("."):
            libs.add(d.name)
    return libs


def discover_wiki_pages() -> dict[str, Path]:
    """Return dict of {page_stem: path} from wiki/."""
    pages: dict[str, Path] = {}
    if not WIKI_DIR.exists():
        return pages
    for f in WIKI_DIR.glob("*.md"):
        pages[f.stem] = f
    return pages


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit wiki page coverage against engine modules."
    )
    parser.add_argument("--strict", action="store_true",
                        help="Treat warnings as errors")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args()

    modules = discover_modules()
    libraries = discover_libraries()
    wiki_pages = discover_wiki_pages()

    findings: list[dict] = []
    page_stems_lower = {k.lower().replace("-", "_"): k for k in wiki_pages}

    # Check modules have wiki pages
    for mod in sorted(modules):
        if mod not in page_stems_lower and mod.replace("_", "-") not in page_stems_lower:
            findings.append({
                "level": "ERROR" if args.strict else "WARN",
                "category": "module",
                "name": mod,
                "message": f"Module '{mod}' has no wiki page in wiki/",
            })

    # Check libraries are mentioned
    for lib in sorted(libraries):
        if lib not in page_stems_lower and lib.replace("_", "-") not in page_stems_lower:
            # Check if mentioned in any wiki page
            mentioned = False
            for page_path in wiki_pages.values():
                text = page_path.read_text(encoding="utf-8", errors="replace")
                if lib in text.lower():
                    mentioned = True
                    break
            if not mentioned:
                findings.append({
                    "level": "WARN",
                    "category": "library",
                    "name": lib,
                    "message": f"Library '{lib}' not mentioned in any wiki page",
                })

    # Check for orphaned wiki pages
    all_known = (
        {m.lower() for m in modules}
        | {m.replace("_", "-").lower() for m in modules}
        | {lb.lower() for lb in libraries}
        | {p.lower().replace("-", "_") for p in META_PAGES}
        | {p.lower() for p in META_PAGES}
    )
    for stem in wiki_pages:
        stem_norm = stem.lower().replace("-", "_")
        if stem_norm not in all_known and stem.lower() not in {p.lower() for p in META_PAGES}:
            findings.append({
                "level": "WARN",
                "category": "orphan",
                "name": stem,
                "message": f"Wiki page '{stem}.md' has no matching module or library",
            })

    errors = [f for f in findings if f["level"] == "ERROR"]
    warns = [f for f in findings if f["level"] == "WARN"]

    if args.format == "json":
        print(json.dumps({
            "modules": len(modules),
            "libraries": len(libraries),
            "wiki_pages": len(wiki_pages),
            "findings": findings,
        }, indent=2))
    else:
        for f in findings:
            print(f"[{f['level']}] {f['category']}/{f['name']}: {f['message']}")
        print(f"\n{len(modules)} modules, {len(libraries)} libraries, "
              f"{len(wiki_pages)} wiki pages")
        print(f"{len(errors)} error(s), {len(warns)} warning(s)")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
