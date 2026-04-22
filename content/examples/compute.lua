-- content/examples/compute.lua
-- Scaffolded coverage of the lurek.compute API (67 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/compute_api.rs   (Lua binding, arg types, return shape)
--   * src/compute/                 (semantics, side effects)
--   * docs/specs/compute.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/compute.lua

-- ── lurek.compute.* functions ──

--@api-stub: lurek.compute.newArray
-- Creates a zero-initialized array with the given shape and optional dtype.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.newArray
  local _todo = "TODO: write a real lurek.compute.newArray usage example"
  print(_todo)
end

--@api-stub: lurek.compute.zeros
-- Creates a zero-filled array with the given shape and optional dtype.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.zeros
  local _todo = "TODO: write a real lurek.compute.zeros usage example"
  print(_todo)
end

--@api-stub: lurek.compute.ones
-- Creates a one-filled array with the given shape and optional dtype.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.ones
  local _todo = "TODO: write a real lurek.compute.ones usage example"
  print(_todo)
end

--@api-stub: lurek.compute.range
-- Creates a 1D array from start to stop with optional step and dtype.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.range
  local _todo = "TODO: write a real lurek.compute.range usage example"
  print(_todo)
end

--@api-stub: lurek.compute.fromTable
-- Creates an array from a Lua table of numbers with optional shape and dtype.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.fromTable
  local _todo = "TODO: write a real lurek.compute.fromTable usage example"
  print(_todo)
end

--@api-stub: lurek.compute.gaussianKernel
-- Creates a sizeĂ—size Gaussian kernel array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.gaussianKernel
  local _todo = "TODO: write a real lurek.compute.gaussianKernel usage example"
  print(_todo)
end

--@api-stub: lurek.compute.rotate2dMatrix
-- Creates a 2Ă—2 rotation matrix for the given angle in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.rotate2dMatrix
  local _todo = "TODO: write a real lurek.compute.rotate2dMatrix usage example"
  print(_todo)
end

--@api-stub: lurek.compute.affine2d
-- Creates a 3Ă—3 homogeneous affine matrix.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.affine2d
  local _todo = "TODO: write a real lurek.compute.affine2d usage example"
  print(_todo)
end

--@api-stub: lurek.compute.fft
-- Computes the discrete Fourier transform of a 1D real-valued sample array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.fft
  local _todo = "TODO: write a real lurek.compute.fft usage example"
  print(_todo)
end

--@api-stub: lurek.compute.ifft
-- Computes the inverse discrete Fourier transform.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.ifft
  local _todo = "TODO: write a real lurek.compute.ifft usage example"
  print(_todo)
end

--@api-stub: lurek.compute.fftMagnitude
-- Returns the magnitude spectrum `|X[k]|` of a real-valued sample array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: lurek.compute.fftMagnitude
  local _todo = "TODO: write a real lurek.compute.fftMagnitude usage example"
  print(_todo)
end

-- ── Array methods ──

--@api-stub: Array:getShape
-- Returns the shape as a table of dimension sizes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:getShape
  local _todo = "TODO: write a real Array:getShape usage example"
  print(_todo)
end

--@api-stub: Array:getDimensions
-- Returns the number of dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:getDimensions
  local _todo = "TODO: write a real Array:getDimensions usage example"
  print(_todo)
end

--@api-stub: Array:getSize
-- Returns the total number of elements.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:getSize
  local _todo = "TODO: write a real Array:getSize usage example"
  print(_todo)
end

--@api-stub: Array:getDataType
-- Returns the element data type name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:getDataType
  local _todo = "TODO: write a real Array:getDataType usage example"
  print(_todo)
end

--@api-stub: Array:isOnGPU
-- Returns false (CPU arrays only).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:isOnGPU
  local _todo = "TODO: write a real Array:isOnGPU usage example"
  print(_todo)
end

--@api-stub: Array:get
-- Returns the element at the given 1-based indices.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:get
  local _todo = "TODO: write a real Array:get usage example"
  print(_todo)
end

--@api-stub: Array:set
-- Sets the element at the given 1-based indices to a value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:set
  local _todo = "TODO: write a real Array:set usage example"
  print(_todo)
end

--@api-stub: Array:toTable
-- Returns all elements as a flat table of numbers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:toTable
  local _todo = "TODO: write a real Array:toTable usage example"
  print(_todo)
end

--@api-stub: Array:reshape
-- Returns a new array with the given shape and the same data.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:reshape
  local _todo = "TODO: write a real Array:reshape usage example"
  print(_todo)
end

--@api-stub: Array:clone
-- Returns a deep copy of this array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:clone
  local _todo = "TODO: write a real Array:clone usage example"
  print(_todo)
end

--@api-stub: Array:transpose
-- Returns the transposed 2D array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:transpose
  local _todo = "TODO: write a real Array:transpose usage example"
  print(_todo)
end

--@api-stub: Array:fill
-- Fills all elements with the given value in-place.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:fill
  local _todo = "TODO: write a real Array:fill usage example"
  print(_todo)
end

--@api-stub: Array:pow
-- Raises each element to a scalar exponent.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:pow
  local _todo = "TODO: write a real Array:pow usage example"
  print(_todo)
end

--@api-stub: Array:sqrt
-- Element-wise square root.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:sqrt
  local _todo = "TODO: write a real Array:sqrt usage example"
  print(_todo)
end

--@api-stub: Array:abs
-- Element-wise absolute value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:abs
  local _todo = "TODO: write a real Array:abs usage example"
  print(_todo)
end

--@api-stub: Array:neg
-- Returns a new Array with every element negated (multiplied by â’1).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:neg
  local _todo = "TODO: write a real Array:neg usage example"
  print(_todo)
end

--@api-stub: Array:clamp
-- Clamps each element to the given range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:clamp
  local _todo = "TODO: write a real Array:clamp usage example"
  print(_todo)
end

--@api-stub: Array:threshold
-- Returns a mask array with 1.0 where elements >= val, else 0.0.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:threshold
  local _todo = "TODO: write a real Array:threshold usage example"
  print(_todo)
end

--@api-stub: Array:countNonZero
-- Returns the count of nonzero elements.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:countNonZero
  local _todo = "TODO: write a real Array:countNonZero usage example"
  print(_todo)
end

--@api-stub: Array:argmin
-- Returns the 1-based flat index of the minimum element.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:argmin
  local _todo = "TODO: write a real Array:argmin usage example"
  print(_todo)
end

--@api-stub: Array:argmax
-- Returns the 1-based flat index of the maximum element.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:argmax
  local _todo = "TODO: write a real Array:argmax usage example"
  print(_todo)
end

--@api-stub: Array:any
-- Returns true if any element is nonzero.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:any
  local _todo = "TODO: write a real Array:any usage example"
  print(_todo)
end

--@api-stub: Array:all
-- Returns true if all elements are nonzero.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:all
  local _todo = "TODO: write a real Array:all usage example"
  print(_todo)
end

--@api-stub: Array:sum
-- Sum of all elements, or along an axis (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:sum
  local _todo = "TODO: write a real Array:sum usage example"
  print(_todo)
end

--@api-stub: Array:mean
-- Mean of all elements, or along an axis (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:mean
  local _todo = "TODO: write a real Array:mean usage example"
  print(_todo)
end

--@api-stub: Array:min
-- Minimum of all elements, or along an axis (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:min
  local _todo = "TODO: write a real Array:min usage example"
  print(_todo)
end

--@api-stub: Array:max
-- Maximum of all elements, or along an axis (1-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:max
  local _todo = "TODO: write a real Array:max usage example"
  print(_todo)
end

--@api-stub: Array:matmul
-- Matrix multiplication of two 2D arrays.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:matmul
  local _todo = "TODO: write a real Array:matmul usage example"
  print(_todo)
end

--@api-stub: Array:dot
-- Dot product of two 1D arrays.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:dot
  local _todo = "TODO: write a real Array:dot usage example"
  print(_todo)
end

--@api-stub: Array:bitwiseAnd
-- Bitwise AND of two Int32 arrays.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:bitwiseAnd
  local _todo = "TODO: write a real Array:bitwiseAnd usage example"
  print(_todo)
end

--@api-stub: Array:bitwiseOr
-- Bitwise OR of two Int32 arrays.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:bitwiseOr
  local _todo = "TODO: write a real Array:bitwiseOr usage example"
  print(_todo)
end

--@api-stub: Array:bitwiseXor
-- Bitwise XOR of two Int32 arrays.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:bitwiseXor
  local _todo = "TODO: write a real Array:bitwiseXor usage example"
  print(_todo)
end

--@api-stub: Array:bitwiseNot
-- Bitwise NOT of an Int32 array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:bitwiseNot
  local _todo = "TODO: write a real Array:bitwiseNot usage example"
  print(_todo)
end

--@api-stub: Array:bitwiseLShift
-- Bitwise left shift of an Int32 array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:bitwiseLShift
  local _todo = "TODO: write a real Array:bitwiseLShift usage example"
  print(_todo)
end

--@api-stub: Array:bitwiseRShift
-- Bitwise right shift of an Int32 array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:bitwiseRShift
  local _todo = "TODO: write a real Array:bitwiseRShift usage example"
  print(_todo)
end

--@api-stub: Array:convolve2D
-- 2D convolution with zero-padding.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:convolve2D
  local _todo = "TODO: write a real Array:convolve2D usage example"
  print(_todo)
end

--@api-stub: Array:dilate
-- Morphological dilation with a diamond structuring element.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:dilate
  local _todo = "TODO: write a real Array:dilate usage example"
  print(_todo)
end

--@api-stub: Array:erode
-- Morphological erosion with a diamond structuring element.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:erode
  local _todo = "TODO: write a real Array:erode usage example"
  print(_todo)
end

--@api-stub: Array:cumsum
-- Cumulative sum of all elements (flattened).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:cumsum
  local _todo = "TODO: write a real Array:cumsum usage example"
  print(_todo)
end

--@api-stub: Array:diff
-- Discrete difference applied `order` times.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:diff
  local _todo = "TODO: write a real Array:diff usage example"
  print(_todo)
end

--@api-stub: Array:percentile
-- Compute the p-th percentile (0â€“100).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:percentile
  local _todo = "TODO: write a real Array:percentile usage example"
  print(_todo)
end

--@api-stub: Array:covariance
-- Population covariance with another 1D array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:covariance
  local _todo = "TODO: write a real Array:covariance usage example"
  print(_todo)
end

--@api-stub: Array:pearsonCorr
-- Pearson correlation coefficient with another 1D array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:pearsonCorr
  local _todo = "TODO: write a real Array:pearsonCorr usage example"
  print(_todo)
end

--@api-stub: Array:normalizeRange
-- Linearly rescale values to [out_min, out_max].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:normalizeRange
  local _todo = "TODO: write a real Array:normalizeRange usage example"
  print(_todo)
end

--@api-stub: Array:zscore
-- Standardise values to zero mean and unit variance.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:zscore
  local _todo = "TODO: write a real Array:zscore usage example"
  print(_todo)
end

--@api-stub: Array:convolve1d
-- 1D convolution with a kernel array (full output).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:convolve1d
  local _todo = "TODO: write a real Array:convolve1d usage example"
  print(_todo)
end

--@api-stub: Array:correlate1d
-- 1D cross-correlation with a template array (valid output).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:correlate1d
  local _todo = "TODO: write a real Array:correlate1d usage example"
  print(_todo)
end

--@api-stub: Array:normalizeVec
-- L2-normalise a 1D vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:normalizeVec
  local _todo = "TODO: write a real Array:normalizeVec usage example"
  print(_todo)
end

--@api-stub: Array:outer
-- Outer product of two 1D vectors â†’ 2D array [m, n].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:outer
  local _todo = "TODO: write a real Array:outer usage example"
  print(_todo)
end

--@api-stub: Array:cross2d
-- Signed 2D cross product with another length-2 array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:cross2d
  local _todo = "TODO: write a real Array:cross2d usage example"
  print(_todo)
end

--@api-stub: Array:transformPoints
-- Apply this 2Ă—2 or 3Ă—3 matrix to an [N,2] points array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:transformPoints
  local _todo = "TODO: write a real Array:transformPoints usage example"
  print(_todo)
end

--@api-stub: Array:sobel
-- Apply Sobel edge detection to a 2D array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:sobel
  local _todo = "TODO: write a real Array:sobel usage example"
  print(_todo)
end

--@api-stub: Array:linsolve
-- Solve AÂ·x = b where this array is A (square [n,n]) and b is a 1D vector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:linsolve
  local _todo = "TODO: write a real Array:linsolve usage example"
  print(_todo)
end

--@api-stub: Array:luDecompose
-- Decomposes this square matrix into L and U factors with partial pivoting.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:luDecompose
  local _todo = "TODO: write a real Array:luDecompose usage example"
  print(_todo)
end

--@api-stub: Array:type
-- Returns the type name "Array".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:type
  local _todo = "TODO: write a real Array:type usage example"
  print(_todo)
end

--@api-stub: Array:typeOf
-- Returns true when the given name matches "Array" or a parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/compute_api.rs and docs/specs/compute.md).
do  -- TODO: Array:typeOf
  local _todo = "TODO: write a real Array:typeOf usage example"
  print(_todo)
end

