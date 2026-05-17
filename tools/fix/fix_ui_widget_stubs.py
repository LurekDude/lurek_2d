"""
Fix all widget stub calls in ui.lua:
1. Replace new_example_image_widget():newXxx(args) with lurek.ui.newXxx(correct_args)
2. Replace widget_var:method(args) with widget_var.method(args)
"""
import re

with open("content/examples/ui.lua", "r", encoding="utf-8") as f:
    content = f.read()

# ---- Step 1: Replace constructor calls ----
# Each entry: (old_pattern, new_replacement)
# Using exact string replacement for specific constructor calls
constructor_fixes = [
    ('new_example_image_widget():newButton("btn_play", "Play")', 'lurek.ui.newButton("Play")'),
    ('new_example_image_widget():newLabel("lbl_score", "Score: 0")', 'lurek.ui.newLabel("Score: 0")'),
    ('new_example_image_widget():newTextInput("ti_name", "")', 'lurek.ui.newTextInput()'),
    ('new_example_image_widget():newCheckbox("cb_sound", "Sound", true)', 'lurek.ui.newCheckbox("Sound")'),
    ('new_example_image_widget():newSlider(0, 100, 50)', 'lurek.ui.newSlider(0, 100)'),
    ('new_example_image_widget():newProgressBar(0.5)', 'lurek.ui.newProgressBar()'),
    ('new_example_image_widget():newComboBox({"Easy","Normal","Hard"})', 'lurek.ui.newComboBox()'),
    ('new_example_image_widget():newList()', 'lurek.ui.newList()'),
    ('new_example_image_widget():newTabBar({"Equip","Stats","Map"})', 'lurek.ui.newTabBar()'),
    ('new_example_image_widget():newSpinBox()', 'lurek.ui.newSpinBox()'),
    ('new_example_image_widget():newSwitch(false)', 'lurek.ui.newSwitch()'),
    ('new_example_image_widget():newBadge("3")', 'lurek.ui.newBadge("3")'),
    ('new_example_image_widget():newPanel()', 'lurek.ui.newPanel()'),
    ('new_example_image_widget():newLayout("vertical")', 'lurek.ui.newLayout("vertical")'),
    ('new_example_image_widget():newScrollPanel()', 'lurek.ui.newScrollPanel()'),
    ('new_example_image_widget():newNinePatch("assets/panel.9.png")', 'lurek.ui.newNinePatch()'),
    ('new_example_image_widget():newToast("Saved.", 2.0)', 'lurek.ui.newToast("Saved.", 2.0)'),
    ('new_example_image_widget():newSeparator("horizontal")', 'lurek.ui.newSeparator(false)'),
    ('new_example_image_widget():newTreeView({label="root"})', 'lurek.ui.newTreeView()'),
    ('new_example_image_widget():newRadioButton("rb_easy","Easy","diff")', 'lurek.ui.newRadioButton("Easy", "diff")'),
    ('new_example_image_widget():newScrollBar("vertical", 0, 100)', 'lurek.ui.newScrollBar(true)'),
    ('new_example_image_widget():newSplitPanel("horizontal", 0.5)', 'lurek.ui.newSplitPanel("horizontal")'),
    ('new_example_image_widget():newDockPanel()', 'lurek.ui.newDockPanel()'),
    ('new_example_image_widget():newToolbar()', 'lurek.ui.newToolbar()'),
    ('new_example_image_widget():newMenuBar()', 'lurek.ui.newMenuBar()'),
    ('new_example_image_widget():newMenuItem("New Game")', 'lurek.ui.newMenuItem("New Game")'),
    ('new_example_image_widget():newDialog("dlg_quit", "Quit?")', 'lurek.ui.newDialog("Quit?")'),
    ('new_example_image_widget():newStatusBar()', 'lurek.ui.newStatusBar()'),
    ('new_example_image_widget():newAccordion()', 'lurek.ui.newAccordion()'),
    # Some stubs also create child widgets:
    ('new_example_image_widget():newButton("child_1", "Journal")', 'lurek.ui.newButton("Journal")'),
    ('new_example_image_widget():newButton("child_1", "Child")', 'lurek.ui.newButton("Child")'),
]

count_c = 0
for old, new in constructor_fixes:
    n = content.count(old)
    if n > 0:
        content = content.replace(old, new)
        count_c += n
        print(f"  constructor [{n}x]: {old[:50]!r}")
    # else:
    #     print(f"  NOT FOUND: {old[:50]!r}")

print(f"Constructor fixes: {count_c}")

# ---- Step 2: Replace colon method calls on specific widget vars ----
# Widget vars in use: btn, lbl, ti, cb, sl, pb, w, tabs, spin, sw, badge,
#                     panel, layout, sp, np, toast, sep, tree, rb, sb,
#                     split, dock, tb, mb, mi, dlg, statusbar, acc, child
# ALL method calls on these widget tables must use dot syntax (not colon).
# Pattern: "  <varname>:<method>(" → "  <varname>.<method>("
# We target only inside do...end blocks (2-space indent lines).

widget_vars = r'(?:btn|lbl|ti|cb|sl|pb|w|tabs|spin|sw|badge|panel|layout|sp|np|toast|sep|tree|rb|sb|split|dock|tb|mb|mi|dlg|acc|child)'
# Replace "<varname>:method(" with "<varname>.method(" (but not "::" or other patterns)
pattern = re.compile(r'\b(' + widget_vars + r'):([a-zA-Z][a-zA-Z0-9]*)\(')
new_content, count_m = re.subn(pattern, r'\1.\2(', content)
content = new_content
print(f"Method colon→dot fixes: {count_m}")

with open("content/examples/ui.lua", "w", encoding="utf-8") as f:
    f.write(content)
print("Done!")
