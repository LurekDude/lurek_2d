use crate::image::ImageData;
/// Render a panel layout with borders, labels, and content areas into an image.
pub fn panel_layout_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(35, 35, 45, 255);
    let px = 30i32;
    let py = 20i32;
    let pw = 340i32;
    let ph = 300i32;
    img.draw_rect(px + 3, py + 3, pw as u32, ph as u32, 15, 15, 20, 255);
    img.draw_rect(px, py, pw as u32, ph as u32, 55, 55, 65, 255);
    img.draw_rect(px, py, pw as u32, 24, 70, 100, 160, 255);
    img.draw_label("SETTINGS PANEL", px + 8, py + 8, 220, 230, 240);
    let cbx = px + pw - 20;
    img.draw_rect(cbx, py + 4, 16, 16, 200, 60, 60, 255);
    img.draw_label("X", cbx + 5, py + 9, 255, 255, 255);
    let cy = py + 36;
    img.draw_label("SOUND", px + 12, cy, 180, 180, 190);
    img.draw_rect(px + 80, cy - 2, 12, 12, 40, 40, 50, 255);
    img.draw_line(px + 82, cy + 3, px + 85, cy + 7, 100, 220, 100, 255);
    img.draw_line(px + 85, cy + 7, px + 90, cy, 100, 220, 100, 255);
    img.draw_label("ON", px + 96, cy, 100, 220, 100);
    let sy = cy + 20;
    img.draw_label("VOLUME", px + 12, sy, 180, 180, 190);
    let sl_x = px + 80;
    let sl_w = 200i32;
    img.draw_rect(sl_x, sy + 2, sl_w as u32, 4, 40, 40, 50, 255);
    let knob_x = sl_x + (sl_w as f32 * 0.7) as i32;
    img.draw_circle(knob_x, sy + 4, 5, 100, 160, 230, 255);
    img.draw_label("70%", knob_x + 8, sy - 2, 130, 180, 240);
    let sy2 = sy + 24;
    img.draw_label("BRIGHT", px + 12, sy2, 180, 180, 190);
    img.draw_rect(sl_x, sy2 + 2, sl_w as u32, 4, 40, 40, 50, 255);
    let knob2_x = sl_x + (sl_w as f32 * 0.45) as i32;
    img.draw_circle(knob2_x, sy2 + 4, 5, 100, 160, 230, 255);
    img.draw_label("45%", knob2_x + 8, sy2 - 2, 130, 180, 240);
    let dy = sy2 + 28;
    img.draw_label("MODE", px + 12, dy, 180, 180, 190);
    img.draw_rect(sl_x, dy - 2, 120, 14, 45, 45, 55, 255);
    img.draw_label("FULLSCREEN", sl_x + 4, dy, 200, 200, 210);
    img.draw_line(sl_x + 108, dy + 2, sl_x + 112, dy + 6, 150, 150, 160, 255);
    img.draw_line(sl_x + 112, dy + 6, sl_x + 116, dy + 2, 150, 150, 160, 255);
    let sep_y = dy + 22;
    img.draw_line(px + 8, sep_y, px + pw - 8, sep_y, 70, 70, 80, 255);
    let ry = sep_y + 8;
    img.draw_label("QUALITY", px + 12, ry, 180, 180, 190);
    let options = ["LOW", "MED", "HIGH"];
    for (i, &opt) in options.iter().enumerate() {
        let ox = sl_x + i as i32 * 56;
        for angle in 0..32i32 {
            let a = angle as f32 * std::f32::consts::PI / 16.0;
            let rx = ox + 5 + (a.cos() * 5.0) as i32;
            let ry_px = ry + 3 + (a.sin() * 5.0) as i32;
            if rx >= 0 && ry_px >= 0 && (rx as u32) < width && (ry_px as u32) < height {
                img.set_pixel(rx as u32, ry_px as u32, 140, 140, 150, 255);
            }
        }
        if i == 1 {
            img.draw_circle(ox + 5, ry + 3, 2, 100, 180, 230, 255);
        }
        img.draw_label(opt, ox + 14, ry, 170, 170, 180);
    }
    let pby = ry + 24;
    img.draw_label("LOADING", px + 12, pby, 180, 180, 190);
    img.draw_rect(sl_x, pby, sl_w as u32, 10, 40, 40, 50, 255);
    let fill_w = (sl_w as f32 * 0.65) as u32;
    img.draw_rect(sl_x, pby, fill_w, 10, 70, 160, 90, 255);
    img.draw_label("65%", sl_x + fill_w as i32 + 4, pby + 2, 130, 200, 140);
    let csy = pby + 22;
    img.draw_label("THEME", px + 12, csy, 180, 180, 190);
    let swatch_colors: [(u8, u8, u8); 5] = [
        (200, 60, 60),
        (60, 160, 200),
        (60, 180, 80),
        (200, 180, 60),
        (160, 80, 200),
    ];
    for (i, &(cr, cg, cb)) in swatch_colors.iter().enumerate() {
        let sx = sl_x + i as i32 * 22;
        img.draw_rect(sx, csy - 2, 18, 14, cr, cg, cb, 255);
        if i == 1 {
            for edge in 0..18i32 {
                img.set_pixel((sx + edge) as u32, (csy - 2) as u32, 255, 255, 255, 255);
                img.set_pixel((sx + edge) as u32, (csy + 11) as u32, 255, 255, 255, 255);
            }
        }
    }
    let btn_y = py + ph - 30;
    img.draw_rect(px + pw - 80, btn_y, 60, 22, 60, 140, 60, 255);
    img.draw_label("OK", px + pw - 62, btn_y + 8, 220, 240, 220);
    img.draw_rect(px + pw - 150, btn_y, 60, 22, 160, 60, 60, 255);
    img.draw_label("CANCEL", px + pw - 144, btn_y + 8, 240, 220, 220);
    img
}
/// Render a HUD with labeled health, mana, and XP bars at various fill levels into an image.
pub fn hud_bars_to_image(width: u32, height: u32) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 30, 255);
    let hx = 20i32;
    let hy = 30i32;
    img.draw_label("HP", hx, hy - 10, 200, 80, 80);
    img.draw_rect(hx, hy, 300, 20, 40, 15, 15, 255);
    img.draw_rect(hx, hy, (300.0 * 0.75) as u32, 20, 200, 50, 50, 255);
    img.draw_rect(hx, hy, (300.0 * 0.75) as u32, 3, 240, 100, 100, 255);
    img.draw_label("75%", hx + 230, hy + 7, 255, 200, 200);
    let my = hy + 36;
    img.draw_label("MP", hx, my - 10, 80, 120, 220);
    img.draw_rect(hx, my, 300, 20, 15, 15, 40, 255);
    img.draw_rect(hx, my, (300.0 * 0.40) as u32, 20, 50, 80, 200, 255);
    img.draw_rect(hx, my, (300.0 * 0.40) as u32, 3, 100, 140, 240, 255);
    img.draw_label("40%", hx + 124, my + 7, 180, 200, 255);
    let sy = my + 36;
    img.draw_label("ST", hx, sy - 10, 80, 200, 80);
    img.draw_rect(hx, sy, 300, 14, 15, 30, 15, 255);
    img.draw_rect(hx, sy, (300.0 * 0.90) as u32, 14, 50, 180, 50, 255);
    img.draw_rect(hx, sy, (300.0 * 0.90) as u32, 2, 100, 220, 100, 255);
    img.draw_label("90%", hx + 275, sy + 4, 180, 255, 180);
    let xy = sy + 30;
    img.draw_label("XP", hx, xy - 10, 220, 200, 80);
    img.draw_rect(hx, xy, 300, 8, 30, 25, 10, 255);
    img.draw_rect(hx, xy, (300.0 * 0.55) as u32, 8, 200, 180, 50, 255);
    img.draw_label("55% TO LVL 12", hx + 170, xy - 2, 230, 210, 120);
    let cd_y = xy + 30;
    img.draw_label("SKILLS", hx, cd_y - 10, 180, 180, 190);
    let skill_pcts = [1.0f32, 0.7, 0.3, 0.0];
    let skill_colors: [(u8, u8, u8); 4] =
        [(80, 200, 80), (200, 200, 80), (200, 120, 60), (100, 40, 40)];
    for (i, (&pct, &(cr, cg, cb))) in skill_pcts.iter().zip(skill_colors.iter()).enumerate() {
        let scx = hx + 40 + i as i32 * 50;
        let scy = cd_y + 10;
        img.draw_circle(scx, scy, 16, 30, 30, 40, 255);
        if pct > 0.0 {
            let end_angle = -std::f32::consts::FRAC_PI_2 + pct * 2.0 * std::f32::consts::PI;
            for iy in (scy - 15)..=(scy + 15) {
                for ix in (scx - 15)..=(scx + 15) {
                    let dx = ix as f32 - scx as f32;
                    let dy = iy as f32 - scy as f32;
                    if dx * dx + dy * dy > 14.0 * 14.0 {
                        continue;
                    }
                    let mut a = dy.atan2(dx);
                    if a < -std::f32::consts::FRAC_PI_2 {
                        a += 2.0 * std::f32::consts::PI;
                    }
                    if a <= end_angle
                        && ix >= 0
                        && iy >= 0
                        && (ix as u32) < width
                        && (iy as u32) < height
                    {
                        img.set_pixel(ix as u32, iy as u32, cr, cg, cb, 220);
                    }
                }
            }
        }
        img.draw_label(&format!("{}", i + 1), scx - 2, scy - 2, 255, 255, 255);
    }
    img.draw_label("GAME HUD", (width / 2 - 20) as i32, 10, 220, 220, 230);
    img
}
