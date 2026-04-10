import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";

/**
 * Runs all tests (cargo test).
 */
export function testAll(): void {
  const terminal = getOrCreateTerminal("Lurek2D Tests");
  terminal.show();
  terminal.sendText("cargo test");
}

/**
 * Runs a specific Rust test module.
 */
export function testModule(moduleName: string): void {
  const terminal = getOrCreateTerminal("Lurek2D Tests");
  terminal.show();
  terminal.sendText(`cargo test ${moduleName}_tests`);
}

/**
 * Runs all Lua integration tests.
 */
export function testLuaAll(): void {
  const terminal = getOrCreateTerminal("Lurek2D Tests");
  terminal.show();
  terminal.sendText("cargo test --test lua_tests");
}

/**
 * Runs golden (snapshot) tests.
 */
export function testLuaGolden(): void {
  const terminal = getOrCreateTerminal("Lurek2D Tests");
  terminal.show();
  terminal.sendText("cargo test --test golden_tests");
}

/**
 * Generates test boilerplate for the currently open file.
 */
export async function generateTestForFile(): Promise<void> {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showWarningMessage("No active editor.");
    return;
  }

  const filePath = editor.document.fileName;
  const fileName = path.basename(filePath, path.extname(filePath));
  const ext = path.extname(filePath);
  const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;

  // ── Lua file → generate a tests/lua/<name>_test.lua ──────────────────────
  if (ext === ".lua") {
    const testDir = wsRoot ? path.join(wsRoot, "tests", "lua") : null;
    const testFile = testDir ? path.join(testDir, `${fileName}_test.lua`) : null;
    if (testFile && fs.existsSync(testFile)) {
      const doc = await vscode.workspace.openTextDocument(testFile);
      await vscode.window.showTextDocument(doc);
      vscode.window.showInformationMessage(`Opened existing test: tests/lua/${fileName}_test.lua`);
      return;
    }
    const skeleton = `-- Tests for ${fileName}.lua
-- Run with: cargo run -- tests/lua/${fileName}_test.lua

local passed, failed = 0, 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("[PASS] " .. name)
  else
    failed = failed + 1
    print("[FAIL] " .. name .. ": " .. tostring(err))
  end
end

-- ──────────────────────────────────────────────────
-- Add tests below

test("example: math works", function()
  assert(1 + 1 == 2, "basic arithmetic failed")
end)

-- ──────────────────────────────────────────────────
print(string.format("\\n%d passed, %d failed", passed, failed))
if failed > 0 then error(failed .. " test(s) failed") end
`;
    if (testDir && !fs.existsSync(testDir)) { fs.mkdirSync(testDir, { recursive: true }); }
    if (testFile) {
      fs.writeFileSync(testFile, skeleton, "utf-8");
      const doc = await vscode.workspace.openTextDocument(testFile);
      await vscode.window.showTextDocument(doc);
      vscode.window.showInformationMessage(`✅ Created: tests/lua/${fileName}_test.lua`);
    }
    return;
  }

  // ── Rust file → generate or open tests/<module>_tests.rs ─────────────────
  if (ext === ".rs") {
    // Derive module name from file path (e.g. src/physics/mod.rs → physics)
    const parts = filePath.replace(/\\/g, "/").split("/src/");
    const relPart = parts.length > 1 ? parts[parts.length - 1] : fileName;
    const moduleName = relPart.split("/")[0] === fileName ? fileName : relPart.split("/")[0];

    const testFile = wsRoot ? path.join(wsRoot, "tests", `${moduleName}_tests.rs`) : null;
    if (testFile && fs.existsSync(testFile)) {
      const doc = await vscode.workspace.openTextDocument(testFile);
      await vscode.window.showTextDocument(doc);
      vscode.window.showInformationMessage(`Opened existing test: tests/${moduleName}_tests.rs`);
      return;
    }

    const skeleton = `//! Integration tests for the \`${moduleName}\` module.

use lurek2d::${moduleName};

fn make_test_state() {
    // TODO: set up any required state here
}

#[test]
fn test_${moduleName}_basic() {
    // TODO: replace with a real test
    assert!(true);
}

#[test]
fn test_${moduleName}_example() {
    // TODO: add meaningful assertions
    let result = true;
    assert!(result, "expected true");
}
`;
    if (testFile) {
      fs.writeFileSync(testFile, skeleton, "utf-8");
      const doc = await vscode.workspace.openTextDocument(testFile);
      await vscode.window.showTextDocument(doc);
      vscode.window.showInformationMessage(`✅ Created: tests/${moduleName}_tests.rs`);
    }
    return;
  }

  vscode.window.showWarningMessage(`Test generation is not supported for ${ext} files.`);
}

function getOrCreateTerminal(name: string): vscode.Terminal {
  const existing = vscode.window.terminals.find((t) => t.name === name);
  if (existing) {
    return existing;
  }
  return vscode.window.createTerminal(name);
}
