# `compute` � Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 � Core Engine Subsystems                      |
| **Status**     | Implemented � Full                                   |
| **Lua API**    | `lurek.compute`                                       |
| **Source**      | `src/compute/`                                       |
| **Rust Tests** | `tests/rust/unit/compute_tests.rs`                   |
| **Lua Tests**  | `tests/lua/unit/test_compute.lua`                    |
| **Architecture** | �                                                  |

## Summary

The compute module provides dense N-dimensional numerical arrays with NumPy-style
operations for Lua game scripts. The core type is `NdArray`, a contiguous byte-buffer
array supporting 1D, 2D, and 3D shapes with three element types: `Float32`, `Float64`,
and `Int32`. Data is stored in row-major order with typed access through `get_f64`/`set_f64`
and `get_i32`/`set_i32` accessors that handle byte-level serialisation internally.

The module is split into three submodules: `array` (core container and constructors),
`ops` (50+ element-wise arithmetic, comparison, reduction, masking, shape manipulation,
and bitwise operations), and `spatial` (2D convolution, morphological operations,
flood fill, region extraction, matrix multiplication, and dot product). All operations
are CPU-side � there is no GPU compute shader path. The CPU path operates on contiguous
`Vec<u8>` storage so that Rust-level loops can benefit from SIMD auto-vectorisation
without requiring any `unsafe` code or explicit intrinsic calls.

Typical use cases include procedural terrain height-map generation, batch distance field
computation for AI pathfinding preprocessing, real-time numerical simulation (spring
networks, heat diffusion) at scales that would drop below target frame rate if processed
sequentially in Lua, and offline data preprocessing during level loading. The module
enforces a hard cap of 268,435,456 elements per array to prevent unbounded allocations.

The compute module is intentionally NOT a general-purpose tensor library � it does not
provide broadcasting, automatic differentiation, or GPU dispatch. For named-column
tabular data, use the `dataframe` module instead.

## Architecture

```
lurek.compute (Lua API)
  -
  �
LuaArray (UserData wrapper)
  -
  �
NdArray (core container � src/compute/array.rs)
  +�� shape: Vec<usize>      (1D / 2D / 3D, max 268M elements)
  +�� strides: Vec<usize>    (row-major, computed from shape)
  +�� dtype: DataType         (Float32 | Float64 | Int32)
  L�� data: Vec<u8>          (contiguous byte buffer)
        -
        +�� ops.rs �� 50+ pure functions ����������������������
        -     +�� Arithmetic �� add, sub, mul, div, pow, neg, abs, sqrt
        -     +�� Scalar ops �� add_scalar, sub_scalar, mul_scalar, etc.
        -     +�� Comparison �� eq, neq, gt, lt, gte, lte (� Float32 0|1)
        -     +�� Masking �� threshold, where_mask, count_nonzero
        -     +�� Predicates �� any, all, argmin, argmax
        -     +�� Reductions �� sum, mean, min_val, max_val (global)
        -     +�� Axis reductions �� sum_axis, mean_axis, min_axis, max_axis
        -     +�� Shape �� reshape, transpose_2d, fill, clone_array
        -     L�� Bitwise �� and, or, xor, not, lshift, rshift (Int32 only)
        -
        L�� spatial.rs �� spatial / linear algebra ������������
              +�� convolve2d �� 2D convolution with zero-padding
              +�� dilate / erode �� morphological ops (Manhattan diamond)
              +�� flood_fill �� BFS 4-connectivity region fill
              +�� get_region / set_region �� rectangular sub-array access
              +�� matmul �� matrix multiplication (m,k)�(k,n)�(m,n)
              L�� dot �� vector dot product
```

## Source Files

| File         | Purpose                                                        |
|--------------|----------------------------------------------------------------|
| `mod.rs`     | Module root; re-exports `NdArray`, `DataType`, submodules      |
| `array.rs`   | Core `NdArray` struct, `DataType` enum, constructors, accessors |
| `ops.rs`     | Element-wise arithmetic, comparison, reduction, shape, bitwise ops |
| `spatial.rs` | 2D convolution, morphology, flood fill, regions, matmul, dot   |

## Submodules

### `compute::array`

Core NdArray container and DataType enum. Provides constructors (`new`, `zeros`,
`ones`, `range`, `from_slice`), element access (`get_f64`, `set_f64`, `get_i32`,
`set_i32`, `get_by_indices`, `set_by_indices`), metadata queries (`shape`, `dtype`,
`size`, `ndim`, `strides`), raw data access (`data`, `data_mut`), and utilities
(`flat_index`, `compute_strides`, `to_f64_vec`, `display_string`).

