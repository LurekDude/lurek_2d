use crate::globe::fog::FogStore;
use crate::globe::label::LabelStore;
use crate::globe::layer::LayerStore;
use crate::globe::lighting::{province_intensity, sun_direction};
use crate::globe::marker::MarkerStore;
use crate::globe::projection::{build_view_matrix, project_point, project_province, OrbitCamera};
use crate::globe::topology::ProvinceGraph;
use crate::globe::types::{Arc as GlobeArc, FogState, GlobeSpec, HeatLayer, LodTier, Province};
use crate::math::sphere::great_circle_path;
use crate::math::Vec2;
use crate::render::renderer::{BlendMode, DrawMode, RenderCommand};
use crate::runtime::resource_keys::FontKey;
use crate::runtime::resource_keys::TextureKey;
use slotmap::KeyData;
use std::collections::HashMap;
/// Emit a full globe frame as render commands for the current globe state.
#[allow(clippy::too_many_arguments)]
pub fn emit_globe_frame(
    spec: &GlobeSpec,
    camera: &OrbitCamera,
    graph: &ProvinceGraph,
    fog: &FogStore,
    markers: &MarkerStore,
    labels: &LabelStore,
    layers: &LayerStore,
    heat_layers: &[HeatLayer],
    arcs: &HashMap<u32, GlobeArc>,
    active_viewer: Option<&str>,
    default_font: Option<FontKey>,
    sim_time_sec: f32,
) -> Vec<RenderCommand> {
    let mut cmds: Vec<RenderCommand> = Vec::new();
    let view = build_view_matrix(spec, camera);
    let sun = sun_direction(spec);
    let lod = camera.lod();
    let lod_u8 = lod as u8;
    let zoom = camera.zoom;
    let cx = camera.screen_cx;
    let cy = camera.screen_cy;
    let radius = spec.radius;
    emit_atmosphere_halo(&mut cmds, spec, camera);
    for province in graph.iter() {
        if let Some(viewer) = active_viewer {
            if let FogState::Hidden = fog.state(viewer, province.id) {
                if let Some(proj) = project_province(province, &view, spec, camera, 0.0) {
                    cmds.push(RenderCommand::DrawConvexFan {
                        vertices: proj.screen_verts,
                        uvs: Vec::new(),
                        texture_key: None,
                        tint: [0.05, 0.05, 0.05, 1.0],
                        blend: BlendMode::Alpha,
                    });
                }
                continue;
            }
        }
        let intensity =
            province_intensity(province.centroid.0, province.centroid.1, &sun, spec.ambient);
        let mut base = layers
            .effective_color(province.id)
            .unwrap_or(province.base_color);
        apply_heat_layers(&mut base, province, heat_layers);
        if let Some(viewer) = active_viewer {
            if let FogState::Explored = fog.state(viewer, province.id) {
                base[0] *= 0.45;
                base[1] *= 0.45;
                base[2] *= 0.45;
            }
        }
        let tint = [
            (base[0] * intensity).clamp(0.0, 1.0),
            (base[1] * intensity).clamp(0.0, 1.0),
            (base[2] * intensity).clamp(0.0, 1.0),
            base[3],
        ];
        if let Some(proj) = project_province(province, &view, spec, camera, intensity) {
            let texture_key = province
                .attrs
                .get("__texture_raw")
                .and_then(|v| v.parse::<u64>().ok())
                .map(|raw| TextureKey::from(KeyData::from_ffi(raw)));
            let uvs = build_province_uvs(province, province.texture_uv_rect);
            cmds.push(RenderCommand::DrawConvexFan {
                vertices: proj.screen_verts.clone(),
                uvs,
                texture_key,
                tint,
                blend: BlendMode::Alpha,
            });
            if spec.render_borders && lod >= LodTier::Mid {
                let [br, bg, bb, ba] = spec.border_color;
                cmds.push(RenderCommand::SetLineWidth(spec.border_width));
                cmds.push(RenderCommand::SetColor(br, bg, bb, ba));
                let border_verts =
                    smooth_polyline(&proj.screen_verts, spec.border_smoothing_passes);
                let mut pts: Vec<f32> = border_verts.iter().flat_map(|v| [v.x, v.y]).collect();
                if let Some(first) = border_verts.first() {
                    pts.push(first.x);
                    pts.push(first.y);
                }
                if pts.len() >= 4 {
                    cmds.push(RenderCommand::Polyline { points: pts });
                }
            }
        }
    }
    for arc in arcs.values() {
        if !arc.visible {
            continue;
        }
        let [ar, ag, ab, aa] = arc.color;
        let pts = project_arc(
            arc.from.0, arc.from.1, arc.to.0, arc.to.1, arc.steps, &view, spec, camera,
        );
        if pts.len() < 4 {
            continue;
        }
        cmds.push(RenderCommand::SetLineWidth(arc.width));
        cmds.push(RenderCommand::SetColor(ar, ag, ab, aa));
        cmds.push(RenderCommand::Polyline { points: pts });
    }
    for marker in markers.iter_visible() {
        if let Some(screen) =
            project_point(marker.lat_deg, marker.lon_deg, &view, radius, zoom, cx, cy)
        {
            let [mr, mg, mb, ma] = marker.style.color;
            let pulse = if marker.style.pulse_hz > 0.0 {
                (sim_time_sec * marker.style.pulse_hz * std::f32::consts::TAU).sin()
                    * marker.style.pulse_amplitude
            } else {
                0.0
            };
            let r = (marker.style.size * (0.5 + pulse)).max(2.0);
            cmds.push(RenderCommand::SetColor(mr, mg, mb, ma));
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Fill,
                x: screen.x,
                y: screen.y,
                r,
            });
            if marker.style.rotation_deg_per_sec.abs() > 0.0 {
                let ang = sim_time_sec * marker.style.rotation_deg_per_sec.to_radians();
                let dx = ang.cos() * (r + 3.0);
                let dy = ang.sin() * (r + 3.0);
                cmds.push(RenderCommand::SetLineWidth(1.0));
                cmds.push(RenderCommand::Polyline {
                    points: vec![screen.x, screen.y, screen.x + dx, screen.y + dy],
                });
            }
            if let (Some(label_text), Some(font_key)) = (&marker.label, default_font) {
                cmds.push(RenderCommand::SetColor(1.0, 1.0, 1.0, 1.0));
                cmds.push(RenderCommand::Print {
                    font_key,
                    text: label_text.clone(),
                    x: screen.x + r + 2.0,
                    y: screen.y - 6.0,
                    scale: 0.75,
                });
            }
        }
    }
    if lod >= LodTier::Mid {
        if let Some(font_key) = default_font {
            for label in labels.iter_visible(lod_u8) {
                if let Some(screen) =
                    project_point(label.lat_deg, label.lon_deg, &view, radius, zoom, cx, cy)
                {
                    let [lr, lg, lb, la] = label.style.color;
                    let scale = (label.style.font_size / 16.0).clamp(0.5, 4.0);
                    cmds.push(RenderCommand::SetColor(lr, lg, lb, la));
                    cmds.push(RenderCommand::Print {
                        font_key,
                        text: label.text.clone(),
                        x: screen.x,
                        y: screen.y,
                        scale,
                    });
                }
            }
        }
    }
    cmds
}
/// Build province UVs from latitude/longitude vertices and an optional UV rectangle.
fn build_province_uvs(province: &Province, rect: Option<[f32; 4]>) -> Vec<Vec2> {
    let [u0, v0, u1, v1] = rect.unwrap_or([0.0, 0.0, 1.0, 1.0]);
    province
        .vertices
        .iter()
        .map(|(lat, lon)| {
            let un = ((lon + 180.0) / 360.0).clamp(0.0, 1.0);
            let vn = ((90.0 - lat) / 180.0).clamp(0.0, 1.0);
            Vec2::new(u0 + (u1 - u0) * un, v0 + (v1 - v0) * vn)
        })
        .collect()
}
/// Blend visible heat layers into a province base color.
fn apply_heat_layers(base: &mut [f32; 4], province: &Province, heat_layers: &[HeatLayer]) {
    let mut sorted: Vec<&HeatLayer> = heat_layers.iter().filter(|l| l.visible).collect();
    sorted.sort_by_key(|l| l.z_order);
    for layer in sorted {
        let Some(raw_val) = province.attrs.get(&layer.attr_key) else {
            continue;
        };
        let Ok(v) = raw_val.parse::<f32>() else {
            continue;
        };
        let span = (layer.max_value - layer.min_value).max(1e-6);
        let t = ((v - layer.min_value) / span).clamp(0.0, 1.0);
        let heat = [
            layer.cold_color[0] + (layer.hot_color[0] - layer.cold_color[0]) * t,
            layer.cold_color[1] + (layer.hot_color[1] - layer.cold_color[1]) * t,
            layer.cold_color[2] + (layer.hot_color[2] - layer.cold_color[2]) * t,
            layer.alpha.clamp(0.0, 1.0),
        ];
        base[0] = base[0] * (1.0 - heat[3]) + heat[0] * heat[3];
        base[1] = base[1] * (1.0 - heat[3]) + heat[1] * heat[3];
        base[2] = base[2] * (1.0 - heat[3]) + heat[2] * heat[3];
    }
}
/// Emit atmosphere halo circles when globe atmosphere rendering is enabled.
fn emit_atmosphere_halo(cmds: &mut Vec<RenderCommand>, spec: &GlobeSpec, camera: &OrbitCamera) {
    if !spec.show_atmosphere {
        return;
    }
    let [r, g, b, a] = spec.atmosphere_color;
    let core = (spec.radius * camera.zoom).max(8.0);
    let outer = core + spec.atmosphere_width.max(1.0);
    cmds.push(RenderCommand::SetColor(r, g, b, (a * 0.55).clamp(0.0, 1.0)));
    cmds.push(RenderCommand::Circle {
        mode: DrawMode::Line,
        x: camera.screen_cx,
        y: camera.screen_cy,
        r: outer,
    });
    cmds.push(RenderCommand::SetColor(r, g, b, (a * 0.30).clamp(0.0, 1.0)));
    cmds.push(RenderCommand::Circle {
        mode: DrawMode::Line,
        x: camera.screen_cx,
        y: camera.screen_cy,
        r: outer + spec.atmosphere_width * 0.5,
    });
}
/// Smooth a closed polyline by repeated corner subdivision.
fn smooth_polyline(points: &[Vec2], passes: u8) -> Vec<Vec2> {
    if points.len() < 3 || passes == 0 {
        return points.to_vec();
    }
    let mut current = points.to_vec();
    for _ in 0..passes {
        if current.len() < 3 {
            break;
        }
        let mut out = Vec::with_capacity(current.len() * 2);
        for i in 0..current.len() {
            let a = current[i];
            let b = current[(i + 1) % current.len()];
            out.push(Vec2::new(0.75 * a.x + 0.25 * b.x, 0.75 * a.y + 0.25 * b.y));
            out.push(Vec2::new(0.25 * a.x + 0.75 * b.x, 0.25 * a.y + 0.75 * b.y));
        }
        current = out;
    }
    current
}
/// Project a great-circle arc into a flat polyline of screen coordinates.
#[allow(clippy::too_many_arguments)]
pub fn project_arc(
    lat_a: f32,
    lon_a: f32,
    lat_b: f32,
    lon_b: f32,
    steps: u32,
    view: &crate::math::sphere::Mat3x3,
    spec: &GlobeSpec,
    camera: &OrbitCamera,
) -> Vec<f32> {
    let pts = great_circle_path(lat_a, lon_a, lat_b, lon_b, steps);
    let mut out = Vec::with_capacity(pts.len() * 2);
    for (lat, lon) in pts {
        if let Some(v) = project_point(
            lat,
            lon,
            view,
            spec.radius,
            camera.zoom,
            camera.screen_cx,
            camera.screen_cy,
        ) {
            out.push(v.x);
            out.push(v.y);
        }
    }
    out
}
