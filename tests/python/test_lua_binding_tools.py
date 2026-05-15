"""Tests for tool-side Lua binding snapshot extraction and validation."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


class LuaBindingToolTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tool = _load(
            "gen_lua_binding_reports_test",
            REPO / "tools" / "docs" / "gen_lua_binding_reports.py",
        )
        cls.code_snapshot = cls.tool.extract_binding_snapshot_from_code()
        cls.doc_snapshot = cls.tool.extract_binding_snapshot_from_docstrings()

    def test_code_snapshot_extracts_selected_entries_from_source_files(self) -> None:
        graph = self.code_snapshot.get_entry("lurek.graph.newGraph")
        self.assertIsNotNone(graph)
        self.assertEqual(graph.returns[0].lua_type, "LGraph")

        minimap = self.code_snapshot.get_entry("lurek.minimap.newMinimap")
        self.assertIsNotNone(minimap)
        self.assertEqual(len(minimap.parameters), 4)
        self.assertEqual(minimap.parameters[0].lua_type, "integer")
        self.assertTrue(minimap.parameters[2].optional)
        self.assertEqual(minimap.returns[0].lua_type, "LMinimap")

        nav_grid = self.code_snapshot.get_entry("lurek.pathfind.newNavGrid")
        self.assertIsNotNone(nav_grid)
        self.assertEqual(len(nav_grid.parameters), 2)
        self.assertEqual(nav_grid.parameters[0].lua_type, "integer")
        self.assertEqual(nav_grid.returns[0].lua_type, "LNavGrid")

        tween = self.code_snapshot.get_entry("lurek.tween.tween")
        self.assertIsNotNone(tween)
        self.assertEqual(len(tween.parameters), 4)
        self.assertEqual(tween.parameters[0].name, "duration")
        self.assertTrue(tween.parameters[3].optional)
        self.assertEqual(tween.returns[0].lua_type, "LTween")

        cancel = self.code_snapshot.get_entry("LTween:cancel")
        self.assertIsNotNone(cancel)
        self.assertEqual(cancel.parameters, [])
        self.assertEqual(cancel.returns[0].lua_type, "nil")

    def test_doc_snapshot_reads_selected_entries_from_source_files(self) -> None:
        graph = self.doc_snapshot.get_entry("lurek.graph.newGraph")
        self.assertIsNotNone(graph)
        self.assertIn("Creates an empty logistics graph", graph.summary)
        self.assertEqual(graph.returns[0].lua_type, "LGraph")

        minimap = self.doc_snapshot.get_entry("lurek.minimap.newMinimap")
        self.assertIsNotNone(minimap)
        self.assertEqual(minimap.parameters[0].name, "grid_w")
        self.assertEqual(minimap.parameters[0].lua_type, "integer")
        self.assertEqual(minimap.parameters[2].name, "display_w")
        self.assertEqual(minimap.returns[0].lua_type, "LMinimap")

        nav_grid = self.doc_snapshot.get_entry("lurek.pathfind.newNavGrid")
        self.assertIsNotNone(nav_grid)
        self.assertEqual(nav_grid.parameters[0].name, "width")
        self.assertEqual(nav_grid.returns[0].lua_type, "LNavGrid")

        tween = self.doc_snapshot.get_entry("lurek.tween.tween")
        self.assertIsNotNone(tween)
        self.assertEqual(tween.parameters[0].name, "duration")
        self.assertEqual(tween.parameters[3].lua_type, "string")
        self.assertTrue(tween.parameters[3].optional)

        cancel = self.doc_snapshot.get_entry("LTween:cancel")
        self.assertIsNotNone(cancel)
        self.assertEqual(cancel.parameters, [])

    def test_validation_reports_drift_categories(self) -> None:
        expected = self.tool.BindingSnapshot(
            source="code",
            source_dir="src/lua_api",
            entries=[
                self.tool.BindingEntry(
                    module="example",
                    namespace="lurek.example",
                    name="orderCase",
                    qualified_name="lurek.example.orderCase",
                    kind="function",
                    call_style=".",
                    owner="",
                    parameters=[
                        self.tool.BindingParam("x", "integer", "u32", False, False, True),
                        self.tool.BindingParam("y", "string", "String", True, False, True),
                    ],
                    returns=[self.tool.BindingReturn("LThing", "LuaThing", False, True)],
                    source_file="src/lua_api/example_api.rs",
                    line=1,
                ),
                self.tool.BindingEntry(
                    module="example",
                    namespace="lurek.example",
                    name="missingDoc",
                    qualified_name="lurek.example.missingDoc",
                    kind="function",
                    call_style=".",
                    owner="",
                    source_file="src/lua_api/example_api.rs",
                    line=2,
                ),
            ],
        )

        actual = self.tool.BindingSnapshot(
            source="docstrings",
            source_dir="src/lua_api",
            entries=[
                self.tool.BindingEntry(
                    module="example",
                    namespace="lurek.example",
                    name="orderCase",
                    qualified_name="lurek.example.orderCase",
                    kind="function",
                    call_style=".",
                    owner="",
                    parameters=[
                        self.tool.BindingParam("y", "integer", "integer", False, False, True),
                        self.tool.BindingParam("x", "number", "number", False, False, True),
                    ],
                    returns=[self.tool.BindingReturn("table", "table", True, True)],
                    source_file="src/lua_api/example_api.rs",
                    line=1,
                ),
                self.tool.BindingEntry(
                    module="example",
                    namespace="lurek.example",
                    name="phantomDoc",
                    qualified_name="lurek.example.phantomDoc",
                    kind="function",
                    call_style=".",
                    owner="",
                    source_file="src/lua_api/example_api.rs",
                    line=3,
                ),
            ],
        )

        report = self.tool.validate_binding_snapshots(expected, actual)
        self.assertEqual(report.missing_doc_entries, ["lurek.example.missingDoc"])
        self.assertEqual(report.phantom_doc_entries, ["lurek.example.phantomDoc"])
        self.assertTrue(report.parameter_order_mismatches)
        self.assertTrue(report.parameter_name_mismatches)
        self.assertTrue(report.parameter_type_mismatches)
        self.assertTrue(report.parameter_optionality_mismatches)
        self.assertTrue(report.return_type_mismatches)
        self.assertTrue(report.return_optionality_mismatches)


if __name__ == "__main__":
    unittest.main()