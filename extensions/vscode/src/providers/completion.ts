import * as vscode from "vscode";
import { ApiDataService, ApiFunction } from "../services/apiData.js";
import { LuaDocumentAnalyzer, LuaDocumentInfo } from "../services/luaParser.js";

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: "file", language: "lua" };
const analyzer = new LuaDocumentAnalyzer();

// ── Document analysis cache ──────────────────────────────────

interface CachedAnalysis {
  version: number;
  info: LuaDocumentInfo;
}

const analysisCache = new Map<string, CachedAnalysis>();

function getCachedAnalysis(document: vscode.TextDocument): LuaDocumentInfo {
  const key = document.uri.toString();
  const cached = analysisCache.get(key);
  if (cached && cached.version === document.version) return cached.info;
  const info = analyzer.analyze(document.getText());
  analysisCache.set(key, { version: document.version, info });
  return info;
}

// ── Lua builtin globals ──────────────────────────────────────

interface BuiltinGlobal {
  label: string;
  kind: vscode.CompletionItemKind;
  detail: string;
  doc: string;
  snippet?: string;
}

const LUA_BUILTINS: BuiltinGlobal[] = [
  { label: "print", kind: vscode.CompletionItemKind.Function, detail: "print(...)", doc: "Receives any number of arguments and prints their values to stdout.", snippet: "print(${1:value})" },
  { label: "require", kind: vscode.CompletionItemKind.Function, detail: "require(modname)", doc: "Loads the given module, returns the value stored in `package.loaded[modname]`.", snippet: 'require("${1:module}")' },
  { label: "type", kind: vscode.CompletionItemKind.Function, detail: "type(v) → string", doc: "Returns the type of its argument as a string.", snippet: "type(${1:value})" },
  { label: "tostring", kind: vscode.CompletionItemKind.Function, detail: "tostring(v) → string", doc: "Converts any value to a string in a reasonable format.", snippet: "tostring(${1:value})" },
  { label: "tonumber", kind: vscode.CompletionItemKind.Function, detail: "tonumber(e [, base]) → number|nil", doc: "Tries to convert its argument to a number.", snippet: "tonumber(${1:value})" },
  { label: "pairs", kind: vscode.CompletionItemKind.Function, detail: "pairs(t) → iterator", doc: "Returns an iterator function for all key-value pairs in table t.", snippet: "pairs(${1:table})" },
  { label: "ipairs", kind: vscode.CompletionItemKind.Function, detail: "ipairs(t) → iterator", doc: "Returns an iterator function for the integer keys 1, 2, ... in table t.", snippet: "ipairs(${1:table})" },
  { label: "next", kind: vscode.CompletionItemKind.Function, detail: "next(table [, index]) → key, value", doc: "Returns the next key-value pair after index in the table.", snippet: "next(${1:table})" },
  { label: "select", kind: vscode.CompletionItemKind.Function, detail: "select(index, ...)", doc: 'Returns all arguments after argument number index, or the total number with "#".', snippet: "select(${1:index})" },
  { label: "unpack", kind: vscode.CompletionItemKind.Function, detail: "unpack(list [, i [, j]])", doc: "Returns the elements from the given list.", snippet: "unpack(${1:list})" },
  { label: "setmetatable", kind: vscode.CompletionItemKind.Function, detail: "setmetatable(table, metatable) → table", doc: "Sets the metatable for the given table.", snippet: "setmetatable(${1:table}, ${2:metatable})" },
  { label: "getmetatable", kind: vscode.CompletionItemKind.Function, detail: "getmetatable(object) → table|nil", doc: "Returns the metatable of the given object, if it has one.", snippet: "getmetatable(${1:object})" },
  { label: "rawset", kind: vscode.CompletionItemKind.Function, detail: "rawset(table, index, value) → table", doc: "Sets the value of table[index] without invoking metamethods.", snippet: "rawset(${1:table}, ${2:index}, ${3:value})" },
  { label: "rawget", kind: vscode.CompletionItemKind.Function, detail: "rawget(table, index) → value", doc: "Gets the value of table[index] without invoking metamethods.", snippet: "rawget(${1:table}, ${2:index})" },
  { label: "rawequal", kind: vscode.CompletionItemKind.Function, detail: "rawequal(v1, v2) → boolean", doc: "Checks equality without invoking __eq metamethod.", snippet: "rawequal(${1:v1}, ${2:v2})" },
  { label: "rawlen", kind: vscode.CompletionItemKind.Function, detail: "rawlen(v) → number", doc: "Returns the length without invoking __len metamethod.", snippet: "rawlen(${1:v})" },
  { label: "error", kind: vscode.CompletionItemKind.Function, detail: "error(message [, level])", doc: "Terminates the last protected function called and returns message as the error object.", snippet: "error(${1:message})" },
  { label: "pcall", kind: vscode.CompletionItemKind.Function, detail: "pcall(f, ...) → ok, result...", doc: "Calls function f in protected mode. Returns status and results.", snippet: "pcall(${1:func})" },
  { label: "xpcall", kind: vscode.CompletionItemKind.Function, detail: "xpcall(f, msgh, ...) → ok, result...", doc: "Calls function f in protected mode with message handler msgh.", snippet: "xpcall(${1:func}, ${2:handler})" },
  { label: "assert", kind: vscode.CompletionItemKind.Function, detail: "assert(v [, message])", doc: "Calls error if the value of v is false or nil.", snippet: "assert(${1:value})" },
  { label: "dofile", kind: vscode.CompletionItemKind.Function, detail: "dofile(filename)", doc: "Opens the named file and executes its contents as a Lua chunk.", snippet: 'dofile("${1:filename}")' },
  { label: "loadfile", kind: vscode.CompletionItemKind.Function, detail: "loadfile(filename) → function|nil, err", doc: "Loads a chunk from a file without executing it.", snippet: 'loadfile("${1:filename}")' },
  { label: "load", kind: vscode.CompletionItemKind.Function, detail: "load(chunk [, chunkname]) → function|nil, err", doc: "Loads a chunk from a string or function.", snippet: "load(${1:chunk})" },
  { label: "loadstring", kind: vscode.CompletionItemKind.Function, detail: "loadstring(s) → function|nil, err", doc: "Loads a chunk from a string (LuaJIT/Lua 5.1 compat).", snippet: "loadstring(${1:code})" },
  { label: "collectgarbage", kind: vscode.CompletionItemKind.Function, detail: "collectgarbage(opt [, arg])", doc: "Interface to the garbage collector.", snippet: 'collectgarbage("${1:collect}")' },
];

