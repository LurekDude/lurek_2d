#!/usr/bin/env python3
"""
validate_module_coverage.py
============================
Validates that every top-level src/<module>/ directory has:
    1. An AGENT.md file inside it
    2. A matching docs/specs/<module>.md file

Also reports any docs/specs/*.md files that have NO matching src/<module>/ dir
(these are orphaned specs that should be removed or merged).

Usage:
    python tools/validate/validate_module_coverage.py
    python tools/validate/validate_module_coverage.py --fix-readme   # also update docs/specs/README.md
"""

import os
import sys
import pathlib
import argparse

ROOT = pathlib.Path(__file__).parent.parent.parent
SRC = ROOT / "src"
SPECS = ROOT / "docs" / "specs"
SPECS_README = SPECS / "README.md"

def main():
    parser = argparse.ArgumentParser(description="Validate module spec/AGENT.md coverage")
    parser.add_argument("--fix-readme", action="store_true",
                        help="Rewrite docs/specs/README.md to match actual src/ modules")
    args = parser.parse_args()

    # --- Gather ground truth ---
    src_modules = sorted(
        d.name for d in SRC.iterdir()
        if d.is_dir() and not d.name.startswith(".")
    )

    spec_files = sorted(
        f.stem for f in SPECS.glob("*.md")
        if f.name not in {"README.md", "SPEC_TEMPLATE.md"}
    )

    src_set = set(src_modules)
    spec_set = set(spec_files)

    # --- Report ---
    missing_spec = sorted(src_set - spec_set)
    missing_agent = sorted(m for m in src_modules if not (SRC / m / "AGENT.md").exists())
    orphan_specs = sorted(spec_set - src_set)

    has_errors = False

    if orphan_specs:
        has_errors = True
        print("FAIL — Orphan specs (no matching src/<module>/ dir):")
        for s in orphan_specs:
            print(f"  ORPHAN  docs/specs/{s}.md")
        print()

    if missing_spec:
        has_errors = True
        print("FAIL — src/ modules without docs/specs/<module>.md:")
        for m in missing_spec:
            print(f"  MISSING_SPEC  src/{m}/")
        print()

    if missing_agent:
        has_errors = True
        print("FAIL — src/ modules without AGENT.md:")
        for m in missing_agent:
            print(f"  MISSING_AGENT  src/{m}/AGENT.md")
        print()


    if not has_errors:
        print(f"PASS — All {len(src_modules)} src/ modules have AGENT.md and docs/specs/*.md")

    # Summary counts
    print(f"\nSummary: {len(src_modules)} src modules | "
          f"{len(spec_files)} spec files | "
          f"{len(orphan_specs)} orphans | "
          f"{len(missing_spec)} missing specs | "
          f"{len(missing_agent)} missing AGENT.md")

    if args.fix_readme:
        _rewrite_readme(src_modules)

    return 1 if has_errors else 0


def _rewrite_readme(all_entries):
    """Rewrite docs/specs/README.md module list."""
    existing = SPECS_README.read_text(encoding="utf-8")
    marker = "## Modules\n"
    if marker not in existing:
        print("WARNING: Could not find '## Modules' section in README.md — skipping rewrite")
        return

    prefix = existing[: existing.index(marker) + len(marker)]
    links = "\n".join(f"- [{m}]({m}.md)" for m in sorted(all_entries))
    new_content = prefix + links + "\n"
    SPECS_README.write_text(new_content, encoding="utf-8")
    print(f"\nREWROTE docs/specs/README.md — {len(all_entries)} entries")


if __name__ == "__main__":
    sys.exit(main())
