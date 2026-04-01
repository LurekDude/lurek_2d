---
applyTo: "tools/**"
---

# Tools Instructions

All files in `tools/` are CLI scripts for developer and agent workflows. Every script must include `--help` output, accept a `--file` or path argument, and produce structured output suitable for both human and agent consumption.

## Core Rules

- **Python only**: all tools/*.py scripts run with standard `python` (3.10+); no third-party imports beyond stdlib unless documented in a `requirements.txt` or inline comment
- **`--help` required**: every script must support `python tools/<script>.py --help` with a concise description of flags
- **Non-zero exit on failure**: scripts must exit with code 1 when validation fails, code 0 when it passes — agents use exit codes to determine success
- **Structured console output**: prefix lines with severity (`[OK]`, `[WARN]`, `[ERROR]`, `[INFO]`) so agents can parse results
- **Idempotent**: running a tool twice on the same input produces the same output — no side effects

## Canonical CLI Tool

`tools/cag_validate.py` is the primary CAG validation tool:

```powershell
# Full validation of all .github/ files
python tools/cag_validate.py

# Validate a specific file
python tools/cag_validate.py --file .github/skills/lua-api-design/SKILL.md

# Validate all files of one type
python tools/cag_validate.py --type agent
python tools/cag_validate.py --type skill
python tools/cag_validate.py --type prompt
python tools/cag_validate.py --type instruction

# Show only errors (suppress OK lines)
python tools/cag_validate.py --errors-only

# Output as JSON for agent consumption
python tools/cag_validate.py --json
```

## Compliance

- Tools must operate relative to the repository root — detect it via `git rev-parse --show-toplevel` or by checking for `Cargo.toml`
- Exit code 0 = all checks pass, exit code 1 = one or more failures
- Never modify any source files — tools are read-only validators and analyzers

## Avoid

- Hard-coded absolute paths — always use paths relative to the repo root
- Requiring virtualenv or special Python setup — standard library only unless clearly documented
- Writing to `src/` or `.github/` — tools observe, they do not edit
- Silently ignoring files that fail to parse — report the error with the file path
