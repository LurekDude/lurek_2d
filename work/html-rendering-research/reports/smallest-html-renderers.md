# HTML/CSS UI Rendering for Rust Game Engines - Size Comparison

**Question:** What are the smallest HTML/CSS UI rendering solutions for a Rust/wgpu game engine that keep logic in Lua/JS?

## Findings

1. **RmlUi (formerly libRocket)** [1]
   * **Footprint:** Extremely lightweight (usually < 2-3 MB compiled).
   * **Integration:** C++ library with existing Rust bindings (e.g., `rmlui-rs`). Uses a custom, game-optimized subset of HTML/CSS.
   * **Logic:** Lua integration is a first-class citizen in the core C++ library, making it highly suitable for Lua-heavy game engines.
   * **Renderer:** Requires implementing a custom render interface (draw vertices, indices, textures), which maps perfectly and efficiently to `wgpu`. 

2. **Sciter** [2]
   * **Footprint:** Very small for a full engine. The precompiled dynamic library (`sciter.dll`/`libsciter.so`) is typically ~5-8 MB.
   * **Integration:** Strong native Rust bindings via `sciter-rs`.
   * **Logic:** Has its own built-in JS engine (QuickJS in Sciter.JS) which handles the UI logic, keeping it separate from the Rust core.
   * **Renderer:** Can output directly to a graphics API surface or to a bitmap/texture that can be easily uploaded to a `wgpu` texture. Note: Proprietary engine, but free for commercial use.

3. **Lexbor** [3]
   * **Footprint:** Microscopic (< 1 MB).
   * **Integration:** It is an extremely fast C HTML/CSS parser and layout engine, *not* a standalone graphical renderer.
   * **Logic / Renderer:** No built-in JS/Lua bindings or rasterization. You must manually traverse the generated layout tree, render UI elements using `wgpu`, and map interactions to your engine's Lua state yourself.

4. **Pure Rust Renderers (Blitz / Servo / Wry)** [4]
   * **Footprint:** `Servo` is massive and unsuitable for a minimal footprint. `Wry` (used by Tauri/Dioxus) uses the OS-native WebView (very small binary, but massive runtime memory footprint and tied to the OS browser version). Native pure Rust web renderers like `Blitz` (Dioxus' wgpu renderer) statically compile to ~10-15 MB.
   * **Integration:** Strictly coupled to Rust logic (or requires heavy custom bridging to JS/Lua). They lack standalone JS/Lua runtime coupling for games.

5. **Ultralight** [5]
   * **Footprint:** Large. Based on a stripped-down WebKit, the compiled binaries usually exceed 20-30+ MB.
   * **Integration:** Rust bindings exist (`ultralight-rs`). Full HTML/CSS/JS support. Renders to a pixel buffer or GPU surface. Disqualified based on the strict "smallest in size" requirement.

## Sources
- [1] RmlUi Official Repository: https://github.com/mikke89/RmlUi
- [2] Sciter Official Website: https://sciter.com/
- [3] Lexbor Official Repository: https://github.com/lexbor/lexbor
- [4] Dioxus/Blitz Repository: https://github.com/DioxusLabs/blitz
- [5] Ultralight Official Website: https://ultralig.ht/

## Confidence
**HIGH.** The binary sizes and architectural trade-offs of these libraries are well-documented in their respective repositories and game development ecosystems. 

## Unanswered Gaps
- Which specific subset of CSS is required by the game? (RmlUi only supports a targeted, game-centric subset of CSS, missing some modern web features).
- Does the engine require statically linked libraries? (Sciter is typically distributed as a dynamic library).

## Recommendation
**Recommendation:** Use **RmlUi**. It offers the smallest complete rendering package (< 3 MB), natively supports Lua for logic binding, maps cleanly to `wgpu` via a custom render interface, and avoids the massive footprint of full web browsers. If full standard JS/CSS support is strictly required, use **Sciter** (~5-8 MB) and render it to a `wgpu` texture.