# Luna Toolkit — IntelliSense & Language Provider Design

> Defines how the extension provides Lua language intelligence
> powered by Luna2D's generated API documentation.

---

## 1. API Data Pipeline

### Source of Truth

The engine generates API docs via `tools/gen_lua_api.py`:
- **Input**: `///` doc comments in `src/lua_api/*.rs`
- **Output**: generated API metadata (structured, local build artifact) + `docs/lua_api_reference_generated.md` (human-readable)

Current coverage: **729 / 1523 functions** documented (48%).

### Build-Time Transformation

The extension includes build scripts that transform generated API metadata into VS Code-optimized formats:

```
generated API metadata
         │
         ├──► tools/generate-api-data.ts
         │         │
         │         ├─► data/api-completions.json
         │         │     Array of CompletionItem-ready objects:
         │         │     { label, kind, detail, documentation, insertText, sortText }
         │         │
         │         ├─► data/api-signatures.json
         │         │     Map<functionPath, SignatureInfo>:
         │         │     { label, parameters: [{label, documentation}], documentation }
         │         │
         │         ├─► data/api-hover.json
         │         │     Map<functionPath, MarkdownString>:
         │         │     Full documentation with signature, params, return type, example
         │         │
         │         └─► data/api-enums.json
         │               Map<enumName, string[]>:
         │               e.g. "BlendMode" → ["alpha", "add", "subtract", "multiply"]
         │
         ├──► tools/generate-snippets.ts
         │         │
         │         └─► data/snippets.json
         │               VS Code snippet format with prefixes and bodies
         │
         └──► tools/generate-luacats.ts
                   │
                   └─► data/luna2d.lua
                         LuaCATS annotation file for Lua Language Server integration
```

### Runtime Loading

```typescript
// services/apiData.ts

interface ApiFunction {
  module: string;          // "graphics"
  name: string;            // "draw"
  fullPath: string;        // "luna.graphics.draw"
  signature: string;       // "luna.graphics.draw(drawable, x, y, r, sx, sy, ox, oy)"
  description: string;     // "Draws a drawable object..."
  parameters: ApiParam[];  // [{name: "drawable", type: "Drawable", desc: "..."}]
  returns?: string;        // "number" or undefined
  since?: string;          // "0.1.0"
  deprecated?: string;     // reason string if deprecated
  isMethod: boolean;       // true for obj:method() calls
}

interface ApiParam {
  name: string;
  type: string;
  description: string;
  optional: boolean;
  default?: string;
}

class ApiDataService {
  private completions: vscode.CompletionItem[] = [];
  private signatures: Map<string, vscode.SignatureInformation[]> = new Map();
  private hoverDocs: Map<string, vscode.MarkdownString> = new Map();
  private enums: Map<string, string[]> = new Map();
  private functions: ApiFunction[] = [];

  async load(extensionPath: string): Promise<void> { ... }

  getCompletions(prefix: string): vscode.CompletionItem[] { ... }
  getSignature(funcPath: string): vscode.SignatureHelp | undefined { ... }
  getHover(symbol: string): vscode.Hover | undefined { ... }
  getEnumValues(enumName: string): string[] { ... }
  searchFunctions(query: string): ApiFunction[] { ... }
}
```

---

## 2. Provider Specifications

### 2.1 Completion Provider (`providers/completion.ts`)

**Trigger characters**: `.`, `:`

**Behavior**:
| User types | Completions offered |
|---|---|
| `luna.` | All top-level modules: `graphics`, `audio`, `physics`, `input`, ... |
| `luna.graphics.` | All functions in `luna.graphics`: `draw`, `rectangle`, `circle`, ... |
| `luna.graphics.new` | Filtered: `newImage`, `newCanvas`, `newFont`, `newShader`, ... |
| `sprite:` | Method completions for Drawable objects |
| `body:` | Method completions for physics Body objects |
| `world:` | Method completions for physics World objects |

**Implementation notes**:
- Parse left-of-cursor to determine completion context
- `luna.X` → module completions (CompletionItemKind.Module)
- `luna.X.Y` → function completions (CompletionItemKind.Function)
- `obj:Y` → method completions (CompletionItemKind.Method)
- Include `insertText` as snippet with parameter placeholders
- Sort by relevance (exact prefix match first)

### 2.2 Hover Provider (`providers/hover.ts`)

**Behavior**: When hovering over any `luna.*` function call, show:

```
luna.graphics.draw(drawable, x, y, r, sx, sy, ox, oy)

Draws a drawable object (Image, Canvas, etc.) at the specified position.

Parameters:
  • drawable — Drawable — The object to draw
  • x — number — X position (default: 0)
  • y — number — Y position (default: 0)
  • r — number — Rotation in radians (default: 0)
  • sx — number — Scale factor X (default: 1)
  • sy — number — Scale factor Y (default: sx)
  • ox — number — Origin offset X (default: 0)
  • oy — number — Origin offset Y (default: 0)

Returns: nil

Since: 0.1.0
```

