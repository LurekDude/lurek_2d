"""Fix remaining type mismatch errors in ui.lua."""
import re
from pathlib import Path

p = Path("content/examples/ui.lua")
text = p.read_text(encoding="utf-8")

# 1. Module-level funcs need proper args
text = text.replace("lurek.ui.mousepressed()", 'lurek.ui.mousepressed(100, 200, 1)')
text = text.replace("lurek.ui.mousereleased()", 'lurek.ui.mousereleased(100, 200, 1)')
text = text.replace("lurek.ui.mousemoved()", 'lurek.ui.mousemoved(100, 200)')
text = text.replace("lurek.ui.keypressed()", 'lurek.ui.keypressed("space")')
text = text.replace("lurek.ui.textinput()", 'lurek.ui.textinput("a")')
text = text.replace("lurek.ui.wheelmoved()", 'lurek.ui.wheelmoved(0, 1)')
text = text.replace("lurek.ui.update()", 'lurek.ui.update(0.016)')
text = text.replace("lurek.ui.drawToImage()", 'lurek.ui.drawToImage(nil, nil)')
text = text.replace("lurek.ui.parseWidgetState()", 'lurek.ui.parseWidgetState("{}")')
text = text.replace('lurek.ui.setViewport(1)', 'lurek.ui.setViewport(800, 600)')
text = text.replace("lurek.ui.update_bindings()", 'lurek.ui.update_bindings({})')
text = text.replace("lurek.ui.loadLayout()", 'lurek.ui.loadLayout("layout.toml")')
text = text.replace("lurek.ui.loadLayoutFile()", 'lurek.ui.loadLayoutFile("layout.toml")')
text = text.replace("lurek.ui.renderToImage()", 'lurek.ui.renderToImage(nil, 800, 600)')

# 2. setDefaultTheme takes 0 args but example passes "dark"
text = text.replace('lurek.ui.setDefaultTheme("dark")', 'lurek.ui.setDefaultTheme()')

# 3. setTheme expects LTheme userdata, not string
text = text.replace('lurek.ui.setTheme("dark")', 'lurek.ui.setTheme(lurek.ui.newTheme({}))')

# 4. setFocus expects table?, not integer
text = text.replace('lurek.ui.setFocus(1)', 'lurek.ui.setFocus(nil)')

# 5. addToast expects table
text = text.replace('lurek.ui.addToast(1)', 'lurek.ui.addToast({text="Hello"})')

# 6. addChild/removeChild expect LWidget, not integer
text = text.replace('_w:addChild(1)', '_w:addChild(lurek.ui.newButton("x"))')
text = text.replace('_w:removeChild(1)', '_w:removeChild(lurek.ui.newButton("x"))')

# 7. setOn expects boolean
text = text.replace('sw:setOn(function() print("event") end)', 'sw:setOn(true)')

# 8. setVertical expects boolean
text = text.replace('sep:setVertical(1)', 'sep:setVertical(true)')

# 9. setGroup expects string
text = text.replace('rb:setGroup(1)', 'rb:setGroup("group1")')

# 10. setShortcut expects string
text = text.replace('mi:setShortcut(1)', 'mi:setShortcut("Ctrl+S")')

# 11. addButton expects string
text = text.replace('dlg:addButton(1)', 'dlg:addButton("OK")')

# 12. drawToImage(nil) -> drawToImage with proper LImageData
# The stub says drawToImage(target: LImageData) — use a cast annotation
# Actually simplest: create a dummy image data
text = text.replace(':drawToImage(nil)', ':drawToImage(lurek.image.newImageData(64, 64))')

# 13. LBarChart:addCategory(label, vals_tbl) - needs 2 args
text = text.replace('bc:addCategory("Jan")', 'bc:addCategory("Jan", {100})')
text = text.replace('bc:addCategory("Feb")', 'bc:addCategory("Feb", {80})')
text = text.replace('bc:addCategory("Q1"); bc:addCategory("Q2")',
                    'bc:addCategory("Q1", {120}); bc:addCategory("Q2", {180})')

# 14. LTheme:setStyle(widget_type, state, style_table) - needs 3 args after self
text = re.sub(
    r'theme:setStyle\("([^"]+)",\s*(\{[^}]+\})\)',
    r'theme:setStyle("\1", "normal", \2)',
    text
)

# 15. Line 2928: w:setYMax on wrong object - check if it was fixed
# Already handled by Panel->AreaChart fix earlier

p.write_text(text, encoding="utf-8")
print("Done. Type mismatch fixes applied.")
