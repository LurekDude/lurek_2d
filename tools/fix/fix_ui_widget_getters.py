"""Fix remaining widget get/is instance method calls in ui.lua."""

with open("content/examples/ui.lua", "r", encoding="utf-8") as f:
    content = f.read()

WIDGET_METHODS = [
    "getState",
    "getChildCount",
    "getChildren",
    "getPadding",
    "getMargin",
    "getMinSize",
    "getMaxSize",
    "getFlexGrow",
    "getFlexShrink",
]

count = 0
for method in WIDGET_METHODS:
    old = f'  local v = lurek.ui.{method}()\n'
    new = f'  local _w = lurek.ui.newLabel("ui")\n  local v = _w.{method}()\n'
    if old in content:
        content = content.replace(old, new, 1)
        count += 1
        print(f"Fixed: {method}")
    else:
        print(f"NOT FOUND: {method}")

with open("content/examples/ui.lua", "w", encoding="utf-8") as f:
    f.write(content)
print(f"Total: {count}")
