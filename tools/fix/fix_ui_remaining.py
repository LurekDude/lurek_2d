"""
Comprehensive fix for all remaining ui.lua argument and constructor errors.
"""

with open("content/examples/ui.lua", "r", encoding="utf-8") as f:
    content = f.read()

fixes = []

# ─────────────────────────────────────────────────────────────
# 1. Gui_Window stubs: newPanel() → newWindow(), fix bool args
# ─────────────────────────────────────────────────────────────
gw_stubs = [
    "setTitle", "isCloseable", "setCloseable", "isDraggable",
    "setDraggable", "isResizable", "setResizable", "setOnClose"
]
for method in gw_stubs:
    old = f"--@api-stub: Gui_Window:{method}\n-- "
    # Replace each panel -> window by patching the do block
    pass

# Use precise whole-block replacements for each Gui_Window stub
fixes += [
    # setTitle
    ("do\n  local w = lurek.ui.newPanel()\n  w.setTitle(\"Hello\")\nend",
     "do\n  local w = lurek.ui.newWindow()\n  w.setTitle(\"Hello\")\nend"),
    # isCloseable
    ("do\n  local w = lurek.ui.newPanel()\n  local v = w.isCloseable()\n  print(\"isCloseable:\", v)\nend",
     "do\n  local w = lurek.ui.newWindow()\n  local v = w.isCloseable()\n  print(\"isCloseable:\", v)\nend"),
    # setCloseable
    ("do\n  local w = lurek.ui.newPanel()\n  w.setCloseable(1)\nend",
     "do\n  local w = lurek.ui.newWindow()\n  w.setCloseable(true)\nend"),
    # isDraggable
    ("do\n  local w = lurek.ui.newPanel()\n  local v = w.isDraggable()\n  print(\"isDraggable:\", v)\nend",
     "do\n  local w = lurek.ui.newWindow()\n  local v = w.isDraggable()\n  print(\"isDraggable:\", v)\nend"),
    # setDraggable
    ("do\n  local w = lurek.ui.newPanel()\n  w.setDraggable(1)\nend",
     "do\n  local w = lurek.ui.newWindow()\n  w.setDraggable(true)\nend"),
    # isResizable
    ("do\n  local w = lurek.ui.newPanel()\n  local v = w.isResizable()\n  print(\"isResizable:\", v)\nend",
     "do\n  local w = lurek.ui.newWindow()\n  local v = w.isResizable()\n  print(\"isResizable:\", v)\nend"),
    # setResizable
    ("do\n  local w = lurek.ui.newPanel()\n  w.setResizable(true)\nend",
     "do\n  local w = lurek.ui.newWindow()\n  w.setResizable(true)\nend"),
    # setOnClose
    ("do\n  local w = lurek.ui.newPanel()\n  w.setOnClose(function() print(\"event\") end)\nend",
     "do\n  local w = lurek.ui.newWindow()\n  w.setOnClose(function() print(\"event\") end)\nend"),
]

# ─────────────────────────────────────────────────────────────
# 2. SplitPanel: fix arg types
# ─────────────────────────────────────────────────────────────
fixes += [
    ("  split.setSplitPosition(100, 200)\n",
     "  split.setSplitPosition(0.5)\n"),
    ("  split.setMinPanelSize(200, 50)\n",
     "  split.setMinPanelSize(50)\n"),
    ("  split.setSecondChild(function() print(\"event\") end)\n",
     "  split.setSecondChild(1)\n"),
]

# ─────────────────────────────────────────────────────────────
# 3. DockPanel: fix arg types
# ─────────────────────────────────────────────────────────────
fixes += [
    ("  dock.dock()\n", '  dock.dock(1, "left")\n'),
    ("  dock.undock()\n", "  dock.undock(1)\n"),
    ("  dock.setSplitSize(200, 50)\n", '  dock.setSplitSize("left", 200)\n'),
    ("  local v = dock.getSplitSize()\n", '  local v = dock.getSplitSize("left")\n'),
]

