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

// src/test/unit/typeInference.test.ts
var assert = __toESM(require("assert"));

// src/providers/typeInference.ts
var vscode = __toESM(require("vscode"));
var FACTORY_TYPES = {
  "lurek.graphics.newImage": {
    typeName: "Image",
    methods: [
      { name: "getDimensions", sig: ":getDimensions()", desc: "Returns width, height" },
      { name: "getWidth", sig: ":getWidth()", desc: "Returns pixel width" },
      { name: "getHeight", sig: ":getHeight()", desc: "Returns pixel height" },
      { name: "getFilter", sig: ":getFilter()", desc: "Returns min, mag filter modes" },
      { name: "setFilter", sig: ":setFilter(min, mag)", desc: "Set texture filter" },
      { name: "setWrap", sig: ":setWrap(horiz, vert)", desc: "Set texture wrap mode" },
      { name: "getWrap", sig: ":getWrap()", desc: "Returns horizontal, vertical wrap" },
      { name: "release", sig: ":release()", desc: "Free GPU resources" },
      { name: "type", sig: ":type()", desc: "Returns 'Image'" }
    ]
  },
  "lurek.graphics.newCanvas": {
    typeName: "Canvas",
    methods: [
      { name: "getDimensions", sig: ":getDimensions()", desc: "Returns width, height" },
      { name: "getWidth", sig: ":getWidth()", desc: "Returns pixel width" },
      { name: "getHeight", sig: ":getHeight()", desc: "Returns pixel height" },
      { name: "getFilter", sig: ":getFilter()", desc: "Returns min, mag filter modes" },
      { name: "setFilter", sig: ":setFilter(min, mag)", desc: "Set texture filter" },
      { name: "renderTo", sig: ":renderTo(fn)", desc: "Render to this canvas" },
      { name: "release", sig: ":release()", desc: "Free GPU resources" },
      { name: "type", sig: ":type()", desc: "Returns 'Canvas'" }
    ]
  },
  "lurek.graphics.newFont": {
    typeName: "Font",
    methods: [
      { name: "getWidth", sig: ":getWidth(text)", desc: "Width of text in pixels" },
      { name: "getHeight", sig: ":getHeight()", desc: "Font height in pixels" },
      { name: "getLineHeight", sig: ":getLineHeight()", desc: "Returns line height multiplier" },
      { name: "setLineHeight", sig: ":setLineHeight(h)", desc: "Set line height multiplier" },
      { name: "getAscent", sig: ":getAscent()", desc: "Returns font ascent" },
      { name: "getDescent", sig: ":getDescent()", desc: "Returns font descent" },
      { name: "hasGlyphs", sig: ":hasGlyphs(text)", desc: "Check if font has glyphs" },
      { name: "release", sig: ":release()", desc: "Free resources" },
      { name: "type", sig: ":type()", desc: "Returns 'Font'" }
    ]
  },
  "lurek.graphics.newShader": {
    typeName: "Shader",
    methods: [
      { name: "send", sig: ":send(name, value)", desc: "Set uniform value" },
      { name: "hasUniform", sig: ":hasUniform(name)", desc: "Check if uniform exists" },
      { name: "release", sig: ":release()", desc: "Free GPU resources" },
      { name: "type", sig: ":type()", desc: "Returns 'Shader'" }
    ]
  },
  "lurek.graphics.newMesh": {
    typeName: "Mesh",
    methods: [
      { name: "setVertices", sig: ":setVertices(verts)", desc: "Set vertex data" },
      { name: "setTexture", sig: ":setTexture(tex)", desc: "Set texture for mesh" },
      { name: "getVertexCount", sig: ":getVertexCount()", desc: "Returns vertex count" },
      { name: "release", sig: ":release()", desc: "Free GPU resources" },
      { name: "type", sig: ":type()", desc: "Returns 'Mesh'" }
    ]
  },
  "lurek.graphics.newSpriteBatch": {
    typeName: "SpriteBatch",
    methods: [
      { name: "add", sig: ":add(quad, x, y, r, sx, sy)", desc: "Add sprite to batch" },
      { name: "clear", sig: ":clear()", desc: "Remove all sprites" },
      { name: "getCount", sig: ":getCount()", desc: "Returns current sprite count" },
      { name: "set", sig: ":set(id, quad, x, y, r, sx, sy)", desc: "Update sprite at index" },
      { name: "flush", sig: ":flush()", desc: "Upload data to GPU" },
      { name: "release", sig: ":release()", desc: "Free GPU resources" },
      { name: "type", sig: ":type()", desc: "Returns 'SpriteBatch'" }
    ]
  },
  "lurek.graphics.newQuad": {
    typeName: "Quad",
    methods: [
      { name: "getViewport", sig: ":getViewport()", desc: "Returns x, y, w, h" },
      { name: "setViewport", sig: ":setViewport(x, y, w, h)", desc: "Set viewport rect" },
      { name: "getTextureDimensions", sig: ":getTextureDimensions()", desc: "Returns ref width, height" },
      { name: "type", sig: ":type()", desc: "Returns 'Quad'" }
    ]
  },
  "lurek.audio.newSource": {
    typeName: "Source",
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
      { name: "type", sig: ":type()", desc: "Returns 'Source'" }
    ]
  },
  "lurek.physics.newWorld": {
    typeName: "World",
    methods: [
      { name: "update", sig: ":update(dt)", desc: "Step the simulation" },
      { name: "setGravity", sig: ":setGravity(gx, gy)", desc: "Set gravity vector" },
      { name: "getGravity", sig: ":getGravity()", desc: "Returns gx, gy" },
      { name: "getBodyCount", sig: ":getBodyCount()", desc: "Number of bodies" },
      { name: "queryBoundingBox", sig: ":queryBoundingBox(x1, y1, x2, y2, fn)", desc: "Query AABB" },
      { name: "rayCast", sig: ":rayCast(x1, y1, x2, y2, fn)", desc: "Cast a ray" },
      { name: "setCallbacks", sig: ":setCallbacks(begin, end, pre, post)", desc: "Set collision callbacks" },
      { name: "destroy", sig: ":destroy()", desc: "Destroy physics world" },
      { name: "type", sig: ":type()", desc: "Returns 'World'" }
    ]
  },
  "lurek.physics.newBody": {
    typeName: "Body",
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
      { name: "setType", sig: ":setType(type)", desc: "Set body type" },
      { name: "getType", sig: ":getType()", desc: "Returns body type string" },
      { name: "isAwake", sig: ":isAwake()", desc: "Returns true if body is awake" },
      { name: "destroy", sig: ":destroy()", desc: "Remove body from world" },
      { name: "type", sig: ":type()", desc: "Returns 'Body'" }
    ]
  },
  "lurek.graphics.newParticleSystem": {
    typeName: "ParticleSystem",
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
      { name: "type", sig: ":type()", desc: "Returns 'ParticleSystem'" }
    ]
  },
  // ── cardgame types ────────────────────────────────────────
  // lurek.cardgame.clone is an alias — it clones a Card from another (advanced use)
  "lurek.cardgame.clone": {
    typeName: "Card",
    fields: [
      { name: "card_type", type: "string", desc: "The registered card type name" },
      { name: "name", type: "string", desc: "Card display name" },
      { name: "category", type: "string", desc: "Category (creature, spell, etc.)" },
      { name: "face_up", type: "boolean", desc: "Whether the card is face-up" },
      { name: "tapped", type: "boolean", desc: "Whether the card is tapped/exhausted" },
      { name: "owner", type: "string", desc: "Owner player identifier" },
      { name: "controller", type: "string", desc: "Controller player identifier" },
      { name: "zone", type: "string", desc: "Current zone name" }
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
      { name: "setMeta", sig: ":setMeta(key, value)", desc: "Set metadata value" }
    ]
  },
  "lurek.cardgame.newCard": {
    typeName: "Card",
    fields: [
      { name: "card_type", type: "string", desc: "The registered card type name" },
      { name: "name", type: "string", desc: "Card display name" },
      { name: "category", type: "string", desc: "Category (creature, spell, etc.)" },
      { name: "face_up", type: "boolean", desc: "Whether the card is face-up" },
      { name: "tapped", type: "boolean", desc: "Whether the card is tapped/exhausted" },
      { name: "owner", type: "string", desc: "Owner player identifier" },
      { name: "controller", type: "string", desc: "Controller player identifier" },
      { name: "zone", type: "string", desc: "Current zone name" }
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
      { name: "getAllCounters", sig: ":getAllCounters()", desc: "Returns all (kind, count) counter pairs" }
    ]
  },
  "lurek.cardgame.newDeck": {
    typeName: "Deck",
    fields: [
      { name: "name", type: "string", desc: "Deck display name" }
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
      { name: "reset", sig: ":reset()", desc: "Reset to original state" }
    ]
  },
  "lurek.cardgame.newDeckBuilder": {
    typeName: "DeckBuilder",
    fields: [
      { name: "min_cards", type: "integer", desc: "Minimum total cards required" },
      { name: "max_cards", type: "integer", desc: "Maximum total cards allowed (0 = no limit)" },
      { name: "max_copies", type: "integer", desc: "Maximum copies of a single card type" }
    ],
    methods: [
      { name: "validate", sig: ":validate(deck)", desc: "Validate a deck, returns list of violation messages" }
    ]
  },
  "lurek.cardgame.newStackManager": {
    typeName: "StackManager",
    methods: [
      { name: "push", sig: ":push(entry)", desc: "Push an entry onto the stack" },
      { name: "resolve", sig: ":resolve()", desc: "Pop and return the top entry" },
      { name: "peek", sig: ":peek()", desc: "Peek at the top entry" },
      { name: "isEmpty", sig: ":isEmpty()", desc: "Whether the stack has anything to resolve" },
      { name: "size", sig: ":size()", desc: "Number of entries on the stack" },
      { name: "clear", sig: ":clear()", desc: "Clear all entries" },
      { name: "findByKind", sig: ":findByKind(kind)", desc: "Find first entry matching a kind" }
    ]
  },
  "lurek.cardgame.newZone": {
    typeName: "Zone",
    fields: [
      { name: "name", type: "string", desc: "Zone name" },
      { name: "capacity", type: "integer", desc: "Max capacity (0 = unlimited)" }
    ],
    methods: [
      { name: "canAdd", sig: ":canAdd()", desc: "Returns true if zone accepts one more card" },
      { name: "add", sig: ":add(card)", desc: "Add a card (returns error if zone full)" },
      { name: "removeAt", sig: ":removeAt(index)", desc: "Remove card at 0-based index" },
      { name: "size", sig: ":size()", desc: "Number of cards in zone" },
      { name: "isEmpty", sig: ":isEmpty()", desc: "True if empty" },
      { name: "findByType", sig: ":findByType(card_type)", desc: "Find first card by type" },
      { name: "countByType", sig: ":countByType(card_type)", desc: "Count cards of a specific type" },
      { name: "getAllTypes", sig: ":getAllTypes()", desc: "Return type strings of all cards" }
    ]
  },
  "lurek.cardgame.newCardPool": {
    typeName: "CardPool",
    fields: [
      { name: "name", type: "string", desc: "Pool name" }
    ],
    methods: [
      { name: "add", sig: ":add(card_type, weight)", desc: "Add a card type with weight (default 1)" },
      { name: "remove", sig: ":remove(card_type)", desc: "Remove a card type from pool" },
      { name: "draw", sig: ":draw(n)", desc: "Draw n cards (with replacement), returns type names" },
      { name: "size", sig: ":size()", desc: "Number of entries" },
      { name: "getTypes", sig: ":getTypes()", desc: "Returns all card types in pool" },
      { name: "totalWeight", sig: ":totalWeight()", desc: "Total weight of all entries" }
    ]
  },
  // ── entity types ──────────────────────────────────────────
  "lurek.entity.new": {
    typeName: "Entity",
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
      { name: "type", sig: ":type()", desc: "Returns 'Entity'" }
    ]
  },
  // ── timer types ───────────────────────────────────────────
  "lurek.timer.after": {
    typeName: "Timer",
    methods: [
      { name: "cancel", sig: ":cancel()", desc: "Cancel the timer" },
      { name: "pause", sig: ":pause()", desc: "Pause the timer" },
      { name: "resume", sig: ":resume()", desc: "Resume the timer" },
      { name: "isActive", sig: ":isActive()", desc: "Returns true if still active" },
      { name: "type", sig: ":type()", desc: "Returns 'Timer'" }
    ]
  },
  "lurek.timer.every": {
    typeName: "Timer",
    methods: [
      { name: "cancel", sig: ":cancel()", desc: "Cancel the timer" },
      { name: "pause", sig: ":pause()", desc: "Pause the timer" },
      { name: "resume", sig: ":resume()", desc: "Resume the timer" },
      { name: "isActive", sig: ":isActive()", desc: "Returns true if still active" },
      { name: "type", sig: ":type()", desc: "Returns 'Timer'" }
    ]
  },
  "lurek.timer.tween": {
    typeName: "Tween",
    methods: [
      { name: "cancel", sig: ":cancel()", desc: "Cancel the tween" },
      { name: "pause", sig: ":pause()", desc: "Pause the tween" },
      { name: "resume", sig: ":resume()", desc: "Resume the tween" },
      { name: "isActive", sig: ":isActive()", desc: "Returns true if still active" },
      { name: "getProgress", sig: ":getProgress()", desc: "Returns progress 0-1" },
      { name: "type", sig: ":type()", desc: "Returns 'Tween'" }
    ]
  },
  // ── tilemap types ─────────────────────────────────────────
  "lurek.tilemap.load": {
    typeName: "Tilemap",
    methods: [
      { name: "draw", sig: ":draw()", desc: "Draw the tilemap" },
      { name: "getWidth", sig: ":getWidth()", desc: "Returns width in tiles" },
      { name: "getHeight", sig: ":getHeight()", desc: "Returns height in tiles" },
      { name: "getTileAt", sig: ":getTileAt(x, y)", desc: "Get tile at grid position" },
      { name: "setTileAt", sig: ":setTileAt(x, y, tile)", desc: "Set tile at grid position" },
      { name: "getLayer", sig: ":getLayer(name)", desc: "Get layer by name" },
      { name: "getLayerCount", sig: ":getLayerCount()", desc: "Returns number of layers" },
      { name: "getProperty", sig: ":getProperty(name)", desc: "Get map property" },
      { name: "type", sig: ":type()", desc: "Returns 'Tilemap'" }
    ]
  },
  // ── scene types ───────────────────────────────────────────
  "lurek.scene.new": {
    typeName: "Scene",
    methods: [
      { name: "enter", sig: ":enter()", desc: "Called when scene becomes active" },
      { name: "exit", sig: ":exit()", desc: "Called when scene is deactivated" },
      { name: "update", sig: ":update(dt)", desc: "Update scene" },
      { name: "draw", sig: ":draw()", desc: "Draw scene" },
      { name: "getName", sig: ":getName()", desc: "Returns scene name" },
      { name: "type", sig: ":type()", desc: "Returns 'Scene'" }
    ]
  },
  // ── data types ────────────────────────────────────────────
  "lurek.data.newStore": {
    typeName: "DataStore",
    methods: [
      { name: "get", sig: ":get(key)", desc: "Get value by key" },
      { name: "set", sig: ":set(key, value)", desc: "Set a key-value pair" },
      { name: "delete", sig: ":delete(key)", desc: "Delete a key" },
      { name: "has", sig: ":has(key)", desc: "Returns true if key exists" },
      { name: "keys", sig: ":keys()", desc: "Returns all keys" },
      { name: "values", sig: ":values()", desc: "Returns all values" },
      { name: "clear", sig: ":clear()", desc: "Remove all entries" },
      { name: "size", sig: ":size()", desc: "Returns number of entries" },
      { name: "type", sig: ":type()", desc: "Returns 'DataStore'" }
    ]
  },
  // ── event types ───────────────────────────────────────────
  "lurek.event.on": {
    typeName: "EventHandle",
    methods: [
      { name: "cancel", sig: ":cancel()", desc: "Unsubscribe from event" },
      { name: "type", sig: ":type()", desc: "Returns 'EventHandle'" }
    ]
  },
  // ── camera types ──────────────────────────────────────────
  "lurek.camera.new": {
    typeName: "Camera",
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
      { name: "type", sig: ":type()", desc: "Returns 'Camera'" }
    ]
  }
};
var LUREK_MODULES = [
  "graphics",
  "audio",
  "physics",
  "input",
  "timer",
  "filesystem",
  "compute",
  "data",
  "image",
  "entity",
  "window",
  "thread",
  "animation",
  "camera",
  "automation",
  "event",
  "math",
  "particle",
  "tilemap",
  "scene",
  "savegame",
  "modding",
  "graph",
  "pathfinding",
  "ai",
  "dataframe",
  "gui",
  "minimap",
  "overlay",
  "postfx",
  "terminal",
  "cardgame",
  "tween"
];
function scanDocument(document) {
  const varTypes = [];
  const classes = [];
  const moduleAliases = [];
  const classMap = /* @__PURE__ */ new Map();
  const text = document.getText();
  const lines = text.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const factoryMatch = line.match(
      /\blocal\s+(\w+)\s*=\s*(lurek\.\w+\.\w+)\s*\(/
    );
    if (factoryMatch) {
      const [, varName, factoryCall] = factoryMatch;
      const typeInfo = FACTORY_TYPES[factoryCall];
      if (typeInfo) {
        varTypes.push({ varName, typeName: typeInfo.typeName, factoryCall, line: i });
      }
    }
    const aliasMatch = line.match(
      /\blocal\s+(\w+)\s*=\s*(lurek\.(\w+))\s*(?:$|--)/
    );
    if (aliasMatch) {
      const [, varName, modulePath, moduleName] = aliasMatch;
      if (LUREK_MODULES.includes(moduleName)) {
        moduleAliases.push({ varName, modulePath, line: i });
      }
    }
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
          line: i
        });
      }
    }
    const classDefMatch = line.match(
      /\b(?:local\s+)?(\w+)\s*=\s*\{\s*\}/
    );
    if (classDefMatch) {
      const className = classDefMatch[1];
      if (i + 1 < lines.length) {
        const nextLine = lines[i + 1];
        if (nextLine.includes(`${className}.__index`) || nextLine.includes(`__index = ${className}`)) {
          if (!classMap.has(className)) {
            classMap.set(className, { name: className, methods: [], instances: [] });
          }
        }
      }
    }
    const indexMatch = line.match(/\b(\w+)\.__index\s*=\s*\1\b/);
    if (indexMatch) {
      const className = indexMatch[1];
      if (!classMap.has(className)) {
        classMap.set(className, { name: className, methods: [], instances: [] });
      }
    }
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
          desc: `Method of ${className}`
        });
      }
    }
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
    const setmetaMatch = line.match(/\blocal\s+(\w+)\s*=\s*setmetatable\s*\([^,]*,\s*(\w+)\s*\)/) ?? line.match(/\blocal\s+(\w+)\s*=\s*setmetatable\s*\([^,]*,\s*\{[^}]*__index\s*=\s*(\w+)[^}]*\}\s*\)/);
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
function getTypeInfoForVar(varName, position, varTypes, classes) {
  const factoryVar = varTypes.find(
    (v) => v.varName === varName && v.line < position.line
  );
  if (factoryVar) {
    const typeInfo = Object.values(FACTORY_TYPES).find(
      (t) => t.typeName === factoryVar.typeName
    );
    if (typeInfo) return { typeInfo, factoryCall: factoryVar.factoryCall };
  }
  return void 0;
}
function getMethodsForVar(varName, position, varTypes, classes) {
  const factoryVar = varTypes.find(
    (v) => v.varName === varName && v.line < position.line
  );
  if (factoryVar) {
    const typeInfo = Object.values(FACTORY_TYPES).find(
      (t) => t.typeName === factoryVar.typeName
    );
    if (typeInfo) return typeInfo.methods;
  }
  for (const cls of classes) {
    const instance = cls.instances.find(
      (inst) => inst.varName === varName && inst.line < position.line
    );
    if (instance && cls.methods.length > 0) {
      return cls.methods;
    }
  }
  return void 0;
}

