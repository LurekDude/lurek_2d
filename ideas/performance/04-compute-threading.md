# Compute, DataFrame & GPU Compute � Threading Opportunities

## Part 1: NdArray (src/compute/)

### Current Architecture

`NdArray` is an N-dimensional dense array supporting multiple data types
(U8, I32, F32, F64). All operations run single-threaded on the CPU.

### Operations Inventory

| Category | Functions | Parallelizable? |
|----------|-----------|-----------------|
| Element-wise | add, sub, mul, div, pow, sqrt, abs, neg, clamp | ? Yes � trivial |
| Reductions | sum, mean, min, max (along axis) | ? Yes � parallel reduce |
| Comparisons | eq, ne, lt, le, gt, ge, where | ? Yes � trivial |
| Spatial | convolve2d, dilate, erode | ? Yes � row-parallel |
| Spatial | flood_fill | ? No � BFS frontier |
| Shape | reshape, transpose, squeeze, flatten | N/A � zero-copy views |
| Creation | zeros, ones, full, rand, arange | ? Yes � trivial |

### Hot Path: Element-wise Operations

Current implementation in `src/compute/ops.rs` (lines 56�140):
```rust
for i in 0..a.size() {
    out.set_f64(i, op(a.get_f64(i), b.get_f64(i)));
}
```

**Cost**: O(n) with per-element f64 conversion overhead. For a 1000�1000
array, that's 1M iterations per operation.

### Hot Path: Convolution

Current implementation in `src/compute/spatial.rs` (lines 23�44):
```rust
for r in 0..in_rows {
    for c in 0..in_cols {
        for kr in 0..k_rows {
            for kc in 0..k_cols {
                sum += input[r + kr][c + kc] * kernel[kr][kc];
            }
        }
        output[r][c] = sum;
    }
}
```

**Cost**: O(rows � cols � kernel_rows � kernel_cols)
- 512�512 input, 5�5 kernel = **6.5M multiply-accumulate operations**
- 1024�1024 input, 9�9 kernel = **85M operations**

### Hot Path: Dilation/Erosion

`src/compute/spatial.rs` (lines 58�90):
```rust
for r in 0..rows {
    for c in 0..cols {
        // Manhattan neighborhood scan
        for dr in -radius..=radius {
            for dc in -radius..=radius {
                // max/min operation
            }
        }
    }
}
```

**Cost**: O(rows � cols � radius2)

---

### Opportunity 1: Rayon Parallelism for Element-wise Ops (Effort: LOW)

```rust
use rayon::prelude::*;

// Parallel element-wise operation
pub fn par_element_wise(a: &NdArray, b: &NdArray, op: fn(f64, f64) -> f64) -> NdArray {
    let mut out = NdArray::zeros_like(a);
    let a_data = a.data();
    let b_data = b.data();
    let out_data = out.data_mut();

    out_data.par_iter_mut().enumerate().for_each(|(i, val)| {
        *val = op(a_data[i], b_data[i]);
    });
    out
}
```

**Threshold**: Only parallelize when `array.size() > 10_000` (below that,
serial is faster due to thread dispatch overhead).

**Expected Speedup**:
- 4-core: 3�3.5� for 100k+ elements
- 8-core: 5�7� for 100k+ elements

### Opportunity 2: Row-Parallel Convolution (Effort: LOW)

Parallelize the outer loop of convolution by rows:

```rust
(0..in_rows).into_par_iter().for_each(|r| {
    for c in 0..in_cols {
        let mut sum = 0.0;
        for kr in 0..k_rows {
            for kc in 0..k_cols {
                sum += input[(r + kr) * in_cols + (c + kc)] * kernel[kr * k_cols + kc];
            }
        }
        output[r * in_cols + c] = sum;
    }
});
```

**Expected Speedup**: 4�8� for 256�256+ inputs (sufficient rows to fill threads)

### Opportunity 3: SIMD Vectorization (Effort: Medium)

Rust's auto-vectorization can handle simple element-wise ops if data is
aligned and the loop is simple enough. However, explicit SIMD via
`std::simd` (nightly) or glam's Vec4 can guarantee vectorization:

```rust
// Process 4 elements at once
for chunk in data.chunks_exact(4) {
    let a = f32x4::from_slice(chunk);
    let b = f32x4::from_slice(&other[offset..]);
    let result = a + b;
    result.write_to_slice(&mut out[offset..]);
}
```

**Impact**: 2�4� for f32 ops, less for f64 (wider SIMD lanes)

### Opportunity 4: GPU Compute Shaders (Effort: HIGH)

For very large arrays (100k+ elements), offload computation to GPU via
wgpu compute shaders:

```wgsl
@group(0) @binding(0) var<storage, read> a: array<f32>;
@group(0) @binding(1) var<storage, read> b: array<f32>;
@group(0) @binding(2) var<storage, read_write> result: array<f32>;

@compute @workgroup_size(256)
fn add(@builtin(global_invocation_id) id: vec3<u32>) {
    let i = id.x;
    if (i < arrayLength(&a)) {
        result[i] = a[i] + b[i];
    }
}
```

