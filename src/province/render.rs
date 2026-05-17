//! - Province map rendering: convert registry data into a flat RenderCommand list.
//! - Viewport culling based on screen bounds and zoom/pan transform.
//! - Fill rendering via per-province span rectangles coloured by the active map mode.
//! - Border rendering with colour classification (land-land, coast, sea-sea, special).
//! - Capital dot markers and text labels with shadow offset.
//! - Hover and selection highlight outlines for interactive feedback.

use crate::province::borders::classify_border;
use crate::province::map_modes::{resolve_color, ProvinceMapMode};
use crate::province::registry::ProvinceRegistry;
use crate::province::types::{BorderClass, ProvinceId};
use crate::render::renderer::{DrawMode, RenderCommand};
use crate::runtime::resource_keys::FontKey;

/// Options controlling what gets rendered and how the province map is projected onto the screen.
#[derive(Debug, Clone)]
pub struct ProvinceRenderOptions {
    /// Horizontal screen translation applied before zoom.
    pub x: f32,
    /// Vertical screen translation applied before zoom.
    pub y: f32,
    /// Zoom multiplier applied after translation.
    pub zoom: f32,
    /// Size in screen pixels of one province map pixel; combined with zoom for final scale.
    pub pixel_size: f32,
    /// Screen width in pixels, used for viewport culling.
    pub screen_w: f32,
    /// Screen height in pixels, used for viewport culling.
    pub screen_h: f32,
    /// Active map mode that drives fill colour selection.
    pub map_mode: ProvinceMapMode,
    /// When true, emit fill rectangles for province spans.
    pub draw_fills: bool,
    /// When true, emit line segments for province borders.
    pub draw_borders: bool,
    /// When true, emit text labels at province label or centroid positions.
    pub draw_labels: bool,
    /// When true, emit capital dot markers.
    pub draw_capitals: bool,
    /// Line width in screen pixels for border segments.
    pub border_width: f32,
    /// Province to highlight with a white hover outline, or None.
    pub hovered_id: Option<ProvinceId>,
    /// Province to highlight with a yellow selection outline, or None.
    pub selected_id: Option<ProvinceId>,
}

/// Default ProvinceRenderOptions: no translation, zoom 1, pixel_size 1, political mode, fills+borders+capitals enabled.
impl Default for ProvinceRenderOptions {
    fn default() -> Self {
        Self {
            x: 0.0,
            y: 0.0,
            zoom: 1.0,
            pixel_size: 1.0,
            screen_w: 1280.0,
            screen_h: 720.0,
            map_mode: ProvinceMapMode::Political,
            draw_fills: true,
            draw_borders: true,
            draw_labels: false,
            draw_capitals: true,
            border_width: 1.0,
            hovered_id: None,
            selected_id: None,
        }
    }
}

/// Return the RGBA line colour for a border segment based on its class.
fn border_color(class: BorderClass) -> [f32; 4] {
    match class {
        BorderClass::LandLand => [120.0 / 255.0, 120.0 / 255.0, 120.0 / 255.0, 1.0],
        BorderClass::Coast => [250.0 / 255.0, 220.0 / 255.0, 60.0 / 255.0, 230.0 / 255.0],
        BorderClass::SeaSea => [40.0 / 255.0, 130.0 / 255.0, 1.0, 230.0 / 255.0],
        BorderClass::Special => [1.0, 0.2, 1.0, 1.0],
    }
}

