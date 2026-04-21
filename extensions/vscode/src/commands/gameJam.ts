import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";

// ─── Template definitions ─────────────────────────────────

interface GameTemplate {
  label: string;
  description: string;
  confLua: string;
  mainLua: string;
}

const TEMPLATES: GameTemplate[] = [
  {
    label: "Platformer",
    description: "Side-scrolling platformer with jump physics",
    confLua: `function lurek.conf(t)
  t.window.title = "My Platformer"
  t.window.width = 800
  t.window.height = 600
end
`,
    mainLua: `-- Platformer Starter
local player = { x = 100, y = 400, w = 32, h = 48, vy = 0, speed = 200, jumping = false }
local gravity = 980
local jumpForce = -450
local ground = 500

function lurek.load()
  lurek.window.setTitle("My Platformer")
end

function lurek.update(dt)
  -- Horizontal movement
  if lurek.input.keyboard.isDown("left") or lurek.input.keyboard.isDown("a") then
    player.x = player.x - player.speed * dt
  end
  if lurek.input.keyboard.isDown("right") or lurek.input.keyboard.isDown("d") then
    player.x = player.x + player.speed * dt
  end

  -- Gravity
  player.vy = player.vy + gravity * dt
  player.y = player.y + player.vy * dt

  -- Ground collision
  if player.y + player.h >= ground then
    player.y = ground - player.h
    player.vy = 0
    player.jumping = false
  end
end

function lurek.keypressed(key)
  if key == "space" and not player.jumping then
    player.vy = jumpForce
    player.jumping = true
  end
  if key == "escape" then
    lurek.event.quit()
  end
end

function lurek.draw()
  -- Sky
  lurek.graphics.setBackgroundColor(0.4, 0.7, 1.0)

  -- Ground
  lurek.graphics.setColor(0.3, 0.6, 0.2)
  lurek.graphics.rectangle("fill", 0, ground, 800, 100)

  -- Player
  lurek.graphics.setColor(0.2, 0.4, 0.9)
  lurek.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

  -- HUD
  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print("Arrow keys / WASD to move, Space to jump", 10, 10)
end
`,
  },
  {
    label: "Top-Down RPG",
    description: "Tile-based RPG with 4-directional movement",
    confLua: `function lurek.conf(t)
  t.window.title = "My RPG"
  t.window.width = 640
  t.window.height = 480
end
`,
    mainLua: `-- Top-Down RPG Starter
local player = { x = 320, y = 240, w = 32, h = 32, speed = 150, dir = "down" }
local map_w, map_h = 20, 15
local tile_size = 32

function lurek.load()
  lurek.window.setTitle("My RPG")
end

function lurek.update(dt)
  local dx, dy = 0, 0

  if lurek.input.keyboard.isDown("up") or lurek.input.keyboard.isDown("w") then
    dy = -1
    player.dir = "up"
  elseif lurek.input.keyboard.isDown("down") or lurek.input.keyboard.isDown("s") then
    dy = 1
    player.dir = "down"
  end

  if lurek.input.keyboard.isDown("left") or lurek.input.keyboard.isDown("a") then
    dx = -1
    player.dir = "left"
  elseif lurek.input.keyboard.isDown("right") or lurek.input.keyboard.isDown("d") then
    dx = 1
    player.dir = "right"
  end

  -- Normalize diagonal movement
  if dx ~= 0 and dy ~= 0 then
    local len = math.sqrt(dx * dx + dy * dy)
    dx = dx / len
    dy = dy / len
  end

  player.x = player.x + dx * player.speed * dt
  player.y = player.y + dy * player.speed * dt

  -- Clamp to map bounds
  player.x = math.max(0, math.min(player.x, map_w * tile_size - player.w))
  player.y = math.max(0, math.min(player.y, map_h * tile_size - player.h))
end

function lurek.keypressed(key)
  if key == "escape" then
    lurek.event.quit()
  end
end

function lurek.draw()
  lurek.graphics.setBackgroundColor(0.15, 0.15, 0.2)

  -- Draw grid
  lurek.graphics.setColor(0.25, 0.25, 0.3)
  for x = 0, map_w - 1 do
    for y = 0, map_h - 1 do
      lurek.graphics.rectangle("line", x * tile_size, y * tile_size, tile_size, tile_size)
    end
  end

  -- Player
  lurek.graphics.setColor(0.2, 0.8, 0.3)
  lurek.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

  -- Direction indicator
  lurek.graphics.setColor(1, 1, 1)
  local cx, cy = player.x + player.w / 2, player.y + player.h / 2
  local indicators = { up = {0, -8}, down = {0, 8}, left = {-8, 0}, right = {8, 0} }
  local ind = indicators[player.dir]
  lurek.graphics.circle("fill", cx + ind[1], cy + ind[2], 4)

  -- HUD
  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print("WASD / Arrow keys to move", 10, 10)
end
`,
  },
  {
    label: "Shooter",
    description: "Top-down shooter with projectiles",
    confLua: `function lurek.conf(t)
  t.window.title = "My Shooter"
  t.window.width = 800
  t.window.height = 600
end
`,
    mainLua: `-- Shooter Starter
local player = { x = 400, y = 500, w = 24, h = 24, speed = 250 }
local bullets = {}
local enemies = {}
local score = 0
local shoot_timer = 0
local shoot_cooldown = 0.2
local spawn_timer = 0
local spawn_rate = 1.5

function lurek.load()
  lurek.window.setTitle("My Shooter")
end

function lurek.update(dt)
  -- Player movement
  if lurek.input.keyboard.isDown("left") or lurek.input.keyboard.isDown("a") then
    player.x = player.x - player.speed * dt
  end
  if lurek.input.keyboard.isDown("right") or lurek.input.keyboard.isDown("d") then
    player.x = player.x + player.speed * dt
  end
  player.x = math.max(0, math.min(player.x, 800 - player.w))

  -- Shooting
  shoot_timer = shoot_timer - dt
  if lurek.input.keyboard.isDown("space") and shoot_timer <= 0 then
    table.insert(bullets, { x = player.x + player.w / 2 - 2, y = player.y - 8, w = 4, h = 8 })
    shoot_timer = shoot_cooldown
  end

  -- Update bullets
  for i = #bullets, 1, -1 do
    bullets[i].y = bullets[i].y - 400 * dt
    if bullets[i].y < -10 then
      table.remove(bullets, i)
    end
  end

  -- Spawn enemies
  spawn_timer = spawn_timer - dt
  if spawn_timer <= 0 then
    table.insert(enemies, {
      x = math.random(0, 800 - 24),
      y = -30,
      w = 24, h = 24,
      speed = 80 + math.random(0, 80)
    })
    spawn_timer = spawn_rate
  end

  -- Update enemies
  for i = #enemies, 1, -1 do
    enemies[i].y = enemies[i].y + enemies[i].speed * dt
    if enemies[i].y > 620 then
      table.remove(enemies, i)
    end
  end

  -- Collision: bullet vs enemy
  for bi = #bullets, 1, -1 do
    for ei = #enemies, 1, -1 do
      local b, e = bullets[bi], enemies[ei]
      if b and e and b.x < e.x + e.w and b.x + b.w > e.x and b.y < e.y + e.h and b.y + b.h > e.y then
        table.remove(bullets, bi)
        table.remove(enemies, ei)
        score = score + 10
        break
      end
    end
  end
end

function lurek.keypressed(key)
  if key == "escape" then
    lurek.event.quit()
  end
end

function lurek.draw()
  lurek.graphics.setBackgroundColor(0.05, 0.05, 0.1)

  -- Player
  lurek.graphics.setColor(0.2, 0.7, 1.0)
  lurek.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

  -- Bullets
  lurek.graphics.setColor(1, 1, 0.3)
  for _, b in ipairs(bullets) do
    lurek.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
  end

  -- Enemies
  lurek.graphics.setColor(1, 0.3, 0.3)
  for _, e in ipairs(enemies) do
    lurek.graphics.rectangle("fill", e.x, e.y, e.w, e.h)
  end

  -- HUD
  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print("Score: " .. score, 10, 10)
  lurek.graphics.print("WASD to move, Space to shoot", 10, 30)
end
`,
  },
  {
    label: "Puzzle",
    description: "Grid-based puzzle with tile swapping",
    confLua: `function lurek.conf(t)
  t.window.title = "My Puzzle"
  t.window.width = 480
  t.window.height = 520
end
`,
    mainLua: `-- Puzzle Starter
local grid_size = 4
local tile_size = 100
local padding = 40
local grid = {}
local selected = nil
local moves = 0

local colors = {
  {0.9, 0.3, 0.3}, {0.3, 0.9, 0.3}, {0.3, 0.3, 0.9}, {0.9, 0.9, 0.3},
  {0.9, 0.3, 0.9}, {0.3, 0.9, 0.9}, {0.9, 0.6, 0.2}, {0.6, 0.2, 0.9},
}

function lurek.load()
  lurek.window.setTitle("My Puzzle")
  -- Fill grid with paired colors
  local tiles = {}
  for i = 1, (grid_size * grid_size) / 2 do
    local c = colors[(i - 1) % #colors + 1]
    table.insert(tiles, c)
    table.insert(tiles, c)
  end
  -- Shuffle
  for i = #tiles, 2, -1 do
    local j = math.random(1, i)
    tiles[i], tiles[j] = tiles[j], tiles[i]
  end
  -- Place on grid
  local idx = 1
  for y = 1, grid_size do
    grid[y] = {}
    for x = 1, grid_size do
      grid[y][x] = { color = tiles[idx], revealed = false, matched = false }
      idx = idx + 1
    end
  end
end

function lurek.mousepressed(mx, my, button)
  if button ~= 1 then return end

  local gx = math.floor((mx - padding) / tile_size) + 1
  local gy = math.floor((my - padding) / tile_size) + 1
  if gx < 1 or gx > grid_size or gy < 1 or gy > grid_size then return end

  local tile = grid[gy][gx]
  if tile.matched or tile.revealed then return end

  tile.revealed = true

  if selected == nil then
    selected = { x = gx, y = gy }
  else
    moves = moves + 1
    local prev = grid[selected.y][selected.x]
    if prev.color[1] == tile.color[1] and prev.color[2] == tile.color[2] and prev.color[3] == tile.color[3] then
      prev.matched = true
      tile.matched = true
    else
      -- Hide both after a short pause (simplified: immediate)
      prev.revealed = false
      tile.revealed = false
    end
    selected = nil
  end
end

function lurek.keypressed(key)
  if key == "r" then lurek.load() end
  if key == "escape" then lurek.event.quit() end
end

function lurek.draw()
  lurek.graphics.setBackgroundColor(0.12, 0.12, 0.15)

  for y = 1, grid_size do
    for x = 1, grid_size do
      local tile = grid[y][x]
      local px = padding + (x - 1) * tile_size + 4
      local py = padding + (y - 1) * tile_size + 4
      local tw = tile_size - 8
      local th = tile_size - 8

      if tile.revealed or tile.matched then
        lurek.graphics.setColor(tile.color[1], tile.color[2], tile.color[3])
      else
        lurek.graphics.setColor(0.3, 0.3, 0.35)
      end
      lurek.graphics.rectangle("fill", px, py, tw, th)

      -- Border
      lurek.graphics.setColor(0.5, 0.5, 0.55)
      lurek.graphics.rectangle("line", px, py, tw, th)
    end
  end

  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print("Moves: " .. moves .. "  |  R to restart", 10, 10)
end
`,
  },
  {
    label: "Visual Novel",
    description: "Dialog-driven narrative with choices",
    confLua: `function lurek.conf(t)
  t.window.title = "My Visual Novel"
  t.window.width = 800
  t.window.height = 600
end
`,
    mainLua: `-- Visual Novel Starter
local scenes = {
  intro = {
    text = "You find yourself at the entrance of a mysterious forest.",
    speaker = "Narrator",
    choices = {
      { text = "Enter the forest", next = "forest" },
      { text = "Turn back home", next = "home" },
    },
  },
  forest = {
    text = "The trees tower above you. A faint light glows deeper within.",
    speaker = "Narrator",
    choices = {
      { text = "Follow the light", next = "light" },
      { text = "Search the underbrush", next = "search" },
    },
  },
  home = {
    text = "You decide the adventure can wait. Maybe tomorrow...",
    speaker = "Narrator",
    choices = {
      { text = "Play again", next = "intro" },
    },
  },
  light = {
    text = "The light reveals a clearing with an ancient stone altar!",
    speaker = "Narrator",
    choices = {
      { text = "Touch the altar", next = "ending_good" },
      { text = "Leave quickly", next = "home" },
    },
  },
  search = {
    text = "You find a small chest hidden under the roots of an old oak.",
    speaker = "Narrator",
    choices = {
      { text = "Open the chest", next = "ending_treasure" },
      { text = "Leave it alone", next = "forest" },
    },
  },
  ending_good = {
    text = "The altar glows warmly. You feel a profound sense of peace...\n\n--- THE END ---",
    speaker = "Narrator",
    choices = { { text = "Play again", next = "intro" } },
  },
  ending_treasure = {
    text = "Inside the chest is a golden key! What could it unlock?\n\n--- THE END ---",
    speaker = "Narrator",
    choices = { { text = "Play again", next = "intro" } },
  },
}

local current_scene = "intro"
local hover_choice = 0

function lurek.load()
  lurek.window.setTitle("My Visual Novel")
end

function lurek.update(dt)
  local mx, my = lurek.input.mouse.getPosition()
  local scene = scenes[current_scene]
  hover_choice = 0

  for i, _ in ipairs(scene.choices) do
    local cy = 420 + (i - 1) * 50
    if mx >= 100 and mx <= 700 and my >= cy and my <= cy + 40 then
      hover_choice = i
    end
  end
end

function lurek.mousepressed(mx, my, button)
  if button ~= 1 then return end
  local scene = scenes[current_scene]
  if hover_choice >= 1 and hover_choice <= #scene.choices then
    current_scene = scene.choices[hover_choice].next
    hover_choice = 0
  end
end

function lurek.keypressed(key)
  if key == "escape" then lurek.event.quit() end
  local scene = scenes[current_scene]
  local num = tonumber(key)
  if num and num >= 1 and num <= #scene.choices then
    current_scene = scene.choices[num].next
  end
end

function lurek.draw()
  lurek.graphics.setBackgroundColor(0.1, 0.08, 0.15)

  local scene = scenes[current_scene]

  -- Dialog box background
  lurek.graphics.setColor(0.15, 0.12, 0.2, 0.95)
  lurek.graphics.rectangle("fill", 50, 280, 700, 100)
  lurek.graphics.setColor(0.6, 0.5, 0.8)
  lurek.graphics.rectangle("line", 50, 280, 700, 100)

  -- Speaker name
  lurek.graphics.setColor(0.8, 0.7, 1.0)
  lurek.graphics.print(scene.speaker, 70, 260)

  -- Dialog text
  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print(scene.text, 70, 300)

  -- Choices
  for i, choice in ipairs(scene.choices) do
    local cy = 420 + (i - 1) * 50
    if hover_choice == i then
      lurek.graphics.setColor(0.3, 0.25, 0.45)
    else
      lurek.graphics.setColor(0.2, 0.17, 0.3)
    end
    lurek.graphics.rectangle("fill", 100, cy, 600, 40)
    lurek.graphics.setColor(0.6, 0.5, 0.8)
    lurek.graphics.rectangle("line", 100, cy, 600, 40)
    lurek.graphics.setColor(1, 1, 1)
    lurek.graphics.print(i .. ". " .. choice.text, 120, cy + 10)
  end
end
`,
  },
];

