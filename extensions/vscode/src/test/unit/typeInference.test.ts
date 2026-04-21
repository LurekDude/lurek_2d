/**
 * Unit tests for the type inference provider.
 *
 * Tests scanDocument, getTypeInfoForVar, getMethodsForVar, and FACTORY_TYPES
 * against mock Lua documents.
 */
import * as assert from "assert";
import {
  scanDocument,
  getTypeInfoForVar,
  getMethodsForVar,
  FACTORY_TYPES,
} from "../../providers/typeInference";
import { MockTextDocument, MockPosition } from "../mocks/vscode";

// scanDocument accepts vscode.TextDocument which we mock — cast as any
/* eslint-disable @typescript-eslint/no-explicit-any */

suite("TypeInference — FACTORY_TYPES registry", () => {
  test("contains Image type from lurek.graphics.newImage", () => {
    assert.ok(FACTORY_TYPES["lurek.graphics.newImage"]);
    assert.strictEqual(FACTORY_TYPES["lurek.graphics.newImage"].typeName, "Image");
  });

  test("contains Canvas type from lurek.graphics.newCanvas", () => {
    assert.ok(FACTORY_TYPES["lurek.graphics.newCanvas"]);
    assert.strictEqual(FACTORY_TYPES["lurek.graphics.newCanvas"].typeName, "Canvas");
  });

  test("contains Font type from lurek.graphics.newFont", () => {
    assert.ok(FACTORY_TYPES["lurek.graphics.newFont"]);
    assert.strictEqual(FACTORY_TYPES["lurek.graphics.newFont"].typeName, "Font");
  });

  test("contains Entity type from lurek.ecs.new", () => {
    assert.ok(FACTORY_TYPES["lurek.ecs.new"]);
    assert.strictEqual(FACTORY_TYPES["lurek.ecs.new"].typeName, "Entity");
  });

  test("contains World type from lurek.physics.newWorld", () => {
    assert.ok(FACTORY_TYPES["lurek.physics.newWorld"]);
    assert.strictEqual(FACTORY_TYPES["lurek.physics.newWorld"].typeName, "World");
  });

  test("Canvas has setFilter and getFilter methods", () => {
    const canvas = FACTORY_TYPES["lurek.graphics.newCanvas"];
    const methodNames = canvas.methods.map((m) => m.name);
    assert.ok(methodNames.includes("setFilter"), "Canvas should have setFilter");
    assert.ok(methodNames.includes("getFilter"), "Canvas should have getFilter");
  });

  test("Canvas has width and height fields", () => {
    const canvas = FACTORY_TYPES["lurek.graphics.newCanvas"];
    const fieldNames = canvas.fields.map((f) => f.name);
    assert.ok(fieldNames.includes("width"), "Canvas should have width field");
    assert.ok(fieldNames.includes("height"), "Canvas should have height field");
  });

  test("Image has methods and fields", () => {
    const image = FACTORY_TYPES["lurek.graphics.newImage"];
    assert.ok(image.methods.length > 0, "Image should have methods");
    assert.ok(image.fields.length > 0, "Image should have fields");
  });
});

