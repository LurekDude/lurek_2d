import * as assert from "assert";
import * as vscode from "vscode";

const EXTENSION_ID = "lurek2d.lurek2d-toolkit";
const CRITICAL_SIDEBAR_COMMANDS = [
  "lurek.browseApi",
  "lurek.openApiDocs",
  "lurek.cag.selectAgent",
  "lurek.cag.selectSkill",
  "lurek.editor.worldMap",
  "lurek.editor.testRunner",
];

type ExtensionManifest = {
  contributes?: {
    commands?: Array<{ command: string }>;
  };
};

async function activateExtension(): Promise<vscode.Extension<unknown>> {
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
    const manifest = extension.packageJSON as ExtensionManifest;
    const contributedCommands = new Set(
      (manifest.contributes?.commands ?? []).map((entry) => entry.command),
    );

    for (const commandId of CRITICAL_SIDEBAR_COMMANDS) {
      assert.ok(
        contributedCommands.has(commandId),
        `Expected ${commandId} to be declared in package.json contributes.commands.`,
      );
    }
  });

  test("activation registers critical sidebar commands", async () => {
    await activateExtension();
    const registeredCommands = new Set(await vscode.commands.getCommands(true));

    for (const commandId of CRITICAL_SIDEBAR_COMMANDS) {
      assert.ok(
        registeredCommands.has(commandId),
        `Expected ${commandId} to be registered after extension activation.`,
      );
    }
  });
});