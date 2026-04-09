import * as child_process from "child_process";
import * as fs from "fs";
import * as path from "path";

/**
 * MCP tool definition following the Model Context Protocol schema.
 */
export interface ToolDefinition {
  name: string;
  description: string;
  inputSchema: {
    type: "object";
    properties: Record<string, { type: string; description: string }>;
    required?: string[];
  };
}

/**
 * A tool handler function that accepts arguments and returns a text result.
 */
export type ToolHandler = (
  args: Record<string, unknown>
) => Promise<string>;

/**
 * Returns all MCP tool definitions for the Luna2D server.
 */
export function getToolDefinitions(): ToolDefinition[] {
  return [
    {
      name: "luna2d.runExample",
      description:
        "Build and run a named Luna2D example, returning its output.",
      inputSchema: {
        type: "object",
        properties: {
          name: {
            type: "string",
            description:
              'Name of the example directory (e.g. "hello_world").',
          },
        },
        required: ["name"],
      },
    },
    {
      name: "luna2d.getApiDoc",
      description:
        "Search the Luna2D Lua API documentation for a query string.",
      inputSchema: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description:
              'Search query (e.g. "luna.graphics.draw" or "physics").',
          },
        },
        required: ["query"],
      },
    },
    {
      name: "luna2d.listExamples",
      description: "List all available Luna2D example directories.",
      inputSchema: {
        type: "object",
        properties: {},
      },
    },
    {
      name: "luna2d.runLuaTest",
      description: "Run a Lua test file against a debug build of Luna2D.",
      inputSchema: {
        type: "object",
        properties: {
          file: {
            type: "string",
            description:
              "Path to the Lua test file, relative to workspace root.",
          },
        },
        required: ["file"],
      },
    },
    {
      name: "luna2d.checkBuild",
      description:
        "Run `cargo check` and return compiler diagnostics.",
      inputSchema: {
        type: "object",
        properties: {},
      },
    },
    {
      name: "luna2d.getLogs",
      description:
        "Return the last N lines of Luna2D engine log output.",
      inputSchema: {
        type: "object",
        properties: {
          lines: {
            type: "number",
            description:
              "Number of log lines to return (default: 50).",
          },
        },
      },
    },
  ];
}

/**
 * Executes a shell command in the workspace and returns combined output.
 *
 * @param command - The command string to execute.
 * @param cwd - Working directory for the command.
 * @param timeoutMs - Maximum execution time in milliseconds.
 * @returns Combined stdout and stderr output.
 */
function execCommand(
  command: string,
  cwd: string,
  timeoutMs: number = 60_000
): Promise<string> {
  return new Promise((resolve) => {
    child_process.exec(
      command,
      { cwd, timeout: timeoutMs, maxBuffer: 1024 * 1024 },
      (error, stdout, stderr) => {
        const output = (stdout || "") + (stderr || "");
        if (error) {
          resolve(`${output}\n[exit code: ${error.code ?? "unknown"}]`);
        } else {
          resolve(output || "(no output)");
        }
      }
    );
  });
}

/**
 * Creates the handler for `luna2d.runExample`.
 *
 * Builds and runs the specified demo via `cargo run -- demos/<name>`.
 */
export function handleRunExample(
  workspaceRoot: string
): ToolHandler {
  return async (args) => {
    const name = args.name as string | undefined;
    if (!name) {
      return "Error: 'name' parameter is required.";
    }

    // Validate example exists
    const exampleDir = path.join(workspaceRoot, "demos", name);
    if (!fs.existsSync(exampleDir)) {
      const available = listExampleDirs(workspaceRoot);
      return `Demo "${name}" not found. Available: ${available.join(", ")}`;
    }

    return execCommand(
      `cargo run -- demos/${name}`,
      workspaceRoot,
      120_000
    );
  };
}

/**
 * Creates the handler for `luna2d.getApiDoc`.
 *
 * Searches the generated API reference markdown for sections matching
 * the query string (case-insensitive).
 */
