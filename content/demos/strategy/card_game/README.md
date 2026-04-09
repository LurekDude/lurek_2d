# Card Game

A collectible card game (CCG) demo featuring turn-based combat between you and an AI opponent. Each turn your mana pool grows, letting you play increasingly powerful cards from your hand. Defeat the enemy by reducing their HP to zero before they do the same to you.

## What It Demonstrates

- `lurek.gfx.rectangle()` — card rendering with fill and outline passes
- `lurek.gfx.circle()` — mana cost badges drawn on each card
- `lurek.gfx.print()` — multi-field HUD text: HP, mana, shield, log lines
- `lurek.gfx.setColor()` — per-card tint, hover highlight, and status-bar colouring
- `lurek.mouse.getPosition()` — hover detection and click-to-play input
- `lurek.mouse.isPressed()` — single-frame click detection for card selection
- `lurek.keyboard.isPressed()` — End Turn (Enter) and Quit (Escape) hotkeys
- `lurek.gfx.setBackgroundColor()` — dark purple arena atmosphere

## How to Run

```powershell
cargo run -- content/demos/card_game
```

## Controls

| Input | Action |
|-------|--------|
| Click card | Play the hovered card from your hand |
| Enter | End your turn (triggers AI turn) |
| Escape | Quit |

## Notes

- Mana cap increases by 1 each turn up to a maximum of 10, matching the design pattern of many CCGs.
- The AI sorts its hand by cost descending and plays every card it can afford in a single sweep.
- Shields absorb damage first; excess damage carries through to HP.
- The battle log keeps the six most recent events, trimming older entries automatically.
