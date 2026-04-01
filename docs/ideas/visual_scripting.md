# luna.scripting — Visual Block-Based Scripting

> **Lua namespace:** `luna.scripting`
> **C++ module:** `src/modules/scripting/`
> **Purpose:** Visual node-based scripting system for creating game logic, event handlers, and data flows through interconnected blocks. Supports execution of block graphs, runtime compilation to Lua, and visual editing integration.

## Reimplementation Notes

- **Recommended strategy**: **Pure Lua** reimplementation — block graph is a data structure with Lua function execution
- Blocks are nodes in a directed acyclic graph (DAG). Each block has typed input/output ports
- Connections link an output port of one block to an input port of another
- Port types: `"flow"` (execution order), `"number"`, `"string"`, `"boolean"`, `"any"`, `"table"`
- Flow ports define execution order; data ports pass values
- Canvas is the visual container and coordinate system for blocks
- Compiler traverses the graph and generates equivalent Lua source code
- Blocks can be custom-defined with Lua callbacks (`onExecute`)
- All port indices are **1-based** in the Lua API
- Block positions are in canvas-space coordinates (not screen-space)
- Circular connections are rejected — the graph must remain a DAG

## Dependencies

- `engine::Object` base (reference counted)
- No external library dependencies

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newCanvas` | `width?: number, height?: number` | `Canvas` | Create a visual scripting canvas (default 4000×4000) |
| `newBlock` | `type: string, label?: string` | `Block` | Create a block of a given type |
| `newCompiler` | — | `Compiler` | Create a graph-to-Lua compiler |
| `defineBlockType` | `typeName: string, definition: table` | — | Register a custom block type |
| `getBlockType` | `typeName: string` | `table \| nil` | Get a registered block type definition |
| `getBlockTypeNames` | — | `{string, ...}` | Get all registered block type names |
| `clearBlockTypes` | — | — | Remove all custom block type definitions |

### Built-In Block Types

| Type Name | Category | Inputs | Outputs | Description |
|---|---|---|---|---|
| `"start"` | Flow | — | flow | Entry point of execution |
| `"end"` | Flow | flow | — | End of execution chain |
| `"branch"` | Flow | flow, condition:boolean | flow_true, flow_false | Conditional branch |
| `"loop"` | Flow | flow, count:number | flow_body, flow_done, index:number | Loop N times |
| `"while"` | Flow | flow, condition:boolean | flow_body, flow_done | While loop |
| `"sequence"` | Flow | flow | flow_1, flow_2, flow_3 | Execute multiple flows in sequence |
| `"delay"` | Flow | flow, seconds:number | flow_done | Wait before continuing |
| `"print"` | Action | flow, message:any | flow | Print to console |
| `"set_var"` | Action | flow, name:string, value:any | flow | Set a variable |
| `"get_var"` | Data | name:string | value:any | Get a variable |
| `"add"` | Math | a:number, b:number | result:number | Addition |
| `"subtract"` | Math | a:number, b:number | result:number | Subtraction |
| `"multiply"` | Math | a:number, b:number | result:number | Multiplication |
| `"divide"` | Math | a:number, b:number | result:number | Division (safe, returns 0 for /0) |
| `"modulo"` | Math | a:number, b:number | result:number | Modulo |
| `"negate"` | Math | value:number | result:number | Negation |
| `"abs"` | Math | value:number | result:number | Absolute value |
| `"min"` | Math | a:number, b:number | result:number | Minimum |
| `"max"` | Math | a:number, b:number | result:number | Maximum |
| `"clamp"` | Math | value:number, min:number, max:number | result:number | Clamp to range |
| `"random"` | Math | min:number, max:number | result:number | Random number |
| `"number"` | Constant | — | value:number | Number literal |
| `"string"` | Constant | — | value:string | String literal |
| `"boolean"` | Constant | — | value:boolean | Boolean literal |
| `"and"` | Logic | a:boolean, b:boolean | result:boolean | Logical AND |
| `"or"` | Logic | a:boolean, b:boolean | result:boolean | Logical OR |
| `"not"` | Logic | value:boolean | result:boolean | Logical NOT |
| `"equal"` | Compare | a:any, b:any | result:boolean | Equality |
| `"not_equal"` | Compare | a:any, b:any | result:boolean | Inequality |
| `"greater"` | Compare | a:number, b:number | result:boolean | Greater than |
| `"less"` | Compare | a:number, b:number | result:boolean | Less than |
| `"concat"` | String | a:string, b:string | result:string | String concatenation |
| `"length"` | String | value:string | result:number | String length |
| `"to_string"` | Convert | value:any | result:string | Convert to string |
| `"to_number"` | Convert | value:string | result:number | Convert to number |
| `"lua_eval"` | Custom | flow, code:string | flow, result:any | Execute Lua code string (sandboxed) |
| `"lua_function"` | Custom | flow, args:table | flow, result:any | Call a registered Lua function |
| `"comment"` | Meta | — | — | Visual comment block (no execution) |

---

## Type: Block

A single node in the visual script graph with typed input/output ports.

**Created by:** `luna.scripting.newBlock(type, label?)`

### Identity

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getType` | — | `string` | Get block type name |
| `getLabel` | — | `string` | Get display label |
| `setLabel` | `label: string` | — | Set display label |
| `getId` | — | `number` | Get unique block ID |
| `getCategory` | — | `string` | Get block category (from type definition) |

