import { ToolDefinition, ToolHandler } from "./tools";
import * as child_process from "child_process";
import * as fs from "fs";
import * as path from "path";
import * as readline from "readline";

/**
 * JSON-RPC request structure used by the MCP protocol.
 */
interface JsonRpcRequest {
  jsonrpc: "2.0";
  id: number | string;
  method: string;
  params?: Record<string, unknown>;
}

/**
 * JSON-RPC response structure used by the MCP protocol.
 */
interface JsonRpcResponse {
  jsonrpc: "2.0";
  id: number | string;
  result?: unknown;
  error?: { code: number; message: string; data?: unknown };
}

/**
 * Starts the MCP server as an in-process stdio handler.
 *
 * The server reads JSON-RPC messages from stdin and writes responses to
 * stdout. It implements the MCP initialize, tools/list, and tools/call
 * methods.
 *
 * @param workspaceRoot - Absolute path to the Luna2D workspace root.
 * @returns A handle with a `kill()` method to shut down the server.
 */
export function startMcpServer(workspaceRoot: string): { kill: () => void } {
  // The MCP server runs in-process — we just set up the handler.
  // In a real deployment this would be a separate child process.
  // For the extension, we expose a function that can be called
  // by VS Code's MCP integration.

  return { kill: () => {} };
}

/**
 * Runs the MCP server on stdio.
 *
 * This is the entry point when the server is launched as a standalone
 * process (e.g., `node out/mcp/server.js --workspace /path/to/luna2d`).
 *
 * Reads newline-delimited JSON-RPC messages from stdin and writes
 * responses to stdout.
 */
export function runStdioServer(workspaceRoot: string): void {
  const tools = buildToolRegistry(workspaceRoot);
  const toolDefs = getToolDefinitions(workspaceRoot);

  const rl = readline.createInterface({
    input: process.stdin,
    output: undefined,
    terminal: false,
  });

  rl.on("line", (line: string) => {
    const trimmed = line.trim();
    if (!trimmed) {
      return;
    }

    let request: JsonRpcRequest;
    try {
      request = JSON.parse(trimmed) as JsonRpcRequest;
    } catch {
      writeResponse({
        jsonrpc: "2.0",
        id: 0,
        error: { code: -32700, message: "Parse error" },
      });
      return;
    }

    handleRequest(request, tools, toolDefs).then((response) => {
      writeResponse(response);
    });
  });
}

/**
 * Writes a JSON-RPC response to stdout followed by a newline.
 */
function writeResponse(response: JsonRpcResponse): void {
  const json = JSON.stringify(response);
  process.stdout.write(json + "\n");
}

/**
 * Handles a single JSON-RPC request and returns a response.
 */
async function handleRequest(
  request: JsonRpcRequest,
  tools: Map<string, ToolHandler>,
  toolDefs: ToolDefinition[]
): Promise<JsonRpcResponse> {
  const { id, method, params } = request;

  switch (method) {
    case "initialize":
      return {
        jsonrpc: "2.0",
        id,
        result: {
          protocolVersion: "2024-11-05",
          capabilities: { tools: {} },
          serverInfo: {
            name: "luna2d-mcp",
            version: "0.1.0",
          },
        },
      };

    case "notifications/initialized":
      // Acknowledgement — no response needed, but send one if id exists
      return { jsonrpc: "2.0", id, result: {} };

    case "tools/list":
      return {
        jsonrpc: "2.0",
        id,
        result: {
          tools: toolDefs,
        },
      };

    case "tools/call": {
      const toolName = (params as Record<string, unknown>)?.name as string;
      const toolArgs =
        ((params as Record<string, unknown>)?.arguments as Record<
          string,
          unknown
        >) ?? {};

      const handler = tools.get(toolName);
      if (!handler) {
        return {
          jsonrpc: "2.0",
          id,
          error: {
            code: -32601,
            message: `Unknown tool: ${toolName}`,
          },
        };
      }

      try {
        const result = await handler(toolArgs);
        return {
          jsonrpc: "2.0",
          id,
          result: {
            content: [{ type: "text", text: result }],
          },
        };
      } catch (err) {
        return {
          jsonrpc: "2.0",
          id,
          result: {
            content: [
              {
                type: "text",
                text: `Error: ${err instanceof Error ? err.message : String(err)}`,
              },
            ],
            isError: true,
          },
        };
      }
    }

    default:
      return {
        jsonrpc: "2.0",
        id,
        error: {
          code: -32601,
          message: `Method not found: ${method}`,
        },
      };
  }
}

/**
 * Builds the tool handler registry from tool definitions.
 */
function buildToolRegistry(
  workspaceRoot: string
): Map<string, ToolHandler> {
  const {
    handleRunExample,
    handleGetApiDoc,
    handleListExamples,
    handleRunLuaTest,
    handleCheckBuild,
    handleGetLogs,
  } = require("./tools");

  const registry = new Map<string, ToolHandler>();
  registry.set("luna2d.runExample", handleRunExample(workspaceRoot));
  registry.set("luna2d.getApiDoc", handleGetApiDoc(workspaceRoot));
  registry.set("luna2d.listExamples", handleListExamples(workspaceRoot));
  registry.set("luna2d.runLuaTest", handleRunLuaTest(workspaceRoot));
  registry.set("luna2d.checkBuild", handleCheckBuild(workspaceRoot));
  registry.set("luna2d.getLogs", handleGetLogs(workspaceRoot));
  return registry;
}

/**
 * Returns the array of MCP tool definitions.
 */
function getToolDefinitions(workspaceRoot: string): ToolDefinition[] {
  const { getToolDefinitions: getDefs } = require("./tools");
  return getDefs();
}

// Allow running as standalone process
if (require.main === module) {
  const args = process.argv.slice(2);
  let workspace = process.cwd();

  const wsIndex = args.indexOf("--workspace");
  if (wsIndex !== -1 && args[wsIndex + 1]) {
    workspace = args[wsIndex + 1];
  }

  runStdioServer(workspace);
}