### 2.3 Signature Help Provider (`providers/signature.ts`)

**Trigger characters**: `(`, `,`

**Behavior**: When inside a `luna.*` function call:
- Show the full signature with all parameters
- Highlight the current parameter (based on comma count)
- Show parameter documentation for the active parameter

### 2.4 Definition Provider (`providers/definition.ts`)

**Behavior**:
| Symbol | Goes to |
|---|---|
| `require("module")` | Resolved `module.lua` file |
| `luna.graphics.draw` | Generated API doc (virtual document) or source |
| Local function | Declaration site in current file |
| Local variable | Assignment site |

**Implementation**:
- Parse `require()` calls → resolve relative to workspace + `package.path`
- For `luna.*` → open API reference at the matching section
- For local symbols → simple text search in current document

### 2.5 References Provider (`providers/references.ts`)

**Behavior**: Find all references to a symbol across all `.lua` files in workspace.

**Implementation**:
- Workspace-wide `grep` for the symbol text
- Filter to `.lua` files only
- Return `Location[]` with file + position

### 2.6 Diagnostics Provider (`providers/diagnostics.ts`)

**Diagnostic rules**:

| Rule ID | Severity | Pattern | Message |
|---|---|---|---|
| `luna.deprecated` | Warning | `luna.X.deprecatedFunc()` | "luna.X.deprecatedFunc is deprecated. Use luna.X.newFunc instead." |
| `luna.colorRange` | Warning | `luna.graphics.setColor(255, ...)` | "Luna2D uses 0-1 color range, not 0-255. Did you mean 1.0?" |
| `luna.unusedRequire` | Hint | `local x = require(...)` unused | "Unused require: 'x' is never referenced" |
| `luna.assetNotFound` | Warning | `luna.graphics.newImage("missing.png")` | "Asset file not found: missing.png" |
| `luna.threadRandom` | Info | `math.random` in threaded code | "Consider luna.math.random for thread-safety" |
| `luna.missingCallback` | Info | No `luna.draw` defined | "No luna.draw() callback — nothing will be rendered" |

**Implementation**:
- Run on document save and document open
- Use regex + AST-light parsing (no full Lua parser needed for these rules)
- Cache results per document version

### 2.7 Document Symbol Provider (`providers/symbols.ts`)

**Behavior**: Provide outline view with:
- Functions (including nested)
- Luna2D callbacks (`luna.load`, `luna.update`, `luna.draw`, etc.)
- Local variables/tables
- `require()` imports

**Symbol kinds**:
| Pattern | Kind | Icon |
|---|---|---|
| `function X()` | Function | ƒ |
| `local function X()` | Function | ƒ |
| `luna.load = function` | Event | ⚡ |
| `luna.update = function` | Event | ⚡ |
| `local X = require()` | Module | 📦 |
| `local X = {}` | Object | {} |

### 2.8 Color Provider (`providers/color.ts`)

**Behavior**: Detect Luna2D color values (0.0–1.0 range) in:
- `luna.graphics.setColor(r, g, b, a)`
- `luna.graphics.setBackgroundColor(r, g, b)`
- Color table literals `{0.5, 0.3, 0.8, 1.0}`

Show inline color swatch. Clicking opens VS Code color picker.
Convert between 0–1 range when editing.

### 2.9 Asset Path Provider (`providers/assetPath.ts`)

**Trigger**: Inside string arguments to asset-loading functions:
- `luna.graphics.newImage("...")`
- `luna.audio.newSource("...")`
- `luna.filesystem.read("...")`

**Behavior**:
- Autocomplete file paths relative to game root
- Filter by expected file type (`.png/.jpg` for images, `.wav/.ogg/.mp3` for audio)
- Show warning diagnostic if file doesn't exist

### 2.10 Inlay Hints Provider (`providers/inlayHints.ts`)

**Behavior**: Show parameter names inline for `luna.*` calls:

```lua
luna.graphics.draw(sprite, 100, 200, 0, 2, 2)
--                        ↑x   ↑y  ↑r ↑sx ↑sy
```

Rendered as:
```
luna.graphics.draw(sprite, x:100, y:200, r:0, sx:2, sy:2)
```

### 2.11 Code Actions Provider (`providers/codeActions.ts`)

| Trigger | Action | Kind |
|---|---|---|
| Unused `require` | Remove unused `local x = require(...)` | `quickfix` |
| Missing callback | Generate `luna.load/update/draw` stubs | `quickfix` |
| 0-255 color value | Convert to 0-1 range | `quickfix` |
| Function selected | Extract to local function | `refactor.extract` |

