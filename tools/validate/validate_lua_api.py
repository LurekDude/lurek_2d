#!/usr/bin/env python3
"""validate_lua_api.py -- Validates a Lurek2D lua_api file against the SKILL.md contract.

Usage:
    python tools/validate_lua_api.py src/lua_api/timer_api.rs
    python tools/validate_lua_api.py src/lua_api/
    python tools/validate_lua_api.py src/lua_api/ --errors-only

The gold standard (timer_api.rs) must always score 0 errors / 0 warnings.

Exit codes:
    0  all checks pass (zero errors)
    1  one or more errors found
"""

import re
import sys
from pathlib import Path

# ─── per-file issue accumulators ──────────────────────────────────────────────

_errors: list[tuple[int, str]] = []
_warnings: list[tuple[int, str]] = []


def _err(line_no: int, msg: str) -> None:
    _errors.append((line_no, msg))


def _warn(line_no: int, msg: str) -> None:
    _warnings.append((line_no, msg))


# ─── individual checks ────────────────────────────────────────────────────────

def check_file_header(lines: list[str]) -> None:
    """First line must be //! `lurek.<module>` -- description."""
    for i, raw in enumerate(lines[:3]):
        line = raw.rstrip()
        if line.startswith("//!"):
            if not re.match(r'//! `lurek\.\w+`', line):
                _warn(i + 1,
                      'File header exists but does not match `//! `lurek.<module>` -- description`')
            return
    _err(1, "Missing file header: first line must be `//! `lurek.<module>` -- description`")


def check_register_signature(lines: list[str]) -> None:
    """pub fn register must exist with the canonical 3-argument signature."""
    for i, line in enumerate(lines):
        # Skip comment lines (//!, //, or ///): they may mention `pub fn register()
        # in prose and must not be treated as actual Rust function definitions.
        stripped = line.strip()
        if stripped.startswith("//"):
            continue
        if "pub fn register(" in line:
            # capture up to 5 continuation lines for multi-line signatures
            block = "\n".join(lines[i: i + 6])
            if "&Lua" not in block:
                _err(i + 1, "register() is missing `&Lua` as first parameter")
            if "&LuaTable" not in block:
                _err(i + 1, "register() is missing `&LuaTable` as second parameter")
            if "Rc<RefCell<SharedState>>" not in block:
                _warn(i + 1,
                      "register() is missing `Rc<RefCell<SharedState>>` -- "
                      "add it unless this module provably needs no state")
            # check for a /// docstring directly above
            preceding = [l.strip() for l in lines[max(0, i - 4): i]]
            if not any(l.startswith("///") for l in preceding):
                _warn(i + 1, "pub fn register() is missing a `///` docstring line")
            return
    _err(0, "No `pub fn register(` found -- file is not a valid lua_api module")


def check_module_registration(content: str) -> None:
    """lurek.set("module", var) must appear at the end of register().

    Handles:
    - ``luna.set("name", tbl)`` — standard form (Rust param is named ``luna``)
    - ``luna.set("name", tbl.clone())`` — clone variant
    - ``luna_table.set("name", ...)`` — alternate parameter name
    """
    # Match any identifier (possibly named luna_table, luna, etc.) calling .set("name", expr)
    # where expr is an identifier with an optional .clone() call.
    if not re.search(
        r'\bluna(?:_\w+)?\s*\.\s*set\s*\(\s*"[\w]+"\s*,\s*\w+(?:\.clone\(\))?\s*\)',
        content,
    ):
        _err(0, 'No `luna.set("module", tbl)?;` found -- module is not registered in the lurek global table')


def check_no_rustdoc_sections(lines: list[str]) -> None:
    """/// # Parameters and /// # Returns are completely forbidden in lua_api files."""
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped == "/// # Parameters":
            _err(i + 1,
                 "FORBIDDEN `/// # Parameters` in lua_api -- "
                 "use `/// @param name : type` instead")
        elif stripped == "/// # Returns":
            _err(i + 1,
                 "FORBIDDEN `/// # Returns` in lua_api -- "
                 "use `/// @return type` instead")


