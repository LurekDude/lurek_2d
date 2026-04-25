import * as vscode from "vscode";
import { ApiDataService } from "../services/apiData.js";

// Module-level ApiDataService reference — set once at extension activation.
let _apiDataSingleton: ApiDataService | null = null;

/** Called once in register() to wire up the live API data. */
export function setApiData(data: ApiDataService): void {
  _apiDataSingleton = data;
}

/** Look up the return type name for a factory function full path. */
function getReturnTypeName(fullPath: string): string | undefined {
  if (_apiDataSingleton) {
    const typeName = _apiDataSingleton.getFactoryTypes().get(fullPath);
    if (typeName) return typeName;
  }
  return FACTORY_TYPES[fullPath]?.typeName;
}

/** Build a TypeInfo for a type name using live API data, falling back to the hardcoded map.
 *  Methods always come from the JSON; `fields` are supplemented from the legacy map. */
function getTypeInfoByName(typeName: string): TypeInfo | undefined {
  if (_apiDataSingleton) {
    const methods = _apiDataSingleton.getMethods(typeName);
    if (methods.length > 0) {
      // Supplement with field definitions from legacy map (fields not yet sourced from JSON)
      const legacyEntry = Object.values(FACTORY_TYPES).find(t => t.typeName === typeName);
      return {
        typeName,
        methods: methods.map(fn => ({
          name: fn.name,
          sig: fn.signature,
          desc: fn.description,
        })),
        ...(legacyEntry?.fields ? { fields: legacyEntry.fields } : {}),
      };
    }
  }
  return Object.values(FACTORY_TYPES).find(t => t.typeName === typeName);
}

/** All factory function full paths from API data, with hardcoded keys as fallback. */
function getAllFactoryPaths(): string[] {
  const paths = new Set<string>(Object.keys(FACTORY_TYPES));
  if (_apiDataSingleton) {
    for (const key of _apiDataSingleton.getFactoryTypes().keys()) {
      paths.add(key);
    }
  }
  return Array.from(paths);
}

const LUA_SELECTOR: vscode.DocumentSelector = {
  scheme: "file",
  language: "lua",
};

// ── Type information ──────────────────────────────────────

export interface MethodInfo {
  name: string;
  sig: string;
  desc: string;
}

export interface FieldInfo {
  name: string;
  type: string;
  desc: string;
}

export interface TypeInfo {
  typeName: string;
  methods: MethodInfo[];
  fields?: FieldInfo[];
}