# ─────────────────────────────────────────────────────────────
# 4. Toolbar: fix arg types (whole blocks for complex ones)
# ─────────────────────────────────────────────────────────────
fixes += [
    ("  tb.addButton(1)\n", '  tb.addButton("file")\n'),
    ("  tb.addSeparator(1)\n", "  tb.addSeparator()\n"),
    # getButton needs a button added first
    (
        "do\n  local tb = lurek.ui.newToolbar()\n  local v = tb.getButton()\n  print(\"getButton:\", v)\nend",
        'do\n  local tb = lurek.ui.newToolbar()\n  tb.addButton("file"); local v = tb.getButton("file")\n  print("getButton:", v)\nend'
    ),
    # setButtonEnabled needs id + bool
    (
        "do\n  local tb = lurek.ui.newToolbar()\n  tb.setButtonEnabled(true)\nend",
        'do\n  local tb = lurek.ui.newToolbar()\n  tb.addButton("file"); tb.setButtonEnabled("file", true)\nend'
    ),
    # setButtonToggled needs id + bool
    (
        "do\n  local tb = lurek.ui.newToolbar()\n  tb.setButtonToggled(function() print(\"event\") end)\nend",
        'do\n  local tb = lurek.ui.newToolbar()\n  tb.addButton("file"); tb.setButtonToggled("file", true)\nend'
    ),
    # isButtonToggled needs id
    (
        "do\n  local tb = lurek.ui.newToolbar()\n  local v = tb.isButtonToggled()\n  print(\"isButtonToggled:\", v)\nend",
        'do\n  local tb = lurek.ui.newToolbar()\n  tb.addButton("file"); local v = tb.isButtonToggled("file")\n  print("isButtonToggled:", v)\nend'
    ),
]

# ─────────────────────────────────────────────────────────────
# 5. MenuBar: fix arg types
# ─────────────────────────────────────────────────────────────
fixes += [
    # addMenu(child) → addMenu(child._idx)  (child is LuaTable with _idx field)
    ("  mb.addMenu(child)\n", "  mb.addMenu(child._idx)\n"),
    # removeMenu() → removeMenu(1) - no error even if idx not found
    ("  mb.removeMenu()\n", "  mb.removeMenu(1)\n"),
]

# ─────────────────────────────────────────────────────────────
# 6. StatusBar: fix arg types
# ─────────────────────────────────────────────────────────────
fixes += [
    ("  sb.addSection(1)\n", '  sb.addSection("Ready")\n'),
    # setSectionText needs (idx, text)
    (
        "do\n  local sb = lurek.ui.newStatusBar()\n  sb.setSectionText(\"Hello\")\nend",
        'do\n  local sb = lurek.ui.newStatusBar()\n  sb.addSection("Ready"); sb.setSectionText(1, "Hello")\nend'
    ),
    # getSectionText needs idx
    (
        "do\n  local sb = lurek.ui.newStatusBar()\n  local v = sb.getSectionText()\n  print(\"getSectionText:\", v)\nend",
        'do\n  local sb = lurek.ui.newStatusBar()\n  sb.addSection("Ready"); local v = sb.getSectionText(1)\n  print("getSectionText:", v)\nend'
    ),
    # setSectionWidget needs (idx, any)
    (
        "do\n  local sb = lurek.ui.newStatusBar()\n  sb.setSectionWidget(\"primary\")\nend",
        'do\n  local sb = lurek.ui.newStatusBar()\n  sb.addSection("Ready"); sb.setSectionWidget(1, nil)\nend'
    ),
]

