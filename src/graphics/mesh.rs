//! Mesh API for custom geometry rendering.
//!
//! Meshes allow Lua scripts to define arbitrary vertex data
//! for rendering textured or colored geometry.
//!
//! This module is part of Lurek2D's `graphics` subsystem and provides the implementation
//! details for mesh-related operations and data management.
//! Key types exported from this module: `MeshDrawMode`, `MeshVertex`, `Mesh`.
//! Primary functions: `new()`, `from_vertices()`, `set_vertex()`, `get_vertex()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::engine::log_messages::{MS01, MS02};
use crate::engine::resource_keys::TextureKey;
use crate::log_msg;

/// Drawing mode for mesh geometry. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Triangles` — Triangles variant.
/// - `Fan` — Fan variant.
/// - `Strip` — Strip variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum MeshDrawMode {
    /// Individual triangles (every 3 vertices = 1 triangle).
    Triangles,
    /// Triangle fan (first vertex shared, subsequent pairs form triangles).
    Fan,
    /// Triangle strip (sliding window of 3 vertices).
    Strip,
}

/// A single vertex in a mesh. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `u` — `f32`.
/// - `v` — `f32`.
/// - `r` — `f32`.
/// - `g` — `f32`.
/// - `b` — `f32`.
/// - `a` — `f32`.
#[derive(Debug, Clone, Copy)]
pub struct MeshVertex {
    /// X position in local mesh coordinates.
    pub x: f32,
    /// Y position in local mesh coordinates.
    pub y: f32,
    /// U texture coordinate (0.0–1.0 range).
    pub u: f32,
    /// V texture coordinate (0.0–1.0 range).
    pub v: f32,
    /// Red vertex color component (0.0–1.0).
    pub r: f32,
    /// Green vertex color component (0.0–1.0).
    pub g: f32,
    /// Blue vertex color component (0.0–1.0).
    pub b: f32,
    /// Alpha vertex color component (0.0–1.0).
    pub a: f32,
}

impl Default for MeshVertex {
    fn default() -> Self {
        Self {
            x: 0.0,
            y: 0.0,
            u: 0.0,
            v: 0.0,
            r: 1.0,
            g: 1.0,
            b: 1.0,
            a: 1.0,
        }
    }
}

/// Custom geometry mesh with per-vertex position, UV, and color data.
///
/// # Fields
/// - `vertices` — `Vec<MeshVertex>`.
/// - `indices` — `Option<Vec<u32>>`.
/// - `texture` — `Option<TextureKey>`.
/// - `draw_mode` — `MeshDrawMode`.
#[derive(Debug, Clone)]
pub struct Mesh {
    /// Vertex data.
    pub vertices: Vec<MeshVertex>,
    /// Optional index buffer for indexed drawing.
    pub indices: Option<Vec<u32>>,
    /// Optional texture to apply to the mesh.
    pub texture: Option<TextureKey>,
    /// Drawing mode.
    pub draw_mode: MeshDrawMode,
}

impl Mesh {
    /// Creates a new empty mesh with the specified vertex count and draw mode.
    ///
    /// # Parameters
    /// - `vertex_count` — `usize`.
    /// - `mode` — `MeshDrawMode`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(vertex_count: usize, mode: MeshDrawMode) -> Self {
        log_msg!(debug, MS01, "{}", vertex_count);
        Self {
            vertices: vec![MeshVertex::default(); vertex_count],
            indices: None,
            texture: None,
            draw_mode: mode,
        }
    }

    /// Creates a mesh from a vector of vertices.
    ///
    /// # Parameters
    /// - `vertices` — `Vec<MeshVertex>`.
    /// - `mode` — `MeshDrawMode`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_vertices(vertices: Vec<MeshVertex>, mode: MeshDrawMode) -> Self {
        log_msg!(debug, MS02, "{}", vertices.len());
        Self {
            vertices,
            indices: None,
            texture: None,
            draw_mode: mode,
        }
    }

    /// Creates a mesh from raw per-vertex float rows (x, y, u, v, r, g, b, a).
    ///
    /// # Parameters
    /// - `rows` — `&[[f32; 8]]`.
    /// - `mode` — `MeshDrawMode`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_vertex_rows(rows: &[[f32; 8]], mode: MeshDrawMode) -> Self {
        let vertices: Vec<MeshVertex> = rows
            .iter()
            .map(|r| MeshVertex {
                x: r[0],
                y: r[1],
                u: r[2],
                v: r[3],
                r: r[4],
                g: r[5],
                b: r[6],
                a: r[7],
            })
            .collect();
        Self::from_vertices(vertices, mode)
    }

    /// Sets a single vertex at the given index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    /// - `vertex` — `MeshVertex`.
    pub fn set_vertex(&mut self, index: usize, vertex: MeshVertex) {
        if index < self.vertices.len() {
            self.vertices[index] = vertex;
        }
    }

    /// Gets a vertex at the given index. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&MeshVertex>`.
    pub fn get_vertex(&self, index: usize) -> Option<&MeshVertex> {
        self.vertices.get(index)
    }

    /// Sets the index buffer for indexed drawing.
    ///
    /// # Parameters
    /// - `indices` — `Vec<u32>`.
    pub fn set_vertex_map(&mut self, indices: Vec<u32>) {
        self.indices = Some(indices);
    }

    /// Returns the number of vertices. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `usize`.
    pub fn vertex_count(&self) -> usize {
        self.vertices.len()
    }

    /// Sets the texture for this mesh. Replaces the current texture value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `texture` — `Option<TextureKey>`.
    pub fn set_texture(&mut self, texture: Option<TextureKey>) {
        self.texture = texture;
    }

    /// Sets the draw mode. Replaces the current draw mode value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `mode` — `MeshDrawMode`.
    pub fn set_draw_mode(&mut self, mode: MeshDrawMode) {
        self.draw_mode = mode;
    }

    /// Expands vertices into a list of triangle indices based on the draw mode.
    ///
    /// # Returns
    /// `Vec<usize>`.
    ///
    /// Returns indices into the vertex array forming a triangle list.
    /// Uses the index buffer if present, otherwise uses sequential vertex indices.
    pub fn triangulate(&self) -> Vec<usize> {
        let source_indices: Vec<usize> = if let Some(idx) = &self.indices {
            idx.iter().map(|i| *i as usize).collect()
        } else {
            (0..self.vertices.len()).collect()
        };

        match self.draw_mode {
            MeshDrawMode::Triangles => source_indices,
            MeshDrawMode::Fan => {
                if source_indices.len() < 3 {
                    return Vec::new();
                }
                let mut out = Vec::with_capacity((source_indices.len() - 2) * 3);
                let hub = source_indices[0];
                for i in 1..source_indices.len() - 1 {
                    out.push(hub);
                    out.push(source_indices[i]);
                    out.push(source_indices[i + 1]);
                }
                out
            }
            MeshDrawMode::Strip => {
                if source_indices.len() < 3 {
                    return Vec::new();
                }
                let mut out = Vec::with_capacity((source_indices.len() - 2) * 3);
                for i in 0..source_indices.len() - 2 {
                    if i % 2 == 0 {
                        out.push(source_indices[i]);
                        out.push(source_indices[i + 1]);
                        out.push(source_indices[i + 2]);
                    } else {
                        out.push(source_indices[i + 1]);
                        out.push(source_indices[i]);
                        out.push(source_indices[i + 2]);
                    }
                }
                out
            }
        }
    }
}