- **`NdArray`** (struct): Dense N-dimensional numerical array with row-major strides. Stores data as a contiguous `Vec<u8>` byte buffer. Shapes limited to 1�3 dimensions, max 268M elements.
- **`DataType`** (enum): Element data type � `Float32` (4 bytes), `Float64` (8 bytes), `Int32` (4 bytes). Parsed from strings `"float32"` / `"float64"` / `"int32"`.

### `compute::ops`

50+ pure functions for element-wise and aggregate operations on NdArray. All arithmetic
and comparison operations produce new arrays (immutable pattern) except `fill` which
is in-place. Comparison operations always return `Float32` arrays with `0.0`/`1.0` values.

- **`add`**, **`sub`**, **`mul`**, **`div`** (fn): Element-wise binary arithmetic on two same-shape, same-dtype arrays.
- **`add_scalar`**, **`sub_scalar`**, **`mul_scalar`**, **`div_scalar`** (fn): Element-wise arithmetic with a scalar.
- **`pow_scalar`** (fn): Raise every element to a scalar exponent.
- **`sqrt`**, **`abs`**, **`neg`** (fn): Element-wise unary operations.
- **`clamp`** (fn): Clamp every element to `[min_val, max_val]`.
- **`eq`**, **`neq`**, **`gt`**, **`lt`**, **`gte`**, **`lte`** (fn): Element-wise comparison of two arrays; returns Float32 0/1.
- **`eq_scalar`**, **`neq_scalar`**, **`gt_scalar`**, **`lt_scalar`**, **`gte_scalar`**, **`lte_scalar`** (fn): Element-wise comparison against a scalar.
- **`threshold`** (fn): Mask where elements >= value (delegates to `gte_scalar`).
- **`where_mask`** (fn): Conditional selection from two arrays based on a condition array.
- **`count_nonzero`** (fn): Count non-zero elements.
- **`argmin`**, **`argmax`** (fn): Flat index of min/max element (0-based).
- **`any`**, **`all`** (fn): Boolean predicates over all elements.
- **`sum`**, **`mean`**, **`min_val`**, **`max_val`** (fn): Global reductions.
- **`sum_axis`**, **`mean_axis`**, **`min_axis`**, **`max_axis`** (fn): Reductions along a given axis.
- **`reshape`** (fn): Reshape to new dimensions with same total element count.
- **`transpose_2d`** (fn): Transpose a 2D array (swap rows and columns).
- **`fill`** (fn): Fill all elements with a value (in-place).
- **`clone_array`** (fn): Clone convenience wrapper.
- **`bitwise_and`**, **`bitwise_or`**, **`bitwise_xor`**, **`bitwise_not`** (fn): Bitwise ops on Int32 arrays.
- **`bitwise_lshift`**, **`bitwise_rshift`** (fn): Bitwise shift on Int32 arrays.

### `compute::spatial`

2D spatial operations and linear algebra for NdArray. All spatial ops require 2D input
arrays except `dot` which requires 1D.

- **`convolve2d`** (fn): 2D convolution with zero-padding (same-size output). Kernel center at `(kR/2, kC/2)`.
- **`dilate`** (fn): Morphological dilation with Manhattan-diamond structuring element.
- **`erode`** (fn): Morphological erosion with Manhattan-diamond structuring element.
- **`flood_fill`** (fn): BFS flood fill with 4-connectivity from a seed cell.
- **`get_region`** (fn): Extract a rectangular sub-region from a 2D array.
- **`set_region`** (fn): Copy a source 2D array into a target at a given position (in-place).
- **`matmul`** (fn): Matrix multiplication (m,k)�(k,n)�(m,n) using naive triple loop.
- **`dot`** (fn): Dot product of two 1D arrays.

## Key Types

### Structs

#### `compute::array::NdArray`

Dense N-dimensional numerical array with row-major strides. Data is stored as a
contiguous `Vec<u8>` byte buffer with typed access through `get_f64`/`set_f64`
and `get_i32`/`set_i32`. Shapes are limited to 1D, 2D, or 3D with a hard cap of
268,435,456 elements. Constructors: `new`, `zeros`, `ones`, `range`, `from_slice`.
Metadata: `shape`, `dtype`, `size`, `ndim`, `strides`. Element access: `get_f64`,
`set_f64`, `get_i32`, `set_i32`, `get_by_indices`, `set_by_indices`, `flat_index`.

