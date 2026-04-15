# IDEA.md — `window` module

> Migrated from `ideas/features/window.md`.
> Status checked against `src/window/` and `src/lua_api/window_api.rs`.
> Lua namespace: `lurek.window`.

---

## Features

### ✅ DONE — Window Creation and Configuration
Title, size, resizability, fullscreen, borderless, always-on-top, minimize/maximize/restore.

---

### ✅ DONE — Viewport Scaling (5 Modes)
**Source**: features/window.md — Summary

Stretch, Letterbox, PixelPerfect, Fixed, None — all implemented.

---

### ✅ DONE — Multi-Display Enumeration with DPI
**Source**: features/window.md — Summary

`lurek.window.getDisplayInfo()` returns display count, DPI, size info.

---

### ✅ DONE — Clipboard Read/Write
**Source**: features/window.md — Summary

`lurek.window.getClipboard()` / `setClipboard(text)`.

---

### ✅ DONE — File Drop Detection
**Source**: features/window.md — Summary

`lurek.window.onFileDrop(fn)` callback fires with dropped file path.

---

### ✅ DONE — Deferred Property Writes (Safe Mid-Frame)
**Source**: features/window.md — Summary

All window property changes applied end-of-frame to avoid mid-frame resize issues.

---

### ✅ DONE — DPI Change Callback
**Source**: features/window.md — Feature Gaps #6 / Suggestions #1

No `lurek.window.onDpiChange(fn)`. When user moves window between monitors with different
DPI, no callback fires and scaling mode doesn't adjust. Important for multi-monitor setups.

---

### ❌ TODO — Runtime Window Icon
**Source**: features/window.md — Suggestions #2

Icon set at build time only (embedded binary). No `lurek.window.setIcon(imageData)` at runtime.

---

### ✅ DONE — Native File Dialog
**Source**: features/window.md — Feature Gaps #1 / Suggestions #3

No `lurek.window.openFileDialog(filters)` or `saveFileDialog()`. Very useful for tools,
level editors, and mod loaders. `rfd` crate would provide this cross-platform.

---

### ❌ TODO — Window Position Control
**Source**: features/window.md — Suggestions #5

No `lurek.window.setPosition(x, y)` for placing the window at a specific screen coordinate.

---

### 🤔 CONSIDER — API Sub-Table Reorganization
**Source**: features/window.md — Structural Issues

39+ functions is a flat namespace. Grouping into sub-tables would improve discoverability:
`lurek.window.display.*`, `lurek.window.cursor.*`, `lurek.window.clipboard.*`.
Breaking change — requires API version bump.
