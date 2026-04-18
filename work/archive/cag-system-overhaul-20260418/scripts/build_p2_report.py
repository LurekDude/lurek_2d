"""Build the consolidated P2 baseline violations report (human-readable)."""

from __future__ import annotations

import json
from pathlib import Path

P = Path(__file__).resolve().parents[1]  # work/cag-system-overhaul-20260418
DATA = P / "data"
val = json.loads((DATA / "p2_validator_full.json").read_text(encoding="utf-8"))
link = json.loads((DATA / "p2_link_check.json").read_text(encoding="utf-8"))
cov = json.loads((DATA / "p2_coverage.json").read_text(encoding="utf-8"))
pers = json.loads((DATA / "p2_personas.json").read_text(encoding="utf-8"))

out: list[str] = []
out.append("# P2 Baseline Violations Report")
out.append("")
out.append("Captured immediately after the P2 validator+tools build, before any "
           "P3-P6 cleanup of agents/skills/prompts.")
out.append("")
out.append("Used to bound regressions in subsequent phases via "
           "`python tools/validate/cag_validate.py --baseline`.")
out.append("")

s = val["summary"]
out.append("## 1. cag_validate.py (strict mode)")
out.append("")
out.append(f"- Scanned: {val['scanned']}")
out.append(f"- **Errors: {s['errors']}** — **Warnings: {s['warnings']}**")
out.append("- Violations by rule (descending):")
for k, v in sorted(s["by_rule"].items(), key=lambda kv: -kv[1]):
    out.append(f"  - `{k}`: {v}")
out.append("")

out.append("## 2. cag_link_check.py")
out.append("")
out.append(f"- Files scanned: {link['files_scanned']}, "
           f"links extracted: {link['links_total']}")
out.append(f"- **Broken: {link['broken_total']}**")
out.append("- Broken by category:")
for k, v in sorted(link["broken_by_category"].items()):
    out.append(f"  - {k}: {v}")
out.append("")
out.append("Examples (first 8):")
for b in link["broken"][:8]:
    out.append(f"  - {b['file']}:{b['line']} -> `{b['target']}`")
out.append("")

out.append("## 3. cag_coverage.py")
out.append("")
out.append("Full matrix: `data/p2_coverage.md`. Per-type coverage:")
out.append("")
for kind, blob in cov.items():
    out.append(f"### {kind} (n={blob['count']})")
    out.append("")
    out.append("| Field | Coverage |")
    out.append("|---|---:|")
    for k, v in blob["coverage"].items():
        out.append(f"| `{k}` | {v}% |")
    out.append("")

out.append("## 4. cag_persona_matrix.py")
out.append("")
out.append("Full matrix: `data/p2_persona_matrix.md`.")
out.append("")
out.append("| Persona | Agents declaring it |")
out.append("|---|---:|")
for k, v in pers["persona_counts"].items():
    out.append(f"| `{k}` | {v} |")
out.append("")
zero = pers["warnings"]["agents_with_zero_personas"]
err = pers["errors"]["unmapped_personas"]
warn = pers["warnings"]["low_coverage_personas"]
out.append(f"- Agents with zero personas (W108): **{len(zero)}** "
           f"({', '.join(zero) if zero else 'none'})")
out.append(f"- Personas with zero agents (gap): "
           f"{list(err.keys()) if err else 'none'}")
out.append(f"- Low-coverage personas (<3 agents): "
           f"{dict(warn) if warn else 'none'}")
out.append("")
out.append("---")
out.append("")
out.append("Baseline state: "
           "`tools/validate/cag_validate.baseline.json` (943 keys).  ")
out.append("Subsequent phases (P3 onwards) MUST NOT introduce new violation "
           "keys; the baseline is the floor, not the ceiling.")

target = P / "reports" / "P2_baseline_violations.md"
target.write_text("\n".join(out), encoding="utf-8")
print(f"wrote {target}")
