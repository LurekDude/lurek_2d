//! Draw command types, blend modes, and texture data for the Lurek2D rendering pipeline.
//!
//! This module is part of Lurek2D's `graphics` subsystem and provides the implementation
//! details for renderer-related operations and data management.
//! Key types exported from this module: `CompareMode`, `StencilAction`, `TextAlign`, `DrawMode`, `BlendMode`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::collections::HashMap;
use crate::math::Vec2;
use crate::runtime::resource_keys::{
    CanvasKey, FontKey, MeshKey, ShaderKey, ShapeKey, SpriteBatchKey, TextureKey,
};
use crate::render::image_effect::ShaderPassDescriptor;
use crate::render::mesh::Mesh;

/// Stencil comparison mode for `lurek.graphic.setStencilTest`.
///
/// # Variants
/// - `Equal` — Equal variant.
/// - `NotEqual` — NotEqual variant.
/// - `Less` — Less variant.
/// - `LessEqual` — LessEqual variant.
/// - `Greater` — Greater variant.
/// - `GreaterEqual` — GreaterEqual variant.
/// - `Always` — Always variant.
/// - `Never` — Never variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum CompareMode {
    /// Pass if (ref & mask) == (stencil & mask).
    Equal,
    /// Pass if (ref & mask) != (stencil & mask).
    NotEqual,
    /// Pass if (ref & mask) < (stencil & mask).
    Less,
    /// Pass if (ref & mask) <= (stencil & mask).
    LessEqual,
    /// Pass if (ref & mask) > (stencil & mask).
    Greater,
    /// Pass if (ref & mask) >= (stencil & mask).
    GreaterEqual,
    /// Always pass.
    Always,
    /// Never pass.
    Never,
}

/// Stencil write action for `lurek.graphic.stencil` and `lurek.graphic.setStencilMode`.
///
/// # Variants
/// - `Keep` — Keep variant.
/// - `Zero` — Zero variant.
/// - `Replace` — Replace variant.
/// - `Increment` — Increment variant.
/// - `Decrement` — Decrement variant.
/// - `IncrementWrap` — IncrementWrap variant.
/// - `DecrementWrap` — DecrementWrap variant.
/// - `Invert` — Invert variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum StencilAction {
    /// Keep the current stencil value (no change).
    Keep,
    /// Set the stencil value to zero.
    Zero,
    /// Replace the stencil value.
    Replace,
    /// Increment the stencil value (clamps at 255).
    Increment,
    /// Decrement the stencil value (clamps at 0).
    Decrement,
    /// Increment with wrap-around.
    IncrementWrap,
    /// Decrement with wrap-around.
    DecrementWrap,
    /// Bitwise invert the stencil value.
    Invert,
}

/// Combined stencil rendering mode stored in `SharedState`.
///
/// Controls what happens to stencil buffer values when draws occur (`action`),
/// the test that subsequent draws must pass (`compare`), and the reference
/// value (`value`) used by the comparison.  The GPU applies this lazily when
/// the pipeline is rebuilt.
///
/// # Fields
/// - `action` — `StencilAction`.
/// - `compare` — `CompareMode`.
/// - `value` — `u8`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct StencilMode {
    /// Operation applied to the stencil buffer on pass/fail.
    pub action: StencilAction,
    /// Comparison function used to test incoming fragments against `value`.
    pub compare: CompareMode,
    /// Reference value compared against the stencil buffer.
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

/// Depth test comparison mode for `lurek.graphic.setDepthMode`.
///
/// # Variants
/// - `Always` — Always variant.
/// - `Never` — Never variant.
/// - `Less` — Less variant.
/// - `LessEqual` — LessEqual variant.
/// - `Equal` — Equal variant.
/// - `NotEqual` — NotEqual variant.
/// - `Greater` — Greater variant.
/// - `GreaterEqual` — GreaterEqual variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum DepthMode {
    /// Always pass — depth test is effectively disabled (default).
    #[default]
    Always,
    /// Never pass.
    Never,
    /// Pass if incoming depth < stored depth.
    Less,
    /// Pass if incoming depth <= stored depth.
    LessEqual,
    /// Pass if incoming depth == stored depth.
    Equal,
    /// Pass if incoming depth != stored depth.
    NotEqual,
    /// Pass if incoming depth > stored depth.
    Greater,
    /// Pass if incoming depth >= stored depth.
    GreaterEqual,
}

/// Text alignment mode for formatted text printing.
///
/// # Variants
/// - `Left` — Left variant.
/// - `Center` — Center variant.
/// - `Right` — Right variant.
/// - `Justify` — Justify variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TextAlign {
    /// Left-aligned (default).
    Left,
    /// Centered within the limit width.
    Center,
    /// Right-aligned within the limit width.
    Right,
    /// Justified (treated as Left for now).
    Justify,
}

/// Whether a shape is drawn filled or as an outline.
///
/// # Variants
/// - `Fill` — Draw shapes as solid filled areas.
/// - `Line` — Draw shapes as outlines using the current line width.
#[derive(Debug, Clone)]
pub enum DrawMode {
    Fill,
    Line,
}

/// Blending mode for draw operations. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Alpha` — Alpha variant.
/// - `Add` — Add variant.
/// - `Multiply` — Multiply variant.
/// - `Replace` — Replace variant.
/// - `Screen` — Screen variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum BlendMode {
    /// Standard alpha blending (default). Src * SrcAlpha + Dst * (1 - SrcAlpha).
    #[default]
    Alpha,
    /// Additive blending. Src * SrcAlpha + Dst * One.
    Add,
    /// Multiplicative blending. Src * Dst + Dst * Zero.
    Multiply,
    /// Replace — no blending, just overwrite. Src * One + Dst * Zero.
    Replace,
    /// Screen blend. Src * One + Dst * (1 - Src).
    Screen,
}

