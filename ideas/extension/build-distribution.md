# Build and Distribution Analysis

## Current Build State

### Documented (00-architecture.md)

| Aspect | Planned |
|---|---|
| Bundler | esbuild |
| Output | `dist/extension.js` (single bundle) |
| Config | `esbuild.js` build script |

### Actual

| Aspect | Current |
|---|---|
| Compiler | tsc (TypeScript compiler) |
| Output | `out/` directory (many JS files) |
| Config | `tsconfig.json` |

### package.json vs package2.json Conflict

| Field | package.json (v1) | package2.json (v2) |
|---|---|---|
| name | luna2d-vscode | luna-toolkit |
| version | 0.1.0 | 0.9.0 |
| main | ./out/extension.js | ./dist/extension.js |
| displayName | Luna2D | Luna Toolkit |
| dependencies | @modelcontextprotocol/sdk | @modelcontextprotocol/sdk + more |

---

## Improvement Ideas

### 1. Migrate to esbuild

**Action**: Create `esbuild.js` build script:

```javascript
const esbuild = require('esbuild');

esbuild.build({
  entryPoints: ['src/extension.ts'],
  bundle: true,
  outfile: 'dist/extension.js',
  external: ['vscode'],
  format: 'cjs',
  platform: 'node',
  target: 'node18',
  sourcemap: true,
  minify: process.env.NODE_ENV === 'production',
}).catch(() => process.exit(1));
```

**Benefits**:
- Build time: ~5s (tsc) → ~100ms (esbuild)
- Output: many files → single bundle
- Size: ~2MB (tsc) → ~500KB (esbuild, minified)
- Tree shaking: dead code eliminated

### 2. Resolve the v1/v2 Split

**Action plan**:
1. Rename `extension2.ts` → `extension.ts` (backup v1 first)
2. Rename `package2.json` → `package.json`
3. Rename `README2.md` → `README.md`
4. Rename `.vscodeignore2` → `.vscodeignore`
5. Delete or archive v1 files
6. Update `main` field in package.json to match build system
7. Update all tests and CI to reference canonical files

### 3. Publishing Pipeline

**Not documented anywhere.** Need:

1. **Marketplace account**: Create publisher on VS Code Marketplace
2. **VSIX packaging**: `vsce package` → `luna-toolkit-0.9.0.vsix`
3. **CI pipeline**: Build → test → package → publish
4. **Pre-publish checklist**:
   - All tests pass
   - No hardcoded file paths
   - Icons and media exist
   - README is user-facing (not developer docs)
   - CHANGELOG.md exists
   - LICENSE included in package

### 4. Extension Size Optimization

**Concerns**:
- 29 editor files with inline HTML templates → large source
- Shared CSS duplicated in every editor
- API data hardcoded in TypeScript → compiled into bundle

**Optimizations**:
- Extract HTML templates to separate .html files (not compiled into JS)
- Shared CSS as a single file loaded at runtime
- API data as external JSON (loaded, not compiled)
- Consider code splitting: lazy-load editors
- Use .vscodeignore to exclude dev files from VSIX

### 5. Development Workflow

**Improvements**:
- Add `npm run watch` for development (esbuild watch mode)
- Add `npm run lint` with ESLint
- Add `npm run typecheck` for type verification without build
- Add `F5 launch config` for extension debugging
- Add `npm run package` for VSIX creation

### 6. Dependency Audit

**Current dependencies** (from package.json):
- `@modelcontextprotocol/sdk` — MCP protocol

**Missing from package.json but used in code**:
- Needs audit of all `require()` and `import` statements
- Check if any runtime dependencies are missing
- Check for unused dependencies
- Pin dependency versions for reproducibility

### 7. Extension API Version Planning

**Current**: vscode engine `^1.90.0`

**Check**: Are all used VS Code APIs available in v1.90.0? Some features may require newer versions:
- Custom editor API (stable since 1.70)
- Webview debug tools (newer)
- InlayHints API (stable since 1.67)
- SemanticTokens (stable since 1.70)

### 8. Media Assets

**Referenced but missing**:
- `media/luna-logo.png` — extension icon
- `media/sidebar-icon.svg` — sidebar icon

**Action**: Create or generate these assets. Use the engine's existing `assets/icon.png` as base.
