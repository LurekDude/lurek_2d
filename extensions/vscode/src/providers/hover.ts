import * as vscode from "vscode";
import { ApiDataService, ApiFunction } from "../services/apiData.js";
// LuaDocumentAnalyzer removed — local-symbol hover is now handled by sumneko.lua

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: "file", language: "lua" };

// ── NOTE: The following are intentionally NOT provided here because sumneko.lua
// (Lua Language Server) already covers them with higher-quality analysis:
//   • Lua keyword hover (if, while, function, …)
//   • Lua stdlib function hover (string.*, table.*, math.*, …)
//   • Local/upvalue symbol hover with type inference
//   • math.pi / math.huge constant hover
// This extension only provides hover for lurek.* API surface and engine callbacks.

// PLACEHOLDER — kept to avoid reformatting the diff below
const _REMOVED_LUA_KEYWORD_DOCS = {  // sumneko handles keyword docs
  function: "Declares a function. Functions are first-class values in Lua.\n```lua\nfunction name(args) body end\nlocal f = function(args) body end\n```",
  local: "Declares a local variable or function. Local scope is limited to the enclosing block.\n```lua\nlocal x = 10\nlocal function helper() end\n```",
  if: "Conditional statement. Evaluates condition and executes the `then` block if truthy.\n```lua\nif condition then\n  -- body\nelseif other then\n  -- body\nelse\n  -- body\nend\n```",
  then: "Follows `if`/`elseif` to begin the conditional block.",
  else: "Alternative branch in an `if` statement, executed when all preceding conditions are false.",
  elseif: "Additional conditional branch in an `if` statement.\n```lua\nif x > 0 then\n  -- positive\nelseif x < 0 then\n  -- negative\nend\n```",
  end: "Closes a block started by `function`, `if`, `for`, `while`, or `do`.",
  for: "Loop construct. Numeric `for` or generic `for` (iterator).\n```lua\nfor i = 1, 10 do end       -- numeric\nfor k, v in pairs(t) do end -- generic\n```",
  while: "Loop that repeats while condition is truthy.\n```lua\nwhile condition do\n  -- body\nend\n```",
  repeat: "Loop that repeats until condition becomes truthy (always executes at least once).\n```lua\nrepeat\n  -- body\nuntil condition\n```",
  until: "Ends a `repeat` loop when the condition becomes truthy.",
  do: "Creates a block scope.\n```lua\ndo\n  local temp = compute()\nend -- temp is out of scope\n```",
  return: "Returns values from a function. Must be the last statement in a block.\n```lua\nreturn value1, value2\n```",
  break: "Exits the innermost `for`, `while`, or `repeat` loop.",
  goto: "Jumps to a label (Lua 5.2+/LuaJIT).\n```lua\ngoto done\n::done::\n```",
  in: "Used in generic `for` loops: `for k, v in pairs(t) do end`",
  and: "Logical AND operator. Returns first argument if falsy, otherwise second.\n```lua\nlocal x = a and b  -- b if a is truthy\n```",
  or: "Logical OR operator. Returns first argument if truthy, otherwise second.\n```lua\nlocal x = a or default  -- default if a is falsy\n```",
  not: "Logical NOT operator. Returns `true` if argument is falsy, `false` otherwise.",
  nil: "The absence of a value. Variables are `nil` before assignment. `nil` is falsy.",
  true: "Boolean true value.",
  false: "(removed — handled by sumneko.lua)",
};

// ── Easing function charts ───────────────────────────────────
// (MATH_CONSTANT_DOCS removed — sumneko.lua covers math.pi / math.huge hover)

type EasingFn = (t: number) => number;

