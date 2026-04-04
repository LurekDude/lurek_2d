# Engine Ratings — Numerical Comparison

> **Scope**: 7 engine architectures rated across 18 categories on a 1–10 scale.
> **Methodology**: Ratings derived from source code analysis, architecture reports, documentation review, and public ecosystem data. Each rating includes a short justification. Ratings assess the engine _as it exists today_, not its roadmap or potential.

## Rating Scale

| Score | Meaning |
|-------|---------|
| 1–2 | Missing or non-functional |
| 3–4 | Basic / minimal implementation |
| 5–6 | Adequate / meets core needs |
| 7–8 | Strong / well-implemented |
| 9–10 | Excellent / best-in-class |

## Comparison Table

| # | Category | Love2D | Solar2D | Gideros | ggez | macroquad | Luna2D Original | Luna2D Rust |
|---|----------|--------|---------|---------|------|-----------|-----------------|-------------|
| 1 | **API Design & Simplicity** | 9 | 7 | 6 | 7 | 9 | 6 | 8 |
| 2 | **Rendering Pipeline** | 8 | 7 | 6 | 8 | 5 | 4 | 8 |
| 3 | **Physics Integration** | 8 | 8 | 5 | 2 | 2 | 1 | 8 |
| 4 | **Audio System** | 7 | 7 | 6 | 6 | 3 | 3 | 7 |
| 5 | **Input Handling** | 7 | 6 | 6 | 7 | 6 | 5 | 8 |
| 6 | **Cross-Platform Support** | 8 | 9 | 8 | 5 | 9 | 7 | 5 |
| 7 | **Documentation & Learning** | 10 | 7 | 5 | 6 | 5 | 3 | 4 |
| 8 | **Community & Ecosystem** | 10 | 7 | 4 | 4 | 5 | 1 | 1 |
| 9 | **Production Track Record** | 10 | 9 | 3 | 2 | 2 | 1 | 1 |
| 10 | **Memory Safety** | 4 | 4 | 4 | 8 | 5 | 3 | 9 |
| 11 | **Error Handling & Recovery** | 5 | 5 | 4 | 6 | 3 | 3 | 8 |
| 12 | **Scene & State Management** | 3 | 9 | 7 | 2 | 3 | 6 | 2 |
| 13 | **Math & Utility Libraries** | 5 | 5 | 4 | 4 | 5 | 3 | 9 |
| 14 | **Animation System** | 4 | 8 | 8 | 3 | 3 | 3 | 4 |
| 15 | **Asset Pipeline & Filesystem** | 7 | 7 | 6 | 7 | 4 | 5 | 7 |
| 16 | **Extensibility & Modularity** | 6 | 7 | 6 | 6 | 7 | 4 | 3 |
| 17 | **AI & Game Logic Primitives** | 2 | 2 | 2 | 1 | 1 | 1 | 8 |
| 18 | **Code Architecture Quality** | 7 | 6 | 5 | 7 | 5 | 4 | 7 |
|   | **Total** | **120** | **120** | **95** | **85** | **82** | **63** | **107** |
|   | **Average** | **6.7** | **6.7** | **5.3** | **4.7** | **4.6** | **3.5** | **5.9** |

## Category Notes

### 1. API Design & Simplicity
_How easy is it to write a working game with minimal boilerplate?_

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 9 | Gold standard — smallest possible function signatures, sensible defaults everywhere, one file = working game. 16 years of API refinement. |
| Solar2D | 7 | Clean but display-tree paradigm requires learning scene graph concepts. Transition system is elegant but opinionated. |
| Gideros | 6 | OOP inheritance model (`Core.class()`) adds ceremony. Flash-era API patterns feel dated. |
| ggez | 7 | Clean `EventHandler` trait, but `&mut Context` everywhere is verbose. No scripting = Rust syntax overhead. |
| macroquad | 9 | 10 lines to a working game. Ultra-minimal free functions. Simplest possible Rust game dev experience. |
| Luna2D Original | 6 | `luna.*` namespace is clean but limited. Mobile-centric API not optimized for desktop workflows. |
| Luna2D Rust | 8 | Love2D-inspired callbacks with flat namespace. 100+ functions well-organized across 26 modules. Slightly complex due to scope breadth. |

