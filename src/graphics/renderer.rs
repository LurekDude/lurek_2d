//! Draw command types, blend modes, and texture data for the Lurek2D rendering pipeline.
//!
//! This module is part of Lurek2D's `graphics` subsystem and provides the implementation
//! details for renderer-related operations and data management.
//! Key types exported from this module: `CompareMode`, `StencilAction`, `TextAlign`, `DrawMode`, `BlendMode`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::engine::resource_keys::{
    CanvasKey, FontKey, MeshKey, ShaderKey, ShapeKey, SpriteBatchKey, TextureKey,
};
use crate::graphics::image_effect::ShaderPassDescriptor;
use crate::graphics::mesh::Mesh;

/// Stencil comparison mode for `lurek.gfx.setStencilTest`.
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

/// Stencil write action for `lurek.gfx.stencil` and `lurek.gfx.setStencilMode`.
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

/// Depth test comparison mode for `lurek.gfx.setDepthMode`.
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
/// - `Print` — Renders text using the built-in bitmap font.
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
#[derive(Debug, Clone)]
pub enum DrawCommand {
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
        text: String,
        x: f32,
        y: f32,
        scale: f32,
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
    /// Draw text using a loaded TTF font.
    PrintFont {
        /// Key into `SharedState::fonts`.
        font_key: FontKey,
        /// The text string to render.
        text: String,
        /// X position in pixels.
        x: f32,
        /// Y position in pixels.
        y: f32,
        /// Scale multiplier applied to the font's native size.
        scale: f32,
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
    /// The renderer processes the shape's [`crate::graphics::ShapeCommand`] queue wrapped in a
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
    /// appropriate geometry helper for each particle, avoiding N separate top-level `DrawCommand`
    /// dispatches.
    DrawParticleSystem {
        /// Pre-computed per-particle render data for this frame.
        particles: Vec<ParticleInstance>,
    },
    /// Begin capturing the framebuffer for post-processing.
    ///
    /// Subsequent draw calls render into the capture target associated with the named post-FX
    /// stack. Call [`DrawCommand::EndPostFx`] to stop capturing, then
    /// [`DrawCommand::ApplyPostFx`] to composite the effects back onto the screen.
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
    ApplyPostFx {
        /// Identifier for the post-FX stack whose effects will be applied.
        stack_id: u64,
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
/// - `Square` — Square variant.
/// - `Circle` — Circle variant.
/// - `Triangle` — Triangle variant.
/// - `Spark` — Spark variant.
/// - `Diamond` — Diamond variant.
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
}

/// Per-particle render data for a single frame.
///
/// Produced by `ParticleSystem::draw_commands()` and consumed by the GPU renderer's
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

/// Type discriminator for resources that can be passed to lurek.gfx.draw.
///
/// Used to dispatch the polymorphic draw(drawable, ...) Lua API to the
/// correct DrawCommand variant based on resource type.
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