const EASING_FUNCTIONS: Record<string, { fn: EasingFn; desc: string }> = {
  linear: { fn: (t) => t, desc: "Constant speed, no acceleration" },
  inQuad: { fn: (t) => t * t, desc: "Slow start, accelerating (quadratic)" },
  outQuad: { fn: (t) => t * (2 - t), desc: "Fast start, decelerating (quadratic)" },
  inOutQuad: { fn: (t) => (t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t), desc: "Accelerate then decelerate (quadratic)" },
  inCubic: { fn: (t) => t * t * t, desc: "Slow start, accelerating (cubic)" },
  outCubic: { fn: (t) => { const u = t - 1; return u * u * u + 1; }, desc: "Fast start, decelerating (cubic)" },
  inOutCubic: { fn: (t) => (t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1), desc: "Accelerate then decelerate (cubic)" },
  inQuart: { fn: (t) => t * t * t * t, desc: "Slow start, accelerating (quartic)" },
  outQuart: { fn: (t) => { const u = t - 1; return 1 - u * u * u * u; }, desc: "Fast start, decelerating (quartic)" },
  inQuint: { fn: (t) => t * t * t * t * t, desc: "Slow start, accelerating (quintic)" },
  outQuint: { fn: (t) => { const u = t - 1; return 1 + u * u * u * u * u; }, desc: "Fast start, decelerating (quintic)" },
  inSine: { fn: (t) => 1 - Math.cos((t * Math.PI) / 2), desc: "Sine wave acceleration" },
  outSine: { fn: (t) => Math.sin((t * Math.PI) / 2), desc: "Sine wave deceleration" },
  inOutSine: { fn: (t) => 0.5 * (1 - Math.cos(Math.PI * t)), desc: "Sine wave accel/decel" },
  inExpo: { fn: (t) => (t === 0 ? 0 : Math.pow(2, 10 * (t - 1))), desc: "Exponential acceleration" },
  outExpo: { fn: (t) => (t === 1 ? 1 : 1 - Math.pow(2, -10 * t)), desc: "Exponential deceleration" },
  inBack: { fn: (t) => { const s = 1.70158; return t * t * ((s + 1) * t - s); }, desc: "Overshoot start then accelerate" },
  outBack: { fn: (t) => { const s = 1.70158; const u = t - 1; return u * u * ((s + 1) * u + s) + 1; }, desc: "Decelerate with overshoot at end" },
  outBounce: {
    fn: (t) => {
      if (t < 1 / 2.75) return 7.5625 * t * t;
      if (t < 2 / 2.75) { const u = t - 1.5 / 2.75; return 7.5625 * u * u + 0.75; }
      if (t < 2.5 / 2.75) { const u = t - 2.25 / 2.75; return 7.5625 * u * u + 0.9375; }
      const u = t - 2.625 / 2.75; return 7.5625 * u * u + 0.984375;
    },
    desc: "Bounce at end",
  },
  inBounce: {
    fn: (t) => {
      const r = 1 - t;
      if (r < 1 / 2.75) return 1 - 7.5625 * r * r;
      if (r < 2 / 2.75) { const u = r - 1.5 / 2.75; return 1 - (7.5625 * u * u + 0.75); }
      if (r < 2.5 / 2.75) { const u = r - 2.25 / 2.75; return 1 - (7.5625 * u * u + 0.9375); }
      const u = r - 2.625 / 2.75; return 1 - (7.5625 * u * u + 0.984375);
    },
    desc: "Bounce at start",
  },
  outElastic: {
    fn: (t) => {
      if (t === 0 || t === 1) return t;
      return Math.pow(2, -10 * t) * Math.sin((t - 0.075) * (2 * Math.PI) / 0.3) + 1;
    },
    desc: "Elastic spring at end",
  },
  inElastic: {
    fn: (t) => {
      if (t === 0 || t === 1) return t;
      return -(Math.pow(2, 10 * (t - 1)) * Math.sin((t - 1.075) * (2 * Math.PI) / 0.3));
    },
    desc: "Elastic spring at start",
  },
};

