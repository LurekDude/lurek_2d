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

## Purpose

The compute module provides dense N-dimensional numerical arrays with NumPy-style
operations for Lua game scripts. The core type is `NdArray`, a contiguous byte-buffer
array supporting 1D, 2D, and 3D shapes with three element types: `Float32`, `Float64`,
and `Int32`. Data is stored in row-major order with typed access through `get_f64`/`set_f64`
and `get_i32`/`set_i32` accessors that handle byte-level serialisation internally.

## Source Files

| File         | Purpose                                                        |
|--------------|----------------------------------------------------------------|
| `mod.rs`     | Module root; re-exports `NdArray`, `DataType`, submodules      |
| `array.rs`   | Core `NdArray` struct, `DataType` enum, constructors, accessors |
| `ops.rs`     | Element-wise arithmetic, comparison, reduction, shape, bitwise ops |
| `spatial.rs` | 2D convolution, morphology, flood fill, regions, matmul, dot   |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

� [`docs/specs/compute.md`](../../docs/specs/compute.md)

_Update both this file **and** `docs/specs/compute.md` whenever source files, public types, or Lua bindings change._
