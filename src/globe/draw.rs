//! Frame emission for the globe module.
//!
//! `emit_globe_frame` converts a `Globe` snapshot into a flat `Vec<RenderCommand>`
//! suitable for the Lurek2D render queue. No GPU state is held here.

use std::collections::HashMap;
use crate::globe::types::{GlobeSpec, LodTier, Arc as GlobeArc};
use crate::globe::projection::{OrbitCamera, build_view_matrix, project_province, project_point};
use crate::globe::lighting::{sun_direction, province_intensity};
use crate::globe::topology::ProvinceGraph;
use crate::globe::fog::FogStore;
use crate::globe::marker::MarkerStore;
use crate::globe::label::LabelStore;
use crate::globe::layer::LayerStore;
use crate::math::sphere::great_circle_path;
use crate::render::renderer::{RenderCommand, BlendMode, DrawMode};
use crate::runtime::resource_keys::FontKey;

/// Emit all render commands for one globe frame.
///
/// `default_font` is the `FontKey` to use for labels and marker text.
/// Pass `None` to suppress all text rendering.
pub fn emit_globe_frame(
    spec: &GlobeSpec,
    camera: &OrbitCamera,
    graph: &ProvinceGraph,
    fog: &FogStore,
    markers: &MarkerStore,
    labels: &LabelStore,
    layers: &LayerStore,
    arcs: &HashMap<u32, GlobeArc>,
    active_viewer: Option<&str>,
    default_font: Option<FontKey>,
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

    // ── 1. Province polygons ─────────────────────────────────────────────────
    for province in graph.iter() {
        // Fog check
        if let Some(viewer) = active_viewer {
            if !fog.is_visible(viewer, province.id) {
                // Render as dark, unfilled
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

        let intensity = province_intensity(
            province.centroid.0,
            province.centroid.1,
            &sun,
            spec.ambient,
        );

        let base = layers
            .effective_color(province.id)
            .unwrap_or(province.base_color);

        let tint = [
            (base[0] * intensity).clamp(0.0, 1.0),
            (base[1] * intensity).clamp(0.0, 1.0),
            (base[2] * intensity).clamp(0.0, 1.0),
            base[3],
        ];

        if let Some(proj) = project_province(province, &view, spec, camera, intensity) {
            cmds.push(RenderCommand::DrawConvexFan {
                vertices: proj.screen_verts.clone(),
                uvs: Vec::new(),
                texture_key: None,
                tint,
                blend: BlendMode::Alpha,
            });

            // Borders at Mid/Near LOD
            if spec.render_borders && lod >= LodTier::Mid {
                let [br, bg, bb, ba] = spec.border_color;
                cmds.push(RenderCommand::SetLineWidth(spec.border_width));
                cmds.push(RenderCommand::SetColor(br, bg, bb, ba));
                let mut pts: Vec<f32> = proj
                    .screen_verts
                    .iter()
                    .flat_map(|v| [v.x, v.y])
                    .collect();
                if let Some(first) = proj.screen_verts.first() {
                    pts.push(first.x);
                    pts.push(first.y);
                }
                if pts.len() >= 4 {
                    cmds.push(RenderCommand::Polyline { points: pts });
                }
            }
        }
    }

    // ── 2. Arcs (great-circle paths) ─────────────────────────────────────────
    for arc in arcs.values() {
        if !arc.visible || arc.screen_points.len() < 4 {
            continue;
        }
        let [ar, ag, ab, aa] = arc.color;
        cmds.push(RenderCommand::SetLineWidth(arc.width));
        cmds.push(RenderCommand::SetColor(ar, ag, ab, aa));
        cmds.push(RenderCommand::Polyline {
            points: arc.screen_points.iter().flat_map(|p| [p.x, p.y]).collect(),
        });
    }

    // ── 3. Markers ────────────────────────────────────────────────────────────
    for marker in markers.iter_visible() {
        if let Some(screen) = project_point(
            marker.lat_deg,
            marker.lon_deg,
            &view,
            radius,
            zoom,
            cx,
            cy,
        ) {
            let [mr, mg, mb, ma] = marker.style.color;
            let r = (marker.style.size * 0.5).max(2.0);
            cmds.push(RenderCommand::SetColor(mr, mg, mb, ma));
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Fill,
                x: screen.x,
                y: screen.y,
                r,
            });

            // Marker label
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

    // ── 4. Labels (Mid/Near LOD only) ─────────────────────────────────────────
    if lod >= LodTier::Mid {
        if let Some(font_key) = default_font {
            for label in labels.iter_visible(lod_u8) {
                if let Some(screen) = project_point(
                    label.lat_deg,
                    label.lon_deg,
                    &view,
                    radius,
                    zoom,
                    cx,
                    cy,
                ) {
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

/// Pre-project a great-circle arc into a flat screenspace point list.
///
/// Returns `[x0, y0, x1, y1, …]`. May return fewer points if the arc is
/// entirely on the back of the globe.
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
        if let Some(v) = project_point(lat, lon, view, spec.radius, camera.zoom, camera.screen_cx, camera.screen_cy) {
            out.push(v.x);
            out.push(v.y);
        }
    }
    out
}


