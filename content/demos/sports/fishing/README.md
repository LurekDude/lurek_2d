# Fishing

A marine fishing simulation where you cast a line, wait for a bite, and reel in a catch using a live tension mini-game. Six fish species are distributed by depth and matched to specific bait types. Each 120-second day ends with an automatic sell phase that tallies earnings.

## What It Demonstrates

- `lurek.keyboard.isDown()` — movement, cast hold, and reel up/down input
- `lurek.keyboard.wasPressed()` — cast release and bait cycling
- `lurek.gfx.setColor()` / `lurek.gfx.rectangle()` — underwater scene, tension bar, and HUD
- `lurek.gfx.circle()` — fish sprites and bobber rendering
- `lurek.time.getTime()` — sinusoidal fish-pull oscillation during the reel phase
- `lurek.mouse.getPosition()` — used indirectly to track cast direction
- Boid-lite fish movement — independent fish entities with random velocity changes
- Depth-gated bite logic — fish only bite when the lure is within their depth range and matches the active bait

## How to Run

```powershell
cargo run -- content/demos/fishing
```

## Controls

| Input | Action |
|-------|--------|
| A / D (or Left / Right) | Move along the dock |
| Hold Space | Charge cast power |
| Release Space | Cast line |
| Up Arrow | Reel in (increases tension) |
| Down Arrow | Release line (decreases tension) |
| Tab | Cycle bait type |
| Escape | Quit |

## Notes

- Tension must be kept inside `[tensionMin, tensionMax]`; if it breaks the bounds before `reelProgress` reaches 100, the fish escapes
- Fish swim in a pool of up to 20 entities; they wander with random velocity kicks and are attracted toward the lure when bait matches
- Day length is 120 seconds; unsold catches are tallied and cleared at midnight
- Wave animation on the water surface uses a `waveOffset` driven by `lurek.time.getTime()`
