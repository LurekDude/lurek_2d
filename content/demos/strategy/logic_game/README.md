# Logic Game

A programming-puzzle game where you assemble a command sequence to guide a robot through a grid maze to reach the flag. Commands are placed into a program slot-by-slot from a palette (Forward, Left, Right, Loop), then executed step-by-step with visual animation. Three handcrafted levels of increasing complexity teach sequencing, rotation, and looping.

## What It Demonstrates

- `luna.gfx.rectangle()` — drawing the grid, command slots, and UI panels
- `luna.gfx.print()` — labelling commands, level names, and status messages
- `luna.mouse.getPosition()` / `luna.mousepressed()` — palette selection and program slot clicking
- `luna.keyboard.isDown()` — run, reset, and quit key handling
- `luna.time.getTime()` — step execution timing and animation lerp
- `luna.gfx.setColor()` — colour-coded command blocks and robot direction indicator

## How to Run

```powershell
cargo run -- demos/logic_game
```

## Controls

| Input | Action |
|-------|--------|
| Click palette | Select command to place |
| Click slot | Place / clear a command |
| Enter | Execute program |
| R | Reset level |
| N | Next level (after win) |
| Escape | Quit |

## Notes

- Robot direction uses a 4-element array (`DIR`) indexed by a 1-based integer, making rotation a simple increment/decrement with wrap.
- The `LOOP` command is implemented as a simple repeat-3 construct tracked with `loop_start` and `loop_count`.
- Grid walls are stored as a 2D array; `can_move()` checks both bounds and wall cell values before each `FWD` step.
- Execution is timer-driven (`EXEC_SPEED = 0.35 s`), allowing smooth step-by-step animation of the robot's journey.
