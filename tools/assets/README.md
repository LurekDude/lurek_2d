# tools/assets — Engine Artwork

All engine artwork in `assets/` is maintained **manually**. Place your ICO,
PNG, and other image files directly in `assets/` — no generators needed.

## Assets

| File | Purpose |
|---|---|
| `assets/favicon.ico` | Windows executable icon (embedded by `build.rs` via winresource) |
| `assets/splash.png` | Engine splash screen (displayed when no game is loaded) |
| `assets/banner.png` | Branding banner image |
| `assets/icon.png` | Standard icon PNG |
| `assets/icon-large.png` | High-resolution icon PNG |

## Notes

The **Windows binary icon** is embedded at compile time from `assets/favicon.ico`
by `build.rs`. Replacing the file and rebuilding will update the embedded icon.

The **runtime splash screen** is drawn via `make_splash_commands()` in
`src/engine/app.rs`. Replace `assets/splash.png` and rebuild to update it.
