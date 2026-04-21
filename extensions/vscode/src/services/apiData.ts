import * as vscode from "vscode";
import * as fs from "fs";
import * as path from "path";

// ── Public interfaces ────────────────────────────────────────

/** A single parameter of a Lurek2D API function. */
export interface ApiParam {
  name: string;
  type: string;
  description: string;
  optional: boolean;
  default?: string;
}

/** A single Lurek2D API function or method. */
export interface ApiFunction {
  module: string;
  name: string;
  fullPath: string;
  signature: string;
  description: string;
  parameters: ApiParam[];
  returns?: string;
  returnType?: string;
  since?: string;
  deprecated?: string;
  isMethod: boolean;
  objectType?: string;
  sourceFile?: string;
}

/** A Lurek2D API module (lurek.graphics, lurek.audio, etc.). */
export interface ApiModule {
  name: string;
  fullPath: string;
  description: string;
  functions: ApiFunction[];
  methods: ApiFunction[];
  totalEntries: number;
  documentedEntries: number;
}

/** A Lurek2D API enum type. */
export interface ApiEnum {
  name: string;
  values: string[];
  descriptions: Map<string, string>;
}

// ── Built-in enum definitions ────────────────────────────────

const BUILTIN_ENUMS: Record<string, { values: string[]; descriptions: Map<string, string> }> = {
  DrawMode: { values: ["fill", "line"], descriptions: new Map([["fill", "Filled shape"], ["line", "Outlined shape"]]) },
  BodyType: { values: ["static", "dynamic", "kinematic"], descriptions: new Map([["static", "Does not move"], ["dynamic", "Full physics simulation"], ["kinematic", "Moves via velocity only"]]) },
  SourceType: { values: ["static", "stream"], descriptions: new Map([["static", "Fully loaded into memory"], ["stream", "Streamed from disk"]]) },
  BlendMode: { values: ["alpha", "add", "subtract", "multiply", "premultiplied", "replace", "screen"], descriptions: new Map() },
  FilterMode: { values: ["nearest", "linear"], descriptions: new Map([["nearest", "Pixelated (sharp)"], ["linear", "Smooth (blurred)"]]) },
  WrapMode: { values: ["clamp", "clampzero", "repeat", "mirroredrepeat"], descriptions: new Map() },
  ShapeType: { values: ["circle", "rectangle", "polygon", "edge", "chain"], descriptions: new Map() },
  JointType: { values: ["distance", "revolute", "prismatic", "pulley", "gear", "weld", "friction", "motor"], descriptions: new Map() },
  AlignMode: { values: ["left", "center", "right", "justify"], descriptions: new Map() },
  ArcType: { values: ["pie", "open", "closed"], descriptions: new Map() },
  CompareMode: { values: ["equal", "notequal", "less", "lequal", "gequal", "greater", "always", "never"], descriptions: new Map() },
  LineJoin: { values: ["miter", "bevel", "none"], descriptions: new Map() },
  LineCap: { values: ["butt", "round", "square"], descriptions: new Map() },
  EasingFunction: { values: ["linear", "quad", "cubic", "quart", "quint", "sine", "expo", "circ", "back", "bounce", "elastic"], descriptions: new Map() },
};

// ── Callback definitions ─────────────────────────────────────

const CALLBACK_DEFS: { name: string; signature: string; description: string; params: ApiParam[] }[] = [
  { name: "load", signature: "lurek.load()", description: "Called once after the script is loaded.", params: [] },
  { name: "update", signature: "lurek.update(dt)", description: "Called every frame; `dt` is elapsed seconds.", params: [{ name: "dt", type: "number", description: "Delta time in seconds", optional: false }] },
  { name: "draw", signature: "lurek.draw()", description: "Called every frame for rendering.", params: [] },
  { name: "keypressed", signature: "lurek.keypressed(key)", description: "Called when a keyboard key is pressed.", params: [{ name: "key", type: "string", description: "Key name", optional: false }] },
  { name: "keyreleased", signature: "lurek.keyreleased(key)", description: "Called when a keyboard key is released.", params: [{ name: "key", type: "string", description: "Key name", optional: false }] },
  { name: "textinput", signature: "lurek.textinput(text)", description: "Called on text input.", params: [{ name: "text", type: "string", description: "Input character(s)", optional: false }] },
  { name: "mousepressed", signature: "lurek.mousepressed(x, y, button)", description: "Called when a mouse button is pressed.", params: [{ name: "x", type: "number", description: "Mouse X", optional: false }, { name: "y", type: "number", description: "Mouse Y", optional: false }, { name: "button", type: "number", description: "Button index", optional: false }] },
  { name: "mousereleased", signature: "lurek.mousereleased(x, y, button)", description: "Called when a mouse button is released.", params: [{ name: "x", type: "number", description: "Mouse X", optional: false }, { name: "y", type: "number", description: "Mouse Y", optional: false }, { name: "button", type: "number", description: "Button index", optional: false }] },
  { name: "wheelmoved", signature: "lurek.wheelmoved(x, y)", description: "Called on mouse wheel movement.", params: [{ name: "x", type: "number", description: "Horizontal scroll", optional: false }, { name: "y", type: "number", description: "Vertical scroll", optional: false }] },
  { name: "gamepadpressed", signature: "lurek.gamepadpressed(id, button)", description: "Called on gamepad button press.", params: [{ name: "id", type: "number", description: "Gamepad ID", optional: false }, { name: "button", type: "string", description: "Button name", optional: false }] },
  { name: "gamepadreleased", signature: "lurek.gamepadreleased(id, button)", description: "Called on gamepad button release.", params: [{ name: "id", type: "number", description: "Gamepad ID", optional: false }, { name: "button", type: "string", description: "Button name", optional: false }] },
  { name: "gamepadaxis", signature: "lurek.gamepadaxis(id, axis, value)", description: "Called on gamepad axis change.", params: [{ name: "id", type: "number", description: "Gamepad ID", optional: false }, { name: "axis", type: "string", description: "Axis name", optional: false }, { name: "value", type: "number", description: "Axis value", optional: false }] },
  { name: "joystickadded", signature: "lurek.joystickadded(id)", description: "Called when a gamepad is connected.", params: [{ name: "id", type: "number", description: "Gamepad ID", optional: false }] },
  { name: "joystickremoved", signature: "lurek.joystickremoved(id)", description: "Called when a gamepad is disconnected.", params: [{ name: "id", type: "number", description: "Gamepad ID", optional: false }] },
  { name: "touchpressed", signature: "lurek.touchpressed(id, x, y, dx, dy, pressure)", description: "Called on touch start.", params: [{ name: "id", type: "number", description: "Touch ID", optional: false }, { name: "x", type: "number", description: "X position", optional: false }, { name: "y", type: "number", description: "Y position", optional: false }, { name: "dx", type: "number", description: "X delta", optional: false }, { name: "dy", type: "number", description: "Y delta", optional: false }, { name: "pressure", type: "number", description: "Touch pressure", optional: false }] },
  { name: "touchmoved", signature: "lurek.touchmoved(id, x, y, dx, dy, pressure)", description: "Called on touch move.", params: [{ name: "id", type: "number", description: "Touch ID", optional: false }, { name: "x", type: "number", description: "X position", optional: false }, { name: "y", type: "number", description: "Y position", optional: false }, { name: "dx", type: "number", description: "X delta", optional: false }, { name: "dy", type: "number", description: "Y delta", optional: false }, { name: "pressure", type: "number", description: "Touch pressure", optional: false }] },
  { name: "touchreleased", signature: "lurek.touchreleased(id, x, y, dx, dy, pressure)", description: "Called on touch end.", params: [{ name: "id", type: "number", description: "Touch ID", optional: false }, { name: "x", type: "number", description: "X position", optional: false }, { name: "y", type: "number", description: "Y position", optional: false }, { name: "dx", type: "number", description: "X delta", optional: false }, { name: "dy", type: "number", description: "Y delta", optional: false }, { name: "pressure", type: "number", description: "Touch pressure", optional: false }] },
  { name: "focus", signature: "lurek.focus(has_focus)", description: "Called when window gains or loses focus.", params: [{ name: "has_focus", type: "boolean", description: "Whether window has focus", optional: false }] },
  { name: "visible", signature: "lurek.visible(is_visible)", description: "Called when window visibility changes.", params: [{ name: "is_visible", type: "boolean", description: "Whether window is visible", optional: false }] },
  { name: "resize", signature: "lurek.resize(w, h)", description: "Called when the window is resized.", params: [{ name: "w", type: "number", description: "New width", optional: false }, { name: "h", type: "number", description: "New height", optional: false }] },
  { name: "quit", signature: "lurek.quit()", description: "Called when the window is closed.", params: [] },
];

// ── Lua standard library ─────────────────────────────────────

interface StdlibEntry {
  name: string;
  signature: string;
  description: string;
  params: ApiParam[];
  returns: string;
}

interface StdlibTable {
  common: StdlibEntry[];
  lua54Only?: StdlibEntry[];
  luajitOnly?: StdlibEntry[];
}

