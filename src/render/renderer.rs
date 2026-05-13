use crate::math::Vec2;
use crate::render::image_effect::ShaderPassDescriptor;
use crate::render::mesh::Mesh;
use crate::runtime::resource_keys::{
    CanvasKey, FontKey, MeshKey, ShaderKey, ShapeKey, SpriteBatchKey, TextureKey,
};
use std::collections::HashMap;
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum CompareMode {
    Equal,
    NotEqual,
    Less,
    LessEqual,
    Greater,
    GreaterEqual,
    Always,
    Never,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum StencilAction {
    Keep,
    Zero,
    Replace,
    Increment,
    Decrement,
    IncrementWrap,
    DecrementWrap,
    Invert,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct StencilMode {
    pub action: StencilAction,
    pub compare: CompareMode,
    pub value: u8,
}
impl Default for StencilMode {
    fn default() -> Self {
        Self {
            action: StencilAction::Keep,
            compare: CompareMode::Always,
            value: 0,
        }
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum DepthMode {
    #[default]
    Always,
    Never,
    Less,
    LessEqual,
    Equal,
    NotEqual,
    Greater,
    GreaterEqual,
}
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TextAlign {
    Left,
    Center,
    Right,
    Justify,
}
#[derive(Debug, Clone)]
pub enum DrawMode {
    Fill,
    Line,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum BlendMode {
    #[default]
    Alpha,
    Add,
    Multiply,
    Replace,
    Screen,
}
#[derive(Debug, Clone)]
pub struct PostFxPass {
    pub effect_name: String,
    pub params: HashMap<String, f32>,
    pub shader_id: Option<usize>,
    pub auto_uniforms: bool,
}
#[derive(Debug, Clone)]
pub struct TextSpan {
    pub text: String,
    pub r: u8,
    pub g: u8,
    pub b: u8,
    pub a: u8,
    pub scale: f32,
}
impl TextSpan {
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
#[derive(Debug, Clone)]
pub enum RenderCommand {
    SetColor(f32, f32, f32, f32),
    Rectangle {
        mode: DrawMode,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
    },
    RoundedRectangle {
        mode: DrawMode,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        rx: f32,
        ry: f32,
    },
    Circle {
        mode: DrawMode,
        x: f32,
        y: f32,
        r: f32,
    },
    Ellipse {
        mode: DrawMode,
        x: f32,
        y: f32,
        rx: f32,
        ry: f32,
    },
    Triangle {
        mode: DrawMode,
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
        x3: f32,
        y3: f32,
    },
    Polygon {
        mode: DrawMode,
        vertices: Vec<f32>,
    },
    Line {
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
    },
    Polyline {
        points: Vec<f32>,
    },
    DrawImage {
        texture_key: TextureKey,
        x: f32,
        y: f32,
        effect: Option<Vec<ShaderPassDescriptor>>,
    },
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
    Print {
        font_key: FontKey,
        text: String,
        x: f32,
        y: f32,
        scale: f32,
    },
    DrawRichText {
        font_key: FontKey,
        spans: Vec<TextSpan>,
        x: f32,
        y: f32,
    },
    SetLineWidth(f32),
    PushTransform,
    PopTransform,
    Translate {
        x: f32,
        y: f32,
    },
    Rotate {
        angle: f32,
    },
    Scale {
        sx: f32,
        sy: f32,
    },
    Shear {
        kx: f32,
        ky: f32,
    },
    Origin,
    ApplyTransform {
        matrix: [f32; 9],
    },
    Arc {
        mode: DrawMode,
        x: f32,
        y: f32,
        radius: f32,
        angle1: f32,
        angle2: f32,
        segments: u32,
    },
    DrawBatch {
        batch_key: SpriteBatchKey,
    },
    SetBlendMode(BlendMode),
    SetCanvas(Option<CanvasKey>),
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
    RegisterCanvas {
        canvas_key: CanvasKey,
        width: u32,
        height: u32,
    },
    Points {
        points: Vec<(f32, f32)>,
    },
    SetPointSize(f32),
    SetScissor(Option<(f32, f32, f32, f32)>),
    SetColorMask(bool, bool, bool, bool),
    SetWireframe(bool),
    PrintFormatted {
        font_key: FontKey,
        text: String,
        x: f32,
        y: f32,
        limit: f32,
        align: TextAlign,
        scale: f32,
    },
    StencilBegin {
        action: StencilAction,
        value: u8,
    },
    StencilEnd,
    SetStencilTest(Option<(CompareMode, u8)>),
    SetShader(Option<ShaderKey>),
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
    SyncMesh {
        mesh_key: MeshKey,
        mesh: Mesh,
    },
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
    DrawParticleSystem {
        particles: Vec<ParticleInstance>,
    },
    BeginPostFx {
        stack_id: u64,
    },
    EndPostFx {
        stack_id: u64,
    },
    ApplyPostFx {
        stack_id: u64,
        passes: Vec<PostFxPass>,
        width: u32,
        height: u32,
    },
    DrawTexturedQuad {
        corners: [Vec2; 4],
        uvs: [Vec2; 4],
        corner_w: [f32; 4],
        texture_key: TextureKey,
        color: [f32; 4],
    },
    DrawQuadBezier {
        start: Vec2,
        control: Vec2,
        end: Vec2,
        segments: u32,
    },
    DrawCubicBezier {
        start: Vec2,
        c1: Vec2,
        c2: Vec2,
        end: Vec2,
        segments: u32,
    },
    DrawPath {
        segments: Vec<PathSegment>,
        mode: DrawMode,
        close: bool,
    },
    DrawGradientRect {
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        color1: [f32; 4],
        color2: [f32; 4],
        direction: GradientDirection,
    },
    DrawColoredPolygon {
        vertices: Vec<f32>,
        colors: Vec<[f32; 4]>,
        mode: DrawMode,
    },
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
    DrawHexTile {
        cx: f32,
        cy: f32,
        size: f32,
        orientation: HexOrientation,
        mode: DrawMode,
    },
    BeginSortGroup {
        group_id: u64,
    },
    PushSortKey(f32),
    FlushSortGroup {
        group_id: u64,
    },
    DrawPhysicsDebug {
        shapes: Vec<PhysicsDebugShape>,
        config: PhysicsDebugConfig,
    },
    DrawSpineSkeleton {
        slots: Vec<SpineSlotDraw>,
    },
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
    PushLayer {
        id: u64,
        alpha: f32,
        blend: BlendMode,
    },
    PopLayer {
        id: u64,
    },
    DrawConvexFan {
        vertices: Vec<Vec2>,
        uvs: Vec<Vec2>,
        texture_key: Option<TextureKey>,
        tint: [f32; 4],
        blend: BlendMode,
    },
}
#[derive(Clone)]
pub struct TextureData {
    pub pixels: Vec<u8>,
    pub width: u32,
    pub height: u32,
    pub color_space: crate::image::TextureColorSpace,
}
#[derive(Clone, Debug)]
pub enum ParticleRenderShape {
    Square,
    Circle,
    Triangle,
    Spark,
    Diamond,
    Shrapnel { edges: u8, seed: u32 },
    Ray { aspect: f32 },
    Puff,
    Ring { thickness: f32 },
    Capsule,
}
#[derive(Clone, Debug)]
pub struct ParticleInstance {
    pub x: f32,
    pub y: f32,
    pub r: f32,
    pub g: f32,
    pub b: f32,
    pub a: f32,
    pub rotation: f32,
    pub size: f32,
    pub shape: ParticleRenderShape,
    pub texture_key: Option<TextureKey>,
    pub quad: Option<[f32; 4]>,
    pub quad_tex_dims: Option<(f32, f32)>,
}
#[derive(Debug, Clone)]
pub enum DrawableKind {
    Image(TextureKey),
    Canvas(CanvasKey),
    SpriteBatch(SpriteBatchKey),
    Mesh(MeshKey),
}
#[derive(Clone, Debug)]
pub enum PathSegment {
    MoveTo {
        x: f32,
        y: f32,
    },
    LineTo {
        x: f32,
        y: f32,
    },
    QuadTo {
        cx: f32,
        cy: f32,
        x: f32,
        y: f32,
    },
    CubicTo {
        cx1: f32,
        cy1: f32,
        cx2: f32,
        cy2: f32,
        x: f32,
        y: f32,
    },
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum GradientDirection {
    Horizontal,
    Vertical,
    DiagDown,
    DiagUp,
    Radial,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HexOrientation {
    PointyTop,
    FlatTop,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum BevelStyle {
    Raised,
    Sunken,
    Ridge,
    Groove,
    Flat,
}
#[derive(Clone, Debug)]
pub struct PhysicsDebugShape {
    pub x: f32,
    pub y: f32,
    pub half_w: f32,
    pub half_h: f32,
    pub angle: f32,
    pub is_static: bool,
    pub is_sleeping: bool,
    pub is_sensor: bool,
    pub hull_verts: Vec<[f32; 2]>,
    pub is_circle: bool,
}
#[derive(Clone, Debug)]
pub struct PhysicsDebugConfig {
    pub body_color: [f32; 4],
    pub static_color: [f32; 4],
    pub sleep_color: [f32; 4],
    pub sensor_color: [f32; 4],
    pub line_width: f32,
}
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
#[derive(Clone, Debug)]
pub struct SpineSlotDraw {
    pub texture_key: TextureKey,
    pub corners: [Vec2; 4],
    pub uvs: [Vec2; 4],
    pub color: [f32; 4],
    pub blend_mode: BlendMode,
}
