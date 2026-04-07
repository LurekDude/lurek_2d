# Lua Parser Service Analysis

## Current State

`services/luaParser.ts` is ~1100 lines — the **largest single file** in the extension.
It is the foundation that all language providers depend on.

### Features

- Complete Lua tokenizer (all token types)
- Multi-line string and comment handling
- Symbol collection (functions, locals, parameters)
- Scope tracking (do/if/for/while/function blocks)
- Class pattern detection (metatable-based OOP)
- Parameter extraction with position queries
- Document-level analysis cache

---

## Improvement Ideas

### 1. Incremental Parsing

**Problem**: Currently reparses the entire document on every change.

**Improvement**:
- Track changed line ranges from TextDocumentChangeEvent
- Only reparse affected scopes
- Reuse token cache for unchanged regions
- Significant speedup for large files (>500 lines)

### 2. AST Construction

**Current**: Token-based analysis without full AST.

**Improvement**:
- Build a lightweight AST (Abstract Syntax Tree)
- Support nested expressions, function composition, table construction
- Enable deeper analysis: data flow, control flow, dead code detection
- Consider using tree-sitter-lua grammar for robust parsing

### 3. Tree-Sitter Integration

**Alternative to custom parser**: Use tree-sitter-lua or WASM-compiled grammar.

**Benefits**:
- Battle-tested Lua grammar (handles all edge cases)
- Incremental parsing built-in
- Error recovery (handles incomplete/invalid code)
- Consistent with VS Code's built-in language features

**Trade-off**: Adds WASM dependency, requires different integration pattern.

### 4. LuaJIT-Specific Syntax

**Gap**: Parser may not handle LuaJIT extensions.

**LuaJIT features to support**:
- `bit.band()`, `bit.bor()`, `bit.bxor()` etc.
- `ffi.cdef`, `ffi.typeof`, `ffi.new` (if used)
- `jit.on()`, `jit.off()`, `jit.opt` (if used)
- Long long integer literals (`1LL`)
- Complex number literals (`1i`)
- `goto` and `::label::` (Lua 5.2+ / LuaJIT)

### 5. Type Flow Analysis

**Current**: Basic type inference from factory returns.

**Enhancement**: Track types through assignment chains:
```lua
local img = luna.gfx.newImage("player.png")  -- Image
local w = img:getWidth()                          -- number
local pos = luna.math.vec2(w, 0)                 -- Vec2
local x = pos.x                                  -- number
```

Each step requires knowing return types from the previous step.

### 6. Cross-File Analysis

**Gap**: Parser operates per-document.

**Improvement**:
- Build workspace-wide require() graph
- Resolve imports: `local M = require("mymodule")` → track M's type
- Support go-to-definition across files
- Support find-all-references across workspace
- Update on file changes (incremental)

### 7. Error Recovery

**Important for IDE use**: Parser must handle incomplete/broken code gracefully.

**Scenarios**:
- User is mid-typing: `luna.gfx.` → show completions despite syntax error
- Missing `end`: keep parsing subsequent code
- Unmatched parentheses: recover scope tracking
- Incomplete string: don't break tokenizer

### 8. Performance Profiling

**Action**: Profile luaParser.ts on large Lua files:
- Typical game file: 200-500 lines → should parse in < 10ms
- Large file: 1000+ lines → should parse in < 50ms
- Stress test: 5000 lines → measure and optimize

### 9. Parser Test Suite

**Critical**: The parser has zero tests. As the most complex single component, it needs the most tests.

**Test categories**:
- Token types (keywords, operators, strings, numbers, comments)
- Multi-line strings (`[[...]]` with nesting levels)
- Multi-line comments (`--[[ ... ]]`)
- Scope tracking (nested functions, closures)
- Symbol extraction (function names, parameters)
- Class detection (metatable patterns)
- Edge cases: empty file, single-line file, huge file
- Error recovery: broken syntax, incomplete code
- LuaJIT syntax extensions
- Unicode in strings and identifiers
