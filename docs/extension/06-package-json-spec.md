# Luna Toolkit — package.json Specification

> This document specifies the complete `package.json` manifest for the Luna Toolkit extension.
> It defines all commands, views, settings, keybindings, menus, and custom editors.

---

## Full Manifest

```jsonc
{
  "name": "luna-toolkit",
  "displayName": "Luna Toolkit",
  "description": "Complete development toolkit for Luna2D game engine — IntelliSense, visual editors, run/test/package, debug bridge, and AI-powered game development",
  "version": "1.0.0",
  "publisher": "luna2d",
  "icon": "media/luna-logo.png",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/RandomBladeDude/luna2d"
  },
  "engines": {
    "vscode": "^1.90.0"
  },
  "categories": [
    "Programming Languages",
    "Snippets",
    "Debuggers",
    "Other"
  ],
  "keywords": [
    "lua",
    "game",
    "game engine",
    "2d",
    "luna2d",
    "game development",
    "pixel art",
    "tilemap"
  ],
  "activationEvents": [
    "workspaceContains:**/main.lua",
    "workspaceContains:Cargo.toml",
    "onLanguage:lua"
  ],
  "main": "./dist/extension.js",

  "contributes": {

    // ─── VIEWS ───────────────────────────────────────────────────

    "viewsContainers": {
      "activitybar": [
        {
          "id": "luna-sidebar",
          "title": "Luna Toolkit",
          "icon": "media/sidebar-icon.svg"
        }
      ]
    },

    "views": {
      "luna-sidebar": [
        { "id": "luna.projectTools", "name": "Project" },
        { "id": "luna.devTools",     "name": "Dev Tools" },
        { "id": "luna.aiCopilot",    "name": "AI & Copilot" }
      ]
    },

    "viewsWelcome": [
      {
        "view": "luna.projectTools",
        "contents": "No Luna2D project detected.\n[Create New Project](command:luna.scaffold.project)\n[Open Folder with main.lua](command:vscode.openFolder)"
      }
    ],

    // ─── COMMANDS ────────────────────────────────────────────────

    "commands": [
      // --- Run ---
      { "command": "luna.runGame",       "title": "Luna: Run Game",             "icon": "$(play)" },
      { "command": "luna.stopGame",      "title": "Luna: Stop Game",            "icon": "$(debug-stop)" },
      { "command": "luna.runWithArgs",   "title": "Luna: Run with Arguments" },
      { "command": "luna.runExample",    "title": "Luna: Run Example" },

      // --- Testing: All ---
      { "command": "luna.test.all",      "title": "Luna: Run All Tests",        "icon": "$(testing-run-all-icon)" },

      // --- Testing: Rust modules ---
      { "command": "luna.test.rust.math",       "title": "Luna: Test Math" },
      { "command": "luna.test.rust.physics",     "title": "Luna: Test Physics" },
      { "command": "luna.test.rust.graphics",    "title": "Luna: Test Graphics" },
      { "command": "luna.test.rust.audio",       "title": "Luna: Test Audio" },
      { "command": "luna.test.rust.input",       "title": "Luna: Test Input" },
      { "command": "luna.test.rust.timer",       "title": "Luna: Test Timer" },
      { "command": "luna.test.rust.filesystem",  "title": "Luna: Test Filesystem" },
      { "command": "luna.test.rust.tilemap",     "title": "Luna: Test Tilemap" },
      { "command": "luna.test.rust.scene",       "title": "Luna: Test Scene" },
      { "command": "luna.test.rust.ai",          "title": "Luna: Test AI" },
      { "command": "luna.test.rust.compute",     "title": "Luna: Test Compute" },
      { "command": "luna.test.rust.data",        "title": "Luna: Test Data" },
      { "command": "luna.test.rust.dataframe",   "title": "Luna: Test DataFrame" },
      { "command": "luna.test.rust.entity",      "title": "Luna: Test Entity" },
      { "command": "luna.test.rust.event",       "title": "Luna: Test Event" },
      { "command": "luna.test.rust.graph",       "title": "Luna: Test Graph" },
      { "command": "luna.test.rust.image",       "title": "Luna: Test Image" },
      { "command": "luna.test.rust.modding",     "title": "Luna: Test Modding" },
      { "command": "luna.test.rust.particle",    "title": "Luna: Test Particle" },
      { "command": "luna.test.rust.savegame",    "title": "Luna: Test SaveGame" },
      { "command": "luna.test.rust.sound",       "title": "Luna: Test Sound" },
      { "command": "luna.test.rust.system",      "title": "Luna: Test System" },

      // --- Testing: Lua ---
      { "command": "luna.test.lua.all",          "title": "Luna: Run All Lua Tests" },
      { "command": "luna.test.lua.golden",       "title": "Luna: Run Golden Tests" },
      { "command": "luna.test.generateForFile",  "title": "Luna: Generate Tests for File" },

      // --- Scaffolding ---
      { "command": "luna.scaffold.project", "title": "Luna: New Project from Template" },
      { "command": "luna.scaffold.file",    "title": "Luna: New File from Template" },

      // --- Packaging ---
      { "command": "luna.package.zip",     "title": "Luna: Package Game (.zip)" },
      { "command": "luna.package.windows", "title": "Luna: Package for Windows" },
      { "command": "luna.package.linux",   "title": "Luna: Package for Linux" },

      // --- Editors ---
      { "command": "luna.editor.tileMap",          "title": "Luna: Tile Map Editor" },
      { "command": "luna.editor.sceneFlow",        "title": "Luna: Scene Flow Editor" },
      { "command": "luna.editor.entity",           "title": "Luna: Entity Designer" },
      { "command": "luna.editor.pixelArt",         "title": "Luna: Pixel Art Editor" },
      { "command": "luna.editor.dialog",           "title": "Luna: Dialog Editor" },
      { "command": "luna.editor.particle",         "title": "Luna: Particle Designer" },
      { "command": "luna.editor.database",         "title": "Luna: Database Browser" },
      { "command": "luna.editor.procMap",          "title": "Luna: Procedural Map Generator" },
      { "command": "luna.editor.questTree",        "title": "Luna: Quest / Tech Tree Editor" },
      { "command": "luna.editor.guiWidget",        "title": "Luna: GUI Widget Editor" },
      { "command": "luna.editor.aiBehavior",       "title": "Luna: AI Behavior Tree" },
      { "command": "luna.editor.graph",            "title": "Luna: Graph / Node Editor" },
      { "command": "luna.editor.tilemapScript",    "title": "Luna: Tilemap Script Editor" },
      { "command": "luna.editor.voxel",            "title": "Luna: Voxel Editor" },
      { "command": "luna.editor.testRunner",       "title": "Luna: Test Runner" },
      { "command": "luna.editor.apiReference",     "title": "Luna: API Reference" },

      // --- Reference ---
      { "command": "luna.browseApi",     "title": "Luna: Browse API (Quick Pick)" },
      { "command": "luna.openApiDocs",   "title": "Luna: Open Lua API Docs" },
      { "command": "luna.openWiki",      "title": "Luna: Open Wiki" },
      { "command": "luna.depGraph",      "title": "Luna: Dependency Graph" },
      { "command": "luna.depList",       "title": "Luna: Dependency List" },

      // --- Debug Bridge ---
      { "command": "luna.debug.connect",       "title": "Luna: Debug Connect" },
      { "command": "luna.debug.disconnect",    "title": "Luna: Debug Disconnect" },
      { "command": "luna.debug.runAndConnect", "title": "Luna: Debug Run + Connect" },
      { "command": "luna.debug.performance",   "title": "Luna: Debug Performance" },
      { "command": "luna.debug.printHistory",  "title": "Luna: Debug Print History" },
      { "command": "luna.debug.evaluate",      "title": "Luna: Debug Evaluate Lua" },
      { "command": "luna.debug.screenshot",    "title": "Luna: Debug Screenshot" },
      { "command": "luna.debug.callStack",     "title": "Luna: Debug Call Stack" },
      { "command": "luna.debug.status",        "title": "Luna: Debug Status" },

      // --- AI & CAG ---
      { "command": "luna.cag.install",       "title": "Luna: Install AI Config" },
      { "command": "luna.cag.selectAgent",   "title": "Luna: Select Agent" },
      { "command": "luna.cag.selectSkill",   "title": "Luna: Select Skill" },
      { "command": "luna.cag.selectPrompt",  "title": "Luna: Select Prompt" },
      { "command": "luna.cag.update",        "title": "Luna: Update CAG Files" },
      { "command": "luna.mcp.install",       "title": "Luna: Install MCP Server" },
      { "command": "luna.mcp.status",        "title": "Luna: MCP Status" },

      // --- Game Jam ---
      { "command": "luna.jam.timer",      "title": "Luna: Game Jam Timer" },
      { "command": "luna.jam.quickBuild", "title": "Luna: Quick Build" },
      { "command": "luna.jam.checklist",  "title": "Luna: Submission Checklist" },

      // --- Libraries ---
      { "command": "luna.library.install", "title": "Luna: Install Library" },
      { "command": "luna.library.list",    "title": "Luna: List Libraries" },

      // --- Analysis ---
      { "command": "luna.apiCoverage", "title": "Luna: API Coverage Report" }
    ],

    // ─── KEYBINDINGS ─────────────────────────────────────────────

    "keybindings": [
      {
        "command": "luna.runGame",
        "key": "alt+l",
        "when": "editorTextFocus && resourceLangId == lua"
      },
      {
        "command": "luna.stopGame",
        "key": "shift+alt+l",
        "when": "luna.gameRunning"
      },
      {
        "command": "luna.openWiki",
        "key": "f2",
        "when": "editorTextFocus && resourceLangId == lua"
      },
      {
        "command": "luna.test.all",
        "key": "ctrl+shift+t",
        "when": "workspaceFolderCount > 0"
      }
    ],

    // ─── MENUS ───────────────────────────────────────────────────

    "menus": {
      "editor/context": [
        {
          "command": "luna.runGame",
          "when": "resourceLangId == lua",
          "group": "luna@1"
        },
        {
          "command": "luna.openWiki",
          "when": "resourceLangId == lua",
          "group": "luna@2"
        },
        {
          "command": "luna.test.generateForFile",
          "when": "resourceLangId == lua",
          "group": "luna@3"
        }
      ],
      "explorer/context": [
        {
          "command": "luna.runGame",
          "when": "explorerResourceIsFolder",
          "group": "luna@1"
        }
      ]
    },

    // ─── CUSTOM EDITORS ──────────────────────────────────────────

    "customEditors": [
      {
        "viewType": "luna.sceneLuaEditor",
        "displayName": "Luna Scene Editor",
        "selector": [
          { "filenamePattern": "*.scene.lua" }
        ],
        "priority": "default"
      }
    ],

    // ─── SNIPPETS ────────────────────────────────────────────────

    "snippets": [
      {
        "language": "lua",
        "path": "./data/snippets.json"
      }
    ],

    // ─── CONFIGURATION ──────────────────────────────────────────

    "configuration": {
      "title": "Luna Toolkit",
      "properties": {
        "luna.lunaPath": {
          "type": "string",
          "default": "",
          "description": "Path to luna2d executable"
        },
        "luna.srcDir": {
          "type": "string",
          "default": "",
          "description": "Game source subdirectory"
        },
        "luna.saveOnRun": {
          "type": "boolean",
          "default": true,
          "description": "Save files before running"
        },
        "luna.diagnostics.deprecationWarnings": {
          "type": "boolean",
          "default": true,
          "description": "Show deprecated API warnings"
        },
        "luna.diagnostics.commonMistakes": {
          "type": "boolean",
          "default": true,
          "description": "Detect common Luna2D mistakes"
        },
        "luna.diagnostics.unusedRequires": {
          "type": "boolean",
          "default": true,
          "description": "Flag unused require statements"
        },
        "luna.diagnostics.assetValidation": {
          "type": "boolean",
          "default": true,
          "description": "Validate asset file paths"
        },
        "luna.inlayHints.parameterNames": {
          "type": "boolean",
          "default": true,
          "description": "Show parameter name hints"
        },
        "luna.test.testDir": {
          "type": "string",
          "default": "tests",
          "description": "Test directory path"
        },
        "luna.test.luaTestDir": {
          "type": "string",
          "default": "tests/lua",
          "description": "Lua test directory"
        },
        "luna.cag.installOnScaffold": {
          "type": "boolean",
          "default": true,
          "description": "Auto-install AI config on scaffold"
        },
        "luna.package.outputDir": {
          "type": "string",
          "default": "dist",
          "description": "Build output directory"
        },
        "luna.debugBridge.port": {
          "type": "number",
          "default": 19740,
          "minimum": 1024,
          "maximum": 65535,
          "description": "Debug bridge TCP port"
        },
        "luna.debugBridge.autoConnect": {
          "type": "boolean",
          "default": true,
          "description": "Auto-connect on debug run"
        }
      }
    },

    // ─── LANGUAGES ───────────────────────────────────────────────

    "languages": [
      {
        "id": "lua",
        "aliases": ["Lua"],
        "extensions": [".lua"],
        "configuration": "./language-configuration.json"
      }
    ]
  },

  // ─── SCRIPTS ─────────────────────────────────────────────────

  "scripts": {
    "vscode:prepublish": "npm run build",
    "build": "node esbuild.config.mjs --production",
    "watch": "node esbuild.config.mjs --watch",
    "test": "node ./dist/test/runTest.js",
    "lint": "eslint src --ext ts",
    "generate-api": "npx tsx tools/generate-api-data.ts",
    "generate-snippets": "npx tsx tools/generate-snippets.ts",
    "generate-luacats": "npx tsx tools/generate-luacats.ts",
    "generate-all": "npm run generate-api && npm run generate-snippets && npm run generate-luacats",
    "package": "npx @vscode/vsce package --no-dependencies --allow-missing-repository"
  },

  // ─── DEPENDENCIES ────────────────────────────────────────────

  "devDependencies": {
    "@types/vscode": "^1.90.0",
    "@types/node": "^20.0.0",
    "typescript": "^5.4.0",
    "esbuild": "^0.21.0",
    "@vscode/vsce": "^2.26.0",
    "@vscode/test-electron": "^2.4.0",
    "tsx": "^4.0.0",
    "eslint": "^9.0.0",
    "@typescript-eslint/eslint-plugin": "^7.0.0",
    "@typescript-eslint/parser": "^7.0.0"
  },

  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  }
}
```

---

## Notes

1. **Command count**: 76 commands total
2. **Views**: 3 sidebar views in 1 container
3. **Settings**: 14 configuration properties
4. **Keybindings**: 4 default bindings
5. **Custom editors**: 1 (`.scene.lua`)
6. **Snippets**: 1 language contribution (Lua)
7. **Menus**: Editor context + explorer context