function renderEasingChart(name: string, fn: EasingFn): string {
  const W = 20;
  const H = 8;
  const samples: number[] = [];
  for (let i = 0; i <= W; i++) {
    samples.push(Math.max(0, Math.min(1, fn(i / W))));
  }
  const grid: string[][] = [];
  for (let row = 0; row < H; row++) {
    grid.push(new Array(W + 1).fill(" "));
  }
  for (let col = 0; col <= W; col++) {
    const row = Math.max(0, Math.min(H - 1, Math.round((1 - samples[col]) * (H - 1))));
    grid[row][col] = "●";
  }
  const lines: string[] = [];
  for (let row = 0; row < H; row++) {
    const label = row === 0 ? "1│" : row === H - 1 ? "0│" : " │";
    lines.push(label + grid[row].join(""));
  }
  lines.push("  └" + "─".repeat(W + 1) + "► t");
  return lines.join("\n");
}

// ── Rich hover content builder ───────────────────────────────

function buildRichHover(fn: ApiFunction): vscode.MarkdownString {
  const md = new vscode.MarkdownString();
  md.appendCodeblock(fn.signature, "lua");

  if (fn.description) md.appendMarkdown("\n" + fn.description + "\n");

  if (fn.parameters.length > 0) {
    md.appendMarkdown("\n**Parameters:**\n\n");
    md.appendMarkdown("| Name | Type | Description |\n");
    md.appendMarkdown("|------|------|-------------|\n");
    for (const p of fn.parameters) {
      const opt = p.optional ? " *(opt)*" : "";
      const def = p.default ? ` (default: \`${p.default}\`)` : "";
      const desc = (p.description || "") + def;
      md.appendMarkdown(`| \`${p.name}\` | *${p.type}*${opt} | ${desc} |\n`);
    }
  }

  if (fn.returns) md.appendMarkdown(`\n**Returns:** ${fn.returns}\n`);
  if (fn.since) md.appendMarkdown(`\n*Since ${fn.since}*\n`);
  if (fn.deprecated) md.appendMarkdown(`\n⚠️ **Deprecated:** ${fn.deprecated}\n`);

  const source = fn.module ? `lurek.${fn.module}` : "";
  if (source) md.appendMarkdown(`\n*${source}*`);

  md.isTrusted = true;
  return md;
}

// ── Provider registration ────────────────────────────────────

