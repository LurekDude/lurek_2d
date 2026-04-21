import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";

interface TemplateChoice {
  label: string;
  description: string;
  files: Record<string, string>;
}

const PROJECT_TEMPLATES: TemplateChoice[] = [
  {
    label: "Minimal",
    description: "Empty main.lua with gameloop stubs",
    files: {
      "main.lua": [
        "function lurek.load()",
        "end",
        "",
        "function lurek.update(dt)",
        "end",
        "",
        "function lurek.draw()",
        "end",
        "",
      ].join("\n"),
      "conf.lua": [
        'function lurek.conf(t)',
        '  t.window.title = "My Game"',
        '  t.window.width = 800',
        '  t.window.height = 600',
        'end',
      ].join("\n"),
    },
  },
  {
    label: "Game Loop",
    description: "Full game loop with player movement",
    files: {
      "main.lua": [
        "local x, y = 400, 300",
        "local speed = 200",
        "",
        "function lurek.load()",
        '  lurek.window.setTitle("Game Loop Demo")',
        "end",
        "",
        "function lurek.update(dt)",
        '  if lurek.input.keyboard.isDown("left") then x = x - speed * dt end',
        '  if lurek.input.keyboard.isDown("right") then x = x + speed * dt end',
        '  if lurek.input.keyboard.isDown("up") then y = y - speed * dt end',
        '  if lurek.input.keyboard.isDown("down") then y = y + speed * dt end',
        "end",
        "",
        "function lurek.draw()",
        "  lurek.graphics.clear(0.1, 0.1, 0.2)",
        "  lurek.graphics.setColor(1, 1, 1)",
        "  lurek.graphics.circle(\"fill\", x, y, 20)",
        "end",
        "",
      ].join("\n"),
      "conf.lua": [
        'function lurek.conf(t)',
        '  t.window.title = "Game Loop Demo"',
        '  t.window.width = 800',
        '  t.window.height = 600',
        'end',
      ].join("\n"),
    },
  },
  {
    label: "Physics",
    description: "Physics world with falling objects",
    files: {
      "main.lua": [
        "local world",
        "local ground, ball",
        "",
        "function lurek.load()",
        "  world = lurek.physics.newWorld(0, 981)",
        '  ground = lurek.physics.newBody(world, 400, 580, "static")',
        "  lurek.physics.newRectangleShape(ground, 800, 40)",
        '  ball = lurek.physics.newBody(world, 400, 100, "dynamic")',
        "  lurek.physics.newCircleShape(ball, 20)",
        "end",
        "",
        "function lurek.update(dt)",
        "  world:update(dt)",
        "end",
        "",
        "function lurek.draw()",
        "  lurek.graphics.clear(0.1, 0.1, 0.2)",
        "  lurek.graphics.setColor(0.3, 0.3, 0.3)",
        '  lurek.graphics.rectangle("fill", 0, 560, 800, 40)',
        "  lurek.graphics.setColor(1, 0.3, 0.3)",
        "  local bx, by = ball:getPosition()",
        '  lurek.graphics.circle("fill", bx, by, 20)',
        "end",
        "",
      ].join("\n"),
      "conf.lua": [
        'function lurek.conf(t)',
        '  t.window.title = "Physics Demo"',
        '  t.window.width = 800',
        '  t.window.height = 600',
        'end',
      ].join("\n"),
    },
  },
  {
    label: "Platformer",
    description: "Simple platformer with gravity and jumping",
    files: {
      "main.lua": [
        "local player = { x = 100, y = 400, vy = 0, w = 32, h = 48, onGround = false }",
        "local gravity = 900",
        "local jumpForce = -400",
        "local moveSpeed = 200",
        "local groundY = 500",
        "",
        "function lurek.update(dt)",
        "  -- Horizontal movement",
        '  if lurek.input.keyboard.isDown("left") then player.x = player.x - moveSpeed * dt end',
        '  if lurek.input.keyboard.isDown("right") then player.x = player.x + moveSpeed * dt end',
        "",
        "  -- Gravity",
        "  player.vy = player.vy + gravity * dt",
        "  player.y = player.y + player.vy * dt",
        "",
        "  -- Ground collision",
        "  if player.y + player.h >= groundY then",
        "    player.y = groundY - player.h",
        "    player.vy = 0",
        "    player.onGround = true",
        "  else",
        "    player.onGround = false",
        "  end",
        "end",
        "",
        "function lurek.keypressed(key)",
        '  if key == "space" and player.onGround then',
        "    player.vy = jumpForce",
        "  end",
        "end",
        "",
        "function lurek.draw()",
        "  lurek.graphics.clear(0.2, 0.3, 0.4)",
        "  lurek.graphics.setColor(0.4, 0.4, 0.4)",
        '  lurek.graphics.rectangle("fill", 0, groundY, 800, 100)',
        "  lurek.graphics.setColor(0.2, 0.8, 0.4)",
        '  lurek.graphics.rectangle("fill", player.x, player.y, player.w, player.h)',
        "end",
        "",
      ].join("\n"),
      "conf.lua": [
        'function lurek.conf(t)',
        '  t.window.title = "Platformer"',
        '  t.window.width = 800',
        '  t.window.height = 600',
        'end',
      ].join("\n"),
    },
  },
  {
    label: "Top-Down",
    description: "Top-down view with WASD movement",
    files: {
      "main.lua": [
        "local player = { x = 400, y = 300, speed = 200, size = 16 }",
        "",
        "function lurek.update(dt)",
        '  if lurek.input.keyboard.isDown("w") then player.y = player.y - player.speed * dt end',
        '  if lurek.input.keyboard.isDown("s") then player.y = player.y + player.speed * dt end',
        '  if lurek.input.keyboard.isDown("a") then player.x = player.x - player.speed * dt end',
        '  if lurek.input.keyboard.isDown("d") then player.x = player.x + player.speed * dt end',
        "end",
        "",
        "function lurek.draw()",
        "  lurek.graphics.clear(0.15, 0.15, 0.2)",
        "  lurek.graphics.setColor(0.3, 0.7, 1)",
        '  lurek.graphics.rectangle("fill", player.x - player.size/2, player.y - player.size/2, player.size, player.size)',
        "end",
        "",
      ].join("\n"),
      "conf.lua": [
        'function lurek.conf(t)',
        '  t.window.title = "Top-Down"',
        '  t.window.width = 800',
        '  t.window.height = 600',
        'end',
      ].join("\n"),
    },
  },
  {
    label: "ECS",
    description: "Entity Component System with lurek.ecs",
    files: {
      "main.lua": [
        "local universe",
        "",
        "function lurek.load()",
        "  universe = lurek.ecs.newUniverse()",
        "",
        "  for i = 1, 10 do",
        "    local e = universe:spawn()",
        "    e:set(\"position\", { x = math.random(50, 750), y = math.random(50, 550) })",
        "    e:set(\"velocity\", { x = math.random(-100, 100), y = math.random(-100, 100) })",
        "    e:set(\"radius\", math.random(5, 20))",
        "  end",
        "end",
        "",
        "function lurek.update(dt)",
        '  for _, e in universe:query("position", "velocity") do',
        '    local pos = e:get("position")',
        '    local vel = e:get("velocity")',
        "    pos.x = pos.x + vel.x * dt",
        "    pos.y = pos.y + vel.y * dt",
        "    if pos.x < 0 or pos.x > 800 then vel.x = -vel.x end",
        "    if pos.y < 0 or pos.y > 600 then vel.y = -vel.y end",
        "  end",
        "end",
        "",
        "function lurek.draw()",
        "  lurek.graphics.clear(0.1, 0.1, 0.15)",
        '  for _, e in universe:query("position", "radius") do',
        '    local pos = e:get("position")',
        '    local r = e:get("radius")',
        "    lurek.graphics.setColor(0.4, 0.8, 1)",
        '    lurek.graphics.circle("fill", pos.x, pos.y, r)',
        "  end",
        "end",
        "",
      ].join("\n"),
      "conf.lua": [
        'function lurek.conf(t)',
        '  t.window.title = "ECS Demo"',
        '  t.window.width = 800',
        '  t.window.height = 600',
        'end',
      ].join("\n"),
    },
  },
];

