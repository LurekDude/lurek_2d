import re
with open('tests/rust/golden/evidence.rs', 'r', encoding='utf-8') as f:
    text = f.read()

# remove GUI button states
text = re.sub(r'/// GUI button states[\s\S]*?save_png\("gui/button_states", &img\);\n}\n*', '', text)
# remove GUI panel layout
text = re.sub(r'/// GUI panel[\s\S]*?save_png\("gui/panel_layout", &img\);\n}\n*', '', text)
# remove GUI hud bars
text = re.sub(r'#\[test\]\nfn evidence_gui_hud_bars\(\)[\s\S]*?save_png\("gui/hud_bars", &img\);\n}\n*', '', text)

# remove chart imports
text = re.sub(r'use lurek2d::ui::chart::\{[\s\S]*?\};\n*', '', text)
text = re.sub(r'use lurek2d::ui::theme::Theme;\n*', '', text)
text = re.sub(r'use lurek2d::ui::visualization;\n*', '', text)

with open('tests/rust/golden/evidence.rs', 'w', encoding='utf-8') as f:
    f.write(text)