/// A single deferred draw operation queued during `lurek.draw()` and executed by `GpuRenderer`.
///
/// # Variants
/// - `SetColor(r, g, b, a)` — Sets the active draw color; affects all subsequent draw calls.
/// - `Rectangle` — Draws an axis-aligned rectangle.
/// - `RoundedRectangle` — Draws a rectangle with rounded corners.
/// - `Circle` — Draws a circle at center `(x, y)` with radius `r`.
/// - `Ellipse` — Draws an ellipse with semi-axes `rx`, `ry`.
/// - `Triangle` — Draws a triangle with three explicit vertices.
/// - `Polygon` — Draws an arbitrary polygon from a flat `[x0, y0, x1, y1, ...]` vertex list.
/// - `Line` — Draws a line segment from `(x1, y1)` to `(x2, y2)`.
/// - `Polyline` — Draws a connected sequence of line segments through a flat `[x0,y0,x1,y1,…]` list.
/// - `DrawImage` — Blits a texture (by index) at position `(x, y)`.
/// - `DrawImageEx` — Draws a texture with full transform (rotation, scale, origin offset).
/// - `DrawQuad` — Draws a sub-region (quad) of a texture with full transform.
/// - `Print` — Renders text using a loaded bitmap font.
/// - `SetLineWidth` — Sets the stroke width for subsequent outline draws.
/// - `PushTransform` — Saves the current transform onto the stack.
/// - `PopTransform` — Restores the previous transform from the stack.
/// - `Translate` — Applies a translation to the current transform.
/// - `Rotate` — Applies a rotation (in radians) to the current transform.
/// - `Scale` — Applies a scale to the current transform.
/// - `Arc` — Draws an arc (sector or outline) of a circle.
/// - `DrawShape` — Draw all primitives in a compound shape with a unified affine transform.
/// - `DrawParticleSystem` — Renders all particles in a single batched command, dispatching per-shape geometry helpers internally.
/// - `BeginPostFx` — Start capturing the framebuffer for post-processing; subsequent draw calls render into the capture target.
/// - `EndPostFx` — Stop capturing; resume rendering to the previous target.
/// - `ApplyPostFx` — Apply the registered post-processing effects from the named stack and composite the result onto the current target.
/// - `DrawTexturedQuad` — Draws an arbitrary textured quad specified by four explicit screen-space corners and four UV coordinates.

/// A single shader pass in a post-FX pipeline.
///
/// Produced by the Lua PostFx stack at `apply()` time and stored inside
/// [`RenderCommand::ApplyPostFx`]. The GPU renderer iterates the list and
/// dispatches the appropriate WGSL shader for each pass in order.
///
/// # Fields
/// - `effect_name` — Name that maps to a WGSL shader file (e.g. `"bloom"`, `"vignette"`).
/// - `params` — Shader uniform values keyed by name.
/// - `shader_id` — For `Custom` passes only; index into the GPU shader registry.
#[derive(Debug, Clone)]
pub struct PostFxPass {
    /// Effect name mapping to a built-in WGSL shader (e.g. `"bloom"`, `"crt"`, `"vignette"`).
    pub effect_name: String,
    /// Uniform values forwarded to the WGSL shader for this pass.
    pub params: HashMap<String, f32>,
    /// For custom shader passes: index into the GPU shader registry. `None` for built-ins.
    pub shader_id: Option<usize>,
}

#[derive(Debug, Clone)]
/// RenderCommand.
///
/// # Variants
/// - `SetColor` — SetColor variant.
/// - `Rectangle` — Rectangle variant.
/// - `RoundedRectangle` — RoundedRectangle variant.
/// - `Circle` — Circle variant.
/// - `Ellipse` — Ellipse variant.
/// - `Triangle` — Triangle variant.
/// - `Polygon` — Polygon variant.
/// - `Line` — Line variant.
/// - `Polyline` — Polyline variant.
/// - `DrawImage` — DrawImage variant.
/// - `DrawImageEx` — DrawImageEx variant.
/// - `DrawQuad` — DrawQuad variant.
/// - `Print` — Print variant.
/// - `SetLineWidth` — SetLineWidth variant.
/// - `PushTransform` — PushTransform variant.
/// - `PopTransform` — PopTransform variant.
/// - `Translate` — Translate variant.
/// - `Rotate` — Rotate variant.
/// - `Scale` — Scale variant.
/// - `Shear` — Shear variant.
/// - `Origin` — Origin variant.
/// - `ApplyTransform` — ApplyTransform variant.
/// - `Arc` — Arc variant.
/// - `DrawBatch` — DrawBatch variant.
/// - `SetBlendMode` — SetBlendMode variant.
/// - `SetCanvas` — SetCanvas variant.
/// - `DrawCanvas` — DrawCanvas variant.
/// - `RegisterCanvas` — RegisterCanvas variant.
/// - `Points` — Points variant.
/// - `SetPointSize` — SetPointSize variant.
/// - `SetScissor` — SetScissor variant.
/// - `SetColorMask` — SetColorMask variant.
/// - `SetWireframe` — SetWireframe variant.
/// - `PrintFormatted` — PrintFormatted variant.
/// - `StencilBegin` — StencilBegin variant.
/// - `StencilEnd` — StencilEnd variant.
/// - `SetStencilTest` — SetStencilTest variant.
/// - `SetShader` — SetShader variant.
/// - `DrawMesh` — DrawMesh variant.
/// - `SyncMesh` — SyncMesh variant.
/// - `DrawNineSlice` — DrawNineSlice variant.
/// - `DrawShape` — DrawShape variant.
/// - `DrawParticleSystem` — DrawParticleSystem variant.
/// - `BeginPostFx` — BeginPostFx variant.
/// - `EndPostFx` — EndPostFx variant.
/// - `ApplyPostFx` — ApplyPostFx variant.
/// - `DrawTexturedQuad` — DrawTexturedQuad variant.
/// - `DrawQuadBezier` — DrawQuadBezier variant.
/// - `DrawCubicBezier` — DrawCubicBezier variant.
/// - `DrawPath` — DrawPath variant.
/// - `DrawGradientRect` — DrawGradientRect variant.
/// - `DrawColoredPolygon` — DrawColoredPolygon variant.
/// - `DrawIsoCubeTile` — DrawIsoCubeTile variant.
/// - `DrawHexTile` — DrawHexTile variant.
/// - `BeginSortGroup` — BeginSortGroup variant.
/// - `PushSortKey` — PushSortKey variant.
/// - `FlushSortGroup` — FlushSortGroup variant.
/// - `DrawPhysicsDebug` — DrawPhysicsDebug variant.
/// - `DrawSpineSkeleton` — DrawSpineSkeleton variant.
/// - `DrawBevelRect` — DrawBevelRect variant.
/// - `PushLayer` — PushLayer variant.
/// - `PopLayer` — PopLayer variant.
/// - `DrawRichText` — DrawRichText variant.

