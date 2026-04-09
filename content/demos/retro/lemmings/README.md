# Lemmings

A puzzle platformer inspired by DMA Design's 1991 Amiga classic. Guide a horde of
mindless lemmings to the exit by assigning them specialised jobs before they walk
into danger.

## What It Demonstrates

- `lurek.gfx.rectangle()` / `lurek.gfx.circle()` — terrain tiles, lemming sprites
- Complex per-frame agent logic for multiple independently-moving entities
- Destructible terrain via a 2D boolean grid
- Job-system state machine per agent (walk, block, dig, build, bash)

## Controls

| Key | Action |
|-----|--------|
| 1 | Select Blocker |
| 2 | Select Digger |
| 3 | Select Builder |
| 4 | Select Basher |
| A | Assign selected job to the next available lemming |
| R | Restart level |
| Escape | Quit |

## Jobs

| Job | Description |
|-----|-------------|
| Blocker | Stands still, turns other lemmings around |
| Digger | Removes tiles below — digs straight down |
| Builder | Lays tiles in a staircase — steps up over gaps |
| Basher | Removes tiles in front — bashes through walls |

## Notes

Save at least **8 out of 12** lemmings to win. Lemmings die if they fall more than
300 pixels. Use the right jobs in the right order to route the horde to the door.
