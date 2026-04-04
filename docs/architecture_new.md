# Luna2D Architecture

## Overview

Luna2D is a 2D game engine written in Rust that loads and executes Lua game scripts. The engine provides a complete `luna.*` Lua API for graphics, audio, input, physics, windowing, filesystems, math, data processing, particles, and multi-threading. Games consist of a `main.lua` (and optionally `conf.lua`) loaded at startup from a game directory.

**Runtime stack**: winit 0.30 (event loop + windowing) → wgpu 22 (GPU rendering via Vulkan/DX12/Metal) → mlua 0.9 (Lua 5.4 scripting, vendored) → rapier2d 0.32 (physics) → rodio 0.17 (audio).

---

## Table of Contents

1. [Lifecycle and Boot Sequence](#lifecycle-and-boot-sequence)
2. [Game Loop and Frame Model](#game-loop-and-frame-model)
3. [State Architecture](#state-architecture)
4. [Resource Management](#resource-management)
5. [Rendering Pipeline](#rendering-pipeline)
6. [Lua Binding Architecture](#lua-binding-architecture)
7. [Input Pipeline](#input-pipeline)
8. [Audio Pipeline](#audio-pipeline)
9. [Physics Pipeline](#physics-pipeline)
10. [Particle System](#particle-system)
11. [Data, Image, and Sound Modules](#data-image-and-sound-modules)
12. [Filesystem and Virtual FS](#filesystem-and-virtual-fs)
13. [Window Management](#window-management)
14. [Threading Model](#threading-model)
15. [Error Handling and Recovery](#error-handling-and-recovery)
16. [Module Dependency Graph](#module-dependency-graph)
17. [Configuration System](#configuration-system)
18. [Callback Contract](#callback-contract)
19. [DrawCommand Queue Reference](#drawcommand-queue-reference)
20. [Dependencies](#dependencies)
21. [File Structure](#file-structure)
22. [Testing Architecture](#testing-architecture)

---

## Lifecycle and Boot Sequence

```
main.rs
  │
  ├── Parse CLI arguments (game directory path)
  │
  ├── Config::load_from_conf_lua(game_dir)
  │     └── Temporary Lua VM → execute conf.lua → call luna.conf(t) → read back → Config struct
  │
  ├── App::new(config)
  │     ├── Create winit Window (applying WindowConfig: title, size, min size, decorations, icon, display)
  │     ├── Create GpuRenderer (wgpu Instance → Adapter → Device → Surface → pipeline cache)
  │     ├── Create Clock
  │     ├── Create Mixer (rodio OutputStream — headless fallback if no audio device)
  │     ├── Create GameFS (sandboxed to game directory + user save directory)
  │     ├── Create VirtualFS (mount points: game dir, save dir, archives)
  │     └── Create SharedState (Rc<RefCell<SharedState>>)
  │
  ├── create_lua_vm()
  │     ├── Create mlua::Lua VM (StdLib subset — no os, io, loadfile, dofile)
  │     ├── Create `luna` global table
  │     ├── Register 15 API modules (graphics, input, audio, timer, math, physics,
  │     │                             filesystem, window, event, system, particle,
  │     │                             data, image, sound, thread)
  │     └── Each module: register(lua, luna_table, Rc<RefCell<SharedState>>)
  │
  ├── Load game_dir/main.lua (or display splash screen if no game directory)
  │
  ├── Call luna.load()
  │
  └── Enter RunState::Running → game loop
```

If any step fails, the engine transitions to `RunState::Error(ErrorScreen)` (see [Error Handling](#error-handling-and-recovery)).

### No-Game Behavior

When no game directory is provided, the engine displays a built-in splash screen — a crescent moon logo and "LUNA2D" title rendered through the same DrawCommand system. The splash screen runs at 60 FPS until the user closes the window.

---

## Game Loop and Frame Model

The game loop runs inside `App::run()` using winit's `ApplicationHandler` trait. Each frame follows a strict phase sequence:

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRAME START                              │
├─────────────────────────────────────────────────────────────────┤
│ 1. Clock::tick()               → compute dt, update FPS        │
│ 2. Poll input events           → update KeyboardState,         │
│                                   MouseState, GamepadState,     │
│                                   TouchState                    │
│ 3. Fire input callbacks        → keypressed, keyreleased,      │
│                                   textinput, mousepressed,      │
│                                   mousereleased, mousemoved,    │
│                                   wheelmoved, gamepadpressed,   │
│                                   gamepadreleased, gamepadaxis, │
│                                   touchpressed, touchmoved,     │
│                                   touchreleased                 │
│ 4. Fire window callbacks       → focus, visible, resize         │
│ 5. Fire gamepad hotplug        → joystickadded, joystickremoved │
│ 6. Call luna.update(dt)        → game logic                     │
│ 7. Clear draw command queue                                     │
│ 8. Call luna.draw()            → game pushes DrawCommands       │
│ 9. GpuRenderer::render_frame()                                 │
│    ├── Flush pending resource removals (deferred destruction)   │
│    ├── Update auto-uniforms (time, screen size)                 │
│    ├── Acquire swapchain texture                                │
│    ├── Process DrawCommand queue → wgpu render passes           │
│    └── Present surface                                          │
│10. Reset per-frame state       → scroll deltas, pressed/        │
│                                   released arrays, events       │
├─────────────────────────────────────────────────────────────────┤
│                         FRAME END                               │
└─────────────────────────────────────────────────────────────────┘
```

### RunState Machine

```
        ┌──────────┐
        │ Running  │ ◄── normal gameplay
        └────┬─────┘
             │ uncaught error / panic
             ▼
        ┌──────────────────┐
        │ Error(ErrorScreen)│ ◄── blue error screen
        └────┬────────┬────┘
             │        │
     [Escape]│        │[R key]
             ▼        ▼
        ┌────────┐ ┌────────────┐
        │Quitting│ │ Restarting │ → re-run game_dir/main.lua → Running
        └────────┘ └────────────┘
```

- **Running**: Normal game loop.
- **Error(ErrorScreen)**: Renders a blue error screen with the error message using a built-in font. Escape quits, R restarts.
- **Quitting**: Clean shutdown (resource release, audio stop, window close).
- **Restarting**: Tear down Lua VM, re-create SharedState, reload main.lua.

---

## State Architecture

### SharedState

All mutable engine state lives in a single `SharedState` struct, shared between Lua closures and the engine loop via `Rc<RefCell<SharedState>>`. Each Lua closure captures a cloned `Rc`, and borrows the `RefCell` for the duration of the call.

```rust
pub struct SharedState {
    // ── Resource Pools (SlotMap) ──────────────────────────
    pub textures:         SlotMap<TextureKey, TextureData>,
    pub fonts:            SlotMap<FontKey, Font>,
    pub canvases:         SlotMap<CanvasKey, Canvas>,
    pub sprite_batches:   SlotMap<SpriteBatchKey, SpriteBatch>,
    pub meshes:           SlotMap<MeshKey, Mesh>,
    pub shaders:          SlotMap<ShaderKey, Shader>,
    pub particle_systems: SlotMap<ParticleKey, ParticleSystem>,

    // ── Rendering State ──────────────────────────────────
    pub draw_commands:      Vec<DrawCommand>,
    pub current_color:      Color,
    pub background_color:   Color,
    pub current_font:       Option<FontKey>,
    pub current_canvas:     Option<CanvasKey>,
    pub current_shader:     Option<ShaderKey>,
    pub camera:             Camera,
    pub scissor:            Option<Rect>,
    pub color_mask:         (bool, bool, bool, bool),
    pub wireframe:          bool,
    pub point_size:         f32,
    pub default_filter:     FilterMode,

    // ── Input State ──────────────────────────────────────
    pub keyboard:   KeyboardState,
    pub mouse:      MouseState,
    pub gamepads:   Vec<GamepadState>,
    pub touch:      TouchState,

    // ── Subsystems ───────────────────────────────────────
    pub mixer:        Mixer,
    pub clock:        Clock,
    pub game_fs:      GameFS,
    pub virtual_fs:   VirtualFS,
    pub window_state: WindowState,
    pub event_queue:  Vec<EventKind>,
}
```

**Why `Rc<RefCell<>>`**: Lua closures require `'static` lifetimes. `Rc<RefCell<>>` provides shared ownership with runtime borrow checking, eliminating the need for `unsafe` code or raw pointers.

**Why not `Arc<Mutex<>>`**: The main game loop is single-threaded. `Rc<RefCell<>>` has zero synchronization overhead. The threading module (see [Threading Model](#threading-model)) uses separate Lua VMs per thread — they do not share SharedState.

---

## Resource Management

### Generational IDs via SlotMap

All engine resources (textures, fonts, canvases, meshes, shaders, audio sources, particle systems) are stored in typed `SlotMap<K, V>` pools. SlotMap provides:

- **O(1) insert, remove, lookup** with generation checking
- **Use-after-free prevention**: stale keys (from released resources) return `None`, never access wrong data
- **Dense iteration**: cache-friendly for per-frame operations
- **No hash overhead**: keys are plain integers + generation counter

### Typed Resource Keys

All keys are defined in `src/engine/resource_keys.rs`:

```rust
new_key_type! {
    pub struct TextureKey;
    pub struct FontKey;
    pub struct CanvasKey;
    pub struct SoundKey;
    pub struct ParticleKey;
    pub struct SpriteBatchKey;
    pub struct MeshKey;
    pub struct ShaderKey;
    pub struct PhysicsWorldKey;
    pub struct PhysicsBodyKey;
}
```

Compile-time type safety: a `TextureKey` cannot be passed where a `FontKey` is expected. Function signatures document which resource type they operate on.

### Lua-Side Representation

Resources are exposed to Lua as `UserData` objects (see [Lua Binding Architecture](#lua-binding-architecture)). Each UserData wrapper holds the typed key internally:

```rust
struct LuaImage(TextureKey);
impl UserData for LuaImage { /* methods: getWidth, getHeight, etc. */ }
```

### Resource Lifecycle

```
   Lua: local img = luna.graphics.newImage("player.png")
                         │
                         ▼
   Rust: load pixels → insert into textures SlotMap → upload to GPU
         → return LuaImage(TextureKey) as UserData to Lua
                         │
                         ▼
   Lua: luna.graphics.draw(img, 100, 200)
                         │
                         ▼
   Rust: push DrawImage { texture_key, ... } into draw_commands
                         │
                         ▼
   Lua: img:release()    OR    garbage collection
                         │
                         ▼
   Rust: remove from SlotMap → queue GPU resource for deferred destruction
```

### Deferred GPU Destruction

GPU resources (textures, canvases, shader pipelines) cannot be freed during an active render pass. When `release()` is called, the key is added to a pending removal queue. At the start of the next frame, before encoding new commands, `GpuRenderer::flush_pending_removals()` processes the queue.

```rust
pub struct GpuRenderer {
    gpu_textures:              SlotMap<TextureKey, GpuTexture>,
    canvas_gpu_textures:       SlotMap<CanvasKey, GpuTexture>,
    pending_texture_removals:  Vec<TextureKey>,
    pending_canvas_removals:   Vec<CanvasKey>,
    // ...
}
```

---

## Rendering Pipeline

### GPU Renderer (Primary)

The primary renderer uses wgpu to submit draw commands to the system GPU (Vulkan, DX12, Metal, or OpenGL fallback).

```
GpuRenderer
├── wgpu::Instance
├── wgpu::Adapter
├── wgpu::Device + Queue
├── wgpu::Surface (swapchain)
├── Pipeline Cache
│   ├── Color pipelines       (5 blend modes × 2 wireframe states)
│   ├── Texture pipelines     (5 blend modes × 2 wireframe states)
│   ├── Stencil pipelines     (write mode, test mode)
│   ├── Color mask variants   (lazily created, cached)
│   └── Custom shader pipelines (per Shader object)
├── Depth/Stencil Texture     (Depth24PlusStencil8, window-sized)
├── gpu_textures              SlotMap<TextureKey, GpuTexture>
├── canvas_gpu_textures       SlotMap<CanvasKey, GpuTexture>
├── font_atlas_textures       SlotMap<FontKey, GpuTexture>
└── Vertex Buffer (dynamic)
```

### Embedded Shaders

Two WGSL shaders are embedded in the binary:

- **COLOR_SHADER** — Solid-color geometry (position + color per vertex)
- **TEXTURE_SHADER** — Textured sprites (position + UV + color tint)

### Custom Shaders (WGSL)

Users can provide custom fragment shaders (or vertex + fragment pairs) in WGSL. The engine:

1. Prepends a standard header with auto-updated globals (`luna_ScreenSize`, `luna_Time`)
2. Validates the source with naga (bundled in wgpu)
3. Creates a dedicated `wgpu::RenderPipeline` for the shader
4. Manages a uniform buffer and bind group per shader, rebuilt when uniforms change

```rust
pub struct Shader {
    pipeline:          wgpu::RenderPipeline,
    bind_group_layout: wgpu::BindGroupLayout,
    uniforms:          HashMap<String, UniformValue>,
    uniform_buffer:    wgpu::Buffer,
    bind_group:        wgpu::BindGroup,
    dirty:             bool,
    source:            String,
}

pub enum UniformValue {
    Float(f32), Vec2([f32; 2]), Vec3([f32; 3]), Vec4([f32; 4]),
    Mat3([[f32; 3]; 3]), Mat4([[f32; 4]; 4]),
    Int(i32), Bool(bool), Texture(TextureKey),
}
```

### Render-to-Texture (Canvas)

Off-screen rendering uses canvas textures with `TextureUsages::RENDER_ATTACHMENT | TEXTURE_BINDING`. The `SetCanvas` draw command switches the render target:

```
SetCanvas(Some(canvas_key))  → end screen pass, begin canvas pass (canvas texture view)
     ↓ (subsequent draws render to canvas)
SetCanvas(None)              → end canvas pass, resume screen pass
     ↓
DrawImage(canvas_key, ...)   → draw canvas as a textured quad on screen
```

### Stencil and Scissor

- **Scissor**: `wgpu::RenderPass::set_scissor_rect()`. Saved/restored with transform stack push/pop.
- **Stencil**: Requires a `Depth24PlusStencil8` texture attachment. Stencil write + test use separate pipeline variants.

### Mesh Rendering

Custom geometry via the Mesh API:

```rust
pub struct Mesh {
    vertices:      Vec<MeshVertex>,    // position + UV + color per vertex
    indices:       Option<Vec<u32>>,
    texture:       Option<TextureKey>,
    draw_mode:     MeshDrawMode,       // Triangles, TriangleFan, TriangleStrip, Points
    vertex_buffer: Option<wgpu::Buffer>,
    index_buffer:  Option<wgpu::Buffer>,
    dirty:         bool,
}

#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct MeshVertex {
    pub position: [f32; 2],
    pub uv:       [f32; 2],
    pub color:    [f32; 4],
}
```

### Blend Modes

Five blend modes, each with a pre-built pipeline:

| Mode | Operation |
|---|---|
| `alpha` | Standard alpha blending (default) |
| `add` | Additive blending (particles, glow) |
| `multiply` | Multiplicative blending (shadows) |
| `replace` | No blending (overwrite) |
| `screen` | Screen blending (lightening) |

### Transform Stack

Affine transforms managed via a push/pop stack. Each entry stores translation, rotation, scale, shear, and scissor state. Reset with `origin()`.

### Legacy CPU Renderer

`renderer.rs` contains a tiny-skia + minifb software renderer path. Kept as a fallback for systems without GPU support. Not actively developed.

---

## Lua Binding Architecture

### UserData Object Model

All major resource types are exposed to Lua as `mlua::UserData` objects, providing an object-oriented API:

```lua
local img = luna.graphics.newImage("player.png")
img:getWidth()      -- method call on UserData
img:getHeight()
img:release()

local source = luna.audio.newSource("music.ogg", "stream")
source:play()
source:setVolume(0.8)
source:setLooping(true)
```

### UserData Types

| Lua Type | Rust Struct | Key Type | Module |
|---|---|---|---|
| Image | `LuaImage` | `TextureKey` | graphics |
| Font | `LuaFont` | `FontKey` | graphics |
| Canvas | `LuaCanvas` | `CanvasKey` | graphics |
| SpriteBatch | `LuaSpriteBatch` | `SpriteBatchKey` | graphics |
| Mesh | `LuaMesh` | `MeshKey` | graphics |
| Shader | `LuaShader` | `ShaderKey` | graphics |
| Quad | `LuaQuad` | — (value type) | graphics |
| Source | `LuaSource` | `SoundKey` | audio |
| World | `LuaWorld` | `PhysicsWorldKey` | physics |
| Body | `LuaBody` | `PhysicsBodyKey` | physics |
| ParticleSystem | `LuaParticleSystem` | `ParticleKey` | particle |
| RandomGenerator | `LuaRandomGenerator` | — (owned) | math |
| Transform | `LuaTransform` | — (owned) | math |
| BezierCurve | `LuaBezierCurve` | — (owned) | math |
| ByteData | `LuaByteData` | — (owned) | data |
| ImageData | `LuaImageData` | — (owned) | image |
| SoundData | `LuaSoundData` | — (owned) | sound |
| FileHandle | `LuaFileHandle` | — (owned) | filesystem |
| Channel | `LuaChannel` | — (shared) | thread |

### LunaType Trait

All UserData types implement a shared `LunaType` trait that provides:

```rust
pub trait LunaType {
    fn type_name() -> &'static str;
}

pub fn add_type_methods<T: LunaType>(methods: &mut impl UserDataMethods<T>) {
    methods.add_method("type", |_, _, ()| Ok(T::type_name()));
    methods.add_method("typeOf", |_, _, ()| Ok(T::type_name()));
    methods.add_meta_method("__tostring", |_, this, ()| Ok(format!("{}: {:p}", T::type_name(), this)));
}
```

### Drawable Protocol

Types that implement the Drawable protocol can be passed to `luna.graphics.draw()`:

- Image, Canvas, SpriteBatch, Mesh, ParticleSystem

The `draw()` function inspects the UserData type at runtime and pushes the appropriate `DrawCommand` variant.

### Registration Pattern

Every API module follows the same signature:

```rust
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let module = lua.create_table()?;
    // Clone Rc before moving into each closure
    let state_clone = Rc::clone(&state);
    module.set("functionName", lua.create_function(move |lua, args| {
        let mut s = state_clone.borrow_mut();
        // ... implementation
    })?)?;
    luna.set("module_name", module)?;
    Ok(())
}
```

### API Namespace

All bindings live under `luna.*`. The engine registers 15 namespaces:

| Namespace | Module | Scope |
|---|---|---|
| `luna.graphics` | graphics_api.rs | Drawing, images, fonts, canvases, meshes, shaders |
| `luna.audio` | audio_api.rs | Sound loading, playback, volume, pitch |
| `luna.keyboard` | input_api.rs | Key state, scancodes, text input |
| `luna.mouse` | input_api.rs | Position, buttons, cursor, scroll, grab |
| `luna.gamepad` | input_api.rs | Joystick state, buttons, axes, vibration |
| `luna.touch` | input_api.rs | Touch points, pressure |
| `luna.timer` | timer_api.rs | Delta time, FPS, sleep |
| `luna.math` | math_api.rs | Trig, random, noise, transforms, Bezier, triangulation |
| `luna.physics` | physics_api.rs | Worlds, bodies, shapes, joints, raycasting |
| `luna.filesystem` | filesystem_api.rs | Sandboxed I/O, directories, archive mounting |
| `luna.window` | window_api.rs | Fullscreen, VSync, display info, DPI, clipboard |
| `luna.event` | event_api.rs | Event queue, quit, push/poll/clear |
| `luna.system` | system_api.rs | OS info, processor count, openURL, locales |
| `luna.particle` | particle_api.rs | Particle emitters, configuration, rendering |
| `luna.data` | data_api.rs | Binary data, compression, hashing, encoding |
| `luna.image` | image_api.rs | CPU pixel buffers, pixel manipulation |
| `luna.sound` | sound_api.rs | Decoded PCM audio samples |
| `luna.thread` | thread_api.rs | Worker threads, channels |

---

## Input Pipeline

### Data Flow

```
winit WindowEvent
  │
  ├── KeyEvent
  │     ├── logical_key  → KeyboardState.keys_down (layout-dependent)
  │     ├── physical_key → KeyboardState.scancodes_down (layout-independent)
  │     ├── is_repeat    → filtered by key_repeat_enabled flag
  │     └── fire luna.keypressed(key, scancode, isrepeat) / luna.keyreleased(key, scancode)
  │
  ├── Ime(Commit(text))
  │     └── fire luna.textinput(text)
  │
  ├── CursorMoved
  │     ├── update MouseState position
  │     └── fire luna.mousemoved(x, y, dx, dy, istouch)
  │
  ├── MouseInput
  │     ├── update MouseState.buttons[0..5]
  │     └── fire luna.mousepressed/mousereleased(x, y, button, istouch, presses)
  │
  ├── MouseWheel
  │     ├── accumulate MouseState.scroll_x/scroll_y
  │     └── fire luna.wheelmoved(x, y)
  │
  ├── Touch { id, phase, location, force }
  │     ├── update TouchState.touches HashMap
  │     └── fire luna.touchpressed/moved/released(id, x, y, dx, dy, pressure)
  │
  ├── Focused(focused) → update WindowState.focused → fire luna.focus(focused)
  ├── Occluded(occ)    → update WindowState.visible → fire luna.visible(!occ)
  └── Resized(size)    → update WindowState, reconfigure wgpu surface → fire luna.resize(w, h)

gilrs events (polled per frame)
  │
  ├── ButtonChanged → GamepadState.buttons → fire luna.gamepadpressed/released
  ├── AxisChanged   → GamepadState.axes    → fire luna.gamepadaxis
  ├── Connected     → gamepads.push()      → fire luna.joystickadded(id)
  └── Disconnected  → gamepads.remove()    → fire luna.joystickremoved(id)
```

### Input State Structs

```rust
pub struct KeyboardState {
    keys_down:          HashSet<String>,     // logical keys currently held
    scancodes_down:     HashSet<String>,     // physical keys currently held
    keys_pressed:       Vec<String>,         // pressed this frame
    keys_released:      Vec<String>,         // released this frame
    scancodes_pressed:  Vec<String>,
    scancodes_released: Vec<String>,
    key_repeat_enabled: bool,                // default: false
    text_input_enabled: bool,
}

pub struct MouseState {
    x: f64, y: f64,
    buttons:          [bool; 5],             // left, right, middle, x1, x2
    buttons_pressed:  [bool; 5],
    buttons_released: [bool; 5],
    visible:  bool,
    grabbed:  bool,
    relative_mode: bool,
    scroll_x: f64, scroll_y: f64,           // per-frame delta
    cursor_type: SystemCursor,
}

pub struct GamepadState {
    buttons: HashMap<String, bool>,          // "a", "b", "x", "y", "start", etc.
    axes:    HashMap<String, f32>,           // "leftx", "lefty", "rightx", "righty"
    name:    String,
    connected: bool,
}

pub struct TouchState {
    touches: HashMap<u64, TouchPoint>,       // active touch points
}

pub struct TouchPoint {
    pub id: u64,
    pub x: f64, pub y: f64,
    pub pressure: f64,                       // 0.0..=1.0
}
```

---

## Audio Pipeline

### Architecture

```
luna.audio.newSource("file.ogg", "stream")
  │
  ▼
AudioSource struct
├── path: String
├── source_type: SourceType (Static | Stream)
├── decoded_data: Option<Arc<Vec<u8>>>    ← Static: pre-decoded, Arc-shared for cloning
├── volume: f32                           ← per-source volume
├── pitch: f32
├── pan: f32                              ← -1.0 (left) .. 1.0 (right)
├── looping: bool
└── play_state: PlayState                 ← Stopped | Playing | Paused

Mixer
├── output_stream: rodio::OutputStream
├── stream_handle: rodio::OutputStreamHandle
├── sources: SlotMap<SoundKey, AudioEntry>
│   └── AudioEntry { source: AudioSource, sink: Option<rodio::Sink>, playback: PlaybackState }
├── master_volume: f32                    ← scales all sinks
└── headless: bool                        ← true if no audio device
```

### Source Types

| Type | Loading | Memory | Latency | Use Case |
|---|---|---|---|---|
| **Static** | Decode entire file to `Vec<u8>` | Higher | Low (no decode at play time) | Short SFX |
| **Stream** | Open file, decode on-the-fly | Low | Slight (decode overhead) | Music, ambience |

### Playback Position Tracking

rodio's Sink does not expose seek position natively. Luna2D tracks position manually:

```rust
pub struct PlaybackState {
    start_time:  Instant,
    paused_at:   Option<Duration>,
    seek_offset: Duration,
}
// current_position = (now - start_time) + seek_offset (adjusted for pauses)
```

### Source Cloning

`source:clone()` creates a new audio source with independent playback state. For Static sources, the decoded data is shared via `Arc<Vec<u8>>` (zero-copy).

---

## Physics Pipeline

### Architecture

```
luna.physics.newWorld(gx, gy)
  │
  ▼
World struct
├── rapier2d::PhysicsPipeline
├── rapier2d::RigidBodySet
├── rapier2d::ColliderSet
├── rapier2d::ImpulseJointSet
├── rapier2d::MultibodyJointSet
├── rapier2d::IslandManager
├── rapier2d::BroadPhaseMultiSap
├── rapier2d::NarrowPhase
├── rapier2d::CCDSolver
├── gravity: Vec2
├── contact_events: Vec<ContactEvent>    ← collision callback queue
└── bodies: SlotMap<PhysicsBodyKey, Body>
```

### Body Sync-Buffer Pattern

The `Body` struct is a user-visible data buffer. It decouples Lua from rapier2d internals:

```
Lua script sets body position/velocity/angle
    │
    ▼
Body struct (buffer) ── fields written by Lua
    │
    ▼ (at start of World::step())
rapier2d RigidBody ── sync from buffer → simulate
    │
    ▼ (after World::step())
Body struct (buffer) ── read back dynamic body state
    │
    ▼
Lua script reads updated body position
```

### Shapes and Fixtures

Bodies can have multiple colliders (fixtures), each with its own shape:

| Shape | rapier2d Type |
|---|---|
| Rectangle (AABB) | `Cuboid` |
| Circle | `Ball` |
| Polygon (convex) | `ConvexPolygon` |
| Edge (line segment) | `Segment` |
| Chain (polyline) | `Polyline` |

Each fixture has independent: density, friction, restitution, sensor flag, collision category/mask.

### Joint Types

11 joint types connecting body pairs:

Distance, Revolute, Prismatic, Weld, Wheel, Pulley, Gear, Friction, Motor, Rope, Mouse.

### Raycasting and Queries

```lua
local hits = world:rayCast(x1, y1, x2, y2)           -- all intersections
local hit  = world:rayCastClosest(x1, y1, x2, y2)    -- nearest
local any  = world:rayCastAny(x1, y1, x2, y2)        -- boolean
local bodies = world:queryBoundingBox(x, y, w, h)     -- AABB query
```

### Collision Callbacks

```lua
world:setCallbacks({
    beginContact = function(a, b, contact) end,
    endContact   = function(a, b, contact) end,
    preSolve     = function(a, b, contact) end,
    postSolve    = function(a, b, contact, impulse) end,
})
```

---

## Particle System

### Architecture

```rust
pub struct ParticleSystem {
    config:      ParticleConfig,    // ~35 configurable fields
    particles:   Vec<Particle>,
    texture:     Option<TextureKey>,
    position:    Vec2,
    state:       EmitterState,      // Playing | Paused | Stopped
    time_acc:    f32,               // emission accumulator
    count:       usize,            // active particle count
}

pub struct Particle {
    position: Vec2,
    velocity: Vec2,
    acceleration: Vec2,
    angle: f32,
    angular_velocity: f32,
    lifetime: f32,
    age: f32,
    size_start: f32, size_end: f32,
    color_start: Color, color_end: Color,
    // Multi-stop interpolation via keyframe arrays
    size_keys:  Option<Vec<(f32, f32)>>,    // (time_fraction, size)
    color_keys: Option<Vec<(f32, Color)>>,  // (time_fraction, color)
}
```

### ParticleConfig (~35 fields)

| Category | Fields |
|---|---|
| Emission | rate, burst_count, insert_mode (Top/Bottom/Random) |
| Lifetime | min/max lifetime |
| Speed | min/max speed, radial acceleration, tangential acceleration |
| Direction | direction angle, spread angle |
| Size | start/end sizes, size variation, size keyframes (N-point) |
| Color | start/end colors, color keyframes (N-point) |
| Rotation | min/max rotation, min/max spin |
| Physics | linear acceleration, linear damping, gravity scale |
| Area | area_distribution (Point, Uniform, Normal, Ellipse, BorderRect, BorderEllipse) |

### Emission Areas

```rust
pub enum AreaDistribution {
    Point,                                    // all particles from center
    Uniform(f32, f32),                        // random within rectangle
    Normal(f32, f32, f32),                    // Gaussian distribution
    Ellipse(f32, f32),                        // within ellipse
    BorderRect(f32, f32),                     // along rectangle edge
    BorderEllipse(f32, f32),                  // along ellipse perimeter
}
```

### Rendering

Particle systems push `DrawCommand::DrawParticleSystem { particle_key }` during `luna.draw()`. The renderer iterates active particles and draws each as a textured quad (if texture is set) or colored point/circle.

---

## Data, Image, and Sound Modules

### luna.data — Binary Data Processing

```
src/data/
├── byte_data.rs   ← ByteData: contiguous byte buffer
├── compress.rs    ← deflate/gzip/lz4/zlib (flate2 + lz4_flex)
├── hash.rs        ← md5/sha1/sha256/sha512 (sha2 + md-5)
├── encode.rs      ← base64/hex encoding/decoding
└── mod.rs
```

**ByteData**: A `Vec<u8>` accessible from Lua for binary data manipulation, compression input/output, and C interop.

### luna.image — CPU Pixel Manipulation

```rust
pub struct ImageData {
    width:  u32,
    height: u32,
    pixels: Vec<u8>,  // RGBA8, 4 bytes per pixel, row-major
}
```

Supports `getPixel`, `setPixel`, `mapPixel` (per-pixel transform callback), `paste`, and `encode("png")`. ImageData can be uploaded to the GPU to create a texture: `luna.graphics.newImage(imageData)`.

### luna.sound — Decoded Audio Samples

```rust
pub struct SoundData {
    samples:     Vec<f32>,   // interleaved PCM
    sample_rate: u32,
    channels:    u16,        // 1 (mono) or 2 (stereo)
    bit_depth:   u16,
}
```

Supports per-sample access (`getSample`, `setSample`), metadata queries, and creating audio Sources from SoundData for playback.

---

## Filesystem and Virtual FS

### GameFS (Sandboxed I/O)

`GameFS` provides path-traversal-protected file operations. All paths are resolved relative to the game directory or save directory, with `..` traversal blocked.

### VirtualFS (Archive Mounting)

```rust
pub struct VirtualFS {
    mount_points: Vec<MountPoint>,
}

pub enum MountPoint {
    Directory(PathBuf),          // physical directory
    Archive(PathBuf, ZipArchive), // .zip file (via zip crate)
}
```

File reads search mount points in reverse order (last mounted = highest priority). This enables mod support and DLC patterns.

### FileHandle

```rust
pub struct FileHandle {
    mode: FileMode,              // Read | Write | Append | Closed
    // internal reader/writer
}

pub enum FileMode { Read, Write, Append, Closed }
```

Lua API: `luna.filesystem.newFile(path, mode)` returns a FileHandle UserData with `read()`, `write()`, `lines()`, `close()`, `isOpen()`, `getMode()` methods.

---

## Window Management

### WindowState

```rust
pub struct WindowState {
    pub focused:       bool,
    pub mouse_focused: bool,
    pub minimized:     bool,
    pub maximized:     bool,
    pub visible:       bool,
    pub fullscreen:    bool,
    pub fullscreen_type: FullscreenType,  // Desktop (borderless) | Exclusive
    pub width:  u32,
    pub height: u32,
    pub dpi_scale: f64,
}
```

### Runtime Capabilities

| Feature | Implementation |
|---|---|
| Fullscreen toggle | `winit::Window::set_fullscreen()` (borderless or exclusive) |
| VSync control | wgpu `PresentMode` (Fifo / Immediate / Mailbox) + surface reconfigure |
| DPI scaling | `window.scale_factor()`, `toPixels()`/`fromPixels()` conversion |
| Window icon | Load image → `winit::window::Icon` → `window.set_window_icon()` |
| Clipboard | `arboard` crate — get/set clipboard text |
| Message boxes | Platform message box dialogs |
| Display info | `EventLoop::available_monitors()` → count, dimensions, video modes |

---

## Threading Model

### Design Principle

The main game loop and all Lua callbacks run on a single thread. The threading module provides worker threads with **separate Lua VMs** — they do not share SharedState.

### Architecture

```
Main Thread
├── Lua VM (full luna.* API)
├── SharedState (Rc<RefCell<>>)
├── GpuRenderer
└── Game Loop

Worker Thread 1                      Worker Thread 2
├── Separate Lua VM                  ├── Separate Lua VM
├── Thread-safe modules ONLY:        ├── Thread-safe modules ONLY:
│   math, thread, timer (read),      │   math, thread, timer (read),
│   filesystem (read), system        │   filesystem (read), system
└── Channel ◄──────────────────────► └── Channel

                    ▲
                    │ Channel (thread-safe)
                    ▼
              Main Thread
```

### Channel

Inter-thread communication via typed, thread-safe MPMC channels:

```rust
pub struct Channel {
    name:  String,
    queue: Arc<Mutex<VecDeque<ChannelValue>>>,
    cond:  Arc<Condvar>,
}

pub enum ChannelValue {
    Nil,
    Bool(bool),
    Number(f64),
    String(String),
}
```

Operations: `push(value)`, `pop()`, `demand()` (blocking pop), `peek()`, `getCount()`, `clear()`.

### Thread-Safety Boundary

| Module | Worker Thread Access |
|---|---|
| `luna.math` | Full — stateless functions |
| `luna.thread` | Full — channel operations |
| `luna.timer` | Read-only — getTime, getMicroTime |
| `luna.filesystem` | Read-only — file reading |
| `luna.system` | Full — getOS, getProcessorCount |
| `luna.graphics` | **NOT available** — GPU is single-threaded |
| `luna.audio` | **NOT available** — rodio OutputStream is thread-bound |
| `luna.window` | **NOT available** — winit is main-thread |
| `luna.input` | **NOT available** — tied to SharedState |
| `luna.physics` | **NOT available** — rapier2d is not Send |

---

## Error Handling and Recovery

### EngineError

```rust
#[derive(Debug, thiserror::Error)]
pub enum EngineError {
    #[error("Config error: {0}")]
    Config(String),
    #[error("Lua error: {0}")]
    Lua(#[from] mlua::Error),
    #[error("Graphics error: {0}")]
    Graphics(String),
    #[error("Audio error: {0}")]
    Audio(String),
    #[error("Physics error: {0}")]
    Physics(String),
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Image error: {0}")]
    Image(String),
    #[error("Window error: {0}")]
    Window(String),
    #[error("Font error: {0}")]
    Font(String),
    #[error("Timer error: {0}")]
    Timer(String),
    #[error("Filesystem error: {0}")]
    Filesystem(String),
    #[error("Resource not loaded: {0}")]
    ResourceNotLoaded(String),
}
```

### Error Flow

```
Lua runtime error during luna.update() or luna.draw()
  │
  ├── Check: is luna.errorhandler(msg) defined?
  │     ├── YES → call luna.errorhandler(msg)
  │     │         ├── returns replacement message → display it
  │     │         └── errors itself → use original message
  │     └── NO → use raw error message
  │
  ▼
Transition to RunState::Error(ErrorScreen)
  │
  ├── ErrorScreen renders:
  │   ├── Blue background (#1e3a5f)
  │   ├── "Error" heading (built-in font, white)
  │   ├── Formatted stack trace (cleaned [string "..."] markers)
  │   ├── "Press Escape to quit or R to restart"
  │   └── Minimal input handling (Escape/R only)
  │
  ├── [Escape] → RunState::Quitting → clean shutdown
  └── [R]      → RunState::Restarting → reload main.lua → Running
```

### conf.lua Errors

If `conf.lua` fails to parse or `luna.conf(t)` errors, the engine shows the error screen rather than crashing. The game can still be restarted.

### Missing main.lua

If no `main.lua` is found in the game directory, the engine displays a "No game found" message on the splash screen instead of crashing.

### Panic Hook

On Windows, `std::panic::catch_unwind()` wraps the game loop. On panic, a message box is shown with the panic message before the process exits.

### Lua Error Context

All Lua-callable functions include the function name in error messages:

```rust
Err(LuaError::RuntimeError(format!(
    "luna.graphics.draw: texture key {:?} is no longer valid", key
)))
```

---

## Module Dependency Graph

```
                     ┌──────────┐
                     │  engine  │ ◄── depended on by all modules
                     │          │     (Config, EngineError,
                     │          │      resource_keys, RunState)
                     └──┬───┬──┘
                        │   │
            ┌───────────┘   └───────────┐
            ▼                           ▼
      ┌───────────┐              ┌───────────┐
      │  lua_api   │              │    math    │ ◄── depended on by
      │            │              │            │     physics, graphics,
      │ (15 files) │              │ (Vec2,Mat3,│     particle, input
      │            │              │  Rect,etc) │
      └──────┬─────┘              └────────────┘
             │ depends on all domain modules:
             ▼
    ┌─────────────────────────────────────────────────┐
    │  graphics  audio  input  physics  timer         │
    │  filesystem  particle  window  data  image      │
    │  sound                                          │
    │                                                 │
    │  Domain modules DO NOT depend on each other     │
    │  (except through math)                          │
    └─────────────────────────────────────────────────┘
```

### Dependency Rules

1. **`engine`** may be depended upon by all modules. Contains Config, EngineError, resource keys.
2. **`math`** is a foundation module. Other domain modules may depend on it (Vec2, Rect, Mat3).
3. **`lua_api`** depends on `engine` and all domain modules. It is the bridge between Lua and Rust.
4. **Domain modules** (`graphics`, `audio`, `input`, `physics`, `timer`, `filesystem`, `particle`, `window`, `data`, `image`, `sound`) must **NOT** depend on each other (except through `math`).
5. **No circular dependencies** — the graph is a DAG.

---

## Configuration System

### Config Struct

```rust
pub struct Config {
    pub window:      WindowConfig,
    pub modules:     ModulesConfig,
    pub performance: PerformanceConfig,
    pub identity:    Option<String>,       // save directory name
    pub version:     Option<String>,       // target engine version
}

pub struct WindowConfig {
    pub width:         u32,
    pub height:        u32,
    pub title:         String,
    pub vsync:         bool,
    pub fullscreen:    bool,
    pub resizable:     bool,
    pub min_width:     Option<u32>,
    pub min_height:    Option<u32>,
    pub borderless:    bool,
    pub icon:          Option<String>,     // path to icon image
    pub display_index: u32,
}

pub struct ModulesConfig {
    pub audio:      bool,
    pub physics:    bool,
    pub graphics:   bool,
    pub input:      bool,
    pub timer:      bool,
    pub filesystem: bool,
}

pub struct PerformanceConfig {
    pub target_fps: u32,
}
```

### conf.lua Processing

```
main.rs
  │
  ├── Create temporary Lua VM (separate from game VM)
  ├── Build Lua table `t` with all defaults
  ├── Execute conf.lua
  ├── Call luna.conf(t) if defined
  ├── Read values back into Config struct
  │   ├── t.window.title → Config.window.title
  │   ├── t.window.width → Config.window.width
  │   ├── ...
  │   ├── t.identity → Config.identity
  │   └── t.version → Config.version
  ├── Destroy temporary VM
  └── Return Config
```

---

## Callback Contract

The engine fires Lua callbacks at specific lifecycle points. All callbacks are optional — the engine checks if the function exists before calling it.

| Callback | Arguments | When Fired |
|---|---|---|
| `luna.conf(t)` | config table | During conf.lua processing (before window) |
| `luna.load()` | — | Once after main.lua loads |
| `luna.update(dt)` | delta time (seconds) | Every frame |
| `luna.draw()` | — | Every frame (push DrawCommands here) |
| `luna.keypressed(key, scancode, isrepeat)` | key name, scancode, repeat flag | Key press |
| `luna.keyreleased(key, scancode)` | key name, scancode | Key release |
| `luna.textinput(text)` | Unicode text | Character input (IME) |
| `luna.mousepressed(x, y, btn, istouch, presses)` | position, button, touch flag, click count | Mouse button down |
| `luna.mousereleased(x, y, btn, istouch, presses)` | position, button, touch flag, click count | Mouse button up |
| `luna.mousemoved(x, y, dx, dy, istouch)` | position, delta, touch flag | Mouse movement |
| `luna.wheelmoved(x, y)` | scroll deltas | Scroll wheel |
| `luna.gamepadpressed(id, button)` | gamepad ID, button name | Gamepad button down |
| `luna.gamepadreleased(id, button)` | gamepad ID, button name | Gamepad button up |
| `luna.gamepadaxis(id, axis, value)` | gamepad ID, axis name, value | Gamepad axis change |
| `luna.joystickadded(id)` | gamepad ID | Gamepad connected |
| `luna.joystickremoved(id)` | gamepad ID | Gamepad disconnected |
| `luna.touchpressed(id, x, y, dx, dy, pressure)` | touch ID, position, delta, pressure | Touch start |
| `luna.touchmoved(id, x, y, dx, dy, pressure)` | touch ID, position, delta, pressure | Touch move |
| `luna.touchreleased(id, x, y, dx, dy, pressure)` | touch ID, position, delta, pressure | Touch end |
| `luna.focus(focused)` | boolean | Window focus change |
| `luna.visible(visible)` | boolean | Window visibility change |
| `luna.resize(w, h)` | new dimensions | Window resize |
| `luna.quit()` | — | Close requested (return `true` to cancel) |
| `luna.errorhandler(msg)` | error message | Uncaught Lua error |

---

## DrawCommand Queue Reference

The `DrawCommand` enum defines all rendering operations that Lua can request:

### Shape Drawing
`Rectangle`, `RoundedRectangle`, `Circle`, `Ellipse`, `Triangle`, `Arc`, `Polygon`, `Line`, `Polyline`, `Points`

### Resource Drawing
`DrawImage { texture_key, x, y, rotation, sx, sy, ox, oy, quad }`,
`DrawCanvas { canvas_key, ... }`,
`DrawMesh { mesh_key, x, y, rotation, sx, sy, ox, oy }`,
`DrawSpriteBatch { batch_key }`,
`DrawParticleSystem { particle_key }`

### Text
`Print { font_key, text, x, y, scale }`,
`PrintFormatted { font_key, text, x, y, limit, align, scale }`

### State Changes
`SetColor(Color)`, `SetBackgroundColor(Color)`,
`SetCanvas(Option<CanvasKey>)`, `SetShader(Option<ShaderKey>)`,
`SetScissor(Option<Rect>)`, `SetColorMask(bool, bool, bool, bool)`,
`SetLineWidth(f32)`, `SetPointSize(f32)`, `SetWireframe(bool)`

### Stencil
`StencilBegin { action, value }`, `StencilEnd`, `SetStencilTest(Option<StencilTest>)`

### Transforms
`PushTransform`, `PopTransform`, `Translate(f32, f32)`, `Rotate(f32)`, `Scale(f32, f32)`, `Shear(f32, f32)`, `Origin`, `ApplyTransform(TransformKey)`

### Other
`Clear(Color)`

---

## Dependencies

| Crate | Version | Purpose |
|---|---|---|
| wgpu | 22 | Primary GPU rendering (Vulkan/DX12/Metal) |
| winit | 0.30 | Cross-platform windowing, event loop, input |
| mlua | 0.9 | Lua 5.4 scripting (lua54 + vendored + send) |
| rapier2d | 0.32 | 2D rigid-body physics simulation |
| rodio | 0.17 | Audio playback (WAV, OGG, MP3, FLAC) |
| image | 0.24 | Image loading (PNG, JPEG, BMP) |
| fontdue | 0.9 | TTF/OTF font parsing and glyph rasterization |
| gilrs | 0.11 | Gamepad input (cross-platform) |
| slotmap | 1 | Generational ID resource pools |
| bytemuck | 1 | Safe POD casts for GPU vertex data |
| pollster | 0.3 | Blocking executor for wgpu async init |
| thiserror | 1 | Derive macros for error types |
| fastrand | 2 | Fast random number generation |
| serde | 1 | Serialization framework |
| serde_json | 1 | JSON serialization |
| directories | 5 | Platform-specific directory paths |
| log | 0.4 | Logging facade |
| env_logger | 0.10 | Environment-based log configuration |
| flate2 | 1 | Deflate/gzip/zlib compression |
| lz4_flex | 0.11 | LZ4 compression |
| sha2 | 0.10 | SHA-256/SHA-512 hashing |
| md-5 | 0.10 | MD5 hashing |
| arboard | 3 | Clipboard access |
| zip | 2 | ZIP archive reading (VFS mounting) |
| tiny-skia | 0.11 | Legacy CPU fallback renderer |
| minifb | 0.27 | Legacy CPU fallback windowing |

---

## File Structure

```
src/
├── main.rs                          CLI entry point, arg parsing
├── lib.rs                           Library re-exports
│
├── engine/
│   ├── mod.rs                       Module re-exports
│   ├── app.rs                       App struct, RunState, game loop, error mode loop
│   ├── config.rs                    Config, WindowConfig, ModulesConfig, PerformanceConfig
│   ├── error.rs                     EngineError (12 variants), EngineResult<T>
│   ├── error_screen.rs              ErrorScreen (blue error display, built-in font)
│   ├── debug_overlay.rs             Debug HUD (FPS, draw calls, memory)
│   └── resource_keys.rs             All SlotMap key type definitions
│
├── graphics/
│   ├── mod.rs
│   ├── gpu_renderer.rs              GpuRenderer: wgpu pipelines, render passes, texture upload
│   ├── renderer.rs                  Legacy CPU renderer, DrawCommand enum, DrawMode, BlendMode
│   ├── shader.rs                    Shader: WGSL compilation, uniform system, pipeline creation
│   ├── mesh.rs                      Mesh: custom geometry, vertex/index buffers
│   ├── texture.rs                   Texture loading (premultiplied alpha)
│   ├── color.rs                     Color (f32 RGBA)
│   ├── sprite.rs                    Sprite struct
│   ├── sprite_batch.rs              SpriteBatch for efficient batched rendering
│   ├── camera.rs                    Camera (view transform, zoom, rotation)
│   ├── animation.rs                 Animation, AnimationFrame (sprite-sheet playback)
│   ├── canvas.rs                    Canvas off-screen render target
│   └── font.rs                      TTF/OTF loading, glyph raster, atlas, word-wrap, metrics
│
├── input/
│   ├── mod.rs
│   ├── keyboard.rs                  KeyboardState (keys + scancodes + repeat + text input)
│   ├── mouse.rs                     MouseState (5 buttons, cursor, scroll, grab, relative)
│   ├── gamepad.rs                   GamepadState (buttons, axes, name, gilrs mapping)
│   └── touch.rs                     TouchState, TouchPoint
│
├── audio/
│   ├── mod.rs
│   ├── mixer.rs                     Mixer (rodio, SlotMap<SoundKey>, master volume)
│   └── source.rs                    AudioSource (Static/Stream, looping, pitch, pan)
│
├── math/
│   ├── mod.rs
│   ├── vec2.rs                      Vec2 operations
│   ├── mat3.rs                      Mat3 (affine transforms)
│   ├── rect.rs                      Rect (AABB)
│   ├── easing.rs                    22 easing functions
│   ├── noise.rs                     Perlin, simplex, fractal Brownian motion
│   ├── random.rs                    RandomGenerator (fastrand wrapper, Box-Muller normal)
│   ├── transform.rs                 Transform (Mat3 UserData wrapper)
│   ├── bezier.rs                    BezierCurve (De Casteljau, render, derivative)
│   ├── triangulate.rs               Polygon triangulation (ear-clipping)
│   └── color_space.rs               sRGB ↔ linear conversion
│
├── physics/
│   ├── mod.rs
│   ├── world.rs                     World (rapier2d pipeline, step, gravity, callbacks)
│   ├── body.rs                      Body (sync buffer, position, velocity, forces, damping)
│   ├── shape.rs                     Shape types (Cuboid, Ball, ConvexPolygon, Segment, Polyline)
│   ├── fixture.rs                   Fixture (per-collider properties)
│   ├── joint.rs                     11 joint types
│   └── contact.rs                   Contact info, collision events
│
├── particle/
│   └── mod.rs                       ParticleSystem, Particle, ParticleConfig, EmitterState
│
├── timer/
│   ├── mod.rs
│   └── clock.rs                     Clock (delta, FPS, average delta, total time, micro time)
│
├── filesystem/
│   ├── mod.rs
│   ├── vfs.rs                       GameFS (sandboxed, path traversal protection)
│   ├── file_handle.rs               FileHandle (Read/Write/Append/Closed modes)
│   └── virtual_fs.rs                VirtualFS, MountPoint (directory + zip archives)
│
├── data/
│   ├── mod.rs
│   ├── byte_data.rs                 ByteData (Vec<u8> buffer)
│   ├── compress.rs                  Compression (deflate, gzip, lz4, zlib)
│   ├── hash.rs                      Hashing (MD5, SHA-1, SHA-256, SHA-512)
│   └── encode.rs                    Encoding (Base64, hex)
│
├── image/
│   ├── mod.rs
│   └── image_data.rs                ImageData (CPU RGBA8 pixel buffer)
│
├── sound/
│   ├── mod.rs
│   └── sound_data.rs                SoundData (decoded PCM f32 samples)
│
├── window/
│   ├── mod.rs
│   └── event_loop.rs                Placeholder (logic in engine/app.rs)
│
└── lua_api/
    ├── mod.rs                       SharedState, create_lua_vm()
    ├── userdata.rs                  LunaType trait, add_type_methods()
    ├── graphics_api.rs              luna.graphics.* + LuaImage, LuaFont, LuaCanvas, etc.
    ├── input_api.rs                 luna.keyboard.*, luna.mouse.*, luna.gamepad.*, luna.touch.*
    ├── audio_api.rs                 luna.audio.* + LuaSource
    ├── timer_api.rs                 luna.timer.*
    ├── math_api.rs                  luna.math.* + LuaRandomGenerator, LuaTransform, LuaBezierCurve
    ├── physics_api.rs               luna.physics.* + LuaWorld, LuaBody
    ├── filesystem_api.rs            luna.filesystem.* + LuaFileHandle
    ├── window_api.rs                luna.window.*
    ├── event_api.rs                 luna.event.*
    ├── system_api.rs                luna.system.*
    ├── particle_api.rs              luna.particle.* + LuaParticleSystem
    ├── data_api.rs                  luna.data.* + LuaByteData
    ├── image_api.rs                 luna.image.* + LuaImageData
    ├── sound_api.rs                 luna.sound.* + LuaSoundData
    ├── thread_api.rs                luna.thread.*
    ├── thread_channel.rs            Channel, ChannelValue (thread-safe MPMC)
    └── thread_worker.rs             LuaThread (separate Lua VM per thread)

examples/                            Lua game examples
tests/                               Integration tests
docs/                                Documentation
tools/                               CLI utilities and build scripts
```

---

## Testing Architecture

### Test Organization

| Layer | Location | Scope |
|---|---|---|
| Unit tests | `src/**/*.rs` (`#[cfg(test)]` modules) | Individual functions, data structures |
| Integration tests | `tests/<module>_tests.rs` | Cross-module behavior via public API |
| Lua API tests | `tests/lua/` | BDD-style Lua test suites via test framework |

### Integration Test Files

| File | Coverage |
|---|---|
| `tests/math_tests.rs` | Vec2, Mat3, Rect, easing, noise, random, transform, Bezier |
| `tests/physics_tests.rs` | World, Body, step, collision, joints, raycasting |
| `tests/graphics_tests.rs` | Color, DrawCommand, BlendMode, texture, canvas |
| `tests/audio_tests.rs` | Mixer, AudioSource, playback state, volume |
| `tests/input_tests.rs` | KeyboardState, MouseState, GamepadState |
| `tests/particle_tests.rs` | ParticleSystem, emission, lifecycle, config |
| `tests/lua_tests.rs` | Lua VM creation, API registration, script execution |

### Test Conventions

- Float comparisons: `assert!((val - expected).abs() < 1e-5)` — never `assert_eq!` on `f32`
- Tests must not create windows, play audio, or write outside `target/`
- Integration tests import from the `luna2d` crate public API
- New public Rust API requires at least one integration test

### Quality Gates

```powershell
cargo test                            # All tests must pass
cargo clippy -- -D warnings           # Zero warnings
cargo fmt --check                     # Formatting verified
```
