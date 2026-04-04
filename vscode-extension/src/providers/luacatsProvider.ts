/**
 * LuaCATS annotation provider.
 *
 * Parses `---@class`, `---@field`, `---@param`, `---@return` comments in
 * user Lua files and uses them to power:
 *   - Hover docs on user-defined class fields and methods (I5)
 *   - Completion items for instances inferred from `---@type` and
 *     `setmetatable({}, Class)` patterns
 */
import * as vscode from "vscode";
import { ApiDataService } from "../services/apiData.js";

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: "file", language: "lua" };

// ── Types ─────────────────────────────────────────────────────

export interface CatsField {
  name: string;
  type: string;
  description: string;
  line: number;
}

export interface CatsMethod {
  name: string;
  params: string;
  returns: string;
  description: string;
  line: number;
}

export interface CatsClass {
  name: string;
  parent?: string;
  fields: CatsField[];
  methods: CatsMethod[];
  definedLine: number;
  fileUri: string;
}

// ── Per-document class registry ──────────────────────────────

interface DocRegistry {
  version: number;
  classes: Map<string, CatsClass>;
  /** Maps local variable name → class name (from ---@type or setmetatable) */
  instanceTypes: Map<string, string>;
}

const docRegistries = new Map<string, DocRegistry>();

// ── Parser ────────────────────────────────────────────────────

function parseDocument(document: vscode.TextDocument): DocRegistry {
  const key = document.uri.toString();
  const cached = docRegistries.get(key);
  if (cached && cached.version === document.version) return cached;

  const classes = new Map<string, CatsClass>();
  const instanceTypes = new Map<string, string>();
  const lines = document.getText().split("\n");

  let pendingClass: CatsClass | null = null;
  let pendingDesc = "";
  let pendingParams: { name: string; type: string; desc: string }[] = [];
  let pendingReturn = "";

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();

    // ── @class ──────────────────────────────────────────────
    const classMatch = trimmed.match(/^---@class\s+(\w+)(?:\s*:\s*(\w+))?(?:\s+(.*))?$/);
    if (classMatch) {
      pendingClass = {
        name: classMatch[1],
        parent: classMatch[2],
        fields: [],
        methods: [],
        definedLine: i,
        fileUri: document.uri.toString(),
      };
      if (classMatch[3]) pendingDesc = classMatch[3].trim();
      classes.set(pendingClass.name, pendingClass);
      continue;
    }

    // ── @field ──────────────────────────────────────────────
    const fieldMatch = trimmed.match(/^---@field\s+(\w+)\s+(\S+)(?:\s+(.*))?$/);
    if (fieldMatch && pendingClass) {
      pendingClass.fields.push({
        name: fieldMatch[1],
        type: fieldMatch[2],
        description: fieldMatch[3]?.trim() ?? "",
        line: i,
      });
      continue;
    }

    // ── @param ──────────────────────────────────────────────
    const paramMatch = trimmed.match(/^---@param\s+(\w+)\s+(\S+)(?:\s+(.*))?$/);
    if (paramMatch) {
      pendingParams.push({
        name: paramMatch[1],
        type: paramMatch[2],
        desc: paramMatch[3]?.trim() ?? "",
      });
      continue;
    }

    // ── @return ─────────────────────────────────────────────
    const returnMatch = trimmed.match(/^---@return\s+(\S+)(?:\s+(.*))?$/);
    if (returnMatch) {
      pendingReturn = returnMatch[1];
      continue;
    }

    // ── Regular doc comment (description) ───────────────────
    const docMatch = trimmed.match(/^---(?!@)(.*)$/);
    if (docMatch) {
      pendingDesc = docMatch[1].trim();
      continue;
    }

    // ── Function definition following annotations ────────────
    const funcMatch = trimmed.match(/^(?:local\s+)?function\s+(\w+)[.:]([\w]+)\s*\(([^)]*)\)/);
    if (funcMatch) {
      const className = funcMatch[1];
      const methodName = funcMatch[2];
      const cls = classes.get(className);
      if (cls) {
        const paramStr = pendingParams.length > 0
          ? pendingParams.map(p => `${p.name}: ${p.type}`).join(", ")
          : funcMatch[3];
        cls.methods.push({
          name: methodName,
          params: paramStr,
          returns: pendingReturn,
          description: pendingDesc,
          line: i,
        });
      }
      pendingParams = [];
      pendingReturn = "";
      pendingDesc = "";
      continue;
    }

    // ── @type annotation on local variable ──────────────────
    const typeAnnotLine = i > 0 ? lines[i - 1].trim() : "";
    const typeMatch = typeAnnotLine.match(/^---@type\s+(\w+)/);
    if (typeMatch) {
      const localMatch = trimmed.match(/^local\s+(\w+)\s*=/);
      if (localMatch) {
        instanceTypes.set(localMatch[1], typeMatch[1]);
      }
    }

    // ── setmetatable({}, ClassName) pattern ─────────────────
    const setmetaMatch = trimmed.match(/^local\s+(\w+)\s*=\s*setmetatable\s*\(\s*\{[^}]*\}\s*,\s*(\w+)\s*\)/);
    if (setmetaMatch) {
      instanceTypes.set(setmetaMatch[1], setmetaMatch[2]);
    }

    // ── ClassName.new() return setmetatable pattern ──────────
    const retSetmeta = trimmed.match(/^\s*return\s+setmetatable\s*\(\s*\{[^}]*\}\s*,\s*(\w+)\s*\)/);
    if (retSetmeta) {
      // Track the enclosing function's class (best-effort heuristic)
      const cls = classes.get(retSetmeta[1]);
      if (cls) {
        // Mark this class as having a .new() constructor
        if (!cls.methods.find(m => m.name === "new")) {
          cls.methods.push({
            name: "new",
            params: "",
            returns: retSetmeta[1],
            description: `Create a new ${retSetmeta[1]} instance`,
            line: i,
          });
        }
      }
    }

    // Reset pending annotations on non-annotation lines (unless blank)
    if (trimmed !== "" && !trimmed.startsWith("---")) {
      pendingDesc = "";
      pendingParams = [];
      pendingReturn = "";
    }
  }

  const registry: DocRegistry = { version: document.version, classes, instanceTypes };
  docRegistries.set(key, registry);
  return registry;
}

