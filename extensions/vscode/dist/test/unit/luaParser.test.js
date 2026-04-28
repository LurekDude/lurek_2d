"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// src/test/unit/luaParser.test.ts
var assert = __toESM(require("assert"));

// src/generated/lurekApiData.ts
var LUREK_CALLBACK_NAMES = /* @__PURE__ */ new Set([
  "load",
  "update",
  "draw",
  "keypressed",
  "keyreleased",
  "textinput",
  "mousepressed",
  "mousereleased",
  "mousemoved",
  "wheelmoved",
  "gamepadpressed",
  "gamepadreleased",
  "gamepadaxis",
  "joystickadded",
  "joystickremoved",
  "focus",
  "visible",
  "resize",
  "quit",
  "init",
  "ready",
  "process",
  "process_late",
  "process_physics",
  "fixedUpdate",
  "draw_ui",
  "exit",
  "touchpressed",
  "touchmoved",
  "touchreleased",
  "textedited"
]);

// src/services/luaParser.ts
var LUA_KEYWORDS = /* @__PURE__ */ new Set([
  "and",
  "break",
  "do",
  "else",
  "elseif",
  "end",
  "false",
  "for",
  "function",
  "goto",
  "if",
  "in",
  "local",
  "nil",
  "not",
  "or",
  "repeat",
  "return",
  "then",
  "true",
  "until",
  "while"
]);
var OPERATORS = /* @__PURE__ */ new Set([
  "+",
  "-",
  "*",
  "/",
  "%",
  "^",
  "#",
  "==",
  "~=",
  "<",
  ">",
  "<=",
  ">=",
  "=",
  "..",
  "...",
  "//"
]);
var PUNCTUATION = /* @__PURE__ */ new Set([
  "(",
  ")",
  "{",
  "}",
  "[",
  "]",
  ";",
  ":",
  ",",
  "."
]);
var LuaDocumentAnalyzer = class {
  tokenize(text) {
    const tokens = [];
    const len = text.length;
    let pos = 0;
    let line = 0;
    let col = 0;
    while (pos < len) {
      const ch = text[pos];
      if (ch === " " || ch === "	" || ch === "\r" || ch === "\n") {
        const start = pos;
        const startLine = line;
        const startCol = col;
        while (pos < len && (text[pos] === " " || text[pos] === "	" || text[pos] === "\r" || text[pos] === "\n")) {
          if (text[pos] === "\n") {
            line++;
            col = 0;
          } else {
            col++;
          }
          pos++;
        }
        tokens.push({ type: 7 /* Whitespace */, value: text.slice(start, pos), line: startLine, column: startCol, length: pos - start });
        continue;
      }
      if (ch === "-" && pos + 1 < len && text[pos + 1] === "-") {
        const startLine = line;
        const startCol = col;
        if (pos + 2 < len && text[pos + 2] === "[") {
          const level = this.countLongBracketLevel(text, pos + 2);
          if (level >= 0) {
            const closing = "]" + "=".repeat(level) + "]";
            const endIdx = text.indexOf(closing, pos + 4 + level);
            const end2 = endIdx >= 0 ? endIdx + closing.length : len;
            const value2 = text.slice(pos, end2);
            const nlCount = countNewlines(value2);
            tokens.push({ type: 4 /* Comment */, value: value2, line: startLine, column: startCol, length: end2 - pos });
            for (let i = pos; i < end2; i++) {
              if (text[i] === "\n") {
                line++;
                col = 0;
              } else {
                col++;
              }
            }
            pos = end2;
            continue;
          }
        }
        const nlIdx = text.indexOf("\n", pos);
        const end = nlIdx >= 0 ? nlIdx : len;
        const value = text.slice(pos, end);
        tokens.push({ type: 4 /* Comment */, value, line: startLine, column: startCol, length: end - pos });
        col += end - pos;
        pos = end;
        continue;
      }
      if (ch === "[") {
        const level = this.countLongBracketLevel(text, pos);
        if (level >= 0) {
          const closing = "]" + "=".repeat(level) + "]";
          const contentStart = pos + 2 + level;
          const endIdx = text.indexOf(closing, contentStart);
          const end = endIdx >= 0 ? endIdx + closing.length : len;
          const value = text.slice(pos, end);
          const startLine = line;
          const startCol = col;
          for (let i = pos; i < end; i++) {
            if (text[i] === "\n") {
              line++;
              col = 0;
            } else {
              col++;
            }
          }
          tokens.push({ type: 2 /* String */, value, line: startLine, column: startCol, length: end - pos });
          pos = end;
          continue;
        }
      }
      if (ch === '"' || ch === "'") {
        const startLine = line;
        const startCol = col;
        const quote = ch;
        let end = pos + 1;
        while (end < len) {
          if (text[end] === "\\") {
            end += 2;
            continue;
          }
          if (text[end] === quote) {
            end++;
            break;
          }
          if (text[end] === "\n") break;
          end++;
        }
        const value = text.slice(pos, end);
        tokens.push({ type: 2 /* String */, value, line: startLine, column: startCol, length: end - pos });
        col += end - pos;
        pos = end;
        continue;
      }
      if (isDigit(ch) || ch === "." && pos + 1 < len && isDigit(text[pos + 1])) {
        const startLine = line;
        const startCol = col;
        let end = pos;
        if (ch === "0" && end + 1 < len && (text[end + 1] === "x" || text[end + 1] === "X")) {
          end += 2;
          while (end < len && isHexDigit(text[end])) end++;
        } else if (ch === "0" && end + 1 < len && (text[end + 1] === "b" || text[end + 1] === "B")) {
          end += 2;
          while (end < len && (text[end] === "0" || text[end] === "1")) end++;
        } else {
          while (end < len && isDigit(text[end])) end++;
          if (end < len && text[end] === ".") {
            end++;
            while (end < len && isDigit(text[end])) end++;
          }
          if (end < len && (text[end] === "e" || text[end] === "E")) {
            end++;
            if (end < len && (text[end] === "+" || text[end] === "-")) end++;
            while (end < len && isDigit(text[end])) end++;
          }
        }
        const value = text.slice(pos, end);
        tokens.push({ type: 3 /* Number */, value, line: startLine, column: startCol, length: end - pos });
        col += end - pos;
        pos = end;
        continue;
      }
      if (isIdentStart(ch)) {
        const startCol = col;
        let end = pos + 1;
        while (end < len && isIdentPart(text[end])) end++;
        const value = text.slice(pos, end);
        const type = LUA_KEYWORDS.has(value) ? 0 /* Keyword */ : 1 /* Identifier */;
        tokens.push({ type, value, line, column: startCol, length: end - pos });
        col += end - pos;
        pos = end;
        continue;
      }
      if (pos + 2 < len) {
        const three = text.slice(pos, pos + 3);
        if (three === "...") {
          tokens.push({ type: 5 /* Operator */, value: three, line, column: col, length: 3 });
          col += 3;
          pos += 3;
          continue;
        }
      }
      if (pos + 1 < len) {
        const two = text.slice(pos, pos + 2);
        if (OPERATORS.has(two)) {
          tokens.push({ type: 5 /* Operator */, value: two, line, column: col, length: 2 });
          col += 2;
          pos += 2;
          continue;
        }
      }
      if (OPERATORS.has(ch)) {
        tokens.push({ type: 5 /* Operator */, value: ch, line, column: col, length: 1 });
        col++;
        pos++;
        continue;
      }
      if (PUNCTUATION.has(ch)) {
        tokens.push({ type: 6 /* Punctuation */, value: ch, line, column: col, length: 1 });
        col++;
        pos++;
        continue;
      }
      col++;
      pos++;
    }
    tokens.push({ type: 8 /* EOF */, value: "", line, column: col, length: 0 });
    return tokens;
  }
  // ── Document analysis ──────────────────────────────────────
  analyze(text) {
    const tokens = this.tokenize(text);
    const symbols = [];
    const requires = [];
    const callbacks = [];
    const scopes = [];
    const comments = [];
    for (const tok of tokens) {
      if (tok.type === 4 /* Comment */) {
        const stripped = tok.value.replace(/^--\[=*\[/, "").replace(/\]=*\]$/, "").replace(/^--/, "").trim();
        comments.push({
          text: stripped,
          line: tok.line,
          isBlock: tok.value.startsWith("--["),
          isLuaCATS: tok.value.startsWith("---@")
        });
      }
    }
    const toks = tokens.filter((t) => t.type !== 7 /* Whitespace */ && t.type !== 4 /* Comment */);
    const scopeStack = [];
    let i = 0;
    const peek = (offset = 0) => toks[i + offset];
    const match = (type, value) => {
      const t = peek();
      if (!t) return false;
      if (t.type !== type) return false;
      if (value !== void 0 && t.value !== value) return false;
      return true;
    };
    const advance = () => toks[i++];
    const getPrecedingComment = (targetLine) => {
      for (let c = comments.length - 1; c >= 0; c--) {
        if (comments[c].line === targetLine - 1 || comments[c].line === targetLine) {
          return comments[c].text;
        }
      }
      return void 0;
    };
    while (i < toks.length && peek()?.type !== 8 /* EOF */) {
      const cur = peek();
      if (match(0 /* Keyword */, "local")) {
        const localTok = advance();
        if (match(0 /* Keyword */, "function")) {
          advance();
          if (peek()?.type === 1 /* Identifier */) {
            const nameTok = advance();
            const params = this.parseParamList(toks, i);
            i = params.nextIndex;
            const desc = getPrecedingComment(localTok.line);
            const sym = {
              name: nameTok.value,
              kind: "function",
              line: nameTok.line,
              column: nameTok.column,
              scope: scopeStack.length > 0 ? scopeStack[scopeStack.length - 1].name : void 0,
              parameters: params.names,
              isLocal: true,
              description: desc
            };
            symbols.push(sym);
            for (const pName of params.names) {
              symbols.push({
                name: pName,
                kind: "parameter",
                line: nameTok.line,
                column: nameTok.column,
                scope: nameTok.value,
                isLocal: true
              });
            }
            scopeStack.push({ name: nameTok.value, startLine: nameTok.line, kind: "function" });
          }
          continue;
        }
        if (peek()?.type === 1 /* Identifier */) {
          const nameTok = advance();
          if (match(5 /* Operator */, "=")) {
            advance();
            if (peek()?.type === 1 /* Identifier */ && peek()?.value === "require") {
              advance();
              if (match(6 /* Punctuation */, "(")) {
                advance();
                if (peek()?.type === 2 /* String */) {
                  const strTok = advance();
                  const modPath = strTok.value.slice(1, -1);
                  requires.push({
                    modulePath: modPath,
                    localName: nameTok.value,
                    line: nameTok.line,
                    column: nameTok.column
                  });
                }
              }
            }
            if (peek()?.type === 6 /* Punctuation */ && peek()?.value === "{") {
              symbols.push({
                name: nameTok.value,
                kind: "table",
                line: nameTok.line,
                column: nameTok.column,
                scope: scopeStack.length > 0 ? scopeStack[scopeStack.length - 1].name : void 0,
                isLocal: true,
                description: getPrecedingComment(nameTok.line)
              });
              continue;
            }
          }
          symbols.push({
            name: nameTok.value,
            kind: "local",
            line: nameTok.line,
            column: nameTok.column,
            scope: scopeStack.length > 0 ? scopeStack[scopeStack.length - 1].name : void 0,
            isLocal: true,
            description: getPrecedingComment(nameTok.line)
          });
          while (match(6 /* Punctuation */, ",")) {
            advance();
            if (peek()?.type === 1 /* Identifier */) {
              const extraTok = advance();
              symbols.push({
                name: extraTok.value,
                kind: "local",
                line: extraTok.line,
                column: extraTok.column,
                scope: scopeStack.length > 0 ? scopeStack[scopeStack.length - 1].name : void 0,
                isLocal: true
              });
            }
          }
        }
        continue;
      }
      if (match(0 /* Keyword */, "function")) {
        const funcTok = advance();
        if (peek()?.type === 1 /* Identifier */) {
          const nameTok = advance();
          let fullName = nameTok.value;
          let isMethod = false;
          let objectType;
          while (true) {
            if (match(6 /* Punctuation */, ".")) {
              advance();
              if (peek()?.type === 1 /* Identifier */) {
                fullName += "." + advance().value;
              }
            } else if (match(6 /* Punctuation */, ":")) {
              advance();
              isMethod = true;
              objectType = fullName;
              if (peek()?.type === 1 /* Identifier */) {
                const methTok = advance();
                fullName += ":" + methTok.value;
              }
            } else {
              break;
            }
          }
          const params = this.parseParamList(toks, i);
          i = params.nextIndex;
          const lastDot = fullName.lastIndexOf(".");
          const lastColon = fullName.lastIndexOf(":");
          const sep = Math.max(lastDot, lastColon);
          const shortName = sep >= 0 ? fullName.slice(sep + 1) : fullName;
          const sym = {
            name: shortName,
            kind: isMethod ? "method" : "function",
            line: funcTok.line,
            column: funcTok.column,
            scope: scopeStack.length > 0 ? scopeStack[scopeStack.length - 1].name : void 0,
            type: objectType,
            parameters: params.names,
            isLocal: false,
            description: getPrecedingComment(funcTok.line)
          };
          symbols.push(sym);
          if (fullName.startsWith("lurek.") && LUREK_CALLBACK_NAMES.has(shortName)) {
            callbacks.push(sym);
          }
          for (const pName of params.names) {
            symbols.push({
              name: pName,
              kind: "parameter",
              line: funcTok.line,
              column: funcTok.column,
              scope: shortName,
              isLocal: true
            });
          }
          scopeStack.push({ name: shortName, startLine: funcTok.line, kind: "function" });
          continue;
        }
        scopeStack.push({ name: "<anonymous>", startLine: funcTok.line, kind: "function" });
        if (match(6 /* Punctuation */, "(")) {
          const params = this.parseParamList(toks, i);
          i = params.nextIndex;
        }
        continue;
      }
      if (cur.type === 1 /* Identifier */) {
        const startIdx = i;
        let fullName = cur.value;
        let tempI = i + 1;
        let isColon = false;
        while (tempI < toks.length) {
          if (toks[tempI]?.value === "." && toks[tempI + 1]?.type === 1 /* Identifier */) {
            fullName += "." + toks[tempI + 1].value;
            tempI += 2;
          } else if (toks[tempI]?.value === ":" && toks[tempI + 1]?.type === 1 /* Identifier */) {
            fullName += ":" + toks[tempI + 1].value;
            isColon = true;
            tempI += 2;
          } else {
            break;
          }
        }
        if (tempI < toks.length && toks[tempI]?.value === "=") {
          const eqIdx = tempI;
          const afterEq = toks[eqIdx + 1];
          if (afterEq?.type === 0 /* Keyword */ && afterEq.value === "function") {
            i = eqIdx + 2;
            const params = this.parseParamList(toks, i);
            i = params.nextIndex;
            const lastDot = fullName.lastIndexOf(".");
            const shortName = lastDot >= 0 ? fullName.slice(lastDot + 1) : fullName;
            const sym = {
              name: shortName,
              kind: "function",
              line: cur.line,
              column: cur.column,
              parameters: params.names,
              isLocal: false,
              description: getPrecedingComment(cur.line)
            };
            symbols.push(sym);
            if (fullName.startsWith("lurek.") && LUREK_CALLBACK_NAMES.has(shortName)) {
              callbacks.push(sym);
            }
            for (const pName of params.names) {
              symbols.push({
                name: pName,
                kind: "parameter",
                line: cur.line,
                column: cur.column,
                scope: shortName,
                isLocal: true
              });
            }
            scopeStack.push({ name: shortName, startLine: cur.line, kind: "function" });
            continue;
          }
          if (fullName.endsWith(".__index") && afterEq?.type === 1 /* Identifier */) {
            i = eqIdx + 2;
            continue;
          }
        }
        advance();
        continue;
      }
      if (cur.type === 0 /* Keyword */) {
        if (cur.value === "do") {
          scopeStack.push({ name: "do", startLine: cur.line, kind: "do" });
          advance();
          continue;
        }
        if (cur.value === "if" || cur.value === "elseif") {
          if (cur.value === "if") {
            scopeStack.push({ name: "if", startLine: cur.line, kind: "if" });
          }
          advance();
          continue;
        }
        if (cur.value === "for") {
          scopeStack.push({ name: "for", startLine: cur.line, kind: "for" });
          advance();
          continue;
        }
        if (cur.value === "while") {
          scopeStack.push({ name: "while", startLine: cur.line, kind: "while" });
          advance();
          continue;
        }
        if (cur.value === "repeat") {
          scopeStack.push({ name: "repeat", startLine: cur.line, kind: "repeat" });
          advance();
          continue;
        }
        if (cur.value === "end" || cur.value === "until") {
          const popped = scopeStack.pop();
          if (popped) {
            scopes.push({
              name: popped.name,
              startLine: popped.startLine,
              endLine: cur.line,
              kind: popped.kind
            });
            for (let s = symbols.length - 1; s >= 0; s--) {
              if (symbols[s].kind === "function" && symbols[s].name === popped.name && symbols[s].line === popped.startLine) {
                symbols[s].endLine = cur.line;
                break;
              }
            }
          }
          advance();
          continue;
        }
      }
      advance();
    }
    const lastLine = text.split("\n").length - 1;
    while (scopeStack.length > 0) {
      const popped = scopeStack.pop();
      scopes.push({ name: popped.name, startLine: popped.startLine, endLine: lastLine, kind: popped.kind });
    }
    const baseInfo = {
      symbols,
      requires,
      callbacks,
      scopes,
      comments,
      classes: []
    };
    baseInfo.classes = this.detectClasses(baseInfo);
    return baseInfo;
  }
  // ── Position-based queries ─────────────────────────────────
  getSymbolAt(info, line, column) {
    for (const sym of info.symbols) {
      if (sym.line === line && column >= sym.column && column < sym.column + sym.name.length) {
        return sym;
      }
    }
    return void 0;
  }
  getScopeAt(info, line) {
    let best;
    for (const scope of info.scopes) {
      if (line >= scope.startLine && line <= scope.endLine) {
        if (!best || scope.startLine > best.startLine) {
          best = scope;
        }
      }
    }
    return best;
  }
  findReferencesInDocument(text, symbolName) {
    const results = [];
    const tokens = this.tokenize(text);
    for (const tok of tokens) {
      if (tok.type === 1 /* Identifier */ && tok.value === symbolName) {
        results.push({ line: tok.line, column: tok.column });
      }
    }
    return results;
  }
  getVisibleLocals(info, line) {
    const scope = this.getScopeAt(info, line);
    return info.symbols.filter((sym) => {
      if (!sym.isLocal) return false;
      if (sym.line > line) return false;
      if (sym.scope && scope) {
        return sym.scope === scope.name || !sym.scope;
      }
      return true;
    });
  }
  detectClasses(info) {
    const classes = [];
    const classNames = /* @__PURE__ */ new Set();
    for (const sym of info.symbols) {
      if (sym.kind === "method" && sym.type) {
        classNames.add(sym.type);
      }
    }
    for (const name of classNames) {
      const methods = info.symbols.filter((s) => s.kind === "method" && s.type === name);
      const fields = info.symbols.filter((s) => s.kind === "field" && s.scope === name).map((s) => s.name);
      const firstMethod = methods[0];
      if (firstMethod) {
        classes.push({
          name,
          methods,
          fields,
          line: firstMethod.line
        });
      }
    }
    return classes;
  }
  getWordAtPosition(text, line, column) {
    const lines = text.split("\n");
    if (line < 0 || line >= lines.length) return "";
    const lineText = lines[line];
    if (column < 0 || column >= lineText.length) return "";
    let start = column;
    let end = column;
    while (start > 0 && isIdentPart(lineText[start - 1])) start--;
    while (end < lineText.length && isIdentPart(lineText[end])) end++;
    while (start > 0 && (lineText[start - 1] === "." || lineText[start - 1] === ":")) {
      start--;
      while (start > 0 && isIdentPart(lineText[start - 1])) start--;
    }
    return lineText.slice(start, end);
  }
  getFunctionCallContext(text, line, column) {
    const lines = text.split("\n");
    if (line < 0 || line >= lines.length) return void 0;
    const lineText = lines[line];
    let parenDepth = 0;
    let paramIndex = 0;
    let searchLine = line;
    let searchCol = Math.min(column, lineText.length) - 1;
    while (searchLine >= 0) {
      const sLine = lines[searchLine];
      const startCol = searchLine === line ? searchCol : sLine.length - 1;
      for (let c = startCol; c >= 0; c--) {
        const ch = sLine[c];
        if (ch === ")") {
          parenDepth++;
          continue;
        }
        if (ch === "(") {
          if (parenDepth === 0) {
            let nameEnd = c - 1;
            while (nameEnd >= 0 && sLine[nameEnd] === " ") nameEnd--;
            let nameStart = nameEnd;
            while (nameStart > 0 && (isIdentPart(sLine[nameStart - 1]) || sLine[nameStart - 1] === "." || sLine[nameStart - 1] === ":")) {
              nameStart--;
            }
            const funcName = sLine.slice(nameStart, nameEnd + 1);
            if (funcName.length > 0) {
              return { functionName: funcName, paramIndex };
            }
            return void 0;
          }
          parenDepth--;
          continue;
        }
        if (ch === "," && parenDepth === 0) {
          paramIndex++;
        }
      }
      searchLine--;
      if (searchLine >= 0) {
        searchCol = lines[searchLine].length - 1;
      }
    }
    return void 0;
  }
  isInsideString(text, line, column) {
    const tokens = this.tokenize(text);
    for (const tok of tokens) {
      if (tok.type !== 2 /* String */) continue;
      const endLine = tok.line + countNewlines(tok.value);
      if (tok.line === endLine) {
        if (tok.line === line && column >= tok.column && column < tok.column + tok.length) {
          return true;
        }
      } else {
        if (line > tok.line && line < endLine) return true;
        if (line === tok.line && column >= tok.column) return true;
        if (line === endLine) {
          const lastNl = tok.value.lastIndexOf("\n");
          const endCol = tok.value.length - lastNl - 1;
          if (column < endCol) return true;
        }
      }
    }
    return false;
  }
  isInsideComment(text, line, column) {
    const tokens = this.tokenize(text);
    for (const tok of tokens) {
      if (tok.type !== 4 /* Comment */) continue;
      const endLine = tok.line + countNewlines(tok.value);
      if (tok.line === endLine) {
        if (tok.line === line && column >= tok.column) return true;
      } else {
        if (line > tok.line && line < endLine) return true;
        if (line === tok.line && column >= tok.column) return true;
        if (line === endLine) {
          const lastNl = tok.value.lastIndexOf("\n");
          const endCol = tok.value.length - lastNl - 1;
          if (column < endCol) return true;
        }
      }
    }
    return false;
  }
  // ── Internal helpers ───────────────────────────────────────
  countLongBracketLevel(text, pos) {
    if (text[pos] !== "[") return -1;
    let level = 0;
    let p = pos + 1;
    while (p < text.length && text[p] === "=") {
      level++;
      p++;
    }
    if (p < text.length && text[p] === "[") return level;
    return -1;
  }
  parseParamList(toks, startIndex) {
    const names = [];
    let i = startIndex;
    if (i >= toks.length || toks[i]?.value !== "(") return { names, nextIndex: i };
    i++;
    while (i < toks.length && toks[i]?.value !== ")") {
      if (toks[i]?.type === 1 /* Identifier */) {
        names.push(toks[i].value);
      } else if (toks[i]?.value === "...") {
        names.push("...");
      }
      i++;
    }
    if (i < toks.length && toks[i]?.value === ")") i++;
    return { names, nextIndex: i };
  }
};
function isDigit(ch) {
  return ch >= "0" && ch <= "9";
}
function isHexDigit(ch) {
  return isDigit(ch) || ch >= "a" && ch <= "f" || ch >= "A" && ch <= "F";
}
function isIdentStart(ch) {
  return ch >= "a" && ch <= "z" || ch >= "A" && ch <= "Z" || ch === "_";
}
function isIdentPart(ch) {
  return isIdentStart(ch) || isDigit(ch);
}
function countNewlines(text) {
  let count = 0;
  for (let i = 0; i < text.length; i++) {
    if (text[i] === "\n") count++;
  }
  return count;
}

