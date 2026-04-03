//! Draw command types, blend modes, and texture data for the Luna2D rendering pipeline.
//!
//! This module is part of Luna2D's `graphics` subsystem and provides the implementation
//! details for renderer-related operations and data management.
//! Key types exported from this module: `CompareMode`, `StencilAction`, `TextAlign`, `DrawMode`, `BlendMode`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::engine::resource_keys::{
    CanvasKey, FontKey, MeshKey, ShaderKey, SpriteBatchKey, TextureKey,
};
use crate::graphics::mesh::Mesh;

/// Stencil comparison mode for `luna.graphics.setStencilTest`.
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

/// Stencil write action for `luna.graphics.stencil`.
///
/// # Variants
/// - `Replace` — Replace variant.
/// - `Increment` — Increment variant.
/// - `Decrement` — Decrement variant.
/// - `IncrementWrap` — IncrementWrap variant.
/// - `DecrementWrap` — DecrementWrap variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum StencilAction {
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

/// A single deferred draw operation queued during `luna.draw()` and executed by `GpuRenderer`.
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

/// Type discriminator for resources that can be passed to luna.graphics.draw.
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
