# compute

## General Info

- Module group: `Foundations`
- Source path: `src/compute/`
- Lua API path(s): `src/lua_api/compute_api.rs`
- Primary Lua namespace: `lurek.compute`
- Rust test path(s): tests/rust/unit/compute_tests.rs; tests/rust/stress/compute_stress_tests.rs; inline tests in src/compute/array.rs, src/compute/spatial.rs
- Lua test path(s): tests/lua/unit/test_compute.lua; tests/lua/stress/test_compute_stress.lua; tests/lua/integration/test_data_compute.lua; tests/lua/integration/test_compute_dataframe.lua; tests/lua/golden/test_compute_golden.lua

## Summary

The `compute` module is Lurek2D's dense N-dimensional numerical array library for the Foundations tier. It provides CPU-side matrix operations, signal processing, spatial transforms, and linear algebra that would otherwise require GPU compute shaders. All arithmetic executes synchronously on the calling thread — no background workers, no GPU memory — making it safe to call from Lua game scripts and easy to unit-test headlessly.

**Core type: `NdArray`.** `NdArray` is a row-major contiguous buffer supporting N-dimensional shapes (minimum 1 dimension). Three element types are supported via the `DataType` enum: `Float32`, `Float64`, and `Int32`. The restricted dtype set keeps the API predictable for Lua callers who do not control Rust type inference. Construction helpers: `new(shape, dtype)`, `zeros`, `ones`, `range(start, stop, step)`, `from_slice`. The Lua API additionally exposes `fromTable` to create an array from a plain Lua table. Shape inspection: `shape()`, `ndim()`, `numel()`. Mutation: `get_by_indices`/`set_by_indices` (multi-dim), `get_f64`/`set_f64` (flat index). Structural transforms: `reshape`, `transpose_2d`, `clone_array`, `fill`.

**`ops` submodule.** Element-wise binary operations (add, sub, mul, div, mod, pow) and their scalar variants. Binary element-wise ops support shape-equal arrays and 2D<->1D row broadcasting (`[rows, cols]` with `[cols]`). Unary transforms: `sqrt`, `abs`, `neg`, `clamp`, `threshold`. In-place arithmetic helpers: `add_inplace`, `sub_inplace`, `mul_inplace`, `div_inplace`. Comparison predicates (eq, neq, gt, lt, gte, lte) with scalar forms. Logical aggregates: `any`, `all`, `count_nonzero`. Global reductions: `sum`, `mean`, `min_val`, `max_val`, `argmin`, `argmax`. Axis reductions with the same set of operations. Conditional selection: `where_mask`. Bitwise operations for `Int32` arrays: AND, OR, XOR, NOT, left shift, right shift.

**`spatial` submodule.** 2D convolution (`convolve2d`) with zero-padding for same-size output. Morphological dilation and erosion with a Manhattan-diamond structuring element. Flood fill using BFS with 4-connectivity. Sub-array extraction/insertion (`get_region`/`set_region`). 2D matrix multiplication (`matmul`). 1D dot product.

**`linalg` submodule.** Vector utilities: L2 normalise, 2D cross product (signed scalar), outer product. Matrix construction: 2×2 rotation matrix, 3×3 homogeneous affine matrix. Point transformation by 2×2 or 3×3 matrix. `linsolve` via Gaussian elimination with partial pivoting. `lu_decompose` (P·A = L·U). `eigenvalue_power` (dominant eigenvalue by power iteration). `gaussian_kernel` generator. `sobel` edge detection.

**`analytics` submodule.** Signal processing: `convolve1d`, `correlate1d`, autocorrelation, moving average. Statistics: `variance`, `std_dev`, `histogram`, `percentile`, `covariance`, `pearson_corr`. Transforms: `cumsum`, `diff`, normalise to range (`normalize_range`), z-score standardisation (`zscore`). Normalisation norms: L1, L2, min-max.

