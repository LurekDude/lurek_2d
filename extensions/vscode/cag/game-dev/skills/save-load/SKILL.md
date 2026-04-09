# Save / Load

Persist game state with versioned TOML saves, migration, autosave, multiple slots, and validation.

## Key Concepts

- **Save structure**: A plain Lua table with a `save_version` field for forward compatibility.
- **TOML encoding**: Use `luna.data.encodeToml` / `luna.data.decodeToml` for human-readable saves.
- **Migration**: On load, check `save_version` and apply transforms to upgrade old saves.
- **Autosave**: Trigger on key events (room change, quest complete) — not every frame.
- **Validation**: After decoding, verify required fields exist before using the data.

## Save Structure

```lua
local function build_save()
    return {
        save_version = 2,
        player = {
            x = player.x, y = player.y,
            hp = player.hp, max_hp = player.max_hp,
            inventory = serialize_inventory(player.inv),
        },
        flags = {
            intro_seen = game.intro_seen,
            boss_defeated = game.boss_defeated,
        },
        world = {
            current_map = game.current_map,
            time_played = game.time_played,
        },
    }
end
```

## Save to File

```lua
local function save_game(slot)
    local data = build_save()
    local toml_str = luna.data.encodeToml(data)
    local path = "saves/slot" .. slot .. ".toml"
    luna.fs.write(path, toml_str)
end
```

## Load from File

```lua
local function load_game(slot)
    local path = "saves/slot" .. slot .. ".toml"
    if not luna.fs.exists(path) then return nil, "no save" end
    local content = luna.fs.read(path)
    local data = luna.data.decodeToml(content)
    if not data or not data.save_version then return nil, "corrupt" end
    data = migrate(data)
    return data
end
```

## Migration

```lua
local function migrate(data)
    if data.save_version < 2 then
        -- v1 → v2: added max_hp field
        data.player.max_hp = data.player.max_hp or 100
        data.save_version = 2
    end
    return data
end
```

## Autosave

```lua
local AUTOSAVE_SLOT = 0

local function autosave()
    save_game(AUTOSAVE_SLOT)
end

-- Call on room transitions, quest completions, etc.
local function enter_room(room_id)
    game.current_map = room_id
    load_room(room_id)
    autosave()
end
```

## Multiple Slots with Metadata

```lua
local function get_slot_info()
    local slots = {}
    for i = 1, 3 do
        local path = "saves/slot" .. i .. ".toml"
        if luna.fs.exists(path) then
            local content = luna.fs.read(path)
            local data = luna.data.decodeToml(content)
            slots[i] = {
                time_played = data.world.time_played,
                map = data.world.current_map,
            }
        end
    end
    return slots
end
```

## Common Pitfalls

- **No save_version** — without it, you can't migrate old saves. Always include it from day one.
- **Saving references** — tables with circular refs or userdata can't be serialized. Flatten to primitives.
- **Overwriting without backup** — write to a temp file first, then rename. Prevents corruption on crash.
- **Loading without validation** — a corrupt or hand-edited file can crash the game. Check required fields.
- **Autosave too often** — saving every frame is wasteful. Trigger on meaningful events only.
- **Forgetting luna.fs sandbox** — saves go to the game's sandboxed directory, not an absolute path.
