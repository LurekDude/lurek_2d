# Luna2D Cross-Platform Feasibility Research

**Date:** March 2026
**Scope:** Android, iOS, Web/HTML (WebAssembly), Linux, macOS
**Engine version:** v0.2.0
**Verdict format:** Ready / Feasible-with-work / Major-refactoring-required / Not-possible

> Note: This document is a historical research snapshot. Several platform conclusions below assume the older `minifb`/`tiny-skia` runtime that predated Luna2D's current `winit` + `wgpu` primary stack. See `docs/architecture.md` for the current architecture.

---

## Executive Summary

| Platform            | Status                        | Primary Blocker                                      | Estimated Effort     |
|---------------------|-------------------------------|------------------------------------------------------|----------------------|
| Linux x86/x64       | **Ready**                     | None — 4 system packages required                   | < 1 hour             |
| Linux ARM64         | **Ready with minor toolchain**| Cross-compile libasound setup                        | 1–2 hours            |
| macOS (Apple Silicon / Intel) | **Ready**          | None (on macOS machine) / Osxcross (from Linux/Win) | < 1 hour on macOS    |
| Web / HTML (WASM)   | **Major refactoring required**| mlua↔WASM target mismatch, event loop rewrite       | 3–6 months           |
| Android             | **Major refactoring required**| minifb has zero Android support                      | 3–6 months           |
| iOS                 | **Major refactoring required**| minifb has zero iOS support; macOS hardware required | 3–6 months + hardware|

---

## 1. Linux Builds

### Status: READY

Linux builds require no code changes. All dependencies have full Linux support.

### Dependency Analysis

| Dependency | Linux Support | Backend |
|---|---|---|
| `minifb` 0.27 | ✅ Full — X11 and Wayland | Native X11/XCB or Wayland |
| `tiny-skia` 0.11 | ✅ Full — pure Rust, no platform code | Software rasterizer |
| `mlua` 0.9 (vendored) | ✅ Full — Lua C sources compile via cc | Vendored C |
| `rodio` 0.17 / `cpal` | ✅ Full — ALSA, PipeWire, PulseAudio | libasound2 / PipeWire / PulseAudio |
| `image` 0.24 | ✅ Full — pure Rust | — |
| `directories` 5 | ✅ Full | XDG Base Directory Spec |

### Required System Packages (Ubuntu/Debian)

These must be installed before `cargo build` on a fresh Linux system:

```bash
# Windowing (X11 + Wayland support for minifb)
sudo apt install libxkbcommon-dev libwayland-cursor0 libwayland-dev

# Audio backend (cpal/rodio via ALSA)
sudo apt install libasound2-dev

# Optional: PipeWire or PulseAudio native backends
sudo apt install libpipewire-0.3-dev   # for PipeWire
sudo apt install libpulse-dev          # for PulseAudio
```

On Fedora/RHEL equivalents:
```bash
sudo dnf install libxkbcommon-devel wayland-devel alsa-lib-devel
```

On Arch Linux:
```bash
sudo pacman -S libxkbcommon wayland alsa-lib
```

### Build Commands

```bash
cargo build                            # Debug build
cargo build --release                  # Release build
cargo run -- demos/hello_world      # Run with example
```

### Cross-Compilation to Linux ARM64 from Windows

To cross-compile from Windows to Linux aarch64:

1. Install cross-compilation target:
   ```powershell
   rustup target add aarch64-unknown-linux-gnu
   ```

2. Install `cross` (Docker-based cross-compiler):
   ```powershell
   cargo install cross --git https://github.com/cross-rs/cross
   cross build --target aarch64-unknown-linux-gnu --release
   ```

   `cross` handles the libasound2-dev multi-arch issue automatically via Docker.

### Notes

- Wayland support in minifb requires the `wayland-cursor0` and `wayland-dev` packages.
- The ALSA backend is default for `cpal` on Linux; PipeWire/PulseAudio are optional features. If PipeWire is running, it holds the ALSA `default` device exclusively — use the native PipeWire backend to avoid `DeviceBusy` errors.
- `build.rs` uses `#[cfg(target_os = "windows")]` only for icon embedding via `winresource` — this is harmless on Linux and produces no build errors.

