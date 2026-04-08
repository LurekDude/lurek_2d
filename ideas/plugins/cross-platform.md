# Plugin Architecture — Cross-Platform Considerations

## Platform Matrix

| Platform | DLL Extension | Loader API | GPU Backend | Plugin Support | Phase |
|----------|--------------|------------|-------------|---------------|-------|
| Windows x86_64 | `.dll` | `LoadLibrary` / `libloading` | DX12 (wgpu) | Full | Phase 2 |
| Linux x86_64 | `.so` | `dlopen` / `libloading` | Vulkan (wgpu) | Full | Phase 6 |
| macOS x86_64 | `.dylib` | `dlopen` / `libloading` | Metal (wgpu) | Full | Phase 6 |
| macOS ARM64 | `.dylib` | `dlopen` / `libloading` | Metal (wgpu) | Full | Phase 6 |
| Linux ARM64 | `.so` | `dlopen` / `libloading` | Vulkan (wgpu) | Full¹ | Phase 6 |
| iOS | `.framework` | `dlopen` forbidden² | Metal (wgpu) | Static only | Phase 10+ |
| Android | `.so` | `dlopen` (NDK) | Vulkan/GLES (wgpu) | Partial³ | Phase 10+ |
| WASM | `.wasm` | N/A | WebGPU (wgpu) | Lua-only⁴ | Phase 10+ |

¹ Raspberry Pi 4/5 can run Vulkan via Mesa; earlier models may need software rendering.
² App Store rejects apps that load executable code at runtime (except JavaScript).
³ Android supports `.so` loading via NDK but requires native ABI matching (armeabi-v7a, arm64-v8a, x86_64).
⁴ WASM cannot load native DLLs; plugins must be pure Lua or compiled to WASM modules.

---

## Desktop Platforms (Phase 2 + Phase 6)

### Windows

**Status**: Primary development platform. Plugin loading implemented first here.

- **Library format**: `.dll` (PE/COFF)
- **Loading**: `LoadLibraryW` (via `libloading`)
- **Symbol export**: `#[no_mangle] pub extern "C" fn luaopen_*()`
- **Search path**: `plugins/` relative to exe, then `search_paths` from `conf.toml`
- **Naming**: `luna_gamedev.dll` (no `lib` prefix)
- **Architecture**: x86_64 only (per A-02; no 32-bit builds)
- **Code signing**: Optional — Windows SmartScreen shows a warning for unsigned DLLs
  but does not block loading
- **DLL Hell**: Plugins should not depend on Visual C++ runtime DLLs. Build with
  `+crt-static` in Rust to avoid MSVCRT version conflicts:
  ```toml
  # .cargo/config.toml
  [target.x86_64-pc-windows-msvc]
  rustflags = ["-C", "target-feature=+crt-static"]
  ```

**Known issues**:
- `LoadLibrary` locks the DLL file — cannot overwrite while loaded (affects hot-reload)
- Anti-virus may scan DLLs on load, adding 100–500ms to startup time
- Windows Defender may flag unsigned DLLs from unknown publishers

### macOS

**Status**: Supported platform, tested on both Intel and Apple Silicon.

- **Library format**: `.dylib` (Mach-O)
- **Loading**: `dlopen` (via `libloading`)
- **Symbol export**: Same as Windows (`#[no_mangle] pub extern "C"`)
- **Search path**: `plugins/` relative to exe, then `search_paths`
- **Naming**: `libluna_gamedev.dylib` (note `lib` prefix — standard on Unix)
- **Architecture**: x86_64 + aarch64 (universal binary possible but not required)
- **Code signing**: Required for distribution. Unsigned libraries trigger Gatekeeper:
  ```
  "libluna_gamedev.dylib" cannot be opened because the developer cannot be verified.
  ```
  **Mitigation**: Distribute plugins inside a signed `.app` bundle, or instruct users
  to run `xattr -d com.apple.quarantine libluna_gamedev.dylib`
- **Notarization**: Apple requires notarization for distribution outside the App Store.
  This includes all `.dylib` files.
- **`@rpath` / `@loader_path`**: Set `install_name_tool` paths correctly so the plugin
  finds its dependencies. Since plugins depend only on mlua (which links LuaJIT
  statically), this is usually not an issue.

**macOS-specific build flags**:
```toml
# .cargo/config.toml
[target.x86_64-apple-darwin]
rustflags = ["-C", "link-arg=-Wl,-rpath,@loader_path/plugins"]

[target.aarch64-apple-darwin]
rustflags = ["-C", "link-arg=-Wl,-rpath,@loader_path/plugins"]
```

### Linux

**Status**: Supported platform.

- **Library format**: `.so` (ELF)
- **Loading**: `dlopen` (via `libloading`)
- **Symbol export**: Same as other platforms
- **Search path**: `plugins/` relative to exe, then `search_paths`, then standard
  `LD_LIBRARY_PATH` fallback
- **Naming**: `libluna_gamedev.so` (with `lib` prefix)
- **Architecture**: x86_64 primary, aarch64 secondary
- **Code signing**: Not required by the OS. Distribution channels (Flatpak, Snap,
  AppImage) have their own sandboxing.
- **`RUNPATH`**: Set `RUNPATH` in the executable to find plugins:
  ```toml
  [target.x86_64-unknown-linux-gnu]
  rustflags = ["-C", "link-arg=-Wl,-rpath,$ORIGIN/plugins"]
  ```

**Linux-specific considerations**:
- Distro packaging: `.deb`/`.rpm` packages should install plugins to
  `/usr/lib/luna2d/plugins/`
