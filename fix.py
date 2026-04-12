import re

with open('src/ui/chart.rs', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('pub fn draw_to_image(&self) -> ImageData {', 'pub fn draw_to_image(&self, img: &mut crate::image::ImageData) {')
content = content.replace('        let mut img = ImageData::new(cfg.width, cfg.height);\n', '')
content = content.replace('        let mut img = ImageData::new(w, h);\n', '')

content = re.sub(r'        img\n    \}', '    }', content)

with open('src/ui/chart.rs', 'w', encoding='utf-8') as f:
    f.write(content)