**`fft` submodule.** Dedicated Fast Fourier Transform (power-of-two optimized). `fft(data)` returns the complex DFT spectrum. `ifft(data)` reconstructs the time-domain signal. `fft_magnitude(data)` returns the magnitude spectrum `|X[k]|`. Lua scripts access all three via `lurek.compute.fft`, `lurek.compute.ifft`, `lurek.compute.fftMagnitude`.

**Lua surface.** 11 module-level constructor/utility functions and a full `Array` userdata type with ~40 methods covering shape inspection, element access, arithmetic, reductions, transforms, and serialisation. Matrix helpers `gaussianKernel`, `rotate2dMatrix`, `affine2d` are exposed as free functions.

**Scope boundary.** Foundations tier. No Lurek2D module dependencies. Lua bridge in `src/lua_api/compute_api.rs`. Plugin candidacy under proposed constraint A-05 — see [docs/architecture/plugins.md](../architecture/plugins.md).

## Files

- `analytics.rs`: Statistical analytics, signal processing, and normalisation for NdArray.
- `array.rs`: Defines `NdArray`, `DataType`, shape validation, contiguous storage rules, typed element access, and array construction helpers.
- `fft.rs`: Fast Fourier Transform (FFT) and Inverse FFT for the compute subsystem.
- `linalg.rs`: Linear algebra extensions for NdArray.
- `mod.rs`: Declares the compute submodules and re-exports the core ndarray surface.
- `ops.rs`: Implements the bulk of ndarray behavior, including arithmetic, scalar ops, comparisons, masks, reductions, reshaping, transposition, and Int32-only bitwise operations.
- `spatial.rs`: Adds higher-level 2D spatial and linear algebra helpers such as convolution, morphology, flood fill, region copy, matrix multiply, and vector dot product.

## Types

- `DataType` (`enum`, `array.rs`): Declares the supported element representations: `Float32`, `Float64`, and `Int32`. The restricted dtype set keeps the implementation small and predictable for Lua callers.
- `NdArray` (`struct`, `array.rs`): Core dense numeric array type. It owns the contiguous row-major buffer and is the foundation every compute operation works against.
- `LuDecomp` (`struct`, `linalg.rs`): Result of an LU decomposition with partial pivoting.

## Functions

