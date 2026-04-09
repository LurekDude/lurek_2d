# Visual Novel Engine

A branching narrative engine with a typewriter text effect, multiple character relationship variables, and multiple endings. Three character story paths (Luna, Sol, Nova) converge into different endings based on which `affection` variable is highest when the story concludes.

## What It Demonstrates

- Scene table format: each scene contains `speaker`, `text`, `bg` (background colour key), and an optional `choices` array
- Typewriter effect: `char_index` increments by `CHARS_PER_SEC * dt` each frame; full scene text is sliced to `sub(1, floor(char_index))`
- Choice presentation: when a scene has `choices`, input is redirected to `selected_choice` navigation instead of advance
- Affection variables: choosing dialogue options for a character increments `affection[char]`; the ending scene is selected by comparing all three values
- Auto-advance mode (`A`): sets a timer that fires Space automatically after each scene completes its typewriter animation
- Skip mode (`S`): all remaining characters in the current scene are revealed instantly

## How to Run

```powershell
cargo run -- demos/visual_novel
```

## Controls

| Key | Action |
|-----|--------|
| `Space` / `Enter` | Advance scene / skip typewriter |
| Arrow Up / Down | Navigate choices |
| `A` | Toggle auto-advance mode |
| `S` | Skip typewriter for current line |
| `Escape` | Quit |

## Notes

- Each of the three character paths has dedicated scenes; visit all three before the final choice for the best ending.
- Affection values persist across save/load within the session — there is no reset between runs.
- Background colour changes visually signal location transitions (indoor, outdoor, night).
