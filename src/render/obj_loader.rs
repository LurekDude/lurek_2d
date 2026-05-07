//! Wavefront OBJ loader for Lurek2D.
//!
//! Parses `.obj` and associated `.mtl` files into an [`ObjModel`] that holds
//! the raw 3D geometry (vertices, UVs, normals, indexed faces).
//! The model can then be software-projected into a 2D [`Mesh`] for rendering
//! via the standard GPU pipeline (constraint A-03: 2D graphics only).
//!
//! # Usage (Rust)
//! ```no_run
//! let model = ObjLoader::load_file("path/to/tank.obj")?;
//! let mesh  = model.project_to_mesh(camera, screen_w, screen_h, texture_key);
//! ```
//!
//! # Usage (Lua)
//! ```lua
//! local mdl = lurek.render.loadObj("assets/models/tank.obj")
//! local mesh = mdl:projectToMesh(camera, 800, 600, texture)
//! lurek.graphic.drawMesh(mesh, x, y)
//! ```

use std::collections::HashMap;
use std::path::Path;

use crate::image::ImageData;
use crate::render::mesh::{Mesh, MeshDrawMode, MeshVertex};
use crate::runtime::resource_keys::TextureKey;

// â”€â”€ Error â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Error variants from OBJ parsing.
#[derive(Debug)]
pub enum ObjError {
    /// IO error opening or reading a file.
    Io(std::io::Error),
    /// Malformed OBJ or MTL data.
    Parse(String),
}

impl std::fmt::Display for ObjError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ObjError::Io(e) => write!(f, "OBJ IO error: {}", e),
            ObjError::Parse(s) => write!(f, "OBJ parse error: {}", s),
        }
    }
}

impl From<std::io::Error> for ObjError {
    fn from(e: std::io::Error) -> Self {
        ObjError::Io(e)
    }
}

// â”€â”€ Data types â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// A 3D Cartesian vector used for positions, directions, and normals.
#[derive(Debug, Clone, Copy)]
pub struct Vec3 {
    pub x: f32,
    pub y: f32,
    pub z: f32,
}

impl Vec3 {
/// Auto-doc: public item.
    pub fn new(x: f32, y: f32, z: f32) -> Self {
        Self { x, y, z }
    }

    /// Dot product.
    pub fn dot(self, other: Vec3) -> f32 {
        self.x * other.x + self.y * other.y + self.z * other.z
    }

    /// Length.
    pub fn len(self) -> f32 {
        (self.x * self.x + self.y * self.y + self.z * self.z).sqrt()
    }

    /// Normalise (returns zero vector on zero length).
    pub fn normalise(self) -> Vec3 {
        let l = self.len();
        if l < 1e-9 {
            Vec3::new(0.0, 0.0, 0.0)
        } else {
            Vec3::new(self.x / l, self.y / l, self.z / l)
        }
    }

    #[allow(clippy::should_implement_trait)]
/// Auto-doc: public item.
    pub fn sub(self, o: Vec3) -> Vec3 {
        Vec3::new(self.x - o.x, self.y - o.y, self.z - o.z)
    }

/// Auto-doc: public item.
    pub fn cross(self, o: Vec3) -> Vec3 {
        Vec3::new(
            self.y * o.z - self.z * o.y,
            self.z * o.x - self.x * o.z,
            self.x * o.y - self.y * o.x,
        )
    }

    #[allow(clippy::should_implement_trait)]
/// Auto-doc: public item.
    pub fn add(self, o: Vec3) -> Vec3 {
        Vec3::new(self.x + o.x, self.y + o.y, self.z + o.z)
    }

    #[allow(clippy::should_implement_trait)]
/// Auto-doc: public item.
    pub fn mul(self, s: f32) -> Vec3 {
        Vec3::new(self.x * s, self.y * s, self.z * s)
    }
}

fn rotate_y(v: Vec3, angle: f32) -> Vec3 {
    let c = angle.cos();
    let s = angle.sin();
    Vec3::new(v.x * c + v.z * s, v.y, -v.x * s + v.z * c)
}

fn edge_fn(ax: f32, ay: f32, bx: f32, by: f32, px: f32, py: f32) -> f32 {
    (px - ax) * (by - ay) - (py - ay) * (bx - ax)
}