export function register(
  context: vscode.ExtensionContext,
  apiData: ApiDataService,
): void {
  // ── Main API hover provider ──

  const apiHover = vscode.languages.registerHoverProvider(LUA_SELECTOR, {
    provideHover(
      document: vscode.TextDocument,
      position: vscode.Position,
    ): vscode.Hover | undefined {
      // ── A: Lurek2D API functions (lurek.module.func) ──
      const funcRange = document.getWordRangeAtPosition(position, /lurek\.\w+\.\w+/);
      if (funcRange) {
        const word = document.getText(funcRange);
        const fn = apiData.getFunction(word);
        if (fn) return new vscode.Hover(buildRichHover(fn), funcRange);
      }

      // ── D: Lurek2D callbacks (lurek.callback) ──
      const cbRange = document.getWordRangeAtPosition(position, /lurek\.\w+/);
      if (cbRange) {
        const word = document.getText(cbRange);
        // Don't match lurek.graphics etc. (already handled above or is a module)
        if (!word.includes(".", 5)) {
          for (const cb of apiData.getCallbacks()) {
            if (cb.fullPath === word) {
              const md = new vscode.MarkdownString();
              md.appendCodeblock(cb.signature, "lua");
              md.appendMarkdown("\n" + cb.description + "\n");
              if (cb.parameters.length > 0) {
                md.appendMarkdown("\n**Parameters:**\n");
                for (const p of cb.parameters) {
                  md.appendMarkdown(`- \`${p.name}\`: *${p.type}* — ${p.description}\n`);
                }
              }
              md.appendMarkdown("\n*Engine callback — called automatically by Lurek2D*");
              md.isTrusted = true;
              return new vscode.Hover(md, cbRange);
            }
          }
        }

        // Module hover
        const modName = word.replace("lurek.", "");
        const mod = apiData.getModule(modName);
        if (mod) {
          const md = new vscode.MarkdownString();
          md.appendMarkdown(`**lurek.${mod.name}**\n\n`);
          if (mod.description) md.appendMarkdown(mod.description + "\n\n");
          md.appendMarkdown(`*${mod.functions.length} functions, ${mod.methods.length} methods*`);
          md.isTrusted = true;
          return new vscode.Hover(md, cbRange);
        }
      }

      // Sections B (stdlib), C (local symbols), F (keywords) removed —
      // sumneko.lua provides higher-quality hover for all of these.
      return undefined;
    },
  });

  // ── E: Easing string hover provider ──

  const easingHover = vscode.languages.registerHoverProvider(LUA_SELECTOR, {
    provideHover(
      document: vscode.TextDocument,
      position: vscode.Position,
    ): vscode.Hover | undefined {
      const line = document.lineAt(position).text;
      const charIdx = position.character;

      // Find string boundaries
      let stringStart = -1;
      let quoteChar = "";
      for (let i = charIdx; i >= 0; i--) {
        if (line[i] === '"' || line[i] === "'") {
          stringStart = i + 1;
          quoteChar = line[i];
          break;
        }
      }
      if (stringStart < 0 || !quoteChar) return undefined;

      let stringEnd = -1;
      for (let i = charIdx; i < line.length; i++) {
        if (line[i] === quoteChar) {
          stringEnd = i;
          break;
        }
      }
      if (stringEnd < 0) return undefined;

      const stringContent = line.substring(stringStart, stringEnd);
      const easing = EASING_FUNCTIONS[stringContent];
      if (!easing) return undefined;

      const chart = renderEasingChart(stringContent, easing.fn);
      const md = new vscode.MarkdownString();
      md.appendMarkdown(`**Easing: \`${stringContent}\`**\n\n`);
      md.appendCodeblock(chart, "");
      md.appendMarkdown(`\n${easing.desc}\n`);
      md.isTrusted = true;

      const range = new vscode.Range(position.line, stringStart, position.line, stringEnd);
      return new vscode.Hover(md, range);
    },
  });

  // mathConstHover removed — sumneko.lua covers math.pi / math.huge / math.maxinteger

  // ── I4: Callback parameter hover ─────────────────────────────

  // Map: callback name → parameter name → {type, description}
  const CALLBACK_PARAM_DOCS: Record<string, Record<string, { type: string; desc: string }>> = {
    update: {
      dt: { type: "number", desc: "Delta time in seconds since the last frame. Use this to make movement frame-rate-independent.\n\n```lua\nfunction lurek.update(dt)\n  x = x + speed * dt\nend\n```" },
    },
    keypressed: {
      key: { type: "string", desc: 'Name of the key that was pressed (e.g. `"space"`, `"a"`, `"left"`, `"escape"`).' },
      scancode: { type: "string", desc: "Physical hardware scancode — use for layout-independent input." },
      isrepeat: { type: "boolean", desc: "`true` if generated by key repeat (held down), `false` for first press." },
    },
    keyreleased: {
      key: { type: "string", desc: 'Name of the key that was released (e.g. `"space"`, `"a"`, `"left"`).' },
      scancode: { type: "string", desc: "Physical hardware scancode of the key." },
    },
    mousepressed: {
      x: { type: "number", desc: "Mouse X position in screen coordinates when button was pressed." },
      y: { type: "number", desc: "Mouse Y position in screen coordinates when button was pressed." },
      button: { type: "number", desc: "Mouse button index: `1` = left, `2` = right, `3` = middle." },
      istouch: { type: "boolean", desc: "`true` if this event was generated by a touch input device." },
      presses: { type: "number", desc: "Number of consecutive presses (`2` = double-click)." },
    },
    mousereleased: {
      x: { type: "number", desc: "Mouse X position when button was released." },
      y: { type: "number", desc: "Mouse Y position when button was released." },
      button: { type: "number", desc: "Mouse button index: `1` = left, `2` = right, `3` = middle." },
      istouch: { type: "boolean", desc: "`true` if generated by a touch input device." },
    },
    wheelmoved: {
      x: { type: "number", desc: "Horizontal scroll amount. Positive = right." },
      y: { type: "number", desc: "Vertical scroll amount. Positive = up (scroll wheel towards user)." },
    },
    resize: {
      w: { type: "number", desc: "New window width in pixels." },
      h: { type: "number", desc: "New window height in pixels." },
    },
    focus: {
      f: { type: "boolean", desc: "`true` if the window gained focus, `false` if it lost focus." },
    },
    visible: {
      v: { type: "boolean", desc: "`true` if the window became visible, `false` if minimized/hidden." },
    },
    textinput: {
      t: { type: "string", desc: "The UTF-8 encoded character(s) that were typed. Use this for text field input rather than `lurek.keypressed`." },
    },
    gamepadpressed: {
      joystick: { type: "Joystick", desc: "The joystick/gamepad object that reported the event." },
      button: { type: "string", desc: 'Gamepad virtual button name: `"a"`, `"b"`, `"x"`, `"y"`, `"back"`, `"start"`, `"leftshoulder"`, `"rightshoulder"`, `"dpup"`, `"dpdown"`, `"dpleft"`, `"dpright"`.' },
    },
    gamepadreleased: {
      joystick: { type: "Joystick", desc: "The joystick/gamepad object that reported the event." },
      button: { type: "string", desc: 'Gamepad virtual button name (`"a"`, `"b"`, `"x"`, `"y"`, etc.).' },
    },
    gamepadaxis: {
      joystick: { type: "Joystick", desc: "The joystick/gamepad object that reported the event." },
      axis: { type: "string", desc: 'Axis name: `"leftx"`, `"lefty"`, `"rightx"`, `"righty"`, `"triggerleft"`, `"triggerright"`.' },
      value: { type: "number", desc: "Axis value in the range `[-1.0, 1.0]` (triggers: `[0, 1]`)." },
    },
    joystickadded: { joystick: { type: "Joystick", desc: "The joystick/gamepad that was connected." } },
    joystickremoved: { joystick: { type: "Joystick", desc: "The joystick/gamepad that was disconnected." } },
    touchpressed: {
      id: { type: "lightuserdata", desc: "Unique identifier for this touch point." },
      x: { type: "number", desc: "X position of the touch in screen coordinates." },
      y: { type: "number", desc: "Y position of the touch in screen coordinates." },
      dx: { type: "number", desc: "X movement delta since last touch event." },
      dy: { type: "number", desc: "Y movement delta since last touch event." },
      pressure: { type: "number", desc: "Touch pressure in `[0, 1]`. Not all devices support pressure." },
    },
    touchmoved: {
      id: { type: "lightuserdata", desc: "Unique identifier for this touch point." },
      x: { type: "number", desc: "X position of the touch." },
      y: { type: "number", desc: "Y position of the touch." },
      dx: { type: "number", desc: "X movement delta." },
      dy: { type: "number", desc: "Y movement delta." },
      pressure: { type: "number", desc: "Touch pressure in `[0, 1]`." },
    },
    touchreleased: {
      id: { type: "lightuserdata", desc: "Unique identifier for the touch point that ended." },
      x: { type: "number", desc: "X position where touch was released." },
      y: { type: "number", desc: "Y position where touch was released." },
      dx: { type: "number", desc: "X movement delta at release." },
      dy: { type: "number", desc: "Y movement delta at release." },
      pressure: { type: "number", desc: "Pressure at release." },
    },
  };

  // Build combined set of all known callback parameter names for fast rejection.
  // apiData.getCallbacks() is the primary source; CALLBACK_PARAM_DOCS provides legacy fallback.
  const _allCallbackParamNames = new Set<string>(
    Object.values(CALLBACK_PARAM_DOCS).flatMap(p => Object.keys(p)),
  );
  for (const cb of apiData.getCallbacks()) {
    for (const p of cb.parameters) _allCallbackParamNames.add(p.name);
  }

  const callbackParamHover = vscode.languages.registerHoverProvider(LUA_SELECTOR, {
    provideHover(
      document: vscode.TextDocument,
      position: vscode.Position,
    ): vscode.Hover | undefined {
      const wordRange = document.getWordRangeAtPosition(position, /\w+/);
      if (!wordRange) return undefined;
      const word = document.getText(wordRange);
      if (!_allCallbackParamNames.has(word)) return undefined;

      // Walk backwards from current line to find the enclosing lurek callback
      const lines = document.getText().split("\n");
      let callbackName: string | undefined;
      let depth = 0;

      for (let lineIdx = position.line; lineIdx >= 0; lineIdx--) {
        const line = lines[lineIdx];
        const endCount = (line.match(/\bend\b/g) ?? []).length;
        const startCount = (line.match(/\b(?:function|do|then|repeat)\b/g) ?? []).length;
        depth += endCount - startCount;
        if (depth >= 0) {
          const cbMatch = line.match(/lurek\.(\w+)\s*=\s*function/);
          if (cbMatch) { callbackName = cbMatch[1]; break; }
        }
      }

      if (!callbackName) return undefined;

      // Primary: apiData callbacks (live JSON data)
      const apiCb = apiData.getCallbacks().find(c => c.name === callbackName);
      if (apiCb) {
        const apiParam = apiCb.parameters.find(p => p.name === word);
        if (apiParam) {
          const md = new vscode.MarkdownString();
          md.appendCodeblock(`(parameter) ${word}: ${apiParam.type}`, "typescript");
          if (apiParam.description) md.appendMarkdown(`\n${apiParam.description}\n`);
          md.appendMarkdown(`\n*Parameter of \`lurek.${callbackName}\`*`);
          md.isTrusted = true;
          return new vscode.Hover(md, wordRange);
        }
      }

      // Fallback: legacy rich descriptions
      const paramDocs = CALLBACK_PARAM_DOCS[callbackName];
      if (!paramDocs?.[word]) return undefined;

      const { type, desc } = paramDocs[word];
      const md = new vscode.MarkdownString();
      md.appendCodeblock(`(parameter) ${word}: ${type}`, "typescript");
      md.appendMarkdown(`\n${desc}\n\n*Parameter of \`lurek.${callbackName}\`*`);
      md.isTrusted = true;
      return new vscode.Hover(md, wordRange);
    },
  });

  // ── G: Physics gravity hover ─────────────────────────────────

  const physicsGravityHover = vscode.languages.registerHoverProvider(LUA_SELECTOR, {
    provideHover(
      document: vscode.TextDocument,
      position: vscode.Position,
    ): vscode.Hover | undefined {
      const line = document.lineAt(position).text;
      // Only trigger near lurek.physics.newWorld calls
      if (!/lurek\.physics\.newWorld/.test(line)) return undefined;

      const wordRange = document.getWordRangeAtPosition(position, /[-\d]+\.?\d*/);
      if (!wordRange) return undefined;
      const numText = document.getText(wordRange);
      const num = parseFloat(numText);
      if (isNaN(num)) return undefined;

      // Check if this number is the 2nd arg (gravity Y) of newWorld
      const before = line.substring(0, wordRange.start.character);
      const commaCount = (before.match(/,/g) ?? []).length;
      if (commaCount !== 1) return undefined;

      const earthPx = Math.round(980);
      const md = new vscode.MarkdownString(
        `**Gravity Y = ${num} px/s²**\n\n` +
        `Earth gravity (at 1px = 1cm) ≈ **${earthPx} px/s²**\n\n` +
        `Current value is **${(num / earthPx * 100).toFixed(0)}%** of Earth gravity.`
      );
      md.isTrusted = true;
      return new vscode.Hover(md, wordRange);
    },
  });

  context.subscriptions.push(apiHover, easingHover, callbackParamHover, physicsGravityHover);
  // mathConstHover not registered — sumneko.lua handles math.pi / math.huge
}
