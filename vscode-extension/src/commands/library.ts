import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";

// ─── Snippet definitions ──────────────────────────────────

interface SnippetEntry {
  label: string;
  category: string;
  code: string;
}

const SNIPPETS: SnippetEntry[] = [
  // Graphics
  {
    label: "Draw sprite",
    category: "Graphics",
    code: `local img = luna.graphics.newImage("assets/sprite.png")

function luna.draw()
  luna.graphics.draw(img, x, y)
end`,
  },
  {
    label: "Animation loop",
    category: "Graphics",
    code: `local frames = {}
local current_frame = 1
local frame_timer = 0
local frame_duration = 0.1

function luna.load()
  for i = 1, 4 do
    frames[i] = luna.graphics.newImage("assets/frame" .. i .. ".png")
  end
end

function luna.update(dt)
  frame_timer = frame_timer + dt
  if frame_timer >= frame_duration then
    frame_timer = frame_timer - frame_duration
    current_frame = current_frame % #frames + 1
  end
end

function luna.draw()
  luna.graphics.draw(frames[current_frame], x, y)
end`,
  },
  {
    label: "Particle burst",
    category: "Graphics",
    code: `local particles = {}

local function emit(px, py, count)
  for i = 1, count do
    local angle = math.random() * math.pi * 2
    local speed = 50 + math.random() * 100
    table.insert(particles, {
      x = px, y = py,
      vx = math.cos(angle) * speed,
      vy = math.sin(angle) * speed,
      life = 0.5 + math.random() * 0.5,
    })
  end
end

function luna.update(dt)
  for i = #particles, 1, -1 do
    local p = particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    if p.life <= 0 then table.remove(particles, i) end
  end
end

function luna.draw()
  for _, p in ipairs(particles) do
    local a = p.life
    luna.graphics.setColor(1, 0.8, 0.2, a)
    luna.graphics.circle("fill", p.x, p.y, 3)
  end
  luna.graphics.setColor(1, 1, 1, 1)
end`,
  },
  {
    label: "Screen shake",
    category: "Graphics",
    code: `local shake_timer = 0
local shake_intensity = 0
local shake_ox, shake_oy = 0, 0

local function startShake(duration, intensity)
  shake_timer = duration
  shake_intensity = intensity
end

function luna.update(dt)
  if shake_timer > 0 then
    shake_timer = shake_timer - dt
    shake_ox = (math.random() - 0.5) * 2 * shake_intensity
    shake_oy = (math.random() - 0.5) * 2 * shake_intensity
  else
    shake_ox, shake_oy = 0, 0
  end
end

function luna.draw()
  luna.graphics.push()
  luna.graphics.translate(shake_ox, shake_oy)
  -- Draw your game here
  luna.graphics.pop()
end`,
  },

  // Input
  {
    label: "WASD movement",
    category: "Input",
    code: `local player = { x = 400, y = 300, speed = 200 }

function luna.update(dt)
  if luna.keyboard.isDown("w") or luna.keyboard.isDown("up") then
    player.y = player.y - player.speed * dt
  end
  if luna.keyboard.isDown("s") or luna.keyboard.isDown("down") then
    player.y = player.y + player.speed * dt
  end
  if luna.keyboard.isDown("a") or luna.keyboard.isDown("left") then
    player.x = player.x - player.speed * dt
  end
  if luna.keyboard.isDown("d") or luna.keyboard.isDown("right") then
    player.x = player.x + player.speed * dt
  end
end`,
  },
  {
    label: "Mouse aim",
    category: "Input",
    code: `local player = { x = 400, y = 300, angle = 0 }

function luna.update(dt)
  local mx, my = luna.mouse.getPosition()
  player.angle = math.atan2(my - player.y, mx - player.x)
end

function luna.draw()
  luna.graphics.push()
  luna.graphics.translate(player.x, player.y)
  luna.graphics.rotate(player.angle)
  luna.graphics.setColor(0.3, 0.7, 1)
  luna.graphics.rectangle("fill", -16, -8, 32, 16)
  luna.graphics.pop()
end`,
  },
  {
    label: "Gamepad support",
    category: "Input",
    code: `local player = { x = 400, y = 300, speed = 200 }

function luna.update(dt)
  local axes = luna.gamepad.getAxes(1)
  if axes then
    local deadzone = 0.2
    if math.abs(axes.leftx) > deadzone then
      player.x = player.x + axes.leftx * player.speed * dt
    end
    if math.abs(axes.lefty) > deadzone then
      player.y = player.y + axes.lefty * player.speed * dt
    end
  end
end

function luna.gamepadpressed(id, button)
  if button == "a" then
    -- Jump or action
  end
end`,
  },
  {
    label: "Touch controls",
    category: "Input",
    code: `local touches = {}

function luna.touchpressed(id, x, y, dx, dy, pressure)
  touches[id] = { x = x, y = y, startX = x, startY = y }
end

function luna.touchmoved(id, x, y, dx, dy, pressure)
  if touches[id] then
    touches[id].x = x
    touches[id].y = y
  end
end

function luna.touchreleased(id, x, y, dx, dy, pressure)
  if touches[id] then
    local swipeX = x - touches[id].startX
    local swipeY = y - touches[id].startY
    -- Detect swipe direction
    if math.abs(swipeX) > 50 then
      if swipeX > 0 then print("Swipe right") else print("Swipe left") end
    end
    if math.abs(swipeY) > 50 then
      if swipeY > 0 then print("Swipe down") else print("Swipe up") end
    end
    touches[id] = nil
  end
end`,
  },

  // Physics
  {
    label: "Platformer controller",
    category: "Physics",
    code: `local player = { x = 100, y = 400, w = 32, h = 48, vx = 0, vy = 0, onGround = false }
local gravity = 980
local jumpForce = -450
local moveSpeed = 200
local friction = 0.85
local ground_y = 500

function luna.update(dt)
  -- Horizontal
  if luna.keyboard.isDown("left") then player.vx = -moveSpeed
  elseif luna.keyboard.isDown("right") then player.vx = moveSpeed
  else player.vx = player.vx * friction end

  -- Gravity
  player.vy = player.vy + gravity * dt

  -- Apply
  player.x = player.x + player.vx * dt
  player.y = player.y + player.vy * dt

  -- Ground check
  if player.y + player.h >= ground_y then
    player.y = ground_y - player.h
    player.vy = 0
    player.onGround = true
  else
    player.onGround = false
  end
end

function luna.keypressed(key)
  if key == "space" and player.onGround then
    player.vy = jumpForce
  end
end`,
  },
  {
    label: "Top-down movement",
    category: "Physics",
    code: `local player = { x = 400, y = 300, vx = 0, vy = 0, speed = 200, friction = 8 }

function luna.update(dt)
  local ix, iy = 0, 0
  if luna.keyboard.isDown("w") then iy = iy - 1 end
  if luna.keyboard.isDown("s") then iy = iy + 1 end
  if luna.keyboard.isDown("a") then ix = ix - 1 end
  if luna.keyboard.isDown("d") then ix = ix + 1 end

  -- Normalize
  local len = math.sqrt(ix * ix + iy * iy)
  if len > 0 then ix, iy = ix / len, iy / len end

  -- Accelerate
  player.vx = player.vx + ix * player.speed * dt * 10
  player.vy = player.vy + iy * player.speed * dt * 10

  -- Friction
  player.vx = player.vx * (1 - player.friction * dt)
  player.vy = player.vy * (1 - player.friction * dt)

  player.x = player.x + player.vx * dt
  player.y = player.y + player.vy * dt
end`,
  },
  {
    label: "Projectile",
    category: "Physics",
    code: `local bullets = {}

local function shoot(x, y, angle, speed)
  table.insert(bullets, {
    x = x, y = y,
    vx = math.cos(angle) * speed,
    vy = math.sin(angle) * speed,
    life = 3.0,
  })
end

function luna.update(dt)
  for i = #bullets, 1, -1 do
    local b = bullets[i]
    b.x = b.x + b.vx * dt
    b.y = b.y + b.vy * dt
    b.life = b.life - dt
    if b.life <= 0 or b.x < -10 or b.x > 810 or b.y < -10 or b.y > 610 then
      table.remove(bullets, i)
    end
  end
end

function luna.draw()
  luna.graphics.setColor(1, 1, 0)
  for _, b in ipairs(bullets) do
    luna.graphics.circle("fill", b.x, b.y, 3)
  end
end`,
  },
  {
    label: "Raycast",
    category: "Physics",
    code: `-- Simple DDA raycast on a tile grid
local function raycast(grid, x, y, angle, maxDist)
  local dx = math.cos(angle)
  local dy = math.sin(angle)
  local dist = 0
  local step = 1

  while dist < maxDist do
    local checkX = math.floor(x + dx * dist)
    local checkY = math.floor(y + dy * dist)
    local gx = math.floor(checkX / 32) + 1
    local gy = math.floor(checkY / 32) + 1

    if grid[gy] and grid[gy][gx] and grid[gy][gx] > 0 then
      return { hit = true, x = checkX, y = checkY, dist = dist, tile = grid[gy][gx] }
    end
    dist = dist + step
  end

  return { hit = false, x = x + dx * maxDist, y = y + dy * maxDist, dist = maxDist }
end`,
  },

  // UI
  {
    label: "Health bar",
    category: "UI",
    code: `local hp = { current = 75, max = 100 }

local function drawHealthBar(x, y, w, h)
  local pct = hp.current / hp.max

  -- Background
  luna.graphics.setColor(0.2, 0.2, 0.2)
  luna.graphics.rectangle("fill", x, y, w, h)

  -- Fill
  local color_r = (1 - pct) * 2
  local color_g = pct * 2
  luna.graphics.setColor(math.min(color_r, 1), math.min(color_g, 1), 0)
  luna.graphics.rectangle("fill", x, y, w * pct, h)

  -- Border
  luna.graphics.setColor(0.8, 0.8, 0.8)
  luna.graphics.rectangle("line", x, y, w, h)

  -- Text
  luna.graphics.setColor(1, 1, 1)
  luna.graphics.print(hp.current .. "/" .. hp.max, x + 4, y + 2)
end`,
  },
  {
    label: "Dialog box",
    category: "UI",
    code: `local dialog = { active = false, text = "", speaker = "", char_idx = 0, timer = 0, speed = 0.03 }

local function showDialog(speaker, text)
  dialog.active = true
  dialog.speaker = speaker
  dialog.text = text
  dialog.char_idx = 0
  dialog.timer = 0
end

function luna.update(dt)
  if not dialog.active then return end
  dialog.timer = dialog.timer + dt
  if dialog.timer >= dialog.speed then
    dialog.timer = dialog.timer - dialog.speed
    dialog.char_idx = math.min(dialog.char_idx + 1, #dialog.text)
  end
end

function luna.keypressed(key)
  if dialog.active and (key == "space" or key == "return") then
    if dialog.char_idx < #dialog.text then
      dialog.char_idx = #dialog.text
    else
      dialog.active = false
    end
  end
end

local function drawDialog()
  if not dialog.active then return end
  luna.graphics.setColor(0, 0, 0, 0.85)
  luna.graphics.rectangle("fill", 50, 400, 700, 150)
  luna.graphics.setColor(0.7, 0.7, 0.9)
  luna.graphics.rectangle("line", 50, 400, 700, 150)
  luna.graphics.setColor(0.9, 0.8, 1)
  luna.graphics.print(dialog.speaker, 70, 410)
  luna.graphics.setColor(1, 1, 1)
  luna.graphics.print(string.sub(dialog.text, 1, dialog.char_idx), 70, 440)
end`,
  },
  {
    label: "Menu system",
    category: "UI",
    code: `local menu = {
  items = { "Start Game", "Options", "Quit" },
  selected = 1,
}

function luna.keypressed(key)
  if key == "up" then
    menu.selected = menu.selected - 1
    if menu.selected < 1 then menu.selected = #menu.items end
  elseif key == "down" then
    menu.selected = menu.selected + 1
    if menu.selected > #menu.items then menu.selected = 1 end
  elseif key == "return" then
    if menu.items[menu.selected] == "Quit" then
      luna.event.quit()
    end
  end
end

function luna.draw()
  luna.graphics.setBackgroundColor(0.1, 0.1, 0.15)
  for i, item in ipairs(menu.items) do
    local y = 200 + (i - 1) * 50
    if i == menu.selected then
      luna.graphics.setColor(1, 0.9, 0.2)
      luna.graphics.print("> " .. item, 300, y)
    else
      luna.graphics.setColor(0.7, 0.7, 0.7)
      luna.graphics.print("  " .. item, 300, y)
    end
  end
end`,
  },
  {
    label: "Minimap",
    category: "UI",
    code: `local minimap = { x = 620, y = 10, w = 160, h = 120, scale = 0.1 }

local function drawMinimap(world_objects, player, world_w, world_h)
  -- Background
  luna.graphics.setColor(0, 0, 0, 0.6)
  luna.graphics.rectangle("fill", minimap.x, minimap.y, minimap.w, minimap.h)
  luna.graphics.setColor(0.5, 0.5, 0.5)
  luna.graphics.rectangle("line", minimap.x, minimap.y, minimap.w, minimap.h)

  local sx = minimap.w / world_w
  local sy = minimap.h / world_h

  -- Objects
  luna.graphics.setColor(0.4, 0.4, 0.6)
  for _, obj in ipairs(world_objects) do
    luna.graphics.rectangle("fill",
      minimap.x + obj.x * sx, minimap.y + obj.y * sy,
      math.max(obj.w * sx, 2), math.max(obj.h * sy, 2))
  end

  -- Player dot
  luna.graphics.setColor(0, 1, 0)
  luna.graphics.circle("fill", minimap.x + player.x * sx, minimap.y + player.y * sy, 3)
end`,
  },

  // Audio
  {
    label: "Music manager",
    category: "Audio",
    code: `local music = { current = nil, volume = 0.7 }

local function playMusic(file)
  if music.current then
    luna.audio.stop(music.current)
  end
  music.current = luna.audio.newSource(file, "stream")
  luna.audio.setVolume(music.current, music.volume)
  luna.audio.play(music.current)
end

local function setMusicVolume(vol)
  music.volume = math.max(0, math.min(1, vol))
  if music.current then
    luna.audio.setVolume(music.current, music.volume)
  end
end

local function stopMusic()
  if music.current then
    luna.audio.stop(music.current)
    music.current = nil
  end
end`,
  },
  {
    label: "SFX player",
    category: "Audio",
    code: `local sfx = {}

local function loadSFX(name, file)
  sfx[name] = luna.audio.newSource(file, "static")
end

local function playSFX(name, volume, pitch)
  local s = sfx[name]
  if s then
    local clone = luna.audio.clone(s)
    luna.audio.setVolume(clone, volume or 1.0)
    luna.audio.setPitch(clone, pitch or 1.0)
    luna.audio.play(clone)
  end
end

-- Usage:
-- loadSFX("jump", "assets/sounds/jump.wav")
-- playSFX("jump", 0.8)`,
  },
  {
    label: "Volume control",
    category: "Audio",
    code: `local master_volume = 1.0

function luna.keypressed(key)
  if key == "+" or key == "=" then
    master_volume = math.min(master_volume + 0.1, 1.0)
    luna.audio.setMasterVolume(master_volume)
  elseif key == "-" then
    master_volume = math.max(master_volume - 0.1, 0.0)
    luna.audio.setMasterVolume(master_volume)
  elseif key == "m" then
    if master_volume > 0 then
      master_volume = 0
    else
      master_volume = 1.0
    end
    luna.audio.setMasterVolume(master_volume)
  end
end`,
  },
  {
    label: "Crossfade",
    category: "Audio",
    code: `local crossfade = { from = nil, to = nil, progress = 0, duration = 2.0, active = false }

local function crossfadeTo(newMusic, duration)
  crossfade.from = crossfade.to or nil
  crossfade.to = luna.audio.newSource(newMusic, "stream")
  luna.audio.setVolume(crossfade.to, 0)
  luna.audio.play(crossfade.to)
  crossfade.progress = 0
  crossfade.duration = duration or 2.0
  crossfade.active = true
end

function luna.update(dt)
  if not crossfade.active then return end
  crossfade.progress = crossfade.progress + dt / crossfade.duration
  if crossfade.progress >= 1 then
    crossfade.progress = 1
    crossfade.active = false
    if crossfade.from then luna.audio.stop(crossfade.from) end
  end
  if crossfade.from then luna.audio.setVolume(crossfade.from, 1 - crossfade.progress) end
  if crossfade.to then luna.audio.setVolume(crossfade.to, crossfade.progress) end
end`,
  },

  // Data
  {
    label: "Save/Load",
    category: "Data",
    code: `local function saveGame(data, filename)
  filename = filename or "save.lua"
  local function serialize(val, indent)
    indent = indent or ""
    local t = type(val)
    if t == "table" then
      local parts = { "{\\n" }
      for k, v in pairs(val) do
        local key = type(k) == "number" and "" or ("[" .. serialize(k) .. "] = ")
        table.insert(parts, indent .. "  " .. key .. serialize(v, indent .. "  ") .. ",\\n")
      end
      table.insert(parts, indent .. "}")
      return table.concat(parts)
    elseif t == "string" then
      return string.format("%q", val)
    else
      return tostring(val)
    end
  end
  luna.filesystem.write(filename, "return " .. serialize(data))
end

local function loadGame(filename)
  filename = filename or "save.lua"
  if not luna.filesystem.exists(filename) then return nil end
  local content = luna.filesystem.read(filename)
  local fn = load(content)
  return fn and fn() or nil
end`,
  },
  {
    label: "Config file",
    category: "Data",
    code: `local config = {
  music_volume = 0.7,
  sfx_volume = 1.0,
  fullscreen = false,
  language = "en",
}

local function loadConfig()
  if luna.filesystem.exists("config.lua") then
    local content = luna.filesystem.read("config.lua")
    local fn = load(content)
    if fn then
      local loaded = fn()
      for k, v in pairs(loaded) do
        config[k] = v
      end
    end
  end
end

local function saveConfig()
  local lines = { "return {" }
  for k, v in pairs(config) do
    if type(v) == "string" then
      table.insert(lines, string.format("  %s = %q,", k, v))
    else
      table.insert(lines, string.format("  %s = %s,", k, tostring(v)))
    end
  end
  table.insert(lines, "}")
  luna.filesystem.write("config.lua", table.concat(lines, "\\n"))
end`,
  },
  {
    label: "High scores",
    category: "Data",
    code: `local scores = {}
local MAX_SCORES = 10

local function loadScores()
  if luna.filesystem.exists("scores.lua") then
    local content = luna.filesystem.read("scores.lua")
    local fn = load(content)
    if fn then scores = fn() or {} end
  end
end

local function saveScores()
  local lines = { "return {" }
  for _, entry in ipairs(scores) do
    table.insert(lines, string.format('  { name = %q, score = %d },', entry.name, entry.score))
  end
  table.insert(lines, "}")
  luna.filesystem.write("scores.lua", table.concat(lines, "\\n"))
end

local function addScore(name, score)
  table.insert(scores, { name = name, score = score })
  table.sort(scores, function(a, b) return a.score > b.score end)
  while #scores > MAX_SCORES do table.remove(scores) end
  saveScores()
end`,
  },
  {
    label: "Inventory",
    category: "Data",
    code: `local inventory = { slots = {}, maxSlots = 20 }

local function addItem(name, count)
  count = count or 1
  for _, slot in ipairs(inventory.slots) do
    if slot.name == name then
      slot.count = slot.count + count
      return true
    end
  end
  if #inventory.slots < inventory.maxSlots then
    table.insert(inventory.slots, { name = name, count = count })
    return true
  end
  return false  -- inventory full
end

local function removeItem(name, count)
  count = count or 1
  for i, slot in ipairs(inventory.slots) do
    if slot.name == name then
      slot.count = slot.count - count
      if slot.count <= 0 then table.remove(inventory.slots, i) end
      return true
    end
  end
  return false  -- item not found
end

local function hasItem(name, count)
  count = count or 1
  for _, slot in ipairs(inventory.slots) do
    if slot.name == name and slot.count >= count then return true end
  end
  return false
end`,
  },
];

