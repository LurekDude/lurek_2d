#!/usr/bin/env python3
"""
gen_lua_library_api.py — Generate API reference docs from Luna2D Lua library files.

Reads all library/*/init.lua files and produces a comprehensive Markdown API
reference at docs/API/lua_library_api_reference.md.

Usage: python tools/gen_lua_library_api.py [--output PATH] [--library-dir PATH]
       Default output: docs/API/lua_library_api_reference.md
       Default library-dir: library/
"""

import re
import os
import argparse
from pathlib import Path


# ---------------------------------------------------------------------------
# Type inference helpers
# ---------------------------------------------------------------------------

_NAME_TYPE_HINTS = {
    # names whose types are well-known regardless of position
    'name': 'string',
    'id': 'string|number',
    'description': 'string',
    'text': 'string',
    'label': 'string',
    'title': 'string',
    'tag': 'string',
    'key': 'string',
    'path': 'string',
    'source': 'string',
    'stat': 'string',
    'type': 'string',
    'type_name': 'string',
    'category': 'string',
    'color': 'table',
    'pos': 'table',
    'data': 'table',
    'def': 'table',
    'options': 'table',
    'tags': 'table',
    'nodes': 'table',
    'items': 'table',
    'stats': 'table',
    'hp': 'number',
    'mp': 'number',
    'atk': 'number',
    'def': 'number',
    'spd': 'number',
    'dmg': 'number',
    'damage': 'number',
    'amount': 'number',
    'count': 'number',
    'size': 'number',
    'weight': 'number',
    'capacity': 'number',
    'duration': 'number',
    'speed': 'number',
    'rate': 'number',
    'value': 'number',
    'base': 'number',
    'add': 'number',
    'mul': 'number',
    'x': 'number',
    'y': 'number',
    'w': 'number',
    'h': 'number',
    'r': 'number',
    'g': 'number',
    'b': 'number',
    'a': 'number',
    'index': 'number',
    'required': 'number',
    'max': 'number',
    'min': 'number',
    'dt': 'number',
    'enabled': 'boolean',
    'visible': 'boolean',
    'mandatory': 'boolean',
    'flag': 'boolean',
    'callback': 'function',
    'fn': 'function',
    'handler': 'function',
    'self': 'table',
}

_TYPE_SUFFIX_HINTS = {
    # suffix → type
    '_id': 'string',
    '_name': 'string',
    '_type': 'string',
    '_count': 'number',
    '_index': 'number',
    '_rate': 'number',
    '_factor': 'number',
    '_mul': 'number',
    '_add': 'number',
    '_max': 'number',
    '_min': 'number',
    '_hp': 'number',
    '_mp': 'number',
    '_cb': 'function',
    '_fn': 'function',
}


def infer_type(param_name: str) -> str:
    """Infer a parameter type from its name using heuristics."""
    clean = param_name.lstrip('_').lower()
    if clean in _NAME_TYPE_HINTS:
        return _NAME_TYPE_HINTS[clean]
    for suffix, t in _TYPE_SUFFIX_HINTS.items():
        if clean.endswith(suffix):
            return t
    # varargs
    if param_name == '...':
        return 'any...'
    return 'any'


# ---------------------------------------------------------------------------
# Description generation from function name
# ---------------------------------------------------------------------------

