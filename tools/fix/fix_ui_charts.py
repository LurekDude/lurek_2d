"""Fix chart examples in ui.lua."""
import re
from pathlib import Path

p = Path("content/examples/ui.lua")
text = p.read_text(encoding="utf-8")

# 1. Fix: lurek.ui.newImageWidget():newXxx(...) -> lurek.ui.newXxx(...)
text = re.sub(r'lurek\.ui\.newImageWidget\(\):new(\w+)\(', r'lurek.ui.new\1(', text)

# 2. Fix: :drawToImage() -> :drawToImage(nil)
text = re.sub(r':drawToImage\(\)', ':drawToImage(nil)', text)

# 3. Fix: :setXRange(N) -> :setXRange(N, 10)
text = re.sub(r':setXRange\((\d+)\)', r':setXRange(\1, 10)', text)

# 4. Fix: :setYRange(N) -> :setYRange(N, 10)
text = re.sub(r':setYRange\((\d+)\)', r':setYRange(\1, 10)', text)

# 5. Fix newChart(width, height) -> newChart({})
text = re.sub(
    r'lurek\.ui\.new(LineChart|BarChart|ScatterPlot|PieChart|AreaChart)\((\d+),\s*\d+\)',
    r'lurek.ui.new\1({})', text
)

# 6. Fix child._idx -> 1
text = text.replace("mb:addMenu(child._idx)", "mb:addMenu(1)")

# 7. Fix Panel-as-chart: newPanel() followed by chart methods
# Replace "local w = lurek.ui.newPanel()\n    w:setYMax" with area chart
text = text.replace(
    "local w = lurek.ui.newPanel()\n    w:setYMax(100)",
    "local w = lurek.ui.newAreaChart({})\n  w:setYMax(100)"
)
# Replace "local w = lurek.ui.newPanel()\n    w:drawToImage(nil)"
text = text.replace(
    "local w = lurek.ui.newPanel()\n    w:drawToImage(nil)",
    "local w = lurek.ui.newBarChart({})\n  w:drawToImage(nil)"
)
# Also the BarChart:drawToImage standalone section
text = text.replace(
    "local w = lurek.ui.newPanel()\n  w:drawToImage(nil)",
    "local w = lurek.ui.newBarChart({})\n  w:drawToImage(nil)"
)

# 8. Fix addSeries/addLayer/addSegment arg order
# LLineChart:addSeries(name, pts_tbl, r, g, b)
text = text.replace(
    'lc:addSeries("revenue", {0.2, 0.8, 0.4, 1}, {10, 20, 15, 35, 30})',
    'lc:addSeries("revenue", {10, 20, 15, 35, 30}, 0.2, 0.8, 0.4)')
text = text.replace(
    'lc:addSeries("cost",    {0.9, 0.3, 0.2, 1}, {8,  12, 10, 18, 20})',
    'lc:addSeries("cost", {8, 12, 10, 18, 20}, 0.9, 0.3, 0.2)')

# LScatterPlot:addSeries(name, pts_tbl, r, g, b)
text = text.replace(
    'sp:addSeries("players", {0.2, 0.7, 1, 1}, {10,20, 30,40, 50,35, 70,55})',
    'sp:addSeries("players", {10,20, 30,40, 50,35, 70,55}, 0.2, 0.7, 1.0)')

# LBarChart:addSeries(name, r, g, b)
text = text.replace(
    'bc:addSeries("sales",   {0.2, 0.6, 0.9, 1}, {120, 180})',
    'bc:addSeries("sales", 0.2, 0.6, 0.9)')
text = text.replace(
    'bc:addSeries("returns", {0.9, 0.3, 0.2, 1}, {10,  15})',
    'bc:addSeries("returns", 0.9, 0.3, 0.2)')

# LAreaChart:addLayer(name, vals_tbl, r, g, b)
text = text.replace(
    'ac:addLayer("series_a", {1,0.3,0.3,0.7}, {10,20,15,30,25})',
    'ac:addLayer("series_a", {10,20,15,30,25}, 1.0, 0.3, 0.3)')
text = text.replace(
    'ac:addLayer("series_b", {0.3,0.6,1,0.7}, {5,10,8,14,12})',
    'ac:addLayer("series_b", {5,10,8,14,12}, 0.3, 0.6, 1.0)')

# LPieChart:addSegment(label, value, r, g, b)
text = text.replace(
    'pc:addSegment("Wheat",  40, {0.9, 0.8, 0.3, 1})',
    'pc:addSegment("Wheat", 40, 0.9, 0.8, 0.3)')
text = text.replace(
    'pc:addSegment("Sheep",  25, {0.8, 0.9, 0.5, 1})',
    'pc:addSegment("Sheep", 25, 0.8, 0.9, 0.5)')
text = text.replace(
    'pc:addSegment("Forest", 35, {0.2, 0.7, 0.3, 1})',
    'pc:addSegment("Forest", 35, 0.2, 0.7, 0.3)')

p.write_text(text, encoding="utf-8")
print("Done. All chart fixes applied.")