const LUA_STDLIB: Record<string, StdlibTable> = {
  string: {
    common: [
      { name: "byte", signature: "string.byte(s, i, j)", description: "Returns the internal numeric codes of the characters s[i], s[i+1], ..., s[j].", params: [{ name: "s", type: "string", description: "Input string", optional: false }, { name: "i", type: "number", description: "Start index", optional: true, default: "1" }, { name: "j", type: "number", description: "End index", optional: true, default: "i" }], returns: "number..." },
      { name: "char", signature: "string.char(...)", description: "Returns a string with characters with the given internal numeric codes.", params: [{ name: "...", type: "number", description: "Byte values", optional: false }], returns: "string" },
      { name: "find", signature: "string.find(s, pattern, init, plain)", description: "Looks for the first match of pattern in the string.", params: [{ name: "s", type: "string", description: "Input string", optional: false }, { name: "pattern", type: "string", description: "Search pattern", optional: false }, { name: "init", type: "number", description: "Start position", optional: true, default: "1" }, { name: "plain", type: "boolean", description: "Plain text search", optional: true, default: "false" }], returns: "number, number, ...string" },
      { name: "format", signature: "string.format(formatstring, ...)", description: "Returns a formatted string following the description given in its arguments.", params: [{ name: "formatstring", type: "string", description: "Format string", optional: false }, { name: "...", type: "any", description: "Format arguments", optional: true }], returns: "string" },
      { name: "gmatch", signature: "string.gmatch(s, pattern)", description: "Returns an iterator function that returns the next captures from pattern over string s.", params: [{ name: "s", type: "string", description: "Input string", optional: false }, { name: "pattern", type: "string", description: "Pattern", optional: false }], returns: "function" },
      { name: "gsub", signature: "string.gsub(s, pattern, repl, n)", description: "Returns a copy of s in which all (or the first n) occurrences of the pattern are replaced.", params: [{ name: "s", type: "string", description: "Input string", optional: false }, { name: "pattern", type: "string", description: "Pattern", optional: false }, { name: "repl", type: "string|table|function", description: "Replacement", optional: false }, { name: "n", type: "number", description: "Max replacements", optional: true }], returns: "string, number" },
      { name: "len", signature: "string.len(s)", description: "Returns the length of the string.", params: [{ name: "s", type: "string", description: "Input string", optional: false }], returns: "number" },
      { name: "lower", signature: "string.lower(s)", description: "Returns a copy of this string with all uppercase letters changed to lowercase.", params: [{ name: "s", type: "string", description: "Input string", optional: false }], returns: "string" },
      { name: "match", signature: "string.match(s, pattern, init)", description: "Looks for the first match of pattern in the string.", params: [{ name: "s", type: "string", description: "Input string", optional: false }, { name: "pattern", type: "string", description: "Pattern", optional: false }, { name: "init", type: "number", description: "Start position", optional: true, default: "1" }], returns: "string..." },
      { name: "rep", signature: "string.rep(s, n, sep)", description: "Returns a string that is the concatenation of n copies of the string s.", params: [{ name: "s", type: "string", description: "Input string", optional: false }, { name: "n", type: "number", description: "Repetitions", optional: false }, { name: "sep", type: "string", description: "Separator", optional: true, default: '""' }], returns: "string" },
      { name: "reverse", signature: "string.reverse(s)", description: "Returns a string that is the string s reversed.", params: [{ name: "s", type: "string", description: "Input string", optional: false }], returns: "string" },
      { name: "sub", signature: "string.sub(s, i, j)", description: "Returns the substring from i to j.", params: [{ name: "s", type: "string", description: "Input string", optional: false }, { name: "i", type: "number", description: "Start index", optional: false }, { name: "j", type: "number", description: "End index", optional: true, default: "-1" }], returns: "string" },
      { name: "upper", signature: "string.upper(s)", description: "Returns a copy of this string with all lowercase letters changed to uppercase.", params: [{ name: "s", type: "string", description: "Input string", optional: false }], returns: "string" },
      { name: "dump", signature: "string.dump(function, strip)", description: "Returns a string containing a binary representation of the given function.", params: [{ name: "function", type: "function", description: "Function to dump", optional: false }, { name: "strip", type: "boolean", description: "Strip debug info", optional: true }], returns: "string" },
    ],
  },
  table: {
    common: [
      { name: "concat", signature: "table.concat(list, sep, i, j)", description: "Concatenates elements of a table into a string.", params: [{ name: "list", type: "table", description: "Input table", optional: false }, { name: "sep", type: "string", description: "Separator", optional: true, default: '""' }, { name: "i", type: "number", description: "Start index", optional: true, default: "1" }, { name: "j", type: "number", description: "End index", optional: true, default: "#list" }], returns: "string" },
      { name: "insert", signature: "table.insert(list, pos, value)", description: "Inserts element value at position pos in list.", params: [{ name: "list", type: "table", description: "Target table", optional: false }, { name: "pos", type: "number", description: "Position", optional: true }, { name: "value", type: "any", description: "Value to insert", optional: false }], returns: "nil" },
      { name: "remove", signature: "table.remove(list, pos)", description: "Removes from list the element at position pos.", params: [{ name: "list", type: "table", description: "Target table", optional: false }, { name: "pos", type: "number", description: "Position", optional: true, default: "#list" }], returns: "any" },
      { name: "sort", signature: "table.sort(list, comp)", description: "Sorts list elements in-place using the given comparison function.", params: [{ name: "list", type: "table", description: "Table to sort", optional: false }, { name: "comp", type: "function", description: "Comparison function", optional: true }], returns: "nil" },
      { name: "unpack", signature: "table.unpack(list, i, j)", description: "Returns the elements from the given table.", params: [{ name: "list", type: "table", description: "Input table", optional: false }, { name: "i", type: "number", description: "Start index", optional: true, default: "1" }, { name: "j", type: "number", description: "End index", optional: true, default: "#list" }], returns: "any..." },
    ],
    lua54Only: [
      { name: "move", signature: "table.move(a1, f, e, t, a2)", description: "Moves elements from table a1 into table a2.", params: [{ name: "a1", type: "table", description: "Source table", optional: false }, { name: "f", type: "number", description: "From index", optional: false }, { name: "e", type: "number", description: "End index", optional: false }, { name: "t", type: "number", description: "Target start", optional: false }, { name: "a2", type: "table", description: "Dest table", optional: true, default: "a1" }], returns: "table" },
      { name: "pack", signature: "table.pack(...)", description: "Returns a new table with all arguments stored into keys 1, 2, etc.", params: [{ name: "...", type: "any", description: "Values to pack", optional: false }], returns: "table" },
    ],
    luajitOnly: [
      { name: "new", signature: "table.new(narray, nhash)", description: "Pre-allocates a table with the given number of array and hash slots.", params: [{ name: "narray", type: "number", description: "Array slots", optional: false }, { name: "nhash", type: "number", description: "Hash slots", optional: false }], returns: "table" },
      { name: "clear", signature: "table.clear(tab)", description: "Clears all keys and values from a table.", params: [{ name: "tab", type: "table", description: "Table to clear", optional: false }], returns: "nil" },
    ],
  },
  math: {
    common: [
      { name: "abs", signature: "math.abs(x)", description: "Returns the absolute value of x.", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "number" },
      { name: "acos", signature: "math.acos(x)", description: "Returns the arc cosine of x (in radians).", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "number" },
      { name: "asin", signature: "math.asin(x)", description: "Returns the arc sine of x (in radians).", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "number" },
      { name: "atan", signature: "math.atan(y, x)", description: "Returns the arc tangent of y/x (in radians).", params: [{ name: "y", type: "number", description: "Y value", optional: false }, { name: "x", type: "number", description: "X value", optional: true, default: "1" }], returns: "number" },
      { name: "ceil", signature: "math.ceil(x)", description: "Returns the smallest integer larger than or equal to x.", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "number" },
      { name: "cos", signature: "math.cos(x)", description: "Returns the cosine of x (in radians).", params: [{ name: "x", type: "number", description: "Angle in radians", optional: false }], returns: "number" },
      { name: "deg", signature: "math.deg(x)", description: "Converts angle x from radians to degrees.", params: [{ name: "x", type: "number", description: "Angle in radians", optional: false }], returns: "number" },
      { name: "exp", signature: "math.exp(x)", description: "Returns the value e^x.", params: [{ name: "x", type: "number", description: "Exponent", optional: false }], returns: "number" },
      { name: "floor", signature: "math.floor(x)", description: "Returns the largest integer smaller than or equal to x.", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "number" },
      { name: "fmod", signature: "math.fmod(x, y)", description: "Returns the remainder of the division of x by y.", params: [{ name: "x", type: "number", description: "Dividend", optional: false }, { name: "y", type: "number", description: "Divisor", optional: false }], returns: "number" },
      { name: "huge", signature: "math.huge", description: "The value HUGE_VAL, representing positive infinity.", params: [], returns: "number" },
      { name: "log", signature: "math.log(x, base)", description: "Returns the logarithm of x in the given base.", params: [{ name: "x", type: "number", description: "Input value", optional: false }, { name: "base", type: "number", description: "Log base", optional: true, default: "e" }], returns: "number" },
      { name: "max", signature: "math.max(x, ...)", description: "Returns the maximum value among its arguments.", params: [{ name: "x", type: "number", description: "First value", optional: false }, { name: "...", type: "number", description: "More values", optional: true }], returns: "number" },
      { name: "min", signature: "math.min(x, ...)", description: "Returns the minimum value among its arguments.", params: [{ name: "x", type: "number", description: "First value", optional: false }, { name: "...", type: "number", description: "More values", optional: true }], returns: "number" },
      { name: "modf", signature: "math.modf(x)", description: "Returns the integral and fractional parts of x.", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "number, number" },
      { name: "pi", signature: "math.pi", description: "The value of pi.", params: [], returns: "number" },
      { name: "rad", signature: "math.rad(x)", description: "Converts angle x from degrees to radians.", params: [{ name: "x", type: "number", description: "Angle in degrees", optional: false }], returns: "number" },
      { name: "random", signature: "math.random(m, n)", description: "Returns a pseudo-random number.", params: [{ name: "m", type: "number", description: "Lower bound", optional: true }, { name: "n", type: "number", description: "Upper bound", optional: true }], returns: "number" },
      { name: "randomseed", signature: "math.randomseed(x)", description: "Sets x as the seed for the pseudo-random generator.", params: [{ name: "x", type: "number", description: "Seed value", optional: false }], returns: "nil" },
      { name: "sin", signature: "math.sin(x)", description: "Returns the sine of x (in radians).", params: [{ name: "x", type: "number", description: "Angle in radians", optional: false }], returns: "number" },
      { name: "sqrt", signature: "math.sqrt(x)", description: "Returns the square root of x.", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "number" },
      { name: "tan", signature: "math.tan(x)", description: "Returns the tangent of x (in radians).", params: [{ name: "x", type: "number", description: "Angle in radians", optional: false }], returns: "number" },
    ],
    lua54Only: [
      { name: "maxinteger", signature: "math.maxinteger", description: "An integer with the maximum value for an integer.", params: [], returns: "integer" },
      { name: "mininteger", signature: "math.mininteger", description: "An integer with the minimum value for an integer.", params: [], returns: "integer" },
      { name: "tointeger", signature: "math.tointeger(x)", description: "If x is convertible to an integer, returns that integer.", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "integer|nil" },
      { name: "type", signature: "math.type(x)", description: "Returns 'integer', 'float', or false.", params: [{ name: "x", type: "any", description: "Value to check", optional: false }], returns: "string|false" },
      { name: "ult", signature: "math.ult(m, n)", description: "Returns true if m < n when compared as unsigned integers.", params: [{ name: "m", type: "integer", description: "First value", optional: false }, { name: "n", type: "integer", description: "Second value", optional: false }], returns: "boolean" },
    ],
  },
  os: {
    common: [
      { name: "clock", signature: "os.clock()", description: "Returns CPU time used by the program in seconds.", params: [], returns: "number" },
      { name: "date", signature: "os.date(format, time)", description: "Returns a string or table with date and time.", params: [{ name: "format", type: "string", description: "Date format", optional: true, default: '"%c"' }, { name: "time", type: "number", description: "Time value", optional: true }], returns: "string|table" },
      { name: "difftime", signature: "os.difftime(t2, t1)", description: "Returns the difference in seconds between two times.", params: [{ name: "t2", type: "number", description: "End time", optional: false }, { name: "t1", type: "number", description: "Start time", optional: false }], returns: "number" },
      { name: "time", signature: "os.time(table)", description: "Returns the current time or converts the given table to a timestamp.", params: [{ name: "table", type: "table", description: "Date table", optional: true }], returns: "number" },
    ],
  },
  io: {
    common: [
      { name: "close", signature: "io.close(file)", description: "Closes file, or the default output file.", params: [{ name: "file", type: "file", description: "File handle", optional: true }], returns: "boolean" },
      { name: "lines", signature: "io.lines(filename, ...)", description: "Opens the given file and returns an iterator function.", params: [{ name: "filename", type: "string", description: "File path", optional: true }, { name: "...", type: "string|number", description: "Read formats", optional: true }], returns: "function" },
      { name: "open", signature: "io.open(filename, mode)", description: "Opens a file in the given mode.", params: [{ name: "filename", type: "string", description: "File path", optional: false }, { name: "mode", type: "string", description: "Open mode", optional: true, default: '"r"' }], returns: "file|nil, string" },
      { name: "read", signature: "io.read(...)", description: "Reads from the default input file.", params: [{ name: "...", type: "string|number", description: "Read formats", optional: true }], returns: "string|number|nil" },
      { name: "write", signature: "io.write(...)", description: "Writes to the default output file.", params: [{ name: "...", type: "string|number", description: "Values to write", optional: false }], returns: "file|nil, string" },
      { name: "type", signature: "io.type(obj)", description: "Checks whether obj is a valid file handle.", params: [{ name: "obj", type: "any", description: "Value to check", optional: false }], returns: "string|nil" },
    ],
  },
  coroutine: {
    common: [
      { name: "create", signature: "coroutine.create(f)", description: "Creates a new coroutine with body f.", params: [{ name: "f", type: "function", description: "Coroutine body", optional: false }], returns: "thread" },
      { name: "resume", signature: "coroutine.resume(co, ...)", description: "Starts or continues the execution of coroutine co.", params: [{ name: "co", type: "thread", description: "Coroutine", optional: false }, { name: "...", type: "any", description: "Arguments", optional: true }], returns: "boolean, any..." },
      { name: "yield", signature: "coroutine.yield(...)", description: "Suspends the execution of the calling coroutine.", params: [{ name: "...", type: "any", description: "Values to yield", optional: true }], returns: "any..." },
      { name: "status", signature: "coroutine.status(co)", description: "Returns the status of coroutine co.", params: [{ name: "co", type: "thread", description: "Coroutine", optional: false }], returns: "string" },
      { name: "wrap", signature: "coroutine.wrap(f)", description: "Creates a coroutine and returns a resume function.", params: [{ name: "f", type: "function", description: "Coroutine body", optional: false }], returns: "function" },
      { name: "isyieldable", signature: "coroutine.isyieldable()", description: "Returns true if the running coroutine can yield.", params: [], returns: "boolean" },
      { name: "running", signature: "coroutine.running()", description: "Returns the running coroutine plus a boolean.", params: [], returns: "thread, boolean" },
    ],
  },
  debug: {
    common: [
      { name: "getinfo", signature: "debug.getinfo(f, what)", description: "Returns a table with information about a function.", params: [{ name: "f", type: "function|number", description: "Function or stack level", optional: false }, { name: "what", type: "string", description: "Info selector", optional: true }], returns: "table" },
      { name: "getlocal", signature: "debug.getlocal(f, local)", description: "Returns name and value of local variable.", params: [{ name: "f", type: "function|number", description: "Function or stack level", optional: false }, { name: "local", type: "number", description: "Local index", optional: false }], returns: "string, any" },
      { name: "sethook", signature: "debug.sethook(hook, mask, count)", description: "Sets the given function as a hook.", params: [{ name: "hook", type: "function", description: "Hook function", optional: false }, { name: "mask", type: "string", description: "Hook mask", optional: false }, { name: "count", type: "number", description: "Instruction count", optional: true }], returns: "nil" },
      { name: "traceback", signature: "debug.traceback(message, level)", description: "Returns a string with a traceback of the call stack.", params: [{ name: "message", type: "string", description: "Prefix message", optional: true }, { name: "level", type: "number", description: "Stack level", optional: true, default: "1" }], returns: "string" },
    ],
  },
  package: {
    common: [
      { name: "loaded", signature: "package.loaded", description: "A table of already-loaded modules.", params: [], returns: "table" },
      { name: "path", signature: "package.path", description: "The path used by require to search for a Lua loader.", params: [], returns: "string" },
      { name: "preload", signature: "package.preload", description: "A table to store loaders for specific modules.", params: [], returns: "table" },
      { name: "searchpath", signature: "package.searchpath(name, path, sep, rep)", description: "Searches for the given name in the given path.", params: [{ name: "name", type: "string", description: "Module name", optional: false }, { name: "path", type: "string", description: "Search path", optional: false }, { name: "sep", type: "string", description: "Name separator", optional: true, default: '"."' }, { name: "rep", type: "string", description: "Replacement", optional: true, default: '"/"' }], returns: "string|nil, string" },
    ],
  },
  utf8: {
    common: [],
    lua54Only: [
      { name: "char", signature: "utf8.char(...)", description: "Returns a UTF-8 string from one or more codepoints.", params: [{ name: "...", type: "number", description: "Codepoints", optional: false }], returns: "string" },
      { name: "codepoint", signature: "utf8.codepoint(s, i, j)", description: "Returns the codepoints of all characters in s between positions i and j.", params: [{ name: "s", type: "string", description: "Input string", optional: false }, { name: "i", type: "number", description: "Start", optional: true, default: "1" }, { name: "j", type: "number", description: "End", optional: true, default: "i" }], returns: "number..." },
      { name: "codes", signature: "utf8.codes(s)", description: "Returns an iterator for all codepoints in string s.", params: [{ name: "s", type: "string", description: "Input string", optional: false }], returns: "function" },
      { name: "len", signature: "utf8.len(s, i, j)", description: "Returns the number of UTF-8 characters in string s.", params: [{ name: "s", type: "string", description: "Input string", optional: false }, { name: "i", type: "number", description: "Start byte", optional: true, default: "1" }, { name: "j", type: "number", description: "End byte", optional: true, default: "-1" }], returns: "number|nil, number" },
      { name: "offset", signature: "utf8.offset(s, n, i)", description: "Returns the byte position where the n-th character starts.", params: [{ name: "s", type: "string", description: "Input string", optional: false }, { name: "n", type: "number", description: "Character offset", optional: false }, { name: "i", type: "number", description: "Start byte", optional: true }], returns: "number" },
      { name: "charpattern", signature: "utf8.charpattern", description: "The pattern that matches exactly one UTF-8 byte sequence.", params: [], returns: "string" },
    ],
  },
  bit: {
    common: [],
    luajitOnly: [
      { name: "tobit", signature: "bit.tobit(x)", description: "Normalizes a number to the numeric range of a 32-bit integer.", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "number" },
      { name: "tohex", signature: "bit.tohex(x, n)", description: "Converts x to a hex string with n digits.", params: [{ name: "x", type: "number", description: "Input value", optional: false }, { name: "n", type: "number", description: "Number of digits", optional: true }], returns: "string" },
      { name: "bnot", signature: "bit.bnot(x)", description: "Returns the bitwise NOT of x.", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "number" },
      { name: "band", signature: "bit.band(x1, ...)", description: "Returns the bitwise AND of all arguments.", params: [{ name: "x1", type: "number", description: "First value", optional: false }, { name: "...", type: "number", description: "More values", optional: true }], returns: "number" },
      { name: "bor", signature: "bit.bor(x1, ...)", description: "Returns the bitwise OR of all arguments.", params: [{ name: "x1", type: "number", description: "First value", optional: false }, { name: "...", type: "number", description: "More values", optional: true }], returns: "number" },
      { name: "bxor", signature: "bit.bxor(x1, ...)", description: "Returns the bitwise XOR of all arguments.", params: [{ name: "x1", type: "number", description: "First value", optional: false }, { name: "...", type: "number", description: "More values", optional: true }], returns: "number" },
      { name: "lshift", signature: "bit.lshift(x, n)", description: "Returns x logically shifted left by n bits.", params: [{ name: "x", type: "number", description: "Input value", optional: false }, { name: "n", type: "number", description: "Shift amount", optional: false }], returns: "number" },
      { name: "rshift", signature: "bit.rshift(x, n)", description: "Returns x logically shifted right by n bits.", params: [{ name: "x", type: "number", description: "Input value", optional: false }, { name: "n", type: "number", description: "Shift amount", optional: false }], returns: "number" },
      { name: "arshift", signature: "bit.arshift(x, n)", description: "Returns x arithmetically shifted right by n bits.", params: [{ name: "x", type: "number", description: "Input value", optional: false }, { name: "n", type: "number", description: "Shift amount", optional: false }], returns: "number" },
      { name: "rol", signature: "bit.rol(x, n)", description: "Returns x rotated left by n bits.", params: [{ name: "x", type: "number", description: "Input value", optional: false }, { name: "n", type: "number", description: "Rotation amount", optional: false }], returns: "number" },
      { name: "ror", signature: "bit.ror(x, n)", description: "Returns x rotated right by n bits.", params: [{ name: "x", type: "number", description: "Input value", optional: false }, { name: "n", type: "number", description: "Rotation amount", optional: false }], returns: "number" },
      { name: "bswap", signature: "bit.bswap(x)", description: "Swaps the bytes of x (byte-reverse).", params: [{ name: "x", type: "number", description: "Input value", optional: false }], returns: "number" },
    ],
  },
  jit: {
    common: [],
    luajitOnly: [
      { name: "on", signature: "jit.on(func, recursive)", description: "Enables JIT compilation.", params: [{ name: "func", type: "function", description: "Function or true for all", optional: true }, { name: "recursive", type: "boolean", description: "Include sub-functions", optional: true }], returns: "nil" },
      { name: "off", signature: "jit.off(func, recursive)", description: "Disables JIT compilation.", params: [{ name: "func", type: "function", description: "Function or true for all", optional: true }, { name: "recursive", type: "boolean", description: "Include sub-functions", optional: true }], returns: "nil" },
      { name: "flush", signature: "jit.flush(func, recursive)", description: "Flushes the compiled code cache.", params: [{ name: "func", type: "function", description: "Function to flush", optional: true }, { name: "recursive", type: "boolean", description: "Include sub-functions", optional: true }], returns: "nil" },
      { name: "status", signature: "jit.status()", description: "Returns the current JIT status and architecture.", params: [], returns: "boolean, string..." },
      { name: "version", signature: "jit.version", description: "The LuaJIT version string.", params: [], returns: "string" },
      { name: "version_num", signature: "jit.version_num", description: "The LuaJIT version number.", params: [], returns: "number" },
      { name: "os", signature: "jit.os", description: "The target OS name.", params: [], returns: "string" },
      { name: "arch", signature: "jit.arch", description: "The target architecture name.", params: [], returns: "string" },
    ],
  },
  ffi: {
    common: [],
    luajitOnly: [
      { name: "cdef", signature: "ffi.cdef(def)", description: "Adds C declarations.", params: [{ name: "def", type: "string", description: "C declarations", optional: false }], returns: "nil" },
      { name: "new", signature: "ffi.new(ctype, ...)", description: "Creates a C data object of the given type.", params: [{ name: "ctype", type: "string|ctype", description: "C type", optional: false }, { name: "...", type: "any", description: "Initializers", optional: true }], returns: "cdata" },
      { name: "cast", signature: "ffi.cast(ctype, init)", description: "Creates a scalar C data object with ctype and init.", params: [{ name: "ctype", type: "string|ctype", description: "Target type", optional: false }, { name: "init", type: "any", description: "Initial value", optional: false }], returns: "cdata" },
      { name: "typeof", signature: "ffi.typeof(ctype)", description: "Creates a C type object.", params: [{ name: "ctype", type: "string", description: "C type declaration", optional: false }], returns: "ctype" },
      { name: "sizeof", signature: "ffi.sizeof(ctype, nelem)", description: "Returns the size of a C type in bytes.", params: [{ name: "ctype", type: "string|ctype|cdata", description: "C type", optional: false }, { name: "nelem", type: "number", description: "Number of elements", optional: true }], returns: "number" },
      { name: "alignof", signature: "ffi.alignof(ctype)", description: "Returns the minimum required alignment of a C type.", params: [{ name: "ctype", type: "string|ctype", description: "C type", optional: false }], returns: "number" },
      { name: "istype", signature: "ffi.istype(ctype, obj)", description: "Returns true if obj has the given C type.", params: [{ name: "ctype", type: "string|ctype", description: "C type", optional: false }, { name: "obj", type: "any", description: "Object to check", optional: false }], returns: "boolean" },
      { name: "load", signature: "ffi.load(name, global)", description: "Loads a shared library.", params: [{ name: "name", type: "string", description: "Library name", optional: false }, { name: "global", type: "boolean", description: "Export symbols globally", optional: true }], returns: "clib" },
      { name: "string", signature: "ffi.string(ptr, len)", description: "Creates a Lua string from a C char pointer.", params: [{ name: "ptr", type: "cdata", description: "Char pointer", optional: false }, { name: "len", type: "number", description: "Length", optional: true }], returns: "string" },
      { name: "copy", signature: "ffi.copy(dst, src, len)", description: "Copies data between C objects.", params: [{ name: "dst", type: "cdata", description: "Destination", optional: false }, { name: "src", type: "cdata|string", description: "Source", optional: false }, { name: "len", type: "number", description: "Byte count", optional: true }], returns: "nil" },
      { name: "fill", signature: "ffi.fill(dst, len, c)", description: "Fills a memory region with a byte value.", params: [{ name: "dst", type: "cdata", description: "Destination", optional: false }, { name: "len", type: "number", description: "Byte count", optional: false }, { name: "c", type: "number", description: "Fill byte", optional: true, default: "0" }], returns: "nil" },
      { name: "gc", signature: "ffi.gc(cdata, finalizer)", description: "Associates a finalizer with a C data object.", params: [{ name: "cdata", type: "cdata", description: "C data object", optional: false }, { name: "finalizer", type: "function", description: "Finalizer function", optional: false }], returns: "cdata" },
    ],
  },
};

