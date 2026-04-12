import re

with open('tests/rust/golden/evidence.rs', 'r', encoding='utf-8') as f:
    text = f.read()

# remove evidence_chart_line_chart to evidence_chart_area_chart
text = re.sub(r'// ===== CHART / GRAPH EVIDENCE =====.*?fn evidence_chart_area_chart.*?save_png\("chart/area_chart", &img\);\n}', '', text, flags=re.DOTALL)

with open('tests/rust/golden/evidence.rs', 'w', encoding='utf-8') as f:
    f.write(text)

