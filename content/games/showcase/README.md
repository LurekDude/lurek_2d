# Showcase Games

Showcase games demonstrate specific Lurek2D feature systems in isolation,
keeping each demo focused on one API area while still being playable.

## Demos

| Demo | Description | Key APIs |
|------|-------------|----------|
| [`demo_game`](demo_game/) | Physics shooting gallery — aim with mouse, fire at moving targets, combo scoring | `lurek.physics`, `lurek.particle`, `lurek.render` |
| [`globe_demo`](globe_demo/) | Interactive world globe — 200 procedural provinces, drag-pan, zoom, day/night, hover highlight, political overlay | `lurek.globe.*` |
| [`html-load-document`](html-load-document/) | File-backed HTML UI demo — loads `ui/hud.html` + `ui/hud.css` with `lurek.html.loadDocument` | `lurek.html.*`, `lurek.render` |
| [`terminal_demo`](terminal_demo/) | In-game terminal emulator — custom command parsing, scrollback buffer | `lurek.terminal` |
| [`sprites`](sprites/) | Procedural pixel-art sprites — animation, tinting, trail effects, collectibles | `lurek.image`, `lurek.render` |

## Running any demo

```bash
cargo run -- content/games/showcase/<name>
```

For example:

```bash
cargo run -- content/games/showcase/globe_demo
```
