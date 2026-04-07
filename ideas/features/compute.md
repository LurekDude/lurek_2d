# compute — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/compute.md`
**Files**: NdArray CPU dense arrays

## Purpose

Dense N-dimensional numerical array operations: create, reshape, slice, element-wise math, reductions, matrix multiply. CPU-only compute.

## Current Feature Summary

- `NdArray`: N-dimensional f64 array with shape
- Element-wise ops: add, sub, mul, div, pow, abs, sqrt, exp, log
- Reductions: sum, mean, min, max, argmin, argmax
- Matrix operations: matmul, transpose
- Shape operations: reshape, flatten, squeeze, unsqueeze
- Broadcasting: automatic shape expansion for element-wise ops
- Slicing: extract sub-arrays
- Random initialization: uniform, normal distributions
- Statistical functions: variance, standard deviation

## Feature Gaps

1. **No GPU compute**: All operations are CPU. For large arrays, GPU compute shaders (via wgpu) would be dramatically faster.
2. **No sparse arrays**: Only dense storage. Sparse matrices common for graph algorithms.
3. **No convolution**: No 1D/2D convolution (useful for image processing, signal processing).
4. **No FFT**: No Fast Fourier Transform (needed for audio analysis, signal processing).
5. **No linear algebra beyond matmul**: No eigenvalues, SVD, LU decomposition, least squares solve.
6. **No integer arrays**: Only f64. Integer arrays useful for lookup tables, game data.
7. **No interop with ImageData**: Can't view an ImageData as an NdArray for computation.

## Structural Issues

- **Name is misleading**: "compute" suggests GPU compute or general computation. Module is actually an ndarray implementation. Rename to `ndarray` or merge into `data`.
- **Overlap with data module**: ByteData (binary arrays) and NdArray (numerical arrays) are conceptually adjacent. Different use cases (I/O vs math) but confusing to have both.
- **Overlap with dataframe**: DataFrame column operations overlap with NdArray operations. DataFrame adds column names but operates on similar data.
- **Tier placement questionable**: NdArray is powerful but how many 2D game scripts need dense array math? This feels like a Tier 2 extension rather than core Tier 1.

## Suggestions

1. **Rename to `ndarray`**: `luna.ndarray.new(shape)` is clearer than `luna.compute.new(shape)`. The current name implies GPU compute which doesn't exist.
2. **Consider merging with data**: Create a unified `luna.data` namespace: `luna.data.newBuffer(size)` for binary, `luna.data.newArray(shape)` for numerical. Reduces module count.
3. **Move to Tier 2**: Unless game simulation commonly needs dense array math, this is more of an extension than core. Pathfinding flow fields and AI utility scoring might use it, but those are Tier 2 themselves.
4. **Add ImageData interop**: `ndarray:fromImage(imageData)` / `ndarray:toImage()` — enables numerical image processing.
5. **Add GPU compute path**: Long-term, use wgpu compute shaders for large arrays. Mark as future roadmap.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| NdArray | ? | ? | ? | ? |
| Matrix math | ? | ? | ? | ? (glam) |
| Broadcasting | ? | ? | ? | ? |
| GPU compute | ? | ? | ? | ? |
| Statistics | ? | ? | ? | ? |

Luna2D is unique among 2D Lua engines in offering dense array compute. This is a differentiator — but the naming and positioning should reflect what it actually is.

## Priority

**LOW** — Rename is important for clarity. Tier reassignment is an architectural decision. Merge with data is worth considering.
