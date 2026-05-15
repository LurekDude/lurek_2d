#!/usr/bin/env python3
"""Generate source-derived Lua binding snapshots from src/lua_api/*.rs.

This tool emits two machine-readable views of the Lua API surface:
- code snapshot: what Rust registration code actually exposes
- docstring snapshot: what /// @param / @return markers currently document

The snapshots share one normalized schema so they can be diffed without any
engine/runtime support.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Optional


ROOT = Path(__file__).resolve().parents[2]
SRC_LUA_API_DIR = ROOT / "src" / "lua_api"
SOURCE_DIR_RELATIVE = "src/lua_api"
CODE_SNAPSHOT_RELATIVE = "logs/data/lua_api_bindings_from_code.json"
DOCSTRING_SNAPSHOT_RELATIVE = "logs/data/lua_api_bindings_from_docstrings.json"
VALIDATION_REPORT_RELATIVE = "logs/reports/lua_api_binding_validation.json"
MODULE_NAMESPACE_OVERRIDES = {"system": "runtime"}

TABLE_WRAPPER_NAMES = {
    "Vec",
    "HashMap",
    "BTreeMap",
    "IndexMap",
    "HashSet",
    "BTreeSet",
}

REGISTRATION_TABLE_FUNCTION = "table_function"
REGISTRATION_ADD_METHOD = "add_method"
REGISTRATION_ADD_METHOD_MUT = "add_method_mut"
REGISTRATION_ADD_FUNCTION = "add_function"


def _load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load module from {path}")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


GEN = _load_module("gen_lua_api_for_binding_reports", ROOT / "tools" / "docs" / "gen_lua_api.py")


@dataclass
class BindingParam:
    name: str
    lua_type: str
    raw_type: str
    optional: bool
    variadic: bool
    inferred: bool
    description: str = ""


@dataclass
class BindingReturn:
    lua_type: str
    raw_type: str
    optional: bool
    inferred: bool
    description: str = ""


@dataclass
class BindingEntry:
    module: str
    namespace: str
    name: str
    qualified_name: str
    kind: str
    call_style: str
    owner: str
    parameters: list[BindingParam] = field(default_factory=list)
    returns: list[BindingReturn] = field(default_factory=list)
    summary: str = ""
    raw_doc: str = ""
    source_signature: str = ""
    source_file: str = ""
    line: int = 0


@dataclass
class BindingSnapshot:
    source: str
    source_dir: str
    entries: list[BindingEntry] = field(default_factory=list)

    def entry_count(self) -> int:
        return len(self.entries)

    def get_entry(self, qualified_name: str) -> Optional[BindingEntry]:
        for entry in self.entries:
            if entry.qualified_name == qualified_name:
                return entry
        return None

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class BindingCountMismatch:
    qualified_name: str
    expected: int
    actual: int


@dataclass
class BindingParameterOrderMismatch:
    qualified_name: str
    name: str
    expected_index: int
    actual_index: int


@dataclass
class BindingIndexedStringMismatch:
    qualified_name: str
    index: int
    expected: str
    actual: str


@dataclass
class BindingIndexedBoolMismatch:
    qualified_name: str
    index: int
    expected: bool
    actual: bool


@dataclass
class BindingValidationReport:
    missing_doc_entries: list[str] = field(default_factory=list)
    phantom_doc_entries: list[str] = field(default_factory=list)
    parameter_count_mismatches: list[BindingCountMismatch] = field(default_factory=list)
    parameter_order_mismatches: list[BindingParameterOrderMismatch] = field(default_factory=list)
    parameter_name_mismatches: list[BindingIndexedStringMismatch] = field(default_factory=list)
    parameter_type_mismatches: list[BindingIndexedStringMismatch] = field(default_factory=list)
    parameter_optionality_mismatches: list[BindingIndexedBoolMismatch] = field(default_factory=list)
    return_count_mismatches: list[BindingCountMismatch] = field(default_factory=list)
    return_type_mismatches: list[BindingIndexedStringMismatch] = field(default_factory=list)
    return_optionality_mismatches: list[BindingIndexedBoolMismatch] = field(default_factory=list)

    def is_clean(self) -> bool:
        return not any(
            (
                self.missing_doc_entries,
                self.phantom_doc_entries,
                self.parameter_count_mismatches,
                self.parameter_order_mismatches,
                self.parameter_name_mismatches,
                self.parameter_type_mismatches,
                self.parameter_optionality_mismatches,
                self.return_count_mismatches,
                self.return_type_mismatches,
                self.return_optionality_mismatches,
            )
        )

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class ValueHint:
    lua_type: str
    raw_type: str
    optional: bool
    inferred: bool


@dataclass
class ParsedSignature:
    call_style: str = "."
    parameters: list[BindingParam] = field(default_factory=list)
    returns: list[BindingReturn] = field(default_factory=list)
    source_signature: str = ""


@dataclass
class NamedFunctionInfo:
    header: str
    doc_block: str


def default_binding_code_snapshot_path() -> str:
    return CODE_SNAPSHOT_RELATIVE


def default_binding_docstring_snapshot_path() -> str:
    return DOCSTRING_SNAPSHOT_RELATIVE


def default_binding_validation_report_path() -> str:
    return VALIDATION_REPORT_RELATIVE


def extract_binding_snapshot_from_code(source_dir: Path = SRC_LUA_API_DIR) -> BindingSnapshot:
    return _extract_binding_snapshot(source_dir, "code")


def extract_binding_snapshot_from_docstrings(source_dir: Path = SRC_LUA_API_DIR) -> BindingSnapshot:
    return _extract_binding_snapshot(source_dir, "docstrings")


def validate_binding_snapshots(expected: BindingSnapshot, actual: BindingSnapshot) -> BindingValidationReport:
    expected_map = {entry.qualified_name: entry for entry in expected.entries}
    actual_map = {entry.qualified_name: entry for entry in actual.entries}
    report = BindingValidationReport()

    for qualified_name in sorted(expected_map):
        if qualified_name not in actual_map:
            report.missing_doc_entries.append(qualified_name)
    for qualified_name in sorted(actual_map):
        if qualified_name not in expected_map:
            report.phantom_doc_entries.append(qualified_name)

    for qualified_name in sorted(expected_map):
        expected_entry = expected_map[qualified_name]
        actual_entry = actual_map.get(qualified_name)
        if actual_entry is None:
            continue

        if len(expected_entry.parameters) != len(actual_entry.parameters):
            report.parameter_count_mismatches.append(
                BindingCountMismatch(
                    qualified_name=qualified_name,
                    expected=len(expected_entry.parameters),
                    actual=len(actual_entry.parameters),
                )
            )

        actual_param_positions = {
            parameter.name: index for index, parameter in enumerate(actual_entry.parameters)
        }
        for expected_index, parameter in enumerate(expected_entry.parameters):
            actual_index = actual_param_positions.get(parameter.name)
            if actual_index is not None and actual_index != expected_index:
                report.parameter_order_mismatches.append(
                    BindingParameterOrderMismatch(
                        qualified_name=qualified_name,
                        name=parameter.name,
                        expected_index=expected_index,
                        actual_index=actual_index,
                    )
                )

        param_count = min(len(expected_entry.parameters), len(actual_entry.parameters))
        for index in range(param_count):
            expected_param = expected_entry.parameters[index]
            actual_param = actual_entry.parameters[index]
            if expected_param.name != actual_param.name:
                report.parameter_name_mismatches.append(
                    BindingIndexedStringMismatch(
                        qualified_name=qualified_name,
                        index=index,
                        expected=expected_param.name,
                        actual=actual_param.name,
                    )
                )
            if expected_param.inferred and actual_param.inferred and expected_param.lua_type != actual_param.lua_type:
                report.parameter_type_mismatches.append(
                    BindingIndexedStringMismatch(
                        qualified_name=qualified_name,
                        index=index,
                        expected=expected_param.lua_type,
                        actual=actual_param.lua_type,
                    )
                )
            if expected_param.optional != actual_param.optional:
                report.parameter_optionality_mismatches.append(
                    BindingIndexedBoolMismatch(
                        qualified_name=qualified_name,
                        index=index,
                        expected=expected_param.optional,
                        actual=actual_param.optional,
                    )
                )

        if len(expected_entry.returns) != len(actual_entry.returns):
            report.return_count_mismatches.append(
                BindingCountMismatch(
                    qualified_name=qualified_name,
                    expected=len(expected_entry.returns),
                    actual=len(actual_entry.returns),
                )
            )

        return_count = min(len(expected_entry.returns), len(actual_entry.returns))
        for index in range(return_count):
            expected_return = expected_entry.returns[index]
            actual_return = actual_entry.returns[index]
            if expected_return.inferred and actual_return.inferred and expected_return.lua_type != actual_return.lua_type:
                report.return_type_mismatches.append(
                    BindingIndexedStringMismatch(
                        qualified_name=qualified_name,
                        index=index,
                        expected=expected_return.lua_type,
                        actual=actual_return.lua_type,
                    )
                )
            if expected_return.optional != actual_return.optional:
                report.return_optionality_mismatches.append(
                    BindingIndexedBoolMismatch(
                        qualified_name=qualified_name,
                        index=index,
                        expected=expected_return.optional,
                        actual=actual_return.optional,
                    )
                )

    return report


def export_binding_snapshot(snapshot: BindingSnapshot, path: str) -> None:
    _write_json(ROOT / path, snapshot.to_dict())


def export_binding_validation(report: BindingValidationReport, path: str) -> None:
    _write_json(ROOT / path, report.to_dict())


def generate_binding_reports(
    source_dir: Path = SRC_LUA_API_DIR,
    code_output: str = CODE_SNAPSHOT_RELATIVE,
    doc_output: str = DOCSTRING_SNAPSHOT_RELATIVE,
    report_output: str = VALIDATION_REPORT_RELATIVE,
) -> tuple[BindingSnapshot, BindingSnapshot, BindingValidationReport]:
    code_snapshot = extract_binding_snapshot_from_code(source_dir)
    doc_snapshot = extract_binding_snapshot_from_docstrings(source_dir)
    report = validate_binding_snapshots(code_snapshot, doc_snapshot)
    export_binding_snapshot(code_snapshot, code_output)
    export_binding_snapshot(doc_snapshot, doc_output)
    export_binding_validation(report, report_output)
    return code_snapshot, doc_snapshot, report


def _extract_binding_snapshot(source_dir: Path, mode: str) -> BindingSnapshot:
    entries_by_name: dict[str, BindingEntry] = {}
    for api_file in sorted(source_dir.glob("*_api.rs")):
        lines = api_file.read_text(encoding="utf-8").splitlines()
        owner_display_names = _collect_owner_display_names(lines)
        named_functions = _collect_named_functions(lines)
        for fn in GEN.extract_lua_functions(api_file):
            entry = _build_binding_entry(mode, fn, lines, owner_display_names, named_functions)
            if entry is not None:
                entries_by_name[entry.qualified_name] = entry
    return BindingSnapshot(
        source=mode,
        source_dir=SOURCE_DIR_RELATIVE,
        entries=[entries_by_name[name] for name in sorted(entries_by_name)],
    )


def _build_binding_entry(mode: str, fn, lines: list[str], owner_display_names: dict[str, str], named_functions: dict[str, NamedFunctionInfo]) -> Optional[BindingEntry]:
    index = max(fn.line - 1, 0)
    qualified_name = fn.lua_name
    namespace, name, call_style = _qualified_name_parts(qualified_name)
    module = _module_name_from_entry(qualified_name, fn.module)
    owner = fn.owner_type or ""
    registration_kind = _detect_registration_kind(lines[index] if index < len(lines) else "")
    doc_block = _binding_doc_block(lines, index, named_functions)

    if mode == "docstrings":
        if not doc_block:
            return None
        parameters = _parse_doc_parameters(doc_block)
        if call_style == ":" and parameters and parameters[0].name == "self":
            parameters = parameters[1:]
        return BindingEntry(
            module=module,
            namespace=namespace,
            name=name,
            qualified_name=qualified_name,
            kind=fn.kind,
            call_style=call_style,
            owner=owner,
            parameters=parameters,
            returns=_parse_doc_returns(doc_block),
            summary=_first_summary_line(doc_block),
            raw_doc=doc_block,
            source_signature="",
            source_file=fn.file,
            line=fn.line,
        )

    signature = _parse_code_signature(lines, index, registration_kind, call_style, owner_display_names, named_functions)
    return BindingEntry(
        module=module,
        namespace=namespace,
        name=name,
        qualified_name=qualified_name,
        kind=fn.kind,
        call_style=call_style,
        owner=owner,
        parameters=signature.parameters,
        returns=signature.returns,
        summary="",
        raw_doc="",
        source_signature=signature.source_signature,
        source_file=fn.file,
        line=fn.line,
    )


def _parse_code_signature(
    lines: list[str],
    index: int,
    registration_kind: str,
    call_style: str,
    owner_display_names: dict[str, str],
    named_functions: dict[str, NamedFunctionInfo],
) -> ParsedSignature:
    window = _collect_window(lines, index, 20)
    named_function = _self_named_function(window) or _named_create_function(window)
    if named_function and named_function in named_functions:
        signature = _parse_function_signature(
            named_functions[named_function].header,
            registration_kind,
            owner_display_names,
        )
    else:
        signature = _parse_closure_signature(lines, index, registration_kind, owner_display_names)

    if registration_kind == REGISTRATION_ADD_FUNCTION and call_style == ":":
        if signature.parameters and _is_userdata_receiver_parameter(signature.parameters[0]):
            signature.parameters.pop(0)
    signature.call_style = call_style
    return signature


def _parse_closure_signature(
    lines: list[str],
    index: int,
    registration_kind: str,
    owner_display_names: dict[str, str],
) -> ParsedSignature:
    window = _collect_window(lines, index, 20)
    signature_head, return_type = _closure_head_and_return_type(window)
    if signature_head is None:
        return ParsedSignature(call_style=_default_call_style(registration_kind))

    parameters = _parse_callable_parameters(signature_head, registration_kind, owner_display_names)
    if return_type:
        returns = _parse_return_type_list(return_type, owner_display_names)
    else:
        body_text = _closure_body_text(lines, index, window)
        returns = _infer_returns_from_text(body_text, owner_display_names)

    return ParsedSignature(
        call_style=_default_call_style(registration_kind),
        parameters=parameters,
        returns=returns,
        source_signature=signature_head,
    )


def _parse_function_signature(header: str, registration_kind: str, owner_display_names: dict[str, str]) -> ParsedSignature:
    fn_index = header.find("fn ")
    if fn_index < 0:
        return ParsedSignature(call_style=_default_call_style(registration_kind))
    after_fn = header[fn_index + 3 :]
    params_text = _parenthesized_segment(after_fn)
    parameters = _parse_callable_parameters(params_text or "", registration_kind, owner_display_names)
    return_type = _function_return_type(header)
    returns = _parse_return_type_list(return_type, owner_display_names) if return_type else []
    return ParsedSignature(
        call_style=_default_call_style(registration_kind),
        parameters=parameters,
        returns=returns,
        source_signature=header.strip(),
    )


def _parse_callable_parameters(source_signature: str, registration_kind: str, owner_display_names: dict[str, str]) -> list[BindingParam]:
    params_text = source_signature
    if source_signature.lstrip().startswith("|"):
        params_text = _closure_parameter_segment(source_signature) or ""
    tokens = _split_top_level(params_text, ",")
    parsed: list[BindingParam] = []
    for token in tokens:
        parsed.extend(_parse_parameter_token(token, owner_display_names))

    public_parameters = list(parsed)
    if registration_kind in (REGISTRATION_TABLE_FUNCTION, REGISTRATION_ADD_FUNCTION):
        if public_parameters and _is_lua_context_parameter(public_parameters[0]):
            public_parameters.pop(0)
    if registration_kind in (REGISTRATION_ADD_METHOD, REGISTRATION_ADD_METHOD_MUT):
        if public_parameters and _is_lua_context_parameter(public_parameters[0]):
            public_parameters.pop(0)
        if public_parameters and (
            public_parameters[0].name == "" or _is_receiver_parameter(public_parameters[0])
        ):
            public_parameters.pop(0)
    return public_parameters


def _parse_parameter_token(token: str, owner_display_names: dict[str, str]) -> list[BindingParam]:
    trimmed = token.strip()
    if not trimmed or trimmed == "()":
        return []

    split = _split_pattern_and_type(trimmed)
    if split is None:
        normalized_name = _normalize_parameter_name(trimmed)
        return [_binding_param(normalized_name, "any", "any", False, False, True, "")]

    pattern, raw_type = split
    pattern = pattern.strip()
    raw_type = raw_type.strip()

    if _is_parenthesized(pattern) and _is_parenthesized(raw_type):
        names = _split_top_level(_inner_parenthesized(pattern) or "", ",")
        types = _split_top_level(_inner_parenthesized(raw_type) or "", ",")
        parameters: list[BindingParam] = []
        for name, raw_inner_type in zip(names, types):
            normalized_name = _normalize_parameter_name(name)
            if not normalized_name or normalized_name == "()":
                continue
            if "LuaMultiValue" in raw_inner_type:
                parameters.append(_binding_param("...", "any", raw_inner_type.strip(), False, True, True, ""))
                continue
            hint = _normalize_rust_type(raw_inner_type.strip(), owner_display_names)
            parameters.append(
                _binding_param(
                    normalized_name,
                    hint.lua_type,
                    raw_inner_type.strip(),
                    hint.optional,
                    False,
                    hint.inferred,
                    "",
                )
            )
        return parameters

    if "LuaMultiValue" in raw_type:
        return [_binding_param("...", "any", raw_type, False, True, True, "")]

    normalized_name = _normalize_parameter_name(pattern)
    hint = _normalize_rust_type(raw_type, owner_display_names)
    return [
        _binding_param(
            normalized_name,
            hint.lua_type,
            raw_type,
            hint.optional,
            False,
            hint.inferred,
            "",
        )
    ]


def _parse_return_type_list(raw_return_type: str, owner_display_names: dict[str, str]) -> list[BindingReturn]:
    stripped = _strip_result_wrapper(raw_return_type.strip())
    if not stripped.strip():
        return []
    if stripped.strip() == "()":
        return [_binding_return("nil", raw_return_type.strip(), False, True, "")]
    if _is_parenthesized(stripped):
        returns = []
        for segment in _split_top_level(_inner_parenthesized(stripped) or "", ","):
            if not segment.strip():
                continue
            hint = _normalize_rust_type(segment.strip(), owner_display_names)
            returns.append(_binding_return(hint.lua_type, segment.strip(), hint.optional, hint.inferred, ""))
        return returns
    hint = _normalize_rust_type(stripped, owner_display_names)
    return [_binding_return(hint.lua_type, stripped, hint.optional, hint.inferred, "")]


def _infer_returns_from_text(body_text: str, owner_display_names: dict[str, str]) -> list[BindingReturn]:
    if not body_text.strip():
        return []
    variable_hints = _collect_variable_hints(body_text, owner_display_names)
    expression = _last_ok_expression(body_text) or body_text.strip()
    hints = _infer_return_expression(expression, variable_hints, owner_display_names)
    return [
        _binding_return(hint.lua_type, hint.raw_type, hint.optional, hint.inferred, "")
        for hint in hints
    ]


def _infer_return_expression(expression: str, variable_hints: dict[str, ValueHint], owner_display_names: dict[str, str]) -> list[ValueHint]:
    trimmed = expression.strip().rstrip(";").strip()
    if not trimmed:
        return []
    if trimmed == "()":
        return [ValueHint(lua_type="nil", raw_type="()", optional=False, inferred=True)]
    if trimmed.startswith("Some("):
        inner = _balanced_suffix(trimmed[4:], "(", ")")
        if inner is not None:
            hints = _infer_return_expression(inner, variable_hints, owner_display_names)
            for hint in hints:
                hint.optional = True
            return hints
    if trimmed == "None":
        return [ValueHint(lua_type="nil", raw_type="None", optional=True, inferred=True)]
    if _is_parenthesized(trimmed):
        hints: list[ValueHint] = []
        for segment in _split_top_level(_inner_parenthesized(trimmed) or "", ","):
            hints.extend(_infer_return_expression(segment, variable_hints, owner_display_names))
        return hints
    return [_infer_value_hint(trimmed, variable_hints, owner_display_names)]


def _collect_variable_hints(body_text: str, owner_display_names: dict[str, str]) -> dict[str, ValueHint]:
    hints: dict[str, ValueHint] = {}
    for raw_line in body_text.splitlines():
        line = raw_line.strip()
        if not line.startswith("let "):
            continue
        stripped = line[4:]
        if "=" not in stripped:
            continue
        left, right = stripped.split("=", 1)
        value_expression = right.strip().rstrip(";").strip()
        split = _split_pattern_and_type(left)
        if split is None:
            name = _normalize_parameter_name(left)
            explicit_type = None
        else:
            name = _normalize_parameter_name(split[0])
            explicit_type = split[1].strip()
        if not name or name == "()":
            continue
        if explicit_type:
            simplified = _strip_references(explicit_type)
            if any(token in simplified for token in ("LuaAnyUserData", "AnyUserData")) and "create_userdata" in value_expression:
                hint = _infer_value_hint(value_expression, hints, owner_display_names)
            else:
                hint = _normalize_rust_type(explicit_type, owner_display_names)
        else:
            hint = _infer_value_hint(value_expression, hints, owner_display_names)
        hints[name] = hint
    return hints


def _infer_value_hint(expression: str, variable_hints: dict[str, ValueHint], owner_display_names: dict[str, str]) -> ValueHint:
    trimmed = expression.strip().rstrip("?").strip()
    if trimmed in variable_hints:
        return variable_hints[trimmed]
    if trimmed.startswith("Some("):
        inner = _balanced_suffix(trimmed[4:], "(", ")")
        if inner is not None:
            hint = _infer_value_hint(inner, variable_hints, owner_display_names)
            return ValueHint(hint.lua_type, hint.raw_type, True, hint.inferred)
    if trimmed == "None":
        return ValueHint(lua_type="nil", raw_type="None", optional=True, inferred=True)
    if trimmed.startswith("lua.create_table"):
        return ValueHint(lua_type="table", raw_type="LuaTable", optional=False, inferred=True)
    if trimmed.startswith("lua.create_string"):
        return ValueHint(lua_type="string", raw_type="LuaString", optional=False, inferred=True)
    if trimmed.startswith("lua.create_userdata"):
        inner = _balanced_suffix(trimmed[len("lua.create_userdata") :], "(", ")")
        if inner is not None:
            inner_hint = _infer_value_hint(inner, variable_hints, owner_display_names)
            if inner_hint.lua_type != "any":
                return ValueHint(
                    lua_type=inner_hint.lua_type,
                    raw_type=inner_hint.raw_type,
                    optional=inner_hint.optional,
                    inferred=inner_hint.inferred,
                )
        return ValueHint(lua_type="userdata", raw_type="LuaAnyUserData", optional=False, inferred=True)
    owner_type = _owner_type_from_expression(trimmed, owner_display_names)
    if owner_type:
        return ValueHint(lua_type=owner_type, raw_type=owner_type, optional=False, inferred=True)
    if trimmed.startswith('"') or trimmed.startswith("format!(") or trimmed.endswith(".to_string()"):
        return ValueHint(lua_type="string", raw_type=trimmed, optional=False, inferred=True)
    if trimmed in ("true", "false") or _looks_like_boolean_expression(trimmed):
        return ValueHint(lua_type="boolean", raw_type=trimmed, optional=False, inferred=True)
    number_type = _numeric_literal_type(trimmed)
    if number_type:
        return ValueHint(lua_type=number_type, raw_type=trimmed, optional=False, inferred=True)
    identifier = _last_method_identifier(trimmed)
    if identifier:
        if _looks_like_boolean_name(identifier):
            return ValueHint(lua_type="boolean", raw_type=trimmed, optional=False, inferred=True)
        if _looks_like_integer_name(identifier):
            return ValueHint(lua_type="integer", raw_type=trimmed, optional=False, inferred=True)
    return ValueHint(lua_type="any", raw_type=trimmed, optional=False, inferred=False)


def _owner_type_from_expression(expression: str, owner_display_names: dict[str, str]) -> Optional[str]:
    trimmed = expression.strip()
    brace_index = trimmed.find("{")
    path_index = trimmed.find("::")
    if brace_index >= 0 and (path_index < 0 or brace_index < path_index):
        candidate = trimmed[:brace_index].strip()
    elif path_index >= 0:
        candidate = trimmed[:path_index].strip()
    else:
        candidate = ""
    if not candidate:
        return None
    identifier = _last_path_segment(candidate)
    if identifier.startswith("Lua"):
        return _owner_display_name(identifier, owner_display_names)
    if identifier.startswith("L"):
        return identifier
    return None


def _binding_doc_block(lines: list[str], index: int, named_functions: dict[str, NamedFunctionInfo]) -> str:
    window = _collect_window(lines, index, 20)
    named_function = _self_named_function(window) or _named_create_function(window)
    if named_function and named_function in named_functions:
        doc_block = named_functions[named_function].doc_block
        if doc_block:
            return doc_block
    return _collect_doc_block_above(lines, index)


def _parse_doc_parameters(doc_block: str) -> list[BindingParam]:
    parameters: list[BindingParam] = []
    for line in doc_block.splitlines():
        trimmed = line.strip()
        if not trimmed.startswith("@param"):
            continue
        columns = [part.strip() for part in trimmed.split("|")]
        if len(columns) < 4:
            continue
        name = columns[1]
        type_text = columns[2]
        description = " | ".join(columns[3:])
        variadic = name == "..."
        optional = False
        if name.endswith("?") and not variadic:
            optional = True
            name = name[:-1]
        type_hint = _normalize_doc_type(type_text)
        parameters.append(
            _binding_param(
                name,
                type_hint.lua_type,
                type_text,
                optional or type_hint.optional,
                variadic,
                True,
                description,
            )
        )
    return parameters


def _parse_doc_returns(doc_block: str) -> list[BindingReturn]:
    returns: list[BindingReturn] = []
    for line in doc_block.splitlines():
        trimmed = line.strip()
        if not trimmed.startswith("@return"):
            continue
        columns = [part.strip() for part in trimmed.split("|")]
        if len(columns) < 3:
            continue
        type_text = columns[1]
        description = " | ".join(columns[2:])
        type_hint = _normalize_doc_type(type_text)
        returns.append(
            _binding_return(
                type_hint.lua_type,
                type_text,
                type_hint.optional,
                True,
                description,
            )
        )
    return returns


def _normalize_doc_type(raw_type: str) -> ValueHint:
    cleaned = raw_type.strip().strip("`").replace(" ", "")
    optional = False
    if cleaned.endswith("?"):
        cleaned = cleaned[:-1]
        optional = True
    parts = [part for part in cleaned.split("|") if part]
    if len(parts) == 2 and "nil" in parts:
        optional = True
        parts = [part for part in parts if part != "nil"]
    normalized_parts = []
    for part in sorted(set(parts)):
        normalized_parts.append(
            {
                "int": "integer",
                "integer": "integer",
                "u8": "integer",
                "u16": "integer",
                "u32": "integer",
                "u64": "integer",
                "usize": "integer",
                "i8": "integer",
                "i16": "integer",
                "i32": "integer",
                "i64": "integer",
                "isize": "integer",
                "float": "number",
                "double": "number",
                "number": "number",
                "f32": "number",
                "f64": "number",
                "bool": "boolean",
                "boolean": "boolean",
                "str": "string",
                "string": "string",
            }.get(part, part)
        )
    normalized = "|".join(normalized_parts) if normalized_parts else "nil"
    return ValueHint(lua_type=normalized, raw_type=raw_type.strip(), optional=optional, inferred=True)


def _normalize_rust_type(raw_type: str, owner_display_names: dict[str, str]) -> ValueHint:
    cleaned = _strip_references(raw_type.strip())
    option_inner = _wrapper_inner_type(cleaned, "Option")
    if option_inner is not None:
        hint = _normalize_rust_type(option_inner, owner_display_names)
        hint.optional = True
        return hint

    simplified = _strip_result_wrapper(cleaned)
    if simplified == "()":
        return ValueHint(lua_type="nil", raw_type=raw_type.strip(), optional=False, inferred=True)

    if any(_wrapper_inner_type(simplified, name) is not None for name in TABLE_WRAPPER_NAMES):
        return ValueHint(lua_type="table", raw_type=raw_type.strip(), optional=False, inferred=True)

    last_segment = _last_path_segment(simplified)
    if last_segment in {"String", "str", "LuaString"}:
        lua_type = "string"
    elif last_segment == "bool":
        lua_type = "boolean"
    elif last_segment in {"f32", "f64"}:
        lua_type = "number"
    elif last_segment in {"u8", "u16", "u32", "u64", "usize", "i8", "i16", "i32", "i64", "isize"}:
        lua_type = "integer"
    elif last_segment in {"LuaTable", "Table"}:
        lua_type = "table"
    elif last_segment in {"LuaFunction", "Function"}:
        lua_type = "function"
    elif last_segment in {"LuaValue", "Value", "LuaSerdeValue"}:
        lua_type = "any"
    elif last_segment in {"LuaAnyUserData", "AnyUserData"}:
        lua_type = "userdata"
    elif last_segment in owner_display_names:
        return ValueHint(
            lua_type=_owner_display_name(last_segment, owner_display_names),
            raw_type=raw_type.strip(),
            optional=False,
            inferred=True,
        )
    elif last_segment.startswith("Lua"):
        return ValueHint(
            lua_type=_owner_display_name(last_segment, owner_display_names),
            raw_type=raw_type.strip(),
            optional=False,
            inferred=True,
        )
    elif last_segment.startswith("L"):
        lua_type = last_segment
    else:
        lua_type = "any"

    inferred = lua_type != "any" or last_segment in {"LuaValue", "Value", "LuaAnyUserData", "AnyUserData"}
    return ValueHint(lua_type=lua_type, raw_type=raw_type.strip(), optional=False, inferred=inferred)


def _collect_owner_display_names(lines: list[str]) -> dict[str, str]:
    names: dict[str, str] = {}
    _collect_luna_type_names(lines, names)

    current_owner: Optional[str] = None
    depth = 0
    for index, line in enumerate(lines):
        trimmed = line.strip()
        if current_owner is None:
            owner = _parse_lua_userdata_impl_owner(trimmed)
            if owner:
                current_owner = owner
                depth = _brace_delta(trimmed)
                continue
        if current_owner:
            if 'add_method("type"' in trimmed or 'add_method_mut("type"' in trimmed:
                window = _collect_window(lines, index, 8)
                type_name = _ok_string_literal(window)
                if type_name:
                    names[current_owner] = type_name
            depth += _brace_delta(trimmed)
            if depth <= 0:
                current_owner = None
                depth = 0
    return names


def _collect_luna_type_names(lines: list[str], names: dict[str, str]) -> None:
    current_owner: Optional[str] = None
    depth = 0
    for line in lines:
        trimmed = line.strip()
        if current_owner is None:
            owner = _parse_luna_type_impl_owner(trimmed)
            if owner:
                current_owner = owner
                depth = _brace_delta(trimmed)
                continue
        if current_owner:
            if "TYPE_NAME" in trimmed:
                type_name = _first_string_literal(trimmed)
                if type_name:
                    names[current_owner] = type_name
            depth += _brace_delta(trimmed)
            if depth <= 0:
                current_owner = None
                depth = 0


def _collect_named_functions(lines: list[str]) -> dict[str, NamedFunctionInfo]:
    functions: dict[str, NamedFunctionInfo] = {}
    for index, line in enumerate(lines):
        trimmed = line.strip()
        if "fn " not in trimmed or trimmed.startswith("//"):
            continue
        function_name = _function_name_from_line(trimmed)
        if not function_name:
            continue
        functions[function_name] = NamedFunctionInfo(
            header=_collect_header(lines, index),
            doc_block=_collect_doc_block_above(lines, index),
        )
    return functions


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def _qualified_name_parts(qualified_name: str) -> tuple[str, str, str]:
    if ":" in qualified_name:
        namespace, name = qualified_name.split(":", 1)
        return namespace, name, ":"
    namespace, name = qualified_name.rsplit(".", 1)
    return namespace, name, "."


def _module_name_from_entry(qualified_name: str, default_module: str) -> str:
    if qualified_name.startswith("lurek."):
        parts = qualified_name.split(".")
        if len(parts) >= 2:
            return parts[1]
    return MODULE_NAMESPACE_OVERRIDES.get(default_module, default_module)


def _detect_registration_kind(line: str) -> str:
    if "methods.add_method_mut(" in line:
        return REGISTRATION_ADD_METHOD_MUT
    if "methods.add_method(" in line or "dispatch_arith!(" in line:
        return REGISTRATION_ADD_METHOD
    if "methods.add_function(" in line:
        return REGISTRATION_ADD_FUNCTION
    return REGISTRATION_TABLE_FUNCTION


def _default_call_style(registration_kind: str) -> str:
    return ":" if registration_kind != REGISTRATION_TABLE_FUNCTION else "."


def _binding_param(name: str, lua_type: str, raw_type: str, optional: bool, variadic: bool, inferred: bool, description: str) -> BindingParam:
    return BindingParam(
        name=name,
        lua_type=lua_type,
        raw_type=raw_type,
        optional=optional,
        variadic=variadic,
        inferred=inferred,
        description=description,
    )


def _binding_return(lua_type: str, raw_type: str, optional: bool, inferred: bool, description: str) -> BindingReturn:
    return BindingReturn(
        lua_type=lua_type,
        raw_type=raw_type,
        optional=optional,
        inferred=inferred,
        description=description,
    )


def _collect_window(lines: list[str], start: int, max_lines: int) -> str:
    return " ".join(line.strip() for line in lines[start : start + max_lines])


def _collect_header(lines: list[str], start: int) -> str:
    header_parts = []
    for line in lines[start : start + 24]:
        header_parts.append(line.strip())
        if "{" in line:
            break
    return " ".join(header_parts)


def _collect_block(lines: list[str], start: int) -> str:
    body_parts = []
    started = False
    depth = 0
    for line in lines[start : start + 256]:
        if not started:
            if "{" in line:
                offset = line.find("{")
                started = True
                depth = 1
                body_parts.append(line[offset + 1 :])
                depth += _brace_delta(line[offset + 1 :])
                if depth <= 0:
                    break
            continue
        depth += _brace_delta(line)
        body_parts.append(line)
        if depth <= 0:
            break
    return "\n".join(body_parts)


def _closure_head_and_return_type(window: str) -> tuple[Optional[str], Optional[str]]:
    start = window.find("|")
    if start < 0:
        return None, None
    end = window.find("|", start + 1)
    if end < 0:
        return None, None
    signature_head = window[start : end + 1].strip()
    tail = window[end + 1 :].lstrip()
    return_type = None
    if tail.startswith("->"):
        return_type = _extract_type_before_body(tail[2:].lstrip())
    return signature_head, return_type


def _closure_parameter_segment(signature_head: str) -> Optional[str]:
    trimmed = signature_head.strip()
    if not (trimmed.startswith("|") and trimmed.endswith("|")):
        return None
    return trimmed[1:-1].strip()


def _closure_body_text(lines: list[str], index: int, window: str) -> str:
    if "{" in window:
        return _collect_block(lines, index)
    if "|" in window:
        return window.rsplit("|", 1)[1].strip()
    return ""


def _last_ok_expression(body_text: str) -> Optional[str]:
    last_expression = None
    offset = 0
    while True:
        found = body_text.find("Ok(", offset)
        if found < 0:
            break
        start = found + 2
        inner = _balanced_suffix(body_text[start:], "(", ")")
        if inner is None:
            break
        last_expression = inner.strip()
        offset = start + len(inner)
    return last_expression


def _function_name_from_line(line: str) -> Optional[str]:
    match = re.search(r"\bfn\s+([A-Za-z_][A-Za-z0-9_]*)", line)
    return match.group(1) if match else None


def _function_return_type(header: str) -> Optional[str]:
    closing = header.rfind(")")
    if closing < 0:
        return None
    after_parens = header[closing + 1 :].strip()
    if not after_parens.startswith("->"):
        return None
    return _extract_type_before_body(after_parens[2:].strip())


def _collect_doc_block_above(lines: list[str], index: int) -> str:
    collected = []
    cursor = index
    while cursor > 0:
        cursor -= 1
        trimmed = lines[cursor].strip()
        if trimmed.startswith("///"):
            collected.append(trimmed[3:].lstrip())
            continue
        if (
            not trimmed
            or trimmed.startswith("#[")
            or _is_simple_bridge_line(trimmed)
            or (trimmed.startswith("//") and not trimmed.startswith("///"))
        ):
            continue
        break
    collected.reverse()
    return "\n".join(collected).strip()


def _is_simple_bridge_line(line: str) -> bool:
    return line.startswith("let ") and line.endswith(";") and "{" not in line and "}" not in line


def _first_summary_line(doc_block: str) -> str:
    for line in doc_block.splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("@"):
            return stripped
    return ""


def _named_create_function(window: str) -> Optional[str]:
    marker = "lua.create_function("
    if marker not in window:
        return None
    after_call = window.split(marker, 1)[1].lstrip()
    if after_call.startswith("|") or after_call.startswith("move |"):
        return None
    return _leading_identifier(after_call)


def _self_named_function(window: str) -> Optional[str]:
    if "Self::" not in window:
        return None
    return _leading_identifier(window.split("Self::", 1)[1])


def _ok_string_literal(text: str) -> Optional[str]:
    if "Ok(" not in text:
        return None
    return _first_string_literal(text.split("Ok(", 1)[1])


def _first_string_literal(text: str) -> Optional[str]:
    in_string = False
    escape = False
    literal = []
    for character in text:
        if not in_string:
            if character == '"':
                in_string = True
                literal.clear()
            continue
        if escape:
            literal.append(character)
            escape = False
            continue
        if character == "\\":
            escape = True
            continue
        if character == '"':
            return "".join(literal)
        literal.append(character)
    return None


def _leading_identifier(text: str) -> Optional[str]:
    match = re.match(r"\s*([A-Za-z_][A-Za-z0-9_]*)", text)
    return match.group(1) if match else None


def _parenthesized_segment(text: str) -> Optional[str]:
    start = text.find("(")
    if start < 0:
        return None
    return _balanced_suffix(text[start:], "(", ")")


def _balanced_suffix(text: str, open_char: str, close_char: str) -> Optional[str]:
    depth = 0
    in_string = False
    in_char = False
    escape = False
    start = None
    for index, character in enumerate(text):
        if in_string:
            if escape:
                escape = False
                continue
            if character == "\\":
                escape = True
            elif character == '"':
                in_string = False
            continue
        if in_char:
            if escape:
                escape = False
                continue
            if character == "\\":
                escape = True
            elif character == "'":
                in_char = False
            continue
        if character == '"':
            in_string = True
        elif character == "'":
            in_char = True
        elif character == open_char:
            depth += 1
            if start is None:
                start = index + 1
        elif character == close_char:
            depth -= 1
            if depth == 0 and start is not None:
                return text[start:index]
    return None


def _extract_type_before_body(text: str) -> Optional[str]:
    result = []
    paren_depth = 0
    angle_depth = 0
    bracket_depth = 0
    in_string = False
    in_char = False
    escape = False
    for character in text:
        if in_string:
            result.append(character)
            if escape:
                escape = False
            elif character == "\\":
                escape = True
            elif character == '"':
                in_string = False
            continue
        if in_char:
            result.append(character)
            if escape:
                escape = False
            elif character == "\\":
                escape = True
            elif character == "'":
                in_char = False
            continue
        if character == '"':
            in_string = True
            result.append(character)
        elif character == "'":
            in_char = True
            result.append(character)
        elif character == "(":
            paren_depth += 1
            result.append(character)
        elif character == ")":
            paren_depth -= 1
            result.append(character)
        elif character == "<":
            angle_depth += 1
            result.append(character)
        elif character == ">":
            angle_depth -= 1
            result.append(character)
        elif character == "[":
            bracket_depth += 1
            result.append(character)
        elif character == "]":
            bracket_depth -= 1
            result.append(character)
        elif character == "{" and paren_depth == 0 and angle_depth == 0 and bracket_depth == 0:
            break
        else:
            result.append(character)
    trimmed = "".join(result).strip().rstrip(")").strip()
    return trimmed or None


def _strip_result_wrapper(raw_type: str) -> str:
    for wrapper_name in ("LuaResult", "Result", "mlua::Result"):
        inner = _wrapper_inner_type(raw_type, wrapper_name)
        if inner is not None:
            parts = _split_top_level(inner, ",")
            return parts[0] if parts else inner
    return raw_type


def _wrapper_inner_type(raw_type: str, wrapper_name: str) -> Optional[str]:
    trimmed = raw_type.strip()
    prefix = f"{wrapper_name}<"
    if not trimmed.startswith(prefix):
        return None
    return _balanced_suffix(trimmed[len(prefix) - 1 :], "<", ">")


def _strip_references(raw_type: str) -> str:
    trimmed = raw_type.strip()
    while trimmed.startswith("&"):
        trimmed = trimmed[1:].strip()
    if trimmed.startswith("mut "):
        trimmed = trimmed[4:].strip()
    return trimmed


def _normalize_parameter_name(pattern: str) -> str:
    trimmed = pattern.strip()
    if trimmed.startswith("mut "):
        trimmed = trimmed[4:].strip()
    return trimmed.lstrip("_").strip()


def _split_pattern_and_type(text: str) -> Optional[tuple[str, str]]:
    paren_depth = 0
    angle_depth = 0
    bracket_depth = 0
    for index, character in enumerate(text):
        if character == "(":
            paren_depth += 1
        elif character == ")":
            paren_depth -= 1
        elif character == "<":
            angle_depth += 1
        elif character == ">":
            angle_depth -= 1
        elif character == "[":
            bracket_depth += 1
        elif character == "]":
            bracket_depth -= 1
        elif character == ":" and paren_depth == 0 and angle_depth == 0 and bracket_depth == 0:
            return text[:index], text[index + 1 :]
    return None


def _split_top_level(text: str, delimiter: str) -> list[str]:
    parts = []
    current = []
    paren_depth = 0
    angle_depth = 0
    bracket_depth = 0
    brace_depth = 0
    in_string = False
    in_char = False
    escape = False
    for character in text:
        if in_string:
            current.append(character)
            if escape:
                escape = False
            elif character == "\\":
                escape = True
            elif character == '"':
                in_string = False
            continue
        if in_char:
            current.append(character)
            if escape:
                escape = False
            elif character == "\\":
                escape = True
            elif character == "'":
                in_char = False
            continue
        if character == '"':
            in_string = True
            current.append(character)
        elif character == "'":
            in_char = True
            current.append(character)
        elif character == "(":
            paren_depth += 1
            current.append(character)
        elif character == ")":
            paren_depth -= 1
            current.append(character)
        elif character == "<":
            angle_depth += 1
            current.append(character)
        elif character == ">":
            angle_depth -= 1
            current.append(character)
        elif character == "[":
            bracket_depth += 1
            current.append(character)
        elif character == "]":
            bracket_depth -= 1
            current.append(character)
        elif character == "{":
            brace_depth += 1
            current.append(character)
        elif character == "}":
            brace_depth -= 1
            current.append(character)
        elif character == delimiter and paren_depth == 0 and angle_depth == 0 and bracket_depth == 0 and brace_depth == 0:
            trimmed = "".join(current).strip()
            if trimmed:
                parts.append(trimmed)
            current = []
        else:
            current.append(character)
    trimmed = "".join(current).strip()
    if trimmed:
        parts.append(trimmed)
    return parts


def _is_parenthesized(text: str) -> bool:
    trimmed = text.strip()
    return trimmed.startswith("(") and trimmed.endswith(")")


def _inner_parenthesized(text: str) -> Optional[str]:
    trimmed = text.strip()
    if not (trimmed.startswith("(") and trimmed.endswith(")")):
        return None
    return trimmed[1:-1]


def _last_path_segment(text: str) -> str:
    return text.rsplit("::", 1)[-1]


def _is_lua_context_parameter(parameter: BindingParam) -> bool:
    return parameter.name == "lua" or parameter.name == "" or ("Lua" in parameter.raw_type and "&Lua" in parameter.raw_type)


def _is_receiver_parameter(parameter: BindingParam) -> bool:
    return parameter.name in {"this", "self", "ud"} or "Self" in parameter.raw_type or _is_userdata_receiver_parameter(parameter)


def _is_userdata_receiver_parameter(parameter: BindingParam) -> bool:
    return "LuaAnyUserData" in parameter.raw_type or "AnyUserData" in parameter.raw_type


def _numeric_literal_type(text: str) -> Optional[str]:
    try:
        int(text)
        return "integer"
    except ValueError:
        pass
    try:
        float(text)
        return "number"
    except ValueError:
        return None


def _looks_like_boolean_expression(text: str) -> bool:
    return any(token in text for token in ("==", "!=", ">=", "<=", "&&", "||", ".is_", ".has_")) or text.lstrip().startswith("!")


def _last_method_identifier(text: str) -> Optional[str]:
    candidate = text.rsplit(".", 1)[-1].rsplit(":", 1)[-1].rstrip("()").strip()
    return _leading_identifier(candidate)


def _looks_like_boolean_name(name: str) -> bool:
    return name in {"isActive", "isAlive", "isBlocked", "isComplete", "isFogEnabled", "isRunning", "has", "hasTag"} or name.startswith("is") or name.startswith("has")


def _looks_like_integer_name(name: str) -> bool:
    return name in {
        "len",
        "count",
        "width",
        "height",
        "grid_width",
        "grid_height",
        "grid_size",
        "display_width",
        "display_height",
        "active_count",
        "get_width",
        "get_height",
        "get_chunk_size",
    } or name.endswith(("Count", "Width", "Height", "Size", "Id", "Index"))


def _owner_display_name(owner_name: str, owner_display_names: dict[str, str]) -> str:
    if owner_name in owner_display_names:
        return owner_display_names[owner_name]
    if owner_name.startswith("Lua"):
        return f"L{owner_name[3:]}"
    if owner_name.startswith("L"):
        return owner_name
    return f"L{owner_name}"


def _parse_lua_userdata_impl_owner(line: str) -> Optional[str]:
    if "impl" not in line or "for" not in line or "UserData" not in line:
        return None
    after_for = line.split("for", 1)[1].strip()
    return _leading_identifier(after_for)


def _parse_luna_type_impl_owner(line: str) -> Optional[str]:
    if "impl" not in line or "LunaType" not in line or "for" not in line:
        return None
    after_for = line.split("for", 1)[1].strip()
    return _leading_identifier(after_for)


def _brace_delta(line: str) -> int:
    return line.count("{") - line.count("}")


def _report_summary(report: BindingValidationReport) -> str:
    return (
        f"missing={len(report.missing_doc_entries)} "
        f"phantom={len(report.phantom_doc_entries)} "
        f"param_count={len(report.parameter_count_mismatches)} "
        f"param_order={len(report.parameter_order_mismatches)} "
        f"param_name={len(report.parameter_name_mismatches)} "
        f"param_type={len(report.parameter_type_mismatches)} "
        f"param_optional={len(report.parameter_optionality_mismatches)} "
        f"return_count={len(report.return_count_mismatches)} "
        f"return_type={len(report.return_type_mismatches)} "
        f"return_optional={len(report.return_optionality_mismatches)}"
    )


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Generate code/docstring Lua binding snapshots from src/lua_api.")
    parser.add_argument("--source-dir", default=str(SRC_LUA_API_DIR), help="Directory with *_api.rs files.")
    parser.add_argument("--mode", choices=["code", "docstrings", "all"], default="all")
    parser.add_argument("--code-output", default=CODE_SNAPSHOT_RELATIVE)
    parser.add_argument("--doc-output", default=DOCSTRING_SNAPSHOT_RELATIVE)
    parser.add_argument("--report-output", default=VALIDATION_REPORT_RELATIVE)
    args = parser.parse_args(argv)

    source_dir = Path(args.source_dir)
    if args.mode == "code":
        snapshot = extract_binding_snapshot_from_code(source_dir)
        export_binding_snapshot(snapshot, args.code_output)
        print(f"[OK] wrote code snapshot: {args.code_output} ({snapshot.entry_count()} entries)")
        return 0
    if args.mode == "docstrings":
        snapshot = extract_binding_snapshot_from_docstrings(source_dir)
        export_binding_snapshot(snapshot, args.doc_output)
        print(f"[OK] wrote docstring snapshot: {args.doc_output} ({snapshot.entry_count()} entries)")
        return 0

    code_snapshot, doc_snapshot, report = generate_binding_reports(
        source_dir=source_dir,
        code_output=args.code_output,
        doc_output=args.doc_output,
        report_output=args.report_output,
    )
    print(f"[OK] wrote code snapshot: {args.code_output} ({code_snapshot.entry_count()} entries)")
    print(f"[OK] wrote docstring snapshot: {args.doc_output} ({doc_snapshot.entry_count()} entries)")
    print(f"[OK] wrote validation report: {args.report_output} ({_report_summary(report)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())