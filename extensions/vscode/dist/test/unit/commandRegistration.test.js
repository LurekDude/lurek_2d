"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// src/test/unit/commandRegistration.test.ts
var assert = __toESM(require("assert"));
var vscode = __toESM(require("vscode"));
var EXTENSION_ID = "lurek2d.lurek2d-toolkit";
var CRITICAL_SIDEBAR_COMMANDS = [
  "lurek.browseApi",
  "lurek.openApiDocs",
  "lurek.cag.selectAgent",
  "lurek.cag.selectSkill",
  "lurek.editor.worldMap",
  "lurek.editor.testRunner"
];
async function activateExtension() {
  const extension = vscode.extensions.getExtension(EXTENSION_ID);
  assert.ok(extension, `Expected extension ${EXTENSION_ID} to be available in the test host.`);
  if (!extension.isActive) {
    await extension.activate();
  }
  return extension;
}
suite("Extension command wiring", () => {
  test("manifest contributes critical sidebar commands", async () => {
    const extension = await activateExtension();
    const manifest = extension.packageJSON;
    const contributedCommands = new Set(
      (manifest.contributes?.commands ?? []).map((entry) => entry.command)
    );
    for (const commandId of CRITICAL_SIDEBAR_COMMANDS) {
      assert.ok(
        contributedCommands.has(commandId),
        `Expected ${commandId} to be declared in package.json contributes.commands.`
      );
    }
  });
  test("activation registers critical sidebar commands", async () => {
    await activateExtension();
    const registeredCommands = new Set(await vscode.commands.getCommands(true));
    for (const commandId of CRITICAL_SIDEBAR_COMMANDS) {
      assert.ok(
        registeredCommands.has(commandId),
        `Expected ${commandId} to be registered after extension activation.`
      );
    }
  });
});
//# sourceMappingURL=commandRegistration.test.js.map