// ─── Helpers ──────────────────────────────────────────────

function getCategories(): string[] {
  const cats = new Set<string>();
  for (const s of SNIPPETS) {
    cats.add(s.category);
  }
  return [...cats].sort();
}

function listPatternFiles(extensionPath: string): Array<{ name: string; fullPath: string }> {
  const dir = path.join(extensionPath, "data", "patterns");
  if (!fs.existsSync(dir)) {
    return [];
  }
  return fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".lua"))
    .map((f) => ({ name: f.replace(".lua", ""), fullPath: path.join(dir, f) }));
}

// ─── Commands ─────────────────────────────────────────────

export function registerLibraryCommands(context: vscode.ExtensionContext): void {
  // ── luna.library.browse ──────────────────────────────────
  context.subscriptions.push(
    vscode.commands.registerCommand("luna.library.browse", async () => {
      const patterns = listPatternFiles(context.extensionPath);
      if (patterns.length === 0) {
        vscode.window.showInformationMessage("No patterns found in data/patterns/.");
        return;
      }

      const picked = await vscode.window.showQuickPick(
        patterns.map((p) => ({
          label: p.name,
          description: `data/patterns/${p.name}.lua`,
          fullPath: p.fullPath,
        })),
        { placeHolder: "Browse Luna2D patterns" }
      );
      if (!picked) {
        return;
      }

      // Show preview with option to copy to project
      const action = await vscode.window.showQuickPick(
        [
          { label: "Preview", description: "Open the pattern file in a new tab" },
          { label: "Copy to project", description: "Copy to libs/ folder in your project" },
        ],
        { placeHolder: `${picked.label}: What would you like to do?` }
      );

      if (!action) {
        return;
      }

      if (action.label === "Preview") {
        const doc = await vscode.workspace.openTextDocument(picked.fullPath);
        await vscode.window.showTextDocument(doc, { preview: true });
      } else {
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
        if (!workspaceRoot) {
          vscode.window.showErrorMessage("No workspace folder open.");
          return;
        }

        const libsDir = path.join(workspaceRoot, "libs");
        if (!fs.existsSync(libsDir)) {
          fs.mkdirSync(libsDir, { recursive: true });
        }

        const dest = path.join(libsDir, `${picked.label}.lua`);
        if (fs.existsSync(dest)) {
          const overwrite = await vscode.window.showWarningMessage(
            `libs/${picked.label}.lua already exists. Overwrite?`,
            "Yes",
            "No"
          );
          if (overwrite !== "Yes") {
            return;
          }
        }

        fs.copyFileSync(picked.fullPath, dest);
        vscode.window.showInformationMessage(`Copied ${picked.label} to libs/${picked.label}.lua`);
      }
    })
  );

  // ── luna.library.insertSnippet ───────────────────────────
  context.subscriptions.push(
    vscode.commands.registerCommand("luna.library.insertSnippet", async () => {
      const categories = getCategories();

      const catPick = await vscode.window.showQuickPick(
        categories.map((c) => ({ label: c })),
        { placeHolder: "Choose snippet category" }
      );
      if (!catPick) {
        return;
      }

      const snippetsInCat = SNIPPETS.filter((s) => s.category === catPick.label);
      const snippetPick = await vscode.window.showQuickPick(
        snippetsInCat.map((s) => ({ label: s.label, snippet: s })),
        { placeHolder: `${catPick.label} snippets` }
      );
      if (!snippetPick) {
        return;
      }

      const editor = vscode.window.activeTextEditor;
      if (!editor) {
        // No editor open — create a new untitled document
        const doc = await vscode.workspace.openTextDocument({
          language: "lua",
          content: snippetPick.snippet.code + "\n",
        });
        await vscode.window.showTextDocument(doc);
        return;
      }

      // Insert at cursor
      await editor.edit((editBuilder) => {
        editBuilder.insert(editor.selection.active, snippetPick.snippet.code + "\n");
      });
    })
  );

  // ── luna.library.newPattern ──────────────────────────────
  context.subscriptions.push(
    vscode.commands.registerCommand("luna.library.newPattern", async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor || editor.selection.isEmpty) {
        vscode.window.showWarningMessage("Select some Lua code first to create a pattern from it.");
        return;
      }

      const selectedText = editor.document.getText(editor.selection);

      const name = await vscode.window.showInputBox({
        prompt: "Pattern name",
        placeHolder: "my-pattern",
        validateInput: (v) => {
          if (!v.trim()) {
            return "Name cannot be empty";
          }
          if (/[<>:"/\\|?*\s]/.test(v)) {
            return "Name should be a simple identifier (use dashes, no spaces)";
          }
          return undefined;
        },
      });
      if (!name) {
        return;
      }

      const category = await vscode.window.showInputBox({
        prompt: "Category",
        placeHolder: "e.g. gameplay, ui, utility",
      });

      const description = await vscode.window.showInputBox({
        prompt: "Brief description",
        placeHolder: "What does this pattern do?",
      });

      const header = [
        `--- ${name} pattern for Luna2D.`,
        `--- ${description ?? "Custom pattern."}`,
        `---`,
        `--- Category: ${category ?? "general"}`,
        `---`,
        "",
      ].join("\n");

      const patternsDir = path.join(context.extensionPath, "data", "patterns");
      if (!fs.existsSync(patternsDir)) {
        fs.mkdirSync(patternsDir, { recursive: true });
      }

      const destFile = path.join(patternsDir, `${name}.lua`);
      if (fs.existsSync(destFile)) {
        const overwrite = await vscode.window.showWarningMessage(
          `Pattern "${name}" already exists. Overwrite?`,
          "Yes",
          "No"
        );
        if (overwrite !== "Yes") {
          return;
        }
      }

      fs.writeFileSync(destFile, header + selectedText + "\n", "utf-8");
      vscode.window.showInformationMessage(`Pattern "${name}" saved to data/patterns/${name}.lua`);
    })
  );
}