# ─────────────────────────────────────────────────────────────
# 7. Accordion: fix arg types
# ─────────────────────────────────────────────────────────────
fixes += [
    ("  acc.addSection(1)\n", '  acc.addSection("Stats")\n'),
    ("  acc.setExclusive(1)\n", "  acc.setExclusive(true)\n"),
    # toggleSection needs idx
    (
        "do\n  local acc = lurek.ui.newAccordion()\n  acc.toggleSection()\nend",
        'do\n  local acc = lurek.ui.newAccordion()\n  acc.addSection("Stats"); acc.toggleSection(1)\nend'
    ),
    # isSectionExpanded needs idx
    (
        "do\n  local acc = lurek.ui.newAccordion()\n  local v = acc.isSectionExpanded()\n  print(\"isSectionExpanded:\", v)\nend",
        'do\n  local acc = lurek.ui.newAccordion()\n  acc.addSection("Stats"); local v = acc.isSectionExpanded(1)\n  print("isSectionExpanded:", v)\nend'
    ),
    # getSectionTitle needs idx
    (
        "do\n  local acc = lurek.ui.newAccordion()\n  local v = acc.getSectionTitle()\n  print(\"getSectionTitle:\", v)\nend",
        'do\n  local acc = lurek.ui.newAccordion()\n  acc.addSection("Stats"); local v = acc.getSectionTitle(1)\n  print("getSectionTitle:", v)\nend'
    ),
]

# ─────────────────────────────────────────────────────────────
# 8. TooltipPanel: fix constructor and colon syntax
# ─────────────────────────────────────────────────────────────
# Replace constructor: new_example_image_widget():newTooltipPanel(X) → lurek.ui.newTooltipPanel(X)
import re

def fix_tooltip_constructors(text):
    return re.sub(
        r'new_example_image_widget\(\):newTooltipPanel\(([^)]*)\)',
        r'lurek.ui.newTooltipPanel(\1)',
        text
    )

# Fix colon methods on tip: tip:METHOD → tip.METHOD
def fix_tip_colon(text):
    return re.sub(r'\btip:(\w+)\(', r'tip.\1(', text)

# ─────────────────────────────────────────────────────────────
# 9. ColorPicker: fix constructor and method args
# ─────────────────────────────────────────────────────────────
def fix_color_picker(text):
    # Constructor: new_example_image_widget():newColorPicker({...}) → lurek.ui.newColorPicker()
    text = re.sub(
        r'new_example_image_widget\(\):newColorPicker\([^)]*\)',
        r'lurek.ui.newColorPicker()',
        text
    )
    # Fix colon methods on cp
    text = re.sub(r'\bcp:(\w+)\(', r'cp.\1(', text)
    return text

# Fix cp.setColor({0.2, 0.6, 1.0, 1.0}) → cp.setColor(0.2, 0.6, 1.0, 1.0) — takes r,g,b,a
fixes += [
    ("  cp.setColor({0.2, 0.6, 1.0, 1.0})\n", "  cp.setColor(0.2, 0.6, 1.0, 1.0)\n"),
    ("  cp.setShowAlpha(0.85)\n", "  cp.setShowAlpha(true)\n"),
    ("  cp.setColorMode({0.2, 0.6, 1.0, 1.0})\n", '  cp.setColorMode("rgb")\n'),
]

# ─────────────────────────────────────────────────────────────
# 10. Gui_Table: fix constructor and method args
# ─────────────────────────────────────────────────────────────
def fix_gui_table(text):
    # Constructor
    text = re.sub(
        r'new_example_image_widget\(\):newTable\([^)]*\)',
        r'lurek.ui.newTable()',
        text
    )
    # Fix colon methods on tbl
    text = re.sub(r'\btbl:(\w+)\(', r'tbl.\1(', text)
    return text

# Fix addRow("item_1") → addRow({"item_1"}) — takes Vec<String>
fixes += [
    ('  tbl.addRow("item_1")\n', '  tbl.addRow({"item_1"})\n'),
    # getCell needs (row, col)
    (
        "do\n  local tbl = lurek.ui.newTable()\n  local v = tbl.getCell()\n  print(\"getCell:\", v)\nend",
        'do\n  local tbl = lurek.ui.newTable()\n  tbl.addColumn("Name"); tbl.addRow({"Alice"}); local v = tbl.getCell(1, 1)\n  print("getCell:", v)\nend'
    ),
    # setCell needs (row, col, text)
    (
        "do\n  local tbl = lurek.ui.newTable()\n  tbl.setCell(1)\nend",
        'do\n  local tbl = lurek.ui.newTable()\n  tbl.addColumn("Name"); tbl.addRow({"Alice"}); tbl.setCell(1, 1, "Bob")\nend'
    ),
    # setSelectedRow(true) → setSelectedRow(1)
    ("  tbl.setSelectedRow(true)\n", "  tbl.setSelectedRow(1)\n"),
    # setSortable(1) → setSortable(true)
    ("  tbl.setSortable(1)\n", "  tbl.setSortable(true)\n"),
]

