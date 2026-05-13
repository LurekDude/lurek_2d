use crate::log_msg;
use crate::runtime::log_messages::MS01;
use crate::runtime::resource_keys::TextureKey;
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum MeshDrawMode {
    Triangles,
    Fan,
    Strip,
}
#[derive(Debug, Clone, Copy)]
pub struct MeshVertex {
    pub x: f32,
    pub y: f32,
    pub u: f32,
    pub v: f32,
    pub r: f32,
    pub g: f32,
    pub b: f32,
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
#[derive(Debug, Clone)]
pub struct Mesh {
    pub vertices: Vec<MeshVertex>,
    pub indices: Option<Vec<u32>>,
    pub texture: Option<TextureKey>,
    pub draw_mode: MeshDrawMode,
}
impl Mesh {
    pub fn new(vertex_count: usize, mode: MeshDrawMode) -> Self {
        log_msg!(trace, MS01, "{}", vertex_count);
        Self {
            vertices: vec![MeshVertex::default(); vertex_count],
            indices: None,
            texture: None,
            draw_mode: mode,
        }
    }
    pub fn from_vertices(vertices: Vec<MeshVertex>, mode: MeshDrawMode) -> Self {
        Self {
            vertices,
            indices: None,
            texture: None,
            draw_mode: mode,
        }
    }
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
    pub fn set_vertex(&mut self, index: usize, vertex: MeshVertex) {
        if index < self.vertices.len() {
            self.vertices[index] = vertex;
        }
    }
    pub fn get_vertex(&self, index: usize) -> Option<&MeshVertex> {
        self.vertices.get(index)
    }
    pub fn set_vertex_map(&mut self, indices: Vec<u32>) {
        self.indices = Some(indices);
    }
    pub fn vertex_count(&self) -> usize {
        self.vertices.len()
    }
    pub fn set_texture(&mut self, texture: Option<TextureKey>) {
        self.texture = texture;
    }
    pub fn set_draw_mode(&mut self, mode: MeshDrawMode) {
        self.draw_mode = mode;
    }
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
