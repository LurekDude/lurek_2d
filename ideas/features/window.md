# window — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/window.md`
**Files**: Window management, viewport, display info

## Purpose

OS window management via winit: creation, sizing, fullscreen, display enumeration, clipboard, cursor, viewport scaling modes.

## Current Feature Summary

- Window creation with configurable size, title, resizability, fullscreen
- 39+ Lua API functions
- Viewport scaling: 5 modes (Stretch, Letterbox, PixelPerfect, Fixed, None)
- Multi-display enumeration with DPI info
- Clipboard read/write
- Cursor visibility, lock, position
- Deferred writes: window property changes applied at end of frame (avoids mid-frame resize issues)
- Minimize, maximize, restore, always-on-top, borderless
- File drop detection

## Feature Gaps

1. **No multi-window support**: Can't open additional windows (debug tools, inventory, map). Probably acceptable for A-02 desktop-only constraint, but some dev tools benefit from separate windows.
2. **No system tray**: No tray icon or menu. Low priority for games but useful for background applications.
3. **No native notification API**: Can't show OS toasts. Very niche.
4. **No screen recording/capture**: Beyond saveScreenshot — can't record video. Niche but growing need for content creation.
5. **No window transparency**: Can't make window background transparent for overlay-style applications.
6. **No scale factor change event**: If user moves window between monitors with different DPI, no callback fires.

## Structural Issues

- **Viewport overlap with camera**: Window module manages viewport scaling modes, camera module manages viewport/world coordinate mapping. These are related but distinct — window = screen mapping, camera = world mapping. Current separation is correct but could cause confusion.
- **39 functions is large**: Consider grouping into sub-tables: `luna.window.display.*`, `luna.window.cursor.*`, `luna.window.clipboard.*`.

## Suggestions

1. **Add DPI change callback**: `luna.window.setDpiChangeCallback(fn)` — notifies when DPI scale changes (monitor switch).
2. **Add window icon from Lua**: Currently set via build-time embedded icon. Allow `luna.window.setIcon(imageData)` at runtime.
3. **Add native file dialog**: `luna.window.openFileDialog(filters)` → path. Very useful for tools, level editors, mod loaders. Common in desktop engines.
4. **Reorganize API into sub-tables**: Group related functions under `luna.window.display.*`, `luna.window.cursor.*` etc. Reduces flat namespace sprawl.
5. **Add window position**: `luna.window.setPosition(x, y)` — dock window to specific screen coordinates.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Fullscreen | ✅ | ✅ | ✅ | ✅ |
| Viewport scaling | ✅ (5 modes) | ❌ (manual) | ✅ (letterbox) | ✅ |
| Multi-display | ✅ | ✅ | ❌ | ✅ |
| Clipboard | ✅ | ✅ | ❌ | ❌ |
| File drop | ✅ | ✅ | ❌ | ✅ |
| File dialog | ❌ | ❌ | ❌ | ✅ (rfd) |
| Multi-window | ❌ | ❌ | ❌ | ✅ |

## Priority

**LOW** — Window module is solid. File dialog and DPI change callback are nice-to-haves. No critical gaps.
