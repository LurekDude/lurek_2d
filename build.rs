// build.rs — Luna2D build script
//
// Responsibilities:
//   1. If assets/splash.png exists → set cfg(luna2d_has_splash) so app.rs
//      can use the embedded PNG instead of the procedural fallback.
//   2. On Windows — embed assets/icon.ico into the .exe via winresource
//      (requires:  [build-dependencies] winresource = "0.1" in Cargo.toml).

use std::env;
use std::path::Path;

fn main() {
    let manifest = env::var("CARGO_MANIFEST_DIR").unwrap();

    // ── Declare custom cfg so rustc doesn't warn about unexpected names ───────
    println!("cargo:rustc-check-cfg=cfg(luna2d_has_splash)");

    // ── 1. Splash PNG detection ──────────────────────────────────────────────
    let splash = Path::new(&manifest).join("assets").join("splash.png");
    if splash.exists() {
        println!("cargo:rustc-cfg=luna2d_has_splash");
        // Re-run build.rs if the PNG changes
        println!("cargo:rerun-if-changed=assets/splash.png");
    }

    // ── 2. Always rerun if icon changes ─────────────────────────────────────
    println!("cargo:rerun-if-changed=assets/icon.ico");

    // ── 3. Windows icon embedding ───────────────────────────────────────────
    #[cfg(target_os = "windows")]
    {
        let icon = Path::new(&manifest).join("assets").join("icon.ico");
        if icon.exists() {
            let mut res = winresource::WindowsResource::new();
            res.set_icon(icon.to_str().unwrap());
            res.set("FileDescription", "Luna2D Game Engine");
            res.set("ProductName", "Luna2D");
            res.set("FileVersion", env!("CARGO_PKG_VERSION"));
            res.set("ProductVersion", env!("CARGO_PKG_VERSION"));
            res.set("LegalCopyright", "MIT Licence");
            if let Err(e) = res.compile() {
                // Non-fatal: warn but don't break the build (e.g. on CI without RC tools)
                eprintln!("cargo:warning=winresource: {e}");
            }
        } else {
            eprintln!(
                "cargo:warning=assets/icon.ico not found — restore the prebuilt raster asset or rebuild it from assets/svg/col_icon.png"
            );
        }
    }
}