- Flatpak/AppImage: bundle plugins inside the container
- SELinux: some distros restrict `dlopen` on home-directory files — install to
  `/usr/lib/` or adjust SELinux policy

---

## Plugin File Naming Convention

```
Platform    | File Name                | Cargo crate name
------------|--------------------------|------------------
Windows     | luna_gamedev.dll         | luna2d-gamedev
macOS       | libluna_gamedev.dylib    | luna2d-gamedev
Linux       | libluna_gamedev.so       | luna2d-gamedev
```

The `PluginLoader` maps plugin names to platform-specific filenames:

```rust
fn platform_filename(name: &str) -> String {
    #[cfg(target_os = "windows")]
    { format!("luna_{name}.dll") }
    #[cfg(target_os = "macos")]
    { format!("libluna_{name}.dylib") }
    #[cfg(target_os = "linux")]
    { format!("libluna_{name}.so") }
}
```

---

## Mobile Platforms (Future — Requires A-02 Update)

### iOS

**Feasibility**: LOW for native plugins.

Apple's App Store Review Guidelines §2.5.2:
> "Apps that download code in any way or form will be rejected."

This means:
- No `dlopen` for third-party plugins distributed after installation
- **Static linking only**: plugins must be compiled into the app binary at build time
- Lua-only plugins (pure `.lua` files) are allowed — they're interpreted, not compiled

**Static plugin strategy for iOS**:
```rust
// Plugins are compiled in at build time, not loaded at runtime
fn register_plugins(lua: &Lua) -> LuaResult<()> {
    #[cfg(feature = "plugin-gamedev")]
    luna2d_gamedev::register_all(lua)?;

    #[cfg(feature = "plugin-business")]
    luna2d_business::register_all(lua)?;

    Ok(())
}
```

### Android

**Feasibility**: MEDIUM for native plugins.

Android supports loading `.so` files via the NDK's `dlopen`, but:
- Libraries must be bundled in the APK's `lib/<abi>/` directory
- Cannot download and load `.so` from arbitrary paths (security sandbox)
- Must match the device's ABI (armeabi-v7a, arm64-v8a, x86_64)

**Strategy**: Bundle plugin `.so` files in the APK at build time. Runtime "downloading"
new plugins is theoretically possible but violates Play Store policies for most cases.

### WASM / WebAssembly

**Feasibility**: LOW for current DLL-based approach.

WASM has no equivalent of `dlopen`. Possible alternatives:
1. **WASI Components** — emerging standard for modularizing WASM modules. Not mature.
2. **Lua-only plugins** — ship pure Lua files alongside the WASM binary. These load
   via `require()` and work today.
3. **Compile-time plugin linking** — include plugins in the WASM build. Same as iOS.

---

## Cross-Compilation Matrix

Building Luna2D plugins for different platforms from a single development machine:

| Build From → | Windows Target | macOS Target | Linux Target |
|-------------|---------------|-------------|-------------|
| Windows | Native | Cross-compile (osxcross) | Cross-compile (WSL, cross-rs) |
| macOS | Cross-compile (MinGW, cross-rs) | Native | Cross-compile (cross-rs) |
| Linux | Cross-compile (MinGW, cross-rs) | Cross-compile (osxcross) | Native |

**Recommended CI setup** (GitHub Actions):
```yaml
jobs:
  build-plugins:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        plugin: [luna2d-gamedev, luna2d-business]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: cargo build --release -p ${{ matrix.plugin }}
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.plugin }}-${{ matrix.os }}
          path: build/release/*.{dll,so,dylib}
```

---

## Platform-Specific Testing

| Test | Windows | macOS | Linux |
|------|---------|-------|-------|
| DLL loads successfully | CI + local | CI | CI |
| `luaopen_*` symbol found | CI + local | CI | CI |
| Version check works | CI + local | CI | CI |
| Plugin APIs callable | CI + local | CI | CI |
| Unsigned DLL loads | Auto | Manual (Gatekeeper) | Auto |
| Code-signed DLL loads | Manual (optional) | CI (required) | N/A |
| Anti-virus interference | Manual | N/A | N/A |
| SELinux restriction | N/A | N/A | Manual |

---

## Distribution Packaging Per Platform

### Windows — `.zip` + Optional NSIS Installer
```
luna2d-windows-x86_64/
├── luna2d.exe
├── plugins/
│   ├── luna_gamedev.dll
│   └── luna_business.dll
├── library/
├── demos/
└── README.md
```

### macOS — `.dmg` or `.app` Bundle
```
Luna2D.app/
└── Contents/
    ├── MacOS/
    │   └── luna2d              ← executable
    ├── Frameworks/
    │   ├── libluna_gamedev.dylib
    │   └── libluna_business.dylib
    ├── Resources/
    │   ├── library/
    │   └── demos/
    └── Info.plist
```

### Linux — `.tar.gz` + Optional AppImage
```
luna2d-linux-x86_64/
├── bin/
│   └── luna2d
├── lib/
│   └── luna2d/
│       └── plugins/
│           ├── libluna_gamedev.so
│           └── libluna_business.so
├── share/
│   └── luna2d/
│       ├── library/
│       └── demos/
└── README.md
```

FHS-compatible for `/usr/local/` installation:
```
/usr/local/bin/luna2d
/usr/local/lib/luna2d/plugins/libluna_gamedev.so
/usr/local/share/luna2d/library/
/usr/local/share/luna2d/demos/
```
