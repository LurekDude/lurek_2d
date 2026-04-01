---
name: numerical-computing
description: "Load this skill when working with Luna2D NdArray dense arrays: creation, element-wise ops, reductions, spatial operations (convolution, pooling, distance transforms), or DataType selection. Skip it for Lua tables, DataFrame, or graph structures."
---

# Numerical Computing — Luna2D Engine

## Load When

- Creating or manipulating NdArray dense arrays
- Performing element-wise operations (add, subtract, multiply)
- Running reductions (sum, mean, min, max)
- Applying spatial operations (convolution, pooling, distance transforms)
- Choosing DataType (float32, float64, int32)
- Using `luna.compute.*` API functions

## Owns

- `src/compute/` module — NdArray and operations
- `src/lua_api/compute_api.rs` — `luna.compute.*` Lua bindings

## Does Not Cover

- DataFrame column operations → separate dataframe module
- Lua table manipulation → use `lua-scripting` skill
- GPU compute → wgpu compute shaders (not available in Luna2D)
- Graph algorithms → use `graph-systems` skill

## Live Repository Contracts

- `src/compute/array.rs` — `NdArray` core struct, shape, strides, indexing
- `src/compute/ops.rs` — element-wise and reduction operations
- `src/compute/spatial.rs` — convolution, pooling, distance transforms
- `tests/compute_tests.rs` — helpers `arr_1d()`, `arr_2d()`

## Key Types

| Type | Purpose |
|---|---|
| `NdArray` | N-dimensional dense array (NumPy-style) |
| `DataType` | Element type: `Float32`, `Float64`, `Int32` |

## Decision Rules

- **NdArray is row-major** — C-style memory layout, last dimension varies fastest
- **DataType selection**: Float32 for game math, Float64 for precision, Int32 for indices
- **Shape is immutable after creation** — reshape creates a new view, not in-place
- **Element access by flat index or multi-dim coordinates** — both supported
- **Spatial operations need 2D arrays** — convolution, pooling operate on 2D grids
- **All operations are CPU-bound** — no GPU acceleration; use Workers for large arrays

## Best Practices

- Use `Float32` for most game computations — sufficient precision, half the memory
- Pre-allocate arrays of known size — avoid repeated resizing
- Use spatial operations for influence maps, heightfields, and procedural generation
- Float comparisons in tests: `(a - b).abs() < 1e-5`
- Use reductions (sum, mean) instead of manual element iteration

## Anti-Patterns

- **Wrong DataType**: Using Float64 when Float32 suffices — wastes memory
- **Element-by-element loops**: Iterating elements in Lua instead of using vectorized ops
- **Large arrays on main thread**: Processing huge NdArrays in `luna.update()` — use Workers
- **Ignoring shape constraints**: Attempting spatial ops on 1D arrays — requires 2D
