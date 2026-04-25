# HTML Scoreboard Demo

A live leaderboard that automatically refreshes every two seconds, built with
an HTML `<table>` element, showing how to rebuild DOM content from Lua data.

## What it demonstrates

- Using `<table>` / `<thead>` / `<tbody>` / `<tr>` / `<td>` markup.
- Full document rebuild via `setHtml` + `relayout` on data change.
- CSS medal classes (`.gold`, `.silver`, `.bronze`) applied dynamically.
- Simulated live data: random player scores arriving on a timer.

## Controls

| Input    | Action       |
|----------|--------------|
| `Escape` | Quit         |

Scores refresh automatically every 2 seconds.
