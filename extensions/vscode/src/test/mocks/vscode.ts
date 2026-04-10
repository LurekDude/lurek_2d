/**
 * Minimal mock objects for VS Code API used in unit tests.
 * These mocks replicate the portions of vscode.TextDocument, Position, Range,
 * CompletionItem, and Diagnostic needed by provider test suites.
 */

/* eslint-disable @typescript-eslint/no-explicit-any */

// ── Position & Range ────────────────────────────────────────

export class MockPosition {
  constructor(
    public readonly line: number,
    public readonly character: number,
  ) {}

  translate(lineDelta: number, charDelta: number): MockPosition {
    return new MockPosition(this.line + lineDelta, this.character + charDelta);
  }

  isEqual(other: MockPosition): boolean {
    return this.line === other.line && this.character === other.character;
  }
}

export class MockRange {
  constructor(
    public readonly start: MockPosition,
    public readonly end: MockPosition,
  ) {}

  static fromLineChar(
    startLine: number,
    startChar: number,
    endLine: number,
    endChar: number,
  ): MockRange {
    return new MockRange(
      new MockPosition(startLine, startChar),
      new MockPosition(endLine, endChar),
    );
  }
}

// ── TextDocument ────────────────────────────────────────────

export class MockTextDocument {
  readonly uri = { fsPath: "/mock/test.lua", scheme: "file" };
  readonly fileName: string;
  readonly languageId = "lua";
  readonly version = 1;
  readonly isDirty = false;
  readonly isUntitled = false;
  readonly eol = 1; // LF
  private readonly lines: string[];

  constructor(content: string, fileName = "/mock/test.lua") {
    this.lines = content.split("\n");
    this.fileName = fileName;
    this.uri = { fsPath: fileName, scheme: "file" };
  }

  get lineCount(): number {
    return this.lines.length;
  }

  lineAt(lineOrPos: number | MockPosition): { text: string; range: MockRange } {
    const lineNum =
      typeof lineOrPos === "number" ? lineOrPos : lineOrPos.line;
    const text = this.lines[lineNum] ?? "";
    return {
      text,
      range: MockRange.fromLineChar(lineNum, 0, lineNum, text.length),
    };
  }

  getText(range?: MockRange): string {
    if (!range) {
      return this.lines.join("\n");
    }
    if (range.start.line === range.end.line) {
      return (this.lines[range.start.line] ?? "").substring(
        range.start.character,
        range.end.character,
      );
    }
    const result: string[] = [];
    for (let i = range.start.line; i <= range.end.line; i++) {
      const line = this.lines[i] ?? "";
      if (i === range.start.line) {
        result.push(line.substring(range.start.character));
      } else if (i === range.end.line) {
        result.push(line.substring(0, range.end.character));
      } else {
        result.push(line);
      }
    }
    return result.join("\n");
  }

  positionAt(offset: number): MockPosition {
    let remaining = offset;
    for (let i = 0; i < this.lines.length; i++) {
      if (remaining <= this.lines[i].length) {
        return new MockPosition(i, remaining);
      }
      remaining -= this.lines[i].length + 1; // +1 for newline
    }
    const lastLine = this.lines.length - 1;
    return new MockPosition(lastLine, this.lines[lastLine]?.length ?? 0);
  }

  offsetAt(position: MockPosition): number {
    let offset = 0;
    for (let i = 0; i < position.line && i < this.lines.length; i++) {
      offset += this.lines[i].length + 1;
    }
    offset += position.character;
    return offset;
  }

  getWordRangeAtPosition(
    position: MockPosition,
    regex?: RegExp,
  ): MockRange | undefined {
    const line = this.lines[position.line] ?? "";
    const pattern = regex ?? /\w+/g;
    let match: RegExpExecArray | null;
    const searchRegex = new RegExp(pattern.source, "g");
    while ((match = searchRegex.exec(line)) !== null) {
      const start = match.index;
      const end = start + match[0].length;
      if (start <= position.character && position.character <= end) {
        return MockRange.fromLineChar(
          position.line,
          start,
          position.line,
          end,
        );
      }
    }
    return undefined;
  }
}

// ── CancellationToken ───────────────────────────────────────

export const MockCancellationToken = {
  isCancellationRequested: false,
  onCancellationRequested: () => ({ dispose: () => {} }),
};

// ── DiagnosticSeverity (mirrors vscode's enum) ─────────────

export enum MockDiagnosticSeverity {
  Error = 0,
  Warning = 1,
  Information = 2,
  Hint = 3,
}

// ── CompletionItemKind ──────────────────────────────────────

export enum MockCompletionItemKind {
  Text = 0,
  Method = 1,
  Function = 2,
  Constructor = 3,
  Field = 4,
  Variable = 5,
  Class = 6,
  Interface = 7,
  Module = 8,
  Property = 9,
  Unit = 10,
  Value = 11,
  Enum = 12,
  Keyword = 13,
  Snippet = 14,
  Color = 15,
  Reference = 17,
  File = 16,
  Folder = 18,
  EnumMember = 19,
  Constant = 20,
  Struct = 21,
  Event = 22,
  Operator = 23,
  TypeParameter = 24,
}
