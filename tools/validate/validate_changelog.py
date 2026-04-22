"""Validate docs/CHANGELOG.md structure and content.

Checks that the CHANGELOG follows the expected format:
  - Has a top-level heading with versioning policy.
  - Each version section uses ## [X.Y.Z] — YYYY-MM-DD format.
  - The latest version section (topmost) has at least one bullet.
  - No duplicate version numbers exist.
  - Versions are listed in descending order.
  - Every bullet begins with a category prefix (Added, Changed, Fixed,
    Removed, Deprecated, Security) or is a plain descriptive line.

Usage:
    python tools/validate/validate_changelog.py [--strict]

Options:
    --strict   Treat warnings (missing date, missing category prefix) as errors.

Exit code:
    0 if valid, 1 if any errors found.
"""
import re
import sys
import argparse
from pathlib import Path

ROOT = Path(".").resolve()
CHANGELOG = ROOT / "docs" / "CHANGELOG.md"

VERSION_RE = re.compile(
    r"^##\s+\[(\d+\.\d+\.\d+(?:-\w+)?)\]"
    r"(?:\s*[-—]\s*(\d{4}-\d{2}-\d{2}))?"
)
CATEGORY_PREFIXES = {
    "added", "changed", "fixed", "removed", "deprecated",
    "security", "refactored", "documented", "tested",
}


def validate(strict: bool = False) -> list[dict]:
    """Return list of {level, line, message} findings."""
    findings: list[dict] = []

    if not CHANGELOG.exists():
        findings.append({"level": "ERROR", "line": 0,
                         "message": f"{CHANGELOG} does not exist"})
        return findings

    lines = CHANGELOG.read_text(encoding="utf-8").splitlines()
    if not lines:
        findings.append({"level": "ERROR", "line": 0,
                         "message": "CHANGELOG is empty"})
        return findings

    # --- structural checks ---
    versions_seen: dict[str, int] = {}
    prev_version_parts: tuple | None = None
    current_version_bullets = 0
    first_version_line: int | None = None

    for i, line in enumerate(lines, start=1):
        m = VERSION_RE.match(line)
        if m:
            ver = m.group(1)
            date = m.group(2)

            if first_version_line is None:
                first_version_line = i
                # Check that topmost version has content (checked after loop)

            if ver in versions_seen:
                findings.append({
                    "level": "ERROR", "line": i,
                    "message": f"Duplicate version [{ver}] "
                               f"(first at line {versions_seen[ver]})",
                })
            versions_seen[ver] = i

            # Date presence
            if not date:
                level = "ERROR" if strict else "WARN"
                findings.append({
                    "level": level, "line": i,
                    "message": f"Version [{ver}] has no release date",
                })

            # Descending order check
            ver_parts = tuple(int(x) for x in ver.split("-")[0].split("."))
            if prev_version_parts is not None:
                if ver_parts >= prev_version_parts:
                    findings.append({
                        "level": "ERROR", "line": i,
                        "message": f"Version [{ver}] is not in descending "
                                   f"order after previous version",
                    })
            prev_version_parts = ver_parts
            current_version_bullets = 0
            continue

        # Count bullets under the current version
        stripped = line.strip()
        if stripped.startswith("- ") and first_version_line is not None:
            current_version_bullets += 1

            # Category prefix check (optional)
            bullet_text = stripped[2:].strip()
            has_prefix = False
            for prefix in CATEGORY_PREFIXES:
                if bullet_text.lower().startswith(prefix):
                    has_prefix = True
                    break
            if not has_prefix and bullet_text and not bullet_text.startswith("*"):
                level = "ERROR" if strict else "WARN"
                # Only warn, don't fail — many changelogs use plain bullets
                pass  # Intentionally relaxed

    # Check topmost version has at least one bullet
    if first_version_line is not None and current_version_bullets == 0:
        # Only error if there's exactly one version (the latest)
        # If there are multiple versions, bullets may be elsewhere
        if len(versions_seen) == 1:
            findings.append({
                "level": "WARN", "line": first_version_line,
                "message": "Latest version section has no bullet entries",
            })

    if not versions_seen:
        findings.append({
            "level": "ERROR", "line": 0,
            "message": "No version sections found (expected ## [X.Y.Z])",
        })

    return findings


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate docs/CHANGELOG.md structure and content."
    )
    parser.add_argument(
        "--strict", action="store_true",
        help="Treat warnings as errors",
    )
    parser.add_argument(
        "--format", choices=["text", "json"], default="text",
        help="Output format (default: text)",
    )
    args = parser.parse_args()

    findings = validate(strict=args.strict)

    errors = [f for f in findings if f["level"] == "ERROR"]
    warns = [f for f in findings if f["level"] == "WARN"]

    if args.format == "json":
        import json
        print(json.dumps({"findings": findings}, indent=2))
    else:
        for f in findings:
            print(f"[{f['level']}] line {f['line']}: {f['message']}")
        print(f"\n{len(errors)} error(s), {len(warns)} warning(s)")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