### Enums

#### `compute::array::DataType`

Element data type for an NdArray. Three variants:
- `Float32` � 32-bit IEEE 754 floating point (4 bytes per element)
- `Float64` � 64-bit IEEE 754 floating point (8 bytes per element)
- `Int32` � 32-bit signed integer (4 bytes per element)

Methods: `parse(s)` parses `"float32"` / `"float64"` / `"int32"`, `byte_size()` returns bytes per element, `name()` returns the string name.

## Lua API

Exposed under `lurek.compute.*` by `src/lua_api/compute_api.rs`. The API provides
five module-level constructor functions and a `LuaArray` UserData type with 52 methods.
All indices in the Lua API are 1-based. The default dtype is `"float32"`.

### Module-level functions

| Function | Description |
|----------|-------------|
| `lurek.compute.newArray(shape, dtype?)` | Create a zero-initialized array |
| `lurek.compute.zeros(shape, dtype?)` | Create a zero-filled array |
| `lurek.compute.ones(shape, dtype?)` | Create a one-filled array |
| `lurek.compute.range(start, stop, step?, dtype?)` | Create a 1D array from start to stop |
| `lurek.compute.fromTable(data, shape?, dtype?)` | Create an array from a Lua table |

### Array methods

| Method | Description |
|--------|-------------|
| `arr:getShape()` | Returns shape as a table of dimension sizes |
| `arr:getDimensions()` | Returns the number of dimensions |
| `arr:getSize()` | Returns total element count |
| `arr:getDataType()` | Returns dtype name string |
| `arr:isOnGPU()` | Always returns `false` (CPU-only) |
| `arr:get(i, ...)` | Get element at 1-based indices |
| `arr:set(i, ..., val)` | Set element at 1-based indices |
| `arr:toTable()` | Returns all elements as a flat table |
| `arr:reshape(shape)` | Returns reshaped copy |
| `arr:clone()` | Deep copy |
| `arr:transpose()` | Transpose a 2D array |
| `arr:fill(val)` | Fill all elements in-place |
| `arr:add(other)` | Element-wise add (Array or number) |
| `arr:sub(other)` | Element-wise subtract |
| `arr:mul(other)` | Element-wise multiply |
| `arr:div(other)` | Element-wise divide |
| `arr:pow(exp)` | Raise each element to exponent |
| `arr:sqrt()` | Element-wise square root |
| `arr:abs()` | Element-wise absolute value |
| `arr:neg()` | Element-wise negation |
| `arr:clamp(min, max)` | Clamp elements to range |
| `arr:eq(other)` | Equality comparison (� 0/1 array) |
| `arr:neq(other)` | Not-equal comparison |
| `arr:gt(other)` | Greater-than comparison |
| `arr:lt(other)` | Less-than comparison |
| `arr:gte(other)` | Greater-or-equal comparison |
| `arr:lte(other)` | Less-or-equal comparison |
| `arr:threshold(val)` | Mask where elements >= val |
| `arr:where(mask, other)` | Conditional selection |
| `arr:countNonZero()` | Count non-zero elements |
| `arr:argmin()` | 1-based flat index of min element |
| `arr:argmax()` | 1-based flat index of max element |
| `arr:any()` | True if any element is non-zero |
| `arr:all()` | True if all elements are non-zero |
| `arr:sum(axis?)` | Sum all or along 1-based axis |
| `arr:mean(axis?)` | Mean all or along 1-based axis |
| `arr:min(axis?)` | Min all or along 1-based axis |
| `arr:max(axis?)` | Max all or along 1-based axis |
| `arr:matmul(other)` | Matrix multiplication (2D) |
| `arr:dot(other)` | Dot product (1D) |
| `arr:bitwiseAnd(other)` | Bitwise AND (Int32) |
| `arr:bitwiseOr(other)` | Bitwise OR (Int32) |
| `arr:bitwiseXor(other)` | Bitwise XOR (Int32) |
| `arr:bitwiseNot()` | Bitwise NOT (Int32) |
| `arr:bitwiseLShift(n)` | Left shift (Int32) |
| `arr:bitwiseRShift(n)` | Right shift (Int32) |
| `arr:convolve2D(kernel)` | 2D convolution with zero-padding |
| `arr:dilate(radius)` | Morphological dilation |
| `arr:erode(radius)` | Morphological erosion |
| `arr:floodFill(row, col, val)` | BFS flood fill (1-based) |
| `arr:getRegion(row, col, rows, cols)` | Extract sub-region (1-based) |
| `arr:setRegion(row, col, source)` | Paste sub-region in-place (1-based) |