// ─── Module patterns ──────────────────────────────────────

interface ModuleTemplate {
  label: string;
  description: string;
  patternFile: string;       // filename in data/patterns/
  requireLine: string;       // require() call to insert in main.lua
}

const MODULES: ModuleTemplate[] = [
  { label: "Camera",        description: "Smooth follow camera with zoom and shake",   patternFile: "camera.lua",           requireLine: 'local Camera = require("libs.camera")' },
  { label: "Tilemap",       description: "Tile-based map rendering and collision",      patternFile: "grid.lua",             requireLine: 'local Grid = require("libs.grid")' },
  { label: "Physics",       description: "Simple physics wrappers",                     patternFile: "component-system.lua", requireLine: 'local ECS = require("libs.component-system")' },
  { label: "UI",            description: "Basic UI components",                         patternFile: "stack.lua",            requireLine: 'local Stack = require("libs.stack")' },
  { label: "Particles",     description: "Particle effects system",                     patternFile: "timer.lua",            requireLine: 'local Timer = require("libs.timer")' },
  { label: "Save/Load",     description: "Game state serialization",                    patternFile: "class.lua",            requireLine: 'local Class = require("libs.class")' },
  { label: "Sound Manager", description: "Audio management with fade and crossfade",    patternFile: "event-bus.lua",        requireLine: 'local EventBus = require("libs.event-bus")' },
  { label: "State Machine", description: "Finite state machine for game states",        patternFile: "fsm.lua",              requireLine: 'local FSM = require("libs.fsm")' },
  { label: "Signal",        description: "Pub-sub signal / observer pattern",           patternFile: "signal.lua",           requireLine: 'local Signal = require("libs.signal")' },
  { label: "Tween",         description: "Property tweening / animation engine",        patternFile: "tween.lua",            requireLine: 'local Tween = require("libs.tween")' },
  { label: "Object Pool",   description: "Recycling pool for bullets/particles/etc.",   patternFile: "object-pool.lua",      requireLine: 'local Pool = require("libs.object-pool")' },
];

