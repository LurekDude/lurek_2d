# gui — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/gui.md`
**Files**: Retained-mode widget toolkit

## Purpose

GUI system: retained-mode widget tree with layout, styling, and event handling. For in-game UI (HUD, menus, dialogs, inventory).

## Current Feature Summary

- Widget hierarchy: parent-child tree with automatic layout
- Core widgets: Label, Button, Panel, TextInput, Checkbox, Slider, ProgressBar, List, Dropdown, Image, ScrollView
- Layout modes: Vertical, Horizontal, Grid, Absolute
- Styling: per-widget colors, fonts, padding, margins
- Event handling: onClick, onChange, onHover callbacks per widget
- Nine-slice backgrounds for panels
- Focus/keyboard navigation
- Widget visibility, enabled/disabled states
- Text wrapping in labels

## Feature Gaps

1. **No flexbox/CSS-like layout**: Layout modes are simple (V/H/Grid/Abs). No flex-grow, flex-shrink, align-items, justify-content. Complex responsive layouts are hard.
2. **No theming/skins system**: No way to define a theme (colors, fonts, spacing) and apply it globally. Must style each widget individually.
3. **No data binding**: No automatic synchronization between UI widgets and game data. Must manually update labels when values change.
4. **No drag-and-drop**: Can't drag widgets between containers (essential for inventory, card games, crafting).
5. **No rich text in labels**: Can't mix colors/fonts within a single label.
6. **No tooltips**: No built-in tooltip on hover. Very common UI need.
7. **No modal dialogs**: No built-in modal system (block input to background, dimmed overlay).
8. **No tab bar / tabbed panels**: No tab widget for settings screens with multiple pages.
9. **No accessibility**: No screen reader support, no high-contrast mode, no text scaling independent of UI scaling.
10. **No animation**: No built-in widget animations (fade in, slide, scale on hover).

## Structural Issues

- **Retained mode vs immediate mode**: Lurek2D chose retained mode (widget tree). Good for complex UIs but more complex to implement. Most Lua game engines have minimal UI — Lurek2D is ahead here.
- **No integration with entity/scene**: Widgets exist in a separate tree from game entities. Can't attach UI to world-space positions (health bars over entities) easily.
- **Layout is basic**: V/H/Grid/Abs covers 80% of cases but the remaining 20% (responsive, flex) require workarounds.

## Suggestions

1. **Add theming system**: `lurek.ui.setTheme({primary="#2196F3", font="default", spacing=8})` — global style application. Huge productivity boost for consistent UI.
2. **Add drag-and-drop**: `widget:setDraggable(true)` / `container:setDropTarget(true, onDrop)` — enables inventory, card games, editor tools.
3. **Add tooltips**: `widget:setTooltip(text)` or `widget:setTooltip(widgetTree)` — hover tooltip with configurable delay.
4. **Add data binding**: `label:bind("text", gameState, "playerHealth")` — auto-update when value changes. Reactive UI pattern.
5. **Add widget animations**: `widget:fadeIn(duration)`, `widget:slideIn(direction, duration)` — polish.
6. **Add world-space UI anchor**: `widget:attachToEntity(entity, offsetX, offsetY)` — health bars, name tags above game entities.
7. **Add flexbox layout**: Implement flex-grow, flex-shrink, align-items at minimum. This is the industry standard for UI layout.

## Competitor Comparison

| Feature | Lurek2D | Engine A | Engine B | Engine D |
|---|---|---|---|---|
| Widget toolkit | ✅ (retained) | ❌ (libs only) | ✅ (widget lib) | ✅ (full UI) |
| Layout engine | ✅ (basic) | N/A | ❌ | ✅ (flexbox) |
| Theming | ❌ | N/A | ❌ | ✅ |
| Drag and drop | ❌ | N/A | ❌ | ✅ |
| Data binding | ❌ | N/A | ❌ | ✅ (reactive) |
| Widget types | 11 | N/A | 8 | 15+ |
| Tooltips | ❌ | N/A | ❌ | ✅ |

## Priority

**HIGH** — GUI is already ahead of most Lua engines. Theming, drag-and-drop, and data binding would make it production-ready. Flexbox layout is the gold standard.