## Lua Examples

```lua
function lurek.init()
    -- Create a 10�10 heightmap filled with zeros
    heightmap = lurek.compute.zeros({10, 10}, "float32")

    -- Fill with some procedural values
    for r = 1, 10 do
        for c = 1, 10 do
            heightmap:set(r, c, math.sin(r * 0.5) * math.cos(c * 0.3))
        end
    end

    -- Apply a blur kernel via 2D convolution
    local kernel = lurek.compute.fromTable(
        {1/9, 1/9, 1/9, 1/9, 1/9, 1/9, 1/9, 1/9, 1/9},
        {3, 3}
    )
    blurred = heightmap:convolve2D(kernel)

    -- Compute statistics
    local total = blurred:sum()
    local avg   = blurred:mean()
    local hi    = blurred:max()

    -- Threshold into a binary mask
    mask = blurred:threshold(0.5)

    -- Extract a 3�3 sub-region starting at row 2, col 2
    local region = blurred:getRegion(2, 2, 3, 3)
end
```

```lua
-- Matrix multiplication example
function lurek.init()
    local a = lurek.compute.fromTable({1, 2, 3, 4, 5, 6}, {2, 3})
    local b = lurek.compute.fromTable({7, 8, 9, 10, 11, 12}, {3, 2})
    local c = a:matmul(b)  -- result is 2�2

    -- Dot product of 1D arrays
    local v1 = lurek.compute.fromTable({1, 0, 0})
    local v2 = lurek.compute.fromTable({0, 1, 0})
    local dp = v1:dot(v2)  -- 0.0
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 1     |
| `enum`     | 1     |
| `fn`       | 83    |
| **Total**  | **85** |

## References

| Module      | Relationship | Notes                                                    |
|-------------|--------------|----------------------------------------------------------|
| `engine`    | Imports from | Uses `log_messages` constants for allocation warnings    |
| `math`      | Peer         | Both are Tier 1 leaf-like modules; `compute` does not import `math` |
| `dataframe` | Related      | `dataframe` stores named-column tabular data; `compute` stores raw N-dimensional numeric arrays |
| `lua_api`   | Imported by  | `src/lua_api/compute_api.rs` registers `lurek.compute.*`  |

**Similar modules**: `dataframe` provides named-column tabular data (think spreadsheet rows);
`compute` provides raw numerical arrays (think NumPy ndarrays). Use `compute` for spatial
grids, convolution kernels, and matrix math. Use `dataframe` for records with heterogeneous
column types.

## Notes

- `NdArray` stores data in **row-major** order. The last axis varies fastest. Strides are computed as `strides[i] = product(shape[i+1..])`.
- All arithmetic and comparison operations return **new arrays** (immutable pattern). Only `fill` and `set_region` mutate in-place.
- Comparison operations (`eq`, `gt`, etc.) always produce `Float32` arrays with `0.0` / `1.0` values, regardless of input dtype.
- Bitwise operations (`bitwiseAnd`, `bitwiseOr`, etc.) require `Int32` dtype and return an error for float arrays.
- The Lua API uses **1-based indices** (converted to 0-based internally). The Rust API uses 0-based indices throughout.
- Maximum element count is 268,435,456 (256M). Arrays exceeding this limit produce an error at construction time.
- Shape is constrained to 1D, 2D, or 3D � higher-dimensional arrays are not supported.
- `matmul` uses a naive O(n3) triple loop. For very large matrices this will be slow; it is intended for moderate-size game data, not HPC workloads.
- `convolve2d` uses zero-padding and produces same-size output. Kernel center is at `(kRows/2, kCols/2)`.
- The `dispatch_arith!` macro in `compute_api.rs` unifies Array-vs-scalar overloading for arithmetic and comparison methods � a single Lua method accepts either an Array or a number.
- There is no GPU compute path. All operations run on the CPU. The `isOnGPU()` method always returns `false`.
- Large arrays (>10M elements) may cause GC pressure in Lua when converting via `toTable()`; prefer Rust-side batch operations.