### Ports

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getInputCount` | — | `number` | Number of input ports |
| `getOutputCount` | — | `number` | Number of output ports |
| `getInputPort` | `index: number` | `table` | Get input port info: `{name, type, connected, value}` (1-based) |
| `getOutputPort` | `index: number` | `table` | Get output port info: `{name, type, connected}` (1-based) |
| `getInputByName` | `name: string` | `number \| nil` | Get input port index by name (1-based, nil if not found) |
| `getOutputByName` | `name: string` | `number \| nil` | Get output port index by name (1-based, nil if not found) |
| `setInputDefault` | `index: number, value: any` | — | Set default value for an unconnected input (1-based) |
| `getInputDefault` | `index: number` | `any \| nil` | Get default value for an input (1-based) |

### Custom Ports (for custom block types)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addInput` | `name: string, portType: string` | `number` | Add a custom input port. Returns port index (1-based) |
| `addOutput` | `name: string, portType: string` | `number` | Add a custom output port. Returns port index (1-based) |
| `removeInput` | `index: number` | — | Remove an input port (1-based) |
| `removeOutput` | `index: number` | — | Remove an output port (1-based) |

### Position (for visual layout)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setPosition` | `x: number, y: number` | — | Set canvas-space position |
| `getPosition` | — | `x: number, y: number` | Get canvas-space position |
| `setSize` | `w: number, h: number` | — | Set visual size |
| `getSize` | — | `w: number, h: number` | Get visual size |
| `setColor` | `r: number, g: number, b: number, a?: number` | — | Set block color |
| `getColor` | — | `r, g, b, a` | Get block color |

### Execution

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setOnExecute` | `fn: function \| nil` | — | Set custom execution callback: `fn(inputs) → outputs` |
| `execute` | `inputs: table` | `table` | Execute the block with given inputs. Returns outputs table |
| `setEnabled` | `enabled: boolean` | — | Enable/disable block (disabled blocks are skipped) |
| `isEnabled` | — | `boolean` | Check if block is enabled |

### Metadata

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setData` | `key: string, value: any` | — | Set custom metadata |
| `getData` | `key: string` | `any \| nil` | Get custom metadata |
| `setComment` | `text: string` | — | Set block comment (shown in tooltip) |
| `getComment` | — | `string` | Get block comment |

---

## Type: Canvas

Visual container for blocks and connections. Manages the graph structure, validation, and execution.

**Created by:** `luna.scripting.newCanvas(width?, height?)`

### Block Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addBlock` | `block: Block` | — | Add a block to the canvas |
| `removeBlock` | `block: Block` | — | Remove a block and all its connections |
| `getBlock` | `id: number` | `Block \| nil` | Get block by ID |
| `getBlocks` | — | `{Block, ...}` | Get all blocks |
| `getBlockCount` | — | `number` | Number of blocks |
| `getBlocksByType` | `type: string` | `{Block, ...}` | Get all blocks of a given type |
| `findBlock` | `label: string` | `Block \| nil` | Find first block with matching label |
| `clear` | — | — | Remove all blocks and connections |

