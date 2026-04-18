# Deckbuilder

Slay-the-Spire-style turn-based card battler. Build your deck as you climb three floors.

## Run
```
cargo run -- content/games/strategy/deckbuilder
```

## Controls
| Key | Action |
|-----|--------|
| 1–5 | Play card from hand |
| Enter | End turn |
| Q/E | Pick reward card |
| Escape | Quit |

## Gameplay
Fight through three increasingly difficult monsters. Each victory rewards a new card to add to your deck. Manage energy each turn, block incoming attacks, and crush the Dragon to win.

## APIs Used
- `lurek.render` / `lurek.render_ui` — card layout, HP bars, combat log
- `lurek.particles` — hit flash, card play sparks
- `lurek.tween` — HP bar animation
- `lurek.input` — action bindings for card play and turn end
- `lurek.window`, `lurek.signal`

## Changes from Original Demo
### Replaced
- Bare `lurek.render.drawRect` color blocks → structured card panels with type-coloured accent bars
- Manual particle table → `lurek.particles.newSystem` with emit bursts
- Linear HP display → `lurek.tween.to` animated HP bars

### Added
- Stun mechanic (Shockwave card)
- Fortify card (12 block)
- Energy display and per-card affordability dimming
- Combat log with fade timer

### Removed
- Nothing from original gameplay

### Open questions
- Card sprites / artwork not yet wired