/** Known factory functions → return type mappings. */
export const FACTORY_TYPES: Record<string, TypeInfo> = {
  "lurek.graphics.newImage": {
    typeName: "LImage",
    methods: [
      { name: "getDimensions", sig: ":getDimensions()", desc: "Returns width, height" },
      { name: "getWidth", sig: ":getWidth()", desc: "Returns pixel width" },
      { name: "getHeight", sig: ":getHeight()", desc: "Returns pixel height" },
      { name: "getFilter", sig: ":getFilter()", desc: "Returns min, mag filter modes" },
      { name: "setFilter", sig: ":setFilter(min, mag)", desc: "Set texture filter" },
      { name: "setWrap", sig: ":setWrap(horiz, vert)", desc: "Set texture wrap mode" },
      { name: "getWrap", sig: ":getWrap()", desc: "Returns horizontal, vertical wrap" },
      { name: "release", sig: ":release()", desc: "Free GPU resources" },
      { name: "type", sig: ":type()", desc: "Returns 'LImage'" },
    ],
  },
  "lurek.graphics.newCanvas": {
    typeName: "LCanvas",
    methods: [
      { name: "getDimensions", sig: ":getDimensions()", desc: "Returns width, height" },
      { name: "getWidth", sig: ":getWidth()", desc: "Returns pixel width" },
      { name: "getHeight", sig: ":getHeight()", desc: "Returns pixel height" },
      { name: "getFilter", sig: ":getFilter()", desc: "Returns min, mag filter modes" },
      { name: "setFilter", sig: ":setFilter(min, mag)", desc: "Set texture filter" },
      { name: "renderTo", sig: ":renderTo(fn)", desc: "Render to this canvas" },
      { name: "release", sig: ":release()", desc: "Free GPU resources" },
      { name: "type", sig: ":type()", desc: "Returns 'LCanvas'" },
    ],
  },
  "lurek.graphics.newFont": {
    typeName: "LFont",
    methods: [
      { name: "getWidth", sig: ":getWidth(text)", desc: "Width of text in pixels" },
      { name: "getHeight", sig: ":getHeight()", desc: "Font height in pixels" },
      { name: "getLineHeight", sig: ":getLineHeight()", desc: "Returns line height multiplier" },
      { name: "setLineHeight", sig: ":setLineHeight(h)", desc: "Set line height multiplier" },
      { name: "getAscent", sig: ":getAscent()", desc: "Returns font ascent" },
      { name: "getDescent", sig: ":getDescent()", desc: "Returns font descent" },
      { name: "hasGlyphs", sig: ":hasGlyphs(text)", desc: "Check if font has glyphs" },
      { name: "release", sig: ":release()", desc: "Free resources" },
      { name: "type", sig: ":type()", desc: "Returns 'LFont'" },
    ],
  },
  "lurek.graphics.newShader": {
    typeName: "LShader",
    methods: [
      { name: "send", sig: ":send(name, value)", desc: "Set uniform value" },
      { name: "hasUniform", sig: ":hasUniform(name)", desc: "Check if uniform exists" },
      { name: "release", sig: ":release()", desc: "Free GPU resources" },
      { name: "type", sig: ":type()", desc: "Returns 'LShader'" },
    ],
  },
  "lurek.graphics.newMesh": {
    typeName: "LMesh",
    methods: [
      { name: "setVertices", sig: ":setVertices(verts)", desc: "Set vertex data" },
      { name: "setTexture", sig: ":setTexture(tex)", desc: "Set texture for mesh" },
      { name: "getVertexCount", sig: ":getVertexCount()", desc: "Returns vertex count" },
      { name: "release", sig: ":release()", desc: "Free GPU resources" },
      { name: "type", sig: ":type()", desc: "Returns 'LMesh'" },
    ],
  },
  "lurek.graphics.newSpriteBatch": {
    typeName: "LSpriteBatch",
    methods: [
      { name: "add", sig: ":add(quad, x, y, r, sx, sy)", desc: "Add sprite to batch" },
      { name: "clear", sig: ":clear()", desc: "Remove all sprites" },
      { name: "getCount", sig: ":getCount()", desc: "Returns current sprite count" },
      { name: "set", sig: ":set(id, quad, x, y, r, sx, sy)", desc: "Update sprite at index" },
      { name: "flush", sig: ":flush()", desc: "Upload data to GPU" },
      { name: "release", sig: ":release()", desc: "Free GPU resources" },
      { name: "type", sig: ":type()", desc: "Returns 'LSpriteBatch'" },
    ],
  },
  "lurek.graphics.newQuad": {
    typeName: "LQuad",
    methods: [
      { name: "getViewport", sig: ":getViewport()", desc: "Returns x, y, w, h" },
      { name: "setViewport", sig: ":setViewport(x, y, w, h)", desc: "Set viewport rect" },
      { name: "getTextureDimensions", sig: ":getTextureDimensions()", desc: "Returns ref width, height" },
      { name: "type", sig: ":type()", desc: "Returns 'LQuad'" },
    ],
  },
  "lurek.audio.newSource": {
    typeName: "LSource",
    methods: [
      { name: "play", sig: ":play()", desc: "Start or resume playback" },
      { name: "pause", sig: ":pause()", desc: "Pause playback" },
      { name: "stop", sig: ":stop()", desc: "Stop and rewind" },
      { name: "isPlaying", sig: ":isPlaying()", desc: "Returns true if playing" },
      { name: "setVolume", sig: ":setVolume(v)", desc: "Set volume (0-1)" },
      { name: "getVolume", sig: ":getVolume()", desc: "Returns current volume" },
      { name: "setPitch", sig: ":setPitch(p)", desc: "Set pitch multiplier" },
      { name: "getPitch", sig: ":getPitch()", desc: "Returns pitch" },
      { name: "setLooping", sig: ":setLooping(loop)", desc: "Enable/disable loop" },
      { name: "isLooping", sig: ":isLooping()", desc: "Returns loop state" },
      { name: "seek", sig: ":seek(seconds)", desc: "Seek to position" },
      { name: "tell", sig: ":tell()", desc: "Returns current position" },
      { name: "getDuration", sig: ":getDuration()", desc: "Returns duration in seconds" },
      { name: "release", sig: ":release()", desc: "Free audio resources" },
      { name: "type", sig: ":type()", desc: "Returns 'LSource'" },
    ],
  },
  "lurek.physics.newWorld": {
    typeName: "LWorld",
    methods: [
      { name: "update", sig: ":update(dt)", desc: "Step the simulation" },
      { name: "setGravity", sig: ":setGravity(gx, gy)", desc: "Set gravity vector" },
      { name: "getGravity", sig: ":getGravity()", desc: "Returns gx, gy" },
      { name: "getBodyCount", sig: ":getBodyCount()", desc: "Number of bodies" },
      { name: "queryBoundingBox", sig: ":queryBoundingBox(x1, y1, x2, y2, fn)", desc: "Query AABB" },
      { name: "rayCast", sig: ":rayCast(x1, y1, x2, y2, fn)", desc: "Cast a ray" },
      { name: "setCallbacks", sig: ":setCallbacks(begin, end, pre, post)", desc: "Set collision callbacks" },
      { name: "destroy", sig: ":destroy()", desc: "Destroy physics world" },
      { name: "type", sig: ":type()", desc: "Returns 'LWorld'" },
    ],
  },
  "lurek.physics.newBody": {
    typeName: "LBody",
    methods: [
      { name: "getPosition", sig: ":getPosition()", desc: "Returns x, y" },
      { name: "setPosition", sig: ":setPosition(x, y)", desc: "Set position" },
      { name: "getAngle", sig: ":getAngle()", desc: "Returns rotation in radians" },
      { name: "setAngle", sig: ":setAngle(angle)", desc: "Set rotation" },
      { name: "getLinearVelocity", sig: ":getLinearVelocity()", desc: "Returns vx, vy" },
      { name: "setLinearVelocity", sig: ":setLinearVelocity(vx, vy)", desc: "Set velocity" },
      { name: "applyForce", sig: ":applyForce(fx, fy)", desc: "Apply force at center" },
      { name: "applyLinearImpulse", sig: ":applyLinearImpulse(ix, iy)", desc: "Apply impulse" },
      { name: "setMass", sig: ":setMass(mass)", desc: "Set body mass" },
      { name: "getMass", sig: ":getMass()", desc: "Returns body mass" },
      { name: "setType", sig: ':setType(type)', desc: "Set body type" },
      { name: "getType", sig: ":getType()", desc: "Returns body type string" },
      { name: "isAwake", sig: ":isAwake()", desc: "Returns true if body is awake" },
      { name: "destroy", sig: ":destroy()", desc: "Remove body from world" },
      { name: "type", sig: ":type()", desc: "Returns 'LBody'" },
    ],
  },
  "lurek.graphics.newParticleSystem": {
    typeName: "LParticleSystem",
    methods: [
      { name: "emit", sig: ":emit(count)", desc: "Emit particles" },
      { name: "update", sig: ":update(dt)", desc: "Update particle system" },
      { name: "start", sig: ":start()", desc: "Start emitting" },
      { name: "stop", sig: ":stop()", desc: "Stop emitting" },
      { name: "pause", sig: ":pause()", desc: "Pause system" },
      { name: "reset", sig: ":reset()", desc: "Reset and clear particles" },
      { name: "getCount", sig: ":getCount()", desc: "Returns active particle count" },
      { name: "setEmissionRate", sig: ":setEmissionRate(rate)", desc: "Particles per second" },
      { name: "setLifetime", sig: ":setLifetime(min, max)", desc: "Set particle lifetime range" },
      { name: "setPosition", sig: ":setPosition(x, y)", desc: "Set emitter position" },
      { name: "setSpeed", sig: ":setSpeed(min, max)", desc: "Set speed range" },
      { name: "setDirection", sig: ":setDirection(angle)", desc: "Set emission direction" },
      { name: "setSpread", sig: ":setSpread(spread)", desc: "Set emission cone angle" },
      { name: "release", sig: ":release()", desc: "Free resources" },
      { name: "type", sig: ":type()", desc: "Returns 'LParticleSystem'" },
    ],
  },
  // ── cardgame types ────────────────────────────────────────
  // lurek.cardgame.clone is an alias — it clones a Card from another (advanced use)
  "lurek.cardgame.clone": {
    typeName: "LCard",
    fields: [
      { name: "card_type", type: "string", desc: "The registered card type name" },
      { name: "name", type: "string", desc: "Card display name" },
      { name: "category", type: "string", desc: "Category (creature, spell, etc.)" },
      { name: "face_up", type: "boolean", desc: "Whether the card is face-up" },
      { name: "tapped", type: "boolean", desc: "Whether the card is tapped/exhausted" },
      { name: "owner", type: "string", desc: "Owner player identifier" },
      { name: "controller", type: "string", desc: "Controller player identifier" },
      { name: "zone", type: "string", desc: "Current zone name" },
    ],
    methods: [
      { name: "hasTag", sig: ":hasTag(tag)", desc: "Returns true if card has the tag" },
      { name: "addTag", sig: ":addTag(tag)", desc: "Add a tag (deduplicated)" },
      { name: "removeTag", sig: ":removeTag(tag)", desc: "Remove a tag by value" },
      { name: "getStat", sig: ":getStat(name)", desc: "Get a numeric stat value" },
      { name: "setStat", sig: ":setStat(name, value)", desc: "Set a numeric stat value" },
      { name: "addCounter", sig: ":addCounter(kind, amount)", desc: "Add to a counter, returns new total" },
      { name: "getCounter", sig: ":getCounter(kind)", desc: "Get a counter value" },
      { name: "tap", sig: ":tap()", desc: "Tap the card (exhausted)" },
      { name: "untap", sig: ":untap()", desc: "Untap the card" },
      { name: "getMeta", sig: ":getMeta(key)", desc: "Get metadata value" },
      { name: "setMeta", sig: ":setMeta(key, value)", desc: "Set metadata value" },
    ],
  },
  "lurek.cardgame.newCard": {
    typeName: "LCard",
    fields: [
      { name: "card_type", type: "string", desc: "The registered card type name" },
      { name: "name", type: "string", desc: "Card display name" },
      { name: "category", type: "string", desc: "Category (creature, spell, etc.)" },
      { name: "face_up", type: "boolean", desc: "Whether the card is face-up" },
      { name: "tapped", type: "boolean", desc: "Whether the card is tapped/exhausted" },
      { name: "owner", type: "string", desc: "Owner player identifier" },
      { name: "controller", type: "string", desc: "Controller player identifier" },
      { name: "zone", type: "string", desc: "Current zone name" },
    ],
    methods: [
      { name: "hasTag", sig: ":hasTag(tag)", desc: "Returns true if card has the tag" },
      { name: "addTag", sig: ":addTag(tag)", desc: "Add a tag (deduplicated)" },
      { name: "removeTag", sig: ":removeTag(tag)", desc: "Remove a tag by value" },
      { name: "getStat", sig: ":getStat(name)", desc: "Get a numeric stat value" },
      { name: "setStat", sig: ":setStat(name, value)", desc: "Set a numeric stat value" },
      { name: "addCounter", sig: ":addCounter(kind, amount)", desc: "Add to a counter, returns new total" },
      { name: "getCounter", sig: ":getCounter(kind)", desc: "Get a counter value" },
      { name: "removeCounters", sig: ":removeCounters(kind)", desc: "Remove all counters of a type" },
      { name: "getMeta", sig: ":getMeta(key)", desc: "Get metadata value" },
      { name: "setMeta", sig: ":setMeta(key, value)", desc: "Set metadata value" },
      { name: "tap", sig: ":tap()", desc: "Tap the card (exhausted)" },
      { name: "untap", sig: ":untap()", desc: "Untap the card" },
      { name: "getAllCounters", sig: ":getAllCounters()", desc: "Returns all (kind, count) counter pairs" },
    ],
  },
  "lurek.cardgame.newDeck": {
    typeName: "LDeck",
    fields: [
      { name: "name", type: "string", desc: "Deck display name" },
    ],
    methods: [
      { name: "shuffle", sig: ":shuffle()", desc: "Shuffle using Fisher-Yates" },
      { name: "draw", sig: ":draw()", desc: "Draw from the top; returns Card or nil" },
      { name: "drawBottom", sig: ":drawBottom()", desc: "Draw from the bottom" },
      { name: "pushTop", sig: ":pushTop(card)", desc: "Add a card to the top" },
      { name: "pushBottom", sig: ":pushBottom(card)", desc: "Add a card to the bottom" },
      { name: "peek", sig: ":peek()", desc: "Peek at the top card without removing" },
      { name: "insertAt", sig: ":insertAt(index, card)", desc: "Insert a card at a 0-based position" },
      { name: "removeAt", sig: ":removeAt(index)", desc: "Remove and return card at index" },
      { name: "moveWithin", sig: ":moveWithin(from, to)", desc: "Move card at from_index to to_index" },
      { name: "size", sig: ":size()", desc: "Returns card count" },
      { name: "isEmpty", sig: ":isEmpty()", desc: "Returns true if empty" },
      { name: "searchByTag", sig: ":searchByTag(tag)", desc: "Returns indices of cards with tag" },
      { name: "searchByType", sig: ":searchByType(card_type)", desc: "Returns indices of matching type" },
      { name: "countByType", sig: ":countByType(card_type)", desc: "Count cards of a specific type" },
      { name: "revealTop", sig: ":revealTop(n)", desc: "Peek at top n cards, returns type strings" },
      { name: "reset", sig: ":reset()", desc: "Reset to original state" },
    ],
  },
  "lurek.cardgame.newDeckBuilder": {
    typeName: "LDeckBuilder",
    fields: [
      { name: "min_cards", type: "integer", desc: "Minimum total cards required" },
      { name: "max_cards", type: "integer", desc: "Maximum total cards allowed (0 = no limit)" },
      { name: "max_copies", type: "integer", desc: "Maximum copies of a single card type" },
    ],
    methods: [
      { name: "validate", sig: ":validate(deck)", desc: "Validate a deck, returns list of violation messages" },
    ],
  },
  "lurek.cardgame.newStackManager": {
    typeName: "LStackManager",
    methods: [
      { name: "push", sig: ":push(entry)", desc: "Push an entry onto the stack" },
      { name: "resolve", sig: ":resolve()", desc: "Pop and return the top entry" },
      { name: "peek", sig: ":peek()", desc: "Peek at the top entry" },
      { name: "isEmpty", sig: ":isEmpty()", desc: "Whether the stack has anything to resolve" },
      { name: "size", sig: ":size()", desc: "Number of entries on the stack" },
      { name: "clear", sig: ":clear()", desc: "Clear all entries" },
      { name: "findByKind", sig: ":findByKind(kind)", desc: "Find first entry matching a kind" },
    ],
  },
  "lurek.cardgame.newZone": {
    typeName: "LZone",
    fields: [
      { name: "name", type: "string", desc: "Zone name" },
      { name: "capacity", type: "integer", desc: "Max capacity (0 = unlimited)" },
    ],
    methods: [
      { name: "canAdd", sig: ":canAdd()", desc: "Returns true if zone accepts one more card" },
      { name: "add", sig: ":add(card)", desc: "Add a card (returns error if zone full)" },
      { name: "removeAt", sig: ":removeAt(index)", desc: "Remove card at 0-based index" },
      { name: "size", sig: ":size()", desc: "Number of cards in zone" },
      { name: "isEmpty", sig: ":isEmpty()", desc: "True if empty" },
      { name: "findByType", sig: ":findByType(card_type)", desc: "Find first card by type" },
      { name: "countByType", sig: ":countByType(card_type)", desc: "Count cards of a specific type" },
      { name: "getAllTypes", sig: ":getAllTypes()", desc: "Return type strings of all cards" },
    ],
  },
  "lurek.cardgame.newCardPool": {
    typeName: "LCardPool",
    fields: [
      { name: "name", type: "string", desc: "Pool name" },
    ],
    methods: [
      { name: "add", sig: ":add(card_type, weight)", desc: "Add a card type with weight (default 1)" },
      { name: "remove", sig: ":remove(card_type)", desc: "Remove a card type from pool" },
      { name: "draw", sig: ":draw(n)", desc: "Draw n cards (with replacement), returns type names" },
      { name: "size", sig: ":size()", desc: "Number of entries" },
      { name: "getTypes", sig: ":getTypes()", desc: "Returns all card types in pool" },
      { name: "totalWeight", sig: ":totalWeight()", desc: "Total weight of all entries" },
    ],
  },
  // ── entity types ──────────────────────────────────────────
  "lurek.ecs.new": {
    typeName: "LEntity",
    methods: [
      { name: "getId", sig: ":getId()", desc: "Returns entity ID" },
      { name: "getTag", sig: ":getTag()", desc: "Returns entity tag" },
      { name: "setTag", sig: ":setTag(tag)", desc: "Set entity tag" },
      { name: "getPosition", sig: ":getPosition()", desc: "Returns x, y" },
      { name: "setPosition", sig: ":setPosition(x, y)", desc: "Set position" },
      { name: "getComponent", sig: ":getComponent(name)", desc: "Get component by name" },
      { name: "addComponent", sig: ":addComponent(name, data)", desc: "Add component" },
      { name: "removeComponent", sig: ":removeComponent(name)", desc: "Remove component" },
      { name: "hasComponent", sig: ":hasComponent(name)", desc: "Returns true if entity has component" },
      { name: "destroy", sig: ":destroy()", desc: "Destroy entity" },
      { name: "isAlive", sig: ":isAlive()", desc: "Returns true if entity is alive" },
      { name: "type", sig: ":type()", desc: "Returns 'LEntity'" },
    ],
  },
  // ── timer types ───────────────────────────────────────────
  "lurek.timer.after": {
    typeName: "LTimer",
    methods: [
      { name: "cancel", sig: ":cancel()", desc: "Cancel the timer" },
      { name: "pause", sig: ":pause()", desc: "Pause the timer" },
      { name: "resume", sig: ":resume()", desc: "Resume the timer" },
      { name: "isActive", sig: ":isActive()", desc: "Returns true if still active" },
      { name: "type", sig: ":type()", desc: "Returns 'LTimer'" },
    ],
  },
  "lurek.timer.every": {
    typeName: "LTimer",
    methods: [
      { name: "cancel", sig: ":cancel()", desc: "Cancel the timer" },
      { name: "pause", sig: ":pause()", desc: "Pause the timer" },
      { name: "resume", sig: ":resume()", desc: "Resume the timer" },
      { name: "isActive", sig: ":isActive()", desc: "Returns true if still active" },
      { name: "type", sig: ":type()", desc: "Returns 'LTimer'" },
    ],
  },
  "lurek.timer.tween": {
    typeName: "LTween",
    methods: [
      { name: "cancel", sig: ":cancel()", desc: "Cancel the tween" },
      { name: "pause", sig: ":pause()", desc: "Pause the tween" },
      { name: "resume", sig: ":resume()", desc: "Resume the tween" },
      { name: "isActive", sig: ":isActive()", desc: "Returns true if still active" },
      { name: "getProgress", sig: ":getProgress()", desc: "Returns progress 0-1" },
      { name: "type", sig: ":type()", desc: "Returns 'LTween'" },
    ],
  },
  // ── tilemap types ─────────────────────────────────────────
  "lurek.tilemap.load": {
    typeName: "LTilemap",
    methods: [
      { name: "draw", sig: ":draw()", desc: "Draw the tilemap" },
      { name: "getWidth", sig: ":getWidth()", desc: "Returns width in tiles" },
      { name: "getHeight", sig: ":getHeight()", desc: "Returns height in tiles" },
      { name: "getTileAt", sig: ":getTileAt(x, y)", desc: "Get tile at grid position" },
      { name: "setTileAt", sig: ":setTileAt(x, y, tile)", desc: "Set tile at grid position" },
      { name: "getLayer", sig: ":getLayer(name)", desc: "Get layer by name" },
      { name: "getLayerCount", sig: ":getLayerCount()", desc: "Returns number of layers" },
      { name: "getProperty", sig: ":getProperty(name)", desc: "Get map property" },
      { name: "type", sig: ":type()", desc: "Returns 'LTilemap'" },
    ],
  },
  // ── scene types ───────────────────────────────────────────
  "lurek.scene.new": {
    typeName: "LScene",
    methods: [
      { name: "enter", sig: ":enter()", desc: "Called when scene becomes active" },
      { name: "exit", sig: ":exit()", desc: "Called when scene is deactivated" },
      { name: "update", sig: ":update(dt)", desc: "Update scene" },
      { name: "draw", sig: ":draw()", desc: "Draw scene" },
      { name: "getName", sig: ":getName()", desc: "Returns scene name" },
      { name: "type", sig: ":type()", desc: "Returns 'LScene'" },
    ],
  },
  // ── data types ────────────────────────────────────────────
  "lurek.data.newStore": {
    typeName: "LDataStore",
    methods: [
      { name: "get", sig: ":get(key)", desc: "Get value by key" },
      { name: "set", sig: ":set(key, value)", desc: "Set a key-value pair" },
      { name: "delete", sig: ":delete(key)", desc: "Delete a key" },
      { name: "has", sig: ":has(key)", desc: "Returns true if key exists" },
      { name: "keys", sig: ":keys()", desc: "Returns all keys" },
      { name: "values", sig: ":values()", desc: "Returns all values" },
      { name: "clear", sig: ":clear()", desc: "Remove all entries" },
      { name: "size", sig: ":size()", desc: "Returns number of entries" },
      { name: "type", sig: ":type()", desc: "Returns 'LDataStore'" },
    ],
  },
  // ── event types ───────────────────────────────────────────
  "lurek.event.on": {
    typeName: "LEventHandle",
    methods: [
      { name: "cancel", sig: ":cancel()", desc: "Unsubscribe from event" },
      { name: "type", sig: ":type()", desc: "Returns 'LEventHandle'" },
    ],
  },
  // ── camera types ──────────────────────────────────────────
  "lurek.camera.new": {
    typeName: "LCamera",
    methods: [
      { name: "getPosition", sig: ":getPosition()", desc: "Returns x, y" },
      { name: "setPosition", sig: ":setPosition(x, y)", desc: "Set camera position" },
      { name: "getZoom", sig: ":getZoom()", desc: "Returns zoom level" },
      { name: "setZoom", sig: ":setZoom(zoom)", desc: "Set zoom level" },
      { name: "getRotation", sig: ":getRotation()", desc: "Returns rotation in radians" },
      { name: "setRotation", sig: ":setRotation(angle)", desc: "Set rotation" },
      { name: "lookAt", sig: ":lookAt(x, y)", desc: "Center camera on position" },
      { name: "shake", sig: ":shake(intensity, duration)", desc: "Apply screen shake" },
      { name: "attach", sig: ":attach()", desc: "Apply camera transform" },
      { name: "detach", sig: ":detach()", desc: "Reset camera transform" },
      { name: "worldToScreen", sig: ":worldToScreen(wx, wy)", desc: "Convert world to screen coords" },
      { name: "screenToWorld", sig: ":screenToWorld(sx, sy)", desc: "Convert screen to world coords" },
      { name: "type", sig: ":type()", desc: "Returns 'LCamera'" },
    ],
  },
};

