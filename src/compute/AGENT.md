# compute

## Module Info
- Module name: `compute`
- Module group: `Foundations`
- Spec path: `docs/specs/compute.md`
- Lua API path(s): `src/lua_api/compute_api.rs`
- Rust test path(s): `tests/rust/unit/compute_tests.rs`; `tests/rust/stress/compute_stress_tests.rs`; inline tests in `src/compute/array.rs`, `src/compute/spatial.rs`
- Lua test path(s): `tests/lua/unit/test_compute.lua`; `tests/lua/stress/test_compute_stress.lua`; `tests/lua/integration/test_data_compute.lua`; `tests/lua/integration/test_compute_dataframe.lua`; `tests/lua/golden/test_compute_golden.lua`

## Module Purpose
The `compute` module owns dense numeric array processing for Lurek2D. It provides a CPU-side `NdArray` container plus array math, reductions, comparisons, and 2D spatial operations that are expensive or awkward to express efficiently in plain Lua.

This module exists so game scripts can work with structured numeric grids, vectors, and matrices without depending on renderer resources or external scientific-computing crates. Its design is intentionally simple: contiguous row-major storage, a small fixed dtype set, and operations that return new arrays unless an explicitly mutating method is being used.

`compute` intentionally does not own GPU dispatch, general tensor features, broadcasting semantics, or named-column analytics. It is a raw numeric array module; for heterogeneous tabular records use `src/dataframe/`, and for binary serialization or byte transport use `src/data/`.

## Files
- `mod.rs`: Declares the compute submodules and re-exports the core ndarray surface.
- `array.rs`: Defines `NdArray`, `DataType`, shape validation, contiguous storage rules, typed element access, and array construction helpers.
- `ops.rs`: Implements the bulk of ndarray behavior, including arithmetic, scalar ops, comparisons, masks, reductions, reshaping, transposition, and Int32-only bitwise operations.
- `spatial.rs`: Adds higher-level 2D spatial and linear algebra helpers such as convolution, morphology, flood fill, region copy, matrix multiply, and vector dot product.

## Key Types
- `NdArray`: Core dense numeric array type. It owns the contiguous row-major buffer and is the foundation every compute operation works against.
- `DataType`: Declares the supported element representations: `Float32`, `Float64`, and `Int32`. The restricted dtype set keeps the implementation small and predictable for Lua callers.
- `LuaArray`: Lua-facing wrapper around `NdArray` defined in the Lua API layer. It carries the overloaded method surface that accepts either arrays or scalars while keeping domain logic in `src/compute/`.