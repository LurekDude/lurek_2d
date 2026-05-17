"""Fix ui.lua example stubs that incorrectly call lurek.ui.METHOD() instead of widget.METHOD()."""
import re

with open("content/examples/ui.lua", "r", encoding="utf-8") as f:
    content = f.read()

# Widget instance methods that are incorrectly called as lurek.ui.METHOD()
# These are all create_function closures on the widget table (need dot syntax)
WIDGET_METHODS = [
    "setSize", "getSize", "getRect", "setVisible", "isVisible",
    "setEnabled", "isEnabled", "setId", "getId", "setTooltip",
    "addChild", "removeChild", "clearChildren",
    "setOnClick", "setOnHover", "setOnChange", "setOnDraw",
    "setPadding", "setMargin", "setZOrder", "getZOrder",
    "setMinSize", "setMaxSize",
    "setAnchor", "setAnchorCenter", "clearAnchor",
    "setFlexGrow", "setFlexShrink",
    "bind", "unbind",
    "setAlpha", "getAlpha",
    "fadeIn", "fadeOut", "slideIn", "slideOut",
    "attachToEntity", "detachFromEntity", "detach", "attach", "remove",
]

count = 0
for method in WIDGET_METHODS:
    # Pattern: find lines with exactly 2 leading spaces + 'lurek.ui.METHOD('
    # Replace with: same 2-space indent + widget creation + method call
    pattern = r"(\n  )lurek\.ui\." + re.escape(method) + r"\("
    replacement = r"\1local _w = lurek.ui.newLabel(\"ui\")\1_w." + method + r"("
    new_content, n = re.subn(pattern, replacement, content)
    if n > 0:
        content = new_content
        count += n
        print(f"Fixed {n} occurrence(s) of lurek.ui.{method}")

with open("content/examples/ui.lua", "w", encoding="utf-8") as f:
    f.write(content)
print(f"Total fixes: {count}")