// ── Known lurek sub-modules (for alias detection) ─────────
const LUREK_MODULES = [
  "render", "audio", "physics", "input", "timer", "filesystem",
  "compute", "data", "image", "ecs", "window", "thread",
  "animation", "camera", "automation", "event", "math",
  "particle", "tilemap", "scene", "save", "mods",
  "graph", "pathfind", "ai", "dataframe", "ui", "minimap",
  "effect", "postfx", "terminal", "cardgame", "tween",
];

// ── Variable → Type tracking ──────────────────────────────

export interface VarType {
  varName: string;
  typeName: string;
  factoryCall: string; // the factory function that created this, e.g. "lurek.graphics.newImage"
  line: number;
}

export interface ModuleAlias {
  varName: string;
  modulePath: string; // e.g. "lurek.graphics"
  line: number;
}

export interface ClassInfo {
  name: string;
  methods: MethodInfo[];
  instances: { varName: string; line: number }[];
}

/**
 * Scan document for `local var = lurek.*.new*()` patterns, OOP classes,
 * module aliases (`local gfx = lurek.graphics`), and re-assignments.
 */
export function scanDocument(document: vscode.TextDocument): {
  varTypes: VarType[];
  classes: ClassInfo[];
  moduleAliases: ModuleAlias[];
} {
  const varTypes: VarType[] = [];
  const classes: ClassInfo[] = [];
  const moduleAliases: ModuleAlias[] = [];
  const classMap = new Map<string, ClassInfo>();
  const text = document.getText();
  const lines = text.split("\n");

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Match: local var = lurek.module.anyFunction(...)
    const factoryMatch = line.match(
      /\blocal\s+(\w+)\s*=\s*(lurek\.\w+\.\w+)\s*\(/
    );
    if (factoryMatch) {
      const [, varName, factoryCall] = factoryMatch;
      const returnTypeName = getReturnTypeName(factoryCall);
      if (returnTypeName) {
        varTypes.push({ varName, typeName: returnTypeName, factoryCall, line: i });
      }
    }

    // Match module alias: local X = lurek.MODULE (no parentheses — not a function call)
    const aliasMatch = line.match(
      /\blocal\s+(\w+)\s*=\s*(lurek\.(\w+))\s*(?:$|--)/
    );
    if (aliasMatch) {
      const [, varName, modulePath, moduleName] = aliasMatch;
      if ((_apiDataSingleton?.getModuleNames() ?? LUREK_MODULES).includes(moduleName)) {
        moduleAliases.push({ varName, modulePath, line: i });
      }
    }

    // Match re-assignment: local b = a (where a is a known typed variable)
    const reassignMatch = line.match(
      /\blocal\s+(\w+)\s*=\s*(\w+)\s*(?:$|--)/
    );
    if (reassignMatch) {
      const [, newVar, sourceVar] = reassignMatch;
      const sourceType = varTypes.find(
        (v) => v.varName === sourceVar && v.line < i
      );
      if (sourceType) {
        varTypes.push({
          varName: newVar,
          typeName: sourceType.typeName,
          factoryCall: sourceType.factoryCall,
          line: i,
        });
      }
    }

    // Match OOP class pattern: ClassName = {} or local ClassName = {}
    const classDefMatch = line.match(
      /\b(?:local\s+)?(\w+)\s*=\s*\{\s*\}/
    );
    if (classDefMatch) {
      const className = classDefMatch[1];
      // Check if next lines have __index pattern
      if (i + 1 < lines.length) {
        const nextLine = lines[i + 1];
        if (nextLine.includes(`${className}.__index`) || nextLine.includes(`__index = ${className}`)) {
          if (!classMap.has(className)) {
            classMap.set(className, { name: className, methods: [], instances: [] });
          }
        }
      }
    }

    // Detect __index assignment: Foo.__index = Foo
    const indexMatch = line.match(/\b(\w+)\.__index\s*=\s*\1\b/);
    if (indexMatch) {
      const className = indexMatch[1];
      if (!classMap.has(className)) {
        classMap.set(className, { name: className, methods: [], instances: [] });
      }
    }

    // Detect class method: function ClassName:methodName(...)
    const methodMatch = line.match(
      /\bfunction\s+(\w+):(\w+)\s*\(/
    );
    if (methodMatch) {
      const [, className, methodName] = methodMatch;
      let cls = classMap.get(className);
      if (!cls) {
        cls = { name: className, methods: [], instances: [] };
        classMap.set(className, cls);
      }
      if (!cls.methods.find((m) => m.name === methodName)) {
        cls.methods.push({
          name: methodName,
          sig: `:${methodName}(...)`,
          desc: `Method of ${className}`,
        });
      }
    }

    // Detect instance creation: local obj = ClassName:new() or ClassName.new()
    const instanceMatch = line.match(
      /\blocal\s+(\w+)\s*=\s*(\w+)[:.](new|create)\s*\(/
    );
    if (instanceMatch) {
      const [, varName, className] = instanceMatch;
      const cls = classMap.get(className);
      if (cls) {
        cls.instances.push({ varName, line: i });
      }
    }

    // Detect setmetatable pattern: local obj = setmetatable({...}, ClassName)
    // Also handles:  setmetatable({}, {__index = ClassName})
    const setmetaMatch =
      line.match(/\blocal\s+(\w+)\s*=\s*setmetatable\s*\([^,]*,\s*(\w+)\s*\)/) ??
      line.match(/\blocal\s+(\w+)\s*=\s*setmetatable\s*\([^,]*,\s*\{[^}]*__index\s*=\s*(\w+)[^}]*\}\s*\)/);
    if (setmetaMatch) {
      const [, varName, className] = setmetaMatch;
      const cls = classMap.get(className);
      if (cls) {
        cls.instances.push({ varName, line: i });
      }
    }
  }

  for (const cls of classMap.values()) {
    classes.push(cls);
  }

  return { varTypes, classes, moduleAliases };
}

