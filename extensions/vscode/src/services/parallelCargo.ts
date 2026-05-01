import * as child_process from "child_process";

const PYTHON_EXECUTABLE = "python";
const WRAPPER_SCRIPT = "tools/dev/parallel_cargo.py";

export interface ParallelCargoTestOptions {
  nocapture?: boolean;
  verbose?: boolean;
  warmBuild?: boolean;
  outerJobs?: number;
  testThreads?: number;
}

function quoteTerminalArg(arg: string): string {
  if (arg.length === 0) {
    return '""';
  }
  if (!/[\s"]/u.test(arg)) {
    return arg;
  }
  return `"${arg.replace(/"/g, '\\"')}"`;
}

export function buildTerminalCommand(program: string, args: readonly string[] = []): string {
  return [program, ...args].map(quoteTerminalArg).join(" ");
}

export function buildParallelCargoCommand(args: readonly string[]): string {
  return buildTerminalCommand(PYTHON_EXECUTABLE, [WRAPPER_SCRIPT, ...args]);
}

function appendVerbose(args: string[], verbose?: boolean): void {
  if (verbose) {
    args.push("--verbose");
  }
}

function appendTestOptions(args: string[], options: ParallelCargoTestOptions = {}): void {
  appendVerbose(args, options.verbose);
  if (options.nocapture) {
    args.push("--nocapture");
  }
  if (options.warmBuild) {
    args.push("--warm-build");
  }
  if (options.outerJobs !== undefined) {
    args.push("--outer-jobs", String(options.outerJobs));
  }
  if (options.testThreads !== undefined) {
    args.push("--test-threads", String(options.testThreads));
  }
}

export function buildBuildCommand(profile: "debug" | "release", verbose = false): string {
  const args = ["build", profile];
  appendVerbose(args, verbose);
  return buildParallelCargoCommand(args);
}

export function buildCheckCommand(verbose = false): string {
  const args = ["check"];
  appendVerbose(args, verbose);
  return buildParallelCargoCommand(args);
}

export function buildClippyCommand(denyWarnings = false, verbose = false): string {
  const args = ["clippy"];
  if (denyWarnings) {
    args.push("--deny-warnings");
  }
  appendVerbose(args, verbose);
  return buildParallelCargoCommand(args);
}

export function buildFmtCommand(mode: "apply" | "check", verbose = false): string {
  const args = ["fmt", mode];
  appendVerbose(args, verbose);
  return buildParallelCargoCommand(args);
}

export function buildDocCommand(open = false, noDeps = false, verbose = false): string {
  const args = ["doc"];
  if (open) { args.push("--open"); }
  if (noDeps) { args.push("--no-deps"); }
  appendVerbose(args, verbose);
  return buildParallelCargoCommand(args);
}

export function buildBuildDistCommand(verbose = false): string {
  const args = ["build", "dist"];
  appendVerbose(args, verbose);
  return buildParallelCargoCommand(args);
}

export function buildRunCommand(
  profile: "debug" | "release",
  runArgs: readonly string[] = [],
  verbose = false,
): string {
  const args = ["run", profile];
  appendVerbose(args, verbose);
  if (runArgs.length > 0) {
    args.push("--", ...runArgs);
  }
  return buildParallelCargoCommand(args);
}

export function buildTestAllCommand(options: ParallelCargoTestOptions = {}): string {
  const args = ["test", "all"];
  appendTestOptions(args, options);
  return buildParallelCargoCommand(args);
}

export function buildLuaTestsCommand(options: ParallelCargoTestOptions = {}): string {
  const args = ["test", "lua"];
  appendTestOptions(args, options);
  return buildParallelCargoCommand(args);
}

export function buildRustFanoutCommand(options: ParallelCargoTestOptions = {}): string {
  const args = ["test", "rust"];
  appendTestOptions(args, options);
  return buildParallelCargoCommand(args);
}

export function normalizeRustTestTarget(target: string): string {
  return target.endsWith("_tests") ? target : `${target}_tests`;
}

export function buildTestTargetCommand(
  target: string,
  options: ParallelCargoTestOptions = {},
): string {
  const args = ["test", "target", normalizeRustTestTarget(target)];
  appendTestOptions(args, options);
  return buildParallelCargoCommand(args);
}

export function execParallelCargoCommand(
  workspaceRoot: string,
  args: readonly string[],
  timeoutMs = 60_000,
): Promise<string> {
  return new Promise((resolve) => {
    child_process.execFile(
      PYTHON_EXECUTABLE,
      [WRAPPER_SCRIPT, ...args],
      {
        cwd: workspaceRoot,
        timeout: timeoutMs,
        maxBuffer: 1024 * 1024,
        encoding: "utf-8",
      },
      (error, stdout, stderr) => {
        const output = `${stdout || ""}${stderr || ""}`;
        if (error) {
          resolve(`${output}\n[exit code: ${error.code ?? "unknown"}]`);
          return;
        }
        resolve(output || "(no output)");
      },
    );
  });
}