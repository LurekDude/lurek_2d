"""
Transform ui_api.rs create_function closures to accept _self: LuaValue as
the first parameter, enabling colon-syntax calls from Lua.

Patterns handled:
  |_, ()| ...           → |_, _self: LuaValue| ...
  |_, name: String| ... → |_, (_self, name): (LuaValue, String)| ...
  |_, (x, y): (f32, f32)| ... → |_, (_self, x, y): (LuaValue, f32, f32)| ...
  etc.

Skips:
  - Closures that already have _self
  - Functions in register_ui (module-level lurek.ui.* functions, not object methods)
"""
import re
import sys
from pathlib import Path

def transform_closure_params(match_obj):
    """Transform a single create_function closure parameter list."""
    prefix = match_obj.group(1)  # everything up to |_,
    params = match_obj.group(2)  # the parameter part after |_,
    suffix = match_obj.group(3)  # the |

    # Already has _self
    if '_self' in params:
        return match_obj.group(0)

    params = params.strip()

    # Case: () — no params
    if params == '()':
        return f"{prefix}_self: LuaValue{suffix}"

    # Case: single typed param like "name: String" or "v: bool" or "id: String" etc.
    # Pattern: word: Type
    single_param = re.match(r'^(\w+)\s*:\s*(.+)$', params)
    if single_param:
        pname = single_param.group(1)
        ptype = single_param.group(2)
        return f"{prefix}(_self, {pname}): (LuaValue, {ptype}){suffix}"

    # Case: tuple params like "(x, y): (f32, f32)" or "(top, right, bottom, left): (...)"
    tuple_param = re.match(r'^\(([^)]+)\)\s*:\s*\(([^)]+)\)$', params)
    if tuple_param:
        names = tuple_param.group(1)
        types = tuple_param.group(2)
        return f"{prefix}(_self, {names}): (LuaValue, {types}){suffix}"

    # Case: complex multi-line tuple — handle separately
    # e.g. (left, top, right, bottom): (\n  Option<f32>, ...
    # Just return unchanged for manual fix
    return match_obj.group(0)


def process_file(filepath):
    content = Path(filepath).read_text(encoding='utf-8')

    # Find the create_widget_table function and all add_*_methods functions
    # These contain the widget method closures that need _self

    # Match: lua.create_function(move |_, <params>|
    # or:   lua.create_function(move |lua, <params>|
    # The pattern captures up to the closing |

    # Simple single-line params
    pattern = r'(lua\.create_function\(\s*(?:move\s*)?\|(?:_|lua),\s*)((?:\(\)|[^|]+?))\s*(\|)'

    # We need to be selective — only transform closures inside:
    # - create_widget_table function
    # - add_button_methods, add_label_methods, etc.
    # NOT transform closures in register_ui (module-level functions)

    # Find the boundary of register_ui function
    # We'll process in segments

    # Find where create_widget_table starts and where register_ui starts
    cwt_start = content.find('fn create_widget_table')
    register_start = content.find('pub fn register(lua: &Lua')

    if cwt_start == -1:
        print("ERROR: create_widget_table not found")
        return

    if register_start == -1:
        print("ERROR: register_ui not found")
        return

    # Process everything from create_widget_table up to register_ui
    # (this includes create_widget_table and all add_*_methods functions)
    before = content[:cwt_start]
    widget_section = content[cwt_start:register_start]
    after = content[register_start:]

    # Track changes
    count = 0

    def do_replace(m):
        nonlocal count
        result = transform_closure_params(m)
        if result != m.group(0):
            count += 1
        return result

    # Apply transformation to the widget methods section
    widget_section_new = re.sub(pattern, do_replace, widget_section)

    # Also need to handle multi-line tuple params that weren't caught
    # Pattern for multi-line: lua.create_function(\n  move |_, (params): (\n  types\n)|
    # These are harder. Let me handle the specific cases.

    # Fix multi-line tuples manually by looking for specific patterns
    # Pattern: move |_,\n  (names): (\n types\n)|
    ml_pattern = r'(lua\.create_function\(\s*\n\s*(?:move\s*)?\|(?:_|lua),\s*)((?:\(\)|[^|]+?))\s*(\|)'
    widget_section_new = re.sub(ml_pattern, do_replace, widget_section_new)

    new_content = before + widget_section_new + after

    Path(filepath).write_text(new_content, encoding='utf-8')
    print(f"Transformed {count} closures in widget methods section")


if __name__ == '__main__':
    filepath = sys.argv[1] if len(sys.argv) > 1 else 'src/lua_api/ui_api.rs'
    process_file(filepath)