### 2. Rendering Pipeline
_GPU backend quality, shader support, batching, render-to-texture capabilities._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 8 | Multi-backend (GL/Vulkan/Metal), GLSL shaders, canvas, SpriteBatch. Mature but maintaining 3 backends is complex. |
| Solar2D | 7 | Hardware-accelerated scene graph with auto-batching by draw order. Shader support via Corona Shader Language. No immediate-mode option. |
| Gideros | 6 | GL2/DX11/Metal/Vulkan. Adequate for 2D sprite games. Mesh API allows custom geometry. No modern GPU abstraction. |
| ggez | 8 | wgpu-backed, pipeline caching, InstanceArray for GPU batching. Canvas abstraction for offscreen. Modern architecture. |
| macroquad | 5 | GLES 2.0 baseline via miniquad. No compute shaders, limited pipeline control. Simple but constrained. |
| Luna2D Original | 4 | GLES 2.0 only. Batched vertices but no shader API, no render-to-texture, no multi-backend. |
| Luna2D Rust | 8 | wgpu 22, two pipelines (color + texture), WGSL custom shaders, canvas, SpriteBatch, render stats. Renderer file is monolithic. |

### 3. Physics Integration
_Built-in physics engine quality, body types, collision detection, joints, raycasting._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 8 | Box2D fully wrapped. Bodies, fixtures, shapes, joints, raycasting. Proven physics engine. |
| Solar2D | 8 | Box2D with Lua-friendly API. Per-body event listeners for collision. Well-integrated with display tree. |
| Gideros | 5 | LiquidFun via plugin — not core. Requires separate installation. Plugin maintenance uncertain. |
| ggez | 2 | No built-in physics. Users must integrate rapier or similar manually. |
| macroquad | 2 | Minimal subcrate only. No full rigid body simulation. |
| Luna2D Original | 1 | No physics engine at all. Games must implement collision manually. |
| Luna2D Rust | 8 | rapier2d 0.32 — mature library. Dynamic/static/kinematic bodies, shapes, raycasting, joints, CCD. |

### 4. Audio System
_Sound loading, playback control, mixing, effects, format support._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 7 | OpenAL-backed. Static + streaming sources. Audio effects (reverb, echo). Mature and well-tested. |
| Solar2D | 7 | OpenAL with multiple channels. Background music + SFX. Adequate for mobile games. |
| Gideros | 6 | OpenAL + custom backend. Sound effects and BGM. Functional but not distinguished. |
| ggez | 6 | rodio-based. Load and play sources. No audio buses or effects pipeline. |
| macroquad | 3 | quad-snd — minimal. Play/stop. No mixing, no effects, feature-gated optional. |
| Luna2D Original | 3 | Custom audio. Basic playback capabilities. Limited format support. |
| Luna2D Rust | 7 | rodio with mixer, per-source volume/pitch/pan, audio buses, fade-in, MIDI synthesis. Graceful headless fallback. No effects (reverb, EQ). |

### 5. Input Handling
_Keyboard, mouse, gamepad, touch support. Event model quality._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 7 | Keyboard, mouse, joystick callbacks. Text input. Gamepad mapping via SDL. No native touch design. |
| Solar2D | 6 | Touch-first event listeners. Multi-touch. Keyboard support secondary. Accelerometer. |
| Gideros | 6 | Event dispatcher model. Touch, keyboard, mouse. Accelerometer via plugin. |
| ggez | 7 | Keyboard, mouse, gamepad via gilrs. Clean trait-based callbacks. No touch. |
| macroquad | 6 | Polling for keyboard/mouse/gamepad/touch. Simple but no event callbacks. |
| Luna2D Original | 5 | Touch and accelerometer (mobile-focused). Keyboard via event callbacks. Limited gamepad support. |
| Luna2D Rust | 8 | Keyboard (scancode + logical), mouse (5 buttons + scroll), gamepad (gilrs — 14 buttons, 6 axes, GUID), multi-touch (pressure + deltas). Callback and polling APIs. |

