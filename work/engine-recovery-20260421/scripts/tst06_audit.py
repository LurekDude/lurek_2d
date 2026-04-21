#!/usr/bin/env python3
"""TST-06 audit: enforce one test file per module per layer in tests/lua/."""
import argparse, io, os, subprocess, sys
from collections import defaultdict
from pathlib import Path

LAYERS = ["unit", "evidence", "golden", "stress", "security", "config"]
ROOT = Path(__file__).resolve().parents[3]
TESTS = ROOT / "tests" / "lua"
LOG_DIR = ROOT / "work" / "engine-recovery-20260421" / "logs"


def infer_module(filename: str, layer: str) -> str:
    # filename like test_<rest>.lua
    stem = filename[5:-4] if filename.startswith("test_") and filename.endswith(".lua") else filename
    tokens = stem.split("_")
    if len(tokens) > 1 and tokens[-1] == layer:
        tokens = tokens[:-1]
    return tokens[0] if tokens else stem


def collect():
    groups = defaultdict(list)
    for layer in LAYERS:
        d = TESTS / layer
        if not d.is_dir():
            continue
        for f in sorted(d.iterdir()):
            if not f.is_file() or not f.name.endswith(".lua"):
                continue
            if f.name.startswith("_"):
                continue
            module = infer_module(f.name, layer)
            groups[(layer, module)].append(f)
    return groups


def report(groups):
    violations = {k: v for k, v in groups.items() if len(v) > 1}
    print(f"TST-06 audit — scanned layers: {', '.join(LAYERS)}")
    print(f"Total groups: {len(groups)}  Violations (>1 file): {len(violations)}")
    if not violations:
        print("OK — zero TST-06 violations.")
        return violations
    ranked = sorted(violations.items(), key=lambda kv: -len(kv[1]))
    print("\nTop groups by file count:")
    for (layer, module), files in ranked[:10]:
        total_lines = sum(sum(1 for _ in io.open(f, encoding="utf-8", errors="replace")) for f in files)
        print(f"  [{layer}/{module}] files={len(files)} lines={total_lines}")
        for f in files:
            print(f"    - {f.relative_to(ROOT).as_posix()}")
    return violations


def apply(groups, log_lines):
    violations = {k: v for k, v in groups.items() if len(v) > 1}
    merged_count = 0
    removed_count = 0
    pairs = []  # (deleted_relpath, canonical_relpath)
    for (layer, module), files in sorted(violations.items()):
        canonical_name = f"test_{module}_{layer}.lua"
        canonical_path = TESTS / layer / canonical_name
        files_sorted = sorted(files, key=lambda p: p.name)
        # ensure canonical first if present
        files_sorted.sort(key=lambda p: (p.name != canonical_name, p.name))
        chunks = []
        non_canonical = []
        for f in files_sorted:
            text = io.open(f, encoding="utf-8", errors="replace").read()
            if f.name == canonical_name:
                chunks.append(text)
            else:
                rel = f.relative_to(ROOT).as_posix()
                header = f"-- @origin: {rel}\n-- @merged-by: tst06_audit.py\n"
                chunks.append(header + text)
                non_canonical.append(f)
        merged = "\n".join(c.rstrip("\n") for c in chunks) + "\n"
        merged = merged.replace("\r\n", "\n")
        io.open(canonical_path, "w", encoding="utf-8", newline="\n").write(merged)
        log_lines.append(f"MERGED group=[{layer}/{module}] -> {canonical_path.relative_to(ROOT).as_posix()} (n={len(files_sorted)})")
        merged_count += 1
        for f in non_canonical:
            rel = f.relative_to(ROOT).as_posix()
            r = subprocess.run(["git", "rm", "-f", rel], cwd=ROOT, capture_output=True, text=True)
            if r.returncode != 0:
                # fallback: unlink
                try:
                    f.unlink()
                except Exception:
                    pass
                log_lines.append(f"REMOVED-FS {rel}  (git rm rc={r.returncode}: {r.stderr.strip()})")
            else:
                log_lines.append(f"REMOVED {rel} -> {canonical_path.relative_to(ROOT).as_posix()}")
            pairs.append((rel, canonical_path.relative_to(ROOT).as_posix()))
            removed_count += 1
    log_lines.append(f"SUMMARY merged_groups={merged_count} files_removed={removed_count}")
    return pairs


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--report", action="store_true")
    g.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    groups = collect()
    if args.report:
        report(groups)
        return 0
    if args.apply:
        report(groups)
        log_lines = []
        apply(groups, log_lines)
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        out = LOG_DIR / "tst06.log"
        io.open(out, "w", encoding="utf-8", newline="\n").write("\n".join(log_lines) + "\n")
        for ln in log_lines:
            print(ln)
        print(f"Log written: {out.relative_to(ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
