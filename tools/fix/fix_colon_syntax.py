#!/usr/bin/env python3
"""Fix UI widget method calls from dot/bracket syntax to colon syntax.

Converts:
  obj["method"](args)  →  obj:method(args)
  obj.method(args)     →  obj:method(args)

Only for local widget variables (not lurek.*, expect_*, etc.)
"""

import re
import sys
from pathlib import Path

# Known UI widget method names (from lurek.lua stub)
WIDGET_METHODS = {
    # LUiWidget base
    "setPosition", "getPosition", "setSize", "getSize", "setVisible", "isVisible",
    "setEnabled", "isEnabled", "addChild", "removeChild", "getChildren",
    "setId", "getId", "setStyle", "getStyle", "setBorderColor", "getBorderColor",
    "setBackgroundColor", "getBackgroundColor", "setForegroundColor", "getForegroundColor",
    "setOpacity", "getOpacity", "setTooltip", "getTooltip", "setZIndex", "getZIndex",
    "setFocusable", "isFocusable", "requestFocus", "hasFocus", "getParent",
    "getAbsolutePosition", "containsPoint", "setAnchor", "getAnchor",
    "setPadding", "getPadding", "setMargin", "getMargin", "setBorderWidth", "getBorderWidth",
    "setCornerRadius", "getCornerRadius", "setMinSize", "getMinSize", "setMaxSize", "getMaxSize",
    "setClipChildren", "getClipChildren",
    # LButton
    "setText", "getText", "setOnClick", "getOnClick", "setIcon", "getIcon",
    # LLabel
    "setFontSize", "getFontSize", "setAlignment", "getAlignment", "setColor", "getColor",
    "setWrap", "getWrap",
    # LTextInput
    "setPlaceholder", "getPlaceholder", "setMaxLength", "getMaxLength",
    "isFocused", "getCursorPosition", "setReadOnly", "isReadOnly",
    "setInputType", "getInputType", "clear",
    # LCheckbox
    "setChecked", "isChecked",
    # LSlider
    "setValue", "getValue", "setRange", "getRange", "setStep", "getStep",
    "getMin", "getMax", "setOrientation", "getOrientation",
    # LProgressBar
    "getProgress",
    # LComboBox
    "addItem", "removeItem", "clearItems", "getItemCount", "getItem",
    "setSelectedIndex", "getSelectedIndex", "getSelectedItem",
    # LListBox
    "setItemHeight", "getItemHeight", "setMultiSelect", "isMultiSelect",
    # LTabBar
    "addTab", "removeTab", "getTab", "getTabCount", "setActiveTab", "getActiveTab",
    # LSpinBox
    "increment", "decrement",
    # LSwitch
    "setOn", "isOn", "toggle",
    # LBadge
    "setCount", "getCount", "getDisplayText",
    # LPanel
    "setTitle", "getTitle", "setScrollable", "isScrollable",
    # LLayout
    "setDirection", "getDirection", "setSpacing", "getSpacing",
    # LScrollPanel
    "setContentSize", "getContentSize", "getScrollPosition", "setScrollPosition",
    "getViewSize", "setViewSize",
    # LScrollBar
    "setContentSize", "setViewSize",
    # LDialog
    "addButton", "setMessage", "getMessage",
    # LStatusBar
    "addSection", "removeSection", "setSectionText",
    # LAccordion
    "addSection", "toggleSection", "removeSection",
    # LTooltipPanel (newTooltipPanel)
    # LTable
    "addColumn", "addRow", "removeRow", "clearRows", "getRowCount",
    "setColumnWidth", "getColumnWidth", "setCellValue", "getCellValue",
    # LTreeView
    "addNode", "removeNode", "expandNode", "collapseNode",
    "getSelectedNode", "setSelectedNode",
    # LColorPicker
    "setColor", "getColor", "setAlpha", "getAlpha",
    # LImageWidget
    "setImage", "getImage", "setScaleMode", "getScaleMode",
    # LMenuBar
    "addMenu", "removeMenu",
    # LNinePatchTile
    "setTexture", "getTexture", "setBorders", "getBorders",
    # LWindow
    "setCloseable", "isCloseable", "setResizable", "isResizable",
    "setDraggable", "isDraggable",
    # LRadioGroup / LRadioButton
    "addOption", "setSelected", "getSelected",
}

# Identifiers to NEVER convert (module paths, test functions)
SKIP_IDENTIFIERS = {
    "lurek", "expect_equal", "expect_type", "expect_true", "expect_false",
    "expect_nil", "expect_not_nil", "expect_error", "expect_evidence_created",
    "describe", "it", "before_each", "after_each", "test_summary",
    "string", "table", "math", "os", "io", "type", "print", "pairs", "ipairs",
    "tostring", "tonumber", "assert", "error", "pcall", "xpcall", "require",
    "setmetatable", "getmetatable", "rawget", "rawset", "select", "unpack",
}

def fix_bracket_calls(line: str) -> str:
    """Convert obj["method"](args) to obj:method(args)."""
    # Pattern: identifier["methodName"]( — captures before and after
    pattern = r'(\b[a-z_]\w*)\["(\w+)"\]\('

    def replacer(m):
        ident = m.group(1)
        method = m.group(2)
        if ident in SKIP_IDENTIFIERS:
            return m.group(0)
        return f"{ident}:{method}("

    return re.sub(pattern, replacer, line)


def fix_dot_calls(line: str) -> str:
    """Convert obj.method(args) to obj:method(args) for widget method calls."""
    # Pattern: identifier.method( where not preceded by another dot
    # We use a negative lookbehind for dot to avoid matching lurek.ui.method
    pattern = r'(?<!\.)(\b[a-z_]\w*)\.(\w+)\('

    def replacer(m):
        ident = m.group(1)
        method = m.group(2)
        if ident in SKIP_IDENTIFIERS:
            return m.group(0)
        # Skip if method starts with underscore (internal field access)
        if method.startswith("_"):
            return m.group(0)
        # Skip common non-method patterns
        if method in ("new", "create", "format", "match", "find", "gsub",
                      "sub", "rep", "len", "byte", "char", "upper", "lower",
                      "reverse", "gmatch", "dump", "insert", "remove", "sort",
                      "concat", "pack", "unpack", "move",
                      "floor", "ceil", "abs", "sqrt", "sin", "cos", "tan",
                      "max", "min", "random", "randomseed",
                      "clock", "time", "date", "difftime",
                      "open", "close", "read", "write", "lines", "tmpfile"):
            # Only skip string/table/math/os/io methods on their modules
            if ident in ("string", "table", "math", "os", "io"):
                return m.group(0)
        return f"{ident}:{method}("

    return re.sub(pattern, replacer, line)


def fix_file(path: Path) -> int:
    """Fix a single file. Returns number of lines changed."""
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    changed = 0

    new_lines = []
    for line in lines:
        original = line
        line = fix_bracket_calls(line)
        line = fix_dot_calls(line)
        if line != original:
            changed += 1
        new_lines.append(line)

    if changed > 0:
        path.write_text("\n".join(new_lines), encoding="utf-8")

    return changed


def main():
    root = Path(__file__).resolve().parents[2]

    targets = [
        root / "tests/lua/unit/test_ui_core_unit.lua",
        root / "tests/lua/evidence/test_ui_evidence.lua",
        root / "tests/lua/unit/test_ui_input_unit.lua",
    ]

    total = 0
    for p in targets:
        if not p.exists():
            print(f"SKIP (not found): {p}")
            continue
        n = fix_file(p)
        print(f"Fixed {n} lines in {p.name}")
        total += n

    print(f"\nTotal: {total} lines fixed across {len(targets)} files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