def check_no_embedded_lua(lines: list[str]) -> None:
    """lua.load(...) and lua.eval(...) embed Lua code -- forbidden.

    Comment lines (starting with //) are skipped so that explanatory
    comments mentioning lua.load() are not flagged as violations.

    A line bearing the marker ``// LUA-EVAL-JUSTIFIED:`` immediately before
    a lua.load() call suppresses the error for that one call.  Use this only
    for the eval/debug-introspection cases where embedding Lua IS the feature.
    """
    suppress_next = False
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("//"):
            if "LUA-EVAL-JUSTIFIED:" in stripped:
                suppress_next = True
            continue  # skip all comment lines
        if re.search(r'\blua\.load\s*\(', line):
            if suppress_next:
                suppress_next = False
            else:
                _err(i + 1,
                     "FORBIDDEN `lua.load(...)` -- do not embed Lua code strings; "
                     "move the logic to the domain module")
            continue
        if re.search(r'\blua\.eval\s*\(', line):
            if suppress_next:
                suppress_next = False
            else:
                _err(i + 1,
                     "FORBIDDEN `lua.eval(...)` -- do not embed Lua code strings")
            continue
        # Any non-comment, non-forbidden line resets the suppress flag
        suppress_next = False


def check_no_return_any(lines: list[str]) -> None:
    """`@return any` / `@return Any` is too vague."""
    for i, line in enumerate(lines):
        if re.search(r'///\s+@return\s+[Aa]ny\b', line):
            _err(i + 1,
                 '`@return any` is too vague -- replace with a specific Lua type '
                 '(e.g., Agent, integer, boolean, table, nil)')


def check_no_block_pattern(lines: list[str]) -> None:
    """{ let s = state.clone(); tbl.set(...); } is the block-wrapped anti-pattern."""
    for i, line in enumerate(lines):
        if re.search(r'^\s*\{\s*let\s+\w+\s*=\s*\w+\.clone\s*\(\s*\)', line):
            _err(i + 1,
                 "FORBIDDEN block-wrapped pattern `{ let x = foo.clone(); tbl.set(...); }` -- "
                 "use the flat pattern (let s = state.clone(); tbl.set(...))")


def _get_doc_block(lines: list[str], pos: int) -> list[str]:
    """Collect consecutive `///` lines immediately above `lines[pos]` (backwards scan).

    Stops at the first line that is NOT a `///` line.  Does NOT cross blank lines
    or section-header comments, so we never pick up a previous method's doc block.
    """
    doc: list[str] = []
    for i in range(pos - 1, max(-1, pos - 25), -1):
        stripped = lines[i].strip()
        if stripped.startswith("///"):
            doc.insert(0, stripped)
        else:
            break
    return doc


def _is_api_registration(lines: list[str], idx: int) -> bool:
    """Return True if the .set() call at `idx` is an API function registration.

    API registrations contain `create_function` within a few lines of the .set()
    call.  Table-building calls like `t.set("id", value)` do not.
    """
    block = "\n".join(lines[idx: min(len(lines), idx + 4)])
    return "create_function" in block


def check_docstring_coverage(lines: list[str]) -> None:
    """Every *.set / methods.add_method* must have @return in the docstring above it."""
    api_call_re = re.compile(
        r'\b(\w+\.set|methods\.add_method(?:_mut)?)\s*\(\s*"(\w+)"'
    )
    for i, line in enumerate(lines):
        m = api_call_re.search(line)
        if not m:
            continue
        kind, name = m.group(1), m.group(2)

        # Skip module registration calls (lurek.set) and table-building .set()
        if kind == "lurek.set":
            continue
        # Skip Lua metamethod keys (__index, __newindex, __call, etc.) --
        # these are always metatable internals, never API endpoint registrations.
        if name.startswith("__"):
            continue
        if ".set" in kind and not _is_api_registration(lines, i):
            continue

        # Only the consecutive /// block immediately above this line
        doc_lines = _get_doc_block(lines, i)

        # @return must be present
        has_return = any("@return" in l for l in doc_lines)
        if not has_return:
            _err(i + 1,
                 f'`{name}` ({kind}): missing `/// @return type` docstring above this entry')

        # @param must come before @return if both exist (within same doc block)
        if doc_lines:
            return_pos = next(
                (j for j, l in enumerate(doc_lines) if "@return" in l), None)
            last_param_pos = None
            for j, l in enumerate(doc_lines):
                if "@param" in l:
                    last_param_pos = j
            if return_pos is not None and last_param_pos is not None:
                if last_param_pos > return_pos:
                    _err(i + 1,
                         f'`{name}`: `@param` line appears AFTER `@return` -- '
                         '`@param` lines must always come first')


