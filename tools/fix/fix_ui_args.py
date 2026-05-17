"""
Fix all remaining argument errors in ui.lua:
- NinePatch: setInsets needs (left, top, right, bottom), setImageDimensions needs (w, h)
- Toast: setMessage needs a string
- Separator: setVertical needs a bool
- TreeView: all node methods that need index
- setSelectedNode(true) -> setSelectedNode(1)
"""

with open("content/examples/ui.lua", "r", encoding="utf-8") as f:
    content = f.read()

fixes = [
    # NinePatch
    ("  np.setInsets(8) -- 8px fixed border on all sides",
     "  np.setInsets(8, 8, 8, 8) -- 8px fixed border on all sides"),
    ('  np.setImageDimensions("assets/icon.png")',
     "  np.setImageDimensions(64, 64)"),
    # Toast
    ("  toast.setMessage(1)",
     '  toast.setMessage("Level Up!")'),
    # TreeView: methods that need index arg
    ("  tree.toggleNode()",
     "  tree.addNode(\"Root\"); tree.toggleNode(1)"),
    ("  local v = tree.isExpanded()",
     "  tree.addNode(\"Root\"); local v = tree.isExpanded(1)"),
    ("  local v = tree.getNodeText()",
     "  tree.addNode(\"Skill\"); local v = tree.getNodeText(1)"),
    ('  tree.setNodeText("Hello")',
     '  tree.addNode("Node"); tree.setNodeText(1, "Hello")'),
    ('  tree.setNodeIcon("assets/icon.png")',
     '  tree.addNode("Node"); tree.setNodeIcon(1, "assets/icon.png")'),
    ("  tree.expandNode()",
     "  tree.addNode(\"Node\"); tree.expandNode(1)"),
    ("  tree.collapseNode()",
     "  tree.addNode(\"Node\"); tree.collapseNode(1)"),
    ("  local v = tree.isNodeExpanded()",
     "  tree.addNode(\"Node\"); local v = tree.isNodeExpanded(1)"),
    ("  tree.setSelectedNode(true)",
     "  tree.addNode(\"Node\"); tree.setSelectedNode(1)"),
    ("  local v = tree.getChildNodes()",
     "  tree.addNode(\"Parent\"); tree.addNode(\"Child\"); local v = tree.getChildNodes(1)"),
    ("  local v = tree.getParentNode()",
     "  tree.addNode(\"Parent\"); tree.addNode(\"Child\"); local v = tree.getParentNode(2)"),
    ("  local v = tree.getNodeDepth()",
     "  tree.addNode(\"Node\"); local v = tree.getNodeDepth(1)"),
    # TreeView removeNode() was already fixed to removeNode(1), but it needs a node first:
]

count = 0
for old, new in fixes:
    if old in content:
        content = content.replace(old, new, 1)
        count += 1
        print(f"Fixed: {old[:60]!r}")
    else:
        print(f"NOT FOUND: {old[:60]!r}")

with open("content/examples/ui.lua", "w", encoding="utf-8") as f:
    f.write(content)
print(f"Total: {count}")