// ─── Game Jam Timer ───────────────────────────────────────

let jamTimerInterval: ReturnType<typeof setInterval> | undefined;
let jamTimerItem: vscode.StatusBarItem | undefined;
let jamEndTime: number | undefined;

function startJamTimer(minutes: number): void {
  stopJamTimer();

  jamEndTime = Date.now() + minutes * 60_000;
  jamTimerItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 200);
  jamTimerItem.show();

  const totalMs = minutes * 60_000;
  let notified50 = false;
  let notified25 = false;
  let notified10 = false;

  const update = (): void => {
    if (!jamEndTime || !jamTimerItem) {
      return;
    }
    const remaining = jamEndTime - Date.now();
    if (remaining <= 0) {
      jamTimerItem.text = "$(bell) TIME'S UP!";
      jamTimerItem.backgroundColor = new vscode.ThemeColor("statusBarItem.errorBackground");
      vscode.window.showWarningMessage("Game Jam Timer: Time's up!");
      stopJamTimer();
      return;
    }

    const pct = remaining / totalMs;
    const mins = Math.floor(remaining / 60_000);
    const secs = Math.floor((remaining % 60_000) / 1000);
    jamTimerItem.text = `$(clock) ${mins}:${String(secs).padStart(2, "0")} remaining`;

    if (pct <= 0.10 && !notified10) {
      notified10 = true;
      jamTimerItem.backgroundColor = new vscode.ThemeColor("statusBarItem.errorBackground");
      vscode.window.showWarningMessage("Game Jam Timer: 10% time remaining!");
    } else if (pct <= 0.25 && !notified25) {
      notified25 = true;
      jamTimerItem.backgroundColor = new vscode.ThemeColor("statusBarItem.warningBackground");
      vscode.window.showWarningMessage("Game Jam Timer: 25% time remaining!");
    } else if (pct <= 0.50 && !notified50) {
      notified50 = true;
      vscode.window.showInformationMessage("Game Jam Timer: 50% time remaining.");
    }
  };

  update();
  jamTimerInterval = setInterval(update, 1000);
}

