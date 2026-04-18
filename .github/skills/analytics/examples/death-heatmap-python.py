# Parse death events and print ASCII heatmap
import re, pathlib
from collections import Counter

log = pathlib.Path("logs/game.log").read_text()
deaths = re.findall(r'event="player_died" x=(\d+) y=(\d+)', log)

# Bucket into 64px grid cells
grid = Counter()
for x, y in deaths:
    grid[(int(x)//64, int(y)//64)] += 1

# Print top death zones
for (cx, cy), count in grid.most_common(10):
    print(f"  cell ({cx*64}, {cy*64}): {count} deaths")
