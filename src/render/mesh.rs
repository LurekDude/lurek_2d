//! CPU-side mesh geometry: vertex list, optional index buffer, texture binding,
//! and draw-mode for Triangles/Fan/Strip. Consumed by `GpuRenderer::render_frame`
//! via `RenderCommand::DrawMesh`. Does not hold GPU buffers.

use crate::log_msg;
use crate::runtime::log_messages::MS01;
use crate::runtime::resource_keys::TextureKey;
/// Triangle topology when submitting a `Mesh` to the GPU.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum MeshDrawMode {
    /// Interpret every three indices as an independent triangle.
    Triangles,
    /// Treat indices as a triangle fan around the first vertex.
    Fan,
    /// Treat indices as a triangle strip.
    Strip,
}
/// A single mesh vertex: 2D position, UV, and RGBA color.
#[derive(Debug, Clone, Copy)]
pub struct MeshVertex {
    /// X screen or world coordinate.
    pub x: f32,
    /// Y screen or world coordinate.
    pub y: f32,
    /// Texture U coordinate, 0.0..1.0.
    pub u: f32,
    /// Texture V coordinate, 0.0..1.0.
    pub v: f32,
    /// Red channel, 0.0..1.0.
    pub r: f32,
    /// Green channel, 0.0..1.0.
    pub g: f32,
    /// Blue channel, 0.0..1.0.
    pub b: f32,
    /// Alpha channel, 0.0..1.0.
    pub a: f32,
}
/// Provide `Default` for `MeshVertex`.
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
/// A drawable 2D geometry object built from `MeshVertex` data.
#[derive(Debug, Clone)]
pub struct Mesh {
    /// All vertices in the mesh.
    pub vertices: Vec<MeshVertex>,
    /// Optional index list; when `None`, vertices are drawn in order.
    pub indices: Option<Vec<u32>>,
    /// Optional texture bound for all draw calls on this mesh.
    pub texture: Option<TextureKey>,
    /// Triangle topology used when submitting this mesh to the GPU.
    pub draw_mode: MeshDrawMode,
}
impl Mesh {
    /// Allocate a mesh of `vertex_count` default-white vertices in the given draw mode.
    pub fn new(vertex_count: usize, mode: MeshDrawMode) -> Self {
        log_msg!(trace, MS01, "{}", vertex_count);
        Self {
            vertices: vec![MeshVertex::default(); vertex_count],
            indices: None,
            texture: None,
            draw_mode: mode,
        }
    }
    /// Create a mesh directly from an existing `Vec<MeshVertex>` without index reuse.
    pub fn from_vertices(vertices: Vec<MeshVertex>, mode: MeshDrawMode) -> Self {
        Self {
            vertices,
            indices: None,
            texture: None,
            draw_mode: mode,
        }
    }
    /// Build a mesh from a slice of `[x, y, u, v, r, g, b, a]` row arrays.
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
    /// Set the vertex at `index`; silently ignored when `index` is out of bounds.
    pub fn set_vertex(&mut self, index: usize, vertex: MeshVertex) {
        if index < self.vertices.len() {
            self.vertices[index] = vertex;
        }
    }
    /// Return a reference to the vertex at `index`, or `None` when out of bounds.
    pub fn get_vertex(&self, index: usize) -> Option<&MeshVertex> {
        self.vertices.get(index)
    }
    /// Replace the index buffer with `indices`.
    pub fn set_vertex_map(&mut self, indices: Vec<u32>) {
        self.indices = Some(indices);
    }
    /// Return the number of vertices in this mesh.
    pub fn vertex_count(&self) -> usize {
        self.vertices.len()
    }
    /// Bind or unbind a texture for subsequent draw calls on this mesh.
    pub fn set_texture(&mut self, texture: Option<TextureKey>) {
        self.texture = texture;
    }
    /// Change the triangle topology for this mesh.
    pub fn set_draw_mode(&mut self, mode: MeshDrawMode) {
        self.draw_mode = mode;
    }
    /// Return a flat list of vertex indices expanding Fan/Strip and indexed modes into independent triangles.
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