/// One styled segment inside a [`RenderCommand::DrawRichText`] command.
///
/// Each span can carry its own colour and scale, while the command as a
/// whole provides the default font and the baseline origin.
///
/// # Fields
/// - `text` — `String`. UTF-8 text content of this span.
/// - `r`, `g`, `b`, `a` — `u8`. RGBA colour override (0–255).
/// - `scale` — `f32`. Font scale multiplier (1.0 = default size).
#[derive(Debug, Clone)]
pub struct TextSpan {
    /// UTF-8 text content of this span.
    pub text: String,
    /// Red channel (0–255).
    pub r: u8,
    /// Green channel (0–255).
    pub g: u8,
    /// Blue channel (0–255).
    pub b: u8,
    /// Alpha channel (0–255, 255 = fully opaque).
    pub a: u8,
    /// Scale multiplier applied to the default font size.
    pub scale: f32,
}

impl TextSpan {
    /// Creates a new span with the given text, RGBA colour, and scale.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`. Text content.
    /// - `r`, `g`, `b`, `a` — `u8`. RGBA components.
    /// - `scale` — `f32`. Font scale multiplier.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(text: impl Into<String>, r: u8, g: u8, b: u8, a: u8, scale: f32) -> Self {
        Self { text: text.into(), r, g, b, a, scale }
    }
}