_VERB_PATTERNS = [
    (r'^new([A-Z].+)', lambda m: f"Creates and returns a new {_camel_to_words(m.group(1))} instance."),
    (r'^add([A-Z].+)', lambda m: f"Adds a {_camel_to_words(m.group(1))} to the collection."),
    (r'^remove([A-Z].+)', lambda m: f"Removes the specified {_camel_to_words(m.group(1))} from the collection."),
    (r'^get([A-Z].+)', lambda m: f"Returns the current {_camel_to_words(m.group(1))} value."),
    (r'^set([A-Z].+)', lambda m: f"Sets the {_camel_to_words(m.group(1))} to the given value."),
    (r'^has([A-Z].+)', lambda m: f"Returns true if the object has the specified {_camel_to_words(m.group(1))}."),
    (r'^is([A-Z].+)', lambda m: f"Returns true if the object is currently {_camel_to_words(m.group(1)).lower()}."),
    (r'^clear([A-Z].+)', lambda m: f"Clears all {_camel_to_words(m.group(1)).lower()} entries."),
    (r'^clear$', lambda m: "Clears all entries from the collection."),
    (r'^reset([A-Z].*)?', lambda m: "Resets the object to its initial state."),
    (r'^update$', lambda m: "Updates the object state for the current frame or tick."),
    (r'^start$', lambda m: "Starts or resumes execution of the sequence or process."),
    (r'^stop$', lambda m: "Stops execution and resets the active state."),
    (r'^tick([A-Z].*)?', lambda m: "Advances the simulation by one step or turn."),
    (r'^find([A-Z].+)', lambda m: f"Searches for and returns a matching {_camel_to_words(m.group(1)).lower()}."),
    (r'^define([A-Z].+)', lambda m: f"Registers a {_camel_to_words(m.group(1)).lower()} definition in the global registry."),
    (r'^register([A-Z].+)', lambda m: f"Registers a {_camel_to_words(m.group(1)).lower()} in the registry."),
    (r'^calculate([A-Z].+)', lambda m: f"Calculates and returns the {_camel_to_words(m.group(1)).lower()}."),
    (r'^compute([A-Z].+)', lambda m: f"Computes and returns the {_camel_to_words(m.group(1)).lower()}."),
    (r'^apply([A-Z].+)', lambda m: f"Applies a {_camel_to_words(m.group(1)).lower()} to the object."),
    (r'^load([A-Z].*)?', lambda m: "Loads and processes the provided data or script."),
    (r'^advance([A-Z].*)?', lambda m: "Advances progress or moves to the next step."),
    (r'^draw([A-Z].*)?', lambda m: "Draws or renders the object to the screen."),
    (r'^shuffle([A-Z].*)?', lambda m: "Shuffles the items in the collection randomly."),
    (r'^sort([A-Z].*)?', lambda m: "Sorts the collection according to the given comparator or default order."),
    (r'^count([A-Z].*)?', lambda m: "Returns the number of items currently in the collection."),
    (r'^size([A-Z].*)?', lambda m: "Returns the current size of the collection."),
    (r'^emit([A-Z].*)?', lambda m: "Emits an event to registered listeners."),
    (r'^on([A-Z].+)', lambda m: f"Registers a callback for the '{_camel_to_words(m.group(1)).lower()}' event."),
    (r'^build([A-Z].*)?', lambda m: "Builds and returns the constructed object."),
    (r'^copy([A-Z].*)?', lambda m: "Returns a shallow copy of the object."),
    (r'^clone([A-Z].*)?', lambda m: "Returns a deep copy of the object."),
    (r'^save([A-Z].*)?', lambda m: "Serializes the object state to a table for persistence."),
    (r'^resolve([A-Z].*)?', lambda m: "Resolves and returns the computed result."),
    (r'^process([A-Z].*)?', lambda m: "Processes the input and updates internal state accordingly."),
    (r'^simulate([A-Z].*)?', lambda m: "Simulates one step of the system and updates state."),
]


def _camel_to_words(s: str) -> str:
    """Convert CamelCase to spaced words: 'StatusEffect' → 'Status Effect'."""
    return re.sub(r'([A-Z])', r' \1', s).strip()


def generate_description(func_name: str, raw_comment: str) -> str:
    """Return a 2-sentence description given a function name and any raw comment."""
    if raw_comment and raw_comment.strip():
        # Clean up the comment
        lines = [l.strip() for l in raw_comment.strip().splitlines()]
        # Strip leading ---/-- markers
        lines = [re.sub(r'^-{2,3}\s*', '', l) for l in lines]
        # Remove @tparam/@treturn/@param/@return lines
        lines = [l for l in lines if not re.match(r'^@', l)]
        text = ' '.join(l for l in lines if l).strip()
        if text:
            # Ensure ends with period
            if not text.endswith('.'):
                text += '.'
            # If it's a single short sentence, append a generic second sentence
            if text.count('.') == 1 and len(text) < 120:
                text += ' Returns the result to the caller.'
            return text

    # Generate from function name
    for pattern, factory in _VERB_PATTERNS:
        m = re.match(pattern, func_name)
        if m:
            first = factory(m)
            if not first.endswith('.'):
                first += '.'
            return first + ' Returns the result to the caller.'

    # Fallback
    words = _camel_to_words(func_name).lower()
    return f"Performs the {words} operation on the object. Returns the result to the caller."


