# Fighting Game

A two-character 2D fighting game featuring a local player versus a reactive AI opponent. The game tracks rounds, builds a combo counter on successive hits, fills a super meter that unlocks a powerful charged attack, and applies screen shake on heavy blows. The match continues until one fighter wins two rounds.

## What It Demonstrates

- `luna.keyboard.isDown()` — per-frame directional movement and attack input polling
- `luna.graphics.rectangle()` / `luna.graphics.circle()` — fighter body, health bar, and super-meter rendering
- `luna.graphics.setColor()` — dynamic color shifts for damage flash and super-charge state
- `luna.graphics.print()` — combo counter pop-up text and round HUD
- `luna.window.setTitle()` — setting the window caption at load time
- `luna.graphics.setBackgroundColor()` — dark purple stage background
- Manual AABB collision — attack hitboxes computed each frame without a physics engine
- Simple probability-based AI — randomised punch/kick/block decisions with range gating

## How to Run

```powershell
cargo run -- demos/fighting_game
```

## Controls

| Input | Action |
|-------|--------|
| A / D | Move left / right |
| W | Jump |
| F | Punch |
| G | Kick |
| H | Block |
| Escape | Quit |

## Notes

- P2 is fully AI-controlled; it approaches, attacks at close range, and uses its super move when the meter is full
- Landing a blocked attack still builds the blocker's super meter
- `screenShake` is applied as a random offset to the draw origin for heavy hits (kicks and super attacks)
- Combo text is pushed into a list and rendered with fading timers — no retained-mode UI needed
