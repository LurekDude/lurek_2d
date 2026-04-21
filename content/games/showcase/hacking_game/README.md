# Hacking Game

Terminal-based hacking game with full CRT aesthetics. Type commands at the prompt to scan networks, connect to servers, crack passwords, and download classified data before the trace timer runs out.

## Run

```
cargo run -- content/games/showcase/hacking_game
```

## Controls

| Input     | Action                       |
| --------- | ---------------------------- |
| Type      | Enter commands at the prompt |
| Enter     | Execute command              |
| Backspace | Delete last character        |
| Escape    | Quit                         |

## Commands

| Command            | Description                                    |
| ------------------ | ---------------------------------------------- |
| `help`             | List available commands                        |
| `scan`             | Discover connected servers with IP addresses   |
| `connect <ip>`     | Connect to a server (starts trace timer)       |
| `ls`               | List files on connected server                 |
| `cat <file>`       | Read a file (may contain passwords or clues)   |
| `crack <password>` | Attempt to crack a server's password           |
| `download <file>`  | Download classified data for points            |
| `disconnect`       | Return to home, stop trace                     |
| `proxy <ip>`       | Route through proxy (extends trace timer +10s) |
| `mission`          | Show current mission objective                 |
| `score`            | Show current score and download count          |

## Gameplay

A 60-second trace timer starts when you connect to a server. If traced, the game ends. Use proxy routing to extend the timer. Read files to find password hints, crack servers to gain access, and download classified data to earn points.

### Missions
1. **Download inbox.dat from MAILSRV** — password is in plaintext on the server
2. **Chain through PROXYNODE to reach SECVAULT** — hint file narrows the password
3. **Download ALL classified files from DARKSRV** — time pressure, 3 files needed

### Scoring
- Download classified files: 100–400 points each
- Crack a password: 50 points
- Mission completion bonus: 200–600 points
- Time bonus: 2 points per second remaining on trace timer

### Visual Effects
- Matrix-rain title screen
- Animated boot sequence
- CRT scanlines and flicker overlay
- Pulsing trace bar when time runs low
- Particle effects on file downloads and trace alerts

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particle`, `lurek.tween`, `lurek.timer`, `lurek.event`