# ---------------------------------------------------------------------------
# Lua source parser
# ---------------------------------------------------------------------------

class LuaFunc:
    def __init__(self, name: str, params: list[str], comment: str,
                 kind: str = 'method', type_name: str = ''):
        self.name = name
        self.params = params          # list of param name strings
        self.comment = comment        # raw comment block
        self.kind = kind              # 'factory' | 'method' | 'free'
        self.type_name = type_name    # which type this method belongs to


class LuaEnum:
    def __init__(self, name: str, values: list[str], comment: str):
        self.name = name
        self.values = values
        self.comment = comment


class ModuleInfo:
    def __init__(self, module_name: str, source_path: str):
        self.module_name = module_name
        self.source_path = source_path
        self.description = ''
        self.types: dict[str, list[LuaFunc]] = {}   # type_name → [LuaFunc]
        self.free_funcs: list[LuaFunc] = []
        self.enums: list[LuaEnum] = []
        self.unparsed: list[str] = []


def _strip_non_ascii(s: str) -> str:
    """Remove non-ASCII characters (e.g. box-drawing chars) from a string."""
    return re.sub(r'[^\x00-\x7F]+', '', s).strip()


def _is_separator_line(raw: str) -> bool:
    """Return True for comment lines that are pure separators (no real text)."""
    # Remove the leading -- or --- marker
    stripped_marker = re.sub(r'^-{2,3}\s*', '', raw.strip())
    # After removing non-ASCII, if nothing meaningful remains it's a separator
    ascii_only = _strip_non_ascii(stripped_marker)
    if not ascii_only:
        return True
    # Lines of only dashes, equals, spaces
    if re.match(r'^[-=\s]+$', ascii_only):
        return True
    return False


def _extract_comment_before(lines: list[str], idx: int) -> str:
    """Walk back from idx collecting contiguous ---/-- comment lines.

    Stops at separator lines (pure dashes/box-drawing) so section headers
    above a separator are not accidentally attributed to the item below it.
    """
    collected = []
    i = idx - 1
    while i >= 0:
        stripped = lines[i].strip()
        if re.match(r'^-{2,3}', stripped):
            # Stop at separator lines — don't include or continue past them
            if _is_separator_line(stripped):
                break
            collected.insert(0, stripped)
            i -= 1
        elif stripped == '':
            # Allow one blank line gap between doc comment and the function
            if i > 0 and re.match(r'^-{2,3}', lines[i - 1].strip()):
                i -= 1
                continue
            break
        else:
            break
    return '\n'.join(collected)


def _parse_params_from_comment(comment: str) -> dict[str, tuple[str, str]]:
    """Return {param_name: (type, description)} from @param / @tparam lines."""
    result = {}
    for line in comment.splitlines():
        line = re.sub(r'^-{2,3}\s*', '', line.strip())
        # @tparam[opt=x] type name  description
        m = re.match(r'@tparam(?:\[opt[^\]]*\])?\s+(\S+)\s+(\w+)\s*(.*)', line)
        if m:
            result[m.group(2)] = (m.group(1), m.group(3).strip())
            continue
        # @param name type  description
        m = re.match(r'@param\s+(\w+)\s+(\S+)\s*(.*)', line)
        if m:
            result[m.group(1)] = (m.group(2), m.group(3).strip())
            continue
        # @param name description (no explicit type)
        m = re.match(r'@param\s+(\w+)\s+(.*)', line)
        if m:
            result[m.group(1)] = ('any', m.group(2).strip())
    return result


def _parse_return_from_comment(comment: str) -> tuple[str, str]:
    """Return (type, description) from @treturn / @return lines."""
    for line in comment.splitlines():
        line = re.sub(r'^-{2,3}\s*', '', line.strip())
        m = re.match(r'@treturn\s+(\S+)\s*(.*)', line)
        if m:
            return m.group(1), m.group(2).strip()
        m = re.match(r'@return\s+(\S+)\s*(.*)', line)
        if m:
            return m.group(1), m.group(2).strip()
    return '', ''