- `cumsum` (`analytics.rs`): Cumulative sum along a 1D array (or flattened elements if axis is None).
- `diff` (`analytics.rs`): Discrete difference: `out[i] = a[i+1] - a[i]` (order `n = 1`, 1D or flat).
- `histogram` (`analytics.rs`): Compute a histogram with `bins` equal-width bins.
- `percentile` (`analytics.rs`): Compute the `p`-th percentile (0–100) of all elements.
- `covariance` (`analytics.rs`): Population covariance of two 1D (or flat) arrays of equal size.
- `pearson_corr` (`analytics.rs`): Pearson correlation coefficient of two 1D (or flat) arrays.
- `normalize_range` (`analytics.rs`): Linearly rescale all elements to [out_min, out_max].
- `zscore` (`analytics.rs`): Standardise all elements to zero mean and unit variance (z-score).
- `convolve1d` (`analytics.rs`): 1D convolution of `signal` with `kernel` (full output length).
- `correlate1d` (`analytics.rs`): 1D cross-correlation: slide `template` over `signal` (valid output).
- `DataType::parse` (`array.rs`): Parse dtype string and return matching DataType or parse error.
- `DataType::byte_size` (`array.rs`): Return byte width of dtype element representation.
- `DataType::name` (`array.rs`): Return canonical dtype name string.
- `NdArray::new` (`array.rs`): Create zero-initialized array and return it for shape and dtype.
- `NdArray::zeros` (`array.rs`): Allocate zero-filled array and return it after validating shape limits.
- `NdArray::ones` (`array.rs`): Allocate one-filled array and return initialized values.
- `NdArray::range` (`array.rs`): Build 1D range array and return values from start to stop with step.
- `NdArray::from_slice` (`array.rs`): Build array from f64 slice and return typed array with requested shape.
- `NdArray::get_f64` (`array.rs`): Read element by flat index and return value converted to f64.
- `NdArray::set_f64` (`array.rs`): Write f64 value by flat index and return after dtype conversion.
- `NdArray::get_i32` (`array.rs`): Read element as i32 by flat index and return integer value.
- `NdArray::set_i32` (`array.rs`): Write i32 value by flat index and return after byte update.
- `NdArray::flat_index` (`array.rs`): Convert multidimensional indices to flat index and return offset.
- `NdArray::shape` (`array.rs`): Read shape slice and return axis lengths.
- `NdArray::dtype` (`array.rs`): Read scalar dtype and return DataType value.
- `NdArray::size` (`array.rs`): Read element count and return total number of elements.
- `NdArray::ndim` (`array.rs`): Read number of dimensions and return ndim value.
- `NdArray::strides` (`array.rs`): Read stride slice and return per-axis element strides.
- `NdArray::data` (`array.rs`): Read immutable byte buffer and return raw data slice.
- `NdArray::data_mut` (`array.rs`): Read mutable byte buffer and return raw mutable data slice.
- `NdArray::set_shape` (`array.rs`): Replace shape and stride metadata and return after metadata update.
- `NdArray::compute_strides` (`array.rs`): Compute row-major strides and return stride vector for provided shape.
- `NdArray::get_by_indices` (`array.rs`): Read element by multidimensional indices and return f64 value.
- `NdArray::set_by_indices` (`array.rs`): Write element by multidimensional indices and return success status.
- `NdArray::to_f64_vec` (`array.rs`): Convert all elements to f64 and return copied vector.
- `NdArray::fill` (`array.rs`): Fill all elements with scalar value and return after mutation.
- `NdArray::map` (`array.rs`): Map function over elements and return new array with mapped values.
- `NdArray::iter_f64` (`array.rs`): Iterate elements as f64 values and return lazy iterator.
- `NdArray::display_string` (`array.rs`): Format array summary and return short display string.
- `next_power_of_two` (`fft.rs`): Returns the smallest power of two ≥ `n`.
- `fft` (`fft.rs`): Computes the discrete Fourier transform (DFT) of `data`.
- `ifft` (`fft.rs`): Computes the inverse discrete Fourier transform.
- `fft_magnitude` (`fft.rs`): Returns the magnitude spectrum of `data` as `|X[k]|` values.
- `normalize_vec` (`linalg.rs`): L2-normalise a 1D vector.
- `cross2d` (`linalg.rs`): 2D cross product (returns signed scalar area of the parallelogram).
- `outer` (`linalg.rs`): Outer product of two 1D vectors: result shape is [m, n].
- `rotate2d_matrix` (`linalg.rs`): Build a 2×2 rotation matrix for `angle_rad` radians.
- `affine2d` (`linalg.rs`): Build a 3×3 homogeneous affine matrix combining translation, rotation, and scale.
- `transform_points` (`linalg.rs`): Apply a 2×2 or 3×3 (homogeneous) matrix to a list of 2D points.
- `gaussian_kernel` (`linalg.rs`): Generate a `size × size` Gaussian kernel with the given `sigma`.
- `sobel` (`linalg.rs`): Apply Sobel edge detection to a 2D Float32/Float64 array.
- `linsolve` (`linalg.rs`): Solve the linear system A·x = b using Gaussian elimination with partial pivoting.
- `lu_decompose` (`linalg.rs`): Decomposes a square matrix `a` into P·A = L·U using partial pivoting.
- `eigenvalue_power` (`linalg.rs`): Computes the dominant eigenvalue and its eigenvector of a square matrix using the power-iteration method.
- `get_par_threshold` (`ops.rs`): Returns the current parallelization threshold for element-wise and reduction operations (default 10,000).
- `set_par_threshold` (`ops.rs`): Sets the parallelization threshold for element-wise and reduction operations, returning the previous value.
- `add` (`ops.rs`): Element-wise addition of two arrays (same shape and dtype).
- `add_scalar` (`ops.rs`): Add a scalar to every element.
- `sub` (`ops.rs`): Element-wise subtraction of two arrays (same shape and dtype).
- `sub_scalar` (`ops.rs`): Subtract a scalar from every element.
- `mul` (`ops.rs`): Element-wise multiplication of two arrays (same shape and dtype).
- `mul_scalar` (`ops.rs`): Multiply every element by a scalar.
- `div` (`ops.rs`): Element-wise division of two arrays (same shape and dtype).
- `div_scalar` (`ops.rs`): Divide every element by a scalar.
- `pow_scalar` (`ops.rs`): Raise every element to a scalar exponent.
- `sqrt` (`ops.rs`): Element-wise square root.
- `abs` (`ops.rs`): Element-wise absolute value.
- `neg` (`ops.rs`): Element-wise negation.
- `clamp` (`ops.rs`): Clamp every element to `[min_val, max_val]`.
- `eq` (`ops.rs`): Element-wise equality comparison of two arrays.
- `eq_scalar` (`ops.rs`): Element-wise equality comparison against a scalar.
- `neq` (`ops.rs`): Element-wise not-equal comparison of two arrays.
- `neq_scalar` (`ops.rs`): Element-wise not-equal comparison against a scalar.
- `gt` (`ops.rs`): Element-wise greater-than comparison of two arrays.
- `gt_scalar` (`ops.rs`): Element-wise greater-than comparison against a scalar.
- `lt` (`ops.rs`): Element-wise less-than comparison of two arrays.
- `lt_scalar` (`ops.rs`): Element-wise less-than comparison against a scalar.
- `gte` (`ops.rs`): Element-wise greater-than-or-equal comparison of two arrays.
- `gte_scalar` (`ops.rs`): Element-wise greater-than-or-equal comparison against a scalar.
- `lte` (`ops.rs`): Element-wise less-than-or-equal comparison of two arrays.
- `lte_scalar` (`ops.rs`): Element-wise less-than-or-equal comparison against a scalar.
- `threshold` (`ops.rs`): Threshold mask: returns Float32 array with 1.0 where `a >= val`, 0.0 otherwise.
- `where_mask` (`ops.rs`): Conditional selection: where `cond != 0`, choose from `a`; otherwise from `b`.
- `count_nonzero` (`ops.rs`): Count the number of non-zero elements.
- `argmin` (`ops.rs`): Return the flat index of the minimum element (0-based).
- `argmax` (`ops.rs`): Return the flat index of the maximum element (0-based).
- `any` (`ops.rs`): Returns `true` if any element is non-zero.
- `all` (`ops.rs`): Returns `true` if all elements are non-zero.
- `sum` (`ops.rs`): Sum of all elements.
- `mean` (`ops.rs`): Mean of all elements.
- `min_val` (`ops.rs`): Minimum value across all elements.
- `max_val` (`ops.rs`): Maximum value across all elements.
- `sum_axis` (`ops.rs`): Sum along a given axis, producing an array with that axis removed.
- `mean_axis` (`ops.rs`): Mean along a given axis.
- `min_axis` (`ops.rs`): Minimum along a given axis.
- `max_axis` (`ops.rs`): Maximum along a given axis.
- `reshape` (`ops.rs`): Reshape an array to a new shape with the same total element count.
- `transpose_2d` (`ops.rs`): Transpose a 2D array (swap rows and columns).
- `fill` (`ops.rs`): Fill all elements of an array with a value (in-place).
- `add_inplace` (`ops.rs`): Add second array into first array in place and return success status.
- `sub_inplace` (`ops.rs`): Subtract second array from first array in place and return success status.
- `mul_inplace` (`ops.rs`): Multiply first array by second array in place and return success status.
- `div_inplace` (`ops.rs`): Divide first array by second array in place and return success status.
- `clone_array` (`ops.rs`): Clone an array (convenience wrapper).
- `bitwise_and` (`ops.rs`): Bitwise AND of two Int32 arrays.
- `bitwise_or` (`ops.rs`): Bitwise OR of two Int32 arrays.
- `bitwise_xor` (`ops.rs`): Bitwise XOR of two Int32 arrays.
- `bitwise_not` (`ops.rs`): Bitwise NOT of an Int32 array.
- `bitwise_lshift` (`ops.rs`): Bitwise left shift of an Int32 array by `amount` bits.
- `bitwise_rshift` (`ops.rs`): Bitwise right shift (arithmetic) of an Int32 array by `amount` bits.
- `convolve2d` (`spatial.rs`): 2D convolution with zero-padding (same-size output).
- `dilate` (`spatial.rs`): Morphological dilation with a Manhattan-diamond structuring element.
- `erode` (`spatial.rs`): Morphological erosion with a Manhattan-diamond structuring element.
- `flood_fill` (`spatial.rs`): Flood fill using BFS with 4-connectivity.
- `get_region` (`spatial.rs`): Extract a rectangular sub-region from a 2D array.
- `set_region` (`spatial.rs`): Copy a source 2D array into a target 2D array at position `(row, col)`.
- `matmul` (`spatial.rs`): Matrix multiplication of two 2D arrays: (m,k) × (k,n) → (m,n).
- `dot` (`spatial.rs`): Dot product of two 1D arrays (same length).