// ── Resolve the class name for a variable at a position ──────

function resolveClassForWord(
  document: vscode.TextDocument,
  word: string,
  registry: DocRegistry,
): CatsClass | undefined {
  // Direct match (hovering on class name itself)
  if (registry.classes.has(word)) return registry.classes.get(word)!;

  // Instance lookup
  const className = registry.instanceTypes.get(word);
  if (className) return registry.classes.get(className);

  // Scan backwards in the file for most recent assignment
  const text = document.getText();
  const lines = text.split("\n");

  // local varName = ClassName.new(...)
  const constructorPat = new RegExp(`\\blocal\\s+${word}\\s*=\\s*(\\w+)\\.new\\s*\\(`);
  for (let i = lines.length - 1; i >= 0; i--) {
    const m = constructorPat.exec(lines[i]);
    if (m) {
      const cls = registry.classes.get(m[1]);
      if (cls) return cls;
    }
  }

  return undefined;
}

// ── Main registration ────────────────────────────────────────

export function register(
  context: vscode.ExtensionContext,
  _apiData: ApiDataService,
): void {
  // ── Hover provider ─────────────────────────────────────

  const hoverProvider = vscode.languages.registerHoverProvider(LUA_SELECTOR, {
    provideHover(document, position): vscode.Hover | undefined {
      const registry = parseDocument(document);

      // Check for word.field or word:method
      const fullRange = document.getWordRangeAtPosition(position, /\w+[.:]\w+/);
      if (fullRange) {
        const fullText = document.getText(fullRange);
        const dot = fullText.includes(":") ? ":" : ".";
        const [owner, member] = fullText.split(dot);
        const cls = resolveClassForWord(document, owner, registry);
        if (cls) {
          const field = cls.fields.find(f => f.name === member);
          if (field) {
            const md = new vscode.MarkdownString();
            md.appendCodeblock(`${cls.name}.${field.name}: ${field.type}`, "lua");
            if (field.description) md.appendMarkdown(`\n${field.description}\n`);
            md.appendMarkdown(`\n*Defined in class \`${cls.name}\`*`);
            md.isTrusted = true;
            return new vscode.Hover(md, fullRange);
          }
          const method = cls.methods.find(m => m.name === member);
          if (method) {
            const md = new vscode.MarkdownString();
            md.appendCodeblock(`${cls.name}:${method.name}(${method.params})${method.returns ? ` → ${method.returns}` : ""}`, "lua");
            if (method.description) md.appendMarkdown(`\n${method.description}\n`);
            md.appendMarkdown(`\n*Method of class \`${cls.name}\`*`);
            md.isTrusted = true;
            return new vscode.Hover(md, fullRange);
          }
        }
      }

      // Hover on class name itself
      const wordRange = document.getWordRangeAtPosition(position, /\w+/);
      if (!wordRange) return undefined;
      const word = document.getText(wordRange);
      const cls = registry.classes.get(word);
      if (!cls) return undefined;

      const md = new vscode.MarkdownString();
      md.appendCodeblock(`class ${cls.name}${cls.parent ? ` : ${cls.parent}` : ""}`, "lua");
      if (cls.fields.length > 0) {
        md.appendMarkdown("\n**Fields:**\n\n");
        for (const f of cls.fields) {
          md.appendMarkdown(`- \`${f.name}\`: *${f.type}*${f.description ? ` — ${f.description}` : ""}\n`);
        }
      }
      if (cls.methods.length > 0) {
        md.appendMarkdown("\n**Methods:**\n\n");
        for (const m of cls.methods) {
          md.appendMarkdown(`- \`${m.name}(${m.params})\`${m.returns ? ` → ${m.returns}` : ""}${m.description ? ` — ${m.description}` : ""}\n`);
        }
      }
      md.isTrusted = true;
      return new vscode.Hover(md, wordRange);
    },
  });

  // ── Completion provider ───────────────────────────────────

  const completionProvider = vscode.languages.registerCompletionItemProvider(
    LUA_SELECTOR,
    {
      provideCompletionItems(document, position): vscode.CompletionItem[] {
        const registry = parseDocument(document);
        const linePrefix = document.lineAt(position).text.slice(0, position.character);

        // word. or word:
        const accessMatch = linePrefix.match(/(\w+)[.:]\s*$/);
        if (!accessMatch) return [];

        const ownerName = accessMatch[1];
        const cls = resolveClassForWord(document, ownerName, registry);
        if (!cls) return [];

        const isColon = linePrefix.endsWith(":");
        const items: vscode.CompletionItem[] = [];

        if (!isColon) {
          for (const field of cls.fields) {
            const item = new vscode.CompletionItem(field.name, vscode.CompletionItemKind.Field);
            item.detail = `${field.type} — ${cls.name}`;
            item.documentation = field.description;
            items.push(item);
          }
        }

        for (const method of cls.methods) {
          const item = new vscode.CompletionItem(method.name, vscode.CompletionItemKind.Method);
          item.detail = `${cls.name}:${method.name}(${method.params})${method.returns ? ` → ${method.returns}` : ""}`;
          item.documentation = method.description;
          item.insertText = new vscode.SnippetString(
            method.params
              ? `${method.name}(\${1})`
              : `${method.name}()`
          );
          items.push(item);
        }

        return items;
      },
    },
    ".", ":"
  );

  // ── Invalidate cache on document change ───────────────────

  const changeListener = vscode.workspace.onDidChangeTextDocument((e) => {
    if (e.document.languageId === "lua") {
      docRegistries.delete(e.document.uri.toString());
    }
  });

  context.subscriptions.push(hoverProvider, completionProvider, changeListener);
}