// src/test/mocks/vscode.ts
var MockPosition = class _MockPosition {
  constructor(line, character) {
    this.line = line;
    this.character = character;
  }
  translate(lineDelta, charDelta) {
    return new _MockPosition(this.line + lineDelta, this.character + charDelta);
  }
  isEqual(other) {
    return this.line === other.line && this.character === other.character;
  }
};
var MockRange = class _MockRange {
  constructor(start, end) {
    this.start = start;
    this.end = end;
  }
  static fromLineChar(startLine, startChar, endLine, endChar) {
    return new _MockRange(
      new MockPosition(startLine, startChar),
      new MockPosition(endLine, endChar)
    );
  }
};
var MockTextDocument = class {
  uri = { fsPath: "/mock/test.lua", scheme: "file" };
  fileName;
  languageId = "lua";
  version = 1;
  isDirty = false;
  isUntitled = false;
  eol = 1;
  // LF
  lines;
  constructor(content, fileName = "/mock/test.lua") {
    this.lines = content.split("\n");
    this.fileName = fileName;
    this.uri = { fsPath: fileName, scheme: "file" };
  }
  get lineCount() {
    return this.lines.length;
  }
  lineAt(lineOrPos) {
    const lineNum = typeof lineOrPos === "number" ? lineOrPos : lineOrPos.line;
    const text = this.lines[lineNum] ?? "";
    return {
      text,
      range: MockRange.fromLineChar(lineNum, 0, lineNum, text.length)
    };
  }
  getText(range) {
    if (!range) {
      return this.lines.join("\n");
    }
    if (range.start.line === range.end.line) {
      return (this.lines[range.start.line] ?? "").substring(
        range.start.character,
        range.end.character
      );
    }
    const result = [];
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
  positionAt(offset) {
    let remaining = offset;
    for (let i = 0; i < this.lines.length; i++) {
      if (remaining <= this.lines[i].length) {
        return new MockPosition(i, remaining);
      }
      remaining -= this.lines[i].length + 1;
    }
    const lastLine = this.lines.length - 1;
    return new MockPosition(lastLine, this.lines[lastLine]?.length ?? 0);
  }
  offsetAt(position) {
    let offset = 0;
    for (let i = 0; i < position.line && i < this.lines.length; i++) {
      offset += this.lines[i].length + 1;
    }
    offset += position.character;
    return offset;
  }
  getWordRangeAtPosition(position, regex) {
    const line = this.lines[position.line] ?? "";
    const pattern = regex ?? /\w+/g;
    let match;
    const searchRegex = new RegExp(pattern.source, "g");
    while ((match = searchRegex.exec(line)) !== null) {
      const start = match.index;
      const end = start + match[0].length;
      if (start <= position.character && position.character <= end) {
        return MockRange.fromLineChar(
          position.line,
          start,
          position.line,
          end
        );
      }
    }
    return void 0;
  }
};

// src/test/unit/typeInference.test.ts
suite("TypeInference \u2014 FACTORY_TYPES registry", () => {
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
  test("contains Entity type from lurek.entity.new", () => {
    assert.ok(FACTORY_TYPES["lurek.entity.new"]);
    assert.strictEqual(FACTORY_TYPES["lurek.entity.new"].typeName, "Entity");
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
suite("TypeInference \u2014 scanDocument", () => {
  test("detects local var from lurek.graphics.newCanvas", () => {
    const doc = new MockTextDocument(
      'local canvas = lurek.graphics.newCanvas(100, 100)\ncanvas:setFilter("nearest")'
    );
    const result = scanDocument(doc);
    assert.strictEqual(result.varTypes.length, 1);
    assert.strictEqual(result.varTypes[0].varName, "canvas");
    assert.strictEqual(result.varTypes[0].typeName, "Canvas");
    assert.strictEqual(result.varTypes[0].factoryCall, "lurek.graphics.newCanvas");
  });
  test("detects local var from lurek.graphics.newImage", () => {
    const doc = new MockTextDocument(
      'local img = lurek.graphics.newImage("player.png")'
    );
    const result = scanDocument(doc);
    assert.strictEqual(result.varTypes.length, 1);
    assert.strictEqual(result.varTypes[0].varName, "img");
    assert.strictEqual(result.varTypes[0].typeName, "Image");
  });
  test("detects multiple variables in one document", () => {
    const doc = new MockTextDocument(
      [
        'local img = lurek.graphics.newImage("player.png")',
        "local canvas = lurek.graphics.newCanvas(800, 600)",
        'local font = lurek.graphics.newFont("font.ttf", 16)'
      ].join("\n")
    );
    const result = scanDocument(doc);
    assert.strictEqual(result.varTypes.length, 3);
    const names = result.varTypes.map((v) => v.varName);
    assert.ok(names.includes("img"));
    assert.ok(names.includes("canvas"));
    assert.ok(names.includes("font"));
  });
  test("detects module alias like local gfx = lurek.graphics", () => {
    const doc = new MockTextDocument("local gfx = lurek.graphics\n");
    const result = scanDocument(doc);
    assert.strictEqual(result.moduleAliases.length, 1);
    assert.strictEqual(result.moduleAliases[0].alias, "gfx");
    assert.strictEqual(result.moduleAliases[0].module, "lurek.graphics");
  });
  test("detects factory call via module alias", () => {
    const doc = new MockTextDocument(
      [
        "local gfx = lurek.graphics",
        'local img = gfx.newImage("sprite.png")'
      ].join("\n")
    );
    const result = scanDocument(doc);
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
        "end"
      ].join("\n")
    );
    const result = scanDocument(doc);
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
        'local p = Player:new("hero")'
      ].join("\n")
    );
    const result = scanDocument(doc);
    assert.strictEqual(result.classes.length, 1);
    assert.ok(result.classes[0].instances.length >= 1);
    assert.strictEqual(result.classes[0].instances[0].varName, "p");
  });
  test("detects re-assignment from another variable", () => {
    const doc = new MockTextDocument(
      [
        'local img = lurek.graphics.newImage("sprite.png")',
        "local copy = img"
      ].join("\n")
    );
    const result = scanDocument(doc);
    const copyVar = result.varTypes.find((v) => v.varName === "copy");
    assert.ok(copyVar, "copy should have been detected via re-assignment");
    assert.strictEqual(copyVar.typeName, "Image");
  });
  test("ignores lines without factory patterns", () => {
    const doc = new MockTextDocument(
      [
        "local x = 42",
        'local name = "hello"',
        "local tbl = {}"
      ].join("\n")
    );
    const result = scanDocument(doc);
    assert.strictEqual(result.varTypes.length, 0);
    assert.strictEqual(result.classes.length, 0);
    assert.strictEqual(result.moduleAliases.length, 0);
  });
});
suite("TypeInference \u2014 getTypeInfoForVar", () => {
  test("returns TypeInfo for a factory-typed variable", () => {
    const varTypes = [
      { varName: "canvas", typeName: "Canvas", line: 0, factoryCall: "lurek.graphics.newCanvas" }
    ];
    const pos = new MockPosition(5, 0);
    const result = getTypeInfoForVar("canvas", pos, varTypes, []);
    assert.ok(result);
    assert.strictEqual(result.typeInfo.typeName, "Canvas");
    assert.strictEqual(result.factoryCall, "lurek.graphics.newCanvas");
  });
  test("returns undefined for unknown variable", () => {
    const result = getTypeInfoForVar("unknown", new MockPosition(5, 0), [], []);
    assert.strictEqual(result, void 0);
  });
  test("only considers variables declared before the cursor", () => {
    const varTypes = [
      { varName: "canvas", typeName: "Canvas", line: 10, factoryCall: "lurek.graphics.newCanvas" }
    ];
    const result = getTypeInfoForVar("canvas", new MockPosition(5, 0), varTypes, []);
    assert.strictEqual(result, void 0);
  });
});
suite("TypeInference \u2014 getMethodsForVar", () => {
  test("returns methods for factory-typed variable", () => {
    const varTypes = [
      { varName: "img", typeName: "Image", line: 0, factoryCall: "lurek.graphics.newImage" }
    ];
    const methods = getMethodsForVar("img", new MockPosition(5, 0), varTypes, []);
    assert.ok(methods);
    assert.ok(methods.length > 0);
    const names = methods.map((m) => m.name);
    assert.ok(names.includes("getWidth"));
  });
  test("returns methods for OOP class instance", () => {
    const classes = [
      {
        name: "Enemy",
        methods: [
          { name: "attack", snippet: "attack()", documentation: "Attack!" },
          { name: "flee", snippet: "flee()", documentation: "Run away!" }
        ],
        instances: [{ varName: "boss", line: 10 }]
      }
    ];
    const methods = getMethodsForVar("boss", new MockPosition(15, 0), [], classes);
    assert.ok(methods);
    assert.strictEqual(methods.length, 2);
    const names = methods.map((m) => m.name);
    assert.ok(names.includes("attack"));
    assert.ok(names.includes("flee"));
  });
  test("returns undefined for unrecognised variable", () => {
    const methods = getMethodsForVar("foo", new MockPosition(5, 0), [], []);
    assert.strictEqual(methods, void 0);
  });
});
//# sourceMappingURL=typeInference.test.js.map