/// Enqueues a typed draw or state command into the per-frame GPU render queue.
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
    /// Multi-segment polyline; `points` is `[x0, y0, x1, y1, …]` — at least 4 elements.
    Polyline {
        points: Vec<f32>,
    },
    DrawImage {
        texture_key: TextureKey,
        x: f32,
        y: f32,
        /// Optional per-image effect chain applied at draw time.
        effect: Option<Vec<ShaderPassDescriptor>>,
    },
    /// Draw a texture with full affine transform: rotation (radians), scale, origin offset.
    DrawImageEx {
        texture_key: TextureKey,
        x: f32,
        y: f32,
        rotation: f32,
        sx: f32,
        sy: f32,
        ox: f32,
        oy: f32,
        /// Optional per-image effect chain applied at draw time.
        effect: Option<Vec<ShaderPassDescriptor>>,
    },
    /// Draw a sub-region of a texture (sprite-sheet) with full transform.
    DrawQuad {
        texture_key: TextureKey,
        /// Sub-region top-left in texture pixels.
        quad_x: f32,
        quad_y: f32,
        /// Sub-region size in texture pixels.
        quad_w: f32,
        quad_h: f32,
        /// Full texture dimensions (for UV normalisation).
        tex_w: f32,
        tex_h: f32,
        x: f32,
        y: f32,
        rotation: f32,
        sx: f32,
        sy: f32,
        ox: f32,
        oy: f32,
        /// Optional per-image effect chain applied at draw time.
        effect: Option<Vec<ShaderPassDescriptor>>,
    },
    Print {
        font_key: FontKey,
        text: String,
        x: f32,
        y: f32,
        scale: f32,
    },
    /// Draw a sequence of individually-styled text spans at a common baseline.
    ///
    /// Each span in `spans` can carry its own colour and scale, allowing
    /// mixed-style rich text to be drawn in a single command.
    DrawRichText {
        font_key: FontKey,
        spans: Vec<TextSpan>,
        x: f32,
        y: f32,
    },
    SetLineWidth(f32),
    // ── Feature 1: Transform stack ──────────────────────────────────────────
    /// Push a copy of the current transform onto the stack.
    PushTransform,
    /// Pop the top transform from the stack (no-op if only one entry remains).
    PopTransform,
    /// Concatenate a translation onto the current transform.
    Translate {
        x: f32,
        y: f32,
    },
    /// Concatenate a rotation (radians) onto the current transform.
    Rotate {
        angle: f32,
    },
    /// Concatenate a scale onto the current transform.
    Scale {
        sx: f32,
        sy: f32,
    },
    /// Concatenate a shear (skew) onto the current transform.
    Shear {
        kx: f32,
        ky: f32,
    },
    /// Reset the current transform to identity (world space).
    Origin,
    /// Replace the current transform by multiplying with the given 3×3 column-major matrix.
    ApplyTransform {
        matrix: [f32; 9],
    },
    // ── Feature 2: Arc ──────────────────────────────────────────────────────
    /// Draw an arc of a circle. `angle1`/`angle2` are in radians; `segments` controls quality.
    Arc {
        mode: DrawMode,
        x: f32,
        y: f32,
        radius: f32,
        angle1: f32,
        angle2: f32,
        segments: u32,
    },

    /// Draw all sprites in a sprite batch as a single batched draw call.
    DrawBatch {
        /// Key into `SharedState::sprite_batches`.
        batch_key: SpriteBatchKey,
    },
    /// Change the blend mode for subsequent draw commands.
    SetBlendMode(BlendMode),
    /// Switch the active render target to an off-screen canvas, or back to the screen.
    ///
    /// `None` targets the screen; `Some(id)` targets the canvas at the given index.
    SetCanvas(Option<CanvasKey>),
    /// Draw a canvas texture to the current render target with full transform.
    DrawCanvas {
        /// Key into the canvas list.
        canvas_key: CanvasKey,
        /// Destination X position.
        x: f32,
        /// Destination Y position.
        y: f32,
        /// Rotation in radians.
        rotation: f32,
        /// Horizontal scale.
        sx: f32,
        /// Vertical scale.
        sy: f32,
        /// Origin X offset.
        ox: f32,
        /// Origin Y offset.
        oy: f32,
    },
    /// Legacy software-renderer canvas registration (no-op in GPU path).
    RegisterCanvas {
        canvas_key: CanvasKey,
        width: u32,
        height: u32,
    },
    /// Draw points at the specified coordinates.
    Points {
        points: Vec<(f32, f32)>,
    },
    /// Set the visual size of drawn points (in pixels).
    SetPointSize(f32),
    /// Set the scissor rectangle for clipping, or disable scissor clipping.
    SetScissor(Option<(f32, f32, f32, f32)>),
    /// Set which color channels can be written (r, g, b, a).
    SetColorMask(bool, bool, bool, bool),
    /// Enable or disable wireframe rendering mode.
    SetWireframe(bool),
    /// Draw word-wrapped, aligned text using a loaded TTF font.
    PrintFormatted {
        font_key: FontKey,
        text: String,
        x: f32,
        y: f32,
        limit: f32,
        align: TextAlign,
        scale: f32,
    },
    /// Begin stencil write mode — subsequent draws write to the stencil buffer instead of color.
    StencilBegin {
        action: StencilAction,
        value: u8,
    },
    /// End stencil write mode.
    StencilEnd,
    /// Set stencil comparison for subsequent draws, or disable stencil testing.
    SetStencilTest(Option<(CompareMode, u8)>),
    /// Set the active custom shader, or reset to the default pipeline.
    SetShader(Option<ShaderKey>),
    /// Draw a custom mesh with full affine transform.
    DrawMesh {
        /// Key into `SharedState::meshes`.
        mesh_key: MeshKey,
        /// Destination X position.
        x: f32,
        /// Destination Y position.
        y: f32,
        /// Rotation in radians.
        rotation: f32,
        /// Horizontal scale.
        sx: f32,
        /// Vertical scale.
        sy: f32,
        /// Origin X offset.
        ox: f32,
        /// Origin Y offset.
        oy: f32,
    },
    /// Legacy software-renderer mesh snapshot (no-op in GPU path).
    SyncMesh {
        mesh_key: MeshKey,
        mesh: Mesh,
    },
    /// Draw a nine-slice (9-patch) image stretched to fit a rectangle,
    /// preserving corner and edge proportions.
    DrawNineSlice {
        /// Key into `SharedState::textures`.
        texture_key: TextureKey,
        /// Full source texture width in pixels.
        tex_w: f32,
        /// Full source texture height in pixels.
        tex_h: f32,
        /// Top border inset in pixels.
        top: f32,
        /// Right border inset in pixels.
        right: f32,
        /// Bottom border inset in pixels.
        bottom: f32,
        /// Left border inset in pixels.
        left: f32,
        /// Destination X position.
        x: f32,
        /// Destination Y position.
        y: f32,
        /// Destination total width.
        w: f32,
        /// Destination total height.
        h: f32,
    },
    /// Draw all primitives in a compound shape with a unified affine transform.
    ///
    /// The renderer processes the shape's [`crate::render::ShapeCommand`] queue wrapped in a
    /// `PushTransform`/`PopTransform` pair, applying the given transform before
    /// dispatching each command.
    DrawShape {
        /// Key into `SharedState::shapes`.
        shape_key: ShapeKey,
        /// Destination X position in world pixels.
        x: f32,
        /// Destination Y position in world pixels.
        y: f32,
        /// Rotation in radians (counter-clockwise).
        rotation: f32,
        /// Horizontal scale factor.
        sx: f32,
        /// Vertical scale factor.
        sy: f32,
        /// Origin X offset (pivot point, in object space).
        ox: f32,
        /// Origin Y offset (pivot point, in object space).
        oy: f32,
    },
    /// Draw all particles in a system in a single batched command.
    ///
    /// Each entry in `particles` represents one live particle with its pre-computed world position,
    /// color, rotation, size, and shape. The renderer iterates the list and dispatches to the
    /// appropriate geometry helper for each particle, avoiding N separate top-level `RenderCommand`
    /// dispatches.
    DrawParticleSystem {
        /// Pre-computed per-particle render data for this frame.
        particles: Vec<ParticleInstance>,
    },
    /// Begin capturing the framebuffer for post-processing.
    ///
    /// Subsequent draw calls render into the capture target associated with the named post-FX
    /// stack. Call [`RenderCommand::EndPostFx`] to stop capturing, then
    /// [`RenderCommand::ApplyPostFx`] to composite the effects back onto the screen.
    BeginPostFx {
        /// Identifier for the post-FX stack managing this capture pass.
        stack_id: u64,
    },
    /// Stop capturing; resume rendering to the previous render target.
    EndPostFx {
        /// Identifier for the post-FX stack that started the capture pass.
        stack_id: u64,
    },
    /// Apply the post-processing effects in the named stack and composite onto the current target.
    ///
    /// `passes` lists the enabled shader passes in order. `width` and `height` are the
    /// dimensions of the capture texture used for ping-pong rendering.
    ApplyPostFx {
        /// Identifier for the post-FX stack whose effects will be applied.
        stack_id: u64,
        /// Ordered list of enabled shader passes to execute.
        passes: Vec<PostFxPass>,
        /// Capture texture width in pixels.
        width: u32,
        /// Capture texture height in pixels.
        height: u32,
    },
    /// Draw an arbitrary textured quad with perspective-correct UVs.
    ///
    /// Each corner and its corresponding UV coordinate are specified independently,
    /// enabling perspective-correct mapping for raycaster wall faces, portal geometry,
    /// and any other non-axis-aligned textured surface. The current transform stack
    /// is applied to all four corners before submission to the GPU.
    ///
    /// # Fields
    /// - `corners` — `[Vec2; 4]`. Screen-space corner positions in order: top-left, top-right, bottom-right, bottom-left.
    /// - `uvs` — `[Vec2; 4]`. Normalized UV coordinates `[0.0, 1.0]` for each corner in the same order.
    /// - `texture_key` — `TextureKey`. Texture to sample.
    /// - `color` — `[f32; 4]`. Per-quad RGBA tint multiplied against the sampled colour.
    DrawTexturedQuad {
        /// Screen-space corner positions: top-left, top-right, bottom-right, bottom-left.
        corners: [Vec2; 4],
        /// Normalized UV coordinates `[0.0, 1.0]` for each corner in the same order as `corners`.
        uvs: [Vec2; 4],
        /// Texture to sample.
        texture_key: TextureKey,
        /// Per-quad RGBA tint multiplied against the sampled colour.
        color: [f32; 4],
    },
    /// Draw a quadratic Bézier curve between `start` and `end` with one control point.
    ///
    /// The curve is tessellated into `segments` straight line segments on the CPU before
    /// submission. The current color and line-width state applies.
    ///
    /// # Fields
    /// - `start` — `Vec2`. Start point.
    /// - `control` — `Vec2`. Single control point.
    /// - `end` — `Vec2`. End point.
    /// - `segments` — `u32`. Tessellation resolution. Clamped to 4–256.
    DrawQuadBezier {
        /// Start point.
        start: Vec2,
        /// Single control point.
        control: Vec2,
        /// End point.
        end: Vec2,
        /// Tessellation resolution. Clamped to 4–256.
        segments: u32,
    },
    /// Draw a cubic Bézier curve through four points.
    ///
    /// Tessellated into `segments` straight lines on the CPU. Uses current color/line-width.
    ///
    /// # Fields
    /// - `start` — `Vec2`. Start point.
    /// - `c1` — `Vec2`. First control point.
    /// - `c2` — `Vec2`. Second control point.
    /// - `end` — `Vec2`. End point.
    /// - `segments` — `u32`. Tessellation resolution. Clamped to 4–256.
    DrawCubicBezier {
        /// Start point.
        start: Vec2,
        /// First control point.
        c1: Vec2,
        /// Second control point.
        c2: Vec2,
        /// End point.
        end: Vec2,
        /// Tessellation resolution. Clamped to 4–256.
        segments: u32,
    },
    /// Draw a multi-segment vector path.
    ///
    /// The path is specified as a list of [`PathSegment`] operations. When `close` is true
    /// the renderer appends a line from the last point back to the first `MoveTo` anchor.
    /// Fill mode (`DrawMode::Fill`) triangulates the closed contour; `DrawMode::Line` strokes it.
    ///
    /// # Fields
    /// - `segments` — `Vec<PathSegment>`. Ordered path operations.
    /// - `mode` — `DrawMode`. Fill or stroke mode.
    /// - `close` — `bool`. Close the path before rendering.
    DrawPath {
        /// Ordered path operations.
        segments: Vec<PathSegment>,
        /// Fill or stroke mode.
        mode: DrawMode,
        /// Close the path before rendering.
        close: bool,
    },
    /// Draw a colour-gradient filled rectangle.
    ///
    /// Two RGBA colours are interpolated across the rectangle according to `direction`.
    /// No texture. Current transform applies.
    ///
    /// # Fields
    /// - `x` — `f32`. Rectangle X.
    /// - `y` — `f32`. Rectangle Y.
    /// - `w` — `f32`. Rectangle width.
    /// - `h` — `f32`. Rectangle height.
    /// - `color1` — `[f32; 4]`. Start colour `[r, g, b, a]`.
    /// - `color2` — `[f32; 4]`. End colour `[r, g, b, a]`.
    /// - `direction` — `GradientDirection`. Direction the gradient flows.
    DrawGradientRect {
        /// Rectangle X.
        x: f32,
        /// Rectangle Y.
        y: f32,
        /// Rectangle width.
        w: f32,
        /// Rectangle height.
        h: f32,
        /// Start colour `[r, g, b, a]`.
        color1: [f32; 4],
        /// End colour `[f32; 4]`.
        color2: [f32; 4],
        /// Direction the gradient flows.
        direction: GradientDirection,
    },
    /// Draw a convex polygon with per-vertex colours.
    ///
    /// `vertices` is a flat list of `(x, y)` pairs; `colors` has one `[r,g,b,a]` entry per
    /// vertex. Lengths must match (renderer ignores mismatches silently). Current transform
    /// applies.
    ///
    /// # Fields
    /// - `vertices` — `Vec<f32>`. Flat vertex list: x0,y0, x1,y1, …
    /// - `colors` — `Vec<[f32; 4]>`. Per-vertex colour `[r,g,b,a]`.
    /// - `mode` — `DrawMode`. Fill or stroke.
    DrawColoredPolygon {
        /// Flat vertex list: x0,y0, x1,y1, …
        vertices: Vec<f32>,
        /// Per-vertex colour `[r,g,b,a]`.
        colors: Vec<[f32; 4]>,
        /// Fill or stroke.
        mode: DrawMode,
    },
    /// Draw a three-face isometric cube tile.
    ///
    /// The three visible faces (top, left-front, right-front) are each drawn as a
    /// coloured and/or textured parallelogram quad. A `None` texture key renders the
    /// face as a flat colour only.
    ///
    /// # Fields
    /// - `screen_x` — `f32`. Screen X of the tile's top-centre anchor point.
    /// - `screen_y` — `f32`. Screen Y of the tile's top-centre anchor point.
    /// - `half_w` — `f32`. Half-width of the tile in screen pixels.
    /// - `half_h` — `f32`. Half-height of one face in screen pixels.
    /// - `depth` — `f32`. Y-sort depth key.
    /// - `top_color` — `[f32; 4]`. Top face flat colour tint.
    /// - `top_texture` — `Option<TextureKey>`. Optional texture for the top face.
    /// - `left_color` — `[f32; 4]`. Left-front face colour tint.
    /// - `left_texture` — `Option<TextureKey>`. Optional texture for the left-front face.
    /// - `right_color` — `[f32; 4]`. Right-front face colour tint.
    /// - `right_texture` — `Option<TextureKey>`. Optional texture for the right-front face.
    DrawIsoCubeTile {
        /// Screen X of the tile's top-centre anchor point.
        screen_x: f32,
        /// Screen Y of the tile's top-centre anchor point.
        screen_y: f32,
        /// Half-width of the tile in screen pixels (controls the diamond footprint).
        half_w: f32,
        /// Half-height of one face in screen pixels.
        half_h: f32,
        /// Y-sort depth key. Lower values render behind higher values.
        depth: f32,
        /// Top face flat colour tint.
        top_color: [f32; 4],
        /// Optional texture key for the top face.
        top_texture: Option<TextureKey>,
        /// Left-front face colour tint.
        left_color: [f32; 4],
        /// Optional texture key for the left-front face.
        left_texture: Option<TextureKey>,
        /// Right-front face colour tint.
        right_color: [f32; 4],
        /// Optional texture key for the right-front face.
        right_texture: Option<TextureKey>,
    },
    /// Draw a hexagonal tile outline or fill.
    ///
    /// Hexagons are computed from the `cx`/`cy` centre and `size` (circumradius).
    /// Current color and line-width apply for `DrawMode::Line`; current color fills
    /// for `DrawMode::Fill`. Current transform applies.
    ///
    /// # Fields
    /// - `cx` — `f32`. Centre X in screen space.
    /// - `cy` — `f32`. Centre Y in screen space.
    /// - `size` — `f32`. Circumradius in screen pixels.
    /// - `orientation` — `HexOrientation`. Hex orientation.
    /// - `mode` — `DrawMode`. Fill or stroke.
    DrawHexTile {
        /// Centre X in screen space.
        cx: f32,
        /// Centre Y in screen space.
        cy: f32,
        /// Circumradius (centre to vertex) in screen pixels.
        size: f32,
        /// Hex orientation.
        orientation: HexOrientation,
        /// Fill or stroke.
        mode: DrawMode,
    },
    /// Mark the start of a Y/Z-depth sort group.
    ///
    /// All `PushSortKey` commands issued between this and the matching `FlushSortGroup`
    /// associate draw commands with a depth value. At `FlushSortGroup` the group is
    /// sorted and flushed in ascending depth order. Groups cannot be nested.
    ///
    /// # Fields
    /// - `group_id` — `u64`. Caller-assigned group identifier (must match `FlushSortGroup`).
    BeginSortGroup {
        /// Caller-assigned group identifier (must match `FlushSortGroup`).
        group_id: u64,
    },
    /// Associate the previous draw command with a sort depth within the active group.
    ///
    /// Must appear in the render command stream *immediately after* the draw command it
    /// annotates and between a `BeginSortGroup`/`FlushSortGroup` pair.
    PushSortKey(f32),
    /// Sort all draw commands accumulated since `BeginSortGroup` and flush them.
    ///
    /// After flushing the sort group is closed; a new `BeginSortGroup` is required
    /// before the next sort pass.
    ///
    /// # Fields
    /// - `group_id` — `u64`. Must match the `group_id` of the corresponding `BeginSortGroup`.
    FlushSortGroup {
        /// Must match the `group_id` of the corresponding `BeginSortGroup`.
        group_id: u64,
    },
    /// Draw GPU-accelerated physics debug shapes extracted from a physics world.
    ///
    /// `shapes` contains collider geometry snapshots produced by
    /// `physics::World::extract_debug_shapes()`. The renderer draws each shape as a coloured
    /// outline using `config` colours. No textures are used.
    ///
    /// # Fields
    /// - `shapes` — `Vec<PhysicsDebugShape>`. Pre-extracted collider geometry for this frame.
    /// - `config` — `PhysicsDebugConfig`. Colour and stroke configuration.
    DrawPhysicsDebug {
        /// Pre-extracted collider geometry for this frame.
        shapes: Vec<PhysicsDebugShape>,
        /// Colour and stroke configuration.
        config: PhysicsDebugConfig,
    },
    /// Draw a Spine 2D skeleton as a set of pre-composited textured slots.
    ///
    /// `slots` contains per-slot corner/UV/colour data produced by the spine CPU module.
    /// The renderer processes each slot independently, applying per-slot blend modes.
    ///
    /// # Fields
    /// - `slots` — `Vec<SpineSlotDraw>`. Ordered list of slot draw calls (back → front).
    DrawSpineSkeleton {
        /// Ordered list of slot draw calls (back → front).
        slots: Vec<SpineSlotDraw>,
    },
    /// Draw a 3-D bevel border around a rectangle.
    ///
    /// The bevel is drawn as four trapezoid fill quads forming the border. Inner face
    /// uses `fill_color`; highlight and shadow colours depend on `style`. No texture.
    ///
    /// # Fields
    /// - `x` — `f32`. Rectangle X.
    /// - `y` — `f32`. Rectangle Y.
    /// - `w` — `f32`. Rectangle width.
    /// - `h` — `f32`. Rectangle height.
    /// - `bevel_w` — `f32`. Bevel border width in pixels.
    /// - `style` — `BevelStyle`. Visual style of the bevel.
    /// - `highlight` — `[f32; 4]`. Top/left edge highlight colour.
    /// - `shadow` — `[f32; 4]`. Bottom/right edge shadow colour.
    /// - `fill_color` — `[f32; 4]`. Inner fill colour.
    DrawBevelRect {
        /// Rectangle X.
        x: f32,
        /// Rectangle Y.
        y: f32,
        /// Rectangle width.
        w: f32,
        /// Rectangle height.
        h: f32,
        /// Bevel border width in pixels.
        bevel_w: f32,
        /// Visual style of the bevel.
        style: BevelStyle,
        /// Top/left edge highlight colour `[r,g,b,a]`.
        highlight: [f32; 4],
        /// Bottom/right edge shadow colour `[r,g,b,a]`.
        shadow: [f32; 4],
        /// Inner fill colour `[r,g,b,a]`.
        fill_color: [f32; 4],
    },
    /// Begin a named compositing layer.
    ///
    /// All draw commands between this and the matching `PopLayer` are composited
    /// onto an off-screen target, then blended back onto the parent target at `flush` time
    /// with the layer's `alpha` and `blend` mode applied. Layers can be nested.
    ///
    /// # Fields
    /// - `id` — `u64`. Caller-assigned layer identifier.
    /// - `alpha` — `f32`. Layer opacity (0 = transparent, 1 = opaque).
    /// - `blend` — `BlendMode`. Blend mode used when compositing this layer back to its parent.
    PushLayer {
        /// Caller-assigned layer identifier.
        id: u64,
        /// Layer opacity (0 = transparent, 1 = opaque).
        alpha: f32,
        /// Blend mode used when compositing this layer back to its parent.
        blend: BlendMode,
    },
    /// End the current named compositing layer and composite it to the parent.
    ///
    /// # Fields
    /// - `id` — `u64`. Must match the `id` of the corresponding `PushLayer`.
    PopLayer {
        /// Must match the `id` of the corresponding `PushLayer`.
        id: u64,
    },

    /// Draw a convex polygon fan with an optional texture and a uniform RGBA tint.
    ///
    /// Designed for the `globe` module: each province is projected to screen-space vertices
    /// on the CPU and submitted as a single fan. The GPU path triangulates as a fan
    /// (vertex 0 is the implicit centre/anchor; or if `center` is provided, it is prepended).
    ///
    /// No depth buffer is used — this is a purely 2D draw call. Current transform applies.
    ///
    /// # Fields
    /// - `vertices` — Screen-space positions forming the convex hull in winding order.
    /// - `uvs` — Normalized UV `[0,1]` per vertex. May be empty for untextured draws.
    /// - `texture_key` — Optional texture; `None` renders a flat-coloured polygon.
    /// - `tint` — Per-polygon RGBA tint `[r,g,b,a]` (0.0–1.0). Multiplied against texture colour.
    /// - `blend` — Blend mode for this polygon.
    DrawConvexFan {
        /// Screen-space vertex positions forming the convex hull.
        vertices: Vec<Vec2>,
        /// Normalized UV coordinates per vertex. Empty for untextured polygons.
        uvs: Vec<Vec2>,
        /// Optional texture key. `None` = flat colour fill using `tint`.
        texture_key: Option<TextureKey>,
        /// Per-polygon RGBA tint multiplied against the sampled or flat colour.
        tint: [f32; 4],
        /// Blend mode.
        blend: BlendMode,
    },
}