# ─────────────────────────────────────────────────────────────
# 11. ImageWidget: fix constructor and method args
# ─────────────────────────────────────────────────────────────
def fix_image_widget(text):
    # Constructor for ImageWidget-only stubs (without :newXxx suffix)
    # These appear as: local img = new_example_image_widget()
    # with img:METHOD() calls
    # First replace constructors NOT followed by :new...
    text = re.sub(r'\bnew_example_image_widget\(\)', r'lurek.ui.newImageWidget()', text)
    # Fix colon methods on img
    text = re.sub(r'\bimg:(\w+)\(', r'img.\1(', text)
    return text

# After fixing img.setScaleMode to expect string not number
fixes += [
    ("  img.setScaleMode(1.5)\n", '  img.setScaleMode("fit")\n'),
    ("  img.setTint({0.2, 0.6, 1.0, 1.0})\n", "  img.setTint(0.2, 0.6, 1.0, 1.0)\n"),
]

# ImageWidget:newXxx stubs — these call newXxx() on an ImageWidget but that method
# doesn't exist; fix them to call lurek.ui.newXxx() directly
image_widget_factory_stubs = [
    ("  img.newButton()\n", "  lurek.ui.newButton(\"Btn\")\n"),
    ("  img.newLabel()\n", "  lurek.ui.newLabel(\"hello\")\n"),
    ("  img.newTextInput()\n", "  lurek.ui.newTextInput()\n"),
    ("  img.newCheckbox()\n", "  lurek.ui.newCheckbox(\"opt\")\n"),
    ("  img.newSlider()\n", "  lurek.ui.newSlider()\n"),
    ("  img.newProgressBar()\n", "  lurek.ui.newProgressBar()\n"),
    ("  img.newComboBox()\n", "  lurek.ui.newComboBox()\n"),
    ("  img.newList()\n", "  lurek.ui.newListBox()\n"),
    ("  img.newPanel()\n", "  lurek.ui.newPanel()\n"),
    ("  img.newLayout()\n", "  lurek.ui.newLayout(\"row\")\n"),
    ("  img.newScrollPanel()\n", "  lurek.ui.newScrollPanel()\n"),
    ("  img.newNinePatch()\n", "  lurek.ui.newNinePatch(\"assets/icon.png\")\n"),
    ("  img.newTabBar()\n", "  lurek.ui.newTabBar()\n"),
    ("  img.newSeparator()\n", "  lurek.ui.newSeparator()\n"),
    ("  img.newSpacer()\n", "  lurek.ui.newSpacer()\n"),
    ("  img.newToast()\n", "  lurek.ui.newToast()\n"),
    ("  img.newTreeView()\n", "  lurek.ui.newTreeView()\n"),
    ("  img.newRadioButton()\n", "  lurek.ui.newRadioButton(\"opt\")\n"),
    ("  img.newScrollBar()\n", "  lurek.ui.newScrollBar()\n"),
    ("  img.newWindow()\n", "  lurek.ui.newWindow()\n"),
]
fixes += image_widget_factory_stubs

# ─────────────────────────────────────────────────────────────
# Apply all regex-based fixes first
# ─────────────────────────────────────────────────────────────
content = fix_tooltip_constructors(content)
content = fix_tip_colon(content)
content = fix_color_picker(content)
content = fix_gui_table(content)
content = fix_image_widget(content)

# ─────────────────────────────────────────────────────────────
# Apply all string replacements
# ─────────────────────────────────────────────────────────────
count = 0
for old, new in fixes:
    if old in content:
        content = content.replace(old, new, 1)
        count += 1
        print(f"FIXED: {old[:70]!r}")
    else:
        print(f"MISS:  {old[:70]!r}")

with open("content/examples/ui.lua", "w", encoding="utf-8") as f:
    f.write(content)

print(f"\nTotal string fixes: {count}")
