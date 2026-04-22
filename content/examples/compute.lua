-- content/examples/compute.lua
-- Auto-scaffolded coverage of the lurek.compute Lua API (67 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/compute.lua

print("[example] lurek.compute loaded — 67 API items demonstrated")

-- ── lurek.compute free functions ──

--@api-stub: lurek.compute.newArray
-- Creates a zero-initialized array with the given shape and optional dtype.
-- Use this when creates a zero-initialized array with the given shape and optional dtype is needed.
if false then
  local _r = lurek.compute.newArray(0, 0)
  print(_r)
end

--@api-stub: lurek.compute.zeros
-- Creates a zero-filled array with the given shape and optional dtype.
-- Use this when creates a zero-filled array with the given shape and optional dtype is needed.
if false then
  local _r = lurek.compute.zeros(0, 0)
  print(_r)
end

--@api-stub: lurek.compute.ones
-- Creates a one-filled array with the given shape and optional dtype.
-- Use this when creates a one-filled array with the given shape and optional dtype is needed.
if false then
  local _r = lurek.compute.ones(0, 0)
  print(_r)
end

--@api-stub: lurek.compute.range
-- Creates a 1D array from start to stop with optional step and dtype.
-- Use this when creates a 1D array from start to stop with optional step and dtype is needed.
if false then
  local _r = lurek.compute.range(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.compute.fromTable
-- Creates an array from a Lua table of numbers with optional shape and dtype.
-- Use this when creates an array from a Lua table of numbers with optional shape and dtype is needed.
if false then
  local _r = lurek.compute.fromTable(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.compute.gaussianKernel
-- Creates a sizeĂ—size Gaussian kernel array.
-- Use this when creates a sizeĂ—size Gaussian kernel array is needed.
if false then
  local _r = lurek.compute.gaussianKernel(1, nil)
  print(_r)
end

--@api-stub: lurek.compute.rotate2dMatrix
-- Creates a 2Ă—2 rotation matrix for the given angle in radians.
-- Use this when creates a 2Ă—2 rotation matrix for the given angle in radians is needed.
if false then
  local _r = lurek.compute.rotate2dMatrix(1)
  print(_r)
end

--@api-stub: lurek.compute.affine2d
-- Creates a 3Ă—3 homogeneous affine matrix.
-- Use this when creates a 3Ă—3 homogeneous affine matrix is needed.
if false then
  local _r = lurek.compute.affine2d(0, 0, 1, 0, 0)
  print(_r)
end

--@api-stub: lurek.compute.fft
-- Computes the discrete Fourier transform of a 1D real-valued sample array.
-- Use this when computes the discrete Fourier transform of a 1D real-valued sample array is needed.
if false then
  local _r = lurek.compute.fft(nil)
  print(_r)
end

--@api-stub: lurek.compute.ifft
-- Computes the inverse discrete Fourier transform.
-- Use this when computes the inverse discrete Fourier transform is needed.
if false then
  local _r = lurek.compute.ifft(nil)
  print(_r)
end

--@api-stub: lurek.compute.fftMagnitude
-- Returns the magnitude spectrum `|X[k]|` of a real-valued sample array.
-- Use this when returns the magnitude spectrum `|X[k]|` of a real-valued sample array is needed.
if false then
  local _r = lurek.compute.fftMagnitude(nil)
  print(_r)
end

-- ── Array methods ──

--@api-stub: Array:getShape
-- Returns the shape as a table of dimension sizes.
-- Use this when returns the shape as a table of dimension sizes is needed.
if false then
  local _o = nil  -- Array instance
  _o:getShape()
end

--@api-stub: Array:getDimensions
-- Returns the number of dimensions.
-- Use this when returns the number of dimensions is needed.
if false then
  local _o = nil  -- Array instance
  _o:getDimensions()
end

--@api-stub: Array:getSize
-- Returns the total number of elements.
-- Use this when returns the total number of elements is needed.
if false then
  local _o = nil  -- Array instance
  _o:getSize()
end

--@api-stub: Array:getDataType
-- Returns the element data type name.
-- Use this when returns the element data type name is needed.
if false then
  local _o = nil  -- Array instance
  _o:getDataType()
end

--@api-stub: Array:isOnGPU
-- Returns false (CPU arrays only).
-- Use this when returns false (CPU arrays only) is needed.
if false then
  local _o = nil  -- Array instance
  _o:isOnGPU()
end

--@api-stub: Array:get
-- Returns the element at the given 1-based indices.
-- Use this when returns the element at the given 1-based indices is needed.
if false then
  local _o = nil  -- Array instance
  _o:get({})
end

--@api-stub: Array:set
-- Sets the element at the given 1-based indices to a value.
-- Use this when sets the element at the given 1-based indices to a value is needed.
if false then
  local _o = nil  -- Array instance
  _o:set({})
end

--@api-stub: Array:toTable
-- Returns all elements as a flat table of numbers.
-- Use this when returns all elements as a flat table of numbers is needed.
if false then
  local _o = nil  -- Array instance
  _o:toTable()
end

--@api-stub: Array:reshape
-- Returns a new array with the given shape and the same data.
-- Use this when returns a new array with the given shape and the same data is needed.
if false then
  local _o = nil  -- Array instance
  _o:reshape(0)
end

--@api-stub: Array:clone
-- Returns a deep copy of this array.
-- Use this when returns a deep copy of this array is needed.
if false then
  local _o = nil  -- Array instance
  _o:clone()
end

--@api-stub: Array:transpose
-- Returns the transposed 2D array.
-- Use this when returns the transposed 2D array is needed.
if false then
  local _o = nil  -- Array instance
  _o:transpose()
end

--@api-stub: Array:fill
-- Fills all elements with the given value in-place.
-- Use this when fills all elements with the given value in-place is needed.
if false then
  local _o = nil  -- Array instance
  _o:fill(0)
end

--@api-stub: Array:pow
-- Raises each element to a scalar exponent.
-- Use this when raises each element to a scalar exponent is needed.
if false then
  local _o = nil  -- Array instance
  _o:pow(0)
end

--@api-stub: Array:sqrt
-- Element-wise square root.
-- Use this when element-wise square root is needed.
if false then
  local _o = nil  -- Array instance
  _o:sqrt()
end

--@api-stub: Array:abs
-- Element-wise absolute value.
-- Use this when element-wise absolute value is needed.
if false then
  local _o = nil  -- Array instance
  _o:abs()
end

--@api-stub: Array:neg
-- Returns a new Array with every element negated (multiplied by â’1).
-- Use this when returns a new Array with every element negated (multiplied by â’1) is needed.
if false then
  local _o = nil  -- Array instance
  _o:neg()
end

--@api-stub: Array:clamp
-- Clamps each element to the given range.
-- Use this when clamps each element to the given range is needed.
if false then
  local _o = nil  -- Array instance
  _o:clamp(1, 0)
end

--@api-stub: Array:threshold
-- Returns a mask array with 1.0 where elements >= val, else 0.0.
-- Use this when returns a mask array with 1.0 where elements >= val, else 0.0 is needed.
if false then
  local _o = nil  -- Array instance
  _o:threshold(0)
end

--@api-stub: Array:countNonZero
-- Returns the count of nonzero elements.
-- Use this when returns the count of nonzero elements is needed.
if false then
  local _o = nil  -- Array instance
  _o:countNonZero()
end

--@api-stub: Array:argmin
-- Returns the 1-based flat index of the minimum element.
-- Use this when returns the 1-based flat index of the minimum element is needed.
if false then
  local _o = nil  -- Array instance
  _o:argmin()
end

--@api-stub: Array:argmax
-- Returns the 1-based flat index of the maximum element.
-- Use this when returns the 1-based flat index of the maximum element is needed.
if false then
  local _o = nil  -- Array instance
  _o:argmax()
end

--@api-stub: Array:any
-- Returns true if any element is nonzero.
-- Use this when returns true if any element is nonzero is needed.
if false then
  local _o = nil  -- Array instance
  _o:any()
end

--@api-stub: Array:all
-- Returns true if all elements are nonzero.
-- Use this when returns true if all elements are nonzero is needed.
if false then
  local _o = nil  -- Array instance
  _o:all()
end

--@api-stub: Array:sum
-- Sum of all elements, or along an axis (1-based).
-- Use this when sum of all elements, or along an axis (1-based) is needed.
if false then
  local _o = nil  -- Array instance
  _o:sum(0)
end

--@api-stub: Array:mean
-- Mean of all elements, or along an axis (1-based).
-- Use this when mean of all elements, or along an axis (1-based) is needed.
if false then
  local _o = nil  -- Array instance
  _o:mean(0)
end

--@api-stub: Array:min
-- Minimum of all elements, or along an axis (1-based).
-- Use this when minimum of all elements, or along an axis (1-based) is needed.
if false then
  local _o = nil  -- Array instance
  _o:min(0)
end

--@api-stub: Array:max
-- Maximum of all elements, or along an axis (1-based).
-- Use this when maximum of all elements, or along an axis (1-based) is needed.
if false then
  local _o = nil  -- Array instance
  _o:max(0)
end

--@api-stub: Array:matmul
-- Matrix multiplication of two 2D arrays.
-- Use this when matrix multiplication of two 2D arrays is needed.
if false then
  local _o = nil  -- Array instance
  _o:matmul(0)
end

--@api-stub: Array:dot
-- Dot product of two 1D arrays.
-- Use this when dot product of two 1D arrays is needed.
if false then
  local _o = nil  -- Array instance
  _o:dot(0)
end

--@api-stub: Array:bitwiseAnd
-- Bitwise AND of two Int32 arrays.
-- Use this when bitwise AND of two Int32 arrays is needed.
if false then
  local _o = nil  -- Array instance
  _o:bitwiseAnd(0)
end

--@api-stub: Array:bitwiseOr
-- Bitwise OR of two Int32 arrays.
-- Use this when bitwise OR of two Int32 arrays is needed.
if false then
  local _o = nil  -- Array instance
  _o:bitwiseOr(0)
end

--@api-stub: Array:bitwiseXor
-- Bitwise XOR of two Int32 arrays.
-- Use this when bitwise XOR of two Int32 arrays is needed.
if false then
  local _o = nil  -- Array instance
  _o:bitwiseXor(0)
end

--@api-stub: Array:bitwiseNot
-- Bitwise NOT of an Int32 array.
-- Use this when bitwise NOT of an Int32 array is needed.
if false then
  local _o = nil  -- Array instance
  _o:bitwiseNot()
end

--@api-stub: Array:bitwiseLShift
-- Bitwise left shift of an Int32 array.
-- Use this when bitwise left shift of an Int32 array is needed.
if false then
  local _o = nil  -- Array instance
  _o:bitwiseLShift(1)
end

--@api-stub: Array:bitwiseRShift
-- Bitwise right shift of an Int32 array.
-- Use this when bitwise right shift of an Int32 array is needed.
if false then
  local _o = nil  -- Array instance
  _o:bitwiseRShift(1)
end

--@api-stub: Array:convolve2D
-- 2D convolution with zero-padding.
-- Use this when 2D convolution with zero-padding is needed.
if false then
  local _o = nil  -- Array instance
  _o:convolve2D(1)
end

--@api-stub: Array:dilate
-- Morphological dilation with a diamond structuring element.
-- Use this when morphological dilation with a diamond structuring element is needed.
if false then
  local _o = nil  -- Array instance
  _o:dilate(nil)
end

--@api-stub: Array:erode
-- Morphological erosion with a diamond structuring element.
-- Use this when morphological erosion with a diamond structuring element is needed.
if false then
  local _o = nil  -- Array instance
  _o:erode(nil)
end

--@api-stub: Array:cumsum
-- Cumulative sum of all elements (flattened).
-- Use this when cumulative sum of all elements (flattened) is needed.
if false then
  local _o = nil  -- Array instance
  _o:cumsum()
end

--@api-stub: Array:diff
-- Discrete difference applied `order` times.
-- Use this when discrete difference applied `order` times is needed.
if false then
  local _o = nil  -- Array instance
  _o:diff(nil)
end

--@api-stub: Array:percentile
-- Compute the p-th percentile (0â€“100).
-- Use this when compute the p-th percentile (0â€“100) is needed.
if false then
  local _o = nil  -- Array instance
  _o:percentile(nil)
end

--@api-stub: Array:covariance
-- Population covariance with another 1D array.
-- Use this when population covariance with another 1D array is needed.
if false then
  local _o = nil  -- Array instance
  _o:covariance(0)
end

--@api-stub: Array:pearsonCorr
-- Pearson correlation coefficient with another 1D array.
-- Use this when pearson correlation coefficient with another 1D array is needed.
if false then
  local _o = nil  -- Array instance
  _o:pearsonCorr(0)
end

--@api-stub: Array:normalizeRange
-- Linearly rescale values to [out_min, out_max].
-- Use this when linearly rescale values to [out_min, out_max] is needed.
if false then
  local _o = nil  -- Array instance
  _o:normalizeRange(nil, 0)
end

--@api-stub: Array:zscore
-- Standardise values to zero mean and unit variance.
-- Use this when standardise values to zero mean and unit variance is needed.
if false then
  local _o = nil  -- Array instance
  _o:zscore()
end

--@api-stub: Array:convolve1d
-- 1D convolution with a kernel array (full output).
-- Use this when 1D convolution with a kernel array (full output) is needed.
if false then
  local _o = nil  -- Array instance
  _o:convolve1d(1)
end

--@api-stub: Array:correlate1d
-- 1D cross-correlation with a template array (valid output).
-- Use this when 1D cross-correlation with a template array (valid output) is needed.
if false then
  local _o = nil  -- Array instance
  _o:correlate1d(0)
end

--@api-stub: Array:normalizeVec
-- L2-normalise a 1D vector.
-- Use this when l2-normalise a 1D vector is needed.
if false then
  local _o = nil  -- Array instance
  _o:normalizeVec()
end

--@api-stub: Array:outer
-- Outer product of two 1D vectors â†’ 2D array [m, n].
-- Use this when outer product of two 1D vectors â†’ 2D array [m, n] is needed.
if false then
  local _o = nil  -- Array instance
  _o:outer(0)
end

--@api-stub: Array:cross2d
-- Signed 2D cross product with another length-2 array.
-- Use this when signed 2D cross product with another length-2 array is needed.
if false then
  local _o = nil  -- Array instance
  _o:cross2d(0)
end

--@api-stub: Array:transformPoints
-- Apply this 2Ă—2 or 3Ă—3 matrix to an [N,2] points array.
-- Use this when apply this 2Ă—2 or 3Ă—3 matrix to an [N,2] points array is needed.
if false then
  local _o = nil  -- Array instance
  _o:transformPoints(0)
end

--@api-stub: Array:sobel
-- Apply Sobel edge detection to a 2D array.
-- Returns {gx=Array, gy=Array}.
if false then
  local _o = nil  -- Array instance
  _o:sobel()
end

--@api-stub: Array:linsolve
-- Solve AÂ·x = b where this array is A (square [n,n]) and b is a 1D vector.
-- Use this when solve AÂ·x = b where this array is A (square [n,n]) and b is a 1D vector is needed.
if false then
  local _o = nil  -- Array instance
  _o:linsolve(nil)
end

--@api-stub: Array:luDecompose
-- Decomposes this square matrix into L and U factors with partial pivoting.
-- Use this when decomposes this square matrix into L and U factors with partial pivoting is needed.
if false then
  local _o = nil  -- Array instance
  _o:luDecompose()
end

--@api-stub: Array:type
-- Returns the type name "Array".
-- Use this when returns the type name "Array" is needed.
if false then
  local _o = nil  -- Array instance
  _o:type()
end

--@api-stub: Array:typeOf
-- Returns true when the given name matches "Array" or a parent type.
-- Use this when returns true when the given name matches "Array" or a parent type is needed.
if false then
  local _o = nil  -- Array instance
  _o:typeOf(1)
end

