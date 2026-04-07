# Wildlife Photography

An open-world nature reserve where the player explores a 1600 × 1200 biome map and photographs seven wildlife species. Get close to an animal without startling it, then click to snap a photo. Each species has a skittishness rating that determines how far it will flee when disturbed; fill your field encyclopedia with one photo of every species to complete the run.

## What It Demonstrates

- Large scrolling world larger than the viewport: camera follows the player across a 1600 × 1200 world with coordinate offset applied to all draw calls
- Procedural biome grid: each tile is randomly assigned as forest, meadow, or pond using a probability table
- Animal AI with three behavioural states: `"graze"` (wander slowly), `"flee"` (sprint away from the player), `"sleep"` (stationary, easiest to photograph)
- Skittishness radius: each species has a `skittish` threshold; entering that radius while upright triggers the flee state
- Photography scoring: proximity to the animal at shutter-click time determines star rating (1–3 stars)
- Day timer and visibility: `visibility` reduces at night, making animal detection harder and sleep state more common
- Discovery system: an animal species is added to the `encyclopedia` on its first successful photo

## How to Run

```powershell
cargo run -- demos/wildlife_photo
```

## Controls

| Key / Input | Action |
|-------------|--------|
| `W` `A` `S` `D` | Move |
| Left Click | Take photo (must be near an animal) |
| `Tab` | Open / close encyclopedia |
| `Escape` | Quit |

## Notes

- Move slowly toward sleeping animals for maximum proximity and a 3-star shot.
- Owls and Eagles are rare (rarity 3–4) — they may not appear near the starting area.
- The day/night cycle repeats every 90 seconds; nocturnal animals are more active at night.
