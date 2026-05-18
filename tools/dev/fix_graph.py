"""Fix graph.lua addEdge and addNode issues."""
import re

with open('content/examples/graph.lua', encoding='utf-8') as f:
    text = f.read()

# Replace all g:addEdge(a, b, N.N) patterns (LGraph uses string edge_type, not number)
new_text = re.sub(r'g:addEdge\(a,\s*b,\s*[\d.]+\)', 'g:addEdge(a, b)', text)

# Fix addNode("metropolis", 42) -> addNode("metropolis")
new_text = new_text.replace('g:addNode("metropolis", 42)', 'g:addNode("metropolis")')

# Count changes
old_edge = len(re.findall(r'g:addEdge\(a,\s*b,\s*[\d.]+\)', text))
new_edge = len(re.findall(r'g:addEdge\(a,\s*b,\s*[\d.]+\)', new_text))
old_node = text.count('g:addNode("metropolis", 42)')
new_node = new_text.count('g:addNode("metropolis", 42)')
print(f'addEdge with numeric weight: {old_edge} -> {new_edge}')
print(f'addNode metropolis 42: {old_node} -> {new_node}')

with open('content/examples/graph.lua', 'w', encoding='utf-8') as f:
    f.write(new_text)
print('Done.')
