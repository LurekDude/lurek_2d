# Hacking Game

A terminal-based hacking game where you breach three networked servers, navigate their file systems, and download classified target files before a trace timer expires. Each server requires cracking its password through a click-the-word mini-game. Routing traffic through proxy chains slows the trace counter, giving more time to explore.

## What It Demonstrates

- `luna.keyboard.wasPressed()` — character-by-character terminal input capture
- `luna.graphics.print()` — scrolling terminal output and blinking cursor rendering
- `luna.graphics.rectangle()` — password-crack word grid and trace-bar HUD
- `luna.graphics.setColor()` — colour-coded output lines (green success, red alert, white normal)
- `luna.mousepressed()` — clicking words in the crack mini-game to match the target password
- `luna.timer.getTime()` — cursor blink animation
- In-memory virtual filesystem — `make_fs()` builds a directory-tree table parsed by `ls`, `cd`, and `cat`
- State machine — `gameState` transitions between `playing`, `cracking`, `won`, and `gameover`

## How to Run

```powershell
cargo run -- demos/hacking_game
```

## Controls

| Input | Action |
|-------|--------|
| Type text | Enter terminal commands |
| Enter | Execute command |
| Backspace | Delete last character |
| Left Click | Select a word during crack mini-game |
| Escape | Quit |

## Notes

- Available commands: `ls`, `cd <dir>`, `cat <file>`, `ssh <ip>`, `crack`, `decrypt`, `proxy`, `download`, `help`
- Trace starts at 120 s; each `proxy` command adds 15 s; if it reaches zero the mission fails
- The crack game renders 40 candidate words on a grid; exactly one matches the target password
- Downloading `target.dat` from all three servers wins the game; score is proportional to remaining trace time
