import * as fs from "fs";
import * as path from "path";
import { resolveWorkspaceApiDocPath, searchApiDocumentation } from "../services/apiDocs.js";
import { execParallelCargoCommand } from "../services/parallelCargo.js";

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
 * Returns all MCP tool definitions for the Lurek2D server.
 */
export function getToolDefinitions(): ToolDefinition[] {
  return [
    {
      name: "lurek2d.runExample",
      description:
        "Build and run a named Lurek2D example, returning its output.",
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
      name: "lurek2d.getApiDoc",
      description:
        "Search the Lurek2D Lua API documentation for a query string.",
      inputSchema: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description:
              'Search query (e.g. "lurek.graphics.draw" or "physics").',
          },
        },
        required: ["query"],
      },
    },
    {
      name: "lurek2d.listExamples",
      description: "List all available Lurek2D example directories.",
      inputSchema: {
        type: "object",
        properties: {},
      },
    },
    {
      name: "lurek2d.runLuaTest",
      description: "Run a Lua test file against a debug build of Lurek2D.",
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
      name: "lurek2d.checkBuild",
      description:
        "Run the wrapper-backed repo check flow and return compiler diagnostics.",
      inputSchema: {
        type: "object",
        properties: {},
      },
    },
    {
      name: "lurek2d.getLogs",
      description:
        "Return the last N lines of Lurek2D engine log output.",
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
/**
 * Creates the handler for `lurek2d.runExample`.
 *
 * Builds and runs the specified showcase game via the wrapper-backed run path.
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
    const exampleDir = path.join(workspaceRoot, "content", "games", "showcase", name);
    if (!fs.existsSync(exampleDir)) {
      const available = listExampleDirs(workspaceRoot);
      return `Showcase game "${name}" not found. Available: ${available.join(", ")}`;
    }

    const relativeGamePath = path.posix.join("content", "games", "showcase", name);
    return execParallelCargoCommand(workspaceRoot, ["run", "debug", "--", relativeGamePath], 120_000);
  };
}

/**
 * Creates the handler for `lurek2d.getApiDoc`.
 *
 * Searches the canonical workspace API reference for sections matching the
 * query string (case-insensitive).
 */
export function handleGetApiDoc(
  workspaceRoot: string
): ToolHandler {
  return async (args) => {
    const query = args.query as string | undefined;
    if (!query) {
      return "Error: 'query' parameter is required.";
    }

    const apiDocPath = resolveWorkspaceApiDocPath(workspaceRoot);

    if (!apiDocPath || !fs.existsSync(apiDocPath)) {
      return "API reference not found. Expected docs/api/lurek.lua or docs/api/lurek.md.";
    }

    const content = fs.readFileSync(apiDocPath, "utf-8");
    const matches = searchApiDocumentation(content, apiDocPath, query);

    if (matches.length === 0) {
      return `No documentation found for "${query}".`;
    }

    if (apiDocPath.endsWith(".lua")) {
      return matches.map((match) => `\`\`\`lua\n${match}\n\`\`\``).join("\n\n---\n\n");
    }

    return matches.join("\n\n---\n\n");
  };
}

/**
 * Creates the handler for `lurek2d.listExamples`.
 *
 * Returns a newline-separated list of example directory names.
 */
export function handleListExamples(
  workspaceRoot: string
): ToolHandler {
  return async () => {
    const examples = listExampleDirs(workspaceRoot);
    if (examples.length === 0) {
      return "No showcase games found in content/games/showcase/.";
    }
    return examples.join("\n");
  };
}

/**
 * Creates the handler for `lurek2d.runLuaTest`.
 *
 * Runs a Lua test file via the wrapper-backed debug run path.
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

    const relativeFile = path.relative(workspaceRoot, resolved).replace(/\\/g, "/");
    return execParallelCargoCommand(workspaceRoot, ["run", "debug", "--", relativeFile], 120_000);
  };
}

/**
 * Creates the handler for `lurek2d.checkBuild`.
 *
 * Runs the wrapper-backed repo check flow and returns the compiler output.
 */
export function handleCheckBuild(
  workspaceRoot: string
): ToolHandler {
  return async () => {
    return execParallelCargoCommand(workspaceRoot, ["check"], 120_000);
  };
}

/**
 * Creates the handler for `lurek2d.getLogs`.
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
      path.join(workspaceRoot, "lurek2d.log"),
      path.join(workspaceRoot, "target", "lurek2d.log"),
    ];

    for (const logPath of logPaths) {
      if (fs.existsSync(logPath)) {
        const content = fs.readFileSync(logPath, "utf-8");
        const allLines = content.split("\n");
        const tail = allLines.slice(-lines);
        return tail.join("\n");
      }
    }

    return "No log file found. Engine logs are written to stdout by default. Use RUST_LOG=lurek2d=debug to enable verbose logging.";
  };
}

/**
 * Lists showcase game directory names from the workspace content/games/showcase/ folder.
 */
function listExampleDirs(workspaceRoot: string): string[] {
  const examplesDir = path.join(workspaceRoot, "content", "games", "showcase");
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