// ── Service class ────────────────────────────────────────────

/**
 * Loads and serves Lurek2D API metadata to all language providers.
 * Parses the generated API reference markdown and provides fast
 * lookup by module, function name, object type, and full path.
 */
export class ApiDataService {
  private modules: Map<string, ApiModule> = new Map();
  private allFunctions: Map<string, ApiFunction> = new Map();
  private enums: Map<string, ApiEnum> = new Map();
  private methodsByObjectType: Map<string, ApiFunction[]> = new Map();
  private callbackList: ApiFunction[] = [];
  private loaded: boolean = false;

  /** Load API data from available sources. */
  async load(extensionPath: string): Promise<void> {
    if (this.loaded) return;

    // Priority 1: docs/API/lurek.lua (full LuaCATS reference)
    const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (wsRoot) {
      const luaCatsPath = path.join(wsRoot, "docs", "API", "lurek.lua");
      if (fs.existsSync(luaCatsPath)) {
        try {
          const raw = fs.readFileSync(luaCatsPath, "utf-8");
          this.loadFromLurekLua(raw);
          this.initEnums();
          this.initCallbacks();
          this.loaded = true;
          return;
        } catch {
          // fall through
        }
      }

      // Priority 2: docs/API/api_data.json (precompiled)
      const jsonPath = path.join(wsRoot, "docs", "API", "api_data.json");
      if (fs.existsSync(jsonPath)) {
        try {
          const raw = fs.readFileSync(jsonPath, "utf-8");
          this.loadFromJson(JSON.parse(raw));
          this.initEnums();
          this.initCallbacks();
          this.loaded = true;
          return;
        } catch {
          // fall through
        }
      }
    }

    // Priority 3: data/api-data.json bundled with extension
    const bundledJson = path.join(extensionPath, "data", "api-data.json");
    if (fs.existsSync(bundledJson)) {
      try {
        const raw = fs.readFileSync(bundledJson, "utf-8");
        this.loadFromJson(JSON.parse(raw));
        this.initEnums();
        this.initCallbacks();
        this.loaded = true;
        return;
      } catch {
        // fall through
      }
    }

    // Priority 4: docs/API/lua-api.md (compact generated reference)
    if (wsRoot) {
      const mdPath = path.join(wsRoot, "docs", "API", "lua-api.md");
      if (fs.existsSync(mdPath)) {
        try {
          const md = fs.readFileSync(mdPath, "utf-8");
          this.loadFromLuaApiMd(md);
          this.initEnums();
          this.initCallbacks();
          this.loaded = true;
          return;
        } catch {
          // fall through
        }
      }
    }

    // Priority 4: hardcoded fallback
    this.loadFallback();
    this.initEnums();
    this.initCallbacks();
    this.loaded = true;
  }