---

## 2. macOS Builds

### Status: READY (requires macOS hardware or osxcross toolchain)

All dependencies have full macOS support. The engine compiles and runs on macOS without code changes.

### Dependency Analysis

| Dependency | macOS Support | Backend |
|---|---|---|
| `minifb` 0.27 | ✅ Full — Cocoa/AppKit (Objective-C 17%) | NSWindow / CALayer |
| `tiny-skia` 0.11 | ✅ Full — pure Rust | Software rasterizer |
| `mlua` 0.9 (vendored) | ✅ Full | Vendored Lua C |
| `rodio` 0.17 / `cpal` | ✅ Full — CoreAudio | CoreAudio framework |
| `image` 0.24 | ✅ Full | — |
| `directories` 5 | ✅ Full | `~/Library/Application Support` |

### Requirements on macOS

```bash
# Xcode Command Line Tools (required for linking)
xcode-select --install

# Then just:
cargo build
cargo run -- demos/hello_world
```

Xcode Command Line Tools provide the linker (`ld`), CoreAudio SDK headers, and the Cocoa/AppKit frameworks that minifb links against.

No additional system packages are needed — all Rust dependencies are vendored or link against standard macOS frameworks.

### Apple Silicon (aarch64-apple-darwin)

Apple Silicon Macs are fully supported. Rust's `aarch64-apple-darwin` target is Tier 1.

```bash
rustup target add aarch64-apple-darwin
cargo build --target aarch64-apple-darwin --release
```

### Intel Mac (x86_64-apple-darwin)

```bash
rustup target add x86_64-apple-darwin
cargo build --target x86_64-apple-darwin --release
```

### Universal Binary (fat binary for Intel + Apple Silicon)

Use `cargo-lipo`:
```bash
cargo install cargo-lipo
rustup target add aarch64-apple-darwin x86_64-apple-darwin
cargo lipo --release
```

### Cross-Compiling to macOS from Linux/Windows

Cross-compiling to macOS from a non-Apple OS is possible with `osxcross` (Linux) but is not supported from Windows without a Linux WSL environment. This path is:
- Complex to set up (requires macOS SDK extraction, which has legal restrictions)
- Not recommended for production use
- GitHub Actions macOS runners are the standard CI solution

### Notes

- minifb's macOS backend uses Objective-C (17% of minifb's code). It creates native NSWindow instances. This is transparent to Luna2D.
- `build.rs` `winresource` is `#[cfg(target_os = "windows")]` — no macOS issues.
- The `directories` crate maps `AppDataDir` to `~/Library/Application Support/luna2d/` on macOS.
- macOS requires no code changes in Luna2D.

---

## 3. WebAssembly / HTML Builds

### Status: MAJOR REFACTORING REQUIRED

Web/HTML builds require fundamental architectural changes to Luna2D. In the current architecture, three separate blockers make a straightforward WASM build impossible.

### Blocker 1: mlua WASM Target Incompatibility

mlua (Lua scripting) supports WASM only via `wasm32-unknown-emscripten`. It does **not** support `wasm32-unknown-unknown`, which is the standard browser WASM target used by `wasm-bindgen`, `leptos`, `yew`, and virtually all modern browser-focused Rust tools.

The Emscripten target (`wasm32-unknown-emscripten`) uses an entirely different C runtime (musl via Emscripten), produces `.html` + `.js` + `.wasm` bundles without `wasm-bindgen`, and has limited interop with the browser DOM and modern Web APIs.

**Consequence:** Lua scripting and modern browser Web APIs are on incompatible WASM targets. There is no currently maintained path to run mlua in a `wasm32-unknown-unknown` build.

**Potential resolution:** Replace mlua with a pure-Rust Lua implementation that targets `wasm32-unknown-unknown`, such as a Lua interpreter written entirely in Rust (none exist at production quality today). Alternatively, switch from Lua to a pure-Rust scripting language (Rhai, Rune) for the WASM target — but this would break the entire `luna.*` Lua API contract.

### Blocker 2: minifb Has Partial/Experimental WASM Support Only

The `rust_minifb` repository contains a `Web.toml` file and references to experimental WASM examples from 2+ years ago. The WASM support is not production-ready:

