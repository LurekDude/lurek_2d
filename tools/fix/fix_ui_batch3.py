"""Fix remaining issues in ui.lua — batch 3."""
from pathlib import Path

p = Path("content/examples/ui.lua")
text = p.read_text(encoding="utf-8")

# Fix newTheme({}) -> newTheme()
text = text.replace("lurek.ui.newTheme({})", "lurek.ui.newTheme()")

# Fix setNodeIcon("root", "folder") -> setNodeIcon(1, "folder")
text = text.replace('tree:setNodeIcon("root", "folder")', 'tree:setNodeIcon(1, "folder")')

# Fix lurek.ui.setTheme(lurek.ui.newTheme()) — setTheme expects LTheme userdata
# newTheme() returns LTheme, so this should work once stub is regenerated
# The error was about newTheme receiving 1 arg — already fixed above

p.write_text(text, encoding="utf-8")
print("Done. Batch 3 fixes applied.")