  // ── Module access ──────────────────────────────────────────

  getModuleNames(): string[] {
    return Array.from(this.modules.keys());
  }

  getModule(name: string): ApiModule | undefined {
    return this.modules.get(name);
  }

  // ── Function access ────────────────────────────────────────

  getFunctions(moduleName: string): ApiFunction[] {
    return this.modules.get(moduleName)?.functions ?? [];
  }

  getFunction(fullPath: string): ApiFunction | undefined {
    return this.allFunctions.get(fullPath);
  }

  getAllFunctions(): ApiFunction[] {
    return Array.from(this.allFunctions.values());
  }

  searchFunctions(query: string): ApiFunction[] {
    const lower = query.toLowerCase();
    const results: ApiFunction[] = [];
    for (const fn of this.allFunctions.values()) {
      if (
        fn.fullPath.toLowerCase().includes(lower) ||
        fn.name.toLowerCase().includes(lower) ||
        fn.description.toLowerCase().includes(lower)
      ) {
        results.push(fn);
      }
    }
    return results;
  }

  // ── Method access ──────────────────────────────────────────

  getMethods(objectType: string): ApiFunction[] {
    return this.methodsByObjectType.get(objectType) ?? [];
  }

  getMethod(objectType: string, methodName: string): ApiFunction | undefined {
    const methods = this.methodsByObjectType.get(objectType);
    return methods?.find(m => m.name === methodName);
  }