---

## 3. LuaCATS Integration

### What is LuaCATS?

[LuaCATS](https://luals.github.io/wiki/annotations/) (Lua Comment And Type System) is an annotation standard used by the Lua Language Server (`sumneko.lua`). By generating annotation files, we get:

- Full type checking in Lua files
- Rich hover docs from the language server itself
- Go-to-definition for luna.* types
- Method resolution on typed variables

### Generated File: `data/luna2d.lua`

```lua
---@meta luna2d

---Luna2D game engine API
luna = {}

---Graphics module — drawing, images, shaders, canvas
luna.graphics = {}

---Draws a drawable object at the specified position.
---@param drawable Drawable The object to draw
---@param x? number X position (default: 0)
---@param y? number Y position (default: 0)
---@param r? number Rotation in radians (default: 0)
---@param sx? number Scale X (default: 1)
---@param sy? number Scale Y (default: sx)
---@param ox? number Origin X (default: 0)
---@param oy? number Origin Y (default: 0)
function luna.graphics.draw(drawable, x, y, r, sx, sy, ox, oy) end

---@class Drawable
---@field getWidth fun(self: Drawable): number
---@field getHeight fun(self: Drawable): number

---@class Image: Drawable
---@field getPixel fun(self: Image, x: number, y: number): number, number, number, number

-- ... thousands more annotations
```

### Dual IntelliSense Strategy

The extension provides IntelliSense through **two complementary systems**:

1. **Built-in providers** (`providers/completion.ts`, etc.)
   - Work without any other extension installed
   - Powered by pre-generated JSON API data
   - Fast, no external process

2. **LuaCATS annotations** (`data/luna2d.lua`)
   - Works with Lua Language Server (`sumneko.lua`)
   - Provides type checking, not just completion
   - Users who have `sumneko.lua` installed get enhanced experience
   - Extension auto-configures `Lua.workspace.library` to include annotation path

**No conflict**: Built-in providers are registered with lower priority. If `sumneko.lua` is active, it takes precedence for hover/completion; the built-in providers handle Luna2D-specific features (color, asset paths, diagnostics).

---

## 4. Snippets

### Categories

| Category | Count (est.) | Examples |
|---|---|---|
| Callbacks | 8 | `luna.load`, `luna.update`, `luna.draw`, `luna.keypressed` |
| Graphics | ~50 | `rect`, `circle`, `line`, `setColor`, `newImage`, `draw` |
| Physics | ~30 | `newWorld`, `newBody`, `addFixture`, `setGravity` |
| Audio | ~20 | `newSource`, `play`, `stop`, `setVolume` |
| Input | ~15 | `isDown`, `getPosition`, `getAxis` |
| Math | ~15 | `vec2`, `lerp`, `clamp`, `random` |
| Patterns | ~20 | `gameloop`, `statemachine`, `entityclass`, `timer` |
| Complete games | 5 | `pong`, `breakout`, `platformer`, `asteroids`, `snake` |

### Snippet Format

```json
{
  "Luna2D: Game Loop": {
    "prefix": "luna.gameloop",
    "body": [
      "function luna.load()",
      "\t${1:-- Initialize game state}",
      "end",
      "",
      "function luna.update(dt)",
      "\t${2:-- Update game logic}",
      "end",
      "",
      "function luna.draw()",
      "\t${3:-- Draw game}",
      "end"
    ],
    "description": "Complete Luna2D game loop with load, update, and draw callbacks"
  }
}
```

---

## 5. Diagnostics Deep Dive

### Color Range Detection

```lua
-- WARN: Luna2D uses 0-1 color range
luna.graphics.setColor(255, 128, 0)         -- ⚠ all three > 1.0
luna.graphics.setColor(1, 0.5, 0)           -- ✓ valid 0-1 range
luna.graphics.setColor(1, 1, 1, 255)        -- ⚠ alpha > 1.0

-- Detection heuristic:
-- If ANY numeric argument > 1.0, flag as potential 0-255 mistake
-- Exception: if all values are exactly 0 or 1, it's valid
```

### Asset Validation

```lua
-- Check file existence relative to game root
local img = luna.graphics.newImage("player.png")     -- ✓ if player.png exists
local snd = luna.audio.newSource("music.ogg")        -- ⚠ if music.ogg missing

-- Don't warn for:
-- - Dynamic paths (variables, concatenation)
-- - Paths containing wildcards
-- - Files in require() (handled differently)
```

### Unused Require Detection

```lua
local json = require("lib.json")    -- If 'json' never used below → hint
local bump = require("lib.bump")    -- Used in code → no warning

-- Quick fix: remove the unused line
-- Code action: "Remove unused require 'json'"
```
