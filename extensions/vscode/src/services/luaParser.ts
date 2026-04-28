// ── Token types ──────────────────────────────────────────────
import { LUREK_CALLBACK_NAMES } from "../generated/lurekApiData.js";

export enum TokenType {
  Keyword,
  Identifier,
  String,
  Number,
  Comment,
  Operator,
  Punctuation,
  Whitespace,
  EOF,
}

export interface Token {
  type: TokenType;
  value: string;
  line: number;
  column: number;
  length: number;
}

// ── Symbol and scope types ───────────────────────────────────

export interface LuaSymbol {
  name: string;
  kind: "function" | "local" | "global" | "table" | "method" | "parameter" | "field";
  line: number;
  column: number;
  endLine?: number;
  scope?: string;
  type?: string;
  description?: string;
  parameters?: string[];
  isLocal: boolean;
}

export interface RequireInfo {
  modulePath: string;
  localName: string;
  line: number;
  column: number;
}

export interface ScopeInfo {
  name: string;
  startLine: number;
  endLine: number;
  kind: "function" | "do" | "if" | "for" | "while" | "repeat";
}

export interface CommentInfo {
  text: string;
  line: number;
  isBlock: boolean;
  isLuaCATS: boolean;
}

export interface ClassInfo {
  name: string;
  methods: LuaSymbol[];
  fields: string[];
  line: number;
}

export interface LuaDocumentInfo {
  symbols: LuaSymbol[];
  requires: RequireInfo[];
  callbacks: LuaSymbol[];
  scopes: ScopeInfo[];
  comments: CommentInfo[];
  classes: ClassInfo[];
}

// ── Constants ────────────────────────────────────────────────

const LUA_KEYWORDS = new Set([
  "and", "break", "do", "else", "elseif", "end", "false", "for",
  "function", "goto", "if", "in", "local", "nil", "not", "or",
  "repeat", "return", "then", "true", "until", "while",
]);


const OPERATORS = new Set([
  "+", "-", "*", "/", "%", "^", "#",
  "==", "~=", "<", ">", "<=", ">=",
  "=", "..", "...",
  "//",
]);

const PUNCTUATION = new Set([
  "(", ")", "{", "}", "[", "]",
  ";", ":", ",", ".",
]);

// ── Tokenizer ────────────────────────────────────────────────