export function handleGetApiDoc(
  workspaceRoot: string
): ToolHandler {
  return async (args) => {
    const query = args.query as string | undefined;
    if (!query) {
      return "Error: 'query' parameter is required.";
    }

    const apiDocPath = path.join(
      workspaceRoot,
      "docs",
      "API",
      "lua_api_reference_generated.md"
    );

    if (!fs.existsSync(apiDocPath)) {
      return "API reference not found. Run 'python tools/gen_lua_api.py' to generate it.";
    }

    const content = fs.readFileSync(apiDocPath, "utf-8");
    const lines = content.split("\n");
    const queryLower = query.toLowerCase();

    const matches: string[] = [];
    let currentSection: string[] = [];
    let inMatch = false;

    for (const line of lines) {
      if (line.startsWith("##")) {
        if (inMatch && currentSection.length > 0) {
          matches.push(currentSection.join("\n"));
        }
        currentSection = [line];
        inMatch = line.toLowerCase().includes(queryLower);
      } else {
        currentSection.push(line);
        if (line.toLowerCase().includes(queryLower)) {
          inMatch = true;
        }
      }
    }
    if (inMatch && currentSection.length > 0) {
      matches.push(currentSection.join("\n"));
    }

    if (matches.length === 0) {
      return `No documentation found for "${query}".`;
    }

    return matches.join("\n\n---\n\n");
  };
}

/**
 * Creates the handler for `luna2d.listExamples`.
 *
 * Returns a newline-separated list of example directory names.
 */
export function handleListExamples(
  workspaceRoot: string
): ToolHandler {
  return async () => {
    const examples = listExampleDirs(workspaceRoot);
    if (examples.length === 0) {
      return "No demos found in demos/ directory.";
    }
    return examples.join("\n");
  };
}

/**
 * Creates the handler for `luna2d.runLuaTest`.
 *
 * Runs a Lua test file via `cargo run -- <file>`.
 */
export function handleRunLuaTest(
  workspaceRoot: string
): ToolHandler {
  return async (args) => {
    const file = args.file as string | undefined;
    if (!file) {
      return "Error: 'file' parameter is required.";
    }

    // Prevent path traversal
    const resolved = path.resolve(workspaceRoot, file);
    if (!resolved.startsWith(workspaceRoot)) {
      return "Error: file path must be within the workspace.";
    }

    if (!fs.existsSync(resolved)) {
      return `Test file not found: ${file}`;
    }

    return execCommand(`cargo run -- ${file}`, workspaceRoot, 120_000);
  };
}

/**
 * Creates the handler for `luna2d.checkBuild`.
 *
 * Runs `cargo check` and returns the compiler output.
 */
export function handleCheckBuild(
  workspaceRoot: string
): ToolHandler {
  return async () => {
    return execCommand("cargo check 2>&1", workspaceRoot, 120_000);
  };
}

/**
 * Creates the handler for `luna2d.getLogs`.
 *
 * Returns the last N lines from the engine log file, if any.
 * Falls back to a message indicating no log file was found.
 */
export function handleGetLogs(
  workspaceRoot: string
): ToolHandler {
  return async (args) => {
    const lines = (args.lines as number) || 50;

    // Check common log file locations
    const logPaths = [
      path.join(workspaceRoot, "luna2d.log"),
      path.join(workspaceRoot, "target", "luna2d.log"),
    ];

    for (const logPath of logPaths) {
      if (fs.existsSync(logPath)) {
        const content = fs.readFileSync(logPath, "utf-8");
        const allLines = content.split("\n");
        const tail = allLines.slice(-lines);
        return tail.join("\n");
      }
    }

    return "No log file found. Engine logs are written to stdout by default. Use RUST_LOG=luna2d=debug to enable verbose logging.";
  };
}

/**
 * Lists demo directory names from the workspace demos/ folder.
 */
function listExampleDirs(workspaceRoot: string): string[] {
  const examplesDir = path.join(workspaceRoot, "demos");
  if (!fs.existsSync(examplesDir)) {
    return [];
  }
  try {
    return fs
      .readdirSync(examplesDir, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name);
  } catch {
    return [];
  }
}
