import * as esbuild from "esbuild";

const production = process.argv.includes("--production");
const watch = process.argv.includes("--watch");

/** @type {esbuild.BuildOptions} */
const buildOptions = {
  entryPoints: ["src/extension.ts"],
  bundle: true,
  outfile: "dist/extension.js",
  external: ["vscode"],
  format: "cjs",
  platform: "node",
  target: "node20",
  sourcemap: !production,
  minify: production,
  treeShaking: true,
  logLevel: "info",
};

/** @type {esbuild.BuildOptions} */
const testOptions = {
  entryPoints: [
    "src/test/runTest.ts",
    "src/test/suite/index.ts",
    "src/test/unit/commandRegistration.test.ts",
    "src/test/unit/typeInference.test.ts",
    "src/test/unit/luaParser.test.ts",
  ],
  bundle: true,
  outdir: "dist/test",
  external: ["vscode", "mocha", "@vscode/test-electron"],
  format: "cjs",
  platform: "node",
  target: "node20",
  sourcemap: true,
  logLevel: "info",
};

async function main() {
  if (watch) {
    const ctx = await esbuild.context(buildOptions);
    await ctx.watch();
    console.log("[esbuild] Watching for changes...");
  } else {
    await esbuild.build(buildOptions);
    if (process.argv.includes("--test")) {
      await esbuild.build(testOptions);
    }
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