## Lua API Reference

- Binding path(s): `src/lua_api/compute_api.rs`
- Namespace: `lurek.compute`

### Module Functions
- `lurek.compute.newArray`: Creates a zero-filled array with the requested shape and data type.
- `lurek.compute.zeros`: Creates a zero-filled array with the requested shape and data type.
- `lurek.compute.ones`: Creates a one-filled array with the requested shape and data type.
- `lurek.compute.range`: Creates a one-dimensional range array.
- `lurek.compute.fromTable`: Creates an array from a flat Lua table and optional shape.
- `lurek.compute.gaussianKernel`: Creates a square Gaussian kernel array.
- `lurek.compute.rotate2dMatrix`: Creates a 2D rotation matrix.
- `lurek.compute.affine2d`: Creates a 2D affine transform matrix.
- `lurek.compute.fft`: Computes the FFT of real-valued samples.
- `lurek.compute.ifft`: Computes the inverse FFT of complex frequency pairs.
- `lurek.compute.fftMagnitude`: Computes FFT magnitudes for real-valued samples.
- `lurek.compute.getParThreshold`: Returns the global compute parallelism threshold.
- `lurek.compute.setParThreshold`: Sets the global compute parallelism threshold and returns the previous value.

### `LArray` Methods
- `LArray:getShape`: Returns the array shape as one-based dimension table.
- `LArray:getDimensions`: Returns the number of array dimensions.
- `LArray:getSize`: Returns the total number of array elements.
- `LArray:getDataType`: Returns the array data type name.
- `LArray:isOnGPU`: Returns whether this array is currently stored on the GPU.
- `LArray:get`: Reads an array element using one-based indices.
- `LArray:set`: Writes an array element using one-based indices followed by the value.
- `LArray:toTable`: Returns array values flattened into a Lua table.
- `LArray:reshape`: Returns a reshaped copy of this array.
- `LArray:clone`: Returns a copy of this array.
- `LArray:transpose`: Returns a transposed copy of a two-dimensional array.
- `LArray:fill`: Fills this array in place with one value.
- `LArray:addInplace`: Adds another array into this array in place.
- `LArray:subInplace`: Subtracts another array from this array in place.
- `LArray:mulInplace`: Multiplies this array by another array in place.
- `LArray:divInplace`: Divides this array by another array in place.
- `LArray:add`: Returns element-wise addition with an array or scalar.
- `LArray:sub`: Returns element-wise subtraction with an array or scalar.
- `LArray:mul`: Returns element-wise multiplication with an array or scalar.
- `LArray:div`: Returns element-wise division with an array or scalar.
- `LArray:pow`: Returns this array raised element-wise to a scalar exponent.
- `LArray:sqrt`: Returns element-wise square roots.
- `LArray:abs`: Returns element-wise absolute values.
- `LArray:neg`: Returns element-wise negated values.
- `LArray:clamp`: Returns values clamped between minimum and maximum bounds.
- `LArray:eq`: Returns element-wise equality comparison with an array or scalar.
- `LArray:neq`: Returns element-wise inequality comparison with an array or scalar.
- `LArray:gt`: Returns element-wise greater-than comparison with an array or scalar.
- `LArray:lt`: Returns element-wise less-than comparison with an array or scalar.
- `LArray:gte`: Returns element-wise greater-or-equal comparison with an array or scalar.
- `LArray:lte`: Returns element-wise less-or-equal comparison with an array or scalar.
- `LArray:threshold`: Returns a mask array where values above a threshold are selected.
- `LArray:where`: Selects values from this array or another array using a mask array.
- `LArray:countNonZero`: Counts non-zero elements.
- `LArray:argmin`: Returns the one-based flat index of the minimum value.
- `LArray:argmax`: Returns the one-based flat index of the maximum value.
- `LArray:any`: Returns whether any element is non-zero.
- `LArray:all`: Returns whether all elements are non-zero.
- `LArray:sum`: Returns total sum or a summed array along a one-based axis.
- `LArray:mean`: Returns total mean or a mean array along a one-based axis.
- `LArray:min`: Returns total minimum or a minimum array along a one-based axis.
- `LArray:max`: Returns total maximum or a maximum array along a one-based axis.
- `LArray:matmul`: Returns matrix multiplication of this array and another array.
- `LArray:dot`: Returns dot product with another array.
- `LArray:bitwiseAnd`: Returns element-wise bitwise AND with another array.
- `LArray:bitwiseOr`: Returns element-wise bitwise OR with another array.
- `LArray:bitwiseXor`: Returns element-wise bitwise XOR with another array.
- `LArray:bitwiseNot`: Returns element-wise bitwise NOT.
- `LArray:bitwiseLShift`: Returns element-wise left shift by a bit count.
- `LArray:bitwiseRShift`: Returns element-wise right shift by a bit count.
- `LArray:convolve2D`: Returns two-dimensional convolution with a kernel array.
- `LArray:dilate`: Returns morphological dilation with a radius.
- `LArray:erode`: Returns morphological erosion with a radius.
- `LArray:floodFill`: Returns a flood-filled copy starting at a one-based row and column.
- `LArray:getRegion`: Returns a rectangular region from this array.
- `LArray:setRegion`: Writes a source array into this array at a one-based row and column.
- `LArray:cumsum`: Returns cumulative sum over the flattened array.
- `LArray:diff`: Returns finite differences over the flattened array.
- `LArray:histogram`: Returns histogram bins for the array values.
- `LArray:percentile`: Returns a percentile value from the array.
- `LArray:covariance`: Returns covariance with another array.
- `LArray:pearsonCorr`: Returns Pearson correlation with another array.
- `LArray:normalizeRange`: Returns array values normalized into a target range.
- `LArray:zscore`: Returns z-score normalized array values.
- `LArray:convolve1d`: Returns one-dimensional convolution with a kernel array.
- `LArray:correlate1d`: Returns one-dimensional correlation with a template array.
- `LArray:normalizeVec`: Returns this vector normalized to unit length.
- `LArray:outer`: Returns outer product with another vector array.
- `LArray:cross2d`: Returns two-dimensional cross product with another vector.
- `LArray:transformPoints`: Transforms a point array by this transform matrix.
- `LArray:sobel`: Computes Sobel gradients for this array.
- `LArray:linsolve`: Solves a linear system using this matrix and a right-hand side array.
- `LArray:luDecompose`: Decomposes this matrix into LU data and permutation metadata.
- `LArray:eigenPower`: Estimates dominant eigenvalue and eigenvector using power iteration.
- `LArray:map`: Maps each element through a Lua function and returns a new array.
- `LArray:eval`: Maps each element through a Lua expression compiled as `function(x) return expression end`.
- `LArray:reduce`: Reduces array values with a Lua accumulator function.
- `LArray:scan`: Produces prefix accumulator values with a Lua function.
- `LArray:type`: Returns the Lua-visible type name for this array handle.
- `LArray:typeOf`: Returns whether this array handle matches a supported type name.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/compute/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
