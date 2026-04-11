"""
audit_agent_md.py
=================
For every src/<module>/AGENT.md, compare the "Source Files" table
against the actual .rs files in that directory.

Reports:
  GHOST  — listed in AGENT.md but NOT on disk
  MISSING — exists on disk but NOT in AGENT.md
  OK     — all match

Also checks docs/specs/<module>.md for the same inconsistencies.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).parent.parent.parent
SRC = ROOT / "src"
SPECS = ROOT / "docs" / "specs"

INFRA = {"lua_api", "bin"}

def get_rs_files(mod_dir: pathlib.Path) -> set[str]:
    """Return set of .rs filenames (just basename) in the module dir (non-recursive)."""
    return {f.name for f in mod_dir.glob("*.rs")}

def get_rs_files_recursive(mod_dir: pathlib.Path) -> set[str]:
    """Return set of relative paths for all .rs files recursively."""
    return {str(f.relative_to(mod_dir)) for f in mod_dir.rglob("*.rs")}

def extract_local_rs_refs(text: str, mod_name: str = "") -> set[str]:
    """Extract .rs file basenames from the Source Files TABLE ONLY.

    Only looks at table rows inside the ## Source Files section.
    This avoids false positives from Lua API or Cross-Module sections
    which legitimately reference files from other sub-directories.
    """
    refs = set()
    in_source_section = False

    for line in text.split("\n"):
        # Detect entering the Source Files section
        if re.match(r'^##\s+Source Files', line, re.I):
            in_source_section = True
            continue
        # Detect leaving the section (next ## header)
        if re.match(r'^##\s+', line) and in_source_section:
            in_source_section = False
            continue

        if in_source_section and line.startswith("|"):
            # Only pick bare filenames (no path separators)
            m = re.search(r'`([a-zA-Z0-9_]+\.rs)`', line)
            if m:
                refs.add(m.group(1))

    return refs

def audit_module(mod_name: str) -> dict:
    mod_dir = SRC / mod_name
    agent_md = mod_dir / "AGENT.md"
    spec_md = SPECS / f"{mod_name}.md"

    result = {
        "module": mod_name,
        "agent_ghost": [],
        "agent_missing": [],
        "spec_ghost": [],
        "spec_missing": [],
        "agent_ok": False,
        "spec_ok": False,
        "no_agent": not agent_md.exists(),
        "no_spec": not spec_md.exists(),
    }

    # Actual files on disk (just basenames for top-level, relative for subdirs)
    actual_top = {f.name for f in mod_dir.glob("*.rs")}
    actual_all = {str(f.relative_to(mod_dir)).replace("\\", "/") for f in mod_dir.rglob("*.rs")}

    if agent_md.exists():
        text = agent_md.read_text(encoding="utf-8", errors="replace")
        refs = extract_local_rs_refs(text, mod_name)
        
        agent_ghost = []
        agent_missing = []
        
        # Ghost: mentioned in AGENT.md but not on disk in this module
        for ref in refs:
            if ref not in actual_top:
                agent_ghost.append(ref)
        
        # Missing: on disk but not mentioned in AGENT.md
        for fname in sorted(actual_top):
            if fname not in refs:
                agent_missing.append(fname)
        
        result["agent_ghost"] = sorted(agent_ghost)
        result["agent_missing"] = sorted(agent_missing)
        result["agent_ok"] = not agent_ghost and not agent_missing

    if spec_md.exists():
        text = spec_md.read_text(encoding="utf-8", errors="replace")
        refs = extract_local_rs_refs(text, mod_name)
        
        spec_ghost = []
        spec_missing = []
        
        # Ghost: referenced but not on disk
        for ref in refs:
            if ref not in actual_top:
                spec_ghost.append(ref)
        
        # Missing: on disk but not mentioned
        for fname in sorted(actual_top):
            if fname not in refs:
                spec_missing.append(fname)
        
        result["spec_ghost"] = sorted(spec_ghost)
        result["spec_missing"] = sorted(spec_missing)
        result["spec_ok"] = not spec_ghost and not spec_missing

    return result


def main():
    modules = sorted(
        d.name for d in SRC.iterdir()
        if d.is_dir() and d.name not in INFRA and not d.name.startswith(".")
    )

    all_ok = True
    issues = []

    for mod in modules:
        r = audit_module(mod)
        has_issue = (
            r["no_agent"] or r["no_spec"] or
            r["agent_ghost"] or r["agent_missing"] or
            r["spec_ghost"] or r["spec_missing"]
        )
        if has_issue:
            all_ok = False
            issues.append(r)

    if not issues:
        print(f"PASS — All {len(modules)} modules: AGENT.md and spec match disk exactly.")
        return 0

    print(f"ISSUES FOUND in {len(issues)}/{len(modules)} modules:\n")
    for r in issues:
        mod = r["module"]
        print(f"── {mod} ──")
        if r["no_agent"]:
            print(f"   NO AGENT.md")
        else:
            for g in r["agent_ghost"]:
                print(f"   AGENT GHOST:   {g}")
            for m in r["agent_missing"]:
                print(f"   AGENT MISSING: {m}")
        if r["no_spec"]:
            print(f"   NO SPEC")
        else:
            for g in r["spec_ghost"]:
                print(f"   SPEC GHOST:    {g}")
            for m in r["spec_missing"]:
                print(f"   SPEC MISSING:  {m}")
        print()

    print(f"Total modules with issues: {len(issues)}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