  // ── Enum access ────────────────────────────────────────────

  getEnumValues(enumName: string): string[] {
    return this.enums.get(enumName)?.values ?? [];
  }

  getEnum(name: string): ApiEnum | undefined {
    return this.enums.get(name);
  }

  // ── Callbacks ──────────────────────────────────────────────

  getCallbacks(): ApiFunction[] {
    return this.callbackList;
  }

  // ── Lua stdlib ─────────────────────────────────────────────

  getLuaStdlib(version: "luajit" | "5.4"): ApiFunction[] {
    const result: ApiFunction[] = [];
    for (const [tableName, data] of Object.entries(LUA_STDLIB)) {
      for (const entry of data.common) {
        result.push(this.stdlibToApiFunction(tableName, entry));
      }
      if (version === "5.4" && data.lua54Only) {
        for (const entry of data.lua54Only) {
          result.push(this.stdlibToApiFunction(tableName, entry));
        }
      }
      if (version === "luajit" && data.luajitOnly) {
        for (const entry of data.luajitOnly) {
          result.push(this.stdlibToApiFunction(tableName, entry));
        }
      }
    }
    return result;
  }

  // ── Stats ──────────────────────────────────────────────────

  getStats(): { modules: number; functions: number; methods: number; documented: number } {
    let functions = 0;
    let methods = 0;
    let documented = 0;
    for (const mod of this.modules.values()) {
      functions += mod.functions.length;
      methods += mod.methods.length;
      documented += mod.documentedEntries;
    }
    return { modules: this.modules.size, functions, methods, documented };
  }

  // ── JSON loader ────────────────────────────────────────────

  private loadFromJson(data: unknown): void {
    if (!data || typeof data !== "object") return;
    const obj = data as Record<string, unknown>;

    if (Array.isArray(obj.modules)) {
      for (const raw of obj.modules as Record<string, unknown>[]) {
        const modName = String(raw.name ?? "");
        const mod: ApiModule = {
          name: modName,
          fullPath: `lurek.${modName}`,
          description: String(raw.description ?? ""),
          functions: [],
          methods: [],
          totalEntries: 0,
          documentedEntries: 0,
        };

        const rawFunctions = Array.isArray(raw.functions) ? raw.functions as Record<string, unknown>[] : [];
        for (const rf of rawFunctions) {
          const fn = this.rawToApiFunction(modName, rf);
          if (fn.isMethod) {
            mod.methods.push(fn);
            this.indexMethod(fn);
          } else {
            mod.functions.push(fn);
          }
          this.allFunctions.set(fn.fullPath, fn);
        }

        // Also check for separate methods array
        const rawMethods = Array.isArray(raw.methods) ? raw.methods as Record<string, unknown>[] : [];
        for (const rm of rawMethods) {
          const fn = this.rawToApiFunction(modName, rm);
          fn.isMethod = true;
          mod.methods.push(fn);
          this.indexMethod(fn);
          this.allFunctions.set(fn.fullPath, fn);
        }

        mod.totalEntries = mod.functions.length + mod.methods.length;
        mod.documentedEntries = [...mod.functions, ...mod.methods].filter(f => f.description.length > 0).length;
        this.modules.set(modName, mod);
      }
    }
  }

  private rawToApiFunction(modName: string, raw: Record<string, unknown>): ApiFunction {
    const name = String(raw.name ?? "");
    const fullPath = String(raw.fullPath ?? `lurek.${modName}.${name}`);
    const params: ApiParam[] = Array.isArray(raw.parameters)
      ? (raw.parameters as Record<string, unknown>[]).map(p => ({
          name: String(p.name ?? ""),
          type: String(p.type ?? "any"),
          description: String(p.description ?? ""),
          optional: Boolean(p.optional),
          default: p.default != null ? String(p.default) : undefined,
        }))
      : [];

    return {
      module: modName,
      name,
      fullPath,
      signature: String(raw.signature ?? `${fullPath}(${params.map(p => p.name).join(", ")})`),
      description: String(raw.description ?? ""),
      parameters: params,
      returns: raw.returns != null ? String(raw.returns) : undefined,
      returnType: raw.returnType != null ? String(raw.returnType) : undefined,
      since: raw.since != null ? String(raw.since) : undefined,
      deprecated: raw.deprecated != null ? String(raw.deprecated) : undefined,
      isMethod: Boolean(raw.isMethod),
      objectType: raw.objectType != null ? String(raw.objectType) : undefined,
      sourceFile: raw.sourceFile != null ? String(raw.sourceFile) : undefined,
    };
  }

  // ── Markdown loader ────────────────────────────────────────

