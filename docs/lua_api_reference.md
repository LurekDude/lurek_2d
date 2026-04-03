# Luna2D Audio API Reference

## luna.audio.create_bus(name)
Creates a new audio bus for applying shared volume, pitch, and effects to a group of sources.
- **Parameters**: 
ame (string)
- **Returns**: None

## luna.audio.add_effect(bus_name, effect_id, effect_type)
Adds a real-time DSP effect to the specified bus.
- **Parameters**:
  - us_name (string): The bus to apply the effect to.
  - effect_id (number): A unique identifier for this effect instance.
  - effect_type (string): The type of effect (e.g., "Lowpass", "Reverb").
- **Returns**: None

## luna.audio.remove_effect(bus_name, effect_id)
Removes an effect from the specified bus.
- **Parameters**:
  - us_name (string)
  - effect_id (number)
- **Returns**: None

## luna.audio.set_effect_param(bus_name, effect_id, param_index, value)
Updates a parameter of an active DSP effect.
- **Parameters**:
  - us_name (string)
  - effect_id (number)
  - param_index (number)
  - alue (number)
- **Returns**: None

## luna.audio.play(sound_name, [options])
Plays a sound. 
- **Options**:
  - us: (string) The name of the bus to route this sound through.
  - olume, pitch, loop, ade_in.
---

## luna.postfx — ImageEffect API

`ImageEffect` chains one or more built-in shader passes and applies them to a
single drawable at draw time. Unlike `PostFxStack` (which captures a
full-screen render pass), `ImageEffect` is attached directly to individual
`luna.graphics.draw` calls via the `effect` key of the options-table overload.

### Factory Functions

#### luna.postfx.newImageEffect()

Creates an empty `ImageEffect` chain with no passes.

- **Returns**: `ImageEffect`

#### luna.postfx.newImageEffect(effect_name)

Creates an `ImageEffect` pre-loaded with a single built-in effect.

- **Parameters**:
  - `effect_name` (string): One of `"blur"`, `"vignette"`, `"bloom"`,
    `"crt"`, `"godrays"`, `"colourgrade"`, `"chromatic"`, `"pixelate"`,
    `"sepia"`, `"grayscale"`, `"invert"`, `"scanlines"`, `"edgedetect"`,
    `"hueshift"`, `"noise"`.
- **Returns**: `ImageEffect`

#### luna.postfx.newImageEffect(effect_name, params)

Creates an `ImageEffect` with a single built-in effect and initial float
parameters.

- **Parameters**:
  - `effect_name` (string): Built-in effect name.
  - `params` (table): Key-value pairs of `string → number` parameter overrides.
- **Returns**: `ImageEffect`

#### luna.postfx.newImageEffect(chain_table)

Creates an `ImageEffect` from a structured chain table. Each entry must be a
table with a `type` string key and an optional `params` sub-table.

```lua
local fx = luna.postfx.newImageEffect({
  { type = "blur",     params = { radius = 3 } },
  { type = "vignette", params = { strength = 0.6 } },
})
```

- **Parameters**:
  - `chain_table` (table): Array of `{ type = string, params = table? }` entries.
- **Returns**: `ImageEffect`

#### luna.postfx.loadImageEffect(path)

Loads an `ImageEffect` chain from a TOML preset file.

The TOML file must have a `name` string key and an `[[effects]]` array where
each entry has `type` (string), `enabled` (boolean), and optional float
parameter keys.

- **Parameters**:
  - `path` (string): Path to the `.toml` preset file.
- **Returns**: `ImageEffect`

---

### ImageEffect Methods

#### fx:addEffect(effect_name) → PostFxEffect

Appends a built-in effect to the end of the chain and returns it.

- **Parameters**:
  - `effect_name` (string): Built-in effect name.
- **Returns**: `PostFxEffect` — the new effect (configure with `setParameter`).

#### fx:getEffect(index_or_name) → PostFxEffect | nil

Returns the effect at a 1-based index or matching the given type name.

- **Parameters**:
  - `index_or_name` (integer | string): 1-based position or effect type name.
- **Returns**: `PostFxEffect | nil`

#### fx:effectCount() → integer

Returns the number of effects currently in the chain.

- **Returns**: `integer`

#### fx:removeEffect(index_or_name) → boolean

Removes the effect at a 1-based index or matching the given type name.

- **Parameters**:
  - `index_or_name` (integer | string): 1-based position or effect type name.
- **Returns**: `boolean` — `true` if a matching effect was found and removed.

#### fx:clearEffects()

Removes all effects from the chain.

#### fx:clone() → ImageEffect

Returns a deep clone of this `ImageEffect`. The returned chain shares no state
with the original.

- **Returns**: `ImageEffect`

#### fx:save(path)

Serialises this effect chain to a TOML preset file (readable by
`luna.postfx.loadImageEffect`).

- **Parameters**:
  - `path` (string): Destination file path.

---

### Using ImageEffect with luna.graphics.draw

The `effect` key in the options-table overload of `luna.graphics.draw` accepts
an `ImageEffect`. Effects are applied at draw time to that image only.

```lua
local fx = luna.postfx.newImageEffect("blur", { radius = 4 })

function luna.draw()
  luna.graphics.draw(myImage, {
    x = 100, y = 200,
    sx = 2,  sy = 2,
    effect = fx,
  })
end
```

The `effect` field is supported only with the options-table overload, not the
positional-argument form (`luna.graphics.draw(img, x, y)`).

**Options-table fields for `luna.graphics.draw`:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `x` | number | `0` | Destination X position |
| `y` | number | `0` | Destination Y position |
| `r` | number | `0` | Rotation in radians |
| `sx` | number | `1` | X scale factor |
| `sy` | number | `sx` | Y scale factor (defaults to `sx`) |
| `ox` | number | `0` | X origin offset |
| `oy` | number | `0` | Y origin offset |
| `effect` | ImageEffect | `nil` | Per-image shader effect chain |