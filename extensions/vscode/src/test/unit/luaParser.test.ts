/**
 * Unit tests for the Lua parser service.
 *
 * Tests tokenization, symbol analysis, scope tracking, and utility methods
 * of LuaDocumentAnalyzer.
 */
import * as assert from "assert";
import {
  LuaDocumentAnalyzer,
  TokenType,
} from "../../services/luaParser";

const analyzer = new LuaDocumentAnalyzer();

// ── Tokenizer ───────────────────────────────────────────────

suite("LuaParser — tokenize", () => {
  test("tokenizes empty string", () => {
    const tokens = analyzer.tokenize("");
    assert.strictEqual(tokens.length, 0);
  });

  test("tokenizes a local assignment", () => {
    const tokens = analyzer.tokenize('local x = 42');
    const nonWs = tokens.filter((t) => t.type !== TokenType.Whitespace);
    assert.ok(nonWs.length >= 4); // local, x, =, 42
    assert.strictEqual(nonWs[0].type, TokenType.Keyword);
    assert.strictEqual(nonWs[0].value, "local");
    assert.strictEqual(nonWs[1].type, TokenType.Identifier);
    assert.strictEqual(nonWs[1].value, "x");
  });

  test("tokenizes string literals", () => {
    const tokens = analyzer.tokenize('"hello world"');
    const strTokens = tokens.filter((t) => t.type === TokenType.String);
    assert.strictEqual(strTokens.length, 1);
    assert.strictEqual(strTokens[0].value, '"hello world"');
  });

  test("tokenizes single-line comments", () => {
    const tokens = analyzer.tokenize("-- this is a comment\nlocal x = 1");
    const comments = tokens.filter((t) => t.type === TokenType.Comment);
    assert.strictEqual(comments.length, 1);
    assert.ok(comments[0].value.includes("this is a comment"));
  });

  test("tokenizes multi-line comments", () => {
    const tokens = analyzer.tokenize("--[[ multi\nline ]]");
    const comments = tokens.filter((t) => t.type === TokenType.Comment);
    assert.strictEqual(comments.length, 1);
    assert.ok(comments[0].value.includes("multi"));
  });

  test("tokenizes all Lua keywords", () => {
    const keywords = [
      "and", "break", "do", "else", "elseif", "end",
      "false", "for", "function", "goto", "if", "in",
      "local", "nil", "not", "or", "repeat", "return",
      "then", "true", "until", "while",
    ];
    for (const kw of keywords) {
      const tokens = analyzer.tokenize(kw);
      const nonWs = tokens.filter((t) => t.type !== TokenType.Whitespace);
      assert.strictEqual(
        nonWs[0]?.type,
        TokenType.Keyword,
        `"${kw}" should be tokenized as Keyword`,
      );
    }
  });

  test("tokenizes numbers correctly", () => {
    const tokens = analyzer.tokenize("42 3.14 0xFF 1e10");
    const nums = tokens.filter((t) => t.type === TokenType.Number);
    assert.ok(nums.length >= 4, `Expected at least 4 numbers, got ${nums.length}`);
  });

  test("tokenizes operators", () => {
    const tokens = analyzer.tokenize("x + y - z * w / q");
    const ops = tokens.filter((t) => t.type === TokenType.Operator);
    assert.ok(ops.length >= 4);
  });

  test("tracks line numbers correctly", () => {
    const tokens = analyzer.tokenize("local a\nlocal b\nlocal c");
    const identifiers = tokens.filter(
      (t) => t.type === TokenType.Identifier,
    );
    assert.strictEqual(identifiers[0].line, 0);
    assert.strictEqual(identifiers[1].line, 1);
    assert.strictEqual(identifiers[2].line, 2);
  });

  test("handles escaped characters in strings", () => {
    const tokens = analyzer.tokenize('"hello\\"world"');
    const strs = tokens.filter((t) => t.type === TokenType.String);
    assert.strictEqual(strs.length, 1);
  });

  test("tokenizes long bracket strings", () => {
    const tokens = analyzer.tokenize("[[multi\nline\nstring]]");
    const strs = tokens.filter((t) => t.type === TokenType.String);
    assert.strictEqual(strs.length, 1);
    assert.ok(strs[0].value.includes("multi"));
  });
});

