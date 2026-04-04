# Getting Started with Luna2D

## 1. Install the Engine

### Option A — Pre-built binary (Windows, easiest)

1. Download **luna2d-windows-x86_64.zip** from the [Releases](../../releases) page.
2. Extract to a folder you control, e.g. `C:\luna2d\`.
3. Add `C:\luna2d` to your **PATH**:  
   *System → Advanced System Settings → Environment Variables → Path → New*
4. Open a new terminal and verify:
   ```powershell
   luna2d
   ```
   You should see the Luna2D splash screen.

### Option B — Build from source (all platforms)

**Requirements**: [Rust stable toolchain](https://rustup.rs/) ≥ 1.78

```bash
git clone https://github.com/yourname/luna2d.git
cd luna2d
cargo build --release
# Binary: target/release/luna2d  (or luna2d.exe on Windows)
```

Installed builds use Luna2D's current `winit` + `wgpu` runtime. The older `tiny-skia` + `minifb` path remains in the repository as legacy fallback code.

**Install to PATH (recommended):**

```powershell
# Windows — installs to %USERPROFILE%\bin
powershell -ExecutionPolicy Bypass -File tools/install.ps1
```

```bash
# Linux / macOS — installs to /usr/local/bin (may need sudo)
bash tools/install.sh
```

---

## 2. Verify the Installation

```bash
# Launch the engine (no game) — shows the splash screen
luna2d

# Run a bundled example
luna2d examples/hello_world
luna2d examples/physics_demo
luna2d examples/sprites
```

In VS Code you can also use **Tasks: Run Task** → **Run (Installed): Hello World**.

---

## 3. Create Your First Game

### Project layout
```
my_game/
  main.lua          ← required entry point
  assets/           ← images, audio, etc. (optional, game-local)
```

### `main.lua` skeleton
```lua
-- Called once when the game loads
function luna.load()
    luna.window.setTitle("My First Game")
    luna.graphics.setBackgroundColor(0.1, 0.1, 0.2)
end

-- Called every frame — delta time in seconds
function luna.update(dt)
    -- game logic here
end

-- Called every frame for rendering
function luna.draw()
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print("Hello, Luna2D!", 300, 280, 3)

    luna.graphics.setColor(0.2, 0.8, 0.4)
    luna.graphics.rectangle("fill", 100, 100, 200, 150)

    luna.graphics.setColor(0.8, 0.3, 0.3)
    luna.graphics.circle("fill", 500, 300, 60)
end
```

### Run it
```bash
luna2d my_game
```

---

## 4. Loading Games into Luna2D

Luna2D is a **game runner**: you point it at a folder containing `main.lua` and it runs it.

```bash
luna2d path/to/game_folder        # run any game
luna2d .                          # run game in current directory
luna2d                            # no game → shows splash screen
```

The engine does **not** fuse the game into the binary; game Lua files stay separate.  
This makes development fast — edit a Lua file, re-run, see the change immediately.

---

## 5. Building the Engine (developer workflow)

| Command | Purpose |
|---|---|
| `cargo build` | Debug build (fast compile) |
| `cargo build --release` | Optimised release build (LTO enabled) |
| `cargo run -- examples/hello_world` | Run example with debug engine |
| `cargo run --release -- examples/hello_world` | Run example with release engine |
| `cargo test` | Run all tests |
| `cargo clippy` | Lint (0 warnings required) |
| `cargo fmt` | Auto-format Rust source |

---

## 6. Distributing Your Game

### Portable folder (all platforms)

Collect these files together for end users:

```
my_game-release/
  luna2d.exe          ← copy from your Luna2D installation
  assets/             ← copy luna2d's engine assets/ folder
    splash.png
    icon.png
  my_game/            ← your game folder
    main.lua
    assets/           ← your game's own assets
  README.txt
