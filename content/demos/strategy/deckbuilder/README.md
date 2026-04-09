# Deckbuilder

A Slay the Spire-style roguelite deckbuilder with three escalating floors. Spend energy each turn to play attack, block, and heal cards against increasingly tough monsters. Defeat each enemy to choose a card reward that permanently joins your deck for the rest of the run.

## What It Demonstrates

- `luna.gfx.rectangle()` — card frames, HP/block bars, and reward selection panel
- `luna.gfx.setColor()` — energy pips, vulnerability indicators, and hit-flash colouring
- `luna.gfx.print()` — card names, descriptions, combat log, and floor progress
- `luna.mouse.getPosition()` — card hover detection in hand layout
- `luna.mouse.isPressed()` — click-to-play and reward card selection
- `luna.keyboard.isPressed()` — End Turn hotkey
- `luna.gfx.circle()` — particle burst effects on attack and block plays

## How to Run

```powershell
cargo run -- demos/deckbuilder
```

## Controls

| Input | Action |
|-------|--------|
| Click card | Play a card from your hand (costs energy) |
| Enter | End turn (enemy attacks, draw new hand) |
| Click reward card | Add it to your deck after defeating a monster |
| Escape | Quit |

## Notes

- Each turn starts with 3 energy and a fresh draw of 5 cards; the discard reshuffles back into the draw pile automatically.
- Vulnerable status (applied by Bash) causes the affected target to take 50 % extra damage.
- Block is reset to 0 at the start of the entity's next turn and absorbs incoming damage first.
- Particle bursts are spawned at the target position on every card play for visual feedback.
