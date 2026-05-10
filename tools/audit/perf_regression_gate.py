#!/usr/bin/env python3
"""
perf_regression_gate.py — lightweight perf/stress regression gate for CI.

Reads logs/data/test_analytics.json and enforces:
- minimum percentage of modules with stress coverage,
- non-regression against a stored baseline.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
ANALYTICS_PATH = WORKSPACE_ROOT / "logs" / "data" / "test_analytics.json"
BASELINE_PATH = WORKSPACE_ROOT / "logs" / "data" / "perf_baseline.json"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _module_list(analytics: dict) -> list[dict]:
    raw = analytics.get("modules", {})
    if isinstance(raw, list):
        return [m for m in raw if isinstance(m, dict)]
    if isinstance(raw, dict):
        return [m for m in raw.values() if isinstance(m, dict)]
    return []


def compute_stress_pct(analytics: dict) -> float:
    modules = _module_list(analytics)
    if not modules:
        return 0.0
    covered = sum(1 for m in modules if m.get("has_stress") is True)
    return (covered * 100.0) / len(modules)


def compute_avg_score(analytics: dict) -> float:
    modules = _module_list(analytics)
    if not modules:
        return 0.0
    scores = [float(m.get("score", 0.0)) for m in modules]
    if not scores:
        return 0.0
    return sum(scores) / len(scores)


def main() -> int:
    parser = argparse.ArgumentParser(description="Perf/stress regression gate")
    parser.add_argument("--min-stress-pct", type=float, default=35.0)
    parser.add_argument("--baseline", default=str(BASELINE_PATH))
    parser.add_argument("--update-baseline", action="store_true")
    args = parser.parse_args()

    if not ANALYTICS_PATH.exists():
        print(f"[FAIL] Missing analytics file: {ANALYTICS_PATH}")
        return 1

    analytics = load_json(ANALYTICS_PATH)
    current = {
        "stress_pct": round(compute_stress_pct(analytics), 2),
        "score": round(compute_avg_score(analytics), 3),
    }

    print(f"[INFO] stress_pct={current['stress_pct']:.2f}% score={current['score']:.2f}")

    if current["stress_pct"] < args.min_stress_pct:
        print(
            f"[FAIL] stress coverage {current['stress_pct']:.2f}% < {args.min_stress_pct:.2f}%"
        )
        return 1

    baseline_path = Path(args.baseline)
    if baseline_path.exists():
        baseline = load_json(baseline_path)
        base_stress = float(baseline.get("stress_pct", 0.0))
        base_score = float(baseline.get("score", 0.0))

        if current["stress_pct"] + 0.001 < base_stress:
            print(
                f"[FAIL] stress coverage regressed: {current['stress_pct']:.2f}% < {base_stress:.2f}%"
            )
            return 1

        if current["score"] + 0.001 < base_score:
            print(f"[FAIL] score regressed: {current['score']:.2f} < {base_score:.2f}")
            return 1

    if args.update_baseline or not baseline_path.exists():
        baseline_path.parent.mkdir(parents=True, exist_ok=True)
        baseline_path.write_text(json.dumps(current, indent=2), encoding="utf-8")
        print(f"[OK] baseline updated: {baseline_path}")

    print("[OK] perf/stress gate passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