/// Raw RGBA pixel data for a loaded texture, stored in the renderer's texture atlas.
///
/// # Fields
/// - `pixels` — Raw RGBA byte data in RGBA format.
/// - `width` — Texture width in pixels.
/// - `height` — Texture height in pixels.
#[derive(Clone)]
pub struct TextureData {
    pub pixels: Vec<u8>,
    pub width: u32,
    pub height: u32,
}

/// Geometric shape used when rendering a single untextured particle via `DrawParticleSystem`.
///
/// This mirrors `particle::ParticleShape` one-for-one. The particle module converts
/// `ParticleShape` -> `ParticleRenderShape` when building the `DrawParticleSystem` command,
/// keeping the Tier-1 `graphics` module free of an upward Tier-2 import.
///
/// # Variants
/// - `Square` — Axis-aligned filled square.
/// - `Circle` — Filled circle.
/// - `Triangle` — Filled equilateral triangle.
/// - `Spark` — Thin line segment along velocity.
/// - `Diamond` — Filled diamond (square rotated 45°).
/// - `Shrapnel` — Random jagged polygon (deterministic per particle). `edges` = vertex count; `seed` = per-particle RNG seed.
/// - `Ray` — Elongated filled rectangle. `aspect` = length-to-width ratio.
/// - `Puff` — Soft filled circle (more tessellation segments than `Circle`).
/// - `Ring` — Hollow ring (annulus). `thickness` = band width as fraction of size.
/// - `Capsule` — Filled capsule (rectangle + hemispherical caps).
#[derive(Clone, Debug)]
pub enum ParticleRenderShape {
    /// Axis-aligned filled square. Size = side length.
    Square,
    /// Filled circle. Size = diameter.
    Circle,
    /// Filled equilateral triangle rotated by the particle's `rotation` field. Size = circumradius.
    Triangle,
    /// Thin line segment (1 px stroke) oriented along the particle's `rotation` field.
    /// Rendered length = `size * 3.0`.
    Spark,
    /// Filled diamond (square rotated 45 degrees). Size = diagonal length.
    Diamond,
    /// Random jagged polygon with `edges` vertices (3–12). Shape is deterministic from `seed`.
    Shrapnel {
        /// Number of polygon vertices (3–12). Values outside range are clamped.
        edges: u8,
        /// Per-particle seed for deterministic polygon generation. Set once at spawn.
        seed: u32,
    },
    /// Elongated filled rectangle oriented along particle rotation.
    /// `aspect` is the length-to-width ratio (e.g. 4.0 = 4× longer than wide).
    Ray {
        /// Length-to-width ratio. Values ≤ 0 are treated as 4.0.
        aspect: f32,
    },
    /// Soft filled circle with 24 tessellation segments (smoother than `Circle`'s 12).
    Puff,
    /// Hollow ring (annulus). `thickness` is the band width as a fraction of particle size (0–1).
    Ring {
        /// Band width relative to particle size (0–1). Clamped to a minimum of 0.05 in the renderer.
        thickness: f32,
    },
    /// Filled capsule (rectangle with hemispherical caps), oriented along particle rotation.
    Capsule,
}

