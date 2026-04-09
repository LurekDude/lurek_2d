import * as vscode from "vscode";
import { TileMapEditor } from "../editors/tileMapEditor.js";
import { SceneFlowEditor } from "../editors/sceneFlowEditor.js";
import { EntityEditor } from "../editors/entityEditor.js";
import { PixelArtEditor } from "../editors/pixelArtEditor.js";
import { ParticleEditor } from "../editors/particleEditor.js";
import { DialogEditor } from "../editors/dialogEditor.js";
import { DatabaseEditor } from "../editors/databaseEditor.js";
import { ProcMapEditor } from "../editors/procMapEditor.js";
import { QuestTreeEditor } from "../editors/questTreeEditor.js";
import { GuiWidgetEditor } from "../editors/guiWidgetEditor.js";
import { AiBehaviorEditor } from "../editors/aiBehaviorEditor.js";
import { GraphEditor } from "../editors/graphEditor.js";
import { TilemapScriptEditor } from "../editors/tilemapScriptEditor.js";
import { VoxelEditor } from "../editors/voxelEditor.js";
import { TestRunnerEditor } from "../editors/testRunnerEditor.js";
import { ApiReferenceEditor } from "../editors/apiReferenceEditor.js";
import { PostFxOverlayEditor } from "../editors/postfxOverlayEditor.js";
import { SoundDspEditor } from "../editors/soundDspEditor.js";
import { SpriteAnimEditor } from "../editors/spriteAnimEditor.js";
import { TilesetEditor } from "../editors/tilesetEditor.js";
import { AudioMixerEditor } from "../editors/audioMixerEditor.js";
import { ColorPaletteEditor } from "../editors/colorPaletteEditor.js";
import { InputMapperEditor } from "../editors/inputMapperEditor.js";
import { TimelineEditor } from "../editors/timelineEditor.js";
import { ShaderPreviewEditor } from "../editors/shaderPreviewEditor.js";
import { FontPreviewEditor } from "../editors/fontPreviewEditor.js";
import { LocalizationEditor } from "../editors/localizationEditor.js";
import { PhysicsMaterialsEditor } from "../editors/physicsMaterialsEditor.js";
import { WorldMapEditor } from "../editors/worldMapEditor.js";

interface EditorEntry {
  id: string;
  open: (ctx: vscode.ExtensionContext) => void;
}

const EDITORS: EditorEntry[] = [
  { id: "tileMap", open: (ctx) => TileMapEditor.open(ctx) },
  { id: "sceneFlow", open: (ctx) => SceneFlowEditor.open(ctx) },
  { id: "entity", open: (ctx) => EntityEditor.open(ctx) },
  { id: "pixelArt", open: (ctx) => PixelArtEditor.open(ctx) },
  { id: "particle", open: (ctx) => ParticleEditor.open(ctx) },
  { id: "dialog", open: (ctx) => DialogEditor.open(ctx) },
  { id: "database", open: (ctx) => DatabaseEditor.open(ctx) },
  { id: "procMap", open: (ctx) => ProcMapEditor.open(ctx) },
  { id: "questTree", open: (ctx) => QuestTreeEditor.open(ctx) },
  { id: "guiWidget", open: (ctx) => GuiWidgetEditor.open(ctx) },
  { id: "aiBehavior", open: (ctx) => AiBehaviorEditor.open(ctx) },
  { id: "graph", open: (ctx) => GraphEditor.open(ctx) },
  { id: "tilemapScript", open: (ctx) => TilemapScriptEditor.open(ctx) },
  { id: "voxel", open: (ctx) => VoxelEditor.open(ctx) },
  { id: "testRunner", open: (ctx) => TestRunnerEditor.open(ctx) },
  { id: "apiReference", open: (ctx) => ApiReferenceEditor.open(ctx) },
  { id: "postfxOverlay", open: (ctx) => PostFxOverlayEditor.open(ctx) },
  { id: "soundDsp", open: (ctx) => SoundDspEditor.open(ctx) },
  { id: "spriteAnim", open: (ctx) => SpriteAnimEditor.open(ctx) },
  { id: "tileset", open: (ctx) => TilesetEditor.open(ctx) },
  { id: "audioMixer", open: (ctx) => AudioMixerEditor.open(ctx) },
  { id: "colorPalette", open: (ctx) => ColorPaletteEditor.open(ctx) },
  { id: "inputMapper", open: (ctx) => InputMapperEditor.open(ctx) },
  { id: "timeline", open: (ctx) => TimelineEditor.open(ctx) },
  { id: "shaderPreview", open: (ctx) => ShaderPreviewEditor.open(ctx) },
  { id: "fontPreview", open: (ctx) => FontPreviewEditor.open(ctx) },
  { id: "localization", open: (ctx) => LocalizationEditor.open(ctx) },
  { id: "physicsMaterials", open: (ctx) => PhysicsMaterialsEditor.open(ctx) },
  { id: "worldMap", open: (ctx) => WorldMapEditor.open(ctx) },
];

/**
 * Registers all editor commands and returns the disposables.
 */
export function registerEditorCommands(
  context: vscode.ExtensionContext
): vscode.Disposable[] {
  return EDITORS.map((entry) =>
    vscode.commands.registerCommand(`luna.editor.${entry.id}`, () =>
      entry.open(context)
    )
  );
}