export class LuaDocumentAnalyzer {
  tokenize(text: string): Token[] {
    const tokens: Token[] = [];
    const len = text.length;
    let pos = 0;
    let line = 0;
    let col = 0;

    while (pos < len) {
      const ch = text[pos];

      // Whitespace
      if (ch === " " || ch === "\t" || ch === "\r" || ch === "\n") {
        const start = pos;
        const startLine = line;
        const startCol = col;
        while (pos < len && (text[pos] === " " || text[pos] === "\t" || text[pos] === "\r" || text[pos] === "\n")) {
          if (text[pos] === "\n") { line++; col = 0; } else { col++; }
          pos++;
        }
        tokens.push({ type: TokenType.Whitespace, value: text.slice(start, pos), line: startLine, column: startCol, length: pos - start });
        continue;
      }

      // Comments
      if (ch === "-" && pos + 1 < len && text[pos + 1] === "-") {
        const startLine = line;
        const startCol = col;

        // Block comment --[[ ... ]] or --[=[ ... ]=]
        if (pos + 2 < len && text[pos + 2] === "[") {
          const level = this.countLongBracketLevel(text, pos + 2);
          if (level >= 0) {
            const closing = "]" + "=".repeat(level) + "]";
            const endIdx = text.indexOf(closing, pos + 4 + level);
            const end = endIdx >= 0 ? endIdx + closing.length : len;
            const value = text.slice(pos, end);
            const nlCount = countNewlines(value);
            tokens.push({ type: TokenType.Comment, value, line: startLine, column: startCol, length: end - pos });
            for (let i = pos; i < end; i++) {
              if (text[i] === "\n") { line++; col = 0; } else { col++; }
            }
            pos = end;
            continue;
          }
        }

        // Line comment
        const nlIdx = text.indexOf("\n", pos);
        const end = nlIdx >= 0 ? nlIdx : len;
        const value = text.slice(pos, end);
        tokens.push({ type: TokenType.Comment, value, line: startLine, column: startCol, length: end - pos });
        col += end - pos;
        pos = end;
        continue;
      }

      // Strings: long strings [[...]], [=[...]=]
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
            if (text[i] === "\n") { line++; col = 0; } else { col++; }
          }
          tokens.push({ type: TokenType.String, value, line: startLine, column: startCol, length: end - pos });
          pos = end;
          continue;
        }
      }

      // Strings: "..." and '...'
      if (ch === '"' || ch === "'") {
        const startLine = line;
        const startCol = col;
        const quote = ch;
        let end = pos + 1;
        while (end < len) {
          if (text[end] === "\\") { end += 2; continue; }
          if (text[end] === quote) { end++; break; }
          if (text[end] === "\n") break; // unterminated
          end++;
        }
        const value = text.slice(pos, end);
        tokens.push({ type: TokenType.String, value, line: startLine, column: startCol, length: end - pos });
        col += end - pos;
        pos = end;
        continue;
      }

      // Numbers: 0x, 0b, decimals, floats with exponent
      if (isDigit(ch) || (ch === "." && pos + 1 < len && isDigit(text[pos + 1]))) {
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
        tokens.push({ type: TokenType.Number, value, line: startLine, column: startCol, length: end - pos });
        col += end - pos;
        pos = end;
        continue;
      }

      // Identifiers and keywords
      if (isIdentStart(ch)) {
        const startCol = col;
        let end = pos + 1;
        while (end < len && isIdentPart(text[end])) end++;
        const value = text.slice(pos, end);
        const type = LUA_KEYWORDS.has(value) ? TokenType.Keyword : TokenType.Identifier;
        tokens.push({ type, value, line, column: startCol, length: end - pos });
        col += end - pos;
        pos = end;
        continue;
      }

      // Multi-char operators
      if (pos + 2 < len) {
        const three = text.slice(pos, pos + 3);
        if (three === "...") {
          tokens.push({ type: TokenType.Operator, value: three, line, column: col, length: 3 });
          col += 3; pos += 3; continue;
        }
      }
      if (pos + 1 < len) {
        const two = text.slice(pos, pos + 2);
        if (OPERATORS.has(two)) {
          tokens.push({ type: TokenType.Operator, value: two, line, column: col, length: 2 });
          col += 2; pos += 2; continue;
        }
      }

      // Single-char operators/punctuation
      if (OPERATORS.has(ch)) {
        tokens.push({ type: TokenType.Operator, value: ch, line, column: col, length: 1 });
        col++; pos++; continue;
      }
      if (PUNCTUATION.has(ch)) {
        tokens.push({ type: TokenType.Punctuation, value: ch, line, column: col, length: 1 });
        col++; pos++; continue;
      }

      // Unknown character — skip
      col++;
      pos++;
    }

    tokens.push({ type: TokenType.EOF, value: "", line, column: col, length: 0 });
    return tokens;
  }

  // ── Document analysis ──────────────────────────────────────

  analyze(text: string): LuaDocumentInfo {
    const tokens = this.tokenize(text);
    const symbols: LuaSymbol[] = [];
    const requires: RequireInfo[] = [];
    const callbacks: LuaSymbol[] = [];
    const scopes: ScopeInfo[] = [];
    const comments: CommentInfo[] = [];

    // Collect comments first
    for (const tok of tokens) {
      if (tok.type === TokenType.Comment) {
        const stripped = tok.value.replace(/^--\[=*\[/, "").replace(/\]=*\]$/, "").replace(/^--/, "").trim();
        comments.push({
          text: stripped,
          line: tok.line,
          isBlock: tok.value.startsWith("--["),
          isLuaCATS: tok.value.startsWith("---@"),
        });
      }
    }

    // Filter to non-whitespace, non-comment tokens for analysis
    const toks = tokens.filter(t => t.type !== TokenType.Whitespace && t.type !== TokenType.Comment);

    const scopeStack: { name: string; startLine: number; kind: ScopeInfo["kind"] }[] = [];
    let i = 0;

    const peek = (offset = 0): Token | undefined => toks[i + offset];
    const match = (type: TokenType, value?: string): boolean => {
      const t = peek();
      if (!t) return false;
      if (t.type !== type) return false;
      if (value !== undefined && t.value !== value) return false;
      return true;
    };
    const advance = (): Token => toks[i++];

    const getPrecedingComment = (targetLine: number): string | undefined => {
      for (let c = comments.length - 1; c >= 0; c--) {
        if (comments[c].line === targetLine - 1 || comments[c].line === targetLine) {
          return comments[c].text;
        }
      }
      return undefined;
    };

    while (i < toks.length && peek()?.type !== TokenType.EOF) {
      const cur = peek()!;

      // ── local declarations ──
      if (match(TokenType.Keyword, "local")) {
        const localTok = advance();

        // local function name(...)
        if (match(TokenType.Keyword, "function")) {
          advance();
          if (peek()?.type === TokenType.Identifier) {
            const nameTok = advance();
            const params = this.parseParamList(toks, i);
            i = params.nextIndex;
            const desc = getPrecedingComment(localTok.line);
            const sym: LuaSymbol = {
              name: nameTok.value,
              kind: "function",
              line: nameTok.line,
              column: nameTok.column,
              scope: scopeStack.length > 0 ? scopeStack[scopeStack.length - 1].name : undefined,
              parameters: params.names,
              isLocal: true,
              description: desc,
            };
            symbols.push(sym);
            // Add parameters as symbols
            for (const pName of params.names) {
              symbols.push({
                name: pName,
                kind: "parameter",
                line: nameTok.line,
                column: nameTok.column,
                scope: nameTok.value,
                isLocal: true,
              });
            }
            scopeStack.push({ name: nameTok.value, startLine: nameTok.line, kind: "function" });
          }
          continue;
        }

        // local name = ...
        if (peek()?.type === TokenType.Identifier) {
          const nameTok = advance();

          // local name = require("...")
          if (match(TokenType.Operator, "=")) {
            advance();
            if (peek()?.type === TokenType.Identifier && peek()?.value === "require") {
              advance();
              if (match(TokenType.Punctuation, "(")) {
                advance();
                if (peek()?.type === TokenType.String) {
                  const strTok = advance();
                  const modPath = strTok.value.slice(1, -1);
                  requires.push({
                    modulePath: modPath,
                    localName: nameTok.value,
                    line: nameTok.line,
                    column: nameTok.column,
                  });
                }
              }
            }

            // local name = {} — table
            if (peek()?.type === TokenType.Punctuation && peek()?.value === "{") {
              symbols.push({
                name: nameTok.value,
                kind: "table",
                line: nameTok.line,
                column: nameTok.column,
                scope: scopeStack.length > 0 ? scopeStack[scopeStack.length - 1].name : undefined,
                isLocal: true,
                description: getPrecedingComment(nameTok.line),
              });
              continue;
            }
          }

          symbols.push({
            name: nameTok.value,
            kind: "local",
            line: nameTok.line,
            column: nameTok.column,
            scope: scopeStack.length > 0 ? scopeStack[scopeStack.length - 1].name : undefined,
            isLocal: true,
            description: getPrecedingComment(nameTok.line),
          });

          // Handle multiple names: local a, b, c = ...
          while (match(TokenType.Punctuation, ",")) {
            advance();
            if (peek()?.type === TokenType.Identifier) {
              const extraTok = advance();
              symbols.push({
                name: extraTok.value,
                kind: "local",
                line: extraTok.line,
                column: extraTok.column,
                scope: scopeStack.length > 0 ? scopeStack[scopeStack.length - 1].name : undefined,
                isLocal: true,
              });
            }
          }
        }
        continue;
      }

      // ── function declarations ──
      if (match(TokenType.Keyword, "function")) {
        const funcTok = advance();

        if (peek()?.type === TokenType.Identifier) {
          const nameTok = advance();
          let fullName = nameTok.value;
          let isMethod = false;
          let objectType: string | undefined;

          // function lurek.update(dt) or function Class:method()
          while (true) {
            if (match(TokenType.Punctuation, ".")) {
              advance();
              if (peek()?.type === TokenType.Identifier) {
                fullName += "." + advance().value;
              }
            } else if (match(TokenType.Punctuation, ":")) {
              advance();
              isMethod = true;
              objectType = fullName;
              if (peek()?.type === TokenType.Identifier) {
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

          const sym: LuaSymbol = {
            name: shortName,
            kind: isMethod ? "method" : "function",
            line: funcTok.line,
            column: funcTok.column,
            scope: scopeStack.length > 0 ? scopeStack[scopeStack.length - 1].name : undefined,
            type: objectType,
            parameters: params.names,
            isLocal: false,
            description: getPrecedingComment(funcTok.line),
          };
          symbols.push(sym);

          // Check for lurek.* callbacks
          if (fullName.startsWith("lurek.") && LUREK_CALLBACK_NAMES.has(shortName)) {
            callbacks.push(sym);
          }

          // Add parameters
          for (const pName of params.names) {
            symbols.push({
              name: pName,
              kind: "parameter",
              line: funcTok.line,
              column: funcTok.column,
              scope: shortName,
              isLocal: true,
            });
          }

          scopeStack.push({ name: shortName, startLine: funcTok.line, kind: "function" });
          continue;
        }

        // Anonymous function — still creates a scope
        scopeStack.push({ name: "<anonymous>", startLine: funcTok.line, kind: "function" });
        // Skip past param list
        if (match(TokenType.Punctuation, "(")) {
          const params = this.parseParamList(toks, i);
          i = params.nextIndex;
        }
        continue;
      }

      // ── Assignment patterns: lurek.update = function(...) ──
      if (cur.type === TokenType.Identifier) {
        // Look for patterns like: name.name.name = function | table = {} | Class.__index = Class
        const startIdx = i;
        let fullName = cur.value;
        let tempI = i + 1;
        let isColon = false;

        while (tempI < toks.length) {
          if (toks[tempI]?.value === "." && toks[tempI + 1]?.type === TokenType.Identifier) {
            fullName += "." + toks[tempI + 1].value;
            tempI += 2;
          } else if (toks[tempI]?.value === ":" && toks[tempI + 1]?.type === TokenType.Identifier) {
            fullName += ":" + toks[tempI + 1].value;
            isColon = true;
            tempI += 2;
          } else {
            break;
          }
        }

        // Check for = after the dotted name
        if (tempI < toks.length && toks[tempI]?.value === "=") {
          const eqIdx = tempI;
          const afterEq = toks[eqIdx + 1];

          // lurek.update = function(dt)
          if (afterEq?.type === TokenType.Keyword && afterEq.value === "function") {
            i = eqIdx + 2; // past '=' and 'function'
            const params = this.parseParamList(toks, i);
            i = params.nextIndex;

            const lastDot = fullName.lastIndexOf(".");
            const shortName = lastDot >= 0 ? fullName.slice(lastDot + 1) : fullName;

            const sym: LuaSymbol = {
              name: shortName,
              kind: "function",
              line: cur.line,
              column: cur.column,
              parameters: params.names,
              isLocal: false,
              description: getPrecedingComment(cur.line),
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
                isLocal: true,
              });
            }

            scopeStack.push({ name: shortName, startLine: cur.line, kind: "function" });
            continue;
          }

          // Class.__index = Class — detect class pattern
          if (fullName.endsWith(".__index") && afterEq?.type === TokenType.Identifier) {
            i = eqIdx + 2;
            // Already handled below in detectClasses
            continue;
          }
        }

        // Not an interesting assignment — just skip this token
        advance();
        continue;
      }

      // ── Scope tracking: do/if/for/while/repeat ──
      if (cur.type === TokenType.Keyword) {
        if (cur.value === "do") {
          scopeStack.push({ name: "do", startLine: cur.line, kind: "do" });
          advance(); continue;
        }
        if (cur.value === "if" || cur.value === "elseif") {
          if (cur.value === "if") {
            scopeStack.push({ name: "if", startLine: cur.line, kind: "if" });
          }
          advance(); continue;
        }
        if (cur.value === "for") {
          scopeStack.push({ name: "for", startLine: cur.line, kind: "for" });
          advance(); continue;
        }
        if (cur.value === "while") {
          scopeStack.push({ name: "while", startLine: cur.line, kind: "while" });
          advance(); continue;
        }
        if (cur.value === "repeat") {
          scopeStack.push({ name: "repeat", startLine: cur.line, kind: "repeat" });
          advance(); continue;
        }
        if (cur.value === "end" || cur.value === "until") {
          const popped = scopeStack.pop();
          if (popped) {
            scopes.push({
              name: popped.name,
              startLine: popped.startLine,
              endLine: cur.line,
              kind: popped.kind,
            });
            // Update endLine on matching function symbol
            for (let s = symbols.length - 1; s >= 0; s--) {
              if (symbols[s].kind === "function" && symbols[s].name === popped.name && symbols[s].line === popped.startLine) {
                symbols[s].endLine = cur.line;
                break;
              }
            }
          }
          advance(); continue;
        }
      }

      advance();
    }

    // Close any unclosed scopes at EOF
    const lastLine = text.split("\n").length - 1;
    while (scopeStack.length > 0) {
      const popped = scopeStack.pop()!;
      scopes.push({ name: popped.name, startLine: popped.startLine, endLine: lastLine, kind: popped.kind });
    }

    const baseInfo: LuaDocumentInfo = {
      symbols,
      requires,
      callbacks,
      scopes,
      comments,
      classes: [],
    };
    baseInfo.classes = this.detectClasses(baseInfo);

    return baseInfo;
  }

  // ── Position-based queries ─────────────────────────────────

  getSymbolAt(info: LuaDocumentInfo, line: number, column: number): LuaSymbol | undefined {
    for (const sym of info.symbols) {
      if (sym.line === line && column >= sym.column && column < sym.column + sym.name.length) {
        return sym;
      }
    }
    return undefined;
  }

  getScopeAt(info: LuaDocumentInfo, line: number): ScopeInfo | undefined {
    let best: ScopeInfo | undefined;
    for (const scope of info.scopes) {
      if (line >= scope.startLine && line <= scope.endLine) {
        if (!best || scope.startLine > best.startLine) {
          best = scope;
        }
      }
    }
    return best;
  }

  findReferencesInDocument(text: string, symbolName: string): { line: number; column: number }[] {
    const results: { line: number; column: number }[] = [];
    const tokens = this.tokenize(text);
    for (const tok of tokens) {
      if (tok.type === TokenType.Identifier && tok.value === symbolName) {
        results.push({ line: tok.line, column: tok.column });
      }
    }
    return results;
  }

  getVisibleLocals(info: LuaDocumentInfo, line: number): LuaSymbol[] {
    const scope = this.getScopeAt(info, line);
    return info.symbols.filter(sym => {
      if (!sym.isLocal) return false;
      if (sym.line > line) return false;
      // sym is in scope if it was declared in the same scope or a parent scope
      if (sym.scope && scope) {
        return sym.scope === scope.name || !sym.scope;
      }
      return true;
    });
  }

  detectClasses(info: LuaDocumentInfo): ClassInfo[] {
    const classes: ClassInfo[] = [];
    const classNames = new Set<string>();

    // Look for Class.__index = Class pattern in symbols
    for (const sym of info.symbols) {
      if (sym.kind === "method" && sym.type) {
        classNames.add(sym.type);
      }
    }

    // Also check for setmetatable patterns (detected during analysis)
    // Look for tables that have methods defined on them
    for (const name of classNames) {
      const methods = info.symbols.filter(s => s.kind === "method" && s.type === name);
      const fields = info.symbols.filter(s => s.kind === "field" && s.scope === name).map(s => s.name);
      const firstMethod = methods[0];
      if (firstMethod) {
        classes.push({
          name,
          methods,
          fields,
          line: firstMethod.line,
        });
      }
    }

    return classes;
  }

  getWordAtPosition(text: string, line: number, column: number): string {
    const lines = text.split("\n");
    if (line < 0 || line >= lines.length) return "";
    const lineText = lines[line];
    if (column < 0 || column >= lineText.length) return "";

    let start = column;
    let end = column;

    while (start > 0 && isIdentPart(lineText[start - 1])) start--;
    while (end < lineText.length && isIdentPart(lineText[end])) end++;

    // Extend left through dots/colons for lurek.graphics.draw style
    while (start > 0 && (lineText[start - 1] === "." || lineText[start - 1] === ":")) {
      start--;
      while (start > 0 && isIdentPart(lineText[start - 1])) start--;
    }

    return lineText.slice(start, end);
  }

  getFunctionCallContext(text: string, line: number, column: number): { functionName: string; paramIndex: number } | undefined {
    const lines = text.split("\n");
    if (line < 0 || line >= lines.length) return undefined;

    // Walk backwards from cursor to find the opening paren
    const lineText = lines[line];
    let parenDepth = 0;
    let paramIndex = 0;
    let searchLine = line;
    let searchCol = Math.min(column, lineText.length) - 1;

    // Count commas and find opening paren on current line first
    while (searchLine >= 0) {
      const sLine = lines[searchLine];
      const startCol = searchLine === line ? searchCol : sLine.length - 1;

      for (let c = startCol; c >= 0; c--) {
        const ch = sLine[c];
        if (ch === ")") { parenDepth++; continue; }
        if (ch === "(") {
          if (parenDepth === 0) {
            // Found the opening paren — get function name before it
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
            return undefined;
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

    return undefined;
  }

  isInsideString(text: string, line: number, column: number): boolean {
    const tokens = this.tokenize(text);
    for (const tok of tokens) {
      if (tok.type !== TokenType.String) continue;
      const endLine = tok.line + countNewlines(tok.value);
      // Single-line string
      if (tok.line === endLine) {
        if (tok.line === line && column >= tok.column && column < tok.column + tok.length) {
          return true;
        }
      } else {
        // Multi-line string
        if (line > tok.line && line < endLine) return true;
        if (line === tok.line && column >= tok.column) return true;
        if (line === endLine) {
          // Calculate end column
          const lastNl = tok.value.lastIndexOf("\n");
          const endCol = tok.value.length - lastNl - 1;
          if (column < endCol) return true;
        }
      }
    }
    return false;
  }

  isInsideComment(text: string, line: number, column: number): boolean {
    const tokens = this.tokenize(text);
    for (const tok of tokens) {
      if (tok.type !== TokenType.Comment) continue;
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

  private countLongBracketLevel(text: string, pos: number): number {
    if (text[pos] !== "[") return -1;
    let level = 0;
    let p = pos + 1;
    while (p < text.length && text[p] === "=") { level++; p++; }
    if (p < text.length && text[p] === "[") return level;
    return -1;
  }

  private parseParamList(toks: Token[], startIndex: number): { names: string[]; nextIndex: number } {
    const names: string[] = [];
    let i = startIndex;
    if (i >= toks.length || toks[i]?.value !== "(") return { names, nextIndex: i };
    i++; // skip '('

    while (i < toks.length && toks[i]?.value !== ")") {
      if (toks[i]?.type === TokenType.Identifier) {
        names.push(toks[i].value);
      } else if (toks[i]?.value === "...") {
        names.push("...");
      }
      i++;
    }

    if (i < toks.length && toks[i]?.value === ")") i++; // skip ')'
    return { names, nextIndex: i };
  }
}

// ── Character classification helpers ─────────────────────────

function isDigit(ch: string): boolean {
  return ch >= "0" && ch <= "9";
}

function isHexDigit(ch: string): boolean {
  return isDigit(ch) || (ch >= "a" && ch <= "f") || (ch >= "A" && ch <= "F");
}

function isIdentStart(ch: string): boolean {
  return (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z") || ch === "_";
}

function isIdentPart(ch: string): boolean {
  return isIdentStart(ch) || isDigit(ch);
}

function countNewlines(text: string): number {
  let count = 0;
  for (let i = 0; i < text.length; i++) {
    if (text[i] === "\n") count++;
  }
  return count;
}
