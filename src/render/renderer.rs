//! - Defines the `RenderCommand` enum — the complete vocabulary of draw, state, and control operations submitted each frame.
//! - Provides blend, stencil, and depth mode enums for compositing and test configuration.
//! - Contains text alignment and draw-mode enums shared across shape, font, and path rendering.
//! - Houses post-processing pass descriptors and rich-text span types.
//! - Declares particle instance and render-shape types for the particle system pipeline.
//! - Includes physics debug shape and config records for collider overlay rendering.
//! - Provides path-segment, gradient, hex, bevel, and nine-slice draw primitives.
//! - Defines Spine slot draw records, sort-group markers, and compositing layer commands.
//! - Supplies `TextureData` for CPU-to-GPU texture uploads and `DrawableKind` for generic draw utilities.

use crate::math::Vec2;
use crate::render::image_effect::ShaderPassDescriptor;
use crate::render::mesh::Mesh;
use crate::runtime::resource_keys::{
    CanvasKey, FontKey, MeshKey, ShaderKey, ShapeKey, SpriteBatchKey, TextureKey,
};
use std::collections::HashMap;
/// Depth comparison function for stencil and depth-buffer tests.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum CompareMode {
    /// Pass only when values are equal.
    Equal,
    /// Pass only when values differ.
    NotEqual,
    /// Pass when incoming < stored.
    Less,
    /// Pass when incoming <= stored.
    LessEqual,
    /// Pass when incoming > stored.
    Greater,
    /// Pass when incoming >= stored.
    GreaterEqual,
    /// Always pass.
    Always,
    /// Always fail.
    Never,
}
/// Stencil-buffer write operation applied when a stencil test passes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum StencilAction {
    /// Leave current value unchanged.
    Keep,
    /// Write zero.
    Zero,
    /// Write the reference value.
    Replace,
    /// Clamp-increment the current value.
    Increment,
    /// Clamp-decrement the current value.
    Decrement,
    /// Wrap-increment the current value.
    IncrementWrap,
    /// Wrap-decrement the current value.
    DecrementWrap,
    /// Bitwise-invert the current value.
    Invert,
}
/// Combined stencil action, comparison, and reference value for one draw call.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct StencilMode {
    /// How to update the stencil buffer on pass.
    pub action: StencilAction,
    /// Comparison used to test each fragment.
    pub compare: CompareMode,
    /// Reference value compared against the stencil buffer.
    pub value: u8,
}
/// Provide a no-op `Default` for `StencilMode` (Keep / Always / 0).
impl Default for StencilMode {
    fn default() -> Self {
        Self {
            action: StencilAction::Keep,
            compare: CompareMode::Always,
            value: 0,
        }
    }
}
/// Depth comparison mode for draw calls that use a depth buffer.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum DepthMode {
    /// Always pass depth test (default).
    #[default]
    Always,
    /// Always fail depth test.
    Never,
    /// Pass when incoming < stored depth.
    Less,
    /// Pass when incoming <= stored depth.
    LessEqual,
    /// Pass when incoming == stored depth.
    Equal,
    /// Pass when incoming != stored depth.
    NotEqual,
    /// Pass when incoming > stored depth.
    Greater,
    /// Pass when incoming >= stored depth.
    GreaterEqual,
}
/// Horizontal text alignment within a layout box.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TextAlign {
    /// Align text to the left edge.
    Left,
    /// Center text horizontally.
    Center,
    /// Align text to the right edge.
    Right,
    /// Stretch text across the full width.
    Justify,
}
/// Filled vs outlined draw mode for shapes.
#[derive(Debug, Clone)]
pub enum DrawMode {
    /// Draw as a solid filled shape.
    Fill,
    /// Draw as an outline only.
    Line,
}
/// Compositing blend mode applied when drawing to the current render target.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum BlendMode {
    /// Standard premultiplied alpha blend (default).
    #[default]
    Alpha,
    /// Additive blend — adds source and destination.
    Add,
    /// Multiplicative blend.
    Multiply,
    /// Overwrite destination with no alpha blend.
    Replace,
    /// Screen blend — 1 - (1-src)*(1-dst).
    Screen,
}
/// One named post-processing pass with a parameter map and optional custom shader ID.
#[derive(Debug, Clone)]
pub struct PostFxPass {
    /// Name of the built-in or custom registered effect.
    pub effect_name: String,
    /// Float parameter map forwarded to the WGSL uniform buffer.
    pub params: HashMap<String, f32>,
    /// Optional custom shader registration ID; `None` uses a built-in.
    pub shader_id: Option<usize>,
    /// When `true`, auto-fill time, frame, and viewport params into the uniform.
    pub auto_uniforms: bool,
}
/// A single span within a rich-text draw call, carrying its own color and scale.
#[derive(Debug, Clone)]
pub struct TextSpan {
    /// Span content.
    pub text: String,
    /// Red channel, 0..255.
    pub r: u8,
    /// Green channel, 0..255.
    pub g: u8,
    /// Blue channel, 0..255.
    pub b: u8,
    /// Alpha channel, 0..255.
    pub a: u8,
    /// Per-span font scale multiplier.
    pub scale: f32,
}
impl TextSpan {
    /// Construct a `TextSpan` from a string-like value and explicit RGBA and scale.
    pub fn new(text: impl Into<String>, r: u8, g: u8, b: u8, a: u8, scale: f32) -> Self {
        Self {
            text: text.into(),
            r,
            g,
            b,
            a,
            scale,
        }
    }
}
/// All draw, state, and control operations submitted to `GpuRenderer::render_frame`.
#[derive(Debug, Clone)]
pub enum RenderCommand {
    /// Set the current RGBA draw color used by subsequent shape/line commands.
    SetColor(f32, f32, f32, f32),
    /// Draw a filled or outlined axis-aligned rectangle.
    Rectangle {
        mode: DrawMode,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
    },
    /// Draw a filled or outlined rectangle with per-corner rounded radii.
    RoundedRectangle {
        mode: DrawMode,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        rx: f32,
        ry: f32,
    },
    /// Draw a filled or outlined circle.
    Circle {
        mode: DrawMode,
        x: f32,
        y: f32,
        r: f32,
    },
    /// Draw a filled or outlined ellipse.
    Ellipse {
        mode: DrawMode,
        x: f32,
        y: f32,
        rx: f32,
        ry: f32,
    },
    /// Draw a filled or outlined triangle from three screen-space vertices.
    Triangle {
        mode: DrawMode,
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
        x3: f32,
        y3: f32,
    },
    /// Draw a filled or outlined convex polygon from a flat `[x, y, ...]` array.
    Polygon { mode: DrawMode, vertices: Vec<f32> },
    /// Draw a single line segment.
    Line { x1: f32, y1: f32, x2: f32, y2: f32 },
    /// Draw a polyline from a flat `[x, y, ...]` point array.
    Polyline { points: Vec<f32> },
    /// Draw a texture at `(x, y)` with an optional per-frame shader effect chain.
    DrawImage {
        texture_key: TextureKey,
        x: f32,
        y: f32,
        effect: Option<Vec<ShaderPassDescriptor>>,
    },
    /// Draw a texture with full transform parameters and optional shader effects.
    DrawImageEx {
        texture_key: TextureKey,
        x: f32,
        y: f32,
        rotation: f32,
        sx: f32,
        sy: f32,
        ox: f32,
        oy: f32,
        effect: Option<Vec<ShaderPassDescriptor>>,
    },
    /// Draw a sub-region (quad) of a texture with transform and optional shader effects.
    DrawQuad {
        texture_key: TextureKey,
        quad_x: f32,
        quad_y: f32,
        quad_w: f32,
        quad_h: f32,
        tex_w: f32,
        tex_h: f32,
        x: f32,
        y: f32,
        rotation: f32,
        sx: f32,
        sy: f32,
        ox: f32,
        oy: f32,
        effect: Option<Vec<ShaderPassDescriptor>>,
    },
    /// Draw a text string with a bitmap font at `(x, y)` at `scale`.
    Print {
        font_key: FontKey,
        text: String,
        x: f32,
        y: f32,
        scale: f32,
    },
    /// Draw a sequence of `TextSpan` slices using a shared bitmap font.
    DrawRichText {
        font_key: FontKey,
        spans: Vec<TextSpan>,
        x: f32,
        y: f32,
    },
    /// Set the stroke line width for subsequent outlined shape commands.
    SetLineWidth(f32),
    /// Push the current transform matrix onto the transform stack.
    PushTransform,
    /// Pop the transform matrix from the stack and restore the previous state.
    PopTransform,
    /// Apply a translation to the current transform.
    Translate { x: f32, y: f32 },
    /// Apply a rotation (radians) to the current transform.
    Rotate { angle: f32 },
    /// Apply a non-uniform scale to the current transform.
    Scale { sx: f32, sy: f32 },
    /// Apply a shear (skew) to the current transform.
    Shear { kx: f32, ky: f32 },
    /// Reset the current transform to the identity matrix.
    Origin,
    /// Replace the current transform with an explicit 3x3 column-major matrix.
    ApplyTransform { matrix: [f32; 9] },
    /// Draw a circular arc segment.
    Arc {
        mode: DrawMode,
        x: f32,
        y: f32,
        radius: f32,
        angle1: f32,
        angle2: f32,
        segments: u32,
    },
    /// Draw a registered sprite batch.
    DrawBatch { batch_key: SpriteBatchKey },
    /// Set the active blend mode for subsequent draw commands.
    SetBlendMode(BlendMode),
    /// Set or clear the active render canvas; `None` restores the default target.
    SetCanvas(Option<CanvasKey>),
    /// Draw a canvas texture with full transform parameters.
    DrawCanvas {
        canvas_key: CanvasKey,
        x: f32,
        y: f32,
        rotation: f32,
        sx: f32,
        sy: f32,
        ox: f32,
        oy: f32,
    },
    /// Allocate or resize a named render canvas on the GPU.
    RegisterCanvas {
        canvas_key: CanvasKey,
        width: u32,
        height: u32,
    },
    /// Mark a canvas as needing a full clear before its next render pass.
    ResetCanvas(CanvasKey),
    /// Draw a list of screen-space points.
    Points { points: Vec<(f32, f32)> },
    /// Set the point-sprite size in pixels.
    SetPointSize(f32),
    /// Set or clear the scissor rectangle; `None` disables scissor testing.
    SetScissor(Option<(f32, f32, f32, f32)>),
    /// Set per-channel color write mask.
    SetColorMask(bool, bool, bool, bool),
    /// Toggle wireframe fill mode for subsequent geometry.
    SetWireframe(bool),
    /// Draw word-wrapped formatted text within a horizontal `limit`.
    PrintFormatted {
        font_key: FontKey,
        text: String,
        x: f32,
        y: f32,
        limit: f32,
        align: TextAlign,
        scale: f32,
    },
    /// Begin stencil write pass using `action` and reference `value`.
    StencilBegin { action: StencilAction, value: u8 },
    /// End stencil write pass and restore color writes.
    StencilEnd,
    /// Set or clear stencil test for subsequent draws; `None` disables testing.
    SetStencilTest(Option<(CompareMode, u8)>),
    /// Set or clear the active WGSL shader; `None` restores the default pipeline.
    SetShader(Option<ShaderKey>),
    /// Draw a registered mesh with full transform parameters.
    DrawMesh {
        mesh_key: MeshKey,
        x: f32,
        y: f32,
        rotation: f32,
        sx: f32,
        sy: f32,
        ox: f32,
        oy: f32,
    },
    /// Upload updated `Mesh` data to the named GPU slot.
    SyncMesh { mesh_key: MeshKey, mesh: Mesh },
    /// Draw a one-frame transient mesh without a persistent GPU slot.
    DrawMeshTransient {
        mesh: Mesh,
        x: f32,
        y: f32,
        rotation: f32,
        sx: f32,
        sy: f32,
        ox: f32,
        oy: f32,
    },
    /// Draw a nine-slice scaled region from a texture.
    DrawNineSlice {
        texture_key: TextureKey,
        tex_w: f32,
        tex_h: f32,
        top: f32,
        right: f32,
        bottom: f32,
        left: f32,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
    },
    /// Draw a registered `Shape` with full transform parameters.
    DrawShape {
        shape_key: ShapeKey,
        x: f32,
        y: f32,
        rotation: f32,
        sx: f32,
        sy: f32,
        ox: f32,
        oy: f32,
    },
    /// Draw a particle system snapshot as a list of `ParticleInstance` values.
    DrawParticleSystem { particles: Vec<ParticleInstance> },
    /// Mark the start of a post-processing capture region identified by `stack_id`.
    BeginPostFx { stack_id: u64 },
    /// Mark the end of a post-processing capture region.
    EndPostFx { stack_id: u64 },
    /// Apply a series of post-fx passes to the captured region.
    ApplyPostFx {
        stack_id: u64,
        passes: Vec<PostFxPass>,
        width: u32,
        height: u32,
    },
    /// Draw a perspective-correct textured quad with explicit corner positions and UVs.
    DrawTexturedQuad {
        corners: [Vec2; 4],
        uvs: [Vec2; 4],
        corner_w: [f32; 4],
        texture_key: TextureKey,
        color: [f32; 4],
    },
    /// Draw a quadratic Bezier curve as a polyline.
    DrawQuadBezier {
        start: Vec2,
        control: Vec2,
        end: Vec2,
        segments: u32,
    },
    /// Draw a cubic Bezier curve as a polyline.
    DrawCubicBezier {
        start: Vec2,
        c1: Vec2,
        c2: Vec2,
        end: Vec2,
        segments: u32,
    },
    /// Draw an arbitrary 2D path defined as a sequence of `PathSegment` moves.
    DrawPath {
        segments: Vec<PathSegment>,
        mode: DrawMode,
        close: bool,
    },
    /// Draw a solid rectangle with a two-color gradient.
    DrawGradientRect {
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        color1: [f32; 4],
        color2: [f32; 4],
        direction: GradientDirection,
    },
    /// Draw a polygon where each vertex carries its own RGBA color.
    DrawColoredPolygon {
        vertices: Vec<f32>,
        colors: Vec<[f32; 4]>,
        mode: DrawMode,
    },
    /// Draw a single isometric cube tile with optional per-face textures.
    DrawIsoCubeTile {
        screen_x: f32,
        screen_y: f32,
        half_w: f32,
        half_h: f32,
        depth: f32,
        top_color: [f32; 4],
        top_texture: Option<TextureKey>,
        left_color: [f32; 4],
        left_texture: Option<TextureKey>,
        right_color: [f32; 4],
        right_texture: Option<TextureKey>,
    },
    /// Draw a single hexagonal tile outline or fill.
    DrawHexTile {
        cx: f32,
        cy: f32,
        size: f32,
        orientation: HexOrientation,
        mode: DrawMode,
    },
    /// Begin a depth-sorted draw group identified by `group_id`.
    BeginSortGroup { group_id: u64 },
    /// Push a sort key for the next draw command in the current sort group.
    PushSortKey(f32),
    /// Flush and emit all buffered commands in the sort group ordered by sort key.
    FlushSortGroup { group_id: u64 },
    /// Draw physics collider outlines using `config` colors.
    DrawPhysicsDebug {
        shapes: Vec<PhysicsDebugShape>,
        config: PhysicsDebugConfig,
    },
    /// Draw Spine skeleton slot quads.
    DrawSpineSkeleton { slots: Vec<SpineSlotDraw> },
    /// Draw a bevel-styled rectangle with highlight, shadow, and fill colors.
    DrawBevelRect {
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        bevel_w: f32,
        style: BevelStyle,
        highlight: [f32; 4],
        shadow: [f32; 4],
        fill_color: [f32; 4],
    },
    /// Push a compositing layer with `alpha` and `blend` mode.
    PushLayer {
        id: u64,
        alpha: f32,
        blend: BlendMode,
    },
    /// Pop and composite the named layer onto the parent target.
    PopLayer { id: u64 },
    /// Draw a convex triangle fan with per-vertex UVs, tint, and blend mode.
    DrawConvexFan {
        vertices: Vec<Vec2>,
        uvs: Vec<Vec2>,
        texture_key: Option<TextureKey>,
        tint: [f32; 4],
        blend: BlendMode,
    },
}
/// Raw CPU-side texture pixel data passed to `GpuRenderer::upload_texture`.
#[derive(Clone)]
pub struct TextureData {
    /// Linear RGBA bytes in row-major order.
    pub pixels: Vec<u8>,
    /// Texture width in pixels.
    pub width: u32,
    /// Texture height in pixels.
    pub height: u32,
    /// Color space declared for this texture.
    pub color_space: crate::image::TextureColorSpace,
}
/// Shape used to render a single particle in `DrawParticleSystem`.
#[derive(Clone, Debug)]
pub enum ParticleRenderShape {
    /// Axis-aligned square.
    Square,
    /// Filled circle.
    Circle,
    /// Equilateral triangle.
    Triangle,
    /// Thin elongated spark streak.
    Spark,
    /// Diamond (45-rotated square).
    Diamond,
    /// Irregular fragment with `edges` sides, seeded by `seed`.
    Shrapnel { edges: u8, seed: u32 },
    /// Capsule-like ray with given width-to-height `aspect`.
    Ray { aspect: f32 },
    /// Soft circle puff.
    Puff,
    /// Hollow ring with given fractional `thickness`.
    Ring { thickness: f32 },
    /// Pill-shaped capsule.
    Capsule,
}
/// A single particle snapshot submitted by `DrawParticleSystem`.
#[derive(Clone, Debug)]
pub struct ParticleInstance {
    /// Screen X position.
    pub x: f32,
    /// Screen Y position.
    pub y: f32,
    /// Red channel, 0.0..1.0.
    pub r: f32,
    /// Green channel, 0.0..1.0.
    pub g: f32,
    /// Blue channel, 0.0..1.0.
    pub b: f32,
    /// Alpha channel, 0.0..1.0.
    pub a: f32,
    /// Rotation in radians.
    pub rotation: f32,
    /// Uniform radius or half-size in pixels.
    pub size: f32,
    /// Render shape variant for this particle.
    pub shape: ParticleRenderShape,
    /// Optional texture key for sprite-based particles.
    pub texture_key: Option<TextureKey>,
    /// Optional `[quad_x, quad_y, quad_w, quad_h]` sub-region within the texture.
    pub quad: Option<[f32; 4]>,
    /// Source texture dimensions `(width, height)` used for UV calculation.
    pub quad_tex_dims: Option<(f32, f32)>,
}
/// A renderable resource handle used by generic draw utilities.
#[derive(Debug, Clone)]
pub enum DrawableKind {
    /// A loaded texture.
    Image(TextureKey),
    /// An off-screen render canvas.
    Canvas(CanvasKey),
    /// A sprite batch.
    SpriteBatch(SpriteBatchKey),
    /// A GPU mesh.
    Mesh(MeshKey),
}
/// A single segment in a `DrawPath` command.
#[derive(Clone, Debug)]
pub enum PathSegment {
    /// Move the current pen position without drawing.
    MoveTo {
        /// Target X.
        x: f32,
        /// Target Y.
        y: f32,
    },
    /// Draw a straight line from the current position.
    LineTo {
        /// Target X.
        x: f32,
        /// Target Y.
        y: f32,
    },
    /// Draw a quadratic Bezier curve via one control point.
    QuadTo {
        /// Control point X.
        cx: f32,
        /// Control point Y.
        cy: f32,
        /// Endpoint X.
        x: f32,
        /// Endpoint Y.
        y: f32,
    },
    /// Draw a cubic Bezier curve via two control points.
    CubicTo {
        /// First control point X.
        cx1: f32,
        /// First control point Y.
        cy1: f32,
        /// Second control point X.
        cx2: f32,
        /// Second control point Y.
        cy2: f32,
        /// Endpoint X.
        x: f32,
        /// Endpoint Y.
        y: f32,
    },
}
/// Direction of the color transition in a `DrawGradientRect` command.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum GradientDirection {
    /// Left-to-right.
    Horizontal,
    /// Top-to-bottom.
    Vertical,
    /// Top-left to bottom-right.
    DiagDown,
    /// Bottom-left to top-right.
    DiagUp,
    /// Center to edge.
    Radial,
}
/// Hex tile axis orientation used by `DrawHexTile`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HexOrientation {
    /// Hex has a vertex at the top (pointy-top).
    PointyTop,
    /// Hex has a flat edge at the top (flat-top).
    FlatTop,
}
/// Lighting style for a `DrawBevelRect` command.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum BevelStyle {
    /// Light from top-left; edges appear raised.
    Raised,
    /// Light from bottom-right; edges appear pressed in.
    Sunken,
    /// Double bevel appearing raised on the outer edge and sunken on the inner.
    Ridge,
    /// Double bevel appearing sunken on the outer edge and raised on the inner.
    Groove,
    /// No shading; edges use uniform fill color.
    Flat,
}
/// A single physics collider shape record used in `DrawPhysicsDebug`.
#[derive(Clone, Debug)]
pub struct PhysicsDebugShape {
    /// World X centre of the shape.
    pub x: f32,
    /// World Y centre of the shape.
    pub y: f32,
    /// Half-width in world units for AABB shapes.
    pub half_w: f32,
    /// Half-height in world units for AABB shapes.
    pub half_h: f32,
    /// Body rotation in radians.
    pub angle: f32,
    /// `true` when the body is a static obstacle.
    pub is_static: bool,
    /// `true` when the body is sleeping.
    pub is_sleeping: bool,
    /// `true` when the body is a sensor.
    pub is_sensor: bool,
    /// Convex hull vertices for polygon colliders; empty for AABB/circle.
    pub hull_verts: Vec<[f32; 2]>,
    /// `true` when this shape is a circle; uses `half_w` as radius.
    pub is_circle: bool,
}
/// Color and line-width settings for `DrawPhysicsDebug`.
#[derive(Clone, Debug)]
pub struct PhysicsDebugConfig {
    /// RGBA color for active dynamic bodies.
    pub body_color: [f32; 4],
    /// RGBA color for static bodies.
    pub static_color: [f32; 4],
    /// RGBA color for sleeping bodies.
    pub sleep_color: [f32; 4],
    /// RGBA color for sensor shapes.
    pub sensor_color: [f32; 4],
    /// Outline stroke width in pixels.
    pub line_width: f32,
}
/// Provide sensible default debug colors for `PhysicsDebugConfig`.
impl Default for PhysicsDebugConfig {
    fn default() -> Self {
        Self {
            body_color: [0.0, 1.0, 0.0, 0.8],
            static_color: [0.8, 0.8, 0.8, 0.8],
            sleep_color: [0.2, 0.6, 1.0, 0.6],
            sensor_color: [1.0, 0.8, 0.0, 0.6],
            line_width: 1.0,
        }
    }
}
/// One Spine animation slot draw record used in `DrawSpineSkeleton`.
#[derive(Clone, Debug)]
pub struct SpineSlotDraw {
    /// Texture referenced by this slot attachment.
    pub texture_key: TextureKey,
    /// World-space corner positions for the slot quad.
    pub corners: [Vec2; 4],
    /// UV coordinates at each corner.
    pub uvs: [Vec2; 4],
    /// Tint color applied to this slot.
    pub color: [f32; 4],
    /// Blend mode for this slot.
    pub blend_mode: BlendMode,
}