const FILE_TEMPLATES: Record<string, string> = {
  "main.lua": "function lurek.load()\nend\n\nfunction lurek.update(dt)\nend\n\nfunction lurek.draw()\nend\n",
  "conf.lua": 'function lurek.conf(t)\n  t.window.title = "My Game"\n  t.window.width = 800\n  t.window.height = 600\nend\n',
  "class.lua": "local MyClass = {}\nMyClass.__index = MyClass\n\nfunction MyClass.new()\n  return setmetatable({}, MyClass)\nend\n\nfunction MyClass:update(dt)\nend\n\nfunction MyClass:draw()\nend\n\nreturn MyClass\n",
  "scene.lua": "local Scene = {}\nScene.__index = Scene\n\nfunction Scene.new()\n  return setmetatable({}, Scene)\nend\n\nfunction Scene:enter()\nend\n\nfunction Scene:update(dt)\nend\n\nfunction Scene:draw()\nend\n\nfunction Scene:leave()\nend\n\nreturn Scene\n",
};

/**
 * Scaffolds a new project from a template.
 */
export async function scaffoldProject(): Promise<void> {
  const items = PROJECT_TEMPLATES.map((t) => ({
    label: t.label,
    description: t.description,
  }));

  const picked = await vscode.window.showQuickPick(items, {
    placeHolder: "Select a project template",
  });
  if (!picked) {
    return;
  }

  const folder = await vscode.window.showOpenDialog({
    canSelectFolders: true,
    canSelectFiles: false,
    canSelectMany: false,
    openLabel: "Select Project Folder",
  });
  if (!folder || folder.length === 0) {
    return;
  }

  const projectDir = folder[0].fsPath;
  const template = PROJECT_TEMPLATES.find((t) => t.label === picked.label);
  if (!template) {
    return;
  }

  for (const [filename, content] of Object.entries(template.files)) {
    const filePath = path.join(projectDir, filename);
    if (!fs.existsSync(filePath)) {
      fs.writeFileSync(filePath, content, "utf-8");
    }
  }

  // Open the project
  const uri = vscode.Uri.file(projectDir);
  await vscode.commands.executeCommand("vscode.openFolder", uri);
}

/**
 * Scaffolds a single file from a template.
 */
export async function scaffoldFile(): Promise<void> {
  const templateNames = Object.keys(FILE_TEMPLATES);
  const picked = await vscode.window.showQuickPick(templateNames, {
    placeHolder: "Select a file template",
  });
  if (!picked) {
    return;
  }

  const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!root) {
    vscode.window.showErrorMessage("No workspace folder open.");
    return;
  }

  const filename = await vscode.window.showInputBox({
    prompt: "Enter file name",
    value: picked,
  });
  if (!filename) {
    return;
  }

  const filePath = path.join(root, filename);
  if (fs.existsSync(filePath)) {
    vscode.window.showWarningMessage(`File already exists: ${filename}`);
    return;
  }

  fs.writeFileSync(filePath, FILE_TEMPLATES[picked], "utf-8");
  const doc = await vscode.workspace.openTextDocument(filePath);
  await vscode.window.showTextDocument(doc);
}