/// A 2D texture-coordinate pair in OBJ UV space.
#[derive(Debug, Clone, Copy)]
pub struct Vec2 {
    pub u: f32,
    pub v: f32,
}

/// A single triangle face.
/// Each element is a (position_index, uv_index, normal_index) triplet (all 0-based).
#[derive(Debug, Clone)]
pub struct ObjFace {
    pub verts: [(usize, Option<usize>, Option<usize>); 3],
    /// Index into [`ObjModel::materials`]. `None` = no material assigned.
    pub material: Option<usize>,
}

/// A material parsed from an `.mtl` file.
#[derive(Debug, Clone)]
pub struct ObjMaterial {
    /// Name used in the OBJ `usemtl` directive.
    pub name: String,
    /// Diffuse colour (R, G, B).
    pub diffuse_color: [f32; 3],
    /// Diffuse texture map filename (relative path), if present.
    pub diffuse_map: Option<String>,
}

/// The complete, triangulated OBJ model.
///
/// # Fields
/// - `positions` â€” 3-D vertex positions (0-based).
/// - `uvs` â€” UV coordinates (0-based).
/// - `normals` â€” surface normals (0-based).
/// - `faces` â€” triangulated faces.
/// - `materials` â€” materials from the associated `.mtl` file.
#[derive(Debug, Clone)]
pub struct ObjModel {
    pub positions: Vec<Vec3>,
    pub uvs: Vec<Vec2>,
    pub normals: Vec<Vec3>,
    pub faces: Vec<ObjFace>,
    pub materials: Vec<ObjMaterial>,
}

impl ObjModel {
    /// Number of triangles.
    pub fn face_count(&self) -> usize {
        self.faces.len()
    }

    /// Number of position vertices.
    pub fn vertex_count(&self) -> usize {
        self.positions.len()
    }

    /// Number of UV coordinates.
    pub fn uv_count(&self) -> usize {
        self.uvs.len()
    }

    /// Number of normal vectors.
    pub fn normal_count(&self) -> usize {
        self.normals.len()
    }

