# Localization Demo

**Category:** showcase

Multi-language localization showcase demonstrating instant language switching, variable interpolation, pluralization with language-specific rules, locale-aware number and time formatting, and a mock game menu with translated buttons.

## Run

```
cargo run -- content/games/showcase/localization_demo
```

## Controls

| Key    | Action             |
| ------ | ------------------ |
| 1      | Switch to English  |
| 2      | Switch to French   |
| 3      | Switch to Spanish  |
| 4      | Switch to Polish   |
| R      | Toggle RTL preview |
| Enter  | Start (from title) |
| Escape | Quit               |

## What It Demonstrates

- `lurek.input.bind()` — named action bindings for language switching and RTL toggle
- `lurek.camera.new()` — camera setup for world/UI render split
- `lurek.particles.newSystem()` — confetti burst on language switch
- `lurek.tween.to()` — text fade transitions and menu button slide animations
- `lurek.render.print()` — localized text rendering across all UI elements
- `lurek.render.drawRect()` — styled menu buttons with hover states
- `lurek.render.setBackgroundColor()` — dark themed background
- `lurek.time.getFPS()` — live FPS counter in header
- `lurek.signal.quit()` — clean exit on Escape
- `lurek.window.setTitle()` — window title configuration

## Features

- 4 languages (English, French, Spanish, Polish) with 25 translation keys
- Instant language switching with confetti particle celebration
- Variable interpolation: "Welcome, {name}!" with dynamic substitution
- Pluralization with language-specific rules (Polish singular/few/many)
- Locale-aware number formatting: "1,234.56" (EN) vs "1 234,56" (PL/FR)
- Localized time display: 12-hour AM/PM (EN) vs 24-hour (FR/ES/PL)
- Mock game menu with translated buttons and hover highlighting
- Coverage meter showing translation completeness per language
- Missing key indicator in red: "[MISSING: key]"
- RTL preview mode (press R) mirrors text alignment
- Title screen with animated reveal before browsing state

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particles`, `lurek.tween`, `lurek.time`, `lurek.signal`
