"""Quick python script to insert missing lua API docs."""
import os
import re

base_dir = "src/lua_api"
items = [
    ("ai", "module", "lurek.set(\"ai\""),
    ("automation", "module", "lurek.set(\"automation\""),
    ("camera", "function", "tbl.set(\"newCamera\""),
    ("data", "function", "tbl.set(\"newByteData\""),
    ("globe", "function", "tbl.set(\"new\""),
    ("globe", "method", "methods.add_method(\"getName\""),
    ("globe", "method", "methods.add_method(\"getTimeOfDay\""),
    ("globe", "method", "methods.add_method(\"removeArc\""),
    ("globe", "method", "methods.add_method(\"removeLabel\""),
    ("globe", "method", "methods.add_method(\"removeLayer\""),
    ("globe", "method", "methods.add_method(\"removeMarker\""),
    ("globe", "method", "methods.add_method(\"setLabelText\""),
    ("globe", "method", "methods.add_method(\"setLabelVisible\""),
    ("globe", "method", "methods.add_method(\"setLayerVisible\""),
    ("globe", "method", "methods.add_method(\"setMarkerVisible\""),
    ("globe", "method", "methods.add_method_mut(\"remove\""), # for GlobeRegistry
    ("input", "module", "lurek.set(\"input\""),
    ("minimap", "module", "lurek.set(\"minimap\""),
    ("mods", "method", "methods.add_method(\"getName\""),
    ("mods", "module", "lurek.set(\"mods\""),
    ("particle", "module", "lurek.set(\"particle\""),
    ("pipeline", "module", "lurek.set(\"pipeline\""),
    ("raycaster", "module", "lurek.set(\"raycaster\""),
    ("render", "module", "lurek.set(\"graphic\""), # graphic instead of render maybe?
    ("save", "module", "lurek.set(\"save\""),
    ("scene", "module", "lurek.set(\"scene\""),
    ("serial", "module", "lurek.set(\"serial\""),
    ("thread", "module", "lurek.set(\"thread\""),
    ("tilemap", "module", "lurek.set(\"tilemap\""),
    ("timer", "module", "lurek.set(\"timer\""),
    ("window", "module", "lurek.set(\"window\""),
]

for mod, kind, target in items:
    filename = os.path.join(base_dir, f"{mod}_api.rs")
    if not os.path.exists(filename):
        print(f"Skipping {filename}")
        continue
    
    with open(filename, "r", encoding="utf-8") as f:
        content = f.read()
    
    # We want to add a doc comment right before the target if it doesn't have one
    # A bit crude, but we can do a regex replacement.
    
    escaped_target = re.escape(target)
    # Check if there's already a doc comment directly preceding it
    pattern = rf"(\s+)({escaped_target})"
    
    desc = f"API bindings for the {mod} {kind}."
    if kind == "module":
        desc = f"Namespace containing the {mod} API module."
    elif kind == "function":
        desc = f"Function to create or manipulate {mod}."
    elif kind == "method":
        desc = f"Method to perform an operation on the {mod} object."
    
    # Replace it by injecting `/// {desc}` 
    # but only if it's not already preceded by /// or we want to overwrite it?
    # Simple replace:
    def repl(m):
        spaces = m.group(1)
        tgt = m.group(2)
        # Avoid double inserting if there's already a good doc comment
        if "///" in spaces and len(spaces) > 20: # has a sizable previous comment
            # Still we may want to replace the short comment.
            pass
        return f"{spaces}/// {desc}{spaces}{tgt}"
    
    new_content, count = re.subn(pattern, repl, content)
    if count > 0:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Patched {mod} - {target}")