/**
 * Get the full TypeInfo for a variable at a given position.
 */
export function getTypeInfoForVar(
  varName: string,
  position: vscode.Position,
  varTypes: VarType[],
  classes: ClassInfo[]
): { typeInfo: TypeInfo; factoryCall: string } | undefined {
  const factoryVar = varTypes.find(
    (v) => v.varName === varName && v.line < position.line
  );
  if (factoryVar) {
    const typeInfo = getTypeInfoByName(factoryVar.typeName);
    if (typeInfo) return { typeInfo, factoryCall: factoryVar.factoryCall };
  }
  return undefined;
}

/**
 * Get methods for a variable at a given position.
 */
export function getMethodsForVar(
  varName: string,
  position: vscode.Position,
  varTypes: VarType[],
  classes: ClassInfo[]
): MethodInfo[] | undefined {
  // Check factory-typed variables
  const factoryVar = varTypes.find(
    (v) => v.varName === varName && v.line < position.line
  );
  if (factoryVar) {
    const typeInfo = getTypeInfoByName(factoryVar.typeName);
    if (typeInfo) return typeInfo.methods;
  }

  // Check OOP class instances
  for (const cls of classes) {
    const instance = cls.instances.find(
      (inst) => inst.varName === varName && inst.line < position.line
    );
    if (instance && cls.methods.length > 0) {
      return cls.methods;
    }
  }

  return undefined;
}

