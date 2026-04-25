# Lurek2D Game Projects

Playable game projects organised by genre. Each subfolder contains
a conf.lua + main.lua game entry point and a README.md.

## Directory Layout

- ction/       â€” Action and arcade games
- rcade/       â€” Classic arcade-style projects
-
etro/        â€” Retro-aesthetic titles
-
pg/          â€” Role-playing game demos
- showcase/     â€” Feature showcase projects
- simulation/   â€” Simulation / sandbox games
- sports/       â€” Sports and rhythm games
- strategy/     â€” Strategy and tower-defence games

## Running a Project

`
lurek2d content/games/<category>/<name>
`

## Showcase — HTML UI Demos

| Folder | Title | API highlights |
|--------|-------|----------------|
| `showcase/html-hud` | HTML HUD Demo | `newDocument`, `getElementById`, `setStyle`, input forwarding |
| `showcase/html-inventory` | HTML Inventory Demo | `queryAll`, `el:on("click")`, `addClass`/`removeClass` |
| `showcase/html-dialog` | HTML Dialog Demo | `setHtml`, `relayout`, `mousepressed` consumed-flag |
| `showcase/html-settings` | HTML Settings Demo | `hasClass`/`toggleClass`, `queryAll` radio-group, `keypressed`/`textinput` |
| `showcase/html-scoreboard` | HTML Scoreboard Demo | `<table>` markup, `setHtml`+`relayout`, `table.sort` |