### 6. Cross-Platform Support
_Desktop, mobile, web deployment. Platform coverage breadth._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 8 | Windows, macOS, Linux, iOS, Android. Mobile is secondary. No WASM. Mature platform layer. |
| Solar2D | 9 | Windows, macOS, Linux, iOS, Android, tvOS, Web. Mobile-first design. Best mobile deployment story. |
| Gideros | 8 | Windows, macOS, Linux, iOS, Android, HTML5. One codebase across platforms. |
| ggez | 5 | Windows, macOS, Linux only. No mobile, no WASM. Desktop-only focus. |
| macroquad | 9 | Windows, macOS, Linux, iOS, Android, WASM. Cross-platform from day one. Best web target. |
| Luna2D Original | 7 | iOS, Android native. Qt desktop emulator. Mobile-first but desktop was a development tool. |
| Luna2D Rust | 5 | Windows, Linux, macOS desktop. Mobile and WASM on roadmap but not implemented. LuaJIT limits ARM targets. |

### 7. Documentation & Learning Resources
_API docs, tutorials, examples, wiki, community guides._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 10 | Comprehensive wiki with every function documented. Massive tutorial ecosystem. Books published. 16 years of knowledge. |
| Solar2D | 7 | API reference with examples. Guides for common tasks. Some docs stale since open-source transition. |
| Gideros | 5 | Documentation exists but less comprehensive. Smaller tutorial ecosystem. IDE-focused workflow documented. |
| ggez | 6 | Example-driven. API docs via docs.rs. Love2D familiarity helps. Limited standalone tutorials. |
| macroquad | 5 | Minimal by design. Example programs as primary reference. docs.rs API docs. Few tutorials. |
| Luna2D Original | 3 | Internal documentation. Limited public-facing guides. Code-adjacent comments. |
| Luna2D Rust | 4 | `///` doc comments on public items. Generated API reference. Architecture docs. No tutorials, getting-started guide, or cookbook yet. |

### 8. Community & Ecosystem
_Library availability, forum activity, third-party tools, community contributions._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 10 | Massive Lua library catalog (anim8, bump.lua, STI, HUMP, etc.). Active forums, Reddit, Discord. Largest 2D Lua engine community. |
| Solar2D | 7 | 200+ plugins (many from Corona era). Active community forums. Plugin marketplace, though some plugins unmaintained. |
| Gideros | 4 | Small community. Some plugins. Gideros Studio provides an ecosystem but limited third-party support. |
| ggez | 4 | Rust crate ecosystem available (rapier, egui). Small but dedicated user base. |
| macroquad | 5 | Growing community. Subcrate ecosystem (particles, platformer, tiled). Game jam popularity increasing. |
| Luna2D Original | 1 | Individual project. No community, no plugin ecosystem, no forum. |
| Luna2D Rust | 1 | New project. No community yet, no published games, no third-party libraries. VS Code extension is first-party. |

### 9. Production Track Record
_Commercially released games, years in production use, real-world validation._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 10 | Balatro (2024, massive commercial success), Gravity Circuit, Move or Die. 16 years of production use. Proven at scale. |
| Solar2D | 9 | Thousands of mobile games published during Corona SDK era (2009–2020). Massive commercial validation. |
| Gideros | 3 | Some published games but limited commercial track record. Niche audience. |
| ggez | 2 | A few small indie releases. Rust game ecosystem is still emerging for commercial products. |
| macroquad | 2 | Game jam entries. Limited commercial releases. Framework is newer. |
| Luna2D Original | 1 | No publicly known commercial releases. Internal/hobby project. |
| Luna2D Rust | 1 | Pre-release. No published games. Engine is under active development. |

