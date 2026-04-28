"""
Comprehensive fix script for the Lurek2D VS Code extension.
Fixes namespace, imports, paths, package.json, and esbuild config.
"""
import re, json, shutil, os

BASE = os.path.dirname(os.path.abspath(__file__))

def read(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def write(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  Written: {path}")


# ─── 1. Fix extension.ts ───────────────────────────────────────────────────────
print("\n=== Fixing extension.ts ===")
ext2 = os.path.join(BASE, 'src', 'extension.ts')
content = read(ext2)

# Replace "lurek. string literals → "lurek.
before = content.count('"lurek.')
content = re.sub(r'"lurek\.', '"lurek.', content)
after_str = content.count('"lurek.')
print(f'  String literal "lurek. → "lurek.: {before} replacements')

# Fix bad dynamic import path: ./debug/debugBridge → ./services/debugBridge
old_import = 'import("./debug/debugBridge")'
new_import = 'import("./services/debugBridge")'
n = content.count(old_import)
content = content.replace(old_import, new_import)
print(f'  Fixed bad debugBridge import: {n} replacement(s)')

write(ext2, content)


# ─── 2. Fix apiData.ts ────────────────────────────────────────────────────────
print("\n=== Fixing apiData.ts ===")
api_file = os.path.join(BASE, 'src', 'services', 'apiData.ts')
content = read(api_file)

# Replace "lurek. string literals → "lurek.
n1 = content.count('"lurek.')
content = re.sub(r'"lurek\.', '"lurek.', content)
print(f'  String literal "lurek. → "lurek.: {n1} replacements')

# Replace template literal `lurek. → `lurek.
n2 = content.count('`lurek.')
content = re.sub(r'`lurek\.', '`lurek.', content)
print(f'  Template literal `lurek. → `lurek.: {n2} replacements')

# Fix Priority 3 md path: lua_api_reference_generated.md → lua-api.md  (ALSO change method call)
old_p3 = '      const mdPath = path.join(wsRoot, "docs", "API", "lua_api_reference_generated.md");\n      if (fs.existsSync(mdPath)) {\n        try {\n          const md = fs.readFileSync(mdPath, "utf-8");\n          this.loadFromMarkdown(md);'
new_p3 = '      const mdPath = path.join(wsRoot, "docs", "API", "lua-api.md");\n      if (fs.existsSync(mdPath)) {\n        try {\n          const md = fs.readFileSync(mdPath, "utf-8");\n          this.loadFromLuaApiMd(md);'
n3 = content.count(old_p3)
content = content.replace(old_p3, new_p3)
print(f'  Fixed Priority-3 md path + method call: {n3} replacement(s)')

# Also update the comment for Priority 3
content = content.replace(
    '    // Priority 3: generated markdown in workspace',
    '    // Priority 3: docs/lua-api.md (generated reference)'
)

# Insert loadFromLuaApiMd() and parseParamStr() before loadFallback()
NEW_METHODS = '''
  // ── lua-api.md loader ─────────────────────────────────────────────────────
  // Parses the compact one-liner format used in docs/lua-api.md:
  //   lurek.MODULE.FUNCNAME( params )[ -> returnType]  -- description
  //   ObjType:methodName( params )[ -> returnType]  -- description
  private loadFromLuaApiMd(md: string): void {
    const lines = md.split("\\n");
    let currentModule: ApiModule | null = null;
    let inCodeBlock = false;

    const finishModule = (): void => {
      if (!currentModule) return;
      currentModule.totalEntries = currentModule.functions.length + currentModule.methods.length;
      currentModule.documentedEntries = [
        ...currentModule.functions,
        ...currentModule.methods,
      ].filter((f) => f.description.length > 0).length;
      this.modules.set(currentModule.name, currentModule);
    };

    for (const line of lines) {
      // Module header: ## `lurek.renders` {#graphics}
      const modMatch = line.match(/^## [`']?lurek\\.([\\w]+)[`']?/);
      if (modMatch) {
        finishModule();
        const modName = modMatch[1];
        currentModule = {
          name: modName,
          fullPath: `lurek.${modName}`,
          description: "",
          functions: [],
          methods: [],
          totalEntries: 0,
          documentedEntries: 0,
        };
        inCodeBlock = false;

        // Grab description from blockquote on next lines
        continue;
      }

      // Module description from blockquote: > `lurek.render` — 2D drawing...
      if (currentModule && line.startsWith(">") && !currentModule.description) {
        const desc = line.replace(/^>\s*`[^`]*`\s*—\s*/, "").trim();
        if (desc) currentModule.description = desc;
        continue;
      }

      // Code block toggle
      if (line.startsWith("```")) {
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (!inCodeBlock || !currentModule) continue;

      // Callback line: function lurek.load() -- desc
      {
        const m = line.match(/^function lurek\\.(\\w+)\\(\\s*(.*?)\\s*\\)\\s*--\\s*(.*)/);
        if (m) {
          // Callbacks are handled by initCallbacks() — skip
          continue;
        }
      }

      // Module function: lurek.MODULE.FUNCNAME( params ) -> ret  -- desc
      {
        const m = line.match(/^lurek\\.(\\w+)\\.(\\w+)\\(\\s*(.*?)\\s*\\)(?:\\s*->\\s*([^-]+?))?\\s*--\\s*(.*)/);
        if (m) {
          const [, , funcName, paramStr, retRaw, description] = m;
          const returnType = retRaw?.trim() || undefined;
          const parameters = this.parseParamStr(paramStr);
          const fn: ApiFunction = {
            module: currentModule.name,
            name: funcName,
            fullPath: `lurek.${currentModule.name}.${funcName}`,
            signature: `lurek.${currentModule.name}.${funcName}(${paramStr})`,
            description: description.trim(),
            parameters,
            returns: returnType,
            returnType,
            isMethod: false,
          };
          currentModule.functions.push(fn);
          this.allFunctions.set(fn.fullPath, fn);
          continue;
        }
      }

      // Method: ObjType:methodName( params ) -> ret  -- desc
      {
        const m = line.match(/^([A-Z]\\w*):([\\w]+)\\(\\s*(.*?)\\s*\\)(?:\\s*->\\s*([^-]+?))?\\s*--\\s*(.*)/);
        if (m) {
          const [, objType, methName, paramStr, retRaw, description] = m;
          const returnType = retRaw?.trim() || undefined;
          const parameters = this.parseParamStr(paramStr);
          const fn: ApiFunction = {
            module: currentModule.name,
            name: methName,
            fullPath: `lurek.${currentModule.name}.${objType}:${methName}`,
            signature: `${objType}:${methName}(${paramStr})`,
            description: description.trim(),
            parameters,
            returns: returnType,
            returnType,
            isMethod: true,
            objectType: objType,
          };
          currentModule.methods.push(fn);
          this.indexMethod(fn);
          this.allFunctions.set(fn.fullPath, fn);
          continue;
        }
      }
    }

    finishModule();
  }

  // ── Param string parser ────────────────────────────────────────────────────
  // Parses "name : type, name2 : type2?" style param strings from lua-api.md
  private parseParamStr(paramStr: string): ApiParam[] {
    if (!paramStr.trim()) return [];
    return paramStr.split(",").map((p) => {
      p = p.trim();
      const optional = p.endsWith("?") || p.includes("?");
      const colonIdx = p.indexOf(":");
      if (colonIdx >= 0) {
        const name = p.slice(0, colonIdx).trim().replace(/[?\\[\\]]/g, "");
        const type = p.slice(colonIdx + 1).trim().replace(/\\?$/, "").trim();
        return { name: name || "_", type: type || "any", description: "", optional };
      }
      const name = p.replace(/[?\\[\\]]/g, "").trim();
      return { name: name || "_", type: "any", description: "", optional };
    });
  }

'''

ANCHOR = '  // ── Fallback data ──────────────────────────────────────────'
if ANCHOR in content:
    content = content.replace(ANCHOR, NEW_METHODS + ANCHOR)
    print('  Inserted loadFromLuaApiMd() and parseParamStr() before loadFallback()')
else:
    print('  ERROR: Could not find anchor for method insertion!')

write(api_file, content)


# ─── 3. Merge package2.json → package.json ────────────────────────────────────
print("\n=== Updating package.json from package2.json ===")
pkg2_path = os.path.join(BASE, 'package2.json')
pkg_path  = os.path.join(BASE, 'package.json')

pkg2 = json.loads(read(pkg2_path))

# package2.json already has correct scripts, devDependencies, main etc.
# We use it as-is and write it to package.json

write(pkg_path, json.dumps(pkg2, indent=2) + '\n')
print(f'  Replaced package.json with package2.json content (v{pkg2["version"]})')


# ─── 4. Update esbuild.config.mjs ──────────────────────────────────────────────
print("\n=== Updating esbuild.config.mjs ===")
esbuild_path = os.path.join(BASE, 'esbuild.config.mjs')
content = read(esbuild_path)

old_entry = 'entryPoints: ["src/extension2.ts"],'
new_entry = 'entryPoints: ["src/extension.ts"],'
n = content.count(old_entry)
content = content.replace(old_entry, new_entry)
print(f'  Updated entryPoints: {n} replacement(s)')

write(esbuild_path, content)


print("\n=== All fixes applied successfully ===")