/// Per-particle render data for a single frame.
///
/// Produced by `ParticleSystem::build_render_commands()` and consumed by the GPU renderer's
/// `DrawParticleSystem` arm. All positions are in world space.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `r` — `f32`.
/// - `g` — `f32`.
/// - `b` — `f32`.
/// - `a` — `f32`.
/// - `rotation` — `f32`.
/// - `size` — `f32`.
/// - `shape` — `ParticleRenderShape`.
/// - `texture_key` — `Option<TextureKey>`.
/// - `quad` — `Option<[f32; 4]>`.
/// - `quad_tex_dims` — `Option<(f32, f32)>`.
#[derive(Clone, Debug)]
pub struct ParticleInstance {
    /// World X position.
    pub x: f32,
    /// World Y position.
    pub y: f32,
    /// Red channel (linear, 0-1).
    pub r: f32,
    /// Green channel (linear, 0-1).
    pub g: f32,
    /// Blue channel (linear, 0-1).
    pub b: f32,
    /// Alpha channel (0-1).
    pub a: f32,
    /// Rotation in radians.
    pub rotation: f32,
    /// Size in pixels (semantics depend on `shape`).
    pub size: f32,
    /// Geometric shape for untextured rendering.
    pub shape: ParticleRenderShape,
    /// Optional texture key; when `Some`, the shape field is ignored and the particle renders as a textured sprite.
    pub texture_key: Option<TextureKey>,
    /// Optional sprite-sheet quad region `[quad_x, quad_y, quad_w, quad_h]`.
    /// Only used when `texture_key` is `Some`.
    pub quad: Option<[f32; 4]>,
    /// Full texture dimensions `(tex_w, tex_h)` for UV normalisation.
    /// Only used when both `texture_key` and `quad` are `Some`.
    pub quad_tex_dims: Option<(f32, f32)>,
}