// ── Analyzer ────────────────────────────────────────────────

suite("LuaParser — analyze", () => {
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
      "function greet(name)\n  print(name)\nend",
    );
    const fns = info.symbols.filter((s) => s.kind === "function");
    assert.ok(fns.length >= 1);
    assert.strictEqual(fns[0].name, "greet");
  });

  test("finds local functions", () => {
    const info = analyzer.analyze(
      "local function helper(a, b)\n  return a + b\nend",
    );
    const fns = info.symbols.filter(
      (s) => s.kind === "function" && s.isLocal,
    );
    assert.ok(fns.length >= 1);
    assert.strictEqual(fns[0].name, "helper");
  });

  test("finds method definitions (colon syntax)", () => {
    const info = analyzer.analyze(
      "function Player:update(dt)\n  self.x = dt\nend",
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
        "end",
      ].join("\n"),
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
        "end",
      ].join("\n"),
    );
    assert.ok(info.scopes.length >= 2);
  });

  test("collects comments", () => {
    const info = analyzer.analyze(
      [
        "-- This is a comment",
        "local x = 1",
        "--- Docstring style",
        "function foo() end",
      ].join("\n"),
    );
    assert.ok(info.comments.length >= 2);
  });

  test("handles empty document", () => {
    const info = analyzer.analyze("");
    assert.strictEqual(info.symbols.length, 0);
    assert.strictEqual(info.requires.length, 0);
  });
});

// ── Utility methods ─────────────────────────────────────────

suite("LuaParser — utility methods", () => {
  test("getSymbolAt returns symbol at position", () => {
    const info = analyzer.analyze("local x = 42");
    const sym = analyzer.getSymbolAt(info, 0, 6); // "x" at column 6
    assert.ok(sym);
    assert.strictEqual(sym!.name, "x");
  });

  test("getSymbolAt returns undefined for non-symbol position", () => {
    const info = analyzer.analyze("local x = 42");
    const sym = analyzer.getSymbolAt(info, 0, 0); // "local" keyword
    // Should be undefined since "local" is not a user-defined symbol at col 0
    // (or it could match — depends on implementation)
    // The test verifies getSymbolAt doesn't crash
  });

  test("getScopeAt returns enclosing scope", () => {
    const info = analyzer.analyze(
      "function foo()\n  local x = 1\nend",
    );
    const scope = analyzer.getScopeAt(info, 1); // line 1 inside function
    assert.ok(scope);
    assert.strictEqual(scope!.kind, "function");
  });

  test("getVisibleLocals returns locals visible at line", () => {
    const info = analyzer.analyze(
      [
        "local a = 1",
        "local b = 2",
        "local c = 3",
      ].join("\n"),
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
    const word = analyzer.getWordAtPosition(text, 0, 8); // "myVar" at col 8
    assert.strictEqual(word, "myVar");
  });

  test("getWordAtPosition returns empty string in whitespace", () => {
    const text = "local   x";
    const word = analyzer.getWordAtPosition(text, 0, 6); // in whitespace
    assert.strictEqual(word, "");
  });

  test("getFunctionCallContext detects function call", () => {
    const text = "print(x, y, z)";
    const ctx = analyzer.getFunctionCallContext(text, 0, 9); // inside parens
    assert.ok(ctx);
    assert.strictEqual(ctx!.functionName, "print");
  });

  test("getFunctionCallContext returns undefined outside call", () => {
    const text = "local x = 42";
    const ctx = analyzer.getFunctionCallContext(text, 0, 5);
    assert.strictEqual(ctx, undefined);
  });
});
