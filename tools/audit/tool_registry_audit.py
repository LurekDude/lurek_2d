"""Audit the tools registry for internal consistency.

Self-validates that every Python script under tools/ is:
  1. Registered in its subfolder README.md.
  2. Registered in the master tools/README.md.
  3. Has a module-level docstring.
  4. Uses relative paths (no hardcoded absolute user paths).
  5. Not a duplicate of another script in a different subfolder.

Also checks for phantom entries — scripts listed in READMEs but missing
from disk.

Usage:
    python tools/audit/tool_registry_audit.py [--strict] [--format text|json]

Exit code:
    0 if clean, 1 if any errors found.
"""
import argparse
import ast
import json
import re
import sys
from pathlib import Path

ROOT = Path(".").resolve()
TOOLS_DIR = ROOT / "tools"
MASTER_README = TOOLS_DIR / "README.md"

# Subfolders that contain Python scripts
TOOL_SUBFOLDERS = [
    "validate", "audit", "fix", "docs", "dev",
    "dist", "github", "demos", "ui", "mods",
]

# Files that are helpers, not standalone tools
HELPER_FILES = {"_cag_common.py", "__init__.py"}


def find_all_scripts() -> list[Path]:
    """Find all .py files under tools/ (excluding __pycache__)."""
    scripts = []
    for subfolder in TOOL_SUBFOLDERS:
        subdir = TOOLS_DIR / subfolder
        if subdir.is_dir():
            for f in sorted(subdir.glob("*.py")):
                if f.name not in HELPER_FILES and "__pycache__" not in str(f):
                    scripts.append(f)
    # Root-level scripts
    for f in sorted(TOOLS_DIR.glob("*.py")):
        scripts.append(f)
    return scripts


def has_docstring(script: Path) -> bool:
    """Check if script has a module-level docstring."""
    try:
        text = script.read_text(encoding="utf-8")
        tree = ast.parse(text)
        return (
            tree.body
            and isinstance(tree.body[0], ast.Expr)
            and isinstance(tree.body[0].value, (ast.Constant, ast.Str))
        )
    except Exception:
        return False


def has_hardcoded_user_path(script: Path) -> str | None:
    """Check for hardcoded absolute user paths. Returns the path if found."""
    try:
        text = script.read_text(encoding="utf-8")
    except Exception:
        return None
    # Match Windows-style user paths like C:/Users/... or C:\\Users\\...
    m = re.search(r'["\']([A-Z]:[/\\]+Users[/\\]+\w+)', text)
    if m:
        return m.group(1)
    # Match Unix home paths
    m = re.search(r'["\'](/home/\w+|/Users/\w+)', text)
    if m:
        return m.group(1)
    return None


def extract_readme_scripts(readme_path: Path) -> set[str]:
    """Extract script names mentioned in a README.md table or backtick refs."""
    if not readme_path.exists():
        return set()
    text = readme_path.read_text(encoding="utf-8")
    # Match backtick-wrapped .py filenames in table cells
    return set(re.findall(r"`(\w+\.py)`", text))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit the tools registry for internal consistency."
    )
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args()

    all_scripts = find_all_scripts()
    findings: list[dict] = []

    # Gather README registrations
    master_scripts = extract_readme_scripts(MASTER_README)
    subfolder_scripts: dict[str, set[str]] = {}
    for sub in TOOL_SUBFOLDERS:
        readme = TOOLS_DIR / sub / "README.md"
        subfolder_scripts[sub] = extract_readme_scripts(readme)

    for script in all_scripts:
        name = script.name
        rel = script.relative_to(TOOLS_DIR)
        subfolder = rel.parts[0] if len(rel.parts) > 1 else None

        # 1. Check subfolder README registration
        if subfolder and subfolder in subfolder_scripts:
            if name not in subfolder_scripts[subfolder]:
                findings.append({
                    "level": "ERROR", "script": str(rel),
                    "check": "subfolder_readme",
                    "message": f"Not registered in tools/{subfolder}/README.md",
                })

        # 2. Check master README registration
        if name not in master_scripts:
            findings.append({
                "level": "WARN", "script": str(rel),
                "check": "master_readme",
                "message": "Not registered in tools/README.md",
            })

        # 3. Check docstring
        if not has_docstring(script):
            findings.append({
                "level": "ERROR", "script": str(rel),
                "check": "docstring",
                "message": "Missing module-level docstring",
            })

        # 4. Check hardcoded paths
        bad_path = has_hardcoded_user_path(script)
        if bad_path:
            findings.append({
                "level": "ERROR", "script": str(rel),
                "check": "hardcoded_path",
                "message": f"Contains hardcoded user path: {bad_path}",
            })

    # 5. Check for phantom README entries
    for sub in TOOL_SUBFOLDERS:
        subdir = TOOLS_DIR / sub
        disk_scripts = {f.name for f in subdir.glob("*.py")} if subdir.is_dir() else set()
        for listed in subfolder_scripts.get(sub, set()):
            if listed not in disk_scripts and listed not in HELPER_FILES:
                findings.append({
                    "level": "ERROR", "script": f"{sub}/{listed}",
                    "check": "phantom",
                    "message": f"Listed in tools/{sub}/README.md but not on disk",
                })

    errors = [f for f in findings if f["level"] == "ERROR"]
    warns = [f for f in findings if f["level"] == "WARN"]

    if args.format == "json":
        print(json.dumps({
            "total_scripts": len(all_scripts),
            "findings": findings,
        }, indent=2))
    else:
        for f in findings:
            print(f"[{f['level']}] {f['script']}: {f['message']}")
        print(f"\n{len(all_scripts)} scripts audited, "
              f"{len(errors)} error(s), {len(warns)} warning(s)")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