/// Compute the visible province-space bounds (left, top, right, bottom) from the render options.
fn viewport_bounds(opts: &ProvinceRenderOptions) -> (f32, f32, f32, f32) {
    let zoom_ps = (opts.zoom * opts.pixel_size).max(0.0001);
    let left = -opts.x / zoom_ps;
    let top = -opts.y / zoom_ps;
    let right = (opts.screen_w - opts.x) / zoom_ps;
    let bottom = (opts.screen_h - opts.y) / zoom_ps;
    (left, top, right, bottom)
}
/// Generate a RenderCommand Vec for the province map: fills, borders, capitals, and labels with viewport culling.
pub fn generate_render_commands(
    registry: &ProvinceRegistry,
    opts: &ProvinceRenderOptions,
    font_key: Option<FontKey>,
) -> Vec<RenderCommand> {
    let mut cmds: Vec<RenderCommand> = Vec::new();
    let (left, top, right, bottom) = viewport_bounds(opts);
    cmds.push(RenderCommand::PushTransform);
    cmds.push(RenderCommand::Translate {
        x: opts.x,
        y: opts.y,
    });
    cmds.push(RenderCommand::Scale {
        sx: opts.zoom,
        sy: opts.zoom,
    });
    if opts.draw_fills {
        for id in registry.province_ids() {
            let Some(bb) = registry.bbox_for(id) else {
                continue;
            };
            if (bb.2 as f32) < left {
                continue;
            }
            if (bb.0 as f32) > right {
                continue;
            }
            if (bb.3 as f32) < top {
                continue;
            }
            if (bb.1 as f32) > bottom {
                continue;
            }
            let Some(style) = registry.style_for(id) else {
                continue;
            };
            let c = resolve_color(opts.map_mode, style);
            cmds.push(RenderCommand::SetColor(c[0], c[1], c[2], c[3]));
            if let Some(spans) = registry.spans_for(id) {
                // Merge vertically-adjacent spans with same x0,x1 into taller rectangles
                let mut i = 0;
                while i < spans.len() {
                    let (y, x0, x1) = spans[i];
                    if (y as f32) > bottom || (x1 as f32) <= left || (x0 as f32) >= right {
                        i += 1;
                        continue;
                    }
                    if (y as f32) < top {
                        i += 1;
                        continue;
                    }
                    // Try to merge consecutive spans with same x0, x1
                    let mut height: u32 = 1;
                    while i + (height as usize) < spans.len() {
                        let (ny, nx0, nx1) = spans[i + height as usize];
                        if nx0 == x0 && nx1 == x1 && ny == y + height {
                            height += 1;
                            if (ny as f32) > bottom {
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                    cmds.push(RenderCommand::Rectangle {
                        mode: DrawMode::Fill,
                        x: x0 as f32 * opts.pixel_size,
                        y: y as f32 * opts.pixel_size,
                        w: (x1 - x0) as f32 * opts.pixel_size,
                        h: height as f32 * opts.pixel_size,
                    });
                    i += height as usize;
                }
            }
        }
    }
    if opts.draw_borders {
        let effective_scale = opts.zoom * opts.pixel_size;
        // LOD: skip all borders when they'd be sub-pixel
        if effective_scale >= 0.5 {
            cmds.push(RenderCommand::SetLineWidth(opts.border_width.max(1.0)));
            // Group border segments by class to minimize SetColor calls.
            // At low zoom, skip LandLand borders (invisible at sub-2px scale).
            let skip_land_land = effective_scale < 2.0;
            let classes = if skip_land_land {
                &[BorderClass::Coast, BorderClass::SeaSea, BorderClass::Special][..]
            } else {
                &[
                    BorderClass::LandLand,
                    BorderClass::Coast,
                    BorderClass::SeaSea,
                    BorderClass::Special,
                ][..]
            };
            for &class in classes {
                let c = border_color(class);
                cmds.push(RenderCommand::SetColor(c[0], c[1], c[2], c[3]));
                for &(a, b, x0, y0, x1, y1) in registry.border_segments() {
                    let min_x = x0.min(x1) as f32;
                    let max_x = x0.max(x1) as f32;
                    let min_y = y0.min(y1) as f32;
                    let max_y = y0.max(y1) as f32;
                    if max_x < left || min_x > right || max_y < top || min_y > bottom {
                        continue;
                    }
                    let seg_class = if let Some(c) = registry.get_border_class(a, b) {
                        c
                    } else {
                        let sa = registry.style_for(a);
                        let sb = registry.style_for(b);
                        match (sa, sb) {
                            (Some(sa), Some(sb)) => classify_border(sa, sb),
                            _ => BorderClass::LandLand,
                        }
                    };
                    if seg_class != class {
                        continue;
                    }
                    cmds.push(RenderCommand::Line {
                        x1: x0 as f32 * opts.pixel_size,
                        y1: y0 as f32 * opts.pixel_size,
                        x2: x1 as f32 * opts.pixel_size,
                        y2: y1 as f32 * opts.pixel_size,
                    });
                }
            }
        }
    }
    if opts.draw_capitals {
        for id in registry.province_ids() {
            let Some(bb) = registry.bbox_for(id) else {
                continue;
            };
            if (bb.2 as f32) < left {
                continue;
            }
            if (bb.0 as f32) > right {
                continue;
            }
            if (bb.3 as f32) < top {
                continue;
            }
            if (bb.1 as f32) > bottom {
                continue;
            }
            let marker = registry
                .capital_for(id)
                .or_else(|| registry.get_province(id).and_then(|p| p.centroid));
            let Some((cx, cy)) = marker else {
                continue;
            };
            cmds.push(RenderCommand::SetColor(
                1.0,
                220.0 / 255.0,
                70.0 / 255.0,
                1.0,
            ));
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Fill,
                x: cx * opts.pixel_size,
                y: cy * opts.pixel_size,
                r: (opts.pixel_size * 0.42).max(2.0),
            });
            cmds.push(RenderCommand::SetColor(
                20.0 / 255.0,
                20.0 / 255.0,
                20.0 / 255.0,
                1.0,
            ));
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Fill,
                x: cx * opts.pixel_size,
                y: cy * opts.pixel_size,
                r: (opts.pixel_size * 0.24).max(1.0),
            });
        }
    }
    if opts.draw_labels {
        if let Some(font) = font_key {
            for id in registry.province_ids() {
                let Some(bb) = registry.bbox_for(id) else {
                    continue;
                };
                if (bb.2 as f32) < left {
                    continue;
                }
                if (bb.0 as f32) > right {
                    continue;
                }
                if (bb.3 as f32) < top {
                    continue;
                }
                if (bb.1 as f32) > bottom {
                    continue;
                }
                let text = registry
                    .label_text_for(id)
                    .map(|s| s.to_string())
                    .unwrap_or_else(|| id.to_string());
                let ((ax, ay), (bx, by)) = registry
                    .label_line_for(id)
                    .unwrap_or(((bb.0 as f32, bb.1 as f32), (bb.2 as f32, bb.3 as f32)));
                let mx = (ax + bx) * 0.5;
                let my = (ay + by) * 0.5;
                cmds.push(RenderCommand::SetColor(0.0, 0.0, 0.0, 0.65));
                cmds.push(RenderCommand::Print {
                    font_key: font,
                    text: text.clone(),
                    x: mx * opts.pixel_size + 1.0,
                    y: my * opts.pixel_size + 1.0,
                    scale: 0.8,
                });
                cmds.push(RenderCommand::SetColor(0.92, 0.92, 0.86, 1.0));
                cmds.push(RenderCommand::Print {
                    font_key: font,
                    text,
                    x: mx * opts.pixel_size,
                    y: my * opts.pixel_size,
                    scale: 0.8,
                });
            }
        }
    }
    if let Some(id) = opts.hovered_id {
        if let Some((min_x, min_y, max_x, max_y)) = registry.bbox_for(id) {
            cmds.push(RenderCommand::SetColor(1.0, 1.0, 1.0, 0.35));
            cmds.push(RenderCommand::SetLineWidth(2.0));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Line,
                x: min_x as f32 * opts.pixel_size,
                y: min_y as f32 * opts.pixel_size,
                w: (max_x.saturating_sub(min_x) + 1) as f32 * opts.pixel_size,
                h: (max_y.saturating_sub(min_y) + 1) as f32 * opts.pixel_size,
            });
        }
    }
    if let Some(id) = opts.selected_id {
        if let Some((min_x, min_y, max_x, max_y)) = registry.bbox_for(id) {
            cmds.push(RenderCommand::SetColor(1.0, 0.9, 0.1, 0.9));
            cmds.push(RenderCommand::SetLineWidth(3.0));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Line,
                x: min_x as f32 * opts.pixel_size,
                y: min_y as f32 * opts.pixel_size,
                w: (max_x.saturating_sub(min_x) + 1) as f32 * opts.pixel_size,
                h: (max_y.saturating_sub(min_y) + 1) as f32 * opts.pixel_size,
            });
        }
    }
    cmds.push(RenderCommand::PopTransform);
    cmds
}
