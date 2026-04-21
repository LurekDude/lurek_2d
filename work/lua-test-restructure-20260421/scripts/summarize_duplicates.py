"""One-off Phase 0 summary helper: compute duplicate module groups and residual buckets."""
import collections
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
INV = ROOT / "work" / "lua-test-restructure-20260421" / "data" / "inventory.json"

SUFFIXES = ("_evidence", "_golden", "_stress", "_security", "_unit", "_integration", "_library")
RESIDUAL_TOKENS = ("combined", "misc", "migrated_", "golden_text", "fuzz")


def base_module(path: str) -> str:
    stem = os.path.basename(path).rsplit(".", 1)[0]
    if stem.startswith("test_"):
        stem = stem[5:]
    for suf in SUFFIXES:
        if stem.endswith(suf):
            stem = stem[: -len(suf)]
            break
    return stem.split("_", 1)[0]


def main() -> None:
    data = json.loads(INV.read_text(encoding="utf-8"))
    per_layer: dict[str, dict[str, list[str]]] = collections.defaultdict(lambda: collections.defaultdict(list))
    for f in data["files"]:
        per_layer[f["layer"]][base_module(f["path"])].append(f["path"])

    dup_groups = 0
    dup_files = 0
    lines = ["Per-layer module-prefix groups with >1 file:"]
    for layer in sorted(per_layer):
        groups = {m: v for m, v in per_layer[layer].items() if len(v) > 1}
        if not groups:
            continue
        lines.append(f"[{layer}]")
        for mod, paths in sorted(groups.items()):
            names = [os.path.basename(p) for p in paths]
            lines.append(f"  {mod}: {len(paths)}  -> {names}")
            dup_groups += 1
            dup_files += len(paths)
    lines.append("")
    lines.append(f"TOTAL dup groups: {dup_groups}")
    lines.append(f"TOTAL files in dup groups: {dup_files}")

    residual = [f["path"] for f in data["files"] if any(tok in os.path.basename(f["path"]) for tok in RESIDUAL_TOKENS)]
    lines.append("")
    lines.append(f"Residual-bucket files: {len(residual)}")
    for p in residual:
        lines.append(f"  {p}")

    out = ROOT / "work" / "lua-test-restructure-20260421" / "data" / "duplicate_groups.txt"
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