### 10. Memory Safety
_Protection against use-after-free, buffer overflows, null dereferences, data races._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 4 | C++ with manual retain/release reference counting. Memory bugs possible. No static safety guarantees. |
| Solar2D | 4 | C++ codebase. Manual memory management. Display objects with reference counting. |
| Gideros | 4 | C++ with manual management. Plugin boundary increases risk. Dynamic loading complicates safety. |
| ggez | 8 | Rust ownership model. No `unsafe` in user-facing API. Safe by construction. Some `unsafe` in internal wgpu integration. |
| macroquad | 5 | Rust language but pervasive `unsafe` global state. Safety guarantees partially undermined by design choice. |
| Luna2D Original | 3 | C++ with raw pointers, singleton patterns, manual deallocation. Memory leaks possible. |
| Luna2D Rust | 9 | Rust ownership with `Rc<RefCell<>>` for state sharing. No `unsafe` blocks in engine code. RefCell provides runtime borrow checking. Only risk: RefCell borrow panics (not memory corruption). |

### 11. Error Handling & Recovery
_Graceful error reporting, crash prevention, recovery options, error categorization._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 5 | Blue error screen with Lua traceback. No typed error system. Unrecoverable errors crash. |
| Solar2D | 5 | Error popup with stack trace. Some recovery via pcall. No structured error codes. |
| Gideros | 4 | Error console in IDE. Limited runtime recovery. |
| ggez | 6 | Rust `Result<T>` propagation. `GameError` enum. Structured but no runtime visual recovery. |
| macroquad | 3 | `Option`/`panic` based. No structured error handling. Panics crash the process. |
| Luna2D Original | 3 | Basic error logging. Limited recovery capabilities. |
| Luna2D Rust | 8 | 12 typed `EngineError` variants with stable codes (E1001–E1012). In-engine error screen with traceback and recovery hints. Categorized errors (Init/Runtime/Resource/Script/System). Escape to restart. |

### 12. Scene & State Management
_Built-in scene transitions, state machines, overlay scenes, lifecycle management._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 3 | No built-in scene management. `love.handlers` table is extensible. Community libraries (Gamestate, roomy) fill the gap. |
| Solar2D | 9 | Composer module with `gotoScene`, `overlay`, lifecycle events (create/show/hide/destroy). Best built-in solution. |
| Gideros | 7 | SceneManager plugin with transitions and lifecycle. OOP scene classes with enter/exit hooks. |
| ggez | 2 | No built-in scene system. Users implement manually via trait objects. |
| macroquad | 3 | No scene management. Coroutine-like async offers an alternative pattern. |
| Luna2D Original | 6 | Simple scene table pattern with start/update/draw callbacks. Scene transitions. |
| Luna2D Rust | 2 | No built-in scene management. Games must implement their own state machine. |

### 13. Math & Utility Libraries
_Vectors, matrices, easing, noise, procedural generation, pathfinding, spatial queries._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 5 | Basic math (`love.math`). Noise functions. Random. No vectors, easing, or pathfinding built in. Community libraries fill gaps. |
| Solar2D | 5 | Basic math utilities. No vector library. No easing (transition system covers animation). |
| Gideros | 4 | Matrix class for transforms. No vector math, noise, or pathfinding. Easing via MovieClip only. |
| ggez | 4 | Depends on external crates (glam, nalgebra). No built-in easing, noise, or pathfinding. |
| macroquad | 5 | Built-in Vec2/Vec3. No easing, noise, or pathfinding. Minimal but present. |
| Luna2D Original | 3 | Minimal math support. No vectors beyond position/size. No utilities. |
| Luna2D Rust | 9 | 22 submodules: Vec2, Mat3, Rect, easing (30+), Bezier, Perlin/Simplex noise, procedural gen (cellular automata, Voronoi, Poisson), A*/Dijkstra/BFS pathfinding, spatial hash, raycasting, seeded RNG, transforms, tweens. |