- There is no stable `Canvas2D` rendering path for `Window::update_with_buffer()`.
- The `Window` struct's ownership model and synchronous blocking loop (`while window.is_open()`) conflict with the browser's asynchronous, event-driven execution model.
- Browser tabs cannot block the main thread — they must use `requestAnimationFrame()` callbacks.

**Consequence:** The entire game loop in `src/engine/app.rs` must be rewritten. The `while window.is_open() { ... }` pattern is fundamentally incompatible with browser execution. The correct pattern is a non-blocking state machine driven by `requestAnimationFrame`.

### Blocker 3: Event Loop Architecture

The current game loop in `App::run()` is a synchronous blocking loop. Browsers prohibit this — any synchronous busy loop on the main thread freezes the browser tab. WASM requires:

- `requestAnimationFrame` callbacks for rendering
- DOM event listeners for keyboard/mouse input (replacing minifb's polling)
- Asynchronous file I/O (Web Fetch API, no direct filesystem access)
- WASM memory model incompatibilities with `Rc<RefCell<>>` shared state across async boundaries

### What Does Work on WASM

| Component | WASM Status | Notes |
|---|---|---|
| `tiny-skia` | ✅ Compiles to WASM | Pure Rust, no platform code. SIMD disabled gracefully. |
| `rodio` / `cpal` | ✅ Via `wasm-bindgen` feature on `wasm32-unknown-unknown` | Uses Web Audio API. Requires `cpal` `wasm-bindgen` feature flag. |
| `image` 0.24 | ✅ Pure Rust | Works on WASM. |
| `serde` / `serde_json` | ✅ | Pure Rust. |
| `minifb` | ⚠️ Experimental only | Not production-ready for WASM. |
| `mlua` (vendored) | ❌ Emscripten only | Incompatible with `wasm32-unknown-unknown`. |
| `directories` | ❌ No WASM support | No filesystem on bare WASM. |

### Required Tools for WASM Builds (hypothetical future work)

If the architecture is eventually refactored:

```powershell
# Install WASM target
rustup target add wasm32-unknown-unknown

# Install wasm-pack (recommended for browser WASM)
cargo install wasm-pack

# OR install Trunk (full WASM asset pipeline for single-page apps)
cargo install trunk

# Build (example, not currently usable)
trunk build --release
```

For the Emscripten path (if sticking with mlua):
```powershell
# Install Emscripten SDK
# https://emscripten.org/docs/getting_started/downloads.html
rustup target add wasm32-unknown-emscripten
cargo build --target wasm32-unknown-emscripten
```

But the Emscripten path brings its own incompatibilities (cpal/rodio audio, no wasm-bindgen ergonomics, etc.)

### Summary: WASM Refactoring Scope

A production-quality WASM port would require:
1. Replace `mlua` with a Lua interpreter that compiles to `wasm32-unknown-unknown` (or replace Lua entirely with a Rust-native scripting option)
2. Replace the synchronous game loop with a `requestAnimationFrame`-based state machine
3. Replace `minifb::Window` with a `wasm-bindgen` + Canvas 2D rendering layer (writing pixels to `<canvas>` via `ImageData`)
4. Replace keyboard/mouse polling with DOM `addEventListener` callbacks
5. Replace `GameFS` (filesystem I/O) with a Web Fetch API layer or in-memory VFS
6. Replace `directories` with browser `localStorage` or IndexedDB for save data
7. Update `src/engine/app.rs`, `src/window/`, `src/filesystem/vfs.rs` — essentially the entire platform layer

**Estimated scope:** 3–6 months of significant refactoring for a competent Rust team.

---

## 4. Android Builds

### Status: MAJOR REFACTORING REQUIRED

Android requires the engine's windowing, event loop, and entry point to be completely replaced.

### Root Blocker: minifb Has No Android Support

The minifb crate README explicitly states support for: _"macOS, Linux and Windows (64-bit and 32-bit). X11 (Linux/FreeBSD/etc) and Wayland."_ Android is absent and has never been on the roadmap.

Android applications run in a Java/Kotlin process hosting a `NativeActivity` (or `GameActivity`). The native code is a shared library (`.so`) loaded by the Java runtime — not a standalone executable. The `fn main()` entry point convention does not apply.

### What Would Work on Android Without Code Changes

| Component | Android Status | Notes |
|---|---|---|
| `tiny-skia` | ✅ Pure Rust, compiles to Android targets | ARM NEON SIMD supported |
| `mlua` (vendored Lua) | ✅ Cross-compiles with NDK toolchain | Lua C sources compile via NDK's `clang` |
| `rodio` / `cpal` | ✅ AAudio backend (Android 5.0+) | Requires AAudio feature in cpal |
| `image` 0.24 | ✅ Pure Rust | — |
| `serde` / `serde_json` | ✅ Pure Rust | — |
| `minifb` | ❌ No Android support | Hard blocker |

### Required Architecture Changes

1. **Replace minifb with a windowing library that supports Android:**
   - **`winit`** — The standard choice. Supports Android via `android-activity` crate. Tier 1 community support.
   - **`android-activity`** — Lower-level NativeActivity/GameActivity integration.
   - The entire `App::run()` game loop must be restructured around `winit`'s event loop.

2. **Change entry point:**
   - Add `crate-type = ["cdylib"]` to the `[lib]` section.
   - Use `#[no_mangle] pub extern "C" fn android_main()` entry point (via `android-activity`) or the `winit` `main_loop!` macro.

3. **Replace filesystem access:**
   - Android has a sandboxed filesystem. Asset files are accessed via the Android AssetManager, not raw filesystem paths.
   - `GameFS` needs an Android-aware backend.

4. **Pixel buffer rendering:**
   - On Android, rendering to an `ANativeWindow` (via `winit`'s raw window handle) is required instead of `Window::update_with_buffer()`.
   - tiny-skia's Pixmap can still be used; the pixel buffer just needs to be pushed to `ANativeWindow` surface instead.

### Build Toolchain Requirements

Installing on the **build machine** (Windows, Linux, or macOS):

```powershell
# 1. Android Rust targets
rustup target add aarch64-linux-android       # ARM64 (modern devices)
rustup target add armv7-linux-androideabi     # 32-bit ARM (older devices)
rustup target add i686-linux-android          # x86 (emulator)
rustup target add x86_64-linux-android        # x86_64 (emulator / some Chromebooks)

# 2. Android NDK (r25 or later recommended)
#    Download from: https://developer.android.com/ndk/downloads
#    Set ANDROID_NDK_HOME or ANDROID_HOME

# 3. Java JDK 17+
#    Required by cargo-apk / Gradle

# 4. cargo-apk (build tool)
cargo install cargo-apk
# OR: xbuild (more modern, supports iOS too)
cargo install xbuild
```

cargo-apk links the Rust shared library, generates an `AndroidManifest.xml`, packages it with the assets, and signs the APK using a debug keystore.

### Minimum Android API Version

- cpal's AAudio backend requires Android API 26 (Android 8.0 Oreo).
- If targeting older devices, a fallback to OpenSLES may be needed.
- `cargo-apk` defaults to `min_sdk_version = 23` (Android 6.0).

### Summary: Android Refactoring Scope

1. Replace `minifb` with `winit` + `android-activity`
2. Rearchitect `App::run()` around `winit`'s event loop model
3. Restructure entry point for `cdylib` + `android_main`
4. Add Android AssetManager integration to `GameFS`
5. Replace pixel buffer upload from `Window::update_with_buffer()` to ANativeWindow surface

**Estimated scope:** 2–4 months of significant work, heavily dependent on how cleanly the windowing abstraction is extracted.

---

## 5. iOS Builds

### Status: MAJOR REFACTORING REQUIRED + APPLE HARDWARE MANDATORY

iOS shares all of Android's architectural blockers, plus adds the hard constraint that iOS builds **must** be compiled on macOS. Apple prohibits cross-compiling iOS apps from non-Apple hardware at the toolchain level (Xcode is macOS-only, and the iOS SDK is legally tied to macOS).

### Root Blocker: minifb Has No iOS Support

Same as Android — minifb does not support iOS. The Cocoa/AppKit backend used on macOS is different from UIKit (iOS). iOS would require a UIKit-based rendering surface.

### What Would Work on iOS Without Code Changes

| Component | iOS Status | Notes |
|---|---|---|
| `tiny-skia` | ✅ Compiles to `aarch64-apple-ios` | Pure Rust |
| `mlua` (vendored Lua) | ✅ Cross-compiles to iOS targets via Xcode toolchain | No JIT allowed on iOS (App Store) |
| `rodio` / `cpal` | ✅ CoreAudio backend on iOS | Same CoreAudio used on macOS |
| `image` 0.24 | ✅ Pure Rust | — |
| `minifb` | ❌ No iOS support | Hard blocker |

### Required Architecture Changes

Same as Android but for UIKit instead of NativeActivity:
1. Replace minifb with `winit`, which supports iOS via `UIApplicationDelegate` + `UIWindow`.
2. Restructure entry point: iOS uses `fn main() { /* UIKit startup */ }` via `winit`'s iOS integration.
3. Replace filesystem with sandboxed iOS Documents/Caches directories.
4. Remove any JIT usage in mlua — iOS App Store policy **prohibits runtime code generation** (JIT). The `vendored` feature with standard Lua 5.4 (interpreter mode, no JIT) is App Store compliant since it runs in interpreted mode without JIT.

### Build Machine Requirements

An Apple Silicon or Intel Mac running macOS 13+ (Ventura) is mandatory:

```bash
# On macOS only:
xcode-select --install    # Xcode Command Line Tools (minimum for CLI builds)
# OR: Install full Xcode from App Store (required for device deployment + App Store)

# iOS targets
rustup target add aarch64-apple-ios            # Physical devices (arm64)
rustup target add aarch64-apple-ios-sim        # Simulator on Apple Silicon
rustup target add x86_64-apple-ios             # Simulator on Intel Mac

# Build tools
cargo install cargo-lipo     # Fat binary creation
# OR use xbuild for APK/IPA cross-platform:
cargo install xbuild
```

### Apple Developer Account

- **Simulator testing:** Free — no developer account needed.
- **Physical device deployment:** Requires an Apple Developer account (free tier allows sideloading to personal devices with limitations).
- **App Store distribution:** Requires Apple Developer Program ($99/year).

### Code Signing

All iOS app deployments require code signing with:
- A signing certificate (from Apple Developer portal)
- A provisioning profile (device-specific or wildcard)

`xbuild` automates most of this process when certificates are available.

### Summary: iOS Refactoring Scope

1. Mandatory: macOS build machine with Xcode
2. Replace `minifb` with `winit` (same change as Android)
3. Rearchitect `App::run()` around UIKit event loop
4. Add sandboxed filesystem backend
5. Replace pixel buffer rendering with Metal or UIView-based surface

**Estimated scope:** 3–5 months (larger than Android due to signing, provisioning, and App Store compliance requirements).

---

## 6. Shared Refactoring Path: The "Portable Core" Strategy

If mobile and/or WASM support is a future goal, the most efficient path is a single refactoring that enables all platforms simultaneously, rather than platform-by-platform rewrites.

### Recommended Approach

Replace `minifb` with `winit` as the windowing and event loop abstraction. `winit` supports:

| Platform | `winit` status |
|---|---|
| Windows | ✅ |
| macOS | ✅ |
| Linux (X11 + Wayland) | ✅ |
| Android | ✅ (via `android-activity`) |
| iOS | ✅ |
| WebAssembly | ✅ (via `web-sys`) |

This single dependency swap unblocks Android, iOS, and WASM platform work simultaneously. The tiny-skia rendering pipeline, the Lua VM (mlua), and the physics/audio/math modules are all platform-agnostic and would not require changes.

### Architecture with winit

The current architecture:
```
minifb::Window::new() → blocking while loop → Window::update_with_buffer()
```

The winit architecture:
```
winit::EventLoop::new() → event_loop.run(|event, target| { … }) → surface.present()
```

The `App::run()` method becomes event-driven rather than polling. The SharedState and Lua callbacks remain unchanged — only the shell changes.

### Remaining Gap: mlua on WASM

Even with `winit`, the WASM target still cannot use mlua via `wasm32-unknown-unknown`. The Emscripten path (`wasm32-unknown-emscripten`) would allow mlua but breaks compatibility with modern browser tools. This gap is the hardest to solve without replacing the scripting language or waiting for a future mlua `wasm32-unknown-unknown` implementation.

---

## 7. Dependency Matrix by Platform

| Dependency | Windows | Linux | macOS | Android | iOS | WASM (wasm32-unk-unk) | WASM (Emscripten) |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `minifb` | ✅ | ✅ | ✅ | ❌ | ❌ | ⚠️ experimental | ❌ |
| `tiny-skia` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `mlua` (vendored) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| `rodio`/`cpal` | ✅ WASAPI | ✅ ALSA/PW/PA | ✅ CoreAudio | ✅ AAudio | ✅ CoreAudio | ✅ Web Audio | ❌ |
| `image` 0.24 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `directories` | ✅ | ✅ | ✅ | ✅* | ✅* | ❌ | ❌ |
| `serde`/`serde_json` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `winresource` | ✅ | N/A | N/A | N/A | N/A | N/A | N/A |

*`directories` compiles on Android/iOS but may not map correctly to mobile-specific paths without additional configuration.

---

## 8. Effort Estimation by Platform

### Linux (< 1 day)
- No code changes
- Install system packages
- Add target with `rustup target add`
- Add to CI matrix

### macOS (< 1 day)
- No code changes
- Requires macOS machine or CI macOS runner
- `xcode-select --install` on fresh system
- Optionally build universal binary with `cargo-lipo`

### Android (2–4 months)
- Phase 1: Extract windowing abstraction behind a trait (2–3 weeks)
- Phase 2: Replace minifb with winit (2–3 weeks, impacts app.rs heavily)
- Phase 3: Android-specific entry point, NativeActivity / GameActivity (1–2 weeks)
- Phase 4: Android filesystem/assets (1 week)
- Phase 5: Testing on physical device and emulator (2–3 weeks ongoing)

### iOS (3–5 months)
- Phases 1–4 shared with Android work above (if winit migration already done: 1–2 months)
- Plus: macOS build environment setup
- Plus: Code signing, provisioning profiles
- Plus: App Store compliance review

### WebAssembly (3–6 months)
- Phase 1: Resolve mlua WASM incompatibility — either find an alternative Lua runtime or accept Emscripten constraints (1–3 months investigation/decision)
- Phase 2: `requestAnimationFrame`-based game loop replacing `while window.is_open()` (2–4 weeks)
- Phase 3: Canvas 2D pixel rendering path replacing `Window::update_with_buffer()` (2–3 weeks)
- Phase 4: DOM event listeners for keyboard/mouse (1 week)
- Phase 5: In-memory VFS / Fetch API filesystem (2 weeks)
- Phase 6: Browser-compatible build pipeline (Trunk or wasm-pack) (1 week)

---

## 9. References

- **minifb platform support:** https://github.com/emoon/rust_minifb — "Currently macOS, Linux and Windows (64-bit and 32-bit) are the current supported platforms."
- **mlua WASM:** https://github.com/mlua-rs/mlua — "WebAssembly (WASM) is supported through the `wasm32-unknown-emscripten` target for all Lua/Luau versions excluding JIT."
- **cpal supported platforms:** https://github.com/RustAudio/cpal — Android (AAudio), iOS (CoreAudio), Linux (ALSA/PipeWire/PulseAudio), macOS (CoreAudio), WebAssembly (Web Audio API / AudioWorklet), Windows (WASAPI).
- **tiny-skia:** https://github.com/linebender/tiny-skia — Pure Rust, no platform-specific code, compiles to all Rust targets. WASM Relaxed SIMD supported.
- **cargo-apk:** https://github.com/rust-mobile/cargo-apk — Android APK packaging for Rust native libraries.
- **xbuild:** https://github.com/rust-mobile/xbuild — Cross-platform build tool supporting Android, iOS, Linux AppImage, Windows MSIX.
- **Roadmap reference:** `docs/roadmap.md` — "Web export: WASM target" and "Mobile: Android/iOS support" listed under Future Considerations.