  private loadFromMarkdown(md: string): void {
    const lines = md.split("\n");
    let currentModule: ApiModule | null = null;
    let currentFunc: Partial<ApiFunction> | null = null;
    let currentObjectType: string | null = null;
    let inParams = false;
    let inMethodsSection = false;

    const flushFunc = (): void => {
      if (!currentFunc || !currentModule || !currentFunc.name) {
        currentFunc = null;
        inParams = false;
        return;
      }

      // Clean up description — remove stray "Lua API:" and duplicated short sentences
      let desc = (currentFunc.description ?? "").trim();
      desc = desc.replace(/\s*Lurek2D [\w]+ API function\.\s*/g, " ").trim();

      const fn: ApiFunction = {
        module: currentModule.name,
        name: currentFunc.name,
        fullPath: currentFunc.fullPath ?? `lurek.${currentModule.name}.${currentFunc.name}`,
        signature: currentFunc.signature ?? "",
        description: desc,
        parameters: currentFunc.parameters ?? [],
        returns: currentFunc.returns,
        returnType: currentFunc.returnType ?? inferReturnType(currentFunc.returns),
        since: currentFunc.since,
        deprecated: currentFunc.deprecated,
        isMethod: currentFunc.isMethod ?? false,
        objectType: currentFunc.objectType,
        sourceFile: currentFunc.sourceFile,
      };

      if (!fn.signature) {
        const pStr = fn.parameters.map(p => p.optional ? `[${p.name}]` : p.name).join(", ");
        fn.signature = fn.isMethod
          ? `${fn.objectType ?? "obj"}:${fn.name}(${pStr})`
          : `${fn.fullPath}(${pStr})`;
      }

      if (fn.isMethod) {
        currentModule.methods.push(fn);
        this.indexMethod(fn);
      } else {
        currentModule.functions.push(fn);
      }
      this.allFunctions.set(fn.fullPath, fn);

      currentFunc = null;
      inParams = false;
    };

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      // ── Module header: ## lurek.graphics ──
      const modMatch = line.match(/^## (?:lurek\.)?(\w+)/);
      if (modMatch && !line.startsWith("## Contents") && !line.startsWith("## Callbacks")) {
        flushFunc();
        if (currentModule) {
          currentModule.totalEntries = currentModule.functions.length + currentModule.methods.length;
          currentModule.documentedEntries = [...currentModule.functions, ...currentModule.methods]
            .filter(f => f.description.length > 0).length;
          this.modules.set(currentModule.name, currentModule);
        }
        const modName = modMatch[1].toLowerCase().replace(/-/g, "_");
        currentModule = {
          name: modName,
          fullPath: `lurek.${modName}`,
          description: "",
          functions: [],
          methods: [],
          totalEntries: 0,
          documentedEntries: 0,
        };
        currentObjectType = null;
        inMethodsSection = false;

        // Try to extract module description from the line after header
        const nextLine = i + 1 < lines.length ? lines[i + 1] : "";
        if (nextLine && !nextLine.startsWith("#") && !nextLine.startsWith("*") && nextLine.trim().length > 0) {
          currentModule.description = nextLine.trim();
        }

        // Try to extract entry counts: *119 entries | 119 documented*
        const countLine = lines[i + 1] ?? lines[i + 2] ?? "";
        const countMatch = countLine.match(/\*(\d+)\s+entries?\s*\|\s*(\d+)\s+documented\*/);
        if (countMatch) {
          currentModule.totalEntries = parseInt(countMatch[1], 10);
          currentModule.documentedEntries = parseInt(countMatch[2], 10);
        }
        continue;
      }

      // ── Section headers: ### Functions / ### Methods / ### Canvas Methods ──
      const sectionMatch = line.match(/^### (?:(\w+)\s+)?Methods$/);
      if (sectionMatch && currentModule) {
        flushFunc();
        inMethodsSection = true;
        currentObjectType = sectionMatch[1] ?? null;
        continue;
      }
      if (line.match(/^### Functions$/)) {
        flushFunc();
        inMethodsSection = false;
        currentObjectType = null;
        continue;
      }

      // ── Function header: #### `lurek.graphics.arc(mode, x, y, ...)` ──
      const funcMatch = line.match(
        /^#{3,4}\s+`?lurek\.(\w+)\.(\w+)(?:\(([^)]*)\))?`?/
      );
      if (funcMatch && currentModule) {
        flushFunc();
        const [, , funcName, argStr] = funcMatch;
        const paramNames = argStr
          ? argStr.split(",").map(s => s.trim().replace(/[\[\]]/g, "")).filter(Boolean)
          : [];
        currentFunc = {
          name: funcName,
          fullPath: `lurek.${currentModule.name}.${funcName}`,
          signature: `lurek.${currentModule.name}.${funcName}(${argStr ?? ""})`,
          description: "",
          parameters: paramNames.map(n => ({
            name: n,
            type: "any",
            description: "",
            optional: n.startsWith("[") || argStr?.includes(`[${n}]`) || false,
          })),
          isMethod: false,
        };
        continue;
      }

      // ── Method header: #### `Image:getWidth()` ──
      const methMatch = line.match(/^#{3,4}\s+`?(\w+):(\w+)(?:\(([^)]*)\))?`?\s*$/);
      if (methMatch && currentModule) {
        flushFunc();
        const [, objType, methName, argStr] = methMatch;
        const paramNames = argStr
          ? argStr.split(",").map(s => s.trim().replace(/[\[\]]/g, "")).filter(Boolean)
          : [];
        currentObjectType = objType;
        currentFunc = {
          name: methName,
          fullPath: `lurek.${currentModule.name}.${objType}:${methName}`,
          signature: `${objType}:${methName}(${argStr ?? ""})`,
          description: "",
          parameters: paramNames.map(n => ({
            name: n,
            type: "any",
            description: "",
            optional: false,
          })),
          isMethod: true,
          objectType: objType,
        };
        continue;
      }

      if (!currentFunc) continue;

      // ── Parameter block header ──
      if (/^\*\*Parameters:?\*\*/i.test(line)) {
        // Inline params: **Parameters:** `x`, `y`, `z`
        const inlineMatch = line.match(/^\*\*Parameters:?\*\*\s+`([^`]+)`(?:,\s*`([^`]+)`)*$/);
        if (inlineMatch) {
          const inlineParams = line.match(/`(\w+)`/g);
          if (inlineParams) {
            const existing = new Set((currentFunc.parameters ?? []).map(p => p.name));
            for (const raw of inlineParams) {
              const pName = raw.replace(/`/g, "");
              if (!existing.has(pName)) {
                currentFunc.parameters = currentFunc.parameters ?? [];
                currentFunc.parameters.push({
                  name: pName,
                  type: "any",
                  description: "",
                  optional: false,
                });
              }
            }
          }
        } else {
          inParams = true;
        }
        continue;
      }

      // ── Parameter line: - `name` — type — description ──
      if (inParams && line.match(/^- `[^`]+`/)) {
        // Two-dash format: - `name` — type — description
        const twoDash = line.match(/^- `([^`]+)`(?:,\s*`([^`]+)`)?\s*—\s*([^—]+?)\s*—\s*(.+)/);
        if (twoDash) {
          const [, pName, pName2, pType, pDesc] = twoDash;
          this.upsertParam(currentFunc, pName, pType.trim(), pDesc.trim());
          if (pName2) {
            this.upsertParam(currentFunc, pName2, pType.trim(), pDesc.trim());
          }
          continue;
        }

        // One-dash format: - `name` — description (or `name`: `type`)
        const oneDash = line.match(/^- `([^`]+)`(?:,\s*`([^`]+)`)?\s*—\s*(.*)/);
        if (oneDash) {
          const [, pName, pName2, rest] = oneDash;
          // Check if rest starts with a backticked type: `string`: description
          const typeMatch = rest.match(/^`(\w+)`[:\s]\s*(.*)/);
          if (typeMatch) {
            this.upsertParam(currentFunc, pName, typeMatch[1], typeMatch[2].trim());
          } else {
            // Infer type from description keywords
            const inferredType = inferTypeFromDesc(rest);
            this.upsertParam(currentFunc, pName, inferredType, rest.trim());
          }
          if (pName2) {
            this.upsertParam(currentFunc, pName2, "any", "");
          }
          continue;
        }

        // Bare param: - `name`
        const bareParam = line.match(/^- `(\w+)`\s*$/);
        if (bareParam) {
          this.upsertParam(currentFunc, bareParam[1], "any", "");
          continue;
        }
        continue;
      }

      if (inParams && !line.startsWith("-") && line.trim() !== "") {
        inParams = false;
      }

      // ── Returns line ──
      const retMatch = line.match(/^\*\*Returns:?\*\*\s*(.*)/i);
      if (retMatch) {
        const retText = retMatch[1].trim();
        currentFunc.returns = retText;
        currentFunc.returnType = inferReturnType(retText);
        continue;
      }

      // ── Source line ──
      const srcMatch = line.match(/^\*Source:\s*\[([^\]]+)\]/);
      if (srcMatch) {
        currentFunc.sourceFile = srcMatch[1];
        continue;
      }

      // ── Description accumulation ──
      if (
        !inParams &&
        line.trim().length > 0 &&
        !line.startsWith("#") &&
        !line.startsWith("*Source:") &&
        !line.startsWith("---") &&
        !line.startsWith("*") &&
        !line.match(/^Lua API:/)
      ) {
        const desc = currentFunc.description ?? "";
        currentFunc.description = desc ? `${desc} ${line.trim()}` : line.trim();
      }
    }

    // Flush last function and module
    flushFunc();
    if (currentModule) {
      currentModule.totalEntries = currentModule.functions.length + currentModule.methods.length;
      currentModule.documentedEntries = [...currentModule.functions, ...currentModule.methods]
        .filter(f => f.description.length > 0).length;
      this.modules.set(currentModule.name, currentModule);
    }
  }

  private upsertParam(func: Partial<ApiFunction>, name: string, type: string, description: string): void {
    func.parameters = func.parameters ?? [];
    const existing = func.parameters.find(p => p.name === name);
    if (existing) {
      if (type !== "any") existing.type = type;
      if (description) existing.description = description;
    } else {
      const isOptional =
        description.toLowerCase().startsWith("optional") ||
        description.includes("(default") ||
        name.startsWith("[");
      const cleanName = name.replace(/[\[\]]/g, "");
      let defaultVal: string | undefined;
      const defMatch = description.match(/\(default[:\s]+([^)]+)\)/i);
      if (defMatch) defaultVal = defMatch[1].trim();

      func.parameters.push({
        name: cleanName,
        type,
        description,
        optional: isOptional,
        default: defaultVal,
      });
    }
  }

  private indexMethod(fn: ApiFunction): void {
    const objType = fn.objectType;
    if (!objType) return;
    let list = this.methodsByObjectType.get(objType);
    if (!list) {
      list = [];
      this.methodsByObjectType.set(objType, list);
    }
    list.push(fn);
  }

  // ── Enum initialization ────────────────────────────────────

  private initEnums(): void {
    for (const [name, data] of Object.entries(BUILTIN_ENUMS)) {
      this.enums.set(name, { name, values: data.values, descriptions: data.descriptions });
    }
  }

  // ── Callback initialization ────────────────────────────────

  private initCallbacks(): void {
    this.callbackList = CALLBACK_DEFS.map(cb => ({
      module: "",
      name: cb.name,
      fullPath: `lurek.${cb.name}`,
      signature: cb.signature,
      description: cb.description,
      parameters: cb.params,
      isMethod: false,
    }));
  }

  // ── Stdlib helper ──────────────────────────────────────────

  private stdlibToApiFunction(tableName: string, entry: StdlibEntry): ApiFunction {
    return {
      module: tableName,
      name: entry.name,
      fullPath: `${tableName}.${entry.name}`,
      signature: entry.signature,
      description: entry.description,
      parameters: entry.params,
      returns: entry.returns,
      returnType: entry.returns,
      isMethod: false,
    };
  }

  // ── docs/API/lurek.lua loader ─────────────────────────────────────────────
  // Parses the LuaCATS-style full API reference used as the workspace source of
  // truth. This format includes richer @param and @return annotations than the
  // compact lua-api.md reference.
  private loadFromLurekLua(luaSource: string): void {
    const lines = luaSource.split("\n");
    let currentModule: ApiModule | null = null;
    let pendingDescription: string[] = [];
    let pendingParams: ApiParam[] = [];
    let pendingReturns: string[] = [];

    const finishModule = (): void => {
      if (!currentModule) {
        return;
      }
      currentModule.totalEntries = currentModule.functions.length + currentModule.methods.length;
      currentModule.documentedEntries = [
        ...currentModule.functions,
        ...currentModule.methods,
      ].filter((fn) => fn.description.length > 0).length;
      this.modules.set(currentModule.name, currentModule);
    };

    const clearPending = (): void => {
      pendingDescription = [];
      pendingParams = [];
      pendingReturns = [];
    };

    const ensureModule = (moduleName: string): ApiModule => {
      if (currentModule && currentModule.name === moduleName) {
        return currentModule;
      }

      finishModule();
      currentModule = {
        name: moduleName,
        fullPath: `lurek.${moduleName}`,
        description: pendingDescription.join(" ").trim(),
        functions: [],
        methods: [],
        totalEntries: 0,
        documentedEntries: 0,
      };
      clearPending();
      return currentModule;
    };

    for (const rawLine of lines) {
      const line = rawLine.trim();
      if (line.length === 0) {
        continue;
      }

      const descMatch = line.match(/^---(?!@)(.*)$/);
      if (descMatch) {
        const desc = descMatch[1].trim();
        if (desc) {
          pendingDescription.push(desc);
        }
        continue;
      }

      const paramMatch = line.match(/^---@param\s+(\w+)\s+(\S+)(?:\s+(.*))?$/);
      if (paramMatch) {
        const [, name, rawType, rawDesc] = paramMatch;
        pendingParams.push({
          name,
          type: rawType.replace(/\?$/, ""),
          description: rawDesc?.trim() ?? "",
          optional: rawType.includes("?") || /optional/i.test(rawDesc ?? ""),
        });
        continue;
      }

      const returnMatch = line.match(/^---@return\s+(.+)$/);
      if (returnMatch) {
        pendingReturns.push(returnMatch[1].trim());
        continue;
      }

      const moduleMatch = line.match(/^---@class\s+lurek\.([A-Za-z0-9_]+)\s*$/);
      if (moduleMatch) {
        finishModule();
        currentModule = {
          name: moduleMatch[1],
          fullPath: `lurek.${moduleMatch[1]}`,
          description: pendingDescription.join(" ").trim(),
          functions: [],
          methods: [],
          totalEntries: 0,
          documentedEntries: 0,
        };
        clearPending();
        continue;
      }

      if (/^---@class\s+[A-Za-z_][A-Za-z0-9_]*(?:\s*:\s*[A-Za-z_][A-Za-z0-9_]*)?\s*$/.test(line)) {
        clearPending();
        continue;
      }

      const functionMatch = line.match(/^function\s+lurek\.([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)\(([^)]*)\)\s*end$/);
      if (functionMatch) {
        const [, moduleName, functionName, argStr] = functionMatch;
        const module = ensureModule(moduleName);
        const returns = pendingReturns.length > 0 ? pendingReturns.join(", ") : undefined;
        const parameters = this.mergeSignatureParams(argStr, pendingParams);
        const fn: ApiFunction = {
          module: module.name,
          name: functionName,
          fullPath: `lurek.${module.name}.${functionName}`,
          signature: `lurek.${module.name}.${functionName}(${argStr.trim()})`,
          description: pendingDescription.join(" ").trim(),
          parameters,
          returns,
          returnType: inferReturnType(returns),
          isMethod: false,
        };
        module.functions.push(fn);
        this.allFunctions.set(fn.fullPath, fn);
        clearPending();
        continue;
      }

      const methodMatch = line.match(/^function\s+([A-Za-z_][A-Za-z0-9_]*)[:.]([A-Za-z0-9_]+)\(([^)]*)\)\s*end$/);
      if (methodMatch && currentModule) {
        const [, objectType, methodName, argStr] = methodMatch;
        const returns = pendingReturns.length > 0 ? pendingReturns.join(", ") : undefined;
        const parameters = this.mergeSignatureParams(argStr, pendingParams);
        const fn: ApiFunction = {
          module: currentModule.name,
          name: methodName,
          fullPath: `lurek.${currentModule.name}.${objectType}:${methodName}`,
          signature: `${objectType}:${methodName}(${argStr.trim()})`,
          description: pendingDescription.join(" ").trim(),
          parameters,
          returns,
          returnType: inferReturnType(returns),
          isMethod: true,
          objectType,
        };
        currentModule.methods.push(fn);
        this.indexMethod(fn);
        this.allFunctions.set(fn.fullPath, fn);
        clearPending();
        continue;
      }

      clearPending();
    }

    finishModule();
  }


  // ── lua-api.md loader ─────────────────────────────────────────────────────
  // Parses the compact one-liner format used in docs/API/lua-api.md:
  //   lurek.MODULE.FUNCNAME( params )[ -> returnType]  -- description
  //   ObjType:methodName( params )[ -> returnType]  -- description
  private loadFromLuaApiMd(md: string): void {
    const lines = md.split("\n");
    let currentModule: ApiModule | null = null;
    let inCodeBlock = false;

    const finishModule = (): void => {
      if (!currentModule) return;
      currentModule.totalEntries = currentModule.functions.length + currentModule.methods.length;
      currentModule.documentedEntries = [
        ...currentModule.functions,
        ...currentModule.methods,
      ].filter((f) => f.description.length > 0).length;
      this.modules.set(currentModule.name, currentModule);
    };

    for (const line of lines) {
      // Module header: ## `lurek.graphics` {#graphics}
      const modMatch = line.match(/^## [`']?lurek\.([\w]+)[`']?/);
      if (modMatch) {
        finishModule();
        const modName = modMatch[1];
        currentModule = {
          name: modName,
          fullPath: `lurek.${modName}`,
          description: "",
          functions: [],
          methods: [],
          totalEntries: 0,
          documentedEntries: 0,
        };
        inCodeBlock = false;

        // Grab description from blockquote on next lines
        continue;
      }

      // Module description from blockquote: > `lurek.render` — 2D drawing...
      if (currentModule && line.startsWith(">") && !currentModule.description) {
        const desc = line.replace(/^>\s*`[^`]*`\s*—\s*/, "").trim();
        if (desc) currentModule.description = desc;
        continue;
      }

      // Code block toggle
      if (line.startsWith("```")) {
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (!inCodeBlock || !currentModule) continue;

      // Callback line: function lurek.load() -- desc
      {
        const m = line.match(/^function lurek\.(\w+)\(\s*(.*?)\s*\)\s*--\s*(.*)/);
        if (m) {
          // Callbacks are handled by initCallbacks() — skip
          continue;
        }
      }

      // Module function: lurek.MODULE.FUNCNAME( params ) -> ret  -- desc
      {
        const m = line.match(/^lurek\.(\w+)\.(\w+)\(\s*(.*?)\s*\)(?:\s*->\s*([^-]+?))?\s*--\s*(.*)/);
        if (m) {
          const [, , funcName, paramStr, retRaw, description] = m;
          const returnType = retRaw?.trim() || undefined;
          const parameters = this.parseParamStr(paramStr);
          const fn: ApiFunction = {
            module: currentModule.name,
            name: funcName,
            fullPath: `lurek.${currentModule.name}.${funcName}`,
            signature: `lurek.${currentModule.name}.${funcName}(${paramStr})`,
            description: description.trim(),
            parameters,
            returns: returnType,
            returnType,
            isMethod: false,
          };
          currentModule.functions.push(fn);
          this.allFunctions.set(fn.fullPath, fn);
          continue;
        }
      }

      // Method: ObjType:methodName( params ) -> ret  -- desc
      {
        const m = line.match(/^([A-Z]\w*):([\w]+)\(\s*(.*?)\s*\)(?:\s*->\s*([^-]+?))?\s*--\s*(.*)/);
        if (m) {
          const [, objType, methName, paramStr, retRaw, description] = m;
          const returnType = retRaw?.trim() || undefined;
          const parameters = this.parseParamStr(paramStr);
          const fn: ApiFunction = {
            module: currentModule.name,
            name: methName,
            fullPath: `lurek.${currentModule.name}.${objType}:${methName}`,
            signature: `${objType}:${methName}(${paramStr})`,
            description: description.trim(),
            parameters,
            returns: returnType,
            returnType,
            isMethod: true,
            objectType: objType,
          };
          currentModule.methods.push(fn);
          this.indexMethod(fn);
          this.allFunctions.set(fn.fullPath, fn);
          continue;
        }
      }
    }

    finishModule();
  }

  // ── Param string parser ────────────────────────────────────────────────────
  // Parses "name : type, name2 : type2?" style param strings from lua-api.md
  private parseParamStr(paramStr: string): ApiParam[] {
    if (!paramStr.trim()) return [];
    return paramStr.split(",").map((p) => {
      p = p.trim();
      const optional = p.endsWith("?") || p.includes("?");
      const colonIdx = p.indexOf(":");
      if (colonIdx >= 0) {
        const name = p.slice(0, colonIdx).trim().replace(/[?\[\]]/g, "");
        const type = p.slice(colonIdx + 1).trim().replace(/\?$/, "").trim();
        return { name: name || "_", type: type || "any", description: "", optional };
      }
      const name = p.replace(/[?\[\]]/g, "").trim();
      return { name: name || "_", type: "any", description: "", optional };
    });
  }

  private mergeSignatureParams(argStr: string, annotatedParams: ApiParam[]): ApiParam[] {
    const params = annotatedParams.map((param) => ({ ...param }));
    const existingNames = new Set(params.map((param) => param.name));
    const signatureNames = argStr
      .split(",")
      .map((part) => part.trim())
      .filter(Boolean);

    for (const name of signatureNames) {
      if (!existingNames.has(name)) {
        params.push({
          name,
          type: "any",
          description: "",
          optional: false,
        });
      }
    }

    return params;
  }

  // ── Fallback data ──────────────────────────────────────────

  private loadFallback(): void {
    const mods: [string, string, [string, string, string[]][]][] = [
      [
        "graphics",
        "Drawing and rendering functions",
        [
          ["draw", "Draws a drawable object at the specified position", ["drawable", "x", "y", "r", "sx", "sy", "ox", "oy"]],
          ["rectangle", "Draws a rectangle", ["mode", "x", "y", "width", "height"]],
          ["circle", "Draws a circle", ["mode", "x", "y", "radius"]],
          ["line", "Draws a line between points", ["x1", "y1", "x2", "y2"]],
          ["setColor", "Sets the active drawing color (0-1 range)", ["r", "g", "b", "a"]],
          ["setBackgroundColor", "Sets the background color", ["r", "g", "b"]],
          ["newImage", "Loads an image from file", ["path"]],
          ["newCanvas", "Creates an off-screen canvas", ["width", "height"]],
          ["newFont", "Loads a font from file", ["path", "size"]],
          ["newShader", "Creates a shader from source", ["code"]],
          ["print", "Draws text at position", ["text", "x", "y"]],
          ["push", "Pushes the current transform onto the stack", []],
          ["pop", "Pops the current transform from the stack", []],
          ["translate", "Translates the coordinate system", ["dx", "dy"]],
          ["rotate", "Rotates the coordinate system", ["angle"]],
          ["scale", "Scales the coordinate system", ["sx", "sy"]],
          ["clear", "Clears the screen with current background color", ["r", "g", "b"]],
          ["getWidth", "Returns the window width in pixels", []],
          ["getHeight", "Returns the window height in pixels", []],
          ["arc", "Draws an arc", ["mode", "x", "y", "radius", "angle1", "angle2"]],
          ["polygon", "Draws a polygon", ["mode", "...vertices"]],
          ["ellipse", "Draws an ellipse", ["mode", "x", "y", "rx", "ry"]],
          ["points", "Draws points at positions", ["...coords"]],
          ["setLineWidth", "Sets the line width", ["width"]],
          ["getLineWidth", "Returns the current line width", []],
          ["setFont", "Sets the active font", ["font"]],
          ["origin", "Resets the transform to identity", []],
        ],
      ],
      [
        "audio",
        "Audio playback and management",
        [
          ["newSource", "Creates a new audio source from file", ["path", "type"]],
          ["play", "Plays an audio source", ["source"]],
          ["stop", "Stops an audio source", ["source"]],
          ["pause", "Pauses an audio source", ["source"]],
          ["setVolume", "Sets the master volume (0-1)", ["volume"]],
          ["getVolume", "Returns the master volume", []],
        ],
      ],
      [
        "physics",
        "2D physics simulation with rapier2d",
        [
          ["newWorld", "Creates a new physics world", ["gx", "gy"]],
          ["newBody", "Creates a new rigid body", ["world", "x", "y", "type"]],
          ["newRectangleShape", "Attaches a rectangle collider", ["body", "w", "h"]],
          ["newCircleShape", "Attaches a circle collider", ["body", "radius"]],
          ["newEdgeShape", "Attaches an edge collider", ["body", "x1", "y1", "x2", "y2"]],
          ["newPolygonShape", "Attaches a polygon collider", ["body", "...vertices"]],
        ],
      ],
      [
        "input",
        "Keyboard, mouse, and gamepad input",
        [
          ["isDown", "Checks if a keyboard key is currently pressed", ["key"]],
          ["isUp", "Checks if a keyboard key is not pressed", ["key"]],
          ["getMousePosition", "Returns mouse x, y coordinates", []],
          ["getMouseX", "Returns the mouse X position", []],
          ["getMouseY", "Returns the mouse Y position", []],
          ["isMouseDown", "Checks if a mouse button is pressed", ["button"]],
          ["getGamepadAxis", "Returns gamepad axis value", ["id", "axis"]],
          ["isGamepadDown", "Checks if gamepad button is pressed", ["id", "button"]],
        ],
      ],
      [
        "timer",
        "Timing and frame management",
        [
          ["getTime", "Returns total elapsed time in seconds", []],
          ["getDelta", "Returns delta time for current frame", []],
          ["getFPS", "Returns current frames per second", []],
          ["sleep", "Pauses execution for duration", ["seconds"]],
          ["average", "Returns average frame time", []],
        ],
      ],
      [
        "window",
        "Window management and display",
        [
          ["setTitle", "Sets the window title", ["title"]],
          ["getTitle", "Returns the window title", []],
          ["setMode", "Sets the window dimensions", ["width", "height", "flags"]],
          ["getWidth", "Returns the window width", []],
          ["getHeight", "Returns the window height", []],
          ["setFullscreen", "Toggles fullscreen mode", ["fullscreen"]],
          ["isFullscreen", "Returns whether window is fullscreen", []],
          ["setIcon", "Sets the window icon", ["imagedata"]],
          ["close", "Closes the window", []],
          ["minimize", "Minimizes the window", []],
          ["maximize", "Maximizes the window", []],
          ["restore", "Restores the window from minimize/maximize", []],
        ],
      ],
      [
        "math",
        "Mathematical utility functions",
        [
          ["random", "Returns a random number", ["min", "max"]],
          ["noise", "Generates Perlin noise value", ["x", "y", "z"]],
          ["lerp", "Linearly interpolates between two values", ["a", "b", "t"]],
          ["clamp", "Clamps a value between min and max", ["x", "min", "max"]],
          ["distance", "Returns distance between two points", ["x1", "y1", "x2", "y2"]],
          ["angle", "Returns angle between two points", ["x1", "y1", "x2", "y2"]],
          ["normalize", "Normalizes a vector", ["x", "y"]],
        ],
      ],
      [
        "filesystem",
        "Sandboxed file I/O",
        [
          ["read", "Reads a file as a string", ["path"]],
          ["write", "Writes a string to a file", ["path", "data"]],
          ["exists", "Checks if a file exists", ["path"]],
          ["getDirectoryItems", "Lists items in a directory", ["path"]],
          ["createDirectory", "Creates a directory", ["path"]],
          ["remove", "Removes a file", ["path"]],
          ["isFile", "Checks if path is a file", ["path"]],
          ["isDirectory", "Checks if path is a directory", ["path"]],
        ],
      ],
      [
        "system",
        "System information and utilities",
        [
          ["getOS", "Returns the operating system name", []],
          ["getClipboardText", "Returns clipboard text content", []],
          ["setClipboardText", "Sets clipboard text content", ["text"]],
          ["quit", "Quits the application", []],
          ["openURL", "Opens a URL in the default browser", ["url"]],
        ],
      ],
    ];

    for (const [modName, modDesc, funcs] of mods) {
      const mod: ApiModule = {
        name: modName,
        fullPath: `lurek.${modName}`,
        description: modDesc,
        functions: [],
        methods: [],
        totalEntries: 0,
        documentedEntries: 0,
      };
      for (const [name, desc, params] of funcs) {
        const fn: ApiFunction = {
          module: modName,
          name,
          fullPath: `lurek.${modName}.${name}`,
          signature: `lurek.${modName}.${name}(${params.join(", ")})`,
          description: desc,
          parameters: params.map(p => ({
            name: p,
            type: "any",
            description: "",
            optional: false,
          })),
          isMethod: false,
        };
        mod.functions.push(fn);
        this.allFunctions.set(fn.fullPath, fn);
      }
      mod.totalEntries = mod.functions.length;
      mod.documentedEntries = mod.functions.filter(f => f.description.length > 0).length;
      this.modules.set(modName, mod);
    }
  }
}

// ── Helpers ──────────────────────────────────────────────────

function inferReturnType(returns: string | undefined): string | undefined {
  if (!returns) return undefined;
  const lower = returns.toLowerCase();
  if (lower === "nil" || lower === "none") return "nil";
  if (lower.startsWith("number") || lower.startsWith("`number`")) return "number";
  if (lower.startsWith("string") || lower.startsWith("`string`")) return "string";
  if (lower.startsWith("boolean") || lower.startsWith("`boolean`")) return "boolean";
  if (lower.startsWith("table") || lower.startsWith("`table`")) return "table";
  if (lower.startsWith("integer") || lower.startsWith("`integer`")) return "number";
  if (lower.startsWith("function") || lower.startsWith("`function`")) return "function";
  if (lower.includes(",")) return "multiple";
  return returns;
}

function inferTypeFromDesc(desc: string): string {
  const lower = desc.toLowerCase();
  if (lower.includes("boolean")) return "boolean";
  if (lower.includes("string") || lower.includes("name")) return "string";
  if (lower.includes("pixel") || lower.includes("coordinate") || lower.includes("number") ||
      lower.includes("angle") || lower.includes("radius") || lower.includes("width") ||
      lower.includes("height") || lower.includes("scale") || lower.includes("factor") ||
      lower.includes("offset") || lower.includes("index") || lower.includes("integer")) {
    return "number";
  }
  if (lower.includes("table")) return "table";
  if (lower.includes("function") || lower.includes("callback")) return "function";
  if (lower.includes("draw mode") || lower.includes("'fill'") || lower.includes("'line'")) return "DrawMode";
  if (lower.includes("blend mode")) return "BlendMode";
  return "any";
}