### 14. Animation System
_Sprite animation, tweening, skeletal animation, easing functions, timeline control._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 4 | No built-in animation. Community library anim8 is the standard. Basic frame animation possible via quads. |
| Solar2D | 8 | `transition.to()` declarative property animation with easing. Sprite sheets with `newImageSheet/newSprite`. Timeline control. |
| Gideros | 8 | MovieClip with 15 easing types. Frame-based and tween-based animation. Best built-in animation system among these engines. |
| ggez | 3 | No animation system. Manual sprite sheet slicing. |
| macroquad | 3 | No animation. Manual frame tracking. |
| Luna2D Original | 3 | Basic animation support. Limited to simple sprite frames. |
| Luna2D Rust | 4 | Frame-based sprite animation with SpriteSheet. 30+ easing functions available separately. No tweened property animation system or animation blending. |

### 15. Asset Pipeline & Filesystem
_Asset loading, caching, sandboxing, virtual filesystem, archive support._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 7 | PhysFS-based VFS. `.love` archive support. Sandboxed save directory. Identity system. Mature and well-tested. |
| Solar2D | 7 | System-based resource paths (ResourceDirectory, DocumentsDirectory). Auto DPI-aware asset selection (@2x, @3x). |
| Gideros | 6 | Project-based asset management. Resource system in IDE. Texture pack support. |
| ggez | 7 | VFS overlay filesystem with zip archive support. Multiple mount points. Clean API. |
| macroquad | 4 | File loading functions. No VFS, no sandboxing, minimal caching. Online asset fetch for WASM. |
| Luna2D Original | 5 | Content scaling with DPI-aware loading. Texture atlas with JSON descriptors. iOS/Android asset paths. |
| Luna2D Rust | 7 | GameFS with path traversal protection. Per-game identity save directories. Async background loading. No archive format yet (.luna planned). |

### 16. Extensibility & Modularity
_Plugin systems, module toggling, custom extensions, build-time configuration._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 6 | Modules can be disabled via `conf.lua`. FFI for native extensions. Community libraries are Lua-only. No native plugin API. |
| Solar2D | 7 | 200+ plugins. Plugin marketplace. Native SDK integration. Module toggling via `build.settings`. |
| Gideros | 6 | Plugin system with dynamic C++ loading. Studio integration. Custom native bindings possible. |
| ggez | 6 | Rust crate ecosystem. Composable via Cargo dependencies. No runtime plugin system. |
| macroquad | 7 | Subcrate architecture (particles, platformer, tiled, ui as opt-in crates). Clean modular design. |
| Luna2D Original | 4 | Limited extensibility. Monolithic C++ build. Platform code via preprocessor. |
| Luna2D Rust | 3 | Module enable/disable via `conf.lua`. No runtime plugin system. All modules compiled in. No way to extend `luna.*` from outside the binary. 50+ crate deps always built. |

### 17. AI & Game Logic Primitives
_Built-in FSM, behavior trees, pathfinding, steering, decision-making systems._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 2 | No built-in AI. Community libraries exist (jumper for pathfinding). Manual implementation expected. |
| Solar2D | 2 | No AI modules. Pathfinding and FSM are user-implemented or third-party. |
| Gideros | 2 | No AI primitives. User responsibility. |
| ggez | 1 | No AI. Pure rendering/input framework. Users integrate Rust AI crates. |
| macroquad | 1 | No AI modules at all. Minimal by design. |
| Luna2D Original | 1 | No AI support. |
| Luna2D Rust | 8 | 15 files: FSM, behavior tree, steering (8 behaviors), GOAP, Q-learning, A*/Dijkstra pathfinding, flow fields, influence maps, squad formations, blackboard. Unique among 2D engines. |

### 18. Code Architecture Quality
_Module boundaries, dependency direction, separation of concerns, code maintainability._