def check_section_headers(lines: list[str]) -> None:
    """Every *.set / methods.add_method should have a // ── name section header."""
    api_call_re = re.compile(
        r'\b(\w+\.set|methods\.add_method(?:_mut)?)\s*\(\s*"(\w+)"'
    )
    # U+2500 ─ or plain - both accepted
    header_re_tmpl = r'//\s*[─\-]+\s+{name}\b'

    for i, line in enumerate(lines):
        m = api_call_re.search(line)
        if not m:
            continue
        kind = m.group(1)
        name = m.group(2)

        # Skip module registration calls (lurek.set) and table-building .set()
        if kind == "lurek.set":
            continue
        # Skip Lua metamethod keys (__index, __newindex, __call, etc.)
        if name.startswith("__"):
            continue
        if ".set" in kind and not _is_api_registration(lines, i):
            continue

        preceding_text = "\n".join(lines[max(0, i - 16): i])
        header_re = header_re_tmpl.format(name=re.escape(name))
        if not re.search(header_re, preceding_text, re.IGNORECASE):
            _warn(i + 1,
                  f'`{name}`: missing section header '
                  f'`// ── {name} ──...` before this entry')


def check_orphan_doc_in_closures(lines: list[str]) -> None:
    """/// comments at deep indentation (>=12 spaces) are likely inside a closure body."""
    for i, line in enumerate(lines):
        m = re.match(r'^( {12,})///', line)
        if not m:
            continue
        stripped = line.strip()
        # Legitimate: section headers at this depth use // not ///
        # Legitimate: @param / @return lines in add_methods are at 8 spaces (already excluded)
        # What remains: orphaned /// inside a closure body
        if stripped.startswith("/// @") or stripped.startswith("// ──"):
            continue
        # Skip lines that are just /// (blank doc line) -- common in pub fn docs inside impl blocks
        if stripped == "///":
            continue
        _warn(i + 1,
              f"Deep `///` at indent {len(m.group(1))} -- this doc comment is likely "
              "inside a closure body; docstrings belong ABOVE the closure call, not inside it")


# ─── file-level runner ────────────────────────────────────────────────────────

def check_file(path: Path) -> tuple[int, int]:
    """Run all checks on one file. Returns (error_count, warning_count)."""
    global _errors, _warnings
    _errors = []
    _warnings = []

    try:
        content = path.read_text(encoding="utf-8")
    except Exception as exc:
        _err(0, f"Cannot read file: {exc}")
        return 1, 0

    lines = content.splitlines()

    check_file_header(lines)
    check_register_signature(lines)
    check_module_registration(content)
    check_no_rustdoc_sections(lines)
    check_no_embedded_lua(lines)
    check_no_return_any(lines)
    check_no_block_pattern(lines)
    check_docstring_coverage(lines)
    check_section_headers(lines)
    check_orphan_doc_in_closures(lines)

    return len(_errors), len(_warnings)


# ─── reporting ────────────────────────────────────────────────────────────────

def report(path: Path, ec: int, wc: int, errors_only: bool) -> None:
    status = "PASS" if ec == 0 else "FAIL"
    print(f"[{status}]  {path}  ({ec} error(s), {wc} warning(s))")
    for ln, msg in _errors:
        print(f"    [ERROR] L{ln}: {msg}")
    if not errors_only:
        for ln, msg in _warnings:
            print(f"    [WARN]  L{ln}: {msg}")
    if ec > 0 or (not errors_only and wc > 0):
        print()


# ─── entry point ──────────────────────────────────────────────────────────────

def main() -> None:
    errors_only = "--errors-only" in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith("--")]

    if not args:
        print(__doc__)
        sys.exit(1)

    target = Path(args[0])
    all_pass = True
    file_count = 0

    if target.is_dir():
        files = sorted(target.glob("*_api.rs"))
        if not files:
            print(f"No *_api.rs files found in {target}")
            sys.exit(1)
        for f in files:
            ec, wc = check_file(f)
            report(f, ec, wc, errors_only)
            file_count += 1
            if ec > 0:
                all_pass = False
    elif target.is_file():
        ec, wc = check_file(target)
        report(target, ec, wc, errors_only)
        file_count = 1
        if ec > 0:
            all_pass = False
    else:
        print(f"Error: `{target}` does not exist")
        sys.exit(1)

    if all_pass:
        print(f"[PASS] All {file_count} file(s) passed validation.")
        sys.exit(0)
    else:
        print(f"[FAIL] Validation FAILED -- fix all [ERROR] items before proceeding.")
        sys.exit(1)


if __name__ == "__main__":
    main()