```

Users run: `luna2d.exe my_game`

### Windows ZIP package (from source)

```powershell
# Builds release binary, assembles dist/ folder, creates .zip
powershell -ExecutionPolicy Bypass -File tools/dist.ps1
# Output: dist/luna2d-windows-x86_64.zip
```

### Linux / macOS .tar.gz

```bash
bash tools/dist.sh
# Output: dist/luna2d-linux-x86_64.tar.gz
```

### Windows installer (NSIS)

Install [NSIS 3.x](https://nsis.sourceforge.io/Download), then:

```bash
makensis tools/installer.nsi
# Output: dist/luna2d-0.2.0-setup.exe
```

---

## Input Handling

### Polling (inside `luna.update`)
```lua
function luna.update(dt)
    if luna.keyboard.isDown("w") or luna.keyboard.isDown("up") then
        y = y - speed * dt
    end

    local mx, my = luna.mouse.getPosition()
    if luna.mouse.isDown(1) then  -- 1=left, 2=right, 3=middle
        -- mouse is held
    end
end
```

### Event callbacks
```lua
function luna.keypressed(key)
    if key == "escape" then luna.window.setTitle("Paused") end
end

function luna.keyreleased(key)   end
function luna.mousepressed(x, y, button)  end
function luna.mousereleased(x, y, button) end
```

---

## Drawing

All drawing calls must be inside `luna.draw()`:

```lua
function luna.draw()
    luna.graphics.setColor(1, 0.5, 0, 1)          -- RGBA, 0–1
    luna.graphics.rectangle("fill", x, y, w, h)   -- "fill" or "line"
    luna.graphics.circle("line", cx, cy, radius)
    luna.graphics.line(x1, y1, x2, y2)
    luna.graphics.print("Score: " .. score, 10, 10, 2)
end
```

---

## Images

```lua
local img

function luna.load()
    img = luna.graphics.newImage("player.png")  -- relative to game dir
end

function luna.draw()
    luna.graphics.draw(img, x, y)
end
```

---

## Audio

```lua
local music, sfx

function luna.load()
    music = luna.audio.newSource("bg_music.ogg")
    sfx   = luna.audio.newSource("jump.wav")
    luna.audio.play(music)
    luna.audio.setVolume(music, 0.5)
end

function luna.keypressed(key)
    if key == "space" then luna.audio.play(sfx) end
end
```

---

## Physics

```lua
local world, ball, ground

function luna.load()
    world  = luna.physics.newWorld(0, 200)              -- gravity: x=0, y=200
    ball   = luna.physics.newBody(world, 400, 100, "dynamic")
    ground = luna.physics.newBody(world, 400, 500, "static")
    luna.physics.setBodySize(world, ground, 800, 50)
end

function luna.update(dt)
    luna.physics.step(world, dt)
end

function luna.draw()
    local bx, by = luna.physics.getBody(world, ball)
    luna.graphics.circle("fill", bx, by, 20)

    local gx, gy = luna.physics.getBody(world, ground)
    luna.graphics.rectangle("fill", gx - 400, gy - 25, 800, 50)
end
```

---

## Filesystem

```lua
local data = luna.filesystem.read("level.txt")      -- relative to game dir
luna.filesystem.write("save/progress.txt", "level=3")
if luna.filesystem.exists("config.txt") then ... end
```

---

## Math & Timer

```lua
local angle = luna.math.atan2(dy, dx)
local dist  = luna.math.distance(x1, y1, x2, y2)
local val   = luna.math.clamp(x, 0, 100)
local r     = luna.math.random(1, 10)
local PI    = luna.math.pi

function luna.update(dt)
    local fps   = luna.timer.getFPS()
    local total = luna.timer.getTime()
end
```

---

## Next Steps

- Browse the full API: [`docs/lua_api_reference.md`](lua_api_reference.md)
- Study the bundled examples in [`examples/`](../examples/)
- Read the architecture overview: [`docs/architecture.md`](architecture.md)
