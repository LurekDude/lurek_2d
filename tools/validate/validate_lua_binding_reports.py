#!/usr/bin/env python3
"""Validate docstring bindings against code-derived Lua registration snapshots."""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
GENERATOR_PATH = ROOT / "tools" / "docs" / "gen_lua_binding_reports.py"


def _load_generator():
    spec = importlib.util.spec_from_file_location("gen_lua_binding_reports_for_validation", GENERATOR_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {GENERATOR_PATH}")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


GEN = _load_generator()


def _report_counts(report) -> dict:
    return {
        "missing_doc_entries": len(report.missing_doc_entries),
        "phantom_doc_entries": len(report.phantom_doc_entries),
        "parameter_count_mismatches": len(report.parameter_count_mismatches),
        "parameter_order_mismatches": len(report.parameter_order_mismatches),
        "parameter_name_mismatches": len(report.parameter_name_mismatches),
        "parameter_type_mismatches": len(report.parameter_type_mismatches),
        "parameter_optionality_mismatches": len(report.parameter_optionality_mismatches),
        "return_count_mismatches": len(report.return_count_mismatches),
        "return_type_mismatches": len(report.return_type_mismatches),
        "return_optionality_mismatches": len(report.return_optionality_mismatches),
    }


def _print_text(report) -> None:
    counts = _report_counts(report)
    print("Lua binding validation")
    print("- missing doc entries: {}".format(counts["missing_doc_entries"]))
    print("- phantom doc entries: {}".format(counts["phantom_doc_entries"]))
    print("- parameter count mismatches: {}".format(counts["parameter_count_mismatches"]))
    print("- parameter order mismatches: {}".format(counts["parameter_order_mismatches"]))
    print("- parameter name mismatches: {}".format(counts["parameter_name_mismatches"]))
    print("- parameter type mismatches: {}".format(counts["parameter_type_mismatches"]))
    print("- parameter optionality mismatches: {}".format(counts["parameter_optionality_mismatches"]))
    print("- return count mismatches: {}".format(counts["return_count_mismatches"]))
    print("- return type mismatches: {}".format(counts["return_type_mismatches"]))
    print("- return optionality mismatches: {}".format(counts["return_optionality_mismatches"]))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate /// Lua binding docs against code-derived registration snapshots.")
    parser.add_argument("--source-dir", default=str(GEN.SRC_LUA_API_DIR))
    parser.add_argument("--code-output", default=GEN.default_binding_code_snapshot_path())
    parser.add_argument("--doc-output", default=GEN.default_binding_docstring_snapshot_path())
    parser.add_argument("--report-output", default=GEN.default_binding_validation_report_path())
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args(argv)

    _, _, report = GEN.generate_binding_reports(
        source_dir=Path(args.source_dir),
        code_output=args.code_output,
        doc_output=args.doc_output,
        report_output=args.report_output,
    )

    if args.format == "json":
        print(json.dumps(report.to_dict(), indent=2, ensure_ascii=False))
    else:
        _print_text(report)

    return 0 if report.is_clean() else 1


if __name__ == "__main__":
    raise SystemExit(main())