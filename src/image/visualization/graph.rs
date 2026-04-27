//! Graph visualization helpers.
//!
//! Renders node–edge graphs and pipeline item-flow diagrams as CPU-side [`ImageData`].

use crate::image::ImageData;

/// Render a graph with explicit node positions, labels, edge list, and stats.
///
/// # Parameters
/// - `positions` — `&[(f32, f32)]`. Node positions.
/// - `labels` — `&[&str]`. Node labels.
/// - `colors` — `&[(u8, u8, u8)]`. Node colours.
/// - `edges` — `&[(usize, usize)]`. Active edge index pairs.
/// - `removed_edges` — `&[(usize, usize)]`. Dashed/dim edge pairs.
/// - `stats_text` — `&str`. Stats string to draw at bottom-left.
/// - `title` — `&str`. Title text.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
#[allow(clippy::too_many_arguments)]
pub fn draw_graph_operations_to_image(
    positions: &[(f32, f32)],
    labels: &[&str],
    colors: &[(u8, u8, u8)],
    edges: &[(usize, usize)],
    removed_edges: &[(usize, usize)],
    stats_text: &str,
    title: &str,
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    // Draw active edges
    for &(a, b) in edges {
        if a < positions.len() && b < positions.len() {
            let (ax, ay) = positions[a];
            let (bx, by) = positions[b];
            img.draw_line(
                ax as i32, ay as i32, bx as i32, by as i32, 80, 120, 180, 200,
            );
        }
    }

    // Draw removed edges (dimmed)
    for &(a, b) in removed_edges {
        if a < positions.len() && b < positions.len() {
            let (ax, ay) = positions[a];
            let (bx, by) = positions[b];
            img.draw_line(ax as i32, ay as i32, bx as i32, by as i32, 80, 40, 40, 100);
        }
    }

    // Draw nodes
    for (i, &(px, py)) in positions.iter().enumerate() {
        let (r, g, b) = if i < colors.len() {
            colors[i]
        } else {
            (180, 180, 180)
        };
        img.draw_circle(px as i32, py as i32, 14, r, g, b, 255);
        if i < labels.len() {
            img.draw_label(labels[i], (px - 30.0) as i32, (py + 18.0) as i32, r, g, b);
        }
    }

    img.draw_label(stats_text, 10, (height - 20) as i32, 200, 200, 200);
    img.draw_label(title, (width / 2 - 40) as i32, 5, 100, 255, 100);
    img
}

/// Render a pipeline graph with nodes, directional pipes, and item indicators.
///
/// # Parameters
/// - `node_pos` — `&[(f32, f32)]`. Node centre positions.
/// - `node_names` — `&[&str]`. Node labels drawn below each node.
/// - `node_colors` — `&[(u8, u8, u8)]`. Node fill colours.
/// - `items` — `&[(i32, i32, u8, u8, u8, &str)]`. (x, y, r, g, b, label) for item dots.
/// - `stats_text` — `&str`. Bottom-left stats string.
/// - `title` — `&str`. Top title.
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// # Returns
/// `ImageData`.
#[allow(clippy::too_many_arguments)]
pub fn draw_graph_item_flow_to_image(
    node_pos: &[(f32, f32)],
    node_names: &[&str],
    node_colors: &[(u8, u8, u8)],
    items: &[(i32, i32, u8, u8, u8, &str)],
    stats_text: &str,
    title: &str,
    width: u32,
    height: u32,
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);

    // Draw pipes between consecutive nodes
    for i in 0..node_pos.len().saturating_sub(1) {
        let (ax, ay) = node_pos[i];
        let (bx, by) = node_pos[i + 1];
        let start_x = ax as i32 + 30;
        let end_x = bx as i32 - 30;
        img.draw_line(start_x, ay as i32, end_x, by as i32, 100, 150, 200, 200);
        // Arrow head
        img.draw_line(
            end_x - 10,
            by as i32 - 5,
            end_x,
            by as i32,
            100,
            150,
            200,
            200,
        );
        img.draw_line(
            end_x - 10,
            by as i32 + 5,
            end_x,
            by as i32,
            100,
            150,
            200,
            200,
        );
    }

    // Draw nodes
    for (i, &(px, py)) in node_pos.iter().enumerate() {
        let (r, g, b) = if i < node_colors.len() {
            node_colors[i]
        } else {
            (180, 180, 180)
        };
        img.draw_circle(px as i32, py as i32, 20, r, g, b, 255);
        if i < node_names.len() {
            img.draw_label(
                node_names[i],
                (px - 22.0) as i32,
                (py + 25.0) as i32,
                r,
                g,
                b,
            );
        }
    }

    // Draw items
    for &(ix, iy, ir, ig, ib, label) in items {
        img.draw_circle(ix, iy, 6, ir, ig, ib, 255);
        img.draw_label(label, ix - 10, iy - 15, ir, ig, ib);
    }

    img.draw_label(title, (width / 2 - 40) as i32, 5, 100, 255, 100);
    img.draw_label(stats_text, 10, (height - 20) as i32, 200, 200, 200);
    img
}