const LUA_STDLIB_MODULES: { label: string; detail: string }[] = [
  { label: "string", detail: "String manipulation library" },
  { label: "table", detail: "Table manipulation library" },
  { label: "math", detail: "Math library" },
  { label: "os", detail: "Operating system facilities" },
  { label: "io", detail: "I/O library" },
  { label: "coroutine", detail: "Coroutine library" },
  { label: "debug", detail: "Debug library" },
  { label: "package", detail: "Package library" },
];

// ── Key names for input functions ────────────────────────────

const KEY_NAMES = [
  "space", "return", "escape", "up", "down", "left", "right",
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
  "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
  "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
  "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt",
  "tab", "backspace", "delete", "insert", "home", "end", "pageup", "pagedown",
];

// ── String context completion rules ──────────────────────────

interface StringContextRule {
  pattern: RegExp;
  values: { label: string; detail?: string }[];
}

const STRING_CONTEXT_RULES: StringContextRule[] = [
  {
    pattern: /lurek\.input\.(?:isDown|isUp)\s*\(\s*["']$/,
    values: KEY_NAMES.map(k => ({ label: k, detail: "Key name" })),
  },
  {
    pattern: /lurek\.graphics\.setBlendMode\s*\(\s*["']$/,
    values: [
      { label: "alpha", detail: "Standard alpha blending" },
      { label: "add", detail: "Additive blending" },
      { label: "subtract", detail: "Subtractive blending" },
      { label: "multiply", detail: "Multiply blending" },
      { label: "premultiplied", detail: "Pre-multiplied alpha" },
      { label: "replace", detail: "Replace pixels (no blending)" },
      { label: "screen", detail: "Screen blending" },
      { label: "darken", detail: "Darken blending" },
      { label: "lighten", detail: "Lighten blending" },
    ],
  },
  {
    pattern: /lurek\.graphics\.setLineCap\s*\(\s*["']$/,
    values: [
      { label: "none", detail: "No line cap" },
      { label: "butt", detail: "Flat cap (default)" },
      { label: "square", detail: "Square cap extends past endpoint" },
      { label: "round", detail: "Rounded cap" },
    ],
  },
  {
    pattern: /lurek\.graphics\.setLineJoin\s*\(\s*["']$/,
    values: [
      { label: "miter", detail: "Sharp join (default)" },
      { label: "bevel", detail: "Flat corner join" },
      { label: "none", detail: "No join" },
    ],
  },
  {
    pattern: /lurek\.physics\.newBody\s*\([^)]*,\s*["']$/,
    values: [
      { label: "static", detail: "Immovable body" },
      { label: "dynamic", detail: "Fully simulated body" },
      { label: "kinematic", detail: "Moved by code, not forces" },
    ],
  },
  {
    pattern: /lurek\.audio\.newSource\s*\([^)]*,\s*["']$/,
    values: [
      { label: "static", detail: "Load entirely into memory" },
      { label: "stream", detail: "Stream from disk" },
    ],
  },
  {
    pattern: /:setFilter\s*\(\s*["']$/,
    values: [
      { label: "nearest", detail: "Pixel-perfect (no filtering)" },
      { label: "linear", detail: "Smooth bilinear filtering" },
    ],
  },
  {
    pattern: /:setWrap\s*\(\s*["']$/,
    values: [
      { label: "clamp", detail: "Clamp to edge" },
      { label: "clampzero", detail: "Clamp to transparent" },
      { label: "repeat", detail: "Tile texture" },
      { label: "mirroredrepeat", detail: "Tile with mirroring" },
    ],
  },
  {
    pattern: /lurek\.graphics\.setDefaultFilter\s*\(\s*["']$/,
    values: [
      { label: "nearest", detail: "Pixel-perfect (no filtering)" },
      { label: "linear", detail: "Smooth bilinear filtering" },
    ],
  },
  {
    pattern: /lurek\.graphics\.setLineStyle\s*\(\s*["']$/,
    values: [
      { label: "rough", detail: "Aliased line" },
      { label: "smooth", detail: "Anti-aliased line" },
    ],
  },
  {
    pattern: /lurek\.graphics\.(?:rectangle|circle|polygon|ellipse|arc)\s*\(\s*["']$/,
    values: [
      { label: "fill", detail: "Filled shape" },
      { label: "line", detail: "Outlined shape" },
    ],
  },
  {
    pattern: /(?:easing|ease|tween)\s*[=:]\s*["']$|lurek\.tween\.\w+\s*\([^)]*["']$/i,
    values: [
      { label: "linear", detail: "Constant speed" },
      { label: "inQuad", detail: "Accelerating (quadratic)" },
      { label: "outQuad", detail: "Decelerating (quadratic)" },
      { label: "inOutQuad", detail: "Accel then decel (quadratic)" },
      { label: "inCubic", detail: "Accelerating (cubic)" },
      { label: "outCubic", detail: "Decelerating (cubic)" },
      { label: "inOutCubic", detail: "Accel then decel (cubic)" },
      { label: "inQuart", detail: "Accelerating (quartic)" },
      { label: "outQuart", detail: "Decelerating (quartic)" },
      { label: "inQuint", detail: "Accelerating (quintic)" },
      { label: "outQuint", detail: "Decelerating (quintic)" },
      { label: "inSine", detail: "Sine wave acceleration" },
      { label: "outSine", detail: "Sine wave deceleration" },
      { label: "inOutSine", detail: "Sine wave accel/decel" },
      { label: "inExpo", detail: "Exponential acceleration" },
      { label: "outExpo", detail: "Exponential deceleration" },
      { label: "inCirc", detail: "Circular acceleration" },
      { label: "outCirc", detail: "Circular deceleration" },
      { label: "inBack", detail: "Overshoot on start" },
      { label: "outBack", detail: "Overshoot on end" },
      { label: "inBounce", detail: "Bounce on start" },
      { label: "outBounce", detail: "Bounce on end" },
      { label: "inElastic", detail: "Elastic spring start" },
      { label: "outElastic", detail: "Elastic spring end" },
    ],
  },
  // ── I1 additions ────────────────────────────────────────────
  {
    // lurek.render.printf 5th arg: alignment
    pattern: /lurek\.render\.printf\s*\([^)]*,[^)]*,[^)]*,[^)]*,\s*["']$/,
    values: [
      { label: "left", detail: "Left-aligned text" },
      { label: "center", detail: "Center-aligned text" },
      { label: "right", detail: "Right-aligned text" },
      { label: "justify", detail: "Justified text" },
    ],
  },
  {
    // lurek.render.setStencilTest mode
    pattern: /lurek\.render\.(?:setStencilTest|stencil)\s*\([^)]*["']$/,
    values: [
      { label: "greater", detail: "Draw where stencil > value" },
      { label: "greaterequal", detail: "Draw where stencil >= value" },
      { label: "less", detail: "Draw where stencil < value" },
      { label: "lessequal", detail: "Draw where stencil <= value" },
      { label: "equal", detail: "Draw where stencil == value" },
      { label: "notequal", detail: "Draw where stencil != value" },
      { label: "always", detail: "Always draw" },
      { label: "never", detail: "Never draw" },
    ],
  },
  {
    // lurek.input.getAxis / isGamepadDown axis name
    pattern: /lurek\.input\.(?:getAxis|isGamepadAxis)\s*\([^)]*,\s*["']$/,
    values: [
      { label: "leftx", detail: "Left stick X axis" },
      { label: "lefty", detail: "Left stick Y axis" },
      { label: "rightx", detail: "Right stick X axis" },
      { label: "righty", detail: "Right stick Y axis" },
      { label: "triggerleft", detail: "Left trigger" },
      { label: "triggerright", detail: "Right trigger" },
    ],
  },
  {
    // Gamepad button names
    pattern: /lurek\.input\.(?:isGamepadDown|isGamepadUp|wasGamepadPressed)\s*\([^)]*,\s*["']$/,
    values: [
      { label: "a", detail: "A button (Cross on PS)" },
      { label: "b", detail: "B button (Circle on PS)" },
      { label: "x", detail: "X button (Square on PS)" },
      { label: "y", detail: "Y button (Triangle on PS)" },
      { label: "back", detail: "Back / Select" },
      { label: "start", detail: "Start / Options" },
      { label: "leftshoulder", detail: "Left bumper (LB/L1)" },
      { label: "rightshoulder", detail: "Right bumper (RB/R1)" },
      { label: "lefttrigger", detail: "Left trigger (LT/L2)" },
      { label: "righttrigger", detail: "Right trigger (RT/R2)" },
      { label: "leftstick", detail: "Left stick click (LS/L3)" },
      { label: "rightstick", detail: "Right stick click (RS/R3)" },
      { label: "dpup", detail: "D-pad up" },
      { label: "dpdown", detail: "D-pad down" },
      { label: "dpleft", detail: "D-pad left" },
      { label: "dpright", detail: "D-pad right" },
      { label: "guide", detail: "Guide / Home button" },
    ],
  },
  {
    // lurek.render.setArcType / arc type
    pattern: /lurek\.render\.arc\s*\(\s*["']$/,
    values: [
      { label: "pie", detail: "Pie-slice arc" },
      { label: "open", detail: "Open arc (lines to centre not drawn)" },
      { label: "closed", detail: "Arc with closing chord" },
    ],
  },
  {
    // lurek.audio setEffect type
    pattern: /lurek\.audio\.(?:setEffect|newEffect)\s*\([^)]*,\s*["']$/,
    values: [
      { label: "reverb", detail: "Reverb / room effect" },
      { label: "delay", detail: "Echo delay" },
      { label: "chorus", detail: "Chorus doubling effect" },
      { label: "distortion", detail: "Distortion" },
      { label: "echo", detail: "Echo" },
      { label: "flanger", detail: "Flanger" },
      { label: "ringmodulator", detail: "Ring modulator" },
      { label: "equalizer", detail: "EQ / equalizer" },
      { label: "bandpass", detail: "Band-pass filter" },
      { label: "lowpass", detail: "Low-pass filter" },
      { label: "highpass", detail: "High-pass filter" },
    ],
  },
];

// ── Constructor → object type mapping ────────────────────────

const CONSTRUCTOR_RETURN_TYPES: Record<string, string> = {
  // lurek.render.* is the current API namespace
  "lurek.render.newImage": "Image",
  "lurek.render.newCanvas": "Canvas",
  "lurek.render.newFont": "Font",
  "lurek.render.newShader": "Shader",
  "lurek.render.newQuad": "Quad",
  "lurek.render.newMesh": "Mesh",
  "lurek.render.newSpriteBatch": "SpriteBatch",
  "lurek.render.newParticleSystem": "ParticleSystem",
  "lurek.render.newImageData": "ImageData",
  "lurek.audio.newSource": "Source",
  "lurek.physics.newWorld": "World",
  "lurek.physics.newBody": "Body",
  "lurek.physics.newFixture": "Fixture",
  "lurek.physics.newRectangleShape": "Shape",
  "lurek.physics.newCircleShape": "Shape",
  "lurek.physics.newPolygonShape": "Shape",
  "lurek.physics.newEdgeShape": "Shape",
  "lurek.physics.newChainShape": "Shape",
  "lurek.physics.newDistanceJoint": "Joint",
  "lurek.physics.newRevoluteJoint": "Joint",
  "lurek.physics.newPrismaticJoint": "Joint",
  "lurek.physics.newWeldJoint": "Joint",
  "lurek.thread.newChannel": "Channel",
  "lurek.thread.newThread": "Thread",
};

// ── Frequently used functions (sort boost) ───────────────────

const FREQUENT_FUNCTIONS = new Set([
  "draw", "setColor", "rectangle", "circle", "print", "line",
  "clear", "push", "pop", "translate", "rotate", "scale",
  "newImage", "newFont", "newCanvas", "getWidth", "getHeight",
  "isDown", "getMousePosition",
  "newWorld", "newBody",
  "newSource", "play", "stop",
  "getTime", "getDelta", "getFPS",
  "random", "lerp", "clamp",
  "read", "write", "exists",
]);

// ── Helpers ──────────────────────────────────────────────────

function buildFunctionDoc(fn: ApiFunction): vscode.MarkdownString {
  const md = new vscode.MarkdownString();
  md.appendCodeblock(fn.signature, "lua");
  if (fn.description) md.appendMarkdown("\n" + fn.description + "\n");
  if (fn.parameters.length > 0) {
    md.appendMarkdown("\n**Parameters:**\n");
    for (const p of fn.parameters) {
      const opt = p.optional ? " *(optional)*" : "";
      const def = p.default ? ` — default: \`${p.default}\`` : "";
      const desc = p.description ? ` — ${p.description}` : "";
      md.appendMarkdown(`- \`${p.name}\`: *${p.type}*${opt}${desc}${def}\n`);
    }
  }
  if (fn.returns) md.appendMarkdown(`\n**Returns:** ${fn.returns}\n`);
  if (fn.since) md.appendMarkdown(`\n*Since ${fn.since}*`);
  if (fn.deprecated) md.appendMarkdown(`\n\n⚠️ **Deprecated:** ${fn.deprecated}`);
  md.isTrusted = true;
  return md;
}

function buildSnippet(fn: ApiFunction): string {
  if (fn.parameters.length === 0) return fn.name + "()";
  const required = fn.parameters.filter(p => !p.optional);
  if (required.length === 0) return fn.name + "(${1})";
  const params = required.map((p, i) => `\${${i + 1}:${p.name}}`).join(", ");
  return `${fn.name}(${params})`;
}

function buildStdlibSnippet(fn: ApiFunction): string {
  const isConst = fn.parameters.length === 0 && !fn.signature.includes("(");
  if (isConst) return fn.name;
  const required = fn.parameters.filter(p => !p.optional && p.name !== "...");
  if (required.length === 0) return fn.name + "(${1})";
  const params = required.map((p, i) => `\${${i + 1}:${p.name}}`).join(", ");
  return `${fn.name}(${params})`;
}

function sortPriority(fn: ApiFunction): string {
  if (FREQUENT_FUNCTIONS.has(fn.name)) return "0" + fn.name;
  if (fn.deprecated) return "2" + fn.name;
  return "1" + fn.name;
}

function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function inferObjectType(
  document: vscode.TextDocument,
  position: vscode.Position,
  objName: string,
  apiData: ApiDataService,
): string | undefined {
  const lines = document.getText().split("\n");
  for (let lineIdx = position.line; lineIdx >= 0; lineIdx--) {
    const assignMatch = lines[lineIdx].match(
      new RegExp(`(?:local\\s+)?${escapeRegex(objName)}\\s*=\\s*(lurek\\.[\\w.]+)\\s*\\(`),
    );
    if (assignMatch) {
      const constructorPath = assignMatch[1];
      const objType = CONSTRUCTOR_RETURN_TYPES[constructorPath];
      if (objType) return objType;
      const fn = apiData.getFunction(constructorPath);
      if (fn?.returnType) {
        const methods = apiData.getMethods(fn.returnType);
        if (methods.length > 0) return fn.returnType;
      }
    }
  }
  // Check if the name itself is a known object type
  const capitalName = objName.charAt(0).toUpperCase() + objName.slice(1);
  if (apiData.getMethods(capitalName).length > 0) return capitalName;
  return undefined;
}

// ── Provider registration ────────────────────────────────────

export function register(
  context: vscode.ExtensionContext,
  apiData: ApiDataService,
): void {
  // ── Main completion provider (`.` and `:` triggers) ──

  const mainProvider = vscode.languages.registerCompletionItemProvider(
    LUA_SELECTOR,
    {
      provideCompletionItems(
        document: vscode.TextDocument,
        position: vscode.Position,
      ): vscode.CompletionItem[] | undefined {
        const lineText = document.lineAt(position).text;
        const before = lineText.substring(0, position.character);

        // Skip inside comments
        try {
          if (analyzer.isInsideComment(document.getText(), position.line, position.character)) {
            return undefined;
          }
        } catch { /* continue */ }

        // ── A: lurek.module.func — function completions ──
        const moduleFuncMatch = before.match(/lurek\.(\w+)\.(\w*)$/);
        if (moduleFuncMatch) {
          const modName = moduleFuncMatch[1];
          const partial = moduleFuncMatch[2].toLowerCase();
          const funcs = apiData.getFunctions(modName);
          if (funcs.length === 0) return undefined;

          return funcs
            .filter(fn => !partial || fn.name.toLowerCase().startsWith(partial))
            .sort((a, b) => sortPriority(a).localeCompare(sortPriority(b)))
            .map((fn, idx) => {
              const item = new vscode.CompletionItem(
                fn.name,
                fn.isMethod ? vscode.CompletionItemKind.Method : vscode.CompletionItemKind.Function,
              );
              item.detail = fn.signature;
              item.documentation = buildFunctionDoc(fn);
              item.insertText = new vscode.SnippetString(buildSnippet(fn));
              item.sortText = String(idx).padStart(4, "0");
              if (fn.deprecated) {
                item.tags = [vscode.CompletionItemTag.Deprecated];
              }
              return item;
            });
        }

        // ── A: lurek. — module name completions ──
        const moduleMatch = before.match(/lurek\.(\w*)$/);
        if (moduleMatch) {
          const partial = moduleMatch[1].toLowerCase();
          const items: vscode.CompletionItem[] = [];

          for (const modName of apiData.getModuleNames()) {
            if (partial && !modName.toLowerCase().startsWith(partial)) continue;
            const mod = apiData.getModule(modName);
            const item = new vscode.CompletionItem(modName, vscode.CompletionItemKind.Module);
            item.detail = `lurek.${modName}`;
            if (mod?.description) {
              item.documentation = new vscode.MarkdownString(mod.description);
            }
            item.sortText = "0" + modName;
            items.push(item);
          }

          // Callbacks under lurek.
          for (const cb of apiData.getCallbacks()) {
            if (partial && !cb.name.toLowerCase().startsWith(partial)) continue;
            const item = new vscode.CompletionItem(cb.name, vscode.CompletionItemKind.Event);
            item.detail = cb.signature;
            item.documentation = new vscode.MarkdownString(cb.description);
            item.sortText = "1" + cb.name;
            items.push(item);
          }

          return items;
        }

        // ── B/C: Lua stdlib — string. table. math. bit. jit. ffi. etc. ──
        const stdlibMatch = before.match(/\b(string|table|math|os|io|coroutine|debug|package|utf8|bit|jit|ffi)\.(\w*)$/);
        if (stdlibMatch) {
          const libName = stdlibMatch[1];
          const partial = stdlibMatch[2].toLowerCase();
          const stdlib = apiData.getLuaStdlib("luajit");
          const libFuncs = stdlib.filter(fn => fn.module === libName);
          if (libFuncs.length === 0) return undefined;

          return libFuncs
            .filter(fn => !partial || fn.name.toLowerCase().startsWith(partial))
            .map(fn => {
              const isConst = fn.parameters.length === 0 && !fn.signature.includes("(");
              const item = new vscode.CompletionItem(
                fn.name,
                isConst ? vscode.CompletionItemKind.Constant : vscode.CompletionItemKind.Function,
              );
              item.detail = fn.signature;
              item.documentation = buildFunctionDoc(fn);
              if (!isConst) {
                item.insertText = new vscode.SnippetString(buildStdlibSnippet(fn));
              }
              return item;
            });
        }

        // ── F: Method completions after `:` ──
        const colonMatch = before.match(/(\w+):(\w*)$/);
        if (colonMatch) {
          const objName = colonMatch[1];
          const partial = colonMatch[2].toLowerCase();
          const items: vscode.CompletionItem[] = [];

          const objectType = inferObjectType(document, position, objName, apiData);
          if (objectType) {
            for (const m of apiData.getMethods(objectType)) {
              if (partial && !m.name.toLowerCase().startsWith(partial)) continue;
              const item = new vscode.CompletionItem(m.name, vscode.CompletionItemKind.Method);
              item.detail = m.signature;
              item.documentation = buildFunctionDoc(m);
              item.insertText = new vscode.SnippetString(buildSnippet(m));
              if (m.deprecated) item.tags = [vscode.CompletionItemTag.Deprecated];
              items.push(item);
            }
          }

          // OOP class methods from document analysis
          try {
            const info = getCachedAnalysis(document);
            const classes = analyzer.detectClasses(info);
            const seenNames = new Set(items.map(i => typeof i.label === "string" ? i.label : ""));
            for (const cls of classes) {
              if (cls.name.toLowerCase() !== objName.toLowerCase() && cls.name !== objectType) continue;
              for (const method of cls.methods) {
                if (partial && !method.name.toLowerCase().startsWith(partial)) continue;
                if (seenNames.has(method.name)) continue;
                seenNames.add(method.name);
                const item = new vscode.CompletionItem(method.name, vscode.CompletionItemKind.Method);
                item.detail = `${cls.name}:${method.name}(${(method.parameters ?? []).join(", ")})`;
                if (method.description) {
                  item.documentation = new vscode.MarkdownString(method.description);
                }
                items.push(item);
              }
            }
          } catch { /* skip */ }

          if (items.length > 0) return items;
        }

        // ── D/E: Global + local completions ──
        if (/(?:^|[\s=(,{;])[\w]*$/.test(before) && !before.match(/\.\w*$/) && !before.match(/:\w*$/)) {
          const items: vscode.CompletionItem[] = [];

          // Lua builtins
          for (const g of LUA_BUILTINS) {
            const item = new vscode.CompletionItem(g.label, g.kind);
            item.detail = g.detail;
            item.documentation = new vscode.MarkdownString(g.doc);
            if (g.snippet) item.insertText = new vscode.SnippetString(g.snippet);
            item.sortText = "2" + g.label;
            items.push(item);
          }

          // Stdlib module names
          for (const mod of LUA_STDLIB_MODULES) {
            const item = new vscode.CompletionItem(mod.label, vscode.CompletionItemKind.Module);
            item.detail = mod.detail;
            item.sortText = "3" + mod.label;
            items.push(item);
          }

          // lurek namespace
          const lurekItem = new vscode.CompletionItem("lurek", vscode.CompletionItemKind.Module);
          lurekItem.detail = "Lurek2D engine API";
          lurekItem.sortText = "1lurek";
          items.push(lurekItem);

          // E: Local variables from document analysis
          try {
            const info = getCachedAnalysis(document);
            const locals = analyzer.getVisibleLocals(info, position.line);
            const seen = new Set(items.map(i => typeof i.label === "string" ? i.label : ""));

            for (const sym of locals) {
              if (seen.has(sym.name)) continue;
              seen.add(sym.name);
              const kind = sym.kind === "function"
                ? vscode.CompletionItemKind.Function
                : vscode.CompletionItemKind.Variable;
              const item = new vscode.CompletionItem(sym.name, kind);
              item.detail = sym.kind === "function"
                ? `local function ${sym.name}(${(sym.parameters ?? []).join(", ")})`
                : sym.kind === "parameter" ? "parameter" : `local ${sym.name}`;
              if (sym.description) {
                item.documentation = new vscode.MarkdownString(sym.description);
              }
              item.sortText = "0" + sym.name;
              items.push(item);
            }

            // Non-local symbols (globals, functions, tables)
            for (const sym of info.symbols) {
              if (sym.isLocal || sym.kind === "parameter") continue;
              if (seen.has(sym.name)) continue;
              seen.add(sym.name);
              const kind = sym.kind === "function" || sym.kind === "method"
                ? vscode.CompletionItemKind.Function
                : vscode.CompletionItemKind.Variable;
              const item = new vscode.CompletionItem(sym.name, kind);
              item.detail = sym.kind === "function"
                ? `function ${sym.name}(${(sym.parameters ?? []).join(", ")})`
                : sym.name;
              item.sortText = "1" + sym.name;
              items.push(item);
            }
          } catch { /* builtins still available */ }

          return items;
        }

        return undefined;
      },
    },
    ".",
    ":",
  );

  // ── G: String context completions (`, " triggers) ──

  const stringProvider = vscode.languages.registerCompletionItemProvider(
    LUA_SELECTOR,
    {
      provideCompletionItems(
        document: vscode.TextDocument,
        position: vscode.Position,
      ): vscode.CompletionItem[] | undefined {
        const before = document.lineAt(position).text.substring(0, position.character);
        for (const rule of STRING_CONTEXT_RULES) {
          if (rule.pattern.test(before)) {
            return rule.values.map(v => {
              const item = new vscode.CompletionItem(v.label, vscode.CompletionItemKind.EnumMember);
              if (v.detail) item.detail = v.detail;
              item.insertText = v.label;
              return item;
            });
          }
        }
        return undefined;
      },
    },
    "'",
    '"',
  );

  // ── H: Require path completions ──

  const requireProvider = vscode.languages.registerCompletionItemProvider(
    LUA_SELECTOR,
    {
      async provideCompletionItems(
        document: vscode.TextDocument,
        position: vscode.Position,
      ): Promise<vscode.CompletionItem[] | undefined> {
        const before = document.lineAt(position).text.substring(0, position.character);
        const requireMatch = before.match(/require\s*\(\s*["']([^"']*)$/);
        if (!requireMatch) return undefined;

        const partial = requireMatch[1];
        const items: vscode.CompletionItem[] = [];

        try {
          const luaFiles = await vscode.workspace.findFiles("**/*.lua", "{**/node_modules/**,ideas/**,work/**,.github/**}", 200);
          const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;

          for (const fileUri of luaFiles) {
            if (fileUri.fsPath === document.uri.fsPath) continue;

            let relativePath = "";
            if (wsRoot && fileUri.fsPath.startsWith(wsRoot)) {
              relativePath = fileUri.fsPath.substring(wsRoot.length + 1);
            } else {
              relativePath = vscode.workspace.asRelativePath(fileUri);
            }

            let modulePath = relativePath.replace(/\\/g, "/");
            if (modulePath.endsWith("/init.lua")) {
              modulePath = modulePath.slice(0, -"/init.lua".length);
            } else if (modulePath.endsWith(".lua")) {
              modulePath = modulePath.slice(0, -4);
            }
            const dotPath = modulePath.replace(/\//g, ".");

            if (partial && !dotPath.toLowerCase().startsWith(partial.toLowerCase())) continue;

            const item = new vscode.CompletionItem(dotPath, vscode.CompletionItemKind.File);
            item.detail = relativePath;
            item.insertText = dotPath;
            items.push(item);
          }
        } catch { /* skip */ }

        return items;
      },
    },
    "'",
    '"',
  );

  context.subscriptions.push(mainProvider, stringProvider, requireProvider);
}