// src/test/unit/luaParser.test.ts
var analyzer = new LuaDocumentAnalyzer();
suite("LuaParser \u2014 tokenize", () => {
  test("tokenizes empty string", () => {
    const tokens = analyzer.tokenize("");
    assert.strictEqual(
      tokens.filter((t) => t.type !== 8 /* EOF */).length,
      0
    );
  });
  test("tokenizes a local assignment", () => {
    const tokens = analyzer.tokenize("local x = 42");
    const nonWs = tokens.filter((t) => t.type !== 7 /* Whitespace */);
    assert.ok(nonWs.length >= 4);
    assert.strictEqual(nonWs[0].type, 0 /* Keyword */);
    assert.strictEqual(nonWs[0].value, "local");
    assert.strictEqual(nonWs[1].type, 1 /* Identifier */);
    assert.strictEqual(nonWs[1].value, "x");
  });
  test("tokenizes string literals", () => {
    const tokens = analyzer.tokenize('"hello world"');
    const strTokens = tokens.filter((t) => t.type === 2 /* String */);
    assert.strictEqual(strTokens.length, 1);
    assert.strictEqual(strTokens[0].value, '"hello world"');
  });
  test("tokenizes single-line comments", () => {
    const tokens = analyzer.tokenize("-- this is a comment\nlocal x = 1");
    const comments = tokens.filter((t) => t.type === 4 /* Comment */);
    assert.strictEqual(comments.length, 1);
    assert.ok(comments[0].value.includes("this is a comment"));
  });
  test("tokenizes multi-line comments", () => {
    const tokens = analyzer.tokenize("--[[ multi\nline ]]");
    const comments = tokens.filter((t) => t.type === 4 /* Comment */);
    assert.strictEqual(comments.length, 1);
    assert.ok(comments[0].value.includes("multi"));
  });
  test("tokenizes all Lua keywords", () => {
    const keywords = [
      "and",
      "break",
      "do",
      "else",
      "elseif",
      "end",
      "false",
      "for",
      "function",
      "goto",
      "if",
      "in",
      "local",
      "nil",
      "not",
      "or",
      "repeat",
      "return",
      "then",
      "true",
      "until",
      "while"
    ];
    for (const kw of keywords) {
      const tokens = analyzer.tokenize(kw);
      const nonWs = tokens.filter((t) => t.type !== 7 /* Whitespace */);
      assert.strictEqual(
        nonWs[0]?.type,
        0 /* Keyword */,
        `"${kw}" should be tokenized as Keyword`
      );
    }
  });
  test("tokenizes numbers correctly", () => {
    const tokens = analyzer.tokenize("42 3.14 0xFF 1e10");
    const nums = tokens.filter((t) => t.type === 3 /* Number */);
    assert.ok(nums.length >= 4, `Expected at least 4 numbers, got ${nums.length}`);
  });
  test("tokenizes operators", () => {
    const tokens = analyzer.tokenize("x + y - z * w / q");
    const ops = tokens.filter((t) => t.type === 5 /* Operator */);
    assert.ok(ops.length >= 4);
  });
  test("tracks line numbers correctly", () => {
    const tokens = analyzer.tokenize("local a\nlocal b\nlocal c");
    const identifiers = tokens.filter(
      (t) => t.type === 1 /* Identifier */
    );
    assert.strictEqual(identifiers[0].line, 0);
    assert.strictEqual(identifiers[1].line, 1);
    assert.strictEqual(identifiers[2].line, 2);
  });
  test("handles escaped characters in strings", () => {
    const tokens = analyzer.tokenize('"hello\\"world"');
    const strs = tokens.filter((t) => t.type === 2 /* String */);
    assert.strictEqual(strs.length, 1);
  });
  test("tokenizes long bracket strings", () => {
    const tokens = analyzer.tokenize("[[multi\nline\nstring]]");
    const strs = tokens.filter((t) => t.type === 2 /* String */);
    assert.strictEqual(strs.length, 1);
    assert.ok(strs[0].value.includes("multi"));
  });
});
suite("LuaParser \u2014 analyze", () => {
  test("finds local variable symbols", () => {
    const info = analyzer.analyze("local x = 42\nlocal y = 10");
    const locals = info.symbols.filter((s) => s.kind === "local");
    assert.ok(locals.length >= 2);
    const names = locals.map((s) => s.name);
    assert.ok(names.includes("x"));
    assert.ok(names.includes("y"));
  });
  test("finds function definitions", () => {
    const info = analyzer.analyze(
      "function greet(name)\n  print(name)\nend"
    );
    const fns = info.symbols.filter((s) => s.kind === "function");
    assert.ok(fns.length >= 1);
    assert.strictEqual(fns[0].name, "greet");
  });
  test("finds local functions", () => {
    const info = analyzer.analyze(
      "local function helper(a, b)\n  return a + b\nend"
    );
    const fns = info.symbols.filter(
      (s) => s.kind === "function" && s.isLocal
    );
    assert.ok(fns.length >= 1);
    assert.strictEqual(fns[0].name, "helper");
  });
  test("finds method definitions (colon syntax)", () => {
    const info = analyzer.analyze(
      "function Player:update(dt)\n  self.x = dt\nend"
    );
    const methods = info.symbols.filter((s) => s.kind === "method");
    assert.ok(methods.length >= 1);
  });
  test("detects require statements", () => {
    const info = analyzer.analyze('local utils = require("mylib.utils")');
    assert.ok(info.requires.length >= 1);
    assert.strictEqual(info.requires[0].modulePath, "mylib.utils");
    assert.strictEqual(info.requires[0].localName, "utils");
  });
  test("detects class patterns", () => {
    const info = analyzer.analyze(
      [
        "local Enemy = {}",
        "Enemy.__index = Enemy",
        "function Enemy:new(hp)",
        "  return setmetatable({hp = hp}, Enemy)",
        "end"
      ].join("\n")
    );
    assert.ok(info.classes.length >= 1);
    assert.strictEqual(info.classes[0].name, "Enemy");
  });
  test("tracks scopes", () => {
    const info = analyzer.analyze(
      [
        "function outer()",
        "  local x = 1",
        "  function inner()",
        "    local y = 2",
        "  end",
        "end"
      ].join("\n")
    );
    assert.ok(info.scopes.length >= 2);
  });
  test("collects comments", () => {
    const info = analyzer.analyze(
      [
        "-- This is a comment",
        "local x = 1",
        "--- Docstring style",
        "function foo() end"
      ].join("\n")
    );
    assert.ok(info.comments.length >= 2);
  });
  test("handles empty document", () => {
    const info = analyzer.analyze("");
    assert.strictEqual(info.symbols.length, 0);
    assert.strictEqual(info.requires.length, 0);
  });
});
suite("LuaParser \u2014 utility methods", () => {
  test("getSymbolAt returns symbol at position", () => {
    const info = analyzer.analyze("local x = 42");
    const sym = analyzer.getSymbolAt(info, 0, 6);
    assert.ok(sym);
    assert.strictEqual(sym.name, "x");
  });
  test("getSymbolAt returns undefined for non-symbol position", () => {
    const info = analyzer.analyze("local x = 42");
    const sym = analyzer.getSymbolAt(info, 0, 0);
  });
  test("getScopeAt returns enclosing scope", () => {
    const info = analyzer.analyze(
      "function foo()\n  local x = 1\nend"
    );
    const scope = analyzer.getScopeAt(info, 1);
    assert.ok(scope);
    assert.strictEqual(scope.kind, "function");
  });
  test("getVisibleLocals returns locals visible at line", () => {
    const info = analyzer.analyze(
      [
        "local a = 1",
        "local b = 2",
        "local c = 3"
      ].join("\n")
    );
    const locals = analyzer.getVisibleLocals(info, 2);
    const names = locals.map((s) => s.name);
    assert.ok(names.includes("a"));
    assert.ok(names.includes("b"));
  });
  test("findReferencesInDocument finds all occurrences", () => {
    const text = "local x = 1\nprint(x)\nx = x + 1";
    const refs = analyzer.findReferencesInDocument(text, "x");
    assert.ok(refs.length >= 3);
  });
  test("getWordAtPosition returns word under cursor", () => {
    const text = "local myVar = 42";
    const word = analyzer.getWordAtPosition(text, 0, 8);
    assert.strictEqual(word, "myVar");
  });
  test("getWordAtPosition returns empty string in whitespace", () => {
    const text = "local   x";
    const word = analyzer.getWordAtPosition(text, 0, 6);
    assert.strictEqual(word, "");
  });
  test("getFunctionCallContext detects function call", () => {
    const text = "print(x, y, z)";
    const ctx = analyzer.getFunctionCallContext(text, 0, 9);
    assert.ok(ctx);
    assert.strictEqual(ctx.functionName, "print");
  });
  test("getFunctionCallContext returns undefined outside call", () => {
    const text = "local x = 42";
    const ctx = analyzer.getFunctionCallContext(text, 0, 5);
    assert.strictEqual(ctx, void 0);
  });
});
//# sourceMappingURL=luaParser.test.js.map