def _find_multiline_enum_body(lines: list[str], start: int) -> tuple[str, int]:
    """
    Starting at `start` (the line containing `M.Xxx = {`), read forward until
    the closing `}` and return (body_string, end_line_index).
    Handles both single-line and multi-line enum tables.
    """
    full = ' '.join(l.strip() for l in lines[start:start + 20])
    m = re.search(r'=\s*\{([^}]*)\}', full)
    if m:
        return m.group(1), start
    # Multi-line: scan forward for closing brace
    body_lines = []
    i = start
    depth = 0
    started = False
    while i < len(lines):
        l = lines[i]
        for ch in l:
            if ch == '{':
                started = True
                depth += 1
            elif ch == '}':
                depth -= 1
                if started and depth == 0:
                    return '\n'.join(body_lines), i
            elif started and depth > 0:
                pass  # inside body
        if started and depth > 0:
            body_lines.append(l)
        i += 1
    return '\n'.join(body_lines), i


def _parse_lua_file(path: Path, module_name: str) -> ModuleInfo:
    """Parse a single library init.lua and return a ModuleInfo."""
    info = ModuleInfo(module_name,
                        str(path.relative_to(path.parent.parent.parent)).replace(os.sep, '/'))
    with open(path, encoding='utf-8') as f:
        content = f.read()
    lines = content.splitlines()

    # Extract module-level description from top comment block
    top_desc_lines = []
    for line in lines:
        stripped = line.strip()
        if re.match(r'^---?\s*@module', stripped):
            continue
        if re.match(r'^---?\s*@(?:description|status)', stripped):
            m = re.match(r'^---?\s*@description\s+(.*)', stripped)
            if m:
                top_desc_lines.append(m.group(1))
            continue
        if re.match(r'^---?\s*', stripped) and stripped not in ('---', '--'):
            text = re.sub(r'^---?\s*', '', stripped)
            if text and not text.startswith('@'):
                top_desc_lines.append(text)
        elif stripped == '' or (not stripped.startswith('-')):
            break
    info.description = ' '.join(top_desc_lines[:3]).strip()

    # Determine which local tables are types (have __index set to themselves)
    # e.g.  local Foo = {}  +  Foo.__index = Foo
    type_names: set[str] = set()
    index_pattern = re.compile(r'^\s*(\w+)\.__index\s*=\s*\1')
    for line in lines:
        m = index_pattern.match(line)
        if m:
            type_names.add(m.group(1))

    # Build a map: local_var_name → public constructor name (from M.newXxx)
    type_public_names: dict[str, str] = {}

    # Also track closure-based types: factory functions that define
    # `local varname = {}` and then `function varname:method(...)` inside them.
    # We collect these as (factory_func_name, local_var_name) pairs.
    closure_type_map: dict[str, str] = {}  # local_var → factory_func_name

    # ── Pre-pass: find factory constructors and their setmetatable calls ───
    factory_re = re.compile(
        r'^\s*function\s+M\.(\w+)\s*\(([^)]*)\)'
        r'|^\s*M\.(\w+)\s*=\s*function\s*\(([^)]*)\)'
    )
    constructor_re = re.compile(r'setmetatable\s*\(\s*\{\s*\}\s*,\s*(\w+)\)')
    local_table_re = re.compile(r'^\s*local\s+(\w+)\s*=\s*\{\s*\}')
    return_re = re.compile(r'^\s*return\s+(\w+)\s*$')

    # Also scan for closure-based object pattern:
    # function M.newXxx(...)  ... local obj = {} ... function obj:method() ... return obj end
    current_factory: str | None = None
    current_factory_locals: set[str] = set()

    for i, line in enumerate(lines):
        # Entering a factory function
        fm = factory_re.match(line)
        if fm:
            current_factory = fm.group(1) or fm.group(3)
            current_factory_locals = set()
            # Look ahead for setmetatable
            for j in range(i, min(i + 20, len(lines))):
                cm = constructor_re.search(lines[j])
                if cm:
                    lv = cm.group(1)
                    if lv in type_names:
                        type_public_names[lv] = current_factory
                    break
            continue

        if current_factory:
            # Track local tables defined inside the factory
            lm = local_table_re.match(line)
            if lm:
                current_factory_locals.add(lm.group(1))
            # Track return of a local table → that var is a closure type
            rm = return_re.match(line)
            if rm and rm.group(1) in current_factory_locals:
                closure_type_map[rm.group(1)] = current_factory
            # Simple end-of-function detection (conservative: `^end$`)
            if re.match(r'^end\s*$', line):
                current_factory = None
                current_factory_locals = set()

    # ── Full parse ─────────────────────────────────────────────────────────
    # Patterns
    func_m_re = re.compile(r'^\s*function\s+M\.(\w+)\s*\(([^)]*)\)')
    func_m_assign_re = re.compile(r'^\s*M\.(\w+)\s*=\s*function\s*\(([^)]*)\)')
    func_type_colon_re = re.compile(r'^\s*function\s+(\w+):(\w+)\s*\(([^)]*)\)')
    func_type_dot_re = re.compile(r'^\s*function\s+(\w+)\.(\w+)\s*\(([^)]*)\)')
    func_type_assign_re = re.compile(r'^\s*(\w+)\.(\w+)\s*=\s*function\s*\(([^)]*)\)')
    # M.EnumName = { ... }  (single or multi-line)
    enum_start_re = re.compile(r'^\s*M\.([A-Z]\w*)\s*=\s*\{')

    seen_names: set[str] = set()
    skip_until: int = -1

    for i, line in enumerate(lines):
        if i <= skip_until:
            continue

        comment = _extract_comment_before(lines, i)

        # ── Enum tables (capital-initial name) ────────────────────────────
        m = enum_start_re.match(line)
        if m:
            enum_name = m.group(1)
            body, end_i = _find_multiline_enum_body(lines, i)
            skip_until = end_i
            values = [kv.split('=')[0].strip() for kv in re.split(r'[,\n]', body)
                      if '=' in kv]
            values = [v.strip() for v in values
                      if v.strip() and re.match(r'^[A-Za-z_]\w*$', v.strip())]
            if values:
                info.enums.append(LuaEnum(enum_name, values, comment))
            continue

        # ── Free module functions: function M.name(params) ─────────────────
        m = func_m_re.match(line)
        if m:
            fname, raw_params = m.group(1), m.group(2)
            params = [p.strip() for p in raw_params.split(',') if p.strip()]
            key = f'M.{fname}'
            if key not in seen_names:
                seen_names.add(key)
                fn = LuaFunc(fname, params, comment, kind='free')
                info.free_funcs.append(fn)
            continue

        # ── Free module functions: M.name = function(params) ──────────────
        m = func_m_assign_re.match(line)
        if m:
            fname, raw_params = m.group(1), m.group(2)
            params = [p.strip() for p in raw_params.split(',') if p.strip()]
            key = f'M.{fname}'
            if key not in seen_names:
                seen_names.add(key)
                fn = LuaFunc(fname, params, comment, kind='free')
                info.free_funcs.append(fn)
            continue

        # ── Type methods: function TypeName:method(params) ─────────────────
        m = func_type_colon_re.match(line)
        if m:
            type_var, mname, raw_params = m.group(1), m.group(2), m.group(3)
            # Metatable-based type
            if type_var in type_names:
                params = [p.strip() for p in raw_params.split(',') if p.strip()]
                type_display = type_public_names.get(type_var, type_var)
                key = f'{type_var}:{mname}'
                if key not in seen_names:
                    seen_names.add(key)
                    fn = LuaFunc(mname, params, comment, kind='method',
                                 type_name=type_display)
                    info.types.setdefault(type_display, []).append(fn)
            # Closure-based type (e.g. seq inside newSequencer)
            elif type_var in closure_type_map:
                params = [p.strip() for p in raw_params.split(',') if p.strip()]
                factory_name = closure_type_map[type_var]
                key = f'{type_var}:{mname}'
                if key not in seen_names:
                    seen_names.add(key)
                    fn = LuaFunc(mname, params, comment, kind='method',
                                 type_name=factory_name)
                    info.types.setdefault(factory_name, []).append(fn)
            continue

        # ── Type methods: function TypeName.method(params) ─────────────────
        m = func_type_dot_re.match(line)
        if m:
            type_var, mname, raw_params = m.group(1), m.group(2), m.group(3)
            if type_var in type_names:
                params = [p.strip() for p in raw_params.split(',') if p.strip()]
                type_display = type_public_names.get(type_var, type_var)
                key = f'{type_var}.{mname}'
                if key not in seen_names:
                    seen_names.add(key)
                    fn = LuaFunc(mname, params, comment, kind='method',
                                 type_name=type_display)
                    info.types.setdefault(type_display, []).append(fn)
            continue

        # ── Type methods: TypeName.method = function(params) ──────────────
        m = func_type_assign_re.match(line)
        if m:
            type_var, mname, raw_params = m.group(1), m.group(2), m.group(3)
            if type_var in type_names and mname != '__index':
                params = [p.strip() for p in raw_params.split(',') if p.strip()]
                type_display = type_public_names.get(type_var, type_var)
                key = f'{type_var}.{mname}'
                if key not in seen_names:
                    seen_names.add(key)
                    fn = LuaFunc(mname, params, comment, kind='method',
                                 type_name=type_display)
                    info.types.setdefault(type_display, []).append(fn)
            continue

    return info


