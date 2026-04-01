# `src/compute/` — N-Dimensional Array Computing

## Purpose

The compute module exposes data-parallel computation to Lua scripts for work
that would block the game loop if run naively on the main thread in a single
frame.  It provides an `NdArray` N-dimensional numeric array that supports
vectorised arithmetic, matrix operations, and statistical aggregations over
large datasets without marshalling data through Lua value iteration.  For
massively parallel numeric work a GPU compute path via wgpu compute shaders
runs the full pipeline entirely on the GPU.

Typical use cases include procedural terrain height-map generation (applying
noise functions to grids of thousands of cells in parallel), batch distance
field computation for large-scale AI pathfinding preprocessing, real-time
simulation of physical systems (spring networks, heat diffusion) at scales
that would drop below target frame rate if processed sequentially in Lua, and
offline data preprocessing steps embedded in the game's level-loading stage.

The CPU path operates on contiguous `Vec<f64>` storage so that Rust-level
loops benefit from SIMD auto-vectorisation without requiring any unsafe code or
explicit intrinsic calls.  The GPU path offloads arbitrarily large datasets to
a wgpu compute pipeline, uploads the input buffer, dispatches with the
appropriate workgroup count, and reads results back synchronously via
`pollster::block_on` — appropriate for one-off heavy computations, not
per-frame streaming.

## Architecture

```
NdArray (core container)
  │
  ├── DataType ── Float32 | Float64 | Int32
  │     └── Raw storage: Vec<u8> with type-aware access
  │
  ├── ops.rs ── 50+ pure functions
  │     ├── Arithmetic ── add, sub, mul, div, pow, negate, abs, sqrt
  │     ├── Comparison ── eq, ne, lt, gt, le, ge (return Float32 0|1)
  │     ├── Reductions ── sum, mean, min, max, argmin, argmax
  │     │     └── Global or per-axis variants
  │     ├── Shape ── reshape, transpose, flatten, squeeze, expand_dims
  │     └── Bitwise ── and, or, xor, not (Int32 only)
  │
  └── spatial.rs ── spatial/matrix operations
        ├── convolve2d ── 2D convolution with kernel
        ├── dilate / erode ── morphological operations
        ├── flood_fill ── region filling
        ├── get_region / set_region ── sub-array access
        ├── matmul ── matrix multiplication
        └── dot ── dot product
```

### How It Works

`NdArray` stores data as a flat `Vec<f64>` alongside a `Vec<usize>` shape.
All index access uses a computed stride: `index = sum(coord[i] * stride[i])`.
Operations that produce a new array (element-wise add, matmul, reshape)
allocate a fresh `Vec<f64>` rather than mutating in-place, matching functional
pipelines common in data-processing code.

Reduction operations (sum, mean, max, argmax, std) are implemented as
fold loops in Rust and therefore never cross the Lua boundary per element —
a 1 000 000-element sum is a single Rust call, not a million Lua steps.

The GPU compute path creates a `wgpu::ComputePipeline` from user WGSL and
binds input/output buffers as storage buffers in bind group 0.  After
dispatch, `wgpu::Buffer::slice(..).map_async(MapMode::Read)` reads back the
result.  The synchronous wrapper is intentional: compute shaders in Luna2D
are designed for heavy one-shot work (level generation, baked lighting) where
blocking for a few milliseconds is acceptable.

### Dependency Direction

```
compute/ ──────► (none)
```

**Leaf module** — zero Luna2D dependencies. Pure Rust numeric operations.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports `NdArray`, `DataType`, and all operation functions.

**~12 lines** — pure re-exports.

---

### `array.rs` — `NdArray` (Core Container)

**~398 lines** | N-dimensional array with typed raw byte storage.

#### Struct: `NdArray`

```rust
pub struct NdArray {
    shape: Vec<usize>,
    strides: Vec<usize>,
    dtype: DataType,
    data: Vec<u8>,
}
```

#### Enum: `DataType`

`Float32 | Float64 | Int32`

#### Constraints

| Constraint | Value |
|-----------|-------|
| Max dimensions | 3 (1D, 2D, 3D) |
| Max elements | 268,435,456 (256M) |
| Storage | Contiguous `Vec<u8>` with `DataType`-aware byte offsets |

Methods: `new`, `zeros`, `ones`, `from_vec`, `get`/`set` (multi-dimensional index),
`shape`, `ndim`, `len`, `dtype`, `as_f32_vec`, `as_f64_vec`, `as_i32_vec`.

**Design**: Raw `Vec<u8>` storage with stride-based indexing allows type-generic
operations without generics — keeps the Lua FFI boundary simple.

---

### `ops.rs` — Array Operations

**~841 lines** | 50+ pure functions operating on `NdArray` values.

#### Operation Categories

| Category | Functions | Notes |
|----------|-----------|-------|
| Arithmetic | `add`, `sub`, `mul`, `div`, `pow`, `negate`, `abs`, `sqrt` | Element-wise, broadcasting |
| Comparison | `eq`, `ne`, `lt`, `gt`, `le`, `ge` | Returns Float32 array (0.0/1.0) |
| Reduction (global) | `sum`, `mean`, `min`, `max`, `argmin`, `argmax` | Single scalar result |
| Reduction (axis) | `sum_axis`, `mean_axis`, `min_axis`, `max_axis` | Reduce one dimension |
| Shape | `reshape`, `transpose`, `flatten`, `squeeze`, `expand_dims` | View/copy operations |
| Bitwise | `bitand`, `bitor`, `bitxor`, `bitnot` | Int32 only |
| Clamp | `clamp`, `clip` | Value range limiting |
| Trig | `sin`, `cos`, `exp`, `log` | Element-wise |

**Design**: All operations produce new arrays (immutable semantics). No in-place
mutation from the public API — simplifies Lua ownership and prevents aliasing bugs.

---

### `spatial.rs` — Spatial and Matrix Operations

**~412 lines** | Operations requiring 2D spatial awareness.

| Function | Purpose | Notes |
|----------|---------|-------|
| `convolve2d(array, kernel)` | 2D convolution | Zero-padding, arbitrary kernel size |
| `dilate(array, kernel)` | Morphological dilation | Binary structuring element |
| `erode(array, kernel)` | Morphological erosion | Binary structuring element |
| `flood_fill(array, x, y, val)` | Region filling | 4-connected BFS |
| `get_region(array, x, y, w, h)` | Extract sub-array | Bounds-checked |
| `set_region(array, x, y, region)` | Paste sub-array | Bounds-checked |
| `matmul(a, b)` | Matrix multiplication | 2D arrays only |
| `dot(a, b)` | Dot product | 1D arrays |

---

## Cross-Cutting Concerns

### Error Handling

Shape mismatches and type mismatches return descriptive error strings. Operations
on incompatible arrays fail explicitly rather than silently broadcasting.

### Lua Integration

The Lua bridge lives in `src/lua_api/compute_api.rs` (~380 lines), exposing the
`NdArray` as a UserData type under `luna.compute.*`.

### Usage from Lua

```lua
-- Create arrays
local a = luna.compute.zeros({3, 3}, "float32")
local b = luna.compute.ones({3, 3}, "float32")

-- Arithmetic
local c = luna.compute.add(a, b)

-- Matrix operations
local result = luna.compute.matmul(a, b)

-- Reductions
local total = luna.compute.sum(c)
```