**Lurek2D Implementation**:
1. Add compute pipeline to `GpuRenderer` (alongside existing render pipelines)
2. Create storage buffers for input/output arrays
3. Dispatch compute shader, read back results
4. Expose via `lurek.compute.gpu_add(a, b)` or automatic GPU offload for large arrays

**Expected Speedup**: 10�100� for 100k+ elements (GPU has hundreds of ALUs)

**When Worth It**: Arrays with 100k+ elements AND operations that are
compute-bound (convolution, matmul). Not worth it for small arrays due to
CPU-GPU transfer overhead (~0.1�1ms per transfer).

**Candidate Operations for GPU**:
| Operation | GPU Benefit | Transfer Cost |
|-----------|-------------|---------------|
| Element-wise add/mul/etc. | Moderate | Low |
| Convolution 2D | **Very High** | Low |
| Matrix multiply | **Very High** | Low |
| Reduction (sum/mean) | High | Medium (readback) |
| Dilation/Erosion | High | Low |
| Flood fill | Low (serial BFS) | High |

---

## Part 2: DataFrame (src/dataframe/)

### Current Architecture

Column-major tabular data with SQL-style query support. Operations:
- `filter()` � linear scan, O(n)
- `sort()` � TimSort, O(n log n)
- `select_columns()` � projection, O(columns)
- SQL parsing � recursive descent, O(query_length)

### Opportunity 1: Parallel Sort (Effort: Low)

Replace `indices.sort_by()` with rayon's parallel sort:
```rust
// Before:
indices.sort_by(|a, b| compare_fn(a, b));

// After:
indices.par_sort_by(|a, b| compare_fn(a, b));
```

**Threshold**: Only beneficial for 100k+ rows.
**Expected Speedup**: 2�3� on 4 cores for 1M rows.

### Opportunity 2: Parallel Filter (Effort: Low)

```rust
// Parallel filter with rayon
let passing_indices: Vec<usize> = (0..row_count)
    .into_par_iter()
    .filter(|&i| predicate(&column[i]))
    .collect();
```

**Threshold**: Only for 100k+ rows with complex predicates.

### Opportunity 3: Column-Parallel Aggregation (Effort: Medium)

When computing aggregates over multiple columns simultaneously:
```rust
// Process columns in parallel
columns.par_iter().map(|col| col.aggregate(AggFn::Sum)).collect()
```

**When Worth It**: 10+ columns with millions of rows.

---

## Part 3: Integration Strategy

### Rayon as First-Class Dependency

Currently rayon is only a transitive dependency (via rapier2d). Making it
a direct dependency enables parallelism across:

```toml
[dependencies]
rayon = "1.10"
```

**Modules that benefit**:
- `compute/ops.rs` � element-wise operations
- `compute/spatial.rs` � convolution, dilation, erosion
- `dataframe/query.rs` � sort, filter
- `particle/system.rs` � particle updates
- `ai/influence_map.rs` � map propagation

**Binary cost**: rayon is already linked (transitive). Explicit dependency adds zero bytes.

### Threshold Strategy

Never parallelize unconditionally � always check data size:

```rust
const RAYON_THRESHOLD: usize = 10_000;

fn element_wise_op(a: &NdArray, b: &NdArray, op: fn(f64, f64) -> f64) -> NdArray {
    if a.size() > RAYON_THRESHOLD {
        par_element_wise(a, b, op)  // Rayon parallel
    } else {
        seq_element_wise(a, b, op)  // Sequential (less overhead)
    }
}
```

### GPU Compute Roadmap

| Phase | What | Effort |
|-------|------|--------|
| 1 | Add wgpu compute pipeline infrastructure | Medium |
| 2 | Implement element-wise GPU ops (add, mul) | Medium |
| 3 | Implement GPU convolution 2D | High |
| 4 | Automatic CPU�GPU offload for large arrays | High |
| 5 | Expose via `lurek.compute.gpuAdd()` Lua API | Low |

---

## Summary

| Opportunity | Module | Data Size Threshold | Effort | Speedup |
|-------------|--------|---------------------|--------|---------|
| Rayon element-wise | compute | 10k+ elements | Low | 4�8� |
| Rayon convolution | compute | 256�256+ | Low | 4�8� |
| Rayon dilation/erosion | compute | 256�256+ | Low | 4�8� |
| SIMD vectorization | compute | Always (f32) | Medium | 2�4� |
| Rayon parallel sort | dataframe | 100k+ rows | Low | 2�3� |
| Rayon parallel filter | dataframe | 100k+ rows | Low | 2�3� |
| GPU compute element-wise | compute | 100k+ elements | High | 10�100� |
| GPU convolution 2D | compute | 512�512+ | High | 50�200� |