# ---------------------------------------------------------------------------
# Markdown generation
# ---------------------------------------------------------------------------

def _build_signature(fn: LuaFunc, module_name: str) -> str:
    """Build a human-readable call signature string."""
    clean_params = [p for p in fn.params if p != 'self']
    joined = ', '.join(clean_params)
    if fn.kind == 'factory' or fn.kind == 'free':
        return f"{module_name}.{fn.name}({joined})"
    else:
        # method on a type — use colon syntax
        return f"obj:{fn.name}({joined})"


def _render_param_table(fn: LuaFunc) -> str:
    """Return a Markdown params table for a function."""
    annotated = _parse_params_from_comment(fn.comment)
    clean_params = [p for p in fn.params if p != 'self']
    if not clean_params:
        return ''
    rows = []
    for p in clean_params:
        if p in annotated:
            ptype, pdesc = annotated[p]
            if not pdesc:
                pdesc = f"The {p.replace('_', ' ')} value."
        else:
            ptype = infer_type(p)
            pdesc = f"The {p.replace('_', ' ')} value."
        rows.append(f"| `{p}` | `{ptype}` | {pdesc} |")
    if not rows:
        return ''
    header = "| Parameter | Type | Description |\n|-----------|------|-------------|"
    return header + '\n' + '\n'.join(rows)


