import * as fs from "fs";
import * as path from "path";
import * as child_process from "child_process";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const repoRoot = path.resolve(root, "..", "..");

const sourcePath = path.join(repoRoot, "docs", "api", "lurek.lua");
const outputPath = path.join(root, "data", "lurek.luacats");
const legacyOutputPath = path.join(root, "data", "lurek.lua");

function runPython(scriptPath: string, args: string[] = []): void {
  const python = process.env.PYTHON ?? "python";

  try {
    child_process.execFileSync(
      python,
      [path.join(repoRoot, scriptPath), ...args],
      {
        cwd: repoRoot,
        stdio: "inherit",
      },
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`ERROR: Failed to run ${scriptPath}: ${message}`);
    process.exit(1);
  }
}

// Ensure the copied LuaCATS file matches the current engine API.
runPython("tools/docs/gen_lua_api_data.py");
runPython("tools/docs/gen_luadoc.py");

if (!fs.existsSync(sourcePath)) {
  console.error(`ERROR: ${sourcePath} not found.`);
  process.exit(1);
}

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.copyFileSync(sourcePath, outputPath);
if (fs.existsSync(legacyOutputPath)) {
  fs.rmSync(legacyOutputPath);
}

console.log(`✓ Copied ${path.relative(root, outputPath)} from docs/api/lurek.lua`);
