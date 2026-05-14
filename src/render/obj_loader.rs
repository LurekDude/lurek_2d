//! Wavefront OBJ parser and software rasterizer for preview and mesh projection.
//! Provides `ObjLoader` (file + text parse), `ObjModel` (geometry + materials),
//! and CPU-side `render_to_image`/`project_to_mesh` helpers. Uses `tobj` for
//! file loading and a hand-written parser for in-memory text. No GPU state.

use crate::image::ImageData;
use crate::render::mesh::{Mesh, MeshDrawMode, MeshVertex};
use crate::runtime::resource_keys::TextureKey;
use std::collections::HashMap;
use std::path::Path;
/// Error returned from OBJ loading or parsing.
#[derive(Debug)]
pub enum ObjError {
    /// File I/O error.
    Io(std::io::Error),
    /// Structural parse error with a human-readable message.
    Parse(String),
}
/// Implement `Display` for `ObjError`.
impl std::fmt::Display for ObjError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ObjError::Io(e) => write!(f, "OBJ IO error: {}", e),
            ObjError::Parse(s) => write!(f, "OBJ parse error: {}", s),
        }
    }
}
/// Convert `std::io::Error` into `ObjError::Io`.
impl From<std::io::Error> for ObjError {
    fn from(e: std::io::Error) -> Self {
        ObjError::Io(e)
    }
}
/// Simple 3-D vector used for positions, normals, and scratch arithmetic during projection.
#[derive(Debug, Clone, Copy)]
pub struct Vec3 {
    /// X component.
    pub x: f32,
    /// Y component.
    pub y: f32,
    /// Z component.
    pub z: f32,
}
impl Vec3 {
    /// Construct from components.
    pub fn new(x: f32, y: f32, z: f32) -> Self {
        Self { x, y, z }
    }
    /// Return the scalar dot product of `self` and `other`.
    pub fn dot(self, other: Vec3) -> f32 {
        self.x * other.x + self.y * other.y + self.z * other.z
    }
    /// Return the Euclidean length of this vector.
    pub fn len(self) -> f32 {
        (self.x * self.x + self.y * self.y + self.z * self.z).sqrt()
    }
    /// Return a unit vector; returns zero vector when length < 1e-9.
    pub fn normalise(self) -> Vec3 {
        let l = self.len();
        if l < 1e-9 {
            Vec3::new(0.0, 0.0, 0.0)
        } else {
            Vec3::new(self.x / l, self.y / l, self.z / l)
        }
    }
    /// Return `self - o`.
    #[allow(clippy::should_implement_trait)]
    pub fn sub(self, o: Vec3) -> Vec3 {
        Vec3::new(self.x - o.x, self.y - o.y, self.z - o.z)
    }
    /// Return the cross product `self × o`.
    pub fn cross(self, o: Vec3) -> Vec3 {
        Vec3::new(
            self.y * o.z - self.z * o.y,
            self.z * o.x - self.x * o.z,
            self.x * o.y - self.y * o.x,
        )
    }
    /// Return `self + o`.
    #[allow(clippy::should_implement_trait)]
    pub fn add(self, o: Vec3) -> Vec3 {
        Vec3::new(self.x + o.x, self.y + o.y, self.z + o.z)
    }
    /// Return `self * s` (scalar multiply).
    #[allow(clippy::should_implement_trait)]
    pub fn mul(self, s: f32) -> Vec3 {
        Vec3::new(self.x * s, self.y * s, self.z * s)
    }
}
/// Rotate `v` around the world Y-axis by `angle` radians.
fn rotate_y(v: Vec3, angle: f32) -> Vec3 {
    let c = angle.cos();
    let s = angle.sin();
    Vec3::new(v.x * c + v.z * s, v.y, -v.x * s + v.z * c)
}
/// Compute a 2D edge function value used for barycentric rasterization.
fn edge_fn(ax: f32, ay: f32, bx: f32, by: f32, px: f32, py: f32) -> f32 {
    (px - ax) * (by - ay) - (py - ay) * (bx - ax)
}
/// 2D texture coordinate, `u` and `v`.
#[derive(Debug, Clone, Copy)]
pub struct Vec2 {
    /// Horizontal UV component.
    pub u: f32,
    /// Vertical UV component.
    pub v: f32,
}
/// One triangulated OBJ face with per-vertex position/UV/normal indices and an optional material.
#[derive(Debug, Clone)]
pub struct ObjFace {
    /// Per-vertex `(position_idx, uv_idx, normal_idx)` tuples.
    pub verts: [(usize, Option<usize>, Option<usize>); 3],
    /// Index into `ObjModel::materials`, or `None` for default material.
    pub material: Option<usize>,
}
/// A named material from an MTL file with diffuse colour and optional diffuse texture path.
#[derive(Debug, Clone)]
pub struct ObjMaterial {
    /// Material name as declared in the MTL file.
    pub name: String,
    /// Linear RGB diffuse colour; default `[1.0, 1.0, 1.0]` (white).
    pub diffuse_color: [f32; 3],
    /// Optional relative path to the diffuse texture image.
    pub diffuse_map: Option<String>,
}
/// A parsed OBJ model: vertex positions, UVs, normals, faces, and materials.
#[derive(Debug, Clone)]
pub struct ObjModel {
    /// Vertex positions in local space.
    pub positions: Vec<Vec3>,
    /// UV coordinates indexed by face vertex tuples.
    pub uvs: Vec<Vec2>,
    /// Vertex normals indexed by face vertex tuples.
    pub normals: Vec<Vec3>,
    /// Triangulated faces with per-vertex index tuples.
    pub faces: Vec<ObjFace>,
    /// Materials from `.mtl` file or inline MTL declarations.
    pub materials: Vec<ObjMaterial>,
}
impl ObjModel {
    /// Return the number of triangles in this model.
    pub fn face_count(&self) -> usize {
        self.faces.len()
    }
    /// Return the number of vertex positions in this model.
    pub fn vertex_count(&self) -> usize {
        self.positions.len()
    }
    /// Return the number of UV entries in this model.
    pub fn uv_count(&self) -> usize {
        self.uvs.len()
    }
    /// Return the number of normal entries in this model.
    pub fn normal_count(&self) -> usize {
        self.normals.len()
    }
    /// CPU-rasterize the model into an `ImageData` with a virtual camera, Y-rotation, and a key light.
    pub fn render_to_image(&self, width: u32, height: u32, rotation_quarters: u8) -> ImageData {
        let mut image = ImageData::new(width, height);
        if width == 0 || height == 0 || self.positions.is_empty() {
            return image;
        }
        let angle = (rotation_quarters % 4) as f32 * std::f32::consts::FRAC_PI_2;
        let rotated: Vec<Vec3> = self
            .positions
            .iter()
            .copied()
            .map(|p| rotate_y(p, angle))
            .collect();
        let mut min = Vec3::new(f32::INFINITY, f32::INFINITY, f32::INFINITY);
        let mut max = Vec3::new(f32::NEG_INFINITY, f32::NEG_INFINITY, f32::NEG_INFINITY);
        for p in &rotated {
            min.x = min.x.min(p.x);
            min.y = min.y.min(p.y);
            min.z = min.z.min(p.z);
            max.x = max.x.max(p.x);
            max.y = max.y.max(p.y);
            max.z = max.z.max(p.z);
        }
        let center = Vec3::new(
            (min.x + max.x) * 0.5,
            (min.y + max.y) * 0.5,
            (min.z + max.z) * 0.5,
        );
        let extent = Vec3::new(max.x - min.x, max.y - min.y, max.z - min.z);
        let radius = ((extent.x * extent.x + extent.y * extent.y + extent.z * extent.z).sqrt()
            * 0.5)
            .max(0.5);
        let cam_pos = center.add(Vec3::new(radius * 1.2, radius * 0.8, radius * 2.4));
        let cam_target = center.add(Vec3::new(0.0, extent.y * 0.15, 0.0));
        let forward = cam_target.sub(cam_pos).normalise();
        let world_up = Vec3::new(0.0, 1.0, 0.0);
        let right = forward.cross(world_up).normalise();
        let up = right.cross(forward).normalise();
        let fov_y = 50.0_f32.to_radians();
        let tan_half_fov = (fov_y * 0.5).tan();
        let aspect = width as f32 / height as f32;
        let near_z = 0.05_f32;
        let light_dir = Vec3::new(0.45, 0.90, 0.55).normalise();
        let mut zbuf = vec![f32::INFINITY; (width * height) as usize];
        for face in &self.faces {
            let wp = [
                rotated[face.verts[0].0],
                rotated[face.verts[1].0],
                rotated[face.verts[2].0],
            ];
            let e0 = wp[1].sub(wp[0]);
            let e1 = wp[2].sub(wp[0]);
            let face_normal = e0.cross(e1).normalise();
            let to_cam = cam_pos.sub(wp[0]).normalise();
            if face_normal.dot(to_cam) <= 0.0 {
                continue;
            }
            let z0 = wp[0].sub(cam_pos).dot(forward);
            let z1 = wp[1].sub(cam_pos).dot(forward);
            let z2 = wp[2].sub(cam_pos).dot(forward);
            if z0 <= near_z || z1 <= near_z || z2 <= near_z {
                continue;
            }
            let mut sx = [0.0_f32; 3];
            let mut sy = [0.0_f32; 3];
            for i in 0..3 {
                let rel = wp[i].sub(cam_pos);
                let vz = rel.dot(forward);
                let vx = rel.dot(right);
                let vy = rel.dot(up);
                let ndcx = vx / (vz * tan_half_fov * aspect);
                let ndcy = vy / (vz * tan_half_fov);
                sx[i] = (ndcx + 1.0) * 0.5 * width as f32;
                sy[i] = (1.0 - (ndcy + 1.0) * 0.5) * height as f32;
            }
            let area = edge_fn(sx[0], sy[0], sx[1], sy[1], sx[2], sy[2]);
            if area.abs() < 1e-4 {
                continue;
            }
            let ndotl = face_normal.dot(light_dir).max(0.0);
            let shade = 0.28 + 0.72 * ndotl;
            let (r, g, b) = if let Some(mat_idx) = face.material {
                if let Some(mat) = self.materials.get(mat_idx) {
                    (
                        (mat.diffuse_color[0] * shade * 255.0).clamp(0.0, 255.0) as u8,
                        (mat.diffuse_color[1] * shade * 255.0).clamp(0.0, 255.0) as u8,
                        (mat.diffuse_color[2] * shade * 255.0).clamp(0.0, 255.0) as u8,
                    )
                } else {
                    let c = (shade * 255.0).clamp(0.0, 255.0) as u8;
                    (c, c, c)
                }
            } else {
                let c = (shade * 255.0).clamp(0.0, 255.0) as u8;
                (c, c, c)
            };
            let min_x = sx
                .iter()
                .copied()
                .fold(f32::INFINITY, f32::min)
                .floor()
                .max(0.0) as u32;
            let max_x = sx
                .iter()
                .copied()
                .fold(f32::NEG_INFINITY, f32::max)
                .ceil()
                .min(width as f32 - 1.0) as u32;
            let min_y = sy
                .iter()
                .copied()
                .fold(f32::INFINITY, f32::min)
                .floor()
                .max(0.0) as u32;
            let max_y = sy
                .iter()
                .copied()
                .fold(f32::NEG_INFINITY, f32::max)
                .ceil()
                .min(height as f32 - 1.0) as u32;
            for py in min_y..=max_y {
                for px in min_x..=max_x {
                    let fx = px as f32 + 0.5;
                    let fy = py as f32 + 0.5;
                    let w0 = edge_fn(sx[1], sy[1], sx[2], sy[2], fx, fy) / area;
                    let w1 = edge_fn(sx[2], sy[2], sx[0], sy[0], fx, fy) / area;
                    let w2 = edge_fn(sx[0], sy[0], sx[1], sy[1], fx, fy) / area;
                    if w0 < 0.0 || w1 < 0.0 || w2 < 0.0 {
                        continue;
                    }
                    let depth = w0 * z0 + w1 * z1 + w2 * z2;
                    let idx = (py * width + px) as usize;
                    if depth >= zbuf[idx] {
                        continue;
                    }
                    zbuf[idx] = depth;
                    image.set_pixel(px, py, r, g, b, 255);
                }
            }
        }
        image
    }
    /// Project the model from `cam_pos`/`cam_target` into a `Mesh` sorted back-to-front.
    pub fn project_to_mesh(
        &self,
        cam_pos: Vec3,
        cam_target: Vec3,
        fov_y: f32,
        screen_w: f32,
        screen_h: f32,
        texture_key: Option<TextureKey>,
    ) -> Mesh {
        let forward = cam_target.sub(cam_pos).normalise();
        let world_up = Vec3::new(0.0, 1.0, 0.0);
        let right = forward.cross(world_up).normalise();
        let up = right.cross(forward).normalise();
        let aspect = screen_w / screen_h;
        let tan_half_fov = (fov_y * 0.5).tan();
        let light_dir = Vec3::new(0.5, 1.0, 0.7).normalise();
        let mut projected_tris: Vec<(f32, [MeshVertex; 3])> = Vec::with_capacity(self.faces.len());
        let near_z = 0.05_f32;
        for face in &self.faces {
            let wp: [Vec3; 3] = [
                self.positions[face.verts[0].0],
                self.positions[face.verts[1].0],
                self.positions[face.verts[2].0],
            ];
            let e0 = wp[1].sub(wp[0]);
            let e1 = wp[2].sub(wp[0]);
            let face_normal = e0.cross(e1).normalise();
            let z0 = wp[0].sub(cam_pos).dot(forward);
            let z1 = wp[1].sub(cam_pos).dot(forward);
            let z2 = wp[2].sub(cam_pos).dot(forward);
            if z0 <= near_z || z1 <= near_z || z2 <= near_z {
                continue;
            }
            let to_cam = cam_pos.sub(wp[0]).normalise();
            if face_normal.dot(to_cam) <= 0.0 {
                continue;
            }
            let ndotl = face_normal.dot(light_dir).max(0.0);
            let shade = 0.35 + 0.65 * ndotl;
            let (r, g, b) = if let Some(mat_idx) = face.material {
                if let Some(mat) = self.materials.get(mat_idx) {
                    (
                        mat.diffuse_color[0] * shade,
                        mat.diffuse_color[1] * shade,
                        mat.diffuse_color[2] * shade,
                    )
                } else {
                    (shade, shade, shade)
                }
            } else {
                (shade, shade, shade)
            };
            let mut tri = [MeshVertex::default(); 3];
            for (vi, &wp_v) in wp.iter().enumerate() {
                let rel = wp_v.sub(cam_pos);
                let vz = rel.dot(forward);
                let clip_z = vz.max(0.001);
                let vx = rel.dot(right);
                let vy = rel.dot(up);
                let ndcx = vx / (clip_z * tan_half_fov * aspect);
                let ndcy = vy / (clip_z * tan_half_fov);
                let sx = (ndcx + 1.0) * 0.5 * screen_w;
                let sy = (1.0 - (ndcy + 1.0) * 0.5) * screen_h;
                let (u, v) = if let Some(uv_idx) = face.verts[vi].1 {
                    if let Some(uv) = self.uvs.get(uv_idx) {
                        (uv.u, 1.0 - uv.v)
                    } else {
                        (0.0, 0.0)
                    }
                } else {
                    (0.0, 0.0)
                };
                tri[vi] = MeshVertex {
                    x: sx,
                    y: sy,
                    u,
                    v,
                    r: r.min(1.0),
                    g: g.min(1.0),
                    b: b.min(1.0),
                    a: 1.0,
                };
            }
            let tri_depth = z0.max(z1).max(z2);
            projected_tris.push((tri_depth, tri));
        }
        projected_tris.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));
        let mut vertices: Vec<MeshVertex> = Vec::with_capacity(projected_tris.len() * 3);
        for (_, tri) in projected_tris {
            vertices.push(tri[0]);
            vertices.push(tri[1]);
            vertices.push(tri[2]);
        }
        let mut mesh = Mesh::from_vertices(vertices, MeshDrawMode::Triangles);
        mesh.texture = texture_key;
        mesh
    }
    /// Project a single world-space instance with Y-rotation and uniform scale; return `(Mesh, depth)`.
    #[allow(clippy::too_many_arguments)]
    pub fn project_instance_to_mesh(
        &self,
        cam_pos: Vec3,
        cam_target: Vec3,
        fov_y: f32,
        screen_w: f32,
        screen_h: f32,
        world_x: f32,
        world_y: f32,
        rotation_quarters: u8,
        scale: f32,
    ) -> (Mesh, f32) {
        let forward = cam_target.sub(cam_pos).normalise();
        let world_up = Vec3::new(0.0, 1.0, 0.0);
        let right = forward.cross(world_up).normalise();
        let up = right.cross(forward).normalise();
        let aspect = screen_w / screen_h;
        let tan_half_fov = (fov_y * 0.5).tan();
        let light_dir = Vec3::new(0.5, 1.0, 0.7).normalise();
        let near_z = 0.05_f32;
        let rot = (rotation_quarters % 4) as f32 * std::f32::consts::FRAC_PI_2;
        let c = rot.cos();
        let s = rot.sin();
        let mut projected_tris: Vec<(f32, [MeshVertex; 3])> = Vec::with_capacity(self.faces.len());
        let mut min_x = f32::INFINITY;
        let mut max_x = f32::NEG_INFINITY;
        let mut min_y = f32::INFINITY;
        let mut min_z = f32::INFINITY;
        let mut max_z = f32::NEG_INFINITY;
        for p in &self.positions {
            min_x = min_x.min(p.x);
            max_x = max_x.max(p.x);
            min_y = min_y.min(p.y);
            min_z = min_z.min(p.z);
            max_z = max_z.max(p.z);
        }
        let center_x = (min_x + max_x) * 0.5;
        let center_z = (min_z + max_z) * 0.5;
        let base_y = min_y;
        let mut instance_depth = f32::INFINITY;
        for face in &self.faces {
            let wp = face.verts.map(|v| {
                let p = self.positions[v.0];
                let px = (p.x - center_x) * scale;
                let py = (p.y - base_y) * scale;
                let pz = (p.z - center_z) * scale;
                let rx = px * c + pz * s;
                let rz = -px * s + pz * c;
                Vec3::new(world_x + rx, py, world_y + rz)
            });
            let e0 = wp[1].sub(wp[0]);
            let e1 = wp[2].sub(wp[0]);
            let face_normal = e0.cross(e1).normalise();
            let z0 = wp[0].sub(cam_pos).dot(forward);
            let z1 = wp[1].sub(cam_pos).dot(forward);
            let z2 = wp[2].sub(cam_pos).dot(forward);
            if z0 <= near_z || z1 <= near_z || z2 <= near_z {
                continue;
            }
            let to_cam = cam_pos.sub(wp[0]).normalise();
            if face_normal.dot(to_cam) <= 0.0 {
                continue;
            }
            let ndotl = face_normal.dot(light_dir).max(0.0);
            let shade = 0.35 + 0.65 * ndotl;
            let (r, g, b) = if let Some(mat_idx) = face.material {
                if let Some(mat) = self.materials.get(mat_idx) {
                    (
                        mat.diffuse_color[0] * shade,
                        mat.diffuse_color[1] * shade,
                        mat.diffuse_color[2] * shade,
                    )
                } else {
                    (shade, shade, shade)
                }
            } else {
                (shade, shade, shade)
            };
            let mut tri = [MeshVertex::default(); 3];
            for (vi, &wp_v) in wp.iter().enumerate() {
                let rel = wp_v.sub(cam_pos);
                let vz = rel.dot(forward);
                let clip_z = vz.max(0.001);
                let vx = rel.dot(right);
                let vy = rel.dot(up);
                let ndcx = vx / (clip_z * tan_half_fov * aspect);
                let ndcy = vy / (clip_z * tan_half_fov);
                let sx = (ndcx + 1.0) * 0.5 * screen_w;
                let sy = (1.0 - (ndcy + 1.0) * 0.5) * screen_h;
                let (u, v) = if let Some(uv_idx) = face.verts[vi].1 {
                    if let Some(uv) = self.uvs.get(uv_idx) {
                        (uv.u, 1.0 - uv.v)
                    } else {
                        (0.0, 0.0)
                    }
                } else {
                    (0.0, 0.0)
                };
                tri[vi] = MeshVertex {
                    x: sx,
                    y: sy,
                    u,
                    v,
                    r: r.min(1.0),
                    g: g.min(1.0),
                    b: b.min(1.0),
                    a: 1.0,
                };
            }
            let tri_depth = z0.max(z1).max(z2);
            instance_depth = instance_depth.min((z0 + z1 + z2) / 3.0);
            projected_tris.push((tri_depth, tri));
        }
        projected_tris.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));
        let mut vertices: Vec<MeshVertex> = Vec::with_capacity(projected_tris.len() * 3);
        for (_, tri) in projected_tris {
            vertices.push(tri[0]);
            vertices.push(tri[1]);
            vertices.push(tri[2]);
        }
        (
            Mesh::from_vertices(vertices, MeshDrawMode::Triangles),
            instance_depth,
        )
    }
}
/// Stateless parser wrapper for Wavefront OBJ files.
pub struct ObjLoader;
impl ObjLoader {
    /// Load and triangulate an OBJ file from `path`, using `tobj`; return error on I/O or parse failure.
    pub fn load_file(path: impl AsRef<Path>) -> Result<ObjModel, ObjError> {
        let path = path.as_ref();
        let (models, materials_result) = tobj::load_obj(
            path,
            &tobj::LoadOptions {
                triangulate: true,
                single_index: true,
                ignore_lines: true,
                ignore_points: true,
            },
        )
        .map_err(|e| ObjError::Parse(format!("tobj load failed: {e}")))?;
        let materials_raw = materials_result.unwrap_or_default();
        let mut materials = Vec::with_capacity(materials_raw.len());
        for mat in materials_raw {
            let kd = mat.diffuse.unwrap_or([1.0, 1.0, 1.0]);
            materials.push(ObjMaterial {
                name: mat.name,
                diffuse_color: kd,
                diffuse_map: mat.diffuse_texture,
            });
        }
        let mut positions = Vec::new();
        let mut uvs = Vec::new();
        let mut normals = Vec::new();
        let mut faces = Vec::new();
        for model in models {
            let mesh = model.mesh;
            let base_pos = positions.len();
            let vcount = mesh.positions.len() / 3;
            for i in 0..vcount {
                positions.push(Vec3::new(
                    mesh.positions[i * 3],
                    mesh.positions[i * 3 + 1],
                    mesh.positions[i * 3 + 2],
                ));
                if mesh.texcoords.len() >= (i + 1) * 2 {
                    uvs.push(Vec2 {
                        u: mesh.texcoords[i * 2],
                        v: mesh.texcoords[i * 2 + 1],
                    });
                } else {
                    uvs.push(Vec2 { u: 0.0, v: 0.0 });
                }
                if mesh.normals.len() >= (i + 1) * 3 {
                    normals.push(Vec3::new(
                        mesh.normals[i * 3],
                        mesh.normals[i * 3 + 1],
                        mesh.normals[i * 3 + 2],
                    ));
                } else {
                    normals.push(Vec3::new(0.0, 1.0, 0.0));
                }
            }
            for tri in mesh.indices.chunks_exact(3) {
                let a = base_pos + tri[0] as usize;
                let b = base_pos + tri[1] as usize;
                let c = base_pos + tri[2] as usize;
                let material = mesh.material_id;
                faces.push(ObjFace {
                    verts: [
                        (a, Some(a), Some(a)),
                        (b, Some(b), Some(b)),
                        (c, Some(c), Some(c)),
                    ],
                    material,
                });
            }
        }
        Ok(ObjModel {
            positions,
            uvs,
            normals,
            faces,
            materials,
        })
    }
    /// Parse OBJ + MTL text in memory, resolving `mtllib` paths relative to `base_dir`.
    pub fn parse_obj(src: &str, base_dir: &Path) -> Result<ObjModel, ObjError> {
        let mut positions: Vec<Vec3> = Vec::new();
        let mut uvs: Vec<Vec2> = Vec::new();
        let mut normals: Vec<Vec3> = Vec::new();
        let mut faces: Vec<ObjFace> = Vec::new();
        let mut materials: Vec<ObjMaterial> = Vec::new();
        let mut mat_index: HashMap<String, usize> = HashMap::new();
        let mut current_mat: Option<usize> = None;
        for line in src.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            let mut tokens = line.splitn(2, char::is_whitespace);
            let keyword = tokens.next().unwrap_or("");
            let rest = tokens.next().unwrap_or("").trim();
            match keyword {
                "v" => {
                    let p = Self::parse_vec3(rest)?;
                    positions.push(p);
                }
                "vt" => {
                    let parts = Self::split_floats(rest, 2)?;
                    uvs.push(Vec2 {
                        u: parts[0],
                        v: parts[1],
                    });
                }
                "vn" => {
                    let p = Self::parse_vec3(rest)?;
                    normals.push(p);
                }
                "mtllib" => {
                    let mtl_path = base_dir.join(rest);
                    if let Ok(mtl_src) = std::fs::read_to_string(&mtl_path) {
                        let loaded = Self::parse_mtl(&mtl_src, base_dir);
                        for m in loaded {
                            if !mat_index.contains_key(&m.name) {
                                mat_index.insert(m.name.clone(), materials.len());
                                materials.push(m);
                            }
                        }
                    }
                }
                "usemtl" => {
                    current_mat = mat_index.get(rest).copied();
                }
                "f" => {
                    let verts =
                        Self::parse_face_verts(rest, positions.len(), uvs.len(), normals.len())?;
                    for i in 1..(verts.len() - 1) {
                        faces.push(ObjFace {
                            verts: [verts[0], verts[i], verts[i + 1]],
                            material: current_mat,
                        });
                    }
                }
                _ => {}
            }
        }
        Ok(ObjModel {
            positions,
            uvs,
            normals,
            faces,
            materials,
        })
    }
    /// Parse MTL text; extract `newmtl`, `Kd`, and `map_Kd` entries into `ObjMaterial` list.
    fn parse_mtl(src: &str, _base_dir: &Path) -> Vec<ObjMaterial> {
        let mut out: Vec<ObjMaterial> = Vec::new();
        let mut current: Option<ObjMaterial> = None;
        for line in src.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            let mut tokens = line.splitn(2, char::is_whitespace);
            let keyword = tokens.next().unwrap_or("");
            let rest = tokens.next().unwrap_or("").trim();
            match keyword {
                "newmtl" => {
                    if let Some(m) = current.take() {
                        out.push(m);
                    }
                    current = Some(ObjMaterial {
                        name: rest.to_owned(),
                        diffuse_color: [1.0, 1.0, 1.0],
                        diffuse_map: None,
                    });
                }
                "Kd" => {
                    if let Some(m) = current.as_mut() {
                        if let Ok(parts) = Self::split_floats(rest, 3) {
                            m.diffuse_color = [parts[0], parts[1], parts[2]];
                        }
                    }
                }
                "map_Kd" => {
                    if let Some(m) = current.as_mut() {
                        m.diffuse_map = Some(rest.to_owned());
                    }
                }
                _ => {}
            }
        }
        if let Some(m) = current {
            out.push(m);
        }
        out
    }
    /// Parse `s` as three whitespace-separated floats into a `Vec3`; return error on bad input.
    fn parse_vec3(s: &str) -> Result<Vec3, ObjError> {
        let parts = Self::split_floats(s, 3)?;
        Ok(Vec3::new(parts[0], parts[1], parts[2]))
    }
    /// Split `s` into at least `expected` floats; return error when fewer are found.
    fn split_floats(s: &str, expected: usize) -> Result<Vec<f32>, ObjError> {
        let v: Vec<f32> = s
            .split_whitespace()
            .take(expected + 4)
            .map(|t| {
                t.parse::<f32>()
                    .map_err(|_| ObjError::Parse(format!("expected float, got '{}'", t)))
            })
            .collect::<Result<_, _>>()?;
        if v.len() < expected {
            return Err(ObjError::Parse(format!(
                "expected {} floats, got {} in '{}'",
                expected,
                v.len(),
                s
            )));
        }
        Ok(v)
    }
    /// Parse a whitespace-delimited face vertex string into `(pos, uv, normal)` index triples.
    #[allow(clippy::type_complexity)]
    fn parse_face_verts(
        s: &str,
        pos_count: usize,
        uv_count: usize,
        norm_count: usize,
    ) -> Result<Vec<(usize, Option<usize>, Option<usize>)>, ObjError> {
        let mut out = Vec::new();
        for token in s.split_whitespace() {
            let mut parts = token.split('/');
            let pi = Self::parse_index(parts.next(), pos_count)?;
            let ti = Self::parse_index_opt(parts.next(), uv_count);
            let ni = Self::parse_index_opt(parts.next(), norm_count);
            out.push((pi, ti, ni));
        }
        if out.len() < 3 {
            return Err(ObjError::Parse(format!(
                "face has only {} vertices (need >= 3): '{}'",
                out.len(),
                s
            )));
        }
        Ok(out)
    }
    /// Resolve an OBJ 1-based or negative index into a 0-based index; return error when `s` is empty.
    fn parse_index(s: Option<&str>, count: usize) -> Result<usize, ObjError> {
        match s {
            None | Some("") => Err(ObjError::Parse("missing face index".into())),
            Some(t) => {
                let i: i32 = t
                    .parse()
                    .map_err(|_| ObjError::Parse(format!("bad index '{}'", t)))?;
                let idx = if i < 0 {
                    (count as i32 + i) as usize
                } else {
                    (i - 1) as usize
                };
                Ok(idx)
            }
        }
    }
    /// Like `parse_index` but return `None` for empty or missing tokens.
    fn parse_index_opt(s: Option<&str>, count: usize) -> Option<usize> {
        match s {
            None | Some("") => None,
            Some(t) => {
                let i: i32 = t.parse().ok()?;
                let idx = if i < 0 {
                    (count as i32 + i) as usize
                } else {
                    (i - 1) as usize
                };
                Some(idx)
            }
        }
    }
}
/// Perspective camera description for `ObjModel::project_to_mesh`.
#[derive(Debug, Clone, Copy)]
pub struct ObjCamera {
    /// Camera X position in world space.
    pub x: f32,
    /// Camera Y position in world space.
    pub y: f32,
    /// Camera Z position in world space.
    pub z: f32,
    /// Lookat target X.
    pub target_x: f32,
    /// Lookat target Y.
    pub target_y: f32,
    /// Lookat target Z.
    pub target_z: f32,
    /// Vertical field of view in degrees.
    pub fov_y_deg: f32,
}
impl ObjCamera {
    /// Construct a camera from position, target, and FOV.
    pub fn new(x: f32, y: f32, z: f32, tx: f32, ty: f32, tz: f32, fov_y_deg: f32) -> Self {
        Self {
            x,
            y,
            z,
            target_x: tx,
            target_y: ty,
            target_z: tz,
            fov_y_deg,
        }
    }
    /// Return `(cam_pos, cam_target, fov_y_rad)` unpacked as `Vec3` values.
    pub fn to_vecs(&self) -> (Vec3, Vec3, f32) {
        (
            Vec3::new(self.x, self.y, self.z),
            Vec3::new(self.target_x, self.target_y, self.target_z),
            self.fov_y_deg.to_radians(),
        )
    }
}