def _render_func_section(fn: LuaFunc, module_name: str) -> str:
    """Render a full sub-section for a single function."""
    sig = _build_signature(fn, module_name)
    desc = generate_description(fn.name, fn.comment)
    ret_type, ret_desc = _parse_return_from_comment(fn.comment)
    if not ret_type:
        # Heuristic
        if fn.name.startswith('is') or fn.name.startswith('has'):
            ret_type = 'boolean'
        elif fn.name.startswith('get') or fn.name.startswith('new'):
            ret_type = 'any'
        elif fn.name.startswith('count') or fn.name.startswith('size'):
            ret_type = 'number'
        else:
            ret_type = 'nil'

    lines = [f"#### `{fn.name}` — `{sig}`", '', desc, '']
    param_table = _render_param_table(fn)
    if param_table:
        lines += ['**Parameters**', '', param_table, '']
    if ret_type and ret_type != 'nil':
        ret_line = f"**Returns**: `{ret_type}`"
        if ret_desc:
            ret_line += f" — {ret_desc}"
        lines += [ret_line, '']
    return '\n'.join(lines)


def _render_module(info: ModuleInfo) -> str:
    """Render the Markdown section for one library module."""
    parts = []
    parts.append(f"## `{info.module_name}`")
    parts.append('')
    parts.append(f"**Source**: `{info.source_path}`  ")
    parts.append(f'**Require**: `local {info.module_name} = require("library.{info.module_name}")`')
    parts.append('')
    if info.description:
        desc = info.description
        if not desc.endswith('.'):
            desc += '.'
        parts.append(desc)
        parts.append('')

    # ── Enums ──────────────────────────────────────────────────────────────
    if info.enums:
        parts.append('### Enums')
        parts.append('')
        parts.append('| Name | Values | Description |')
        parts.append('|------|--------|-------------|')
        for enum in info.enums:
            vals = ', '.join(f'`{v}`' for v in enum.values)
            raw_comment = re.sub(r'^-{2,3}\s*', '', enum.comment.strip().split('\n')[0]).strip()
            if raw_comment.startswith('@'):
                raw_comment = ''
            desc = raw_comment if raw_comment else f"Enumeration of {enum.name} constants."
            parts.append(f"| `M.{enum.name}` | {vals} | {desc} |")
        parts.append('')

    # ── Free module functions ──────────────────────────────────────────────
    if info.free_funcs:
        parts.append('### Module Functions')
        parts.append('')
        # Summary table
        parts.append('| Function | Signature | Description |')
        parts.append('|----------|-----------|-------------|')
        for fn in info.free_funcs:
            sig = _build_signature(fn, info.module_name)
            first_sentence = generate_description(fn.name, fn.comment).split('.')[0] + '.'
            parts.append(f"| `{fn.name}` | `{sig}` | {first_sentence} |")
        parts.append('')
        # Detailed entries
        for fn in info.free_funcs:
            parts.append(_render_func_section(fn, info.module_name))

    # ── Types ──────────────────────────────────────────────────────────────
    if info.types:
        parts.append('### Types')
        parts.append('')
        for type_key, methods in sorted(info.types.items()):
            # Find the local var for this type
            constructor_name = type_key  # falls back to local var if no factory found
            parts.append(f"#### `{constructor_name}`")
            parts.append('')
            parts.append(f"Object returned by the corresponding `new{constructor_name}(...)` constructor, or constructed inline.")
            parts.append('')
            if methods:
                parts.append('| Method | Signature | Description |')
                parts.append('|--------|-----------|-------------|')
                for fn in methods:
                    clean_params = [p for p in fn.params if p != 'self']
                    sig = f"obj:{fn.name}({', '.join(clean_params)})"
                    first_sentence = generate_description(fn.name, fn.comment).split('.')[0] + '.'
                    parts.append(f"| `{fn.name}` | `{sig}` | {first_sentence} |")
                parts.append('')
                for fn in methods:
                    parts.append(_render_func_section(fn, info.module_name))

    parts.append('---')
    parts.append('')
    return '\n'.join(parts)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Generate API reference docs from Luna2D Lua library files.'
    )
    parser.add_argument(
        '--output', default='docs/API/lua_library_api_reference.md',
        help='Output Markdown file path (default: docs/API/lua_library_api_reference.md)'
    )
    parser.add_argument(
        '--library-dir', default='library',
        help='Path to the library/ directory (default: library/)'
    )
    args = parser.parse_args()

    # Resolve paths relative to the script's grandparent (repo root)
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    library_dir = repo_root / args.library_dir
    output_path = repo_root / args.output

    if not library_dir.exists():
        print(f"ERROR: library dir not found: {library_dir}")
        return 1

    # Discover modules
    modules = sorted(
        d for d in library_dir.iterdir()
        if d.is_dir() and (d / 'init.lua').exists()
    )

    if not modules:
        print("ERROR: No library modules found (no init.lua files).")
        return 1

    print(f"Scanning {len(modules)} modules in {library_dir} ...")

    # Parse all modules
    all_info: list[ModuleInfo] = []
    for mod_path in modules:
        init_lua = mod_path / 'init.lua'
        info = _parse_lua_file(init_lua, mod_path.name)
        all_info.append(info)
        total = len(info.free_funcs) + sum(len(v) for v in info.types.values())
        enum_count = len(info.enums)
        print(f"  {mod_path.name:20s}  {total:3d} functions,  {enum_count:2d} enums")

    # Render output
    output_lines = [
        '# Luna2D Library API Reference',
        '',
        '> Auto-generated by `tools/gen_lua_library_api.py`. Do not edit manually.',
        '> Run `python tools/gen_lua_library_api.py` to regenerate.',
        '',
        '## Modules',
        '',
    ]

    for info in all_info:
        output_lines.append(f"- [`{info.module_name}`](#{info.module_name})")
    output_lines.append('')
    output_lines.append('---')
    output_lines.append('')

    for info in all_info:
        output_lines.append(_render_module(info))

    output_text = '\n'.join(output_lines)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(output_text)

    line_count = output_text.count('\n') + 1
    print(f"\nWrote {line_count} lines to {output_path}")

    # Report unparsed items if any
    for info in all_info:
        if info.unparsed:
            print(f"  WARNING: {info.module_name} — {len(info.unparsed)} items not parsed:")
            for item in info.unparsed[:5]:
                print(f"    {item}")

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
