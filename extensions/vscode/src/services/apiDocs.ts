import * as fs from "fs";
import * as path from "path";

export type ApiEntryKind = "module" | "function" | "callback" | "method" | "section";

export interface ApiEntry {
  label: string;
  line: number;
  kind: ApiEntryKind;
}

export function resolveWorkspaceApiDocPath(root: string): string | undefined {
  const candidates = [
    path.join(root, "docs", "API", "lurek.lua"),
    path.join(root, "docs", "API", "lua-api.md"),
    path.join(root, "docs", "API", "lua_api_reference_generated.md"),
    path.join(root, "docs", "lua-api.md"),
  ];

  return candidates.find((candidate) => fs.existsSync(candidate));
}

export function listApiEntries(content: string, filePath: string): ApiEntry[] {
  return isLuaCatsApiFile(filePath)
    ? listLuaCatsEntries(content)
    : listMarkdownEntries(content);
}

export function findApiSymbolLine(content: string, filePath: string, symbol: string): number {
  return isLuaCatsApiFile(filePath)
    ? findLuaCatsSymbolLine(content, symbol)
    : findMarkdownSymbolLine(content, symbol);
}

export function searchApiDocumentation(content: string, filePath: string, query: string): string[] {
  return isLuaCatsApiFile(filePath)
    ? searchLuaCatsApi(content, query)
    : searchMarkdownApi(content, query);
}

function isLuaCatsApiFile(filePath: string): boolean {
  return path.basename(filePath).toLowerCase() === "lurek.lua";
}

function listLuaCatsEntries(content: string): ApiEntry[] {
  const lines = content.split("\n");
  const entries = new Map<string, ApiEntry>();

  for (let index = 0; index < lines.length; index++) {
    const trimmed = lines[index].trim();

    const moduleMatch = trimmed.match(/^---@class\s+(lurek\.[A-Za-z0-9_]+)\s*$/);
    if (moduleMatch) {
      const label = moduleMatch[1];
      if (!entries.has(label)) {
        entries.set(label, { label, line: index, kind: "module" });
      }
      continue;
    }

    const functionMatch = trimmed.match(/^function\s+(lurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+)\(/);
    if (functionMatch) {
      const label = functionMatch[1];
      if (!entries.has(label)) {
        entries.set(label, { label, line: index, kind: "function" });
      }
      continue;
    }

    const callbackMatch = trimmed.match(/^function\s+(lurek\.[A-Za-z0-9_]+)\(/);
    if (callbackMatch && callbackMatch[1].split(".").length === 2) {
      const label = callbackMatch[1];
      if (!entries.has(label)) {
        entries.set(label, { label, line: index, kind: "callback" });
      }
      continue;
    }

    const methodMatch = trimmed.match(/^function\s+([A-Za-z_][A-Za-z0-9_]*)[:.]([A-Za-z0-9_]+)\(/);
    if (methodMatch) {
      const label = `${methodMatch[1]}:${methodMatch[2]}`;
      if (!entries.has(label)) {
        entries.set(label, { label, line: index, kind: "method" });
      }
    }
  }

  return Array.from(entries.values()).sort((left, right) => left.label.localeCompare(right.label));
}

function listMarkdownEntries(content: string): ApiEntry[] {
  return content
    .split("\n")
    .map((line, index) => ({ line, index }))
    .filter(({ line }) => line.startsWith("## ") || line.startsWith("### "))
    .map(({ line, index }) => ({
      label: line.replace(/^#+\s*/, ""),
      line: index,
      kind: "section" as const,
    }));
}

function findLuaCatsSymbolLine(content: string, symbol: string): number {
  const lines = content.split("\n");
  const targets = [
    `function ${symbol}(`,
    `---@class ${symbol}`,
  ];

  for (let index = 0; index < lines.length; index++) {
    const trimmed = lines[index].trim();
    if (targets.some((target) => trimmed.startsWith(target))) {
      return index;
    }
  }

  return -1;
}

function findMarkdownSymbolLine(content: string, symbol: string): number {
  const bare = symbol.replace(/^lurek\./, "");
  return content
    .split("\n")
    .findIndex((line) => line.startsWith("##") && (line.includes(symbol) || line.includes(bare)));
}

function searchLuaCatsApi(content: string, query: string): string[] {
  const queryLower = query.toLowerCase();
  const blocks = buildLuaCatsBlocks(content);
  const matches = blocks
    .filter((block) => block.text.toLowerCase().includes(queryLower))
    .map((block) => block.text.trim())
    .filter(Boolean);

  if (matches.length > 0) {
    return dedupe(matches);
  }

  const lines = content.split("\n");
  const windows: string[] = [];
  for (let index = 0; index < lines.length; index++) {
    if (!lines[index].toLowerCase().includes(queryLower)) {
      continue;
    }
    const start = Math.max(0, index - 3);
    const end = Math.min(lines.length, index + 4);
    windows.push(lines.slice(start, end).join("\n").trim());
  }

  return dedupe(windows.filter(Boolean));
}

function searchMarkdownApi(content: string, query: string): string[] {
  const lines = content.split("\n");
  const queryLower = query.toLowerCase();
  const matches: string[] = [];
  let currentSection: string[] = [];
  let inMatch = false;

  for (const line of lines) {
    if (line.startsWith("##")) {
      if (inMatch && currentSection.length > 0) {
        matches.push(currentSection.join("\n").trim());
      }
      currentSection = [line];
      inMatch = line.toLowerCase().includes(queryLower);
      continue;
    }

    currentSection.push(line);
    if (line.toLowerCase().includes(queryLower)) {
      inMatch = true;
    }
  }

  if (inMatch && currentSection.length > 0) {
    matches.push(currentSection.join("\n").trim());
  }

  return dedupe(matches.filter(Boolean));
}

function buildLuaCatsBlocks(content: string): Array<{ startLine: number; text: string }> {
  const lines = content.split("\n");
  const starts: number[] = [];

  for (let index = 0; index < lines.length; index++) {
    const trimmed = lines[index].trim();
    if (!isLuaCatsEntry(trimmed)) {
      continue;
    }

    let start = index;
    while (start > 0 && lines[start - 1].trim().startsWith("---")) {
      start--;
    }
    starts.push(start);
  }

  const uniqueStarts = Array.from(new Set(starts)).sort((left, right) => left - right);
  return uniqueStarts.map((startLine, index) => {
    const endLine = index + 1 < uniqueStarts.length ? uniqueStarts[index + 1] : lines.length;
    return {
      startLine,
      text: lines.slice(startLine, endLine).join("\n"),
    };
  });
}

function isLuaCatsEntry(trimmed: string): boolean {
  return /^---@class\s+lurek\./.test(trimmed)
    || /^function\s+lurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+\(/.test(trimmed)
    || /^function\s+lurek\.[A-Za-z0-9_]+\(/.test(trimmed)
    || /^function\s+[A-Za-z_][A-Za-z0-9_]*[:.][A-Za-z0-9_]+\(/.test(trimmed);
}

function dedupe(values: string[]): string[] {
  return Array.from(new Set(values));
}
