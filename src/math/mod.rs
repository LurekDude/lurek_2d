/// Bezier curve evaluation using De Casteljau's algorithm.
pub mod bezier;
/// sRGB gamma ↔ linear color space conversion.
pub mod srgb;
/// Standard easing functions for smooth animation and interpolation.
pub mod easing;
/// 2D geometry utility functions: intersections, containment, polygon ops, rasterization.
pub mod geometry;
/// 2D pathfinding grid with A*, Dijkstra, BFS, and flow field generation.
pub mod grid;
/// 3x3 column-major matrix for 2D transforms (translate, rotate, scale).
pub mod mat3;
/// 2D Perlin and Simplex noise generators for procedural content.
pub mod noise;
/// Polygon utilities: ear-clipping triangulation and convexity testing.
pub mod polygon;
/// Procedural generation: cellular automata, Voronoi, flood fill, Poisson disk, periodic noise.
pub mod procgen;
/// Seedable random number generator for reproducible sequences.
pub mod random;
/// 2D raycasting and visibility utility functions.
pub mod raycasting;
/// Axis-aligned rectangle with intersection and containment queries.
pub mod rect;
/// Spatial hash for efficient broad-phase AABB collision queries.
pub mod spatial_hash;
/// 2D affine transform with chainable methods wrapping Mat3.
pub mod transform;
/// Value interpolator with easing curves.
pub mod tween;
/// 2D floating-point vector with arithmetic operators and common helpers.
pub mod vec2;

pub use bezier::BezierCurve;
pub use geometry::*;
pub use grid::Grid;
pub use mat3::Mat3;
pub use noise::NoiseGenerator;
pub use procgen::*;
pub use random::RandomGenerator;
pub use raycasting::{RayHit, Raycaster2D, SpriteProjection};
pub use raycasting::{cast_ray_2d, distance_shade, field_of_view, project_column, Segment};
pub use rect::Rect;
pub use spatial_hash::SpatialHash;
pub use crate::tilemap::tile_walker::{Facing, TileWalker};
pub use transform::Transform;
pub use tween::{Tween, TweenValue};
pub use vec2::Vec2;
