# IDEA.md — `compute` module

> Migrated from `ideas/features/compute.md` and `ideas/performance/04-compute-threading.md`.
> Status checked against `src/compute/` and `src/lua_api/compute_api.rs`.
> Lua namespace: `lurek.compute`.

---

## Features

### ✅ DONE — 2D and 1D Convolution
**Source**: features/compute.md — Feature Gaps #3

`convolve2D` and `convolve1d` implemented in `compute_api.rs` (lines ~558, ~729) backed by
`src/compute/spatial.rs` and `src/compute/analytics.rs`.

---

### ⚠️ STUB — GPU Compute
**Source**: features/compute.md — Feature Gaps #1

`isOnGPU()` returns `false` (line ~133 in `compute_api.rs`). The GPU compute path is not
implemented. All operations are CPU-only. Mark as a future roadmap item and ensure docs and
the `isOnGPU()` stub don't mislead users.

---

### ✅ DONE — FFT (Fast Fourier Transform)
**Source**: features/compute.md — Feature Gaps #4

Cooley-Tukey iterative radix-2 FFT added in `src/compute/fft.rs`. Bound in `compute_api.rs` as:
`lurek.compute.fft(samples)`, `lurek.compute.ifft(freqs)`, `lurek.compute.fftMagnitude(samples)`.

---

### ❌ DEFERRED — Sparse Array Support
**Source**: features/compute.md — Feature Gaps #2

Complex implementation. Deferred.

---

### ✅ DONE — Advanced Linear Algebra
**Source**: features/compute.md — Feature Gaps #5

Added to `src/compute/linalg.rs` and bound in `compute_api.rs`:
- `ndarray:luDecompose()` — Doolittle LU with partial pivoting; returns `{n, det_sign, perm, lu_data}`.
- `ndarray:eigenPower(max_iter?, tol?)` — power iteration; returns `{value, vector}`.

---

### ❌ DEFERRED — Integer Array Type
**Source**: features/compute.md — Feature Gaps #6

Deferred. NdArray stays f64-only for now.

---

### ❌ DEFERRED — ImageData Interop
**Source**: features/compute.md — Feature Gaps #7 / Suggestions #4

Needs image module alignment. Deferred.

---

### 🤔 CONSIDER — Rename Module / Namespace
**Source**: features/compute.md — Structural Issues

The name `compute` implies GPU compute. The module is actually a CPU NdArray implementation.
Consider renaming the Lua namespace to `lurek.ndarray` or merging with `lurek.data`.
This is a **breaking API change** requiring MAJOR version bump and Lua-Designer sign-off.

---

## Performance

### ❌ DEFERRED — Parallel Array Operations (rayon)
**Source**: performance/04-compute-threading.md

No rayon in `ops.rs` yet. Deferred until profiling confirms a bottleneck.