suite("TypeInference — scanDocument", () => {
  test("detects local var from lurek.graphics.newCanvas", () => {
    const doc = new MockTextDocument(
      'local canvas = lurek.graphics.newCanvas(100, 100)\ncanvas:setFilter("nearest")',
    );
    const result = scanDocument(doc as any);
    assert.strictEqual(result.varTypes.length, 1);
    assert.strictEqual(result.varTypes[0].varName, "canvas");
    assert.strictEqual(result.varTypes[0].typeName, "Canvas");
    assert.strictEqual(result.varTypes[0].factoryCall, "lurek.graphics.newCanvas");
  });

  test("detects local var from lurek.graphics.newImage", () => {
    const doc = new MockTextDocument(
      'local img = lurek.graphics.newImage("player.png")',
    );
    const result = scanDocument(doc as any);
    assert.strictEqual(result.varTypes.length, 1);
    assert.strictEqual(result.varTypes[0].varName, "img");
    assert.strictEqual(result.varTypes[0].typeName, "Image");
  });

  test("detects multiple variables in one document", () => {
    const doc = new MockTextDocument(
      [
        'local img = lurek.graphics.newImage("player.png")',
        'local canvas = lurek.graphics.newCanvas(800, 600)',
        'local font = lurek.graphics.newFont("font.ttf", 16)',
      ].join("\n"),
    );
    const result = scanDocument(doc as any);
    assert.strictEqual(result.varTypes.length, 3);
    const names = result.varTypes.map((v) => v.varName);
    assert.ok(names.includes("img"));
    assert.ok(names.includes("canvas"));
    assert.ok(names.includes("font"));
  });

  test("detects module alias like local gfx = lurek.graphics", () => {
    const doc = new MockTextDocument("local gfx = lurek.graphics\n");
    const result = scanDocument(doc as any);
    assert.strictEqual(result.moduleAliases.length, 1);
    assert.strictEqual(result.moduleAliases[0].alias, "gfx");
    assert.strictEqual(result.moduleAliases[0].module, "lurek.graphics");
  });

  test("detects factory call via module alias", () => {
    const doc = new MockTextDocument(
      [
        "local gfx = lurek.graphics",
        'local img = gfx.newImage("sprite.png")',
      ].join("\n"),
    );
    const result = scanDocument(doc as any);
    // Should have at least the aliased factory variable
    const imgVar = result.varTypes.find((v) => v.varName === "img");
    assert.ok(imgVar, "Should find img variable from aliased factory call");
  });

  test("detects OOP class pattern", () => {
    const doc = new MockTextDocument(
      [
        "local Player = {}",
        "Player.__index = Player",
        "function Player:new(name)",
        "  return setmetatable({name = name}, Player)",
        "end",
        "function Player:update(dt)",
        "  -- move",
        "end",
      ].join("\n"),
    );
    const result = scanDocument(doc as any);
    assert.strictEqual(result.classes.length, 1);
    assert.strictEqual(result.classes[0].name, "Player");
    const methodNames = result.classes[0].methods.map((m) => m.name);
    assert.ok(methodNames.includes("update"));
  });

  test("detects class instances", () => {
    const doc = new MockTextDocument(
      [
        "local Player = {}",
        "Player.__index = Player",
        "function Player:new(name)",
        "  return setmetatable({name = name}, Player)",
        "end",
        "function Player:jump()",
        "end",
        'local p = Player:new("hero")',
      ].join("\n"),
    );
    const result = scanDocument(doc as any);
    assert.strictEqual(result.classes.length, 1);
    assert.ok(result.classes[0].instances.length >= 1);
    assert.strictEqual(result.classes[0].instances[0].varName, "p");
  });

  test("detects re-assignment from another variable", () => {
    const doc = new MockTextDocument(
      [
        'local img = lurek.graphics.newImage("sprite.png")',
        "local copy = img",
      ].join("\n"),
    );
    const result = scanDocument(doc as any);
    const copyVar = result.varTypes.find((v) => v.varName === "copy");
    assert.ok(copyVar, "copy should have been detected via re-assignment");
    assert.strictEqual(copyVar!.typeName, "Image");
  });

  test("ignores lines without factory patterns", () => {
    const doc = new MockTextDocument(
      [
        "local x = 42",
        'local name = "hello"',
        "local tbl = {}",
      ].join("\n"),
    );
    const result = scanDocument(doc as any);
    assert.strictEqual(result.varTypes.length, 0);
    assert.strictEqual(result.classes.length, 0);
    assert.strictEqual(result.moduleAliases.length, 0);
  });
});

suite("TypeInference — getTypeInfoForVar", () => {
  test("returns TypeInfo for a factory-typed variable", () => {
    const varTypes = [
      { varName: "canvas", typeName: "Canvas", line: 0, factoryCall: "lurek.graphics.newCanvas" },
    ];
    const pos = new MockPosition(5, 0);
    const result = getTypeInfoForVar("canvas", pos as any, varTypes, []);
    assert.ok(result);
    assert.strictEqual(result!.typeInfo.typeName, "Canvas");
    assert.strictEqual(result!.factoryCall, "lurek.graphics.newCanvas");
  });

  test("returns undefined for unknown variable", () => {
    const result = getTypeInfoForVar("unknown", new MockPosition(5, 0) as any, [], []);
    assert.strictEqual(result, undefined);
  });

  test("only considers variables declared before the cursor", () => {
    const varTypes = [
      { varName: "canvas", typeName: "Canvas", line: 10, factoryCall: "lurek.graphics.newCanvas" },
    ];
    // Cursor at line 5, variable declared at line 10 — should not match
    const result = getTypeInfoForVar("canvas", new MockPosition(5, 0) as any, varTypes, []);
    assert.strictEqual(result, undefined);
  });
});

suite("TypeInference — getMethodsForVar", () => {
  test("returns methods for factory-typed variable", () => {
    const varTypes = [
      { varName: "img", typeName: "Image", line: 0, factoryCall: "lurek.graphics.newImage" },
    ];
    const methods = getMethodsForVar("img", new MockPosition(5, 0) as any, varTypes, []);
    assert.ok(methods);
    assert.ok(methods!.length > 0);
    const names = methods!.map((m) => m.name);
    assert.ok(names.includes("getWidth"));
  });

  test("returns methods for OOP class instance", () => {
    const classes = [
      {
        name: "Enemy",
        methods: [
          { name: "attack", snippet: "attack()", documentation: "Attack!" },
          { name: "flee", snippet: "flee()", documentation: "Run away!" },
        ],
        instances: [{ varName: "boss", line: 10 }],
      },
    ];
    const methods = getMethodsForVar("boss", new MockPosition(15, 0) as any, [], classes);
    assert.ok(methods);
    assert.strictEqual(methods!.length, 2);
    const names = methods!.map((m) => m.name);
    assert.ok(names.includes("attack"));
    assert.ok(names.includes("flee"));
  });

  test("returns undefined for unrecognised variable", () => {
    const methods = getMethodsForVar("foo", new MockPosition(5, 0) as any, [], []);
    assert.strictEqual(methods, undefined);
  });
});
