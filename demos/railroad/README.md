# Railroad / Transport Logistics

A transport logistics game on a 25 × 19 tile grid. Place track tiles to connect stations, spawn trains, and earn revenue when a train delivers cargo from a producing station to a consuming one. The train pathfinding uses the directional connection graph defined by each track type.

## What It Demonstrates

- Track connection graph: each of the six track types defines which cardinal directions it connects (`TRACK_DIRS`), and trains follow the graph by choosing the exit direction that is not the entry direction
- Six distinct track tile types (horizontal, vertical, and four corner curves) rendered procedurally
- Station-based cargo production and consumption with a stock/capacity system
- Day cycle timer driving revenue per delivery and a history array for the revenue chart
- Train spawning via `T` and automatic pathfinding along placed track
- `luna.graphics.drawLine` for the track shapes and `drawRect` for train cars

## How to Run

```powershell
cargo run -- demos/railroad
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Left Click on grid | Place selected track type |
| `1` – `6` | Select track type: Horizontal / Vertical / Curve NE / SE / SW / NW |
| `T` | Spawn a new train at the nearest station |
| `Escape` | Quit |

## Notes

- Trains stop when they reach a station and wait briefly before departing.
- A track tile on a station cell (`grid[row][col] == -1`) is overridden; stations always connect to adjacent track.
- The revenue chart in the top-right shows the last several days of income.
