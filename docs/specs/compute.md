# `compute` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Foundations |
| **Status** | Implemented |
| **Lua API** | `lurek.compute` |
| **Source** | `src/compute/` |
| **Rust Tests** | `tests/rust/unit/compute_tests.rs`; `tests/rust/stress/compute_stress_tests.rs`; inline tests in `src/compute/array.rs`, `src/compute/spatial.rs` |
| **Lua Tests** | `tests/lua/unit/test_compute.lua`; `tests/lua/stress/test_compute_stress.lua`; `tests/lua/integration/test_data_compute.lua`; `tests/lua/integration/test_compute_dataframe.lua`; `tests/lua/golden/test_compute_golden.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Foundations` |

---

## Summary

The `compute` module owns dense numeric array processing for Lurek2D. It provides a CPU-side `NdArray` container plus array math, reductions, comparisons, and 2D spatial operations that are expensive or awkward to express efficiently in plain Lua.

This module exists so game scripts can work with structured numeric grids, vectors, and matrices without depending on renderer resources or external scientific-computing crates. Its design is intentionally simple: contiguous row-major storage, a small fixed dtype set, and operations that return new arrays unless an explicitly mutating method is being used.

`compute` intentionally does not own GPU dispatch, general tensor features, broadcasting semantics, or named-column analytics. It is a raw numeric array module; for heterogeneous tabular records use `src/dataframe/`, and for binary serialization or byte transport use `src/data/`.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Foundations responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.compute.* (Lua API — src/lua_api/compute_api.rs)
    |
    v
src/compute/mod.rs
    |- array.rs - array
    |- ops.rs - ops
    |- spatial.rs - spatial
```

---

## Source Files

| File | Purpose |
|------|---------|
| `array.rs` | Defines `NdArray`, `DataType`, shape validation, contiguous storage rules, typed element access, and array construction helpers. |
| `mod.rs` | Declares the compute submodules and re-exports the core ndarray surface. |
| `ops.rs` | Implements the bulk of ndarray behavior, including arithmetic, scalar ops, comparisons, masks, reductions, reshaping, transposition, and Int32-only bitwise operations. |
| `spatial.rs` | Adds higher-level 2D spatial and linear algebra helpers such as convolution, morphology, flood fill, region copy, matrix multiply, and vector dot product. |

---

## Submodules

### `compute::array`

Defines `NdArray`, `DataType`, shape validation, contiguous storage rules, typed element access, and array construction helpers.

- **`DataType`** (enum): Element data type for an NdArray.
- **`NdArray`** (struct): Dense N-dimensional numerical array with row-major strides.

### `compute::ops`

Implements the bulk of ndarray behavior, including arithmetic, scalar ops, comparisons, masks, reductions, reshaping, transposition, and Int32-only bitwise operations.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `compute::spatial`

Adds higher-level 2D spatial and linear algebra helpers such as convolution, morphology, flood fill, region copy, matrix multiply, and vector dot product.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

---

## Key Types

### Public Types

#### `NdArray`

Core dense numeric array type.

#### `DataType`

Declares the supported element representations: `Float32`, `Float64`, and `Int32`.

#### `LuaArray`

Lua-facing wrapper around `NdArray` defined in the Lua API layer.

---

## Lua API

Exposed under `lurek.compute.*` by `src/lua_api/compute_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.compute.newArray` | Creates a zero-initialized array with the given shape and optional dtype. |
| `lurek.compute.zeros` | Creates a zero-filled array with the given shape and optional dtype. |
| `lurek.compute.ones` | Creates a one-filled array with the given shape and optional dtype. |
| `lurek.compute.range` | Creates a 1D array from start to stop with optional step and dtype. |
| `lurek.compute.fromTable` | Creates an array from a Lua table of numbers with optional shape and dtype. |

### `Array` Methods

| Method | Description |
|--------|-------------|
| `array:getShape(...)` | Returns the shape as a table of dimension sizes. |
| `array:getDimensions(...)` | Returns the number of dimensions. |
| `array:getSize(...)` | Returns the total number of elements. |
| `array:getDataType(...)` | Returns the element data type name. |
| `array:isOnGPU(...)` | Returns false (CPU arrays only). |
| `array:get(...)` | Returns the element at the given 1-based indices. |
| `array:set(...)` | Sets the element at the given 1-based indices to a value. |
| `array:toTable(...)` | Returns all elements as a flat table of numbers. |
| `array:reshape(...)` | Returns a new array with the given shape and the same data. |
| `array:clone(...)` | Returns a deep copy of this array. |
| `array:transpose(...)` | Returns the transposed 2D array. |
| `array:fill(...)` | Fills all elements with the given value in-place. |
| `array:pow(...)` | Raises each element to a scalar exponent. |
| `array:sqrt(...)` | Element-wise square root. |
| `array:abs(...)` | Element-wise absolute value. |
| `array:neg(...)` | Element-wise negation. |
| `array:clamp(...)` | Clamps each element to the given range. |
| `array:threshold(...)` | Returns a mask array with 1.0 where elements >= val, else 0.0. |
| `array:countNonZero(...)` | Returns the count of nonzero elements. |
| `array:argmin(...)` | Returns the 1-based flat index of the minimum element. |
| `array:argmax(...)` | Returns the 1-based flat index of the maximum element. |
| `array:any(...)` | Returns true if any element is nonzero. |
| `array:all(...)` | Returns true if all elements are nonzero. |
| `array:sum(...)` | Sum of all elements, or along an axis (1-based). |
| `array:mean(...)` | Mean of all elements, or along an axis (1-based). |
| `array:min(...)` | Minimum of all elements, or along an axis (1-based). |
| `array:max(...)` | Maximum of all elements, or along an axis (1-based). |
| `array:matmul(...)` | Matrix multiplication of two 2D arrays. |
| `array:dot(...)` | Dot product of two 1D arrays. |
| `array:bitwiseAnd(...)` | Bitwise AND of two Int32 arrays. |
| `array:bitwiseOr(...)` | Bitwise OR of two Int32 arrays. |
| `array:bitwiseXor(...)` | Bitwise XOR of two Int32 arrays. |
| `array:bitwiseNot(...)` | Bitwise NOT of an Int32 array. |
| `array:bitwiseLShift(...)` | Bitwise left shift of an Int32 array. |
| `array:bitwiseRShift(...)` | Bitwise right shift of an Int32 array. |
| `array:convolve2D(...)` | 2D convolution with zero-padding. |
| `array:dilate(...)` | Morphological dilation with a diamond structuring element. |
| `array:erode(...)` | Morphological erosion with a diamond structuring element. |
| `array:type(...)` | Returns the type name "Array". |
| `array:typeOf(...)` | Returns true when the given name matches "Array" or a parent type. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.compute.
if lurek.compute then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 1 |
| `enum` | 1 |
| `fn` (Lua API) | 45 |
| **Total** | **47** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Foundations to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/compute/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
