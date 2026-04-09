# Extension Testing Strategy

## Current State

**No tests exist for the extension.** There is no `test/` folder in `vscode-extension/`.

This is the largest quality gap. The extension has 90+ commands, 22 providers, 29 editors, and zero test coverage.

---

## Test Architecture

### 1. Unit Tests (Provider Logic)

Test individual providers in isolation with mock VS Code APIs.

**Priority providers to test**:

| Provider | Test Focus | Complexity |
|---|---|---|
| completion.ts | Correct completions for lurek.* prefixes | High |
| diagnostics.ts | All 9 diagnostic rules fire correctly | High |
| typeInference.ts | Factory return types resolve correctly | Medium |
| luacatsProvider.ts | Annotation parsing accuracy | Medium |
| hover.ts | Correct markdown for all API entries | Medium |
| requireGraph.ts | Cycle detection, missing module warnings | Medium |
| formatting.ts | Indent correctness, multiline handling | Medium |
| semanticTokens.ts | Token classification accuracy | Low |

**Example test structure**:
```typescript
// test/unit/completion.test.ts
import { CompletionProvider } from '../../src/providers/completion';
import { MockDocument, MockPosition } from '../mocks/vscode';

describe('CompletionProvider', () => {
  it('completes lurek.gfx.* methods', () => { ... });
  it('completes builtins after lurek.', () => { ... });
  it('does not complete outside luna namespace', () => { ... });
  it('includes parameter snippets', () => { ... });
});
```

### 2. Service Tests

| Service | Test Focus |
|---|---|
| apiData.ts | Data loading, enum definitions, callback signatures |
| luaParser.ts | Tokenization, symbol extraction, scope tracking |
| debugBridge.ts | Connection lifecycle, message parsing, timeout handling |
| statusBar.ts | State transitions, display text |
| symbolIndex.ts | Workspace indexing, query accuracy |

**luaParser.ts is the most critical** — it's 1100 lines of parsing logic that everything depends on.

### 3. Integration Tests

Test the full activation lifecycle:

```typescript
// test/integration/activation.test.ts
describe('Extension Activation', () => {
  it('registers all commands', async () => {
    const ext = vscode.extensions.getExtension('lurek2d.luna-toolkit');
    await ext.activate();
    const commands = await vscode.commands.getCommands();
    expect(commands).toContain('lurek.runGame');
    expect(commands).toContain('lurek.test.all');
    // ... verify all 90+ commands
  });

  it('registers sidebar views', () => { ... });
  it('loads API data successfully', () => { ... });
  it('creates status bar item', () => { ... });
});
```

### 4. Editor Tests

Test webview editors create correctly and respond to messages:

```typescript
// test/integration/editors.test.ts
describe('TileMapEditor', () => {
  it('creates webview panel', () => { ... });
  it('responds to tool selection message', () => { ... });
  it('exports valid Lua code', () => { ... });
  it('handles empty map gracefully', () => { ... });
});
```

### 5. Snapshot Tests

Capture expected output for regression detection:
- Completion list snapshots for known documents
- Hover content snapshots for lurek.* functions
- Diagnostic output snapshots for known-bad code

### 6. E2E Tests

Use `@vscode/test-electron` for full extension testing:
- Open a demo Lua file → verify IntelliSense works
- Run a game → verify status bar updates
- Open editor → verify webview renders

---

## Test Infrastructure

### Required Dependencies

```json
{
  "devDependencies": {
    "@vscode/test-electron": "^2.3.0",
    "mocha": "^10.0.0",
    "sinon": "^16.0.0",
    "chai": "^4.3.0",
    "@types/mocha": "^10.0.0",
    "@types/sinon": "^10.0.0"
  }
}
```

### Test Config

```json
// .vscode/settings.json (for test discovery)
{
  "mochaExplorer.files": "test/**/*.test.ts"
}
```

### Mock Infrastructure

Create `test/mocks/` with:
- `vscode.ts` — mock VS Code API (TextDocument, Position, Range, etc.)
- `apiData.ts` — mock API data service
- `debugBridge.ts` — mock TCP connection
- `filesystem.ts` — mock file system operations

### CI Integration

```yaml
# .github/workflows/extension-tests.yml
- run: cd vscode-extension && npm test
- run: cd vscode-extension && npm run lint
```

---

## Priority Order

1. **luaParser.ts** unit tests — most complex code, highest risk
2. **diagnostics.ts** unit tests — user-facing, many rules
3. **completion.ts** unit tests — most-used feature
4. **apiData.ts** unit tests — data integrity
5. **Integration: activation** — verify nothing crashes on start
6. **Editor: tileMapEditor** — most complex editor
7. **E2E: full workflow** — open file, get completions, run game

---

## Coverage Targets

| Category | Target | Rationale |
|---|---|---|
| Providers | 80% | Core user-facing features |
| Services | 90% | Data integrity critical |
| Commands | 60% | Many are simple wrappers |
| Editors | 50% | Webview testing is hard |
| Overall | 70% | Reasonable for extension |