/**
 * Registers the type inference completion provider.
 */
export function register(
  context: vscode.ExtensionContext,
  apiData: ApiDataService
): void {
  setApiData(apiData);
  // Colon provider — method completions (var:method)
  const colonProvider = vscode.languages.registerCompletionItemProvider(
    LUA_SELECTOR,
    {
      provideCompletionItems(
        document: vscode.TextDocument,
        position: vscode.Position
      ): vscode.CompletionItem[] | undefined {
        const lineText = document.lineAt(position).text;
        const before = lineText.substring(0, position.character);

        // Trigger on varName: (colon method call)
        const colonMatch = before.match(/\b(\w+):(\w*)$/);
        if (!colonMatch) return undefined;

        const varName = colonMatch[1];
        const partial = colonMatch[2].toLowerCase();
        const { varTypes, classes } = scanDocument(document);
        const methods = getMethodsForVar(varName, position, varTypes, classes);

        if (!methods) return undefined;

        return methods
          .filter((m) => !partial || m.name.toLowerCase().startsWith(partial))
          .map((m) => {
            const item = new vscode.CompletionItem(
              m.name,
              vscode.CompletionItemKind.Method
            );
            item.detail = m.sig;
            item.documentation = new vscode.MarkdownString(m.desc);
            item.sortText = `0${m.name}`; // Sort above other completions
            return item;
          });
      },
    },
    ":"
  );

  // Dot provider — field + method completions (var.field, var.method)
  const dotProvider = vscode.languages.registerCompletionItemProvider(
    LUA_SELECTOR,
    {
      provideCompletionItems(
        document: vscode.TextDocument,
        position: vscode.Position
      ): vscode.CompletionItem[] | undefined {
        const lineText = document.lineAt(position).text;
        const before = lineText.substring(0, position.character);

        // Trigger on varName. but NOT lurek. module paths (e.g. lurek.graphics.)
        const dotMatch = before.match(/\b(\w+)\.(\w*)$/);
        if (!dotMatch) return undefined;

        const varName = dotMatch[1];
        // Skip lurek.* module calls — those are handled by the main completion provider
        if (varName === "lurek") return undefined;

        const partial = dotMatch[2].toLowerCase();
        const { varTypes, classes, moduleAliases } = scanDocument(document);

        // Check module aliases: local gfx = lurek.graphics → gfx.newImage()
        const alias = moduleAliases.find(
          (a) => a.varName === varName && a.line < position.line
        );
        if (alias) {
          const prefix = alias.modulePath + ".";
          const items: vscode.CompletionItem[] = [];
          for (const key of getAllFactoryPaths()) {
            if (key.startsWith(prefix)) {
              const funcName = key.substring(prefix.length);
              if (!partial || funcName.toLowerCase().startsWith(partial)) {
                const typeName = getReturnTypeName(key);
                if (!typeName) continue;
                const item = new vscode.CompletionItem(
                  funcName,
                  vscode.CompletionItemKind.Function
                );
                item.detail = `→ ${typeName}`;
                item.documentation = new vscode.MarkdownString(
                  `Factory from \`${key}\``
                );
                item.sortText = `0${funcName}`;
                items.push(item);
              }
            }
          }
          if (items.length > 0) return items;
        }

        const items: vscode.CompletionItem[] = [];

        // Check factory-typed variables
        const factoryVar = varTypes.find(
          (v) => v.varName === varName && v.line < position.line
        );
        if (factoryVar) {
          const typeInfo = getTypeInfoByName(factoryVar.typeName);
          if (typeInfo) {
            // Add fields
            if (typeInfo.fields) {
              for (const f of typeInfo.fields) {
                if (partial && !f.name.toLowerCase().startsWith(partial)) continue;
                const item = new vscode.CompletionItem(
                  f.name,
                  vscode.CompletionItemKind.Field
                );
                item.detail = f.type;
                item.documentation = new vscode.MarkdownString(f.desc);
                item.sortText = `0a${f.name}`; // Fields before methods
                items.push(item);
              }
            }
            // Add methods (Lua allows obj.method(obj, ...) syntax)
            for (const m of typeInfo.methods) {
              if (partial && !m.name.toLowerCase().startsWith(partial)) continue;
              const item = new vscode.CompletionItem(
                m.name,
                vscode.CompletionItemKind.Method
              );
              item.detail = m.sig;
              item.documentation = new vscode.MarkdownString(m.desc);
              item.sortText = `0b${m.name}`; // Methods after fields
              items.push(item);
            }
          }
        }

        // Check OOP class instances
        if (items.length === 0) {
          for (const cls of classes) {
            const instance = cls.instances.find(
              (inst) => inst.varName === varName && inst.line < position.line
            );
            if (instance && cls.methods.length > 0) {
              for (const m of cls.methods) {
                if (partial && !m.name.toLowerCase().startsWith(partial)) continue;
                const item = new vscode.CompletionItem(
                  m.name,
                  vscode.CompletionItemKind.Method
                );
                item.detail = m.sig;
                item.documentation = new vscode.MarkdownString(m.desc);
                item.sortText = `0${m.name}`;
                items.push(item);
              }
              break;
            }
          }
        }

        return items.length > 0 ? items : undefined;
      },
    },
    "."
  );

  // Hover provider — show type info for typed variables
  const hoverProvider = vscode.languages.registerHoverProvider(LUA_SELECTOR, {
    provideHover(
      document: vscode.TextDocument,
      position: vscode.Position
    ): vscode.Hover | undefined {
      const wordRange = document.getWordRangeAtPosition(position, /\w+/);
      if (!wordRange) return undefined;

      const word = document.getText(wordRange);
      const { varTypes, classes, moduleAliases } = scanDocument(document);

      // Check module aliases
      const alias = moduleAliases.find(
        (a) => a.varName === word && a.line < position.line
      );
      if (alias) {
        const md = new vscode.MarkdownString();
        md.appendCodeblock(`${word}: module (${alias.modulePath})`, "lua");
        md.appendMarkdown(`Alias for \`${alias.modulePath}\``);
        return new vscode.Hover(md, wordRange);
      }

      // Check factory-typed variables
      const result = getTypeInfoForVar(word, position, varTypes, classes);
      if (result) {
        const { typeInfo, factoryCall } = result;
        const md = new vscode.MarkdownString();
        md.appendCodeblock(`${word}: ${typeInfo.typeName}`, "lua");
        md.appendMarkdown(`Created by \`${factoryCall}()\`\n\n`);
        if (typeInfo.fields && typeInfo.fields.length > 0) {
          md.appendMarkdown(
            `**Fields:** ${typeInfo.fields.map((f) => `\`${f.name}\``).join(", ")}\n\n`
          );
        }
        md.appendMarkdown(
          `**Methods:** ${typeInfo.methods.map((m) => `\`${m.name}\``).join(", ")}`
        );
        return new vscode.Hover(md, wordRange);
      }

      // Check OOP class instances
      for (const cls of classes) {
        const instance = cls.instances.find(
          (inst) => inst.varName === word && inst.line < position.line
        );
        if (instance && cls.methods.length > 0) {
          const md = new vscode.MarkdownString();
          md.appendCodeblock(`${word}: ${cls.name}`, "lua");
          md.appendMarkdown(
            `**Methods:** ${cls.methods.map((m) => `\`${m.name}\``).join(", ")}`
          );
          return new vscode.Hover(md, wordRange);
        }
      }

      return undefined;
    },
  });

  context.subscriptions.push(colonProvider, dotProvider, hoverProvider);
}
