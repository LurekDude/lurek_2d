# Genre → API Patterns

Pre-mapped table of common game genres with recommended `lurek.*` API namespaces,
library modules, conf.lua resolution, and structural notes.

Use this to bootstrap `main.lua` and `conf.lua` choices for a given genre.

---

## Quick Reference Table

| Genre | Resolution | Key `lurek.*` APIs | Library Modules | Complexity |
|-------|-----------|-------------------|-----------------|------------|
| Action / Shooter | 960×540 | graphics, physics, input, timer, audio | — | Medium |
| AI / Pathfinding | 800×600 | graphics, ai, pathfinding, entity, timer | — | Medium–High |
| Automation / Factory | 1024×768 | graphics, tilemap, entity, timer, event | — | High |
| Card Game / CCG | 800×600 | graphics, mouse, keyboard, animation | item, inventory | Medium |
| Colony / City Sim | 1024×768 | graphics, tilemap, entity, timer, event | economy, crafting (Stub) | High |
| Deck Builder | 800×600 | graphics, mouse, keyboard, scene | item, inventory | Medium–High |
| Dialog / Visual Novel | 800×600 | graphics, audio, keyboard, mouse, scene | dialog | Medium |
| Endless Runner | 960×540 | graphics, physics, input, timer, audio | — | Simple |
| Fighting Game | 960×540 | graphics, physics, input, animation, audio | — | Medium |
| Fishing / Sports | 800×600 | graphics, physics, input, timer | — | Simple |
| God Game / Sim | 1024×768 | graphics, camera, entity, tilemap, event | — | High |
| Hacking / Terminal | 800×640 | graphics, terminal, keyboard, event | — | Medium |
| Horror / Stealth | 800×600 | graphics, audio, light, physics, input | — | Medium–High |
| Idle / Tycoon | 800×600 | graphics, mouse, keyboard, savegame, timer | economy (Stub) | Medium |
| Metroidvania | 960×540 | graphics, physics, camera, animation, audio | item, inventory | High |
| Mining / Crafting | 800×600 | graphics, tilemap, physics, input | crafting (Stub) | Medium |
| Platformer | 960×540 | graphics, physics, camera, input, audio | — | Medium |
| Portal / Physics Puzzle | 800×600 | graphics, physics, input, camera | — | Medium |
| Puzzle | 800×600 | graphics, mouse, keyboard, event | — | Simple–Medium |
| Racing / Driving | 960×540 | graphics, physics, input, camera, audio | — | Medium |
| Rhythm Game | 800×600 | graphics, audio, input, timer | — | Medium |
| Roguelike / Dungeon | 800×640 | graphics, keyboard, event | — | Medium–High |
| Roguelite | 800×640 | graphics, physics, keyboard, event | item, inventory | High |
| RPG / Loot | 800×600 | graphics, keyboard, mouse, camera | item, inventory | High |
| RTS / Strategy | 1024×768 | graphics, camera, entity, pathfinding, event | — | High |
| Survival / Crafting | 1024×768 | graphics, physics, tilemap, input | item, inventory | High |
| Tower Defense | 1024×768 | graphics, pathfinding, entity, timer, event | — | High |
| Turn-Based Strategy | 1024×768 | graphics, mouse, keyboard, event, tilemap | — | Medium–High |
| Visual Novel | 800×600 | graphics, audio, keyboard, scene, animation | dialog | Medium |

---

## Detailed Genre Notes

### Platformer
- Use `lurek.physics` for bodies or manual AABB (both patterns are acceptable)
- Camera follows player with easing via `lurek.math.applyEasing("outCubic", ...)`
- Audio for footsteps/jumps should be guarded with `pcall` (graceful no-audio fallback)
- Resolution: 960×540 for wide level view

### Roguelike
- Turn-based: `lurek.update` may be empty (logic fires in `lurek.keypressed`)
- Fog of war / FOV can be pure Lua arrays — no `lurek.physics` needed
- Resolution: 800×640 to fit message log at bottom (6–8 line history strip)
- `lurek.gfx.print()` with a small monospaced font for dungeon grid

### Card Game / Deck Builder
- State machine: `MENU → DRAW → PLAY → RESOLVE → END`
- Drag-and-drop: `lurek.mouse.getPosition()` + hit-test rectangle helpers
- Card data as Lua tables with `id`, `name`, `cost`, `effect` fields
- `library.item` + `library.inventory` replace hand-rolled card tracking in richer demos

### Dialog / Visual Novel
- Always use `library.dialog` — **do not reimplement** the sequencer
- Dialog assets (portraits, backgrounds) go in `content/demos/<name>/assets/`
- Text rendering uses `lurek.gfx.print()` inside a letterbox at bottom 25% of screen
- Keyboard `space`/`enter` advance; `up`/`down` select choice

### Horror / Stealth
- `lurek.light.*` for dynamic lighting / shadow cones
- `lurek.audio.*` ambient loop started in `lurek.load()` and stopped in `lurek.keypressed("escape")`
- Guard vision cone can use `lurek.physics.raycast()` against walls

### AI / Pathfinding
- `lurek.ai.*` for FSM / behavior trees
- `lurek.pathfinding.*` for A* grid navigation
- `lurek.entity.*` for actor lifecycle management
- Show debug overlay drawing: paths, FSM state labels

### Automation / Factory
- `lurek.tilemap.*` for the grid world
- `lurek.signal.*` for producer-consumer item queue across belts
- Keep entity count < 500 for 60 FPS on integrated GPU (design constraint B-03)

### RTS / Strategy
- `lurek.camera.*` for pan/zoom; bind scroll to middle-mouse-drag
- `lurek.pathfinding.*` for unit movement
- Selection box: track drag start/end in `lurek.mousepressed`/`lurek.mousereleased`

---

## lurek.* Namespace Quick Reference

For the full API surface run:
```powershell
cat docs/API/lua_api_reference_generated.md
```

Or check `docs/API/lua-api.md` (regenerate with `python tools/gen_all_docs.py` if stale).