### Connections

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `connect` | `fromBlock: Block, outputIndex: number, toBlock: Block, inputIndex: number` | `boolean, string?` | Create a connection (1-based indices). Returns `(ok, error)`. Rejects cycles and type mismatches |
| `disconnect` | `fromBlock: Block, outputIndex: number, toBlock: Block, inputIndex: number` | — | Remove a connection |
| `disconnectAll` | `block: Block` | — | Remove all connections to/from a block |
| `getConnections` | — | `table` | Get all connections: `{{from, outputIndex, to, inputIndex}, ...}` |
| `getConnectionCount` | — | `number` | Number of connections |
| `isConnected` | `fromBlock: Block, outputIndex: number, toBlock: Block, inputIndex: number` | `boolean` | Check if a specific connection exists |
| `getInputConnections` | `block: Block` | `table` | Get all connections feeding into a block |
| `getOutputConnections` | `block: Block` | `table` | Get all connections leaving a block |

### Validation

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `validate` | — | `boolean, table<string>` | Validate the graph (no cycles, no type mismatches, all required inputs connected). Returns `(ok, errors)` |
| `hasCycles` | — | `boolean` | Check for circular connections |
| `getUnconnectedInputs` | — | `table` | Get list of unconnected required inputs |

### Execution

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `execute` | `startBlock?: Block` | `table` | Execute the graph from a start block (or first `"start"` type block). Returns output values |
| `executeStep` | — | `boolean, Block?` | Execute one step. Returns `(hasMore, currentBlock)` for step-by-step debugging |
| `reset` | — | — | Reset execution state |
| `isRunning` | — | `boolean` | Check if execution is in progress |
| `setVariable` | `name: string, value: any` | — | Set a variable accessible by `get_var`/`set_var` blocks |
| `getVariable` | `name: string` | `any \| nil` | Get a variable value |
| `getVariables` | — | `table` | Get all variable names and values |
| `clearVariables` | — | — | Clear all variables |
| `registerFunction` | `name: string, fn: function` | — | Register a Lua function callable by `lua_function` blocks |

### Serialization

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `serialize` | — | `string` | Serialize the entire graph (blocks, connections, positions) to JSON |
| `deserialize` | `json: string` | `boolean, string?` | Load a graph from JSON. Returns `(ok, error)` |
| `exportLua` | `compiler?: Compiler` | `string` | Compile the graph to equivalent Lua source code |

### Layout

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setSize` | `w: number, h: number` | — | Set canvas dimensions |
| `getSize` | — | `w: number, h: number` | Get canvas dimensions |
| `autoLayout` | — | — | Automatically position blocks in a readable arrangement |
| `alignBlocks` | `blocks: {Block,...}, axis: string` | — | Align blocks on `"x"` or `"y"` axis |
| `distributeBlocks` | `blocks: {Block,...}, axis: string, spacing?: number` | — | Evenly distribute blocks |

### Selection (for editor integration)

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getBlockAt` | `x: number, y: number` | `Block \| nil` | Hit test at canvas coordinates |
| `getBlocksInRect` | `x: number, y: number, w: number, h: number` | `{Block, ...}` | Get blocks within a rectangle |
| `selectBlock` | `block: Block` | — | Add block to selection |
| `deselectBlock` | `block: Block` | — | Remove block from selection |
| `getSelection` | — | `{Block, ...}` | Get selected blocks |
| `clearSelection` | — | — | Deselect all blocks |
| `selectAll` | — | — | Select all blocks |
| `deleteSelection` | — | — | Remove all selected blocks |

---

## Type: Compiler

Compiles a block graph into executable Lua source code.

**Created by:** `luna.scripting.newCompiler()`

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `compile` | `canvas: Canvas` | `string, table?` | Compile graph to Lua source. Returns `(code, warnings)` |
| `compileBlock` | `block: Block` | `string` | Compile a single block to Lua |
| `setOptimize` | `enabled: boolean` | — | Enable/disable optimization passes (constant folding, dead code removal) |
| `isOptimize` | — | `boolean` | Check optimization state |
| `setIndent` | `indent: string` | — | Set indentation string (default `"  "`) |
| `setComments` | `enabled: boolean` | — | Include block labels as comments in output |
| `getLastErrors` | — | `table<string>` | Get compilation errors from last compile |

---

## Custom Block Type Definition