    /// Software-renders the model into an RGBA image with a CPU z-buffer.
    ///
    /// This stays within the engine's 2D rendering contract: the 3D model is
    /// rasterized to a flat sprite image, which the standard renderer can then
    /// draw like any other texture. Materials currently use `Kd` diffuse color
    /// from the `.mtl` file.
    pub fn render_to_image(&self, width: u32, height: u32, rotation_quarters: u8) -> ImageData {
        let mut image = ImageData::new(width, height);
        if width == 0 || height == 0 || self.positions.is_empty() {
            return image;
        }

        let angle = (rotation_quarters % 4) as f32 * std::f32::consts::FRAC_PI_2;
        let rotated: Vec<Vec3> = self.positions.iter().copied().map(|p| rotate_y(p, angle)).collect();

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
        let radius = ((extent.x * extent.x + extent.y * extent.y + extent.z * extent.z).sqrt() * 0.5).max(0.5);

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

            let min_x = sx.iter().copied().fold(f32::INFINITY, f32::min).floor().max(0.0) as u32;
            let max_x = sx.iter().copied().fold(f32::NEG_INFINITY, f32::max).ceil().min(width as f32 - 1.0) as u32;
            let min_y = sy.iter().copied().fold(f32::INFINITY, f32::min).floor().max(0.0) as u32;
            let max_y = sy.iter().copied().fold(f32::NEG_INFINITY, f32::max).ceil().min(height as f32 - 1.0) as u32;

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

    /// Software-project the model to a flat 2-D [`Mesh`] for GPU rendering.
    ///
    /// Uses a simple perspective-projection camera:
    /// - `cam_pos` â€” camera world position (x, y, z).
    /// - `cam_target` â€” look-at point (x, y, z).
    /// - `fov_y` â€” vertical field of view in radians.
    /// - `screen_w` / `screen_h` â€” output canvas size in pixels.
    /// - `texture_key` â€” texture to apply to the mesh (or `None`).
    ///
    /// Back-face culling and simple flat-diffuse shading (normal Â· light) are
    /// applied. Triangles behind the camera or fully outside the screen are
    /// discarded.
    ///
    /// # Returns
    /// A [`Mesh`] using `MeshDrawMode::Triangles` ready for
    /// `RenderCommand::DrawMesh`.
    pub fn project_to_mesh(
        &self,
        cam_pos: Vec3,
        cam_target: Vec3,
        fov_y: f32,
        screen_w: f32,
        screen_h: f32,
        texture_key: Option<TextureKey>,
    ) -> Mesh {
        // Build view basis
        let forward = cam_target.sub(cam_pos).normalise();
        let world_up = Vec3::new(0.0, 1.0, 0.0);
        let right = forward.cross(world_up).normalise();
        let up = right.cross(forward).normalise();

        let aspect = screen_w / screen_h;
        let tan_half_fov = (fov_y * 0.5).tan();

        // Fixed light direction (from above-front)
        let light_dir = Vec3::new(0.5, 1.0, 0.7).normalise();

        // Painter order for 2D mesh draw: far triangles first, near last.
        let mut projected_tris: Vec<(f32, [MeshVertex; 3])> = Vec::with_capacity(self.faces.len());

        let near_z = 0.05_f32;
        for face in &self.faces {
            // Fetch world positions
            let wp: [Vec3; 3] = [
                self.positions[face.verts[0].0],
                self.positions[face.verts[1].0],
                self.positions[face.verts[2].0],
            ];

            // Compute face normal for back-face culling + flat shading
            let e0 = wp[1].sub(wp[0]);
            let e1 = wp[2].sub(wp[0]);
            let face_normal = e0.cross(e1).normalise();

            // View-space Z (signed distance along forward axis)
            let z0 = wp[0].sub(cam_pos).dot(forward);
            let z1 = wp[1].sub(cam_pos).dot(forward);
            let z2 = wp[2].sub(cam_pos).dot(forward);

            // Reject triangles that cross or sit behind the near plane.
            // Without clipping support, projecting such triangles creates large
            // screen-space spikes and ordering artefacts.
            if z0 <= near_z || z1 <= near_z || z2 <= near_z {
                continue;
            }

            // Back-face cull: normal should have positive z-component toward camera
            let to_cam = cam_pos.sub(wp[0]).normalise();
            if face_normal.dot(to_cam) <= 0.0 {
                continue;
            }

            // Flat diffuse shading (ambient 0.35 + diffuse)
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

            // Project each vertex
            let mut tri = [MeshVertex::default(); 3];
            for (vi, &wp_v) in wp.iter().enumerate() {
                let rel = wp_v.sub(cam_pos);
                let vz = rel.dot(forward);
                let clip_z = vz.max(0.001); // avoid division by zero

                let vx = rel.dot(right);
                let vy = rel.dot(up);

                // NDC
                let ndcx = vx / (clip_z * tan_half_fov * aspect);
                let ndcy = vy / (clip_z * tan_half_fov);

                // Screen
                let sx = (ndcx + 1.0) * 0.5 * screen_w;
                let sy = (1.0 - (ndcy + 1.0) * 0.5) * screen_h;

                // UVs
                let (u, v) = if let Some(uv_idx) = face.verts[vi].1 {
                    if let Some(uv) = self.uvs.get(uv_idx) {
                        (uv.u, 1.0 - uv.v) // OBJ v is bottom-up; flip for GPU
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

            // Painter key: furthest vertex first (more stable than average depth
            // for steeply slanted faces in this 2D mesh pipeline).
            let tri_depth = z0.max(z1).max(z2);
            projected_tris.push((tri_depth, tri));
        }

        projected_tris.sort_by(|a, b| {
            b.0.partial_cmp(&a.0)
                .unwrap_or(std::cmp::Ordering::Equal)
        });

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

    /// Project a model instance placed on world tile coordinates.
    ///
    /// The instance uses quarter-turn rotation (0..=3), uniform scale, and keeps
    /// material-based flat lighting. Returns both mesh and camera-space depth for
    /// scene sorting.
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

        projected_tris.sort_by(|a, b| {
            b.0.partial_cmp(&a.0)
                .unwrap_or(std::cmp::Ordering::Equal)
        });

        let mut vertices: Vec<MeshVertex> = Vec::with_capacity(projected_tris.len() * 3);
        for (_, tri) in projected_tris {
            vertices.push(tri[0]);
            vertices.push(tri[1]);
            vertices.push(tri[2]);
        }

        (Mesh::from_vertices(vertices, MeshDrawMode::Triangles), instance_depth)
    }
}

// â”€â”€ Loader â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Loader for Wavefront OBJ/MTL assets into the engine's in-memory model.
pub struct ObjLoader;

impl ObjLoader {
    /// Parse an OBJ file (and its `.mtl` sidecars) from the filesystem.
    ///
    /// Faces with more than 3 vertices are triangulated via a fan.
    /// Material names not found in the MTL are stored as a default entry.
    ///
    /// # Parameters
    /// - `path` â€” path to the `.obj` file.
    ///
    /// # Returns
    /// `Result<ObjModel, ObjError>`.
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
                    verts: [(a, Some(a), Some(a)), (b, Some(b), Some(b)), (c, Some(c), Some(c))],
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

    /// Parse OBJ source given as a string (e.g. from GameFS).
    ///
    /// # Parameters
    /// - `src` â€” OBJ source text.
    /// - `base_dir` â€” directory used to resolve `mtllib` references.
    ///
    /// # Returns
    /// `Result<ObjModel, ObjError>`.
    pub fn parse_obj(src: &str, base_dir: &Path) -> Result<ObjModel, ObjError> {
        let mut positions: Vec<Vec3> = Vec::new();
        let mut uvs: Vec<Vec2> = Vec::new();
        let mut normals: Vec<Vec3> = Vec::new();
        let mut faces: Vec<ObjFace> = Vec::new();
        let mut materials: Vec<ObjMaterial> = Vec::new();

        // name -> index in materials vec
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
                        let loaded =
                            Self::parse_mtl(&mtl_src, base_dir);
                        for m in loaded {
                            if !mat_index.contains_key(&m.name) {
                                mat_index.insert(m.name.clone(), materials.len());
                                materials.push(m);
                            }
                        }
                    }
                    // Non-fatal if MTL is missing
                }
                "usemtl" => {
                    current_mat = mat_index.get(rest).copied();
                }
                "f" => {
                    let verts = Self::parse_face_verts(rest, positions.len(), uvs.len(), normals.len())?;
                    // Triangulate as fan
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

    // â”€â”€ MTL parser â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

    // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    fn parse_vec3(s: &str) -> Result<Vec3, ObjError> {
        let parts = Self::split_floats(s, 3)?;
        Ok(Vec3::new(parts[0], parts[1], parts[2]))
    }

    fn split_floats(s: &str, expected: usize) -> Result<Vec<f32>, ObjError> {
        let v: Vec<f32> = s
            .split_whitespace()
            .take(expected + 4) // allow extra components
            .map(|t| {
                t.parse::<f32>().map_err(|_| {
                    ObjError::Parse(format!("expected float, got '{}'", t))
                })
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

    /// Parse face vertex references: `v`, `v/vt`, `v//vn`, `v/vt/vn` (1-based â†’ 0-based).
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

// â”€â”€ Camera helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Simple camera parameters for `project_to_mesh`.
///
/// # Fields
/// - `x` â€” Camera world X.
/// - `y` â€” Camera world Y.
/// - `z` â€” Camera world Z.
/// - `target_x` â€” Look-at X.
/// - `target_y` â€” Look-at Y.
/// - `target_z` â€” Look-at Z.
/// - `fov_y` â€” Vertical FOV in degrees.
#[derive(Debug, Clone, Copy)]
pub struct ObjCamera {
    pub x: f32,
    pub y: f32,
    pub z: f32,
    pub target_x: f32,
    pub target_y: f32,
    pub target_z: f32,
    /// Vertical FOV in degrees (converted to radians internally).
    pub fov_y_deg: f32,
}

impl ObjCamera {
/// Auto-doc: public item.
    pub fn new(x: f32, y: f32, z: f32, tx: f32, ty: f32, tz: f32, fov_y_deg: f32) -> Self {
        Self {
            x, y, z,
            target_x: tx, target_y: ty, target_z: tz,
            fov_y_deg,
        }
    }

/// Auto-doc: public item.
    pub fn to_vecs(&self) -> (Vec3, Vec3, f32) {
        (
            Vec3::new(self.x, self.y, self.z),
            Vec3::new(self.target_x, self.target_y, self.target_z),
            self.fov_y_deg.to_radians(),
        )
    }
}
