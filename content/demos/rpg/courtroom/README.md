# Courtroom

A courtroom drama simulation inspired by Ace Attorney. Work through three cases — missing diamond, poisoned cake, and forged painting — by listening to witness testimony, presenting evidence at the right moment, and pressing witnesses for contradictions to fill the jury bar and secure a guilty verdict.

## What It Demonstrates

- `lurek.gfx.rectangle()` — witness stand, evidence panel, jury progress bar
- `lurek.gfx.print()` — animated typewriter-style testimony text rendering
- `lurek.gfx.setColor()` — flash banners for successful objections and contradiction reveals
- `lurek.keyboard.isPressed()` — state-machine navigation across title, intro, testimony, and verdict screens
- `lurek.signal.quit()` — clean exit triggered from the title screen
- `lurek.gfx.setBackgroundColor()` — courtroom backdrop theming per state

## How to Run

```powershell
cargo run -- content/demos/courtroom
```

## Controls

| Input | Action |
|-------|--------|
| Enter | Advance (title → intro → testimony) |
| E | Toggle evidence panel |
| P | Press witness for a deeper statement |
| Up / Down | Navigate evidence or question list |
| Enter (on evidence) | Present evidence to contradict testimony |
| Q | Ask selected question |
| Escape | Quit (from title screen) |

## Notes

- Each testimony line has a hidden `contradiction` index and an optional `press_reveal` string; only presenting the matching evidence or pressing at the right moment awards jury points.
- Three full cases are included, each with unique evidence and testimony chains.
- The jury bar must reach 100 for a guilty verdict; ending the testimony below that results in acquittal.
- Text renders character-by-character at 40 characters per second for dramatic effect.