```lua
luna.scripting.defineBlockType("custom_health_check", {
    category = "Game",
    label = "Health Check",
    color = {0.8, 0.2, 0.2},
    inputs = {
        { name = "flow", type = "flow" },
        { name = "entity", type = "any" },
        { name = "threshold", type = "number", default = 0 },
    },
    outputs = {
        { name = "flow_alive", type = "flow" },
        { name = "flow_dead", type = "flow" },
        { name = "hp", type = "number" },
    },
    onExecute = function(inputs)
        local hp = inputs.entity.hp or 0
        return {
            hp = hp,
            flow_alive = hp > inputs.threshold,
            flow_dead = hp <= inputs.threshold,
        }
    end,
})
```

---

## Usage Example

```lua
-- Create canvas and blocks
local canvas = luna.scripting.newCanvas()

local start = luna.scripting.newBlock("start", "Begin")
local getVar = luna.scripting.newBlock("get_var", "Get Counter")
getVar:setInputDefault(1, "counter")

local compare = luna.scripting.newBlock("less", "< 10?")
compare:setInputDefault(2, 10)

local branch = luna.scripting.newBlock("branch", "Check")
local printBlock = luna.scripting.newBlock("print", "Say Hello")
printBlock:setInputDefault(2, "Hello World!")

local add = luna.scripting.newBlock("add", "Increment")
add:setInputDefault(2, 1)

local setVar = luna.scripting.newBlock("set_var", "Update Counter")
setVar:setInputDefault(2, "counter")

local loop = luna.scripting.newBlock("start", "Loop Back")
local endBlock = luna.scripting.newBlock("end", "Done")

-- Add to canvas
canvas:addBlock(start)
canvas:addBlock(getVar)
canvas:addBlock(compare)
canvas:addBlock(branch)
canvas:addBlock(printBlock)
canvas:addBlock(add)
canvas:addBlock(setVar)
canvas:addBlock(endBlock)

-- Wire up connections (outputIndex, inputIndex are 1-based)
canvas:connect(start, 1, branch, 1)        -- flow
canvas:connect(getVar, 1, compare, 1)       -- counter value → less.a
canvas:connect(compare, 1, branch, 2)       -- result → branch.condition
canvas:connect(branch, 1, printBlock, 1)    -- flow_true → print.flow
canvas:connect(printBlock, 1, setVar, 1)    -- flow → setVar.flow
canvas:connect(getVar, 1, add, 1)           -- counter → add.a
canvas:connect(add, 1, setVar, 3)           -- incremented → setVar.value
canvas:connect(branch, 2, endBlock, 1)      -- flow_false → end

-- Set initial variable
canvas:setVariable("counter", 0)

-- Validate
local ok, errors = canvas:validate()
if not ok then
    for _, err in ipairs(errors) do print("Error: " .. err) end
end

-- Execute
canvas:execute()

-- Compile to Lua
local compiler = luna.scripting.newCompiler()
compiler:setComments(true)
local code = compiler:compile(canvas)
print(code)

-- Serialize for saving
local json = canvas:serialize()
luna.filesystem.write("my_script.json", json)

-- Load later
local canvas2 = luna.scripting.newCanvas()
canvas2:deserialize(luna.filesystem.read("my_script.json"))
```

---

## Extension Integration

The visual scripting module integrates with two extension panels:

### Graph Editor (`luna2d.editor.graphEditor`)

Used for general-purpose node graphs. See [graph.md](graph.md) for full editor documentation.

- Custom node and edge type definitions with colors and line styles
- Visual canvas with minimap, zoom/pan, and connection mode
- Export to Lua and TOML with typed node/edge arrays

### Scene Flow Editor (`luna2d.editor.sceneFlowEditor`)

Used for scene transition flow graphs. See [scene.md](scene.md) for full editor documentation.

- Draggable scene nodes with transition connections
- Color-coded nodes (start scene, regular, transitions)
- Export to Lua with scene manager boilerplate

### Scripting Canvas Serialization

The `Canvas:serialize()` method produces a JSON string compatible with both editors:

```json
{
    "nodes": [
        { "id": 1, "type": "event", "x": 100, "y": 50, "props": { "name": "onStart" } },
        { "id": 2, "type": "action", "x": 300, "y": 50, "props": { "code": "print('hello')" } }
    ],
    "edges": [
        { "from": 1, "to": 2, "port": "out" }
    ]
}
```

This format can be loaded in either the Graph Editor or programmatically via `Canvas:deserialize()`.
