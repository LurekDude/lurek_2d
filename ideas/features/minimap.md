# minimap — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/minimap.md`
**Files**: Minimap rendering

## Purpose

Minimap system: render a scaled-down view of the game world with icons for entities, fog of war, and customizable display.

## Current Feature Summary

- Minimap rendering from tilemap data
- Entity icons on minimap (configurable per entity type)
- Fog of war overlay
- Minimap viewport tracking (shows current camera area)
- Scale and position configuration
- Shape options: rectangle, circle
- Custom color mapping for tile types
- Click-to-navigate: click minimap to pan camera
- Revealed/explored area tracking (fog of war states: hidden/explored/visible)

## Feature Gaps

1. **No minimap for non-grid worlds**: Only works with tilemaps. Games with continuous worlds (not grid-based) can't use it.
2. **No icon animation**: Minimap icons are static. Blinking, rotation, pulse effects are common for alerts.
3. **No minimap zoom**: Fixed scale factor. Can't zoom in/out on the minimap independently.
4. **No path display**: Can't overlay pathfinding paths on the minimap.
5. **No custom draw on minimap**: Can't draw custom shapes/lines on the minimap (trade routes, borders, areas of influence).
6. **No multi-layer minimap**: Shows one layer of tilemap data. Can't show underground + surface toggle.

## Structural Issues

- **Tight coupling with tilemap**: Minimap requires tilemap data. Games without tilemaps can't use minimap at all. Consider a more generic approach that works with any spatial data.
- **Fog of war scope**: Fog of war is a minimap concern AND potentially a gameplay concern (vision, stealth). Should fog of war live here or be its own module?
- **Correct tier**: Tier 2 is right — depends on tilemap (Tier 2) and camera (Tier 1).

## Suggestions

1. **Generalize beyond tilemap**: Allow minimap from any set of markers: `minimap:addMarker(x, y, icon, color)`. Tilemap-backed rendering is one mode; marker-only is another.
2. **Add minimap zoom**: `minimap:setZoom(level)` — independent zoom control.
3. **Add custom draw layer**: `minimap:drawLine(x1, y1, x2, y2, color)` — overlay custom geometry.
4. **Add icon animation**: `minimap:setIconAnimation(entity, "blink", speed)` — alerts, pulse, rotation.
5. **Separate fog of war**: Consider extracting fog of war into its own module or utility — it's used in RTS, RPG, stealth games even without a minimap.
6. **Add path overlay**: `minimap:showPath(pathPoints, color)` — visualize pathfinding results on minimap.

## Competitor Comparison

No competitor 2D Lua engine has a built-in minimap module. This is unique to Lurek2D.

| Feature | Lurek2D | Engine A | Engine B | Engine D |
|---|---|---|---|---|
| Minimap | ✅ | ❌ | ❌ | ❌ |
| Fog of war | ✅ | ❌ | ❌ | ❌ |
| Click-to-nav | ✅ | N/A | N/A | N/A |
| Icon markers | ✅ | N/A | N/A | N/A |

## Priority

**LOW** — Module is functional for its niche. Generalization beyond tilemap-only and fog of war extraction are the main structural improvements.
