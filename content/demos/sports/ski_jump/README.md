# Ski Jump

A three-phase ski jumping simulation with three attempts. Time your crouch, lean in
the air, and nail the landing for maximum distance.

## What It Demonstrates

- `lurek.input.isKeyDown()` — crouching during the slide
- `lurek.keypressed()` — lean direction mid-air
- Physics simulation — parabolic trajectory, slope intersection detection
- Geometric drawing — ramp profile, landing slope, distance markers
- Multi-attempt scoring loop

## Controls

| Phase | Key | Action |
|-------|-----|--------|
| Slide | Hold Space | Crouch low (boosts launch power) |
| Airborne | A / Left | Lean backward |
| Airborne | D / Right | Lean forward |
| Score screen | Space | Take next jump |
| Any | R | Restart |
| Any | Escape | Quit |

## Scoring

Distance in metres. Crouch the whole way down the ramp and lean forward in air
for maximum distance. Three jumps — best score counts.