/// Type discriminator for resources that can be passed to lurek.graphic.draw.
///
/// Used to dispatch the polymorphic draw(drawable, ...) Lua API to the
/// correct RenderCommand variant based on resource type.
///
/// # Variants
/// - Image(TextureKey) — A loaded texture (Image).
/// - Canvas(CanvasKey) — An off-screen render target.
/// - SpriteBatch(SpriteBatchKey) — A batched sprite collection.
/// - Mesh(MeshKey) — A custom geometry mesh.
#[derive(Debug, Clone)]
pub enum DrawableKind {
    /// A loaded texture (Image).
    Image(TextureKey),
    /// An off-screen render target (Canvas).
    Canvas(CanvasKey),
    /// A batched sprite collection.
    SpriteBatch(SpriteBatchKey),
    /// A custom geometry mesh.
    Mesh(MeshKey),
}

/// A single segment of a vector path, used with `RenderCommand::DrawPath`.
///
/// # Variants
/// - `MoveTo` — Move the pen to an absolute position without drawing.
/// - `LineTo` — Draw a straight line to the given position.
/// - `QuadTo` — Draw a quadratic Bézier curve: one control point, one end point.
/// - `CubicTo` — Draw a cubic Bézier curve: two control points, one end point.
#[derive(Clone, Debug)]
pub enum PathSegment {
    /// Move the pen to an absolute position without drawing.
    MoveTo { x: f32, y: f32 },
    /// Draw a straight line to the given position.
    LineTo { x: f32, y: f32 },
    /// Draw a quadratic Bézier curve: one control point, one end point.
    QuadTo { cx: f32, cy: f32, x: f32, y: f32 },
    /// Draw a cubic Bézier curve: two control points, one end point.
    CubicTo { cx1: f32, cy1: f32, cx2: f32, cy2: f32, x: f32, y: f32 },
}

