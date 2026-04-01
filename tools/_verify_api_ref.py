import pathlib, re

text = pathlib.Path('wiki/API-Reference.md').read_text(encoding='utf-8')

# Check 1: No more double-space padding before --
inside_block = False
padding_found = []
for i, line in enumerate(text.splitlines(), 1):
    stripped = line.strip()
    if stripped.startswith("```"):
        inside_block = not inside_block
    if inside_block and re.search(r'\S  +--', line):
        padding_found.append((i, line[:80]))

print(f'Lines with padding still remaining: {len(padding_found)}')
for ln, s in padding_found[:5]:
    print(f'  L{ln}: {repr(s)}')

# Check 2: Events sections are outside code blocks
graph_events = '**Events:** `itemArrived`' in text
dialog_events = '**Events:** `start`' in text
scene_transitions = '**Transitions:** `none`' in text
print(f'luna.graph events as markdown: {graph_events}')
print(f'luna.dialog events as markdown: {dialog_events}')
print(f'luna.scene transitions as markdown: {scene_transitions}')

# Check 3: Old comment style gone
old_graph = '-- Events: "itemArrived"' in text
old_dialog = 'event: "start"|"advance"' in text
old_transitions = '-- Transitions:' in text
print(f'Old graph events comment still present: {old_graph}')
print(f'Old dialog events comment still present: {old_dialog}')
print(f'Old transitions comment still present: {old_transitions}')

# Check 4: Missing descriptions added
print(f'luna.keyboard desc: {"Query and configure keyboard state." in text}')
print(f'luna.mouse desc: {"Query pointer position" in text}')
print(f'Fixtures desc: {"Attach collision shapes" in text}')
print(f'Joints desc: {"link two rigid bodies" in text}')
print(f'luna.log desc: {"Structured logging" in text}')
print(f'luna.localization desc: {"Multi-language string lookup" in text}')