| Engine | Score | Note |
|--------|-------|------|
| Love2D | 7 | Clean module singleton pattern. Each subsystem independent. Object base class. Well-established patterns. Large C++ codebase is complex but organized. |
| Solar2D | 6 | Scene graph architecture is principled but large. C++ with multiple renderer backends adds complexity. Plugin system well-designed. |
| Gideros | 5 | OOP hierarchy is clean but deep. Binder pattern for Lua registration is elegant. Plugin dynamic loading adds risk. Flash-era design shows age. |
| ggez | 7 | Clean Rust architecture. Context subsystem pattern. Good separation. Pipeline caching well-designed. |
| macroquad | 5 | Simple and flat, but global `unsafe` state undermines Rust's safety story. Intentional simplicity at the cost of correctness. |
| Luna2D Original | 4 | Singleton pattern. Preprocessor platform abstraction. Manual C++ memory management. Functional but dated. |
| Luna2D Rust | 7 | Clean module boundaries (domains don't cross-depend). Lua bindings separated from domain logic. SlotMap resource management. Interior mutability pattern appropriate. Weakened by monolithic app.rs (2100 lines) and gpu_renderer.rs (3100 lines). |

## Summary

### Scores by Engine (sorted by total)

| Rank | Engine | Total | Avg | Best Categories | Worst Categories |
|------|--------|-------|-----|-----------------|------------------|
| 1= | **Love2D** | 120 | 6.7 | Documentation (10), Community (10), Production (10), API Design (9) | Scene Mgmt (3), AI (2), Animation (4) |
| 1= | **Solar2D** | 120 | 6.7 | Scene Mgmt (9), Production (9), Cross-Platform (9), Animation (8) | AI (2), Memory Safety (4), Error Handling (5) |
| 3 | **Luna2D Rust** | 107 | 5.9 | Memory Safety (9), Math (9), Error Handling (8), AI (8), Physics (8), Input (8), Rendering (8) | Community (1), Production (1), Scene Mgmt (2), Extensibility (3) |
| 4 | **Gideros** | 95 | 5.3 | Animation (8), Cross-Platform (8), Scene Mgmt (7) | Production (3), Community (4), Memory Safety (4) |
| 5 | **ggez** | 85 | 4.7 | Memory Safety (8), Rendering (8), Architecture (7) | AI (1), Physics (2), Production (2), Scene Mgmt (2) |
| 6 | **macroquad** | 82 | 4.6 | Cross-Platform (9), API Design (9) | AI (1), Physics (2), Production (2), Audio (3), Error Handling (3) |
| 7 | **Luna2D Original** | 63 | 3.5 | Cross-Platform (7), Scene Mgmt (6) | Community (1), Production (1), AI (1), Physics (1) |

### Key Takeaways

1. **Love2D and Solar2D tie on total score** (120 each) but excel in completely different areas. Love2D dominates in community and documentation; Solar2D in built-in frameworks (scenes, animation, cross-platform).

2. **Luna2D Rust ranks 3rd** (107) with the highest technical scores (memory safety, math, error handling, AI, physics) but the lowest ecosystem scores (community, production, documentation). It's the most technically sophisticated but least battle-tested.

3. **The Rust engines (ggez, macroquad) score lower overall** despite strong technical foundations because they lack scripting, physics, audio depth, and community. They're frameworks, not full engines.

4. **Luna2D Rust's unique differentiator is breadth**: it's the only engine scoring 7+ in physics, audio, input, math, AND AI simultaneously. No other engine in this comparison covers all those domains well.

5. **The two areas where Luna2D Rust trails most** are community/ecosystem (inherent for a new project) and scene management (a design gap that can be addressed).

6. **Luna2D Original scores lowest** (63) — expected for a mobile-only C++ engine that predates the Rust rewrite. The rewrite addresses most of its weaknesses (no physics, limited audio, no desktop support, memory safety).