/// Direction for a two-stop linear or radial gradient.
///
/// # Variants
/// - `Horizontal` — Gradient flows left → right.
/// - `Vertical` — Gradient flows top → bottom.
/// - `DiagDown` — Gradient flows top-left → bottom-right.
/// - `DiagUp` — Gradient flows bottom-left → top-right.
/// - `Radial` — Radial gradient expanding from the rectangle centre outward.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum GradientDirection {
    /// Gradient flows left → right.
    Horizontal,
    /// Gradient flows top → bottom.
    Vertical,
    /// Gradient flows top-left → bottom-right.
    DiagDown,
    /// Gradient flows bottom-left → top-right.
    DiagUp,
    /// Radial gradient expanding from the rectangle centre outward.
    Radial,
}

/// Orientation for a hexagonal tile cell.
///
/// # Variants
/// - `PointyTop` — Pointy-top hexagon (flat sides left/right).
/// - `FlatTop` — Flat-top hexagon (flat sides top/bottom).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HexOrientation {
    /// Pointy-top hexagon (flat sides left/right).
    PointyTop,
    /// Flat-top hexagon (flat sides top/bottom).
    FlatTop,
}

/// Visual style for a bevelled rectangle.
///
/// # Variants
/// - `Raised` — Raised 3-D appearance (highlight top-left, shadow bottom-right).
/// - `Sunken` — Sunken 3-D appearance (shadow top-left, highlight bottom-right).
/// - `Ridge` — Double ridge border on all sides.
/// - `Groove` — Double groove border on all sides.
/// - `Flat` — Flat border (same colour all sides).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum BevelStyle {
    /// Raised 3-D appearance (highlight top-left, shadow bottom-right).
    Raised,
    /// Sunken 3-D appearance (shadow top-left, highlight bottom-right).
    Sunken,
    /// Double ridge border on all sides.
    Ridge,
    /// Double groove border on all sides.
    Groove,
    /// Flat border (same colour all sides).
    Flat,
}

/// Per-collider geometry snapshot extracted from the physics world for GPU debug rendering.
///
/// Produced by `physics::World::extract_debug_shapes()` and consumed by
/// `RenderCommand::DrawPhysicsDebug`. Keeping geometry data in this struct prevents the
/// renderer from importing the physics crate.
///
/// # Fields
/// - `x` — `f32`. AABB centre or circle/capsule origin in world space (X axis).
/// - `y` — `f32`. AABB centre or circle/capsule origin in world space (Y axis).
/// - `half_w` — `f32`. Half-width (box) or radius (circle) in world units.
/// - `half_h` — `f32`. Half-height (box) in world units; equal to `half_w` for circles.
/// - `angle` — `f32`. Body rotation in radians.
/// - `is_static` — `bool`. True when the collider belongs to a static body.
/// - `is_sleeping` — `bool`. True when the body is sleeping.
/// - `is_sensor` — `bool`. True when the collider is a sensor (trigger volume).
/// - `hull_verts` — `Vec<[f32; 2]>`. Convex hull vertices in body-local space (empty for box/circle).
/// - `is_circle` — `bool`. True when the shape is a circle (use `half_w` as radius).
#[derive(Clone, Debug)]
pub struct PhysicsDebugShape {
    /// AABB centre or circle/capsule origin in world space.
    pub x: f32,
    /// AABB centre or circle/capsule origin in world space.
    pub y: f32,
    /// Half-width (box) or radius (circle) in world units.
    pub half_w: f32,
    /// Half-height (box) in world units; equal to `half_w` for circles.
    pub half_h: f32,
    /// Body rotation in radians.
    pub angle: f32,
    /// True when the collider belongs to a static body.
    pub is_static: bool,
    /// True when the body is sleeping.
    pub is_sleeping: bool,
    /// True when the collider is a sensor (trigger volume).
    pub is_sensor: bool,
    /// Convex hull vertices in body-local space (empty for box/circle).
    ///
    /// When non-empty the renderer draws this polygon instead of a rectangle or circle.
    pub hull_verts: Vec<[f32; 2]>,
    /// True when the shape is a circle (use `half_w` as radius).
    pub is_circle: bool,
}

/// Appearance parameters for `RenderCommand::DrawPhysicsDebug`.
///
/// # Fields
/// - `body_color` — `[f32; 4]`. Colour for dynamic bodies.
/// - `static_color` — `[f32; 4]`. Colour for static bodies.
/// - `sleep_color` — `[f32; 4]`. Colour for sleeping bodies.
/// - `sensor_color` — `[f32; 4]`. Colour for sensor colliders.
/// - `line_width` — `f32`. Stroke width in screen pixels.
#[derive(Clone, Debug)]
pub struct PhysicsDebugConfig {
    /// Colour for dynamic bodies `[r, g, b, a]`.
    pub body_color: [f32; 4],
    /// Colour for static bodies `[r, g, b, a]`.
    pub static_color: [f32; 4],
    /// Colour for sleeping bodies `[r, g, b, a]`.
    pub sleep_color: [f32; 4],
    /// Colour for sensor colliders `[r, g, b, a]`.
    pub sensor_color: [f32; 4],
    /// Stroke width in screen pixels.
    pub line_width: f32,
}

impl Default for PhysicsDebugConfig {
    fn default() -> Self {
        Self {
            body_color:   [0.0, 1.0, 0.0, 0.8],
            static_color: [0.8, 0.8, 0.8, 0.8],
            sleep_color:  [0.2, 0.6, 1.0, 0.6],
            sensor_color: [1.0, 0.8, 0.0, 0.6],
            line_width:   1.0,
        }
    }
}

/// One textured slot from a Spine skeleton for GPU rendering.
///
/// Produced by the spine CPU module and consumed by `RenderCommand::DrawSpineSkeleton`.
/// Keeps the renderer free of a spine-crate import.
///
/// # Fields
/// - `texture_key` — `TextureKey`. Texture atlas key for this slot's attachment.
/// - `corners` — `[Vec2; 4]`. Four screen-space corner positions: top-left, top-right, bottom-right, bottom-left.
/// - `uvs` — `[Vec2; 4]`. Normalised UV coordinates in the same winding order as `corners`.
/// - `color` — `[f32; 4]`. RGBA tint for this slot.
/// - `blend_mode` — `BlendMode`. Blend mode for this slot.
#[derive(Clone, Debug)]
pub struct SpineSlotDraw {
    /// Texture atlas key for this slot's attachment.
    pub texture_key: TextureKey,
    /// Four screen-space corner positions: top-left, top-right, bottom-right, bottom-left.
    pub corners: [Vec2; 4],
    /// Normalised UV coordinates in the same winding order as `corners`.
    pub uvs: [Vec2; 4],
    /// RGBA tint for this slot `[r, g, b, a]`.
    pub color: [f32; 4],
    /// Blend mode for this slot.
    pub blend_mode: BlendMode,
}