function stopJamTimer(): void {
  if (jamTimerInterval) {
    clearInterval(jamTimerInterval);
    jamTimerInterval = undefined;
  }
  if (jamTimerItem) {
    jamTimerItem.dispose();
    jamTimerItem = undefined;
  }
  jamEndTime = undefined;
}

// ─── Commands ─────────────────────────────────────────────

export function registerGameJamCommands(context: vscode.ExtensionContext): void {
  // ── lurek.gameJam.quickStart ──────────────────────────────
  context.subscriptions.push(
    vscode.commands.registerCommand("lurek.gameJam.quickStart", async () => {
      // Pick template
      const picked = await vscode.window.showQuickPick(
        TEMPLATES.map((t) => ({ label: t.label, description: t.description, template: t })),
        { placeHolder: "Choose a game template" }
      );
      if (!picked) {
        return;
      }

      // Ask for project name
      const name = await vscode.window.showInputBox({
        prompt: "Project name",
        placeHolder: "my-game",
        validateInput: (v) => {
          if (!v.trim()) {
            return "Name cannot be empty";
          }
          if (/[<>:"/\\|?*]/.test(v)) {
            return "Name contains invalid characters";
          }
          return undefined;
        },
      });
      if (!name) {
        return;
      }

      // Choose parent folder
      const parentUri = await vscode.window.showOpenDialog({
        canSelectFolders: true,
        canSelectFiles: false,
        canSelectMany: false,
        openLabel: "Select parent folder",
      });
      if (!parentUri || parentUri.length === 0) {
        return;
      }

      const projectDir = path.join(parentUri[0].fsPath, name);
      if (fs.existsSync(projectDir)) {
        vscode.window.showErrorMessage(`Folder already exists: ${projectDir}`);
        return;
      }

      // Create project structure
      const template = picked.template;
      fs.mkdirSync(projectDir, { recursive: true });
      fs.mkdirSync(path.join(projectDir, "assets"), { recursive: true });
      fs.mkdirSync(path.join(projectDir, "libs"), { recursive: true });

      fs.writeFileSync(path.join(projectDir, "conf.lua"), template.confLua, "utf-8");
      fs.writeFileSync(path.join(projectDir, "main.lua"), template.mainLua, "utf-8");
      fs.writeFileSync(
        path.join(projectDir, "assets", "README.md"),
        "# Assets\n\nPlace your game assets (images, sounds, fonts) in this folder.\n",
        "utf-8"
      );

      // Open the folder
      const uri = vscode.Uri.file(projectDir);
      await vscode.commands.executeCommand("vscode.openFolder", uri);
      vscode.window.showInformationMessage(`Created "${name}" with ${template.label} template!`);
    })
  );

  // ── lurek.gameJam.addModule ───────────────────────────────
  context.subscriptions.push(
    vscode.commands.registerCommand("lurek.gameJam.addModule", async () => {
      const picked = await vscode.window.showQuickPick(
        MODULES.map((m) => ({ label: m.label, description: m.description, module: m })),
        { placeHolder: "Choose a module to add" }
      );
      if (!picked) {
        return;
      }

      const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
      if (!workspaceRoot) {
        vscode.window.showErrorMessage("No workspace folder open.");
        return;
      }

      const mod = picked.module;

      // Copy pattern file to libs/
      const libsDir = path.join(workspaceRoot, "libs");
      if (!fs.existsSync(libsDir)) {
        fs.mkdirSync(libsDir, { recursive: true });
      }

      const destFile = path.join(libsDir, mod.patternFile);
      if (fs.existsSync(destFile)) {
        const overwrite = await vscode.window.showWarningMessage(
          `libs/${mod.patternFile} already exists. Overwrite?`,
          "Yes",
          "No"
        );
        if (overwrite !== "Yes") {
          return;
        }
      }

      // Read pattern from extension's data/patterns/
      const patternPath = path.join(context.extensionPath, "data", "patterns", mod.patternFile);
      if (!fs.existsSync(patternPath)) {
        vscode.window.showErrorMessage(`Pattern file not found: ${mod.patternFile}`);
        return;
      }

      fs.copyFileSync(patternPath, destFile);

      // Try to add require() to main.lua
      const mainLuaPath = path.join(workspaceRoot, "main.lua");
      if (fs.existsSync(mainLuaPath)) {
        const content = fs.readFileSync(mainLuaPath, "utf-8");
        if (!content.includes(mod.requireLine)) {
          // Insert require at the top, after any existing requires
          const lines = content.split("\n");
          let insertIdx = 0;
          for (let i = 0; i < lines.length; i++) {
            if (lines[i].startsWith("local ") && lines[i].includes("require")) {
              insertIdx = i + 1;
            }
          }
          lines.splice(insertIdx, 0, mod.requireLine);
          fs.writeFileSync(mainLuaPath, lines.join("\n"), "utf-8");
        }
      }

      vscode.window.showInformationMessage(`Added ${mod.label} module to libs/${mod.patternFile}`);
    })
  );

  // ── lurek.gameJam.timer ───────────────────────────────────
  context.subscriptions.push(
    vscode.commands.registerCommand("lurek.gameJam.timer", async () => {
      const picked = await vscode.window.showQuickPick(
        [
          { label: "30 minutes", minutes: 30 },
          { label: "1 hour", minutes: 60 },
          { label: "2 hours", minutes: 120 },
          { label: "Custom...", minutes: -1 },
          { label: "Stop timer", minutes: 0 },
        ],
        { placeHolder: "Game Jam countdown duration" }
      );
      if (!picked) {
        return;
      }

      if (picked.minutes === 0) {
        stopJamTimer();
        vscode.window.showInformationMessage("Game Jam Timer stopped.");
        return;
      }

      let minutes = picked.minutes;
      if (minutes < 0) {
        const custom = await vscode.window.showInputBox({
          prompt: "Duration in minutes",
          placeHolder: "90",
          validateInput: (v) => {
            const n = Number(v);
            if (isNaN(n) || n <= 0) {
              return "Enter a positive number";
            }
            return undefined;
          },
        });
        if (!custom) {
          return;
        }
        minutes = Number(custom);
      }

      startJamTimer(minutes);
      vscode.window.showInformationMessage(`Game Jam Timer started: ${minutes} minutes.`);
    })
  );

  // Clean up timer on deactivation
  context.subscriptions.push({ dispose: stopJamTimer });
}
